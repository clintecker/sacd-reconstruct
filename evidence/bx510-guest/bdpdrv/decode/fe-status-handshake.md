# BX510 FE status handshake — `sata_mt85xx_chk_int_ldr` decode, `port_start` state machine, and the model's FE reply

Decode of the front-end (FE) internal-loader **status mailbox** handshake: what
`sata_mt85xx_chk_int_ldr` reads, what it accepts, who calls it and with what
retry bounds, why the rig hangs in a `0x7005c804` write storm, and the minimal
register/byte set the QEMU model must return to get past it.

**Module under decode (pinned, re-verified):**

| field | value |
|---|---|
| path | `/tmp/bdpdrv/sata_mt85xx_mod.ko` (staged from the guest `/res/shim/`) |
| size | 69,452 B |
| sha256 | `8a0253eb9bff19a3d3c0ac594a507235bad82348d8e80069024368d0f5456657` |
| build | ARM EABI5, `ET_REL`, Linux 2.6.35 (`sata_mt85xx.c`), not stripped |
| function | `sata_mt85xx_chk_int_ldr` = `.text+0x2810`, size `0x294` (660) |

All instruction addresses are **section-relative** (`st_value`; every section
has `sh_addr = 0`). Cite as `.text+0x…`. MMIO addresses are given as the
driver's kernel VA (`0xfd05c…`) with the physical address (`0x7005c…`) in
parentheses — the `0xfd000000..0xfdffffff` → `0x70000000..` section mapping is
`kernel-iomap.md` §2.

**Method.** Two independent decoders agree on every instruction cited below:
`decode/sata_decode_dis.py` (llvm-objdump + mechanical literal-pool/relocation
join) and a `capstone` pass that recomputes each `[rN, #-imm]` MMIO offset
against the literal `0xfd05cfff`. The `.rodata` strings are read straight out
of the ELF. No hexdump was eyeballed.

**Companion artifact:** `decode/fe_reply_bytes.py` — emits the reply words
below as C initialisers and replays the driver's own compare instructions
against them (23 checks: 16 on the reply, 7 mutants that must fail; `PASS`).
Run it (`make sacd-py
SCRIPT=evidence/bx510-guest/bdpdrv/decode/fe_reply_bytes.py`) after any change.

---

## 1. Bottom line

1. **`chk_int_ldr` owns exactly five FE registers**: the interrupt/status word
   `0xfd05c804` (bit 16 = "an FE message is pending", `.text+0x28a4/0x28ac`)
   and the four-word **status block** `0xfd05c040 / c044 / c048 / c04c`
   (`.text+0x28b8/0x28c0/0x28cc/0x28d8`). Nothing else in the FE space. *(The
   earlier reading in the task brief — `0x7005c841/45/49/4d` — is off by one
   byte; both decoders, and the independent reader
   `_sata_mt85xx_svoif_interrupt_handler` at `.text+0x4640..0x465c`, put the
   block at `0x…c040`.)*
2. **The status block is a 4-word message**: `w0` = `{byte3 = code/err,
   byte2 = message type, byte1..0 = unused}`, `w1` = **DRAM offset**, `w2` =
   **length**, `w3` = unused. Two readers of the block in the module
   (`chk_int_ldr` polled, `_sata_mt85xx_svoif_interrupt_handler`
   interrupt-driven) test *the same* byte 2 and byte 3 — an independent
   confirmation of the field layout.
3. **The 0x528 buffer is NOT filled from the status words.** It is filled only
   by the `type == 16` branch: `memcpy(buf, *svoif_int_ldr_dram + w1,
   min(w2, 512))` (`.text+0x291c..0x2960`). On the `type == 0` path the buffer
   still holds whatever `kmem_cache_alloc` returned — the allocator is not a
   zeroing one, so the acceptance gate runs on **undefined memory** unless the
   FE first hands over a table block.
4. **The gate on that block** (`.text+0x299c..0x2a38`) wants `buf[0x2e..0x31] =
   'O','B','T','O'` (four byte compares, **not** ASCII `"BOOT"`) and
   `LE16(buf[0x100]) == 0xeeee` ("manufacture mode"). Return value = byte 3 of
   `w0` (0 = accepted); `*out` (`arg1`, a pointer to `port+0x208`) = 1 only
   when the `0xeeee` word is present.
5. **Nothing in the caller retries.** `port_start` calls `chk_int_ldr` once
   (state-1 fast path, `.text+0x32c8`) or twice (ATAPI-signature probe path,
   `.text+0x32f8` / `.text+0x3314`) — never in a loop, and every internal poll
   is bounded (200 × `msleep(10)` = 2 s). **The 4.4 GB `0x7005c804` storm is
   the FE IRQ top half** `svoif_mt85xx_interrupt`, whose
   read-and-clear drain loop (`.text+0x34b4..0x34c8`, no sleep, exits only on a
   **zero read**) cannot terminate against the model's constant
   `return fe_booted ? 0x10000 : 0`. The logged value (`= 0x10000`, exactly the
   raw read at `.text+0x34c0`) and the write rate both fit; the driver's own
   poll loops fit neither.
6. **The minimal model reply is three things**: bit16 scoped to "a message is
   pending" (and **0 once drained**), a two-message sequence `[type 16 → type 0]`
   per `chk_int_ldr` call, and one 512-byte block DMA'd into the FE DRAM window
   carrying 6 non-zero bytes. §7 has the table; §9 has the byte-by-byte
   justification and the C snippet.

