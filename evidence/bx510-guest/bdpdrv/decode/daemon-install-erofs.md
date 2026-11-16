# Daemon install-path EROFS — decode (issue #8)

Date: 2026-11-15. Scope: **decode only** — original daemon binary, the guest's
filesystem state, and the transcripts already in the repo. No fires, no daemon
patch, no edits to `tools/bx510-fire.sh` or any `bx510_client_*.sh.in` /
`bx510_ui_*.sh.in` template.

Issue (`run-c113-c121.md:83-85`): "the daemon's own `install_modules` fails
EROFS (`open filed ffffffe2` = −30). Its `tmpnam`→copy→insmod path writes
somewhere read-only. Exact failing path still to be pinned."

## 0. TL;DR

* **The path is `/tmp`, hard-coded.** `install_modules` (`0x2f970`) does
  `memcpy(mod_file, "/tmp/", 6)` (`0x2f9a4`, literal `0x36234`) into a 26-byte
  `.bss` object (`mod_file` @ `0x59dc0`), calls `tmpnam()` (`0x2f9ac`), then
  `open64(mod_file, O_WRONLY|O_CREAT|O_TRUNC)` (`0x2f9b8`, flags literal
  `0x241`). The embedded `sacd_read.ko` (97 805 B = `0x56de9-0x3efdc`) is
  written there. **VERIFIED** (disassembly + PLT map, §1).
* **It is *not* `/res`.** `/res` — the payload-tgz extraction target — is a
  writable tmpfs in every fire (`runc131:204` `tmpfs on /res type tmpfs
  (rw,relatime)`). The only path `install_modules` opens for write is `/tmp`.
  **VERIFIED.**
* **Why `/tmp` is read-only here:** in the `init=/bin/sh` guest the root is
  `squashfs` mounted **`ro`** (`p0v4:159`, `runc131:160`), and the rig's own
  repacked image carries an **empty `/tmp` directory inside that read-only
  squashfs** (`runC113:179` ROOTLIST, mtime = the C5x repack date). Until a
  guest script mounts a tmpfs over it, `open("/tmp/fileXXXXXX", O_CREAT)` is a
  create on a read-only mount ⇒ **EROFS (−30)**. **VERIFIED (mount state) +
  INFERRED (the errno of that create, kernel semantics §4).**
* **There is no `ffffffe2` in any artifact in this repo.** The only install
  errno on file is `ffffffeb` = **EISDIR (−21)** (`p0v4:192`, `p0v5:192`) — the
  *same* code path with `tmpnam()` failing outright (§3, §4). The EROFS
  attribution is mechanically correct but currently **unbacked by a pulled
  transcript**; §7 names the one probe that pins it in a single fire.
* **The workaround has two halves and the pre-load alone is not enough:** the
  guest script's `mount -t tmpfs tmpfs /tmp` is what makes the temp-file write
  succeed; pre-loading `sacd_read.ko` only makes the daemon's own `insmod`
  benign (`File exists`). **VERIFIED** (`runc122f:2116-2117`).

## 1. The code path, instruction-cited

Binary: `original/sacd_extract_160` (Sony, sha `0fdcefdb…`, 350 830 B).
Symbols: `install_modules` @ `0x2f970` size 464, `mod_file` @ `0x59dc0`
size **26** (`.symtab`). PLT slots resolved from `.rel.plt` with
`.plt` @ `0xc1f8` (20-byte PLT0 + 12 B/stub).

