# tools/archive — historical probes and debugging programs

These are one-shot probes, debugging instruments and lane-closing repro
harnesses from the rig-building phase. They still compile/run and are part
of the negative-evidence record (see the decode docs and evidence bundles
that reference them), but they are NOT part of the reproduction path for
anything current — the active rig lives in `tools/` proper and the
`Makefile` targets are the entry points.

| File | What it was |
|---|---|
| `bx510_phase0_probe.py` | the Phase-0 guest-environment probe suite (first boots, staging discovery) |
| `bx510_rawdecode.py` | decoder for Phase-0's raw UART protocol captures |
| `bx510_sawman_probe.c` / `bx510_sawman_repro.py` | the SaWMan coexistence probe + run harness (S2 lane; outcome in `evidence/bx510-guest/graphics/sawman-run.md`) |
| `bx510_pair_debug.c` | the instrumented pair-observer variant used to root-cause the silent-miss |
| `bx510_inventory.c` | the guest inventory probe (firmware inventory reports) |
| `bx510_osai_mini.c` | the minimal OSAL exploration module |
| `bx510_dfbhello.c` | the first DirectFB "hello, panel" (vendor-contract ladder rung 0) |
| `bx510_fontprobe.c` | the font-asset discovery probe (`/res/font.bin` decode predecessor) |

Active tools live in `tools/` (indexed in `tools/README.md`). Nothing here
is referenced by a Makefile target.
