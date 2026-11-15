# The enhanced SACD UI, in the guest — run report (c123 → c123d)

Date: 2026-11-15. Repo: `sacd-reconstruct`. **No commit made** (parent commits).

What this is: a **client-driven graphical console** that runs INSIDE the emulated
BX510 and paints disc state + Master TOC + both area TOCs + live daemon/client
activity on the panel framebuffer. It is a *separate process that is also a
daemon client* — the daemon was not modified. Iteration happens at QEMU speed:
no USB stick, no player power cycle, no TV photograph.

```
PASS (c123d): UI_RC=0  session_ok=1  frames=240  fps=8.0  client sessions seen=1
              mean luminance 12.80, text present in 3 pixel bands, 0/360 damaged rows
```

Artifacts a human can look at:
- `sacd-ui-c123d.png` — **the frame the guest rendered**, decoded from the pool
  dump (640x360; fbdump samples every 3rd device pixel of the 1920x1080 panel).
- `sacd-ui-c123d-3x.png` — the same frame upscaled 3x for reading.
- `sacd-ui-preview-1080p.png` — Mac-side SIM render (native 1920x1080) used to
  iterate the LAYOUT before burning fires; TOC bytes are the real fixture, the
  wire/timing values are synthetic (`SACD_UI_SIM`).

---

## 0. Bottom line

1. The whole loop works in one fire: guest boot → module stack → FA latch clear →
   daemon listening → **UI takes its own client session over 127.0.0.1:2002** →
   renders → a second client (`sacdclient`) runs → the UI *watches it connect and
   disconnect* via `/proc/net/tcp` → the frame is read back out of the vendor
   pool. *VERIFIED — `bdpdrv-runc123d.uart.log`.*
2. Everything the UI shows about the disc came off the socket, in that run:
   `DISC_OPEN` (22 292 ms), `DISC_SIZE` 1 064 208 sectors (13 ms),
   Master TOC `lba=510 x10` 20 480 B (127 ms), `lba=544 x40` 81 920 B (129 ms),
   `lba=353804 x40` 81 920 B (101 ms), `DISC_CLOSE` (38 ms) — 184 320 B total.
   Parsed: `SACD 1.20`, catalog `CDSML8558`, `2019-03-19`,
   `ALBUM Firebird / ARTIST Tomita`, `TWOCHTOC` 2 ch 6 tracks 48:27:20,
   `MULCHTOC` 6 ch 6 tracks 48:34:49. *VERIFIED.*
3. The daemon served the same bytes to the second client: `sacdclient ... 510 10`
   → `45ccd7dfbf433a79d28e877d7441677c`, the LBA-510×10 oracle from
   `master-toc-structure.md` §7 — i.e. the UI sitting in the guest did not
   perturb the read path. *VERIFIED.*
4. Frame rate: **8.0 fps** (240 frames / 30.1 s) after adding a glyph cache; the
   first working run was **0.4 fps** (13 frames / 31.5 s) because every frame
   re-rasterized every glyph through stb_truetype. *VERIFIED (both runs).*
5. The dominant session cost is not the UI: `DISC_OPEN`'s `sacd_authenticate`
   leg (CPSA ioctl + the PSP-detect retry loop) takes **~22 s** in the guest —
   the same ~22 s `sacdclient` spends in its own OPEN. Reading 90 sectors of TOC
   costs 0.36 s total. *VERIFIED; INFERRED that the delay is the PSP detect loop
   (`_SACDCLI_TestPhy` "Signal Lock Failed" × N) — the daemon's own log shows it.*

## 1. Architecture (and the constraint that shaped it)

`tools/sacd_ui.c` is one process that:

1. opens the framebuffer and maps the vendor MT85 pool slice (the proven guest-HUD
   path: fbdev geometry → `pixels + 0x1000`, no DirectFB, no Flip),
