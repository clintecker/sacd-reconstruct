# drvcli.ko — the CLI surface (decode)

**Scope:** what the REAL `/lib/modules/2.6.35/BDP/drvcli.ko` registers, what its
command tree contains, what bdpdrv contributes to it, what the C9x runs already
verified about it, and the concrete post-C96 acceptance probes.
**Inputs:** `drvcli.ko` pulled from the VM (`make vm-pull-file
FILE=/tmp/rootfs/lib/modules/2.6.35/BDP/drvcli.ko DEST=/tmp/drvcli` → 34,760 B,
ELF32-ARM relocatable, not stripped, vermagic `2.6.35 preempt mod_unload ARMv6`);
`/tmp/bdpdrv/bdpdrv.ko` + `nm_all.txt` / `nm_defined.txt` / `text.dis`;
`evidence/bx510-guest/bdpdrv/bdpdrv-runC9*.uart.log`; `tools/bx510_clidrive.c`.
**Method:** deterministic decoders, not eyeballing — SHT_REL addend-in-place
resolution of `.data`/`.text` literal pools against the symtab (scripts listed in
§7). Every name/offset below is a decoded value, not a guess.

---

## 0. TL;DR — three corrections that change the plan

1. **`root table = 0x0` in the C50/C93/C95 `[CLIDRIVE]` dump is not an error.**
   `x_cli_get_current_root()` returns `pt_cur_cmd_tbl`, whose documented sentinel
   value **0 means "at root"** (`cli_parser` itself loads `pt_cur_cmd_tbl` and, on
   0, parses against the root array `apt_cli_array[0]` — see §2.4). The instrument
   was reading a legitimate 0 and skipping its table walk for nothing.
2. **`parser('driver') = 1` already IS a successful CLI dump — and the C9x logs
   contain one line of it that the earlier read missed.** `_parse_cmd` returns the
   handler's own return value on a match, `-10` (`-EAGAIN`) when nothing matched,
   and **`argc` (=1) when it matched a directory and dumped that directory's help**
   (0x154c path: `_show_help()` then `mov r0, r4`). The C50/C93/C95 UART therefore
   reads:
   ```
   [CLIDRIVE] root table = 0x0
   [Help]

   hdmitx(hdmitx):         Hdmi Tx command

   [CLIDRIVE] parser('driver') = 1
   ```
   — i.e. bdpdrv's custom-driver lane was **live** and its help printed. That lane
   is `CLI_GetCusDrvCmdTbl()` attached to group **12 = `driver`** by `x_cli_start()`
   (§3.3); the *other*, bigger lane (48 module dirs, incl. `sacd` and `ide`) goes to
   group **5 = `drv`** via `i4Drv_Cli_Cmd_Tbl_Reg` — that one has never been asked
   for yet. Return-code table: `0` handler ran · `1` dir help dumped · `-10` no
   match · `-1` drvcli not initialised.
3. **drvcli has no `read`/`write` file ops at all** — only
   `unlocked_ioctl`, `open`, `release`. So the C9x userland probes
   (`echo help > /res/clidev`, `cat /res/clidev`) could never have reached the
   parser: `write()` → `-EINVAL`, `read()` → `-EINVAL`. The observed log
   (`cli driver open success` / `cli module close sucess!` printed, **no** parser
   output from the write, `CLI_HELP_SENT=1`, `cat: read error: Invalid argument`,
   C95:1558-1576) is fully explained and is an **honest negative about the probe
   path, not about drvcli**. The only two live routes into `x_cli_parser()` are
   `ioctl(0x00045102)` (§1) or the kernel-side shim calling the exported
   `x_cli_parser()` directly — the latter is the only route that has ever produced
   output in this rig (item 2).

Net: the CLI is a *usable* verification instrument **today** (it loads, registers
major 244, and bdpdrv attaches to it — C95:335, 1545-1549), and drvcli's own
command set is a factory/debug set (memory peek/poke, log control, framework
`cd`/`ls`) — the SACD/disc commands live in **bdpdrv's** attached lane, not in
drvcli.

---

## 1. What drvcli.ko registers (the interface)

### 1.1 char device

`init_module` (`.init.text`, 0x48 B) is the only registration in the module:

| field | value | evidence |
|---|---|---|
| call | `__register_chrdev(244, 0, 256, "drvcli", &cli_fops)` | `init_module+0x1c` R_ARM_CALL `__register_chrdev`; `mov r0,#244`, `mov r1,#0`, `mov r2,#256`, lit `.data`=`cli_fops`, lit `.rodata.str1.1=0x19e`=`"drvcli"` |
| success print | `<6>cli device init success\n` | str 0x1d1; seen C95:335 |
| failure print | `<3>Unable to register "drvcli" misc device\n` | str 0x1a5 (message is a lie — it is a chardev, not misc) |

* **Major 244 is hard-coded** (not dynamic), 256 minors. Verified live:
  `244 drvcli` in `/res/proc/devices` (C95:1549, repeated C93/C50) and
  `crw-r--r-- 244,0 /res/clidev` after `mknod c 244 0` (C95:1551-1554).
