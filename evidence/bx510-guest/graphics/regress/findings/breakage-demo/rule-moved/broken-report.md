# UI layout regression — FAIL

- renderer: `/tmp/pin/broken.c` sha256 `3f738d2fb56cb95ebb0f38603f13c8b2e44033326981d361e6420a477e529ad3`
- spec: `/Users/clint/code/sacd-reconstruct/tools/ui_layout_spec.json` sha256 `54ffc800bca2e79fd03befece41186632e6a13a9e90e89f669fbf8e9e7acdd22`
- font: `/Users/clint/code/sacd-reconstruct/evidence/bx510/display-payload/sony-font.ttf` sha256 `98121878fc7fc85205aa6b62bd40d9fb478b3629e62ec4f947c80ec9830d7fd9`
- run: 2026-11-15T14:31:46-06:00

## scenes

| scene | geometry | sha256 | about |
|---|---|---|---|
| s1-full | 1920x1080 | `f75adfee1b0bfec4…` | all three fixture TOC files — the default SIM scene |
| s2-no-areas | 1920x1080 | `b0466206e78f2949…` | master TOC only: both panels take the 'no area TOC' path |
| s3-session-fail | 1920x1080 | `c290f8141fa6d822…` | the failed-session screen (red DISC line + red state chip) |
| s4-scale1 | 640x360 | `b13c862bb9573f37…` | 640x360 (scale 1): scale independence |
| s5-many-tracks | 1920x1080 | `2df733d8bd9265bc…` | area1 track_count forced to 9: six rows + the '+3 more' row |

## per-region ink (sampled logical grid)

| scene | frame | title | status | panel_2ch | panel_multi | rule_panels_end | log | rule_log_end | summary |
|---|---|---|---|---|---|---|---|---|---|
| s1-full | 0.0215 | 0.0162 | 0.0343 | 0.0196 | 0.0206 | 0.0000 | 0.0198 | 0.0000 | 0.0253 |
| s2-no-areas | 0.0167 | 0.0162 | 0.0343 | 0.0025 | 0.0035 | 0.0000 | 0.0198 | 0.0000 | 0.0247 |
| s3-session-fail | 0.0203 | 0.0162 | 0.0260 | 0.0196 | 0.0206 | 0.0000 | 0.0198 | 0.0000 | 0.0251 |
| s4-scale1 | 0.0185 | 0.0156 | 0.0321 | 0.0216 | 0.0214 | 0.0000 | 0.0161 | 0.0000 | 0.0138 |
| s5-many-tracks | 0.0215 | 0.0162 | 0.0343 | 0.0196 | 0.0206 | 0.0000 | 0.0198 | 0.0000 | 0.0253 |

## notes / recorded findings

- FINDING region panel_2ch (s5-many-tracks): drawn x=12 y=88 w=304 h=111 != spec (12, 88, 304, 104) but inside a declared_overflow — see spec.declared_overflow
- rule y=196 (s5-many-tracks): 1px-locality probe skipped — row 198 is inside the declared overflow 'more_row'
- scale independence title: ink 0.0156 vs 0.0162, bbox drift 1px
- scale independence status: ink 0.0321 vs 0.0343, bbox drift 0px
- scale independence log: ink 0.0161 vs 0.0198, bbox drift 15px
- scale independence summary: ink 0.0138 vs 0.0253, bbox drift 0px

## FAILURES

- region rule_log_end (s1-full): the renderer draws x=12 y=293 w=616 h=1 but the spec says x=12 y=296 w=616 h=1
- rule y=296 (s1-full): only 0% of the row is inked — the structural rule is missing
- region rule_log_end (s2-no-areas): the renderer draws x=12 y=293 w=616 h=1 but the spec says x=12 y=296 w=616 h=1
- rule y=296 (s2-no-areas): only 0% of the row is inked — the structural rule is missing
- region rule_log_end (s3-session-fail): the renderer draws x=12 y=293 w=616 h=1 but the spec says x=12 y=296 w=616 h=1
- rule y=296 (s3-session-fail): only 0% of the row is inked — the structural rule is missing
- region rule_log_end (s4-scale1): the renderer draws x=12 y=293 w=616 h=1 but the spec says x=12 y=296 w=616 h=1
- rule y=296 (s4-scale1): only 0% of the row is inked — the structural rule is missing
- region rule_log_end (s5-many-tracks): the renderer draws x=12 y=293 w=616 h=1 but the spec says x=12 y=296 w=616 h=1
- rule y=296 (s5-many-tracks): only 0% of the row is inked — the structural rule is missing
- GOLDEN MISMATCH s1-full: f75adfee1b0bfec4… != golden 9f24414161b865dc… — 11,088 px changed, worst region rule_log_end (616 changed px); diff: /Users/clint/code/sacd-reconstruct/evidence/bx510-guest/graphics/regress/diff/s1-full.diff.png
- GOLDEN MISMATCH s2-no-areas: b0466206e78f2949… != golden 4ea9140b99b36d4a… — 11,088 px changed, worst region rule_log_end (616 changed px); diff: /Users/clint/code/sacd-reconstruct/evidence/bx510-guest/graphics/regress/diff/s2-no-areas.diff.png
- GOLDEN MISMATCH s3-session-fail: c290f8141fa6d822… != golden b43b1cc243bdab42… — 11,088 px changed, worst region rule_log_end (616 changed px); diff: /Users/clint/code/sacd-reconstruct/evidence/bx510-guest/graphics/regress/diff/s3-session-fail.diff.png
- GOLDEN MISMATCH s4-scale1: b13c862bb9573f37… != golden 1eaa3f78b518b6de… — 1,232 px changed, worst region rule_log_end (616 changed px); diff: /Users/clint/code/sacd-reconstruct/evidence/bx510-guest/graphics/regress/diff/s4-scale1.diff.png
- GOLDEN MISMATCH s5-many-tracks: 2df733d8bd9265bc… != golden eed6f43152521e55… — 11,088 px changed, worst region rule_log_end (616 changed px); diff: /Users/clint/code/sacd-reconstruct/evidence/bx510-guest/graphics/regress/diff/s5-many-tracks.diff.png

