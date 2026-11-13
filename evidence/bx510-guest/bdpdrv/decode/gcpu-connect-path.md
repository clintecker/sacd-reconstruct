# The CPSA Connect path: what `i4CPSA_Inst_Connect` actually does

Date: 2026-11-13. Static decode (Mac-side, no VM) of `bdpdrv.ko`'s CPSA/GCPU
Connect leg, answering the four questions in the C106 stage brief so a
C-implementer can stop guessing where `SACDREAD cmd=0x40105301
result=-402653184` (0xE8000000) comes from.

**House rules.** **VERIFIED** = read out of an instruction, a literal-pool
word resolved through its relocation, or a symbol/relocation table entry, with
the function and offset cited; every row below is re-derivable with the
commands in §8. **INFERRED** = reasoned from those facts, labelled. **OPEN** =
not closed in this time-box, with the exact next probe.

Binary: `evidence/bx510-guest/artifacts/bdpdrv.ko`, sha256
`6604f6cd6c204c3399ac047f389f47162b06a3f6576159f21b4e8aaf3a72cf54`,
8,122,068 B, ELF32 ARM `ET_REL` with a 42,036-entry symtab. Module load base
from the C104 console: `i4CPSA_Inst_Connect` at `0xbf0e09d8` = `.text+0x559d8`
⇒ **base = 0xbf089000** (every address below is `.text`-relative; add the base
to get the runtime VA).

---

## 0. Bottom line

1. **Connect does not talk to TrustZone. Not one SMC, not one MMIO access.**
   `i4CPSA_Inst_Connect` (`0x559d8`) checks the instance slot and calls
   `i4CPSA_Inst_Create` (`0x54724`). Create allocates a 0x44-byte CPSA
   instance, brings up a GCPU instance (thread + queue + 3 event groups), then
   does **two interface-manager lookups** and one indirect call. There is no
   literal-pool word in either function that is not a string, a `.bss` address
   or a small constant. *VERIFIED (§1.1).*
2. **The GCPU half already works in the rig.** The C104 console shows
   `[OSAL_STUB] thread created: GcpuHw0 fct=_vGCPU_MainLoop` immediately
   *before* `[SACDREAD]i4CPSA_Inst_Connect Fail:-402653184`, i.e.
   `i4GCPU_InstanceCreate` returned its success code `0x67000000` — the
   instance, the 10-deep command queue and the three event groups all exist
   before the failure. *VERIFIED from the log + §2.1.*
3. **`0xE8000000` has exactly three producers inside Create** — `cpsa_main.c:852`
   (GCPU instance create), `:883` (interface *register*), `:895` (interface
   *query*). The log excludes `:852`. What remains is the **Im registry**, and
   the key the query asks for — peer type **0x168 (360)**, peer compid,
   op **0** — has **no registrar anywhere in bdpdrv**: all 19
   `i4ImRegisterInterface2` call sites were resolved (`r0` immediate or literal
   pool) and none uses 0x168, and no component descriptor in `.data` carries
   that type. *VERIFIED for the
   sites and the key; INFERRED that `:895` is the one that fires (§1.4 says why
   the second attempt must be `:883`).*
4. **So the acceptance string is a guest-side problem, not a model problem.**
   The minimal way to make Connect return `0x68000000` (1744830464) is to make
   the `(0x168, any-compid, 0)` Im entry exist before the ioctl, with a
   function-pointer slot that survives the indirect call. That is a handful of
   lines in the OSAL module (or a 40-line helper `.ko`), zero QEMU changes
   (§4.1, route A). *INFERRED but mechanically complete.*
5. **The decrypt leg (0x806) is a `TzServiceCall` — a kernel *symbol*, not an
   `SMC` instruction.** bdpdrv contains **no** `smc`/`smc #0` at all;
   `TzServiceCall` is `SHN_UNDEF` and is supplied by the platform module (today:
   our stub). Its ABI is `(handle, func_id, params|0x40000000, 0x40)` — the
   service id is **r1**, and the whole id table is decoded in §3.2. The current
   C106 stub dispatches on **r0** (the handle, always 1), so every call is
   currently answered by the `default:` arm. *VERIFIED (§3).*
6. **A no-op TZ stub is already sufficient for the decrypt leg to report
   success**: the HAL pre-seeds `params+0x34 = 0x67000000` and the driver reads
   that word back *after* the call — so a stub that returns without touching
   memory yields "success". Only the ciphertext itself needs real work.
   *VERIFIED (§3.4).*

---

## 1. Q1 — `i4CPSA_Inst_Connect`, instruction by instruction

### 1.1 The chain

```
sacd_read.ko  CPSA_SACDCmdEnable(compid=0)                 (sacd_read.ko .text+0x1a4)
  r0=0x16b  r1=compid  r2=360  r3=compid
  -> i4CPSA_Inst_Connect                     bdpdrv .text+0x559d8  (0x60 B)
       busy check on _au4CpsaInst[compid]    -> 0xE8000006
       -> i4CPSA_Inst_Create                bdpdrv .text+0x54724 (0x208 B)
            (a) i4GCPU_InstanceCreate       bdpdrv .text+0x173374      :852
            (b) i4ImRegisterInterface2      bdpdrv .text+0x127aac      :883
            (c) i4ImQueryInterface          bdpdrv .text+0x1279a8      :895
            (d) call  *(u32*)out1           (indirect, see §1.3)
            (e) i4ImReleaseInterface        bdpdrv .text+0x127940
            (f) *pHandle = inst ; return 0x68000000
```

`sacd_read.ko`'s exact argument words, `CPSA_SACDCmdEnable` at its `.text+0x1a4`:
`ldr r0,=0x16b` (pool word 0x16b), `mov r1,r5` (compid), `mov r2,#360`,
`mov r3,r5`, then `ldr pc,[r4,#0x20]` through its `.bss` symbol slot. *VERIFIED
(objdump of `original/sacd_read.ko`).*

### 1.2 What Connect itself does

