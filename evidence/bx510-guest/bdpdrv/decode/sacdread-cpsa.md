# sacd_read.ko ↔ bdpdrv: the CPSA/IDECLI interface, decoded

Date: 2026-11-13. Stage after the ATA probe comes alive: the module the real
daemon loads to reach the disc through Sony's copy-protection stack.
Answers the five questions in the stage brief: the looked-up symbol list, the
bdpdrv side of each, the userspace entry, what the QEMU model still owes, and
whether anything here changes the C96 lane.

**House rules.** Every claim is labelled **VERIFIED** (read out of an
instruction, the module's own DWARF, the daemon's own code, or a symtab — and
re-derivable with `sacdread_cpsa.py`, §8) or **INFERRED** (reasoned from a
pattern). §7 lists what did not resolve.

---

## 0. Bottom line

1. **Fourteen symbols, fourteen lookups, one string table.** `sacd_read.ko`
   calls `kallsyms_lookup_name_diag` fourteen times at module init, once per
   name, and stores each result into its own `.bss` pointer. Thirteen of them
   are mandatory (a miss aborts init with `-EFAULT`); the fourteenth,
   `__ksymtab_disable_print`, is optional and **absent from bdpdrv.ko**, so that
   step never runs. *VERIFIED (§1, §2).*
2. **Every one of the thirteen exists in `bdpdrv.ko`** — the CPSA framework
   (`i4CPSA_*`, `u4CPSA_*`), the SACD CLI (`eSacdGetVersion`,
   `_SACDCLI_TestPhy`, `_SACDCLI_FindTag`, `vSacdDecryptEnable`) and the ODD
   driver CLI (`_IDECLI_OddRead`, `_IDECLI_OddTestUnitReadyLoop`,
   `_IDECLI_OddGetProfile`). `sacd_read.ko`'s prototypes for them are in its
   DWARF; three of the seven that matter are declared with the wrong shape
   (§2.1). *VERIFIED.*
3. **The userspace entry is a misc char device with an old-style `ioctl`.**
   `/dev/sacd_read`, misc major 10, minor **201** (the daemon passes
   `minor=201` to insmod; the module default is `MISC_DYNAMIC_MINOR`),
   `file_operations.ioctl` (4-argument, BKL slot — *not* `unlocked_ioctl`), seven
   commands `0x40105301..0x40105307` carrying one 16-byte
   `_IOCTL_SACD_COMMAND`. The real daemon `sacd_extract_160` contains all seven
   constants and the device path. *VERIFIED (§3).*
4. **The read path never touches MMIO.** `SACD_IOC_READ` → `_IDECLI_OddRead` →
   a READ(10) CDB with byte 10 = `0x98` → `_IDECLI_SendOddCmd` →
   `open("/dev/sr0", O_RDONLY|O_NONBLOCK)` + **`ioctl(fd, 0x8530, req)`** →
   Sony's `mt85xx_ioctl` (core-kernel, `U` in `sr_mod.ko`) → the SCSI/libata/ATA
   stack → the **already-modelled** FE-mailbox + A-window SATA path. The model
   owes *no new MMIO window* for reads; it owes the disc's *answers*
   (§4.2). *VERIFIED.*
5. **Two small register clusters appear only in the enable/disable leg** and are
   cosmetic for the pipeline: `0xfd039000`/`0xfd039004` (write `0x17`, then
   `0x12` on enable / `0` on disable) and the BIM doorbell
   `0xfd008154`/`0xfd00815c` (write `0x00800000`, then poll until bit 23
   clears). Physical: `0x70039000`, `0x70008154`. The model's generic 16 MiB
   window plus the existing `BX_BIM + 0x154 → 0` read already satisfies both
   (§4.1). *VERIFIED.*
6. **The decrypt leg is a TrustZone call, not MMIO.** `SACD_IOC_DECRYPT` →
   `CPSA_SACDCmdDecrypt` → `_i4CPSA_Inst_Decrypt` → `i4CPSA_SACD_Decrypt`
   (rejects any length ≠ **2064**) → `i4GCPU_CmdExec(gcpu, 0x806, …)` → a
   bdpdrv worker thread → `TzServiceCall` (SMC). This is the one place where the
   model cannot be "answered" by a register reply; see §4.3. *VERIFIED to the
   SMC, INFERRED for the secure-world result.*
7. **Blocking verdict for C96: no change.** Nothing in `sacd_read.ko` adds an
   MMIO question to the C96 (ATA-probe) lane, and nothing requires the module to
   be loaded before bdpdrv finishes probing — it *requires the opposite*
   (bdpdrv loaded first, §2.4). The one ordering fact worth carrying into C96 is
   that the read leg needs an enumerated **`/dev/sr0`** with a media-present
   sense answer; that is a C96/C97 enumeration gate, not a sacd_read
   requirement. *VERIFIED (§5).*

---

## 1. Q1 — the `kallsyms_lookup_name_diag` argument strings

`sacd_read.ko` ships an ARM32 wrapper `kallsyms_lookup_name_diag` (`.text+0x67c`,
a `printk`-instrumented `kallsyms_lookup_name`) and calls it fourteen times from
`sacd_read_init` (`.init.text`). Each name is a plain `ldr r0, =<str>` into
`.rodata.str1.1`; each result is stored into a distinct `.bss` slot whose name
the module's own symtab still carries. All fourteen, in lookup order:

| # | lookup string (`.rodata.str1.1`) | `.bss` slot | module variable | required? |
|---|---|---|---|---|
| 1 | `i4CPSA_Inst_CPSMode_Ctrl` | +0x18 | `pi4CPSA_Inst_CPSMode_Ctrl` | yes |
| 2 | `_IDECLI_OddRead` | +0x28 | `p_IDECLI_OddRead` | yes |
| 3 | `_i4CPSA_Inst_Decrypt` | +0x00 | `p_i4CPSA_Inst_Decrypt` | yes |
| 4 | `i4CPSA_Inst_SetSACDControl` | +0x08 | `pi4CPSA_Inst_SetSACDControl` | yes |
| 5 | `u4CPSA_Inst_GetInstHandleFromCompId` | +0x04 | `pu4CPSA_Inst_GetInstHandleFromCompId` | yes |
| 6 | `i4CPSA_Inst_Connect` | +0x20 | `pi4CPSA_Inst_Connect` | yes |
| 7 | `i4CPSA_Inst_Disconnect` | +0x1c | `pi4CPSA_Inst_Disconnect` | yes |
| 8 | `vSacdDecryptEnable` | +0x14 | `pvSacdDecryptEnable` | yes |
| 9 | `_SACDCLI_TestPhy` | +0x0c | `p_SACDCLI_TestPhy` | yes |
| 10 | `eSacdGetVersion` | +0x10 | `peSacdGetVersion` | yes |
| 11 | `_SACDCLI_FindTag` | +0x38 | `p_SACDCLI_FindTag` | yes |
| 12 | `_IDECLI_OddTestUnitReadyLoop` | +0x2c | `p_IDECLI_OddTestUnitReadyLoop` | yes |
| 13 | `_IDECLI_OddGetProfile` | +0x30 | `p_IDECLI_OddGetProfile` | yes |
| 14 | `__ksymtab_disable_print` | +0x3c | `ppdisable_print` | no |

Notes that matter:

* **The leading underscores are part of the symbol names.** `_i4CPSA_Inst_Decrypt`,
  `_IDECLI_OddRead`, `_IDECLI_OddTestUnitReadyLoop`, `_IDECLI_OddGetProfile`,
  `_SACDCLI_TestPhy`, `_SACDCLI_FindTag` are the real spellings in bdpdrv.ko's
  symtab — `i4CPSA_Inst_Decrypt` without the underscore does **not** exist.
  *VERIFIED (nm).*
* `kallsyms_lookup_name` searches the full kallsyms table, so the `t` (local)
  symbols `_SACDCLI_TestPhy` and `_SACDCLI_FindTag` resolve just as well as the
  exported `T` ones — the module does not depend on `EXPORT_SYMBOL` for any of
  these thirteen, only on bdpdrv being resident. *VERIFIED (they are `t`; init
  only checks for non-NULL).*
* Four of the fourteen — `_SACDCLI_TestPhy`, `eSacdGetVersion`,
  `_SACDCLI_FindTag`, `ppdisable_print` — are **looked up but never called** by
  `sacd_read.ko`'s own code (no reference to those `.bss` slots survives in
  `.text`; only the non-NULL test in `.init.text`). They are init gates, not
  used API. *VERIFIED (no `[r4,#0x0c|0x10|0x38|0x3c]` load outside init).*
* `__ksymtab_disable_print` is **absent from bdpdrv.ko** and from every module
  in the rootfs; the lookup fails, `ppdisable_print` stays NULL, and the
  "silence the CPSA logger" step is skipped — non-fatal, since it is not in the
  required set. If the symbol had resolved, the code does
  `*(UINT32*)*ppdisable_print = 0`, i.e. it zeroes the kernel global
  `disable_print` (`bdpdrv.ko .bss+0x103774`). *VERIFIED (string absent from
  nm_all; store decoded).*

### 1.1 Init gates and return codes (what a wrong stack reports)

`.init.text` in order: print a `====` banner, print `minor` and `compid`, do the
fourteen lookups, test thirteen of them, then:

```
  ldrh r0,[_,#0x24]        ; compid (module param, bss+0x24)
  blx  pi4CPSA_Inst_GetInstHandleFromCompId
  cmn  r0,#1               ; == 0xFFFFFFFF ?
  beq  proceed             ; free compid -> continue
  printk("[%s] compid = %d is used. Try another.\n")
  return -EBUSY            ; (mvn r4,#15)
```

* Missing symbol → `-EFAULT` (`mvn r4,#13`); compid already owned → `-EBUSY`
  (matches `docs/DAEMON-MAP.md`). *VERIFIED.*
* `i4CPSA_Init` (`bdpdrv .text+0x5458c`) fills the four instance slots
  `_au4CpsaInst[0..3]` (`.bss+0x11590`) with `0xFFFFFFFF` — so "free" really is
  `-1`, and the `cmn #1` polarity above is right: **the gate demands the slot be
  free**. Four slots for four GCPUs, matching the module's own modinfo
  `parm=compid:GCPU Compute ID (0-3)`. *VERIFIED.*
* `misc_register(&sacd_read_dev)` last; failure prints
  `"<3>[%s]Unable to register misc device\n"` and propagates the error.
  `sacd_read_open` and `sacd_read_release` return 0 and do nothing. *VERIFIED.*

---

