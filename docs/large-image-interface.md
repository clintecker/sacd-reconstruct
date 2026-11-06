# Synthetic read-only host-image interface — design sketch

Status: design (team-reviewed route, pre-implementation)
Date: 2026-11-03
Acceptance condition (team): both pinned daemons serve independently
verified sectors from a large host-backed image through BOTH disc-read
paths, without staging the full image in guest RAM.

## Route selection — decided by a checked fact, not preference

`mediatek_defconfig` (the config we build guest modules against,
`~/sony-kernel/linux-2.6.35`) has **`# CONFIG_PCI_SYSCALL is not set`**.
No PCI → no virtio_pci → **virtio is not a route** for this guest, and
SATA/AHCI stays deferred per team guidance until `sata_mt85xx_mod.ko` is
validated against QEMU's model. What the kernel does give us:
`CONFIG_BLOCK=y`, `CONFIG_BLK_DEV=y`.

We also control the emulator itself: our own `qemu-system-arm` build
carries the `sony-bx510` machine. Therefore:

**HDHOST** = a small read-only MMIO block device added to the
sony-bx510 machine (our QEMU build) + `hdhost.ko`, a guest block-driver
module built through the proven module pipeline (GPL tree,
mediatek_defconfig, SMP off, armv6, vermagic patch, kallsyms tail swap),
exposing the host image as a guest block device.

## Host backing and shared access

- QEMU opens the image through its block layer, **read-only**:
  `-drive file=large.bin,format=raw,if=none,id=hdhost,readonly=on`.
  The device model has no write command at all; the guest cannot
  request a write. Capacity comes from the image byte size (a sparse
  file built by ftruncate + sentinel writes; no full-image material-
  ization anywhere).
- **One shared backend, one truth**: the guest sees exactly one block
  node, `/dev/hdhost`. Both disc-read paths reach it:
  1. Daemon plain path (TOC reads, everything through the libc file
     API): `tmpredir` redirects `/dev/sr0` → `/dev/hdhost` — the
     existing path-redirect seam, no daemon or shim logic change.
  2. Module path: `bdpvirt`'s `_IDECLI_OddRead` does
     `filp_open("/dev/hdhost", O_RDONLY|O_LARGEFILE)` + `kernel_read`
     with the backported `loff_t` signature — identical to the verified
     code, only the target node changes.
- Host-backed throughout: QEMU's backend serves sectors on demand into
  guest page-cache pages for the sectors touched. Guest transfer
  buffers are bounded by the request (≤ MAX_PROCESSING_BLOCK_SIZE ×
  2064 bytes); nothing larger is ever staged in guest RAM.

## Guest-visible behavior

MMIO register block (one page, placed at a free physical slot confirmed
against the board memory map at implementation; address recorded in the
run manifest):

| Register | Meaning |
|---|---|
| SECTOR_LO / SECTOR_HI | 64-bit LSN, **explicit per transaction** — no shared seek position |
| COUNT | sectors per transaction, hard max 128 |
| BUF_LO / BUF_HI | guest physical address of the transfer buffer |
| CAP_LO / CAP_HI | read-only capacity in sectors (from host image size) |
| CMD / STATUS | doorbell write starts; STATUS: busy bit + code (0 OK, 1 out-of-bounds, 2 host I/O error) |

`hdhost.ko`: `register_blkdev` → `blk_init_queue(request_fn)` →
`alloc_disk`. The request function splits each bio into ≤128-sector
transactions, programs the registers (explicit 64-bit LSN per
transaction), rings the doorbell, and waits on STATUS; the device model
copies sectors from the host backend into the bio's pages
(`dma_memory_write` on our side — the buffer is the bio's own page,
i.e., page cache, allocated on demand).

Guest node: `/dev/hdhost` via `mknod` (S_IFBLK — the known mode-bit
lesson; the probe reads the dynamic major from `/proc/devices`).
The battery script also runs the daemon's `fstat` path against the
node.

Capacity to the daemon: on 2.6.35, `fstat64` on an opened block node
returns the true device size (bdev inode size is set at open), so the
daemon's primary capacity path works unchanged. The daemon's
`BLKGETSIZE64` fallback stays supported as belt-and-braces: `tmpredir`'s
stat wrapper issues `BLKGETSIZE64` if `fstat64` reports zero size on a
block node and substitutes the result.

