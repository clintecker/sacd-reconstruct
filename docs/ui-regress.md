# UI regression — deterministic layout verification for `tools/sacd_ui.c`

> Lifecycle position: rung R2 of `docs/LIFECYCLE.md` (the build/test ladder). Read that document for the gates around this one.

One spec, one renderer, five machine-computed checks. The renderer is `tools/sacd_ui.c`
(draw_frame); the contract is `tools/ui_layout_spec.json`; the referee is the frame
hashes in `evidence/bx510-guest/graphics/regress/golden/`. Nothing here is eyeballed,
and nothing here can update a golden by accident.

Labels used below: **VERIFIED** = demonstrated on this machine with the artifact named;
**INFERRED** = reasoned from evidence but not demonstrated end-to-end here.

## How to run

```sh
make ui-regress                     # A+B+C on the Mac (seconds): scenes, goldens, invariants
make ui-regress SRC=path/to/sacd_ui.c   # regress a pinned ref or a candidate renderer
make ui-golden GOLDEN=accept        # re-seed the goldens — explicit, and only this way
make ui-anim                        # D: render a SIM sequence and diff it (exact ground truth)
make ui-anim RUNID=c124 DT=0.25     # D: diff a guest fire's captured sequence
make ui-parity RUNID=c123d          # E: guest capture vs the SIM golden
make ui-regress-all                 # A-D + parity against the newest ui-<runid>
```

Direct tool form (every check is also a subcommand): `python3 tools/ui_regress.py
{regress|golden|scenes|seq|anim|parity} [--src FILE] [--aconst...]`. Stdlib only
(`zlib`, `struct`, `hashlib`, `json`, `re`) — no PIL, no numpy, same rule as
`tools/sacd_ui_gate.py`.

Fixtures: the SIM renderer reads three dd slices of the Firebird ISO (`/tmp/mtoc.bin`
20480 B, `/tmp/area1.bin`, `/tmp/area2.bin` 81920 B each; LBA 510×10, 544×40,
353804×40). The tool prints the exact recipe if they are missing, and
`SACD_UI_FIXTURES=DIR` points it elsewhere.

### The C side: `tools/sacd_ui_spec_dump.patch`

The checker must compare the spec against **what the compiled renderer actually
draws**, not against a second hand-maintained table. The patch adds a
compile-time-only mode: `spec_begin("title")` markers in `draw_frame()` plus
recording hooks in the primitives (`rect()`, `px_blend()`, and `text_top()`'s font
size), so the rects and colours are captured by the drawing calls themselves.
With `-DSACD_UI_SPEC_DUMP` the binary prints

```
SPEC canvas w=1920 h=1080 scale=3 logical=640x360 pulse_hz=2
SPEC palette C_PHOS 0x22ff66
SPEC region=panel_multi x=324 y=88 w=304 h=104 draws=17389 colors=... sizes=11,9,10
```

**VERIFIED byte-inert**: the same fixture renders to the same sha256 with and without
`-DSACD_UI_SPEC_DUMP` (`9f24414161b865dc…` for `s1-full`), and the patch applies
cleanly to `b39b521:tools/sacd_ui.c` (`git apply --check`). The suite re-proves the
inertness on every run: it builds both variants and requires equal frames.

Also in the patch: two SIM scene knobs — `SACD_UI_SIM_FAIL=1` (the failed-session
screen; the wire path reaches it through a real failed session, the SIM path has no
wire) and `SACD_UI_SIM_SEQ=N` + `SACD_UI_SIM_DT` (N frames at exactly known `t`,
for the animation analysis).

## The scene inventory