## 2. Q2 — the bdpdrv side of each looked-up symbol

Signatures below are the **module's own DWARF** (`sacd_read.c:46-58`,
`DW_TAG_variable` → `DW_TAG_subroutine_type`), which is the authoritative record
of what `sacd_read.ko` *believes* it is calling; the bdpdrv prologue is then
quoted to show what the callee *actually* does with those registers.

### 2.1 Declared vs actual — three signatures are wrong in the module

| symbol | `sacd_read.ko` DWARF says | bdpdrv callee proves |
|---|---|---|
| `i4CPSA_Inst_SetSACDControl` | `INT32 (UINT32, X_CPSA_SACCTRL_INFO_T *)` | arg0 is a **pointer**: first act is `ldr r2,[r0]; cmp r2,#0x12043000` (instance magic). The UINT32 is the handle from `GetInstHandleFromCompId`. |
| `i4CPSA_Inst_Connect` / `_Disconnect` | `INT32 (UINT16, UINT16, UINT16, UINT16)` | the caller passes `(0x16b, compid, 360, compid)` — `0x16b` is a *literal constant* in the pool (not a pointer, no reloc), so arg0 is a component-type id and arg2 a millisecond timeout. Callee indexes `_au4CpsaInst[arg1]`. |
| `p_IDECLI_OddRead` | `INT32 (UINT32, UINT32, UINT8 *, UINT32, BOOL)` | arg3 is the *byte length* of the transfer (`2064 × sectors` at the call site), arg4 is the SACD flag that becomes CDB byte 10. |

*VERIFIED both sides.* The declared shapes were enough to link (everything is a
word), so this only matters when trading register-level stories.

The single struct both sides share, from the module's DWARF
(`sacd_read.h:52-56`, byte size 0x10):

```c
typedef struct _IOCTL_SACD_COMMAND {   /* 16 bytes, the ioctl's only payload */
    UINT32  u4Result;   /* +0x00  command result, also the in/out status    */
    UINT32  u4Offset;   /* +0x04  LBA                                        */
    UINT32  u4Sectors;  /* +0x08  sector count                               */
    UINT8  *pu1Buf;     /* +0x0c  user buffer                                */
} _IOCTL_SACD_COMMAND;
/* and: struct _X_CPSA_SACCTRL_INFO_T { BOOL fgEnable; }  (sacd_read.h:8-10) */
```

### 2.2 Symbol by symbol (bdpdrv addresses from `nm_defined.txt`)

**`u4CPSA_Inst_GetInstHandleFromCompId`** — `0x55a8c`, 0x14 B.
`{ return _au4CpsaInst[compid]; }` → `ldr r3,=.bss; add r3,r3,r0,lsl#2; ldr r0,[r3,#8]`
(base `0x11588` + 8 = `0x11590`). No MMIO. Returns the instance pointer, or
`0xFFFFFFFF` when the compid is free. *VERIFIED.*

**`i4CPSA_Inst_SetSACDControl`** — `0x55900`, 0x48 B.
```
ldr r2,[r0]            ; instance->magic
cmp r2,#0x12043000
bne  -> Assert(src/driver/cpsa/cpsa_main.c:1824); return 0xE8000002
ldr r0,[r0,#0x28]      ; instance->pSACD          <- arg0 for the tail call
ldrb r1,[r1]           ; pInfo->fgEnable (BOOL!)
b    i4CPSA_SACD_EnableControl          ; tail call, (pSACD, fgEnable)
```
`i4CPSA_SACD_EnableControl` (`0x55d2c`, 0x18 B) stores `fgEnable` into
`pCtx->byte[0x11]` (normalised to 0/1) and **returns `0x68000000`** — a CPSA
"call the CPSA-instance API, not the raw command" convention, not an errno.
No MMIO. *VERIFIED.*

**`i4CPSA_Inst_CPSMode_Ctrl`** — `0x54b78`, 0x6ac B.
Pure dispatch: a component-type table of `Create` / `SetCallback` / `Destroy`
entries (`i4CPSA_SACD_Create`, `i4CPSA_SACD_SetCallback`,
`vCPSA_SACD_Destroy`, …, one family per BDROM/BDRE/CSS/CPRM/CPPM/DivxDRM/MARLIN/
WMDRM/SACD). **No MMIO literal anywhere in the function** (no `0xfd…` word in
its pool; every relocation is a text symbol or a string). Signature
`INT32 (UINT32 handle, UINT32 mode, BOOL fgEnable)`; the module calls it as
`CPSMode_Ctrl(handle, 0x40, TRUE)` on enable and `(handle, 0x40, FALSE)` on
disable. *VERIFIED.*

**`i4CPSA_Inst_Connect`** — `0x559d8`, 0x60 B; **`i4CPSA_Inst_Disconnect`** —
`0x55a38`, 0x54 B.
```
r4 = &_au4CpsaInst[compid];  r12 = *r4
if (r12 != -1) -> Assert(cpsa_main.c:1881); return 0xE8000006   /* slot busy */
else i4CPSA_Inst_Create(comptype, compid, timeout, compid, &h); *r4 = h
```
Called by the module as `Connect(0x16b, compid, 360, compid)` on
`SACD_IOC_INIT` and `Disconnect(0x16b, compid, 360, compid)` on
`SACD_IOC_UNINIT`. No MMIO. *VERIFIED.*

