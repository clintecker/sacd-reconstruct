# `sata_mt85xx_mod.ko` bottom-half control flow, buffer arming, and the message
# sequence that can put 512 IDENTIFY bytes in front of libata

Decode of `_sata_mt85xx_svoif_interrupt_handler` (`sata .text+0x4540`),
`_sata_mt85xx_hw_chg_st` (`+0x3fc0`), `sata_mt85xx_qc_issu_task` (`+0x6c94`),
`sata_mt85xx_data_xfer` (`+0x5434`), `sata_mt85xx_exec_command` (`+0x5b28`),
`sata_mt85xx_qc_prep` (`+0x2ed4`), `sata_mt85xx_qc_issue` (`+0x3628`) and
`svoif_mt85xx_interrupt` (`+0x346c`) against `/tmp/bdpdrv/sata_mt85xx_mod.ko`,
cross-read with `libata.ko` (`ata_dev_read_id`, `ata_sff_hsm_move`) and the C98
trace facts in the brief.

**Address convention / reproduction.** All `sata` addresses are section-relative
(`.text+0x…`, `.init.text+0x…` for the second block). Every cited site is a real
instruction in:

```
/opt/homebrew/opt/llvm/bin/llvm-objdump -dr sata_mt85xx_mod.ko   > sata_rel.dis
/opt/homebrew/opt/llvm/bin/llvm-objdump -dr --section=.text libata.ko > libata_rel.dis
```

`-dr` matters: without relocation records ~30 % of the call targets read as
`bl <self> @ imm = #-0x8`, and the tail call that posts the mailbox command
(`0x5ca8`, `R_ARM_JUMP24 _svoif_mt85xx_send_ata_cmd`) is invisible to a
`R_ARM_CALL`-only search — that is how earlier docs concluded "nothing in the
module posts the 0xa1". It does: `exec_command` does, as a tail call.

**Corrections to earlier docs are listed in §7.**

---

## 0. Bottom line

1. **The "bottom half" is a work item, not a thread**: `qc_issu_task` calls
   `queue_delayed_work(drv_wq, priv+0x2e8, 0)` (`+0x7158..+0x7164`) and the
   work function is `_sata_mt85xx_svoif_interrupt_handler` (installed as that
   work item's `work.func`, `priv+0x2f4`, by `.init.text+0xab4/0xac4` — struct
   decode in §1.0). It enters with
   `priv = arg - 0x2e8` (`+0x4544`) and **blocks in a full
   `wait_event_interruptible(priv+0x2e0, priv+0x22c != 0)`**
   (`prepare_to_wait` `+0x45d0`, `schedule` `+0x45c0`, `finish_wait` `+0x45e8`),
   woken by the IRQ top half's `__wake_up(priv+0x2e0,1,1,0)` (`+0x3540`).
2. **It consumes exactly ONE status-block message per queueing, then returns.**
   After a message is handled the tail is
   `cmp r9,#0 ; beq 0x4578 (loop back to the wait)` (`+0x46c4..+0x46d4`,
   repeated at `+0x4794..+0x47a4`), where `r9 = *(priv+0x2dc)` (`+0x454c/0x4558`)
   and `priv+0x2dc` is the in-flight `qc` pointer stored by
   `qc_issue` (`+0x3668`) — the **only** writer of that field in the module, and
   there is no clear anywhere. `*(qc) = qc->ap` is never NULL, so the loop-back
   is dead in practice and the tail
   `+0x46d8..+0x4748` (`disable_irq` → libata `port_intr` → `enable_irq` →
   `pop`) returns. C98 confirms this empirically: the type-0x10 message's
   pending bit was drained by the top half, `__wake_up` fired, and the status
   block was **never** read again.
   ⇒ **Two messages per qc cannot work. Only the first one is ever read.**
3. **Also collapsing**: the top half latches `priv+0x22c |= (pending & mask)`
   (`+0x34f0/0x34f4`) — a single bit-16 — and records per-drain ring entries in
   `priv+0x234[priv+0x230]` (`+0x350c/0x3510`, 8 slots). The worker reads only
   the OR'd bit and **never reads the ring** (only a debug print at `+0x491c`
   touches it). So two messages posted before one block read become one bit and
   one block read, whose contents are the *last* message the model wrote.
4. **The branch that skipped the block read for message P is not in the type
   dispatch at all** — it is the missing worker. Message P's block read was
   skipped because the worker was already past `finish_wait` (`+0x45e8`) and
   inside `ata_sff_port_intr`/`ata_bmdma_port_intr` (`+0x4830`/`+0x48e0`), and
   its next act was to return (`+0x4748`). The dispatch branches that *could*
   skip a payload do exist and are named in §1.5 (they were not the cause here):
   `+0x4674/0x4680` (state ∈ {0,5}) is only reachable for **type 0**, and
   `+0x47ec` (the `priv+0x48 == 0` drop) would have *acked* the message —
   C98 shows no ack post, so the payload never entered the dispatch at all.
5. **Who arms `priv+0x4c` / `priv+0x54`: `qc_issu_task`, i.e. the per-qc delayed
   work queued by `qc_issue` — not `qc_prep`, and only *after* the qc is issued.**
   `+0x6cdc` arms the byte count, `+0x6ce0` zeroes the offset, `+0x6de8`/`+0x6f70`
   arm the 16-byte-aligned bounce buffer; `+0x6f04` re-arms both for the READ-CD
   rewrite. `data_xfer` only **decrements** them (`+0x5528/+0x55a4`). The mailbox
   post happens *inside* the same `qc_issu_task` run, one call deeper:
   `ata_bmdma_qc_issue` → libata → driver `exec_command` →
   `hw_chg_st(priv,1)` → tail call `send_ata_cmd(priv)` (`+0x5c9c..+0x5ca8`).
   The bottom-half work is queued **after** that, at `+0x7158`.
6. **The sequence that can actually feed libata is constrained to one
   status-block message read per qc, and that single message cannot supply both
   the bytes and the DRQ** (§3.1): the only writer of the 512 bytes is the
   type-0x10 branch (`+0x4878`, needs `priv+0x48 == 1` and `priv+0x54 == 0x200`,
   both true from `qc_issu_task` `+0x6cdc`) and the only state advance to DRQ is
   the type-0 branch (`hw_chg_st(priv,2)` `+0x46b8`). Recommended C99: **drop
   the completion and post only the payload** (§3.3-A) — that satisfies the data
   requirements and turns the state question into a measured `err_mask=0x2` /
   `ST_FIRST` result instead of an inference; §3.3-B/C are the follow-ups if
   that shows the state gate blocks the data phase.

---

## 1. The bottom half, in full (`_sata_mt85xx_svoif_interrupt_handler`, `+0x4540`)

### 1.0 Where the handler and the wait queue come from (struct decode)

`.init.text+0xa6c..0xacc` initialises two `struct delayed_work`s and one
`wait_queue_head_t` in one object (`r7` there = call it `B`). The handler's own
prologue gives `priv = arg - 0x2e8` and `B = priv - 0x20`; with
`struct work_struct = {data; entry.next; entry.prev; func}` (0x10 bytes) plus a
`struct timer_list` at +0x10, every init store lands on a work field:

