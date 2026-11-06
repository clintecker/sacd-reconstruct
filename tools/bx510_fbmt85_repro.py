#!/usr/bin/env python3
"""BX510 MT85xx vendor-contract guest reproduction (DirectFB rung harness).

Question: does the SHIPPED retail libdirectfb-1.2.so.0 get through
FBIO_INIT + system_initialize + DirectFBCreate + a live surface when the
fbvirt guest module implements the published MT85xx vendor ioctl contract
(18 requests, three-class mmap selector protocol)?

The probe file (bx510_phase0_probe.py) belongs to another lane and is NOT
modified; this harness replicates its guest machinery (tmpfs /res, tar
staging through the fe_test_data partition, tmpredir shim, device nodes,
the guest's own fusion.ko) exactly the way bx510_pair_repro.py does.

Guest sequence (controls first, every suite):
  1. fbvirt.ko insmod, /res/dev/{fb0,shm,tty*,vc*} nodes, fusion.ko
  2. CONTROL: `fbdraw fbdraw` — the raw-fbdev regression gate; its
     full-frame md5 must equal the pinned pre-MT85 md5
     7d19af14518cb5c201aedab2cf94e83d (byte-stable extension)
  3. RUNG: `fbdraw fbmt85` under LD_PRELOAD=tmpredir — negative controls
     (invalid selector/request/mmap must fail) then the shipped DirectFB
     with no-hardware software rendering: FBIO_INIT -> ... ->
     DirectFBCreate -> FillRectangle -> Flip -> pool capture + md5 vs an
     independently built expectation
  4. DISCOVERY: `fbdraw fbmt85hw` under bgstart (may wedge — bounded by
     the sleep; its output is catted, never gating the rung evidence);
     the retail gfxdriver may push command-ring items (module logs them)

Success ladder (printed markers, evidence in the UART transcript):
  FBMT85: rung (a)+(b) ... DirectFBCreate SUCCEEDED   -> rungs a+b
  FBMT85: rung (c) primary surface LIVE              -> rung c
  FBMT85: rung (d) ... FillRectangle ... rc=0         -> rung d
  FBMT85: rung (e) pool capture MATCHES ...          -> rung e

Run from ~/bx510-emu/emulator on the lab VM:

  python3 bx510_fbmt85_repro.py --qemu work/build/qemu-system-arm \\
      --images ../images --shim /tmp/tmpredir.so --bgstart /tmp/bgstart \\
      --fbmod /tmp/mt85mod/bx510_fbvirt.ko --fbdraw /tmp/mt85mod/fbdraw \\
      --timeout 900 --log /tmp/mt85mod/run.log
"""
import argparse
import io
import json
import shutil
import sys
import tarfile
import tempfile
from pathlib import Path

from run import command
from smoke import observe

RAW_REGRESSION_MD5 = "7d19af14518cb5c201aedab2cf94e83d"
"""Pinned pre-MT85 full-frame md5 (RESULTS.md rung 1). The MT85 extension
must leave the raw fbdev path byte-identical; the harness asserts it."""


def build_tar(shim: Path, bgstart: Path, fbmod: Path, fbdraw: Path) -> bytes:
    """Stage the guest shims + the extended module + the test tool."""
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w", format=tarfile.USTAR_FORMAT) as arc:
        for name, path in (("shim/tmpredir.so", shim),
                           ("shim/bgstart", bgstart),
                           ("shim/fbvirt.ko", fbmod),
                           ("shim/fbdraw", fbdraw)):
            data = path.read_bytes()
            entry = tarfile.TarInfo(name)
            entry.size, entry.mode = len(data), 0o755
            arc.addfile(entry, io.BytesIO(data))
    return buf.getvalue()


