# UI layout regression — FAIL

- renderer: `/tmp/pin/broken.c` sha256 `1ae164c352f397f85e36c1a6d862fd01ae6b5d7994500b5c79b75355371e7d87`
- spec: `/Users/you/code/sacd-reconstruct/tools/ui_layout_spec.json` sha256 `ae3d49398421459fb1732fc68fdd22b1755a504ee43c3d6c3c13396ade4ef32f`
- font: `/Users/you/code/sacd-reconstruct/evidence/bx510/display-payload/sony-font.ttf` sha256 `98121878fc7fc85205aa6b62bd40d9fb478b3629e62ec4f947c80ec9830d7fd9`
- run: 2026-11-15T14:03:50-06:00

## scenes

| scene | geometry | sha256 | about |
|---|---|---|---|
| s1-full | 1920x1080 | `3d9cb8d87ebe0e17…` | all three fixture TOC files — the default SIM scene |
| s2-no-areas | 1920x1080 | `b6d4d19880b9432d…` | master TOC only: both panels take the 'no area TOC' path |
| s3-session-fail | 1920x1080 | `2e7ce5022f16d618…` | the failed-session screen (red DISC line + red state chip) |
| s4-scale1 | 640x360 | `575974d81bdff433…` | 640x360 (scale 1): scale independence |
| s5-many-tracks | 1920x1080 | `d1283bbf0ecfa92d…` | area1 track_count forced to 9: six rows + the '+3 more' row |

## per-region ink (sampled logical grid)

| scene | frame | title | status | panel_2ch | panel_multi | rule_panels_end | log | rule_log_end | summary |
|---|---|---|---|---|---|---|---|---|---|
| s1-full | 0.0299 | 0.0499 | 0.0373 | 0.0196 | 0.0206 | 0.0000 | 0.0228 | 0.0000 | 0.0438 |
| s2-no-areas | 0.0252 | 0.0499 | 0.0373 | 0.0025 | 0.0035 | 0.0000 | 0.0229 | 0.0000 | 0.0432 |
| s3-session-fail | 0.0288 | 0.0499 | 0.0290 | 0.0196 | 0.0206 | 0.0000 | 0.0228 | 0.0000 | 0.0436 |
| s4-scale1 | 0.0270 | 0.0494 | 0.0351 | 0.0216 | 0.0214 | 0.0000 | 0.0192 | 0.0000 | 0.0325 |
| s5-many-tracks | 0.0300 | 0.0499 | 0.0373 | 0.0196 | 0.0206 | 0.0000 | 0.0229 | 0.0000 | 0.0438 |

## notes / recorded findings

- FINDING region panel_2ch (s5-many-tracks): drawn x=12 y=88 w=304 h=111 != spec (12, 88, 304, 104) but inside a declared_overflow — see spec.declared_overflow
- rule y=196 (s5-many-tracks): 1px-locality probe skipped — row 198 is inside the declared overflow 'more_row'
- scale independence title: ink 0.0494 vs 0.0499, bbox drift 1px
- scale independence status: ink 0.0351 vs 0.0373, bbox drift 0px
- scale independence log: ink 0.0192 vs 0.0228, bbox drift 15px
- scale independence summary: ink 0.0325 vs 0.0438, bbox drift 0px

## FAILURES

- region panel_multi (s1-full): the renderer draws x=330 y=88 w=304 h=104 but the spec says x=324 y=88 w=304 h=104
- region panel_multi (s2-no-areas): the renderer draws x=330 y=88 w=304 h=104 but the spec says x=324 y=88 w=304 h=104
- region panel_multi (s3-session-fail): the renderer draws x=330 y=88 w=304 h=104 but the spec says x=324 y=88 w=304 h=104
- region panel_multi (s4-scale1): the renderer draws x=330 y=88 w=304 h=104 but the spec says x=324 y=88 w=304 h=104
- region panel_multi (s5-many-tracks): the renderer draws x=330 y=88 w=304 h=104 but the spec says x=324 y=88 w=304 h=104
- GOLDEN MISMATCH s1-full: 3d9cb8d87ebe0e17… != golden 9f24414161b865dc… — 40,384 px changed, worst region panel_multi (3,833 changed px); diff: /Users/you/code/sacd-reconstruct/evidence/bx510-guest/graphics/regress/diff/s1-full.diff.png
- GOLDEN MISMATCH s2-no-areas: b6d4d19880b9432d… != golden 4ea9140b99b36d4a… — 17,098 px changed, worst region panel_multi (1,292 changed px); diff: /Users/you/code/sacd-reconstruct/evidence/bx510-guest/graphics/regress/diff/s2-no-areas.diff.png
- GOLDEN MISMATCH s3-session-fail: 2e7ce5022f16d618… != golden b43b1cc243bdab42… — 40,384 px changed, worst region panel_multi (3,833 changed px); diff: /Users/you/code/sacd-reconstruct/evidence/bx510-guest/graphics/regress/diff/s3-session-fail.diff.png
- GOLDEN MISMATCH s4-scale1: 575974d81bdff433… != golden 1eaa3f78b518b6de… — 5,787 px changed, worst region panel_multi (5,163 changed px); diff: /Users/you/code/sacd-reconstruct/evidence/bx510-guest/graphics/regress/diff/s4-scale1.diff.png
- GOLDEN MISMATCH s5-many-tracks: d1283bbf0ecfa92d… != golden eed6f43152521e55… — 40,384 px changed, worst region panel_multi (3,833 changed px); diff: /Users/you/code/sacd-reconstruct/evidence/bx510-guest/graphics/regress/diff/s5-many-tracks.diff.png

