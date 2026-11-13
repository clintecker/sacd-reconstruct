# C103 — the READ(10) end-to-end harness: `sr0 attached` → `md5(sector) == firebird oracle`

Design + acceptance harness for the whole tip-to-tail goal: the guest gets a real
`/dev/sr0`, reads real Firebird sectors through the real stack (libata → sr →
ATAPI → FE mailbox → `0x5c400` descriptor DMA → host RAM), and the md5 of the
bytes the *guest* receives equals the md5 of the bytes the *fixture* contains.

**This document designs the measurement and the gate. It changes nothing in
`emulator-kit/` or `tools/`** (labelled rows for those files appear here as
proposals only) — and it fires nothing.

**Inputs (nothing here is re-derived):**

| input | what it contributes |
|---|---|
| `decode/c97-read-path.md` | the READ data path: `0x5c400` phys descriptor, bare type-0 completion, `0xbb` poison, the 2352 strip loop, model rows 17-24 |
| `decode/firebird-fixture.md` §5 | the oracle md5s (LBA 16 / 510 / 532104 / 510×10 / 1064207 / zeros) + the 2352-frame md5s + the BCD-MSF overflow trap |
| `decode/mt85xx-ioctl.md` §3.2/§3.3/§5 | **`qc->nbytes = 2064 × n` and CDB byte 10 = `0x98` reach the FE** — the host side of the 2064 question, and SR-10/SR-11 |
| `decode/sacdread-cpsa.md` §3.2/§4.2 | the seven `0x4010530x` commands, the 16-byte `_IOCTL_SACD_COMMAND`, and that the read leg is `open("/dev/sr0") + ioctl(0x8530)` — no new MMIO |
| `decode/daemon-gate-experiments.md` | the 14 startup gates, `sacd_gate_ioctl.c`'s shape (one machine-readable line per ioctl), the guest-env block |
| `decode/probe-injection.md` §4/§5 | the verdict-gate pattern this doc's §4 follows (anchored markers, synthetic-fixture selftest in both directions) |
| `decode/eh-recovery-map.md` | the fatal-signature lines the gate must exclude (`qc timeout`, `reset failed, giving up`, `SRST failed`) |
| `bdpdrv-runC101.uart.log` + `.meta.json` | the current top of the ladder: ATAPI + `scsi 0:0:0:0: CD-ROM` with **no `sr0`** |
| `decode/sr0-scan-seq.md` | **not present in the tree at the time of writing** — §6 row R1 is written so it can be replaced by that doc's evidence when it lands |

**Certainty labels.** *VERIFIED* = read out of an instruction, a log line already
in evidence, or a tool run reproduced in §8. *INFERRED* = consistent with
everything seen, not closed; the settling experiment is named.

---

## 0. Bottom line

1. **The ladder is five rungs, in this order, and the last one is the only
   measurement that can still surprise us:** (a) `sr0` attached with the
   fixture's exact capacity → (a2) a `dd` read of LBA 16 with no helper staged →
   (b)(c)(d) SG_IO `READ(10)` of LBA 16 / 510 / 532104 + the batch, EOF-boundary,
   zero-sector and past-EOF controls → (e) the daemon's own path
   (`ioctl 0x40105303`, 2064-byte SACD frames) where the **framing verdict** is
   finally measured instead of assumed. Legs (a2)-(d) run **before `bdpdrv.ko`
   loads**, so their bytes are attributable to libata/sr/FE alone.
2. **The model is NOT ready for a READ, and the failure will not look like a
   failure.** `bx510_fe_dispatch()` has no armed-descriptor branch; a READ post
   is `code == 0xa1` with non-zero args, so it falls into the IDENTIFY branch and
   is answered with a type-0x10 IDENTIFY payload. libata then takes the data
   phase from the window copy and reports **success with the IDENTIFY table as
   sector content**. The gate's discriminator for exactly this is "the three
   single-sector oracles must hash to three *different* values" (§4, check D0).
3. **Top risk:** the 2064-byte SACD frame. `qc->nbytes` is `2064 × n` while the
   CDB block count is `n` (`mt85xx-ioctl.md` §3.3, VERIFIED), so the FE is asked
   for 2064 bytes per sector on the daemon's path — a *third* framing next to
   the 2048 plain and 2352 raw ones. If the model serves 2048-per-sector into
   that buffer, every sector after the first is shifted, and the daemon path
   cannot produce a single correct md5. Leg (e) exists to *measure* which layout
   the drive is assumed to answer, and the verdict names it by offset.

---

## 1. Where the ladder actually starts (C101, VERIFIED)

`bdpdrv-runC101.uart.log` ends the enumeration story at:

```
290  ata1.00: ATAPI: SONY    BDPSACDEMUL, 1.00, max UDMA/33
294  ata1.00: configured for UDMA/33
295  scsi 0:0:0:0: CD-ROM            MTK 85xx - FA Mode 1.00        PQ: 0 ANSI: 5
```

Three facts about that state, each load-bearing:

* **`sr0` does not exist yet.** `sr_mod.ko` and `cdrom.ko` are staged in the
  rootfs (`/lib/modules/2.6.35/BDP/`) but the C-run command list does not insmod
  them and no `mknod /dev/sr0` line runs. The SCSI *device* is enumerated; the
  block *node* is not. That is the one row leg (a) adds.
* **The disc really is attached in this rig** — line 1 is the model's own
  `bx510: SATA ATAPI drive attached: …/firebird.iso (1064208 sectors)`, i.e. the
  C100-R1 machine-option (`BX510_MACHINE_OPTS='sata-disc=…'`) is in force. The
  gate re-checks that line first (§4, check A) because C95-C99 were five runs of
  protocol work interpreted against an *empty* `identify[]`.