**`_IDECLI_OddRead`** — `0xaa3d8`, 0x94 B. Builds a 12-byte CDB on the stack:
```c
cdb[0] = 0x28;                      /* READ(10)                        */
cdb[2..5] = lba   (big-endian);     /* bits 31..8, then cdb[5] = lba   */
cdb[7..8] = sectors (big-endian);
cdb[10]   = fgSacd ? 0x98 : 0x00;   /* Sony/MediaTek SACD read flag    */
_IDECLI_SendOddCmd(cdb, 2, pBuf, len, NULL);
```
Returns 0 or -1 from the send. `fgSacd` is what `sacd_read.ko` passes as the
5th argument (`1` on the read command). *VERIFIED.*

**`_IDECLI_OddTestUnitReadyLoop`** — `0xa9760`, 0x70 B. Polls
`_IDECLI_OddTestUnitReady(&status)` every **200 ms** until the masked status is
`0x23A00` or `0x23000`, or until `timeout_ms` (the module asks for **20000**).
Masked status = `((reply[2] & 0x0F) << 16) | (reply[0x0C] << 8) | reply[0x0D]`,
i.e. **SCSI status in bits 16-19 and ASC/ASCQ in bits 0-15**; `0x23A00` =
CHECK CONDITION + ASC 0x3A ("medium not present"), `0x23000` = the same with
ASC 0x30 ("incompatible medium installed"). Those two are treated as
*keep-polling*; anything else ends the loop. Returns the last error and, when a
non-NULL out pointer was given, stores the masked status. *VERIFIED for the
mask/compare, INFERRED for the SCSI field naming.*

**`_IDECLI_OddGetProfile`** — `0xa9a54`, 0x94 B. Sends the 12-byte template
`46 01 00 00 00 00 00 00 14 00 00 00` = **MMC GET CONFIGURATION (0x46)** with a
20-byte allocation length, then `*profile = be16(reply[6..7])` — the MMC
"current profile" field. Returns 0 on success, -1 otherwise (and stores 0 into
the out pointer on failure). *VERIFIED.*

**`vSacdDecryptEnable`** — `0xc6e30`, 0x60 B. **The only MMIO in the whole set**
(see §4.1). Returns `void`. Sequence:
```
*(u32*)0xfd039000 = 0x17;                 /* SACD/CPSA block, always      */
*(u32*)0xfd00815c = 0x00800000;           /* BIM doorbell                 */
*(u32*)0xfd008154 = 0x00800000;
while (*(u32*)0xfd008154 & 0x00800000) x_thread_delay(1);   /* self-clear   */
*(u32*)0xfd039004 = fgEnable ? 0x12 : 0;
```
*VERIFIED.*

**`eSacdGetVersion`** — `0xc6d38`, 0x48 B. `v = (*(u32*)0xfd039008 & 6) >> 1;`
then `3 → SACD_VER_UNKNOWN(0)`, `0 → SACD_VER_10(1)`, `1|2 → SACD_VER_20(2)`.
Never called by the module (§1). *VERIFIED.*

**`_SACDCLI_TestPhy`** — `0xc719c`, 0x160 B (local `t`). The full SACD bring-up
self-test — and therefore the best available checklist of what the device must
answer: `_IDECLI_OddCheckFaMode` → `_IDECLI_OddTestUnitReadyLoop(20000)` →
`_IDECLI_OddGetProfile` → `_IDECLI_OddSetSpeedLevel` →
`vSacdDetectPspPdmEnable` → `_IDECLI_OddSacdSeek` → `eSacdWaitPspPdmResult(5000)`
→ `eSacdGetVersion` → `_IDECLI_OddSacdSeek` ×2. Never called by the module.
*VERIFIED.*

**`_SACDCLI_FindTag`** — `0xc75f4`, 0x274 B (local `t`). Reads sectors through
`_IDECLI_OddRead`, then `vEkbInit` → `bEkbParseTagKey` → `fgSacdSetEkbParam`:
this is the EKB/key-material step, i.e. GCPU/TrustZone work, not ATA work. Never
called by the module. *VERIFIED.*

### 2.3 The three wrappers `sacd_read.ko` exports back into the CPSA layer

`CPSA_SACDCmdEnable/SetCtrl/Disable/Decrypt` (`sacd_read.ko .text+0x10..0x22c`,
all `T`, exported) are what the *bdpdrv* side may call if it holds the module's
addresses; each is a thin `GetInstHandleFromCompId(compid)` + call + `printk`
on failure, with `compid` read from the module's own `.bss` (the insmod
parameter), **not** from the ioctl payload:

| export | sequence | failure string |
|---|---|---|
| `CPSA_SACDCmdEnable(compid)` | `Connect(0x16b,compid,360,compid)` → `CPSMode_Ctrl(handle,0x40,TRUE)` | `"[%s]i4CPSA_Inst_Connect Fail:%d"`, `"[%s]Ena i4CPSA_Inst_CPSMode_Ctrl Fail:%d"` |
| `CPSA_SACDCmdSetCtrl(compid)` | `handle=GetInst(compid)`; `X_CPSA_SACCTRL_INFO_T t={.fgEnable=TRUE}`; `SetSACDControl(handle,&t)` | `"[%s]i4CPSA_Inst_SetSACDControl Fail:%d"` |
| `CPSA_SACDCmdDecrypt(compid,src,dst,len)` | `handle=GetInst(compid)`; `_i4CPSA_Inst_Decrypt(handle,src,dst,len)` | `"[%s]_i4CPSA_Inst_Decrypt Fail:%d"` |
| `CPSA_SACDCmdDisable(compid)` | `vSacdDecryptEnable(FALSE)` → `CPSMode_Ctrl(handle,0x40,FALSE)` → `Disconnect(0x16b,compid,360,compid)` | three strings, as above with `Dis i4CPSA_Inst_CPSMode_Ctrl` / `i4CPSA_Inst_Disconnect` |