`i4CPSA_Inst_Connect` (`0x559d8`, 0x60 B) is 12 instructions of bookkeeping:

| offset | instruction | meaning |
|---|---|---|
| `0x559dc` | `ldr r4,=0x11588(.bss)` | CPSA globals base |
| `0x559e0` | `add r4,r4,r1,lsl#2` | `&_au4CpsaInst[compid]` (table at `.bss+0x11590`) |
| `0x559e4` | `ldr r12,[r4,#8]` | current slot value |
| `0x559e8` | `cmn r12,#1` | free ⇔ `0xFFFFFFFF` |
| `0x559f0..0x55a04` | `Assert(cpsa_main.c:1881)` + `return 0xE8000006` | slot already owned |
| `0x55a08..0x55a10` | `add r12,sp,#12 ; str r12,[sp] ; bl i4CPSA_Inst_Create` | 5th arg = `&h` |
| `0x55a14..0x55a18` | `ldr r3,[sp,#0xc] ; str r3,[r4,#8]` | publish the instance |

No MMIO, no SMC, no queue. *VERIFIED.* Note the returned error is
`0xE8000006`, **not** `0xE8000000` — so the observed failure is inside Create.

### 1.3 `i4CPSA_Inst_Create` (`0x54724`, 0x208 B)

Registers in, from Connect: `r7`=0x16b (my type), `r6`=compid, `r8`=360 (peer
type), `r9`=compid (peer id), `[sp]`=`&h`.

| site | action | failure |
|---|---|---|
| `0x54730` | `ldrb r3,[r11]` — `i4CPSA_Init` ran? | `Assert(:826)` → `0xE8000004` |
| `0x54764` | out-pointer NULL? | `Assert(:831)` → `0xE8000002` |
| `0x54794` | `x_mem_alloc(0x44)` | `Assert(:840)` → `0xE8000007` |
| `0x547bc` | `i4GCPU_InstanceCreate(&_vCPSA_Inst_GCPU_CB, inst, &slotbyte)` | `Assert(:852)` → **`0xE8000000`** |
| `0x547ec..0x5483c` | fill instance: `+0x00 = 0x12043000` (magic), `+0x04 = my type`, `+0x06 = my compid`, `+0x08 = peer type`, `+0x0a = peer compid`, `+0x40 = GCPU slot byte`, `+0x10..+0x34 = 0xFFFFFFFF`, `+0x3c = 0`, `+0x38 = 0` | — |
| `0x54844..0x54858` | `i4ImRegisterInterface2(0x16b, compid, 1, &CPSA.api[0x18], inst)` | `Assert(:883)` → **`0xE8000000`** |
| `0x54884..0x5489c` | `i4ImQueryInterface(360, compid, 0, &out1, &out2)` | `Assert(:895)` → **`0xE8000000`** |
| `0x548c0..0x548d4` | `r3 = *(u32*)out1 ; r0 = out2 ; r1 = 0x16b ; r2 = compid ; blx r3` | return value ignored |
| `0x548d8..0x548e8` | `i4ImReleaseInterface(360, compid, 0)` | — |
| `0x548ec..0x548f8` | `*pHandle = inst ; return 0x68000000` | — |

The `&CPSA.api[0x18]` word handed to the registration is
`.bss+0x115a0` = `&_i4CPSA_Inst_SetInBandCmd`, because `i4CPSA_Init`
(`0x5458c`) writes the whole CPSA API vector into `.bss+0x11588+0x18…0x60`:
`+0x18 _i4CPSA_Inst_SetInBandCmd`, `+0x1c _i4CPSA_Inst_Decrypt`,
`+0x20 DecryptCPRM`, `+0x24 DecryptEx`, `+0x28 GetBDPlusOptionMode`, …,
`+0x60 i4CPSA_Inst_GetRealSampleSize`, and `+0x08..+0x14` = the four
`_au4CpsaInst[]` slots seeded with `-1`. *VERIFIED (`0x5458c..0x54694`, one
`ldr r2,=<symbol> / str r2,[r3,#imm]` pair per slot).*

### 1.4 The interface-manager step, and why 0x168 has no counterparty

`i4ImRegisterInterface2` / `i4ImQueryInterface` are 3-word-key table calls over
a single global list `_rImInfoList` at `.bss+0x76f40` (head at `+0`, end at
`+4`). Entry = 32 bytes from `pImAllocInfo` = `x_mem_alloc(0x20)`:

| entry field | written by | read by |
|---|---|---|
| `+0x00` next | `i4ImRegisterInterfaceImpl 0x127a88` | `pImFindInfo 0x127928` |
| `+0x04` **u16 type** | `0x127a5c strh r6` (arg0) | `0x1278fc ldrh; cmp r3` |
| `+0x08` **compid** | `0x127a68 str r5` (arg1) | `0x127908` (`0xFFFFFFFF` = wildcard) |
| `+0x0c` **op/mode** | `0x127a74 str r4` (arg2) | `0x12791c cmp r2` |
| `+0x10` arg3 = *address of a function-pointer slot* | `0x127a7c` | query `*out1 = [e+0x10]` |
| `+0x14` arg4 = context | `0x127a60` | query `*out2 = [e+0x14]` (or the return of the `+0x18` generator) |
| `+0x18` arg5 = generator hook | `0x127a6c` (0 from `…Interface2`) | called as `fn(type,compid,op)` if non-NULL |
| `+0x1c` arg6 = release hook | `0x127a78` (0 from `…Interface2`) | called by `i4ImReleaseInterface 0x127970` |

`i4ImRegisterInterfaceImpl` returns **-1** if the key already exists
(`0x127a44 mvnne r0,#1`) or the alloc fails (`0x127aa0`), **0** on success.
`i4ImQueryInterface` returns **-3** (`0x127a20 mvn r0,#2`) when the key is not
found. *VERIFIED.*

Registration vs query keys in Create (raw instruction words, so this is not a
disassembler interpretation):

