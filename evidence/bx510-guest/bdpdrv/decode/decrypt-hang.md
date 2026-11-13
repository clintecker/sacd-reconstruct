# Why the C109 decrypt ioctl hangs: the GCPU completion event nobody raises

Date: 2026-11-13. Static decode (Mac-side, no VM) of the `SACD_IOC_DECRYPT`
(`0x40105304`) hang observed in run C109, plus the stub fix and the single
UART line that falsifies the finding.

**House rules.** **VERIFIED** = read out of an instruction, a literal-pool word
resolved through its relocation, a symtab entry, or a log line quoted verbatim,
with function + offset cited; re-derivable with §7. **INFERRED** = reasoned
from those facts, labelled. **OPEN** = not closed in this time-box, with the
next probe.

Binary: `evidence/bx510-guest/artifacts/bdpdrv.ko`, sha256
`6604f6cd6c204c3399ac047f389f47162b06a3f6576159f21b4e8aaf3a72cf54`
(8,122,068 B, ELF32 ARM `ET_REL`). Runtime base `0xbf089000`; every address
below is `.text`-relative (`+ base` for the VA). Rig console:
`evidence/bx510-guest/bdpdrv/bdpdrv-runC109.uart.log` (identical to
`VM:/tmp/bdpdrv-runC109.uart.log`; `cmp` clean), 195,403 B / 3,408 lines — all
line numbers below are from that file.

---

## 0. Bottom line

1. **The premise of the brief is wrong in the most useful way: the command was
   sent.** `[OSAL_STUB] mq_send #5 h=c6378eb0 w0=0x806
   caller=_fgGCPU_SendCMD` (log line 2292) is `i4GCPU_CmdExec` posting the
   `0x806` SACDDEC command into the worker's queue. So nothing blocks between
   `i4LockDecryResource` and `x_msg_q_send` — the send happened *before* that
   printk. *VERIFIED (§1).*
2. **The worker picked the command up and got as far as the H/W-resource
   step.** `_u1GCPU_HWRes_Obtain` is called from exactly one place,
   `_i4GCPU_SACDDEC+0xf4` (`0x171600`), and it is the only caller of the
   `i4LockDecryResource` import in the whole module. The `i4LockDecryResource
   called` line (2294) is therefore proof that the **worker thread, not the
   ioctl thread**, had reached the middle of the SACDDEC handler.
   *VERIFIED (§2.1–2.2).*
3. **The blocking site is `_vGCPU_WaitCmdExec` (`.text+0x173e7c`), reached from
   `_i4GCPU_SACDDEC+0x128` (`0x171634`).** It waits on event group
   `inst+0x0c` with `x_ev_group_wait_event(h, mask=1, op=5)`. **The only
   writer of `inst+0x0c` in the entire module is `_i4GCPU_Hal_CB`
   (`.text+0x1736b4`)** — the per-GCPU-slot completion callback registered by
   `_u1GCPU_HWRes_Obtain` through `i4GCPU_HAL_SetCBFunc`. That callback runs
   only from `_GCPU_IrqHandle` (`.text+0x173080`), the GCPU **interrupt-32**
   handler that `_GCPU_InitIsr` hands to `x_reg_isr`. *VERIFIED (§2.3).*
4. **Three independent breaks make that interrupt undeliverable in this rig:**
   (a) `x_reg_isr` is a no-op stub (`tools/bx510_osal_stub.c:573`), so the ISR
   is never hooked; (b) there is no GCPU hardware in the rig at all — the
   "hardware" is `TzServiceCall`, which is synchronous, returns nothing to the
   driver, and raises no IRQ; (c) even a hand-called `_GCPU_IrqHandle` would
   early-return on `*prScallCmd == NULL` (`0x1730f4`), and bdpdrv never
   writes `prScallCmd`. *VERIFIED for (a)(c); (b) is the rig's definition.*
5. **The ioctl's own hang is a consequence, not a separate bug.**
   `i4GCPU_CmdExec` unblocks at `0x174218` (after the send) and then blocks in
   `_vGCPU_WaitCmdExecFinish` (`0x174238`) on event group `inst+0x10`, which
   only the worker's `_vGCPU_SendCmdExecFinish` sets — after the handler
   returns. The handler never returns, so the ioctl waits forever. *VERIFIED.*
6. **The "no tz svc line" half of the observation carries no information, and
   the C109 rig additionally ran a stale stub.** The module that ran had
   `unsigned long TzServiceCall(unsigned long a0, ...) { STUB_ONCE(); return
   0; }` — the pre-C106 stub, with no service dispatch and no `0x1e` handler
   at all (`VM:/tmp/bx510_osal_stub.c`, md5 `9d3dfd05…`, build stamp 17:25;
   the committed `tools/bx510_osal_stub.c` (`HEAD:`, commit `ed40006`) is md5
   `532f1834…` and carries the dispatcher). So the missing `tz:` line is a **provenance defect
   of the run**, not evidence about the path. *VERIFIED (§1.2).*
7. **The fix is one behaviour, not one line of model code:** `TzServiceCall`
   service `0x1e` must raise the GCPU completion — it *is* the hardware that
   was supposed to interrupt. Called for the MISC carrier in
   `tools/bx510_osal_stub.c` (`gcpu_cmd_complete()`); no QEMU change, no MMIO,
   no new model row. *VERIFIED mechanism; the call is INFERRED-correct by
   construction — §4.*
