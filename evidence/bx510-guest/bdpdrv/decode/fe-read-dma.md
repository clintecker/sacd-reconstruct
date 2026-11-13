# C104-pre — `FE_PKT_READ` is now a real descriptor DMA (rows 17-24 landed)

The model gap C103 measured is closed: a READ-family packet no longer advances the
ATA state machine with no data behind it. The FE now decodes the CDB out of the
mailbox words, reads the sectors from `s->sata_blk`, DMAs them straight into guest
RAM at the physical address in `0x5c400`, and completes with **one bare type-0
message** — exactly `c97-read-path.md` §5.2 rows 21-24.

**Scope of this stage: implementation + build + math proof. No fire.** The C104
fire is the parent's, with the C103 verdict in hand.

Model: `emulator-kit/sony-bx510.c`. Proof: `decode/fe_read_dma_selftest.py`
(new, re-runnable — extracts the model's own helpers and checks them against the
fixture oracles).

---

## 0. Bottom line

1. **The descriptor *is* armed in the real trace** — C103 measured the full
   `data_xfer` arm sequence nine times: `W 05c40c = 1`, `W 05c400 = 1d8b8000`,
   `W 05c404 = <len>`, `R 05c408`, `W 05c408 = 100`, `R 05c40c`, `W 05c40c = 601`.
   So row 21's `(fe_dma[3] & 1)` gate is live, and `fe_dma[0]` holds a real
   guest-physical address (`0x1d8b8000` = 495 943 680 < the 512 MiB RAM ceiling;
   the SACD leg uses a second buffer at `0x6314040`).
2. **Nine READ posts, three distinct shapes** (all measured, `bdpdrv-runC103`,
   full trace `VM:/tmp/bdpdrv-runC103.mmio.log`): six plain 2048-byte reads
   (`0x5c404` = `0x800` / `0x5000`), one past-EOF read (LBA 1 064 208), and two
   `0x5c404 = 0x1020` reads — **4128 = 2 × 2064**, the daemon's SACD frame
   channel with vendor flag `cdb[10] = 0x98`.
3. **What the model now does with each** (§4): serves the six plain reads (the
   five C97 oracle LBAs plus LBA 0), refuses the past-EOF read with `byte3 != 0`
   (row 23), and **refuses the two 2064-byte SACD reads loudly** rather than
   DMAing a ragged/mis-framed transfer — that framing is a different channel and
   needs a decision this stage did not take (§6, open item 1).
4. **Framing the brief left ambiguous is now settled by the spec, and
   implemented**: for `0xBE` the model must *synthesise* standard mode-1 CD
   frames (`frame[15] = 1`, payload at +16) — the driver strips the raw framing
   itself (`data_xfer` `0x54ac..0x54fc`), and the plain ISO holds no framing
   bytes (`c97-read-path.md` §4.2/§4.4, `firebird-fixture.md` §3.3, §6). It is
   not a "log and complete empty" case, and it is not readable at `lba × 2352`.
5. **Proof without firing**: the model's own decode + frame helpers, extracted
   verbatim and run against the ISO, reproduce **all five raw-frame md5s, all
   five stripped-payload md5s and all four recorded header quads** from
   `firebird-fixture.md` §5.1/§5.2, plus three CDB-decode cases. `SELFTEST PASS`
   (§5).

---

## 1. What changed, function by function

All in `emulator-kit/sony-bx510.c`.

