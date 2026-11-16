# UI shot — run hudisc4

capture: `evidence/bx510-guest/bdpdrv/bdpdrv-runhudisc4.uart.log` (UART transcript)

| frame | buffer | geometry | mean luminance | verdict | png |
|---|---|---|---|---|---|
| pool | /dev/fb0(pool) | 320x180 | 13.17 | PASS | `pool-320x180.png` |
| fbdev | /dev/fb0 | 320x180 | 0.00 | BLACK | `fbdev-320x180.png` |
| pool | /dev/fb0(pool) | 320x180 | 13.54 | PASS | `pool-320x180.png` |

animation: `frames.gif` (3 frames)

## run markers

- `FA_MODE`: `FA_MODE fa=0 rc=0 be_quiet=0 rc=0`
- `DAEMON_PID`: `DAEMON_PID=822`
- `UI_SCALE`: `UI_SCALE=6`
- `UI_DUMP_FBDEV`: `UI_DUMP_FBDEV=0`
- `UI_DUMP_POOL`: `UI_DUMP_POOL=0`
- `UI_SHOT_DONE`: `UI_SHOT_DONE`
- absent: FIRE_RC, DAEMON_ORACLE, CLIENT_RC, CLIENT_PASS, UI_RC, UI_PID

**verdict: PASS** — pool: mean luminance 13.17 -> PASS (8 of 180 sampled rows lost to console interleaving; zero-filled — geometry 1920x1080 / 6); fbdev: mean luminance 0.00 -> BLACK (11 of 180 sampled rows lost to console interleaving; zero-filled — geometry 1920x1080 / 6); pool: mean luminance 13.54 -> PASS (7 of 180 sampled rows lost to console interleaving; zero-filled — geometry 1920x1080 / 6)
