# BX510 FE ATA-command reply protocol — `sata_mt85xx_mod.ko` decode + the C96 model recipe

Decode of the **FE ATA-command channel** (mailbox message format, interrupt/mask
gating, reply-block consumers, and the hw state machine that converts an FE reply
into an ATA status byte), plus the per-register recipe the QEMU FE model needs so
`ata1.00` IDENTIFYs instead of timing out.

**Inputs (pre-extracted; nothing here was produced by scanning a binary):**

| input | role |
|---|---|
| `/tmp/bdpdrv/fe-ata-funcs.dis` | objdump of the 19 relevant functions, 4298 lines, literal pools inline as `.word` |
| `/tmp/bdpdrv/sata.dis` | full module disassembly, used only via `sed` single-function pulls (`port_start`, `tf_load`, `tf_read`, `VSF_FrontEndStatus`, `_set_tx_reg`) |
| `decode/map.txt` | per-function MMIO access map, literal-relative accesses only |
| `decode/fe-status-handshake.md` | the already-modeled `chk_int_ldr` two-message protocol + DRAM-window mechanism |
| `decode/post-aacs-state.md`, `run-c94-c95.md` | C95 runtime facts (13 mailbox posts, zero a-window traffic) |

All instruction addresses are **section-relative** (`.text+0x…`). MMIO addresses are
the driver's kernel VA (`0xfd05c…`), physical (`0x7005c…`) in parentheses.
`0xfd000000..0xfdffffff` → `0x70000000..` ( `kernel-iomap.md` §2).

**Certainty labels.** *DECODED* = a compare/store instruction in the bundle fixes
it. *INFERRED* = consistent with every instruction seen but not closed by one; the
settling experiment is named. The C95 trace is cited only for *values observed*,
never used to fill a static gap.

---

## 0. Bottom line (what changes for C96)

1. **The ATA-command channel and the `chk_int_ldr` channel are the same four
   mailbox words, distinguished only by content, not by address.** `.text+0xa1`
   is used *both* as the chk entry code (`chk_int_ldr` `.text+0x2850/0x2858`) and
   as the ATA command byte `IDENTIFY PACKET DEVICE` (0xa1). The model must key on
   **w1/w2/w3**, not on byte 3 alone. Today it keys on byte 3 → it answers the
   IDENTIFY-PACKET post with the table-data message-A/B sequence, which is the
   wrong protocol for that call site. *(This is defect #1 and it alone explains
   "driver never reads `0x5c040-4c` after cmd#3 in the expected shape".)*
2. **`0x5c800` is an interrupt mask register and the model must return `0x10000`
   in it.** `port_start` writes `0xfffffff0` there (`.text+0x32d0/0x32d8`:
   `mvn r2,#15`), and the FE IRQ top half computes the latched pending set as
   `read(0x5c804) & read(0x5c800)` (`.text+0x34b0..0x34b8`). With the model
   returning 0 for `0x5c800`, every FE message is **drained and discarded**: the
   top half clears `bit16` with its W1C write and never latches it into
   `priv+0x22c`, so the bottom half returns at `.text+0x4628..0x4630` without
   ever touching the status block. *(Defect #2 — this is the exact mechanism of
   the measured "polls `0x5c804`, never reads `0x5c040-4c`" C95 signature.)*
3. **The status byte libata finally sees is synthesised by the driver from a
   hardware-state variable (`priv+0x220`), not read from MMIO** in the executed
   (mailbox/mode-1) path: `check_status` `.text+0x5d1c` branches on
   `priv+0x8 == 1` to `.text+0x5e04`, where the returned status is
   `{4|1 → 0xd0, 2|3 → 0x58, 5 → 0x51, else 0x50}`. Advancing `priv+0x220` is the
   *only* way an FE reply becomes an ATA status. The state advances on a **type-0
   reply with byte3 == 0** (`.text+0x46a4..0x46b8`).
4. **The IDENTIFY payload is delivered through the FE DRAM window, not through a
   mailbox word and not through the a-window.** A `type 0x10` reply whose `w1` is
   the DRAM offset and `w2` the length makes the bottom half
   `memcpy(priv+0x4c, *svoif_int_ldr_dram + w1, min(priv+0x54, w2))`
   (`.text+0x47b4..0x47d8`, `.text+0x4850..0x4884`). The DRAM window itself
   (`0x5c500` page register, `phys = (pgn<<22)+w1`) is already modeled —
   `fe-status-handshake.md` §`.text+0x192c..0x1940`, §7.
5. **Nothing on the executed path touches the `0xa000` a-window** (C95: zero
   accesses in 5.7M lines). That is not an accident of the trace: the whole
   a-window body of `data_xfer`/`send_atapi_cmd`/`exec_command`/`tf_load` is
   guarded by `priv+0x8 == 0` (`data_xfer` `.text+0x5610`, `tf_load`
   `.text+0x3838`, `exec_command` `.text+0x5b54`, `check_status` `.text+0x5d1c`).
   `priv+0x8 == 1` selects the mailbox/shadow-register mode, and that is the mode
   this unit's firmware AACS state puts the driver in.