All four share the literal `__func__` = `"SACDREAD"` (`.rodata.str1.1+0x22`).
*VERIFIED.*

### 2.4 Ordering consequence

Because the thirteen symbols are resolved at init and any miss is fatal, **bdpdrv
must already be loaded and initialised when `sacd_read.ko` is insmodded** — and
in practice `i4CPSA_Init` must have run (it is the function that fills the free
slots with `-1`; without it the compid gate reads 0 and refuses with
`EBUSY`*). The daemon does the insmod itself at runtime (`insmod %s minor=201`),
so nothing about the kernel's own module load order changes. *VERIFIED for the
symbol and table facts; INFERRED that `i4CPSA_Init` runs during bdpdrv init.*

---

## 3. Q3 — the userspace→kernel path

### 3.1 The device

`struct miscdevice sacd_read_dev` (`.data`, 0x24 bytes):
`minor = 0xFF` (`MISC_DYNAMIC_MINOR`) overwritten at init if the `minor` module
parameter is non-zero; `name = "sacd_read"`; `fops = sacd_read_fops`.
`file_operations` (module's own DWARF for the 2.6.35 layout): only
`owner`, **`ioctl` (+0x20)**, `open (+0x30)`, `release (+0x38)` are set —
`unlocked_ioctl` (+0x24) and `compat_ioctl` (+0x28) are NULL, and
`sacd_read_ioctl` really does take `(struct inode *, struct file *, unsigned
int cmd, unsigned long arg)`. *VERIFIED (`.rel.rodata` × DWARF member offsets).*

The daemon is explicit about the node:

```
mknod -m0666 /dev/sacd_read c 10 201
insmod %s minor=201
rmmod sacd_read
strings in original/sacd_extract_160 — VERIFIED
```

The `.ko` is **embedded inside the daemon** (`_binary_sacd_read_ko_start/_end/_size`),
written to a temp file, and insmodded at runtime — the rootfs ships no copy in
`/lib/modules/2.6.35/BDP/`. *VERIFIED (no `sacd_read*` file in the extracted
rootfs; the blob symbols are in the daemon).*

### 3.2 The commands

`sacd_read_ioctl` accepts only `type == 0x53` (`(cmd >> 8) & 0xFF`) and then
switches on `cmd + 0xBFEFACFF ≤ 6` — i.e. exactly seven commands, all
`_IOC_WRITE`-direction, all 16-byte payload:

| cmd | `_IOC` | driver action | daemon wrapper | call site |
|---|---|---|---|---|
| `0x40105301` | dir=1 type=0x53 nr=1 size=16 | `CPSA_SACDCmdEnable(compid)` | `init_sacd()` | `sacd_dev_input_open` |
| `0x40105302` | nr=2 | `CPSA_SACDCmdSetCtrl(compid)` | `auth_sacd()` | `sacd_dev_input_authenticate` |
| `0x40105303` | nr=3 | `read`: `kmalloc(2064*n)`, `p_IDECLI_OddRead(lba,n,buf,2064*n,TRUE)`, `copy_to_user(…,2064*n)` | `read_sacd(lba,n,buf)` | `sacd_dev_input_read64` |
| `0x40105304` | nr=4 | `decrypt`: `kmalloc(2064*n)`, `copy_from_user(…,2064*n)`, per block `CPSA_SACDCmdDecrypt(compid,in+2064*i,out,2064)` then `memcpy(buf+i*2048, out+12, 2048)`, `copy_to_user(…,2048*n)` | `decrypt_sacd(n,buf)` | `sacd_dev_input_decrypt` |
| `0x40105305` | nr=5 | `CPSA_SACDCmdDisable(compid)` | `uninit_sacd()` | `sacd_dev_input_close` |
| `0x40105306` | nr=6 | `p_IDECLI_OddTestUnitReadyLoop(20000,&st)` | `disc_sacd()` | `server_loop` |
| `0x40105307` | nr=7 | `p_IDECLI_OddGetProfile(&p)`; status = -1 unless `p == 0x10` | `sacd_sacd()` | `server_loop` |

*VERIFIED:* switch base literal `0xBFEFACFF` + a seven-word jump table
(`.text+0x2d4`), decoded by `sacdread_cpsa.py --ioctl`; the same seven constants
appear verbatim in `original/sacd_extract_160` at file offsets
`0x1901c, 0x190ac, 0x19160, 0x19208, 0x19274, 0x19304, 0x19394`, each inside the
corresponding `init_sacd`/`auth_sacd`/`read_sacd`/`decrypt_sacd`/`uninit_sacd`/
`disc_sacd`/`sacd_sacd` (`nm` → those seven `T` symbols at `0x20f90..0x21308`).
Each wrapper is `open("/dev/sacd_read",0)` → `ioctl` → `result = cgc.u4Result` →
`close()`; `read_sacd` fills `u4Offset/u4Sectors/pu1Buf`, `decrypt_sacd` fills
`u4Sectors/pu1Buf`. The mnemonic names (`SACD_IOC_INIT` …) and the 16-byte field
names are the reconstructed userspace's (`reconstruct/libsacd/sacd_read.c`,
`sacd_read.h`); they agree with the module's DWARF struct and with every field the
daemon actually writes, but the daemon itself carries only the numbers.
*VERIFIED for numbers and offsets; the names are the reconstruction's.*

