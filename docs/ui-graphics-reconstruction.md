# Appliance UI & graphics stack — survey findings and reconstruction outline

Status: survey document (high-level outline, pre-commitment)
Date: 2026-11-03
Scope: the BX510's main Blu-ray interface — how it draws graphics and
does everything else on the device. Separately tracked per the
virtual-drive team's round-4 list (initrd, appliance startup,
graphics/UI, host networking, accurate SATA).

## The reframe that matters

There is nothing to exfiltrate: we already possess every byte. The
firmware images in the emulator kit (`~/bx510-emu/images`) contain the
full NAND dump (256 MB), the kernel, and the root filesystem; the root
squashfs is now unpacked at `/tmp/rootfs` on the VM (`squashfs-tools`
via apt, exposure logged). This is an analysis problem, not an
acquisition problem.

## Inventory (what we hold, verified)

### The UI application layer: the X2 platform (`/res/X2/__system/`)

The main UI is a set of **application modules loaded by an "X2"
runtime** — not monolithic binaries in `/bin`:

- `bin/*.rel` — the UI applications, each a self-contained screen or
  service (40–367 KB each): `AudioOutput.rel`, `AutoCalibration.rel`,
  `BDPHDMISetting.rel`, `BGMRegister.rel`, `BIVLServiceUpdater.rel`,
  `BivlErrorDlg/Favorite/NetworkCheck.rel` (Sony's BIVL video
  service), `BudaDelete.rel`, `CautionApp/CautionService.rel`,
  `ContentInfoDistributor.rel`, `DSDOutputModel.rel`, `DemoMode.rel`,
  `DeviceAccessModerator.rel`, `DiscLockBD.rel`, `DivXVOD.rel`,
  `DlnaControllerSettings.rel`, …
- `xml/` — UI layout/definitions (a large directory: the screens are
  at least partly data-driven)
- `img/` — the UI image assets
- `font/`, `dic/`, `sound/` — fonts, dictionaries, UI sounds
- `main.prml`, `main-CHN/JPN/LTN.prml` — regional UI profiles
- `hsinchuReg.xdb` — a registration/settings database

The `.rel` format and the X2 runtime loader are the first decode
targets. The runtime itself is not in the squashfs `bin/sbin/usr-bin`
(a strings scan found no Qt-linked executable there) — it is most
likely in the **initrd** (533 KB, still undecoded), which is where
normal appliance boot currently stops on the emulator.

### The rendering stack (`/lib`, `/usr/lib`)

- **Qt 4.7** — `libQtGui` (3.8 MB), `libQtCore` (2.5 MB),
  `libQtWebKit` (10.3 MB), `libQtNetwork/Sql/Xml`; embedded Qt of this
  era renders through QWS or a platform plugin
- **DirectFB 1.2.0** (`libdirectfb-1.2.so.0.7.0`) — the graphics
  abstraction bridging Qt surfaces to the MediaTek display hardware
- `libBDQtVirtualKb.so` — the player's Qt virtual keyboard
  (BD-specific Qt component)
- `libViewComponent.so` — the shared view layer
- `libfreetype` (2.x) — text rasterization; `libavcodec/libavformat`
  (FFmpeg 52.x) — media decode; `libplayready.so` (DRM)
- **Browser**: `usr/browser` carries an **Opera** directory
  (`opera_dir/`, styles, jsplugins) — the browser UI is Opera-based;
  QtWebKit likely serves the apps/services screens

### The kernel side

- `bdpdrv.ko` — **8.1 MB**, the monolithic BDP driver stack: display
  controller programming, video planes, and the CPSA machinery we
  already know from the SACD work. The hardware end of the drawing
  pipeline — plane setup, pixel formats, OSD composition, scaler
  registers — lives here.
- 39 further modules (filesystems, USB, WiFi rt3370, snd-usb-audio,
  `sata_mt85xx_mod`, `hst_*` Atheros HAL stack, …) — inventoried and
  size-sorted in the survey log.

### The assets (`/res`)

- `font.bin`, `font_java.bin` — bitmap font sheets
- `logo*.bin` — raw framebuffer-style images (boot logo, music
  background, color bars — likely OSD-plane dumps; format TBD)
- `osdmsg.bin` — 4.9 MB of on-screen-display message data
  (localized strings/icons)
