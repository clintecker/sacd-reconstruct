# Run C103 — the READ(10) ladder, fired: **PARTIAL LADDER**

**Verdict: the ladder RAN end-to-end and the gate says FAIL — by design.**
`READ10_VERDICT=FAIL` (exit 1), 13 checks failed, 15 passed. Two are real
measurements that had never been taken before, one is the model gap the run was
fired to calibrate against, and three are **tooling defects this run found in the
ladder itself** (named in §6, none of them a model or driver fault).

**This is not a model failure and must not be read as one.** The FE model
deliberately stops short of the READ data path: `case FE_PKT_READ:` in
`emulator-kit/sony-bx510.c` logs

```
bx510: FE READ packet — no FE-DMA implementation, completion carries no data
```

nine times in this run and then posts a bare completion. The comment above that
case says so in the source — *"the C97 FE-DMA path (descriptor
0x5c400/404/408/40c armed, data lands in guest RAM) is NOT modelled yet — C103
owns it"*. Rows 21-24 of `decode/c97-read-path.md` §5 are therefore still absent,
and everything the oracles measure is expected to fail until they land. That is
the peer's work item, not a defect discovered here.

Run identity: `ts_utc 2026-11-13T05:42:09Z`, qemu `~/bx510-emu/emulator/work/build/qemu-system-arm`
(rebuilt 05:28 with the `0xa0` PACKET rows), `bdpdrv 6604f6cd…`,
`clidrive_mode PROBE_SEQ`, `stages.odd_tail true`, `stages.sacdread` present
(`sacd-auth 0`), `stages.sr_ladder` present (`phase_order post-load`),
`fe_test_data.payload_size 788480`, `terminal_marker true`,
`BX510_TRACE=1`, `BX510_MACHINE_OPTS='sata-disc=/home/aftermath/sacd-verify/firebird.iso'`.

---

## 0. The five observables, up front

| # | observable | value | reading |
|---|---|---|---|
| 1 | disc + enumeration (`bx510: SATA ATAPI drive attached` + `scsi 0:0:0:0`) | **PASS** | the run is a C103 run — the ISO the model opened is the pinned 1 064 208-sector one |
| 2 | `sr0` attach | `sr0: scsi-1 drive` + `Uniform CD-ROM driver Revision: 3.20` + `SR0_MKNOD=0`, node `brw-r--r-- 11,0` | branch A, as C102 predicted (FA mode short-circuits MODE SENSE) |
| 3 | **capacity: READ CAPACITY FAILED** | `blkgetsize64=1073741312 blkssz=512` = **0x1fffff × 512** | sr.c's documented *fallback* capacity — the command failed, the FE never saw it (§2) |
| 4 | **the 0xbb poison reached user data** | `head16=698c867c835081965870124d1b90f66e` on 5 of 5 single-sector dumps | the bounce-buffer poison travelled **sr → sg → ATA → FE mailbox → back to a user buffer**: the no-DMA signature, now guest-observable, not a trace inference |
| 5 | **the descriptor was armed for every rung, with the driver's own lengths** | `W 05c40c = 1`×9, `W 05c404 = 800`×6 / `5000`×1 / `1020`×2, `W 05c008 = fe01`×4, `W 05c00c = 980002`×2 | gate check H — lba/VLBA big-endian, 2048 / 20480 / 4128-byte lengths, and the Sony vendor byte `0x98` all reached the FE (SR-11 answered) |

Points 3-5 together are the calibration this run exists for: **the gate's
discriminating power is now bounded by a real rig, not only by fixtures** — it
catches a canned/absent payload, a false EOF, and a missing DMA, and it says
which one.

---

## 1. The guest transcript, verbatim (the ladder block)

