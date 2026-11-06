#!/usr/bin/env python3
"""bx510_bigimg_gen.py — the 5 GiB boundary-sentinel disc image (sparse).

The final large-image validation battery (docs/large-image-interface.md,
team round-3 spec): a sparse raw image larger than 4 GiB with a valid
ScarletBook head (master TOC / SACDText / SACD_Man / area TOC), a
two-channel track range straddling the 2 GiB and 4 GiB boundaries, and
distinct nonzero per-LSN sentinel data at the sectors the battery reads.
Everything else stays sparse zeros — independently expected zeros, not
missing data (the sentinels prove transport fidelity; sparse regions
prove the daemon's zero regions are real).

One generator family for all data sectors (same xorshift as the
regression fixture): the mock decrypt is a verbatim copy, so expected
wire bytes equal the written bytes on every path — per-LSN distinctness
is what detects wrong-sector reads.

Usage:
    bx510_bigimg_gen.py OUT [--manifest PATH]
Writes OUT (sparse) and a manifest recording image identity: size,
per-sector sha256 of every written sector, and the full-image sha256.
"""
import argparse
import hashlib
import sys
from pathlib import Path

LSN = 2048
TOTAL_SECTORS = 2621440            # 5 GiB
TRACK_START = 1048500              # inside the 2 GiB region
TRACK_END = 2621430                # near the final sector
AREA_LSN = 600

sys.path.insert(0, str(Path(__file__).resolve().parent))
from bx510_gate_check import synthetic_sector  # noqa: E402
import fixture_gen  # noqa: E402  (proven TOC builders — do not hand-roll)

# The TOC sector builders are the VALIDATED ones from fixture_gen.py;
# the big image only changes geometry: the two-channel track range is
# patched before building the area TOC (the builders read the module
# globals at call time). This generator must NOT hand-roll TOC bytes.
fixture_gen.ENCRYPTED_START = TRACK_START
fixture_gen.ENCRYPTED_END = TRACK_END


def build_toc_sectors():
    return (fixture_gen.master_toc_sector(),
            fixture_gen.sacd_text_sector(),
            fixture_gen.sacd_man_sector(),
            fixture_gen.area_toc_sector())


# battery read targets: sentinels at the 2 GiB / 4 GiB byte-offset
# boundaries, the final sector, the 128-sector straddle spans, the
# clamp span, and the encrypted-range pair.
SENTINEL_RANGES = [
    (1048575, 1048576 + 1),   # 2 GiB boundary pair
    (2097151, 2097152 + 1),   # 4 GiB boundary pair
    (2621439, 2621439 + 1),   # final sector
    (1048512, 1048512 + 128),  # 2 GiB straddle read span
    (2097136, 2097136 + 128),  # 4 GiB straddle read span
    (1048494, 1048500),        # clamp span (up to track_start)
    (80000, 80000 + 2),        # encrypted-range pair (regression anchor)
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out", type=Path)
    ap.add_argument("--manifest", type=Path)
    a = ap.parse_args()
    manifest = a.manifest or a.out.with_suffix(".manifest.txt")

    written = {}
    with open(a.out, "wb") as f:
        f.truncate(TOTAL_SECTORS * LSN)

        def put(lsn, data):
            f.seek(lsn * LSN)
            f.write(data)
            written[lsn] = hashlib.sha256(data).hexdigest()

        mtoc, text, man, atoc = build_toc_sectors()
        put(510, mtoc)
        for i in range(511, 519):
            put(i, text)
        put(519, man)
        put(AREA_LSN, atoc)
        for lo, hi in SENTINEL_RANGES:
            for lsn in range(lo, hi):
                put(lsn, synthetic_sector(lsn))

    # full-image sha256 (one-time; the VM reads 5 GiB — ~30s)
    h = hashlib.sha256()
    with open(a.out, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 22), b""):
            h.update(chunk)

    with open(manifest, "w") as m:
        m.write(f"image: {a.out}\n")
        m.write(f"total_sectors: {TOTAL_SECTORS}\n")
        m.write(f"total_bytes: {TOTAL_SECTORS * LSN}\n")
        m.write(f"track_range: {TRACK_START}..{TRACK_END}\n")
        m.write(f"image_sha256: {h.hexdigest()}\n")
        m.write("generator: synthetic_sector (shared with the regression gate)\n")
        m.write("written_sectors:\n")
        for lsn in sorted(written):
            m.write(f"  {lsn}: {written[lsn]}\n")
        m.write("all other sectors: sparse zeros (independently expected)\n")
    print(f"wrote {a.out} ({TOTAL_SECTORS} sectors, sparse; "
          f"{len(written)} materialized)")
    print(f"manifest: {manifest}")
    print(f"image_sha256: {h.hexdigest()}")


if __name__ == "__main__":
    main()
