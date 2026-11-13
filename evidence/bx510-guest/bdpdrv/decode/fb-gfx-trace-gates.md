# fb-gfx-trace-gates.md — the G1–G4 gate harness for the GFX/fb path

The fb lane's own next step (`fb-surface.md` §7 step 1) is to ask one question
before writing any model row: **does the guest's fb/GFX kernel code already run
against the modelled machine, or is the model the thing in the way?** This
directory now has a tool that answers it per gate from a single MMIO log, and a
ready-to-apply patch for the model rows that only matter *if* the answer is
"some of it runs".

| Artifact | What it is |
|---|---|
| `decode/fb_gates.py` | the checker: evaluates G1–G4 from a `BX510_TRACE=1` MMIO log, prints PASS/FAIL/INDETERMINATE with counts (and `--selftest`) |
| `decode/fb-gfx-rows.patch` | model rows **R2/R3/R4/R7** as a unified diff against `emulator-kit/sony-bx510.c` — **apply only if a trace shows `GFX_CmdQueAction`/`GFX_HwGetIdle` running** |
| this file | gate definitions with instruction receipts, the Run C95 baseline result, the apply procedure |

Subject binary: `bdpdrv.ko` sha256
`6604f6cd6c204c3399ac047f389f47162b06a3f6576159f21b4e8aaf3a72cf54`. Every
`.text` address below is section-relative (ET_REL) and every phys address was
resolved with `decode/resolve_addrs.py --reach` / `--func`, not by eye.

## 1. The gates, and where each one comes from

`fb-surface.md` §4.3 defines the fb proof as four *witnesses* (two UART string
lines, two guest-shell files). Two of those cannot be read from an MMIO log, so
the trace-side harness covers the UART pair plus three structural gates that
ask the same question the row table asks — "did the GFX code actually execute
against this model?":

| Gate | Question it answers | Evidence it requires | Receipt |
|---|---|---|---|
| **G1** `HwReset-complete` | did `GFX_HwReset` run to its end instead of wedging in the status poll? | 7 accesses, in order: `W 0x4000=0xa0000000`, `W 0x4010`, `R 0x4000`, `R 0x400c`, `W 0x400c`, `R 0x4134`, `W 0x4134` | `.text 0x176898, 0x1768d4, 0x176958, 0x176a14, 0x176a2c, 0x176a3c, 0x176a78` |
| **G2** `fb-registered` | did `register_framebuffer` succeed? | UART: `_mt8530fb_probe() fail: cannot register mt53fb!` absent **and** `_mt8530fb_probe(): probe init OK!` present | literals `.rodata.str1.1+0x54ea5` / `+0x54ed6`, logged via `vFBDbgLog` |
| **G3** `CmdQueAction` | did the driver push an action onto the command ring? | a write to `0x400c` that is **not** paired with a read of `0x400c` | `GFX_CmdQueAction` `str` `.text 0x175bcc` (its only `0x400c` access) |
| **G4** `HwGetIdle` | did anything ask the engine whether it is idle? | any read of `0x4004` | `GFX_HwGetIdle` `ldr` `.text 0x177074`, `and r3,r3,#1` 0x177084 (the only `0x4004` reader in the module) |

Mapping to `fb-surface.md` §4.3 (so the two numbering schemes never get
conflated):

| §4.3 gate | §4.3 asks | covered here |
|---|---|---|
| G1 (UART tag without the fail line) | probe reached, registration not rejected | **G2** — FAIL only when the fail line is present; silence is INDETERMINATE, never PASS (§2.1: "its absence is not evidence") |
| G2 (UART `probe init OK!`) | registration succeeded | **G2** PASS line |
| G3 (`/proc/fb`, `/dev/fb0`) | the fb device exists in the guest | **not covered** — one shell command, §5 below |
| G4 (sysfs stride/virtual_size) | geometry parity with the player | **not covered** — one shell command, §5 below |
| — | did the GFX code path execute? | **new G1/G3/G4**, the MMIO side |

### G1's legs, and why the ordering is the gate

`GFX_HwReset` is a straight-line access sequence, so *reaching the last leg* is
the proof that the poll loop at `.text 0x17694c-0x17697c` was satisfied: the
loop keeps the CPU inside the function body, so a poll that never passes shows
up as a read storm on `0x4000` and **no** later legs. Two accesses that look
like they belong are deliberately not legs:

* `W 0x4010` at `.text 0x176a98` is guarded by `cmp r5, #16` / `bne 0x176a9c`
  (an optional caller-argument epilogue), so Run C95 — which has exactly **one**
  `0x4010` write — is not missing a leg;
* the poll `ldr` at `0x176958` reads whichever engine the `r4` argument
  selects — `cmp r4,#0` / `moveq r3,<0xfd004000>` / `movne r3,<0xfd040000>` at
  `0x17694c-0x176954`. `resolve_addrs.py --func GFX_HwReset` reports the
  **engine-1** address at that site because it resolves the `movne` path; Run
  C95 ran with `r4 == 0` (11 reads of `0x4000`, 0 engine-1 events). Same for
  `0x176908/0x17692c/0x176948` (R11 in `fb-surface.md` §4.2): engine 1 is
  counted and reported separately, and has never fired in a run we hold.

### G3's discriminator: two functions own `0x400c`

| Owner | Shape | Site |
|---|---|---|
| `GFX_HwReset` | read → `orr #0x10000000` → write, so the write is **paired** with a read of the same offset | `0x176a14` / `0x176a20` / `0x176a2c` |
| `GFX_CmdQueAction` | value built on the stack, written **unpaired** | `0x175bcc` |

Pairing is per-offset, not per-adjacent-line: a `BX510_TRACE=1` log interleaves
SATA/BIM traffic freely, so "the previous line" is not "the previous access to
this word". The queue-base word `0x4008` is reported as G3 context, not as a
gate — its three owners are `GFX_CmdQue{Reset,Restore,Change}`
(`.text 0x1756d8 / 0x17607c / 0x176130`), i.e. it proves the *family* ran, not
that an action was pushed.

## 2. What a trace can and cannot prove

Three properties decide how much weight a gate result carries; all three are
implemented in `fb_gates.py`:

1. **Reads carry no value.** `bx510_read` logs `MMIO R %06x sz%u` — no value.
   So "the poll returned idle" is *not* observable; the gates are structural
   (which offset, which order, which write value). Write values *are* logged.
2. **In a `BX510_TRACE=1` log, absence is evidence.** Every access is logged,
   so "no read of `0x4004` in a 5.2 M-line trace" really does mean
   `GFX_HwGetIdle` never ran — unlike a missing UART line, which means nothing.
   The one caveat: the default arm's `unimplemented` log is capped
   (`s->unimp_logs++ < 200000`), and it is **not** the gate's evidence — see 3.
3. **Both line shapes are emitted for an unmodelled register.** Run C95 lines
   2616804/2616805 and 2616806/2616807 are the `MMIO` line *and* the
   `unimplemented` line for the same access. Counting both double-counts
   exactly the registers under test, so the checker prefers the `MMIO` set when
   a log has one and falls back to `unimplemented`-only logs (e.g. Run C50)
   with a printed warning that a FAIL there may just mean "answered by the
   model".

## 3. Run C95 baseline — the honest result on the current model

The tracked trace tail is `decode/bdpdrv-runC95.posthandshake.mmio.gz` (the
committed post-FE-handshake tail, 5.22 M lines, of the 5.7 M-line C95 fire; the
full log stays VM-side — see `bdpdrv/run-c94-c95.md`). Command and full output:

```
$ cd evidence/bx510-guest/bdpdrv/decode
$ python3 fb_gates.py bdpdrv-runC95.posthandshake.mmio.gz \
      --uart ../bdpdrv-runC95.uart.log -v
trace:  bdpdrv-runC95.posthandshake.mmio.gz
source: BX510_TRACE lines (5188226 MMIO, 36145 unimplemented) in 5224801 lines
gfx:    61 events in 0x4000..0x5000; engine-1 (0x40000+) events: 0

G1 HwReset-complete      PASS
    7/7 legs: W 0x4000 = 0xa0000000, W 0x4010, R 0x4000, R 0x400c, W 0x400c, R 0x4134, W 0x4134
    leg W 0x4000 = 0xa0000000  .text 0x176898       reset command word (event #1)
    leg W 0x4010               .text 0x1768d4       engine control word (event #2)
    leg R 0x4000               .text 0x176958       status poll (event #3)
    leg R 0x400c               .text 0x176a14       RMW read (event #8)
    leg W 0x400c               .text 0x176a2c       RMW write | 0x10000000 (event #9)
    leg R 0x4134               .text 0x176a3c       read before write (event #10)
    leg W 0x4134               .text 0x176a78       write back (event #11)
G2 fb-registered (UART)  INDETERMINATE
    fail line: False | success line: False | any probe tag: False
    probe tag absent — vFBDbgLog's enable flag is off in captured runs, so this
    gate cannot fire from UART; use /proc/fb + sysfs (fb-surface.md §4.3 G3/G4)
    or the MMIO gates here
G3 CmdQueAction          FAIL
    0x400c writes: 1 paired (HwReset RMW) [0x10000000], 0 unpaired (CmdQueAction)
    0x4008 queue-base writes (G3 context, owners GFX_CmdQue{Reset,Restore,Change}
    .text 0x1756d8/0x17607c/0x176130): 2 [0x975e0000 0x975e0000]
G4 HwGetIdle             FAIL
    0x4004 reads (GFX_HwGetIdle): 0

VERDICT: 3 of 4 gates not PASS (G2 fb-registered (UART), G3 CmdQueAction, G4 HwGetIdle)
$ echo $?
1
```

(`fb_gates.py --selftest` is 16 synthetic checks against the model's own line
shapes: the C95 shape, the post-rows shape, a wedge shape, all four G2 UART
skins, and the double-log dedupe. Exit 0 == PASS.)

### 3.1 What C95 actually shows

The 61-event gfx sequence in file order (`fb_gates.py ... --dump`), condensed:

| Events | What ran | Consequence for the row table |
|---|---|---|
| #0 `W 0x4104 = 0x1` | `GFX_Init` | R6 already answered |
| #1–#11 | **`GFX_HwReset` complete**: `0xa0000000` → `0xc00001f0` → poll → `0x400c` RMW (`0x10000000`) → `0x4134` read/write | **G1 PASS. The model's six gfx words (`fb-surface.md` §4.1) are already enough for the full reset path** — and `0x400c`/`0x4134` reads returning 0 did not wedge anything (R4/R7 are benign-as-zero for the reset leg) |
| #12–#31 | a second `0x4000` command block twice, each ending in `W 0x4008 = 0x975e0000` | the `GFX_CmdQue{Reset,Restore,Change}` family ran; **R3 (`0x4008` store) is exercised in a real run**; today those writes fall into the default arm (`unimplemented write 0x70004008`) and are benign. Which of the three ran cannot be pinned from the trace alone (all three write `0x4008`) |
| #32–#60 | the RLE/SE engine's `0x4800` block, same shape as engine 0's reset (`W 0x4800=0xa0000000`, `W 0x4810=0x1f0`, poll, `W 0x48c0=0x40000000`, queue base `W 0x4808=0x17750000`) | R10 (RLE/SE engine) confirmed answered; see §3.2 for `0x4808` |
| — | **no `0x4004` read, no unpaired `0x400c` write** | G3/G4 FAIL: `GFX_CmdQueAction` and `GFX_HwGetIdle` never executed in this run |

Counts per offset (deduped): `0x4000` R=11 W=13 · `0x4008` W=2 (`0x975e0000`) ·
`0x400c` R=1 W=1 (`0x10000000`) · `0x4010` W=1 (`0xc00001f0`) · `0x4104` W=1
(`0x1`) · `0x4134` R=1 W=1 (`0x0`) · `0x4800` R=11 W=13 · `0x4808` W=2
(`0x17750000`) · `0x4810` W=1 (`0x1f0`) · `0x48c0` R=1 W=1 (`0x40000000`).

### 3.2 Two findings from the baseline worth keeping