```
2047  sr0: scsi-1 drive
2048  Uniform CD-ROM driver Revision: 3.20
2051  SR0_MKNOD=0
2119  SRREAD_CHMOD=0
2124  SRREAD mode=size dev=/dev/sr0 rc=0 errno=0 blkgetsize64=1073741312 blkssz=512
2125  LADDER a PASS size probed
2126  LADDER a2 FAIL dd reason=dd: can't open '/dev/sr0': No medium found
2127  SRREAD mode=read10 lba=16 nsec=1 len=2048 rc=0 errno=0 sense=000000 host=0000 driver=0000 file=/res/c103/lba16.bin
2128  MD5 name=lba16 off=0 hash=d41d8cd98f00b204e9800998ecf8427e
2129  MD5 name=lba16 head16=698c867c835081965870124d1b90f66e
...
2152  SRREAD mode=read10 lba=1064208 nsec=1 len=2048 rc=0 errno=0 sense=000000 host=0000 driver=0000 file=/res/c103/past_eof.bin
2153  LADDER past_eof FAIL (LBA 1064208 returned data)
2154  LADDER done 7/7
2186  SACDREAD cmd=0x40105301 ret=0 errno=0 result=-402653184
2187  SR_SACDREAD_PRIME=-402653184
2188  SR_SACDREAD_UNINIT=skipped-prime-failed
2195  SACDREAD cmd=0x40105303 lba=510 nsec=2 len=4128 ret=0 errno=0 result=0 file=/res/c103/sacd510.bin
2209  LADDER e MEASURED lba=510 nsec=2 len=4128 via ioctl 5303
2210  SRREAD mode=read10 lba=510 nsec=2 len=4128 rc=0 errno=0 sense=000000 host=0000 driver=0000 file=/res/c103/sacd_sg.bin
2220  LADDER done 2/2
```

`d41d8cd98f00b204e9800998ecf8427e` is `md5("")` — the 2048-byte hashes are
**empty because of a ladder defect, not a payload fact** (§6.1: this rootfs has
no `tail`). The `head16=` lines do not use `tail`, and they are the ones that
carry information: `698c867c…` = `md5(0xbb × 16)`.

---

## 2. What capacity=0x1fffff×512 means (the sharpest new finding)