Two facts the model lane should carry:

* **`disc_sacd() != 0` and then `sacd_sacd() == 0` is the daemon's disc gate**
  (`server_loop`, `0xe1f0`/`0xe214`): unit-ready must come back good *and* the
  drive must report profile **0x10 (DVD-ROM)**. Rejecting either kills the
  session before a single sector is read.
* **2048 vs 2064.** Every SACD sector is framed as **2064 bytes = 12-byte header
  + 2048-byte payload** on the decrypt side (`memcpy(…, out+12, 2048)`), and the
  read side allocates and copies **2064 × sectors** although the CDB asks for
  `sectors` blocks. Either Sony's READ(10)-with-`0x98` returns 2064-byte
  frames, or 16 bytes/sector of the kernel buffer are stale — *not resolved
  here* (§7). Whoever builds the disc responder must decide which, because it
  changes the byte count per command.

---

## 4. Q4 — what the model still owes for this stage

### 4.1 New MMIO: two register clusters, both already tolerated

| access | virt | phys | who | model status |
|---|---|---|---|---|
| write `0x17` | `0xFD039000` | `0x70039000` | `vSacdDecryptEnable` | unmapped case → write ignored (default `bx510_ops`) — harmless |
| write `0x12` / `0` | `0xFD039004` | `0x70039004` | `vSacdDecryptEnable` | same |
| read bits[2:1] | `0xFD039008` | `0x70039008` | `eSacdGetVersion` (not called) | default read returns 0 → "SACD_VER_10" if ever called |
| write `0x00800000` | `0xFD008154`, `0xFD00815C` | `0x70008154`, `0x7000815C` | `vSacdDecryptEnable` | `BX_BIM+0x154/0x158` reads already return 0 (`sony-bx510.c:403`), so the self-clear poll exits on the first iteration; the writes fall through to default |
| read (poll) | `0xFD008154` | `0x70008154` | `vSacdDecryptEnable` | returns 0 → bit 23 clear → loop exits immediately |

So **no new MMIO window is required** for the enable/disable leg: the model's
single 16 MiB peripheral region at `0x70000000` already swallows these
accesses, and the one read that could hang (the BIM doorbell) is already
answered with 0. Only fidelity would improve (a real `SACD/CPSA` block model
that latches `0xfd039008` and returns a version), and nothing on the read path
asks for it. *VERIFIED against `emulator-kit/sony-bx510.c` (`BX_BIM` cases
0x138/0x13c/0x154/0x158, default `bx510_ops`).*

### 4.2 The read/profile/ready leg: answers, not registers

`_IDECLI_SendOddCmd` (`bdpdrv 0xa92dc`) is the whole ODD interface and it is
**not** MMIO:

```c
req = {0}; memcpy(req.cdb, cdb, 12);
req.buf = pBuf; req.len = len; req.reply = &reply44; req.type = cmdtype; /* 2 or 3 */
req.timeout_ms = 10000;
fd = sys_open("/dev/sr0", O_RDONLY|O_NONBLOCK);
err = sys_ioctl(fd, 0x8530, &req);
sys_close(fd);
```

* `/dev/sr0` + ioctl `0x8530` (`_IOC` type 0x85, nr 0x30 — a Sony vendor
  command) are handled in `sr_block_ioctl` (`sr_mod.ko 0x6a0`):
  ```
  7d0: ldr r3,=0x8530 ; cmp r5,r3 ; bne next
  7dc: mov r0,r8 (q) ; mov r1,r5 (cmd) ; mov r2,r4 (arg) ; bl mt85xx_ioctl
  ```
  `mt85xx_ioctl` is `U` in `sr_mod.ko` and defined by no module in the rootfs —
  it is compiled into the guest kernel. *VERIFIED.*
* The 44-byte request layout, as the caller writes it: `+0x00 u8 cdb[12]`,
  `+0x0c buf`, `+0x10 len`, `+0x18 reply44`, `+0x1c u8 type`, `+0x24 timeout_ms`.
  *VERIFIED for the offsets/values, INFERRED for the field meanings (the callee
  is inside the kernel image, not available).*
* Diagnostics on failure print the CDB and a 24-bit
  `SenseKey: %06x` = the same status/ASC/ASCQ triple the TUR loop masks.
  *VERIFIED.*

Consequently, everything the model must answer for this stage is **ATAPI/SCSI
behaviour on the already-modelled SATA path**:

1. the device must enumerate as an ATAPI CD-ROM and `/dev/sr0` must exist
   (C96/C97 enumeration; `sacd_read` read fails with
   `"[%s]Open ODD device failed: %d !!"` and errno -2 if it does not);
2. **TEST UNIT READY** must return good, or CHECK CONDITION with ASC 0x3A/0x30
   while "no disc" (the driver polls 100 × 200 ms);