* **The INQUIRY answer did not come from the model.** `grep -n inquiry
  emulator-kit/sony-bx510.c` returns nothing; no FE message carries INQUIRY data.
  *INFERRED*: `scsi 0:0:0:0` and the vendor/product string come from guest-side
  ATAPI plumbing (libata's simulated commands or `sata_mt85xx_mod.ko`), which is
  also where `READ CAPACITY` would be answered from `identify[]`'s word 100-103.
  **Consequence: leg (a) should need no new FE answer** — and the settling
  measurement is the `SRREAD mode=size` line (capacity must be
  `2179497984` = `1064208 × 2048`, the number the model printed at boot).

---

## 2. The ladder

Order is not cosmetic: (a2) needs no staged binary, (b)-(d) need no `bdpdrv`, and
(e) is the only leg that goes through `sacd_read.ko`. Each rung is a *separate
process invocation*, so a hang names its own rung.

| rung | guest command | expected | failure signature |
|---|---|---|---|
| **a** | `sr_read10 size /dev/sr0` | `rc=0 blkgetsize64=2179497984 blkssz=2048` | node missing (`errno=2`) / wrong capacity (`READ CAPACITY` unanswered, or `identify[]` empty) |
| **a2** | `dd if=/dev/sr0 of=/tmp/c103/lba16.dd.bin bs=2048 skip=16 count=1` then md5 | `c117ce4cef54ab625e33583156605721` | short/empty dump (md5 of nothing = `d41d8cd9…`), or a hang ⇒ block-layer `READ(10)` never completed |
| **b** | `sr_read10 read10 /dev/sr0 16 1 /tmp/c103/lba16.bin` | `c117ce4cef54ab625e33583156605721` | same hash as (c)/(d) ⇒ FE served the IDENTIFY block (§0.2); head still `0xbb` ⇒ no DMA at all |
| **c** | `sr_read10 read10 /dev/sr0 510 1 …/lba510.bin` | `e56de1add53c90dd30cf9232b29ddc93` (`SACDMTOC`) | as (b); a *constant* 2048-byte shift ⇒ CDB LBA decoded little-endian |
| **d** | `sr_read10 read10 /dev/sr0 532104 1 …/lba532104.bin` | `9ed18b47f67232ea972515df65cb6ac5` | as (b) |
| **d2** | `… 510 10 …/lba510x10.bin` (20480 B) | `45ccd7dfbf433a79d28e877d7441677c` (the daemon's master-TOC batch) | first N sectors right then desync ⇒ multi-sector length/split bug (§5 R2) |
| **d3** | `… 1064207 1 …` (the last valid LBA) | `d1c54ec6c395d7092ce06f04705d33ae` | zeros ⇒ a **zero-filled** DMA is indistinguishable from a correct read *except* by md5 — this sector has 14 non-zero bytes |
| **d4** | `… 0 1 …` (the system area) | `c99a74c555371a433d121f551d6c6398` (= `md5(2048 × 0x00)`, verified both ways) | head16 = `698c867c…` ⇒ `0xbb` poison ⇒ the FE advanced the state machine without DMAing |
| **d5** | `… 1064208 1 …` (one past EOF) | `rc=-1` + a non-zero sense triple | `rc=0` ⇒ row 23 not implemented (silent zeros); silence ⇒ libata `qc timeout` after 30 s |
| **e** | `sr_read10 sacdread init /dev/sacd_read` then `sr_read10 sacdread read /dev/sacd_read 510 2 …/sacd510.bin` | block 0.2048 @ offset **+12**, block 1 @ **+2076** (`e56de1ad…`, `68e5b97be9a6db48a3d477d77522d47d`) | the framing is *named* by the offset that matches (§4 G): +0/2048 ⇒ kernel re-packed, +0/2064 ⇒ payload-then-trailing, +16 ⇒ the "16-byte header" reading, +24 ⇒ a mode-2/2352 leak |
| **e0** | `sr_read10 read10 /dev/sr0 510 2 … --sacd` (2064 × 2 over plain SG_IO) | same offsets as (e) | a disagreement between (e) and (e0) puts the framing change in the **kernel/sacd_read layer**, not in the FE |

### 2.1 Why `dd` first (rung a2)

`dd` is busybox, so it needs nothing staged, and it exercises the *block layer's
own* `READ(10)` — a different CDB builder (`sr`'s read path) from the helper's.
If (a2) passes and (b) fails, the difference is the CDB: SG_IO sends exactly the
12 bytes we wrote. That is the only cheap way to separate "the FE serves reads"
from "the FE serves *our* reads".

### 2.2 Why SG_IO rather than `sg3-utils`

There is **no `sg3_utils` in this guest rootfs** (`daemon-gate-experiments.md`
§5), and the daemon's own TUR is `ioctl 0x40105306`, not an `sg` binary. So the
CDB-controlled rungs are a ~270-line C helper (`sr_read10.c`, appendix §9.2)
built with the same era toolchain and the same one-line-per-invocation output
shape as `sacd_gate_ioctl.c`. It is the *only* new guest binary the ladder
needs, and it deliberately has **no DECRYPT mode**: `0x40105304` blocks on the
GCPU/TrustZone worker with no timeout (`sacdread-cpsa.md` §4.3), and a ladder
must not be able to wedge the guest.

### 2.3 The oracles, precisely

All md5s are of the **2048 logical bytes**, taken from
`decode/firebird-fixture.md` §5.1/§5.2 (independently re-derived there with
`dd | md5sum` and with literal-frame construction). Two of them are weak on
purpose-by-nature and strong only because they are md5s:

* LBA 1064207 has **14** non-zero bytes — a zero-filled DMA differs from truth by
  14 bytes and is invisible to a glance;
* LBA 0 is *genuinely* all-zero, which is why it is paired with the `0xbb` head
  canary rather than used as a data oracle.

---

## 3. Model-side readiness for `READ(10)`

### 3.1 Verdict: rows 17-20 already exist; rows 21-24 do not

| # | row (from `c97-read-path.md` §5) | current `emulator-kit/sony-bx510.c` | verdict |
|---|---|---|---|
| 17-20 | store `0x5c400/404/408/40c`, lossless readback, `& 1` = armed, never auto-clear | `fe_dma[4]`, written at `case 0x5c400..0x5c40c` (write), read back at the same offsets (read) — VERIFIED by reading both arms | **ready** |
| 21 | `(fe_dma[3] & 1) && cdb[0] ∈ {0x28,0xA8,0xBE}` ⇒ decode CDB, build `fe_dma[1]` bytes from `sata_blk`, `stb_phys` to `fe_dma[0]`, post ONE type-0 | **absent.** The dispatch order is `type == 0x10` → `code == 0xa1 && arg == 0` (loader offer) → `code == 0xa1` (IDENTIFY, type-0x10) → else type-0 | **missing** |
| 22 | armed descriptor but a non-READ opcode ⇒ log, serve a plain type-0, do not DMA | absent | missing |
| 23 | `lba + nsec > blk_getlength()/2048` ⇒ post `byte3 != 0` | absent (and `sata_blk` is *never read*: the only use is `blk_getlength()` in `bx510_sata_build_identify`) | missing |
| 24 | IDENTIFY / chk / ack / reset unchanged | present | ready |

### 3.2 What a READ does today (the smoking gun, INFERRED from the code)

`data_xfer` posts `w0 = 0xa1 << 24 | …` with `w1..w3` = the CDB
(`c97-read-path.md` §4.1). For a plain `READ(10)` at LBA 16 the words are
`w1 = 0x00000028`, `w2 = 0x00001000`, `w3 = 0x00000001` — so `arg != 0` and
`code == 0xa1`: the current dispatch takes the **IDENTIFY** branch and posts a
type-0x10 offer of `FE_IDENT_OFF`. The guest's bottom half then runs the
direction-1 window→buffer `memcpy` (`0x4850`) into the bounce buffer and libata
copies 2048 bytes of *identify table* into the sg buffer — with `byte3 = 0`,
i.e. **success**. No timeout, no error line, wrong bytes. This is exactly the
destructive case `c97-read-path.md` §1.3 predicted, and it is why the gate's
first payload check is "the three oracles are three *different* hashes".

### 3.3 The `0xbb` poison is a free canary — on the plain path only

`qc_issu_task` 0x7468 poisons `min(priv+0x54, 16)` bytes of the **bounce buffer**
before every device→host transfer, and the descriptor's target *is* that buffer
(`priv+0x50 = (u32)(priv+0x4c + 0x40000000)`). So:

* **plain path** (`priv+0x1c == 0`): the driver copies the whole bounce buffer to
  the sg buffer (`0x554c`), so a no-DMA read shows `0xbb` × 16 at the head of
  *user* data. Verdict check E gates on it (`head16 = 698c867c…`).
* **raw 2352 path**: the strip loop copies from `frame + 16` (or +24), i.e.
  *past* the poisoned 16 bytes, so the poison is invisible after stripping — the
  md5 comparison is the only detector there.
* The tail poison (`0xbbbbbbbb` at `buf+len-4`) is **ATA-class only**
  (`priv+0x38 ∈ 1..4`), and these are ATAPI protocols 5/6/7, so the tail canary
  does not apply on this path — do not build a check on it.

### 3.4 The framing triple, and which number is authority

| framing | who asks for it | bytes/sector | payload offset | state |
|---|---|---|---|---|
| plain | `READ(10)`/`READ(12)`, no vendor byte | 2048 | 0 | DECODED (c97 §4.1) |
| raw CD | `READ CD 0xBE` (driver rewrote the CDB; `priv+0x18 ∈ {8,9,10}`) | 2352 | +16 (mode 1) / +24 (mode 2) | DECODED (c97 §4.2) |
| SACD | `READ(10)` with **byte 10 = `0x98`** (`_IDECLI_OddRead`) | **2064** | **+12** (INFERRED) | host side VERIFIED (`mt85xx-ioctl.md` §3.2/§3.3), drive side measured by leg (e) |

Two rules the model must obey, both already settled by the decode:

1. **`0x5c404` is the authority for the byte count**, never the CDB block count
   ("A model that recomputes the length from the CDB's block count would truncate
   every SACD read" — `mt85xx-ioctl.md` §5.1). `0x5c404` is always
   `nsec × 2048`, `nsec × 2352` or `nsec × 2064`.
2. **The CDB byte-10 flag is the framing discriminator** the FE can see, and it
   must not be treated as a malformed group number (`mt85xx-ioctl.md` §3.2: this
   kernel's `scsi_command_size_tbl` is patched to 12 for `0x28` so byte 10 does
   arrive).

Everything else in the READ recipe is unchanged from `c97-read-path.md` §3: one
bare type-0 (`w0 = w1 = w2 = w3 = 0`), then `0x5c804 |= 0x10000`, then drain.

---

## 4. The verdict script

`decode/read10_verdict.sh` — post-fire, Mac-side, on the pulled evidence. Shape
follows `probe-injection.md` §5: **anchored** fixed markers (the guest echoes
every command line, so unanchored counts double), one line per check, a machine
summary at the end, and an exit code that means something:

```
0  READ10_VERDICT=PASS
1  READ10_VERDICT=FAIL        (a check broke)
2  READ10_VERDICT=INCOMPLETE  (a class could not run — e.g. no MMIO log)
```

### 4.1 Guest → verdict contract

One space-separated field list per line, no padding (the guest script and helper
in §9 emit exactly this):

```
SRREAD   mode=size dev=<p> rc=<n> errno=<n> blkgetsize64=<n> blkssz=<n>
SRREAD   mode=read10 lba=<n> nsec=<n> len=<n> rc=<n> errno=<n> sense=<6hex> host=<4hex> driver=<4hex> file=<p>
SACDREAD cmd=0x401053.. [lba= nsec= len=] ret=<n> errno=<n> result=<n> [file=<p>]
MD5      name=<label> off=<byte offset in dump> hash=<md5 of the next 2048 B>
MD5      name=<label> head16=<md5 of the first 16 B>
LADDER   <step> <PASS|FAIL> <detail>      # PASS = the measurement was TAKEN
LADDER   done <measured>/<attempted>
```

`sense=` is the triple `bdpdrv` prints as `SenseKey: %06x` —
`(status & 0xf) << 16 | ASC << 8 | ASCQ` — the same mask
`_IDECLI_OddTestUnitReadyLoop` compares (`sacdread-cpsa.md` §2.2).

### 4.2 The checks

| id | check | why it is here |
|---|---|---|
| A | `bx510: SATA ATAPI drive attached: …(1064208 sectors)` ×1 | C100-R0: five runs were interpreted against an empty `identify[]` |
| B | `SRREAD mode=size … rc=0 blkgetsize64=2179497984 blkssz=2048` | leg (a): behavioural (capacity), not keyed on an unobserved printk |
| C | 0 × {`qc timeout`, `reset failed, giving up`, `SRST failed`, `failed to IDENTIFY`} | the fatal-signature reader (`eh-recovery-map.md`) |
| D0 | the three single-sector hashes are **3 distinct values** | the un-armed-dispatch signature (§3.2) |
| D1-5 | the five 2048 oracles | the actual acceptance criterion |
| E | LBA 0 head16 = `4ae71336…` (zeros) and **no** head16 = `698c867c…` (0xbb) | the free canary (§3.3) |
| F | past-EOF: `rc=-1`, never `rc=0`, and a non-zero sense triple | model row 23 |
| G | leg (e): `ret=0`, 12 measured offsets, framing decided **here** | the measured framing verdict |
| H | MMIO: `W 05c40c = 1`, `W 05c404 ∈ {800, 5000, 1020}`, `W 05c004 = 28`, `W 05c008 = fe01`, `W 05c00c = 980002` | proves the descriptor was armed *for this transfer*, the length was the driver's (`0x800`/`0x5000`/`0x1020`), the LBA was big-endian (`0x1FE`), and the vendor byte `0x98` reached the FE (SR-11) |
| — | `terminal_marker`, `payload_size` | INFO only |

Check H is the one that distinguishes "the guest got the right bytes" from "the
guest got the right bytes *from the FE*": `0x5c404 = 0x1020` (4128 = 2064 × 2)
cannot be produced by any path other than the 2064 SACD request, and
`W 05c00c = 980002` is `cdb[8..11] = 02 00 98 00` little-ended.

### 4.3 The framing decision (check G)

The guest reports 12 hashes for the 2-sector 5303 dump; the *verdict* decides:

| measurement | layout | reading |
|---|---|---|
| b0@+12 and b1@+2076 | `payload_at_12_stride_2064` | the drive answers 2064-byte SACD frames, 12-byte header — matches `memcpy(buf + i*2048, out + 12, 2048)` in the decrypt leg and `large-image-interface.md`'s "12-byte header + 2048 logical + 4 trailing" |
| b0@+0 and b1@+2064 | `payload_at_0_stride_2064` | payload first, 16 trailing bytes/sector |
| b0@+0 and b1@+2048 | `payload_at_0_stride_2048` | the kernel re-packed 2048-per-sector into a 2064-sized buffer; the tail 16 × n bytes are stale |
| b0@+16 | `payload_at_16_stride_2064` | `DAEMON-MAP.md`'s "2048 payload + 16-byte header" phrasing — 4 bytes off from the code |
| b0@+24 | `payload_at_24_stride_2064` | a mode-2 subheader is in play — investigate a 2352 leak |
| none | `unresolved` | the bytes are not the fixture's at all (wrong sector, wrong disc, canned block) |

**Accept = `payload_at_12_stride_2064` only.** Any other value is a *finding*,
not a pass: the daemon's decrypt leg consumes exactly `out+12` and `2064` bytes,
so a different layout means the CPSA path cannot work end-to-end even though the
read "succeeded".

### 4.4 Validation performed (the gate can fail, in named ways)

Built on the Mac and run against five fixtures — the same discipline as
`probe-injection.md` §6.3 (a gate that cannot fail is not a gate):

| fixture | expectation | result |
|---|---|---|
| synthetic PASS transcript + synthetic MMIO trace (§8) | PASS, 28/28 | `READ10_VERDICT=PASS`, exit **0** |
| **`bdpdrv-runC101.uart.log`** (the real current top of the ladder) | FAIL: no capacity, no oracles, no 5303, no `LADDER done` | exit **1**, 13 checks fail |
| synthetic "model not ready" (all three reads return one canned hash) | FAIL, naming D0 + the three oracles + G | exit **1**, exactly those 5 |
| synthetic "wrong framing" (payload packed at +0, stride 2048) | FAIL, naming *only* G with `payload_at_0_stride_2048` | exit **1**, 1 failure |
| synthetic truncation (no `LADDER done`) | FAIL, naming *only* completion | exit **1**, 1 failure |
| PASS transcript with **no** MMIO log | INCOMPLETE | exit **2** |

`sh -n` clean (dash), `shellcheck -s sh -S style` → rc 0, no findings.

### 4.5 The differential table (what each failure means)

| failing check | reading |
|---|---|
| A | the disc was not attached (`BX510_MACHINE_OPTS`), or the ISO on the VM is not the pinned one — the run is not C103 |
| B | `sr0` did not attach, or `READ CAPACITY` answered 0 ⇒ every later leg is meaningless; check the `sr` attach printk (recorded as INFO) and the `identify[]` capacity |
| C | a fatal libata path fired: silence/asynchrony is a *rig* verdict first (`AGENTS.md`: suspect the rig before the target) |
| D0 | the FE answered every read with the same canned block — un-armed READ dispatch (§3.2), i.e. model rows 21-24 missing |
| D1-5 | wrong bytes: compare *which* oracles pass. All fail ⇒ no DMA; head `0xbb` ⇒ no DMA; a constant 8-byte shift ⇒ mode-2 framing on a raw read; a constant 2048 shift ⇒ little-endian LBA decode; only `lba510x10` fails ⇒ multi-sector split/length (§5 R2) |
| E | the head is poison at an LBA whose content is not zeros ⇒ the state machine advanced without a transfer |
| F | past-EOF returned data ⇒ row 23 clamps instead of erroring; past-EOF timed out ⇒ the model stayed silent (silence is a 30 s libata timeout, not an error) |
| G | framing ≠ 12/2064: the 2064 question is answered — in the *wrong* direction. Read the layout name, do not re-run blindly |
| H (any) | the FE never saw an armed READ descriptor: `W 05c404` absent ⇒ `data_xfer` took the non-mailbox body (`priv+0x220 != 3`, c97 §9 row 1) — a driver-state problem, not a payload problem |

---

## 5. Risks

**R1 — the 2352 rewrite path (`priv+0x18 ∈ {8,9,10}`).** If the vendor CDB `0x46`
(`hw_chg_st` 0x4360, `cdb[1] == 1`) ever runs before the ladder, the driver
rewrites `0x28/0xA8` into `0xBE` and `0x5c404` becomes `nsec × 2352`, so rungs
(b)-(d) would fail with a *mode-1-correct* 2352 payload that the driver strips
back to the oracle only if `frame[15] == 1`. **Settling observable:** the trace's
`W 05c404` for a 1-sector read is `800` (plain) or `930` (2352); and check H
asserts `800`/`5000`/`1020`. If `930` appears, the run has raw mode on and the
oracles must move to `firebird-fixture.md` §5.2's frame md5s. Nothing in the C101
command list sends `0x46`, so raw mode should be **off** — INFERRED until the
trace says so.

**R2 — multi-sector transfers (`0x5c404 != 2048`).** Three ceilings, all decoded,
none of them equal:

| ceiling | value | who enforces | consequence if exceeded |
|---|---|---|---|
| `atapi_xlat` transfer count | `0xFC00` = 64512 B | libata | `31 × 2048 = 63488` fits, `32 × 2048 = 65536` does **not**; `31 × 2064 = 63984` fits, `32 × 2064 = 66048` does not |
| `qc_issu_task` length cap | `0x12800` = 75776 B | the vendor driver | `37 × 2048` fits exactly, `32 × 2352 + 512` = 75776 is the constant's arithmetic; above it the driver takes an error path |
| block-layer split | — | libata/scsi | a request above the queue's `max_sectors` is split into several qcs, each with its own `0x5c404` |

So the ladder keeps every rung at ≤ 10 sectors (the batch) — well inside both
ceilings — and R2's real test is a **separate** probe: `nsec = 32` plain and
`nsec = 32` with `--sacd`. **Settling observable:** whether the batch md5 desyncs
after sector *k* (the clamp truncated) or whether two `W 05c404` writes appear
with a smaller length each (the layer split). Do not raise the batch count before
that probe runs.

**R3 — DMA address translation (bus vs physical).** `0x5c400` is
`(u32)(buf_va + 0x40000000)` = `buf_va − 0xc0000000`, and `kernel-iomap.md`
pins page offset `0xc0000000`, physical offset 0 (VERIFIED). For a kmalloc'd
bounce buffer this equals the machine physical address **only while RAM is
entirely lowmem**: with the 3G/1G split, lowmem ends at `0x30000000` (768 MiB)
and `sony-bx510.c` gives the machine 512 MiB — so every kmalloc'd buffer is
lowmem and the identity holds (INFERRED, arithmetic on the two documented
constants). **Model requirement:** treat `0x5c400` as machine-physical, DMA only
into `[0, ram_size)`, assert `len <= 0x12800` and `phys + len <= ram_size`, and
log a `LOG_GUEST_ERROR` on violation so a translation bug is loud. If a later rig
raises RAM above 768 MiB, this risk re-opens.

**R4 — cache coherency on the emulated ARM.** The driver publishes with `dsb`
plus `outer_cache->fn` (`data_xfer` 0x5818..0x5830, whose literal is 0 ⇒ no-op)
and invalidates on completion (`0x48ec`). The model performs none of it. **Safe
for TCG** (INFERRED, and it is the strong direction): QEMU's TCG has no modelled
data cache, so a guest store and the device's `stb_phys` hit the same
`MemoryRegion`, and the guest's invalidate is a no-op over memory that is already
correct. Two consequences worth writing down: (i) a model that *only* works
because it is coherent would silently break under KVM or on hardware — that is a
labelling duty, not a bug; and (ii) ordering still matters in one direction: the
`0xbb` poison must be *guest* stores that land before the doorbell write, which
holds because TCG executes them in program order — but the model must not
speculate a DMA on a `0x5c400`/`0x5c404` write (c97 §1.2: the descriptor is
armed *before* the mailbox words, on the very first READ `priv+0x50` may still be
the previous command's value). Key everything on the `0x5c020` doorbell.

---

## 6. Run recipe

### 6.1 Staging (added to the existing C-run set)

| artifact | how it enters the guest |
|---|---|
| `cdrom.ko`, `sr_mod.ko` | already in the rootfs: `/lib/modules/2.6.35/BDP/` — only an `insmod` line is missing |
| `srread` (from `sr_read10.c`) | `--extra-file srread=<built>` then `chmod 0555` (the `sacdgate` shape) |
| `sr_read_ladder.sh` | `--extra-file sr_read_ladder.sh=<path>`, run with `sh` |
| the disc | `BX510_MACHINE_OPTS='sata-disc=/home/aftermath/sacd-verify/firebird.iso'` (C100-R1) |
| the trace | `BX510_TRACE=1` + `--unimp` — without it there is no `0x5c4xx` evidence at all (C95 had zero such accesses) |

Version pinning that must be in the pulled metadata: `firebird.iso`
sha256 `1d8f0697…` / md5 `217ea92b…` (`firebird-fixture.md` §1), i.e. the same
image the model was given. A C103 run against a different ISO is not C103.

### 6.2 Command-list rows to insert (proposal — `tools/` not touched)

Insert **before** `insmod …/osal_stub_a.ko` (so legs a2-d cannot be attributed to
`bdpdrv`), then the post-phase rows after the `sacd_read.ko` gate:

```sh
# ── C103 pre-phase: the ODD stack, then the ladder that needs no bdpdrv ─────
insmod /lib/modules/2.6.35/BDP/cdrom.ko;  echo CDROM_RC=$?
insmod /lib/modules/2.6.35/BDP/sr_mod.ko; echo SRMOD_RC=$?
mknod /dev/sr0 b 11 0;                    echo SR0_MKNOD=$?
PHASE=pre  HELPER=/res/shim/srread sh /res/shim/sr_read_ladder.sh; \
    echo LADDER_PRE_RC=$?

# … existing stack: osal_stub_a → drvcli → osal_stub → feboot → bdpdrv …
insmod /res/shim/sacd_read.ko minor=201;  echo SACDREAD_INSMOD=$?
mknod /dev/sacd_read c 10 201
# ── C103 post-phase: the daemon's own ioctl path, 2064-byte framing ─────────
PHASE=post HELPER=/res/shim/srread sh /res/shim/sr_read_ladder.sh; \
    echo LADDER_POST_RC=$?
```

The existing guest-env block from `daemon-gate-experiments.md` §4 (tmpfs `/dev`,
tmpfs `/tmp`, `mount -t proc proc /res/proc`) is a prerequisite: `/tmp/c103` is
where the dumps land, and `/dev` must be writable for `mknod`.

### 6.3 Evidence separation (do not read across these)

| artifact | carries | must not be used for |
|---|---|---|
| `bdpdrv-runC103.uart.log` | boot, model `printf`, kernel printk, the ladder's `SRREAD`/`SACDREAD`/`MD5`/`LADDER` lines | byte-level protocol claims (it is text; the OSAL stub's IRRC thread interleaves printk throughout) |
| `bdpdrv-runC103.mmio.log` (gzipped tail committed) | `0x5c4xx` / `0x5c0xx` / `0x5c8xx` sequence | payload claims — the trace has no payload bytes |
| `bdpdrv-runC103.meta.json` | run identity: qemu path, stub/bdpdrv hashes, payload size, `terminal_marker` | anything behavioural |
| the `/tmp/c103/*.bin` dumps | the actual payload bytes | — (VM-side only; 2 GiB stays VM-side, md5s cross the channel) |

---

## 7. Open items, labelled

| item | label | settling experiment |
|---|---|---|
| `sr`'s attach printk string in this kernel | unobserved | leg (a) records it (INFO); promote it to an exact anchor on the first passing run (expectation-freshness rule) |
| `READ CAPACITY` answered guest-side (libata simulated) rather than by the FE | INFERRED | `SRREAD mode=size` = `2179497984` with **no** FE post in the trace around it |
| the 2064 SACD frame layout (payload at +12) | INFERRED | leg (e) check G; a +16 result refutes the code's `out+12` reading or the drive's framing |
| SACD IOCTL `u4Result` success polarity for 5303 | INFERRED (0; the CPSA commands are `>= 0` with `0x68000000` positive) | the helper prints `result=` as INFO; treat only `ret=0` as gating |
| whether the daemon's decrypt leg can ever be satisfied | known wall | out of scope: `TzServiceCall` (`sacdread-cpsa.md` §4.3). C103's oracles compare **ciphertext to ciphertext**, which is valid end-to-end for the read path and must be labelled that way |
| the daemon itself (`sacd_extract_160 -S`) reading a track | not in this harness | gates 10-14 (`daemon-gate-experiments.md`) then a single `DISC_OPEN`; a separate stage — C103 stops at "the real stack returns the fixture's bytes" |
| raw mode (R1) actually off during C103 | INFERRED | `W 05c404 = 800` for a 1-sector rung in the trace |

---

## 8. Reproduce (everything this doc asserts, without a fire)

```sh
# 1. the model's current dispatch and the missing read leg (VERIFIED claims)
grep -n "bx510_fe_dispatch\|blk_pread\|blk_getlength" emulator-kit/sony-bx510.c

# 2. no INQUIRY answer in the model (basis of §1's third bullet)
grep -n "inquiry" emulator-kit/sony-bx510.c || echo "no model INQUIRY"

# 3. the two 16-byte canary constants in §4 (E)
python3 -c "import hashlib;print(hashlib.md5(b'\xbb'*16).hexdigest());print(hashlib.md5(bytes(16)).hexdigest());print(hashlib.md5(bytes(2048)).hexdigest())"
#   698c867c835081965870124d1b90f66e / 4ae71336e44bf9bf79d2752e234818a5 / c99a74c555371a433d121f551d6c6398

# 4. the C helper's exact output formats (host twin; also the failure paths)
gcc -O2 -Wall -Wextra -std=gnu99 -o /tmp/sr_read10 sr_read10.c
/tmp/sr_read10 read10 /nonexistent 510 2 /tmp/y.bin --sacd
/tmp/sr_read10 sacdread read /nonexistent 510 2 /tmp/z.bin

# 5. the gate itself, both directions (§4.4) — 5 fixtures + 1 truncation
sh read10_verdict.sh synth-pass.uart.log synth-pass.mmio.log ; echo rc=$?   # 0
sh read10_verdict.sh bdpdrv-runC101.uart.log              ; echo rc=$?      # 1

# 6. guest-side build + syntax gates (VM, era toolchain)
~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -Wall -Wextra -std=gnu99 \
    -o /tmp/srread sr_read10.c
sh -n sr_read_ladder.sh && shellcheck -s sh -S style sr_read_ladder.sh
```

---

## 9. Appendix — the three artifacts, as validated

### 9.1 `decode/sr_read_ladder.sh` (guest, POSIX sh / busybox)

```sh
#!/bin/sh
# sr_read_ladder.sh — C103 guest-side READ(10) ladder. MEASURES ONLY.
# Every oracle comparison happens Mac-side (decode/read10_verdict.sh): the guest
# has no copy of the 2 GiB ISO, and the oracles are recorded constants
# (decode/firebird-fixture.md §5).
#
# Two phases, run in two places on purpose (evidence separation):
#   PHASE=pre   immediately after the SATA stack is insmodded, BEFORE bdpdrv.ko.
#               Legs (a)(a2)(b)(c)(d) + the 2064 SG_IO differential (e0).
#               Nothing here involves bdpdrv, so a PASS attributes the bytes to
#               libata/sr/FE alone and the MMIO log carries no bdpdrv FE traffic
#               to read across.
#   PHASE=post  after bdpdrv.ko + sacd_read.ko: leg (e), the daemon's own
#               ioctl 0x40105303 path.
#
# Output contract (one space-separated field list per line, no padding):
#   SRREAD   mode=size|read10 lba= nsec= len= rc= sense= host= driver= file=
#   SACDREAD cmd=0x401053.. lba= nsec= len= ret= errno= result= file=
#   MD5      name=<label> off=<offset in dump> hash=<md5 of 2048 B>
#   MD5      name=<label> head16=<md5 of the first 16 B>
#   LADDER   <step> <PASS|FAIL> <detail>   (PASS = the measurement was taken,
#                                           NOT that the md5 matched)
#   LADDER   done <measured>/<attempted>
#
# Env: SR0=/dev/sr0  SACD=/dev/sacd_read  HELPER=/res/shim/srread
#      OUT=/tmp/c103  PHASE=pre|post  SACD_DIFF=1
SR0=${SR0:-/dev/sr0}
SACD=${SACD:-/dev/sacd_read}
HELPER=${HELPER:-/res/shim/srread}
OUT=${OUT:-/tmp/c103}
PHASE=${PHASE:-pre}
SACD_DIFF=${SACD_DIFF:-1}
mkdir -p "$OUT"
ok=0; total=0

# hash_at <file> <offset> <len> — busybox has md5sum/head/tail/cut; it has no
# od/tr (tagfix-mtd-trace.md §appendix), so every byte comparison is an md5.
hash_at() {
  tail -c "+$(( $2 + 1 ))" "$1" 2>/dev/null | head -c "$3" | md5sum | cut -d' ' -f1
}
md5_of() {    # md5_of <label> <file> <offset within the dump>
  echo "MD5 name=$1 off=$3 hash=$(hash_at "$2" "$3" 2048)"
}
head16_of() { # head16_of <label> <file> — the 0xbb poison canary
  echo "MD5 name=$1 head16=$(head -c 16 "$2" | md5sum | cut -d' ' -f1)"
}
step() { total=$((total + 1)); ok=$((ok + 1)); echo "LADDER $1 PASS $2"; }

# read_one <label> <lba> <nsec> [--sacd] — the helper computes its own byte
# count (2048 x nsec, or 2064 x nsec with --sacd), always prints its SRREAD
# line, and exits non-zero on failure so this `if` sees the verdict.
read_one() {
  if $HELPER read10 "$SR0" "$2" "$3" "$OUT/$1.bin" "$4"; then
    if [ "$4" = "--sacd" ]; then
      i=0
      while [ $i -lt "$3" ]; do
        for d in 0 8 12 16; do
          md5_of "$1" "$OUT/$1.bin" $(( i * 2064 + d ))
        done
        i=$((i + 1))
      done
    else
      md5_of "$1" "$OUT/$1.bin" 0
      if [ "$3" = "1" ]; then head16_of "$1" "$OUT/$1.bin"; fi
    fi
    step "$1" "lba=$2 nsec=$3"
  else
    echo "LADDER $1 FAIL lba=$2 nsec=$3"
  fi
}

if [ "$PHASE" != post ]; then
  # ── (a) sr0 present: the block device must report the fixture's capacity ──
  if $HELPER size "$SR0"; then step a "size probed"; else echo "LADDER a FAIL size"; fi

  # ── (a2) the same read with no helper staged: dd through the block layer ──
  if dd if="$SR0" of="$OUT/lba16.dd.bin" bs=2048 skip=16 count=1 2>/dev/null; then
    md5_of lba16.dd "$OUT/lba16.dd.bin" 0
    step a2 "dd LBA 16"
  else
    echo "LADDER a2 FAIL dd"
  fi

  # ── (b)(c)(d) the 2048-byte oracles, CDB-controlled through SG_IO ─────────
  read_one lba16      16      1     # oracle 1: ISO9660 PVD
  read_one lba510     510     1     # oracle 2: SACDMTOC master TOC
  read_one lba532104  532104  1     # oracle 3: mid-disc audio sector
  read_one lba0       0       1     # all-zero sector: the poison control
  read_one lba510x10  510     10    # the daemon's master-TOC batch shape
  read_one lba1064207 1064207 1     # last valid LBA: a read that MUST work
  # past EOF: must FAIL with a sense triple, not return zeros (model row 23) —
  # here success is the failure, so the helper's non-zero exit is the PASS.
  if $HELPER read10 "$SR0" 1064208 1 "$OUT/past_eof.bin"; then
    echo "LADDER past_eof FAIL (LBA 1064208 returned data)"
  else
    step past_eof "rejected"
  fi
fi

if [ "$PHASE" = post ]; then
  # ── (e) the daemon's own path: /dev/sacd_read ioctl 0x40105303, 2064 x n ──
  $HELPER sacdread init "$SACD"
  if $HELPER sacdread read "$SACD" 510 2 "$OUT/sacd510.bin"; then
    for off in 0 4 8 12 16 24 2048 2064 2072 2076 2080 2088; do
      md5_of sacd510 "$OUT/sacd510.bin" $off
    done
    step e "lba=510 nsec=2 via ioctl 5303"
  else
    echo "LADDER e FAIL ioctl 5303"
  fi
  # ── (e0) differential: the same 2064 framing without sacd_read.ko/bdpdrv ──
  if [ "$SACD_DIFF" = 1 ]; then
    read_one sacd_sg 510 2 --sacd
  fi
fi

echo "LADDER done $ok/$total"
```

### 9.2 `decode/sr_read10.c` (guest helper — the only new binary)

```c
/* sr_read10.c — the C103 read ladder's only non-shell tool.
 *
 * Three modes, each printing exactly one machine-readable line so the Mac-side
 * verdict (decode/read10_verdict.sh) can grep it verbatim:
 *
 *   sr_read10 size     <dev>
 *     SRREAD mode=size dev=… rc=… errno=… blkgetsize64=… blkssz=…
 *
 *   sr_read10 read10   <dev> <lba> <nsec> <outfile> [--sacd]
 *     SRREAD mode=read10 lba=… nsec=… len=… rc=… errno=… sense=… file=…
 *
 *   sr_read10 sacdread init <dev>
 *     SACDREAD cmd=0x40105301 ret=… errno=… result=…
 *   sr_read10 sacdread read <dev> <lba> <nsec> <outfile>
 *     SACDREAD cmd=0x40105303 lba=… nsec=… len=… ret=… errno=… result=… file=…
 *
 * `read10` is a plain SG_IO executor: it builds the CDB itself, so the ladder
 * controls LBA, block count and the Sony vendor byte 10 (0x98, the SACD flag
 * _IDECLI_OddRead sets — mt85xx-ioctl.md §3.1) instead of hoping the block
 * layer picks them. With --sacd the transfer buffer is 2064 x nsec — the byte
 * count the kernel's own mt85xx_ioctl path asks for (mt85xx-ioctl.md §3.3) —
 * which makes this mode the framing differential against /dev/sacd_read.
 *
 * `sacdread` drives the daemon's own path: the 16-byte _IOCTL_SACD_COMMAND
 * { u4Result, u4Offset, u4Sectors, pu1Buf } (sacdread-cpsa.md §2.1), INIT
 * first because that is the daemon's order (daemon-gate-experiments.md §1).
 * DECRYPT (0x40105304) is deliberately absent: it blocks on the GCPU/TrustZone
 * worker with no timeout (sacdread-cpsa.md §4.3) — a ladder must not be able to
 * wedge the guest.
 *
 * sense= is the triple bdpdrv itself prints as "SenseKey: %06x":
 * (SCSI status & 0x0f) << 16 | sb[12] << 8 | sb[13] (ASC, ASCQ)
 * — the same mask _IDECLI_OddTestUnitReadyLoop compares (sacdread-cpsa.md §2.2).
 *
 * Exit status: 0 the operation succeeded, 1 it failed (the line still prints),
 * 2 usage error.
 *
 * Build (VM, era toolchain, dynamic against Sony's libc — the shape
 * daemon-gate-experiments.md §2 uses for sacd_gate_ioctl.c):
 *   ~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -Wall -Wextra -std=gnu99 \
 *       -o /tmp/srread sr_read10.c
 */

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

#include <scsi/sg.h>

#ifndef SG_IO
#define SG_IO 0x2285u              /* identical on every Linux since 2.6 */
#endif
#ifndef BLKGETSIZE64
#define BLKGETSIZE64 0x80081272u   /* asm-generic/ioctl.h, 2.6.35 */
#endif
#ifndef BLKSSZGET
#define BLKSSZGET 0x1268u
#endif

#define SACD_IOC_INIT 0x40105301u
#define SACD_IOC_READ 0x40105303u
#define SG_DXFER_FROM_DEV_ (-3)
#define TIMEOUT_MS 10000           /* _IDECLI_SendOddCmd asks for the same */

static int usage(const char *p)
{
    fprintf(stderr,
            "usage: %s size <dev>\n"
            "       %s read10 <dev> <lba> <nsec> <outfile> [--sacd]\n"
            "       %s sacdread init <dev>\n"
            "       %s sacdread read <dev> <lba> <nsec> <outfile>\n",
            p, p, p, p);
    return 2;
}

static int dump(const char *path, const unsigned char *buf, size_t len)
{
    FILE *f = fopen(path, "wb");
    if (!f) {
        fprintf(stderr, "open %s: errno=%d\n", path, errno);
        return -1;
    }
    if (fwrite(buf, 1, len, f) != len) {
        fprintf(stderr, "write %s: errno=%d\n", path, errno);
        fclose(f);
        return -1;
    }
    fclose(f);
    return 0;
}

static int mode_size(const char *dev)
{
    unsigned long long bytes = 0;
    int ssz = 0, fd, rc, saved;

    errno = 0;
    fd = open(dev, O_RDONLY | O_NONBLOCK);
    if (fd < 0) {
        saved = errno;
        printf("SRREAD mode=size dev=%s rc=-1 errno=%d blkgetsize64=0 blkssz=0\n",
               dev, saved);
        return 1;
    }
    errno = 0;
    rc = ioctl(fd, BLKGETSIZE64, &bytes);
    saved = (rc < 0) ? errno : 0;
    if (rc == 0) {
        errno = 0;
        if (ioctl(fd, BLKSSZGET, &ssz) < 0) {
            ssz = 0;
        }
    }
    printf("SRREAD mode=size dev=%s rc=%d errno=%d blkgetsize64=%llu blkssz=%d\n",
           dev, rc, saved, bytes, ssz);
    close(fd);
    return (rc < 0) ? 1 : 0;
}

static int mode_read10(const char *dev, unsigned lba, unsigned nsec,
                       const char *out, int sacd)
{
    struct sg_io_hdr io;
    unsigned char cdb[12], sb[64];
    unsigned char *buf;
    unsigned long len;
    unsigned sense;
    int fd, rc, saved;

    len = (unsigned long)nsec * (sacd ? 2064UL : 2048UL);
    buf = calloc(1, len);
    if (!buf) {
        fprintf(stderr, "calloc %lu: errno=%d\n", len, errno);
        return 1;
    }

    memset(cdb, 0, sizeof(cdb));
    cdb[0] = 0x28;                       /* READ(10)                     */
    cdb[2] = (unsigned char)(lba >> 24); /* LBA, big-endian (c97 §4.1)   */
    cdb[3] = (unsigned char)(lba >> 16);
    cdb[4] = (unsigned char)(lba >> 8);
    cdb[5] = (unsigned char)lba;
    cdb[7] = (unsigned char)(nsec >> 8);
    cdb[8] = (unsigned char)nsec;
    if (sacd) {
        cdb[10] = 0x98;                  /* Sony SACD flag (_IDECLI_OddRead) */
    }

    memset(&io, 0, sizeof(io));
    memset(sb, 0, sizeof(sb));
    io.interface_id    = 'S';
    io.dxfer_direction = SG_DXFER_FROM_DEV_;
    io.cmd_len         = sizeof(cdb);
    io.mx_sb_len       = sizeof(sb);
    io.dxferp          = buf;
    io.dxfer_len       = len;
    io.sbp             = sb;
    io.timeout         = TIMEOUT_MS;

    errno = 0;
    fd = open(dev, O_RDONLY | O_NONBLOCK);
    if (fd < 0) {
        saved = errno;
        printf("SRREAD mode=read10 lba=%u nsec=%u len=%lu rc=-1 errno=%d "
               "sense=000000 host=0000 driver=0000 file=%s\n",
               lba, nsec, len, saved, out);
        free(buf);
        return 1;
    }
    errno = 0;
    rc = ioctl(fd, SG_IO, &io);
    saved = (rc < 0) ? errno : 0;
    close(fd);

    sense = (unsigned)((io.masked_status & 0x0f) << 16)
          | ((unsigned)sb[12] << 8) | (unsigned)sb[13];
    if (rc == 0 && (io.status != 0 || io.host_status != 0 || io.driver_status != 0)) {
        rc = -1;                         /* SCSI-level failure, ioctl returned 0 */
    }
    dump(out, buf, len);
    printf("SRREAD mode=read10 lba=%u nsec=%u len=%lu rc=%d errno=%d "
           "sense=%06x host=%04x driver=%04x file=%s\n",
           lba, nsec, len, rc, saved, sense, io.host_status, io.driver_status, out);
    free(buf);
    return (rc == 0) ? 0 : 1;
}

static int mode_sacdread(const char *sub, const char *dev, unsigned lba,
                         unsigned nsec, const char *out)
{
    unsigned int a[4];
    unsigned char *buf = NULL;
    unsigned long len = 0;
    unsigned cmd;
    int fd, rc, saved, result;

    if (strcmp(sub, "init") != 0 && strcmp(sub, "read") != 0) {
        return usage("sr_read10");
    }
    cmd = (strcmp(sub, "init") == 0) ? SACD_IOC_INIT : SACD_IOC_READ;

    if (cmd == SACD_IOC_READ) {
        len = (unsigned long)nsec * 2064UL;   /* sacd_read.ko's own budget */
        buf = calloc(1, len);
        if (!buf) {
            fprintf(stderr, "calloc %lu: errno=%d\n", len, errno);
            return 1;
        }
    }

    errno = 0;
    fd = open(dev, O_RDONLY);
    if (fd < 0) {
        saved = errno;
        if (cmd == SACD_IOC_INIT) {
            printf("SACDREAD cmd=0x%08x ret=-1 errno=%d result=-1\n", cmd, saved);
        } else {
            printf("SACDREAD cmd=0x%08x lba=%u nsec=%u len=%lu ret=-1 errno=%d "
                   "result=-1 file=%s\n", cmd, lba, nsec, len, saved, out);
        }
        free(buf);
        return 1;
    }
    memset(a, 0, sizeof(a));
    if (cmd == SACD_IOC_READ) {
        a[1] = lba;
        a[2] = nsec;
        a[3] = (unsigned int)(unsigned long)buf;
    }
    errno = 0;
    rc = ioctl(fd, cmd, a);
    saved = (rc < 0) ? errno : 0;
    result = (int)a[0];                        /* u4Result */
    close(fd);

    if (cmd == SACD_IOC_INIT) {
        printf("SACDREAD cmd=0x%08x ret=%d errno=%d result=%d\n",
               cmd, rc, saved, result);
    } else {
        dump(out, buf, len);
        printf("SACDREAD cmd=0x%08x lba=%u nsec=%u len=%lu ret=%d errno=%d "
               "result=%d file=%s\n", cmd, lba, nsec, len, rc, saved, result, out);
    }
    free(buf);
    /* INIT's success value is CPSA-positive (0x68000000), never 0
     * (daemon-gate-experiments.md §0.6), so success is "ioctl did not fail". */
    return (rc < 0) ? 1 : 0;
}

int main(int argc, char **argv)
{
    if (argc >= 3 && strcmp(argv[1], "size") == 0) {
        return mode_size(argv[2]);
    }
    if (argc == 3 && strcmp(argv[1], "sacdread") == 0) {
        return usage(argv[0]);
    }
    if (argc >= 6 && strcmp(argv[1], "read10") == 0) {
        int sacd = (argc > 6 && strcmp(argv[6], "--sacd") == 0);
        return mode_read10(argv[2], (unsigned)strtoul(argv[3], NULL, 0),
                           (unsigned)strtoul(argv[4], NULL, 0), argv[5], sacd);
    }
    if (argc >= 4 && strcmp(argv[1], "sacdread") == 0 && strcmp(argv[2], "init") == 0) {
        return mode_sacdread("init", argv[3], 0, 0, NULL);
    }
    if (argc >= 7 && strcmp(argv[1], "sacdread") == 0 && strcmp(argv[2], "read") == 0) {
        return mode_sacdread("read", argv[3], (unsigned)strtoul(argv[4], NULL, 0),
                             (unsigned)strtoul(argv[5], NULL, 0), argv[6]);
    }
    return usage(argv[0]);
}
```

### 9.3 `decode/read10_verdict.sh` (Mac, post-fire gate)

```sh
#!/bin/sh
# read10_verdict.sh — post-fire gate for the C103 READ(10) ladder.
# Usage: sh read10_verdict.sh <uart.log> [<mmio.log>] [<meta.json>]
# Exit 0 = PASS, 1 = FAIL (a check broke), 2 = INCOMPLETE (a class never ran).
#
# Contract with the guest ladder (sr_read_ladder.sh + sr_read10 helper), one
# space-separated field list per line, no padding:
#   SRREAD   mode=size|read10 lba=<n> nsec=<n> len=<n> rc=<ret> sense=<6hex> host= driver=
#   SACDREAD cmd=0x401053.. lba=<n> nsec=<n> len=<n> ret=<ioctl ret> errno= result=
#   MD5      name=<label> off=<byte offset in the dump> hash=<md5 of 2048 bytes>
#   MD5      name=<label> head16=<md5 of the first 16 bytes>
#   LADDER   <step> PASS|FAIL <detail>   /   LADDER done <n>/<n>
# This script PRINTS the FRAMING verdict itself (§G) — it is decided here, not
# by the guest, which has no ISO to compare against.
#
# LC_ALL=C: the UART transcript carries non-UTF8 bytes (boot banners, ANSI
# colour codes); a UTF-8 locale makes sed/awk abort mid-stream.
LC_ALL=C; export LC_ALL
U=${1:?usage: read10_verdict.sh <uart.log> [<mmio.log>] [<meta.json>]}
M=${2:-}
J=${3:-}
STATE=0                      # 0 PASS, 1 FAIL, 2 INCOMPLETE

pass() { echo "PASS  $1  ($2)"; }
bad()  { echo "FAIL  $1  ($2)"; if [ "$STATE" != 2 ]; then STATE=1; fi; }
inc()  { echo "SKIP  $1  ($2)"; if [ "$STATE" = 0 ]; then STATE=2; fi; }

# want <count> <bre> <file> <label>
want() {
  n=$(grep -c "$2" "$3" 2>/dev/null)
  if [ "$n" = "$1" ]; then pass "$4" "$n"; else bad "$4" "want $1, got $n"; fi
}
# want_ge <min> <bre> <file> <label>  — counts an EH retry would legitimately change
want_ge() {
  n=$(grep -c "$2" "$3" 2>/dev/null)
  if [ "$n" -ge "$1" ] 2>/dev/null; then pass "$4" "$n"; else bad "$4" "want >=$1, got $n"; fi
}

# ── A. the run is the run: the disc the model was given is the pinned ISO ───
want 1 '^bx510: SATA ATAPI drive attached: .*firebird\.iso (1064208 sectors)$' "$U" \
     "disc attached (C100-R0)"

# ── B. leg (a): sr0 present. Behavioural, not string-keyed: the block device
#       reports the fixture's exact capacity, which only happens when sr0
#       attached AND READ CAPACITY was answered.
want_ge 1 '^SRREAD mode=size .*rc=0 blkgetsize64=2179497984 blkssz=2048' "$U" \
     "sr0 capacity + block size (leg a)"

# ── C. no fatal libata signature (qc timeout / EH give-up / SRST) ───────────
want 0 '^ata1\.00: qc timeout'          "$U" "no qc timeout"
want 0 '^ata1: reset failed, giving up' "$U" "no EH give-up"
want 0 '^ata1\.00: SRST failed'         "$U" "no SRST failure"
want 0 '^ata1\.00: failed to IDENTIFY'  "$U" "no failed IDENTIFY"

# ── D. legs (b)(c)(d): the 2048-byte oracles ───────────────────────────────
# D0 first: if the three single-sector reads hash IDENTICALLY, the FE served
# one canned block (the IDENTIFY table) instead of disc bytes — the signature
# of an un-armed READ dispatch, and the reason the oracles are md5s and not
# eyeballed hexdumps.
nh=$(grep -hE '^MD5 name=lba(16|510|532104) off=0 hash=' "$U" 2>/dev/null \
     | sed 's/.*hash=//' | sort -u | grep -c .)
if [ "$nh" = 3 ]; then pass "three distinct payloads (no canned block)" "$nh"
else bad "three distinct payloads (no canned block)" "want 3, got $nh"; fi
want 1 '^MD5 name=lba16 off=0 hash=c117ce4cef54ab625e33583156605721$'      "$U" "oracle LBA 16 (PVD)"
want 1 '^MD5 name=lba510 off=0 hash=e56de1add53c90dd30cf9232b29ddc93$'     "$U" "oracle LBA 510 (SACDMTOC)"
want 1 '^MD5 name=lba532104 off=0 hash=9ed18b47f67232ea972515df65cb6ac5$'  "$U" "oracle LBA 532104 (mid-disc)"
want 1 '^MD5 name=lba510x10 off=0 hash=45ccd7dfbf433a79d28e877d7441677c$'  "$U" "oracle LBA 510 x10 (batch)"
want 1 '^MD5 name=lba1064207 off=0 hash=d1c54ec6c395d7092ce06f04705d33ae$' "$U" "oracle final sector (EOF boundary)"

# ── E. the 0xbb poison canary and the resident-zero control ────────────────
# 0xbb x 16 = 698c867c835081965870124d1b90f66e : a head that still hashes to
# this was never DMA'd (c97-read-path.md §3.3). A zero page is a CORRECT
# answer at LBA 0, so its head must hash to 0x00 x 16 = 4ae71336…, not 0xbb.
want 1 '^MD5 name=lba0 head16=4ae71336e44bf9bf79d2752e234818a5$' "$U" "LBA 0 served as real zeros"
want 0 'head16=698c867c835081965870124d1b90f66e'                  "$U" "0xbb poison in no head bytes"

# ── F. past-EOF must fail loudly (row 23), with a sense triple ─────────────
want 1 '^SRREAD mode=read10 lba=1064208 nsec=1 len=2048 rc=-1 ' "$U" "past-EOF rejected"
want 0 '^SRREAD mode=read10 lba=1064208 nsec=1 len=2048 rc=0 '  "$U" "past-EOF did not 'succeed'"
want 0 '^SRREAD mode=read10 lba=1064208 .* sense=000000'        "$U" "past-EOF carried a sense triple"

# ── G. leg (e): the /dev/sacd_read framing verdict — decided HERE, from the
# guest's measurements (the guest has no ISO to compare against; the Mac does
# not need one either, because the oracles are recorded constants).
O510=e56de1add53c90dd30cf9232b29ddc93      # LBA 510, 2048 logical
O511=68e5b97be9a6db48a3d477d77522d47d      # LBA 511, 2048 logical
h() { grep -h "^MD5 name=sacd510 off=$1 hash=" "$U" 2>/dev/null \
      | sed 's/.*hash=//' | head -1; }
b0_0=$(h 0);  b0_4=$(h 4);  b0_8=$(h 8);  b0_12=$(h 12);  b0_16=$(h 16);  b0_24=$(h 24)
b1_2048=$(h 2048); b1_2064=$(h 2064); b1_2072=$(h 2072); b1_2076=$(h 2076)
want 1 '^SACDREAD cmd=0x40105303 lba=510 nsec=2 len=4128 ret=0' "$U" "ioctl 5303 read succeeded"
want 1 '^LADDER e MEASURED'                                    "$U" "5303 dump + hashes emitted"
want_ge 1 '^LADDER done '                                      "$U" "ladder ran to completion"

LAYOUT=unresolved
if [ "$b0_12" = "$O510" ] && [ "$b1_2076" = "$O511" ]; then
  LAYOUT=payload_at_12_stride_2064
elif [ "$b0_0" = "$O510" ] && [ "$b1_2064" = "$O511" ]; then
  LAYOUT=payload_at_0_stride_2064          # 16 stale/trailing bytes per sector
elif [ "$b0_0" = "$O510" ] && [ "$b1_2048" = "$O511" ]; then
  LAYOUT=payload_at_0_stride_2048          # kernel re-packed, 2064 buffer tail stale
elif [ "$b0_16" = "$O510" ]; then
  LAYOUT=payload_at_16_stride_2064         # DAEMON-MAP's "16-byte header" phrasing
elif [ "$b0_24" = "$O510" ]; then
  LAYOUT=payload_at_24_stride_2064         # mode-2 subheader offset (2352 leak?)
elif [ "$b0_0" = "$O510" ]; then
  LAYOUT=payload_at_0_wrong_stride
fi
echo "FRAMING layout=$LAYOUT (b0:0=$b0_0 4=$b0_4 8=$b0_8 12=$b0_12 16=$b0_16 24=$b0_24 b1:2048=$b1_2048 2064=$b1_2064 2072=$b1_2072 2076=$b1_2076)"
if [ "$LAYOUT" = payload_at_12_stride_2064 ]; then
  pass "framing verdict" "$LAYOUT"
else
  bad "framing verdict" "$LAYOUT (accept is payload_at_12_stride_2064)"
fi

# ── H. model side: the armed descriptor carried THIS transfer ──────────────
if [ -n "$M" ] && [ -f "$M" ]; then
  want_ge 1 '^bx510: MMIO W 05c40c sz4 = 1$'      "$M" "descriptor armed (0x5c40c = 1)"
  want_ge 1 '^bx510: MMIO W 05c404 sz4 = 800$'    "$M" "plain read length 2048"
  want 1    '^bx510: MMIO W 05c404 sz4 = 5000$'   "$M" "batch read length 20480"
  want 1    '^bx510: MMIO W 05c404 sz4 = 1020$'   "$M" "SACD ioctl length 2064x2 = 4128"
  want_ge 1 '^bx510: MMIO W 05c004 sz4 = 28$'     "$M" "CDB[0..3] = READ(10)"
  want_ge 1 '^bx510: MMIO W 05c008 sz4 = fe01$'   "$M" "CDB[4..7] = LBA 0x1FE, big-endian"
  want 1    '^bx510: MMIO W 05c00c sz4 = 980002$' "$M" "CDB[8..11] = nsec 2 + vendor 0x98"
else
  inc "model-side MMIO checks" "no mmio log supplied (pass it as \$2)"
fi

if [ -n "$J" ] && [ -f "$J" ]; then
  python3 - "$J" <<'PY'
import json, sys
m = json.load(open(sys.argv[1]))
print("INFO  terminal_marker =", m.get("terminal_marker"))
print("INFO  payload_size    =", m.get("fe_test_data", {}).get("payload_size"))
PY
fi

# record, do not gate: the sr attach printk string is not yet observed in any
# run (C101 reached 'scsi 0:0:0:0: CD-ROM' with sr_mod.ko absent), so the gate
# keys on capacity + a real read and this line is the evidence to promote it.
grep -n 'sr0' "$U" 2>/dev/null | grep -v ':# ' | head -3 | sed 's/^/INFO  attach: /'

case "$STATE" in
  0) echo "READ10_VERDICT=PASS";       exit 0 ;;
  2) echo "READ10_VERDICT=INCOMPLETE"; exit 2 ;;
  *) echo "READ10_VERDICT=FAIL";       exit 1 ;;
esac
```

### 9.4 Model dispatch shape this harness expects (proposal — not applied)

Row 21 must be evaluated **first**, keyed on the doorbell, before the existing
`code`/`type` ladder (`bx510_fe_dispatch`, `sony-bx510.c`):

```c
case 0x5c020:                       /* doorbell */
    s->fe_doorbell = val;
    if (val & 1) {
        if ((s->fe_dma[3] & 1) && bx510_fe_is_read_cdb(s->fe_cmd)) {
            bx510_fe_read10(s);      /* decode LBA/nsec, blk_pread, synth
                                      * 2048 | 2352 | 2064 framing, stb_phys
                                      * fe_dma[1] bytes, post ONE type-0 */
        } else {
            bx510_fe_dispatch(s);    /* loader / IDENTIFY / reset / ack */
        }
    }
    break;
```

with `bx510_fe_read10()` holding the three hard assertions from
`c97-read-path.md` §3.1: `fe_dma[1] <= 0x12800`, `fe_dma[0] & 0xf == 0`,
`fe_dma[0] + fe_dma[1] <= ram_size`. Nothing else on the model side changes for
this harness; rows 22/23 are the two error branches of the same call.

---

## 10. Provenance

| item | identity / how |
|---|---|
| `firebird.iso` (VM, the copy the rig opens) | sha256 `1d8f0697389ea2a95cf971a4526ffba421cbcc029d529032ea0a155b6b6f68d3`, md5 `217ea92bdb6915dd229055facba43552`, 2,179,497,984 B (`firebird-fixture.md` §1) |
| oracles | `firebird-fixture.md` §5.1/§5.2, re-derived twice there (`dd \| md5sum` and literal-frame construction) |
| canary constants | `md5(0xbb × 16)`, `md5(0x00 × 16)`, `md5(0x00 × 2048)` computed here with `hashlib` (§8.3); the last equals the fixture's LBA-0 oracle, which is the cross-check |
| model claims | read out of `emulator-kit/sony-bx510.c` (read-only): `fe_dma[4]` at 0x5c400..0x5c40c, `bx510_fe_dispatch()` branches, `blk_getlength` as the only `sata_blk` use |
| C101 baseline | `evidence/bx510-guest/bdpdrv/bdpdrv-runC101.uart.log` line 1 (disc) / 290-295 (ATAPI + `scsi 0:0:0:0`), `.meta.json` (`payload_size` 634880, `terminal_marker` true) |
| gate validation | 5 fixtures, results in §4.4; scripts `sh -n` + `shellcheck -s sh -S style` clean; helper compiled `-Wall -Wextra` clean with clang **and** gcc against a 2.6.35-shaped `scsi/sg.h` stub, and its runtime line formats exercised on the host twin (§8.4) |

Nothing was executed inside the emulator for this document, and no file outside
this path was modified.
