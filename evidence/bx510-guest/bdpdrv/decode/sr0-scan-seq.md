# sr0 attachment: the post-enumeration SCSI sequence, the C101 stall, and the predicted C102 UART

**Question.** Between `scsi 0:0:0:0: CD-ROM MTK 85xx - FA Mode 1.00 PQ: 0 ANSI: 5`
and the missing `sr0:` / `Uniform CD-ROM driver` lines, what does the kernel
issue, what stalled in C101, what does `sr_probe` require to attach, and what
will C102's UART look like line-by-line?

**Answers up front.**

1. **Nothing stalled in C101, and there is no post-enumeration CDB to stall on:
   `cdrom.ko` and `sr_mod.ko` were never loaded.** C101's PRE_ phase insmods
   only `/res/shim/libata.ko` + `/res/shim/sata_mt85xx_mod.ko`
   (`bdpdrv-runC101.uart.log:224,226`). With no driver registered for a type-5
   LUN, `scsi_scan_target()` finishes and returns — no TEST UNIT READY, no MODE
   SENSE, no READ CAPACITY, no GET CONFIGURATION. The whole run contains
   **8 mailbox posts and they all precede the `CD-ROM … ANSI: 5` line**
   (§2.2); after it, zero.
2. The one CDB the scan *does* issue — INQUIRY — rides the mailbox as code
   `0xa0` with **all four argument words zero** (trace line 552656), i.e. the
   CDB itself never reaches the FE in this build. The 36 INQUIRY bytes that
   produced `MTK 85xx - FA Mode 1.00` are handed to libata by the *host driver*
   out of its own FA-table image, not by the FE (§4.2). So the earlier
   reading of the C101 mailbox ("`0xa0` + `0xef` posts are the scan's CDBs in
   flight") is half right: `0xa0` is the INQUIRY post, `0xef` is libata's
   SET FEATURES (`UDMA/33`) *taskfile*, and neither carries a CDB.
3. `sr_probe` attaches on **type alone** (`TYPE_ROM`/`TYPE_WORM`) plus
   `register_cdrom()` succeeding. TUR / MODE SENSE / READ CAPACITY /
   GET CONFIGURATION success is **not** an attachment condition — a failed
   capability probe only downgrades the label to `sr0: scsi-1 drive`.
4. The predicted C102 UART is §4: three-to-five new lines, and the
   `Attached scsi CD-ROM sr0` line is `KERN_DEBUG` and therefore **invisible on
   this console** (default `console_loglevel` = 7) unless the harness raises
   `/proc/sys/kernel/printk` to 8 first.

Certainty labels: **DECODED** = fixed by an instruction/relocation, a source
line in the exact tree that built the module, or a trace event. **INFERRED** =
consistent with all evidence, not closed by one. **OPEN** = not settled here,
with the settling experiment named.

---

## 0. Inputs and method

| input | what it decided |
|---|---|
| repo `evidence/bx510-guest/bdpdrv/bdpdrv-runC101.uart.log` (2028 lines), `…meta.json` | console truth for C101 (what was/was not printed, module load lines, cmdline) |
| VM `/tmp/bdpdrv-runC101.mmio.log` (3 500 041 lines) | every MMIO access. The UART THR byte writes (`W 00c000`, `sz1` early / `sz4` after the kernel takes over) rebuild the console stream, so **console line ⟷ trace line is exact** — all "trace line" numbers below come from that join (`/tmp/c101_interleave_stage.py`, `/tmp/allposts_stage.py`) |
| VM `~/sony-kernel/linux-2.6.35` (the tree in the module `vermagic`/build paths: `…/msb8g_BX_R_0257/mtk/BDP_Linux_8560/linux-2.6.35`) — `drivers/scsi/sr.c`, `sr_ioctl.c`, `sr_vendor.c`, `sr.h`, `drivers/cdrom/cdrom.c`, `drivers/scsi/scsi_scan.c`, `drivers/ata/libata-scsi.c`, `libata-core.c`, `fs/partitions/check.c`, `kernel/printk.c`, `include/linux/cdrom.h` | the authoritative sequence + print strings; pulled to Mac `/tmp/ksrc` |
| VM `/tmp/rootfs/lib/modules/2.6.35/BDP/{sr_mod.ko,cdrom.ko,libata.ko}` (pulled: `/tmp/scsimod/sr_mod.ko`, `libata.ko`) | proves the *shipped* module carries the Sony patches (ioctl numbers, host-name `strcmp`, log strings) — disassembled with the same reloc/pool join the other decode docs use |
| VM `/tmp/bdpdrv/sata_mt85xx_mod.ko` (+ `/tmp/bdpdrv/sata.dis`) | where the `MTK 85xx- FA Mode` identity and the FA-mode INQUIRY branch live |
| VM `/tmp/sony-bx510.c` (QEMU FE model, mtime 05:04 < run 05:05) | what the FE model does with each posted code — i.e. what C101's FE actually answered |
| VM `/tmp/rootfs/usr/usbmod.sh` | the factory's own module load order (the C102 recipe) |

The Sony `sr.c` in this tree is **not** mainline: grep shows `SR_LOG`/`SR_LOG_FN`
instrumentation, `strcmp(sht->name, "sata_mt85xx")` in `sr_probe`, and the
`MT85XX_IDE_GET_FA_MODE` / `…_GET_BE_QUIET` ioctls in the CDB paths. Every claim
below was checked against the *module bytes*, not only the source (the module's
`.text+0x1d4c`/`0x1d64` literal pools are `0x8531`/`0x8533`, its
`.text+0x1a90` call is `strcmp(hostt->name, "sata_mt85xx")`, its
`.text+0x21f0` pool is `35000` = `SR_TIMEOUT` with `HZ`=1000), so source and
binary agree.

---

## 1. The scan → attach CDB sequence, decoded from the stack that runs

### 1.1 What `scsi_scan_target` itself issues (only INQUIRY)

`scsi_probe_lun()` (`scsi_scan.c:553-700`) issues **INQUIRY (0x12)**, CDB[4] =
length, first pass 36 bytes, `DMA_FROM_DEVICE`, timeout `HZ/2 + HZ*scsi_inq_timeout`
(5 s here), 3 attempts to swallow UNIT ATTENTION. `scsi_add_lun()` then prints the
line in question (`scsi_scan.c:851`):

```c
sdev_printk(KERN_NOTICE, sdev, "%s %.8s %.16s %.4s PQ: %d ANSI: %d%s\n", …)
```

`KERN_NOTICE` ⇒ always on the console (this is why C101 shows it).

Because the target is ATAPI, libata **relays** the INQUIRY instead of emulating
it (`libata-scsi.c:3153-3164`: `dev->class != ATA_DEV_ATA` ⇒
`xlat_func = atapi_xlat`), and `atapi_xlat()` (`libata-scsi.c:2681`) builds
`qc->cdb` as a **12-byte zero-padded** copy of the CDB and sets
`tf.command = ATA_CMD_PACKET (0xa0)`, `tf.lbam/lbah = nbytes`, protocol
`ATAPI_PROT_DMA` (or `_NODATA`). So *every* ATAPI CDB reaches the FE as one
`0xa0` post; the ATA emulation path (`ata_scsiop_inq_std`, which would have said
`ATA     ` / the IDENTIFY model) is not reachable for this device.

### 1.2 What the sr driver adds (the sequence the question asks for)

`sr_probe()` (`sr.c:761`) in order — each step's CDB, or the fact that it has none:

| # | step | CDB | data | length | timeout / retries | source |
|---|---|---|---|---|---|---|
| 1 | `sr_probe` entry | — | — | — | — | `sr.c:761-810` |
| 2 | media capability probe: `sr_test_unit_ready(cd->device, &sshdr)` | **TEST UNIT READY 0x00**, 6-byte CDB `00 00 00 00 00 00` | `DMA_NONE` | 0 | `SR_TIMEOUT` = 35 s, `MAX_RETRIES` = 3, loops while UNIT ATTENTION | `sr.c:206-258`, `sr.h:23-24` |
| 3 | `get_capabilities()` → two *vendor ioctls*, no CDB: `scsi_ioctl(sdev, MT85XX_IDE_GET_FA_MODE=0x8531, &isFaMode)`, `scsi_ioctl(sdev, MT85XX_IDE_GET_BE_QUIET=0x8533, &isBeQuiet)` | — | — | 4 B each, `__copy_to_user` | — | `sr.c:1010-1014`, `cdrom.h:150,152`; handler `_sata_mt85xx_sht_ioctl` `.text+0x78f4` → `sata_mt85xx_get_FA_mode` `.text+0x7680` |
| 4 | if `isFaMode \|\| isBeQuiet`: **skip** both CDBs below, `rc = 0x8000002` (fabricated `CHECK CONDITION`) | — | — | — | — | `sr.c:1017-1023`, `sr.c:226-231` |
| 4′ | else MODE SENSE(10) page 0x2a | **0x5A**, `5a 00 2a 00 00 00 00 00 00 80` (alloc=`0x0080`) | `DMA_FROM_DEVICE` | 128 | 35 s, 3 | `sr.c:1025`, `scsi_mode_sense` |
| 5 | capability print | — | — | — | — | §4.1 |
| 6 | `sr_vendor_init(cd)` | **none for this device**: `readcd_known == 0` and vendor `MTK` matches no `NEC/TOSHIBA/PLEXTOR/MATSHITA/TEAC/HP` prefix ⇒ `VENDOR_SCSI3` | — | — | — | `sr_vendor.c:66-110` |
| 7 | `register_cdrom(&cd->cdi)` | — | — | — | — | `cdrom.c:393` |
| 8 | `add_disk(disk)` | **no CDB, ever**: `alloc_disk(1)` ⇒ `minors == 1` ⇒ `!disk_partitionable()` ⇒ `register_disk()` returns before `bdget_disk()`/`blkdev_get()` (`fs/partitions/check.c:515-527`). Nothing opens sr0 at probe time. | — | — | — | `check.c:490-541`, `sr.c:867` |
| 9 | `sdev_printk(KERN_DEBUG, sdev, "Attached scsi CD-ROM %s\n", cd->cdi.name)` | — | — | — | — | `sr.c:869-870` |

Steps 2–4 are what the question calls "sr_attach TEST UNIT READY"; note the
Sony patch can skip them entirely (step 4) — that is the single biggest fork in
the C102 prediction.

**After attach, on the first `open()` of `/dev/sr0`** (not at probe):

| step | CDB | length | source |
|---|---|---|---|
| `cdrom_open` → `check_disk_change` | — | — | `cdrom.c:1020` |
| `sr_media_change` → `sr_test_unit_ready` | 0x00 (or skipped by step 4) | 0 | `sr.c:264-330` |
| `device->changed == 1` (set by `sr_probe`, `sr.c:837`) ⇒ `sr_cd_check` | **READ TOC 0x43**, `43 00 00 00 00 00 00 00 0c 40` (`cmd[8]=12` alloc, `cmd[9]=0x40`) | 12 | `sr_vendor.c:157-190` |
| ⇒ `get_sectorsize` | **READ CAPACITY(10) 0x25**, 10-byte CDB, 8-byte reply | 8 | `sr.c:890-975` |
| `cdrom_open` with `CDO_LOCK` | ALLOW_MEDIUM_REMOVAL 0x1e (`sr_lock_door`) | 0 | `cdrom.c:1026`, `sr_ioctl.c` |
| tray/status ioctls if userspace asks | START STOP UNIT 0x1b, READ SUBCHANNEL 0x42, SET CD SPEED 0xbb, READ CD 0xbe, READ(10) 0x28 | — | `sr_ioctl.c:337,508,546,612,679` |

`GET CONFIGURATION (0x46)` appears **nowhere in the sr attach path** — in this
tree it is a *userspace CLI* probe (`_IDECLI_OddCheckFaMode` →
`[_SACDCLI_TestPhy]` "Disc profile", `drvcli-surface.md:463`,
`sacdread-cpsa.md:263`), not something `sr_mod` issues. A CDB trace of the attach
must not be read as missing a `0x46`.

---

## 2. Where the C101 tail came from (observations, not conjecture)

### 2.1 Module state — the whole explanation

`bdpdrv-runC101.uart.log`:

```
224  / # insmod /res/shim/libata.ko;            echo PRE_libata.ko_RC=$?
226  / # insmod /res/shim/sata_mt85xx_mod.ko;   echo PRE_sata_mt85xx_mod.ko_RC=$?
...
329  / # insmod /lib/modules/2.6.35/BDP/bdpdrv.ko; echo BDPDRV_INSMOD=$?
1830 / # insmod /res/shim/bx510_clidrive.ko clidrive_args=PROBE_SEQ
```

`cdrom.ko` and `sr_mod.ko` appear **nowhere** in the run, and `scsi_mod` is
built in (no `scsi_mod.ko` in `/tmp/rootfs/lib/modules/2.6.35/BDP/`; the scan
runs). `sr_probe` is therefore never called: there is no driver whose
`probe` matches the type-5 LUN, so `scsi_scan_target` → `scsi_add_lun` →
`scsi_sysfs_add_sdev` → `device_add` finds no match, and the scan ends. The
harness's own warning banner confirms the module set at that moment
(`uart.log:326`: `Modules linked in: … sata_mt85xx_mod libata`). Independent
corroboration, from the same run's `/proc/devices` inventory (quoted in
`decode/scsi-scan-codes.md` §0.5): **no block major 11 is registered**, i.e.
no `sr` driver ever bound.

