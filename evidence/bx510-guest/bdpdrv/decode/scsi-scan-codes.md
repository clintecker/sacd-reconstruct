# C101 — the two new FE-mailbox codes (`0xa0`, `0xef`), the reply path, and the model recipe to reach `/dev/sr0`

Decode of the posts that appear **after** the IDENTIFY round in the C101 run
(`evidence/bx510-guest/bdpdrv/bdpdrv-runC101.uart.log`, trace
`VM:/tmp/bdpdrv-runC101.mmio.log`, 3 500 042 lines), plus the exact reply route
each one took and the per-register recipe the QEMU FE model needs so the SCSI
scan finishes and the CD-ROM block device enumerates.

**Certainty labels.** *DECODED* = an instruction / relocation / source line fixes it.
*OBSERVED* = the C101 (or C100) trace shows the bytes. *INFERRED* = consistent with
everything seen but not closed by one site; the settling experiment is named.

Trace citations are **line numbers in `bdpdrv-runC101.mmio.log`** (format
`bx510: MMIO R|W <off> szN [= val]`). Driver addresses are section-relative
(`.text+0x…`). Driver file offsets/relocations come from `sata_mt85xx_mod.ko`'s
`.rel.text`/`.symtab`, read with a small ELF parser, not by eye.

---

## 0. Bottom line

1. **`w0` byte 3 is the ATA command byte, not an opaque "FE code".** The three
   sites that store into `priv+0x29c` store *ATA commands* — `0xa1`
   (`chk_int_ldr`, `.text+0x2850/0x2858`), `0x08` (`softreset`, `.text+0x4f6c/0x4f70`),
   `0xf7` (`prereset`, `.text+0x51c4/0x51c8`) — and both posters copy that byte to
   `w0` byte 3 (`send_ata_cmd` `.text+0x3ac4/0x3ae4`, `data_xfer` `.text+0x576c/0x5778`).
   So the two new posts are plain ATA commands:
   **`0xef` = ATA SET FEATURES**, **`0xa0` = ATA PACKET (the ATAPI command gate)**.
