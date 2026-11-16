# Daemon-gate C111 decode — the two blockers: GESN media-present (GATE 06) and GET CONFIGURATION profile (GATE 11)

Date: 2026-11-13. Stage: static decode (Mac-side) of the C110 daemon-gate
failures, so the C111 fire has rows instead of guesses. This document
**extends** `daemon-gate-experiments.md` (the gate's own contract) and
`write10-model.md` §2 rows 30-37 (the recipe tables) — it re-derives neither.
Both blockers resolve to **one missing reply each**, both delivered through the
already-decoded type-0x10 window mechanism (`FE_PKT_OFF`).

**House rules.** **VERIFIED** = read out of an instruction, a literal pool, a
string, or a run already in evidence. **INFERRED** = reasoned from a pattern and
labelled. Every citation is reproducible with the commands in §7.

---

## 0. Bottom line

| gate | C110 measurement | decode verdict | model row |
|---|---|---|---|
| **06** sr0-node | `block node present, open failed`; the same run's ladder says why: `LADDER a2 FAIL dd reason=dd: can't open '/dev/sr0': No medium found` — **ENOMEDIUM** (uart L2119, L2424) | `open_for_data()` asks `sr_drive_status()`, which asks `sr_test_unit_ready()` — **short-circuited by the MT85XX FA-mode flag, no TUR on the wire** — and then `cdrom_get_media_event()` = **GESN 0x4a**. The bare-success GESN leaves the media descriptor empty ⇒ not `CDS_DISC_OK` ⇒ `-ENOMEDIUM`. **GESN is the deciding call, not TUR/sense.** | **row A:** 8-byte GESN reply, `buf[5] bit1 = media present` (§2.6) |
| **11** disc-profile | `ret=0 result=-1 raw=[ffffffff …]` (uart L2430); 2040 `0x46` posts, every one answered bare (`-> unknown`) | `_IDECLI_OddGetProfile` issues **GET CONFIGURATION 0x46 RT=1 alloc 20** and reads the profile from reply **bytes 6..7 big-endian**; `sacd_read.ko` keeps `u4Result = 0` only when that equals **0x10**, else `-1`. The `-1` is *provably the compare* (no `SenseKey` print anywhere in the run ⇒ `GetProfile` returned 0). | **row B:** 20-byte-capable GET CONFIG reply, profile `0x0010` at bytes 6..7 (§3.5) |
| 06 (determinism, not a blocker) | no `0x43` posts at all (the open died before `cdrom_count_tracks`) | once row A lands, `cdrom_count_tracks()` is the very next call: `audio_ioctl(CDROMREADTOCHDR)` → **READ TOC 0x43**. Without a reply the track count comes from uninitialised `kmalloc(32)` heap — a coin flip on how many TOC-entry reads follow. | **row C (optional):** static 12-byte single-data-track TOC (§2.7) |

Three brief assumptions the decode corrects:

1. **`sr_media_change` does not read GESN.** The media-present question is asked
   by **`sr_drive_status`** (the `drive_status` hook, called by
   `open_for_data`); `sr_media_change` (the `media_changed` hook) only calls
   `sr_test_unit_ready`, which on this rig returns `0x08000002` *without
   touching the wire* — so it always answers "changed", and that answer cannot
   fail an open (`cdrom.c:1020` discards `check_disk_change()`'s return).
2. **Zero TUR posts from sr is structural, not luck**: `sr_test_unit_ready`
   returns `0x08000002` at `sr_mod.ko .text+0x1554` (`mov r10,#134217730`)
   whenever `isFaMode || isBeQuiet`, and the same flag is what prints
   `sr0: scsi-1 drive` in the C110 log. TUR+sense is the *non-FA* path and is
   unreachable here.
3. **DOE/CDE do not exist on this path.** The only "changed/pending" bit any
   reader touches is **NEA** (`buf[2]` bit 7), which must be **0**. `grep`ing
   the Sony `sr`/`cdrom` sources for DOE/CDE finds nothing; they belong to legacy ATAPI
   Media Status Notification, unused by `sr`/`cdrom`.

---

## 1. Inputs and what each one is worth

| input | identity | use here |
|---|---|---|
| Sony kernel tree, VM `~/sony-kernel/linux-2.6.35` | the vendor 2.6.35 with the MT85XX patches (`sr.c:220` `MT85XX_IDE_GET_FA_MODE`, `sr.c:1012` the same call in `get_capabilities`) | source-level narrative + line citations |
| **shipped** `sr_mod.ko`, VM `/tmp/rootfs/lib/modules/2.6.35/BDP/sr_mod.ko` (34,944 B, symtab present) | the binary the C110 guest actually `insmod`ed | **every instruction citation below is from this file**, so no "is the tree the build?" risk for the load-bearing claims |
| **shipped** `cdrom.ko`, same dir (85,276 B) | same | the GESN reader's predicates |
| `evidence/bx510-guest/artifacts/bdpdrv.ko` (sha256 `6604f6cd…`) | `_IDECLI_OddGetProfile` `@.text+0xa9a54`, `_IDECLI_SendOddCmd.clone.0` `@.text+0xa92dc` | the CDB it issues, the transport, the reply parse |
| `original/sacd_read.ko` | `sacd_read_ioctl @.text+0x22c`, 5307 handler `@.text+0x5ac` | the `profile == 0x10` compare that produces `u4Result = -1` |
| C110 run, VM `/tmp/bdpdrv-runC110.uart.log` (298,256 B) | pulled locally for this decode | gate lines, `LADDER a2` ENOMEDIUM, `sr0: scsi-1 drive`, absence of `SenseKey` prints |
| C110 FE trace, VM `/tmp/bdpdrv-runC110.mmio.log` (1,133,217,700 B) | the `--unimp` trace (39,562,857 lines) | the FE PACKET census (exact post words, §3.4/§2.5) |

FE PACKET census of the whole C110 run (`grep -a 'FE PACKET' | sort | uniq -c`):

```
   2041  w1=00000000 w2=00000000 w3=00000000 nbytes=0   -> no-data     (TUR-shaped; bdpdrv's 5306 path only — sr posts none, §2.2)
   2040  w1=00000146 w2=00000000 w3=00000014 nbytes=326 -> unknown     (GET CONFIGURATION, alloc 20)
      3  w1=0000014a w2=00000010 w3=00000008 nbytes=330 -> gesn        (GET EVENT STATUS NOTIFICATION)
      1  w1=00000003 w2=00000060 w3=00000000 nbytes=3   -> req-sense
      0  opcode 0x43                                                      (READ TOC never issued — open died first)
```

The counts close: 2039 TUR+GET-CONFIG pairs are the **daemon's `server_loop`**
(`disc_sacd()` then `sacd_sacd()`, one of each per iteration, no dwell while
both answer), plus one TUR for gate 10 and one for the CLIDRIVE probe. The
three GESNs sit one-per-failing-open and **before** the first gate-11 `0x46`,
which is the ordering §2 predicts (open → drive_status → GESN; the ioctl path
never reaches it).

The three words are the CDB image `{w1: cdb[0..1], w2: cdb[4..5], w3: cdb[8..9]}`
— INFERRED from three opcodes agreeing at once (`0x4a 0x01`, `0x46 0x01`,
`0x03` + `cdb[4]=0x60` = libata's 96-byte sense buffer). The model does not have
to rely on that: `bx510_fe_cdb()` reads the authoritative CDB out of the mailbox
(`fe_cmd[1..3]`), which is what §4's rows use.

---

## 2. GATE 06 — why a *blocking* open says ENOMEDIUM

### 2.1 The open chain (all VERIFIED)

```
dd → open("/dev/sr0", O_RDONLY)                     [no O_NONBLOCK]
  → sr_block_open            sr.c:550
  → cdrom_open               cdrom.c:984
      if ((mode & FMODE_NDELAY) && (cdi->options & CDO_USE_FFLAGS))  ← NOT taken
          cdi->ops->open(cdi, 1);                    ← the O_NONBLOCK fast path
      else open_for_data(cdi)                        cdrom.c:1040
          cdo->drive_status(cdi, CDSL_CURRENT)       cdrom.c:1052   ← THE GATE
          if (ret != CDS_DISC_OK) { ret = -ENOMEDIUM; goto clean_up; }   cdrom.c:1088-1090
          cdrom_count_tracks(cdi, &tracks)           cdrom.c:1093   → READ TOC 0x43
          ret = cdo->open(cdi, 0)                    cdrom.c:1119   = sr_open
      cdrom_mmc3_profile(cdi)                        cdrom.c:1001   → GET CONFIG 0x46, alloc 32
      check_disk_change(bdev);                       cdrom.c:1020   (return discarded)
```

`cdi->options` defaults to `CDO_USE_FFLAGS` only (`cdrom.c:420`); `CDO_CHECK_TYPE`
is set only when the module param `check_media_type=1`, which it is not — so a
"zero data tracks" TOC is a warning, never `-EMEDIUMTYPE`.

**This is also the whole explanation for "the ladder works but the gate does
not".** Every `bdpdrv` ODD command reaches the drive through its own
`/dev/sr0` open with **`O_NONBLOCK`** — `_IDECLI_SendOddCmd.clone.0`
`.text+0xa936c` `mov r1,#2048` (ARM `O_NONBLOCK`) then
`.text+0xa9374` `bl sys_open` on the literal `/dev/sr0`
(`.rodata.str1.1+0x2ff39`), then `.text+0xa93a0` `bl sys_ioctl` with cmd
`0x8530` (`MT85XX_IOCTL`, `sr.c:609`). The fast path skips `open_for_data`
entirely. Gates 10/11, the whole C104/C108 ladder (`srread` opens
`O_RDONLY|O_NONBLOCK`, `sr_read10.c:140/208`) and the decrypt leg therefore
never ask the media question — **only `dd` does**, and `dd` is exactly what
gate 06 and gate 13 run.

### 2.2 `sr_test_unit_ready()` — the FA-mode short circuit (VERIFIED, shipped binary)

`sr_mod.ko .text+0x13b0` (`sr.c:206`), the branch that decides whether a TUR is
ever posted:

```
1484: ldr  r3, [sp, #0x24]        ; isFaMode  (scsi_ioctl MT85XX_IDE_GET_FA_MODE = 0x8531, lit @0x15a4)
1488: cmp  r3, #0
148c: bne  0x1554                 ; FA mode  → short circuit
1490: ldr  r6, [sp, #0x20]        ; isBeQuiet (scsi_ioctl MT85XX_IDE_GET_BE_QUIET = 0x8533, lit @0x15a8)
1494: cmp  r6, #0
1498: bne  0x1554                 ; quiet     → short circuit
…
1554: mov  r10, #134217730        ; = 0x08000002: driver-byte 8 + CHECK CONDITION, no command issued
```

`0x08000002 & 0xff = 0x02` = CHECK CONDITION ⇒ `scsi_status_is_good()` false.
The C110 log proves the flag is set in this rig: `sr0: scsi-1 drive`
(uart L2038) is printed **only** from `get_capabilities()`'s
`if (!scsi_status_is_good(rc))` branch with `rc = 0x8000002` (`sr.c:1018-1026`).
⇒ **sr never issues a TUR in these runs**, which is why the census shows no TUR
attributable to sr and why any TUR/sense-based model row would be dead code.

### 2.3 `cdrom_get_media_event()` — the predicates (VERIFIED, shipped binary)

`sr_drive_status` `sr_mod.ko .text+0x2bec` (`sr_ioctl.c:358`):

```
2c7c: bl   sr_test_unit_ready
2c80: cmp  r0, #0
2c84: bne  0x2cbc                ; not-ready (always, on this rig) → media event
…
2cfc: bl   cdrom_get_media_event ; ← the GESN
2d00: cmp  r0, #0
2d04: bne  0x2dc0                ; GESN failed → sense ladder
2d08: ldrb r3, [sp, #0xd]        ; med[1] == GESN buffer[5]
2d0c: and  r2, r3, #2            ; bit1 = media_present
2d14: cmp  r2, #0
2d18: beq  0x2d54                ; else: tst r3,#1 (bit0 door_open) → CDS_TRAY_OPEN
2ea4: mov  r4, #4                ; CDS_DISC_OK = 4        ← what the open needs
2eac: mov  r4, #1                ; CDS_NO_DISC = 1
2eb4: mov  r4, #2                ; CDS_TRAY_OPEN = 2
```

`cdrom.ko .text+0x2fa0` (`cdrom.c:465`) — the reader, instruction by instruction:

```
3008-3028: build cdb = {0x4a, 0x01, 0, 0, 0x10, 0, 0, 0, 8}  ; IMMED, class at cdb[4], alloc 8
303c:      blx r3                 ; ops->generic_packet → sr_packet → the FE PACKET
3048:      ldrh r3, [sp, #48]     ; buffer[0..1]  (the 8-byte reply lands here)
304c:      rev16 r3, r3           ; be16_to_cpu
3054:      cmp  r3, #3
3058:      bls  fail              ; ① Event Data Length must be > 3
305c:      ldrb r2, [sp, #0x32]   ; buffer[2] = event_header byte 2
3060:      and  r2, r2, #135      ; 0x87 → keep bits 0-2 (notification_class) and bit 7 (NEA)
3064:      cmp  r2, #4
3068:      beq  ok                ; ② (buffer[2] & 0x87) == 0x04  ⇒ class 4 AND NEA clear
30cc:      memcpy(med, buffer+4, 4)  ; r2 is still 4 from the mask — VERIFIED
```

Source side (`cdrom.c:465-486`, `cdrom.h:1204/1218`): `struct event_header`
`{__be16 data_len; notification_class:3; reserved1:4; nea:1; supp_event_class;}`
= 4 bytes; `struct media_event_desc {media_event_code:4; reserved1:4; door_open:1;
media_present:1; reserved2:6; start_slot; end_slot;}` = 4 bytes copied from
`buffer[4..7]`.

### 2.4 The 8-byte GESN reply, byte by byte

| off | value | why (reader) |
|---|---|---|
| 0..1 | `00 06` | `data_len` be16 = 6 ≥ 4 (`cmp r3,#3; bls fail`). A real drive's media-class length is 6; anything ≥ 4 passes |
| 2 | `04` | bits 0-2 = `notification_class` = **4**; bit 7 = **NEA = 0** (`and #0x87; cmp #4`). Bits 3-6 are masked off |
| 3 | `00` | `supp_event_class` — **copied nowhere, never read** on this path |
| 4 | `00` | `media_event_code` = 0 = "no change". Copied into `med[0]`; **never read** by `sr_drive_status` |
| 5 | `02` | **bit1 `media_present` = 1**, bit0 `door_open` = 0 — the only byte that decides the gate (`and #2` at `.text+0x2d0c`) |
| 6..7 | `00 00` | `start_slot` / `end_slot` — copied into `med[2..3]`, never read |

Answer to "does the drive also need media NOT changed (DOE/CDE/NEA)": **only NEA**,
and it must be **clear** (bit 7 of byte 2). There is no DOE/CDE bit in any reader
on this path. `media_event_code = 0` means "no change" by MMC convention, which
is also the honest answer here (the disc has been present since boot).

### 2.5 What C110 already measured (the negative that pins it)

* `GESN` posts: exactly **3**, all answered bare (`bx510_fe_post(s,0,0,0,0)`), one
  per failing blocking open (ladder `a2` dd, gate 06 dd, gate 13 dd — a
  `CDS_TRAY_OPEN` answer would have produced a *second* GESN in the same open
  via the tray-close re-check; none appeared).
* The failure mode is **ENOMEDIUM**, twice: `LADDER a2 FAIL dd reason=dd: can't
  open '/dev/sr0': No medium found` and `GATE 06 FAIL sr0-node -- block node
  present, open failed`.
* With `buffer` zeroed (`__memzero(sp+48,8)`, `.text+0x2fcc..0x2fdc`) the
  `data_len > 3` test fails deterministically ⇒ the answer comes from the
  sense ladder, not from a lucky garbage byte. The model row removes the branch
  entirely: `CDS_DISC_OK` on the first call.

### 2.6 MODEL ROW A — GESN media present (paste-ready, §4 block)

```
bx510_fe_gesn(payload)  →  payload = 00 06 04 00 00 02 00 00 , len = 8
delivery: bx510_fe_dram_write(s, FE_PKT_OFF, payload, 8);
          bx510_fe_post(s, 0x00100000u, FE_PKT_OFF, 8, 0);     ← type-0x10 offer, byte3 = 0
```

Delivery is the same type-0x10 window path that already carries MODE SENSE /
READ CAPACITY / the IDENTIFY block: bottom half `sata .text+0x47ac`, dir 1 →
`memcpy(priv+0x4c, *(svoif_int_ldr_dram) + w1, min(priv+0x54, w2))`
(`c97-read-path.md` §2 table row `type == 0x10`, dir 1; the IDENTIFY payload took
exactly this route at boot — `[IDE]<sata_mt85xx_id_atapi_dev>copy from
(0xdfc01000, 0x200) to (0xc6268c60, 0x200)` in the C110 log). `w2 = 8` equals
`cgc.buflen = 8`, so the clamp is exact.

### 2.7 ROW C (optional, same function) — READ TOC 0x43, format 0

`cdrom_count_tracks()` (`cdrom.c:1517`) is called **immediately after**
`drive_status` (`cdrom.c:1093`) and does:

```
audio_ioctl(cdi, CDROMREADTOCHDR, &header)     → sr_read_tochdr  (sr_ioctl.c:47)
    cdb = {0x43, 0, 0, 0, 0, 0, 0, 0, 12}      ; alloc 12, LBA format
    header.cdth_trk0 = buffer[2]; cdth_trk1 = buffer[3]
for (i = trk0; i <= trk1; i++)
    audio_ioctl(cdi, CDROMREADTOCENTRY, &entry)→ sr_read_tocentry (sr_ioctl.c:83)
    cdb[1] |= 0x02 (MSF), cdb[6] = track
    cdte_ctrl = buffer[5] & 0xf   ; CDROM_DATA_TRACK = 0x04
    cdte_addr.msf = buffer[9..11]
```

It only *fails* the open when the first ioctl returns `-ENOMEDIUM` — with a bare
success it returns `0` and reads uninitialised `kmalloc(32)` heap. So this row is
**not a blocker**; it is what makes the gate deterministic instead of a coin flip
on `cdth_trk0 > cdth_trk1` (and on how many of up to 255 garbage TOC-entry reads
get issued). One static 12-byte reply satisfies *both* readers:

```
00 0a  01 01  00 14 01 00  00 00 02 00
 │      │  │   │  │  │  └─ address MSF 00:02:00 = LBA 0
 │      │  │   │  │  └──── track number 1
 │      │  │   │  └─────── 0x14 = ADR 1 (position), CONTROL 4 (DATA track)
 │      │  │   └────────── descriptor byte 0 (reserved)
 │      │  └────────────── last track = 1
 │      └───────────────── first track = 1
 └──────────────────────── TOC data length 10 (be16)
```

---

## 3. GATE 11 — `_IDECLI_OddGetProfile` returns "not 0x10"

### 3.1 What it issues (VERIFIED — a literal in `.rodata`)

`bdpdrv.ko _IDECLI_OddGetProfile @.text+0xa9a54`:

```
a9a58: ldr  r2, [pc, #0x78]      ; .rodata+0x129b80 (R_ARM_ABS32)
a9a68: ldm  r2, {r0,r1,r2}       ; 12-byte CDB
a9a6c: stm  r3, {r0,r1,r2}
a9a70: mov  r0, #20              ; buffer 20 bytes
a9a74: bl   x_mem_alloc
a9a90: mov  r3, #20              ; length
a9a9c: mov  r1, #2               ; direction/quiet byte
a9aa8: bl   _IDECLI_SendOddCmd.clone.0
```

`.rodata+0x129b80` = **`46 01 00 00 00 00 00 00 14 00 00 00`**
(`46` = GET CONFIGURATION, `cdb[1]=0x01` → **RT = 1 "current profile only"**,
`cdb[3]=0` starting feature, `cdb[7..8] = 0x0014` = **allocation length 20**,
`cdb[9..11]=0` control). Not MODE SENSE, not INQUIRY.

### 3.2 The transport (VERIFIED) — and why it never hits the media gate

`_IDECLI_SendOddCmd.clone.0 @.text+0xa92dc` builds a 44-byte
`struct packet_command` and:

```
a9368: ldr  r0, [pc]  ; "/dev/sr0"        (.rodata.str1.1+0x2ff39)
a936c: mov  r1, #2048 ; O_NONBLOCK        (.text+0xa9374 → sys_open)
a93a0: bl   sys_ioctl ; cmd = 0x8530       (literal @0xa9498 = MT85XX_IOCTL)
```

`sr_block_ioctl` (`sr.c:609`) takes `cmd == MT85XX_IOCTL` into the Sony vendor
path → `sr_packet` → the ATAPI PACKET post the FE model already sees. Failure
prints `CDB: %02x … SenseKey: %06x` (`format .rodata.str1.1+0x31036`) and
returns `-1` (`0xa947c mvnne r0,#0`); success returns 0.

### 3.3 What it compares against — both consumers, one reply (VERIFIED)

| consumer | reply bytes read | predicate |
|---|---|---|
| `_IDECLI_OddGetProfile` `0xa9ab0..0xa9ac0` | `ldrbeq r2,[r4,#6]; ldrbeq r3,[r4,#7]; add r3,r3,r2,lsl #8` | profile = **be16 at 6..7**; on `SendOddCmd != 0` it writes 0 and returns the error |
| `cdrom_mmc3_profile` (`cdrom.c:847`, runs on the block-open path once GATE 06 passes) | `(buffer[6] << 8) \| buffer[7]` | same field, alloc 32, RT=0 |
| `sacd_read.ko` 5307 handler `@.text+0x5ac` | — | `0x5bc cmp r0,#0 / bne keep`; `0x5c8 ldr r3,[sp,#0x1c]; 0x5cc cmp r3,#16; 0x5d0 beq; 0x5d4 mvn r3,#0` ⇒ **`u4Result` is 0 only for profile `0x10`**, else `-1` |

`0x10` = MMC profile DVD-ROM (the profile a SACD reports; the gate's own string
already says so). Nothing anywhere compares against 0x2A/0x2B.

### 3.4 The measurement: `result=-1` is the compare, not a driver error (VERIFIED)

Two distinct code paths produce `-1` in `u4Result` (`.text+0x5c0` keeps
`GetProfile`'s return; `.text+0x5d4` overwrites with `-1` on the compare), so
`result=-1` alone is ambiguous. The run disambiguates it:

* `grep -ac SenseKey /tmp/bdpdrv-runC110.uart.log` = **0** — `SendOddCmd` never
  failed, for any of the 2040 `0x46` posts nor for the gate-11 one, so
  `_IDECLI_OddGetProfile` returned **0** and wrote `*out = buf[6]<<8|buf[7]`
  from the untouched 20-byte heap buffer.
* Corollary: a data-in PACKET answered with a bare type-0 completion (no payload)
  still completes **status GOOD** through this stack — the row is missing the
  *bytes*, not the completion.
* Corollary 2: the profile could never be 0x10 by accident; there is no path
  where the current reply yields 0 except heap luck.

### 3.5 MODEL ROW B — GET CONFIGURATION (paste-ready, §4 block)

```
bx510_fe_get_configuration(payload) → payload[0..13] , len = 14
    [0..3]  = 00 00 00 06   Data Length = 6 (one 6-byte Profile List descriptor)
    [4..5]  = 00 00         reserved
    [6..7]  = 00 10         CURRENT PROFILE = 0x0010  ← the load-bearing field
    [8..9]  = 00 00         Profile List feature code 0x0000
    [10]    = 08            bit3 current
    [11]    = 02            additional length 2 = one profile entry
    [12..13]= 00 10         the entry: 0x0010
delivery: bx510_fe_dram_write(s, FE_PKT_OFF, payload, min(14, cdb alloc));
          bx510_fe_post(s, 0x00100000u, FE_PKT_OFF, len, 0);
```

Bytes 6..7 are the only load-bearing ones (two independent readers, §3.3). Bytes
0..3 make the reply self-consistent with the descriptor that follows; bytes 8..13
are **unread** by both kernel readers — marked **INFERRED** (MMC-6 §5.3.6
Profile List layout) and easy to drop if a reviewer prefers a shorter reply
(`len = 8` with `Data Length = 0` also passes both readers).

Classifier: `0x46` is currently **not** in `bx510_fe_packet_kind`'s `cdb_ops[]`
so every one of the 2040 posts fell to `FE_PKT_UNKNOWN` (bare success). The
byte-count shortcut cannot shadow it — `nbytes` is `w1 & 0xffff = 0x0146`, never
0/8/128.

---

## 4. The patch — `emulator-kit/player.local.c`, style-matched

Four insertion points. Nothing existing changes behaviour: the new cases fall
through to the shared `bx510_fe_dram_write` + `bx510_fe_post(0x00100000, …)`
tail already used by `FE_PKT_READ_CAPACITY` / `FE_PKT_MODE_SENSE6`.

### 4.1 enum + name table (after `FE_PKT_GESN`, line 583)

```c
    FE_PKT_GESN,            /* sr.c's media poll: GET EVENT STATUS NOTIFICATION */
    FE_PKT_GET_CONFIG,      /* bdpdrv GetProfile / cdrom_mmc3_profile: 0x46 */
    FE_PKT_READ_TOC,        /* cdrom_count_tracks on the blocking open: 0x43 */
    FE_PKT_REQ_SENSE,       /* REQUEST SENSE after a drive-error completion */
```

```c
    case FE_PKT_GESN:        return "gesn";
    case FE_PKT_GET_CONFIG:  return "get-config";
    case FE_PKT_READ_TOC:    return "read-toc";
    case FE_PKT_REQ_SENSE:   return "req-sense";
```

### 4.2 classifier (`cdb_ops[]` line 605, the opcode switch line 619)

```c
    static const uint8_t cdb_ops[] = { 0x00, 0x03, 0x12, 0x1a, 0x1b, 0x25,
                                       0x28, 0x43, 0x46, 0x4a, 0x5a, 0xa8, 0xbe };
…
        case 0x4a: return FE_PKT_GESN;
        case 0x46: return FE_PKT_GET_CONFIG;
        case 0x43: return FE_PKT_READ_TOC;
        case 0x03: return FE_PKT_REQ_SENSE;
```

### 4.3 the reply builders (after `bx510_fe_mode_sense6`, which ends at line 679)

```c
/* GET EVENT STATUS NOTIFICATION (0x4a, media class) — the media-present answer
 * and the ONLY thing that decides "disc in drive" on this rig's blocking open
 * (daemon-gate-c111.md §2). Sony's sr_test_unit_ready short-circuits to a
 * NOT-READY result with NO SCSI command while the driver's FA-mode/be-quiet
 * flag is set (sr_mod.ko .text+0x1554 `mov r10,#0x08000002`) — and it is
 * (C110: "sr0: scsi-1 drive") — so sr_drive_status drops to
 * cdrom_get_media_event (.text+0x2cfc) and this 8-byte reply IS the media
 * check. Its predicates (cdrom.ko .text+0x3048..0x3068): be16(buf[0..1]) > 3,
 * (buf[2] & 0x87) == 0x04 — notification class 4, NEA clear — then
 * med = buf[4..7] with media_present = buf[5] bit1, door_open = buf[5] bit0
 * (sr_mod.ko .text+0x2d08/.text+0x2d54). buf[3], buf[4], buf[6], buf[7] are
 * copied or skipped and never read; no DOE/CDE bit exists on this path. */
static void bx510_fe_gesn(uint8_t *buf)
{
    memset(buf, 0, 8);
    buf[1] = 0x06;              /* Event Data Length 6 (predicate: > 3) */
    buf[2] = 0x04;              /* notification class 4; NEA (bit7) clear */
    buf[5] = 0x02;              /* bit1 media present = 1, bit0 door open = 0 */
}

/* GET CONFIGURATION (0x46) — the current MMC profile, big-endian at bytes 6..7.
 * Two independent readers of this one reply: bdpdrv _IDECLI_OddGetProfile
 * (.text+0xa9ab0: ldrb r2,[r4,#6]; ldrb r3,[r4,#7]; add r3,r3,r2,lsl #8) — the
 * daemon gate's profile test, CDB literal .rodata+0x129b80 =
 * 46 01 00 00 00 00 00 00 14 00 00 00 (RT=1, alloc 20) — and cdrom.c
 * cdrom_mmc3_profile, the same (buffer[6]<<8)|buffer[7] read on the block-open
 * path. 0x10 (DVD-ROM) is the profile the gate wants: sacd_read.ko
 * .text+0x5cc `cmp r3,#16` keeps u4Result 0 only for 0x10, else -1
 * (.text+0x5d4). Bytes 8..13 are a Profile List descriptor (feature 0x0000,
 * current, one entry = the same 0x0010) so the Data Length field does not
 * lie; no reader on this path parses them (MMC-6 §5.3.6 layout, INFERRED). */
#define FE_GETCONFIG_LEN  14u
static void bx510_fe_get_configuration(uint8_t *buf)
{
    memset(buf, 0, FE_GETCONFIG_LEN);
    buf[3]  = 0x06;             /* Data Length = 6: one 6-byte descriptor */
    buf[7]  = 0x10;             /* current profile 0x0010 */
    buf[10] = 0x08;             /* Profile List: bit3 current */
    buf[11] = 0x02;             /* additional length 2 = one profile entry */
    buf[13] = 0x10;             /* the entry: 0x0010 */
}

/* READ TOC/PMA/ATIP (0x43) format 0, one data track. Not a gate-06 blocker —
 * cdrom_count_tracks only fails the open on an -ENOMEDIUM return — but without
 * it cdth_trk0/trk1 come from uninitialised kmalloc(32) heap, so the track
 * count (and up to 255 TOC-entry reads) is nobody's decision. Both readers:
 * sr_read_tochdr wants buffer[2]/[3], sr_read_tocentry wants buffer[5]&0xf
 * (CDROM_DATA_TRACK = 0x04) and buffer[9..11] (MSF). */
static void bx510_fe_read_toc(uint8_t *buf)
{
    static const uint8_t toc[12] = {
        0x00, 0x0a,                 /* TOC data length 10 */
        0x01, 0x01,                 /* first track 1, last track 1 */
        0x00, 0x14, 0x01, 0x00,     /* ADR 1, CONTROL 4 (data), track 1 */
        0x00, 0x00, 0x02, 0x00      /* address MSF 00:02:00 = LBA 0 */
    };
    memcpy(buf, toc, sizeof(toc));
}

/* Allocation length for the three opcodes that carry it at CDB[7..8]. Other
 * data-in rows keep their own byte: READ CAPACITY 0x25 uses CDB[8..9],
 * MODE SENSE(6) 0x1a uses CDB[4] — do not route them through this. */
static unsigned bx510_fe_cdb_alloc78(Bx510State *s)
{
    uint8_t cdb[12];

    bx510_fe_cdb(s, cdb);
    return ((unsigned)cdb[7] << 8) | cdb[8];
}
```

### 4.4 the packet cases — replace the `FE_PKT_GESN` block (line 714)

```c
    case FE_PKT_GESN:
        bx510_fe_gesn(payload);
        len = 8;
        break;
    case FE_PKT_GET_CONFIG:
        bx510_fe_get_configuration(payload);
        len = FE_GETCONFIG_LEN;
        break;
    case FE_PKT_READ_TOC:
        bx510_fe_read_toc(payload);
        len = 12;
        break;
```

and immediately before the shared tail (`bx510_fe_dram_write`, line 744):

```c
    /* the CDB always wins: never answer with more bytes than it asked for */
    if (kind == FE_PKT_GESN || kind == FE_PKT_GET_CONFIG ||
        kind == FE_PKT_READ_TOC) {
        unsigned alloc = bx510_fe_cdb_alloc78(s);

        if (alloc != 0 && alloc < len) {
            len = alloc;
        }
    }
    bx510_fe_dram_write(s, FE_PKT_OFF, payload, len);
    bx510_fe_post(s, 0x00100000u, FE_PKT_OFF, len, 0);
```

### 4.5 the byte tables, checked against the decoded predicates (host self-check)

The three reply builders above were run through a host replica of every reader
predicate cited in §2/§3 (`cdrom.ko .text+0x3048..0x3068` for GESN,
`(buf[6]<<8)|buf[7]` + `cmp #16` for the profile, the two TOC parse offsets).
Source: the three builders verbatim + the predicate chain; output:

```
gesn: payload=00 06 04 00 00 02 00 00
gesn: reader rc=0 media_present=1 door_open=0 -> CDS_DISC_OK
bare: reader rc=1 (rejected => sense ladder, the measured ENOMEDIUM)
get-config: len=14 data_len=6 profile=0x0010 desc_feature=0x0000 addl=2 entry=0x0010
sacd_read: cmp profile,#16 -> u4Result=0 (PASS)
read-toc: trk0=1 trk1=1 ctrl=0x4 (DATA_TRACK=yes) msf=00:02:00 data_len=10
SELFTEST PASS   (rc=0)
```

Two things it pins that prose does not: the **bare** reply the model sends today
is rejected by the same predicate chain (so the measured ENOMEDIUM is the
predicate, not a heap accident), and the GET CONFIG Data Length field agrees
with the descriptor it announces (6 = the 6 bytes at `[8..13]`). It is a
predicate check, not an emulator run: the one link it cannot cover is the
window delivery itself (§6 item 1).

---

## 5. What C111 should show (the greps that decide it)

| check | expected on PASS | if it fails |
|---|---|---|
| `grep -a 'FE PACKET' … \| sort \| uniq -c` | `-> gesn` (w1=0000014a), `-> get-config` (w1=00000146), **zero** `w1=00000146 … -> unknown` | a `0x46` still logged `unknown` = the classifier edit did not land |
| `GATE 06 PASS sr0-node -- block node present, open(O_RDONLY) ok` | the ENOMEDIUM is gone | still ENOMEDIUM ⇒ GESN payload not reaching the driver (see §6 item 1) |
| `LADDER a2 PASS dd LBA 16` | the `dd` leg (blocking open + block-layer read) now works — the first end-to-end proof the daemon's own disc path opens | read error after open ⇒ that is the READ path, not this decode |
| `GATE 11 PASS disc-profile -- result=0` | profile 0x10 seen by `sacd_read.ko` | `result=-1` + a `SenseKey` print ⇒ the GET CONFIG *completion* regressed; `result=-1` without a print ⇒ bytes still not delivered |
| `grep -ac SenseKey` | **0** throughout | any hit names the failing CDB in hex — that is the diagnosis, not a mystery |
| `GATE 13 master-toc` | needs the block layer; expect it to move from `0 B` to a real 20480-byte read | if it still says 0 B, the open failed again — check §2.7 TOC row |

---

## 6. Labels, and what stays open

| claim | label |
|---|---|
| `sr_test_unit_ready` short-circuits to `0x08000002` with no command when FA/quiet is set; the flag is set in this rig | **VERIFIED** (`sr_mod.ko .text+0x1484..0x1554`; `sr0: scsi-1 drive` C110 L2038) |
| the blocking open dies in `drive_status` → GESN, not in a TUR | **VERIFIED** (code path + ENOMEDIUM measurement + one GESN per open, no TUR attributable to sr) |
| the GESN predicates: `data_len > 3`, `(buf[2]&0x87)==4`, `media_present = buf[5] bit1` | **VERIFIED** (`cdrom.ko .text+0x3048..0x3068`, `sr_mod.ko .text+0x2d08`, `cdrom.c:465`, `cdrom.h:1204/1218`) |
| no DOE/CDE on this path; NEA must be 0 | **VERIFIED** (no symbol/bit anywhere in the Sony tree's sr/cdrom; NEA is the `and #0x87` bit) |
| `GetProfile` issues GET CONFIG `46 01 … 14` and parses be16 at 6..7 | **VERIFIED** (`.rodata+0x129b80`; `.text+0xa9ab0..0xa9ac0`) |
| `u4Result = -1` came from the `profile == 0x10` compare, not from a driver error | **VERIFIED** (that compare at `sacd_read.ko .text+0x5cc/.text+0x5d4`; zero `SenseKey` prints in the whole run) |
| the reply reaches the guest through the type-0x10 window (`FE_PKT_OFF`) for a packet data-in | **decoded, unexercised for a PACKET** — `sata .text+0x47ac` dir-1 memcpy is VERIFIED by instruction and proven only for the IDENTIFY payload; C111 is its first packet use |
| Profile List descriptor bytes 8..13 (feature 0x0000 / current / one entry) | **INFERRED** (MMC-6 §5.3.6); unread by both kernel readers — drop to `len = 8` if a reviewer objects |
| READ TOC bytes `00 0a 01 01 00 14 01 00 00 00 02 00` | **INFERRED** from the two readers' parse offsets (`sr_ioctl.c:47/83`) + MMC format-0 layout; no C-run has issued a `0x43` yet |
| post words = CDB image `{cdb[0..1], cdb[4..5], cdb[8..9]}` | **INFERRED** (three opcodes agree); the rows read the CDB from the mailbox instead, so nothing depends on it |

Open items, in the order they would bite:

1. **Packet data-in delivery is the one unproven link.** If GATE 11 still says
   `result=-1` with no `SenseKey` print after the patch, the window bytes are not
   landing; the settling experiment is to dump the FE reply bytes host-side
   (`FE PKT` line already names the window offset) against `cgc.buffer` read back
   through `MT85XX_IOCTL` — i.e. add the GET CONFIG reply dump to the helper, not
   another decoder round.
2. **`0x43`/`0x51`/`0x52` are still unclassified** (READ TOC, Sony disc-info).
   `0x51` READ DISC INFORMATION is issued by `sr_cd_check` only on a real media
   change; the daemon path never called it in C110. Out of scope here, named so
   the next gate failure is not a surprise.
3. **`sr_media_change` will keep saying "changed"** for as long as FA mode is on
   (it reads `sr_test_unit_ready`, which never asks the drive). Harmless for the
   open (return discarded, `cdrom.c:1020`) but it means `check_disk_change`
   invalidates buffers on every open — worth remembering if a later read looks
   short.

---

## 7. Reproduce

```sh
# the shipped binaries the guest ran (VM has the assembled rootfs)
scp -o BatchMode=yes -P 2222 user@192.0.2.10:/tmp/rootfs/lib/modules/2.6.35/BDP/sr_mod.ko   /tmp/
scp -o BatchMode=yes -P 2222 user@192.0.2.10:/tmp/rootfs/lib/modules/2.6.35/BDP/cdrom.ko    /tmp/
scp -o BatchMode=yes -P 2222 user@192.0.2.10:'~/sony-kernel/linux-2.6.35/drivers/scsi/sr.c'         /tmp/
scp -o BatchMode=yes -P 2222 user@192.0.2.10:'~/sony-kernel/linux-2.6.35/drivers/scsi/sr_ioctl.c'   /tmp/
scp -o BatchMode=yes -P 2222 user@192.0.2.10:'~/sony-kernel/linux-2.6.35/drivers/cdrom/cdrom.c'     /tmp/
scp -o BatchMode=yes -P 2222 user@192.0.2.10:'~/sony-kernel/linux-2.6.35/include/linux/cdrom.h'     /tmp/

# §2.2 the FA short circuit
/opt/homebrew/opt/llvm/bin/llvm-objdump -dr --no-show-raw-insn --triple=armv6-linux-gnueabi \
    --start-address=0x1484 --stop-address=0x1558 /tmp/sr_mod.ko
# §2.3 the reader's predicates
/opt/homebrew/opt/llvm/bin/llvm-objdump -dr --no-show-raw-insn --triple=armv6-linux-gnueabi \
    --start-address=0x2fa0 --stop-address=0x30d8 /tmp/cdrom.ko
/opt/homebrew/opt/llvm/bin/llvm-objdump -dr --no-show-raw-insn --triple=armv6-linux-gnueabi \
    --start-address=0x2cf4 --stop-address=0x2d20 /tmp/sr_mod.ko
# §3.1 the CDB literal
python3 -c "d=open('evidence/bx510-guest/artifacts/bdpdrv.ko','rb').read(); \
  o=0x31e2fc+0x129b80; print(d[o:o+12].hex(' '))"
# §3.3 the compare in the daemon's own module
/opt/homebrew/opt/llvm/bin/llvm-objdump -dr --no-show-raw-insn --triple=armv6-linux-gnueabi \
    --start-address=0x5ac --stop-address=0x5e0 original/sacd_read.ko
# §1 the post census + §3.4 the disambiguator — VM side, multi-word commands go
# through vm-script (vm-exec's single-argument form cannot carry a pipeline):
cat > /tmp/c111-repro.sh <<'EOF'
grep -a -o 'FE PACKET w1=[0-9a-f]* w2=[0-9a-f]* w3=[0-9a-f]* nbytes=[0-9]* -> [a-z-]*' \
    /tmp/bdpdrv-runC110.mmio.log | sort | uniq -c
grep -ac SenseKey /tmp/bdpdrv-runC110.uart.log
grep -an 'GATE 0[6]\|GATE 11\|LADDER a2\|sr0: scsi-1' /tmp/bdpdrv-runC110.uart.log
EOF
make vm-script SCRIPT=/tmp/c111-repro.sh
```
