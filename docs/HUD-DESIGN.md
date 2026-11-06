# SACD HUD — a cyberpunk console that shows what the daemon is doing

Status: design (2026-11-05), grounded in tonight's hardware results.
Target: our own full-screen UI on the BX510, driven by **real daemon state**,
not decoration.

## Why this is now possible

Tonight proved the three pieces this needs:

1. **We can own the panel.** A ~40 KB binary linking the player's own
   DirectFB 1.2.7 + the MT85xx provider creates a 1920x1080 DSPF_ARGB primary
   surface and flips it (`dfbhello`, photo evidence). Raw `/dev/fb0` is a dead
   end (another writer erases it in <2 s).
2. **We can run it from the stick automatically** — MTK CLI AutoScript, kept at
   the proven 9-line shape, extras armed by flag files that `hwmon_restore.sh`
   starts (the CLI parser truncates longer scripts).
3. **We can get the daemon up on the panel's terms** — pre-load `sacd_read.ko`
   on a free CPSA `compid`, then the daemon validates and serves.

So the HUD is a normal DirectFB app plus telemetry. No daemon changes needed
for v1.

## Telemetry: three tiers, cheapest first

| Tier | Source | Content | Cost |
|---|---|---|---|
| **T0** | `/proc` sampling, 4-10 Hz | 2002 listener + state (`/proc/net/tcp`), daemon pid/uptime (`/proc/<pid>/{stat,cmdline}`), bytes read + syscall rate (`/proc/<pid>/io`), module state (`/proc/misc` 201, `/proc/modules`), memory, network counters, fusion/fb holders, uptime | zero daemon changes |
| **T1** | `LD_PRELOAD` observer → FIFO (`/tmp/sacd-events`) | per-`ioctl` events: `READ lsn=… count=…`, `DECRYPT`, `AUTH`, errors; we already have this machinery (`evidence/bx510-guest/pair-observer/`, the pair-retry debug build) | one `.so`, no daemon change |
| **T2** | Host channel (UDP in, or the player dials the Mac) | capture orchestration state from `hostctl`: range done/total, MB/s, ETA, verify result, job id | Mac side exists (Phase-2 skeleton) |

T0 alone gives a convincing live console; T1 is what makes it *feel* like the
machine is talking to you ("ticker" lines per request). T2 turns it into a
control surface later.

## Rendering plan (performance is the real constraint)

- Render into a **960x540** logical surface, then **stretch-blit once** to the
  1920x1080 primary. `dfbhello` reported `blit_flags=0x10ff` — accelerated
  blit is available, so the scale is hardware's problem, not the ARM926's.
- Per frame only repaint what changed: full repaint at 15-20 fps for the
  background/grid; **dirty rectangles** for text/tickers each frame. Typical
  scene writes ~50-150 KB/frame instead of 8 MB.
- Text: reuse `cyberdraw`'s hand-rolled 5x7 font, upscaled 2x through the blit
  (authentically blocky, readable at 1080p). Add an 8x12 face for the small
  telemetry column. **No freetype dependency.**
- Budget: measure `Flip` latency and achieved fps on the panel in phase H1 and
  record it; fall back to 1280x720 or 12 fps if 960x540 misses.

## Scene composition (the thing on the TV)

```
┌──────────────────────────────────────────────────────────────┐
│ ▓ SACD//RIPPER  M15.R.0257    BX510   UPTIME 00:14:32   ●LIVE │  status bar
├───────────────────────────────┬──────────────────────────────┤
│ > CPSA module armed compid=1  │  THROUGHPUT  ▁▂▅█▇▅▃▂ 4.7 MB/s│
│ > disc: FIREBIRD  1064208 sec │  LSN         0532104 / 1064208│
│ > listener :2002 LISTEN       │  SECTORS READ  532104          │
│ > client 192.0.2.10 connected│  REQUESTS     1024             │
│ > READ lsn=0532104 n=128  ok  │  ERRORS       0                │
│ > DECRYPT ok  1.9 ms          │  ┌ disc map ────────────────┐  │
│ > READ lsn=0532232 n=128  ok  │  │····●······················│  │
│                               │  └──────────────────────────┘  │
│      (scrolling event log)    │  CPSA 1  MEM 189M  TMP 82%      │
├───────────────────────────────┴──────────────────────────────┤
│ rotating wireframe cube · perspective grid · scanlines · glitch│  backdrop
└──────────────────────────────────────────────────────────────┘
```

