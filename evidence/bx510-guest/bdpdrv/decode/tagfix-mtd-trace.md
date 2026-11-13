# Why the applied FE TAG fixtures still fail — C97 trace analysis

Scope: `decode/fe-tags.md` (tag decode + fixture recipe) → `decode/tags-fixture-build.md`
(what was applied) → **why the C97 run's UART still prints `TAG mismatch` for all three
tables**, using the C97 full MMIO trace. Everything below is either a byte-level tool
output (VERIFIED) or explicitly labelled INFERRED / OPEN.

Rig facts used throughout:

| item | value | source |
|---|---|---|
| trace | `/tmp/bdpdrv-runC97.mmio.log`, 100,900,313 B / 3,526,314 lines | `wc`, scan §1 |
| UART | `/tmp/bdpdrv-runC97.uart.log` | run artifacts |
| image | `/tmp/images-fe/nand.img`, md5 `1ddc0b62fb04ac57e69a0e875046cdef` = the fixture image (`tags-fixture-build.md` §4.1) | `md5sum` |
| harness that produced C97 | **`/tmp/bx510_bdpdrv_stub_probe.py`** — its `meta.json` schema (`bdpdrv`, `osal_stub`, `osal_stub_a`, `clidrive_mode: PROBE_SEQ`, `fe_test_data{offset,size,payload_size}`, `terminal_marker`) is byte-for-byte the C97 meta | `bdpdrv-runC97.meta.json` vs probe source |
| module | `/tmp/sata_staging/sata_mt85xx_mod.ko`, sha256 `8a0253eb…` (the `fe-tags.md` pin) | `shasum -a 256` |
| QEMU NAND model | `hw/block/nand.c` from the pinned qemu-9.2.4 tree at `~/bx510-emu/emulator/work/qemu-9.2.4/` | pulled, read |

---

## 0. Verdict up front

