# guest-gate run report — sacd-hud-guest PASS + ring-fill pixel-verify + §4.6 controls

Run: 2026-11-09, lab VM (aftermath@10.20.0.18:2222). Rig lane of the
tri-lane round. Evidence files (pulled into this directory):
`hud_guest.log` (guest HUD run), `guest-gate-run.log` (fbmt85 ladder
UART transcript). Worker run 80845a41 (gpt-5.2 high); reviewer findings
addressed by the parent where noted.

## 1) The guest gate: PASS (VERIFIED)

`sh tools/hud_guest_run.sh` → `python3 tools/hud_guest_gate.py`:

```
PASS: rc=0, surface present, mean luminance 83.84
```

hud_guest.log decisive lines (the HUD is the REAL ARM binary under Sony's
guest + retail DirectFB + fbvirt-with-real-ring):

```
HUD: fbdev /dev/fb0 1920x1080 bpp=32 stride=7680 smem=8294400
HUD: vendor pool mapped len=8298496 (pixels=8294400 +0x1000)
HUD: geom 1920x1080 scale=3 retro_x6 pitch=1920 type head=77 body=54 (hdr=0x1000)
HUD: font /res/shim/sony-font.ttf
HUD: POOL-RENDER DONE
```

This is the gate that motivated S3 (the pre-S3 guest SIGSEGV in the
provider's faked-DISPATCHHW path). **The original red gate is green.**

Scope labels (honest, per house rules):
- VERIFIED in the rig: guest boot, retail stack init, HUD process rc=0,
  pool mapping at the S3 geometry (pool0 = 1920*1080*4+0x1000, primary at
  +0x1000 — the header-page adoption), non-black framebuffer
  (mean luminance 83.84), pool dump matches the render.
- INFERRED (unverified on hardware): the +0x1000 header-page adoption on
  the REAL player — a vendor-length mmap could theoretically succeed on
  an smem without a header page (→ HUD drawn 4 KiB shifted). Confirm at
  the next on-player display trial before trusting guest parity there.

## 2) Ring-executed fill: pixel-verified (VERIFIED — closes the S3 scope gap)

guest-gate-run.log, hardware leg:

```
FBMT85HW: rFill payload(slot=0) dst=0x48465ff0 color=0xff3099e0 0,0 1280x720 pitch=5120 fmt=12 magic=0x12345678
FBMT85HW: DISPATCHHW(rc=0 errno=0)
FBMT85HW: capture md5 (captured vs independently-built expectation — must match):
bb76dca28f3ed55bfa646e98c58453c6  /res/hwfillcap.bin
bb76dca28f3ed55bfa646e98c58453c6  /res/hwfillexp.bin
FBMT85HW: ring fill pixel-VERIFY PASS
```

The expectation is built from the same payload words the module logs
(dst = w[2], color = w[12], magic = w[13] — the §3.2 empirical map).
md5 equality is decisive: the ring-consumed fill changed pool memory
exactly as the contract says it should.

## 3) §4 item 6 controls: PASS (VERIFIED)

```
FBMT85: NEGCTL DISPATCHHW(arg=NULL) -> rc=-1 errno=14 (EFAULT ok) — must be EFAULT
FBMT85: NEGCTL DISPATCHHW_NULL PASS
FBMT85HW: FULLRING before rd=0 wr=7 max=8; after rd=0 wr=0; rc=0
FBMT85HW: FULLRING RETRY PASS
```

(Chosen semantics recorded in contract §4.6: the module REJECTS a NULL
ring with -EFAULT rather than tolerating it; "does not fault" is satisfied
by rejection + guest survival.)

## 4) Controls-first invariants (every run)

```
FBDRAW: full-frame md5: 7d19af14518cb5c201aedab2cf94e83d   (raw-fbdev regression, pinned)
FBMT85: NEGCTL PASS (failures=0)                            (selector/request/mmap negatives)
```

Full ladder from guest-gate-run.log: 9/9 PASS — rungs ab/c/d/e, negative
controls, DISPATCHHW-NULL, raw regression md5, ring-fill pixel-verify,
full-ring retry.

## Code changes in this lane (verified by review)

- `tools/bx510_fbdraw.c` (+~300): `mt85_hw_ring_fill_verify` (reads the
  executed item from the ring, builds the expectation, md5s the pool),
  FULLRING control, DISPATCHHW-NULL control, GETMULTIPOOL input hygiene
  (memset + num init — removes a real nondeterministic-failure source).
- `tools/bx510_fbvirt.c`: NULL-ring → -EFAULT semantics (consumer-safe
  for real callers, which always pass mmap+32).
- `tools/bx510_fbmt85_repro.py`: hw checks now gate the ladder (docstring
  updated to match); `tools/hud_guest_run.sh` staging note added.
- Reviewer-flagged dead staging (fbmt85_repro staged but not run by the
  HUD flow) annotated rather than removed — the VM-side record keeps it.

## Remaining honest gaps

- Player-leg parity of the +0x1000 header-page adoption (INFERRED until
  the next on-player display trial).
- The font staged here is still the carved sony-font.ttf path
  (`HUD_FONT`); the wrapped-`/res/font.bin` direct load landed in the
  same HUD source and is exercised by the font-hud lane's sim evidence.
