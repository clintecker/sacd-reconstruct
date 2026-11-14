# The Master TOC structure — and the request sequence that follows it

Date: 2026-11-14. Scope: the 20,480 bytes the daemon reads at LBA 510 ×10 after
the rig started serving them correctly (md5 `45ccd7df…` = the recorded oracle),
what `scarletbook_read_master_toc` does with them, and **exactly which disc
reads come next** so the FE model can be pre-checked instead of discovered
mid-fire. Everything here is Mac-side decode + the real fixture bytes; no rig
state was changed.

Companions (read them for the surrounding lanes, not repeated here):
`daemon-ioctl-side.md` (the ioctl stack + boot sequence),
`firebird-fixture.md` (§2.5/§2.6 real-disc TOC bytes, §3.3 the 2352 synthesis),
`fe-read-dma.md` (`bx510_fe_read`, `FE_DMA_MAX`),
`c97-read-path.md` §3.1 (the 0x12800 driver cap).

**House rules.** **VERIFIED** = read out of an instruction (cited as `vaddr`,
file offset = `vaddr − 0x8000`), a literal-pool word, or the actual disc bytes,
and re-derivable with §7. **INFERRED** = reasoned from a pattern, with the
settling experiment named.

---

## 0. Bottom line

1. **The 20,480 bytes are a 10-sector *bundle*, not a 10-sector structure.**
   Sector 0 is the `SACDMTOC` header (168-byte struct + zero fill), sectors 1-8
   are `SACDText`, sector 9 is `SACD_Man`. The daemon validates **every one of
   the ten** — the bundle is a checksum-by-structure. *VERIFIED (real bytes §1,
   loop + strncmp sites §2.3).*
2. **The master-TOC struct is 168 bytes at sector 0, all fields big-endian on
   disc; the daemon byte-swaps exactly 9 of them in place** (`0x10, 0x12, 0x40,
   0x44, 0x48, 0x4c, 0x54, 0x56, 0x78`) and leaves the byte fields and both
   16-byte catalog strings alone. Field map with the real disc's values: §2.
3. **Only five failures are fatal**: the 10-sector read itself, `"SACDMTOC"`,
   the version pair, any one of the eight `SACDText` ids, and the `SACD_Man`
   id. Every `reserved`
   zero-check, every genre range check and the `text_area_count` range check
   **only logs** — a hostile or synthetic TOC can fail them all and still
   enumerate. §3.
4. **After the master TOC the daemon issues exactly two more plain reads** —
   the area TOC blocks — and then it is done with the block device:
   `read(dev, 544, 40)` and `read(dev, 353804, 40)` on this disc.
   *VERIFIED (§4.1: the LBAs come from the real TOC's `0x40`/`0x48` fields, the
   counts from `0x54`/`0x56`, the call sites from `0x299d8`/`0x29bac`).*
5. **The `*_toc_2_start` fields are dead.** `0x44` (353 764) and `0x4c`
   (1 064 127) — the copies `firebird-fixture.md` §2.6 spends a section on —
   are never read by this daemon. Only the `_toc_1` copies (544, 353 804) are.
   *VERIFIED (the whole binary contains three `sacd_read_block_raw` call sites
   and no others, §4.2).*
6. **⚠ PREDICTED MODEL BLOCKER — the area-TOC read is 4× larger than anything
   the FE has ever served.** Each area TOC read is 40 sectors: 81 920 B at the
   plain 2048 framing (94 080 B if the vendor driver arms the 2352 raw
   framing). `bx510_fe_read()` refuses any transfer `> FE_DMA_MAX` (75 776 B)
   with a drive error, and **no block-layer split is coming** — the guest's
   own queue limit is `BLK_DEF_MAX_SECTORS`=1024 (512 KiB) with Sony's
   `ATA_MAX_SECTORS`=1024 hack, so an 80 KiB request is one READ(10).
   Predicted observable: `libsacdread: Can't read Area TOC 1.` This needs a
   decision before the next fire is read as a TOC-parse failure. *INFERRED from
   VERIFIED arithmetic — §5.1 has the numbers, the three options, and the
   decisive one-line check.*
