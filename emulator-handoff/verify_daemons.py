#!/usr/bin/env python3
"""Compare both pinned sacd_extract_160 binaries on the emulated player's userland."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import shutil
import tarfile
import tempfile

from run import command
from smoke import observe

REFERENCE = "0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45"
RELEASE = "e91720fbbbd592505bde6630843b0495ff82a93e40c0e427aaa70a081ff9ae22"
HELP_MD5 = "f6c27101912941479a1f2c400230cd39"


def test_archive(reference, release):
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w", format=tarfile.USTAR_FORMAT) as archive:
        for name, path, sha in [("original", reference, REFERENCE), ("release", release, RELEASE)]:
            elf = path.read_bytes()
            if hashlib.sha256(elf).hexdigest() != sha:
                raise ValueError(f"unexpected SHA-256 for {path}")
            entry = tarfile.TarInfo(f"{name}/sacd_extract_160")
            entry.size = len(elf)
            entry.mode = 0o755
            archive.addfile(entry, io.BytesIO(elf))
    return buf.getvalue()


def read_help(log, name):
    begin = f"BX510_{name}_BEGIN".encode()
    end = f"BX510_{name}_END".encode()
    raw = log.split(begin, 1)[1].split(end, 1)[0]
    return bytes.fromhex(raw.decode("ascii"))


def check(args):
    images = args.images.resolve(strict=True)
    payload = test_archive(args.reference, args.release)
    parts = json.loads((images / "manifest.json").read_text())["partitions"]
    part = next(p for p in parts if p["name"] == "fe_test_data")
    if part["records"] or part["offset"] != 0xe00000 or len(payload) > part["size"]:
        raise ValueError("fixture does not fit the expected unused partition")
    blocks = (len(payload) + 4095) // 4096
    commands = ["/bin/mount -t tmpfs tmpfs /res",
                "/bin/mknod /res/test-bdev b 31 10",
                f"/bin/dd if=/res/test-bdev bs=4096 count={blocks} 2>/res/dd.log | /bin/tar -xf - -C /res"]
    wanted = []
    for name, subdir in [("REFERENCE", "original"), ("RELEASE", "release")]:
        out = f"/res/{subdir}.out"
        commands.append(f"LD_BIND_NOW=1 /res/{subdir}/sacd_extract_160 --help >{out}; "
                        f"echo {name}_EXIT=$?")
        commands.append(f"printf 'BX510_%s\\n' {name}_BEGIN; "
                        f"/usr/bin/hexdump -v -e '1/1 \"%02x\"' {out}; "
                        f"printf '\\nBX510_%s\\n' {name}_END")
        wanted.extend([f"{name}_EXIT=0".encode(), f"BX510_{name}_END".encode()])
    with tempfile.TemporaryDirectory() as temp:
        nand = Path(temp) / "fixture.img"
        shutil.copyfile(images / "nand.img", nand)
        with nand.open("r+b") as f:
            f.seek(part["offset"])
            f.write(payload)
        guest = command(args.qemu.resolve(strict=True), images, "shell", nand)
        log = observe(guest, commands, wanted, args.timeout, args.log)
    original = read_help(log, "REFERENCE")
    release = read_help(log, "RELEASE")
    if original != release or hashlib.md5(original).hexdigest() != HELP_MD5:
        raise SystemExit("Guest stdout differs from the captured reference")
    print(f"PASS --help, {len(original)} identical stdout bytes, both exits 0, LD_BIND_NOW=1")
    print("stdout SHA-256", hashlib.sha256(original).hexdigest())


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    for opt in ("qemu", "images", "reference", "release"):
        p.add_argument("--" + opt, required=True, type=Path)
    p.add_argument("--log", type=Path)
    p.add_argument("--timeout", type=float, default=90)
    check(p.parse_args())