| init store | lands at | is |
|---|---|---|
| `+0xa94 [B+0x2d0]=0` | `priv+0x2b0` = work.data | dwork #1 |
| `+0xa78/0xa7c [B+0x2d4/2d8]=B+0x2d4` | `priv+0x2b4/2b8` = INIT_LIST_HEAD(entry) | dwork #1 |
| `+0xa88 [B+0x2dc]=&qc_issu_task` | `priv+0x2bc` = work.func | **dwork #1 = `qc_issu_task`** — queued by `qc_issue +0x3678`, and `qc_issu_task` subtracts 0x2b0 at `+0x6c98` ✓ |
| `+0xa8c/0xa98 init_timer_key(B+0x2e0)` | `priv+0x2c0` | dwork #1 timer ✓ |
| `+0xa9c..0xaa4 __init_waitqueue_head(B+0x300, B+0x340)` | `priv+0x2e0` = **wait_queue_head** (name buffer `priv+0x320`) | the queue `__wake_up +0x3540` and `prepare_to_wait +0x45d0` use ✓ |
| `+0xac8 [B+0x308]=0` | `priv+0x2e8` = work.data | dwork #2 |
| `+0xaac/0xab0 [B+0x30c/310]=B+0x30c` | `priv+0x2ec/2f0` = INIT_LIST_HEAD(entry) | dwork #2 |
| `+0xac4 [B+0x314]=&_sata_mt85xx_svoif_interrupt_handler` | `priv+0x2f4` = work.func | **dwork #2 = this bottom half** — queued at `+0x7164`, `priv = arg-0x2e8` at `+0x4544` ✓ |
| `+0xacc init_timer_key(B+0x318)` | `priv+0x2f8` | dwork #2 timer ✓ |

Two consequences earlier docs read the other way: `priv+0x314` is **not** a
function pointer (that is `priv+0x2f4`) — it is a guard field, cleared at
`+0x709c` and tested at `+0x714c`, that nothing ever sets, which is why
`qc_issu_task` re-queues the bottom half unconditionally; and `priv+0x2dc` gets
its `&qc_issu_task` value from `work.func`, not from a store to `priv+0x2dc`
(the only writer of `priv+0x2dc` is `qc_issue`).

### 1.1 Prologue and the wait gate

```
4540  push {r4-r11,lr}
4544  r4 = r0 - 744                      ; priv = &dwork(priv+0x2e8) - 0x2e8
4548  r8 = &ide_log_en
454c  r3 = [r4+0x2dc]                    ; ★ priv+0x2dc = the in-flight qc
4558  r9 = [r3]                          ; ★ r9 = *(qc) = qc->ap  (decides loop vs return)
4574  r7 = sp+0x38                        ; r7 = &{w0,w1,w2,w3}
4578  r2 = [r4+0x22c]                    ; ★ the latched IRQ/message bitmask
457c  cmp  r2,#0 ; bne 0x45ec            ; work available → consume it
      ; ---- wait_event_interruptible(&priv[0x2e0], priv[0x22c] != 0) ----
4590  r1 = &autoremove_wake_function  (pool .init → autoremove_wake_function)
4598  r6 = r4+736                        ; ★ wait_queue_head at priv+0x2e0
45d0  prepare_to_wait(r6, r7, TASK_INTERRUPTIBLE=1)
45d4  if ([r4+0x22c] == 0) → 45ac : if (signal_pending) → 490c (finish_wait+return);
45c0                                  schedule()
45e8  finish_wait(r6, r7)
45ec  ---- critical section (cpsid i) ----
4604  r6 = [r4+0x22c] ; 4608 [r4+0x22c] = 0     ; ★ consume the whole latch
4628  tst r6, #0x10000                          ; ← bit16 = "status block has a message"
462c  moveq r0, r11 (=0) → 4794                 ; no bit16 → nothing to do
```

`priv+0x2e0` is a `wait_queue_head` (initialised in §1.0), `priv+0x22c` is the
latch. `__wake_up` at `+0x3540` is the other end.

### 1.2 The status-block read (the only read in the module for an IRQ message)

```
4638  r3   = 0xfd05cfff                     (pool 0x4ae4)
4640  [sp+0x38] = [r3-0xfbf] = 0xfd05c040   ; w0
464c  [sp+0x3c] = [r3-0xfbb] = 0xfd05c044   ; w1  (DRAM-window offset)
4654  [sp+0x40] = [r3-0xfb7] = 0xfd05c048   ; w2  (length)
465c  [sp+0x44] = [r3-0xfb3] = 0xfd05c04c   ; w3
4664  tst  [ide_log_en],#4 → 0x4a5c (byte-dump printk), then falls to 4668
```

Reachability of `0xfd05c040..04c` in the whole module (exhaustive, base
`0xfd05cfff` has only 12 users): `chk_int_ldr` `+0x28b8..0x28d8`,
`port_start` `+0x3394`, and this handler `+0x4640..0x465c`. Nothing else.

### 1.3 Type dispatch

```
4668  r3 = byte[r7+2]        ; ★ message TYPE = byte2 of w0
466c  cmp r3,#0 ; bne 0x47ac ; type != 0 → the 0x10 payload path (§1.5)
      ; ---- type 0 = completion/status message, byte3 = status code ----
4674  r3 = [r4+0x220]        ; ★ privacy: hw state (hw_st)
4678  if (r3 == 0) → 474c    ; state 0 → "unhandled" (log ring + port_intr)
4680  r3 = [r4+0x220]
4684  if (r3 == 5) → 474c    ; state 5 = error → "unhandled"
468c  r3 = [r4+0x48]         ; ★ direction (qc_prep / qc_issu_task field)
4690  if (r3 == 1) → 48ec     ; see §1.4: BSP_InvDCacheRange(priv+0x4c, priv+0x54)
4698  r3 = byte[r7+3]        ; status code
469c  if (r3 != 0) → 488c    ; hw_chg_st(priv, 5)   → state 5 (ERR)
46a4  r1 = [r4+0x48]         ; ★ re-read direction; r1 is the hw_chg_st argument
46a8  if (r1 == 0) → 483c    ; hw_chg_st(priv, r1) with r1 == 0  → state 0
46b0  r0 = r4 ; r1 = 2
46b8  hw_chg_st(priv, 2)     ; ★ SUCCESS advance: state → 2 (RDY|DSC|DRQ)
```

**Answer to "which hw_chg_st variant runs for type 0 / byte3 = 0":**

| condition (`priv` fields) | site | call | resulting `priv+0x220` |
|---|---|---|---|
| `priv+0x220 ∈ {0,5}` | `+0x467c`/`+0x4688` → `+0x474c` | none (log path) | unchanged |
| `byte3 != 0` (any direction) | `+0x46a0` → `+0x488c` | `hw_chg_st(priv, 5)` | 5 (status `0x51`, ATA error) |
| `byte3 == 0`, `priv+0x48 == 0` | `+0x46ac` → `+0x483c` | `hw_chg_st(priv, 0)` (r1 was proven 0 by the `cmp`) | 0 (status `0x50`, no DRQ) |
| `byte3 == 0`, `priv+0x48 != 0` (1 or 2) | `+0x46b4` → `+0x46b8` | `hw_chg_st(priv, 2)` | **2 (status `0x58` = DRDY\|DSC\|DRQ)** |

