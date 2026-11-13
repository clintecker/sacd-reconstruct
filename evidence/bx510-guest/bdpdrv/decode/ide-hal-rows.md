# P5 transport leg — the two a-window model rows, decoded and landed

**Scope.** Turn `decode/ide-cli-lane.md` §4.5's two *falsifiable* model rows into a
verified a-window implementation: (1) the ATA signature block the IDE-HAL reads,
(2) the `0xa220` command-completion bit the IDE-HAL waits on. Ends with the
conflict question answered (who reads what in the taskfile block), a
reset/init-path sanity check of both rows, and the corrections this decode
forces on the P5 verdict matrix.

**Method.** Deterministic decoders only, no binutils on the Mac needed beyond
`llvm-objdump`: `/tmp/bdpdrv/bdpdrv.ko` (IDE HAL), `/tmp/bdpdrv/sata_mt85xx_mod.ko`
(libata-side driver), `/tmp/bdpdrv/libata.ko` (stock 2.6.35 libata) — function-scoped
disassembly with `-r` so every literal-pool slot resolves to its section or symbol.
**DECODED** = an instruction or a reloc fixes it; **INFERRED** = consistent with
every instruction seen, with the settling experiment named. No claim here comes
from reading a hexdump.

**Deliverable.** `evidence/bx510-guest/bdpdrv/decode/ide-hal-rows.patch`
(2 hunks, 51+/16−), applied to `emulator-kit/sony-bx510.c` and rebuilt on the
lab VM (§6).

---

## 0. TL;DR

1. **The taskfile block holds ONE post-reset signature, not two.** At
   `a+0x00c…a+0x018` the window serves the SATA D2H signature word
   `0xEB140101` — `nsect/lbal/lbam/lbah = 01/01/14/eb`. libata and the IDE HAL
   are **two readers of disjoint slices of that block**, one word apart, and each
   one's own arithmetic lands on its own constant: libata recomposes
   `lbah<<16|lbam<<8|lbal = 0x00eb1401` (and classifies on
   `(lbam|lbah<<8) == 0xeb14`), the HAL composes
   `+014<<16|+010<<8|+00c = lbam<<16|lbal<<8|nsect = 0x140101`.
2. **The old model served only `i>=3` (`+0x010…+0x018`)**, so `a+0x00c` read 0 and
   the HAL would have printed `Signature:0x140100`. The fix is to serve the whole
   block: `sig[4] = {01,01,14,eb}`, guard `i >= 2`. **Predicted P5 observable:
   `Signature:0x140101`** (not `0xeb1401` — see §1.4) **with the `0xa1` ATAPI
   branch taken**.
3. **`0xa220` completion must latch bit5 as well as bit0.** The HAL's
   `i4IdeHalWaitEvt` finishes a `flags&3 == 1` command on `status & 0x20`
   (DECODED, `0x9e300`), the libata/FE consumers test bit0 and/or bit4, nothing
   anywhere tests bit5 for another meaning, and every reader acks by writing back
   the whole word it accumulated — so both bits are W1C-clearable by all three
   readers and the extra bit is invisible to the others.
4. **No consumer ever wants `0x00eb1401` from the HAL.** `i4IdeHalTestIdDev`
   branches only on `sig == 1` (`0xa0808`/`0xa0844`: eq → `0xa1` ATAPI, ne →
   `0xec`). The decode's `Signature:0xeb1401` expectation was an inference that
   contradicts the SATA signature convention libata itself requires (§1.4).
5. Three side-findings that change what a green P5 will look like: the `a+0x038`
   poll is a *single-shot* classify on `a+0x01c` (it passes — but `a+0x01c` is a
   real gate, §5.1); the unbounded `a+0x6b8` spin is **not** on this probe's path
   (gated on transfer type `== 2`, §5.2); and the IDENTIFY payload never arrives
   because the HAL's data phase is DMA through `a+0x24c`, which the model does not
   implement (§5.3) — so `ModelName:` is a *later* row, not this one.

---

## 1. Row 1 — the signature block

### 1.1 What the HAL actually reads — DECODED verbatim

`i4IdeHalGetSignature` (bdpdrv `.text+0x9a384`, 0xec B), success path
`0x9a410…0x9a438`:

