# BX510 guest kernel — static IO map + interrupt routing decode

Target: `kernel.uImage` pulled from the player (`evidence/bx510-guest/u4-initrd/pulled/`),
`Linux version 2.6.35 (aokino@rvds241) gcc 4.5.1 #1 PREEMPT Thu Sep 20 09:03:01 JST 2018`.
uImage sha256 `10bb0fba4eb26c5b1ebf798f4d4669dc8b5899d520be294d333c318a360be2d7`.

Status of every claim is labelled **VERIFIED** (read out of the bytes by a script in
this directory) or **INFERRED** (reasoned, not machine-checked).

---

## Verdict — the short version

```
(a) VA 0xfd05c704 / 0xfd05c500 / 0xfd05c780  -> COVERED: PA 0x7005c704 ... (one 16 MiB entry)
(b) VA 0xfd324180 / 0xfd324b00               -> COVERED: PA 0x70324180 ... (same entry)
(c) VA 0xfd024xxx (FE block)                 -> COVERED: PA 0x70024xxx   (same entry; log confirms hits)
(d) VA 0xfd00a000 (ATA/IDE window)           -> COVERED: PA 0x7000a000   (same entry)
    The map is ONE flat MT_DEVICE section: 0xfd000000..0xfdffffff -> 0x70000000..0x70ffffff.
    There is no per-block map and no non-0x8d000000 delta anywhere. The map is NOT the bug.
SATA port IRQ = 53 -> BIM group 1, pending 0x70008138 bit 21, mask 0x7000813c bit 21.
FE/SVOIF IRQ = 18 -> BIM group 0, pending 0x70008030 bit 18, mask 0x70008034 bit 18.
    sony-bx510.c implements NEITHER -> no SATA/FE interrupt can ever be delivered.
FIX: add group-0 bit 18 and group-1 bit 21 to the model's pending logic (both already
    flow through bx510_update_irq), widen the IO window to the kernel's 16 MiB (the model
    covers 4 MiB, so 0x7006xxxx/0x7009xxxx -- used by the SATA reset path -- are unassigned),
    and log the FE-SRAM FIFO at LOG_UNIMP or run QEMU with `-d unimp,guest_errors`
    (today those accesses are LOG_GUEST_ERROR and are invisible under the rig's `-d unimp`).
```

---

## 1. Image chain (how a vmlinux came out of the uImage)

| Layer | Fact | Script |
|---|---|---|
| uImage | magic `0x27051956`, `size=2285568`, `load=ep=0x0da00000`, `os=5`, `arch=2`, `type=2`, **`comp=0`** (payload is a self-decompressing zImage, not a flat kernel) | `kernel_decode_image.py` |
| zImage | ARM magic `0x016f2818` at `+0x24`, start `0x0`, end `0x22e000`; gzip member at `+0x43d5` | same |
| raw image | 4,676,960 bytes (`0x475d60`) of ARM code, no ELF headers (`objcopy -O binary` of vmlinux) | same |

File offset 0 == `stext`. The VA of `stext` is not assumed: it is recovered from the
kallsyms address table, whose first entry is `0xc0008000` and whose top entry matches
the end of `.text` (**VERIFIED**). Page offset `0xc0000000`, physical offset 0.

**Note on the input path:** `/tmp/bdpdrv/` contains no kernel image; the kernel used
here is the in-repo pull above (`kernel.uImage`), which is the same artifact the rig
boots (`run.py` passes `-kernel images/kernel.uImage`).

## 2. Symbols without a System.map

The image has no `System.map`, but 2.6.35 always carries kallsyms. `kernel_decode_kallsyms.py`
locates the tables by structural invariant rather than by hard-coded offsets:

```
kallsyms_addresses   file 0x378200..0x391564   25817 absolute u32 VAs, ascending, first = stext
kallsyms_num_syms    file 0x391570             = 25817   (12 bytes of link-time pad before it)
kallsyms_names       file 0x391580..0x3d77e0   len-prefixed token-index stream
kallsyms_markers     file 0x3d77e0             101 ascending u32 (names offsets)
kallsyms_token_table file 0x3d7980..0x3d7d01   256 NUL-terminated tokens + zero pad
kallsyms_token_index file 0x3d7d10             256 u16
```

