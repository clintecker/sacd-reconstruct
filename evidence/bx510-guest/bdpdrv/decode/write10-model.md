# C103+ — the ATAPI verb table, and the WRITE direction (no `0x5c400` descriptor exists for host→device)

Decode of the *rest* of the ATAPI verb set that reaches the FE mailbox after READ(10) works:
every CDB the SCSI scan, `sr_mod`'s open/media-change ladder, the block read and the daemon
actually issue; how each one's data (if any) reaches the driver; and the WRITE direction,
which is the one place C97 left an INFERRED answer. Ends with the C103 verdict: READ-only
support is **not** sufficient, and the two rows that gate it are named.

**This lane EXTENDS `c97-read-path.md` and `fe-ata-cmd.md`; it does not re-derive them.**
Everything in both stands except where §5 below says otherwise. C97's row numbers 1-24 are
untouched; this doc adds rows 25-37.

**Inputs.** `/tmp/bdpdrv/sata_rel.dis` (objdump `-dr` of `sata_mt85xx_mod.ko` — relocation
records, so every `bl` is a name), `/tmp/bdpdrv/fe-ata-funcs.dis` (the 19 FE-path functions),
`/tmp/kmod/sr_mod.ko` + `cdrom.ko` + `libata.ko` (pulled from the guest rootfs,
`mt85xx-ioctl.md` §10 has the sha256s), `decode/c97-read-path.md`,
`decode/hsm-buffer-seq.md`, `decode/fe-status-handshake.md`, `decode/fe-ata-cmd.md`,
`decode/mt85xx-ioctl.md`, `decode/daemon-ioctl-side.md`, `decode/sacdread-cpsa.md`,
`decode/read10-orchestration.md`, `decode/scsi-scan-codes.md` (C101 — the *live* trace that
came in while this lane ran; it corrects two static claims here, §5.8/§5.9),
`emulator-kit/sony-bx510.c` (read-only: `fe_msg[]` queue,
`fe_dma[]`, `bx510_fe_dram_write`).

**Certainty labels.** *DECODED* = an instruction in the bundle fixes it (site cited).
*INFERRED* = consistent with every instruction seen, not closed by one; the settling
experiment is named. There is still **no `0x5c4xx` trace** (C95 post-handshake has none), so
every claim here is static.

---

## 0. Bottom line

1. **There is no host→device DMA descriptor anywhere in mailbox mode.** The
   `0xfd05c400..0xfd05c40c` group has **exactly eight** access sites in the whole module
   (exhaustive scan, §1.4) and every one of them is on the *device→host* READ path. A
   WRITE(10) never touches it. `priv+0x48 == 2` is software-visible only.
2. **The write data path is the DRAM window, direction 2** (bottom half `0x48a4`:
   `memcpy(window + w1 ← priv+0x4c, min(priv+0x54, w2))`). It is *requested* by the FE: the
   FE posts `type 0x10` and the driver moves bytes **out** of its bounce buffer into the
   window. The driver then ACKs with `_svoif_mt85xx_send_table_data_ack_cmd` (§1.5).
3. **The driver has an opinion about exactly eight CDB opcodes** — `0x28/A8/BE` (READ family),
   `0x12` (INQUIRY, answered **locally** whenever FA mode `priv+0x208` is set — and it is set in
   our rig, OBSERVED at C101), `0x46`, `0x52`, `0xF0`, `0x1B`. **Every other CDB is a
   blind post and the model owes the entire answer** (§2.1). That is the whole dispatch
   contract, and it is why a "READ-only" model half-works and then hangs at `sr` attach.
4. **`priv+0x18` ("Disc Type") is the current profile from the `GET CONFIGURATION` response**,
   not a vendor mode: `hw_chg_st 0x4360` sets `priv+0x18 = (resp[6] << 8) | resp[7]` when
   `cdb[1] == 1`, and `0x4468` prints it as `[IDE]Disc Type = %d`. The `2352`-raw read framing
   fires only for `priv+0x18 ∈ {8,9,10}` = profiles **CD-ROM / CD-R / CD-RW**. Answering the
   profile the daemon demands (`0x0010` DVD-ROM, SR-3) *also* keeps the driver in plain-2048
   mode **and** leaves its read cache disabled (`priv+0x84 = 0`). One answer, three good
   outcomes (§2.3).
5. **Three data mechanisms exist and the model must implement all three** — descriptor DMA
   (READ family only, one status message), window *offer* direction 1 (every other data-in,
   **two** status messages), window *request* direction 2 (every data-out, **two** messages).
   The current model already has the two-message machinery (`fe_msg[]` queue, retire on the
   `0x5c04c` read, re-arm the pending bit) — that is load-bearing, not incidental (§3).
6. **The scan issues a real data-OUT before the ladder even starts**: `MODE SELECT(6) 0x15`
   with a 12-byte parameter list, from `sr_cd_check` → `sr_set_blocklength` at first media
   check. READ-only support therefore deadlocks the ladder at the *first open*, which is the
   C103 verdict in §4.

---

## 1. The direction machine, end to end

### 1.1 Who decides direction (both DECODED)

| site | effect |
|---|---|
| `qc_prep 0x2ed8/0x2edc/0x2ee8` | `priv+0x38 = qc->tf.protocol` — so `(priv+0x38 - 5) <= 2` is "ATAPI class 5/6/7" |
| `qc_prep 0x2eec..0x2f18` | protocol ∈ {1,5} ⇒ `priv+0x48 = 0`; else `tf.flags & ATA_TFLAG_WRITE` ⇒ `2` (host→device) else `1` (device→host) |
| `qc_issue 0x369c..0x36c0` | ATAPI + `cdb[0] ∈ {0x28,0xA8,0xBE}` ⇒ `qc->tf.protocol = 7` and `tf.flags \|= 1`; every ATAPI command still queues `qc_issu_task` (`0x3664`) |
| `qc_issue 0x3644/0x36e4` | *if* `ap+0x10 & 0x400000` were set, READ CDBs would take a shortcut that sets `qc->flags \|= 0x80000`, `ap+0x10 \|= 0x800000` and **skip** `qc_issu_task`. It is not set in this configuration (the same word is `ap->ioaddr`, whose value is 0 — every MMIO address in this driver is an absolute literal, e.g. `0xfd00a208`), so the branch is **dead** and the C97 chain holds. INFERRED once; settled by the C97 trace (see §7). |

### 1.2 The three data mechanisms (DECODED, one table)

| # | mechanism | armed by | selected when | completion that drives it |
|---|---|---|---|---|
| A | **descriptor DMA to guest RAM** `0x5c400/404/408/40c` | `data_xfer 0x5810..0x5878`, only for `cdb[0] ∈ {0x28,0xA8,0xBE}` (`0x570c..0x5724`) | READ family, mailbox mode | **one** `type 0` message; the bottom half only cache-invalidates (`0x48ec`) |
| B | **DRAM-window offer, dir 1** (driver *reads* the window) | FE posts `type 0x10`, `w1` = window offset, `w2` = length | every data-**in** command that is not the READ family (INQUIRY, MODE SENSE, GET CONFIGURATION, READ TOC, READ CAPACITY, REQUEST SENSE …) | **two**: the `type 0x10` message fills the bounce buffer (`0x4850`), then a `type 0` message advances the state to DRQ (`0x46b0`) |
| C | **DRAM-window request, dir 2** (driver *writes* the window) | FE posts `type 0x10`, `w1` = window offset, `w2` = length | every data-**out** command (MODE SELECT, WRITE(6/10/12), FORMAT …) | **two**: the `type 0x10` message copies bounce→window and the driver ACKs, then a `type 0` message advances to DRQ |

