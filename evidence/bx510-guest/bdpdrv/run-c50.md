# BX510 guest: bdpdrv.ko Run C50 — FIRST FULL LOAD (insmod rc=0, module Live)

Date: 2026-11-12. Instrument lineage: Run A/B (stub-run.md) → C2 root cause
(x_crit_start/x_crit_end are OSAL FUNCTION-POINTER VARIABLES — decoded from
i4IdeDrvInit 0x987e8: `ldr r3,[lit]; ldr r3,[r3]; blx r3`, 121 ABS32 sites
each, zero direct calls; stub exported functions → blx jumped into the
prologue word 0xe92d000e) → C3..C49 stub instruments (nesting-aware critical
sections, mini-OSAL threads/semaphores, ABI order fixes from assert strings,
two-part build C33+ so bdpdrv links the REAL drvcli.ko CLI framework,
clidrive kernel-side CLI driver C45+, clicmd userland C45+, feboot C50 prep)
→ **Run C50**.

## Verdict (VERIFIED)

- `insmod bdpdrv.ko` returned **0** and the module reports **Live** in
  /proc/modules (`bdpdrv 8830036 1 - Loading 0xbf…` then stays; all prior
  runs: rc=139 Oops).
- Load order proven: `osal_stub_a` → `drvcli.ko` (REAL Sony CLI framework,
  in-rootfs) → `osal_stub` (part B) → `bx510_feboot.ko` (rc=1 — needs
  sata_bltin's `_fg_fe_bootup`, expected, non-blocking) → `bdpdrv.ko`.
- Driver init milestones on the UART (driver's OWN prints):
  `[i4IdeDrvInit]register suspend to DRAM resume function`,
  `[i4IdeDrvBootup]Start..`, `[i4IdeDrvBootup]End..`, `[CEC] Driver Disalbe`.
- Driver threads ALIVE: `IRRC_DataProcessingThread` polls
  `x_thread_delay(arg=10)` continuously (#15104..#15872 counter).
- Driver ASSERT reachable (Sony source path in the assert string:
  `custom/sony/src/driver/ir/irrx_if.c:2093`) — the stub's Assert prints
  the driver's real __FILE__/__LINE__ (provenance bonus).
- Driver's CLI framework serves REAL command tables through the drvcli
  chardev + clicmd (`CLI_EXEC_RC=0`, table shows `hdmitx(hdmitx): Hdmi Tx
  command`); x_cli_parser reachable from userspace AND kernel-side.
- Character device major 29 (**fb**) registered — the display stack surface
  the S5 success criterion needs.

## MMIO trace (VERIFIED) — the Phase-C model spec, written by the driver

33,993 unimplemented accesses (23,970 reads / 10,023 writes), 0.9 MB raw log.
Hot set (count, address, semantics INFERRED from access pattern):

| count | address | pattern |
|---|---|---|
| 12,014 r | 0x7002420c | polled status register (dominant poll) |
| 1,232×6 | 0x70050300/04/08/0c/10/14 + 0x70050320 | 6-register burst ×1232 iterations; writes 0x5001c, 0x70046 …, 0x70050320 toggles 0x30/0x31 (per-chunk kick / done-toggle) |
| 1,234 w | 0x700240f4 = 0x0 | per-iteration ack/clear |
| 907/906 r | 0x70047108 / 0x70047110 | second poll pair |
| ~26 r/w | 0x700000c0/c8, 0x7002117c/84/88, 0x70005028 | init-time config/irq-mask writes |

Model implication (INFERRED): the burst sequence + poll pair + status
register look like a descriptor/DMA engine handshake; a Phase-C device
needs (a) the status register to eventually report done, (b) the 6-register
burst accepted as storage, (c) the ack write to advance the handshake.

## Fidelity notes (honest labels)

- The OSAL stub remains an INSTRUMENT (STUB/INSTRUMENT — not reconstruction);
  Sony OSAL behavior is still approximated. What is now REAL: bdpdrv's own
  init, its CLI framework (drvcli), its threads, its MMIO access pattern.
- Not yet proven: probe completing into a functional /dev/fb0 provider
  (framebuffer registration through bdpdrv), CPSA export surface, display
  init through the real driver (S5 Phase C success criterion).

## Evidence files

- `bdpdrv-runC50.uart.log` (84,590 B, sha256 102a7ed4…)
- `bdpdrv-runC50.mmio.log` (1,483,073 B, sha256 e3ccf142…)
- `bdpdrv-runC50.meta.json` (sha256 3829908b…)
- Stub identity in meta; bdpdrv.ko sha256 6604f6cd… (pin unchanged).

## Next (S5 Phase C input)

1. Pull the decode of the 0x700503xx burst + 0x7002420c poll from
   bdpdrv's code (register names in the 169 vendor-named symbols).
2. Implement the minimal QEMU device for the hot set; iterate boot→probe.
3. Check what device node the driver's fb provider path expects.
