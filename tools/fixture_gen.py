#!/usr/bin/env python3
"""fixture_gen.py — deterministic Scarlet Book fixture disc for the QEMU rig.

Writes a sparse fixture image (default rig_disc.bin) that satisfies the
daemon's scarletbook_read.c validators when read through BOTH device paths:
the plain lseek64+read() path (used for TOC reads) and the sacd_read.ko
ioctl path (rig.c serves READ via pread from this same file).

Layout (LSNs are 2048 bytes):
  510          master TOC  ("SACDMTOC", version 1.20, reserved zero,
                          area_1_toc_1_start=600, area_1_toc_size=10)
  511..518     eight SACDText blocks (id + zeros -> no text conversion)
  600          area TOC ("TWOCHTOC", version 1.20, size=1 -> skips the
                          SACDTTxt scan, channel_count=2/loudspeaker=0,
                          track_count=1, encrypted range 80000..86000 so
                          the test LSNs stay in the unencrypted path)
  0..127       synthetic sectors (client's 1- and 128-sector reads)
  43100..43101 synthetic sectors (client's mid-disc reads; mid = 86200/2)

Everything else stays sparse zeros. DISC_SIZE comes from fstat64 of the
file: 86200 * 2048 bytes -> 86200 reported sectors.

All multi-byte fields are big-endian on disc (the daemon SWAPs after read).
"""

import argparse
import struct
from pathlib import Path

TOTAL_SECTORS = 86200
AREA_LSN = 600
ENCRYPTED_START = 80000
ENCRYPTED_END = 86000
MID_LSN = TOTAL_SECTORS // 2
LSN = 2048


def be16(v):
    return struct.pack(">H", v)


def be32(v):
    return struct.pack(">I", v)


def master_toc_sector():
    s = bytearray(LSN)
    off = 0

    def put(b):
        nonlocal off
        s[off:off + len(b)] = b
        off += len(b)

    put(b"SACDMTOC")
    put(bytes([1, 0x14]))               # version 1.20
    put(b"\x00" * 6)                    # reserved01
    put(be16(1))                        # album_set_size
    put(be16(1))                        # album_sequence_number
    put(b"\x00" * 4)                    # reserved02
    put(b"\x00" * 16)                   # album_catalog_number
    put(b"\x00" * 16)                   # album_genre[4] (4-byte genre_table_t:
                                      # category u8 + reserved u16 + genre u8)
    put(b"\x00" * 8)                    # reserved03
    put(be32(AREA_LSN))                 # area_1_toc_1_start
    put(be32(0))                        # area_1_toc_2_start
    put(be32(0))                        # area_2_toc_1_start
    put(be32(0))                        # area_2_toc_2_start
    put(bytes([0]))                     # disc_type
    put(b"\x00" * 3)                    # reserved04
    put(be16(10))                       # area_1_toc_size (LSNs)
    put(be16(0))                        # area_2_toc_size
    put(b"\x00" * 16)                   # disc_catalog_number
    put(b"\x00" * 16)                   # disc_genre[4] (4-byte genre_table_t)
    put(be16(2025))                     # disc_date_year
    put(bytes([11, 2]))                 # month, day
    put(b"\x00" * 4)                    # reserved05
    put(bytes([1]))                     # text_area_count
    put(b"\x00" * 7)                    # reserved06
    for _ in range(8):                  # locales[8]
        put(b"en" + bytes([0, 0]))
    # 4-byte genre tables (real-disc ground truth: Firebird's master TOC
    # has year at 120, text_area_count at 128, reserved06 at 129-136,
    # locales at 136-168). The previous 20-byte genre arrays shifted the
    # tail 8 bytes late and failed the original daemon's reserved06
    # zero-check in the full-system guest (the qemu-user rig never caught
    # it: both binaries failed OPEN identically, so the differential was
    # equal-failure-equal).
    assert off == 168, off
    return bytes(s)


def sacd_text_sector():
    s = bytearray(LSN)
    s[0:8] = b"SACDText"
    return bytes(s)


def sacd_man_sector():
    """master_man_t: id 'SACD_Man' + zeros (real Firebird LSN 519 ground
    truth; scarletbook_read_master_toc requires it at the end of the
    10-sector master read or fails with a SILENT return 0 -> the daemon's
    'Can't read Master TOC' without any diagnostic)."""
    s = bytearray(LSN)
    s[0:8] = b"SACD_Man"
    return bytes(s)


def area_toc_sector():
    s = bytearray(LSN)
    off = 0

    def put(b):
        nonlocal off
        s[off:off + len(b)] = b
        off += len(b)

    put(b"TWOCHTOC")
    put(bytes([1, 0x14]))               # version 1.20
    put(be16(1))                        # size -> skips SACDTTxt scan
    put(b"\x00" * 4)                    # reserved01
    put(be32(0))                        # max_byte_rate
    put(bytes([0x04]))                  # sample_frequency
    put(bytes([0]))                     # frame_format / reserved02
    put(b"\x00" * 10)                   # reserved03
    put(bytes([2]))                     # channel_count (two-channel)
    put(bytes([0]))                     # loudspeaker_config=0 | extra
    put(bytes([2]))                     # max_available_channels
    put(bytes([0]))                     # area_mute_flags
    put(b"\x00" * 12)                   # reserved04
    put(bytes([0]))                     # track_attribute / reserved05
    put(b"\x00" * 15)                   # reserved06
    put(bytes([0, 0, 0]))               # total_playtime
    put(bytes([0]))                     # reserved07
    put(bytes([0]))                     # track_offset
    put(bytes([1]))                     # track_count
    put(b"\x00" * 2)                    # reserved08
    put(be32(ENCRYPTED_START))           # track_start
    put(be32(ENCRYPTED_END))            # track_end
    put(bytes([0]))                     # text_area_count
    put(b"\x00" * 7)                    # reserved09
    put(b"\x00" * 40)                   # languages[10]
    put(be16(0))                        # track_text_offset
    put(be16(0))                        # index_list_offset
    put(be16(0))                        # access_list_offset
    put(b"\x00" * 10)                   # reserved10
    put(be16(0))                        # area_description_offset
    put(be16(0))                        # copyright_offset
    put(be16(0))                        # area_description_phonetic_offset
    put(be16(0))                        # copyright_phonetic_offset
    assert off == 152, off
    return bytes(s)


def synthetic_sector(lsn):
    # xorshift32 seeded per LSN; identical bytes for both daemons
    s = bytearray(LSN)
    x = (lsn ^ 0x5ACD5ACD) & 0xFFFFFFFF
    for i in range(0, LSN, 4):
        x ^= (x << 13) & 0xFFFFFFFF
        x ^= x >> 17
        x ^= (x << 5) & 0xFFFFFFFF
        s[i:i + 4] = struct.pack("<I", x)
    return bytes(s)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out", nargs="?", default="rig_disc.bin", type=Path)
    args = ap.parse_args()

    f = open(args.out, "wb")
    f.truncate(TOTAL_SECTORS * LSN)

    def put_sector(lsn, data):
        f.seek(lsn * LSN)
        f.write(data)

    put_sector(510, master_toc_sector())
    for i in range(511, 519):
        put_sector(i, sacd_text_sector())
    put_sector(519, sacd_man_sector())
    put_sector(AREA_LSN, area_toc_sector())
    for lsn in list(range(0, 128)) + [MID_LSN, MID_LSN + 1]:
        put_sector(lsn, synthetic_sector(lsn))
    f.close()
    print("wrote %s (%d sectors, sparse)" % (args.out, TOTAL_SECTORS))


if __name__ == "__main__":
    main()
