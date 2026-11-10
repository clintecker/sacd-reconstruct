# SaWMan coexistence experiment (S2 lane) — run report

Spec: `docs/S2-SAWMAN-PLAN.md` (SaWMan coexistence: second app over the appliance UI).

This report is for the QEMU **Sony guest** rig (no hardware UI process). Evidence is the UART transcript logs pulled from the lab VM.

## Evidence bundle

Pulled logs (verbatim UART transcripts, IN THIS TREE):
- `hud_guest.log` — **Control A** (unchanged guest-gate HUD run), PASS.
- `sawman_guest.log` — S1/S2/S3 rungs for SaWMan coexistence.

(These files live alongside this report. First commit of this report
omitted them from the tree — reviewer P0; fixed by copying the pulled
artifacts into evidence/.)

## Summary verdict

- **VERIFIED:** The shipped DirectFB configuration selects SaWMan (`wm = sawman` in `/usr/etc/directfbrc`).
- **VERIFIED:** A second DirectFB client can create a window via SaWMan (`CreateWindow`), draw, flip, and cleanly destroy the window (S1).
- **VERIFIED:** A “background” DirectFB app remains alive while the probe window is created/drawn/destroyed; the background app’s own surface bytes (raw dump MD5) are unchanged across the probe lifetime (S2).
- **VERIFIED:** Two concurrent probe instances can run at the same time (fusion multi-app mediation), both alive simultaneously, each creating/flipping/destroying a window, with distinct per-window surface dumps (S3).

- **INFERRED (not pixel-verified to a composite output buffer):** The *visual* stacking ("probe is on top of background") follows from `RaiseToTop`, `SetOpacity(0xff)`, and the SaWMan WM path; we did not decode a composite framebuffer dump into an image in this run.

**Reviewer follow-up (P1, queued):** the S2 md5 match proves the
background app's PRIVATE surface undisturbed — panel-level "UI keeps
running underneath" additionally needs a composited-frame capture
before/after the probe lifetime. The tool for it now exists
(`fbdump --md5`, deterministic whole-buffer digest) and the harness
emits `SAW_S2_FBMD5_PRE/POST`; the next boot run closes this with
numbers instead of inference. All windows in the captured run created
via **attempt#1** (shared cooperation) — zero attempt#3 escalations
(grep-verified: 4× attempt#1, 0× attempt#3), so the claim is the strong
form, not the administrative-cooperation fallback.

## Control A — unchanged guest gate (must stay green)

- **VERIFIED PASS:** `tools/hud_guest_run.sh` gate succeeded.
  - Gate output on host: `PASS: rc=0, surface present, mean luminance 83.84`.
  - Full UART transcript: `hud_guest.log`.

## Rung S1 — SaWMan loads; one window created/drawn/destroyed

Evidence (from `sawman_guest.log`):

- **VERIFIED:** shipped config selects SaWMan:
  - `SAW_DFBRC_BEGIN` shows `wm           = sawman`.
- **VERIFIED:** WM module loads:
  - `(*) DirectFB/Core/WM: SaWMan 0.2 (directfb.org)`
- **VERIFIED:** probe step markers show successful window lifecycle:
  - `SAWMAN-PROBE: Layer.CreateWindow: rc=0 (OK)`
  - `SAWMAN-PROBE: Surface.Flip: rc=0 (OK)`
  - `SAWMAN-PROBE: Window.Destroy: rc=0 (OK)`
- **VERIFIED:** probe produced a surface raw dump (window buffer) with MD5:
  - `SAW_S1_RAW_MD5` → `5025f3825b5f1ce16a6b171117fa49e1  /res/s1_win.raw`

Notes:
- DirectFB prints: `(!) Fusion/SHM: Could not find tmpfs mount point, falling back to /dev/shm!`.
  - **VERIFIED:** despite this warning, DirectFB init + SaWMan + window ops succeeded under the tmpredir staging (/res/dev/shm provisioned).

## Rung S2 — background app survives; probe window created/drawn/destroyed; background surface MD5 matches

We simulate “UI already running” by keeping a first DirectFB app alive (`dfbhello`) while launching the window probe.

Evidence (from `sawman_guest.log`):

- **VERIFIED:** background app was alive while the probe ran:
  - `SAW_S2_BG_ALIVE_DURING=1`
  - after probe hold window completed: `SAW_S2_BG_ALIVE_AFTER=1` and `SAW_S2_PROBE_ALIVE_AFTER=0`
- **VERIFIED:** background app dumped its own primary surface bytes twice (scheduled at t=1s and t=12s) and the MD5s match:
  - `SAW_S2_BG_RAW_MD5_1` → `4c2d29170b97d11f6224e3760ab3e7b5  /res/s2_bg1.raw`
  - `SAW_S2_BG_RAW_MD5_2` → `4c2d29170b97d11f6224e3760ab3e7b5  /res/s2_bg2.raw`
  - harness comparison: `SAW_S2_BG_MD5_MATCH=1`
- **VERIFIED:** the probe produced its own window-surface raw dump:
  - `SAW_S2_WIN_RAW_MD5` → `770a7ecaa4a7d2c346b90d441c3d42c1  /res/s2_win.raw`
- **VERIFIED:** both apps used the SaWMan WM path (both logs include `DirectFB/Core/WM: SaWMan 0.2`).

## Rung S3 — two concurrent probe instances

Evidence (from `sawman_guest.log`):

- **VERIFIED:** both processes alive at the same time (checked after launch):
  - `SAW_S3_A_ALIVE_DURING=1`
  - `SAW_S3_B_ALIVE_DURING=1`
- **VERIFIED:** both later exited:
  - `SAW_S3_A_ALIVE_AFTER=0`
  - `SAW_S3_B_ALIVE_AFTER=0`
- **VERIFIED:** distinct per-window raw dumps (shows each probe had a live surface buffer):
  - `SAW_S3_A_RAW_MD5` → `dabcb12103db3c89664189208f6ee629  /res/s3_a.raw`
  - `SAW_S3_B_RAW_MD5` → `7ef0af54ca2e95c4a4699288bf541cfe  /res/s3_b.raw`
- **VERIFIED:** each probe log shows the full window lifecycle (`CreateWindow` → `Flip` → `DestroyWindow`).

## Deviations / notes

- We could not use `/bin/sh ... &` backgrounding because the guest root is squashfs RO and has **no `/dev`**. This is already known and documented; we used the existing strategy from prior rungs: stage a fork/exec helper.
  - **VERIFIED:** `bgstart` (new named-output variant) is used to launch concurrent apps without relying on `/dev/null`.
- `SaWMan` shutdown warns about still objects in pools (seen at least in S1). This did not prevent clean exit or subsequent rungs.

## Files changed (in this mirror; no commits made)

- Added: `tools/bx510_sawman_probe.c`
- Added: `tools/bx510_sawman_repro.py`
- Added: `tools/bx510_bgstart_named.c`
- Updated: `tools/bx510_dfbhello.c` (optional dump flags; backward-compatible when invoked with just positional args)

## Quick index of log markers

In `sawman_guest.log`:
- S1 begins: `SAW_S1_BEGIN`
- S2 begins: `SAW_S2_BEGIN`
- S3 begins: `SAW_S3_BEGIN`
- Probe markers: `SAWMAN-PROBE: ...`
- Background app markers: `DFBHELLO: DUMP1 ...`, `DFBHELLO: DUMP2 ...`
