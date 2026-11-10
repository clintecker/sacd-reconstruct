# BX510 guest: bdpdrv.ko Phase A trace run (MMIO + insmod verdict)

Date: 2026-11-10

## Goal
Capture a QEMU-side MMIO trace for Sony’s real display driver (`bdpdrv.ko`) during `insmod`, and record whether the module’s `module_init` reaches probe (success or failure).

House-rule note: this writeup labels **VERIFIED** vs **INFERRED**; raw evidence files live alongside this markdown.

## Provenance / staging

### bdpdrv.ko hash pin
**VERIFIED** (VM host, `/tmp/rootfs` copy):

- Path: `VM:/tmp/rootfs/lib/modules/2.6.35/BDP/bdpdrv.ko`
- Size: `8122068` bytes
- SHA-256: `6604f6cd6c204c3399ac047f389f47162b06a3f6576159f21b4e8aaf3a72cf54`
- MD5: `fd3542eeeb6881bcd715fc1b83519ba3`

**VERIFIED** (in-guest file MD5): the guest’s `/lib/modules/2.6.35/BDP/bdpdrv.ko` reports the same MD5 (`fd3542…`).

### fe_test_data tar-through staging
The previously-proven `fe_test_data` staging partition is only **1 MiB**; `bdpdrv.ko` is ~8.1 MiB, so staging the module itself via that path is not possible.

**Decision (supervisor-approved):** use the in-guest `bdpdrv.ko` already present in the rootfs (`/lib/modules/2.6.35/BDP/bdpdrv.ko`), and stage only small helper files via `fe_test_data`.

Staged helper(s):
- `undef.syms` (the 260 undefined symbols from a Mac-side preflight extract)

## Preflight / dependency check

### Mac-side undefined symbol list
**VERIFIED:** extracted `bdpdrv.ko` undefined symbols list length = **260**.

- File: `bdpdrv.undef.syms`

### Guest kernel export check (/proc/kallsyms)
We checked each undefined symbol name against the guest’s `/proc/kallsyms` (as a proxy for “resolvable by insmod”).

**VERIFIED:** missing from `/proc/kallsyms` before loading any deps: **153** symbols.

- File: `missing.pre.syms`

Examples (first lines from `missing.pre.syms`):
- `SYS_Printf`, `UTIL_Printf`, `Printf`, `Assert`
- `BIM_*`, `CKGEN_*`, `HAL_*`
- many `x_*` vendor OS abstraction symbols (`x_mem_*`, `x_thread_*`, `x_sema_*`, `x_rm_*`, ...)

### Attempted dependency module loads
We attempted to `insmod` likely prerequisite modules (based on a host-side symbol-provider scan across `BDP/*.ko`).

**VERIFIED:** all of these failed to load with *unknown symbol* errors:
- `osai.ko`
- `kmem.ko`
- `rm.ko`
- `drvcli.ko`
- `cbagent.ko`

See UART log for the exact unknown-symbol lists per module.

- Raw UART transcript: `bdpdrv-trace3.uart.log`

After these attempts:

**VERIFIED:** missing-from-kallsyms count remained **153** (unchanged).

- File: `missing.post.syms`

## insmod verdict

**VERIFIED:** `insmod /lib/modules/2.6.35/BDP/bdpdrv.ko` failed.

- Return code marker in UART: `PR_INSMOD_BDPDRV=2`
- `dmesg` / console contained extensive `bdpdrv: Unknown symbol ...` lines.

Interpretation:
- **VERIFIED:** `module_init` did **not** reach probe/MMIO-driving code; failure occurs at module load/link due to unresolved symbols.
- **INFERRED:** resolving this likely requires additional Sony kernel exports (or additional kernel modules not present/bootstrapped in this `init=/bin/sh` boot path).

## MMIO trace (QEMU LOG_UNIMP)

Trace source:
- QEMU started with `-d unimp -D /tmp/bdpdrv-trace3.mmio.log`.
- These are **unimplemented** accesses within the BX510 peripheral MMIO window (see `emulator-kit/sony-bx510.c`’s `qemu_log_mask(LOG_UNIMP, ...)`).

Important constraint:
- **VERIFIED:** because `bdpdrv.ko` failed to load, this MMIO log is **not** attributable to `bdpdrv`’s probe path; it is just the unimplemented-access stream observed during the boot + insmod attempts.