---

## 2. The FE mailbox register block (`0xfd05c0xx`)

Both directions of the same mailbox are visible in the module. Everything is
VERIFIED from the cited instructions unless marked otherwise.

| VA (PA) | role | evidence |
|---|---|---|
| `0xfd05c000/04/08/0c` (`0x7005c000…`) | 16-byte **CPU→FE command block** (4 words) | stores in `_svoif_mt85xx_send_ata_cmd` `.text+0x3b18/3b20/3b28/3b30` and `_svoif_mt85xx_send_table_data_ack_cmd` `.text+0x3c68…3c80` |
| `0xfd05c020` (`0x7005c020`) | **doorbell**: read-modify-write `|= 1` after the command block | `.text+0x3b54/0x3b60`, `.text+0x3ca8/0x3cb4` |
| `0xfd05c040/44/48/4c` (`0x7005c040…`) | 16-byte **FE→CPU status block** (this document) | `chk_int_ldr` `.text+0x28b8…28d8`; `_sata_mt85xx_svoif_interrupt_handler` `.text+0x4640…465c`; `port_start` log `.text+0x3394` |
| `0xfd05c500` (`0x7005c500`) | **FE DRAM-window page number** = `(phys_base >> 22) & 0xff` | `xfer_int_ldr_fw` `.text+0x192c..0x1940` (`lsr/and` then `str [r3,#-0xaff]`) |
| `0xfd05c600/604` (`0x7005c600/604`) | `|= 0x00808080`, `|= 0x80` (DRAM wrapper) | `.text+0x1944..0x1958` |
| `0xfd05c704` (`0x7005c704`) | `|= 0x601` = **FE reset release**; `& 0x601 == 0x601` = booted | `.text+0x1998..0x19a4`, `.text+0x19dc..0x19e4`, `.init.text+0x224` |
| `0xfd05c780` (`0x7005c780`) | `|= 0x103` | `.text+0x19cc..0x19d8` |
| `0xfd05c800` (`0x7005c800`) | interrupt **enable/mask** register (read by the top half as the mask, `.text+0x34b0`; `port_start` writes `0xfffffff0` = clear-all, `.text+0x32d8`) | |
| `0xfd05c804` (`0x7005c804`) | interrupt **status**, read-and-clear; **bit16 = FE message pending** | `chk_int_ldr` `.text+0x28a4/0x28b0`; `port_start` `.text+0x3260/0x327c`; `svoif_mt85xx_interrupt` `.text+0x34b4/0x34c0` |
| `0xfd05c808` (`0x7005c808`) | extra status word folded into the wake payload (`(extra) \| (bit16<<8)`) | `.text+0x34f8..0x350c` |
| `0xfd05c180/184` (`0x7005c180/184`) | FE SRAM FIFO pointer/data (boot-code download) | `init_int_ldr`, `xfer_int_ldr_aacs_data` — see `sram-readback-live.md` |

Command-block and status-block share one **byte layout**: `byte3` = code,
`byte2` = message type. That is why the same 16-byte struct serves both
directions:

| sender | word0 byte3 | word0 byte2 | meaning |
|---|---|---|---|
| CPU, `.text+0x2858` (`chk_int_ldr`) | `0xa1` | 0 | ATA **IDENTIFY PACKET DEVICE** → status request |
| CPU, `.text+0x3c58` (ack helper) | 0 | `0x10` | table-data **ACK** |
| CPU, `.text+0x4f70` (`softreset`) | `0x08` | 0 | ATA DEVICE RESET |
| CPU, `.text+0x51c8` (`prereset`) | `0xf7` | 0 | ATA SET FEATURES |
| FE → CPU | error code | `0x10` | table data available in DRAM at `(w1, w2)` |
| FE → CPU | `0` | `0` | status/idle — inspect the last table block |
| FE → CPU | ≠0 | `0` | command error: `[IDE]<%s>Command Error !!(0x%02x, 0x%06x)` = `(byte3, w1)` |

`0xa1` is sent from exactly one place (`R_ARM_CALL _svoif_mt85xx_send_ata_cmd`
at `.text+0x2878`; the other two call sites send `0x08` and `0xf7`), so
**`word0 >> 24 == 0xa1` is the model's "a `chk_int_ldr` call starts here"
trigger.**

---

## 3. `sata_mt85xx_chk_int_ldr` — full flow

Argument registers, as they actually arrive from `port_start`
(`mov r0,r5; add r1,r5,#520` at `.text+0x32bc/0x32c4`):

* `r0` = **port struct** (`r6`; offsets `+0x280..0x29c` = ATA taskfile mirror,
  `+0x22c/+0x230` = interrupt accumulator, `+0x4` = channel index)
* `r1` = **`int *out` flag**, i.e. `port + 0x208` — written with 0 or 1,
  never read as a buffer (`.text+0x29c8/0x29cc`, `.text+0x29e8/0x29ec`).
  `port+0x208` is read later by `sata_mt85xx_data_xfer` (`.text+0x55dc`:
  `if (port->[0x208] != 0 && cmd == 18) …`), so the flag does have a
  downstream consumer.

The function is `sata_mt85xx_id_atapi_dev` **inlined** into
`sata_mt85xx_chk_int_ldr` — its `__func__` string is
`.rodata+0x8c = "sata_mt85xx_id_atapi_dev"`, used by every printk inside.
(Second instance of the pattern documented in `sata-fw-load.md` §2.)

