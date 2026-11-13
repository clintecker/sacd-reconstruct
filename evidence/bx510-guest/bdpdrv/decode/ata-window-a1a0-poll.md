# The a-window `0xfd00a1a0…0xfd00a1fc` block — who polls it, what it waits for, and the model rows that release it

**Scope.** C106's stub rebuild turned clidrive P3 (`drv.ide.pri_ver.initial 0 s 0`)
from a `[i4IdeHalSAtaReg(1072)]ERR:-4` early-out (C105) into
`[i4IdeHalSAtaReg(1151)](ERR)Ret:-6, ST:0x58` followed by a **timer-less spin**
on ATA-window offsets `0x1a0..0x1ac` and `0x1fc` (QEMU `-D` growing ≈28 MB/s).
This doc answers the four questions that spin raises — who reads the block, what
the block is, why the return code changed, and the minimal model rows that make
the poll exit — and nothing else.

**Deliverable.** This document (the model rows are §5; no tracked file was
modified: the rig's `emulator-kit/sony-bx510.c` is the model owner's edit).

**Inputs** (Mac-side, pinned):

| input | identity |
|---|---|
| `bdpdrv.ko` — the HAL that spins | sha256 `c146e0d6c8900d526c88017dc6ae561d407a366ff2959d66e68611c6b8a81c45`, 8 112 032 B, ARM `ET_REL`, `.text` `0x0..0x31d81c` |
| `sata_mt85xx_mod.ko` — the libata-side driver (negative control) | sha256 `8a0253eb9bff19a3d3c0ac594a507235bad82348d8e80069024368d0f5456657`, 69 452 B |
| `libata.ko` (stock 2.6.35, negative control) | 193 620 B |
| tools | `decode/resolve_addrs.py` (forward register dataflow, literal+immediate → PA), `decode/ata_probe_regs.py --scan` (module window scanner), `llvm-objdump -dr` |

**Labels.** **VERIFIED** = an instruction word, a relocation or a pool literal
fixes it (and where stated, the decode was replayed against those same bytes).
**TRACE** = a value measured in a run and supplied with the C105/C106 brief (the
`-D` trace and the two HAL log lines are VM-side; they are not re-measured here).
**INFERRED** = consistent with every instruction seen, not closed by one; the
settling experiment is named. Nothing below comes from eyeballing a hexdump: the
address joins are `resolve_addrs.py` output, the compare/branch semantics are
re-decoded from the instruction words by the replay in §5.4.

---

## 0. TL;DR

1. **Nothing in `sata_mt85xx_mod.ko` (or `libata.ko`) touches `0xa1a0..0x1fc`.**
   The block is read by **`bdpdrv.ko` only**, and by exactly **two**
   functions: `vIdeHalForceArbiterIdle` (`.text+0x9ec30`) and
   `vIdeHalForceHostIdle` (`.text+0x9ea88`) — the HAL's *error-recovery idle
   forcing* routines. VERIFIED (whole-window sweep + pool-word scan + module
   scanner negative control).
2. **The C106 spin is `vIdeHalForceArbiterIdle(ch=0, 1)`**, reached
   `i4IdeHalSAtaReg` → `vIdeHalErrorRecovery(ch,1)` → it. Its loop body reads
   `1fc, 1a0, 1a4, 1a8, 1ac` in exactly that order and its head re-reads `1fc`,
   i.e. **2 × `R a+1fc` per 1 × each of the other four** — the exact access mix
   and ordering the `-D` trace shows. VERIFIED (order + ratio replayed against
   the instruction bytes; TRACE for the observation).
3. **The exit condition is five exact values**: `(a+0x1fc & 0xfff) == 1`,
   `a+0x1a0 == 1`, `a+0x1a4 == 1`, `a+0x1a8 == 1`, `a+0x1ac == 1`. Not masks —
   the four words are compared to the *whole* value `1` (`cmp rN,#1`), so a
   model that returns `0x3` or `0xffffffff` spins just as hard as one returning
   `0`. There is **no timer, no counter and no delay call** anywhere in the
   loop. VERIFIED.
4. **The block is the SATA host/arbiter idle handshake** (four per-client
   idle-ack words + a 12-bit TRP-FIFO fill field), and it is *not* the SCR bank:
   the driver's SCR-shaped registers are `a+0x100..0x114`, one `0x100` stride
   under the taskfile. `a+0x1a0` is a different, upper block. INFERRED naming;
   VERIFIED placement (only the idle routines touch it, and only after an
   arbiter request in `a+0x108`/`a+0x208`).
