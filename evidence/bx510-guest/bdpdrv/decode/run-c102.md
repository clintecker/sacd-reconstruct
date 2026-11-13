# Run C102 — sr0 ENUMERATES (`sr0: scsi-1 drive` + `Uniform CD-ROM driver Revision: 3.20`)

**Verdict: PASS on the primary objective.** The CD-ROM block device appears:
`sr0: scsi-1 drive`, `Uniform CD-ROM driver Revision: 3.20`, and
`/dev/sr0` is a real `brw-r--r-- … 11, 0` node. The recipe rows from
`decode/scsi-scan-codes.md` §4 were applied; the run also proves — by absence —
that **no SCSI CDB from `sr_mod` ever reaches the FE**, because Sony's patched
`sr.c` short-circuits both TUR and MODE SENSE on `isFaMode`.

Three deliverables were in scope and all three landed:

1. `decode/scsi-scan-codes.md` §4 recipe applied to `emulator-kit/sony-bx510.c`
   (`0xa0` = ATA PACKET rows, `0xef` = SET FEATURES row documented).
2. The PROBE_SEQ v2 CLI ladder (P0–P3) fired for the first time — **all four rows
   hit their predicted observable**, including `Signature:0x140101`.
3. The feboot drop (option A, commit `6fc4282`) is in the fire line — no
   `--extra-file bx510_feboot.ko`, no `/proc/driver` WARNING.

**Evidence bundle** (`evidence/bx510-guest/bdpdrv/`):

| file | size | sha256 |
|---|---|---|
| `bdpdrv-runC102.uart.log` | 94 156 B, 2 042 lines | `1bb18fe235f632ecd4aa217584fdfc63ad5ae56fedae09a5f3a60bc3ba2adfeb` |
| `bdpdrv-runC102.meta.json` | 1 005 B | `8b77f22aef8c102399d9e654960e8215a001e43971daa19b0fb2ab03a5a97033` |
| `bdpdrv-runC102.packet.mmio.gz` | 793 501 B — trace lines 552 020→EOF (the whole FE-window + `sr_mod` tail), gzipped per the C99 precedent | `e032b01ada004573b87709fcd3d006f16f09e2aad38f36f3743cb5f5e4be2eee` |

Full trace on the VM: `VM:/tmp/bdpdrv-runC102.mmio.log`, 100 555 867 B /
3 500 978 lines. Run identity: `ts_utc 2026-11-13T05:29:50Z`, bdpdrv
`6604f6cd…`, `clidrive_mode: PROBE_SEQ`, `stages.odd_tail: true`,
`terminal_marker: true`.

---

## 1. The verdict lines, verbatim

UART log, `sr_mod` load → node creation (lines 2028–2038):

```
2028  / # insmod /lib/modules/2.6.35/BDP/cdrom.ko; echo CDROM_INSMOD=$?
2029  CDROM_INSMOD=0
2030  / # insmod /lib/modules/2.6.35/BDP/sr_mod.ko; echo SRMOD_INSMOD=$?
2031  sr0: scsi-1 drive
2032  Uniform CD-ROM driver Revision: 3.20
2033  SRMOD_INSMOD=0
2034  / # mknod /dev/sr0 b 11 0; echo SR0_MKNOD=$?
2035  SR0_MKNOD=0
2036  / # ls -l /dev/sr0; echo SR0_LS=$?
2037  brw-r--r--    1 0        0          11,   0 Jan  1 00:02 /dev/sr0
2038  SR0_LS=0
```

| grep the task asked for | count | verdict |
|---|---|---|
| `sr0: scsi3-mmc drive` | **0** | NOT present — expected, see §2 |
| `sr0: scsi-1 drive` | **1** | ✅ **the attach line** |
| `Uniform CD-ROM driver` | **1** | ✅ `Revision: 3.20` |
| `Attached scsi CD-ROM` | 0 | expected — `KERN_DEBUG`, invisible at default loglevel (recipe §4.4.3) |
| `CDROM not ready` | 0 | expected — nothing opened the device, so `get_sectorsize()` never ran |