```
0x54844 e1a00007  mov r0, r7    ; 0x16b   <- register key0
0x54848 e1a01006  mov r1, r6    ; compid
0x5484c e3a02001  mov r2, #1    ; op = 1
...
0x5488c e1a00008  mov r0, r8    ; 360     <- query key0
0x54890 e1a01009  mov r1, sb    ; compid  (r9)
0x54894 e1a02005  mov r2, r5    ; op = 0
```

So Create **registers itself** under `(0x16b, compid, 1)` and then **binds to a
peer component** under `(360, compid, 0)`. The peer is not incidental: CPSA's
own connection table declares it. `_rCPSAComp` (`.data+0x127a4`, header u32
`0x16b`, name string `"cps_agent"` at `.rodata.str1.4+0x2364`) points at
`_arCPSAConnTbl` (`.data+0x127ec`, size **0x30** = two 24-byte records — a free
cross-check on the stride), whose two records are
`{type=0x20 (32), …}` and `{type=0x168 (360), …}` — i.e. the component types
the CPSA component connects to. *VERIFIED.*

And **no one in bdpdrv registers type 0x168**: all 19
`i4ImRegisterInterface2` call sites were enumerated with their `r0` resolved
(§8), and the types used are 32, 33, 52, 64, 65, 68, 71, 390, 396, 0x16b and
`<dynamic>` — never 360. Nor does any `_r*Comp` descriptor in `.data` carry the
header 0x168 (full scan, §8). The only occurrences of 0x168 in `.data` are the
two connection-table records above. *VERIFIED.*

Consequences:

* **First INIT in a boot** fails at `:895` with `-3` → 0xE8000000, *after*
  leaving a GCPU instance and the `(0x16b, compid, 1)` registration behind
  (the failure path frees `inst` but calls neither `vGCPU_InstanceDestroy` nor
  `i4ImReleaseInterface`).
* **Every later INIT for the same compid** in that boot fails at `:883` with
  `-1` (duplicate key) — the same 0xE8000000. The C104 log shows exactly this
  signature: the first attempt created `GcpuHw0`, the second `GcpuHw1`
  (slot 0 leaked, so the scan moved on). This is the strongest evidence
  available without a re-fire, and it is also why **the decoding of "which
  assert line" matters**: it distinguishes "missing peer" from "duplicate
  registration". *VERIFIED for the two-attempt pattern; the per-attempt line
  attribution is INFERRED.*
* **`Disconnect` does not undo the `(0x16b, compid, 1)` registration.**
  `i4CPSA_Inst_Destroy` (`0x5492c`) queries `(inst+0x08, inst+0x0a, 0)` = the
  **peer** key and calls `i4ImReleaseInterface` on it — which only invokes
  `[e+0x1c]` if set, it does **not** unlink the record (`0x127970..0x127994`).
  So `daemon-wiring.md` §5.1's "gate INIT poisons the daemon" hazard has a
  second leg: even with the `0x40105305` uninit line, the daemon's own
  `Connect` still meets a duplicate `(0x16b, compid, 1)`. *VERIFIED for the code
  paths; INFERRED that no other path unregisters it (only
  `i4ImUnregisterInterface*`, which CPSA never calls).*

### 1.5 Answering "what makes it return -402653184 vs 0x68000000"

| return | site | condition |
|---|---|---|
| `0xE8000000` | Create `:852` | GCPU instance create < 0: no free GCPU slot (`0xE7000005`) or the global GCPU semaphore/queue/thread creation failed |
| `0xE8000000` | Create `:883` | Im register returned -1: **duplicate** `(0x16b, compid, 1)` (i.e. a previous Connect in this boot) or a 32-byte alloc failure |
| `0xE8000000` | Create `:895` | Im query returned -3: **no `(0x168, compid, 0)` peer registered** |
| `0x68000000` | Create `0x548f0` | all of the above succeeded; the indirect peer call's return value is ignored |
| `0xE8000006` | Connect `0x55a00` | `_au4CpsaInst[compid]` already owned (a *successful* Connect that was never disconnected) |

---

## 2. Q2 — the OSAL message-queue layer and the GCPU worker

### 2.1 `i4GCPU_InstanceCreate` (`0x173374`, 0x340 B) — what "thread created" proves

* Scans `_arGcpuInst` (`.bss+0xb18e4`) for the first of **11** records (stride
  **0x38**) whose `flags & 1` is clear; the record index becomes the instance
  handle. (`0x1733d0..0x173440`; `11*0x38 = 0x268`, and indeed `_hGcpuSema`
  sits at `.bss+0xb1b4c` = `_arGcpuInst+0x268` — a free cross-check of both the
  stride and the count. *VERIFIED.*)
* `x_ev_group_create(&h, "gcpuevent%d", 0)` → `inst+0x0c`;
  `…"gcpuevent1"` → `inst+0x14`; `…"gcpuevent2"` → `inst+0x10`. *VERIFIED.*
* `x_msg_q_create(&h, name, sizeof(GcpuCmdInfo)=12, GCPU_CMD_Q_SIZE=10)` →
  `inst+0x08`. *VERIFIED (`0x173528..0x173534`, `r2=#12`, `r3=#10`, assert
  string at `.rodata.str1.1+0x5a8fe`).*
* `x_thread_create(&h, "GcpuHw%d", stack=0x8000, pri=0x6e, _vGCPU_MainLoop,
  4, &slotbyte)` — `0x1735ac`; on failure it prints
  `"GCPU Instance Create Fail, Return Info %d, Instance Handel %d \n"` and
  asserts (`gcpu_main.c:1112`). *VERIFIED.*
* `x_mem_aligned_alloc(0x40, 0x80)` → `inst+0x28`; the failure path prints
  `"GCPU Instance Create Fail, Alloc Working Buffer Fail \n"` and then **falls
  through into the success return** (no branch around it) — a harmless dead
  error path. *VERIFIED (`0x173600..0x173640`).*
* Returns: `0x67000000` success (`0x173638`), `0xE7000005` no free slot
  (`0x173654`), `0xE7000007` reseved for the alloc path.

