# The daemon stage of the C-run — wiring `sacd_extract_160` as the last stage

Date: 2026-11-13. Stage after `daemon-gate-experiments.md` (the 14-gate script,
the ioctl helper, the fire command block) and `daemon-ioctl-side.md` §3
(boot order) — this document **extends** both and re-derives nothing about the
daemon's own code except the four places where the wiring depends on it
(argv surface, launch discipline, staging size, and one ordering hazard the
gate script creates).

**Status: READY-but-gated, nothing applied.** No file under `tools/` or
`emulator-kit/` was touched. The block in §2 is a *proposed* command-list
insert; the parent owns the fire script. Every number below was measured on
the lab VM this stage (§6) except where marked VERIFIED-from-decode.

**House rules.** **VERIFIED** = read out of an instruction / literal / a run
already in evidence / a measurement in §6. **INFERRED** = reasoned, labelled.

---

## 0. Bottom line

1. **Two assumptions in the stage brief do not survive the binary.** The daemon
   has **no device, model or port argv**: its option surface is
   `getopt_long("2mepsSIcCi:t:P?", …)` plus `--usage`, and `--device` is
   rejected at runtime (`unrecognized option '--device'` + usage, §6 test 2a).
   `/dev/sacd_read`, `/dev/sr0` and port 2002 are hard-coded. The launch line is
   therefore **`-S` and nothing else**, with stdin redirected.
2. **The daemon does not fit the current staging channel.** Current payload
   = 634,880 B of a 1,048,576-B `fe_test_data` partition. Adding the four
   daemon-stage files (daemon 350,830 + `sacd_read.ko` 97,805 + helper 38,710 +
   gate 19,080 = 506,425 raw) makes the tar **1,146,880 B — 98,304 B over the
   partition**. No combination of "drop a module" fixes it without gutting the
   run (`-clidrive -feboot -kcheck -procc` still leaves it 6,144 B over). The
   stage therefore needs a **second staging channel**, and the cheap one is a
   **nested `.tgz` (198,324 B) extracted guest-side by the guest's own busybox
   `tar -z`,** which this stage validated end-to-end (§4). No Python change
   needed: it travels as one more `--extra-file`.
3. **The gate must run before the daemon and must release the CPSA instance
   afterwards.** Gate 12 issues `0x40105301` = `CPSA_SACDCmdEnable` →
   `i4CPSA_Inst_Connect`, which **owns `_au4CpsaInst[compid]`**; none of the 14
   gates issues `0x40105305` (uninit), and the daemon's own first `DISC_OPEN`
   calls the same `Connect` — which asserts and returns `0xE8000006` on a busy
   slot. So a full gate run followed by a daemon run in the same boot turns
   into `libsacdread: Can't open /dev/sr0 for reading` unless one
   `sacdgate 0x40105305` line separates them. **This is the one ordering hazard
   the wiring must carry** (§5.1), and the helper already supports 5305.
4. **`/tmp` is not in the rootfs squashfs and `/` is squashfs-ro**, and
   `install_modules()` writes the embedded 97,805-B `sacd_read.ko` to
   `/tmp/XXXXXX`. The C-run has never mounted `/tmp`; the daemon stage must
   (`mount -t tmpfs tmpfs /tmp`, exactly the proven `/dev` idiom — `/tmp`
   exists in the *runtime* root, C101 `ROOTLIST`).
5. **The ODD tail is missing from the command list.** `cdrom.ko`, `sr_mod.ko`
   and `mknod /dev/sr0 b 11 0` appear nowhere in
   `tools/bx510_bdpdrv_stub_probe.py`; without them gate 06/10/11/13 cannot
   pass regardless of the model. They are wiring, cheap, and included below —
   but **the gates stay red until C102 answers TUR/profile**, which is not this
   stage's work.
6. **What the daemon needs at startup is not copy-protection state.** No EKB,
   no key material, no GCPU: `_SACDCLI_FindTag`/`vEkbInit`/`bEkbParseTagKey` are
   never called by `sacd_read.ko`, and AUTH (`0x40105302`) only stores
   `fgEnable` and returns `0x68000000` (§5.2). The `key_block_1/2` NAND
   partitions exist in the image and are empty — and never consulted on this
   path.
7. **The first-prints oracle is a single flush-per-second line**,
   `\rSACD Daemon 0.37 active. Client none. Tray is empty.` + 14 spaces
   (`safe_fwprintf` does `vfwprintf`+`fflush`, VERIFIED `0xd638`/`0xd648`), so a
   file capture of the daemon's stdout is reliable and greppable (§3.1). Its
   absence means `install_modules()` failed, and that path's exact console text
   was reproduced this stage: `[0]: install_modules: mknod/insmod filed` then
   `[0]: Can not install modules` (§3.2).

