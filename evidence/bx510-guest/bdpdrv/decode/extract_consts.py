#!/usr/bin/env python3
"""Extract MMIO register constants from bdpdrv.ko and attribute each hit to its
owning function.

METHOD (lane-proven): Sony's driver touches registers through constants baked
into ARM literal pools (`ldr rX, [pc, #imm]` followed by a `.word`). The .ko is
an ET_REL, so at rest a literal-pool word is either
  (a) a plain constant -- what we want, or
  (b) zero/garbage with an R_ARM_ABS32/R_ARM_REL32 relocation pointing at a
      symbol -- NOT a constant, must be excluded.

A register may be stored as the exact physical address, or as a block base with
the register as a small load/store immediate offset (`ldr rX, [rBase, #0xf4]`).
This script therefore reports BOTH exact hits and base+offset candidates.

Ownership is keyed by SECTION: the .ko is ET_REL, so st_value is a section
offset and .text@0x100 and .rodata@0x100 are different addresses.

Note on aliases: guest-physical 0x7002_4xxx has top nibble 7, so the
`| 0xf0000000` alias (0xf002_4xxx) collides with any 0x0002_4xxx constant and
is searched but reported as an alias form, never assumed.

Usage:
  extract_consts.py --targets 0x7002420c,0x700240f4,...
  extract_consts.py --dump-bases          # every 0x70xxxxxx constant in the .ko
  extract_consts.py --sym <name> --disasm # disassemble one function
"""
import argparse
import bisect
import subprocess
from collections import defaultdict

from elftools.elf.elffile import ELFFile

KO = "/tmp/bdpdrv/bdpdrv.ko"
OBJDUMP = "/opt/homebrew/opt/llvm/bin/llvm-objdump"

ALIASES = (0x00000000, 0xF0000000, 0xC0000000)
MMIO_LO, MMIO_HI = 0x70000000, 0x71000000


def alias_forms(v):
    return [(v | a, a) for a in ALIASES]


def load_elf(path=KO):
    fh = open(path, "rb")
    return fh, ELFFile(fh)


def reloc_offsets(elf):
    """Offsets inside each section that carry a relocation (=> not a constant)."""
    out = defaultdict(set)
    for sec in elf.iter_sections():
        if not sec.name.startswith(".rel"):
            continue
        target = sec.name[4:]  # ".rel.text" -> ".text"
        for r in sec.iter_relocations():
            out[target].add(r["r_offset"])
    return out


def functions(elf):
    """{section_name: [(start, end, name)]} for symbols with non-zero st_size."""
    sym = elf.get_section_by_name(".symtab")
    by_sec = defaultdict(list)
    for s in sym.iter_symbols():
        if s["st_info"]["type"] not in ("STT_FUNC", "STT_NOTYPE"):
            continue
        idx = s["st_shndx"]
        if not isinstance(idx, int) or not s.name:
            continue
        start = s["st_value"] & ~1  # clear Thumb bit
        if not s["st_size"]:
            continue
        by_sec[elf.get_section(idx).name].append((start, start + s["st_size"], s.name))
    for v in by_sec.values():
        v.sort()
    return by_sec


def owning_function(by_sec, sec_name, offset):
    """Symbol in the same section whose [st_value, st_value+st_size) spans
    offset (innermost if nested); else nearest preceding enclosing symbol."""
    funcs = by_sec.get(sec_name) or []
    best = None
    for start, end, name in funcs:
        if start <= offset < end and (best is None or start > best[0]):
            best = (start, name)
    if best:
        return best[1], best[0]
    starts = [f[0] for f in funcs]
    i = bisect.bisect_right(starts, offset) - 1
    if i >= 0:
        return funcs[i][2] + " (nearest-preceding)", funcs[i][0]
    return None, None


