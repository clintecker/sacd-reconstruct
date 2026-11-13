# bdpdrv's `ide` CLI lane — decode + the P5 transport-leg probe

**Scope.** Decode `i4Drv_Cli_Cmd_Tbl_Reg`'s `ide` lane (group 5 = `drv`, getter #47
of the 48) end-to-end: the `ide` table, `ide.pri_ver`'s 33-entry subcommand table,
every handler's argument parse, and the exact execution chain of
**`drv.ide.pri_ver.initial 0 s 0`** — the probe that exercises bdpdrv's own IDE
HAL ATA transport *without* the SACD/ODD layer. Ends with the P5 acceptance block
(exact greps) for the verdict script.

**Inputs (pre-extracted; nothing here came from scanning a binary).**
`/tmp/bdpdrv/bdpdrv.ko` (8,112,032 B, ELF32-ARM relocatable, vermagic-matched),
`nm_all.txt`/`nm_defined.txt`, `/tmp/drvcli` (drvcli.ko, 34,760 B) for the parser
and help formatter, `decode/drvcli-surface.md` §2–§3 (lane/entry layout — extended,
not re-derived), `decode/fe-ata-cmd.md`, `decode/c97-read-path.md`,
`decode/kernel-iomap.md`, `emulator-kit/sony-bx510.c` (the QEMU model — read at
HEAD plus the working-tree diff, which touches only `bx510_sata_build_identify`'s
descriptor *content*; none of the transport rows cited below (`a+00c…a+018`,
`a+220`, `a+600`) are affected by it).

**Method.** Deterministic decoders only: `clitable.py` (24-byte `cli_ent` walk with
`.rel.data` symbol resolution), `moddis.py` (function-scoped llvm-objdump with
literal-pool → section+addend → printable-string resolution), `resolve_addrs.py
--func` (MMIO dataflow, already calibrated for this module), plus a `strb`-scan for
store/read classification. Scripts in §8. Every name and offset below is a decoded
value. **DECODED** = a compare/store/reloc fixes it; **INFERRED** = consistent with
every instruction seen but not closed by one, with the settling experiment named.

---

## 0. TL;DR — what `initial 0 s 0` actually is, and the four things it settles

1. **The lane is reachable with one parser call, dotted form.** `_parse_cmd`
   descends into a sub-table on a `.` inside `argv[0]` (`_search_tbl` matches
   `strlen(entry)==strlen(token-up-to-'.') && strncmp(...)`); whitespace-separated
   arguments after that go to the leaf's `(argc, argv)`. So the single string
   **`drv.ide.pri_ver.initial 0 s 0`** reaches `_IDECLI_Init` with
   `argc=4, argv={"initial","0","s","0"}` — no `cd` sequencing needed (§2.3).
2. **`pri_ver` is a directory, not a leaf.** `ide.pri_ver` alone dumps 33 help
   lines and returns rc=1; that dump *is* the lane's cheapest signature (§3).
3. **`initial 0 s 0` → `i4IdeHalTestInit(0, /*isSata=*/1, /*queMode=*/0)`**
   (`_IDECLI_Init` @ `.text+0xa8e68`, 0x60 B). It programs the **bdpdrv IDE HAL**
   window `0x7000a000` (`VA 0xfd00a000`, kernel-iomap.md item (d)), configures
   PHY/link, reads the 3-byte ATA signature, then issues **IDENTIFY (0xa1)** via
   `i4IdeHalAtaCmd → i4IdeHalSAtaReg` and waits for completion.
4. **It is a different ATA path from C96/C97.** The C9x work proved the **libata /
   sata_mt85xx FE-mailbox** path (`0x7005c000`); this probe drives the **private
   IDE-HAL register file** (`0x7000a000`). A green P5 says "the IDE HAL transport
   leg runs and the a-window register semantics are right"; it says *nothing*
   about the FE mailbox. Do not let the result be read across.
5. **Two model facts make the outcome decidable, not vague** (§4.5):
   the signature trio is read at `+0x0c/+0x10/+0x14` by this HAL (the model serves
   `+0x10/+0x14/+0x18`), and the completion wait polls `0xa220` for **bit 5**
   (the model raises **bit 0**). Predicted today: `Signature:0x140100`, a clean
   `CmdWaitEvtRet` timeout, and no data phase — a *falsifiable* prediction, and
   the two rows to change are named.

---

## 1. The lane's registration (extends drvcli-surface.md §3.3 — not re-derived)

| fact | value | evidence |
|---|---|---|
| getter slot | #47 of 48 in `_paBDPDrvCliGetFuncTbl` (`.data 0x13530`) | drvcli-surface.md §3.3 lane list |
| lane dir table | `_rIdeCmdTbl` `.data 0x41bcc`, 0x18 B, 1 entry | `clitable.py _rIdeCmdTbl` |
| dir entry | `{"ide", alias=NULL, fn=0, sub=_arIdeCmdTbl, help="Ide command", acc=2}` | same |
| action table | `_arIdeCmdTbl` `.data 0x41fc0`, 0x90 B → **6 × 24 B, 5 live** + zero terminator | `clitable.py _arIdeCmdTbl` |
| attach | `i4Drv_Cli_Cmd_Tbl_Reg(...)` → `x_cli_attach_cmd_tbl(block, grp=5, 8, 0)`; group 5 = `drv` | drvcli-surface.md §3.3, §2.4 |
| access | every entry `acc=2` (guest); the shim's `x_cli_set_mode(0)` = supervisor ⇒ passes | drvcli-surface.md §2.2 |