5. **−6 vs −4 is not a hardware difference: the two returns are in different
   halves of the function.** −4 is the *pre-issue* event-group gate (line 1072,
   `mvn #3`, an OSAL event word *not an MMIO register*); −6 is the *post-wait*
   status classify (line 1151, `mvn #5`) on `a+0x01c & 0x88`. `ST:0x58` is
   `a+0x01c`, which **is** implemented (it is the model's `sata_st`), and
   `0x58 = DRDY|DSC|DRQ` — bit 3 (DRQ) is what trips the `BSY|DRQ` mask.
   VERIFIED (encodings + a classify replay).
6. **C105's success was a false pass.** Line 1072 returns *before*
   `vIdeHalSetXferReg`/`vIdeHalSendCmd`, so in C105 the ATA command was never
   issued at all — and `i4IdeHalTestInit` prints `Done!` without ever looking at
   `i4IdeHalTestIdDev`'s return value. The C106 stub rebuild did not break
   anything; it let the flow reach its first real gate. VERIFIED for the code
   shape, TRACE for the two runs.

---

## 1. Q1 — who reads `0xfd00a1a0 .. 0xfd00a1fc`?

### 1.1 The readers, from a whole-window sweep (not a grep)

`resolve_addrs.py` does the only join that works on this module: bdpdrv stores
the *virtual* address `0xfd00a000` in a literal pool (20 sites) and reaches
registers as `[rBase, #imm]`, so a `grep '#0x1a0]'` is meaningless (287 hits,
almost all struct fields; `#0x1a4]` 339, `#0x1a8]` 265, `#0x1ac]` 235,
`#0x1fc]` 300 — and exactly 6, 6, 6, 6, 4 of those are the a-window). The full
a-window sweep:

```
cd evidence/bx510-guest/bdpdrv/decode
python3 resolve_addrs.py --lo 0x7000a000 --hi 0x7000b000
```

52 distinct offsets are touched in `0x7000a000..0x7000afff`. The five that
matter, with **every** reader (this is the complete list — no other function in
bdpdrv.ko reaches these addresses):

| PA | readers (all) | accesses |
|---|---|---|
| `0x7000a1a0` | `vIdeHalForceArbiterIdle`, `vIdeHalForceHostIdle` | 6 `ldr` |
| `0x7000a1a4` | `vIdeHalForceArbiterIdle`, `vIdeHalForceHostIdle` | 6 `ldr` |
| `0x7000a1a8` | `vIdeHalForceArbiterIdle`, `vIdeHalForceHostIdle` | 6 `ldr` |
| `0x7000a1ac` | `vIdeHalForceArbiterIdle`, `vIdeHalForceHostIdle` | 6 `ldr` |
| `0x7000a1fc` | `vIdeHalForceArbiterIdle`, `vIdeHalForceHostIdle` | 4 `ldr` |

Per-site detail (`--reach`), the form the claim rests on:

```
python3 resolve_addrs.py --reach 0x7000a1a0
0x009eb24 R4 0xfd00a1a0 phys 0x7000a1a0  ldr       vIdeHalForceHostIdle
0x009eb2c R4 0xfd00a1a0 phys 0x7000a1a0  ldr       vIdeHalForceHostIdle
0x009eb68 R4 0xfd00a1a0 phys 0x7000a1a0  ldr       vIdeHalForceHostIdle
0x009eb98 R4 0xfd00a1a0 phys 0x7000a1a0  ldr       vIdeHalForceHostIdle
0x009ec70 R4 0xfd00a1a0 phys 0x7000a1a0  ldr       vIdeHalForceArbiterIdle
0x009eca0 R4 0xfd00a1a0 phys 0x7000a1a0  ldr       vIdeHalForceArbiterIdle
```

(`--reach` is silent for `0x7000a6c8` because that one is `pool(0xfd00a6c8) +
0x100*ch` with a live channel register — §6.3.)

### 1.2 Negative controls — the other two modules cannot be the reader

| control | result |
|---|---|
| `sata_mt85xx_mod.ko`: all `.text` words in `[0xfd00a000,0xfd00b000)` | 28 distinct pool words; **zero** in `0xfd00a1a0..0xfd00a1ff` VERIFIED |
| `sata_mt85xx_mod.ko`: constant-propagating window scan (`ata_probe_regs.py --scan`) | 15 distinct a-window offsets — `a00c a010 a014 a01c a108 a114 a220 a24e a24f a400 a600 a604 a610 a620 a634` — none in `0x1a0..0x1ff` VERIFIED |
| `sata_mt85xx_mod.ko`: only `[rN,#0x1xx]` immediates | 2, both `[r3,#0x1d0]` in `sata_mt85xx_PreparePwrOnParm`, base = pool `0xfd0241d0` (the FE/IR block, not the a-window) VERIFIED |
| `libata.ko`: words in `[0xfd00a000,0xfd00b000)` | **none** — libata does no MMIO of its own VERIFIED (`ide-hal-rows.md` §2.3). Its SCR read (INFERRED: `struct ata_ioports.scr_addr + 4*reg`, field `0x54` in `ata_probe_regs.py`'s `IOADDR_FIELDS`) lands in `a+0x100..0x114`, not `0x1a0` |

So: **`0xfd00a1a0…0xfd00a1fc` is a bdpdrv-only, error-recovery-only block.**

### 1.3 Where the spin sits in the call graph

```
i4IdeHalTestInit  .text+0xa0a28   ("… Done!" — prints without testing the return)
 └─ i4IdeHalTestIdDev  .text+0xa07e8
     └─ i4IdeHalAtaCmd  .text+0x9a470
         └─ i4IdeHalSAtaReg  .text+0x9ca10  (0x438 B)
             ├─ i4IdeHalPollingStReg .text+0x9af94   → the -6 (line 1151)
             └─ vIdeHalErrorRecovery  .text+0x9f228  (only when the poll's ret != 0)
                 ├─ vIdeHalForceArbiterIdle .text+0x9ec30   ← THE SPIN (r0=ch=0, r1=1)
                 ├─ vIdeHalForceArbiterIdle .text+0x9ec30   (r1=0: clears a+0x108 bit0)
                 └─ vIdeHalForceSataIdle    .text+0x9edec   (tail-calls ResetSataTrpFifo)
```

Call-site provenance (`llvm-objdump -dr`, `R_ARM_CALL`/`R_ARM_JUMP24`):

| callee | call sites (containing function) |
|---|---|
| `vIdeHalErrorRecovery` | `i4IdeHalPAtaReg` 0x9c728, `i4IdeHalPPktReg` 0x9c9bc, **`i4IdeHalSAtaReg` 0x9cdb4**, `i4IdeHalSPktReg` 0x9d46c, `_IdeHalIsrRoutine` 0x9de84 |
| `vIdeHalForceArbiterIdle` | `vIdeHalErrorRecovery` 0x9f248/0x9f254/0x9f268/0x9f274, `vIdeHalForceSataIdle` 0x9ee7c/0x9ee88 |
| `vIdeHalForceHostIdle` | `vIdeHalErrorRecovery` 0x9f23c + tail 0x9f260 — **nowhere else** |
| `vIdeHalForceSataIdle` | `vIdeHalErrorRecovery` tail 0x9f280 |

Two consequences worth recording:

* the −6 spin is **not P3-specific** — all four HAL command variants
  (`i4IdeHal{PAta,PPkt,SAta,SPkt}Reg`) and the ISR share this recovery tail, so
  any HAL command whose post-wait status has `BSY|DRQ` set wedges the same way;
* on the `r1 == 1` arm (`vIdeHalErrorRecovery` 0x9f264) `ForceHostIdle` is **not**
  called, which is why the C106 trace carries no `a+0x208` traffic: the reader
  is `ForceArbiterIdle`, not `ForceHostIdle`.

### 1.4 The access mix matches the trace (this is the attribution argument)

`vIdeHalForceArbiterIdle`'s loop body is `0x9ec68…0x9ec8c` (five loads into a
`.bss+0x16fa8` snapshot) falling through to the head at `0x9ec90`, which
short-circuits. Replaying that structure over the current model (every offset
reads 0) gives, per iteration:

```
first-12 reads: 1fc 1fc 1a0 1a4 1a8 1ac 1fc 1fc 1a0 1a4 1a8 1ac
counts over 1200 reads: {1a0:200, 1a4:200, 1a8:200, 1ac:200, 1fc:400}
```

i.e. **`R a+1fc` appears exactly twice per `R a+1a0`** and the five-offset
cluster repeats with no other address in it — the shape reported for the C106
`-D` log ("`00a1fc` + `00a1a0/a1a4/a1a8/a1ac`"). A cheap falsifier for the rig
owner: `grep -c 'R 00a1fc' trace` must be ≈ `2 ×` `grep -c 'R 00a1a0' trace`.
**1:1 means it is a different loop** (statistically it would then be
`ForceHostIdle`'s first spin, which reads `1a4,1a8,1ac` without `1fc`).

---

## 2. The poll, decoded verbatim

`vIdeHalForceArbiterIdle` (`0x9ec30`, 0xf0 B), `r0 = ch`, `r1 = assert/deassert`:

```
9ec30  cmp r1,#0 ; beq 0x9ece4                 ; r1 == 0 -> deassert path (no polls)
9ec38  cmp r0,#0 ; bne 0x9ecd4                 ; ch != 0 -> a+0x108 bit15 arm (no polls!)
9ec40  r3 = 0xfd00a000                         ; pool 0x9ed18
9ec44  r2 = [r3,#0x108] ; orr r2,#1 ; [r3,#0x108] = r2     ; arbiter-idle REQUEST (bit0)
9ec50  [r3,#0x108] x4                          ; four readbacks = write post-barrier
9ec60  r2 = 0x16fa8                            ; .bss snapshot buffer (pool 0x9ed1c)
9ec64  b 0x9ec90
9ec90  r1 = [r3,#0x1fc] ; lsl r1,#20 ; cmp r1,#0x100000 ; bne 0x9ec68
9eca0  r1 = [r3,#0x1a0] ; cmp r1,#1          ; bne 0x9ec68
9ecac  r1 = [r3,#0x1a4] ; cmp r1,#1          ; bne 0x9ec68
9ecb8  r1 = [r3,#0x1a8] ; cmp r1,#1          ; bne 0x9ec68
9ecc4  r1 = [r3,#0x1ac] ; cmp r1,#1          ; bne 0x9ec68
9ecd0  bx lr                                             ; EXIT
9ec68  [r2,#0x10] = [r3,#0x1fc] ; [r2,#0x0c] = [r3,#0x1a0]
9ec78  [r2,#0x00] = [r3,#0x1a4] ; [r2,#0x04] = [r3,#0x1a8]
9ec88  [r2,#0x08] = [r3,#0x1ac]  -> falls through to 0x9ec90
```

**Exit condition** (the five compares, with their decoded immediates):

```
(a+0x1fc << 20) == 0x100000   ⇔  (a+0x1fc & 0xfff) == 1
a+0x1a0 == 1        a+0x1a4 == 1        a+0x1a8 == 1        a+0x1ac == 1
```

* `lsl r1,r1,#20` keeps only the low 12 bits of `a+0x1fc`; the compared value
  `0x100000` is `1 << 20`. So `a+0x1fc = 0x1001` also exits, `0x2` does not —
  the field is **12 bits wide, idle value 1**.
* the four `cmp rN,#1` are *whole-word* equality (not `tst`), so upper bits must
  be zero: `0xffffffff` (a plausible "unread" default) spins forever.
* **no `bl`, no counter, no `vIdeOsDelay1ms`** in the loop: `0x9ec68…0x9ecd0`
  contains only loads/stores/compares/branches. This is why the `-D` log grows
  at disk speed — nothing yields the CPU.
* side effect: each pass overwrites a 20-byte debug snapshot at
  `.bss+0x16fa8` (`{1a4,1a8,1ac,1a0,1fc}` at `+0,+4,+8,+0xc,+0x10`), which is
  why a wedged run still holds readable last-values in RAM.

`vIdeHalForceHostIdle` (`0x9ea88`, 0x1a8 B) is the same handshake plus a
pre-phase and an `a+0x208` protocol — it is what runs on the
`vIdeHalErrorRecovery(ch, 0)` arm:

```
9ea88  cmp r0,#0 ; beq 0x9ebcc           ; r0 == 0 -> deassert: bic 0xe, bic 1 (a+0x208), bic 1 (a+0x108)
9ea90  r3 = 0xfd00a000 ; r1 = 0x16fa8
9ea98  [r3,#0x208] |= 0xe                ; host-idle request bits 1..3
9eab8  b 0x9ead4
9ead4  while ([r3,#0x1a4] != 1) { snapshot 1a4/1a8/1ac }     ; unbounded
9eae4  while ([r3,#0x1a8] != 1) { ... }
9eaf0  while ([r3,#0x1ac] != 1) { ... }
9eafc  [r3,#0x208] |= 0x1
9eb2c  while ([r3,#0x1a0] != 1) { snapshot 1a0 }
9eb3c  [r3,#0x108] |= 0x1
9eb88  loop { snapshot 1fc,1a0,1a4,1a8,1ac } while !(  (a+1fc & 0xfff)==1 &&
                                                         1a0==1 && 1a4==1 && 1a8==1 && 1ac==1 )
```

Note the asymmetry that makes ch 0 special: `vIdeHalForceArbiterIdle(ch != 0, 1)`
takes the `a+0x108 |= 0x8000` arm and **returns without any poll** (0x9ecd4),
while `ch == 0` takes the `|= 1` arm and polls. The CLI drive is channel 0, so
only the primary channel can hit this spin.

---

## 3. Q2 — what the block *is*

### 3.1 Placement in the a-window (what is around it)

The a-window is one `0x100`-strided ATA port (taskfile `+0x000..0x03f`, SCR
bank `+0x100..0x114`) plus an **upper "host/arbiter" block above `0x1a0`**:

| offset | owner(s) touching it | meaning (label) |
|---|---|---|
| `+0x000` | `sata_mt85xx_*`, HAL data port | PIO data port VERIFIED (model implements) |
| `+0x004..0x01c` | taskfile / `vIdeHalSendCmd` / `i4IdeHalPollingStReg` | ATA taskfile + status VERIFIED (model implements) |
| `+0x040`, `+0x058`, `+0x05c` | `vIdeHalSendPacket`, `i4IdeHalVen*` | packet/VEN path (not on P3) |
| `+0x078` | `i4IdeHalPollingStReg`, `i4IdeHalWaitStReg` | second status/alt-status port (model does **not** implement) |
| `+0x080..0x090` | `_vIdeHalQueGo.clone.9` | queue-go control |
| `+0x100` | `vIdeHalHostEnable`, `vIdeHalHostSetup` | host enable/control |
| `+0x108` | `vIdeHalHostSetup`, `vIdeHalRegDmaEnable`, **both idle routines**, `sata_mt85xx_trig_fe_boot` | FE data/start word — **bit0 = start/idle-request**, bit15 = FE doorbell (module `0x265c` `orr #1`; HAL `0x9ec44` `orr #1`, `0x9ecd8` `orr #0x8000`) VERIFIED |
| `+0x114` | `i4IdeHalInit`, `port_start` | per-channel enable bytes |
| `+0x164` | `vIdeHalHostSetup` | host timing |
| **`+0x198`** | the four `i4IdeHal*Que` routines | queue index/handle, logged only VERIFIED |
| **`+0x1a0 / 1a4 / 1a8 / 1ac`** | **only the two idle routines** | **four idle-ack words; each must read exactly 1** VERIFIED (access + compare), semantics INFERRED |
| **`+0x1fc`** | **only the two idle routines** | **12-bit fill/boundary field; must read 1** VERIFIED (mask + compare), semantics INFERRED |
| `+0x200` | `i4IdeHalInit`, `vIdeHalTestSscEnable` | SSC control |
| `+0x208` | `vIdeHalForceHostIdle` only | host-idle request/handshake word, RMW `|=0xe`, `|=0x1`, `bic` VERIFIED |
| `+0x220`, `+0x224` | `_u4IdeHalHwIntStatus`, `i4IdeHalWaitEvt` | ATA IRQ status (W1C) — model implements `0x220` |
| `+0x240..0x26c` | `port_start`, `vIdeHalSetDriving` | per-channel/PIO/DMA descriptors |

`0x62c`-style *low* offsets in the model source (see §6.3) are a different story;
nothing here is at `0x1a0` in PA space — the PA is `0x7000a1a0` (`VA =
PA + 0x8d000000`).

Provenance note: every row above except `+0x220`/`+0x224`/`+0x240..0x25c` comes
straight out of the `--lo/--hi` sweep. Those three rows carry a live
`+0x100*ch` base (`_u4IdeHalHwIntStatus`, the PIO/DMA descriptor writes), so the
resolver cannot fold them into a constant address; they rest on the pool words
(`0xfd00a220` ×2, `0xfd00a224` ×2, `0xfd00a24c` ×2, `0xfd00a25c` ×2) plus
`ide-hal-rows.md` §2.2 / `ata-probe-path.md`, and are not part of this claim.

### 3.2 The semantic reading (INFERRED, with the reasoning chain)

The evidence fixes the *required values* and the *protocol shape*; it does not
name the silicon. What the instructions do fix:

1. The four words sit in a block that only the **idle-forcing** routines read,
   and they are read **only after** a request bit is written (`a+0x108` bit0 for
   the arbiter arm, `a+0x208` bits 1..3 + bit0 for the host arm).
2. Each of the four must be **exactly 1** — a single-bit "done/ack" flag per
   word (a status *bitfield* would be tested with `tst`; whole-word equality to 1
   is how a "one flag word" reads).
3. `a+0x1fc` is tested through a **12-bit** extract and must read 1 — a
   fill/pointer field settling to its idle boundary, not a flag.
4. The recovery sequence ends by **resetting the TRP FIFO**
   (`vIdeHalResetSataTrpFifo`, `0x9ed20`, writes `a+0x680` bit0), and the same
   driver logs `"[%s(%d)](SATA IF ERR)TRP CRC_ERR:0x%x"` (`.rodata.str1.1+0x2eb4a`) —
   the TRP engine is a named unit in this HAL.
5. `vIdeHalForceSataIdle` (`0x9edec`) completes the picture with the PHY/link
   side: `a+0x6b8 == 1` = link idle, `a+0x6b8 == 0x40000` = the
   COMRESET/SYNC-ESC state (its own log strings `"(0x%x, 0x%x)SYNC ESC"` /
   `"COMRESET"`, `.rodata.str1.1+0x2e963/0x2e981`, function name printed as the
   literal `"XXX"`), `a+0x648` bits `[12:8]` = per-channel state (`7` = done),
   `a+0x640/0x644/0x6c0` = per-channel control/status RMW.

**Reading:** `0x1a0..0x1ac` = *arbiter-client idle acknowledgements* (one word
per client; the client↔word mapping is not established by this decode) and
`0x1fc` = *TRP transport-FIFO fill/boundary* (idle = 1). **Settling experiment**
(name it, don't assert it): on the real player, read `a+0x1a0..0x1ac`/`a+0x1fc`
from the stick-side client after an ATA error and after an idle period — the
values on real silicon either match the `1/1/1/1/1` pattern (this recipe is
literally right) or reveal the settled pattern the driver accepts.

**What it is not:** these are not the SATA SCR registers. libata's SCR bank is
`ioaddr->scr_addr + 4*reg` and the driver's SCR-shaped offsets are
`a+0x100..0x114` (SStatus/SError/SControl/SActive/SNotification/SControl). The
`0x1a0` block sits above both the taskfile port and its SCR bank, and is not
touched by libata at all (§1.2).
---

## 4. Q3 — why −4 (line 1072) vs −6 (line 1151)

### 4.1 The return codes, decoded from the `mvn` encodings

`i4IdeHalSAtaReg` and its poller use the ARM idiom `mvn rN,#k` → `~(k)`:

| value | site | encoding | meaning |
|---|---|---|---|
| `-2` | `i4IdeHalPollingStReg` 0x9b0f8 (`mvn r2,#1`) | `e3e02001` | poll timer expired (line 1164 `TIMEOUT !!`) |
| `-3` | `i4IdeHalPollingStReg` 0x9b094 (`mvn r2,#2`) | `e3e02002` | event-group bit1 seen mid-poll; **downgraded to 0** at 0x9b13c if `(st & mask) == 0` |
| `-4` | `i4IdeHalSAtaReg` 0x9cac4 (`mvn r3,#3`) | `e3e03003` | **event-group bit1 at function entry — before the command is issued** |
| `-5` | `i4IdeHalPollingStReg` 0x9b12c (`mvn r2,#4`) | `13e02004` | post-wait classify: `a+0x01c & 0x1` (ERR) |
| `-6` | `i4IdeHalPollingStReg` 0x9b120 (`mvn r2,#5`) | `13e02005` | post-wait classify: `a+0x01c & 0x88` (BSY\|DRQ) |

### 4.2 The two log sites, with `__LINE__` and format strings

Both lines are in `i4IdeHalSAtaReg` (`0x9ca10`) and both carry the function name
from `.rodata+0x1296ec = "i4IdeHalSAtaReg"`:

| log line | site | `__LINE__` source | format |
|---|---|---|---|
| `[i4IdeHalSAtaReg(1072)]ERR:%d` | `0x9caf8` | `mov r2,#1072` @ `0x9caf4` (literal immediate) | `.rodata.str1.1+0x2e509` = `"[%s(%d)]ERR:%d\n"` |
| `[i4IdeHalSAtaReg(1151)](ERR)Ret:%d, ST:0x%x` | `0x9cd24` | pool `0x9ce3c` = `0x47f` = **1151** | `.rodata.str1.1+0x2e519` = `"[%s(%d)](ERR)Ret:%d, ST:0x%x\n"` |
| `[i4IdeHalSAtaReg(1142)](ERR)CmdWaitEvtRet:%d` | `0x9ccac` | pool `0x9ce34` = `0x476` = 1142 | `+0x2e537` |
| `[i4IdeHalSAtaReg(1164)]TIMEOUT !!` | `0x9cd8c` | pool `0x9ce40` = `0x48c` = 1164 | `+0x2e556` |

`C106` printed the **1151** form → the failure is the **post-wait status
classify**, not the event wait (that would have been 1142) and not the timeout
(1164). TRACE for the line, VERIFIED for which site emits it.

### 4.3 What `-6 with ST:0x58` means

```
i4IdeHalSAtaReg 0x9cccc  r0 = ch ; r1 = 0x88          ; mask = bit7 BSY | bit3 DRQ
i4IdeHalSAtaReg 0x9ccdc  bl i4IdeHalPollingStReg      ; (ch, 0x88, timeout=arg7, &st)
i4IdeHalPollingStReg:
  0x9af94..0x9b0a8   timed poll of a+0x01c(+0x40 for odd ch): exits on
                     (st & 0x88) != 0  ||  (st & 0x7f) == 0x7f
  0x9b10c..0x9b130   re-read a+0x01c, then classify:
                       if (st & 0x88) -> -6
                       else if (st & 1) -> -5
                       else 0
  0x9b148            strne st, [out]      ; ST = the status word itself
```

Replay of that classify against the model's own served status (the model writes
`s->sata_st = 0x58` when the command completes, `sony-bx510.c` PIO/cmd path):

| `a+0x01c` | `st & 0x88` | Ret |
|---|---|---|
| `0x58` | `0x08` | **−6** |
| `0x50` | `0x00` | 0 |
| `0x48` | `0x08` | −6 |
| `0x40` / `0x00` | `0x00` | 0 |
| `0x01` | `0x00` | −5 |

`0x58 = DRDY(0x40) | DSC(0x10) | DRQ(0x08)`. The HAL's verdict is *correct for
this model*: DRQ says "the device has a data phase pending", and the model has
no data path for the IDENTIFY payload (it rides the unimplemented DMA register
`a+0x24c`). So `-6` is the HAL refusing to pretend a transfer happened.

### 4.4 Why C105 got −4 instead — and why that "success" was a false pass

The −4 gate is at the **top** of `i4IdeHalSAtaReg`, before any MMIO command
work:

```
0x9ca5c  bl i4IdeHalFlushEvt(ch, 0)                  ; drains a+0x220 (model: 0)
0x9ca68  if (ret < 0) -> log(1065) and return
0x9ca9c  bl i4IdeOsEventValue(_hIdeHalChEvt[ch], &ev)  ; OSAL event group, NOT MMIO
0x9cab8  if (ev & 2) -> 0x9cac4  mvn r3,#3 (= -4) -> log(1072) -> return
0x9cb14  … only past this point does the ATA command get issued:
         fgIdeHalIsDmaMode / vIdeHalSetXferReg / vIdeHalSendCmd (writes a+0x01c)
         / i4IdeHalWaitEvt / i4IdeHalPollingStReg
```

`i4IdeOsEventValue` (`0xa7080`) is a thin wrapper over the **imported**
`x_ev_group_get_info` (undefined in bdpdrv.ko — it comes from the OSAL module,
i.e. the C105/C106 `osal_stub.ko`): it writes the group's info word to the
caller's out pointer, and bit 1 of that word is what the HAL treats as "this
channel's event state forbids starting a command".

So the C105→C106 flip is a **stub/OSAL behaviour change, not a hardware or HAL
change**: C105's stub reported `info & 2` set (early-out at 1072, *nothing
issued*), C106's reports it clear (flow proceeds to the real command and the
real status gate). Two consequences:

1. **C105's `CH:0, SataDev:1, UseQueue:0 Done!` was not evidence of anything
   working** — `i4IdeHalTestInit` (`0xa0c38`) calls `i4IdeHalTestIdDev`, stores
   its return in `r5`, frees the buffer and prints `Done!` at `0xa0c7c`
   *without ever branching on `r5`*. The "Done!" banner is unconditional; only
   the `(ERR)` lines inside the HAL carry a verdict.
2. **The OSAL stub's event-group info word bit 1 is now a load-bearing knob**:
   with it set, P3 never issues a command; with it clear, P3 reaches the status
   classify. If the goal is "exercise the ATA path", the stub must keep bit1
   clear — and the *falsifiable* confirmation is that C106's trace contains a
   `SATA WR a+01c` (the command byte `0xa1`) that C105's does not.

---

## 5. Q4 — the model rows

Model source: `emulator-kit/sony-bx510.c`, `bx510_read`/`bx510_write` switch on
`off` (PA relative to `BX_IO_BASE = 0x70000000`, so **the a-window rows are
written `0xa1a0…`, not `0x1a0`**). Tier A is all-new (those five offsets are
absent from both switches today → `default:` → return 0 / `LOG_UNIMP` +
`LOG_GUEST_ERROR`); Tier B marks which rows are new and which amend an existing
one.

