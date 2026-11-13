# BX510 `sata_mt85xx_mod.ko` — the three FE `TAG mismatch` errors: tags, partitions, structure, fixture recipe

Decode of the three `TAG mismatch` lines that every C9x run prints immediately after
`[IDE] FE firmware CheckSum OK !!`, and the fixture recipe that makes them pass.

**Module under decode (pinned, same file as `sata-fw-load.md`):**

| field | value |
|---|---|
| path | `/tmp/bdpdrv/sata_mt85xx_mod.ko` (staged from the guest `/res/shim/`) |
| size | 69,452 B |
| sha256 | `8a0253eb9bff19a3d3c0ac594a507235bad82348d8e80069024368d0f5456657` |
| disassembly | `/tmp/bdpdrv/sata.dis` (line numbers cited below are *file lines* in that file) |

All three `SocRead*` names in the log are `__func__` strings — **none of them is a
symbol**. They are the three inlined sections of `sata_mt85xx_xfer_int_ldr_fw`
(`.text+0x1644`, size 0x8f8):

| `__func__` string | `.rodata` slot | referenced at | section of `xfer_int_ldr_fw` |
|---|---|---|---|
| `sata_mt85xx_SocReadPowerCurve` | `.rodata+0x30` | `.text+0x1a3c` (check), `.text+0x1ccc`/`0x1e60`/`0x1e8c` (prints) | `.text+0x16ac`..`0x16e8` + `.text+0x1a34`..`0x1dc0` |
| `sata_mt85xx_SocReadFaTable` | `.rodata+0x50` | `.text+0x1b74` (check), `.text+0x1ba4`/`0x1e14` | `.text+0x1708`..`0x1780` + `.text+0x1b4c`..`0x1da0` |
| `sata_mt85xx_SocReadParameter` | `.rodata+0x6c` | `.text+0x1af8` (check), `.text+0x1b2c`/`0x1e44` | `.text+0x1788`..`0x17e0` + `.text+0x1ad4`..`0x1d58` |

The mismatch print is one shared format string, `%c%c%c%c` of the four bytes at
`buf+0`:

```
.rodata.str1.4+0x658  "[IDE]<%s>(Error)TAG mismatch:%c%c%c%c\n"
```

The four bytes come from four separate `ldrb` (`buf[0]`, `buf[1]`, `buf[2]`, `buf[3]`),
so the log field is exactly 4 bytes — including bytes that are not printable. Do not
read them as text.

**The three observed payloads, decoded with a byte-level tool (`decode/fe_tags_probe.py`), not by eye:**

| log line | bytes | as ASCII |
|---|---|---|
| `SocReadPowerCurve` | `b6 7a 75 2c` | `<0xb6>` `z` `u` `,` |
| `SocReadFaTable` | `73 68 69 6d` | `shim` |
| `SocReadParameter` | `ff ff ff ff` | (erased) |

Identical in C76, C77, C91, C93, C94, C95 — deterministic, not per-run noise.

---

## 1. The three tables

### 1.1 `SocReadPowerCurve` — reads `fe_power_curve` (`/dev/mtd12`)

| item | value | evidence |
|---|---|---|
| **expected tag** | `"PWRC"` = `50 57 52 43` (LE dword `0x43525750`) | `sata.dis:1690` `ldr r1, [pc,#0x4a0] @ 0x1ee0` → `R_ARM_ABS32 .data` +0x10; `.data+0x10 = b"PWRC"` |
| compare | `strncmp(buf, "PWRC", 4)` | `sata.dis:1689-1694` — `0x1a34 mov r0,r7`, `0x1a40 bl strncmp`, `0x1a48 bne 0x1ca8` (mismatch) |
| **partition** | `fe_power_curve`, `.bss+0x20` | `.text+0x16ac` `ldr r0,[pc,#0x7fc] @ 0x1eb0 → .bss+0x20`; `sata.dis:1463` |
| partition geometry | `0x01000000`, size `0x00100000` | manifest `fe_power_curve off=0x01000000 size=0x100000 recs=0`; guest `/proc/mtd`-derived table, C95 UART line 100 |
| driver's own node binding | `/dev/mtd12` | C95 UART line 236 — `fe_power_curve - /dev/mtd12` (printed by `sata_mt85xx_parse_mtd_table`) |
| **read call** | `MTDRawRead(fe_power_curve, 32, 0x420, buf)` — reads from partition **offset 0** | `.text+0x16ac`..`0x16bc`; len `r10 = (POWC.f2=0x400 + 32) & ~15 = 0x420` (`.text+0x1658`, `0x1684-0x1688`) |
| **expected structure** | 16-byte header + payload + byte-sum checksum (see §2) | checksum block at `.text+0x1a4c`..`0x1a84` |
| **on mismatch** | **non-fatal, zero-fills** | `.text+0x1a48 bne 0x1ca8` → print `TAG mismatch` → `b 0x16d8` → kfree → `.text+0x16f4 bne 0x1d38` → `__memzero(power_curve_buf)` (.text+0x1d38-0x1d3c) → `b 0x16f8` (continue with the FA table) |

