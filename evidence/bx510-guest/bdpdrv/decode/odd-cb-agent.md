# The ODD/cbagent stack — what actually sits between bdpdrv and the SATA driver

Date: 2026-11-14. Stage after `sacdread-cpsa.md` (§4.2) left two questions open:
*who receives `ioctl(/dev/sr0, 0x8530)`*, and *what the 44-byte request really
is*. Both are answered below, plus the module-load checklist for `/dev/sr0`,
a full MMIO survey of the intermediate modules (zero new windows), and the
verdict for the C96/C97 model.

**House rules.** **VERIFIED** = read out of an instruction, a relocation, a
symtab, the module's own modinfo, or the shipped kernel image — and
re-derivable with §8. **INFERRED** = reasoned from a pattern, labelled as such.

**A note on tooling that made this stage possible in one sitting:** the guest
kernel image (`evidence/bx510-guest/u4-initrd/kernel/kernel.gzip_member.out`,
raw 4,676,960 B, `stext` file offset 0) still carries its kallsyms tables, and
`kernel_decode_kallsyms.py` (this directory) recovers all **25 817** symbols
from it. That turns "compiled into the kernel, not available" into
"disassemble it": every kernel-side claim below is an extracted function, not
an inference from a symbol name.

---

## 0. Bottom line

1. **`0x8530` is received by `sr_mod.ko`'s own block-device ioctl, not by
   `scsi_ioctl` and not by any host-template hook.** `sr_block_ioctl`
   (`sr_mod.ko .text+0x6a0`) keeps the stock `SCSI_IOCTL_GET_IDLUN` /
   `SCSI_IOCTL_GET_BUS_NUMBER` early-outs, calls `cdrom_ioctl()`, and when that
   returns `-ENOSYS` runs a **Sony vendor chain**: `0x8530` →
   `mt85xx_ioctl()`. `mt85xx_ioctl` is not in any module — it is a **kernel-image
   export at `0xC01DEBB8`** which bounces the user struct and tail-calls
   `cdi->ops->generic_packet` = **`sr_packet`** (also `sr_mod.ko`) →
   **`sr_do_ioctl`** → **`scsi_execute()`** (kernel scsi_mod, `0xC01D40FC`) → the
   block layer → **libata `ata_scsi_queuecmd`** → **`sata_mt85xx_mod`** port ops →
   the already-modelled FE-mailbox/SATA path. *VERIFIED (§1).*
2. **The 44-byte request is `struct packet_command` — the kernel ABI struct, not
   a Sony private one.** `+0x18` is `cgc->sense`, a **64-byte**
   `struct request_sense`, not a 44-byte "reply". This corrects
   `sacdread-cpsa.md` §4.2 and closes its open question 2. *VERIFIED (§1.4).*
3. **`cbagent.ko` is the "Callback Agent":** a kernel↔userspace callback/event
   broker with its **own char device, major 242 minor 0 ("cbagent")**, whose
   CLI lane is `cbak`. It has **no SCSI, no block, no sr, no cdrom, no MMIO** —
   it is **not on the disc read path at all**. It *is* a hard load-order
   dependency of `bdpdrv.ko` (`GetCbkCmdTbl`, `vCBAgent_Cb_Nfy`,
   `vCBAgent_SyncCb_Nfy` are UND in bdpdrv). *VERIFIED (§2).*
4. **Stack assembly for `/dev/sr0` is four `insmod`s and one `mknod`:**
   `libata.ko` → `sata_mt85xx_mod.ko` → `cdrom.ko` → `sr_mod.ko`, then
   `mknod /dev/sr0 b 11 0`. Everything else that `sr_mod`/`cdrom`/`libata` need
   (scsi_mod, block layer, `mt85xx_ioctl`, `SR_LOG_Level`, every `mt85xx_*` /
   `svoif_*` / `_sata_*` data export) is **built into the kernel image**.
   *VERIFIED (§3).*
5. **Zero new MMIO windows.** A literal-pool + `movw`/`movt` scan of all five
   pulled modules (`cbagent, cbagent_test_ker, cdrom, ciphsv, sr_mod`) finds **no**
   `0xfd0xxxxx`/`0x70xxxxxx` constant anywhere; `mt85xx_ioctl`'s whole literal pool
   is one kmalloc-cache pointer and four strings. **No new `kernel-iomap.md`
   rows.** *VERIFIED (§4).*
6. **Verdict for C96/C97: no new register rows, no new MMIO — but three model
   requirements are now sharpened** (sense data, `data_direction` bouncing,
   profile 0x10), and one prior open number (2048 vs 2064) is **half-settled**:
   the host stack passes `cgc->buflen` (2064×n) straight to the device and never
   converts, so the extra 16 B/sector can only come from the drive. *VERIFIED
   for the stack, INFERRED for the drive (§5).*

---

## 1. Q1 — the `0x8530` receiver, traced instruction by instruction

### 1.1 Where it comes from (recap, now with the request named)

`_IDECLI_SendOddCmd` (`bdpdrv.ko 0xa92dc`, local `_IDECLI_SendOddCmd.clone.0`) is
the only producer of `0x8530`. Re-read this session with the request named:

```
a92e4  add  r7, sp, #108            ; r7 = &cgc     (packet_command, 44 B)
a92f4  x_memset(r7, 0, 44)
a930c  x_memcpy(r7, cdb, 12)        ; cgc.cmd[0..11]
a931c  ldr  r3, =0x2710             ; 10 000  (cgc.timeout, ms)
a9324  str  r3, [sp, #0x90]         ;   -> cgc+0x24
a9328  add  r3, sp, #44             ; r3 = sp+0x2c
a932c  str  r3, [sp, #0x84]         ;   -> cgc+0x18 = sense  (64 B local!)
a9334  strb r6, [sp, #0x88]         ;   -> cgc+0x1c = data_direction (arg1)
a9338  str  r5, [sp, #0x78]         ;   -> cgc+0x0c = buffer
a933c  str  r8, [sp, #0x7c]         ;   -> cgc+0x10 = buflen
a9368  ldr  r0, ="/dev/sr0" ; r1 = 2048 (O_NONBLOCK) ; sys_open
a9398  ldr  r1, =0x8530     ; sys_ioctl(fd, 0x8530, r7)
```

Two facts fall out immediately: the sense buffer is the 64 bytes
`sp+0x2c .. sp+0x6c` (**the cgc starts exactly where it ends** — no slack, so 64
is the intended size), and `data_direction` is a caller-supplied byte passed
through untouched. *VERIFIED.*

### 1.2 The receiver: `sr_block_ioctl` (sr_mod.ko)

`sr_mod.ko` is not stock. Its modinfo carries `parmtype=xa_test:int`,
`depends=cdrom`, and its `.rodata.str1.1` carries `[SR] CDB : %02X …` plus a
`"sata_mt85xx"` transport name. `.text+0x6a0` is `sr_block_ioctl`, 0x518 B long.
Decoded control flow:

```
6a0   push {…}                          ; sr_block_ioctl(bdev, mode, cmd, arg)
6c0   r6 = bdev->bd_disk ; r8 = disk->private_data (= cd) ; r6 = cd->sdev  [+8]
728   if (cmd == 0x5382 || cmd == 0x5386)  goto tail_scsi_ioctl
                                           ^^^^^ stock SCSI_IOCTL_GET_*_NUMBER
774   r8 = &cd->cdi                       ; cd->cdi is at cd+0x18
78c   err = cdrom_ioctl(cdi, bdev, mode, cmd, arg)
790   cmn  r0, #38                        ; == -ENOSYS ?
798   beq  0x7d0                          ; Sony vendor chain
7d0   if (cmd != 0x8530) goto vendor_8600
7dc   r0 = &cd->cdi ; r1 = cmd ; r2 = arg
7e8   bl  mt85xx_ioctl                    ; <-- THE RECEIVER
7ec   cmn r0, #38 ; beq 0xa7c             ; -ENOSYS -> fall through to stock
...
a7c   ret = scsi_nonblockable_ioctl(sdev, cmd, arg, (mode & FMODE_NDELAY) != 0)
a9c   cmn r0, #19 ; beq 0xb0c             ; -ENODEV -> stock scsi_ioctl
b0c   tail: scsi_ioctl(sdev, cmd, arg)
```

* So the ordering is **block-layer → `sr_block_ioctl` → `cdrom_ioctl`
  (`cdrom.ko`, returns `-ENOSYS` for commands it does not own) → Sony vendor
  chain → only then the stock `scsi_nonblockable_ioctl`/`scsi_ioctl` fallback.**
  `0x8530` never reaches `scsi_ioctl`, so it never reaches
  `scsi_host_template.ioctl` (which libata points at `ata_scsi_ioctl`). *VERIFIED
  (the `cmn r0,#38` / `cmn r0,#19` comparisons are the stock source structure of
  2.6.35 `sr_block_ioctl` present verbatim).*
* `mt85xx_ioctl` receives `r0 = &cd->cdi`, i.e. the `struct cdrom_device_info *`,
  and **never reads `r1` (cmd) at all** — the callee assumes 0x8530. *VERIFIED
  (r1 is not saved in the prologue and appears in no subsequent instruction).*

For completeness, the whole Sony vendor chain in `sr_block_ioctl`, with each
command's effect (all reached only after `cdrom_ioctl` → `-ENOSYS`):

| cmd | effect | target variable (kernel export) |
|---|---|---|
| `0x8530` | pass the `packet_command` to the ODD | `mt85xx_ioctl()` |
| `0x8600` | `arg` → | `ide_log_en` |
| `0x8601` | `arg` → `ide_cdb_log_en`; bit 1 of `ide_log_en` set/cleared to match | `ide_cdb_log_en` |
| `0x8602` | `arg` → | `sr_log_en` |
| `0x8603` | `arg` → | `sr_ioc_log_en` |
| `0x8604` | `arg` → | `cdrom_log_en` |
| `0x8a30` | `arg` → `linux_pms_check_en`; if non-zero also `mt85xx_clr_pms_result()`; prints `Linux Performance Check : Enable/Disable` | `linux_pms_check_en` |
| `0x8a31` | `mt85xx_get_pms_result(arg)`, returns its result | — |

*VERIFIED (each `cmp` literal and each `.rel.text` target read out of
`sr_mod.ko`).* Operational note: `0x8600..0x8604` are **runtime log switches for
the whole ODD stack**, settable from userspace with `ioctl(fd, 0x8602, 1)` etc.;
`sr_mod.ko` imports no `capable()`, so any holder of a readable `/dev/sr0` can
flip them. For the C9x rig this replaces a whole class of "why is sr silent"
debugging — see §3.4.

### 1.3 `mt85xx_ioctl` — a user↔kernel bounce around `generic_packet`

Symbol facts (kernel image, decoded kallsyms):

| symbol | address | note |
|---|---|---|
| `SR_LOG_Level` | `0xC01DE1D4` | function (imported by `sr_mod` and `cdrom`) |
| `mt85xx_get_pms_result` | `0xC01DEB38` | |
| `mt85xx_clr_pms_result` | `0xC01DEB9C` | |
| **`mt85xx_ioctl`** | **`0xC01DEBB8`** | size 0x284 (next symbol `default_mtd_writev` @ `0xC01DEE3C`) |
| `__ksymtab_mt85xx_ioctl` | `0xC0423910` | `__kstrtab_` @ `0xC0432B20` → it really is an export |

