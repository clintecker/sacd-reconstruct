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
import sys
import json
import shutil
import tarfile
import tempfile
from pathlib import Path

from run import command
from smoke import observe

REFERENCE = "0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45"
RELEASE = "e91720fbbbd592505bde6630843b0495ff82a93e40c0e427aaa70a081ff9ae22"


def build_tar(reference: Path, shim: Path, bgstart: Path, stub: Path,
              mkfixture: Path, gclient: Path, lo_up: Path,
              sacdstat: Path, role: str, hdmod=None) -> bytes:
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w", format=tarfile.USTAR_FORMAT) as arc:
        elf = reference.read_bytes()
        got = hashlib.sha256(elf).hexdigest()
        # role-pinned identity: the caller states WHICH binary this run
        # exercises, and only that binary's digest is accepted. Accepting
        # either digest let an accidental original-vs-original run pass
        # as a cross-binary comparison (team review finding).
        want = {"original": REFERENCE, "release": RELEASE}[role]
        if got != want:
            raise ValueError(f"role {role!r} requires SHA-256 {want}, "
                             f"got {got} for {reference}")
        entry = tarfile.TarInfo("original/sacd_extract_160")
        entry.size, entry.mode = len(elf), 0o755
        arc.addfile(entry, io.BytesIO(elf))
        for name, blob in (("shim/tmpredir.so", shim.read_bytes()),
                           ("shim/bgstart", bgstart.read_bytes()),
                           ("shim/bdpvirt.ko", stub.read_bytes()),
                           ("shim/mkfixture", mkfixture.read_bytes()),
                           ("shim/gclient", gclient.read_bytes()),
                           ("shim/lo_up", lo_up.read_bytes()),
                           ("shim/sacdstat", sacdstat.read_bytes()),
                           *([("shim/hdhost.ko", hdmod.read_bytes())]
                             if hdmod else [])):
            entry = tarfile.TarInfo(name)
            entry.size, entry.mode = len(blob), 0o755
            arc.addfile(entry, io.BytesIO(blob))
    return buf.getvalue()


