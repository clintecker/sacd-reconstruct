# `failed to IDENTIFY (device reports invalid type, err_mask=0x0)` — the exact check, the class-3 ladder, and the words that pass

Decode of `/tmp/bdpdrv/libata.ko` (2.6.35 ARM, unstripped) + `/tmp/bdpdrv/sata_mt85xx_mod.ko`,
cross-read against the C97 UART (`evidence/bx510-guest/bdpdrv/bdpdrv-runC97.uart.log` lines
285-299) and the model (`emulator-kit/sony-bx510.c`, read-only).

Extends `libata-probe.md` §2/§3 — that doc stopped at "the payload must arrive and the qc must
complete"; this one decodes what happens to the payload **after** it arrives and why libata
threw it away with `err_mask=0x0`.

**Address convention** as in `libata-probe.md`: section-relative (`libata .text+0x…`,
`sata .text+0x…` for `sata_mt85xx_mod.ko`). Reproduce any site with:

```
/opt/homebrew/opt/llvm/bin/llvm-objdump -d --section=.text /tmp/bdpdrv/libata.ko     # + -r for pool words
/opt/homebrew/opt/llvm/bin/llvm-objdump -d --section=.text /tmp/bdpdrv/sata_mt85xx_mod.ko
```

Literal-pool slots resolve through `R_ARM_ABS32`; for ARM `REL` relocations the addend is the
**in-place word at the slot**, which is how every string below was mapped to its branch.

---

## 0. Bottom line

1. **The check is one bit.** For a class-3 (ATAPI) device, `ata_dev_read_id` accepts the payload
   iff `(int16_t)id[0] < 0`, i.e. **`id[0] & 0x8000`** (`.text+0x3cb8 ldrsh` / `0x3cc0 bge`).
   Fail → `rc = -EINVAL`, reason string `"device reports invalid type"`
   (`.rodata.str1.4+0x39c`, pool slot `.text+0x4084`) → the C97 line, with
   `err_mask = 0` because the *read* had succeeded and nothing on the validity path sets the
   mask (`.text+0x3b98` `mov r6,r2` initialises it to 0).
2. **class=3 = `ATA_DEV_ATAPI`**, decided before `read_id` by `ata_sff_dev_classify` →
   `ata_dev_classify` from the signature `(lbam,lbah) == (0x14,0xeb)`
   (`libata .text+0x328..0x344`). It is what selects `tf.command = 0xa1`
   (`IDENTIFY PACKET DEVICE`) at `.text+0x3d6c` instead of `0xec`.
3. **`word0 = 0x8580` already passes that check** (`0x8580 & 0x8000 = 0x8000`,
   `0x8580 & 3 = 0` → 12-byte CDB). So the C97 failure is **not** caused by the current word
   values — see §5: two UART lines in the same run constrain `id[0]` to *incompatible* values,
   which is only possible if the 512 bytes in `dev->id` never were the model's table.
4. **Two real table bugs do exist** and would break the lines *after* the check:
   * the string fields are written at byte offsets 10 / 23 / 27, which are the **word** indices —
     the model string lands in words 13-23 instead of 27-46 (§3.5);
   * `w[53] = 0` invalidates words 64-70 and 88, so the xfermask collapses to `MWDMA2`, and
     `w[83] = 0` drops the LBA48 count so `ata_id_n_sectors` returns **0 sectors**.
5. Predicted C98 (payload hand-off fixed): one `prereset`/`softreset` pair, then
   `ata1.00: ATAPI: SONY    BDPSACDEMUL, 1.00, max UDMA/33`,
   `ata1.00: configured for UDMA/33`, `ata1: EH complete` (§6).

---

## 1. The check that failed (DECODED)

`ata_dev_read_id` = `libata .text+0x3b54`, size `0x568` (to `0x40bc`). After
`ata_do_dev_read_id` returns `err_mask == 0` the function runs a *validity ladder* on the payload.
Class is held in `r4` for the retry loop (`ldr r4,[sp,#0x1c]` at `.text+0x3b90`, flipped on the
ATA/ATAPI fallback at `.text+0x3c90..0x3c9c`); the payload pointer (`u16 *id`, arg 4) is `r7`
(`.text+0x3b60`). `id` base is `dev+0x58` — proven at `ata_dev_configure+0x210`
(`add r5, r6, #88` = `&dev->id[0]`, `libata .text+0x4348`) and by the `cfg 49:%04x 82:%04x …`
debug print which loads `word 49` at `dev+186` (`.text+0x5534`).

