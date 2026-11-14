# The daemon's master-TOC read — why c122f served ZERO FE traffic, and the one-line scenario fix that makes it dispatch (c122g: CLIENT_PASS)

Date: 2026-11-14. Scope: the c122f failure (`libsacdread: Not a ScarletBook disc!`
+ `Can't read Master TOC.`, client `DISC_OPEN type=1 result=-1`, zero `FE READ`
lines in a 578 MB / 20.1 M-line MMIO trace) — the descriptor shape the model was
accused of missing, what actually blocked the read, and the fire that closed it.

**Result in one line: the model's descriptor dispatch was never reached, and it
was never wrong — the buffered READ died one layer ABOVE libata
(`sr_prep_fn` → `BLKPREP_KILL` while `sdev->changed` is latched), so not one
SCSI command was ever built. The missing artefact was the guest-side FA/be-quiet
clear (`sr_fa_mode /dev/sr0 clear`) that the passing ladder scenario runs and the
c122 daemon scenario did not. `emulator-kit/sony-bx510.c` is UNCHANGED.**
c122g with the clear inserted: client md5 `45ccd7dfbf433a79d28e877d7441677c`
(= the LBA-510×10 oracle) + `CLIENT_PASS` + `DISC_OPEN ok` + `DISC_SIZE ok
sectors=1064208`, and the FE served six descriptor DMAs.

Companions (not re-derived here): `dd-eio-loop.md` (§2/§6 — the `sdev->changed`
latch and the `sr_fa_mode` lever), `c97-read-path.md` (§5.1/§5.2 — the
`0x5c400` arm sequence), `fe-read-dma.md` (`bx510_fe_read`),
`master-toc-structure.md` (§4 the post-TOC read sequence, §5.1 the open
question this fire answers), `daemon-ioctl-side.md` (§1/§6 — the daemon's plain
`sacd_read_block_raw` path).

**House rules.** **VERIFIED** = a store/compare in a binary, a source line, or a
measured trace line, cited with its address/line. **INFERRED** = reasoned from
those, with the settling experiment named.

---

## 0. Bottom line

1. **The 0x5c400 descriptor group is never armed in c122f — not once, at any
   address.** `05c400`, `05c404`, `05c408` have **zero** accesses in the whole
   run (`grep -ac` = 0/0/0); `05c40c` is written **1959 times, always `0`** —
   that is `hw_chg_st`'s disarm (c97 §1.4), i.e. the model only ever saw the
   *not-armed* state. *VERIFIED (§1.1).*
2. **Not one READ-family CDB is ever posted.** The whole-run `W 05c004` (w1,
   whose byte 0 is the CDB opcode) census is `0x00`×1964, `0x46`×977, `0x4a`×2,
   `0x43`×2, `0x03`×1 — no `0x28`, no `0xa8`, no `0xbe`. `bx510_fe_read()` was
   therefore never entered, which is why `grep -ac 'FE READ'` is **0 including
   the refusal lines** (`no armed … descriptor`, `past EOF`, `unusable
   transfer`). *VERIFIED (§1.2).*
3. **The parent's hypothesis is falsified**: there is no "second descriptor
   shape" in the trace to match. The model's `bx510_fe_dispatch()` row-21 gate
   (`emulator-kit/sony-bx510.c:950`) would have fired on the very first READ
   post; no READ post exists. *VERIFIED (§1.3).*
4. **The read died in `sr_prep_fn`, above the driver, before a CDB existed.**
   The Sony `sr_mod.ko` returns `BLKPREP_KILL` while `sdev->changed` is set
   (`dd-eio-loop.md` §2, VERIFIED from `.text+0xfdc..0xfec`), and `changed` is
   only cleared when `sr_test_unit_ready()` succeeds — which the FA/be-quiet
   flags short-circuit **without issuing a CDB**. `BLKPREP_KILL` completes the
   request with `-EIO` and *no* device command, which is exactly a run with zero
   FE traffic. *VERIFIED (§2.1, inherited decode + §2.2 the c122f corroborating
   census: no `0x25`/`0x51`/`0x52` either, so `get_sectorsize()` never ran — the
   same latch is what keeps it from running).*
