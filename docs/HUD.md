# The on-panel HUD

A cyberpunk console drawn on the player's own display while the daemon works,
designed to be legible from a sofa and honest about what the daemon is doing.

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

## Build and run

```sh
make sacd-hud-build       # ARM build through the era toolchain
make sacd-hud-sim         # host render (same scene code) -> PNG
make sacd-hud-anim        # host render -> animated GIF + MP4
make sacd-hud-guest       # render inside the QEMU guest, gated on rc + non-black
```

On the player the HUD is started by the session stick's supervisor, which
preloads the CPSA module on a free compid, starts the daemon with its stdout
captured, then draws into the pool slice.

## The game it plays with the appliance

The appliance UI and the HUD are both clients of the same display; taking the
primary surface over means the UI does not come back until a reboot. Coexistence
(via the shipped SaWMan window manager) is the next step, described in
`STOCK-LEVERAGE-PLAN.md`.
