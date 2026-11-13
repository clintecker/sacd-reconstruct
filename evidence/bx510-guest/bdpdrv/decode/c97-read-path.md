# C97 — the disc-READ path: ATAPI READ(10)/READ(12)/READ-CD over the FE mailbox + the `0x5c400` DMA descriptor

Decode of how Firebird sectors actually reach libata once `ata1.00` is configured: the
`0x5c400..0x5c40c` descriptor group, the direction machine that arms it, the CDB rewrite
that decides the sector framing, and the per-register recipe the QEMU FE model needs so a
READ delivers real disc bytes instead of timing out or silently zero-filling.

**This lane EXTENDS `fe-ata-cmd.md`; it does not re-derive it.** Everything in that doc
stands except where §7 below says otherwise (two entries: §1.2's "the model only has to
accept the writes" and §9's "2352-byte vs 2048 PIO path — not in scope").

**Inputs (pre-extracted; nothing here was produced by scanning a binary):**

| input | role |
|---|---|
| `/tmp/bdpdrv/fe-ata-funcs.dis` | objdump of the 19 FE-path functions (literal pools inline) |
| `/tmp/bdpdrv/sata.dis` | full module disassembly; single-function pulls by line range |
| `decode/fe-ata-cmd.md` | the mailbox/reply/status protocol this doc continues (§1.1, §1.2, §2.3 assumed) |
| `decode/fe-status-handshake.md` | DRAM-window mechanism (`0x5c500`, `phys=(pgn<<22)+off`) |
| `decode/sata-fw-load.md`, `decode/kernel-iomap.md` | page offset `0xc0000000`, physical offset 0 (VERIFIED) |
| `docs/DAEMON-MAP.md`, `docs/large-image-interface.md` | fixture geometry: Firebird = 1,064,208 × 2048 B; SACD raw frame = 2064 B |
| `emulator-kit/sony-bx510.c` | read-only: the model's current FE/mailbox state and its `sata_blk` backing |

All instruction addresses are **section-relative** (`.text+0x…`). `priv` is the driver's
per-port private struct: `priv = *(u32*)(ap + 0x1dfc) + 0xc` (`data_xfer` 0x544c/0x5464).

**Certainty labels.** *DECODED* = a compare/store/load in the bundle fixes it.
*INFERRED* = consistent with every instruction seen, not closed by one; the settling
experiment is named. **No trace evidence exists for this path yet** — the newest run
(C95 post-handshake, `decode/bdpdrv-runC95.posthandshake.mmio.gz`: 10 mailbox posts, two
`0x5c804` reads) contains zero `0x5c4xx` accesses and zero `0x5c040` reads, so every claim below is static, and §6 is the
first trace that would falsify it.

---

## 0. Bottom line (what changes for C97)

1. **The FE DMAs the sectors straight into host RAM at the address in `0x5c400`.** There is
   no mailbox-window hop for a READ: `0x5c404` is the byte count the driver allocated, and
   the completion reply is a **bare type-0 message whose payload words are ignored**. The
   `type 0x10` DRAM-window `memcpy` of `fe-ata-cmd.md` §2.3 is for the *loader/table*
   traffic and for IDENTIFY, **not** for a READ (§1.3).
2. **`0x5c400` holds a guest PHYSICAL address**, computed in 32-bit arithmetic as
   `(u32)(buf_va + 0x40000000)` = `buf_va - 0xc0000000` (`qc_issu_task` 0x7090/0x7098;
   page offset `0xc0000000`, physical offset 0 — `kernel-iomap.md`, VERIFIED). It is a
   plain RAM address in the machine's `ram` region (512 MiB at phys 0, `sony-bx510.c`
   `.default_ram_size`), so `stb_phys(&address_space_memory, …)` is the whole mechanism.
3. **`priv+0x48` is the direction register and `priv+0x38` is `qc->tf.protocol`** — both
   *DECODED* in `sata_mt85xx_qc_prep` (`0x2ed4`), which nothing in the docs attributed
   before. `1` = device→host (READ), `2` = host→device (WRITE), `0` = no data
   (`0x2ee8`, `0x2eec..0x2f18`). §2.
4. **The driver poisons the destination buffer with `0xbb` before every device→host
   transfer** (`qc_issu_task` 0x7468, `memset(buf, 0xbb, min(len,16))`). A model that
   advances the ATA state machine without performing the DMA produces a *detectably*
   poisoned payload instead of failing loudly — that poison is the cheapest C97 assertion
   (§6, check 3).
5. **Sector framing is chosen by the driver, and it rewrites the CDB to do it**
   (`qc_issu_task` 0x6e9c..0x6ef4): when the vendor mode field `priv+0x18 ∈ {8,9,10}`,
   READ(10)/READ(12) are **mutated in place into READ CD (0xBE) with byte9 = `0xF8`** and
   the length becomes `count × 2352`. Otherwise the CDB is posted unmodified with
   `len = qc->nbytes` (2048-byte sectors). The model must handle both, keyed on the opcode
   it actually receives. §4.
6. **The driver itself strips the 2352-byte raw framing**, using the frame's own header
   byte 15 (mode) to pick payload offset 16 or 24 (`data_xfer` 0x54cc..0x54fc). So the FE
   must emit *standard* CD raw frames with a valid 4-byte header; it must not pre-strip.
7. **The model's current dispatch mis-serves every READ.** `bx510_fe_dispatch` keys
   `code == 0xa1 && arg != 0` → IDENTIFY and posts *two* messages (type-0x10 + type-0).
   A READ post is also `code == 0xa1` with `arg != 0` (the CDB rides w1..w3), so it would
   get an IDENTIFY payload first — and that type-0x10 message is **destructive**: on the
   IRQ path, direction 1 takes the window→buffer `memcpy` (`0x4850`), which would overwrite
   the just-DMA'd sectors with whatever the window holds. The discriminator must be the
   armed descriptor, not the code byte (§3, §5 rows 21-24).

