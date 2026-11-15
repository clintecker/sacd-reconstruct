# UI guest parity — uiloop6

- guest capture: `evidence/bx510-guest/bdpdrv/bdpdrv-runuiloop6.uart.log` (row step 6)
- SIM golden: `/Users/clint/code/sacd-reconstruct/evidence/bx510-guest/graphics/regress/golden/s1-full.ppm` (1920x1080)
- scene: s1-full

## per-frame, per-region

### fbdev — 320x180, row step 6, 6 damaged row(s)

| region | verdict | evidence |
|---|---|---|
| frame | FAIL | correlation undefined (a flat series); ink 0 vs golden 6898 px — the guest region carries under a quarter of the predicted ink |
| title | FAIL | correlation undefined (a flat series); ink 0 vs golden 1022 px — the guest region carries under a quarter of the predicted ink |
| status | FAIL | correlation undefined (a flat series); ink 0 vs golden 1171 px — the guest region carries under a quarter of the predicted ink |
| panel_2ch | FAIL | correlation undefined (a flat series); ink 0 vs golden 619 px — the guest region carries under a quarter of the predicted ink |
| panel_multi | FAIL | correlation undefined (a flat series); ink 0 vs golden 651 px — the guest region carries under a quarter of the predicted ink |
| rule_panels_end | PASS | correlation undefined (a flat series); ink 0 vs golden 0 px |
| log | FAIL | correlation undefined (a flat series); ink 0 vs golden 1433 px — the guest region carries under a quarter of the predicted ink |
| rule_log_end | PASS | correlation undefined (a flat series); ink 0 vs golden 0 px |
| summary | FAIL | correlation undefined (a flat series); ink 0 vs golden 1766 px — the guest region carries under a quarter of the predicted ink |

### pool — 320x180, row step 6, 4 damaged row(s)

| region | verdict | evidence |
|---|---|---|
| frame | FAIL | correlation undefined (a flat series); ink 0 vs golden 6898 px — the guest region carries under a quarter of the predicted ink |
| title | FAIL | correlation undefined (a flat series); ink 0 vs golden 1022 px — the guest region carries under a quarter of the predicted ink |
| status | FAIL | correlation undefined (a flat series); ink 0 vs golden 1171 px — the guest region carries under a quarter of the predicted ink |
| panel_2ch | FAIL | correlation undefined (a flat series); ink 0 vs golden 619 px — the guest region carries under a quarter of the predicted ink |
| panel_multi | FAIL | correlation undefined (a flat series); ink 0 vs golden 651 px — the guest region carries under a quarter of the predicted ink |
| rule_panels_end | PASS | correlation undefined (a flat series); ink 0 vs golden 0 px |
| log | FAIL | correlation undefined (a flat series); ink 0 vs golden 1433 px — the guest region carries under a quarter of the predicted ink |
| rule_log_end | PASS | correlation undefined (a flat series); ink 0 vs golden 0 px |
| summary | FAIL | correlation undefined (a flat series); ink 0 vs golden 1766 px — the guest region carries under a quarter of the predicted ink |

**verdict: FAIL** — the guest renders what the Mac predicts when every region correlates >= 0.85
