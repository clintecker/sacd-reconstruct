# The QEMU-speed UI loop — one command from a UI source edit to a viewable frame

Scope: iterate the emulated player's on-screen UI without USB sticks, TV
photos, or hand-typed QEMU command lines. Owner of the targets: this repo's
Makefile (`make help` → `BX510 UI loop`). The UI *source* is its own lane's
artifact (`tools/sacd_ui.c`); this harness builds, stages, fires, captures and
decodes it.

## The loop

```sh
make bx510-ui-loop RUNID=uiloop8          # build + fire + shot, one command
```

or the stages separately (each is one artifact class):

| Target | What it does |
|---|---|
| `bx510-ui-build` | stages the kit's sources to the VM, era-builds `sacdclient`, `fbdump`, `sacdgate`, `fbvirt.ko`, the guest font and **your** UI, repacks `/tmp/bx510-daemon-payload.tgz`, then GATES the `fe_test_data` budget through the probe's own payload arithmetic |
| `bx510-ui-fire` | renders the guest **script** from `tools/bx510_ui_guest.sh.in`, stages it INTO the tgz, and fires the 85-byte `tar -xzf …; sh /res/shim/<name>` command through `tools/bx510-fire.sh` |
| `bx510-ui-shot` | decodes the pulled UART transcript's framebuffer dumps into PNG/GIF + a per-buffer luminance verdict under `evidence/bx510-guest/graphics/ui-<runid>/` |
| `bx510-ui-loop` | the three above, in order |

Knobs on the fire: `SCALE` (fbdump decimation; 6 → 320×180 per buffer, 2 →
960×540), `UI_ARGS` (argv for `./sacd_ui`), `TIMEOUT` (probe seconds).
On the shot: `MIN_LUM` (black-frame threshold, default 4.0).

## The egress path, and why it is shaped this way

The guest has no image tooling (no `base64`/`uudecode`/`od`), so the fastest
frame path is `tools/bx510_fbdump.c` printing RGB888 hex and the **UTF-8 UART
transcript** carrying it home. Everything else (PNG, GIF) happens on the Mac.

Measured lessons, each of which cost a fire:

1. **A long one-line guest command is TRUNCATED by the console.** A ~1350-byte
   command died at `/bin/sh: slee: not found` and the rest of the scenario
   silently never ran (run `uiloop3`; the C43 lesson, now with a length). The
   scenario therefore lives in a staged script inside the payload tgz and the
   fire command is 85 bytes.
2. **`--rows` is mandatory.** One long `FBPIX` line gets interleaved by the
   kernel's console writers and truncated mid-hex (run `c123c`: 1016 of 230400
   pixels). Per-row lines confine the damage; the decoder counts the lost rows
   and zero-fills them, and `shot.md` says "N of M sampled rows lost".
3. **`/dev/fb0` must be bound to fbvirt, not to the driver.** With the daemon
   stack resident `/proc/fb` is `0 mt8530` / `1 fbvirt` — fbvirt registers
   second. `mknod /dev/fb0 c 29 0` gets the real MT8530 framebuffer, which does
   not work in the emulator: `Unhandled fault: external abort on non-linefetch`
   and SIGBUS for both the UI (`UI_RC=135`) and the dump (`Bus error`). The
   template binds the node to the index fbvirt reported.
4. **Kill the UI before reading its log.** A live UI keeps appending UI-EV
   lines; `cat` of a file that never stops growing never returns (run
   `uiloop2`: the fire sat in `cat` until the probe timeout).
5. **Dump BOTH buffers.** A raw-fbdev painter writes the fbdev smem; a
   DirectFB app's surface lands in the vendor pool primary. The verdict names
   which one your frame reached — `uiloop6` (a raw painter) reads
   `fbdev PASS / pool BLACK`, `uiloop7` (the UI under development) reads both
   BLACK.
6. **The FA-latch clear is a scenario invariant, not a step.** `c122f` served
   zero FE traffic and died with "Not a ScarletBook disc!" only because the two
   `sr_fa_mode` invocations were missing. The renderer REFUSES to emit a script
   without the clear, its read-back, and the clear ordered before the daemon's
   `/dev/sr0` open — the same rule `decode/daemon_gate.sh` gate 12b applies.
7. **The CPSA slot must be released before the daemon connects.** Without
   `sacdgate 0x40105301` then `0x40105305`, the daemon's own Connect returns
   `0xE8000006` (busy) and every client read fails. Also an invariant.
8. **One fire at a time per host.** `tools/bx510-fire.sh` takes
   `/tmp/bx510-fire.lock` (exit 3 "REFUSING") and scopes its staged files by
   RUNID: concurrent fires share the runner, the guest command and
   `pkill -f qemu-system-arm`, and a sibling run SIGTERMed a live fire
   (FIRE_RC=143) and deleted its traces. RUNIDs must also be unique per lane —
   the traces are `/tmp/bdpdrv-run<RUNID>.*` on the VM.
9. **A pulled transcript must prove it is the fire you ran.** `bx510-ui-shot`
   exits 2 unless the transcript carries the template's own `UI_SHOT_DONE`
   marker: another lane's trace can carry `FBGEOM` blocks and would otherwise
   "pass" as a frame from a build nobody asked about.

## What the artifact is

```
evidence/bx510-guest/graphics/ui-<runid>/
  fbdev-<w>x<h>.png   the fbdev smem (raw painters)
  pool-<w>x<h>.png    the vendor pool primary (DirectFB apps)
  *.ppm               the same frames, for ffmpeg or other tooling
  frames.gif          both buffers side by side in time (when ffmpeg exists)
  shot.md             per-frame geometry, mean luminance, verdict, lost rows,
                      and the run's markers (CLIENT_RC, UI_RC, FA_MODE, …)
```

Exit codes from `bx510-ui-shot`: 0 at least one buffer passed, 1 both black,
2 no frame / a truncated single-line dump / a foreign transcript.

## Validated runs (this lane's own artifacts)

| Run | UI built | Result |
|---|---|---|
| `uiloop6` | a throwaway raw-fbdev painter (validation stand-in) | `fbdev PASS (mean luminance 40.57)` / `pool BLACK` — the egress path produces a real, viewable frame through QEMU |
| `uiloop7` | `tools/sacd_ui.c` (the UI lane's build) | both buffers `BLACK` within `UI_WAIT=3 s` — honest verdict for the UI as it stood, not a harness failure |

`u1`/`u2`/`ui1` in `evidence/bx510-guest/bdpdrv/` are concurrency casualties
from the RUNID collision described in lesson 8; their transcripts belong to a
different lane and are kept only as the record of that diagnosis.
