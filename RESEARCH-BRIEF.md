# RESEARCH BRIEF: reverse-engineering a 2010-era MTK ARM toolchain build from binary forensics

I have reconstructed a closed-source ARM binary to **377/388 functions instruction-identical**
(compiled from recovered source with a toolchain I built from public releases). The last 13
mismatches cluster into two root causes I cannot solve from public releases alone. I need
help (a) identifying the exact toolchain, (b) confirming the remaining deltas are
behavior-neutral, and (c) any shortcuts to the exact build.

## The target

Binary: `sacd_extract_160` — a SACD-ripping daemon from the "AutoScript" USB exploit package
for certain Sony Blu-ray/SACD players. ELF32, ARM EABI5, **soft-float**, ARMv6z, glibc-2.9-era,
dynamically linked. It embeds a `sacd_read.ko` kernel module (linux-2.6.35, DWARF intact,
source path `/home/sym/sacd_read/sacd_read.c`, patches Sony CPSA via `kallsyms_lookup_name_diag`).
Application base = sacd-ripper v0.3.7 (Google Code era, commit de008ff) + community server-mode
additions (pthread listener on port 2002, nanopb protobuf protocol, wide-char status prints,
`L"SACD Daemon %ls active..."`, `L"0.37"`).

## Toolchain provenance (proven from the binary's own DWARF + codegen)

- DWARF `DW_AT_comp_dir`: `/usr/local/mtk-toolchain/gnuarm-4.4.1/cross-tools/usr/local/src/gcc-build/armv6z-mediatek-linux-gnueabi/libgcc`
- DWARF `DW_AT_producer`: `"GNU C 4.4.1"` for C files; `"GNU AS 2.19.1"` for `.S`
- MTK-style "gnuarm-4.4.1" crosstool layout (this naming is used by several leaked vendor
  crosstools). Target triplet literally `armv6z-mediatek-linux-gnueabi`.
- Built `-O0`, `-marm`, soft-float AAPCS, non-PIC, `-D_GNU_SOURCE`,
  `-D_FILE_OFFSET_BITS=64`.

## The smoking gun for a branch snapshot

Original's libgcc DWARF says `__divdi3` is declared at **libgcc2.c:1079**, `__udivdi3` at 1138.
The gcc-4.4.1 release tarball has them at 1076/1135. **Every release 4.4.2–4.4.7 has 1079/1138.**
So their gcc source = the 4.4 branch *after* 4.4.1 but the version string still said "4.4.1"
(i.e., a checkout between 2009-07-22 (4.4.1) and 2009-10-23 (4.4.2 release bump)).

I built gcc-4.4.2 release as proxy (`--target=arm-none-linux-gnueabi --with-arch=armv6z
--with-sysroot=<CodeSourcery 2009q3 glibc-2.9 sysroot>`, binutils 2.19.1). It reproduces 377/388.
The 4 codegen differences that remain, all at -O0, original-vs-4.4.2-release:

1. Original emits **no** dead `mov r0, r0` (0xe1a00000) after a `bl close` whose result is
   discarded and which is followed by `goto` (function `sacd_dev_input_open`); my 4.4.2 does.
   Both compilers DO emit such nops elsewhere (empty goto-target label blocks get a leading
   `mov r0,r0`, fprintf-const→fwrite folds at body level emit one) — those match.
2. `pthread_create(&id, 0, client_thread, (void*)&conn_s)` argument setup: original evaluates
   `&id` into a temp **r3** first (`sub r3,r11,#12; mov r0,r3; mov r1,#0; ldr r2,=fn; mov r3,#0`),
   mine uses temp r2 and a different order.
3. `memcpy(mod_file, "/tmp/", 6)` and `sprintf(cmd, "insmod %s minor=201", mod_file)`: original
   precomputes the **arg1** constant into a temp reg then places it; mine loads args directly
   left-to-right.
