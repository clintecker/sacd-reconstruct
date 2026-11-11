# BX510 guest: bdpdrv.ko OSAL stub instrumentation run (STUB/INSTRUMENT)

Date: 2026-11-11

## Goal
Get Sony’s real display driver (`bdpdrv.ko`) to load far enough to execute its `module_init`/probe path so we can capture a QEMU-side MMIO trace (`-d unimp`).

This is a **DELIBERATE INSTRUMENT**: we load a synthetic module (`bx510_osal_stub.ko`) that **exports placeholder symbols** solely to satisfy `bdpdrv.ko`’s unresolved imports.

- **STUB / INSTRUMENT (VERIFIED):** the stub contains fake exports and fake implementations.
- **NOT reconstruction (VERIFIED):** nothing here is an attempt to reproduce Sony OSAL behavior.

House-rule note: this report labels **VERIFIED** vs **INFERRED**. Raw evidence files are listed below.

## Provenance / pinning

### bdpdrv.ko
**VERIFIED** (host-side copy from read-only rootfs at `VM:/tmp/rootfs`):

- Path: `VM:/tmp/rootfs/lib/modules/2.6.35/BDP/bdpdrv.ko`
- Size: `8122068`
- SHA-256: `6604f6cd6c204c3399ac047f389f47162b06a3f6576159f21b4e8aaf3a72cf54`

### BDP module export set (for “covered by sibling modules” accounting)
We enumerated **exported** symbols from all `BDP/*.ko` in the rootfs by scanning for `__ksymtab_*` / `__ksymtab_gpl_*` entries.

**VERIFIED:**
- Output: `bdp_exports.syms`
- Lines: `1397`
- SHA-256: `3b7f047d223f286ab3aa367124ddd1a8c943c32427f3f8235631dc78d1deb165`

**Note (VERIFIED):** This **supersedes** an earlier plain-`nm` “T symbol” provider scan. The kernel module loader resolves against `__ksymtab` exports; raw global `T` symbols that are not exported are not linkable by `insmod`.

### Missing symbol set / “54 vs 73” recomputation
Input list:
- `missing.pre.syms` — symbols missing from the kernel’s `/proc/kallsyms` prior to loading any deps.

**VERIFIED:**
- `missing.pre.syms` count: `153`
- Covered by BDP `__ksymtab` exports: `99` (`missing.pre.covered_by_bdp_ksymtab.syms`)
- **NOT** covered by BDP `__ksymtab` exports: `54` (`missing.pre.not_covered_by_bdp_ksymtab.syms`)

## Stub module implementation (bx510_osal_stub.ko)

Source (VERIFIED): `tools/bx510_osal_stub.c`

Design constraints (VERIFIED):
- Exports **every** symbol from `missing.pre.syms` via `EXPORT_SYMBOL`.
- Many functions are generic success/no-op stubs.
- A few high-traffic primitives are implemented:
  - `x_mem_alloc/free/calloc/realloc`, `x_memcpy/memset/strlen/...`
  - `HalCriticalStart/End`, `x_crit_start/end`
  - printing wrappers (`Printf`, `SYS_Printf`, `UTIL_Printf`, `vdbg_printf`) are guarded against NULL format strings.
- Every stub emits a **printk-once** marker: `[OSAL_STUB] <sym> called`.

## Probe method (VERIFIED)

We used a small VM-local probe runner (`/tmp/bx510_bdpdrv_stub_probe.py`) that follows the same discipline as `bx510_phase0_probe.py`:

- Writes a tar payload containing `shim/osal_stub.ko` into the unused NAND partition `fe_test_data` (offset and size from `images/manifest.json`).
- Boots QEMU in `shell` mode (`init=/bin/sh`).
- In-guest commands:
  1. mount tmpfs `/res`
  2. `dd` the staged payload from `b 31 10` into `/res` and extract
  3. mount proc at `/res/proc`
  4. `insmod /res/shim/osal_stub.ko`
  5. `insmod /lib/modules/2.6.35/BDP/bdpdrv.ko`
- Captures UART transcript and QEMU `-d unimp` output.

## Results

### Run A: first stub build (crashed in vdbg_printf)
Evidence:
- UART: `bdpdrv-stub-20261111-033848.uart.log` (12611 bytes, sha256 `92f5094e…`)
- MMIO: `bdpdrv-stub-20261111-033848.mmio-unimp.log` (31 unimp lines)
- Meta: `bdpdrv-stub-20261111-033848.meta.json`

