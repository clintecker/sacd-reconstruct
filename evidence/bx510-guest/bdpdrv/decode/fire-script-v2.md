# Fire script v2 — the ODD tail, the `sacd_read` stage and the daemon stage, wired

Date: 2026-11-13. Stage after `daemon-wiring.md` (§2 command block, §4 staging
channels, §5.1 ordering hazard), `sacdread-stage-plan.md` (§5 fire block, §4.1
INIT success value), `read10-orchestration.md` (§6.2 ODD stack) and
`probe-injection.md` (the flag-render + intent-echo pattern). Integrates the four
landed decode docs into `tools/bx510_bdpdrv_stub_probe.py`.

**House rules.** **VERIFIED** = a command in §5 produced it, or it is read out of
an instruction / a run already in evidence. **INFERRED** = reasoned, labelled.
**COMPUTED** = the probe's own `--print-commands` output (the fire's real
arithmetic), not an estimate.

---

## 0. Bottom line

1. **Three stages are now flags, and the unflagged path is byte-identical to
   C100/C101.** The default render is 43 guest command lines and a 634,880 B
   payload — the same two numbers C101 recorded (`payload_size` in
   `bdpdrv-runC101.meta.json`). Proven twice in §5: the new script's default
   render, and a control that ran the **pre-edit** script (git HEAD) through a
   fake qemu and diffed the command lists (identical, 43/43). *VERIFIED.*
2. **`--odd-tail` is a flag, default OFF.** `cdrom.ko`, `sr_mod.ko` and
   `mknod /dev/sr0 b 11 0` cost nothing in the payload (both modules are already
   in the guest rootfs) and 6 command lines. *VERIFIED — the guest paths are
   pinned to a prior run's BDP dirent listing (§1.1).*
3. **`--sacdread` stages the module + the smoke script and derives
   `SACDREAD_INIT=<val>` from the smoke script's own S07 gate line — it does not
   re-fire INIT.** A second INIT would hit the compid slot S10 re-connected and
   return `0xE8000006`, which would make a passing stage look failed. The
   expected success value `0x68000000` (= 1744830464) is echoed as
   `SACDREAD_INIT_EXPECT=` and the extraction was validated in all three
   directions (pass / helper-missing / busy-slot) (§5.3). *VERIFIED.*
4. **`--daemon` is `daemon-wiring.md` §2, line for line, through the nested
   `.tgz` channel** — with one deliberate difference: §2's three ODD-tail lines
   are **not** repeated inside the daemon block, because they are the
   `--odd-tail` stage (§6.1). Everything else (labels included: `TMPTMP`,
   `DAEMON_TGZ`, `DAEMON_MD5`, `GATE_UNINIT`, `PRE_RMMOD`, `PRE_RMNODE`,
   `DAEMON_PID`, `DAEMON_SLEPT`, `DAEMON_PS/MISC/MOD/OUT/ORACLE`,
   `DAEMON_STAGE_DONE`) is §2 verbatim.
5. **Budget verdict: every combination fits, and the worst case is 55,296 B
   from the ceiling.** All four stages together: **993,280 B of 1,048,576
   (94.7 %)**. `--daemon` alone lands on **839,680 B — exactly §4.3's number**,
   which is an independent confirmation of that doc's arithmetic. *COMPUTED.*
6. **`--print-commands` is the dry run**: it builds the payload (so the budget is
   real), renders the command list and the member sizes, and returns before QEMU
   is even resolved. The over-budget guard now fails with the numbers instead of
   a bare refusal (§5.4). *VERIFIED.*

---

## 1. The flags

