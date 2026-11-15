# The reactive UI — one event loop, one state machine, one painter

> Lifecycle position: rung R3 of `docs/LIFECYCLE.md` (the build/test ladder). Read that document for the gates around this one.

Scope: `tools/sacd_ui.c` (the guest console) and its controls
`tools/test_sacd_ui_events.py`. The layout the loop paints is the layout lane's
contract (`tools/ui_layout_spec.json`, `make ui-regress`); this doc owns the
*loop*, not the layout.

The panel used to be repainted thirty times a second whether anything had
changed or not, with `/proc` reads sprinkled through the drawing code. That
worked and told you nothing: the fps number counted redraws, not work, and a new
real-time feature (watching a second client rip) had nowhere to live. The loop
below is the fix, and it is deliberately small enough to read in one sitting.

## The model

```
  POLL (non-blocking, one cadence per source)
  --------------------------------------------------------------
  frame clock                30 Hz   ->  EV_TICK      the glass clock
  /proc/net/tcp               4 Hz   ->  EV_TCP       listener up/down, clients live
  /proc/<pid>/cmdline         4 Hz*  ->  EV_PID       the daemon's pid (*until found)
  /proc/net/dev (lo)          4 Hz   ->  EV_WIRE      cumulative bytes -> MB/s
  stat(SACD_UI_WATCH_FILE)    4 Hz   ->  EV_PROGRESS  a second client's rip
  the startup session         once   ->  EV_SESSION   the disc picture's outcome
                    |
                    v
  QUEUE   fixed ring of typed events, FIFO, no allocation, drop counter
                    |
                    v
  APPLY   apply_event(event, state) -> (state, log line, dirty?)   <-- the ONLY
                    |                                                  state
                    v                                                  writer
  PAINT   draw_frame(state)  when dirty, or when the 2 Hz blink flips
```

Four things make it deterministic, and each one is a line of code you can point
at:

1. **One cadence per source**, both named at the top of the file:
   `FRAME_PERIOD_S` (0.030) for the tick, `TEL_PERIOD_S` (0.250) for the `/proc`
   sources. No source is bursty, so the ring never holds more than five events
   and a drain never has to reorder anything.
2. **A fixed source order** inside one drain: tick → tcp → pid → wire →
   progress. The ring is FIFO, so the apply order in a pass is that order in
   every pass. (Drain-all-per-pass, not one-event-per-pass: with at most one
   event per source and the clock first, draining everything cannot starve the
   tick, and it is the simpler of the two.)
3. **Every log line carries a monotone sequence number**: `UI-EV <seq> <t>
   <mark> <text>`. A transcript's log ORDER is therefore assertable without
   comparing timestamps, which are the one thing a real run cannot reproduce.
4. **`apply_event()` is the only writer of `g_tel`/`g_prog`** and the only place
   a transition is logged; `draw_frame()` reads state and nothing else. Same
   event sequence → same state → same log → same frame. That last arrow is what
   the frame goldens and the frame-to-frame diff rest on.

The 2 Hz blink is the one motion that repaints without a state change
(`BLINK_HZ`, shared by the painter and the loop so they cannot disagree): a
static scene repaints twice a second instead of thirty times. `frames` counts
painted frames, so the `fps` on the RENDER line is now a measurement — run
`c126` painted 167 frames in 90 s (1.8 fps) because nothing else on that screen
was changing, which is the whole point.

The samplers are pure in the sense that matters: `(state_in) -> (sample,
events[])`. `tel_sample_tcp()` returns `(listen, clients)` from
`/proc/net/tcp`; `tel_find_pid()` returns a pid from `/proc/<pid>/cmdline`;
`tel_sample_wire()` returns the loopback device's cumulative received bytes from
`/proc/net/dev`; `tel_sample_file()` returns a file's size. None of them touches
a global, logs, or decides anything. The `* 4.0` that used to convert a byte
delta into MB/s was a hard-typed `1/0.25 s`; it is now `window_mb_s()`, derived
from `TEL_PERIOD_S`, with a halving decay instead of a snap-to-zero so one idle
sample does not read as a stall.

## Why there is no `/proc/<pid>/io` anywhere (VERIFIED, inherited defect)

The first design read `/proc/<pid>/io` for both the daemon's rate and the
watched client's progress. **The BX510 guest kernel does not have that file.**
It is built without `CONFIG_TASK_IO_ACCOUNTING`:

```
fire pio1  (evidence/bx510-guest/bdpdrv/bdpdrv-runpio1.uart.log)
  cat /res/proc/self/io   -> can't open '/res/proc/self/io': No such file or directory
  ls -l /res/proc/1/io    -> No such file or directory
  ls /res/proc            -> a real procfs (pids listed)
  grep -c . /res/proc/net/tcp -> works
```

That is not a permissions problem (the guest is root) and not a mount problem —
`/res/proc/net/tcp` and `/res/proc/net/dev` read fine. It is the kernel's
configuration, so it is a permanent property of this rig.

