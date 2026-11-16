# Reproducing the results

> Lifecycle context: this document maps the same ladder as
> `docs/LIFECYCLE.md` — unit gates (§5), wire-level without hardware (§2),
> full-system QEMU (§3), hardware gate (§4) — from the outside-in
> (reproducer's view rather than developer's view).

Nothing here needs a player except the hardware gate. Everything else runs on a
Linux host (x86-64 is fine) with Python 3, and `qemu-system-arm` for the full
system step.

## 0. What you must supply

| Thing | Why | Where it comes from |
|---|---|---|
| Original `sacd_extract_160` | the parity reference | your own player: `/usr/local/bin/sacd_extract_160` (SHA-256 `0fdcefdb…`) |
| `sacd_read.ko` | the CPSA module contract | same player: `/usr/local/lib/sacd_read.ko` |
| Firmware images (NAND, kernel, rootfs) | full-system differential | full NAND dump of your player (see `docs/PROVENANCE.md`) |
| A disc image or disc | the fixture | your own SACD; the recorded runs used *Tomita — Firebird* (2,179,497,984 bytes = 1,064,208 sectors) |

## 1. Function-level parity

```sh
python3 tools/fn_diff.py sacd_extract_160 reconstruct/release/sacd_extract_160_release
python3 tools/pool_audit.py sacd_extract_160 reconstruct/release/sacd_extract_160_release
```

`fn_diff` normalises and compares 390 functions; only the `_start` and
`call_gmon_start` residuals are expected to differ. `pool_audit` compares the
literal pools by content and at their load sites (it caught two real misreads:
`L"c"` and `__FILE__`).

## 2. Wire behaviour without hardware

```sh
# client self-test (no daemon needed)
python3 tools/sacd_client.py selftest --out /tmp/selftest

# against a real daemon, wherever it runs:
python3 tools/sacd_client.py capture --host <ip> --port 2002 --out out/
```

A capture writes `manifest.json` with every read's LSN, sector count and payload
SHA-256, so two runs are comparable by diffing manifests.

## 3. Full system (Sony's own kernel and rootfs in QEMU)

Build the machine model and boot a target image; `emulator-kit/build.sh` builds
QEMU with the `player.local` machine, and `emulator-kit/run.py` boots it with the
NAND image. The gate scripts under `evidence/bx510-guest/gates*/` show the
canonical command lines: they boot the guest twice (original binary, then the
reconstruction), replay the same client sequence, and compare raw TX/RX bytes.

```sh
python3 emulator-kit/run.py --images <dir> shell <fixture.img>
```

Regenerable fixtures that are **not** in this repo (they were 150 MB of NAND
images) are produced by `tools/fixture_gen.py`.

## 4. The rip (the user-visible product)

With any of the rigs above serving port 2002, the same reconstructed binary
runs as the ripper client (no `-S`):

```sh
sacd_extract_160 -s -c -t 1 -i 127.0.0.1:2002 /tmp/ripout
# -> /tmp/ripout/01 - <album>.dsf   (DST -> DSD decode via -c)
```

This is proven end to end under the qemu-user rig; the recorded runs produced
213,188,877 B and 301,154,576 B DSF files with md5s in
`evidence/bx510-guest/rip/README.md`, deterministic across two rips. One
reconstruction-side divergence was required (documented at the patch site):
`recursive_mkdir` tolerates `EPERM` because the original ran as root on the
player and never met it; a non-root reproducer does.

## 5. Level-1 cipher (the decrypt leg, for real)

`tools/bx510_disc_cipher.py` derives an encrypted-at-rest copy of a disc image
(both audio areas; TOCs stay plaintext — the daemon reads TOCs via the plain
lseek64 path and never the decrypt ioctl). Boot the emulator with the
`sacd-cipher` machine property armed and the daemon's DECRYPT ioctl leg runs
for real. `tools/bx510_cipher_check.py` gates the run against the oracle table
(`level1-cipher-oracles.json`, 7 gates incl. negative controls); the spec,
battery results and the decisive byte-level evidence are in
`evidence/bx510-guest/bdpdrv/decode/level1-cipher-spec.md`.

## 6. The UI/HUD on the emulated panel

```sh
make sacd-hud-sim                 # host render -> PNG (seconds)
make sacd-hud-guest               # the HUD inside Sony's guest OS, gated
make bx510-ui-loop RUNID=<id>     # UI edit -> guest frame -> verdict, one command
make ui-regress-all               # layout + animation + guest-parity suite
```

Viewable results: `docs/GRAPHICS-GALLERY.md`.

## 7. Hardware gate

`docs/` ships the runbook (`evidence/bx510/PLAYER-SESSION-RUNBOOK.md`) and
`tools/sacd_hardware.sh` drives it: build a FAT32 stick whose `AutoScript/`
starts the daemon, insert it, capture over the LAN. Two mechanisms are
non-obvious and cost several failed runs to learn:

- the player executes an **MTK CLI script** (`#MTKAT` header + `CLI(...)` lines),
  not a shell script, and truncates long scripts;
- the daemon needs the CPSA module preloaded on a **free compid**, or it dies in
  one second with `insmod … busy`.

## 8. Gates

```sh
uv run pytest -m "not smoke"     # unit gates (parity, pool, alteration controls)
```

The alteration controls are the important ones: they assert that the comparison
tooling *detects* a deliberately altered binary, so a PASS is meaningful.
