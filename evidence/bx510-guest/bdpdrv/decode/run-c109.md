# Run C109/C109b/C109c — the decrypt leg: **THE PIPELINE DECRYPTS.**

**Verdict: the full SACD pipeline — read framed → TZ decrypt → strip to
plaintext — now runs end-to-end and byte-matches the fixture, and the final
verdict gate PASSES with the decrypt oracle included (`VERDICT_RC=0`).**

## 1. The three-run arc

| run | what changed | outcome |
|---|---|---|
| C109 | decrypt leg (f) added: `srread sacdread decrypt` (ioctl `0x40105304`), gate oracle `a9e63d2d…` = plain ISO LBA 510+511 | **HANG** after `i4LockDecryResource` — silent, no mq/ev/tz evidence; guest alive (VFD noise) |
| C109b | hang-decode fix applied (ISR-tail completion) | **OOPS** at `TzServiceCall+0x4c` (see §3) |
| C109c | phys→virt mapping added | **PASS** — full round-trip, 0 oopses |

## 2. The C109 hang — decode result (decrypt-hang.md)

The hang decode found the wait chain: `_i4GCPU_SACDDEC` (`0x17150c`) calls
`_vGCPU_WaitCmdExec` (`0x173e7c`) → `x_ev_group_wait_event(inst+0x0c, mask 1,
op 5)` — and the **only writer of `inst+0x0c` in all of bdpdrv is
`_i4GCPU_Hal_CB` (`0x1736b4`), which runs only from `_GCPU_IrqHandle`**
(`0x173080`), the GCPU IRQ-32 handler. There is no GCPU hardware:
`TzServiceCall` IS the hardware, so the completion interrupt never arrives.
The C109 log confirms the command WAS delivered and the worker DID pick it up
(`mq_send #5 h=c6378eb0 w0=0x806` → worker `mq_recv #14` — the `mq_recv #14
h0=c6378eb0` line is the worker's parked receive from before, no second print
owed). The fix: after serving `0x1e`, the stub runs the ISR's own tail —
`cb(NULL, hw->ctx)` via `_prGcpu_Hw_GetGCPUStruct`'s record (+0x1c callback,
+0x20 instance) — which sets `inst+0x0c` and unblocks both waits.

## 3. The C109b oops — the phys/VA lesson

`Internal error: Oops: 5` at `TzServiceCall+0x4c`, called from
`i4GCPU_HAL_SetMISC_Cmd+0x50`. Register file: `params = 0x06321000` — a
**physical** address. `GCPUMemoryAlloc` returns phys (`kernel VA −
0xc0000000`: every kernel heap handle this boot is `0xc6xxxxxx`, so
`0x06321000` ↔ `0xc6321000`). The secure world works on physical addresses
(they arrive `| 0x40000000` NS-tagged); the stub works on VAs. `tz_ns()` now
NS-strips AND `phys_to_virt()`s anything below `PAGE_OFFSET`. Same treatment
for the request block's `src`/`dst` before the copy.

## 4. The C109c measurement (the point of the whole arc)

```
[OSAL_STUB] tz: svc 0x1e: opcode=0x80 src=0x6312020 dst=0x625e0c0 count=1 len=2064
[OSAL_STUB] tz: svc 0x1e: identity transform done (2064 bytes)     (×2 blocks)
SACDREAD cmd=0x40105304 lba=510 nsec=2 len=4096 ret=0 errno=0 result=1728053248
MD5 name=sacd510dec off=0 hash=a9e63d2dda7ef0cc5face5682f0a913e
LADDER f MEASURED lba=510 nsec=2 decrypt via ioctl 5304
READ10_VERDICT=PASS    (VERDICT_RC=0 — every check, including H2)
```

`result=1728053248` = `0x67000000` — the GCPU CmdExec success code the decode
predicted (`0x174258`). The output's first bytes are `SACDMTOC` — the disc's
own master-TOC sector, delivered through read → decrypt → strip. **This is
the daemon's exact production path, proven at Level 0.**

## 5. One more rig defect named (bisect residue)

C109 also carried a self-inflicted trap now written down: the C106-era
bisect overwrote `VM:/tmp/bx510_osal_stub.c` with the pre-dispatcher stub
(`git show HEAD:` for the bisect), so C106b–C109 silently ran the old-stub
`.ko` — Connect succeeded anyway (peer module), but "no `tz:` line" was
never evidence of anything. Standing rule: any bisect that swaps staged
sources must re-stage the canonical tree immediately after, or label the
fire as bisect-contaminated in its doc.

## 6. Next

The daemon stage (`sacd_extract_160`, payload already staged on the VM) is
unblocked: Connect ✓, framing ✓, real reads ✓, decrypt ✓.
