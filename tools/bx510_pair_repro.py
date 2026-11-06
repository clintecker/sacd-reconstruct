#!/usr/bin/env python3
"""BX510 pair-observer guest reproduction (silent-miss repro harness).

Question: does bx510_pair.so (the LD_PRELOAD pair observer that never
fired on real hardware) write its 8,240-byte pair file when the REAL
embedded sacd_read.ko module + the REAL original daemon run inside the
QEMU Sony guest — the combination the observer was never tested against
before the hardware session?

One boot per invocation, parameterized:
  --pair-so none    control: daemon WITHOUT the observer. Proves the
                    2-sector reads at the chosen LSNs succeed at all
                    (harness + client sanity before any claim).
  --pair-so <path>  armed: daemon under LD_PRELOAD=tmpredir:<observer>
                    with BX510_PAIR_OUT/BX510_PAIR_LSN (+ optional
                    BX510_PAIR_LOG for the debug build). Proves the
                    pass-through still serves, then checks the pair
                    file and dumps its size + header bytes.

Guest flow is the proven bx510_phase0_probe.py chain (tmpfs /res, tmpredir
shim, bdpvirt stub module, daemon -S under bgstart, real embedded
sacd_read.ko insmod by the daemon itself, mkfixture, loopback client).
The probe file is NOT modified; this harness copies its machinery
(build_tar pattern, observe-driven UART, marker discipline).

Run from ~/bx510-emu/emulator on the lab VM (needs run.py + smoke.py +
../images), e.g.:

  python3 bx510_pair_repro.py --qemu work/build/qemu-system-arm \
      --images ../images --reference /home/aftermath/sacd-verify/original/sacd_extract_160 \
      --shim /tmp/tmpredir.so --bgstart /tmp/bgstart --stub /tmp/mod/bx510_bdpvirt.ko \
      --mkfixture /tmp/mkfixture --gclient /tmp/gclient --lo_up /tmp/lo_up \
      --pair-so /tmp/pairrepro/bx510_pair.so --arm-lsn 80000 --read-lsns 80000,600 \
      --pair-log --timeout 900 --log /tmp/pairrepro/runB.log
"""
import argparse
import hashlib
import io
import json
import shutil
import sys
import tarfile
import tempfile
from pathlib import Path

from run import command
from smoke import observe

REFERENCE = "0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45"
assert len(REFERENCE) == 64


def build_tar(reference: Path, shim: Path, bgstart: Path, stub: Path,
              mkfixture: Path, gclient: Path, lo_up: Path,
              pair_so: str) -> bytes:
    """Stage the pinned original daemon + guest shims (+ observer)."""
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w", format=tarfile.USTAR_FORMAT) as arc:
        elf = reference.read_bytes()
        if hashlib.sha256(elf).hexdigest() != REFERENCE:
            raise ValueError("reference SHA-256 is not the pinned original")
        entry = tarfile.TarInfo("original/sacd_extract_160")
        entry.size, entry.mode = len(elf), 0o755
        arc.addfile(entry, io.BytesIO(elf))
        members = (("shim/tmpredir.so", shim), ("shim/bgstart", bgstart),
                   ("shim/bdpvirt.ko", stub), ("shim/mkfixture", mkfixture),
                   ("shim/gclient", gclient), ("shim/lo_up", lo_up))
        for name, blob in members:
            data = blob.read_bytes()
            entry = tarfile.TarInfo(name)
            entry.size, entry.mode = len(data), 0o755
            arc.addfile(entry, io.BytesIO(data))
        if pair_so and pair_so != "none":
            data = Path(pair_so).read_bytes()
            entry = tarfile.TarInfo("pair/bx510_pair.so")
            entry.size, entry.mode = len(data), 0o755
            arc.addfile(entry, io.BytesIO(data))
    return buf.getvalue()