`ide` has **no alias**, so its `drv`-help line is the no-alias form:
`cd ide:` + pad to column 24 + `Ide command` (§2.4 formatter decode).

### 1.1 `_arIdeCmdTbl` (.data 0x41fc0) — the `ide` group, verbatim

| # | name | alias | fn (leaf) | sub (dir) | help | acc |
|---|---|---|---|---|---|---|
| 0 | `SLT` | `slt` | — | `_arIdeSltCmdTbl` (0x41be8, 0x48) | `SLT commands` | 2 |
| 1 | `Pri_Verify` | `pri_ver` | — | `_arIdePriVerifyCmdTbl` (0x41c30, 0x330) | `Private Driver Verify commands` | 2 |
| 2 | `Drv_Verify` | `drv_ver` | — | `_arIdeDrvVerifyCmdTbl` (0x41f60, 0x60) | `Linux Native Driver Verify commands` | 2 |
| 3 | `tray_open_close` | `trayoc` | `_IDECLI_IdeTrayOpenClose` | — | `ide.tray_open_close` | 2 |
| 4 | `save_pwr_cur` | `spc` | `_IDECLI_IdeSavePowerCurve` | — | `ide.save_pwr_cur [power curve string]` | 2 |
| 5 | *zero terminator* | | | | | |

Sub-tables decoded in full:

| table | entries | decoded |
|---|---|---|
| `_arIdeSltCmdTbl` | 2 live | `srvo_test`/`svotst` → `_IDECLI_SltServoTest` (0x4f0 B); `hdd_test`/`hddtst` → `_IDECLI_SltHddTest` (0xe4 B) |
| `_arIdeDrvVerifyCmdTbl` | 3 live | `driver_verify`/`drv_ver` → `_IDECLI_LinuxDrvVerify` (0x484 B); `sc_verify`/`sc_ver` → `_IDECLI_SecureChannelVerify`; `rd_dvd_st` (no alias) → `_IDECLI_ReadDvdStructTest` |

Note `drv_ver` is **doubly aliased** (once on the `Drv_Verify` directory, once on
its first leaf `driver_verify`) — harmless (dir and leaf live in different tables)
but do not grep `drv_ver` and assume depth.

---

## 2. Reaching it: parser semantics that the probe string depends on

### 2.1 tokenizer
`cli_parser` (`drvcli.ko .text 0x2150`) splits the string with `_find_cmd_argv`
(whitespace, 128-B tokens, ≤64), then calls `_parse_cmd(argc, argv, root_tbl)`; on
`-10` it retries against the directory state, else returns `-10`.

### 2.2 dotted descent — DECODED
`_search_tbl` (0x9b0): `r4 = length of argv[0] up to '.' or NUL`, match when
`strlen(entry->name)==r4 && strncmp(entry->name, argv[0], r4)==0` (alias tried
second). `_parse_cmd` (0x1478): after a match with `sub != 0`, if the terminating
byte is `'.'` it does `argv[0]++` past the dot and **recurses with the same
`argc`/`argv`** into the sub-table (0x1614–0x1674); if the token ended and
`argc==1` it dumps help (0x1620–0x1638). It never mutates `pt_cur_cmd_tbl`, so the
dotted form is stateless.

### 2.3 the P5 strings (exact, one call each)
```
P5a  drv                                   -> rc 1 (drv lane help)
P5b  drv.ide                               -> rc 1 (5 ide lines)
P5c  drv.ide.pri_ver                       -> rc 1 (33 lines)
P5d  drv.ide.pri_ver.initial 0 s 0         -> rc 0 (handler ran)
```
rc semantics (drvcli-surface.md §0.2): `0` handler ran · `1` dir help dumped ·
`-10` no match · `-1` drvcli not initialised.

### 2.4 help-line format — DECODED (`drvcli.ko _format_help_str.clone.1` 0x1090)
`name(alias):` (or `name:` when alias is NULL, or `":"`-suffixed variants for
modes 4/5) then **spaces padded while `len <= 23`** (⇒ prefix field = 24 columns),
then `strncpy(help, 104)`. `_show_help` (0x11d4) prefixes `cd ` for directories
(`fn==0`) and `   ` for leaves, prints `[Help]\n\r` first, one `%s\n\r` per entry.
**Greps must anchor on help text, never on the spacing.**

---

## 3. `_arIdePriVerifyCmdTbl` (.data 0x41c30, 0x330 = 33 entries + terminator)

Every handler is a `.text` local (`t`) in bdpdrv. `argc` is the decoded minimum
from the handler's own `cmp r0,#N; bgt` guard; "argv" lists the `StrToInt` /
`StrToHex` reads of `argv[n]`.