### 3.1 Prologue and the acceptance buffer (`.text+0x2810..0x2858`)

```
0x2810 push {r4-r11,lr}; sub sp,#60
0x2818 mov  r6, r0                     ; r6 = port
0x281c str  r1, [sp,#0x10]             ; save &out
0x2820 ldr  r0, =kmalloc_caches+0x528  ; compiler-inlined kmalloc(cache)  <- §8
0x2824 mov  r1, #0xd0                  ; GFP_KERNEL
0x2828 bl   kmem_cache_alloc
0x282c cmp  r6, #0                     ; port == NULL ?  -> -1 (after free)
0x2830 add  r8, sp, #0x18              ; r8 = &w[0] (the 4 status words)
0x2834 add  r10, r0, #15
0x2838 mov  r9, r0                     ; r9 = raw pointer (for kfree)
0x283c bic  r10, r10, #15              ; r10 = 16-byte-aligned buffer
0x2840 beq  0x28fc                     ; NULL port -> mvn r4,#0; kfree; return -1
0x2844 ldr  r4, =0xfd05cfff            ; register base for the mailbox
0x2848 ldr  r11, =ide_log_en
0x284c mov  r3, #0
0x2850 mov  r2, #0xa1                  ; ATA_CMD_ID_ATAPI
0x2854 mov  r5, r4
0x2858 str  r2, [r6,#0x29c]            ; port->cmd = 0xa1
0x285c..0x2870 str r3,[r6,#0x280..0x294]   ; zero the 6 taskfile words
0x2874 mov  r0, r6
0x2878 bl   _svoif_mt85xx_send_ata_cmd ; post the command block + doorbell
```

### 3.2 Message loop (`.text+0x2880..0x2978`)

```
0x2880 mov r3,#0; mov r6,r3; mov r7,r3  ; r6 = interrupt accumulator, r7 = i
0x288c b   0x28a4
--- poll: exit as soon as bit16 is seen, bounded at 200 x 10 ms ---
0x28a4 ldr  r3, [r4,#-0x7fb]     ; r3 = *(u32*)0xfd05c804
0x28a8 orr  r6, r6, r3           ; r6 |= status
0x28ac tst  r6, #0x10000         ; bit16 = FE message pending
0x28b0 str  r6, [r4,#-0x7fb]     ; write back = clear the bits just read
0x28b4 beq  0x2890               ; not yet -> msleep(10); ++r7; if r7==200 -> 0x297c
--- take the message ---
0x28b8 ldr  r3, [r5,#-0xfbf]     ; w0 = *(u32*)0xfd05c040  -> [sp+0x18]
0x28c0 ldr  r0, [r5,#-0xfbb]     ; w1 = 0xfd05c044         -> [sp+0x1c]  (DRAM off)
0x28cc ldr  r3, [r5,#-0xfb7]     ; w2 = 0xfd05c048         -> [sp+0x20]  (length)
0x28d8 ldr  r1, [r5,#-0xfb3]     ; w3 = 0xfd05c04c         -> [sp+0x24]  (unused)
0x28c4 ldrb r2, [r8,#2]          ; type = byte2(w0)
0x28e0 bne  0x2914               ; type != 0 -> the type-16 branch
0x28e4 ldrb r2, [r8,#3]          ; err = byte3(w0)
0x28ec beq  0x299c               ; err == 0 -> acceptance gate
0x28f0..0x28f8                   ; err != 0 + logging -> 0x2a64 Command Error
0x28fc mvn  r4,#0; mov r0,r9; bl kfree; mov r0,r4; return -1
--- type 16: table data available in DRAM at (w1, w2) ---
0x2914 cmp  r2,#16
0x2918 bne  0x2880               ; any other type -> poll again (no progress!)
0x291c ldr  r1,=svoif_int_ldr_dram   ; r6 = *(u8**)&svoif_int_ldr_dram
0x2924 cmp  r3,#512              ; r3 = w2
0x2928 movlo ip, r3              ; n = min(w2, 512)
0x292c movhs ip, #512
0x2930 ldr  r6, [r1]
0x2938 add  r6, r6, r0           ; src = dram + w1
0x294c bl   BSP_FlushDCacheRange(src, n)     ; the FE DMA'd this region
0x2960 bl   memcpy(r10 /*buf*/, r6, n)
0x2968 bl   _svoif_mt85xx_send_table_data_ack_cmd(port)   ; ack -> next message
0x296c ldrb r3,[r8,#2]; cmp r3,#0; bne 0x2880             ; loop for the next
0x2978 b    0x28fc                                       ; (unreachable: type != 0)
--- poll timeout ---
0x297c..0x2998 printk "[IDE]<%s>wait status interrupt timeout !"; return -1
```

**Consequence that decides the model design:** a `chk_int_ldr` call consumes
messages until it sees one with `type == 0`, and each `type == 16` message costs
one DRAM copy plus one ACK. It never fills `r10` any other way, and it never
looks at `r10` on the `type == 16` path. So a reply of "only type 0" inspects
*uninitialised allocator memory*, and a reply of "type 16 forever" never
returns (the `0x2918`/`0x2974` loop restarts at `0x2880` with `r7 = 0`, so even
the 2 s poll bound is reset every iteration).

### 3.3 Acceptance gate on the copied block (`.text+0x299c..0x2a38`)

