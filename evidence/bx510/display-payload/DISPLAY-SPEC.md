# DISPLAY-SPEC — the display-leg payload (does OUR pixels reach the TV?)

The on-player half of the graphics programme: prove, cheaply and first-hand,
whether a userspace paint of `/dev/fb0` reaches the panel — and if it does
not, make the log name the cause instead of leaving "black screen".

Guest-side status: `tools/bx510_cyberdraw.c` is QEMU-proven against our
`fbvirt` MT85xx device (deterministic full-frame md5 `f3392f1a…`, identical
across independent boots — `evidence/bx510-guest/graphics/RESULTS.md`).
What is unproven is the real bdpdrv fbdev: idle hwmon snapshots show
**zero `/dev/fb*` and `/dev/fusion*` holders**, `fusion.ko` use-count 0, and
no fusion world files, so the appliance is *not* holding the framebuffer
when idle — a raw paint is low-contention, but whether that buffer is the
scan-out plane, an OSD plane, or nothing the compositor samples is exactly
what this leg measures.

## Contents

| File | What it is |
|---|---|
| `cyberdraw` | The ARM payload. Built from `tools/bx510_cyberdraw.c` (tracked), gnuarm 2009q3 toolchain, dynamic, stripped. |
| `displaylaunch.sh` | The launcher wrapper. Copied to `/tmp` by short CLI lines, then run (`&`), exactly like the proven `pairlaunch.sh` shape. |

## Pinned build (reproduce before trusting)

Source SHA-256 (`tools/bx510_cyberdraw.c`):
`22f71b539bd832939f17fc06b0522fb1b36c80f2ab35d6d18546c3b24cf5d036`

Binary SHA-256 (`cyberdraw` here):
`17d0c2cb7ba7fd4ae43fa499124d099a7ec4b42c1ac7290d2f6cbcf0856fde13`

Recipe (build host, x86 native — never on the Mac):

    ~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -Wall \
        -o /tmp/cyberdraw tools/bx510_cyberdraw.c -lm -lrt
    ~/gnuarm/bin/arm-none-linux-gnueabi-strip /tmp/cyberdraw

Build facts worth keeping:

- `-lrt` is required — `clock_gettime` is in librt in the 2009q3 glibc
  (without it the link fails with `undefined reference to clock_gettime`).
- The result must stay **dynamic**: a static build's `dlopen` of the retail
  DirectFB died on `__getpagesize: _dl_pagesize != 0` (mt85 run6 lesson).
  `NEEDED: libm.so.6, librt.so.1, libc.so.6`, interpreter
  `/lib/ld-linux.so.3` — the player ships glibc 2.12.2, backward-compatible
  with these 2.9-era symbols.
- Rebuild reproduces the SHA bit-identically (verified: a fresh VM build of
  the same source produced the same `17d0c2cb…`).

## What the launcher does (and why in that order)

1. **State dump before/after** — `/proc/fb`, `/dev/fb*`, fb0 sysfs
   (`blank`, `state`, `stride`, `virtual_size`, `mode`), `/dev/fusion*`,
   `/proc/fusion/*`, `/dev/shm`, bdpprog pid + its fd table, `directfbrc`,
   meminfo head. This is the discriminator set: a black screen must resolve
   to ENODEV (no fb), open/ioctl failure, `blank=1`, or "painted fine,
   nobody scanned it out".
2. **`--static` on EVERY `/dev/fb*` (device sweep)** — geometry + full-frame
   md5 per device before anything can hang. This is the return channel; the
   TV photo is the display proof. They are separate claims. The sweep exists
   because the appliance's scan-out surface may be a second fb/OSD plane
   (idle snapshots showed NOBODY holding `/dev/fb0`), and guessing fb0 is
   exactly the silent-failure shape this project keeps hitting.
3. **`--anim N`** (default 45 s; the stick's `displayanim` file overrides,
   validated 1..100 by `usb-display-mode` and clamped again by the wrapper;
   the tool caps at 100) — the TV-video window, on the first device that
   drew. Ends on the static frame.
4. **Phase-0 inventory re-run at +5 s** — the *active-display* state
   (`RECONCILIATION.md` §14 says idle-only so far). Read-only collector.
   RAM FIRST (`/tmp/inventory-active-<uptime>.txt`), then copied to the
   stick: the stick can unmount during the window (proven failure mode), and
   `hwmon_restore.sh` recovers the RAM copies at the next trigger.
