# Provenance

Where each input came from, and what is deliberately **not** redistributed here.

## Sony artefacts (referenced, not shipped)

| Artefact | Path on the player | Size | SHA-256 (prefix) |
|---|---|---|---|
| `sacd_extract_160` (original daemon) | `/usr/local/bin/sacd_extract_160` | 350,830 B | `0fdcefdb…` |
| `sacd_read.ko` (CPSA module, closed) | `/usr/local/lib/sacd_read.ko` | 97,805 B | see `evidence/bx510-guest/artifacts/` |
| Firmware | — | — | M15.R.0257 (BDP-BX510 family) |
| Rootfs squashfs | `/mnt/rootfs_normal` (mtd17) | 69 MB image | — |
| Kernel | mtd14/15 | Linux 2.6.35, armv6l | — |

Verify yours with:

```sh
shasum -a 256 /usr/local/bin/sacd_extract_160     # expect 0fdcefdb…
```

The full SHA-256 values are in `evidence/bx510-guest/artifacts/` manifests and in
the on-player runbooks.

## Upstream source we reconstruct from

The original daemon is a port of **sacd-ripper** at the v0.3.7 commit
(`de008ff`, 2012-12-29) with a new disc backend (CPSA via `sacd_read.ko`), a
merged server mode, and an ARM/glibc-2.9 toolchain build. The delta from v0.3.7 is
documented in `DELTA.md`:

- CPSA wrappers (`init_sacd`, `auth_sacd`, `read_sacd`, `decrypt_sacd`,
  `disc_sacd`, `uninit_sacd`) and the 64-bit-sector readers;
- `install_modules` / `remove_modules` (embedded `sacd_read.ko`, mknod + insmod);
- server mode: `server_loop`, `main_loop`, `client_thread`, `listener_thread`,
  `validate_stdin`, and the socket-backed protobuf stream;
- ID3/DSF/DST pieces as statically linked in the shipped image.

## Excluded from this repository (and why)

| Excluded | Reason |
|---|---|
| Sony binaries (daemon, `sacd_read.ko`, firmware) | proprietary; referenced by SHA-256 above |
| NAND images, QEMU disk fixtures (~150 MB) | regenerable via `tools/fixture_gen.py` |
| Disassembly dumps (`analysis/`) | regenerable via `objdump`; see `docs/REPRODUCE.md` |
| Third-party team packages that were handed to us | not ours to publish |
| Full gate logs (>1 MiB) | regenerable; summary documents are kept |

## Toolchain

- `gnuarm` 2009q3 (`arm-none-linux-gnueabi-gcc` 4.4.1, glibc 2.9) for the
  reconstruction, to match the shipped build's ABI.
- QEMU 9.2.4 with `emulator-kit/` for the `sony-bx510` machine model.
- Python 3 for the verification tooling.
