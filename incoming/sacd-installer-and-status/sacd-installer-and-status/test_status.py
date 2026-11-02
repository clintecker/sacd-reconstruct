#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["pyelftools==0.33"]
# ///
"""Check exact headless daemon status bytes on unstripped ARM ET_EXEC images.

    uv run test_status.py --qemu qemu-arm-static --sysroot /path/to/libc ORIGINAL REBUILD

The bundled guest DSO bypasses the module installer, supplies the client/device
state and stops after one iteration. The ELF's server_loop, safe_fwprintf,
locking and the guest libc's actual wide formatting all run under QEMU.
"""
import argparse
import os
from pathlib import Path
import subprocess
import sys

from elftools.elf.elffile import ELFFile


def fixture_addresses(path: Path) -> list[str]:
    """Derive the two functions and two writable state slots from this ELF."""
    with path.open("rb") as file:
        elf = ELFFile(file)
        if (elf.elfclass, elf.little_endian, elf["e_machine"], elf["e_type"]) != (32, True, "EM_ARM", "ET_EXEC"):
            raise ValueError("expected a little-endian ARM32 ET_EXEC")
        table = elf.get_section_by_name(".symtab")
        if table is None:
            raise ValueError("unstripped symbol table required")
        result = []
        for name, kind in (("init","STT_FUNC"), ("server_loop","STT_FUNC"),
                           ("client_connected","STT_OBJECT"), ("exit_requested","STT_OBJECT")):
            syms = [s for s in table.get_symbol_by_name(name) or [] if s["st_info"]["type"] == kind
                    and isinstance(s["st_shndx"], int) and s["st_value"]]
            addresses = {s["st_value"] for s in syms}
            if len(addresses) != 1:
                raise ValueError(f"missing or ambiguous {name}")
            if kind == "STT_OBJECT" and any(s["st_size"] != 4 for s in syms):
                raise ValueError(f"unexpected size for {name}")
            result.append(format(addresses.pop(), "x"))
        return result


def check(path: Path, qemu: str, sysroot: Path, shim: Path) -> bool:
    addresses = fixture_addresses(path)
    # Apply LD_PRELOAD and eager binding to the guest using QEMU's -E option.
    # In particular, never preload the ARM library into the host Python or QEMU.
    env = {k:v for k,v in os.environ.items() if not k.startswith(("LD_", "QEMU_"))
           and k not in {"LOG_FILE", "LOG_MODULES"}}
    base = [qemu, "-cpu", "arm1176", "-L", str(sysroot), "-E", f"LD_PRELOAD={shim}",
            "-E", "LD_BIND_NOW=1", "-E", "LC_ALL=C", str(path), *addresses]
    passed = 0
    for disc_index, disc in enumerate(("Tray is empty", "Disc inserted", "SACD disc inserted")):
        for connected, client in enumerate(("none", "connected")):
            # The original includes a carriage return, fourteen spaces, and no newline.
            want = f"\rSACD Daemon 0.37 active. Client {client}. {disc}.".encode("ascii") + b" " * 14
            run = subprocess.run([*base, str(disc_index), str(connected)], env=env,
                                 stdin=subprocess.DEVNULL, capture_output=True, timeout=6)
            if run.returncode == 0 and run.stdout == want:
                passed += 1
            else:
                print(f"  {disc} / {client}: exit={run.returncode}\n    expected {want!r}\n    observed {run.stdout!r}")
                if run.stderr:
                    print(f"    stderr   {run.stderr!r}")
    print(f"{path.name}: {passed}/6 exact status lines", flush=True)
    return passed == 6


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--qemu", default="qemu-arm-static")
    p.add_argument("--sysroot", required=True, type=Path)
    p.add_argument("--shim", type=Path, default=Path(__file__).with_name("status_probe.so"))
    p.add_argument("elf", type=Path, nargs="+")
    args = p.parse_args()
    passed = True
    for path in args.elf:
        try:
            if not check(path.resolve(strict=True), args.qemu, args.sysroot.resolve(strict=True), args.shim.resolve(strict=True)):
                passed = False
        except (ValueError, OSError, subprocess.TimeoutExpired) as exc:
            print(f"{path}: {exc}", file=sys.stderr)
            passed = False
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