---

## 1. What the fire script must already have (not part of this block)

From `daemon-gate-experiments.md` §4 gates 01-06, all **already in**
`tools/bx510_bdpdrv_stub_probe.py` except the ODD tail:

| need | where it comes from today |
|---|---|
| `/res` tmpfs + tar extraction | command list lines 142-145 |
| `/proc` | `mount -t proc proc /res/proc` (line 155) **and** `mount -t proc proc /proc` (line 162, `ROOTPROC=0` in C101) — so the gate's default `PROC=/proc` works, no override needed |
| `/dev` tmpfs + `console`/`null`/`ttyMT0` | lines 167-168 |
| `osal_stub_a` → `drvcli` → `osal_stub` → `feboot` → `bdpdrv` (gate 04/05) | lines 176-181 |
| real SATA stack (`--pre-file libata.ko`, `sata_mt85xx_mod.ko`) | `pre_files` loop, line 174-175 |
| **`cdrom.ko`, `sr_mod.ko`, `mknod /dev/sr0 b 11 0` (gate 06)** | **absent — added by §2** |
| `insmod`/`rmmod`/`mknod` resolvable in the shell PATH (gate 03) | VERIFIED present: `/sbin/insmod`, `/sbin/rmmod`, `/bin/mknod`, all BusyBox v1.17.2 applet hard-links; C101 shows `STUBA_INSMOD=0`, `BDPDRV_INSMOD=0`, i.e. PATH lookup already works |

---

## 2. The command-list block (proposed; NOT applied)

Insert **after line 213** (`"sleep 3; echo CLI_DRAIN2",`) and **before**
`"echo STUB_DONE",` (line 214). Two constraints force that position:

* `emulator-kit/smoke.py:63` breaks the whole run as soon as **every** marker in
  `wanted` is in the transcript, so anything *after* `echo STUB_DONE` never
  executes. `wanted` stays `[b"STUB_DONE"]`; the last line of this block is
  `echo DAEMON_STAGE_DONE` so the transcript still proves the stage ran.
