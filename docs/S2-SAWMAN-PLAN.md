# S2 experiment plan — SaWMan coexistence: a second app over the appliance UI

Status: plan (2026-11-09, reviewed against the shipped rootfs evidence).
Predecessor: S3 (DONE — guest gate green, ring pixel-verified).

## The question

Can a second DirectFB application run **alongside** the appliance UI
(bdpprog/X2) instead of taking the panel over — with the UI returning
when the second app exits? This is the product-grade coexistence answer:
a HUD that appears over the stock UI rather than instead of it.

## Ground truth already in hand (VERIFIED)

- `/usr/etc/directfbrc` (shipped rootfs): `wm = sawman` — the shipped
  configuration selects the SaWMan window manager. Also: two layers
  configured (graphics layer 0, middle/upper stacking; video layer 1,
  lower stacking, frontonly buffers), `no-cursor`, `no-sighandler`,
  fifo threading.
- `bdpprog` strings: `AWM_TEST_MODE_FLAG`, `awm_clear`, `wm_msg_q`,
  `wm_thread` — the appliance host talks SaWMan's own API (awm_*).
- `libdirectfbwm_sawman.so` exports `directfbwm_sawman` and uses
  fusion skirmishes/refs (`fusion_skirmish_prevail`,
  `fusion_ref_up/down`, `sawman_update_window`,
  `sawman_window_border`).
- `fusion.ko` loads cleanly in our guest (proven in the S2/S3 rungs);
  multi-app core initialized in prior rungs ("Multi Application Core"
  in the init log).
- MT85-RESULTS.md recorded DirectFB reporting "SaWMan layers" during a
  rig run.

## Design of the experiment (rig: QEMU guest, no hardware)

Build ONE new probe: `tools/bx510_sawman_probe.c` — a second DirectFB
client that does NOT take over:

1. `DirectFBInit` + `DirectFBCreate` (same as dfbhello — proven path).
2. Instead of `GetDisplayLayer`+`CreateSurface` on the primary:
   `CreateWindow(width, height, DWDESC_*)` → `GetSurface` → draw a
   recognizable pattern (colour bars + label) → `Flip`.
3. Hold for N seconds, then `DestroyWindow` and exit cleanly.
4. Print markers at each step so the UART log is the evidence.

Runs, in this order (controls first, every suite):

- **Control A (unchanged gate)**: the existing guest-gate HUD run must
  still PASS — proves the probe rig didn't disturb the proven path.
- **Rung S1 — sawman loads**: run the probe with the shipped
  `directfbrc` (`wm = sawman`). Log must show the WM module loading
  and the window creation succeeding. Record the layer/stacking state
  the log reports.
- **Rung S2 — window over the "UI"**: the guest has no bdpprog
  equivalent running yet, so simulate the coexistence condition:
  keep a *first* DirectFB app alive (a long-running dfbhello variant
  drawing a static background), then start the probe's window on top.
  Assert: first app's surface still alive after probe exit (md5 its
  output region before/after), probe's window drawn, no deadlock.
- **Rung S3 — the fusion test**: run TWO probe instances
  simultaneously with different window geometries. SaWMan's whole job
  is mediating multiple clients through fusion; two windows stacking
  is the minimal real multi-app test.

## What would falsify the plan

- `CreateWindow` unsupported by the shipped core build (DirectFB 1.2.7
  core definitely has it; the risk is the MT85 provider's layer config
  `layer-buffer-mode = frontonly` interacting with window buffers) →
  fall back to `SetCooperativeLevel(DISCRETE)` + secondary layer
  requests, record which the provider accepts.
- Sawman requires `fusion` cell allocation the guest's tmpredir
  environment doesn't stage (shm paths) → extend the staging list,
  same pattern as prior rungs.
- bdpprog-specific behavior (AWM_TEST_MODE_FLAG etc.) can't be probed
  without running bdpprog itself in the guest — explicitly OUT of scope
  here; that is the follow-up hardware/guest-boot experiment.

## Acceptance

- Probe log shows: window created under wm=sawman, content flipped,
  clean destroy, and (S2) the underlying app undisturbed (md5 proof),
  (S3) two concurrent windows both alive.
- `evidence/bx510-guest/graphics/sawman-run.md` with VERIFIED/INFERRED
  labels + pulled logs.
- No changes to fbvirt expected; if the provider needs new ioctls,
  decode first (contract doc), then implement — no guessing.

## Deliverables

| artifact | where |
|---|---|
| probe source | `tools/bx510_sawman_probe.c` |
| run harness (guest boot + staging) | extend `tools/bx510_hud_repro.py` or a sibling script |
| logs + run report | `evidence/bx510-guest/graphics/sawman-*` |
| contract/plan updates | `docs/STOCK-LEVERAGE-PLAN.md` S2 section |