| insn | what | resolved to | evidence |
|---|---|---|---|
| `main+0x30` `0xe308` | `bl install_modules` | — | disasm `0xe308: eb008598  bl 0x2f970` |
| `main+0x3c` `0xe314` | `cmp r3,#0; blt 0xe434` | `<0` ⇒ failure branch | disasm |
| `0xe448`/`0xe44c` | `log_print("Can not install modules")` | literal `0xe4a4` → `0x31fe4`; gated by level `*(0x5735c)+4 > 1` | disasm + word read |
| `0x2f984-0x2f990` | `size = 0x56de9 - 0x3efdc` | **97 805** — the embedded ko | literals `0x2fb0c`/`0x2fb10`; symbols `_binary_sacd_read_ko_start=0x3efdc`, `_end=0x56de9` |
| `0x2f994-0x2f9a4` | `memcpy(mod_file, "/tmp/", 6)` | PLT `0xc50c` = `memcpy`; src literal `0x36234` = `"/tmp/"` (`\x2f\x74\x6d\x70\x2f\x00`) | disasm + `.rodata` read |
| `0x2f9a8-0x2f9ac` | `tmpnam(mod_file)` | PLT `0xc3ec` = `tmpnam` | `.rel.plt` idx 40 |
| `0x2f9b0-0x2f9b8` | `fd = open64(mod_file, 0x241)` | PLT `0xc578` = `open64`; `0x241` = `O_WRONLY(1)|O_CREAT(0x40)|O_TRUNC(0x200)` (literal `0x2fb1c`) | disasm |
| `0x2f9c8-0x2f9cc` | `fd < 0` ⇒ `0x2fac4` | — | `ba00003c blt 0x2fac4` |
| `0x2fac4-0x2fad4` | `result = -errno` | PLT `0xc7dc` = `__errno_location` | disasm |
| `0x2faec-0x2faf8` | `log_print("%s: open filed %x", "install_modules", result)` | fmt `0x362b4`, arg `0x36310` | `.rodata` reads |
| `0x2f9dc` | `write(fd, ko_start, 97805)` | PLT `0xc434` = `write` | disasm |
| `0x2fa88-0x2fabc` | short write ⇒ `-errno`, `"%s: write filed %x"` (`0x362a0`) | — | disasm |
| `0x2f9fc`, `0x2fa14`+`0x2fa20` | `system("mknod -m0666 /dev/sacd_read c 10 201")`, `sprintf(cmd,"insmod %s minor=201",mod_file)`+`system(cmd)` | PLT `0xc320` = `system`, `0xc800` = `sprintf`; literals `0x3623c`, `0x36264` | disasm |
| `0x2fa24-0x2fa28` | `unlink(mod_file)` | PLT `0xc4f4` = `unlink` | disasm |
| `0x2fa2c-0x2fa48` | `fd = open64("/dev/sacd_read", 0)`; `<0` ⇒ `0x2fa58` | literal `0x36278` | disasm |
| `0x2fa6c-0x2fa74` | `log_print("%s: mknod/insmod filed", ...)` (`0x36288`) then `remove_modules` | — | disasm |

So the log line observed in the guest, `[0]: install_modules: open filed
<hex>`, is unambiguously the **`open64(mod_file, …)` at `0x2f9b8`** (the format
`%s: open filed %x` at `0x362b4` has exactly one call site, `0x2faf8`), and the
value printed is `-errno` of *that* open. Nothing else in the binary can emit
it. **VERIFIED** — and mechanically: scanning every 4-byte word of `.text` for
the literals `0x362b4` / `0x36288` / `0x36234` yields exactly one pool slot
each (`0x2fb3c`, `0x2fb30`, `0x2fb14`), all inside `install_modules`. The
`"/tmp/"` literal is referenced **once in the whole binary**.

**`tmpnam` is the only variable in the path.** The 6-byte `memcpy` writes
`"/tmp/"` and `tmpnam(mod_file)` then *overwrites the whole buffer* with an
absolute name — or fails and leaves it untouched. Both outcomes are reachable
and both are represented in the evidence (§3).

## 2. Which directory the copy lands in

`tmpnam()`'s candidate directory is **`P_tmpdir` = `"/tmp"`**, and it is
consulted **only for existence as a directory** — never for writability:

* glibc 2.9's `tmpnam()` calls `__path_search(..., try_tmpdir=0)`, i.e. it
  **does not** read `TMPDIR` (that is `tempnam()`'s behaviour). Source-derived
  decode already on file: `tools/bx510_tmpredir.c:139-142`,
  `evidence/bx510-guest/PHASE0-RESULTS.md:20-23`. **INFERRED (source) +
  VERIFIED (empirical, below).**
* **Empirical proof that `TMPDIR` is ignored** — the p0-era `bgstart` already
  exported `TMPDIR=/res/tmp` (`git show 6dd1f18:tools/bx510_bgstart.c:44`,
  unchanged through HEAD), `/res/tmp` existed in the guest (`p0v4:162-163`
  `mkdir /res/tmp /res/dev /res/proc`), the daemon was launched through that
  wrapper (`p0v4:180`), and `tmpnam` **still** failed (`p0v4:192`). If `TMPDIR`
  were honoured the temp file would have landed on the rw tmpfs and the open
  would have succeeded. **VERIFIED.**
* If `"/tmp"` does not exist as a directory, `__path_search` returns −1,
  `tmpnam` returns NULL **and leaves the caller's buffer alone** — so
  `mod_file` is still the literal `"/tmp/"` from the `memcpy`. **VERIFIED by
  the EISDIR artifact** (§3 row C), which is only reachable with a
  *directory* path.
* If `"/tmp"` exists, `tmpnam` fills in `"/tmp/fileXXXXXX"` (the 26-byte
  buffer accommodates glibc's `L_tmpnam` = 20). The name is then opened with
  `O_CREAT` **on whatever filesystem is mounted at `/tmp` at that instant**.
  **VERIFIED** by the `insmod: can't insert '/tmp/fileAUE86a': File exists`
  lines, which prove the generated name is `/tmp/fileXXXXXX`.

Guest filesystem state, both eras, all **VERIFIED** from transcripts:

| fact | evidence |
|---|---|
| root is `squashfs` mounted **ro** | `p0v4:159`, `p0v5:159`, `runC113:160`, `runc131:160` — `VFS: Mounted root (squashfs filesystem) readonly on device 31:17` |
| full mount table mid-fire, before the client script's `/tmp` mount | `runc131:202-207`: `rootfs on / type rootfs (rw)` / `/dev/root on / type squashfs (ro,relatime)` / `tmpfs on /res type tmpfs (rw,relatime)` / `proc on /res/proc` / `proc on /proc` / `tmpfs on /dev type tmpfs (rw,relatime)` — **no ` /tmp ` entry** |
| the rig's image *does* contain an empty `/tmp` **inside** that ro squashfs | `runC113:179` ROOTLIST: `drwxrwxr-x 2 0 0 3 Nov 12 2026 tmp` (mtime = the C5x repack, not the 2018 Sony dates: `bin/lib/sbin/usr` are `Sep 20 2018`) |
| why the repack added it | `run-c51-c55.md:20-24` — `rootfs_normal_1` unsquashed, **`/proc /dev /sys /tmp` dirs added**, re-`mksquashfs`ed into the rig image. The **pristine** Sony image has no `/tmp` at all: `daemon-wiring.md:436` (`unsquashfs -l` shows top level `bin lib res sbin usr` only) |
| on real hardware the writable `/tmp` comes from the **initramfs**, which this rig does not run | `PHASE0-RESULTS.md:12-14` ("A real player's entire VFS skeleton comes from the initramfs") |

⇒ **The failing target is the `/tmp` directory that lives in the read-only
squashfs root — a *rig-environment* read-only path, not a daemon bug and not
`/res`.** The daemon's hard-coded `"/tmp/"` (`0x36234`) is correct for a real
player, where the initramfs has already mounted a writable `/tmp`.

**Doc conflict, resolved (and it is the EISDIR→EROFS hinge).**
`daemon-wiring.md:155` and `:407` state that `/tmp` "exists at runtime (C101
ROOTLIST, mode 775, runtime mtime) but is **not in the rootfs squashfs**". The
ROOTLIST mtime is `Nov 12 2026` — the exact date of the C5x image repack — while
every pristine Sony entry keeps `Sep 20 2018`, and `run-c51-c55.md:20-24`
records `/tmp` being **added** to the squashfs at that repack. So the
timestamped `/tmp` in `runC113:179` is the repack's in-squashfs directory, and
`daemon-wiring.md:155`/`:407` describe the *pristine* image (`:436`, `:490`).
That single fact is what changes the same failure from row C (no `/tmp` ⇒
`tmpnam` fails ⇒ EISDIR) in the 2026-11-03 p0-era image to row A (`/tmp`
present on a ro mount ⇒ EROFS) in every C54+ image. **VERIFIED for the mtime and
the repack record; INFERRED that every later `images-*` variant carries it**
(only the `images-proc`/`images-*`-era C113 ROOTLIST was read here).

## 3. The three error modes of the same open — and the artifact for each

All three are `0x2f9b8` `open64(mod_file, 0x241)`; they differ only in what
`tmpnam` did and which fs answered.

| # | guest state | `mod_file` | errno at `0x2f9b8` | exit text in `/res/daemon.out` | artifact |
|---|---|---|---|---|---|
| **A** | `/tmp` **exists** (in the ro squashfs) but **no tmpfs mounted** | `/tmp/fileXXXXXX` | **EROFS −30** (`ffffffe2`) | `[0]: install_modules: open filed ffffffe2` + `[0]: Can not install modules` | **NONE IN REPO** (§4) |
| **B** | `/tmp` is a mounted **tmpfs** | `/tmp/fileXXXXXX` | `open` **succeeds**, 97 805 B written, `insmod` runs | `insmod: can't insert '/tmp/file…': File exists` then `SACD Daemon 0.37 active. …` when the module was pre-loaded | `runc122f:2114-2117`; `runc131:2105` (+`2439`); `runc132:2098-2099` (same fire, both daemon starts) |
| **C** | `/tmp` **does not exist** as a directory (pre-repack image) | literal `"/tmp/"` | **EISDIR −21** (`ffffffeb`) — opening a *directory* `O_WRONLY`; the shim rewrote `/tmp/` → `/res/tmp/`, still a directory | `[0]: install_modules: open filed ffffffeb` + `[0]: Can not install modules` | `p0v4:192-193`, `p0v5:192` |

Row-B quotes (verbatim):

```
evidence/bx510-guest/bdpdrv/bdpdrv-runc122f.uart.log:2114:====DAEMON_OUT====
evidence/bx510-guest/bdpdrv/bdpdrv-runc122f.uart.log:2116:insmod: can't insert '/tmp/fileAUE86a': File exists
evidence/bx510-guest/bdpdrv/bdpdrv-runc122f.uart.log:2117:SACD Daemon 0.37 active. Client none. SACD disc inserted. …
```

Row-C quotes (verbatim):

```
evidence/bx510-guest/artifacts/p0v4-uart.log:192:[0]: install_modules: open filed ffffffeb
evidence/bx510-guest/artifacts/p0v4-uart.log:193:[0]: Can not install modules
evidence/bx510-guest/artifacts/p0v5-uart.log:192:[0]: install_modules: open filed ffffffeb
```

`tools/decode_errno.py ffffffeb` → `-21 → EISDIR`; `tools/decode_errno.py
ffffffe2` → `-30 → EROFS` — both decoded through the tool, never by eye
(AGENTS.md #7).

**Row C is only reachable because `tmpnam` failed**, so it doubles as the
VERIFIED proof of the "failed `tmpnam` leaves `"/tmp/"`" branch in §2. It also
shows the C5x repack *changed the errno of the same failure* from EISDIR
(no `/tmp` at all) to EROFS (`/tmp` present but on a ro mount).

## 4. Artifact audit — the −30 has no transcript in this repo (honest negative)

`grep -rn 'ffffffe2|EROFS|open filed'` across the whole tree: the only
`install_modules` errno artifacts are the two `ffffffeb` lines above; every
other install artifact is `mknod/insmod filed` (the *third* message,
`0x36288`, i.e. the write succeeded but `open("/dev/sacd_read")` failed:
`p0v6:195`, `p0v8:425`, `p0v9:430`, `p0v10:462`, `p0v11:291`,
`evidence/runtime-differential/*.err:3`, `evidence/bx510/hw-session-2026-11-05/RESULTS.md:46`).
`EROFS` as a bare word appears **only** in `run-c113-c121.md` itself.
The `mount | grep ' /tmp '`-less state that produces A is real
(`runc131:202-207`), but no pulled transcript captured the daemon failing in
it.

**So: the *mechanism* is pinned; the *specific* `ffffffe2` sighting is
unbacked-by-artifact.** Two candidate provenances, both INFERRED:

1. **A `--guest-cmd` fast fire that omitted the `/tmp` mount.** Fast-fire mode
   is `spine + odd_tail + the one command` **and skips `daemon_commands()`
   entirely** (`tools/bx510_bdpdrv_stub_probe.py:499-505` vs the `/tmp` mount
   at `:199-205`). A one-command fire whose single line is the daemon launch
   therefore boots with `runc131:202-207`'s mount table, and the daemon's own
   `open("/tmp/fileXXXXXX", O_CREAT)` hits the ro squashfs. This fits
   `run-c113-c121.md:92-93` ("the EROFS/active-oracle answers each cost one
   fast fire") — the EROFS probe and the oracle probe were two different fires,
   and only the second one's transcript is quoted in that doc.
2. A mis-copy of `ffffffeb`→`ffffffe2` when the doc was written.

Either way **§7's probe settles it in one fire** and is cheap.

Why the create *must* be EROFS on a ro mount (row A) — **INFERRED** (kernel
2.6.35 semantics; not measured on this path): `open(..., O_CREAT)` takes
`mnt_want_write()` on the path's mount before any inode-level check, and a
`MS_RDONLY` mount returns `-EROFS`. The guest itself demonstrates EROFS for
the sibling write op — `mkdir: can't create directory '/proc': Read-only file
system` (`bdpdrv-runC50.uart.log:169`, `:1634`, `bdpdrv-runC51.uart.log:169`)
— so the mount really does refuse creates with EROFS. Row C shows EISDIR is
what a *directory* target yields instead; those two are therefore mutually
exclusive and diagnostic, which is exactly what the §7 probe exploits.

## 5. Why the standing workaround works (and which half does what)

The workaround in use is two separate guest-side facts, and they fix different
legs:

1. **`mkdir -p /tmp; mount -t tmpfs tmpfs /tmp`** before the launch
   (`tools/bx510_client_a_reconnect.sh.in:24-25`, `…_b_readfail.sh.in:22-23`,
   `…_c_overlap.sh.in:34-35`, `…_d_arearead.sh.in:30-31`,
   `tools/bx510_ui_guest.sh.in:33-34`, `…_ui_reactive_guest.sh.in:30-31`;
   transcripts `runC113:2389-2390`, `runC120:2396-2397`,
   `runC121:2392-2393`, all `TMPTMP=0`). This is what makes
   `open64(mod_file, 0x241)` at `0x2f9b8` **succeed** — it moves the create off
   the ro squashfs onto a rw tmpfs. This is the half that actually retires the
   EROFS.
2. **Pre-loading `sacd_read.ko` ourselves** (then `insmod` inside the daemon's
   `system()` reports `File exists`). This retires the *third* failure message
   (`0x36288`, "the node did not open") — not the EROFS. **VERIFIED**: the
   daemon's own `mknod`/`insmod` still execute (they always do; the temp file
   exists and was written), and its `open("/dev/sacd_read")` at `0x2fa2c`
   succeeds only because the module is already resident.

⇒ **Pre-loading the module does NOT bypass the EROFS.** With the module
resident but the filesystem state equal to row A, the daemon still dies at
`0x2f9b8` with `open filed ffffffe2` + `Can not install modules` and never
reaches `insmod`. Any future fire that "just adds the module" without the
`/tmp` mount will fail exactly there.

Note (recorded, not acted on): `tools/bx510_bgstart.c:11-16` claims
`TMPDIR=/res/tmp` restores the temp-dir behaviour. §2 shows `tmpnam()` ignores
`TMPDIR` in this libc, and `p0v4` proves it empirically. `bgstart`'s `TMPDIR`
is therefore inert for `install_modules`; its genuinely load-bearing actions
are the `PATH` export and the `mknod /res/dev/sacd_read c 10 201`
(`tools/bx510_bgstart.c:54`, `:61`). Not edited here (out of scope; the file's
comment is a documentation defect, not a behaviour defect).

## 6. What a real fix would be — a guest-script change, never a daemon patch

The daemon is the unmodified Sony binary (`original/sacd_extract_160`) and its
`"/tmp/"` literal is *correct* for the platform (a real player's initramfs
provides a writable `/tmp`, `PHASE0-RESULTS.md:12-14`). The defect is in the
**rig's guest environment**, so the fix belongs in the guest shell, in this
order:

1. **`mkdir -p /tmp` then `mount -t tmpfs tmpfs /tmp` before ANY daemon
   launch** — keep the `mkdir` even though the current image has `/tmp`: it is
   the same line the probe needed for the *pristine* image
   (`daemon-wiring.md:47-51`, `daemon-gate-experiments.md:262`). Do not rely
   on the `/tmp` that the C5x repack added — that one is **ro**.
2. **Assert it, don't assume it** — the three-line pre-launch probe in §7,
   placed after the mount and before `./sacd_extract_160 -S`. A fire whose
   `EROFS_PIN_RC` is non-zero must fail loudly instead of burning a run.
3. **Ordering rule for every future template:** the `/tmp` mount must precede
   the *first* daemon start in the boot, including a re-launch after
   `rmmod`. `remove_modules()` (`0x2fb40`) does not touch `/tmp`, but a
   re-launch after a tmpfs `umount`/reboot re-enters row A.
4. **Fallback if `/tmp` cannot be a mount** (e.g. a future pristine-image
   run): an LD_PRELOAD `tmpnam` fallback in the existing shim — already
   implemented at `tools/bx510_tmpredir.c:148-162` (`/tmp/m%06lu` at `:160`,
   returned when the real call yields NULL) — never a daemon patch. Not needed
   while the tmpfs line is present.

Do **not** "fix" it by patching `install_modules` to write somewhere else:
that would alter the artifact under study (`DELTA.md`'s install/remove modules
are part of the reconstructed delta and are byte-gated by
`incoming/sacd-installer-and-status/…/RESULTS.txt:1-2` — 464 exact bytes,
sha-pinned).

## 7. The pin — in-guest observable for a future fire

Three short lines (C43 lesson: one command per line, no long one-liners), to be
added by whoever next edits a guest template — **not** added here:

```
echo EROFS_PIN_BEGIN; mount | grep -E ' on /tmp | on / '; ls -ld /tmp
/bin/dd if=/dev/zero of=/tmp/.erofs_probe bs=1 count=1 2>&1; echo EROFS_PIN_RC=$?
echo EROFS_PIN_END
```

(`EROFS_PIN_RC` is the `dd` status itself — 0 on success, 1 on the failed
create. BusyBox's three-line dd report is fine here because the marker is a
separate command; the C117/C118 parsing lesson
(`evidence/bx510-guest/bdpdrv/decode/daemon_gate.sh:146-158`) is about gates
that tried to *parse* that report, not about printing it.)

**Expected outputs, and what each one proves:**

| state | `mount` line | `ls -ld /tmp` | dd's line |
|---|---|---|---|
| **A — the bug (row A)** | no ` /tmp ` entry; `/dev/root on / type squashfs (ro,relatime)` | `drwxrwxr-x 2 0 0 3 … /tmp` (squashfs) | `dd: can't open '/tmp/.erofs_probe': Read-only file system`; `EROFS_PIN_RC=1` |
| **B — fixed (row B)** | `tmpfs on /tmp type tmpfs (rw,relatime)` | `drwxrwxrwt 2 0 0 … /tmp` (tmpfs) | `1+0 records in` / `1+0 records out` / `1 byte (1B) copied…`, no error text; `EROFS_PIN_RC=0` |

In state A the dd `open` is byte-for-byte the daemon's `0x2f9b8` create
(`O_WRONLY|O_CREAT|O_TRUNC` = `0x241`), so its `Read-only file system` **is**
the `-30` of the issue — measured, not inferred. In state B the same line
returns nothing, which is the negative control for the whole claim.

One extra marker that closes the loop on the daemon side (still no new code):

```
grep -c 'install_modules: open filed' /res/daemon.out; grep -c 'Can not install modules' /res/daemon.out
```

`0 0` = install did not fail; `1 1` = row A/C happened, and the preceding
`open filed ffffffe2` line is the sighting to pull into
`evidence/bx510-guest/bdpdrv/` (this repo currently has none — §4).

## 8. How the −30 can be reproduced deliberately (recipe only — NOT fired)

One `--guest-cmd` fast fire whose single command is the daemon launch
**without** the `/tmp` mount reproduces row A deterministically, because
fast-fire skips `daemon_commands()` (`tools/bx510_bdpdrv_stub_probe.py:499-505`)
and the spine leaves `/tmp` on the ro squashfs (`runc131:202-207`). Expected
`/res/daemon.out`:

```
[0]: install_modules: open filed ffffffe2
[0]: Can not install modules
```

This is deliberately left unfired: it costs one boot and its only product is
the artifact §4 is missing. If it is ever run, the transcript belongs next to
`p0v4/p0v5` as the row-A artifact, and the fix (§6.1) is already in every
current template — so it can only be produced by *removing* the mount line,
which is why no current fire can hit it.

## 9. Labels

* **VERIFIED** — instruction addresses and PLT resolutions (§1); `mod_file` =
  26 B @ `0x59dc0`, `"/tmp/"` @ `0x36234`, flags `0x241`; the `%s: open filed
  %x` single call site `0x2faf8`; root fs `ro` and the mount table
  (`p0v4:159`, `runc131:160,202-207`); `/tmp` present in the ro squashfs
  (`runC113:179`) and absent from the pristine image
  (`daemon-wiring.md:436`); `/tmp/fileXXXXXX` as the generated name
  (`runc122f:2116`); `tmpnam` ignores `TMPDIR`
  (`git show 6dd1f18:tools/bx510_bgstart.c:44` + `p0v4:180,192`); `tmpnam`
  failure leaves the literal `"/tmp/"` (EISDIR artifact); the `/tmp` tmpfs
  mount is what makes install succeed.
* **INFERRED** — that `open(O_CREAT)` on this ro mount returns exactly
  `-EROFS` (kernel 2.6.35 `mnt_want_write`; corroborated by the guest's own
  EROFS on `mkdir`, `bdpdrv-runC50.uart.log:169`); the provenance of the
  `ffffffe2` sighting (§4 option 1 or 2); glibc 2.9 `try_tmpdir=0` (source
  decode on file, empirically corroborated rather than read from the shipped
  libc).
* **NOT CLAIMED** — that the rig's `images-*` repack is identical in `/tmp`
  content to the C5x `images-proc` one for every image variant; only
  `runC113`'s ROOTLIST (the images-* era) was checked.
