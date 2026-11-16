# The QEMU-speed UI loop — one command from a UI source edit to a viewable frame

> Lifecycle position: rung R3 of `docs/LIFECYCLE.md` (the build/test ladder). Read that document for the gates around this one.

Scope: iterate the emulated player's on-screen UI without USB sticks, TV
photos, or hand-typed QEMU command lines. Owner of the targets: this repo's
Makefile (`make help` → `BX510 UI loop`). The UI *source* is its own lane's
artifact (`tools/sacd_ui.c`); this harness builds, stages, fires, captures and
decodes it.

The UI's own loop — what repaints a frame and why, the `/proc` event model, the
`SACD_UI_WATCH_PID` rip-progress band in the event log, the `SACD_UI_SIM_SCRIPT`
scenario replay and the determinism rules — is `docs/ui-reactive.md`. The
scenario script this page fires is rendered from `tools/bx510_ui_guest.sh.in`.

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

The UI-kill wait is not a sleep knob any more (lesson 10): it is the UI's own
first-frame marker plus a fallback bound, and that bound is the renderer's
`--ui-wait-max` (default 90 s), which `bx510-ui-fire` does not override. Pass it
to `tools/bx510_ui_render.py` directly when a scenario needs a different bound.

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
10. **The UI kill waits on a MARKER, never on a sleep.** The UI's
   first frame includes its own client session — `DISC_OPEN` alone measured
   22 s (c123/c132/c133) — so one number cannot be right on both sides:
   `UI_WAIT=3 s` read both buffers BLACK (`uiloop7`: an honest verdict on a
   UI that had not painted yet, not a harness failure) and c126 needed
   `UI_WAIT=150 s` to cover a 35 s rip. `tools/sacd_ui.c` now writes
   `/res/ui-frame.done` once, after its first painted frame (`SACD_UI_FRAME_FILE`
   overrides the path); the template's wait is
   `i=0; while [ ! -f /res/ui-frame.done ] && [ $i -lt N ]; do sleep 1; i=$((i+1)); done`
   — the marker ends it in the good path, `N` (`--ui-wait-max`) only ends it when
   the UI never paints (no hang, and the guest transcript prints
   `UI_WAIT_ITERS=<n>` so the fire says which of the two happened). The plain UI
   template waits on the frame marker **alone**. The three watch-mode templates
   (`bx510_ui_reactive_guest`, `bx510_client_c_overlap`, `bx510_client_d_arearead`)
   wait on the frame marker **AND** their own scenario marker (`/res/rip.rc`, or
   `/res/a.rc` + `/res/b.rc`) — AND, not OR: killing on the frame alone would end
   the observation window ~1 s after the UI's session, before the watched rip made
   any progress, and the AND costs nothing in the good path (the frame marker
   lands first). `tools/bx510_ui_render.py` refuses any UI-launching script that
   has no such bounded marker wait or that puts a bare `sleep <n>` between the
   launch and the kill; `tools/test_bx510_ui_loop.py` executes the wait itself
   (marker-only → runs to the bound, every marker → returns immediately).
   Two rules came out of the same review pass and apply to EVERY wait in these
   templates: a marker wait is always bounded and reports its own expiry on the
   console (`A_WAIT_TIMEOUT=60`, `RIP_WAIT_TIMEOUT=60`) — an unbounded
   `while [ ! -f … ]; do sleep 1; done` turns a UI that never opens into a silent
   probe timeout with nothing in the transcript saying which wait died (the
   renderer now refuses one) — and a client's exit status is captured ONCE
   (`rc=$?; echo A_RC=$rc >/res/a.rc; echo A_RC=$rc`). The old
   `echo A_RC=$? >/res/a.rc; echo A_RC=$?` printed the FIRST echo's status, i.e.
   always `0`: c132's console read `B_RC=0` while `cat /res/b.rc` said
   `B_RC=1` — the exact shape of a receipt that lies.

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
| `uiloop7` | `tools/sacd_ui.c` (the UI lane's build) | both buffers `BLACK` at `UI_WAIT=3 s` — the fixed sleep that was replaced by the frame marker (shorter than the 22 s session, so no frame could exist); honest verdict for the UI as it stood, not a harness failure |
| `docshot1` (2026-11-16) | `tools/sacd_ui.c` | PASS — the UI held its own wire session (`UI-EV 0003–0012`: DISC_OPEN → SIZE → READ 510×10 → both area TOCs → DISC_CLOSE), decoded `cat=CDSML8558` off the socket, the rip client PASSED in the same run, pool mean luminance 13.12 with 3 damaged rows. Gallery: `docs/GRAPHICS-GALLERY.md` (`gallery/ui-guest-docshot1.png`) |

`u1`/`u2`/`ui1` in `evidence/bx510-guest/bdpdrv/` are concurrency casualties
from the RUNID collision described in lesson 8; their transcripts belong to a
different lane and are kept only as the record of that diagnosis.
