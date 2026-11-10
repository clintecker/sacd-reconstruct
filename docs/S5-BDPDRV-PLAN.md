# S5 experiment plan — the real display driver (`bdpdrv.ko`) in the rig

Status: plan (2026-11-10). Predecessors: S3 (fbvirt real-ring, DONE),
S2 (SaWMan coexistence, DONE in guest). Scope decision made up front:
**run, don't reconstruct** — the 8.1 MB / ~12,500-function driver is not
a reconstruction target (no DWARF, 30x the daemon's function count), but
its PROBE PATH is decodable and traceable. The tracer and the targeted
decode cross-check each other.

## The question

Does Sony's real display/CPSA kernel driver probe and run in our QEMU
guest if we model only the MT85xx registers it actually touches? If yes,
the rig runs the real display stack end to end and fbvirt becomes a
stepping stone. If no, the failure log is a register map — cheap
targeting data either way (house rule: evidenced negatives are results).

## Ground truth in hand (VERIFIED)

- `bdpdrv.ko` 8,122,068 B, sha-pinned below, ARM REL ELF, at
  VM:/tmp/rootfs/lib/modules/2.6.35/BDP/bdpdrv.ko (matches guest kernel
  2.6.35 exactly — same-tree module).
- Symbol situation: 260 undefined, 12,469 named T/t symbols, ZERO
  debug sections, 23 printk strings. 169 mt85/mtk/cec/hdmi/gfx/disp/
  bdp-named symbols — the decode starting set.
- Our own `sacd_read.ko` (the CPSA shim we built) loads in this guest;
  module-loading machinery proven.
- fbvirt.ko proves the /dev/fb0 chardev surface the provider needs;
  bdpdrv would REPLACE fbvirt, not sit beside it.

## Phase A — the trace (the cheap experiment, first)

1. Stage `bdpdrv.ko` into the guest (same tar-through-fe_test_data path).
2. Boot with an EMPTY MMIO model: unassigned accesses currently log via
   QEMU's unimplemented-device (log "invalid memory access" style).
   Ensure the machine logs guest-physical address + size + direction for
   every faulting access (extend `sony-bx510.c` IO region if needed).
3. `insmod bdpdrv.ko` in the guest; capture the full UART log + the
   MMIO trace until module_init returns (probe success OR failure).
4. Differential read: which physical ranges were touched, in what
   order, read vs write, what values were written.

Deliverable A: `evidence/bx510-guest/bdpdrv/trace-run.md` + the raw trace.
Register list = the model spec. No guessing.

## Phase B — targeted decode of the probe path (cross-check)

Same method as the mtk.so extraction (llvm-objdump + pyelftools literal
reads; scripts retained beside outputs):

- Decode `module_init` and the probe entry (findable from `initcall`
  structure + the 169 vendor-named symbols).
- For each MMIO range Phase A saw: find the accessor functions that
  reference that base (constant-pool addresses), pin offsets and the
  read/write semantics of the first-level registers.
- Expected focus set: 50-200 functions (probe, reg helpers, clock/
  power sequence). NOT the full binary.

Deliverable B: contract section in `docs/` (VERIFIED/INFERRED labeled)
+ extraction scripts/outputs under `evidence/bx510-guest/bdpdrv/`.

## Phase C — the minimal model

Implement the smallest QEMU device that satisfies the trace: the touched
register ranges with decode-informed read values (IDs/versions often
read-only constants; status bits often polled). Iterate boot -> probe ->
deeper until `bdpdrv.ko` reaches the state fbvirt reaches for the
provider: chardev surface present, /dev/fb0 functional.

Success criterion (parallel to S3's): the retail DirectFB stack
initializes THROUGH bdpdrv (not fbvirt) and the guest-gate HUD run
passes with the real driver in the loop.

## Falsification paths (declared up front)

- Driver hard-fails on a register we cannot model (e.g. hardware RNG,
  efuse, chip ID baked into silicon) -> record exactly which; the
  negative is the result for this round.
- Driver requires the CPSA crypto block -> out of S5's display scope;
  record and stop (our sacd_read.ko already covers the CPSA userspace
  path).
- Probe takes a hardware watchdog path we cannot satisfy -> record.

## Cost estimate

Phase A: half a day (staging + one boot + trace parse).
Phase B: half a day (focused decode, known method).
Phase C: 1-2 days IF the probe is tractable; otherwise Phase A+B results
stand as the deliverable and fbvirt+SaWMan remains the rig.

sha256 (record at stage time, PROVENANCE.md):
bdpdrv.ko = 6604f6cd6c204c3399ac047f389f47162b06a3f6576159f21b4e8aaf3a72cf54 (pinned 2026-11-10 from /tmp/rootfs; in-guest copy md5-identical)