Record layout (`_arGcpuInst[i]`, 0x38 B, all offsets from the disassembly):

| off | field | evidence |
|---|---|---|
| `+0x00` | u32 state word: bit0 = record in use, bit1 = thread-exit request, bits 8/12/16/20/24/28 = command slots (see 2.3) | `0x1733d8/0x1733f8`, `0x174978`, `0x174150` |
| `+0x01` | u8 "command in progress" (polled by the loop between `x_crit_start/end`) | `0x174818` |
| `+0x04` | u32 spin counter (diagnostic) | `0x174844/0x174878` |
| `+0x08` | **msg-queue handle** `hMsgQ` | `0x173564`, used by `_fgGCPU_RetrieveCMD`/`_fgGCPU_SendCMD` |
| `+0x0c` | **event group** waited by `_vGCPU_WaitCmdExec` (mask 1, op 5 = OR_CONSUME) | `0x173e90` |
| `+0x10` | **event group** set by `_vGCPU_SendCmdExecFinish` (mask 1, op 3 = OR) | `0x173d94` |
| `+0x14` | **event group** set by `_vGCPU_SendCmdQue` (mask 1, op 3) | `0x173e40` |
| `+0x18` | u32 last state tag (0..12) — a pure trace aid, written on every branch | `0x1747c0..0x17492c` |
| `+0x1c` | completion callback (`_vCPSA_Inst_GCPU_CB` — **`bx lr`, a no-op**) | `0x1733fc`, `0x1748b4` |
| `+0x20` | callback context | `0x1733ec` |
| `+0x24` | u8 H/W-resource id, `0xFF` = none | `0x1735f8`, `_u1GCPU_HWRes_Obtain 0x173f1c` |
| `+0x28` | 0x40-byte aligned work buffer | `0x173600` |
| `+0x34` | u32 debug state mirror | `0x1747c4` etc. |

### 2.2 `_fgGCPU_RetrieveCMD` (`0x174008`) — what the C104 `mq_recv` line is

```
r0 = inst index, r1 = &GcpuCmdInfo (12 B, caller's stack)
local: u32 zMsgSize = 12 ; u16 idx ; stack args cnt=1, option=1
x_msg_q_receive(&idx, msg, &zMsgSize, &inst->hMsgQ /* .bss+0xb18ec = inst+8 */, 1, 1)
if (ret != 0) return 0                        ; error -> "no command"
if (zMsgSize != 12) Assert("zMsgSize == sizeof(GcpuCmdInfo)", gcpu_main.c:444)
return 1
```

*VERIFIED.* `option = 1` is `WAIT`, so with the OSAL stub's blocking
implementation the worker parks inside `x_msg_q_receive` — which is exactly the
C104 line `[OSAL_STUB] mq_recv #13 h0=c6378f28 cnt=1 caller=_fgGCPU_RetrieveCMD`
(a non-NULL queue handle ⇒ the queue was created; the count of 13 is the 13th
receive since boot). `_vGCPU_WaitCmdQue` (`0x173dcc`, event `inst+0x14`) is the
fallback for the non-blocking/error case. *VERIFIED for the code; the log line
mapping is VERIFIED against `tools/bx510_osal_stub.c:697`. *

### 2.3 `_vGCPU_MainLoop` (`0x174798`) — does it SMC, or post to hardware?

```
loop:
  if (inst->flags & 2) { inst->flags &= ~2; x_thread_exit(); }
  if (!_fgGCPU_RetrieveCMD(idx, &cmd)) { _vGCPU_WaitCmdQue(idx); continue; }
  if (cmd.op == 0xFFFFFFFF) -> same exit path
  _prGcpu_Hw_GetGCPUStruct(); inst->busy = 1 ; x_crit_start();
  rc = _i4GCPU_CmdHandle(idx, cmd.op & 0x00FFFFFF, cmd.param);
  if (rc >= 0) { set success bit; cb(rc, cmd.op, ctx); }
  else         { set error bit;  cb(...); }
  _vGCPU_SendCmdExecFinish(idx);  x_crit_end(); inst->busy = 0;
```

*VERIFIED (`0x174798..0x1749a0`).* **The worker does the "hardware" work
synchronously, in the calling thread, via `TzServiceCall` — it does not post to
any MMIO block.** There is no peripheral register in `_vGCPU_MainLoop`,
`_i4GCPU_CmdHandle`, or any `_i4GCPU_*_CmdHandle`: every effect leaves the CPU
as an SMC through the `TzServiceCall` import (§3). *VERIFIED for the worker
loop and the command dispatcher; the HAL layer is §3.*

Command dispatch is by the **second byte** of the opcode
(`_i4GCPU_CmdHandle 0x1746ac`, `and r3,r1,#0xFF00`):

| group | handler | | group | handler |
|---|---|---|---|---|
| `0x0000` | `_i4GCPU_CSS_CmdHandle` | | `0x0500` | `_i4GCPU_DES_CmdHandle` |
| `0x0100` | `_i4GCPU_CPPM_CmdHandle` | | `0x0600` | `_i4GCPU_BDRE_CmdHandle` |
| `0x0200` | `_i4GCPU_AES_CmdHandle` | | `0x0700` | `_i4GCPU_EF_CmdHandle` |
| `0x0300` | `_i4GCPU_VCPS_CmdHandle` | | **`0x0800`** | **`_i4GCPU_Misc_CmdHandle`** |
| `0x0400` | `_i4GCPU_AACS_CmdHandle` | | `0x0900` | `_i4GCPU_SEC_CmdHandle` |
| other | `Assert(gcpu_main.c:574)` → `0xE7000002` | | | |

