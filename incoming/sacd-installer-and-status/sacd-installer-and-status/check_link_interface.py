#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["pyelftools==0.33"]
# ///
"""Compare the loader-facing sets and compact unwind entries of two ARM ELFs."""
import argparse
from pathlib import Path
import struct

from elftools.elf.elffile import ELFFile


def inspect(path: Path) -> dict:
    with path.open("rb") as fp:
        elf = ELFFile(fp)
        dynamic = elf.get_section_by_name(".dynamic")
        syms = elf.get_section_by_name(".dynsym")
        versions = elf.get_section_by_name(".gnu.version")
        needs = elf.get_section_by_name(".gnu.version_r")
        version_name = {}
        if needs:
            for library, entries in needs.iter_versions():
                for entry in entries:
                    version_name[entry["vna_other"] & 0x7fff] = (library.name, entry.name)
        imports, exports = set(), set()
        for i, sym in enumerate(syms.iter_symbols()):
            if not sym.name:
                continue
            binding, kind = sym["st_info"]["bind"], sym["st_info"]["type"]
            if sym["st_shndx"] == "SHN_UNDEF":
                index = versions.get_symbol(i).entry["ndx"] if versions else None
                version = version_name.get(index & 0x7fff, ("", "")) if isinstance(index, int) else ("", "")
                imports.add((sym.name, binding, kind, *version))
            elif binding in ("STB_GLOBAL", "STB_WEAK") and sym["st_other"]["visibility"] in ("STV_DEFAULT", "STV_PROTECTED"):
                exports.add(sym.name)
        # Compare compact EHABI records by function identity and descriptor.
        # For this reference all five records are inline or CANTUNWIND.
        target_names = {}
        for sym in elf.get_section_by_name(".symtab").iter_symbols():
            if sym["st_info"]["type"] == "STT_FUNC" and sym["st_shndx"] != "SHN_UNDEF":
                target_names.setdefault(sym["st_value"], set()).add(sym.name)
        idx = elf.get_section_by_name(".ARM.exidx")
        unwind = []
        for i,(relative, desc) in enumerate(struct.iter_unpack("<II", idx.data())):
            delta = relative & 0x7fffffff
            if delta & 0x40000000: delta -= 0x80000000
            address = (idx["sh_addr"] + 8*i + delta) & 0xffffffff
            names = tuple(sorted(target_names.get(address, {f"unresolved@{address:#x}"})))
            unwind.append((names, desc))
        return {"DT_NEEDED (order)": tuple(t.needed for t in dynamic.iter_tags("DT_NEEDED")),
                "exported names": exports, "undefined symbols (binding, type, DSO and version)": imports,
                ".ARM.exidx (function and descriptor)": tuple(unwind)}


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("reference", type=Path)
    p.add_argument("candidate", type=Path)
    args = p.parse_args()
    ref, candidate = inspect(args.reference), inspect(args.candidate)
    ok = True
    for name, expected in ref.items():
        actual = candidate[name]
        matches = expected == actual
        print(f"{name}: {'MATCH' if matches else 'DIFF'} ({len(expected)} reference, {len(actual)} candidate)")
        if not matches:
            ok = False
            for title, items in (("reference only", set(expected)-set(actual)), ("candidate only", set(actual)-set(expected))):
                if items: print(f"  {title}: {sorted(items)}")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