Note the spelling trap: the **partition record tag** is `PWRC`, while the **`fw` header
tag record** for the same table is `POWC` (`0x43574f50`, `sata-fw-load.md` §4). Two
different strings for the same concept — the partition must carry `PWRC`.

### 1.2 `SocReadFaTable` — reads `fe_test_data` (`/dev/mtd10`)

| item | value | evidence |
|---|---|---|
| **expected tag** | `"FATB"` = `46 41 54 42` (LE dword `0x42544146`) — checked **twice** | (a) `.text+0x1b74` `ldr r1,[pc,#0x384] @ 0x1efc → .data+0x24`; `.data+0x24 = b"FATB"`; `sata.dis:1767-1772`. (b) inside `MTDAdvRead` at `sata.dis:889-895` (`0xdb8 mov r2,#4`, `0xdc4 bl strncmp`, `0xdcc bne 0xe50`) against the tag argument passed in `r2` |
| **partition** | `fe_test_data`, `.bss+0x30` | `.text+0x1b4c` `ldr r0,[pc,#0x3a4] @ 0x1ef8 → .bss+0x30`; `sata.dis:1759` |
| partition geometry | `0x00e00000`, size `0x00100000` | manifest `fe_test_data off=0xe00000 size=0x100000 recs=0`; C95 UART line 98 |
| driver's own node binding | `/dev/mtd10` | C95 UART line 234 |
| **read call** | `MTDAdvRead(fe_test_data, 20, "FATB", 0x2020, buf)` | `.text+0x1b4c`..`0x1b60` — args `path=.bss+0x30`, `r1=20` (dead, see §2.3), `r2="FATB"`, `r3=0x2020` = `(FATB.f2=0x2000)+32` (`.text+0x1710-0x1714`), `[sp]=out`. Log cross-check: `Read from addr : 0x00000000, len : 0x00002020, Align len : 0x00002800` |
| **expected structure** | same 16-byte header, tag at **buffer offset 0** *and* at the first 4 bytes of the NAND page it finds | §2 |
| **on mismatch (inner, `MTDAdvRead`)** | **skips and keeps scanning**; prints `[IDE] <sata_mt85xx_MTDAdvRead> TAG mismatched, Latest stored data in start_addr = 0x%08X` (`.rodata.str1.4+0x484`, `.text+0x12b8`) and returns the best-effort region with `Read from addr : 0x%08X, len : 0x%08X, Align len : 0x%08X` (`.rodata.str1.4+0x4f8`, `.text+0x12f4`) | `sata.dis:891-895`, `540`, `557` |
| **on mismatch (outer, caller)** | **non-fatal, falls back to the FW image** | `.text+0x1b80 beq 0x1c0c` (ok) ⇒ else `0x1b84..0x1bb4` print `TAG mismatch` → `b 0x174c` → kfree → `.text+0x1760-0x1778` `memcpy(buf, *sata_int_ldr_fw + FATB.f1(=0xFE000), 0x2000)` → `read FA table from FW offset = 0x%x` → `Read FA table len: %d OK.` |