6. **`w2 = 0xa000` in the C95 post is NOT a window address** (the C95 note's
   reading). Both instruction paths that build that word decode it as
   `{low byte = taskfile lba2 = 0x00, next byte = taskfile device = 0xa0}`, i.e.
   the ATA *device/head* register value `0xA0` (master, LBA) in the upper byte of
   the low halfword. §3.3.
7. **The `0x242xx` poll (12945 reads of `0x2420c`) is the FE/HAL CSR block
   `0xfd024000 + 0x20c`** — `VSF_FrontEndStatus` returns `*(u32*)0xfd024034`
   (`sata.dis` `.text+0x1f4..0x1fc`), so the block is confirmed to be the FE/HAL
   CSR bank. The writer of `0x2420c/210/214/218` is **not attributable to a
   literal in this bundle or in `bdpdrv.ko`'s `.text`** (three independent greps:
   no `0xfd02420c` pool word, no `[rN,#0x20c]` immediate) → INFERRED to be a
   computed-base/table-driven access; §5 gives the model row plus the settling
   experiment.

---

## 1. What `sata_mt85xx_data_xfer` (`.text+0x5434`) actually does

Signature (libata 2.6.35 `ata_port_operations.data_xfer`):
`data_xfer(dev /*r0*/, buf /*r1→r11*/, buflen /*r2→r6*/, rw)`.
Private port struct recovered exactly as `check_status`/`tf_read` do it:
`ap = dev->link->ap` (`.text+0x543c/0x5448`), `priv = *(u32*)(ap + 0x1dfc) + 0xc`
(`.text+0x544c/0x5458/0x5464`).

### 1.1 The mailbox post (DECODED, `.text+0x570c..0x57e8`)

Reached only when `priv+0x8 == 1` (`.text+0x5610/0x561c`) **and** the device is
ATAPI in hw-state 3: `(priv+0x38 - 5) <= 2 && priv+0x220 == 3`
(`.text+0x546c..0x5484`).

```
0x570c  ldrb r3,[r11]              ; r3 = CDB opcode (buf[0])
0x5710  cmp  r3,#0x28 ; cmpne #0xA8 ; READ(10) / READ(12)
0x571c  cmp  r3,#0xBE              ; READ CD
0x5738..0x5768  zero sp+0x48..sp+0x68   (nine words; w0..w3 live at sp+0x48..0x54)
0x576c  ldrb r9,[r4,#0x29c]        ; r9 = FE command code
0x5778  strb r9,[sp,#0x4b]         ; w0 byte3 = code, w0 bytes0..2 = 0
0x577c  ldr  r1,[r4,#0x24]
0x5780  bl   memcpy(sp+0x4c, [r4+0x24], 12)   ; w1,w2,w3 = 12-byte arg block
0x579c..0x57b8  str w0..w3 → 0xfd05c000/004/008/00c
0x57bc  mcr  p15,c7,c10,4          ; dsb (publish before doorbell)
0x57c0  blx  *(outer_cache+0xc)    ; platform cache-maintenance hook (literal 0 → no-op)
0x57d8  ldr  r2,[0xfd05c020]
0x57e0  orr  r2,r2,#1
0x57e4  str  r2,[0xfd05c020]       ; doorbell bit0, read-modify-write
0x57e8  return buflen              ; the FE owns the transfer
```

**Command word layout for `data_xfer` posts (DECODED):**

| word | register | content |
|---|---|---|
| `w0` | `0x5c000` | `byte3 = priv+0x29c` (FE command code), `byte2 = 0`, `byte1..0 = 0` |
| `w1` | `0x5c004` | bytes 0..3 of the 12-byte block at `priv+0x24` |
| `w2` | `0x5c008` | bytes 4..7 of `priv+0x24` |
| `w3` | `0x5c00c` | bytes 8..11 of `priv+0x24` |
| door | `0x5c020` | `\|= 1` (RMW) — "command posted" |

There is **no ATA command byte, no sector count and no DRAM buffer address in
`w0`** — `w0` carries only the code. The command/CDB bytes ride in `w1..w3` as an
opaque 12-byte blob the driver does not re-encode (it is the same 12 bytes an
ATAPI CDB occupies). The only `data_xfer` post path that also arms a data
descriptor is the READ-CDB branch (below).

### 1.2 The READ-CDB descriptor block, `0x5c400..0x5c40c` (DECODED, `.text+0x5800..0x587c`)

Taken for CDB `0x28`/`0xA8`/`0xBE` only:

```
0x5814  str  #1        → 0xfd05c40c          ; direction/arm = 1
0x5838  ldr  r2,[r4,#0x50]; str → 0xfd05c400 ; DMA/host address ([priv+0x50])
0x5840  ldr  r2,[r4,#0x54]; str → 0xfd05c404 ; byte count ([priv+0x54] = remaining)
0x5848  ldr  r2,[0xfd05c408]; orr #0x100; str ; bit8
0x5870  ldr  r2,[0xfd05c40c]; orr #0x600; str ; |= 0x600
        then falls into the mailbox post of §1.1
```

