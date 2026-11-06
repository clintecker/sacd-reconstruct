# Handoff: BX510 graphics subsystem & appliance research (2026-11-03)

State-of-knowledge snapshot for any agent picking up the UI/graphics +
appliance-behavior thread. Full conversation context lives in the
session; everything referenced here is committed in this repo.

## 0. Mission context

This project reconstructed the closed-source SACD daemon
(sacd_extract_160, SHA 0fdcefdb...) at function-level parity (388/390)
and proved it byte-identical across qemu-user replay, full-system
in-guest differential with raw wire captures, and (hardware leg) the
on-player session. The graphics work sits on the same infrastructure:
Sony's real kernel 2.6.35 + real squashfs booted in our own QEMU
player.local machine, with module-seam tools (bdpvirt, hdhost.ko,
fbvirt.ko, tmpredir, bx510_phase0_probe.py).

## 1. Nothing to exfiltrate: we hold every byte

~/bx510-emu/images: full NAND dump (256MB), kernel.uImage,
initrd_1.bin, rootfs_normal_1.bin (69MB squashfs, unpacked at
VM:/tmp/rootfs). squashfs-tools installed via apt (policy-allowlisted,
exposure logged).

## 2. Appliance/UI inventory (verified from the unpacked rootfs)

- usr/local/bin/bdpprog = the main appliance process (initially
  missed — lives in usr/local/bin). Links libmtp/libcurl/libimtkpb_drm
  and drives the X2 runtime as a LIBRARY (libX2.so, X2_main).
- UI apps are X2 .rel modules (res/X2/__system/bin/*.rel, 40-367KB
  each) + xml layouts, img assets, fonts, regional .prml profiles.
  .rel format: still undecoded (decode target U1).
- Rendering stack: Qt 4.7 (QtGui 3.8MB, QtCore 2.5MB, QtWebKit
  10.3MB), DirectFB 1.2.7 (+ usr/etc/directfbrc), freetype, FFmpeg
  52.x, libplayready. Browser: Opera in usr/browser.
- DirectFB drivers shipped: systems/libdirectfb_mtk.so (31KB — THE
  MT85xx system provider, the compressed user-side display contract),
  gfxdrivers/libdirectfb_mt85.so, wm/libdirectfbwm_sawman.so
  (SaWMan multi-app coexistence is architecturally supported).
- Kernel: bdpdrv.ko 8.1MB (monolithic display/video/CPSA stack);
  fusion.ko (DirectFB IPC) loads cleanly in our guest; 39 more modules.
- Assets in /res: font.bin, osdmsg.bin 4.9MB, logo*.bin.
- Deep unknown: initrd_1.bin (533KB) — transformation undecoded;
  contains real init + OSAL base + likely the X2 launcher. Gates the
  complete boot picture.

## 3. MT85xx display contract (from the 31KB provider)

Provider opens /dev/fb0 and issues MT85xx-extended ioctls: FBIO_INIT,
FBIO_GETIMAGEBUFFER, FBIO_GETMULTIPOOL, FBIO_GETCMDBUFLEN, FBIO_RELCMDBUF,
FBIO_SET (+MT85FB_SET_MASK_SAFETY) plus standard FBIOGET_FSCREENINFO.
Architecture: mapped GFX command buffer + multi image pool; hardware
compositor executes. Exported symbols: mt85AdapterCmdBufInit/Uninit,
_mapColorFormat, mt85xx_check_wait_vsync, surface-manager, VT mgmt.
IOCTL NUMBERS NOT YET EXTRACTED — shell-objdump PLT chase stalled;
needs Ghidra or reloc-aware scripted pass (ioctl GOT slot 0xf1e4).

## 4. Drawing in QEMU — proven live

Rung 1 COMPLETE (canonical 3a6531a, evidence/
bx510-guest/graphics/): tools/bx510_fbvirt.c registers a standard
720x576@32bpp framebuffer; bx510_fbdraw paints via mmap and emits
ASCII + md5 evidence (7d19af14...).

Rung 2 to the exact vendor boundary: fbdraw directfb dlopens the
SHIPPED /lib/libdirectfb-1.2.so.0; with the guest supplying what the
real initramfs would (own fusion.ko; /res/dev/{fb0,fusion0,tty*,vc*}
nodes; /res/dev/shm; tool under LD_PRELOAD=tmpredir), the stack
initializes through Multi Application Core, Fusion/SHM, VT switcher,
MediaTek/System system_initialize: #237 — then FBIO_INIT ENOTTY.
Everything standard works; six vendor ioctls remain.

Boot-loop lessons (tracked): no cfb_* helpers exported; no /dev in the
guest (all via /res/dev + tmpredir); remap_vmalloc_range EINVAL on
this 2.6.35/armv6 build AND the vfb.c vma-mutation mmap pattern
SIGSEGVs (zero-length VMA torn down) — local-cursor remap_pfn_range
per page; no /dev/null in the guest.

## 5. Standby: pause, not death (corrected model)

Operator observed: power press -> screen off, tray in, daemon keeps
serving. Evidence: bdpprog has SetResumeInfo / ResumeInfoDef /
quick-standby strings; .rel apps have sysStandbyHandler/
sysResumeHandler message handlers — you don't give a dead process a
resume handler. Model: power press -> standby message -> bdpprog
saves resume state, blanks planes via bdpdrv display ioctls, STAYS
ALIVE holding its DirectFB/fusion session. This is INFERENCE pending
the hwmon watcher proof (staged for the hardware session).

## 6. Consequences for "our own pixels"

Interface tiers: Tier 1 = link shipped DirectFB; Tier 2 = decode the
31KB provider -> mt85xx-fbdev-graphics-contract.md; Tier 3 =
dependency-free raw-ioctl client. Coexistence: strategy A (draw in
standby) LIKELY FALSE — the competitor sleeps holding its session;
strategy B (SaWMan multi-app) = main path, wake-collision risk;
strategy C (never let bdpprog start, via USB AutoScript boot) =
strongest for a ripping station. Keep the reconstruction binary at
parity — a companion graphics service draws.

## 7. Open work, priority order

1. HW session (operator has hardware): primary = reconstructed-binary
   verification per PLAYER-SESSION-RUNBOOK.md; add-on = hwmon standby
   watcher (staged automatically by usb-build now).
2. MT85xx ioctl extraction -> implement in fbvirt -> shipped DirectFB
   gets a live QEMU surface.
3. .rel/.prml format decode (U1).
4. Initrd decode (U4, shared with the emulator track).
5. gfx-hello on hardware (needs DirectFB 1.2.7 source fetch Mac-side
   + link pass against the shipped libs).

## 8. House rules that apply

Verified vs inferred must be labeled; bytes decoded through tools;
deterministic decoders for binary assets; hardware is ground truth
(TV photo, pair capture); regenerable artifacts stay out of git
(SHA-recorded manifests); VM outbound = apt allowlist only; commit
through make sacd-commit, sync through make sacd-sync-standalone;
ALWAYS operate via /Users/you/bin/sacd (CWD-reset incident history:
a490e51).
