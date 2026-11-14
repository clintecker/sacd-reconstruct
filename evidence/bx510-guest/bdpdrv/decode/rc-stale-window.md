# rc-stale-window.md — the C113 READ CAPACITY "stale window": root cause, and the model row it is owed

**Verdict.** There is no stale *window*. The model's `FE_PKT_OFF` payload route, its offset,
and its 8-byte READ CAPACITY(10) reply are all **correct, and that reply did land in the
guest's buffer** (`sr.c:933` read block length `2048` out of it — see V6). The wrong geometry
comes from a **second, independent capacity source that the model never answered**:
`get_sectorsize()` consults `cdrom_get_last_written()` (`sr.c:930`) and keeps
`max_t(long, cd->capacity, last_written)` (`sr.c:931`). That function ran its
`CDC_GENERIC_PACKET` branch and issued **READ DISC INFORMATION `0x51` and READ TRACK/RZONE
INFO `0x52`** — the model's only four `FE_PKT_UNKNOWN` posts in the whole run — answering each
with a **bare success and no payload**. Both readers return `buflen` regardless (`cdrom.c:3846`,
`cdrom.c:3803`), so the driver then read its **own uninitialised `track_information` stack
local**, took `*last_written = be32_to_cpu(ti.last_rec_address)` (`cdrom.c:3890`), and
`max_t()` replaced the correct 1 064 208-sector answer with a stale 4-byte value that the
guest itself prints: **`Disc MAX LBA=0x30300021`** (uart:2124).

The number chain, exact, no off-by-one anywhere:

| step | value | source |
|---|---|---|
| image | `firebird.iso` = 2 179 497 984 B = **1 064 208** × 2048 | `firebird-fixture.md:398` |
| model's RC reply, last LBA | 1 064 207 = `0x00103D0F` → `sr.c:921` `cd->capacity = 1064208` | model `sony-bx510.c:647`, VERIFIED |
| stale `ti.last_rec_address` | `0x30300020` = **808 452 128** (guest prints it **+1** as "Disc MAX LBA") | uart:2124, VERIFIED |
| `sr.c:931` `max_t()` | `max(1 064 208, 808 452 128)` = 808 452 128 | VERIFIED |
| `sr.c:948` `capacity *= 4` (sector_size 2048) | 3 233 808 512 sectors | VERIFIED |
| `sr.c:964` `set_capacity` → `i_size` = ×512 | **1 655 709 958 144 B** = the observed `blkgetsize64` | VERIFIED |
| `sr.c:968` `blk_queue_logical_block_size(2048)` | `blkssz=2048` = the observed value | VERIFIED |

`1 655 709 958 144 = 512 × 4 × 0x30300020` **exactly**, and `blkgetsize64/2048 = 0x30300020`
is the parent brief's arithmetic, confirmed. The wanted value is
`1 064 208 × 2048 = 2 179 497 984`.

---

## 1. The chain, step by step (each step's label in §6)

**V1 — the capacity reader is two readers, not one.** `get_sectorsize()`
(`sr.c:890`, Sony 2.6.35 tree `~/sony-kernel/linux-2.6.35/drivers/scsi/sr.c`):

```c
 901     cmd[0] = READ_CAPACITY;      /* 0x25 */
 902     memset((void *) &cmd[1], 0, 9);
 903     memset(buffer, 0, sizeof(buffer));          /* 8-byte stack buffer */
 906     the_result = scsi_execute_req(cd->device, cmd, DMA_FROM_DEVICE,
 907         buffer, sizeof(buffer), NULL, SR_TIMEOUT, MAX_RETRIES, NULL);
 ...
 921         cd->capacity = 1 + ((buffer[0] << 24) | (buffer[1] << 16) |
 922             (buffer[2] << 8) | buffer[3]);
 923     /* READ_CAPACITY doesn't return the correct size on certain UDF media.
 924      * If last_written is larger, use it instead. */
 930         if (!cdrom_get_last_written(&cd->cdi, &last_written))
 931             cd->capacity = max_t(long, cd->capacity, last_written);
 933         sector_size = (buffer[4] << 24) | (buffer[5] << 16) | ... buffer[7];
 942         case 0: case 2340: case 2352: sector_size = 2048;
 947         case 2048: cd->capacity *= 4;
 964         set_capacity(cd->disk, cd->capacity);
 968     blk_queue_logical_block_size(queue, sector_size);
```

The `buffer[0..3]` path and the `last_written` path are independent, and `max_t()` means the
**larger** of two wins. A model that only feeds the first path loses to any garbage in the second.

**V2 — the generic-packet branch is live on this rig.** `sr.c:845` sets `cd->cdi.mask = 0`
(no `CDC_*` capability is masked out), so `CDROM_CAN(CDC_GENERIC_PACKET)` is true at
`cdrom.c:3861` and the `use_toc` fallback is **not** taken.

**V3 — the four posts exist, in the right order, and only on this path.** C113 trace
(`VM:/tmp/bdpdrv-runC113.mmio.log`, pulled census kept at `VM:/tmp/c113-pkts.txt`):