So `0x5c400` = host address, `0x5c404` = length, `0x5c408/40c` = arm/direction
flags. On the executed path these are *written by the driver*, never read back —
the model only has to accept the writes (and, if it chooses to model DMA, may use
them; the reply itself still arrives as a mailbox reply message).

### 1.3 Why the statically-decoded a-window is never touched (DECODED)

Three mutually exclusive modes on `priv+0x8`:

| `priv+0x8` | `data_xfer` | `tf_load` | `check_status` | `exec_command` |
|---|---|---|---|---|
| `0` | a-window: `0xfd00a208`/`a24c`/`a25c`/`a250`, poll `0xfd00a6b8 == 0x200000` (`.text+0x5620..0x56fc`, `.text+0x58d8..0x593c`) | writes taskfile to `ap->ioaddr.X - 0x3000000 + 0xA000` (`.text+0x3890..0x38ec`) | reads a-window taskfile, 8× stable-read (`.text+0x5d28..0x5d50`) | descriptor writes at `0xfd00a250/25c`, `0xfd00a208` (`.text+0x5c04..0x5c94`) |
| `1` | **mailbox post (§1.1)** | writes **shadow memory** `*[ap+0x28..0x3c]`, `*[ap+0x4c]` (`.text+0x3990..0x3a54`) | status synthesised from `priv+0x220` (`.text+0x5e04..0x5e50`) | `tf->command` cached only (`.text+0x5b54..0x5b78`) |

`send_atapi_cmd` (`.text+0x1f54`) is a pure a-window function: it writes
`0xfd00a038/0xa108/0xa220..0xa228/0xa00c/0xa248..0xa24c/0xa010/0xa014`, polls
`0xa00c == 0` → `0xa010 == 0xfe` → `0xa014 == 0xff`, and finally posts command
`0xa0` (PACKET) to `0xfd00a01c` (`.text+0x2058/0x2060`). It is mode-0-only and no
caller on the executed path reaches it. That, plus the C95 absence measurement, is
the whole explanation for "zero a-window accesses".

### 1.4 The non-mailbox data body (context, not a model requirement)

For ATA-class devices and for mode 0, `data_xfer` moves bytes between `buf` and
`priv+0x58 + priv+0x4c` (`.text+0x554c..0x5588` single-shot, `.text+0x54cc..0x54fc`
2352-byte sector loop), then calls `_sata_mt85xx_hw_chg_st(priv)` at transfer end
(`.text+0x55ac`). These paths issue **no MMIO at all** — the buffer is a shadow of
FE DMA the driver believes already happened.

---

## 2. The FE reply for an ATA command (vs the chk table-data reply)

### 2.1 Two consumers of the status block, one block layout (DECODED)

| consumer | trigger | reads |
|---|---|---|
| `chk_int_ldr` (polled, `.text+0x28a4..0x28d8`) | called directly by `port_start` | `0x5c804` then `0x5c040/044/048/04c` |
| `_sata_mt85xx_svoif_interrupt_handler` (IRQ, `.text+0x4638..0x4660`) | workqueue after the top half latches `bit16` | `0x5c040/044/048/04c` |

Both decode the block identically (`fe-status-handshake.md` §2):

| word | register | field |
|---|---|---|
| `w0` | `0x5c040` | `byte2` = message type, `byte3` = status/code (0 = OK); bytes0..1 unused |
| `w1` | `0x5c044` | DRAM-window offset |
| `w2` | `0x5c048` | length in bytes (clamped to 512 by the polled path, to `priv+0x54` by the IRQ path) |
| `w3` | `0x5c04c` | unused |

### 2.2 `0x5c800` = mask, `0x5c804` = pending/W1C, `0x5c808` = secondary (DECODED)

Top half `svoif_mt85xx_interrupt` (`.text+0x346c`):

```
0x34b0  ldr  lr,[0xfd05c800]       ; mask
0x34b4  ldr  r3,[0xfd05c804]       ; pending
0x34b8  and  r12,r3,lr             ; latched = pending & mask
0x34bc  cmp  r3,#0 ; beq exit      ; drain loop exits ONLY on a zero read
0x34c0  str  r3,[0xfd05c804]       ; write-1-to-clear
0x34c4  orr  r2,r2,r12             ; accumulate
0x34d4..0x34f4  priv+0x22c |= r2 | priv+0x22c
0x34f8  and  r2,r2,#0x10000        ; was bit16 latched?
0x34fc  ldr  r3,[0xfd05c808]
0x3500..0x3510  priv+0x234[priv+0x230] = r3 | (r2 << 8); ring index in priv+0x230
0x3530..0x3540  queue_work(priv+0x2e0)      ; always scheduled
```

Bottom half (`_sata_mt85xx_svoif_interrupt_handler`, `.text+0x4540`, entry
`priv = arg - 0x2e8`):

