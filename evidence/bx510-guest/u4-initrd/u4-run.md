# U4 lane run log — initrd_1.bin decode attempt

Repo: `/Users/clint/code/sacd-reconstruct` (standalone mirror; no commits)

Goal: decode `initrd_1.bin` (532,976 bytes) to extract the OSAL provider (symbols like `x_mem_*`, `BIM_*`, `CKGEN_*`, `HAL_*`) needed to satisfy `bdpdrv.ko` unresolved symbols (`evidence/bx510-guest/bdpdrv/missing.pre.syms`).

## Result (short)

- **VERIFIED:** U-Boot loads `initrd_1` *raw* from NAND to RAM (no U-Boot decrypt/decompress/XOR transform).
- **VERIFIED:** `initrd_1.bin` is high-entropy, structureless to our tooling; it does **not** parse as gzip/cpio/ubifs/squashfs/etc and does not decode with common decompressors.
- **VERIFIED:** NAND `key_block_1` and `key_block_2` partitions are **all 0xFF** (empty/unprogrammed).
- **OPEN/BLOCKED:** If `initrd_1` is encrypted or proprietary-compressed, the remaining unwrap is likely **kernel-side** and/or uses **hardware-bound secrets** (eFuse / secure world). This lane did not recover that transform or any key material.

Therefore: **no OSAL provider binary/module extracted**; **0/73** “no-provider-in-BDP/*.ko” missing symbols resolved in this lane.

## Evidence bundle (all files)

All evidence for this run is under:
- `evidence/bx510-guest/u4-initrd/`

Key evidence files:

### Artifact pulls + hashes
- `evidence/bx510-guest/u4-initrd/pulled/` — pulled `initrd_1.bin`, `u-boot.bin`, `arm2-fastboot.bin`, `kernel.uImage`, `rootfs_enc_it_1.bin`, `manifest.json`
- `evidence/bx510-guest/u4-initrd/pulled/SHA256SUMS.txt`
- `evidence/bx510-guest/u4-initrd/pulled/SIZES.txt`

### Blob stats + signature scans
- `evidence/bx510-guest/u4-initrd/initrd_1.analysis.txt`
- `evidence/bx510-guest/u4-initrd/rootfs_enc_it_1.analysis.txt`
- `evidence/bx510-guest/u4-initrd/magic_scan.txt`

### Decompressor sweep (negative results)
- `evidence/bx510-guest/u4-initrd/initrd_1.try_decompress.txt`
- `evidence/bx510-guest/u4-initrd/initrd_1.{xz,lz4,zstd}_stderr.txt`

### Key blocks (empty)
- `evidence/bx510-guest/u4-initrd/pulled/key_blocks/key_block_1.bin`
- `evidence/bx510-guest/u4-initrd/pulled/key_blocks/key_block_2.bin`
- `evidence/bx510-guest/u4-initrd/key_block_1.analysis.txt`

### U-Boot reverse: initrd load path (no transform)
- `evidence/bx510-guest/u4-initrd/u-boot.r2.initrd_loadpath.nocolor.txt`
  - Shows: `fcn.04f1f7b4` → selects initrd partition (`fcn.04f1f748`) → reads NAND via `fcn.04f22090`.
  - `fcn.04f22090` calls a NAND read helper and returns status; no decrypt/decompress.

### U-Boot reverse: upgrade XOR checksum path (not used for initrd)
- `evidence/bx510-guest/u4-initrd/u-boot.r2.fcn_04f185b8.pdf.txt` (function printing `[appendXOR] ...`)
- `evidence/bx510-guest/u4-initrd/initrd_1.xors_marker_scan.txt` (marker not present in initrd blob)

### Kernel extraction (partial)
- `evidence/bx510-guest/u4-initrd/kernel/kernel.gzip_member.out`
- `evidence/bx510-guest/u4-initrd/kernel/kernel.gzip_member.strings.grep.txt`

## Writeup

- `docs/U4-INITRD.md` — consolidated transform status + explicit blocker + next steps.
