# UI animation diff — sim

- source: sequence evidence/bx510-guest/graphics/regress/anim/sim/frames (12 frames, dt=0.125)
- renderer spec: `/Users/clint/code/sacd-reconstruct/tools/ui_layout_spec.json`
- scale: 1

| frame | frame | title | status | panel_2ch | panel_multi | rule_panels_end | log | rule_log_end | summary | lamp |
|---|---|---|---|---|---|---|---|---|---|---|
| frame-000-t0.000.ppm | 0.0181 | 0.0156 | 0.0300 | 0.0216 | 0.0214 | 0.0000 | 0.0161 | 0.0000 | 0.0129 | off |
| frame-001-t0.125.ppm | 0.0181 | 0.0156 | 0.0300 | 0.0216 | 0.0214 | 0.0000 | 0.0161 | 0.0000 | 0.0129 | off |
| frame-002-t0.250.ppm | 0.0181 | 0.0156 | 0.0300 | 0.0216 | 0.0214 | 0.0000 | 0.0161 | 0.0000 | 0.0130 | off |
| frame-003-t0.375.ppm | 0.0181 | 0.0156 | 0.0300 | 0.0216 | 0.0214 | 0.0000 | 0.0161 | 0.0000 | 0.0129 | off |
| frame-004-t0.500.ppm | 0.0185 | 0.0156 | 0.0321 | 0.0216 | 0.0214 | 0.0000 | 0.0161 | 0.0000 | 0.0139 | ON |
| frame-005-t0.625.ppm | 0.0185 | 0.0156 | 0.0321 | 0.0216 | 0.0214 | 0.0000 | 0.0161 | 0.0000 | 0.0138 | ON |
| frame-006-t0.750.ppm | 0.0185 | 0.0156 | 0.0321 | 0.0216 | 0.0214 | 0.0000 | 0.0161 | 0.0000 | 0.0139 | ON |
| frame-007-t0.875.ppm | 0.0185 | 0.0156 | 0.0321 | 0.0216 | 0.0214 | 0.0000 | 0.0161 | 0.0000 | 0.0139 | ON |
| frame-008-t1.000.ppm | 0.0181 | 0.0156 | 0.0300 | 0.0216 | 0.0214 | 0.0000 | 0.0161 | 0.0000 | 0.0129 | off |
| frame-009-t1.125.ppm | 0.0181 | 0.0156 | 0.0300 | 0.0216 | 0.0214 | 0.0000 | 0.0161 | 0.0000 | 0.0130 | off |
| frame-010-t1.250.ppm | 0.0181 | 0.0156 | 0.0300 | 0.0216 | 0.0214 | 0.0000 | 0.0161 | 0.0000 | 0.0131 | off |
| frame-011-t1.375.ppm | 0.0181 | 0.0156 | 0.0300 | 0.0216 | 0.0214 | 0.0000 | 0.0161 | 0.0000 | 0.0130 | off |

## verdict

- lamp toggles 2 times over 12 frames; period 8.00 frames = a 1.000 s cycle (2.00 Hz toggle rate) vs the spec's 1.0 s cycle / 2.0 Hz toggle
- animation artifact: /Users/clint/code/sacd-reconstruct/evidence/bx510-guest/graphics/regress/anim/sim/frames.gif

**PASS**