7. **`sacd_authenticate` is not an FE request.** The DISC_OPEN auth leg is
   `ioctl 0x40105302` → `CPSA_SACDCmdSetCtrl` (the SoC media co-processor,
   stubbed in the rig), not a disc command — it cannot ask the FE for anything.
   *VERIFIED (`sacdread-cpsa.md` §3 table, `daemon-ioctl-side.md` §2.5).*
8. **Nothing else touches the disc until the client asks.** The TOC leg uses no
   vendor CDB, no `READ CD` (0xBE), no `GET CONFIGURATION`, and no
   `SACD_IOC_READ` — plain `lseek64`+`read()` only, which the block layer turns
   into READ(10). The 2064-byte ioctl channel starts only at `DISC_READ` /
   track rip, i.e. after the TOC parse succeeds. *VERIFIED (§4.2).*

---

## 1. The bytes (provenance, re-derivable)

```
# on the VM (the ISO lives there; nothing is fetched)
dd if=/home/aftermath/sacd-verify/firebird.iso bs=2048 skip=510 count=10 of=/tmp/mtoc.bin
md5sum    /tmp/mtoc.bin   -> 45ccd7dfbf433a79d28e877d7441677c   (the recorded oracle)
sha256sum /tmp/mtoc.bin   -> cd90f21ce6ed0786acfe8eeca9d2177189e32f1c26bd9d143b718011a3b7494d
```

Sector inventory of the bundle (first 8 bytes / nonzero-byte count / md5):

| LBA | sector in read | id | nz | md5 |
|---:|---:|---|---:|---|
| 510 | 0 | `SACDMTOC` | 70 | `e56de1add53c90dd30cf9232b29ddc93` |
| 511 | 1 | `SACDText` | 110 | `68e5b97be9a6db48a3d477d77522d47d` ← the only text sector with payload |
| 512 | 2 | `SACDText` | 8 | `cc0040c13d0b0517897687c77eca8e00` |
| 513 | 3 | `SACDText` | 8 | `cc0040c13d0b0517897687c77eca8e00` |
| 514 | 4 | `SACDText` | 8 | `cc0040c13d0b0517897687c77eca8e00` |
| 515 | 5 | `SACDText` | 8 | `cc0040c13d0b0517897687c77eca8e00` |
| 516 | 6 | `SACDText` | 8 | `cc0040c13d0b0517897687c77eca8e00` |
| 517 | 7 | `SACDText` | 8 | `cc0040c13d0b0517897687c77eca8e00` |
| 518 | 8 | `SACDText` | 8 | `cc0040c13d0b0517897687c77eca8e00` |
| 519 | 9 | `SACD_Man` | 8 | `52566a9e355cc1ad1b61956fe01eed7f` |

Sectors 2-8 are literally the 8-byte id and nothing else — the daemon still
requires each one (it would refuse the whole bundle if any read as zeros, since
zeroed sectors cannot match `"SACDText"`). **A fixture that fills only sector 1
fails the read.** `tools/fixture_gen.py:main` already writes all ten
(`put_sector(511..518, sacd_text_sector())`, `put_sector(519, sacd_man_sector())`).

Sector 0 beyond the 168-byte struct is zero (offsets `0xa8..0x7ff`).
The 8-byte id is at `0x00`, not at a sector-aligned "header block" — the
previous three master-TOC copies on this disc (LBAs 520-529, 530-539) are *not*
part of the daemon's read and are only reached if something re-issues it.

---

## 2. The master-TOC struct (field map, offsets, real values)

Layout of sector 0, big-endian on disc. "swap" = the daemon rewrites the field
in place to host order while parsing (`ldrb`-compose + byte-swap pairs, sites in
§2.2). Field names are the binary's own, out of the two diagnostic tables
(`ZeroCheck` / `CHECK_VALUE` `%s` strings at `0x359d0`/`0x35b15`).

