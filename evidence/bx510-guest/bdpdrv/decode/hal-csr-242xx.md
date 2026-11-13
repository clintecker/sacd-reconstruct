# `0xfd0242xx` — owner, meaning, and why the 12 945 `R 0x2420c` reads are not a poll

**Settles `fe-ata-cmd.md` §4.2 (and §0.7, §5.1 rows 15–16), which left the writer of
`0x2420c/210/214/218` INFERRED as "a computed-base/table-driven access, orthogonal to the
ATA reply".** It is not table-driven, it is not the FE, and there is no completion poll.

**One-line answer:** the `0x242xx` block is the **MediaTek IR (infrared) receiver CSR
bank** inside the shared `0xfd024000` host/SIF block. The three writes are
`IRHW_RxInit()` (bdpdrv.ko `.text+0x30ff80`), called from `IRRX_InitMtkIr()`
(`.text+0x311010`) with constants `0x111 / 225 / 512`. The `0x24218←1` is
`_IRHW_RxSetIsr()` (`.text+0x30fdd8`). The 12 945 reads are **one `ldr` per iteration of a
sleeping kernel thread** — `IRRC_DataProcessingThread` (`.text+0x30ec9c`) →
`IRRX_PollMtkIr` (`.text+0x3102b8`), which tests **bit 18 (`0x00040000`)** and otherwise
returns; the loop exits on a thread stop flag, never on a register value. It runs **in
parallel** with (in C95: entirely *after*) the ATA path and cannot block IDENTIFY.

**Inputs** (`/tmp/bdpdrv/` unless a repo path is given):

