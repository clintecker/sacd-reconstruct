# P0 `read` — why it returns -10, and the correct spelling

*(intended repo home: `evidence/bx510-guest/bdpdrv/decode/p0-scan-decode.md`)*

**Scope:** the C96/C97/C98 `PROBE_SEQ` P0 failure only — `parser('P0 read 0x1000 16') = -10`
while P1 (`driver`) and P2 (`drv`) both return 1. Names the registered command, its
table location, the corrected probe string(s), and whether the shim's call shape can
itself produce `-EAGAIN`. No source file is edited by this doc.

**Inputs:** `/tmp/drvcli.d/drvcli.ko` (34,760 B, ELF32-ARM relocatable, the same
`/lib/modules/2.6.35/BDP/drvcli.ko` `decode/drvcli-surface.md` pulled) + `drvcli.dis`,
`/tmp/bdpdrv/bdpdrv.ko` + `text.dis`; `decode/drvcli-surface.md`, `decode/clidrive-fix.md`,
`decode/kernel-iomap.md`; `evidence/bx510-guest/bdpdrv/bdpdrv-runC9{6,7,8}.uart.log`.

**Method:** deterministic decode — ELF section/reloc/symtab reads and `objdump -d` of the
exact function ranges quoted below (§7 reproduces each command). Nothing here is read
out of a hexdump by eye. Labels: **VERIFIED** = machine-read out of the bytes or the log;
**INFERRED** = reasoned, not machine-checked.

---

## 0. TL;DR — the four answers

1. **`read` is a real, registered, functional command — but it lives in group 5 (`drv`),
   not at the root.** It is `_arDefaultCmdTbl[0]` (name string `.rodata.str1.1 0x957`
   = `"read"`, alias `"r"`, handler `_CmdMemRead`), and `cli_init()` attaches that whole
   table to **group 5** (`mov r1,#5` at `.text 0x8c0`). The C98 P2 dump proves it on the
   wire: `drv`'s help lists `read(r):                Memory read(word)` (C98:1995).
2. **P0 returned `-10` because the ROOT search has no `read` entry** — the root array
   (`apt_cli_array`, `.bss 0xc68`) carries the mandatory commands plus the **group
   directory** tables, and nothing else; `read` is a *leaf* inside group 5's array
   (`.bss 0x1668`). `-10` is `_parse_cmd`'s "no match" return (`.text 0x1678`,
   `mvn r0,#9`) and both of `cli_parser`'s two root-ish attempts miss (§1.3). It was
   never an argv problem, a privilege problem, or a drvcli-load problem.
3. **Corrected P0: `drv.read 0x1000 0`** (dot-joined path, length 0). Expected
   `rc=0` + `Read addr = 0x00001000, length = 0`. **`drv.read 0x1000 16` is NOT a safe
   rig control on this build** — `_CmdMemRead` ORs the address with `0xF0000000` and
   derefs unconditionally, and `0xF0001000` sits in the guest's *vmalloc* window
   (`0xe0800000-0xf8000000`), outside lowmem (`0xc0000000-0xe0000000`) and outside the
   only statically mapped IO section (`0xfd000000-0xfdffffff`). A data abort there is the
   expected outcome (INFERRED, high) — i.e. the upstream P0 was a *bad address*, not just
   a bad spelling. The command is an **IO-VA peek**, not a RAM peek (§3.2).
4. **The shim's call shape is correct** (`x_cli_parser(const char *)`, one call per probe).
   Two genuine shape constraints do exist and one of them also yields `-10`: **a directory
   can only be descended in the same call via `.` inside argv[0]** — `drv read 0x1000 16`
   (space-separated) returns `-10` at `_parse_cmd 0x1614-0x1624` because `drv` matches a
   directory while `argc != 1` and there is no `.` (§4.3).

---

## 1. The exact registered name and its table location

### 1.1 the command entry (VERIFIED)

`_arDefaultCmdTbl` is `.data 0x3a4`, 9 × 24 B (`0xd8`), NULL-name terminated. Entry 0:

| field | value | where it comes from |
|---|---|---|
| `name` | `"read"` @ `.rodata.str1.1 0x957` | `.data 0x3a4` R_ARM_ABS32 → `.rodata.str1.1` |
| `alias` | `"r"` @ `.rodata.str1.1 0x95c` | `.data 0x3a8` |
| `fn` | `_CmdMemRead` (`g F .text 0x2a88`, 0xc0 B) | `.data 0x3ac` **R_ARM_ABS32 `_CmdMemRead`** |
| `sub` | 0 (leaf, not a directory) | `.data 0x3b0` is zero, no reloc |
| `help` | `"Memory read(word)"` @ 0x95e | `.data 0x3b4` |
| `access` | 2 (`guest`) | `.data 0x3b8` |

`_CmdMemRead`'s own literal pool (VERIFIED, relocs at `0x2ac0`/`0x2ae8` = `UTIL_Printf`,
`0x2ac8`/`0x2ad4` = `StrToInt`): usage `"read <addr> <length>\n"` (`.rodata 0x543`), echo
`"Read addr = 0x%08x, length = %d\n"` (`.rodata 0x559`), payload row
`"0x%08X | %08X %08X %08X %08X\n"` (`.rodata 0x4f7`).

### 1.2 where that table is registered — **group 5, not root** (VERIFIED)

`CLI_GetDefaultCmdTbl` (`.text 0x2b48`) is a two-instruction getter: `ldr r0,=0x3a4`
(reloc → `.data`) + `bx lr` → it returns exactly `_arDefaultCmdTbl`.

`cli_init` (`.text 0x878`), the only owner of that call:

```
878  push {r3,r4,r5,lr}
880  ldrb r4,[r5,#1]                 ; b_cli_init — idempotence gate
8a4  bl   cli_parser_clear_cmd_tbl   ; R_ARM_CALL
8a8  bl   cli_alias_init             ; R_ARM_CALL
8bc  bl   CLI_GetDefaultCmdTbl       ; R_ARM_CALL  -> r0 = &_arDefaultCmdTbl
8c0  mov  r1, #5                     ;  <<< GROUP 5
8c4  mov  r2, #0
8c8  mov  r3, #0
8cc  bl   x_cli_attach_cmd_tbl       ; R_ARM_CALL
```

`cli_parser_attach_cmd_tbl` (`.text 0x1a00`) is the 13-way switch on that `r1`
(jump table at `0x1a40`, cases 0..12, 11 = the invalid hole). Case **5** = `0x1aec`:

* attached-table array base = literal `0x1dc4` = **`.bss 0x1668`**
  (i.e. `apt_cli_array` + 5 × 0x200);
* count slot = `*(0xc30 + 0x18)` = `aui4_cli_tbl_cnt[5]` (`.bss 0xc48`);
* group directory entry = literal `0x1dcc` = **`at_drv_cmd_tbl`** (`.data 0x254`,
  `name="drv"`, `help="Driver"`, `access=1`, no alias);
* group info record = literal `0x1dc8` = `.bss 0x4e98` = `at_cli_mod_grp_info + 5*0x800`.

`_get_cmd_tbl_array` (`.text 0xa6c`) resolves the *same* group by name: literal `0x2dc`
= `"drv"` → count `*(0xc30+0x18)`, array literal `0xc54` = `.bss 0x1668`.
`_is_cmd_tbl_array` (`.text 0xc7c`) is the name whitelist that makes `drv` be treated as
an array of attached tables (`"basic","b","app","mw","mmw","drv","test","mtktool","0"`).