* Every line is short on purpose (the C43 "long one-liners get truncated by the
  guest shell" lesson); the launch line is the only >80-char one and is the
  same shape as the existing 130-char CLI line that works.

```diff
--- a/tools/bx510_bdpdrv_stub_probe.py
+++ b/tools/bx510_bdpdrv_stub_probe.py
@@ -213,6 +213,30 @@
         "sleep 3; echo CLI_DRAIN2",
+        # ── DAEMON STAGE (decode/daemon-wiring.md) ────────────────────
+        # /tmp: absent from the rootfs squashfs and / is squashfs-ro; the
+        # daemon writes its embedded sacd_read.ko (97,805 B) there
+        # (daemon-ioctl-side.md §3.1, 0x2f9a4-0x2f9f4).
+        "mount -t tmpfs tmpfs /tmp; echo TMPTMP=$?",
+        "HOME=/; export HOME",
+        # second staging channel: the four daemon-stage files do not fit the
+        # fe_test_data tar uncompressed (daemon-wiring.md §4).
+        "tar -xzf /res/shim/daemon_payload.tgz -C /res; echo DAEMON_TGZ=$?",
+        "md5sum /res/shim/sacd_extract_160; echo DAEMON_MD5=$?",
+        # ODD tail (gate 06) — the command list has never loaded these
+        "insmod /lib/modules/2.6.35/BDP/cdrom.ko; echo CDROM_INSMOD=$?",
+        "insmod /lib/modules/2.6.35/BDP/sr_mod.ko; echo SRMOD_INSMOD=$?",
+        "mknod /dev/sr0 b 11 0; echo SR0_MKNOD=$?",
+        "ls -l /dev/sr0; echo SR0_LS=$?",
+        # gates 01-14 with the ioctl helper staged (10-14 need it)
+        "sh /res/shim/daemon_gate.sh; echo DAEMON_GATE_RC=$?",
+        # release what gate 12's 0x40105301 owns (see §5.1)
+        "/res/shim/sacdgate 0x40105305 /dev/sacd_read; echo GATE_UNINIT=$?",
+        # hand the INSTALL back to the daemon (D-1)
+        "rmmod sacd_read; echo PRE_RMMOD=$?",
+        "rm -f /dev/sacd_read; echo PRE_RMNODE=$?",
+        # the daemon: -S only; stdin NOT a tty or server_loop skips the disc
+        # poll AND redirects the log to /dev/null (daemon-ioctl-side.md §3.3)
+        "PATH=/sbin:/usr/sbin:/bin:/usr/bin; export PATH",
+        "cd /res/shim; ./sacd_extract_160 -S </dev/null >/res/daemon.out 2>&1 & echo DAEMON_PID=$!",
+        "sleep 6; echo DAEMON_SLEPT=$?",
+        "ps | grep sacd_extract; echo DAEMON_PS=$?",
+        "cat /res/proc/misc; echo DAEMON_MISC=$?",
+        "grep -c sacd_read /res/proc/modules; echo DAEMON_MOD=$?",
+        "cat /res/daemon.out; echo DAEMON_OUT=$?",
+        "grep -q 'SACD Daemon 0.37 active' /res/daemon.out; echo DAEMON_ORACLE=$?",
+        "echo DAEMON_STAGE_DONE",
         "echo STUB_DONE",
```

Fire-line side — **one** new staging flag (the other three files ride inside it):

```sh
  --extra-file daemon_payload.tgz=/tmp/bx510-daemon-payload.tgz \
```

Why each line, in order:

| line | gate / decode sentence it serves |
|---|---|
| `mount -t tmpfs tmpfs /tmp` | gate 02. `/tmp` exists at runtime (C101 `ROOTLIST`, mode 775, runtime mtime) but is **not in the rootfs squashfs** (`unsquashfs -l` top level = `bin lib res sbin usr` only) and `/` is `squashfs (ro)`. Same idiom as the proven `/dev` mount. If the mount is refused, `TMPTMP!=0` is the first thing to read. |
| `HOME=/; export HOME` | `daemon_gate.sh` runs under `set -u` and its `helper_missing_detail` reads `$HOME`; shell-mode `init=/bin/sh` has no `/etc/profile`, so `HOME` may be unset (observed as `daemon_gate.sh: line 338: HOME: parameter not set` in the §6 dry run). |
| `tar -xzf … -C /res` | §4 channel. Members are `shim/<name>`, so `-C /res`. Validated with the guest's own busybox (TAR_FILE_RC=0, mode 0755 preserved). |
| `md5sum /res/shim/sacd_extract_160` | pins the staged blob in-transcript: must print `49107e9625e8cd27232e395787c46fe2` (sha256 `0fdcefdb…`, 350,830 B). |
| `insmod …/cdrom.ko`, `sr_mod.ko`, `mknod /dev/sr0 b 11 0` | gate 06 (`daemon-gate-experiments.md` §4 row B tail; `odd-cb-agent.md` §3.2). |
| `sh /res/shim/daemon_gate.sh` | the 14 gates. Defaults already match this layout (`PROC=/proc`, `SR0=/dev/sr0`, `DEV=/dev/sacd_read`, `KO=/res/shim/sacd_read.ko`, `HELPER=/res/shim/sacdgate`) — no env prefix needed, which keeps the line short. **Expected verdict pre-disc: `INCOMPLETE`** (gate 13 needs a disc; 10/11/12 need the model) — that is by design, not a defect. |
| `sacdgate 0x40105305` | §5.1 hazard. `5305` is one of the five zero-payload commands the helper accepts (it refuses only 5303/5304). |
| `rmmod sacd_read; rm -f /dev/sacd_read` | hands `install_modules()` back to the daemon so D-1 is the *daemon's* install, not the gate's. **Safe if it fails**: the daemon's `mknod` returns EEXIST and its `insmod` prints `File exists`, but its acceptance test is the `open("/dev/sacd_read",0)` (`0x2fa34`), which still succeeds → the status line still appears. |
| launch line | `-S` server mode; no `-i` (it cannot redirect `DISC_OPEN`, which hard-codes `/dev/sr0` at `0xcc40`); stdin `/dev/null` so `validate_stdin()` returns −1 and the poll runs; stdout+stderr into `/res/daemon.out` (tmpfs) **and** the console via the later `cat`. |
| `sleep 6` | `server_loop` emits one line per second, so 6 s ≥ 6 records; also covers `install_modules`' 97,805-B write. |
| `ps`/`/proc/misc`/`/proc/modules` | positive liveness + the daemon's *own* install registering minor 201 (gate 08's second half, now attributable to the daemon). Caveat: `ps \| grep sacd_extract` can match the `grep` itself, so treat `DAEMON_PS` as a **hint** — the authoritative liveness signals are `DAEMON_ORACLE=0` plus a non-empty `/res/daemon.out` (each second appends ~75 B, `fflush`ed). |
| `cat /res/daemon.out` | puts the oracle bytes in the UART transcript even when stdout is a file. |
| `grep -q 'SACD Daemon 0.37 active'` | the machine-readable marker: `DAEMON_ORACLE=0` is the pass. `grep -c` would report **1** (the file is one line with embedded `\r`), so use `-q`, not a count. |