8. **Falsifiable prediction (§5):** the next fire prints
   `[OSAL_STUB] tz: svc 0x1e: opcode=0x80 …` followed by
   `[OSAL_STUB] tz: svc 0x1e: identity transform done (4128 bytes)` and then
   `LADDER f MEASURED lba=510 nsec=2 decrypt via ioctl 5304`. If `LADDER f` does
   not appear while both `tz:` lines do, this analysis is wrong about the
   completion being the last blocker and the next candidate is an `Assert`
   from `_i4GCPU_SACDDEC`'s own post-conditions.

---

## 1. What the log actually says (premise correction)

### 1.1 The real ordering around the decrypt

Verbatim, log lines 2291-2294 (the ladder's leg (f) begins right after leg (e)
prints `LADDER sacd_sg PASS`):

```
LADDER sacd_sg PASS lba=510 nsec=2
[OSAL_STUB] mq_send #5 h=c6378eb0 w0=0x806 caller=_fgGCPU_SendCMD
[OSAL_STUB] crit_end depth=0
[OSAL_STUB] i4LockDecryResource called
```

and from line 2295 to the end of the 3,408-line capture there is **no**
`mq_recv`, no `mq_send`, no `ev_wait`, no `[SACDREAD]`, no `LADDER f`, and no
Oops/BUG — only `VFD_CmdProcThread`, `i4VFDIndirectSIFCmdRegMode`,
`IRRC_DataProcessingThread` and `_sircs_key_proc_thread` `x_thread_delay`
cadence plus the rate-limited `Assert xNNNNNN total
(last: irrx_if.c:2093)` summary. The guest is alive; the ioctl is parked.
*VERIFIED (whole-file grep).*

The `crit_end depth=0` between the send and the lock is another thread: the
stub's `x_crit_end_impl` prints `depth=0` for every unbalanced end call and the
boot log is full of them (e.g. lines 649-655, 684-701) — it is noise, not a
worker transition.

### 1.2 Why "no `tz` line" proves nothing in this run

Two independent reasons, both cheap to check:

1. **The stub binary that ran has no `0x1e` handler.** The run staged
   `VM:/tmp/bx510_osal_stub.c` (md5 `9d3dfd05b95c525cd2dc1c36cdbe8fa0`), which
   contains literally
   `unsigned long TzServiceCall(unsigned long a0, ...) { STUB_ONCE(); return 0; }`
   — the pre-C106 stub. `strings` of the built `VM:/tmp/osal_b/bx510_osal_stub.ko`
   (17:25) has no `tz:` / `opcode=` / `identity transform` strings at all.
   The canonical source (md5 `532f18342b8be153226b50287c7bc929`) has the
   service dispatcher (`TZ_LOG`, `tz_set_misc`) from commit `ed40006`
   (2026-11-13 11:36). *VERIFIED (md5 + strings + the pulled source).*
