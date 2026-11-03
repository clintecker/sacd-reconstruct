# BX510 screen probe

This ARM binary writes custom color bars into a window on the player's existing DirectFB graphics layer. The default pattern is 320 × 96 in the center of the TV for three seconds. The fullscreen option covers the current layer for three seconds. Both modes use Sony's reported pixel pitch. The window closes to reveal the UI underneath.

## With a test copy of your working AutoScript USB

**Existing `/Volumes/SACD` test stick:** The first hardware report confirmed the v1 wrapper ran twice and that the framebuffer queries succeeded. With Home visible, try the already installed build for 30 seconds without pressing power a second time. To collect per-call and process diagnostics, copy the old log to the Mac and run `sh usb.sh refresh "/Volumes/SACD"` from this folder. This supports the reported v1 launcher hash and preserves the original files and logs. Use `restore` when returning to the original-daemon baseline.

If the power-button sequence puts the TV in low-power mode, first run a display-only test. On the Mac run `sh usb.sh awake "/Volumes/YOUR SPARE STICK"` from this folder. Use a spare FAT32 stick without an existing AutoScript directory. With this stick inserted, turn the Sony on normally and leave it at Home for 30 seconds on the TV’s Sony HDMI input. The script creates `AutoScript/BX510Screen/entered.txt` before trying the graphics stack. Send that marker, `bx510-screen.log`, `boot-info.txt` and what you saw. In this mode the probe neither launches a daemon nor opens a network port. The USB launch syntax follows an existing standalone program whose maintainer reports a working S5100/BX510. [AutoScript example](https://github.com/saramibreak/SacdImageCreator/blob/4cfbb257e9fa852ea355132f3df34943a5e62833/AutoScript/AutoScript)

1. Duplicate your working rip stick. On your Mac, unzip this package and open Terminal in the extracted folder containing `usb.sh`.
2. Run `sh usb.sh install "/Volumes/NAME"`, replacing NAME with the **test copy**. The installer verifies the original daemon’s SHA-256 before saving a copy under `AutoScript/BX510Screen/original/`. It replaces the daemon entry point on that stick with a shell launcher. Your existing AutoScript and AutoScript.TSS files are used as supplied.
3. Eject the stick normally. Select the player’s HDMI input on the TV, keep the player awake and use your usual USB startup procedure. The launcher starts the saved original daemon with its original arguments. When launched with `-S`, it also starts the graphics probe after five seconds. A disc is optional for this display test.
4. Look for eight color bars. After taking the stick back to the Mac, inspect `AutoScript/BX510Screen/bx510-screen.log`. The PID line records that the server process existed at probe time. `DRAW_EXIT=0` records a successful window/surface call sequence. What appeared on the TV is the physical observation. The helper also writes `AutoScript/BX510Screen/boot-info.txt` with read-only kernel, partition, mount and framebuffer information for the emulator comparison.
5. To try full-screen bars on the next start, create an empty file called `AutoScript/BX510Screen/FULLSCREEN` on the test stick. Remove the file to return to the smaller window.
6. Run `sh usb.sh restore "/Volumes/NAME"` to restore the original launcher filename from the verified backup. The log and backup stay on the test stick.

The helper expects the known 350,830-byte original daemon, SHA-256 `0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45`, and a player USB mount under `/mnt/sd*/AutoScript`. The player must invoke the daemon entry point as an executable for the shell wrapper to run. If the hash differs, preserve your working setup and use the direct command below from an existing player shell or command hook. A failure before the PID line points to the launcher or USB path. An initialization error in the log points to Sony’s display session. HDMI can also be inactive during standby.

## From an existing player shell

Copy the screen folder onto the stick and run the following **on the player**, adjusting the mount path to match your stick.

```sh
/bin/sh /mnt/sda1/AutoScript/BX510Screen/run-screen.sh --info
/bin/sh /mnt/sda1/AutoScript/BX510Screen/run-screen.sh --bars
/bin/sh /mnt/sda1/AutoScript/BX510Screen/run-screen.sh --fullscreen
```

`--info` only queries the framebuffer. The script stages the ARM executable in a private temporary directory so it also works with a non-executable USB mount. The screen experiment does not install a kernel module or issue disc commands. Collect the untouched Firebird baseline separately from an instrumented or wrapped run.

## Firmware and verification

The M15.R.0257 root filesystem contains the MT85 DirectFB system driver and a SaWMan window-manager configuration in `/usr/etc/directfbrc`. It assigns layer 0 to middle/upper graphics and layer 1 to lower video. Sony’s `systems/mtk/mt85.c` maps different pools and the command buffer through the same device file. The probe asks DirectFB for an ARGB8888 surface and writes the pixels returned by `Lock`. It uses the existing Fusion session in client mode and bounds its wait. The screen program accepts no focus or input.

Tested on the emulated BX510 with Sony’s stock Linux 2.6.35 and DirectFB 1.2.7. The ARM self-test verified all eight ARGB values, preserved row padding and rejected an invalid pitch. The emulator has no display device, and the visible-window call returned an initialization failure when Fusion device 0 was unavailable. The hardware report from a BDP-S5100 on M15.R.0257 confirmed the wrapper and framebuffer info path. It reported `mt8530`, 1920×1080 visible, 1920×2160 virtual, 32 bpp, 7,680-byte row stride and 16 MiB framebuffer memory. HDMI went to no signal after the power-button transition. No bars were observed. Run 2 ended with exit status 142. The earlier trace does not establish the exact blocking call or why there were two PIDs. The larger virtual height allows two frame-sized regions but does not identify the active OSD surface or its pool.

The source and build recipe are included. To reproduce the binary, use Zig 0.13.0, Sony’s DirectFB source and the firmware’s own `/lib` directory. Extract the inner `DirectFB/DirectFB/DirectFB-1.2.7.tar.bz2` from Sony’s download. Run `sh build_screen.sh /path/to/DirectFB-1.2.7 /path/to/extracted-root/lib bx510-screen`. Sources are GPL-2.0-or-later. [Sony’s BX510 source distribution](https://oss.sony.net/Products/Linux/Video/BDP-S1100.html) · [Sony’s firmware](https://www.sony.com/electronics/support/downloads/00015891)