| trace line | post | kind the model gave it |
|---|---|---|
| 3746719 | `w1=00000025 w2=00000000 w3=00000000` → `read-capacity` | correct (the run's only `0x25`) |
| 3746851 | `w1=00000051 w2=00000000 w3=00000002` | **`unknown`** |
| 3746937 | `w1=00000051 w2=00000000 w3=00000024` | **`unknown`** |
| 3747039 | `w1=00000152 w2=0000bbbb w3=00000008` | **`unknown`** |
| 3747365 | `w1=00000152 w2=0000bbbb w3=00000020` | **`unknown`** |

Whole-run packet census: 2031 × get-config, 6104 × no-data, 9 × read-toc, 1 × read-capacity,
1 × req-sense, **4 × unknown** — and the four `unknown`s are exactly these. `0x51` is issued
only by `cdrom_get_disc_info` (`cdrom.c:3807`, issuing `GPCMD_READ_DISC_INFO` =
`0x51` at `cdrom.c:3817`, `cdrom.h:506`) and `0x52` only by `cdrom_get_track_info`
(`cdrom.c:3764`, issuing `GPCMD_READ_TRACK_RZONE_INFO` = `0x52` at `cdrom.c:3774`, `cdrom.h:510`)
— the only other tree clients are `pktcdvd`/`viocd`, neither loaded on this guest — and both are
reached only from `cdrom_get_last_written`'s generic branch
(`cdrom.c:3864`, `cdrom.c:3871`). The pairs `2 → 0x24` and `8 → 0x20` are the driver's own
"read the header length, then requeue with the length the drive told us" trick
(`cdrom.c:3827-3836`, `cdrom.c:3787-3793`).

**V4 — the model answered them datalessly.** `bx510_fe_packet_kind()` (`sony-bx510.c:605-642`)
has no `0x51`/`0x52` row, so both fall to `FE_PKT_UNKNOWN`, and
`sony-bx510.c:815-819` posts `bx510_fe_post(s, 0, 0, 0, 0)` — status = success, **no
`bx510_fe_dram_write` at all**. `sr_do_ioctl` therefore returns 0 ("success") for both, which
is the trap: the driver proceeds *as if* it had data.

**V5 — the guest's own bytes prove `di` was never written.** The `0x52` CDB carries the track
number from `last_track = (di.last_track_msb << 8) | di.last_track_lsb` (`cdrom.c:3870`), i.e.
`cdb[4..5]` = `di[11]`,`di[6]`. The trace's `w2=0000bbbb` ⇒ **`di[6] = di[11] = 0xbb`**. That
is the driver's poison (`qc_issu_task` `0x7468`, `memset(buf, 0xbb, min(len,16))`,
`c97-read-path.md:52-55/§3.3`), not a drive payload — so `disc_information di;`
(`cdrom.c:3854`, a stack local) held nothing the FE ever wrote.

