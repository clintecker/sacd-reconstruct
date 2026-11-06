# BX510 at-home test card

You need the player, its remote, the Mac on the same LAN, Firebird, and the USB you already use to rip. A second, duplicate USB is useful for the optional screen test.

## Start here after your first hardware report

Your current `/Volumes/SACD` stick already has the working wrapper and a verified backup of the original daemon. The first two launches reached `--info` on the physical player. The first log has no finish record. The second ended with `DRAW_EXIT=142` in standby. The probe reached Fusion initialization. The first probe version did not log completion of each DirectFB call.

**One experiment changes only power state.** Keep the existing stick as it is, select the Sony HDMI input, turn on the player once, and leave Home visible for at least 30 seconds. Let the tray open as usual. Keep the power button untouched, leave Lossless Extract disconnected, and run `nc -vz -G 3 192.0.2.10 2002` on the Mac while Home is visible. Send the exact output, whether bars appeared, and the new part of the log. A TCP connection checks the listener. Firebird sector reads are the next, separate test.

Then press power as you normally do for a rip and run the same Mac command after the OFF blinking stops. Label the two results **Home** and **standby**. If you are already in standby, collect that reading first. Your AutoScript launches `/sacd_extract_160 -S &` before its tray command. The two readings determine when the listener is reachable on your player. A disc read may have separate drive-ownership requirements. “Leave Home visible” means keep the player on at the menu for the first reading.

**For the instrumented retry**, first copy your current `bx510-screen.log` to the Mac. Eject the USB from the player normally, mount it on the Mac, then run this from the extracted home kit:

```sh
sh screen/usb.sh refresh "/Volumes/SACD"
```

This verifies the installed wrapper and original backup. It updates the helper and wrapper on the already prepared stick and preserves both original AutoScript files, the backed-up original ELF and earlier logs. It accepts the exact wrapper hash you reported. Repeat the **awake** test. Send `AutoScript/BX510Screen/bx510-screen.log` and `AutoScript/BX510Screen/boot-info.txt`. The new logs contain per-call BEGIN/END markers, uptime, wrapper PID/parent and launch path, boot ID where available, and selected Fusion/display process details. With only one working stick, the separate `awake` mode below is optional. Do not use `install` again on your already wrapped stick.

## 1. Identify the player

Your reported device is **Sony BDP-S5100, M15.R.0257, 192.0.2.10**. Sony distributes the same US firmware update for the S5100 and BX510. You observed the TV enter low-power mode after the usual power-button sequence. To see whether the original daemon is still listening, leave it in that state and run the following on your Mac on the same LAN.

```sh
nc -vz -G 3 192.0.2.10 2002
```

Send the exact result and identify the USB used. A successful connection makes the next test the Firebird capture. A refusal means the address answered but port 2002 wasn’t accepting connections at that instant. A timeout leaves both power and network reachability open. This port check is for a daemon USB. The standalone display stick in step 3 starts only the display probe.

## 2. Capture Firebird over the LAN

1. For the untouched baseline, save the screen logs and restore the original daemon on the current stick with `sh screen/usb.sh restore "/Volumes/SACD"`, or use a separate original stick. Follow your normal ripping procedure. Put in the Firebird SACD and disconnect Lossless Extract so the baseline has one client.
2. On the Mac, open Terminal in this extracted kit folder. With the player at its previously reported address, run

```sh
python3 firebird.py --host 192.0.2.10 --model BDP-S5100 --firmware M15.R.0257
```

The runner loads the maintainers's exact capture client from a matching local checkout or via your authenticated GitHub CLI. If you prefer to use an existing local copy, pass `--client /path/to/sacd-reconstruct/tools/sacd_client.py`. It must match the recorded commit. Replace the IP if it has changed. Optional arguments are `--model`, `--firmware`, `--disc-id` and `--iso "/path/to/Firebird.iso"`. The ISO stays on your Mac. Python 3.8 or newer is sufficient.

3. **Send `bx510-firebird/send-this.zip`**. It contains the client log, available manifest and device metadata. On a successful run the checks cover nine exchanges, positive open/size/read/close results, a reconnect and four read records. With an ISO they also verify each returned sector and its complete response-frame hash. On failure, send whatever log the runner saved and the final terminal error. Use a fresh directory on a retry, e.g. `--out bx510-firebird-2`.

The original USB establishes the reference. The optional screen or tracing launchers belong on subsequent runs.

## 3. Optional HDMI and normal-boot observations

**First isolate the display from standby.** On a spare FAT32 USB with no existing `AutoScript` directory, run

```sh
sh screen/usb.sh awake "/Volumes/YOUR SPARE STICK"
```

Eject the stick normally. With the TV on the Sony input, insert the stick while the player is off, turn the player **on normally**, and leave it awake on the Home screen for 30 seconds. Do not press the power button a second time during this display-only test. The launcher first writes `AutoScript/BX510Screen/entered.txt`, then attempts to draw the pattern. This creates separate evidence for USB script execution and HDMI rendering. Return `entered.txt`, `bx510-screen.log`, `boot-info.txt` and what appeared on the TV. If none were written, send the file listing of the stick’s `AutoScript` directory.

**Then test the daemon and display together**, if desired.

Use a **duplicate** of the working USB. In the kit folder on your Mac run

```sh
sh screen/usb.sh install "/Volumes/YOUR TEST STICK"
```

Eject the stick normally. Select the Sony’s HDMI input, keep the player awake and start the daemon as usual. The original daemon is preserved and the graphics helper should briefly display eight colored bars. The read-only boot snapshot runs even if graphics initialization fails.

**Return these two files from the test USB plus what you saw on the TV.**

- `AutoScript/BX510Screen/bx510-screen.log`
- `AutoScript/BX510Screen/boot-info.txt`

The second file includes the kernel version, boot command line, flash partition list, mounted filesystems and framebuffer listing, as available. These help compare the emulator’s early boot with yours. If you already have a player shell, the equivalent read-only command is `cat /proc/version /proc/cmdline /proc/mtd /proc/mounts /proc/fb`.

To restore the test USB on the Mac run

```sh
sh screen/usb.sh restore "/Volumes/YOUR TEST STICK"
```

The full-screen option and standalone shell invocation are in `screen/README.md`. No firmware update, case opening or serial connection is required for these steps.

## Later, if needed

A serial log captured from a cold boot or a copy of the initial ramdisk as passed to Linux would address the remaining preloader question. Those are separate from tonight's baseline. On the optical side, the next specific capture is a 4,128-byte raw pair and its 4,096-byte logical result at the same two adjacent audio sectors. An existing matching `.raw` and `.iso` from a whole-disc capture would also supply those bytes.