This is the only one of the three with a **working fallback that already succeeds
today**: C95 shows `[IDE]read FA table from FW offset = 0xfe000` then
`[IDE]<xfer_int_ldr_fw> Read FA table len: 8192 OK.` So the FA table is *not* left
at a default fill — the driver substitutes the copy embedded in `fe_bin_1` at
`0xFE000`.

### 1.3 `SocReadParameter` — reads `fe_parameters` (`/dev/mtd11`)

| item | value | evidence |
|---|---|---|
| **expected tag** | `"PARM"` = `50 41 52 4d` (LE dword `0x4d524150`) | `.text+0x1af8` `ldr r1,[pc,#0x3ec] @ 0x1eec → .data+0x38`; `.data+0x38 = b"PARM"`; `sata.dis:1735-1742` |
| compare | `strncmp(buf, "PARM", 4)` | `0x1af4 mov r0,r10`, `0x1afc mov r2,#4`, `0x1b00 bl strncmp`, `0x1b08 beq 0x1bb8` (ok) |
| **partition** | `fe_parameters`, `.bss+0x40` | `.text+0x1ad4` `ldr r0,[pc,#0x40c] @ 0x1ee8 → .bss+0x40` |
| partition geometry | `0x00f00000`, size `0x00100000` | manifest `fe_parameters off=0xf00000 size=0x100000 recs=0`; C95 UART line 99 |
| driver's own node binding | `/dev/mtd11` | C95 UART line 235 |
| **read call** | `MTDAdvRead(fe_parameters, 30, "PARM", 0x2000, buf)` — **note: no `+0x20` slack here** | `.text+0x1ad4`..`0x1ae8`; len `[sp,#0x10] = PARM.f2 = 0x2000` (`.text+0x1788`, `0x1798-0x179c`). Log cross-check: `len : 0x00002000, Align len : 0x00002000` |
| **expected structure** | same 16-byte header | checksum block `.text+0x1bb8`..`0x1bec` |
| **on mismatch** | **non-fatal, 0xFF-fills** | `0x1b0c..0x1b3c` print `TAG mismatch` → `b 0x17e4` → kfree → `0x1e54` print `Read parameter failed !!` → `.text+0x17f8-0x1800 bne 0x1d28` → `memset(param_buf, 0xFF, PARM.f2)` (`.text+0x1d28-0x1d30`) → `b 0x1804` |

Quirk worth recording: the Parameter path copies the **whole** read buffer
(including the 16-byte header) into FE DRAM — `.text+0x1d4c-0x1d58`
`memcpy(dst, buf /* r10, not r10+16 */, PARM.f2)`. The PowerCurve and FA-table paths
strip the header first (`.text+0x1da8` `memcpy(dst, buf+16, min(total_len, 0x400))`,
`.text+0x1d80` `memcpy(dst, buf+16, min(total_len-16, 0x2000))`). So the 16-byte header
lands in the FE's parameter region at DRAM `0x15000`.

---

## 2. The structure all three expect

Every one of the three check blocks is the same two-stage test, in the same order:
**tag first, then a byte-sum checksum.** Layout (VERIFIED from `.text+0x1a4c`,
`.text+0x1bb8`, `.text+0x1c0c`):

```
+0x00   char  tag[4]        "PWRC" / "FATB" / "PARM"      <- strncmp, 4 bytes
+0x04   u32   (never read)                               <- no code touches +4
+0x08   u32   total_len     payload length = total_len - 16
+0x0c   u32   checksum      == sum of payload bytes (mod 2^32)
+0x10   u8    payload[total_len - 16]
```

Checksum, exactly (Parameter block, `.text+1bb8`..`0x1bec`; identical shape in the
other two):

```
0x1bbc  subs r12, r12, #16        ; r12 = total_len - 16 = payload length
0x1bc0  moveq r3, r12             ; payload length 0  ->  sum = 0
0x1bc8  add  r1, r10, #15
0x1bd0  ldrb r0, [r1, #0x1]!      ; pre-increment: first byte read is buf[0x10]
0x1bdc  add  r3, r3, r0           ; accumulate
0x1be4  ldr  r2, [r10, #0xc]
0x1be8  cmp  r3, r2               ; beq -> accept
```