2. **`0xef` is libata's transfer-mode set, and the model already answers it
   correctly.** `w1 = 0x00004203` decodes as `{feature = 0x03 (set transfer mode),
   nsect = 0x42 (UDMA mode 2), lba0..2 = 0, device = 0xa0}` — i.e. libata's
   `ata_dev_set_xfermode()` → and that is *exactly* the "`ata1.00: configured for
   UDMA/33`" line the same run prints. Nothing to change.
3. **`0xa0` is a PACKET post with an all-zero 12-byte argument image** (OBSERVED:
   `w1 = w2 = w3 = 0`). Zero bytes is simultaneously (a) an ATAPI taskfile with a
   zero byte-count and (b) the exact 12 bytes of a `TEST UNIT READY` CDB — the two
   readings are indistinguishable *for this packet*, and that is the modelling
   constraint that decides the whole recipe (§4).
4. **The reply path is unchanged and works.** All eight posts in C101 are answered
   through the same 4-word block `0x5c040..0x5c04c` gated by `0x5c804` bit16 and
   masked by `0x5c800 = 0xfffffff0` (§3). The model's *content* dispatch is the
   problem, not the transport: `bx510_fe_dispatch()` has a row for
   `0xa1 && arg == 0` (table A) and `0xa1 && arg != 0` (IDENTIFY) and then
   **one catch-all `type 0, byte3 = 0, no args`** that serves `0xef` and `0xa0`
   alike. It can therefore never hand the driver a data payload for a PACKET.
5. **`/dev/sr0` cannot appear in a C101-shaped run for a reason that is not the
   FE model at all: `CONFIG_BLK_DEV_SR=m` and nothing loads `sr_mod.ko`.** The same
   run's own `/proc/devices` dump has **no block major 11** (UART log,
   `INVENTORY_DEVICES` block). `sr_mod.ko` and `cdrom.ko` *are* present in the
   Sony rootfs (`/lib/modules/2.6.35/BDP/`, vermagic `2.6.35 preempt mod_unload ARMv6`,
   `depends=cdrom`). C102 must `insmod cdrom.ko` then `insmod sr_mod.ko`; only then
   does anything issue TUR / READ CAPACITY / MODE SENSE. §4.4 / §5.
6. **The scan's *first* PACKET needs no data**: with FA mode set
   (`priv+0x208 != 0`, proven by the driver-synthesised INQUIRY, §2.3), Sony's
   patched `sr.c` takes `rc = 0x8000002` and prints `sr0: scsi-1 drive` **without
   issuing MODE SENSE**, and `add_disk()` runs either way. So enumeration needs
   only a correct zero-length PACKET completion; the payload rows
   (`READ CAPACITY(10)`, `MODE SENSE(6)` page `0x2a`) are needed to *open/mount*
   the disc and to get the `scsi3-mmc` line.

---

## 1. `w0 = 0xa0000000` — ATA PACKET, with a zero 12-byte argument image

### 1.1 The post, verbatim (OBSERVED, C101)

```
552657  W 05c000 sz4 = a0000000
552658  W 05c004 sz4 = 0          <- w1
552659  W 05c008 sz4 = 0          <- w2
552660  W 05c00c sz4 = 0          <- w3
552661  R 05c020 sz4
552662  W 05c020 sz4 = 1          <- doorbell bit0
```

Identical bytes in C100 (`bdpdrv-runC100.mmio.log`), so it is deterministic — the
same packet in both runs. Every `0x5c000` post in the whole C101 log, with the
quartet collapsed (8 posts; `grep -A3 "W 05c000 sz4"` + `paste - - - -`):

| count | w0 | w1 | w2 | w3 | reading |
|---|---|---|---|---|---|
| 2 | `0xa1000000` | 0 | `0xa000` | 0 | ATA IDENTIFY PACKET DEVICE (`device = 0xa0`) |
| 1 | `0xa1000000` | 0 | 0 | 0 | `chk_int_ldr` entry (table A) |
| 1 | `0xef000000` | `0x4203` | `0xa000` | 0 | ATA SET FEATURES, UDMA mode 2 |
| **1** | **`0xa0000000`** | **0** | **0** | **0** | **ATA PACKET, zero-length** |
| 3 | `0x00100000` | 0 | 0 | 0 | driver ACK of a type-`0x10` offer |

### 1.2 Why `0xa0` is PACKET and not a vendor code (DECODED)

* `w0` byte3 is `priv+0x29c`, copied by **both** posters:
  `send_ata_cmd` `.text+0x3ac4` (`ldrb r12,[r4,#0x29c]`) → `.text+0x3ae4`
  (`strb r12,[sp,#0x1b]`, i.e. `w0` byte 3); `data_xfer` `.text+0x576c/0x5778`
  (`ldrb r9,[r4,#0x29c]` / `strb r9,[sp,#0x4b]`).
* The only three stores to that field in the module are ATA commands:
  `.text+0x2850` `mov r2,#161` (`0xa1`, chk_int_ldr — immediately followed by
  zeroing `priv+0x280..0x294`, `.text+0x285c..0x2870`), `.text+0x4f6c` `mov r3,#8`
  (`0x08`, DEVICE RESET), `.text+0x51c4` `mov r3,#247` (`0xf7`, the vendor
  prereset op). Verified with `grep -n '#0x29c'`: 3 stores, 2 loads, nothing else.
* `0xa0` is `ATA_CMD_PACKET`; the module's *mode-0* (a-window) companion
  `send_atapi_cmd` posts exactly that byte to `0xfd00a01c` `.text+0x2058/0x2060`.
  The mailbox path is the mode-1 twin of the same command.
* The 12-byte image in `w1..w3` is the driver's `*(priv+0x24)` buffer:
  `data_xfer` `.text+0x577c` `ldr r1,[r4,#0x24]` → `.text+0x5780` `bl memcpy(sp+0x4c, …12)`.
  `priv+0x24` is a **pointer**: `.text+0x5884` `ldr r0,[r4,#0x24]` then
  `memcpy(*(priv+0x24), buf, 12)` `.text+0x588c`; `hw_chg_st` dereferences it as
  bytes (`.text+0x4480/0x4484`, `.text+0x44c4/0x44c8`).

### 1.3 What CDB rode `w1..w3` — the honest answer

OBSERVED: **zero bytes**, i.e. either a zero ATAPI taskfile (`feature` = byte
count lo, `nsect` = byte count hi, `lba0..2` = 0, `device` = 0) or the CDB
`00 00 00 00 00 00 00 00 00 00 00 00`.

* A zero byte-count PACKET is what libata produces for a **no-data SCSI command**
  (`atapi_xlat` puts `qc->nbytes` in `tf.feature`/`tf.nsect`; `0` for TUR).
* A 12-byte-zero CDB is **`TEST UNIT READY` (`0x00`)**, the standard first command
  a CD-ROM gets.
* Both readings say the same thing about the *device-visible* command: a
  zero-length packet. What is **INFERRED** is only which SCSI opcode it was
  (`TUR` vs another zero-length CDB such as `START STOP UNIT`), and the C101 trace
  cannot settle it because the two encodings coincide.
* Two independent facts confirm that **the CDB is normally not delivered at all on
  this post path**, which is the decisive modelling constraint:
  - `hw_chg_st` switches on `CDB[0]` against SCSI opcodes — `0xf0`, `0x1b`,
    `0x28`, `0xa8`, `0xbe` (`.text+0x4084..0x40c8`) — so the buffer *is* a CDB
    buffer when the driver fills it.
  - the only site that fills it is the INQUIRY short-circuit
    (`memcpy(*(priv+0x24), buf, 12)`, `.text+0x588c`); the READ-CDB rewrite in
    `qc_issu_task` fills `priv+0x2c`/`priv+0x30` only for `0x28`/`0xa8`/`0xbe`
    (`.text+0x6ebc..0x6ec0` CDB byte 3 rewritten to `0xbe`; `.text+0x7400..0x7404`
    rewritten to `0xa8`).
  Settling experiment: C102 with `sr_mod` loaded and `0xa0` packets for
  TUR → READ CAPACITY; log the quartet each time. Prediction from the decode
  above: `w1 = 0x0000` (TUR) then `w1 = 0x0008` (READ CAPACITY, 8-byte byte-count),
  `w2 = 0` in both (device byte 0), i.e. **the byte count changes but the opcode
  does not appear**.

So: for a `0xa0` post the model can rely on **`nbytes = (w1 & 0xff) | (((w1 >> 8) & 0xff) << 8)`**
(the ATAPI byte-count limit) and on the packet's position in the sequence — not on
a CDB opcode. §4 gives both the `nbytes`-keyed rows (implementable today) and the
opcode-keyed rows (the same table, selected when `w1` byte 0 is nonzero, which is
what a READ packet looks like: `0x28`/`0xa8`/`0xbe` in byte 0 of the image).

---

## 2. `w0 = 0xef000000` — ATA SET FEATURES (transfer mode)

### 2.1 The post, verbatim (OBSERVED, C101)

```
552296  W 05c000 sz4 = ef000000
552297  W 05c004 sz4 = 4203       <- w1
552298  W 05c008 sz4 = a000       <- w2
552299  W 05c00c sz4 = 0          <- w3
552300  R 05c020 sz4
552301  W 05c020 sz4 = 1
```

### 2.2 Decode of `w1`/`w2` (DECODED layout + OBSERVED values)

`send_ata_cmd`'s word build is `.text+0x3ac8..0x3afc`:
`w1 = {priv+0x280, +0x284, +0x288, +0x28c}` = `{feature, nsect, lba0, lba1}`,
`w2 = {byte0 = priv+0x290 (lba2), byte1 = priv+0x294 (device)}`.
Against the observed words (`{feature, nsect, lba0, lba1, lba2, device}`):

| field | value | meaning |
|---|---|---|
| feature | `0x03` | **SET FEATURES subcommand 0x03 = "Set Transfer Mode"** |
| nsect | `0x42` | transfer-mode byte: `0x40` (UDMA class) `|` mode `2` → **UDMA/33** |
| lba0/1/2 | `0` | unused |
| device | `0xa0` | dev0 + LBA |

That is libata's `ata_dev_set_xfermode()` taskfile, and it is *identical* to the
`device = 0xa0` byte the IDENTIFY posts carry (`w2 = 0xa000`), which is the same
decoding `fe-ata-cmd.md` §3.3 already established for `0xa000`.

Cross-check in the same run (UART): `ata1.00: ATAPI: SONY    BDPSACDEMUL, 1.00,
max UDMA/33` / `ata1.00: applying bridge limits` / `ata1.00: configured for
UDMA/33` — the announced mode is exactly what `nsect = 0x42` asks for. **The FE
model's answer to this post is already correct** (`type 0`, `byte3 = 0`, no args),
and the driver's own log proves it was accepted.

---

## 3. Where each reply went and what the model answered

### 3.1 The transport, per post (OBSERVED)

Every one of the 8 posts is answered through the *same* sequence; the mask write
that makes it possible lands once, in `port_start`, between post 2 and post 3:

```
546541  W 05c800 sz4 = fffffff0     <- port_start mask (mvn r2,#15, .text+0x32d0/0x32d8)
```

Per post (post numbers in trace order):

| # | line | w0 | reply route | block read | UART crossed |
|---|---|---|---|---|---|
| 1 | 545773 | `0xa1000000` (arg 0) | polled: `R 05c804` (545795) → `W 05c804=0x10000` → `R 05c040..04c` (545797-800) | 1 | `[IDE]<sata_mt85xx_id_atapi_dev>copy from (0xdfc01000, 0x200)` |
| 2 | 546141 | `0x00100000` (ACK) | `R 05c804` → W1C → block 546165-168 | 1 | `[IDE]Internal loader boot code mode` / `----- Loader is in manufacture mode !! -----` |
| 3 | 550880 | `0xa1000000` w2=`0xa000` | IRQ: `R 05c800` 550902, `R 05c804` → `W 05c804=0x10000` → `R 05c804` → `W 05c804=0` → `R 05c808` → block 550938-941 | 1 | `ata1.00: ATAPI: SONY BDPSACDEMUL…` `applying bridge limits` `Drive reports diagnostics failure` |
| 4 | 550958 | `0x00100000` (ACK) | same shape, block 551000-003 | 1 | (before `configured for UDMA/33`) |
| 5 | 552296 | `0xef000000` w1=`4203` | `R 05c800` 552308 … block 552322-325 | 1 | (after the ATAPI banner) |
| 6 | 552360 | `0xa1000000` w2=`0xa000` | block 552396-399 | 1 | (revalidate) |
| 7 | 552400 | `0x00100000` (ACK) | block 552426-429 | 1 | `ata1.00: configured for UDMA/33` |
| 8 | **552657** | **`0xa0000000`** | `R 05c800` 552679, `R 05c804` → `W`=0x10000, `R 05c804` → `W`=0, `R 05c808`, block 552699-702; **then** `W 05c40c = 0` (552719), a **second** block read 553316-319 with **no** preceding `0x5c804` drain, `W 05c40c = 0` (553356) | 2 | then `scsi 0:0:0:0: CD-ROM MTK 85xx - FA Mode 1.00 PQ: 0 ANSI: 5` |

**Read values are not logged** (the trace only prints `R <off> szN`), so a read's
value is inferred from the driver's own follow-up write: a `W 05c804 = 0x10000`
means the preceding read returned bit16, and the `W 05c804 = 0` that follows means
the next read returned 0. Every claim below about a read value is that inference.

Counts over the whole log: 8 posts / 8 doorbells / 17 reads+writes of `0x5c804` /
7 reads of `0x5c800` / 6 reads of `0x5c808` / 10 reads of `0x5c040` /
**2 writes of `0x5c40c`, both `0`** / **zero** writes of `0x5c400`, `0x5c404`,
`0x5c408` (so no DMA-descriptor arming anywhere — a PACKET post in this state is
*not* the READ path).

The two `0x5c40c = 0` writes are `hw_chg_st`'s disarm (`.text+0x4420/0x4428`, from
`0x40cc..0x40d4`), i.e. two driver state changes for one packet: one from the post
path (`hw_chg_st(priv, 1)` `.text+0x5728/0x5730`) and one from the reply. The second
block read without a fresh `0x5c804` drain is the printed-argument/second-drain
artefact of the same packet, **not** a second message.

