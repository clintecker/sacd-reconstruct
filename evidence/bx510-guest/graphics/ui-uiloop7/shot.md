# UI shot — run uiloop7

capture: `evidence/bx510-guest/bdpdrv/bdpdrv-runuiloop7.uart.log` (UART transcript)

| frame | buffer | geometry | mean luminance | verdict | png |
|---|---|---|---|---|---|
| fbdev | /dev/fb0 | 320x180 | 0.00 | BLACK | `fbdev-320x180.png` |
| pool | /dev/fb0(pool) | 320x180 | 0.00 | BLACK | `pool-320x180.png` |

animation: `frames.gif` (2 frames)

## run markers

- `FA_MODE`: `FA_MODE fa=0 rc=0 be_quiet=0 rc=0`
- `DAEMON_PID`: `DAEMON_PID=822`
- `CLIENT_RC`: `CLIENT_RC=0`
- `CLIENT_PASS`: `CLIENT_PASS`
- `UI_SCALE`: `UI_SCALE=6`
- `UI_DUMP_FBDEV`: `UI_DUMP_FBDEV=0`
- `UI_DUMP_POOL`: `UI_DUMP_POOL=0`
- `UI_SHOT_DONE`: `UI_SHOT_DONE`
- `UI_PID`: `UI_PID=836`
- absent: FIRE_RC, DAEMON_ORACLE, UI_RC

**verdict: FAIL** — fbdev: mean luminance 0.00 -> BLACK (4 of 180 sampled rows lost to console interleaving; zero-filled — geometry 1920x1080 / 6); pool: mean luminance 0.00 -> BLACK (7 of 180 sampled rows lost to console interleaving; zero-filled — geometry 1920x1080 / 6)