```
0x4604  r6 = priv+0x22c ; priv+0x22c = 0     ; consume latch
0x4628  tst  r6,#0x10000
0x462c  moveq r0,#0 → return 0               ; <<< no bit16 latched ⇒ status block NEVER read
0x4640..0x4660  read 0x5c040/044/048/04c
0x4668  type = byte[w0+2]
0x4674  if priv+0x220 in {0,5} → skip
0x468c  if priv+0x48 == 1 → 0x48ec (queue the argument/data path)
0x4698  if byte[w0+3] != 0 → 0x488c: hw_chg_st(priv, 5)
0x46a4  else if priv+0x48 == 0 → 0x483c: hw_chg_st(priv)      ; implicit new state
0x46b0  else hw_chg_st(priv, 2)                                ; SUCCESS advance
0x47ac  type == 0x10 → memcpy from the DRAM window (§2.3)
```

`port_start`'s fast path uses the same pending register with its own bound
(`.text+0x3230..0x3280`: read `0x5c804`, if nonzero W1C back, test `bit16`,
150 × `msleep(10)` = 1.5 s) and then sets the mask: `.text+0x32d0 mvn r2,#15`
→ `.text+0x32d8 str r2,[0xfd05c800]` = **`0xfffffff0`**.

### 2.3 The IDENTIFY payload delivery (DECODED, `.text+0x47ac..0x48d8`)

```
0x47b4  r1 = &svoif_int_ldr_dram
0x47b8  r3 = w2 (length); 0x47c8 r1 = w1 (offset)
0x47c4  r6 = *svoif_int_ldr_dram + w1
0x47cc  r10 = min(priv+0x54, w2)
0x47d8  switch (priv+0x48):
          == 1 → 0x4850: memcpy(priv+0x4c, r6, r10)   ; FE → host (device read)
          == 2 → 0x48a4: memcpy(r6, priv+0x4c, r10)   ; host → FE (device write)
          else → hw_chg_st(priv) and drop
```

So: **512 bytes of IDENTIFY data go into the FE DRAM window at
`phys = ((*(u32*)0x7005c500 & 0xff) << 22) + w1`, and the reply that carries them
is `type = 0x10, w1 = <that same offset>, w2 = 512`.** The `0x5c500` page register
is written by `xfer_int_ldr_fw` (`.text+0x192c..0x1940`) and already modeled.

### 2.4 What must be true for `check_status` to report a real status byte

Answer: **nothing MMIO-side.** In mode 1 `check_status` never reads the a-window;
it maps `priv+0x220` → status (`.text+0x5e04..0x5e50`). `priv+0x220` changes only
through `_sata_mt85xx_hw_chg_st` (`priv+0x220 = new_state`, `.text+0x4070`), and on
the reply path the only callers are the bottom-half branches above. Therefore:

- a **type-0, byte3-0** reply advances the machine past "awaiting command
  completion" → `check_status` returns `0x58` (`RDY|DSC|DRQ`, states 2/3) →
  libata's identify wait sees DRQ and calls `data_xfer` for 512 bytes.
- a **type-0, byte3≠0** reply drives `hw_chg_st(priv, 5)` → status `0x51`
  (`RDY|DSC|ERR`) — the ATA error path. Use this only when you intend a device
  error.
- state 4/1 → `0xd0`; state 6 → `0x50`; anything else → the previous cached
  status (`.text+0x5db8..0x5dd8`).

The *taskfile* registers libata reads back (`tf_read`) come from **shadow memory**
`*[ap+0x24]/[ap+0x2c]/[ap+0x30]/[ap+0x34]/[ap+0x38]/[ap+0x3c]` in mode 1
(`.text+0x6120..0x6178`) — written by the driver itself in `tf_load`
(`.text+0x39cc..0x3a54`). The model does not and cannot feed them; only `0x5c040-4c`
matters.

---

## 3. The command codes: who posts them, what they mean, what reply they expect

Only **three** functions in the module write `0x5c000` (`map.txt` rows 331-341,
386-392; bundle agrees): `_svoif_mt85xx_send_ata_cmd` (`.text+0x3a78`),
`_svoif_mt85xx_send_table_data_ack_cmd` (`.text+0x3c08`), `sata_mt85xx_data_xfer`
(§1.1). Codes are set in exactly three places:

| code (`w0` byte3) | set by | call site | follow-up |
|---|---|---|---|
| `0xa1` | `chk_int_ldr` `.text+0x2850/0x2858` (`mov r2,#161`) | `.text+0x2874 bl send_ata_cmd` | poll `0x5c804` bit16 (200 × 10 ms), then read `0x5c040-4c`, then the `'B','O','O','T'`/`0xeeee` gate (`.text+0x29a4..0x2a38`) |
| `0xa1` (IDENTIFY PACKET) | same field, different content (see §3.3) | mailbox post with a real taskfile | type-0x10 (payload) + type-0 (completion) |
| `0xf7` | `sata_mt85xx_prereset` `.text+0x51c4/0x51c8` (`mov r3,#247`) | `.text+0x51d0 bl send_ata_cmd`, `.text+0x51dc hw_chg_st` | type-0 completion, byte3 = 0 |
| `0x08` | `sata_mt85xx_softreset` `.text+0x4f6c/0x4f70` (`mov r3,#8`) | `.text+0x4f78 bl send_ata_cmd`, `.text+0x4f7c` | type-0 completion, byte3 = 0 |
| `type 0x10` (`w0 = 0x00100000`) | `_svoif_mt85xx_send_table_data_ack_cmd` `.text+0x3c50/0x3c58` | driver's ACK of message A | no reply; the FE then posts message B (type 0) |

