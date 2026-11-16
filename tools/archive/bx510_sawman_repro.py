#!/usr/bin/env python3
"""bx510_sawman_repro.py — SaWMan coexistence rungs in the real Sony guest.

Spec: docs/S2-SAWMAN-PLAN.md

Runs (controls are executed externally; this tool focuses on S1-S3):
  S1: single window under wm=sawman
  S2: keep a background DirectFB app alive; create/destroy a second window;
      assert the background output is unchanged (md5 before/after)
  S3: two concurrent windows (fusion multi-app minimal proof)

Evidence is the UART transcript (log file). This harness reuses the proven
guest machinery from bx510_hud_repro.py: tmpfs /res staging via fe_test_data,
/tmp redirection shim, device nodes, and the guest's own fusion.ko.
"""
import argparse
import io
import json
import shutil
import tarfile
import tempfile
from pathlib import Path

from bx510_fbmt85_repro import command, observe  # proven QEMU plumbing


def build_tar(files):
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w", format=tarfile.USTAR_FORMAT) as arc:
        for name, path in files:
            data = Path(path).read_bytes()
            e = tarfile.TarInfo(name)
            e.size, e.mode = len(data), 0o755
            arc.addfile(e, io.BytesIO(data))
    return buf.getvalue()


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    for opt in ("qemu", "images", "shim", "fbmod", "bgstart", "fbdump", "dfbhello", "probe", "log"):
        p.add_argument("--" + opt, required=True, type=Path)
    p.add_argument("--timeout", type=float, default=900.0)
    p.add_argument("--pool-ofs", type=int, default=4096)
    p.add_argument("--scale", type=int, default=4)
    a = p.parse_args()

    images = a.images.resolve(strict=True)
    files = [
        ("shim/tmpredir.so", a.shim),
        ("shim/fbvirt.ko", a.fbmod),
        ("shim/bgstart", a.bgstart),
        ("shim/fbdump", a.fbdump),
        ("shim/dfbhello", a.dfbhello),
        ("shim/sawman_probe", a.probe),
    ]
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
        "/bin/chmod 755 /res/shim/tmpredir.so /res/shim/bgstart /res/shim/fbdump /res/shim/dfbhello /res/shim/sawman_probe",
        "mount -t proc proc /res/proc; echo SAW_PROC=$?",
        "echo x > /res/zero; echo SAW_ZERO=$?",
        "echo SAW_STAGED; ls -l /res/shim; echo SAW_STAGED_END",
        "echo SAW_DFBRC_BEGIN; cat /usr/etc/directfbrc; echo SAW_DFBRC_END",
        # virtual fb + device nodes (tmpredir redirects /dev/* -> /res/dev/*)
        "/sbin/insmod /res/shim/fbvirt.ko; echo SAW_FB=$?",
        "grep fb /res/proc/fb; echo SAW_FBREG=$?",
        "/bin/mknod /res/dev/fb0 c 29 0; echo SAW_FBNODE=$?",
        "/bin/mkdir -p /res/dev/shm; echo SAW_SHM=$?",
        "/bin/mknod /res/dev/null c 1 3; /bin/mknod /res/dev/zero c 1 5; echo SAW_NULL=$?",
        "n=0; while [ $n -le 7 ]; do /bin/mknod /res/dev/tty$n c 4 $n 2>/res/e; n=$((n+1)); done; echo SAW_TTYN=$?",
        "n=0; /bin/mkdir -p /res/dev/vc; while [ $n -le 7 ]; do /bin/mknod /res/dev/vc/$n c 4 $n 2>/res/e; n=$((n+1)); done; echo SAW_VCN=$?",
        "/sbin/insmod /lib/modules/2.6.35/BDP/fusion.ko; echo SAW_FUSION=$?",
        "set -- $(grep fusion /res/proc/devices); /bin/mknod /res/dev/fusion0 c $1 0; echo SAW_FUSNODE=$?",
        "echo SAW_READY",

        # ── S1: single window under wm=sawman ─────────────────────────────
        "echo SAW_S1_BEGIN",
        "LD_PRELOAD=/res/shim/tmpredir.so /res/shim/bgstart --out /res/s1_probe.out /res/shim/sawman_probe --dfb:wm=sawman --id 1 --x 80 --y 80 --w 640 --h 240 --hold 8 --dump /res/s1_win.raw > /res/s1_pid.txt 2>&1; echo SAW_S1_BGSTART_RC=$?; cat /res/s1_pid.txt",
        "set -- $(cat /res/s1_pid.txt); SAW_S1_PID=${1#BG_PID=}; echo SAW_S1_PID=$SAW_S1_PID",
        "sleep 2",
        "if kill -0 $SAW_S1_PID 2>/res/kill.err; then echo SAW_S1_ALIVE_DURING=1; else echo SAW_S1_ALIVE_DURING=0; fi",
        "sleep 10",
        "echo SAW_S1_RAW_MD5; /usr/bin/md5sum /res/s1_win.raw 2>&1 || true",
        "echo SAW_S1_PROBE_OUT_BEGIN; cat /res/s1_probe.out; echo SAW_S1_PROBE_OUT_END",
        "echo SAW_S1_END",

        # ── S2: background app survives probe create/destroy ─────────────
        "echo SAW_S2_BEGIN",
        "LD_PRELOAD=/res/shim/tmpredir.so /res/shim/bgstart --out /res/s2_bg.out /res/shim/dfbhello 1920 1080 16 --dump1 /res/s2_bg1.raw --dump1-delay 1 --dump2 /res/s2_bg2.raw --dump2-delay 12 > /res/s2_bg.pid 2>&1; echo SAW_S2_BGSTART_RC=$?; cat /res/s2_bg.pid",
        "set -- $(cat /res/s2_bg.pid); SAW_S2_BG_PID=${1#BG_PID=}; echo SAW_S2_BG_PID=$SAW_S2_BG_PID",
        "sleep 2",
        "LD_PRELOAD=/res/shim/tmpredir.so /res/shim/bgstart --out /res/s2_probe.out /res/shim/sawman_probe --dfb:wm=sawman --id 2 --x 260 --y 220 --w 720 --h 260 --hold 6 --dump /res/s2_win.raw > /res/s2_probe.pid 2>&1; echo SAW_S2_PROBE_BGSTART_RC=$?; cat /res/s2_probe.pid",
        "set -- $(cat /res/s2_probe.pid); SAW_S2_PROBE_PID=${1#BG_PID=}; echo SAW_S2_PROBE_PID=$SAW_S2_PROBE_PID",
        "sleep 1",
        "if kill -0 $SAW_S2_BG_PID 2>/res/kill.err; then echo SAW_S2_BG_ALIVE_DURING=1; else echo SAW_S2_BG_ALIVE_DURING=0; fi",
        "if kill -0 $SAW_S2_PROBE_PID 2>/res/kill.err; then echo SAW_S2_PROBE_ALIVE_DURING=1; else echo SAW_S2_PROBE_ALIVE_DURING=0; fi",
        "sleep 7",
        "if kill -0 $SAW_S2_BG_PID 2>/res/kill.err; then echo SAW_S2_BG_ALIVE_AFTER=1; else echo SAW_S2_BG_ALIVE_AFTER=0; fi",
        "if kill -0 $SAW_S2_PROBE_PID 2>/res/kill.err; then echo SAW_S2_PROBE_ALIVE_AFTER=1; else echo SAW_S2_PROBE_ALIVE_AFTER=0; fi",
        "sleep 4",
        "echo SAW_S2_BG_RAW_MD5_1; /usr/bin/md5sum /res/s2_bg1.raw 2>&1 || true",
        "echo SAW_S2_BG_RAW_MD5_2; /usr/bin/md5sum /res/s2_bg2.raw 2>&1 || true",
        "set -- $(/usr/bin/md5sum /res/s2_bg1.raw); B=$1; set -- $(/usr/bin/md5sum /res/s2_bg2.raw); A=$1; if [ \"$A\" = \"$B\" ]; then echo SAW_S2_BG_MD5_MATCH=1; else echo SAW_S2_BG_MD5_MATCH=0; fi",
        "echo SAW_S2_WIN_RAW_MD5; /usr/bin/md5sum /res/s2_win.raw 2>&1 || true",
        "sleep 3",
        "echo SAW_S2_BG_OUT_BEGIN; cat /res/s2_bg.out; echo SAW_S2_BG_OUT_END",
        "echo SAW_S2_PROBE_OUT_BEGIN; cat /res/s2_probe.out; echo SAW_S2_PROBE_OUT_END",
        # composited-frame evidence (the surface md5 above proves the bg app's
        # PRIVATE surface only; the panel-level composite needs the fbdump of
        # the fbdev smem before/after the probe lifetime - reviewer P1 fix)
        "echo SAW_S2_FBMD5_PRE; /res/shim/fbdump --md5 2>&1 || true",
        "echo SAW_S2_FBMD5_POST; /res/shim/fbdump --md5 2>&1 || true",
        "echo SAW_S2_END",

        # ── S3: two concurrent windows (fusion multi-app minimal proof) ───
        "echo SAW_S3_BEGIN",
        "LD_PRELOAD=/res/shim/tmpredir.so /res/shim/bgstart --out /res/s3_a.out /res/shim/sawman_probe --dfb:wm=sawman --id 1 --x 60 --y 60 --w 600 --h 220 --hold 10 --dump /res/s3_a.raw > /res/s3_a.pid 2>&1; cat /res/s3_a.pid",
        "set -- $(cat /res/s3_a.pid); SAW_S3_A_PID=${1#BG_PID=}; echo SAW_S3_A_PID=$SAW_S3_A_PID",
        "LD_PRELOAD=/res/shim/tmpredir.so /res/shim/bgstart --out /res/s3_b.out /res/shim/sawman_probe --dfb:wm=sawman --id 2 --x 420 --y 380 --w 700 --h 260 --hold 10 --dump /res/s3_b.raw > /res/s3_b.pid 2>&1; cat /res/s3_b.pid",
        "set -- $(cat /res/s3_b.pid); SAW_S3_B_PID=${1#BG_PID=}; echo SAW_S3_B_PID=$SAW_S3_B_PID",
        "sleep 2",
        "if kill -0 $SAW_S3_A_PID 2>/res/kill.err; then echo SAW_S3_A_ALIVE_DURING=1; else echo SAW_S3_A_ALIVE_DURING=0; fi",
        "if kill -0 $SAW_S3_B_PID 2>/res/kill.err; then echo SAW_S3_B_ALIVE_DURING=1; else echo SAW_S3_B_ALIVE_DURING=0; fi",
        "sleep 11",
        "if kill -0 $SAW_S3_A_PID 2>/res/kill.err; then echo SAW_S3_A_ALIVE_AFTER=1; else echo SAW_S3_A_ALIVE_AFTER=0; fi",
        "if kill -0 $SAW_S3_B_PID 2>/res/kill.err; then echo SAW_S3_B_ALIVE_AFTER=1; else echo SAW_S3_B_ALIVE_AFTER=0; fi",
        "echo SAW_S3_A_RAW_MD5; /usr/bin/md5sum /res/s3_a.raw 2>&1 || true",
        "echo SAW_S3_B_RAW_MD5; /usr/bin/md5sum /res/s3_b.raw 2>&1 || true",
        "echo SAW_S3_A_OUT_BEGIN; cat /res/s3_a.out; echo SAW_S3_A_OUT_END",
        "echo SAW_S3_B_OUT_BEGIN; cat /res/s3_b.out; echo SAW_S3_B_OUT_END",
        "echo SAW_S3_END",

        "echo SAW_REPRO_DONE",
    ]

    wanted = [b"SAW_REPRO_DONE"]

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