| # | name | alias | handler (`.text+`) | argc | args parsed | first downstream call (DECODED) | help |
|---|---|---|---|---|---|---|---|
| 0 | `initial` | `init` | `_IDECLI_Init` 0xa8e68 | >3 | `StrToInt(argv[1])`=ch, `argv[2][0]`=='s'/'S'⇒sata, `StrToInt(argv[3])`=que | `i4IdeHalTestInit(ch, sata, que)` | ide.initial [Channel] [s(sata)/p(pata)] [0-REG/1-QUE] |
| 1 | `setxfer` | `xfer` | 0xa8e20 | >1 | `StrToInt`×2 (ch, mode) | `vIdeHalTestSetXferMode` | ide.setxfer [Channel] [0-REG/1-QUE] |
| 2 | `ata_verify` | `ata_ver` | 0xa8688 | >5 | 5×`StrToInt` | `x_thread_create(_vIdeCliAtaVerify)` | ata_verify [DevId] [LoopCnt] [AccuracyCnt] [UDMA Enable] [TestCnt] |
| 3 | `pkt_verify` | `pkt_ver` | 0xa85bc | >3 | 3×`StrToInt` | `x_thread_create(_vIdeCliPktVerify)` | pkt_verify [DevId] [LoopCnt] [AccuracyCnt] |
| 4 | `partial` | = | 0xa8318 | 0 | — | `i4IdeHalTestSataEnterPartialMode` | partial |
| 5 | `slumber` | = | 0xa8390 | 0 | — | `i4IdeHalTestSataEnterSlumberMode` | slumber |
| 6 | `wakeup` | = | 0xa8354 | 0 | — | `i4IdeHalTestSataWakeup` | wakeup |
| 7 | `standby` | = | 0xa8580 | 0 | — | `i4IdeHalTestStandbyImmed` | standby |
| 8 | `active` | = | 0xa84ec | 0 | — | `x_mem_aligned_alloc` + `i4IdeHalTestAtaRead` | active |
| 9 | `power_save` | `pwr_sv` | 0xa83cc | >4 | 3×`StrToInt` | Partial/Slumber/Wakeup loop | power_save [0-Packet/1-ATA Device] [0-Partial/1-Slumber] [LoopCnt] |
| 10 | `regtest` | `reg` | 0xa82c0 | >3 | 3×`StrToInt` | `vIdeHalTestPhyCtrlRegWr` | regtest [Channel] [WaitTime] [IntervalTime] |
| 11 | `bisttest` | = | 0xa8198 | >3 | 3×`StrToInt` | `vIdeHalTestSscEnable`, `vIdeHalTestOutputSignal` | bisttest [Channel] [BistMode] [0-SSC OFF/1-SSC ON] |
| 12 | `loopback` | = | 0xa80ec | >3 | 2×`StrToInt` | `vIdeHalTestLoopbackEnable` | loopback [Channel 0~1] [0-OFF/1-ON] |
| 13 | `comwake` | = | 0xa8138 | >3 | 2×`StrToInt` | `vIdeHalTestLoopbackEnable`, `vIdeHalTestComWakeIntEnable` | comwake [Channel 0~1] [0-Disable/1-Enable] |
| 14 | `rsg01` | = | 0xa80a8 | >1 | `StrToInt` | `vIdeHalTestJitterTolerance` | rsg01 [Channel 0~1] |
| 15 | `bistact` | = | 0xa8054 | >2 | 2×`StrToInt` | `vIdeHalTestSscEnable`, `vIdeHalTestBistAct` | bistact [Channel 0~1] [0-SSC OFF/1-SSC ON] |
| 16 | `ssc` | = | 0xa7fdc | >1 | 3×`StrToInt` | `vIdeHalTestSscEnable` | ssc [0-SSC OFF/1-SSC ON] [Delta(opt)] [Delta1(opt)] |
| 17 | `tximp` | = | 0xa7f5c | >2 | 2×`StrToInt` | `u4IdeHalTestTxImp` | tximp [Channel 0~1] [TXIMP 0x0 ~ 0xF] |
| 18 | `rximp` | = | 0xa7edc | >2 | 2×`StrToInt` | `u4IdeHalTestRxImp` | rximp [Channel 0~1] [RXIMP 0x0 ~ 0xF] |
| 19 | `power` | = | 0xa7e64* | >3 | 2×`StrToInt` | `vIdeHalTestSataPower` | power [Channel 0~1] [0 - OFF, 1 - ON] |
| 20 | `abist` | = | 0xa7df8 | >2 | 2×`StrToInt` | `fgIdeHalTestABIST` | abist [Channel 0~1] |
| 21 | `rx_dco_test` | `rx_dco` | 0xa7db0 | >2 | 2×`StrToInt` | `i4IdeHalTestRxDco` | rx_dco_test [Channel] [TestCnt] |
| 22 | `sata_speed` | `sspd` | 0xa7d80 | >1 | `StrToInt` | `i4IdeHalTestSataSpeed` | sata_speed [0-Auto/1-Gen1/2-Gen2] |
| 23 | `hftp` | = | 0xa7d54 | 0 | — | `vIdeHalTestBistPattern` | hftp |
| 24 | `mftp` | = | 0xa7d28 | 0 | — | `vIdeHalTestBistPattern` | mftp |
| 25 | `lftp` | = | 0xa7cfc | 0 | — | `vIdeHalTestBistPattern` | lftp |
| 26 | `lbp` | = | 0xa7cd0 | 0 | — | `vIdeHalTestBistPattern` | lbp |
| 27 | `ssop` | = | 0xa7ca4 | 0 | — | `vIdeHalTestBistPattern` | ssop |
| 28 | `bist` | = | 0xa7c24 | >2 | 2×`StrToHex` (`argv+2` skip) | `vIdeHalTestBistPattern` | bist [0xXXXXXXXX] [0xXXXXXXXX] |
| 29 | `r` | = | `_IDECLI_RegRead` 0xa7b40 | >1 | `StrToHex(argv[1]+2)`=ofs, `StrToInt(argv[2])`=len (only when argc==3) | `u4IdeHalTestReadReg(ofs)` | r [Addr] [Length in Byte (Optional)] |
| 30 | `w` | = | `_IDECLI_RegWrite` 0xa7ab4 | >2 | `StrToHex(argv[1]+2)`=ofs, `StrToHex(argv[2]+2)`=data | `vIdeHalTestWriteReg(ofs,data)` then readback print | w [Addr] [Data] |
| 31 | `impcal` | = | 0xa7a84 | >1 | `StrToInt` | `i4IdeHalTestSataImpCalReFine` | impcal [Channel] |
| 32 | `dump_sram` | `dsram` | 0xa7984 | >2 | 2×`StrToInt` | `x_mem_alloc` + `VSF_SramRead` | dump_sram [Addr] [Length] |