---

## 1. The full READ data path, end to end

### 1.1 The chain (every hop DECODED)

```
libata qc (READ(10) 0x28 or READ(12) 0xA8, sg)
  → sata_mt85xx_qc_prep  (0x2ed4)      priv+0x38 = tf.protocol ; priv+0x48 = 1 (device→host)
  → sata_mt85xx_tf_load  (0x3814)      mode 1 ⇒ shadow memory only, no MMIO (fe-ata-cmd §1.3)
  → sata_mt85xx_exec_command (0x5b28)  mode 1 ⇒ caches tf->command, hw_chg_st(priv,1) (0x5b80)
  → sata_mt85xx_qc_issu_task (0x6c94)  [deferred]  ← this is where the transfer is armed
        0x6cdc/0x6ce0  priv+0x54 = byte count, priv+0x58 = 0
        0x6e38..0x6e98 LBA → priv+0x2c ; transfer length → priv+0x30
        0x6ebc..0x6ee8 (raw mode) CDB 0x28/0xA8 → 0xBE, byte9 = 0xF8
        0x6ef4..0x6f04 priv+0x54 = count × 2352
        0x6f4c..0x6f70 kmalloc(priv+0x54 + 16) ⇒ priv+0x4c = 16-aligned buffer,
                                                     priv+0x5c = kmalloc base
        0x7468         memset(priv+0x4c, 0xbb, min(priv+0x54,16))     ← POISON
        0x704c..0x7068 memcpy(priv+0x24, qc->cdb, 12)                ← the 12-byte blob
        0x706c..0x7098 priv+0x50 = (u32)(priv+0x4c + 0x40000000)     ← PHYS ADDRESS
  → sata_mt85xx_data_xfer (0x5434)     buf = qc->cdb, buflen = 12, rw = 1 (command phase)
        gate: priv+0x8 == 1 && (priv+0x38-5) <= 2 && priv+0x220 == 3   (0x546c..0x5484)
        0x570c..0x5724  cdb[0] ∈ {0x28,0xA8,0xBE} ⇒ 0x5800
        0x5814          0x5c40c = 1
        0x5838/0x5844   0x5c400 = priv+0x50 ; 0x5c404 = priv+0x54
        0x5848..0x5850  0x5c408 |= 0x100
        0x5870..0x5878  0x5c40c |= 0x600
        0x5728          hw_chg_st(priv,1)                       priv+0x220: 3 → 1
        0x576c..0x57e4  w0[byte3] = priv+0x29c, w1..w3 = priv+0x24..0x2f (the CDB)
                        str w0..w3 → 0x5c000/004/008/00c ; dsb ; 0x5c020 |= 1 (doorbell)
        return buflen                                     ← "the FE owns the transfer"
  ══ MODEL: doorbell + armed descriptor ⇒ read sata_blk, DMA to phys 0x5c400,
  ══        post ONE type-0 reply,  raise 0x5c804 bit16
  → IRQ top half svoif_mt85xx_interrupt (0x346c)   0x5c804 & 0x5c800 → priv+0x22c |= bit16
  → bottom half _sata_mt85xx_svoif_interrupt_handler (0x4540)
        0x4640..0x4664  read 0x5c040/044/048/04c
        0x4668          type = byte2 ; != 0 ⇒ 0x47ac (payload path) ; == 0 ⇒ continue
        0x4674..0x4694  state ∉ {0,5} ; priv+0x48 == 1 ⇒ 0x48ec
        0x48ec          cache-invalidate [priv+0x4c, priv+0x54)          ← NO COPY
        0x4698          byte3 == 0 ⇒ 0x46a4 ; priv+0x48 != 0 ⇒ hw_chg_st(priv,2)
        0x46b8          priv+0x220 = 2                     ⇒ check_status = 0x58 (RDY|DSC|DRQ)
  → libata data phase: data_xfer (0x5434) buf = sg page, buflen, rw = 0
        gate fails (state == 2, not 3) ⇒ 0x5488
        priv+0x48 == 1 ⇒ 0x5494 ; priv+0x5c != 0 (bounce exists) ⇒ 0x54a0
        priv+0x1c == 1 (raw frames) ⇒ 0x54ac strip loop: per 2352-byte src frame,
              mode = src[0xf] ; src_offset = (mode == 2) ? 24 : 16 ;
              memcpy(dst, src + src_offset, 2048)      ; src += 2352 ; dst += 2048
        priv+0x1c == 0 (plain 2048) ⇒ 0x554c memcpy(buf, priv+0x4c + priv+0x58, buflen)
  → libata completes the qc; the next command's completion path disarms:
        hw_chg_st 0x4420/0x4428  0x5c40c = 0   (plain store, not RMW)  and
        hw_chg_st 0x4038/0x4044  priv+0x50 = 0
```

### 1.2 The descriptor arm, instruction by instruction (DECODED, `data_xfer` 0x5800..0x587c)

| addr | insn | effect |
|---|---|---|
| `0x5800/0x5804` | `ldr r3,[r5]` / `tst r3,#0x40` | debug-print gate on a global flags word; `0x596c` is a `printk` of `(priv+0x50, priv+0x4c, priv+0x54)` then falls through — no functional effect |
| `0x5810/0x5814` | `mov r2,#1` / `str r2,[0xfd05c40c]` | **`0x5c40c = 1`** — a plain store, executed *first*, before addr/len |
| `0x5818/0x581c` | `mcr p15,c7,c10,4` | `dsb` — publish before the address words |
| `0x5824..0x5830` | `outer_cache->fn` | platform cache hook (literal `0` ⇒ no-op) |
| `0x5838/0x583c` | `ldr r2,[r4,#0x50]` / `str r2,[0xfd05c400]` | **`0x5c400 = priv+0x50`** (phys addr) |
| `0x5840/0x5844` | `ldr r2,[r4,#0x54]` / `str r2,[0xfd05c404]` | **`0x5c404 = priv+0x54`** (byte count, = count×2352 or qc->nbytes) |
| `0x5848..0x5850` | `ldr r2,[0xfd05c408]` / `orr #0x100` / `str` | **`0x5c408 \|= 0x100`** (RMW) |
| `0x5854..0x5868` | `dsb` + cache hook | publish |
| `0x5870..0x5878` | `ldr r2,[0xfd05c40c]` / `orr #0x600` / `str` | **`0x5c40c \|= 0x600`** (RMW) ⇒ final `0x601` |
| `0x587c` | `b 0x5728` | fall into `hw_chg_st(priv,1)` + the mailbox post of `fe-ata-cmd.md` §1.1 |

