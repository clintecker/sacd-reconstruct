# Graphics gallery — what the reconstructed stack actually renders

Every image here is a captured or reproducible artifact, not a mock-up. One
line per image names the run and the evidence trail. The goldens are the
reference frames; the guest captures are what Sony's real guest OS painted;
the parities tie the two together.

## The daemon UI (`sacd_ui`) — client-driven disc console

| image | what it shows | provenance |
|---|---|---|
| `ui-sim-golden-s1.png` | the accepted golden frame, scene s1-full, 1920x1080: master TOC + both area TOCs + 6 tracks + ASCII disc map | accepted by explicit human `make ui-golden GOLDEN=accept`; renderer sha + spec sha + font sha recorded in `regress/golden/manifest.json` |
| `ui-guest-docshot1.png` | the SAME scene rendered INSIDE the Sony guest (QEMU, kernel 2.6.35), 320x180 capture upscaled 3x | run `ui-docshot1` (2026-11-16): the UI held its own wire session (`UI-EV 0003-0012`: DISC_OPEN -> SIZE -> READ 510x10 -> READ 544x40 -> READ 353804x40 -> DISC_CLOSE), decoded `cat=CDSML8558 year=2019` from bytes read off port 2002, and the rip client PASSED in the same run (`CLIENT_PASS`). Transcript: `evidence/bx510-guest/bdpdrv/bdpdrv-rundocshot1.uart.log` |
| `ui-guest-c132-watch.png` | the UI while a SECOND client rips: `* DAEMON CLIENT CONNECT (1 live)`, `RIP WATCH file=/tmp/ripA.bin`, `RIP DONE 128 sectors` | run c132 (the F-1 overlap experiment); `evidence/bx510-guest/graphics/ui-c132/shot.md` |

Guest-vs-SIM parity: per-region ink correlation >= 0.85 on the latest ui-loop
runs (`make ui-parity`); layout regression 5/5 scenes PASS with the accepted
goldens (`make ui-regress`).

## The HUD (`sacd_hud`) — cyberpunk capture console

| image | what it shows | provenance |
|---|---|---|
| `hud-sim.png` | Mac SIM render, 1280x720, real Sony font + synthetic telemetry | `make sacd-hud-sim` (the layout-iteration loop, seconds per frame) |
| `hud-guest-render.png` | the HUD rendered in the real Sony guest, 640x360x3 capture decoded from the UART `FBPIX` hex line | `make sacd-hud-guest` — gate PASS 3x on 2026-11-16 (rc=0, mean luminance 83.84); green since e9dbd8b (pool-mmap render path) |
| `hud-anim.gif` | the HUD animating: rotating wireframe cube, perspective grid, CRT sweep, cursor blink | `make sacd-hud-anim`; blink period asserted 2 Hz +/-10% by `make ui-anim` |

## Capture-fidelity notes (read before judging image quality)

- Guest captures ride the UART transcript as one `FBPIX` hex line; the
  standard capture is 6x-downscaled (320x180) and loses 3-7 rows to console
  interleaving (zero-filled black stripes). These losses are MEASURED and
  reported per frame in every `shot.md`, never eyeballed away.
- The full-resolution ground truth for any scene is the SIM golden; the
  guest is proven to reproduce it per-region (>=0.85 ink correlation), so
  `ui-sim-golden-s1.png` is what the guest paints, row-exact.
- A `UI_SCALE=1` full-res guest dump (1920x1080 over several UART chunks)
  is possible but slow; not needed while parity gates carry the proof.

## Regeneration

    make sacd-hud-sim                 # hud-sim.png
    make sacd-hud-anim                # hud-anim.gif
    make sacd-hud-guest               # guest HUD render + gate verdict
    make bx510-ui-loop RUNID=<id>     # fresh guest UI capture -> ui-<id>/
    make ui-regress-all               # layout + animation + guest parity suite