### 5.1 Tier A — required for the -6 poll to EXIT (the rows this decode adds)

| # | offset | access | model value | why (VERIFIED against the disassembly) |
|---|---|---|---|---|
| A1 | `0xa1a0` | R | `return 1` | `cmp r1,#1` @ `0x9eca4` — exact whole-word equality |
| A2 | `0xa1a4` | R | `return 1` | `cmp r1,#1` @ `0x9ecb0` |
| A3 | `0xa1a8` | R | `return 1` | `cmp r1,#1` @ `0x9ecbc` |
| A4 | `0xa1ac` | R | `return 1` | `cmp r1,#1` @ `0x9ecc8` |
| A5 | `0xa1fc` | R | `return 1` | `(r1<<20) == 0x100000` @ `0x9ec94/0x9ec98` — 12-bit field, value 1 |

```c
    /* ---- a-window: SATA host/arbiter idle handshake (bdpdrv
     * vIdeHalForceArbiterIdle .text+0x9ec30 / vIdeHalForceHostIdle .text+0x9ea88).
     * Read ONLY by those two error-recovery routines, and only after the
     * arbiter-idle request bit is written (a+0x108 bit0 / a+0x208 bits 1..3).
     * EXIT CONDITION (decode/ata-window-a1a0-poll.md §2):
     *   (a+0x1fc & 0xfff) == 1 && a+0x1a0 == 1 && a+0x1a4 == 1 &&
     *   a+0x1a8 == 1 && a+0x1ac == 1        <- whole-word equality, not masks
     * The loop has no timer and no delay, so serving anything else is an
     * unbounded spin. The controller is modelled as always-idle: the driver
     * only ever tests the settled value, never a transition. */
    case 0xa1a0: case 0xa1a4: case 0xa1a8: case 0xa1ac: case 0xa1fc:
        return 1;
```

