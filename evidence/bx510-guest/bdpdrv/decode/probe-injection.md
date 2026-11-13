# PROBE_SEQ injection path — how the C96 fire carries the fixed clidrive shim and runs P0-P2 by itself

**Scope:** the *injection path* only — how the shim's module parameter reaches the
guest, the exact probe-runner edit that carries it (proposed, not applied), the
post-fire verdict gate, and the built `.ko` that the fire consumes.
**Not touched:** `tools/bx510_bdpdrv_stub_probe.py` (diff proposed below, applies
with `patch -p1`), `tools/bx510_clidrive.c` (fixed already, only built),
`emulator-kit/sony-bx510.c` (owned elsewhere).
**Inputs:** `tools/bx510_bdpdrv_stub_probe.py` (tar staging + guest command list),
`tools/bx510_clidrive.c` (PROBE_SEQ mode), `decode/clidrive-fix.md` §3/§6.1,
`decode/drvcli-surface.md` §5, `run-c94-c95.md` (the C95 fire line this one extends).

---

## 0. The constraint that shapes the whole design

The probe runner builds ONE tar and writes it into the unused `fe_test_data`
NAND partition, then boots the guest and drives a fixed command list; the guest
untars to `/res` and insmods out of `/res/shim/`:

```
host: build_tar(shim/osal_stub.ko, shim/osal_stub_a.ko, extra{shim/<NAME>})   ← --extra-file NAME=PATH
  → fe_test_data @ offset 14680064 (1 MiB partition; C95 payload 634,880 B)
guest: dd if=/res/test-bdev | tar -xf - -C /res
  → insmod /res/shim/osal_stub_a.ko   (part A provider)
  → insmod /lib/modules/2.6.35/BDP/drvcli.ko
  → insmod /res/shim/osal_stub.ko     (part B)
  → insmod /res/shim/bx510_feboot.ko
  → insmod /lib/modules/2.6.35/BDP/bdpdrv.ko
  → … CLI channel / inventory / kallsyms checks …
  → insmod /res/shim/bx510_clidrive.ko         ← the LAST module; no arguments today
```

The shim has exactly one interface — a `charp` module parameter
(`decode/clidrive-fix.md` §3). The tar can therefore carry the *binary* but not
the *mode*: **the mode can only travel on the insmod line.** Nothing else in the
command list runs after that line except `sleep 3; echo CLI_DRAIN2` and
`echo STUB_DONE`, so there is no "second chance" command; the flag has to be on
the insmod line itself.

Why insmod parameters work here (mechanism, verified not assumed):

| link | evidence |
|---|---|
| the shim declares the parameter | `module_param(clidrive_args, charp, 0444)` in `tools/bx510_clidrive.c`; the built module's `.modinfo` carries `parm=clidrive_args:…` + `parmtype=clidrive_args:charp` (§3 below) and its UND set includes `param_set_charp`/`param_get_charp` — i.e. the kernel's own param parser is linked in |
| the guest's `insmod` forwards `NAME=VALUE` argv to the kernel | the guest's `/sbin/insmod` is BusyBox v1.17.2 (ARM, 584,608 B, hard-linked applet multiplexer — pulled from `/tmp/rootfs/sbin/insmod` on the VM); its insmod applet joins `argv[2..]` into the module-options string (`parse_cmdline_module_options`) and calls `init_module`. A single token needs no quoting |
| the shim's test is a substring | `strstr(clidrive_args, "PROBE_SEQ")` — so a composite value is a later addition, not a rewrite |

Residual: this guest has never been fired with a module parameter (no `insmod … =
…` line exists in any C2…C95 UART log), so the mechanism is *high-confidence but
not yet observed end-to-end*. The gate in §5 makes a failed injection fail
loudly instead of silently reproducing the old default-mode output.

---

## 1. Proposed edit — `tools/bx510_bdpdrv_stub_probe.py` (`--clidrive-mode`)

Four hunks, ~14 added lines, zero behaviour change when the flag is absent
(the default rendering is `insmod /res/shim/bx510_clidrive.ko`, plus one new
echo line). **Not applied here** — the tracked file is untouched (md5
`5838d8b3d66905fdd9f0a540d3df6bbd`); the diff below was validated by applying it
to a copy, `py_compile`-ing the copy and running its `--help` (§6).