**Ordering facts the model must respect:** the descriptor is fully armed *before* the
mailbox words and the doorbell, and `0x5c40c = 1` lands before `0x5c400/404`. So a model
that acts on the descriptor write would DMA a stale/garbage address (on the very first
READ, `priv+0x50` is whatever the previous command left, usually 0 after the disarm at
`0x4044`). **Key everything on the `0x5c020` doorbell.**

### 1.3 When the DRAM-window copy applies vs the `0x5c400` descriptor (DECODED)

Both mechanisms write to `priv+0x4c`, but they are selected by the *reply type*, and only
one of them is in play for a READ:

| reply | `priv+0x48` | branch | action |
|---|---|---|---|
| `type == 0x10` | `1` | `0x47ac` → `0x4850` | `memcpy(priv+0x4c /*ptr*/, *(svoif_int_ldr_dram) + w1, min(priv+0x54, w2))` + cache clean (`0x4878`), then `hw_chg_st(priv, r1=w1)` at `0x47ec` |
| `type == 0x10` | `2` | `0x47ac` → `0x48a4` | `memcpy(window + w1, priv+0x4c, n)` + cache clean — the writer's uplink |
| `type == 0x10` | `0` | `0x47ac` → `0x47ec` | `hw_chg_st(priv)`, payload dropped |
| **`type == 0`** | **`1`** | `0x4674` → `0x4694` → **`0x48ec`** | **cache-invalidate only** (`bl` with `r0=priv+0x4c, r1=priv+0x54`); *no copy* — the FE already DMA'd into `0x5c400` |
| `type == 0` | `2` | `0x4698` → `0x46b0` | `hw_chg_st(priv,2)` |
| `type == 0` | `0` | `0x4698` → `0x46a4` → `0x483c` | `hw_chg_st(priv,0)` (idle) |

So: **`0x5c400` descriptor ⇒ type-0 completion; DRAM window ⇒ type-0x10 offer.** The
descriptor is armed on exactly the three CDB opcodes that *have* a data-in phase
(`0x28/0xA8/0xBE`, `0x5710..0x5724`); every other post (IDENTIFY, SRST, prereset, the
loader ack) never touches `0x5c400` and therefore must be served through the window.

**The destructive case to avoid (INFERRED, high confidence):** if the model posts a
type-0x10 for a READ, direction is 1, so `0x4850` runs `memcpy(priv+0x4c, window+w1,
min(priv+0x54, w2))` over the freshly DMA'd sectors. With `w1 = 0x1000` and a window page
of 0, the guest gets whatever is at phys `0x1000` and the read is silently corrupted —
the reply still looks successful. This is the concrete reason rows 17-19 of §5 key on the
descriptor rather than on `code == 0xa1`.

### 1.4 The one-deep pin: no reader of `0x5c400/0x5c404` exists (DECODED)

Grep over the whole module for the `0xfd05cfff`-relative forms (`#-0xbff`, `#-0xbfb`,
`#-0xbf7`, `#-0xbf3`) returns exactly **eight** sites, all in three functions:

* `data_xfer` 0x5814, 0x583c, 0x5844, 0x5848, 0x5850, 0x5870, 0x5878 — the arm above;
* `hw_chg_st` 0x4420/0x4428 — `0x5c40c = 0` (**disarm**), reached from `0x40cc..0x40d4`
  when `priv+0x8 == 1` and the completing CDB is *not* one of `0x28/0xA8/0xBE`;
* nothing else.

`0x5c400` and `0x5c404` are **write-only** across the entire driver. They are a pure
hardware contract: "DMA `len` bytes to `addr`." The driver never polls a completion bit in
`0x5c408/0x5c40c`; the only completion evidence it consumes is the mailbox reply. That is
what makes the model's job small — and what makes a *wrong* model silently produce garbage
rather than an error.

---

## 2. The direction field: `0x5c40c = 1` then `|= 0x600`, and `0x5c408 |= 0x100`

### 2.1 Where direction actually lives — `sata_mt85xx_qc_prep` (DECODED, `0x2ed4`)

```
2ed4..2ee4  r1 = qc->ap ; r2 = *(ap+0x1dfc) ; priv = [r2+0xc]
2ed8/2edc   r3 = *(u8*)(qc+0x14)            ; tf.protocol
2ee8        priv+0x38 = r3                  ; ← priv+0x38 IS tf.protocol
2eec..2ef8  if (protocol == 1 || protocol == 5)   ; NODATA classes
2efc        priv+0x48 = 0                   ; no data phase
2f04/2f08   r3 = *(u32*)(qc+0x10) ; tst r3,#8     ; ATA_TFLAG_WRITE
2f0c/2f10   ne ⇒ 2 (host→device) ; eq ⇒ 1 (device→host)
2f14/2f18   priv+0x48 = that
```

This closes three open threads at once:
* `priv+0x48` = **transfer direction**: `0` none, `1` device→host, `2` host→device.
* `priv+0x38` = **`qc->tf.protocol`**, so the `(priv+0x38 - 5) <= 2` gates in `data_xfer`
  (`0x546c`) and `hw_chg_st` (`0x4024`) are "the protocol is one of 5/6/7" — an ATAPI
  class test, as the C96 recipe assumed, but now by name rather than by guess.