Every handler symbol above is both the table's decoded `fn` word *and* a real
`.symtab` `STT_FUNC`; addresses/sizes cross-checked against `nm_defined.txt`.

**`trayoc` is a stub — DECODED, size 4 B (`mov r0,#0; bx lr`).** The `ide` tray
command does nothing; real tray control is `sacd.trayctrl` → `_IDECLI_OddTrayCtrl`
(→ FE mailbox). Do not use `trayoc` as a tray probe.

---

## 4. `drv.ide.pri_ver.initial 0 s 0` — the full chain

### 4.1 argument parse (`_IDECLI_Init` @ 0xa8e68, 0x60 B, DECODED verbatim)

```
cmp   r0,#3 ; bgt ok                  ; else print usage and return 0
ok:   r5 = StrToInt(argv[1])          ; channel            0
      r0 = StrToInt(argv[3]) ; r2 = r0 & 0xff   ; queMode   0
      r1 = (argv[2][0]=='s' || argv[2][0]=='S') ? 1 : 0     ; isSata  1
      i4IdeHalTestInit(r5 /*ch*/, r1 /*sata*/, r2 /*que*/)
      return 0
usage: "ide.initial [Channel] [s(sata)/p(pata)] [0-REG/1-QUE]\n"
```
Any first character other than `s`/`S` (e.g. `p`) yields **PATA**. The channel is
passed straight through with no bound check — `initial 5 s 0` writes far outside
the window (§7 risk).

### 4.2 call chain (all DECODED; sizes from `.symtab`)

```
_IDECLI_Init(4, argv)
└─ i4IdeHalTestInit(ch=0, isSata=1, que=0)                       .text 0xa0a28, 0x2a8
   ├─ _fgSataDev = isSata          (.data 0x418b4, 1 B — GLOBAL side effect)
   ├─ vIdeHalSataModeAccessEnable()                                0x99adc
   ├─ if (!_fgSataHwInit)          (.bss 0x16ff8 = _fgUseQueMode+0x30)
   │   ├─ i4IdeHalInit(_fgSataDev, 8)                               0x99c0c
   │   │   ├─ i4IdeOsTmrInit / SemaInit / EventCreate ×2, allocs
   │   │   ├─ vIdeHalHostEnable(0) ; vIdeHalHostEnable(1)           0x99bdc
   │   │   └─ if sata: RMW 0xa200 |= 8 ; RMW 0xa114 (low16 = 0x0808)
   │   ├─ vIdeHalSataDevSetup(ch, 1, 0)                             0x99e78
   │   │   ├─ W 0x801 → 0xa400 + 0x100*ch
   │   │   ├─ RMW 0xa600 + 0x100*ch |= 1
   │   │   └─ poll 10×1 ms: ((rd(0xa600+0x100ch) & 0xA000414D) == 0xA000414D)
   │   │      else Assert("((UINT32)IDE_READ32(RW_SATA_PHY_CTRL00 + u4SataRegOfst) & 0xA000414D) == 0xA000414D")
   │   └─ _fgSataHwInit = 1                     ; second `initial` in a boot SKIPS this
   ├─ if (!_fgSataDev) { …PATA block… }         ; NOT executed for 's'  (see §4.6)
   ├─ vIdeHalBusEnable(ch,0) ; vIdeOsDelay1ms(10) ; vIdeHalBusEnable(ch,1) ; delay(10)
   ├─ _fgUseQueMode[ch] = que                  (.bss 0x16fc8, 2 B array)
   ├─ i4IdeHalGetSignature(ch*2, &sig)                            0x9a384
   │   ├─ i4IdeHalSelDev(ch*2, 1000)                               0x9b31c
   │   │   └─ W dev/head → 0xa018+0x40*dev ; i4IdeHalPollingStReg(ch, /*mask*/0x80, /*timeout*/1000, &st)
   │   └─ sig = ((u8)rd(0xa014+r6)<<16) | ((u8)rd(0xa010+r6)<<8) | (u8)rd(0xa00c+r6)
   ├─ 512-B alloc (+ Assert "pu1IdDevBuf != NULL", idehal_test.c:154)
   ├─ i4IdeHalTestIdDev(ch*2, sig==1, buf, 1)                      0xa07e8
   │   ├─ cmd = (sig==1) ? 0xEC IDENTIFY DEVICE : 0xA1 IDENTIFY PACKET DEVICE
   │   └─ i4IdeHalAtaCmd(ch*2, cmd, buf, atapi, 1000, 0x31, que, sata)   0x9a470
   │       └─ i4IdeHalSAtaReg(...)                                 0x9ca10
   │           ├─ flush evt ; vIdeHalRegDmaEnable ; vIdeHalSetXferReg(512 B)
   │           ├─ vIdeHalSendCmd(...)  → W 0xa018,0xa004,0xa008,0xa00c,0xa010,0xa014, then 0xa01c = cmd   0x9b4d4
   │           ├─ flags 0x31 ⇒ fgIdeHalNeedIntrq(0x31)=1  (IRQ required)
   │           ├─ i4IdeHalWaitEvt(ch, flags&3=1, needIrq=1, 1000)  0x9e188
   │           │   └─ (ISR-registered flag clear ⇒ POLLING branch, see 4.4)
   │           ├─ i4IdeHalPollingStReg(ch, /*mask*/0x88, /*timeout*/1000, &out)
   │           ├─ vIdeHalChkSataError ; vIdeHalErrorRecovery on error
   │           └─ vIdeHalRegDmaEnable(0)
   ├─ vIdeOsMemFree(buf)
   └─ if (_fgIDELog) printf "[i4IdeHalTestInit]CH:%d, SataDev:%d, UseQueue:%d Done!\n"
```