| input | role |
|---|---|
| `bdpdrv.ko` + `text.dis` (840 681 lines) | the owner module; `resolve_addrs.py --reach` and `--func` do the literal-base join |
| `sata_mt85xx_mod.ko` + `sata.dis` + `decode/map.txt` | negative control: **zero** accesses to `0xfd024200..0xfd02424f` (map.txt's whole `0xfd024` footprint is 4 addresses — `0xfd024030`×4, `0xfd024034`×8, `0xfd024188`×6, `0xfd0241d0`×2 — none in `0x200..0x240`) |
| `evidence/bx510-guest/bdpdrv/decode/bdpdrv-runC95.posthandshake.mmio.gz` | committed trace tail, 5 224 802 lines = VM lines 541511..5766311 (`gz line N == VM line 541510+N`) |
| `bdpdrv-runC95.uart.log` | console (reconstructed inline from `W 00c000` byte writes — reproduces the 1878-line log exactly, per `trace-analysis-c95.md`) |
| `decode/fe-ata-cmd.md`, `decode/model-spec.md`, `decode/model-c96-diff.md`, `decode/trace-analysis-c95.md`, `run-c94-c95.md` | the claims being settled/corrected |

**Certainty labels.** *DECODED* = fixed by the instruction sequence (and, where stated, by
an exact ordered match against the trace). *TRACE* = a measured value/count from the
committed tail. *INFERRED* = consistent with everything seen, not closed by one
instruction; the settling experiment is named.

**Why the earlier search missed it.** The earlier run grepped for the literal
`0xfd02420c` and for a bare `[rN,#0x20c]` immediate. Neither is evidence: `grep -c ",
#0x20c]" text.dis` = **354** hits, almost all struct-field accesses, and the driver never
stores `0xfd02420c` as a literal. The address is `literal 0xfd024000` (71 pool words in
`.text`) + a small immediate. The join has to be done by a base-tracking resolver, which is
exactly what the committed tool does:

```
$ cd evidence/bx510-guest/bdpdrv/decode && python3 resolve_addrs.py --reach 0x7002420c
0x030fe98 R4 0xfd02420c  ldr  IRHW_RxRdConf
0x030fec8 W4 0xfd02420c  str  IRHW_RxWrConf
0x030fefc R4 0xfd02420c  ldr  IR_RxEnable
0x030ff04 W4 0xfd02420c  str  IR_RxEnable
0x030ff5c R4 0xfd02420c  ldr  IR_RxEnable
0x030ff64 W4 0xfd02420c  str  IR_RxEnable
0x030fff4 W4 0xfd02420c  str  IRHW_RxInit      <- the C95 writer
0x03100a4 R4 0xfd02420c  ldr  i4IrHWUninit
0x03100b0 W4 0xfd02420c  str  i4IrHWUninit
0x03102dc R4 0xfd02420c  ldr  IRRX_PollMtkIr   <- the C95 reader
```

---

## 0. Bottom line (six findings)

1. **`0xfd0242xx` is IR, not FE.** `0xfd024000` is a *shared* host-interface ("SIF") block:
   FE reset/status `+0x30/+0x34`, secondary-IRQ pending/mask/ack `+0x140/+0x144/+0x148`,
   SRAM clock `+0x188`, DDC/I²C bit-bang `+0xd0..+0xf8`, IR RX `+0x200..+0x240`, CEC
   `+0x16c/+0x500..`. `kernel-iomap.md` §"0xfd024000" already had the FE half and the
   `+0x140/+0x144` secondary controller; the IR half is what §4.2 was looking at.
2. **The writer is `IRHW_RxInit` and the values are its arguments.** `IRRX_InitMtkIr`
   passes `r0=0x111` (pool literal `.text+0x31112c`), `r1=225`, `r2=512`
   (`.text+0x311090..0x31109c`). `0x111 / 0xe1 / 0x200` therefore have **nothing** to do
   with the `fe_test_data` partition offset `0xE00000` or any FE SRAM address — that
   hypothesis is dead, replaced by a positive identification.
3. **Attribution is not merely plausible, it is order-exact.** `IRHW_RxInit` +
   `_IRHW_RxSetIsr` produce an 18-access sequence whose *instruction order* matches the trace
   tail access-for-access (§1.2). No other function in the module reads/writes `0x24088`,
   `0x24240`, `0x24080`, `0x2420c`, `0x24210`, `0x24214`, `0x24040`, `0x24188`, `0x24044`,
   `0x24218`, `0x24148`, `0x24144` in that order.
4. **There is no completion poll and no "exit value".** `IRRX_PollMtkIr` reads `0x2420c`
   once per call and branches on **bit 18**: set ⇒ it counts the occurrence, prints
   `ir state clear!,Cnt=%d` (or `ir state long clear !Cnt=%d`) and **re-arms** the receiver
   (`0x24148 |= 0x2000`, `0x24218 |= 1`); clear ⇒ it goes on to drain the software key
   queue. The thread's loop condition is a stop flag in RAM, not a CSR. **The model must
   keep bit 18 clear** (0 and the current echo of `0x111` both do); setting it would fire the
   diag path ~13 k times plus ~26 k spurious writes.
5. **The loop is a thread, not a spin.** `IRRC_DataProcessingThread` =
   `for(;;){ IRRX_PollMtkIr(&key); …; x_thread_delay(10); }` (`.text+0x30ece4`,
   `.text+0x30ed28`, back-edge `.text+0x30ed30`); the console names it
   (`x_thread_delay #N arg=10 caller=IRRC_DataProcessingThread`, sampled — see below).
   In the trace the reads sit **178 trace lines apart** (median; min 172) and are interleaved
   with ~8 BIM interrupt bursts each — the machine is doing other work between them.
   *Counting cross-check:* the OSAL stub prints `x_thread_delay` only for its first 4 calls
   and then every 256th (`tools/bx510_osal_stub.c:436` `STUB_COUNTED` throttle), so the 44
   `caller=IRRC_DataProcessingThread` lines in the tail are 256-step samples of the loop,
   not 44 iterations. The stub's **global** counter reaches `#17152` at VM 5 740 423, and
   the loop sampled `#16896` at VM 5 701 667 — 17 152 total delay calls against 12 945 IRRC
   iterations plus ~4 200 from the other threads on the same counter: quantitatively
   consistent, and the poller is still sleeping at the end of the run.
   (Do not confuse it with `IRRX_DataProcessingThread` `.text+0x3104c4`, a *different,
   non-polling* IR thread that waits on a semaphore with timeout 100 and exits at VM
   3 262 019 — `[IR]IRRX_DataProcessingThread, exit`. It never touches `0x24xxxx`; only
   `IRRC_DataProcessingThread` calls `IRRX_PollMtkIr` in this lane.)
6. **Trace ordering settles the "blocking?" question with no overlap at all.** In C95 the
   whole `0x24xxxx` block is absent from the IDENTIFY window: the first `0x24xxxx` access in
   the committed tail is at tail line 2 477 452 (VM 3 018 962), i.e. ~2.4 M tail lines after
   post #3's drain and after the EH cycle had already ended (`reset failed, giving up` /
   `EH complete`, VM 2 874 442–2 874 751). The IR init is at VM 3 194 785; the first
   `0x2420c` read at VM 3 231 501; the last ATA mailbox post (cmd#13, `0x08`) at VM
   2 793 661. §5.

---

## 1. Owning function(s), module, instruction cites

All addresses below are `.text`-relative in **`bdpdrv.ko`** (the SATA/FE module
`sata_mt85xx_mod.ko` has *no* access in `0xfd024200..0xfd02424f` — `decode/map.txt`, 602
rows, confirms). MMIO VA `0xfd0240xx` ↔ physical `0x700240xx`; the model prints the
physical address minus `0x70000000` as `%06x`, hence `W 02420c = 0x111` in the log.

### 1.1 The three writers and one reader (DECODED)

| role | function | module | instruction cites |
|---|---|---|---|
| **writer of `0x2420c/210/214` (the C95 triple)** | `IRHW_RxInit` | bdpdrv `.text+0x30ff80` | `.text+0x30fff4` `str r5,[r3,#0x20c]`; `.text+0x30fff8` `str r4,[r3,#0x210]`; `.text+0x30fffc` `str r7,[r3,#0x214]`; base `r3 = *(0xfd024000)`, loaded `.text+0x30ffd8` from pool `.text+0x310064` = `00 40 02 fd` |
| **argument source (`0x111/0xe1/0x200`)** | `IRRX_InitMtkIr` | bdpdrv `.text+0x311010` | `.text+0x311090` `mov r1,#225`; `.text+0x311094` `ldr r0,[pc,#0x90]` → pool `.text+0x31112c` = `0x00000111`; `.text+0x311098` `mov r2,#512`; `.text+0x31109c` `bl IRHW_RxInit` |
| **writer of `0x24218←1`** | `_IRHW_RxSetIsr` | bdpdrv `.text+0x30fdd8` | `.text+0x30fe24` `ldr r2,[r3,#0x218]`; `.text+0x30fe28` `orr r2,r2,#1`; `.text+0x30fe2c` `str r2,[r3,#0x218]` (`bl` from `IRHW_RxInit` at `.text+0x310028`) |
| **reader (the 12 945 reads)** | `IRRX_PollMtkIr` ← `IRRC_DataProcessingThread` | bdpdrv `.text+0x3102b8` ← `.text+0x30ec9c` | read `.text+0x3102dc` `ldr r2,[r4,#0x20c]`; test `.text+0x3102e0` `tst r2,#262144`; diag `.text+0x3102f8..0x310314`; re-arm `.text+0x310318..0x31032c`; call site `.text+0x30ece4` `bl IRRX_PollMtkIr`; sleep `.text+0x30ed28` `mov r0,#10` + `bl x_thread_delay`; back-edge `.text+0x30ed30` |

Secondary writers (not executed in C95 — no matching values in the trace):
`IRHW_RxWrConf` `.text+0x30fec4` (plain triple store), `IRHW_RxRdConf` `.text+0x30fe70`
(triple read → `IR_Status_WD` `.text+0x3114c8`, CLI only), `IR_RxEnable`
`.text+0x30fedc` (RMW `0x20c |= 1` / `&= ~1`), `i4IrHWUninit` `.text+0x310094`
(RMW `0x20c |= 0x8000`).

Callers of `IRRX_PollMtkIr` (from `.rel.text`, `R_ARM_CALL`): `IRRC_DataProcessingThread`
`.text+0x30ece4`; `IR_Diag` ×6; `_RxCLI_PollKey` `.text+0x312030`; `_RxCLI_IrThread`
`.text+0x312098`. Callers of `IRHW_RxInit`: `IRRX_InitMtkIr` `.text+0x31109c`,
`IRRX_Partial_ResetMtkIr` `.text+0x311184` (same `0x111/225/512`), `_RxCLIReset`
`.text+0x311c84`.

### 1.2 The order-exact match (the decisive evidence)

`IRHW_RxInit` then `_IRHW_RxSetIsr` (tail lines 2 653 273 – 2 653 506, VM 3 194 783 –
3 195 016) against the instruction order of the two functions:

| # | trace (tail line) | trace access | static instruction |
|---|---|---|---|
| 1 | 2653273 | `R 024088` | `.text+0x30ffb8` `ldr r3,[r6,#0x88]` (`tst #256` wake-up; `r6 = 0xfd024000` from `.text+0x30ffa0`) |
| 2 | 2653275 | `W 024240 = 0` | `.text+0x30ffe0` `str r6,[r3,#0x240]` (`r6=0`) |
| 3 | 2653277 | `R 024080` | `.text+0x30ffe4` `ldr r2,[r3,#0x80]` |
| 4 | 2653279 | `W 024080 = 0` | `.text+0x30fff0` `str r2,[r3,#0x80]` (`bic #256`; read 0 ⇒ 0) |
| 5 | 2653281 | `W 02420c = 111` | `.text+0x30fff4` `str r5,[r3,#0x20c]` |
| 6 | 2653283 | `W 024210 = e1` | `.text+0x30fff8` `str r4,[r3,#0x210]` |
| 7 | 2653301 | `W 024214 = 200` | `.text+0x30fffc` `str r7,[r3,#0x214]` |
| 8 | 2653303 | `R 024040` | `.text+0x310000` `ldr r2,[r3,#0x40]` |
| 9 | 2653305 | `W 024040 = 0` | `.text+0x310008` `str r2,[r3,#0x40]` (`bic #2`) |
| 10 | 2653307 | `R 024188` | `.text+0x31000c` `ldr r2,[r3,#0x188]` |
| 11 | 2653309 | `W 024188 = 0` | `.text+0x310014` `str r2,[r3,#0x188]` (`bic #0x100000`) |
| 12 | 2653311 | `R 024044` | `.text+0x310018` `ldr r2,[r3,#0x44]` |
| 13 | 2653313 | `W 024044 = 3` | `.text+0x310024` `str r2,[r3,#0x44]` (`bic #15` / `orr #3`) |
| 14 | 2653480 | `R 024218` | `_IRHW_RxSetIsr` `.text+0x30fe24` `ldr r2,[r3,#0x218]` |
| 15 | 2653482 | `W 024218 = 1` | `.text+0x30fe2c` `str r2,[r3,#0x218]` (`orr #1`) |
| 16 | 2653484 | `R 024148` | `.text+0x30fe30` `ldr r2,[r3,#0x148]` |
| 17 | 2653486 | `W 024148 = 2000` | `.text+0x30fe38` `str r2,[r3,#0x148]` (`orr #8192`) |
| 18 | 2653506 | `W 024144 = 2000` | back in `IRHW_RxInit` `.text+0x310058` `str r2,[r3,#0x144]` (`orr #8192`) |

Rows 1–13 are one straight-line body; rows 14–17 are the `_IRHW_RxSetIsr` call at
`.text+0x310028`; row 18 is the return path. The 217-line gaps (rows 6→7, 13→14) are
interrupt bursts, not extra accesses — no `0x24xxxx` access occurs between them.

### 1.3 Independent cross-check: the console names the subsystem

The reconstructed console inside the same window (each character is a `W 00c000` in the
same stream; the VM line below is where the console *line completed*) says:

```
VM 3194791  W 02420c = 0x111                    (row 5 of the table)
VM 3194828  [IR][IR]: IRRX_InitMtkIr            <- the caller's entry printf (pool .rodata.str1.1+0xa6809)
VM 3194992  W 024218 = 1                        (row 15)
VM 3195656  [IR][IRRX] Not a BDP8.5G model, let FE try it.
VM 3195882  [IR][IRRX]HW_FastejectKeyNotify arm2 eject
```

The second line is the string at `.rodata.str1.1+0xa62b6`, printed by
`HW_FastejectKeyNotify` `.text+0x310168..0x310170` after it reads `0xfd0241c0`
(`.text+0x31013c`, base `0xfd008000 + 0x1c000`; `tst #0x10000` clear because the model
returns 0). So the 30 lines of trace around the IR init are a **contiguous IR/fast-eject
init sequence**, and the trace's `R 0241c0` is that model-detect read. Two independent
sources (instruction order, console text) name the same subsystem.

---

## 2. Semantics of the other `0x24xxx` sites (model-row ready)

Complete census of the committed tail (5 224 802 lines), `R`/`W` counts and the *distinct*
written values. "value seen" is what the guest wrote **given the model returns 0** for
these registers, so an RMW reads 0.

| reg (VA) | tail R/W | values seen | owner (function, cite) | meaning (certainty) |
|---|---|---|---|---|
| `0x24030` | **0 in tail** (pre-handshake only: 50 902 writes whole-run, `post-aacs-state.md` §) | `0x85` | `VSFHW_FrontEndResetLo` `.text+0x130b38..0x130b40`, `VSFHW_FrontEndResetHi` `.text+0x130b54..0x130b58`, `vResetClock` `.text+0x13a714`, sata `reset_int_ldr` `.text+0x3c`/`xfer_int_ldr_fw` `.text+0x1820` | **FE reset command = constant `0x85` (133)**. DECODED (immediate `mov r2,#133`). |
| `0x24034` | R 1 / W 0 in tail | — | read `VSFHW_FrontEndStatus` `.text+0x130b74`; written `VSFHW_FrontEndResetLo` (`0`) / `Hi` (`1`) `.text+0x130b44/0x130b60`, sata `.text+0x44`, `.text+0x19bc/0x19c4` | **FE reset level / FE status**: `1` = assert reset, `0` = release; the same word is polled as status by `reset_int_ldr`/`init_int_ldr`/`xfer_int_ldr_fw`. DECODED. |
| `0x24040` | R 2 / W 2 = `0,0` | `0` | `IR_RxEnable` `.text+0x30fef4` (`bic #2`) / `.text+0x30ff6c` (`orr #2`); `IRHW_RxInit` `.text+0x310008` (`bic #2`); `i4IrHWUninit` `.text+0x3100c0` (`orr #2`); `_vCommonSRAMInit` `.text+0x2acce4..0x2accec` (`bic #8192`) | **per-block reset/hold bits; bit 1 = IR block reset (1 = in reset, 0 = running)**. DECODED for the polarity (enable clears, disable/uninit sets). bit 13 = SRAM-clock related (only `_vCommonSRAMInit`). |
| `0x24044` | R 1 / W 1 = `3` | `3` | `IRHW_RxInit` `.text+0x310018` / `.text+0x31001c..0x310024` (`bic #15`, `orr #3`) | **field[3:0] = 3 after IR init** — the IR front-end clock/pin select nibble. DECODED for the pattern, INFERRED for the field name. |
| `0x24080` | R 1 / W 1 = `0` | `0` | `IRHW_RxInit` `.text+0x30ffe4` / `.text+0x30fff0` (`bic #256`) | **wake-up enable/clear, bit 8**. DECODED. |
| `0x24088` | R 1 / W 0 | — | `IRHW_RxInit` `.text+0x30ffb8` (`tst #256`) | **wake-up source status, bit 8**; set ⇒ `[Wake up] IR wake up!!` (`.rodata.str1.1+0xa6248`) and `0x2408c ← 1` (`.text+0x30ffd4`). Return 0 = "no IR wake event" (the correct idle answer). DECODED. |
| `0x240d0` | 0 in tail | — | `vDDCRead` `.text+0x2e386c..0x2e3878` (`tst #0x1000000`) | **DDC (I²C) SDA *input*** — bit 24. DECODED. |
| `0x240d4` | R 3 / W 3 = `100,0,0` | `0x100`, `0` | `vInitDDCLine` `.text+0x2e36c8..0x2e36dc` (`bic #0x1000000`, `bic #0x800000`); `fgDDCSend` `.text+0x2e3734..0x2e374c`, `.text+0x2e3758..0x2e378c`; the `0x100` write is unattributed — **note (a)** | **DDC SDA output + SCL output** (bits 23/24) — bit-banged I²C to the HDMI sink. DECODED for the bit roles. |
| `0x240d8` | R 1 / W 1 = `0` | `0` | `fgDDCSend` `.text+0x2e3730/0x2e373c/0x2e3770/0x2e377c`; `vDDCRead` `.text+0x2e38b0/0x2e38bc` | **second DDC channel (port 2) SDA/SCL** — same two bits. DECODED. |
| `0x240e8` | R 2 / W 2 = `800000,1000000` | bits 23, 24 | `vInitDDCLine` `.text+0x2e36b0..0x2e36c4` (`orr #0x800000`, `orr #0x1000000` ×2) | **DDC-port-2 pull-up/level enable** (bits 23/24 set). DECODED (bits), INFERRED (the "pull-up" reading). |
| `0x240f0` | R 1 / W 1 = `2000000` | bit 25 | `vHotPlugPinInit` `.text+0x2d3a20..0x2d3a28` (`orr #0x2000000`) | **HDMI hot-plug detect pin enable, bit 25**. DECODED (bit), INFERRED (name). |
| `0x240f4` | R 1333 / W 1333 = `100`(1), `800000`, `1000000`, `0`(1330) | as shown | `_CEC_Init` `.text+0x2e2174..0x2e2180` (`bic #0x4000000`); `vInitDDCLine` `.text+0x2e3698..0x2e36ac`; `IFcon_Init` `.text+0x30faa4..0x30faac`; `i4Vfd_set_driver_cmd_init` `.text+0x319c7c..0x319c84` (`bic #15`); `i4VFD_Resume` `.text+0x319ff8..0x31a000`; `i4VfdScanKeyWithDriver` `.text+0x31a2f4..0x31a300` | **shared pin-mux/level register: low nibble = front-panel bus (VFD/IFcon) function select, bits 23/24 = DDC SCL, bit 26 = CEC pin.** The 1330 `= 0` R/W pairs are the periodic **VFD key-scan** RMW (`i4VfdScanKeyWithDriver`) — write-back of a read that the model returns 0. DECODED (bits), INFERRED (the "key scan" periodicity label). |
| `0x240f8` | R 2 / W 2 = `0,0` | `0` | `IFcon_Init` `.text+0x30fab0/0x30fab8`; `i4Vfd_set_driver_cmd_init` `.text+0x319c88..0x319c90` (`bic #15`) | **front-panel bus (VFD MCU) pin select, low nibble**. DECODED. |
| `0x240fc` | R 1 / W 1 = `f` | `0xf` | `IFcon_Init` `.text+0x30fabc..0x30fac4` (`orr #1`); `i4Vfd_set_driver_cmd_init` `.text+0x319c94..0x319c9c` (`orr #15`) | **front-panel bus enable, low nibble** (`0xf`). DECODED. |
| `0x24108`, `0x2410c`… | R 1 / W 1 = `0` | `0` | `i4Vfd_*` / DDC family (`resolve_addrs.py --lo 0x70024100 --hi 0x70024120`) | front-panel/DDC aux, write-back of 0. INFERRED (no reader). |
| `0x24140` | (not in tail) | — | `_DDCMIsr` `.text+0x21eb14`; `_SifMIsr` `.text+0x21f540`; `_IRHW_RxIsr` `.text+0x30fd3c` | **secondary interrupt-controller *pending*** (read-to-clear). DECODED. |
| `0x24144` | R 3 / W 3 = `0,800,2000` | bits 11, 13 | `vCecIsr` `.text+0x2e08e0..0x2e08f8` (bic/orr `#2048`); `IR_RxEnable` `.text+0x30ff24..0x30ff2c` / `.text+0x30ff38..0x30ff40`; `IRHW_RxInit` `.text+0x310050..0x310058`; `IRHW_RxStop` `.text+0x310080..0x310088`; `i4SIFM_Suspend/Resume`; `i4DDCM_*`; `CEC_DRVInit`, `vCECTaskMain` | **IRQ enable mask, one bit per source**: bit 11 = CEC, bit 13 = IR RX, bit 15 = DDCM. RMW (read-back must be lossless). DECODED. |
| `0x24148` | R 1 / W 2 = `800,2000` | bits 11, 13 | `_IRHW_RxIsr` `.text+0x30fda8..0x30fdb0`; `_IRHW_RxSetIsr` `.text+0x30fe30..0x30fe38`; `IRRX_PollMtkIr` `.text+0x310318..0x310320`; `vCecIsr` `.text+0x2e08dc` (`0x800`); `_DDCMIsr` `.text+0x21eb18..0x21eb20` (`0x8000`); `_SifMIsr` `.text+0x21f544..0x21f54c` | **IRQ ack / write-1-to-clear, same bit map** (11 CEC, 13 IR, 15 DDCM). Writing it is harmless; reading it is not needed. DECODED. |
| `0x2416c` | R 2 / W 3 = `0,8000,ffff0fff` | — | `_CEC_Init` `.text+0x2e2148` (`0`); `CECMWSetEnableCEC` `.text+0x2e16ac` (`orr #0x8000`); `_CEC_Mainloop` `.text+0x2e2578`/`0x2e2628`; `vCecService` `.text+0x2e3004` | **CEC control/enable** (bit 15 = enable). DECODED (bit), INFERRED (names of the cleared fields). |
| `0x24188` | R 3 / W 3 = `0,0,2` | bit 1, 12, 20, 9 | `VSFHW_SramClk` `.text+0x130bf4..0x130bf8` (writes `0x45` or `0x245`); `VSFHW_SramStatus` `.text+0x130c10` (read); `_vCommonSRAMInit` `.text+0x2accc8..0x2accd0` (`orr #2`); `IRHW_RxInit` `.text+0x31000c..0x310014` (`bic #0x100000`); `_CEC_Init` `.text+0x2e2184..0x2e2190` (`bic #4096`) | **shared-SRAM clock/retention control**: bit 1 = clock on, bit 12 = CEC-side gate, bit 20 = IR-side gate, bit 9 = alternate divisor (`0x245` vs `0x45`). DECODED (bits). |
| `0x241c0` | R 1 / W 0 | — | `HW_FastejectKeyNotify` `.text+0x31013c` / `.text+0x310148` (`tst #16`, `tst #2`); writers `_ifcon_set_force_power_on` `.text+0x2fb26c..0x2fb274` (`orr #1`), `_ifcon_set_auto_goto_standby` `.text+0x2fd064..0x2fd074`, `_ifcon_check_dimmer_power_off` `.text+0x2fd0cc..0x2fd0dc`, `_ifcon_check_8032_demo_mode_power_off` `.text+0x2fd154..0x2fd1a0` | **board/feature register**: bit 0 = force power-on (T8032), bit 2, **bit 16 = "this unit is a BDP8.5G model"**. Cleared ⇒ the driver prints `[IR][IRRX] Not a BDP8.5G model, let FE try it.` and defers ejection to the FE. DECODED for bit 16's consequence (console ↔ instruction); INFERRED for bits 0/2 naming. |
| `0x241d0` | R 3 / W 0 | — | `IRRX_FastEject_Init` `.text+0x310dc0..0x310dc8` (`tst #128`); `MW_IFCON_Init` `.text+0x3067b8..0x3067c0`, `.text+0x3067f8..0x306804` (`and #255` → board id); sata `PreparePwrOnParm` `.text+0x1588` (`tst #2`) | **board/model configuration**: low byte = model id, bit 7 = fast-eject capable, bit 1 = power-on-parameter ready. DECODED (fields), INFERRED (names). |
| `0x24200/204/208` | 0 in tail (`_IRHW_RxIsr` never ran) | — | `_IRHW_RxIsr` `.text+0x30fd40/0x30fd4c/0x30fd54`; `IR_Status_WD` `.text+0x311504/0x311508/0x31150c` | **IR receive payload, three words (96-bit frame)**; `_IRHW_RxIsr` prints `RxIsr Info:0x%08x data: 0x%08x%08x` (`.rodata.str1.1+0xa6200`). Return 0 = "no frame". DECODED. |
| `0x2420c/210/214` | R 12945 / W 1 + 1 + 1 | `111`, `e1`, `200` | writers §1.1; readers `IRHW_RxRdConf` `.text+0x30fe98/0x30fea0/0x30fea8`, `IRRX_PollMtkIr` `.text+0x3102dc` | **IR RX configuration word 0/1/2** (written once at init; read back only by the CLI status dump). `0x2420c` bit 18 is the *only* bit the driver tests — see §3. DECODED. |
| `0x24218` | R 1 / W 1 = `1` | bit 0 | `_IRHW_RxSetIsr` `.text+0x30fe24..0x30fe2c`; `_IRHW_RxIsr` `.text+0x30fdb4..0x30fdbc`; `IRRX_PollMtkIr` `.text+0x310324..0x31032c` | **IR receiver enable / re-arm, bit 0** (set after init and after every processed frame). DECODED. |
| `0x24240` | W 1 = `0` | `0` | `IRHW_RxInit` `.text+0x30ffe0` (only site in the module) | **IR side misc, zeroed at init, write-only**. INFERRED (no reader ⇒ name unprovable; 0 is the observed and correct value). |
| `0x24500..0x245bc` | 5 W + 3 R (`0x24500`), etc. | `0x1, 0x0f, 0xf000000, 0xfff1101, 0x40004019, …` | `_CEC_Init` `.text+0x2e2194..0x2e21b4`; `_CEC_Mainloop`; `_CEC_SendFrame`; `DDCM_TrigMode` `0x484` (different word) | **CEC control + TX/RX FIFO block** — outside the FE-ATA lane; listed so the tail's `0x245xx` traffic is not mistaken for FE. DECODED. |

*Note (a)* — `0x240d4 = 0x100` is written at tail 2 477 458 (VM 3 018 968) at the head of
the DDC/HDMI init burst, and `0x240f4 = 0x100` at tail 2 477 576 — the same value, same bit
8, two registers, neither of which any statically-resolved site ORs (`grep` for
`orr …, #256` across the 20 `0x240d0..0x240fc` sites: none). That pair is the signature of a
**generic set-bit helper with a runtime base argument** (`set_bit(reg, 8)`-shaped), i.e. the
one access class in this block that static resolution cannot attribute — and note it does
**not** extend to the `0x2420c/210/214` triple, which is fully attributed (§1). The two
`bic`-only writes to `0x240d4` in the same burst are `vInitDDCLine`'s
(`.text+0x2e36c8..0x2e36dc`). Flagged rather than guessed; irrelevant to FE-ATA.

---

## 3. What `R 0x2420c` value terminates the poll — and the bit that matters

**Nothing terminates it, and it is not a poll.** There is no driver-side compare whose
result depends on a *completion* value of `0x2420c`; the only bits the module ever tests
are:

| site | test | consequence |
|---|---|---|
| `IRRX_PollMtkIr` `.text+0x3102e0` | `tst r2,#262144` = **bit 18 (`0x00040000`)** | set ⇒ `.text+0x3102e8..0x310314`: increment `[0x144650+8]`, and for count > 1 print `ir state clear!,Cnt=%d` (`.rodata.str1.1+0xa6338`), for count > 9 print `ir state long clear !Cnt=%d` (`.rodata.str1.1+0xa631b`), then **ack + re-arm**: `0x24148 |= 0x2000` (`.text+0x310318..0x310320`) and `0x24218 |= 1` (`.text+0x310324..0x31032c`). clear ⇒ fall through to `.text+0x310330` (semaphore + software key-queue drain; **no MMIO**). |
| `IR_RxEnable` `.text+0x30fefc` | RMW `orr #1` / `bic #1` | bit 0 = receiver enable (not read back for a decision). |
| `i4IrHWUninit` `.text+0x3100a4` | RMW `orr #0x8000` | bit 15 = shutdown request. |

So: **bit 18 (`0x00040000`) of `0xfd02420c` is a sticky "IR receiver state needs
clearing" flag.** Its meaning is fixed by the module's own diagnostic strings and by the
remedy the code performs (re-arm), not by a datasheet: *DECODED* for "these are the only
bits tested and this is what the set-branch does", *INFERRED* for the natural-language name
(`model-spec.md` §3.1 calls bit 18 "data-available / packet-complete"; that label is
unsupported — a data-ready bit would be consumed as a frame from `0x200/0x204/0x208` with
the `_IRHW_RxIsr` path, and the set-branch consumes no data and prints "state clear").

The loop's real exit is the thread's stop flag: `IRRC_DataProcessingThread` loops on
`ldr r3,[r7,#0xc]; cmp r3,#0; bne .loop` (`.text+0x312120..0x312128` in the sibling
`_RxCLI_IrThread`; `IRRC_DataProcessingThread` is `for(;;)` with no test at all —
`.text+0x30ed30` unconditional back-edge). With the model returning 0 (or echoing
`0x111`, which also has bit 18 clear) the guest takes the benign branch forever, which is
what C95 shows: **12 945 reads, 0 writes to `0x24218`/`0x24148` after the init above, and
zero `ir state clear` / `ir state long clear` console lines** (string search over the whole
reconstructed console). The IR-subsystem console lines in the tail are exactly five:
`IRRX_InitMtkIr` (VM 3 194 828), `Not a BDP8.5G model, let FE try it.` (3 195 656),
`HW_FastejectKeyNotify arm2 eject` (3 195 882), `thread created: IRRX Thread` (3 196 927),
and `IRRX_DataProcessingThread, exit` (3 262 019) — plus 139
`[OSAL_STUB] Assert x… (last: …/irrx_if.c:1637)` lines, which are the OSAL semaphore
assert of the key-queue lock, not this branch.

**Model guardrail (new):** do **not** return bit 18 set from `0x2420c`. It would fire the
diag path on every iteration (~12 945 × (2 prints + 2 RMW writes)) and change the trace
shape of the whole post-EH era.

---

## 4. Model recipe rows

### 4.1 The `0x24200..0x2421f` bank (replaces `fe-ata-cmd.md` §5.1 rows 15–16)

| # | reg (VA / phys) | driver op | model must | why |
|---|---|---|---|---|
| 15a | `0xfd02420c` / `0x7002420c` | `W` (`IRHW_RxInit` `.text+0x30fff4`, `IRHW_RxWrConf` `.text+0x30fec8`); `R` (`IRHW_RxRdConf` `.text+0x30fe98`, `IRRX_PollMtkIr` `.text+0x3102dc`, `IR_RxEnable`, `i4IrHWUninit`) | store on `W`; on `R` return the stored value **with bit 18 (`0x00040000`) guaranteed clear** (echo of the stored `0x111` is fine; a constant `0` is equally fine). Never set bit 18. | only bit 18 is branched on; storing keeps the CLI status dump self-consistent |
| 15b | `0xfd024210` / `0x70024210` | `W` (`.text+0x30fff8`, `.text+0x30fecc`); `R` (`.text+0x30fea0`) | store; echo | config word 1 (225 at init) |
| 15c | `0xfd024214` / `0x70024214` | `W` (`.text+0x30fffc`, `.text+0x30fed0`); `R` (`.text+0x30fea8`) | store; echo | config word 2 (512 at init) |
| 16 | `0xfd024218` / `0x70024218` | `R`+`W` RMW `|=1` (`_IRHW_RxSetIsr` `.text+0x30fe24..0x30fe2c`, `_IRHW_RxIsr` `.text+0x30fdb4..0x30fdbc`, `IRRX_PollMtkIr` `.text+0x310324..0x31032c`) | store; `R` = stored value. Must be a lossless RMW. | bit 0 = receiver enable / re-arm |
| 17 | `0xfd024200/204/208` | `R` only (`_IRHW_RxIsr` `.text+0x30fd40/0x30fd4c/0x30fd54`) | return `0` | "no IR frame"; a nonzero answer would fabricate a remote-control key (and `_IRHW_RxIsr` only runs on a real IR interrupt, which the model never raises) |
| 18 | `0xfd024240` | `W` only (`.text+0x30ffe0`) | store, no read case needed | write-only, always `0` |
| 19 | `0xfd024088` | `R` (`IRHW_RxInit` `.text+0x30ffb8`) | return `0` (bit 8 clear) | otherwise the driver logs `[Wake up] IR wake up!!` and reports a spurious wake source |
| 20 | `0xfd024080`, `0xfd02408c` | RMW `bic #256` / `W 1` | store + echo (lossless RMW) | wake-up enable/ack |
| 21 | `0xfd024040` | RMW, bits 1 / 13 | store + echo (lossless RMW) | IR block reset (bit 1 = in reset) |
| 22 | `0xfd024044` | RMW `bic #15 / orr #3` | store + echo | IR clock/pin select nibble |
| 23 | `0xfd024188` | RMW bits 1/12/20; direct write `0x45`/`0x245` | store + echo; **bit 1 must read back after `_vCommonSRAMInit`** | shared SRAM clock; `VSFHW_SramStatus` is a plain read-back |
| 24 | `0xfd0241c0` | `R` (`HW_FastejectKeyNotify` `.text+0x31013c/0x310148`) + RMW writes (`_ifcon_*`) | return `0` **today** (keeps the "Not a BDP8.5G model, let FE try it" fallback); to model a BDP8.5G-class unit later, return bit 16 (`0x10000`) and honour the resulting fast-eject path (a separate, larger change) | board/feature register |
| 25 | `0xfd0241d0` | `R` (`IRRX_FastEject_Init`, `MW_IFCON_Init`, sata `PreparePwrOnParm`) | return `0` **today** (bit 7 clear ⇒ no fast eject; `tst #2` in `PreparePwrOnParm` stays false) | board config / model id |
| 26 | `0xfd024144` / `0xfd024148` | RMW mask / W1C ack (IR, CEC, DDCM ISRs) | store + echo lossless for `0x144`; `0x148` accept-and-store (W1C semantics not required — nothing reads it for a decision on the executed path) | IRQ enable/ack. **Not** required for the ATA lane: no ISR in C95 depended on it (no IR/CEC/DDCM interrupt is raised by the model) |
| 27 | `0xfd024030` / `0xfd024034` | `W 0x85` then `W 0` or `W 1` (reset command + level); `R` = status | store; `R` = stored | already the FE half of the block; unchanged from `kernel-iomap.md` §"0xfd024000" |

Rows 15a–18 are a *relabel + one guardrail* of what `model-c96-diff.md` §1 row 15/16
already implements (`fe_csr[8]` over `0x24200..0x2421f`, echo). Rows 19–27 are new
information for the IR/CEC/DDC neighbours, which today fall through the unimplemented
default — that is **harmless for the ATA path** (proof: §5) and only affects the IR
remote-control and front-panel lanes.

### 4.2 What the FE-ATA model does **not** need from this block

* No `0x242xx` value gates, terminates, or orders any FE mailbox access. The FE-ATA model
  rows of `fe-ata-cmd.md` §5.1 (1–14) stand unchanged; row 15's "ladder" is deleted
  (there is no poll to satisfy) and row 16 stands as written.
* `0x2420c` needs no "completion" semantics at all.

---

## 5. Does the poll block the ATA IDENTIFY path? — **Parallel. No overlap in C95.**

Three independent arguments:

**(a) Static: the reader is not reachable from the ATA path.**
`IRRX_PollMtkIr`'s four callers are all IR-lane (`IRRC_DataProcessingThread`, `IR_Diag`,
`_RxCLI_PollKey`, `_RxCLI_IrThread` — §1.1). No libata callback
(`qc_issue`/`data_xfer`/`check_status`/`tf_load`/`exec_command`/`prereset`/`softreset`/
`port_start`/`interrupt`) nor `sata_mt85xx_mod.ko` reaches it; the SATA module has no
`0xfd0242xx` access at all (`decode/map.txt`). The thread sleeps
(`x_thread_delay(10)`, `.text+0x30ed28`) between iterations, so even the worst case is one
`ldr` per scheduler tick, not a busy-wait.