```diff
--- a/tools/bx510_bdpdrv_stub_probe.py
+++ b/tools/bx510_bdpdrv_stub_probe.py
@@ -70,6 +70,11 @@
                         "/res/shim/NAME) — e.g. the real SATA stack (C51: "
                         "libata.ko -> sata_mt85xx_mod.ko) so _fg_fe_bootup "
                         "comes from the real driver")
+    p.add_argument("--clidrive-mode", default="", metavar="MODE",
+                   help="module parameter for the clidrive shim: the guest "
+                        "gets 'insmod /res/shim/bx510_clidrive.ko "
+                        "clidrive_args=MODE' (e.g. PROBE_SEQ for the P0-P2 "
+                        "ladder); empty = the default instrument path")
     p.add_argument("--bdpdrv-host", required=True, type=Path,
                    help="host path to bdpdrv.ko for hashing/pinning")
     p.add_argument("--bdpdrv-guest", required=True, type=str,
@@ -105,6 +110,10 @@
             raise SystemExit(f"bad --pre-file {spec!r}; want NAME=PATH")
         extra[f"shim/{name}"] = Path(path).read_bytes()
         pre_files.append(name)
+    # decode §5: the clidrive shim is inert without its module parameter, and
+    # insmod is the only place the parameter can travel — so the mode is
+    # rendered here, next to the file that is staged, not guessed later.
+    clidrive_opt = f" clidrive_args={a.clidrive_mode}" if a.clidrive_mode else ""
     payload = build_tar(stubko, stuba_ko, extra)
     parts = json.loads((images / "manifest.json").read_text())["partitions"]
     part = next(x for x in parts if x["name"] == "fe_test_data")
@@ -169,7 +178,8 @@
         "sleep 2; echo CLI_DRAIN1",
         # Run C49: kernel-side driver — x_cli_set_mode(5) + x_cli_parser via
         # module param (cli output is SerPrintStr-polled UART + printk)
-        "insmod /res/shim/bx510_clidrive.ko; echo CLIDRIVE_RC=$?",
+        f"echo CLIDRIVE_MODE={a.clidrive_mode or 'DEFAULT'}",
+        f"insmod /res/shim/bx510_clidrive.ko{clidrive_opt}; echo CLIDRIVE_RC=$?",
         "sleep 3; echo CLI_DRAIN2",
         "echo STUB_DONE",
         # clean guest shutdown (C85 lesson): QEMU flushes its -D log on a
@@ -226,6 +236,7 @@
             "sha256": sha256(stubko),
             "size": stubko.stat().st_size,
         },
+        "clidrive_mode": a.clidrive_mode or "DEFAULT",
         "fe_test_data": {"offset": part["offset"], "size": part["size"], "payload_size": len(payload)},
         "terminal_marker": marker_ok,
     }
```

Rendered guest lines (the whole point; produced by running the patched logic):

| fire flag | guest commands (new/changed) |
|---|---|
| *(none)* | `echo CLIDRIVE_MODE=DEFAULT` · `insmod /res/shim/bx510_clidrive.ko; echo CLIDRIVE_RC=$?` |
| `--clidrive-mode PROBE_SEQ` | `echo CLIDRIVE_MODE=PROBE_SEQ` · `insmod /res/shim/bx510_clidrive.ko clidrive_args=PROBE_SEQ; echo CLIDRIVE_RC=$?` |

Design notes (why this shape and nothing more):

* **One flag, not a command-list variant.** The mode is a single string that the
  shim already parses; a second hard-coded command list would fork the run
  sequence and break comparability between C9x traces.
* **The intent echo is part of the edit, not a nicety.** Without
  `CLIDRIVE_MODE=…` on the UART, "PROBE_SEQ did not fire" and "the probe copy on
  the VM was stale" look identical in the evidence (the stale-probe trap). The
  echo is the UART-side record of what the fire asked for; the shim's own
  `[CLIDRIVE] mode = PROBE_SEQ (3 probes…)` line is the guest-side record of
  what it did. Two records, one grep apart.
* **`meta.json` gets the mode** so the bundle is self-describing without the
  fire line being remembered.
* Line length after the edit: `insmod /res/shim/bx510_clidrive.ko
  clidrive_args=PROBE_SEQ; echo CLIDRIVE_RC=$?` = 74 chars. The guest console
  wraps at ~80 but does not truncate — C95 already ran a 155-char two-line
  command (`cat /res/clidev > /res/cliout …`, log line 1562-1563) successfully.