### 3.2 What the model answered (read from the model source, read-only)

`emulator-kit/sony-bx510.c` → `bx510_fe_dispatch()` (content-keyed on the doorbell):

| doorbell content | model action |
|---|---|
| `type == 0x10` | post `w0 = 0` (completion) — table-A message B |
| `code == 0xa1 && arg == 0` | write the loader block at window `0x1000`, post `type 0x10, w1=0x1000, w2=0x200` |
| `code == 0xa1` (any other) | write the 512-byte IDENTIFY block at window `0x2000`, post `type 0x10, w1=0x2000, w2=0x200` (single message, "variant A" — the C98 lesson) |
| **everything else, incl. `0xef` and `0xa0`** | **`bx510_fe_post(s, 0, 0, 0, 0)` — `type 0`, `byte3 = 0` = success, no payload** |

So in C101:
* `0xef` (SET FEATURES) → generic success. **Correct**, and the run's own
  "configured for UDMA/33" proves acceptance.
* `0xa0` (PACKET, zero-length) → generic success. Enough for the packet to
  *complete* (the scan reached `scsi 0:0:0:0`), but this row can never carry a
  data payload, so any packet with a nonzero byte count would complete "successfully"
  with the driver's buffer untouched.
* `0xa1` IDENTIFY → payload offer at window offset `0x2000`; the IDENTIFY data
  demonstrably arrived (`ATAPI: SONY BDPSACDEMUL`, plus the pre-port
  `copy from (0xdfc01000, 0x200)` = window page `0x7f` `<<22` + `0x1000`,
  `W 05c500 = 7f` at line 455795).