B and C are one instruction pair, differing only in `memcpy` argument order:
`bottom half 0x4850` (`memcpy(priv+0x4c ← r6, r10)` + `BSP_CleanDCacheRange`) vs
`0x48a4` (`memcpy(r6 ← priv+0x4c, r10)` + `BSP_FlushDCacheRange`), selected by
`0x47d8/0x47e4` on `priv+0x48`.

### 1.3 The WRITE transcription (DECODED) — where the data comes from

`qc_issu_task` (`0x6c94`), for `priv+0x48 == 2`:

```
6ccc..6ce0  priv+0x54 = qc->nbytes (u32 end-cur subtraction) ; priv+0x58 = 0
6ce4..6da8  walk the sg list to learn the aligned span (bounce sizing)
6e00/6e04  if (priv+0x54 > 75776) -> 0x6f9c (error, the same 74 KiB cap as READ)
6dbc..6de8  kmalloc(priv+0x54 + 16) when unaligned ; priv+0x5c = base, priv+0x4c = 16-aligned
6e1c/6e20  if (priv+0x48 == 2) -> 0x71f8          <-- THE WRITE BRANCH, before any CDB parse
71f8..7290  for each sg chunk:
              src = uncached alias of sg page  (mem_map-based : `0x7540` = mem_map,
                     `0x7250..0x7270` = (pfn<<12) - page_offset + 0xc0000000)
              memcpy(priv+0x4c + cursor, src, min(remaining, sg_len))     (*)
704c..7068  memcpy(priv+0x24, qc->cdb, 12)
706c..7080  if (priv+0x4c) { if (priv+0x48 != 1) BSP_FlushDCacheRange(priv+0x4c, priv+0x54) }
7090/7098   priv+0x50 = (u32)priv+0x4c + 0x40000000        <-- phys, set for BOTH directions
709c..7164  queue_delayed_work(drv_wq, priv+0x2e8)  (= the bottom half; qc_issu_task itself
            reaches the FE through ata_bmdma_qc_issue -> exec_command -> send_ata_cmd)
```

`(*)` is the whole write data path: **the sg data is already in RAM at `priv+0x4c` before the
CDB is even posted.** The transcriptions in C97 §1.1 for the READ branch (CDB rewrite, `0xbb`
poison, `nsec × 2352`) are all *downstream* of this branch and do not run for a write.

**`priv+0x50` is computed for writes too — and then thrown away.** Its only consumer is
`data_xfer 0x5838/0x583c`, inside the READ-only branch (`0x5800`). So for a write the driver
holds the physical address of the bounce buffer in its private struct and **never tells the
FE**. That is the load-bearing negative half of item 2 of this stage's brief: *no, a WRITE(10)
does not DMA from host RAM via `0x5c400`.*

### 1.4 Settling the descriptor direction bits (exhaustive, closes C97 §2's last INFERRED cell)

Every `str`/`ldr` against the `0xfd05cxxx` block, found by decoding the literal base
`0xfd05cfff` (12 literal sites) and collecting every register-offset access with
`-0x1000 ≤ off ≤ 0` (script in §6 note):

```
-0xfff .. -0xff3  (0x5c000..0x5c00c)  mailbox words  : 0x3b18-0x3b30, 0x3c60-0x3c80, 0x579c-0x57b8
-0xfdf            (0x5c020)           doorbell      : 0x3b50/0x3b60, 0x3ca0/0x3cb0, 0x57d0/0x57e4
-0xfbf .. -0xfb3  (0x5c040..0x5c04c)  status block  : 0x28b8-0x28d8 (chk_int_ldr), 0x4640-0x465c (bottom half)
-0xbff            (0x5c400)           DMA addr      : 0x583c
-0xbfb            (0x5c404)           DMA length    : 0x5844
-0xbf7            (0x5c408)           RMW |= 0x100  : 0x5848/0x5850
-0xbf3            (0x5c40c)           arm/disarm    : 0x5814 (=1), 0x5870/0x5878 (|= 0x600), 0x4428 (= 0)
```

Eight sites, all in `data_xfer`'s READ branch plus the single disarm in `hw_chg_st`. So:

| word | bit | meaning | label |
|---|---|---|---|
| `0x5c40c` | 0 | descriptor armed (device→host). Set to 1 *before* addr/len, so it alone is not "go" | DECODED value, INFERRED name |
| `0x5c408` | 8 (`0x100`) | addr+len valid | DECODED value, INFERRED name |
| `0x5c40c` | 9,10 (`0x600`) | DMA enable + go (last write of the group, after two `dsb`s) | DECODED value, INFERRED name |
| — | — | **there is no direction bit.** Direction is not encoded in these words at all | **DECODED (exhaustive: 8 sites, one code path)** |

The counterexample that *proves* direction is not a register bit lives in the **register
(non-mailbox) mode**, where the hardware does have both: `_sata_mt85xx_set_tx_reg`
(`0x2e48`) programs `0xfd00a240 = addr`, `0xa244 = addr + 0x20 + len`, `0xa248 = addr`,
`0xa24c = len` (the **TX / host→device** group), and `exec_command 0x5c74` calls it with
`(priv, priv+0x50, priv+0x54, go=1)` when `priv+0x48 == 2`, then sets `0xfd00a208 = 16`.
Direction 1 in that mode uses the *other* group `0xfd00a250..0xa25c` (`0x5c04`, and
`data_xfer 0x58d8`) with `0xfd00a208 = 32` / `|= 0x20`. Mailbox mode exposes only the RX
analogue (`0x5c400`) — which is exactly why a mailbox-mode write cannot be a descriptor.

`sata_mt85xx_send_atapi_cmd` (`0x1f54`) is the register-mode ATAPI packet poster (it plants
`phys(cdb)` into the `0xa240` group, `0xa24c = 12`, `0xa208 = 16`, then rings `0xfd00a01c += 0xa0`).
It has **no call site anywhere in the module** — dead code in this build, and the reason the
register path can be ignored for the model.

### 1.5 The WRITE request protocol, message by message (DECODED shapes, INFERRED ordering)