```
libata .text
3ca4:  ldr   r3,[r5,#0x8]        ; dev->horkage
3ca8:  tst   r3,#0x10000         ; ATA_HORKAGE_DUMP_ID → print_hex_dump of the 512 bytes (.text+0x3f38)
3cac:  bne   0x3f38
3cb0:  cmp   r4,#1               ; class == ATA_DEV_ATA ?
3cb4:  beq   0x3d90             ;   → ATA ladder (below)
3cb8:  ldrsh r3,[r7]             ; ★ id[0], sign-extended
3cbc:  cmp   r3,#0
3cc0:  bge   0x3dc8             ; ★ bit15 clear  → "device reports invalid type"
3cc4:  ldr   r2,[sp,#0x18]       ; tried_spinup
3cc8:  cmp   r2,#0
3ccc:  movne r3,#1
3cd0:  strne r3,[sp,#0x18]       ;   already retried once → skip the spin-up probe
3cd4:  bne   0x3cf0
3cd8:  ldrh  r3,[r7,#4]          ; id[2]
3cdc:  ldr   r1,= 0x738c
3ce0:  ldr   r2,= 0x37c8
3ce4:  cmp   r3,r2
3ce8:  cmpne r3,r1
3cec:  beq   0x3dfc             ; id[2] ∈ {0x37c8,0x738c} = powered-up-in-standby
3cf0:  cmp   r4,#1               ; (the ATA-version / LBA downgrade scan below is class-1 only)
3cf4:  movne r3,#0
3cf8:  andeq r3,r11,#1
3cfc:  cmp   r3,#0
3d00:  beq   0x3dec             ; ★ class 3 → ACCEPT
…
3dc8:  mvn   r4,#21              ; ★ rc = -EINVAL (-22)
3dcc:  ldr   r2,[pc]             ; → "device reports invalid type"  (.rodata.str1.4+0x39c)
3dd0:  b     0x3bf8
3bf8:  ldr   r3,= 0x1e44
3bfc:  ldr   r3,[r8,r3]          ; ap->msg_enable
3c00:  tst   r3,#8               ; ATA_MSG_WARN — set on this ap (the line printed)
3c04:  bne   0x4038             ; → printk( … "failed to IDENTIFY (%s, err_mask=0x%x)", reason, r6)
3dec:  ldr   r1,[sp,#0x20]       ; p_class
3df0:  str   r4,[r1]             ; *p_class = 3
3df4:  mov   r4,#0               ; rc = 0
3df8:  b     0x3c08             ; return 0
```

The err_out print itself: `.text+0x40b4` is the pool slot for `.rodata.str1.4+0x4fc`
`"%sata%u.%02u: failed to IDENTIFY (%s, err_mask=0x%x)\n"`; `%s` = `r2` (the reason pointer).

**`err_mask = 0x0` is the fingerprint of the validity path**, not of an I/O failure:
`r6` (= err_mask) is zeroed at `.text+0x3b90/0x3b98` and only ever written from
`ata_do_dev_read_id`'s return (`.text+0x3c54 mov r6,r0`) or by the `mov r6,#128`
(`AC_ERR_DEV`-class) at `.text+0x3d5c`. The invalid-type path touches neither.

### 1.1 The surrounding ladder (what else is checked, and in what order)

| # | site | test | consequence |
|---|---|---|---|
| 0 | `.text+0x3c5c` | `err_mask == 0` | else: `.text+0x3c60` `& 0x200` → `NODEV after polling detection` (`.text+0x401c`); class 7 → `IDENTIFY failed on device w/ SEMB sig, disabled` (`.text+0x3fe4`); `err_mask != 1` or tf.status has no `ATA_ERR` → `I/O error` (`.text+0x3f08`); otherwise fall back to the *other* class and retry (`.text+0x3c90`: `1↔3`) |
| 1 | `.text+0x3ca8` | `dev->horkage & 0x10000` | hexdump of the 512 bytes, then continue |
| 2 | `.text+0x3cb0` | `class == 1` | ATA ladder (2a-2c), else (2d) |
| 2a | `.text+0x3d94` | `id[0] & 0x8000` **clear** | accept (plain ATA) |
| 2b | `.text+0x3d9c..0x3dac` | `id[0] == 0x848a` or `0x844a` (pools `.text+0x4078`/`0x4074`) | accept |
| 2c | `.text+0x3db0..0x3dc4` | `(id[83] & 0xc004) == 0x4004` (CFA) | accept, else → **invalid type** |
| 2d | `.text+0x3cb8..0x3cc0` | **`(int16_t)id[0] >= 0` for any non-ATA class** | **← the C97 failure** |
| 3 | `.text+0x3cd8..0x3dfc` | `id[2] ∈ {0x37c8, 0x738c}` | `ata_dev_set_feature(dev, 7, 0)` (spin-up), `"SPINUP failed"` on error, retry |
| 4 | `.text+0x3cf0..0x3d00` | class 1 only: word-80 version scan + `id[49] & 0x200` | downgrade class to ATA / keep |
| 5 | `.text+0x3dec` | — | `*p_class = class; return 0` |

For class 3 **nothing else is examined** — no CFA, no version, no LBA. The whole ATAPI
acceptance criterion at read time is `id[0] & 0x8000` (plus "word 2 is not a spin-up magic").