### 5.2 Tier B — required for the *recovery path* to finish (next two blockers, same path)

Tier A alone stops the 28 MB/s storm but the same `i4IdeHalSAtaReg` call still
never returns: `vIdeHalForceSataIdle` and `vIdeHalResetSataTrpFifo` run next and
each has its own unbounded poll.

| # | offset | access | model value | why (VERIFIED) |
|---|---|---|---|---|
| B1 | `0xa6b8` | R | `return 1` | `vIdeHalForceSataIdle` 0x9f0e4/0x9f0e8: `while ([a+0x6b8] != 1)` — no bound; the only guard is a counter into `Assert()` (imported; its noreturn-ness is not established here). `1` = link idle; `0x40000` = the COMRESET/SYNC-ESC state it logs (0x9ef58) |
| B2 | `0xa680` | W | `s->sata_a680 = val & ~1u;` | `vIdeHalResetSataTrpFifo` 0x9ed3c writes `a+0x680 \|= 1`, then 0x9edbc/0x9edc0 polls `while ([a+0x680] & 1)` — the written value is stored today, so bit0 stays set and the loop never ends. bit0 is a self-clearing "reset TRP FIFO" trigger |
| B3 | `0xa208` | RW | `s->sata_a208 = val;` (read returns it) | `vIdeHalForceHostIdle` RMWs `\|=0xe` (0x9ea9c), `\|=0x1` (0x9eb04), `bic 0xe`/`bic 1` (0x9ebd4/0x9ebf0). Nothing gates on the read value, but a dropped write makes the deassert path clear bits that were never set — a lossless store is the house rule for every RMW register |

