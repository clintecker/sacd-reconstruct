# Runs C94/C95 — the a-window model was aimed at a window the driver never touches

**Date:** 2026-11-12/13 (night session). **Verdict: honest negative for the C93 fix batch + a decisive protocol discovery.**

## C94 — the status-model fix batch did not change behavior

The uncommitted `emulator-kit/sony-bx510.c` diff (status byte model 0x50/0x58 at
`0xa01c`, ATAPI signature trio on lbal/lbam/lbah, SRST-as-reset classification,
RMW PHY registers 0xa604/0xa620/0xa634/0xa680/0xa080/0xa114/0xa108, IDENTIFY
drain on the PIO data port, a-window access tracing) was staged to the VM kit
dir, rebuilt (`sacd-emu-build`, binary mtime 23:57, run ts 23:58:50 — the new
binary demonstrably ran) and fired identically to C93.

Result: **byte-for-byte the same failure** — `ata1.00: qc timeout (cmd 0xa1)`,
`failed to IDENTIFY (I/O error, err_mask=0x4)`, the full SRST-failure EH loop
(`errno=-16` = EBUSY), `reset failed, giving up`, bdpdrv still loads Live.
UART diff vs C93: timing/address drift only.

## C95 — BX510_TRACE=1 full trace, and the surprise

The new build logs **every** MMIO access (`BX510_TRACE=1` env on the VM fire).
5.7M lines / 165 MB (`/tmp/bdpdrv-runC95.mmio.log` on the VM; post-FE-handshake
tail = lines 541511+ committed as `decode/bdpdrv-runC95.posthandshake.mmio.gz`).

**Measured fact: ZERO accesses to the 0x7000a000 SATA port window in the whole
run.** Not "unhandled" — *zero*. `port_start` took the state==1 fast path
(post-AACS), which skips the a-window probe-path bring-up entirely, and libata's
post-activate probe never goes near it either. Every a-window model addition
from `ata-probe-path.md` §6 — including the C93 fix batch — targets a window
this driver phase does not use. The doc's §2.2 "taskfile block shape" analysis
inherits the same error.

## What the driver actually does (from the trace)

1. **ATA commands go through the FE mailbox** (0x70005c000 block), 13 commands
   posted over the run:
   - #1 `w0=0xa1000000` → reply read from `0x5c040-4c` (chk_int_ldr entry —
     the modeled path, "CheckSum OK" observed).
   - #2 `w0=0x00100000` (type 0x10 ack) → reply read + final `05c804` W1C=0.
   - **#3 `w0=0xa1000000 w2=0xa000` → the IDENTIFY PACKET dispatch
     (`send_atapi_cmd`). The driver polls `0x5c804` (R, W1C=0x10000, ×2, R,
     W1C=0) and NEVER reads `0x5c040-4c`.** The current model answers the
     byte3-0xa1 doorbell with the chk_int_ldr message-A/B sequence — wrong
     protocol for this call site. ~30 s later libata prints `qc timeout`.
   - #4..#13 `w0=0xf7000000` / `0x08000000`, `w2=0xa000`, ~1.6 s apart — the
     EH/retry cadence. Codes 0xf7 and 0x08 are unhandled by the model
     (silently ignored → no reply → spin).
2. **Unmodeled register pair `0x5108`/`0x5110`** (current model: `adsp_port`/
   `adsp_data`): 0x5108 written 2037× (values all carry low byte 0xa1, e.g.
   `0x8ca8f1a1`), 0x5110 written 4075× (values `0xa1, 0x1a1..0x7a1`).
3. **SATA HAL hw-init block `0x242xx`**: `0x2420c=0x111, 0x24210=0xe1,
   0x24214=0x200, 0x24218=1`, then **12945 reads of `0x2420c`**.
4. The massive BIM traffic (`0x8030/0x34/0x38` ~1.2M reads, `0x8138/3c`,
   `0x8154/58` ~300k each) is kernel IRQ dispatch + the 10 ms poll loops of the
   EH cycle; the mask shuffle is `0x44000` (bits 18,14) → `0x8044000`, ack
   `0x8000000` (bit 27 = timer).
5. Byte-width MMIO in the entire post-handshake era: only `W 0x424bb=0x8`,
   `W 0x434bb=0x0` (twice each), one `R 0x24501 sz1`.

## Consequence + next step

`ata-probe-path.md`'s claim "the observable is the model's own UNIMP log" was
right in spirit but the decode assumed the ioaddr fields land in the a-window;
the C95 full trace (absence = proof of absence) settles the question the doc
left as §2.2's unresolved experiment — **negatively**. The FE-ATA-command
protocol (`send_atapi_cmd` .text+0x1fe8, `xfer_fe_data` .text+0x2198, the
0xf7/0x08 codes, the 0x5108/5110 pair, the 0x242xx block) is the missing decode.

Decode worker dispatched (output: `decode/fe-ata-cmd.md` + mechanical
re-verification script `decode/fe_ata_cmd.py`). libata.ko is now present in
`/tmp/bdpdrv/` — the old doc's "libata absent" caveat is stale and §2.2's
ioaddr question can be answered from libata's host template too.

## Fire commands (repro)

```
# stage kit + tools, rebuild (mac side):
make vm-stage-file FILE=emulator-kit/sony-bx510.c   # then cp /tmp/sony-bx510.c ~/bx510-emu/emulator/
make sacd-emu-build
# fire (VM):
cd ~/bx510-emu/emulator && [BX510_TRACE=1] python3 bx510_bdpdrv_stub_probe.py \
  --qemu work/build/qemu-system-arm --images /tmp/images-fe \
  --stubko /tmp/osal_b/bx510_osal_stub.ko --stuba-ko /tmp/osal_a/bx510_osal_stub_a.ko \
  --bdpdrv-host /tmp/rootfs/lib/modules/2.6.35/BDP/bdpdrv.ko \
  --bdpdrv-guest /lib/modules/2.6.35/BDP/bdpdrv.ko \
  --pre-file libata.ko=/tmp/sata_staging/libata.ko \
  --pre-file sata_mt85xx_mod.ko=/tmp/sata_staging/sata_mt85xx_mod.ko \
  --extra-file bx510_feboot.ko=/tmp/osal_d/bx510_feboot.ko \
  --extra-file bx510_clidrive.ko=/tmp/osal_c/bx510_clidrive.ko \
  --uart /tmp/bdpdrv-runC9N.uart.log --unimp /tmp/bdpdrv-runC9N.mmio.log \
  --meta /tmp/bdpdrv-runC9N.meta.json --timeout 300
```

Evidence: `bdpdrv-runC94.{uart,meta}` (committed), `bdpdrv-runC95.{uart,meta}`
+ `decode/bdpdrv-runC95.posthandshake.mmio.gz` (committed). The full C95 trace
stays VM-side at `/tmp/bdpdrv-runC95.mmio.log` (tmpfs, 165 MB — re-fire with
`BX510_TRACE=1` to regenerate if the VM reboots).
