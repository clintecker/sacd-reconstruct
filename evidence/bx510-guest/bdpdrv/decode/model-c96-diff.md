# C96 model diff — recipe `fe-ata-cmd.md` §5 → `emulator-kit/sony-bx510.c`

Line numbers are the **post-edit** file (`emulator-kit/sony-bx510.c`, 231
insertions / 83 deletions, one file). Recipe row numbers are `fe-ata-cmd.md`
§5.1 rows 1–16 and §5.2's two hard rules.

## 1. Row → code map

| §5 row | reg | model must | where (post-edit lines) |
|---|---|---|---|
| 1 | `0x5c000` | store `w0`, **do not act** | write `case 0x5c000..c00c` **717–719** (unchanged); the action moved to the doorbell |
| 2 | `0x5c004/008/00c` | store | same case group **717–719** (unchanged) |
| 3 | `0x5c020` | `R` = stored value; `W` with bit0 = doorbell → §5.2; other bits latched | read **467–468** (`return s->fe_doorbell`); write **720–730** (`s->fe_doorbell = val;` then `if (val & 1) bx510_fe_dispatch(s);`) |
| 4 | `0x5c040` | reply w0 (`byte2` = type, `byte3` = status) | read **441–464** (`fe_msg[fe_msg_head][0]`) |
| 5 | `0x5c044` | reply w1 = DRAM offset | read **441–464** (`[...][1]`) |
| 6 | `0x5c048` | reply w2 = length | read **441–464** (`[...][2]`) |
| 7 | `0x5c04c` | reply w3 = 0 | read **441–464** (`[...][3]`, plus message retirement — §3 deviation 3) |
| 8 | `0x5c800` | `R` = last written, at minimum bit16; `W` accepted | read **434–440** (`return s->fe_mask`); write **732–734**; reset default **843–844** (`s->fe_mask = FE_IRQ_MSG`) |
| 9 | `0x5c804` | `R` = MASK while a reply is unconsumed, **0** once drained; `W` = W1C | read **421–429** (`return s->fe_irq & FE_IRQ_MSG`); write **735–739** (`s->fe_irq &= ~val`) |
| 10 | `0x5c808` | `R` = 0 | read **430–433** (new case) |
| 11 | `0x5c400/404` | store host addr / length | write **740–744**; read **469–475** (echo) |
| 12 | `0x5c408/40c` | store, RMW lossless | write **740–744**; read **469–475** |
| 13 | `0x5c500` | page → `pgn & 0xff`, `base = pgn << 22` | write **746–748** (unchanged), consumed by `bx510_fe_dram_write` **274–286** |
| 14 | `0x5c704/708` | already modeled | write **749–762** (0x601 release; now also arms the bare pending bit); `0x5c708` still in the accepted-silently case list. **Reads of `0x5c704` still fall through the unimplemented default** — see §4. |
| 15 | `0x2420c/210/214` | `W` store; `R` echo the stored `0x111` | range check read **374–381**, write **572–578** (`fe_csr[8]` bank, `0x24200..0x2421f`) |
| 16 | `0x24218` | store; `R` = stored | same range checks; field `fe_csr[8]` at **156–160** |
| HR 1 | "raise MASK after the doorbell `W`" | latch set in `bx510_fe_post` **292–311** (called *from* the doorbell handler, observed on the **next** `0x5c804` read), never inside the `0x5c020` write's store | **292–311**, **720–730** |
| HR 2 | "serve the block before raising MASK" | `bx510_fe_dram_write` **274–286** runs before `bx510_fe_post` on both payload paths (**339–340**, **350–351**); the four queue words are written before the latch inside `bx510_fe_post` | same |

### §5.2 state machine → code

`bx510_fe_dispatch()` **318–359**, keyed on content:

| §5.2 condition | action | lines |
|---|---|---|
| `type == 0x10` (driver ACK) | post message B `(0,0,0,0)` | **325–332** |
| `code == 0xa1 && arg == 0` | fill `fe_reply_block` at `FE_REPLY_OFF`, post A `(0x00100000, 0x1000, 0x200, 0)` | **334–341** |
| `code == 0xa1 && arg != 0` | fill `s->identify` (512 B) at `FE_IDENT_OFF` in `(pgn<<22)`, post P `(0x00100000, 0x2000, 0x200, 0)`, then C `(0,0,0,0)` | **344–353** |
| `code == 0xf7` / `0x08` / anything else | post `(0,0,0,0)` — never silent | **355–358** |

Queue: `fe_msg[FE_MSG_SLOTS=4][4]` + `fe_msg_head` + `fe_msg_count`
(**149–152**), staging/overflow in `bx510_fe_post`, reset **838–851**.
`fe_irq` (0x5c804 latch), `fe_mask` (0x5c800), `fe_dma[4]` (0x5c400 block),
`fe_csr[8]` (0x242xx bank) are all initialised in `bx510_reset`.

## 2. The mask default, and why

`FE_IRQ_MSG` = **`0x00010000`** (bit16 only), set in `bx510_reset`
(**843–844**).

* C93–C95 reached the driver **without** the register being modeled because the
  `chk_int_ldr` path is *polled*: it reads `0x5c804` directly
  (`.text+0x28a4`) and never consults `0x5c800`. The mask only gates the FE IRQ
  top half's latch, `latched = read(0x5c804) & read(0x5c800)` (`.text+0x34b0..34b8`).