---

## 2. What `class=3` means

`ata_sff_dev_classify` (`libata .text+0x12da4`) calls `ops->sff_dev_select` (slot `0x90`),
`ops->sff_tf_read` (slot `0xa4`) into a local 20-byte taskfile, then `ata_dev_classify`
(`libata .text+0x328`, the `bl` at `.text+0x12e1c`):

```
328:  ldrh r3,[r0,#14]          ; lbam | lbah<<8
32c:  cmp  r3,#0        → 1     ; ATA_DEV_ATA
338:  ldr  r2,= 0xeb14
33c:  cmp  r3,r2        → 3     ; ★ ATA_DEV_ATAPI   (lbam=0x14, lbah=0xeb)
348:  ldr  r2,= 0x9669  → 5     ; ATA_DEV_PMP
354:  ldr  r0,= 0xc33c  → 7     ; ATA_DEV_SEMB
                        else 0 ; ATA_DEV_UNKNOWN
```

That enum numbering is confirmed independently inside `ata_dev_read_id`, which dispatches on it:
`class == 3` → `tf.command = 0xa1` (`.text+0x3d6c`: `mvn r3,#94` = `0xa1`), `class ∈ {1,7}` →
`0xec` (`.text+0x3c14`: `mvn r3,#19`), `class == 7` → the SEMB message (`.text+0x3fe4`),
anything else → `"unsupported class"` + `-ENODEV` (`.text+0x3bf0`).

Who printed `class=3`: `sata_mt85xx_softreset` (`sata .text+0x4b18`) calls
`ata_sff_dev_classify(&link->device[0], 1, &err)` on its mode-1 path and prints
`"[IDE]<%s>ch:%d end, class=%d\n"` (`sata .rodata.str1.4+0x151c`, pool `sata .text+0x5108`) —
C97 lines 288/293/298. The signature it classified came from the model's read handler at
`0xa004..0xa018` (`sig = {0x01,0x14,0xeb}` → `0xeb1401` → **3**).

⇒ Libata assigned `dev->class = 3` *before* `read_id`, so `read_id` sent
`IDENTIFY PACKET DEVICE` and took the **class-3** validity branch at `.text+0x3cb8`. The
`class == 1` ladder (which accepts `0x844a`/`0x848a`/CFA) was never entered in C97.

---

## 3. The corrected word list

Two independent gates: **A** = passes `ata_dev_read_id` (§1); **B** = makes
`ata_dev_configure` print `ATAPI: <model>, <fw>, max <mode>` and reach
`ata_do_set_mode`'s `configured for <mode>`.

### 3.1 Words tested by gate A (and only these)

| word | required | instruction that tests it |
|---|---|---|
| `w[0]` bit15 | **1** | `.text+0x3cb8 ldrsh` + `0x3cc0 bge` |
| `w[2]` | ≠ `0x37c8`, ≠ `0x738c` | `.text+0x3cd8..0x3cec` (and `.text+0x3e14..0x3e20` on the spin-up retry) |
| (`w[0]` bit15 clear + `w[0] ∈ {0x844a,0x848a}` or `w[83]&0xc004==0x4004`) | irrelevant here | `.text+0x3d90` — **ATA class only**, not reached with class 3 |

`w[0] = 0x8580` satisfies gate A: bit15 = 1; `& 3 = 0`; `w[2] = 0`.

### 3.2 Words tested by gate B — `ata_dev_configure` (`libata .text+0x4138`)

Class branch: `.text+0x4408..0x4418` (`dev->class` at `dev+0x28`) → class 1 → `0x48c4`,
class 3 → `0x4b08`, else → `0x441c`.

**(B1) CDB length** — `.text+0x4b08`: `id[0] & 3` indexes a table at `.rodata+0x728`, whose
decoded words are **{12, 16, 25, 500}**; `.text+0x4e48` then requires `cdb_len - 12 <= 4`:

```
4b08:  ldrh r3,[r6,#88]   ; id[0]
4b0c:  and  r2,r3,#3
4b10:  cmp  r2,#1
4b14:  bls  0x4e3c        ; id[0]&3 ∈ {0,1} → cdb_len = table[id[0]&3] = 12 | 16
4b18:  ldr  r3,[ap+0x1e44]; tst r3,#8 → printk "%sata%u.%02u: unsupported CDB len" (.rodata.str1.4+0x9ec)
4b28:  tst  r3,#4 ; else silent
       → rc = -EINVAL     ; configure FAILS
4e48:  sub  r1,r2,#12 ; cmp r1,#4 ; bhi 0x4b18   ; 25 and 500 are rejected here
4e58:  str  r2,[r6,#0x40]                        ; dev->cdb_len = 12 | 16
```

⇒ **`id[0] & 3 ∈ {0,1}` is mandatory** (bit0 = "16-byte CDB"). `0x8580 & 3 = 0` → 12 ✓.