1. **G2 cannot fire from UART at all, on any run, until someone sets a debug
   flag.** `vFBDbgLog` returns before printing unless a `.bss` byte is non-zero:
   `.text 0x14a010` `ldr r3,[pc,#0x3c]` → literal `0x14a054` = `.bss+0x82888`
   (REL addend read out of the module), `ldrb r3,[r3]` / `cmp r3,#0` /
   `beq 0x14a040` (skip). No captured UART log contains `_mt8530fb_probe` at
   all — including Run C50, where `[OSAL_STUB] x_memset … caller=mt8530fb_init`
   proves the init path ran. So §4.3's UART pair is structurally dark in this
   rig, and the shell/MMIO witnesses are the real observables. Setting
   `.bss+0x82888` (config word or module-image patch) is the only way to light
   it up; that is a separate decision, not taken here.
2. **`0x4808` is unmodelled and nobody noticed.** The RLE/SE block's queue-base
   write (`W 0x4808 = 0x17750000`, twice) has no case in the model — it lands in
   the default arm exactly like `0x4008` does. Structurally identical to R3 and
   likewise benign so far; it is **not** in the patch (rows R1–R12 do not list
   it, and nothing has needed it). Recorded here so the next agent does not
   rediscover it as a surprise.

### 3.3 What this means for the fb lane

* The kernel side of the fb path that is *reachable without a compositing
  client* already works on the current model: `GFX_Init`, `GFX_HwReset` (G1),
  and the `GFX_CmdQue{Reset,Restore,Change}` family.
* The ring-kick half (`GFX_CmdQueAction`, G3) and the idle poll
  (`GFX_HwGetIdle`, G4) have **never executed** in any run we hold — consistent
  with C95's guest-shell phase, where no DirectFB/compose client opens
  `/dev/fb0`. R2 (idle polarity) and R4 (the action word) therefore remain
  untestable guesses, which is exactly why `fb-surface.md` §7 step 3 gates them
  on a trace rather than shipping them.
* `fb-surface.md` §4.3's payoff gates (`/proc/fb`, sysfs geometry) are still
  unmeasured — they need a guest-shell run, not an MMIO log. §5 has the
  commands.

## 4. The model patch — R2/R3/R4/R7, staged not applied

`decode/fb-gfx-rows.patch` is a unified diff against the working-tree
`emulator-kit/sony-bx510.c` (baseline sha256
`02e49dea7f9bfdeb00843c551dcae156203e95728135d6da0d1b557e272d6508` at stage
time; that file belongs to another lane, was **not** modified by this work, and
had already moved once since the patch was first cut — so the header carries
the `git apply --check` line to run first). It adds three state words and five
`case` arms:

| Row | Word | Change |
|---|---|---|
| R2 | `0x4004` R | `return 1u` — `GFX_HwGetIdle` returns `val & 1`, bit0 = idle (polarity INFERRED from name+mask) |
| R3 | `0x4008` W | store into `gfx_qbase` (ring base; nothing consumes the ring) |
| R4 | `0x400c` R/W | readback-last-written (`gfx_act`) |
| R7 | `0x4134` R/W | readback-last-written (`gfx_rst`) |

Untouched on purpose: R1/R5/R6/R10 (already answered), R8 `0x4258` and R9
`0x40a0/0x40d0-0x40ec` (0 is the correct idle answer for those debug readers),
R11 engine 1 (no trace shows it) and R12 the ring consumer (a project, not a
row).

**The patch header carries the gate**: `*** APPLY ONLY IF TRACE SHOWS
GFX_CmdQueAction / GFX_HwGetIdle EXECUTING ***`. R2 is the one row that can
*wedge* a driver loop (a flush waiting on an idle bit that never sets), so it
must be added with a trace-backed polarity.

### 4.1 One-command apply procedure

```bash
# 0. is it time, and does it still apply?  G3 and G4 must both PASS:
python3 evidence/bx510-guest/bdpdrv/decode/fb_gates.py RUN.mmio.log -v | \
    grep -E 'G3 |G4 '          # -> "PASS" on both lines

# 1. apply (either tool; both were verified to apply cleanly to the baseline
#    above and land the same bytes — sha256 cb6fb5fa98640dc2a4b10b5b90b531c1cbf905a4ceb06bdff78c00f32d44361d
#    on that base; a newer base gives a different sha but the same edits)
git apply -p1 evidence/bx510-guest/bdpdrv/decode/fb-gfx-rows.patch
#   or: patch -p1 < evidence/bx510-guest/bdpdrv/decode/fb-gfx-rows.patch

# 2. rebuild + re-fire with the trace on (see bdpdrv/run-c94-c95.md for the
#    full stub-probe recipe)
make vm-stage-file FILE=emulator-kit/sony-bx510.c     # then cp into ~/bx510-emu/emulator/
make sacd-emu-build
#    VM: BX510_TRACE=1 python3 bx510_bdpdrv_stub_probe.py ... --uart ... --unimp ...

# 3. re-gate: G3/G4 must stay PASS and G1 must not regress
python3 evidence/bx510-guest/bdpdrv/decode/fb_gates.py NEW.mmio.log -v
```

