# Third-party components

Only what is actually vendored, and why.

| Component | Where | Licence | Note |
|---|---|---|---|
| `stb_truetype.h` | `tools/third_party/` | Public domain (Sean Barrett) | TrueType rasteriser for the on-panel HUD |
| `font8x8_basic.h` | `tools/third_party/` | Public domain (Daniel Hepper / Marcel Sondaar) | 8×8 bitmap face for the retro HUD canvas |
| Tiresias Screenfont | `evidence/bx510/display-payload/sony-font.ttf` | Freely distributable screen font (Tiresias, Dr John Gill / RNIB lineage) | Carved from the player's own `/res/font.bin`; used for the HUD's earlier TTF layout. Kept because it is the device's real typeface |
| LuaSocket-derived socket helpers | `reconstruct/libcommon/` | MIT (LuaSocket) | Present in the original daemon's static image; reconstructed from behaviour |

Not vendored, referenced only:

- **yarn** (Mark Adler's C threading library) — used by the original binary; the
  reconstruction reproduces the needed behaviour in `reconstruct/libcommon/`.
- **libdirectfb / DirectFB 1.2.7** — the player's own graphics stack; the HUD
  links against the *device's* copy, none is shipped here.
- **nanopb-era protobuf encode/decode** — reconstructed as `sacd_pb_*` sources.
