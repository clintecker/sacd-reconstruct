# Phase 0/2 results — the daemon and its real kernel module inside the full-system guest

Date: 2026-11-03. Rig: lab VM (`make sacd-emu-build` QEMU sony-bx510,
Sony kernel 2.6.35 from the M15.R.0257 NAND), probe
`tools/bx510_phase0_probe.py` (observe-driven, marker-split to defeat the
shell's command echo), artifacts `/tmp/p0v*-uart.log`, `p0v*-probe.out`
on the VM; unimp baseline: 29 unique MMIO lines, all boot-time.

## Guest environment facts (all new, all Sony-image facts)

- The squashfs root has **no /proc, /dev, /sys, /mnt, /tmp**. A real
  player's entire VFS skeleton comes from the initramfs (the same
  initrd_1 we cannot yet unpack). Minimal `init=/bin/sh` boots must
  create everything under `/res` (tmpfs) — the only standard mountpoint
  that exists is `/res`.
- Sony's `/bin/sh` aborts every background job at `/dev/null` open, so
  daemons must be started via a fork-exec wrapper (`tools/bx510_bgstart.c`).
- Sony's `/bin/mknod` is statically linked → LD_PRELOAD does not reach
  it; `/sbin/insmod` is dynamic and honors it.
- `ls -ld /tmp` → absent; `tmpnam()` therefore fails (glibc tmpnam
  ignores TMPDIR: `__path_search(..., try_tmpdir=0)` in glibc 2.9
  sources) leaving `strcpy(mod_file,"/tmp/")` → open EISDIR. The shim
  (`tools/bx510_tmpredir.c`) provides tmpnam + /tmp→/res/tmp and
  /dev→/res/dev redirects at the libc boundary. mknod without S_IFCHR
  creates a REGULAR file (vfs_mknod falls back to vfs_create) — the node
  must be created with S_IFCHR|0666 (bgstart).

## P1 — does the daemon serve in the guest? YES (server path), with the gate still to pass honestly

With install bypassed by the accidental regular-file node, the daemon
ran its full server path inside Sony's OS: LISTEN on 00000000:07D2 in
/proc/net/tcp (state 0A) and the genuine status loop:

    SACD Daemon 0.37 active. Client none. Tray is empty.

pthread create/bind/listen/status all work under Sony's kernel. With the
S_IFCHR node (honest gate) install fails and the daemon correctly
refuses to serve — so honest serving requires the module to load (below).

## P2 — the real module: dependency chain walked, contract pinned

- sacd_read.ko (embedded, extracted; vermagic `2.6.35 preempt mod_unload
  ARMv6`, **no __versions → CONFIG_MODVERSIONS off**, name-only binding)
  imports exactly one non-kernel symbol: **x_memset**.
- The full module dependency graph of /lib/modules/2.6.35/BDP computed
  offline (nm bipartite graph): load order drvcli → kmem → osai →
  drvuart/cbagent/rm → bdpdrv; but the chain's base (`UTIL_Printf`,
  `SYS_Printf`, `Assert`, `get_dynamic_memory`...) is defined by NO
  module in the squashfs → the OSAL base lives in the initramfs.
  hst_*.ko are the Atheros WiFi stack (wmi_*), not OSAL.
- **osai_mini stub** (`tools/bx510_osai_mini.c`, built against Sony's
  GPL linux-2.6.35 drop + mediatek_defconfig, SMP off, -march=armv6,
  vermagic token patched ARMv7→ARMv6 same-length in .modinfo):
  `this_module` size **0x148 exact match** with every Sony module
  (struct module layout proven), x_memset instruction-identical to
  osai.ko's own. Loaded Live in the guest first try.
- With x_memset provided, the daemon's own insmod of the REAL
  sacd_read.ko **passed symbol resolution and its init executed**:
  init resolves **16 symbols via kallsyms_lookup_name** (loose coupling
  into the bdpdrv stack) and returns **-EFAULT if any is NULL** — the
  observed "insmod: Bad address". 9 are missing (all bdpdrv functions):

      u4CPSA_Inst_GetInstHandleFromCompId, i4CPSA_Inst_Connect,
      i4CPSA_Inst_Disconnect, vSacdDecryptEnable, _SACDCLI_TestPhy,
      eSacdGetVersion, _SACDCLI_FindTag, _IDECLI_OddTestUnitReadyLoop,
      _IDECLI_OddGetProfile

  (`__ksymtab_disable_print` was found in the kernel — used to silence
  bdpdrv's printk). After the lookups, init calls the first-resolved
  function with the `minor` module param (201), expects **-1 as its
  success sentinel**, then misc_register's minor 201.
- The module itself CONTAINS `CPSA_SACDCmdDecrypt`, `CPSA_SACDCmdEnable/
  Disable/SetCtrl` and its own `_IDECLI_OddRead` raw-2064-frame path
  (per the handoff's optical disassembly) — the kallsyms symbols are the
  stack glue above it.

## The super-right path, now concrete

`kallsyms_lookup_name` also searches loaded modules' symbol tables, so a
"bdpvirt" provider module defining the 9 missing symbols satisfies the
lookup — in kernel space, exactly at the seam the Phase-2 design wanted.
Behavior contract to derive from bdpdrv.ko (unstripped, 8 MB, local in
BX510-Inputs) per function; `_SACDCLI_TestPhy(201)` must return -1.
After init completes: misc_register(201) → daemon's open("/dev/sacd_read")
succeeds against the REAL module → honest serving → ioctl READ/DECRYPT
run the module's own code path (raw 2064-byte frames) → hardware-facing
probes appear in the QEMU unimp log → iterate sony-bx510.c stubs from
there. The qemu-user rig (raw-frame contract, offset-12 packing) remains
the reference for what those paths must produce.

## Verdict

- P1: **server path proven in-guest** (bind/listen/status); honest
  module-gated serving pending the 9-symbol provider.
- P2: **module executes in-guest past symbol resolution**; its full
  runtime dependency contract is now pinned with disassembly evidence.
