#!/usr/bin/env python3
"""build_fe_tag_fixtures.py — synthetic page-0 records for the three FE tag partitions.

NOT factory content. Recipe source: decode/fe-tags.md §4.2. The record layout
(§2) is VERIFIED from the three check blocks in sata_mt85xx_mod.ko
(.text+0x1a4c PowerCurve, .text+0x1bb8 Parameter, .text+0x1c0c FA table):

    +0x00  char tag[4]     "PWRC" / "FATB" / "PARM"    <- strncmp(buf, tag, 4)
    +0x04  u32 unused      never referenced by any of the three blocks
    +0x08  u32 total_len   LE, = 16 + payload length
    +0x0c  u32 checksum    LE, = byte-wise 32-bit wrapping sum over
                           [0x10, total_len)
    +0x10  u8  payload[total_len - 16]

Checksum idiom warning: this byte-sum is NOT the fe_bin_1 checksum (that one is a
big-endian dword sum against the hardcoded 0x37922226 — decode/sata-fw-load.md §3).
Do not substitute one for the other.

Each output blob is exactly the number of bytes the driver asks for at partition
offset 0, so dd-ing it at the partition offset leaves the rest of the 1 MiB
partition erased (0xFF), which is what §4.2 specifies. The driver reads only page 0
(page = 2048 B, §2.1), and the MTD path delivers image bytes verbatim (ECC clean,
0 bad blocks), so the fixture is complete with one page per partition.

Field provenance is declared in FIELD_PROVENANCE below. --strict refuses to build
while an INFERRED field is still carrying its default — see --hdr-unused.

Usage:
    python3 build_fe_tag_fixtures.py                     # write the three blobs
    python3 build_fe_tag_fixtures.py --strict --hdr-unused 0
    python3 build_fe_tag_fixtures.py --outdir /tmp/fix
"""
from __future__ import annotations

import argparse
import hashlib
import struct
import sys
from dataclasses import dataclass
from pathlib import Path

VERIFIED = "VERIFIED"
INFERRED = "INFERRED"
SYNTHETIC = "SYNTHETIC"

# Every field this builder writes, with what the doc settles and what it does not.
FIELD_PROVENANCE: dict[str, tuple[str, str]] = {
    "tag": (VERIFIED,
            "the 4 bytes at +0; strings read from .data+0x10/+0x24/+0x38 "
            "(fe-tags.md §1.1-1.3). PWRC at the partition head, never the fw-header "
            "spelling POWC (§3, §7.4)."),
    "hdr_unused": (INFERRED,
                   "+0x04: no instruction in the three check blocks reads it "
                   "(fe-tags.md §2 'UNKNOWN/unused'). 0 is written so that a genuine "
                   "factory sequence-number/version is not imitated; whether a real "
                   "image carries something there is §7.3, unsettled."),
    "total_len": (VERIFIED,
                  "+0x08 LE = 16 + payload length; read lengths are the callers' "
                  "r10/PARM.f2 values (fe-tags.md §1.1-1.3)."),
    "checksum": (VERIFIED,
                 "+0x0c LE = byte-wise running sum, 32-bit wrapping, over "
                 "[0x10, total_len) (fe-tags.md §2, .text+0x1bbc..0x1be8)."),
    "payload_contents": (SYNTHETIC,
                         "the driver never interprets the payload (it only memcpy's "
                         "POWC.f2/FATB.f2/PARM.f2 bytes into FE DRAM); what real FE "
                         "firmware accepts here is INFERRED — fe-tags.md §5. The bytes "
                         "are therefore self-identifying ASCII labels, so no reader can "
                         "mistake a hexdump of them for factory data."),
}


@dataclass(frozen=True)
class FeTagPartition:
    """One of the three partitions, keyed by its manifest partition name."""

    name: str            # == manifest "partitions[].name" == fixture file stem
    tag: bytes
    payload_len: int     # POWC.f2 / FATB.f2 / PARM.f2 payload size the driver copies
    read_len: int        # bytes the driver asks for from partition offset 0
    label: bytes         # SYNTHETIC payload fill
    recipe_offset: int   # informational only: apply_tag_fixtures.sh re-reads these
                         # from /tmp/images-fe/manifest.json (never trusts this)


PARTITIONS = (
    FeTagPartition(
        name="fe_power_curve",
        tag=b"PWRC",
        payload_len=0x400,
        read_len=0x420,          # MTDRawRead(fe_power_curve, 32, 0x420, buf)
        label=b"BX510 FE POWER CURVE FIXTURE (SYNTHETIC - NOT FACTORY DATA) v1\n",
        recipe_offset=0x01000000,
    ),
    FeTagPartition(
        name="fe_test_data",
        tag=b"FATB",
        payload_len=0x2000,
        read_len=0x2020,         # MTDAdvRead(fe_test_data, 20, "FATB", 0x2020, buf)
        label=b"BX510 FE FA TABLE FIXTURE (SYNTHETIC - NOT FACTORY DATA) v1\n",
        recipe_offset=0x00E00000,
    ),
    FeTagPartition(
        name="fe_parameters",
        tag=b"PARM",
        payload_len=0x1FF0,
        read_len=0x2000,         # MTDAdvRead(fe_parameters, 30, "PARM", 0x2000, buf)
        label=b"BX510 FE PARAMETERS FIXTURE (SYNTHETIC - NOT FACTORY DATA) v1\n",
        recipe_offset=0x00F00000,
    ),
)