4. `__divdi3`/`__udivdi3`/`__gnu_{,u}ldivmod_helper` (libgcc, compiled -O2 by the stage-1 xgcc):
   same call structure (17 × bl to `__aeabi_uidivmod`/`__udivsi3`), but register allocation and
   block order differ (e.g. original's 13-instr `__gnu_uldivmod_helper` uses r4/r5 for the 64-bit
   remainder where mine uses different regs). `decl_line` proves their libgcc2.c/bpabi.c were
   4.4.2+ content, compiled by a gcc whose RA differs from my 4.4.2 release build.

**Question 1:** Which 4.4-branch commits/PRs between 4.4.1 and 4.4.2 touched ARM register
allocation/expand order, the `mov r0,r0` emission after calls, or libgcc RA at -O2? Is there a
known arm crosstool ("gnuarm") used by MediaTek ~2009-2010 whose source/patches are public?
(e.g. android-era MTK SDK toolchains, "gnuarm" from gnuarm.com successors, Crosstool-NG
configs for `armv6z-mediatek-linux-gnueabi`.) Is there a public snapshot archive of the gcc
4.4 branch circa Aug-Oct 2009 I can bisect against the four markers above?

## glibc/csu residuals

`__libc_csu_init`, `_start`, `call_gmon_start` (glibc csu) and `frame_dummy`,
`__do_global_dtors_aux` (gcc crtbegin) differ in bytes from mine (CodeSourcery 2009q3
glibc-2.9 sysroot objects). Same contracts, just different builds.

**Question 2:** What glibc version/patch set did "gnuarm-4.4.1" MTK crosstools ship (2.9?
2.10? 2.11?), and is that toolchain or its source mirrored anywhere? (Knowing the glibc
release would let me rebuild matching csu bytes.)

**Question 3:** Their link binds `__aeabi_unwind_cpp_pr0@**GCC_3.5**` (versioned) plus nothing
else from the unwinder; my link (FSF 4.4.2 + CS 2.19.1 binutils, glibc 2.9 sysroot) imports
`__aeabi_unwind_cpp_pr0/pr1/pr2` **unversioned** and `__gnu_Unwind_Find_exidx@GLIBC_2.4`,
`__cxa_*` extras. What controls this set — the libgcc_s the gcc was configured against, the
crtbegin, or a gcc configure flag (e.g. `--disable-sjlj-exceptions`, unwind header selection)?
Both should resolve on a normal ARM linux runtime, but I'd like to understand it.

## Runtime equivalence (the actual goal)

The goal is a drop-in replacement that runs on the player hardware. Current runtime-interface
parity: identical GLIBC version-needs (`GLIBC_2.4` only), identical dynamic symbol export set
(they linked `--export-dynamic` — ~400 symbols; I match now), identical embedded .ko blob
(byte-for-byte), identical ioctl ABI to the module. The 13 function residuals are standard
implementations / dead nops / arg-eval order — believed behavior-neutral.

**Question 4:** Any known pitfalls differentiating two ARM binaries under qemu-user
(qemu-arm) for wide-char stdout (`fwprintf` + `setlocale(LC_ALL,"")`), pthread
create/join paths, or `-L sysroot` library binding that could produce false diffs in a
differential test?

**Question 5:** Does anyone know of published source for this specific server ("SACD Daemon
0.37", port 2002, nanopb `ServerRequest`/`ServerResponse` protocol with
DISC_OPEN/DISC_READ/DISC_CLOSE, writes via insmod'd `sacd_read.ko` with mknod c 10 201)?
It pairs with sacd-ripper v0.3.7. If the community server source exists anywhere it would
let me verify my ~20 decoded source deltas independently.

## What I can provide on request

Per-function disassembly diffs (llvm-objdump, normalized), the full `decl_line` evidence,
the embedded module's DWARF, my reconstructed source tree, the fn_diff harness, and exact
codegen micro-tests (single .c files) reproducing each of the four markers under 4.4.2.