def main():
    p = argparse.ArgumentParser(description=__doc__)
    for opt in ("qemu", "images", "reference", "shim", "bgstart", "stub",
                "mkfixture", "gclient", "lo_up", "sacdstat"):
        p.add_argument("--" + opt, required=True, type=Path)
    p.add_argument("--timeout", type=float, default=300.0)
    p.add_argument("--corrupt-toc", action="store_true",
                   help="malformed-TOC negative control: corrupt reserved06 "
                        "after mkfixture (both binaries must fail OPEN "
                        "identically; the gate refuses success-parity)")
    p.add_argument("--role", choices=("original", "release"), required=True,
                   help="which pinned binary this run exercises; the "
                        "reference's SHA-256 must equal that role's "
                        "digest exactly")
    p.add_argument("--hdhost", type=Path,
                   help="HDHOST: VM-side path to the read-only host image; "
                        "passed to QEMU as the sony-bx510 machine property "
                        "(device at 0x70020000; see docs/large-image-interface.md)")
    p.add_argument("--hdmod", type=Path,
                   help="HDHOST guest block-driver module (hdhost.ko) to "
                        "stage and load; enables the in-guest device "
                        "verification commands")
    p.add_argument("--rawdump", action="store_true",
                   help="dump the full both-direction raw capture "
                        "(gc-raw.bin + gc-tx.bin) through the UART as "
                        "hex, gzip-compressed when the guest has gzip "
                        "(md5 + sizes in-transcript; decode with "
                        "bx510_rawdecode.py)")
    p.add_argument("--log", type=Path)
    a = p.parse_args()

    images = a.images.resolve(strict=True)
    payload = build_tar(a.reference, a.shim, a.bgstart, a.stub,
                        a.mkfixture, a.gclient, a.lo_up, a.sacdstat,
                        a.role, a.hdmod)
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
        "/sbin/insmod /res/shim/bdpvirt.ko; echo P0_STUB=$?; cat /res/proc/modules",
        "echo P0_BDPDIR_BEGIN; ls -l /lib/modules/2.6.35/BDP/; echo P0_BDPDIR_END",

        "LD_PRELOAD=/res/shim/tmpredir.so /res/shim/bgstart "
        "/res/original/sacd_extract_160 -S",
        "sleep 8; echo P0_TCP_BEGIN; cat /res/proc/net/tcp; echo P0_TCP_END",
        "echo P0_MOD_BEGIN; cat /res/proc/modules; echo P0_MOD_END",
        "/bin/chmod 755 /res/shim/mkfixture /res/shim/gclient /res/shim/lo_up",
        "LD_PRELOAD= /res/shim/lo_up; echo P0_LO=$?",
        "LD_PRELOAD= /res/shim/mkfixture /res/dev/sr0 "
        + ("corrupt" if a.corrupt_toc else "") + "; echo P0_FIXT=$?",
        "dd if=/res/dev/sr0 bs=2048 skip=510 count=1 of=/res/t510 2>/res/e",
        "echo TDB; /usr/bin/hexdump -v -e '1/1 \"%02x\"' /res/t510 | head -c 352; echo",
        "LD_PRELOAD= /res/shim/gclient 127.0.0.1 2002 >/res/client.out 2>&1; "
        "echo P0_GC=$?",
        "echo P0_CLIENT_BEGIN; cat /res/client.out; echo P0_CLIENT_END",
        "echo P0_RL_BEGIN; cat /res/readlog; echo P0_RL_END",
    ] + ([
        # kernel printks share the UART console with the shell and can be
        # injected MID-LINE into the hexdump (observed: 32 hex chars glued
        # to "bdpvirt: TestUnitReadyLoop..."), costing the decode a 16-byte
        # line. Lower the console loglevel so module printks stay in the
        # kernel ring buffer but never reach the console during the dump.
        "echo 3 > /res/proc/sys/kernel/printk 2>/res/e; echo P0_LOGLEVEL=$?",
        "echo P0_RAWFULL_BEGIN",
        "wc -c /res/gc-raw.bin /res/gc-tx.bin; md5sum /res/gc-raw.bin /res/gc-tx.bin",
        "gzip -c /res/gc-raw.bin > /res/gc-raw.gz 2>/res/e && echo P0_GZ=yes || { echo P0_GZ=no; rm -f /res/gc-raw.gz; }",
        "if [ -f /res/gc-raw.gz ]; then hexdump -v -e '16/1 \"%02x\" \"\n\"' /res/gc-raw.gz | head -20000; else hexdump -v -e '16/1 \"%02x\" \"\n\"' /res/gc-raw.bin | head -20000; fi",
        "echo P0_TX_BEGIN; hexdump -v -e '16/1 \"%02x\" \"\n\"' /res/gc-tx.bin; echo P0_TX_END",
        "echo P0_RAWFULL_END",
    ] if a.rawdump else []) + [
        "echo P0_P128_BEGIN",
        "hexdump -v -e '16/1 \"%02x\" \"\n\"' /res/p128.bin | head -4",
        "echo P0_P128_END",
        "LD_PRELOAD= /res/shim/sacdstat; echo P0_STAT=$?",
        "dd if=/res/dev/sr0 bs=2048 skip=510 count=1 2>/res/e | md5sum",
        "echo P0_RAW_BEGIN; hexdump -v -e '1/1 \"%02x\"' /res/gc-raw.bin | head -c 48; echo",
        "dd if=/res/gc-raw.bin bs=1 skip=2040 count=16 2>/res/e | hexdump -v -e '1/1 \"%02x\"'; echo P0_RAW_END",
        "dd if=/res/dev/sr0 bs=2048 skip=510 count=1 2>/res/e | md5sum",
        "dd if=/res/dev/sr0 bs=2048 skip=600 count=1 2>/res/e | md5sum",
        "hexdump -v -e '16/1 \"%02x\" \"\n\"' /res/t510 | head -12",
        "echo P0_OUT_BEGIN; cat /res/daemon.out; echo P0_OUT_END",
        *([
            "/sbin/insmod /res/shim/hdhost.ko; echo P0_HD=$?",
            "grep hdhost /res/proc/devices; echo P0_HDDEV=$?",
            # the guest busybox has no tr/cut — split with pure shell
            "set -- $(grep hdhost /res/proc/devices); "
            "/bin/mknod /res/dev/hdhost b $1 0; echo P0_HDNODE=$?",
            "dd if=/res/dev/hdhost bs=2048 skip=0 count=1 2>/res/e | md5sum",
            "dd if=/res/dev/hdhost bs=2048 skip=10 count=1 2>/res/e | md5sum",
            "dd if=/res/dev/hdhost bs=2048 skip=5000 count=1 2>/res/e | md5sum",
            "dd if=/res/dev/hdhost bs=2048 skip=8190 count=2 2>/res/e | md5sum",
            "dd if=/res/dev/hdhost bs=2048 skip=8191 count=1 2>/res/e | md5sum",
            "dd if=/res/dev/hdhost bs=2048 skip=4000000 count=1 2>/res/e >/dev/null; echo P0_HDOOB=$?",
            "echo P0_HDDONE",
        ] if a.hdmod else []),
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
        if a.hdhost:
            try:
                i = argv.index("-M")
            except ValueError:
                i = argv.index("-machine")
            argv[i + 1] = f"sony-bx510,hdhost={a.hdhost.resolve()}"
        log = observe(argv, commands, wanted, a.timeout, a.log)
        # An expected negative protocol response lives INSIDE a completed
        # run (the client prints result=-1). A probe that never reaches
        # P0_FINISHED is an EXECUTION failure and must exit nonzero so
        # the runner does not mistake a dead boot for a valid capture
        # (team review: the blanket `|| true` concealed this class).
        if b"P0_FINISHED" not in log:
            print("PROBE FAILED: P0_FINISHED never appeared (boot/UART "
                  "failure); log preserved at " + str(a.log),
                  file=sys.stderr)
            sys.exit(1)
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