`_i4GCPU_Misc_CmdHandle` (`0x171e70`) subtracts 0x800 and jump-tables on the
low byte: 0 `_i4GCPU_MEMCPY`, 1 `_i4GCPU_DMA`, 2 `SHA1`, 3 `MD5`, 4 `KPSET`,
5 `XOR`, **6 `_i4GCPU_SACDDEC`**, 7 `RC4_KSA`, 8 `RC4_64B0`, 9 `WMDRMPD_DEC`,
10 `SetKey2Slot`, 11 (last) `…`. So **`0x806` = MISC op 6 = `_i4GCPU_SACDDEC`**
(`0x17150c`). *VERIFIED (jump table at `0x171e84..0x171eb0`, each word a
`.text` ABS32 relocation to the named handler).*

### 2.4 What a "satisfied reply" looks like

There is no reply *message* on any queue for a command. The command is satisfied
by three guest-side effects, all inside bdpdrv:

1. the worker sets the per-command-slot success bit in `inst->flags`
   (`0x17490c`: `orr 3<<(slotbyte+1)` — bit `+1` = finished, bit `+2` =
   success; `CmdExec` tests bit `slotbyte+2` at `0x17424c`),
2. the worker calls `_vGCPU_SendCmdExecFinish` → `x_ev_group_set_event(inst+0x10, 1, OR)`,
3. `i4GCPU_CmdExec` returns `0x67000000` (`0x174258`) — or `0xE7000008` if the
   success bit is absent (`0x17426c`).

The only message ever put on a GCPU queue is the **command** (`x_msg_q_send` in
`_fgGCPU_SendCMD 0x17409c`, 12 bytes = `{op, param_ptr, slotbyte}`), and the
only sender is the driver itself. **A QEMU model cannot and need not inject
anything into these queues.** *VERIFIED.*

### 2.5 `i4GCPU_CmdExec` return codes (`0x1740bc`)

| code | offset | meaning |
|---|---|---|
| `0xE7000000` | `0x174128` | instance index > 10 |
| `0xE7000005` | `0x1741bc` | no free command slot (all six `flags` nibbles busy) |
| `0x67000000` | `0x174224` | fire-and-forget (`fgWait == 0`) |
| `0x67000000` | `0x174258` | waited, success bit set |
| `0xE7000008` | `0x17426c` | waited, success bit **not** set (prints `"i4GCPU_CmdExec CMD FAIL:%d %d, %d\n"`) |
| handler value | — | `_i4GCPU_CmdHandle`'s own rc is *not* returned once a wait was requested |

---

## 3. Q3 — the SMC leg

### 3.1 There is no `SMC` instruction in bdpdrv

`TzServiceCall` is `SHN_UNDEF` in `bdpdrv.ko`'s symtab and appears in **54**
`R_ARM_CALL` relocations in `.text` (§8). It is resolved at insmod time from
whichever module exports it — today `tools/bx510_osal_stub.c`. A scan of the
whole module for the `SMC`/`SMC #0` encodings finds none. **Therefore the QEMU
model has nothing to trap for the TZ leg on ARMv6/7 without EL3**: no guest code
ever executes an SMC. If we later want the secure world *inside* QEMU, the
clean seam is a new kernel module exporting `TzServiceCall`, not a CPU trap.
*VERIFIED (symbol table + relocation walk + encoding scan).*

### 3.2 The `TzServiceCall` ABI and the full service-id table

Every call site has the identical shape — the four words are a *handle*, a
**function id**, a params pointer, and a constant:

```
r0 = *(g_hSecureHandle)          ; the platform's TZ channel handle
r1 = <service id>                ; see the table below
r2 = <params block> | 0x40000000 ; NS-tagged pointer (ARM TrustZone NS bit)
r3 = 0x40 (64)                   ; block size / attribute word
```

Parameters are 0x38-byte blocks from `GCPUMemoryAlloc(0x38)`, pre-seeded at
`+0x34` with `0x67000000`, and the **return value is read back out of the
block**, not from r0. *VERIFIED (`i4GCPU_HAL_RegWrite 0x172358`,
`…RegRead 0x1724e4`-family, `…SetMISC_Cmd 0x172c10`, `…HAL_Init 0x17210c`).*

| id | caller | | id | caller |
|---|---|---|---|---|
| `0x03` | `i4GCPU_HAL_Init` | | `0x1a`/`0x1b` | `Set/GetEFUSE_Cmd` |
| `0x04` | `vGCPU_HAL_Uninit` | | `0x1c`/`0x1d` | `Set/GetKeyProtect_Cmd` |
| `0x05` | `i4GCPU_HAL_Reset` | | **`0x1e`/`0x1f`** | **`Set/GetMISC_Cmd`** |
| `0x0a` | `i4GCPU_HAL_ClrIntr` | | `0x23`/`0x24` | `SetSlotData` / `GetSlotData` |
| `0x0b`/`0x0c` | `Set/GetCSS_Cmd` | | `0x25`..`0x33` | `fgGcpuSwSec*` (RNG, hash, ECDSA, HMAC, AES128, Marlin, KB, CW, MCKey) |
| `0x0d`/`0x0e` | `Set/GetCPPM_Cmd` | | **`0x34`/`0x35`** | **`HAL_RegWrite`/`HAL_RegRead`** |
| `0x10`/`0x11` | `Set/GetAES_Cmd` | | `0x30` | `i4GCPU_Init` |
| `0x12`/`0x13` | `Set/GetVCPS_Cmd` | | `0x31` | `i4GCPU_Uninit` |
| `0x14`/`0x15` | `Set/GetAACS_Cmd` | | `0x36`..`0x3d` | `BSP_*` (bonding, IC version) |
| `0x16`/`0x17` | `Set/GetTDES_Cmd` | | `0x38`/`0x39` | `VSFHW_SramWrite/Read` |
| `0x18`/`0x19` | `Set/GetBDRE_Cmd` | | `0x3a` | `i4KmGetICEKey` |

*VERIFIED: every id above was extracted by scanning back for `mov r1,#imm`
before each `bl TzServiceCall` (script in §8); the function names are the
symtab owners of those call sites.*

