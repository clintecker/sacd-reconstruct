# The on-panel HUD (`sacd_hud`)

A cyberpunk console drawn on the player's own display while the daemon works,
designed to be legible from a sofa and honest about what the daemon is doing.

**There is one HUD, and the HUD is the daemon's UI — one thing.** The daemon
presents a single user-facing interface, built into `sacd_extract_160`
itself. Two other graphics programs exist in the tree and neither is the
daemon's UI:

- **`sacd_ui`** — a *client-leg milestone artifact*: a separate-process disc
  console that holds a real client session and reads the TOC off the wire.
  It proved a client-driven panel render plus wire parity; it is kept as a
  regression fixture, but it is not the daemon's UI and it is not shipped on
  the stick.
- **`cyberdraw`** — a *display-leg test payload*: a self-authenticating
  procedural pattern whose TV photo can only mean "our pixels reached the
  panel". It is rig instrumentation, never a product.

## Architecture: where the HUD lives

**The in-daemon HUD is LANDED (2026-11-16) — both modes.** One binary:
`sacd_extract_160 -S --hud=console|panel` serves port 2002 AND renders the
HUD from its own live state — clients, ripping progress, disc stats — no
`/proc` scraping, no ticker file, no second process, no UDP hop. The panel
mode runs the proven retro renderer core (pool-mmap surface, Sony font)
inside the daemon process; guest run `hudpan2` captured its frame (pool
mean luminance 50.49, gated PASS — `evidence/bx510-guest/graphics/ui-hudpan2/`).

The seam (`reconstruct/tool/hud_state.h`): the daemon publishes a state
snapshot at its existing 1 Hz `server_loop` heartbeat and inside the
DISC_READ dispatch (reads served, sectors served, encrypted sectors, last
LSN, high-water progress); the HUD thread (`reconstruct/tool/hud.c`) copies
under a mutex and renders at its own pace. Compiled only under
`-DENABLE_HUD` (`make ENABLE_HUD=1`): the parity/verify build is untouched —
`sacd-verify` still PASSes with the same release SHA, because the HUD layer
does not exist in that configuration.

Proven in the guest (run hudint5, UART transcript in
`evidence/bx510-guest/bdpdrv/`): the daemon served a real client's TOC reads
while the HUD printed
`HUD disc=sacd 353844/1064208 sectors (33%) reads=4 last=353804+40` — the
ripping progress is the DAEMON'S OWN counters, not an outside observer's.

## The disc console (`HUD_SCENE=disc`) — the sacd_ui layout merged in

Panel mode's second scene: the client-leg console's proven 640x360 layout
(title bar, status block, two area panels with track tables, event log,
summary) drawn at DEVICE resolution (crisp 1:1 text, the sacd_ui convention)
in this renderer's palette, finished with the device fx. The client-side
session-summary block is replaced by the live rip telemetry only the daemon
knows (reads, sectors, encrypted subset, rate, ETA, progress bar). Selected
with `HUD_SCENE=disc` at launch; the retro scene stays the default until a
fire flips it deliberately.

The data is the state seam's v2: `hud_state_t` now also publishes the parsed
TOC snapshot at `DISC_OPEN` (areas, channels, per-track LSN + MSF straight
out of the scarletbook handle the daemon already parsed for serving), and a
daemon-side event ring (connect/disconnect, disc open/close) that the
renderer imports into its log.

Proven in the guest (run hudisc4, fired mid-rip): every region renders with
LIVE data — the track tables carry the real Firebird TOC the daemon parsed,
the telemetry panel shows the rip's own progress bar lit. Region ink probes:
2ch rows 2639 px, multi rows 4457 px, telemetry bar 480 px + lines 2125 px.
Two lessons codified: the first fire's dump came after the UI session's
`DISC_CLOSE`, which clears the TOC — the captured frame was the honest
post-close idle frame (fire the dump MID-SESSION); and per-char stbtt
rasterization every frame starved the HUD thread on the emulated ARM926
(run hudisc3 stalled mid-repaint) — the device-res path now caches glyph
bitmaps keyed (codepoint, size), pixel-identical on the sim.

Also fixed on the way: `fx_aberration` sampled its own output in-place, so
the left border's blue propagated across the whole row (found by the
disc-scene pixel probes; the sim never ran fx before).

The two stdout-orientation traps this cost a day to find, both codified:
stdout is WIDE-oriented (`fwide(stdout,1)` before the server loop), so the
HUD prints through `fwprintf` — narrow `printf` silently fails; and a
redirected stdout is fully buffered — every guest gate that reads the HUD's
lines must re-read `daemon.out` AFTER the client session
(`DAEMON_OUT_END2` in the fire template).

## The separate-process HUD (the stepping stone, still in the tree)

The standalone `tools/bx510_sacd_hud.c` binary remains as the panel-renderer
stepping stone: it proved the render path (pool-mmap, Sony font, guest gate
green) and carries the UDP-push + `/proc` telemetry that the in-daemon HUD
will absorb when its panel mode integrates the renderer core
(`--hud=panel` degrades to console, loudly, if the pool surface cannot be
opened). It is scaffolding,
not a second HUD, and is never presented as one.

## Why it is built the way it is

> The full design walk-through (panels, alert classes, the state model and
> its evidence trail) is [HUD-DESIGN](HUD-DESIGN.md).

Three findings from the hardware shaped the design:

1. **`/dev/fb0`'s smem is not the scan-out.** A paint into it is overwritten
   within two seconds (measured: two different md5s, same region). The panel
   scans an MT85xx *image-pool* buffer.
