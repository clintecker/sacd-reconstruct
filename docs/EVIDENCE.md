# Reading the evidence

Each bundle is self-contained: probe/tool versions, raw captures, and a results
document that separates **demonstrated** from **inferred**.

| Bundle | What it proves |
|---|---|
| `evidence/runtime-differential/` | the reconstruction and the original produce identical stdout and option handling for a matrix of invocations |
| `evidence/qemu-rig/` | rig-side runs of both binaries against a fixture disc, with wire captures |
| `evidence/bx510-guest/gates*/` | full-system gates in Sony's own kernel + rootfs: canonical 6-boot sequence, large-image boundary battery, and the negative controls |
| `evidence/bx510-guest/differential/` | the in-guest differential: same client sequence, both binaries, TX/RX compared byte-for-byte |
| `evidence/bx510-guest/pair-observer/` | the LD_PRELOAD observer that records the module's raw and decrypted buffers |
| `evidence/bx510-baseline/`, `evidence/bx510-candidate/` | on-player captures: `OPEN`, `SIZE`, sector hashes, beyond-EOF refusal, reconnect |
| `evidence/bx510/display-payload/` | the on-panel HUD: retro render, animations, the panel photograph, and the specs |
| `evidence/bx510/hw-session-*/` | the hardware session: candidate acceptance, standby behaviour, and the mechanisms learned the hard way |

## Conventions in the results documents

- **Demonstrated** — a transcript, capture or photograph in the same directory
  shows it.
- **Inferred** — labelled as such, with the evidence that supports it.
- **N** (not tested) — a dimension that was never exercised scores N; nothing is
  scored from a library call alone.
- **Negatives are results.** A clean run needs the same evidence as a finding:
  the probe set, the counts, and the parity check.

## Raw captures

Wire captures are recorded as raw TX/RX byte streams (`*-tx.bin`, `*-rx.bin`)
next to the transcript that frames them, because client-library observations
have twice produced wrong conclusions; framing claims are checked against bytes.