**Do not lower `--timeout 300`.** If the model never answers, gate 10 alone
polls `_IDECLI_OddTestUnitReadyLoop(20000)` for 20 s and gates 11/12 each sit
on the driver's 10 s timeout (`+0x24 = 0x2710`) — worst case ≈ 45 s of gate plus
the 6 s sleep.

---

## 3. The oracle

### 3.1 Happy path — the exact bytes

`server_loop` `0xe1e4-0xe288`, format literal `0x31e68` (wide):

```
'\rSACD Daemon %ls active. Client %ls. %ls.' + 14 spaces
```

with `"0.37"` (`0x31f48`), `"connected"|"none"` (`0x31d70`/`0x31d98`), and
`"SACD disc inserted"|"Disc inserted"|"Tray is empty"`
(`0x31dac`/`0x31df8`/`0x31e30`). No trailing newline; `\r` + 14 spaces overwrite
in place, and `safe_fwprintf` `fflush`es every iteration
(`vfwprintf@0xd638`, `fflush@0xd648`), so the file is never stale.

Expected first 10 console lines for a **pre-disc** run (no disc model yet — the
C102-or-later state this wiring is built for):

```
/ # cd /res/shim; ./sacd_extract_160 -S </dev/null >/res/daemon.out 2>&1 & echo DAEMON_PID=$!
DAEMON_PID=57
DAEMON_SLEPT=0
  <pid> 0:00 sacd_extract_160            <- `ps` (busybox `ps` has no uid column)
DAEMON_PS=0
201 sacd_read                            <- /proc/misc: the DAEMON's insmod
DAEMON_MISC=0
1                                        <- grep -c sacd_read /proc/modules
DAEMON_MOD=0
\rSACD Daemon 0.37 active. Client none. Tray is empty.       (× 6, one per second)
DAEMON_OUT=0
DAEMON_ORACLE=0
```

`Tray is empty` is the **correct pre-disc output**: `disc_sacd() != 0` is the
daemon's own "no disc" reading, and it requires `0x40105306` to *answer* —
which is exactly what C102 owes. The three fields are mutually exclusive:

| third field | daemon predicate (VERIFIED) | gate |
|---|---|---|
| `Tray is empty` | `disc_sacd() != 0` (5306) | 10 red, model not answering / no media |
| `Disc inserted` | 5306 == 0, `sacd_sacd() < 0` (profile ≠ 0x10) | 11 red — present but not a SACD profile |
| `SACD disc inserted` | 5306 == 0, 5307 ≥ 0 | 11 green — **the endgame-ready line** |

### 3.2 Failure signatures, in the order the daemon reaches them

All strings VERIFIED from `daemon-ioctl-side.md` §5.1 / §3.2, except the two
marked ★ which were reproduced on this stage's VM run (§6 test 2c) — note the
`[0]: ` prefix the log layer adds, which the earlier doc quotes without it:

| where it dies | console/stderr text | `DAEMON_ORACLE` | first gate to read |
|---|---|---|---|
| `/tmp` unwritable | ★`[0]: install_modules: mknod/insmod filed` then ★`[0]: Can not install modules` | 1 | 02 |
| `mknod`/`insmod`/`rmmod` not in PATH | same two lines | 1 | 03 |
| `insmod` of the embedded copy fails (vermagic / unresolved `x_memset` / 13th symbol NULL) | `installing`… same two lines + busybox's `insmod: … Invalid module format` / `Unknown symbol` / `Bad address` | 1 | 05/08 |
| CPSA slot busy (`compid 0` owned by the gate's own 5301) | `insmod: … Device or resource busy`, then `[SACDREAD] compid = 0 is used. Try another.` → same two lines | 1 | **§5.1** |
| minor 201 taken by a stale instance | `<3>[SACDREAD]Unable to register misc device` | 1 | 08 |
| module never becomes `sacd_read` on 201, node opens but no driver | `[0]: … open filed` variants | 1 | 08/09 |
| daemon runs, no disc path | status line with `Tray is empty` | **0** | 10/11 (model) |
| `0x40105301` refused | stderr `libsacdread: Can't open /dev/sr0 for reading` on the first `DISC_OPEN`; status line **still** prints (`disc_sacd`/`sacd_sacd` do not need a session) | 0 | 12 |
| TOC leg | `libsacdread: Can't read Master TOC.` / `Not a ScarletBook disc!` | 0 | 13 |
| AUTH | `auth_sacd (%#x)` / `authentication failed: %x` (log level > 1 only) | 0 | 14 |

`DAEMON_ORACLE=0` therefore proves **D-1** only (`install_modules` returned 0 →
`server_loop` running). Everything after it is the disc lane. Do not read a
`Tray is empty` line as a pass for gates 10/13.

**Absence of output is not failure** (the launch-from-a-tty case): if
`DAEMON_OUT=0` but the file is empty/1-byte, suspect the tty guard — the
`</dev/null` is what keeps the poll alive.

---

## 4. Staging: sizes, arithmetic, and the second channel

### 4.1 What is in the payload today (measured, VM)

| file | bytes |
|---|---|
| `shim/osal_stub.ko` | 220,658 |
| `shim/osal_stub_a.ko` | 50,539 |
| `shim/sata_staging/libata.ko` | 193,620 |
| `shim/sata_staging/sata_mt85xx_mod.ko` | 69,452 |
| `shim/bx510_feboot.ko` | 55,187 |
| `shim/bx510_clidrive.ko` | 28,510 |
| `shim/kcheck.sh` + `shim/procc.sh` | 5,932 + 936 |
| **raw sum** | **624,834** |
| **tar (USTAR, `build_tar`)** | **634,880** = 62 × 10,240 — matches `payload_size` in `bdpdrv-runC99/C100/C101.meta.json` |
| partition `fe_test_data` (`/tmp/images-fe/manifest.json`) | **1,048,576** (offset `0xe00000`, `records: []`) |
| **free today** | **413,696** |

### 4.2 What the daemon stage adds — and why it does not fit

| new file | bytes | identity |
|---|---|---|
| `shim/sacd_extract_160` | **350,830** | sha256 `0fdcefdb84ae…`, md5 `49107e9625e8cd27232e395787c46fe2` (`~/sacd-verify/original/sacd_extract_160` on the VM == `original/sacd_extract_160` in the repo) |
| `shim/sacd_read.ko` | 97,805 | sha256 `b3d7a383…`, byte-identical to the blob embedded in the daemon |
| `shim/sacdgate` | 38,710 | built on the VM this stage with the era toolchain, md5 `e03244f71233231919f2422ec0f16538` (`~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -Wall -Wextra -std=gnu99`) |
| `shim/daemon_gate.sh` | 19,080 | landed last stage |

Full set raw = **1,131,259** → tar = **1,146,880** → **over the partition by
98,304 B**. Measured on the VM with `tar -cf` on the exact 12 files, so this is
not an estimate.

**And "drop something" does not rescue it.** The only droppable modules are the
CLI lane (`bx510_clidrive.ko`, 28,510) and the FE marshalling shim
(`bx510_feboot.ko`, 55,187) — and `kcheck.sh`/`procc.sh` are staged
unconditionally by `build_tar`. Dropping all four rebuilds the tar at
**1,054,720 B — still 6,144 B over**, and it would delete the CLI evidence and
the ioctl helper. Verdict: **uncompressed staging is not viable at all.**

### 4.3 The channel: one nested `.tgz` (recommended; validated)

Build (host side, deterministic — this is the exact recipe whose size is quoted):

```sh
# staging dir with the four files, modes 0755
mkdir -p /tmp/daemon-payload/shim && cd /tmp/daemon-payload/shim
cp ~/sacd-verify/original/sacd_extract_160 ~/sacd-verify/original/sacd_read.ko .
cp /tmp/sacdgate /tmp/daemon_gate.sh .
chmod 0755 *
python3 - <<'PY'
import io, pathlib, tarfile
root = pathlib.Path('/tmp/daemon-payload')
buf = io.BytesIO()
with tarfile.open(fileobj=buf, mode='w:gz', format=tarfile.USTAR_FORMAT) as arc:
    for p in sorted((root / 'shim').iterdir()):
        blob = p.read_bytes()                       # 350,830 B daemon included
        e = tarfile.TarInfo('shim/' + p.name)
        e.size, e.mode = len(blob), 0o755
        arc.addfile(e, io.BytesIO(blob))
pathlib.Path('/tmp/bx510-daemon-payload.tgz').write_bytes(buf.getvalue())
print(len(buf.getvalue()))
PY
# -> 198324
```

Payload after: **839,680 B** (one more USTAR member: `512 + 198,656` bytes of
entry, re-padded to a 10,240 multiple) → fits with **208,896 B (204 KB)**
head-room, and **zero changes to `build_tar`** (it is just another
`--extra-file`). The same arithmetic run against today's eight files
reproduces the meta's `payload_size` of 634,880 exactly, so the model is
faithful to `build_tar`.

Guest side: `tar -xzf /res/shim/daemon_payload.tgz -C /res; echo DAEMON_TGZ=$?`
(one line in §2).

**Validated this stage under the guest's own BusyBox** (`qemu-arm -L /tmp/rootfs
/tmp/rootfs/bin/tar`, §6 tests 1 and 3):

| check | result |
|---|---|
| `dd … bs=4096 count=49 \| tar -xzf - -C DIR` (the probe's pipe form) | `TAR_RC=0`, all four files extracted |
| `tar -xzf FILE -C DIR` (the nested-tgz form used above) | `TAR_FILE_RC=0` |
| extract modes | `-rwxr-xr-x` on all four |
| extracted daemon sha256 | `0fdcefdb84ae…` — byte-identical to the pinned ELF |
| `sh -n /res/shim/daemon_gate.sh` under busybox ash | `GATE_SYNTAX=0` |

Two rejected alternatives, for the record:

* **gzip the whole outer tar** (`mode="w:gz"` in `build_tar` + `tar -xzf -` in
  the guest): all twelve files = **449,759 B**, i.e. the most head-room of any
  option, and only two lines change. Held back because it rewrites the
  extraction path that C50-C101 all validated, for no benefit the nested tgz
  does not already deliver.
* **A second `fe_test_data` write after boot**: there is no host→guest write
  channel after boot, and the partition's page 0 is the FATB record the driver
  reads — a second stream would be at best a tail-offset blob (`skip=` dd), and
  the tail is 413,696 B, which does not hold daemon + module + helper + gate
  (506,425). Dead end at today's payload size; it would only work if the main
  tar also shrank.
* **HDHOST** (`docs/large-image-interface.md`) is the right channel for a
  multi-MiB blob, but it costs a whole rig lane (host-image interface plumbed
  into the C-run) for a 350 KB file, and `sacd-gate3` is the only thing that
  proves it. Over-engineering here.

---

## 5. The gating risks

### 5.1 The gate's own INIT poisons the daemon (measured-from-decode, highest risk)

```
sacdgate 0x40105301  -> CPSA_SACDCmdEnable(compid=0)
                     -> i4CPSA_Inst_Connect(0x16b, 0, 360, 0)     bdpdrv 0x559d8
                          *r4 = &_au4CpsaInst[0]; if (*r4 != -1) { Assert; return 0xE8000006 }
                                              else  { Create(...); *r4 = h; }
daemon DISC_OPEN     -> init_sacd() -> the same Connect with the same compid 0
```

`_au4CpsaInst[]` lives in **bdpdrv's** `.bss` (`.bss+0x11590`), not the module's
— so `rmmod sacd_read` does **not** free it. Nothing in the 14 gates issues
`0x40105305` (`CPSA_SACDCmdDisable` → `Disconnect`), so without an explicit
uninit the daemon's `DISC_OPEN` gets `0xE8000006`, `init_sacd()` returns < 0,
and `sacd_dev_input_open` returns NULL → `libsacdread: Can't open /dev/sr0 for
reading`. `DAEMON_ORACLE` still passes (the status line does not need a
session), so **this failure is invisible unless you look at `GATE_UNINIT` and
the `DISC_OPEN` result** — hence the explicit `sacdgate 0x40105305` line.

If the parent prefers the pre-disc split (gates 01-09 only, no ioctl at all),
the zero-edit form is one line:

```sh
"HELPER=/res/shim/no-such-helper; export HELPER",   # gates 10-14 -> SKIP
```

with `sh /res/shim/daemon_gate.sh` after it; gates 01-09 + 13 still run for
real, the verdict is `INCOMPLETE` (by design) and no `Connect` ever happens, so
no uninit is needed. Trade-off: gates 10/11 — the two cheapest proofs that the
ODD model answers at all — are skipped, and they are exactly the ones C102 will
make interesting.

### 5.2 `/dev/sr0` and copy-protection state: what is owed vs what exists

| what the daemon needs before the first *successful* `DISC_OPEN` | doc sentence | exists in the rig today? |
|---|---|---|
| `/dev/sr0` as a block node (11:0) that opens | gate 06; `client_thread 0xcc40`, `sacd_dev_input_open 0x21df8` | **no** — `cdrom.ko`/`sr_mod.ko`/`mknod` are absent from the command list (added by §2); enumeration itself is C96/C97 |
| TUR answering (`0x40105306`) | gate 10; `_IDECLI_OddTestUnitReadyLoop(20000)` | **no** — needs the model's media-present sense (SR-2) |
| profile `0x10` (`0x40105307`) | gate 11; `_IDECLI_OddGetProfile` | **no** — SR-3, the daemon's own disc gate |
| master TOC `"SACDMTOC"` at LBA 0x1FE ×10 (plain read, **no** `0x8530`) | gate 13 | **no** — needs a disc fixture / responder |
| `0x40105301` accepted (Connect + `CPSMode_Ctrl(…,0x40,TRUE)`) | gate 12 | needs bdpdrv's CPSA initialised — load order gives it; and see §5.1 |
| **EKB / key material / GCPU state** | — | **not needed at startup.** `vEkbInit`/`bEkbParseTagKey` hang off `_SACDCLI_FindTag`, which `sacd_read.ko` looks up and *never calls*; AUTH (`0x40105302`) only sets `fgEnable` in `ctx->byte[0x11]` and returns `0x68000000`. Key/GCPU work is only on `0x40105304` DECRYPT → `i4GCPU_CmdExec(0x806)` → `TzServiceCall` = D-7, explicitly out of scope. The `key_block_1`/`key_block_2` NAND partitions exist in `manifest.json` (1 MiB each, empty, `records: []`) and nothing on this path reads them. |

So the gating risk is a **disc/ODD** risk (C102+), not a copy-protection one.
The one thing this stage can bank before C102 is the module + `install_modules`
half, which is exactly what `DAEMON_ORACLE=0` proves.

### 5.3 Environment facts the wiring now depends on (all measured)

| fact | consequence |
|---|---|
| `/tmp` **not in** the rootfs squashfs (top level = `bin lib res sbin usr`), `/` is `squashfs (ro)` | §2's `mount -t tmpfs tmpfs /tmp` is mandatory, not defensive |
| `/dev`, `/proc`, `/sys`, `/tmp` **do** exist in the runtime root (C101 `ROOTLIST`, mode 775, runtime mtime) | the mount has a mount point; the same trick already works for `/dev` (`DEVTMP=0`) |
| `/proc` mounts at `/proc` (`ROOTPROC=0`, C101) | the gate's default `PROC=/proc` is right; no `/res/proc` override |
| `insmod`/`rmmod` live in `/sbin`, `mknod` in `/bin`, all BusyBox applet hard-links | the daemon's `system("insmod …")` inherits our PATH → §2 exports `/sbin:/usr/sbin:/bin:/usr/bin` explicitly |
| **`od`, `cut`, `wc`, `gzip`, `gunzip`, `zcat`, `cmp`, `tail`, `tr` are absent** from the guest; `printf` is an ash **builtin**; `awk`, `sed`, `dd`, `grep`, `head`, `hexdump`, `tee`, `ps`, `md5sum` are present | gate 13's `od`-formatted hex detail and gate 04's `cut` detail come out **empty** (decisions unaffected — 13 keys on `dd` + the 8 magic bytes, 04 on `grep -q`). `printf`-driven parsing works. Do not add a `gzip`-the-file step: the applet does not exist; only `tar -z` does. |
| `tar` supports `-z`/`-j` (`busybox tar` usage text, §6) | the §4 channel works |

---

## 6. Validation performed this stage (no emulator fire)

Everything below ran on the lab VM (`make vm-exec` / `make vm-script`) or on the
Mac against the tracked binaries; nothing was edited under `tools/` or
`emulator-kit/`.

| # | check | result |
|---|---|---|
| 1 | nested-tgz round trip, **pipe form**: `dd if=bdev bs=4096 count=49 \| busybox tar -xzf - -C DIR` (`qemu-arm -L /tmp/rootfs`) | `TAR_RC=0`; four files; `-rwxr-xr-x` |
| 2 | nested-tgz round trip, **file form**: `busybox tar -xzf FILE -C DIR` | `TAR_FILE_RC=0`; sha256 of the extracted daemon = `0fdcefdb84ae…` |
| 2a | daemon argv: `sacd_extract_160 --device /dev/sacd_read` under the guest libc | `unrecognized option '--device'` + `Usage: sacd_extract_160 [options] [outfile]` → **no device/model option exists** |
| 2b | `--usage` | prints the 8-option surface; matches `getopt_long("2mepsSIcCi:t:P?")` + `--usage` |
| 2c | `-S </dev/null` with no modules (deliberately broken env) | `[0]: install_modules: mknod/insmod filed` + `[0]: Can not install modules` — the D-1 failure text, with its `[0]: ` prefix |
| 3 | helper build, era toolchain: `arm-none-linux-gnueabi-gcc -O2 -Wall -Wextra -std=gnu99` | rc=0, `/tmp/sacdgate` = 38,710 B, md5 `e03244f71233231919f2422ec0f16538` |
| 4 | guest applet inventory (`[ -e /tmp/rootfs/{bin,usr/bin,sbin}/X ]`, plus `qemu-arm` runs) | the §5.3 row: `od/cut/wc/gzip/gunzip/zcat/cmp/tail/tr` absent, `printf` builtin, `tar -z`/`-j` present |
| 5 | `sh -n daemon_gate.sh` under the **guest's** busybox ash | `GATE_SYNTAX=0` |
| 6 | gate-script dry run under busybox ash with a fake procfs (modules/kallsyms/misc), fake helper, `DEV=/dev/null` | parsing + summary block behave (`GATE_N`, `GATE_VERDICT=FAIL` on the fake inputs); it surfaced the `HOME`-unset line under `set -u` (§2 line 2) |
| 7 | payload arithmetic: `tar -cf` the exact 12 files on the VM | 1,146,880 B vs partition 1,048,576 → **over by 98,304**; `gzip -9` of the same tar = 449,759 |
| 8 | the four-file tgz built with the §4.3 snippet + `build_tar` arithmetic replayed on the 9-file set | tgz 198,324 B → payload **839,680**, 208,896 B free |
| 9 | daemon/read.ko identity | `sacd_extract_160` sha256 `0fdcefdb…` / md5 `49107e96…` / 350,830 B; `sacd_read.ko` sha256 `b3d7a383…` / 97,805 B; VM copy == repo copy |
| 10 | `unsquashfs -l /tmp/rootfs17.img` (= `rootfs_normal_1`, 72,282,112 B) | top level `bin lib res sbin usr` only — no `/tmp`, `/dev`, `/proc`, `/sys` in the image |

Reproduce the two load-bearing ones:

```sh
# payload ceiling (VM)
make vm-exec CMD='ls -l /tmp/osal_a/*.ko /tmp/osal_b/*.ko /tmp/osal_c/*.ko /tmp/osal_d/*.ko /tmp/sata_staging/*.ko ~/sacd-verify/original/sacd_*'
# the argv surface (Mac, no emulator): the option string + long-option table
python3 - <<'EOF'
import struct
d=open('original/sacd_extract_160','rb').read()
w=lambda v: struct.unpack('<I', d[v-0x8000:v-0x8000+4])[0]
def c(v):
    o=v-0x8000; return d[o:d.index(b'\0',o)].decode('latin1')
print(repr(c(w(0xd5ec))))                 # the getopt string
o=w(0xd5f0)-0x8000                         # the long-option table
while True:
    n,ha,f,val=struct.unpack('<IIII', d[o:o+16])
    if not n: break
    print(c(n), ha, chr(val)); o+=16
EOF
# the flush that makes the file capture trustworthy
/opt/homebrew/opt/llvm/bin/llvm-objdump -d --no-show-raw-insn \
    --start-address=0xd5fc --stop-address=0xd65c original/sacd_extract_160
```

---

## 7. What this stage did **not** decide (parent's call)

1. **Full gate then daemon (with the 5305 release) vs pre-disc gates 01-09 only
   (`HELPER=none`).** §2 wires the first; §5.1 gives the one-line second. Both
   are valid; the first buys gates 10-14 evidence earlier at the risk of the
   `Connect` bookkeeping, the second is strictly additive to today's run.
2. **Whether to compress the whole outer tar instead of the nested tgz**
   (449,759 B, two-line change) — bigger margin, but it rewrites the extraction
   path every C50-C101 run used.
3. **When to fire.** Gates 06/10/11/13 stay red until C102 (sr0 + media
   answers). The block is safe to land now — the daemon stage reports
   `DAEMON_ORACLE` honestly either way — but the *interesting* transcript needs
   C102.

---

## 8. Provenance

| input | identity |
|---|---|
| `original/sacd_extract_160` (= `~/sacd-verify/original/sacd_extract_160` on the VM) | sha256 `0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45`, md5 `49107e9625e8cd27232e395787c46fe2`, 350,830 B |
| `original/sacd_read.ko` | sha256 `b3d7a383…`, 97,805 B — byte-identical to the daemon's embedded copy |
| `decode/daemon_gate.sh` (landed) | 19,080 B, `GATE_SYNTAX=0` under the guest's busybox ash |
| `decode/sacd_gate_ioctl.c` → `/tmp/sacdgate` | built this stage on the VM, 38,710 B, md5 `e03244f71233231919f2422ec0f16538` |
| `tools/bx510_bdpdrv_stub_probe.py` | read only; the diff in §2 is against lines 213/214 of the tracked file |
| `emulator-kit/smoke.py` | `observe()` line 63 — the `wanted` break that forces the block's position |
| guest rootfs | `/tmp/rootfs17.img` on the VM (= partition `rootfs_normal_1`, 72,282,112 B); BusyBox v1.17.2 multiplexer, 584,608 B, applet hard-links |
| images | `/tmp/images-fe/manifest.json` — `fe_test_data` @ `0xe00000`, 1,048,576 B, `records: []` |