```c
    /* B1 — new row */
    case 0xa6b8: /* PHY/link state word. 1 = link idle (vIdeHalForceSataIdle's
                  * completion value); 0x40000 = COMRESET/SYNC-ESC. The FE
                  * transfer path waits for 0x200000 here — that poll cannot
                  * pass at 1 any more than it can at the current 0, so this
                  * row moves the idle path without touching that one. */
        return 1;
    /* B2 — existing row, add the self-clearing mask */
    case 0xa680:
        s->sata_a680 = val & ~1u;   /* bit0 = TRP-FIFO reset, self-clearing */
        break;
    /* B3 — new row */
    case 0xa208: /* host-idle request/handshake word: plain RMW readback */
        s->sata_a208 = val;
        break;
```

Caveat to state loudly for B1: `a+0x6b8` is a **multi-state** word, not a flag.
Its other observed states are `0x40000` (link fault) and `0x200000` (FE transfer
complete, polled by `sata_mt85xx_data_xfer`/`_hw_chg_st` and by
`i4IdeHalSAtaReg`'s own `r8 == 2` branch at `0x9cbe4`). Serving `1`
unconditionally is safe *today* only because those consumers already hang on the
current `0`; if the FE transfer path is ever made to work, this row must become
conditional on "no FE transfer outstanding". The alternative (leave `a+0x6b8`
at 0) means accepting that the HAL call never returns — the spin becomes a
1 ms-delay loop instead of a hot loop, which is quieter but still a wedged
thread.

### 5.3 Write side of the handshake (what the loop writes first, and what must not change)

| offset | write seen | current model | verdict |
|---|---|---|---|
| `0xa108` bit0 | `vIdeHalForceArbiterIdle` 0x9ec44 `\|=1`, cleared at 0x9ecf8 (`biceq #1`) | `s->sata_a108 = val & ~0x8000u` — bit0 stored ✔ | **keep**. bit0 is shared with `sata_mt85xx_trig_fe_boot` (`0x2658` `orr #1`, cleared by the module itself at `0x2664`), so a HAL set/clear pulse is invisible to the FE path |
| `0xa108` bit15 | `ForceArbiterIdle(ch!=0,1)` 0x9ecd8 | dropped as the FE doorbell | keep (ch≠0 arm polls nothing) |
| `0xa208` | `ForceHostIdle` | **unimplemented** (dropped) | add the store (B3) |

No new write semantics are needed for the five Tier-A offsets: the driver never
writes them (all six accesses per offset are `ldr`). The request/start bit lives
in `a+0x108`, and the existing behaviour already satisfies it.

### 5.4 Verification of the recipe (replay over the real instruction bytes)

The loop was re-simulated from the decoded immediates (`cmp #1` / `lsl #20` /
`cmp #0x100000`), with the model's values as input, including mutants that must
fail:

```
AS-IS model (five offsets unmodelled, read 0)     SPIN  iters>2000  1fc 1fc 1a0 1a4 1a8 1ac …
RECIPE  (1a0/1a4/1a8/1ac = 1, 1fc = 1)            EXIT  iters=1     1fc 1a0 1a4 1a8 1ac
mutant 1fc = 0x1001  (low 12 bits 1, upper set)   EXIT  iters=1     (proves the 12-bit extract)
mutant 1fc = 0x2                                  SPIN              (boundary off by one)
mutant 1a0 = 3                                    SPIN              (whole-word equality)
mutant 1a8 = 0xffffffff                           SPIN              ("unread" default)
mutant 1ac = 0x10                                 SPIN              (bit4 only)
```

A check that cannot fail is not a check: the four `SPIN` mutants are what makes
the `EXIT` meaningful.

---

## 6. Corrections and side-findings this decode forces

### 6.1 `ide-hal-rows.md` §5.1 / §5.4 mislabel the two post-wait returns

That section predicts `[i4IdeHalSAtaReg(0)](ERR)Ret:-5, ST:0x58` and describes
the classify as `mask -> -5`, `bit0 -> -4`. Decoded from the encodings
(`13e02005` = `mvn #5` = **−6**; `13e02004` = `mvn #4` = **−5**), the real
mapping is `a+0x01c & 0x88 -> -6` and `a+0x01c & 1 -> -5`. C106's own
`Ret:-6, ST:0x58` is the confirming observation. §5.4's verdict row
`(ERR)Ret:-5, ST:0x58` should read **−6**; there is no −5 in the `ST:0x58`
case (0x58 has bit0 clear). The `(0)` in the predicted line was the
`__LINE__` placeholder — the real line is 1151.

### 6.2 The −6 is *not* a regression from the C106 stub rebuild

It is the first real gate after an early-out that used to hide the command
entirely (§4.4). Any future stub change that clears the event-info bit1 will
"regress" every HAL command to −6 until `a+0x01c` stops asserting DRQ *or* the
model serves the data phase. Expected, not new.

### 6.3 Two stale rows in the model source

`sony-bx510.c` carries `case 0x6c8: /* IRQ mask */` and `case 0x62c: /* global
ctrl */`. Those are **PA** `0x700006c8` / `0x7000062c`, and bdpdrv never names
either address (pool-word scan: `0xfd0006c8` = 0 occurrences, `0xfd00062c` = 0).
The driver's a-window versions are `0xfd00a6c8` (5 pool words, IRQ mask, read by
`vIdeHalChkSataError`) and `0xfd00a62c` (1 pool word, `fgIdeHalTestABIST`), so
both rows are dead code today. Nothing on the −6 path blocks on them —
`vIdeHalChkSataError` polls `a+0x6c4 & a+0x6c8`, and with both reading 0 the
drain loop exits immediately — but an a-window `0xa6c8` row is what the driver
actually addresses if that mask ever needs to be real.