* `qc+0x10` = `tf.flags` (u32) and `qc+0x14` = `tf.protocol` ⇒ `sizeof(struct ata_taskfile)`
  = `0x14`, so **`qc+0x24` is `qc->cdb[0]`** — which is why every function reads the CDB
  opcode at `[qc+0x24]` (`qc_issue` 0x369c, `qc_issu_task` 0x6e38, `hw_chg_st` 0x4084).

Nothing in the module ever writes `priv+0x48 = 1/2` except `qc_prep`, and never writes
`priv+0x48 = 0` except `qc_prep`, `softreset` (`0x4f64`) and `prereset` (`0x51c0`).

### 2.2 The `0x5c40c` / `0x5c408` bits

The driver is write-only here, so the *semantics* are INFERRED from the write pattern plus
the single disarm site — but the write pattern is unambiguous about three things:

| word | bit(s) | value observed | reading | label |
|---|---|---|---|---|
| `0x5c40c` | `0` | plain store `1`, before addr/len | **descriptor armed / device→host** — "this transfer's buffer is described below" | DECODED value, INFERRED name |
| `0x5c408` | `8` (`0x100`) | RMW `\|= 0x100` after addr+len | **address+length are valid** (the driver sets it only after writing both) | DECODED value, INFERRED name |
| `0x5c40c` | `9,10` (`0x600`) | RMW `\|= 0x600` last | **DMA enable + go** (last write of the group, after the `dsb`s) | DECODED value, INFERRED name |
| `0x5c40c` | all | plain store `0` (`hw_chg_st` 0x4428) | **disarm**, on the next non-READ completion in mailbox mode | DECODED |
| `0x5c408` | `8` | never cleared | sticky for the port's lifetime | DECODED |

Why the two-phase write (store `1`, later OR `0x600`) is not a reset: the *store of 1* is
followed by the address/len writes and a `dsb`, and only then the `0x600` OR — a
"clear-then-program-then-start" sequence that also sets bit0 as part of the direction
value. There is no code path that arms the group with a write-direction value, i.e. the
hardware contract only ever describes **device→host** transfers; the write direction is
handled entirely in software (`qc_issu_task` 0x71f8 copies sg→bounce buffer itself, then
the FE DMAs the bounce buffer out — the descriptor is never used for it).

**Model requirement: none.** Store all four words, return what was written (the two RMWS
must be lossless), and use `(0x5c40c & 1)` only as the "a READ's data descriptor is
armed" discriminator. Do **not** auto-clear or auto-complete any bit: the driver's
`ldr/orr/str` on `0x5c408/0x5c40c` would fold the model's value into its own.

---

## 3. What the model must do for a READ to deliver Firebird bytes

### 3.1 The DMA

```
on W 0x5c020 with bit0 set:
  armed  = (fe_dma[3] & 1) != 0            /* 0x5c40c */
  if (armed):
      phys = fe_dma[0]                     /* 0x5c400, guest physical, 16-byte aligned */
      len  = fe_dma[1]                     /* 0x5c404, bytes the driver allocated      */
      decode cdb[0..11] from fe_cmd[1..3]  /* w1/w2/w3, §4.1                            */
      build `len` bytes from s->sata_blk   /* §4.2/§4.3                                 */
      for (i = 0; i < len; i++)
          stb_phys(&address_space_memory, phys + i, buf[i]);
      bx510_fe_post(s, 0, 0, 0, 0);        /* ONE type-0, byte3 = 0 = success            */
  else:
      … existing content-keyed dispatch (chk / IDENTIFY / reset) …
```

Why `stb_phys`/`ldnb_phys` and not the DRAM window: the address is a real phys address in
the machine's `ram` region (`MemoryRegion` at phys 0, 512 MiB, `sony-bx510.c` 0x880/0x965),
and `bx510_fe_dram_write()` already uses exactly this API for the window
(`sony-bx510.c`: `stb_phys(&address_space_memory, win + off + i, buf[i])`). No new
plumbing is needed — one more caller of the same primitive.

`blk_pread(s->sata_blk, off, buf, len, 0)` is the read side; the model today only calls
`blk_getlength()` for the IDENTIFY word 100-103 fields (`bx510_sata_build_identify`), i.e.
`sata_blk` is opened but **never read** — this is the missing leg.

Bounds: `len` is capped by the driver at `0x12800` = 75776 bytes (`qc_issu_task` 0x6e00
`cmp r3,#75776` / `0x74e0`), i.e. 32 × 2352 + 512. Keep a hard assert in the model so a
CDB decode bug cannot scribble across RAM: `len <= 0x12800` and `phys + len <= ram_size`.

### 3.2 The completion reply shape

For a READ the reply is **exactly one message**:

| word | value | why |
|---|---|---|
| `0x5c040` | `0x00000000` | `byte2` = type 0 (no payload offer), `byte3` = 0 (**success**) — `0x4668`/`0x4698` |
| `0x5c044` | `0` | unused on a type-0 (`0x4668` branches away from the payload path) |
| `0x5c048` | `0` | unused |
| `0x5c04c` | `0` | unused |

then raise `0x5c804 |= 0x10000` (never inside the same write that stages the words —
`fe-ata-cmd.md` §5.2 rules 1 and 2 still apply verbatim).

Three ways to get this wrong, all of which "succeed" visibly:
* **two messages** (type-0x10 then type-0) ⇒ `0x4850` overwrites the payload (§1.3);
* **`byte3 != 0`** ⇒ `hw_chg_st(priv,5)` ⇒ `check_status` returns `0x51`
  (`RDY|DSC|ERR`) ⇒ libata EH retries, then `qc timeout` — the C95 signature again;
* **no `0x5c804` raise** ⇒ the bottom half returns at `0x4628..0x4630` without ever reading
  the block ⇒ same 30 s timeout.

