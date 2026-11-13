# Run C104 — the READ(10) ladder with the data path live: **THE DISC READS.**

**Verdict: every data check the gate has PASSES. The five plain-read oracles
byte-match the fixture ISO, LBA 0 arrives as true zeros, the 0xbb poison is
gone from every head, past-EOF is rejected with a sense triple, and the only
FAIL is the framing verdict — `unresolved` by design, because the 2064-byte
SACD layout still has no ground truth to accept against.** This is the run the
whole C-ladder was built toward: for the first time, real Firebird disc bytes
cross the FE descriptor into a guest user buffer.

Run identity: `ts_utc 2026-11-13T16:29:11Z`, QEMU rebuilt 16:28 from the
tracked kit state (FE-DMA + GESN row), `bdpdrv 6604f6cd…` unchanged,
`clidrive_mode PROBE_SEQ`, `stages.odd_tail true`, `stages.sacdread` present
(`sacd-auth 0`), `stages.sr_ladder` present with the FIXED ladder
(`sr_read_ladder.sh` sha256 `6e7f04c7…`, 6 375 B — the `dd bs=1` hash window,
not the C103 `tail` one), `fe_test_data.payload_size 788480`,
`terminal_marker true`, `BX510_TRACE=1`,
`BX510_MACHINE_OPTS='sata-disc=/home/aftermath/sacd-verify/firebird.iso'`.
Full trace stays VM-side (`VM:/tmp/bdpdrv-runC104.mmio.log`); the FE excerpt
is `bdpdrv-runC104.fe-tail.txt`, the gate output `bdpdrv-runC104.verdict.txt`.

## 0. The five observables, up front

| # | observable | value | reading |
|---|---|---|---|
| 1 | disc attached, 1 064 208 sectors | **PASS** | the run is the run |
| 2 | **the five plain-read oracles** | **ALL PASS** | `lba16` `c117ce4c…`, `lba510` `e56de1ad…`, `lba532104` `9ed18b47…`, `lba510x10` batch `45ccd7df…`, `lba1064207` `d1c54ec6…` — each re-derived host-side from the ISO at `lba × 2048` in the same session and equal byte-for-byte |
| 3 | **LBA 0 = real zeros** | `head16=4ae71336…` = md5(0x00 ×16) | the all-zero sector is served as zeros, not as poison or canned data |
| 4 | **poison gone** | 0 of 6 heads carry `698c867c…` (C103: 5 of 5) | the no-DMA signature is extinct |
| 5 | **past-EOF rejected with a sense triple** | `rc=-1, sense=010000 host=0000 driver=0000` | model row 23 (`byte3 != 0`, no clamp) behaves exactly as designed |

## 1. The model-side trace (what the FE did)

```
bx510: FE READ 28 lba=16      nsec=1  len=2048  frame=2048 -> phys 1d8bc000 (descriptor DMA)
bx510: FE READ 28 lba=510     nsec=1  len=2048  frame=2048 -> phys 1d8bc000 (descriptor DMA)
bx510: FE READ 28 lba=532104  nsec=1  len=2048  frame=2048 -> phys 1d8bc000 (descriptor DMA)
bx510: FE READ 28 lba=0       nsec=1  len=2048  frame=2048 -> phys 1d8bc000 (descriptor DMA)
bx510: FE READ 28 lba=510     nsec=10 len=20480 frame=2048 -> phys 1d8bc000 (descriptor DMA)
bx510: FE READ 28 lba=1064207 nsec=1  len=2048  frame=2048 -> phys 1d8bc000 (descriptor DMA)
bx510: FE READ 28 past EOF: lba=1064208 nsec=1, disc has 1064208 sectors (last LBA 1064207) — answering drive error
bx510: FE READ 28 lba=510 nsec=2: 0x5c404=4128 means 2064 bytes per sector, not 2048 — taking the descriptor length
bx510: FE READ 28 lba=510 nsec=2: 2064-byte sector framing is not modelled (2048 plain, 2352 raw CD) — answering drive error, no data
```

FE PACKET census (whole run): 1 × `no-data`, 3 × `unknown` (= REQUEST SENSE,
see §3), 1 × `gesn` — the GESN row named the media poll honestly this time
(same bare-success answer C103 proved benign; the semantic medium-present
reply is still a later decode). Descriptor census: `05c40c=1` ×9 arms,
`05c404` = 800×6 / 5000×1 / 1020×2 — every transfer the driver asked for,
each served or refused by name.

## 2. The verdict table

`sh read10_verdict.sh bdpdrv-runC104.uart.log bdpdrv-runC104.mmio.log
bdpdrv-runC104.meta.json` → **28 PASS / 1 FAIL / 0 SKIP**; the single FAIL is
`framing verdict (unresolved (accept is payload_at_12_stride_2064))`. New
since C103:

* **B is recalibrated and green.** `blkgetsize64=1073741312 blkssz=512` — the
  FA-mode fallback — is now the *expected* value, with a `want 0` discriminator
  on `nbytes=8` packets keeping the calibration honest (if a READ CAPACITY
  packet ever appears, the guest tree changed and B must be re-derived, not
  silently inherited).
* **D0/D1–5/E are green for real.** C103's tooling-defect FAILs are gone
  (`dd` hash window, CR normalization — §3), and C103's no-DMA FAILs are gone
  because the DMA exists.
* **H is 8/8.** The `1020`/`980002` rows are `want_ge 1` (two 5303 entries are
  correct), and the no-READ-CAPACITY constant is part of the gate.

## 3. What the run adds beyond the oracles

