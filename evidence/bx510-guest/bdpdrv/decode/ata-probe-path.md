# BX510 ATA probe path — what the guest touches after `port_start`, and what the model must answer

Decode of the libata/SFF probe path that runs **after** `sata_mt85xx_port_start`
completes its FE handshake: the port-window register map, the ordered probe
sequence, the driver's `ata_port_operations` hook set, and the model additions
needed for the disc to appear.

**Scope honesty up front.** `libata.ko` is **not present Mac-side** (`/tmp/bdpdrv/`
holds only `bdpdrv.ko`, `sata_mt85xx_mod.ko` and disassembly text; a bounded
search of `/tmp` and the repo found no copy, and there is no `/tmp/sata_staging`
on this machine). Everything below is therefore decoded **from
`sata_mt85xx_mod.ko` alone** — its own instruction stream, its literal pools, its
relocations and its `ata_port_operations` struct. Statements that depend on
libata's internals (the *order* in which libata calls these hooks, and the
`ata_ioports` field *values* the shim installed) are labelled **INFERRED** and
carry the experiment that would settle them.

| field | value |
|---|---|
| module | `/tmp/bdpdrv/sata_mt85xx_mod.ko` |
| sha256 | `8a0253eb9bff19a3d3c0ac594a507235bad82348d8e80069024368d0f5456657` (re-verified by the script, pinned constant) |
| build | ARM EABI5 `ET_REL`, Linux 2.6.35, not stripped, every section `sh_addr = 0` |
| addresses | section-relative (`.text+0x…`); MMIO as kernel VA `0xfd00a…` with PA `0x7000a…` (VA = PA + `0x8d000000`, `kernel-iomap.md` §2) |
| companion | `decode/ata_probe_regs.py` — emits the table below and replays the driver's compares against a mock model (13 checks incl. 6 mutants; `ALL CHECKS PASS`) |

All instruction addresses and every register offset below are produced
mechanically by `ata_probe_regs.py` (constant propagation over
`llvm-objdump -d`, literal pools joined to `.rel.text`), not by reading
hexdumps. `make sacd-py SCRIPT=evidence/bx510-guest/bdpdrv/decode/ata_probe_regs.py`
re-runs the whole decode + checks.

---

## 1. Bottom line

1. **The port window is `0xfd00a000..0xfd00afff`** (`base + 0xfd000000 +
   0xa000`; every access in the module is built from one of those two literals).
   Inside it the driver touches **19 distinct offsets**, listed in §2. The
   model implements **8** of them (`0xa004..0xa018`, `0xa01c`, `0xa220`,
   `0xa400`, `0xa480`, `0xa610`, `0xa648`, `0xa6c8`) — and three of the 19 are
   missing or mis-shaped in ways that matter (§2.1).
2. **The probe does not use DMA and does not use SCR programming.** The module
   installs **no `scr_read`/`scr_write` hooks at all** (§4), so `sata_link_resume`
   never issues a SCR access on this controller — the model needs **no SCR
   aliasing**. Likewise `bmdma_setup`/`bmdma_start` exist but sit on the
   `.inherits = &ata_sff_port_ops` chain and the probe's IDENTIFY path runs
   **PIO** (`sata_mt85xx_data_xfer`, §5).
3. **`chk_int_ldr` is called by `port_start` at exactly three sites, and they
   are on two mutually exclusive paths**: `.text+0x32c8` (state-1 fast path,
   *after* the AACS download) and the probe-path pair `.text+0x32f8` →
   `xfer_int_ldr_fw` → `.text+0x3314`. Only call #2 has its return value
   checked (`0x32fc: cmp r0,#0; bne 0x31c8` — a non-zero return *silently skips
   the FW download*).
4. **The disc becomes visible only if three things hold**: the link poll reads
   `0x37` in `[21:16]` of `0xa610`; the taskfile carries the ATAPI signature
   (lbal/lbam/lbah = `0x01`,`0x14`,`0xeb` → the `0x00eb1401` compare at
   `.text+0x32e0`); and the status word `0xa01c` reads `0x50` or `0`. Nothing
   else in `port_start` gates it.
5. **What libata does *after* `port_start` cannot be seen from this module** —
   see §3 for why the observable is the model's own UNIMP log rather than a
   code citation.

---

## 2. Register map — offsets inside the port window (`0xfd00a000`)

