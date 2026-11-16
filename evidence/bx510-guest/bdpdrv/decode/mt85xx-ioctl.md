# `mt85xx_ioctl` (0x8530) — Sony's CDB-passthrough ioctl on `/dev/sr0`, decoded

Date: 2026-11-14. Settles the one row every earlier decode left **INFERRED**:
`sacdread-cpsa.md` §4.2/§7.2 said "the callee (`mt85xx_ioctl`) is inside the guest
kernel image, which is not in this evidence set". **It is in the evidence set** — it is
in `evidence/bx510-guest/u4-initrd/pulled/kernel.uImage`, the exact image the rig boots,
and it is an **exported** symbol: `__ksymtab_mt85xx_ioctl` = `{ 0xc01debb8,
"mt85xx_ioctl" }` at kernel file offset `0x23910c`. Everything below is read out of
those bytes and out of `sr_mod.ko` / `libata.ko` / `bdpdrv.ko`.

**House rules.** **VERIFIED** = read out of an instruction, a literal pool, a relocation,
a DWARF/symtab entry, or a data table — with the offset cited. **INFERRED** = consistent
with every instruction seen but not closed by one; the settling experiment is named.
Re-derivation: §7.

---

## 0. Bottom line

1. **0x8530 is handled in the guest kernel, not in `sr_mod.ko`.** `sr_mod.ko` only
   *routes* it: no standard (`cdrom_ioctl`) handler wants the number, so the block-ioctl
   path falls through `sr_block_ioctl`'s vendor branch into the **exported core-kernel**
   `mt85xx_ioctl` (`kernel 0xc01debb8`, `.text` file offset `0x1d6bb8`). *VERIFIED*
   (§1.1–§1.3.)
2. **`mt85xx_ioctl` is a generic 12-byte-CDB executor, not a READ builder.** It copies
   in a 44-byte request, replaces the caller's data/sense pointers with kernel buffers,
   and calls `cdi->ops->generic_packet` — which in this tree is **`sr_packet`**
   (`sr_mod.ko .text+0x3d4`, slot `sr_dops+0x38`) → `sr_do_ioctl` (`.text+0x2248`) →
   `scsi_execute` (`kernel 0xc01d40fc`) → block/SCSI mid-layer → `ata_scsi_queuecmd` →
   `atapi_xlat` → `ata_qc_issue` → `sata_mt85xx_qc_issue` → **the already-modelled FE
   mailbox**. *VERIFIED* (§1.)
3. **The 44-byte request struct is now fully pinned** (eight fields consumed by three
   different functions, offsets cited in §2), and the **44-byte "reply" is actually a
   64-byte raw SCSI sense buffer** — `bdpdrv` allocates exactly 64 bytes for it and the
   kernel copies out exactly 64 (`mov r2,#64`). `sacdread-cpsa.md`'s name `reply44` is a
   misnomer. *VERIFIED* (§2.2.)
4. **The READ(10) with byte 10 = `0x98` is built entirely by `bdpdrv`, and the kernel's
   only job is not to truncate it** — which it nearly does: stock `scsi_execute` copies
   `COMMAND_SIZE(cdb[0])` = **10** bytes for opcode `0x28`. **Sony patched the kernel's
   `scsi_command_size_tbl` to `{12,12,12,12,16,12,12,12}`** so every 6/10-byte CDB is
   transferred as a 12-byte ATAPI packet. Without that table patch the `0x98` byte could
   never reach the drive. *VERIFIED* (§3.2.) — this is the single most load-bearing new
   fact in this document.
5. **No new MMIO, no new MMIO window.** All five kernel-side functions in the chain have
   zero IO-VA literals; the register surface is unchanged and is the one C96/C97 already
   model. What the model owes for this ioctl is *ATAPI answers*, not registers. *VERIFIED*
   (§4.)
6. **C97's read path needs no register-level change**; it needs two assumptions recorded
   and (optionally) two new model rows: the descriptor byte count for the SACD ioctl read
   is **`qc->nbytes = 2064 × n`** (the kernel never reconciles the CDB block count with the
   buffer length — `sacdread-cpsa.md` §7.1's "single most load-bearing open number" is now
   closed on the host side), and the ATAPI packet carries the vendor byte
   (`byte10 = 0x98`) because of §0.4. *VERIFIED / one INFERRED row* (§5.)

---

## 1. Q1 — where 0x8530 is handled, and the exact call chain

### 1.1 Entry: `/dev/sr0` → the driver's `ioctl` fop

| hop | offset | what it does |
|---|---|---|
| `sys_ioctl` → `do_vfs_ioctl` | `kernel 0xc00a3d9c` / `0xc00a37e0` | cmd has **no `_IOC` dir/size bits** (`0x8530` = `_IO(0x85,0x30)`), so `do_vfs_ioctl` takes the `default:` arm — no automatic `copy_from_user`. *VERIFIED* |
| `blkdev_ioctl` | `kernel 0xc018570c` | block-device switch, unknown cmd → `__blkdev_driver_ioctl` |
| `__blkdev_driver_ioctl` | `kernel 0xc01853bc..0xc0185450` | `r6 = bdev->bd_disk` (`[r0,#0x4c]`), `r4 = disk->fops` (`[r6,#0x1a0]`), `r12 = fops->[0xc]`; if zero, takes `_lock_kernel()` + `fops->[0x8]` — i.e. the **BKL `ioctl` slot**, which is what `sr_mod` fills. Args passed as `(bdev, mode, cmd, arg)`, `arg` untouched. *VERIFIED* |
| `sr_block_ioctl` | `sr_mod.ko .text+0x6a0` | see §1.2 |