Cross-checks the script enforces: `num_syms` must equal `ceil(markers)` sizing, the
address run must start at `0xc0008000` and be monotone, the names stream must decode to
exactly `num_syms` entries landing on the markers start, and the token table must be the
unique start for which every `token_index[k]` is a string start (**VERIFIED**).
Decoded names sanity: `stext`, `_stext`, `printk`, `iotable_init`, `mt85xx_map_io`,
`mt85xx_init_irq`, `sata_bltin_init`, `__irq_svc` …

## 3. The static IO map

`machine_desc.map_io = mt85xx_map_io` (`__mach_desc_MT85XX` @ `0xc001e644`, field `+0x24`,
nr = 2000 — same board id the model uses). Its body is:

```
c000cd84  push {r4, lr}
c000cd88  mov  r1, #1
c000cd8c  ldr  r4, [pc, #0x14]     ; pool = 0xc00204e4  (&mt85xx_io_desc)
c000cd90  mov  r0, r4
c000cd94  bl   iotable_init        ; iotable_init(&mt85xx_io_desc, 1)
c000cd98  add  r0, r4, #16         ; == &mt85xx_local_io_desc (0xc00204f4)
c000cd9c  mov  r1, #1
c000cda0  pop  {r4, lr}
c000cda4  b    iotable_init        ; iotable_init(&mt85xx_local_io_desc, 1)
```

So exactly two 1-entry `map_desc` arrays are installed. 2.6.35 fills `pfn`, not
`physical`, so physical = `pfn << 12`:

| array | virtual | physical | length | type | span |
|---|---|---|---|---|---|
| `mt85xx_io_desc[0]` | `0xfd000000` | `0x70000000` | `0x01000000` (16 MiB) | `0` | VA `0xfd000000..0xfdffffff` -> PA `0x70000000..0x70ffffff` |
| `mt85xx_local_io_desc[0]` | `0xfe000000` | `0x50000000` | `0x00002000` (8 KiB) | `0` | VA `0xfe000000..0xfe001fff` -> PA `0x50000000..0x50001fff` |

**VERIFIED**: both descriptors read word-for-word out of the image at their kallsyms
addresses; `mt85xx_io_desc` is also referenced as a pool literal inside `mt85xx_map_io`
(`0xc000cda8`), the local descriptor as `+16` from that pointer.

* The `0xfe000000` entry is the L2 cache controller: `mt85xx_init` calls
  `l2x0_init(0xfe000000, 0x02520000, 0xc0000fff)` (**VERIFIED**, pool `0xc000ccec-f0`).
* **type = 0** is `MT_DEVICE` in 2.6.35 (`arch/arm/include/asm/mach/map.h`). The *value*
  is VERIFIED from the image; the *enum name* is INFERRED from the header. Cross-check
  that makes it solid: every register access the drivers make is individually visible at
  the model, i.e. the mapping is uncached/device — a cacheable (`MT_MEMORY`) mapping
  would swallow those writes (**VERIFIED behaviourally**).
* No Kconfig involvement: the image carries no embedded config (`IKCFG_ST` absent,
  no `CONFIG_MT85*` strings). The map is a hard-coded C array, not table-driven from
  `.config` (**VERIFIED**).

## 4. The four specific addresses

Everything the BX510 drivers touch inside `0xfd000000..0xfdffffff` is served by the
single 16 MiB entry, so the "-0x8d000000 for all ranges" assumption is correct for all
four blocks. From `kernel_decode_iomap.py`:

```
0xfd00a000 -> PA 0x7000a000  [mt85xx_io_desc[0] VA 0xfd000000 len 0x1000000 type 0]
0xfd024000 -> PA 0x70024000  [same entry]     FE block base
0xfd024180 -> PA 0x70024180  [same entry]
0xfd05c500 -> PA 0x7005c500  [same entry]
0xfd05c704 -> PA 0x7005c704  [same entry]
0xfd060004 -> PA 0x70060004  [same entry]     clock/PLL block
0xfd090308 -> PA 0x70090308  [same entry]     DRAM wrapper
0xfd324180 -> PA 0x70324180  [same entry]     FE SRAM FIFO write pointer
0xfd324b00 -> PA 0x70324b00  [same entry]
```

