#!/usr/bin/env python3
"""Exercise the Sony system through its UART. Requires the full-system QEMU build."""
import argparse
import os
from pathlib import Path
import selectors
import subprocess
import time

from run import command

SHELL = (b"Linux version 2.6.35 (aokino@rvds241)", b"mt85xx_part_tbl_init success",
         b"VFS: Mounted root (squashfs filesystem) readonly on device 31:17.",
         b"BX510_GUEST_OK pid=1",
         b"fd3542eeeb6881bcd715fc1b83519ba3  /lib/modules/2.6.35/BDP/bdpdrv.ko")
UBOOT = (b"U-Boot 2009.08 (Oct 15 2012", b"DRAM:  512 MB", b"NAND:  256 MiB",
         b"Loading Kernel Image ... OK", b"Linux version 2.6.35 (aokino@rvds241)")
FASTBOOT = (b"[vFL_fastboot_main]Power Mode", b"[IDE_FB]F/E working area = 0xc0c00000",
            b"vIdeFastBoot(9415) end")
# The MD5 value verifies a multi-megabyte file across emulated NAND pages.
# Package authenticity is checked separately with SHA-256 in firmware.py.


def observe(argv, lines, wanted, timeout, log):
    proc = subprocess.Popen(argv,
                            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    data = bytearray()
    pos = 0
    pending = iter(lines)
    try:
        with selectors.DefaultSelector() as sel:
            sel.register(proc.stdout, selectors.EVENT_READ)
            deadline = time.monotonic() + timeout
            while time.monotonic() < deadline:
                if not sel.select(.5):
                    if proc.poll() is not None:
                        break
                    continue
                chunk = os.read(proc.stdout.fileno(), 8192)
                if not chunk:
                    break
                data.extend(chunk)
                prompt = data.find(b"/ # ", pos)
                if prompt >= 0:
                    pos = prompt + 4
                    line = next(pending, None)
                    if line is not None:
                        proc.stdin.write(line.encode() + b"\n")
                        proc.stdin.flush()
                if all(item in data for item in wanted):
                    break
    finally:
        if proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(timeout=4)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()
        if log:
            log.write_bytes(data)
        proc.stdin.close()
        proc.stdout.close()
    missing = [s.decode() for s in wanted if s not in data]
    if missing:
        print(bytes(data[-2200:]).decode(errors="replace"))
        raise SystemExit("Missing UART evidence: " + ", ".join(missing))
    return bytes(data)


def check(args):
    modes = {"shell": ("shell", SHELL), "handoff": ("uboot", UBOOT), "fastboot": ("fastboot", FASTBOOT)}
    mode, wanted = modes[args.mode]
    # Split the marker so a local terminal echo cannot pass the shell check.
    lines = ["printf 'BX510_%s pid=%s\\n' GUEST_OK $$",
             "/usr/bin/md5sum /lib/modules/2.6.35/BDP/bdpdrv.ko"] if mode == "shell" else []
    observe(command(args.qemu.resolve(strict=True), args.images, mode), lines, wanted, args.timeout, args.log)
    print("PASS " + args.mode)
    for item in wanted:
        print("  " + item.decode())


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--qemu", required=True, type=Path)
    p.add_argument("--images", required=True, type=Path)
    p.add_argument("--log", type=Path)
    p.add_argument("--timeout", type=float, default=70)
    p.add_argument("mode", choices=("shell", "handoff", "fastboot"))
    check(p.parse_args())
