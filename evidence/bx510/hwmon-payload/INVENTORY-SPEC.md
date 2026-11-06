# INVENTORY-SPEC — Phase 0 runtime inventory collector

`bx510_inventory` (source: `tools/bx510_inventory.c`, built binary staged
here as `inventory`) is the read-only runtime-inventory collector for the
production plan §4 remainder — the fields the 2026-11-04 hwmon corpus
does NOT already carry (see `incoming/production-plan/RECONCILIATION.md`).
It completes Phase 0 in one trigger on the next hardware session.

## What is already covered elsewhere (NOT re-collected here)

hwmon + hwmon-boot artifacts already hold: mounts, process ancestry and
lifecycle, UID/GID, duplicate-launch observations, module identity
(sacd_read.ko SHA + /proc/modules), display/fusion IDLE state. Do not
interpret an absent field here as a gap — check the hwmon corpus first.

## Fields, sources, unknown-handling

Every probe is wrapped: a missing file or permission error prints
`UNKNOWN (<errno reason>)` and collection continues; the process never
aborts mid-report. `cat_file` sections cap at the listed byte limits.

| Report section | Field | Source | Unknown-handling |
|---|---|---|---|
| uptime | trigger uptime | `/proc/uptime` | UNKNOWN line |
| elf interpreter | PT_INTERP of the collector image (records the interpreter the player loader actually resolves; the collector is static by build choice — see below) | ELF program headers of `/proc/self/exe` (32+64-bit parse) | `none (static image)` if no PT_INTERP |
| core runtime libraries | interpreter + libc + libpthread + libgcc_s (+libm/libdl/librt) paths, sizes, SHA-256 | directory scan of `/lib` and `/usr/lib` by name prefixes (`ld-linux*`, `ld-2.*`, `libc.so*`, `libc-*`, `libpthread*`, `libgcc_s*`, …), each file hashed | dir unopenable → UNKNOWN; no match → section empty (recorded absence) |
| loaded images | the ACTUAL loaded shared objects of a dynamic process + hashes | `/proc/self/maps`, unique paths, each `.so` hashed | maps unopenable → UNKNOWN; static image → explicit "no mapped file paths" note |
| libc version markers | max `GLIBC_2.x` version marker + the "GNU C Library …" release banner | byte-scan of the libc image (`strings(1)` equivalent — the player has none). libc resolved: first the maps-resolved image, then `/lib/libc.so.6`, `/lib/libc-2.12.2.so`, `/usr/lib/libc.so.6`, … | no image → UNKNOWN; no markers → UNKNOWN |
| kernel release | version string + osrelease | `/proc/version`, `/proc/sys/kernel/osrelease` | UNKNOWN |
| cpu | model, features/flags (full dump) | `/proc/cpuinfo` (16 KiB cap) | UNKNOWN |
| memory | visible/free memory (vendor-reserved observations are derivable from the dump) | `/proc/meminfo` (8 KiB cap) | UNKNOWN |
| random devices + entropy | `/dev/urandom`, `/dev/random` existence/permissions/type, one 8-byte read each, `entropy_avail` | stat + open/read; `/dev/random` is opened O_NONBLOCK so a low-entropy player can never wedge the trigger | stat/open/read failures → UNKNOWN; partial reads marked PARTIAL |
| network interfaces + negotiated link | interface counters; per-interface speed/duplex/carrier (the 100BASE-TX verification); ARP table | `/proc/net/dev`, `/sys/class/net/*/speed|duplex|carrier`, `/proc/net/arp` | per-file UNKNOWN |
| resource limits | soft/hard limits of the trigger context | `/proc/self/limits` | UNKNOWN |
| busybox identity + applet list | busybox SHA + the no-args applet listing + `uname -a` (the player busybox lacks `date`; the raw listing IS the applet inventory) | stat/hash `/bin/busybox`; fork/exec capture, 4 KiB cap | not executable → UNKNOWN |
| flash / storage | MTD layout, free space per mount | `/proc/mtd`; `busybox df`; stat `/dev/mtd0` | per-probe UNKNOWN |
| directfb / fusion runtime identities | `/dev/fusion*` + `/dev/fb*` listing, `/proc/fusion/*` contents (read-only, 4 KiB/file), DirectFB/Fusion library hashes | opendir/stat + hash of `/usr/lib` + `/lib` matches (`libdirectfb*`, `libdirect-*`, `libdirect_*`, `libfusion*`) | per-probe UNKNOWN |