So it is a **byte-wise running sum**, 32-bit wrapping, over `[0x10, total_len)`. That
is a *different* idiom from the `fe_bin_1` checksum (`sata-fw-load.md` §3: big-endian
dword sum, must equal the hardcoded `0x37922226`) — do not reuse one for the other.

`+0x04` is never referenced by any of the three blocks — no version field, no
sequence number, no per-record CRC. **Label: UNKNOWN/unused** (a real firmware image
may use it; the driver does not).

### 2.1 What `MTDAdvRead` adds on top of the caller's check

`MTDAdvRead` is a wear-level/journal-style reader, not a linear one. It opens the
device, `MEMGETINFO`, then walks **eraseblocks** from `start_addr`:
`MEMGETBADBLOCK` (`sata.dis` `.text+0xc78`), `pread64` **one page** into the shared
`sata_mtd_read_buf`, and `strncmp(page, tag, 4)`. Matching pages are accumulated into
the caller's buffer with `memcpy(out + bytes_copied, read_buf, min(remaining, chunk))`
(`.text+0x10ac-0x10b8`, `out` = the 5th argument at `[sp,#0xc0]`).

Geometry, derived arithmetically from the two log lines (never guessed):

| quantity | value | derivation |
|---|---|---|
| page (`writesize`) | 2048 | `.text+0xbd8..0xc24`: `aligned = round_up(len, writesize)`; log says `len 0x2020 -> Align 0x2800` and `len 0x2000 -> Align 0x2000`; `0x2020 -> 0x2800` requires `writesize = 0x800` |
| eraseblock (`erasesize`) | `0x20000` | guest `/proc/mtd`, C95 UART line 196: `mtd0: 10000000 00020000` |
| scan start | `0x00000000` | log field `Latest stored data in start_addr = 0x00000000`; `[sp,#0x58]` is never stored to anywhere in `.text+0xadc..0x1444`, so in this clone it is effectively 0 |
| failure exit | `[IDE] <%s> Can't read enough data, u4RdByteCnt = 0x%x, u4ByteCnt = 0x%x` → return `-1` | `.rodata.str1.4+0x3b0`, `.text+0x1058` → `.text+0xd44` `mvn r0,#0` |

Consequence for the fixture: writing the record at **partition offset 0, page 0** with
the tag as its first four bytes satisfies both the `MTDAdvRead` scan and the caller's
`strncmp`. No journal rotation, no sequence numbers, no bad-block games are needed.

### 2.2 Second argument of both readers is dead

`MTDRawRead(path, 16|18|32, len, dst)` and `MTDAdvRead(path, 20|30, tag, len, dst)` —
the second argument is **provably unread** in both clones (`MTDRawRead`: `sata-fw-load.md`
§2; `MTDAdvRead`: `.text+0xb30 mov r4,r1` then `r4` is reloaded from `[sp,#0x60]` at
`.text+0xbd8` with no intervening read). Do not encode meaning into 16/18/32/20/30.

### 2.3 `+0x0C014` fw-header records vs these partition records

Two unrelated tag systems, easy to conflate:

| | `fe_bin_1` fw-header records | these three partition records |
|---|---|---|
| tag strings | `POWC` `FATB` `PARM` `BOOT` `MAIN` `ENCC` | `PWRC` `FATB` `PARM` |
| location | `fw + 0xC010 + 16*i` | partition offset 0 |
| record size | 16 B `{tag, BE f0, BE f1, BE f2}` | 16 B header + payload, with byte-sum |
| checked by | the fw tag parser (`sata-fw-load.md` §4) | `xfer_int_ldr_fw` §1.1–1.3 above |

`FATB`/`PARM` appear in **both**, with different record semantics. `PWRC`/`POWC` differ
by one character.

---

## 3. Why they mismatch today

**Cause: the three partitions are empty. Not a wrong tag format.** The tag *format*
is the same 4 ASCII bytes at offset 0 — the partitions simply contain erased flash,
whose first four bytes are `0xFF FF FF FF`, which is not `PWRC`/`FATB`/`PARM`.

Byte-level proof, from the image the rig actually runs (`decode/fe_tags_probe.py`,
run on the Lab VM against `/tmp/images-fe/nand.img`, md5 `88da7e1635e122fb00483a6a20bf8401`):

