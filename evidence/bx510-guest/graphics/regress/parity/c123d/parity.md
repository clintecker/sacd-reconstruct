# UI guest parity — c123d

- guest capture: `evidence/bx510-guest/bdpdrv/bdpdrv-runc123d.uart.log` (row step 3)
- SIM golden: `/Users/clint/code/sacd-reconstruct/evidence/bx510-guest/graphics/regress/golden/s1-full.png` (1920x1080)
- scene: s1-full

## per-frame, per-region

### pool — 640x360, row step 3, 0 damaged row(s)

| region | verdict | evidence |
|---|---|---|
| frame | PASS | corr 0.997 over 360 rows; ink 6864 vs golden 6898 px |
| title | PASS | corr 1.000 over 32 rows; ink 1022 vs golden 1022 px |
| status | PASS | corr 0.999 over 49 rows; ink 1161 vs golden 1171 px |
| panel_2ch | PASS | corr 1.000 over 104 rows; ink 619 vs golden 619 px |
| panel_multi | PASS | corr 1.000 over 104 rows; ink 651 vs golden 651 px |
| rule_panels_end | PASS | correlation undefined (a flat series); ink 0 vs golden 0 px |
| log | PASS | corr 0.940 over 98 rows; ink 1545 vs golden 1433 px |
| rule_log_end | PASS | correlation undefined (a flat series); ink 0 vs golden 0 px |
| summary | PASS | corr 0.999 over 63 rows; ink 1630 vs golden 1766 px |

**verdict: PASS** — the guest renders what the Mac predicts when every region correlates >= 0.85

weakest region: log (corr 0.940)