**This is the correction the C106 stub needs**: it switches on `a0` (the
handle, always 1) instead of `a1` (the service id). The ids `0x16b` and `0x806`
in its `TZ_SVC_*` macros are not `TzServiceCall` ids at all — `0x16b` is a
*component type* and `0x806` is a *GCPU command opcode*. Neither ever reaches
`TzServiceCall`.

### 3.3 The 0x806 (SACD decrypt) path end to end

```
SACD_IOC_DECRYPT (0x40105304)
 -> CPSA_SACDCmdDecrypt(compid, in, out, 2064)                 (sacd_read.ko)
 -> _i4CPSA_Inst_Decrypt(inst, in, out, 2064)          .text+0x542b4
      dispatch on inst->+0x0c bit 0x40 -> inst->+0x28
 -> i4CPSA_SACD_Decrypt(ctx, src, dst, len)            .text+0x55d44
      magic 0x12043007 ; src/dst non-NULL ; **len == 2064 exactly**
      ctx->byte[4] must be non-zero (set to 1 by i4CPSA_SACD_Create)
      param = {src, dst, 2064} on the stack
      i4GCPU_CmdExec(ctx->byte[0x10] /*gcpu slot*/, 0x806, &param, 1)
 -> i4GCPU_CmdExec(slot, 0x806, p, 1)                  .text+0x1740bc
      allocate a command slot, x_msg_q_send({0x806, p, slotbyte}), wait
 -> _vGCPU_MainLoop -> _i4GCPU_CmdHandle -> MISC op 6
 -> _i4GCPU_SACDDEC(slot, p)                           .text+0x17150c
      blk = GCPUMemoryAlloc(0x9b8 /*2488*/)
      validate p = {src, dst, len}; len % 2064 == 0
      blk+0x00 = u8 _u1GCPU_HWRes_Obtain(slot)   (H/W resource id, 0xFF = busy)
      blk+0x04 = 0x80                            (opcode: SACD decrypt)
      blk+0x08 = src | 0x40000000
      blk+0x0c = dst | 0x40000000
      blk+0x10 = len / 2064                      (block count)
      blk+0x14 = len                             (bytes)
      i4GCPU_HAL_SetMISC_Cmd(blk)
 -> i4GCPU_HAL_SetMISC_Cmd(blk)                        .text+0x172c10
      q = GCPUMemoryAlloc(0x38); q+0x34 = 0x67000000; q+0x18 = blk | 0x40000000
      TzServiceCall(g_hSecureHandle, 0x1e, q | 0x40000000, 0x40)
      return q+0x34        <-- the result the whole chain reports
```

*VERIFIED at every step.* Note: **the secure world's job for 0x806 is to fill
`dst` from `src` per 2064-byte block and to leave a non-negative code at
`q+0x34`.** The 12-byte block header that `sacd_read.ko` strips
(`memcpy(buf+i*2048, out+12, 2048)`) is produced by that transform, i.e. it is
part of what the TZ side returns — consistent with `sacdread-cpsa.md` §4.3,
which could not see past the SMC.

Prerequisite: this whole chain needs a **successful Connect**, because
`sacd_read.ko`'s `CPSA_SACDCmdDecrypt` starts with
`GetInstHandleFromCompId(compid)` and passes the result straight into
`_i4CPSA_Inst_Decrypt`, whose first act is the instance magic check
(`0x12043000`, else `0xE8000002`). With Connect failed the handle is
`0xFFFFFFFF`. So route A (§4.1) gates the decrypt leg as well; conversely the
decrypt leg adds no requirement on top of it beyond the SMC (§4.2).
`_i4CPSA_Inst_Decrypt` itself returns `0xE8000000` when none of the family bits
(`0x02/0x04/0x08/0x10/0x20/0x40/0x100`) is set (`0x5437c`). *VERIFIED.*

### 3.4 A no-op stub already yields "success"

`i4GCPU_HAL_SetMISC_Cmd` writes `0x67000000` into `q+0x34` *before* the call and
reads it back *after*. `i4GCPU_HAL_Init` does not even read the block (it returns
its own pre-set `r5`). Therefore any `TzServiceCall` that returns without
touching the params block yields a positive HAL result, `_i4GCPU_SACDDEC`
takes its `rc >= 0` branch, the worker sets the success bit, and `CmdExec`
returns `0x67000000`. *VERIFIED (`0x172c38/0x172c60`, `0x172140/0x1721b8`).*

What a *faithful* reply changes is only the data: a Level-0 identity transform
in `dst` reproduces the guest's expectations for a fixture that already carries
plaintext frames; a Level-1 synthetic cipher needs the real key schedule, which
is a separate piece of work (`_i4GCPU_SACDDEC` itself does not touch the key —
it hands the whole block to the secure world).

---

## 4. Q4 — the model recipe

### 4.1 Route A (recommended): make the peer entry exist; no model change at all

| # | behaviour | why | verdict |
|---|---|---|---|
| A1 | Export `i4ImRegisterInterface2` reachable by kallsyms and make one record `(type=0x168, compid=0xFFFFFFFF, op=0, arg3=&fnslot, arg4=ctx)` exist **before** the ioctl | Create's query is keyed `(0x168, compid, 0)`; a compid of `0xFFFFFFFF` is the matcher's wildcard (`0x127908 cmn r12,#1`) | **VERIFIED** for the key, the wildcard and the matcher; the "register it ourselves" step is the recipe |
| A2 | `*(u32*)fnslot` must be the address of a function `int peer(void *ctx, u32 mytype, u32 mycompid)`; it is called once with `(ctx, 0x16b, compid)` and its return value is ignored | `0x548c0..0x548d4` | **VERIFIED** |
| A3 | The record's `+0x18`/`+0x1c` hooks may be left 0 (`i4ImRegisterInterface2` does exactly that) — Release and the generator call both NULL-check | `0x127a6c/0x127a78`, `0x1279e4`, `0x127974` | **VERIFIED** |
| A4 | Fire the INIT **once** per bdpdrv load, or reload bdpdrv between attempts | the `(0x16b, compid, 1)` self-registration is never unlinked ⇒ 2nd attempt gets `-1` at `:883` | **VERIFIED** for the code; INFERRED as the explanation of C104's second failure |
| A5 | Keep the existing `BX_BIM+0x154 → 0` answer and the generic 16 MiB window | `vSacdDecryptEnable` is called only on Disable, and its poll is already answered | **VERIFIED** (unchanged from `sacdread-cpsa.md` §4.1) |
| A6 | Nothing else: no MMIO window, no queue, no register, no SMC | §1.1, §2, §3 | **VERIFIED** |

