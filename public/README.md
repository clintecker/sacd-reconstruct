# sacd_extract_160

Reconstructing Sony's secret SACD-ripping daemon — from the shipped binary to
working source, proven byte-for-byte, and now ripping real music files out of
an emulated player.

<p align="center">
  <img src="evidence/bx510-guest/graphics/gallery/hud-in-daemon-panel.png" width="720" alt="The daemon's UI — the HUD, painted by the daemon itself">
</p>

*The daemon's UI is its HUD: `sacd_extract_160 -S --hud=panel` paints this
panel from its own live state while it serves port 2002. This exact frame is
proven to render inside Sony's real guest OS
([gallery](docs/GRAPHICS-GALLERY.md)).*

## The story

In 2013 Sony shipped the BDP-BX510 Blu-ray player. It played SACDs — and,
quietly, ripped them. A small daemon on the player (`sacd_extract_160`) reads
raw encrypted sectors through the player's CPSA decryption hardware and serves
the plaintext over TCP port 2002. The tool leaked, became the community's
standard ripping method, and was never documented. The source was never
public. The last release shipped as a stripped ARM binary.

This repository is that binary, rebuilt: the public
[sacd-ripper v0.3.7](DELTA.md) tree plus the closed-source community delta,
recovered from disassembly and verified against the original — 387 of 390
functions instruction-identical, the rest accounted for, down to literal-pool
contents and wire bytes.

## What it does today

```sh
# the daemon, serving a disc over TCP 2002 (just like the original):
sacd_extract_160 -S

# the ripper client — the SAME binary, no -S:
sacd_extract_160 -s -c -t 1 -i 127.0.0.1:2002 ~/rip
#   -> ~/rip/01 - <album>.dsf      (DST lossless -> DSD, playable)
```

That rip was the finish line, and it's crossed — under the emulator. The
daemon and the client are the same program, the DSF files are deterministic
(two rips, one md5), and every byte the client received came through the
reconstructed protocol stack.

The **HUD** — the daemon's UI, one program, one product — is built **into
the daemon**: `sacd_extract_160 -S --hud=console|panel` serves the rip and
renders live telemetry from its own internal state (clients, ripping
progress, disc stats). The image at the top of this page is the daemon
itself painting its panel in the guest, taken from the run's captured frame.

## How it's proven

Nothing here is claimed from a library call or an eyeballed diff. Three
altitudes, cheapest first, each with committed evidence:

| Altitude | What runs | The proof |
|---|---|---|
| **qemu-user rig** | the daemon as real ARM code; device touches interposed onto a disc image | original vs reconstruction on the same disc, manifests identical ([`evidence/qemu-rig/`](evidence/qemu-rig/20261116-032705/capture-orig/manifest.json) — latest run manifest) |
| **full-system guest** | Sony's own Linux 2.6.35 kernel + rootfs booting in our `sony-bx510` QEMU machine ([`emulator-kit/`](emulator-kit/README.md)) | same client sequence to both binaries, raw TX/RX compared byte-for-byte ([`evidence/bx510-guest/differential/`](evidence/bx510-guest/differential/transcript-orig.txt) — the transcript; captures alongside) |
| **the real player** | a USB stick boots the daemon on actual hardware | sector hashes matching the reference ISO, beyond-EOF refusal, standby survival ([`evidence/bx510/hw-session-2026-11-05/`](evidence/bx510/hw-session-2026-11-05/RESULTS.md)) |

*The proof behind the top image: this frame came out of the daemon process
(`--hud=panel`) running inside Sony's real guest OS, captured during the
same run in which a real client read the disc over port 2002. One binary:
serves the rip, draws the panel. The decrypt leg is proven for real too: a
derived disc image carries the audio areas encrypted at rest, and the
emulated CPSA path decrypts under seven acceptance gates.*

## The protocol

Two messages over TCP 2002 — protobuf frames terminated by a single `0x00`
byte, no length prefix:

```
ServerRequest:   08 <type> 10 <offset> 18 <count> 00
ServerResponse:  08 <type> 10 <result:int64> [1A <len> <data>] 00

type:  1=DISC_OPEN  2=DISC_CLOSE  3=DISC_READ  4=DISC_SIZE
```

The two numbers that define everything: a raw SACD sector is **2064** bytes
(2048 payload + 16 header); the daemon reads the 2064-byte form, has the CPSA
module decrypt it via ioctl, and ships the **2048-byte** logical sector.
[`tools/sacd_client.py`](tools/sacd_client.py) is a stdlib-only client that
speaks this protocol.

## Using this repository

```sh
# build the reconstruction (GNU GCC 4.4.1 / glibc 2.9 — the recovered recipe):
python3 tools/release_build.py
sh    tools/release_verify.sh        # the 5-leg verification gate

# verify parity against a dump of YOUR player's binary:
python3 tools/fn_diff.py dump/sacd_extract_160 reconstruct/release/sacd_extract_160_release
python3 tools/pool_audit.py dump/sacd_extract_160 reconstruct/release/sacd_extract_160_release

# unit gates (77 tests, including the alteration controls that keep PASS honest):
make tests

# boot the emulated player:
python3 emulator-kit/run.py --images <dir> shell <fixture.img>
```

Full reproduction ladder (rig → guest → hardware): [docs/REPRODUCE.md](docs/REPRODUCE.md).

## Where to read next

| Doc | What it covers |
|---|---|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | the device, the daemon, the harness — three layers |
| [docs/DAEMON-MAP.md](docs/DAEMON-MAP.md) | a guided tour of the binary: module byte budgets, thread model, the 2064/2048 geometry |
| [docs/RIG-ARCHITECTURE.md](docs/RIG-ARCHITECTURE.md) | how the emulation rigs work (qemu-user + full-system) |
| [docs/LIFECYCLE.md](docs/LIFECYCLE.md) | the build/test ladder from idea to hardware |
| [docs/EVIDENCE.md](docs/EVIDENCE.md) | how to read the evidence bundles |
| [docs/HUD.md](docs/HUD.md) | the HUD (`sacd_hud`) — one HUD, its architecture, and its roadmap into the daemon |
| [DELTA.md](DELTA.md) | the exact change-set vs public v0.3.7, verified from disassembly |

## Not in this repository

Sony's binaries. The original daemon, the CPSA kernel module (`sacd_read.ko`)
and the firmware are **not redistributed** — [docs/PROVENANCE.md](docs/PROVENANCE.md)
records their SHA-256 fingerprints so you can verify against your own device.
Large regenerable fixtures (NAND images, QEMU disks) are omitted;
[docs/REPRODUCE.md](docs/REPRODUCE.md) shows how to regenerate them.

## Licence

Our additions: MIT ([LICENSE](LICENSE)). The reconstruction has derivable
lineage you should know about: `libsacd/` builds on the public sacd-ripper
v0.3.7 tree, `libid3/` derives from libid3tag, `libdstdec/` follows the
Philips DST reference decoder — see [THIRD_PARTY.md](THIRD_PARTY.md) and
[DELTA.md](DELTA.md). Sony's binaries remain Sony's.