Answers: **(a)** covered — `0xfd05c704 -> 0x7005c704`, in the same 16 MiB entry;
**(b)** covered — `0xfd324180 -> 0x70324180`; **(c)** covered — `0xfd024xxx -> 0x70024xxx`,
and the run log confirms real hits there; **(d)** covered — `0xfd00a000 -> 0x7000a000`.

### Where these blocks actually are (from the driver's own literal pools)

The module `sata_mt85xx_mod.ko` (pool scan of `.text`) uses four distinct windows:

| VA window | role | evidence |
|---|---|---|
| `0xfd00a000` | ATA/IDE taskfile + per-channel + IRQ-status registers | `sata_mt85xx_send_atapi_cmd`, `sata_mt85xx_xfer_fe_data`, `sata_mt85xx_trig_fe_boot`, `sata_mt85xx_softreset`, `sata_mt85xx_interrupt` |
| `0xfd024000` | FE block (`VSFHW_*`: reset cmd `+0x30`, level `+0x34`, SRAM clk `+0x188`) **and** the secondary interrupt controller (`+0x140` pending / `+0x144` mask) | `sata_mt85xx_reset_int_ldr`, `sata_mt85xx_xfer_int_ldr_fw`; bdpdrv `VSFHW_FrontEndResetLo/Hi/Status`, `VSFHW_SramClk/Status` |
| `0xfd05c000` | **FE/IDE control block**: DRAM wrapper base `+0x500`, clock enables `+0x600/+0x604`, reset/interrupt control `+0x704/+0x708` | bdpdrv `i4IdeDrvBootup` (read-modify-writes at `0xfd05cfff-0x8fb` = `+0x704`, `-0x8f7` = `+0x708`, `-0x9ff` = `+0x600`, `-0x9fb` = `+0x604`, `-0xaff` = `+0x500`); module's `0xfd05cfff` base idiom; kernel `vStarResetClock` and `vResetClock` |
| `0xfd324000` | FE boot-code SRAM FIFO (`0xfd324fff` base) | `sata_mt85xx_xfer_int_ldr_aacs_data` |

`0xfd05c704` — the address named in the brief as "the FE/IDE control block" — is exactly
that: `i4IdeDrvBootup` read-modify-writes it (mode bits `9..11` cleared, then `0x0a01`
set: "release frontend reset"), `0xfd05c500` takes `addr >> 22` (the DRAM wrapper base),
`0xfd05c600/+0x604` take enable bits, `0xfd05c708` takes bit 4 (interrupt enable/clear)
(**VERIFIED** disassembly of `i4IdeDrvBootup`). The module uses the same window through the
`0xfd05cfff` base idiom, and the kernel's `vStarResetClock` pool holds `0xfd05c704`,
`0xfd05c708`, `0xfd024034`, `0xfd024030`, `0xfd090308`, `0xfd09030c`, `0xfd060004`,
`0xfd000314` — i.e. a single FE/IDE + clock-control window shared by the IDE driver, the
STAR clock path and the SATA module (**VERIFIED literal set**; the exact pairing of value to
register in the kernel function is INFERRED).

## 5. Interrupt routing

### 5.1 Controller geometry (VERIFIED)

`mt85xx_init_irq` programs three pending/mask/clear triples off a BIM base of
`0xfd008000` (PA `0x70008000`, matching `BX_BIM`), and installs a chip + level handler
for **virq 0..127**:

```
mask regs  (written 0)        : +0x034  +0x13c  +0x158
pending/clear (written ~0)    : +0x030 +0x038   +0x138 +0x140   +0x154 +0x15c
groups                        : (0x030/0x034/0x038) (0x138/0x13c/0x140) (0x154/0x158/0x15c)
```

`mt85xx_unmask_irq` / `mt85xx_mask_ack_irq` split on `31 / 32 / 64 / 96`, i.e.

```
virq  0..31  -> +0x030 pending, +0x034 mask, +0x038 clear
virq 32..63  -> +0x138 pending, +0x13c mask, +0x140 clear
virq 64..95  -> +0x154 pending, +0x158 mask, +0x15c clear
virq 96..127 -> secondary controller at 0xfd024000: +0x140 pending, +0x144 mask
```