## golden mismatch, per-region ink


#### s1-full

| region | changed px | golden ink | now ink | ink delta |
|---|---|---|---|---|
| frame | 1232 | 0.0215 | 0.0215 | +0.0000 |
| title | 0 | 0.0162 | 0.0162 | +0.0000 |
| status | 0 | 0.0343 | 0.0343 | +0.0000 |
| panel_2ch | 0 | 0.0196 | 0.0196 | +0.0000 |
| panel_multi | 0 | 0.0206 | 0.0206 | +0.0000 |
| rule_panels_end | 0 | 0.0000 | 0.0000 | +0.0000 |
| log | 616 | 0.0198 | 0.0198 | -0.0000 |
| rule_log_end | 616 | 0.0000 | 0.0000 | +0.0000 |
| summary | 0 | 0.0253 | 0.0253 | -0.0000 |

#### s2-no-areas

| region | changed px | golden ink | now ink | ink delta |
|---|---|---|---|---|
| frame | 1232 | 0.0167 | 0.0167 | -0.0000 |
| title | 0 | 0.0162 | 0.0162 | +0.0000 |
| status | 0 | 0.0343 | 0.0343 | +0.0000 |
| panel_2ch | 0 | 0.0025 | 0.0025 | -0.0000 |
| panel_multi | 0 | 0.0035 | 0.0035 | +0.0000 |
| rule_panels_end | 0 | 0.0000 | 0.0000 | +0.0000 |
| log | 616 | 0.0198 | 0.0198 | -0.0000 |
| rule_log_end | 616 | 0.0000 | 0.0000 | +0.0000 |
| summary | 0 | 0.0247 | 0.0247 | -0.0000 |

#### s3-session-fail

| region | changed px | golden ink | now ink | ink delta |
|---|---|---|---|---|
| frame | 1232 | 0.0203 | 0.0203 | -0.0000 |
| title | 0 | 0.0162 | 0.0162 | +0.0000 |
| status | 0 | 0.0260 | 0.0260 | -0.0000 |
| panel_2ch | 0 | 0.0196 | 0.0196 | +0.0000 |
| panel_multi | 0 | 0.0206 | 0.0206 | +0.0000 |
| rule_panels_end | 0 | 0.0000 | 0.0000 | +0.0000 |
| log | 616 | 0.0198 | 0.0198 | -0.0000 |
| rule_log_end | 616 | 0.0000 | 0.0000 | +0.0000 |
| summary | 0 | 0.0251 | 0.0251 | +0.0000 |

#### s4-scale1

| region | changed px | golden ink | now ink | ink delta |
|---|---|---|---|---|
| frame | 1232 | 0.0185 | 0.0185 | +0.0000 |
| title | 0 | 0.0156 | 0.0156 | -0.0000 |
| status | 0 | 0.0321 | 0.0321 | +0.0000 |
| panel_2ch | 0 | 0.0216 | 0.0216 | +0.0000 |
| panel_multi | 0 | 0.0214 | 0.0214 | +0.0000 |
| rule_panels_end | 0 | 0.0000 | 0.0000 | +0.0000 |
| log | 616 | 0.0161 | 0.0161 | +0.0000 |
| rule_log_end | 616 | 0.0000 | 0.0000 | +0.0000 |
| summary | 0 | 0.0138 | 0.0138 | +0.0000 |

#### s5-many-tracks

| region | changed px | golden ink | now ink | ink delta |
|---|---|---|---|---|
| frame | 1232 | 0.0215 | 0.0215 | -0.0000 |
| title | 0 | 0.0162 | 0.0162 | +0.0000 |
| status | 0 | 0.0343 | 0.0343 | +0.0000 |
| panel_2ch | 0 | 0.0196 | 0.0196 | +0.0000 |
| panel_multi | 0 | 0.0206 | 0.0206 | +0.0000 |
| rule_panels_end | 0 | 0.0000 | 0.0000 | +0.0000 |
| log | 616 | 0.0198 | 0.0198 | -0.0000 |
| rule_log_end | 616 | 0.0000 | 0.0000 | +0.0000 |
| summary | 0 | 0.0253 | 0.0253 | -0.0000 |
