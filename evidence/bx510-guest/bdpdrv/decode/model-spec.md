# bdpdrv.ko MMIO hot set — register-level model spec

Date: 2026-11-12. Decode of the Run C50 MMIO trace against Sony's display
driver. Deliverable of the Stage-1 analyst step for S5 Phase C: what the QEMU
device model must implement, register by register.

**House rules.** Every claim is labelled **VERIFIED** (disassembly-evidenced —
I read the instruction) or **INFERRED** (pattern/behaviour-based). Nothing here
is a guess dressed as a fact; §8 lists what did not resolve.

## 0. Provenance

| input | identity |
|---|---|
| `bdpdrv.ko` | sha256 `6604f6cd6c204c3399ac047f389f47162b06a3f6576159f21b4e8aaf3a72cf54`, 8,122,068 B, ELF32 ARM `ET_REL` (relocatable module), unstripped, 42,036 symtab entries |
| MMIO trace | `bdpdrv-runC50.mmio.log`, sha256 `e3ccf142787836c037c28022fca1da883d34910908a9af066352d03d97208026`, 33,993 unimplemented accesses over 1,908 distinct addresses |
| UART transcript | `bdpdrv-runC50.uart.log` — supplies thread identity (§5) |
| tools | llvm-objdump 22.1.2, pyelftools 0.33, Python 3.12.7 |

Exact trace totals (recomputed, not carried over from `run-c50.md`):
**23,970 reads / 10,023 writes**, 807 distinct read addresses, 1,370 distinct
write addresses.

## 1. The one thing that unlocks this binary: address arithmetic

**VERIFIED.** bdpdrv never stores a guest-physical address. It stores the
kernel's *static IO mapping* virtual address, and reaches registers as
`[rBase, #imm]` — often with a **negative** immediate against a base
pre-biased to a block's last byte:

```
0x318fe4 <i4VFDIndirectSIFCmdRegMode>:
  319010:  ldrb  r2, [r4, #0x3]
  319014:  ldr   r5, [pc, #0xd0]        @ 0x3190ec     <- literal-pool word
  319018:  orr   r3, r3, r2, lsl #24
  31901c:  str   r3, [r5, #0x300]                      <- 0x70050300
```
The literal at `.text+0x3190ec` is `0xfd050000`. A block base is sometimes
pre-biased instead, e.g. `0xfd039fff` used as `[r1, #-0xfff]` → `0xfd039000`.

**Calibration of the mapping (VERIFIED).** `virt - phys` is a single constant
`0x8d000000`:

```
$ python3 resolve_addrs.py --calibrate
distinct 0xfd literal words referenced by .text: 295
distinct addresses in the Run C50 trace:         1908
  delta 0x8d000000:   46 literal words land exactly on a traced address
  delta 0x8c000000:    0
  delta 0x8e000000:    0
  delta 0x8f000000:    0
  delta 0x88000000:    0
  delta 0x90000000:    0
```

So: **`phys = virt - 0x8d000000`**, and the IO window is
`0xfd000000..0xfdffffff` ↔ `0x70000000..0x70ffffff`. A search for the plain
physical form (`0x7002420c`, `0x70050300`, …) or the `|0xf0000000` /
`|0xc0000000` aliases finds **zero** hits, which is why the earlier
"search literal pools for 0x70024xxx" plan looked like a dead end.

**Coverage achieved (VERIFIED):** the resolver attributes **91.5% of all
traced traffic** (31,120 of 33,993 accesses) to a concrete instruction, and
**100% of the primary hot set**. The residual 8.5% is a long tail of 1,464
low-count addresses — see §8.

## 2. What the hot set actually is

The prior note called this a "descriptor/DMA engine handshake". It is not.
The hot set is **three unrelated peripheral blocks**, each driven by its own
kernel thread:

| block | physical range | what it is | driver subsystem |
|---|---|---|---|
| A | `0x70024000`–`0x70024fff` | front-end shared control: IR RX, CEC, DDC, SIF, VFD bridge | `irrx_if.c`, `cec*`, `ddc*`, `vfd*` |
| B | `0x70050300`–`0x70050320` | **VFD front-panel MCU serial command interface** ("IFcon"/SIF) | `i4VFD*` |
| C | `0x70047100`–`0x70047110` | **audio DSP load-table port** | `aud_hal_8560.c` |

