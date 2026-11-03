#!/usr/bin/env python3
"""BX510 Phase-0 probes, v2 (guest environment repaired).

P1: does sacd_extract_160 -S serve inside Sony's guest OS?
    Chain repaired from v1: /dev tmpfs (+null), /proc mounted, /tmp provided
    via the tmpredir.so LD_PRELOAD redirect (RO squashfs root has no /tmp;
    real players receive it from the initrd we cannot yet unpack).
    Observable: LISTEN on port 2002 (hex 07D2, state 0A) in /proc/net/tcp.
P2: does the REAL embedded sacd_read.ko insmod against the emulated MT8560?
    Observable: /proc/modules entry, the daemon's own log, and QEMU's
    unimplemented-MMIO log captured with -d unimp (the discovery instrument).
    LD_PRELOAD propagates through system(), so the daemon's own insmod runs.

v1 lessons encoded: the wanted marker must not appear verbatim in any
command text (the shell echoes commands and would trip observe early), and
artifacts must be copied out of the TemporaryDirectory before it vanishes.
"""
import argparse
import hashlib
import io
import json
import shutil
import tarfile
import tempfile
from pathlib import Path

from run import command
from smoke import observe

REFERENCE = "0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45"


def build_tar(reference: Path, shim: Path, bgstart: Path, stub: Path) -> bytes:
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w", format=tarfile.USTAR_FORMAT) as arc:
        elf = reference.read_bytes()
        if hashlib.sha256(elf).hexdigest() != REFERENCE:
            raise ValueError(f"unexpected SHA-256 for {reference}")
        entry = tarfile.TarInfo("original/sacd_extract_160")
        entry.size, entry.mode = len(elf), 0o755
        arc.addfile(entry, io.BytesIO(elf))
        for name, blob in (("shim/tmpredir.so", shim.read_bytes()),
                           ("shim/bgstart", bgstart.read_bytes()),
                           ("shim/osai_mini.ko", stub.read_bytes())):
            entry = tarfile.TarInfo(name)
            entry.size, entry.mode = len(blob), 0o755
            arc.addfile(entry, io.BytesIO(blob))
    return buf.getvalue()


def main():
    p = argparse.ArgumentParser(description=__doc__)
    for opt in ("qemu", "images", "reference", "shim", "bgstart", "stub"):
        p.add_argument("--" + opt, required=True, type=Path)
    p.add_argument("--timeout", type=float, default=300.0)
    p.add_argument("--log", type=Path)
    a = p.parse_args()

    images = a.images.resolve(strict=True)
    payload = build_tar(a.reference, a.shim, a.bgstart, a.stub)
    parts = json.loads((images / "manifest.json").read_text())["partitions"]
    part = next(x for x in parts if x["name"] == "fe_test_data")
    if part["records"] or part["offset"] != 0xe00000 or len(payload) > part["size"]:
        raise ValueError("fixture does not fit the expected unused partition")
    blocks = (len(payload) + 4095) // 4096

    commands = [
        "mount -t tmpfs tmpfs /res; /bin/mknod /res/test-bdev b 31 10; "
        "/bin/mkdir /res/tmp /res/dev /res/proc",
        f"/bin/dd if=/res/test-bdev bs=4096 count={blocks} 2>/res/dd.err | /bin/tar -xf - -C /res",
        "/bin/chmod 755 /res/original/sacd_extract_160 /res/shim/tmpredir.so",
        "mount -t proc proc /res/proc; echo P0_PROC=$?",
        "echo x > /res/zero",
        "echo P0_EXEC_BEGIN; ls -l /res/original /res/shim; echo P0_EXEC_END",
        "/bin/chmod 755 /res/shim/bgstart",
        "/sbin/insmod /res/shim/osai_mini.ko; echo P0_STUB=$?; cat /res/proc/modules",
        "echo P0_BDPDIR_BEGIN; ls -l /lib/modules/2.6.35/BDP/; echo P0_BDPDIR_END",

        "LD_PRELOAD=/res/shim/tmpredir.so /res/shim/bgstart "
        "/res/original/sacd_extract_160 -S",
        "sleep 20; echo P0_TCP_BEGIN; cat /res/proc/net/tcp; echo P0_TCP_END",
        "echo P0_MOD_BEGIN; cat /res/proc/modules; ls -l /res/dev; echo P0_MOD_END",
        "echo P0_OUT_BEGIN; cat /res/daemon.out; echo P0_OUT_END",
        'echo P0_F""INISHED',
    ]
    wanted = [b"P0_FINISHED"]

    with tempfile.TemporaryDirectory() as temp:
        nand = Path(temp) / "fixture.img"
        shutil.copyfile(images / "nand.img", nand)
        with nand.open("r+b") as f:
            f.seek(part["offset"])
            f.write(payload)
        argv = command(a.qemu.resolve(strict=True), images, "shell", nand)
        unimp = Path(temp) / "unimp.log"
        argv[1:1] = ["-d", "unimp", "-D", str(unimp)]
        log = observe(argv, commands, wanted, a.timeout, a.log)
        shutil.copyfile(unimp, "/tmp/p0v2-unimp.log")
        text = log.decode(errors="replace")
        print(text[-6000:])
        lines = [ln for ln in unimp.read_text(errors="replace").splitlines()
                 if "unimplemented" in ln]
        print(f"--- unimp: {len(lines)} lines ---")
        seen = {}
        for ln in lines:
            seen[ln] = seen.get(ln, 0) + 1
        for ln, count in sorted(seen.items()):
            print(f"{count:6d}  {ln}")


if __name__ == "__main__":
    main()