* **No `/proc` entry, no sysfs, no misc_register, no workqueue, no
  request_irq** anywhere in the module: the `.symtab` UND set is exactly
  `UTIL_Printf, __aeabi_unwind_cpp_pr0/1, __copy_from_user, __copy_to_user,
  __memzero, __register_chrdev, __unregister_chrdev, g_u4disable_log,
  g_u4enable_log_droped, snprintf, strcat, strchr, strcmp, strlen, strncat,
  strncmp, strncpy, vsnprintf` (19). No `proc_create`, no
  `__create_workqueue_key`, no `__raw_readl/writel`.

### 1.2 file_operations (`cli_fops`, .data+0x78, 0x70 B = 7 used words)

2.6.35 `struct file_operations` slot arithmetic on the relocations
(`+0x24`, `+0x30`, `+0x38` from the struct base):

| slot | offset | value |
|---|---|---|
| `unlocked_ioctl` | +0x24 | `k_cli_ioctl` |
| `open` | +0x30 | `k_cli_open` |
| `release` | +0x38 | `k_cli_release` |
| `llseek`/`read`/`write`/`aio_*`/`poll`/`mmap` | — | **0 (absent)** |

* `k_cli_open`: `cli_init(0)` → `x_cli_attach_cmd_tbl(arTestCmdTbl, 5, 0, 0)` →
  `UTIL_Printf("<6>cli driver open success\n")`, returns 0.
* `k_cli_release`: `UTIL_Printf("<6>cli module close sucess!\n")` (vendor typo —
  a reliable grep anchor), returns 0.
* Consequence: `read(2)`/`write(2)` on `/dev/drvcli` return `-EINVAL`; there is
  **no character stream**, so shell redirection can never drive the CLI.

### 1.3 ioctl ABI (`k_cli_ioctl`, 0x48..0x250)

Dispatch is `cmd - 0x00045101 ∈ [0,3]` (jump table at 0x94). The four commands are
`_IOC`-encoded with **type 0x51, size 4**:

| cmd | decoded behaviour | returns |
|---|---|---|
| `0x00045101` | `copy_from_user(&b, arg, 1)`; `UTIL_Printf("<6>kernel cli get one byte:0x%x \n", b)` | 0 |
| `0x00045102` | `len = strlen((char*)arg)`; bounds vs `access_ok`; `copy_from_user(s_buf, arg, len)`; **`x_cli_parser(s_buf)`** (s_buf = .bss 0x408, 1028 B) | the parser return code (0/1/-EAGAIN, see §0.2) |
| `0x00045103` | `strlen((char*)arg)`, bounds-check, `copy_to_user(arg, &local, 4)` | 4 |
| `0x00045104` | `copy_from_user(&local, arg, 4)` then `copy_to_user(arg, &local, 4)` (mirror) | 4 |
| anything else | falls through to `mov r0,#0` | 0 |

`0x45101` is the "char injection" channel used by the RS232-transparent mode (the
commands that would consume it are stubs in this build, §2.5). `0x45102` is the
**command-execution channel**: userland → `s_buf` → `x_cli_parser`. The 03/04 pair
is a 4-byte in/out primitive whose *purpose* is unresolved (INFERRED: a
get/set-argument channel around the transparent mode). `0x45103` reads *from* the
user pointer, so it is not a "get current root" call despite the shape.

---

## 2. The command table

### 2.1 entry layout (decoded, NOT assumed)

`cli_ent` is **24 bytes**, NULL-name terminated, in `.data`:

```
+0x00  char *name
+0x04  char *alias
+0x08  void (*fn)(int argc, char **argv)   /* leaf handler */
+0x0c  struct cli_ent *sub                 /* subtable, for a directory */
+0x10  char *help
+0x14  u32   access right index
```

Evidence: `_parse_cmd` reads `[entry+0x08]` (fn) and `[entry+0x0c]` (sub) and
`[entry+0x14]` (access) — 0x15b8/0x15dc/0x153c in the disassembly; every table
below parses cleanly at a 24-byte stride with the last entry all-zero. (The
`root table = 0x0` line in the shim is the *root sentinel*, not a failure — §2.4.)
**Note the trap for `tools/bx510_clidrive.c`:** its `struct cli_ent` puts
`fn_or_sub` at +0x0c, i.e. it reads *only* `sub`. For leaf commands it therefore
always reported `<NULL fn>` — and group entries with `sub==0` printed `<NULL fn>`
even though `fn` at +0x08 may be set. The struct is right about `sub`, wrong about
`fn` (there is no "z" word).

### 2.2 access rights

`ps_access_right` (.rodata, 8 pointers) =
`{supervisor, admin, guest, factory, diag, boot, cec, driver}`.
`_parse_cmd` rejects an entry when `entry->access < e_access_right` (lower index =
higher privilege) and additionally gates modes 4/5 specially
(`access==5||access==8` allowed in boot mode, `<=5` in cec mode, `==4` only in diag).
`access == 8` is an out-of-list sentinel meaning *unrestricted* — used by the
mandatory framework commands. `x_cli_set_mode(mode)` simply writes
`e_access_right` (.bss 0xc30) — the shim's `x_cli_set_mode(0)` = supervisor is
correct.

### 2.3 the framework's own tables (all in drvcli.ko `.data`)

`_arDefaultCmdTbl` (root/default, 8 cmds) — **fn column is the leaf handler**:

| name | alias | fn | sub | help | acc |
|---|---|---|---|---|---|
| `read` | `r` | `_CmdMemRead` | — | Memory read(word) | 2 |
| `read hdmi clock` | `rhc` | `_CmdHdmiClockRead` | — | Memory read hdmi clock | 2 |
| `write` | `w` | `_CmdMemWrite` | — | Memory write(word) | 2 |
| `basic_` | `b` | — | `_arBasicCmdTbl` | basic command | 2 |
| `mtktool` | `0` | `_CmdEnterUart` | `_ar0CmdTbl` | mtktool command | 2 |
| `Uart2Init` | `u2i` | `_RegRs232` | — | register uart2 in Resource manager | 0 |
| `//` | `;` | `_CmdDoNothing` | — | Line comment | 0 |
| `MTKSys` | `sys` | `_CmdOS` | — | MTK Sys Type | 2 |

`at_mandatory_cmd_tbl` (always available, `access=8`): `cd` → `_cli_cmd_change_dir`,
`ls` → `_cli_cmd_list_cmd`, `do` → `_cli_cmd_repeat`, `whoami` →
`_cli_cmd_get_access_right`, `suadmin` → `_cli_cmd_set_admin_access_right`,
`sumtk` → `_cli_cmd_set_supervisor_access_right`.

`_arBasicCmdTbl` (dir `basic_`/`b`): `stop`, `sv`, `version`/`ver`, `reboot`,
`calpll`/`cp`, `getpllclk`/`gpc`, `sleep`/`slp`, `boottime`/`bt`.
`_ar0CmdTbl` (dir `mtktool`/`0`): `et` (enter RS232 transparent), `ft` (factory
mode), `st` (stop transparent).
`arTestCmdTbl` (attached by `k_cli_open`): `test1`/`t1`, `test2`/`t2`,
`enable_log_droped`/`eld`, `enable_log_out`/`el`.

### 2.4 module-group registry (where a *driver's* commands land)

`cli_parser_attach_cmd_tbl(tbl, grp, a, b)` (0x1a00, 0x418 B) is a 13-way switch on
`grp` (0..12, **11 invalid**) that resolves, per group:

| grp | group dir table (a 24 B "directory" entry) | dir name | array slot | count |
|---|---|---|---|---|
| 0 | — (root array, no dir entry) | — | `apt_cli_array+0x0000` | `aui4_cli_tbl_cnt[0]` |
| 1 | `at_basic_cmd_tbl` (0x194) | `basic`/`b` | +0x0200 | [1] |
| 2 | `at_app_cmd_tbl` (0x1c4) | `app` | +0x0400 | [2] |
| 3 | `at_mw_cmd_tbl` (0x1f4) | `mw` | +0x0600 | [3] |
| 4 | `at_mmw_cmd_tbl` (0x224) | `mmw` | +0x0800 | [4] |
| **5** | **`at_drv_cmd_tbl` (0x254)** | **`drv` ("Driver")** | +0x0A00 | [5] |
| 6 | `at_test_cmd_tbl` (0x284) | `test`/`t` | +0x0C00 | [6] |
| 7 | `at_mtk_tool_cmd_tbl` (0x2b4) | `mtktool`/`0` | +0x0E00 | [7] |
| 8 | `at_factory_cmd_tbl` (0x2e4) | `factory` | +0x1000 | [8] |
| 9 | `at_diag_cmd_tbl` (0x344) | `diag` | +0x1200 | [9] |
| 10 | `at_boot_cmd_tbl` (0x374) | `boot` | +0x1400 | [10] |
| 12 | `at_cus_driver_cmd_tbl` (0x314) | **`driver` ("cus driver")** | +0x1800 | [12] |

`apt_cli_array` = .bss 0xc68, 0x1A00 B = 13 groups × **128** pointer slots
(0x200 B each — confirmed by the per-case literals: grp1 → `0xC30+0x238` = 0xC68,
grp5 → 0x1668, grp12 → 0x2468); per-group counters are `aui4_cli_tbl_cnt`
(.bss 0xc34, 13 × u32), per-group info records `at_cli_mod_grp_info`
(.bss 0x698, 0x6800 = 13 × 0x800). Wiring: the group dir entry's `sub` ← the
attached table (`str r7,[r6,#0xc]`), the two extra `a`/`b` args recorded in the
group record. `cli_parser` at root uses `*(u32*)(e_access_right+0x38)` =
`apt_cli_array[0]`, and falls back to `pt_cur_cmd_tbl` when inside a directory;
`_parse_cmd` walks either a single table or a *table array* (`_is_cmd_tbl_array` /
`_get_cmd_tbl_array`), which is how a group accumulates N attached tables.