def scan_words(elf, relocs):
    """Yield (section_name, offset, value) for every 4-byte word in an
    allocated section that is NOT relocation-covered."""
    for sec in elf.iter_sections():
        if not (sec["sh_flags"] & 0x2):  # SHF_ALLOC
            continue
        if sec["sh_type"] == "SHT_NOBITS":
            continue
        data = sec.data()
        skip = relocs.get(sec.name, set())
        for off in range(0, len(data) - 3, 4):
            if off in skip:
                continue
            yield sec.name, off, int.from_bytes(data[off:off + 4], "little")


def is_mmio_const(v):
    return MMIO_LO <= v < MMIO_HI


def scan_mmio(elf):
    """[(value, section, offset, func, func_addr)] for every plain constant word
    in the 0x7000_0000..0x70ff_ffff range."""
    relocs = reloc_offsets(elf)
    by_sec = functions(elf)
    rows = []
    for sec_name, off, v in scan_words(elf, relocs):
        if is_mmio_const(v):
            fn, faddr = owning_function(by_sec, sec_name, off)
            rows.append((v, sec_name, off, fn, faddr))
    return rows


def exact_hits(elf, targets):
    want = {}
    for t in targets:
        for form, alias in alias_forms(t):
            want[form] = (t, alias)
    hits = defaultdict(list)
    for v, sec_name, off, fn, faddr in scan_mmio(elf):
        if v in want:
            tgt, alias = want[v]
            hits[tgt].append((sec_name, off, v, alias, fn, faddr))
    return hits


def base_hits(elf, targets, span=0xFFF):
    """A register may be base + small immediate offset. Report mmio constants C
    such that target-C is a plausible ARM load/store immediate."""
    rows = scan_mmio(elf)
    out = []
    for tgt in targets:
        for v, sec_name, off, fn, faddr in rows:
            d = tgt - v
            if v != tgt and 0 <= d <= span:
                out.append((tgt, v, d, sec_name, off, fn, faddr))
    return out


def disasm(symbol=None, start=None, length=0x200):
    if symbol:
        cmd = [OBJDUMP, "-d", "--no-show-raw-insn",
               "--disassemble-symbols=" + symbol, KO]
    else:
        cmd = [OBJDUMP, "-d", "--no-show-raw-insn",
               "--start-address=%d" % start, "--stop-address=%d" % (start + length), KO]
    p = subprocess.run(cmd, capture_output=True, text=True)
    if p.returncode != 0:
        return "llvm-objdump failed: " + p.stderr
    return p.stdout


def fmt_addr(a):
    return "0x%x" % a if a is not None else "?"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--targets")
    ap.add_argument("--dump-bases", action="store_true")
    ap.add_argument("--base-match", action="store_true")
    ap.add_argument("--sym")
    ap.add_argument("--start", type=lambda s: int(s, 0))
    ap.add_argument("--len", type=lambda s: int(s, 0), default=0x200)
    ap.add_argument("--disasm", action="store_true")
    a = ap.parse_args()

    fh, elf = load_elf()

    if a.disasm:
        print(disasm(symbol=a.sym) if a.sym else disasm(start=a.start, length=a.len))
        return

    if a.dump_bases:
        for v, sec, off, fn, faddr in scan_mmio(elf):
            print(f"{v:#010x}  {sec:16s} off={off:#08x}  {fn or '?'} @ {fmt_addr(faddr)}")
        return

    targets = [int(x, 0) for x in a.targets.split(",")]
    hits = exact_hits(elf, targets)
    for t in targets:
        print(f"=== {t:#010x} ===")
        if hits.get(t):
            for sec, off, v, alias, fn, faddr in hits[t]:
                note = "" if not alias else f"  (alias form |{alias:#x})"
                print(f"  HIT {sec:16s} off={off:#08x} word={v:#010x}  {fn} @ {fmt_addr(faddr)}{note}")
        else:
            print("  no exact constant")
        if a.base_match:
            for tgt, v, d, sec, off, fn, faddr in base_hits(elf, [t]):
                print(f"  BASE {v:#010x}+{d:#05x} {sec:16s} off={off:#08x} {fn} @ {fmt_addr(faddr)}")
        print()


if __name__ == "__main__":
    main()