1. **The C97 trace contains no NFI activity at all — the "full MMIO" mode is blind to the
   NAND controller.** `mt8560-nfi.c` registers its own `MemoryRegion` over
   `0x7001e400`/`0x7001ec00` and its read/write ops contain no `qemu_log` call, so
   `BX510_TRACE=1` (which hooks only the machine's `0x70000000` region) never sees them.
   Zero NFI/ECC-window accesses in 3.5 M lines (§1). **So the requested "NFI page per
   read" is not recoverable from C97** — this is an instrumentation gap, not a missing
   decode.
2. **The image geometry suspicion in the brief is ruled out.** QEMU's chip (`mtd
   NAND_MFR_SAMSUNG,0xda`, LP, 256 MiB) has 2048-byte pages with 64-byte OOB, and because
   the 256 MiB image is shorter than `pages*(2048+64)` the model keeps **OOB in RAM**
   (`mem_oob=1`). Page *N* is at image offset `N*2048` — no OOB interleave, no ECC
   prefix, no bad-block compaction. A linear `dd` at the partition offset lands exactly
   on the page the driver reads (§3).
3. **One of the three failures is now fully explained and is *not* a fixture problem:**
   the C97 harness itself overwrites `fe_test_data` (0xe00000) with its **shim tar
   stream** before boot. A ustar archive's first bytes are the member name, so the
   FATB read window came back starting `73 68 69 6d` = `shim` (§2.2, reproduced with
   `tarfile`). The tag read worked; the bytes at that offset were the tar, not the
   fixture.
4. **PWRC / PARM remain OPEN**, and the honest statement is that the *byte source* of
   those two reads is unresolved: the trace cannot see the NAND, and the guest-side
   readback probe I ran (`/dev/mtdN` + `dd`, read-only, `snapshot=on`) returns pages
   that **do not match the image** — while the same run's driver-visible read of
   `fe_bin_1` demonstrably works in C97 (§4). That contradiction is itself the finding:
   the model's page-addressing needs a read-side log before anyone can conclude
   further (§6).
5. Two claims in the existing docs are wrong and must not be used as controls:
   `tags-fixture-build.md` §7.1's "embedded FA table md5 `84d04c9d…`" is
   `md5(8192 × 0xFF)` (an erased region), and `fe-tags.md` §3.1's "the printed 4 bytes
   are stale heap" does not hold for the `MTDRawRead` path (§7).

---

## 1. The trace is blind to the NAND controller (VERIFIED)

`emulator-kit/mt8560-nfi.c` (read-only):

```c
#define NFI_BASE 0x7001e400u
#define ECC_BASE 0x7001ec00u
...
static const MemoryRegionOps nfi_ops = { .read = nfi_read, .write = nfi_write, ... };
static const MemoryRegionOps ecc_ops = { .read = ecc_read, .write = ecc_write, ... };
...
    memory_region_init_io(&n->regs, owner, &nfi_ops, n, "mt8560.nfi", 0x400);
    memory_region_init_io(&n->ecc,  owner, &ecc_ops, n, "mt8560.ecc", 0x200);
    memory_region_add_subregion_overlap(mem, NFI_BASE, &n->regs, 1);
    memory_region_add_subregion_overlap(mem, ECC_BASE, &n->ecc, 1);
```

`nfi_read()` / `nfi_write()` / `ecc_read()` / `ecc_write()` log **nothing** (the only
model-side log lines are `LOG_UNIMP`/`LOG_GUEST_ERROR` on *unsupported transfer* and
*DMA failure*; both are absent from the C97 trace — `grep -c mt8560-nfi` = 0). The
`bx510: MMIO R/W %06x` lines come from `sony-bx510.c`'s own region at `0x70000000`
(`s->trace_all`), which the NFI subregion overlaps and shadows.

Scan of the whole C97 trace (tool: `decode/probes/nfi_scan.py`, address field is masked
`& 0xffffff` by the log format, so `NFI_BASE & 0xffffff = 0x01e400`):

```
total lines: 3526314
NFI/ECC-window accesses: 0
```

`0x01e400..0x01e7ff` (NFI) and `0x01ec00..0x01edff` (ECC): **zero hits**. The only hit in
that 4 KiB page is `0x01effc`, read 8100 times — that is the machine model's
"DMA writes have drained" register (`case 0x1effc: return 0;`), i.e. `0x7001effc`,
outside both NFI windows.

Consequence: **no page/row/column evidence exists in C97 for any of the three reads.**
Any statement about "which pages were fetched" has to come from either (a) a logging
patch to the model (must be applied by the owner of `emulator-kit/`) or (b) a
guest-visible readback (§4).

### 1.1 What the trace *does* pin: the reads ran, and they were not short

The driver-side evidence is in the UART + the module disassembly
(`decode/listings/sata_mt85xx_MTDRawRead_clone_6.txt`, `…_xfer_int_ldr_fw.txt`):

```
L247 [IDE]<sata_mt85xx_SocReadPowerCurve>(Error)TAG mismatch:b6 7a 75 2c
L248 [IDE]<xfer_int_ldr_fw> read power curve failed !!
L251 [IDE] <sata_mt85xx_MTDAdvRead> TAG mismatched, Latest stored data in start_addr = 0x00000000
L253 [IDE]<sata_mt85xx_SocReadFaTable>(Error)TAG mismatch:shim
L254 [IDE]read FA table from FW offset = 0xfe000
L258 [IDE] <sata_mt85xx_MTDAdvRead> TAG mismatched, Latest stored data in start_addr = 0x00000000
L260 [IDE]<sata_mt85xx_SocReadParameter>(Error)TAG mismatch:ff ff ff ff
L261 [IDE]<xfer_int_ldr_fw> Read parameter failed !!
```

with the per-read `[IDE] ECC failed: 0, ECC corrected: 0` +
`[IDE] Number of bad blocks: 0, bbt blocks: 0` pair printed **before** each mismatch —
those are `MTDRawRead`'s entry prints at `.text+0xa14`/`.text+0xa38` (rodata
`.str1.4+0x1b8` / `+0x1e4`), i.e. the reader really was entered three times.

The read loop's error paths are all print-and-return-`-1` and every one of them is
gated on the same `ide_log_en & 32` flag that produced those prints, so a failed
`pread64` would have printed (`+0x2d4` = rodata `.str1.4+0x2d4`, `+0x304`, `+0x150`,
`+0x110`). **No such line exists in the C97 UART** (`grep -c "Can't read enough|No ECC
status|MTDRawRead|read error"` = 1, and that single hit is the guest shell's own
`cat: read error: Invalid argument` at L1531, unrelated to the reader) ⇒ each page
`pread64` returned the
full 2048 bytes and the success-path `memcpy(out + copied, sata_mtd_read_buf, n)`
(`.text+0x74c..0x780`) executed. The three `%c%c%c%c` fields are therefore the **actual
first four bytes of the flash page the driver got**, not uninitialised memory (§7.2).

