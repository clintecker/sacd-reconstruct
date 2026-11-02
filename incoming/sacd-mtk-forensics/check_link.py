#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["pyelftools==0.33"]
# ///
"""Use a real ARM linker to place the rebuilt division functions at the reference addresses."""

import argparse
import hashlib
import subprocess
from pathlib import Path
from tempfile import TemporaryDirectory

from elftools.elf.elffile import ELFFile


def symbol(elf: ELFFile, name: str):
    """Return one defined symbol, allowing duplicate entries at the same address."""
    table = elf.get_section_by_name(".symtab")
    if table is None:
        raise ValueError("the reference and the test link both need .symtab")
    matches = [s for s in table.get_symbol_by_name(name) or [] if s["st_shndx"] != "SHN_UNDEF"]
    if len({(s["st_value"], s["st_size"]) for s in matches}) != 1:
        raise ValueError(f"missing or ambiguous symbol {name}")
    return matches[0]


def function_bytes(elf: ELFFile, name: str) -> tuple[int, bytes]:
    sym = symbol(elf, name)
    address, size = sym["st_value"], sym["st_size"]
    offset = next(elf.address_offsets(address, size), None)
    if not size or offset is None:
        raise ValueError(f"cannot map {name} into the file")
    elf.stream.seek(offset)
    return address, elf.stream.read(size)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("reference", type=Path)
    parser.add_argument("--ld", default="arm-linux-gnueabi-ld")
    parser.add_argument("--objects", type=Path, default=Path(__file__).parent / "objects")
    args = parser.parse_args()
    names = ("__gnu_uldivmod_helper", "__gnu_ldivmod_helper", "__divdi3", "__udivdi3")
    with args.reference.open("rb") as reference_file, TemporaryDirectory() as work:
        reference = ELFFile(reference_file)
        start = symbol(reference, names[0])["st_value"]
        image = Path(work) / "comparison.elf"
        # These symbols give GNU ld the actual destinations of the BLs.
        symbols = [f"--defsym={n}={symbol(reference, n)['st_value']:#x}"
                   for n in ("__aeabi_uidiv", "__aeabi_uidivmod")]
        # The four functions carry an R_ARM_NONE dependency on pr0. The temporary
        # link only compares .text and never runs. Zero is a test-link placeholder.
        subprocess.run([args.ld, f"-Ttext={start:#x}", "-e", names[0], *symbols,
                        "--defsym=__aeabi_unwind_cpp_pr0=0", "-o", image,
                        *(args.objects / f for f in ("bpabi.o", "_divdi3.o", "_udivdi3.o"))],
                       check=True)
        actual = bytearray()
        with image.open("rb") as linked_file:
            linked = ELFFile(linked_file)
            for name in names:
                addr, want = function_bytes(reference, name)
                check_addr, got = function_bytes(linked, name)
                if check_addr != addr or got != want:
                    raise SystemExit(f"Mismatch in {name}: ref {addr:#x}/{len(want)}, linked {check_addr:#x}/{len(got)}")
                actual.extend(got)
                print(f"  {addr:#07x}  {len(got):4} bytes  {name}")
        print(f"All {len(actual)} bytes match. SHA-256 {hashlib.sha256(actual).hexdigest()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