### 6.4 The `-4` line number is a literal, the others are pool words

`mov r2,#1072` is an immediate (1072 is not ARM-immediate-encodable as a pool
word here for the other sites, they use `.rodata` words: 1065 / 1142 / 1151 /
1164). Anyone re-deriving line numbers from `.rodata` alone will find 1072
missing for exactly this reason.

---

## 7. Residual risks / next experiments

1. **`a+0x1a0..0x1ac` client mapping** is INFERRED. The rows only need the
   settled value 1, so the model is safe either way; a real-hardware read is the
   only way to close it (§3.2).
2. **`a+0x1fc` field width** is proven 12 bits; whether the *hardware* idles at
   1 or the driver merely accepts 1 is not provable from this module. If the
   real device is ever observed, prefer its value inside the 12-bit window.
3. **The `0x58 → 0x50` alternative** (avoid −6 entirely by dropping DRQ after an
   unserved data phase) is `ide-hal-rows.md` §7.2's open row and is a
   model-owner decision: `sata_st = 0x58` is also what libata's PIO drain wants,
   so changing it blind trades one wedge for another. The Tier-A/B rows above
   are the safe side of that trade — they make the *recovery* terminate without
   changing the verdict the HAL reaches.
4. **`Assert()`'s noreturn-ness** is not established (it is imported). If it is
   fatal on this build, B rows are still required but the failure mode is a
   panic instead of a slow spin.
