#!/usr/bin/env python3
"""Prepare the Sony M15.R.0257 ARM kernel and a 256 MiB update-derived NAND image."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import struct
import tempfile
from urllib.request import urlopen
from zipfile import ZipFile
import zlib

FIRMWARE = "https://hav.update.sony.net/BDP/data/UPDATA_M15R0257.zip"
ARCHIVE_HASH = "7209013baa51d9d011c928c76f96c7dec883c271b99097b91a376b930add151c"
TABLE = ("https://raw.githubusercontent.com/theubusu/unixtract/"
         "aadba866ea47ed9506ffe130a8558bb9147ee968/src/keys.ukf")
TABLE_HASH = "9371ed11ffed8ea82fbb9f612036ba1f09e31c6e851da2ea56721013a34b48af"
KERNEL_HASH = "10bb0fba4eb26c5b1ebf798f4d4669dc8b5899d520be294d333c318a360be2d7"
UBOOT_HASH = "40f19951773da0b180c4719c6d12dd2cea222b29f777f6c69d559fb85d9ac03b"
ARM2_HASH = "2e84f931415dde0c9e85fc2c9f11c1cde64af8097acbbc117a3d2bff259f66af"
NAND_HASH = "592b2920c2044f90ba91d85f8e58b8d52282355dd25c6ed6c0c88c0c548ceb30"
NAND_SIZE = 256 << 20
PITIT = b"iTIPiTIP"
BIT_HEAD = struct.pack("<I", 0x8530ABCD) * 5
PIT_HEAD = struct.pack("<I", 0x8530EADC) * 2
ADAPT_HEAD = struct.pack("<I", 0x8530AAAA) * 2


def digest(data):
    return hashlib.sha256(data).hexdigest()


def require(ok, why):
    if not ok:
        raise ValueError(why)


def source(local, url, expected, tmp):
    """An optional local file makes the extraction fully offline."""
    if local is None:
        with urlopen(url, timeout=90) as upstream, tmp.open("wb") as out:
            shutil.copyfileobj(upstream, out)
        local = tmp
    with local.open("rb") as stream:
        h = hashlib.sha256()
        for chunk in iter(lambda: stream.read(1 << 20), b""):
            h.update(chunk)
    require(h.hexdigest() == expected, f"SHA-256 mismatch for {local}")
    return local


def decode_update(data, lookup):
    """Decode the outer Sony substitution, then take the host update member."""
    decoded = data.translate(lookup)
    require(decoded[:5] == b"MSB15" and decoded[16:26] == b"M15.R.0257", "unexpected Sony firmware")
    require(struct.unpack_from("<I", decoded, 92)[0] == len(decoded), "Sony file length mismatch")
    offset, size = struct.unpack_from("<II", decoded, 160 + 4 * 8)
    require(offset >= 240 and offset + size <= len(decoded), "bad host image bounds")
    return decoded[offset:offset + size]


def extract(out, archive, table):
    # Follow the Sony/MediaTek header layout documented by unixtract. Always
    # verify ranges before using firmware-supplied offsets or partition names.
    text = table.read_text()
    raw_table = text.split('key "SONY_BDP_HEX_SUBST"', 1)[1].split('x"', 1)[1].split('"', 1)[0]
    lut = bytes.fromhex(raw_table)
    require(len(lut) == 256 and len(set(lut)) == 256, "invalid substitution table")
    with ZipFile(archive) as update:
        data = decode_update(update.read("UPDATE/MSB15-FW.BIN"), lut)
    table_at = data.rfind(PITIT)
    require(table_at >= 0, "missing MediaTek table directory")
    cap, pit, pit_len, _, bit, bit_len, _, _ = struct.unpack_from("<8I", data, table_at + 16)
    require(cap == NAND_SIZE and data[pit:pit + 8] == PIT_HEAD, "unexpected NAND geometry or PIT")
    require(data[bit:bit + 20] == BIT_HEAD and bit_len % 20 == 0, "unexpected BIT")
    first, stride, count = struct.unpack_from("<3I", data, pit + 12)
    require(stride == 64 and first + count * stride <= pit_len and pit + pit_len <= len(data), "invalid PIT")
    parts = {}
    for i in range(count):
        name, ident, flags, start, size = struct.unpack_from("<16s4I", data, pit + first + i * stride)
        name = name.split(bytes(1), 1)[0].decode("ascii")
        require(name.replace("_", "").isalnum() and ident not in parts and start + size <= cap, "invalid partition")
        parts[ident] = dict(name=name, offset=start, size=size, flags=flags, records=[])
    require(bit + bit_len <= len(data) and data[bit + bit_len - 20:bit + bit_len] ==
            struct.pack("<I", 0x8530EFEF) * 5, "unterminated BIT")
    firmware_kernel = None
    with (out / "nand.img").open("w+b") as flash:
        # The updater leaves factory data, bad blocks and untouched sectors
        # unspecified. 0xff means erased in this synthetic installation.
        blank = b"\xff" * (1 << 20)
        for _ in range(cap // len(blank)):
            flash.write(blank)
        for pos in range(bit + 20, bit + bit_len - 20, 20):
            ident, offset, size, within, flags = struct.unpack_from("<5I", data, pos)
            part = parts[ident]
            require(offset + size <= len(data) and within + size <= part["size"], "BIT range outside partition")
            content = data[offset:offset + size]
            flash.seek(part["offset"] + within)
            flash.write(content)
            part["records"].append(dict(offset=within, size=size, sha256=digest(content), flags=flags))
            if part["name"] == "boot_1" and within == 0x2a000:
                require(digest(content) == UBOOT_HASH, "stock U-Boot SHA-256 mismatch")
                (out / "u-boot.bin").write_bytes(content)
            if part["name"] == "boot_1" and within == 0x17400:
                require(digest(content) == ARM2_HASH, "ARM2 fastboot SHA-256 mismatch")
                (out / "arm2-fastboot.bin").write_bytes(content)
            if part["name"] == "kernel_1":
                require(within == 0 and firmware_kernel is None, "unexpected fragmented kernel")
                firmware_kernel = content
            if within == 0 and part["name"] in ("initrd_1", "rootfs_normal_1", "rootfs_enc_it_1"):
                (out / (part["name"] + ".bin")).write_bytes(content)
        # The running kernel scans for an installed/adaptive PIT. Build its
        # no-bad-block geometry from the exact updater PIT, without inventing
        # MAC addresses, keys, optical calibration, or factory payloads.
        installed_pit = ADAPT_HEAD + data[pit + 8:pit + pit_len]
        info = next(p for p in parts.values() if p["name"] == "part_info_1")
        require(all(r["offset"] >= len(installed_pit) for r in info["records"]), "adaptive PIT overlaps update data")
        flash.seek(info["offset"])
        flash.write(installed_pit)
    require(firmware_kernel is not None and digest(firmware_kernel) == KERNEL_HASH, "stock kernel SHA-256 mismatch")
    header, kernel = firmware_kernel[:64], firmware_kernel[64:]
    magic, crc, _, size, load, entry, data_crc, os_id, arch, kind, comp = struct.unpack(">7I4B", header[:32])
    require((magic, os_id, arch, kind, comp) == (0x27051956, 5, 2, 2, 0), "unexpected uImage type")
    require(zlib.crc32(header[:4] + bytes(4) + header[8:]) == crc and len(kernel) == size and
            zlib.crc32(kernel) == data_crc, "uImage CRC mismatch")
    (out / "kernel.uImage").write_bytes(firmware_kernel)
    # This is an explicitly reconstructed handoff, not a ROM dump. Fields follow
    # board/mt8530_base/mt85xx_board.c and arch-mt8530/args_to_uboot.h.
    init_size = (out / "initrd_1.bin").stat().st_size
    (out / "preloader.args").write_bytes(struct.pack("<10I", 0xa0b0ead1, 1, 0,
            256 << 20, 256 << 20, load - 64, 0x1c000000, init_size, 0, 0))
    require((out / "u-boot.bin").is_file(), "missing retail U-Boot")
    require((out / "arm2-fastboot.bin").is_file(), "missing ARM2 fastboot image")
    with (out / "nand.img").open("rb") as flash:
        h = hashlib.sha256()
        for chunk in iter(lambda: flash.read(1 << 20), b""):
            h.update(chunk)
        require(h.hexdigest() == NAND_HASH, "reconstructed NAND SHA-256 mismatch")
    manifest = dict(uboot_sha256=UBOOT_HASH, arm2_sha256=ARM2_HASH, nand_sha256=NAND_HASH,
                    firmware="M15.R.0257", archive_sha256=ARCHIVE_HASH, kernel_sha256=KERNEL_HASH,
                    load=hex(load), entry=hex(entry), nand_size=cap, adaptive_pit_at=info["offset"],
                    partitions=list(parts.values()))
    (out / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("output", type=Path, help="new directory for the kernel, flash and metadata")
    p.add_argument("--zip", type=Path, help="locally downloaded Sony update ZIP")
    p.add_argument("--keys", type=Path, help="pinned public unixtract keys.ukf")
    a = p.parse_args()
    if a.output.exists():
        p.error("choose a new output directory")
    a.output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=a.output.parent) as temp:
        work = Path(temp)
        archive = source(a.zip, FIRMWARE, ARCHIVE_HASH, work / "update.zip")
        table = source(a.keys, TABLE, TABLE_HASH, work / "keys.ukf")
        stage = work / "output"
        stage.mkdir()
        extract(stage, archive, table)
        stage.rename(a.output)
    print(f"{a.output / 'kernel.uImage'}  SHA-256 {KERNEL_HASH}")


if __name__ == "__main__":
    main()
