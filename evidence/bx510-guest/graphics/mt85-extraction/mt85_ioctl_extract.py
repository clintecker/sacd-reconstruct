#!/usr/bin/env python3
"""Parse llvm-objdump -d text of an ARM .so; for every ioctl@plt call site,
back-trace the definition of r1 (the ioctl request register) to its
literal-pool word and read that word out of the file. Deterministic:
request numbers come from file bytes at annotated literal addresses."""
import sys, re
from elftools.elf.elffile import ELFFile

LINE = re.compile(r'^\s*([0-9a-f]+):\s+(\S+)\s*(.*?)\s*$')


def split_comment(rest):
    """Split 'ops @ comment' on the LAST ' @ ' (symbol names contain '@')."""
    pos = rest.rfind(' @ ')
    if pos < 0:
        return rest, ''
    return rest[:pos], rest[pos + 3:]


def read_words(path):
    f = open(path, 'rb')
    elf = ELFFile(f)
    spans = []
    for s in elf.iter_sections():
        if s.header['sh_type'] != 'SHT_NOBITS' and s.header['sh_addr']:
            spans.append((s.header['sh_addr'], s.data()))
    return spans


def word_at(spans, addr):
    for base, data in spans:
        if base <= addr < base + len(data) - 3:
            return int.from_bytes(data[addr - base: addr - base + 4], 'little')
    return None


def main(path, objdump_txt):
    spans = read_words(path)
    funcs = []  # (addr, name)
    insns = []  # (addr, mnem, ops, comment)
    cur = None
    for line in open(objdump_txt):
        m = re.match(r'^([0-9a-f]+) <(.+)>:$', line.strip())
        if m:
            cur = (int(m.group(1), 16), m.group(2))
            funcs.append(cur)
            continue
        m = LINE.match(line.rstrip('\n'))
        if m and cur:
            addr = int(m.group(1), 16)
            ops, comment = split_comment(m.group(3) or '')
            insns.append((addr, m.group(2), ops, comment))
    idx_of = {a: k for k, (a, _, _, _) in enumerate(insns)}

    def fn_of(addr):
        best = None
        for fa, name in funcs:
            if fa <= addr and addr < fa + 0x10000:
                if best is None or fa > best[0]:
                    best = (fa, name)
        return best

    callsites = [(a, m, o, c) for (a, m, o, c) in insns
                 if m in ('bl', 'blx') and 'ioctl@plt' in o + ' ' + c]
    print(f"# ioctl@plt call sites: {len(callsites)}\n")
    for a, m, o, c in callsites:
        k = idx_of[a]
        # back-trace r1
        r1def = None
        j = k - 1
        steps = 0
        while j >= 0 and steps < 80:
            ia, im, io, ic = insns[j]
            if im == 'ldr' and io.startswith('r1, [pc'):
                lit = re.match(r'\s*(0x[0-9a-f]+)', ic)
                if lit:
                    tgt = int(lit.group(1), 16)
                    val = word_at(spans, tgt)
                    r1def = (tgt, val)
                    break
                break
            if im == 'ldr' and re.match(r'r1, \[r\d+', io):
                break  # memory load: def not a constant
            if im in ('mov', 'movw') and io.startswith('r1,'):
                src = io.split(',', 1)[1].strip()
                m2 = re.match(r'#(0x[0-9a-f]+|\d+)$', src)
                if m2:
                    r1def = (None, int(m2.group(1), 0))
                break
            if im in ('add', 'sub') and io.startswith('r1,'):
                break
            if im == 'pop' and 'r1' in io.split('{')[1].split('}')[0].split(','):
                break
            j -= 1
            steps += 1
        fa, fname = fn_of(a) or (0, '?')
        print(f"== {a:#06x} in {fname}")
        if r1def:
            tgt, val = r1def
            where = f"literal@{tgt:#x}" if tgt is not None else "immediate"
            print(f"   r1 <- {where} = {val:#x}" if val is not None else f"   r1 <- {where} (VALUE NOT IN FILE)")
        else:
            print("   r1 def: NOT RESOLVED (non-constant)")
        # context
        for kk in range(max(0, k - 6), k + 2):
            ia, im, io, ic = insns[kk]
            print(f"   {ia:#06x}: {im:8s} {io:34s} {('@ ' + ic) if ic else ''}")
        print()


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