```
fe_test_data   @ 0x00e00000: head=ffffffff…  distinct-bytes-in-1MiB=1
fe_parameters  @ 0x00f00000: head=ffffffff…  distinct-bytes-in-1MiB=1
fe_power_curve @ 0x01000000: head=ffffffff…  distinct-bytes-in-1MiB=1
```

`distinct-bytes-in-1MiB = 1` ⇒ each partition is a uniform fill; `head=ff…` ⇒ that
fill is `0xFF`, i.e. erased. The manifest agrees for all three:
`fe_test_data recs=0`, `fe_parameters recs=0`, `fe_power_curve recs=0`.

(The Sony **update** never ships these — they are factory-programmed. `fe_bin_1` and
`fe_bin_2` in *this* image carry `recs=1` each, which is why `CheckSum OK` passes now
and only the three partition reads fail.)

### 3.1 Two of the three printed payloads are *not* `0xFF` — and that is not flash content

`socReadFaTable` printed `shim` and `SocReadPowerCurve` printed `b6 7a 75 2c`. Neither
can be the partition content:

| pattern | occurrences in the whole 256 MiB `nand.img` |
|---|---|
| `73 68 69 6d` (`shim`) | **0** |
| `b6 7a 75 2c` | 1 — at `0x01a00000`, i.e. the first 4 bytes of `initrd_1` (coincidence in compressed data, 15 MiB away from `fe_power_curve`) |
| `ff ff ff ff` | ubiquitous |

Conclusion (**VERIFIED** for "not flash", **INFERRED** for the mechanism): on the
no-record path the caller's buffer is **never filled** — `out` is fresh `kmalloc`
memory whose contents are stale heap. `shim` is most plausibly the residue of the
guest's `/res/shim/` path string (the module is `insmod /res/shim/sata_mt85xx_mod.ko`,
C95 UART) — plausible, not proven. `SocReadParameter` printing `ff ff ff ff` is then
coincidence (a heap region that happened to be `0xFF`-filled), not proof that the
Parameter path deposited flash bytes.

Practical consequence, and the reason this matters for the fixture: **the printed
4 bytes are a diagnostic artifact, not a flash readback.** The acceptance observable
must be the *success* message, not a change in the printed tag bytes (§4.1).

---

## 4. The fixture recipe

### 4.1 Where to inject: the images, not the model

**Inject into `nand.img` (image repack). Do not touch `emulator-kit/mt8560-nfi.c`.**

Reasons, all verified:

1. The driver already resolves the *right* node for the *right* name —
   `sata_mt85xx_parse_mtd_table` prints `fe_test_data - /dev/mtd10`,
   `fe_parameters - /dev/mtd11`, `fe_power_curve - /dev/mtd12` (C95 UART 234-236) —
   and the guest's partition table offsets (`0xe00000`, `0xf00000`, `0x1000000`,
   C95 UART 98-100) match the manifest exactly. There is no addressing bug to fix in
   the model.
2. The MTD/NAND path delivers the image bytes unchanged: ECC clean
   (`ECC failed: 0, ECC corrected: 0`) and 0 bad blocks, so `MTDRawRead`/`MTDAdvRead`
   copy pages verbatim with no bad-block compaction to undo. What goes into
   `nand.img` is what `pread64` returns. (The *caller's* buffer not being filled on
   the no-record path, §3.1, is a separate post-read handoff issue — it does not
   change which bytes a successful match would see.)
3. A model-side tag injection would report flash content the image does not hold.
   That is a falsified observable and it would mask future genuine decode work.

Put the fixture in the repack step that writes `nand.img` (the
`emulator-handoff/firmware.py`-style writer), keyed on the manifest partition **names**,
and label it synthetic in the manifest/README next to the image.

### 4.2 What bytes to write

Only page 0 of each partition is read (`len` quoted below is what the driver asks
for). Everything else stays `0xFF`. Fill the payload with a labelled default — the
driver never interprets it, only the FE does.

**`fe_power_curve` @ `0x01000000` — driver reads `0x420` B from offset 0**

