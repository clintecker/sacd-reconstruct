# PROBE_SEQ v2 — the corrected ladder, the built shim, and the feboot option-A decision

**Scope:** the two edits this pass owned — (1) `tools/bx510_clidrive.c` `PROBE_SEQ`
upgraded to the corrected ladder from `decode/p0-scan-decode.md` +
`decode/ide-cli-lane.md`, rebuilt on the lab VM; (2) the **option-A** (drop the feboot
module) decision turned into an exact one-line diff for the fire script plus the UART
delta it must be read against.
**Not touched:** `tools/bx510_bdpdrv_stub_probe.py` (the fire script is the parent's —
the diff below is handed over, not applied), `emulator-kit/sony-bx510.c`,
`tools/bx510_osal_stub.c` (parts A/B unchanged this pass), any other `decode/*.md`.

**Inputs:** `decode/p0-scan-decode.md` (§0.1/§1.2/§3.1/§4.3/§5), `decode/ide-cli-lane.md`
(§0/§2.2/§2.3/§4/§6/§7), `decode/feboot-marshal.md` (§1–§5), `tools/bx510_clidrive.c`
@ HEAD `da40a3d115ab887537328edf17d00199`, `tools/bx510_stub_build.sh` (the clidrive
build stanza, reused verbatim), `/tmp/bdpdrv/bdpdrv.ko` (8,112,032 B) for the
`fe_bootup` reader.

**Method:** the C source edit is the only source change; every expectation is a cite
into one of the three decodes. The feboot delta was re-derived from the module bytes,
not from the marshal doc's prose — that re-derivation **corrects** one of its claims
(§3.3), and the correction changes how the fire must be read.

---

## 0. TL;DR

1. **P0 is now `drv.read 0x1000 0`, not `read 0x1000 16`.** `read` is a leaf inside
   group 5 (`cli_init` `.text 0x8c0` `mov r1,#5`), so the dot-joined path is the only
   spelling that reaches it in one call. Length **0** keeps it a zero-risk control: the
   handler ORs the address with `0xF0000000` and derefs unconditionally, and length 0
   returns at `0x2aec` *before* the first load.
2. **P3 is the IDE-HAL transport leg**, full dotted form
   `drv.ide.pri_ver.initial 0 s 0` — one call, `argc=4`, bounded wait
   (`flags 0x31` ⇒ `flags&3==1`), placed last because the IDE HAL latches sticky globals.
3. **Default (non-`PROBE_SEQ`) mode is unchanged**: `clidrive_init`'s instruction
   sequence is identical to HEAD modulo immediates (130 vs 130 lines, `diff` clean) and
   every default-mode log literal is still present.
4. **Built:** `/tmp/osal_c/bx510_clidrive.ko`, 28,510 B, md5
   `e1d14c2577fd7a65bf54d3d51ef22897`, vermagic patched ARMv7→ARMv6 (0 ARMv7 left).
5. **feboot option A** = delete one line (`bx510_bdpdrv_stub_probe.py:183`). The
   expected delta is *not* just "WARNING gone": the module `v4IdeDrvInitThread` **polls
   the file content** for a `'1'` byte with no iteration cap, so with the real flag still
   `0` the line `FE boot up OK !!` disappears **and the thread never reaches `End..`** —
   an unbounded 200-unit poll, which is the honest observable of "the handshake really
   did not complete" (§3.3 corrects `feboot-marshal.md` §2 here).

---

## 1. The new `PROBE_SEQ` table (`tools/bx510_clidrive.c`)

```c
static const struct cli_probe cli_probes[] = {
  { "P0", "drv.read 0x1000 0",
    "rc=0 + 'Read addr = 0x00001000, length = 0' and NO payload row "
    "(length 0 => no deref)" },
  { "P1", "driver",
    "[Help] + hdmitx(hdmitx):         Hdmi Tx command (rc=1)" },
  { "P2", "drv",
    "[Help] + 57 lines incl 'read(r):                Memory read(word)' (rc=1)" },
  { "P3", "drv.ide.pri_ver.initial 0 s 0",
    "rc=0 + '[i4IdeHalTestInit]Signature:0x......' + 'CH:0, SataDev:1, "
    "UseQueue:0 Done!'; today also 'CmdWaitEvtRet'/'TIMEOUT !!' (model rows "
    "a+00c / a+220), or 'ModelName:' if the wait completed" },
};
```

### 1.1 why each row is that string

