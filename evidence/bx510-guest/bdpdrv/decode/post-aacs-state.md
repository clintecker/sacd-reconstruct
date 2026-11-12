# BX510 post-AACS state machine — the LOGO command, `0x24188`, and where Run C91 actually stops

Decode of Run C91 (the first run where the FE boot chain completes end to end)
against Sony's `bdpdrv.ko` and `sata_mt85xx_mod.ko`. Answers five questions:
what the `0x5c010 = 'LOGO'` write is, what the `0x70024188` read-modify-write
rounds are, which subsystem initialises next, which function (if any) is
parked, and how the UART lines up with the trace.

**House rules.** Every claim is **VERIFIED** (read out of an instruction, the
trace, the UART, or the model source — and re-derivable by the two scripts
below) or **INFERRED** (reasoned). §6 lists what did not resolve.

---

## 0. Bottom line

1. **The `0x5c010 = 'LOGO'` write is not a command with a completion handshake.**
   It is a single store, executed as the **last statement of
   `sata_mt85xx_init`** (`sata_mt85xx_mod.ko .init.text+0xd0c`), that puts the
   dword `0x4f474f4c` (`'L','O','G','O'`) into the FE/IDE mailbox word 4.
   **Nothing in either module ever reads that address** — not bdpdrv, not the
   SATA module. No reply, no `0x5c804` bit16, no polling. *VERIFIED.*
2. **`0x70024188` is not a mailbox, a command index, or a sibling of
   `0x700240f4`.** It is the shared **SIF/SRAM clock + bus-ownership** register:
   four subsystems own one bit each and every access is a read-modify-write of
   their own field. The trace's three rounds (`0x0`, `0x2`, `0x0`) are three
   *different* subsystem inits — `_CEC_Init`, `_vCommonSRAMInit`, `IRHW_RxInit`
   — not a three-step protocol. Nothing has to "reply" for them to advance.
   *VERIFIED (instruction-cited, §2).*
3. **bdpdrv does a large amount of work after the LOGO write, and finishes.**
   Audio clock + DSP table load, CEC, DDC, HDMI gamma, video NR, the VDP planes,
   HDMI TX info frames, IR, VFD, OSD — then it settles into its two poll
   threads. `BDPDRV_INSMOD=0` (UART line 1532) proves module init returned.
   *VERIFIED (§3).*