| flag | value | default | what it does |
|---|---|---|---|
| `--odd-tail` | — | **off** | 6 guest lines after the CLI probes: `insmod /lib/modules/2.6.35/BDP/cdrom.ko`, `insmod …/sr_mod.ko`, `mknod /dev/sr0 b 11 0`, `ls -l /dev/sr0`, wrapped in `ODD_TAIL_BEGIN`/`ODD_TAIL_DONE` |
| `--sacdread` | host path to `sacd_read.ko` | none = stage dark | stages `shim/sacd_read.ko` and emits the smoke stage (7 lines) |
| `--sacdread-smoke` | host path to `decode/sacdread_smoke.sh` | none; **required by `--sacdread`** | stages `shim/sacdread_smoke.sh` — the script that owns insmod/mknod/rmmod and the INIT-before-AUTH/UNINIT ordering rule |
| `--sacdgate` | host path to the ARM `sacdgate` helper | none; **required by `--sacdread`** | stages `shim/sacdgate` (the helper `sacdread_smoke.sh` drives; `--daemon` gets its own copy inside the tgz) |
| `--sacd-auth` | `0` \| `1` | `1` | `AUTH=` on the smoke-script line. `0` skips S08, which runs bdpdrv's whole SACD bring-up self-test and costs up to ~35 s when `/dev/sr0` exists but answers nothing (`sacdread-stage-plan.md` §3.5) |
| `--daemon` | host path to the prebuilt payload `.tgz` | none = stage dark | stages `shim/daemon_payload.tgz` and emits the daemon stage (17 lines) |
| `--print-commands` | — | off | dry run: render the command list + budget, exit without QEMU |

Everything the probe already had (`--stubko`, `--stuba-ko`, `--pre-file`,
`--extra-file`, `--clidrive-mode`, `--fatb-fixture`, `--kscript`, …) is
unchanged, and a fire that passes none of the six new flags renders the C100/C101
command list byte for byte.

Every flag also lands in `meta.json` under a new `stages` key (`odd_tail`,
`sacdread.{host_path,sha256,size,smoke_sha256,auth,init_ok_value}`,
`daemon.{host_path,sha256,size}`) so the bundle is self-describing without the
fire line being remembered — `probe-injection.md`'s design note, applied to the
new stages.

### 1.1 The ODD module paths are not guessed

`daemon-wiring.md` §2 writes `/lib/modules/2.6.35/BDP/`, and this pass found the
dirent listing that proves it (`evidence/bx510-guest/artifacts/p0v33-uart.log`,
a `ls -l /lib/modules/2.6.35/BDP/` from an earlier run):

```
-rw-rw-r--  1 0 0    85276 Sep 20  2018 cdrom.ko
-rw-rw-r--  1 0 0    34944 Sep 20  2018 sr_mod.ko
-rw-rw-r--  1 0 0  8122068 Sep 20  2018 bdpdrv.ko
-rw-rw-r--  1 0 0    34760 Sep 20  2018 drvcli.ko
```

So the tail is **wiring only** — nothing is staged, and `sr_mod.ko` registering
its SCSI driver *after* libata has enumerated the device (C101: `scsi 0:0:0:0:
CD-ROM`) is exactly the ordering that makes `sr0` attach.

---

## 2. Code map — what changed in `tools/bx510_bdpdrv_stub_probe.py`

| seam | shape |
|---|---|
| `SACDREAD_INIT_OK = "1744830464"` | module constant for `0x68000000`; the *positive* value, never 0 (`sacdread-stage-plan.md` §4.1) |
| `odd_tail_commands()` | the 6 ODD-tail lines |
| `sacdread_commands(auth)` | the 7 smoke-stage lines |
| `daemon_commands()` | the 17 daemon-stage lines |
| stage append | after `sleep 3; echo CLI_DRAIN2`, in fixed order `odd-tail → sacdread → daemon`, then the existing `echo STUB_DONE` + `poweroff` lines |
| `--print-commands` | after the payload/partition guard, before the temp dir: prints `stages:`, `payload:`, one `member` line per extra, then the numbered command list, then `return` |
| partition guard | now reports `payload N B does not fit fe_test_data M B (over by K B); records=[…]` |
| staging | `--sacdgate` / `--sacdread` (+ smoke script) / `--daemon` read into the same `extra` map `build_tar` already takes; `--sacdread` refuses to run without its two dependencies |
| `meta.json` | `stages` block (§1) |

Design constraint that fixes the **position** of the new blocks:
`emulator-kit/smoke.py` breaks the run the moment every wanted marker appears, and
`wanted` is `[b"STUB_DONE"]` — so every stage must be emitted **before**
`echo STUB_DONE`. Each block ends with its own `*_DONE` marker so a truncated
stage is visible in the transcript.