`_fgIDELog` (`.data 0x41820`) is **initialised to 1 in the image and has no
writer**: 54 `.text` pool references, all `ldrb` gates; a full-`.text` scan for a
store to any `_fgIDELog` pool slot returns 0, and no setter symbol exists. ⇒ **the
IDE-HAL UART logging is ON unless the image is patched.** (DECODED)

### 4.3 MMIO touched by the SATA path — with the committed model's status

Offsets are inside the IDE window (`0x7000a000`); `+0x100*ch`, `+0x40*dev` as
decoded per instruction. For ch=0 the multipliers vanish.

| step | offset | access | model (`sony-bx510.c`) | P5 impact |
|---|---|---|---|---|
| SataModeAccessEnable | `a+400` | RMW `\|= 0x800` | **absent** → read 0, write dropped | benign (RMW sees 0) |
| SataModeAccessEnable | `a+500` | RMW `\|= 0x800` | **absent** | benign |
| i4IdeHalInit | `a+100` | W 42 then 6 | **absent** | benign |
| i4IdeHalInit | `a+200` | RMW `\|= 8` | **absent** | benign |
| i4IdeHalInit | `a+114` | RMW low16=0x0808 | present (`sata_a114`) | echo, harmless |
| SataDevSetup | `a+400+0x100ch` | W 0x801 | read-only case `0xa400` | write dropped |
| SataDevSetup | `a+600+0x100ch` | RMW `\|=1` + PHY poll | **present**, returns `0xa000414d\|0x370000` ⇒ mask match passes for ch0 | ✔ (ch1 → `a+700`, **absent** ⇒ 10 ms then **Assert**) |
| BusEnable | `a+080+0x20ch` | RMW bit2 clear/set | present (`sata_a080`) | φ |
| SelDev | `a+018+0x40dev` | W dev/head, readback | present as `tf[5]` + sig default `0xeb` | φ |
| PollingStReg | `a+038` | poll `&0x80`, `&0x7f != 0x7f` | **absent** → 0 ⇒ poll *passes* instantly | benign, but note it is a *silent* pass |
| SendCmd | `a+004,008,00c,010,014,018,01c` | taskfile + command W | present (`tf[]`, cmd case) | ✔ model sets `sata_st=0x58`, `sata_ist\|=1`, raises virq 53 |
| **signature read** | **`a+00c`, `a+010`, `a+014`** | 3 byte reads | model places the ATAPI trio at `+0x10/+0x14/+0x18` | **MISMATCH — see 4.5** |
| **WaitEvt completion poll** | **`a+220+0x100ch`** | poll then W1C | present (`sata_ist`), model raises **bit0** | **MISMATCH — see 4.5** |
| WaitEvt error drain | `a+6c8`,`a+6c4` | poll/drain on bit29 | **absent** | only if error |
| data phase (PIO-in) | `a+6b8+0x40dev` waits `==0x200000`, then data at `a+000`/`a+25c` | — | `a+6b8` **absent** | **bare spin, no timeout — §7 wedge** |
| RegRead/RegWrite (`r`, `w`) | `0xfd00a000 + ofs` | 32-bit R/W | whatever offset is asked | direct a-window instrument |

`u4IdeHalTestReadReg(ofs)` is exactly `*(volatile u32*)(0xfd00a000 + ofs)`
(.text 0xa47e4, 4 instructions) and `vIdeHalTestWriteReg(ofs,v)` is
`*(volatile u32*)(0xfd00a000+ofs) = v` + 4 readbacks — DECODED. That makes
`drv.ide.pri_ver.r/w` a **general a-window peek/poke tool** (§5.1).

### 4.4 why the wait degrades to polling — DECODED, and it matters

`i4IdeHalWaitEvt` tests the per-channel **"ISR registered"** byte
(`.bss 0x16e70 + ch + 0x98`). It is set only by `vIdeHalIsrInit(ch)`, and
`vIdeHalIsrInit` (0x9e04c, which does `i4IdeOsIsrEvtInit(ch, irq = ch==0 ? 53 : 0,
_IdeHalIsrRoutine)`) **has zero references anywhere in the module** (no `.text`
and no data reloc; not in `__ksymtab`/`__kstrtab`, so no other module can call it
either). ⇒ in this build the byte stays 0 and every IDE-HAL command wait takes the
**polling** branch: `_u4IdeHalHwIntStatus(ch, mask)` reads `0xa220+0x100ch` (W1C),
accumulates, and loops until `fgIdeOsTmrIsTimeout(timer)`.

Consequence for P5: **no infinite wait** — the wait is bounded by the timeout
argument (1000; the unit is the OSAL timer's — `i4IdeOsTmrAlloc` +
`i4IdeOsTmrGetValue`/`fgIdeOsTmrIsTimeout` against `i4IdeOsGetRiscClock`, INFERRED
milliseconds), then the error path runs. This also explains why the real player
still works without an IDE ISR in this build: the HAL is polling by construction.

### 4.5 expected UART signatures, and the two model rows P5 measures

Success shape (DECODED format strings, `_fgIDELog=1`):
```
[i4IdeHalTestInit]Signature:0x%06x
[i4IdeHalTestIdDev]ModelName:%20s, Size:%dMB
[i4IdeHalTestIdDev]Support UDMA Mode: %d
[i4IdeHalTestInit]CH:%d, SataDev:%d, UseQueue:%d Done!
```
with the payload checks in `i4IdeHalTestIdDev` (LBA48 capacity from identify
words 200..206 / 120..122, UDMA bit from word 176 bit7..0).