* **No `sleep` change.** P2's help dump is ≤48 short lines; `sleep 3` before
  `echo STUB_DONE` is already the drain window, and the `after PROBE_SEQ: cur =`
  end marker makes a truncation visible.

---

## 2. Built artifact — the fixed shim, ready for the fire

The tracked build pipeline (`tools/bx510_stub_build.sh`) builds *all three*
modules (osal_a, osal_b, osal_c). Only `osal_c` changed, so only `osal_c` was
rebuilt: `osal_a`/`osal_b` are already built and are byte-for-byte what C94/C95
fired (meta sha256 `50539 B / 63cdd078…`, `220658 B / d78be553…`), and
rebuilding them would change nothing but the recorded hashes.

**Pipeline caveat, recorded:** `make sacd-stub-build` cannot run in this
checkout — its `$(SACD)` prefix is `experiments/sacd_reconstruct`, which does not
exist here:

```
$ make sacd-stage
scp: stat local "experiments/sacd_reconstruct/tools/bx510_*.c": No such file or directory
make: *** [sacd-stage] Error 1
```

So the same steps were run through the same ssh/scp prefix the target uses
(`ssh -o BatchMode=yes -p 2222 aftermath@10.20.0.18`), with the build form the
tracked pipeline and `sacd-hdhost-mod` use: `cd $KDIR; make ARCH=arm M=<dir>
modules EXTRA_CFLAGS="-march=armv6 -Wa,-march=armv6"` + the vermagic patch.

### 2.1 Compile command (from kbuild's own `.bx510_clidrive.o.cmd`)

```
/home/aftermath/gnuarm/bin/arm-none-linux-gnueabi-gcc
  -nostdinc -isystem …/gcc/arm-none-linux-gnueabi/4.4.1/include -I…/arch/arm/include
  -include include/generated/autoconf.h -D__KERNEL__ -mlittle-endian -Wall -Wundef
  -Wstrict-prototypes -Wno-trigraphs -fno-strict-aliasing -fno-common
  -Werror-implicit-function-declaration -fno-delete-null-pointer-checks -Os -marm
  -mabi=aapcs-linux -mno-thumb-interwork -funwind-tables -D__LINUX_ARM_ARCH__=7
  -march=armv7-a -msoft-float -Uarm -Wframe-larger-than=1024 -fno-stack-protector
  -fomit-frame-pointer -g -Wdeclaration-after-statement -Wno-pointer-sign
  -fno-strict-overflow -fconserve-stack -fno-dwarf2-cfi-asm
  -march=armv6 -Wa,-march=armv6                  ← the pipeline's EXTRA_CFLAGS (last wins)
  -DMODULE -DKBUILD_BASENAME=KBUILD_STR(bx510_clidrive)
  -DKBUILD_MODNAME=KBUILD_STR(bx510_clidrive) -c -o …/bx510_clidrive.o …/bx510_clidrive.c
```

`make_rc=0`, `warning_count=0`, `error_count=0` (the only kbuild chatter is the
pre-existing "Symbol version dump … is missing" notice, which every module build
in this tree prints).