`priv+0x48` for the IDENTIFY qc is **1**, not 0 and not 2 — decoded, not inferred:
`ata_dev_read_id` builds `tf.protocol = 2` (`libata +0x3c20..0x3c24`, the ATAPI
branch `+0x3d6c..+0x3d74` jumps back to it) and `tf.flags |= 0x46`
(`+0x3c34`, ISADDR|DEVICE|LBA, **bit3/IO16 clear**); `qc_prep` stores
`priv+0x38 = protocol` (`+0x2ee8`), returns `priv+0x48 = 0` only for protocol ∈
{1,5} (`+0x2ef4..+0x2efc`), else `priv+0x48 = (tf.flags & 8) ? 2 : 1`
(`+0x2f04..+0x2f18`) ⇒ **1**. This also proves `data_xfer`'s ATAPI branch
(`+0x546c..+0x5484`, needs protocol ∈ {5,6,7}) is *not* on the IDENTIFY path,
which is why the 512-byte copy at `+0x554c` is what runs.

### 1.4 What `+0x48ec` actually is (the `priv+0x48 == 1` "queue path")

```
48ec  r0 = [r4+0x4c]        ; bounce buffer
48f0  r1 = [r4+0x54]        ; remaining byte count
48f4  bl  BSP_InvDCacheRange       (reloc: R_ARM_CALL BSP_InvDCacheRange)
48f8  b   4698
```

It is **not** a queue and it does not touch the data pointer: it invalidates
`priv+0x54` bytes at `priv+0x4c` — the "the device DMA'd into my buffer, drop the
stale cache lines" step for a device→host transfer — and then continues into the
`byte3` test at `+0x4698`. Consequence for the model: on the *completion*
message the driver invalidates the bounce buffer, i.e. the driver's design
expectation is that the payload is already there when the completion is read.

### 1.5 The type-0x10 payload path, and the three drop branches

```
47ac  cmp r3,#16 ; bne 0x474c      ; any type other than 0x10 → "unhandled"
47b4  r1 = &svoif_int_ldr_dram     (pool 0x4af0)
47b8  r3  = [sp+0x40]              ; w2 = length in bytes
47bc  r12 = [r4+0x54]              ; ★ priv+0x54 = remaining/destination length
47c0  r2  = [r4+0x48]              ; ★ direction
47c4  r6  = *svoif_int_ldr_dram    ; DRAM base (0xdfc00000 in C98)
47c8  r1  = [sp+0x3c]              ; w1 = offset
47cc  cmp r12,r3
47d0  movlo r10,r12 / movhs r10,r3 ; ★ copy_len = min(priv+0x54, w2)   ← 0 if disarm
47d8  cmp r2,#1  ; beq 0x4850      ; dir == 1  → FE→host
47e4  cmp r2,#2  ; beq 0x48a4      ; dir == 2  → host→FE
47ec  ; ---- dir == 0: DROP ----
47f0  bl  _svoif_mt85xx_send_table_data_ack_cmd(priv)   (R_ARM_CALL)
47f4  uxtb r3, r11 ; 47f8 b 0x4794

4850  (dir==1) if ([ide_log_en] & 4) printk
485c  if (*(mt85xx_svoif_reserve_base_remap) == 0) → 48fc (extra InvDCacheRange(src,len))
486c  r1 = r6  (= dram + w1)
4870  r0 = [r4+0x4c]
4874  r2 = r10
4878  bl  memcpy                    ★★ THE ONLY WRITE OF THE 512 IDENTIFY BYTES
487c  r0 = [r4+0x4c] ; r1 = r10
4884  bl  BSP_CleanDCacheRange
4888  b   0x47ec                    ; → ack the message, then 0x4794

48a4  (dir==2) r0 = r6 ; r1 = [r4+0x4c] ; r2 = r10 ; memcpy(DST=FIELD, SRC=bounce)
48b0..48d8  memcpy(dram+w1, priv+0x4c, len) [+ BSP_FlushDCacheRange]  ; host→FE
48dc  b 0x47ec
48fc/4904  extra BSP_InvDCacheRange(dram+w1, len) then 0x486c
```

So for every payload message the driver **acks it** by posting
`w0 = 0x00100000` (`_svoif_mt85xx_send_table_data_ack_cmd` `+0x3c50/0x3c58`:
`mov r3,#16 ; strb r3,[sp+0x3a]` = type byte2 = 0x10, all args 0, then the
doorbell `|= 1` at `+0x3cb0..+0x3cb4`). **A payload message that reached the
dispatch therefore always leaves an ack post in the trace.** C98 has none after
the payload drain ⇒ the payload never reached `+0x47ac` at all (§1.6).

### 1.6 Tail: loop vs return — why C98's payload block read never happened

```
46bc  r11 = 1
46c4  cmp r9,#0
46c8/46cc  r3 = (r9 != 0)
46d4  beq 0x4578        ; r9 == 0 → back to the wait gate (next message)
46d8  disable_irq(priv+0x4 + 18)
46e4  r3 = *(r9 + 0x13b8)                  ; selected port/device index (<=31 test)
46f4..4728  sanity checks on that entry → 472c (enable_irq; return) on failure
47fc..4830  ATA device class == 3 or 7 → ata_bmdma_port_intr(r9)
            else                       → ata_sff_port_intr(r9)     (48e0)
472c  enable_irq(priv+0x4 + 18)
4744/4748  add sp ; pop {…,pc}             ★★ RETURN — the work item is done
```

`r9 = *(priv+0x2dc)`; `priv+0x2dc` is written **only** at `qc_issue +0x3668`
(the qc pointer). There is no clear anywhere, so after the first `qc_issue`
`r9 = qc->ap ≠ 0` for the life of the module ⇒ **the handler never loops; every
queueing of the work item consumes one message and returns.**

Both tails (`+0x4794..+0x47a4` for the payload path, `+0x46c4..+0x46d4` for the
type-0 path) make the same `r9` decision and land on the same `+0x46d8` block.

⇒ **C98 explanation (decoded):** message C (type 0, byte3 = 0) was drained by
the one and only work-item invocation for the IDENTIFY qc. The handler read the
block once (`+0x4640`), advanced the state via `hw_chg_st(priv, 2)` (`+0x46b8`),
then took the `r9 != 0` tail and called libata's `port_intr` (`+0x4830`). While
it was in there, the model posted message P; the top half drained it (`R 05c800`,
`R/W1C 05c804=0x10000`, `R/W1C=0`) and `__wake_up` found **no waiter** — the
handler had already left the queue at `finish_wait` `+0x45e8`. The handler then
returned at `+0x4748`. `priv+0x22c` stayed `0x10000` and the block read for P
never happened. `priv+0x54` being armed or not was irrelevant: the message was
never dispatched.

### 1.7 `_sata_mt85xx_hw_chg_st` (`+0x3fc0`) — the state machine

Signature `hw_chg_st(priv /*r4*/, new /*r5*/)`. Only writer of `priv+0x220`
anywhere in the module (`str r5,[r4,#0x220]` at `+0x4070` — store scan).