SHA-256 is implemented in-binary (no crypto dependency) and was verified
bit-exact against `sha256sum` on the lab VM (libc.so.6 hash matched).

## Build

One portable C99 source. Behavior tested as an x86 build against the
VM's real `/proc` (sample: `INVENTORY-SAMPLE-x86-vm.txt`); the payload
build is the era gnuarm toolchain, STATIC:

    ~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -Wall -std=gnu99 \
        -static -o inventory tools/bx510_inventory.c
    ~/gnuarm/bin/arm-none-linux-gnueabi-strip inventory

Rationale: zero loader/libc dependency at collection time (the 2009q3
libc.a exists; the stripped static binary is ~526 KiB — trivial for
FAT32), and a static collector keeps its own `/proc/self/maps` clean of
the very libraries it is there to hash. ELF header says "for GNU/Linux
2.6.16" — compatible with the player's 2.6.35. The ARM static binary
was executed under `qemu-arm-static` on the VM (exit 0, full report;
sample: `INVENTORY-SAMPLE-arm-qemu-vm.txt`). NOTE: those samples carry
VM values — player values come only from the player run (emulator/VM
values must never fill plan fields silently).

## Invocation (wired, no CLI line needed)

`hwmon_restore.sh` — which already runs FIRST on every AutoScript
trigger — runs the collector ONCE PER BOOT:

    if [ -x "$D/inventory" ]; then
        U=$(cut -d. -f1 /proc/uptime)
        LAST=$(newest recorded inventory uptime)
        [ "$U" -gt "$LAST" ] && skip    # same boot
        "$D/inventory" >"$D/inventory-$U.txt" 2>&1

Guard logic: `/proc/uptime` resets at boot, so a current uptime LOWER
than the newest recorded one means a NEW boot → collect; higher means
the same boot → skip (five triggers on one boot were observed on
2026-11-04 — this guard collects exactly once). Output:
`<stick>/AutoScript/inventory-<uptime>.txt`, with a one-line note in
`hwmon-boot.txt` for every trigger (collected / skipped / failed).
Failures are logged, never fatal — the restore script keeps working as
the trigger bootstrap either way.

The wiring was proven end-to-end on the lab VM with the real ARM binary
(binfmt-registered qemu-arm): trigger 1 wrote the report, trigger 2
(uptime advanced) skipped, a simulated new boot (recorded uptime ahead
of wall clock) re-collected.

## Stick staging

`tools/sacd_hardware.sh` stages `HWMON_DIR/inventory` →
`AutoScript/inventory` on `usb-build` and refreshes it on every mode
flip; `usb-check` fails if it is missing, verifies it is an ARM ELF,
and WARNs if the stick copy differs from the repo copy.

## Post-session reading

The report is plain text; fields land in the plan §4 profile
(`sony-s5100-m15r0257` compatibility profile) as collected — every
field is either a value or an explicit UNKNOWN with reason.

## v2 addition: the Fusion participant adjudicator (display-takeover decision)

The `directfb / fusion runtime identities` section now ends with
`participant identity resolution` — THE measurement the
display-takeover research package says adjudicates between the two
takeover strategies:

- **Join-a-world reading**: a surviving participant PID + start time
  (/proc/<pid>/stat field 22) with a live fusionees entry (ID 1 =
  master) → a Fusion world exists on the player; the takeover can
  target joining it (DirectFB route).
- **No-master reading**: no /proc/fusion entries / no live PIDs → the
  old forced-slave hang is fully explained (no master at all); the
  takeover goes native-route (x_gl_* inside bdpprog) or vendor-layer.

Mechanics: while dumping /proc/fusion, any file content is parsed for
integer tokens following the word "pid" (the fusionees TABLE layout)
with a fallback to bare-ID lists; live-resolving PIDs (dead PIDs are
filtered — control-proven) get their full /proc/<pid>/stat line
(start time = field 22) plus Name/Tgid (Tgid matters: the recorded PID
can be a thread). Raw file content is always dumped alongside, so the
report is self-checking. A missing /proc/fusion prints the explicit
"no live PIDs ... supports the no-master reading" line.

Controls (2026-11-04, VM): negative (no /proc/fusion) → explicit
no-master line; positive (faked fusionees table with live pid 1 +
a dead pid) → systemd's stat + Tgid resolved, dead pid correctly
filtered. ARM static binary SHA-256 starts 70666def308646ba.
