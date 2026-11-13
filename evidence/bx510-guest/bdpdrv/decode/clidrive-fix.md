# bx510_clidrive.c — fix per the drvcli-surface decode

**Scope:** the kernel-side CLI shim (`tools/bx510_clidrive.c`) only. No other
source file touched; load order, build pipeline (`tools/bx510_stub_build.sh`)
and vermagic handling are unchanged.
**Input:** `evidence/bx510-guest/bdpdrv/decode/drvcli-surface.md` — §0 (three
corrections), §2.1 (entry layout), §0.2 (return codes), §2.2 (access rights),
§5 (P0-P5 ladder + the four shim rules). Section cites below are that doc's.

---

## 1. What changed

| # | change | decode cite |
|---|---|---|
| 1 | **Entry struct fixed**: `fn` at `+0x08`, `sub` at `+0x0c`, 24-byte stride. The old struct had a phantom `void *_z` at `+0x08` and read `fn_or_sub` at `+0x0c`, i.e. it only ever saw `sub` — which is why every leaf printed `<NULL fn>`. | §2.1 (and the explicit "trap for `tools/bx510_clidrive.c`" note) |
| 2 | **Route into the parser**: the extern-linkage calls (`x_cli_parser`, `x_cli_set_mode`, `x_cli_get_current_root`) are replaced by `kallsyms_lookup_name` resolution of those same **functions** at init. No data symbol is looked up — `pt_cur_cmd_tbl`, `apt_cli_array`, `e_access_right`, `at_cli_mod_grp_info`, `_arDefaultCmdTbl` are absent from the guest kallsyms (CONFIG_KALLSYMS_ALL off), so the tree is read by *asking the parser*, not by walking pointers. Every lookup is printed (`[CLIDRIVE] sym …`), so an unresolved name is evidence rather than a guess. | §5 rule 4, §0.3, §6 |
| 3 | **`root table = 0` re-read as what it is**: the root sentinel, not a failure. The default path still prints it (so the C50/C93/C95 line stays byte-identical) and no longer treats a 0 as a reason to skip anything. | §0.1, §2.4 |
| 4 | **Probe-sequence mode added**: `clidrive_args=PROBE_SEQ` runs P0 → P1 → P2 as **separate** `x_cli_parser()` calls, printing the return code per call. Without the flag the module keeps the old instrument behaviour (root table + `parser('driver')`), which reproduces the known-good reference. | §5 (ladder + "1 is a help dump, not an error") |
| 5 | `dump_tbl` recursion now keys on `sub` (a directory is an entry with a subtable), prints `fn`, `sub` and `access` as decoded words, and is documented as single-table-only — a group slot can be a *table array*, which is reachable through the parser (`ls`) but must not be pointer-walked. | §2.1, §2.4 |

### Route: what the module now links against

UND symbol set of the built `bx510_clidrive.ko`:

```
U __aeabi_unwind_cpp_pr0
U kallsyms_lookup_name
U param_get_charp
U param_set_charp
U printk
U strstr
```

All kernel-core. Consequence worth having: the shim no longer *requires*
drvcli at link/insmod time. If `x_cli_parser` does not resolve, it prints

```
[CLIDRIVE] x_cli_parser unresolved - drvcli.ko not loaded; nothing to drive
```

and loads inert, instead of failing insmod with "Unknown symbol". The
instrument therefore cannot be misread as "drvcli missing" vs "shim broken".

---

## 2. Entry-struct layout as now packed

```c
struct cli_ent {                       /* 24 bytes, NULL-name terminated */
  char *name;                          /* +0x00 */
  char *alias;                         /* +0x04 */
  int (*fn)(int argc, char **argv);    /* +0x08  leaf handler   */
  struct cli_ent *sub;                 /* +0x0c  subtable (dir) */
  char *help;                          /* +0x10 */
  unsigned access;                     /* +0x14  access-right index (§2.2) */
};
typedef char cli_ent_must_be_24_bytes[sizeof(struct cli_ent) == 24 ? 1 : -1];
```

Evidence for the layout: `_parse_cmd` reads `[entry+0x08]` (fn), `[entry+0x0c]`
(sub) and `[entry+0x14]` (access) at 0x15b8 / 0x15dc / 0x153c (§2.1). The
24-byte assertion is a compile-time gate: the cross-build below only succeeds
if the packing is right, so a later header change cannot silently shift the
walk (a wrong word here reads a string pointer as a function pointer).

Directory semantics: an entry with `sub != 0` is a directory; the parser at a
directory match calls `_show_help()` and returns `argc` (**1**), it does not
change `pt_cur_cmd_tbl` — only `cd` does (`_cli_cmd_change_dir`). That is why
`parser('driver') = 1` in C50/C93/C95 is a successful dump and why
`cur` remains `0x0` afterwards.

---

## 3. Probe-sequence mode

Module parameter (`charp`, perm 0444), so the parameter string is the only
new interface on the shim:

```
insmod /res/shim/bx510_clidrive.ko clidrive_args=PROBE_SEQ
```

The same ASCII argument goes in the AutoScript launch line on the player; the
test is `strstr(clidrive_args, "PROBE_SEQ")`, so a composite string
(`clidrive_args=PROBE_SEQ,P2ONLY`) is a later addition, not a rewrite.

Probe strings, each handed to `x_cli_parser()` as its own call (state matters —
cd-like semantics, so the ladder is not equivalent to one concatenated string):

