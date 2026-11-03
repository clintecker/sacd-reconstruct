# On-player session — FULLY EXPLICIT EDITION (blank-USB start)

Time on your side: ~45 minutes. Everything downstream (analysis, cross-checks,
commits, the #6 close-out) is the assistant's job.

This runbook is codified as make targets (see the SACD hardware section of the
Makefile, driven by tools/sacd_hardware.sh). The quick path:

    make sacd-hw-preflight                 # Mac prep, all checks
    make sacd-usb-build DISK=/dev/diskN CONFIRM=ERASE   # blank stick -> baseline USB
    # PLAYER: power off, Firebird in tray, USB in, power on
    make sacd-hw-wait && make sacd-hw-baseline
    make sacd-usb-pair-mode               # flip the stick to instrumented mode
    # PLAYER: power off, power on
    make sacd-hw-wait && make sacd-hw-pair
    # PLAYER: power off, remove USB
    make sacd-hw-analyze && make sacd-hw-collect   # -> ~/bx510-session

The detailed steps below remain the authoritative reference for what each
target does and what to check manually.

Conventions:
- `REPO` = your Mac checkout of this project (e.g. ~/code/aftermath-sacd)
- `USB`  = the USB stick's mount point on the Mac (e.g. /Volumes/SONYUSB)
- The player mounts the stick at /mnt/sda1 (if your earlier ripping USB used a
  different path, your old AutoScript shows the truth — keep the pattern).

--------------------------------------------------------------------------------
## PART 0 — Mac prep (5 min, nothing touches the player)

0.1  Confirm the ISO (needed for cross-checks):
       ls -la "/Volumes/1TB - WD/tomita/iso/Firebird/Firebird.iso"
     Expected: 2,179,497,984 bytes.

0.2  Confirm the original ELF:
       cd REPO/experiments/sacd_reconstruct
       shasum -a 256 original/sacd_extract_160
     MUST print: 0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45

0.3  Selftest the client:
       cd REPO/experiments/sacd_reconstruct
       python3 tools/sacd_client.py selftest --out /tmp/selftest
     Expected: SELFTEST: PASS

--------------------------------------------------------------------------------
## PART 1 — Build the USB from blank (10 min)

1.1  Plug the USB into the Mac. Identify its device (BE CAREFUL — wrong disk
     = wiped disk):
       diskutil list external
     Find the line for your stick, e.g. "/dev/disk4". Note the SIZE matches.

1.2  Erase as FAT32 (Sony players of this era do not read exFAT):
       diskutil eraseDisk FAT32 SONYUSB MBRFormat /dev/diskN
     (replace diskN with YOUR device; this destroys everything on the stick)

1.3  When it finishes it is mounted at /Volumes/SONYUSB. Copy the daemon:
       cp REPO/experiments/sacd_reconstruct/original/sacd_extract_160 /Volumes/SONYUSB/

1.4  Copy the observer kit for Phase 2:
       cp -R /Users/clint/Downloads/BX510-Handoff/emulator/optical /Volumes/SONYUSB/

1.5  Create the AutoScript (this is what the player executes at boot when the
     stick is inserted). Create a plain text file /Volumes/SONYUSB/AutoScript
     containing exactly this one line:

       /bin/sh /mnt/sda1/sacd_extract_160 -S &

     (No trailing spaces. Unix line ending. If your previous working ripping
     USB used a different daemon line — e.g. with output redirection or a
     different mount path — use THAT line as the base instead; the requirement
     is only "start the original daemon in server mode".)

     Terminal way:
       printf '/bin/sh /mnt/sda1/sacd_extract_160 -S &\n' > /Volumes/SONYUSB/AutoScript

1.6  Verify the stick's daemon is the untouched original:
       shasum -a 256 /Volumes/SONYUSB/sacd_extract_160
     MUST print 0fdcefdb… (same as 0.2).

1.7  Leave the stick mounted for now (we edit it again in Part 3).

--------------------------------------------------------------------------------
## PART 2 — Phase 1: baseline capture (~10 min)

Player side:
2.1  Power the player OFF (real off, not standby).
2.2  Put Firebird in the tray.
2.3  Insert the USB stick.
2.4  Power ON. Wait ~60-90 s for boot; the AutoScript starts the daemon
     automatically. Nothing appears on the TV — that is normal; the daemon
     is headless.

Mac side:
2.5  Check the daemon is listening:
       nc -z 10.20.1.236 2002 && echo up
     If "up" does not appear within ~2 min of boot, note the time and go to
     the failure cheat-sheet (bottom).

2.6  Capture:
       cd REPO/experiments/sacd_reconstruct
       python3 tools/sacd_client.py capture \
           --host 10.20.1.236 --port 2002 \
           --out evidence/bx510-baseline \
           --firmware "M15.R.0257 (BDP-S5100 family)" \
           --disc-id "Tomita - Firebird" \
           --label baseline \
           --daemon-sha 0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45

     Expected lines include:
       OPEN   -> result 0
       SIZE   -> result 1064208
       READ   x4 (hashes)
       CLOSE
       reconnect repeat matching
     Takes ~1-2 minutes. Nothing is written to the USB by this step — the
     capture happens over your LAN onto the Mac.

2.7  If DISC_OPEN returns zero bytes (a prior attempt saw this once):
       - keep the transcript! It is evidence. Do NOT delete the out dir.
       - wait 90 s (the daemon binds port 2002 with no SO_REUSEADDR; a
         daemon restart needs the port to clear), retry the capture with
         --label baseline-retry and a fresh --out dir.
       - if it still fails, note everything and continue to Part 3 anyway —
         the pair capture does not depend on the baseline succeeding.

--------------------------------------------------------------------------------
## PART 3 — Phase 2: the instrumented pair capture (~10 min)

This is the ground-truth run: the observer records the real module's raw
2064-byte frame and the post-CPSA-decrypt logical bytes for two sectors.

3.1  On the Mac, edit the AutoScript so the daemon-start line becomes:
       printf '/bin/sh /mnt/sda1/optical/trace-launch.sh /mnt/sda1/sacd_extract_160 600 /mnt/sda1/firebird.pair -S\n' > /Volumes/SONYUSB/AutoScript
     (600 is a decimal LSN inside Firebird's two-channel track range
      584..353763, chosen from the disc's own area TOC. The output path
      firebird.pair must NOT already exist on the stick.)

3.2  Player: power OFF. (Leave disc in tray, leave USB in.)

3.3  Power ON, wait for boot (the instrumented daemon starts instead of the
     normal one — again invisible on screen).

3.4  Mac: wait for the listener:
       until nc -z 10.20.1.236 2002; do sleep 2; done && echo listener up

3.5  Mac: request the pair (same LSN, same client):
       cd REPO/experiments/sacd_reconstruct
       python3 emulator/optical/media_check.py request-pair \
           --client tools/sacd_client.py --host 10.20.1.236 --lsn 600
     (if you did not copy emulator/ into this checkout, run it from
      /Users/clint/Downloads/BX510-Handoff/emulator/optical/ instead)
     This performs a 2-sector read + decrypt through the REAL module; the
     observer writes the ~8,240-byte pair file to the USB. COPY DOWN the
     console output — especially any wire hash it prints.

3.6  Player: power OFF. Remove the USB.

--------------------------------------------------------------------------------
## PART 4 — Phase 3: analysis on the Mac (5 min)

4.1  Validate the pair (raw frames vs logical bytes vs the ISO):
       cd REPO/experiments/sacd_reconstruct
       python3 emulator/optical/media_check.py pair \
           /Volumes/SONYUSB/firebird.pair \
           --iso "/Volumes/1TB - WD/tomita/iso/Firebird/Firebird.iso"

4.2  Validate the baseline manifest (independent verifier, strict compare):
       python3 emulator/optical/media_check.py baseline \
           evidence/bx510-baseline/manifest.json \
           --iso "/Volumes/1TB - WD/tomita/iso/Firebird/Firebird.iso"

     (If 4.1/4.2 error on tooling, skip them — just hand everything over raw;
      the analysis can be done for you.)

--------------------------------------------------------------------------------
## PART 5 — Bringing it back (the actual handoff)

5.1  Create a handoff folder on the Mac:
       mkdir -p ~/bx510-session

5.2  Copy these EXACT things in:
       cp /Volumes/SONYUSB/firebird.pair ~/bx510-session/
       cp -R evidence/bx510-baseline ~/bx510-session/
       # the console output of step 3.5 (the request-pair run) — copy-paste
       # the terminal text into a file:
       #   ~/bx510-session/request-pair-console.txt
       # likewise the capture console output from 2.6:
       #   ~/bx510-session/baseline-capture-console.txt
       # and any notes (timestamps, player behavior, screen messages):
       #   ~/bx510-session/notes.txt

5.3  Eject the USB safely (keep it — it becomes the baseline USB for the
     future candidate trial; just restore the Phase-1 AutoScript line).

5.4  Say: "it's in ~/bx510-session".

What happens next (my side): SHA-verify every artifact, run the pair and
baseline analyses against the ISO, cross-check the on-player logical bytes
against the ISO rip AND against the emulator's fixture methodology, commit
everything under evidence/bx510-hardware/, push, and post the #6 update.
If the baseline succeeded, the FOLLOWING session is the candidate trial:
same USB with the release ELF (e91720fb…), same disc, same capture, diff.

--------------------------------------------------------------------------------
## Failure cheat-sheet

- nc never connects:
    * Is the player's LAN light on? Same subnet as the Mac?
    * Try: ping 10.20.1.236 — and confirm the player IP didn't change
      (check your router's client list; if it moved, substitute everywhere).
    * USB stick LED/inserted fully? Re-seat and reboot once.
- nc connects but DISC_OPEN zero bytes:
    * Wait 90 s, retry with --label baseline-retry, fresh --out dir.
    * Still failing: proceed to Part 3 anyway; note timings.
- request-pair times out:
    * Confirm the AutoScript edit took (cat /Volumes/SONYUSB/AutoScript).
    * Confirm firebird.pair did NOT pre-exist (trace-launch refuses to
      overwrite; delete it from the stick if present, reboot, retry).
    * Note: only ONE instrumented daemon per boot; never two on port 2002.
- Wrong disc/size looks odd:
    * SIZE should be ~1064208 for Firebird. Anything wildly different means
      a different disc or a tray-state issue: reboot with the disc in.
- Player behaves oddly at any point: power off, remove USB, reboot normally.
  The instrumentation is one launcher line; booting without the USB restores
  stock behavior completely.