Emitted by `ata_probe_regs.py`; `cite` is the instruction (or literal-pool slot)
the row is read from, and the script fails if the scanner cannot reproduce it.

| off | name | access | phase | cite | semantics |
|---|---|---|---|---|---|
| 0x00c | ATA_CMD0 | W | fe-cmd | .text+0x1fe8 | word 0 of the ATA command handed to the FE (`send_atapi_cmd` 0x1fe8, `xfer_fe_data` 0x2198, `trig_fe_boot` 0x2528) |
| 0x010 | ATA_CMD1 | W | fe-cmd | .text+0x2008 | word 1 of the same command block |
| 0x014 | ATA_CMD2 | W | fe-cmd | .text+0x2028 | word 2; read back before issue |
| 0x01c | ATA_STATUS_CMD | RW | probe | .text+0x3144 | status (read) / command (write); polled 2500×10 ms accepting `0x50` or `0` |
| 0x080 | CH_IRQ_EN | RW | probe | pool 0x3430 | `port_start` clears bit8 (0x31e0) before re-enabling the channel |
| 0x108 | FE_DATA | RW | probe | .text+0x1f74 | FE command/data word; write `0x20`; `trig_fe_boot` sets bit15 and polls it back |
| 0x114 | PHY_CH_EN | RW | probe | .text+0x2ffc | 8-bit per-channel field at bit `ch*8+3`: clear the byte, write `0x08<<(ch*8)` |
| 0x220 | IRQ_STATUS | RW | probe | .text+0x2238 | ATA IRQ status, W1C (model has it) |
| 0x25c | PIO_BURST | W | identify | pool 0x5af0 | `data_xfer`'s store port — **seven consecutive 32-bit stores** per call |
| 0x400 | CH_CTRL | RW | probe | .text+0x2ff4 | write `0x801`, clear bit0, then set bit8 (`0x100`) |
| 0x604 | PHY_CFG0 | RW | probe | .text+0x3040 | `|=0xf` (0x304c), `&=~0xf` (0x30b8), `|=0x1` (0x30c0) — a reset pulse bracketing link-up |
| 0x610 | LINK_STATUS | R | probe | .text+0x3100 | `(v>>16)&0x3f` must read `0x37` (55) = link up; 50×10 ms |
| 0x620 | PHY_CFG1 | RW | probe | .text+0x3074 | `|= 0x3f` before the link poll |
| 0x634 | PHY_CFG2 | RW | probe | .text+0x3088 | clear `0xe6000000`, set `0xa4000000` (speed/width field) |
| 0x648 | CH_BUSY | R | probe | pool 0x50dc | per-channel busy poll, bits[12:8] must clear (model returns 0 ✔) |
| 0x680 | PHY_CFG3 | RW | probe | pool 0x3434 | clear `0x3c0000` (0x3200); `0x680+0x48` gets `0xffffdffc` (0x3218) |
| 0x6b8 | PHY_STATUS | R | probe | pool 0x4500 | link/PHY status word (`_hw_chg_st` 0x4500, `data_xfer` 0x5ae4), byte lane +1 = secondary state |
| 0x6c4 | PHY_STATUS_2 | RW | probe | pool 0x50f4 | second PHY status word (`softreset` 0x50f4, `_hw_chg_st` 0x6824) |
| 0x6c8 | IRQ_MASK | RW | probe | pool 0x3434 | `0xffffdffc` = unmask all but two (model has it) |

`phase` = **probe** (needed before the disc appears), **identify** (needed for
IDENTIFY data), **fe-cmd** (needed when the FE path issues an ATA command).

### 2.1 Three corrections to the model's current map

1. **`0xa600` is never accessed as a 32-bit register.** Every PHY access is at
   `0xa604`, `0xa610`, `0xa620`, `0xa634`, `0xa680`, `0xa6c8` — the model's
   `case 0xa600:` (signature readback) is dead code for `port_start`, and
   `0xa604/0xa620/0xa634/0xa680` fall into `default:` → `LOG_UNIMP`. The
   signature the probe actually checks is recomposed from **lbal/lbam/lbah**
   (§6), not read as one word.
2. **`0xa01c` is the status/command word**, polled with the accept set
   `{0x50, 0x00}` (`.text+0x3144`: `cmp r10,#80; cmpne r10,#0`). The model
   returns the last *command byte* there; that happens to satisfy the poll
   (`0x00` is accepted) but it is not a status model — after a real IDENTIFY the
   driver reads status through here on every IRQ (`sff_check_status`,
   `.text+0x5ce8`).