```
off  size  content
0x000   4   "PWRC"                        <- tag, must be PWRC not POWC
0x004   4   00 00 00 00                   <- unused by the driver
0x008   4   10 04 00 00   = 0x410         <- total_len = 16 + 0x400 payload
0x00c   4   <checksum LE> = sum(payload)
0x010 0x400 labelled default table        <- 1 KiB
0x410  0x10 00…                           <- 16 B slack (driver reads 0x420)
```
`POWC.f2 = 0x400` (1 KiB) is the size the driver copies to DRAM.

**`fe_test_data` @ `0x00e00000` — driver reads `0x2020` B from offset 0**

```
0x000   4   "FATB"
0x004   4   00 00 00 00
0x008   4   10 20 00 00   = 0x2010        <- 16 + 0x2000
0x00c   4   <checksum LE>
0x010 0x2000 labelled default FA table     <- 8 KiB, FATB.f2
0x2010  0x10 00…
```
Note: today this one already works via the `fe_bin_1 + 0xFE000` fallback. Injecting it
only removes the two `TAG mismatch` / `TAG mismatched` log lines and the
`read FA table from FW offset` line; it does not change what reaches FE DRAM unless the
payload differs from the embedded copy.

**`fe_parameters` @ `0x00f00000` — driver reads `0x2000` B from offset 0, no slack**

```
0x000   4   "PARM"
0x004   4   00 00 00 00
0x008   4   00 20 00 00   = 0x2000        <- total_len must fit the 0x2000 read
0x00c   4   <checksum LE>
0x010 0x1FF0 labelled default parameters   <- 8176 B (NOT 0x2000: this read is not padded)
```
The whole `0x2000` buffer — header included — is copied to FE DRAM at `0x15000`
(§1.3 quirk), so the header bytes are visible to the FE here.

### 4.3 Acceptance gates (use these, not the printed tag bytes)

In order, from the UART log:

| # | must appear | replaces |
|---|---|---|
| 1 | `[IDE]<xfer_int_ldr_fw> read pwr_curve len: %d OK.` (`.rodata.str1.4+0x6b0`) | `read power curve failed !!` |
| 2 | `Read FA table len: %d OK.` **without** the preceding `read FA table from FW offset = 0x%x` | fallback line |
| 3 | `[IDE]<xfer_int_ldr_fw> Read parameter len: %d OK.` (`.rodata.str1.4+0x784`) | `Read parameter failed !!` |
| 4 | no `TAG mismatch:%c%c%c%c` and no `MTDAdvRead> TAG mismatched` at all | — |
| 5 | controls unchanged: `FE firmware CheckSum OK !!`, `verify boot code -- OK`, `release frontend reset done !!` | — |

A fixture that changes only the printed 4 bytes without emitting gate 1/3 has not been
loaded — see §3.1.

---

## 5. Verdict: benign with defaults — they do **not** block the tip-to-tail goal

**Not blocking.** All three failures are log-only; the driver never branches on the
table *contents*. Control flow, cited:

```
xfer_int_ldr_fw
  .text+0x16ac  MTDRawRead(fe_power_curve)        rc!=0 -> .text+0x16d8 (kfree)
  .text+0x1a34  strncmp "PWRC"                    mismatch -> .text+0x1ca8 -> .text+0x16d8
                                                          -> .text+0x1d38 __memzero(buf) -> .text+0x16f8
  .text+0x1708  MTDAdvRead(fe_test_data)          ...  -> .text+0x174c (kfree) -> .text+0x1760 FW-image fallback
  .text+0x1ad4  MTDAdvRead(fe_parameters)         ...  -> .text+0x17e4 (kfree) -> .text+0x1d28 memset(buf,0xFF) -> .text+0x1804
  ------------- unconditional from here -------------
  .text+0x1844  memcpy(dram + BOOT.f0,  fw + BOOT.f1,  BOOT.f2)
  .text+0x1864  memcpy(dram + MAIN.f0,  fw + MAIN.f1,  MAIN.f2)   (clamped to dram_sz)
  .text+0x18a0  memcpy(dram + POWC.f0=0x10000, power_curve_buf, POWC.f2=0x400)
  .text+0x18b8  memcpy(dram + FATB.f0=0x11000, fa_table_buf,    FATB.f2=0x2000)
  .text+0x18d0  memcpy(dram + PARM.f0=0x15000, param_buf,       PARM.f2=0x2000)
  .text+0x18e8  sata_mt85xx_PreparePwrOnParm(); memcpy(dram+0x20000, .bss+0x0, 32)
  .text+0x1908  BSP_CleanDCacheRange(dram, dram_sz)
  .text+0x1938  FE DRAM wrapper + reset release -> "[IDE]release frontend reset done !!"
```