| off | size | field (daemon's name) | on disc | decoded | swap | daemon use |
|---:|---:|---|---|---|---|---|
| `0x00` | 8 | `id` | `SACDMTOC` | — | — | `strncmp(…,8)` — **fatal** |
| `0x08` | 1 | version major | `01` | 1 | — | must be ≤ 1 — **fatal** |
| `0x09` | 1 | version minor | `14` | 20 | — | must be ≤ 20 — **fatal** |
| `0x0a` | 6 | `master_toc->reserved01` | `00×6` | 0 | — | zero-check (log) |
| `0x10` | 2 | `album_set_size` | `00 01` | 1 | ✔ | — |
| `0x12` | 2 | `album_sequence_number` | `00 01` | 1 | ✔ | — |
| `0x14` | 4 | `master_toc->reserved02` | `00×4` | 0 | — | zero-check (log) |
| `0x18` | 16 | `album_catalog_number` | `CDSML8558␠␠␠␠␠␠␠` | string | — | printed |
| `0x28` | 16 | `album_genre[4]` | `01 00 00 05` then 0 | cat 1, gen 5 (i=0) | — | `.reserved` zero-check per entry; `category ≤ 3`; `genre ≤ 29` (log-only) |
| `0x38` | 8 | `master_toc->reserved03` | `00×8` | 0 | — | zero-check (log) |
| `0x40` | 4 | `area_1_toc_1_start` | `00 00 02 20` | **544** | ✔ | **LBA of the next read** (`scarletbook_open` `0x2989c`) |
| `0x44` | 4 | `area_1_toc_2_start` | `00 05 65 e4` | 353 764 | ✔ | **never read** |
| `0x48` | 4 | `area_2_toc_1_start` | `00 05 66 0c` | **353 804** | ✔ | **LBA of the third read** (`0x29a70`) |
| `0x4c` | 4 | `area_2_toc_2_start` | `00 10 3c bf` | 1 064 127 | ✔ | **never read** |
| `0x50` | 1 | `disc_type` | `80` | 0x80 | — | **not validated at all** (no reader in the function) |
| `0x51` | 3 | `master_toc->reserved04` | `00×3` | 0 | — | zero-check (log) |
| `0x54` | 2 | `area_1_toc_size` | `00 28` | **40** | ✔ | sector count of the area-1 read |
| `0x56` | 2 | `area_2_toc_size` | `00 28` | **40** | ✔ | sector count of the area-2 read |
| `0x58` | 16 | `disc_catalog_number` | `CDSML8558␠␠␠␠␠␠␠` | string | — | printed |
| `0x68` | 16 | `disc_genre[4]` | `01 00 00 05` then 0 | cat 1, gen 5 (i=0) | — | as album_genre |
| `0x78` | 2 | `disc_date_year` | `07 e3` | 2019 | ✔ | printed |
| `0x7a` | 1 | `disc_date_month` | `03` | 3 | — | printed |
| `0x7b` | 1 | `disc_date_day` | `13` | 19 | — | printed |
| `0x7c` | 4 | `master_toc->reserved05` | `00×4` | 0 | — | zero-check (log) |
| `0x80` | 1 | `text_area_count` | `01` | 1 | — | `≤ MAX_LANGUAGE_COUNT` (8) — **log-only** |
| `0x81` | 7 | `master_toc->reserved06` | `00×7` | 0 | — | zero-check (log) |
| `0x88` | 32 | `locales[8]` | `65 6e 00 00` ×8 | `"en"` | — | passed to `charset_convert` |
| `0xa8` | … | (zero fill to 2048) | `00…` | — | — | — |

`0x28` and `0x68` are 4 entries of a 4-byte `genre_table_t`
`{category u8; reserved u16; genre u8}` — that is the layout the daemon's own
`%s` names (`album_genre[i].reserved` / `.category` / `.genre`) and its
`memcmp(buf + 4*(10+i) + 1, zeros, 2)` / `ldrb buf + 4*(10+i)` /
`ldrb buf + 4*(26+i) + 3` accesses pin down. *VERIFIED (`0x2ac24`-`0x2af28`.)*

> Offset-spelling note for future readers: `firebird-fixture.md` §2.5 says
> "`disc_type @80` … `text_area_count @128`". Those are **decimal** — 80 = `0x50`,
> 128 = `0x80`. There is no contradiction with this table; do not "fix" one into
> the other.

### 2.1 In-memory result of the parse

`scarletbook_open` gives `scarletbook_read_master_toc` a freshly `calloc`'d
`scarletbook_t` (`calloc(1, 0x7084)`, `scarletbook_open` `0x297d0`). After a
successful parse (`0x2c0a4`-`0x2c0d8`):

| slot | value | how |
|---|---|---|
| `sb + 0x04` | the `malloc(20480)` buffer | `0x2a220` |
| `sb + 0x08` | same pointer, "the master TOC" (`master_toc`) | `0x2a284` |
| `sb + 0x0c` | `buffer + 9×2048` — the `SACD_Man` sector | `0x2c0ac` |
| `sb + 0x50`, `sb + 0x54` | `-1` | area start/end seeds (`0x29840`/`0x29850`) |
| `sb + 0x58` | area count, incremented per area TOC parsed | `0x29a5c` |
| `sb + 0x5c + 0x5c·n` | area-`n` TOC buffer pointer | `0x29918` |
| `sb + 0x703c` | `malloc(65536)` working buffer | `0x2980c` |

The TOC struct is manipulated **in place inside the 20 480-byte buffer** — the
swaps rewrite sector 0; in sector 1 the table at `0x10..0x2f` is read as
16 big-endian `u16` **byte offsets relative to that sector's own base**, each
turned into a `char *` by `strlen`+`charset_convert` and stored back over the
same buffer at `0x10..0x4f` (`0x2b100`-`0x2c07c`: 16 ×
swap → `strlen` → `charset_convert` → `str`). The real disc's table, decoded
straight out of the bytes:

| table slot | sector-relative offsets | text at that offset |
|---|---|---|
| lang 0 (`0x10`,`0x12`,`0x14`,`0x16`) | 64, 74, 82, 96 | `Firebird `, `Tomita `, `Vocalion Ltd `, `Sony Classical Int` |
| lang 1 (`0x20`,`0x22`,`0x24`,`0x26`) | 115, 125, 133, 147 | the same four strings again |
| lang 2-3 (`0x18`,`0x1a`,`0x1c`,`0x1e`,`0x28`…`0x2e`) | 0 ×8 | — |

So the on-disc table is 4 languages × 4 offsets (title/artist/publisher/
copyright), two of them populated. *Offsets, swap set, string conversion and
the "relative to the SACDText sector" rule are VERIFIED from the bytes; the
four semantic roles are INFERRED from the string order (album → artist →
label → copyright) and are not used by the FE model.*

### 2.2 Swap sites (all nine, cited)

`0x10` `0x2a2dc`, `0x12` `0x2a344`, `0x40` `0x2a3ac`, `0x44` `0x2a44c`,
`0x54` `0x2a4ec`, `0x48` `0x2a554`, `0x4c` `0x2a5f4`, `0x56` `0x2a694`,
`0x78` `0x2a6fc`. The four `0x4x` fields are 4-byte swaps, the rest 2-byte.
Nothing at `0x50`, `0x68`, `0x7a`, `0x7b`, `0x88` is touched — byte fields and
strings stay as read. **VERIFIED.**

Consequence for anyone reading the code after the parse: `scarletbook_open`
re-composes those fields from the buffer's bytes as if big-endian (`0x2989c`:
`b[0x40] | b[0x41]<<8 | b[0x42]<<16 | b[0x43]<<24`). That is correct **only
because the swap already ran** — it is a little-endian re-read of a
host-order value. Both readings agree; a model or a test that hands the daemon
unswapped bytes and compares fields numerically will not.