Where to put it, in order of cost:

1. **A 40-line helper `.ko`** loaded *after* bdpdrv: `kallsyms_lookup_name
   ("i4ImRegisterInterface2")`, one call, done. Deterministic, no ordering
   games, no changes to existing tools — the same trick `sacd_read.ko` already
   uses for its 14 lookups. *(Recommended.)*
2. **In `tools/bx510_osal_stub.c`**, lazily: the stub already sees the exact
   instant (`x_thread_create` of `"GcpuHw0"` happens inside Create before the
   Im steps), so it can `kallsyms_lookup_name` + register there. Cheaper to
   write, more fragile (depends on call ordering and on `kallsyms_lookup_name`
   being exported — it is, `original/sacd_read.ko` uses it).
3. **Patch the guest's `bdpdrv.ko`**: not recommended (breaks the
   "no patched target" discipline of every other rig here).

Expected observable after A1–A6: `SACDREAD cmd=0x40105301 ret=0
errno=0 result=1744830464`, and `_au4CpsaInst[0]` owns the instance, so the
daemon's own `DISC_OPEN` needs a `0x40105305` uninit **and** a fresh bdpdrv
(hazard above).

### 4.2 Route B (what the brief assumed): a GCPU/TrustZone counterparty

Modelling a GCPU/TZ counterparty does **not** move Connect, because Connect
never issues an SMC. It is required only for `0x40105304` (decrypt). The model
rows for that leg are:

| # | behaviour | verdict |
|---|---|---|
| B1 | `TzServiceCall` exists as an exported kernel symbol with the ABI `(u32 handle, u32 id, void *params_ns, u32 len)` | **VERIFIED** §3.2 |
| B2 | For **id 0x1e** (`SetMISC_Cmd`): read `params+0x18` (NS-tagged pointer to the 2488-byte request block), honour `+0x04` opcode `0x80`, `+0x08 src`, `+0x0c dst`, `+0x10 count`, `+0x14 len`; write a non-negative code into `params+0x34`; per 2064-byte block write `dst` from `src` | **VERIFIED** for the block layout and the read-back; INFERRED that the secure world performs the transform (nothing else can) |
| B3 | For **id 0x1f** (`GetMISC_Result`) the same `params+0x18` request block is the carrier; answer `params+0x34` | **VERIFIED** (`0x172c80`) |
| B4 | For **id 0x34/0x35** (`RegWrite`/`RegRead`): `params+0x28` = register index, `params+0x04` = write value, `params+0x30` = read-back value | **VERIFIED** |
| B5 | For **id 0x03** (`HAL_Init`): `params+0x04/0x08/0x0c/0x10` = NS-tagged pointers to `_arGCPUStru`, `_u4GcpuNSS`, `_arSecureSlot`, `_arGcpuNSSInfo`; result ignored by the driver | **VERIFIED** |
| B6 | The driver pre-seeds `params+0x34 = 0x67000000`, so "do nothing" already reads as success | **VERIFIED** §3.4 |
| B7 | No SMC CPU trap is needed, ever | **VERIFIED** §3.1 |

### 4.3 Route C: retarget the CPSA `Connect` hook

`_i4CPSA_Inst_Connect` is exported (`__ksymtab_i4CPSA_Inst_Connect`), revocable by
kallsyms-style patch: a replacement that skips Create and hands
`_au4CpsaInst[compid]` a hand-built instance would also produce
`0x68000000`, but `CPSMode_Ctrl` immediately dereferences the instance magic and
its `+0x28` SACD context, so a hand-built instance must be structurally correct —
i.e. it re-implements Create. Not worth it; listed for completeness. *INFERRED.*

### 4.4 What never appears on the wire

For the avoidance of future work: neither the Connect leg nor the decrypt leg
performs a single peripheral access. Reconciling with the C104 mmio census: the
only MMIO near this path is `vSacdDecryptEnable`'s `0xfd039000/4` +
`0xfd008154/0x15c` pair; inside bdpdrv that function is referenced only by
`_sacd_set_fct` (`.text+0x771ec`, a registration) and `_SACDCLI_DecTrack`
(`.text+0xc6ff4`); from outside it is reached by `sacd_read.ko`'s
`CPSA_SACDCmdDisable` through its own kallsyms slot. It is on neither the
Enable/Connect nor the Decrypt path.
*VERIFIED (relocation xref).*

---

## 5. Corrections to earlier docs

| doc | statement | correction |
|---|---|---|
| `sacdread-cpsa.md` §0.6 / §4.3 | "the decrypt leg … `i4GCPU_CmdExec(gcpu, 0x806, …)` → a bdpdrv worker thread → `TzServiceCall`" and "the model cannot answer it by a register reply" | Right about the wall, wrong about the mechanism: `0x806` is a MISC-group opcode (op 6) that reaches `TzServiceCall` with service id **0x1e**, not with 0x806, and not through `RegWrite`. §3.3 supersedes. |
| `sacdread-cpsa.md` §0.6 (implication) | Connect fails for want of a GCPU/TZ counterparty | Connect issues no SMC. It fails on an interface-manager peer lookup (§1.4). |
| `daemon-wiring.md` §5.1 | the gate's INIT "poisons the daemon" through `_au4CpsaInst[]` | correct *and* there is a second poison: the `(0x16b, compid, 1)` Im registration is never unlinked, so even after a clean Disconnect a second `Connect` for the same compid fails at `:883`. |
| `tools/bx510_osal_stub.c` (C106 block) | "TzServiceCall is the guest's one entry … for every CPSA service (Connect 0x16b, Decrypt 0x806 …)" and dispatches on `a0` | dispatch on **a1**; Connect never reaches it; the ids are 0x03/0x1e/0x1f/0x34/0x35/… (§3.2). |

