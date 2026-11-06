#!/usr/bin/env python3
"""release_build.py — build the release candidate ELF from tracked sources.

This is the `make verify` engine (issues #3/#4). It reproduces the
experimental GNU 4.4.1 / CodeSourcery link against the *tracked* tree:

  - tool/install.c and tool/main.c compile directly — no witness
    substitution and no silent string repair. The status strings and
    installer shapes are asserted instead, so a source regression fails
    the build rather than being masked.
  - the four __FILE__ TUs compile with `#line 1 "/root/sacd-ripper/..."`
    staging plus `-iquote` of their physical directory (sudo-free).
  - GNU crtbegin.o/crtend.o, glibc 2.9 elf-init/stat64/fstat64 and the
    division helpers build from source; the pinned CodeSourcery 2009q3
    libgcc_s.so.1 provides __aeabi_unwind_cpp_pr0 dynamically.

Environment prerequisites (pinned in verify output):
  --gcc-src   GNU gcc 4.4.1 release source tree
  --gcc-build configured+built gcc 4.4.1 tree (gcc/xgcc present)
  --glibc-src extracted glibc 2.9 (+ glibc-ports 2.9) source
  --sdk       extracted arm-2009q3-67 tarball
  --as/--ld   GNU as/ld 2.19.1 (built with --with-sysroot)

Prints the image path and SHA-256, and a link map next to them.
"""

import argparse
import hashlib
import os
import re
import subprocess
import sys
from pathlib import Path

LIBGCC_S_SHA = "5068e1ea0c56591305d3c605d9fbd3e900ae8d134d13bc32a65e3fe1ddbec6d4"
CANONICAL_FILES = {
    "libdstdec/buffer_pool.c",
    "libdstdec/dst_decoder.c",
    "libid3/id3.c",
    "libsacd/scarletbook_read.c",
}