### 1.2 `sr_block_ioctl`'s vendor branch (`sr_mod.ko .text+0x6a0`)

```
 6b0..6c4   r10 = mode ; r5 = cmd ; r4 = arg ; r6 = bdev->bd_disk ([bdev+0x4c])
 6f0        r8 = disk->private_data            ([r6,#0x1a8])   = struct scsi_cd *
 6f8        r6 = [r8+0x8]                                       = struct scsi_device *
 728..73c   if (cmd == 0x5382 /*SCSI_IOCTL_GET_IDLUN*/ ||
                 cmd == 0x5386 /*GET_BUS_NUMBER*/) -> log+return
 774        r8 = r8 + 24        <-- r8 is now &scsi_cd->cdi (the cdrom_device_info)
 77c..78c   ret = cdrom_ioctl(cdi, bdev, mode, cmd, arg)          [cdrom.ko 0x8a44]
 790        cmn  r0,#38          ; ret == -ENOSYS ?
 798        beq  0x7d0
 7d0        ldr r3,=0x8530 ; cmp r5,r3 ; bne 0x82c
 7dc..7e8   mt85xx_ioctl(cdi, 0x8530, arg)        R_ARM_CALL mt85xx_ioctl
 7ec        cmn  r0,#38 ; ...
 82c        cmp r5,#34304 (0x8600) ...            <- other Sony cmds, below
```

Two facts worth carrying:

* **The vendor ioctl is only reachable through `-ENOSYS`.** `cdrom.ko`'s `cdrom_ioctl`
  returns `-38` from its default arm (`mvn r6,#37` at `cdrom.ko .text+0x9508` and
  `+0x97f0`), and `sr_block_ioctl` gates on exactly that. So `0x8530` must be a command
  no standard handler claims. *VERIFIED.*
* **`mt85xx_ioctl`'s first argument is `&cdrom_device_info`**, not a request queue and not
  a gendisk. The object chain (all *VERIFIED* offsets):
  `gendisk->private_data` (`gendisk+0x1a8`, set at `sr_probe .text+0x2080`) = `struct
  scsi_cd *`; `cdi = scsi_cd + 0x18`; `cdi+0x00` = `ops` (→ `sr_dops`);
  `cdi+0x10` = **back-pointer to the enclosing `scsi_cd`** (`str r4,[r4,#0x28]` at
  `sr_probe .text+0x1ca8`, and `0x28 = cdi+0x10` exactly); `scsi_cd+0x08` =
  `struct scsi_device *` (`sr_do_ioctl 0x2294`, `sr_probe 0x201c`);
  `scsi_device+0x04` = `request_queue` (proved by `scsi_execute 0xc01d4108`
  `ldr r0,[r0,#0x4]` feeding `blk_get_request`). Cross-check that `[cdi]` really is
  `ops`: `cdrom_ioctl 0x8bdc` does `ldr r3,[r7]` / `ldr r3,[r3,#0x30]` = `ops->capability`,
  and `sr_dops+0x30` holds `0x002bfbfb`. *VERIFIED.*

**The other Sony commands in the same gate** (context for the lane, from the same pool
`.text+0xb34..0xb60`): `0x8530` → `mt85xx_ioctl`; `0x8601`,`0x8602`,`0x8603`,`0x8604` →
store `arg` into kernel globals; `0x8a30` → `mt85xx_clr_pms_result` + printk; `0x8a31` →
`mt85xx_get_pms_result(arg)` (`kernel 0xc01deb38` / `0xc01deb9c`). None of these is on
the sacd read path. *VERIFIED.*

### 1.3 `mt85xx_ioctl` (`kernel 0xc01debb8..0xc01dee3c`, 0x284 bytes) — instruction walk

Exported (`__ksymtab` value/name verified, §7). Signature as called:
`long mt85xx_ioctl(struct cdrom_device_info *cdi, unsigned int cmd, unsigned long arg)`.

```
c01debb8  push {r4,r5,r6,r7,r8,r10,lr} ; sub sp,#52
c01debc0  r5 = sp+4                    ; the local 44-byte request
c01debc4  r8 = r0                      ; cdi
c01debd0  r4 = r2                      ; arg
c01debd4  __memzero(r5, 44)
c01debd8  r6 = sp & ~0x1FFF            ; current_thread_info()
c01debe4  r3 = [r6,#8]                 ; addr_limit
c01debe8  adds r2, r4, #44 ; sbcslo r2,r2,r3 ; movlo r3,#0 ; bne -> c01dece4
          ^ __range_ok(VERIFY_WRITE, arg, 44)      fail: printk(tbl.49) ; ret = -EFAULT(-14)
c01dec08  __copy_from_user(r5, arg, 44)         fail: printk(tbl.49) ; ret = -EFAULT
c01dec14  type  = *(u8*)(r5+0x1c)
c01dec18  ubuf  =  (r5+0x0c)   -> r10
c01dec1c  ureply=  (r5+0x18)   -> r4
c01dec24  (r5+0x0c) = 0                 ; the returned struct no longer has the user ptr
c01dec30  (r5+0x18) = 0
c01dec34  if ((u8)(type-1) > 1) goto c01dec38           ; types 1 and 2 take a data buffer
c01ded4c      s = __kmalloc(*(u32*)(r5+0x10), GFP_KERNEL /*0xd0*/)
c01ded60      (r5+0x0c) = s                             ; kernel buffer in the struct
c01ded68      if (type == 1) {                         ; user -> device
c01ded7c          if (__range_ok(VERIFY_READ, ubuf, len))
c01dede4              __copy_from_user(s, ubuf, len)    ; fail -> EFAULT
              }
c01dec38  rep = kmem_cache_alloc(generic 64-byte class, GFP_KERNEL)
c01dec4c  (r5+0x18) = rep                               ; kernel sense buffer in the struct
c01dec54  r3 = [r8]                    ; cdi->ops
c01dec60  r3 = [r3,#0x38]              ; ops->generic_packet
c01dec64  blx r3                       ; (cdi, &req)   <-- the whole SCSI path
c01dec70  r7 = r0
c01dec74  if (type == 2) {                             ; device -> user
c01ded0c      if (__range_ok(VERIFY_WRITE, ubuf, len))
c01dedd4          __copy_to_user(ubuf, s, len)          ; fail -> EFAULT
          }
c01dec78  if (ureply) {
c01dec84      if (__range_ok(VERIFY_WRITE, ureply, 64))
c01dedbc          __copy_to_user(ureply, rep, 64)       ; NOTE: 64, not 44
c01dec9c      fail: printk("(%s,%d) Failed to copy to user\n",121) ; EFAULT
          }
c01decb0  kfree(s) ; kfree(rep)
c01decd0  return (r4 /*copy err*/ ? r4 : r7 /*ops result*/)        ; VERIFIED
```