### 2.3 The bundle loop and the `SACD_Man` tail

```
buffer          = malloc(20480)                                   0x2a20c
if read(dev, 0x1FE, 10, buffer) == 0            -> return 0       0x2a25c
if strncmp(buffer, "SACDMTOC", 8)               -> fwrite(36) + 0  0x2a2a4
   ... swaps, zero-checks, genre checks, text_area_count check ...
text = buffer + 2048            (sector 1 / LBA 511)              0x2af70
for i = 0..7:                                                     0x2c09c (cmp #7)
    if strncmp(text, "SACDText", 8)  -> return 0   (SILENT)       0x2af9c
    if memcmp(text+8, zeros, 8)      -> log, continue             0x2afc8
    ... 16 u16 text offsets swapped + converted ...
    text += 2048                                                  0x2c084
sb->man = text                  (now sector 9 / LBA 519)          0x2c0ac
if strncmp(sb->man, "SACD_Man", 8) -> return 0   (SILENT)        0x2c0c4
return 1                                                          0x2c0dc
```

Four of the five fatal paths are `return 0` **with no message on stderr** — the
only visible symptom is the caller's `libsacdread: Can't read Master TOC.`
(`0x29868`, 36-byte `fwrite`). *VERIFIED.*

---

## 3. The validation ladder: what is fatal, what only logs

Fatal (returns 0, `scarletbook_open` then prints `Can't read Master TOC.`):