Signature elements worth keeping from `cyberdraw` because they photograph
unmistakably: phosphor green on near-black, typed boot log, blinking block
cursor, wireframe cube, perspective grid, CRT scanlines + a moving green sweep.

HUD-specific additions:

- **Disc map**: a horizontal strip of 1,064,208 sectors (aggregated into ~120
  cells); the read head moves, already-read cells stay lit, a verify pass shows
  a second colour. Instantly readable progress on a TV photo.
- **Glitch bars** on real events only: an error line (from T1), module EBUSY,
  a client disconnect. Honest: the glitch means something.
- **Alerts panel** that renders the failure classes we learned the hard way —
  `compid in use`, `insmod EBUSY`, `/tmp` full (zero-byte log), CLI truncation —
  so the HUD doubles as a bring-up diagnosis surface.
- **STANDBY state** (we proved the daemon keeps serving in standby): the HUD can
  show a dimmed "serving in standby" mode, which is exactly the ripping-station
  posture.

## Input (phase H4)

The `dfbhello` log shows DirectFB already opening **`LiRC Input`** and the
player runs `lircd_simulator`, so the IR remote is available to a DirectFB app:
keys can scroll the event log, switch panels (telemetry / raw ticker / errors),
and arm "start capture". Fallback: read `/dev/lirc*` directly.

## Process model and lifecycle

- `sacd_hud` is a **separate process** from the daemon. It never touches
  `/dev/sacd_read`.
- Launcher: `AutoScript/hudmode` flag file → `hwmon_restore.sh` starts the
  preload-aware daemon, then the HUD (`nohup` in RAM, output to the stick log).
- **Screen ownership**: the HUD is a takeover app. Tonight, after our DirectFB
  session released, the appliance UI did not come back (panel stayed blank) —
  so the contract is explicit: *while the HUD runs, it owns the panel; stopping
  it leaves the panel blank and the appliance UI returns on the next
  boot/launch of `bdpprog`.*
- SaWMan coexistence (HUD as a second app under the appliance's WM) is a
  **later experiment**, not a v1 requirement.

## Phases

| Phase | Deliverable | Evidence |
|---|---|---|
| **H0** | `bx510_sacd_hud.c` static mock: the layout above, fixed strings, one flip + 20 s hold | TV photo (framing check, like `dfbhello`) |
| **H1** | T0 telemetry live (module, listener, pid, MB/s from `/proc/<pid>/io`, uptime), measured fps | log with fps + live values changing while a capture runs; photo mid-capture |
| **H2** | T1 event FIFO from the LD_PRELOAD observer; the event log becomes real per-request lines; glitch on errors | log + photo showing `READ lsn=…` lines that match the host capture |
| **H3** | T2 host push: range progress, ETA, verify result | hostctl pushes; HUD photo shows the same range the host reports |
| **H4** | IR remote input (scroll/panels) | key events in the log + photo of two different panels |
| **H5** | Polish: CRT sweep, glitch shader-by-hand, boot sequence that replays real init events | final photo set |

H0 is a day-reachable artifact (the dfbhello skeleton + layout code). H1 is the
one that makes it a *monitor*; H2 is the one that makes it *the product*.

## Reuse map

| Need | Already exists |
|---|---|
| DirectFB bring-up, surface + flip | `tools/bx510_dfbhello.c` (proven on panel) |
| Bitmap font, scene style | `tools/bx510_cyberdraw.c` |
| Per-ioctl telemetry | `evidence/bx510-guest/pair-observer/` (LD_PRELOAD observer) |
| Host-side job state | `hostctl/` (Phase-2 skeleton, journal/resume) |
| Stick plumbing, flag-arming, logs | `evidence/bx510/hwmon-payload/{hwmon_restore.sh,candlaunch.sh}` |
| Disc facts for the map | baseline manifest: 1,064,208 sectors, ISO-verified hashes |

## Open questions to settle in H1/H2

1. Achieved fps at 960x540-render + 1080p stretch-blit on the real ARM926.
2. Does the LD_PRELOAD observer see the daemon's `ioctl`s when loaded via the
   AutoScript launcher (pair-retry proved the plumbing, not the visibility).
3. Does `Flip` keep the panel refresh while the appliance is in **standby**
   (the daemon serves there; the HUD might be the thing that keeps the panel
   out of deep-blank).
4. How much of the scene can be repainted from a dirty-rect list before the
   cost of tracking exceeds the savings.