Failure / diagnostic shapes that exist on the path (all DECODED):
```
[i4IdeHalSelDev(%d)](ERR)DevId:%d, PollStFailed:%d, ST:0x%x !!
[i4IdeHalGetSignature(%d)]DevId:%d SelDev Failed:%d !!
[i4IdeHalTestInit]Get Signature Failed:%d !!
[i4IdeHalSAtaReg(%d)](ERR)CmdWaitEvtRet:%d
[i4IdeHalSAtaReg(%d)]TIMEOUT !!
[i4IdeHalSAtaReg(%d)](ERR)Ret:%d, ST:0x%x
[i4IdeHalSAtaReg(%d)]ERR:%d
```

**Measured-vs-model, first row — signature placement.** The HAL composes
`sig = (u8@a+014)<<16 | (u8@a+010)<<8 | (u8@a+00c)`. A real ATAPI ODD gives
`0x00EB1401` (LBA low `0x01`, mid `0x14`, high `0xEB`) ⇒ `sig != 1` ⇒ cmd `0xA1`
IDENTIFY PACKET — which is the correct choice for this player. The committed model
serves the trio at `+0x10/+0x14/+0x18` (libata's layout, `ata-probe-path.md` §6
add.10), so the HAL reads `+0x0c = 0`, `+0x10 = 0x01`, `+0x14 = 0x14` ⇒
**`sig = 0x140100`**. The command byte is still `0xA1` (same branch), so nothing
breaks — but the printed value is a **fingerprint of the placement**:
`Signature:0xeb1401` ⇒ HAL placement right (row `+0x0c` must also serve `0x01`);
`Signature:0x140100` ⇒ model's placement served, HAL sees `+0x0c` as zero.
*This one line is the cheapest possible resolution of the libata-vs-IDE-HAL
signature-layout conflict* — measure, don't argue.

**Second row — completion status.** For `flags&3 == 1` the wait loop accepts
completion when `status & 0x7300` is non-zero, else for `flags&3==1` on
`status & 0x20` (bit 5). The model raises `sata_ist |= 0x1` on a command write —
bit 0 — which satisfies neither. ⇒ **predicted today: `CmdWaitEvtRet`/`TIMEOUT`,
no data phase, no `ModelName` line.** The candidate fix (`0x20` for a command
completion) is on a row **shared with the C97 libata path** — that is a model
decision for the owner, not something this decode should assert.

**Predicted P5 observable (INFERRED, falsifiable):**
```
[i4IdeHalTestInit]Signature:0x140100
[i4IdeHalSAtaReg(0)](ERR)CmdWaitEvtRet:<n>
[i4IdeHalSAtaReg(0)]TIMEOUT !!
[i4IdeHalTestInit]CH:0, SataDev:1, UseQueue:0 Done!
```
guest-side log: `SATA WR a+004…a+018` then `SATA WR a+01c sz4 = 0xa1`, and **no**
`SATA RD a+000`. If instead `ModelName:` appears and `a+000` reads show up, the
wait completed and the payload drained — that would *disprove* the two rows above
and should be reported as such.

### 4.6 the PATA branch is not taken, and should not be — vendor-bug note

With `isSata == 1` the whole `if (!_fgSataDev)` block is skipped: the pad RMW at
**`0x7000d0cc |= 0x10000000`**, `vIdeHalHostSetup`, the two-device bus/dev timing
programming and `vIdeHalSetDriving(ch, 0x04040404)`.
Two decoded anomalies for anyone who runs `initial 0 p 0` instead:
* `0x7000d000` is the **only** direct *physical* address literal in the whole
  `.text` (every other IDE access uses the `0xfd00a000` mapped alias) and it is in
  the **DRAMC** block (`0xfd00d000` is what the `DRAMc*` functions use) — a
  vendor-side VA/phys mix-up; expect a data abort or a silent wrong-register write.
* the PATA PHY read `ldr r1,[r4,r2]` with `r4 = 0xa600+0x100ch` and
  `r2 = 0xfd00a604` forms a wild address (both operands are bases) — INFERRED
  vendor bug, unreachable from the `s` path.
⇒ **P5 uses `s`.** Do not "just try `p`" as a differential; it is a guest-fault
differential, not a transport differential.

---

## 5. Other `ide` subcommands worth running as probes

### 5.1 `r` / `w` — the a-window instrument (cheapest, highest value)
`drv.ide.pri_ver.r 0x<off> [len]`, `drv.ide.pri_ver.w 0x<off> 0x<val>`.
Offset is added to `0xfd00a000`; the parse skips **2 characters** before
`StrToHex`, so the `0x` prefix is mandatory (`r 1c` parses as empty ⇒ 0).
`len == 4` is a special-cased single read (`Read IDE Register [0x%03X] = 0x%08X`);
any other len walks `len/4` words printing ` [0x%03X] : ` + `0x%08X `.

Ready-made, model-relevant reads (ch0 addresses; verdict in §4.3):

