#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["pyelftools==0.33"]
# ///
"""Link the installer witness at the reference addresses and compare its bytes."""
import argparse
import hashlib
from pathlib import Path
import subprocess
import tempfile

from elftools.elf.elffile import ELFFile


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("reference", type=Path)
    p.add_argument("--object", type=Path, default=Path(__file__).with_name("install_module.o"))
    p.add_argument("--ld", default="arm-linux-gnueabi-ld")
    args = p.parse_args()
    # Only this reference has the recorded .text/.rodata/.bss placement.
    ref_sha = "0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45"
    if hashlib.sha256(args.reference.read_bytes()).hexdigest() != ref_sha:
        raise SystemExit("Expected the 350,830-byte _160 reference named in the README.")
    with args.reference.open("rb") as image, args.object.open("rb") as obj:
        ref, unit = ELFFile(image), ELFFile(obj)
        # The original static table records the imported functions' PLT addresses.
        symbols = {s.name.split("@")[0]: s["st_value"] for s in ref.get_section_by_name(".symtab").iter_symbols()
                   if s["st_value"] and s.name}
        imports = {s.name for s in unit.get_section_by_name(".symtab").iter_symbols()
                   if s.name and s["st_shndx"] == "SHN_UNDEF"}
        # Resolve addresses only. Code, string data and literal-pool contents come
        # from the compiled object; neither instructions nor relocations are masked.
        with tempfile.TemporaryDirectory() as temp:
            out = Path(temp) / "witness.elf"
            subprocess.run([args.ld, "-e", "install_modules", "-Ttext=0x2f970",
                            "--section-start=.rodata=0x36234", "--section-start=.bss=0x59dc0",
                            *(f"--defsym={name}={symbols[name]:#x}" for name in sorted(imports)),
                            "-o", out, args.object], check=True)
            with out.open("rb") as built:
                linked = ELFFile(built)
                for name, addr, size in (("install_modules", 0x2f970, 464),
                                         ("remove_modules", 0x2fb40, 132)):
                    symbol = linked.get_section_by_name(".symtab").get_symbol_by_name(name)[0]
                    if (symbol["st_value"], symbol["st_size"]) != (addr, size):
                        raise SystemExit(f"{name}: address or size differs")
                    image.seek(next(ref.address_offsets(addr, size)))
                    built.seek(next(linked.address_offsets(addr, size)))
                    data = built.read(size)
                    if data != image.read(size):
                        raise SystemExit(f"{name}: linked code differs")
                    print(f"{name}: {size} exact bytes, SHA-256 {hashlib.sha256(data).hexdigest()}")
                ro = linked.get_section_by_name(".rodata")
                image.seek(next(ref.address_offsets(ro["sh_addr"], ro["sh_size"])))
                if ro.data() != image.read(ro["sh_size"]):
                    raise SystemExit("Installer string data differs")
                print(f".rodata: {ro['sh_size']} exact bytes")


if __name__ == "__main__":
    main()