def run(*cmd, cwd=None, quiet=False):
    if not quiet:
        print("+", " ".join(str(c) for c in cmd))
    res = subprocess.run([str(c) for c in cmd], cwd=str(cwd) if cwd else None)
    if res.returncode != 0:
        raise SystemExit("command failed (%d): %s" % (res.returncode, cmd[0]))


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def main():
    p = argparse.ArgumentParser(description=__doc__)
    here = Path(__file__).resolve().parent          # tools/
    repo = here.parent                              # sacd_reconstruct/
    p.add_argument("--gcc-src", default=os.path.expanduser("~/gcc-4.4.1"), type=Path)
    p.add_argument("--gcc-build", default=os.path.expanduser("~/g441obj"), type=Path)
    p.add_argument("--glibc-src", default=os.path.expanduser("~/glibc-2.9-build/glibc-2.9"), type=Path)
    p.add_argument("--sdk", default=os.path.expanduser("~/arm-2009q3"), type=Path)
    p.add_argument("--as", dest="gas", default=os.path.expanduser("~/gnuarm/bin/arm-none-linux-gnueabi-as"), type=Path)
    p.add_argument("--ld", default=os.path.expanduser("~/gnuarm/bin/arm-none-linux-gnueabi-ld"), type=Path)
    p.add_argument("--ar", default="ar")
    p.add_argument("--out", default=repo / "reconstruct/release", type=Path)
    p.add_argument("--profile", choices=("parity", "enhanced"), default="parity",
                   help="parity: the frozen reference build (asserts the legacy "
                        "verified installer/status shapes). enhanced: the "
                        "the repaired tree branch build (asserts the B01-B12 fixed "
                        "shapes instead — regressions still fail the build).")
    args = p.parse_args()

    gcc_src, gcc_build = args.gcc_src.resolve(), args.gcc_build.resolve()
    glibc = args.glibc_src.resolve()
    repo = repo.resolve()
    recon = repo / "reconstruct"
    sysroot = args.sdk.resolve() / "arm-none-linux-gnueabi/libc"
    lib, usr = sysroot / "lib", sysroot / "usr"
    gas, ld, out = args.gas.resolve(), args.ld.resolve(), args.out.resolve()
    tools = repo / "incoming/sacd-mtk-forensics"

    if not (gcc_build / "gcc/xgcc").exists():
        raise SystemExit("gcc-build has no gcc/xgcc: %s" % gcc_build)
    if not (gcc_src / "gcc/crtstuff.c").exists():
        raise SystemExit("gcc-src has no gcc/crtstuff.c: %s" % gcc_src)
    if not (glibc / "csu/elf-init.c").exists():
        raise SystemExit("glibc-src missing csu/elf-init.c: %s" % glibc)
    dso = lib / "libgcc_s.so.1"
    if sha256(dso) != LIBGCC_S_SHA:
        raise SystemExit("libgcc_s.so.1 does not match the pinned CS 2009q3 DSO")

    out.mkdir(parents=True, exist_ok=True)
    if any(out.glob("*")) and not (out / "sacd_extract_160_release").exists():
        pass  # allow re-runs; staging files get overwritten
    inputs = out / "inputs"
    inputs.mkdir(exist_ok=True)

    cc = [gcc_build / "gcc/xgcc", f"-B{gcc_build}/gcc/", "-marm", "-march=armv6z",
          "-mfloat-abi=soft", "-mabi=aapcs-linux"]
    arm_flags = ["-march=armv6z", "-meabi=5"]

    def c_object(src, obj, options, cwd=None):
        asm = obj.with_suffix(".s")
        run(*cc, *options, "-S", src, "-o", asm, quiet=True)
        run(gas, *arm_flags, asm, "-o", obj, quiet=True)
        return obj

    target_headers = ["-isystem", usr / "include"]
    app_flags = ["-O0", "-fno-pic", "-D_GNU_SOURCE", "-D_FILE_OFFSET_BITS=64",
                 "-DLIBSACD_INTERNAL", *target_headers,
                 *[f"-I{recon / d}" for d in
                   ("tool", "libsacd", "libcommon", "libcommon/sys", "libid3", "libdstdec")]]

    names = re.findall(r"^\s*((?:tool|libsacd|libcommon|libdstdec|libid3)/[^ \t\\\n]+\.c)[ \t]*\\?$",
                       (recon / "Makefile").read_text(), re.M)
    if len(names) != 45 or len(set(names)) != len(names):
        raise SystemExit("Expected the 45 C sources enumerated by the Makefile, got %d" % len(names))

    # Regression guards (review directive): the tracked sources must already
    # carry the fixes — never repair them here. Profile selects which shape:
    # parity guards the frozen reference tree; enhanced guards the fixed tree.
    install_src = (recon / "tool/install.c").read_text()
    main_src = (recon / "tool/main.c").read_text()
    if args.profile == "parity":
        if 'strcpy(mod_file, "/tmp/")' not in install_src or "mod_file[26]" not in install_src:
            raise SystemExit("tool/install.c lost the verified installer shape")
    else:
        # The B10/B11 fixed installer shapes (enhanced/DELTA.md): atomic
        # temp creation, shell-free loader, device-interface validation.
        for marker in ("mkstemp", "execvp", "S_ISCHR", "SACD_IOC_INIT"):
            if marker not in install_src:
                raise SystemExit("tool/install.c lost the ENHANCED installer "
                                 f"shape (missing: {marker})")
        # The wave-1/2 fixed main.c shapes: send-all, owned connections,
        # detached workers, async-signal-safe handler.
        for marker in ("socket_send_all", "pthread_detach", "volatile sig_atomic_t"):
            if marker not in main_src:
                raise SystemExit("tool/main.c lost the ENHANCED shape "
                                 f"(missing: {marker})")
    if main_src.count('L"connected" : L"none"') != 1:
        raise SystemExit("tool/main.c lost the L\"connected\"/L\"none\" status strings")

    objects = []
    for name in names:
        original = recon / name
        source = original
        if name in CANONICAL_FILES:
            source = inputs / original.name
            source.write_bytes(
                f'#line 1 "/root/sacd-ripper/libs/{name}"\n'.encode()
                + original.read_bytes())
        flags = [*app_flags, "-iquote", original.parent]
        if name == "libsacd/sacd_reader.c":
            flags += ["-include", "linux/limits.h"]
        objects.append(c_object(source, out / (name.replace("/", "_")[:-2] + ".o"), flags))
        print("compiled", name)

    # embedded kernel module via .incbin (avoids the FSF ld -b binary bug)
    ko = out / "sacd_read_ko.o"
    blob_asm = inputs / "module.s"
    blob_asm.write_text(
        ".data\n.globl _binary_sacd_read_ko_start,_binary_sacd_read_ko_end,_binary_sacd_read_ko_size\n"
        '_binary_sacd_read_ko_start:\n.incbin "sacd_read.ko"\n_binary_sacd_read_ko_end:\n'
        ".set _binary_sacd_read_ko_size,_binary_sacd_read_ko_end-_binary_sacd_read_ko_start\n")
    run(gas, *arm_flags, blob_asm, "-o", ko, cwd=recon, quiet=True)

    # GNU crtbegin/crtend from source (CS crtbegin imports pr1 via frame_dummy)
    gcc_includes = [f"-I{gcc_build}/gcc", f"-I{gcc_src}/gcc",
                    f"-I{gcc_src}/include", f"-I{gcc_src}/libgcc"]
    crt_flags = ["-O2", "-g0", "-finhibit-size-directive", "-fno-inline-functions",
                 "-fno-exceptions", "-fno-zero-initialized-in-bss",
                 "-fno-toplevel-reorder", "-fno-tree-vectorize", "-DIN_GCC",
                 *gcc_includes, *target_headers]
    for symbol, stem in (("CRT_BEGIN", "crtbegin"), ("CRT_END", "crtend")):
        c_object(gcc_src / "gcc/crtstuff.c", out / (stem + ".o"),
                 [*crt_flags, "-D" + symbol])
        print("built", stem + ".o")

    # glibc 2.9 nonshared wrappers from source (CS copies carry extra unwind)
    glibc_flags = ["-O2", "-std=gnu99", "-fPIC", "-fno-unwind-tables",
                   "-fno-asynchronous-unwind-tables", "-D__NO_INLINE__",
                   "-D_GNU_SOURCE", "-DLIBC_NONSHARED",
                   '-Dattribute_hidden=__attribute__((visibility("hidden")))',
                   *target_headers]
    glibc_objects = [c_object(glibc / n, out / (Path(n).stem + ".o"), glibc_flags)
                     for n in ("csu/elf-init.c", "io/stat64.c", "io/fstat64.c")]
    print("built glibc 2.9 elf-init/stat64/fstat64")

    # division helpers + private GNU libgcc.a from lib1funcs
    div = out / "division"
    run("sh", tools / "build_objects.sh", gcc_src, gcc_build, gas, div)
    arm = gcc_src / "gcc/config/arm"
    members = ["_aeabi_uldivmod", "_arm_addsubdf3", "_arm_addsubsf3", "_arm_cmpdf2",
               "_arm_fixdfsi", "_arm_muldivdf3", "_arm_muldivsf3", "_arm_truncdfsf2",
               "_divsi3", "_dvmd_lnx", "_udivsi3", "_arm_cmpsf2", "_arm_unorddf2",
               "_aeabi_ldivmod", "_aeabi_lcmp", "_call_via_rX"]
    member_objects = []
    for member in members:
        asm, obj = out / (member + ".s"), out / (member + ".o")
        run(*cc, "-fPIC", "-DHIDE_EXPORTS", "-DL" + member, f"-I{arm}",
            "-xassembler-with-cpp", "-E", "-P", arm / "lib1funcs.asm", "-o", asm, quiet=True)
        run(gas, *arm_flags, asm, "-o", obj, quiet=True)
        member_objects.append(obj)
    run(args.ar, "crs", out / "libgcc.a", *member_objects)
    print("built private libgcc.a (%d members)" % len(members))

    # the release link
    image = out / "sacd_extract_160_release"
    run(ld, "-m", "armelf_linux_eabi", "--export-dynamic",
        "--dynamic-linker", "/lib/ld-linux.so.3",
        "-e", "_start", f"-Map={out}/release.map", "-o", image,
        usr / "lib/crt1.o", usr / "lib/crti.o", out / "crtbegin.o", *objects, ko,
        div / "bpabi.o", div / "_divdi3.o", div / "_udivdi3.o",
        "-rpath-link", lib, "--start-group", "--exclude-libs", "libgcc.a",
        out / "libgcc.a", lib / "libpthread.so.0",
        "--as-needed", lib / "libgcc_s.so.1", "--no-as-needed", lib / "libc.so.6",
        *glibc_objects, usr / "lib/libc_nonshared.a", "--end-group",
        out / "crtend.o", usr / "lib/crtn.o")
    print()
    print("RELEASE IMAGE: %s" % image)
    print("SHA-256:      %s" % sha256(image))
    print("MAP:          %s" % (out / "release.map"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