| new / changed | what it does | spec |
|---|---|---|
| `FE_DMA_MAX` `0x12800`, `CD_PAYLOAD` `2048`, `CD_FRAME` `2352` | the driver's own 75 776-byte cap and the two sector sizes | §3.1, §4.3 |
| `FE_STATUS_ERR` `0x01000000` | a type-0 reply with `byte3 != 0` = drive error ⇒ `hw_chg_st(priv,5)` ⇒ status `0x51` | §3.2 |
| `bx510_fe_cdb()` | the 12-byte CDB image out of `w1..w3`, little-endian per word — `cdb[0]` = `w1` byte 0 | §4.1 |
| `bx510_fe_cdb_is_read()`, `bx510_fe_post_is_read()` | the three opcodes that have a data-in phase, i.e. the only posts that arm the descriptor | §5.2 row 21 |
| `bx510_fe_cdb_nsec()` | READ(10) `cdb[7..8]`, READ(12) `cdb[6..9]`, READ CD `cdb[6..8]` | §4.1 |
| `bx510_cd_frame()` | one mode-1 raw frame: sync, BCD MSF (minute masked to two digits), `frame[15] = 1`, payload at +16 | §4.2, fixture §3.3 |
| `bx510_fe_read()` | rows 21-23 end to end: framing + length reconciliation, EOF refusal, RAM bound, `blk_pread`, DMA, one type-0 | §5.2 |
| `bx510_fe_dispatch()` | the row-21 gate, evaluated **before** the content ladder | §5.2 "order matters" |
| `bx510_fe_dispatch()`, `code == 0xa1` branch | a READ CDB riding an `0xa1` post goes to `bx510_fe_read`, never to the IDENTIFY/window-offer branch | §0.7, §1.3 |
| `bx510_fe_packet()`, `FE_PKT_READ` | the old `LOG_UNIMP … completion carries no data` + **success** reply is gone; the case is now the unarmed-descriptor fallback and answers a drive error | §3.3 |
| `0x5c400..0x5c40c` read/write comments | the words are consumed on the doorbell, never on the write; `& 1` is the arm flag; never auto-clear | §1.2, §2.2 |

### 1.1 The transfer, in order

```
on W 0x5c020 with bit0 set, BEFORE the code/type ladder:
  if (fe_dma[3] & 1) && the post's w1..w3 decode to CDB[0] ∈ {0x28,0xA8,0xBE}:
      lba  = BE32(cdb[2..5])
      nsec = CDB count            (READ10/12/READCD field)
      flen = 2352 if cdb[0]==0xBE else 2048
      if 0x5c404 / nsec ⇔ flen disagrees → take the descriptor length (§4.1)
      if flen ∉ {2048, 2352}      → refuse, type-0 byte3 != 0       (§6 open item 1)
      nsec = 0x5c404 / flen       (when whole frames), then cap at 0x12800
      lba + nsec > sectors        → refuse, type-0 byte3 != 0        (row 23)
      phys + nsec*flen > RAM      → refuse, type-0 byte3 != 0
      blk_pread(sata_blk, lba*2048, nsec*2048)
      if flen == 2352: synthesise nsec mode-1 frames around those sectors
      address_space_write(&address_space_memory, phys, …, len)
      bx510_fe_post(s, 0, 0, 0, 0)      ← ONE message, no type-0x10
```

`address_space_write` (not a `stb_phys` loop) because the destination is one
contiguous physical run of up to 75 776 bytes; a 32-sector raw read is 75 264
bytes, and the byte-at-a-time path would be 75 k MMIO dispatches per qc.

---

## 2. The dispatch order, and why the CDB decides (not the code byte)

`c97-read-path.md` §0.7 warns that a READ rides `w0 byte3 = priv+0x29c`, the same
sticky byte an IDENTIFY/loader post carries, so keying on `code == 0xa1` +
`arg != 0` would answer a READ with an IDENTIFY payload — and that type-0x10
message is **destructive**: on the IRQ path, direction 1 takes the
window→buffer `memcpy` (`0x4850`) over the freshly DMA'd sectors and the read
still looks successful (§1.3).

The measured C103 trace has `W 05c000 = a0000000` on every packet post (the
`0xa0` ATA-PACKET byte), so in this rig the READ packets reach the ladder through
`code == 0xa0`. The gate is written for both:

* `(arm ∧ READ CDB)` → `bx510_fe_read()` — before the ladder, so `0xa1` and
  `0xa0` are handled identically;
* `code == 0xa1` ∧ READ CDB → `bx510_fe_read()` (never the IDENTIFY branch);
* `code == 0xa0` → the packet ladder; `FE_PKT_READ` there is the "READ CDB, no
  armed descriptor" fallback.

### 2.1 Deviation from row 22, deliberately

Row 22 says "armed but not a READ ⇒ log loudly once, then serve as a plain
type-0 completion". The model instead logs nothing at that point and **falls
through to the content ladder** (which never DMAs, so row 22's actual invariant —
no DMA on a stale descriptor — holds). Two reasons, both from the decode:

* the arm is **not** cleared on a READ completion: `hw_chg_st`'s disarm
  (`0x4428`) is reached only when the completing CDB is *not* one of
  `0x28/0xA8/0xBE` (§1.1, §1.4). So `0x5c40c = 0x601` is the *normal* state after
  any read, and a "loud" log would fire on every subsequent TUR/MODE SENSE;
