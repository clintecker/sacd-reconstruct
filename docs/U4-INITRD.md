# U4 INITRD decode — BX510 (M15.R.0257)

Scope: attempt to decode `initrd_1.bin` (532,976 bytes) extracted from the BX510 NAND image, and identify any boot-time transform (XOR/AES/etc) applied before Linux consumes it.

This lane is **about initrd decoding**, because the guest kernel module `bdpdrv.ko` has many unresolved OSAL-style symbols (see `evidence/bx510-guest/bdpdrv/missing.pre.syms`). If `initrd_1` contains the missing OSAL provider binary/module, decoding it would let us extract that provider and list its exports.

Status: **OPEN / BLOCKED**. We verified U-Boot loads `initrd_1` *raw* from NAND into RAM (no U-Boot-side decrypt/decompress). The blob itself looks like high-entropy opaque data and did not decode with common decompressors. The likely remaining decode/unwrap step is in the **kernel** and/or uses **hardware-bound keys** (eFuse / secure world), which we did not extract in this lane.

## Artifacts (VERIFIED)

Pulled from VM `~/bx510-emu/images/` into `evidence/bx510-guest/u4-initrd/pulled/`.

SHA-256 and sizes are recorded in:
- `evidence/bx510-guest/u4-initrd/pulled/SHA256SUMS.txt`
- `evidence/bx510-guest/u4-initrd/pulled/SIZES.txt`

Additional pulls:
- NAND `key_block_1` and `key_block_2` extracted from `nand.img` (see below), under `evidence/bx510-guest/u4-initrd/pulled/key_blocks/`.

## 1) Blob classification (VERIFIED)

Reports:
- `evidence/bx510-guest/u4-initrd/initrd_1.analysis.txt`
- `evidence/bx510-guest/u4-initrd/rootfs_enc_it_1.analysis.txt`

Key points:
- `initrd_1.bin` has near-max Shannon entropy (**~7.9997 bits/byte**) and **zero duplicate blocks** at 8/16/32/64-byte granularity.
- No common embedded signatures (cpio/gzip/xz/zstd/lz4/squashfs) occur anywhere in the blob (see `evidence/bx510-guest/u4-initrd/magic_scan.txt`).
- A fixed-offset ext2 superblock check does **not** match (`ext_superblock_magic_at_0x438 != 0xef53`), which is consistent with “not a raw ext[234] image”.

Interpretation:
- This distribution is consistent with either **encryption** (CBC/CTR/etc) or **high-quality compression** (possibly proprietary/headerless). There is no visible structure to anchor known-plaintext recovery.

## 2) Common decompressor sweep (VERIFIED negatives)

Report: `evidence/bx510-guest/u4-initrd/initrd_1.try_decompress.txt`

Tried and failed (all evidenced in the report):
- zlib (headered + raw)
- gzip
- bzip2
- lzma (auto)
- zstd

CLI evidence:
- `evidence/bx510-guest/u4-initrd/initrd_1.xz_stderr.txt`
- `evidence/bx510-guest/u4-initrd/initrd_1.lz4_stderr.txt`
- `evidence/bx510-guest/u4-initrd/initrd_1.zstd_stderr.txt`

## 3) Key block partitions (VERIFIED)

The NAND manifest lists key partitions:
- `key_block_1` at offset `0x0080_0000` size `0x0010_0000`
- `key_block_2` at offset `0x0090_0000` size `0x0010_0000`

We extracted both blocks from `nand.img` (via a Python slicer on the VM) and pulled them back.

Evidence:
- `evidence/bx510-guest/u4-initrd/pulled/key_blocks/key_block_1.bin`
- `evidence/bx510-guest/u4-initrd/pulled/key_blocks/key_block_2.bin`
- `evidence/bx510-guest/u4-initrd/pulled/key_blocks/SHA256SUMS.txt`
- `evidence/bx510-guest/u4-initrd/key_block_1.analysis.txt`

Result:
- `key_block_1.bin` and `key_block_2.bin` are identical and appear to be **all 0xFF** (entropy 0, duplicate blocks across the entire file).