| # | test | site | message |
|---|---|---|---|
| 1 | `malloc(20480)` failed | `0x2a22c` | none |
| 2 | the 10-sector plain read returned 0 | `0x2a264` | none |
| 3 | `id != "SACDMTOC"` | `0x2a2a4` | **stderr** `libsacdread: Not a ScarletBook disc!` (`0x3597c`, `fwrite` 37) |
| 4 | `version_major > 1` or `version_minor > 20` | `0x2a768`-`0x2a7a4` | stderr `libsacdread: Unsupported version: %i.%02i` (`0x359a4`, `fprintf`) |
| 5 | any of the 8 `SACDText` ids ≠ `"SACDText"` | `0x2af9c` | **none** |
| 6 | `SACD_Man` id ≠ `"SACD_Man"` | `0x2c0c4` | **none** |

Log-only (a `fprintf` into the log stream `*[0x56df8]`, then parsing continues):

| test | site | text (rodata) |
|---|---|---|
| `reserved01`/`02`/`03`/`04`/`05`/`06` ≠ 0 | `0x2a7c4` … `0x2ab70`, base `0x595c0` = **.bss zero region** (VERIFIED, `.bss` = `0x56df0+0x302c`) | `*** Zero check failed in %s:%i` + the field name |
| `album_genre[i].reserved` / `disc_genre[i].reserved` ≠ 0 | `0x2ac48`/`0x2ad28` | idem |
| `album_genre[i].category > 3` (> `MAX_CATEGORY_COUNT`) | `0x2adf0`, `0x2ae34` | `*** libsacdread: CHECK_VALUE failed…` |
| `…genre > 29` (> `MAX_GENRE_COUNT`) | `0x2ae8c`, `0x2aec8` (`cmp #29`) | idem |
| `text_area_count > 8` (> `MAX_LANGUAGE_COUNT`) | `0x2af30` (`ldrb [r3,#0x80]`, `cmp #8`) | idem |
| `SACDText` sector: `memcmp(text+8, 0, 8)` | `0x2afc8` | `master_text->reserved` |

So: **a hostile TOC cannot be detected by this parser as long as the ids and
the version are right** — everything else is a log line. Conversely the parser
is easy to satisfy: id + version + 8 `SACDText` + 1 `SACD_Man`. (That is why
`tools/fixture_gen.py` "just works" through `scarletbook_open`.)

---

## 4. What comes AFTER — the request sequence

### 4.1 The sequence (`scarletbook_open`, `0x297bc`)

| # | call | LBA | sectors | bytes (@2048) | expected first 8 bytes | source of LBA/len |
|---:|---|---|---:|---:|---|---|
| 1 | plain `read(/dev/sr0)`, `0x2a25c` | **510** (`0x1FE`) | 10 | 20 480 | `SACDMTOC` | literal |
| 2 | plain read, `0x299d8` | `BE32 mtoc[0x40]` = **544** | `BE16 mtoc[0x54]` = **40** | 81 920 | `TWOCHTOC` | master TOC |
| 3 | plain read, `0x29bac` | `BE32 mtoc[0x48]` = **353 804** | `BE16 mtoc[0x56]` = **40** | 81 920 | `MULCHTOC` | master TOC |

Rules the open applies:

* An area is read **only if its `_toc_1_start` is non-zero** (`0x298c4` /
  `0x29a98` test the composed value). This disc has both.
* Buffer per area: `malloc(count << 11)`, stored at `sb + 0x5c·(area+1)`
  (`0x298f8`/`0x29918`); a failed `malloc` aborts the whole open silently.
* A failed area read clears the field it read (`strb 0` over
  `mtoc[0x40..0x43]`, `0x299f0`) and continues — i.e. **the open still
  succeeds with zero areas**, which is why the api-level symptom of a failed
  area read is a disc with no tracks rather than an error return.