`mt85xx_ioctl` (`0xC01DEBB8..0xC01DEE3C`) decodes to:

```c
int mt85xx_ioctl(struct cdrom_device_info *cdi, unsigned int cmd /*unused*/,
                 unsigned long arg)
{
    struct packet_command cgc;                  /* sp+4,  44 B */
    struct request_sense *ksense;               /* kmalloc-64  */
    unsigned char *kbuf = NULL;
    void __user *ubuf, *usense;
    int ret;

    __memzero(&cgc, 44);
    if (!range_ok(arg, arg+44))        -> printk("(%s,%d) …"), -EFAULT
    if (__copy_from_user(&cgc, arg, 44)) -> "-EFAULT" (line 49)
    ubuf   = cgc.buffer;  cgc.buffer = NULL;    /* +0x0c */
    usense = cgc.sense;   cgc.sense  = NULL;    /* +0x18 */
    if ((cgc.data_direction - 1) <= 1)          /* WRITE(1) or READ(2) */
        kbuf = kmalloc(cgc.buflen, GFP_KERNEL); /* +0x10 */
    if (cgc.data_direction == CGC_DATA_WRITE)   /* == 1 */
        if (__copy_from_user(kbuf, ubuf, cgc.buflen)) -> -EFAULT
    ksense = kmem_cache_alloc(kmalloc-64, GFP_KERNEL);      -> -ENOMEM
    cgc.buffer = kbuf; cgc.sense = ksense;
    ret = cdi->ops->generic_packet(cdi, &cgc);  /* ops+0x38 */
    if (cgc.data_direction == CGC_DATA_READ && cgc.buflen)
        __copy_to_user(ubuf, kbuf, cgc.buflen);
    if (usense)
        __copy_to_user(usense, ksense, 64);     /* the 0x40 above */
    kfree(kbuf); kfree(ksense);
    return ret;
}
```

*VERIFIED:* every branch above is an instruction at `0xC01DEBB8+off`
(`__memzero` `+0x1c`/`+0x134`/`+0x1e4`, `__copy_from_user` `+0x50`/`+0x230`,
`kmem_cache_alloc` `+0x88`, `ops+0x38` indirect `+0xa8/+0xac`, `__copy_to_user`
`+0x220` with `r2 = 0x40`, `printk` `+0xf0/+0x24c/+0x264`); the literal pool
holds exactly `{&kmalloc-64 cache, "(%s,%d) Failed to copy from user",
"mt85xx_ioctl", "(%s,%d) Failed to copy to user", "(%s,%d) Failed to kmalloc"}`
and **no register address**.

`cdi->ops + 0x38` resolves to `sr_packet`: `sr_dops` is `sr_mod.ko` `.data+0x4c`
and the `.rel.data` records are `+0x00 sr_open, +0x04 sr_release, +0x08
sr_drive_status, +0x0c sr_media_change, +0x10 sr_tray_move, +0x14 sr_lock_door,
+0x18 sr_select_speed, +0x20 sr_get_last_session, +0x24 sr_get_mcn, +0x28
sr_reset, +0x2c sr_audio_ioctl, capability(+0x30)=0x002bfbfb, +0x38 sr_packet` —
i.e. `+0x38` is `generic_packet`, the last slot of 2.6.35's
`struct cdrom_device_ops`. *VERIFIED.*

```
sr_packet(cdi, cgc)      sr_mod.ko 0x3d4
  if (cgc->timeout <= 0) cgc->timeout = 0x7530 (30 000)   [literal @0x470]
  sr_do_ioctl(cdi->handle /* cdi+0x10 */, cgc);           [+0x424]
  return cgc->stat                                        [+0x14]
```

### 1.4 The 44-byte request, named — `struct packet_command`

| off | field | bdpdrv writer (`_IDECLI_SendOddCmd`) | kernel reader (`mt85xx_ioctl` / `sr_do_ioctl`) |
|---|---|---|---|
| 0x00 | `u8 cmd[12]` | `x_memcpy(cgc, cdb, 12)` | passed as the SCSI CDB |
| 0x0c | `u8 *buffer` | data pointer (`pBuf`) | bounced via `kmalloc(buflen)` for dir 1/2 |
| 0x10 | `u32 buflen` | `len` (= 2064 × sectors) | `kmalloc` size **and** `scsi_execute(bufflen)` |
| 0x14 | `int stat` | — (out) | `sr_packet` return value |
| 0x18 | `struct request_sense *sense` | **64-byte stack buffer** | replaced by kmalloc-64; copied back 64 B |
| 0x1c | `u8 data_direction` | arg1: `2` = READ | drives the bounce (`(d-1)<=1`) and the copy-back (`d==2`) |
| 0x20 | `int quiet` | 0 | suppresses the CDB dump |
| 0x24 | `int timeout` | `0x2710` = 10 000 ms | `sr_packet` only defaults it when `<= 0` |
| 0x28 | `void *reserved[1]` | 0 | — |

*VERIFIED* by the two disassemblies above (`data_direction = 2` is what
`_IDECLI_OddRead` and `_IDECLI_OddGetProfile` both pass — `mov r1,#2` at
`bdpdrv 0xa9a9c`). `CGC_DATA_{WRITE=1,READ=2,NONE=3}` are
`include/linux/cdrom.h` constants, not Sony's.