4. **There is no parked driver thread.** The last 2,045 trace lines contain
   exactly **nine** addresses, all belonging to two healthy poll threads
   (`IRRX_PollMtkIr` and the VFD command pump), and the last event of the run is
   one of those polls. The run ends because the **harness's terminal marker
   matched the tty echo of its own final command**, not because the guest
   wedged: `emulator-kit/smoke.py:63` tests `all(item in data for item in
   wanted)` with `wanted = [b"STUB_DONE"]` over the raw console stream, and the
   last command typed is `echo STUB_DONE`. The same file already documents the
   defence it does not apply here ("Split the marker so a local terminal echo
   cannot pass the shell check", `smoke.py:90`). *VERIFIED (§4.1).*
5. **The one hardware-facing wait that really did time out in this run is the
   FE handshake's second message**, and the trace pins it exactly: 201 writes to
   `0x7005c804` = one message-A iteration + **200** zero iterations
   (`chk_int_ldr`'s `cmp r7,#200` × `msleep(10)` = 2 s), matching UART line 282
   `wait status interrupt timeout !`. Root cause is one line in the model: the
   ACK branch sets `fe_msg = 2` ("drained") while posting message B, so the
   pending bit for message B is never visible (`sony-bx510.c:499-505`).
   *VERIFIED (§4.2).*

**The one thing the model must do next:** in `sony-bx510.c`, the `0x5c020`
ACK branch must leave `fe_msg = 1` (message B pending) instead of jumping to
`2`; `fe_msg` should only reach 2 when a `0x5c804` **read** consumes message B.
That converts the 2-second timeout into the reply the driver's acceptance gate
is waiting for (`0x5c040..0x5c04c` all zero → `type 0`, `err 0` → `*out = 1`).

---

## 1. Provenance and method

| input | identity |
|---|---|
| `bdpdrv.ko` | sha256 `6604f6cd6c204c3399ac047f389f47162b06a3f6576159f21b4e8aaf3a72cf54`, 8,122,068 B |
| `sata_mt85xx_mod.ko` | sha256 `8a0253eb9bff19a3d3c0ac594a507235bad82348d8e80069024368d0f5456657`, 69,452 B |
| MMIO trace | `bdpdrv-runC91.mmio.log`, 4,729,901 B, 119,045 lines → **34,961 MMIO events**, 1,918 distinct addresses |
| UART | `bdpdrv-runC91.uart.log`, 91,770 B, 1,868 lines |
| meta | `bdpdrv-runC91.meta.json` — `terminal_marker: true`, qemu `/home/aftermath/bx510-emu/.../qemu-system-arm` |
| model | `emulator-kit/sony-bx510.c` (the `0x5c020` / `0x5c804` / `0x8118` cases) |

Address translation is `model-spec.md` §1: the driver stores kernel VAs and
`phys = virt - 0x8d000000`; all MMIO below is printed as **PA**.

Two scripts carry every claim, both with self-checks that fail on drift:

```
python3 decode/post_aacs_trace.py  --checks   # 14 assertions on the trace
python3 decode/post_aacs_static.py --checks   # 13 assertions on the binaries
```

`post_aacs_trace.py` also has `--phases`, `--subsystems`, `--regions`, `--new`,
`--rmw`, `--tail`, `--thread-map`; `post_aacs_static.py` has `--logo`,
`--sram`, `--fastlogo`. Both exit non-zero if any check fails.

**Caveat that governs §3.** Only **unimplemented** accesses reach the `-d unimp`
log. Everything `sony-bx510.c` answers (BIM `0x8000..0x81b4`, `0x8118`,
`0x5c000/0x5c020/0x5c040/0x5c704/0x5c804`, the ATA window, the DSP ports,
`0x324180/0x324184`) is **invisible** in the trace. Absence from the log is not
evidence of absence (`kernel-iomap.md` §6).

---

## 2. The `0x5c010 = 'LOGO'` write

### 2.1 The instruction

`sata_mt85xx_mod.ko`, `.init.text+0xd00..0xd14` — the tail of
`sata_mt85xx_init` (the `module_init` function):

```
0xd00  ldr  r3, [pc,#0x40]     ; pool 0xd48 = 0xfd05cfff  (block base, pre-biased)
0xd04  ldr  r2, [pc,#0x9c]     ; pool 0xda8 = 0x4f474f4c  ('L','O','G','O')
0xd08  mov  r0, #0
0xd0c  str  r2, [r3,#-0xfef]   ; *(u32*)0xfd05c010 = 0x4f474f4c
0xd10  add  sp, sp, #20
0xd14  pop  {r4-r11, pc}       ; return 0
```

`.init.text+0xd0c` → VA `0xfd05c010` → **PA `0x7005c010`**. *VERIFIED.*

Control flow: the block is the common tail. The success path leaves the
per-channel loop at `.init.text+0xb30` (`b 0xce0`) after the two
`ata_host_activate` calls (`R_ARM_CALL` at `+0xb6c`, `+0xb90`), and the
`platform_device_register_simple`-error path (`.init.text+0xcc8`) also branches
to `0xce0`; `0xd08` then sets the return value to 0. So **`sata_mt85xx_init` writes
`'LOGO'` on every load**, as its last act, after the port has been brought up
and handed to libata.

### 2.2 What it expects back: nothing

`post_aacs_static.py --logo` decodes every load/store in both modules whose
effective address is `0xfd05c010`:

| module | sites |
|---|---|
| `sata_mt85xx_mod.ko` | **1 store** (`.init.text+0xd0c`), 0 loads |
| `bdpdrv.ko` | **0 accesses at all** |

That is the whole census. There is no reader, so there is no completion
protocol: **no `0x5c804` bit16, no status word, no poll.** The `0x5c804`
activity that follows the LOGO write in the trace belongs to the FE interrupt
top half draining messages that the earlier `chk_int_ldr` call left behind
(§4.2), not to the LOGO write.

Reading `0x5c010` in the block map: the CPU→FE command block is
`0x5c000/04/08/0c` (four words) plus doorbell `0x5c020`
(`fe-status-handshake.md` §2), so `0x5c010` is **word 4** of that block — a
second, doorbell-less mailbox slot. The value is a literal ASCII dword, which
is the classic "post a magic opcode to the front-end MCU" idiom. **INFERRED:**
the FE's `LOGO` state means "show the boot logo"; the FE firmware is factory
programmed and not in anything we hold, so what it does with the word cannot be
proven from the driver side.

### 2.3 The real FastLogo handshake is somewhere else (and already answered)

The FastLogo/audio-init handshake the brief points at is **independent of
`0x5c010`**, and it lives in bdpdrv:

```
vAudInitThread (.text+0x2c330)
0x2c340  ldr  r4, [=0xfd008000]        ; BIM block base
0x2c348  ldr  r5, [r4, #0x118]         ; 0xfd008118 -> PA 0x70008118
0x2c34c  cmp  r5, #64                  ; must read 0x40
0x2c350  moveq r0,#5 ; ... print "get FastLogo_STATUS: 0x%x"
0x2c360  mov  r0,#100 ; delay(100 ticks) ; ++r6 ; 11 tries then loop forever
```

*VERIFIED* — `post_aacs_static.py --fastlogo` recovers the base literal and the
`#0x118` load. The format string is `.rodata.str1.1+0xb0d3`
`"[AUD_IF] Audio Init Thread get FastLogo_STATUS: 0x%x. \n"`.

The model answers `0x8118` with `0x40` (`sony-bx510.c:268`), so the poll passes
on its **first** read — consistent with the UART, which never prints the
status-timeout line and instead shows
`[AUD][AUD_IF] Audio Init Thread is destroyed automatically.` (line 719). The
address `0x70008118` therefore never appears in the MMIO log: it is *answered*,
not untouched. **Not a gap.**

One driver-side complaint is worth recording: `OSD_SC_Scale`
(`.text+0x20071c`, string `[osd_scaler_if]fastlogo didn't run first.`) prints
once at UART line 1105, during the OSD phase. That is bdpdrv noting the scaler
was programmed before its own FastLogo OSD path ran — a sequencing note inside
the driver, **not** an FE handshake and not related to `0x5c010`. **INFERRED
benign** (the run continues normally for another 26,000 trace lines).

---

## 3. `0x70024188` — a shared per-subsystem bit field, not a mailbox

### 3.1 What the register is

`post_aacs_static.py --sram` resolves every read of `0xfd024188` in bdpdrv and
decodes the AND/ORR the compiler placed between the load and the store:

| owner | site | operation |
|---|---|---|
| `_vCommonSRAMInit` | `.text+0x2accc8` | `orr #2` (bit 1) |
| `i4NR_Suspend` | `.text+0x2a67a0` | `bic #2` (bit 1) |
| `i4NR_Uninit` | `.text+0x2a7294` | `bic #2` (bit 1) |
| `_CEC_Init` | `.text+0x2e2184` | `bic #0x1000` (bit 12) |
| `IRHW_RxInit` | `.text+0x31000c` | `bic #0x100000` (bit 20) |
| `i4EtherDrv_Init` | `.text+0x1350c8` | `bic #0x10000000` (bit 28) |
| `VSFHW_SramClk` | `.text+0x130bf8` | whole-word write (`0x45` or `0x245`) |
| `VSFHW_SramStatus`, `_SifMRead`, `_DDCMRead`, `SIF_RanAddr_Write`, `DDCM_RanAddr_Write` | — | read only |

**VERIFIED.** One register, one bit per subsystem, standard read-modify-write
ownership — the same idiom as `0x700240f4` but a *different register with a
different meaning* (`0x240f4` is pending/ack; `0x24188` is clock + bus
ownership). It is **not** a command slot and **not** a sibling of `0x240f4`.

That the readers treat bit 20 as a *bus-ownership guard* and not as a
completion flag is visible in `_SifMRead` / `_DDCMRead`
(`.text+0x21f024` / `.text+0x21ec14`), which do a **one-shot** test:

```
ldr r3,[base,#0x188] ; tst r3,#1048576 ; beq <proceed>
                     ; if set and offset >= 456 -> abort the transfer
```

No loop, no retry, nothing to advance. **VERIFIED.**

### 3.2 The three rounds in the trace

`post_aacs_trace.py --rmw` finds read→write pairs on the register; after the
LOGO write there are exactly three:

| trace line | read returned | written | owner (from the contiguous event pattern) |
|---|---|---|---|
| 87974 | `0` (unimplemented read) | `0x0` | `_CEC_Init` — `bic #0x1000`, immediately followed by `0x24504=0xf`, `0x245bc=0x40004019`, `0x24500=0x1`, then its 9-word timing table |
| 88122 | `0` | `0x2` | `_vCommonSRAMInit` — `orr #2`; the writes immediately before are `0x70044804 = 0xfe000000` / `0x0` (`_vNRHWReset`), the video-NR block |
| 89891 | `0` | `0x0` | `IRHW_RxInit` — `bic #0x100000`; the writes immediately before are its own config triple `0x2420c=0x111`, `0x24210=0xe1`, `0x24214=0x200` |

The values follow mechanically from "the model returns 0 for an unimplemented
read, then each function clears/sets its own bit" — `0x0`, `0x2`, `0x0` is what
`bic`, `orr`, `bic` produce against a zero base. **No protocol, no reply.**

**What a faithful model needs here:** a plain 32-bit read/write register
returning the last value written, so the bits accumulate across subsystems.
Today it returns 0 always; that is harmless for the *writes* (each function
re-derives its own field) and only becomes observable if some future read-back
checks another subsystem's bit. **INFERRED** — no such reader exists today.

---

## 4. What bdpdrv does after the LOGO write

### 4.1 The order (trace line ranges)

`post_aacs_trace.py --subsystems --lo 83930 --hi 119045` run-lengths the block
label over consecutive events and names the likeliest owners per run. The run
after the LOGO write, compressed to the phase boundaries:

| lines | subsystem (block) | owner family |
|---|---|---|
| 83930-84012 | BIM/efuse, then audio clock | `AUD_HwInit`, `vExtSPDIFInIRQInit`, `vHal_SetCcirOutPinMux`, plus **DDC** (`fgDDCStart`, `vDDCRead`, `vDDCStop`) |
| 84019-86084 | CKGEN/clock (1,972 events) | `vAudHalSetDspBlkRegInit`, `vAudHalSetDspABBlkRegInit`, `_DMX_HWConfig` — audio DSP block/clock setup |
| 86091-87957 | audio DSP load port (1,838) | `vAudHalSetDspLoadTable` (the `0x47108` write-then-read-back verify loop) |
| 87971-88033 | FE shared control (63) | **`_CEC_Init`** + `vInitDDCLine` |
| 88048-88103 | video path | `vHalBlackHDMIOnly`, `vWriteGammaReg` / `vGetGammaReg` |
| 88133-88354 | video NR (222) | **`_vNRParaInit`** (110 addresses), `_vNRSetQualityParameter` |
| 88411-89486 | video planes (4 × 269) | `VDP_HalReset`, `vDispVfSet_*`, `vVDP_HalGetVSyncStatus` — plane 0 / plane 1 twice |
| 89511-89779 | HDMI TX | `vHwSet_Hdmi_I2S_C_Status`, `vHalSend{AVI,Audio,SPD}InfoFrame`, `vSetPLLGP_HDMIDDS` |
| 89783-89802 | panel mux | `PMX_HalSetMode`, `PMX_IsrInit`, `PMX_HalEnableMute` |
| 89882-89901 | FE shared control | **`IRHW_RxInit`**, `IR_RxEnable` |
| 89920-90051 | VFD + OSD | `IFcon_Init`, `i4VFDTrigQueModeStart`, `OSD_BASE_Dump`, `_GfxCmdDrawRect` |
| 90058-119045 | the poll set only (28,735 events, every address in four 4 KiB pages) | `i4VFDIndirectSIFCmdRegMode` pump + `IRRX_PollMtkIr`, with the occasional one-shot (IR re-init, a CEC command, an OSD update) |

Note what is **not** in that list but was asked about: the framebuffer driver
`_mt8530fb_*` contributes **no MMIO at all** — it is a Linux `fb_info` /
memory-manager client (`fb_decode_functions.py`: allocations, `remap_pfn_range`,
a 17-command ioctl chain). Its hardware programming happens through the OSD/GFX
layer, which is why the OSD phase above (`OSD_BASE_Dump`, `_GfxCmdDrawRect`) is
the visible part of the same bring-up.

### 4.2 No new MMIO regions

`post_aacs_trace.py --new` diffs C91 against the Run C50 trace: 10 addresses new.
Against the **union of every prior run** in `evidence/bx510-guest/bdpdrv/`
(`runC2`, `runC5x`, `trace*`, `stub*`) it is **6**:

| address | block | first seen | already documented |
|---|---|---|---|
| `0x70024030` | FE reset command | 50902 | sata-fw-load.md §5(b) (`*[0xfd024030] = 0x85`) |
| `0x7005c600` | FE DRAM wrapper enable | 50910 | kernel-iomap.md §7 item 5 |
| `0x7005c604` | same | 50911 | same |
| `0x7005c704` | FE reset release | 50906 | fe-status-handshake.md §2 |
| `0x7005c780` | FE clock enable | 50917 | same |
| `0x70324b00` | loader-done flag | 50901 | sata-fw-load.md §5(a) |

So the post-AACS path asks the model for **nothing it has never been asked
for**; the whole bring-up walks blocks the model already logs. The gaps it does
expose are *semantic* (what a register returns), not *addressed* — which is why
§4.3's answer is about a flag, not a register.

### 4.3 The end of the run: nine addresses, two threads, no spin

`post_aacs_trace.py --thread-map --lo 117000 --hi 119045`:

```
addr          n    first    last   owners
0x7002420c   874  117006  119045   IRHW_RxInit,IRHW_RxRdConf,IRRX_PollMtkIr,...
0x70050320   447  117000  119033   i4VFDWaitBusy,IFconWaitHWBusy,i4VFDTrigRegModeStart,...
0x700240f4   178  117015  119025   i4VFD_Resume,i4VfdScanKeyWithDriver,IFcon_Init,...
0x700503{00,04,08,0c,10,14}   ~90 each  ... i4VFDIndirectSIFCmdRegMode
```

Nine addresses. Two threads, both cycling to the last line of the log. There is
no high-rate repeated read of a single *new* register anywhere after line
90,100 (`--regions` for that window returns four 4 KiB pages, two of them the
threads, one clock page with 14 reads and one BIM event).

And the module init returned:

```
uart:1532  BDPDRV_INSMOD=0
```

So the guest was neither blocked in `insmod` nor spinning in a driver wait at
the moment the run ended. Whatever stopped Run C91, it was not a driver
register wait — see §5.1.

---

## 5. The stall

### 5.1 The end-of-run "stall" is the harness, not the guest

The UART's last line (1868) is

```
/ # echo STUB_DONE
```

with the prompt, the **tty echo of the typed command**, and no output.
`emulator-kit/smoke.py` explains both halves:

```python
# smoke.py:63 — inside observe()
if all(item in data for item in wanted):
    break
# smoke.py:86 — inside check(), the defence the probe does not use
# "Split the marker so a local terminal echo cannot pass the shell check."
```

`tools/bx510_bdpdrv_stub_probe.py` sets `wanted = [b"STUB_DONE"]` and its last
two commands are `"echo STUB_DONE"` and `"/sbin/poweroff -f; ..."`. The moment
the tty echoes `echo STUB_DONE`, the substring test succeeds, `observe()` breaks
and the `finally:` block sends `SIGINT` — which is also why the `-D` log has
4.7 MB (a clean interrupt flush, not SIGKILL) and why `/sbin/poweroff` never
appears in the transcript. `terminal_marker: true` in the meta file is a **false
positive**.

Consequently "STUB_DONE never reached" is true but not diagnostic: the marker
was satisfied by the echo, the guest was healthy (both poll threads alive at the
last trace line, `BDPDRV_INSMOD=0`, and the immediately preceding
`sleep 3; echo CLI_DRAIN2` had produced real output), and the run was cut ~0.5 s
after the command line appeared. **VERIFIED** from the code path plus the
transcript ends.

**Recommended harness fix (one line, no driver impact):** make the emitted text
differ from the echoed text, e.g. send `echo STUB'_'DONE` — the shell prints
`STUB_DONE`, the echo shows the quoting — or reuse `smoke.check`'s own
`printf 'BX510_%s ...'` split-marker idiom.

### 5.2 The wait that *did* time out: `chk_int_ldr` message B

Independent of the harness question, Run C91 contains exactly one FE handshake
that timed out, and the trace measures it. `post_aacs_trace.py --checks`:

* between line 83600 and port_start's final `0x7005c800 = 0xfffffff0`
  (line 83898) there are **201** writes to `0x7005c804`;
* the **first** is `0x10000` (bit 16 seen — message A), all **200** after it are
  `0x0`;
* `chk_int_ldr` writes its accumulator once per iteration
  (`.text+0x28b0`, after re-zeroing it at `.text+0x2880` for each message) and
  bounds the poll with `cmp r7,#200` (`.text+0x289c`), sleeping 10 ms per
  iteration — 200 × 10 ms = **2 s**.

That is the mechanism behind UART line 282
`[IDE]<sata_mt85xx_id_atapi_dev>wait status interrupt timeout !`, and the line
before it, 281, proves message A was delivered correctly:

```
copy from (0xdfc01000, 0x200) to (0xc6264c60, 0x200)
```

i.e. `svoif_int_ldr_dram` (`0xdfc00000`) + `w1` (`0x1000`) and `w2` (`0x200`) —
exactly the message-A fields `fe-status-handshake.md` §7 prescribes.

**Why message B never becomes visible.** `emulator-kit/sony-bx510.c`, the
`0x5c020` doorbell write case:

```c
if (code == 0xa1) {                       /* chk_int_ldr entry */
    s->fe_msg = 0;                        /* message A pending  */
} else if (type == 0x10) {                /* table-data ACK     */
    s->fe_msg = 1;
}
...
} else if (s->fe_msg == 1) {              /* post message B ... */
    s->fe_status[0] = s->fe_status[1] = s->fe_status[2] = s->fe_status[3] = 0;
    s->fe_msg = 2;                        /* ... and call it drained */
```

and the `0x5c804` read:

```c
if (s->fe_booted && s->fe_msg < 2) { s->fe_msg++; return 0x00010000u; }
return 0u;
```

The ACK sets `fe_msg = 2`, so the very next read of `0x5c804` returns 0 even
though message B's status words are already staged. The driver's next iteration
therefore writes `0x0` (trace line 83695, four lines after the message-A
write at 83694 — the three intervening lines are the CPSR-noise lines of the
interrupt entry), then burns the 200-iteration poll.

**The fix is that one assignment:** leave `fe_msg = 1` after the ACK, and let
the *read* that consumes message B move it to 2. Then `chk_int_ldr` sees bit 16,
reads `w0..w3` = all zero, takes the `type == 0` / `err == 0` path, runs the
acceptance gate on the DMA'd block (`'O','B','T','O'` at `0x2e..0x31` plus
`0xeeee` at `0x100` — already implemented), sets `*out` (`port+0x208`) = 1 and
returns 0. Cost of leaving it: 2 s per `port_start` call and `port+0x208`
stuck at 0 (`sata_mt85xx_data_xfer` reads that flag for the ATA-18 vendor-string
override, fe-status-handshake.md §9.3).

**Scope honesty.** This is the FE internal-loader handshake. It is **not** why
`ata1` fails to appear: the disc-less outcome in this run is the libata
IDENTIFY path dying on the SATA engine's status/IRQ model
(`ata1.00: qc timeout (cmd 0xa1)`, UART 289; `ata1: reset failed, giving up`,
UART 306/326), which is `ata-probe-path.md` §5/§6's subject. The two failures
are independent in the trace and the causal link between them is **not**
established here. **INFERRED independent.**

### 5.3 The `0x5c804` write runs, all six of them

For completeness (`post_aacs_trace.py --tail`/manual grouping), the register is
written in six separate runs in the run:

| trace lines | writes | what it is |
|---|---|---|
| 50912 | `0x10000` ×1 | `xfer_int_ldr_fw`'s "clear default interrupt" RMW (`.text+0x197c/0x1980`) |
| 50922 | `0x10000` ×1 | `port_start` state-1 poll, bit 16 already set → passes (UART 277-278) |
| 83694-83695 | `0x10000`, `0x0` | `chk_int_ldr` message A, then the first message-B iteration |
| 83699-83897 | `0x0` ×199 | the rest of the 200-iteration message-B poll → UART 282 |
| 83900 | `0x0` ×1 | the FE IRQ **top half** entering at the `0x5c800` read (83899) and finding nothing pending — its `ldr 0x5c804` returned 0, so it wrote 0 and left |
| 83921-83923 | `0x10000`,`0x10000`,`0x0` | the same top half entering again (mask read 83920) and draining **two** messages: two `0x10000` reads then the zero that ends the loop. The `0xa1` doorbell that made fe_msg 0 again is invisible (`0x5c020` writes are model-implemented), so the posting call cannot be dated from the log |

`207 = 1 + 1 + 2 + 199 + 1 + 3`, which is the complete census of that register
for the run.

The last row is worth flagging for the model: the top half and `chk_int_ldr`
are two consumers of one read-and-clear queue, and the model raises `BX_FE_IRQ`
on the `0xa1` doorbell, so whenever the interrupt wins the race it drains both
messages and `chk_int_ldr` can only time out. The fix in §5.2 makes the
*in-order* case work; a model that also wants the interrupt path to be
harmless should keep the IRQ raise but leave both messages for whichever
consumer reads first (which the read-and-clear semantics already do).

---

## 6. UART ↔ trace correlation

Every line below is matched to a trace line range and, where the driver prints
enough, to the function that printed it.

| UART | text | trace | mechanism |
|---|---|---|---|
| 244 | `[IDE]download boot code to SRAM (0x0, 0x4000)` | 1744-34512 (`FE-SRAM FIFO wptr` ×16,385) | 16 KiB boot code through `0xfd324180/184` |
| 245 | `[IDE]verify boot code -- OK` | 34515-50899 (`read idx` ×16,384) | the read-back verify; the C81 FIFO fix holds |
| 258-262 | MTD tag-mismatch / `Read parameter failed` | — | the `fe_parameters` partition is blank in our image (sata-fw-load.md §6) |
| 272 | `[IDE]release frontend reset done !!` | 50905-50918 (`0x5c708/0x5c704/0x5c600/0x5c604/0x5c780` reads) | `xfer_int_ldr_fw` §5(b). **The writes are model-implemented, so only the reads appear.** |
| 274 | `[IDE]<init_int_ldr>init end` | 50901 (`0x70324b00 = 1`) | loader-done flag |
| 277-278 | `[IDE]int_val = 0x10000` / `Receive frontend boot up status:0x0` | 50922 | `port_start` state-1 poll, bit 16 set |
| 279-280 | `download AACS code (0x0, 0x4000) …start/…end` | 50924-83692 (16,384 × wptr+read) | `xfer_int_ldr_aacs_data` through the same FIFO |
| **281** | `copy from (0xdfc01000, 0x200)` | 83694 | message A accepted: DRAM `0xdfc00000` + `w1 0x1000`, `w2 0x200` |
| **282** | `wait status interrupt timeout !` | 83695-83897 (200 × `0x5c804 = 0x0`) | **message B never pending — §5.2** |
| 283-284 | `scsi0 : sata_mt85xx` / `ata1: SATA max UDMA/133 irq 18` | 83916 (`0x5c010 = 'LOGO'`) | port handed to libata; LOGO is the last statement of `sata_mt85xx_init` |
| 285-326 | `prereset`/`softreset`, `qc timeout (cmd 0xa1)`, `reset failed, giving up` | (ATA window is model-implemented → invisible) | `ata-probe-path.md` |
| 420-434 | `[i4IdeDrvBootup]Start..` … `FE boot up OK !!` … `End..` | 83930+ | bdpdrv init begins; the first post-LOGO quantum is BIM/efuse + audio clock |
| 676 / 719 | `Audio Init Thread is created` / `destroyed automatically` | — (`0x8118` is model-implemented) | `vAudInitThread`'s FastLogo poll passed on the first read |
| 1105 | `[OSD][osd_scaler_if]fastlogo didn't run first.` | ~89960-90051 (OSD phase) | `OSD_SC_Scale` ordering note |
| **1532** | `BDPDRV_INSMOD=0` | — | **module init returned; nothing is parked in the driver** |
| **1868** | `/ # echo STUB_DONE` (echo only) | 119045 (last event: `0x2420c` read) | harness marker matched the echo — §5.1 |

So the last *driver* print (line 1105) is followed by ~26,000 more trace events
of normal steady-state polling, and the last *module* milestone
(`BDPDRV_INSMOD=0`) precedes the run's end by the whole harness command list.
Neither marks a stall location.

---

## 7. What did not resolve

1. **What the FE does with `'LOGO'`.** The write has no reader in either module
   and the FE firmware is factory-programmed, absent from the Sony update and not
   in our holdings. The "show the boot logo" reading is **INFERRED** from the
   constant. Settling it needs either a FE firmware dump or a video-side
   observation on real hardware.
2. **Why the top half won the race at 83921.** The model raises `BX_FE_IRQ` on
   the `0xa1` doorbell, so message A can be consumed by either consumer. The
   trace shows one top-half entry draining two messages but cannot show which
   `0xa1` posted them (the `0x5c020` writes are model-implemented and therefore
   invisible). Reproduce with a model-side `-d` print on `0x5c020`.
3. **Whether `0x24188` read-back ever matters.** Every current reader uses it
   as a one-shot guard; no reader checks another subsystem's bit. A model that
   stores the written value is strictly more faithful, but no failure is
   attributable to returning 0 today.
4. **The wall-clock length of the run.** The guest has no timestamped source in
   these artifacts (the stub counts delays, not seconds), so "the harness cut it
   ~0.5 s after the echo" is derived from `observe()`'s loop shape
   (`select(.5)` + immediate break), not measured.
5. **`0x70024030`** (the FE reset command the sata module writes at 50902) is
   new to the trace family; its read semantics are unexercised here
   (sata-fw-load.md §5(b) documents the write only).

---

## 8. Reproduction

```bash
cd evidence/bx510-guest/bdpdrv/decode

# trace side: 14 assertions (LOGO census, 0x24188 rounds + owners, 201-write
# poll, steady-state address set)
python3 post_aacs_trace.py --checks

# the tables the document quotes
python3 post_aacs_trace.py --subsystems --lo 83930 --hi 119045 --min-events 8
python3 post_aacs_trace.py --regions     --lo 90100 --hi 119045
python3 post_aacs_trace.py --thread-map  --lo 117000 --hi 119045
python3 post_aacs_trace.py --new            # vs Run C50
python3 post_aacs_trace.py --rmw            # read-modify-write rounds on 0x24188
python3 post_aacs_trace.py --phases --lo 83680 --hi 83940

# binary side: 13 assertions (LOGO writer/reader census, the 0x24188 owners and
# their masks, vAudInitThread's FastLogo poll)
python3 post_aacs_static.py --checks
python3 post_aacs_static.py --logo --sram --fastlogo
```

`post_aacs_static.py` runs `resolve_addrs.py --reach 0x70024188` internally
rather than re-deriving constant bases — `0x24188` is reached from a
`0xfd024000` literal, not from the `0xfd05cfff` FE-block base the per-module
scanner in that file models.

Inputs: `bdpdrv.ko` / `sata_mt85xx_mod.ko` under `/tmp/bdpdrv/` (sha-pinned in
the script), `bdpdrv-runC91.{mmio,uart}.log`, `bdpdrv-runC91.meta.json`,
`emulator-kit/sony-bx510.c`, `emulator-kit/smoke.py`,
`tools/bx510_bdpdrv_stub_probe.py`.