### 3.3 Why nothing followed: the CD-ROM driver is a module and was never loaded

The scan stops dead after `scsi 0:0:0:0: CD-ROM …` — no further `0x5c000` post
exists in the remaining 2.9 M trace lines, and no `sr0` line is printed. The cause
is in the same UART log:

```
Block devices:
259 blkext
  7 loop
  8 sd
 ...
```
**No major 11** in `/proc/devices` ⇒ the `sr` driver is not bound/registered.
Guest kernel config (`VM:/home/aftermath/sony-kernel/linux-2.6.35/.config`):
`CONFIG_BLK_DEV_SR=m` (line 627), `CONFIG_BLK_DEV_SD=y` (built-in `sd` rejects
`TYPE_ROM`), `CONFIG_CHR_DEV_SG` unset. The modules exist and match:

```
/tmp/rootfs/lib/modules/2.6.35/BDP/cdrom.ko    vermagic=2.6.35 preempt mod_unload ARMv6
/tmp/rootfs/lib/modules/2.6.35/BDP/sr_mod.ko   vermagic=2.6.35 preempt mod_unload ARMv6
                                               depends=cdrom
```

`sd` alone cannot own a `TYPE_ROM` device and nothing else is loaded, so **no
driver ever issues a SCSI command** — which is also the reason the single `0xa0`
packet in the trace sits *before* the device-add line rather than after it.
(INFERRED identity of that one packet: libata's own zero-length packet at
attach time; TUR from `sr_probe` cannot be it, because `sr` is not loaded. §1.3
gives the settling experiment.)

