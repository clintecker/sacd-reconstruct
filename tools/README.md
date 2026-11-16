# tools/ — what each thing is

The verification + harness toolkit. Everything here is driven through the
repository `Makefile` (the targets are the documented, gate-carrying entry
points); the table below is the file-level index. Generated docs that must
not drift from code: `docs/DAEMON-MAP.md` is regenerated from the linker map
by `daemon_map.py`.

## Verification core (the parity gates)

| File | Role |
|---|---|
| `fn_diff.py` | per-function normalised disassembly comparison vs the original binary |
| `pool_audit.py` | literal-pool content + load-site positional match |
| `sacd_parity.sh` | the whole-parity wrapper: fn_diff + pool_audit + ko-blob identity + regression mutants |
| `release_build.py` | the release-candidate build (reproduces the GNU 4.4.1 / glibc 2.9 link) |
| `release_verify.sh` | the 5-leg verify gate around the release build |
| `daemon_map.py` | regenerates `docs/DAEMON-MAP.md` from the linker map |
| `decode_errno.py` | deterministic errno decoding (never mental arithmetic) |

## Wire protocol

| File | Role |
|---|---|
| `sacd_client.py` | stdlib-only client: `capture` / `compare` / `selftest` |
| `sacdclient.c` | the same client in C (runs in the guest) |
| `qemu_rig.c` | the interposition shim that turns the daemon's device/module touches into disc-image reads (builds `sacd_rig.so`) |
| `rig_run.sh` / `rig_pull.sh` | run the qemu-user rig; pull + compare its manifests |
| `fakesacd_test_server.py` | fake daemon for the client selftest |
| `fixture_gen.py` | deterministic Scarlet Book fixture disc |

## Full-system emulation (the `sony-bx510` guest)

| File | Role |
|---|---|
| `bx510-fire.sh` | the guest fire loop: stage, boot, run, capture, grep verdicts |
| `bx510_gate_check.py` / `bx510_gate2.sh` / `bx510_gate3*.sh` / `bx510_gate4*` | the in-guest gate ladder (6-boot canonical, HDHOST interface, 5 GiB boundary battery) |
| `bx510_hdhost.c` | synthetic read-only host-image block device (QEMU device model) |
| `bx510_bdpvirt.c` | guest module virt: the bdpdrv block-device seam |
| `bx510_clidrive.c` / `bx510_guest_client.c` | kernel/user client harnesses for the in-guest read path |
| `bx510_tmpredir.c` | LD_PRELOAD path redirect (`/dev/sr0` -> elsewhere) |
| `bx510_gdb_rsp.py` | GDB remote-serial client for the rig |
| `bx510_bigimg_gen.py` | the 5 GiB boundary-sentinel image (sparse) |

## Level-1 cipher

| File | Role |
|---|---|
| `bx510_disc_cipher.py` | derive an encrypted-at-rest disc image (audio areas) |
| `bx510_cipher_check.py` | the 7 acceptance gates vs the oracle table |

## UI / HUD

| File | Role |
|---|---|
| `sacd_ui.c` | the client-leg console (milestone artifact, regression fixture; renders in the guest) |
| `ui_regress.py` | layout regression: scenes, goldens, invariants, animation, guest parity |
| `ui_layout_spec.json` | the layout contract (regions, palette, invariants) |
| `bx510_ui_render.py` / `bx510_ui_stage.sh` / `bx510_ui_shot.py` / `bx510_ui_build*.sh` | the ui-loop pipeline: render guest script, stage, fire, capture -> PNG/GIF + verdict |
| `sacd_ui_gate.py` / `sacd_ui_guest.sh` | guest-side UI gate helpers |
| `bx510_sacd_hud.c` | the cyberpunk HUD (DirectFB, pool-mmap render path) |
| `hud_build.sh` / `hud_anim.py` / `hud_scenarios.py` / `hud_push.py` | HUD build, animation, scenario telemetry, host-side UDP pusher |
| `hud_guest_run.sh` / `hud_guest_gate.py` | run + gate the HUD in the real guest |
| `bx510_fbdump.c` / `bx510_fbmd5.c` / `bx510_fbdraw.c` / `bx510_fbvirt.c`(+`.h`) | framebuffer dump/md5/draw + the MT85xx fbdev provider model |
| `bx510_cyberdraw.c` | the display-leg test pattern (self-authenticating evidence; see `evidence/bx510/display-payload/DISPLAY-SPEC.md`) |
| `bx510_fbmt85_repro.py` | the MT85xx vendor-contract run harness (rungs a–e) |
| `bx510_font_carve.py` / `bx510_font_decode.py` / `bx510_fontprobe.c` | Sony `/res/font.bin` decode chain |
| `bx510_hud_diff.py` | rig-render vs panel-photo SSIM gate (hardware leg) |

## Hardware lane (real player)

| File | Role |
|---|---|
| `sacd_hardware.sh` | the USB-stick/session driver: build stick, modes, baseline capture, pair capture |
| `bx510_hwmon.c` / `bx510_hwmon_analyze.py` | on-player hardware snapshots + deterministic analyzer |
| `bx510_pair_repro.py` | the pair-observer lane (silent-miss repro) |
| `bx510_hud_diff.py` | panel-photo vs render verification |

## Module / firmware analysis

| File | Role |
|---|---|
| `bx510_ko_symbol_classify.py` / `bx510_ko_classify_matrix.py` / `bx510_ko_disasm.py` | `.ko` symbol classification + reloc-aware disassembly |
| `bx510_vermagic_patch.py` / `bx510_bdpswap.py` | module-loading fixes (vermagic, symtab tail) |
| `bx510_osal_stub.c` / `bx510_stub_build.sh` | the OSAL stub for loading bdpdrv in the rig |
| `bx510_feboot.c` / `bx510_lo_up.c` / `bx510_sacdstat.c` / `bx510_mkfixture.c` / `bx510_bgstart*.c` | guest boot/fixture helpers |

## Guest fire driver

| File | Role |
|---|---|
| `bx510_bdpdrv_stub_probe.py` | the fire pipeline's guest driver: OSAL stub + bdpdrv insmod trace (staged by `bx510-fire.sh`) |

## Historical probes

One-shot probes, debugging instruments and lane-closing harnesses from the
rig-building phase live in `tools/archive/` (indexed there). They are part
of the negative-evidence record, not the reproduction path.

## Publishing pipeline

| File | Role |
|---|---|
| `public_tree.py` | assemble the public tree (include/exclude/scrub, deterministic, manifest-recorded) |
| `audit_public.py` | the public-readiness audit gate (run before every publish) |
| `public_publish.sh` | refresh the `public` branch (audit as a gate, then commit+push) |
| `sacd_sync_standalone.sh` | mirror the canonical tree into this standalone repo |
| `PUBLIC-SCAN-REPORT.md` | the scan methodology + findings from the last full audit |

## Tests

`test_*.py` are the unit gates (`make tests`); `sacd_ui_spec_dump.patch` is
the instrumentation used by the layout regression's compiled-spec check;
`third_party/` holds vendored code with its own notices.