For a read past EOF the honest reply is `byte3 != 0` (drive error). That is the model's
counterpart to the player's documented beyond-EOF refusal (`public/README.md`) and it is
directly observable as an error status on `ata1.00` rather than as zeros.

### 3.3 The poison check the driver gives us for free (DECODED)

`qc_issu_task` 0x7468: `memset(priv+0x4c, 0xbb, min(priv+0x54, 16))` before every
device→host transfer, and for ATA-class devices only (`priv+0x38 ∈ 1..4`) it also writes
`0xbbbbbbbb` at `buf + priv+0x54 - 4` (`0x7128..0x7134` sets it up, `0x7138..0x7144`
stores it, literal `0x754c`).
So after a successful READ the first 16 bytes of the destination must **not** be `0xbb`.
A model that raises the reply without DMAing leaves a detectable fingerprint — the cheapest
possible negative control for this stage (§6 check 3).

---

## 4. Sector addressing and framing

### 4.1 Decoding the CDB out of the mailbox words (DECODED, `data_xfer` 0x576c..0x5780)

The 12-byte blob at `priv+0x24` is `memcpy`'d verbatim into `sp+0x4c` = `w1`,`w2`,`w3`
(0x5770 `add r0, r7, #4` with `r7 = sp+0x68` = `&w0`; 0x5780 `memcpy(r0=sp+0x6c, priv+0x24, 12)`),
and `w0` byte3 is the sticky FE code (`priv+0x29c`, set by `chk_int_ldr` = `0xa1`
`0x2858`, `softreset` = `0x08` `0x4f70`, `prereset` = `0xf7` `0x51c8`). **Nothing writes
`priv+0x29c` per command**, so a READ post carries `w0 = 0xa1000000` in practice — the same
word as an IDENTIFY post. Content decode:

```c
cdb[i] for i in 0..11  ==  (w[(i>>2)+1] >> (8*(i&3))) & 0xff   /* w1,w2,w3 little-endian */

op    = cdb[0];
lba   = cdb[2]<<24 | cdb[3]<<16 | cdb[4]<<8 | cdb[5];   /* BE, all three opcodes */
switch (op) {
case 0x28: nsec = cdb[7]<<8 | cdb[8]; break;                       /* READ(10)  */
case 0xA8: nsec = cdb[6]<<24 | cdb[7]<<16 | cdb[8]<<8 | cdb[9]; break; /* READ(12) */
case 0xBE: nsec = cdb[6]<<16 | cdb[7]<<8 | cdb[8];
           flags = cdb[9]; break;                                  /* READ CD   */
}
```

Cross-check that the FE can use instead of trusting the CDB: `0x5c404 = priv+0x54` is the
driver's own byte count, and `priv+0x54 = nsec × 2352` when it rewrote to READ CD
(`qc_issu_task` 0x6ef4..0x6f04), else `qc->nbytes` (normally `nsec × 2048`). **DMA
`0x5c404` bytes and derive `nsec` from it** when the CDB and the length disagree — the
length is what the driver allocated, so it is the one that cannot overrun guest RAM.

### 4.2 The 2352-byte raw frame, and how the driver proves its layout

`data_xfer`'s strip loop (`0x54ac..0x54fc`) is the oracle for the framing:

```
54ac  r9 = buflen >> 11                  ; number of 2048-byte output chunks
54cc  r1 = *(u8*)(src + 0xf)             ; FRAME BYTE 15 (CD header: MSF+mode, mode in byte 15)
54d8  if (r1 != 2) r1 = 16 else r1 = 24  ; mode1 ⇒ payload at 16 ; mode2 ⇒ payload at 24
54e4      src_ofs = frame + r1
54d4/54f0 memcpy(dst, src_ofs, 2048)
54f8  src += 2352 ; 54ec dst += 2048
```

That is a textbook CD-DA/CD-ROM raw frame: `sync[0..11] | header[12..15] | [subheader[16..23]
only for mode 2] | user[2048] | EDC/ECC`. The driver only reads byte 15, so the FE's
synthesised frames must at minimum set it correctly; the rest only has to be consistent.

Synthesis from the fixture (2048-byte sectors, §4.3):

```
frame = zeros[2352];
memset(frame, 0x00, 12);              /* sync: 00 FF×10 00 in a real drive; unread here */
frame[12..14] = BCD MSF of (lba + 150) ;   /* unread; correctness is cosmetic            */
frame[15] = 1;                        /* mode 1 ⇒ payload offset 16                */
memcpy(frame + 16, image + lba*2048, 2048);
```

If the disc reports mode 2 form 1 the FE must instead put an 8-byte subheader at 16..23,
set `frame[15] = 2`, and place the payload at 24. Mode 1 is the right default for a
data-only image; the settling experiment is §6 check 4 (if the guest payload is shifted by
8 bytes, the model used the wrong mode byte).

### 4.3 Fixture geometry — 2048 / 2064 / 2352 (and which one this path uses)

| quantity | value | source |
|---|---|---|
| Firebird logical sectors | `1,064,208` | `docs/DAEMON-MAP.md`, `tools/hud_scenarios.py` |
| fixture byte length | `1,064,208 × 2048 = 2,179,497,984` | `docs/DAEMON-MAP.md` ("the TOC's total-sector count multiplied by 2048 equals the ISO's byte length exactly") |
| SACD *raw* frame (module path) | `2064` = 12-byte header + 2048 logical + 4 trailing | `docs/large-image-interface.md`, `docs/DAEMON-MAP.md` |
| ATAPI raw CD frame (this path) | `2352` = 12 + 4 + 2048 + EDC/ECC | `qc_issu_task` 0x6ef4, `data_xfer` 0x54f8 |

So on **this** path:
* **LBA unit = 2048 bytes.** LBA is the *logical* sector address; a READ CD raw transfer
  returns the raw framing of that same logical sector. Offset math:
  `image_off = lba * 2048`, `image_len = nsec * 2048`.