---

## 3. The command-list diffs, per combination

Rendered by `--print-commands` (§5.1). `@@` hunks are `diff -u` against the
combination named in each heading.

### 3.1 combo 1 — no stage flags (the C100/C101 command list)

43 lines; payload 634,880 B. **Identical to the pre-edit script's list** (§5.2).

### 3.2 combo 2 — `--odd-tail`

```diff
@@ -39,5 +39,11 @@   (after sleep 3; echo CLI_DRAIN2)
+echo ODD_TAIL_BEGIN
+insmod /lib/modules/2.6.35/BDP/cdrom.ko; echo CDROM_INSMOD=$?
+insmod /lib/modules/2.6.35/BDP/sr_mod.ko; echo SRMOD_INSMOD=$?
+mknod /dev/sr0 b 11 0; echo SR0_MKNOD=$?
+ls -l /dev/sr0; echo SR0_LS=$?
+echo ODD_TAIL_DONE
```

Payload unchanged at 634,880 B (nothing staged): the stage costs 6 command
lines and no bytes. This is the block `daemon-gate-experiments.md` gate 06 and
`read10-orchestration.md` §6.2 both require and the command list never had.

### 3.3 combo 3 — `--odd-tail --sacdread` (+ `--sacdgate`, `--sacdread-smoke`)

```diff
@@ -1,5 +1,5 @@
-/bin/dd if=/res/test-bdev bs=4096 count=155 2>/res/dd.err | /bin/tar -xf - -C /res
+/bin/dd if=/res/test-bdev bs=4096 count=195 2>/res/dd.err | /bin/tar -xf - -C /res
@@ -45,5 +45,12 @@   (after echo ODD_TAIL_DONE)
+echo SACDREAD_STAGE_BEGIN
+echo SACDREAD_INIT_EXPECT=1744830464
+ls -l /res/shim/sacd_read.ko; echo SACDREAD_LS=$?
+AUTH=1 sh /res/shim/sacdread_smoke.sh > /res/sacdread.smoke 2>&1; echo SACDREAD_SMOKE_RC=$?
+cat /res/sacdread.smoke; echo SACDREAD_SMOKE_OUT=$?
+V=$(sed -n '/^SMOKE S07 /s/.*result=\(-*[0-9][0-9]*\).*/\1/p' /res/sacdread.smoke); echo SACDREAD_INIT=${V:-NONE}
+echo SACDREAD_STAGE_END
```

Why this shape:

| line | why not something simpler |
|---|---|
| `SACDREAD_INIT_EXPECT=1744830464` | the intent echo `probe-injection.md` §1 established: without it, "INIT returned a different code" and "the stage never ran" look identical in the transcript |
| `sh … > /res/sacdread.smoke 2>&1` then `cat` | the stage emits ~12 `SMOKE` lines plus `[SACDREAD]` printk chatter from the stub's IRRC thread; a file keeps the gate lines contiguous for the marker extraction, and the `cat` still puts every byte in the UART transcript. `/res` is tmpfs, so the write cannot fail on the ro squashfs |
| `AUTH=1` rendered, not inherited | `--sacd-auth` is the speed knob for a pre-C102 rig (S08's TestPhy leg can burn ~35 s); the value the stage used is in the line AND in `meta.json` |
| `SACDREAD_INIT=${V:-NONE}` | **the requirement is "print `SACDREAD_INIT=<val>`", and this prints it even when S07 produced nothing.** The value comes from the smoke script's S07 gate line (`SMOKE S07 PASS sacd-init -- ret=0 result=1744830464 …`), i.e. the one place the INIT result already exists — `sed` is the same `result=` idiom `sacdread_smoke.sh`'s own `ioctl_run` uses. Re-firing INIT here instead would meet a slot that S10 re-connected and return `0xE8000006` — a passing stage would look broken |

The smoke script (S01–S12) does the rest: `insmod minor=201`, `mknod c 10 201`,
INIT, AUTH (gated on INIT), UNINIT, re-INIT (the decisive teardown proof),
`rmmod`. Its defaults already match this layout (`KO=/res/shim/sacd_read.ko`,
`HELPER=/res/shim/sacdgate`, `PROC=/proc`, `DEV=/dev/sacd_read`), so the fire
line needs no env prefix.

### 3.4 combo 4 — `--odd-tail --daemon`

```diff
@@ -1,5 +1,5 @@
-/bin/dd if=/res/test-bdev bs=4096 count=155 2>/res/dd.err | /bin/tar -xf - -C /res
+/bin/dd if=/res/test-bdev bs=4096 count=205 2>/res/dd.err | /bin/tar -xf - -C /res
@@ -45,5 +45,23 @@   (after echo ODD_TAIL_DONE)
+echo DAEMON_STAGE_BEGIN
+mount -t tmpfs tmpfs /tmp; echo TMPTMP=$?
+HOME=/; export HOME
+tar -xzf /res/shim/daemon_payload.tgz -C /res; echo DAEMON_TGZ=$?
+md5sum /res/shim/sacd_extract_160; echo DAEMON_MD5=$?
+sh /res/shim/daemon_gate.sh; echo DAEMON_GATE_RC=$?
+/res/shim/sacdgate 0x40105305 /dev/sacd_read; echo GATE_UNINIT=$?
+rmmod sacd_read; echo PRE_RMMOD=$?
+rm -f /dev/sacd_read; echo PRE_RMNODE=$?
+PATH=/sbin:/usr/sbin:/bin:/usr/bin; export PATH
+cd /res/shim; ./sacd_extract_160 -S </dev/null >/res/daemon.out 2>&1 & echo DAEMON_PID=$!
+sleep 6; echo DAEMON_SLEPT=$?
+ps | grep sacd_extract; echo DAEMON_PS=$?
+cat /res/proc/misc; echo DAEMON_MISC=$?
+grep -c sacd_read /res/proc/modules; echo DAEMON_MOD=$?
+cat /res/daemon.out; echo DAEMON_OUT=$?
+grep -q 'SACD Daemon 0.37 active' /res/daemon.out; echo DAEMON_ORACLE=$?
+echo DAEMON_STAGE_DONE
```

Line-by-line this is `daemon-wiring.md` §2 minus its three ODD-tail lines (see
§6.1). The expected in-guest identities are `md5sum` **49107e9625e8cd27232e39
5787c46fe2** (`sacd_extract_160`, 350,830 B, sha256 `0fdcefdb…`) and
`DAEMON_ORACLE=0`; `Tray is empty` in `daemon.out` is the **correct** pre-disc
output, not a failure. `GATE_UNINIT` is the §5.1 marker: gate 12's `0x40105301`
owns `_au4CpsaInst[0]` in bdpdrv's `.bss` (rmmod does not free it), so without
the explicit `0x40105305` the daemon's first `DISC_OPEN` gets `0xE8000006` — and
`DAEMON_ORACLE` would still pass, which is why that failure is invisible without
this marker.

### 3.5 combo 5 — all four (`--odd-tail --sacdread … --daemon …`)

The union, in the fixed order `odd-tail → sacdread → daemon`; 74 command lines.
Ordering matters in one direction only: `sr0` must exist before
`daemon_gate.sh`'s gate 06 and before the daemon's `DISC_OPEN`. The reverse
interaction is covered without extra lines: a `--sacdread` stage leaves the
compid slot owned (its S10 re-INITs and never un-inits), and the daemon stage's
own `sacdgate 0x40105305` line releases it — the §5.1 hazard and the sacd_read
hand-off are the same release. A failing `PRE_RMMOD` (`rmmod: not found`) in this
combination is expected: the smoke script's S12 already removed the module.

---

## 4. Staging budget

### 4.1 Member arithmetic (USTAR via `build_tar`, 512-B header + data rounded up)

| member | bytes | tar cost |
|---|---|---|
| `shim/osal_stub.ko` | 220,658 | 221,184 |
| `shim/osal_stub_a.ko` | 50,539 | 51,200 |
| `shim/kcheck.sh` | 5,932 | 6,656 |
| `shim/procc.sh` | 936 | 1,536 |
| `shim/bx510_feboot.ko` | 55,187 | 55,808 |
| `shim/bx510_clidrive.ko` | 28,510 | 29,184 |
| `shim/libata.ko` | 193,620 | 194,560 |
| `shim/sata_mt85xx_mod.ko` | 69,452 | 70,144 |
| **8-member sum** | | **630,272** |
| end-of-archive | | 1,024 |
| **payload (padded to 10,240)** | | **634,880** = C101's `payload_size` |

Stage adds: `sacdgate` 38,710 → 39,424 · `sacd_read.ko` 97,805 → 98,816 ·
`sacdread_smoke.sh` 18,659 → 19,456 · `daemon_payload.tgz` 198,324 → 199,168.

### 4.2 Per-combination result (COMPUTED — the probe's own budget line)

| combo | flags | payload | free | members | `dd count` | cmds |
|---|---|---|---|---|---|---|
| 1 | *(none)* | **634,880** | 413,696 | 8 | 155 | 43 |
| 2 | `--odd-tail` | **634,880** | 413,696 | 8 | 155 | 49 |
| 3 | + `--sacdread` | **798,720** | 249,856 | 11 | 195 | 56 |
| 4 | + `--daemon` | **839,680** | 208,896 | 9 | 205 | 67 |
| 5 | all four | **993,280** | **55,296** | 12 | 243 | 74 |

Ceiling: `fe_test_data` = 1,048,576 B (`/tmp/images-fe/manifest.json`, offset
0xe00000). **Verdict: every combination fits; the worst case leaves 55,296 B
(5.3 %).**

Two cross-checks worth keeping:

* **combo 1 = 634,880 reproduces the recorded C101 `payload_size` exactly**, so
  the stand-in file set used for the dry run (§5.1) is byte-faithful to the fire.
* **combo 4 = 839,680 is `daemon-wiring.md` §4.3's number.** That doc derived it
  from `tar -cf` on the VM; the probe now derives it from `build_tar` itself.
  Agreement here means the `.tgz` channel's size claim is independently confirmed.

### 4.3 The new loud guard (task item 3)

An over-budget payload no longer dies with `payload does not fit fe_test_data`:

```
$ … --daemon /tmp/dry/oversize.tgz (a 430,000 B stand-in) --print-commands
payload 1064960 B does not fit fe_test_data 1048576 B (over by 16384 B);
records=[] — shrink a stage or move its files to the nested-tgz channel
(decode/daemon-wiring.md §4.2)
rc=1
```

---

## 5. Validation performed (no emulator fire, nothing destructive)

Everything below ran on the Mac against the tracked script. The VM-built modules
(`osal_stub*`, `libata`, `sata_mt85xx_mod`, `feboot`, `clidrive`, `sacdgate`)
were replaced by **byte-size stand-ins** whose sizes are taken from the C101 meta
and `daemon-wiring.md` §4.1 — the control in §5.2 shows that substitution is
faithful (it reproduces C101's payload exactly). The real tracked artifacts used
where they exist: `original/sacd_read.ko` (97,805), `original/sacd_extract_160`
(350,830), `decode/daemon_gate.sh` (19,080), `decode/sacdread_smoke.sh` (18,659),
`tools/kcheck.sh` (5,932).

### 5.1 The four combinations render

```sh
python3 /tmp/dry_setup.py      # size-matched stand-ins + a minimal images/ manifest
python3 /tmp/dry_tgz.py        # the §4.3 tgz recipe: 4 files, raw sum 506,425 B
PYTHONPATH=emulator-kit sh /tmp/dry_run.sh
```

```
combo1-default.txt   payload: 634880 B of 1048576 B (413696 B free), dd count=155 x 4096 B, 8 tar members
combo2-odd-tail.txt  payload: 634880 B of 1048576 B (413696 B free), dd count=155 x 4096 B, 8 tar members
combo3-sacdread.txt  payload: 798720 B of 1048576 B (249856 B free), dd count=195 x 4096 B, 11 tar members
combo4-daemon.txt    payload: 839680 B of 1048576 B (208896 B free), dd count=205 x 4096 B, 9 tar members
combo5-all.txt       payload: 993280 B of 1048576 B (55296 B free),  dd count=243 x 4096 B, 12 tar members
command counts: 43 / 49 / 56 / 67 / 74
```

The last combo's full header + member listing, copied from the same output (the
`.tgz` rides as one member — no `build_tar` change):

```
stages: odd_tail=True sacdread=sacd_read.ko sacd_auth=1 daemon=daemon_payload_198324.tgz
payload: 993280 B of 1048576 B (55296 B free), dd count=243 x 4096 B, 12 tar members
  member shim/kcheck.sh 5932 B
  member shim/procc.sh 936 B
  member shim/bx510_feboot.ko 55187 B
  member shim/bx510_clidrive.ko 28510 B
  member shim/libata.ko 193620 B
  member shim/sata_mt85xx_mod.ko 69452 B
  member shim/sacdgate 38710 B
  member shim/sacd_read.ko 97805 B
  member shim/sacdread_smoke.sh 18659 B
  member shim/daemon_payload.tgz 198324 B
```

(the two unconditional members, `shim/osal_stub.ko` and `shim/osal_stub_a.ko`,
are added by `build_tar` itself and are the `+2` in the member count)

The dry run is side-effect free: `--qemu /tmp/dry/no-qemu-in-dry-run` does not
exist and the run still succeeds (QEMU is never resolved), and no `--meta` /
`--uart` / `--unimp` file is created.

### 5.2 Control — the unflagged path is byte-identical to the pre-edit script

A gate that cannot fail is not a gate, so the comparison was made against the
**git HEAD** version of the probe, driven through a fake qemu (a shell script
that prints `/ # ` prompts and records the command lines the probe sends), i.e.
the pre-edit command list as it would actually have been typed into the guest:

```sh
git show HEAD:tools/bx510_bdpdrv_stub_probe.py > /tmp/head/probe_head.py
cp tools/kcheck.sh /tmp/head/                       # kscript default is __file__-relative
FAKEQEMU_RECORD=/tmp/head/head_cmds.txt PYTHONPATH=emulator-kit \
  python3 /tmp/head/probe_head.py --qemu /tmp/head/fakeqemu --images /tmp/dry/images …
python3 -c "import json;print(json.load(open('/tmp/head/h.meta.json'))['fe_test_data']['payload_size'])"
diff -u /tmp/head/head_cmds.txt <(new render of combo 1)
```

```
HEAD payload_size = 634880
BYTE-COMPAT: default command list identical to HEAD (43 lines)
```

(43 = the whole list including `echo STUB_DONE` and `poweroff`; the first attempt
of this control differed by one `dd count=` digit because the HEAD copy had no
`kcheck.sh` next to it — the harness was fixed, not the script, and the mismatch
is recorded here because a control that had to be corrected is worth knowing
about.)

### 5.3 The `SACDREAD_INIT` extraction, three directions

The rendered guest line was run against synthetic smoke output under `sh`:

| fixture | result |
|---|---|
| S07 PASS `result=1744830464` (plus S08/S09/S10 lines that also carry `result=`) | `SACDREAD_INIT=1744830464` ✓ — the `/^SMOKE S07 /` address is what keeps S08/S09/S10 out |
| S07 SKIP (helper missing, no `result=` field) | `SACDREAD_INIT=NONE` ✓ — absence is never silent |
| S07 FAIL `result=-402653178` | `SACDREAD_INIT=-402653178` ✓ — the negative CPSA code (`0xE8000006`, slot busy) survives verbatim |

Expected value cross-check: `0x68000000` = 1744830464, echoed as
`SACDREAD_INIT_EXPECT=`; the smoke script itself asserts `result >= 0` and
annotates a positive-but-different code.

### 5.4 Guards fire loudly (both negative controls)

```
$ … --sacdread original/sacd_read.ko --print-commands      (no --sacdgate/--sacdread-smoke)
--sacdread needs --sacdgate, --sacdread-smoke: the INIT proof runs through the
sacdgate helper, and the smoke script is the only place the INIT-before-AUTH/
UNINIT ordering rule lives
rc=1

$ … --daemon <430,000 B tgz> --print-commands
payload 1064960 B does not fit fe_test_data 1048576 B (over by 16384 B); …
rc=1
```

### 5.5 Syntax / help / suite gates

```sh
python3 -m py_compile tools/bx510_bdpdrv_stub_probe.py     # OK
python3 tools/bx510_bdpdrv_stub_probe.py --help            # new flags present, exit 0
uv run pytest -m "not smoke" -q                            # 18 passed
```

### 5.6 Identity of the artifacts the stages consume (re-checked Mac-side)

| artifact | identity | matches |
|---|---|---|
| `original/sacd_extract_160` | 350,830 B, sha256 `0fdcefdb84ae…`, md5 `49107e9625e8cd27232e395787c46fe2` | `daemon-wiring.md` §8 ✓ |
| `original/sacd_read.ko` | 97,805 B, sha256 `b3d7a383e45d…` | `sacdread-stage-plan.md` §1.1 ✓ |
| the 4-file tgz built from them | raw sum 506,425 B; `.tgz` 180,624 B **with a zero stand-in for `sacdgate`** (the real helper is VM-built and compresses differently) | `daemon-wiring.md` §4.3's 198,324 B is the real-helper number; the budget rows in §4.2 use a size-matched 198,324 B copy, labelled as such |

---

## 6. Deviations from the source docs (and why)

### 6.1 The ODD tail is its own stage, not part of `--daemon`

`daemon-wiring.md` §2 places the three ODD-tail lines inside the daemon block.
This pass keeps them as `--odd-tail` because (a) the task's contract says the
tail must be independently flaggable and off by default, and (b) the C103 ladder
(`read10-orchestration.md` §6.2) needs `sr0` with **no** daemon stage at all.
The daemon block therefore assumes `--odd-tail` has run: **firing `--daemon`
without `--odd-tail` is legal but gate 06 will FAIL** (no `/dev/sr0`), and the
daemon will still reach `DAEMON_ORACLE=0` with `Tray is empty` — a red gate, not
a broken stage. `--print-commands` records which stages were requested, so the
combination is never ambiguous after the fact.

### 6.2 `--sacdread` derives the marker instead of firing a second INIT

Covered in §3.3: a second INIT would collide with the compid slot the smoke
script's S10 re-connects, so `SACDREAD_INIT` is lifted from S07's own output.
The alternative (INIT first, smoke script second) inverts the ordering-safety
rule and fails S07 — `sacdread-stage-plan.md` §3.4.

### 6.3 `sacd_read.ko` and the smoke script cost more than §1.2's 774,144 B

`sacdread-stage-plan.md` §1.2 budgets the two files it knew about (module +
helper) and adds the end-of-archive twice; this stage also stages the 18,659 B
smoke script. COMPUTED value with the real file set: **798,720 B**, not 774,144
— 249,856 B free, so the doc's *verdict* ("fits with ~274 KB to spare") holds;
only the number moved. The two-file-only render (no smoke script) is 778,240 B.

### 6.4 `--sacd-auth` exists

`sacdread-stage-plan.md` §5 proposed exactly this flag; it is rendered into the
guest line (`AUTH=1`) and recorded in `meta.json`, because the S08 leg's ~35 s
cost has to be controllable from the fire line and not from an edit.

### 6.5 The `.tgz` is an input, not something the probe builds

The probe takes a prebuilt `--daemon <tgz>` and pins its sha256 in the meta; the
build recipe stays `daemon-wiring.md` §4.3 (it needs the VM-built `sacdgate`,
which is not in this repo). The in-guest `md5sum` line is the identity check on
the extracted daemon.

---

## 7. Fire lines

Base (unchanged from `probe-injection.md` §3), then add stages as needed. Stage
inputs on the VM: `~/sacd-verify/original/sacd_read.ko`, `/tmp/sacdgate`
(rebuilt per session — `md5 e03244f71233231919f2422ec0f16538`), the smoke script
staged with `make vm-stage-file FILE=evidence/bx510-guest/bdpdrv/decode/sacdread_smoke.sh`,
and the tgz built with the §4.3 snippet.

```sh
# C102 — ODD tail + sacd_read smoke (the cheap, hardware-free half)
  --odd-tail \
  --sacdread /home/aftermath/sacd-verify/original/sacd_read.ko \
  --sacdgate /tmp/sacdgate \
  --sacdread-smoke /tmp/sacdread_smoke.sh \
  --sacd-auth 0 \
  --timeout 300

# C103 — the daemon stage on top (gate 14 / 5305 hazard wired)
  --odd-tail \
  --daemon /tmp/bx510-daemon-payload.tgz \
  --timeout 300
```

`--timeout 300` is not negotiable (`daemon-wiring.md` §2: gate 10 alone polls
`_IDECLI_OddTestUnitReadyLoop(20000)` for 20 s, gates 11/12 sit on the driver's
10 s timeout, and the daemon stage adds a 6 s sleep — worst case ≈ 45 s of gate
plus the smoke stage's own ~40 s when `AUTH=1`). Add a pre-fire
`--print-commands` run with the same flags: it costs a second and proves the
payload and command list before the box is spent.

Verdict greps (transcript markers, anchored — the guest echoes every command it
is sent, so an unanchored count doubles):

```sh
grep -c  '^CDROM_INSMOD=0$'   uart    # ODD tail loaded
grep -c  '^SRMOD_INSMOD=0$'   uart
grep -c  '^SR0_MKNOD=0$'      uart
grep     '^SACDREAD_INIT='    uart    # want 1744830464; NONE = S07 produced no result
grep -c  '^SMOKE_VERDICT='    uart    # PASS | INCOMPLETE | FAIL, then read SMOKE_FAIL
grep -c  '^TMPTMP=0$'         uart    # daemon stage
grep -c  '^DAEMON_TGZ=0$'     uart
grep     '^49107e9625e8cd27232e395787c46fe2' uart   # the staged daemon's md5
grep -c  '^GATE_UNINIT=0$'    uart    # the §5.1 release happened
grep -c  '^DAEMON_ORACLE=0$'  uart    # D-1 proved: install_modules + server_loop
```

---

## 8. Residual risks / open questions for the parent

1. **combo 5 leaves 55,296 B.** Any further stage must go through the same
   nested-tgz trick (or displace a member). The next candidate
   (`srread` + `sr_read_ladder.sh` from `read10-orchestration.md` §6.1) is small,
   but the margin is now one 10,240-B tar block plus 45 KB — check with
   `--print-commands` before firing.
2. **`tools/procc.sh` is not in this repo** (the fire's copy lives next to the
   probe on the VM). A Mac-side `--print-commands` therefore renders a 0-byte
   `shim/procc.sh` and a payload one 10,240-B block smaller unless `--kscript`
   points at a directory that has both scripts. All §4.2 numbers were produced
   with the faithful pair (real `kcheck.sh` + a 936-B `procc.sh`).
3. **Nothing here has been fired.** The guest-side questions the docs already
   flag stay open: does `sr_mod.ko` attach `sr0` at all (C102), does gate 06
   pass, does `SACDREAD_INIT` come back `1744830464`, does `install_modules()`
   succeed inside the guest. Each has its own marker so a partial run is
   diagnosable without the parent guessing.
4. **Gate verdict pre-C102 is `INCOMPLETE` by design** (gates 10-14 need a disc
   and a model that answers TUR/profile) — `DAEMON_GATE_RC` and the summary block
   will say so; do not read it as a wiring failure.
5. **`--sacd-auth 1` + `--odd-tail` costs ~35 s** of guest time when `sr0` exists
   but the model answers nothing (TestPhy's TUR loop + PSP/PDM wait). Use
   `--sacd-auth 0` for the first C102 pass and re-run with `1` once the model
   answers.
6. **The `--daemon` path trusts the tgz's contents.** The probe pins the tgz's
   sha256 in the meta and the stage md5sums the extracted daemon in-transcript;
   a mis-built tgz (missing `sacdgate`, wrong modes) shows up as `DAEMON_TGZ≠0`
   or a `GATE_UNINIT≠0` plus `sacdgate: not found`, not silently.