5. **The daemon then swallows the error.** `sacd_read_block_raw` (`0x2a264`)
   tests `ret != 0` for success, and `sacd_dev_input_read` propagates
   `read()`'s negative return (`0x21f58`/`0x21f70`) — so `-EIO` reads as
   "successful", the untouched `malloc(20480)` buffer (fresh anon pages =
   zeros) is parsed, the magic check fails, and the two stderr lines the brief
   saw are printed. *VERIFIED (§2.3).*
6. **The fix is guest wiring, not a model row** (§3): insert
   `/res/shim/sr_fa_mode /dev/sr0 clear` before the daemon launch — the same
   line `sr_read_ladder.sh:98-99` already runs, and the reason C113's
   block-layer `dd` passed while c122c/d/e/f did not. *VERIFIED by fire (§4).*
7. **The 40-sector area-TOC question is answered by the same fire**
   (`master-toc-structure.md` §5.1): the guest **does** split — the 40-sector
   read arrives as `nsec=32` (65 536 B) + `nsec=8` (16 384 B), so `FE_DMA_MAX`
   is never hit and no model change is needed for it. *VERIFIED (§4.2).*
8. **Bonus, unpredicted:** once the latch is clear the 2064-byte SACD channel
   runs end-to-end on the daemon's own path — `FE READ 28 lba=510 nsec=10
   len=20640 frame=2064` then `tz: svc 0x1e … len=2064` (identity decrypt) ×2 —
   and the client's file md5 still equals the plain oracle. *VERIFIED (§4.3).*

---

## 1. The c122f census: what the trace says was (not) there

Trace: VM `/tmp/bdpdrv-runc122f.mmio.log`, 20 155 358 lines, 578 142 274 B.
All counts below are whole-file (`grep -ac`), never sampled.

### 1.1 The descriptor group — armed zero times

```sh
L=/tmp/bdpdrv-runc122f.mmio.log
for r in 05c400 05c404 05c408 05c40c; do printf "%s: " $r; grep -ac ".. $r " $L; done
# 05c400: 0   05c404: 0   05c408: 0   05c40c: 1959
grep -a 'W 05c40c' $L | sed 's/.*= //' | sort -u        # -> 0   (only the disarm value)
```

The 1959 `05c40c = 0` writes are the driver's own disarm
(`hw_chg_st` 0x4420/0x4428, reached on any non-READ completion — c97 §1.4),
not an arm. An arm would be the seven-line group `W 05c40c=1; W 05c400=<phys>;
W 05c404=<len>; R/W 05c408=100; R/W 05c40c=601` (`c97-read-path.md` §5.1 rows
17-20); not one instance exists in c122f. The same group appears in c122g
(§4.1) — `W 05c40c` there is `0`×3927 / `1`×6 / `601`×6, i.e. **six** complete
arm/disarm cycles.

### 1.2 The mailbox posts — no READ CDB at all

```sh
grep -a 'W 05c000 sz4 = ' $L | sed 's/.*= //' | sort | uniq -c   # w0 census
#   1958 a0000000      (ATAPI PACKET posts)
#    984 00100000      (type-0x10 ACKs, _svoif_mt85xx_send_table_data_ack_cmd)
#      3 a1000000      (IDENTIFY PACKET)
#      1 ef000000      (SET FEATURES / xfermode)
grep -a 'W 05c004 sz4 = ' $L | sed 's/.*= //' | awk '{print substr($0,length($0)-1,2)}' | sort | uniq -c
#   1964 00   977 46   2 4a   2 43   1 03         (CDB[0] of every post)
```

Model classification agrees exactly — `grep -a 'FE PACKET' | sed 's/.*-> //' |
sort | uniq -c` on the same run: **977 no-data, 977 get-config, 2 read-toc,
2 gesn, 0 read, 0 req-sense, 0 read-capacity**. So the FE saw the daemon's
1 Hz poll (`_IDECLI_OddTestUnitReadyLoop` = TUR, `_IDECLI_OddGetProfile` = CDB
`46 01 …`, `dd-eio-loop.md` §4.2) and nothing else on the read side.

### 1.3 What the model WOULD have matched

The row-21 gate exists and is first in the dispatch:

```
emulator-kit/sony-bx510.c:950   if ((s->fe_dma[3] & 1u) != 0 && bx510_fe_post_is_read(s)) {
emulator-kit/sony-bx510.c:951       bx510_fe_read(s);     /* 422 */
```

`bx510_fe_post_is_read()` decodes `cdb[0]` from `w1` byte 0
(`bx510_fe_cdb()`, line 348) and accepts `0x28/0xa8/0xbe` (line 359). c122f
contained no such post, and the arm bit (`fe_dma[3] & 1`) was 0 on every
doorbell because `0x5c400..0x40c` were never written (§1.1). The gate did not
miss a shape — **there was no shape**: `data_xfer` (`0x5810..0x587c`), the only
code that arms it, never ran for a READ.

Corollary worth keeping: a run with a permanently-clear arm also cannot use
`bx510_fe_read()`'s own diagnostic path, so "no FE READ lines" is *ambiguous*
between "the model refused" and "the read never happened". The census in §1.1
is the discriminator; `FE READ` alone is not. (Every refusal in
`bx510_fe_read()` logs `FE READ …` too, by design.)

---

## 2. Where the read actually died

### 2.1 Mechanism (inherited, VERIFIED in `dd-eio-loop.md` §2/§6)

```
write(2)-side:  read(/dev/sr0, buf, 20480)
  -> block layer builds a REQ_TYPE_FS request
  -> sr_prep_fn (sr_mod.ko .text+0xfdc..0xfec)
         ldrb r2,[sdev+0x7c] ; and r2,#4        ; BIT 2 == sdev->changed
         bne  0x1328 -> mov r5,#1               ; BLKPREP_KILL
  -> blk layer completes the request with -EIO ; **no CDB is ever built**
```

`sdev->changed` is cleared only on `sr_media_change`'s success path, which needs
`sr_test_unit_ready() == 0`; Sony's fork fabricates `NOT_READY` from
`isFaMode | isBeQuiet` **without issuing a CDB** (`dd-eio-loop.md` §3). The two
flags live in the `sata_mt85xx` channel struct and are written only by the
`MT85XX_IDE_SET_FA_MODE (0x8532)` / `SET_BE_QUIET (0x8534)` ioctls — i.e. by
userspace (`/res/shim/sr_fa_mode`).

The c122f scenario ran no `sr_fa_mode` (VERIFIED: the guest command echoed into
the run's own transcript at `bdpdrv-runc122f.uart.log` L2050-2054 — `tar -xzf`,
`insmod bx510_cpsa_peer.ko`, `insmod sacd_read.ko`, `sacdgate 0x40105301`,
`sacdgate 0x40105305`, daemon, client — with no FA clear anywhere; the earlier
odd-tail stage only `insmod`s `sr_mod.ko`).
The ladder scenario does (`decode/sr_read_ladder.sh:98-99`):

```sh
if [ -x /res/shim/sr_fa_mode ]; then
  /res/shim/sr_fa_mode /dev/sr0 clear
```

That is the entire difference between C113/C121 (block-layer `dd` PASS, real
`FE READ`s) and c122c/d/e/f (zero FE traffic). The census is checked on the two
traces that survived log rotation: **c122f** (§1.1-§1.2) and **c122e**
(`FE READ`=0, `05c400`=0, `05c404`=0, `05c40c` nonzero=0, READ-CDB posts=0, of
1952 packet posts); c122c/c122d's traces were rotated off the VM by the c122g
fire, and their pulled uarts carry the same three failure lines
(`FAIL DISC_OPEN type=1 result=-1`, `CLIENT_RC=1`, missing
`/tmp/client-toc.bin`).

### 2.2 The corroborating census (independent of the decode)

If the latch was set, `sr_media_change` never reported success, so
`get_sectorsize()` (`sr.c:890`) never ran — and `get_sectorsize` is the only
issuer of READ CAPACITY `0x25` and of the `cdrom_get_last_written` pair
`0x51`/`0x52`. c122f has **none** of them (§1.2: `0x25`×0, `0x51`×0, `0x52`×0),
while c122g has `0x25`×1, `0x51`×2, `0x52`×2 and the daemon's own
`[IDE]<_sata_mt85xx_hw_chg_st>Disc MAX LBA=0x103d10` (= 1 064 208, the exact
fixture geometry). *VERIFIED.* This is the same latch seen from the other side.

### 2.3 Why the daemon printed "Not a ScarletBook disc!" instead of failing loudly

objdump of `original/sacd_extract_160` (deterministic, address-cited):

```
scarletbook_read_master_toc 0x2a25c
  0x2a25c  bl sacd_read_block_raw(sb->dev, 0x1FE, 10, buffer)
  0x2a264  cmp r3,#0 ; bne 0x2a274        ; ANY nonzero return == success
sacd_read_block_raw 0x2eb04
  0x2eb28  cmp [sb+4],#0 ; bne 0x2eb54    ; NULL fd -> 40-byte fwrite, ret 0
  0x2eb7c  blx r12                        ; *(0x59e14) = sacd_dev_input_read
sacd_dev_input_read 0x21eb4
  0x21f08  bl lseek64(fd, lba<<11, SEEK_SET) ; <0 -> ret 0
  0x21f58  bl read(fd, buf, len)             ; <0 -> ret that NEGATIVE value (0x21f70)
  0x21fe4  short-read path: return ceil(remaining/2048)
```

So `read() == -1` (EIO from `BLKPREP_KILL`) is returned upward as `-1`, which
`sacd_read_block_raw` reports as success, and `scarletbook_read_master_toc`
parses a buffer that was never written — `malloc(20480)` fresh anon pages are
zero, so `strncmp(buffer,"SACDMTOC",8)` fails at `0x2a2a4` → `Not a ScarletBook
disc!` → `Can't read Master TOC.`. *VERIFIED (instructions cited); the "zeros"
part is INFERRED from Linux's zero-filled fresh anon pages — the alternative
(heap reuse) would print the same two lines and needs no different fix.*

This is a genuinely useful negative for future stages: **a daemon-side read
failure is invisible at the daemon's own error handling**; the trace census, not
the daemon's stderr, is what names it.

---

## 3. The fix (scenario wiring; **no model change**)

Insert, after the modules are in place and before the daemon launch:

```sh
/res/shim/sr_fa_mode /dev/sr0 clear     # 0x8532 = 0, 0x8534 = 0
/res/shim/sr_fa_mode /dev/sr0           # read-back diagnostic: FA_MODE fa=0 rc=0 be_quiet=0 rc=0
```

Ordering constraints (all four are load-bearing):

1. **after** `insmod sr_mod.ko` — `sr_probe` re-arms `sdev->changed = 1`
   (`sr.c:837`), so a clear before the insmod is thrown away;
2. **before** any open that matters — the clear only takes effect on the *next*
   open, because `check_disk_change()` → `sr_media_change()` is what clears
   `changed` (the second `sr_fa_mode` invocation in §4 is both the read-back
   and that next open);
3. **before** the daemon's `-S` launch, so the daemon's own `/dev/sr0` open
   inherits a cleared latch;
4. repeat the clear in **every** fire — the latch is not persistent state of the
   emulator, it is a driver dword that the previous run's guest left at 1.

### 3.1 Why the model did not need to change

* The read shape the daemon finally produced is byte-for-byte the shape
  `c97-read-path.md` §5.1 rows 17-21 describe, and the model matched it on the
  first doorbell (§4.1). `bx510_fe_read()` served 20480 B at
  `0x1d8bc000` from `lba 510`, `nsec 10`, framing 2048 — no new accepted shape
  was needed, so **any additive "second shape" branch would have been dead code
  guarded by no evidence** (and a rewrite was never on the table).
* The two guards that matter (whole-frame, EOF, `phys+len <= RAM`) were not
  stressed by this fire and stay as they are.

A model change was the approved *plan*; the trace falsified its premise, and
fabricating a matching branch would have been ungrounded scope. Recorded as a
deliberate deviation, not a silent scope change.

### 3.2 Codified so the class cannot recur

`decode/daemon_gate.sh` gate 13 is the same block-layer `dd` at LBA 510, and it
had the same latent hole (C112b: `GATE 13 FAIL master-toc -- LBA 510 x10 = 0 B`).
A **gate 12b** block now runs `sr_fa_mode $SR0 clear` + a read-back invocation
between gate 12 and gate 13, guarded on the helper being executable and echoing a
loud line when it is absent — same helper, same order as
`sr_read_ladder.sh:98-99`. `sh -n` / `dash -n` clean; the two shellcheck
warnings in that file are the pre-existing deliberate `set -- $(ls -l …)`
splits (lines 173/444).

---

## 4. c122g — the fire that closed it

`make bx510-fire RUNID=c122g GCMD_FILE=/tmp/g-c122g.txt TIMEOUT=240`
(guest command = the c122f line + the two `sr_fa_mode` invocations + a
`grep sr0 /res/proc/partitions`; evidence pulled to
`bdpdrv-runc122g.{uart.log,meta.json,fire.txt}`; MMIO trace stays VM-side at
`/tmp/bdpdrv-runc122g.mmio.log`, 580 588 054 B / ~20.2 M lines).

### 4.1 The FE side (VERIFIED — `/tmp/bdpdrv-runc122g.mmio.log`)

```sh
grep -a 'FE READ' /tmp/bdpdrv-runc122g.mmio.log
bx510: FE READ 28 lba=510 nsec=10 len=20480 frame=2048 -> phys 1d8bc000 (descriptor DMA)
bx510: FE READ 28 lba=544 nsec=32 len=65536 frame=2048 -> phys 1d8bc000 (descriptor DMA)
bx510: FE READ 28 lba=576 nsec=8  len=16384 frame=2048 -> phys 06289000 (descriptor DMA)
bx510: FE READ 28 lba=353804 nsec=32 len=65536 frame=2048 -> phys 0628d000 (descriptor DMA)
bx510: FE READ 28 lba=353836 nsec=8  len=16384 frame=2048 -> phys 0629d000 (descriptor DMA)
bx510: FE READ 28 lba=510 nsec=10: 0x5c404=20640 means 2064 bytes per sector, not 2048 — taking the descriptor length
bx510: FE READ 28 lba=510 nsec=10 len=20640 frame=2064 -> phys 17748000 (descriptor DMA)
```

The arm group, first instance (lines 3768630-3768636) — exactly `c97-read-path.md`
§5.1's predicted ordering:

```
W 05c40c = 1          W 05c400 = 1d8bc000      W 05c404 = 5000   (20480)
R 05c408              W 05c408 = 100           R 05c40c          W 05c40c = 601
```

Post census for the run: CDB[0] = `0x00`×3917, `0x46`×972, `0x28`×6, `0x43`×5,
`0x51`×2, `0x52`×2, `0x25`×1, `0x03`×1, `0xf0`-family×9. Model
classification: 2929 no-data, 972 get-config, 5 read-toc, 2 track-info,
2 disc-info, 1 read-capacity, 9 unknown (= 3920 logged; the 6 READ posts go to
`bx510_fe_read()` and log `FE READ` instead), **0 refusals** — no `past EOF`,
no `unusable transfer`, no `no armed … descriptor`.

### 4.2 The 40-sector area read splits (answers `master-toc-structure.md` §5.1)

`lba=544 nsec=32` + `lba=576 nsec=8` = 40 sectors = 81 920 B in two qcs;
`lba=353804 nsec=32` + `lba=353836 nsec=8` likewise. The block layer / driver
split at 32 sectors, so `FE_DMA_MAX` was never approached and **no model bound
needed raising** — §5.1's option (3) "do nothing and confirm first" wins.

### 4.3 The guest side (VERIFIED — `bdpdrv-runc122g.uart.log`)

```
L2089  FA_MODE fa=0 rc=0 be_quiet=0 rc=0                         <- the clear
L2091  [sr_cd_check]TOC buf:000a0101 00140100 00000200            <- sr's own drive check
L2092  [sr_cd_check]ms_offset=0x0, xa_flag=0x0, sector_size=0x800  <- 2048-byte sectors
L2093  [IDE]<_sata_mt85xx_hw_chg_st>Disc MAX LBA=0x103d10          <- 1 064 208 sectors
L2168  DISC_OPEN ok
L2169  DISC_SIZE ok sectors=1064208
L2173  [OSAL_STUB] tz: svc 0x1e: opcode=0x80 src=0x17738000 … len=2064
L2174  [OSAL_STUB] tz: svc 0x1e: identity transform done (2064 bytes)
L2221  CLIENT_PASS
L2222  CLIENT_RC=0
L2223  45ccd7dfbf433a79d28e877d7441677c  /tmp/client-toc.bin
```

`45ccd7df…` is the LBA-510×10 oracle (`master-toc-structure.md` §7 step 1), and
the daemon's own output shows the parse went **past** the magic check into
`convert_string()` (`[0]: convert_string(): Conversion not supported. Charsets:
ISO646-JP -> UTF-8`) — i.e. sectors 1-8 (`SACDText`) were validated and the
text pipeline started. No `Not a ScarletBook disc!`, no `Can't read Master TOC.`,
no `Can't read Area TOC`, no `Not a valid Area TOC!`.

Fire-harness note: `probe incomplete: STUB_DONE marker never appeared` is
expected — the marker belongs to the staged `daemon_gate.sh` tail sequence,
which a custom `--guest-cmd` replaces. It is not a result signal.

---

## 5. Remaining gaps (labelled)

| # | item | label | settling experiment |
|---|---|---|---|
| 1 | nine `0xa0` posts classify as `FE_PKT_UNKNOWN` and get a **bare success** (`w1 = 0x0000b8f0`, then `w1 = 0x020050f0/0x030050f0 w2 = 0x000000f0 w3 = 0x00020000`, `nbytes` 20 720) — posted during the SACD leg after the TOC, answered with no data and no error, and the client still matched | **open** — needs a decode of bdpdrv's write-direction taskfile encoding; `c97-read-path.md` §2.2 says the write direction is software-side, so a bare success may be correct | fire a run that turns one into a *read* (`0x5c404` set + READ CDB) and watch for a refusal; or decode `data_xfer`'s non-`0x28/0xA8/0xBE` mailbox body |
| 2 | "the buffer was zeros" vs "the buffer was recycled heap" in c122f | INFERRED (zeros) | re-fire c122f's exact command with `sr_fa_mode` omitted and dump the daemon's buffer head — not worth a fire unless another silent-read failure appears |
| 3 | why the FA/be-quiet dwords are 1 at all on a cold boot (nobody in the kernel writes them) | **open** (`dd-eio-loop.md` Q-1, unchanged) | `sr_fa_mode /dev/sr0` *before* the clear in a fresh run — already printed `fa=0` after the clear only |
| 4 | the 2064-byte SACD framing's 12-byte header is still zeros (model "Level 0") and the decrypt is the TZ identity | INFERRED-acceptable (client md5 matches through `out+12` strip) | compare a decrypted frame against a CPSA-bearing disc image; out of scope here |
| 5 | `sr0: scsi-1 drive` still appears — `get_capabilities`' MODE SENSE fails before reaching the FE | open, harmless (C101's FA-mode fallback); capacity now comes from READ CAPACITY `0x25` in c122g | one fire with the `0x1a` MODE SENSE post traced end-to-end |

