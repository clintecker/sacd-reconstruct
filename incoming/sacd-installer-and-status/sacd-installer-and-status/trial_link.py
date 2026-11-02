#!/usr/bin/env python3
"""Repeat the experimental GNU 4.4.1 / CodeSourcery link using a separate build directory.

This is a recipe for the 694f27d repository layout and an already built GNU
compiler. It stages all inputs under --out and leaves the checkout untouched.
"""
import argparse
import hashlib
from pathlib import Path
import re
import subprocess


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("repo", "gcc-src", "gcc-build", "glibc-src", "sdk", "as", "ld", "out"):
        parser.add_argument("--" + name, required=True, type=Path)
    parser.add_argument("--ar", default="ar")
    args = parser.parse_args()
    repo = args.repo.resolve() / "reconstruct"
    gcc_src, gcc_build = args.gcc_src.resolve(), args.gcc_build.resolve()
    glibc = args.glibc_src.resolve()
    tools = Path(__file__).resolve().parent
    sysroot = args.sdk.resolve() / "arm-none-linux-gnueabi/libc"
    gas, ld, out = getattr(args,"as").resolve(), args.ld.resolve(), args.out.resolve()
    lib = sysroot / "lib"
    usr = sysroot / "usr"
    if hashlib.sha256((lib / "libgcc_s.so.1").read_bytes()).hexdigest() != "5068e1ea0c56591305d3c605d9fbd3e900ae8d134d13bc32a65e3fe1ddbec6d4":
        raise SystemExit("Choose the default multilib of CodeSourcery 2009q3-67.")
    out.mkdir(parents=True, exist_ok=True)
    if any(out.iterdir()):
        raise SystemExit("Use an empty --out for this experiment.")
    inputs = out / "inputs"
    inputs.mkdir()
    cc = [gcc_build / "gcc/xgcc", f"-B{gcc_build}/gcc/", "-marm", "-march=armv6z",
          "-mfloat-abi=soft", "-mabi=aapcs-linux"]
    arm_flags = ["-march=armv6z", "-meabi=5"]

    def run(*cmd: str | Path, cwd: Path = out) -> None:
        subprocess.run(cmd, cwd=cwd, check=True)

    def c_object(src: Path, obj: Path, options: list) -> Path:
        asm = obj.with_suffix(".s")
        run(*cc, *options, "-S", src, "-o", asm)
        run(gas, *arm_flags, asm, "-o", obj)
        return obj

    target_headers = ["-isystem", usr / "include"]
    app_flags = ["-O0", "-fno-pic", "-D_GNU_SOURCE", "-D_FILE_OFFSET_BITS=64", "-DLIBSACD_INTERNAL",
                 *target_headers, *[f"-I{repo / d}" for d in ("tool","libsacd","libcommon","libcommon/sys","libid3","libdstdec")]]
    names = re.findall(r"^\s*((?:tool|libsacd|libcommon|libdstdec|libid3)/[^ \t\\\n]+\.c)[ \t]*\\?$",
                       (repo / "Makefile").read_text(), re.M)
    if len(names) != 45 or len(set(names)) != len(names):
        raise SystemExit("Expected the 45 C sources enumerated by the 694f27d Makefile.")
    canonical = {"libdstdec/buffer_pool.c", "libdstdec/dst_decoder.c", "libid3/id3.c", "libsacd/scarletbook_read.c"}
    objects = []
    for name in names:
        original = repo / name
        source = original
        if name == "tool/install.c":
            source = tools / "install_module.c"
        elif name == "tool/main.c":
            # Apply the already established status-string fix to the local input.
            source = inputs / "main.c"
            raw = original.read_bytes()
            short = b'L"c" : L"n"'
            full = b'L"connected" : L"none"'
            if raw.count(short) + raw.count(full) != 1:
                raise SystemExit("Check the client-status source expression before using this recipe.")
            source.write_bytes(raw.replace(short, full))
        elif name in canonical:
            # Change the logical filename. Keep the original input's physical
            # include directory and all source lines following the directive.
            source = inputs / original.name
            source.write_bytes(f'#line 1 "/root/sacd-ripper/libs/{name}"\n'.encode() + original.read_bytes())
        flags = [*app_flags, "-iquote", original.parent]
        if name == "libsacd/sacd_reader.c":
            # The stage-one compiler was configured without target headers.
            flags += ["-include", "linux/limits.h"]
        objects.append(c_object(source, out / (name.replace("/", "_")[:-2]+".o"),flags))

    # Embed the exact checked-in module with the same linker-symbol contract.
    ko = out / "sacd_read_ko.o"
    blob_asm = inputs / "module.s"
    blob_asm.write_text(".data\n.globl _binary_sacd_read_ko_start,_binary_sacd_read_ko_end,_binary_sacd_read_ko_size\n"
                        '_binary_sacd_read_ko_start:\n.incbin "sacd_read.ko"\n_binary_sacd_read_ko_end:\n'
                        ".set _binary_sacd_read_ko_size,_binary_sacd_read_ko_end-_binary_sacd_read_ko_start\n")
    run(gas, *arm_flags, blob_asm, "-o", ko, cwd=repo)

    # Build GCC startup objects with the target glibc headers. The CS crtbegin
    # pulls in pr1 through frame_dummy, even when the shared DSO supplies pr0.
    gcc_includes = [f"-I{gcc_build}/gcc", f"-I{gcc_src}/gcc", f"-I{gcc_src}/include", f"-I{gcc_src}/libgcc"]
    crt_flags = ["-O2", "-g0", "-finhibit-size-directive", "-fno-inline-functions", "-fno-exceptions",
                 "-fno-zero-initialized-in-bss", "-fno-toplevel-reorder", "-fno-tree-vectorize", "-DIN_GCC",
                 *gcc_includes, *target_headers]
    for symbol, stem in (("CRT_BEGIN","crtbegin"), ("CRT_END","crtend")):
        c_object(gcc_src / "gcc/crtstuff.c", out / (stem + ".o"), [*crt_flags, "-D"+symbol])

    # The CS libc_nonshared.a entries have extra unwind descriptors. Compile
    # these three actual glibc 2.9 source files against the target headers.
    glibc_flags = ["-O2", "-std=gnu99", "-fPIC", "-fno-unwind-tables", "-fno-asynchronous-unwind-tables",
                   "-D__NO_INLINE__", "-D_GNU_SOURCE", "-DLIBC_NONSHARED",
                   '-Dattribute_hidden=__attribute__((visibility("hidden")))', *target_headers]
    glibc_objects = [c_object(glibc / n, out / (Path(n).stem+".o"), glibc_flags)
                     for n in ("csu/elf-init.c", "io/stat64.c", "io/fstat64.c")]

    # Rebuild the three proven division objects using the earlier kit included
    # in the repository. Use a GNU archive of source-built soft-float helpers.
    div = out / "division"
    recipe = repo.parent / "incoming/sacd-mtk-forensics/build_objects.sh"
    run("sh", recipe, gcc_src, gcc_build, gas, div)
    arm = gcc_src / "gcc/config/arm"
    members = ["_aeabi_uldivmod","_arm_addsubdf3","_arm_addsubsf3","_arm_cmpdf2","_arm_fixdfsi",
               "_arm_muldivdf3","_arm_muldivsf3","_arm_truncdfsf2","_divsi3","_dvmd_lnx","_udivsi3",
               "_arm_cmpsf2","_arm_unorddf2","_aeabi_ldivmod","_aeabi_lcmp","_call_via_rX"]
    member_objects = []
    for member in members:
        asm, obj = out/(member+".s"), out/(member+".o")
        run(*cc, "-fPIC", "-DHIDE_EXPORTS", "-DL"+member, f"-I{arm}", "-xassembler-with-cpp", "-E", "-P",
            arm / "lib1funcs.asm", "-o", asm)
        run(gas, *arm_flags, asm, "-o", obj)
        member_objects.append(obj)
    run(args.ar, "crs", out/"libgcc.a", *member_objects)

    # The shared compatibility input is only a link-time provider. Hide exports
    # from the private arithmetic archive and keep exports from the application.
    image = out / "sacd_extract_160_trial"
    run(ld, "-m","armelf_linux_eabi","--export-dynamic","--dynamic-linker","/lib/ld-linux.so.3",
        "-e","_start",f"-Map={out}/trial.map","-o",image,
        usr/"lib/crt1.o", usr/"lib/crti.o", out/"crtbegin.o", *objects, ko,
        div/"bpabi.o",div/"_divdi3.o",div/"_udivdi3.o",
        "-rpath-link",lib,"--start-group","--exclude-libs","libgcc.a",out/"libgcc.a",lib/"libpthread.so.0",
        "--as-needed",lib/"libgcc_s.so.1","--no-as-needed",lib/"libc.so.6",*glibc_objects,
        usr/"lib/libc_nonshared.a","--end-group",out/"crtend.o",usr/"lib/crtn.o")
    print(f"{image}\nSHA-256 {hashlib.sha256(image.read_bytes()).hexdigest()}")


if __name__ == "__main__":
    main()