* a bare type-0 completion for a non-READ data-in post would break READ
  CAPACITY / MODE SENSE / READ TOC, which need the type-0x10 window offer
  (`write10-model.md` §1.2 mechanism B). That would be a C101/C102 regression.

The measured trace confirms the pattern: after each read the driver writes
`W 05c40c = 0` on the *next* non-READ completion, so the stale state is real and
transient.

---

## 3. Framing decision (§4.2 / §4.4, brief item 3)

The brief offered "2048-only, log + complete empty for 2352" if §4.4 turned out
ambiguous. It is not ambiguous, so the spec's answer is implemented:

* the driver rewrites READ(10)/READ(12) into READ CD (`0xBE`, `byte9 = 0xF8`) and
  sets `0x5c404 = nsec × 2352` only when the disc profile `priv+0x18 ∈ {8,9,10}`
  (`qc_issu_task` `0x6e9c..0x6f04`); otherwise the CDB is posted unmodified and
  `0x5c404 = nsec × 2048`;
* **the driver strips the raw framing itself**, using the frame's own header byte
  15 to pick payload offset 16 (mode 1) or 24 (mode 2) — `data_xfer`
  `0x54cc..0x54fc`. So the FE must emit *standard* CD frames and must not
  pre-strip;
* a 2352-addressed read of the plain ISO is **not** a frame: the file stores no
  framing bytes, and `lba × 2352` diverges from `lba × 2048` by `352 × lba`
  (`firebird-fixture.md` §3.2 — wrong sector from LBA 1 onward, past EOF from LBA
  926 657). Frames are *synthesised* around the same 2048-byte logical sector.

`bx510_cd_frame()` implements fixture §3.3 exactly: `00 FF×10 00` sync, BCD MSF of
`lba + 150`, `frame[15] = 1`, payload at +16, EDC/ECC left zero (never verified).
The minute is masked `% 100` — the constraint the fixture found the hard way: a
literal BCD of `(lba+150)/4500` overflows a byte past LBA 449 849 and corrupts the
mode byte.

In this rig the profile is DVD (the driver never rewrote the CDB — every C103
post is `0x28`), so the 2352 branch is not exercised by C104. It is implemented
because the decode is closed, not because a trace demands it yet.

---

## 4. Predicted model response to every C103-measured READ post

Decoded from the full trace (`VM:/tmp/bdpdrv-runC103.mmio.log`, line numbers) and
evaluated through the rules in §1.1. `sectors = blk_getlength/2048 = 1 064 208`.

| trace line | op | LBA | nsec | `0x5c404` | frame | model response |
|---|---:|---:|---:|---:|---:|---|
| 3796036 | `0x28` | 16 | 1 | `0x800` | 2048 | DMA 2048 B from 32768 → one type-0 success |
| 3802629 | `0x28` | 510 | 1 | `0x800` | 2048 | DMA 2048 B from 1044480 → success |
| 3808808 | `0x28` | 532104 | 1 | `0x800` | 2048 | DMA 2048 B from 1089748992 → success |
| 3814944 | `0x28` | 0 | 1 | `0x800` | 2048 | DMA 2048 B (legitimate zeros) → success |
| 3821085 | `0x28` | 510 | 10 | `0x5000` | 2048 | DMA 20480 B (batch) → success |
| 3825389 | `0x28` | **1064207** | 1 | `0x800` | 2048 | DMA 2048 B from 2179495936 → success (**last valid LBA**, `0x00103C8F`) |
| 3831454 | `0x28` | **1064208** | 1 | `0x800` | 2048 | **refuse** — past EOF → type-0 `byte3 != 0` → status `0x51` |
| 3879446 | `0x28` | 510 | 2 | `0x1020` | 2064 | **refuse** — framing not modelled → `byte3 != 0` |
| 3910085 | `0x28` | 510 | 2 | `0x1020` | 2064 | **refuse** — framing not modelled → `byte3 != 0` |

The last-LBA clamp agrees with the IDENTIFY/READ-CAPACITY geometry already in the
model (`sectors - 1 = 1064207 = 0x00103C8F`, the literal in the C101 recipe), so
the boundary the ladder tests is the same boundary libata was told about.

---

## 5. Verification

### 5.1 Build (VM, tracked sources → pinned QEMU 9.2.4)