2. **runs one client session** per `decode/daemon-socket-protocol.md` §9,
3. closes it, writes `/res/ui-session.done`, then renders for `hold` seconds while
   sampling `/proc/net/tcp` (listener + connection count) and `/proc/<pid>/io`
   (the daemon's own byte counter) four times a second.

The single-session design is not laziness — it is forced. The daemon **accepts into
one shared stack slot and hands its address to every client thread**
(`daemon-socket-protocol.md` §0.6): two simultaneous connections make the first
client thread talk to (and close) the second connection's FD. So the UI takes its
session, closes it, and only then can a second client run. The handshake is a
**marker file written at DISC_CLOSE**, never a sleep guess: the guest sequence
waits for `/res/ui-session.done` before starting `sacdclient`. In c123d the UI's
session closed at t=22.93 s and the client connected at t=24.03 s.

This is also why the UI reads `/proc` for "other client" activity instead of
opening a second socket: a second connection would corrupt both sessions.

## 2. What renders (and where each value comes from)

```
SACD RECONSTRUCT                                    BX510 DAEMON CONSOLE
────────────────────────────────────────────────────────────────────────
DAEMON 127.0.0.1:2002 LISTEN  CLIENTS n  PID p  IO x MB/s     [link lamp]
DISC   1,064,208 SECTORS  SACD 1.20  CAT CDSML8558  2019-03-19
ALBUM  Firebird        ARTIST  Tomita
┌ 2-CHANNEL 2 CH 48:27:20 ─────────┐┌ MULTI-CHANNEL 6 CH 48:34:49 ──────┐
│ 6 TRACKS  LBA 584..353763        ││ 6 TRACKS  LBA 353844..1064126    │
│ #  START    LENGTH    LSN        ││ #  START    LENGTH    LSN        │
│ 1  0:02:00  5:00:11   745        ││ 1  0:02:00  5:02:40   354316     │  … 6 rows each
└──────────────────────────────────┘└──────────────────────────────────┘
EVENT LOG   (timestamped, newest last; '!' red, '*' live amber)
SESSION  open/size/mtoc/a1/a2/close ms   WIRE n B READ BY THIS UI  areas n
         client sessions seen: n  listener UP   RENDER …px font … frames fps
                                                              SESSION OK ▮
```

Provenance: `DISC`/`ALBUM`/`ARTIST`/TOC rows = bytes read over the socket in that
run; `DAEMON`/`CLIENTS`/`IO` = `/proc/net/tcp` + `/proc/<pid>/io`;
`EVENT LOG` = the UI's own session steps plus every listener/client transition it
observed; `SESSION`/`RENDER` = the UI's own counters.

## 3. The TOC parser — offsets, and one correction to the existing decode

Read out of the fixture deterministically (same bytes on the VM):

```sh
python3 - <<'EOF'   # /home/aftermath/sacd-verify/firebird.iso
f=open("/home/aftermath/sacd-verify/firebird.iso","rb")
for lba in (510, 544, 545, 546, 353804, 353805, 353806):
    f.seek(lba*2048); print(lba, f.read(2048)[:8], f.read(0))
EOF
```

Master TOC bundle (sector 0 of `lba 510 x10`), big-endian: `id@0`, `ver@8/9`,
`album_catalog@0x18`, `area_1_toc_1_start@0x40`, `area_2_toc_1_start@0x48`,
`disc_type@0x50`, `area_1_toc_size@0x54`, `area_2_toc_size@0x56`,
`disc_catalog@0x58`, `year@0x78`, `month@0x7a`, `day@0x7b`, `text_area_count@0x80`,
`locales@0x88` — all as `master-toc-structure.md` §2 lists them. SACDText is
sector 1: 16 BE16 offsets at `+0x10`, NUL-terminated strings at those offsets;
lang-0 slots 0/1 = the album/artist strings the UI shows (`Firebird`, `Tomita`).

Area TOC block (`lba @0x40 x @0x54`), verified against both copies:

| off | field | TWOCHTOC @544 | MULCHTOC @353804 |
|---:|---|---:|---:|
| `0x00` | id | `TWOCHTOC` | `MULCHTOC` |
| `0x10` | size (BE16) | 40 | 40 |
| `0x10+4` | max_byte_rate (BE32) | 327680 | 634880 |
| `0x14` | sample_freq / frame_format | 4 / 0 | 4 / 0 |
| `0x20` | channel_count | **2** | **6** |
| `0x22` | max_available_channels | 2 | 6 |
| `0x40` | total_playtime MSF | 48:27:20 | 48:34:49 |
| `0x45` | track_count | **6** | **6** |
| `0x48` | audio range start (BE32) | **584** | **353844** |
| `0x4c` | audio range end (BE32) | **353763** | **1064126** |

**Correction worth keeping:** `firebird-fixture.md` §2.6 labels `@76 = 353763` as
`track_start` and `@80 = 0x01000000` as `track_end`. The real layout is
`track_start@0x48` (= 584 / 353844 — exactly the first audio sector after each
40-sector block) and `track_end@0x4c` (= 353763 / 1064126 — the last audio sector
before the next block). Both copies agree, and the values land on the block
boundaries §4.3 of `master-toc-structure.md` independently predicts. Call this
*VERIFIED against the fixture bytes* (not against the daemon's disassembly, which
is not re-read here).

Track lists live in the area block's own sectors, found by scanning for the tag
ids (robust to offset drift): `SACDTRL1` carries `track_start_lsn[i]` at `+8+4i`
and `track_length_lsn[i]` at `+8+1020+4i`; `SACDTRL2` carries the same slots as
MSF start / duration. Decoded for this disc: 2-ch track 1 = `0:02:00`, `5:00:11`,
LSN 745 … track 6 = `35:37:70`, `12:49:25`, LSN 261507; multi-ch track 1 LSN
354316 … track 6 LSN 878724. Both areas sum to their `total_playtime`.

## 4. Build and the staging channel (budget-checked)

`tools/sacd_ui_build.sh` (era gnuarm 2009q3, `-std=gnu99`, `-Wno-pragmas`,
**dynamic** — the guest rootfs carries the libs `sacdclient` already uses;
`-lrt -lm` because glibc 2.12 keeps `clock_gettime` in librt). Zero warnings with
`-Wall -Wextra` under the era compiler.

Staging rides the channel the guest already extracts — one tgz:

| member | bytes | why |
|---|---:|---|
| `sacd_extract_160`, `sacd_read.ko`, `sacdgate`, `daemon_gate.sh`, `sacdclient` | 492 345 | the existing daemon payload (c122g) |
| `sacd_ui` | 81 044 | this task |
| `fbdump` | 14 216 | the proven pool readback |
| `bx510_fbvirt.ko` | 117 079 | guest framebuffer + vendor pool model |
| `sony-font.ttf` | 62 560 | `/res` is a tmpfs in the probe run, so the shipped `/res/font.bin` is shadowed |
| `sacd_ui_guest.sh` | 3 766 | the in-guest sequence (a file, not a one-liner: Run C43 truncation lesson) |

`tgz` = **348 416 B gz / 806 585 B raw**, and the probe's own arithmetic for the
fire is `fe_test_data payload_size = 972 800 B of 1 048 576 B` (75 776 B free).
Under budget — the font does not need a separate channel.

Binaries kept as payload artifacts (same convention as `sacd_hud`), as built for
the passing run c123d:
`evidence/bx510/display-payload/sacd_ui` sha256 `f64a93e7407f396d…` (the c123c
build was `fc870dd693d0b59c…` — it differs only by the glyph cache) and
`.../fbdump` sha256 `65ad229ed280ca56d…` (`--rows` build).

## 5. The fires — four runs, each with its own lesson

| run | verdict | what it proved / what broke | fix |
|---|---|---|---|
| `c123` | staging error | `sh /res/shim/sacd_ui_guest.sh` → *can't open*: the script lives IN the tgz, which only the script extracted. Chicken-and-egg. | guest command = `tar -xzf …; sh /res/shim/sacd_ui_guest.sh` |
| `c123b` | 3 defects | (a) UI connected, but `OPEN NO REPLY` after 8.4 s; (b) `UI_RC=135`, `UI_DUMP_RC=135` = **SIGBUS** on the pool mapping; (c) `/proc/fb` = `0 mt8530 / 1 fbvirt` — this guest also carries the REAL MTK framebuffer, so fbvirt is **fb1**, and `mknod /dev/fb0 c 29 0` pointed at mt8530 (shorter mapping ⇒ SIGBUS). | socket bound 8 s → **60 s** (the auth leg is 8–20 s); guest script picks fbvirt's index from `/proc/fb` and uses that node for both the UI and the readback |
| `c123c` | loop complete, frame lost | session VERIFIED end-to-end (all 5 wire steps + both area parses + live client CONNECT/GONE + `UI_PASS`, `UI_RC=0`), but the single 691 KB `FBPIX` line was truncated at 1016 of 230 400 pixels — the daemon's kernel threads interleave their console output into it. | `fbdump --rows` (one `FBPIXROW` line per sampled row, additive flag) + `echo 3 > /proc/sys/kernel/printk` before the readback |
| **`c123d`** | **PASS** | `360/360` rows, 0 damaged, mean luminance 12.80, ink in title/status/track bands, `UI_RC=0`, `CLIENT_PASS`, md5 oracle match, 8.0 fps. | — |

The in-guest sequence (each line is a rule that cost a run):

1. `mkdir /tmp; mount -t tmpfs tmpfs /tmp` — the rootfs is read-only squashfs.
2. `ifconfig lo … up`.
3. extract the tgz to `/res`.
4. `insmod bx510_cpsa_peer.ko`, `insmod sacd_read.ko minor=201 comppid=0`,
   `mknod /dev/sacd_read c 10 201`, the two `sacdgate` ioctls.
5. **`sr_fa_mode /dev/sr0 clear` AFTER `sr_mod` is loaded** (c122f: with the latch
   set the daemon "succeeds" on zero FE traffic).
6. `insmod bx510_fbvirt.ko`, pick its `/proc/fb` index, mknod that node.
7. `sacd_extract_160 -S </dev/null >/res/daemon.out 2>&1 &`, then
   `grep -q 'SACD Daemon 0.37 active'` (the oracle).
8. launch `sacd_ui`, **wait for `/res/ui-session.done`** (not a sleep), run
   `sacdclient 127.0.0.1 510 10`, then `wait` for the UI, then
   `fbdump --pool <fbnode> 3 4096 1920 1080 --rows`.

## 6. Gates and their controls

`tools/sacd_ui_gate.py <uart> --png out.png` — PASS requires: `UI_RC=0` (the code
reserves **3** for "frame rendered but the client session failed", so a red screen
cannot pass), pool/canvas evidence, `UI_PASS`, a passing second client, mean
luminance ≥ 4, **and rendered text in three pixel bands** (title / status /
track-table bright-pixel fractions) — a lit-but-blank panel is not evidence.
Interleaving damage is counted, not hidden: >5 % missing rows fails.

Controls (run before the fire, all three behave):

```
black frame            FAIL: framebuffer is black (mean luminance 0.00 < 4.00)
lit, no text           FAIL: no rendered text in the title band (ink 0.0000 < 0.0040)
UI_RC=3 (session bad)  FAIL: UI_RC=3 (3 = frame rendered but the client session failed)
real c123d dump        PASS: rc=0, pool canvas, luminance 12.80, text present in 3 bands
```

## 7. Performance, measured

| what | before | after | why |
|---|---:|---:|---|
| UI frame rate in the guest | 0.4 fps (13 frames / 31.5 s) | **8.0 fps** (240 / 30.1 s) | glyph cache keyed by (char, logical px) — every frame was re-rasterizing ~2 000 glyphs through stb_truetype |
| TOC reads | 191 + 354 + 340 ms | 127 + 129 + 101 ms | console loglevel 3 during the run (less kernel chatter through the same UART) |
| `DISC_OPEN` | 22 292 ms | 22 317 ms | **not the UI**: the daemon's `sacd_authenticate`/PSP-detect leg |

Frame cost is dominated by the full-canvas clear + text blit into the pool
(8.3 MB of stores per frame, plus ~80 lines of device-pixel text). 8 fps is
comfortable for a state console; a 30 fps iteration is possible by redrawing only
the dynamic bands.

## 8. VERIFIED vs INFERRED

VERIFIED (this run, in the guest, from the artifacts named):
- the UI process runs in Sony's guest, draws into the vendor pool via the fbdev
  path, exits 0, and its pixels decode into the PNG above;
- every disc value shown was read over the port-2002 client protocol in that run;
- the second client's session is visible to the UI via `/proc/net/tcp`;
- the daemon's read path is unchanged by the UI (md5 oracle match);
- the build/staging arithmetic and the 1 MiB partition budget;
- **source↔artifact provenance**: rebuilding the committed `tools/sacd_ui.c`
  with the recipe in `tools/sacd_ui_build.sh` reproduces the binary that drew the
  c123d frame bit-for-bit (`sha256 f64a93e7407f396d…`).

INFERRED:
- the ~22 s `DISC_OPEN` is the PSP-detect retry loop (the daemon's own log shows
  `_SACDCLI_TestPhy` "Signal Lock Failed" repeats; not separately timed here);
- the album/artist *roles* of SACDText slots 0/1 (`master-toc-structure.md` §2.1
  already labels the order INFERRED; the strings themselves are VERIFIED);
- fbvirt's pool slice is a faithful stand-in for the real MT85 pool **for
  drawing**: geometry and +0x1000 header-page adoption are the guest-gate
  results, and that gate's own INFERRED note about the header page on real
  hardware still stands.

Not demonstrated (honest gaps): nothing was run on a physical player; the
readback is a 1-in-3 pixel sample of the panel, so a 1-pixel-tall artifact would
be invisible; the UI does not draw through Sony's retail DirectFB layers (it owns
the pool directly, like the HUD's pool path).

## 9. What the user sees now, and the next knobs

Open `evidence/bx510-guest/graphics/sacd-ui-c123d-3x.png`: a dark console with the
title bar, the daemon/link line, the disc identity (1 064 208 sectors, SACD 1.20,
`CDSML8558`, 2019-03-19, `Firebird`/`Tomita`), both area panels with all twelve
track rows (start, length, LSN), and an event log whose last lines are the real
session steps *and* `DAEMON CLIENT CONNECT (1 live)` / `GONE (0 live)` — the
extraction client arriving and leaving while the UI was on screen.

Iteration knobs, no code change needed: `sacd_ui <host> <render_seconds>`;
`SACD_UI_FB`, `SACD_UI_FONT`, `SACD_UI_SCALE`, `SACD_UI_DONE_FILE`. Layout edits
are one re-render away on the Mac (`SACD_UI_SIM`, ~0.3 s per frame) before any
fire.

## 10. Reproduce

```sh
sh tools/sacd_ui_build.sh                       # build + repack the tgz + budget line
printf 'tar -xzf /res/shim/daemon_payload.tgz -C /res; sh /res/shim/sacd_ui_guest.sh\n' \
  > /tmp/g-ui.txt
make bx510-fire RUNID=c1xx GCMD_FILE=/tmp/g-ui.txt TIMEOUT=500
python3 tools/sacd_ui_gate.py evidence/bx510-guest/bdpdrv/bdpdrv-runc1xx.uart.log \
  --png evidence/bx510-guest/graphics/sacd-ui-c1xx.png
```

Layout iteration on the Mac (no VM, no fire):

```sh
cc -O2 -std=gnu99 -Wall -DSACD_UI_SIM -I. -o /tmp/sacd_uim tools/sacd_ui.c -lm
SACD_UI_FONT=evidence/bx510/display-payload/sony-font.ttf \
  /tmp/sacd_uim /tmp/mtoc.bin /tmp/area1.bin /tmp/area2.bin /tmp/ui.ppm
# the fixture files: dd from the ISO at LBA 510 x10, 544 x40, 353804 x40
```

Evidence files in this directory: `sacd-ui-c123d.png`, `sacd-ui-c123d-3x.png`,
`sacd-ui-preview-1080p.png`; transcripts under
`evidence/bx510-guest/bdpdrv/bdpdrv-runc123{,b,c,d}.{uart.log,meta.json,fire.txt}`.

## 11. Files

Added: `tools/sacd_ui.c` (the UI client), `tools/sacd_ui_build.sh` (era build +
tgz repack), `tools/sacd_ui_guest.sh` (in-guest sequence),
`tools/sacd_ui_gate.py` (gate + PNG decoder), this report, the three PNGs, four
run transcripts.

Changed (additive): `tools/bx510_fbdump.c` — `--rows` prints `FBPIXROW <y> <hex>`
per sampled row; the default single-line `FBPIX` output is untouched, so the HUD
lane and `hud_guest_gate.py` are unaffected.

**Concurrency note for the parent:** a sibling session is working the same UI
deliverable in this same checkout (`tools/bx510_ui_build.sh`,
`bx510_ui_build_vm.sh`, `bx510_ui_guest.sh.in`, `bx510_ui_render.py`,
`bx510_ui_shot.py`, `test_bx510_ui_loop.py`, new `bx510-ui-*` Makefile targets,
runs `u1`/`u2`) and its `bx510-ui-build` target defaults to `UI_SRC=tools/sacd_ui.c`
— i.e. the same path this lane implements. This lane touched only its own files
plus the additive `fbdump --rows`, and made no Makefile/AGENTS.md edits (both are
currently modified by the sibling). One of the two lanes should be dropped or
renamed before the commit.