- `image.bin`, `image_browser.bin`, `bg_party.bin`, `T8032_8560.bin`,
  `noah_8560.bin`

### The deep unknown

- `initrd_1.bin` (533 KB) — the transformation is still undecoded
  (both teams have failed so far). It almost certainly contains the
  real init, the OSAL base (`UTIL_Printf`, `SYS_Printf`, `Assert`, …),
  the X2 runtime, and possibly the UI launcher. This gates a complete
  picture of appliance startup.

## The drawing pipeline (inferred; each link to verify)

```
X2 runtime (.rel applications, XML layouts)
  -> Qt 4.7 (QtGui widgets/scenes, QWS or platform plugin)
  -> DirectFB 1.2 (surfaces, blitters)
  -> bdpdrv.ko display ioctls (plane setup, composition)
  -> MT8560 display controller (OSD/GDP planes, scaler, HDMI encoder)
  -> TV
```

Parallel paths: FFmpeg decode planes for video playback; freetype for
text into surfaces; `logo*.bin` pre-rendered frames likely pushed
straight to an OSD plane at boot.

## Work phases

**U0 — Survey deliverable** (days, mostly done): full inventory
(this document), module classification by nm-exports, `.rel`/`.prml`
format identification, asset format headers. Output: inventory tables
+ this doc.

**U1 — X2 application format** (days): decode `.rel` (ARM ELF?
relocatable object? custom container?) and `.prml`/XML — with a
deterministic decoder tool per the house rules (never eyeball
hexdumps). If `.rel` files are ELF relocatables, the Qt linkage and
every screen's logic are directly disassemblable with the proven
SACD workflow.

**U2 — Display contract** (weeks): disassemble the display-facing
functions of `bdpdrv.ko` (8.1 MB — by subsystem, never wholesale) +
the DirectFB system driver + the Qt platform plugin. Deliverable: a
`display-contract.md` — the ioctl table, plane/pixel formats, and
register semantics, the same way the module init contract was decoded
for `sacd_read.ko`.

**U3 — Asset decoders** (days): `tools/` decoders for font.bin,
logo*.bin, osdmsg.bin, X2 img/ assets → PNG/text. Verification:
round-trip and visual sanity, deterministic and re-runnable.

**U4 — Initrd decode** (unknown effort; shared with the emulator
track): unlocks the real init, OSAL base, and the X2 runtime/
launcher. The single highest-leverage unknown in the whole appliance
picture.

**U5 — Optional: emulator display model.** From U2's register
knowledge, add a display controller to our QEMU `sony-bx510` machine
(the HDHOST playbook: understand the contract, model the device,
watch it work) — boot the real UI to a virtual framebuffer and diff
frame dumps. This is the "watch it draw" endgame, and it feeds the
same emulator the whole verification program runs on.

**U6 — Optional: component reconstruction.** If any single behavior
needs deep understanding (e.g. a specific screen's logic), apply the
SACD playbook — function-level parity of the specific `.rel` app or
library — rather than the whole stack.

## Verification doctrine (unchanged from the SACD program)

- Deterministic decoders for every binary asset; bytes through tools,
  never eyeballed
- Claims about behavior require observable evidence (framebuffer
  dumps, register traces, wire-level captures)
- Emulator limitations labeled honestly (no HDMI encoder model, no
  video-decode hardware in the sony-bx510 machine today)
- Hardware stays ground truth: a photograph of the actual player's
  output can anchor any framebuffer-diff claim

## Risks / open questions

- Initrd decode difficulty (both teams' attempts so far failed) — the
  X2 runtime may not be reachable without it
- `.rel` format unknown until U1; if custom/packed, a container
  decoder comes first
- bdpdrv.ko's 8.1 MB scale — tractable only subsystem-by-subsystem
- "Correct drawing" verification without HDMI capture (a TV photo is
  the pragmatic anchor)
- Qt-DirectFB plugin details may sit in a plugin .so not yet
  located (likely initrd again)

## Where this lives

Everything is on the VM at `/tmp/rootfs` (regenerable: unsquashfs of
`~/bx510-emu/images/rootfs_normal_1.bin`) — and the source images are
in the emulator kit. No new acquisition is needed at any phase.
