#!/usr/bin/env python3
"""BX510 bdpdrv insmod trace with OSAL stub preloaded (STUB/INSTRUMENT).

Runs full-system QEMU in shell mode (init=/bin/sh), stages a tar payload
into the unused fe_test_data NAND partition, then in-guest:
  - mounts proc to /res/proc
  - insmods the staged osal_stub.ko
  - insmods the rootfs bdpdrv.ko
Captures UART and QEMU -d unimp logs.

This is a deliberate instrumentation run, not reconstruction.
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


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build_tar(stubko: Path) -> bytes:
    buf = io.BytesIO()
    blob = stubko.read_bytes()
    with tarfile.open(fileobj=buf, mode="w", format=tarfile.USTAR_FORMAT) as arc:
        entry = tarfile.TarInfo("shim/osal_stub.ko")
        entry.size, entry.mode = len(blob), 0o755
        arc.addfile(entry, io.BytesIO(blob))
    return buf.getvalue()


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--qemu", required=True, type=Path)
    p.add_argument("--images", required=True, type=Path)
    p.add_argument("--stubko", required=True, type=Path,
                   help="host path to the built osal stub module")
    p.add_argument("--bdpdrv-host", required=True, type=Path,
                   help="host path to bdpdrv.ko for hashing/pinning")
    p.add_argument("--bdpdrv-guest", required=True, type=str,
                   help="guest path to bdpdrv.ko to insmod")
    p.add_argument("--uart", required=True, type=Path)
    p.add_argument("--unimp", required=True, type=Path)
    p.add_argument("--meta", required=True, type=Path)
    p.add_argument("--timeout", type=float, default=120.0)
    a = p.parse_args()

    images = a.images.resolve(strict=True)
    stubko = a.stubko.resolve(strict=True)
    bdpdrv_host = a.bdpdrv_host.resolve(strict=True)

    payload = build_tar(stubko)
    parts = json.loads((images / "manifest.json").read_text())["partitions"]
    part = next(x for x in parts if x["name"] == "fe_test_data")
    if part["records"] or len(payload) > part["size"]:
        raise SystemExit("payload does not fit fe_test_data")
    blocks = (len(payload) + 4095) // 4096

    commands = [
        "mount -t tmpfs tmpfs /res; /bin/mknod /res/test-bdev b 31 10; /bin/mkdir -p /res/shim /res/proc",
        f"/bin/dd if=/res/test-bdev bs=4096 count={blocks} 2>/res/dd.err | /bin/tar -xf - -C /res",
        "mount -t proc proc /res/proc; echo STUB_PROC=$?",
        "echo STUB_BEGIN",
        "ls -l /res/shim; echo STUB_LS=$?",
        "md5sum /res/shim/osal_stub.ko; echo STUB_MD5=$?",
        "insmod /res/shim/osal_stub.ko; echo STUB_INSMOD=$?",
        "grep osal_stub /res/proc/modules; echo STUB_MOD=$?",
        f"insmod {a.bdpdrv_guest}; echo BDPDRV_INSMOD=$?",
        "grep bdpdrv /res/proc/modules; echo BDPDRV_MOD=$?",
        "echo STUB_DONE",
    ]
    wanted = [b"STUB_DONE"]

    with tempfile.TemporaryDirectory() as temp:
        td = Path(temp)
        nand = td / "fixture.img"
        shutil.copyfile(images / "nand.img", nand)
        with nand.open("r+b") as f:
            f.seek(part["offset"])
            f.write(payload)
        argv = command(a.qemu.resolve(strict=True), images, "shell", nand)
        unimp = td / "unimp.log"
        argv[1:1] = ["-d", "unimp", "-D", str(unimp)]
        marker_ok = True
        try:
            observe(argv, commands, wanted, a.timeout, a.uart)
        except SystemExit:
            # smoke.observe raises when a wanted marker is missing; the UART
            # transcript is already written. Keep going so the MMIO/unimp
            # trace and meta still land as evidence (blocked/crashed init is
            # exactly the state we study).
            marker_ok = False
        shutil.copyfile(unimp, a.unimp)

    meta = {
        "ts_utc": __import__("datetime").datetime.utcnow().isoformat() + "Z",
        "qemu": str(a.qemu.resolve()),
        "images": str(images),
        "bdpdrv": {
            "host_path": str(bdpdrv_host),
            "guest_path": a.bdpdrv_guest,
            "sha256": sha256(bdpdrv_host),
            "size": bdpdrv_host.stat().st_size,
        },
        "osal_stub": {
            "host_path": str(stubko),
            "sha256": sha256(stubko),
            "size": stubko.stat().st_size,
        },
        "fe_test_data": {"offset": part["offset"], "size": part["size"], "payload_size": len(payload)},
        "terminal_marker": marker_ok,
    }
    a.meta.write_text(json.dumps(meta, indent=2, sort_keys=True) + "\n")
    if not marker_ok:
        raise SystemExit("probe incomplete: STUB_DONE marker never appeared (artifacts written)")


if __name__ == "__main__":
    main()
