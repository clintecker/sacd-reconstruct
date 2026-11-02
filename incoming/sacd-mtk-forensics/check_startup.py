#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["pyelftools==0.33"]
# ///
"""Rebuild four startup .text fragments and check their fully relocated bytes.

The linker layout is specific to the original _160. The output objects live in
a temporary directory. These experiments isolate code generation and are not a
recipe to build a complete development sysroot or replacement crt1.o.
"""
import argparse
import hashlib
import subprocess
from pathlib import Path
from tempfile import TemporaryDirectory

from elftools.elf.elffile import ELFFile

REFERENCE = "0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45"


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("reference", type=Path)
    for flag in ("gcc-src", "gcc-build", "glibc", "ports", "as", "ld"):
        p.add_argument("--" + flag, required=True, type=Path)
    args = p.parse_args()
    src, build = args.gcc_src.resolve(), args.gcc_build.resolve()
    glibc, ports = args.glibc.resolve(), args.ports.resolve()
    gas, ld = getattr(args, "as").resolve(), args.ld.resolve()
    if hashlib.sha256(args.reference.read_bytes()).hexdigest() != REFERENCE:
        raise SystemExit("This fixed-address startup experiment requires the reference _160 SHA-256 in the README.")
    cc = [build / "gcc/xgcc", f"-B{build}/gcc/", "-marm", "-march=armv6z", "-mfloat-abi=soft"]

    with TemporaryDirectory() as temp, args.reference.open("rb") as disk:
        work = Path(temp)
        reference = ELFFile(disk)

        def run(*cmd: str | Path) -> None:
            subprocess.run(cmd, cwd=work, check=True)

        def check(name: str, address: int, size: int, *flags: str) -> None:
            # The temporary executable uses the original symbol and section VAs
            # solely to give the PC-relative and absolute relocations the same values.
            run(gas, "-march=armv6z", "-meabi=5", f"{name}.s", "-o", f"{name}.o")
            run(ld, *flags, "-o", f"{name}.elf", f"{name}.o")
            with (work / f"{name}.elf").open("rb") as image:
                text = ELFFile(image).get_section_by_name(".text")
                disk.seek(next(reference.address_offsets(address, size)))
                if text["sh_addr"] != address or disk.read(size) != text.data():
                    raise SystemExit(f"Startup mismatch: {name}")
            print(f"  {address:#07x}  {size:3} bytes  {name}")

        run(*cc, "-E", "-P", "-x", "assembler-with-cpp", ports / "sysdeps/arm/elf/start.S", "-o", "start.s")
        check("start", 0xC818, 56, "-Ttext=0xc818", "-e", "_start",
              "--defsym=__libc_csu_fini=0x31908", "--defsym=main=0xe2d8",
              "--defsym=__libc_csu_init=0x3190c", "--defsym=__libc_start_main=0xc29c",
              "--defsym=abort=0xc248", "--defsym=__aeabi_unwind_cpp_pr0=0")

        # The ARM wrapper marks call_gmon_start noinline. Glibc splits the
        # generated initfini assembly into crti/crtn. Isolate the same .text
        # function here. This TU uses no declarations from stdlib.h.
        (work / "stdlib.h").touch()
        run(*cc, "-O2", "-fPIC", f"-I{glibc}", f"-I{work}", "-S",
            ports / "sysdeps/arm/initfini.c", "-o", "initfini.s")
        asm = (work / "initfini.s").read_text()
        label = asm.index("\ncall_gmon_start:\n")
        body = asm[asm.rindex("\t.text", 0, label):asm.index("\t.size\tcall_gmon_start,", label)]
        (work / "gmon.s").write_text(body + "\t.size call_gmon_start,.-call_gmon_start\n\t.weak __gmon_start__\n")
        # Reproduce the original GOT base and the offset of its weak gmon slot.
        (work / "gmon.ld").write_text("SECTIONS { .text 0xc850 : { *(.text) } "
                                     ".got 0x3e5b4 : { *(.got.plt) . = 0x210; *(.got) } }\n")
        check("gmon", 0xC850, 36, "-T", "gmon.ld")

        # Select the glibc-aware crtstuff path explicitly for the headerless
        # cross build. A normal SDK configures this using its target headers
        # and linker capabilities. -finhibit-size-directive is a CRT build flag.
        run(*cc, "-O2", "-std=gnu89", "-g0", "-finhibit-size-directive", "-fno-inline-functions",
            "-fno-exceptions", "-fno-zero-initialized-in-bss", "-fno-toplevel-reorder",
            "-fno-tree-vectorize", "-DIN_GCC", "-Dinhibit_libc", "-DUSE_PT_GNU_EH_FRAME",
            "-DCRT_BEGIN", f"-I{build}/gcc", f"-I{src}/gcc", f"-I{src}/include", f"-I{src}/libgcc",
            "-S", src / "gcc/crtstuff.c", "-o", "crtbegin_part.s")
        check("crtbegin_part", 0xC874, 76, "-Ttext=0xc874", "-e", "0xc874",
              "--section-start=.bss=0x56e00", "--section-start=.jcr=0x3e4b8")

        run(*cc, "-O2", "-fPIC", "-std=gnu99", "-DLIBC_NONSHARED",
            '-Dattribute_hidden=__attribute__((visibility("hidden")))', "-S",
            glibc / "csu/elf-init.c", "-o", "elf_init.s")
        check("elf_init", 0x31908, 108, "-Ttext=0x31908", "-e", "__libc_csu_init",
              "--section-start=.got=0x3e5b4", "--defsym=__init_array_start=0x3e4b0",
              "--defsym=__init_array_end=0x3e4b4", "--defsym=_init=0xc1ec")
        print("All 276 bytes match, including __libc_csu_fini.")


if __name__ == "__main__":
    main()