```
guest: qc_issu_task fills bounce (0x71f8), posts CDB via data_xfer
       W 05c000 = 0xa1000000 ; W 05c004/8/c = CDB  (cdb[0] = 0x2A)   <- no 0x5c400 anywhere
FE   : must now *pull*. Post status block:
       W 05c040 = 0x00100000   (byte2 = 0x10 type offer, byte3 = 0)
       W 05c044 = w1           (window offset; 0 is fine, see below)
       W 05c048 = w2           (bytes wanted; clamp to nsec*2048 from the CDB)
       W 05c04c = 0
       raise 0x5c804 |= 0x10000
guest: bottom half 0x47ac type==0x10, 0x47e4 dir==2 -> 0x48a4
       memcpy(window + w1  <-  priv+0x4c,  min(priv+0x54, w2))     ; BSP_FlushDCacheRange
       then 0x47ec _svoif_mt85xx_send_table_data_ack_cmd(priv)  =  W 05c000 = 0x00001000
       then loops back to wait_event (0x47a4 -> 0x4578): the worker is ready for message 2
FE   : sees the command post with w0 byte2 == 0x10 -> that IS the ack
       read the payload: ldb_phys(window_phys_base + w1 + i), i < w2
       then post the completion:   W 05c040 = 0 (type 0, byte3 = 0), rest zero
guest: 0x4698/0x46b0 dir != 0 -> hw_chg_st(priv, 2)  => state 2 => check_status 0x58 (DRQ)
       libata data phase -> data_xfer 0x554c copies bounce -> sg (a no-op copy-back, since
       qc_issu_task already sg->bounce'd the same bytes) and burns priv+0x54 to 0
       -> 0x55ac hw_chg_st(priv, 0)  => state 0
```

Notes the model needs:

* **`w2` is clamped by the driver, not trusted:** `min(priv+0x54, w2)` (`0x47cc..0x47d4`). The
  driver's dir-2 copy does **not** advance `priv+0x58`/`priv+0x54`, so a request larger than
  the window must be split by the FE using `w1` only (the *source* is always `priv+0x4c + 0`).
  One message suffices for ≤ 75776 bytes, i.e. every qc.
* `window_phys_base = ((*(u32*)0xfd05c500 & 0xff) << 22)` (`fe-status-handshake.md` §, the same
  base `bx510_fe_dram_write` already uses). Direction 2 is the mirror: `ldb_phys`.
* **Ordering is mandatory.** Two messages posted back to back collapse into one latch bit whose
  block content is the last message (hsm-buffer-seq §0.3). The current model's
  `fe_msg[]`-queue + "retire on the `0x5c04c` read, then re-arm `0x5c804`" (`sony-bx510.c`
  0x5c040 case) is exactly the required sequencing — keep it for A *and* for B/C.
* After the dir-2 ACK the driver loops back to `wait_event_interruptible`, so message 2 *is*
  read in the same work-item invocation. (This corrects hsm-buffer-seq §0.2's "only the first
  message is ever read": the loop-back at `0x47a4` fires whenever the handled message left
  `r11 == 0`, which the type-0x10 paths always do.)

### 1.6 What the model should *do* with write payloads

Two defensible policies; the second is the one C103 wants:

| policy | how | consequence |
|---|---|---|
| accept & discard | as §1.5, drop the bytes after reading them | the guest sees a successful write to read-only media — dishonest, and it makes a "write refused" control impossible |
| **refuse, honestly** | post `type 0` with **`byte3 != 0`** on the CDB post (no window dance at all) ⇒ `0x488c hw_chg_st(priv,5)` ⇒ `check_status` = `0x51` (RDY\|DSC\|ERR) ⇒ libata runs EH ⇒ `REQUEST SENSE` | matches the player's beyond-EOF/read-only posture; needs row 30 (REQUEST SENSE via mechanism **B**) to return `ILLEGAL REQUEST / DATA PROTECT` (`02 27 07` … sense key `0x7`, ASC `0x27`, ASCQ `0x00`) so EH does not retry |

`MODE SELECT` is the exception: it is a data-out command on a *non-media* path, and refusing it
costs nothing but noise (`sr_set_blocklength` just returns an error; `sdev->sector_size` was
already forced to 2048 at `sr_probe 0x1cb8`), whereas accepting it costs one 12-byte window
copy. Recommendation: **accept MODE SELECT, refuse WRITE** (§3 rows 25/26 keep both possible).

---

## 2. The verb table

### 2.1 The driver's opinion set (DECODED, exhaustive)

Every `cdb[0]` comparison in `sata_mt85xx_mod.ko` (script §6), i.e. every opcode on which the
driver does anything other than post-and-wait:

| opcode | site | driver action |
|---|---|---|
| `0x28` READ(10), `0xA8` READ(12), `0xBE` READ CD | `qc_issue 0x369c/0x36c4`, `qc_issu_task 0x6e38/0x6eac/0x6fe4/0x7008/0x737c`, `data_xfer 0x55b8/0x570c`, `hw_chg_st 0x40b4`, `qc_issue 0x36ac` (protocol=7) | descriptor DMA (mechanism A), 2352 rewrite when `priv+0x18 ∈ {8,9,10}` |
| `0x12` INQUIRY | `data_xfer 0x55dc/0x55e8` | answered **inside the driver** from `.data+0x70` (template `"MTK 85xx- FA Mode "` + `ata_id_c_string(…, 23, 9)`), gated on FA mode `priv+0x208 != 0`. `priv+0x208` is written by `sata_mt85xx_set_FA_mode 0x7714` (`copy_from_user(priv+0x208, u, 4)`, the `+520` form — *not* an immediate offset, which is why a naive `#0x208` scan misses it). **FA mode = 1 in our rig (OBSERVED, `scsi-scan-codes.md` §4.3) ⇒ the FE never sees INQUIRY**; if FA mode were driven to 0 the post would appear and mechanism **B** would owe a 36-byte standard INQUIRY |
| `0x46` GET CONFIGURATION | `hw_chg_st 0x41a4` → `0x4360` | when `priv+0x38 ∈ 5..7` **and** `cdb[1] == 1` **and** the transfer completes: `priv+0x18 = (resp[6]<<8) \| resp[7]` (current profile); profile ∈ `0x40..0x43` ⇒ `cache_alloc(1536)`, else `cache_alloc(128)` + cache disabled (`0x4430`), and `0x4468` logs `Disc Type = %d` |
| `0x52` (RD) | `hw_chg_st 0x41b0` → `0x427c` | parses the **response** buffer: flag `buf[7] & 2`, `BE32(buf[8..11])`, `BE32(buf[24..27])`, `BE32(buf[28..31])` ⇒ `priv+0x20` = "Disc MAX LBA" (logged at `0x44e0`) |
| `0xF0` | `hw_chg_st 0x41b4` | `cdb[1] == 0xE0` ⇒ `_sata_tray_status = resp[7]`; `cdb[1] == 0xA4` ⇒ `_fg_fe_bootup = 0` |
| `0x1B` START STOP UNIT | `hw_chg_st 0x4094` → `0x43e0` | `cdb[4] == 2` (eject) ⇒ `priv+0x18 = 0`, `priv+0x20 = 0`, `priv+0x214 = priv+0x218 = 0`, `sata_mt85xx_cache_free(priv, -1)` |

`0x52` is the one identity still open: the parse reads a byte at offset 7 and three 4-byte BE
fields at 8 / 24 / 28 and folds them into a *last LBA*, which matches neither MODE SENSE nor
READ TOC layout cleanly (READ TRACK INFORMATION's fields at 24/28 are a track start address and
the next track number). **INFERRED: a Sony/MediaTek disc-info command**; settling experiment in
§7. Consequence of getting it wrong: `priv+0x20` stays 0 ⇒ the `0x7394` cache gate
(`if (priv+0x2c < priv+0x20) sata_mt85xx_cache_check()`) is never taken ⇒ *no* behavioural
change once the cache is disabled, which the profile-`0x0010` answer already guarantees.

