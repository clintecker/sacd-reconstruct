# Drawing primitive in QEMU — rung results (2026-11-03)

Can we draw in QEMU? Yes — two rungs proven, one precisely scoped.

## Rung 1: raw fbdev drawing — COMPLETE

bx510_fbvirt.ko (guest module, native-armv6 recipe) registers a
standard 2.6.35 framebuffer: 720x576 @32bpp, 1,658,880 bytes of
vmalloc RAM, /dev/fb0 (fb0, major 29). bx510_fbdraw (user space)
opens, mmaps, paints a deterministic test pattern (8-color bars /
diagonal gradient / checkerboard), re-reads through a fresh mapping,
and renders a 60x18 luminance ASCII dump + full-frame md5 into the
UART log. Evidence (evidence/bx510-guest/graphics/fbsmoke-20261103.log):

```
FBDRAW: pattern painted and re-read, 1658880 bytes
[ASCII art showing all three pattern regions exactly as designed]
FBDRAW: full-frame md5: 7d19af14518cb5c201aedab2cf94e83d
```

Our own code now owns a working pixel path in the real guest OS.

## Rung 2: the device's own DirectFB — LIVE to the MT85xx boundary

bx510_fbdraw's directfb mode dlopen's /lib/libdirectfb-1.2.so.0 (the
SHIPPED lib from the device's rootfs, running in the guest's own
rootfs), then DirectFBInit -> SetOption(system=fbdev... actually the
mtk provider loads) -> DirectFBCreate. With the guest providing what
the real initramfs would provide, the shipped stack initializes
layer by layer:

- Multi Application Core (the device's 2012-10-27 build) starts
- Fusion/SHM works (the guest loads its OWN fusion.ko from
  /lib/modules/2.6.35/BDP; /dev/fusion0 via mknod + tmpredir)
- Fusion dispatch thread runs; /dev/shm provisioned inside the
  /res tmpfs
- VT switcher thread runs (tty0..tty7 + vc/0..vc/7 nodes created)
- **MediaTek/System: system_initialize: #237 — the real MTK system
  provider starts**
- ...and issues FBIO_INIT, the first MT85xx-custom ioctl, which a
  standard fbdev does not implement: ENOTTY. DirectFBCreate rc=2.

That is the exact boundary: everything standard works in our guest;
only the ~6 vendor ioctls (FBIO_INIT, FBIO_GETIMAGEBUFFER,
FBIO_GETMULTIPOOL, FBIO_GETCMDBUFLEN/RELCMDBUF, FBIO_SET) stand
between the shipped stack and a live surface.

## Boot-loop lessons (all fixed in tracked code)

- this kernel does not export the cfb_* blit helpers (CONFIG_FB_CFB_*
  off) — fbvirt drops them; drawing is user-space mmap
- the guest has no /dev (initramfs-provided on real hardware): every
  node is created under /res/dev and reached through tmpredir
- remap_vmalloc_range returns EINVAL on this 2.6.35/armv6 build; the
  classic vfb.c mmap-mutation pattern SIGSEGVs (zero-length VMA torn
  down); the fix is a local cursor + remap_pfn_range per page
- DirectFB needs the tool run under LD_PRELOAD=tmpredir so its literal
  /dev/fusion0, /dev/fb0, /dev/shm, /dev/ttyN opens reach /res/dev/*
- no /dev/null in the guest (known) — redirects go to /res/e

## Next (precisely scoped)

1. Extract the six MT85xx ioctl numbers + struct semantics from the
   31 KB provider (proper disassembly pass — the shell-objdump PLT
   chase stalled; use Ghidra or a scripted objdump+reloc analysis).
2. Implement them in fbvirt (a command buffer, an image pool, layer
   SET) — the shipped DirectFB then has a live surface in the guest.
3. Then: DrawString/Blit via the real libdirectfb, captured to a
   host-side image via a framebuffer-dump channel.


## Rung 1b: cyberdraw — the vibey test pattern (2026-11-04)

bx510_cyberdraw.c draws an old-school hacker/cyberpunk console scene,
100% procedural (5x7 hand-rolled font, no deps), resolution-adaptive via
FBIOGET_VSCREENINFO (32bpp + 16bpp RGB565): phosphor banner, typed boot
log with ACCESS GRANTED + blinking cursor, rotating wireframe cube,
scrolling perspective grid, CRT scanlines + green sweep, corner brackets.

Why a recognizable pattern: a TV photo of THIS cannot be confused with
any appliance UI — the visual is self-authenticating hardware evidence.

Modes: --static (deterministic frame + max-luminance ASCII + embedded
md5) and --anim [secs] (15 fps, capped 100s; hardware TV-video mode).

QEMU proof (evidence/bx510-guest/graphics/cybersmoke-20261104.log,
720x576@32bpp via fbvirt): full-frame md5 f3392f1ac70471872bc64edef4037554
IDENTICAL across two independent boots. ASCII dump shows banner, boot
log, cube, grid floor, footer exactly as designed. Probe wiring:
bx510_phase0_probe.py --cyberdraw (runs after the fbdraw rung under
--fbmod; deterministic-only in the guest — anim is a hardware mode).

Hardware plan: stage cyberdraw on the session USB; run --anim in the
standby window (TV photo/video = display evidence); run --static for
the md5 if a return channel exists (hwmon log).