```
3fd4  if ([ide_log_en] & 0x80) printk(hw_st: old → new)
3fe0  r3 = [r4+0x220]
3fe4  if (r3 == new) → 0x4074  ★ NO-OP RULE: equal state → return, no side effects
3fec  if (new == 2) → 0x4180   ; ATAPI-aware "data phase" entry
3ff4  r3 = (new == 0 || new == 5)     ; "reset-ish" states
4004  if (!r3) → 0x4020
4008  if ([r4+0x8] != 1) *0xfd00a208 = 0     ; mode 0: clear the a-window status
4020  r2 = [r4+0x38] - 5              ; protocol ∈ {5,6,7} = ATAPI?
402c  if (r2 > 2) → 0x4030 (non-ATAPI) else → 0x407c (ATAPI)
4030  if (!r3) → 0x4070               ; non-ATAPI, new ∉ {0,5} → just store
4038  r0 = [r4+0x5c] ; [r4+0x50] = 0 ; if (r0) {kfree unless == [r4+0x60] ; [r4+0x5c]=0}
4070  [r4+0x220] = new                ★ THE STORE
4074  return
407c  if (!r3) → 0x4070               ; ATAPI, new ∉ {0,5} → store only
4084  ... CDB-opcode special cases for new == 2 (below)
```

**`new == 2` path (`+0x4180`), the one the IDENTIFY completion takes:**

```
4180  r3 = [r4+0x38] - 5 ; cmp #2
418c  [r4+0x50] = 0                    ; clear the DMA/physical view
4194  if (protocol ∉ {5,6,7}) → 0x3ff4 (generic → store 2)
4198  r2 = [r4+0x24]                   ; ★ priv+0x24 = CDB/arg blob pointer
41a0  switch (r2[0]) {                 ; CDB opcode
        0x46 ('F' GET CONFIGURATION), r2[1]==1:
            [r4+0x18] = buf[6]<<8 | buf[7]; cache_alloc(1536 or 128)
        0x52 ('R' READ DISC INFO):     parse buf[8..11], buf[0x18..0x1b] → [r4+0x20]
        0xf0, r2[1]==0xe0:             _sata_tray_status = buf[7]
        default:                       → 0x3ff4 }
```
For the IDENTIFY qc `priv+0x38 == 2` (protocol = ATA_PROT_PIO), so the ATAPI
switch is skipped and the generic store runs: `priv+0x220 = 2`.

**Resulting status byte** (`check_status` mode-1 map, `+0x5e04..+0x5e50`, decoded,
not inferred):

| `priv+0x220` | status returned | site |
|---|---|---|
| 1 or 4 | `0xd0` (BSY\|DRDY\|DSC) | `+0x5ea4 mov r4,#208` |
| 2 or 3 | `0x58` (DRDY\|DSC\|**DRQ**) | `+0x5eec mov r4,#88` |
| 5 | `0x51` (RDY\|ERR) | `+0x5e3c/0x5e40` |
| other | `0x50` | `+0x5e3c movne r4,#80` |

and `priv+0x38 != 1` / `priv+0x8 == 1` gate the whole mode-1 map at `+0x5d1c`.

### 1.8 The `+0x474c` "unhandled" branch (state ∈ {0,5}, or type ∉ {0,0x10})

```
474c  if ([ide_log_en] & 1) printk(…, latch)          ; +0x4960
4758  r2 = [r4+0x230]                                  ; ring write index
475c..4788  for i < index: if (log) printk of [r4+4*i+0x234]
4790  r3 = r11  → 0x4794
```
i.e. log-and-ignore, then the same `r9` tail. It does **not** match and it does
not consume the block; a message that lands here is silently dropped after a
UART line that only appears with `ide_log_en` bit0 set (it is not set — KEXP
shows `cdrom_log_en=no`, and `ide_log_en` bit0 prints did not appear in C98).

---

## 2. Who arms `priv+0x4c` / `priv+0x54`, and when

### 2.1 Exhaustive writer list (store scan over `.text`)

| field | writers | meaning |
|---|---|---|
| `priv+0x4c` | `+0x6b2c` (`cache_check`), `+0x6de8`, `+0x6e08`, `+0x6f70`, `+0x72f8`, `+0x734c`, `+0x74e4` (all `qc_issu_task`) | bounce-buffer pointer, 16-byte aligned |
| `priv+0x54` | `+0x5528`, `+0x55a4` (`data_xfer`), `+0x6b30` (`cache_check`), `+0x6cdc`, `+0x6f04`, `+0x72fc` (`qc_issu_task`) | remaining byte count |
| `priv+0x58` | `+0x5510/0x552c/0x5598` (`data_xfer`), `+0x6ce0` (`qc_issu_task`) | offset inside the bounce buffer |
| `priv+0x48` | `+0x2efc`/`+0x2f14`/`+0x2f18` (`qc_prep`), `+0x4f24`/`+0x4f64` (`softreset`), `+0x51c0` (`prereset`) | direction: 0 = none, 1 = FE→host, 2 = host→FE |
| `priv+0x220` | `+0x4070` (`hw_chg_st`) only | hw state |
| `priv+0x2dc` | `+0x3668` (`qc_issue`) only, never cleared | the in-flight qc pointer |

`qc_prep` (`+0x2ed4..+0x2f1c`) does **not** touch `priv+0x4c/0x54` — it only
stores `priv+0x38` (protocol) and `priv+0x48` (direction).

### 2.2 `qc_issu_task` (`+0x6c94`) — the per-qc arming, in order

Entry: `r4 = arg - 688 = priv` (`+0x6c98`), so the work item is the
`delayed_work` at `priv+0x2b0`, and `r5 = priv+0x2dc = qc` (`+0x6ca0`).