* `0x5c404 = nsec × 2352` **only** when the driver rewrote the CDB to READ CD (§4.1);
  otherwise `0x5c404 = qc->nbytes = nsec × 2048` and the payload is already plain.
* The existing model assumption — `sectors = blk_getlength(sata_blk) / 2048`
  (`bx510_sata_build_identify`) — is **correct** for the fixture and must stay: the
  IDENTIFY capacity and the LBA unit are both 2048-based. Do not switch it to 2064 or
  2352: `1064208 × 2048` matches the ISO exactly, and an IDENTIFY word 100-103 built from
  a different divisor would make `sr` refuse reads past a wrong capacity.
* **2064 belongs to a different channel** (`_IDECLI_OddRead`, the SACD raw-frame path in
  `PHASE0-RESULTS.md`), not to the SATA READ CD path. `fe_test_data` is likewise **not** a
  disc fixture — it is a NAND partition name (`sata-fw-load.md` §"Partition binding",
  `.bss+0x30`, `records=0`), so it contributes nothing to the read path. (The C97 brief
  named it as a fixture source; that is a mis-read of `sata-fw-load.md`.)

### 4.4 The raw-mode switch: where `2352` comes from (DECODED write, INFERRED trigger)

```
qc_issu_task 0x6e9c:  r3 = priv+0x18 ; if (r3 - 8) > 2  ⇒ 0x6fcc (no rewrite, 2048 mode)
             0x6ebc:  cdb[0] = 0xBE                       (mvn #65 ⇒ 0xbe)
             0x6ec4..0x6ee8: cdb[6]=nsec>>16, cdb[7]=nsec>>8, cdb[8]=nsec,
                              cdb[9] = 0xF8, cdb[10] = 0
             0x6ef4..0x6f04: priv+0x54 = nsec × 2352 ; priv+0x1c = 1 (0x74d0)
```
`priv+0x18` is written **only** by the vendor CDB `0x46` with `cdb[1] == 1`:
`hw_chg_st` 0x4360..0x4384 → `priv+0x18 = (cdb[6] << 8) | cdb[7]`, and values `64..67`
take a *different* branch (`0x438c..0x43c0`, `0x600`, `priv+0x84/0x6c`). So the raw-2352
mode is selected by a vendor command the application sent earlier — **INFERRED**: values
`8/9/10` mean "return raw CD frames". Settling experiment: the C97 trace shows either
`W 05c404 = 32 × 2352` for a 32-sector read (raw mode active) or `= 32 × 2048`
(plain mode). Either way the *model* does not have to guess: the opcode it receives says
which framing to emit (`0xBE` + byte9 `0xF8` ⇒ 2352; `0x28`/`0xA8` ⇒ 2048).

---

## 5. Model recipe — C97 rows

Continues `fe-ata-cmd.md` §5.1 (rows 1-16 there; rows 1-16 are unchanged and all still
required — in particular rows 8-10, the `0x5c800` mask, without which nothing is
observed). Current `emulator-kit/sony-bx510.c` already stores `0x5c400..0x40c`
(`fe_dma[]`), so rows 17-20 are verification, not new work; the new work is the
row 21-24 dispatch delta.

### 5.1 Registers

| # | reg (VA) | driver op | model must |
|---|---|---|---|
| 17 | `0xfd05c400` | `W` (`data_xfer` 0x583c) | store; it is a **guest physical** address (§0.2) |
| 18 | `0xfd05c404` | `W` (0x5844) | store; it is the **authoritative DMA length** |
| 19 | `0xfd05c408` | `R`+`W` RMW `\|= 0x100` (0x5848..0x5850) | store + lossless readback (already) |
| 20 | `0xfd05c40c` | `W =1` (0x5814), then `R`+`W` RMW `\|= 0x600` (0x5870..0x5878), and `W =0` on the next non-READ completion (`hw_chg_st` 0x4428) | store + lossless readback (already). **`& 1` is the armed flag**; never auto-clear |

### 5.2 Dispatch delta on the `0x5c020` doorbell — order matters

Evaluate in this order, **before** the existing `code`/`type` ladder:

| # | condition | meaning | model action |
|---|---|---|---|
| 21 | `(fe_dma[3] & 1) != 0` **and** `cdb[0] ∈ {0x28,0xA8,0xBE}` | `data_xfer`'s READ-CDB post (C97 cmd) | decode §4.1; build `fe_dma[1]` bytes (§4.2/§4.3); `stb_phys` them to `fe_dma[0]`; `bx510_fe_post(s, 0, 0, 0, 0)`; **no type-0x10** |
| 22 | `(fe_dma[3] & 1) != 0` but the opcode is not a READ | descriptor stale (should not happen — `hw_chg_st` 0x4428 disarms) | log loudly once (`LOG_GUEST_ERROR`), then serve as a plain type-0 completion. Do **not** DMA. |
| 23 | `lba + nsec > blk_getlength()/2048` | read past EOF | serve nothing (or the in-range prefix) and post a type-0 with **`byte3 != 0`** ⇒ `hw_chg_st(priv,5)` ⇒ status `0x51` |
| 24 | otherwise | IDENTIFY / chk / ack / reset | unchanged from `fe-ata-cmd.md` §5.2 |

Then the two hard rules from §5.2 of `fe-ata-cmd.md` unchanged: stage the block, then raise
`0x5c804 |= 0x10000`; and drain to a zero read so the top half's loop terminates.

### 5.3 State machine the model is driving (for the row-21 reply to be right)

`priv+0x220` has exactly one writer (`hw_chg_st` 0x4070) and these transitions are the ones
a READ walks (`0x4668..0x46b8`, `0x5728`, `0x5e04..0x5e50`):

