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

Three optional stages extend the command list after the C95-C101 spine. Each is
its own flag and OFF by default, so an unflagged fire renders the C100/C101
command list byte-for-byte (comparability is the point, not a nicety):
  --odd-tail   cdrom.ko + sr_mod.ko + mknod /dev/sr0 (decode/daemon-wiring.md §2)
  --sacdread   the sacd_read.ko smoke stage (decode/sacdread-stage-plan.md §5)
  --daemon     sacd_extract_160 as the last stage (decode/daemon-wiring.md §2)

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

# bdpdrv's CPSA "OK" return: 0x68000000, POSITIVE and never 0 — a stage that
# tested == 0 would report a false FAIL (decode/sacdread-stage-plan.md §4.1).
SACDREAD_INIT_OK = "1744830464"


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


def odd_tail_commands() -> list[str]:
    """The ODD tail the C-run command list never had.

    Both modules ship in the guest rootfs — verified against the BDP dirent
    listing in a prior run (artifacts/p0v33-uart.log: cdrom.ko 85,276 B,
    sr_mod.ko 34,944 B under /lib/modules/2.6.35/BDP/) — so this is wiring
    only: no staging, no model change. sr_mod.ko registers a SCSI driver, so
    loading it AFTER libata has enumerated the device (C101: 'scsi 0:0:0:0:
    CD-ROM') is what makes sr0 attach (decode/read10-orchestration.md §6.2,
    decode/daemon-gate-experiments.md gate 06).
    """
    return [
        "echo ODD_TAIL_BEGIN",
        "insmod /lib/modules/2.6.35/BDP/cdrom.ko; echo CDROM_INSMOD=$?",
        "insmod /lib/modules/2.6.35/BDP/sr_mod.ko; echo SRMOD_INSMOD=$?",
        "mknod /dev/sr0 b 11 0; echo SR0_MKNOD=$?",
        "ls -l /dev/sr0; echo SR0_LS=$?",
        "echo ODD_TAIL_DONE",
    ]


def sacdread_commands(auth: str) -> list[str]:
    """The sacd_read.ko module stage (decode/sacdread-stage-plan.md §5).

    The smoke script owns insmod/mknod/rmmod AND the ordering safety rule —
    AUTH (0x40105302) and UNINIT (0x40105305) both dereference the instance
    handle, which is 0xFFFFFFFF until a successful INIT, so the script hard-
    gates them behind S07 (plan §3.4). The command list therefore only brackets
    it and lifts the one machine-readable marker: a second INIT here would hit
    the slot S10 re-connected and return 0xE8000006, so SACDREAD_INIT is
    derived from the script's own S07 line, never re-fired.
    """
    return [
        "echo SACDREAD_STAGE_BEGIN",
        f"echo SACDREAD_INIT_EXPECT={SACDREAD_INIT_OK}",
        "ls -l /res/shim/sacd_read.ko; echo SACDREAD_LS=$?",
        f"AUTH={auth} sh /res/shim/sacdread_smoke.sh > /res/sacdread.smoke "
        "2>&1; echo SACDREAD_SMOKE_RC=$?",
        "cat /res/sacdread.smoke; echo SACDREAD_SMOKE_OUT=$?",
        # same sed idiom the smoke script's ioctl_run uses for the helper's
        # 'result=' field — one spelling per concept. Always prints the marker:
        # NONE means S07 produced no result (so 'missing' can never be read as
        # 'passed').
        "V=$(sed -n '/^SMOKE S07 /s/.*result=\\(-*[0-9][0-9]*\\).*/\\1/p' "
        "/res/sacdread.smoke); echo SACDREAD_INIT=${V:-NONE}",
        "echo SACDREAD_STAGE_END",
    ]