**The inherited defect it hid:** the pre-refactor `tel_daemon()` read the same
`/proc/<pid>/io` and logged nothing on failure, so the panel's `IO x.x MB/s`
field has ALWAYS rendered `0.0` in the guest while looking like a live gauge.
That is the silent-fake-display class the census-first rule exists for. The
reactive fire `c124` reproduced it with the new explicit model (zero progress
events, `watch_pid=0`, no error anywhere) before the sources were replaced.

## The two sources that DO exist (and what each measures)

* **EV_WIRE — `/proc/net/dev`, the `lo` row, the RECEIVED byte column.** This is
  the loopback *wire*: every byte the SACD session moves. Measured on `c126`,
  after a 1600-sector rip: `lo: 3496688 … 3496688` — on this kernel the receive
  and transmit columns carry the same number, so the rate is taken from the
  receive side; summing them would double every byte. Rate = delta over
  `TEL_PERIOD_S`, with the same decay.
  The sample: `wire_mb` → the panel's existing `IO x.x MB/s` field. The field's
  LABEL still says `IO`, because renaming it changes the rendered frame and the
  frame goldens are locked; the honest name (`WIRE`) is used in the code, the
  event trace, the log and here. The rename is a one-word `draw_frame()` change
  that lands with the layout lane's next golden re-acceptance.
* **EV_PROGRESS — `stat(SACD_UI_WATCH_FILE)`: the rip's output file size.**
  `sectors = size / 2048`, rate from the delta. A file size cannot lie about how
  far a client got, and it needs no process accounting at all. Rendered into the
  existing event log (`RIP <n> sectors <x.y> MB/s`, one line per second of event
  time, then one `RIP DONE <n> sectors` when two consecutive 250 ms samples show
  no growth) — **no layout change**, so the frame diff's allowed-motion set does
  not grow.

Neither source opens a session: the daemon's accept loop parks connections in
ONE shared slot (`decode/daemon-socket-protocol.md` §0.6), so a second
simultaneous connection would corrupt both. A `/proc` read and a `stat()` are
not connections.

## Watching a second client rip (opt-in)

```sh
SACD_UI_WATCH_FILE=/tmp/rip.bin ./sacd_ui 127.0.0.1 90
```

The UI stats that file four times a second and logs:

```
UI-EV 0013  23.20 > WATCHING /tmp/rip.bin for RIP progress
UI-EV 0017  46.89 * RIP WATCH file=/tmp/rip.bin
UI-EV 0018  48.63 > RIP 128 sectors 1.0 MB/s
UI-EV 0025  60.49 > RIP 1600 sectors 2.5 MB/s
UI-EV 0026  61.01 > RIP DONE 1600 sectors
```

(the guest's own rip, fire `c126`: 1600 requested sectors, 1600 logged.)

## Replaying a scenario (the SIM script)

The guest loop's own event stream is not reproducible (wall clock, real
`/proc`), so the `apply_event()` path is driven from a text file instead — the
same function, the same state, the same log, the same frames:

```sh
cc -O2 -std=gnu99 -Wall -DSACD_UI_SIM -I. -o /tmp/sacd_uim tools/sacd_ui.c -lm
SACD_UI_SIM_SCRIPT=/tmp/scenario.txt SACD_UI_SIM_FRAMES=/tmp/frames \
  /tmp/sacd_uim /tmp/final.ppm
```

One event per line (`#` comments and blank lines ignored):