3. **GET CONFIGURATION (0x46)** must return at least 8 bytes with the *current
   profile* field at reply[6..7] = `0x0010` for the daemon's gate to pass;
4. **READ(10)** with byte 10 = `0x98` must return data (byte count question in
   §3.2);
5. requests time out after 10 s in the driver (`0x2710`), so a model that never
   answers looks like a 10-second stall per command, not an error.

### 4.3 The decrypt leg: a TrustZone call, not a register

```
CPSA_SACDCmdDecrypt(compid,src,dst,len)
 -> _i4CPSA_Inst_Decrypt(handle,src,dst,len)          bdpdrv 0x542b4
      dispatch on handle->flags: &0x40 -> i4CPSA_SACD_Decrypt(handle->pSACD,...)
 -> i4CPSA_SACD_Decrypt(ctx,src,dst,len)              bdpdrv 0x55d44
      magic must be 0x12043007; **len must equal 2064** (else Assert, 0xE8000002)
      if (ctx->byte[4] == 0) return 0xE800000A          /* not enabled */
      i4GCPU_CmdExec(ctx->byte[0x10] /*gcpu*/, 0x806, &{src,dst,len}, 1)
 -> i4GCPU_CmdExec                                    bdpdrv 0x1740bc
      queue to a per-GCPU worker thread + event group; returns 0xE7000005 /
      0xE7000008 on the failure paths
 -> the worker's register access is i4GCPU_HAL_RegWrite (0x172358), which packs
    a request and calls **TzServiceCall(g_hSecureHandle, ...)** — a TrustZone
    secure-monitor call.
```

*VERIFIED* down to the `TzServiceCall`; what the secure world does with it, and
therefore what ciphertext comes back, is **INFERRED to be unimplementable** in
QEMU without the secure firmware. Practical consequences:

* the decrypt ioctl blocks in `x_ev_group_wait_event` until the worker posts
  completion; if the GCPU worker never completes, the *daemon* hangs on the
  ioctl (no timeout on that path) — a model that answers SATA but not the GCPU
  will read fine and then stall on the first `SACD_IOC_DECRYPT`;
* the raw-read leg (`SACD_IOC_READ`) does **not** need any of this, so the
  "does the real daemon get real disc bytes out of the emulator" gate can be
  satisfied before any GCPU work exists;
* authenticity (EKB) is the same story one level up (`_SACDCLI_FindTag` →
  `vEkbInit`/`bEkbParseTagKey`), and it is *not* on the sacd_read ioctl path at
  all.

### 4.4 Preliminary "model rows" for this stage

| id | row | evidence | verdict |
|---|---|---|---|
| SR-1 | `/dev/sr0` exists as an enumerated ATAPI CD-ROM with media present | daemon `mknod`/`open`, `_IDECLI_SendOddCmd` `sys_open` fail path | C96/C97 enumeration — no new row here |
| SR-2 | TEST UNIT READY: good, or CHECK CONDITION ASC 0x3A/0x30 while not ready | `_IDECLI_OddTestUnitReadyLoop` mask/compare | model row (device answer) |
| SR-3 | GET CONFIGURATION 0x46: reply[6..7] = current profile `0x0010` | `_IDECLI_OddGetProfile` + `sacd_sacd()` 16-byte gate | model row — **the daemon gate** |
| SR-4 | READ(10) opcode 0x28, byte10 = 0x98: SACD sector frames (2048 or 2064 B) | `_IDECLI_OddRead` CDB build | model row — byte count open (§7) |
| SR-5 | 10 000 ms completion budget per ODD command | `_IDECLI_SendOddCmd` `+0x24 = 0x2710` | timing note |
| SR-6 | `0xFD039000/4/8` SACD block: writes accepted, `+8` bits[2:1] = version | `vSacdDecryptEnable`, `eSacdGetVersion` | optional fidelity (default I/O already suffices) |
| SR-7 | `0xFD008154/0x15C` BIM doorbell self-clears | `vSacdDecryptEnable` poll | already answered (`BX_BIM+0x154 → 0`) |
| SR-8 | `i4GCPU_CmdExec(…, 0x806, …)` → `TzServiceCall` completes | `_i4CPSA_Inst_Decrypt` chain | **not a register interface**; needs a GCPU/TZ stand-in or the daemon stalls on decrypt |
| SR-9 | CPSA instance table `_au4CpsaInst[0..3]` free at insmod; `i4CPSA_Init` ran | `i4CPSA_Init` fills `-1`; `cmn #1` gate | ordering row (bdpdrv first) |

---

## 5. Q5 — blocking verdict for the current C96 lane

**No change.** Verified three ways:

1. **No new MMIO question.** Every access on the `SACD_IOC_*` path lands in
   either (a) the existing SATA/FE-mailbox path via `/dev/sr0` + `mt85xx_ioctl`,
   (b) the two register clusters in §4.1 that the model's default handlers
   already swallow, or (c) the `TzServiceCall` leg, which is not MMIO at all.
   Nothing on the path reads a register that C96 has to invent an answer for.
2. **No ordering constraint on C96.** `sacd_read.ko` must load *after* bdpdrv
   has initialised CPSA (§2.4) — it cannot be a pre-boot precondition of the ATA
   probe, and the daemon loads it at runtime by itself. C96 gates stay "does the
   ATA probe come alive"; this stage gates nothing upstream.
