# ATA_HORKAGE_DUMP_ID diagnostic — scratch `libata.ko` patch (C100)

**Purpose.** Answer, in one guest run, the question that decides H1 vs H2 vs H3 of
`id-validity-check.md` §5: *did the model's IDENTIFY table arrive in `dev->id`, byte for byte?*
The `read_id` hexdump path (libata `.text+0x3f38`) prints the exact 512 bytes libata validates, so
the model's `w[0] = 0x8580` (bytes `80 85` in the dump) either appears or it does not.

**Scratch copy only.** Nothing tracked was modified: not `emulator-kit/`, not the libata source, not
`tools/`. The patch is applied to a copy of the staged blob.

| | |
|---|---|
| patch baseline (byte-identical to the VM's C9x-staged copy) | `/tmp/bdpdrv/libata.ko` — sha256 `e28ac41ad4f808c4b9768858533ab295547730618eaa4f656f6124a806c95354` |
| patched module (host) | `/tmp/libata_dump.ko` — sha256 `df972363f74483c884f41d6f0a3e172031de7c43543cd2745f6502cd85eb686b`, 193620 bytes (unchanged size) |
| patched module (VM, staged) | `/tmp/libata_dump.ko` — sha256 verified `df972363…` on the VM after `make vm-stage-file` |
| swap-in flag for the next fire | `--pre-file libata.ko=/tmp/libata_dump.ko` |

---

## 1. The gate, and the one instruction that opens it

`id-validity-check.md` §1.1 row 1 — the `ATA_HORKAGE_DUMP_ID` test — decoded from the module:

```
.text+0x3ca4:  e5953008   ldr  r3, [r5, #0x8]      ; r3 = dev->horkage
.text+0x3ca8:  e3130801   tst  r3, #0x10000        ; ATA_HORKAGE_DUMP_ID
.text+0x3cac:  1a0000a1   bne  0x3f38              ; → dump path; falls through otherwise
.text+0x3cb0:  e3540001   cmp  r4, #1              ; class == ATA_DEV_ATA?
```

**Patch: make the branch unconditional.** `.text+0x3cac`, word `0x1a0000a1` → `0xea0000a1`
(`bne` → `b`). The imm24 is untouched — the target is still `0x3f38`, so the dump runs and then
`b 0x3cb0` at `.text+0x3f94` resumes the normal class ladder exactly as the stock
horkage-set path does.

Why `b` and not "replace the `tst` with `mov r3,#0x10000`": `mov` does not set flags, so the
following `bne` would then branch on **stale** condition flags. Patching the branch is one word,
keeps the target/offset identical to the original encoding, and cannot make the path
flag-dependent.

## 2. The second word — the dump's log level (mandatory, not cosmetic)

The dump's two print calls take their level as a **runtime argument**, not a folded prefix
(`dev_printk`-style: `printk("%sata%u.%02u: " fmt, level, …)`; `print_hex_dump(level, …)`):

```
.text+0x3f4c: e59f113c  ldr r1, [pc, #316]  @ 0x4090   ; level string  ← printk's %s
.text+0x3f58: e59f0134  ldr r0, [pc, #308]  @ 0x4094   ; "…dumping IDENTIFY data, class=%d …"
.text+0x3f78: e59f0110  ldr r0, [pc, #272]  @ 0x4090   ; level string  ← print_hex_dump's level
```

That pool slot resolves (via `R_ARM_ABS32` against `.rodata.str1.4`) to **`<7>`** — `KERN_DEBUG`
(`.rodata.str1.4+0x3fc`, perfect string `<7>`). This guest's console loglevel is **7**, so level 7
is dropped and the dump would never reach the UART. Proven from the committed C97/C99 logs, not
assumed:

| site | level | evidence in `bdpdrv-runC97/C99.uart.log` |
|---|---|---|
| `ata_host_register`'s `%sata%u: %cATA max %s %s` print (fmt `.rodata.str1.4+0x12bc`, level arg pool `.text+0x76d0` → `+0x198` = **`<6>`**) | `KERN_INFO` (6) | **printed**: `ata1: SATA max UDMA/133 irq 18` ⇒ `console_loglevel ≥ 7` |
| `ata_init`'s `"libata version 3.00 loaded.\n"` (level folded inline: literal `.rodata.str1.4+0x1380` = `<7>libata version 3.00 loaded.`) | `KERN_DEBUG` (7) | **absent** although `PRE_libata.ko_RC=0` and its ports registered ⇒ level 7 is suppressed ⇒ `console_loglevel ≤ 7` |

⇒ `console_loglevel == 7`; `<7>` never prints, `<3>` always does.

**Patch: repoint that pool slot's addend** `.text+0x4090`: `0x000003fc` (`<7>`) → `0x000000cc`
(`<3>`, `KERN_ERR`, `.rodata.str1.4+0xcc` is the perfect string `<3>`). Redirecting the
*addend* rather than editing the `<7>` literal keeps the other user of that literal
(pool `.text+0x5184`, `ata_dev_configure`'s debug line) untouched — no collateral output. This is
exactly how the 2.6.x ARM module loader works: an `R_ARM_ABS32` site is relocated as
`section_base + <value already in the slot>`, so the in-file word *is* the addend.

## 3. The two edits, byte for byte

`.text` sh_offset = `0x34` (read from the section headers and asserted by the script);
`.rodata.str1.4` sh_offset = `0x18ea0`.

| # | location | file offset | original bytes | patched bytes | meaning |
|---|---|---|---|---|---|
| 1 | `.text+0x3cac` | `0x3ce0` | `a1 00 00 1a` | `a1 00 00 ea` | `bne 0x3f38` → `b 0x3f38` (dump always) |
| 2 | `.text+0x4090` | `0x40c4` | `fc 03 00 00` | `cc 00 00 00` | level arg `<7>` → `<3>` (`KERN_DEBUG` → `KERN_ERR`) |

Only three bytes in the whole file differ (`cmp -l`):

```
15588  32 352      # 0x3ce3: 0x1a -> 0xea
16581 374 314      # 0x40c4: 0xfc -> 0xcc
16582   3   0      # 0x40c5: 0x03 -> 0x00
```

## 4. Verification

Exact disassembly diff of the whole `.text` (`armv7-linux-gnueabihf-objdump -dr --section=.text`,
stock vs patched) — nothing else changed:

```
4291c4291
<  1a0000a1  bne 3f38 <ata_dev_read_id+0x3e4>
---
>  ea0000a1  b 3f38 <ata_dev_read_id+0x3e4>
4554c4554
<  000003fc  .word 0x000003fc
---
>  000000cc  .word 0x000000cc
```

Patched site and the dump path it now always enters:

```
    3ca4: e5953008  ldr  r3, [r5, #8]
    3ca8: e3130801  tst  r3, #65536        @ 0x10000
    3cac: ea0000a1  b    3f38
    3cb0: e3540001  cmp  r4, #1
    3cb4: 0a000035  beq  3d90
    3cb8: e1d730f0  ldrsh r3, [r7]         @ id[0]
...
    3f38: e5953000  ldr  r3, [r5]
    3f3c: e5952004  ldr  r2, [r5, #4]
    3f40: e59de018  ldr  lr, [sp, #24]
    3f44: e593c000  ldr  ip, [r3]
    3f48: e5933004  ldr  r3, [r3, #4]
    3f4c: e59f113c  ldr  r1, [pc, #316]    @ 4090   ; level  (now "<3>")
    3f50: e88d4210  stm  sp, {r4, r9, lr}
    3f54: e0833002  add  r3, r3, r2
    3f58: e59f0134  ldr  r0, [pc, #308]    @ 4094   ; "…dumping IDENTIFY data, class=%d may_fallback=%d tried_spinup=%d\n"
    3f5c: e59c2014  ldr  r2, [ip, #20]
    3f60: ebfffffe  bl   printk
    3f64: e3a0c002  mov  ip, #2                    ; prefix_type = DUMP_PREFIX_OFFSET
    3f68: e1a0200c  mov  r2, ip
    3f6c: e58dc000  str  ip, [sp]                  ; groupsize = 2
    3f70: e3a0cc02  mov  ip, #512                  ; len = 512
    3f74: e58dc008  str  ip, [sp, #8]
    3f78: e59f0110  ldr  r0, [pc, #272]    @ 4090   ; level  (now "<3>")
    3f7c: e3a0c001  mov  ip, #1                    ; ascii = true
    3f80: e59f1110  ldr  r1, [pc, #272]    @ 4098   ; prefix_str = ""
    3f84: e3a03010  mov  r3, #16                   ; rowsize = 16
    3f88: e58d7004  str  r7, [sp, #4]              ; buf = dev->id (r7 = arg 4)
    3f8c: e58dc00c  str  ip, [sp, #12]
    3f90: ebfffffe  bl   print_hex_dump
    3f94: eaffff45  b    3cb0                      ; ← resumes the class ladder
```

Registers are safe: this is the *stock* fall-through path (compiled for the horkage-set case),
so `r4`/`r5`/`r7` are live across `printk`/`print_hex_dump` by construction — the patch only
removes the condition on entering it.

Structural checks that the module is still loadable/honoured:

* **No relocation targets the patched instruction.** `0` relocations in `.text+0x3c80..0x3cc0`
  (26 exist inside `ata_dev_read_id`, none at `0x3cac`), so nothing overwrites the branch at load.
  `.text+0x4090` *is* an `R_ARM_ABS32` site — that is the mechanism used in edit 2 (see §2).
* **No `__versions` section** in this `.ko` (`CONFIG_MODVERSIONS` off for it), vermagic string
  untouched: `vermagic=2.6.35 preempt mod_unload ARMv6` — byte-identical to the module that
  already insmods in C91/C97/C99 (`PRE_libata.ko_RC=0`).
* `print_hex_dump` and `printk` are pre-existing `R_ARM_CALL` imports of this same blob (they
  resolved at load in the C9x runs), so the dump path adds no new symbol dependency.
* ELF size unchanged (193620), section table untouched, 3 bytes differ.

## 5. Where it is staged, and how to fire it

Staged with the repo's private channel:

```
make vm-stage-file FILE=/tmp/libata_dump.ko       # → VM:/tmp/libata_dump.ko
# verified: sha256 df972363f74483c884f41d6f0a3e172031de7c43543cd2745f6502cd85eb686b
# (the baseline the patch was computed from, VM:/tmp/sata_staging/libata.ko, is
#  e28ac41a… — byte-identical to the C9x-staged module: same blob, patched.)
```

Nothing else changes in the fire line — swap exactly one `--pre-file` (the flag reads a
**VM-side** host path, because the probe script runs on the lab VM; `--pre-file NAME=PATH` copies
`PATH` into `shim/NAME` and `insmod /res/shim/NAME`):

```
cd ~/bx510-emu/emulator && python3 bx510_bdpdrv_stub_probe.py \
  --qemu work/build/qemu-system-arm --images /tmp/images-fe \
  --stubko /tmp/osal_b/bx510_osal_stub.ko --stuba-ko /tmp/osal_a/bx510_osal_stub_a.ko \
  --bdpdrv-host /tmp/rootfs/lib/modules/2.6.35/BDP/bdpdrv.ko \
  --bdpdrv-guest /lib/modules/2.6.35/BDP/bdpdrv.ko \
  --pre-file libata.ko=/tmp/libata_dump.ko \
  --pre-file sata_mt85xx_mod.ko=/tmp/sata_staging/sata_mt85xx_mod.ko \
  --extra-file bx510_feboot.ko=/tmp/osal_d/bx510_feboot.ko \
  --extra-file bx510_clidrive.ko=/tmp/osal_c/bx510_clidrive.ko \
  --uart /tmp/bdpdrv-runC100.uart.log --unimp /tmp/bdpdrv-runC100.mmio.log \
  --meta /tmp/bdpdrv-runC100.meta.json --timeout 300
```

(`--pre-file sata_mt85xx_mod.ko=` may point wherever the run's driver module is staged; only the
libata line differs from the C99 fire.)

## 6. What the UART should now contain, and how to read it

Per `ata_dev_read_id` call, the dump block is one message line + 32 hex lines (16 bytes/row,
groupsize 2, ASCII column):

```
ata1.00: dumping IDENTIFY data, class=3 may_fallback=1 tried_spinup=0
00000000: 8085 0000 0000 0000 0000 0000 0000 0000  ................
00000010: 0000 0000 0000 0000 ...
```

C99 shows two `read_id` attempts (two EH cycles), so expect **two** blocks; a third appears only if
the ATA/ATAPI class fallback retry (`id-validity-check.md` §1.1 row 0) ever runs — it does not on
the `err_mask=0` path.

Decision rule — word 0 of the first data line:

| first data line begins | reads as | conclusion |
|---|---|---|
| `8085 0000 0000 …` | `w[0] = 0x8580` (model's ATAPI CD-ROM word), `w[2] = 0` | **the model's table arrived.** Gate A passes; any remaining failure is gate B / word values (`id-validity-check.md` §3.3) — H3. |
| `0000 0000 0000 …` | all-zero / untouched bounce buffer | the payload never landed: `priv+0x54 == 0` at drain **or** the memcpy target is not what `data_xfer` reads — H1/H2. |
| anything else / differing between the two blocks | stale or FE-window bytes | payload hand-off, and it varies per cycle — exactly the C97 contradiction (`id-validity-check.md` §5). |

Cross-check the words that gate B reads, all in the same dump: `w[0] & 3` (bytes `00 00`: expect
`0` → 12-byte CDB), `w[2]` (≠ `0x37c8`/`0x738c`), `w[83]` at byte offset `166` (`0x4000`),
`w[88]` at offset `176` (`0x0007`), model string at bytes `54..93` — `SONY    BDPSACDEMUL` in the
ASCII column iff the `+54` model fix went in.

Also relevant from C99 and to be read together with the dump: the driver printed
`[IDE]<sata_mt85xx_id_atapi_dev>copy from (0xdfc01000, 0x200) to (0xc6268c60, 0x200)` — a
0x200-byte copy *did* happen that cycle. The two possible reasons it still left libata with
non-model bytes (copy landed before `priv+0x54` was armed, or it targeted a buffer `data_xfer`
does not read) are distinguishable only by comparing those bytes to the model table — which is
what this dump does.

If the message line is **absent** entirely, that is an honest negative with meaning: the dump path
was not reached, i.e. `ata_dev_read_id` did not run in that cycle (not a patch failure — the
`b` is unconditional on that path).

## 7. Reproduce the patch (exact script used)

```python
#!/usr/bin/env python3
"""Patch a SCRATCH copy of libata.ko so ata_dev_read_id always hexdumps the
512 bytes it actually validates (ATA_HORKAGE_DUMP_ID path), at KERN_ERR."""
import hashlib, struct, sys

TEXT_FILE_OFF = 0x34  # sh_offset of .text (asserted below)
EDITS = [  # (file offset, original word, new word, label) — little-endian ARM
    (TEXT_FILE_OFF + 0x3CAC, 0x1A0000A1, 0xEA0000A1,
     ".text+0x3cac bne 0x3f38 -> b 0x3f38"),
    (TEXT_FILE_OFF + 0x4090, 0x000003FC, 0x000000CC,
     ".text+0x4090 level addend 0x3fc (<7>) -> 0xcc (<3>)"),
]

def section_offsets(d):
    shoff = struct.unpack("<I", d[0x20:0x24])[0]
    shentsize, shnum, shstrndx = struct.unpack("<HHH", d[0x2E:0x34])
    shstr = struct.unpack("<I", d[shoff + shstrndx*shentsize + 0x10:
                                shoff + shstrndx*shentsize + 0x14])[0]
    out = {}
    for i in range(shnum):
        b = d[shoff+i*shentsize:shoff+(i+1)*shentsize]
        name, _, _, _, off, size = struct.unpack("<IIIIII", b[:24])
        s = shstr + name
        out[d[s:d.index(b"\0", s)].decode()] = (off, size)
    return out

src, dst = sys.argv[1], sys.argv[2]
d = bytearray(open(src, "rb").read())
secs = section_offsets(bytes(d))
if secs[".text"][0] != TEXT_FILE_OFF:
    raise SystemExit("wrong .ko: .text moved")
str_off = secs[".rodata.str1.4"][0]
for off, old_word, new_word, label in EDITS:
    old, new = struct.pack("<I", old_word), struct.pack("<I", new_word)
    if bytes(d[off:off+4]) != old:
        raise SystemExit(f"{label}: 0x{off:x} holds {bytes(d[off:off+4]).hex()}, "
                         f"expected {old.hex()}")
    d[off:off+4] = new
    print(f"patched 0x{off:x}: {old.hex()} -> {new.hex()}  {label}")
assert d[str_off+0xCC:str_off+0xCF] == b"<3>", "level literal moved"
assert d[str_off+0x3FC:str_off+0x3FF] == b"<7>", "level literal moved"
open(dst, "wb").write(bytes(d))
for p in (src, dst):
    print(p, hashlib.sha256(open(p, "rb").read()).hexdigest())
```

Run as: `cp /tmp/bdpdrv/libata.ko /tmp/libata_dump.ko && python3 patch_libata_dump_id.py
/tmp/libata_dump.ko /tmp/libata_dump.ko`. The script refuses if the instruction bytes are not the
expected originals, so it cannot silently double-patch or patch a different build.

## 8. Risks and limits

* The patch is **pinned to this blob** (`e28ac41a…`). If the staged libata.ko is ever rebuilt, the
  byte patch must be recomputed (the script fails loudly rather than guessing).
* The dump fires on **every** `ata_dev_read_id`, at `KERN_ERR`, 32 lines each — console noise is
  expected, not a symptom. It does not alter control flow, the class, or the payload.
* Not verifiable here: the module only loads inside the emulated guest. Loadability is unchanged
  in every dimension the 2.6.35 ARM loader checks (vermagic, symbol set, no modversions), and the
  patched word is only executed on this path — but "it insmods and prints" is a C100 run fact, not
  a static claim.
* The `<3>` level may render as a literal `"<3>"` text prefix depending on how this kernel's
  `printk` handles an argument-supplied level; the C9x logs show level prefixes stripped
  (`ata1: SATA max …` with no `<6>`), so a clean `ata1.00: dumping …` line is the expectation.
  Cosmetic either way — the bytes follow the line.
* The `--pre-file` path is a **VM** path. Staging the file to the Mac only (without
  `make vm-stage-file`) makes the probe fail at tar-build time on the VM.

## 9. Certainty ledger

**DECODED (instruction level, this module):** the `horkage & 0x10000` gate and its `bne` at
`.text+0x3ca8/0x3cac`; the dump path's exact argument setup (`printk` at `.text+0x3f60`,
`print_hex_dump` at `.text+0x3f90`, level arg pooled at `.text+0x4090` = `.rodata.str1.4+0x3fc` =
`<7>`, prefix `""`, rowsize 16, groupsize 2, len 512, ascii 1, buffer `r7` = `dev->id`); the
resume edge `b .text+0x3cb0`; that the level is an argument (not a folded prefix) at both sites;
that `.text+0x4090` is an `R_ARM_ABS32` site whose in-file word is the addend; no relocation at
`.text+0x3cac`; no `__versions` section; `vermagic=2.6.35 preempt mod_unload ARMv6`; the two
dumps' levels (`<6>` at `.text+0x76d0` for the printed `ATA max` line, inline `<7>` on
`"libata version 3.00 loaded."`) and therefore `console_loglevel == 7` in the C97/C99 rigs.

**INFERRED:** that the hexdump's level arg is honoured the same way at console granularity as the
`%s`-supplied level in `dev_printk` (same rendered-string mechanism) — the `<3>` choice makes the
distinction moot; that C100 will show exactly two dump blocks (≈ one `read_id` per EH cycle).

**Open (this patch does not answer):** whether the bytes, once printed, match §3.3 — that is the
run's question, and the table in §6 is the reading rule.
