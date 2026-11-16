#!/usr/bin/env python3
"""Linear string-xref scanner over an llvm-objdump -d listing of an ARM .so.
Tracks literal loads / pc-relative adds / stack spills within each function
and records every register value that resolves to a printable string.
Deterministic: values come from file bytes."""
import sys, re
from elftools.elf.elffile import ELFFile

LINE = re.compile(r'^\s*([0-9a-f]+):\s+(\S+)\s*(.*?)$')
LABEL = re.compile(r'^([0-9a-f]+) <(.+)>:$')


def load(path):
    spans = []
    with open(path, 'rb') as f:
        elf = ELFFile(f)
        for s in elf.iter_sections():
            if s.header['sh_type'] != 'SHT_NOBITS' and s.header['sh_addr']:
                spans.append((s.header['sh_addr'], s.data()))
    return spans


def word_at(spans, addr):
    for base, data in spans:
        if base <= addr < base + len(data) - 3:
            return int.from_bytes(data[addr - base: addr - base + 4], 'little')
    return None


def string_at(spans, addr, maxlen=100):
    for base, data in spans:
        if base <= addr < base + len(data):
            chunk = data[addr - base: addr - base + maxlen]
            end = chunk.find(b'\0')
            if end <= 0:
                return None
            try:
                s = chunk[:end].decode('ascii')
            except UnicodeDecodeError:
                return None
            return s if all(32 <= ord(c) < 127 or c in '\n\t' for c in s) else None
    return None


def main(path, txt):
    spans = load(path)
    regs, stack, cur = {}, {}, '?'
    hits = []
    for line in open(txt):
        lm = LABEL.match(line.strip())
        if lm:
            cur, regs, stack = lm.group(2), {}, {}
            continue
        m = LINE.match(line.rstrip('\n'))
        if not m:
            continue
        a = int(m.group(1), 16)
        mn, ops = m.group(2), m.group(3)
        main_ops = ops.split(' @ ')[0].strip()
        cmt = ops.split(' @ ')[1] if ' @ ' in ops else ''
        d = main_ops.split(',')[0].strip() if main_ops else ''
        rest = main_ops.split(',', 1)[1].strip() if ',' in main_ops else ''
        sp = re.match(r'\[sp, #(0x[0-9a-f]+|\d+)\]', rest)

        if mn == 'ldr' and '[pc' in rest:
            lm2 = re.match(r'@?\s*(0x[0-9a-f]+)', cmt)
            if lm2:
                w = word_at(spans, int(lm2.group(1), 16))
                regs[d] = ('w', w) if w is not None else None
        elif mn == 'add' and re.fullmatch(r'r\d+,pc,r\d+', main_ops.replace(' ', '')):
            src = main_ops.split(',')[-1].strip()
            v = regs.get(src)
            regs[d] = ('abs', (a + 8 + v[1]) & 0xFFFFFFFF) if v and v[0] == 'w' else None
        elif mn in ('add', 'sub', 'rsb') and re.fullmatch(r'r\d+,r\d+,r\d+', main_ops.replace(' ', '')):
            p = [x.strip() for x in main_ops.split(',')]
            v1, v2 = regs.get(p[1]), regs.get(p[2])
            if v1 and v2 and v1[0] != v2[0] and v1[1] is not None and v2[1] is not None:
                abs_v, w_v = (v1, v2) if v1[0] == 'abs' else (v2, v1)
                val = abs_v[1] + w_v[1] if mn == 'add' else (
                    abs_v[1] - w_v[1] if mn == 'sub' else w_v[1] - abs_v[1])
                regs[d] = ('abs', val & 0xFFFFFFFF)
        elif mn in ('mov', 'movw') and rest.startswith('#'):
            try:
                regs[d] = ('w', int(rest.lstrip('#'), 0))
            except ValueError:
                regs[d] = None
        elif mn in ('ldr', 'ldrb', 'ldrsh', 'ldrsb', 'ldrh', 'pop'):
            if sp and ('sp', sp.group(1)) in stack:
                regs[d] = stack[('sp', sp.group(1))]
            else:
                regs[d] = None
        elif mn in ('str', 'strb', 'strh'):
            if sp and regs.get(d):
                stack[('sp', sp.group(1))] = regs[d]
        elif mn == 'mov' and rest in regs:
            regs[d] = regs[rest]
        elif mn == 'mov' and re.fullmatch(r'r\d+', rest):
            regs[d] = regs.get(rest)
        elif mn in ('mvn', 'eor', 'orr', 'and', 'mul', 'mla', 'ldrdeq', 'andeq',
                    'eoreq', 'subeq', 'streq', 'streqb', 'streqh', 'ldreq',
                    'ldreqb', 'cmp', 'tst'):
            if d.startswith('r') and mn not in ('cmp', 'tst'):
                regs[d] = None

        v = regs.get(d)
        if v and v[0] == 'abs':
            s = string_at(spans, v[1])
            if s:
                hits.append((a, cur, d, v[1], s))

    for a, fn, reg, val, s in hits:
        print(f'{a:#08x} {fn:35s} {reg} = {val:#x}  "{s[:90]}"')


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