---

## 4. The model recipe — what the FE must answer for the scan to COMPLETE

Constants: `MASK = 0x10000`, `win = ((*(0x5c500) & 0xff) << 22)`.

### 4.1 Unchanged rows (proven in C101 — do not touch)

| # | detect | meaning | model action |
|---|---|---|---|
| R0 | `0x5c800` read | IRQ mask | return the last written value, bit16 kept (`0xfffffff0` from `port_start`) |
| R1 | `0x5c804` read / W1C | message pending | `MASK` while a reply is un-consumed; clear what is written; return 0 after (drain loop needs the zero) |
| R2 | `0x5c040..04c` | status block | `w0 = {byte2 = type, byte3 = status}`, `w1` = window offset, `w2` = length, `w3` = 0 |
| R3 | `code == 0xa1 && arg == 0` | `chk_int_ldr` | table A: loader block at `win+0x1000`, post `type 0x10, w1=0x1000, w2=0x200` |
| R4 | `code == 0xa1 && w2 == 0xa000` | IDENTIFY PACKET DEVICE | 512-byte IDENTIFY at `win+0x2000`, post `type 0x10, w1=0x2000, w2=0x200` (single message) |
| R5 | `type == 0x10` | driver ACK of an offer | post `type 0`, `w1 = w2 = w3 = 0` |
| **R6** | **`code == 0xef`** | **SET FEATURES** | **`type 0`, `byte3 = 0`, no args — current catch-all behaviour is correct; optionally echo `0x4203`/`0xa000` back in `w1`/`w2` (not read back on this path)** |

### 4.2 The PACKET rows (`code == 0xa0`) — keyed on the ATAPI byte count