* Failure strings: `libsacdread: Can't read Area TOC 1.` (`0x35920`) /
  `… Area TOC 2.` (`0x35948`) — both 36-byte `fwrite`s to stderr, printed by
  *open*, not by the read; `libsacdread: Not a valid Area TOC!` (`0x35cbc`)
  comes from `scarletbook_read_area_toc` (`0x2c1b0`) when neither `TWOCHTOC`
  nor `MULCHTOC` matches (`0x2c168`/`0x2c188`).
* Then `scarletbook_read_area_toc(sb, area)` parses **the buffer it already
  has** — it issues no reads of its own (its only external calls are 18 ×
  `charset_convert` + one `fwrite`; VERIFIED by symbol scan).

### 4.2 Exhaustive read-site audit (so "nothing else" is a claim with evidence)

`bl sacd_read_block_raw` (plain, 2048 B/sector) — **3 sites, the three above**:
`0x2a25c` (master TOC), `0x299d8` (area 1), `0x29bac` (area 2).
`bl sacd_read_block_raw64` (ioctl `0x40105303`, 2064 B/sector) — **2 sites**:
`client_thread` `0xcbc0` (client `DISC_READ`) and `processing_thread` `0x28968`
(track rip). There is no fourth read path anywhere in the binary. *VERIFIED
(all `bl` to both symbols enumerated across `analysis/disasm.txt`).*

⇒ After request #3 the daemon makes **no further disc requests** until a client
sends `DISC_READ`; the TOC work is finished in memory. `DISC_OPEN` then runs
`sacd_authenticate` (ioctl `0x40105302` → CPSA, not the FE — §0.7) and returns.

### 4.3 What the FE will actually see on this disc (cross-check from the ISO)

The two area-TOC LBAs and lengths above are not guesses — the ISO's own sector
map agrees to the sector:

| LBA | first 8 B | belongs to |
|---:|---|---|
| 538-539 | `SACDText`, `SACD_Man` | the read's last two sectors (510+8, 510+9) |
| 540-543 | zeros | gap after the bundle |
| **544** | `TWOCHTOC` | **request #2 target** (2-channel area, size 40) |
| 545 / 546 | `SACDTRL1` / `SACDTRL2` | track lists inside the area block |
| 547 / 549 | `SACD_IGL` / `SACD_ACC` | ISRC-ish + access list |
| 581 / 583 | `SACDTTxt` + text payload | area text |
| 584 | audio (DSD sectors) | first sector after the 40-sector block ⇒ the block is exactly 544…583 |
| 353 763 | audio (last sector of the program area's data run) | — |
| **353 764** | `TWOCHTOC` copy 2 | = `mtoc[0x44]` — **never read** |
| **353 804** | `MULCHTOC` | **request #3 target** (multi-channel area, size 40) |
| 353 805-353 843 | `SACDTRL1`, `SACDTRL2`, `SACD_IGL`, `SACD_ACC`, `SACDTTxt`… | block ends exactly where audio starts (353 844) |
| 1 064 126 | audio | — |
| **1 064 127** | `MULCHTOC` copy 2 | = `mtoc[0x4c]` — **never read** |

So the disc is laid out as: `[bundle @510][gap][2-ch area block @544 ×40][2-ch audio
@584…353 762]` and `[multi-ch area block @353 804 ×40][multi-ch audio @353 844…]`.
The `@76 = area_LBA − 1` observation in `firebird-fixture.md` §2.6 now has a
plausible reading (last data sector before the block: 353 763 for the copy at
353 764) — **INFERRED**, unchanged, and still not load-bearing for the model.

### 4.4 The synthetic fixture's sequence (for `tools/fixture_gen.py` runs)

The fixture's master TOC points at `area_1_toc_1_start = 600`,
`area_1_toc_size = 10`, `area_2_toc_1_start = 0`. So on the fixture the
sequence is 510×10 → **600×10** → done (area 2 skipped). 10 sectors = 20 480 B,
comfortably inside `FE_DMA_MAX` — **the fixture path cannot hit the §5.1
blocker; only the real ISO does.** Keep that in mind when comparing a
fixture-based PASS with a firebird-based fire.

---

## 5. FE-model gaps the next fire will probe

### 5.1 The 40-sector area read vs `FE_DMA_MAX` — the one to decide

`bx510_fe_read()` (`emulator-kit/sony-bx510.c`) refuses when
`nsec * flen > FE_DMA_MAX` (`0x12800` = 75 776 B) and answers `FE_STATUS_ERR`
(one type-0 reply, byte3 ≠ 0 → `hw_chg_st(priv,5)` → SCSI status 0x51).

| request | nsec | flen (plain 2048) | flen (raw 2352) | vs 75 776 |
|---|---:|---:|---:|---|
| master TOC @510 (today, PASSES) | 10 | 20 480 | 23 520 | under |
| area 1 TOC @544 | 40 | **81 920** | **94 080** | **over both** |
| area 2 TOC @353 804 | 40 | **81 920** | **94 080** | **over both** |

No split is coming from the guest (VERIFIED against the guest's own kernel
tree on the VM, `/home/aftermath/sony-kernel/linux-2.6.35`):

* `libata-core.c:2565` `dev->max_sectors = ATA_MAX_SECTORS`, and Sony's
  `include/linux/ata.h:49` raises `ATA_MAX_SECTORS` to **1024** (`// Nathan
  kernel hacking`) → `blk_queue_max_hw_sectors(1024)` = 512 KiB.
* `block/blk-settings.c:239` `max_sectors = min(max_hw_sectors,
  BLK_DEF_MAX_SECTORS)`, `blkdev.h:1032` `BLK_DEF_MAX_SECTORS = 1024`.
* `sr.c:504` `this_count = (scsi_bufflen >> 9) / (s_size >> 9)` → 40 blocks, no
  clamp below 0xffff.
* the daemon's read is one `read(fd, buf, 81920)` (`lseek64` at `lba<<11`,
  `sacd_dev_input_read` `0x21eb4`) — one bio, one READ(10).

