#!/usr/bin/env python3
"""Capture a short positive reference session from your player using the maintainers's pinned client."""
import argparse
from importlib.util import module_from_spec, spec_from_file_location
import json
from pathlib import Path
import hashlib
import shutil
import subprocess
import sys
import tempfile
from zipfile import ZipFile, ZIP_DEFLATED

from optical.media_check import compare

COMMIT = "40e146700bbc239fd949dd9916120f13ffdddba7"
CLIENT_SHA = "ea64e78f2549115d3f9e97201752b894fb17dd02a74c464277036b4e8edcd73e"


def get_client(path):
    if path:
        data = path.read_bytes()
    else:
        for candidate in [Path("tools/sacd_client.py"), Path("../sacd-reconstruct/tools/sacd_client.py")]:
            if candidate.is_file() and hashlib.sha256(candidate.read_bytes()).hexdigest() == CLIENT_SHA:
                return candidate.read_bytes()
        if not shutil.which("gh"):
            raise ValueError("Use --client /path/to/sacd-reconstruct/tools/sacd_client.py, or install and sign in to gh.")
        api = "repos/clintecker/sacd-reconstruct/contents/tools/sacd_client.py?ref=" + COMMIT
        data = subprocess.run(["gh", "api", "-H", "Accept: application/vnd.github.raw+json", api],
                              check=True, stdout=subprocess.PIPE).stdout
    if hashlib.sha256(data).hexdigest() != CLIENT_SHA:
        raise ValueError("Client hash differs from the pinned version. Omit --client to fetch it with gh.")
    return data


def main(args):
    client_data = get_client(args.client)
    args.out.mkdir(parents=True, exist_ok=False)
    metadata = dict(model=args.model, firmware=args.firmware, disc=args.disc_id,
                    client_sha256=CLIENT_SHA, client_commit=COMMIT)
    (args.out / "device.json").write_text(json.dumps(metadata, indent=2) + "\n")
    try:
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "sacd_client.py"
            path.write_bytes(client_data)
            spec = spec_from_file_location("sacd_capture", path)
            client = module_from_spec(spec)
            spec.loader.exec_module(client)
            # The CLI at this commit passes a successful dict to sys.exit().
            # Call the original capture function directly and check the evidence.
            options = argparse.Namespace(host=args.host, port=args.port, out=str(args.out),
                                         firmware=" ".join((args.model,args.firmware)), disc_id=args.disc_id,
                                         label="baseline", daemon_sha=None)
            client.cmd_capture(options)
        compare(argparse.Namespace(manifest=args.out / "manifest.json", iso=args.iso, against=None))
    finally:
        target = args.out / "send-this.zip"
        with ZipFile(target, "x", ZIP_DEFLATED) as z:
            for name in ["device.json", "capture.log", "manifest.json"]:
                source = args.out / name
                if source.is_file():
                    z.write(source, name)
        print(f"Return {target} (contains the available metadata and capture logs)")


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--host", default="192.0.2.10")
    p.add_argument("--port", default=2002, type=int)
    p.add_argument("--out", default=Path("bx510-firebird"), type=Path)
    p.add_argument("--model", default="unknown")
    p.add_argument("--firmware", default="unknown")
    p.add_argument("--disc-id", default="Firebird")
    p.add_argument("--client", type=Path)
    p.add_argument("--iso", type=Path, help="optional local full-disc 2048-byte-sector ISO")
    try:
        main(p.parse_args())
    except (OSError, ValueError, RuntimeError, KeyError, subprocess.CalledProcessError) as e:
        print(f"FAIL: {e}", file=sys.stderr)
        sys.exit(1)