If the baseline tree has moved since staging, the hunks are small with ≥3 lines
of context and can be re-cut by hand; `git apply -3` also handles a moved base.

### 4.2 What to expect after applying, and the wedge tell

* `0x4004` reads start returning `1` and `0x400c`/`0x4134` reads start echoing
  the last write. G1 must still PASS.
* **Wedge tell:** if R2's polarity is wrong (bit0 = *busy*, not idle), a flush
  or wait loop will spin on `0x4004`. The trace signature is a read storm on
  offset `0x4004` with no forward progress, and `fb_gates.py` will still say
  G4 PASS — G4 only proves the read happened. Check the **count**: a handful of
  `0x4004` reads per action is normal; thousands means the polarity is
  inverted. (This is why the row is trace-gated and not shipped blind.)
* If G3 PASSes but the ring never drains, that is R12 (no engine consumer) —
  the model's job ends at "the ring was written", per `fb-surface.md` §4.2.

## 5. The two gates the trace cannot answer (run them when a shell exists)

`fb-surface.md` §4.3's payoff gates, one command inside the guest:

```sh
cat /proc/fb                                   # expect: "0 mt8530"
ls -l /dev/fb0                                 # expect: char 29,0
cat /sys/class/graphics/fb0/stride             # expect: 7680
cat /sys/class/graphics/fb0/virtual_size       # expect: 1920,2160
```

PASS on all four means the model already advertises the player's exact fb
geometry — the thing the HUD rig has been faking (`fb-surface.md` §5). No
script in this repo drives that yet; it is a shell-session observation, and it
is the cheapest remaining item in the fb lane.

## 6. Claims ledger

| Claim | Status | Receipt |
|---|---|---|
| `GFX_HwReset` runs to completion on the current (C96-era) model | VERIFIED (Run C95) | `fb_gates.py` G1 7/7; `.text 0x176898…0x176a78` |
| `GFX_CmdQue{Reset,Restore,Change}` run in C95 (`0x4008` stored twice) | VERIFIED | `W 0x4008 = 0x975e0000` ×2; owners `.text 0x1756d8/0x17607c/0x176130` |
| `GFX_CmdQueAction` never executed in C95 | VERIFIED (absence in a complete trace) | 0 unpaired `0x400c` writes; only `0x400c` writer besides CmdQueAction is `GFX_HwReset` (`--reach 0x7000400c`) |
| `GFX_HwGetIdle` never executed in C95 | VERIFIED (absence in a complete trace) | 0 reads of `0x4004`; only reader is `.text 0x177074` |
| `vFBDbgLog` output is gated off by default, so §4.3's UART gates are dark | VERIFIED (mechanism) + INFERRED (that nothing sets the flag) | `.text 0x14a010-0x14a01c`, literal `.bss+0x82888`; `_mt8530fb_probe` absent from all 19 captured UART logs |
| `0x4808` (RLE/SE queue base) is unmodelled but benign | VERIFIED (trace) | `W 0x4808 = 0x17750000` ×2, `unimplemented write 0x70004808`, run continues |
| R2's idle polarity is bit0 = 1 | **INFERRED, untested** | `and r3,r3,#1` `.text 0x177084`; no run has ever read `0x4004` |
| The patch applies cleanly and lands the intended edits | VERIFIED | `git apply -p1 --check` and `patch -p1` both succeed on the baseline and yield `cb6fb5fa…`; an earlier cut of the same edits was verified the same way (`88d555b0…`) |
| The fb probe registers a framebuffer in the guest | UNKNOWN | needs `/proc/fb` + sysfs (§5) |