3. **`0xa25c` (PIO burst) and `0xa108` (FE data) are missing entirely.**
   `0xa108` is the busiest register in the module (11 accesses across five
   functions).

### 2.2 The taskfile block — the one genuinely unresolved offset question

`sata_mt85xx_tf_load` / `tf_read` / `check_status` do **not** use hard-coded
addresses: they load a per-register offset out of the `struct ata_ioports`
block inside `struct ata_port` and add the folded window base
(`add rX, rX, #-0x03000000; add rX, rX, #0xa000` — a 30-instruction pattern the
scanner tags `ioaddr:<field>`):

| `ap` offset | `ata_ioports` field | used by | off |
|---|---|---|---|
| +0x24 | `error_addr` | `tf_read` .text+0x5fc4 | ? |
| +0x28 | `feature_addr` | `tf_load` .text+0x38a0 | ? |
| +0x2c | `nsect_addr` | `tf_load` 0x38b4 / `tf_read` 0x5fd8 | ? |
| +0x30 | `lbal_addr` | `tf_load` 0x38c8, `port_start` 0x3188 (signature!) | ? |
| +0x34 | `lbam_addr` | `tf_load` 0x38dc, `port_start` 0x3190 | ? |
| +0x38 | `lbah_addr` | `tf_load` 0x38f0, `port_start` 0x319c | ? |
| +0x40 | `status_addr` | `check_status` .text+0x5d28 | ? |
| +0x44 | `command_addr` | `exec_command` .text+0x5bd4 | ? |
| +0x48 | `altstatus_addr` | `check_altstatus` .text+0x63a4 | ? |
| +0x4c | `ctl_addr` | `tf_load` .text+0x3858 | ? |
| +0x54 | `scr_addr` | (present, unused — no scr hooks) | ? |

**The values are set outside this module** (by the shim/libata glue) and are
therefore **UNRESOLVED without `libata.ko` or a guest trace**. What the module
*does* pin down:

* All accesses are **32-bit** (`ldr`/`str`, never `ldrb`/`strb`), and the
  register that lands at `0xa01c` is the status/command word.
* A **4-byte register stride** is the only arrangement consistent with a
  status word at `+0x1c` (check `C3n` in the script): a classic byte-strided
  SFF map would put status at `+0x7` (`0xa007`), contradicting the literal
  `0xfd00a01c` at `.text+0x3144`.
* Under that stride the natural map is `0x000` data, `0x004` error, `0x008`
  feature, `0x00c` nsect, `0x010` lbal, `0x014` lbam, `0x018` lbah,
  `0x01c` device/status/command aliased — which is **exactly** the 6-word block
  the model already implements (`0xa004..0xa018`) plus `0xa01c`. So the model's
  taskfile block is *right in shape*, and the `0xa00c/0x010/0x014` writes the
  module also makes (rows ATA_CMD0/1/2 above) land on the same words the
  taskfile mirror uses.
* **Settling experiment** (cheap, next rig run): the model already logs every
  unimplemented access. Read `0xfd00a0…` addresses out of that log and the
  stride/aliasing question becomes a measurement, not an inference. Note the
  archived logs `/tmp/bdpdrv-runC5{5,6,7}.mmio.log` predate the SATA phase
  (their newest lines are `0x700503xx`), so they cannot answer it.

---

## 3. Probe sequence

`port_start` is `.text+0x2fac` (size `0x4c0`). Two entry branches, keyed on the
driver's own port struct `[port+0x8]`:

```
port_start(ap)                              ; r9 = ap, r5 = driver port struct
 0x2fd4  if (port[0x8] == 1) -> 0x3230          ; "state 1" fast path (post-AACS)
 ---- probe path (state != 1) ------------------------------------------------
 0x2fe0  window bring-up (all near-direct, driver port base [port+0x10]):
         base[0xa400] = 0x801                                    (0x2ff4)
         base[0xa114]: clear channel byte, then |= 0x08<<(ch*8)  (0x2ffc..0x3028)
         base[0xa604] |= 0xf                                     (0x3040..0x304c)
         base[0xa400] &= ~1                                      (0x3060..0x3068)
         base[0xa620] |= 0x3f                                    (0x3074)
         base[0xa634]: &= ~0xe6000000, |= 0xa4000000             (0x3088..0x3094)
         base[0xa400] |= 0x100                                   (0x30a4)
         base[0xa604] &= ~0xf ; base[0xa604] |= 0x1               (0x30b8..0x30d8)
 0x30ec  poll 50 x 10 ms:  (base[0xa610] >> 16) & 0x3f == 0x37  ; link up
 0x3144  poll 2500 x 10 ms: base[0xa01c] in {0x50, 0x00}         ; device ready
 0x316c  sig = lbah<<16 | lbam<<8 | lbal   (via ioaddr +0x38/0x34/0x30)
 0x31c0  if (!reset_poll_ok)         -> shared tail 0x31c8
 0x32e0  if (sig != 0x00eb1401)      -> shared tail 0x31c8   ; not ATAPI: skip FW
 0x32f8  chk_int_ldr(port, &port[0x208])            ; call #2, RET CHECKED
 0x32fc    if (ret != 0) -> 0x31c8                   ;   error: skip FW download
 0x3308  xfer_int_ldr_fw(port->[0x4])               ; stage FW + FE DMA window
 0x3314  chk_int_ldr(port, &port[0x208])            ; call #3, RET IGNORED
 0x3318  -> shared tail 0x31c8
 ---- shared tail ------------------------------------------------------------
 0x31c8  _fg_fe_bootup = 1
 0x31d4  base[0xa080] &= ~0x100 (via driver port [port+0x14] path)
 0x31f0  base[0xa680+0x48 = 0xa6c8] = 0xffffdffc
 0x321c  return 0
 ---- state == 1 fast path ---------------------------------------------------
 0x3230  if (*(.bss+0x80) != 0) -> 0x32b0
 0x3244  poll 150 x 10 ms on FE status 0xfd05c804 (bit16), clearing reads
 0x32b0  xfer_int_ldr_aacs_data(port)
 0x32b4  _fg_fe_bootup = 1
 0x32c8  chk_int_ldr(port, &port[0x208])            ; call #1, RET IGNORED
 0x32d8  *(u32*)0xfd05c800 = 0xfffffff0             ; clear all FE interrupts
 0x32dc  -> return 0
```

**Two-message reply consumption** (`chk_int_ldr`, `.text+0x2810`, fully decoded
in `fe-status-handshake.md` §3 and re-verified here by checks `C5/C5m/C5n`):

```
post CPU->FE command (0xfd05c000 block, word0 byte3 = 0xa1) + doorbell 0xfd05c020 |= 1
loop (bounded 200 x 10 ms per message, counter reset per message):
   r = *(u32*)0xfd05c804 ; r6 |= r ; str r6 -> 0xfd05c804   (read-and-clear)
   if !(r6 & 0x10000) -> msleep(10), retry
   w0..w3 = 0xfd05c040/44/48/4c
   type = byte2(w0)
   type == 0x10 -> memcpy(buf, dram + w1, min(w2,512)); ACK; loop
   type == 0    -> err = byte3(w0); err==0 ? acceptance gate : Command Error
   type == other-> loop forever (counter reset at 0x2880)
acceptance gate: buf[0x2e..0x31] == 'O','B','T','O' and LE16(buf[0x100]) == 0xeeee
                 -> *out (port[0x208]) = 1 ; return byte3(w0)
```

The model must therefore post **two** messages per `chk_int_ldr` call with
`0x5c804` bit16 raised only while a message is pending (that is already the
`fe_msg` behaviour in `emulator-kit/sony-bx510.c`), and must DMA the 512-byte
table block whose `0x2e..0x31`/`0x100` bytes carry the magic.

**What runs after `ata_host_activate` — INFERRED.** libata's post-activate
probe (`ata_port_probe` → `sata_link_resume` → `ata_dev_read_id`, i.e.
IDENTIFY) is **not visible in this module**: the module supplies *hooks*, not a
sequence, and `libata.ko` is absent so the caller order cannot be cited. The
hooks the probe will necessarily drive, all VERIFIED present in the module's
`ata_port_operations` (.data+0x138, see §4): `prereset`/`softreset`/`postreset`
(reset + signature), `tf_load` (taskfile programming), `exec_command` (command
issue), `check_status`/`check_altstatus` (status polling), `data_xfer`
(IDENTIFY payload). The right observable is the model's UNIMP log on the next
fire — it names every access libata makes, which is a stronger artifact than a
reconstructed call order.

