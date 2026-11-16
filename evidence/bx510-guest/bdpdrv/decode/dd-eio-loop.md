# dd-EIO decode — the `sdev->changed` latch: why the block layer's read of /dev/sr0 dies with EIO, and why "2038" is not a retry count

Date: 2026-11-13. Stage: static decode (Mac-side) of the C112b daemon-gate
failure (`GATE 13 FAIL master-toc -- LBA 510 x10 = 0 B`, ladder
`a2 FAIL dd reason=dd: /dev/sr0: Input/output error`), while the same LBAs read
fine through SG_IO. This document **extends** `daemon-gate-c111.md` (it
re-derives none of the GESN / GET CONFIGURATION / READ TOC rows — those are
proven there) and `sr0-scan-seq.md` §3.2 (which left FA mode as open item O-1;
§3 below closes it).

**House rules.** **VERIFIED** = read out of an instruction, a literal, a source
line, or a run already in evidence. **INFERRED** = reasoned from a pattern and
labelled as such. Every citation is reproducible with §8.

---

## 0. Bottom line

| question in the brief | answer | label |
|---|---|---|
| what loops ~2038 times and then returns EIO? | **Nothing loops.** `dd` opens once, issues one buffered read, and that read is **killed in `sr_prep_fn` before any SCSI command exists** — `sr_mod.ko` `.text+0xfdc..0xfec` tests `sdev->changed` and returns `BLKPREP_KILL` (`.text+0x1328` `mov r5,#1`). The block layer completes the request with `-EIO`. **Zero READ packets reach the FE.** | **VERIFIED** (instructions + FE census §4) |
| is 2038 meaningful (a counter / timeout loop)? | **No.** 2037 of the 2038 TURs and all 2037 `0x46 RT=1 alloc 20` posts are the **daemon's own 1 Hz disc poll** — `_IDECLI_OddTestUnitReadyLoop` then `_IDECLI_OddGetProfile` — and the daemon is launched *after* the gate script finishes (uart L2456). The count equals its `[IDE]cache_avail_cnt` log line count (**2036**) plus the gate-10/gate-11 pair. It is run duration in seconds, not a retry. | **VERIFIED** (counts in §4.2) |
| does the EIO come from sense / CHECK CONDITION / GET_PERFORMANCE? | **None of them.** No sense is fetched (`req-sense` = 1 in the whole run, and it belongs to the ladder's past-EOF probe), no CHECK CONDITION is synthesised, and no CDB of any kind is issued for the dd reads. The decision is made one layer above `sr_do_ioctl`. | **VERIFIED** (census §4.1) |
| who issues the interleaved TUR + `0x46` pair, and what ends it? | The **daemon**, not the kernel: `_IDECLI_OddTestUnitReadyLoop` (TUR CDB `00`) + `_IDECLI_OddGetProfile` (CDB literal `46 01 …14 00`, RT=1 alloc 20) once per `server_loop` pass. It ends when the disc **read** succeeds, not on any reply value — the poll already advanced past the profile gate in C112b (GATE 11 PASS). | **VERIFIED** for the pair identity; end-condition **INFERRED** from `_IDECLI_OddTestUnitReadyLoop`'s call site |
| would a different GET CONFIGURATION reply content fix it (alloc 20 vs our 14)? | **No — the reply is not consulted.** `cdrom_mmc3_profile` (`cdrom.c:847-867`) reads `buffer[6..7]` only, once, and both readers were already satisfied in C112b (GATE 11 PASS). Bytes `[8..19]` of the kernel's 32-byte buffer are never read by either consumer, so truncating to 14 is inert, and there is no retry in that function at all. | **VERIFIED** (source + §5) |
| is it `cdrom.c`'s "disc status changed" retry — is GESN/GET CONFIG re-asserting a media event? | **Half right, and the half that is right is the load-bearing half.** `check_disk_change()` → `sr_media_change()` **does** run on every open and **does** re-arm `changed = 1` — not because our replies change state, but because `sr_test_unit_ready()` is short-circuited by Sony's FA/be-quiet flag and can never return success. The flag is a **latch**, not a loop: there is no retry anywhere. | **VERIFIED** (§3, instructions) |
| the ONE change that ends it | **No FE reply change can end it.** The lever is the driver flag `isFaMode`/`isBeQuiet`: clear it and the latch dissolves (§6, paste-ready helper + falsifiable prediction). No model row is needed — every follow-on CDB (READ CAPACITY `0x25`, READ TOC `0x43`, READ `0x28`) already has a row. | **VERIFIED** for "no FE reply can end it"; the clear-flag helper is the **one** open assumption (§6.3) |

Correction to the brief's model, in one line: **the EIO is not a timeout or a
retry budget — it is a boolean the Sony fork tests before it builds a CDB, and
that boolean is stuck because the same fork fabricates `sr_test_unit_ready`.**

---

## 1. Inputs and what each one is worth

| input | identity | use here |
|---|---|---|
| **shipped** `sr_mod.ko`, VM `/tmp/rootfs/lib/modules/2.6.35/BDP/sr_mod.ko` (34,944 B, md5 `26d748bceba23ecf1311a8f37cc4f436`) | the binary the C112b guest `insmod`ed at uart L2035 | **every instruction citation in §2/§3 is from this file** |
| **shipped** `cdrom.ko`, same dir (85,276 B) | same | `cdrom_mmc3_profile` alloc/parse (§5) |
| **shipped** `sata_mt85xx_mod.ko`, VM `/tmp/sata_mt85xx_mod.ko` | the LLDD behind `scsi_host_template.ioctl` | `sata_mt85xx_get_FA_mode` `.text+0x7680`, `get_BE_quiet` `.text+0x775c`, `data_xfer`'s FA branch `.text+0x55dc` (§6) |
| Sony kernel tree, VM `~/sony-kernel/linux-2.6.35` | the vendor fork | `sr.c:206-250` (TUR), `sr.c:255-320` (media_change), `sr.c:403-460` (prep_fn), `sr.c:837` (probe), `sr.c:1005-1055` (get_capabilities), `cdrom.c:984-1024` (open), `cdrom.c:847-867` (mmc3_profile), `sr_vendor.c:157` (`sr_cd_check`), `include/scsi/scsi_device.h:115-120` (the bitfield) |
| `original/sacd_extract_160` (via `daemon-ioctl-side.md`) | the daemon | its master-TOC read is a **plain** `lseek64`+`read` at LBA 0x1FE ×10 (`0x2a25c`) — i.e. gate 13 is testing the daemon's real mechanism |
| C112b run, VM `/tmp/bdpdrv-runC112b.uart.log` (298,334 B, 5,592 lines) | pulled locally for this decode | gate lines, `sr0: scsi-1 drive`, the daemon launch line, `[IDE]cache_avail_cnt` count |
| C112b FE trace, VM `/tmp/bdpdrv-runC112b.mmio.log` (1,134,499,188 B, ~39.6 M lines) | `--unimp` trace | the whole-run FE census (§4.1) |

Census method: `grep -an 'FE PACKET'` (4,091 hits) and `grep -an 'FE READ'`
(11 hits) — no sampling, no line-range guessing.

---

## 2. Where the EIO is born: `sr_prep_fn` refuses `REQ_TYPE_FS` while `changed` is set

### 2.1 The instruction chain (VERIFIED — shipped `sr_mod.ko`)

`sr_prep_fn` `sr_mod.ko .text+0xefc` (`sr.c:403`). The FS leg first
(`sr.c:417-420`), then the three kill tests, then **the `changed` test**:

```
 f6c: ldr  r0, [r4]  ...            ; sdp = q->queuedata
 f74: bl   scsi_setup_fs_cmnd       ; rq->cmd_type == REQ_TYPE_FS (1)
 f78: subs r5, r0, #0
 f7c: bne  0x132c                   ; prep error -> out
 ...
 fbc: ldr  r10, [r6, #0x1a8]        ; cd = rq->rq_disk->private_data   (struct scsi_cd)
 fc0: ldr  r3,  [r10, #0x8]         ; r3 = cd->device                  (struct scsi_device *)
 fc4: cmp  r3, #0
 fc8: beq  0x1328                   ; !cd->device            -> out
 fcc: ldr  r2,  [r3, #0x2cc]        ; sdev->sdev_state
 fd0: cmp  r2, #4
 fd4: cmpne r2, #6
 fd8: beq  0x1328                   ; !scsi_device_online()  -> out
 fdc: ldrb r2,  [r3, #0x7c]         ; sdev bitfield byte
 fe0: and  r2, r2, #4               ; BIT 2 == sdev->changed
 fe4: uxtb r2, r2
 fe8: cmp  r2, #0
 fec: bne  0x1328                   ; ← changed != 0  ⇒ refusal   (sr.c:440)
 ...
 1328: mov r5, #1                   ; BLKPREP_KILL          (blkdev.h: BLKPREP_KILL == 1)
 132c: ...                          ; out: return r5 through SR_LOG tail
```

`include/scsi/scsi_device.h:115-120` fixes the bit order —
`writeable:1` (bit 0), `removable:1` (bit 1), **`changed:1` (bit 2)**,
`busy:1`, … — so `and #4` is `sdev->changed` and nothing else. The same bit is
set/cleared in §3 by `orr #4` / `bic #4` at the same byte offset.

`BLKPREP_KILL` is the "no I/O ever happens" verdict — `include/linux/blkdev.h:693`
`#define BLKPREP_KILL 1` matches `mov r5,#1` — and in 2.6.35 `blk_peek_request()`
(`block/blk-core.c`, the `ret == BLKPREP_KILL` branch) takes the request off the
queue and calls `__blk_end_request_all(rq, -EIO)`. The transport is never
touched. That is the entire source of `dd: /dev/sr0: Input/output error`.

### 2.2 What the FE census says: the reads never existed (VERIFIED)

Whole C112b run, `FE PACKET` lines (4,091) and `FE READ` descriptor-DMA lines
(11):

```
   2038  w1=00000000 w2=00000000 w3=00000000 nbytes=0   -> no-data       (TUR)
   2037  w1=00000146 w2=00000000 w3=00000014 nbytes=326 -> get-config     (RT=1 alloc 20, bdpdrv GetProfile)
      3  w1=00000046 w2=00000000 w3=00000020 nbytes=70  -> get-config     (RT=0 alloc 32, cdrom_mmc3_profile)
      6  w1=0000014a w2=00000010 w3=00000008 nbytes=330 -> gesn
      3  w1=00000043 w2=00000000 w3=0000000c nbytes=67  -> read-toc       (tochdr)
      3  w1=00000243 w2=00010000 w3=0000000c nbytes=579 -> read-toc       (tocentry, MSF)
      1  w1=00000003 w2=00000060 w3=00000000 nbytes=3   -> req-sense      (the ladder's past-EOF drive error)
      0  any READ-family PACKET from the block layer
```

and the 11 `FE READ` lines reconcile exactly to the **ioctl** legs, not the
block layer:

```
3752822 lba=16     nsec=1     ← ladder read10 lba16
3763337 lba=510    nsec=1     ← ladder read10 lba510
3773122 lba=532104 nsec=1     ← ladder read10 lba532104
3783433 lba=0      nsec=1     ← ladder read10 lba0
3793154 lba=510    nsec=10    ← ladder read10 lba510x10          (the 20480-byte oracle match)
3846294 lba=1064207 nsec=1    ← ladder read10 lba1064207
3857613 past EOF lba=1064208  ← ladder past_eof (drive error)
3906937 lba=510 nsec=2 len=4128 frame=2064   ← 5303 MEASURED leg
4032246 lba=510 nsec=2 len=4128 frame=2064   ← 5303 sacd_sg leg
```

Three `dd` opens, three buffered reads, **zero** transport traffic for any of
them. `sr_prep_fn` is provably the only place left where a read can turn into
`-EIO` without a CDB.

### 2.3 The `dd` runs are single-shot, not retried (VERIFIED)

A blocking open on this fork has a fixed, five-packet signature — 2× GESN,
READ TOC `0x43`, READ TOC `0x243`, GET CONFIG `0x46 RT=0 alloc 32` — from
`cdrom_open` → `open_for_data`→`sr_drive_status` (GESN), `cdrom_count_tracks`
(the two TOCs) and `cdrom_mmc3_profile` (the `0x46`). It appears **exactly
three times** in the run, at trace lines

```
3750118  ← ladder a2      dd if=/dev/sr0 bs=2048 skip=16  count=1
5156389  ← gate 06        dd if=/dev/sr0 bs=2048 count=0     (opens, reads nothing, PASSES)
5182691  ← gate 13        dd if=/dev/sr0 bs=2048 skip=510 count=10
```

Each is followed by exactly one failure. There is no re-open, no re-read, no
retry budget: `dd` exits on the first `read()` error. Gate 06 passing while
gates a2/13 fail is the fingerprint of this decode — the open path is fine
(its gate was the GESN row, `daemon-gate-c111.md` §2, now PASSing); it is the
**read** path that is dead.

---

## 3. Why the latch is stuck: `sr_media_change` can never reach its clear path

### 3.1 `changed` has exactly one setter at probe and one clear site (VERIFIED)

| site | source | shipped-binary evidence |
|---|---|---|
| **set at probe** | `sr.c:837` `cd->device->changed = 1;  /* force recheck CD type */` | `sr_probe` `.text+0x1a6c` |
| **re-armed on every open** | `sr.c:284-295`: `if (retval \|\| (scsi_sense_valid(sshdr) && sshdr->asc == 0x3a)) { cd->device->changed = 1; retval = 1; goto out; }` | `sr_media_change` `.text+0x1654..0x168c` |
| **cleared** | `sr.c:299-300`: `retval = cd->device->changed; cd->device->changed = 0;` — reachable **only** when `sr_test_unit_ready` returned 0 | `sr_media_change` `.text+0x1738..0x1744` |

`grep -n 'changed' drivers/scsi/sr.c` in the Sony tree returns exactly these
three writers (837, 290, 300) plus the read at 440. Nothing else in the tree
clears `sdev->changed` for a CD device (`sd.c:999` does it for disks).

### 3.2 The TUR that would clear it is fabricated (VERIFIED — shipped binary)

`sr_media_change` `.text+0x15b0`:

```
 164c: ldr  r0, [r4, #0x8]      ; r0 = cd->device
 1650: bl   sr_test_unit_ready  ; ← the ONLY thing that can unlock the clear path
 1654: subs r6, r0, #0
 1658: bne  0x1680              ; retval != 0  ⇒  the `changed = 1` store
 165c: cmp  r5, #0 / beq 0x16e4 ; sense-invalid fast path (still needs r0 == 0)
 1674: ldrb r3, [r5, #0x2] / cmp r3, #58   ; sshdr->asc == 0x3a (medium not present)
 1680: ldr  r3, [r4, #0x8]
 1684: ldrb r2, [r3, #0x7c]
 1688: orr  r2, r2, #4          ; sdev->changed = 1
 168c: strb r2, [r3, #0x7c]
 ...
 1738: ldrb r3, [r2, #0x7c]     ; THE clear path — unreachable while 0x1658 branches away
                                ;   (sr.c:299-300 = retval = changed; changed = 0)
 173c: bic  r1, r3, #4
 1740: tst  r3, #4
 1744: strb r1, [r2, #0x7c]     ; sdev->changed = 0
 1748: beq  0x1958              ; retval was 0 -> return 0
 1754: bl   sr_cd_check         ; retval was 1 -> re-probe multisession ...
             (+ get_sectorsize, sr.c:301-305)
```

and `sr_test_unit_ready` `.text+0x13b0` returns a fabricated CHECK CONDITION
whenever the vendor flags are set — `daemon-gate-c111.md` §2.2 already pinned
this: `.text+0x1484` loads `isFaMode`, `.text+0x1490` loads `isBeQuiet`,
`.text+0x1554` `mov r10,#134217730` = `0x08000002`, **no CDB issued**. So
`retval` is `0x08000002 ≠ 0` on every call, `0x1658` always branches to the
setter, and `changed` — armed at probe — is **never cleared for the lifetime of
the module**.

### 3.3 Two independent measurements confirm `changed` is (and stays) 1 (VERIFIED)

1. **`sr0: scsi-1 drive`** at insmod time (uart L2036) is printed by
   `get_capabilities` only on its `!scsi_status_is_good(rc)` branch
   (`sr.c:1029-1039`), and rc there is `0x8000002` **only** from the FA/be-quiet
   short circuit — the non-FA branch would have issued MODE SENSE(6). The C112b
   census contains **no** `nbytes=128 / mode-sense-6` packet anywhere, so the
   short circuit fired. This closes `sr0-scan-seq.md` **O-1**: the flag is
   non-zero in this rig. (It is the same conclusion `scsi-scan-codes.md` drew
   from the `MTK 85xx- FA Mode` identity — the canned INQUIRY block at
   `.data+0x70`, reached only by `data_xfer`'s FA branch `.text+0x55dc`.)
2. **Capacity is still the `sr_probe` default.** Ladder leg (a) reports
   `blkgetsize64=1073741312 blkssz=512`; `1073741312 = 0x1fffff * 512`, i.e.
   exactly `cd->capacity = 0x1fffff` (`sr.c:836`) with the default 512-byte
   logical block. `get_sectorsize()` — the function that would have set both
   from READ CAPACITY — runs **only** from the clear path (`sr.c:301-305`), and
   the run contains **zero** `0x25 READ CAPACITY` packets. The latch is visible
   in the size probe itself.

### 3.4 What this costs on the FE side: nothing (VERIFIED)

The one-line summary the brief needs: **there is no reply the FE can send that
would clear `sdev->changed`.** No CDB is issued on the failing path, so no
reply is read; the decision is `sr_mod.ko`'s own boolean, and its unlock
condition (`sr_test_unit_ready() == 0`) is a hard-coded fabrication gated on a
*vendor flag*, not on the drive.

---

## 4. "2038" decoded: it is the daemon's 1 Hz poll, launched after the gate

### 4.1 The pair, byte for byte (VERIFIED)

| field | TUR post | `0x46` post | who |
|---|---|---|---|
| `w1` | `00000000` | `00000146` | CDB image `{cdb[0..1], cdb[4..5], cdb[8..9]}` |
| `w3` | `00000000` | `00000014` | ← **allocation length 20** at CDB[7..8] |
| meaning | `TEST UNIT READY` | `GET CONFIGURATION, RT=1 (current profile), alloc 20` | |
| CDB owner | `_IDECLI_OddTestUnitReadyLoop` | `_IDECLI_OddGetProfile`, literal `.rodata+0x129b80` = `46 01 00 00 00 00 00 00 14 00 00 00` | **`bdpdrv.ko`**, not the kernel |

The kernel's only `0x46` is `cdrom_mmc3_profile` (`cdrom.c:855-858`: `cmd[1]=0`
RT=0, `cmd[8]=32` alloc) — that is the `w1=00000046 … w3=00000020` row, and it
appears **3 times**, once per blocking open. The 2,037 `RT=1 alloc 20` posts
cannot be kernel traffic.

### 4.2 The count reconciles three ways (VERIFIED)

| observation | value | source |
|---|---|---|
| `get-config RT=1 alloc 20` posts | 2,037 | census §2.2 |
| `[IDE]cache_avail_cnt = 2, cache_fs_cnt = 0` uart lines | **2,036** | `grep -ac cache_avail_cnt /tmp/bdpdrv-runC112b.uart.log` |
| daemon launch line | `./sacd_extract_160 -S </dev/null … &` at uart **L2456**, i.e. **after** `DAEMON_GATE_RC=1` (L2445) | uart |
| gate-10 (`5306`) + gate-11 (`5307`) pair | trace `5161815` (TUR) + `5169109` (0x46), sitting between gate 06's open (5 156 389) and gate 13's open (5 182 691) — exactly the gate script's 10/11 slots | trace |
| daemon poll pairs | 2,036, starting at trace `5223093` (TUR) / `5223318` (0x46) and running unbroken to the last line `39610164` | trace |
| one stray TUR at trace `561995` | 1 | unattributed (early probe traffic; the only packet before the ladder) — **INFERRED** |

2,036 + 1 = 2,037 `0x46`; 2,037 TUR + the stray = 2,038 `no-data`. The C110
figures (2,040 `0x46` / 2,041 TUR) differ by a couple of seconds of daemon
runtime, nothing more.

Consequence: **the census the brief read as "each dd open retries ~2038 times"
is the daemon's poll**, and it is *disjoint* from the three `dd` opens in §2.3.
A retry loop inside `dd`'s open would also have to show 2 037 open signatures
(2× GESN + 2× TOC + GET CONFIG); the run contains three.

### 4.3 What the daemon's loop is waiting for (INFERRED)

`_IDECLI_OddTestUnitReadyLoop` + `_IDECLI_OddGetProfile` is the daemon's
disc-detect pass (`drvcli-surface.md` §P3 names the same two symbols behind
`testphy`). In C112b the profile gate answered `0x10`, so the daemon advanced
to `DISC_OPEN` → `scarletbook_read_master_toc` (plain read at LBA 0x1FE) → that
read is the one §2 kills → the daemon logs, unwinds, and polls again. This is
why the daemon emits `cache_avail_cnt` once per pass and never logs
`Can't read Master TOC.` at level 1: the loop never terminates, it is the
`server_loop` itself. **The daemon's loop and the gate's `dd` die of the same
bug**, which is why the gate is a faithful proxy — only the *count* in the
brief was misread as a retry budget.

---

## 5. The reply-content questions, answered decisively

**"Does the reader read bytes 0..19 of a buffer kmalloc'ed 20 and branch on
garbage at [8..19]?"** No.

`cdrom_mmc3_profile` (`cdrom.c:847-867`, VERIFIED source + `cdrom.ko`):

```c
    char buffer[32];                                  /* a 32-byte STACK buffer */
    init_cdrom_command(&cgc, buffer, sizeof(buffer), CGC_DATA_READ);
    cgc.cmd[0] = GPCMD_GET_CONFIGURATION;
    cgc.cmd[1] = 0;                                   /* RT = 0 */
    cgc.cmd[8] = sizeof(buffer);                      /* alloc 32 */
    cgc.quiet = 1;
    if ((ret = cdi->ops->generic_packet(cdi, &cgc)))  /* one packet, no retry */
        mmc3_profile = 0xffff;
    else
        mmc3_profile = (buffer[6] << 8) | buffer[7];  /* bytes 6..7 ONLY */
    cdi->mmc3_profile = mmc3_profile;                 /* never branched on */
```

and `bdpdrv`'s `_IDECLI_OddGetProfile` reads `[r4,#6]`/`[r4,#7]` only
(`daemon-gate-c111.md` §3.3, `bdpdrv.ko` `.text+0xa9ab0..0xa9ac0`). So:

* our `min(14, alloc)` clamp is **inert** — bytes 14..19 are never read by
  either consumer (`mmc3_profile` is stored and only ever compared against
  `0x12`/`0x1A` in `cdrom_is_dvd_rw`, `cdrom.c:869-877`);
* there is **no retry and no loop** in `cdrom_mmc3_profile` — one
  `generic_packet`, one parse, done;
* `ret` non-zero would set `0xffff` (not retry), and the run contains zero
  `SenseKey` prints, so every `0x46` completed GOOD — the completion path was
  never the problem in C112b.

**"Does the EIO come from `sr_do_ioctl`/sense/GET_PERFORMANCE?"** No —
`sr_do_ioctl` and `sr_read10`'s block path are never entered for these reads
(§2.2: zero CDBs, one `req-sense` for a different leg). `GET_PERFORMANCE` is
not issued anywhere in the run.

---

## 6. The one change that ends it

### 6.1 Why it cannot be an FE reply

`sdev->changed` is cleared only at `sr_media_change` `.text+0x173c` (bic #4),
reachable only when `.text+0x1650 bl sr_test_unit_ready` returns **0** — and
that function's return value is fabricated from `isFaMode | isBeQuiet` with no
CDB issued (`.text+0x1554`). **No post, offset, DRAM window or reply byte
influences it.** Every model row that the *kernel* would consult on this leg
already exists and already passes (GESN, GET CONFIG RT=0/RT=1, READ TOC, READ
CAPACITY, READ, REQ SENSE); the missing thing is a **driver flag**, not a reply.

### 6.2 The lever (VERIFIED reachable, one open assumption)

`isFaMode` is the dword at `*(*(ata_host->private_data + 0xc) + 0x208)` in
`sata_mt85xx_mod.ko`:

```
sata_mt85xx_get_FA_mode  .text+0x7680
  7690: ldr r2, [r0, #0xc]
  76c4: mov r0, r1                 ; __copy_to_user(to = user ptr)
  76c8: add r1, r2, #520           ; from = field + 0x208
  76d0: bl  __copy_to_user
```

and it has **exactly one writer in the whole module**: the ioctl setter
`MT85XX_IDE_SET_FA_MODE (0x8532)` → `sata_mt85xx_set_FA_mode` `.text+0x76ec`
(`__copy_from_user` into the same `+520`). `grep '#0x208\]'` over the full
`.text` disassembly finds **one** hit, the `ldr` in `data_xfer`
(`.text+0x55dc`, the FA INQUIRY branch) — there is **no store**. Same for
be-quiet: `MT85XX_IDE_SET_BE_QUIET (0x8534)` → `sata_mt85xx_set_seq_rd_mode`
`.text+0x7670` (`str r1,[r3,#0x218]`). Neither setter is called from anywhere
in the kernel tree (`grep -rn 'SET_FA_MODE\|SET_BE_QUIET' ~/sony-kernel/linux-2.6.35`
→ only the four `GET_*` reads in `sr.c:220/221/1012/1013` and the `#define`s),
so **both flags are only ever what a userspace ioctl last put there** — and the
guest can therefore zero them the same way.

That is Q-1 below: *who* set them in this rig is still unidentified (candidates:
a stale value in the channel struct our emulator never writes, or one of the
vendor modules — `bdpdrv.ko` carries the `0x8534` constant once, in a rodata
ioctl table). It does not block the fix: the read-back in step 0 names the
value, and the setter clears it.

### 6.3 Paste-ready fix (guest-side helper; style-matched to `sacd_gate_ioctl.c`)

A ~20-line helper — `sr_fa_mode` — staged next to `sacdgate`, used twice in the
gate script and once in the ladder:

```c
/* sr_fa_mode — read (and optionally clear) the two vendor flags sr_mod.ko's
 * sr_test_unit_ready() short-circuits on, so the block layer's buffered read of
 * /dev/sr0 stops being refused with -EIO (dd-eio-loop.md §3/§6).
 *
 * Why this is the lever and not a reply: sr_prep_fn (sr_mod.ko .text+0xfdc)
 * returns BLKPREP_KILL while sdev->changed is set, and `changed` is cleared only
 * by sr_media_change's success path (.text+0x1738), which needs
 * sr_test_unit_ready() == 0. That function fabricates 0x08000002 with NO CDB
 * whenever isFaMode|isBeQuiet is set (.text+0x1484/0x1490/0x1554), so the latch
 * never clears and no SCSI command is ever issued for a buffered read. The two
 * flags are plain dwords in the sata_mt85xx channel struct, written ONLY by the
 * 0x8532/0x8534 ioctls (sata_mt85xx_set_FA_mode .text+0x76ec / set_seq_rd_mode
 * .text+0x7670) — so userspace can read them back and zero them.
 *
 *   sr_fa_mode /dev/sr0            print both flags  (diagnostic)
 *   sr_fa_mode /dev/sr0 clear      write 0 to both, then print the read-back
 * Exit 0 on success; the printed line is the observable:
 *   FA_MODE fa=<v> rc=<n> be_quiet=<v> rc=<n>
 */
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <errno.h>

#define MT85XX_IDE_GET_FA_MODE  0x8531
#define MT85XX_IDE_SET_FA_MODE  0x8532
#define MT85XX_IDE_GET_BE_QUIET 0x8533
#define MT85XX_IDE_SET_BE_QUIET 0x8534

int main(int argc, char **argv)
{
    const char *dev = (argc > 1) ? argv[1] : "/dev/sr0";
    int clear = (argc > 2 && strcmp(argv[2], "clear") == 0);
    int fd, fa = -1, bq = -1, r1, r2, z = 0;

    /* O_RDONLY|O_NONBLOCK: the fast open path, so this never depends on media. */
    fd = open(dev, O_RDONLY | O_NONBLOCK);
    if (fd < 0) {
        printf("FA_MODE open failed %s errno=%d\n", dev, errno);
        return 1;
    }
    r1 = ioctl(fd, MT85XX_IDE_GET_FA_MODE, &fa);
    r2 = ioctl(fd, MT85XX_IDE_GET_BE_QUIET, &bq);
    if (clear) {
        (void)ioctl(fd, MT85XX_IDE_SET_FA_MODE, &z);
        (void)ioctl(fd, MT85XX_IDE_SET_BE_QUIET, &z);
        fa = bq = -1;
        r1 = ioctl(fd, MT85XX_IDE_GET_FA_MODE, &fa);
        r2 = ioctl(fd, MT85XX_IDE_GET_BE_QUIET, &bq);
    }
    printf("FA_MODE fa=%d rc=%d be_quiet=%d rc=%d\n", fa, r1, bq, r2);
    close(fd);
    return (fa == 0 && bq == 0) ? 0 : 2;
}
```

Wiring (guest side), inserted **after** `insmod sr_mod.ko` and **before** any
`dd` — gate 06's `count=0` dd is fine either way, the clears must precede
`LADDER a2` and gate 13:

```sh
/res/shim/sr_fa_mode /dev/sr0 clear       # 0x8532 + 0x8534 = 0, then read back
```

Nothing in `emulator-kit/player.local.c` changes. The follow-on traffic the
unlocked path generates is already modelled:

| after the clear | CDB | model row | status |
|---|---|---|---|
| `sr_media_change` clear path → `sr_test_unit_ready` | `00` TUR | `FE_PKT_NODATA` (bare success) | exists — and a bare success is exactly what the clear path needs (sense invalid ⇒ `0x165c` fast path) |
| `sr_cd_check()` (`sr_vendor.c:157`, VENDOR_SCSI3) | `43` READ TOC alloc 12 | `FE_PKT_READ_TOC` | exists; prints a new `[sr_cd_check]TOC buf:…` line — **use it as the "latch cleared" tell** |
| `get_sectorsize()` | `25` READ CAPACITY | `FE_PKT_READ_CAPACITY` (derived from the image: last LBA 1 064 207, block 2048) | exists |
| `dd`'s buffered read | `28` READ(10) via libata PACKET | `FE_PKT_READ` (descriptor DMA) | exists — same route the SG_IO ladder already proved |

### 6.4 Falsifiable next-fire prediction (C113)

Run C112b's command list with `sr_fa_mode /dev/sr0 clear` inserted after the
`sr_mod.ko` insmod. **Predicted, in this order:**

1. `FA_MODE fa=0 rc=0 be_quiet=0 rc=0` on both reads. *(If instead `rc=-1` /
   `-ENOTTY` / `-EFAULT`: the two vendor ioctls are unreachable from userspace
   on this guest — then §6.5 applies and the flags are uninitialised stack
   garbage in `sr.c`, not driver state.)*
2. Ladder leg (a) size probe: **`blkgetsize64=2179497984 blkssz=2048`**
   (`1 064 208 × 2048`), i.e. **changed** from `1073741312` / `512`. This alone
   proves `get_sectorsize()` ran, which proves the clear path executed.
3. A new uart line `[sr_cd_check]TOC buf:00 0a 01 01 00 14 01 00 00 00 02 00`
   (our READ TOC row, echoed by the Sony vendor function).
4. FE census gains, per blocking open: one `nbytes=8 -> read-capacity`, one
   extra `nbytes=0 -> no-data` (the TUR), one `read-toc`, and **one
   `-> read` FE READ line with `lba=16` for ladder a2** and
   `lba=510 nsec=10` for gate 13.
5. `LADDER a2 PASS dd LBA 16` and `GATE 13 PASS master-toc -- LBA 510 x10 =
   20480 B, first 8 bytes [53 41 43 44 4d 54 4f 43]`.
6. The daemon (launched after the gate) then reaches `DISC_OPEN`; its poll
   pairs stop being the trace's steady state and `GATE 14` becomes runnable
   (`AUTH` was 0 in C112b).

**Kill criterion (if it fails):** if (2) is still `1073741312 / 512` while (1)
printed `fa=0 be_quiet=0`, then the flags are not what sr reads — the next
suspect is that `scsi_ioctl()` in `sr.c:220` is failing on this guest and
`isFaMode`/`isBeQuiet` are **uninitialised stack locals** (`int isFaMode;`
`sr.c:213`), which no ioctl can fix; §6.5 then becomes the fix.

### 6.5 Fallback if the flags are unreachable (recorded, not recommended first)

If step 1 shows the ioctls failing, the latch is un-clearable from userspace and
`/dev/sr0` buffered reads are dead on this fork by construction. Then the gate
must stop testing a mechanism the drive stack refuses: re-base gate 13 (and
ladder a2) on the path the daemon can actually use on such a stack — SG_IO
`READ(10)` (the ladder's `read10` leg already byte-matches the oracle) or
`sacd_read` ioctl `0x40105303`. **That is a gate-design decision, not a decode
result** — flagged here so it is not re-derived if §6.4 item 1 comes back red.

---

## 7. Labels

| claim | label |
|---|---|
| the `-EIO` is `sr_prep_fn`'s `sdev->changed` test → `BLKPREP_KILL`, before any CDB | **VERIFIED** (`sr_mod.ko .text+0xfdc..0xfec`, `.text+0x1328`; `sr.c:425,440`; `scsi_device.h:115-120`) |
| three `dd` opens, three killed reads, zero READ packets from the block layer | **VERIFIED** (census §2.2/2.3; 11 `FE READ` lines all reconcile to ioctl legs) |
| `changed` is armed at probe and re-armed on every open | **VERIFIED** (`sr.c:837`; `.text+0x1680..0x168c`) |
| it can only be cleared when `sr_test_unit_ready() == 0`, which FA/be-quiet mode makes impossible | **VERIFIED** (`.text+0x1650`, `.text+0x1658`, `.text+0x1738`; `sr.c:284-305`; FA short circuit `daemon-gate-c111.md` §2.2) |
| the FA/be-quiet flags are non-zero in this rig | **VERIFIED** (`sr0: scsi-1 drive` at insmod + no MODE SENSE packet anywhere + no INQUIRY packet; closes `sr0-scan-seq.md` O-1) |
| capacity still `0x1fffff × 512` ⇒ `get_sectorsize()` never ran ⇒ clear path never ran | **VERIFIED** (ladder `blkgetsize64=1073741312`; zero `0x25` packets) |
| 2,037 TUR + 2,037 `0x46 RT=1 alloc 20` = the daemon's poll, not a retry | **VERIFIED** (CDB literal ownership, 2,036 `cache_avail_cnt`, daemon launch line after the gate, 3 open signatures) |
| the daemon's poll and the gate's `dd` share one root cause | **INFERRED** (daemon's master TOC read is the same `lseek64`+`read`, `daemon-ioctl-side.md` §2.4; its loop never logs a terminal failure) |
| `0x46` alloc-20 truncation is inert | **VERIFIED** (both readers read only bytes 6..7; `cdrom.c:864`) |
| the flags have no writer in the driver and no kernel caller | **VERIFIED** (one `ldr` to `+0x208`, zero stores; no `SET_*` callers in the tree) |
| clearing them fixes the rig | **the one open assumption** — paste-ready helper + falsifiable prediction (§6.4); Q-1 names which run closes it |
| who/what set the flags in C112b | **OPEN (Q-1)** — a stale channel-struct value the emulator never writes, or a vendor-module ioctl (`bdpdrv.ko` carries `0x8534` once in a rodata ioctl table) |

Open items, in the order they would bite:

1. **Q-1 (who set the flags).** One fire with `sr_fa_mode /dev/sr0` (read-only
   form) answers it: `fa`/`be_quiet` values, or an ioctl error → §6.5.
2. **`get_sectorsize()`'s ×4.** `sr.c:945-955` multiplies `cd->capacity` by 4
   for a 2048-byte sector size, then `blk_queue_logical_block_size(2048)`. The
   predicted `blkgetsize64=2179497984` depends on that branch; if the real disc
   size later disagrees, this is where to look (not a gate blocker).
3. **`0x51` READ DISC INFORMATION** is still unclassified. It is *not* on the
   unlocked path (`sr_cd_check`'s VENDOR_SCSI3 branch uses READ TOC `0x43`, not
   `0x51`); `0x51` is reached only from a real media-change notification.
4. **`sr_media_change` will still report `changed` to the block layer on every
   open** (it returns 1 when it re-arms) — harmless once the clear path runs
   first, but it means `check_disk_change()` invalidates buffers per open.

---

## 8. Reproduce

```sh
# §1 shipped binaries + sources (VM has the assembled rootfs and the Sony tree)
scp -o BatchMode=yes -P 2222 user@192.0.2.10:/tmp/rootfs/lib/modules/2.6.35/BDP/sr_mod.ko   /tmp/
scp -o BatchMode=yes -P 2222 user@192.0.2.10:/tmp/rootfs/lib/modules/2.6.35/BDP/cdrom.ko    /tmp/
scp -o BatchMode=yes -P 2222 user@192.0.2.10:/tmp/sata_mt85xx_mod.ko /tmp/
for f in drivers/scsi/sr.c drivers/scsi/sr_ioctl.c drivers/scsi/sr_vendor.c \
         drivers/cdrom/cdrom.c include/scsi/scsi_device.h; do
  scp -o BatchMode=yes -P 2222 user@192.0.2.10:~/sony-kernel/linux-2.6.35/$f /tmp/sony/
done

# §2.1 the kill test in sr_prep_fn
/opt/homebrew/opt/llvm/bin/llvm-objdump -dr --no-show-raw-insn --triple=armv6-linux-gnueabi \
    --start-address=0xfbc --stop-address=0xff0 /tmp/sr_mod.ko
/opt/homebrew/opt/llvm/bin/llvm-objdump -dr --no-show-raw-insn --triple=armv6-linux-gnueabi \
    --start-address=0x1328 --stop-address=0x1330 /tmp/sr_mod.ko
# §3.2 the setter and the unreachable clear
/opt/homebrew/opt/llvm/bin/llvm-objdump -dr --no-show-raw-insn --triple=armv6-linux-gnueabi \
    --start-address=0x164c --stop-address=0x1690 /tmp/sr_mod.ko
/opt/homebrew/opt/llvm/bin/llvm-objdump -dr --no-show-raw-insn --triple=armv6-linux-gnueabi \
    --start-address=0x1734 --stop-address=0x175c /tmp/sr_mod.ko
# §6.2 the only writer of the FA-mode dword
/opt/homebrew/opt/llvm/bin/llvm-objdump -dr --no-show-raw-insn --triple=armv6-linux-gnueabi \
    --start-address=0x7680 --stop-address=0x76e0 /tmp/sata_mt85xx_mod.ko
/opt/homebrew/opt/llvm/bin/llvm-objdump -d --no-show-raw-insn --triple=armv6-linux-gnueabi \
    /tmp/sata_mt85xx_mod.ko | grep '#0x208\]\|#520\]'      # one ldr, zero stores
# §5 the mmc3 parse (one packet, bytes 6..7)
grep -n 'cdrom_mmc3_profile' -A22 /tmp/sony/cdrom.c

# §4 the FE census and the daemon-poll reconciliation — VM side, multi-word
# commands go through vm-script (vm-exec's single-argument form cannot pipeline):
cat > /tmp/c112b-decode.sh <<'EOF'
grep -a -o 'FE PACKET w1=[0-9a-f]* w2=[0-9a-f]* w3=[0-9a-f]* nbytes=[0-9]* -> [a-z-]*' \
    /tmp/bdpdrv-runC112b.mmio.log | sort | uniq -c
grep -an 'FE PACKET' /tmp/bdpdrv-runC112b.mmio.log | sed 's/bx510: FE PACKET //' > /tmp/pkts.txt
head -1 /tmp/pkts.txt; sed -n '1,25p' /tmp/pkts.txt
grep -an 'FE READ' /tmp/bdpdrv-runC112b.mmio.log
grep -ac 'cache_avail_cnt'            /tmp/bdpdrv-runC112b.uart.log
grep -an 'sacd_extract_160 -S\|DAEMON_GATE_RC\|sr0: scsi-1' /tmp/bdpdrv-runC112b.uart.log
grep -ac 'Failed to copy to user'     /tmp/bdpdrv-runC112b.uart.log   # 0 = no -EFAULT from the 0x8531/0x8533
                                                                      #     __copy_to_user (does NOT prove the
                                                                      #     ioctls were dispatched — that is §6.4 item 1)
EOF
make vm-script SCRIPT=/tmp/c112b-decode.sh
```