---

## 6. OPEN items with exact next probes

1. **Which assert line fires (`:852` / `:883` / `:895`).** One-line stub change:
   raise the `Assert` print limit in `tools/bx510_osal_stub.c` (currently "first
   24 print", `bx510_osal_stub.c:293`) or reset the counter from a `/proc`
   hook, then re-fire the C104 ladder and read
   `[OSAL_STUB] Assert FIRED: 0 (src/driver/cpsa/cpsa_main.c:NNN)`. Line 895 ⇒
   missing peer (route A applies as written); line 883 ⇒ duplicate
   registration ⇒ also check §4.1 A4. **This is the single decisive probe.**
2. **Identity of component type 0x168.** Scans to run on the VM (they need no
   rig): (a) `ls /lib/modules/2.6.35/BDP/`; (b) for each `.ko`, the same
   probe as §8's "register-site scan" with `r0 == 0x168`; (c) grep each for a
   `_r*Comp` descriptor whose first u32 is 0x168. If a provider module exists,
   the honest fix is to load it in the command list, not to fake the peer.
3. **Whether `i4ImRegisterInterface2` tolerates a not-yet-initialised
   `_rImInfoList`.** `Im`'s own init (the function that seeds
   `_rImInfoList[1]`, the walk terminator) was not traced in this box;
   `pImFindInfo` compares against `[.bss+0x76f44]`, whose writer is **OPEN**.
   Registering from a helper `.ko` after bdpdrv init is safe by construction
   (the registry is already in use by AUD/DMX at that point), but the exact
   init function is worth naming before trusting an *early* registration.
4. **The 2064-byte frame layout** inside `dst` after the TZ transform (header
   bytes 0..11) — unchanged from `sacdread-cpsa.md` §7.1; this decode adds only
   that the frame is produced by the secure world, not by the driver.
5. **`_prGcpu_Hw_GetGCPUStruct` / `_vGcpu_Hw_InitSecureSlot`** were read only
   far enough to confirm they touch `.bss` (and `_arSecureSlot`) and not MMIO;
   a full read is required before claiming the *whole* GCPU init is
   peripheral-free.

---

## 7. Provenance

| input | identity |
|---|---|
| `bdpdrv.ko` | sha256 `6604f6cd6c204c3399ac047f389f47162b06a3f6576159f21b4e8aaf3a72cf54`, 8,122,068 B, ELF32 ARM `ET_REL`, 42,036 symtab entries, sections `.text` 3,266,588 B / `.rel.text` 942,064 B |
| module base (runtime) | `.text` at `0xbf089000`, from C104's `i4CPSA_Inst_Connect = 0xbf0e09d8` |
| `original/sacd_read.ko` | sha256 `b3d7a383e45d3bbe1a987a4a2e15ab7a68dd55e88d0319f7a0fd2e9cf0246dfa` |
| rig console | `evidence/bx510-guest/bdpdrv/bdpdrv-runC104.uart.log` (lines 2161-2201) |
| stub ABI | `tools/bx510_osal_stub.c` (`x_*` mini-OSAL block, `Assert` at :287, `TzServiceCall` at :315) |
| tools | pyelftools 0.33, capstone, `llvm-objdump` (Apple LLVM 17) |

## 8. Reproduce

```sh
# 0) a small annotated disassembler for this module (the one used throughout)
#    ~120 lines: llvm-objdump -d -r --section=.text + literal-pool resolution
#    through R_ARM_ABS32 relocations + branch-target naming.  Then:
python3 /tmp/bdx.py --func i4CPSA_Inst_Connect      # §1.2
python3 /tmp/bdx.py --func i4CPSA_Inst_Create       # §1.3
python3 /tmp/bdx.py --func i4GCPU_InstanceCreate    # §2.1
python3 /tmp/bdx.py --func _vGCPU_MainLoop          # §2.3
python3 /tmp/bdx.py --func _i4GCPU_CmdHandle        # §2.3 dispatch table
python3 /tmp/bdx.py --func _i4GCPU_Misc_CmdHandle   # 0x806 -> SACDDEC
python3 /tmp/bdx.py --func _i4GCPU_SACDDEC          # §3.3 request block
python3 /tmp/bdx.py --func i4GCPU_HAL_SetMISC_Cmd   # §3.2 SMC ABI
python3 /tmp/bdx.py --func i4ImRegisterInterfaceImpl  # §1.4 entry layout
python3 /tmp/bdx.py --func i4ImQueryInterface

# 1) every TzServiceCall site with its service id (§3.2 table)
#    walk .rel.text for R_ARM_CALL to TzServiceCall, scan back for mov r1,#imm

# 2) every i4ImRegister*/Query/Release site with r0/r1/r2 resolved (§1.4)
#    same walk over the four Im entry points, resolving r0 through the
#    literal pool when it is not an immediate

# 3) the 0x168 hunt (§1.4, §6.2)
#    a) all u32 == 0x168 in .data/.rodata with the nearest STT_OBJECT name
#    b) all _r*Comp descriptors' first u32 (component type ids):
#       _rCPSAComp 0x16b, _rGcpuComp 0x16a, _rKmComp 0x16c, _rAmComp 0x16d,
#       _rEsnComp 0x18c, _rVfdComp1 0x172, _rAvdComp 0x173, _rCecComp 0x154,
#       _rIfconComp 0x187, _rDmxDccComp 0x20  ->  no 0x168 anywhere

# 4) the no-SMC check (§3.1)
#    nm bdpdrv.ko | grep TzServiceCall   -> "U TzServiceCall"
#    capstone scan of .text for E1600070 (SMC #0) / E1600070-family  -> none
```
