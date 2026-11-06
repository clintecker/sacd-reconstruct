# emulator-kit — the LIVE BX510 emulator kit state (tracked, single source of truth)

The `emulator-handoff/` directory is the immutable original handoff.
This directory is the WORKING state of the VM kit at
`~/bx510-emu/emulator`: every file here is staged to the VM by the
`sacd-kit-stage` make target before any QEMU rebuild, and the VM copies
are disposable. Differences from the handoff are intentional and
documented in the sacd commit history:

- `sony-bx510.c`: HDHOST machine wiring (the `hdhost` machine property,
  device state, and init call; design in
  `../docs/large-image-interface.md`).
- `mt8560-hdhost.c/.h`: the HDHOST read-only MMIO block device.
- `qemu-integration.patch`, `build.sh`: meson line + kit copy list
  extended for the HDHOST files.
- `mt8560-nfi.c/.h`, `run.py`, `smoke.py`: current working copies
  (kept tracked so the kit can be rebuilt from scratch from this repo
  alone; they may incorporate post-handoff fixes by the emulator team).

Rebuild QEMU on the VM from this state: `make sacd-hdhost-qemu`.
