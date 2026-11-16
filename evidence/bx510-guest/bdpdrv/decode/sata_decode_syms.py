#!/usr/bin/env python3
"""Symbol / string inventory for sata_mt85xx_mod.ko (ARM ET_REL kernel module).

Answers, deterministically, the questions the firmware-load decode needs:
  * where each interesting function lives (st_value/st_size, section index)
  * what literals exist in .rodata/.data (offsets + printable content), so a
    literal-pool reference in the disassembly can be resolved to a string
    instead of being eyeballed
  * which relocations target a given symbol (callers of a function)

Usage:
  sata_decode_syms.py --funcs                 # all FUNC symbols, addr/size
  sata_decode_syms.py --grep SUBSTR           # symbols whose name matches
  sata_decode_syms.py --strings               # printable literals + offsets
  sata_decode_syms.py --strrefs SUBSTR        # literal-pool entries matching
  sata_decode_syms.py --callers NAME          # relocs referencing NAME
  sata_decode_syms.py --sections
"""
import argparse
import re
import sys

from elftools.elf.elffile import ELFFile

KO = "/tmp/bdpdrv/sata_mt85xx_mod.ko"

FUNCS_OF_INTEREST = [
    # gcc inlined sata_mt85xx_SocReadMainCode into init_int_ldr; SocVerifyMainCode
    # survived as a real symbol -- see sata-fw-load.md §2.
    "sata_mt85xx_init_int_ldr",
    "sata_mt85xx_SocVerifyMainCode.clone.5",
    "sata_mt85xx_MTDRawRead.clone.6",
    "sata_mt85xx_parse_mtd_table",
    "sata_mt85xx_xfer_int_ldr_fw",
    "sata_mt85xx_port_start",
]


def load(path=KO):
    return ELFFile(open(path, "rb"))


def sections(elf):
    for i, s in enumerate(elf.iter_sections()):
        print(f"[{i:2d}] {s.name:24s} off=0x{s['sh_offset']:06x} "
              f"addr=0x{s['sh_addr']:08x} size=0x{s['sh_size']:06x} "
              f"entsize={s['sh_entsize']}")


def symtab(elf):
    sec = elf.get_section_by_name(".symtab")
    if sec is None:
        sys.exit("no .symtab -- module is stripped, decode target invalid")
    return sec


def funcs(elf, pattern=None):
    for s in symtab(elf).iter_symbols():
        if s["st_info"]["type"] != "STT_FUNC":
            continue
        if s["st_size"] == 0:
            continue
        name = s.name
        if pattern and pattern not in name:
            continue
        print(f"0x{s['st_value']:08x} size=0x{s['st_size']:06x} "
              f"shndx={s['st_shndx']:>3} {name}")


def objs(elf, pattern=None):
    for s in symtab(elf).iter_symbols():
        if s["st_info"]["type"] != "STT_OBJECT":
            continue
        name = s.name
        if pattern and pattern not in name:
            continue
        print(f"0x{s['st_value']:08x} size=0x{s['st_size']:06x} "
              f"shndx={s['st_shndx']:>3} {name}")


def strings(elf, minlen=8):
    """Print every printable run in each allocatable data section.

    ET_REL: st_value of a local symbol equals its offset within its section,
    so a literal-pool word in .text or an entry in .rodata is addressed by
    (section base in the loaded image) + offset; for a relocatable module the
    link-time offset within the section is what the relocation records.
    """
    for s in elf.iter_sections():
        if s.name not in (".rodata", ".data", ".rodata.str1.1",
                          ".rodata.str1.4", ".init.data", ".text"):
            continue
        data = s.data()
        for m in re.finditer(rb"[\x20-\x7e]{%d,}" % minlen, data):
            print(f"{s.name}+0x{m.start():06x}  {m.group().decode()}")


def strrefs(elf, needle):
    """Find printable literals matching needle, with section+offset, and then
    report every place in .text whose bytes equal a relocation-free copy of the
    pointer (pool entry) or whose reloc targets that offset."""
    hits = []
    for s in elf.iter_sections():
        if not s['sh_flags'] & 0x2:  # SHF_ALLOC
            continue
        try:
            data = s.data()
        except Exception:
            continue
        for m in re.finditer(re.escape(needle.encode()), data):
            hits.append((s.name, s['sh_offset'], m.start()))
    for secname, shoff, off in hits:
        print(f"literal in {secname} @ section+0x{off:06x} "
              f"(file off 0x{shoff + off:06x})")
    return hits


def callers(elf, name):
    """Report every relocation whose symbol name matches, with the location of
    the relocated word -- that word is the call/branch site (BL imm) or the
    literal-pool slot holding the function address."""
    targets = {}
    for s in symtab(elf).iter_symbols():
        if s.name == name:
            targets[s['st_value']] = s['st_shndx']
    for s in elf.iter_sections():
        if s["sh_type"] not in ("SHT_REL", "SHT_RELA"):
            continue
        for r in s.iter_relocations():
            sym = None
            try:
                sym = elf.get_symbol(r["r_info_sym"])
            except Exception:
                pass
            if sym is None:
                continue
            if sym.name == name or (sym['st_shndx'] in targets
                                    and name in sym.name):
                print(f"{s.name}: offset=0x{r['r_offset']:06x} "
                      f"type={r['r_info_type']} sym={sym.name}")


def ranges(elf, names):
    """Emit objdump command lines for exactly the requested functions."""
    by_name = {}
    for s in symtab(elf).iter_symbols():
        if s["st_info"]["type"] == "STT_FUNC" and s.name in names:
            by_name[s.name] = (s["st_value"], s["st_size"])
    for n in names:
        if n in by_name:
            v, sz = by_name[n]
            print(f"{n} 0x{v:08x} 0x{v + sz:08x}  # size 0x{sz:x}")
        else:
            print(f"{n} MISSING")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ko", default=KO)
    ap.add_argument("--sections", action="store_true")
    ap.add_argument("--funcs", nargs="?", const="", default=None)
    ap.add_argument("--objs", nargs="?", const="", default=None)
    ap.add_argument("--strings", action="store_true")
    ap.add_argument("--strrefs")
    ap.add_argument("--callers")
    ap.add_argument("--ranges", action="store_true")
    a = ap.parse_args()
    elf = load(a.ko)
    if a.sections:
        sections(elf)
    if a.funcs is not None:
        funcs(elf, a.funcs or None)
    if a.objs is not None:
        objs(elf, a.objs or None)
    if a.strings:
        strings(elf)
    if a.strrefs:
        strrefs(elf, a.strrefs)
    if a.callers:
        callers(elf, a.callers)
    if a.ranges:
        ranges(elf, FUNCS_OF_INTEREST)


if __name__ == "__main__":
    main()