### 2.2 The verb table proper

`dir`: 1 = device→host, 2 = host→device, 0 = none. `len`: what the *device* must supply or
accept. `mech`: A/B/C from §1.2. `msgs`: status-block messages per command.

#### (a) SCSI-scan + `sr_probe` — runs at `insmod sr_mod` / `scsi_scan_host`

| verb | op | dir | len | mech | msgs | what the model must answer |
|---|---|---|---|---|---|---|
| TEST UNIT READY | `0x00` | 0 | 0 | — | 1 | `type 0`, `byte3 = 0` (media present). `byte3 != 0` ⇒ state 5 + EH (that is the *not-ready* answer, SR-2) |
| INQUIRY | `0x12` | 1 | 36 (midlayer), 36+ for VPD `0x00/0x80/0x83` | **B** | 2 | **not posted while FA mode is 1** (the driver synthesizes it — the `MTK 85xx - FA Mode` line is the driver's own template, OBSERVED at C101). Model it anyway *only* for the FA-mode-0 case (§5.8): peripheral type `0x05` (CD-ROM), version `0x05`, additional length ≥ 31 |
| MODE SENSE(6) `0x1A` **or** MODE SENSE(10) `0x5A` | — | 1 | ≤ `cdb[4]` (0x6) / `cdb[7..8]` (0x10) | **B** | 2 | **conditional**: `sr_probe` skips it when either vendor `scsi_ioctl` (`0x8531`, `0x8533` — 0x8530-family vendor gets; the FA-mode getter is one of them, INFERRED) returns non-zero (`sr_probe 0x1d58..0x1df4` ⇒ SCSI result `0x8000002`), which is the OBSERVED C101 path. Answer it if it appears: header (medium type, device-specific param, **block descriptor length 0**) + page `0x2A` (MMC capabilities) zero-filled; the opcode is chosen by `sdev->use_10_for_ms` in `scsi_mod`, so **answer both** |
| REPORT LUNS | `0xA0` | 1 | 16 | B | 2 | only if the midlayer decides the device is SCSI-3; a 16-byte reply with LUN 0 is the safe answer |

*sites*: `sr_test_unit_ready 0x13b0` (zero 6-byte CDB at `0x13d0/0x13d4`, retry loop, plus the
same two vendor `scsi_ioctl`s `0x8531`/`0x8533` at `0x1438/0x1448` — and when either returns
non-zero the function returns `0x8000002` **without issuing the TUR at all**, `0x1554`; FA mode is
1 in our rig, so the FE may see no TUR either, see §4); `sr_probe 0x1d18` (TUR),
`0x1dec` = `scsi_mode_sense(sdev, 0, 0x2a, buf, 0x80, …)` and the capability parse at
`0x1e14..0x1ff0`; `sr_probe 0x1cb8` forces `sdev->sector_size = 2048` regardless.

#### (b) First open of `/dev/sr0` — `sr_media_change` → `sr_cd_check` (the attach ladder)

Order matters; this is the sequence the C103 pre-phase walks:

| # | verb | op | dir | len | mech | msgs | model answer |
|---|---|---|---|---|---|---|---|
| 1 | TEST UNIT READY | `0x00` | 0 | 0 | — | 1 | good |
| 2 | READ TOC | `0x43` fmt 0, `cdb[9] = 0x40` (MSF) | 1 | 12 | B | 2 | TOC header: first/last track (2 B), then one 8-byte descriptor per track |
| 3 | READ HEADER | `0x4B` | 1 | 8 | B | 2 | CD header: MSF of data start, `cdb[9]`-ish |
| 4 | READ TOC again | `0x43` | 1 | 4, then 12 | B | 2 each | as #2 |
| 5 | **MODE SELECT(6)** | `0x15`, `cdb[1] = 0x10` (PF), `cdb[4] = 12` | **2** | 12 | **C** | 2 | 8-byte header + block descriptor with **block length 2048** (`buf[10..11]`); accept it |
| 6 | READ TOC / disc info | `0x43` variants | 1 | ≤ 12 | B | 2 | as #2 |
| 7 | drive status | `0`, `0x1B`-adjacent | mixed | — | — | 1 | good / tray closed |
| 8 | READ CD (XA probe) | `0xBE`, `cdb[8] = 1`, `cdb[9] = 0x78` | 1 | 2352-ish | **A** (it is in the READ family!) | 1 | one frame at LBA 0; the driver strips `buflen>>11` × 2048 out of each 2352-byte frame (`data_xfer 0x54ac`) |
| 9 | READ CAPACITY | `0x25` | 1 | 8 | B | 2 | `last_LBA = nsectors-1` (BE32), **`block_length = 2048`** (BE32). The driver does `capacity(512B) = (last_LBA+1) << 2` for block length 2048/2340/2352/0, but **not** for 512, and zeroes capacity for anything else (`0x1894..0x18f4`). Wrong block length ⇒ `capacity = 0` ⇒ every read past LBA 0 fails |
| 10 | READ TOC (via `cdrom_get_last_written`) | `0x43` | 1 | ≤ 12 | B | 2 | as #2 |

*sites*: `sr_media_change 0x1650` (TUR) → `0x1754` (`sr_cd_check`) → `0x1790` READ CAPACITY
(`mov r9,#37`; `scsi_execute_req` at `0x17ec`, 3 retries) → `0x1824..0x18f4` capacity/block-length
parse → `0x1854` `cdrom_get_last_written`; `sr_cd_check 0x3d60` (READ TOC 12 B),
`0x3ee4` (READ HEADER), `0x3fb0/0x4060` (READ TOC), `0x3fa8`/`0x4138` (`sr_set_blocklength`),
`0x40d4` (`sr_disk_status`), `0x40e4` (`sr_is_xa`); `sr_set_blocklength 0x3c20` (MODE SELECT(6),
param list 12 B, `buf[0xa..0xb] = 2048`, `sdev->sector_size = 2048` on success);
`sr_is_xa 0x3884..0x38b8` (READ CD, `cdb[8] = 1`, `cdb[9] = 0x78`).

Two more `sr_set_blocklength` call sites exist and are inert for us: `sr_release 0x4c0` (only if
`sector_size > 2048`) and `sr_prep_fn 0x1024` (same guard).

#### (c) The read

| verb | op | dir | len | mech | msgs | model answer |
|---|---|---|---|---|---|---|
| READ(10) from the block layer | `0x28`, LBA `cdb[2..5]` BE, `nsec` `cdb[7..8]` | 1 | `nsec × 2048` (= `0x5c404`) | **A** | **1** | `nsec × 2048` bytes from `lba*2048` DMA'd to `0x5c400`; `type 0/0` |
| READ(10)+SACD flag (daemon) | `0x28`, `cdb[10] = 0x98` | 1 | as above | **A** | 1 | identical — the driver never reads `cdb[10]`; the model must **ignore** it |
| READ CD (driver-rewritten or `sr_is_xa`) | `0xBE`, `cdb[9] = 0xF8` / `0x78` | 1 | `nsec × 2352` / `buflen` | **A** | 1 | 2352-byte frames, `frame[15] = 1` (mode 1) ⇒ payload at +16 |

`READ(12)` (`0xA8`) is in the driver's set but **no one in this pipeline issues it** (`sr` uses
READ(10); `sr_is_xa` uses READ CD). The model should still accept it (`nsec` = `cdb[6..9]`) because
the cost is four lines and a `0xA8` from a future tool would otherwise be an unhandled post.