```
0x299c ldrb r3, [r10,#0x2f]
0x29a0 mov  r4, r2               ; return value := err (== 0 on this path)
0x29a4 cmp  r3, #66              ; 'B'
0x29a8 beq  0x29f4
0x29ac mvn  r4, #0               ; reject
0x29b0 ldrb r2, [r10,#0x101]     ; length = buf[0x100] | buf[0x101]<<8   (LE16)
0x29b4 ldrb r3, [r10,#0x100]
0x29b8 add  r2, r3, r2, lsl #8
0x29bc ldr  r3, =0x0000eeee      ; literal at .text+0x2a90
0x29c0 cmp  r2, r3
0x29c4 ldrne r2,[sp,#0x10]; movne r3,#0; strne r3,[r2]   ; *out = 0
0x29d0 bne  0x2900                                       ; kfree; return r4
0x29e0 bne  0x2a34               ; logging on -> printk "…manufacture mode !!…" (0x2a34/0x2a38)
0x29e4 ldr  r1,[sp,#0x10]; mov r3,#1; str r3,[r1]        ; *out = 1
0x29f0 b    0x2900                                       ; kfree; return r4
--- the 'B' branch ---
0x29f4 ldrb r3,[r10,#0x2e]; cmp r3,#79   ; 'O'   0x29fc bne 0x29ac
0x2a00 ldrb r3,[r10,#0x31]; cmp r3,#79   ; 'O'   0x2a08 bne 0x29ac
0x2a0c ldrb r3,[r10,#0x30]; cmp r3,#84   ; 'T'   0x2a14 bne 0x29ac
0x2a28..0x2a2c printk "[IDE]Internal loader boot code mode"   ; string .rodata.str1.4+0xa58
```

So the block must contain, at byte offsets **0x2e..0x31**, the bytes
`4F 42 54 4F` (`'O','B','T','O'`) and at **0x100..0x101** the little-endian
halfword `0xEEEE`.

> **The magic is not the string `"BOOT"`.** The four compares are
> `0x2f=='B'`, `0x2e=='O'`, `0x31=='O'`, `0x30=='T'` — i.e. each adjacent pair
> is swapped. That is exactly what a big-endian producer writing the two 16-bit
> halfwords `'B','O'` and `'O','T'` looks like when the CPU reads them
> little-endian (VERIFIED from the instructions; the "16-bit halfword" reading
> of *why* is INFERRED). `fe_reply_bytes.py` carries a mutant that fails when
> the block is written as ASCII `"BOOT"` — the naive reading does not pass.
>
> `0xeeee` is the "manufacture mode" marker (`printk` at `.text+0x2a34`,
> string `.rodata.str1.4+0xa80`), and it is what makes `*out = 1`. Length
> floors: `n >= 0x32` for the return code (the four magic bytes), `n >= 0x102`
> for `*out = 1`.

### 3.4 Return value / side effects

| path | return | `*out` (port+0x208) |
|---|---|---|
| poll timeout (2 s) | `-1` | untouched |
| `type ∉ {0,16}` | — never returns (loops at `0x2880`) |
| `type == 16` | — continues the loop after the copy + ACK |
| `type == 0`, `err != 0` | `-1` | untouched |
| `type == 0`, `err == 0`, no magic | `-1` | `0` |
| `type == 0`, `err == 0`, magic, no `0xeeee` | `0` | `0` |
| `type == 0`, `err == 0`, magic + `0xeeee` | **`0`** | **`1`** |

---

## 4. Who calls it, and with what retry loop

`R_ARM_CALL sata_mt85xx_chk_int_ldr` occurs **three** times in the module, all
inside `sata_mt85xx_port_start` (`.text+0x2fac`, size 0x4a8). They are on **two
mutually exclusive paths**, so one `port_start` invocation runs one or two of
them, never three:

```
port_start(host):
  0x2fb8..0x2fcc  r5 = port struct (r3 = host[0x1dfc]; r5 = [r3,#0xc])
  0x2fd4          if (port->[0x8] == 1)  -> 0x3230        ; "state == 1" fast path
  ------------------------------------------------------------------ probe path
  0x2fe0..0x3080  program the ATA/PHY windows
  0x30ec..0x3110  poll 0xfd00a610: (v>>16)&0x3f == 55 ('FE link up'), 50 x 10 ms
  0x3144..0x3168  poll 0xfd00a01c: v in {0x50, 0}, 2500 x 10 ms
  0x316c..0x31bc  printk "ch:%d, i=%d, st=0x%x, signature=0x%x"
  0x31c0          if (!reset_poll_ok) -> 0x31c8            ; the shared tail
  0x32e0          if (signature != 0x00eb1401 /*ATAPI*/) -> 0x31c8
  0x32f8          chk_int_ldr(port, &port->[0x208])        ; call #2  (RET is checked)
  0x32fc          if (ret != 0) -> 0x31c8                  ; skip the FW download
  0x3308          xfer_int_ldr_fw(port->[0x4])
  0x3314          chk_int_ldr(port, &port->[0x208])        ; call #3  (RET ignored)
  0x3318          b 0x31c8
  ------------------------------------------------------- state == 1 fast path
  0x3230..0x3234  if (*(u32*)(.bss+0x80) != 0) -> 0x32b0
  0x3244..0x3278  poll 0xfd05c804: v != 0 && (v & 0x10000), 150 x 10 ms,
                  clearing what it reads;  on timeout: 0x3290
  0x3290          if (timed_out && *(.bss+0x80) == 0) -> 0x335c (-EIO exit)
  0x32b0          xfer_int_ldr_aacs_data(port)             ; the AACS download
  0x32b4          _fg_fe_bootup = 1
  0x32c8          chk_int_ldr(port, &port->[0x208])        ; call #1  (RET ignored)
  0x32d8          *(u32*)0xfd05c800 = 0xfffffff0           ; clear all FE interrupts
  0x32dc          b 0x321c                                 ; return 0
```