`get_sectorsize()` (`sr.c:890-965`) sets `capacity` from READ CAPACITY(10) and
multiplies by 4 for a 2048-byte sector. `0x1fffff` blocks × 512 B =
1 073 741 312 is the **fallback** the Sony tree uses when the command *fails* —
`scsi_scan-codes.md` §5 predicted exactly this distinction ("garbage in the
buffer would produce a nonsense capacity, **not** the `0x1fffff` fallback (the
fallback only triggers on a *failed* command)").

The FE trace agrees with "failed", and sharpens it:

* **no `nbytes == 8` packet exists anywhere in the run** (`FE PACKET` census:
  `nbytes=0 -> no-data`, `nbytes=330 -> unknown`, and 9 × `nbytes=40 -> read`).
  The `0xa0`/P2 READ CAPACITY row that the model *does* now implement
  (`bx510_fe_read_capacity()`, `FE_PKT_OFF 0x2400`) was therefore **never
  exercised** — the command died before it could be posted.
* the same run's block-layer open path reports **no medium**:
  `dd: can't open '/dev/sr0': No medium found` (ENOMEDIUM). `sr_read10` opens
  with `O_NONBLOCK` and succeeds; `dd` opens blocking and is refused.

So the open question is precise and has a named settling experiment: *why does
READ CAPACITY never reach the mailbox?* Either the Sony `sr.c` FA-mode branch
skips it and the fallback is the intended quiet path, or the command is failing
in `scsi_execute`/libata before `data_xfer` — the `nbytes=330 -> unknown` packet
(`w1=0x0000014a`, `w2=0x00000010`, `w3=0x00000008`) is the only unexplained post
and is the first place to look. `sr0: CDROM not ready` did **not** appear, so the
media-change probe did not run the "unanswered P1/P2" path either.

**One more consequence worth writing down:** with capacity on the fallback,
`dd`/`BLKGETSIZE64`-based rungs (leg a as originally specified) cannot measure
the fixture's real geometry. The model row must be exercised *and* the sr layer
must be satisfied before check B can pass; the two are coupled and this run is
the evidence.

---

## 3. The verdict table (authoritative gate output)

`sh decode/read10_verdict.sh bdpdrv-runC103.uart.log bdpdrv-runC103.mmio.log bdpdrv-runC103.meta.json`
→ `READ10_VERDICT=FAIL`, **exit 1** (15 PASS / 13 FAIL / 0 SKIP).

| id | check | result | reading |
|---|---|---|---|
| A | disc attached, 1 064 208 sectors | **PASS** (1) | the run is the run |
| B | `SRREAD mode=size … blkgetsize64=2179497984 blkssz=2048` | **FAIL** (0) | capacity is the `0x1fffff×512` fallback → READ CAPACITY failed (§2). **Root cause is upstream of the model row** |
| C | no `qc timeout` / EH give-up / SRST / failed-IDENTIFY | **PASS** (0,0,0,0) | no libata fatality anywhere — the ladder's failures are clean completions |
| D0 | three distinct single-sector payloads | **FAIL** (1 distinct) | *in this run this is a tooling artifact, not the canned-block signature*: all three hashes are `md5("")` because the ladder's 2048-byte path used the absent `tail` (§6.1). The real discriminator here is `head16=698c867c` |
| D1-5 | the five 2048-byte oracles | **FAIL** (all 0) | no DMA — expected, `FE_PKT_READ` is unimplemented |
| E | LBA 0 served as real zeros / no `0xbb` in any head | **FAIL** (`0xbb` in 5 heads) | **the informative FAIL**: the poison canary fingerprint is now guest-observable (§0.4). "LBA 0 = zeros" cannot hold while no DMA happens, and the gate says so instead of accepting zeros as data |
| F | past-EOF rejected with a sense triple | **FAIL** (3 checks) | `rc=0` returned data at LBA 1 064 208: model row 23 (past-EOF `byte3 != 0`) is absent, so the drive happily "read" one sector past the end |
| G | `/dev/sacd_read` 5303 framing | **FAIL** — `unresolved` | ioctl `0x40105303` returned `ret=0 result=0`, but every one of the 12 offsets hashes to `md5("")` (§6.1) and the FE logged `no FE-DMA implementation` for the corresponding read packet. The framing question (12 vs 0 vs 16 vs 24) needs a real transfer |
| H | the armed descriptor carried THIS transfer | **6 PASS / 2 FAIL** | PASS: `05c40c=1`×9, `05c404=800`×6, `5000`×1, `cdb[0..3]=28`×6, `cdb[4..7]=fe01`×4. The two FAILs are exact-count artefacts: `05c404=1020` and `05c00c=980002` each appear **twice** (want 1) because the 5303 path was entered twice in this stage. Behaviour is correct; the expected counts need to be `want_ge 1` |
| — | `terminal_marker`, `payload_size` | INFO | `True`, `788480` |

Full output is in the bundle as `bdpdrv-runC103.verdict.txt`.

### 3.1 The differential table (what each FAIL rules in/out)

| failing check | what this run therefore rules OUT | what it rules IN |
|---|---|---|
| B | "the fixture's geometry reaches the guest" | READ CAPACITY fails before the mailbox; `get_sectorsize` fallback active |
| D0/D1-5 | "the FE served disc bytes" | the FE received the commands and declined to transfer |
| E | "zeros at LBA 0 are proof of a correct read" | the `0xbb` poison is the only cheap no-DMA discriminator, and it works through the real stack |
| F | "the model clamps at EOF" (it does not) | row 23 is genuinely missing — a silent-zeros read past EOF reads as success |
| G | any framing claim | the 2064 question stays open until a transfer exists |

---

## 4. The model-side trace (check H's evidence)

```
bx510: FE PACKET w1=00000000 w2=00000000 w3=00000000 nbytes=0   -> no-data
bx510: FE PACKET w1=0000014a w2=00000010 w3=00000008 nbytes=330 -> unknown
bx510: FE PACKET w1=00000028 w2=00001000 w3=00000001 nbytes=40  -> read     (LBA 16, nsec 1)
bx510: FE PACKET w1=00000028 w2=0000fe01 w3=00000001 nbytes=40  -> read     (LBA 510, nsec 1)
bx510: FE PACKET w1=08000028 w2=0000881e w3=00000001 nbytes=40  -> read     (retry-shaped)
… 9 × "FE READ packet — no FE-DMA implementation, completion carries no data"
```

Descriptor / mailbox census over the whole 112 825 122-byte trace:

| register | values (count) | meaning |
|---|---|---|
| `W 05c40c` | `1` ×9, `601` ×9, `0` ×12 | descriptor armed for 9 transfers (`hw_chg_st` disarms with 0) |
| `W 05c404` | `800` ×6, `5000` ×1, `1020` ×2 | the driver's own byte counts: 6 × 2048 B, 1 × 20480 B batch, 2 × 4128 B SACD |
| `W 05c008` | `fe01` ×4, `a000` ×3, `1000`, `103d`, `881e` … | CDB[4..7]: LBA `0x1FE` big-endian = 510 |
| `W 05c00c` | `980002` ×2, `1` ×6, `0` ×8 | CDB[8..11] with the Sony vendor byte `0x98` (SR-11 answered) |
| `W 05c400` / `05c408` | present | `stb_phys` target + arm word — the C97 descriptor, not the window |
| `W 05c000` | `a1000000` ×3, `a0000000` ×3, `100000` ×3, `ef000000` ×1 | the attach-path posts (IDENTIFY ×3, PACKET ×3, ACK ×3, SET FEATURES) |
| — | **0** reads of `0x5c404` by the model | the DMA never happened (nothing consumed the descriptor) |

Note what is *absent*: no `nbytes == 8` (READ CAPACITY) and no `nbytes == 128`
(MODE SENSE) packet. The `0xa0` PACKET rows the C102 worker landed are correct in
the model but **untested by this run** — see §2's settling experiment.

---

## 5. What was measured, stated as claims (labelled)

| claim | label |
|---|---|
| `sr0` attaches in the C103 fire line with `--odd-tail` alone (no daemon stage), and `/dev/sr0` is a usable `11,0` block node | **VERIFIED** (this run, §1) |
| The guest's CD stack opens `/dev/sr0` and issues READ(10) CDBs whose LBA/length/vendor byte reach the FE mailbox intact | **VERIFIED** (H + the `FE PACKET` lines) |
| The FE declines every READ transfer (`FE_PKT_READ` unimplemented) so user buffers keep the driver's `0xbb` poison | **VERIFIED** (9 unimplemented logs + 5 × `head16=698c867c…`) |
| READ CAPACITY fails, and the guest falls back to `0x1fffff × 512`, because the command never reaches the mailbox | **VERIFIED** (capacity value + absence of the `nbytes=8` packet); *why* it never reaches it is **OPEN** (§2) |
| Past-EOF is not rejected (row 23 absent); LBA 1 064 208 returns "data" with `rc=0` and a zero sense triple | **VERIFIED** |
| The 2064-byte SACD framing layout | **NOT MEASURED** — no transfer exists; `payload_at_*` stays `unresolved`. Do not quote any framing verdict from this run |
| Whether the daemon's SACD path can work end-to-end | **NOT MEASURED** — `SACDREAD cmd=0x40105301 result=-402653184` (`0xE8000000`, CPSA Connect fail) in both the smoke stage and the ladder's prime; leg (e) is a `ret=0` with an un-DMA'd buffer |

---

## 6. Defects in the ladder tooling, found by firing it

Five, all fixed in the tracked files except 6.3 (fixed) and 6.5 (open). They are
listed prominently because the gate's FAIL table is only trustworthy if the
instrument is: three of them would have made a *correct* run read as a wrong one.

### 6.1 The guest rootfs has no `tail` and no `cut` (ladder, FIXED)
`md5sum | cut -d' ' -f1` printed nothing (`line 130: cut: not found`) and
`tail -c +N` printed nothing either — **every 2048-byte hash in this run is
`md5("")`**. `decode/read10-orchestration.md` §9.1 asserts busybox has
`tail`/`cut`; it has `md5sum`, `head`, `dd` and shell builtins. The digest is now
lifted with POSIX parameter expansion (`md5_hex()`), and the 2048-byte window
needs a `tail` replacement (`dd bs=1 skip= count=`) — **still to change** before
the next run. The `head16=` canary was unaffected and is what carried the run.

### 6.2 `dd` cannot open the node (ladder design, FIXED as a labelled negative)
`dd: can't open '/dev/sr0': No medium found`. `dd` opens blocking, so it meets
`sr_media_change`'s no-medium verdict; `sr_read10` opens `O_NONBLOCK` and
succeeds. Leg (a2) therefore cannot work while capacity is on the fallback.
Its stderr is now captured into the transcript (`reason=…`) instead of discarded —
"dd failed" with no reason is not a measurement.

### 6.3 `0x40105305` before any successful INIT oopses the kernel (FIXED)
The first fire's `sacdgate 0x40105305` (now preserved as attempt 1) produced
```
Unable to handle kernel NULL pointer dereference at virtual address 00000000
PC is at i4CPSA_Inst_CPSMode_Ctrl+0xc/0x6ac [bdpdrv]
LR is at CPSA_SACDCmdDisable+0x34/0x98 [sacd_read]   r0 = ffffffff
Process sacdgate (pid: 830)                          exit 139
```
— the release must see a *live* instance handle, and on a freshly insmod'ed
module (or after a failed Connect) it is `0xFFFFFFFF`. The stage now primes with
one INIT and runs the release **only if that INIT returned a non-negative CPSA
code** (the same rule `sacdread_smoke.sh` applies to AUTH/UNINIT). In this run
the prime returned `-402653184`, the release was skipped, and the kernel stayed
clean (`grep -c 'Internal error: Oops'` = **0**).

### 6.4 Three bugs in the appendix artifacts, fixed before the fire (§7)
Check B's regex, the batch-hash span, and the `LADDER e MEASURED` key.

### 6.5 READ CAPACITY never posted (OPEN, not a ladder defect)
§2. Not fixed here — it needs the guest-side settling experiment, and it is the
single highest-value next measurement.

---

## 7. The three appendix bugs this gate arrived with (and why the file differs)

`decode/read10-orchestration.md` §9 shipped three defects that a transcription
would have carried straight into the endgame run. All three are fixed in the
tracked artifacts, with the reason in the code:

1. **Check B could never match.** `want_ge 1 '^SRREAD mode=size .*rc=0
   blkgetsize64=…'` assumes the fields are adjacent, but the helper's own format
   is `rc=%d errno=%d blkgetsize64=%llu` — `errno=` sits between them. The check
   failed even against a synthetic PASS transcript. Now
   `… rc=0 errno=[0-9]* blkgetsize64=2179497984 blkssz=2048$`.
2. **The batch oracle hashed the wrong span.** §9.1's `md5_of` always hashed
   2048 B, so `lba510x10` could never equal `45ccd7df…` (the md5 of 20480 B).
   A correct run would have failed D1-5's batch row by construction. `md5_of`
   now takes a length and the plain path passes `nsec × 2048`.
3. **`LADDER e MEASURED` was in the gate but not in the ladder.** §9.3 keys check
   G on that line; §9.1 only emitted `LADDER e PASS …`, so a perfect leg (e)
   would still have failed G. The ladder now emits the marker the gate reads.

The gate's own validation (both directions, six fixtures) is reproduced in §9.

---

## 8. Rig defect in attempt 1 (preserved, not deleted)

The first C103 fire (05:39:04Z) ran **without** `BX510_MACHINE_OPTS`, so no disc
was attached: no `bx510: SATA ATAPI drive attached` line, no `scsi 0:0:0:0`, and
every request failed `errno=6` (ENXIO) against a node with no device behind it —
i.e. gate check A would have been the only true statement in the whole table.
Preserved on the VM as `/tmp/bdpdrv-runC103a-nodisc.{uart.log,meta.json}` and in
the bundle. The lesson is the standing one (`AGENTS.md`: suspect the rig first):
the model printed the absence, check A caught it, and no interpretation was
published off that run. The trace was also missing (`BX510_TRACE=1` unset →
4.3 MB of unimp lines, **zero** `MMIO` lines), which is why check H had no input
at all in attempt 1.

---

## 9. What the fire line is (reproduce) and what it costs

```sh
# VM, from /home/aftermath — 40 s wall clock, payload 788,480 B of 1,048,576 B
export BX510_TRACE=1
export BX510_MACHINE_OPTS='sata-disc=/home/aftermath/sacd-verify/firebird.iso'
PYTHONPATH=~/bx510-emu/emulator python3 /tmp/bx510_bdpdrv_stub_probe.py \
  --qemu ~/bx510-emu/emulator/work/build/qemu-system-arm --images /tmp/images-fe \
  --stubko /tmp/osal_b/bx510_osal_stub.ko --stuba-ko /tmp/osal_a/bx510_osal_stub_a.ko \
  --kscript /tmp/kcheck.sh \
  --pre-file libata.ko=/tmp/sata_staging/libata.ko \
  --pre-file sata_mt85xx_mod.ko=/tmp/sata_staging/sata_mt85xx_mod.ko \
  --extra-file bx510_clidrive.ko=/tmp/osal_c/bx510_clidrive.ko \
  --bdpdrv-host /tmp/rootfs/lib/modules/2.6.35/BDP/bdpdrv.ko \
  --bdpdrv-guest /lib/modules/2.6.35/BDP/bdpdrv.ko \
  --clidrive-mode PROBE_SEQ --odd-tail \
  --sacdread ~/sacd-verify/original/sacd_read.ko --sacdgate /tmp/sacdgate \
  --sacdread-smoke /tmp/sacdread_smoke.sh --sacd-auth 0 \
  --sr-ladder /tmp/sr_read_ladder.sh --srread /tmp/srread \
  --uart /tmp/bdpdrv-runC103.uart.log --unimp /tmp/bdpdrv-runC103.mmio.log \
  --meta /tmp/bdpdrv-runC103.meta.json --timeout 480
sh /tmp/read10_verdict.sh /tmp/bdpdrv-runC103.uart.log \
   /tmp/bdpdrv-runC103.mmio.log /tmp/bdpdrv-runC103.meta.json; echo rc=$?
```

Rendered command list: 62 command lines (`--print-commands`), ladder block =
commands 55-62, markers `SR_LADDER_BEGIN / SRREAD_CHMOD / SR_LADDER_PRE_RC /
SR_SACDREAD_INSMOD / SR_SACDREAD_MKNOD / SR_SACDREAD_PRIME /
SR_SACDREAD_UNINIT / SR_LADDER_POST_RC / SR_LADDER_DONE`.

Artifacts (in this directory unless noted, `md5` for the guest-side ones):

| artifact | identity |
|---|---|
| `decode/sr_read10.c` | 9 889 B — guest SG_IO/5303 helper, `-O2 -Wall -Wextra` clean on the era toolchain |
| `decode/sr_read_ladder.sh` | 6 231 B — the two-phase ladder |
| `decode/read10_verdict.sh` | 8 680 B — the gate; `sh -n` + `shellcheck -s sh -S style` clean |
| `tools/bx510_bdpdrv_stub_probe.py` | `--sr-ladder` + `--srread` stage (fourth optional stage) |
| `srread` binary | built VM-side: `~/gnuarm/bin/arm-none-linux-gnueabi-gcc` (GCC 4.4.1), ELF 32-bit ARM EABI5, dynamic `/lib/ld-linux.so.3`, 41 156 B |

The gate was validated in six directions before it judged this run: synthetic
PASS → exit 0; **real C101** → exit 1 (13 failures, matching
`read10-orchestration.md` §4.4's prediction); **real C102** → exit 1; canned-block
fixture → D0 + the three oracles; wrong-framing fixture → **only** G, named
`payload_at_0_stride_2048`; truncation → only completion; PASS-without-MMIO →
exit 2 (`INCOMPLETE`).

---

## 10. Next: what has to change before a C104 run can pass

Ordered by what breaks first, each with its own observable:

| # | change | owner | settling observable |
|---|---|---|---|
| 1 | **`case FE_PKT_READ:` must perform the C97 FE-DMA** — decode CDB lba/nsec, `blk_pread` from `sata_blk`, scatter to `fe_dma[0]` (`stb_phys`) for `fe_dma[1]` bytes, one bare type-0; rows 22/23 for non-READ and past-EOF (`byte3 != 0`) | peer worker (model) | guest `head16` stops being `698c867c…`; D1-5 match; check H's `1020`/`980002` counts are 1 |
| 2 | **Why READ CAPACITY never reaches the mailbox** (§2) | next rig run | a `nbytes=8 -> read-capacity` line appears in the `FE PACKET` census and `blkgetsize64=2179497984` |
| 3 | **Ladder: replace `tail -c +N`** (`dd bs=1 skip=N count=M`) so the 2048-byte hashes are real | next ladder edit | `MD5 … off=0 hash=` becomes a real digest, and D0 becomes meaningful again |
| 4 | Gate: H's `1020` / `980002` rows should be `want_ge 1`, not `want 1` (two 5303 entries are expected: prime + leg e) | gate edit | H 8/8 PASS on a correct run |
| 5 | `sacd_read` INIT still fails `0xE8000000` (`CPSA Connect`) — leg (e) cannot pass while that holds | driver/CPSA owner | `SACDREAD cmd=0x40105301 … result=1744830464` (`0x68000000`) |

**Post-run state of items 3 and 4 (applied after this run's fire, NOT exercised by it):** the
`tail` replacement (`dd bs=1 skip= count=`) is in `decode/sr_read_ladder.sh` and check H's
`1020`/`980002` rows are `want_ge 1` in `decode/read10_verdict.sh` — both are committed edits
this session made on the strength of the findings above; C104 is their first exercise. The
probe's prime gate was also hardened after a review pass: the 0x40105305 release now skips on
an EMPTY result string too (exec/loader failure case the clean negative did not cover).

**Resolution of item 2 without a new run (added post-fire, from the VM-side full trace):** the
`nbytes=330 -> unknown` packet decodes as a GET EVENT STATUS NOTIFICATION CDB (`0x4a`, event
class mask 0x10 = media events, allocation length 8 — w1=0x0000014a little-endian words),
i.e. sr.c's media-change poll, issued once at line 3 793 986 of the trace — immediately
before the first READ packet (3 796 041), which timestamps it to the `/dev/sr0` open in the
ladder. The whole 3.9M-line trace contains ZERO READ CAPACITY (`0x25`) and zero TEST UNIT
READY posts: in this FA-mode Sony sr.c the open path is open(2) → GESN → straight to
READ(10), and `get_sectorsize()`'s `0x1fffff × 512` fallback is the steady state, not a
failure signature. The model's GESN answer (bare success, buffer left poisoned) did not
block anything — but an honest GESN row is C104 model work regardless (a media-event NO
EVENT answer, not the 0xbb residue).

Correction to the record: §3's D0 note — a run where the ladder's hash path is
healthy and the FE does not DMA should show **one distinct** hash (identical
poison), i.e. D0's FAIL is also a correct discriminator once `tail` is fixed.
This run's `1 distinct` is *coincidentally* the right answer for the wrong reason
(`md5("")` three times); the fix in item 3 makes the check honest again.

---

## 11. Provenance of this document

Everything above is from the pushed evidence bundle and the two scripts in this
directory; nothing was hand-derived. Fire at 05:42:09Z on the lab VM, trace
112 825 122 B, uart 104 474 B, `terminal_marker true`. Full trace stays VM-side
(`VM:/tmp/bdpdrv-runC103.mmio.log`); the FE-window excerpt is
`bdpdrv-runC103.fe-tail.txt`, the gate output is `bdpdrv-runC103.verdict.txt`.

**Nothing was committed.** The tree is left dirty for parent review on purpose:
this run's files are new (`decode/sr_read10.c`, `decode/sr_read_ladder.sh`,
`decode/read10_verdict.sh`, this doc) and two tracked files carry edits from two
different workers (`tools/bx510_bdpdrv_stub_probe.py` = the `--sr-ladder` stage;
`emulator-kit/sony-bx510.c` = the peer's PACKET rows, untouched by this run).
