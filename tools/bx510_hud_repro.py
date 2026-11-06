#!/usr/bin/env python3
"""bx510_hud_repro.py — render the SACD HUD in the REAL Sony guest and dump the
framebuffer, so a screenshot can be inspected without the player.

Why this is faithful: the guest runs Sony's own kernel 2.6.35 + rootfs +
libdirectfb 1.2.7 + libdirectfb_mtk.so provider, and fbvirt.ko implements the
MT85xx vendor contract we decoded. So what the HUD draws, the layout, the text,
the blit and the pixel content all exercise the same code path as the panel.

What it does NOT reproduce: HDMI/video layers, real CPU speed (fps is not
meaningful here), IR input, and the appliance's own UI process.

Usage:
  python3 bx510_hud_repro.py --qemu <qemu-system-arm> --images <images dir> \
      --shim tmpredir.so --fbmod fbvirt.ko --hud sacd_hud --fbdump fbdump \
      --log out.log [--secs 3] [--scale 2]
"""
import argparse
import io
import json
import shutil
import tarfile
import tempfile
from pathlib import Path

from bx510_fbmt85_repro import command, observe   # same QEMU plumbing


def build_tar(files):
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w", format=tarfile.USTAR_FORMAT) as arc:
        for name, path in files:
            data = Path(path).read_bytes()
            e = tarfile.TarInfo(name)
            e.size, e.mode = len(data), 0o755
            arc.addfile(e, io.BytesIO(data))
    return buf.getvalue()


def main():
    p = argparse.ArgumentParser(description=__doc__)
    for opt in ("qemu", "images", "shim", "fbmod", "hud", "fbdump", "log"):
        p.add_argument("--" + opt, required=True, type=Path)
    p.add_argument("--secs", type=int, default=3)
    p.add_argument("--scale", type=int, default=2)
    p.add_argument("--dump", choices=("fbdev", "pool"), default="fbdev",
                   help="which buffer to dump (the HUD writes the fbdev smem)")
    p.add_argument("--calib", action="store_true",
                   help="draw the calibration pattern instead of the HUD scene")
    p.add_argument("--font", type=Path, default=None,
                   help="Sony font (carved from /res/font.bin) to stage in-guest")
    p.add_argument("--pool-mode", action="store_true",
                   help="run the HUD with HUD_POOL=1 (draw straight into the pool)")
    p.add_argument("--pool-w", type=int, default=1920)
    p.add_argument("--pool-h", type=int, default=1080)
    p.add_argument("--pool-ofs", type=int, default=4096,
                   help="byte offset of the primary inside the vendor pool")
    p.add_argument("--timeout", type=float, default=900.0)
    a = p.parse_args()

    images = a.images.resolve(strict=True)
    files = [("shim/tmpredir.so", a.shim),
             ("shim/fbvirt.ko", a.fbmod),
             ("shim/sacd_hud", a.hud),
             ("shim/fbdump", a.fbdump)]
    if a.font:
        files.append(("shim/sony-font.ttf", a.font))
    payload = build_tar(files)
    parts = json.loads((images / "manifest.json").read_text())["partitions"]
    part = next(x for x in parts if x["name"] == "fe_test_data")
    if part["records"] or part["offset"] != 0xE00000 or len(payload) > part["size"]:
        raise ValueError("fixture does not fit the expected unused partition")
    blocks = (len(payload) + 4095) // 4096

    commands = [
        "mount -t tmpfs tmpfs /res; /bin/mknod /res/test-bdev b 31 10; "
        "/bin/mkdir -p /res/tmp /res/dev /res/proc",
        f"/bin/dd if=/res/test-bdev bs=4096 count={blocks} 2>/res/dd.err | /bin/tar -xf - -C /res",
        "/bin/chmod 755 /res/shim/tmpredir.so /res/shim/sacd_hud /res/shim/fbdump",
        "mount -t proc proc /res/proc; echo HR_PROC=$?",
        "echo HR_STAGED; ls -l /res/shim; echo HR_STAGED_END",
        "/sbin/insmod /res/shim/fbvirt.ko; echo HR_FB=$?",
        "grep fb /res/proc/fb; echo HR_FBREG=$?",
        "/bin/mknod /res/dev/fb0 c 29 0; echo HR_FBNODE=$?",
        "/bin/mkdir -p /res/dev/shm",
        "n=0; while [ $n -le 7 ]; do /bin/mknod /res/dev/tty$n c 4 $n 2>/res/e; n=$((n+1)); done",
        "n=0; /bin/mkdir -p /res/dev/vc; while [ $n -le 7 ]; do /bin/mknod /res/dev/vc/$n c 4 $n 2>/res/e; n=$((n+1)); done",
        "/sbin/insmod /lib/modules/2.6.35/BDP/fusion.ko; echo HR_FUSION=$?",
        "set -- $(grep fusion /res/proc/devices); /bin/mknod /res/dev/fusion0 c $1 0; echo HR_FUSNODE=$?",
        # the HUD itself, exactly as the supervisor runs it
        "LD_PRELOAD=/res/shim/tmpredir.so HUD_POOL=1 HUD_FONT=/res/shim/sony-font.ttf "
        + ("HUD_CALIB=1 " if a.calib else "")
        + "/res/shim/sacd_hud --render >/res/hud.out 2>&1; echo HR_HUD=$?",
        "echo HR_HUD_BEGIN; cat /res/hud.out; echo HR_HUD_END",
        # and what it actually put on the (virtual) panel
        f"LD_PRELOAD=/res/shim/tmpredir.so /res/shim/fbdump {'--pool ' if a.dump == 'pool' else ''}/res/dev/fb0 {a.scale} "
        + (f"{a.pool_ofs} {a.pool_w} {a.pool_h}" if a.dump == 'pool' else "")
        + " >/res/fb.txt 2>&1; echo HR_DUMP=$?",
        "echo HR_FB_BEGIN; cat /res/fb.txt; echo HR_FB_END",
        'echo HR_REPRO_DONE',
    ]
    wanted = [b"HR_REPRO_DONE"]

    with tempfile.TemporaryDirectory() as temp:
        nand = Path(temp) / "fixture.img"
        shutil.copyfile(images / "nand.img", nand)
        with nand.open("r+b") as f:
            f.seek(part["offset"])
            f.write(payload)
        argv = command(a.qemu.resolve(strict=True), images, "shell", nand)
        observe(argv, commands, wanted, a.timeout, a.log)


if __name__ == "__main__":
    main()