`nbytes = (w1 & 0xff) | ((w1 >> 8) & 0xff) << 8` (the image's `feature`/`nsect`
pair, same layout as R6); if `w1` byte 0 is a plausible CDB opcode
(`0x00 0x12 0x1a 0x1b 0x25 0x28 0x5a 0xa8 0xbe`) treat `w1..w3` as the CDB instead
and key on it — the table is identical, only the selector changes.

| # | selector | SCSI command | reply | payload |
|---|---|---|---|---|
| P1 | `nbytes == 0` (zero image) | zero-length packet — TUR / START STOP UNIT | `type 0`, `byte3 = 0`, no args (raise `MASK`) | none. **This is the only packet `sr_probe` needs before `add_disk()`** |
| P2 | `nbytes == 8` (or CDB[0] `0x25`) | READ CAPACITY(10) | `type 0x10`, `w1 = <off>`, `w2 = 8`, payload written to `win+off` **before** raising `MASK`; no separate `type 0` | `00 10 3C 8F 00 00 08 00` = last LBA `0x00103C8F` (1 064 207, from the 1 064 208-sector ISO) + block length 2048 |
| P3 | `nbytes == 128` (or CDB[0] `0x1a`) | MODE SENSE(6), page `0x2a` | `type 0x10`, `w2 = 128`, payload in the window | 128-byte mode page, layout below |
| P4 | `nbytes == 8`, CDB[0] `0x1a`/`0x5a` variant | MODE SENSE(10) | `type 0x10`, `w2 = 8` | `00 3a 00 00 00 00 00 00` (header only) — optional, not on the 2.6.35 sr path |
| P5 | CDB[0] `0x1b` | START STOP UNIT | `type 0`, `byte3 = 0` | none |
| P6 | CDB[0] `0x28`/`0xa8`/`0xbe` | READ(10)/READ(12)/READ CD | **C97 path** — descriptor `0x5c400/404/408/40c` is armed and the FE DMAs into guest RAM, completion is `type 0` (`c97-read-path.md` §1.3) | FE-DMA |
| P7 | anything else | unknown packet | `type 0`, `byte3 = 0` (never stay silent — silence is a 30 s libata timeout) | none |
| **P8** | **CDB[0] `0x12` INQUIRY** | **never reaches the FE** — the driver synthesises it (`.text+0x55dc..0x55f0` gate on `priv+0x208 != 0`, then `.text+0x5880..0x58d0`), which is where `MTK 85xx - FA Mode` comes from (template in `.data+0x78` `"MTK 85xx- FA Mode "` + `ata_id_c_string(…, 23 /*FW_REV*/, 9)`) | **do not model INQUIRY** | — |

Where the payload goes: **the same DRAM-window / `type 0x10` route as IDENTIFY**
(§3.2, `win = (*(0x5c500) & 0xff) << 22`, `w1` = offset inside the window, `w2` =
length; the bottom half `memcpy`s `min(priv+0x54, w2)` into `priv+0x4c` at
`.text+0x47b4..0x48d4` when `priv+0x48 == 1`). Do **not** use the `0x5c400`
descriptor for these: C101 shows zero writes to `0x5c400/404/408`, and the
descriptor branch is taken only for READ CDBs (`.text+0x5710..0x5724` →
`.text+0x5800`). The `0x5c40c` writes in the trace are `hw_chg_st`'s disarm
(always `0`), not descriptor arming.

One message per packet, payload only — the C98 lesson already encoded in the
model (`fe_msg` slot comment): the bottom-half work item reads the status block
exactly once per invocation, so a `type 0x10` payload offer *is* the completion
for that qc.

### 4.3 Mode page `0x2a` payload (for the `scsi3-mmc` line)

`sr.c`'s `get_capabilities()` reads `buffer[n+2..n+15]` with
`n = data.header_length + data.block_descriptor_length` (= 4 for MODE SENSE(6)
with no block descriptor):