### Touched ranges summary
**VERIFIED:** 29 unimplemented MMIO accesses across 4 pages (4 KiB each):

| guest-phys page | count | notes |
|---|---:|---|
| `0x70000000` | 3 | 32-bit read @+0x70/+0x7c and write @+0x70 |
| `0x70008000` | 8 | writes around +0x100/+0x154..+0x15c, read @+0x730 |
| `0x7000c000` | 1 | single write @+0x1c |
| `0x70024000` | 17 | reads/writes at +0x80/+0x88/+0xc4/+0x144/+0x148/+0x188/+0x1cc |

### Per-range access tables (in trace order)

#### Range: `0x70000000` (page)
| # | dir | addr | +off | size | value |
|---:|---|---|---:|---:|---|
| 14 | R | 0x7000007c | 0x07c | 4 | — |
| 26 | R | 0x70000070 | 0x070 | 4 | — |
| 27 | W | 0x70000070 | 0x070 | 4 | 0x50000 |

#### Range: `0x70008000` (page)
| # | dir | addr | +off | size | value |
|---:|---|---|---:|---:|---|
| 11 | W | 0x70008158 | 0x158 | 4 | 0x0 |
| 12 | W | 0x7000815c | 0x15c | 4 | 0xffffffff |
| 13 | W | 0x70008154 | 0x154 | 4 | 0xffffffff |
| 15 | W | 0x70008100 | 0x100 | 4 | 0xc047ec40 |
| 16 | W | 0x70008100 | 0x100 | 4 | 0xc047ec40 |
| 17 | R | 0x70008730 | 0x730 | 4 | — |
| 24 | R | 0x7000811c | 0x11c | 4 | — |
| 25 | W | 0x7000811c | 0x11c | 4 | 0x0 |

#### Range: `0x7000c000` (page)
| # | dir | addr | +off | size | value |
|---:|---|---|---:|---:|---|
| 18 | W | 0x7000c01c | 0x01c | 4 | 0x100 |

#### Range: `0x70024000` (page)
| # | dir | addr | +off | size | value |
|---:|---|---|---:|---:|---|
| 01 | R | 0x70024188 | 0x188 | 4 | — |
| 02 | W | 0x70024188 | 0x188 | 4 | 0x45 |
| 03 | R | 0x70024144 | 0x144 | 4 | — |
| 04 | W | 0x70024144 | 0x144 | 4 | 0x100 |
| 05 | W | 0x700241cc | 0x1cc | 4 | 0x4 |
| 06 | R | 0x700241cc | 0x1cc | 4 | — |
| 07 | W | 0x70024144 | 0x144 | 4 | 0x0 |
| 08 | W | 0x70024148 | 0x148 | 4 | 0xffffffff |
| 09 | W | 0x70024144 | 0x144 | 4 | 0x0 |
| 10 | W | 0x70024080 | 0x080 | 4 | 0x0 |
| 19 | R | 0x70024088 | 0x088 | 4 | — |
| 20 | R | 0x700240c4 | 0x0c4 | 4 | — |
| 21 | W | 0x700240c4 | 0x0c4 | 4 | 0x0 |
| 22 | R | 0x70024080 | 0x080 | 4 | — |
| 23 | W | 0x70024080 | 0x080 | 4 | 0x0 |
| 28 | R | 0x70024188 | 0x188 | 4 | — |
| 29 | W | 0x70024188 | 0x188 | 4 | 0x0 |

## Evidence files (this folder)

- `trace-run.md` (this document)
- `bdpdrv-trace3.uart.log` — UART transcript (boot + staging + symbol checks + insmod attempts)
- `bdpdrv-trace3.mmio.log` — QEMU `-d unimp` output
- `bdpdrv-trace3.meta.json` — run metadata (paths, hashes)
- `bdpdrv.undef.syms` — 260 undefined symbol names from the module (Mac-side extract)
- `missing.pre.syms` — 153 undefined symbols missing from `/proc/kallsyms` before dep loads
- `missing.post.syms` — same check after attempted dep loads (unchanged)
- `bdpdrv-symprov.txt` — host-side scan: which `BDP/*.ko` define which bdpdrv undefined symbols

## Phase B status
Not attempted.

Rationale: **VERIFIED** module load fails before reaching probe, so there is no probe path to decode yet. The immediate blocker is resolving/understanding the missing exported symbols / required bootstrap modules.