5. Recovery: `hwmon_restore.sh` (runs first on every trigger) copies
   `/tmp/displaylaunch.log` to `<stick>/AutoScript/displaylaunch-recovered.log`
   and every `/tmp/inventory-active-*.txt` back to the stick, and the live
   `<stick>/AutoScript/displaylaunch.log` normally exists too.

### Log semantics (read before interpreting)

- The stick log **appends across triggers and boots**, `pairlaunch.sh`-style
  (an early death must never destroy earlier evidence). Each run is bounded
  by `=== displaylaunch trigger … ===` / `=== displaylaunch end … ===`
  blocks with uptime stamps — count the blocks, don't assume one run.
- Every `log()` line goes to the stick AND `/tmp`; program output is appended
  separately (`draw static-fbN …`, `draw anim …`), so no duplicated blocks.
- `displayanim` on the stick is cleared by `sacd-usb-baseline-mode` and
  rewritten only by `sacd-usb-display-mode` (1..100 s enforced).

## What counts as what

- **Display DEMONSTRATED**: a TV photo/video showing the cyberpunk scene
  (green phosphor banner + wireframe cube + grid) that no appliance UI could
  be mistaken for.
- **Paint DEMONSTRATED, display NOT**: `CYBERDRAW: full-frame md5 …` in the
  log but a black/absent picture, with fb0 present and not blanked — then
  the fb buffer is not the scan-out plane; the follow-on is the vendor-layer
  scratch-surface probe (`FBIO_SET`/plane ops), not a cyberdraw patch.
- **Blocker NAMED**: the exact failing call (`open /dev/fb0`,
  `screeninfo`, `mmap`, `unsupported bpp N`) or `blank=1` in the state dump.
- Never scored as "display failed" when the log shows the paint landed and
  the panel is blanked by bdpdrv standby — that is the standby finding, not
  a draw failure.

## Recovery / risk

A paint only writes RAM the driver owns; nothing is written to flash. If the
UI is disturbed, pull the stick and do a **cold** power cycle (standby alone
may keep a torn plane state) and confirm the stock UI returns before the next
leg. The stick carries the launcher line only; booting without the stick is
stock.

## Session wiring

`tools/sacd_hardware.sh` stages both files on `usb-build`, verifies the
binary SHA in `preflight` and `usb-check`, and `usb-display-mode` writes the
display AutoScript (it also refreshes `pairlaunch.sh`/`hwmon_restore.sh`,
the inventory collector, and writes/removes `displayanim`). The collect step
copies `displaylaunch*.log` and every `inventory*.txt` into the session
folder; the TV photo/video is an operator artifact copied in by hand.

## HARDWARE RESULT (2026-11-05) — raw fbdev loses, the real stack wins

Everything above is guest-side proof and design; the panel settled it:

| Test | Result |
|---|---|
| `cyberdraw --static` / `--anim` on `/dev/fb0` | paint lands (md5 `5be59ae2…`), **nothing on the TV** |
| `fbmd5` 2 s later | md5 `1656abea…` — **different**: another writer owns fb0 |
| `dfbhello` (player's own DirectFB 1.2.7 → `libdirectfb_mtk.so`) | `CreateSurface 1920x1080 DSPF_ARGB` + `Flip OK` → **pattern on the panel 25 s** |

So `/dev/fb0` (mt8530, 1920x1080, stride 7680) is actively rewritten and is not
a usable user-space display path; the vendor-pool path through the retail
DirectFB stack is. Photo: `photos/2026-11-04-dfbhello-on-panel.{HEIC,png}`
(SHA-256 in `photos/SHA256SUMS.txt`). Run log:
`2026-11-04-displaylaunch-hardware.log`. Full session context:
`../hw-session-2026-11-05/RESULTS.md`.

Operational facts learned on the panel and now baked into this payload:

- **Arming is flag-driven** (`AutoScript/displayanim`): the MTK CLI parser
  truncates longer scripts (13 lines / 628 B ran only the first 4), so the
  AutoScript stays at the proven 9-line shape and `hwmon_restore.sh` starts
  this launcher.
- **`/tmp` fills across triggers** (`/tmp/hwmon-data`): zero-byte logs while
  the programs still run. `hwmon_restore.sh` now prunes it per trigger.
- **`fbmd5` exists to keep the claim honest**: a paint that lands is not a
  display; only a photo/video of the panel is.