def labelled_payload(label: bytes, size: int) -> bytes:
    """Deterministic SYNTHETIC fill: the label cycled to exactly `size` bytes."""
    if not label:
        raise ValueError("empty label")
    return (label * (size // len(label) + 1))[:size]


def build_record(part: FeTagPartition, hdr_unused: int) -> bytes:
    """Header + payload + the read-length slack, exactly as §4.2 lays it out."""
    payload = labelled_payload(part.label, part.payload_len)
    total_len = 16 + len(payload)
    if total_len > part.read_len:
        raise ValueError(
            f"{part.name}: total_len 0x{total_len:x} does not fit the 0x{part.read_len:x} "
            "byte read, which has no slack on the Parameter path")
    checksum = sum(payload) & 0xFFFFFFFF
    blob = part.tag + struct.pack("<III", hdr_unused, total_len, checksum) + payload
    # §4.2: "16 B slack (driver reads 0x420)" for PWRC/FATB; zero on PARM.
    blob += b"\x00" * (part.read_len - total_len)
    verify_record(part, blob)
    return blob


def verify_record(part: FeTagPartition, blob: bytes) -> None:
    """Re-derive every gate a successful read has to pass, from the bytes alone."""
    if len(blob) != part.read_len:
        raise AssertionError(f"{part.name}: length {len(blob):#x} != read_len {part.read_len:#x}")
    if blob[0:4] != part.tag:
        raise AssertionError(f"{part.name}: tag bytes {blob[0:4]!r} != {part.tag!r}")
    hdr_unused, total_len, checksum = struct.unpack("<III", blob[4:16])
    if total_len != 16 + part.payload_len:
        raise AssertionError(f"{part.name}: total_len {total_len:#x} != {16 + part.payload_len:#x}")
    payload = blob[16:total_len]
    if sum(payload) & 0xFFFFFFFF != checksum:
        raise AssertionError(f"{part.name}: checksum {checksum:#x} != recomputed "
                             f"{sum(payload) & 0xFFFFFFFF:#x}")
    if struct.unpack("<I", blob[4:8])[0] != hdr_unused:
        raise AssertionError(f"{part.name}: +0x04 round-trip mismatch")
    if not payload.startswith(part.label[:len(payload)]):
        raise AssertionError(f"{part.name}: payload lost its SYNTHETIC label")


def main(argv: list[str] | None = None) -> int:
    repo_decode = Path(__file__).resolve().parent
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--outdir", type=Path, default=repo_decode.parent / "fixtures",
                    help="fixture output dir (default: evidence/bx510-guest/bdpdrv/fixtures)")
    ap.add_argument("--hdr-unused", type=lambda s: int(s, 0), default=None,
                    help="value for the never-read header word at +0x04 (INFERRED; default 0)")
    ap.add_argument("--strict", action="store_true",
                    help="refuse to build while an INFERRED field is still at its default")
    args = ap.parse_args(argv)

    inferred_used = ["hdr_unused"]
    if args.strict and args.hdr_unused is None:
        print("--strict: refusing to build — INFERRED field(s) still unset: "
              + ", ".join(inferred_used), file=sys.stderr)
        for name in inferred_used:
            label, note = FIELD_PROVENANCE[name]
            print(f"  {name} [{label}] {note}", file=sys.stderr)
        print("  supply e.g. --hdr-unused 0", file=sys.stderr)
        return 2

    hdr_unused = 0 if args.hdr_unused is None else args.hdr_unused & 0xFFFFFFFF
    if args.hdr_unused is None:
        print(f"note: {inferred_used[0]} is INFERRED and defaulted to 0x{hdr_unused:08x} "
              "(--strict refuses this; see FIELD_PROVENANCE)")

    args.outdir.mkdir(parents=True, exist_ok=True)
    for part in PARTITIONS:
        blob = build_record(part, hdr_unused)
        path = args.outdir / f"{part.name}.bin"
        path.write_bytes(blob)
        _, total_len, checksum = struct.unpack("<III", blob[4:16])
        print(f"{path}")
        print(f"  tag={blob[0:4]!r} (+0x04=0x{hdr_unused:08x}) total_len=0x{total_len:x} "
              f"payload=0x{part.payload_len:x} slack=0x{part.read_len - total_len:x} "
              f"checksum=0x{checksum:08x} size=0x{len(blob):x}")
        print(f"  md5={hashlib.md5(blob).hexdigest()} sha256={hashlib.sha256(blob).hexdigest()}")
        print(f"  -> {part.name} (recipe offset 0x{part.recipe_offset:08x}; "
              "apply_tag_fixtures.sh resolves the live offset from manifest.json)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