| command | proves |
|---|---|
| `r 0x018` / `r 0x01c` | taskfile dev/head + status word are live and echo |
| `r 0x600` | PHY_CTRL00 raw value (`0xa037414d` expected from the model) |
| `r 0x220` | IDE IRQ status `sata_ist`. The model clears it only on a **write** of the read-back value (the HAL's own `_u4IdeHalHwIntStatus` does exactly that), so a bare `r` does **not** consume the pending bit |
| `r 0x008 0x10` | the 4 words covering the signature trio + neighbours: the raw bytes behind `Signature:0x…` |
| `w 0x220 0x20` then `r 0x220` | wpoke/W1C sanity, and a manual way to *satisfy* the §4.5 second row for one round-trip |

`w` is a **real MMIO write into the a-window** — treat it as an attack surface, not
a toy (writing `0x01c` issues an ATA command to the model's command handler).

### 5.2 power/link state (fast, no data phase)
`slumber`, `partial`, `wakeup`, `standby`, `power 0 1|0`, `power_save 0 0 3`.
DECODED registers: `a+610` (LNK_CTRL08, read by partial/slumber/wakeup),
`a+640` (wakeup RMW), `a+200`/`a+604` (ssc). All safe, all model-light.
`active` is the exception — it allocates and calls `i4IdeHalTestAtaRead` (a real
512-byte read ⇒ data phase ⇒ §7 wedge risk).

### 5.3 timing/PHY knobs
`sata_speed 0|1|2` → `i4IdeHalTestSataSpeed`; `setxfer 0 0|1` →
`vIdeHalTestSetXferMode`; `impcal 0`; `tximp 0 0x5` / `rximp 0 0x5`
(both RMW `a+600`); `regtest 0 <wait> <interval>` → `vIdeHalTestPhyCtrlRegWr`;
`ssc 0`, `bistact 0 0`, `abist 0`, `rx_dco_test 0 10`, `rsg01 0`, `loopback 0 1`,
`comwake 0 1`. `hftp/mftp/lftp/lbp/ssop` are zero-arg one-liners into
`vIdeHalTestBistPattern` (BIST pattern injection) — cheap, and the only
zero-arg ones in the table.

### 5.4 the two data-path verifies — DO NOT fire before the wedge row is fixed
`ata_verify 0 1 1 0 1` (`_vIdeCliAtaVerify`) and `pkt_verify 0 1 1`
(`_vIdeCliPktVerify`) spawn kernel threads that issue bulk PIO reads. The PIO-in
wait is a **bare spin on `a+6b8+0x40dev == 0x200000`** with no timeout
(`i4IdeHalSAtaReg` 0xcbe4–0xcbec); that register is not modelled, so the spin never
exits ⇒ hard guest wedge, only recoverable by the outer timeout. They are the right
*next* probes **after** a row for `a+6b8` exists.

### 5.5 the sibling lanes (not the IDE HAL, but wired under the same `ide` dir)
`drv.ide.slt.srvo_test 0 <usbroot>` (`_IDECLI_SltServoTest` → `_IDECLI_OddCheckFaMode`,
`_IDECLI_OddTestUnitReadyLoop`, `_IDECLI_OddGetProfile` — the **ODD/FE path**, i.e.
C96/C97 territory); `drv.ide.drv_ver.driver_verify /dev/sdX 1 <sectors> <blocks>`
(`_IDECLI_LinuxDrvVerify` — goes through the **block layer / libata**, the actual
disc transport); `drv.ide.drv_ver.rd_dvd_st` (`_IDECLI_OddReadDvdStruct`);
`drv.ide.drv_ver.sc_verify <pat>` (`_IDECLI_OddSecureChannelTest`, the AACS path).
These are the probes that *do* touch the proven FE mailbox — keep them distinct
from P5 in the results doc.

---

## 6. P5 acceptance block (exact greps for the verdict script)

Prerequisites (fail fast, all cheap):
```
grep -q ' 244 drvcli'            /res/proc/devices        # drvcli loaded, major 244
grep -q 'i4Drv_Cli_Cmd_Tbl_Reg'  /res/proc/kallsyms        # bdpdrv attached its lanes
```
The shim must set `x_cli_set_mode(0)` (supervisor) or `access=2` entries are refused.

| gate | command (one `x_cli_parser()` call each) | expected rc | exact UART greps (fixed strings) |
|---|---|---|---|
| P5-a | `drv` | 1 | `cd ide:` present **and** `grep -c '^cd '` ≥ 40 (48 getters each return a one-entry directory; the count is a sanity gate, not a spec) |
| P5-b | `drv.ide` | 1 | `cd SLT(slt):` · `cd Pri_Verify(pri_ver):` · `cd Drv_Verify(drv_ver):` · `ide.tray_open_close` · `ide.save_pwr_cur [power curve string]` |
| P5-c | `drv.ide.pri_ver` | 1 | `ide.initial [Channel] [s(sata)/p(pata)] [0-REG/1-QUE]` · `ide.setxfer [Channel] [0-REG/1-QUE]` · `r [Addr] [Length in Byte (Optional)]` · `dump_sram [Addr] [Length]` |
| P5-d | `drv.ide.pri_ver.initial 0 s 0` | 0 | `[i4IdeHalTestInit]Signature:0x` · `[i4IdeHalTestInit]CH:0, SataDev:1, UseQueue:0 Done!` |
| P5-e | guest-side model log, same fire | — | `SATA WR a+01c sz4 = 0xa1` present |

Verdict matrix for P5-d/P5-e (the whole point of the probe):

| observation | conclusion |
|---|---|
| `Signature:0xeb1401` | IDE-HAL signature layout is `+0x0c/+0x10/+0x14` — the model's `+0x10…+0x18` placement is libata-only |
| `Signature:0x140100` | model's placement is what the HAL sees (`+0x0c` returns 0) — the predicted value today |
| `Get Signature Failed:` / `SelDev Failed:` | signature read path itself broken (SelDev/`a+038` poll) — different, earlier failure |
| `ModelName:` + `Support UDMA Mode:` present | wait completed **and** payload drained ⇒ status row already sufficient; report as a disproof of §4.5's second row |
| `CmdWaitEvtRet:` / `TIMEOUT !!` and no `ModelName:` | command posted, completion never latched ⇒ status row (`a+220` bit5) is the gap |
| `a+01c` never written | the command never reached the window ⇒ look at `a+600` assert / `a+6b8`, not at the status row |
| no UART at all from `[i4IdeHalTestInit]` | `_fgIDELog` cleared or drvcli not initialised (`rc=-1`) — check the parser rc line first |

Best-effort negative evidence to keep in the bundle: the full `SATA WR/RD a+…`
trace lines (they are the wire-level record here), the parser rc lines, and the
absence of `a+000` reads.

---

## 7. Risks / open questions (do not settle these by guessing)

1. **Wedge risk is real but confined:** the only unbounded loop is the PIO-in spin
   at `a+6b8` (§5.4), reached by `active`, `ata_verify`, `pkt_verify` and anything
   else with `flags&3 == 2`. `initial 0 s 0` passes `flags=0x31` (`&3 == 1`) and
   therefore takes the **bounded** event/poll wait. Keep the battery's outer timeout
   as-is and do not "just try" the verify pair.
2. **Channel is unbounded.** `_IDECLI_Init` passes `StrToInt(argv[1])` straight to
   `i4IdeHalTestInit` with no `< 2` check (the HAL's own asserts use
   `u4ChId < IDEHAL_MAX_CH_NUM` but only inside `_u4IdeHalHwIntStatus`/`WaitEvt`,
   reached *after* the `a+400+0x100ch` write). `initial 3 s 0` writes ~0xa700-ish
   and then asserts. Do not add such a probe as a "differential".
3. **`_fgSataDev` / `_fgSataHwInit` / `_fgUseQueMode[]` are process-global and
   sticky.** After P5-d the IDE HAL believes it is in SATA/REG mode for the rest of
   the boot; a later SACD/ODD probe in the same boot inherits that. Run P5 as the
   **last** gate of a boot, or reboot between P5-d and any disc-path probe.
4. **Two drivers, one window.** The IDE HAL (`0x7000a000`) and sata_mt85xx's PIO
   path both touch `a+000`/`a+25c`, and the model aliases `0xa25c` as the PIO
   data port while the IDE HAL's `WaitEvt` uses `a+25c` as an IRQ-enable/status
   word. If both paths run in one boot, a `WaitEvt` read can pop IDENTIFY payload
   words. Flagged as a **row-collision** to resolve with the model owner; P5 alone
   (no libata traffic) does not trip it.
5. **`Signature` layout conflict is unresolved by design here.** libata's decode
   says `+0x10/+0x14/+0x18`; the IDE HAL reads `+0x0c/+0x10/+0x14`. Both cannot be
   the ATAPI signature. `Signature:0x%06x` is the decisive measurement; this doc
   deliberately does not pick a winner.
6. **`i4IdeHalAtaCmd`'s 8-argument stack layout** (timeout/flags/que/sata) was
   read from the caller (`i4IdeHalTestIdDev`) and matches the flags value `0x31`
   proven by `fgIdeHalNeedIntrq(0x31)=1`; the *identity* of the 49/0x31 flag bits
   beyond bit0 (transfer type) and bit4 (IRQ required) is **INFERRED**.

---

## 8. Reproducibility

Run from any directory; all three scripts take the module path and print
deterministic output. Sources are short enough to inline (they were run from
`/tmp/ide_cli/` for this decode; nothing was added to the repo tree).

```
clitable.py   walk a cli_ent table (24 B stride) resolving each word through
              .rel.data: name/alias/fn/sub/help/acc, with the printable string at
              the addend. Key primitives:
                sec/data from ELFFile; symtab; relocs[(sh_info, r_offset)] = sym
                resolve_word: reloc -> "<sym>+0x<addend>" + printable-at-addend
                              no reloc -> literal 0x%08x
                dump(name): sec_of(sym) -> (secidx, value, size); for i in size/24:
                  words at +0,+4,+8,+0xc,+0x10,+0x14
moddis.py     function-scoped llvm-objdump -d -r --section=.text, annotating each
              `ldr rN,[pc,#imm]` with POOL -> section+off + the printable string,
              and `mov #imm` with the un-rotated immediate. (Copy of the in-repo
              decode/sata_decode_dis.py with KO re-pointed at bdpdrv.ko — note the
              module must not be named dis.py, it shadows stdlib `dis`.)
resolve_addrs.py --func <name>     (in-repo) forward register-value dataflow for
              MMIO base+immediate; used unchanged.
```

Store/read classification of `_fgIDELog`: decode every `ldr rN,[pc,#imm]` in
`.text`, keep the ones whose target is one of the 54 `.rel.text` slots for
`_fgIDELog`, and look for a following `strb/str` to the same register — result 0
stores (so the flag is read-only).

`trayoc` stub proof: `_IDECLI_IdeTrayOpenClose` has `st_size = 4` and no
relocations (`nm_defined.txt`, `moddis.py`).

---

### One-line summary

`drv.ide.pri_ver.initial 0 s 0` = `i4IdeHalTestInit(0,1,0)` = program the
`0x7000a000` IDE-HAL window, read the ATA signature, POST IDENTIFY `0xA1`, wait for
completion — reachable in one dotted parser call, logging on by default, bounded by
a timeout, and decisive on exactly two model rows (`a+00c` signature placement,
`a+220` completion bit) that today predict `Signature:0x140100` + `TIMEOUT`.
