# Plan: leverage the stock code we already ship, before writing more of our own

Status: plan (2026-11-05). Written after the hardware session that produced a
working 13-FPS HUD and then blanked the panel, plus a rig run that segfaulted
in the retail provider. Both failures point the same way: we are replacing
more of Sony's stack than we need to.

## What stock code actually exists (evidence, checked on the real rootfs)

| Stock asset | Where | What it gives us | Evidence |
|---|---|---|---|
| DirectFB 1.2.7 core | `/lib/libdirectfb-1.2.so.0.7.0` | surfaces, layers, windows, blits, font engine (`dfb_font_create`, `dfb_font_decode_*`) | `nm -D` |
| System provider | `lib/directfb-1.2-0/systems/libdirectfb_mtk.so` | MT85xx vendor init + pool + cmd ring | decoded in `MT85-RESULTS.md` |
| **GFX driver** | `lib/directfb-1.2-0/gfxdrivers/libdirectfb_mt85.so` | accelerated fill/blit (the path that crashes when the ring is faked) | shipped, unused by us |
| **Window managers** | `wm/libdirectfbwm_sawman.so` **and** `wm/libdirectfbwm_default.so` | multi-app windowing — coexistence instead of takeover | shipped |
| Input drivers | `inputdrivers/libdirectfb_{lirc,keyboard,ps2mouse}.so` | IR remote, keyboard | shipped |
| **Sony fonts/messages** | `/res/font.bin` (62 KB), `/res/osdmsg.bin` (4.9 MB) | the device's own glyphs and OSD strings | present |
| Sony images | `/res/logo*.bin`, `logo_clrbar.bin` | boot logo, colour-bar art — authentic visuals | present |
| Appliance UI | `bdpprog` + `libX2.so` + `.rel` apps | draws via `x_gl_*` natively, references `libdirectfb` by name | `strings`, `nm` |
| Kernel driver | `bdpdrv.ko` (8.1 MB) | the REAL display/CPSA stack (vs our `fbvirt`) | shipped |

## What we currently replace ourselves (and pay for)

1. **Text**: hand-rolled 5×7 bitmap font. Sony ships a font engine *and*
   font assets. Our thin, small text was the first operator complaint.
2. **Windowing**: we take over the primary and assume we own the panel. Sony
   ships two WMs; `bdpprog` is a DirectFB-capable client. Takeover is why the
   UI never comes back and why two drawers fight.
3. **Acceleration**: we route through the provider's cmdbuf (StretchBlit) and
   crash when `fbvirt` fakes `FBIO_DISPATCHHW`.
4. **Presentation model**: we assume `/dev/fb0` is the scan-out (it is not —
   proven), instead of using layers/windows the way stock code does.

## Phases (ordered by payoff per hour)

### S1 — Sony's own font and assets in the HUD (hours, not days)

- Load `/res/font.bin` through DirectFB's font API (`dfb_font_create` /
  `IDirectFBFont`) if the format is DGI: then `DrawString` replaces our glyph
  painter and text becomes the device's own, at real sizes.
- If `font.bin` is a Sony-private container, write the decoder (deterministic
  bytes-through-tools, `tools/bx510_fontdecode.py`) — it is 62 KB, small.
- Use `logo_clrbar.bin`/`logo.bin` as blit sources for backgrounds instead of
  procedural patterns.
- **Acceptance**: HUD text rendered by DirectFB's font engine, readable at 1080p,
  plus one stock image blitted; photo evidence.

### S2 — Stop taking the panel over; use the stock WM (1-2 days)

- Create an `IDirectFBWindow` (or a SaWMan window) instead of the primary, so
  the appliance UI keeps running underneath and our HUD is a window.
- This is also the coexistence answer for the product: a HUD that can appear
  over the stock UI, not instead of it.
- **Acceptance**: stock UI visible, HUD window on top, UI returns when the HUD
  exits; no double-draw flicker.

### S3 — Make the rig faithful where it lied to us (1 day)

Two fbvirt gaps, in this order:
1. **Mode parity**: advertise the player's exact mode (1280×720, stride 7680,
   ARGB, virtual 1920→2160) instead of 720×576. Every pitch/size bug tonight came
   from this mismatch.
2. **Ring semantics**: implement `FBIO_DISPATCHHW` for real (32-byte header,
   64-byte items, maxcount, read/write index handshake, `WR_LOCK/UNLOCK`), so the
   accelerated fill/blit executes instead of the provider faulting.
- **Acceptance**: `sacd_hud` runs in the guest to completion (no SIGSEGV), the
  pool slice is dumped, and the PNG matches the drawing code's intent.

### S4 — Measure the panel the way the panel is fed (half day)

- Dump the **pool buffer the provider mapped** (not fb0) and diff it against a
  phone photo of the same state; that is the only honest "it looks like this"
  check we can automate.

### S5 — Try the real kernel driver in the rig (1-2 days, speculative)

- Load `bdpdrv.ko` in the guest instead of `fbvirt` and model only the MT85
  display registers it touches. If it probes, the rig runs the *real* display
  stack end to end (and the HUD/ring work in S3 becomes unnecessary).
- Fallback if it does not probe: keep `fbvirt` + S3, and record exactly which
  registers bdpdrv needed.

### S6 — Stock input and messages (optional)

- `libdirectfb_lirc` for the remote (scroll/panels), `/res/osdmsg.bin` for
  authentic OSD text.

## What this buys, in one line each

- S1: text that looks like the device's, not ours.
- S2: the appliance UI survives us — the product-level requirement.
- S3: a rig that can test the crashing path instead of the player.
- S4: an automated screenshot check that means something.
- S5: highest fidelity available without hardware.

## Non-goals / honest limits

- FPS in QEMU will never predict FPS on an ARM926; timing stays a hardware
  measurement.
- `bdpprog`'s `x_gl_*` path stays opaque until `.rel`/X2 decode (U1/U4); S2 only
  needs it to *keep drawing*, not to be understood.
- Sony's font may be bitmap-only; if so, sizes are fixed and the HUD must
  compose from the sizes it ships.