The fast dispatcher `__irq_svc` (this is the real IRQ entry, not `handle_level_irq`)
confirms the numbering and adds two special cases:

```
pending0 & 1<<17            -> serviced even if masked  (priority line, virq 17)
pending0 & mask0            -> virq = 31 - clz(..)           (group 0)
pending2 & mask2            -> virq = 63 - clz(..)           (group 1)
   if that virq == 52       -> cascade: 0xfd024000 pending+0x140 & mask+0x144,
                               virq = 127 - clz(..)          (group 3, 96..127)
pending3 & mask3            -> virq = 95 - clz(..)           (group 2)
none                        -> 128 (spurious)
```

`mt85xx_unmask_irq` sets `mask2 |= 1<<20` when it unmasks any group-3 line — that is the
cascade enable, not an independent line.

### 5.2 The two lines the SATA/FE path needs (VERIFIED)

`sata_mt85xx_init` registers its platform device with **no resources**
(`platform_device_register_simple("sata_mt85xx", 0, NULL, 0)` — name literal at
`.rodata.str1.4+0x1eb4`) and then hard-codes the virq as `port_index + imm`:

```
ldr r1,[r7,#0x24]        ; [r7+0x24] = this port's index (0 for the single drive)
add r1,r1,#53            ; irq = port_index + 53
ldr r2,=sata_mt85xx_interrupt
mov r3,#128              ; IRQ flags
bl  ata_host_activate    ; .init.text+0xb6c
...
add r1,r1,#18            ; irq = port_index + 18
ldr r2,=svoif_mt85xx_interrupt
bl  ata_host_activate    ; .init.text+0xb90
```

and the FE interrupt handler independently re-derives the same number:
`disable_irq(host->port_index + 18)` at `.text+0x46d8`. `kernel_decode_irqmap.py`
recovers both immediates from the instructions that feed the relocations.

```
SATA/ATA port      virq 53 -> group 1, +0x138 bit 21, mask +0x13c bit 21  (PA 0x70008138 / 0x7000813c)
FE / SVOIF         virq 18 -> group 0, +0x030 bit 18, mask +0x034 bit 18  (PA 0x70008030 / 0x70008034)
(secondary intc     virq 52 = group-1 bit 20 cascade -> 0x70024140 / 0x70024144, virqs 96..127)
```

### 5.3 What `sony-bx510.c` implements today

| line | model | required |
|---|---|---|
| virq 27 (timer 0) | `BX_T0_IRQ (1u<<27)` in `pending`, `BX_BIM+0x30/0x34` | correct as-is |
| virq 14 (UART) | `BX_UART_IRQ (1u<<14)` | correct as-is |
| virq 33 (NFI) | `pending2 \|= 2` (`BX_BIM+0x138/0x13c`) | correct as-is |
| **virq 18 (FE/SVOIF)** | **absent** | `pending \|= 1<<18` — mask bit 18 lives in `BIM+0x34`, already modelled |
| **virq 53 (SATA port)** | **absent** | `pending2 \|= 1<<21` — mask bit 21 lives in `BIM+0x13c`, already modelled |
| virq 52 + secondary 0x70024000 | absent | only needed if the guest drives group-3 lines (IR/VFD); the IR driver currently polls instead |

Because `bx510_update_irq()` already computes `(pending & mask) | (pending2 & mask2)`,
adding the two bits is a two-line change plus placement of the raise calls.

## 6. Why `0xfd05c704` / `0xfd324180` "never appear" — the real cause

Three artifacts, none of which is the static map:

**(1) `0x324180`/`0x324184` are IMPLEMENTED in the model and logged at `LOG_GUEST_ERROR`**
(sram FIFO wptr/data). The rig captures QEMU with **`-d unimp`**
(`tools/bx510_phase0_probe.py`: `argv[1:1] = ["-d","unimp","-D",unimp]`), which does not
enable `guest_errors`. So an absent FIFO line in `*.mmio.log` proves **nothing** about
whether the FIFO was written. **VERIFIED** by reading the model and the probe tool.