```
6cc0  r3 = [qc+0x58]                ; qc byte-count field (0 ⇒ no data stage)
6cc8  if (r3 == 0) → 0x72f4:  [priv+0x5c]=0 ; [priv+0x4c]=0 ; [priv+0x54]=0
                              ⇒ DISARMED (0x72f4/0x72f8/0x72fc)
6ccc  r2 = [qc+0x4c] ; 6cd0 r3 = [qc+0x50]
6cd8  r3 = r2 - r3
6cdc  [priv+0x54] = r3              ★★ ARM the byte count        (512 for IDENTIFY)
6ce0  [priv+0x58] = 0               ★★ ARM the offset
6ce4  r2 = [qc+0x3c] ; 6ce8 r6 = [qc+0x70]      ; SG walk
6d34..6da0  iterate sg_next() accumulating the DMA address/length to r9/r8
6db4  if ([priv+0x54] & 15) → 6dbc, else → 0x7348
6dbc  r1 = [priv+0x60]              ; cached buffer?
6dc0  if (r1 != 0) → 0x6e00:  [priv+0x5c] = r1 ; [priv+0x4c] = r1   ★ REUSE
6dc8  else: r1 = 32 (GFP flags) ; r0 = [priv+0x54] + 16
6dd0  __kmalloc(len+16)             ; 
6dd4  r1 = (r0 + 15) & ~15          ; 16-byte align
6de4  [priv+0x5c] = r0 (raw) ; 6de8 [priv+0x4c] = r1 (aligned)      ★★ ARM
6e0c  if ([priv+0x54] > 75776) → 0x6f9c (bail + log)
6e1c  if ([priv+0x48] == 2) → 0x71f8           ; host→FE path
6e28  if ([priv+0x38]-5 <= 2) → 0x6e38        ; ATAPI CDB path
6e9c  (READ-CD rewrite) if ([priv+0x18] ∈ {8,9,10} && cdb[0] ∈ {0x28,0xa8})
6ebc    cdb[0] = 0xbe ; 6ef4 r2 = 2352
6efc    r3 = 2352 * [priv+0x30]
6f04    [priv+0x54] = r3             ★★ RE-ARM = 2352 * sectors
6f08..6f70  realloc/reuse the bounce buffer for the new size
6fcc  [priv+0x1c] = 0                 ★ gate for the single-shot memcpy in data_xfer
7044  [priv+0x80] = 0
704c  memcpy(priv+0x24_dst, qc->cdb /*qc+0x24*/, 12)    ; the arg blob
705c  memcpy(qc->cdb, priv+0x24, 12)                     ; (copy-back, same bytes)
706c  if ([priv+0x4c] == 0) → 0x709c
7078  if ([priv+0x48] == 1) → 0x7114 (r2 = min([priv+0x54],16) → tail padding)
7084  else BSP_FlushDCacheRange(priv+0x4c, priv+0x54)
7090  [priv+0x50] = [priv+0x4c] + 0x40000000   ; phys() view = phys of the buffer
709c  [priv+0x314] = 0                          ★ clears the bottom-half guard
70a4  if (qc->tf.protocol == 7) → 0x7188        ; ATAPI DMA start
70d0  r0 = qc
70d4  bl  ata_bmdma_qc_issue(qc)
        └─ libata → driver sff_tf_load (mode 1 shadow) + sff_exec_command:
           exec_command +0x5b68..+0x5b80: protocol ∈ {1..4} → hw_chg_st(priv,1)
           exec_command +0x5c9c..+0x5ca8: → TAIL CALL _svoif_mt85xx_send_ata_cmd(priv)
                                         = the mailbox post (w0 byte3 = [priv+0x29c])
70f4  if ([priv+0x8] == 1) → 0x714c
714c  if ([priv+0x314] != 0) → return
7158  r1 = priv + 0x2e8
7160  r0 = drv_wq
7164  queue_delayed_work(drv_wq, priv+0x2e8, 0)   ★★ START THE BOTTOM HALF (once)
```

**Answers to §2 of the brief, precisely:**

* Does the issu task run per command? **Yes** — `qc_issue` stores the qc
  (`+0x3668`) and `queue_delayed_work(drv_wq, priv+0x2b0, 0)` (`+0x3678`) for
  every qc, and `qc_issu_task` subtracts 0x2b0 (`+0x6c98`) so it *is* that work
  item. There is no other path into it.
* Does it set `priv+0x54` before or after posting the mailbox command?
  **Before.** `priv+0x54`/`priv+0x58`/`priv+0x4c` are armed at
  `+0x6cdc/0x6ce0/0x6de8` (or `+0x6f04/0x6f70`), the post happens three calls
  deeper at `+0x70d4 → exec_command +0x5ca8`, and the bottom-half work is queued
  after that at `+0x7164`. So for the IDENTIFY qc, **`priv+0x54 == 0x200` and
  `priv+0x48 == 1` are already true when the 0xa1 post hits the wire.**
* Does it run for the IDENTIFY qc (or only CDB commands)? **For every qc**,
  including IDENTIFY. For protocol 2 it takes the `+0x6e28 →` non-ATAPI branch,
  copies the CDB blob, does the read-direction cache op, and issues
  (`+0x70d4`). The 2352-byte re-arm (`+0x6f04`) is the CDB/READ-CD case only.
* `data_xfer +0x5528/+0x552c`: **not arming.** They are the sector-loop
  accounting for the 2352-byte path: `[priv+0x54] = K*[sectors] + [priv+0x54]`
  with a negative constant (pool `+0x5ad8`) i.e. *decrement*, and
  `[priv+0x58] = 2352*sectors + [priv+0x58]`; when the count reaches 0 the
  driver calls `hw_chg_st(priv)` (`+0x55ac/0x55b0`). The single-shot path
  decrements at `+0x5594..+0x55a4` (`[priv+0x54] -= buflen`,
  `[priv+0x58] += buflen`) and does the same `hw_chg_st(priv)` at
  `+0x55a8/0x55ac` when it reaches 0. **`data_xfer` never *increases* them.**

### 2.3 `data_xfer`'s read path and its gates

```
5434  data_xfer(dev, buf /*r11*/, buflen /*r6*/, rw /*r3, unused on this path*/)
5448  r8 = dev->link->ap ; 5464 r4 = *(*(ap+0x1dfc)+0xc) = priv
546c  if ([priv+0x38]-5 <= 2 && [priv+0x220] == 3) → 0x55b8   ; ATAPI CDB post path
5488  r3 = [priv+0x48] ; if (r3 == 0) → 5534 : return buflen  ★ NO COPY at all
5494  r3 = [priv+0x5c] ; if (r3 == 0) → 558c : advance counters only, NO COPY
54a0  r3 = [priv+0x1c] ; if (r3 == 0) → 554c
54ac  else → 2352-byte sector loop (priv+0x1c != 0)
554c  r3 = [priv+0x4c] ; r1 = [priv+0x58] + r3 ; r2 = buflen
5560  memcpy(libata_buf, priv+0x4c + priv+0x58, buflen)      ★★ what libata validates
558c  [priv+0x58] += buflen ; [priv+0x54] -= buflen ; if (![priv+0x54]) hw_chg_st(priv)
```

**So there are three ways for libata to get stale bytes**, and C97/C98 hit one of
them: `priv+0x5c == 0` (counters advance, buffer untouched — the buffer keeps
whatever the previous cycle left, which is exactly how two EH cycles can see
different `id[0]` values), `priv+0x48 == 0` (return 512 without copying), or the
`priv+0x4c` contents never having been written by the payload path.

---

## 3. The correct model protocol

### 3.1 The requirement set (each one decoded)

| id | requirement | site |
|---|---|---|
| R1 | The 512 bytes must be written to `[priv+0x4c .. +0x200]` | `+0x4878` — and **only** there; nothing else writes that buffer |
| R2 | At that moment `priv+0x48 == 1` (FE→host) | `+0x47d8` (==2 goes the other way, ==0 drops) |
| R3 | At that moment `priv+0x54 == 0x200` and `priv+0x58 == 0` | armed by `qc_issu_task` `+0x6cdc/0x6ce0` |
| R4 | `priv+0x5c != 0` and `priv+0x1c == 0` when `data_xfer` runs | `+0x5494`, `+0x54a0` |
| R5 | When libata's HSM polls, `check_status` must return DRQ ⇒ `priv+0x220 ∈ {2,3}` | `+0x5eec`; state 2 only via `hw_chg_st(priv,2)` at `+0x46b8` |
| R6 | The payload message and the port_intr that drives the data phase must be in the same work-item invocation, with the state advance already visible | `+0x46d4`/`+0x4748` |