Answered directly:

* **which call is pre-AACS vs post-AACS** — call #1 (`.text+0x32c8`) is the
  **post-AACS** one (AACS download at `0x32b0`, `_fg_fe_bootup = 1` at
  `0x32b4`). Calls #2/#3 (`.text+0x32f8`, `.text+0x3314`) are the
  **probe-path** pair, with `xfer_int_ldr_fw` between them; neither involves
  AACS. The rig reaches call #1 — the log sequence "bit16 poll passed → AACS →
  `_fg_fe_bootup=1` → `chk_int_ldr`" is exactly `.text+0x3244 → 0x32b0 →
  0x32b4 → 0x32c8`.
* **what makes the caller retry forever** — *nothing in the caller*. `port_start`
  contains no loop around any `chk_int_ldr` call; each call has its own bounded
  internal poll (`.text+0x289c`: `cmp r7,#200`), and the caller's own polls are
  bounded too (50, 2500, 150 iterations). `-EIO` exits are at `.text+0x335c`
  and the shared `.text+0x33f4`. The two ways this handshake can fail to
  terminate are (a) the caller's *return values* send it to the shared tail
  early — a silent skip, not a hang; and (b) `chk_int_ldr`'s own message loop
  (`0x2880`) if the FE keeps posting a type it will never finish with. **The
  observed storm is neither** — see §5.

---

## 5. The `0x7005c804` storm — which loop it is

Three code sites write that register:

| site | loop bound | writes/s ceiling |
|---|---|---|
| `chk_int_ldr` `.text+0x28b0` | 200 iterations, each preceded by `msleep(10)`; exits the same iteration bit16 is seen | ≤ 100/s, ≤ 200 per call |
| `port_start` `.text+0x327c` | 150 iterations, `msleep(10)` | ≤ 100/s, ≤ 150 per boot |
| `svoif_mt85xx_interrupt` `.text+0x34b4..0x34c8` | **none** — `ldr; and; cmp; str; orr; bne`, no sleep, no counter; terminates **only when the read returns 0** | unbounded (TCG tight loop) |

```
svoif_mt85xx_interrupt (top half, .text+0x346c, IRQs off via cpsid i at 0x3488)
  0x34b0 ldr  lr, [r3,#-0x7ff]      ; lr = *(u32*)0xfd05c800   (enable mask)
  0x34b4 ldr  r3, [r1,#-0x7fb]      ; r3 = *(u32*)0xfd05c804   <- the storm read
  0x34b8 and  r12, r3, lr
  0x34bc cmp  r3, #0
  0x34c0 str  r3, [r1,#-0x7fb]      ; write back = clear (W1C)
  0x34c4 orr  r2, r2, r12
  0x34c8 bne  0x34b4                ; <-- exits only on a ZERO read
```

The model currently answers that read with `return s->fe_booted ? 0x10000 : 0`
(`emulator-kit/sony-bx510.c` `case 0x5c804`), i.e. a **constant** non-zero
value that no write can clear (the write path has no `0x5c804` case at all, so
it lands in `default:` → `LOG_UNIMP`). The loop therefore never ends, and each
iteration emits exactly one

```
bx510: unimplemented write 0x7005c804 = 0x10000
```

which is the observed 4.4 GB of log (`sram-readback-live.md` §6 "still open").
The logged value matches the mechanism exactly: `0x10000` is the raw read value
stored back at `.text+0x34c0` with no accumulation.