| scene | inputs | what it exercises |
|---|---|---|
| `s1-full` | all three fixture TOCs | the default screen; the event ring is **over-full** (10 events > `LOG_SHOWN`=7) so the wrap/reclip path renders |
| `s2-no-areas` | master TOC only | both panels' "no area TOC" path; a **partly filled** log (6 rows) |
| `s3-session-fail` | all three + `SACD_UI_SIM_FAIL=1` | the red DISC line and the red `SESSION FAIL` chip |
| `s4-scale1` | `SACD_UI_SCALE=1` | 640×360: scale independence |
| `s5-many-tracks` | area1's `track_count` byte forced to 9 | the `>6 rows` branch: six rows and **no** overflow row (it cannot fit — see the closed finding below) |

The many-tracks fixture is a **byte mutation of the real area TOC** (byte 69), not a
synthesised file, so the rows are the disc's own and only one field is moved. The tool
refuses if the file is not tagged `TWOCHTOC`/`MULCHTOC`.

Every scene is rendered 2× with the dump build and 1× with the plain build; the
hashes must agree (see *Determinism* below).

## What each check proves

**A — scenes.** Five full frames from real fixture bytes, each with a manifest
(`scenes/manifest.json`): argv, env, font path, geometry, frame sha256, the compile
source sha256, the spec sha256, the compiled spec dump, and per-region ink. This is
the evidence bundle for everything below.

**B — goldens.** `golden/<scene>.ppm.sha256` holds the sha256 **of the PPM bytes**;
`golden/<scene>.png` is the same frame for diffing. A default run only compares, and
a pass rewrites nothing (**VERIFIED**: golden mtimes unchanged across a passing run).
A mismatch FAILS naming the scene and writes `diff/<scene>.diff.png` (red = changed
pixel) plus a per-region table of changed-pixel counts; the region with the most
changed pixels is named, with container regions excluded so the name is a specific
band. **VERIFIED** on two deliberate breakages (below).

**C — invariants (hash-free).** These catch breakage even while an intentional change
is pending:

- *spec contract*: the committed spec vs the compiled dump — region rects (exact for
  the frame/panels/rules, containment for the text bands), the palette in both
  directions, each region's allowed colours and font sizes, the canvas and the pulse.
  This is the anti-drift check: edit a `draw_frame()` constant without the spec and
  it FAILS naming the region.
- *palette*: every colour the renderer records must be a `C_*` macro value, and every
  sampled pixel colour covering ≥200 logical px must lie on the palette **blend
  manifold** (a palette entry, or a blend of two — which is all `px_blend()` can
  produce). A hand-typed literal fails either way.
- *text floors*: each band's ink fraction must clear a floor. The 1px frame border is
  excluded from every band, because count it and a blank band passes on its own edge
  (measured: 0.034 of the title band is border alone).
- *structural rows*: the four rules (y=30/80/196/296) must be findable by 1px scans
  and must **not** still be inked two rows below (that is what makes "1px" a claim);
  the frame border must be `C_FRAME` on ≥95% of border samples.
- *scale independence*: `s4-scale1` vs `s1-full` — exact regions must match exactly,
  a band's **origin** must not move (≤3 px) and its extent may only move by glyph
  rasterisation (≤15% of the extent); per-band ink must agree within 0.015 / 35%.
- *source invariants*: the loop constants that have no drawn rect (`LOG_RING`,
  `LOG_SHOWN`, the log row geometry `212 + i*12`, the track row geometry `126 + y*11`,
  the 6-row cap) are read back out of the source with narrow regexes and compared to
  the spec. A vanished anchor is reported as an extractor break, never as a pass.

**D — animation.** Per-region ink time series, blink period from the lamp pixels
(asserted against `spec.pulse` — a 1.0 s cycle = 2 Hz toggle), the RENDER line's
per-frame change cadence (must change every frame), and **confinement**: every
frame-to-frame change must land inside `spec.motion_regions` (lamp, cursor, RENDER
line). A moving track row FAILS with the region named. A GIF is written when ffmpeg
is present (never required).

