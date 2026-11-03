# On-player session runbook — baseline + raw/logical pair capture

Target: the BDP-S5100/BX510 family unit at **10.20.1.236** (M15.R.0257).
Disc: Firebird (the ISO on the 1TB drive is the same disc's rip — the
on-player logical bytes can be cross-checked against it).
All Mac commands run from a checkout of this repo.

## Phase 0 — Preconditions (~5 min)

1. Verify the daemon ELF on the ripping USB from the Mac:
   ```sh
   shasum -a 256 /Volumes/<RIPPING-USB>/sacd_extract_160
   # must be 0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45
   ```
2. Copy the full-system team's optical kit onto the same USB:
   ```sh
   cp -R /Users/clint/Downloads/BX510-Handoff/emulator/optical /Volumes/<RIPPING-USB>/
   ```
   (contains `trace-launch.sh`, `bx510_pair.so` — the ARM ioctl observer —
   and nothing that autostarts.)
3. Firebird in the tray. Mac on the same LAN.

## Phase 1 — Baseline capture (retry with diagnostics, ~10 min)

Boot the player normally (AutoScript starts the original daemon with `-S`).

1. Confirm reachability at the moment of the attempt:
   ```sh
   nc -z 10.20.1.236 2002 && echo up
   ```
2. Capture:
   ```sh
   python3 tools/sacd_client.py capture \
       --host 10.20.1.236 --port 2002 \
       --out evidence/bx510-baseline \
       --firmware "M15.R.0257 (BDP-S5100 family)" \
       --disc-id "Tomita — Firebird" \
       --label baseline \
       --daemon-sha 0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45
   ```
3. Expected: OPEN=0, SIZE≈1064208, four reads with hashes, reconnect
   repeat matching. If DISC_OPEN again returns zero bytes (the one prior
   attempt did): **keep the transcript** — it is evidence. Note the time
   since boot (the daemon binds without SO_REUSEADDR; a daemon restart
   needs ~60s of port-clear time — a false-zero can happen if two
   instances raced). Wait 90 seconds and try once more.

## Phase 2 — The instrumented pair run (~10 min)

This replaces the normal daemon start ONCE, so the observer can record
the module's raw 2064-byte frames and the post-decrypt 2048-byte logical
bytes for two sectors. **Do not run two daemons on port 2002.**

1. Edit the AutoScript launcher so the daemon-start line becomes (use
   your USB's real mount path; the example assumes it appears as
   `/mnt/sda1`):
   ```sh
   /bin/sh /mnt/sda1/optical/trace-launch.sh \
       /mnt/sda1/sacd_extract_160 600 /mnt/sda1/firebird.pair -S
   ```
   - `600` is a decimal LSN inside Firebird's two-channel track range
     (584..353763, from the area TOC at LSN 353764).
   - The output path must NOT already exist — use a fresh name per run.
2. Boot the player with the USB in. From the Mac, wait for the listener:
   ```sh
   until nc -z 10.20.1.236 2002; do sleep 2; done && echo listener up
   ```
3. Request the pair (same LSN, same client):
   ```sh
   python3 emulator/optical/media_check.py request-pair \
       --client tools/sacd_client.py --host 10.20.1.236 --lsn 600
   ```
   This performs the two-sector read + decrypt through the real module;
   the observer writes the 8,240-byte pair file to the USB.
4. Power the player down; eject the USB.

## Phase 3 — Analysis on the Mac (~5 min)

```sh
# pair validity: raw frames vs logical bytes vs the ISO
python3 emulator/optical/media_check.py pair \
    /Volumes/<RIPPING-USB>/firebird.pair \
    --iso "/Volumes/1TB - WD/tomita/iso/Firebird/Firebird.iso"

# baseline strictness (independent verifier with negative controls)
python3 emulator/optical/media_check.py baseline \
    evidence/bx510-baseline/manifest.json \
    --iso "/Volumes/1TB - WD/tomita/iso/Firebird/Firebird.iso"
```

## What to bring back

- `evidence/bx510-baseline/` (manifest + capture.log) — success or
  zero-byte transcript either way
- `firebird.pair` + the LSN + the wire hash `request-pair` printed
- Any visible daemon output on the player, and rough timestamps of each
  attempt

The pair file is the missing ground truth: it pins the module's real raw
frame metadata and the CPSA decrypt output for the exact sectors the
daemon serves, closing the gap between the qemu-user oracle (identical
above the ioctl boundary), the full-system guest (loader/libc), and the
hardware.
