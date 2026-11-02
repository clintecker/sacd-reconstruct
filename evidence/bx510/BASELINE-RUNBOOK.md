# BX510 baseline capture runbook (issue #6, step 1)

Goal: record a complete wire-level baseline of the **original** daemon
running on the player, so the same sequence can later be replayed against
the rebuilt candidate on the same player + disc.

## What you need

- The BX510 online on the same LAN as the Mac (AutoScript USB staging works).
- The AutoScript USB prepared as usual (boots the original
  `sacd_extract_160`, SHA-256 `0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45`,
  which listens on port 2002 once a client would connect — server mode).
- An SACD in the tray (note the album + catalog number for `--disc-id`).
- The player's IP address (router/ARP table or however you usually find it).
- Firmware version if you can get it (Settings → System Information; if not
  available, leave `--firmware` as "unknown" — we can pull build IDs later).

## Steps (on the Mac)

```sh
cd <repo>/experiments/sacd_reconstruct

# 0. sanity: the client validates itself against an in-process fake server
python3 tools/sacd_client.py selftest --out /tmp/sacd-self
# expect: SELFTEST: PASS

# 1. capture the baseline (player IP in place of 192.168.x.x)
python3 tools/sacd_client.py capture \
    --host 192.168.x.x --port 2002 \
    --out evidence/bx510-baseline \
    --firmware "BX510 <fw version or unknown>" \
    --disc-id "<album> — <catalog no.>" \
    --label baseline \
    --daemon-sha 0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45
```

The client performs, in order:

1. connect, `DISC_OPEN`
2. `DISC_SIZE`
3. `DISC_READ` 1 sector @ LSN 0
4. `DISC_READ` 128 sectors @ LSN 0 (the server's block cap — doubles as a
   disc fingerprint hash)
5. `DISC_READ` 1 sector @ mid-disc
6. `DISC_CLOSE` (server drops the connection)
7. reconnect, `DISC_OPEN`, repeat the mid-disc 1-sector read, `DISC_CLOSE`

Every request/response frame is recorded (request bytes hex, response
frame SHA-256, result codes, payload SHA-256, requested vs returned
sector counts) into `evidence/bx510-baseline/manifest.json` with a
`capture.log` transcript.

## What to check before packing up

- `capture.log` shows `OPEN result=...` non-negative and `SIZE
  total_sectors=` a plausible number (SACD layers run in the hundreds of
  thousands of LSNs).
- The mid-disc read and its reconnect repeat show the **same** `sha=` prefix.
- If `OPEN result` is negative: no disc / tray open — fix and re-run
  (delete the old output dir first; the manifest appends a new log line).

## After the capture

Keep the whole `evidence/bx510-baseline/` directory (manifest.json +
capture.log) — that is the baseline. The follow-up run uses the identical
command with `--label candidate` (and `--daemon-sha` of the rebuilt ELF)
after staging the candidate via AutoScript, and:

```sh
python3 tools/sacd_client.py compare \
    evidence/bx510-baseline/manifest.json \
    evidence/bx510-candidate/manifest.json
```

prints per-read verdicts (requested/returned counts, payload hashes) and
an overall IDENTICAL / DIFFERS verdict. Also compare the same sequence
under QEMU against the #5 rig before going on-player.
