# blit-maps run report — payload field maps decoded for all 18 wrappers

Run: 2026-11-09, Mac-side only (no VM). Worker run 03725614 (glm-5.3 high)
TIMED OUT at the 30-min wall AFTER the decode completed and
cross-validated — it died during contract-doc write-up. The parent
completed the write-up from the worker's transcript + the retained
extraction outputs (this file records that split honestly).

## Deliverable state

- `evidence/bx510-guest/graphics/mt85-extraction/mt85_payload_extract.py`
  — the extraction tool (retained beside the other scripts).
- `evidence/bx510-guest/graphics/mt85-extraction/mt85_payload_maps_fill.txt`
  — 7 fill-family wrappers, per-store annotated (address-level evidence).
- `evidence/bx510-guest/graphics/mt85-extraction/mt85_payload_maps_blit.txt`
  — 11 blit/stretch wrappers, per-store annotated.
- `docs/mt85xx-fbdev-graphics-contract.md` §§3.3–3.8 — the human-readable
  field maps (written by the parent from the extraction outputs; the
  worker's draft asserted sections that did not exist, caught by review,
  fixed by writing the sections from the retained data).

## Coverage (18/18 wrappers, all cmd ids from §3.1 with callers)

Fill family: 0x01 (56 B), 0x30 (60 B), 0x27 (128 B), 0x28 (56 B),
0x29 (128 B), 0x2c (64 B), 0x2d (72 B).
Blit/stretch family: 0x02 (124 B), 0x03 (128 B), 0x0f (108 B),
0x31 (132 B), 0x2e (112 B), 0x2f (120 B), 0x34–0x38 (PM variants,
128 B), 0x3a (124 B).
Still unrouted (no caller found in the binary): ids 4, 0x15, 0x1d,
0x32, 0x12e — unchanged as §5.2.

## Headline structural findings (VERIFIED as store positions)

1. **Common prologue everywhere**: payload +0x00 = `_h_mt85_Ticket`
   heap pointer (GOT slot 0x10478 R_ARM_GLOB_DAT), +0x04 = 1,
   format-code words at +0x18/+0x30 from the DSPF switch.
2. **Sentinel placement rule**: 0x12345678 sits in the LAST payload
   word of each struct — +0x34 for fill-family (56–72 B),
   +0x58 for bitblt-family (124–132 B). Cheap rig assertion: every
   executed item must carry the sentinel at its family's tail word.
3. **§3.2 empirical correction now has its static explanation**:
   +0x00's value IS the ticket pointer (the old "+0x00 = color" was a
   misattribution of the same global-load chain); color at +0x30 is
   assembled from four CardState bytes (ARG1+0x2c..0x2f).
4. 14/14 payload words of the static rFill map match the observed
   s3-run3 dump word-for-word.

Labeling: store POSITIONS are VERIFIED (disassembly + retained
per-store addresses); field SEMANTICS are INFERRED from the wrappers'
assert strings (rBitblt.pv_src/pv_dst, etc.) and arg positions — the
observable that settles each is a rig payload dump, exactly as §3.2
was settled.