---

## 2. The actual byte source of each read

### 2.1 `SocReadPowerCurve` / `SocReadParameter` — OPEN

* `MTDRawRead(fe_power_curve, 32, 0x420, out)` → `strncmp(out, "PWRC", 4)` — same
  pointer (`.text+0x16ac` passes `r7`, `.text+0x1a34` checks `r7`), so the printed bytes
  are the read page. Page = `0x1000000 / 2048 = 8192`.
* `MTDAdvRead(fe_parameters, 30, "PARM", 0x2000, out)` → page-0 scan at
  `0xf00000 / 2048 = 7680`.
* The two observed payloads (`b6 7a 75 2c`, `ff ff ff ff`) are **not** the fixtures and
  are **not** explained by any offset arithmetic this analysis could verify. They are
  unchanged from C91→C97 (`fe-tags.md` §3 table), which means the value is independent
  of the image bytes at those offsets, i.e. the reads are landing somewhere else. §4 is
  the probe that was meant to name that "somewhere else"; it produced a contradiction
  instead of an answer, so this is recorded as OPEN, with the exact next experiment in
  §6.

### 2.2 `SocReadFaTable` — VERIFIED: the harness overwrote the partition with its tar

`/tmp/bx510_bdpdrv_stub_probe.py` (the script whose meta schema matches
`bdpdrv-runC97.meta.json` exactly) does, before booting:

```python
payload = build_tar(stubko, stuba_ko, extra)          # ustar, members shim/osal_stub.ko, …
part = next(x for x in parts if x["name"] == "fe_test_data")
nand = td / "fixture.img"
shutil.copyfile(images / "nand.img", nand)            # copy of the fixture image
with nand.open("r+b") as f:
    f.seek(part["offset"])                            # 0x00e00000
    f.write(payload)                                  # <-- the tag fixture is gone
argv = command(qemu, images, "shell", nand)           # guest boots from this copy
```

and the guest extracts that tar through `mknod /res/test-bdev b 31 10` = **mtdblock10 =
fe_test_data**. Reproduced locally with the identical `tarfile`/`USTAR_FORMAT` recipe:

```
tar stream first 4 bytes: b'shim'
ustar name field: b'shim/osal_stub.ko'
bytes 0x2020 window md5: 4cf75979677fab80057c455fb263d488
```

`0x2020` is exactly the FATB read length (`MTDAdvRead(fe_test_data, 20, "FATB", 0x2020,
out)`), so **the whole FATB read window was tar bytes and its first four bytes were
`shim`**. The tag check was correct; the fixture never reached that page. This is the
`shim` literally — not stale heap, not a coincidence in compressed data.

⇒ **The `fe_test_data` fixture cannot survive this harness.** Any recipe that puts a
record at `fe_test_data` offset 0 is silently destroyed at run start (§5).

---

## 3. Image geometry: the dd offsets *are* the page addresses (VERIFIED)

From `hw/block/nand.c` (qemu-9.2.4, pulled from the VM):