---

## 6. Reproduce

```sh
# 1. the census that falsifies the descriptor hypothesis (VM; trace stays there)
make vm-exec CMD='L=/tmp/bdpdrv-runc122f.mmio.log; \
  for r in 05c400 05c404 05c408 05c40c; do printf "%s: " $r; grep -ac ".. $r " $L; done; \
  grep -a "W 05c004 sz4 = " $L | sed "s/.*= //" | awk "{print substr(\$0,length(\$0)-1,2)}" | sort | uniq -c'

# 2. the daemon-side silent-success decode (Mac)
objdump -d --start-address=0x2a1fc --stop-address=0x2a2d0 original/sacd_extract_160
objdump -d --start-address=0x21eb4 --stop-address=0x22028 original/sacd_extract_160

# 3. the fix re-fired
make bx510-fire RUNID=c122g GCMD_FILE=/tmp/g-c122g.txt TIMEOUT=240

# 4. the verdict
grep -a 'FE READ\|CLIENT_PASS\|CLIENT_RC\|45ccd7df\|FA_MODE' \
  /tmp/bdpdrv-runc122g.mmio.log evidence/bx510-guest/bdpdrv/bdpdrv-runc122g.uart.log

# 5. the guest command that works (one line; /tmp/g-c122g.txt on the Mac)
#    c122f's line with this inserted after the insmod/sacdgate block:
#    /res/shim/sr_fa_mode /dev/sr0 clear; /res/shim/sr_fa_mode /dev/sr0;
```

Evidence state: `emulator-kit/sony-bx510.c` untouched; MMIO traces VM-side
(policy); uart/meta/fire outputs committed under
`evidence/bx510-guest/bdpdrv/bdpdrv-runc122g.*`.
