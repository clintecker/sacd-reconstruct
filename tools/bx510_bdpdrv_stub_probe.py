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


def build_tar(stubko: Path, stuba_ko: Path) -> bytes:
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w", format=tarfile.USTAR_FORMAT) as arc:
        for name, path in (("shim/osal_stub.ko", stubko),
                           ("shim/osal_stub_a.ko", stuba_ko)):
            blob = path.read_bytes()
            entry = tarfile.TarInfo(name)
            entry.size, entry.mode = len(blob), 0o755
            arc.addfile(entry, io.BytesIO(blob))
    return buf.getvalue()


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--qemu", required=True, type=Path)
    p.add_argument("--images", required=True, type=Path)
    p.add_argument("--stubko", required=True, type=Path,
                   help="host path to the built osal stub module (part B)")
    p.add_argument("--stuba-ko", required=True, type=Path,
                   help="host path to the stub part-A provider module")
    p.add_argument("--bdpdrv-host", required=True, type=Path,
                   help="host path to bdpdrv.ko for hashing/pinning")
    p.add_argument("--bdpdrv-guest", required=True, type=str,
                   help="guest path to bdpdrv.ko to insmod")
    p.add_argument("--uart", required=True, type=Path)
    p.add_argument("--unimp", required=True, type=Path)
    p.add_argument("--meta", required=True, type=Path)
    p.add_argument("--timeout", type=float, default=120.0)
    p.add_argument("--qemu-extra", default="",
                   help="extra QEMU argv appended verbatim (e.g. '-s' for a "
                        "gdbserver on :1234 for post-mortem attach)")
    a = p.parse_args()

    images = a.images.resolve(strict=True)
    stubko = a.stubko.resolve(strict=True)
    bdpdrv_host = a.bdpdrv_host.resolve(strict=True)

    stuba_ko = a.stuba_ko.resolve(strict=True)
    payload = build_tar(stubko, stuba_ko)
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
        "insmod /res/shim/osal_stub_a.ko; echo STUBA_INSMOD=$?",
        f"insmod {a.bdpdrv_guest.rsplit('/',1)[0]}/drvcli.ko; echo DRVCLI_INSMOD=$?",
        "insmod /res/shim/osal_stub.ko; echo STUB_INSMOD=$?",
        "grep osal_stub /res/proc/modules; echo STUB_MOD=$?",
        f"insmod {a.bdpdrv_guest}; echo BDPDRV_INSMOD=$?",
        "grep bdpdrv /res/proc/modules; echo BDPDRV_MOD=$?",
        # CLI runtime channel (Run C35+): drvcli registers char major 244;
        # make the node and exercise the driver's real command tables
        "grep 244 /res/proc/devices; echo CLI_MAJOR=$?",
        "mknod /res/clidev c 244 0; echo CLI_MKNOD=$?",
        "ls -l /res/clidev; echo CLI_NODE=$?",
        "mknod /res/null c 1 3; echo CLI_NULLNODE=$?",
        "echo help > /res/clidev; echo CLI_HELP_SENT=$?",
        "cat /res/clidev > /res/cliout & sleep 3; echo CMD > /res/clidev 2>/dev/null; echo ver > /res/clidev; echo CLI_SENT=$?; sleep 2; head -c 3000 /res/cliout; echo CLI_READ_DONE",
        # post-load runtime-surface inventory (Run C31+)
        "cat /res/proc/devices; echo INVENTORY_DEVICES=$?",
        "cat /res/proc/misc; echo INVENTORY_MISC=$?",
        "ls -1 /dev 2>&1 | head -40; echo INVENTORY_DEV=$?",
        "cat /res/proc/partitions; echo INVENTORY_PART=$?",
        "grep -iE 'bdp|sacd' /res/proc/kallsyms | tail -8; echo INVENTORY_KSYM=$?",
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
        if a.qemu_extra:
            argv[1:1] = a.qemu_extra.split()
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
        "osal_stub_a": {
            "host_path": str(stuba_ko),
            "sha256": sha256(stuba_ko),
            "size": stuba_ko.stat().st_size,
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