**(B2) ATAPI feature flags** (all *optional*, all add text to the print):

| word | test | effect |
|---|---|---|
| `w[0]` bits[6:5] | `.text+0x4ef4`: `(id[0] & 0x60) == 0x20` | `", CDB intr"` + `ATA_DFLAG_CDB_INTR` |
| `w[76]` | `.text+0x4e70`: `id[76] ∉ {0, 0xffff}` | AN block becomes eligible |
| `w[78]` bit5 | `.text+0x4e88`: `id[78] & 0x20` | AN eligible → `ata_dev_set_feature(dev, 0x10, 5)` → `", ATAPI AN"` |
| `w[62]` bit15 | `.text+0x4fb8`: `ldrsh` negative | `", DMADIR"` |

Keep `w[0]` bits[6:5] = 00, `w[76] = w[78] = 0`, `w[62] = 0`: no extra SET-FEATURES round trip and
a clean print (the parent's current table already does this).

**(B3) xfer_mask → the `max %s` and `configured for %s` strings** —
`ata_id_xfermask` is inlined into `ata_dev_configure` (`libata .text+0x468` standalone, same code):

| word | instruction | decode |
|---|---|---|
| `w[53]` bit1 | `.text+0x470 tst r3,#2` | words 64-70 valid → `pio_mask = 7 \| ((w[64] & 3) << 3)` (`.text+0x478..0x488`) |
| `w[51]` bits[15:8] | `.text+0x524..0x538` | *fallback only*: `pio_mask = (1 << (w[51]>>8)) - 1`, capped: `>4 → 1` |
| `w[63]` bits[2:0] | `.text+0x498` | `mwdma_mask = (w[63] & 7) << 7` |
| `w[53]` bit2 | `.text+0x4c0 ands r3,r3,#4` | words 88 valid → `udma_mask = (w[88] & 0xff) << 12` (`ldrbne r3,[r0,#0xb0]; lslne r3,#12`) |
| `w[83]` bits[15:14] | `.text+0x4a8..0x4bc` (xfermask) and `.text+0x4b68..0x4b7c` (configure) | `== 0x4000` → CFA path (`w[163..164]`), i.e. *avoid* `(w[83]&0xc004)==0x4004` |
| mode name | `ata_mode_string` `.text+0x9ac`: `31 - clz(mask)` indexes `.rodata+0x214`, decoded = `PIO0..PIO6, MWDMA0..MWDMA4, UDMA/16, UDMA/25, UDMA/33, UDMA/44, UDMA/66, UDMA/100, UDMA/133, UDMA7` | highest set bit wins |

With the **current** table (`w[53]=0`, `w[63]=7`, `w[88]=7`): `pio_mask = 1`, `mwdma = 0x380`,
`udma = 0` → mask `0x381` → highest bit 9 → **`max MWDMA2`**.
With `w[53] = 0x0007`, `w[64] = 0x0003`: `pio = 0x1F`, `mwdma = 0x380`, `udma = 0x7000` →
mask `0x739F` → highest bit 14 → **`UDMA/33`** (matches the driver's own
`ata1: SATA max UDMA/133` cap, which does not shrink it).

**(B4) capacity** — `ata_id_n_sectors` (`libata .text+0x37c`):

```
380:  ldrh r3,[r0,#98]      ; w[49]
384:  tst  r3,#512          ;   LBA supported?
388:  beq  0x3bc             ;   no → CHS / w[54..56] path
38c:  ldrh r1,[r0,#166]     ; w[83]
390:  and  r3,r1,#0xc000
394:  cmp  r3,#0x4000       ;   LBA48 count valid?
398:  beq  0x41c             ;   → w[100] | w[101]<<16 | w[102]<<32 | w[103]<<48
39c:  ldrh r2,[r0,#122] ; ldrh r3,[r0,#120]   ; else w[61]<<16 | w[60]
```

⇒ with `w[83] = 0` the model's `w[100..103]` are **ignored** and the drive reports
**0 sectors**. `w[83] = 0x4000` (and, belt-and-braces, `w[60]/w[61]`) is required for the
real disc size to reach `dev->n_sectors`.

**(B5) strings — byte offsets, not word indices (a real bug in the current model)**

`ata_id_string` (`libata .text+0x1454`) reads each word high-byte-first
(`lsr r2,r2,#8` → `strb` at `[r1]`, low byte at `[r1,#1]`), so sequential ASCII written at
**byte offset `2 × word`** is correct. `ata_id_c_string` (`libata .text+0x1c38`) copies
`len-1` bytes, NUL-terminates, trims trailing spaces. The calls in `ata_dev_configure`:

```
libata .text+0x43d0: ata_id_c_string(id, buf, r2=23, r3=9)   ; firmware, words 23-26 (bytes 46-53)
libata .text+0x43f0: ata_id_c_string(id, buf, r2=27, r3=41)  ; model,    words 27-46 (bytes 54-94)
libata .text+0x4f6c..0x4fa0: printk "%sata%u.%02u: ATAPI: %s, %s, max %s%s%s%s"
        args = [model][fw][ata_mode_string(mask)][", CDB intr"|""][", ATAPI AN"|""][", DMADIR"|""]
        fmt = .rodata.str1.4+0xa4c, pool slot .text+0x5120
```

`sprintf`-order proof: `[sp]=r9` (model buf at `sp+100`), `[sp+4]=r8` (fw buf at `sp+168`),
`[sp+8]=r0` (from `ata_mode_string` via `.text+0x4f64`), `[sp+0xc]=r11`, `[sp+0x10]=r5`,
`[sp+0x14]=r7` (`.text+0x4f7c..0x4f94`).

Current model writes `memcpy((uint8_t *)w + 27, "SONY    BDPSACDEMUL  ", 20)` — byte 27 is
**word 13.5**, i.e. inside the firmware/serial field. The model string libata reads
(bytes 54-93) is therefore all zeros → `ATAPI: , , max …`.

### 3.3 The word set that passes both gates

Values are the words to program (LE `u16`, `w[i]` = ATA IDENTIFY word `i`); "why" cites the
instruction in §1/§3.2.

```
w[0]   = 0x8580   bit15 ATAPI ★(.text+0x3cbc) | bits[12:8]=5 CD-ROM | bit7 removable
                  &3 == 0 → cdb_len 12 ★(.text+0x4b0c/4e44) | bits[6:5]==00 → no ", CDB intr"
w[1]   = 0x0000   (obsolete cylinders; only read on the CHS fallback at .text+0x400)
w[2]   = 0x0000   must not be 0x37c8 / 0x738c ★(.text+0x3ce4)
w[10..19] serial  bytes 20..39   ("SACDEMUL0001", space-pad to 20)   — display only
w[23..26] fw      bytes 46..53   ("1.00    ", exactly 8)             — display only
w[27..46] model   bytes 54..93   ("SONY    BDPSACDEMUL", pad to 40 with spaces/NUL)
w[49]  = 0x0A00   bit9 LBA ★(ata_id_n_sectors .text+0x384) | bit11 LBA48 (verify path .text+0x64cc)
w[53]  = 0x0007   bit0 w54-58 valid | bit1 w64-70 valid ★(.text+0x470) | bit2 w88 valid ★(.text+0x4c0)
w[60]  = sectors & 0xffff        \
w[61]  = (sectors >> 16) & 0xffff >  fallback capacity when w83 LBA48 bit is not honoured
w[62]  = 0x0000   bit15 clear → no ", DMADIR" ★(.text+0x4fb8)
w[63]  = 0x0007   MWDMA0-2 ★(.text+0x498)
w[64]  = 0x0003   advanced PIO3/PIO4 ★(.text+0x478: pio = 7 | ((w64&3)<<3))
w[76]  = 0x0000   ∉{0,0xffff} test fails → no ATAPI-AN round trip ★(.text+0x4e70)
w[78]  = 0x0000   bit5 clear → no ATAPI-AN ★(.text+0x4e88)
w[80]  = 0x001E   major version ATA-4..ATA-6 (version scan .text+0x4f1c; text only)
w[83]  = 0x4000   bits[15:14]=01 → w100-103 valid ★(ata_id_n_sectors .text+0x390)
                  and (w83 & 0xc004) == 0x4000 ≠ 0x4004 → not CFA ★(.text+0x4a8)
w[84]  = 0x4000   spec-mandated bit14 (keep)
w[85]  = 0x4000   spec-mandated bit14 (keep)
w[87]  = 0x4000   spec-mandated bit14 (keep)
w[88]  = 0x0007   UDMA0-2 → "UDMA/33" ★(.text+0x4c8/0x4dc: (w88&0xff)<<12)
w[100..103]       LBA48 sector count (effective only with w83 = 0x4000)
```

The minimum that makes libata *stop rejecting* the payload is `w[0] bit15` (+ `w[2]` not a
spin-up magic). Everything from `w[49]` down is what makes the two dmesg lines come out right
and the drive report a non-zero size.

---

## 4. Model patch spec for `bx510_sata_build_identify` (NOT applied)

`emulator-kit/sony-bx510.c`, function at line 811. Diff-style:

```diff
 static void bx510_sata_build_identify(Bx510State *s)
 {
     uint16_t *w = (uint16_t *)s->identify;
     uint64_t sectors = 0;
     memset(s->identify, 0, sizeof(s->identify));
     if (s->sata_blk) {
         sectors = blk_getlength(s->sata_blk) / 2048;
     }
-    w[0] = 0x8c00 | (0x8000);      /* ATAPI packet device, removable */
-    w[1] = 0x3c00 | 0x00c4;        /* bogus cyls; device type CD-ROM (5) */
-    w[0] = 0x8000 | 5 << 8 | 0x80; /* type 5 = CD-ROM, removable, ATAPI */
+    /* libata's class-3 payload check is id[0] bit15 only (libata .text+0x3cb8
+     * ldrsh/bge).  bits[1:0] = 0 selects the 12-byte CDB (ata_dev_configure
+     * .text+0x4b0c -> cdb-len table .rodata+0x728 = {12,16,25,500}); bits[6:5]
+     * must stay 00 to avoid ", CDB intr"; word 2 must not be a spin-up magic. */
+    w[0] = 0x8000 | 5 << 8 | 0x80; /* type 5 = CD-ROM, removable, ATAPI */
+    w[1] = 0x0000;                 /* obsolete cylinders (CHS fallback only) */
+    w[2] = 0x0000;                 /* never 0x37c8/0x738c: that asks for SPINUP */
     w[49] = 1 << 9;                /* LBA supported */
+    w[49] |= 1 << 11;              /* LBA48 (ata_do_set_mode verify .text+0x64cc) */
+    w[53] = 0x0007;                /* words 54-58 / 64-70 / 88 valid */
     w[52] = 0x0007;                /* ATA-1..ATA-3 obsolete bits */
     w[63] = 7;                     /* PIO modes 3/4 supported */
+    w[64] = 0x0003;                /* advanced PIO3/PIO4 (pio = 7 | ((w64&3)<<3)) */
     w[80] = 0x1e;                  /* ATA-4..ATA-6 */
     w[84] = 0x4000; w[85] = 0x4000;
     w[87] = 0x4000;                /* DMA setup */
     w[88] = 0x0007;                /* UDMA modes */
+    w[83] = 0x4000;                /* LBA48 count valid: without it
+                                    * ata_id_n_sectors returns w[60]|w[61]<<16 = 0 */
+    w[60] = (uint16_t)sectors;
+    w[61] = (uint16_t)(sectors >> 16);
     w[100] = (uint16_t)sectors;
     w[101] = (uint16_t)(sectors >> 16);
     w[102] = (uint16_t)(sectors >> 32);
     w[103] = (uint16_t)(sectors >> 48);
-    memcpy((uint8_t *)w + 27, "SONY    BDPSACDEMUL  ", 20); /* model, BE */
-    memcpy((uint8_t *)w + 23, "1.00", 8);
-    memcpy((uint8_t *)w + 10, "SACDEMUL0001  ", 20);        /* serial */
+    /* ata_id_string (libata .text+0x1454) takes the HIGH byte of each word
+     * first, so sequential ASCII at byte offset 2*word is the ATA byte order.
+     * The old +10/+23/+27 were the WORD indices used as byte offsets: the
+     * model string landed in words 13-23 and libata read words 27-46 as NULs. */
+    memcpy((uint8_t *)w + 54, "SONY    BDPSACDEMUL  ", 20); /* model, words 27-46 */
+    memcpy((uint8_t *)w + 46, "1.00    ", 8);               /* fw,    words 23-26 */
+    memcpy((uint8_t *)w + 20, "SACDEMUL0001  ", 20);        /* serial, words 10-19 */
 }
```

(`w[0]`'s first dead assignment is dropped; nothing else in the function changes.)

Two notes for whoever applies it:

* `w[88] = 7` **only matters with `w[53] & 4`** — without `w[53]` the predicted line is
  `max MWDMA2`, not `max UDMA/33`.
* `w[83] = 0x4000` is the difference between a 0-sector disc and an 8.5 GB one;
  keep `(w[83] & 0xc004) != 0x4004` or libata takes the CFA branch
  (`libata .text+0x4a8`, and the same test in `read_id` at `.text+0x3db4`).

---

## 5. Why C97 failed anyway — the two lines contradict each other

Gate A says the model's `w[0] = 0x8580` **passes** (bit15 = 1). So the observed failure needs an
explanation, and the C97 log supplies it:

| C97 line | message | what it proves about `id[0]` |
|---|---|---|
| 289 | `failed to IDENTIFY (device reports invalid type, err_mask=0x0)` | reachable only via `.text+0x3cb8`/`0x3cc0` with class 3 (line 288 printed `class=3`) ⇒ **`id[0] & 0x8000 == 0`** |
| 294 | `ata1.00: unsupported CDB len` | printed only from `ata_dev_configure`'s class-3 branch (`.text+0x4b18`, entered only from `.text+0x4418` where `dev->class == 3`), and only when `id[0] & 3 ∈ {2,3}` (`.text+0x4b0c..0x4b14`, table `.rodata+0x728` = {12,16,25,500}, gate `.text+0x4e48`) ⇒ read_id had **succeeded** (so **`id[0] & 0x8000 == 1`**) and **`id[0] & 3 ∈ {2,3}`** |

`0x8580` satisfies neither constraint (bit15 = 1, `&3 = 0`) and the two constraints cannot both
hold for one value. **Conclusion (DECODED constraints, one inference): the 512 bytes that
reached `dev->id` in C97 were not the model's IDENTIFY block — they were stale/uninitialised
bytes, and they differed between EH cycles.**

The rest of the chain is decoded too, and it pins the defect to the payload hand-off rather than
to the table:

1. `err_mask = 0x0` **and** no `qc timeout` ⇒ the HSM's first poll saw `DRQ`. Had it seen
   `BSY=0, DRQ=0, ERR=0` in `HSM_ST_FIRST`, `ata_sff_hsm_move` would have set
   `qc->err_mask |= 2` and printed `ST_FIRST: !(DRQ|ERR|DF)`
   (`libata .text+0x139e4..0x139f8`, `.rodata.str1.4+0x2b9c`) — neither appears.
2. ⇒ the `HSM_ST` branch ran `ata_pio_sectors` → `ops->sff_data_xfer` (`[ops+0xac]`,
   `.text+0x135c0`), i.e. **`sata_mt85xx_data_xfer` executed and returned 512**.
3. `sata_mt85xx_data_xfer`'s READ path does
   `memcpy(libata_buf, priv+0x4c + priv+0x58, buflen)` (`sata .text+0x554c..0x5560`), i.e.
   libata's 512 bytes come from the **driver's bounce buffer**, never from the FE window
   directly. So whatever the bounce buffer holds is what libata validates.
4. The bounce buffer is filled only by the FE type-0x10 branch of
   `_sata_mt85xx_svoif_interrupt_handler` (`sata .text+0x47ac..0x4884`):

```
47ac:  cmp   r3,#16            ; message type 0x10
47b8:  ldr   r3,[sp,#0x40]     ; w2 = length
47bc:  ldr   r12,[r4,#0x54]    ; priv+0x54 = remaining bytes
47c8:  ldr   r1,[sp,#0x3c]     ; w1 = DRAM offset
47cc:  cmp   r12,r3
47d0:  movlo r10,r12           ; copy_len = min(priv+0x54, w2)   ← 0 if priv+0x54 == 0
47dc:  add   r6,r6,r1          ; src = svoif_int_ldr_dram + w1
47d8:  cmp   r2,#1  → 0x4850   ; priv+0x48 == 1: memcpy(priv+0x4c, src, copy_len)  (.text+0x4878)
47e4:  cmp   r2,#2  → 0x48a4   ; priv+0x48 == 2: write direction
47ec:  else                    ; → dropped
```

   A store scan over the whole module finds `priv+0x4c` / `priv+0x54` written **only** in
   `sata_mt85xx_data_xfer` itself (`0x5528`/`0x552c`), `sata_mt85xx_qc_issu_task`
   (`0x6cdc`, `0x6f04`, `0x72fc` — the driver's own issu-task thread, referenced only from
   `.init.text+0xd6c`), and `sata_mt85xx_cache_check` (`0x6b30`). `sata_mt85xx_qc_prep`
   (`.text+0x2ed4`) arms only `priv+0x38` (protocol) and `priv+0x48` (direction: 0 for
   `ATA_PROT_NODATA`/`ATAPI`, else 1 = read / 2 = write).

So the payload is copied **only if the message is drained while `priv+0x48 ∈ {1,2}` and
`priv+0x54 != 0`**. If `priv+0x54` is still 0 when the type-0x10 message is consumed, the copy
length is 0, the payload is silently dropped, and step (3) later hands libata 512 bytes of stale
bounce-buffer content with `err_mask = 0` — exactly the C97 signature.

**Ranked hypotheses for C98 (parent's call, none applied here):**

* **H1 (ordering).** Post the **type-0 completion first, then the type-0x10 payload** (the
  fallback already written in `sony-bx510.c`'s own comment and in `fe-ata-cmd.md` §6 row 2).
  If `priv+0x54` is armed by the driver's data-phase entry, payload-after-completion lands in
  the armed window; payload-before-completion (today's order) is dropped with length 0.
* **H2 (arming).** If H1 does not move it, the driver's `qc_issu_task` thread is the only armer
  of `priv+0x4c`/`priv+0x54`; check (with `ide_log_en` bit3 set) whether
  `[IDE]<sata_mt85xx_data_xfer>ch:0, rw:0, buf:…, buflen:0x200`
  (`sata .rodata.str1.4+0x1604`, gate at `sata .text+0x545c`) appears **before** the message is
  drained. Order in the UART is the discriminator.
* **H3 (content).** Only after H1/H2 pass does the word set in §3.3 matter.

**Cheapest decisive diagnostic:** the `read_id` hexdump path. Set
`dev->horkage |= 0x10000` (`ATA_HORKAGE_DUMP_ID`) before the read — then
`.text+0x3ca8`/`.text+0x3f38` prints `dumping IDENTIFY data, class=%d may_fallback=%d
tried_spinup=%d` (`libata .rodata.str1.4+0x4a8`) followed by `print_hex_dump` of all 512 bytes
(`.text+0x3f90`). One line of dmesg then answers "did the model's table arrive, byte for byte".
(Nothing in the model sets horkage today; the blacklist table in `libata.ko` has no `SONY` entry,
so this needs either a blacklist patch or a byte patch of the test at `.text+0x3ca8` in a
scratch `libata.ko`.)

---

## 6. Predicted C98 UART (payload hand-off fixed, §3.3 table in place)

```
[IDE]<sata_mt85xx_prereset>ch:0, deadline:0x… start
[IDE]<sata_mt85xx_prereset>ch:0 end
[IDE]<sata_mt85xx_softreset>ch:0 start
[IDE]<sata_mt85xx_softreset>ch:0 end, class=3
ata1.00: ATAPI: SONY    BDPSACDEMUL, 1.00, max UDMA/33
ata1.00: configured for UDMA/33
ata1: EH complete
```

and **absent**: `failed to IDENTIFY (…)`, `unsupported CDB len`, `link is slow to respond`,
`device not ready (errno=-16)`, `SRST failed`, `reset failed, giving up`, the second
`prereset`/`softreset` pair.

Line-by-line basis:

* `ATAPI: …` — `libata .text+0xa4c` fmt (pool `.text+0x5120`), gated by
  `(ehc->i.flags & 0x40000 /*ATA_EHI_PRINTINFO*/) && (ap->msg_enable & 1 /*ATA_MSG_DRV*/)`
  (`.text+0x43e4`, `.text+0x4f48..0x4f60`). `msg_enable` has bit0 set on this ap (the
  `class=%d` prints prove bit0-class gating works). **If `ATA_EHI_PRINTINFO` is not set in the
  probe round, this line is legitimately absent** — `configured for` + `EH complete` still
  means pass.
* `<model>` = words 27-46 trimmed → `SONY    BDPSACDEMUL` (internal spaces preserved; trailing
  pads trimmed by `ata_id_c_string`). `<fw>` = words 23-26 → `1.00`.
* `max UDMA/33` — mask `0x739F` = pio `0x1F` | mwdma `0x380` | udma `0x7000`, highest bit 14,
  `ata_mode_string` table `.rodata+0x214` → index 14 = `UDMA/33`.
* `configured for UDMA/33` — `ata_do_set_mode` (`libata .text+0x5eec`) print at `.text+0x6538`
  (`%sata%u.%02u: configured for %s%s`, pool `.text+0x67c0`); second `%s` is
  `" (device error ignored)"` only when the mode-set verification failed (`.text+0x650c`).
* Expect extra mailbox traffic after configure: `SET FEATURES 0xef` (xfer mode) qcs; the model's
  generic type-0 reply covers them, but the PIO/UDMA SET-FEATURES verification reads
  `id[49] & 0x800` (`.text+0x64cc`) and `id[83]` (`w[83]=0x4000` makes that a no-op) — a wrong
  value there appends `" (device error ignored)"`, it does not fail the probe.

---

## 7. Certainty ledger

**DECODED (instruction level):** the invalid-type site and its `id[0]` bit-15 test (§1); the
whole class-3 ladder and the ATA/CFA/SEMB alternatives (§1.1); `err_mask = 0` on that path;
`ata_dev_classify`'s 0/0xeb14/0x9669/0xc33c → 1/3/5/7 mapping and the `class==3 → 0xa1`
dispatch (§2); the cdb-len table and its `{12,16}`-only gate; the xfermask arithmetic
(w53/w63/w64/w88/w51/w83) and the mode-name table; `ata_id_n_sectors`'s w49/w83/w100-103/
w60-61 selection; `ata_id_string`'s high-byte-first copy and the (23,9)/(27,41) calls; the
`"unsupported CDB len"` reachability set; `HSM_ST_FIRST`'s `err_mask |= 2` on a DRQ-less poll;
`sata_mt85xx_data_xfer`'s memcpy from `priv+0x4c`; the interrupt handler's
`min(priv+0x54, w2)` copy length and its `priv+0x48 ∈ {1,2}` gate; every writer of
`priv+0x4c`/`priv+0x54` in the module.

**INFERRED (labelled where used):** libata's `ATA_MSG_*` bit names (DRV=1/WARN=8/CTL=4 —
consistent with which lines printed); `ATA_EHI_PRINTINFO = 0x40000`; `dev->horkage`,
`priv+0xNN` field *names*; that the C97 `id[0]` bytes were stale rather than mis-delivered in a
structured way (the two constraints prove "not the model's table", not *why*); H1 > H2 > H3
ordering of fixes.

**Open, not resolvable statically:** whether `priv+0x54` is armed before or after the FE reply is
drained in the libata PIO path (the issu-task thread is invoked indirectly through
`.init.text+0xd6c`, so static call-graph reasoning stops there). That single ordering question
decides H1 vs H2 — and C98 answers it from the UART line order.