### 2.2 The complete mailbox post census of C101 (all 8, DECODED)

`W 05c000` count over the whole 3.5 M-line trace: 8. Reconstructed
(`/tmp/allposts_stage.py`), with console anchors from the UART↔trace join:

| trace line | w0 | w1 | w2 | w3 | reading | console context (after the post) |
|---|---|---|---|---|---|---|
| 545772 | `0xa1000000` | 0 | 0 | 0 | `chk_int_ldr` table-data request (`arg==0`) | `[IDE]<sata_mt85xx_id_atapi_dev>copy from (0xdfc01000, 0x200) to (0xc6268c60, 0x200)` |
| 546140 | `0x00100000` | 0 | 0 | 0 | type-0x10 table-data **ACK** | `[IDE]Internal loader boot code mode` / `----- Loader is in manufacture mode !! -----` / `scsi0 : sata_mt85xx` / `ata1: SATA max UDMA/133 irq 18` |
| 550879 | `0xa1000000` | 0 | `0x0000a000` | 0 | **IDENTIFY PACKET DEVICE** taskfile (device/head `0xa0`) | `ata1.00: ATAPI: SONY    BDPSACDEMUL, 1.00, max UDMA/33` + `applying bridge limits` + the two `Drive reports diagnostics failure…` WARNING lines |
| 550957 | `0x00100000` | 0 | 0 | 0 | table-data ACK | — |
| 552295 | `0xef000000` | `0x00004203` | `0x0000a000` | 0 | **SET FEATURES** (`feature=0x03` SETFEATURES_XFER, `count=0x42` = UDMA mode 2 = UDMA/33) | `ata1.00: configured for UDMA/33` |
| 552359 | `0xa1000000` | 0 | `0x0000a000` | 0 | second **IDENTIFY PACKET DEVICE** (libata re-read after the xfer-mode set) | — |
| 552399 | `0x00100000` | 0 | 0 | 0 | table-data ACK | — |
| **552656** | **`0xa0000000`** | **0** | **0** | **0** | **ATAPI PACKET = the scan's INQUIRY — and its CDB words are ZERO** | `scsi 0:0:0:0: CD-ROM            MTK 85xx - FA Mode 1.00        PQ: 0 ANSI: 5` (console byte 13616, trace line 553567/553839) |