2. **Even with the current stub, `TzServiceCall`'s own `STUB_ONCE` fires at
   boot.** `[OSAL_STUB] TzServiceCall called` appears once, at log line 402
   (bdpdrv's `i4GCPU_HAL_Init` → service `0x03`). A `STUB_ONCE` line can never
   appear twice, so its absence later says nothing about later calls.
   *VERIFIED (`tools/bx510_osal_stub.c:87` + line 402).*

The general lesson (worth keeping): with `STUB_ONCE` instrumentation, **absence
of a printk is not absence of a call**. The C109 observation was built on the
opposite assumption. The only prints in this run that carry per-call weight are
the counted ones (`mq_send` first 8, `mq_recv` first 16, `x_sema_lock` every
256, `x_thread_delay` every 256, `ev_wait` first 4) and the unconditional ones
(`Assert`, `UTIL/Printf`-forwarded driver text, `TZ_LOG`).

---

## 2. The chain, instruction by instruction

### 2.1 The ioctl thread: `i4GCPU_CmdExec` (`0x1740bc`, 508 B)

| offset | instruction | meaning |
|---|---|---|
| `0x1740f8` | `ldr sl,=0xb18e4(_arGcpuInst)` | GCPU instance table |
| `0x174100` | `ldr r0,[sl,#0x268]` | `_hGcpuSema` (`= _arGcpuInst+0x268`, symtab value `0xb1b4c`) |
| `0x174104` | `bl x_sema_lock` with `r1 = #1` | **blocking** `down()` on the *global* GCPU semaphore |
| `0x174130..0x1741a0` | flag scan, `bic`/`orr` | allocate one of the **6** command slots: busy bit `8+4k`, `k` bounded by `cmp r3,#8` at `0x174198`; the free path stores `slotbyte = 8+4k` at `[sp,#0xc]`, and the worker later sets finished = `slotbyte+1`, success = `slotbyte+2` |
| `0x1741b0..0x1741bc` | `x_sema_unlock`; `return 0xE7000005` | no free slot |
| `0x1741d4` | `str r2(=1),[r3,#0x34]` | state tag 1 (trace aid) |
| `0x1741e8..0x1741f4` | `bl _fgGCPU_SendCMD` | `x_msg_q_send({op,param,slot},12)` → **the `mq_send #5` line** |
| `0x1741f8..0x1741fc` | `cmp r0,#0 ; beq 0x1741e0` | on send failure: `x_thread_delay(1)` and retry |
| `0x174214` | `str r3(=2),[r6,#0x34]` | state tag 2 |
| `0x174218` | `bl x_sema_unlock` | release `_hGcpuSema` |
| `0x174238` | `bl _vGCPU_WaitCmdExecFinish` | **the ioctl's blocking wait** (`fgWait != 0`) |
| `0x17424c..0x174254` | `lsr r1,r2,r1 ; tst r1,#1` | test success bit `slotbyte+2` |
| `0x174260` | `UTIL_Printf("i4GCPU_CmdExec CMD FAIL:%d %d, %d\n")` + `return 0xE7000008` | waited, no success bit |
| `0x174258` | `return 0x67000000` | success |

*VERIFIED (whole function disassembled).* Answering the brief's Q2 directly:
**slot allocation cannot block** — it is a bounded flag scan under `_hGcpuSema`,
there is no per-slot semaphore/count wait, and the two INITs do not leak slots
(only bit pairs set by the *worker* on completion; `i4GCPU_CmdExec` clears them
at `0x174270..0x17428c`). What *can* block on the ioctl side is
`_hGcpuSema` at `0x174100` — and it did not, because the `mq_send` line proves
`0x1741f4` was reached.

### 2.2 The worker thread: `_vGCPU_MainLoop` (`0x174798`, 548 B)

```
0x1747c4 bl _fgGCPU_RetrieveCMD(slot, &cmd)     ; x_msg_q_receive(..., cnt 1, WAIT)
0x1747e0 ldr r3,[sp,#4] ; cmn r3,#1             ; op == 0xFFFFFFFF -> exit
0x174824/0x174848 blx [x_crit_start]            ; the stub's global depth-counted lock
0x174864 bl _i4GCPU_CmdHandle(slot, op&0x00FFFFFF, param)
0x17486c.. rc >= 0 -> 0x1748dc:
0x17490c..0x174924  orr bits, bl _vGCPU_SendCmdExecFinish(slot)   ; sets event inst+0x10
0x17484c.. rc <  0 -> 0x174890:
0x1748bc..0x1748d4  error bit, bl _vGCPU_SendCmdExecFinish(slot)
0x174930/0x174948 blx [x_crit_end]
```

`_vGCPU_SendCmdExecFinish` (`0x173d80`): `x_ev_group_set_event(inst[0x10], 1, 3)`
— i.e. **event group `+0x10` is only ever set *after* the handler returns**.
*VERIFIED.* That is why the ioctl parks at `0x174238`: the handler never
returns.

### 2.3 The handler: `_i4GCPU_SACDDEC` (`0x17150c`, 356 B)

| offset | instruction | meaning |
|---|---|---|
| `0x171514/0x17151c` | `r0=0x9b8 ; bl GCPUMemoryAlloc` | 2,488-byte request block |
| `0x171520..0x171540` | NULL → `GCPUMemoryFree` + `Assert(gcpu_drv_misc.c:0x6d5)` → `0xE7000007` | |
| `0x171544..0x171594` | `p==0`, `p[0]==0`, `p[1]==0`, `p[2]==0` → `0xE7000002` | |
| `0x171598..0x1715c0` | `__aeabi_uidivmod(p[2], 0x810)`, remainder → `Assert(:0x6e8)` | len must be a multiple of 2064 |
| `0x1715c4` | `str #0x80,[r4,#4]` | request opcode 0x80 |
| `0x1715cc..0x1715e8` | `blk[2]=p[0]\|0x40000000`, `blk[3]=p[1]\|0x40000000` | src/dst, NS-tagged |
| `0x1715ec` | `str p[2],[r4,#0x14]` | `blk+0x14 = len` (bytes) |
| `0x1715f4/0x1715f8` | `__aeabi_uidiv` ; `str r0,[r4,#0x10]` | `blk+0x10 = len/2064` (block count) |
| **`0x171600`** | **`bl _u1GCPU_HWRes_Obtain(slot)`** | **← the `i4LockDecryResource` print comes from here** |
| `0x171604/0x17160c` | `cmp r0,#0xff ; strb r0,[r4] ; bne 0x171620` | `0xFF` = busy → free + `0xE7000000` |
| **`0x171624`** | **`bl i4GCPU_HAL_SetMISC_Cmd(blk)`** | → `TzServiceCall(handle, 0x1e, q\|0x40000000, 0x40)` |
| `0x171628/0x17162c` | `subs r5,r0,#0 ; blt 0x171638` | HAL result < 0 → skip the wait |
| **`0x171634`** | **`bl _vGCPU_WaitCmdExec(slot)`** | **← THE BLOCK** |
| `0x17163c/0x171644` | `bl _vGCPU_HWRes_Release(slot)` ; `bl GCPUMemoryFree(blk)` | |

*VERIFIED (whole function).* Every call in this list was checked against the
stub's implementation:

| call | stub behaviour | can block? |
|---|---|---|
| `GCPUMemoryAlloc(0x9b8)` | `x_mem_aligned_alloc` → `vmalloc` (sz > 256 KiB? no → `kmalloc`) + `x_memset` | no |
| `_u1GCPU_HWRes_Obtain(slot)` (`0x173f08`) | first call: `ucGCPU_HAL_HWRes_Obtain` returns the old busy byte `0` → `_i4Gcpu_Hw_SetCBFunc(slot,_i4GCPU_Hal_CB,&inst[slot])` → `i4LockDecryResource(1)` (stub: `return 0`) → returns `0` | no |
| `i4GCPU_HAL_SetMISC_Cmd(blk)` (`0x172c10`) | `GCPUMemoryAlloc(0x38)`, `q+0x34=0x67000000`, `q+0x18=blk\|NS`, `TzServiceCall`, `return q+0x34` | no |
| `_vGCPU_WaitCmdExec(slot)` (`0x173e7c`) | `x_ev_group_wait_event(inst[0x0c], 1, &got, 5)` → `wait_event()` | **yes — forever** |

The retry loop inside `_u1GCPU_HWRes_Obtain` (`0x173f40..0x173f84`: busy byte
`0xFF` → `x_thread_delay(1)` + `UTIL_Printf("[GCPU]: HW Res obtain retry %d!\n")`)
is *not* what happened: that message appears **zero** times in the C109 log and
no `x_thread_delay arg=1` line exists (the counted printer shows `arg=5/10/100/150`
only). The first obtain returned `0`, so the fast success path ran. *VERIFIED.*

### 2.4 `_vGCPU_WaitCmdExec` and the missing producer

```
0x173e84  mov r2,#0x38
0x173e88  mla r3,r2,r0,r3          ; r3 = &_arGcpuInst[slot]
0x173e8c  mov r1,#1                ; mask = 1
0x173e90  ldr r0,[r3,#0xc]         ; THE EVENT GROUP
0x173e94  add r2,sp,#4
0x173e98  mov r3,#5                ; op 5 = OR_CONSUME
0x173e9c  bl x_ev_group_wait_event
0x173ea0  cmp r0,#0 ; beq ok ; Assert(gcpu_main.c:0x16f)
```

`x_ev_group_wait_event` in the stub (`tools/bx510_osal_stub.c:752`) is a plain
`wait_event()` on `flags & mask`; with the flag never set, the thread sleeps
forever. *VERIFIED.*

Now the decisive xref — **who sets `inst+0x0c`?** Every
`x_ev_group_set_event` call site in the module (192 of them) was enumerated with
its argument register; inside the GCPU subsystem there are exactly three:

| site | event group | reached from |
|---|---|---|
| `_i4GCPU_Hal_CB+0x30` (`0x1736e4`) | **`inst+0x0c`** | `_GCPU_IrqHandle+0xdc` (`0x17315c`, `blx r3`) — the GCPU **IRQ** |
| `_vGCPU_SendCmdExecFinish+0x1c` (`0x173d9c`) | `inst+0x10` | the worker, *after* the handler returns |
| `_vGCPU_SendCmdQue+0x30` (`0x173e48`) | `inst+0x14` | `_fgGCPU_SendCMD`, after a queue post |

`_i4GCPU_Hal_CB` (`0x1736b4`) is 9 instructions:

```
0x1736b8 push {r3,lr}
0x1736bc cmp r1,#0 ; bne ok
0x1736cc Assert("mm_info_hdl", gcpu_main.c:0x123) ; return 0xE7000000
0x1736d8 ldr r0,[r1,#0xc]          ; r1 = the GCPU instance, [0xc] = the event group
0x1736dc mov r2,#3                 ; OR
0x1736e0 mov r1,#1                 ; mask 1
0x1736e4 bl x_ev_group_set_event
0x173708 return 0x67000000
```

so `inst+0x0c` is set **only** by that callback, **only** from the interrupt
handler. *VERIFIED.* Answering the brief's Q1: no, `decrypt_sacd` does not take
or release `i4LockDecryResource` itself — `_u1GCPU_HWRes_Obtain` locks it
(`r0 = 1`) and `_vGCPU_HWRes_Release` unlocks it (`r0 = 0`, tail `b` at
`0x173f00`), and both are no-ops under the stub, so the lock is not the
blocker. The thing that *is* stranded by a no-op stub is the **event**, not the
lock.

### 2.5 `_GCPU_IrqHandle` — why the interrupt never comes

`_GCPU_InitIsr` (`0x173180`) runs once from `i4GCPU_HAL_Init+0xa0`
(`0x1721ac`, boot-time; that is the `TzServiceCall called` line 402):

```
0x173188 ldrb r2,[r3,#4]                    ; _ucGCPUIsrInitiated (.bss+0xb18e0)
0x173190 bne done                            ; already initiated
0x173198 strb #1,[r3,#4]                     ; mark initiated
0x17319c bl i4GCPU_HAL_ClrIntr
0x1731a4 bl BIM_ClearIrq(0x20)
0x1731ac ldr r1,=_GCPU_IrqHandle
0x1731b4 bl x_reg_isr(0x20, _GCPU_IrqHandle, &h)   ; <-- STUB: no-op, return 0
```

`_GCPU_IrqHandle` (`0x173080`) is the completion path:

```
0x17308c ldrb r3,[r5,#4] ; beq done          ; _ucGCPUIsrInitiated gate   (passes)
0x1730a8 ldr r3,=_arGCPUStru ; ldr r3,[r3] ; cmp #0 ; beq done
0x1730c4 bl _prGcpu_Hw_GetGCPUStruct(0)
0x1730d8 ldr r3,[r4,#0x1c] ; beq done        ; the registered callback
0x1730ec ldr r3,=prScallCmd ; ldr r3,[r3] ; cmp #0 ; beq done   ; <-- ALWAYS 0 in bdpdrv
0x173108 bl i4GCPU_HAL_ClrIntr
0x173118 bl BIM_ClearIrq(vector)
0x173150 mov r0,sp ; ldr r3,[r4,#0x1c] ; ldr r1,[r4,#0x20] ; blx r3   ; cb(NULL, inst)
```

*VERIFIED.* So in this rig the event is unreachable **three ways**: `x_reg_isr`
is a no-op (`tools/bx510_osal_stub.c:573` — `{ STUB_ONCE(); return 0; }`), no
peripheral raises IRQ 32 (there is no GCPU in the QEMU model, and bdpdrv issues
no SMC — the whole "hardware" is the `TzServiceCall` import), and
`prScallCmd` (`.bss+0xb1b54`, a plain `B` pointer) has **no writer anywhere in
the module** — my full `.rel.text` scan for `.bss` relocations shows only two
references to it (`0x1722dc` in `i4GCPU_HAL_ClrIntr`, `0x173174` in
`_GCPU_IrqHandle`), both literal *loads*. *VERIFIED (reloc walk).* A writer
outside the module would have to reach the address by kallsyms; none of the
modules this rig loads does, so the pointer stays NULL. *INFERRED for the
product's real supplier, VERIFIED for this rig.*

---

## 3. The brief's four sub-questions, answered

| # | question | answer |
|---|---|---|
| 1 | does `decrypt_sacd` pair `Lock/UnlockDecryResource` through the GCPU completion callback? | **No.** `i4LockDecryResource(1)` is in `_u1GCPU_HWRes_Obtain` and `i4LockDecryResource(0)` in `_vGCPU_HWRes_Release`; both are called inline around the command inside `_i4GCPU_SACDDEC` — no callback involved. What *is* callback-gated is the **event group `inst+0x0c`** (§2.4). *VERIFIED* |
| 2 | does `i4GCPU_CmdExec` slot allocation block when all slots are busy? | **No.** It is a bounded 6-iteration flag scan under `_hGcpuSema`; "all busy" returns `0xE7000005` and unlocks. The two INITs leak no slots (a leaked slot would also have shown as `0xE7000005`, not a hang). The only blocking call is `_hGcpuSema` itself, and the `mq_send` line proves it was acquired and released. *VERIFIED* |
| 3 | could `_i4CPSA_Inst_Decrypt`'s family-bit check / `i4CPSA_SACD_Create`'s `byte[4]` route Decrypt to a different (blocking) branch? | **No, not on this run.** The handler was reached (proof: the `i4LockDecryResource` line, which is inside `_i4GCPU_SACDDEC`), which means `_i4CPSA_Inst_Decrypt` passed its magic check, `i4CPSA_SACD_Decrypt` passed its `len == 2064` and `ctx->byte[4] != 0` checks, and `i4GCPU_CmdExec` posted `0x806`. A family-bit failure would have returned `0xE8000000` to userspace (`SACDREAD cmd=0x40105304 result=…`), which is not what the ladder recorded (no ioctl result line at all). *VERIFIED* |
| 4 | is `vSacdDecryptEnable` on this path with a poll the model must answer? | **No.** Its only xrefs inside bdpdrv are `_sacd_set_fct` (registration) and `_SACDCLI_DecTrack`; from outside it is reached by `sacd_read.ko`'s `CPSA_SACDCmdDisable` only. Nothing on the Decrypt ioctl path calls it, so `0xfd039000`/`0xfd008154` are not involved in the hang. *VERIFIED (relocation xref, unchanged from `gcpu-connect-path.md` §4.4)* |

---

## 4. The fix

### 4.1 The behaviour that is missing

`TzServiceCall` **is** the GCPU. In the product, a posted command makes the
GCPU raise IRQ 32; the ISR runs `_i4GCPU_Hal_CB`, which sets `inst+0x0c`; the
handler's `_vGCPU_WaitCmdExec` returns. In the rig `TzServiceCall` returns
silently, so the last link of the chain is missing. **The stub must deliver the
completion callback after it has "executed" a command carrier.**

### 4.2 The patch, as landed (`tools/bx510_osal_stub.c`)

`gcpu_cmd_complete()` at `tools/bx510_osal_stub.c:352` — resolve
`_prGcpu_Hw_GetGCPUStruct` with `kallsyms_lookup_name` (exported by this
kernel: `sacd_read.ko` imports it, `nm -u original/sacd_read.ko`), read
`hw = get_hw(0)`, take `cb = hw->[0x1c]`, `ctx = hw->[0x20]` and call
`cb(NULL, ctx)` — the ISR's own tail (`0x173150..0x17315c`) with the interrupt
plumbing removed. Called from `TzServiceCall`'s `TZ_SVC_SET_MISC` (0x1e) arm
immediately after `tz_set_misc()` (`tools/bx510_osal_stub.c:393`). `#include
<linux/kallsyms.h>` added at `:28`.

```c
static void gcpu_cmd_complete(void)
{
	static unsigned long (*get_hw)(unsigned long);
	unsigned long *hw;
	void (*cb)(void *, void *);

	if (!get_hw)
		get_hw = (unsigned long (*)(unsigned long))
			kallsyms_lookup_name("_prGcpu_Hw_GetGCPUStruct");
	if (!get_hw)
		return;
	hw = (unsigned long *)get_hw(0);
	if (!hw || !hw[0x1c / 4] || !hw[0x20 / 4])
		return;
	cb = (void (*)(void *, void *))hw[0x1c / 4];
	cb(NULL, (void *)hw[0x20 / 4]);
}
```

Why this shape and not the two obvious alternatives:

* **Firing `_GCPU_IrqHandle` (the real ISR)** would early-return at
  `0x1730f8` because `*prScallCmd` is NULL and bdpdrv never writes it (§2.5).
* **Modelling an interrupt in QEMU** is impossible-by-construction here: the
  driver issues no MMIO for this command and no SMC — the only thing that ever
  leaves the CPU is the `TzServiceCall` *call*. There is nothing for a model to
  trap. This is why the fix is a stub fix, not a model row.
* **Nothing needs a thread, timer or semaphore**: the event group latches
  (`x_ev_group_wait_event` op 5 consumes on success), so setting the flag
  *before* the handler reaches the wait is correct — the command has in fact
  already completed, because `TzServiceCall` is synchronous.

Verified-not-guessed details:

* `hw` is the per-slot 0x24-byte hardware record: `_i4Gcpu_Hw_SetCBFunc`
  (`0x172f20`) stores `cb` at `+0x1c` and `ctx` at `+0x20` of
  `_rGcpuLock[+8] + 0x24*idx`; `_prGcpu_Hw_GetGCPUStruct(idx)` (`0x172ee4`)
  returns exactly that record. *VERIFIED.*
* The SACD path registers the callback in record **0**: `ucGCPU_HAL_HWRes_Obtain`
  (`0x1720dc`) reads/returns byte 0 of that record (the busy flag), and
  `_u1GCPU_HWRes_Obtain` passes the returned byte as the slot index to
  `i4GCPU_HAL_SetCBFunc`. First obtain returns 0 ⇒ callback at `[0]`. The C109
  console shows one `GcpuHw0` instance per INIT. *VERIFIED.*
* `_vGCPU_HWRes_Release` (`0x173ecc`) → `vGCPU_HAL_HWRes_Release` (`0x1720c8`)
  clears only `hw->[0]` (the busy byte), never `+0x1c`/`+0x20`, so the callback
  survives command-to-command. *VERIFIED.*
* Calling the callback from inside `TzServiceCall` runs in the worker thread
  inside the stub's `x_crit_start` spinlock; `_i4GCPU_Hal_CB` only takes a
  small spinlock and `wake_up_all()` — atomic-safe. *VERIFIED (`_i4GCPU_Hal_CB`
  + `tools/bx510_osal_stub.c:748`).*
* Scope: only the MISC carrier (0x1e) fires it. The other `Set*_Cmd` service
  ids (0x0b, 0x0d, 0x10, 0x12, 0x14, 0x16, 0x18, 0x1a, 0x1c, 0x23) carry
  commands whose handlers (`_i4GCPU_AES_*`, `_i4GCPU_CSS_*`, … — 65 call sites,
  one per command handler) will need the same one-line call the first time
  they are exercised. Left out deliberately: unverified scaffolding.

### 4.3 The rebuild is part of the fix

The C109 rig ran a stale stub (§1.2). A re-fire must rebuild both stub parts
from the canonical source and verify the staging, otherwise the fix is not in
the box. The `sacd-stub-build` Makefile target stages from
`experiments/sacd_reconstruct/tools/` (that directory does not exist in this
checkout — `ls -d experiments` fails), so the staging step that actually fed
C109 was hand-rolled, and that is how a 6-hour-old source reached the guest.
The validated sequence (run for this fix, build clean):

```sh
for f in tools/bx510_osal_stub.c tools/bx510_clidrive.c \
         tools/bx510_stub_build.sh tools/bx510_vermagic_patch.py \
         tools/bx510_cpsa_peer.c; do
  scp -o BatchMode=yes -P 2222 "$f" aftermath@10.20.0.18:/tmp/
done
make vm-exec CMD='md5sum /tmp/bx510_osal_stub.c'    # MUST equal md5sum tools/bx510_osal_stub.c
make vm-exec CMD='sh /tmp/bx510_stub_build.sh'      # /tmp/osal_{a,b,c,d}
make vm-exec CMD='strings /tmp/osal_b/bx510_osal_stub.ko'
#   must contain "tz: svc 0x1e: opcode=" and "identity transform done"
```

Observed: build clean (only the two pre-existing C90 `x_snprintf`/`x_sscanf`
warnings at `:156`/`:160`), `kallsyms_lookup_name` present as `U`, vermagic
patched, `/tmp/osal_b/bx510_osal_stub.ko` sha256
`0fe30c6e4ea56993d1b016e11b60c968dd99657ea4ed475a0e92b78ef2b0ee3a`.

---

## 5. Falsifiable prediction for the next fire

Ladder leg (f) is
`srread sacdread decrypt /dev/sacd_read 510 2 sacd510.bin sacd510.dec`
(ioctl `0x40105304`), after the 5303 read leg — unchanged.

**Predicted new UART lines, in this order, from the current stub source:**

1. `[OSAL_STUB] i4LockDecryResource called` (only if the stub image is fresh —
   otherwise it was already consumed in an earlier run of the same boot).
2. `[OSAL_STUB] tz: svc 0x1e: opcode=0x80 src=0x<kva> dst=0x<kva> count=2 len=4128`
3. `[OSAL_STUB] tz: svc 0x1e: identity transform done (4128 bytes)`
4. `SACDREAD cmd=0x40105304 lba=510 nsec=2 len=4096 ret=0 errno=0 result=…
   file=/res/c103/sacd510.dec` followed by `DUMPHEX name=sacd510.dec …` (the
   helper prints `len` = `nsec*2048` = 4096, the post-`out+12` repack length,
   and dumps the returned bytes; `result` is `_i4CPSA_Inst_Decrypt`'s return)
5. `LADDER f MEASURED lba=510 nsec=2 decrypt via ioctl 5304`

**The single line that proves the unblock is (3) followed by (5).** (2) alone
only proves the TZ leg was reached — which the stale-stub run could never
print at all. If (2)/(3) appear and (5) does not, the completion event was
raised but something *after* the wait (`_vGCPU_HWRes_Release`, `GCPUMemoryFree`,
the worker's `_vGCPU_SendCmdExecFinish`) broke. The next evidence to collect is
the rate-limited assert summary line: `_vGCPU_WaitCmdExec`'s own
`Assert("0", gcpu_main.c:0x16f=367)` and `_vGCPU_WaitCmdExecFinish`'s
`gcpu_main.c:0x136=310` are the two post-wait post-conditions, so a
`Assert xNNNNNN total (last: src/driver/gcpu/gcpu_main.c:367)` at the tail of
the log names the failing one. (`ev_wait` prints are NOT usable here — the stub
prints only the first four calls plus every 256th, and those four were spent at
boot.)

**Secondary prediction (cheap, same fire):** `[GCPU]: HW Res obtain retry`
must stay absent — it would mean a second GCPU instance found the busy byte
still set, i.e. `_vGCPU_HWRes_Release` was skipped on some earlier path.

---

## 6. Residual risk / OPEN

1. **`_hGcpuSema` is created with count 1 by our `x_sema_create` and is taken
   with `down()` at `i4GCPU_CmdExec+0x44`.** If any path ever posts a command
   from inside a GCPU handler (there is none on the decrypt path), it would
   self-deadlock. Not hit in C109 (`mq_send` proves the lock was held and
   released), listed as the next-most-likely blocker for future command work.
   *OPEN.*
2. **`x_crit_start`/`x_crit_end` keep a *global* depth counter and a global
   spinlock.** The worker holds it across the whole handler, including
   `kmalloc(GFP_KERNEL)` inside `GCPUMemoryAlloc`. It has not produced a
   "scheduling while atomic" report in C109 (none in the log), but it is a
   latent wedge. *OPEN (pre-existing, unchanged by this fix).*
3. **The `tZ` data leg is still a Level-0 identity transform.** The fix unblocks
   the ioctl; it does not make `sacd510.dec` correct beyond
   `memcpy(dst,src)`. `_i4GCPU_SACDDEC` never touches a key — the secure world
   would — so an identity transform is the honest ceiling until a key schedule
   exists. *By design.*
4. **Only slot 0 is exercised.** `gcpu_cmd_complete()` reads record 0 only
   (matching `_GCPU_IrqHandle`'s own `get_hw(0)`). A future multi-instance
   configuration would need the slot plumbed through `TzServiceCall`, which the
   ABI does not carry (`params+0x18` is the request block, whose `+0x00` byte is
   the HW-resource id — the only slot-ish hint available). *OPEN, not needed
   for the current rig.*

---

## 7. Reproduce

```sh
# annotated disassembler used throughout (/tmp/bdx.py): capstone + pyelftools,
# R_ARM_ABS32 literal resolution through the reloc symbol's section, branch
# names from .symtab
python3 /tmp/bdx.py bdpdrv.ko --sym i4GCPU_CmdExec             # §2.1
python3 /tmp/bdx.py bdpdrv.ko --sym _vGCPU_MainLoop            # §2.2
python3 /tmp/bdx.py bdpdrv.ko --sym _i4GCPU_SACDDEC            # §2.3
python3 /tmp/bdx.py bdpdrv.ko --sym _vGCPU_WaitCmdExec         # §2.4
python3 /tmp/bdx.py bdpdrv.ko --sym _i4GCPU_Hal_CB             # §2.4
python3 /tmp/bdx.py bdpdrv.ko --sym _u1GCPU_HWRes_Obtain       # §2.3
python3 /tmp/bdx.py bdpdrv.ko --sym _GCPU_IrqHandle            # §2.5
python3 /tmp/bdx.py bdpdrv.ko --sym _GCPU_InitIsr              # §2.5
python3 /tmp/bdx.py bdpdrv.ko --sym i4GCPU_HAL_SetMISC_Cmd     # §2.3
python3 /tmp/bdx.py bdpdrv.ko --callers i4LockDecryResource    # 3 sites only
python3 /tmp/bdx.py bdpdrv.ko --callers _u1GCPU_HWRes_Obtain   # 1 call site (SACDDEC)
python3 /tmp/bdx.py bdpdrv.ko --callers _vGCPU_WaitCmdExec     # 65 command handlers
python3 /tmp/bdx.py bdpdrv.ko --callers x_ev_group_set_event   # event-group writers

# the log evidence (in-tree copy = the VM capture, cmp-clean)
cd evidence/bx510-guest/bdpdrv
grep -n 'mq_send\|mq_recv\|i4LockDecry\|tz:\|HW Res obtain\|Oops' bdpdrv-runC109.uart.log
sed -n '2192,2194p;2291,2296p' bdpdrv-runC109.uart.log

# the provenance check (§1.2)
make vm-exec CMD='md5sum /tmp/bx510_osal_stub.c'      # 9d3dfd05… = pre-C106
git show HEAD:tools/bx510_osal_stub.c | md5sum            # 532f1834… = what ran-pre-fix should have been
md5sum tools/bx510_osal_stub.c                           # 967cc21b… = canonical + this fix
make vm-pull-file FILE=/tmp/osal_b/stub_part_b.c DEST=/tmp
grep -n 'TzServiceCall' /tmp/stub_part_b.c            # { STUB_ONCE(); return 0; }
```

---

## 8. Corrections to earlier docs

| doc | statement | correction |
|---|---|---|
| `gcpu-connect-path.md` §3.3 | the 0x806 chain ends `… → TzServiceCall → "the result the whole chain reports"` | the chain continues: after `i4GCPU_HAL_SetMISC_Cmd` returns, `_i4GCPU_SACDDEC` calls **`_vGCPU_WaitCmdExec`** (`0x171634`) and blocks on the event group `inst+0x0c` until the GCPU *interrupt* fires `_i4GCPU_Hal_CB`. The Tz leg is necessary but not sufficient — the completion event is the missing counterparty. |
| `gcpu-connect-path.md` §2.4 | "A command is satisfied by three guest-side effects, all inside bdpdrv" (success bit, `+0x10` event, `CmdExec` return) | those three are the *ioctl's* satisfaction; the *handler's* satisfaction needs a fourth: the `+0x0c` event from `_i4GCPU_Hal_CB`. Without it the worker never reaches step 1. |
| `gcpu-connect-path.md` §4.2 B6 | "The driver pre-seeds `params+0x34 = 0x67000000`, so 'do nothing' already reads as success" | true for the *HAL result*, and it is exactly why the hang looked like a silent success: the HAL result is positive, the handler takes the `rc >= 0` branch, and dies in the wait. "Success" is not "completed". |
| `sacdread-cpsa.md` §0.6 / §4.3 | "the model cannot be 'answered' by a register reply" | still true, and now sharper: there is nothing to answer — the missing party is an *event*, not a register. No model change is needed at all. |
| the C109 brief's observation | "no mq_send, no mq_recv, no tz svc line — blocked before the send" | the `mq_send #5 w0=0x806` is in the log (line 2292, **before** the `i4LockDecryResource` line); the worker consumed it as its already-blocking `mq_recv #14` (line 2193, `h0=c6378eb0` — same queue handle), so no *new* `mq_recv` print is owed. The absent `tz:` line is explained by the stale stub (§1.2). |
| `tools/bx510_osal_stub.c` TZ block | `TzServiceCall` delivers the decrypt | it delivers the *data*; it must also deliver the **completion** (`gcpu_cmd_complete()`), or every GCPU command handler that waits parks forever. |

---

## 9. Provenance

| input | identity |
|---|---|
| `bdpdrv.ko` | sha256 `6604f6cd6c204c3399ac047f389f47162b06a3f6576159f21b4e8aaf3a72cf54`, 8,122,068 B, ELF32 ARM `ET_REL`; `.text` 3,266,588 B |
| `sacd_read.ko` | sha256 `b3d7a383e45d3bbe1a987a4a2e15ab7a68dd55e88d0319f7a0fd2e9cf0246dfa` (unchanged; not needed — the decrypt handler never blocked) |
| rig console | `evidence/bx510-guest/bdpdrv/bdpdrv-runC109.uart.log` = `VM:/tmp/bdpdrv-runC109.uart.log` (`cmp` identical), 195,403 B / 3,408 lines; quotes verbatim |
| stub source that RAN | `VM:/tmp/bx510_osal_stub.c` md5 `9d3dfd05b95c525cd2dc1c36cdbe8fa0`; built `VM:/tmp/osal_b/bx510_osal_stub.ko` 2026-11-13 17:25 |
| stub source (canonical, at run time) | `HEAD:tools/bx510_osal_stub.c` md5 `532f18342b8be153226b50287c7bc929`, commit `ed40006` — already had the dispatcher |
| stub source (canonical + this fix) | `tools/bx510_osal_stub.c` md5 `967cc21b6966aada959b515e45afbb7c` (`gcpu_cmd_complete()` at `:352`, call at `:393`) |
| tools | pyelftools 0.33, capstone 5.0.7 (ARM, detail on), `/tmp/bdx.py` (§7) |
