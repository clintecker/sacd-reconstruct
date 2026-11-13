#!/usr/bin/env python3
"""BX510 bdpdrv insmod trace with OSAL stub preloaded (STUB/INSTRUMENT).

Runs full-system QEMU in shell mode (init=/bin/sh), stages a tar payload
into the unused fe_test_data NAND partition (page 0 onward — which is ALSO
where the driver reads the FATB record, so --fatb-fixture restages that record
from inside the tar after extraction), then in-guest:
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


def build_tar(stubko: Path, stuba_ko: Path,
              extra: dict[str, bytes] | None = None) -> bytes:
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w", format=tarfile.USTAR_FORMAT) as arc:
        for name, path in (("shim/osal_stub.ko", stubko),
                           ("shim/osal_stub_a.ko", stuba_ko)):
            blob = path.read_bytes()
            entry = tarfile.TarInfo(name)
            entry.size, entry.mode = len(blob), 0o755
            arc.addfile(entry, io.BytesIO(blob))
        for name, blob in (extra or {}).items():
            entry = tarfile.TarInfo(name)
            # 0755: extras may include executables (Run C45: clicmd 0644
            # -> "Permission denied" in the guest).
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
    p.add_argument("--kscript", type=Path,
                   default=Path(__file__).resolve().parent / "kcheck.sh",
                   help="guest-side check script staged as shim/kcheck.sh "
                        "(Run C43 lesson: long one-liners get truncated by "
                        "the guest shell — multi-checks go through files)")
    p.add_argument("--extra-file", action="append", default=[],
                   metavar="NAME=PATH",
                   help="stage an additional file into shim/ (repeatable)")
    p.add_argument("--pre-file", action="append", default=[],
                   metavar="NAME=PATH",
                   help="stage an additional file into shim/ insmodded BEFORE "
                        "the stub/drvcli sequence (repeatable; guest path is "
                        "/res/shim/NAME) — e.g. the real SATA stack (C51: "
                        "libata.ko -> sata_mt85xx_mod.ko) so _fg_fe_bootup "
                        "comes from the real driver")
    p.add_argument("--clidrive-mode", default="", metavar="MODE",
                   help="module parameter for the clidrive shim: the guest "
                        "gets 'insmod /res/shim/bx510_clidrive.ko "
                        "clidrive_args=MODE' (e.g. PROBE_SEQ for the P0-P2 "
                        "ladder); empty = the default instrument path")
    p.add_argument("--fatb-fixture", type=Path, default=None,
                   help="FATB page-0 record (build_fe_tag_fixtures.py's "
                        "fe_test_data.bin): staged inside the tar as "
                        "shim/fatb.bin and written back to offset 0 of the "
                        "staging partition AFTER extraction — the driver reads "
                        "FATB from fe_test_data page 0 only, so a fixture "
                        "applied to the image beforehand is clobbered by the "
                        "tar stream (decode/nfi-logging.md)")
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
    kscript_bytes = a.kscript.read_bytes() if a.kscript.exists() else b""
    procc_path = a.kscript.parent / "procc.sh"
    procc_bytes = procc_path.read_bytes() if procc_path.exists() else b""
    extra = {"shim/kcheck.sh": kscript_bytes,
             "shim/procc.sh": procc_bytes}
    for spec in a.extra_file:
        name, _, path = spec.partition("=")
        if not name or not path:
            raise SystemExit(f"bad --extra-file {spec!r}; want NAME=PATH")
        extra[f"shim/{name}"] = Path(path).read_bytes()
    pre_files = []
    for spec in a.pre_file:
        name, _, path = spec.partition("=")
        if not name or not path:
            raise SystemExit(f"bad --pre-file {spec!r}; want NAME=PATH")
        extra[f"shim/{name}"] = Path(path).read_bytes()
        pre_files.append(name)
    fatb_blob = b""
    if a.fatb_fixture is not None:
        fatb_blob = a.fatb_fixture.resolve(strict=True).read_bytes()
        # mtdblock writes whole pages, so pad the record with erased (0xFF)
        # filler to a NAND page multiple; the record itself is untouched.
        fatb_blob += b"\xff" * (-len(fatb_blob) % 2048)
        extra["shim/fatb.bin"] = fatb_blob
    # decode §5: the clidrive shim is inert without its module parameter, and
    # insmod is the only place the parameter can travel — so the mode is
    # rendered here, next to the file that is staged, not guessed later.
    clidrive_opt = f" clidrive_args={a.clidrive_mode}" if a.clidrive_mode else ""
    payload = build_tar(stubko, stuba_ko, extra)
    parts = json.loads((images / "manifest.json").read_text())["partitions"]
    part = next(x for x in parts if x["name"] == "fe_test_data")
    if part["records"] or len(payload) > part["size"]:
        raise SystemExit("payload does not fit fe_test_data")
    blocks = (len(payload) + 4095) // 4096

    commands = [
        "mount -t tmpfs tmpfs /res; /bin/mknod /res/test-bdev b 31 10; /bin/mkdir -p /res/shim /res/proc",
        f"/bin/dd if=/res/test-bdev bs=4096 count={blocks} 2>/res/dd.err | /bin/tar -xf - -C /res",
    ]
    if fatb_blob:
        # The restage MUST follow the extraction: the tar stream starts at the
        # partition head, which is the only offset the driver's FATB reader
        # accepts, so the record rides inside the tar and is written back to
        # page 0 once the modules are safely in tmpfs.
        commands.append(
            f"/bin/dd if=/res/shim/fatb.bin of=/res/test-bdev bs=2048 "
            f"count={len(fatb_blob) // 2048} 2>/res/fatb.dd.err; "
            f"echo FATB_RESTAGE=$?")
    commands += [
        "mount -t proc proc /res/proc; echo STUB_PROC=$?",
        # bdpdrv opens /proc/... at the LITERAL path; shell mode lacks /proc.
        # ROOTPROC=255 every run (C51 finding): mount says ENOENT on /proc
        # while /res/proc mounts fine — inspect what /proc actually is.
        "ls -la / | head -20; echo ROOTLIST=$?",
        "ls -la /proc 2>&1 | head -5; echo PROCLS=$?",
        "mkdir -p /proc 2>&1; echo MKDIRPROC=$?",
        "mount -t proc proc /proc 2>&1; echo ROOTPROC=$?",
        # /dev: tmpfs over the (now-existing) squashfs /dev dir — the SATA
        # loader mknods /dev/mtdblockN for its firmware read (C54: mknod
        # failed on the ro squashfs even with the dir present).
        "mount -t tmpfs tmpfs /dev 2>&1; echo DEVTMP=$?",
        "mknod /dev/console c 5 1; mknod /dev/null c 1 3; mknod /dev/ttyMT0 c 204 66; echo DEVNODES=$?",
        "cat /proc/mtd 2>&1 | head -4; echo MTDPROC=$?",
        "mount 2>&1 | head -8; echo MOUNTLIST=$?",
        "echo STUB_BEGIN",
        "ls -l /res/shim; echo STUB_LS=$?",
        "md5sum /res/shim/osal_stub.ko; echo STUB_MD5=$?",
    ]
    # --pre-file modules load FIRST (rootfs-independent deps of the driver
    # stack, e.g. the real SATA HAL providing _fg_fe_bootup).
    for name in pre_files:
        commands.append(f"insmod /res/shim/{name}; echo PRE_{name}_RC=$?")
    commands += [
        "insmod /res/shim/osal_stub_a.ko; echo STUBA_INSMOD=$?",
        f"insmod {a.bdpdrv_guest.rsplit('/',1)[0]}/drvcli.ko; echo DRVCLI_INSMOD=$?",
        "insmod /res/shim/osal_stub.ko; echo STUB_INSMOD=$?",
        "grep osal_stub /res/proc/modules; echo STUB_MOD=$?",
        # feboot option A (feboot-marshal.md §4): the module forged
        # _fg_fe_bootup=1 and shadowed /proc/driver; dropped so bdpdrv reads
        # the REAL flag (its absence from a run is now true evidence).
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
        # SATA/CDROM stack loadability check — via staged script file
        "sh /res/shim/kcheck.sh; echo KEXP2_DONE",
        "sh /res/shim/procc.sh; echo PROCCHECK_DONE",
        "ls /res/proc/kallsyms; grep -c sata /res/proc/kallsyms; grep -c . /res/proc/kallsyms; echo KCUR_DONE",
        # CLI runtime channel (Run C45+): ioctl ABI 0xc0014502 -> x_cli_parser
        "/res/shim/clicmd help; echo CLI_EXEC_RC=$?",
        "sleep 2; echo CLI_DRAIN1",
        # Run C49: kernel-side driver — x_cli_set_mode(5) + x_cli_parser via
        # module param (cli output is SerPrintStr-polled UART + printk)
        f"echo CLIDRIVE_MODE={a.clidrive_mode or 'DEFAULT'}",
        f"insmod /res/shim/bx510_clidrive.ko{clidrive_opt}; echo CLIDRIVE_RC=$?",
        "sleep 3; echo CLI_DRAIN2",
        "echo STUB_DONE",
        # clean guest shutdown (C85 lesson): QEMU flushes its -D log on a
        # CLEAN exit only — SIGTERM/SIGINT from the probe lose the whole
        # trace (0-byte mmio artifacts). poweroff makes the kernel exit
        # QEMU properly, so the log lands even when the run hangs earlier.
        "/sbin/poweroff -f; echo POWEROFF_ISSUED",
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
        # -d flags accumulate as a comma list in ONE arg; a second -d arg
        # REPLACES the mask (C68 lesson: '-d unimp' + extra '-d guest_errors'
        # silently dropped unimp -> the trace lost every unimplemented line).
        argv[1:1] = ["-d", "unimp,guest_errors", "-D", str(unimp)]
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
        "clidrive_mode": a.clidrive_mode or "DEFAULT",
        "fe_test_data": {"offset": part["offset"], "size": part["size"], "payload_size": len(payload)},
        "fatb_fixture": ({"host_path": str(a.fatb_fixture.resolve()),
                          "sha256": sha256(a.fatb_fixture.resolve()),
                          "size": len(fatb_blob),
                          "restage_pages": len(fatb_blob) // 2048}
                         if fatb_blob else None),
        "terminal_marker": marker_ok,
    }
    a.meta.write_text(json.dumps(meta, indent=2, sort_keys=True) + "\n")
    if not marker_ok:
        raise SystemExit("probe incomplete: STUB_DONE marker never appeared (artifacts written)")


if __name__ == "__main__":
    main()
