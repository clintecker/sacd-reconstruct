# sacd_extract_160 — reconstruction

Full source reconstruction of the closed-source ARM binary `sacd_extract_160`
(SACD-ripping daemon from the "AutoScript" USB packages for certain Sony
BD/SACD players), engineered back to byte-level parity with the original.

## Status

- **377/388 functions instruction-identical** (normalized disassembly,
  `tools/fn_diff.py`)
- **Runtime differential: 12/12 cases byte-identical** under qemu-arm
  (stdout/stderr/exit codes), including the LOG subsystem and the full
  install_modules chain — see `evidence/runtime-differential/RESULTS.md`
- Remaining 13 diffs: toolchain-furnished startup/libgcc objects + a handful
  of compiler-build micro-differences; all believed behavior-neutral, and
  reproducible from stock GNU GCC 4.4.1 + glibc 2.9 + glibc-ports 2.9 +
  binutils 2.19.1 (see RESEARCH-BRIEF.md and DELTA.md for the open items)

## Layout

- `original/` — the reference binary (SHA-256
  `0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45`)
- `reconstruct/` — the buildable reconstruction (compiles to
  `reconstruct/sacd_extract_160_fsf`)
- `analysis/` — disassembly/DWARF/strings artifacts per function
- `tools/fn_diff.py` — parity harness (normalized per-function diff)
- `evidence/` — runtime differential test evidence
- `gccbuild/` — recipe + logs for building the FSF GCC 4.4.x armv6z
  cross-compiler used for the rebuild
- `incoming/` — external forensics kit (rebuilt libgcc/csu objects +
  comparison scripts) from third-party analysis
- `DELTA.md` — the decoded change-set vs sacd-ripper v0.3.7 (base)
- `NOTES.md` — working notes
- `RESEARCH-BRIEF.md` — open research questions (toolchain identification)

## Build

Toolchain: GNU GCC 4.4.1 (`--target=arm-none-linux-gnueabi --with-arch=armv6z
--with-sysroot=<glibc-2.9 ARM sysroot>`), GNU binutils 2.19.1 (`--with-sysroot`).
Application flags: `-O0 -marm -march=armv6z -D_GNU_SOURCE
-D_FILE_OFFSET_BITS=64`, link with `--export-dynamic`. The embedded
`sacd_read.ko` blob is the original module bytes, linked via
`ld -r -b binary`.

```
cd reconstruct && make CROSS=arm-none-linux-gnueabi-
python3 ../tools/fn_diff.py ../original/sacd_extract_160 sacd_extract_160_fsf
```

## Provenance of the original

Base application = sacd-ripper v0.3.7 (de008ff) + a community Linux port
(server mode, /dev/sacd_read backend, kernel module loader). Original built
with the MTK "gnuarm-4.4.1" crosstool (target `armv6z-mediatek-linux-gnueabi`,
GNU GCC 4.4.1, binutils 2.19.1, glibc 2.9) — proven from the binary's DWARF.