`port_start` (`.text+0x2fac`) polls only the ATA link register (`0xfd00a610`, expect
link-up `0x370000`) and the FE status register (`0x7000a01c` ∈ {0, 0x50}) — neither
reads `power_curve_buf`, `fa_table_buf` nor `param_buf`. `AACS`/`IDENTIFY` travel the
SVOIF/`xfer_fe_data` mailbox to the FE. **No host-side gate depends on these tables.**

What that means honestly:

* **For reaching `port_start` / `AACS` / `IDENTIFY` on the rig: benign.** The tables
  are shipped (zero-filled for POWC, `0xFF`-filled for PARM, FW-embedded for FATB) and
  the FE reset is released regardless. The three lines are `ide_log_en & 32` debug
  output (every print is gated on `tst r3, #32`), not error gates.
* **For faithful FE modelling: not benign.** They *are* FE inputs at DRAM
  `0x10000` / `0x11000` / `0x15000`. Real FE firmware would get a zero power curve and
  `0xFF` parameters; the SATA PHY/timing configuration the FE applies may then differ.
  Since neither of those regions is read back by the host, this cannot be detected from
  the CPU side — it can only show up as FE-side misbehaviour.
* **Priority:** the fixtures are therefore a *log-hygiene + FE-fidelity* task, not a
  blocker on the tip-to-tail path. They are cheap (one page per partition) and should
  still be done, because they are the only way to make the rig's UART honest before
  anyone reads it for a different reason.

---

## 6. Reproduce

```sh
cd evidence/bx510-guest/bdpdrv/decode
python3 sata_decode_dis.py --func sata_mt85xx_xfer_int_ldr_fw    # §1 check sites
python3 sata_decode_dis.py --func sata_mt85xx_MTDAdvRead.clone.7 # §2.1 scan + geometry
python3 sata_decode_dis.py --list                                # confirm the SocRead* names are not symbols
```

```sh
# image byte provenance (Lab VM; never mount the image Mac-side)
make vm-stage-file FILE=evidence/bx510-guest/bdpdrv/decode/fe_tags_probe.py
make vm-exec CMD='python3 /tmp/fe_tags_probe.py'
```

Inputs: `/tmp/bdpdrv/sata.dis`, `/tmp/bdpdrv/sata_mt85xx_mod.ko` (sha256 `8a0253eb…`),
`evidence/bx510-guest/bdpdrv/bdpdrv-runC93/C94/C95.uart.log`,
VM `/tmp/images-fe/{manifest.json,nand.img}` (md5 `88da7e16…`).

## 7. Open questions

1. **Why is `out` unwritten on the no-record path?** The `memcpy(out + copied, …)`
   exists (`.text+0x10ac`) and the Parameter path does surface real flash bytes
   (`0xFF`) — but `FATB` shows stale heap. Whether `MTDAdvRead` returns 0 early or the
   copy is skipped when nothing matched is not settled by static read. Needs one live
   breakpoint on `MTDAdvRead`'s return to classify. Affects only the *diagnostic*
   wording, not the fixture.
2. **`[sp,#0x58]` (the `start_addr` of the journal scan) is never stored to**
   anywhere in `.text+0xadc..0x1444`. Either the clone dropped the initialiser or my
   listing misses a store. It always reads 0 in every log, so the fixture recipe is
   unaffected, but a real journal-partition image would care.
3. **`+0x04` of the record header** is never touched by the driver. Unknown whether a
   genuine factory image carries a sequence number or version there.
4. **Is the `PWRC` spelling (vs the fw-header `POWC`) shared by other MT85xx builds?**
   One module, one observation. If a real dump ever shows `POWC` at the partition
   head, the check would fail — so the fixture must use `PWRC`, not the fw spellings.