**Why the storm starts after `port_start` and not before.** The FE IRQ pending
bit is set by the model on the `0x5c704 |= 0x601` write, which the driver does
inside `xfer_int_ldr_fw` (`.text+0x1998..0x19a4`) — during module init and
again on the probe path. The FE handler is registered by `ata_host_activate`
(external; `R_ARM_CALL ata_host_activate` at `.init.text+0xb6c` and `0xb90`),
and libata's `ata_host_activate` calls `->port_start` **before**
`devm_request_irq`. So during `port_start` the pending line is harmless; the
moment the handler is installed the line is already asserted, the top half
enters, and it never leaves. (Registration ordering: INFERRED from libata
2.6.35 — it is not visible inside this module. Everything else in this section
is VERIFIED from instructions + model source + the log's own value.)

**Two design consequences**, both mandatory for the reply in §7:

1. `0x7005c804` bit16 must be **message-scoped**, not permanent: present while
   a message is pending, **0 once the sequence is drained**. A latched bit that
   no write clears re-arms the same hang even after a successful handshake.
2. `chk_int_ldr`'s message loop must be given a sequence that *ends* on
   `type == 0`; a repeating `type == 16` (or any other type) resets the poll
   counter at `0x2880` and loops forever inside a single call — the second,
   independent storm path, available even without the IRQ.

---

## 6. Where the reply block comes from (and why the model must DMA it)

`*svoif_int_ldr_dram` is an external pointer (another module) to the internal
loader's DRAM window; `svoif_int_ldr_dram_sz` is its size. `xfer_int_ldr_fw`
fills that window from the staged firmware image (`memcpy(dram + sec.f0, fw +
sec.len, sec.size)` at `.text+0x1844..0x18e4`) and then tells the FE where it
is:

```
0x191c ldr r2, =mt85xx_svoif_reserve_base ; (remap variant)
0x192c lsr r4, r1, #22
0x1930 and r4, r4, #255
0x1940 str r4, [r3,#-0xaff]              ; *(u32*)0xfd05c500 = (phys >> 22) & 0xff
```

(the non-remap variant at `.text+0x1aa4` does the same with
`*svoif_int_ldr_dram + 0x40000000`, the channel-A DRAM alias). So the FE is
handed a **4 MB-granular physical page number** and writes its replies into
that window; `w1` of a `type == 16` message is an offset *inside* it, and the
CPU flushes the D-cache range before copying (`0x294c`) because the block
arrived by DMA, not by cache-coherent bus writes.

The interrupt-driven twin of this copy makes the direction explicit by memcpy
argument order (`_sata_mt85xx_svoif_interrupt_handler` `.text+0x47ac..0x48dc`):
`port->[0x48] == 1` → `memcpy(port->[0x4c], dram + w1, min(port->[0x54], w2))`
(`.text+0x4878`); `== 2` → `memcpy(dram + w1, port->[0x4c], …)`
(`.text+0x48bc`). `chk_int_ldr` implements only the first direction, with a
hard-coded `512` clamp instead of `port->[0x54]`.

**Model consequence:** nothing in guest RAM holds the reject-free block until
something puts it there. The model has to write the 512 bytes to
`phys = ((*(u32*)0x7005c500 & 0xff) << 22) + w1` when it posts message A —
playing the FE's DMA role. (The alternative — pointing `w1` at fixture content
that happens to carry the magic — couples the model to the fixture image and is
rejected for that reason.)

---

## 7. The model reply — register → value table

Ordered per `chk_int_ldr` call. `FE` = the model's FE state. All values written
as one 32-bit little-endian read.

| # | address (PA) | returned value | why (VERIFIED unless marked) |
|---|---|---|---|
| 1 | `0x7005c804` while a message is pending | `0x00010000` | `tst r6,#0x10000` `.text+0x28ac`; `port_start` also needs "non-zero + bit16" at `.text+0x3264/0x3278` |
| 1' | `0x7005c804` when the sequence is drained | `0x00000000` | `cmp r3,#0 / bne` drain loop `.text+0x34bc/0x34c8` — **mandatory**, else §5's hang |
| 2 | `0x7005c040` — message A word 0 | `0x00100000` | byte2 = `0x10` → `cmp r2,#16` `.text+0x2914` |
| 3 | `0x7005c044` — message A word 1 | `0x00001000` | `src = dram + w1` `.text+0x2938`; any in-window offset works (see §9) |
| 4 | `0x7005c048` — message A word 2 | `0x00000200` | `n = min(w2, 512)` `.text+0x2924..0x292c`; must be `>= 0x102` |
| 5 | `0x7005c04c` — message A word 3 | `0x00000000` | read into `[sp+0x24]` (`.text+0x28d8`) and never used again |
| 6 | `0x7005c040` — message B word 0 | `0x00000000` | byte2 = 0 (`.text+0x28d0/0x28e0`) **and** byte3 = 0 (`.text+0x28e8/0x28ec`); byte3 is also the return value (`.text+0x29a0`) |
| 7 | `0x7005c044/c048/c04c` — message B | `0x00000000` ×3 | unread on this path |
| 8 | *DRAM* window `+0x1000`, 512 B | only 6 non-zero bytes: `[0x2e]=0x4f [0x2f]=0x42 [0x30]=0x54 [0x31]=0x4f [0x100]=0xee [0x101]=0xee` | `.text+0x29a4/0x29f8/0x2a04/0x2a10` and `.text+0x29b0..0x29c0` |

Sequencing the model needs (all five fields are new; none exists in
`sony-bx510.c` today):

```c
/* command block 0x5c000..c00c + doorbell 0x5c020 (bit0) + status 0x5c040..c04c */
uint32_t fe_cmd0;        /* last write to 0x7005c000 */
uint32_t fe_dram_pgn;    /* last write to 0x7005c500: (phys>>22)&0xff */
int      fe_msg;         /* 0 = A next, 1 = B next, >= 2 = drained */
```

* write `0x5c000` → `fe_cmd0 = val`
* write `0x5c020` with bit0 set (doorbell):
  * `(fe_cmd0 >> 24) == 0xa1` → **`chk_int_ldr` entry**: `fe_msg = 0`, post
    message A (and DMA the block if `fe_dram_pgn` is known)
  * `(fe_cmd0 >> 16) & 0xff) == 0x10` → **table-data ACK**: `fe_msg = 1`
* read `0x5c040/44/48/4c` → `word(fe_msg)` (message B once `fe_msg >= 1`)
* read `0x5c804` → `(fe_msg < 2) ? 0x00010000 : 0` — derived, so it drains by
  construction. If a later stage needs the FE IRQ live *while* a message is
  pending, switch to a latched `fe_irq` cleared by a write of bit16 to
  `0x5c804` (that is the hardware contract at `.text+0x34c0`); the derived form
  is the smallest thing that cannot storm.

Two `chk_int_ldr` calls in one `port_start` (probe path) get the same pair
again, because each call re-sends `0xa1`.

---

## 8. The allocation at `.text+0x2820` (question 5)