| Line | Meaning |
|---|---|
| `tick [secs]` | advance the event clock (default `FRAME_PERIOD_S`) |
| `tcp <listen> <clients>` | one `/proc/net/tcp` sample (0/1, live count) |
| `pid <pid>` | the daemon's pid (a `/proc/<pid>/cmdline` scan) |
| `wire <bytes>` | one `/proc/net/dev lo` sample (cumulative) |
| `watch <path>` | the rip file's path (what the log names) |
| `rip <bytes>` | one `stat(<watch file>)` sample (the file's size) |
| `session ok\|fail [text]` | the startup session's outcome |

A line that changes state paints a frame (the guest rule), plus the scenario's
`t=0` frame. Painted frames land in `$SACD_UI_SIM_FRAMES/frame-NNN.ppm`, and the
end state also goes to the argv output path. The clock is the script's own
ticks — a SIM build starts the event clock at 0 and nothing on this path reads
the wall clock — so the same script renders the same bytes on any machine.

```
$ cat sc.txt
watch /tmp/rip.bin
rip 0
tick 1.0
rip 1048576
tick 1.0
rip 1048576
tick 1.0
rip 1048576
tick 1.0
rip 1048576
$ SACD_UI_SIM_SCRIPT=sc.txt SACD_UI_SIM_FRAMES=out /tmp/sacd_uim final.ppm
UI-EV 0002   0.00 * RIP WATCH file=/tmp/rip.bin
UI-EV 0003   1.00 > RIP 512 sectors 4.0 MB/s
UI-EV 0004   2.00 > RIP 512 sectors 2.0 MB/s
UI-EV 0005   3.00 > RIP DONE 512 sectors
```

## The golden, and what may move

The argv episode (`sacd_uim <mtoc> <a1> <a2> <out.ppm>`, no script) is the
seeded golden and is left exactly as it was: it sets state directly, because
routing it through `apply_event()` would add transition lines a real run would
have logged, and the rendered frame would change. Its frame is
`sha256 9f24414161b865dc97a48642433604801f954a5d0d61697fffa2bc6b0e828dcc`
(repo-relative font path — the RENDER line prints the font path, so
`SACD_UI_FONT` must stay unset or the path itself is a different frame).

Regions a state-identical frame may differ in — the live-link lamp, the blinking
cursor, and the RENDER line — have ONE machine-readable home: the layout spec's
`motion_regions` (`tools/ui_layout_spec.json`, logical 640×360 units). The C
mirrors the painter's own numbers as `LAMP_X/Y/W/H` + `CURSOR_W/H/Y` (the only
literals the painter uses for those two shapes), and
`tools/test_sacd_ui_events.py` reads the spec's tight measured boxes when the
spec is present, falls back to a deliberately generous superset otherwise, and
asserts the spec's boxes stay inside it (the lamp exactly — it is a fixed
rectangle, not a band).

## What is testable now that was not

| Before | Now |
|---|---|
| "the UI noticed a client" — a screenshot | `apply_event()` transitions as a table: tcp up/connect/gone, one log line per transition, `changed=0` on a repeated sample |
| the `* 4.0` rate conversion | `window_mb_s()` derived from `TEL_PERIOD_S`, decay tested 4.0 → 2.0 → 1.0 → 0.5 MB/s |
| a dead telemetry source could look alive | `c124` shows the `/proc/<pid>/io` source producing nothing while the panel reads 0.0; the sources now have a control that fails if the C ever reads `rchar` again |
| a RIP progress feature could not be tested at all | sector/rate math, the 1 Hz throttle and the single `RIP DONE` asserted from a scripted file |
| log order = "read the times" | monotone `seq` on every `UI-EV` line: the order is assertable |
| a repaint's stability = "looks the same" | identical event sequence → identical stdout and identical frame bytes, every run |
| what motion a frame may contain = a comment | differing pixels confined to the motion regions (and the lamp is asserted to actually blink) |
| the rendered frame itself | the argv-episode sha256 asserted in the test suite |

## Controls (all run on the Mac, no VM)

```sh
uv run pytest tools/test_sacd_ui_events.py -q     # 15 controls
CC + -DSACD_UI_SIM             -> the golden frame + the replay
CC + -DSACD_UI_EVENTS_TEST     -> the UI-EVAPP transition table (the C referee)
CC + -DSACD_UI_SPEC_DUMP       -> the layout dump (pulse_hz comes from BLINK_HZ)
```

## The guest proof (fire c126)

Scenario: `tools/bx510_ui_reactive_guest.sh.in` (the standard scenario plus one
watched second client; rendered by `tools/bx510_ui_render.py --template`, so the
FA-latch clear, the CPSA pre-arm, the tmpfs and the fbvirt node are all still
gated). Render + stage + fire:

```sh
python3 tools/bx510_ui_render.py --runid c126 \
    --template tools/bx510_ui_reactive_guest.sh.in \
    --script /tmp/bx510_ui_guest-c126.sh --out /tmp/g-c126.txt \
    --scale 6 --ui-wait 150 --ui-args '127.0.0.1 90'
sh tools/bx510_ui_stage.sh /tmp/bx510_ui_guest-c126.sh
make bx510-fire RUNID=c126 GCMD_FILE=/tmp/g-c126.txt TIMEOUT=420
make bx510-ui-shot RUNID=c126
```

VERIFIED (guest, `evidence/bx510-guest/bdpdrv/bdpdrv-runc126.uart.log`):
UI up; its own session completes (`DISC_OPEN 22238 ms`, MTOC + both area TOCs);
`LISTENER :2002 UP`; `DAEMON pid=822`; a second client connects
(`DAEMON CLIENT CONNECT (1 live)` 24.53) and rips 1600 sectors; the UI logs `RIP
128 … 1600 sectors` and `RIP DONE 1600 sectors`, then `DAEMON CLIENT GONE`
(60.49); 167 painted frames, 26 events, 0 dropped; frame artifact
`evidence/bx510-guest/graphics/ui-c126/` (pool PASS, mean luminance 12.66 —
fbdev BLACK, which is the vendor-pool painter path, not a failure).

INFERRED: nothing in the above depends on an unmeasured assumption except the
0.5 s "rip finished" hysteresis, which is a design choice (two quiet samples),
not a measurement.