R3 and R5 are satisfied automatically at different times: R3 at issue, R5 only
after the completion is processed. **R1+R2 and R5+R6 cannot both be satisfied by
one status-block message**, because the writer (`+0x4878`) lives only in the
type-0x10 branch and the state advance (`+0x46b8`) only in the type-0 branch,
and the handler reads the block exactly once per invocation (§1.6).

### 3.2 What this rules out

* **H1 (completion then payload) — the C98 order — is wrong.** The completion
  is consumed, the state advances, `port_intr` runs, the HSM does the 512-byte
  `data_xfer` copy from an unarmed bounce buffer, and the payload is then
  latched and orphaned. This is exactly the observed C98 trace.
* **Payload then completion posted back to back is also wrong.** Both pending
  bits collapse into the one latch bit (`+0x34f0/0x34f4`) and the single block
  read sees only the **last** message written (`0x5c040..4c` is one register
  set, re-written per message) ⇒ the completion is what gets dispatched and the
  payload is silently overwritten. That is the C97 signature.
* **Any two-message scheme is wrong** while `priv+0x2dc` is never cleared: the
  second message is never read.

### 3.3 The sequences that satisfy R1–R6, ranked, with their observables

**(A) One message per qc: the type-0x10 payload only.** `w0 = 0x00100000`,
`w1 = <DRAM offset of the 512-byte table>`, `w2 = 0x200`, `w3 = 0`. No
completion.
* R1/R2/R3/R4 satisfied (the worker is started by `+0x7164` before the FE can
  reply, and `qc_issu_task` armed the buffer at `+0x6cdc`/`+0x6de8`).
* R5 then rests on `priv+0x220 == 1` (`exec_command +0x5b80`), which the
  mode-1 map turns into `0xd0` = **BSY, no DRQ**.
* Predicted: the driver **acks** the message (`W 05c000 = 0x00100000` + doorbell
  right after the drain — this post is the proof the payload branch ran), then
  libata's `__ata_sff_port_intr` (`libata +0x13ce4`) polls `check_status`, gets
  `0xd0` (BSY, no DRQ) and `ata_sff_hsm_move` (`libata +0x13578 → +0x139d0`)
  does `ata_ehi_push_desc("ST_FIRST: !(DRQ|ERR|DF)")` + `err_mask |= 2` ⇒
  `failed to IDENTIFY (I/O error, err_mask=0x2)` (§4.1).
* This is the **cheapest decisive experiment** (one variable: drop the
  completion) and it converts the §3.1 bind from inference to measurement.

**(B) Payload in one pass, completion in the next pass of the same qc.** Needs
the worker to loop past the first message. Blocked by `priv+0x2dc` never being
cleared (§1.6). Would become reachable only if a future model/trace shows
`priv+0x2dc == 0` (i.e. no `qc_issue` has ever run) or a second
`queue_delayed_work(priv+0x2e8)`. Observable that would falsify the block:
**two** `R 05c040/044/048/04c` quadruples inside one IDENTIFY qc window.

**(C) Payload carried over from an earlier qc.** `qc_issu_task` reuses a cached
buffer (`priv+0x60` → `priv+0x4c` at `+0x6dc0/+0x6e00`), so a payload copied
during an earlier pass survives into the next `qc_issu_task`. Protocol:
payload message in cycle N (phase (A), tolerated as an error), completion in
cycle N+1 (which is the EH retry of the same read). Observable: the *first*
IDENTIFY cycle prints `ST_FIRST: !(DRQ|ERR|DF)`, the *second* one succeeds with
`ATAPI: SONY …`.
* *INFERRED* — this depends on the cache reuse at `+0x6dc0` returning the same
  buffer (`priv+0x60` non-zero) and on `priv+0x4c` not being re-zeroed; settling
  step: the C99 trace showing either one or two `kmalloc`-driven arming paths (a
  `[IDE]<sata_mt85xx_qc_issu_task>ch:…buf:` line, needs `ide_log_en` bit1)
  and, in the (B)/(C) case, whether `priv+0x4c` differs between cycles.