Note on verbosity: this tree's `make` 4.4.1 run prints no `CC [M]` line even at
`V=1` (kbuild's `findstring s,$(MAKEFLAGS)` path picks the silent form), so the
"build log" is thin; the compile command above is taken from kbuild's own
`.cmd` file, which is a stronger record than a console echo.

### 2.2 Source → module identity

| item | value |
|---|---|
| source | `tools/bx510_clidrive.c`, 8,537 B, md5 `da40a3d115ab887537328edf17d00199` (identical on the Mac and VM — the fix is the tracked file) |
| module **before** vermagic patch | 28,184 B, sha256 `895c0e40c157f3c4cd6e331fcae30a2e444687edd0dbcde95388497c8816206c`, `vermagic=2.6.35 preempt mod_unload ARMv7` |
| vermagic patch | `bx510_vermagic_patch.py`: `ARMv7 occurrences: 1 → patched 1` |
| **module the fire consumes** | **`/tmp/osal_c/bx510_clidrive.ko` — 28,184 B, md5 `8a2f8c5b434e8989b9769b68ce0b4b34`, sha256 `ca029c211bd03ee8fb72a45a7d5d3d73dac10cb7df79024f257728a7dd5bdf5f`** |
| `.modinfo` | `description=BX510 CLI runtime driver + tree dump (INSTRUMENT)` · `parm=clidrive_args:"PROBE_SEQ" runs the P0->P1->P2 acceptance ladder (decode drvcli-surface.md section 5)` · `parmtype=clidrive_args:charp` · `depends=` · `vermagic=2.6.35 preempt mod_unload ARMv6` |
| UND set (all kernel-core) | `__aeabi_unwind_cpp_pr0, kallsyms_lookup_name, param_get_charp, param_set_charp, printk, strstr` |
| durability | VM `/tmp` is tmpfs, so the artifact is **also** at `~/bx510-build/osal_c/` (`bx510_clidrive.ko` + `bx510_clidrive.c` + `buildC.log` + `compile-cmd.txt`), same md5 |
| determinism | three independent builds (fresh dirs) produced the identical sha256 `ca029c21…` — the recorded hash is a stable identity, not a timestamp |

Size cross-check against the old shim, which is what the gate in §5 keys on:
C95's `ls -l /res/shim` (UART log line 211) shows **23088** for the old
`bx510_clidrive.ko`; this build is **28184**. `decode/clidrive-fix.md` §5
recorded 28,192 from the fix's own build — an 8-byte delta from the source as it
now sits in the tree; the load-bearing facts (24-byte `cli_ent` assertion
compiled, `.modinfo` parm, UND set, vermagic) are re-verified above, and the
gate compares against **28,184**, the artifact that will actually be staged.

Payload fit: C95's 634,880 B payload carried the 23,088 B shim; swapping in
28,184 B gives **639,976 B of 1,048,576** (61 %) — the probe's own
`payload does not fit fe_test_data` guard stays quiet.

---

## 3. Fire command — C96 with the injected PROBE_SEQ

Staging (Mac → VM). The probe file on the VM is what actually runs, so the
stale-copy check is part of the fire, not an afterthought:

```sh
# 1) mac: the tracked probe + shim source are the source of truth
md5 tools/bx510_bdpdrv_stub_probe.py            # pre-diff: 5838d8b3d66905fdd9f0a540d3df6bbd
scp -o BatchMode=yes -P 2222 tools/bx510_bdpdrv_stub_probe.py \
    aftermath@10.20.0.18:/tmp/
# 2) vm: the fire runs from ~/bx510-emu/emulator (run.py/smoke.py live there)
cp /tmp/bx510_bdpdrv_stub_probe.py ~/bx510-emu/emulator/
md5sum ~/bx510-emu/emulator/bx510_bdpdrv_stub_probe.py   # must equal the mac md5
# 3) vm: pre-fire artifact check — the FIXED shim must be the one staged
md5sum /tmp/osal_c/bx510_clidrive.ko        # must be 8a2f8c5b434e8989b9769b68ce0b4b34
ls -l /tmp/osal_c/bx510_clidrive.ko         # must be 28184 bytes
```

Fire (VM; the C95 line + `--clidrive-mode PROBE_SEQ`):

```sh
cd ~/bx510-emu/emulator && BX510_TRACE=1 python3 bx510_bdpdrv_stub_probe.py \
  --qemu work/build/qemu-system-arm --images /tmp/images-fe \
  --stubko /tmp/osal_b/bx510_osal_stub.ko --stuba-ko /tmp/osal_a/bx510_osal_stub_a.ko \
  --bdpdrv-host /tmp/rootfs/lib/modules/2.6.35/BDP/bdpdrv.ko \
  --bdpdrv-guest /lib/modules/2.6.35/BDP/bdpdrv.ko \
  --pre-file libata.ko=/tmp/sata_staging/libata.ko \
  --pre-file sata_mt85xx_mod.ko=/tmp/sata_staging/sata_mt85xx_mod.ko \
  --extra-file bx510_feboot.ko=/tmp/osal_d/bx510_feboot.ko \
  --extra-file bx510_clidrive.ko=/tmp/osal_c/bx510_clidrive.ko \
  --clidrive-mode PROBE_SEQ \
  --uart /tmp/bdpdrv-runC96.uart.log --unimp /tmp/bdpdrv-runC96.mmio.log \
  --meta /tmp/bdpdrv-runC96.meta.json --timeout 300
```

`BX510_TRACE=1` keeps C95's full MMIO trace (the C96 model check needs the FE
register sequence; it costs ~165 MB in the VM's tmpfs). `--timeout 300` matches
C95. Without `--clidrive-mode` the same command reproduces the old default
instrument output — that is the run-to-run differential, one flag apart.

Pull-back (evidence files, named like C94/C95 so the bundle stays uniform):

```sh
# mac
scp -o BatchMode=yes -P 2222 \
  aftermath@10.20.0.18:/tmp/bdpdrv-runC96.uart.log \
  aftermath@10.20.0.18:/tmp/bdpdrv-runC96.meta.json \
  aftermath@10.20.0.18:/tmp/bdpdrv-runC96.clidrive.txt \
  evidence/bx510-guest/bdpdrv/
# the 165 MB mmio log stays VM-side (C95 precedent); commit the post-handshake
# tail as decode/bdpdrv-runC96.posthandshake.mmio.gz if the FE sequence is the story
```

---

## 4. Evidence separation — which file carries which claim

One run produces three artifact classes that must not be read across each other:

| artifact | carries | must NOT be used for |
|---|---|---|
| `bdpdrv-runC96.uart.log` | console: boot, module loads, printk, `[CLIDRIVE]` lines, CLI help dumps, `[OSAL_STUB]` thread chatter | byte-level protocol claims (it is text, and the stub's IRRC thread interleaves printk lines into every region — see C95 lines 1855-1877) |
| `bdpdrv-runC96.mmio.log` | `-d unimp,guest_errors` + `BX510_TRACE` MMIO/FE sequence | CLI claims (the parser/driver calls are kernel-side function calls and touch no MMIO by construction) |
| `bdpdrv-runC96.meta.json` | run identity: qemu path, `bdpdrv`/stub sha256, `fe_test_data` offset+size+payload_size, `terminal_marker`, **`clidrive_mode`** | anything behavioural |
| `bdpdrv-runC96.clidrive.txt` | the PROBE_SEQ slice, carved from the UART by the gate (§5): from `[CLIDRIVE] up (INSTRUMENT)` to `[CLIDRIVE] after PROBE_SEQ` | — (derived, regenerate, don't hand-edit) |

Ordering matters for attribution and it is favourable: the clidrive insmod is
the **last** module in the list, after bdpdrv is loaded and after the FE/ATA
traffic has happened. So the P0-P2 probes cannot perturb the ATA/FE evidence,
and if P0 data-aborts (`decode/drvcli-surface.md` §5: a P0 abort is a *rig* bug)
the bdpdrv evidence is already in the log; the tell is
`terminal_marker: false` in meta plus the missing `STUB_DONE`.

Interleaving caution: the stub's `IRRC_DataProcessingThread` prints
`[OSAL_STUB] x_thread_delay …` continuously (C95: thousands of lines, several
inside the clidrive region). Every verdict below therefore keys on **line-anchored
fixed markers** owned by the shim (`^[CLIDRIVE] …`) plus exact help-line
prefixes — never on adjacency, ordering, or "the next line after".

---

## 5. Verdict greps — the post-fire gate

All patterns are anchored (`^`) for a measured reason: the guest echoes each
command line before running it, and the shim's own `expect …` lines *quote* the
expected payload strings — so unanchored counts came out **2** for
`CLIDRIVE_MODE=`, `Read addr = …` and `hdmitx(hdmitx): …` in the harness
selftest (§6). Anchoring is what separates "the shim printed it" from "the shell
echoed the command" and from "the shim printed what it expects".

```sh
#!/bin/sh
# bx510_c96_clidrive_verdict.sh — post-fire gate for the PROBE_SEQ injection.
# Usage: sh bx510_c96_clidrive_verdict.sh [uart.log]
# Exit 0 = PASS (every marker present), 1 = FAIL (prints which one broke).
#
# LC_ALL=C: the UART transcript carries non-UTF8 bytes (boot banners, ANSI
# colour codes); a UTF-8 locale makes sed/awk abort mid-stream.
LC_ALL=C; export LC_ALL
U=${1:-/tmp/bdpdrv-runC96.uart.log}
CLI=${U%.uart.log}.clidrive.txt

# Evidence separation: the CLI-probe slice gets its own file, bounded on BOTH
# ends — a truncated dump shows up as the missing end marker, not as silence.
sed -n '/^\[CLIDRIVE\] up (INSTRUMENT)/,/^\[CLIDRIVE\] after PROBE_SEQ/p' "$U" > "$CLI"

fail=0
want() {   # want <count> <bre> <file> <label>
  n=$(grep -c "$2" "$3")
  if [ "$n" = "$1" ]; then echo "PASS  $4  ($n)"
  else echo "FAIL  $4  (want $1, got $n)"; fail=1; fi
}

# Anchors are load-bearing: the guest echoes every command line before running
# it, and the shim's own "expect ..." lines quote the expected payload strings,
# so an unanchored count doubles. Anchored = the shim's output line only.
want 1 '^CLIDRIVE_MODE=PROBE_SEQ$'                      "$U"   "intent: mode reached the shell"
want 1 '^\[CLIDRIVE\] up (INSTRUMENT)'                  "$CLI" "shim insmodded"
want 1 '^\[CLIDRIVE\] mode = PROBE_SEQ (3 probes'       "$CLI" "PROBE_SEQ branch taken"
want 1 "^\[CLIDRIVE\] parser('P0 read 0x1000 16') = 0"  "$CLI" "P0 rc=0 (rig control)"
want 1 "^\[CLIDRIVE\] parser('P1 driver') = 1"          "$CLI" "P1 rc=1 (help dump)"
want 1 "^\[CLIDRIVE\] parser('P2 drv') = "              "$CLI" "P2 rc recorded (1 or -10)"
want 1 '^\[CLIDRIVE\] after PROBE_SEQ: cur = '          "$CLI" "ladder ran to completion"
want 1 '^Read addr = 0x00001000, length = 16'           "$CLI" "P0 memory-read payload"
want 1 '^hdmitx(hdmitx):         Hdmi Tx command'       "$CLI" "P1 known-good help line"
want 0 "^\[CLIDRIVE\] parser('driver') = "              "$CLI" "default path skipped"
want 1 '^CLIDRIVE_RC=0$'                                "$U"   "insmod took the parameter"

# the FIXED shim ran: old shim 23088 B, fixed shim 28184 B (`ls -l /res/shim`).
# $1 ~ /^-/ keeps the command-echo line (which also names the .ko) out.
sz=$(awk '$1 ~ /^-/ && /bx510_clidrive\.ko/ {print $5}' "$U" | sort -u | tr '\n' ' ')
if [ "$sz" = "28184 " ]; then echo "PASS  fixed shim size ($sz)"
else echo "FAIL  fixed shim size (want 28184, got '$sz')"; fail=1; fi

if [ "$fail" = 0 ]; then echo "CLIDRIVE_VERDICT=PASS"; else echo "CLIDRIVE_VERDICT=FAIL"; fi
exit "$fail"
```

Meta assertions (separate, two lines, no parsing of prose):

```sh
python3 - <<'PY'
import json
m = json.load(open("/tmp/bdpdrv-runC96.meta.json"))
print("clidrive_mode    =", m.get("clidrive_mode"), "(want PROBE_SEQ)")
print("payload_size     =", m["fe_test_data"]["payload_size"], "(want 639976 with the C95 extra set)")
print("terminal_marker  =", m["terminal_marker"], "(want True)")
PY
```

### What each failure means (the differential table)

| failing check | reading |
|---|---|
| `intent: mode reached the shell` = 0 | the probe copy on the VM is stale, or `--clidrive-mode` was not passed. Fix staging; the run is not C96 |
| `intent` PASS + `PROBE_SEQ branch taken` = 0, `insmod took the parameter` PASS | the option string did not reach the shim (insmod argv not forwarded). Fallback is a source change — the mode as a marker file staged in the tar, read with a kernel file API — which is a parent decision, not a flag |
| `insmod took the parameter` = 0 | module load failed outright (read `CLIDRIVE_RC=` value; verify the 24-byte `cli_ent` assertion and vermagic by re-running §2 on the staged source) |
| `P0 rc=0` = 0 but `P0 memory-read payload` = 1 | the handler ran but returned non-zero — a real behavioural difference in `_CmdMemRead`, not a rig fault |
| neither P0 line, and `ladder ran to completion` = 0 | P0 data-aborted (parser unreachable / direct-map assumption broken). RIG bug per §5 P0; the earlier bdpdrv/ATA evidence in the same log is still valid |
| `P1 known-good help line` = 1 in *default*-mode log fields | expected: the default path logs the same `hdmitx` line. That is why P1 must be judged together with `parser('P1 driver') = 1`, not on the text alone |
| `default path skipped` = 1 | the shim ran its default path — either the flag never arrived (see row 2) or an old `.ko` was staged (row `fixed shim size`) |
| `fixed shim size` ≠ 28184 | the staged `.ko` is not this build; re-check `md5sum /tmp/osal_c/bx510_clidrive.ko` |
| `P2 rc recorded` = 1 but no lane lines follow | group 5 matched as a directory but dumped nothing — that is `decode §5` P2's discovery branch: re-read the tree with `ls` before scripting the 48 lanes |

---

## 6. Validation performed (harness controls, not a fire)

1. **Diff applied to a copy, not the tree.** `python3 /tmp/probe_diff_test.py`
   applied the four hunks to a copy of `tools/bx510_bdpdrv_stub_probe.py`
   (asserting each `oldText` occurs exactly once), wrote `/tmp/probe_patched.py`,
   `py_compile` → OK, `diff -u` → the four hunks in §1.
   `PYTHONPATH=emulator-kit python3 /tmp/probe_patched.py --help` → usage line
   includes `[--clidrive-mode MODE]` with the help text, exit 0.
   The tracked file is unchanged: `md5 5838d8b3d66905fdd9f0a540d3df6bbd`,
   `git status` clean for that path.
2. **Rendered-command check** for both modes (§1 table) — the empty-flag render
   is byte-identical to today's insmod line.
3. **Gate selftest, both directions** (a gate that cannot fail is not a gate):

   | fixture | expectation | result |
   |---|---|---|
   | synthetic PROBE_SEQ transcript built from the shim's own `printk` format strings (`/tmp/synth-c96.uart.log`) | PASS | `CLIDRIVE_VERDICT=PASS`, exit 0, 12/12 PASS |
   | the committed C95 UART log (default instrument mode) | FAIL | `CLIDRIVE_VERDICT=FAIL`, exit 1 — fails 9 checks incl. `PROBE_SEQ branch taken` and `fixed shim size (want 28184, got '23088')` |
   | synthetic transcript with the `after PROBE_SEQ` line removed (truncation) | FAIL | `CLIDRIVE_VERDICT=FAIL`, exit 1 — only `ladder ran to completion` fails, i.e. truncation is named precisely |

   The selftest earned its keep: the first version of the gate had four pattern
   bugs (unanchored intent marker / payload / help-line counts and an `awk`
   that also matched the command echo) and the synthetic fixture caught all
   four before the fire.
4. **Build** (§2): `make_rc=0`, zero warnings/errors, vermagic patched
   ARMv7→ARMv6, `.modinfo` parm present, UND set kernel-core only, three builds
   → identical sha256.
5. **Not performed, by scope:** no guest fire. Stage-3/fire is the parent's
   (`gt-fire` / the C96 line in §3); this doc's job is to make that run carry
   the flag and to make its evidence checkable.

---

## 7. Residual risks

1. **The module parameter has never been exercised in this guest** (no
   `insmod … = …` in any C2..C95 log). Mechanism evidence is BusyBox-v1.17.2
   argv forwarding + the kernel param parser linked into the shim; the gate's
   `intent` + `branch taken` + `insmod took the parameter` triple is the test.
   If it fails, the fallback (mode read from a staged file) is a source change
   and a parent decision.
2. **P0 may data-abort** on the first attempt (`decode §5` P0 caveat: the
   `0xF0000000` direct-map assumption is inferred). Symptom and reading are in
   the differential table; the ATA/FE evidence from the same run stays valid
   because the shim loads last.
3. **P2 is the one unresolved expectation** — `drv` may return `-10` (lanes not
   reachable by group name at root). The gate asserts only that a return code
   was recorded; the value 1 vs -10 is the finding, not a PASS/FAIL.
4. **Gate constants are build-specific**: `28184` (shim size) and the anchored
   shim strings follow `tools/bx510_clidrive.c` as committed. Any further edit
   to that file must re-derive them (expectation-freshness rule).
5. **`/tmp/osal_c` is tmpfs**: after a VM reboot the shim is gone
   (`~/bx510-build/osal_c/` holds the same md5 and the build script; re-stage
   from there, then re-check `md5sum`).
6. **Makefile `sacd-*` staging targets do not run in this checkout** (§2) — the
   fire's staging steps above use the equivalent direct `scp` form. If those
   targets are meant to be the single path, `$(SACD)` needs fixing first.