Printk strings it can emit (`.rodata`): `"(%s,%d) Failed to copy from user\n"`
(`0xc040d0fc`), `"(%s,%d) Failed to copy to user\n"` (`0xc040d0dc`), `"(%s,%d) Failed to
kmalloc\n"` (`0xc040d120`), all with `__func__ = "mt85xx_ioctl"` (`0xc0374ff8`) and a line
number. There is **no functional printk, no CDB validation, and no opcode whitelist** —
any 12 bytes are executed as a CDB.

### 1.4 The ops slot → `sr_packet` (`sr_mod.ko`)

`sr_dops` is `.data+0x4c`; its slot at **`+0x38` relocates to `sr_packet`** (VERIFIED by
`R_ARM_ABS32 sr_packet` at `.data+0x84`). The table as read (relocation + `capability`):

| dops+ | value | dops+ | value |
|---|---|---|---|
| 0x00 | `sr_open` | 0x20 | `sr_get_last_session` |
| 0x04 | `sr_release` | 0x24 | `sr_get_mcn` |
| 0x08 | `sr_drive_status` | 0x28 | `sr_reset` |
| 0x0c | `sr_media_change` | 0x2c | `sr_audio_ioctl` |
| 0x10 | `sr_tray_move` | 0x30 | `0x002bfbfb` (`capability`) |
| 0x14 | `sr_lock_door` | 0x34 | NULL |
| 0x18 | `sr_select_speed` | **0x38** | **`sr_packet`** |
| 0x1c | NULL | | |

`sr_packet` (`.text+0x3d4`), complete body:

```
3dc  r3 = [cgc+0x24]              ; timeout
3e4  if (r3 <= 0) [cgc+0x24] = 0x7530        ; IOCTL_TIMEOUT = 30000 jiffies = 30 s
424  r0 = [cdi+0x10]              ; = &scsi_cd (the back-pointer, §1.2)
430  sr_do_ioctl(scsi_cd, cgc)
464  return [cgc+0x14]            ; the stat field
```

So the "generic packet" entry point is reached with `cgc` = the kernel's *own* 44-byte
request, not a `struct packet_command`. Sony re-pointed `sr_packet` at their struct.

`sr_do_ioctl` (`.text+0x2248`) — the only function that talks to SCSI:

```
2294  r7 = [r6+0x8]                        ; sdev = scsi_cd->device
2260  r5 = [cgc+0x18]                      ; sense buffer (caller-provided or NULL)
229c  if (!r5) r5 = kmem_cache_alloc(kmalloc_caches+0x84, GFP_KERNEL)   ; the 64-byte sense
22c8 loop:
        scsi_block_when_processing_errors(sdev)      ; fail -> -ENODEV(-19) at 0x2498
22d8    __memzero(r5, 64)                         ; sense cleared to 64 bytes
2300    if (sr_ioc_log_en) printk("[SR] CDB : %02X ... x12")
234c    r3 = [cgc+0x10]                   ; bufflen
2350    r2 = *(u8*)(cgc+0x1c)             ; data_direction
2354    stack: bufflen, sense, timeout=[cgc+0x24], retries=0, flags=0, resid=NULL
2374    r3 = [cgc+0xc]                    ; buffer
2370    r0 = sdev ; r1 = cgc              ; the CDB is cgc+0x00 .. +0x0b
2378    scsi_execute(...)
238c    scsi_normalize_sense(r5, 64, &sshdr on stack)
2390    if (driver_byte(result) == 0) goto 0x2488
2398    switch (sshdr.sense_key /*[sp+0x31]*/) {
          case 2  NOT_READY:     asc/ascq 0x04/0x01 -> "CDROM not ready yet."
                                 else "CDROM not ready.  Make sure there is a disc..."
                                 err = -123                       (0x247c, mvn r10,#122)
          case 5  ILLEGAL_REQ:   ASC==0x20 -> err = -EOPNOTSUPP(-95) if ASCQ==0, else -EIO
          case 6  UNIT_ATTEN:    *(u8*)(sdev+0x7c) |= 4 ; "disc change detected."
                                 retry up to 11 total, then err = -123
          default:               printk("<3>%s: CDROM (ioctl) error, command: ")
                                 + __scsi_print_command(cgc) + scsi_print_sense_hdr
                                 err = -EIO(-5)
        }
2488    if (status_byte(result) != 0) err = -EIO
249c    if (![cgc+0x18]) kfree(r5)
24b0    [cgc+0x14] = err ; return err
```