⇒ expected trace: `W 05c40c=1; W 05c400=<phys>; W 05c404=14000` (81920; `0x24c00`
if raw) then `FE READ 28 lba=544 nsec=40 …` and the model's own
`… unusable transfer (nsec=40, 2448/2352-byte frames, cap 75776)` line.
Predicted daemon-side symptom: **`libsacdread: Can't read Area TOC 1.`**

Caveat / why this is INFERRED and not a claim: (a) no request >10 sectors has
ever been served on this rig (C113 ladder tops out at `lba510x10`), (b) which
descriptor framing the libata lane arms (`nsec×2048` vs `nsec×2352`, the
`priv+0x18 ∈ {8,9,10}` raw trigger of `c97-read-path.md` §9) is still open —
it does not change the verdict, only the number.

Options (a product/model decision, not taken here):

1. **Raise the bound** — `FE_DMA_MAX` to ≥ 94 080 (or make it a per-path
   constant: the 0x12800 figure is bdpdrv's `qc_issu_task` cap, not the FE's
   DMA limit). The other guards (whole-frame check, EOF, `phys+len ≤ RAM`) are
   what actually keep a decode bug from scribbling RAM, and they stay.
2. **Split inside the model** — accept a large `nsec`, loop `blk_pread`
   in ≤ 32-block chunks and DMA contiguously. No guest change, more code.