**(2) `0xfd05c704` itself really was not touched in these runs — and *only* that can be
concluded.** PA `0x7005c704` is *unimplemented* in the model, so it *would* print under
`-d unimp`; the C50 log contains no `0x7005c*` at all, and **zero** `unassigned memory
access` lines, so every access the guest made landed in a modelled region (**VERIFIED**).
What that does *not* cover: the ATA window `0x7000a0xx` and the FIFO `0x70032xxx` are
**implemented**, so their absence from a `-d unimp` log is uninformative (see (1)).
What the log does show is that the guest spent its time in the FE/video/IR front-end
blocks rather than in the FE firmware download — and in that run `i4IdeDrvBootup`'s
reset release at `0xfd05c704` had not happened yet.

What *did* reach the model in Run C50, i.e. what the guest was actually doing:

| PA | count | what it is |
|---|---|---|
| `0x70050320` | 6185 | `IFconWaitHWBusy`: `while (readl(0xfd050320) & 0x80);` — returns 0, loop exits, benign |
| `0x7002420c` | 12014 | `IRRX_PollMtkIr`: tests bit `0x40000` — returns 0 = "no IR", poll forever, benign |
| `0x700240f4`, `0x70024188`, `0x70024144` | 2474 / 20 / 2 | FE block / FE secondary-intc registers, unimplemented (return 0) |
| `0x7002600x..0x70026xxx` | 934 distinct | SIF/IR/VFD window, unimplemented |
| `0x7005f0xx`, `0x7005b1xx`, `0x7005e01x` | 5 / 2 / 2 | graphics/IOMMU MMU registers (`GFX_CmdQueAction`, `vIIOMMU_*`, `vHwGif_MMU_Flush`), unimplemented |

**(3) The IO window is too small for the map.** The kernel maps 16 MiB
(`0xfd000000..0xfdffffff` -> `0x70000000..0x70ffffff`) but the model registers only
`0x400000` bytes (`memory_region_init_io(..., 0x400000)`), i.e. PA
`0x70000000..0x703fffff`. Every block in §4 fits, **but** the SATA reset path also writes
`0xfd060004` (PA `0x70060004`, clock/PLL) and `0xfd090308/0xfd09030c/0xfd090324`
(PA `0x70090308..`, DRAM wrapper) — both **outside** the model. When that path runs those
accesses will appear as *unassigned memory*, not as model `LOG_UNIMP` lines
(**VERIFIED** geometry, INFERRED that the reset path runs).

## 7. Fix implications for `emulator-kit/sony-bx510.c`

1. **Interrupt lines (the actual blocker for the FE handshake).**
   ```c
   /* virq 18: FE/SVOIF, BIM group 0 (pending +0x30 / mask +0x34) */
   #define BX_FE_IRQ   (1u << 18)
   /* virq 53: SATA/ATAPI port, BIM group 1 (pending2 +0x138 / mask2 +0x13c) */
   #define BX_SATA_IRQ (1u << 21)
   ```
   Raise `BX_FE_IRQ` in `pending` when the FE operation the guest started completes, and
   `BX_SATA_IRQ` in `pending2` on ATA command completion (replacing the current
   unconditional `sata_ist |= 1` that goes nowhere). `bx510_update_irq()` already gates on
   `mask`/`mask2`, so no other change is needed for delivery.
2. **Widen the peripheral window to the kernel's own map**: extend the `io` region to
   `0x01000000` (or add subregions at `0x70060000` and `0x70090000`) so the SATA reset
   path (`0xfd060004`, `0xfd0903xx`) does not fall off the end of the device. Keeping
   `0x400000` silently converts those accesses into unassigned memory.
3. **Make the FIFO stage observable.** `0x324180/0x324184` log at `LOG_GUEST_ERROR`; either
   move them to `LOG_UNIMP` (consistent with every other model line) or run the rig with
   `-d unimp,guest_errors`. Otherwise the emulator team cannot tell "never wrote the FIFO"
   from "wrote it and we did not look".
4. **Registers to model next**, in the order the driver needs them: `0xfd00a000` ATA
   window (`0xa000/0xa004..0xa01c/0xa208/0xa220/0xa240..0xa24c/0xa6b8/0xa6c8` are all
   already touched by the module), `0xfd024030/0x34` (FE reset command 0x85 + level),
   `0xfd024188` (SRAM clock), `0xfd024034` (FE status), `0xfd324000..` FIFO.
   `0xfd050320` and `0xfd02420c` may stay returning 0 — the waits are poll loops that
   exit or idle harmlessly.