```
$ scp emulator-kit/sony-bx510.c VM:bx510-emu/emulator/
$ make sacd-emu-build
[4/5] Compiling C object libqemu-arm-softmmu.a.p/hw_arm_sony-bx510.c.o
[5/5] Linking target qemu-system-arm
sony-bx510           Sony BDP-BX510 (MT8560, experimental)
```
Clean rebuild of the touched unit on request (`touch` + `ninja`): **no warnings, no
errors**.

### 5.2 Math selftest — `SELFTEST PASS`

`python3 decode/fe_read_dma_selftest.py` (Mac → VM: the ISO lives there). It
extracts `bx510_fe_cdb`, `bx510_fe_cdb_is_read`, `bx510_fe_cdb_nsec` and
`bx510_cd_frame` **verbatim from the model source**, compiles them with a driver,
and compares against the fixture doc's independently-derived oracles:

```
DECODE read10     lba=510 nsec=10 PASS        (CDB 28 00 00 00 01 FE 00 00 0A 00 …)
DECODE read12     lba=532104 nsec=32 PASS      (CDB A8 …, 4-byte length field)
DECODE readcd     lba=510 nsec=1 PASS          (CDB BE …, 3-byte length field)

                                          # raw 2352-byte frames: md5 of what the model DMAs
b8f578e8806bf4debabc28f765281699  16_1.raw         (fixture §5.2 row 1)
e03d750071d75dfdb006b074a1897b21  510_1.raw
149a9ff1432a87fec5e71656be195a95  532104_1.raw
14690aec4e5333ebed530137f53d4f4a  510_10.raw       (23520 B, the daemon's TOC batch)
dfaefb598cdde300952201794e826bd7  1064207_1.raw    (final sector)

c117ce4cef54ab625e33583156605721  16_1.strip       ← after the driver's own strip loop
e56de1add53c90dd30cf9232b29ddc93  510_1.strip
9ed18b47f67232ea972515df65cb6ac5  532104_1.strip
45ccd7dfbf433a79d28e877d7441677c  510_10.strip
d1c54ec6c395d7092ce06f04705d33ae  1064207_1.strip

91adbac10a8ba858c03bf68317384405  16_1.hdr         00 02 16 01
0c0420bff999813d8f45c7c03114eb0d  510_1.hdr        00 08 60 01
541bc260e6ae7026ae8ac524dbd34882  532104_1.hdr     18 16 54 01
72d90c4a1a175f02f4d356b136a6bf76  1064207_1.hdr    36 31 32 01   (minute wrapped %100)

SELFTEST PASS — 5 raw frames + stripped payloads + headers, 3 CDB decode cases
```

Every hash equals `firebird-fixture.md` §5.1/§5.2 (raw column and strip column) and
every header quad equals the recorded `frame[12:16]`. So if the C104 guest reads
any of those LBAs, the bytes it *should* see are already known-good — a mismatch
in the guest dump now means the plumbing (descriptor, IRQ, completion shape), not
the arithmetic.

Not covered by the selftest (needs a fire): the EOF refusal, the completion shape
(one vs two messages), and the `0x5c804` raise — those are §6 checks of
`c97-read-path.md` and the C104 verdict's job.

---

## 6. What C104 should show, and what to check first

Per read, in the trace:

```
W 05c40c = 1 ; W 05c400 = <phys> ; W 05c404 = <nsec*2048> ; R/W 05c408 ; R/W 05c40c = 601
W 05c004/8/c = CDB ; W 05c020 = <|1>
bx510: FE READ 28 lba=<lba> nsec=<nsec> len=<nsec*2048> frame=2048 -> phys <phys> (descriptor DMA)
R 05c804 = 0x10000 ; R 05c800 = 0xfffffff0
R 05c040 = 0 ; R 05c044/048/04c = 0          ← exactly ONE quadruple per READ
```

Fail signatures, in the order worth checking:

1. **`FE READ packet CDB .. with no armed 0x5c400 descriptor`** — the arm is
   gated on `Priv+0x220 == 3` in `data_xfer` (`0x546c..0x5484`); if the model sees
   the post without the arm, the qc was posted by a different branch and no DMA
   target exists (C97 §9 item 1's settling experiment, now model-visible).
2. **`past EOF`** on a read that should succeed → the CDB LBA decode went
   little-endian (fixture §6: a constant 2048-byte shift in the guest payload).
3. **`bytes per sector, not 2048`** → the driver sized a frame the model does not
   synthesise (the 2064 SACD leg, below).
4. **Two `R 05c040..c04c` quadruples for one READ** → a second message was posted;
   the payload is suspect (§1.3).
5. **`0xbb` still in the first 16 bytes** of a destination buffer that the trace
   shows as DMA'd → the DMA went somewhere else than the guest reads (check
   `fe_dma[0]` against the `W 05c400` value in the trace).

---

## 7. Merge notes — the in-flight peer, kept

The working tree already carried an uncommitted model change from the C102/C103
worker. It was **read first and kept**; this stage is additive on top of it:

| kept as-is | why |
|---|---|
| `0xa0` → `bx510_fe_packet()`, the CDB/length classifier, `FE PKT …` trace line | it is what produced the C102/C103 measurements; the READ classifier agrees with the new CDB decode by construction (both read `w1` byte 0) |
| READ CAPACITY(10) (8 B, last LBA from `blk_getlength/2048`) and MODE SENSE(6) page `0x2a` (128 B) rows, `FE_PKT_OFF = 0x2400` | untouched; these are the mechanism-B rows C103 needs next |
| the `0xef` SET FEATURES comment/dispatch, `fe_msg[]` staging | untouched |

Changed on top of it: the `FE_PKT_READ` case (was `LOG_UNIMP` + **success**
reply), the dispatch (row-21 gate first, `0xa1`-guard), the `0x5c400` group
comments, and the new helper block. `tools/bx510_bdpdrv_stub_probe.py` (also
uncommitted, the peer's fire-side probe) was **not touched** by this stage.

Nothing is committed: the tree stays exactly as the parent's fire worker needs it
(model + probe + C103 evidence, uncommitted).

---

## 8. Open items

| # | item | label | settling experiment |
|---|---|---|---|
| 1 | **the 2064-byte SACD frame channel** — two C103 posts carry `0x5c404 = nsec × 2064` with the vendor flag `cdb[10] = 0x98`; the model refuses them (loud log + `byte3 != 0`) rather than DMA a mis-framed transfer. Serving it needs the frame layout *and* the CPSA decrypt question decided (`firebird-fixture.md` §3.4: 12-byte header, payload at +12 — but the daemon calls `CPSA_SACDCmdDecrypt` on the frame first, so what the FE supplies may be ciphertext) | **open — needs a decision**, not guessable from the current decode | C104's `FE READ … 2064-byte sector framing is not modelled` line proves the refusal is the only affected leg; the framing question is `decode/sacdread-cpsa.md`'s territory, a separate stage |
| 2 | mode 1 vs mode 2 for the raw frames | INFERRED (mode 1, `frame[15] = 1`) — oracle-proven for the *mode-1* layout only | a C104 trace with a `0xBE` post; §6 check 4 of `c97-read-path.md` (uniform 8-byte shift ⇒ wrong mode byte) |
| 3 | does any live path ever post READ(12) `0xA8`? | no trace has one; accepted because the cost is four lines | C104 trace: `W 05c004` low byte `a8` |
| 4 | row 22's literal "bare completion" for a stale arm | **deliberate deviation** (§2.1) — arm stays set after a read, and a bare completion would break the data-in verbs | C104: the first post-read TUR/READ CAPACITY must still be answered by the ladder (type-0x10 for READ CAPACITY), not by a bare success |
| 5 | `0x5c400` sometimes holds a *second* buffer (`0x6314040`, the SACD leg) | observed; both are < 512 MiB so the RAM bound never trips | no action needed unless a future arm shows `phys + len > 512 MiB` (then the model refuses and says so) |

---

## 9. Reproduce

```sh
# math proof (Mac → VM; the ISO lives on the VM)
python3 evidence/bx510-guest/bdpdrv/decode/fe_read_dma_selftest.py

# the model build (VM)
scp -o BatchMode=yes -P 2222 emulator-kit/sony-bx510.c \
    aftermath@10.20.0.18:bx510-emu/emulator/
make sacd-emu-build

# the C103 posts this stage answers (full trace, 3.5 M lines)
ssh -p 2222 aftermath@10.20.0.18 \
    'grep -n "W 05c40[04c]\|FE PACKET\|FE READ" /tmp/bdpdrv-runC103.mmio.log | head -80'
```