#### (d) The daemon's own verbs (post-phase)

| verb | op | dir | len | mech | msgs | model answer |
|---|---|---|---|---|---|---|
| TEST UNIT READY loop | `0x00` | 0 | 0 | — | 1 | good, or CHECK CONDITION with ASC `0x3A`/`0x30` while "loading" (SR-2) |
| GET CONFIGURATION | `0x46`, `cdb[1] == 1`, `cdb[7..8]` alloc | 1 | 20 (`_IDECLI_OddGetProfile`), 8 minimum needed | B | 2 | `resp[0..3]` data length BE, `resp[6..7]` **current profile = `0x0010`** (SR-3). This single word sets the driver's read framing (plain 2048) and disables its cache |
| READ(10) `0x98` | `0x28` | 1 | `nsec × 2048` | A | 1 | disc bytes (2064-byte SACD framing belongs to the `/dev/sacd_read` leg, not here — C97 §4.3) |
| vendor `0xF0` (`0xE0` / `0xA4` sub-codes) | `0xF0` | 1 | 8–12 | B | 2 | tray status byte at `resp[7]`, or "ack" (the driver just latches a global) |

`0x98`/`0x99` in the brief are **not opcodes** — they are `cdb[10]` of READ(10)
(`sacdread-cpsa.md` §3.2, `mt85xx-ioctl.md` §3.2). There is no vendor opcode `0x98` or `0x99` in
the driver's dispatch (2.1 is exhaustive).

#### (e) Verbs nobody in this pipeline issues (model: reject or ignore)

`REQUEST SENSE 0x03` is the exception — it *is* issued, but only after an error (libata EH,
`atapi_eh_request_sense`), and it is mechanism **B** (18 bytes). `START STOP UNIT 0x1B` is issued
only by an explicit `CDROMEJECT`/`CDROMCLOSETRAY` (`sr_tray_move 0x2ad4`); `SYNCHRONIZE CACHE
0x35`, `MODE SELECT(10) 0x55`, `RESERVE/RELEASE`, `FORMAT UNIT 0x04` and `WRITE(10) 0x2A` are
never issued by any component in the tree (`daemon-ioctl-side.md` §1.2/§2.5: the daemon only ever
`open(O_RDONLY)`s `/dev/sr0`, `lseek`s, `read`s, `fstat64`/`BLKGETSIZE64`s and issues the seven
`/dev/sacd_read` ioctls — **verified: no write anywhere in the daemon**).

### 2.3 Why the profile answer is the linchpin (DECODED consequence chain)

`GET CONFIGURATION` answer `resp[6..7]` → `priv+0x18` (`hw_chg_st 0x4360`) → three consumers:

1. `qc_issu_task 0x6e9c`: `priv+0x18 ∈ {8,9,10}` ⇒ rewrite the CDB to READ CD `0xBE` and
   `priv+0x54 = nsec × 2352`; otherwise plain `0x28`/`0xA8` with `nsec × 2048`.
   **So answering CD-ROM (`0x0008`) *changes the read framing*, and answering `0x0010` keeps it
   plain.** This closes C97 §4.4's INFERRED cell.
2. `hw_chg_st 0x438c..0x4448`: profile ∈ `0x40..0x43` ⇒ `cache_alloc(1536)` + `priv+0x84 = 1`
   (read-ahead cache **on**); anything else ⇒ `cache_alloc(128)`, `priv+0x84 = 0`, `priv+0x6c = 0`
   (cache **off**).
3. `hw_chg_st 0x43e0`: `START STOP UNIT` with `cdb[4] == 2` clears it back to 0.

`priv+0x84 == 0` also disables the `0x701c` cache gate, which is why `0x52` (`priv+0x20`) cannot
break the read path. One answer (`0x0010`) is therefore simultaneously: the daemon gate (SR-3),
plain-2048 framing, and a disabled driver cache.

The cache matters twice for the model. `sata_mt85xx_cache_check` is reachable **only** through the
`priv+0x84 != 0` block (`qc_issu_task 0x701c..0x7040`, `protocol == 7`), and it is the only
writer of `priv+0x80 = 1` (`0x69f4`, the "serve this read from the read-ahead cache" verdict).
`data_xfer 0x55f4..0x5608` then returns **without posting anything** when
`priv+0x80 != 0 && priv+0x7c != 1`. So a model that answered a BD profile (`0x40..0x43`) would
silently stop seeing READ posts — the FE would look dead with no error anywhere. Profile `0x0010`
structurally prevents that (`priv+0x64 = 0` ⇒ `cache_check` miss path ⇒ `priv+0x80` stays 0, and
0x7048 clears it for every command anyway).

---

## 3. Model rows (continues `fe-ata-cmd.md` §5.1 rows 1-16 and `c97-read-path.md` §5 rows 17-24)

Registers: rows 17-20 unchanged. Dispatch: rows 21-24 unchanged for the READ family. New rows:

| # | condition on the `0x5c020` doorbell / status-block read | meaning | model action |
|---|---|---|---|
| 25 | `cdb[0] ∈ {0x28,0xA8,0xBE}` **and** `fe_dma[3] & 1` | READ family, descriptor armed (rows 21-23) | DMA `fe_dma[1]` bytes to `fe_dma[0]`, **one** `type 0/0` (unchanged) |
| 26 | `cdb[0]` is a data-**in**, not in the READ family (MODE SENSE/GET CONFIGURATION/READ TOC/READ CAPACITY/REQUEST SENSE/vendor `0xF0`; INQUIRY only when FA mode is 0) | mechanism **B** | build the answer for that opcode (table below), `bx510_fe_dram_write(off, answer, len)`, post `w0 = 0x00100000, w1 = off, w2 = len`; **remember the command is still "in flight"** |
| 27 | command post with **`w0` byte2 == `0x10`** and `w1 == w2 == 0` | `_svoif_mt85xx_send_table_data_ack_cmd` (`0x3c08`) — the driver consumed the offer/request | post the **completion**: `type 0`, `byte3 = 0` (success). This is the existing `type == 0x10 → post type-0` arm and it now serves three meanings: loader ack, dir-1 ack, dir-2 ack |
| 28 | `cdb[0]` is a data-**out** we accept (`MODE SELECT(6) 0x15`, `MODE SELECT(10) 0x55`) | mechanism **C** | post `w0 = 0x00100000, w1 = 0, w2 = len` (the request); on the ack (row 27) **read** the payload with `ldb_phys(window + w1 + i)` (discard or apply), then `type 0/0` |
| 29 | `cdb[0]` is a data-out we refuse (`WRITE(6/10/12)`, `FORMAT UNIT`) | read-only media | post **one** `type 0` with `byte3 != 0` ⇒ state 5 ⇒ status `0x51`; no window traffic. §1.6 |
| 30 | `cdb[0] == 0x03` REQUEST SENSE | EH follow-up | 18-byte fixed sense: `resp[0] = 0x70`, `resp[2..3]` ASC/ASCQ, `resp[7] = additional length (10)`. For row 29 emit `0x02 0x3A 0x00` (NOT READY / MEDIUM NOT PRESENT) or `0x07 0x27 0x00` (DATA PROTECT) as appropriate; mechanism **B** |
| 31 | `cdb[0] == 0x25` READ CAPACITY | capacity probe | 8 bytes: `BE32(nsectors - 1)`, `BE32(2048)`; mechanism B. `nsectors = blk_getlength(sata_blk)/2048` (the same divisor IDENTIFY word 100-103 already uses) |
| 32 | `cdb[0] == 0x00` TUR / `0x1B` START STOP | no data | `type 0`, `byte3 = 0`. Never silent |
| 33 | `cdb[0] == 0x43` READ TOC / `0x4B` READ HEADER | attach ladder | build the min TOC: `data_len`, first/last track, one descriptor; honour `cdb[6]` (track) and the MSF bit `cdb[9] & 2`; return `len = min(cdb-alloc, 12)` |
| 34 | `cdb[0] == 0x1A` / `0x5A` MODE SENSE | `sr_probe` capability read | header with **block descriptor length 0** + zeros to the allocation length; page `0x2A` = all-capability-zero is legal and yields "no capabilities" (mask bits set, attach still succeeds; only audio/`CDC_*` ioctls get refused) |
| 35 | `cdb[0] == 0x46` GET CONFIGURATION | the daemon gate **and** the framing switch | `resp[0..3] = 0x00000008`, `resp[6..7] = 0x0010` (DVD-ROM); pad to allocation length |
| 36 | `cdb[0] == 0x52` | Sony disc-info | **stub**: 12 zero bytes (⇒ `priv+0x20 = 0` ⇒ cache gate off, which row 35 already guaranteed). Replace with the real layout if a trace ever shows it (§7) |
| 37 | any other opcode | unknown | `type 0` with `byte3 != 0` (CHECK CONDITION) — never silence, never success-then-hang |

**Answer table for row 26/30/31/33/34/35** (`off` = any free window offset ≥ `0x1000`; the model
already uses `FE_REPLY_OFF`/`FE_IDENT_OFF`):

| opcode | model bytes | note |
|---|---|---|
| `0x12` INQUIRY | `05 80 05 01 1F 00 00 00` + `SONY    ` + product + `1.00` | `resp[0] = 0x05` (CD-ROM), `resp[2] = 0x05` (SPC-2), `resp[3] = 0x01`, `resp[4] = 0x1F` (31). Only reachable with FA mode 0; with FA mode 1 the driver answers it and this row never fires |
| `0x1A`/`0x5A` MODE SENSE | zeros, `len = alloc` (6) / `len = alloc` (10), `resp[0] = len-1` / `resp[0..1] = len-2` | block descriptor length byte = 0 |
| `0x25` READ CAPACITY | `BE32(n-1) BE32(0x800)` | **must not be 512** |
| `0x43` READ TOC | `BE16(data_len) 01 01` + `00 14 01 00 00 00 00 00` | one track, MSF |
| `0x4B` READ HEADER | `01 00 00 00 00 00 00 00` | |
| `0x46` GET CONFIGURATION | `00 00 00 08 00 00 00 10` | profile `0x0010` |

### 3.1 Dispatch keying — the CDB, the byte count, or both (a live-vs-static conflict)

Rows 26-35 key on `cdb[0]`, which exists only on the **CDB post** — `data_xfer 0x576c..0x5780`
(`memcpy(r0 = sp+0x4c, priv+0x24, 12)`), reached only when `priv+0x220 == 3` (`0x547c`). Two posts
can therefore reach the model for one ATAPI command:

| post | poster | `w0` byte3 | `w1..w3` |
|---|---|---|---|
| taskfile | `_svoif_mt85xx_send_ata_cmd 0x3a78` (tail-called by `exec_command 0x5c9c`) | `priv+0x29c`, whose only three writers are `0xa1` (`0x2858` chk_int_ldr), `0x08` (`0x4f70` softreset), `0xf7` (`0x51c8` prereset) | `priv+0x280..0x294` = the ATAPI taskfile, i.e. **byte count** in `w1[7:0]`/`w1[15:8]` |
| CDB | `data_xfer 0x578c..0x57b8` | same byte (`priv+0x29c`) | **the 12-byte CDB** |

`scsi-scan-codes.md` (C101, live trace) observed the ATAPI posts with `w0 = 0xa0000000` /
`0xef000000` and `w1..w3` = 0, and concluded that byte3 is *the ATA command byte* and that the CDB
is normally not delivered. The static read disagrees on the mechanism (byte3 has three writers,
none of which is `tf->command`; `exec_command 0x5b78` puts `tf->command` in `priv+0x34`, a
different field) while **agreeing on the consequence**: in the C101 state the CDB post did not
happen, so the model saw the taskfile post only.

**Model rule that is correct either way:**

* If a doorbell arrives whose `w1..w3` are non-zero **and** `w1[7:0] ∈ {0x00,0x03,0x12,0x1a,0x1b,
  0x25,0x28,0x43,0x46,0x4b,0x52,0x5a,0xa8,0xbe,0xf0}` — treat `w1..w3` as the CDB (rows 26-35).
* Otherwise treat `w2`/`w1` as a **byte count** and dispatch on *(count, position in the
  sequence)*: 0 ⇒ TUR/no-data, 8 ⇒ READ CAPACITY, 12 ⇒ READ TOC, 128 ⇒ MODE SENSE page `0x2A`,
  ≥ 2048 ⇒ READ (and then the descriptor tells you it is a read, row 21/25).
* For a READ the ambiguity does not exist: the descriptor arm and the CDB post are the *same*
  `data_xfer` call (`0x5800` falls through to `0x5728`), so `fe_dma[3] & 1` ⇒ the CDB is in
  `0x5c000..0x5c00c` — which is what row 21 already relies on.

---

## 4. C103 verdict — can the ladder complete with READ-only support?

**No.** Three independent gates, in the order the ladder hits them:

| gate | why READ-only fails | row needed |
|---|---|---|
| **G1 — `sr_media_change` → `sr_cd_check` issues `MODE SELECT(6) 0x15` with a 12-byte data-out plus `READ TOC 0x43`/`READ HEADER 0x4B`/`READ CD 0xBE`** | a model that only answers `cdb[0] ∈ {0x28,0xA8,0xBE}` posts *nothing* for `0x43/0x4B/0x15`, so each of those qcs sits until `check_status` times out (30 s) and the ladder's first `open("/dev/sr0")` fails | 26, 27, 28, 33 |
| **G2 — `READ CAPACITY 0x25`** | with no answer, `sr_media_change` takes the `result != 0` arm ⇒ `capacity = 0x1fffff`, `sector_size = 2048`; the device then reports `0x1fffff × 512 ≈ 1 GiB` and every `lseek`/read past that fails. Worse, a wrong *block length* (e.g. 512) zeroes capacity outright (`0x18dc..0x18f0`) | 31 |
| **G3 — the daemon's `GET CONFIGURATION 0x46`** (`sacd_sacd() >= 0` is "profile ok") | post-phase only, but it is the documented SR-3 gate; and it is the same row that pins the framing to plain 2048 (§2.3) | 35 |