**E — parity.** A guest capture (`bx510_ui_shot.parse_frames`, `FBPIXROW` sampling)
resampled onto the logical grid, then per-region Pearson correlation of the per-row
ink series against the SIM golden, ≥0.85, with damaged/missing rows excluded and
counted separately. Fallbacks are explicit: a flat series compares total ink instead
of faking a correlation, and a region carrying under a quarter of the predicted ink
fails regardless of correlation.

## Results on this tree

**VERIFIED — the suite passes against the pinned renderer.**
`make ui-regress SRC=<b39b521 + tools/sacd_ui_spec_dump.patch>` → `verdict: PASS
(5 scenes, 0 problem(s))`. `golden/manifest.json` records what the goldens were
accepted against — renderer sha256 `206119820866bcc9…` (that renderer was the pinned
substrate at a scratch path; **the parent re-accepts once the patch is applied to
`tools/sacd_ui.c`**, which only rewrites that path field), patch
`c3e140b4c4bf6a0d…`, spec `54ffc800bca2e79f…`, font `98121878fc7fc852…`, accepted
2026-11-15T14:28:06-06:00. Frame hashes: `s1 9f24414161b865dc…`, `s2
4ea9140b99b36d4a…`, `s3 b43b1cc243bdab42…`, `s4 1eaa3f78b518b6de…`, `s5
eed6f43152521e55…`. (Those five hashes are the renderer's own fingerprint: they were
produced independently — manually, before the tool existed — and reproduce exactly.)

**VERIFIED — a deliberate breakage is caught by name, twice** (throwaway copies, never
committed; artifacts in `findings/breakage-demo/`):