**V6 — the READ CAPACITY payload *did* land; the model is not at fault on that row.**
`sr.c:903` zeroes the 8-byte buffer before the command. If the model's payload had *not*
landed, `buffer[4..7] = 0` → `sr.c:942` coerces `sector_size` to 2048 and `cd->capacity` would
be `1 → ×4 = 4` sectors = **2048 bytes** total. The guest observed
1 655 709 958 144 B, i.e. `cd->capacity` = 808 452 128 ≠ 1, so `buffer[0..3]` landed too and was
`0x00103D0F` (the model's derived last LBA). **The RC reply was read correctly and then thrown
away by `max_t()`.**

**V7 — the stale read is `ti.last_rec_address`, and the branches say so.** Struct geometry taken
from the guest's own header (`~/sony-kernel/linux-2.6.35/include/linux/cdrom.h:855-940`) and
compiled through a `sizeof`/`offsetof` harness (see §7), not eyeballed:

```
sizeof(disc_information)   = 36   (0x24)   off last_track_lsb = 6, last_track_msb = 11
sizeof(track_information)  = 32   (0x20)   off track_start = 8, track_size = 24, last_rec_address = 28
```

`36` and `32` are **exactly** the alloc lengths of the two second-attempt posts (`0x24`, `0x20`):
with `di[0..1] = ti[0..1] = 0xbbbb` (poison), `buflen = 0xbbbb + 2 = 0xbbbd`, clamped at
`cdrom.c:3833-3834` / `cdrom.c:3790-3791` to the struct size. That is a second independent
signature of "the drive never wrote these structs".

Then, with `ret = buflen = 36 ≥ offsetof(last_track_lsb)+1 = 7` (`cdrom.c:3865`) and
`ti_size = buflen = 32`:

| gate | value from `0xbb` poison | taken? |
|---|---|---|
| `cdrom.c:3872` `ti_size < offsetof(track_start)=8` | 32 | no |
| `cdrom.c:3876` `ti.blank` — byte 6 bit 6 | `0xbb` bit6 = **0** | no retry (trace confirms: only two `0x52`) |
| `cdrom.c:3883` `ti_size < offsetof(track_size)+4 = 28` | 32 | no |
| `cdrom.c:3888` `ti.lra_v` — byte 7 **bit 1** | `0xbb` bit1 = **1** | **yes → `*last_written = be32(ti[28..31])`** |

(`0xbb` = `0b1011_1011`: bit1 = 1 ⇒ `lra_v`, bit6 = 0 ⇒ `blank` cleared. Bit numbering is the
`__LITTLE_ENDIAN_BITFIELD` arm of the header, verified by tool in §7.)

The poison covers only the **head 16 bytes** (`min(len,16)`), while the tail `0xbbbbbbbb` store
is **ATA-class only** (`c97-read-path.md:569`). `last_rec_address` sits at offset **28** — outside
the head, inside the tail — so on this **packet** post it stayed stale stack. C113 is therefore
also the standing confirmation of that "ATA-class only" clause: had the tail store run, the
capacity would have been `4 × 0xbbbbbbbb × 512 = 6 450 468 214 784 B`, not 1 655 709 958 144.

**V8 — the value is printed by the guest.** `evidence/bx510-guest/bdpdrv/bdpdrv-runC113.uart.log:2123-2124`:

```
[IDE]<_sata_mt85xx_hw_chg_st>Disc MAX LBA=0x1
[IDE]<_sata_mt85xx_hw_chg_st>Disc MAX LBA=0x30300021
```

`write10-model.md:228/518` decoded this exact site: `hw_chg_st 0x41b0 → 0x427c` parses the
**`0x52` response buffer** — `buf[7] & 2` (that is `lra_v`), `BE32(buf[8..11])`,
`BE32(buf[24..27])`, `BE32(buf[28..31])` — into `priv+0x20` = "Disc MAX LBA", printed at
`0x44e0`. The driver reads the **same** DMA buffer sr.c parses (`ti`), so:

* `Disc MAX LBA = 0x30300021` ⇒ `be32(buf[28..31]) = 0x30300020` (the driver stores
  last-recorded-**LBA + 1**, i.e. a count),
* `sr.c:3890` stores the field **without** the +1 ⇒ `last_written = 0x30300020 = 808 452 128`,
* and `512 × 4 × 0x30300020` reproduces `blkgetsize64` **to the byte**.

The earlier `Disc MAX LBA=0x1` is the same parse over a zeroed buffer (`0 + 1`) — the driver's
`+1` semantic and the all-zero baseline, both confirmed in one line pair. Two independent
witnesses (the block-layer size and the driver's printk) agree on the same four stale bytes.

**V9 — nothing else in the run touched capacity.** Exactly one `0x25` post exists in 1.14 GB of
trace; `get_sectorsize()` ran once (the `retries` loop only re-executes when `the_result != 0`,
and the guest never printed `unsupported sector size`, `sr.c:953`).

**V10 — this is the *only* thing `FE_PKT_UNKNOWN` is hiding on the open path.** The four
`unknown` posts are all capacity-related; `0x43`/`0x46`/`0x4a` are already answered and their
readers pass (gate 06/11, `[sr_cd_check]TOC buf:000a0101 00140100 00000200` at uart:2121 —
the model's 12-byte TOC reply, verbatim).

---

## 2. The brief's four questions, answered

**Q1 — where does the bottom half expect a type-`0x10` payload for a PACKET completion, and is
it the same `FE_PKT_OFF` READ CAPACITY uses?**
It is **not a guest-side constant**: the offset is carried *in the post*. The model writes the
payload into its FE DRAM window at `FE_PKT_OFF = 0x2400` (`sony-bx510.c:72`) and posts
`w0=0x00100000, w1=0x2400, w2=len` (`bx510_fe_post(s, 0x00100000u, FE_PKT_OFF, len, 0)`); the
bottom half copies `len` bytes from *that* window offset (`fe_dram_page << 22`, page programmed
at `0x5c500`) into the SCSI command's data buffer, whose VA→phys the driver computed at
`qc_issu_task 0x7090/0x7098` (`c97-read-path.md:44-46`). So the window offset is
**post-carried and identical for every data-in row** — the same route serves GESN, GET
CONFIGURATION, READ TOC (`fe_dram_page` armed, payload landing proven by uart:2121) and READ
CAPACITY. **What is different about READ CAPACITY's reader is not the buffer, it is that
`get_sectorsize()` has a second source**: `cdrom_get_last_written()` (`sr.c:930`) with
`max_t()` (`sr.c:931`). READ CAPACITY's own 8-byte reply lands in the stack `buffer[8]`
(`sr.c:893`) and is parsed at `sr.c:921/933` — correctly, see V6.

**Q2 — decode the C113 transcript around the capacity read; is `30300020` printed?**
Yes, as `0x30300021` — one more than the value, because the printer is a *different consumer* of
the same field (§V8). The Sony 2.6.35 `sr.c` prints nothing near `get_sectorsize` on the success
path (its `SR_LOG_FN` entry/exit prints carry no values; `cdrom_log_en=no` for
`CDROM_LOG_FN`, uart:1682/1731), but `sr_vendor.c:199`/`:203` do print — and did:

```
uart:2121  [sr_cd_check]TOC buf:000a0101 00140100 00000200     <- model's READ TOC reply, verbatim
uart:2122  [sr_cd_check]ms_offset=0x0, xa_flag=0x0, sector_size=0x800
uart:2123  [IDE]<_sata_mt85xx_hw_chg_st>Disc MAX LBA=0x1
uart:2124  [IDE]<_sata_mt85xx_hw_chg_st>Disc MAX LBA=0x30300021  <- the stale field
uart:2125  SRREAD mode=size dev=/dev/sr0 rc=0 errno=0 blkgetsize64=1655709958144 blkssz=2048
```

`sector_size=0x800` at 2122 is `sr_cd_check`'s own report that the 2048 block size came
through — consistent with V6 ordering (the TOC/`sr_cd_check` leg runs *before*
`get_sectorsize`, `sr.c:305-306`).

**Q3 — who wrote `30 30 00 20`?** Nobody: it is what was **already in the kernel stack frame of
`cdrom_get_last_written`** (`track_information ti;`, `cdrom.c:3855`) at offset 28..31 when the
function read it back as if the drive had filled it. Not the FE_PKT window (the window held the
12-byte TOC reply, and the model wrote nothing for this post — V4), and **not** the new
`bx510_fe_cdb_alloc78` clamp: the clamp list is `GESN | GET_CONFIG | READ_TOC` only
(`sony-bx510.c:835-838`), READ CAPACITY is not in it, and even if it were, `alloc = cdb[7]<<8 |
cdb[8] = 0` on a READ CAPACITY(10) CDB and the guard is `if (alloc != 0 && ...)`
(`sony-bx510.c:841`) — a no-op.
Confirmed against the trace: the RC post is `w1=00000025`, and the model's reply length is the
literal `len = 8` (`sony-bx510.c:775-777`), so the post carried `len=8`, not 0. (The brief's
`nbytes=37` is `w1 & 0xff | w1>>8 & 0xff` = `0x25` = 37 — the **opcode**, not a length; the
kind was resolved by the CDB-opcode key, `sony-bx510.c:626`, not by the byte-count key, which
only matches `0`/`8`/`128` and never fires for this writer. `dd-eio-loop.md` §6.4 item 4's
predicted `nbytes=8 -> read-capacity` is therefore *unreachable* from `sr.c:901-902`, which
posts `cdb[1] = 0`.)

**Q4 — `w1=00000025 w2=0 w3=0`: is the driver's own CDB saying "alloc 0"?**
Yes, and that is **correct per SBC**: READ CAPACITY(10) has **no allocate-length field**
(SBC-2 §6.11: CDB[1] = reserved|PMI, CDB[2..5] = LBA, CDB[6..9] reserved), and `sr.c:901-902`
builds exactly that — `cmd[0] = READ_CAPACITY; memset(&cmd[1], 0, 9)` — a **10-byte** CDB whose
`cdb[8]`/`cdb[9]` are zeros by construction. The transfer length is implicit (8 bytes) and the
model answering 8 bytes is right. `cdb[8] = (w3 >> 0) & 0xff = 0x00` per `c97-read-path.md` §4.1's
encoding (`cdb[i] = (w[(i>>2)+1] >> 8*(i&3)) & 0xff`) — nothing is wrong with the CDB.
**Correction owed to the model comment** that says "READ CAPACITY `0x25` uses CDB[8..9]"
(`sony-bx510.c:744-746`): that is READ CAPACITY(**16**) `0x9e/0x10`, whose allocate length is
CDB[10..13]. The 10-byte form has none. (No behavioural impact — the guard `alloc != 0` never
fires for `0x25` — but the comment will mislead the next reader, see §4.)

---

## 3. The model fix (paste-ready)

The fix is model-side, and it is **two rows, not one line** — the honest reason: two distinct
data-in commands are answered by two distinct readers, and each must carry its own data-length
field so the driver's "requery with the length the drive told us" loop terminates on *our* value
instead of on the `sizeof` clamp. Everything else in the model stays untouched.

Paste against the **current dirty `emulator-kit/sony-bx510.c`** (C112b/C113 state). No other
file changes.

```diff
@@ enum fe_pkt_kind (after FE_PKT_READ_TOC, line 585)
     FE_PKT_READ_TOC,        /* cdrom_count_tracks on the blocking open: 0x43 */
+    FE_PKT_DISC_INFO,       /* sr.c capacity: 0x51 READ DISC INFORMATION */
+    FE_PKT_TRACK_INFO,      /* sr.c capacity: 0x52 READ TRACK/RZONE INFO */
     FE_PKT_REQ_SENSE,       /* REQUEST SENSE after a drive-error completion */

@@ fe_pkt_kind_name (after "read-toc", line 599)
     case FE_PKT_READ_TOC:    return "read-toc";
+    case FE_PKT_DISC_INFO:   return "disc-info";
+    case FE_PKT_TRACK_INFO:  return "track-info";

@@ bx510_fe_packet_kind: cdb_ops (line 609)
-    static const uint8_t cdb_ops[] = { 0x00, 0x03, 0x12, 0x1a, 0x1b, 0x25,
-                                       0x28, 0x43, 0x46, 0x4a, 0x5a,
-                                       0xa8, 0xbe };
+    static const uint8_t cdb_ops[] = { 0x00, 0x03, 0x12, 0x1a, 0x1b, 0x25,
+                                       0x28, 0x43, 0x46, 0x4a, 0x51, 0x52,
+                                       0x5a, 0xa8, 0xbe };

@@ bx510_fe_packet_kind: opcode switch (line 631)
     case 0x43: return FE_PKT_READ_TOC;
+    case 0x51: return FE_PKT_DISC_INFO;
+    case 0x52: return FE_PKT_TRACK_INFO;
     case 0x03: return FE_PKT_REQ_SENSE;

@@ after bx510_fe_read_capacity (line 660, end of function)
+
+/* READ DISC INFORMATION (0x51) and READ TRACK/RZONE INFO (0x52) — the two
+ * data-in rows behind sr.c's capacity, and the C113 geometry bug
+ * (rc-stale-window.md). get_sectorsize keeps max_t(cd->capacity, last_written)
+ * (sr.c:931) and gets last_written from cdrom_get_last_written's generic-packet
+ * branch: 0x51 -> cdrom_get_disc_info (cdrom.c:3807) -> last_track =
+ * be16(di[11],di[6]) (cdrom.c:3870) -> 0x52 -> cdrom_get_track_info
+ * (cdrom.c:3764) -> *last_written = be32(ti[28..31]) (cdrom.c:3890). Both
+ * readers return buflen, not an error (cdrom.c:3846/3803), so a BARE success
+ * hands the driver its own uninitialised stack: `di` keeps the 0xbb head poison
+ * (qc_issu_task 0x7468), last_track became 0xbbbb (C113 trace w2=0000bbbb) and
+ * ti[28..31] kept stale stack 0x30300020, which max_t() then preferred over the
+ * CORRECT READ CAPACITY answer — blkgetsize64 1655709958144 instead of
+ * 2179497984. Answer them with the standard layouts (MMC-6 §5.3.3 / §6.24,
+ * track_information fields the MediaTek parser reads at hw_chg_st 0x427c:
+ * buf[7]&2 = lra_v, BE32 at 8/24/28 — write10-model.md:228). Data Length =
+ * payload-2, so the driver's requeue lands on 36/32 without the sizeof clamp. */
+#define FE_DISC_INFO_LEN  36u   /* sizeof(disc_information)  = 2 + 34 */
+#define FE_TRACK_INFO_LEN 32u   /* sizeof(track_information) = 2 + 30 */
+
+static void bx510_fe_disc_info(uint8_t *buf)
+{
+    memset(buf, 0, FE_DISC_INFO_LEN);
+    buf[0] = 0x00;                  /* Disc Information Length 34, BE */
+    buf[1] = 0x22;
+    buf[3] = 0x01;                  /* n_first_track */
+    buf[4] = 0x01;                  /* n_sessions_lsb */
+    buf[5] = 0x01;                  /* first_track_lsb */
+    buf[6] = 0x01;                  /* last_track_lsb -> last_track = 1 */
+}
+
+static void bx510_fe_track_info(Bx510State *s, uint8_t *buf)
+{
+    uint64_t sectors = s->sata_blk ? blk_getlength(s->sata_blk) / 2048 : 0;
+    uint32_t last_lba = sectors ? (uint32_t)(sectors - 1) : 0;
+
+    memset(buf, 0, FE_TRACK_INFO_LEN);
+    buf[0]  = 0x00;                 /* Track Information Length 30, BE */
+    buf[1]  = 0x1e;
+    buf[2]  = 0x01;                 /* track_lsb */
+    buf[3]  = 0x01;                 /* session_lsb */
+    buf[5]  = 0x04;                 /* track_mode 4 = data track */
+    buf[6]  = 0x01;                 /* data_mode 1; blank (bit6) clear */
+    buf[7]  = 0x02;                 /* lra_v (bit1): last_rec_address valid */
+    buf[24] = last_lba >> 24;       /* track_size */
+    buf[25] = last_lba >> 16;
+    buf[26] = last_lba >> 8;
+    buf[27] = last_lba;
+    buf[28] = last_lba >> 24;       /* last_rec_address -> *last_written */
+    buf[29] = last_lba >> 16;
+    buf[30] = last_lba >> 8;
+    buf[31] = last_lba;
+}

@@ bx510_fe_packet: after the READ_TOC case (after line 814)
+    case FE_PKT_DISC_INFO:
+        bx510_fe_disc_info(payload);
+        len = FE_DISC_INFO_LEN;
+        break;
+    case FE_PKT_TRACK_INFO:
+        bx510_fe_track_info(s, payload);
+        len = FE_TRACK_INFO_LEN;
+        break;

@@ bx510_fe_packet: the allocate-length clamp (line 835)
-    /* the CDB always wins: never answer with more bytes than it asked for
-     * (allocation length at CDB[7..8] for exactly these three opcodes) */
-    if (kind == FE_PKT_GESN || kind == FE_PKT_GET_CONFIG ||
-        kind == FE_PKT_READ_TOC) {
+    /* the CDB always wins: never answer with more bytes than it asked for.
+     * CDB[7..8] is the Allocate Length for exactly these five opcodes (0x51 and
+     * 0x52 in MMC-6 §6.24/§6.35); READ CAPACITY 0x25 has NO allocate field at
+     * all (SBC-2 §6.11, its 10-byte CDB is cdb[0] + 9 zero bytes — sr.c:902),
+     * and MODE SENSE(6) 0x1a carries it at CDB[4]. */
+    if (kind == FE_PKT_GESN || kind == FE_PKT_GET_CONFIG ||
+        kind == FE_PKT_READ_TOC || kind == FE_PKT_DISC_INFO ||
+        kind == FE_PKT_TRACK_INFO) {
```

Result for `firebird.iso`: `0x51` → `di[0..1] = 00 22` → `buflen = 36`; `last_track = 1`;
`0x52` → `ti[0..1] = 00 1e` → `buflen = 32`; `*last_written = 1 064 207`;
`max(1 064 208, 1 064 207) = 1 064 208`; `×4 = 4 256 832` sectors;
`set_capacity` → **2 179 497 984 B**.

Two extra one-word fixes in the same edit (docs debt, no behaviour):

```diff
- * Derived from the attached image, so for C101/C102's 1 064 208-sector ISO it
- * reproduces the recipe's literal bytes 00 10 3C 8F 00 00 08 00 exactly. */
+ * Derived from the attached image, so for C101/C102's 1 064 208-sector ISO it
+ * reproduces last LBA 1 064 207 = 00 10 3D 0F with block length 00 00 08 00. */
```

(`0x00103C8F` = 1 064 079, **not** 1 064 207 — see §4.)

---

## 4. Corrections this decode forces on existing docs

| where | was | now |
|---|---|---|
| `fe-read-dma.md:175,181` and the `bx510_fe_read_capacity` comment | "1 064 207 = `0x00103C8F`" | **1 064 207 = `0x00103D0F`**; `0x00103C8F` = 1 064 079. Arithmetic slip, propagated into the C113 brief. The *code* was always right (`sectors - 1`), which is why the LBA-1064207 read byte-matched the oracle. |
| `sony-bx510.c:744-746` comment | "READ CAPACITY 0x25 uses CDB[8..9]" | READ CAPACITY(**10**) has no allocate-length field (SBC-2 §6.11); `0x9e/0x10` (RC-16) has it at CDB[10..13]. |
| `dd-eio-loop.md` §6.4 item 4 | "one `nbytes=8 -> read-capacity`" | unreachable: `sr.c:902` posts `cdb[1] = 0`, so `nbytes = 0x25 = 37`; the kind resolves on the opcode key. |
| `dd-eio-loop.md` §7 item 3 | "`0x51` … not on the unlocked path … reached only from a real media-change notification" | **closed** — `0x51`/`0x52` are on the capacity path itself (`sr.c:930` → `cdrom.c:3864/3871`); they appear the moment the FA clear lets `get_sectorsize()` run. |
| `write10-model.md:555` | "`0x52`'s real layout — INFERRED (Sony/MediaTek disc-info)" | **VERIFIED = standard `READ TRACK/RZONE INFO` (0x52) reply carrying `track_information`**: the MediaTek parser's `buf[7] & 2`, `BE32[8..11]`, `BE32[24..27]`, `BE32[28..31]` are exactly `lra_v`, `track_start`, `track_size`, `last_rec_address` of `cdrom.h`'s struct, and the CDB (`cdb[1]=type 1`, `cdb[4..5]=track`, `cdb[7..8]=alloc`) is byte-identical to what `cdrom.c:3764-3782` writes. The settling experiment named there has now run. |
| `dd-eio-loop.md` §7 item 2 ("`get_sectorsize()`'s ×4 … if the real disc size later disagrees, this is where to look") | suspect: the ×4 | the ×4 **is** correct and did run (`sr.c:948`); the disagreement is upstream, in `last_written`. |
| `c97-read-path.md:569` "tail `0xbbbbbbbb` … ATA-class only" | asserted from disassembly | **independently confirmed**: a packet-path `0x52` with a 32-byte buffer left `last_rec_address` stale (1 655 709 958 144 B observed vs the 6 450 468 214 784 B a tail store would force). |

Adjacent defect found, **not** this root cause and **not** a C114 blocker: the model answers a
`READ TOC` **LEADOUT** request (`0x43`, `cdb[6] = 0xAA`, i.e. `cdrom_get_last_written`'s
`use_toc` fallback, `cdrom.c:3906-3915`) with the *track-1* entry (MSF 00:02:00 → LBA 0). With
§3 applied the fallback is unreachable on this path, and LBA 0 is safe for `max_t()` anyway;
recording it so it is not re-derived as "the leadout read is stuck at 0" later.

---

## 5. C114 — falsifiable prediction

Run C113's exact battery with the §3 patch; nothing else changes.

| # | prediction | kills |
|---|---|---|
| **P1** | uart: `SRREAD mode=size dev=/dev/sr0 rc=0 errno=0 blkgetsize64=2179497984 blkssz=2048` — exactly `1 064 208 × 2048` | the whole decode if it stays 1 655 709 958 144 |
| **P2** | uart: the two `Disc MAX LBA` lines become `0x1` and **`0x103D10`** (`= 1 064 208`) | proves the 0x52 payload reached the driver's parser (its field is `last_lba + 1`) |
| **P3** | trace: the `0x52` CDB's `w2` changes from `0000bbbb` to **`00010000`** (track `0x0001` from *our* `di[6]/di[11]`), and the four `unknown` rows become `disc-info`, `disc-info`, `track-info`, `track-info` — 4 unknown → **0 unknown** | P3 is the mechanism test; P1 is the consequence test. They can only disagree if the payload lands but the arithmetic differs |
| **P4** | trace: alloc pairs stay `02/24` and `08/20` but now **derived from our data-length fields** (`00 22` → 36, `00 1e` → 32), not from the `sizeof` clamp | — (not distinguishable in the alloc numbers alone; P3 is the discriminator) |
| **P5** | `LADDER a2 PASS dd LBA 16` still passes, gate 06/09/10/11/12 unchanged, 0 oopses; `GATE 13 master-toc` unchanged (it is `SG_IO`, below any capacity bound) | a regression from the two new rows |

**Kill criteria (pre-registered).**

1. If **P3 fails** (`w2` stays `0000bbbb` while the trace shows `disc-info`/`track-info` posts),
   then the type-`0x10` payload is **not** landing in the guest's command buffer for `0x51`/
   `0x52` — a DMA direction/length problem, *not* payload content. Next suspect: the
   `len`-vs-`cgc.buflen` copy rule in the bottom half (`bx510_fe_post`'s w3), because a
   128-byte MODE SENSE landing and a 36-byte DISC INFO not landing would differ only in size.
2. If **P3 passes and P1 fails**, the stale value is being read from somewhere other than
   `ti` — then the `sr.c:931` `max_t()` decode is wrong and `cd->capacity` itself is being
   clobbered; the next target is `sr_media_change`'s re-arm path (`sr.c:284-306`).
3. If **P1 passes and P5 fails** (a gate that used to pass breaks), the new rows changed a byte
   count on the *shared* window at `0x2400` that a later reader was riding; escalate rather
   than tune.

Also expect, and do **not** read as a regression: with capacity correct, buffered `dd` reads are
now bounded to LBA ≤ 1 064 207 by the block layer. The ladder's `past_eof` leg
(`lba=1064208`, `sense=010000`) uses `SG_IO` `read10` and so still reaches the FE — unchanged.

---

## 6. Labels

| claim | label |
|---|---|
| the model's READ CAPACITY reply is correct and reached the guest | **VERIFIED** (V6: `sr.c:903` zero-fill ⇒ a non-landing payload gives capacity 4 sectors = 2048 B; observed 1 655 709 958 144 B) |
| `cdrom_get_last_written` ran its `CDC_GENERIC_PACKET` branch | **VERIFIED** (`sr.c:845` mask 0; the four `0x51`/`0x52` posts exist at trace 3746851/3746937/3747039/3747365, and those opcodes have no other caller) |
| the model answered them bare-success with no payload | **VERIFIED** (audit, `sony-bx510.c:815-819`; all four classified `unknown`) |
| `di` was never written by the drive | **VERIFIED** (`last_track = 0xbbbb` in the `0x52` CDB = `di[6],di[11]`, and `0xbb` is the driver's own poison) |
| the second-attempt allocs `0x24`/`0x20` are the `sizeof` clamps | **VERIFIED** (tool-derived `sizeof(disc_information)=36`, `sizeof(track_information)=32`) |
| the branch taken is `cdrom.c:3888` with `lra_v = 1` | **VERIFIED** (`0xbb` bit1; python-checked, §7) |
| `last_written = 0x30300020` from `ti[28..31]` | **VERIFIED** (two witnesses: `512×4×0x30300020` = observed `blkgetsize64` exactly; `Disc MAX LBA=0x30300021` = that field `+1` per `write10-model.md:228`) |
| `0x52` is standard READ TRACK/RZONE INFO with `track_information` layout | **VERIFIED** (parser offsets = struct offsets; CDB = `cdrom.c:3764-3782` byte-for-byte) |
| the tail `0xbbbbbbbb` store is ATA-class only | **VERIFIED** by this run's arithmetic (would have given 6 450 468 214 784 B) |
| **which earlier stack frame left `30 30 00 20` at `ti+28`** | **INFERRED / OPEN (Q-1)** — a stale kernel-stack fragment from an earlier, deeper call of the same task; provenance irrelevant to the fix (any value > 1 064 208 corrupts the geometry, 0 does not), and asking for it needs a guest memory read the rig has no channel for yet |
| the four `unknown` posts are the *only* remaining dataless data-in rows on the open path | **VERIFIED for C113** (whole-run census: 4 unknown, all `0x51`/`0x52`) |
| §3's patch yields 2 179 497 984 | **PREDICTED** (P1-P3, C114) |

---

## 7. Reproduce

```sh
# the control + the C114 prediction, host-side, in one file (asserted)
cc -Wall -Wextra -o /tmp/rcsim evidence/bx510-guest/bdpdrv/decode/rc-stale-window.sim.c \
   && /tmp/rcsim
#   C113  (0x51/0x52 bare success) blkgetsize64 = 1655709958144
#   +patch(0x51/0x52 answered)     blkgetsize64 = 2179497984
#   OK: control reproduces C113, patch predicts C114 P1

# packet census from the 1.14 GB C113 MMIO trace (VM-side; never pull the log)
grep -o "bx510: FE PACKET.*-> [a-z-]*" /tmp/bdpdrv-runC113.mmio.log | sed 's/.*-> //' | sort | uniq -c
grep -n "bx510: FE PACKET" /tmp/bdpdrv-runC113.mmio.log | grep -v "no-data\|get-config"

# the guest's own witness (pulled: evidence/bx510-guest/bdpdrv/bdpdrv-runC113.uart.log)
sed -n '2121,2125p' evidence/bx510-guest/bdpdrv/bdpdrv-runC113.uart.log

# the reader's source, in the guest tree
sed -n '890,968p' ~/sony-kernel/linux-2.6.35/drivers/scsi/sr.c
sed -n '3764,3900p' ~/sony-kernel/linux-2.6.35/drivers/cdrom/cdrom.c
sed -n '855,940p'  ~/sony-kernel/linux-2.6.35/include/linux/cdrom.h

# struct geometry by tool, not by eye (this doc's §V7 numbers)
python3 - <<'PY'
obs = 1655709958144
assert obs//512//4 == 0x30300020                      # capacity pre-×4
assert 4*0x30300020*512 == obs                        # ×4 (sr.c:948) then ×512 (set_capacity)
assert 1064208*2048 == 2179497984                     # the wanted value
assert 1+0x00103D0F == 1064208                        # the model's RC answer
assert max(1064208, 0x30300020) == 0x30300020          # max_t() wins (sr.c:931)
assert 0xbb & 0x02 and not (0xbb & 0x40)              # ti.lra_v=1, ti.blank=0
print("all assertions hold")
PY
```

The `sizeof`/`offsetof` harness: extract `~/sony-kernel/…/include/linux/cdrom.h` lines 856-940,
typedef `__u8/__u16/__u32/__be16/__be32`, `#define __LITTLE_ENDIAN_BITFIELD`, `cc -o offlen`,
print `sizeof`/`offsetof(disc_information, last_track_lsb|last_track_msb)` and
`offsetof(track_information, track_start|track_size|last_rec_address)` →
`36 / 6 / 11` and `32 / 8 / 24 / 28`.

`rc-stale-window.sim.c` (this directory) is the §3 payload + guest-arithmetic replay: it runs the
two builders verbatim, applies the driver's head poison and the `sizeof` clamps, and asserts the
C113 control (**1 655 709 958 144**) against the patched result (**2 179 497 984**). Its `[0x52
CDB track=…]` lines are C114's P3 in miniature: `0xbbbb` → `0x0001`.

---

## 8. Open items

1. **Q-1 — provenance of `30 30 00 20`.** Stale stack; identifying the earlier writer needs a
   guest memory channel the rig does not have. Not a fix prerequisite.
2. **Q-2 — the driver's `priv+0x20` (Disc MAX LBA) vs `cd->capacity`.** They now agree in
   *origin* (same `0x52` buffer, §V8) but nothing guarantees they are re-derived together. C114's
   P2/P1 pair checks that they move together; if they diverge later, the cache gate at
   `hw_chg_st 0x7394` (`priv+0x2c < priv+0x20`) is the place to look (inert for profile `0x0010`,
   `write10-model.md:228`).
3. **Q-3 — `READ DISC INFORMATION`'s `disc_status`.** The §3 payload says `0x00` (empty). No
   reader on the capacity path parses it (`cdrom.c:3864-3894` reads only `last_track_lsb/msb`),
   but a future media-change row will want `0x02` (complete). Flagged so it is a decision, not a
   discovery.
4. **The LEADOUT TOC answer** (§4, adjacent defect) — one row, not this root cause.