**Every group dir entry in stock drvcli has `fn==0` and `sub==0`** — they are empty
hooks until a driver attaches. In the C9x guest, group 12 (`driver`) is already
wired (bdpdrv's `hdmitx`, §3.3, visible in the logs) and group 5 (`drv`) should
carry the 48-lane block — that last one is the open question P2 in §5 settles.

### 2.5 what drvcli's own commands actually do (functional vs stub)

Disassembly of every handler (`_Cmd*`, `_CLI_*`, `_RegRs232`, `_cli_cmd_*`):

**Functional:**

* `read <addr> <len>` (`_CmdMemRead`) — usage `"read <addr> <length>\n"`, prints
  `"Read addr = 0x%08x, length = %d\n"`, then reads **`(addr & ~3) | 0xF0000000`**
  directly (`orr r4, r6, #-268435456`) 4 words per line via
  `"0x%08X | %08X %08X %08X %08X\n"`, capped at 4096 B. Argument order is
  `(argc, argv)` with `argc>2` required (`argv[1]`=addr, `argv[2]`=len).
* `write <addr> <val>` (`_CmdMemWrite`) — `*(u32*)((addr & ~3) | 0xF0000000) = val`,
  prints `"write addr: 0x%08X  =  0x%08X\n"`.
  → the `0xF0000000` OR is the kernel direct-map base **inferred** to be
  0xF0000000 for this build (the constant is measured; the base is inferred). These
  two commands are a physical-memory peek/poke instrument *if* that holds — verify
  with `read 0x0 16` before relying on it, and expect a data abort otherwise.
* `read hdmi clock` (`_CmdHdmiClockRead`) — fixed unconditional derefs of
  `0xfd0050c0/c4/c8/cc`, `0xfd005200/04/08/0c`, `0xfd005210`, `0xfd005224`,
  `0xfd005284`, `0xfd0000cc`, `0xfd0000d4`, printed with the `0x%08X | …` format.
  **Hazard:** an unmodeled page here is a guest data abort, not a print. (0xfd005000
  is the AUDIO block per the FE-ATA architecture notes.)
* `MTKSys` (`_CmdOS`) — prints a fixed string (`0x4ed`).
* `test1`/`test2`/`enable_log_droped`/`enable_log_out` — `_CLI_Basictest1/2`,
  `_CLI_Ctrl_log`, `_CLI_Ctrl_log_onoff`; the log pair toggles the OSAL globals
  `g_u4enable_log_droped` / `g_u4disable_log` that drvcli imports.
* framework: `cd` (sets `pt_cur_cmd_tbl`), `ls` (`_show_help` of the current dir),
  `do`, `whoami`, `suadmin`, `sumtk` (access-right changes).

**Compiled-out stubs — `mov r0,#0; bx lr` (8 bytes each):** `_CmdEnterUart`,
`_CmdFactoryUart`, `_CmdStopUart`, `_CmdSvDetect`, `_CmdVersion`, `_CmdReboot`,
`_CmdCalibratePLL` (`calpll`/`cp`), `_CmdKBandPLL` (`getpllclk`/`gpc`),
`_CmdSleep` (`sleep`/`slp`), `_CmdGetBootTime` (`boottime`/`bt`), `_RegRs232`
(`Uart2Init`).
Consequence: **`version`, `reboot`, `sv`, `sleep`, `boottime`, `et`/`ft`/`st`,
`calpll`, `getpllclk`, all silent.** The `_aszPointString` 23-entry boot-timeline
string array exists but its only consumer is the stubbed `_CmdGetBootTime`.

Also `SerPollPutChar(c)` (exported, .text 0x378) = `while(!(*(u8*)0xfd00c004 & 2));`
`*(u8*)0xfd00c000 = c;` — a **polled UART2 TX with a hard spin on a status bit**.
Nothing in bdpdrv imports it, but any module that does will hang the guest if
0xfd00c004/bit1 is unmodeled.

---

## 3. Cross-reference: bdpdrv ↔ drvcli

### 3.1 drvcli calls NOTHING in bdpdrv

drvcli's 19 UND symbols (§1.1) contain **no bdpdrv symbol**. The dependency arrow
is one-way: **bdpdrv calls into drvcli**. So "bdpdrv's exported API that drvcli
calls" = ∅; what matters is the reverse set.

### 3.2 drvcli's exports (19, `__ksymtab`) and what bdpdrv imports of them

`x_cli_show_tms_level, x_cli_parse_tms_level, x_cli_show_dbg_level,
x_cli_parse_dbg_level, x_cli_get_char_timeout, x_cli_passwd, x_cli_parser_arg,
x_cli_get_current_root, x_cli_parser, x_cli_attach_alias, x_cli_set_diag_mode,
x_cli_detach_cmd_tbl, x_cli_attach_cmd_tbl, cli_init, SerPollPutChar,
x_cli_set_mode, StrToInt, StrToDec, StrToHex`

`bdpdrv.undef.syms` ∩ above (6) + 3 neighbours:

| symbol | drvcli addr / size | prologue → arg count |
|---|---|---|
| `x_cli_parser` | 0x77c / 0x58 | `push {r4,lr}`, reads `b_cli_init`, tail-calls `cli_parser(r0)` → **1 arg** `const char *cmd`; returns 0 matched / 1 unresolved-at-root / `-EAGAIN` in-dir |
| `x_cli_parser_arg` | 0x6ec / 0x90 | `push {r0,r1,r2,r3}` + `ldr r5,[sp,#0x18]` → **variadic**, `(char *fmt, ...)`; formats with `vsnprintf` into `s_buf` then calls the parser (bdpdrv uses it to *synthesise* CLI commands) |
| `x_cli_attach_cmd_tbl` | 0x840 / 0x38 | r0..r3 forwarded to `cli_parser_attach_cmd_tbl`; gates on `b_cli_init` (−1) and NULL tbl (−3) → **4 args** `(tbl, grp, a, b)` |
| `x_cli_detach_cmd_tbl` | 0x808 / 0x38 | same shape → **4 args** |
| `cli_init` | 0x878 / 0x70 | `cli_parser_clear_cmd_tbl()`; `cli_alias_init()`; `x_cli_attach_cmd_tbl(CLI_GetDefaultCmdTbl(), 5, 0, 0)`; idempotent via `b_cli_init` → **0 args** |
| `x_cli_get_current_root` | 0x3a8 / 0x10 | `ldr r0,=pt_cur_cmd_tbl; ldr r0,[r0]` → **0 args**, 0 = root sentinel |
| `StrToInt` / `StrToHex` | 0x2c48 / 0x2b54 | 1 arg (string) — CLI argument parsing |
| (`UTIL_Printf`, `os_cli_show_mem_all_detail` — **not** drvcli; from the BDP/OSAL set) | — | — |

### 3.3 what bdpdrv attaches, and where

`bdpdrv:init_module` (0x8adf8) — decoded call/literal sequence:

1. `send_notification(0xf)`; `i4Drv_RM_Comp_Reg(_paBDPDrvGetCompInfoFuncTbl, 37)` —
   37 `MW_*_GetCompInfo` components (incl. `MW_Sacd_GetCompInfo` @ index 25).
2. `i4Drv_Cli_Cmd_Tbl_Reg(_paBDPDrvCliGetFuncTbl, 48)` → this is bdpdrv's CLI
   registration wrapper (0x5deb4): it `kmalloc`s `(n+1)*24`, captures each getter's
   `cli_ent*`, keeps entries with a name and (`fn` or `sub`) set, records the block
   in a 10-slot registry (.data 0x116c0, records `{tbl, getters, n}`), then
   **`x_cli_attach_cmd_tbl(block, grp=5, 8, 0)`** — i.e. bdpdrv's whole CLI
   surface is attached to **group 5 = `drv`**, with extra words `8, 0`.
3. `CLI_GetFactoryCmdTbl()` → `x_cli_attach_cmd_tbl(tbl, grp=8, 0, 0)` — group 8 =
   `factory`.
4. **`x_cli_start()` (0x5e03c):** `cli_init(0)` → `CLI_GetCusDrvCmdTbl()` →
   **`x_cli_attach_cmd_tbl(tbl, grp=12, 0, 0)`** → `x_memset(0x116c0, 0, 0x78)`
   (clears the 10-slot registry). Group 12 = `driver` ("cus driver").
   `x_cli_stop()` (0x5e020) detaches the same table from grp 12;
   `cleanup_module` (0x8ae98) detaches grp 8 and the registry blocks.

   **This is the lane the C9x runs already exercised.** `bdp_exports.syms` shows
   `CLI_GetCusDrvCmdTbl` is a bdpdrv symbol, and the decoded table it returns is
   `at_mtk_cus_drv_cmd_tbl` (.data 0xa7a0, 48 B, 1 entry) =
   `{'hdmitx', alias 'hdmitx', sub=_arHdmiTxCustCmdTbl (15 entries: hdmilog,
   infofm, phtvhd, getedid, chksrm, …), help "Hdmi Tx command", acc=6}` —
   byte-for-byte the `hdmitx(hdmitx):         Hdmi Tx command` line in the C50/C93/C95
   logs. So group 12 is wired, the framework prints, and `x_cli_start()` ran.
   (A sibling lane, `x_hdmi_cust_cli_init` @ 0x2e8ef0, attaches
   `_rCustHdmiCmdTbl`={hdmi} to grp 1 = `basic` — a separate customisation.)

`_paBDPDrvCliGetFuncTbl` = 48 getters (.data 0x13530, `.rel.data` verified). Each
returns a single-entry `_r*CmdTbl` directory whose `sub` is the real `_ar*CmdTbl`.
The 48 lanes, in registration order (`<...>` = getter whose literal is not a plain
`.data` reloc — its table is produced through the OS layer):

```
 1 km          2 aud         3 multiline   4 audin       5 pwmdac      6 <GetCbkCmdTbl>
 7 connect     8 dmx         9 esm        10 esn        11 fbm       12 gcpu
13 cpsa       14 gfx        15 gpio       16 hdmi       17 net       18 ir
19 mpv        20 <GetOsCmdTbl> 21 osd     22 pbbuf      23 ipod      24 pmx
25 <GetRmkCmdTbl> 26 sif    27 syncctrl   28 tve        29 uart      30 uart2
31 vdp        32 vpq        33 vfd        34 jdec       35 imgresz   36 png
37 gif        38 dramc      39 system     40 post       41 ccir      42 rai
43 framebuffer 44 auto_test 45 musb       46 sacd       47 ide       48 bonding
```

`sacd` and `ide` are the two disc lanes. Decoded in full (§2.1 layout):

**`sacd` → `_arSacdCmdTbl`** (`_rSacdCmdTbl` @ .data 0x4a5f4, sub @ 0x4a60c):

| name | alias | handler | help |
|---|---|---|---|
| `trayctrl` | `tray` | `_SACDCLI_TrayCtrl` | sacd.trayctrl [0-Tray Close/1-Tray Open] |
| `testphy` | `phy` | `_SACDCLI_TestPhy` | sacd.testphy [0-INT CLK/1-EXT CLK] |
| `findtag` | `find` | `_SACDCLI_FindTag` | sacd.findtag |
| `dectrack` | `dec` | `_SACDCLI_DecTrack` | sacd.dectrack [Start PSN] [End PSN] [Start HDD LBA] |
| `outmonitor` | `om` | `_SACDCLI_OutputMonitor` | sacd.outmonitor |
| `inmonitor` | `im` | `_SACDCLI_InputMonitor` | sacd.inmonitor |

Downstream (relocated call lists): `trayctrl → _IDECLI_OddTrayCtrl`;
`testphy → _IDECLI_OddCheckFaMode, _IDECLI_OddTestUnitReadyLoop,
_IDECLI_OddGetProfile, _IDECLI_OddSetSpeedLevel, vSacdDetectPspPdmEnable,
_IDECLI_OddSacdSeek, eSacdWaitPspPdmResult, eSacdGetVersion`;
`findtag → _IDECLI_OddRead, vEkbInit, bEkbParseTagKey, fgSacdSetEkbParam`;
`dectrack → vSacdDecryptEnable, _IDECLI_OddRead, BSP_Clean/InvDCacheRange,
x_thread_delay`; `outmonitor`/`inmonitor` → print only.
→ **the SACD CLI funnels into the `_IDECLI_Odd*` optical-drive layer, which is the
FE-mailbox/ATAPI path already under test.** `dectrack`'s runtime usage text is
`sacd.dectrack [Start LBA] [End LBA]` (2 `StrToInt` args) — the table's help string
(PSN/HDD LBA) is stale relative to the code.

**`ide` → `_arIdeCmdTbl`** (`_rIdeCmdTbl` @ 0x41bcc, sub @ 0x41fc0, 6 entries):
`SLT`/`slt` → `_arIdeSltCmdTbl` (`srvo_test`/`svotst`, `hdd_test`/`hddtst`),
`Pri_Verify`/`pri_ver` → `_arIdePriVerifyCmdTbl` (34 entries: `initial`/`init`,
`setxfer`, `ata_verify`, `pkt_verify`, `partial`, `slumber`, `wakeup`, `standby`,
`active`, `power_save`, `regtest`, `bisttest`, `loopback`, `comwake`, `rsg01`,
`bistact`, `ssc`, `tximp`, `rximp`, `power`, `abist`, `rx_dco_test`, `sata_speed`,
`hftp`, `mftp`, `lftp`, `lbp`, `ssop`, `bist`, `r`/`w` reg read/write, `impcal`,
`dump_sram`, …), `Drv_Verify`/`drv_ver` → `_arIdeDrvVerifyCmdTbl`,
`tray_open_close`/`trayoc` → `_IDECLI_IdeTrayOpenClose` (**stub, 4 bytes**),
`save_pwr_cur`/`spc` → `_IDECLI_IdeSavePowerCurve`.
`ide.pri_ver.initial [Channel] [s/p] [0-REG/1-QUE]` is the IDE bring-up command.

---

## 4. The KEXP/KEXP2/KEXP3 probe catalog (what the C9x runs already verify)

`tools/kcheck.sh` (staged as `/res/shim/kcheck.sh`) emits **67 probes + 3
terminators = 70 `KEXP` lines**. Results are **byte-identical across C50, C51, C52,
C53, C55, C91, C93, C94, C95** (md5 `c5c36854a623313b2e2bb93894b05387` over the
`^KEXP` lines); C54 differs only by one interleaved `[OSAL_STUB] x_thread_delay`
line on line 29. So the probe set is a fixed checklist and the verdict has not
moved since C50. Method: `grep -wq <sym> /res/proc/kallsyms` in the guest.

**KEXP (42): 29 yes / 13 no** — *"can bdpdrv's imports resolve in THIS guest?"*

* **yes (kernel-core / SCSI-BLK / cache / syscall / logging, 29):**
  `__kmalloc __get_free_pages __copy_from_user __copy_to_user
  __create_workqueue_key __aeabi_idiv ___ratelimit __bug blk_execute_rq
  blk_get_request blk_put_request blk_rq_map_user add_disk alloc_disk
  scsi_execute_req scsi_add_device scsi_host_alloc scsi_register
  BSP_CleanDCacheRange BSP_FlushDCacheRange BSP_InvDCacheRange Ethernet_resume
  SR_LOG_Level sys_open sys_ioctl sys_mknod fgFL_ChkSinfo4Reg vFL_SetSinfo4Reg
  print_err_log`
* **no (13) — the sibling-module/SoC internals we cannot resolve:**
  `_fg_fe_bootup sata_int_ldr_fw sata_hw_seg_buf mt85xx_fefwmem_base
  mt85xx_svoif_reserve_base ide_log_en cdrom_log_en sata_mtd_read_buf
  svoif_int_ldr_dram_sz mt85xx_svoif_reserve_base_remap _sata_tray_status
  cpu_cache mem_map`
  Note these are **not** in `bdpdrv.undef.syms` (grep count 0 for each) — they were
  probed to decide *which driver owns the SATA/FE loader*, not to satisfy a link.
  Their absence is what motivated the stub-module approach.

**KEXP2 (7): 1 yes / 6 no** — the same question re-asked for the
`sata_bltin`/kernel-builtin hypothesis (run C52): `mt85xx_ioctl=yes`;
`sata_int_ldr_fw, cpu_cache, mem_map, sata_hw_seg_buf, cdrom_log_en, ide_log_en` = no.

**KEXP3 (18): 18 yes / 0 no** — *"can `sr_mod`/`cdrom` (the SCSI CD-ROM layer the
ODD path needs) load at all?"*: `__aeabi_uidivmod __memzero __scsi_print_command
_clear_bit_le _find_first_zero_bit_le bcd2bin blk_queue_logical_block_size
del_gendisk scsi_execute scsi_ioctl scsi_mode_sense scsi_register_driver
scsi_set_medium_removal sg_next register_blkdev mutex_lock kref_put mt85xx_ioctl`.
This is the load-gate evidence behind "bdpdrv loads Live".

**Gap:** no KEXP probe covers **drvcli's** own imports. drvcli needs
`UTIL_Printf`, `g_u4disable_log`, `g_u4enable_log_droped`, and none of the three
is in the guest kallsyms/BDP export set — the boot therefore depends on
`bx510_osal_stub_a.ko` ("provider for drvcli", C95:332) supplying them. Three added
`KEXP` lines would make that dependency a *checked* gate instead of a comment:

```sh
for s in UTIL_Printf g_u4disable_log g_u4enable_log_droped; do ...
```

---

## 5. Post-C96 acceptance probes

**Route:** the kernel-side shim calling the *exported* `x_cli_parser()` (route 2 in
§0.3) — no ioctl helper needed, no userspace tooling, output lands on the console
UART through `UTIL_Printf`. The return value *is* the assertion:
**`0` = handler ran · `1` = directory matched, help dumped · `-10` = no match ·
`-1` = drvcli not initialised.** Use `ls`/`cd` to read the live tree instead of
walking pointers (module *data* symbols are not in the guest kallsyms — see §6).

Four shim rules that follow from the decode:
* entry struct: `fn` at **+0x08**, `sub` at **+0x0c** (fix `bx510_clidrive.c`);
* `pt_cur_cmd_tbl == 0` is the *root* sentinel, not a failure;
* `1` from the parser is a **help dump, not an error** — assert on `0` for a
  handler and on the help text for a directory;
* prefer `kallsyms_lookup_name` only for **functions** (`cli_parser`,
  `CLI_GetDefaultCmdTbl`, `CLI_GetCusDrvCmdTbl`); `pt_cur_cmd_tbl`,
  `apt_cli_array`, `e_access_right`, `at_cli_mod_grp_info`, `_arDefaultCmdTbl` are
  data and absent from the guest kallsyms capture (CONFIG_KALLSYMS_ALL off — only
  functions appear).

| # | probe (shim → `x_cli_parser(...)`) | expects (exact UART signature) | proves |
|---|---|---|---|
| P0 | `"read 0x1000 16"` | `Read addr = 0x00001000, length = 16` then one `0x00001000 \| XXXXXXXX XXXXXXXX XXXXXXXX XXXXXXXX` line | rig control: parser, memory peek and the `0xF0000000` direct-map assumption all live. **Run first, every session**; a data abort here is a rig bug, not a target bug. |
| P1 | `"driver"` | `[Help]` + `hdmitx(hdmitx):         Hdmi Tx command` | **known-good reference** — this is byte-identical to what C50/C93/C95 already logged, so it calibrates the shim and the UART drain before anything new is asserted. |
| P2 | `"drv"` | if the 48-lane group resolves: `[Help]` + 48 lines `km(…): …` … `sacd(…): SACD command`, `ide(…): Ide command` … `bonding(…)`. If instead `-10`, the lanes are not reachable *by group name* at root — then use `"ls"` (root listing) to read the actual reachable names first, and try the lane names directly (`"sacd"`, `"ide"`). | **INFERRED-but-strongly-supported**: group 5 = `drv` per the decoded switch; nobody has asked for it yet. This is the one probe that needs a one-shot discovery before it can be scripted. |
| P3 | `"sacd"` (or `"cd drv"` then `"cd sacd"`), then `"ls"`, then `"testphy 0"` | `ls` → the 6 SACD names (`trayctrl tray`, `testphy phy`, `findtag find`, `dectrack dec`, `outmonitor om`, `inmonitor im`); `testphy 0` → `[_SACDCLI_TestPhy]Loader is in FA mode !!` / `_IDECLI_OddCheckFaMode`, then `[%s]Get profile error (%d) !!` or `[%s]Disc profile = 0x%x !!`; `_IDECLI_OddTestUnitReadyLoop` before it | **the decisive "disc appeared" probe**: fa-mode check, TEST UNIT READY loop and GET CONFIGURATION profile. Every outcome is a named line, none silent. |
| P4 | `"findtag"` (inside `sacd`) | `[_SACDCLI_FindTag]LBA:0x%x, TAG:%c%c%c%c%c%c%c%c` per LBA, then `[_SACDCLI_FindTag]EKB length:%d, Tag count:%d, dwKAOfset:%d`; failure = `[_SACDCLI_FindTag]LBA:0x%x Read Fail:%d` | the SACD TOC/key-area read: `_IDECLI_OddRead` + `bEkbParseTagKey`. The `TAG:` line is the "sector payload actually arrived" witness — the strongest acceptance signal available without a rip. |
| P5 | `"ide"` → `"pri_ver"` → `"initial 0 s 0"` | usage string `ide.initial [Channel] [s(sata)/p(pata)] [0-REG/1-QUE]` on bad args; on success the IDE init path reaches the FE mailbox (compare the post-handshake MMIO tail in `decode/bdpdrv-runC95.posthandshake.mmio.gz`) | the transport leg, independent of SACD. INFERRED nesting — `"ide"` + `ls` first to confirm before firing. |
| — | `"ide"` → `"tray_open_close"` | **no output** (handler is `mov r0,#0; bx lr`) | **negative control**: silence here confirms the probe reached a *stub* rather than a broken path, so a silent P3/P4 cannot be excused the same way. |