## golden mismatch, per-region ink


#### s1-full

| region | changed px | golden ink | now ink | ink delta |
|---|---|---|---|---|
| frame | 4457 | 0.0299 | 0.0299 | -0.0000 |
| title | 0 | 0.0499 | 0.0499 | -0.0000 |
| status | 0 | 0.0373 | 0.0373 | +0.0000 |
| panel_2ch | 0 | 0.0196 | 0.0196 | +0.0000 |
| panel_multi | 3833 | 0.0206 | 0.0206 | +0.0000 |
| rule_panels_end | 0 | 0.0000 | 0.0000 | +0.0000 |
| log | 0 | 0.0228 | 0.0228 | +0.0000 |
| rule_log_end | 0 | 0.0000 | 0.0000 | +0.0000 |
| summary | 0 | 0.0438 | 0.0438 | +0.0000 |

#### s2-no-areas

| region | changed px | golden ink | now ink | ink delta |
|---|---|---|---|---|
| frame | 1916 | 0.0252 | 0.0252 | -0.0000 |
| title | 0 | 0.0499 | 0.0499 | -0.0000 |
| status | 0 | 0.0373 | 0.0373 | +0.0000 |
| panel_2ch | 0 | 0.0025 | 0.0025 | -0.0000 |
| panel_multi | 1292 | 0.0035 | 0.0035 | +0.0000 |
| rule_panels_end | 0 | 0.0000 | 0.0000 | +0.0000 |
| log | 0 | 0.0229 | 0.0229 | -0.0000 |
| rule_log_end | 0 | 0.0000 | 0.0000 | +0.0000 |
| summary | 0 | 0.0432 | 0.0432 | -0.0000 |

#### s3-session-fail

| region | changed px | golden ink | now ink | ink delta |
|---|---|---|---|---|
| frame | 4457 | 0.0288 | 0.0288 | +0.0000 |
| title | 0 | 0.0499 | 0.0499 | -0.0000 |
| status | 0 | 0.0290 | 0.0290 | +0.0000 |
| panel_2ch | 0 | 0.0196 | 0.0196 | +0.0000 |
| panel_multi | 3833 | 0.0206 | 0.0206 | +0.0000 |
| rule_panels_end | 0 | 0.0000 | 0.0000 | +0.0000 |
| log | 0 | 0.0228 | 0.0228 | +0.0000 |
| rule_log_end | 0 | 0.0000 | 0.0000 | +0.0000 |
| summary | 0 | 0.0436 | 0.0436 | -0.0000 |

#### s4-scale1

| region | changed px | golden ink | now ink | ink delta |
|---|---|---|---|---|
| frame | 5787 | 0.0270 | 0.0270 | +0.0000 |
| title | 0 | 0.0494 | 0.0494 | -0.0000 |
| status | 0 | 0.0351 | 0.0351 | +0.0000 |
| panel_2ch | 0 | 0.0216 | 0.0216 | +0.0000 |
| panel_multi | 5163 | 0.0214 | 0.0214 | +0.0000 |
| rule_panels_end | 0 | 0.0000 | 0.0000 | +0.0000 |
| log | 0 | 0.0192 | 0.0192 | -0.0000 |
| rule_log_end | 0 | 0.0000 | 0.0000 | +0.0000 |
| summary | 0 | 0.0325 | 0.0325 | -0.0000 |

#### s5-many-tracks

| region | changed px | golden ink | now ink | ink delta |
|---|---|---|---|---|
| frame | 4457 | 0.0300 | 0.0300 | +0.0000 |
| title | 0 | 0.0499 | 0.0499 | -0.0000 |
| status | 0 | 0.0373 | 0.0373 | +0.0000 |
| panel_2ch | 0 | 0.0196 | 0.0196 | +0.0000 |
| panel_multi | 3833 | 0.0206 | 0.0206 | +0.0000 |
| rule_panels_end | 0 | 0.0000 | 0.0000 | +0.0000 |
| log | 0 | 0.0229 | 0.0229 | -0.0000 |
| rule_log_end | 0 | 0.0000 | 0.0000 | +0.0000 |
| summary | 0 | 0.0438 | 0.0438 | +0.0000 |