**Two corrections to `sacdread-cpsa.md` §4.2 follow:** (a) `+0x18` is
`cgc->sense` pointing at a **64-byte** `request_sense`, not a 44-byte "reply44" —
and `_IDECLI_OddTestUnitReady`'s mask reads `sense[2]&0x0F` (SK), `sense[12]`
(ASC), `sense[13]` (ASCQ), which is exactly the `request_sense` layout, so the
field naming in that doc was right and only the size/name were wrong; (b)
`+0x1c` is `data_direction`, so the model can tell a data-less command
(`3`) from a read (`2`) **from the request itself**, before any CDB decode.

### 1.5 The rest of the chain to ATA

```
sr_do_ioctl(cd, cgc)                       sr_mod.ko 0x2248
   sdev = cd->sdev                         [cd+8]
   ksense = cgc->sense ?: kmem_cache_alloc(kmalloc-64)   ; __memzero(ksense, 64)
   scsi_block_when_processing_errors(sdev)
   scsi_execute(sdev, cgc->cmd, cgc->data_direction, cgc->buffer,
                cgc->buflen, ksense, cgc->timeout, retries, NULL)   [0x2378]
   scsi_normalize_sense(...) on DRIVER_SENSE
```

`scsi_execute` is **kernel scsi_mod** (`0xC01D40FC`), *not* a module — there is
no `scsi_mod.ko` in the rootfs. From there the request is dispatched through
`sdev->request_queue` → `scsi_host_template.queuecommand` = `ata_scsi_queuecmd`
(**`libata.ko`**, exported `__ksymtab_ata_scsi_queuecmd`) → builds the ATAPI
`ATA_CMD_PACKET` taskfile → `sata_mt85xx_mod`'s `ata_bmdma_qc_issue` /
`sata_mt85xx_exec_command` → FE mailbox + A-window SATA, already modelled.
*VERIFIED for every hop; the libata→FE register detail is `sata-fw-load.md` /
`fe-ata-cmd.md` territory and untouched here.*

**So: nothing between `/dev/sr0` and libata translates the ioctl into ATA
commands.** `cdrom.ko`, `cbagent.ko` and bdpdrv's ODD layer are all absent from
the translation; the translation is stock libata below a Sony-instrumented
`sr_mod`/kernel ioctl shim.

---

## 2. Q2 — `cbagent.ko`: the Callback Agent, off the disc path

| property | value | evidence |
|---|---|---|
| device | **char device, major 242, minor 0, `cdev_add(MKDEV(242,0),1)`** | `mov r0,#253755392` (= 0x0F200000) at `vCBAgent_Kernel_Init+0x44`; `register_chrdev_region(dev, 1, "cbagent")` |
| node name | `cbagent` | `.rodata.str1.1+0x25` |
| fops | `owner`, `ioctl(+0x24)`, `open(+0x30)`, `release(+0x38)` — **no read/write** | `.rel.rodata` of `_cbagent_dev_fops` |
| exports (7) | `GetCbkCmdTbl`, `vCBAgent_Cb_Nfy`, `vCBAgent_Cb_Nfy_EX`, `vCBAgent_SyncCb_Nfy`, `vCBAgent_SyncCb_Nfy_EX`, `vCBAgent_Kernel_Init`, `vCBAgent_Kernel_Uninit` | `__ksymtab` |
| imports | **OSAL only** (`x_ev_group_*`, `x_sema_*`, `x_kmem_*`, `x_mem*`, `x_snprintf`, `x_strlen/strncmp`, `StrToInt`, `Assert`, `Printf`, `SYS_Printf`, `dump_stack`) + `cdev_*` + `__copy_from/to_user` | `llvm-nm -u` |
| init | `init_module` → `vCBAgent_Kernel_Init` → `cdev_init` + `register_chrdev_region` + `cdev_add` | `.init.text` |
| CLI | `GetCbkCmdTbl` → `_rCbagentKernelModCmdTbl` = `cbak` *"Cbagent kernel command"* with `CBAKdebugmsg`/`dl` *"cb debug level set"* | `.data` + strings |
| source path | `src/system/cbagent/cbagent_kernel.c` | `.rodata.str1.1+0x71` |

**What it is (VERIFIED from behaviour + strings):** a callback broker. Kernel
clients register a notification function (`vCBAgent_*_Nfy[_EX]`); userspace
opens `/dev/cbagent`, gets a per-pid manager block (`block_mem_base`,
`mgr_mem_base`, `ev_name_%d`, `_u4Bdp_Pid`), and the two ioctls
(`_iCBAgent_Ioctl_Get_Callback_Param`, `_iCBAgent_Ioctl_CB_Done`) pull the
pending notification parameters out of a shared block and signal completion
(`nfy_ex … up sema`, `cb_done …`). So: **an event-delivery path between driver
callbacks and the BDP user program, keyed by pid.**

**Is it on the disc read path?** No — three independent proofs:

1. Its 33-symbol UND set contains **no** `scsi_*`, `blk_*`, `sr_*`, `cdrom_*`,
   `ata_*` or `sg_*` symbol. *VERIFIED.*
2. No literal in the whole module is in `0xfd000000-0xfdffffff` or
   `0x70000000-0x77ffffff`. *VERIFIED (§4).*
3. The read leg (`_IDECLI_SendOddCmd`) touches exactly `/dev/sr0` + `0x8530`;
   nothing in it or below it references a callback broker. *VERIFIED (§1).*

**But it is a load-order dependency of bdpdrv:** `bdpdrv.ko`'s UND set contains
`GetCbkCmdTbl`, `vCBAgent_Cb_Nfy`, `vCBAgent_SyncCb_Nfy` → `cbagent.ko` must be
resident before `insmod bdpdrv.ko`, or bdpdrv's `init_module` fails to resolve.
*VERIFIED.*