def main():
    p = argparse.ArgumentParser(description=__doc__)
    for opt in ("qemu", "images", "shim", "bgstart", "fbmod", "fbdraw",
                "log"):
        p.add_argument("--" + opt, required=True, type=Path)
    p.add_argument("--timeout", type=float, default=900.0)
    p.add_argument("--skip-hw", action="store_true",
                   help="skip the fbmt85hw discovery variant (software "
                        "rungs only)")
    a = p.parse_args()

    images = a.images.resolve(strict=True)
    payload = build_tar(a.shim, a.bgstart, a.fbmod, a.fbdraw)
    parts = json.loads((images / "manifest.json").read_text())["partitions"]
    part = next(x for x in parts if x["name"] == "fe_test_data")
    if part["records"] or part["offset"] != 0xe00000 or len(payload) > part["size"]:
        raise ValueError("fixture does not fit the expected unused partition")
    blocks = (len(payload) + 4095) // 4096

    commands = [
        "mount -t tmpfs tmpfs /res; /bin/mknod /res/test-bdev b 31 10; "
        "/bin/mkdir /res/tmp /res/dev /res/proc",
        f"/bin/dd if=/res/test-bdev bs=4096 count={blocks} 2>/res/dd.err | /bin/tar -xf - -C /res",
        "/bin/chmod 755 /res/shim/tmpredir.so /res/shim/bgstart "
        "/res/shim/fbdraw",
        "mount -t proc proc /res/proc; echo PR_PROC=$?",
        "echo x > /res/zero",
        "echo PR_STAGED; ls -l /res/shim; echo PR_STAGED_END",
        # virtual framebuffer with the MT85 vendor contract
        "/sbin/insmod /res/shim/fbvirt.ko; echo PR_FB=$?",
        "grep fb /res/proc/fb; echo PR_FBREG=$?",
        "/bin/mknod /res/dev/fb0 c 29 0; echo PR_FBNODE=$?",
        "/bin/mkdir -p /res/dev/shm; echo PR_SHM=$?",
        "n=0; while [ $n -le 7 ]; do /bin/mknod /res/dev/tty$n c 4 $n "
        "2>/res/e; n=$((n+1)); done; echo PR_TTYN=$?",
        "n=0; /bin/mkdir -p /res/dev/vc; while [ $n -le 7 ]; do "
        "/bin/mknod /res/dev/vc/$n c 4 $n 2>/res/e; n=$((n+1)); done; "
        "echo PR_VCN=$?",
        # the guest's OWN fusion.ko (multi-app core IPC)
        "/sbin/insmod /lib/modules/2.6.35/BDP/fusion.ko; echo PR_FUSION=$?",
        "set -- $(grep fusion /res/proc/devices); "
        "/bin/mknod /res/dev/fusion0 c $1 0; echo PR_FUSNODE=$?",
        # CONTROL: raw fbdev regression gate (pinned md5, must not drift)
        "LD_PRELOAD= /res/shim/fbdraw fbdraw >/res/raw.out 2>&1; "
        "echo PR_RAW=$?",
        "echo PR_RAW_BEGIN; cat /res/raw.out; echo PR_RAW_END",
        # RUNG: negative controls + no-hardware DirectFB + pool capture
        "LD_PRELOAD=/res/shim/tmpredir.so /res/shim/fbdraw fbmt85 "
        ">/res/mt85.out 2>&1; echo PR_MT=$?",
        "echo PR_MT_BEGIN; cat /res/mt85.out; echo PR_MT_END",
        # DISCOVERY variant (never gates the rung; bgstart bounds it)
        *([] if a.skip_hw else [
            "LD_PRELOAD=/res/shim/tmpredir.so /res/shim/bgstart "
            "/res/shim/fbdraw fbmt85hw; sleep 25; echo PR_HWDONE=$?",
            "echo PR_HW_BEGIN; cat /res/daemon.out; echo PR_HW_END",
        ]),
        'echo PR_MT""85_DONE',
    ]
    wanted = [b"PR_MT85_DONE"]

    with tempfile.TemporaryDirectory() as temp:
        nand = Path(temp) / "fixture.img"
        shutil.copyfile(images / "nand.img", nand)
        with nand.open("r+b") as f:
            f.seek(part["offset"])
            f.write(payload)
        argv = command(a.qemu.resolve(strict=True), images, "shell", nand)
        log = observe(argv, commands, wanted, a.timeout, a.log)
        if b"PR_MT85_DONE" not in log:
            print("REPRO FAILED: PR_MT85_DONE never appeared (boot/UART "
                  "failure); log preserved at " + str(a.log),
                  file=sys.stderr)
            sys.exit(1)
        text = log.decode(errors="replace")
        print(text[-12000:])
        # verdict extraction for the transcript summary
        checks = {
            "rung-ab (DirectFBCreate)": b"DirectFBCreate SUCCEEDED" in log,
            "rung-c (live surface)": b"primary surface LIVE" in log,
            "rung-d (FillRectangle)": b"rung (d)" in log and b"rc=0" in log,
            "rung-e (pool match)": b"pool capture MATCHES" in log,
            "negative-control PASS": b"NEGCTL PASS" in log,
            "raw regression md5": RAW_REGRESSION_MD5.encode() in log,
        }
        print("--- ladder ---")
        for name, ok in checks.items():
            print(f"{'PASS' if ok else 'MISS'}  {name}")
        if not all(checks.values()):
            print("INCOMPLETE LADDER — see MT85-RESULTS.md duties: the "
                  "module log names every unhandled request with its args")
            sys.exit(2)


if __name__ == "__main__":
    main()
