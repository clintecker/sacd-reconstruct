# BX510 guest: bdpdrv Runs C51–C55 — real SATA stack + /proc mountpoint rig

Date: 2026-11-12. Predecessor: run-c50.md (first full load).

## What changed per run (VERIFIED)

- **C51**: probe gained `--pre-file` (stage+insmod BEFORE the stub/drvcli
  chain). Loaded the REAL SATA stack from the rootfs — `libata.ko` (rc=0) →
  `sata_mt85xx_mod.ko` (rc=0) — so `_fg_fe_bootup` comes from the real
  driver, retiring the feboot shim's failure (C50's feboot rc=1: feboot
  wants sata_bltin's `_fg_fe_bootup`; with the real module loaded feboot
  rc=**0**). bdpdrv insmod rc=0, Live.
- **C52/C53 (diagnostics)**: ROOTPROC=255 diagnosed — `mount -t proc
  proc /proc` fails ENOENT because the shell-mode root is the READ-ONLY
  squashfs and `/proc` does not exist in it (ls: /proc: No such file or
  directory; `mkdir -p /proc` rc=1). The SATA loader opens the LITERAL
  `/proc/mtd`, so shell mode could never satisfy it.
- **Rig image fix (mkimagesproc.sh)**: `rootfs_normal_1` (mtdblock17,
  slice offset 32505856, 72282112 B, squashfs 4.0 gzip — record sha
  42178010… VERIFIED pre-edit) unsquashed, `/proc /dev /sys /tmp` dirs
  added, repacked (fits the slice exactly), written into a rig-local
  nand.img copy → `/tmp/images-proc/` on the VM (manifest record sha
  updated, note added). Base images untouched.
- **C54** (`--images /tmp/images-proc`): **ROOTPROC=0** — /proc mounts at
  the literal path. `cat /proc/mtd` works. SATA loader:
  `[sata_mt85xx_parse_mtd_table] /proc/mtd rd_length = 1047` — partitions
  parsed: `fe_bin_1 - /dev/mtd8`, `fe_bin_2 - /dev/mtd9` …
- **C55** (+ tmpfs on /dev + console/null/ttyMT0 nodes): the loader's
  mknod path works. **The FE firmware was READ from real flash through
  the NFI model**: `ECC failed: 0, ECC corrected: 0 / Number of bad
  blocks: 0, bbt blocks: 0 / yifan FE firmware without CheckSum..` —
  then rejected: `SocReadMainCode: Read main partition error` (both main
  and backup). The firmware-read acceptance check is the open question
  (decode in flight: decode/sata-fw-load.md).
- After the fw-load failure the port start polls the frontend reset
  interrupt → timeout (`polling frontend reset interrupt timeout`,
  `ata_host_activate err rc=0xfffffffb`) — the QEMU SATA model does not
  raise the reset-complete IRQ yet (device-model work pending the decode).
- bdpdrv itself: insmod rc=0, Live, FBM/ESM/MPV init prints identical to
  C50 in every C5x run.

## Why this matters for tip-to-tail

The SATA/IDE HAL (i4Ide*) IS the disc path the sacd daemon uses. The real
SATA driver + real FE firmware from real flash through the NFI model is
the shortest route to a real `/dev/sr0`-equivalent in the guest — the
same class of provenance as running the real bdpdrv.

## Honest labels

- The OSAL stub remains an INSTRUMENT. The SATA stack + firmware content
  are REAL (rootfs/flash bytes, sha-pinned via the manifest).
- `images-proc` is a RIG-DERIVED image (modified squashfs) — provenance:
  base slice sha 42178010…, repack sha 76f353ff…, both recorded. The
  pinned pristine image stays canonical for the original-build gates.

## Evidence files

- `bdpdrv-runC51..C55.{uart.log,mmio.log,meta.json}` (pulled from VM)
- The repack script is recorded in the session notes (mkimagesproc.sh +
  mksq2.sh: unsquashfs → add dirs → mksquashfs -comp gzip -b 131072
  -all-root → pad → patch manifest record sha).

## Next

1. sata-fw-load decode (in flight) → satisfy SocReadMainCode.
2. hotset decode (in flight) → QEMU device model incl. the frontend-reset
   IRQ raise.
3. Re-run: SATA port 0 up → bdpdrv IDE bootup continues → fb surface.
