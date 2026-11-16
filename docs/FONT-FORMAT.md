# FONT-FORMAT.md — Sony's shipped screen font `/res/font.bin` (BX510, S1)

Status: **decoded 2026-11-08**, source file `incoming/mt85-analyst/font.bin`
(62572 bytes, sha256 `cd5fa82a1044bc486e6ac2347209ac721709f26f87caa31805950e65b0a16827`).
Every structural claim below is VERIFIED from bytes (Python `struct` parses over
the actual file; offsets are file-absolute hex unless marked sfnt-relative).
Decoded by `tools/bx510_font_decode.py` (stdlib-only); cross-checked with
fontTools 4.62.1 and Pillow/FreeType.

## Headline

`/res/font.bin` is **not** a Sony-private bitmap container and **not** a
DirectFB/DGI font. It is a **12-byte wrapper followed by a complete, standard
sfnt/TrueType font**: *TiresiasScreenfont Regular, Release 8.03* (Bitstream Inc.,
1990-2004) — the classic TV/set-top screen font — with **vector outlines**
(`glyf`), not bitmaps. The carve step (`tools/bx510_font_carve.py`, already in
the tree) is therefore the whole "container decoding" problem: strip 12 bytes.

## VERIFIED container layout

```
0x000  4  01 00 00 00      wrapper field A (pattern; semantics INFERRED, likely version 1)
0x004  4  08 00 00 00      wrapper field B (pattern; semantics INFERRED)
0x008  4  00 00 F4 60      u32 BE = 62560 = length of the embedded sfnt
                           (VERIFIED: 62572 - 12 = 62560 = 0xF460, exact)
0x00C  --  sfnt starts: 00 01 00 00 (sfntVersion 1.0), numTables = 0x0011 = 17
0x00C  284  table directory: 12 + 17*16, alphabetically sorted (spec-required)
0x128  --  first table data begins (head)
0xF450  28  FFTM (last table; 62532+28 = 62560 = sfnt end = EOF - 12)
```

Wrapper fields A/B are recorded as byte patterns, not integers: as big-endian
u32s they read 0x01000000 / 0x08000000, which is not a sane version pair; as
little-endian they read 1 and 8 but then the length field would have to be LE
too (it is not — BE matches the file size exactly). Most consistent reading:
the wrapper is `{u8 1, pad, u8 8, pad, u32 BE length}` or an LE-pair + BE-length
mix; either way **only the length field is load-bearing** and it is verified.

## VERIFIED table directory (sfnt-relative offsets)

| tag    | offset | len   | notes |
|--------|--------|-------|-------|
| FFTM   | 62532  | 28    | Bitstream "Font Fusion" metadata (INFERRED name); bytes `00000001 00000000 c21b869a 00000000 bd0624e2 00000000 c50350fc` |
| GDEF   | 50864  | 54    | glyph definitions |
| GPOS   | 51120  | 11412 | kerning/positioning |
| GSUB   | 50920  | 200   | substitutions |
| OS/2   | 408    | 86    | |
| cmap   | 1964   | 1134  | 3 subtables, see below |
| cvt    | 3936   | 240   | hinting |
| fpgm   | 3100   | 139   | hinting |
| glyf   | 4912   | 43552 | the outlines |
| head   | 284    | 54    | fontRevision **8.03**, unitsPerEm **2048**, magic 5F0F3CF5 |
| hhea   | 340    | 36    | ascent 1926, descent −819, lineGap 0 |
| hmtx   | 496    | 1468  | 367 metrics (all glyphs have advances) |
| loca   | 4176   | 736   | short form (offset/2), 368 entries for 367 glyphs |
| maxp   | 376    | 32    | numGlyphs **367** |
| name   | 48464  | 636   | `TiresiasScreenfont`, `Regular`, `Release 8.03`, (c) Bitstream 1990-2004 |
| post   | 49100  | 1762  | v2.0 (glyph names present), italicAngle 0 |
| prep   | 3240   | 695   | hinting |

Integrity, all VERIFIED:
- every table's `offset + length` fits inside the sfnt;
- per-table checksums match for all tables except `head` (which is exempt by
  spec — it carries `checkSumAdjustment`);
- whole-font checksum = **0xB1B0AFBA** exactly (the sfnt spec constant).

## Glyph set (VERIFIED)

- 367 glyphs; **366 Unicode codepoints mapped** by the Windows cmap
  (pid 0 eid 3 and pid 3 eid 1, both format 4, identical) + 1 unmapped (gid 0).
- Coverage: full printable ASCII U+0020–U+007E (95); Latin-1 Supplement
  U+00A0–U+00FF (96); Latin Extended-A U+0100–U+017E (116); 7 Latin Ext-B;
  punctuation/quotes/dashes (U+2010–U+2044), € U+20AC, ™ U+2122, arrows
  U+2190–U+2193, math (− ∕ ∙ ≠ ∞ ⌌ ⩨ ⩩), ♫ U+266B, ✓ U+2713, ✗ U+2717.