| state | set by | `check_status` |
|---|---|---|
| 3 | (the pre-command state; `data_xfer`'s READ branch requires it, 0x5480) | `0x58` (RDY\|DSC\|DRQ) |
| 1 | `data_xfer` 0x5728 (`hw_chg_st(priv,1)`) — right after the post | `0xd0` |
| 2 | the type-0 success reply, `0x46b8` | `0x58` (DRQ — the data phase) |
| 5 | any `byte3 != 0` reply, `0x4894` | `0x51` (RDY\|DSC\|ERR) |
| 0 | type-0 success with `priv+0x48 == 0`, `0x4840` | `0x50` |

So a correct READ is exactly `3 → 1 → 2`, and the model's single type-0/byte3-0 reply is
what performs `1 → 2`.

---

## 6. Expected observable for C97

**Check 1 — the MMIO signature of an armed READ** (in this order, all inside one
`data_xfer` call, then the mailbox post):

```
W 05c40c = 1
W 05c400 = <phys, 16-aligned, < ram_size>
W 05c404 = <nsec*2352 or nbytes, <= 0x12800>
R 05c408 ; W 05c408 = <read | 0x100>
R 05c40c ; W 05c40c = 0x601
W 05c000 = 0xa1000000        (w0: byte3 = priv+0x29c)
W 05c004 = <be 00 ll ll>     (w1 = cdb[0..3], cdb[0] = 0xBE or 0x28/0xA8)
W 05c008 / W 05c00c = <cdb[4..11]>
R 05c020 ; W 05c020 = <read | 1>
R 05c804 = 0x10000           ← the FE answered (never appears in C95)
R 05c800 = 0xfffffff0
R 05c040 = 0 (type 0, byte3 0) ; R 05c044/048/04c = 0
R 05c804 ; W 05c804          (drain)
```

**Absence to check too:** exactly **one** `R 05c040/044/048/04c` quadruple per READ; a
second quadruple means the model posted two messages (row 21 violated) and the payload is
suspect.

**Check 2 — the guest reaches the data phase without an error signature.** `dmesg`/UART has
no `ata1.00: qc timeout` and no EH `SRST` retry block for that command; libata reports the
transfer complete, and `sr0` (or the caller) receives the payload.

**Check 3 — the `0xbb` poison is gone** (cheapest discriminator, §3.3): the first 16 bytes
of the destination buffer are not `bb bb bb bb bb bb bb bb bb bb bb bb bb bb bb bb`. A guest
that "succeeds" with a poisoned head means the FE advanced the state machine without
performing the DMA.

**Check 4 — payload equality with the fixture** (the acceptance check; raw mode):

```sh
# host, from the same image the model was given
dd if=firebird.iso bs=2048 skip=<LBA> count=1 2>/dev/null | md5sum
# guest/model: md5 of the 2048 bytes the driver stripped for that sector, i.e.
#   raw mode  : frame(lba)[16..2063]   (mode 1)   /  frame(lba)[24..2071] (mode 2)
#   plain mode: buffer[lba_index*2048 .. +2047]
```
For a 32-sector raw read the whole payload can be compared at once:
`for i in $(seq 0 31); do …; done` or a single `dd … bs=2048 skip=<LBA> count=32 | md5sum`
against the concatenation of the 32 stripped payloads. A constant off-by-8 in every frame
means the model picked the wrong mode byte (§4.2); a constant off-by-2048 shift means the
LBA decode used the wrong byte order (cdb[2..5] is **big-endian**).

**Check 5 — the fixture-scale read.** A full-disc sweep is the stage-4 job, not C97's; the
C97 gate is one known LBA plus one past-EOF READ that must produce status `0x51`
(row 23).

---

## 7. Conflicts and corrections to earlier docs

1. **`fe-ata-cmd.md` §1.2**: "the model only has to accept the writes (and, if it chooses to
   model DMA, may use them; the reply itself still arrives as a mailbox reply message)."
   Corrected: for a READ the descriptor **is** the data path — accepting the writes without
   DMAing yields a poisoned payload and a libata transfer of garbage. The reply shape is a
   bare type-0 (no window payload), not the type-0x10 used for IDENTIFY.
2. **`fe-ata-cmd.md` §9 last row** ("2352-byte-sector vs 2048 PIO path for real disc reads —
   not in scope") — now decoded: §4.1/§4.2, and the driver's own strip loop settles the
   frame layout.
3. **`fe-ata-cmd.md` / brief**: `priv+0x38` was described as a device-type-ish field whose
   `(x-5)<=2` means ATAPI. Refined: `priv+0x38` **is `qc->tf.protocol`** (`qc_prep` 0x2ee8).
   The gate semantics are unchanged, the name is now known.
4. **`fe-ata-cmd.md` §5.1 row 12**: "store and return what was written (RMW must be
   lossless)" — still exactly right, and §2.2 here explains *why* (the driver's `ldr/orr/str`
   would otherwise fold model state into its own).
5. **C97 brief**: "the `fe_test_data` fixture layout" — `fe_test_data` is a NAND partition
   (`.bss+0x30`, `records=0`, `sata-fw-load.md` §"Partition binding"), not a disc data
   fixture. The only read-path fixture is the disc image.
6. **C97 brief**: "2068-byte vs 2048-byte SACD sectors" — the documented raw SACD frame is
   **2064** (`docs/large-image-interface.md`: 12-byte header + 2048 logical + 4 trailing;
   `docs/DAEMON-MAP.md`: 2048 payload + 16-byte header), it belongs to the `_IDECLI_OddRead`
   channel, and it is **not** the frame this path carries (2352 here).

---

## 8. Instruction-site index (every claim above)