```
0x2820 ldr r0, [pc,#0x250]   ; literal .text+0x2a78 = 0x00000528
                             ;   R_ARM_ABS32 kmalloc_caches  ->  &kmalloc_caches + 0x528
0x2824 mov r1, #0xd0         ; GFP_KERNEL (2.6.35: __GFP_WAIT|__GFP_IO|__GFP_FS)
0x2828 bl  kmem_cache_alloc  ; (relocation R_ARM_CALL kmem_cache_alloc)
```

This is **not** a direct `kmem_cache_alloc` call: it is the compiler-inlined
`kmalloc(<const size>, GFP_KERNEL)` fast path, which expands to
`kmem_cache_alloc(kmalloc_caches[index], flags)`. The literal carries the
*byte offset into the cache array*, not the size. The module's other inlined
sites pin the array stride: the only distinct offsets anywhere in the module
are `0x294` (`.text+0x23e8`, `.text+0x26ec`, `.init.text+0xd68`), `0x528`
(`.text+0x2a78`, this one) and `0x5ac` (`.text+0x2e04`, `.text+0x7fe4`) —
`660 / 1320 / 1452 = 5 / 10 / 11 × 0x84`, i.e. `sizeof(struct kmem_cache) =
0x84` in this build and cache slots 5, 10 and 11 in use. Under the 2.6.35
kmalloc index ladder, slot 10 is the ≤1 KiB class and slot 11 the ≤2 KiB
class, so the request is somewhere in 1025..2048 bytes (most likely the 1320
coincidence, but the exact request size is not recoverable from the instruction
and does not matter). **INFERRED: request ≈ 1320 B; VERIFIED: 16-byte-aligned
destination (`bic r10,r10,#15`) and the buffer is not zeroed.**

What *is* verified about the size, and is what the reply depends on: the driver
reads `buf[0x2e..0x31]` and `buf[0x100..0x101]`, so the object is ≥ `0x102`
bytes and, being a `kmem_cache_alloc` result, its content is **undefined** —
i.e. the acceptance gate at `0x299c` cannot pass by luck, and cannot pass at
all without the `type == 16` copy.

`cmp r6, #0` at `.text+0x282c` (relocation address `.text+0x2828` is the
`bl`): `r6 = r0 = arg0 = the port struct`. `NULL` → `beq 0x28fc` → `mvn r4,#0`
→ `kfree(r9)` → return `-1`, i.e. **a null-port guard placed after the
allocation so the alloc/free pair stays balanced**; it never fires in practice
(`port_start` always passes `r5`, a pointer it just dereferenced). It matters
only in that it does *not* gate anything about the FE handshake.

---

## 9. Every reply byte, justified

### 9.1 Status words (6 non-zero bytes of 32, per call)

| byte | value | status | justification |
|---|---|---|---|
| `w0` byte3 (err) of message A | `0x00` | VERIFIED-required | `0xa1`-command status with a non-zero error byte takes the `Command Error !!` branch (`.text+0x28e8`). Also the return value shape. |
| `w0` byte2 (type) of message A | `0x10` | VERIFIED-required | `cmp r2,#16` `.text+0x2914`; `0x10` is the same type byte the driver's own ACK command carries (`.text+0x3c58`). |
| `w0` byte1, byte0 | `0x00` | VERIFIED-unused | neither reader of the block loads them (only `[r8,#2]` and `[r8,#3]` at `.text+0x28c4/0x28e4`, `.text+0x4668/0x4698`). |
| `w1` = `0x1000` (message A) | — | design choice | must be a valid offset in the FE DRAM window whose content the model controls; `0x1000` sits just past the 0x1000-byte BOOT section (`build_fe_fixture.py` tag defaults) and is inside a 2 MiB window. Anything ≥ 0 and `+0x200 <= dram_sz` works. |
| `w2` = `0x200` (message A) | — | VERIFIED-required ≥ `0x102` | `n = min(w2, 512)` at `.text+0x2924..0x292c`; `0x200` is the driver's own clamp (a full block) and keeps the block word-aligned. `0x102` is the true minimum for `*out = 1`, `0x32` for the return code. |
| `w3` (message A) | `0x00` | VERIFIED-unused | stored to `[sp+0x24]` (`.text+0x28d8`) and never read. |
| `w0` of message B | `0x00000000` | VERIFIED-required | byte2 = 0 → the gate (`.text+0x28d0/0x28e0`); byte3 = 0 → no command error **and** the return value `r4 = 0` (`.text+0x29a0`) — port_start's `cmp r0,#0` at `.text+0x32fc` needs that 0 to run `xfer_int_ldr_fw`. |
| `w1/w2/w3` of message B | `0x0` | VERIFIED-unused | only `w1` is used, and only on the `Command Error` log path. |

### 9.2 The DMA'd block (512 bytes, 6 non-zero)

| offset | value | status | justification |
|---|---|---|---|
| `0x2f` | `0x42` `'B'` | VERIFIED-required | `.text+0x29a4 cmp r3,#66` — tested **first** |
| `0x2e` | `0x4f` `'O'` | VERIFIED-required | `.text+0x29f8 cmp r3,#79` |
| `0x31` | `0x4f` `'O'` | VERIFIED-required | `.text+0x2a04 cmp r3,#79` |
| `0x30` | `0x54` `'T'` | VERIFIED-required | `.text+0x2a10 cmp r3,#84` |
| `0x100` | `0xee` | VERIFIED-required for `*out = 1` | `length = buf[0x100] + (buf[0x101]<<8)` `.text+0x29b0..0x29b8`, `cmp 0xeeee` `.text+0x29c0` |
| `0x101` | `0xee` | same | same |
| `0x00..0x2d`, `0x32..0xff`, `0x102..0x1ff` | `0x00` | INFERRED-filler | not read by `chk_int_ldr` at all; zero is what a "no further fields" status block looks like. Kept inside the 512-byte block so `n` has no special-casing. |

