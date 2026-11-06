# Reproducing the results

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

## 4. Hardware gate

`docs/` ships the runbook (`evidence/bx510/PLAYER-SESSION-RUNBOOK.md`) and
`tools/sacd_hardware.sh` drives it: build a FAT32 stick whose `AutoScript/`
starts the daemon, insert it, capture over the LAN. Two mechanisms are
non-obvious and cost several failed runs to learn:

- the player executes an **MTK CLI script** (`#MTKAT` header + `CLI(...)` lines),
  not a shell script, and truncates long scripts;
- the daemon needs the CPSA module preloaded on a **free compid**, or it dies in
  one second with `insmod … busy`.

## 5. Gates

```sh
uv run pytest -m "not smoke"     # unit gates (parity, pool, alteration controls)
```

The alteration controls are the important ones: they assert that the comparison
tooling *detects* a deliberately altered binary, so a PASS is meaningful.