3. **Do nothing and confirm first** — cheapest: one fire, read the FE log line
   for `lba=544`. If the guest *does* split (contrary to §5.1's kernel read),
   this whole item evaporates.

**Decisive one-line check for the next fire:**
`grep -a 'FE READ 28 lba=544\|unusable transfer\|Can.t read Area TOC' <qemu log> <uart log>`

### 5.2 Already-answered by the model (no change needed for this leg)

`READ(10)`/`READ(12)`/`READ CD` with 2048 or 2352 framing; `TEST UNIT READY`,
`INQUIRY`, `MODE SENSE(6)`, `READ CAPACITY`, `READ TOC`, `READ DISC
INFORMATION`/`TRACK INFO`, `GET CONFIGURATION`, `GET EVENT STATUS
NOTIFICATION`, `REQUEST SENSE` (`fe-read-dma.md`, `daemon-gate-c111.md`,
`rc-stale-window.md`). The TOC leg needs **none** of the 2064-byte SACD framing —
that channel is first used by `DISC_READ`/rip, after the parse.

### 5.3 Explicitly NOT needed after the master TOC

* **No vendor CDB `0x46`.** It is a *client/daemon-gate* command
  (`_IDECLI_OddGetProfile`) that has no descriptor and no data-in; the TOC leg
  does not post it.
* **No CPSA / auth traffic.** `sacd_authenticate` (`0x40105302`) →
  `CPSA_SACDCmdSetCtrl` is SoC-internal (`sacdread-cpsa.md` §3); the rig's stub
  returns 0 (`bdpdrv-runC113.meta.json: sacdread.auth = "0"`).
* **No re-read of the TOC copies** at 520/530/353 764/1 064 127 — the daemon
  never asks; if a host wrapper seeks there it is a host-side choice.

---

## 6. Pre-fire checklist for the TOC leg (what to grep, and what it means)

| observable | expected on success | on failure it means |
|---|---|---|
| UART: `GATE 13 master-toc` (or the gate's dd) | a real **20 480 B** read, not `0 B` | open still failing — check the read, not the parse (`daemon-gate-c111.md` §2.7) |
| daemon stdout/stderr | neither `Not a ScarletBook disc!` nor `Unsupported version:` | magic/version wrong ⇒ the FE served the wrong bytes/LBA |
| daemon stdout/stderr | no `Can't read Master TOC.` | one of the four silent paths (§3 #1/#2/#5/#6): buffer, read, a `SACDText` id, or `SACD_Man` |
| FE log | `FE READ 28 lba=510 nsec=10` then **`lba=544 nsec=40`** | no second READ ⇒ the parse died before `scarletbook_open`'s first area read |
| daemon stdout/stderr | no `Can't read Area TOC 1.` | the 40-block read was refused (§5.1) or answered short |
| daemon stdout/stderr | no `Not a valid Area TOC!` | bytes ok but the type magic is not `TWOCHTOC`/`MULCHTOC` ⇒ wrong LBA served |
| client | `DISC_OPEN` returns and a `DISC_SIZE`/track list follows | parse ok; the 2064-byte ioctl lane is now the next model question |

---

## 7. Provenance / re-derivation

```sh
# 1. the bytes (VM, no network)
make vm-exec CMD='dd if=/home/aftermath/sacd-verify/firebird.iso bs=2048 skip=510 count=10 2>/dev/null | md5sum'
#    -> 45ccd7dfbf433a79d28e877d7441677c

# 2. the parse (Mac, local objdump reads the ARM ELF fine)
objdump -d --start-address=0x2a1fc --stop-address=0x2c0f4 original/sacd_extract_160   # read_master_toc
objdump -d --start-address=0x297bc --stop-address=0x29c6c original/sacd_extract_160   # open
grep -c 'sacd_read_block_raw' analysis/disasm.txt                                     # 3 call sites

# 3. the field names (rodata band, the two diagnostic tables)
#    0x359d0 ZeroCheck fmt | 0x35a34..0x35ab4 reserved01..06 | 0x35acc/0x35af0 genre
#    0x35b58..0x35c04 the CHECK_VALUE expressions | 0x35c38 text_area_count
#    the compare constant 0x595c0 is inside .bss (readelf -SW: .bss @0x56df0 +0x302c) => zeros

# 4. the next-read LBAs against the disc
make vm-exec CMD='for L in 544 353804 353764 1064127; do printf "%s " $L; \
  dd if=/home/aftermath/sacd-verify/firebird.iso bs=2048 skip=$L count=1 2>/dev/null | head -c 8; echo; done'
#    -> 544 TWOCHTOC | 353804 MULCHTOC | 353764 TWOCHTOC | 1064127 MULCHTOC

# 5. the guest's own split behaviour (why §5.1 says "no split is coming")
make vm-exec CMD='cd /home/aftermath/sony-kernel/linux-2.6.35 && grep -n "ATA_MAX_SECTORS" include/linux/ata.h && sed -n 2564,2568p drivers/ata/libata-core.c && grep -n BLK_DEF_MAX_SECTORS include/linux/blkdev.h'
```

Evidence state: no rig files were modified for this document; the extracted
20 480 bytes live at `/tmp/sacdmtoc/mtoc.bin` on the Mac and `/tmp/mtoc.bin` on
the VM, both reproducible with step 1.