`send_ata_cmd`'s word build (DECODED `.text+0x3ac0..0x3b30`):

```
0x3ac4/0x3ae4  w0 byte3 = priv+0x29c                       ; code
0x3ae8..0x3af4 w1 = { priv+0x280, +0x284, +0x288, +0x28c }  ; features, count, lba0, lba1
0x3af8..0x3afc w2 byte0 = priv+0x290, byte1 = priv+0x294    ; lba2, device/head
0x3b10/0x3b14  priv+0x22c = 0 ; priv+0x230 = 0              ; clear latches before posting
0x3b18..0x3b30 str w0..w3 → 0xfd05c000/004/008/00c
0x3b54..0x3b60 orr 0xfd05c020,#1                            ; doorbell
```

`send_table_data_ack_cmd` (DECODED `.text+0x3c50..0x3cb4`): `w0 = 0x00100000`
(type `0x10` at byte2), `w1 = w2 = w3 = 0`, same doorbell. That is exactly C95
cmd#2 — confirming the ack function was exercised.

### 3.1 `0x08` = soft reset, with the `EB140101` taskfile (DECODED `.text+0x4fa0..0x4fd8`)

```
[priv+0x280] = 0x00   features
[priv+0x284] = 0x01   sector count
[priv+0x288] = 0x01   lba0
[priv+0x28c] = 0x14   lba1
[priv+0x290] = 0xeb   lba2
[priv+0x294] = 0x00   device
[priv+0x298] = 0x50 ; [priv+0x2a0] = 0x50
```
i.e. the well-known `0xEB140101` SRST signature laid out as a taskfile, then code
`0x08` posted and `hw_chg_st` run. Expected reply: type 0 / byte3 = 0.

### 3.2 `0xf7` = prereset (DECODED `.text+0x51bc..0x51dc`)

`priv+0x48 = 0` (clears the transfer direction), code `0xf7` posted, then
`hw_chg_st(priv, r8)`. It does **not** touch `priv+0x280..0x294` — which is why the
C95 EH retries (#4..#13) carry the *stale* taskfile words from whatever ran before
them (`w2 = 0xa000` throughout). Expected reply: type 0 / byte3 = 0.

### 3.3 Why C95 cmd#3 (`w0=0xa1000000`, `w2=0xa000`) is an ATA command, not a chk call

- `chk_int_ldr` **zeroes** `priv+0x280..0x294` immediately before posting
  (`.text+0x285c..0x2870`). A chk post therefore always has `w1 = w2 = w3 = 0`.
  C95 cmd#1 (`w2 = 0`) is that post. **Any `0xa1` post with a nonzero arg word is
  not `chk_int_ldr`.**
- Decoding `w2 = 0x0000a000` through either builder:
  - `send_ata_cmd` reading: `{priv+0x290 = 0x00 = lba2, priv+0x294 = 0xa0 = device}`
    → device/head register `0xA0` = master + LBA, the canonical
    `IDENTIFY PACKET DEVICE` taskfile.
  - `data_xfer` reading: the `u32` at `priv+0x28` = `0x0000a000` in the 12-byte
    argument blob.
  Either way it is **not** an address; the a-window is at `0xa000` only in mode 0,
  which the trace proves is not executing.
- Which of the two posters ran is *INFERRED*: `[priv+0x294] = 0xa0` and
  `[priv+0x29c] = 0xa1` have no store in this module outside `chk_int_ldr`
  (which writes 0) and `softreset` (which writes 0), so the taskfile image for
  cmd#3 was written by a path outside the bundle (a taskfile→FE-message bridge in
  another module, or `tf_load`'s mode-0 twin). Settling experiment: the C96 trace
  — if a `W 05c40c`/`W 05c400`/`W 05c404` triple appears immediately before the
  next `0xa1` post, it is `data_xfer`'s READ-CD branch; if not, `send_ata_cmd`.
  **The model does not need the answer**: key on content (§4.1).

---

## 4. The driver's poll/timeout loop shape after cmd#3

### 4.1 The three poll shapes over `0x5c804` (DECODED, distinguishable in a trace)

| shape | code | R/W pattern | exits on |
|---|---|---|---|
| `chk_int_ldr` | `.text+0x28a4..0x28b4` | `R` → `W(accumulated)` each iteration; accumulate with `orr` | `bit16` set (or 200 × 10 ms) |
| `port_start` fast path | `.text+0x3260..0x3280` | one `R` + `W(same value)`; then test `bit16` | nonzero read then `bit16`, else 150 × 10 ms |
| IRQ top half drain | `.text+0x34b4..0x34c8` | `R` → `W(same)` **while nonzero**, no sleep | **a zero read**, or a hard IRQ storm |

C95's post-cmd#3 sequence `R, W=0x10000, R, W=0x10000, R, (no W)` is
**shape 3** — the top half, not `chk_int_ldr`: it needs two consecutive nonzero
reads and then a zero. The model satisfied that, latched nothing (mask read as 0),
and the bottom half returned at `.text+0x4630` without reading the block. The
"30 s later `qc timeout (cmd 0xa1)`" is libata's `ATA_TMOUT_PACKET`-class wait
expiring because `priv+0x220` never left state 3.

### 4.2 The `0x242xx` block — 12945 reads of `0x2420c`

Observed (C95, post-handshake): `W 0x2420c=0x111`, `W 0x24210=0xe1`,
`W 0x24214=0x200`, `R 0x24218`, `W 0x24218=1`, then **12945 × `R 0x2420c`**, all
unimplemented (model returns 0).

- Address identity: `0x7002420c` = VA `0xfd02420c` = **`0xfd024000 + 0x20c`**, the
  FE/HAL CSR bank — confirmed by `VSF_FrontEndStatus` returning
  `*(u32*)0xfd024034` (`sata.dis` `.text+0x1f4..0x1fc`), and by
  `reset_int_ldr`/`xfer_int_ldr_fw` writing `0xfd024030` and polling
  `0xfd024034` (`sata.dis` `.text+0x3c/0x44`, `.text+0x1820..0x19c4`).
- Shape: `{0x111, 0xe1, 0x200}` as three sequential words then a read of a fourth
  and a `1` written to it, then an endless read of the first — the signature of a
  **descriptor setup (addr/addr/len) + start bit + completion poll**.
- Attribution is **INFERRED**: no `0xfd02420c` pool word and no `[rN,#0x20c]`
  immediate exists in `sata_mt85xx_mod.ko` or `bdpdrv.ko`'s `.text` (greps run:
  `0xfd02420c`, `0xfd024{210,214,218}`, `[rN,#0x20c]`). So the base is computed at
  runtime (table-driven accessor, or a caller in another module). It is **not** on
  the reply path decoded above — it is the int-loader/AACS loader's own DMA, and it
  is orthogonal to the ATA reply. Treat it as a *separate* model row (§5, row 12)
  with its own settling experiment, not as a blocker for IDENTIFY.
