# The on-panel HUD (`sacd_hud`)

A cyberpunk console drawn on the player's own display while the daemon works,
designed to be legible from a sofa and honest about what the daemon is doing.

**There is one HUD.** This is it. Two other graphics programs exist in the
tree and neither is a HUD:

- **`sacd_ui`** — the *daemon UI*, a disc console that holds a real client
  session and reads the TOC off the wire. It is a milestone artifact from the
  client-leg proof (it proved a client-driven panel render plus wire parity),
  kept and regression-tested, but it is not the HUD and it is not shipped on
  the stick.
- **`cyberdraw`** — a *display-leg test payload*: a self-authenticating
  procedural pattern whose TV photo can only mean "our pixels reached the
  panel". It is rig instrumentation, never a product.

## Architecture: where the HUD lives

**The in-daemon HUD is LANDED (2026-11-16).** One binary: `sacd_extract_160
-S --hud=console` serves port 2002 AND renders the HUD from its own live
state — clients, ripping progress, disc stats — no `/proc` scraping, no
ticker file, no second process, no UDP hop.

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
(`--hud=panel` currently degrades to console, loudly). It is scaffolding,
not a second HUD, and is never presented as one.

## Why it is built the way it is

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

## Telemetry sources (no daemon changes)

| Source | Gives |
|---|---|
| `/proc/net/tcp` | whether `:2002` listens, how many sessions |
| `/proc/<pid>/io`, `/proc/<pid>/stat` | daemon liveness (note: the daemon reads via ioctl, so `read_bytes` stays 0) |
| `/proc/modules`, `/proc/misc` | CPSA module / minor 201 state |
| host push (UDP 20023) | per-request events from the client: `OPEN`, `READ lsn=… n=…`, `CLOSE` |
| daemon stdout | startup, module install, heartbeats, errors |

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
make sacd-hud-build       # ARM build through the era toolchain
make sacd-hud-sim         # host render (same scene code) -> PNG
make sacd-hud-anim        # host render -> animated GIF + MP4
make sacd-hud-guest       # render inside the QEMU guest, gated on rc + non-black
```

## What it looks like (screenshots)

`docs/GRAPHICS-GALLERY.md` holds the current gallery: the Mac SIM render
(`gallery/hud-sim.png`), the guest render decoded from the UART capture
(`gallery/hud-guest-render.png`, gate PASS 3x 2026-11-16, mean luminance
83.84), and the animation (`gallery/hud-anim.gif`).

On the player the HUD is started by the session stick's supervisor, which
preloads the CPSA module on a free compid, starts the daemon with its stdout
captured, then draws into the pool slice.

## The game it plays with the appliance

The appliance UI and the HUD are both clients of the same display; taking the
primary surface over means the UI does not come back until a reboot.
Coexistence via the shipped SaWMan window manager is PROVEN in the guest
(second DirectFB client creates a window, draws, flips, destroys; the
underlying app undisturbed — `evidence/bx510-guest/graphics/sawman-run.md`).