64-bit discipline: file offsets via `loff_t` everywhere (`kernel_read`
proven), `lseek64` in all instrumentation, `O_LARGEFILE` on every
regular-file open through the guest kernel (already the case in
bdpvirt; preserved).

Module-path frame contract unchanged: `_IDECLI_OddRead` still produces
the verified 2064-byte raw frames (12-byte header + 2048 logical + 4
trailing), and `sacd_read.ko`'s payload unpacking (offset-12 pack on
decrypt) is byte-identical to the fixture rig — only the bytes' origin
moves from a tmpfs file to the host-backed block node.

## Transactions and failures

- **Ownership/serialization**: the MMIO register set is touched only
  under the request-queue lock; exactly one transaction is in flight
  per request-function invocation. No shared-register races, no shared
  seek position — each transaction carries its own explicit LSN.
- **Bounds**: the device model rejects SECTOR+COUNT > capacity with
  STATUS=OOB → the block layer surfaces EIO → the daemon's read fails
  → the established wire failure convention (negative/zero result per
  the reconstructed code path), **never a successful zero-filled
  sector**.
- **Short reads**: within capacity the backend always returns full
  sectors; short means error → EIO as above.
- **Host I/O errors**: QEMU backend failure → STATUS=IERR → EIO →
  same propagation. Missing data must surface as failure; the sentinel
  data in the image is what proves zeros on the wire are genuinely
  zero regions, not failures-in-disguise.
- **End-of-image semantics — explicitly derived, honestly labeled**:
  on a block node, a read entirely past capacity yields EIO rather
  than the regular-file fixture rig's 0-byte EOF. The real player's
  ODD is itself a block device, so this is likely closer to hardware —
  but we have no hardware capture of beyond-EOF yet, so the battery
  records the observed behavior of both binaries as an
  **emulator-derived expectation** (the parity condition — both
  binaries must agree — remains strict), and the hardware leg can
  settle it later with the pair capture.

## Validation plan (large-image battery, `gate3.sh`)

- The existing 86,200-sector gate (`bx510_gate2.sh`) stays unchanged
  and runs FIRST as the TOC-correctness regression case.
- Image: sparse **5 GiB** raw file (2,621,440 LSNs), built ON the VM by
  a generator (ftruncate + sentinel writes only — no full-image
  transfer, no VM outbound). Identity: manifest SHA-256 (size + hashes
  of every sentinel/TOC sector + sampled sectors) computed at build and
  recorded; a full-image SHA-256 is computed once host-side for the
  manifest.
- ScarletBook structure at the image start: master TOC @510, SACDText
  @511–518, SACD_Man @519, area TOC @600 with a two-channel track
  range that **straddles both boundaries**: track_start=1048500,
  track_end=2621430 — so the encrypted range (decrypt/clamp semantics)
  spans the 2 GiB and 4 GiB lines.
- Sentinels — distinct, nonzero, per-LSN patterns (same xorshift
  family, distinct salt inside the track range): at **1048575/1048576**
  (2 GiB boundary), **2097151/2097152** (4 GiB boundary), **2621439**
  (final sector), plus the TOC sectors as structural sentinels.
- Battery steps, both pinned binaries, role-asserted, raw capture on:
  OPEN=0; SIZE=2621440; single reads at every sentinel LSN
  (hash-verified against the generator); 128-sector reads straddling
  2 GiB and 4 GiB (at 1048512 and 2097136, hash-verified); clamp read
  before the encrypted start (1048490 cnt=20 → 10); encrypted-range
  read inside the track range (decrypt path fires; mock verbatim copy
  → enc-pattern bytes, hash-verified); read at the final sector;
  read past capacity (defined end-of-image behavior, recorded);
  CLOSE; reconnect; DONE. Verdict = existing gate discipline
  (per-binary computed expectations before any diff) +
  `--session-diff` raw-frame verification, on the new expectations.
- Per-run identity recording: transcript headers carry role, both ELF
  digests, runner digest, probe invocation — plus the image manifest
  SHA, size, and sentinel expectations for this battery.

## Out of scope / separately tracked (per team)

Original initrd investigation, normal appliance startup, graphics/UI,
host networking, and accurate SATA behavior stay separate work items.
The archived checkpoint (v1, SHA `685c2df6…`) predates our fixes; the
library link is account-authenticated on your side, so please export
it as a tarball over the private channel and we will import any
remaining useful coverage into the canonical tree rather than
maintaining a second baseline.