- What terminates it: nothing the driver-side decode shows; with a model returning
  0 forever, `hw_chg_st`'s own timing path plus libata's timeout are the only exits,
  which is what C95 saw. The loop is bounded in *time* by libata, not by a counter.

---

## 5. The model recipe (per-register "answer X with Y")

Constants: `MASK = 0x10000` (message-pending, `0x5c804` bit16).

### 5.1 Mailbox / reply registers

| # | reg (VA) | driver op | model must |
|---|---|---|---|
| 1 | `0xfd05c000` | `W` 4 words (`data_xfer` `.text+0x57a0`, `send_ata_cmd` `.text+0x3b18`, ack `.text+0x3c68`) | store `w0..w3`; **do not act yet** |
| 2 | `0xfd05c004/008/00c` | `W` | store |
| 3 | `0xfd05c020` | `R` then `W` (`\|=1`, read-modify-write, `.text+0x57d8..0x57e4`) | return the stored value on `R`; on `W` with bit0 set **treat as the doorbell** and run the §5.2 state machine. Keep bit1..31 latched so the RMW is lossless. |
| 4 | `0xfd05c040` | `R` (`chk_int_ldr` `.text+0x28b8`, IRQ `.text+0x4640`) | reply word 0: `byte2 = type`, `byte3 = status` |
| 5 | `0xfd05c044` | `R` | reply word 1 = DRAM-window offset |
| 6 | `0xfd05c048` | `R` | reply word 2 = length (bytes) |
| 7 | `0xfd05c04c` | `R` | reply word 3 = 0 |
| 8 | `0xfd05c800` | `R` (mask, `.text+0x34b0`) / `W` (`0xfffffff0`, `.text+0x32d8`) | **return the last written value, and at minimum `0x10000` set.** A zero here silently discards every FE message. |
| 9 | `0xfd05c804` | `R` (pending) / `W` (write-1-to-clear) | return `MASK` while a reply message is un-consumed; on a `W`, clear exactly the written bits, then return **0** once consumed (the top half's drain loop needs the zero). Never return `MASK` forever. |
| 10 | `0xfd05c808` | `R` (top half, `.text+0x34fc`) | return 0 (or the same reply code) — value only lands in `priv+0x234[n]`; 0 is safe |
| 11 | `0xfd05c400` / `0xfd05c404` | `W` (host addr / length, `data_xfer` `.text+0x583c/0x5844`) | store; no reply needed |
| 12 | `0xfd05c408` / `0xfd05c40c` | `R`+`W` RMW (`\|=0x100`, `\|=0x600`, `=1`) | store and return what was written (RMW must be lossless) |
| 13 | `0xfd05c500` | `W` page number (`.text+0x1940` in `xfer_int_ldr_fw`) | already modeled: `pgn = value & 0xff`; DRAM base `= pgn << 22` |
| 14 | `0xfd05c704` / `0xfd05c708` | `R` (`reset_int_ldr`, `init_int_ldr` `.text+0x224`) | already modeled (`& 0x601 == 0x601` gate) |
| 15 | `0x7002420c` / `0x24210` / `0x24214` | see §4.2 | `W`: store. `R 0x2420c`: **return a "complete" value — first try the stored `0x111`** (i.e. echo). Ladder if the poll continues: `0x111`, `0x1`, `0x2`, `0x111\|0x200`, `0x200`, `-1`. |
| 16 | `0x70024218` | `R` then `W=1` | store; return the stored value |

### 5.2 Reply state machine on the `0x5c020` doorbell (content-keyed)

Let `code = (w0 >> 24) & 0xff`, `type = (w0 >> 16) & 0xff`, `arg = w1 | w2 | w3`.

| condition | meaning | model action |
|---|---|---|
| `type == 0x10` (`w0 == 0x00100000`, `arg == 0`) | driver ACKed message A (`send_table_data_ack_cmd`) | **post message B**: `w0 = 0x00000000`, `w1 = w2 = w3 = 0`; then raise `0x5c804 \|= MASK`. (Existing behavior — keep.) |
| `code == 0xa1 && arg == 0` | `chk_int_ldr` entry | **post message A**: `w0 = 0x00100000` (type 0x10), `w1 = <DRAM offset>`, `w2 = <len ≥ 0x102>`, `w3 = 0`; fill `(pgn<<22)+w1` with the loader/table block whose `buf[0x2e..0x31] = 'B','O','O','T'` and `LE16(buf[0x100]) == 0xeeee`; raise `0x5c804 \|= MASK`. (Existing behavior — keep.) |
| `code == 0xa1 && arg != 0` | **ATA command `IDENTIFY PACKET DEVICE`** (C95 cmd#3) | (1) write the 512-byte IDENTIFY PACKET block into the DRAM window at `(pgn<<22)+off`; (2) `w0 = 0x00100000, w1 = off, w2 = 0x200, w3 = 0`; raise `MASK`; (3) after the driver's ack of that type-0x10 (or immediately after, order chosen to match observed timing): `w0 = 0x00000000` (type 0, byte3 = 0 = success), `w1 = w2 = w3 = 0`; raise `MASK`. Step (3) is what moves `priv+0x220` → 2 and makes `check_status` return `0x58`. |
| `code == 0xf7` | prereset | `w0 = 0` (type 0, byte3 = 0), args 0; raise `MASK`. |
| `code == 0x08` | soft reset | `w0 = 0` (type 0, byte3 = 0), args 0; raise `MASK`. Optionally echo the `EB140101` signature into the reply args (not read back on this path). |
| anything else | unknown | `w0 = 0` (type 0, byte3 = 0), args 0; raise `MASK`. Never leave the pending bit down — silence is a 30 s timeout, not a fast failure. |

Two hard rules, both from `.text+0x34b4..0x34c8`:

1. **Raise `MASK` after the doorbell write, never inside the same `W`.** The top
   half's drain loop reads `0x5c804` and clears until zero; a permanently set bit
   is an IRQ storm (the C-pre-C95 4.4 GB `0x5c804` storm).
2. **Serve the block before raising `MASK`.** The bottom half reads
   `0x5c040-4c` only after the latch, so the words must already be in place.

### 5.3 IDENTIFY payload placement, summarised

| question | answer |
|---|---|
| which register names the buffer? | none — the payload goes to the **FE DRAM window**, `phys = ((*(0x7005c500) & 0xff) << 22) + w1` |
| what names the offset/length? | reply words `w1` (= offset, model's choice) and `w2` (= `0x200`) in the `type 0x10` message |
| how does it reach libata? | `.text+0x47c8..0x4884`: `memcpy(priv+0x4c, *svoif_int_ldr_dram + w1, min(priv+0x54, w2))` when `priv+0x48 == 1` |
| what identifies the drive? | the 512 bytes' word 0 (`0x848a` for an ATAPI packet device), word 49 bit9 (LBA), word 83/86 (command sets) — the model's existing `sata_disc` identify table; `atan` only requires it to be well-formed for `ata1.00` to be configured |
| does the a-window or `0xa01c` matter? | **no** — zero traffic in C95, mode-gated off at `.text+0x5610/0x5d1c` |

---

## 6. Expected observable for C96 (one paragraph)

`ata1.00` should reach the IDENTIFY success path: the UART goes from
`ata1.00: qc timeout (cmd 0xa1)` + `failed to IDENTIFY (I/O error, err_mask=0x4)`
straight to `ata1.00: ATAPI: <model string>` and `ata1.00: configured for UDMA/…`
(or the pata-equivalent line for this driver) in the same probe, with **no** SRST
retry block and no `reset failed, giving up`; `bdpdrv` then gets past its
`port_start` and continues loading. The MMIO signature that proves the FE answered
(rather than the driver timing out) is, in order: `W 05c000..00c` with a nonzero
`w1`/`w2`, `R 05c020`, `W 05c020 = 1`, then `R 05c804` **returning `0x10000`**
followed by `R 05c800` **also returning bit16 set**, then a `R 05c040/044/048/04c`
block — *that last quadruple is the decisive one: it never appears anywhere in the
C95 trace, and it is the only proof that the bottom half got the latch.* Then a
second `R 05c804`/`W 05c804` pair for message B, and the absence of a `0x2420c`
read loop in the same window.

---

## 7. Conflicts and corrections to earlier docs

1. **`run-c94-c95.md` / brief**: "`w2=0xa000` = the window address / `send_atapi_cmd`
   dispatch". Corrected: `0xa000` decodes as `{lba2 = 0x00, device = 0xa0}` (or the
   `u32 0x0000a000` in the CDB blob) — it is a **taskfile byte pair, not an
   address**, and `send_atapi_cmd` is mode-0-only (§1.3).
2. **`run-c94-c95.md`**: "the current model answers the byte3-0xa1 doorbell with
   the chk message-A/B sequence — wrong protocol for this call site" — correct, and
   §5.2 replaces the byte3 discriminator with a content discriminator.
3. **Missing from all prior docs**: `0x5c800` as the mask that gates the latch
   (`.text+0x34b0..0x34b8` + `.text+0x32d0..0x32d8`). Without it, no reply can ever
   be observed regardless of the protocol.
4. **`map.txt` scope**: it records literal-relative accesses only. The
   `ap->ioaddr.X - 0x3000000 + 0xA000` accesses in `tf_load`/`tf_read`/
   `check_status`/`check_altstatus`/`exec_command`/`data_xfer` and the
   `*[ap+0xNN]` shadow accesses are **absent from the map** by construction — the
   absence of a row is not evidence of absence of an access. No row of `map.txt`
   contradicts the bundle; every literal row cited above matches instruction for
   instruction.
5. **`ata-probe-path.md` §2.2 / §6 (a-window status model)**: superseded for this
   firmware state — see `run-c94-c95.md` and §1.3 here.

---

## 8. Instruction-site index (every claim above)

| claim | site(s) |
|---|---|
| `priv+0x8` = mailbox/shadow mode | `data_xfer` 0x5610/0x561c; `tf_load` 0x3838/0x383c; `check_status` 0x5d1c/0x5d24; `exec_command` 0x5b54/0x5b58; `tf_read` 0x5f7c/0x5f84 |
| mailbox post (both builders) | `data_xfer` 0x579c-0x57e4, 0x57bc (dsb), 0x57c0 (hook); `send_ata_cmd` 0x3b18-0x3b60; `ack` 0x3c64-0x3cb4 |
| `w0` byte3 = code | `data_xfer` 0x576c/0x5778; `send_ata_cmd` 0x3ac4/0x3ae4 |
| `w1/w2` taskfile bytes | `send_ata_cmd` 0x3ac8-0x3afc |
| type 0x10 ack word | `ack` 0x3c50/0x3c58 |
| code 0xa1 / 0xf7 / 0x08 | 0x2850+0x2858; 0x51c4+0x51c8; 0x4f6c+0x4f70 |
| chk zeroes the taskfile words | 0x285c-0x2870 |
| mask `0x5c800` = `0xfffffff0` | `port_start` 0x32d0/0x32d8 |
| top-half drain + latch | 0x34b0-0x3510 |
| bottom-half latch test | 0x4604-0x4630 |
| status-block read (IRQ) | 0x4640-0x4660 |
| type dispatch / state advance / error | 0x4668-0x46b8, 0x488c |
| DRAM-window payload copy | 0x47b4-0x48d8 |
| chk status-block read + gate | 0x28b8-0x28d8, 0x2914-0x2960, 0x299c-0x2a38 |
| status byte from `priv+0x220` | `check_status` 0x5e04-0x5e50 (and 0x5d54-0x5db4 for mode 0) |
| `priv+0x220 = state` | `hw_chg_st` 0x4070 |
| shadow taskfile writes/reads | `tf_load` 0x3990-0x3a54; `tf_read` 0x6120-0x6178 |
| a-window body (mode 0) | `data_xfer` 0x5620-0x56fc, 0x58d8-0x593c; `send_atapi_cmd` 0x1f54-0x2064; `exec_command` 0x5c04-0x5c94; `_set_tx_reg` 0x2e48-0x2ec4 |
| FE/HAL CSR block identity | `sata.dis` `VSF_FrontEndStatus` 0x1f4-0x1fc; `reset_int_ldr` 0x3c-0x44; `xfer_int_ldr_fw` 0x1820-0x19c4 |

## 9. Open items with their settling experiments

| item | label | experiment |
|---|---|---|
| which builder posted C95 cmd#3 (`send_ata_cmd` vs `data_xfer`) | INFERRED | C96 trace: presence/absence of the `05c400/404/408/40c` write triple immediately before the `0xa1` post |
| order of reply (payload-then-completion vs completion-then-payload) for IDENTIFY | INFERRED | C96: try type-0x10 first (matches the chk sequence shape); if 512 bytes arrive but the command still times out, swap |
| `0x2420c` completion value | INFERRED | ladder in §5.1 row 15, watching whether the 12945-read loop collapses to O(1) |
| whether the FE must supply a `0x5c808` value | INFERRED | 0 is safe (only stored into `priv+0x234[n]`); if a state-machine branch keys on it, the trace shows the state stall |
| 2352-byte-sector vs 2048 PIO path for real disc reads | not in scope | C97+, after IDENTIFY succeeds |
