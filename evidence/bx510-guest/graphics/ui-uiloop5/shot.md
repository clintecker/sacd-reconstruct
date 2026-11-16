# UI shot — run uiloop5

capture: `evidence/bx510-guest/bdpdrv/bdpdrv-runuiloop5.uart.log` (UART transcript)

| frame | buffer | geometry | mean luminance | verdict | png |
|---|---|---|---|---|---|
| pool | /dev/fb0(pool) | 320x180 | 0.00 | BLACK | `pool-320x180.png` |

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

**capture fault:** fbdev: FBPIX holds 9209 pixels, sampled geometry says 320x180=57600 (the dump was truncated — a short UART read, not a blank screen)

**capture fault:** pool row 78: FBPIX holds 240 pixels, sampled geometry says 320x1=320 (the dump was truncated — a short UART read, not a blank screen)

**capture fault:** pool row 474: FBPIX holds 130 pixels, sampled geometry says 320x1=320 (the dump was truncated — a short UART read, not a blank screen)

**capture fault:** pool row 636: FBPIX holds 301 pixels, sampled geometry says 320x1=320 (the dump was truncated — a short UART read, not a blank screen)

**capture fault:** pool row 960: FBPIX holds 303 pixels, sampled geometry says 320x1=320 (the dump was truncated — a short UART read, not a blank screen)

**verdict: FAIL (with a capture fault)** — pool: mean luminance 0.00 -> BLACK (4 of 180 sampled rows lost to console interleaving; zero-filled — geometry 1920x1080 / 6)