| claim | site(s) |
|---|---|
| `qc+0x10` = tf.flags, `qc+0x14` = tf.protocol, `qc+0x24` = cdb[0] | `qc_prep` 0x2ed8/0x2edc/0x2f04; `qc_issue` 0x369c; `qc_issu_task` 0x6e38 |
| `priv+0x38` = protocol | `qc_prep` 0x2ee8 |
| `priv+0x48` = direction (0/1/2) | `qc_prep` 0x2eec-0x2f18; 0 cleared by `softreset` 0x4f64, `prereset` 0x51c0 |
| length seed / cursor reset | `qc_issu_task` 0x6cc0-0x6ce0 |
| LBA → `priv+0x2c`, len → `priv+0x30` | `qc_issu_task` 0x6e48-0x6e98 |
| READ(10)/READ(12) → READ CD 0xBE, byte9 `0xF8` | `qc_issu_task` 0x6e9c-0x6ee8 (gated by `priv+0x18 ∈ {8,9,10}`) |
| `priv+0x54 = nsec × 2352` | `qc_issu_task` 0x6ef4-0x6f04 |
| bounce buffer kmalloc / `priv+0x4c`,`+0x5c` | `qc_issu_task` 0x6f4c-0x6f70; reuse 0x74d8-0x74e4 |
| `priv+0x1c = 1` (raw-frame flag) | `qc_issu_task` 0x74cc/0x74d0; `= 0` at 0x6fcc/0x6fd0 |
| `0xbb` poison | `qc_issu_task` 0x7114-0x7148 — head: `mov r1,#187` at 0x7468 with len `min(priv+0x54,16)`; tail: `0xbbbbbbbb` store at 0x7144, literal `0x754c`, ATA-class only |
| CDB copy to `priv+0x24` | `qc_issu_task` 0x704c-0x7068 |
| `priv+0x50 = buf_va + 0x40000000` (phys) | `qc_issu_task` 0x7090/0x7098 (dir ≠ 1: 0x7084 first flushes the buffer) |
| write-direction sg→bounce copy | `qc_issu_task` 0x71f8-0x7284 |
| descriptor arm | `data_xfer` 0x5810-0x587c |
| descriptor is armed only for READ CDBs | `data_xfer` 0x570c-0x5724 |
| `hw_chg_st(priv,1)` then mailbox post | `data_xfer` 0x5728-0x57e8 |
| disarm `0x5c40c = 0` | `hw_chg_st` 0x40cc/0x40d4 → 0x4420/0x4428 |
| `priv+0x50 = 0` on completion | `hw_chg_st` 0x4038/0x4044, 0x418c/0x4190 |
| `priv+0x220 = new_state` | `hw_chg_st` 0x4070 |
| type-0 / byte3 / direction dispatch | bottom half 0x4668-0x46b8 |
| dir 1 ⇒ invalidate only (no copy) | bottom half 0x48ec/0x48f8 |
| type-0x10 window copies (both directions) | bottom half 0x47ac-0x48d8 |
| data-phase copy from the bounce buffer | `data_xfer` 0x5488-0x54a8, 0x554c-0x5560 |
| 2352-byte strip loop, mode byte at frame+0xf | `data_xfer` 0x54ac-0x5500 |
| cursor advance / completion | `data_xfer` 0x558c-0x55b4 |
| status byte from state | `check_status` 0x5e04-0x5e50, 0x5eec |
| `0x5c400` never read | module-wide: only 0x5814/0x583c/0x5844/0x5848/0x5850/0x5870/0x5878 + 0x4428 |
| page offset `0xc0000000`, physical 0 | `decode/kernel-iomap.md` §"`0xc0000000`, physical offset 0" (VERIFIED) |
| RAM at phys 0, 512 MiB | `emulator-kit/sony-bx510.c` 0x880 (`memory_region_init_ram(machine->ram, 0, …)`), 0x965 (`default_ram_size = 512 MiB`) |
| fixture geometry | `docs/DAEMON-MAP.md` §"2064 and 2048"; `docs/large-image-interface.md` |
| model: `sata_blk` opened, never read | `emulator-kit/sony-bx510.c` (only `blk_getlength` at `bx510_sata_build_identify`) |

---

## 9. Open items with their settling experiments

| item | label | experiment |
|---|---|---|
| which state the port is in when the CDB phase runs (`priv+0x220 == 3`) | DECODED gate, state-3 writer not found in this module | C97 trace: if the `05c40c/400/404/408` quadruple never appears, `data_xfer` took the non-mailbox body ⇒ state ≠ 3. Not model-actionable (the model cannot see `priv+0x220`), but it decides whether the read is even posted |
| the raw-mode trigger (`priv+0x18 ∈ {8,9,10}` meaning) | INFERRED | C97: `W 05c404` is `nsec×2352` (raw) or `nsec×2048` (plain) — the trace answers it without any model change |
| mode 1 vs mode 2 framing (payload at 16 vs 24) | INFERRED (mode 1 is the default choice) | §6 check 4: a uniform 8-byte shift in the guest payload means the model's frame byte 15 said 2 |
| the vendor CDB `0x46` path (`hw_chg_st` 0x4360, values 64..67 → `0x600`) and how it relates to the 2064-byte SACD frame | not decoded — outside C97 | C97+ trace: does a `cdb[0] == 0x46` ever reach `data_xfer`? If yes, that post has **no** descriptor (0x5710 only matches 0x28/0xA8/0xBE) and its data must come another way — a separate stage |
| whether the FE's raw frames need a real MSF header (bytes 12..14) | INFERRED cosmetic (driver reads only byte 15) | if a later layer validates MSF, the symptom is a media-check failure with correct payloads |
| reads >> 32 sectors (driver caps `priv+0x54` at `0x12800`) | DECODED cap | trace: libata splits large reads into ≤`0x12800`-byte qcs; if not, the driver's `0x6e00`/`0x74e0` `bhi` takes an error path |
| `qc_issu_task`'s caller | INFERRED (deferred work; no `bl 0x6c94` exists in the module, so it is a function pointer / work item) | not model-actionable; the load-bearing fact is that the fields it writes are exactly the ones `data_xfer`'s READ branch consumes |