What READ-only *does* buy: the block-layer read itself (row 21/25) and the attach-time TUR. So
the correct ordering of work is **mechanisms B and C → G1 (media-change ladder) → G2 → read →
G3**, and the minimum model delta over C97 is exactly that: two `memcpy` directions on the
existing window, plus rows 26-35's answers. That is a fixed table (≈ 120 lines of `memcpy` +
`bx510_fe_dram_write`, one more caller each of `stb_phys`/`ldb_phys`) — no new MMIO, no new
window, no change to the FE mailbox protocol. Two things in the model are already right and must
not be regressed: the `fe_msg[]` sequencing for the two-message flows (§1.5), and the
`(0x5c40c & 1)` READ discriminator that keeps a type-0x10 offer from ever being posted for a
READ (§5.5).

Caveat on G1's ordering: **two** of the verbs in this table are short-circuited by the same
vendor ioctl pair (`0x8531`/`0x8533`, 0x8530-family gets; the FA-mode getter is one of them, INFERRED) when it returns non-zero,
which is the observed state (FA mode = 1): `MODE SENSE` at *probe* is skipped (§5.9) **and the
TUR is skipped as well** (`sr_test_unit_ready 0x1554` returns `0x8000002` before the packet is
built). `sr_media_change` still treats that as "media changed" (`0x1680` sets the flag, `0x1754`
then runs `sr_cd_check`), so the ladder proceeds — but the **first FE-visible verb is likely the
media-change `READ TOC 0x43`**, not TUR/MODE SENSE. Answer whichever appears; §3.1's dual keying
(CDB when it is present, byte count when it is not) is what makes that safe.

A secondary but real risk: the ladder's own **write-refusal control** (if `sr_read_ladder.sh`
tries one) needs row 29 + row 30, otherwise it hangs on EH retries instead of failing fast.

---

## 5. Conflicts and corrections to earlier docs

1. **`hsm-buffer-seq.md` §0.2** — "it consumes exactly ONE status-block message per queueing, then
   returns … the loop-back is dead in practice". Corrected: the tail at `0x4794` returns to
   `wait_event_interruptible` whenever the handled message left `r11 == 0`, which is every
   `type 0x10` path (`0x47f4 uxtb r3, r11`), so the worker *is* ready for a second message. What
   actually fails (C98) is posting two messages **before the driver reads the block**: they
   collapse into one latch bit and the block returns the **last** one (§0.3 stands). The rule for
   the model is therefore "one outstanding message, re-post after the driver's `0x5c04c` read"
   — which is what `sony-bx510.c` already implements.
2. **`c97-read-path.md` §2.2 / §9** — the descriptor bit names stay INFERRED, but one item is now
   closed: **there is no direction bit in `0x5c408/0x5c40c`** (exhaustive 8-site scan, §1.4), and
   the direction machinery is *software* (`priv+0x48`) plus, in register mode, *which* descriptor
   group is used (`0xa240` TX vs `0xa250` RX). The write case is settled: window direction 2.
3. **`c97-read-path.md` §4.4 / §9 row 2** — `priv+0x18` is not a vendor mode field: it is the
   **current profile from the GET CONFIGURATION response** (`hw_chg_st 0x4360`, logged as
   `Disc Type = %d`). `{8,9,10}` = CD-ROM / CD-R / CD-RW. INFERRED → DECODED.
4. **`fe-ata-cmd.md` §1.2** and every prior doc that assumed "the model only has to accept the
   writes" — corrected twice over: (a) for a READ the descriptor *is* the data path (C97 §7.1);
   (b) for a WRITE the descriptor does not exist and the payload only leaves the driver if the
   FE *asks* for it (mechanism C).