The pre-existing enumeration lines from C101 are unchanged (lines 290–295), so
the model edit did not regress the IDENTIFY/ATAPI path:

```
290  ata1.00: ATAPI: SONY    BDPSACDEMUL, 1.00, max UDMA/33
291  ata1.00: applying bridge limits
292  ata1.00: Drive reports diagnostics failure. …
293  ata1.00: configured for UDMA/33
294  scsi 0:0:0:0: CD-ROM            MTK 85xx - FA Mode 1.00        PQ: 0 ANSI: 5
```

### 1.1 `scsi-1` vs `scsi3-mmc` — the fork resolved as §4.3 predicted

`decode/scsi-scan-codes.md` §4.3 called this fork explicitly: with FA mode set,
Sony's `sr.c` takes `rc = 0x8000002` and prints `sr0: scsi-1 drive` without
issuing MODE SENSE. That is exactly what C102 shows. Source confirmation from
the tree that built the module (`VM:~/sony-kernel/linux-2.6.35/drivers/scsi/sr.c`):

```
1012  scsi_ioctl(cd->device, MT85XX_IDE_GET_FA_MODE,  (void __user *)&isFaMode);
1013  scsi_ioctl(cd->device, MT85XX_IDE_GET_BE_QUIET, (void __user *)&isBeQuiet);
1018  if (isFaMode || isBeQuiet)
1019  {
1020      rc = 0x8000002;
1021  }
1022  else
1023  {
1024      rc = scsi_mode_sense(cd->device, 0, 0x2a, buffer, 128, …);
```

So the `scsi3-mmc` line requires driving FA mode to 0 first, which is a
different experiment (§5, item 2). **The `scsi-1` outcome still enumerates the
device** — which was the objective.

---

## 2. SURPRISE: `sr_mod` issues NO CDB at all — the recipe's P2/P3 rows were never exercised

The single most important finding of this run is a **negative** one.

The whole 3.5 M-line trace contains **exactly ONE `0xa0` (ATA PACKET) post**, and
it is the **same one C101 had**, at the same place in the boot — *before* the
`ODD_TAIL` stage insmods `sr_mod`. The last FE mailbox write in the entire trace
is the `0xa0` fire itself:

```
552028  W 05c000 sz4 = a0000000     <- the ONLY packet, pre-sr_mod
552034  bx510: FE PACKET w1=00000000 w2=00000000 w3=00000000 nbytes=0 -> no-data
   …    3 500 978 total trace lines; NOTHING at 05c0xx after 552034
```

C102's 8 mailbox posts are the **same 8 quartets, in the same order, as C101**:

| count | w0 | w1 | w2 | w3 | reading |
|---|---|---|---|---|---|
| 2 | `0xa1000000` | 0 | `0xa000` | 0 | ATA IDENTIFY PACKET DEVICE |
| 1 | `0xa1000000` | 0 | 0 | 0 | `chk_int_ldr` entry (table A) |
| 1 | `0xef000000` | `0x4203` | `0xa000` | 0 | ATA SET FEATURES, UDMA mode 2 |
| **1** | **`0xa0000000`** | **0** | **0** | **0** | **ATA PACKET, zero-length** |
| 3 | `0x00100000` | 0 | 0 | 0 | driver ACK of a type-`0x10` offer |

### 2.1 Why: Sony's `sr.c` short-circuits TUR *as well as* MODE SENSE

`decode/scsi-scan-codes.md` §1.3 predicted TUR would reach the FE as a
`nbytes = 0` packet and READ CAPACITY as `nbytes = 8`. **Neither happened.**
The reason is a second FA-mode gate that the recipe did not account for —
`sr_test_unit_ready()` itself, at `sr.c:226`:

```
213  int isFaMode;
220  scsi_ioctl(sdev, MT85XX_IDE_GET_FA_MODE,  (void __user *)&isFaMode);
221  scsi_ioctl(sdev, MT85XX_IDE_GET_BE_QUIET, (void __user *)&isBeQuiet);
226  if (isFaMode || isBeQuiet)
227  {
228      the_result = 0x8000002;      <- fabricated CHECK CONDITION, no CDB issued
229  }
230  else
231  {
232      do { the_result = scsi_execute_req(sdev, cmd, DMA_NONE, NULL, 0, …); …
```

`get_capabilities()` calls `sr_test_unit_ready()` first (`sr.c:1008`), so with
FA mode 1 **both** probes are fabricated and the device is never issued a CDB.
`sr_probe` then attaches on type alone (`TYPE_ROM`) plus `register_cdrom()`
succeeding — matching `decode/sr0-scan-seq.md` §3: attachment is a *type*
decision, not a command-success decision.

**Consequence for the recipe:** rows P1 (zero-length TUR), P2 (READ CAPACITY)
and P3 (MODE SENSE page 0x2a) are implemented but **untested by this run** —
the only packet that appeared is the pre-`sr_mod` libata one, which classifies
as P1. P6 (READ(10)) is likewise unexercised. This is an honest negative with a
named cause, not a model bug: the model answered every packet it was given, and
the C101 comparison (8 posts, identical quartets) shows the `0xa0` row did not
change the pre-`sr_mod` behaviour.

Settling experiment for the untested rows is in §5.

### 2.2 The C102 MMIO signature the recipe predicted (§5), checked

| recipe §5 observable | C102 measurement |
|---|---|
| `W 05c000 = a0000000` (P1 zero image) | ✅ line 552028 |
| `R 05c804` → `W 05c804 = 0x10000` (read returned bit16) | ✅ 9 such writes across the run |
| → `R 05c804` → `W 05c804 = 0` (returned 0) | ✅ (drain loop terminates) |
| `R 05c040..04c` block reads | ✅ 10 reads |
| **NO** `0x5c400` writes for the packet rows | ✅ **0** writes to `0x5c400`, `0x5c404`, `0x5c408` — the descriptor stays unarmed, exactly as the recipe required |
| READ path (`0x5c400` triple) would mean C97's DMA leg | ✅ absent, as expected |

---

## 3. The PROBE_SEQ v2 CLI ladder — all four rows hit their prediction

First firing of the corrected ladder (`decode/probe-seq-v2.md` §1). Every row
matched the observable the decode table specified:

| row | command | parser rc | predicted observable | measured |
|---|---|---|---|---|
| **P0** | `drv.read 0x1000 0` | **0** | `Read addr = 0x00001000, length = 0`, NO payload row | ✅ UART 1828, no payload row → the dotted-leaf spelling reaches the handler, and length 0 returns before the deref |
| **P1** | `driver` | **1** | `[Help]` + `hdmitx(hdmitx):         Hdmi Tx command` | ✅ exact |
| **P2** | `drv` | **1** | `[Help]` + 57 lines incl `read(r):  Memory read(word)` | ✅ `read(r)` present in the dump |
| **P3** | `drv.ide.pri_ver.initial 0 s 0` | **0** | `[i4IdeHalTestInit]Signature:0x140101` + `CH:0, SataDev:1, UseQueue:0 Done!` | ✅ **`Signature:0x140101`** — see below |

The P3 prediction from `decode/ide-hal-rows.md` §0.2 was `Signature:0x140101`
(not `0xeb1401`), and that is the literal value printed. The a-window patch
(commit `996c5fc`) is confirmed in-guest: the old model, serving only `i>=3`,
would have printed `0x140100`.

```
2012  [i4IdeHalTestInit]Signature:0x140101
2015  [i4IdeHalSAtaReg(1072)]ERR:-4
2017  [i4IdeHalTestInit]CH:0, SataDev:1, UseQueue:0 Done!
2019  [CLIDRIVE] parser('P3 drv.ide.pri_ver.initial 0 s 0') = 0
```

Two secondary observations P3 produced:

* `[i4IdeHalSAtaReg(1072)]ERR:-4` — the a-window register the model does not
  serve at index 1072. It did **not** stop the init (`Done!` still printed), so
  it is a further a-window row worth a decode row, not a blocker.
* **No** `CmdWaitEvtRet:` / `TIMEOUT !!` and **no** `ModelName:` line. Per
  `probe-seq-v2.md` §1.1, `TIMEOUT !!` was the expected "today" outcome when the
  model's `a+220` row does not complete the wait. Its absence, together with the
  absence of `ModelName:`, says the bounded wait neither timed out nor reported a
  model name — an open question for §5, not a failure of the ladder.

---

## 4. What changed in the model (and what deliberately did not)

`emulator-kit/sony-bx510.c` — one function plus three helpers, per
`decode/scsi-scan-codes.md` §4.2. Committed-tree md5 before the edit
`3888f852…` → after `b41bb7ed…`.

* New window constant `FE_PKT_OFF 0x2400` / `FE_PKT_MAX 0x80` — the PACKET reply
  payload ride the **same DRAM-window / type-`0x10` route as IDENTIFY**, never
  the `0x5c400` descriptor (recipe §4.2's explicit constraint; C102 confirms
  0 writes there).
* `enum fe_pkt_kind` + `bx510_fe_packet_kind()` — the `0xa0` row selector. Keys
  on the ATAPI byte count (`w1` low 16 = `{feature, nsect}`) first, falling back
  to the CDB-opcode set when the length is neither 0/8/128 — the two readings the
  recipe says coincide row-for-row, so a zero image is P1 under both.
* `bx510_fe_read_capacity()` — P2, 8 bytes, last LBA + 2048 block length, **big
  endian**, derived from the block backend (so for the 1 064 208-sector ISO it
  reproduces the recipe's literal `00 10 3C 8F 00 00 08 00` exactly rather than
  hard-coding it).
* `bx510_fe_mode_sense6()` — P3, 128-byte page `0x2a` at the exact offsets
  `sr.c`'s `get_capabilities()` reads (§4.3).
* `bx510_fe_packet()` — the four-branch reply. **P6 READ posts a type-0
  completion and logs `LOG_UNIMP` that no FE-DMA is implemented** — C103 owns
  that path; the row must not silently claim a payload it never delivered.
