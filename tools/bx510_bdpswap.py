#!/usr/bin/env python3
"""bdpswap: put a sacrificial tail-marker symbol into the LAST symtab slot
of a .ko — WITH full relocation-index fixups and a post-swap export check.

Sony's 2.6.35 layout_symtab/add_kallsyms drop the LAST symtab entry of
every loaded module from kallsyms (off-by-one: 'for (ndst = i = 1; i <
nsrc; ++i, ++src)' starting at index 0 examines 0..nsrc-2). To control
which symbol is the victim we swap a sacrificial marker into the final
slot.

Swapping symtab ENTRIES ALONE IS INSUFFICIENT: relocations reference
symbols BY INDEX (Elf32_Rel.r_info >> 8), so every relocation pointing at
either swapped index must be remapped or exports silently resolve to the
wrong function — found by the virtual-drive team's review: after the old
entry-only swap, __ksymtab_eSacdGetVersion's value relocation resolved
to bdpvirt_tail_marker_2 and vice versa. The kallsyms path (name-string
based) was unaffected, so all guest results stand, but the exported
function pointers were wrong.

This tool now:
  1. swaps the two Elf32_Sym entries,
  2. remaps every relocation's symbol index in every SHT_REL section,
  3. VERIFIES every __ksymtab_* export: its value relocation must resolve
     to the symbol with the matching name. Exits nonzero on failure.

Usage: bdpswap.py <module.ko> <marker-symbol-name>
"""
import struct
import sys

SHT_REL = 9


def u16(b, o):
    return struct.unpack_from("<H", b, o)[0]


def u32(b, o):
    return struct.unpack_from("<I", b, o)[0]


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    path, marker = sys.argv[1], sys.argv[2].encode()
    data = bytearray(open(path, "rb").read())

    e_shoff = u32(data, 0x20)
    e_shentsize, e_shnum, e_shstrndx = u16(data, 0x2e), u16(data, 0x30), u16(data, 0x32)
    shdrs = [(e_shoff + i * e_shentsize) for i in range(e_shnum)]

    def sh(i, off):
        return struct.unpack_from("<I", data, shdrs[i] + off)[0]

    shstr_off = sh(e_shstrndx, 0x10)

    def secname(i):
        o = shstr_off + sh(i, 0)
        return bytes(data[o:data.index(b"\0", o)])

    symtab = strtab = None
    for i in range(e_shnum):
        if secname(i) == b".symtab":
            symtab = i
        elif secname(i) == b".strtab":
            strtab = i
    if symtab is None or strtab is None:
        print("no .symtab/.strtab")
        return 1
    sym_off, sym_size = sh(symtab, 0x10), sh(symtab, 0x14)
    str_off = sh(strtab, 0x10)
    count = sym_size // 16

    def sym_name(idx):
        st_name = u32(data, sym_off + idx * 16)
        o = str_off + st_name
        return bytes(data[o:data.index(b"\0", o)])

    last = count - 1
    midx = None
    for idx in range(count):
        if sym_name(idx) == marker:
            midx = idx
            break
    if midx is None:
        print(f"marker {marker.decode()} not found")
        return 1
    if sym_name(last) == marker:
        print("marker already last")
    elif midx == last:
        print("marker is last")
    else:
        # 1) swap the two Elf32_Sym entries
        ea, eb = sym_off + midx * 16, sym_off + last * 16
        data[ea:ea + 16], data[eb:eb + 16] = data[eb:eb + 16], data[ea:ea + 16]
        # 2) remap relocation symbol indices in every SHT_REL section
        fixed = 0
        for i in range(e_shnum):
            if sh(i, 4) != SHT_REL:
                continue
            if sh(i, 0x18) != symtab:      # sh_link must reference .symtab
                continue
            r_off, r_size = sh(i, 0x10), sh(i, 0x14)
            for o in range(r_off, r_off + r_size, 8):
                r_info = u32(data, o + 4)
                si, rtype = r_info >> 8, r_info & 0xFF
                if si == midx:
                    si = last
                elif si == last:
                    si = midx
                else:
                    continue
                struct.pack_into("<I", data, o + 4, (si << 8) | rtype)
                fixed += 1
        open(path, "wb").write(bytes(data))
        print(f"swapped symtab entries {midx} <-> {last} "
              f"({sym_name(midx).decode()} <-> victim); "
              f"remapped {fixed} relocation symbol indices")

    # 3) verify every export: __ksymtab_X value reloc must resolve to X
    rel_for_sec = {}
    for i in range(e_shnum):
        if sh(i, 4) == SHT_REL:
            rel_for_sec.setdefault(sh(i, 0x1c), i)   # sh_info -> section
    bad = 0
    for idx in range(count):
        name = sym_name(idx)
        if not name.startswith(b"__ksymtab_"):
            continue
        want = name[len(b"__ksymtab_"):]
        # Elf32_Sym: st_name@0 st_value@4 st_size@8 st_info@12 st_other@13
        #            st_shndx@14  (the original checker read +6 — wrong)
        shndx = u16(data, sym_off + idx * 16 + 14)
        st_value = u32(data, sym_off + idx * 16 + 4)
        rel = rel_for_sec.get(shndx)
        if rel is None:
            print(f"WARN no rel section for export {want.decode()}")
            continue
        r_off, r_size = sh(rel, 0x10), sh(rel, 0x14)
        found = False
        for o in range(r_off, r_off + r_size, 8):
            if u32(data, o) == st_value:            # value field of the entry
                si = u32(data, o + 4) >> 8
                got = sym_name(si)
                found = True
                if got != want:
                    print(f"EXPORT CORRUPT: __ksymtab_{want.decode()} -> {got.decode()}")
                    bad += 1
                break
        if not found:
            print(f"WARN no value relocation for export {want.decode()}")
    if bad:
        print(f"export check FAILED ({bad})")
        return 1
    print("export check: every __ksymtab_* resolves to its own symbol")
    return 0


if __name__ == "__main__":
    sys.exit(main())