* `nfi_init` → `nand_init(d, NAND_MFR_SAMSUNG, 0xda)`; `nand_flash_ids[0xda] =
  {256, 8, 0, 0, LP_OPTIONS}`, and for `NAND_SAMSUNG_LP` `nand_realize` sets
  `page_shift = 11`, `erase_shift = 6` → **page 2048 B, erase block `2048<<6 = 0x20000`**
  (matches the guest's `/proc/mtd` column `00020000`), `size = 256<<20 = 0x10000000`,
  `nand_init_2048` → `oob_shift = 11-5 = 6` (**OOB 64 B**) and `pages = size>>11 =
  0x20000`.
* Layout decision:

```c
    if (blk_getlength(s->blk) >= (s->pages << s->page_shift) + (s->pages << s->oob_shift)) {
        pagesize = 0; s->mem_oob = 0;      /* OOB interleaved in the image */
    }
```

  `0x10000000 >= 0x10000000 + 0x200000` is **false** for our 256 MiB image ⇒
  `s->mem_oob = 1` ⇒ **OOB lives in the model's RAM `storage` buffer; the image holds
  page data only.**
* Read path (`nand_blk_load_2048`, `mem_oob` branch): `blk_pread(blk, SECTOR(addr)<<9,
  PAGE_SECTORS<<9, s->io, 0)` with `SECTOR(addr) = addr >> 9` ⇒ **page N is read from
  file offset `N*2048`, verbatim**.

Therefore:

| partition | manifest offset | page | image bytes the driver's `pread64` must return |
|---|---|---|---|
| `fe_test_data` | 0x00e00000 | 7168 | `46 41 54 42 …` (FATB fixture) |
| `fe_parameters` | 0x00f00000 | 7680 | `50 41 52 4d …` (PARM fixture) |
| `fe_power_curve` | 0x01000000 | 8192 | `50 57 52 43 …` (PWRC fixture) |

Host-side (VM) confirmation that the image really holds them
(`decode/probes/img_regions.sh`):

```
image md5: 1ddc0b62fb04ac57e69a0e875046cdef
fe_test_data       off 0xe00000  len 8224  md5 086a3f6031f4ad40f70faea70fa4f69e
fe_parameters      off 0xf00000  len 8192  md5 9866500e5a09b1cac02d676bcea37203
fe_power_curve     off 0x1000000 len 1056  md5 b1e05b13dc2a7880b4a947ed3cd151b4
0xe00000:  46 41 54 42 00 00 00 00 10 20 00 00 1f 10 08 00
0xf00000:  50 41 52 4d 00 00 00 00 00 20 00 00 bc 3f 08 00
0x1000000: 50 57 52 43 00 00 00 00 10 04 00 00 fb 07 01 00
```

…and the guest kernel agrees on the geometry the module branches on: `MTDRawRead`
decodes `MEMGETINFO` as `mtd_info_user` at `sp+0x38`, `+0x10 = writesize` compared
against 2048, `+0x14 = oobsize` compared against 64 and takes the `2048/64` branch
(`.text+0x538..0x548`) — i.e. the 2112-byte-per-page layout assumption is consistent on
both sides. **No ECC stripping and no OOB skew is possible in this configuration.**

One model detail worth handing to whoever writes the instrumentation, because it is the
only place a page can silently move: the LP chip needs **five** address cycles
(`2 col + 3 row`) before `nand_command(READ0)` runs, and the address is assembled as a
little-endian byte address with the row starting at bit 16, so
`PAGE(addr) = addr >> 11 = (col>>11) | (row<<5)` — the **column field's bits 11..15
carry page bits 0..4**. `mt8560-nfi.c`'s `case 0x30` pushes `MIN(val & 15, 4)` column
bytes then `MIN((val>>4)&15, 4)` row bytes. If Sony's NFI driver programs a byte offset
whose low 11 bits are non-zero, or a different col/row cycle count than the model
assumes, the model fetches a *different page* with no error anywhere.

---

## 4. Guest-visible readback probe — the result that contradicts itself (OPEN)

Design (`decode/probes/tagfix_mtd_probe.py`, `…_probe3.py`): boot the reference machine
in shell mode against the image **as-is** (`-drive if=mtd,format=raw,file=…/nand.img,
snapshot=on`; no staging, no write), `mknod` the mtd char nodes `c 90 <minor>`, `dd`
page 0 of each partition into `/res/r/…` (tmpfs) and `md5sum` it. Nothing fires the
driver. Probes and transcripts: this run id's `probes/` + `/tmp/tagfix-mtd-probe*.uart.log`.

```
mtd1  boot_1          0x000000  ba67750c53841a4d518998eaedd79e2f   <- image page 0  (CORRECT)
mtd2  part_info_1     0x200000  ba67750c53841a4d518998eaedd79e2f   <- image page 0
mtd3  part_info_2     0x400000  ba67750c53841a4d518998eaedd79e2f   <- image page 0
mtd5  mac_addr_1      0x600000  3d236bd4509173014d9586fabfbb7d71
mtd7  key_block_1     0x800000  e0deebd3c3f560212af17c68b9344bae   <- 2048 x 0xFF (ERASED)
mtd8  fe_bin_1        0xa00000  e0deebd3c3f560212af17c68b9344bae   <- ERASED
mtd9  fe_bin_2        0xc00000  e0deebd3c3f560212af17c68b9344bae   <- ERASED
mtd10 fe_test_data    0xe00000  e0deebd3c3f560212af17c68b9344bae   <- ERASED
mtd11 fe_parameters   0xf00000  e0deebd3c3f560212af17c68b9344bae   <- ERASED
mtd12 fe_power_curve  0x1000000 e0deebd3c3f560212af17c68b9344bae   <- ERASED
mtd13 ifcon_fw_backup 0x1100000 e0deebd3c3f560212af17c68b9344bae   <- ERASED
mtd14 kernel_1        0x1400000 e0deebd3c3f560212af17c68b9344bae   <- ERASED
mtd16 initrd_1        0x1a00000 da733a14ac3d1f5e7fc796e724510ef8   <- image page 0xa00000
mtd17 rootfs_normal_1 0x1f00000 da733a14ac3d1f5e7fc796e724510ef8   <- image page 0xa00000
mtd19 initrd_2        0x8e00000 da733a14ac3d1f5e7fc796e724510ef8   <- image page 0xa00000
```

with `e0deebd3c3f560212af17c68b9344bae = md5(2048 × 0xFF)`,
`84d04c9d6cc8ef35bf825d51a5277699 = md5(8192 × 0xFF)`,
`00594fd4f42ba43fc1ca0427a0576295 = md5(0xFF)` (byte probes: bytes 0..3 of mtd10/11/12
are all `0xFF`), and image page 0 `ba67750c…`, image page `0xa00000` `da733a14…`
(host-side, `probes/img_regions.sh`).

Second probe detail that matters: `fe_parameters` page 1 and page 2 (`dd bs=2048 skip=1`,
`skip=2`) returned the **same** `e0deebd3` page, i.e. those reads never moved.

**Why this is recorded as OPEN and not as the answer:** it contradicts the C97 driver.
In C97 the `MTDRawRead` of `fe_bin_1` (same partition, same 2048/64 branch) produced
real firmware — `[IDE] FE firmware CheckSum OK !!` against the hardcoded `0x37922226`
— while this probe reads `mtd8` page 0 as erased. Also `mtd17` reads as image page
`0xa00000` here, yet the same partition served the squashfs root at boot
(`VFS: Mounted root (squashfs filesystem) readonly on device 31:17`) — through the
**block** device (`mtdblock`), not the char device.

So the matrix establishes something real and narrow: **the guest's mtd *char* read path
does not faithfully deliver the image pages in a shell-mode boot** (partition offset
apparently dropped or a stale page re-served; `mtd1` correct, `mtd2/3` = master page 0,
`mtd16/17/19` = image page `0xa00000`, `mtd7..mtd14` = erased). It does *not* establish
which page the driver got in C97, and it must not be used as a fixture verdict.
Candidate mechanisms, both testable by one logging patch:

* **(a) model address decode** — col/row → page as in §3 (`(col>>11)|(row<<5)`): a
  guest that programs an 11-bit page-internal column plus a row number would be read
  32 pages away per row unit; a guest that programs a 64 KiB-granular row would be read
  correctly. Only a log line separates these.
* **(b) guest-side "adaptive mtd"** — the boot log prints
  `kernel adaptive mtd mechanism applied.` / `mt85xx_part_tbl_init success, v1 pit
  found !`; Sony's patched partition translation may implement char reads differently
  from block reads (the block path is demonstrably correct, the char path is not).

`(b)` would be a *guest-kernel* property, not an emulator bug, and it would mean the
tag reads cannot be satisfied by editing `nand.img` at all.

---

## 5. Corrected apply recipe

Two changes are needed regardless of how §4 resolves:

1. **Never put the FA table fixture in `fe_test_data`.** That partition is the harness's
   scratch channel (staged tar → `mtdblock10`). Either (i) stage the harness tar in a
   genuinely unused partition (none of the 25 are unused in this image — `ubi0`,
   `upg_status`, `init_wall_paper`, `fast_init_param` are candidates to *label* as
   scratch, and the partition table would have to be rebuilt to add one), or (ii) keep
   the FATB fixture and change the harness to stage through `fe_parameters` /
   `fe_power_curve` — which only works if those fixtures are relocated or the records
   are appended instead of replacing page 0. **The cheapest correct move: leave
   `fe_test_data` alone and accept the existing FW-embedded FA-table fallback
   (`read FA table from FW offset = 0xfe000`, gate 2 of `fe-tags.md` §4.3) — it is a
   real table and it already passes.** The FATB fixture is log-hygiene only; it is not
   worth a partition war.
2. **Keep `fe_parameters` @0xf00000 and `fe_power_curve` @0x1000000 exactly as they
   are.** Their offsets, page numbers and header bytes are verified correct against the
   model's geometry (§3) — nothing about the apply recipe is wrong for them, and the
   `dd` blast radius (`tags-fixture-build.md` §4.2) is still exactly the three extents.
   Restore path unchanged: `cp /tmp/nand.img.bak-TAGFIX /tmp/images-fe/nand.img`.

Pre-condition for calling anything fixed: the read side must be observable (§6). Today
a PASS on gates 1/3 would not distinguish "fixture read" from "lucky stale page".

---

## 6. Instrumentation + the decisive next experiments

`emulator-kit/` is out of this worker's scope, so these are handed over, not applied.

**(i) Read-side NFI log (the missing observable).** A logging-only patch in
`mt8560-nfi.c`, gated on the same env var as the trace:

```c
/* in nfi_write(), case 0x38 */   qemu_log_mask(LOG_GUEST_ERROR, "nfi: row=0x%x\n", val);
/* in nfi_write(), case 0x34 */   qemu_log_mask(LOG_GUEST_ERROR, "nfi: col=0x%x\n", val);
/* in nfi_transfer(), before the bus loop */
    qemu_log_mask(LOG_GUEST_ERROR,
                  "nfi-xfer: %s cfg=%x ctrl=%x sectors=%u size=%u dma=%x aut=%u\n",
                  writing ? "wr" : "rd", n->cfg, n->control, sectors, size, n->dma, automatic);
```

plus, in the read branch only, the page the chip actually served. `Mt8560Nfi` does not
expose the chip's `s->addr`, so the cheapest correct version logs the **row/col
registers** and lets the analysis compute `page = (col>>11)|(row<<5)` per §3 — that is
already enough to answer "did the driver ask for page 8192 and did the model serve
page 8192".

**(ii) Re-fire C97's own harness with the staging removed** (FATB gate should pass, and
`read FA table from FW offset` must then appear alone): that converts §2.2 from
"harness overwrote it" into a *demonstrated* gate-2 pass and isolates PWRC/PARM as the
only real question.

