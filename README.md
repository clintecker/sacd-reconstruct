# SACD daemon reconstruction — Sony BDP-BX510 (`sacd_extract_160`)

In 2013, Sony shipped a Blu-ray player — the BDP-BX510 — that could play SACDs
and, quietly, rip them: a small daemon on the player (`sacd_extract_160`) reads
raw encrypted sectors through the player's CPSA decryption hardware and serves
the plaintext over TCP port 2002. The tool leaked, became the community's
ripping method, and was never documented.

This repository is a **function-level reconstruction** of that daemon, written
from the shipped binary: the public [sacd-ripper v0.3.7](DELTA.md) tree plus the
closed-source community delta, recovered from disassembly and verified against
the original. The tooling that ships with it proves the reconstruction behaves
**byte-identically** to the original — verified at three altitudes, ending on
the real player with a real disc.

![The HUD scene, rendered by the host simulator](evidence/bx510/display-payload/hud-anim.gif)

*Side project: a companion HUD for the player, rendered here by the host
simulator — LCARS-style console on an 8088-VGA canvas (320×180, 16 colours,
integer-scaled ×6). The on-device state, honestly negative in places, is
documented in [docs/HUD.md](docs/HUD.md).*

## What was demonstrated

| Claim | How it is established |
|---|---|
| Function-level parity (388/390 functions identical after normalisation) | [`tools/fn_diff.py`](tools/fn_diff.py) against the original binary; only `_start`/`call_gmon_start` residuals remain |
| Literal-pool parity (content + load-site position) | [`tools/pool_audit.py`](tools/pool_audit.py) — this caught two real reconstruction misreads (`L"c"` and `__FILE__`) |
| Byte-identical wire behaviour | full-system differential: Sony's own kernel + rootfs in QEMU, both binaries, same disc, raw TX/RX captures compared byte-for-byte |
| Byte-identical on the **real player** | on-device run: `DISC_OPEN`, `SIZE 1064208`, sector hashes matching the reference ISO, beyond-EOF refusal, clean reconnect |
| Large-image boundary behaviour (in the QEMU guest) | multi-GiB battery through the HDHOST device, sentinels across the 2 GiB and 4 GiB byte-offset boundaries |

Every bundle lives in [`evidence/`](evidence/) with a results document that
separates **demonstrated** from **inferred**; see
[docs/EVIDENCE.md](docs/EVIDENCE.md) for how to read them and
[docs/REPRODUCE.md](docs/REPRODUCE.md) to rerun any of it.

## The wire protocol

The whole protocol is two messages over TCP 2002 — nanopb-era protobuf frames
terminated by a single `0x00` tag byte, no length prefix:

```
ServerRequest:   08 <type> 10 <offset> 18 <count> 00
ServerResponse:  08 <type> 10 <result:int64> [1A <len> <data>] 00

type:  1=DISC_OPEN  2=DISC_CLOSE  3=DISC_READ  4=DISC_SIZE
```

`DISC_READ` returns `result` = sectors read and `data` = `result × 2048` bytes.
The server clamps `block_size` to 128 and to the disc's encryption-range
boundaries, and closes the connection after `DISC_CLOSE`. The two numbers that
define everything: a raw SACD sector is **2064** bytes (2048 payload + 16
header); the daemon reads the 2064-byte form, has the CPSA module decrypt it
via ioctl, and ships the **2048-byte** logical sector — which is why TOC
total-sectors × 2048 equals the ISO byte length exactly.

[`tools/sacd_client.py`](tools/sacd_client.py) is a stdlib-only client
(`capture`/`compare`/`selftest`) that speaks this protocol.

## Quick start

```sh
# 1. build the reconstructed daemon (ARM)
#    Toolchain: gnuarm 2009q3 (GCC 4.4.1, glibc 2.9) — the release build is
#    driven by tools/release_build.py, which also documents its prerequisites.
#    sacd_read.ko is embedded at link time and is NOT in this repo: extract it
#    from your own player (see docs/PROVENANCE.md).
make -C reconstruct CROSS=/path/to/arm-none-linux-gnueabi- verify

# 2. verify parity against a dump of your own player:
python3 tools/fn_diff.py dump/sacd_extract_160 reconstruct/release/sacd_extract_160_release
python3 tools/pool_audit.py dump/sacd_extract_160 reconstruct/release/sacd_extract_160_release

# 3. or talk to a running daemon over the wire:
python3 tools/sacd_client.py capture --host player.local --port 2002 --out out/
```

## Repository map

| Path | What it is |
|---|---|
| `reconstruct/` | the reconstructed C source (daemon, libsacd, libdstdec, libcommon, libid3) |
| `tools/` | verification + harness: parity diff, wire client, pool auditor, HUD, guest shims |
| `emulator-kit/` | QEMU SoC model of the player (NAND, HDHOST block device, UART) — targets without hardware |
| `docs/` | [architecture](docs/ARCHITECTURE.md) · [what's inside the binary](docs/DAEMON-MAP.md) · [evidence guide](docs/EVIDENCE.md) · [reproduction](docs/REPRODUCE.md) · [provenance](docs/PROVENANCE.md) |
| `evidence/` | recorded proof: gate runs, differential captures, on-player sessions, HUD renders |
| `DELTA.md` | the change-set the closed binary applies to the public v0.3.7 tree, verified from disassembly |

The best entry point after this README is **[docs/DAEMON-MAP.md](docs/DAEMON-MAP.md)** —
a guided tour of the binary (byte budget per module, thread model, the 2064/2048
geometry), with numbers parsed from the linker map rather than hand-written.

## What is *not* in this repository

Sony's binaries. The original daemon, the CPSA kernel module (`sacd_read.ko`)
and the firmware are **not redistributed** — [docs/PROVENANCE.md](docs/PROVENANCE.md)
records their SHA-256 fingerprints (full digests live in the evidence manifests)
so you can verify against your own device. Large
regenerable fixtures (NAND images, QEMU disks) are also omitted; see
[docs/REPRODUCE.md](docs/REPRODUCE.md).

## Licence

Our additions: MIT (see [LICENSE](LICENSE)). The reconstruction itself has
derivable lineage you should know about: `libsacd/` is built on the public
sacd-ripper v0.3.7 tree, `libid3/` derives from libid3tag, and `libdstdec/`
follows the Philips DST reference decoder — see [THIRD_PARTY.md](THIRD_PARTY.md)
and [DELTA.md](DELTA.md). Sony's binaries remain Sony's.