- A legacy Mac cmap (pid 1 eid 0, **format 6**, 256 Mac-Roman codes) also
  exists — its code values are Mac Roman, **not** Unicode; decoders must not
  merge it into Unicode coverage (this over-counts to 431).
- Glyph bodies: 212 simple + 144 composite (accented characters) + 9 empty
  (spaces/controls) + .notdef = 367. `indexToLocFormat` = 0 (short loca).
- ASCII glyph ids are contiguous: cmap segment 0 (`U+0020..U+007E`,
  `delta = −29`, `rangeOffset = 0`) gives `gid = cp − 29` (e.g. 'A' → gid 36).
- Geometry: unitsPerEm 2048; font bbox (−324, −819)–(2152, 1926); ASCII
  advances 0.228–0.829 em (narrow `i`/`.` to wide `W`), cap height 1366/2048
  ≈ 0.67 em — VERIFIED from hmtx + glyf bounds.

## Consumer implications (the S1 decision)

1. **FreeType rejects the raw file** — VERIFIED: `ImageFont.truetype(font.bin)`
   raises `OSError: unknown file format`, while the carved sfnt loads as
   `('TiresiasScreenfont', 'Regular')`. So `dfb_font_create("/res/font.bin")`
   as-is cannot work; anything using the standard stack must pass the
   file + 12 bytes (or a carved copy).
2. **No FreeType on the guest rootfs** (established during HUD work; the main
   `libdirectfb-1.2.so.0.7.0` contains no FreeType symbols, and DirectFB font
   providers are loadable modules that were not found on the rootfs). So
   `dfb_font_create` is not the practical S1 path on-device.
3. **The practical S1 path is already in place**: `tools/bx510_font_carve.py`
   strips the wrapper and `tools/bx510_sacd_hud.c` renders the carved TTF with
   vendored **stb_truetype** (`font_load()`), replacing the hand-drawn 5×7
   face. `tools/bx510_fontprobe.c` is the offline legibility gate for it.
   What this decoder adds is a *deterministic, stdlib-only* decode + a
   pre-rasterized atlas for the sim/tests and any consumer that should not
   carry stb at all.

## Decoder

```sh
python3 tools/bx510_font_decode.py incoming/mt85-analyst/font.bin OUTDIR [px]
```

Stdlib-only parse (wrapper, directory + checksums, head/maxp/hhea/hmtx/loca/
cmap/post, glyf classification: simple/composite/empty with outline headers and
component walks). Prints the summary above. Emits into OUTDIR:

- `out.ttf` — the carved sfnt (byte-identical to `bx510_font_carve.py` output,
  VERIFIED by `cmp`).
- `atlas.png` — grayscale coverage atlas, Pillow/FreeType-rendered (Pillow
  11.1.0 on this Mac): one cell per mapped codepoint, codepoint order,
  baseline-aligned, default 32 px em size (cells auto-sized, e.g. 40×48).
- `atlas.bin` — the same atlas as raw u8 coverage, row-major, cell-major;
  generated by reading back the composed PNG's cells, so the two artifacts are
  identical by construction (VERIFIED cell-by-cell).
- `atlas.txt` — manifest: cell size, grid, per-cell
  `U+XXXX g=<gid> adv=<px>(<font units>) x= y= w= h=`.

Determinism VERIFIED: two runs produce md5-identical `atlas.bin`/`atlas.png`.
Runs cleanly at 16/32/48 px with no clipped glyphs (clip detection is built in
and would be reported).

## What the HUD renderer must change (S1 acceptance)

Current state: `bx510_sacd_hud.c` already renders real Tiresias glyphs via
stb_truetype at HUD sizes (falls back to 5×7 if the TTF is absent), and
`bx510_fontprobe.c` renders the sample sheet for the legibility check. The
remaining S1 items:

- **Ship the carved TTF** (or decode the wrapper in C: it is a fixed
  12-byte skip validated by the u32 length field — 10 lines of C) so the HUD's
  `font_load()` points at `/res/font.bin`-derived data on the player, not a
  separately staged file.
- Keep the 5×7 fallback for the no-font case; it is the regression baseline.
- If a caller wants zero rasterizer dependency, consume `atlas.bin` +
  `atlas.txt` (blit u8 coverage, colourise against the HUD's 16-colour
  palette, multiply by the ×6 panel scale — at 32 px cells that is 192 px tall
  text at 1080p; 16 px cells give the HUD's original 96 px).
- Acceptance evidence: `bx510_fontprobe` sheet rendered from the carved TTF
  (readable at 1080p), plus this decoder's atlas as the deterministic fixture.

## Open items / honest labels

- Wrapper fields A/B semantics: INFERRED (pattern only; the length field is the
  verified one). If another `/res/*.bin` sample ever shows up, compare patterns.
- `FFTM` meaning: INFERRED as Bitstream Font Fusion metadata (name matches the
  vendor era; content is version 1 + three opaque u32/u64-looking values).
- Which loader on-device consumes the wrapper: UNVERIFIED — the player's UI
  stack was not traced to its font call in this pass.