def daemon_commands() -> list[str]:
    """The daemon stage (decode/daemon-wiring.md §2).

    Position, per §2's own constraint: emulator-kit/smoke.py ends the run as
    soon as the wanted STUB_DONE marker appears, so this block must precede
    it. The ODD tail lines §2 lists are NOT repeated here — they are the
    --odd-tail stage, which the gate's gate 06 needs to have run first. The
    explicit 0x40105305 is §5.1's ordering hazard: gate 12's 0x40105301 owns
    _au4CpsaInst[compid] in bdpdrv's .bss (rmmod does NOT free it), and the
    daemon's first DISC_OPEN calls the same Connect and gets 0xE8000006 on a
    busy slot — invisible in DAEMON_ORACLE, hence its own marker.
    """
    return [
        "echo DAEMON_STAGE_BEGIN",
        # /tmp is absent from the rootfs squashfs and / is squashfs-ro; the
        # daemon writes its embedded sacd_read.ko (97,805 B) to /tmp/XXXXXX
        # (decode/daemon-ioctl-side.md §3.1).
        "mount -t tmpfs tmpfs /tmp; echo TMPTMP=$?",
        # daemon_gate.sh runs under set -u and reads $HOME; init=/bin/sh has
        # no /etc/profile.
        "HOME=/; export HOME",
        # the second staging channel: the four daemon-stage files do not fit
        # fe_test_data uncompressed (§4.2), the nested tgz does (§4.3).
        "tar -xzf /res/shim/daemon_payload.tgz -C /res; echo DAEMON_TGZ=$?",
        "md5sum /res/shim/sacd_extract_160; echo DAEMON_MD5=$?",
        "sh /res/shim/daemon_gate.sh; echo DAEMON_GATE_RC=$?",
        "/res/shim/sacdgate 0x40105305 /dev/sacd_read; echo GATE_UNINIT=$?",
        # hand the install back to the daemon so D-1 is the daemon's own
        "rmmod sacd_read; echo PRE_RMMOD=$?",
        "rm -f /dev/sacd_read; echo PRE_RMNODE=$?",
        "PATH=/sbin:/usr/sbin:/bin:/usr/bin; export PATH",
        # -S only: the daemon has no device/model/port argv (§0.1), and stdin
        # must not be a tty or server_loop skips the poll and discards the log
        # (decode/daemon-ioctl-side.md §3.3).
        "cd /res/shim; ./sacd_extract_160 -S </dev/null >/res/daemon.out "
        "2>&1 & echo DAEMON_PID=$!",
        "sleep 6; echo DAEMON_SLEPT=$?",
        "ps | grep sacd_extract; echo DAEMON_PS=$?",
        "cat /res/proc/misc; echo DAEMON_MISC=$?",
        "grep -c sacd_read /res/proc/modules; echo DAEMON_MOD=$?",
        "cat /res/daemon.out; echo DAEMON_OUT=$?",
        # the oracle: one flush-per-second status line; grep -q, not -c (the
        # file is one line with embedded \r, so a count would say 1).
        "grep -q 'SACD Daemon 0.37 active' /res/daemon.out; "
        "echo DAEMON_ORACLE=$?",
        "echo DAEMON_STAGE_DONE",
    ]


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
    p.add_argument("--odd-tail", action="store_true",
                   help="ODD tail: insmod cdrom.ko + sr_mod.ko (both already in "
                        "the guest rootfs) then mknod /dev/sr0 b 11 0; the "
                        "daemon gate 06 and the C103 READ(10) ladder both need "
                        "it. Off by default so C100/C101 traces stay comparable "
                        "(decode/daemon-wiring.md §2)")
    p.add_argument("--sacdread", type=Path, default=None, metavar="KO",
                   help="host path to sacd_read.ko: staged as "
                        "shim/sacd_read.ko and drives the smoke stage — INIT "
                        "ioctl 0x40105301, success value 0x68000000 "
                        "(decode/sacdread-stage-plan.md); absent = stage not run")
    p.add_argument("--sacdread-smoke", type=Path, default=None, metavar="SH",
                   help="host path to decode/sacdread_smoke.sh, staged as "
                        "shim/sacdread_smoke.sh — required by --sacdread (it "
                        "is the only place the INIT/UNINIT ordering rule lives)")
    p.add_argument("--sacdgate", type=Path, default=None, metavar="ELF",
                   help="host path to the ARM sacdgate ioctl helper "
                        "(decode/sacd_gate_ioctl.c built on the VM with the era "
                        "toolchain), staged as shim/sacdgate — required by "
                        "--sacdread; --daemon gets its own copy inside the tgz")
    p.add_argument("--sacd-auth", default="1", choices=("0", "1"), metavar="0|1",
                   help="--sacdread: '0' skips S08 AUTH, which runs bdpdrv's "
                        "whole SACD bring-up self-test and costs up to ~35 s "
                        "when /dev/sr0 exists but answers nothing; default 1")
    p.add_argument("--daemon", type=Path, default=None, metavar="TGZ",
                   help="host path to the prebuilt daemon payload tgz "
                        "(sacd_extract_160 + sacd_read.ko + sacdgate + "
                        "daemon_gate.sh; recipe decode/daemon-wiring.md §4.3), "
                        "staged as shim/daemon_payload.tgz and drives the "
                        "daemon stage; absent = stage not run")
    p.add_argument("--print-commands", action="store_true",
                   help="dry run: render the guest command list and the staging "
                        "budget for this flag combination, then exit WITHOUT "
                        "launching QEMU (the payload is still built, so the "
                        "budget line is the fire's real arithmetic)")
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
    # The three stages' own inputs. Each carries a host path into the tar and
    # its identity into the meta, the same idiom --stubko/--stuba-ko use, so
    # nothing is invented: omitting a flag leaves its stage dark AND out of the
    # payload (the C100/C101 bytes are untouched).
    if a.sacdread is not None:
        missing = [flag for flag, value in (("--sacdgate", a.sacdgate),
                                            ("--sacdread-smoke", a.sacdread_smoke))
                   if value is None]
        if missing:
            raise SystemExit(
                f"--sacdread needs {', '.join(missing)}: the INIT proof runs "
                "through the sacdgate helper, and the smoke script is the only "
                "place the INIT-before-AUTH/UNINIT ordering rule lives")
    if a.sacdgate is not None:
        extra["shim/sacdgate"] = a.sacdgate.resolve(strict=True).read_bytes()
    if a.sacdread is not None:
        extra["shim/sacd_read.ko"] = a.sacdread.resolve(strict=True).read_bytes()
        extra["shim/sacdread_smoke.sh"] = \
            a.sacdread_smoke.resolve(strict=True).read_bytes()
    if a.daemon is not None:
        extra["shim/daemon_payload.tgz"] = a.daemon.resolve(strict=True).read_bytes()
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
        raise SystemExit(
            f"payload {len(payload)} B does not fit fe_test_data "
            f"{part['size']} B (over by {len(payload) - part['size']} B); "
            f"records={part['records']} — shrink a stage or move its files to "
            "the nested-tgz channel (decode/daemon-wiring.md §4.2)")
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
    ]
    # ── optional stages, fixed order, each independently flaggable ──────────
    # Everything above is the C95-C101 spine and stays byte-identical when no
    # stage flag is passed; the stages are appended rather than woven in, so a
    # transcript diff against C100/C101 is exactly the stage's own lines.
    # ODD tail before the smoke stage before the daemon: sr0 must exist before
    # anything opens it, and daemon_gate.sh's gate 06 keys on it.
    if a.odd_tail:
        commands += odd_tail_commands()
    if a.sacdread is not None:
        commands += sacdread_commands(a.sacd_auth)
    if a.daemon is not None:
        commands += daemon_commands()
    commands += [
        "echo STUB_DONE",
        # clean guest shutdown (C85 lesson): QEMU flushes its -D log on a
        # CLEAN exit only — SIGTERM/SIGINT from the probe lose the whole
        # trace (0-byte mmio artifacts). poweroff makes the kernel exit
        # QEMU properly, so the log lands even when the run hangs earlier.
        "/sbin/poweroff -f; echo POWEROFF_ISSUED",
    ]
    wanted = [b"STUB_DONE"]

    if a.print_commands:
        # Dry run: render the guest command list and the staging budget for
        # this flag combination, then exit before QEMU is even resolved. The
        # payload above is BUILT from the same files the fire would stage (and
        # the partition guard above already refused an over-budget one), so
        # the budget line is the fire's real arithmetic, not a second estimate.
        print("stages:", f"odd_tail={a.odd_tail}",
              f"sacdread={'-' if a.sacdread is None else a.sacdread.name}",
              f"sacd_auth={a.sacd_auth}",
              f"daemon={'-' if a.daemon is None else a.daemon.name}")
        print(f"payload: {len(payload)} B of {part['size']} B "
              f"({part['size'] - len(payload)} B free), "
              f"dd count={blocks} x 4096 B, {len(extra) + 2} tar members")
        for name, blob in extra.items():
            print(f"  member {name} {len(blob)} B")
        for i, cmd in enumerate(commands, 1):
            print(f"{i:3d}  {cmd}")
        return

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
        # the stage flags, recorded so the bundle is self-describing without the
        # fire line being remembered (probe-injection.md's design note). Each
        # id carries the host path AND the hash of what actually rode the tar.
        "stages": {
            "odd_tail": a.odd_tail,
            "sacdread": None if a.sacdread is None else {
                "host_path": str(a.sacdread.resolve()),
                "sha256": sha256(a.sacdread.resolve()),
                "size": a.sacdread.stat().st_size,
                "smoke_sha256": sha256(a.sacdread_smoke.resolve()),
                "auth": a.sacd_auth,
                "init_ok_value": int(SACDREAD_INIT_OK),
            },
            "daemon": None if a.daemon is None else {
                "host_path": str(a.daemon.resolve()),
                "sha256": sha256(a.daemon.resolve()),
                "size": a.daemon.stat().st_size,
            },
        },
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