3. **The C96 deliverables already carry the one thing this stage needs from
   them**: an enumerated ATAPI device. If C96 produces IDENTIFY + a
   media-present sense answer, the sacd_read read leg has everything it asks of
   the model; the remaining gap (SR-3/SR-4 profile and sector framing) belongs
   to whichever lane builds the *disc responder*, not to C96.

One thing that would change the answer: if the C9x gate is defined as *"the real
daemon rips a track"*, then SR-3 (profile 0x10), SR-4 (sector framing) and SR-8
(GCPU/TrustZone completion) are all on the critical path — and SR-8 is a
research problem, not a model row. Recommend gating the endgame on "real daemon
reads real sectors through `SACD_IOC_READ`", with decrypt explicitly out of
scope until the GCPU question is settled.

---

## 6. Provenance

| input | identity |
|---|---|
| `original/sacd_read.ko` | sha256 `b3d7a383e45d3bbe1a987a4a2e15ab7a68dd55e88d0319f7a0fd2e9cf0246dfa`, 97,805 B, ELF32 ARM `ET_REL`, **unstripped with DWARF** (`GNU C 4.4.1`, `sacd_read.c`, `build_linux-2.6.35`) |
| `original/sacd_extract_160` | sha256 `0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45`, 350,830 B, ARM EABI5, unstripped with DWARF |
| `bdpdrv.ko` | sha256 `6604f6cd6c204c3399ac047f389f47162b06a3f6576159f21b4e8aaf3a72cf54` (same as `model-spec.md`), 8,122,068 B, 42,036 symtab entries |
| `sr_mod.ko` | 34,944 B, pulled from the guest rootfs (`/lib/modules/2.6.35/BDP/`) for the `0x8530` check |
| tools | Apple llvm-objdump/llvm-nm 17, `dwarfdump` (debug_info/line), `sacdread_cpsa.py` (this dir) |
| guest rootfs | `/tmp/rootfs` on the lab VM (`make vm-exec`), no `sacd_read*` file present |

## 7. What did not resolve

1. **By how many bytes a SACD sector arrives** (§3.2): the read path budgets and
   copies `2064 × n` while the CDB asks for `n` blocks; the decrypt path consumes
   2064 and compacts to 2048. Whether Sony's `0x98` READ(10) returns 2064-byte
   frames could not be settled from user-space-side binaries. It is the single
   most load-bearing open number for the disc responder.
2. **The 44-byte `0x8530` request field meanings** (§4.2): the callee
   (`mt85xx_ioctl`) is inside the guest kernel image, which is not in this
   evidence set. Offsets and written values are VERIFIED; the semantic names are
   INFERRED from the values.
3. **What `TzServiceCall` does** and whether the GCPU command `0x806` can be
   short-circuited at the `i4GCPU_CmdExec` boundary (the daemon would then get a
   "decrypt succeeded" with whatever bytes the model wrote). Not investigated —
   section 4.3 only establishes where the wall is.
4. **`i4CPSA_Init`'s call site** inside bdpdrv's init (INFERRED, not traced to
   its caller).
5. **`cdb[10] = 0x98` semantics.** In MMC, READ(10) byte 10 is the group number;
   `0x98` sets bits 7/4/3, which a standard drive would reject. INFERRED to be a
   MediaTek/Sony vendor flag selecting the SACD sector format; not proven.

## 8. Reproduce

```sh
# all of §1, §2's cross-check, §3's ioctl table and fops — one command
python3 sacdread_cpsa.py \
    --ko original/sacd_read.ko \
    --nm /tmp/bdpdrv/nm_defined.txt \
    --lookups --ioctl --fops --bdpdrv
# (repo-root CWD: run it through the CWD-pinning target)
make sacd-py SCRIPT=$PWD/evidence/bx510-guest/bdpdrv/decode/sacdread_cpsa.py

# the DWARF signatures quoted throughout (no pyelftools needed)
dwarfdump --debug-info original/sacd_read.ko | grep -A3 'i4CPSA_Inst_'

# the daemon side
nm -n original/sacd_extract_160 | grep -E ' (init|auth|read|decrypt|uninit|disc|sacd)_sacd$'
python3 - <<'EOF'
import struct
d=open('original/sacd_extract_160','rb').read()
for n in range(1,8):
    print(n, hex(d.find(struct.pack('<I',0x40105300|n))))
EOF

# the bdpdrv callees
objdump -dr --start-address=0x55900 --stop-address=0x55948 /tmp/bdpdrv/bdpdrv.ko   # SetSACDControl
objdump -dr --start-address=0xaa3d8 --stop-address=0xaa46c /tmp/bdpdrv/bdpdrv.ko   # _IDECLI_OddRead
objdump -dr --start-address=0xa92dc --stop-address=0xa94a0 /tmp/bdpdrv/bdpdrv.ko   # _IDECLI_SendOddCmd
objdump -dr --start-address=0xc6e30 --stop-address=0xc6e90 /tmp/bdpdrv/bdpdrv.ko   # vSacdDecryptEnable (MMIO)
objdump -dr --start-address=0x55d44 --stop-address=0x55e54 /tmp/bdpdrv/bdpdrv.ko   # i4CPSA_SACD_Decrypt
objdump -dr --start-address=0x1740bc --stop-address=0x1742b8 /tmp/bdpdrv/bdpdrv.ko  # i4GCPU_CmdExec
```