5. **`0xfd05c704` is a real FE/IDE control register, and should be modelled.**
   `i4IdeDrvBootup` clears bits `9..11` and then sets `0x0a01` there to release the frontend
   reset, and programs `0xfd05c500` (DRAM wrapper base = `addr >> 22`), `0xfd05c600`,
   `0xfd05c604`, `0xfd05c708` (bit 4). A read-back model of these five registers is what
   lets the IDE bootup path progress past the reset handshake.

## 8. Claim ledger

| Claim | Status |
|---|---|
| uImage comp=0, payload is zImage with gzip at `+0x43d5`, 4,676,960-byte raw image | VERIFIED (`kernel_decode_image.py`) |
| stext VA = `0xc0008000`, 25,817 kallsyms symbols | VERIFIED (`kernel_decode_kallsyms.py`) |
| `mt85xx_map_io` installs exactly two 1-entry descriptors, `mt85xx_io_desc` and `mt85xx_local_io_desc` | VERIFIED (disassembly + pool literals) |
| Entry 1: VA `0xfd000000` -> PA `0x70000000`, len `0x01000000`, type 0 | VERIFIED (image bytes) |
| Entry 2: VA `0xfe000000` -> PA `0x50000000`, len `0x2000`, type 0 (L2X0) | VERIFIED (image bytes + `l2x0_init` call) |
| type 0 == `MT_DEVICE` (device/uncached) | value VERIFIED; enum name INFERRED (2.6.35 `mach/map.h`) + behavioural cross-check |
| All four queried ranges are covered by entry 1; no other delta exists | VERIFIED |
| BIM base `0xfd008000`; groups `0x30/0x34/0x38`, `0x138/0x13c/0x140`, `0x154/0x158/0x15c`; virq = 32*g + bit | VERIFIED (`kernel_decode_irqmap.py`) |
| SATA port virq = 53 -> group 1 bit 21 | VERIFIED (module `ata_host_activate` argument) |
| FE/SVOIF virq = 18 -> group 0 bit 18 | VERIFIED (module `ata_host_activate` + `disable_irq` argument) |
| virq 52 = group-1 bit 20 cascade into `0xfd024000` (+0x140/+0x144, virqs 96..127) | VERIFIED (`__irq_svc`, `mt85xx_unmask_irq`) |
| The model implements no SATA/FE line | VERIFIED (`sony-bx510.c`) |
| Model IO region is 4 MiB vs the kernel's 16 MiB map | VERIFIED |
| FIFO accesses are invisible under `-d unimp` | VERIFIED (model `LOG_GUEST_ERROR` + probe `-d unimp`) |
| `0xfd05c704` not executed in the C50-family runs | VERIFIED (unimplemented register absent from a `-d unimp` log with zero unassigned accesses) |
| Nothing can be asserted from the absence of `0xfd324180`/`0xfd00a000` in these logs | VERIFIED (both are implemented; FIFO logs at `LOG_GUEST_ERROR`, ATA regs log nothing) |
| The SATA reset path will hit unassigned memory at `0x70060004`/`0x700903xx` once it runs | INFERRED (geometry verified; path not yet observed) |

## 9. Reproduction

```bash
cd evidence/bx510-guest/bdpdrv/decode
python3 kernel_decode_image.py \
    ../../u4-initrd/pulled/kernel.uImage /tmp/kdec          # uImage -> vmlinux.bin
python3 kernel_decode_kallsyms.py /tmp/kdec/vmlinux.bin \
    > /tmp/kdec/kallsyms.txt                                # -> nm listing
python3 kernel_decode_dis.py --prep                         # ELF wrapper for objdump
python3 kernel_decode_iomap.py                              # map_desc table + coverage
python3 kernel_decode_irqmap.py                             # BIM groups + driver IRQs
python3 kernel_decode_dis.py --sym mt85xx_map_io            # annotated disassembly
python3 kernel_decode_dis.py --sym __irq_svc
```

`kernel_decode_dis.py` resolves literal-pool words to their **values** (symbol, IO VA,
or physical base), because a pool slot is exactly where a fake-looking register address
hides: the module's `.init.text+0xb6c` "looks like" a branch until its `add r1,r1,#53`
is read.