Ordering: **P0 → P1** are disc-free rig calibration; **P2** is the one discovery
step; **P3 → P4 → P5** need the C96 disc. Every expected string was read out of the
handler's own literal pool (§7), so a mismatch is a real behavioural difference,
not a spelling artefact.

---

## 6. Does drvcli depend on anything not yet modeled?

| dependency | status |
|---|---|
| `UTIL_Printf`, `g_u4disable_log`, `g_u4enable_log_droped` | **already modeled** — `bx510_osal_stub_a.ko` ("provider for drvcli", `tools/bx510_osal_stub.c`), refcounted by both drvcli and bdpdrv (C95:1546). Load order enforced: `drvcli.ko` must come *after* part A. |
| `__register_chrdev(244, …, "drvcli")` | kernel-core, works (C95:335, `244 drvcli`). Needs `mknod c 244 0` for userland paths only. |
| direct-map base `0xF0000000` used by `read`/`write` | **not verified** — inferred from the OR immediate. `read 0x0 16` settles it. |
| `0xfd00c000` / `0xfd00c004` (UART2 polled TX in `SerPollPutChar`) | unmodeled; nothing in bdpdrv imports it, but any consumer would spin forever on an unmodeled status bit. |
| `0xfd005000+0xc0..0xcc`, `0xfd005200..0x210`, `0xfd005224`, `0xfd005284`, `0xfd0000cc`, `0xfd0000d4` (`read hdmi clock`) | partially in range of the modeled AUDIO block; **the individual sub-offsets are not modeled** and an unmapped read aborts the guest. Do not use `read hdmi clock` as a probe yet. |
| proc files / workqueues / irqs | **none** — drvcli registers nothing but the chardev. No new proc modeling required. |
| bdpdrv-side (not drvcli's problem, but the probes' target) | the SACD/IDE lanes need `_IDECLI_OddRead`/`_IDECLI_OddGetProfile` → FE-mailbox ATAPI + the loader/`_fg_fe_bootup`/EKB path — i.e. exactly the C96 lane; the KEXP-no symbols (`sata_int_ldr_fw`, `_sata_tray_status`, `svoif_*` bases) are the parts no guest module provides and the model must supply. |