5. **`c97-read-path.md` §1.3** ("`0x5c400` descriptor ⇒ type-0 completion; DRAM window ⇒ type-0x10
   offer") — still exactly right, and now generalised: the descriptor is used by *exactly* the
   three READ opcodes, so **every other data-in command is a type-0x10 offer** and needs two
   messages, not one.
6. **`sata_mt85xx_send_atapi_cmd`** (`0x1f54`) — previously unremarked. It is the register-mode
   ATAPI packet poster (CDB physical address into the TX descriptor group `0xa240`, doorbell
   `0xfd00a01c += 0xa0`) and it has **no call site in the module**. It is not part of our path and
   must not be modelled.
7. **`qc_issue 0x36e4`'s `qc->flags |= 0x80000` path** — dead in this configuration (the test at
   `0x3644` is on `ap+0x10`, which is the zero-valued `ioaddr` base, not `ap->flags` at `+0xc`;
   libata's own `ata_scsi_activity_store` tests `ap+0xc`). Note it because a future reader will
   otherwise "discover" it and conclude reads bypass `qc_issu_task`.
8. **INQUIRY is not an FE verb in our rig** — this doc's own first draft said the driver's local
   INQUIRY answer was dead code ("`priv+0x208` is never written"). Wrong: `priv+0x208` is FA mode,
   written from userspace via `sata_mt85xx_set_FA_mode 0x7714` (`add r0, r0, #520` +
   `copy_from_user`), i.e. through a **register-offset** store that an immediate-offset scan
   cannot see. `scsi-scan-codes.md` (C101) then *observed* the synthesised answer
   (`CD-ROM MTK 85xx - FA Mode 1.00`). Model consequence: do not expect `0x12` on the doorbell.
9. **MODE SENSE at `sr_probe` is conditional, not unconditional** — `scsi-scan-codes.md` §4.3
   read the `0x8531` short-circuit from the same patched `sr_mod`. Confirmed here from the other
   side: the CDBs at `sr_probe 0x1d58/0x1d68` are `scsi_ioctl(sdev, 0x8531, …)` and
   `scsi_ioctl(sdev, 0x8533, …)`, and a non-zero return takes `0x1da4 → 0x1df4` (`r0 = 0x8000002`)
   *past* the `scsi_mode_sense` at `0x1dec`. The **media-change** ladder's MODE SELECT is
   unaffected — it is unconditional (`sr_cd_check 0x3fa8/0x4138`).

---

## 6. Instruction-site index

| claim | site(s) |
|---|---|
| direction 0/1/2 from `tf.flags & WRITE` | `qc_prep 0x2f04..0x2f18`; `priv+0x38 = protocol` at `0x2ee8` |
| ATAPI READs forced to protocol 7 + `flags \|= 1` | `qc_issue 0x369c..0x36c0`; queue at `0x3664..0x3678` |
| dead BMDMA shortcut (`ap+0x10 & 0x400000`) | `qc_issue 0x3644`, `0x36e4..0x3700` |
| write branch + sg→bounce copy | `qc_issu_task 0x6e1c/0x6e20` → `0x71f8..0x7284` (`memcpy` reloc at `0x7284`); `mem_map` literal `0x7540` |
| 74 KiB cap (both directions) | `qc_issu_task 0x6e00`, `0x74e0` |
| CDB copy to `priv+0x24` | `0x704c/0x7058` and `0x7060/0x7068` |
| `priv+0x50` phys + write-only cache flush | `0x7078..0x7098` (`BSP_FlushDCacheRange` reloc `0x708c`) |
| descriptor arm (READ only) | `data_xfer 0x570c..0x5724` → `0x5800..0x5878` |
| mailbox CDB post | `data_xfer 0x576c..0x57e4` |
| INQUIRY shortcut gated on the never-written `priv+0x208` | `data_xfer 0x55dc/0x55e8`; only read site `0x55dc` |
| data-phase copy is always bounce→sg (rw ignored) | `data_xfer 0x554c/0x5560`, `0x54ac..0x54f4` |
| bottom half type/direction dispatch | `0x4668`, `0x4674..0x46b8`, `0x47ac..0x47f8` |
| dir 1 copy (window → bounce) | `0x4850/0x4878` |
| dir 2 copy (bounce → window) | `0x48a4/0x48bc`, flush `0x48d8` |
| ack after a type-0x10 message | `0x47ec` → `_svoif_mt85xx_send_table_data_ack_cmd 0x3c08` (w0 byte2 = 0x10 at `0x3c58`) |
| state advance: 2 = DRQ, 5 = err, 0 = idle | `0x46b0`, `0x488c`, `0x483c`; `hw_chg_st 0x4180..0x4194` |
| `0x46` profile latch + `Disc Type` print | `hw_chg_st 0x41a4`, `0x4360..0x4384`, print `0x4468` |
| `0x52` → `priv+0x20` (MAX LBA) | `hw_chg_st 0x41b0` → `0x427c..0x4358`; print `0x44e0` |
| `0x1B` eject clears Disc Type/MaxLBA | `hw_chg_st 0x4094` → `0x43e0..0x4408` |
| `0xF0/0xE0` tray, `0xF0/0xA4` bootup | `hw_chg_st 0x41bc..0x41d8`; globals `0x450c`, `0x4510` |
| RX vs TX descriptor groups (register mode) | `_sata_mt85xx_set_tx_reg 0x2e48` (`0xa240..0xa24c`); `exec_command 0x5c04` (`0xa250..0xa25c`), `0x5c74` (set_tx_reg) |
| register-mode ATAPI poster, never called | `sata_mt85xx_send_atapi_cmd 0x1f54` (no `bl`/`b` site in the module) |
| sr TUR (6-byte zero CDB) | `sr_mod.ko sr_test_unit_ready 0x13d0/0x13d4`, `scsi_execute_req 0x14d4` |
| TUR and MODE SENSE short-circuit on the vendor ioctl pair | `sr_test_unit_ready 0x1438/0x1448` → `0x1554` (`r10 = 0x8000002`); `sr_probe 0x1d58/0x1d68` → `0x1db8/0x1df4` → past `0x1dec` |
| FA mode `priv+0x208` is a userspace-writable word | `sata_mt85xx_get_FA_mode 0x76c8` (`copy_to_user`), `sata_mt85xx_set_FA_mode 0x7714` (`copy_from_user`), both via `add …, #520` |
| `priv+0x29c` has exactly three writers (sticky FE code) | `0x2858` (`0xa1`), `0x4f70` (`0x08`), `0x51c8` (`0xf7`); read at `0x3ac4` and `0x576c` |
| read-ahead cache: enable/gate/verify | `hw_chg_st 0x43b0/0x4440`, `qc_issu_task 0x701c..0x7040`, `cache_check 0x69f4`, `data_xfer 0x55f4..0x5608` |
| sr probe MODE SENSE page 0x2A (128 B) | `sr_probe 0x1dc0..0x1dec`, parse `0x1e14..0x1ff0` |
| sr TUR at media change | `sr_media_change 0x1650` |
| sr_cd_check ladder | `0x3d60` (0x43/12 B), `0x3ee4` (0x4B), `0x3fb0`/`0x4060` (0x43), `0x3fa8`/`0x4138` (`sr_set_blocklength`), `0x40d4` (`sr_disk_status`), `0x40e4` (`sr_is_xa`) |
| MODE SELECT(6) 12-byte param list, block length 2048 | `sr_set_blocklength 0x3c20..0x3ce0` |
| READ CAPACITY 0x25 + capacity math | `sr_media_change 0x1790`, exec `0x17ec`, parse `0x1824..0x18f4` |
| READ CD XA probe (0xBE, cdb[9] = 0x78) | `sr_is_xa 0x3884..0x38b8` |
| block read is READ(10) | `sr_prep_fn 0x10f8` |
| MODE SELECT on release/prep (inert) | `sr_release 0x4c0..0x4d8`, `sr_prep_fn 0x1024` |

Reproduce the exhaustive scans:

```sh
# the CDB-opinion set: every cdb[0] compare in bdpdrv
grep -n "ldrb\s*r[0-9]*, \[r[0-9]*, #0x24\]" /tmp/bdpdrv/sata_rel.dis   # then read the next 3 insns
# the 0x5c4xx site scan: literal 0xfd05cfff (12 sites) + every [rN,#-0xNNN] access
grep -n "0xfd05cfff" /tmp/bdpdrv/sata_rel.dis
awk '/\[r[0-9]+, #-0x(fff|fdf|fbf|fb3|bff|bfb|bf7|bf3)\]/ {print}' /tmp/bdpdrv/sata_rel.dis
```

---

## 7. Open items with their settling experiments

| item | label | experiment |
|---|---|---|
| `ap+0x10 & 0x400000` is clear (so `qc_issu_task` runs for READs) | INFERRED once (`ap+0x10` = `ioaddr` = 0, libata's flags live at `ap+0xc`) | the C97 trace: `W 05c404 = nsec×2048` appears ⇒ `qc_issu_task` ran; its absence with the descriptor still armed would mean the dead branch is live |
| which MODE SENSE opcode the scan uses (`0x1A` vs `0x5A`) | INFERRED (depends on `sdev->use_10_for_ms` in the vendor `scsi_mod`) | the C97/C103 trace: `W 05c004` w1 low byte = `1a` or `5a`. The model answers **both**, so this is documentation only |
| `0x52`'s real layout | INFERRED (**Sony/MediaTek disc-info**, parsed into "Disc MAX LBA") | trace the CDB + the `Disc MAX LBA=0x%x` printk; or answer zeros and confirm reads are unaffected (cache is off for profile `0x0010`) |
| does `sr` actually reach `sr_is_xa` on the first media check | INFERRED (control flow read, not traced) | the trace: a `0xBE` post with `cdb[9] = 0x78` before the first `0x28` |
| the read-ahead cache path (`priv+0x80 == 1` ⇒ `data_xfer` returns with **no post**) | DECODED gate, unreachable for profile `0x0010` | if a READ ever appears in `dmesg` as completed with no `W 05c020` in the trace, check whether anything answered a BD profile |
| whether the ladder wants a refused write | design choice (§1.6) | `sr_read_ladder.sh`: a `dd of=/dev/sr0` leg that must fail fast with `ERROR: write protected` rather than an EH timeout |
| the exact INQUIRY strings the midlayer is happy with | INFERRED (standard `scsi_probe_and_add_lun` requirements) | C103 trace/UART: `sr 0:0:0:0: Attached scsi CD-ROM sr0` + `type 5` in `/proc/scsi/scsi` |
