# UI animation diff — uiloop7

- source: guest capture evidence/bx510-guest/bdpdrv/bdpdrv-runuiloop7.uart.log (2 frame(s), device row step 6 = 2 logical row(s)/sample, dt=UNKNOWN)
- renderer spec: `/Users/you/code/sacd-reconstruct/tools/ui_layout_spec.json`
- scale: 1

| frame | frame | title | status | panel_2ch | panel_multi | rule_panels_end | log | rule_log_end | summary | lamp |
|---|---|---|---|---|---|---|---|---|---|---|
| fbdev-320x180 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | off |
| pool-320x180 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | off |

## verdict

- FAIL the capture carries 2 frame(s): a time series needs >= 3. The guest template dumps one frame per buffer (tools/bx510_ui_guest.sh.in step 10), so a guest animation run needs a multi-dump capture; a SIM sequence (make ui-regress-anim -> SACD_UI_SIM_SEQ/SACD_UI_SIM_DT) is the ground-truth substrate today

**NOT MEASURABLE (capture fault)**