2. **The vendor path does reach the panel.** Linking the player's own
   `libdirectfb-1.2.so.0` + `libdirectfb_mtk.so` and flipping a surface puts
   pixels on the TV (photographed). The pool slice can also be mapped directly
   by length and drawn into — that is the path the HUD uses.
3. **Desktop typography is wrong for a TV.** The HUD therefore draws like an
   **8088 VGA screen**: a 320×180 canvas of 16 palette indices with an 8×8
   bitmap font, integer-scaled ×6 to 1920×1080. Text is 48 px tall on the panel.

## Layout

LCARS-inspired grammar, dystopian capture-farm content:

```
 spine │ SACD │ CLUSTER │ NODES │ UPTIME │ FPS │  :2002 UP │ LINK LIVE
       ├────────────────────────────┬──────────────────────────┐
       │ EVENT MATRIX (LED field)   │ TELEMETRY                │
       │  column = event, height =  │  MB/s, sparkline,        │
       │  magnitude, colour = class │  disc map, TMP, alerts   │
       ├────────────────────────────┴──────────────────────────┤
       │ CLUSTER LOAD ▁▂▅█▇  …… (fire / sweep)                │
       │ Z80 NODE FARM · colour key R G B C M Y · build id    │
```

The **event matrix** replaces a text log: one column per event, bar height =
sectors, colour = class (read / decrypt / client / error / system), older columns
fade. You read bursts, gaps and errors as a pattern.

## Telemetry sources

**In-daemon HUD (the product):** the daemon's own live state, published
through `hud_state.h` at the 1 Hz heartbeat and in the DISC_READ dispatch —
client connectivity, reads served, sectors served, encrypted sectors, last
LSN, progress against `total_sectors`, disc presence/type. No scraping, no
second channel.

**Stepping-stone HUD (the separate-process renderer):** `/proc/net/tcp`
(listener state), `/proc/<pid>/io` daemon liveness, `/proc/modules` CPSA
state, the daemon's stdout ticker, and the host's UDP 20023 push. These
inputs retire when the panel-mode renderer moves in-daemon.

## What Sony ships that we use (verified on the real rootfs)

| Stock asset | Where | What it gives us |
|---|---|---|
| DirectFB 1.2.7 core | `/lib/libdirectfb-1.2.so.0.7.0` | surfaces, layers, windows, blits, font engine |
| System provider | `lib/directfb-1.2-0/systems/libdirectfb_mtk.so` | MT85xx vendor init + pool + cmd ring (decoded: [mt85xx contract](mt85xx-fbdev-graphics-contract.md)) |
| GFX driver | `lib/directfb-1.2-0/gfxdrivers/libdirectfb_mt85.so` | accelerated fill/blit |
| Window managers | `wm/libdirectfbwm_sawman.so`, `wm/libdirectfbwm_default.so` | multi-app windowing — coexistence instead of takeover (S2 proven in guest: `evidence/bx510-guest/graphics/sawman-run.md`) |
| Sony fonts/messages | `/res/font.bin` (62 KB), `/res/osdmsg.bin` (4.9 MB) | the device's own glyphs and OSD strings (format: [FONT-FORMAT.md](FONT-FORMAT.md)) |
| Sony images | `/res/logo*.bin`, `logo_clrbar.bin` | boot logo, colour-bar art |
| Appliance UI | `bdpprog` + `libX2.so` + `.rel` apps | draws via `x_gl_*`, references libdirectfb by name |
| Kernel driver | `bdpdrv.ko` (8.1 MB) | the REAL display/CPSA stack — run in the rig, not reconstructed (`evidence/bx510-guest/bdpdrv/`) |

Honest limits: QEMU FPS never predicts ARM926 FPS (timing stays a hardware
measurement); `bdpprog`'s `x_gl_*` path stays opaque until `.rel`/X2 decode;
Sony's font sizes are what the device ships.

## Build and run

```sh
# the ONE HUD, in the daemon (product form):
make -C reconstruct ENABLE_HUD=1 CROSS=<arm-gcc>   # sacd_extract_160 gains --hud=console|panel
# in the guest fire: --daemon-launch="./sacd_extract_160 -S --hud=console"

# the panel-renderer stepping stone (standalone, proven):
make sacd-hud-build       # ARM build through the era toolchain
make sacd-hud-sim         # host render (same scene code) -> PNG
make sacd-hud-anim        # host render -> animated GIF + MP4
make sacd-hud-guest       # render inside the QEMU guest, gated on rc + non-black
```

## What it looks like (screenshots)

The product screenshot is the in-daemon panel frame:
`gallery/hud-in-daemon-panel.png` — `sacd_extract_160 --hud=panel` painting
its own panel in the guest (run hudpan2, pool mean luminance 50.49, gated
PASS). `docs/GRAPHICS-GALLERY.md` embeds it with the run's markers, plus
the renderer core's standalone forms (SIM render, standalone guest render,
animation) for the stepping-stone lineage.

On hardware the daemon IS the HUD: the stick's supervisor preloads the CPSA
module on a free compid and starts `sacd_extract_160 -S --hud=panel`; no
second process exists.

## The game it plays with the appliance

The appliance UI and the HUD are both clients of the same display; taking the
primary surface over means the UI does not come back until a reboot.
Coexistence via the shipped SaWMan window manager is PROVEN in the guest
(second DirectFB client creates a window, draws, flips, destroys; the
underlying app undisturbed — `evidence/bx510-guest/graphics/sawman-run.md`).