The 12,014-read "dominant poll" is the **infrared remote receiver**, not a
display engine. The 1,232-iteration "6-register burst" is the **front-panel
display/key-scan command pump**, not a DMA descriptor ring.

## 3. Per-register table — primary hot set

Counts are exact from the trace. "Owner" is the function containing the
instruction; "executed" is the function the trace shows running (see §5 for
how that is established). All widths are 32-bit (trace reports `(4)`).

### 3.1 `0x7002420c` — IR RX configuration/status, word 0 (R=12,013 / W=1)

| field | meaning | evidence |
|---|---|---|
| bit 0 | **RX enable** | VERIFIED: `IR_RxEnable` `orr r1,r1,#1` @0x30ff00 (enable) / `bic r2,r2,#1` @0x30ff60 (disable) |
| bit 18 (`0x40000`) | **data-available / packet-complete** — what the poll tests | VERIFIED: `IRRX_PollMtkIr` `tst r2,#262144` @0x3102e0 |
| rest | RX configuration (written wholesale from the caller's config block) | INFERRED |

- Written once in the whole run: `0x111` — trace line 5791, inside the
  `IRHW_RxInit` sequence. **VERIFIED** by access order: the surrounding lines
  reproduce `IRHW_RxInit`'s instruction sequence one-for-one.

  ```
  5790  write 0x70024080 = 0x0      @0x30ffe8-0x30fff0  bic #256
  5791  write 0x7002420c = 0x111    @0x30fff4  str r5,[r3,#0x20c]  conf0
  5792  write 0x70024210 = 0xe1     @0x30fff8  str r4,[r3,#0x210]  conf1
  5793  write 0x70024214 = 0x200    @0x30fffc  str r7,[r3,#0x214]  conf2
  5795  write 0x70024040 = 0x0      @0x310000-0x310008  bic #2
  5797  write 0x70024188 = 0x0      @0x31000c-0x310014  bic #1048576
  5799  write 0x70024044 = 0x3      @0x310018-0x310024  bic #15 / orr #3
  5801  write 0x70024218 = 0x1      companion word
  5803  write 0x70024148 = 0x2000   ISR binding, bit 13
  5805  write 0x70024144 = 0x2000   @0x310050-0x310054  orr #8192  IRQ enable
  ```

  Programmed configuration: **conf0 = `0x111`, conf1 = `0xe1`, conf2 = `0x200`**
  (values VERIFIED; reading them as timing/threshold setup is INFERRED).
  Note bit 18 — the bit the poll tests — is *not* set by the driver's own conf.
- Read 12,013 times by `IRRX_PollMtkIr` @0x3102dc — **one `ldr` per call**,
  no spin loop. First read is trace line 5843, right after the init sequence.
  The call count is thread cadence, not a hardware stall.
- Companion words: `0x70024210` (conf1), `0x70024214` (conf2) — written as a
  triple by `IRHW_RxWrConf` @0x30fec8/0x30fecc/0x30fed0, read as a triple by
  `IRHW_RxRdConf` @0x30fe98–0x30fea8. **VERIFIED.**

### 3.2 `0x700240f4` — shared per-subsystem pending/ack (R=1,237 / W=1,237)

A **shared** register: each subsystem clears its own bit field with
read-modify-write. Owner list (VERIFIED; full form in `hotset-functions.txt`):

| field | owner | operation |
|---|---|---|
| bits 3:0 | `i4VfdScanKeyWithDriver` @0x31a2f4 (`bic #15`) | cleared before every VFD key scan — **this is the per-iteration RMW** |
| bit 0 | `IFcon_Init` @0x30faa4 (`bic #1`) | init ack |
| bits 3:0 | `i4VFD_Resume` @0x319ff8, `i4Vfd_set_driver_cmd_init` @0x319c7c (`bic #15`) | resume/init ack |
| bit 26 (`0x4000000`) | `_CEC_Init` @0x2e2174 (`bic #67108864`) | CEC ack |
| — | `vInitDDCLine` @0x2e3698 | DDC ack |

Written values in the run: `0x0` ×1234 (the key-scan clears), plus `0x100`,
`0x800000`, `0x1000000` once each during init. **VERIFIED.**
Sibling registers: `0x700240f8` (same field geometry, `bic #15`; trace: 2
reads / 2 writes of `0x0`) and `0x700240fc` (**set** the same bits: `orr #15` /
`orr #1`; trace: 1 read / 1 write of **`0xf`**). **VERIFIED** shape and
traced values, **INFERRED** hardware meaning (pending / mask / enable).

### 3.3 `0x70050300`–`0x70050320` — VFD front-panel MCU command interface

Executed path: `i4VFDIndirectSIFCmdRegMode`, called from
`i4VfdScanKeyWithDriver` (VERIFIED, §5).

| addr | R | W | role | setting instruction | label |
|---|---|---|---|---|---|
| `0x70050300` | 0 | 1,232 | **CMD word 0** — `b0 \| b1<<8 \| b2<<16 \| b3<<24` of the caller's packet. The low nibble of `b0` is a sub-opcode the Cmd functions switch on; observed `0x5001c` ⇒ `0xc` (>8, and `&3 == 0` so the readback path runs) | `str r3,[r5,#0x300]` @0x31901c | VERIFIED |
| `0x70050304` | 0 | 1,232 | **CMD word 1** — `b4 \| b5<<8 \| b6<<16` (24-bit). Observed `0x70046` | `str r3,[r5,#0x304]` @0x319038 | VERIFIED |
| `0x70050308` | 1,232 | 0 | **DATA/RESULT word 0** (readback) | `ldr r3,[r5,#0x308]` @0x319058 | VERIFIED |
| `0x7005030c` | 1,232 | 0 | **DATA/RESULT word 1** | @0x31907c | VERIFIED |
| `0x70050310` | 1,232 | 0 | **DATA/RESULT word 2** (also sampled by the IRQ handler `_ExtInt2Isr` @0x30f894) | @0x31909c | VERIFIED |
| `0x70050314` | 1,232 | 0 | **DATA/RESULT word 3** | @0x3190bc | VERIFIED |
| `0x70050320` | 3,712 | 2,473 | **CONTROL/STATUS** — see bit map below | mixed | VERIFIED |

`0x70050320` bit map (all **VERIFIED** from the setting instructions):

| bit | meaning | who writes it |
|---|---|---|
| 0 | **START / trigger strobe** — assert then release | `i4VFDTrigRegModeStart`: `0x31` @0x318c8c then `0x30` @0x318cb4. ISR ack path uses `0x71`/`0x70` (`_ExtInt2Isr` @0x30f844/0x30f8c8) |
| 1 | **queue-mode start select** (`0x32` vs `0x30`) | `i4VFDTrigQueModeStart` @0x318be0/0x318c08 |
| 4, 5 | mode field, always `0b11` in the `0x30` pattern | part of `0x30` |
| **7** (`0x80`) | **BUSY** — read-only status; both wait loops spin *while set* | `i4VFDWaitBusy` `and r0,r0,#128` @0x318afc; `IFconWaitHWBusy` `tst r2,#128` @0x30f778 |
| 8 (`0x100`) | **accelerator reset**, pulsed (set then clear) | `i4VFDAcceleratorRst` @0x318b40 (`orr #256`) / @0x318b68 (`bic #256`) |

Observed write histogram for `0x70050320`: `0x30`×1236, `0x31`×1232, `0x32`×3,
`0x100`×1, `0x0`×1. The one-shots are identifiable by position: trace lines
5814–5833 are the VFD init, and they land exactly on the init functions.

```
5814  read  0x70050320                    wait (i4VFDWaitBusy / IFconWaitHWBusy)
5815  write 0x70050328 = 0x17ed002        panel geometry / segment setup
5816  write 0x7005032c = 0x17ed042
5817  write 0x70050330 = 0x17ed062
5818  write 0x70050334 = 0x17ed082
5819  write 0x70050338 = 0x17ed0d2
5820  write 0x7005033c = 0x17ed152
5822  write 0x7005031c = 0x1010101
5823  write 0x70050320 = 0x30
5824  write 0x70050324 = 0x10e7e
5826  write 0x70050320 = 0x100           i4VFDAcceleratorRst: orr #256  (bit 8)
5827  write 0x70050320 = 0x0             i4VFDAcceleratorRst: bic #256
5831  write 0x70050320 = 0x32            i4VFDTrigQueModeStart (bit 1)
5832  write 0x70050320 = 0x30
```

**VERIFIED** — the `0x100`/`0x0` pair is `i4VFDAcceleratorRst`'s `orr`/`bic` on
bit 8, and `0x32`/`0x30` is `i4VFDTrigQueModeStart`'s bit-1 pulse, in each
function's own instruction order. `0x70`/`0x71` **never appear** ⇒ `_ExtInt2Isr`
never ran (no interrupt is ever raised in the emulator). **VERIFIED.**

The model must also tolerate writes to `0x7005031c`, `0x70050324` and
`0x70050328`–`0x7005033c`; store-and-ignore is sufficient, they are never read
back in this run.

### 3.4 `0x70047100`/`0x47108`/`0x4710c`/`0x47110` — audio DSP load port

All four are `vAudHalSetDspLoadTable`. Block base in the literal pool is
`0xfd047fff` (pre-biased), giving `0x70047100/0x47108/0x4710c/0x47110` with
offsets `-0xeff / -0xef7 / -0xef3 / -0xeef`. **VERIFIED.**

| addr | R | W | role | label |
|---|---|---|---|---|
| `0x70047100` | 0 | 2 | **LENGTH / control**: `0x20` before a transfer, `0` after (only 2 writes in the whole run) | VERIFIED |
| `0x7004710c` | 0 | 1 | **COMMAND**: `2` = read-back/verify mode | VERIFIED |
| `0x70047110` | 0 | 907 | **INDEX / address port**: written `0` before each push, then the entry index during verification | VERIFIED |
| `0x70047108` | 453 | 453 | **DATA port**: write = store table word; read = fetch it back | VERIFIED |

**This one matters more than its count suggests.** The function is a
write-then-read-back **verify** loop, not a fire-and-forget push:

```
4b528:  str  #32,   [0x70047100]        ; length
loop1:  str  #0,    [0x70047110]        ; index 0
        ldr  r0,[r1],#4                 ; next source word
        str  r0,    [0x70047108]        ; push
        cmp/blo loop1
4b558:  str  #2,    [0x7004710c]        ; verify mode
loop2:  str  r5,    [0x70047110]        ; index
        ldr  r2,    [0x70047108]        ; READ BACK
        ldr  r3,[r6],#4                 ; expected
        cmp  r2,r3
        beq  ok
        Assert(0, "src/driver/aud/hal/aud_hal_8560.c")   ; @0x4b584
ok:     ...
4b59c:  str  #0,    [0x70047110]
4b5a0:  str  #0,    [0x70047100]
```
**VERIFIED** instruction by instruction. The assert target string resolves to
`src/driver/aud/hal/aud_hal_8560.c`, and the UART shows
`Assert FIRED: 0 (src/driver/aud/hal/aud_hal_8560.c:389)` firing in this run —
consistent with readback returning 0 for every non-zero table word. (That the
fired assert is *this* line is INFERRED: the assert's line-number literal was
not resolvable, since only two of its three pool slots carry relocations.)

## 4. Secondary registers

Lower traffic; named where a vendor symbol makes it nameable.
Owner lists are exhaustive (regenerate with `hotset_table.py`); "role" is INFERRED unless marked.

| addr | R | W | block / role | representative owners |
|---|---|---|---|---|
| `0x700000c0` | 26 | 0 | audio/clock (CKGEN) — bit fields incl. `bic #3`,`orr #1`, `orr #64`, `orr #16384` | `AUD_HwInit`, `vSetMICClk`, `vAIN_ACK_CFG_Multi`, `vInitPwm`, `vHal_SetCcirOutPinMux` |
| `0x700000c8` | 30 | 0 | audio clock | `AUD_HwInit`, `vExtSPDIFInIRQInit` |
| `0x700000cc` | 14 | 0 | audio clock / PWM | `vInitPwm`, `_SACDCLI_*Monitor` |
| `0x70000180`, `0x700001a0` | 9/8 | 9/8 | **unresolved** – see §8 | — |
| `0x7002117c` | 14 | 12 | HDMI bitrate/DSD enable | `vSetHdmiHighBitrate`, `vEnableDsdConfig`, `vHalMuteHDMIAudio` |
| `0x70021184` | 0 | 20 | HDMI N/CTS audio clock | `vHalHDMI_NCTS`, `vHalBypassHDMI_NCTS` |
| `0x70021188` | 0 | 22 | HDMI info-frame dispatch (9 senders) | `_SendAVIFrame.clone.0`, `vHalSend*InfoFrame` |
| `0x70005028` | 18 | 16 | **unresolved** – see §8 | — |
| `0x700050c0` | 7 | 7 | audio clock / IEC958 routing | `AUD_AoutCfg`, `_vAClkHWSetting`, `vAud1BckCFG` |
| `0x700050cc` | 9 | 9 | DSP DRAM-access window | `vAudHalSetDsp{HwRegInit,EnableDramAccess,WorkingDramBlock,…}` |
| `0x70003810` | 8 | 6 | HDMI gamma write port | `vWriteGammaReg`, `vInitHdmiGamma`, `vSetHdmiYscale`, `vGetGammaReg` |
| `0x70047028` | 12 | 11 | audio DSP C-offset | `vAudHalSetAdspCOff` |
| `0x70024580` | 6 | 6 | **unresolved** – see §8 | — |
| `0x70024594` | 6 | 6 | CEC ISR read port | `_CEC_Isr` |
| `0x70024140` | — | — | **IRQ status**, read by every ISR | `_DDCMIsr`, `_IRHW_RxIsr`, `_SifMIsr` |
| `0x70024144` | 4 | 6 | **IRQ enable, bit-per-source** (bit 13 = IR RX: `IR_RxEnable` `orr #8192`) | `IR_RxEnable`, `IRHW_RxInit`, `IRHW_RxStop`, `CEC_DRVInit`, `i4DDCM_*`, `i4SIFM_*` |
| `0x70024148` | — | — | **IRQ → handler binding**, written by each ISR registrar | `_IRHW_RxIsr`, `_DDCMIsr`, `vCecIsr`, `IRRX_PollMtkIr` |
| `0x70024188` | 5 | 5 | shared SRAM/clock control | `VSFHW_SramClk`, `i4NR_*`, `_vCommonSRAMInit`, `i4EtherDrv_Init`, `IRHW_RxInit` |
| `0x700241cc` | 1 | 1 | **unresolved** – see §8 | — |
| `0x70024030`/`0x70024034` | — | — | front-end reset / status | `VSFHW_FrontEndResetHi/Lo`, `VSFHW_FrontEndStatus`, `vResetClock` |
| `0x700240d4`/`0x700240d8` | — | — | DDC (HDMI I²C) start/stop | `fgDDCStart`, `vDDCRead`, `vDDCStop`, `fgDDCSend` |

## 5. How the executed owner is established

Static site counts are *not* a proxy for which function ran: `IRRX_PollMtkIr`
has one site and produced 12,013 accesses, while `i4VFDDirectSIFCmdRegMode`
has four sites and produced none. Owners are therefore pinned by matching the
trace's per-iteration **ordering** against the disassembly:

```
trace lines 6073-6086 (one iteration, 22-23 lines, repeated 1,232×)
  read  0x700240f4              <- i4VfdScanKeyWithDriver: ldr [r3,#0xf4]
  write 0x700240f4 = 0x0        <-                       bic #15 / str
  read  0x70050320              <- i4VFDWaitBusy: ldr [r4,#0x320], and #128
  write 0x70050300 = 0x5001c    <- i4VFDIndirectSIFCmdRegMode: str [r5,#0x300]
  write 0x70050304 = 0x70046    <-                             str [r5,#0x304]
  write 0x70050320 = 0x31       <- i4VFDTrigRegModeStart: str #49 [r3,#0x320]
  write 0x70050320 = 0x30       <-                        str #48
  read  0x70050320              <- i4VFDWaitBusy
  read  0x7002420c              <- IRRX thread, interleaved
  read  0x70050320              <- second wait (IFconWaitHWBusy)
  read  0x70050308..0x70050314  <- i4VFDIndirectSIFCmdRegMode readback
  read  0x7002420c  × 8-9       <- IRRX thread between VFD commands
```
**VERIFIED** — this exact order is what `i4VFDIndirectSIFCmdRegMode` emits
(write 0x300 → write 0x304 → `bl` trigger → `bl` wait ×2 → read 0x308..0x314),
and the `bytes[0] & 3 == 0` guard at 0x319044 is satisfied by opcode `0x1c`.

**Threads** (VERIFIED from the UART):
- `VFD_CmdProcThread` (`0x7884c`) — the pump. Cycles command id 0/1 and waits
  on a message queue with a 100-tick timeout (`mov r5,#100`) each iteration;
  1,232 iterations over the run. The 100-tick wait and the cadence are
  VERIFIED; naming the call `x_msg_q_receive` is INFERRED from its shape.
- `IRRC_DataProcessingThread` / `IRRX_DataProcessingThread` — two IR threads,
  created at UART lines 840 and 933; `x_thread_delay(arg=10)` ×15,872 with
  caller `IRRC_DataProcessingThread`, which is what produces the 12,013 IR
  status reads.

## 6. The handshake protocol (what the device model must implement)

State machine, one iteration of `VFD_CmdProcThread`:

```
IDLE
 │ (a) ldr 0x700240f4 ; bic bits3:0 ; str 0x700240f4     [key field ack]
 ▼
WAIT_TX      ldr 0x70050320 ; loop while (val & 0x80)          <-- BUSY must be 0
 ▼
LOAD_CMD     str 0x70050300 = cmd_w0  (32-bit, opcode = w0 & 0xF)
             str 0x70050304 = cmd_w1  (24-bit)
 ▼
KICK         str 0x70050320 = 0x31   (bit0 strobe asserted)
             str 0x70050320 = 0x30   (bit0 released)           <-- device executes here
 ▼
WAIT_DONE    ldr 0x70050320 ; loop while (val & 0x80)          <-- BUSY must clear
             ldr 0x70050320  (second wait, IFconWaitHWBusy)
 ▼
READBACK     ldr 0x70050308 / 0x7005030c / 0x70050310 / 0x70050314
             -> unpacked little-endian into packet bytes 0x08..0x17
 ▼
IDLE
```

Parallel, independent machine (IR thread):

```
loop every ~10 ticks:  ldr 0x7002420c ; if (val & 0x40000) => packet available
```

Audio DSP machine (startup only, ~14 table pushes):

```
str 0x70047100 = 32 ; [ str 0x70047110 = 0 ; str 0x70047108 = word ]×N
str 0x7004710c = 2  ; [ str 0x70047110 = i ; ldr 0x70047108 ; cmp with source ]×N
str 0x70047110 = 0  ; str 0x70047100 = 0
```

**None of these loops can hang on the current model**, and this is worth
stating plainly: every wait is `while (bit7 of 0x70050320)` / `if (bit18 of
0x7002420c)`, and an unimplemented read yields 0, so both terminate on the
first test. Run C50 completed 1,232 iterations of the full cycle. The problem
is therefore **not** liveness — it is *silent wrong data* (§7).

## 7. Minimal-response recommendation

Ordered by value per line of QEMU code. The first two items are what separate
"the driver keeps running" from "the driver believes the hardware".

1. **`0x70047108` must be a 32-entry word RAM indexed by `0x70047110`.**
   Write stores, read returns the stored word. This is the only hot register
   whose value the driver *checks*: without it, `vAudHalSetDspLoadTable` fails
   its read-back comparison for every non-zero word and fires
   `Assert(0, ".../aud_hal_8560.c")` on each. Recommended storage:
   `uint32_t dsp_load[32]`, `idx = value written to 0x70047110`, reset both to
   0 on write to `0x70047100`.
2. **`0x70050320` bit 7 reads back 0 always** (not busy). Bits 0/1/4/5/8 are
   write-only strobes — accept and ignore. That alone makes all four VFD wait
   loops terminate.
3. **`0x70050308`–`0x70050314` return a coherent, stable response.** All-zero
   is acceptable and already the de-facto behaviour: it decodes as "no key
   pressed / zero-length reply". Do **not** return free-running garbage or
   `0xffffffff` — the driver unpacks these into the dispatch packet consumed
   by `i4VfdScanKeyWithDriver` (INFERRED downstream effect; the unpack itself
   is VERIFIED).
4. **`0x700240f4` / `0x700240f8` / `0x700240fc` need only be a plain 32-bit
   read/write register.** Every access is read-modify-write of the driver's own
   field, so a dumb store is faithful. Return 0 from reset.
5. **`0x7002420c` — return a value with bit 18 clear.** That is "no IR packet",
   which is the honest state of an emulated player with no remote control.
   Keep bit 0 (RX enable) write-visible if you want to observe configuration.
6. `0x70050300` / `0x70050304` are write-only command latches — store, don't
   act. Likewise `0x7005031c`, `0x70050324` and `0x70050328`–`0x7005033c`: the
   panel-geometry setup written once at init and never read back.
7. The `0x70024000` front-end block (CEC/DDC/SIF/IRQ status+enable, §4) needs
   only "reads as 0, writes latch" for the current run, since no interrupt is
   raised. `_ExtInt2Isr` never executes today.

A device implementing 1–3 changes *driver-visible truth*; 4–7 only preserve the
current no-crash behaviour.

## 8. What did NOT resolve — stated loudly

**Traffic coverage: 91.5%** (31,120 / 33,993 accesses attributed to an
instruction). **Address coverage: 23.3%** (444 / 1,908 distinct addresses) —
the long tail is dominated by one-shot register-window sweeps.

| unresolved | R/W | why |
|---|---|---|
| `0x70000180`, `0x700001a0` (**named target**) | 9/9, 8/8 | no resolvable base. All bdpdrv IO bases appear as either a literal-pool word or `mov rN,#-50331648` (=`0xFD000000`, 874 sites); neither yields this offset. Most likely a base returned by a call (e.g. an OSAL/`u4HalGetTTB`-style helper writing it into `r0`), which a static pass cannot see. **INFERRED.** |
| `0x70005028` (**named target**) | 18/16 | same class. Note `0xfd005000` *does* exist as a literal with 118 references and `0x700050c0`/`0x700050cc` resolve in the same block — so the base is known but this particular access uses a different register/offset form (register-indexed addressing is not modelled). |
| `0x70024580` (**named target**) | 6/6 | same block as the resolved `0x70024594` (`_CEC_Isr`), unresolved base. |
| `0x700241cc` (**named target**) | 1/1 | single access during init; no owner found. |
| `0x700000c0`/`0x700000c8`/`0x700000cc` executed owner | 26/0, 30/0, 14/0 | **Owner names resolved, executed owner not established.** The trace shows these as **read-only** (0 writes) while every resolved site is read-modify-*write*. So the running accessor is a *different*, unresolved code path (a status probe reading 0xc0/c8/cc/d4 as a group). Treat the listed functions as candidates, not the answer. |
| `0x7004245x`–`0x7004249c` (~40 addrs) | 2/1 each | a run of consecutive addresses = a table walk using register-indexed addressing (`ldr rX,[rB,rI,lsl #2]`), which this pass does not evaluate. |
| ~1,400 further addresses | 1–6 each | init-time one-shots. |

Also unresolved: the line number of the `aud_hal_8560.c` assert (only 2 of 3
pool slots carry relocations), and the downstream meaning of the VFD readback
words (they are unpacked VERIFIED; what consumes them is INFERRED).

## 9. Reproducing this decode

```
cd evidence/bx510-guest/bdpdrv/decode

python3 extract_consts.py --dump-bases                     # every 0x70xxxxxx constant
python3 extract_consts.py --targets 0x7002420c --base-match # exact + base+offset hits
python3 extract_consts.py --sym IRRX_PollMtkIr --disasm     # one function

python3 resolve_addrs.py --calibrate                        # re-derive virt->phys
python3 resolve_addrs.py --all > /tmp/accesses.txt          # full resolved access list
python3 resolve_addrs.py --reach 0x7002420c                 # who touches an address
python3 resolve_addrs.py --lo 0x70024000 --hi 0x70025000    # a block
python3 resolve_addrs.py --func i4VFDIndirectSIFCmdRegMode

python3 trace_stats.py                 # per-address R/W counts + value histograms
python3 trace_stats.py --addr 0x70050320

python3 correlate.py --summary         # coverage numbers
python3 correlate.py --lo 0x70050300 --hi 0x70050400
python3 hotset_table.py > hotset-functions.txt
```

`x`-refs: `run-c50.md` (the trace that produced this), `stub-run.md` (how the
driver came to load at all).