**Consequence — the root has no `read`:** `cli_parser_clear_cmd_tbl` (`.text 0x2380`)
populates the root array (`apt_cli_array` base `.bss 0xc68`, count `aui4_cli_tbl_cnt[0]`
@ `.bss 0xc34`) by attaching, **all with `grp = 0`** (nine `bl cli_parser_attach_cmd_tbl`
call sites at `0x2420 0x243c 0x2458 0x2474 0x2490 0x24ac 0x24c8 0x24e4 0x2500`, each
with `r1 = 0`): `at_mandatory_cmd_tbl` (`.data 0xec`), then the group **directory**
tables `at_basic_cmd_tbl` `0x194`, `at_drv_cmd_tbl` `0x254`, `at_app_cmd_tbl` `0x1c4`,
`at_mw_cmd_tbl` `0x1f4`, `at_mmw_cmd_tbl` `0x224`, `at_factory_cmd_tbl` `0x2e4`,
`at_cus_driver_cmd_tbl` `0x314`, `at_mtk_tool_cmd_tbl` `0x2b4` (the routine also zeroes
those entries' `sub` fields first: stores at `.data 0x1a0/0x1d0/0x200/0x230/0x260/0x290/0x2c0`).
`read` is in **none** of them — so a root search can never resolve it.

### 1.3 how a root search actually runs (two attempts) — VERIFIED

`cli_parser` (`.text 0x2150`) calls `_parse_cmd` **twice**:

```
22b0  ldr r2,[r3,#0x38]    ; r3 = 0xc30  -> tbl = *(0xc68) = apt_cli_array[0]
22b4  bl  _parse_cmd       ; attempt 1
22b8  cmn r0,#10 ; bne done
22d4  ldr r2,[r3,#-0x594]  ; r3 = 0x2c28 -> tbl = *(0x2694) = pt_cur_cmd_tbl
22d8  bl  _parse_cmd       ; attempt 2 (only if argc > 0)
```

At the root sentinel `pt_cur_cmd_tbl == 0` this second attempt is *not* a single table:
`_parse_cmd 0x14b8` asks `_is_cmd_tbl_array(tbl)` — which returns **1 for NULL**
(`0xc84 beq 0xd44`, `.text 0xc7c`) — and then `_get_cmd_tbl_array(NULL, idx=0, …)`
(`0xa80-0xaa4`) hands back **array `.bss 0xc68`, count `aui4_cli_tbl_cnt[0]`**. So the
second attempt walks the whole root array. That is *exactly* why `drv` and `driver`
resolve at root (their dir entries are in that array) while `read` does not (it is not),
and it is why the C9x probes never needed a `cd` first. Contrast the append-on-attach
path: `str r7,[r5,r10,lsl #2]` (`0x1d10`) — `r7` is the attached table — is what lands a
pointer in a group slot.

### 1.4 the crossing evidence in the C98 log (VERIFIED)

`grep -a "CLIDRIVE" bdpdrv-runC98.uart.log` gives (C96/C97 identical, one line shifted):

```
[CLIDRIVE] parser('P0 read 0x1000 16') = -10        <- root: no `read`
[CLIDRIVE] parser('P1 driver') = 1                  <- group 12 dir, help dumped
[CLIDRIVE] parser('P2 drv') = 1                     <- group 5 dir, help dumped
```

and inside the P2 help dump (C98:1857-2030, **57 unique entries**):

```
... bonding:                Bonding command
read(r):                Memory read(word)                  <- C98:1995  <<< the command
read hdmi clock(rhc):   Memory read hdmi clock
write(w):               Memory write(word)
basic_(b):              basic command
mtktool(0):             mtktool command
Uart2Init(u2i):         register uart2 in Resource manager
//(;):                  Line comment
MTKSys(sys):            MTK Sys Type
test1(t1) ... enable_log_out(el)                        <- arTestCmdTbl (k_cli_open)
```

57 = **45 bdpdrv lanes** (48 minus the three `<GetCbk/GetOs/GetRmk>CmdTbl` lanes whose
getters do not yield a plain `.data` table) **+ drvcli's 8-command default table + the
4 `arTestCmdTbl` entries** attached by `k_cli_open`. That composition *is* the group-5
array, and `read` is in it — so the deck is confirmed from both directions.

*(Upstream doc label to fix: `drvcli-surface.md` §2.3 calls `_arDefaultCmdTbl`
"root/default". It is neither — `cli_init` puts it in group 5. That mislabel is where
the `-10` came from.)*

---

## 2. Why the return value was `-10` (and not something else)

| rc | producer | meaning |
|---|---|---|
| `0` | handler's own return | a leaf ran |
| `1` | `_parse_cmd 0x154c/0x1638` → `_show_help(sub)` then `mov r0,r4` (argc) | **directory matched, help dumped** |
| `-10` | `_parse_cmd 0x1678` `mvn r0,#9` reached from `0x151c` (no `_search_tbl` hit) or `0x1624` (dir + argc>1, no `.`) | `-EAGAIN`, no match |
| `-1` | `x_cli_*` gates on `b_cli_init` | drvcli not initialised |

P0 hit the first `-10` producer **twice**: attempt 1 searched `apt_cli_array[0]`
(`at_mandatory_cmd_tbl` — `cd/ls/do/whoami/suadmin/sumtk`, no `read`), and attempt 2 —
`pt_cur_cmd_tbl == 0` → the whole root array — searched the mandatory cache plus every
group **dir** table (`basic drv app mw mmw factory driver mtktool` are entries; `read`
is not). Nothing else in the path can produce `-10`: the access gate
(`0x1594-0x15a8`) would return `-10` too, but `e_access_right` is 0 (shim
`x_cli_set_mode(0)`) and `read` is access 2, so it never fires. **The command existed,
was privileged enough, and was simply one level down from where the root search looks.**

---

## 3. The correct P0 probe string(s), ranked

The grammar (from `_parse_cmd`, §4) is: `<group>.<leaf> <arg> <arg>` — one string, dot
inside argv[0], arguments as separate whitespace tokens.

### 3.1 ranked table

| # | probe string | expected rc | expected UART (after the `parser(...)` line) | risk |
|---|---|---|---|---|
| **P0-1 (recommended)** | `drv.read 0x1000 0` | **0** | `Read addr = 0x00001000, length = 0` — header only, no payload row | none: with length 0 the handler returns at `0x2aec` **before** any deref |
| P0-2 (dispatch control, zero-arg) | `drv.MTKSys` | 0 | `[SYS] LX` (literal `.rodata 0x4ed`, `_CmdOS` `.text 0x2938`) | none (no memory access) |
| P0-3 (dispatch control, alternate) | `drv.test1` | 0 | `Welcome to kernel cli module! ` (`_CLI_Basictest1` `.text 0x30`) | none |
| P0-4 (silence control) | `drv.//` | 0 | **nothing** (handler `_CmdDoNothing` = `mov r0,#0; bx lr`) | none — mirrors the `ide.tray_open_close` negative control |
| P0-5 (full payload, IO page) | `drv.read 0xd024000 16` | 0 | `Read addr = 0x0d024000, length = 16` + `0x0D024000 | XXXXXXXX XXXXXXXX XXXXXXXX XXXXXXXX` | low — target VA is `0xfd024000` (FE block, statically mapped `0xfd000000-0xfdffffff`, "log confirms hits" per `kernel-iomap.md` §(c)) |
| **P0-6 (the literal §5 spelling — DO NOT use as a control)** | `drv.read 0x1000 16` | *not observed* | header *may* print, then **guest data abort** at `0xF0001000`; the shim's `parser('P0 …') = ` line never appears (abort ≠ hang: a hang still prints) | high (see 3.3) |
| P0-7 (alias form) | `drv.r 0x1000 0` | 0 | same as P0-1 (alias matched by `_search_tbl`'s second compare) | none |
| P0-8 (stateful alternative) | `cd drv` then `read 0x1000 0` (two parser calls) | 1 then 0 | `cd drv` → `[Help]` + 57 lines, rc=1; then the read runs | none, but needs state handling (§4.5) |

Two facts that make P0-1 the right drop-in: the header print is unconditional once the
args parse (`0x2ae8`), and `StrToInt` understands the `0x` prefix
(`StrToInt` 0x2c48: `strlen>2 && s[0]=='0' && s[1]=='x'` → `StrToHex(s+2,len-2)`,
else `StrToDec`), so `0x1000` → `0x1000` and `0` → `0` (VERIFIED).

### 3.2 why `0x1000` was wrong even in principle

Addresses in this CLI are **not** VAs you type in full. `_CmdMemRead` computes
`va = (addr & ~3) | 0xF0000000` (`0x2af4` `bic r6,r6,#3`, `0x2b00`
`orr r4,r6,#-268435456` = `| 0xF0000000`) and then derefs `[r4]`, `[r4,#4]`, `[r4,#8]`,
`[r4,#0xc]` with **no probe, no fixup** (VERIFIED).

* With a `0xDxxxxxxx` argument the OR is idempotent and the result is the guest's real
  IO VA: `0x0d024000 | 0xF0000000 = 0xfd024000` (the FE block). **That is what the
  operand shape is for** — the command is an IO-VA peek.
* With a RAM address (`0x1000`) the OR throws you out of lowmem entirely. The guest's own
  boot log (C98, `grep -a vmalloc`) has the map:

```
lowmem  : 0xc0000000 - 0xe0000000   ( 512 MB)      <- direct map = RAM
vmalloc : 0xe0800000 - 0xf8000000   ( 376 MB)      <- 0xF0001000 lands HERE
modules : 0xbf000000 - 0xc0000000   (  16 MB)
```

and `decode/kernel-iomap.md` §3 shows the only `iotable_init` entry is one flat
16 MiB section `0xfd000000-0xfdffffff ← 0x70000000-0x70ffffff` (VERIFIED). So
`0xF0001000` is inside the vmalloc window, below the IO section, and — absent an
allocator coincidence — **unmapped**: the first `ldr` is a translation fault.
VERIFIED: the map numbers and the OR constant. INFERRED (high): the fault.
Practical upshot: **no `read` argument can reach RAM** (`addr|0xF0000000` for any RAM
address lands in `0xF0000000-0xFFFFFFFF`); the peek only makes sense against IO pages.

### 3.3 the ordering that keeps the rig honest

`drv.//` (silence, rc 0) → `drv.MTKSys` (fixed string, rc 0) → `drv.read 0x1000 0`
(header, rc 0) → *then* an IO-page payload probe. Each step adds exactly one capability
(path descent / leaf dispatch / argument parsing / memory access), so a failure at step N
names its own cause instead of poisoning the ladder.

---

## 4. Can the shim's `x_cli_parser()` call shape itself produce `-10`?

### 4.1 the export takes one string — the shim is feeding it correctly (VERIFIED)

`x_cli_parser` (`.text 0x77c`, 0x58 B) is `push {r4,lr}; ldrb b_cli_init; return cli_parser(r0)`
— one argument, `const char *cmd`. The shim calls it once per probe with the exact
literal in `cli_probes[]` (`tools/bx510_clidrive.c:68-76`), which the UART echoes back
(`parser('P0 read 0x1000 16')`). P1/P2 matching in the same run proves the seam works.

### 4.2 internal tokenisation (`_find_cmd_argv`, `.text 0xf2c`) — VERIFIED

| rule | decoded behaviour |
|---|---|
| delimiters | control chars `0x01-0x1f` (tab/CR/LF) and space `0x20` when unquoted |
| quoting | `'` (state 1) and `"` (state 2) group a token and are **stripped** |
| comment | `#` terminates the whole line (outer loop `0x1078`) |
| limits | token slot 128 B (`.bss 0x8e98`, 64 slots × 128 = 8192), max 64 argv entries (`cmp r0,#63`) |
| `.` | **not** a delimiter — `drv.read` stays one token |

`argv[0]` **is** the command name and `argv[1..]` are the arguments: `_CmdMemRead` reads
`argv[1]` (addr) and `argv[2]` (len) after rejecting `argc<=1 || argv==0 || argv[2]==0`
(`0x2a88-0x2ab8`). So "the shim forgot to put the command in argv[0]" is ruled out by
construction — the shim never builds an argv at all.

### 4.3 the one real shape-induced `-10`: space-separated descent (VERIFIED decode)

`_parse_cmd` matches **one** entry per call:

* `_search_tbl(str, tbl)` (`.text 0x9b0`) is an **exact-length** compare on the segment of
  `argv[0]` up to the first `.` (`strlen(name)==seg_len && strncmp(name,str,seg_len)==0`,
  then the same for the alias). No prefix matching: `rea`, `reads` → `-10`.
* on a directory match (`fn==0`, `sub/array != 0`) the code at `0x160c-0x1624` is:

```
160c cmp r7,#0          ; sub == 0 ?  (dirs have sub/array)
1614 ldrb r3,[r6]       ; char in argv[0] where the match stopped
1618 cmp  r3,#0
161c bne  0x1644        ; -> '.' present: rewrite argv[0] and RECURSE into the subtable
1620 cmp  r4,#1         ; argc == 1 ?
1624 bne  0x1678        ; -> otherwise -10  (mvn r0,#9)
```

So a *one-shot* path descent requires the `.`; `drv read 0x1000 16` = dir `drv` matched,
`argc==4`, no `.` → **`-10`**, for the same numeric reason P0 failed. `drv` alone
(`argc==1`) is the help-dump path (rc 1) — which is exactly what P2 logged, and it is
strong evidence this decode is right: the only difference between P2 (rc 1) and a
space-separated attempt at `read` (rc −10) is the argument count.

### 4.4 silent mis-parse worth knowing (VERIFIED decode)

Multi-word entry names (`read hdmi clock`, len 15) can only be matched by making
`argv[0]` literally contain the spaces — i.e. quoted:
`drv."read hdmi clock"` (the tokenizer strips the quotes, `_search_tbl` then compares 15
bytes). Unquoted `drv.read hdmi clock` silently matches the 4-byte `read` entry and hands
`_CmdMemRead` `argv[1]="hdmi"`→`StrToDec`→0, `argv[2]="clock"`→0, printing
`Read addr = 0x00000000, length = 0` and returning 0 — a plausible rc with the wrong
handler. (Also a hazard page: `_CmdHdmiClockRead` derefs `0xfd0050xx/0xfd0052xx` — do not
aim at it yet, per `drvcli-surface.md` §6.)

### 4.5 state, not shape

`pt_cur_cmd_tbl` (`.bss 0x2694`) persists across calls: `cli_parser` searches
`apt_cli_array[0]` first, then retries with `pt_cur_cmd_tbl` — which at the root
sentinel 0 *is* the root-array walk of §1.3 (`0x22a0-0x22e0`) — and on a full miss inside
a directory it **dumps that directory's help and returns 1** (`0x2304-0x2318`). So after
any `cd`, rc 1 means "name not found here" rather than "directory matched". The dot-path
probes (P0-1 … P0-7) never move `pt_cur_cmd_tbl`, which is why they are the safer
ladder — the C98 log confirms `cur = 0x0` after every probe.

**Answer to Q3:** the call shape cannot explain this `-10` (it is a genuine "not in the
root table"); but the *path grammar* can, and does, for space-separated descent — so any
future probe must use the dot form, and any rc-1 after a `cd` must be read as a typo.

---

## 5. Corrected `PROBE_SEQ` table

Minimal diff (P0 fixed, P1/P2 kept byte-identical so the C50/C93/C95 reference still
reproduces; only the P0 string and its expectation change):

```c
static const struct cli_probe cli_probes[] = {
  { "P0", "drv.read 0x1000 0",
    "Read addr = 0x00001000, length = 0; rc=0 (length 0 => no deref)" },
  { "P1", "driver",
    "[Help] + hdmitx(hdmitx):         Hdmi Tx command (rc=1)" },
  { "P2", "drv",
    "[Help] + 57 lines: 45 bdpdrv lanes + 8 default (incl. read(r)) + 4 test; rc=1" },
};
```

Optional extension (separate flag/run, because the last two add new failure modes):

```c
  /* control + payload leg — enable with clidrive_args=PROBE_SEQ,P0PLUS */
  { "P3", "drv.//",
    "silence; rc=0 (dispatch reached _CmdDoNothing)" },
  { "P4", "drv.MTKSys",
    "[SYS] LX; rc=0 (leaf ran, no memory access)" },
  { "P5", "drv.read 0xd024000 16",
    "Read addr = 0x0d024000, length = 16 + 0x0D024000 | xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx;"
    " rc=0 (IO-page payload leg)" },
```

Assertions to make in the shim's expectation text (all derived above, not guesses):

* P0 rc **0**, and the presence of exactly one output line (the header) — no payload row.
* P2 rc **1** and the help text **must contain `read(r):`**; that single line is the
  standing proof that the P0 fix targets a live entry.
* A missing `parser('P0 …') = ` line with no later log output = **abort**, not a timeout.

---

## 6. Corrections owed to the upstream decode docs (not edited here)

1. `drvcli-surface.md` §2.3 — `_arDefaultCmdTbl` is labelled "root/default". It is
   **group 5 (`drv`)**; `cli_init` `.text 0x8c0` `mov r1,#5` is the registration. This is
   the root cause of the P0 `-10`.
2. `drvcli-surface.md` §5 P0 and `clidrive-fix.md` §3/§4 — `read 0x1000 16` is presented
   as "the rig control, run first, every session" with `0xF0000000` called an inferred
   direct-map base. The guest's own memory map (`lowmem 0xc0000000-0xe0000000`,
   `vmalloc 0xe0800000-0xf8000000`) says the OR can never produce a lowmem address; the
   operand shape is IO-VA oriented (`0xd024000` → `0xfd024000`). P0 must be re-specified
   as above, and the "a data abort here is a rig bug" line must be retired — a data abort
   is the *expected* result of the §5 spelling.
3. `drvcli-surface.md` §2.4 — the group dir entry's `sub` is set to the **first** attached
   table only (`0x1c2c` `strne r7,[r6,#0xc]`, gated on `cnt==0`); for names on the
   `_is_cmd_tbl_array` whitelist (`drv`, `basic`, `test`, `mtktool`) the parser instead
   uses the whole `.bss`-array via `_get_cmd_tbl_array`. That is why `drv` shows 57 entries
   while `driver` (grp 12, *not* whitelisted) shows only its single attached table.

---

## 7. Reproduction (deterministic)

```sh
# table decode: .data 0x3a4 = _arDefaultCmdTbl, 24-byte stride; name/alias/help are
# R_ARM_ABS32 into .rodata.str1.1 and fn is R_ARM_ABS32 into .text (see .rel.data)
python3 - <<'PY'
import struct
d=open('/tmp/drvcli.d/drvcli.ko','rb').read()
sh_off=struct.unpack_from('<I',d,0x20)[0]; sz,n,si=struct.unpack_from('<HHH',d,0x2e)
shs=[struct.unpack_from('<IIIIIIIIII',d,sh_off+i*sz) for i in range(n)]
st=d[shs[si][4]:shs[si][4]+shs[si][5]]
names={(st[o:st.find(b'\0',o)]).decode():i for i,o in
       ((st[s[0]:st.find(b'\0',s[0])].decode(), s[0]) for s in shs)}
data=shs[names['.data']]; ds=d[data[4]:data[4]+data[5]]
ro=shs[names['.rodata.str1.1']]; rs=d[ro[4]:ro[4]+ro[5]]
s=lambda p: None if p==0 else rs[p:rs.find(b'\0',p)].decode('latin1')
for i in range(9):
    nm,al,fn,sub,hp,acc=struct.unpack_from('<IIIIII',ds,0x3a4+i*24)
    print(f'[{i}] {s(nm)!r} ({s(al)}) fn@0x{fn:x} sub@0x{sub:x} {s(hp)!r} acc={acc}')
# fn/sub print 0 here: they are R_ARM_ABS32 relocations with a zero in-place addend,
# so resolve them from `.rel.data` (`objdump -r`: 0x3ac -> _CmdMemRead, 0x3c4 ->
# _CmdHdmiClockRead, 0x3ec -> _arBasicCmdTbl, 0x404 -> _ar0CmdTbl, 0x41c -> _RegRs232, ...)
PY
```

objdump -d --start-address=0x878 --stop-address=0x8e8 /tmp/drvcli.d/drvcli.ko   # cli_init, mov r1,#5
objdump -r /tmp/drvcli.d/drvcli.ko | grep -E '^000008(bc|cc)'                   # CLI_GetDefaultCmdTbl / x_cli_attach_cmd_tbl
objdump -d --start-address=0x1aec --stop-address=0x1b90 /tmp/drvcli.d/drvcli.ko  # grp5: array 0x1668, dir at_drv_cmd_tbl
objdump -d --start-address=0x1478 --stop-address=0x1688 /tmp/drvcli.d/drvcli.ko  # _parse_cmd: dot-descent, -10
objdump -d --start-address=0xf2c  --stop-address=0x1088 /tmp/drvcli.d/drvcli.ko  # tokeniser
objdump -d --start-address=0x2a88 --stop-address=0x2b48 /tmp/drvcli.d/drvcli.ko  # _CmdMemRead: |0xF0000000, len==0 early-out
objdump -d --start-address=0x2b54 --stop-address=0x2be4 /tmp/drvcli.d/drvcli.ko  # StrToHex (0x-prefix path)

# the wire evidence + the guest memory map
grep -a "CLIDRIVE"  evidence/bx510-guest/bdpdrv/bdpdrv-runC98.uart.log
grep -a "vmalloc :\|lowmem  :" evidence/bx510-guest/bdpdrv/bdpdrv-runC98.uart.log
LC_ALL=C sed -n '1857,2030p' evidence/bx510-guest/bdpdrv/bdpdrv-runC98.uart.log | grep -ac '^[A-Za-z_/0-9]'   # 57
```

---

## 8. Open questions (not needed for the P0 fix)

1. Whether anything ever maps `0xF0000000-0xF0001000` at runtime (a vmalloc/ioremap
   coincidence). A cheap answer: fire P0-6 in a throwaway run and look for the KB
   "Unable to handle kernel paging request at f0001000" — that also *proves* the abort
   class rather than inferring it.
2. Whether `drv.read 0xd024000 16` has read side-effects on the FE mailbox page (the
   handler issues four plain `ldr`s; `0x70024000` is not the `0x705c400` descriptor
   block, so I expect none — INFERRED).
3. The `//` name vs the `;` alias: unverified whether a player-side RS232 console can type
   `;` (irrelevant for the shim, which passes the string verbatim).
