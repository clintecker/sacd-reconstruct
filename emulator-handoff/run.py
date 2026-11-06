#!/usr/bin/env python3
"""Launch the reference BX510 machine. NAND changes stay in a transient overlay."""
import argparse
import os
from pathlib import Path


def command(qemu, images, mode, nand=None):
    images = images.resolve(strict=True)
    nand = nand or images / "nand.img"
    # QEMU's comma-separated drive/device syntax escapes a literal comma by doubling it.
    quote = lambda p: str(p).replace(",", ",,")
    args = [str(qemu), "-M", "player.local", "-m", "512M", "-display", "none",
            "-serial", "stdio", "-monitor", "none", "-nic", "none",
            "-drive", f"if=mtd,format=raw,file={quote(nand)},snapshot=on"]
    if mode == "uboot":
        # QEMU stages the four artifacts at a documented preloader handoff.
        # Only the CPU-bearing loader sets the initial program counter.
        for name, addr, sets_pc in (("u-boot.bin", 0x04f00000, True),
                                     ("preloader.args", 0x400, False),
                                     ("kernel.uImage", 0x0d9fffc0, False),
                                     ("initrd_1.bin", 0x1c000000, False)):
            device = f"loader,file={quote(images / name)},addr={addr:#x},force-raw=on"
            args.extend(["-device", device + (",cpu-num=0" if sets_pc else "")])
    elif mode == "fastboot":
        # An independent replay of the update's auxiliary ARM2 image.
        args.extend(["-device", f"loader,file={quote(images / 'arm2-fastboot.bin')},"
                     "addr=0,cpu-num=0,force-raw=on"])
    elif mode == "shell":
        args.extend(["-kernel", str(images / "kernel.uImage"), "-append",
                     "console=ttyMT0,115200 mem=512M root=/dev/mtdblock17 "
                     "rootfstype=squashfs ro init=/bin/sh"])
    else:
        raise ValueError(f"unknown boot mode: {mode}")
    return args


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--qemu", type=Path, required=True)
    parser.add_argument("--images", type=Path, required=True)
    parser.add_argument("mode", choices=("shell", "uboot", "fastboot"))
    a = parser.parse_args()
    args = command(a.qemu.resolve(strict=True), a.images, a.mode)
    os.execv(args[0], args)


if __name__ == "__main__":
    main()