**(b) Trace ordering: the block does not exist anywhere near the IDENTIFY window.**
Post #3 (`IDENTIFY PACKET`, `w0=0xa1000000 w2=0x0000a000`) is at VM 541 480, i.e. 31 lines
before the committed tail begins; libata's `qc timeout (cmd 0xa1)` prints at VM 621 578;
the EH cycle ends with `reset failed, giving up` / `EH complete` at VM 2 874 442–2 874 751. In the tail, **the first
`0x24xxxx` access of any kind is at tail line 2 477 452 = VM 3 018 962** — 2.4 M trace
lines *after* the IDENTIFY post and 144 k lines after EH gave up. Census of the tail's
first occurrences (VM): `0x240d8` 3 018 962 · `0x240f4` 3 019 084 · `0x24040` 3 141 032 ·
`0x24144` 3 123 026 · `0x24188` 3 123 054 · `0x241d0` 3 195 233 · `0x2420c` (W) 3 194 791 ·
`0x2420c` (first R) 3 231 501 · `0x24218` 3 194 990. The last ATA mailbox post of the run
(`0x08`, cmd#13) is at VM 2 793 661 — 400 k lines *before* the IR init.
So in C95 the IR poll neither blocks nor overlaps the ATA path: the two are separated by
the entire EH cycle.

**(c) Interleaving shape: the reads are interrupt-interleaved, not back-to-back.**
Consecutive `R 02420c` gap statistics over the 12 944 gaps: min 172, median 178, mean 196
lines; 11 968 gaps in the 150–199 bucket. Between two reads the trace shows ~8 complete BIM
interrupt bursts (`R 008034/008030/00813c/008138/008158/008154` + the `0x44000` /
`0x8044000` mask shuffle) plus, occasionally, a UART console line — i.e. the CPU is running
other work between iterations. A spin-wait would show thousands of consecutive reads.

**Consequence for the C96/C97 recipe:** the 12 945-read `0x2420c` signature is *not* an
observable of the FE model at all — it is background IR-thread traffic. It must not be used
as a pass/fail signal, and its presence/absence says nothing about the IDENTIFY outcome.
(The prediction "the absence of a `0x2420c` read loop in the same window" in `fe-ata-cmd.md`
§6 is withdrawn: the loop was never in that window.)

---

## 6. Corrections to the existing docs

| doc | claim | correction |
|---|---|---|
| `fe-ata-cmd.md` §0.7 | "the `0x242xx` poll is the FE/HAL CSR block … writer not attributable … INFERRED computed-base/table-driven" | Owner is `IRHW_RxInit` (bdpdrv `.text+0x30ff80`); reader is `IRRX_PollMtkIr` from a sleeping thread; base is the ordinary pool literal `0xfd024000`; attribution DECODED (+ order-exact match). |
| `fe-ata-cmd.md` §4.2 | "descriptor setup (addr/addr/len) + start bit + completion poll"; "bounded in time by libata"; ladder of completion values | It is IR config + IR enable; no descriptor, no start bit, no completion poll; the loop is a thread with a 10-tick delay and a RAM stop flag. |
| `fe-ata-cmd.md` §5.1 row 15 | "`R 0x2420c`: return a 'complete' value — first try `0x111` … ladder `0x111, 0x1, 0x2, 0x111\|0x200, 0x200, -1`" | Delete the ladder. Requirement is exactly: **bit 18 clear**. |
| `fe-ata-cmd.md` §6 | "the absence of a `0x2420c` read loop in the same window" as a success observable | Withdrawn — see §5. |
| `run-c94-c95.md` §3 | "**SATA HAL hw-init block** `0x242xx`" | IR receiver bank inside the shared host/SIF block; nothing to do with SATA. |
| `model-spec.md` §3.1 | bit 18 = "data-available / packet-complete" | The only supported reading is "IR receiver state needs clearing" (the set-branch prints `ir state clear!` and re-arms; it consumes no data). The rest of §3.1 (bit-18 test site, one `ldr` per call, thread cadence) is confirmed. |
| `kernel-iomap.md` §`0xfd024000` | "FE block **and** the secondary interrupt controller" | Correct but incomplete: the same 4 KiB also hosts IR RX (`+0x200..+0x240`), CEC (`+0x16c`, `+0x500..`), DDC/I²C bit-bang (`+0xd0..+0xf8`), wake-up (`+0x080/+0x088/+0x08c`), SRAM clock (`+0x188`), board/model detect (`+0x1c0/+0x1d0`). |

No model source was edited in this run (the recipe rows above are for the model owner);
`emulator-kit/sony-bx510.c` and `tools/` were not touched.

---

## 7. Residual INFERRED items and their settling experiments

| item | label | experiment |
|---|---|---|
| `0x2420c` bit 18's datasheet-level name (**"IR state error/stuck"**) | INFERRED (from the module's own `ir state clear!` strings + the re-arm remedy) | Not reachable by static means. Only matters if the IR lane is ever modelled seriously; a Hardware-level answer would need the MT85xx IR block documentation. No effect on the FE/ATA model (clear bit = benign). |
| `0x24044[3:0]=3` field name (clock/pin select) | INFERRED | model needs nothing; a C9x run with `0x44` returning nonzero would show whether the driver re-reads it. |
| `0x240f4` low-nibble pin select vs bits 23/24 (SCL) vs bit 26 (CEC) sharing one register | DECODED for the bits each function touches; INFERRED for the "shared pin-mux" reading | needs the front-panel/HDMI pin table (not in this module). |
| which single function wrote `0x240d4 = 0x100` (note (a)) | UNRESOLVED (20 candidate sites) | `resolve_addrs.py --lo 0x700240d0 --hi 0x70024100` + a per-site value match; irrelevant to FE-ATA. |
| `0x241c0` bit 16 semantics ("BDP8.5G model") | DECODED for the *consequence* (console string ↔ `tst #0x10000`); INFERRED for the name | set bit 16 in the model and watch which additional code paths arm (fast-eject / IR eject) — a deliberate, separately-scoped change. |
| whether the 12 945 reads came from `IRRC_DataProcessingThread` exactly (vs `_RxCLI_IrThread`) | DECODED (single `ldr`, no companion `0x210/0x214` read, no write; the only 1-access reader) + console `x_thread_delay … caller=IRRC_DataProcessingThread` in the same era | byte-identical read shape between the two callers; a PC-trace run would separate them and change nothing for the model. |

---

## 8. Reproduction

```
cd evidence/bx510-guest/bdpdrv/decode
python3 resolve_addrs.py --reach 0x7002420c      # owner/reader cite set (committed tool)
python3 resolve_addrs.py --reach 0x70024218
python3 resolve_addrs.py --reach 0x700241c0
python3 resolve_addrs.py --lo 0x70024200 --hi 0x70024250   # the whole IR bank
# trace census (committed tail; gz line N == VM line 541510+N)
python3 - <<'EOF'
import gzip,re,collections
L=gzip.open('bdpdrv-runC95.posthandshake.mmio.gz','rt').read().split('\n')
r=re.compile(r'bx510: MMIO ([RW]) ([0-9a-f]{6}) sz(\d)( = ([0-9a-f]+))?$')
c=collections.Counter(); f={}
for i,l in enumerate(L):
    m=r.match(l)
    if m and m.group(2).startswith('024'):
        k=(m.group(1),m.group(2)); c[k]+=1; f.setdefault(k,(i,i+541510))
for k in sorted(c,key=lambda k:(k[1],k[0])): print(k,c[k],'first',f[k])
EOF
```