### 9.3 Degraded variant, if `*out = 1` ever misbehaves downstream

Dropping the two `0xee` bytes yields `return 0, *out = 0` — `port_start` cannot
tell the difference (`cmp r0,#0` only). `sata_mt85xx_data_xfer` keeps the flag
(`port+0x208`) though: with `*out = 0` it skips the
vendor-string override at `.text+0x5880` (`memcpy` of `.data+0x8a` +
`ata_id_c_string`, for ATA command 18). Recommend the full reply; keep the
variant in the rig's pocket as the first thing to try if INQUIRY output looks
wrong.

---

## 10. Corrections to the brief's working decode

| brief said | decode says |
|---|---|
| status words at `0x7005c841/45/49/4d` | **`0x7005c040/44/48/4c`** (the base literal is `0xfd05cfff`, so `-0xfbf` = `c040`) |
| `r1` = buffer pointer | `r1` = **`int *out`** pointing at `port+0x208`; it is *written* with 0/1, never read as a buffer |
| buffer is 0x528 = `kmalloc(0x528, 208)` | inlined `kmalloc` fast path; `0x528` is the **cache-array byte offset** (`&kmalloc_caches + 0x528`), not the size |
| `cmp r6,#0` = port null check, unclear relevance | null-port guard after the allocation; `-1` return; never fires |
| the 4 status words fill the buffer | they **select and locate** a DRAM block; the buffer is filled by `memcpy(dram+w1, min(w2,512))` in the `type == 16` branch only |
| `cmp #16` = "a msg type?" | yes: **message type `0x10` = "read my table block out of DRAM"**, same byte position as the driver's own ACK command type |
| length field at `[r10+0x100/0x101]` | a little-endian halfword compared to the **constant `0xeeee`** ("manufacture mode") — not a variable length |
| caller retries forever → storm source | caller never retries; the storm is the FE IRQ top half `svoif_mt85xx_interrupt` `.text+0x34b4` (§5) |
| the `0x2e..0x31` magic is `"BOOT"` | it is `'O','B','T','O'` (four separate byte compares; ASCII `"BOOT"` fails the driver) |

---

## 11. Open questions / what is not proven here

1. **The FE IRQ registration instant** (§5) — inferred from libata 2.6.35
   `ata_host_activate` ordering, not visible in this module. Decisive live
   test: `-d unimp` with the log capped, plus a gdbstub breakpoint on
   `.text+0x34b4` (runtime addr = `.text` base + 0x34b4) to catch the first
   entry and read the return address.
2. **The exact `kmalloc` request size** (§8) — the cache-slot index (10 or 11)
   is recovered, the size is not.
3. **`port->[0x48]` / `port->[0x4c]` / `port->[0x54]`** — used by the
   interrupt-driven twin as direction / buffer / dram size. The copy
   directions are VERIFIED from memcpy argument order; the field *meanings* are
   INFERRED. Not needed for the reply.
4. **`w3` and `w0` bytes 0–1** — no reader in the module. Something outside
   this module may interpret them (INFERRED-unused, not proven-unused).
5. **Post-port-up FE traffic.** After `port_start`, the FE mailbox is driven by
   the interrupt path, and `softreset` (`.text+0x4f70`, command `0x08`) and
   `prereset` (`.text+0x51c8`, command `0xf7`) also post commands. The reply in
   §7 covers only the `0xa1` status request; those two currently get no answer
   from the model and will time out. That is the next handshake to decode.

---

## 12. Reproduction

```bash
# annotated listing of the function (literal pool + relocation join)
python3 evidence/bx510-guest/bdpdrv/decode/sata_decode_dis.py \
    --func sata_mt85xx_chk_int_ldr

# independent decoder cross-check: recompute every 0xfd05c0xx effective address
python3 - <<'EOF'
from elftools.elf.elffile import ELFFile
import capstone
d = ELFFile(open('/tmp/bdpdrv/sata_mt85xx_mod.ko','rb')).get_section_by_name('.text').data()
md = capstone.Cs(capstone.CS_ARCH_ARM, capstone.CS_MODE_ARM|capstone.CS_MODE_LITTLE_ENDIAN)
md.detail = True
for ins in md.disasm(d[0x2810:0x2a78], 0x2810):
    for o in ins.operands:
        if o.type == capstone.arm.ARM_OP_MEM and o.mem.disp < 0 and o.mem.base:
            ea = (0xfd05cfff + o.mem.disp) & 0xffffffff
            if 0xfd05c000 <= ea < 0xfd05d000:
                print(hex(ins.address), ins.mnemonic, ins.op_str, '->', hex(ea))
EOF

# the reply set + selftest (23 checks: 16 on the reply, 7 mutants; exit 0 == PASS)
make sacd-py SCRIPT=evidence/bx510-guest/bdpdrv/decode/fe_reply_bytes.py

# the paste-ready C form (compiles clean under -std=c99 -Wall -Wextra)
python3 evidence/bx510-guest/bdpdrv/decode/fe_reply_bytes.py --emit-c
```