| row | spelling | decode basis | expected rc / UART |
|---|---|---|---|
| P0 | `drv.read 0x1000 0` | p0-scan-decode §0.1 (leaf in group 5), §3.1 P0-1, §4.3 (`_parse_cmd` recurses on a `.` inside argv[0]; space-separated descent is the other `-10` producer), §3.2 (the `\|0xF0000000` OR + unconditional deref), §3.3 (length 0 returns before the load) | rc **0**, exactly one line `Read addr = 0x00001000, length = 0`, **no** payload row |
| P1 | `driver` | unchanged, kept byte-identical to the C50/C93/C95 reference dump | rc 1 |
| P2 | `drv` | p0-scan-decode §1.2/§1.4 — group 5's array is 57 entries: 45 bdpdrv lanes + drvcli's 8-command default table (incl. `read(r)`) + 4 `arTestCmdTbl`; the old "rc=-10 => use 'ls' first" note was a mislabel from `drvcli-surface.md` §2.3 and is retired | rc **1** + 57 lines; `read(r):` in that dump is the standing proof the P0 fix targets a live entry |
| P3 | `drv.ide.pri_ver.initial 0 s 0` | ide-cli-lane §0.1 (one dotted call → `_IDECLI_Init`, `argc=4`), §2.3 P5-d, §4.1–§4.2 (the chain), §7.1 (bounded wait: `flags 0x31` ⇒ `flags&3==1`, never the untimed PIO-in spin), §7.3 (sticky globals ⇒ run last) | rc **0** + `[i4IdeHalTestInit]Signature:0x…` + `CH:0, SataDev:1, UseQueue:0 Done!`; today also `CmdWaitEvtRet:` / `TIMEOUT !!` (the model's `a+00c` / `a+220` rows), or `ModelName:` if the wait completed |

Both decodes agree the **dotted form is the one-call descent** (`_search_tbl` compares
only `strlen(entry)` bytes up to the first `'.'`, and `_parse_cmd` 0x161c branches to the
recursive descent exactly when that byte is `'.'`), which is why P0 and P3 use it and why
the old space-separated `read 0x1000 16` could never have worked.

### 1.2 P3's placement and its fallback

* **Placement.** `_fgSataDev` / `_fgSataHwInit` / `_fgUseQueMode[]` are sticky
  process globals (ide-cli-lane §7.3): after P3 the IDE HAL believes SATA/REG mode for
  the rest of the boot. The shim is the *last* module the fire insmods
  (`bx510_bdpdrv_stub_probe.py:210`) and nothing but drains follow it, so "last in the
  ladder" already satisfies the decode's "run P5 as the last gate of a boot".
* **Fallback.** If P3 returns `-10` the lane was never attached; the diagnostic is the
  directory spelling `drv.ide.pri_ver` (rc 1, 33 help lines). Pre-typed in the source
  comment so the next run does not re-derive it.

### 1.3 what did NOT change

* `run_probe()` semantics, the `PROBE_SEQ` substring test, the root-sentinel print, and
  the whole default-mode block are untouched (§2.2 verifies this against the built
  bytes).
* Only two non-table strings changed, both `PROBE_SEQ`-only or `modinfo`-only: the mode
  banner (`"(4 probes, dotted ladder)"`) and `MODULE_PARM_DESC`, which now reads
  `parm=clidrive_args:"PROBE_SEQ" runs the P0->P3 acceptance ladder (decode
  p0-scan-decode.md section 5, ide-cli-lane.md section 6)`.
  **Documentation debt this creates:** `decode/probe-injection.md` §3 records the old
  `.modinfo` string; that record is now stale (one line, the parent's file to refresh).

---

## 2. Build — `bx510_stub_build.sh`'s clidrive stanza, on the lab VM

`tools/bx510_stub_build.sh` already builds **three** modules, clidrive included
(`/tmp/osal_c/bx510_clidrive.ko`), so no new build recipe was invented: the stanza was
reused verbatim (same `CROSS_COMPILE`, same `-march=armv6 -Wa,-march=armv6`, same
`$HOME/sony-kernel/linux-2.6.35`, same `bx510_vermagic_patch.py`). Parts A/B were not
rebuilt (their sources did not change).

```
export CROSS_COMPILE=$HOME/gnuarm/bin/arm-none-linux-gnueabi-
FLAGS="-march=armv6 -Wa,-march=armv6"; KDIR=$HOME/sony-kernel/linux-2.6.35
rm -rf /tmp/osal_c && mkdir -p /tmp/osal_c && cd /tmp/osal_c
cp /tmp/bx510_clidrive.c bx510_clidrive.c
printf 'obj-m := bx510_clidrive.o\n' > Makefile
make -C "$KDIR" ARCH=arm M="$PWD" modules EXTRA_CFLAGS="$FLAGS"   # -> /tmp/buildC.log
python3 /tmp/bx510_vermagic_patch.py /tmp/osal_c/bx510_clidrive.ko
```

| result | value |
|---|---|
| **artifact** | `/tmp/osal_c/bx510_clidrive.ko` (on the lab VM, `10.20.0.18`) |
| **size** | 28,510 B (HEAD build: 28,184 B — the difference is the longer ladder strings) |
| **md5** | **`e1d14c2577fd7a65bf54d3d51ef22897`** |
| sha256 after vermagic patch | `e9257de9353e7dab4c9a9f13a2732544b725ce381cad3fa69fc71b53ac3813df` |
| vermagic | `2.6.35 preempt mod_unload ARMv6` (patch reported 1 ARMv7 occurrence patched, 0 remaining) |
| build warnings | none from this source; the only log hit is the standing `WARNING: Symbol version dump …/Module.symvers` (also present on the HEAD build) |
| staged source | VM `/tmp/bx510_clidrive.c` md5 `da40a3d1…` (HEAD) → replaced by the edited source; local+VM in sync |

`strings` on the built module confirms both new probe strings and the new `parm=` line:

```
parm=clidrive_args:"PROBE_SEQ" runs the P0->P3 acceptance ladder (decode p0-scan-decode.md section 5, ide-cli-lane.md section 6)
vermagic=2.6.35 preempt mod_unload ARMv6
drv.read 0x1000 0
drv.ide.pri_ver.initial 0 s 0
```

### 2.1 delivery to the fire

Unchanged from `decode/probe-injection.md`: the parent's fire stages it with
`--extra-file bx510_clidrive.ko=/tmp/osal_c/bx510_clidrive.ko` and runs
`insmod /res/shim/bx510_clidrive.ko clidrive_args=PROBE_SEQ`. The mode banner now reads
`[CLIDRIVE] mode = PROBE_SEQ (4 probes, dotted ladder)` — a fire that sees
`(3 probes` is running the old binary.

### 2.2 "default mode byte-identical" — verified, not asserted

Two builds from the same VM toolchain, `git show HEAD:tools/bx510_clidrive.c` vs the
edited source:

| check | result |
|---|---|
| `clidrive_init` instruction sequence (`.init.text`, addresses/immediates normalized) | **130 lines vs 130 lines, `diff` empty** |
| default-mode literals present in the new `.ko` | `[CLIDRIVE] up (INSTRUMENT)`, `[CLIDRIVE] root table = %#lx`, `parser('driver') = %d`, `[CLIDRIVE] after 'driver': cur = %#lx`, `[CLIDRIVE] down` — all present |
| `strings` diff HEAD vs new | only the ladder strings (`read 0x1000 16` gone; `drv.read 0x1000 0`, `drv.ide.pri_ver.initial 0 s 0` added; three `expect` strings), the mode banner, and the `parm=` line — plus `__mod_*` symbol-index renumbering |

So a default-mode fire (`clidrive_args` absent) produces the same UART it did in
C50/C93/C95; only the `PROBE_SEQ` path and `modinfo` differ.

---

## 3. feboot — option A (drop the module), as an exact one-line diff

`decode/feboot-marshal.md` §4 option A: delete the `insmod` line, keep the file as a
tombstone. The reasoning it establishes (and this pass re-checked against the kernel
source it cites) stands: the module creates a **duplicate `/proc/driver`** at the head of
the proc subdir list and forces `_fg_fe_bootup = 1`, so `FE boot up OK !!` in every
C54+ run is the module's assertion, not evidence.

### 3.1 the diff (one deleted line, `tools/bx510_bdpdrv_stub_probe.py`)

```diff
--- a/tools/bx510_bdpdrv_stub_probe.py
+++ b/tools/bx510_bdpdrv_stub_probe.py
@@ -180,7 +180,6 @@
         f"insmod {a.bdpdrv_guest.rsplit('/',1)[0]}/drvcli.ko; echo DRVCLI_INSMOD=$?",
         "insmod /res/shim/osal_stub.ko; echo STUB_INSMOD=$?",
         "grep osal_stub /res/proc/modules; echo STUB_MOD=$?",
-        "insmod /res/shim/bx510_feboot.ko; echo FEB_INSMOD=$?",
         f"insmod {a.bdpdrv_guest}; echo BDPDRV_INSMOD=$?",
         "grep bdpdrv /res/proc/modules; echo BDPDRV_MOD=$?",
         # CLI runtime channel (Run C35+): drvcli registers char major 244;
```

Applied form: **delete line 183** (8-space indent, string
`"insmod /res/shim/bx510_feboot.ko; echo FEB_INSMOD=$?,"`). Nothing else in the command
list changes: the load order `stub_a → drvcli → stub_b → bdpdrv` is preserved, and
`/proc` is mounted by `procc.sh` (ROOTPROC=0 since C54 — the mount, not the module, is
what flipped `Can't open` to `FE boot up OK`).

Two parent-owned follow-ups, deliberately **not** folded into the diff:

* **`--extra-file bx510_feboot.ko=/tmp/osal_d/bx510_feboot.ko` can stay.** Nothing
  insmods it, so it lands in `/res/shim/` as the tombstone marshal §4-A describes; keeping
  the line also keeps the fire working as long as `/tmp/osal_d` exists. Dropping it is a
  second, optional line — and note `feboot-marshal.md` §0: the source lives only on the
  VM, so a rebuilt VM silently loses it and the fire would then fail at staging.
* If you want the option-A verdict to be *decidable* rather than inferred, marshal §5's
  three observations are the ones that settle §3's shadowing claim:
  `ls -ld /proc/driver /proc/driver/sata; echo DRVLS=$?`,
  `ls /proc/driver/sata; echo SATALS=$?`,
  `cat /proc/driver/sata/fe_bootup; echo CATREAL=$?`
  (unshadowed ⇒ `rtc`, `nvram`, `mmc`, `usb`, `sata` visible and `SATALS` lists the twelve
  real entries). This is a fire-script decision, so it is handed over, not applied.

### 3.2 expected UART delta

| # | line | with feboot | without feboot | why |
|---|---|---|---|---|
| 1 | `WARNING: … fs/proc/generic.c:583 proc_register+0x1a0/0x220` + its `dump_stack` "cut here" block | present | **gone** | the WARN rides the duplicate `proc_mkdir("driver", NULL)`; no module, no duplicate (`feboot-marshal.md` §1.3) |
| 2 | `[FEB] up (INSTRUMENT)` / `[FEB] /proc/driver/sata/fe_bootup created, flag = 1` | present | **gone** | the module's own printks |
| 3 | `FEB_INSMOD=0` | present | **gone** | the echo goes with the insmod line (pure deletion) |
| 4 | `[v4IdeDrvInitThread]Can't open /proc/driver/sata/fe_bootup` | present only C50–C53 (proc unmounted) | **must NOT appear** | `sata_bltin` creates `/proc/driver/sata/fe_bootup` at boot; with `/proc` mounted the `filp_open` succeeds. If this line *does* appear, the premise ("sata_bltin provides the path") is falsified and A becomes B |
| 5 | `[v4IdeDrvInitThread]FE boot up OK !!` | always (forged) | **only if the real `_fg_fe_bootup == 1`** — i.e. if `sata_mt85xx_port_start`'s firmware-load path actually ran. Absent ⇒ the boot genuinely did not complete the FE handshake, which is the whole point of A | see §3.3 |
| 6 | `[v4IdeDrvInitThread]End..` | always | **absent whenever #5 is absent** — the thread is stuck in its content poll (§3.3) | see §3.3 |
| 7 | `/proc/driver/*` for kernel built-ins (`rtc`, `nvram`, `mmc/*`, `usb/*`) and 11 of the twelve `sata_bltin` entries | path-unreachable (shadowed) | **reachable again** | head-insertion + head-first lookup, `feboot-marshal.md` §3 |

Reading rule for the fire: **#4 absent + #5 present** = feboot was vestigial and the FE
handshake is real. **#4 absent + #5 absent + #6 absent** = the handshake did not complete
in this boot (the emulator's status/signature rows are the cause, and the IDE lane is the
next lever — `ide-cli-lane.md` §4.5). **#4 present** = the premise failed; go to option B.

### 3.3 correction to `feboot-marshal.md` §2 — it is a *poll*, and it has no iteration cap

`feboot-marshal.md` §2 states the reader is "a one-shot init wait, not a poll". The
module bytes say otherwise. `v4IdeDrvInitThread` (`.text 0x969ec`, bdpdrv.ko) does:

```
96a60  r0 = "/proc/driver/sata/fe_bootup"; r1 = 0x800; r2 = 0
96a6c  filp_open
96a70  cmn r0,#4096 ; bls 96abc        ; IS_ERR ? -> error print : success path
96abc  success path:
96ae0    vfs_llseek(filp, 0, SEEK_SET)
96af8    vfs_read(filp, &byte@sp+20, 1, &pos)     ; ONE byte
96afc    ldrb r3,[sp,#20]
96b00    cmp  r3, #49                  ; '1'
96b04    bne  96b48 -> x_thread_delay(200) -> b 96acc   ; retry, no cap
96b08    '1' -> print "[%s]FE boot up OK !!\n"
96b54  filp_close ; 96bb0 gated print "[%s]End..\n"
```

* Both prints and the error print are gated on the byte at `.data 0x41820`
  (`_fgIDELog`, image-initialised to 1, no writer — `ide-cli-lane.md` §4.2), so they
  are on unless the image is patched.
* **No counter, no deadline:** the loop's only exit is the content becoming `'1'`.
  With the real flag at `0`, the thread polls every 200 units forever and never prints
  `End..`.
* Consequence for the delta: option A's observable in a non-handshaking boot is a
  **silently stalled thread** (rows 5+6 missing) with the rest of the UART continuing —
  *not* a wedge and *not* the `Can't open` error path. Do not classify that as a rig
  failure.
* **Open risk (INFERRED, not decoded):** if the spawning init (function @ `.text 0x97f68`,
  the one that passes `v4IdeDrvInitThread` to `x_thread_create` at pool `0x983f0`) joins
  or waits on that thread, `bdpdrv`'s `insmod` would not return and the fire would appear
  stuck at `BDPDRV_INSMOD`. The tell is UART traffic continuing while `BDPDRV_MOD` never
  prints. Keep the fire's outer timeout; this is the one way option A can cost a run.

---

## 4. Residual risks / open questions

1. **P0's length-0 read proves dispatch, not the memory path.** `drv.read 0x1000 0`
   exercises path descent + leaf dispatch + argument parse; it deliberately never
   dereferences, because `addr|0xF0000000` cannot reach RAM (`p0-scan-decode.md` §3.2).
   A payload leg needs an IO page (`drv.read 0xd024000 16` → VA `0xfd024000`), which is
   *not* in the ladder — adding it is a separate decision, and §8.2 of that decode leaves
   the read-side-effect question open.
2. **P3 shares the `a-window` with the C97 libata path** (`ide-cli-lane.md` §7.4: `a+000`
   / `a+25c` are aliased as PIO data port vs IRQ-enable/status word). In a boot where
   libata traffic already ran, a `WaitEvt` read can pop IDENTIFY payload words, so P3's
   `Signature:` value can be perturbed by earlier activity. It only distorts the P3
   reading, not the earlier evidence (P3 is last), but do not compare P3's signature
   across boots with different disc traffic.
3. **`.modinfo` record staleness** — `decode/probe-injection.md` §3 quotes the old
   `parm=clidrive_args` string; refresh it when convenient.
4. **feboot source remains untracked** (`feboot-marshal.md` §0) — option A makes the
   module's *absence* the default, which weakens (but does not remove) the cost of that
   gap. Option B, if ever needed, still needs the source tracked first.
5. **`_fg_fe_bootup`'s writer was not re-verified in this pass.** Rows 5–6 depend on the
   claim that `sata_mt85xx_port_start` (or `sata_bltin`) sets the real flag on a
   successful firmware load; that is `feboot-marshal.md` §2's citation, taken as-is.
   The run itself is the experiment.

---

## 5. One-line summary

P0 is now the dotted leaf `drv.read 0x1000 0` (length 0 ⇒ no deref), P1/P2 unchanged,
P3 is the IDE-HAL transport leg `drv.ide.pri_ver.initial 0 s 0` last in the ladder;
default mode verified unchanged in the built bytes; shim rebuilt on the lab VM to
`/tmp/osal_c/bx510_clidrive.ko` md5 `e1d14c2577fd7a65bf54d3d51ef22897`; feboot option A is
one deleted line at `bx510_bdpdrv_stub_probe.py:183`, and the delta to read for is
"WARN gone, `Can't open` absent, `FE boot up OK !!` + `End..` present only if the real
flag reached 1 — the thread content-polls `'1'` with no cap".