Stub identity (VERIFIED from meta):
- `bx510_osal_stub.ko` sha256 `58b53617f8bbc71617410009a9c08ed1b735e1aeb7398f0e5dc3a1297653f43e`

Outcome (VERIFIED):
- `bdpdrv.ko` **loaded** (no `Unknown symbol` lines).
- `insmod` returned `139` due to a kernel Oops triggered by our initial `vdbg_printf` implementation calling `vprintk()` with a NULL format string.

Stub calls observed (VERIFIED; printk-once markers):
- `CKGEN_AgtOffClk`, `SYS_Printf`, `vdbg_printf`, `x_mem_alloc`, `x_sema_create`, `x_sema_unlock`

MMIO delta vs the baseline (VERIFIED):
- One new touched register: `0x700081c0` (read+write).

### Run B: NULL-fmt-guarded printing stubs (progressed further)
Evidence:
- UART: `bdpdrv-stub-20261111-034012.uart.log` (14603 bytes, sha256 `eb557c50…`)
- MMIO: `bdpdrv-stub-20261111-034012.mmio-unimp.log` (112 unimp lines, 40 unique addrs)
- Meta: `bdpdrv-stub-20261111-034012.meta.json`

Stub identity (VERIFIED from meta):
- `bx510_osal_stub.ko` sha256 `d7f94b158f03954d5fcffa1b3914350cec65e9e045d99f80876721c7070f7971`

Outcome (VERIFIED):
- `bdpdrv.ko` **loaded** (no `Unknown symbol` lines).
- `insmod` again returned `139` due to a later crash in `i4IdeDrvInit()` (`PC is at 0xe92d000e`), consistent with a bogus/NULL function pointer call in driver init (not the earlier stub-printing crash).
- The module remained present in `/res/proc/modules` after the crash (`BDPDRV_MOD=0`).

Stub calls observed (VERIFIED; 15 unique):
- `Assert`, `CKGEN_AgtOffClk`, `Printf`, `SYS_Printf`, `UTIL_Printf`, `cli_init`, `init_static_memory`, `vdbg_printf`,
  `x_cli_attach_cmd_tbl`, `x_mem_alloc`, `x_memset`, `x_reg_isr`, `x_sema_create`, `x_sema_unlock`, `x_strncmp`.

MMIO trace (VERIFIED):
- Baseline (pre-stub, link failed) had 16 unique unimplemented MMIO addresses.
- Run B has **40** unique unimplemented MMIO addresses.
- **New addresses attributable to “bdpdrv got further”** (run B minus baseline trace3):
  - `0x700000c0, 0x700000c4, 0x700000c8, 0x700000cc, 0x700000d0, 0x700000d4`
  - `0x70000180, 0x70000184, 0x700001a0, 0x700001a4`
  - `0x700081c0`
  - `0x700240d4, 0x700240d8, 0x700240f4, 0x700240f8, 0x70024108`
  - `0x70048048`
  - `0x7005e010, 0x7005f050, 0x7005f090, 0x7005f0d0, 0x7005f110, 0x7005f150, 0x7005f190`

Interpretation:
- **VERIFIED:** the OSAL stub makes `bdpdrv.ko` link/load (no unresolved symbols) and execute well into its init path.
- **VERIFIED:** bdpdrv’s deeper init performs additional MMIO in the `0x7000xxxx`, `0x7002xxxx`, `0x7004xxxx`, and `0x7005xxxx` regions.
- **INFERRED:** the remaining crash likely reflects unimplemented hardware state in the emulator (or missing real kernel services), not solely the stub.

## Evidence files (this folder)

Symbol accounting:
- `missing.pre.syms` — 153 missing symbols (from /proc/kallsyms)
- `bdp_exports.syms` — exported symbols from BDP modules (via `__ksymtab` scan)
- `missing.pre.covered_by_bdp_ksymtab.syms` — 99
- `missing.pre.not_covered_by_bdp_ksymtab.syms` — 54

Instrumentation runs:
- Run A: `bdpdrv-stub-20261111-033848.{uart.log,mmio-unimp.log,meta.json}`
- Run B: `bdpdrv-stub-20261111-034012.{uart.log,mmio-unimp.log,meta.json}`

Stub source:
- `tools/bx510_osal_stub.c` (STUB/INSTRUMENT)
