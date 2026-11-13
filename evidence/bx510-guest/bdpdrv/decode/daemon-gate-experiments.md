# The daemon's STARTUP GATE, turned into a runnable guest test

Date: 2026-11-13. Stage after `daemon-ioctl-side.md` (§3.1 boot order) and
`sacdread-cpsa.md` (§1.1 module init gates, §3.2 the seven commands). This
document **extends** both — it re-derives nothing — and produces the artifact
the C-run needs before it launches the real daemon:

* `decode/daemon_gate.sh` — 14-gate POSIX-sh startup test (busybox-safe,
  `sh -n` clean on dash, no bashisms),
* `decode/sacd_gate_ioctl.c` — the one thing sh cannot do (issue `ioctl(2)`),
  a 120-line helper built with the era toolchain, same shape as the proven
  `tools/bx510_sacdstat.c`,
* §4 — the exact command block to insert into the C-fire command list
  (`tools/bx510_bdpdrv_stub_probe.py`'s `commands` array) before the daemon.

**House rules.** **VERIFIED** = read out of an instruction, a literal pool, a
symtab/section header, or a run already in evidence. **INFERRED** = reasoned
from a pattern and labelled. Nothing here was executed inside the emulator:
the gate script was syntax-gated VM-side and its helper cross-built, and it
must not be fired until the disc path exists (§4 last paragraph).

---

## 0. Bottom line

1. **14 gates, in the daemon's own order.** The daemon's first five seconds are
   `install_modules()` → `server_loop()`; everything before the first client is
   shell/fs/module work, and everything after it is the `SACD_IOC_*` handshake
   plus one **plain** (non-ioctl) read. §1 is the checklist; every gate cites
   the sentence it stands for.
2. **Two facts assumed by the stage brief do not survive the decode** and are
   corrected here (§5), from instructions rather than preference: `0x40105302` is **AUTH**
   (`CPSA_SACDCmdSetCtrl`), not a version query; and there is **no userspace
   version query at all** — `eSacdGetVersion` is a `bdpdrv` function reachable
   only from `_SACDCLI_TestPhy`, which `sacd_read.ko` never calls. Also: TEST
   UNIT READY is not reachable through `sg`-anything in this rootfs — the TUR
   the daemon performs *is* ioctl `0x40105306`.
3. **The daemon mknods and insmods its own module** — so the gate must not
   "help" it: gate 07 only creates `/dev/sacd_read` when it is absent, and gate
   08 refuses to call a pre-loaded module a pass unless `/proc/misc` agrees on
   minor **201** (the node and the registered minor are two separate facts, and
   a mismatch is invisible until `open()` returns `ENODEV`).
4. **The insmod line is `insmod <staged sacd_read.ko> minor=201` — with no
   `compid`.** `compid` lives in `.bss` (`sacd_read.ko` symtab, `.bss+0x24`,
   section 27 NOBITS) ⇒ its default is **0**, i.e. GCPU 0, and that is the
   slot the daemon asks for. Expected init prints are in §3.
5. **A "sane bytes" ioctl test is possible only for the five zero-payload
   commands.** 5301 INIT / 5302 AUTH / 5305 UNINIT / 5306 TUR / 5307 PROFILE
   take a `memset`-zeroed 16-byte struct (decode §1.2). 5303 READ needs
   `lba+sectors+2064×n` and 5304 DECRYPT blocks on the GCPU/TrustZone worker
   with **no timeout** (`sacdread-cpsa.md` §4.3) — the helper **refuses** both
   by design, so a gate run can never wedge the guest on a decrypt.
6. **Success polarity is not uniform**, and the gate encodes the daemon's own
   test per command: `>= 0` for INIT/AUTH/PROFILE (a CPSA-convention return of
   `0x68000000` is a **success**, not an error) but `== 0` for TUR, because
   `server_loop` itself reads `disc_sacd() != 0` as "Tray is empty".

---

## 1. The ordered checklist — the 14 gates

Order is the daemon's: environment → module stack → nodes → per-second disc
poll → first-`DISC_OPEN` leg. "Lane" is who has to make the row true; no row
here needs anything from the decrypt/GCPU lane.

| gate | what the daemon does (VERIFIED, `daemon-ioctl-side.md`) | what must be true | which lane provides it |
|---|---|---|---|
| **01** proc | loads/uses modules at all; every check below reads `/proc` | `/proc/modules` readable | guest env — shell-mode mounts `proc` (C-run command list already does `mount -t proc proc /res/proc`) |
| **02** tmp-writable | `install_modules` `0x2f9a4-0x2f9f4`: `memcpy(buf,"/tmp/",6)`, `tmpnam`, `open(O_WRONLY\|O_CREAT\|O_TRUNC)`, `write(97805 B)` | `/tmp` writable with ≥ 97,805 B free | guest env — the rootfs is a read-only squashfs (C54 lesson), so `/tmp` must be a tmpfs |
| **03** daemon-shell-deps | `system("mknod -m0666 /dev/sacd_read c 10 201")`, `system("insmod %s minor=201")`, `system("rmmod sacd_read")`, `system("rm -rf /dev/sacd_read")` (`0x2f9fc`, `0x2fa14`, `remove_modules 0x2fb40`) | `mknod`/`insmod`/`rmmod` resolvable via the daemon's inherited `PATH`; `/dev` writable | guest env — `/dev` must be a tmpfs over the squashfs dir (C54) |
| **04** bdpdrv-resident | nothing — the daemon never loads `bdpdrv`; `sacd_read.ko` resolves its whole API by `kallsyms_lookup_name` at init | `bdpdrv` present in `/proc/modules` | module-stack lane (C50/C51-C55: `osai`/`rm`/`cbagent`/`drvcli` + OSAL stubs → `bdpdrv`) |
| **05** module-symbols | `sacd_read.ko` init: 13 mandatory lookups, `-EFAULT` on any NULL (`sacdread-cpsa.md` §1.1) | 13 names resolvable in `/proc/kallsyms` **plus** `x_memset`, the module's only non-kernel link-time import (PHASE0-RESULTS P2) | module-stack lane + the `x_memset` provider — `osal_stub.ko` in the C-run rig (stub-run.md: `x_memset` observed as a stub call), `osai.ko` on the player |
| **06** sr0-node | `client_thread` `0xcc40` calls `sacd_open("/dev/sr0")` unconditionally; `sacd_dev_input_open` `0x21df8` opens it `O_RDONLY` and returns NULL on failure | `/dev/sr0` exists as a block node (11:0) and opens | ODD-stack lane: `libata.ko` → `sata_mt85xx_mod.ko` → `cdrom.ko` → `sr_mod.ko`, then `mknod /dev/sr0 b 11 0` (`odd-cb-agent.md` §3.2); enumeration itself is C96/C97 |
| **07** sacd-read-node | `0x2f9fc` mknods it; the whole ioctl path `open("/dev/sacd_read",0)`s per call (`0x20fb8` et al.) | char node **10:201** exists | sacd_read.ko lane (the gate creates it only if absent) |
| **08** module-load | `0x2fa14` insmods the **embedded** copy with `minor=201`; `misc_register` is init's last step | insmod rc 0 **and** `/proc/misc` reports `sacd_read` on minor **201** | sacd_read.ko lane (a staged copy of `original/sacd_read.ko` in the C-run; the daemon stages its own at runtime) |
| **09** sacd-read-open | `0x2fa34`: `open("/dev/sacd_read", O_RDONLY)` is install's acceptance test; failure ⇒ `"%s: mknod/insmod filed"` ⇒ `"Can not install modules"` ⇒ exit | the node opens | sacd_read.ko lane |
| **10** unit-ready | `server_loop` `0xe1f0`, once per second, **before any client**: `disc_sacd()` = ioctl `0x40105306` → `_IDECLI_OddTestUnitReadyLoop(20000)`; result `!= 0` ⇒ status line says "Tray is empty" | `ret >= 0` **and** `u4Result == 0` | disc responder / ODD model — SR-2 (`sacdread-cpsa.md` §4.4) |
| **11** disc-profile | `server_loop` `0xe214`: `sacd_sacd()` = ioctl `0x40105307` → `_IDECLI_OddGetProfile`; driver returns `-1` unless current profile `== 0x10`; `< 0` ⇒ "Disc inserted", `>= 0` ⇒ "SACD disc inserted" | `ret >= 0` **and** `u4Result >= 0` | disc responder — SR-3, the daemon's own disc gate |
| **12** sacd-init | `sacd_dev_input_open` `0x21e34` on the default `/dev/sr0` path: `init_sacd()` = ioctl `0x40105301`; `< 0` aborts the open (reported as `"libsacdread: Can't open /dev/sr0 for reading"`) | `ret >= 0` **and** `u4Result >= 0` | sacd_read.ko + bdpdrv CPSA (`Connect(0x16b,compid,360,compid)` + `CPSMode_Ctrl(...,0x40,TRUE)`) |
| **13** master-toc | `scarletbook_read_master_toc` `0x2a25c`: **plain** `lseek64`+`read` of 10×2048 B at LBA **0x1FE**, first 8 bytes must be `"SACDMTOC"`; failures `"Can't read Master TOC."` / `"Not a ScarletBook disc!"` | `/dev/sr0` serves those bytes (this needs **no** `0x8530` support) | disc fixture lane (Firebird ISO / synthetic fixture) — this is where "the disc appeared" is observable |
| **14** sacd-auth | `client_thread` `DISC_OPEN`: `sacd_open` → `scarletbook_open` (gate 13) → `sacd_authenticate` = ioctl `0x40105302` → `CPSA_SACDCmdSetCtrl` | `ret >= 0` **and** `u4Result >= 0` | sacd_read.ko + bdpdrv CPSA (`SetSACDControl` → `i4CPSA_SACD_EnableControl`, which returns `0x68000000`) |

Two properties of this table are worth stating plainly:

* **Gates 01-09 are exactly "why the daemon exits in the first 100 ms".** The
  full failure taxonomy for them is already written down in
  `daemon-ioctl-side.md` §5.1; the gate adds nothing to the decode, it only
  makes each row checkable *before* the daemon runs, one at a time.
* **Gates 10-11 run with no session and no disc-specific support beyond SCSI
  answers.** They are the cheapest possible proof that the ODD model is
  answering `TEST UNIT READY` and `GET CONFIGURATION` at all — the two rows
  that `sacdread-cpsa.md` §4.4 already assigned to "the disc responder".

---

## 2. The script

`decode/daemon_gate.sh` — POSIX sh, busybox-safe (`command -v`, `dd`, `awk`,
`sed`, `od`, `grep -qw`, no arrays, no `[[ ]]`, no `local`, no `${var:off:len}`).

**Output contract** (one line per gate, greppable):

```
GATE <id> <PASS|FAIL|SKIP> <name> -- <detail>
...
GATE_N=<passed>/<total>
GATE_FAIL=<n>
GATE_SKIP=<n>
GATE_VERDICT=<PASS|INCOMPLETE|FAIL>
```

Exit status is **0 only on `PASS`**. `INCOMPLETE` (no FAIL, but at least one gate
could not run — helper not staged, `AUTH=0` pre-disc, no disc yet) exits 1: a
gate that did not run must never be accepted at a fire gate, and the most likely
false positive in this rig is exactly that. A *pre-disc* run reporting
`GATE_VERDICT=INCOMPLETE` is the expected outcome and is not a defect.

**Env knobs** (defaults are the C-run's shell-mode layout):

| var | default | why it exists |
|---|---|---|
| `PROC` | `/proc` | shell-mode mounts proc at `/res/proc` |
| `SR0` | `/dev/sr0` | shell-mode `/dev` is a tmpfs at `/dev`, but the C-runs also use `/res/dev` |
| `DEV` | `/dev/sacd_read` | `bx510_sacdstat.c` used `/res/dev/sacd_read` — keep the choice explicit |
| `KO` | `/res/shim/sacd_read.ko` | the staged copy (the rootfs has none: `sacdread-cpsa.md` §3.1) |
| `HELPER` | `/res/shim/sacdgate` | built from `sacd_gate_ioctl.c` |
| `MINOR` | `201` | the daemon's own `mknod`/`insmod` value |
| `COMPID` | *(empty ⇒ module default 0)* | only to escape a stale instance slot (EBUSY) |
| `AUTH` | `1` | `AUTH=0` skips gate 14 when there is no disc yet |

**The helper** (`sacd_gate_ioctl.c`) prints exactly one machine-readable line:

```
IOCTL cmd=0x40105301 ret=<ioctl(2) ret> errno=<n> result=<u4Result as int> raw=<4 words> dev=<path>
```

`result` is `arg[0]`, the field the daemon itself reads back (`ret = cmd.u4Result`,
`daemon-ioctl-side.md` §1.2). The helper exits 0 when a line was produced, 1 when
the device would not open (still printing the line, so the gate can distinguish
"node missing" from "driver refused"), 2 for usage errors and for the two
**refused** commands (5303/5304, §0.5).

**Build** (VM, era toolchain, dynamic against Sony's libc — the
`tools/bx510_sacdstat.c` shape the gate suite already ran in-guest):

```sh
~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -Wall -Wextra -std=gnu99 \
    -o /tmp/sacdgate evidence/bx510-guest/bdpdrv/decode/sacd_gate_ioctl.c
```

**Validation performed for this stage** (no emulator fire, per the brief):

| check | command | result |
|---|---|---|
| POSIX syntax, dash (the VM's `/bin/sh`) | `sh -n /tmp/daemon_gate.sh` on the VM | **rc=0** |
| shellcheck, sh dialect, style severity | `shellcheck -s sh -S style daemon_gate.sh` | **rc=0**, no findings |
| helper cross-build | `~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -Wall -Wextra` | **rc=0**, `-Wall -Wextra` clean |
| helper ELF identity | `readelf -h/-d` | `ELF32, ARM, EABI5, Type EXEC`, `NEEDED libc.so.6` only; undefined set is pure libc (`open/ioctl/close/printf/fprintf/fwrite/memcpy/strtoul/__libc_start_main/abort`) |
| helper logic (host x86 twin) | no args / `0x40105303` / `0x40105304` / junk / missing device | rc 2/2/2/2/1 with the intended messages |
| script logic (fake procfs + fake helper) | 4 runs with `PROC`/`DEV`/`HELPER`/`AUTH` overrides, plus a unit test of the summary block | gates 01-14 all reachable; EFAULT/EBUSY classification on simulated `insmod` text; `GATE_N`/`GATE_VERDICT` and the exit code correct for PASS(0) / INCOMPLETE(1) / FAIL(1) |

---

## 3. The insmod invocation and its expected prints

### 3.1 The exact command line

The daemon's own line (`daemon-ioctl-side.md` §3.1, `0x2fa14`) is

```
sprintf(buf2, "insmod %s minor=201", tmpfile); system(buf2);
```

i.e. **`insmod <tmpnam temp file> minor=201`** — the module image is the copy
embedded in the binary (`_binary_sacd_read_ko_start`, 97,805 B, byte-identical
to `original/sacd_read.ko`, `sha256 b3d7a383…`). For the gate (and for any
pre-daemon test) the equivalent line, run with **no `compid` parameter**:

```sh
insmod /res/shim/sacd_read.ko minor=201
```

* **`minor=201`** — the module's only load-time knob that matters here:
  `sacd_read.ko .init.text+0x8` loads `.bss+0x34` (`minor`) and stores it into
  `sacd_read_dev.minor` **only if non-zero**; otherwise the `.data` default
  `0xFF` (`MISC_DYNAMIC_MINOR`) stands, and the daemon's hard-coded node
  `c 10 201` would then point at nothing. Both halves must agree — that is
  exactly what gate 08 checks against `/proc/misc`.
* **`compid` — omitted, default 0.** `compid` is an **uninitialised** `.bss`
  object (`llvm-readelf -s`: `compid` → section 27 `.bss` NOBITS, offset 0x24;
  `minor` → `.bss+0x34`), so the module comes up with `compid = 0`. The daemon
  never passes it (`daemon-ioctl-side.md` §1.2: "compid/minor are not in the
  payload at all"). Modinfo declares the range: `parm=compid:GCPU Compute ID (0-3)`.
  Only pass `COMPID=1..3` if init returns `-EBUSY` (the slot is owned).
* **`vermagic=2.6.35 preempt mod_unload ARMv6 `** (`.modinfo`). A guest kernel
  that differs by a token rejects the load with `Invalid module format` — the
  gate classifies that text explicitly, because it looks identical to a
  symbol problem from a distance.
* **The module declares `depends=` (empty)** — `insmod` will not pull anything
  in, and `x_memset` must therefore already be exported by a resident module:
  `osal_stub.ko` in the C-run rig (stub-run.md lists `x_memset` among the stub's
  observed calls), `osai.ko` on the player. Gate 05 covers it.

### 3.2 Expected init prints (UART/console)

Init prints three header lines, the separator twice, then one line per symbol
lookup from `kallsyms_lookup_name_diag` (`%s` is the shared `__func__` token
**`SACDREAD`**, literal `.rodata.str1.1+0x22`):

```
[SACDREAD] ========================================
[SACDREAD] minor = 201
[SACDREAD] compid = 0
[SACDREAD] ========================================
[SACDREAD]Symbol "i4CPSA_Inst_CPSMode_Ctrl" address is 0x........
[SACDREAD]Symbol "_IDECLI_OddRead" address is 0x........
[SACDREAD]Symbol "_i4CPSA_Inst_Decrypt" address is 0x........
[SACDREAD]Symbol "i4CPSA_Inst_SetSACDControl" address is 0x........
[SACDREAD]Symbol "u4CPSA_Inst_GetInstHandleFromCompId" address is 0x........
[SACDREAD]Symbol "i4CPSA_Inst_Connect" address is 0x........
[SACDREAD]Symbol "i4CPSA_Inst_Disconnect" address is 0x........
[SACDREAD]Symbol "vSacdDecryptEnable" address is 0x........
[SACDREAD]Symbol "_SACDCLI_TestPhy" address is 0x........
[SACDREAD]Symbol "eSacdGetVersion" address is 0x........
[SACDREAD]Symbol "_SACDCLI_FindTag" address is 0x........
[SACDREAD]Symbol "_IDECLI_OddTestUnitReadyLoop" address is 0x........
[SACDREAD]Symbol "_IDECLI_OddGetProfile" address is 0x........
[SACDREAD]Symbol "__ksymtab_disable_print" address is 0x........   <-- often the not-found line instead
```

The fourteenth line is the optional one: `__ksymtab_disable_print` is **absent
from bdpdrv.ko** and from every module in the rootfs (`sacdread-cpsa.md` §1),
so the expected line there is

```
[SACDREAD]Symbol "__ksymtab_disable_print" not found in /proc/allsyms!!
```

and it is **non-fatal**. (PHASE0-RESULTS P2 recorded the opposite in one rig —
the kernel image itself carried the name — so the gate must not require either
form. That is why gate 05 checks 13 + `x_memset` and not 14.)

The three failure lines, and what they mean:

| print | insmod text | meaning | gate that catches it first |
|---|---|---|---|
| `[SACDREAD]Symbol "X" not found in /proc/allsyms!!` then `-EFAULT` (`mvn r4,#13`) | `insmod: ...: Bad address` | a mandatory lookup is NULL — `bdpdrv` not resident, or one of the 13 missing | **05** (and 04) |
| `[SACDREAD] compid = 0 is used. Try another.` then `-EBUSY` (`mvn r4,#15`) | `insmod: ...: Device or resource busy` | the CPSA instance slot is owned (`_au4CpsaInst[compid] != -1`) — usually a second load without `rmmod` | **08** detail, fix with `COMPID=1..3` |
| `<3>[SACDREAD]Unable to register misc device` | (propagated errno) | `misc_register` failed — minor 201 already taken by a resident `sacd_read` | **08** via `/proc/misc` |

---

## 4. Preconditions — what to add to the C-fire command list

These are the rows `tools/bx510_bdpdrv_stub_probe.py`'s `commands` array must
carry **before** the daemon test. They are ordered; each one is a gate above.

```sh
# ── A. guest env the daemon shells into (gates 01-03) ────────────────────────
mount -t tmpfs tmpfs /dev                       # C54: rootfs /dev is ro squashfs
mknod /dev/console c 5 1; mknod /dev/null c 1 3; mknod /dev/ttyMT0 c 204 66
mkdir -p /tmp; mount -t tmpfs tmpfs /tmp        # install_modules writes the .ko here
mount -t proc proc /res/proc                    # C51: /proc itself never mounts; /res/proc does

# ── B. the stack bdpdrv needs, then bdpdrv, then the ODD stack (gates 04-06) ─
#     (exactly the order the C51-C55 runs use — do not re-invent it here)
insmod /res/shim/osal_stub_a.ko                 # UTIL_Printf/Printf/SYS_Printf + g_u4*log*
insmod /lib/modules/2.6.35/BDP/drvcli.ko
insmod /res/shim/osal_stub.ko                   # also the x_memset provider (gate 05)
insmod /lib/modules/2.6.35/BDP/bdpdrv.ko        # must go LIVE (C50) — gate 04
insmod /tmp/sata_staging/libata.ko              # --pre-file, C51 form
insmod /tmp/sata_staging/sata_mt85xx_mod.ko     # --pre-file, C51 form
insmod /lib/modules/2.6.35/BDP/cdrom.ko
insmod /lib/modules/2.6.35/BDP/sr_mod.ko
mknod /dev/sr0 b 11 0                           # block major 11 (odd-cb-agent.md §3.2)

# ── C. the module image + the ioctl helper (gates 07-09, 10-14) ─────────────
# staged via --extra-file sacd_read.ko=… and --extra-file sacdgate=… (mode 0555).
# gate 07 creates /dev/sacd_read c 10 201 only if it is absent; in a DAEMON run
# the daemon's own mknod creates it — do not pre-create it there.

# ── D. the gate itself, then the daemon ────────────────────────────────────
PROC=/res/proc DEV=/dev/sacd_read SR0=/dev/sr0 KO=/res/shim/sacd_read.ko \
    HELPER=/res/shim/sacdgate sh /res/shim/daemon_gate.sh; echo DAEMON_GATE_RC=$?
```

Three preconditions that are **not** gates but decide whether the daemon's
output exists at all, all from `daemon-ioctl-side.md` §3.3:

1. **Launch it as `-S` with stdin redirected** (`/sacd_extract_160 -S </dev/null &`).
   `validate_stdin()` returns 0 when stdin *is* the controlling terminal, and
   `server_loop` then **skips the disc poll entirely** and redirects logging to
   `/dev/null` — an interactive launch produces *no status line and no log*, and
   an empty transcript would look like a failure.
2. **Nothing printed is not a failure.** The happy path prints exactly one
   over-writing status line (`\r` + 14 spaces) per second; every error string
   goes to **stderr** via `log_print`, and is dropped when that stream is NULL.
   Capture stdout **and** stderr (DockerTarget/logs lesson).
3. **`/tmp` and `/dev` must be tmpfs** — the daemon writes the module image and
   mknods a node; a ro squashfs turns both into `"Can not install modules"` with
   no further diagnosis.

**And the one rule for the fire itself:** run gates 01-09 *before* launching the
daemon (they are "can it start"), and gates 10-14 *after* the disc path answers
(they are "will it read"). Do not fire the emulator on a disc path that fails
gate 13 — a daemon that reaches gate 13 and stops is indistinguishable from a
daemon that never started, without this checklist.

---

## 5. What is deliberately **not** a gate — and the brief's assumptions that the decode does not support

| item | why not a gate |
|---|---|
| **a version query** (`eSacdGetVersion`) | **Not reachable from userspace.** `eSacdGetVersion` is a `bdpdrv` function (`0xc6d38`: `(*0xfd039008 & 6) >> 1` → 3/0/1|2); `sacd_read.ko` looks the symbol up but **never calls it** (`sacdread-cpsa.md` §1: no load of the slot outside `.init.text`), and the only caller anywhere is `_SACDCLI_TestPhy`, which the module also never calls. A C-run/src-level daemon therefore **cannot** report a SACD version and must not be expected to. `0x40105302` — the number the brief called a "version query" — is **AUTH** (`CPSA_SACDCmdSetCtrl`). The gate tests it as AUTH (gate 14), on the daemon's own predicate. |
| TEST UNIT READY "via sg" | There is no `sg3_utils` in the guest rootfs, and the TUR the daemon performs is **ioctl `0x40105306`** → `_IDECLI_OddTestUnitReadyLoop(20000)`. The gate uses the ioctl (gate 10); an `sg`-equivalent would test a different code path (the block layer's own TUR) and prove nothing about the driver. |
| `0x40105303` READ | Needs `lba`, `sectors` and a `2064×n` (`n ≤ 128`) buffer; a zeroed payload is a 0-sector read. Refused by the helper. This is the *endgame* gate ("real daemon reads real sectors"), not a startup gate — and its byte count is still the open number (`sacdread-cpsa.md` §7.1 → `odd-cb-agent.md` §0.6: the host passes `2064×n` straight to the drive). |
| `0x40105304` DECRYPT | Blocks in `x_ev_group_wait_event` on the GCPU worker with **no timeout** (`sacdread-cpsa.md` §4.3) → a gate would hang the guest instead of failing. Refused by the helper. |
| area-TOC signatures (`TWOCHTOC`/`MULCHTOC`) | Real (`scarletbook_read_area_toc` `0x2c198`), but the gate would have to parse the master TOC for the area LBA, and that offset is not pinned in either decode doc. Deliberately absent rather than guessed: if gate 13 passes and the daemon then says `"Can't read Area TOC 1."`, that string is the evidence — do not invent an offset here. |
| `BLKGETSIZE64` / total sectors | `DISC_SIZE` time, not startup. `fstat64` covers the normal case and the disc size is a disc-responder truth, not a gate. |

---

## 6. Provenance and reproduce

| input | identity / role |
|---|---|
| `original/sacd_extract_160` | sha256 `0fdcefdb…`, 350,830 B — `daemon-ioctl-side.md` §3.1/§5.2 (boot order, failure strings) |
| `original/sacd_read.ko` | sha256 `b3d7a383…`, 97,805 B, unstripped DWARF — §1.1 init gates, `.bss` defaults, `.modinfo` vermagic |
| `bdpdrv.ko` | sha256 `6604f6cd…` — the 13 looked-up symbols (`sacdread-cpsa.md` §1, §2) |
| `evidence/bx510-guest/PHASE0-RESULTS.md` P2 | the only prior *execution* of this insmod, and the source of the `"Bad address"` = EFAULT observation and the `x_memset` dependency |
| `evidence/bx510-guest/bdpdrv/decode/odd-cb-agent.md` §3.2 | the four-insmod + mknod stack that produces `/dev/sr0` |
| `tools/bx510_sacdstat.c` | the proven dynamic-guest-binary shape the helper copies (5307 direct ioctl) |

New facts established *in this stage* (all re-derivable with the commands below):

1. `compid` and `minor` are `.bss` objects ⇒ module defaults **0** and **0**
   (`minor` 0 leaves `.data`'s `0xFF`/`MISC_DYNAMIC_MINOR` in force), so the
   daemon's `minor=201` is the *only* parameter that travels.
2. The init print token is **`SACDREAD`** (literal `.rodata.str1.1+0x22`), the
   banner prints twice (before and after minor/compid), and the per-symbol line
   comes from the `kallsyms_lookup_name_diag` wrapper, not from init.
3. `i4CPSA_SACD_EnableControl` returns **`0x68000000`**, which is **positive**
   ⇒ AUTH/INIT success must be tested signed `>= 0`, never `== 0`.

```sh
# the module param defaults and the vermagic (source of §3.1)
/opt/homebrew/opt/llvm/bin/llvm-readelf -s original/sacd_read.ko | grep -E ' compid$| minor$'
/opt/homebrew/opt/llvm/bin/llvm-readelf -S original/sacd_read.ko | grep -E '\.bss|\.data'
strings -a original/sacd_read.ko | grep -E 'vermagic|parm='

# the init print formats and the shared __func__ token (source of §3.2)
/opt/homebrew/opt/llvm/bin/llvm-objdump -d --no-show-raw-insn --section=.init.text \
    original/sacd_read.ko | head -20
python3 - <<'EOF'
d = open('original/sacd_read.ko','rb').read(); base = 0xb0c       # .rodata.str1.1
def s(o): return d[base+o:d.index(b'\0', base+o)].decode('latin1')
for o in (0x22, 0x202, 0x231, 0x242, 0x38c, 0x3b4, 0x1b1, 0x1d4):
    print(hex(o), repr(s(o)))
EOF

# the gate script: syntax + lint (no emulator)
shellcheck -s sh -S style evidence/bx510-guest/bdpdrv/decode/daemon_gate.sh
make vm-stage-file FILE=evidence/bx510-guest/bdpdrv/decode/daemon_gate.sh
make vm-stage-file FILE=evidence/bx510-guest/bdpdrv/decode/sacd_gate_ioctl.c
make vm-exec CMD='sh -n /tmp/daemon_gate.sh'            # dash: POSIX-strict
make vm-exec CMD='~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -Wall -std=gnu99 -o /tmp/sacdgate /tmp/sacd_gate_ioctl.c'
```