def main():
    p = argparse.ArgumentParser(description=__doc__)
    for opt in ("qemu", "images", "reference", "shim", "bgstart", "stub",
                "mkfixture", "gclient", "lo_up", "log"):
        p.add_argument("--" + opt, required=True, type=Path)
    p.add_argument("--pair-so", required=True,
                   help="'none' for the no-observer control, or a VM path "
                        "to the observer .so to stage and preload")
    p.add_argument("--arm-lsn", type=int, default=80000,
                   help="BX510_PAIR_LSN (decimal). Default 80000 = inside "
                        "the fixture's encrypted track range, where the "
                        "daemon issues SACD_IOC_DECRYPT after the read")
    p.add_argument("--read-lsns", default="80000,600",
                   help="comma-separated decimal LSNs for the client's "
                        "count-2 reads. 80000: encrypted range (decrypt "
                        "fires). 600: the fixture's area-TOC LSN — the "
                        "hardware session's armed LSN, an UNENCRYPTED "
                        "region where the daemon is expected to skip "
                        "DECRYPT entirely")
    p.add_argument("--pair-log", action="store_true",
                   help="also set BX510_PAIR_LOG=/res/pairlog (debug "
                        "observer builds) and dump it")
    p.add_argument("--timeout", type=float, default=900.0)
    a = p.parse_args()

    read_lsns = [int(x) for x in a.read_lsns.split(",") if x.strip()]
    images = a.images.resolve(strict=True)
    payload = build_tar(a.reference, a.shim, a.bgstart, a.stub,
                         a.mkfixture, a.gclient, a.lo_up, a.pair_so)
    parts = json.loads((images / "manifest.json").read_text())["partitions"]
    part = next(x for x in parts if x["name"] == "fe_test_data")
    if part["records"] or part["offset"] != 0xe00000 or len(payload) > part["size"]:
        raise ValueError("fixture does not fit the expected unused partition")
    blocks = (len(payload) + 4095) // 4096
    armed = a.pair_so != "none"

    daemon_line = ("LD_PRELOAD=/res/shim/tmpredir.so /res/shim/bgstart "
                   "/res/original/sacd_extract_160 -S")
    if armed:
        daemon_line = (
            "BX510_PAIR_OUT=/res/pairtest BX510_PAIR_LSN=%d %s"
            "LD_PRELOAD=/res/shim/tmpredir.so:/res/pair/bx510_pair.so "
            "/res/shim/bgstart /res/original/sacd_extract_160 -S"
            % (a.arm_lsn,
               "BX510_PAIR_LOG=/res/pairlog " if a.pair_log else ""))

    commands = [
        "mount -t tmpfs tmpfs /res; /bin/mknod /res/test-bdev b 31 10; "
        "/bin/mkdir /res/tmp /res/dev /res/proc",
        f"/bin/dd if=/res/test-bdev bs=4096 count={blocks} 2>/res/dd.err | /bin/tar -xf - -C /res",
        "/bin/chmod 755 /res/original/sacd_extract_160 /res/shim/tmpredir.so "
        "/res/shim/bgstart /res/shim/mkfixture /res/shim/gclient /res/shim/lo_up",
        "mount -t proc proc /res/proc; echo PR_PROC=$?",
        "echo x > /res/zero",
        "echo PR_EXEC_BEGIN; ls -l /res/original /res/shim /res/pair; echo PR_EXEC_END",
        "/sbin/insmod /res/shim/bdpvirt.ko; echo PR_STUB=$?; cat /res/proc/modules",
        daemon_line,
        "sleep 8; echo PR_TCP_BEGIN; cat /res/proc/net/tcp; echo PR_TCP_END",
        "echo PR_MOD_BEGIN; cat /res/proc/modules; echo PR_MOD_END",
        "LD_PRELOAD= /res/shim/lo_up; echo PR_LO=$?",
        "LD_PRELOAD= /res/shim/mkfixture /res/dev/sr0; echo PR_FIXT=$?",
        "LD_PRELOAD= /res/shim/gclient 127.0.0.1 2002 pair "
        + " ".join(str(x) for x in read_lsns)
        + " >/res/client.out 2>&1; echo PR_GC=$?",
        "echo PR_CLIENT_BEGIN; cat /res/client.out; echo PR_CLIENT_END",
        "echo PR_RL_BEGIN; cat /res/readlog; echo PR_RL_END",
        "if [ -f /res/pairtest ]; then echo PR_PAIR_PRESENT; ls -l /res/pairtest; "
        "dd if=/res/pairtest bs=1 count=16 2>/res/e | /usr/bin/hexdump -v -e '1/1 \"%02x\"'; echo; "
        "else echo PR_PAIR_ABSENT; fi",
        "if [ -f /res/pairlog ]; then echo PR_LOG_BEGIN; cat /res/pairlog; "
        "echo PR_LOG_END; else echo PR_LOG_ABSENT; fi",
        "echo PR_OUT_BEGIN; cat /res/daemon.out; echo PR_OUT_END",
        'echo PAIR_R""EPRO_DONE',
    ]
    wanted = [b"PAIR_REPRO_DONE"]

    with tempfile.TemporaryDirectory() as temp:
        nand = Path(temp) / "fixture.img"
        shutil.copyfile(images / "nand.img", nand)
        with nand.open("r+b") as f:
            f.seek(part["offset"])
            f.write(payload)
        argv = command(a.qemu.resolve(strict=True), images, "shell", nand)
        log = observe(argv, commands, wanted, a.timeout, a.log)
        if b"PAIR_REPRO_DONE" not in log:
            print("REPRO FAILED: PAIR_REPRO_DONE never appeared (boot/UART "
                  "failure); log preserved at " + str(a.log),
                  file=sys.stderr)
            sys.exit(1)
        text = log.decode(errors="replace")
        print(text[-8000:])


if __name__ == "__main__":
    main()