The post at 552656 is followed by exactly the standard two status-block reads
(`R 05c040/044/048/04c` at 552698 and 553315) and two `W 05c40c = 0` — i.e.
**one** type-0 completion message, no type-0x10 payload offer, and no
`0x5c400/0x5c404` descriptor writes anywhere in the run (the "`0x5c400`
descriptor writes" in the C101 brief are the `0x5c40c` arm-flag writes only).

Consequences, all DECODED:

* No `sr`-side CDB was ever issued in C101. The `sr0:`/`Uniform CD-ROM` absence
  is a **module-absence signature, not an FE stall**: no error print, no
  timeout, no EH loop, no retry burst — the console simply moves on to the
  next shell prompt (the C101 UART has no further SCSI line at all; lines
  296+ are the harness's own `osal_stub`/`drvcli`/`bdpdrv` insmods).
* The `0xef` post is not a CDB — it is a taskfile (`features=0x03`,
  `count=0x42`). The only CDB-shaped post is the `0xa0` one, and its 12 CDB
  bytes are all zero.

### 2.3 Why the CDB words are zero (DECODED, and a standing model gap)

The `0xa0` post is `sata_mt85xx_data_xfer`'s mailbox branch
(`fe-ata-cmd.md` §1.1, `.text+0x570c..0x57e8`), whose argument words are a
12-byte `memcpy` from the pointer stored at `priv+0x24`:

```
0x576c  ldrb r9,[r4,#0x29c]      ; FE command code = 0xa0 (PACKET)
0x577c  ldr  r1,[r4,#0x24]       ; r1 = *(priv+0x24)  -> a POINTER to the CDB copy
0x5780  bl   memcpy(sp+0x4c, r1, 12)
```

`r4 = priv` is itself loaded (`base = *(u32*)(ap+0x1dfc); priv = *(u32*)(base+0xc)`
— see `sata_mt85xx_qc_prep` `.text+0x2ed4..0x2ee8`, which is the same expression).
The only writer of that CDB buffer anywhere in this module is the *FA-mode
INQUIRY* branch (`0x5880`, §3.3) — so on the normal path the FE receives
`w1 = w2 = w3 = 0` and **cannot key on the CDB**. C101 measures exactly that.
Any model row that "keys the reply on the CDB opcode" is therefore not yet
reachable from the mailbox; that is a property of this driver build, not of the
model (see §6, open item O-2).

One pre-scan detail worth pinning for C102 reproduction: the
`ata1.00: applying bridge limits` line comes from `ata_dev_knobble()`
(`libata-core.c:2578-2581`, `KERN_INFO`), and the two
`Drive reports diagnostics failure…` lines from `ATA_HORKAGE_DIAGNOSTIC`
(`libata-core.c:2604-2617`, `KERN_WARNING`) after `ap->ops->dev_config` runs.
No entry of `ata_device_blacklist` in this tree sets either flag (grep:
`BRIDGE_OK` only on the MTRON entry, `DIAGNOSTIC` nowhere), so both are
**INFERRED** to be set by the controller driver's `dev_config` hook — they are
rig-side facts that will repeat verbatim in C102 and are not evidence about the
ATAPI device.

---

## 3. `sr0` attachment conditions (what `sr_probe` really requires)

### 3.1 Hard gates inside `sr_probe` (`sr.c:761-885`, cross-checked in `sr_mod.ko` `.text+0x1a6c..0x2248`)

1. `sdev->type == TYPE_ROM(5) || sdev->type == TYPE_WORM(4)` — else `-ENODEV`.
   In C101 the INQUIRY byte0 delivers type 5 (`CD-ROM` in the printed line), so
   **this gate already passes**.
2. `kzalloc(sizeof(struct scsi_cd))`, `alloc_disk(1)` succeed (memory only).
3. A free minor in `sr_index_bits` (`SR_DISKS`); the Sony `#else /* Sure SATA
   assign sr0 */` branch keeps `sr0` reserved for host-name
   `sata_mt85xx` — decoded as the `strcmp` at `.text+0x1a90` and the
   `_find_first_zero_bit_le` dance at `.text+0x1b30..0x1bd0`.
4. `register_cdrom(&cd->cdi)`: returns `0` because `sr_dops.open`/`.release`
   are non-NULL (`cdrom.c:396-397`), and prints the one-shot banner.
5. `add_disk(disk)` → then the KERN_DEBUG attach print.

**Not** gates: TEST UNIT READY result, MODE SENSE result, READ CAPACITY,
GET CONFIGURATION, or the `FA Mode` identity. A failing capability probe takes
the explicit soft path (`sr.c:1029-1039`): mask off every capability, print
`"%s: scsi-1 drive\n"`, `return`. `sr_test_unit_ready` likewise only *reports*;
its return value is consumed only by `sr_media_change` (open-time).

### 3.2 What the two vendor ioctls return, and why it matters

The ioctls `0x8531`/`0x8533` are dispatched by the controller's
`scsi_host_template.ioctl` (`_sata_mt85xx_sht_ioctl`, `.text+0x78f4`; the
constant pools at `.text+0x7aac`/`0x7ab0`/`0x7ab4` hold
`0x8531`/`0x8532`/`0x8533`) to
`sata_mt85xx_get_FA_mode` (`.text+0x7680`) / `sata_mt85xx_get_BE_quiet`
(`.text+0x775c`), each of which `__copy_to_user`s 4 bytes from a driver-private
field (`priv+0x208` / the adjacent word). **The value is a runtime flag with no
static initialiser in the module and no store to `priv+0x208` in
`.text` (grep of `sata.dis`: only one `ldr r3,[r4,#0x208]`, at `data_xfer`
`.text+0x55dc`)** — it is set by `MT85XX_IDE_SET_FA_MODE (0x8532)`, i.e. by
whoever sends that ioctl, or it is zero from `kzalloc`.

*OPEN (O-1):* FA=0 vs FA=1 is the fork between two different C102 UARTs; both
are given in §4.1. The line `sr0: scsi-1 drive` **is** the discriminator, so a
single C102 run closes it.

Cross-lane note: the companion decode `decode/scsi-scan-codes.md` (§0.6, §4.2)
concludes FA mode **is** set, from the fact that the `MTK 85xx - FA Mode`
identity is driver-synthesised (which this document agrees with, §3.3), and hence
predicts branch A. This document keeps O-1 open rather than deciding it, for one
specific reason: the canned block the FA short-circuit copies begins
`.data+0x70 = 58 00 03 11 f0 00 00 00`, which would make the INQUIRY reply
`type = 0x18` — not the `CD-ROM`/`ANSI: 5` the console shows — unless the copy
destination is `buf+8` or the pool resolves to a different base than read here.
Both documents agree on the *modelling* consequence: a `0xa0` post carries no CDB
opcode, so the FE must key on the ATAPI byte count plus packet position, not on
an opcode.

### 3.3 Where `MTK 85xx - FA Mode 1.00` comes from (DECODED)

Not from libata and not from the FE model:

* `libata.ko` contains no `MTK`/`FA Mode`/`85xx` string at all (`strings` of the
  shipped module; its INQUIRY emulation `ata_scsiop_inq_std` would answer
  `ATA     ` + the IDENTIFY model — and for ATAPI it is never called, §1.1).
* `sr_mod.ko` has the *host-name* `sata_mt85xx` string (the sr0-reservation
  `strcmp`) but no `FA Mode` text.
* `sata_mt85xx_mod.ko` has exactly one: the 18-byte `"MTK 85xx- FA Mode "`
  at **`.data+0x78`**, reached by the literal pool slot in `data_xfer`
  (`.text+0x5b08`) which resolves to **`.data+0x70`** — so the string sits at
  block offset 8 of that pool target, exactly the INQUIRY `vendor`/`model`
  window. The same `.data` block is the driver's FA/PARM table template
  (`PWRC`@0x10, `FATB`@0x24, `PARM`@0x38).
* The scan's text matches that byte layout under the format string:
  `%.8s` = `"MTK 85xx"` (bytes 8-15 of the reply), `%.16s` = `"- FA Mode"`,
  `%.4s` = `"1.00"` ⇒ printed `MTK 85xx - FA Mode 1.00`. The separator space
  between `85xx` and `-` is the format string's, not the device's.
* The ATA-side identity is a *different* string: `ata1.00: ATAPI: SONY
  BDPSACDEMUL, 1.00` comes from the IDENTIFY payload the FE model builds
  (`sony-bx510.c:854`, `src = "SONY    BDPSACDEMUL  "`), i.e. from
  `dev->id`/words 16-26+27-46 — which is exactly why the two lines disagree.

So the identity the SCSI stack sees is the **driver's FA-table image**, and the
driver hands it to libata itself: at boot it copies 512 bytes out of the FE DRAM
window into its own buffer — the
`[IDE]<sata_mt85xx_id_atapi_dev>copy from (0xdfc01000, 0x200) to (0xc6268c60, 0x200)`
line at `uart.log:283` — and `data_xfer` is what fills the SCSI data buffer for
the INQUIRY. Two code paths can do that in `data_xfer`:

* the FA-mode INQUIRY synthesis at `.text+0x5880..0x58d4` (guarded by
  `*(priv+0x208) != 0 && cdb[0] == 0x12`, `.text+0x55dc..0x55f0`): it saves the
  CDB, runs `ata_id_c_string(id, …, ATA_ID_FW_REV=23, 9)` (so the revision is
  taken from the IDENTIFY — `1.00`), `memcpy(dst, .data+0x70, *(priv+0x54))`,
  sets `priv+0x22c |= 0x10000` and wakes the waiter, **posting nothing**;
* the ordinary mode-1 data body (`fe-ata-cmd.md` §1.4) which copies
  `*(priv+0x54)` bytes from the driver's shadow buffer — the same 512-byte FA
  image copied at boot.

Either way the bytes come from the driver, never from the FE model: the model's
dispatch (`sony-bx510.c: bx510_fe_dispatch`, lines 316-370) has **no `0xa0`
branch** — `0xa0` falls through to "a type-0 success completion" and posts no
payload. That is consistent with both readings.

*OPEN (O-3):* which of the two `data_xfer` paths ran is not closed, because the
FA-synthesis template's own first four bytes (`.data+0x70` = `58 00 03 11`) do
not decode as an INQUIRY header (`type` would be 0x18, not 5), so the *literal*
`.data+0x70` block cannot be the buffer that produced the printed line without
the destination being `buf+8`. Settling experiment: C102 with
`MT85XX_IDE_SET_FA_MODE` toggled between runs — if the `CD-ROM …` line's
vendor/model changes with the flag, path 1 ran; if it is identical in both runs,
the shadow-buffer path supplies the bytes and `.data+0x70` is only the FA table.

The one thing that *is* closed and matters for C102: **the FE never needs to
answer INQUIRY for enumeration to succeed on this rig** — the driver's own
512-byte image does it. Do not design model rows assuming the FE's INQUIRY reply
reaches the scan.

---

## 4. Predicted C102 UART

Recipe (factory order, `usbmod.sh`): `insmod cdrom.ko` → `insmod libata.ko` →
`insmod sata_mt85xx_mod.ko` → `insmod sr_mod.ko`; the factory loads sr_mod
*after* the controller, so `sr_probe` runs at the sr_mod insmod
(`driver_register` → `device_attach` on the already-enumerated LUN). If instead
sr_mod is loaded *before* `sata_mt85xx_mod.ko`, the same lines appear inline,
immediately after the `ANSI: 5` line, at scan time. Both are valid; only the
position in the log changes.

### 4.1 The `sr0:` capability line (printed by `get_capabilities`)

**Branch A — `isFaMode || isBeQuiet` true (both CDBs skipped, `rc = 0x8000002`
fails `scsi_status_is_good`):**

```
sr0: scsi-1 drive
```

(`printk("%s: scsi-1 drive\n", …)` — plain `printk`, default level 4 ⇒ always on
the console. The driver has just masked off `CDC_CD_R|CDC_CD_RW|CDC_DVD_R|CDC_DVD|
CDC_DVD_RAM|CDC_SELECT_DISC|CDC_SELECT_SPEED|CDC_MRW|CDC_MRW_W|CDC_RAM` and set
`cdi.speed = 1`.)

**Branch B — FA/BE-quiet both 0 (real CDBs, "correctly answering FE"):**

```
sr0: scsi3-mmc drive: <N>x/<N>x <writer?> <dvd-ram?> <cd/rw?> <xa/form2?> <cdda?> <mech>
```

from `printk("%s: scsi3-mmc drive: %dx/%dx %s%s%s%s%s%s\n", …)`: `N` is
`((buf[n+8]<<8)+buf[n+9])/176` and `buf[n+14..15]/176` for the two speeds,
flags are single bits of the MODE SENSE(10) page-0x2a reply at `n =
header_length + block_descriptor_length`, and the mechanism word comes from
`buf[n+6] >> 5` (`caddy|tray|pop-up|""|changer|cartridge changer`).
A correct FE with an empty tray may equally answer MODE SENSE with
`CHECK CONDITION` — then branch B prints **`sr0: scsi-1 drive`** as well, and
the UART cannot distinguish "FE said no" from "vendor patch skipped". That
ambiguity is why O-1 needs the ioctl, not the console, as its discriminator if
branch B is to be certified.

One further outcome must be named, because it is what the *current* FE model
produces: a bare type-0 completion makes MODE SENSE look **successful**
(`rc = 0` ⇒ `scsi_status_is_good` true), so `get_capabilities` parses whatever
the data phase delivered (the FA image) and prints the `scsi3-mmc drive:` form
with meaningless numbers — and `n` derived from those bytes. On C102 a
`scsi3-mmc drive:` line is therefore **not** evidence of a working FE; only a
self-consistent capability set is. Branch A is the one outcome a bare
completion cannot fake.

### 4.2 The attachment banner (once per boot, in `register_cdrom`)

```
Uniform CD-ROM driver Revision: 3.20
```

`printk(KERN_INFO, …)` at `cdrom.c:404` with `REVISION "Revision: 3.20"`
(`cdrom.c:245`), guarded by `static char banner_printed`. `KERN_INFO` = 6 < 7 ⇒
**always printed**. It appears at the *first CD-ROM registration in the boot*, so
with the factory load order it lands between the `sr0:` line and the attach line.

### 4.3 The attach line — and why it will look "missing" again

```
sr 0:0:0:0: Attached scsi CD-ROM sr0
```

is `sdev_printk(KERN_DEBUG, …)` (`sr.c:869`). `kernel/printk.c:66` sets
`DEFAULT_CONSOLE_LOGLEVEL 7`, C101's cmdline has no `loglevel=` override
(`uart.log:12`), and `printk.c:469` prints to the console only when
`msg_log_level < console_loglevel` ⇒ **level 7 is suppressed on this UART.**
So a correctly attached sr0 will still show *no* `Attached scsi CD-ROM` line
unless the harness runs `echo 8 > /proc/sys/kernel/printk` before the insmods.
C102 should do that, otherwise "sr0 attached" will again be reported as missing.
(`dmesg` would show it; the UART will not.)

### 4.4 The complete predicted block

Factory load order (`cdrom → libata → sata_mt85xx → sr_mod`), branch A:

```
[IDE]<sata_mt85xx_id_atapi_dev>copy from (0xdfc01000, 0x200) to (…, 0x200)
[IDE]Internal loader boot code mode
[IDE]----- Loader is in manufacture mode !! -----
scsi0 : sata_mt85xx
ata1: SATA max UDMA/133 irq 18
[IDE]<sata_mt85xx_prereset>ch:0, deadline:… start
[IDE]<sata_mt85xx_prereset>ch:0 end
[IDE]<sata_mt85xx_softreset>ch:0 start
[IDE]<sata_mt85xx_softreset>ch:0 end, class=3
ata1.00: ATAPI: SONY    BDPSACDEMUL, 1.00, max UDMA/33
ata1.00: applying bridge limits
ata1.00: Drive reports diagnostics failure. This may indicate a drive
ata1.00: fault or invalid emulation. Contact drive vendor for information.
ata1.00: configured for UDMA/33
scsi 0:0:0:0: CD-ROM            MTK 85xx - FA Mode 1.00        PQ: 0 ANSI: 5
PRE_sata_mt85xx_mod.ko_RC=0
/ # insmod …/cdrom.ko; echo CDROM_INSMOD=$?
CDROM_INSMOD=0
/ # insmod …/sr_mod.ko; echo SR_INSMOD=$?
sr0: scsi-1 drive                                 ← NEW (branch A)
Uniform CD-ROM driver Revision: 3.20              ← NEW (register_cdrom, one-shot)
sr 0:0:0:0: Attached scsi CD-ROM sr0              ← NEW, only if console_loglevel ≥ 8
SR_INSMOD=0
```

Branch B replaces the first new line with the `scsi3-mmc` form (or leaves
`scsi-1 drive` if the FE CHECK-CONDITIONs the MODE SENSE). Nothing else in the
block changes: the pre-scan lines are reproduced verbatim from C101's post
census (§2.2) because they are produced by the same model replies.

If the harness then opens the node (`mknod /dev/sr0 b 11 0` first — there is no
udev/mdev in this rootfs, and `daemon_gate.sh` gate 06 already states exactly
that), the *next* lines are: `sr_media_change` → TUR (or FA-skip) → READ TOC
(0x43) → READ CAPACITY (0x25), with `cd->capacity`/`sector_size` decided there —
i.e. the disc-size question is *not* answered by anything in the attach block.

---

## 5. New model rows implied (beyond the `0xa0`/`0xef` reply work)

These are the FE-side behaviours the sr sequence needs *if* the rig is to
demonstrate a real attach-and-read rather than a driver-local fake. Ordered by
what breaks first.

| # | CDB (code, full CDB) | expected payload / status | why it is needed | current model state |
|---|---|---|---|---|
| R1 | INQUIRY `0x12`, `12 00 00 00 24 00` | 36 B, `[0]=0x05` (type ROM, PQ 0), `[1]&0x80` removable, `[2]&7=5` (ANSI 5), `[8..15]` vendor, `[16..31]` model, `[32..35]` rev, `[3]&0x0f=2` ⇒ "CCS" suppressed | a *real* FE identity, so the scan line stops being the driver's FA table | none needed today (driver fakes it); must exist before any "FE answered INQUIRY" claim |
| R2 | TEST UNIT READY `0x00`, no data | type-0 completion, status good (`priv+0x220` → `0x58` path) **or** CHECK CONDITION with sense `02/3a/00` (medium not present) | branch B's first CDB; also gates `sr_media_change` | not distinguished: any `0xa0` gets a bare completion |
| R3 | MODE SENSE(10) `0x5a 00 2a 00 00 00 00 00 00 80` | 128 B: mode parameter header (`header_length`=8, `block_descriptor_length`=0) + page `0x2a` (CD capabilities): `[n+2]`, `[n+3]`, `[n+4]`, `[n+5]`, `[n+6]>>5` mech, `[n+8..9]` max speed, `[n+14..15]` max speed → feeds the `scsi3-mmc drive:` line | branch B's capability label | **not answered, and a bare completion is worse than failing**: `rc = 0` looks successful, so the driver parses the FA-image bytes and prints a `scsi3-mmc drive: Nx/Nx …` line with meaningless numbers |
| R4 | READ CAPACITY(10) `0x25 …`, 8 B | `4× (last LBA)` big-endian + `4× 0x00000800` block size | `get_sectorsize` on first open: capacity + `blk_queue_logical_block_size` | not answered; garbage in the buffer would produce a nonsense capacity, not the `0x1fffff` fallback (the fallback only triggers on a *failed* command) |
| R5 | READ TOC `0x43 00 00 00 00 00 00 00 0c 40`, 12 B | 12 B TOC header with the TOC data length ≥ 0x0a for "multisession ok", `< 0x0a` to force `Hmm, seems the drive doesn't support multisession CD's` | `sr_cd_check` on first open (only when `CDC_MULTI_SESSION` is clear, which it is for `VENDOR_SCSI3`) | not answered |
| R6 | ALLOW MEDIUM REMOVAL `0x1e`, START STOP UNIT `0x1b`, READ SUBCHANNEL `0x42`, SET CD SPEED `0xbb` | no-data completion / small payloads | `cdrom_open` with `CDO_LOCK`, `sr_drive_status`, `sr_select_speed` | not answered |
| R7 | the **CDB itself** in `w1..w3` | — | without it the model cannot key R1–R6 to a CDB at all: C101 shows `w1=w2=w3=0` (§2.3) | gap is in the driver build's staging of `*(priv+0x24)`; the model can only key on it if C102 shows non-zero args |

Also note for the model's reply *shape*, from C101's measured signatures:

* a `0xa0` post must still produce the **two-block-read** pattern
  (`R 05c040/044/048/04c` twice, ~600 trace lines apart, with two
  `W 05c40c`) — C101 lines 552698 and 553315 — because that is the driver's
  fixed per-qc read pattern, not a per-message artifact;
* `0x5c400`/`0x5c404` are **never written** in the attach path (only `0x5c40c`
  is), so no model row should depend on a host-address descriptor for
  non-`0x28/0xA8/0xBE` CDBs.

---

## 6. Open items and the experiments that close them

| id | open question | settling experiment |
|---|---|---|
| **O-1** | `MT85XX_IDE_GET_FA_MODE` / `_GET_BE_QUIET` return 0 or 1 at sr_probe time (decides branch A vs B) | run C102 twice: once as-is, once after a userspace `ioctl(/dev/sr0 or the shim fd, 0x8532)` that sets FA mode; compare the `sr0:` line. Cheapest probe: a 20-line C program issuing `SCSI_IOCTL_*`/host ioctl 0x8531 and printing the value — no console ambiguity. |
| **O-2** | the FE never sees the CDB (`w1..w3 = 0` on the `0xa0` post) — is that the driver's `priv+0x24` staging gap or a model-side read of the wrong words? | C102 trace: dump `w1..w3` of the INQUIRY post. Non-zero ⇒ staging happens and C101's zeros were a first-command artifact; zero again ⇒ the FE protocol cannot be CDB-keyed from the mailbox and replies must key on *sequence position* (or the driver must be patched). |
| **O-3** | which `data_xfer` path filled the INQUIRY buffer (FA synthesis at `.text+0x5880` vs the shadow-buffer body), and whether the printed identity came from `.data+0x70` or the boot-time FA image | run O-1's FA-mode toggle and diff the `CD-ROM …` line; or add a `printk` to `data_xfer`'s two candidates on a scratch kernel build (blocked by "no emulator-kit edits" for this task). |
| **O-4** | whether C102's sr_mod will attach *inline* (sr before sata) or at insmod (sr after sata) | follow `usbmod.sh` order (after) for the primary run; the alternative run tells whether the two are observably identical. |

No CDB timeout / EH loop is predicted anywhere in the attach block: the Sony
patches remove the two commands most likely to hang (`sr_test_unit_ready`'s loop
is capped at 3 × 35 s, and in FA mode it is not issued at all), and every
remaining CDB is `SR_TIMEOUT`-bounded.

---

## Appendix — reproduction

```
# console<->trace join + annotated episode (VM)
python3 /tmp/c101_interleave_stage.py 544000 556000     # posts + console, trace-line order
python3 /tmp/allposts_stage.py                          # all 8 mailbox posts of the run
python3 /tmp/c101_window_stage.py 552400 553900         # raw 05cxxx stream + address census

# module decode (Mac, same reloc/pool join as the other decode docs)
python3 /tmp/sr_decode.py /tmp/scsimod/sr_mod.ko --strings
python3 /tmp/sr_decode.py /tmp/scsimod/sr_mod.ko --func sr_probe
python3 /tmp/sr_decode.py /tmp/bdpdrv/sata_mt85xx_mod.ko --func sata_mt85xx_data_xfer
python3 /tmp/sr_decode.py /tmp/bdpdrv/sata_mt85xx_mod.ko --func sata_mt85xx_get_FA_mode
python3 /tmp/sr_decode.py /tmp/bdpdrv/sata_mt85xx_mod.ko --func _sata_mt85xx_sht_ioctl

# source (Sony 2.6.35 tree, VM) — pulled to /tmp/ksrc by /tmp/tar_ksrc.sh
grep -n "MT85XX_IDE_GET_FA_MODE" -r drivers/scsi/sr.c include/linux/cdrom.h
sed -n '761,890p;975,1103p' drivers/scsi/sr.c      # sr_probe, get_capabilities
sed -n '157,200p' drivers/scsi/sr_vendor.c         # sr_cd_check (READ TOC)
```

Scripts are throwaway analysis aids kept out of the repo (they read a 100 MB VM
trace and the Sony tree); the numbers they produced are all committed above.
