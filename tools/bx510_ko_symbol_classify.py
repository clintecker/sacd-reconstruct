#!/usr/bin/env python3
"""bx510_ko_symbol_classify.py — classify a .ko's imported (undefined) symbols
by HOW they are referenced, so an OSAL stub can export each with the right
kind: function, function-pointer VARIABLE, or data.

Why (VERIFIED lesson, bdpdrv Run C2): Sony's OSAL exports some "functions"
(e.g. x_crit_start/x_crit_end) as function-pointer VARIABLES. bdpdrv does
  ldr r3,[lit]   ; R_ARM_ABS32 -> &x_crit_start
  ldr r3,[r3]    ; r3 = the pointer VALUE
  blx r3
If the stub exports a real function instead, the deref loads the function's
own prologue word (push {r0-r3} = 0xe92d000f) and blx jumps to it as a thumb
address -> Oops at PC=0xe92d000e.

Method (no LLM eyeballing; deterministic decode of .text + .rel.text):
  - R_ARM_CALL / R_ARM_PC24 on the symbol          -> direct-called (function)
  - pc-relative literal load of the ABS32 slot,
    followed within 3 instructions by ldr rN,[rM]; blx rN
    where rM is the literal-load destination        -> deref-called
    (must be exported as a function-pointer variable)
  - ABS32 without any of the above                   -> data / address-taken

Usage: python3 bx510_ko_symbol_classify.py MODULE.ko [--all]
  default lists only undefined symbols; --all includes defined ones.
Output table: name, direct-call count, ABS32 site count, deref-call sites
(matched/load-sites), suggested export kind.
"""
import argparse
import collections
import re
from elftools.elf.elffile import ELFFile
from capstone import Cs, CS_ARCH_ARM, CS_MODE_ARM


def classify(path, include_defined=False):
    with open(path, 'rb') as f:
        e = ELFFile(f)
        secs = {s.name: s for s in e.iter_sections()}
        text = secs['.text']
        T = text.data()
        symtab = list(secs['.symtab'].iter_symbols())
        syms = [(s.name, s['st_value']) for s in symtab]

        relmap = collections.defaultdict(list)
        for r in secs['.rel.text'].iter_relocations():
            relmap[r['r_offset']].append((r['r_info_type'], r['r_info_sym']))

        # R_ARM_ABS32=2, R_ARM_CALL=28, R_ARM_PC24=30
        abs32 = collections.defaultdict(list)   # symname -> [lit offsets]
        direct = collections.Counter()
        for off, rl in relmap.items():
            for typ, si in rl:
                name = syms[si][0] if si < len(syms) else '?'
                undef = si < len(syms) and syms[si][1] == 0
                if typ == 2 and undef:
                    abs32[name].append(off)
                elif typ in (28, 30):
                    direct[name] += 1

        # every "ldr rX, [pc, #imm]" (any cond): 0bE59F/cond+U pattern
        loads = []
        for a in range(0, len(T) - 3, 4):
            w = int.from_bytes(T[a:a + 4], 'little')
            if (w & 0x0E5F0000) == 0x041F0000:
                rd = (w >> 12) & 0xF
                imm = w & 0xFFF
                up = (w >> 23) & 1
                target = a + 8 + (imm if up else -imm)
                if 0 <= target < len(T):
                    loads.append((a, rd, target))
        loadbylit = collections.defaultdict(list)
        for a, rd, t in loads:
            loadbylit[t].append((a, rd))

        def deref_call_at(loadaddr, rd):
            """from a pc-rel literal load, look for ldr rY,[rX] then blx rY."""
            md = Cs(CS_ARCH_ARM, CS_MODE_ARM)
            seq = list(md.disasm(T[loadaddr:loadaddr + 40], loadaddr))
            for i, ins in enumerate(seq[:7]):
                if ins.mnemonic == 'ldr':
                    m = re.match(r'^(r\d+), \[(r\d+)\]$', ins.op_str)
                    if m and m.group(2) == 'r%d' % rd:
                        y = m.group(1)
                        for j in range(1, 4):
                            if i + j < len(seq):
                                n = seq[i + j]
                                if n.mnemonic == 'blx' and n.op_str.strip() == y:
                                    return True
                        return False
            return False

        rows = []
        for idx, (name, val) in enumerate(syms):
            if not include_defined and val != 0:
                continue
            if not name:
                continue
            lits = abs32.get(name, [])
            nder = nsite = 0
            for la in lits:
                for (la_addr, rd) in loadbylit.get(la, []):
                    nsite += 1
                    if deref_call_at(la_addr, rd):
                        nder += 1
            d = direct[name]
            if nder > 0:
                kind = 'FNPTR-VAR (deref-called)'
            elif d > 0:
                kind = 'function (direct-called)'
            elif lits:
                kind = 'data? (ABS32 only, no deref-call)'
            else:
                kind = 'unused/import unresolved?'
            rows.append((name, d, len(lits), nder, nsite, kind))
    rows.sort(key=lambda r: (r[5].startswith('FNPTR'), r[1], r[2]), reverse=False)
    rows.sort(key=lambda r: 0 if r[5].startswith('FNPTR') else 1)
    return rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('ko')
    ap.add_argument('--all', action='store_true')
    args = ap.parse_args()
    rows = classify(args.ko, args.all)
    print(f"{'symbol':40s} {'direct':>6s} {'ABS32':>5s} {'deref':>9s}  suggested export kind")
    for name, d, na, nder, nsi, kind in rows:
        if d == 0 and na == 0:
            continue
        print(f"{name:40s} {d:6d} {na:5d} {nder:4d}/{nsi:<4d}  {kind}")


if __name__ == '__main__':
    main()