| offset | value | `sr.c` use |
|---|---|---|
| 0 | `0x1d` | mode data length (30-byte response − 1) |
| 1..3 | `00 00 00` | medium type / WP / block-descriptor length (0) |
| 4 | `0x2a` | page code |
| 5 | `0x18` | parameter length |
| 6 (`n+2`) | `0x02` | bit1 → prints `cd/rw` (bit3 would mask in DVD) |
| 7 (`n+3`) | `0x00` | bit0 `writer`, bit5 `dvd-ram` — both clear |
| 8 (`n+4`) | `0x20` | bit5 → prints `xa/form2` |
| 9 (`n+5`) | `0x01` | bit0 → prints `cdda` |
| 10 (`n+6`) | `0x20` | `>>5` = 1 → `loadmech[1]` = `tray` |
| 12..13 (`n+8..9`) | `0x21 0x00` | max read speed 8448 KB/s → `48x` (`/176`) |
| 18..19 (`n+14..15`) | `0x21 0x00` | max write speed → `48x` |

Predicted line: `sr0: scsi3-mmc drive: 48x/48x cd/rw xa/form2 cdda tray`.

**But** the Sony-patched `sr.c` short-circuits this whenever
`scsi_ioctl(MT85XX_IDE_GET_FA_MODE)` returns nonzero — and that ioctl reads
`priv+0x208` (`sata_mt85xx_get_FA_mode`, `.text+0x76c8` `add r1,r2,#520` = `+0x208`),
which is the *same* flag that enables the local INQUIRY synthesis
(`data_xfer` `.text+0x55dc`). Since C101's INQUIRY was clearly synthesised (the
`MTK 85xx` template printed), **FA mode is 1 in this rig state**, so the expected
C102 line is:

```
sr0: scsi-1 drive
```

and `MODE SENSE` is **not** issued. Both outcomes enumerate the device. If the
`scsi3-mmc` line is wanted, `sata_mt85xx_set_FA_mode` must be driven to 0 first
(and then P3 becomes mandatory *and* the INQUIRY synthesis switches off, so the
FE would have to serve INQUIRY as well — see §6).

### 4.4 C102 rig prerequisites (not model rows)

1. Stage and load, in order: `insmod /lib/modules/2.6.35/BDP/cdrom.ko` then
   `insmod /lib/modules/2.6.35/BDP/sr_mod.ko` (the SATA probe must already have
   produced the `scsi 0:0:0:0: CD-ROM` line).
2. `mknod /dev/sr0 b 11 0` — this guest has no devtmpfs (`/dev` holds only
   `console`, `mtd*`, `null`, `ttyMT0`).
3. Do not gate on `Attached scsi CD-ROM sr0`: it is `KERN_DEBUG`
   (`<7>%s %s: Attached scsi CD-ROM %s` in `sr_mod.ko`, `sr.c:869-870`), so it is
   not printed at the default console loglevel.

---

## 5. Expected C102 UART

In order (first three from `cdrom.ko`/`sr_mod.ko` load + probe; the last block only
if the disc is opened):

```
Uniform CD-ROM driver Revision: 3.20                  <- cdrom.c:404, KERN_INFO, at cdrom.ko load
sr0: scsi-1 drive                                     <- sr.c get_capabilities(), FA-mode shortcut (expected in this rig state)
   [or] sr0: scsi3-mmc drive: 48x/48x cd/rw xa/form2 cdda tray   <- if FA mode is 0 and P3 is modelled
```
and, on `open`/`mount` (media-change check → `get_sectorsize()` → READ CAPACITY):

```
sr0: CDROM not ready.  Make sure there is a disc in the drive.   <- only if P1/P2 are unanswered
```

Acceptance observables that do **not** depend on loglevel:

```
# cat /proc/devices            -> Block devices: ... 11 sr
# cat /proc/partitions         -> ... sr0   (capacity after get_sectorsize: 2 128 416 KiB)
# ls -l /dev/sr0               -> brw-r--r-- 1 0 0 11, 0 /dev/sr0
```

MMIO signature that proves the FE served the PACKET round (C102 trace):
`W 05c000 = a0000000` (P1, zero image) → `R 05c804` then `W 05c804 = 0x10000`
(so the read returned bit16) → `R 05c804` then `W 05c804 = 0` (so it returned 0) →
`R 05c040..04c`. For P2/P3 additionally: a **payload** window write and a
`type 0x10` block (`byte2 == 0x10`, `w1` = window offset, `w2` = 8 or 128)
followed by the driver's `memcpy` region being consumed — and **no** `0x5c400`
writes (a `0x5c400` triple would mean the READ path, which these are not).

---

## 6. Open items with their settling experiments