1. `panel_multi`'s x moved 324 → 330: `FAIL: region panel_multi (s1-full): the
   renderer draws x=330 … but the spec says x=324` **and** `GOLDEN MISMATCH s1-full …
   3,833 changed px in panel_multi`, with `diff/s1-full.diff.png`.
2. the `y=296` rule moved to `y=293`: `FAIL: region rule_log_end … y=293 … spec says
   y=296`, `FAIL: rule y=296 (s1-full): only 0% of the row is inked — the structural
   rule is missing`, and the golden diff naming `rule_log_end` (616 changed px).

**VERIFIED — the whole suite runs as targets.** `make ui-regress-all SRC=<patched
renderer>` → regress PASS, anim PASS, then parity against the newest `ui-<runid>`
(picked automatically: `uiloop7`) FAILS with "ink 0 vs golden …" — correct, that
capture's framebuffer is black.

**VERIFIED — animation, on the SIM substrate.** `make ui-anim` renders 12 frames at
`dt=0.125` (`SACD_UI_SIM_SEQ`) and diffs them: `lamp toggles 2 times … period 8.00
frames = a 1.000 s cycle (2.00 Hz toggle rate) vs the spec's 1.0 s cycle / 2.0 Hz
toggle`, every change confined to lamp+cursor+RENDER line, GIF written →
`anim/sim/anim.md` **PASS**.

**VERIFIED — guest parity against a real guest frame.** The only capture in this repo
whose framebuffer actually carries the UI is `bdpdrv-runc123d.uart.log` (pool frame,
640×360, row step 3, 0 damaged rows). Per-region correlation vs the SIM golden:
title 1.000, panel_2ch 1.000, panel_multi 1.000, status 0.999, summary 0.999, frame
0.997, log 0.940 (different event text) → `parity/c123d/parity.md` **PASS**. That is
the "the guest renders what the Mac predicts" proof, at layout level.

**Honest negatives (kept as evidence, not skipped):**
- the later UI-loop captures (`ui-uiloop5/6/7`) carry **no UI pixels**: the pool frame
  is all-black and `uiloop6`'s fbdev frame is a red ramp (a test pattern, not the UI).
  `make ui-parity RUNID=uiloop7` therefore FAILS with "ink 0 vs golden …", which is
  the correct verdict on a black capture.
- `make ui-anim RUNID=…` on today's guest template is **NOT MEASURABLE** (exit 2): the
  template dumps one frame per buffer, and a time series needs ≥3. The SIM sequence is
  the ground-truth substrate until a multi-dump capture exists.
- **FINDING, recorded not endorsed → CLOSED (overflow-row):** with `track_count > 6`
  the `+N more` row was drawn at `y=192` — below the panel's bottom border (`y=191`)
  and across the `y=196` rule. `spec.regions[panel_2ch].declared_overflow` recorded it
  so the suite could pass while naming it. **Fix:** the six table rows are
  `126 + y*11`, so the last one ends *on* the bottom border and a seventh row has no
  room inside the `h=104` panel — the row is now SUPPRESSED, not relocated, and the
  header's `N TRACKS` line already states the full total. `declared_overflow` is
  deleted from the spec, so the exact-rect contract on `panel_2ch` is strict again and
  the `y=196` 1px-locality probe runs instead of being skipped. **Evidence**
  (`make ui-regress`, Mac only): the two notes naming the finding are gone, the
  compiled dump now reports `panel_2ch x=12 y=88 w=304 h=104` (was `h=111`), and the
  remaining pixels the fix removes are logical rows 194,195,197,198 × x=220..241 —
  exactly the `+3 more` glyphs straddling the `y=196` rule (row 196 itself was already
  repainted by the rule, so it never differed). **The `s5-many-tracks` golden frame
  therefore changes** (`8f6baec7a410cd3a…` vs golden `eed6f43152521e55…`, 31 changed
  logical px, worst named region `log` at 13) and the suite reports one
  `GOLDEN MISMATCH`; per the golden rule the frames were NOT re-seeded — that
  re-accept is the human `make ui-golden GOLDEN=accept` step.

## Determinism — and why the suite retries

`draw_frame()` prints `ev_log()` timestamps read from `CLOCK_MONOTONIC` at `%6.2f`
(10 ms granularity). Under load a log row reads `0.01` instead of `0.00` and the frame
changes — **VERIFIED**: `findings/nondeterministic-s2-render.png` is a `s2-no-areas`
frame whose only difference from the accepted one is 102 rows in the event-log band.
Hash goldens are therefore guarded: a scene is rendered until two consecutive frames
agree (≤4 tries) and the plain build must equal the dump build; only then is the hash
trusted. The attempt counts land in `scenes/manifest.json` (`determinism`), so a
machine that needed retries is visible instead of invisible in a green run. The
event-clock work in `tools/sacd_ui.c` (`EV_TICK`, the SIM clock) removes the
dependency; after it lands the control should never trip.

## Artifact map

```
evidence/bx510-guest/graphics/regress/
  report.md                  the run's verdict, per-scene hashes, per-region ink, failures
  scenes/manifest.json       the scene evidence bundle (inputs, dumps, ink, determinism)
  scenes/fixtures/           the mutated many-tracks fixture (byte-mutated real TOC)
  golden/<scene>.ppm.sha256  THE referee (hash of the PPM bytes)
  golden/<scene>.png         the accepted frame, for diffing
  golden/manifest.json       who/what/when: renderer, patch, spec, font shas + per-scene ink
  diff/<scene>.diff.png      written only on a mismatch (red = changed pixel)
  anim/<runid>/anim.md       the animation verdict (+ frames.gif)
  parity/<runid>/parity.md   the guest-vs-SIM correlation table
  findings/                  the retained negatives and the two breakage demos
```

`scenes/*.ppm` and `anim/*/frames/*.ppm` are transient render output (6 MB per
1080p frame); everything with a verdict is kept.

## Tests

`tools/test_ui_regress.py` (18 tests, in `uv run pytest -m "not smoke"`): a
spec-conforming synthetic frame passes; a missing rule, a blank band, a rogue colour,
a shifted region and an undeclared region each FAIL **with the expected name**; the
loop-constant extractor fails loudly when its anchor is gone; blink-period and
confinement maths on synthetic series; a moving track row is caught; `golden` without
`--accept` refuses; the make targets exist and run in order.
