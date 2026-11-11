#!/usr/bin/env python3
"""bx510_ko_disasm.py — reloc-aware ARM disassembly of a range inside a .ko.

House rule: decode bytes with tools, never by squinting (AGENTS.md #7).
Literal pools are section-relative; raw objdump shows garbage words. This
tool resolves R_ARM_ABS32 relocations on literal slots against the module's
own symtab (undefined imports named as-is) and annotates pc-relative loads
with the literal's value + resolved symbol.

Usage:
  python3 bx510_ko_disasm.py MODULE.ko 0x987e8 0x98870
  python3 bx510_ko_disasm.py MODULE.ko --sym i4IdeDrvInit [--len 0x100]
"""
import argparse
import re
import sys
from elftools.elf.elffile import ELFFile
from capstone import Cs, CS_ARCH_ARM, CS_MODE_ARM


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('ko')
    ap.add_argument('start', nargs='?')
    ap.add_argument('end', nargs='?')
    ap.add_argument('--sym')
    ap.add_argument('--len', type=lambda x: int(x, 0), default=0x100)
    args = ap.parse_args()

    with open(args.ko, 'rb') as f:
        e = ELFFile(f)
        secs = {s.name: s for s in e.iter_sections()}
        text = secs['.text']
        T = text.data()
        syms = [(s.name, s['st_value'], s['st_size'])
                for s in secs['.symtab'].iter_symbols()]
        sym_entries = list(secs['.symtab'].iter_symbols())
        allsecs = list(e.iter_sections())

        relmap = {}
        for r in secs['.rel.text'].iter_relocations():
            relmap.setdefault(r['r_offset'], []).append(
                (r['r_info_type'], r['r_info_sym'],
                 r['r_addend'] if r.is_RELA() else None))

        def symname(idx):
            s = syms[idx] if idx < len(syms) else None
            if s is None:
                return '?'
            if s[0]:
                return s[0]
            # STT_SECTION symbol: resolve to section+offset (+ string content)
            shndx = allsecs[sym_entries[idx]['st_shndx']].name \
                if isinstance(sym_entries[idx]['st_shndx'], int) else '?'
            return f"{shndx}+{s[1]:#x}"

        def secstr(shndx, off):
            try:
                sec = allsecs[shndx]
                if sec.name.startswith('.rodata.str'):
                    b = sec.data()[off:off + 90].split(b'\0')[0]
                    return b.decode('latin1')[:80]
            except Exception:
                pass
            return None

        if args.sym:
            hits = [(n, v, sz) for n, v, sz in syms if n == args.sym]
            if not hits:
                sys.exit(f"symbol {args.sym} not found")
            start = hits[0][1]
            end = start + args.len
        else:
            start = int(args.start, 0)
            end = int(args.end, 0)

        md = Cs(CS_ARCH_ARM, CS_MODE_ARM)
        code = T[start:end]
        print(f"== {args.ko} .text [{start:#x}..{end:#x}) ==")
        for ins in md.disasm(code, start):
            line = f"{ins.address:06x}: {ins.mnemonic:8s} {ins.op_str}"
            extra = ""
            if 'ldr' in ins.mnemonic and '[pc' in ins.op_str:
                m = re.search(r'\[pc, #(-?(?:0x[0-9a-f]+|\d+))\]', ins.op_str)
                if m:
                    lit = ins.address + 8 + int(m.group(1), 0)
                    if 0 <= lit < len(T):
                        val = int.from_bytes(T[lit:lit + 4], 'little')
                        extra = f"  ; lit@{lit:06x} = {val:08x}"
                        for typ, symi, addend in relmap.get(lit, []):
                            nm = symname(symi)
                            extra += f"  REL{typ} sym={nm}"
                            if isinstance(sym_entries[symi]['st_shndx'], int):
                                sstr = secstr(sym_entries[symi]['st_shndx'], val)
                                if sstr:
                                    extra += f' str="{sstr}"'
                        if not relmap.get(lit):
                            # section-relative constant: show raw value
                            extra += "  (no reloc)"
            for typ, symi, addend in relmap.get(ins.address, []):
                extra += f"  <<RELOC type={typ} sym={symname(symi)}>>"
            print(line + extra)


if __name__ == '__main__':
    main()
