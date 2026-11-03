#!/usr/bin/env python3
"""Test the retail U-Boot handoff with a known initial ramdisk of identical length."""
import argparse
import gzip
from pathlib import Path
import struct
import tempfile

from run import command
from smoke import UBOOT, observe

MARKER = b"BX510_RAMDISK_CONTROL_EXECUTED\n"


def probe_elf():
    # Standalone ARM Linux /init. write(1, marker, len), then pause forever.
    # The literal follows the eight ARM instructions. At the ADD, PC is 12.
    code = struct.pack("<8I",
                       0xe3a00001,        # mov r0, #1
                       0xe28f1014,        # add r1, pc, #20
                       0xe3a02000 | len(MARKER),  # mov r2, #len
                       0xe3a07004,        # mov r7, #4 (write)
                       0xef000000,        # svc #0
                       0xe3a0701d,        # mov r7, #29 (pause)
                       0xef000000,        # svc #0
                       0xeafffffd) + MARKER  # b to the second svc
    start = 0x10000
    code_offset = 52 + 32
    size = code_offset + len(code)
    ident = b"\x7fELF\x01\x01\x01" + bytes(9)
    header = struct.pack("<16sHH5I6H", ident, 2, 40, 1, start + code_offset, 52,
                         0, 0x05000000, 52, 32, 1, 0, 0, 0)
    load = struct.pack("<8I", 1, 0, start, start, size, size, 5, 4096)
    return header + load + code


def ramdisk(size):
    archive = bytearray()
    entries = (("dev", 0o040755, b"", 0, 0),
               ("dev/console", 0o020600, b"", 5, 1),
               ("init", 0o100755, probe_elf(), 0, 0),
               ("TRAILER!!!", 0, b"", 0, 0))
    for ino, (name, mode, data, major, minor) in enumerate(entries, start=1):
        name = name.encode() + b"\0"
        fields = (ino, mode, 0, 0, 1, 0, len(data), 0, 0, major, minor, len(name), 0)
        archive.extend(b"070701" + "".join(f"{x:08x}" for x in fields).encode() + name)
        archive.extend(bytes(-len(archive) % 4))
        archive.extend(data)
        archive.extend(bytes(-len(archive) % 4))
    compressed = gzip.compress(bytes(archive), mtime=0)
    if len(compressed) > size:
        raise ValueError("control ramdisk exceeds the stock handoff length")
    return compressed.ljust(size, b"\0")


def check(args):
    images = args.images.resolve(strict=True)
    with tempfile.TemporaryDirectory() as temp:
        stage = Path(temp)
        for name in ("nand.img", "kernel.uImage", "u-boot.bin", "preloader.args"):
            (stage / name).symlink_to(images / name)
        (stage / "initrd_1.bin").write_bytes(ramdisk((images / "initrd_1.bin").stat().st_size))
        boot = command(args.qemu.resolve(strict=True), stage, "uboot")
        wanted = UBOOT + (b"root=/dev/ram0 rw initrd=0x1c000000,0x000821f0", MARKER.rstrip())
        observe(boot, [], wanted, args.timeout, args.log)
    print("PASS retail U-Boot and kernel executed the control /init at the stock handoff length")


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--qemu", required=True, type=Path)
    p.add_argument("--images", required=True, type=Path)
    p.add_argument("--log", type=Path)
    p.add_argument("--timeout", type=float, default=70)
    check(p.parse_args())