* `bx510_fe_dispatch()` — the `code == 0xa0` branch (before the catch-all), plus
  the `0xef` row documented at the catch-all as recipe row R6 (SET FEATURES,
  bare completion, correct — C101's own `configured for UDMA/33` is the proof).
* **Untouched:** rows R0–R5 (mask / latch / status block / `0xa1` table-A /
  `0xa1` IDENTIFY variant A), the a-window patch, and every other address range.

### 4.1 Prep facts verified before the fire

| check | result |
|---|---|
| VM model md5 vs the Mac tree | **matched** at stage time (`3888f852…` = HEAD `996c5fc`), so the a-window patch was already in the model the fire used — nothing to fold in from `decode/ide-hal-rows.patch` |
| `decode/ide-hal-rows.patch` | **already applied and committed** in `996c5fc` (dry-run `patch` reports "previously applied") — no duplicate edit made |
| v2 shim `/tmp/osal_c/bx510_clidrive.ko` | ✅ md5 `e1d14c2577fd7a65bf54d3d51ef22897` — matches the task's expected value |
| feboot module in the fire line | ✅ gone — `6fc4282` removed the `insmod`; the run has **no `/proc/driver` WARNING** and no `FEB_INSMOD` line, unlike C101 |

---

## 5. Open items with their settling experiments

| # | item | label | experiment |
|---|---|---|---|
| 1 | P1 (nbytes 0), P2 (nbytes 8), P3 (nbytes 128), P6 (READ) rows are implemented but **never exercised**, because `sr.c` fabricates TUR and MODE SENSE under FA mode | **OBSERVED absent**, cause DECODED (`sr.c:226`, `sr.c:1018`) | Drive FA mode to 0 (the `mt85xx_ioctl` cli), then `insmod sr_mod.ko`: expected `nbytes=0 -> no-data` then `nbytes=128 -> mode-sense-6` and a `scsi3-mmc` line. Or `cat /dev/sr0` after the node exists → open path runs `READ TOC (0x43)` + `READ CAPACITY (0x25)` → expect `nbytes=8 -> read-capacity` |
| 2 | The `scsi3-mmc drive: 48x/48x cd/rw xa/form2 cdda tray` line (recipe §4.3's predicted payload render) | INFERRED — never printed | same FA-mode-0 experiment as #1; that is the only path to it |
| 3 | `[i4IdeHalSAtaReg(1072)]ERR:-4` during P3 | OBSERVED, not decoded | one a-window decode row for index 1072; check whether it is the sticky-global read the ide-hal-rows doc flagged |
| 4 | P3 printed neither `CmdWaitEvtRet`/`TIMEOUT !!` nor `ModelName:` | OBSERVED, not explained | compare the `a+220` wait path in the C102 trace against `ide-cli-lane.md` §7.3; a `ModelName:` print is the "wait completed" branch |
| 5 | `Drive reports diagnostics failure` (carried from C101) | OBSERVED, harmless | unchanged; the drive configures, left as-is per C101's note |
| 6 | READ(10) data path end-to-end (the firebird md5 oracles) | NOT STARTED | C103: implement the `0x5c400/404/408/40c` FE-DMA per `c97-read-path.md` §1.3, then read a sector and compare md5 against the ISO |

---

## 6. Fire line (reproducible, for C103)

```sh
make vm-stage-file FILE=emulator-kit/sony-bx510.c
make vm-exec CMD='cp /tmp/sony-bx510.c ~/bx510-emu/emulator/sony-bx510.c'
make vm-stage-file FILE=tools/bx510_bdpdrv_stub_probe.py
make vm-exec CMD='cp /tmp/bx510_bdpdrv_stub_probe.py ~/bx510-emu/emulator/'
make sacd-emu-build                       # ~5 s incremental, 5/5 steps, machine listed

make vm-exec CMD="cd ~/bx510-emu/emulator && \
  BX510_TRACE=1 BX510_MACHINE_OPTS='sata-disc=/home/aftermath/sacd-verify/firebird.iso' \
  python3 bx510_bdpdrv_stub_probe.py \
    --qemu /home/aftermath/bx510-emu/emulator/work/build/qemu-system-arm \
    --images /tmp/images-fe \
    --stubko /tmp/osal_b/bx510_osal_stub.ko \
    --stuba-ko /tmp/osal_a/bx510_osal_stub_a.ko \
    --bdpdrv-host /tmp/rootfs/lib/modules/2.6.35/BDP/bdpdrv.ko \
    --bdpdrv-guest /lib/modules/2.6.35/BDP/bdpdrv.ko \
    --pre-file libata.ko=/tmp/sata_staging/libata.ko \
    --pre-file sata_mt85xx_mod.ko=/tmp/sata_staging/sata_mt85xx_mod.ko \
    --extra-file bx510_clidrive.ko=/tmp/osal_c/bx510_clidrive.ko \
    --clidrive-mode PROBE_SEQ --odd-tail \
    --uart /tmp/bdpdrv-runC102.uart.log \
    --unimp /tmp/bdpdrv-runC102.mmio.log \
    --meta /tmp/bdpdrv-runC102.meta.json --timeout 420"
```

Deltas vs the C101 line: `--extra-file bx510_feboot.ko=…` **removed**
(`6fc4282`), `--odd-tail` **added** (`cdrom.ko` + `sr_mod.ko` + `mknod /dev/sr0`
— the recipe §4.4 prerequisites, offered as a flag by the probe script).
`--print-commands` dry-runs the same line and renders the 47-command guest list
plus the staging budget; the payload was 634 880 B in C101 and 583 680 B here
(the feboot module is no longer staged).