**Side finding that closes a `drvcli-surface.md` §3.3 loose end:** three of the 48
bdpdrv CLI lanes were recorded as "getter whose literal is not a plain `.data`
reloc — table produced through the OS layer". They are **UND symbols in bdpdrv**
and resolve to three sibling modules:

| bdpdrv lane | getter (UND in bdpdrv) | provider module |
|---|---|---|
| 6 | `GetCbkCmdTbl` | **cbagent.ko** |
| 20 | `GetOsCmdTbl` | **osai.ko** |
| 25 | `GetRmkCmdTbl` | **rm.ko** |

*VERIFIED (`llvm-nm -u bdpdrv.ko` ∩ each module's `__ksymtab`).*

`cbagent_test_ker.ko` is the same pattern one level down — its own cdev, CLI lane
`cb_test` *"cb agent test"* with `sync_cb`/`async_cb`, exports
`cb_test_krn_init/uninit` + `GetCb_TestCmdTbl`. A self-test harness for cbagent;
nothing else references it.

`ciphsv.ko` (pulled because it is in the C9x dir listing) is **not** on the read
path either, but it is adjacent to the *decrypt* leg: it imports
`i4GCPU_CmdExec`, `i4GCPU_InstanceCreate`, `fgKmGet*ForIMTK`, `pGetImtkData`
(all bdpdrv) and its strings are the Widevine/VUDU/AES/Sign service
(`CIPHSV_IOCTL_CMD_WV_SET_ASSET_KEY`, `GCPU cmd, SEC_SW_DERIVECW_PROCESS`, …) on
its own cdev (`MKDEV(255,0)`). Same TrustZone wall as `sacdread-cpsa.md` §4.3:
it is a *client* of the GCPU, not a path around it. *VERIFIED for the imports
and the device; the secure-world behaviour stays INFERRED.*

---

## 3. Q3 — the stack assembly checklist (C9x+)

### 3.1 What is a module and what is built in

The rootfs ships **one** module directory, `/lib/modules/2.6.35/BDP/` (71 files,
no `modules.dep`, no `scsi_mod.ko`, no `sg.ko`, no `sd_mod.ko`). *VERIFIED.*

| needed by the read path | where it lives | evidence |
|---|---|---|
| `scsi_mod` (mid-layer: `scsi_ioctl`, `scsi_execute`, `scsi_register_driver`, `scsi_nonblockable_ioctl`, `scsi_setup_fs_cmnd`, `scsi_setup_blk_pc_cmnd`, `scsi_prep_fn`, `scsi_normalize_sense`) | **kernel image** | every one of those names resolves in the decoded kallsyms (`scsi_ioctl` `0xC01CFCA4`, `scsi_execute` `0xC01D40FC`, `scsi_execute_req` `0xC01D4224`) |
| block layer (`register_blkdev`, `blk_queue_prep_rq`, `sg_next`) | **kernel image** | kallsyms |
| **`mt85xx_ioctl`**, `mt85xx_clr_pms_result`, `mt85xx_get_pms_result`, `SR_LOG_Level` | **kernel image** (functions) | §1.3 |
| the log flags `sr_log_en`, `sr_ioc_log_en`, `cdrom_log_en`, `ide_log_en`, `ide_cdb_log_en`, `linux_pms_check_en`, `linux_pms_result` | **kernel image** (data, exported) | `__kstrtab_<name>` present for each |
| the FE/SATA data exports `_fg_fe_bootup`, `sata_int_ldr_fw`, `mt85xx_fefwmem_base`, `sata_hw_seg_buf`, `svoif_int_ldr_dram(_sz)`, `svoif_…_remap`, `_sata_tray_status`, `sata_mtd_read_buf`, `_sata_pb_buf_time`, `_SataCmdTimeout` | **kernel image** (data, exported) | `__kstrtab_<name>` present for each |
| `ata_*` (libata) | **`libata.ko`** (`depends=` empty) | modinfo |
| the ATA host/port (`ata_host_activate`, `ata_scsi_queuecmd`, `ata_bmdma_qc_issue`, `ata_sff_port_ops`) | **`sata_mt85xx_mod.ko`** (`depends=libata`) | modinfo + `__ksymtab` |
| `cdrom_ioctl`, `register_cdrom`, `cdrom_open` | **`cdrom.ko`** (`depends=` empty) | `__ksymtab` |
| `sr_block_ioctl`, `sr_packet`, `sr_do_ioctl` | **`sr_mod.ko`** (`depends=cdrom`) | modinfo + `.text` |

**Important correction to `drvcli-surface.md` §4:** the 13 KEXP "no" answers were
interpreted as "SoC internals we cannot resolve". Eleven of them
(`_fg_fe_bootup`, `sata_int_ldr_fw`, `mt85xx_fefwmem_base`, `sata_hw_seg_buf`,
`svoif_int_ldr_dram(_sz)`, `_sata_tray_status`, `sata_mtd_read_buf`, `cpu_cache`,
`mem_map`, `ide_log_en`, `cdrom_log_en`) are **data symbols**, and this kernel is
built **without `CONFIG_KALLSYMS_ALL`** — the decoded kallsyms table has 25 817
entries and **zero** data symbols, while every one of those names has a
`__kstrtab_` entry (i.e. it *is* exported by the kernel image and resolves
normally at `insmod`). A `grep -w /proc/kallsyms` probe **cannot** answer
"does this data import exist"; it can only answer it for functions.
*VERIFIED.* Two of the thirteen (`sata_int_ldr_fw`, `sata_hw_seg_buf`) are
function *pointers*, still data. Practical consequence: those KEXP lines are
**not** evidence that anything is missing from the guest.

### 3.2 The load order

```
1. (built into the kernel — nothing to insmod)
     scsi_mod, block layer, and the MT85xx FE/SATA control block that exports
     mt85xx_ioctl / SR_LOG_Level / _fg_fe_bootup / sata_int_ldr_fw / svoif_*
2. insmod libata.ko              # provides ata_*; sata_mt85xx_mod's symbol dep
3. insmod sata_mt85xx_mod.ko     # modinfo depends=libata  (hard)
     -> ata_host_activate() -> ATA/ATAPI identify -> scsi_device (type 5)
4. insmod cdrom.ko               # provides register_cdrom/cdrom_ioctl
5. insmod sr_mod.ko              # modinfo depends=cdrom  (hard)
     -> scsi_register_driver -> sr_probe -> register_cdrom + add_disk -> /dev/sr0
6. mknod /dev/sr0 b 11 0         # sr registers block major 11 (alias block-major-11-*)
```

Hard edges **VERIFIED** (`depends=` in modinfo) for 2→3 and 4→5. The 3↔5 order is
**not** enforced: `sr_mod` registers a `scsi_driver` and `scsi_register_driver()`
re-probes devices already on the bus, so `sr_mod` may load either side of
`sata_mt85xx_mod` — *INFERRED from standard driver-core `driver_register`
semantics; the imports (`scsi_register_driver`, `driver_unregister`) are
VERIFIED.*

Not required for the read path, but required for **bdpdrv** (and therefore for
the real daemon): `osai.ko` (OSAL — `x_*`, `GetOsCmdTbl`), `rm.ko`
(`x_rm_*`, `GetRmkCmdTbl`), `cbagent.ko` (`GetCbkCmdTbl`, `vCBAgent_*`),
`drvcli.ko` (`x_cli_*`, `cli_init`, `StrToInt/Hex`), and the
`bx510_osal_stub_a.ko` provider for `UTIL_Printf`/`Printf`/`SYS_Printf` +
`g_u4*log*`. *VERIFIED* (`bdpdrv.ko`'s 260-symbol UND set, `llvm-nm -u`).

**Corollary worth carrying into C9x+:** bdpdrv's UND set contains **no**
`scsi_*`, `blk_*`, `sr_*`, `cdrom_*` or `ata_*` symbol at all. bdpdrv does not
create a scsi host, does not allocate a gendisk, and does not own an ODD device
node; it is a *client* of `/dev/sr0` by path. Whatever the KEXP list probes, it
is not "bdpdrv's imports". *VERIFIED.*

### 3.3 The C9x shim path vs the real stack

`bx510_bdpvirt.ko` exists to supply the bdpdrv-side surface (assert/print/delay
and friends). It supplies **nothing** in §3.1's table: the four `insmod`s above
are the real stack, and they load live in the guest (KEXP3's 18/18 load gate for
`sr_mod`/`cdrom`). So the shim is orthogonal to `/dev/sr0`: once
libata + sata_mt85xx_mod + cdrom + sr_mod are in, the ODD is served by the real
Sony stack, and `0x8530` reaches the (kernel-resident) shim without any stub
involvement. *VERIFIED.*

### 3.4 Free instrument: the vendor log switches

Because `0x8600..0x8604` are plain `_IOC_WRITE`-style vendor numbers on
`/dev/sr0` with no capability gate, the whole ODD stack's tracing can be enabled
from userspace, at runtime, from the guest:

```c
int fd = open("/dev/sr0", O_RDONLY|O_NONBLOCK);
ioctl(fd, 0x8602, 1);   /* sr_log_en        -> sr_mod's (%s,%d) trace + [SR] CDB */
ioctl(fd, 0x8604, 1);   /* cdrom_log_en     */
ioctl(fd, 0x8600, 1);   /* ide_log_en       */
ioctl(fd, 0x8601, 1);   /* + ide_cdb_log_en */
```
`[SR] CDB : %02X %02X …` (`sr_mod .rodata.str1.1+0x295`) then dumps every CDB the
block layer sees, which is the cheapest available confirmation that a probe's
CDB actually reached the SCSI layer. *VERIFIED for the mechanics; not yet
exercised in the guest (see §9).* Recommend adding this as a `kcheck.sh`/shim
step **before** the next ODD probe, so a silent drive can be distinguished from
a silent stack.

---

## 4. Q4 — MMIO survey of the intermediate layers: **zero new windows**

Method (deterministic, §8): for each of the five pulled modules, every aligned
32-bit word in every allocatable section (`.text`, `.rodata`, `.data`,
`.init.text`, `.exit.text`, … `SHT_REL`/`.ARM.*`/`.modinfo` excluded) was tested
against `0xFD000000-0xFDFFFFFF` and `0x70000000-0x77FFFFFF`; and every
instruction was checked for `movw`/`movt` (none exist in these modules —
`llvm-objdump -d | grep -c movw|movt` = 0 for all five).

| module | MMIO literals | movw/movt |
|---|---|---|
| `cbagent.ko` | **0** | 0 |
| `cbagent_test_ker.ko` | **0** | 0 |
| `cdrom.ko` | **0** | 0 |
| `ciphsv.ko` | **0** | 0 |
| `sr_mod.ko` | **0** | 0 |

The kernel-side members were checked by reading their literal pools directly:
`mt85xx_ioctl`'s pool is `{&kmalloc-64, 4 strings}` only (§1.3), and
`sr_packet` (`0x3d4`) / `sr_do_ioctl` (`0x2248`) resolve everything through
`cgc` fields, globals and the SCSI API.

**New model rows: 0.** `kernel-iomap.md` needs no additions for this stage. The
first register access on the path is inside `sata_mt85xx_mod`'s port ops, which
`map.txt` already covers.

---

## 5. Q5 — verdict: does the C96/C97 model recipe change?

**No new rows, no new MMIO — but four refinements, one of which is load-bearing.**

1. **The answer surface is SCSI sense, not "a status byte".** The request carries
   a 64-byte `request_sense` and the caller (`_IDECLI_OddTestUnitReadyLoop`)
   masks `sense[2]&0xF | sense[12]<<8 | sense[13]`, expecting `0x23A00` /
   `0x23000` while no disc is present. The model therefore has to produce a
   *sense key + ASC + ASCQ triplet* on CHECK CONDITION — a model that only
   returns GOOD or a bare error code will make the driver poll 100 × 200 ms and
   then fail with nothing useful. This is already SR-2 in
   `sacdread-cpsa.md` §4.4; it is now *verified end-to-end* rather than inferred
   from a mask. *VERIFIED.*
2. **`data_direction` is visible before any CDB decode.** `+0x1c` is
   `CGC_DATA_READ(2)` / `NONE(3)`; `mt85xx_ioctl` kmallocs a bounce buffer for
   dir 1/2 only and copies back 64 B of sense always. So a model/responder can
   classify a request from the 44-byte header alone, and the *sense* buffer is
   always 64 bytes regardless of command. *VERIFIED.*
3. **The 2048-vs-2064 question is half-settled — on the host side.** The stack
   does **not** convert: `sr_do_ioctl` passes `cgc->buflen` (which bdpdrv sets to
   `2064 × sectors`) verbatim as `scsi_execute`'s `bufflen`, together with the
   12-byte CDB (`READ(10)`, byte 10 = `0x98`) unchanged, and no layer between
   there and libata touches either. Therefore the extra 16 bytes per sector
   **cannot** be synthesised by the host: either the drive returns 2064-byte
   frames for a `0x98` READ(10) (Sony/MediaTek vendor format) or the caller's
   buffer simply has 16 stale bytes per sector. The disc responder must decide,
   and the decidable experiment is a 1-sector read whose `buflen` is 2064: if
   the returned data's framing lands on `sector*2064` boundaries the drive
   frames at 2064. *VERIFIED for the host half; the drive half stays INFERRED
   (same open item as `sacdread-cpsa.md` §7.1, now narrowed by one side).*
4. **The profile gate is unchanged and still the daemon's gate:**
   `GET CONFIGURATION (0x46)` with `buflen = 20`, profile read as
   `be16(reply[6..7])`, compared against `0x10`. *VERIFIED* (`_IDECLI_OddGetProfile`
   `0xa9a54`: `x_mem_alloc(20)`, `mov r1,#2` (READ), `ldrbeq r2,[r4,#6]`,
   `ldrbeq r3,[r4,#7]`, `add r3, r3, r2, lsl #8`).

**Recipe delta for C96/C97:** keep the FE-mailbox/SATA register model as-is; add
(or confirm) the *device-answer* rows — 64-byte sense on CHECK CONDITION with
ASC 0x3A/0x30 while empty, `0x46` reply with profile `0x0010`, `0x28`+byte10=0x98
returning the SACD frame size the responder chooses. Nothing in the intermediate
stack adds a register question, so **the C96/C97 register model is not
perturbed** by switching from the C9x shim path to the real ODD stack — which is
the answer the brief asked for.

---

## 6. Corrections landed against earlier docs

| doc | was | now | evidence |
|---|---|---|---|
| `sacdread-cpsa.md` §4.2 | `+0x18 reply44` (44-byte reply) | `+0x18` = `cgc->sense`, a **64-byte** `struct request_sense`; the whole 44-byte struct is `struct packet_command` | §1.3/§1.4 |
| `sacdread-cpsa.md` §7.2 (open) | "44-byte `0x8530` request field meanings … INFERRED" | **resolved**: named field-by-field from both sides | §1.4 |
| `sacdread-cpsa.md` §4.2 | "`mt85xx_ioctl` … defined by no module … it is compiled into the guest kernel" | confirmed **and** located: `0xC01DEBB8`, size 0x284, exported at `__ksymtab` `0xC0423910`; body decoded (§1.3) | decoded kallsyms |
| `drvcli-surface.md` §4 | 13 KEXP "no" = "sibling-module/SoC internals we cannot resolve" | 11 of 13 are **kernel-resident data exports**; the probe is structurally blind to data symbols (no `CONFIG_KALLSYMS_ALL`) | §3.1 |
| `drvcli-surface.md` §3.3 | lanes 6/20/25 = "getter whose literal is not a plain `.data` reloc" | resolved: `GetCbkCmdTbl`→`cbagent.ko`, `GetOsCmdTbl`→`osai.ko`, `GetRmkCmdTbl`→`rm.ko` | §2 |

---

## 7. Provenance

| input | identity |
|---|---|
| `sr_mod.ko` | 34 944 B, ELF32 ARM `ET_REL`, not stripped, vermagic `2.6.35 preempt mod_unload ARMv6`, `depends=cdrom`, `parmtype=xa_test:int` |
| `cdrom.ko` | 85 276 B, `depends=` (empty) |
| `cbagent.ko` | 20 628 B, `license=Proprietary`, `depends=` |
| `cbagent_test_ker.ko` | 6 284 B, `license=Proprietary` |
| `ciphsv.ko` | 25 512 B, `license=Proprietary` |
| `osai.ko` / `rm.ko` | 64 848 B / 14 636 B (pulled only for the CLI-lane attribution) |
| `libata.ko` / `sata_mt85xx_mod.ko` | 193 620 B (`depends=` empty) / 69 452 B (`depends=libata`) |
| `bdpdrv.ko` | sha256 `6604f6cd…cf54`, 8 122 068 B |
| guest kernel | `evidence/bx510-guest/u4-initrd/kernel/kernel.gzip_member.out`, 4 676 960 B, raw `objcopy -O binary` image, `stext` = file offset 0 = VA `0xC0008000` |
| rootfs | `/tmp/rootfs` on the lab VM; `/lib/modules/2.6.35/` contains **only** `BDP/` |
| tools | `llvm-objdump`/`llvm-nm`/`llvm-objcopy` 22 (Homebrew LLVM), `kernel_decode_kallsyms.py` (this dir), python3 inline scanners |

---

## 8. Reproduce (every claim above, no hand-reading)

```sh
# 0. pull the modules (VM -> Mac)
for f in sr_mod cdrom cbagent cbagent_test_ker ciphsv osai rm; do
  make vm-pull-file FILE=/tmp/rootfs/lib/modules/2.6.35/BDP/$f.ko DEST=/tmp/oddmod
done

# 1. the 0x8530 receiver + the whole vendor chain  (Q1 §1.2)
llvm-objdump -dr --start-address=0x6a0 --stop-address=0xbb8 /tmp/oddmod/sr_mod.ko
#   literals at 0xb34..0xbb4 hold the cmd numbers and the .rel.text names of
#   ide_log_en/ide_cdb_log_en/sr_ioc_log_en/cdrom_log_en/linux_pms_check_en
llvm-objdump -r -j .rel.data /tmp/oddmod/sr_mod.ko        # sr_dops slots (sr_packet @ +0x38)

# 2. the kernel-side functions: address first, then bytes
python3 evidence/bx510-guest/bdpdrv/decode/kernel_decode_kallsyms.py \
        evidence/bx510-guest/u4-initrd/kernel/kernel.gzip_member.out > /tmp/ks.txt
grep -E "mt85xx_ioctl|SR_LOG_Level|mt85xx_(get|clr)_pms" /tmp/ks.txt
python3 - <<'EOF'
d=open('/Users/clint/code/sacd-reconstruct/evidence/bx510-guest/u4-initrd/kernel/kernel.gzip_member.out','rb').read()
open('/tmp/oddmod/mt85xx_ioctl.bin','wb').write(d[0x1DEBB8:0x1DEE3C])   # 0xC01DEBB8-stext
EOF
llvm-objcopy -I binary -O elf32-littlearm --rename-section .data=.text,code \
        /tmp/oddmod/mt85xx_ioctl.bin /tmp/oddmod/mt85xx_ioctl.o
llvm-objdump -d /tmp/oddmod/mt85xx_ioctl.o     # 0x88=kmem_cache_alloc, 0xac=ops+0x38 call,
                                               # 0x220=__copy_to_user len 0x40, pool @0x270
# the pool's absolute values are VA = 0xC0008000 + file_off (see §1.3 table)

# 3. the request layout on the caller side  (Q1 §1.1/§1.4)
llvm-objdump -dr --start-address=0xa92dc --stop-address=0xa94f0 /tmp/bdpdrv/bdpdrv.ko
llvm-objdump -s -j .text /tmp/bdpdrv/bdpdrv.ko | sed -n '/ a9480 /,/ a94b0 /p'   # 0x2710, 0x8530

# 4. cbagent  (Q2)
llvm-nm -u /tmp/oddmod/cbagent.ko | sed 's/^ *U //' | sort   # no scsi/blk/sr/cdrom
llvm-objdump -dr /tmp/oddmod/cbagent.ko | sed -n '/vCBAgent_Kernel_Init/,+40p'

# 5. MMIO sweep  (Q4)  — all five modules, all sections, plus movw/movt
python3 - <<'EOF'
import struct,glob,subprocess
for ko in sorted(glob.glob('/tmp/oddmod/*.ko')):
    d=open(ko,'rb').read(); n=0
    for i in range(0,len(d)-3,4):
        w=struct.unpack_from('<I',d,i)[0]
        if 0xFD000000<=w<=0xFDFFFFFF or 0x70000000<=w<=0x77FFFFFF: n+=1
    print(ko,n)
EOF

# 6. load order  (Q3)
llvm-objdump -s -j .modinfo /tmp/oddmod/sr_mod.ko        # depends=cdrom
llvm-objdump -s -j .modinfo /tmp/bdpdrv/sata_mt85xx_mod.ko | grep -a depends  # depends=libata
llvm-nm -u /tmp/bdpdrv/bdpdrv.ko | wc -l                 # 260, and: no scsi_*/blk_*
```

---

## 9. What did not resolve

1. **By how many bytes a SACD sector arrives** — narrowed, not closed (§5.3). The
   host side is now ruled out as the source of the 16-byte delta; only the drive
   can answer, and only a live/fixture 1-sector read at `buflen = 2064` will.
2. **The `0x98` bit semantics.** Now known to be CDB byte 10 of a `READ(10)`
   handed unchanged to libata, so the ATA layer sees it as the LBA field's high
   bits (`cdb[2..5]` LBA + `cdb[10]`). Whether libata's ATAPI path passes byte
   10 through untouched or masks it is a `libata.ko` question, not examined here.
3. **`mt85xx_ioctl`'s neighbours** `mt85xx_get_pms_result` / `mt85xx_clr_pms_result`
   / `SR_LOG_Level` bodies were located but not decoded; they only matter to the
   `0x8600..0x8a31` diagnostic chain, not to reads.
4. **`ciphsv.ko`'s device major (255) and whether it is loaded on a real player** —
   the C9x dir listing shows the file; nothing in this session shows it being
   insmodded.
5. **Whether the vendor log ioctls are reachable in the C9x guest** — the
   `/dev/sr0` node does not exist there until someone `mknod`s it, so §3.4 is a
   recommendation, not a demonstrated run.
