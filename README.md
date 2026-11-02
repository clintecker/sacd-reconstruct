# sacd_extract_160 — reconstruction

Full source reconstruction of the closed-source ARM binary `sacd_extract_160`
(SACD-ripping daemon from the "AutoScript" USB packages for certain Sony
BD/SACD players), engineered back to byte-level parity with the original.

## Status (updated 2026-11-02)

- **385/390 functions instruction-identical** (normalized disassembly,
  `tools/fn_diff.py`; denominator corrected — fn_diff compares 390
  functions total: 385 exact + 5 remaining)
- **Installer TU byte-identical**: install_modules (464 B), remove_modules
  (132 B) and installer .rodata (236 B) reproduce the original bytes at the
  original addresses via a reference-address relink, no masking
  (`incoming/sacd-installer-and-status/`)
- **Six-state headless status test: 6/6 exact status lines** — the
  candidate matches the reference byte-for-byte on server_loop output
  (`evidence/status-test/RESULTS.txt`; closes issue #1)
- **Runtime differential: 10/10 committed cases byte-identical** under
  qemu-arm (stdout/stderr/exit codes) — case count corrected from an
  earlier "12/12" claim, see `evidence/runtime-differential/RESULTS.md`
- Remaining 5 diffs: the csu/crtbegin startup objects
  (__libc_csu_init, __do_global_dtors_aux, _start, call_gmon_start,
  frame_dummy) — resolved by the relink recipe in
  `incoming/sacd-installer-and-status/` (GNU crtbegin.o from source +
  glibc 2.9 elf-init/stat64/fstat64, CodeSourcery 2009q3 libgcc_s.so.1
  pinned as the dynamic provider)
- **Current candidate** `reconstruct/sacd_extract_160_fsf` (unstripped),
  SHA-256 `e6daa1128da118f1fb7a7bf3c95d6faba40bc1021c920aec7fca34cae93adaa0`
- Layout note: the original links .data objects in a different order
  (documented in DELTA.md); every pool reference was verified to reach
  the same object and value. Not chased — the BX510 drop-in test is the
  release decision.

## Layout

- `original/` — the reference binary (SHA-256
  `0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45`)
- `reconstruct/` — the buildable reconstruction (compiles to
  `reconstruct/sacd_extract_160_fsf`)
- `analysis/` — disassembly/DWARF/strings artifacts per function
- `tools/fn_diff.py` — parity harness (normalized per-function diff)
- `tools/pool_audit.py` — literal-pool content audit (strings/scalars/pointer
  structures with address masking)
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

## Provenance of the release candidate

Built with GNU GCC 4.4.1 and source-built static arithmetic helpers.
Linked against the default ARM `libgcc_s.so.1` from CodeSourcery
2009q3-67 (SHA-256 `5068e1ea0c56591305d3c605d9fbd3e900ae8d134d13bc32a65e3fe1ddbec6d4`).
The player supplies the runtime DSO. The remaining sysroot inputs are
recorded in `DELTA.md` (release pipeline section).

Caveat on record (issue #4 review): the CodeSourcery archive's libc
identifies itself as glibc 2.10.1, while the original's nonshared CSU
bytes are glibc 2.9 — we build `elf-init.c`, `stat64.c`, `fstat64.c`
from glibc 2.9 source to match. The CS DSO is a pinned link-time ABI
input; the exact MTK-era `libgcc_s.so.1` byte identity is unestablished.
On the player, resolution belongs to the player's own loader; record its
build IDs or hashes when capturing.

## Provenance of the original

Base application = sacd-ripper v0.3.7 (de008ff) + a community Linux port
(server mode, /dev/sacd_read backend, kernel module loader). Original built
with the MTK "gnuarm-4.4.1" crosstool (target `armv6z-mediatek-linux-gnueabi`,
GNU GCC 4.4.1, binutils 2.19.1, glibc 2.9) — proven from the binary's DWARF.