1. **The 2064-byte SACD channel is now a measured object.** Both 4128-byte
   transfers were refused loudly (the model does not synthesise that framing
   yet), the driver retried with REQUEST SENSE after each refusal — the three
   `unknown` packets in the census are exactly the three drive errors
   (past-EOF + two refusals), opcode `0x03`, alloc 0x60 — and *the ioctl still
   returned `ret=0 result=0` with a dump full of real, structured,
   non-poison, non-ISO data*: `sacd510` hashes at offsets 0/4/8/12/16/24/
   2048/2064/2072/2076/2080/2088 are all distinct and none equals any plain
   ISO-sector candidate (off 0 is `33ab29b8…`, not `e56de1ad…`). **The
   4128-byte buffer's origin is OPEN** — the FE refused both descriptor
   transfers, so those bytes did not come from a C104 DMA. Candidates: the
   driver pre-fills/serves its own state through the 5303 handler, or a second
   data path (the IDE-HAL a-window lane is the standing alternative) carried
   them. This is the first real evidence in the framing investigation, and it
   is labelled MEASURED, origin INFERRED-none-yet.
2. **libata EH is clean around errors.** The three drive-error completions
   each went status→REQUEST SENSE→command retry/fail with zero `qc timeout`,
   zero EH give-up, zero SRST noise (gate C: all PASS). The refusal answer is
   not just correct at the SCSI layer, it is correct at the libata layer.
3. **The whole C100→C104 spine is now a single reproducible story**: attach
   (C100/C101) → enumerate (C102) → command ladder (C103) → data (C104).

## 4. Defects the run found in its own tooling (fixed in the tracked files)

1. **The gate's `$`-anchored BREs could never match the UART transcript** —
   guest console lines end CRLF, so `hash=c117ce4c…$` matched nothing and
   five byte-perfect oracle matches read as 0. The gate now normalises one
   `tr -d '\r'` copy and greps that. (C103's §6 tooling defects were the same
   family: the instrument, not the rig.)
2. **Check B's expectation was stale for this tree** — recalibrated to the
   FA-mode fallback with the no-RC discriminator (§2), per the
   expectation-freshness rule. The old `2179497984 blkssz=2048` value could
   never appear in this rig: READ CAPACITY is never issued.
3. **`nbytes=3` packets were `unknown` in the trace** — named as REQUEST
   SENSE (`0x03`) post-fire; behaviour (bare success) unchanged from the
   proven C104 answer, so the next run's census will name them without any
   behavioural delta. The req-sense *semantic* row (real sense bytes) is a
   later decode keyed on what the driver's error recovery reads back.

## 5. What was measured, stated as claims (labelled)

| claim | label |
|---|---|
| The FE descriptor DMA delivers fixture-identical bytes to a guest user buffer for plain 2048-byte READ(10) at LBAs 0/16/510/532104/1064207 and a 20480-byte batch | **VERIFIED** (oracle md5s + host-side ISO re-derivation, same session) |
| Past-EOF is refused (`rc=-1`) with a sense triple and no clamping | **VERIFIED** (transcript + FE refusal line) |
| A 4128-byte (2064×2) transfer is refused loudly and the driver recovers via REQUEST SENSE without EH fatality | **VERIFIED** |
| The 5303 ioctl returns success with 4128 bytes of structured non-ISO data | **VERIFIED** (guest-side hashes); **origin of those bytes: OPEN** |
| The 2064-byte SACD framing layout | **NOT MEASURED** — the refused transfers carry no framing; `payload_at_12_stride_2064` stays the design assumption, now with a real dump to test hypotheses against |
| Whether the daemon's SACD path works end-to-end | **NOT MEASURED** — `SACDREAD cmd=0x40105301 result=-402653184` (CPSA Connect fail) unchanged from C103, in both the smoke stage and the ladder prime |

## 6. Reproduce

```sh
# VM, from /home/aftermath — the fire line is /tmp/c104-fire.sh; identical to
# run-c103.md §9 with C104 names. Verdict:
sh /tmp/read10_verdict.sh /tmp/bdpdrv-runC104.uart.log \
   /tmp/bdpdrv-runC104.mmio.log /tmp/bdpdrv-runC104.meta.json
```

## 7. Next

| # | change | owner | settling observable |
|---|---|---|---|
| 1 | **Decode the 2064-byte framing** — hypotheses against the real `sacd510` dump (12/16/24 offsets × strides, header+payload split), keyed on `sacdread-cpsa.md`'s 2064 decrypt contract | next decode lane | a framing layout whose predicted md5s reproduce the dump's measured hashes |
| 2 | **The 5303 buffer's origin** — where 4128 structured bytes came from with both descriptor transfers refused (driver state? a-window lane? GCPU channel — the OSAL_STUB GCPU threads woke during the prime) | next decode lane | a trace line that carries those bytes |
| 3 | **CPSA Connect `0xE8000000`** — leg (e) cannot truly pass while INIT fails | driver/CPSA owner | `result=1744830464` (`0x68000000`) |
| 4 | **The daemon stage** — `sacd_extract_160` as the last stage, now that the read path serves real bytes | next fire | the daemon's own READ traffic in the FE census |
| 5 | REQUEST SENSE semantic row (real sense bytes) | model | guest records the FE's sense, not a synthesised one |

**Provenance:** everything above is from the pushed evidence bundle and the
two tracked scripts; the ISO-side oracle re-derivation is in this session's
transcript (`dd if=firebird.iso bs=2048 skip=N count=1 | md5sum` for each
oracle LBA, plus the batch). Fire at 16:29:11Z, uart 104 476 B, trace
~112 MB VM-side, `terminal_marker true`.