---

## 4. Hooks — the module's `ata_port_operations`

`struct ata_port_operations` is **`.data+0x138`** (the module keeps it
non-`const`; the `scsi_host_template` precedes it at `.data+0xa0`, whose last
field `ata_common_sdev_attrs` sits at `.data+0x124`). The **symbol at each
offset is VERIFIED** from the 32 `.rel.data` relocations; the **field names are
INFERRED** from libata 2.6.35's declaration order (no `libata.ko` to check the
header), and the order is self-consistent: 0x138/0x140/0x144 are three
consecutive `qc_*` slots with a NULL at 0x13c, `port_start`/`port_stop` are
adjacent at 0x84/0x88, and the last field is the `inherits` pointer.

| off | hook | module symbol | off | hook | module symbol |
|---|---|---|---|---|---|
| 0x00 | qc_defer | `sata_mt85xx_qc_defer` | 0x80 | port_start | `sata_mt85xx_port_start` |
| 0x08 | qc_prep | `sata_mt85xx_qc_prep` | 0x88 | port_stop | `sata_mt85xx_port_stop` |
| 0x0c | qc_issue | `sata_mt85xx_qc_issue` | 0x90 | dev_select | `sata_mt85xx_dev_select` |
| 0x30 | freeze | `sata_mt85xx_freeze` | 0x98 | check_status | `sata_mt85xx_check_status` |
| 0x38 | prereset | `sata_mt85xx_prereset` | 0x9c | check_altstatus | `sata_mt85xx_check_altstatus` |
| 0x3c | softreset | `sata_mt85xx_softreset` | 0xa0 | tf_load | `sata_mt85xx_tf_load` |
| 0x44 | postreset | `sata_mt85xx_postreset` | 0xa4 | tf_read | `sata_mt85xx_tf_read` |
|      |      |      | 0xa8 | exec_command | `sata_mt85xx_exec_command` |
|      |      |      | 0xac | data_xfer | `sata_mt85xx_data_xfer` |
|      |      |      | 0xb0 | irq_on | `sata_mt85xx_irq_on` |
|      |      |      | 0xc0 | bmdma_setup | `sata_mt85xx_bmdma_setup` |
|      |      |      | 0xc4 | bmdma_start | `sata_mt85xx_bmdma_start` |
|      |      |      | 0xc8 | bmdma_stop | `sata_mt85xx_bmdma_stop` |
|      |      |      | 0xcc | bmdma_status | `sata_mt85xx_bmdma_status` |
| 0xe8 | **inherits** | `ata_sff_port_ops` | | | |

Two facts that decide model scope:

* **No `scr_read` / `scr_write` hook.** The window has 15 `ata_ioports`
  pointers including `scr_addr` (+0x54), but the ops struct has no SCR method,
  so `sata_link_resume` (if libata calls it) falls back to the inherited
  `ata_sff_port_ops` chain, which for this driver has no SCR accessor. **The
  model does not need SCR aliases** — `0xa610`/`0xa648` are ordinary PHY/busy
  registers, not SCR aliases. (Which *value* `scr_addr` was given is
  UNRESOLVED; it is never dereferenced in this module.)
* **`read_id` is not overridden** → IDENTIFY goes through the SFF taskfile +
  `data_xfer` path, i.e. **PIO**. `bmdma_*` hooks exist (a packet path used by
  `qc_issu_task`), and `bmdma_setup` writes the *command* word to
  `ioaddr.command_addr` (`.text+0x540c/0x5414`), but no PRD table register
  appears anywhere in the probe path — **no DMA handshake is needed for the disc to appear**.

`irq_on`, `freeze` and `dev_select` are all the **same 4-byte stub**
(`bx lr` at `.text+0x2ed0` / `0x2ec8` / `0x2ecc`) — the driver does not gate
interrupts per-port at all, so nothing in the model has to be conditioned on an
`irq_on` call.

---

## 5. IDENTIFY (`ata_dev_read_id`) — what the model must answer

Decoded from `sata_mt85xx_data_xfer` (`.text+0x5434`), `exec_command`
(`.text+0x5b28`), `check_status` (`.text+0x5ce8`):

