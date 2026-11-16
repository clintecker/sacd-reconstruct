#!/usr/bin/env python3
"""Annotate an llvm-objdump -d listing of an ARM ELF .so with resolved
literal-pool words and pc-relative string references.

Patterns handled (common ARM pic-lite codegen):
  ldr rN, [pc, #imm] @ 0xADDR      -> rN = word at file addr 0xADDR
  add rN, pc, rM                   -> rN = (addr+8) + rM
  add rN, rM, rK / add rN, rK, rM  -> if one side is an absolute base and
                                      the other a raw word: rN = base + word
  mov rN, #imm / movw              -> rN = imm
  ldr rN, [rM ...] / str rN        -> rN becomes unknown
  bl <name@plt>                    -> prints resolved args r0..r3
Resolves printf/puts/assert string arguments when the computed address
lands on printable data (file offset == vaddr for these files; verified
against section headers).
"""
import sys, re
from elftools.elf.elffile import ELFFile

LINE = re.compile(r'^\s*([0-9a-f]+):\s+(\S+)\s*(.*?)\s*$')
LABEL = re.compile(r'^([0-9a-f]+) <(.+)>:$')


def load(path):
    f = open(path, 'rb')
    elf = ELFFile(f)
    spans = []
    for s in elf.iter_sections():
        if s.header['sh_type'] != 'SHT_NOBITS' and s.header['sh_addr']:
            spans.append((s.header['sh_addr'], s.data(), s.name))
    return spans


def word_at(spans, addr):
    for base, data, name in spans:
        if base <= addr < base + len(data) - 3:
            return int.from_bytes(data[addr - base: addr - base + 4], 'little')
    return None


def string_at(spans, addr, maxlen=120):
    for base, data, name in spans:
        if base <= addr < base + len(data):
            off = addr - base
            chunk = data[off:off + maxlen]
            end = chunk.find(b'\0')
            if end == 0:
                return None
            if end > 0:
                chunk = chunk[:end]
            try:
                s = chunk.decode('ascii')
            except UnicodeDecodeError:
                return None
            if all(32 <= ord(c) < 127 or c in '\n\t' for c in s):
                return s
            return None
    return None


def main(path, txt):
    spans = load(path)
    regs = {}   # reg -> ('abs', value) | ('w', value) | None
    cur_fn = '?'
    out = []
    for line in open(txt):
        lm = LABEL.match(line.strip())
        if lm:
            cur_fn = lm.group(2)
            regs.clear()
            out.append(f'\n=== {cur_fn} ===')
            continue
        m = LINE.match(line.rstrip('\n'))
        if not m:
            continue
        addr = int(m.group(1), 16)
        mnem, ops = m.group(2), m.group(3)
        note = ''
        d = ops.split(',')[0].strip() if ops else ''
        rest = ops.split(',', 1)[1].strip() if ',' in ops else ''

        if mnem == 'ldr' and '[pc' in rest:
            am = re.search(r'@\s*([0-9a-f]+)', rest)
            if am:
                tgt = int(am.group(1), 16)
                w = word_at(spans, tgt)
                if w is not None:
                    regs[d] = ('w', w)
                    note = f'lit[{tgt:#x}]={w:#x}'
                else:
                    regs[d] = None
        elif mnem in ('add', 'sub') and re.match(r'r\w+, pc, ', ops):
            src = ops.split(',')[-1].strip()
            v = regs[src][1] if src in regs and regs[src] else None
            if v is not None:
                base = addr + 8 + (v if mnem == 'add' else -v)
                regs[d] = ('abs', base)
                note = f'base={base:#x}'
            else:
                regs[d] = None
        elif mnem == 'add' and ',' in ops and not ops.startswith('sp'):
            parts = [p.strip() for p in ops.split(',')]
            if len(parts) == 3 and parts[1] in regs and parts[2] in regs:
                k1 = regs[parts[1]]
                k2 = regs[parts[2]]
                if k1 and k2 and k1[0] != k2[0] and k1[1] is not None and k2[1] is not None:
                    a, b = (k1, k2) if k1[0] == 'abs' else (k2, k1)
                    val = a[1] + b[1]
                    regs[d] = ('abs', val)
                    s = string_at(spans, val)
                    if s:
                        note = f'ABS={val:#x} str="{s}"'
                    else:
                        note = f'ABS={val:#x}'
        elif mnem in ('mov', 'movw') and rest.startswith('#'):
            try:
                regs[d] = ('w', int(rest.lstrip('#'), 0))
            except ValueError:
                regs[d] = None
        elif mnem == 'movt':
            pass
        elif mnem in ('ldr', 'ldrb') and rest.startswith('[r'):
            regs[d] = None
        elif mnem in ('str', 'strb', 'strh'):
            if d in regs:
                note = 'store ' + str(regs[d][1]) if regs[d] and regs[d][0] == 'w' else 'store'
        elif mnem in ('bl', 'blx') and '@plt' in ops:
            args = []
            for r in ('r0', 'r1', 'r2', 'r3'):
                v = regs.get(r)
                if v and v[0] == 'abs':
                    s = string_at(spans, v[1])
                    args.append(f'{r}={v[1]:#x}' + (f' "{s}"' if s else ''))
                elif v and v[0] == 'w':
                    args.append(f'{r}={v[1]:#x}(w)')
            note = f'CALL {ops.split(" ")[0]} ' + ' '.join(args)
        elif mnem in ('bl', 'blx'):
            args = []
            for r in ('r0', 'r1', 'r2', 'r3'):
                v = regs.get(r)
                if v and v[0] == 'abs':
                    s = string_at(spans, v[1])
                    args.append(f'{r}={v[1]:#x}' + (f' "{s[:40]}"' if s else ''))
                elif v and v[0] == 'w':
                    args.append(f'{r}={v[1]:#x}(w)')
            note = 'CALL ' + ' '.join(args)
        elif mnem in ('b', 'beq', 'bne', 'blt', 'bgt', 'ble', 'bge', 'bhi', 'bls',
                      'bhs', 'blo', 'bcc', 'bcs', 'bvc', 'bvs', 'blx') and 'imm' not in ops:
            regs.clear() if mnem == 'b' else None
        out.append(f'{addr:#07x} {mnem:7s} {ops:42s} ; {note}' if note else
                   f'{addr:#07x} {mnem:7s} {ops}')
    print('\n'.join(out))


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