5. **Falsifier for this whole decode** (cheap, on the rig): with Tier A+B in
   place, P3 must (a) still print `[i4IdeHalSAtaReg(1151)](ERR)Ret:-6, ST:0x58`,
   (b) *return* (the `Done!` banner appears and the next command runs), and
   (c) show `R a+1fc : R a+1a0` ≈ 2:1 in the pre-fix trace and no unbounded
   growth after the fix.

---

## 8. Reproducibility

```
# the five readers (complete list) and the whole a-window footprint
cd evidence/bx510-guest/bdpdrv/decode
python3 resolve_addrs.py --lo 0x7000a000 --hi 0x7000b000
python3 resolve_addrs.py --reach 0x7000a1a0        # (also 1a4 / 1a8 / 1ac / 1fc)

# the loop, with relocations resolved
llvm-objdump -dr --start-address=0x9ec30 --stop-address=0x9ed20 /tmp/bdpdrv/bdpdrv.ko   # ForceArbiterIdle
llvm-objdump -dr --start-address=0x9ea88 --stop-address=0x9ec30 /tmp/bdpdrv/bdpdrv.ko   # ForceHostIdle
llvm-objdump -dr --start-address=0x9edec --stop-address=0x9f228 /tmp/bdpdrv/bdpdrv.ko   # ForceSataIdle
llvm-objdump -dr --start-address=0x9ed20 --stop-address=0x9edec /tmp/bdpdrv/bdpdrv.ko   # ResetSataTrpFifo
llvm-objdump -dr --start-address=0x9f228 --stop-address=0x9f2ac /tmp/bdpdrv/bdpdrv.ko   # ErrorRecovery
llvm-objdump -dr --start-address=0x9af94 --stop-address=0x9b180 /tmp/bdpdrv/bdpdrv.ko   # PollingStReg
llvm-objdump -dr --start-address=0x9ca10 --stop-address=0x9ce48 /tmp/bdpdrv/bdpdrv.ko   # SAtaReg (-4/-6 sites)

# negative controls
python3 - <<'PY'
from elftools.elf.elffile import ELFFile
import struct, collections
for ko in ('/tmp/bdpdrv/sata_mt85xx_mod.ko','/tmp/bdpdrv/libata.ko'):
    d=ELFFile(open(ko,'rb')).get_section_by_name('.text').data()
    w=collections.Counter()
    for i in range(0,len(d)-3,4):
        v=struct.unpack('<I',d[i:i+4])[0]
        if 0xfd00a000<=v<0xfd00b000: w[v]+=1
    print(ko, {hex(k):v for k,v in sorted(w.items())})
PY
python3 evidence/bx510-guest/bdpdrv/decode/ata_probe_regs.py --scan   # module window scan
```

---

## 9. Claim ledger

| claim | status |
|---|---|
| `0xa1a0/1a4/1a8/1ac/1fc` are read by exactly two functions, both in bdpdrv.ko | VERIFIED (`resolve_addrs --lo/--hi` + `--reach`) |
| neither `sata_mt85xx_mod.ko` nor `libata.ko` names or reaches them | VERIFIED (pool-word scan + module scanner) |
| the C106 spin is `vIdeHalForceArbiterIdle(ch=0, r1=1)` via `vIdeHalErrorRecovery(ch,1)` | VERIFIED (call graph) + TRACE (access order/ratio match) |
| exit = `(a+0x1fc & 0xfff)==1 && a+0x1a0==1 && a+0x1a4==1 && a+0x1a8==1 && a+0x1ac==1` | VERIFIED (immediates re-decoded from the words) |
| the loop has no timer, counter or delay | VERIFIED (`0x9ec68..0x9ecd0` has no `bl`, no `cmp` against a tick) |
| `-6` = `mvn #5` = `(a+0x01c & 0x88) != 0`; `-5` = `mvn #4` = `(a+0x01c & 1)` | VERIFIED (`13e02005` / `13e02004`) |
| `ST:0x58` is `a+0x01c` from the implemented `sata_st`; 0x58 = DRDY\|DSC\|DRQ, DRQ trips the mask | VERIFIED (classify replay) |
| `-4` (line 1072) is the pre-issue OSAL event-group bit1 gate, taken before any command is issued | VERIFIED (code shape) + INFERRED (that this is what the stub changed between C105 and C106) |
| C105's `Done!` did not test the HAL return | VERIFIED (`i4IdeHalTestInit` 0xa0c38/a0c7c) |
| the block is the "arbiter idle handshake + TRP fill" (names) | INFERRED (placement + protocol shape VERIFIED; silicon naming open — §3.2) |
| Tier-A rows make the poll exit; Tier-B rows make the recovery return | VERIFIED (replay + mutants) |

---

### One-line summary

The `0xfd00a1a0..0xfd00a1fc` block has exactly two readers, both bdpdrv error-recovery
idle-forcers: the C106 spin is `vIdeHalForceArbiterIdle(0,1)`'s timer-less loop, which
exits only when `a+0x1a0/1a4/1a8/1ac` each read **exactly 1** and `a+0x1fc & 0xfff == 1`;
`-6, ST:0x58` is the post-wait classify on the *implemented* status register `a+0x01c`
(DRQ set, no model data path), while C105's `-4` was a pre-issue OSAL event gate that
meant no command was ever sent — so serving `1` at those five offsets (plus link-idle at
`a+0x6b8` and a self-clearing `a+0x680` bit0) is the minimal model change that releases
the wedge.