The `if ([cgc+0x20])` tests at `0x23c4`, `0x2404`, `0x241c` are the **`quiet`** switch —
a non-zero value suppresses every printk in this function but changes no error code.

### 1.5 `scsi_execute` (`kernel 0xc01d40fc`) — the block-layer handoff

`scsi_execute(sdev, cmd, data_direction, buffer, bufflen, sense, timeout, retries,
flags, resid)` (arg order proved by the callee's own reads: `[sp+0x28]`=bufflen,
`[sp+0x2c]`=sense, `[sp+0x30]`=timeout→`[rq+0xbc]`, `[sp+0x34]`=retries→`[rq+0xc0]`,
`[sp+0x3c]`=resid):

```
c01d4108  blk_get_request(sdev->request_queue /*[sdev+0x4]*/, write, GFP_ATOMIC)
c01d4150  blk_rq_map_kern(q, rq, buffer, bufflen, 16)   ; len > max_hw_sectors<<9 -> -EINVAL
c01d4164  r3 = scsi_command_size_tbl ; r2 = cmd_len = tbl[cmd[0]>>5]     <-- Sony table
c01d4174  [rq+0x9c] = cmd_len
c01d4178  if (*(u8*)[rq+0x98] == 8 || == 10) cmd_len = 6   ; vendor quirk, see §6.4
c01d4190  memcpy([rq+0x98], cmd, cmd_len)                 ; the CDB, cmd_len bytes
c01d419c  [rq+0xac] = sense ; [rq+0xa4] = 0 (sense_len)
c01d41bc  [rq+0x24] = REQ_TYPE_BLOCK_PC(2) ; [rq+0x20] |= flags|REQ_QUIET|REQ_PREEMPT
c01d41dc  blk_execute_rq(rq->q, NULL, rq, 1)
c01d420c  return [rq+0x84]          ; req->errors (driver<<24 | status<<16 | ...)
```

### 1.6 Joining to the FE mailbox (the half C97 already had)

```
block/SCSI mid-layer  → host template queuecommand
  → ata_scsi_queuecmd          libata.ko .text+0xc0c0   (sata_mt85xx_mod.ko imports it)
  → ata_scsi_translate         libata.ko .text+0x8b78
  → atapi_xlat                 libata.ko .text+0x8cec
        memcpy(qc->cdb, scsicmd->cmnd, scsicmd->cmd_len)      ; 12 bytes, see §3.2
        qc->nbytes from scsi_bufflen -> tf.lbam/lbah (clamp 0xFC00)
  → ata_qc_issue               libata.ko .text+0x2f64
  → sata_mt85xx_qc_issue       sata_mt85xx_mod.ko .text+0x3628 (-> ata_bmdma_qc_issue)
  → qc_prep / tf_load / exec_command / qc_issu_task / data_xfer
        = c97-read-path.md §1.1, unchanged: 0x5c400 descriptor + 0x5c000..0x5c020 mailbox
          (memcpy(priv+0x24, qc->cdb, 12) at 0x704c..0x7068 — the CDB blob the FE sees)
```

`sense` for a failed read is **not** injected by the model directly: libata's
`ata_scsi_qc_complete` (`libata.ko 0x9b80`) → `ata_gen_passthru_sense` (`0x8a10`) /
`ata_to_sense_error` (`0x8864`) translate the ATA status/error registers into the fixed
format sense the 64-byte buffer receives. The model therefore influences ASC/ASCQ through
the **ATA status/error** it returns, not through a sense blob. *(Functions VERIFIED
present at those offsets; the exact translation table not decoded here — §6.2.)*

---

## 2. Q2 — the 44-byte request struct, field by field

### 2.1 Layout as the handler consumes it (all offsets from the caller's base)

| off | size | meaning | evidence (instruction) |
|---|---|---|---|
| `0x00` | 12 | **CDB**, raw and unvalidated. Never read by `mt85xx_ioctl` itself; passed by pointer as `scsi_execute`'s `cmd` | `mt85xx_ioctl 0xc01dec5c` (`r1 = &req`), `sr_do_ioctl 0x2374` (`r1 = cgc` → `memcpy([rq+0x98], cmd, cmd_len)`), `bdpdrv 0xa931c` (`memcpy(req, cdb, 12)`) |
| `0x0c` | 4 | **data buffer address**. In: user (or, from `bdpdrv`, *kernel*) pointer. `mt85xx_ioctl` **overwrites it** with its own kernel buffer before the call | read `0xc01dec18`; zeroed `0xc01dec24`; kmalloc stored `0xc01ded60`; consumed `sr_do_ioctl 0x2374` → `scsi_execute` `buffer` |
| `0x10` | 4 | **byte length** of that buffer (`__kmalloc` size, `blk_rq_map_kern` len, `qc->nbytes`) | `0xc01ded4c`, `sr_do_ioctl 0x234c` → stack arg `bufflen` |
| `0x14` | 4 | **status / result, OUT**. The ioctl's own return is a *copy error* if one occurred, else this value | written `sr_do_ioctl 0x24b0` (`[cgc+0x14] = err`), read `sr_packet 0x464` (function return) |
| `0x18` | 4 | **sense buffer address**, **exactly 64 bytes**. Out: replaced by the kernel's own 64-byte slab object | read `0xc01dec1c`; zeroed `0xc01dec30`; `kmem_cache_alloc` stored `0xc01dec4c`; `__memzero(r5,64)` `0x22d8`; `scsi_normalize_sense(r5,64,…)`; `__copy_to_user(…, 64)` `0xc01dedc0` |
| `0x1c` | 1 | **data direction**, `enum dma_data_direction`: `1` = `DMA_TO_DEVICE` (host→device), `2` = `DMA_FROM_DEVICE` (device→host), anything else = no data phase | gate `c01dec20`/`c01dec2c` (`(u8)(t-1) <= 1`), selector `0xc01dec74`, value → `scsi_execute` `data_direction` at `sr_do_ioctl 0x2350` |
| `0x20` | 4 | **`quiet`** — non-zero suppresses `sr_do_ioctl`'s printks; no effect on status | `0x23c4`, `0x2404`, `0x241c` |
| `0x24` | 4 | **timeout in jiffies**; `<= 0` ⇒ `sr_packet` forces `0x7530` (30 s). `bdpdrv` writes `0x2710` (**10 s**, `HZ == 1000` — `msecs_to_jiffies` is an identity function in this image) | `sr_packet 0x3dc..0x3f0`; `sr_do_ioctl 0x2358` → `scsi_execute` `timeout` → `[rq+0xbc]` |
| `0x28` | 4 | **never read** by `mt85xx_ioctl`, `sr_packet`, or `sr_do_ioctl`. Zero from `bdpdrv`. Treated as reserved | exhaustive load scan of all three functions — no `[rX,#0x28]`/`+0x2b` in the handler path |

