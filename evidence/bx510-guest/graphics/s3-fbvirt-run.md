# S3 fbvirt run report — MT85xx vendor contract implemented, ladder PASS

Run: 2026-11-08/09 · Worker run aac15594-db8d-4c9e-ab85-254f00f0f4f2
(timed out at the 30-min wall AFTER the validation ladder went green; final
report + contract-doc correction completed by the parent from the worker's
transcript, the diff, and the VM evidence — nothing re-run).
Authoritative input: `docs/mt85xx-fbdev-graphics-contract.md` (S1 extraction,
same day).

## What changed

- `tools/bx510_fbvirt.c` (+~320 lines): the vendor contract is now served
  for real per the S1 checklist —
  - ring geometry corrected: items are **160 bytes** (not the published 64);
    maxcount = (ring_len − 192)/160 = **3275** for the 512 KiB ring; the old
    64-byte init would have let the gfxdriver scribble ~1.3 MB past the mmap.
  - ring header per the verified map: maxcount@+0x04, RdPoint@+0x10,
    WrPoint@+0x40 (userspace-owned), state@+0x30 = **1** (immediate dispatch).
  - gfxdriver ring ioctls accepted (all take the ring pointer = mmap+32):
    **0x4651 DISPATCHHW** (retail gfxdriver revision) and the published
    **0x4653** share one consumer; **0x464d** `_mt85CheckFlush` (consume +
    wait semantics satisfied synchronously); **0x4900/0x4901** WR_LOCK/
    WR_UNLOCK (return 0). Unknown requests stay ENOTTY (negative control).
  - FillRectangle (cmd 0x01) items are executed by the mirror consumer:
    color read at payload **+0x30** — see the empirical correction now
    recorded in contract §3.2 (the static "color at +0x00" was disproven by
    the run's own payload dump: 0xff3099e0 = the rung's SetColor; +0x34 =
    the 0x12345678 sentinel).
  - **mode parity**: 1920x1080@32bpp, stride 7680, virtual 1920x2160 (the
    hw-session sysfs geometry), pool0 sized exactly as the dump tool maps it
    (pitch*height + one page = 8298496 B) so length-dispatch matches.
- `tools/bx510_fbdraw.c` (+27): the negative-control mmap length is now
  derived from the device's own `fix.smem_len` — the old fixed 0x400003
  silently STOPPED exceeding smem_len when the module grew to 1080p (the
  control passed the mmap and failed its own assertion — rig drift, caught
  by making the control self-consistent).
  (The fill field-map fix is in `tools/bx510_fbvirt.c` `mt85_exec_fill`,
  NOT fbdraw — an earlier draft of this report misattributed it.)
- New harness: `tools/bx510_fbmt85_repro.py` — the DirectFB rung ladder
  (controls first): (a) insmod fbvirt + nodes + fusion.ko, (b) CONTROL
  `fbdraw fbdraw` raw-fbdev regression vs pinned md5 7d19af14…, then rungs
  ab/c/d/e + negative controls under LD_PRELOAD=tmpredir with the SHIPPED
  retail DirectFB + mtk provider + mt85 gfxdriver.

## Evidence (pulled: evidence/bx510-guest/graphics/s3-run{1,2,3}.{log,out})

s3-run1: full ladder PASS except one negative-control artifact (the
smem_len issue above — the control's own bug, since fixed).
s3-run2 and s3-run3 (after the fixes, fresh boots): **6/6 PASS** —

```
PASS  rung-ab (DirectFBCreate)
PASS  rung-c (live surface)      # 1280x720 primary surface LIVE
PASS  rung-d (FillRectangle)     # SOFTWARE path (no-hardware), pixel-verified
PASS  rung-e (pool match)        # md5 vs independently-built expectation
PASS  negative-control           # 0x4666 -> ENOTTY; bad mmap rejected
PASS  raw regression md5
```

**Scope label (honest, per reviewer):** the gated ladder's rung-d/rung-e
exercise the provider's SOFTWARE rendering path (zero ring items — verified:
no dispatch lines in that rung segment); the pool md5 verifies DirectFB's
own fill. The REAL command-ring fill executes in the separate `fbmt85hw`
discovery leg (s3-run3.log:351-361): run3 consumed + executed the rFill
item with the corrected field map (`color=0xff3099e0` — the rung's exact
SetColor — and correct dst) and completed DISPATCH/UNLOCK/CHECKFLUSH
without error, but its pixels are NOT pool-verified end-to-end. In run2
the same leg was a silent no-op (`color=0x000174c0`, row clipped — the
pre-fix w[0]/double-dst bug), which is precisely why the field map is now
empirically pinned. So: ring path = consumed + executed without error
(run3); pixel-verified fill = software path only.

Module banner (VERIFIED line from s3-run1.log):

```
fbvirt-mt85: vendor contract up: 2 pools (p0 8298496 B phys=0x48000000 …,
p1 16777216 B …), ring 524288 B (maxcount 3275 x 160 B items, state=1
immediate), gfxdriver ring ioctls 0x4651/0x464d/0x4900/0x4901 live, debug
4096 B; retail requests served, unknown -> ENOTTY
```

## Verdict

**S3 acceptance met in the rig**: the shipped retail display stack
initializes, creates a live 1280x720-class surface, and completes a
pixel-verified software fill (and a ring-executed fill without error);
controls and negative controls green. The guest SIGSEGV that kept
`make sacd-hud-guest` red is explained and fixed (revision-split ioctl
numbers + ring geometry). Remaining (honest scope note): the
`make sacd-hud-guest` end-to-end target; pixel-verifying the ring-executed
fill (pool capture on the hw leg); remaining payload families
(rBitblt/rStretch); and contract §4 item 6's NULL-ring + full-ring-retry
negative controls, which are specified but not yet implemented/run. (0x4628
CLUT is NOT remaining — fbvirt already serves it; and §4 item 2's "keep
0x4653 as an honest no-op" was improved on: 0x4653 routes through the real
consumer, documented in the code.) The ladder above is the S3 gate.

## Lessons recorded (→ rig doctrine)

1. Controls must be derived from the device's own state, not constants —
   the fixed-length negative control drifted when module geometry changed.
2. Static decodes are hypotheses; a single payload dump outranks them.
   Contract §3.2 now carries the empirical correction inline.