```
9a410: ldr r3,[pool 0x9a468]      ; = 0xfd00a014
9a414: ldr r2,[pool 0x9a46c]      ; = 0xfd00a00c
9a418: ldr r1,[r6,r3]             ; 32-bit word at a+0x014 (+0x100*ch)
9a41c: sub r3,r3,#4               ; 0xfd00a010
9a420: ldr r3,[r6,r3]             ; 32-bit word at a+0x010
9a424: and r1,r1,#255             ; byte0 of +0x014
9a428: lsl r3,r3,#24
9a42c: ldr r2,[r6,r2]             ; 32-bit word at a+0x00c
9a430: lsr r3,r3,#16              ; byte0 of +0x010 << 8
9a434: add r3,r3,r1,lsl #16       ; byte0 of +0x014 << 16
9a438: uxtab r3,r3,r2             ; += (u8)word@+0x00c
```

So **`sig24 = (u8@a+014)<<16 | (u8@a+010)<<8 | (u8@a+00c)`**, all three reads
**32-bit `ldr`** — note this kills any idea of discriminating the two consumers
by access size; both use whole-word reads and slice bytes themselves.

Taskfile map for the same window, from `vIdeHalSendCmd` (`.text+0x9b4d4`, pool
`0x9b6dc…0x9b6f4`), which writes 32-bit words in this order:
`+018` device, `+004` feature, `+008` nsect, `+00c` lbal, `+010` lbam, `+014`
lbah, `+01c` command — each followed by four dummy readbacks (no compares; the
"readback" is a write-post barrier, so a read-back never gates on a value).

### 1.2 Who needs what, from which word

| consumer | words it reads | its arithmetic | needs the values |
|---|---|---|---|
| libata `port_start` (sata_mt85xx `.text+0x316c`) | lbal/lbam/lbah = `i=3,4,5` → `+010/+014/+018` | `lbah<<16\|lbam<<8\|lbal`, compared to `0x00eb1401` (`.text+0x32e0`) | `01 14 eb` |
| libata `ata_dev_classify` (libata.ko `.text+0x328`) | the 16-bit pair `[tf+14]` = lbam,lbah → `+014/+018` | `(lbam\|lbah<<8) == 0xeb14` → `ATA_DEV_ATAPI (3)` | `14 eb` |
| IDE HAL `i4IdeHalGetSignature` | `+014/+010/+00c` | `+014<<16\|+010<<8\|+00c` | `01 14 eb` at `+00c/+010/+014` |

The libata placement is not an assumption — run **C101** printed
`[IDE]<sata_mt85xx_softreset>ch:0 end, class=3` and `ata1.00: ATAPI: SONY
BDPSACDEMUL` while the model served `0x01/0x14/0xeb` at `i=3,4,5`. `class=3` is
`ATA_DEV_ATAPI`, reachable only through `ata_dev_classify`'s `0xeb14` compare on
the lbam/lbah pair, so **libata's `lbam` word is `a+0x014` and its `lbah` word is
`a+0x018` in the guest.** (The ioaddr values are set outside the driver, per
`ata-probe-path.md` §2.2; the run, not the source, is what pins them.)

### 1.3 The resolution — one block, disjoint slices

Composing §1.2 gives exactly one consistent window:

```
a+0x00c nsect = 0x01   a+0x010 lbal = 0x01   a+0x014 lbam = 0x14   a+0x018 lbah = 0xeb
        -> 32-bit word at a+0x00c = 0xEB140101  (the SATA D2H ATAPI signature)
```

* libata's slice (`+010…+018`) recomposes `0x00eb1401` ✔ and classifies `0xeb14` ✔
* the HAL's slice (`+00c…+014`) recomposes `0x140101` ✔ and takes the ATAPI branch ✔
* nothing overlaps, nothing has to be discriminated, no driver has to be detected,
  and the two consumers cannot fight: they read different words of one value.

### 1.4 Why the decode's `0xeb1401` target was wrong — INFERRED, and why it matters