**(iii) The char-vs-block differential from §4** — the cheapest way to test hypothesis
(b): read the same partition page twice in one boot, once through `/dev/mtdN` (char) and
once through `/dev/mtdblockN` (block, e.g. `dd bs=512`), and compare md5s. If block is
right and char is wrong for the same page, the defect is in the guest's mtd char
translation, and no image edit can fix the tag reads.

**(iv) Do not** add tag injection to the model to "make the tag pass" — `fe-tags.md`
§4.1 already rejects that, correctly.

---

## 7. Doc corrections this analysis produced

1. **`tags-fixture-build.md` §7.1 is wrong.** It records the "embedded FA table in
   `fe_bin_1` at `+0xfe000`" as md5 `84d04c9d6cc8ef35bf825d51a5277699`. That region is
   **erased**: `84d04c9d…` is `md5(8192 × 0xFF)` (`python3 -c "hashlib.md5(b'\xff'*8192)"`),
   and the image at `0xafe000` starts `ff ff ff ff`. Any FATB-fidelity comparison
   anchored on that value is comparing two erased regions.
2. **`fe-tags.md` §3.1 ("the printed 4 bytes are stale heap") does not hold for
   `MTDRawRead`.** `sata_mt85xx_MTDRawRead.clone.6` checks `pread64`'s return against
   the requested length (`.text+0x750..0x758`, mismatch → print + `return -1`) and only
   `memcpy`s on the success path (`.text+0x780`), and it takes its "not enough data"
   exit (`.text+0x8f4`, rodata `+0x3b0`) when fewer bytes were produced. C97 prints
   neither error, so the PWRC buffer **was** filled from the pread destination
   (`sata_mtd_read_buf`) ⇒ the printed four bytes are page content. Only the
   `MTDAdvRead` path retains the "out may be unfilled" question (`fe-tags.md` §7.1) —
   and for FATB that question is now moot, because the tar explains `shim`.