| item | label | experiment |
|---|---|---|
| Which SCSI opcode the single C101 `0xa0` packet was | INFERRED (TUR-shaped, zero-length) | C102 with `sr_mod` loaded: log each `0xa0` quartet. Prediction: `w1 = 0` (TUR) then `w1 = 0x0008` (READ CAPACITY) — byte count changes, opcode never appears |
| Whether the driver ever puts a nonzero CDB in `w1..w3` for a PACKET | INFERRED (no) | same C102 quartet log; a nonzero `w1` byte 0 = a CDB, which would switch the recipe from `nbytes`-keyed to opcode-keyed |
| `priv+0x208` (FA mode) value in the C102 rig | OBSERVED = 1 for C101 (INQUIRY synthesised) | `scsi_ioctl(MT85XX_IDE_GET_FA_MODE)` result is visible as the `scsi-1` vs `scsi3-mmc` line; or read `priv+0x208` via the `mt85xx_ioctl` cli |
| Second block read of the `0xa0` reply (no `0x5c804` drain) | OBSERVED, unexplained in detail | C102: if the payload variant (P2) works first try, leave it; if the 8 bytes never land, the second read is the place to look |
| `051c010`-style register (`W 05c010 = 4f474f4c` "LOGO" at line 547243, unimplemented) | not needed | orthogonal to the PACKET path; only worth a row if a later read-back appears |

## 7. Instruction / evidence index

| claim | site |
|---|---|
| `w0` byte3 = `priv+0x29c` | `send_ata_cmd` `.text+0x3ac4/0x3ae4`; `data_xfer` `.text+0x576c/0x5778` |
| only three stores to `priv+0x29c` (`0xa1`/`0x08`/`0xf7`) | `.text+0x2850/0x2858`, `.text+0x4f6c/0x4f70`, `.text+0x51c4/0x51c8`; `grep -n '#0x29c'` → 3 stores / 2 loads |
| taskfile → `w1`/`w2` layout | `.text+0x3ac8..0x3afc` |
| 12-byte image = `*(priv+0x24)` (a CDB pointer) | `.text+0x577c/0x5780`; `.text+0x5884/0x588c`; `hw_chg_st` `.text+0x4480/0x4484`, `.text+0x44c4/0x44c8` |
| CDB opcode switch in `hw_chg_st` (`0xf0/0x1b/0x28/0xa8/0xbe`) | `.text+0x4084..0x40c8` |
| INQUIRY synthesised locally, gated on `priv+0x208` | `.text+0x55dc..0x55f0`, `.text+0x5880..0x58d0` (`ata_id_c_string` reloc `.text+0x58a0`) |
| INQUIRY template + FW_REV buffer | `sata_mt85xx_mod.ko` `.data+0x78` = `"MTK 85xx- FA Mode "`, `+0x8a` = FW_REV text |
| `get_FA_mode` reads `priv+0x208` | `.text+0x76c8` (`add r1,r2,#520`) |
| 05c000 writers (only three) | `decode/map.txt` rows 331-334/340-343/386-389 |
| mask = `0xfffffff0` | `port_start` `.text+0x32d0/0x32d8`; trace line 546541 |
| payload route (`type 0x10` → window → `priv+0x4c`) | `.text+0x47b4..0x48d4` |
| `sr_probe` order: `get_capabilities` → `register_cdrom` → `add_disk` → `Attached…` (KERN_DEBUG) | `VM:…/drivers/scsi/sr.c:852, 857-870` |
| `get_capabilities`: TUR → FA/BE-quiet ioctls → `rc = 0x8000002` or MODE SENSE page `0x2a` (128 B) | `sr.c:1008-1046` |
| `get_sectorsize` = READ CAPACITY(10), 8-byte reply, `capacity *= 4` for 2048-byte sectors | `sr.c:890-965`, called from `sr.c:306` |
| `Uniform CD-ROM driver Revision: 3.20` | `drivers/cdrom/cdrom.c:245, 404` |
| `CONFIG_BLK_DEV_SR=m`, `CONFIG_BLK_DEV_SD=y` | `VM:…/linux-2.6.35/.config:627, 624` |
| `sr_mod.ko depends=cdrom`, vermagic | `strings VM:/tmp/rootfs/lib/modules/2.6.35/BDP/sr_mod.ko` |
| model dispatch table | `emulator-kit/sony-bx510.c` `bx510_fe_dispatch()` |