Implication:
- There is **no device-unique key material present** in these NAND key partitions for this dump.
- If `initrd_1` is encrypted, the key likely comes from **hardware secrets (eFuse / secure world)** or from another partition not yet identified.

## 4) U-Boot consumer analysis: initrd load path (VERIFIED)

We reverse-checked whether U-Boot applies any transform to the initrd bytes.

Evidence (radare2 output, no color):
- `evidence/bx510-guest/u4-initrd/u-boot.r2.initrd_loadpath.nocolor.txt`

Key observations:
- U-Boot selects `initrd_1` / `initrd_2` by name (partition lookup by string): `fcn.04f1f748` references `str.initrd_1`.
- The initrd bytes are then read from NAND via `fcn.04f22090`.
  - At the callsite inside `fcn.04f1f7b4`:
    - `r0 = r6 - [part+0x1c]` (destination address)
    - `r1 = [part+0x18]` (flash offset)
    - `r2 = [part+0x1c]` (size)
    - `bl fcn.04f22090`
  - `fcn.04f22090` calls a NAND read helper (`fcn.04f2a61c`) and returns success/failure.

Conclusion:
- **U-Boot applies no XOR/AES/decompression transform** to `initrd_1` during the load. It is staged into RAM as-stored.

## 5) XOR-checksum (“appendXOR”) code path is present but not used for initrd (VERIFIED)

U-Boot contains an upgrade-oriented XOR-checksum mechanism (strings: `find xor signal`, `appendXOR`, `xor checksum unmatch`).

Evidence:
- `evidence/bx510-guest/u4-initrd/u-boot.r2.fcn_04f185b8.pdf.txt` (function referencing `[appendXOR]`)
- `evidence/bx510-guest/u4-initrd/initrd_1.xors_marker_scan.txt` (marker search in initrd blob)

Findings:
- The XOR-check code searches for `XoRS` / `SRoX` marker words inside an image and then XOR-reduces 32-bit words.
- Those markers do **not** appear anywhere in `initrd_1.bin`.

## 6) Kernel side (INFERRED partial)

We extracted the gzip member from the zImage to a raw decompressed kernel blob:
- `evidence/bx510-guest/u4-initrd/kernel/kernel.gzip_member.out` (+ tail)

Evidence:
- `evidence/bx510-guest/u4-initrd/kernel/kernel.gzip_member.sizes.txt`
- `evidence/bx510-guest/u4-initrd/kernel/kernel.gzip_member.strings.grep.txt`

This contains generic initrd/initramfs strings (e.g. `Unpacking initramfs...`) and many crypto-related strings, but **we did not identify** a definitive initrd decryption routine or key source in this lane.

## Current blocker (explicit)

Because U-Boot loads `initrd_1` raw, decoding it requires understanding a **kernel-side transform** (or another pre-kernel stage) that is not yet located.

Constraints we hit in this lane:
- No plaintext anchors inside `initrd_1` (no cpio/gzip/xz/zstd/lz4 signatures anywhere).
- `key_block_1/2` are empty (0xFF), so NAND does not provide a straightforward key source.

## Recommended next steps

1. **Find the kernel-side consumer/unwrap** of initrd:
   - Disassemble `kernel.gzip_member.out` and search for code paths that parse an initrd header (not the standard `newc`/gzip paths) or call into secure world.
   - Search specifically for platform hooks (strings include `sys_tz`, `tzlib`, `mt85xx_ioctl`, etc.) and any proprietary “image” format identifiers.

2. If the initrd is hardware-decrypted:
   - Determine whether the secure-world implementation is present in NAND/boot partitions (TrustZone firmware) and whether keys are derived from eFuse.

3. If we can get a **runtime memory capture** during a boot path that uses initrd (e.g. recovery/upg mode):
   - Dump the initrd region in RAM after kernel has (supposedly) unpacked/validated it.

## What we did *not* deliver

- No decoded initramfs filesystem.
- No extracted OSAL provider binary/module.
- Therefore **0/73** “no-provider-in-BDP/*.ko” missing symbols were resolved in this lane.