3. **`fe-tags.md` §1.2's "the fallback already succeeds today"** stands, and §5's
   "benign with defaults" stands: none of the three mismatches is on the tip-to-tail
   path. What changes is the *reason*: one is a harness collision, two are an unresolved
   read-path/address problem.

---

## 8. Reproduce

```sh
# trace blindness (§1)
make vm-stage-file FILE=evidence/bx510-guest/bdpdrv/decode/probes/nfi_scan.py
make vm-exec CMD='python3 /tmp/nfi_scan.py /tmp/bdpdrv-runC97.mmio.log'
make vm-exec CMD='grep -c mt8560-nfi /tmp/bdpdrv-runC97.mmio.log'      # 0

# image geometry cross-check (§3)
make vm-script SCRIPT=evidence/bx510-guest/bdpdrv/decode/probes/img_regions.sh

# guest-visible readback (§4) — read-only, snapshot=on, no image write
make vm-stage-file FILE=evidence/bx510-guest/bdpdrv/decode/probes/tagfix_mtd_probe.py
make vm-stage-file FILE=evidence/bx510-guest/bdpdrv/decode/probes/tagfix_mtd_probe3.py
make vm-exec CMD='cd /home/aftermath/bx510-emu/emulator && python3 /tmp/tagfix_mtd_probe3.py \
  --qemu work/build/qemu-system-arm --images /tmp/images-fe \
  --uart /tmp/tagfix-mtd-probe3.uart.log --unimp /tmp/tagfix-mtd-probe3.unimp.log \
  --meta /tmp/tagfix-mtd-probe3.meta.json'
```

Note: `dd … 2>/dev/null` only works after `mount -t tmpfs tmpfs /dev; mknod /dev/null c 1 3`
— in shell mode `/dev` is on the read-only squashfs, and `od`/`tr` are absent from the
Sony rootfs (`md5sum`, `hexdump` exist), which is why every probe compares md5s and uses
single-byte md5 inversion (`md5(0xFF) = 00594fd4…`) instead of hexdumps.