---

## 7. Reproduction (deterministic, no hexdumps by eye)

```sh
# 1. pull the module (VM → Mac)
make vm-pull-file FILE=/tmp/rootfs/lib/modules/2.6.35/BDP/drvcli.ko DEST=/tmp/drvcli
# 2. section/symbol inventory
objdump -h drvcli.ko; objdump -t drvcli.ko | grep -E ' [Oo] \.(data|bss)'
# 3. relocations: the VALUE column names the target SECTION, and the ARM REL
#    addend is stored in place — so (section, in-place word) resolves every
#    pointer without any guesswork
objdump -r drvcli.ko        # .data/.text relocation records
objdump -s -j .rodata.str1.1 drvcli.ko   # the string pool
```
The table decode is a 60-line script: parse the ELF, walk `SHT_REL` records
(`r_info>>8` → symtab index; resolve `STT_SECTION` names from the section header),
and for each 24-byte slot print `(name, alias, fn, sub, help, access)` with the
in-place addend used as the string offset. Two gotchas that cost iterations and
are recorded here so the next session does not repeat them: `SHT_SYMTAB` section
symbols have **empty** names (use `sh[sym.shndx].name`), and an ARM `LDR
rX,[pc,#imm]` literal-pool entry needs `(word>>16)&0xF == 0xF`, not
`(word>>12)&0xF`.

Decoder helpers used this session (Mac-side, `/tmp/drvcli.d/`, regenerate from §7
in <5 min if the /tmp tree is gone): `decode_drvcli.py` (all `.data` cli_ent
tables), `decode_bdp_cli.py` (getter → dir table → sub table for all 48 bdpdrv
lanes), `decode_table_at.py` (one table at an address), `func_strings.py`
(in-program-order string loads = a handler's UART signature),
`find_cli_callsites.py` (relocated call sites of a symbol inside bdpdrv).