**(D) Deliver the payload outside the status block.** The driver computes
`priv+0x50 = virt_to_phys(priv+0x4c)` at `+0x7090` but in mode 1 it is never
sent to the FE (only `send_ata_cmd`'s taskfile words go out, `+0x3ac0..+0x3b30`).
*INFERRED* to be unusable without a model-visible address. Not recommended.

### 3.4 The recommendation for C99

1. **Drop the completion message** for the IDENTIFY qc; post only the type-0x10
   payload with `w1` = the DRAM-window offset holding the byte-exact §3.3 table
   of `id-validity-check.md` and `w2 = 0x200`. This makes the single read the
   driver performs be the payload read and satisfies R1–R4.
2. Expect and capture the `ST_FIRST: !(DRQ|ERR|DF)` line. Its presence proves
   §1.6 + R5 (`state 1 → 0xd0`); its absence means `check_status` produced DRQ
   and the payload will have reached libata (then read the dmesg line).
3. **Never post two messages for one qc** until a trace shows two block
   quadruples (variant B). If both are needed, they must be separated so that
   the payload is *read* and the completion is left pending for the next
   `qc_issu_task` (variant C).

---

## 4. Expected observable for C99

### 4.1 UART (variant A)

```
[IDE]<sata_mt85xx_prereset>ch:0, deadline:0x… start
[IDE]<sata_mt85xx_prereset>ch:0 end
[IDE]<sata_mt85xx_softreset>ch:0 start
[IDE]<sata_mt85xx_softreset>ch:0 end, class=3
ata1.00: failed to IDENTIFY (I/O error, err_mask=0x2)   ← ★ new: 0x2, not 0x0
ata1.00: ST_FIRST: !(DRQ|ERR|DF)          ← ★ new: the ehi desc for the DRQ-less poll
```

`err_mask` changing from `0x0` (C97/C98) to `0x2` is the cleanest single
observable. `0x0` was the *validity* path — `ata_dev_read_id` initialises it to 0
(`libata +0x3b98`) and only `ata_do_dev_read_id`'s return value or the
`mov r6,#128` at `+0x3d5c` write it; the `id[0]` check never does. `0x2` is
`AC_ERR_HSM`, set by `ata_sff_hsm_move`'s `!DRQ` branch:
`libata +0x139d0 tst r7,#33` (ERR|DF) → not set →
`+0x139e4 ata_ehi_push_desc(ehi, "ST_FIRST: !(DRQ|ERR|DF)")` and
`+0x139f4 orr r3,#2 ; str r3,[qc+0x74]` (qc->err_mask |= 2).

Note the exact string is pushed into the EH **description**, not printed with a
device prefix itself (`.rodata.str1.4+0x2b9c` = `"ST_FIRST: !(DRQ|ERR|DF)"`, no
`%sata%u.%02u` prefix), so it appears in the EH report block rather than as its
own dmesg line — grep the UART for `ST_FIRST` and for `err_mask=0x2`, either
form is decisive.

A second, independent check on the same run: the `device reports invalid type`
and `unsupported CDB len` lines must be **absent** (they require libata to have
validated a payload, i.e. `err_mask == 0`).

If variant C is right, the second cycle additionally shows
`ata1.00: ATAPI: SONY    BDPSACDEMUL, 1.00, max UDMA/33` and
`ata1.00: configured for UDMA/33`, with the first cycle still printing the
`ST_FIRST` error.

### 4.2 MMIO signature (in order, per IDENTIFY qc)

1. `W 05c000/004/008/00c = 0xa1000000 / 0 / 0x0000a000 / 0`, `R 05c020`,
   `W 05c020 = 1` — the post from `exec_command`'s tail call (`+0x5ca8`);
   `w2 = 0x0000a000` is `{lba2 = 0x00, device = 0xa0}` from
   `priv+0x290`/`priv+0x294` (`send_ata_cmd +0x3af8/0x3afc`).
2. `R 05c800` → `0x10000`; `R 05c804` → `0x10000`, `W 05c804 = 0x10000`;
   `R 05c804` → `0`, `W 05c804 = 0` — the top-half drain (`+0x34b0..0x34c8`).
   **Note the trailing `W = 0`: it is unconditional at `+0x34c0` and is not a
   second message.**
3. `R 05c040/044/048/04c` **exactly once** — the single block read (`+0x4640`).
4. **`W 05c000 = 0x00100000`, `W 05c004/008/00c = 0,0,0`, `R 05c020`,
   `W 05c020 = 1`** — the payload ack from `+0x47f0`. **This is the decisive new
   line: it can only be produced by the type-0x10 branch having run.**
5. **No** second `R 05c040/044/048/04c` quadruple, and **no** `R 05c800`/
   `R/W1C 05c804` pair after it (nothing is left pending).
6. Then, if variant C: the retry posts a second `0xa1`, drains one more block,
   and this time libata's `data_xfer` runs against an armed `priv+0x4c`;
   the 512-byte copy produces no MMIO at all (it is a `memcpy` from the bounce
   buffer, `+0x554c`) — so **the absence** of a mailbox post between the block
   read and the UART line is what a *successful* data phase looks like.

The single most diagnostic pair: **ack post present + `err_mask=0x2`** = the
payload was dispatched but the state gate blocked the data phase;
**ack post absent** = the message never reached `+0x47ac`, i.e. the worker was
not listening (which is the C98 failure mode). **Ack post present + `err_mask=0x0`
+ a validated-but-wrong table** = the payload was copied but `priv+0x4c` was
re-armed between the copy and the `data_xfer` (variant C territory).

---

## 5. Certainty ledger

**DECODED (instruction level):** every site cited above, in particular
— the handler is a work item whose `work.func` is `priv+0x2f4`
(`.init.text+0xac4`) and is queued by `qc_issu_task` (`+0x7158..+0x7164`) with
`priv = arg - 0x2e8` (`+0x4544`); the struct decode of §1.0 (two delayed works
plus one wait queue at `priv+0x2b0/0x2e0/0x2e8`); the `wait_event_interruptible` expansion
(`+0x45d0`/`+0x45c0`/`+0x45e8`); the single latch consume (`+0x4604/0x4608`);
the one-and-only block read (`+0x4640..0x465c`); the type/state/direction
dispatch (`+0x4668..+0x46b8`); the three payload branches and their shared ack
(`+0x47ac..+0x4888`, `+0x47f0`); the loop-vs-return decision and the fact that
`priv+0x2dc` has exactly one writer and is never cleared; `hw_chg_st`'s
no-op-on-equal rule and single store (`+0x3fe4`, `+0x4070`); the mode-1 status
map (`+0x5e04..+0x5e50`); `qc_prep`'s direction rule (`+0x2f04..+0x2f18`);
`qc_issu_task`'s arming order (`+0x6cdc` → `+0x6de8` → `+0x70d4` → `+0x7164`)
and its disarm path (`+0x72f4..+0x72fc`); `exec_command`'s `hw_chg_st(priv,1)`
and its tail call to `send_ata_cmd` (`+0x5b80`, `+0x5ca8`); `data_xfer`'s
three no-copy exits and its one copying memcpy (`+0x5490/0x549c/0x54a0`,
`+0x554c`); libata's `tf.protocol = 2` / `tf.flags = 0x46`
(`libata +0x3c20..+0x3c38`, `+0x3d6c..+0x3d74`).

**INFERRED (labelled):**
* `priv+0x2dc` being the qc and hence `r9 = qc->ap` — the store at `+0x3668` is
  `qc_issue`'s argument, and `*(qc)` is `ap` per the driver's own use of
  `[r9+0x13b8]`, but the field's *name* is inferred.
* The struct names (`priv+0x220` = hw state, `priv+0x4c` = bounce buffer,
  `priv+0x48` = direction) — the *offsets and behaviours* are decoded, only the
  identifiers are inferred.
* Variant C (buffer carried across an EH retry) — depends on `priv+0x60` cache
  reuse; settling step in §3.3.
* Whether libata's `ata_sff_pio_task` (`in_wq = 1`) or the IRQ-context
  `port_intr` performs the `data_xfer` call. Decoded: `__ata_sff_port_intr`
  (`libata +0x13ce4`) calls `ap->ops->sff_check_status` and then
  `ata_sff_hsm_move` in the *same* context, so with a DRQ status the copy is
  synchronous inside the worker's `port_intr` call; `ata_sff_hsm_move`'s
  `in_wq` compare (`libata +0x1344c → +0x138a8`) is only a `warn_slowpath_null`
  once-latch that falls through to the state dispatch (`libata +0x13454`).
* **The driver calls `ata_sff_port_intr(ap)` / `ata_bmdma_port_intr(ap)` with a
  single argument** (`+0x48e0`, `+0x4830`) while this libata's functions take
  `(ap, qc)` (`libata +0x141cc` tail-branches to `__ata_sff_port_intr(ap, qc,
  in_wq)`, and `ata_bmdma_port_intr` `libata +0x13e28` reads `r1` at once). The
  `qc` those paths then use is whatever `r1` happens to hold, so the *exact*
  DRQ/BSY verdict of the first poll is incident-dependent — which is precisely
  why C99 must measure (variant A) instead of predicting. The buffer-arming
  conclusions R1–R4 are not affected: they are pure memcpy/dispatch logic.

**Open, resolvable only by a run:**
1. Does `check_status` at the payload pass return `0xd0` (⇒ variant A prints
   `ST_FIRST`) or does something advance the state to 2 first? Settling step:
   C99 variant A (§3.3-A).
2. Does `priv+0x4c` survive from one `qc_issu_task` to the next? Settling step:
   set `ide_log_en` bit1 (`[IDE]<…qc_issu_task>ch:%d buf:0x%x len:0x%x`) and
   compare the printed buffer address across the EH retry.

---

## 6. Instruction-site index

| claim | site(s) |
|---|---|
| handler is a work item, `priv = arg-0x2e8` | `+0x4544`; queue at `+0x7158..+0x7164`; `work.func` installed `.init.text+0xab4/0xac4` = `priv+0x2f4` (§1.0) |
| wait_event on `priv+0x22c != 0`, wq at `priv+0x2e0` | `+0x4578..+0x45e8`; `__wake_up` `+0x3540`; `__init_waitqueue_head(priv+0x2e0)` `.init.text+0xa9c..0xaa4` |
| one latch consume, bit16 gate | `+0x4604`, `+0x4608`, `+0x4628`, `+0x462c` |
| the only IRQ-side block read | `+0x4638..+0x4660` (base `0xfd05cfff`, pool `+0x4ae4`) |
| type dispatch | `+0x4668..+0x4670`; `+0x47ac..+0x47b0` |
| state ∈ {0,5} skip | `+0x4674..+0x4688` → `+0x474c` |
| direction==1 cache invalidate | `+0x468c..+0x4694` → `+0x48ec..+0x48f8` |
| byte3 != 0 → state 5 | `+0x4698..+0x46a0` → `+0x488c..+0x4894` |
| no-arg (`=0`) vs arg-2 advance | `+0x46a4..+0x46b8` → `+0x483c/0x4840` and `+0x46b0/0x46b8` |
| loop vs return | `+0x46c4..+0x46d4`, `+0x4794..+0x47a8`, `+0x4744/0x4748` |
| `priv+0x2dc` writer (qc) and readers | `+0x3668`; `+0x454c`, `+0x4558`, `+0x6ca0` |
| struct layout: dwork#1 / waitqueue / dwork#2 | `.init.text+0xa6c..0xacc` (§1.0) |
| port_intr call sites + class gate | `+0x46d8..+0x4728`, `+0x47fc..+0x4834`, `+0x48e0/0x48e4` |
| driver passes only `ap` to `ata_*_port_intr` | `+0x4830`, `+0x48e0` vs `libata +0x141cc`, `+0x13e18`, `+0x13ce4` |
| payload copy_len = min(priv+0x54, w2) | `+0x47bc..+0x47d4` |
| the 512-byte payload memcpy | `+0x486c..+0x4884` |
| payload ack (type 0x10 out) | `+0x47f0`; `ack +0x3c50/0x3c58`, doorbell `+0x3cb0/0x3cb4` |
| `hw_chg_st` no-op + single store | `+0x3fe4`, `+0x4070` |
| `hw_chg_st` new==2 ATAPI path | `+0x4180..+0x41d4` |
| mode-1 status map | `+0x5e04..+0x5e50` (208/88/81/80; `+0x5ea4`, `+0x5eec`) |
| `qc_prep`: protocol + direction | `+0x2ee8`, `+0x2ef4..+0x2efc`, `+0x2f04..+0x2f18` |
| `qc_issue`: store qc + queue issu task | `+0x3668`, `+0x3670..+0x3678` |
| `qc_issu_task`: arm len/offset/buffer | `+0x6cdc`, `+0x6ce0`, `+0x6de8`, `+0x6e08`, `+0x6f70`, `+0x734c`, `+0x74e4`; disarm `+0x72f4..+0x72fc` |
| `qc_issu_task`: 2352 re-arm | `+0x6ef4..+0x6f04` |
| `qc_issu_task`: phys() view | `+0x7090` |
| `qc_issu_task`: issue + start bottom half | `+0x70d4`, `+0x709c`, `+0x714c..+0x7164` |
| `exec_command` mode-1 post | `+0x5b54..+0x5b80`, `+0x5c9c..+0x5ca8` (`R_ARM_JUMP24 send_ata_cmd`) |
| `send_ata_cmd` word layout | `+0x3ac0..+0x3b30`, doorbell `+0x3b4c..+0x3b60` |
| `data_xfer` no-copy exits / the copy | `+0x5490`, `+0x549c`, `+0x54a0`, `+0x554c..+0x5560`, decrement `+0x558c..+0x55a4` |
| libata: protocol 2 + flags 0x46 | `libata +0x3c14..+0x3c38`; ATAPI branch `+0x3d6c..+0x3d74` |
| libata: class-3 id check | `libata +0x3cb8/0x3cc0` |
| libata: `!DRQ` in ST_FIRST | `libata +0x13578 → +0x139d0` (err `AC_ERR_HSM`) |
| top half latch/ring | `+0x34d4..+0x3510` |

---

## 7. Corrections to earlier docs

1. **`fe-ata-cmd.md` §1.3 / §3.3 / §9 item 1** — "`exec_command` tf->command cached
   only" and "which builder posted C95 cmd#3 is INFERRED, perhaps outside the
   module": **wrong on both counts.** `exec_command` mode 1 ends in a *tail call*
   (`+0x5ca8`, `R_ARM_JUMP24`, invisible to a `R_ARM_CALL` scan) to
   `_svoif_mt85xx_send_ata_cmd(priv)` after `hw_chg_st(priv,1)`
   (`+0x5b80`). The `0xa1` post is fully inside the module: it is
   `exec_command → send_ata_cmd`, over the qc's taskfile, for protocol ∈ {1..4}.
   That is also why the post's `w2 = 0x0000a000` matches `send_ata_cmd`'s
   `{priv+0x290, priv+0x294}` layout and *not* `data_xfer`'s CDB blob.
2. **`fe-ata-cmd.md` §2.2 / §5.3** — "`type 0x10` … memcpy … else → hw_chg_st(priv)
   and drop" — the `else` (direction 0) branch actually calls
   `send_table_data_ack_cmd(priv)` (`+0x47ec/0x47f0`), i.e. **it acked the message
   it dropped**, and so does the successful copy path (`+0x4888`). Every payload
   message the worker dispatches produces a visible `W 05c000 = 0x00100000` ack.
3. **`fe-ata-cmd.md` §5.2 / `id-validity-check.md` §5 – H1** — "post the type-0
   completion first, then the type-0x10 payload" is **disproved by C98**: the
   driver's bottom half is a work item that consumes one status-block message per
   queueing and then returns (§1.6), so the second message is never read.
4. **`fe-ata-cmd.md` §2.2** — the `0x468c` "queue the argument/data path" label is
   wrong: `+0x48ec` is `BSP_InvDCacheRange(priv+0x4c, priv+0x54)` (a cache
   invalidate), not a queue.
5. **`fe-ata-cmd.md` §5.1 row 9 / top-half description** — `queue_work` is
   actually `__wake_up(priv+0x2e0, 1, 1, 0)` (`+0x3540`); the "bottom half" is a
   *work item that blocks in wait_event*, not an unconditional work callback.
   There are two delayed works, told apart by their `work.func` slots:
   `priv+0x2bc` = `qc_issu_task`, `priv+0x2f4` = this handler (§1.0).
   Advertising `priv+0x314` as "the handler pointer" (any earlier note) is
   wrong — that field is the re-queue guard.
6. **`id-validity-check.md` §5's store-scan conclusion** ("`priv+0x4c`/`priv+0x54`
   written only in data_xfer, qc_issu_task, cache_check") is confirmed; what it
   missed is that **`data_xfer` only decrements them** and that
   `qc_issu_task` reuses a cached buffer (`priv+0x60`), which is what makes the
   payload survive across cycles (variant C).
7. **`fe-ata-cmd.md` §3.3** — `w1/w2/w3 = 0` as the `chk_int_ldr` discriminator
   still holds, but note `send_ata_cmd` also clears `priv+0x22c`/`priv+0x230`
   right before the post (`+0x3b10/0x3b14`), which is why the first drain after
   an issue always starts from a clean latch.