| id | string handed to the parser | source |
|---|---|---|
| P0 | `read 0x1000 16` | §5 P0 — rig control, run first every session |
| P1 | `driver` | §5 P1 — known-good reference (group 12 = cus driver, bdpdrv's `hdmitx` lane) |
| P2 | `drv` | §5 P2 — group 5, the 48-lane bdpdrv block, never asked for yet |

Per-call output (the return code is the assertion):

```
[CLIDRIVE] up (INSTRUMENT)
[CLIDRIVE] sym x_cli_parser         = c0xxxxxx
[CLIDRIVE] sym x_cli_set_mode       = c0xxxxxx
[CLIDRIVE] sym x_cli_get_current_root = c0xxxxxx
[CLIDRIVE] sym cli_parser           = c0xxxxxx
[CLIDRIVE] sym CLI_GetDefaultCmdTbl = c0xxxxxx
[CLIDRIVE] sym CLI_GetCusDrvCmdTbl  = c0xxxxxx
[CLIDRIVE] root table = 0x0
[CLIDRIVE] mode = PROBE_SEQ (3 probes, decode §5)
<probe output on the console UART>
[CLIDRIVE] parser('P0 read 0x1000 16') = 0
[CLIDRIVE] P0: handler ran; cur = 0x0; expect Read addr = 0x00001000, length = 16 + one memory line
<probe output>
[CLIDRIVE] parser('P1 driver') = 1
[CLIDRIVE] P1: directory matched, help dumped; cur = 0x0; expect [Help] + hdmitx(hdmitx):         Hdmi Tx command (rc=1)
<probe output>
[CLIDRIVE] parser('P2 drv') = 0|1|-10
[CLIDRIVE] P2: <meaning>; cur = 0x#; expect [Help] + 48 lane lines km(...)..bonding(...); rc=-10 => use 'ls' first
[CLIDRIVE] after PROBE_SEQ: cur = 0x0
```

Return-code vocabulary printed per call (§0.2):
`0` handler ran · `1` directory matched, help dumped · `-10` no match
(`-EAGAIN`) · `-1` drvcli not initialised · anything else = "unexpected".
Access mode is set to `0` (supervisor, §2.2) before any call, so `read`'s
`access=2` entry and group lanes are not filtered.

---

## 4. Expected UART signatures (P0/P1/P2, copied from decode §5)

* **P0** — `Read addr = 0x00001000, length = 16` then one line
  `0x00001000 | XXXXXXXX XXXXXXXX XXXXXXXX XXXXXXXX`.
  Proves: parser reachable, `_CmdMemRead` ran, and the `0xF0000000`
  direct-map OR (inferred, §2.5) holds. **A data abort here is a rig bug, not
  a target bug** — run P0 first, every session.
* **P1** — `[Help]` + a blank line + `hdmitx(hdmitx):         Hdmi Tx
  command`, `rc=1`. Byte-identical to the C50/C93/C95 log, so it calibrates
  the shim *and* the UART drain before anything new is asserted.
* **P2** — if group 5 resolves: `[Help]` + 48 lines `km(…): …` …
  `sacd(…): SACD command`, `ide(…): Ide command` … `bonding(…)`, `rc=1`.
  If instead `rc=-10`: the lanes are not reachable *by group name* at root —
  read the actual names with a root `ls` / `ls` after `cd drv`, then try the
  lane names directly (`sacd`, `ide`). P2 is the one probe that may need that
  discovery step before it can be scripted.

**Negative control carried over from §5:** `ide` → `tray_open_close` prints
*nothing* (handler is `mov r0,#0; bx lr`), so silence there distinguishes "the
probe reached a stub" from "the path is broken". Not part of the P0-P2 mode
(kept out to hold the shim to the three requested probes).

---

## 5. Validation

Cross-compiled on the lab VM against the real Sony tree and toolchain
(`~/sony-kernel/linux-2.6.35`, `~/gnuarm/bin/arm-none-linux-gnueabi-`,
`-march=armv6 -Wa,-march=armv6 -Wall`, the same flags `bx510_stub_build.sh`
uses):

```
make -C $KDIR ARCH=arm M=<dir> modules EXTRA_CFLAGS="$FLAGS -Wall"
OWN_WARNINGS=0
OWN_ERRORS=0
-rw-rw-r-- 1 aftermath aftermath 28192 bx510_clidrive.ko
```

`.modinfo` (unchanged shape, ASCII, vermagic untouched — the pipeline's
`bx510_vermagic_patch.py` step still applies exactly as before):

```
description=BX510 CLI runtime driver + tree dump (INSTRUMENT)
parm=clidrive_args:"PROBE_SEQ" runs the P0->P1->P2 acceptance ladder (decode drvcli-surface.md section 5)
parmtype=clidrive_args:charp
depends=
vermagic=2.6.35 preempt mod_unload ARMv7
```

So requirement 4 (no load-order / vermagic change) holds: the module is built
by the same pipeline section, with the same ARMv7→ARMv6 patched token, and its
UND set stays entirely kernel-core.

The 24-byte `cli_ent` assertion is part of that successful build — a wrong
packing is a compile error, not a runtime misread.

---

## 6. Open items (parent-side, not edited here)

1. **The rig's insmod line must carry the flag.** `bx510_bdpdrv_stub_probe.py`
   currently issues `insmod /res/shim/bx510_clidrive.ko` with no arguments, so
   the default instrument path would run and PROBE_SEQ would not fire. The
   one-line change is
   `insmod /res/shim/bx510_clidrive.ko clidrive_args=PROBE_SEQ`
   (or the equivalent AutoScript line). Not edited: single-writer scope for
   this task is `tools/bx510_clidrive.c`.
2. **P2 may need a discovery read** (`ls` at root / after `cd drv`) before the
   48-lane dump can be scripted — §5 flags this as the one unknown.
3. **P3-P5 are out of scope here** — they need the C96 disc and the
   `cd`/nesting state machine; the shim is deliberately only P0-P2.