```
tf_load         writes the 6-word taskfile (+ ctl at ioaddr ctl, value & 0xfd)
exec_command    str command byte -> ioaddr.command_addr (same word as status)
                (.text+0x5bd4..0x5be4)
check_status    (a) reads status twice 8x until two consecutive reads agree
                    (.text+0x5d3c: ldr/ldr/cmp loop, bound 8)
                (b) then maps *its own cached engine state* [port+0x220] to the
                    returned status byte: state 4 -> 0xd0, state 6 -> 0x50,
                    state 5 -> 0x51, states 2/3 -> their own register read
                    (0x5d54..0x5db4). The poll therefore never sees a value the
                    model has to synthesise — it sees what 0xa01c returns.
data_xfer       stores the payload 32 bits at a time to 0xa25c
                (7 stores visible at 0x5748..0x5764), plus FE mailbox activity
                at 0x5c400/0x5c408/0x5c40c when the FE path is taken
IRQ             status bit0 of 0xa220, W1C; BIM `pending2` bit21 raises virq 53
                (kernel-iomap.md)
```

So the model's current behaviour — "any command write completes instantly, sets
`0xa220` bit0 and BIM `pending2` bit21, and the IDENTIFY payload is read from
`0xa000`" — is **the right shape**: PIO, no DMA, IRQ on completion. The gaps are
(a) `0xa25c` does not exist in the model (only `0xa000` is handled), (b)
`check_status`'s cached-state mapping means the value the model returns at
`0xa01c` must be stable across two consecutive reads (the model's
`s->sata_cmd` is stable ✔, but it should be a *status* model: `0x50` after a
successful command, `0x00` when idle), and (c) the ATAPI signature must be
present in the taskfile words the driver reads at `port_start` (`0x010/0x014/
0x018` per §2.2's stride), because that is what decides whether the driver
believes an ATAPI device is there at all.

---

## 6. Model additions — register → semantics → run phase

| # | register | semantics the driver accepts | phase | model change |
|---|---|---|---|---|
| 1 | `0xa604` | `|=0xf`, `&=~0xf`, `|=0x1` (reset pulse) | probe | add case: plain read/write RMW storage (return last written) |
| 2 | `0xa610` | `(v>>16)&0x3f == 0x37` **only when media present**; `0x22` when absent | probe | keep, but make it media-scoped §(model already does) |
| 3 | `0xa620` | `|=0x3f` before the link poll | probe | add case (RMW no-op is enough) |
| 4 | `0xa634` | clear `0xe6000000`, set `0xa4000000` | probe | add case (RMW no-op) |
| 5 | `0xa680`/`0xa6c8` | `&=~0x3c0000`; `0xa6c8 = 0xffffdffc` | probe | add `0xa680`; keep `0xa6c8` |
| 6 | `0xa080` | `&=~0x100` | probe | add case (read-back of the mask matters: it is RMW'd) |
| 7 | `0xa114` | per-channel byte, `0x08<<(ch*8)` | probe | add case returning the written byte |
| 8 | `0xa108` | FE data/command word (`0x20` write, bit15 doorbell) | probe | add case (needed by `send_atapi_cmd`/`trig_fe_boot`) |
| 9 | `0xa25c` | PIO payload port, 7×32-bit stores | identify | add case as an alias of the `0xa000` FIFO |
| 10 | `0xa0xx` taskfile | 4-byte stride, ATAPI sig in lbal/lbam/lbah | probe | keep the 6-word block; **also serve the signature trio** (`0x01`,`0x14`,`0xeb`) before the reset poll, and return `0x50` at `0xa01c` |
| 11 | `0x5c804` bit16 | message-scoped (1 while pending, 0 when drained) | probe | already implemented (`fe_msg`) — must stay scoped |

Explicitly **not needed**: SCR aliases, PRD/DMA table registers, `scr_read`/
`scr_write` hooks, `0xa600` word readback, `0xa400`/`0xa480` ch1 aliasing
beyond what exists.

---

## 7. Reproduce

```
make sacd-py SCRIPT=evidence/bx510-guest/bdpdrv/decode/ata_probe_regs.py            # table + 13 checks
make sacd-py SCRIPT=evidence/bx510-guest/bdpdrv/decode/ata_probe_regs.py -- --scan  # raw access list
```

The script pins the module sha256, re-derives every offset from the ELF, and
exits non-zero if the curated table and the scanner ever disagree.