* So a `0` default reproduces the C95 signature exactly — the top half drains,
  latches nothing, and the bottom half returns at `.text+0x4630` without ever
  reading `0x5c040-4c` (§0 defect #2).
* bit16 only, not `0xfffffff0`: it is the single bit the model ever sets, and
  `port_start` overwrites the register with `0xfffffff0` (which also keeps
  bit16) at `.text+0x32d8` anyway. Any other default would just pre-enable
  unmasked sources the FE model cannot raise.

## 3. Deviations from the recipe text (each deliberate)

1. **Doorbell dispatch on every `W` with bit0 set, not on a 0→1 edge.** The
   driver always read-modify-writes `|= 1` and never clears bit0
   (`.text+0x57e0`, `0x3b60`, `0x3cb4`), so an edge trigger would swallow every
   command after the first. This is also what §5.1 row 3 literally says.
2. **ACK keyed on the type byte alone** (`type == 0x10`) rather than on
   `w0 == 0x00100000 && arg == 0`. Equivalent for the driver's only type-0x10
   post (the ACK, whose `w1..w3` are 0 by construction, §3) and it keeps the
   pre-C96 behaviour byte-for-byte for any other type-0x10 producer.
3. **A staged message is retired by the read of the LAST status word
   (`0x5c04c`), not by the `0x5c804` W1C.** Both are needed and they cannot be
   the same event: the latch must be clearable (the top half's drain loop exits
   only on a zero read), yet both consumers read `0x5c040-4c` *after* clearing
   it (`chk_int_ldr` `.text+0x28b8..28d8`, bottom half `.text+0x4640..4660`), so
   the block has to keep serving the message that was just un-latched. Reading
   `w0..w3` in order is what both consumers do, so `w3` is the end of a message.
   Consequence to watch: a consumer that reads only `w0`/`w1` would leave the
   queue head in place (`port_start`'s signature-mismatch `printk` at
   `.text+0x3394` is such a single-word reader, but it is on the dead probe
   path). With `count == 0` the block keeps serving the last retired message —
   the status block is a register set, and the old `fe_status` was sticky too.
4. **Pending re-armed when a queued message becomes the window content**
   (read of `w3`, **452–461**) — this is how IDENTIFY message C reaches the
   driver, which posts no ACK on the IRQ path (§2.3; the ACK exists only inside
   `chk_int_ldr`). It cannot storm: the re-arm only happens when
   `fe_msg_count > 0`, and each bottom-half pass retires one message.
5. **The bare boot pending bit is armed once**, on the first `0x5c704 |= 0x601`
   (**749–762**), with no status-block payload behind it. `port_start`'s
   state==1 fast path polls `0x5c804` for "nonzero + bit16" *before* any
   command is posted (`.text+0x3244..0x3280`). Pre-C96 the read-and-clear
   counter drained once and never re-armed, so arming once preserves that
   observable and keeps the latch message-scoped.
6. **IDENTIFY payload window offset = `FE_IDENT_OFF` (0x2000).** The recipe
   leaves `w1` to the model; it must be inside the window and must not collide
   with the loader-table block at `0x1000`, so the 512-byte payload gets its own
   slot. Length `0x200` == `sizeof(s->identify)`.
7. **`0x242xx` bank limited to `0x24200..0x2421f`** as instructed. Echoing the
   stored `0x111` keeps bit 18 (the IR "data available" bit `IRRX_PollMtkIr`
   tests, model-spec.md §3.1) clear, i.e. no phantom remote packets; the
   rest of the `0x24000` block still falls through the unimplemented default.
8. **`0x5c808` got a read case only** (returns 0). No decoded writer exists, so
   no write case was added.

Untouched on purpose: every `0xa0xx` a-window case, the `fe_reply_block`
contents, the SATA PIO IDENTIFY drain, `BX510_TRACE` logging, and the
`0x5c600/604/708/780` silent-write list.

## 4. Residual risks

* Send order for IDENTIFY (payload P then completion C) is the recipe's
  INFERRED choice (§9). If C96 shows the 512 bytes arriving but the command
  still timing out, swap the two `bx510_fe_post` calls at **351–352** — the
  comment in the code says so.
* `0x2420c` completion value: the recipe's ladder starts at "echo the stored
  `0x111`". If the C95 12945-read loop persists, the ladder in §5.1 row 15 is
  the next knob. Note model-spec.md §3.1 attributes that read to the IR poll
  thread's cadence (one `ldr` per call), not to a spin loop, so it may not be a
  completion poll at all.
* Reads of `0x5c704` (row 14's `& 0x601 == 0x601` gate) still return 0 via the
  unimplemented default. Pre-existing, not in this batch's scope; it only
  matters if a run reaches `init_int_ldr`'s read-back.
* Retirement on the `w3` read assumes both consumers read all four words in
  order (documented in code). A partial reader would park the queue head.

## 5. Verification performed

* `gcc -fsyntax-only -Wall -Wextra` over the real file against hand-written
  stub QEMU headers (scratch tree in `/tmp`, nothing committed) — clean; catches
  duplicate case labels and undeclared fields.
* A 37-check scratch simulation (`/tmp/bx510stub/fe_sim.c`) that `#include`s
  the real `sony-bx510.c` and replays the driver's own access shapes:
  reset/mask default, FE-release pending, `port_start` fast path, chk message
  A→B, IDENTIFY P→C (payload bytes landing at `win+0x2000`, 512 B), `0xf7`/
  `0x08`/unknown completions, top-half drain loop termination, `0x5c800`
  read-back incl. `0xfffffff0`, doorbell/descriptor RMW losslessness,
  `0x5c808`, the `0x242xx` echo, and an a-window smoke check. **All 37 pass.**
* No `make` target was run (the task forbids it); the QEMU build + C96 fire stay
  on the VM.

## 6. What the C96 trace should show (recipe §6, unchanged)

Per post: `W 05c000..00c` (nonzero `w1`/`w2` for cmd#3) → `R 05c020` →
`W 05c020 = <|1>` → `R 05c804` **= 0x10000** with `R 05c800` **also** bit16 →
`R 05c040/044/048/04c` (the decisive quadruple that never appears in C95) →
`W 05c804 = 0x10000` → `R 05c804 = 0` → for IDENTIFY a second
`R 05c804 = 0x10000` / `R 05c040-4c` pair for the type-0 completion.