`mt85xx_ioctl` reads *exactly four* fields out of the struct (`0x0c`,`0x10`,`0x18`,`0x1c`)
and rewrites two of them; everything else reaches `sr_packet` byte-for-byte as the caller
wrote it. The struct is 44 bytes because `0x28 + 4 = 0x2c`; the last word is unused.

### 2.2 The reply buffer is 64 bytes of raw SCSI sense, not a 44-byte struct

* `bdpdrv`'s `_IDECLI_SendOddCmd` (`bdpdrv.ko .text+0xa92dc`) places a **64-byte** buffer
  immediately below the 44-byte request: `add r3,sp,#44 ; str r3,[sp,#0x84]` stores
  `sp+0x2c` into `req+0x18`, and `sp+0x2c..sp+0x6b` is exactly 64 bytes (`req` starts at
  `sp+0x6c`). *VERIFIED.*
* The kernel copies out exactly 64 bytes (`mov r2,#64` at `0xc01dedc0`). *VERIFIED.*
* Its content is whatever the device's sense became; `bdpdrv` decodes a 24-bit triple out
  of it (`bdpdrv 0xa93b4..0xa9424`): `status = ((reply[2] & 0x0f) << 16) | (reply[0x0c]
  << 8) | reply[0x0d]`, printed as `SenseKey: %06x`. That is the **fixed-format sense**
  layout: `[0]` response code `0x70/0x71`, `[2]&0xf` sense key, `[7..10]` information
  (the residual LBA), `[12]` ASC, `[13]` ASCQ. *VERIFIED* (bdpdrv's own byte offsets).

### 2.3 What `bdpdrv` writes (the producer side, for symmetry)

`_IDECLI_SendOddCmd` (`0xa92dc`) is a 6-argument call
`(u8 *cdb, u8 type, void *buf, u32 len, u32 arg5, u32 *outStatus)`:

```
memset(req,0,44) ; memcpy(req, cdb, 12)
req+0x24 = 0x2710 (10000 jiffies)          ; .text+0xa9488
req+0x18 = 64-byte stack sense buffer
req+0x1c = type (u8) ; req+0x0c = buf ; req+0x10 = len
set_fs(KERNEL_DS): thread_info+0x8 := 0, domain reg via mcr p15,c3   ; 0xa9330..0xa9364
fd = sys_open("/dev/sr0", O_RDONLY|O_NONBLOCK /*0x800*/, 0)
ret = sys_ioctl(fd, 0x8530, req)              ; .text+0xa9498 = 0x8530
restore set_fs ; sys_close(fd)
if (ret) printk CDB + "SenseKey: %06x" ; *outStatus = triple
return ret ? -1 : 0
```

Two consequences worth recording: (a) `bdpdrv` passes **kernel** pointers through a
*uapi* interface, which only works because it clears `addr_limit` first — this is why
`mt85xx_ioctl`'s `__copy_from_user/__copy_to_user` are doing `memcpy` in practice;
(b) the ioctl's own return is 0 or −1 only — all diagnosis rides in the sense buffer.
*VERIFIED.*

---

## 3. Q3 — what happens for a READ, and what is returned

### 3.1 The kernel builds nothing

`mt85xx_ioctl` and every function below it treat `req+0x00..0x0b` as opaque. **The
READ(10) and the `0x98` byte come from `bdpdrv`.** `_IDECLI_OddRead`
(`bdpdrv.ko .text+0xaa3d8`, `(u32 lba, u32 count, void *buf, u32 len, u8 sacd_flag)`)
builds:

```
cdb[0] = 0x28                       ; READ(10)
cdb[2..5] = lba, big-endian         ; strb lba>>24, >>16, >>8, lba
cdb[7..8] = count, big-endian       ; strb count>>8, count
cdb[10]  = sacd_flag ? 0x98 : 0      ; movne r10,#152 ; strb r10,[sp,#0x16]
type     = 2 (DMA_FROM_DEVICE)      ; mov r1,#2
len      = the caller's byte length  ; from sacd_read.ko: 2064 x sectors
outStatus = NULL
```

So: **LBA = CDB bytes 2–5, block count = CDB bytes 7–8, byte length = a separate
argument.** Nothing in the kernel compares the two. *VERIFIED.*

### 3.2 The `0x98` byte would have been truncated — except Sony patched the size table

Stock 2.6.35 `scsi_execute` copies `COMMAND_SIZE(cdb[0])` bytes. For `0x28` (group 1) that
is **10**, which would leave `req->cmd[10] = req->cmd[11]` stale and the vendor byte dead.
This kernel's table (`kernel 0xc036ee20`, 8 bytes) reads:

```
scsi_command_size_tbl = { 12, 12, 12, 12, 16, 12, 12, 12 }      stock: {6,10,10,12,16,12,10,10}
```

so `cmd_len = 12` for `0x28` and the whole CDB, `byte10 = 0x98` included, is copied into
`rq->cmd` and then into `qc->cdb` (`atapi_xlat`, which copies `scsicmd->cmd_len` bytes —
`ldrh r2,[r5,#0x2a]`, with `[r5+0x2c] == DMA_NONE` proving `r5` is the `scsi_cmnd`).
The FE mailbox therefore receives a 12-byte CDB blob with `byte10 = 0x98`, exactly as
`c97-read-path.md` §1.1 (`memcpy(priv+0x24, qc->cdb, 12)` at `0x704c`) assumed.
*VERIFIED.* (The 6-byte special case: `scsi_execute` forces `cmd_len = 6` when opcode is
`0x08`/`0x0a` — *before* the CDB copy, so it tests stale memory; harmless for `0x28`.
§6.4.)

### 3.3 Byte count: the kernel synchronises 2064, it does not enforce 2048

* `scsi_execute` maps exactly `bufflen` bytes. `blk_rq_map_kern` (`kernel
  0xc0183128`) rejects only `len == 0` and `len > max_hw_sectors<<9` (`-EINVAL` at
  `0xc018314c`/`0xc0183160`); an unaligned buffer merely switches to a bounce copy
  (`0xc0183178`, `dma_alignment|dma_pad_mask`). **No block-size multiple is required**, so
  `2064 × n` passes for any `n` (and 2064 is 16-byte aligned anyway).
* `atapi_xlat` takes `qc->nbytes` from `scsi_bufflen` and writes it into the ATAPI
  transfer count (`tf.lbam/lbah`, clamped to `0xFC00` = 64512).
* `sata_mt85xx_qc_issu_task` then sets `priv+0x54 = qc->nbytes` and arms
  `0x5c404 = priv+0x54` (`c97-read-path.md` §1.2).

So for a SACD read the FE is asked to DMA **`2064 × n`** bytes while the CDB says `n`
blocks. **`sacdread-cpsa.md` §7.1's "single most load-bearing open number" is now closed
on the host side**: nothing between the daemon and the drive assumes 2048. Whether the
drive answers in 2064-byte units is still the device's secret (§6.1).

### 3.4 Return values

| outcome | value |
|---|---|
| success | `0` — `scsi_execute` returns `rq->errors == 0`, `sr_do_ioctl` stores `0` at `req+0x14`, `sr_packet` returns it, `mt85xx_ioctl` returns it, `sys_ioctl` returns 0 |
| uaccess failure (`mt85xx_ioctl`) | `-EFAULT` (−14) |
| allocation failure (either layer) | `-ENOMEM` (−12) |
| `scsi_block_when_processing_errors` refused | `-ENODEV` (−19) (`sr_do_ioctl 0x2498`) |
| NOT READY (key 2), incl. ASC/ASCQ `0x04/0x01` | `-123` after the printk (raw `mvn r10,#122`) |
| ILLEGAL REQUEST ASC `0x20` (unsupported opcode) | `-EOPNOTSUPP` (−95) if ASCQ 0, else `-EIO` (−5) |
| UNIT ATTENTION (key 6) | up to 11 `scsi_execute` attempts, then `-123`; sets bit 2 of `sdev+0x7c` |
| any other CHECK CONDITION, or nonzero status byte | `-EIO` (−5) |

The **sense triple is the real payload**; the errno is coarse. `bdpdrv` logs
`SenseKey: %06x` and returns −1 to its own caller. *VERIFIED.*

---

## 4. Q4 — MMIO: none, and no new window is owed

* `mt85xx_ioctl`, `sr_packet`, `sr_do_ioctl`, `scsi_execute` and `__blkdev_driver_ioctl`
  contain **zero** IO-VA literal-pool values. (Method: the disassembler annotates any pool
  value in `0xf0000000..0xfeffffff` as `IO VA (phys …)`; grepping all five functions
  returns 0 hits. *VERIFIED.*)
* The handler is pure `copy_to/from_user` + slab + SCSI. Sony put the vendor hook in the
  **block layer**, but the hook itself never touches a register.
* The only register surface the whole ioctl reaches is the SATA/FE path:
  `0x5c400/0x5c404` descriptor, `0x5c408/0x5c40c`, `0x5c000..0x5c020` mailbox — every one
  of which is already a C96/C97 row. **New MMIO windows owed: none.**
* The neighbouring Sony ioctls that *do* have a register/state flavour (`0x8a30`/`0x8a31`
  → `mt85xx_clr_pms_result` / `mt85xx_get_pms_result`, `kernel 0xc01deb9c`/`0xc01deb38`)
  are not on the read path and are not modelled.

What the model owes *instead* of registers, for this lane: the **ATAPI packet contents**
(12 bytes with `byte10 = 0x98`) and the **transfer byte count** (`2064 × n`), both of which
arrive in the FE mailbox words (`w1..w3` = CDB, `0x5c404` = count) — i.e. ordinary
device-side answers.

---

## 5. Q5 — does the C97 read path need a change?

**No register or descriptor change.** `c97-read-path.md`'s rows (§1.2, §3, §5) all stand:
the arm order, the doorbell key, the type-0 reply, the `0xbb` poison, the strip loop. The
ioctl decode adds no new access pattern.

Three notes that *are* worth folding in:

1. **Byte count is not `2048 × cdb_count`.** C97 §1.1 phrases the non-raw branch as "the
   CDB is posted unmodified with `len = qc->nbytes` (2048-byte sectors)". For the SACD
   ioctl path `qc->nbytes = 2064 × n` (§3.3), so the parenthetical must be relaxed: the FE
   must serve `0x5c404` bytes for *whatever* `n` requests, and `2064` is a legal answer.
   A model that recomputes the length from the CDB's block count would truncate every
   SACD read. **This is the one real risk the decode retires.**
2. **Expect `byte10 = 0x98` to arrive.** Because of the patched size table (§3.2) the FE
   sees the vendor byte, so the responder can key SACD framing off `cdb[10]` — and must
   not treat `0x28` with a non-zero group byte as a malformed CDB (`sacdread-cpsa.md`
   §7.5's INFERRED label is now resolved in the direction "the drive really does see it").
3. **Sense/ASC comes from the ATA status.** For a failing read the 64-byte sense buffer is
   synthesised by libata (`ata_gen_passthru_sense` / `ata_to_sense_error`) from the ATA
   status/error the FE returns — the model should produce a plausible ATA error
   (`ERR`/`ABRT`/`IDNF` + `error` register), not try to inject SCSI sense. Consequence for
   `_IDECLI_OddTestUnitReadyLoop`'s `ASC 0x3A/0x30` expectations: those come out of that
   translation. *(Row candidate; the mapping table itself is §6.2.)*

Optional new model rows this decode justifies:

| id | row | evidence | verdict |
|---|---|---|---|
| SR-10 | the FE is asked for `2064 × n` bytes for a SACD READ(10), independent of the CDB block count | §3.3 | model row — replaces the "2048 or 2064?" question |
| SR-11 | the ATAPI packet for a SACD read is 12 bytes with `byte10 = 0x98` (Sony size-table patch) | §3.2 | model row |
| SR-12 | a UNIT-ATTENTION answer is retried up to 11× by `sr_do_ioctl` before `-123`; a NOT READY answer returns immediately | §3.4 | timing/behaviour note — a model that answers UA forever stalls ~11 round trips and then fails |

**Non-finding, for the security lane (not scored here, not disclosed):** ioctl `0x8530`
is a generic 12-byte-CDB executor reachable from `sr_block_ioctl` with **no capability
check and no opcode filter** — buffer, length, timeout and CDB are all caller-chosen. Any
context that can `open("/dev/sr0")` can post arbitrary ATAPI commands (and `mt85xx_ioctl`
even sets up kernel buffers for it). Whether that is reachable by an unprivileged user is
a *permissions* question (`/dev/sr0` mode), not a code-path question — **INFERRED**,
untested, and out of scope for this decode.

---

## 6. What did not resolve (honest gaps)

1. **The drive's own framing.** The kernel hands it `2064 × n` bytes and `byte10 = 0x98`;
   whether the device actually returns 2064-byte units is still device-side. This decode
   removes the *host* alternative hypothesis only.
2. **The ATA→sense translation table.** `ata_to_sense_error` (`libata.ko 0x8864`) and
   `ata_gen_passthru_sense` (`0x8a10`) exist at those offsets (*VERIFIED*) but their
   entry tables were not decoded, so "this ATA error yields that ASC/ASCQ" is **INFERRED**.
   Settling experiment: feed the FE a chosen ATA status/error and read back the 64-byte
   sense through the ioctl.
3. **Identity of the 64-byte allocation class** `0xc0458318` (`.bss`-adjacent, zero in the
   image, referenced by ~99 `kmem_cache_alloc` sites across unrelated subsystems, and the
   same address `sr_do_ioctl` spells `kmalloc_caches+0x84`). The copy-out length is 64
   (*VERIFIED*); that the class object *is* 64 bytes is **INFERRED** from
   copy-out length + shared-literal generality.
4. **`scsi_execute`'s `cmd_len` quirk.** At `0xc01d4178` the vendor code tests the first
   byte of the CDB *destination* pointer (`[rq+0x98]`) against `0x08`/`0x0a` and forces
   `cmd_len = 6` — before the `memcpy`, so it reads stale content. This implies a
   vendor-modified `struct request` whose CDB is a pointer at `+0x98` (**INFERRED**; the
   alternative — an inline array — would fault on the real player). Harmless for
   opcode `0x28`, but it is a live trap for any 6-byte-command path.
5. **`cdi+0x10`'s field name.** The offset and its use (back-pointer to `scsi_cd`) are
   *VERIFIED*; whether the vendor calls it `handle` is **INFERRED** from mainline
   `cdrom_device_info`. The struct is vendor-modified (`scsi_cd.cdi` sits at `+0x18`; the
   `ops` table has `generic_packet` at `+0x38` and no `check_events`/`select_disc` slots),
   so no mainline layout may be assumed anywhere in this chain.

---

## 7. Reproduce

Inputs (hashes are of the exact files decoded):

| artifact | sha256 |
|---|---|
| `evidence/bx510-guest/u4-initrd/pulled/kernel.uImage` (rig's own `-kernel`) | `10bb0fba4eb26c5b1ebf798f4d4669dc8b5899d520be294d333c318a360be2d7` |
| raw vmlinux after unwrap (`kernel_decode_image.py`) | `cd1cf0cb47d88c14877d49beb0c10a1507424c51892e7fec35347b26c05577de` |
| `sr_mod.ko` (rootfs `/lib/modules/2.6.35/BDP/`) | `82709342e63d37e698b0c0313e46b790b938e2617cfa08eea3a13a1a36557a1a` |
| `libata.ko` | `e28ac41ad4f808c4b9768858533ab295547730618eaa4f656f6124a806c95354` |
| `cdrom.ko` | `df8835ea7ee58ae8048cadb9574a77dad5755d75fdc170e5424df5b9a739bfbb` |
| `sata_mt85xx_mod.ko` | `8a0253eb9bff19a3d3c0ac594a507235bad82348d8e80069024368d0f5456657` |
| `bdpdrv.ko` | `c146e0d6c8900d526c88017dc6ae561d407a366ff2959d66e68611c6b8a81c45` |

```
# 1. kernel image -> raw text (no hard-coded offsets; both layers self-checked)
python3 evidence/bx510-guest/bdpdrv/decode/kernel_decode_image.py \
        evidence/bx510-guest/u4-initrd/pulled/kernel.uImage /tmp/kdec
# 2. kallsyms + one-time ELF wrap
python3 evidence/bx510-guest/bdpdrv/decode/kernel_decode_dis.py --prep
# 3. the four kernel functions in this chain (pool values resolved, IO-VA annotated)
python3 evidence/bx510-guest/bdpdrv/decode/kernel_decode_dis.py --sym mt85xx_ioctl
python3 evidence/bx510-guest/bdpdrv/decode/kernel_decode_dis.py --sym scsi_execute
python3 evidence/bx510-guest/bdpdrv/decode/kernel_decode_dis.py --sym __blkdev_driver_ioctl
# 4. the Sony command-size table (8 bytes at VA 0xc036ee20 == file 0x366e20)
python3 -c "d=open('/tmp/kdec/vmlinux.bin','rb').read();print(list(d[0x366e20:0x366e28]))"
#    -> [12, 12, 12, 12, 16, 12, 12, 12]      (stock is [6,10,10,12,16,12,10,10])
# 5. the export really is this function
python3 -c "import struct;d=open('/tmp/kdec/vmlinux.bin','rb').read();\
print(hex(struct.unpack_from('<I',d,0x23910c)[0]), hex(struct.unpack_from('<I',d,0x239110)[0]))"
#    -> 0xc01debb8 0xc0432b20   (value, "mt85xx_ioctl" kstrtab)
# 6. modules (VM -> Mac, private channel)
make vm-pull-file FILE=/tmp/rootfs/lib/modules/2.6.35/BDP/sr_mod.ko      DEST=/tmp/kmod
make vm-pull-file FILE=/tmp/rootfs/lib/modules/2.6.35/BDP/libata.ko      DEST=/tmp/kmod
make vm-pull-file FILE=/tmp/rootfs/lib/modules/2.6.35/BDP/cdrom.ko       DEST=/tmp/kmod
/opt/homebrew/opt/llvm/bin/llvm-objdump -d -r --triple=armv7a-none-eabi \
        --start-address=0x6a0  --stop-address=0x840  /tmp/kmod/sr_mod.ko   # sr_block_ioctl
/opt/homebrew/opt/llvm/bin/llvm-objdump -d -r --triple=armv7a-none-eabi \
        --start-address=0x3d4  --stop-address=0x484  /tmp/kmod/sr_mod.ko   # sr_packet
/opt/homebrew/opt/llvm/bin/llvm-objdump -d -r --triple=armv7a-none-eabi \
        --start-address=0x2248 --stop-address=0x2520 /tmp/kmod/sr_mod.ko   # sr_do_ioctl
/opt/homebrew/opt/llvm/bin/llvm-objdump -d -r --triple=armv7a-none-eabi \
        --start-address=0x8cec --stop-address=0x8e00 /tmp/kmod/libata.ko   # atapi_xlat
# 7. the producer side
/opt/homebrew/opt/llvm/bin/llvm-objdump -d -r --triple=armv7a-none-eabi \
        --start-address=0xa92dc --stop-address=0xa94a0 /tmp/bdpdrv/bdpdrv.ko  # SendOddCmd
/opt/homebrew/opt/llvm/bin/llvm-objdump -d -r --triple=armv7a-none-eabi \
        --start-address=0xaa3d8 --stop-address=0xaa46c /tmp/bdpdrv/bdpdrv.ko  # OddRead CDB
```

Function offsets used above (all section-relative): `sr_mod.ko` `.text` = `sr_block_ioctl`
`0x6a0`, `sr_packet` `0x3d4`, `sr_do_ioctl` `0x2248`, `sr_probe` `0x1a6c`, `sr_dops`
`.data+0x4c`; `libata.ko` `.text` = `ata_scsi_translate` `0x8b78`, `atapi_xlat` `0x8cec`,
`ata_scsi_queuecmd` `0xc0c0`, `ata_to_sense_error` `0x8864`, `ata_gen_passthru_sense`
`0x8a10`; `sata_mt85xx_mod.ko` `.text` = `sata_mt85xx_qc_issue` `0x3628`,
`sata_mt85xx_data_xfer` `0x5434`; kernel VAs as cited inline.
