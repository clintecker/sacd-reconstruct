# UI layout regression — PASS

- renderer: `tools/sacd_ui.c` sha256 `8bf52cf15da68f0ebed8f77a35eb3aecb36a29ab133479bbec53d1e5e1328137`
- spec: `/Users/clint/code/sacd-reconstruct/tools/ui_layout_spec.json` sha256 `09f6c3f31f34b2f8a7cee8eeb2afd0baaf934e895b2b03656f35c7ef86fd7086`
- font: `/Users/clint/code/sacd-reconstruct/evidence/bx510/display-payload/sony-font.ttf` sha256 `98121878fc7fc85205aa6b62bd40d9fb478b3629e62ec4f947c80ec9830d7fd9`
- run: 2026-11-16T10:21:11-06:00

## scenes

| scene | geometry | sha256 | about |
|---|---|---|---|
| s1-full | 1920x1080 | `9f24414161b865dc…` | all three fixture TOC files — the default SIM scene |
| s2-no-areas | 1920x1080 | `4ea9140b99b36d4a…` | master TOC only: both panels take the 'no area TOC' path |
| s3-session-fail | 1920x1080 | `b43b1cc243bdab42…` | the failed-session screen (red DISC line + red state chip) |
| s4-scale1 | 640x360 | `1eaa3f78b518b6de…` | 640x360 (scale 1): scale independence |
| s5-many-tracks | 1920x1080 | `8f6baec7a410cd3a…` | area1 track_count forced to 9: six rows, the overflow row suppressed |

## per-region ink (sampled logical grid)

| scene | frame | title | status | panel_2ch | panel_multi | rule_panels_end | log | rule_log_end | summary |
|---|---|---|---|---|---|---|---|---|---|
| s1-full | 0.0215 | 0.0162 | 0.0343 | 0.0196 | 0.0206 | 0.0000 | 0.0198 | 0.0000 | 0.0253 |
| s2-no-areas | 0.0167 | 0.0162 | 0.0343 | 0.0025 | 0.0035 | 0.0000 | 0.0198 | 0.0000 | 0.0247 |
| s3-session-fail | 0.0203 | 0.0162 | 0.0260 | 0.0196 | 0.0206 | 0.0000 | 0.0198 | 0.0000 | 0.0251 |
| s4-scale1 | 0.0185 | 0.0156 | 0.0321 | 0.0216 | 0.0214 | 0.0000 | 0.0161 | 0.0000 | 0.0138 |
| s5-many-tracks | 0.0214 | 0.0162 | 0.0343 | 0.0196 | 0.0206 | 0.0000 | 0.0197 | 0.0000 | 0.0253 |

## notes / recorded findings

- scale independence title: ink 0.0156 vs 0.0162, bbox drift 1px
- scale independence status: ink 0.0321 vs 0.0343, bbox drift 0px
- scale independence log: ink 0.0161 vs 0.0198, bbox drift 15px
- scale independence summary: ink 0.0138 vs 0.0253, bbox drift 0px