`ide-cli-lane.md` §4.5 assumed a real ODD leaves `0x01/0x14/0xeb` at
`+00c/+010/+014` ("LBA low 0x01, mid 0x14, high 0xeb"), i.e. the **PATA** ATAPI
convention with `lbal = 0x14`. That cannot coexist with libata's requirement:
libata's `lbam` word is `+014` and must hold `0x14` (§1.2, C101-proven), so the
hardware cannot also hold `0xeb` there. The self-consistent reading is the
**SATA D2H signature** `0xEB140101` (`lbal = 0x01`, `lbam = 0x14`,
`lbah = 0xeb`) — the convention `ata_dev_classify` and `port_start` both encode.

The HAL never needs `0xeb1401` anyway: `i4IdeHalTestIdDev` (`0xa07e8`) takes its
command from `cmp r1,#0` on the `sig == 1` boolean its caller passes
(`0xa0808` → `0xa0844`/`0xa0848`: eq → `0xa1` IDENTIFY PACKET, ne → `0xec`
IDENTIFY DEVICE). Any signature other than `1` selects ATAPI; the 24-bit value is
printed, not gated. **Second writer decision, recorded:** build the model to
match hardware (one block), not to match a printed constant.

### 1.5 The change

```c
-        if (i >= 3 && s->tf[i] == 0) {
-            static const uint8_t sig[3] = { 0x01, 0x14, 0xeb };
-            return sig[i - 3];
+        if (i >= 2 && s->tf[i] == 0) {
+            static const uint8_t sig[4] = { 0x01, 0x01, 0x14, 0xeb };
+            return sig[i - 2];
         }
```

The `tf[i] == 0` guard is kept: once `tf_load`/`vIdeHalSendCmd` writes a real
taskfile the stored byte wins, so taskfile readbacks (and the FE path's raw
command words `0xfe`@`+00c`, `0xff`@`+010` from `trig_fe_boot` `0x2548`/`0x2568`)
are untouched.

---

## 2. Row 2 — `0xa220` completion on bit 5

### 2.1 The HAL's wait condition — DECODED

`i4IdeHalWaitEvt` (`.text+0x9e188`), polling branch (no IDE ISR in this build:
`vIdeHalIsrInit` has zero references):

```
9e26c: bl _u4IdeHalHwIntStatus     ; r1 = per-flags mask
9e278: str r0,[sp,#0x44]           ; st = accumulated status
9e2d0: and r2,st,#0x0260000e       ; error set -> return -7 (0x9e908)
9e2ac: tst st,#0x20000000          ; bit29 = special
9e2e0: tst st,#0x7300 ; bne accept  ; ERR/DF-class bits also end the wait
9e2f8: cmp r6,#1                    ; r6 = flags & 3
9e300: tst st,#0x20 ; beq loop      ; <== BIT 5 completes a flags&3==1 command
```

with per-flags masks (pool `0x9e940/0x9e944/0x9e948`):
`flags&3==2 → 0x62717316`, `==1 → 0x6271732a`, else `0x62717302`, `|= 1` when the
`needIntrq` argument is non-zero. Bit5 is inside the `0x2a` mask (`0x2a & 0x20`)
and bit0 only enters when `needIntrq` is set — i.e. **bit0 alone can never end
the wait**, which is exactly why today's probe times out.

### 2.2 The HAL acks by writing back what it read — DECODED

`_u4IdeHalHwIntStatus` (`.text+0x9dc00`), pool `0x9dcc8 = 0xfd00a220`:

```
9dc3c: ldr r12,[r3,r2]   ; read a+0x220 + 0x100*ch
9dc40: str r12,[r3,r2]   ; write the SAME word back  -> W1C of everything read
9dc44: ldr ... (x3)      ; settle reads
9dc60: orr r0,r12,r0     ; accumulate into .bss+0x16e70[ch]
9dcb8: and r0,r0,r5      ; return accumulated & mask
```

So the ack is unconditional and unmasked: **whatever the model raises is
cleared by the HAL's own first poll.** No separate clear path is needed, and a
bit5 that is raised once cannot become sticky across commands. `i4IdeHalFlushEvt`
(`.text+0x9ea14…0x9ea34`) is the same shape with mask `0xffffffff` and drains
until it reads zero — a belt-and-braces second ack at command start.

### 2.3 Every other `0xa220` reader — grep-verified, bit5 is free

| reader | test | ack |
|---|---|---|
| `sata_mt85xx_xfer_fe_data` `.text+0x2240` | `tst r10,#16` (bit4) | `str r10,[r5]` at `0x2244` |
| `sata_mt85xx_trig_fe_boot` `.text+0x25d4` | `and r3,r4,#17` → bits 0\|4 | `str r4,[r10]` at `0x25dc` |
| `bdpdrv _u4IdeHalHwIntStatus` | bit29 special; returns `accum & mask` | whole word |
| `bdpdrv i4IdeHalFlushEvt` | drain to zero | whole word |

The remaining `tst r3,#32` sites in the mt85xx module (`0x2348`, `0x2378`,
`0x23a0`, `0x25ec`, `0x2604`, `0x2690`) all load pool `0x242c`/`0x2718` =
**`ide_log_en`**, a logging flag — not `a+0x220`. libata.ko performs no MMIO of
its own. So bit5 has no competing meaning anywhere in the guest.

### 2.4 The change

```c
-        s->sata_ist |= 0x1u;
+        s->sata_ist |= 0x1u | 0x20u;
```

Bit0 is left in place: the `0x11`/`16`-style tests above are unchanged by an
extra bit, and the proven C9x behaviour (bit0 + `pending2` bit21 → virq 53) is
not touched.

---

## 3. The conflict question, answered

`ide-cli-lane.md` §7.5 left this open by design. Recorded answer:

| consumer | taskfile offsets it reads | when |
|---|---|---|
| IDE HAL (`i4IdeHalGetSignature`) | `+00c/+010/+014` (byte-slices of three words) | P5 and every HAL ATA command |
| libata probe (`port_start`, `ata_dev_classify`) | `+010/+014/+018` | **boot-time probe only** (C101) |
| FE/mailbox command path (`xfer_fe_data`, `trig_fe_boot`) | writes `+00c/+010/+014` (raw command words `fe`/`ff`), reads `a+220` bits 0\|4, `a+038`, `a+01c` | FE boot / FE IDENTIFY |
| HAL data path after issue | nothing (`vIdeHalSendCmd`'s readbacks are barriers, §1.1) | — |

They do not fight because the signature is **one 32-bit value** at `+00c` and
the two drivers read **disjoint byte slices** of it (§1.3). The only ordering
hazard is the FE path's residue: `trig_fe_boot` leaves `0xfe`/`0xff` in
`+00c`/`+010`, and the `tf[i]==0` guard correctly suppresses serving the
signature over a loaded taskfile. In a boot where the FE path already ran,
P5 therefore reads `tf[2] = 0xfe` … — **INFERRED consequence, named as a
residual risk (§7.1)**, because the model keeps one taskfile mirror for both
drivers. P5 is documented to run last in a boot (`ide-cli-lane.md` §7.3), so the
disc path can still be probed before it.

---

## 4. Sanity check against the reset / init paths

1. **`sata_ist` reset**: `bx510_reset` zeroes `sata_ist`/`sata_im`; no new state
   was added by these two rows, so the reset contract is unchanged.
2. **W1C direction**: model `sata_ist &= ~val` (write) / `return sata_ist` (read)
   matches every consumer's read-then-write-back ack (§2.2) — including the
   HAL's, whose write-back is of the *whole* word, so bit0 and bit5 clear
   together on the first poll after the command.
3. **`i4IdeHalInit` is skipped on a re-probe** (`_fgSataHwInit`), and no arm state
   exists in this design, so a second `initial` in one boot behaves identically.
4. **libata probe unchanged by construction**: neither libata composition reads
   `+00c`, so the new byte cannot alter `class=3` or the `0x00eb1401` compare.
5. **SRST path unchanged**: a `<0x10` write with bit2 still clears `tf` and sets
   `sata_st = 0x50`, so the post-reset signature reappears on a soft reset.
6. **Row 2 does not raise an IRQ by itself**: `pending2 |= BX_SATA_IRQ` is
   unchanged; bit5 rides on the same command-complete event.

---

## 5. Corrections this decode forces on the P5 verdict matrix

### 5.1 `a+0x038` is a silent pass — but `a+0x01c` is a real gate

`i4IdeHalPollingStReg` (`.text+0x9af94`): the `a+0x038` spin exits at once for
`st == 0` (`(st & mask) == 0 && (st & 0x7f) != 0x7f` → `0x9b030` → `0x9b098` →
timer not expired → `0x9b0fc`), which **is** the single-shot classify path, so
`ide-cli-lane.md` §4.3's "absent → poll passes instantly" is right about
`a+0x038`. What it missed is the classify that follows (`0x9b10c…0x9b130`):
`a+0x01c` is read and

```
if (a+01c & mask) -> return -5        ; mask here is 0x88 (bit7 BSY | bit3 DRQ)
else if (a+01c & 1) -> return -4     ; ERR
else return 0
```

The model serves `sata_st = 0x58` (DRDY|DRQ) after a command, so the post-wait
poll returns **−5**, not 0. Predicted line:
`[i4IdeHalSAtaReg(0)](ERR)Ret:-5, ST:0x58` (`0x9ccdc` → `0x9cd24`, format at
`0x9ce38`). See §7.2.

### 5.2 The `a+0x6b8` wedge is not on P5's path — DECODED anchor

`i4IdeHalSAtaReg` enters the unbounded `a+0x6b8 == 0x200000` spin only after
`0x9cbb8: cmp r8,#2 / bne 0x9cc10`, where `r8` is the **transfer-type** argument
(`i4IdeHalAtaCmd`'s 4th arg). `i4IdeHalTestIdDev` passes `0` or `0x10` there
(`0xa07fc`: `ands r3,r0,#1` → `0`/`0x10`), so the IDENTIFY probe never reaches
the spin. `ide-cli-lane.md` §7.1's conclusion stands, now with the anchor.

### 5.3 No data phase on this probe — the payload is DMA via `a+0x24c`

`i4IdeHalSAtaReg` (`.text+0x9ca10…0x9ce48`) contains exactly two MMIO literals:
`0xfd00a6b8` (the spin above) and `0xfd00a24c` (the DMA address register). There
is **no `a+0x000`/`a+0x25c` PIO read anywhere on the `flags&3 == 1` path**, so the
512-byte IDENTIFY payload can only arrive through DMA, which the model does not
implement. Consequence: `ModelName:` / `Support UDMA Mode:` are a *later* row
(§7.2), not part of this change — and their absence is **not** evidence against
row 2.

### 5.4 P5's expected trace after this change

```
[i4IdeHalTestInit]Signature:0x140101          <- row 1 (was 0x140100)
[i4IdeHalSAtaReg(0)](ERR)Ret:-5, ST:0x58      <- row 2 completed; §5.1 is the next row
[i4IdeHalTestInit]CH:0, SataDev:1, UseQueue:0 Done!
```
guest side: `SATA WR a+01c sz4 = 0xa1` present, `SATA RD a+220 sz4` present (the
wait's polls), **no** `SATA RD a+000`, and no `TIMEOUT !!`.

Verdict-matrix rows to use (replacing §6's table in `ide-cli-lane.md`):

| observation | conclusion |
|---|---|
| `Signature:0x140101` | one D2H signature block; both consumers consistent (expected) |
| `Signature:0x140100` | `a+0x00c` (nsect) not served — this patch did not take |
| `Signature:0xeb1401` | the window really is shifted one word earlier than libata needs — **and libata's `class=3` would have to be re-explained** |
| `TIMEOUT !!` / `CmdWaitEvtRet:` and no `(ERR)Ret:` | bit5 did not latch (row 2 did not take) |
| `(ERR)Ret:-5, ST:0x58` | rows 1+2 landed; the post-wait status poll is the next row |
| `ModelName:` present | a data phase exists after all — §5.3 is wrong, say so |

---

## 6. Patch, application, rebuild

| item | value |
|---|---|
| patch | `evidence/bx510-guest/bdpdrv/decode/ide-hal-rows.patch` (2 hunks) |
| applies to | `git apply --check` green against the working tree **and** `HEAD:emulator-kit/sony-bx510.c` |
| applied | `emulator-kit/sony-bx510.c` working tree, md5 `3888f852fb1771596752ffa2636eca77` |
| rebuilt | VM `~/bx510-emu/emulator/work/build/qemu-system-arm`, md5 of the build-tree source `3888f852…`, object+binary timestamp `2026-11-13 05:18:04Z`, `sony-bx510` present in `-machine help` |
| row differential | standalone C harness replaying both patched arms: D2H word `0xeb140101`, libata `0xeb1401`/`0xeb14`, HAL `0x140101` (and `!= 1`), taskfile readback wins, `a+220 = 0x21` then W1C → 0, `0x11`-test sees only bit0 |

---

## 7. Residual rows — decoded, NOT part of this change

1. **One taskfile mirror, two writers.** The FE path leaves `0xfe`/`0xff` in
   `+00c`/`+010`; a HAL probe in the same boot then reads that residue instead of
   the signature (the `tf[i]==0` guard suppresses the serve). Settling
   experiment: `drv.ide.pri_ver.initial 0 s 0` **after** a full disc boot and read
   the `Signature:` line — `0x140101` means the residue was not there, anything
   else means a per-driver taskfile mirror is the next model row.
2. **`a+0x01c` status at the post-wait poll** (§5.1): needs `0x50` (not `0x58`),
   or a modelled DRQ drain, for the HAL's `Ret:` to be 0 — and that row is
   coupled to libata's PIO drain (`sata_st = 0x58` is what libata's `data_xfer`
   wants), so it is a model-owner decision, not a one-liner.
3. **DMA data phase** (`a+0x24c` address, `vIdeHalRegDmaEnable`): without it the
   HAL IDENTIFY buffer stays uninitialised and `ModelName:` never prints.
4. **`a+0x038`** could be served (`0x50`-like value) if a future probe ever arms a
   timer here; today it is harmless.

---

## 8. Reproducibility

```
# the two consumers' code
llvm-objdump -d -r --section=.text --start-address=0x9a384 --stop-address=0x9a470 /tmp/bdpdrv/bdpdrv.ko   # GetSignature
llvm-objdump -d -r --section=.text --start-address=0x9e1dc --stop-address=0x9e320 /tmp/bdpdrv/bdpdrv.ko   # WaitEvt accept masks
llvm-objdump -d -r --section=.text --start-address=0x9dc00 --stop-address=0x9dcd4 /tmp/bdpdrv/bdpdrv.ko   # HwIntStatus ack
llvm-objdump -d -r --section=.text --start-address=0x9af94 --stop-address=0x9b180 /tmp/bdpdrv/bdpdrv.ko   # PollingStReg
llvm-objdump -d -r --section=.text --start-address=0x328   --stop-address=0x37c   /tmp/bdpdrv/libata.ko     # ata_dev_classify
llvm-objdump -d -r --section=.text --start-address=0x2230 --stop-address=0x2260 /tmp/bdpdrv/sata_mt85xx_mod.ko
llvm-objdump -d -r --section=.text --start-address=0x25cc --stop-address=0x25e4 /tmp/bdpdrv/sata_mt85xx_mod.ko
# who touches a+0x220 at all
llvm-objdump -d -r --section=.text /tmp/bdpdrv/sata_mt85xx_mod.ko | grep -n "word.*0xfd00a220"
# apply + rebuild
git apply evidence/bx510-guest/bdpdrv/decode/ide-hal-rows.patch
scp emulator-kit/*.{c,h,sh,patch,py} aftermath@10.20.0.18:bx510-emu/emulator/ && ssh -p 2222 ... 'cd ~/bx510-emu/emulator && JOBS=6 sh ./build.sh'
```

---

### One-line summary

The a-window serves **one** ATAPI signature — the SATA D2H word `0xEB140101` at
`a+0x00c` — of which libata reads `+010…+018` and bdpdrv's IDE HAL reads
`+00c…+014`; serving all four words makes the HAL print `Signature:0x140101` and
take the `0xa1` branch without disturbing `class=3`, and `0xa220` must latch
**bit0 | bit5** because the HAL completes on bit5 while every other reader
accumulates and write-back-clears the whole word.
