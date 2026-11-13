# C95 trace analysis — post↔UART timeline, the `0x5c804` drain, the `0x5108`/`0x5110` pair, and the pre-handshake census

**Trace analysis, not static decode.** Answers the four questions left open by
`decode/fe-ata-cmd.md` (which builder posted cmd#3, the post-cmd#3 poll shape, the
FIFO-or-register question) and by `run-c94-c95.md` (the `0x5108`/`0x5110` pair and its
"low byte `0xa1`" pattern).

**Inputs**

| input | what it is |
|---|---|
| `decode/bdpdrv-runC95.posthandshake.mmio.gz` | committed tail, **VM lines 541511..5766311** (`gz line N == VM line 541510+N`, verified: 5 224 801 lines both ways) |
| `/tmp/bdpdrv-runC95.mmio.log` (VM) | full trace, 5 766 311 lines / 165 MB — the only source for posts #1..#3, the pre-handshake census and whole-run counts |
| `bdpdrv-runC95.uart.log` | the console, 1878 lines |
| `bdpdrv-runC95.meta.json` | run identity (bdpdrv sha256 `6604f6cd…`, ts 2026-11-13T00:01:11Z) |

**Method — and why the correlation is exact.** The trace has **no timestamps**
(`grep -c` for any timestamp form: 0; `sony-bx510.c` prints `%06x` only). It does not
need them: the guest console **is an MMIO device in the same stream** — every character
is a `W 00c000 sz1 = <byte>` preceded by `R 00c004` (UART LSR). Reconstructing the
character stream from those writes reproduces the console **inline, in exact order with
every other access**. Cross-check on that reconstruction: it yields **1878 lines — the
same count as the committed `bdpdrv-runC95.uart.log`** (and the same text). So for every
device access in this document I can name the console line the guest had most recently
finished printing and the next one it printed.

Line numbers below are **VM line numbers in the full log**; subtract 541 510 for the
committed `.gz`. Everything from post #3's drain onwards is inside the committed
artifact; posts #1..#3's own lines and §4's census need the VM log.

**Counts used throughout (whole run, `grep -c`):** `W 05c000` 13 · `05c020` 26 (13 R +
13 W) · `05c804` 24 lines = 16 accesses (8 unimplemented-write lines) · `05c800` 8 lines =
4 accesses · `05c040` 3 · `05c044/048/04c` 2 each · `05c500` 1 · `05c600/05c604` 3 each ·
`05c704/708` 16 · `05c780` 3 · **`05c4xx` 0** · `05108` 4074 · `05110` 4075 ·
`02420c` 25892 · `W 00c000` 92 408.

---

## 0. The four answers in one screen

1. **Q1 — each code maps 1:1 onto a driver printf that names the libata operation.**
   Post #1 (`0xa1`, `w2=0`) = the `chk_int_ldr` entry, right after
   `[IDE]download AACS code … end`. Post #2 (`0x00100000`) = the table-data ACK, before
   `[IDE]Internal loader boot code mode`. Post #3 (`0xa1`, `w2=0xa000`) = the libata
   **IDENTIFY PACKET** command, immediately after `[IDE]<sata_mt85xx_softreset>ch:0 end,
   class=3` and before `ata1.00: qc timeout (cmd 0xa1)`. **`0xf7` = `prereset`** —
   posted ~250 trace lines after the `prereset` entry printf, i.e. it *is* the prereset of
   the round's first hardreset attempt, and it is posted **once per round** (not per SRST
   attempt). **`0x08` = `softreset`** — posted after each `softreset>ch:0 start` printf,
   8× = 4 SRST attempts in round 1 + 4 in round 2. Full table in §1.
2. **Q2 — after cmd#3's doorbell the driver polls `0x5c804` exactly three times, in one
   IRQ top-half entry, and never again for the rest of the run.** `R→W=0x10000`,
   `R→W=0x10000`, `R→W=0` (VM 541504..541511). The reads were nonzero, nonzero, **zero**;
   the zero read terminated the drain, and the driver still wrote the zero back — so the
   loop **writes before it tests** (a small correction to `fe-ata-cmd.md` §2.2's
   `cmp;beq;str` order). The single `R 05c800` at 541502 returned **0** (unmodelled) → the
   latch was empty → the bottom half returned without reading `0x5c040-4c`. The top half
   **never ran again**: there are zero `0x5c8xx` accesses anywhere in the remaining
   2.24 M lines. §2.
3. **Q3 — `0x5108`/`0x5110` is the AUDIO DSP index/data pair, not SATA and not periodic.**
   `0x5110` = index, `0x5108` = data. One bulk download of **2037 words** (index strictly
   `0x0..0x7f4`, one word per index) between two `[AUD]` printfs, then a **2037-index
   verification readback** whose every read returns 0 (unmodelled) and tripwires
   **20 × `Assert FIRED: 0 (src/driver/aud/hal/aud_hal_8560.c:389)`**. The
   "low byte `0xa1` throughout" claim in `run-c94-c95.md` is **false**: low bytes are
   uniform (4 of 2037 are `0xa1`); `0x8ca8f1a1` is simply one sampled word. No arithmetic
   relation between consecutive data words (high-entropy block); the only arithmetic is
   the **index ramp `+1`**. §3.
4. **Q4 — nothing in `0x5c0xx` is touched before the first mailbox post.** The first
   `0x5c0xx` access in the entire run *is* the first post (`W 05c000 = 0xa1000000`, VM
   536198); the doorbell RMW `R 05c020` likewise first appears with it — so on a cold boot
   the driver never reads the doorbell before its first post. What *does* happen
   pre-post is the FE release handshake: `0x5c800←0`, `0x5c708`, `0x5c704←0xa01`,
   `0x5c500←0x7f`, `0x5c600/0x5c604`, `0x5c804` (bit16 arm + W1C), `0x5c704←0x601`,
   `0x5c780←0x103`, `0x5c704←0`, then a `0x5c804` poll and a `05c040` read that is the
   **boot-status** read (`[IDE]Receive frontend boot up status:0x0`), not a reply. §4.

**Bonus closure of a documented INFERRED:** there are **zero `0x5c400/404/408/40c`
accesses in the whole 5.77 M-line run**. `fe-ata-cmd.md` §3.3's settling experiment ("if a
`05c40c`/`05c400`/`05c404` triple appears immediately before the next `0xa1` post it is
`data_xfer`'s READ-CD branch; if not, `send_ata_cmd`") therefore resolves to **not
`data_xfer`** — cmd#3 carried a taskfile image and no descriptor arm. §5.

---

## 1. Q1 — the C95 UART timeline vs the 13 mailbox posts

Reconstructed with the interleaved console (§Method). "PREV/NEXT" are the console lines
the guest printed immediately before and after the post; the console lines themselves are
totals of ~60–260 trace lines each (one `W 00c000` per character), which is why the
"next" line can be a long way after the post.

| # | post line | `w0` | `w1` | `w2` | doorbell | console immediately before | console immediately after |
|---|---|---|---|---|---|---|---|
| 1 | 536198 | `0xa1000000` | 0 | 0 | 536203 | L535982 `[IDE]download AACS code (0x0, 0x4000) … end` | L536246 `[IDE]<sata_mt85xx_id_atapi_dev>copy from (0xdfc01000, 0x200) to (0xc6268c60, 0x200)` |
| 2 | 536583 | `0x00100000` | 0 | 0 | 536604 | L536246 (same copy line) | L536615 `[IDE]Internal loader boot code mode` |
| 3 | 541480 | `0xa1000000` | 0 | `0x0000a000` | 541485 | L541126 `[IDE]<sata_mt85xx_softreset>ch:0 end, class=3` | L621578 `ata1.00: qc timeout (cmd 0xa1)` |
| 4 | 622219 | `0xf7000000` | 0 | `0x0000a000` | 622224 | L621986 `[IDE]<sata_mt85xx_prereset>ch:0, deadline:0xfffbd778 start` | L703028 `ata1: link is slow to respond, please be patient (ready=0)` |
| 5 | 782983 | `0x08000000` | 0 | `0x0000a000` | 782988 | L782820 `[IDE]<sata_mt85xx_softreset>ch:0 start` | L866192 `ata1: link is slow to respond, please be patient (ready=0)` |
| 6 | 944259 | `0x08000000` | 0 | `0x0000a000` | 944280 | L944096 `[IDE]<sata_mt85xx_softreset>ch:0 start` | L1027484 `ata1: link is slow to respond, please be patient (ready=0)` |
| 7 | 1105535 | `0x08000000` | 0 | `0x0000a000` | 1105556 | L1105372 `[IDE]<sata_mt85xx_softreset>ch:0 start` | L1188760 `ata1: link is slow to respond, please be patient (ready=0)` |
| 8 | 1666683 | `0x08000000` | 0 | `0x0000a000` | 1666688 | L1666504 `[IDE]<sata_mt85xx_softreset>ch:0 start` | L1747444 `ata1: SRST failed (errno=-16)` |
| 9 | 1747983 | `0xf7000000` | 0 | `0x0000a000` | 1747988 | L1747760 `[IDE]<sata_mt85xx_prereset>ch:0, deadline:0xfffce9b2 start` | L1828792 `ata1: link is slow to respond, please be patient (ready=0)` |
| 10 | 1909667 | `0x08000000` | 0 | `0x0000a000` | 1909672 | L1909494 `[IDE]<sata_mt85xx_softreset>ch:0 start` | L1992876 `ata1: link is slow to respond, please be patient (ready=0)` |
| 11 | 2071057 | `0x08000000` | 0 | `0x0000a000` | 2071062 | L2070878 `[IDE]<sata_mt85xx_softreset>ch:0 start` | L2154266 `ata1: link is slow to respond, please be patient (ready=0)` |
| 12 | 2232447 | `0x08000000` | 0 | `0x0000a000` | 2232452 | L2232268 `[IDE]<sata_mt85xx_softreset>ch:0 start` | L2315656 `ata1: link is slow to respond, please be patient (ready=0)` |
| 13 | 2793661 | `0x08000000` | 0 | `0x0000a000` | 2793682 | L2793498 `[IDE]<sata_mt85xx_softreset>ch:0 start` | L2874432 `ata1: SRST failed (errno=-16)` |

`w3 = 0` for all thirteen. All 13 doorbell writes are 5 trace lines after their `w0`
write except #13 (21 lines — an IRQ entry/exit dance landed between the word writes and
the doorbell). Every post is followed by the same 8-line BIM interrupt dance
(`R 008034 / R 008030 / R 008034 / W 008034=44000 / W 008038=8000000 / W 008030=8000000
/ W 008038=8000000 / W 008030=8000000`), i.e. the model's IRQ is serviced every time.

### 1.1 The libata structure this pins (derived purely from the interleaving)

```
[IDE]download AACS code (0x0,0x4000) ... end            L535982
post#1  a1/w2=0                                         L536198  <- chk_int_ldr entry
   R 05c804 -> 0x10000, W1C, R 05c040/044/048/04c        L536220..536226
[IDE]<sata_mt85xx_id_atapi_dev>copy from (0xdfc01000,0x200) L536246
post#2  0x00100000 (type 0x10 ACK)                      L536583
   R 05c804 -> 0x10000, W1C, R 05c040/044/048/04c        L536605..536611
[IDE]Internal loader boot code mode                     L536615
[IDE]----- Loader is in manufacture mode !! -----       L536788
scsi0 : sata_mt85xx                                     L537135
ata1: SATA max UDMA/133 irq 18                          L537595
[IDE]<sata_mt85xx_prereset>  ... start / end            L538033 / L538307      (probe: no post!)
[IDE]<sata_mt85xx_softreset>ch:0 start                  L538496
[IDE]<sata_mt85xx_softreset>ch:0 end, class=3           L541126
post#3  a1/w2=0xa000  (IDENTIFY PACKET, libata)         L541480  -> 30 s -> qc timeout
--- EH, round 1 ---
[IDE]<sata_mt85xx_prereset> deadline:0xfffbd778 start   L621986
post#4  f7                                              L622219
ata1: link is slow to respond (ready=0)                 L703028
[IDE]<sata_mt85xx_prereset>ch:0 end                     L782647   (prereset returns without a second post)
ata1: device not ready (errno=-16), forcing hardreset   L782426
[IDE]<sata_mt85xx_softreset>ch:0 start                  L782820
post#5  08  -> link slow -> SRST failed                 L782983
   ... 3 more SRST attempts: post#6 L944259, post#7 L1105535, post#8 L1666683
ata1: reset failed, giving up                           L1747570
--- EH, round 2 ---
[IDE]<sata_mt85xx_prereset> deadline:0xfffce9b2 start   L1747760
post#9  f7                                              L1747983
   ... 4 more SRST attempts: post#10 L1909667, #11 L2071057, #12 L2232447, #13 L2793661
ata1: SRST failed; reset failed, giving up; EH complete L2874432..2874751
```

### 1.2 What each code means, in EH terms

| code | posts | driver printf that brackets it | libata operation |
|---|---|---|---|
| `0xa1`, `w2 = 0` | 1 | `download AACS code … end` → `id_atapi_dev copy` | `chk_int_ldr` loader-table fetch (polled path, `fe-ata-cmd.md` §3) |
| `0x00100000` | 1 | after the `0x5c040` block read of #1 | `send_table_data_ack_cmd` — the driver's ACK of message A |
| `0xa1`, `w2 = 0xa000` | 1 | `softreset … end, class=3` → `qc timeout (cmd 0xa1)` | **libata's IDENTIFY PACKET DEVICE** (`ata_dev_identify`, 30 s packet timeout when unanswered) |
| `0xf7` | 2 | inside `prereset … start` … `prereset … end` | **`sata_mt85xx_prereset`**, once per EH round, at the round's first hardreset attempt — **yes, 0xf7 is the prereset of the first attempt** |
| `0x08` | 8 | after each `softreset … start` | **`sata_mt85xx_softreset`** = the SRST attempt; 4 per round |

Two consequences that matter for the C96 model:

* **The stale `w2 = 0xa000` in posts #4..#13 is confirmed as staleness, not meaning.**
  §3.2 of `fe-ata-cmd.md` predicted it (`prereset` does not touch `priv+0x280..0x294`); the
  trace shows the *identical* `w2` on the IDENTIFY post (#3) and on all ten EH posts,
  including the eight `0x08` posts whose own builder is known to set
  `priv+0x280..0x294 = EB140101`. That is the **inverse** of what a live reload would
  produce — i.e. `send_ata_cmd`'s taskfile snapshot words were captured once (at the
  IDENTIFY) and never refreshed, and `softreset`/`prereset` do not republish them. Model
  rule: **key only on `w0`** for `0xf7`/`0x08`; treat `w1..w3` as don't-care.
* **One reply per post is enough to end EH.** Every EH post is followed by *silence* and
  then a libata timeout print; nothing in the driver retries a post on its own. So
  `fe-ata-cmd.md` §5.2's "never leave the pending bit down" remains the operative rule —
  and a single `(0,0,0,0)` reply to post #4 would collapse the whole 13-post cascade.

### 1.3 Honest note on time

The trace carries no timestamps, so "≈1.6 s apart" cannot be confirmed from it. The only
in-trace clock candidate is the `deadline` field in the `prereset` entry printf
(`0xfffbc336`, `0xfffbd778`, `0xfffce9b2`) — the two deltas are 5186 and 70202, which
cannot both be round durations for two structurally identical EH rounds under either
HZ=100 (51.9 s / 702 s) or HZ=1000 (5.2 s / 70.2 s). **It is not used for any claim here.**
The 30 s anchor for the identify wait comes from libata's packet timeout and from
`run-c94-c95.md`'s measurement, not from this trace.

---

## 2. Q2 — the exact `0x5c804` sequence after cmd#3

### 2.1 The complete census: 16 accesses in 5.77 M lines

`0x5c804` is a W1C latch and all three readers **write back exactly what they read**
(`chk_int_ldr` `.text+0x28b0`, `port_start` `.text+0x327c`, the drain loop
`.text+0x34c0`), so the trace's read values below are recovered from the following W1C
value — and independently confirmed by the console in two cases (`int_val = 0x10000`,
`clear default interrupt = 0x10000`). The trace itself logs no read data.

| VM line | op | what it is (attribution) | read value |
|---|---|---|---|
| 445791 | R | `init_int_ldr` FE-boot poll — console next prints `[IDE]int_val = 0x10000` (L448719) | `0x10000` |
| 445792 | W `0x10000` | W1C of that read | — |
| 448715 | R | second boot poll; 122 trace lines later the W1C | `0x10000` |
| 448837 | W `0x10000` | W1C; next line is `R 05c040` → console `[IDE]Receive frontend boot up status:0x0` | — |
| 536220 | R | `chk_int_ldr` poll after post #1 | `0x10000` |
| 536221 | W `0x10000` | W1C, then `R 05c040/044/048/04c` | — |
| 536605 | R | `chk_int_ldr`/ack poll after post #2 | `0x10000` |
| 536606 | W `0x10000` | W1C, then `R 05c040/044/048/04c` | — |
| 537028 | R | `port_start` fast path (28 lines after `W 05c800 = 0xfffffff0`) | **`0`** |
| 537029 | W `0` | write-back of the zero it read | — |
| **541504** | R | **IRQ top-half drain, entry 1** (after post #3) | `0x10000` |
| **541505** | W `0x10000` | W1C | — |
| **541507** | R | **drain entry 2** | `0x10000` |
| **541508** | W `0x10000` | W1C | — |
| **541510** | R | **drain entry 3 — the zero read** | **`0`** |
| **541511** | W `0` | write-back of the zero (loop writes before testing, §2.3) | — |

**Nothing else. Ever.** After 541511 there is no `0x5c804` read or write in the remaining
2 244 800 lines, and no `0x5c800`/`0x5c808` access either.

### 2.2 The post-cmd#3 window, verbatim (VM 541478..541516)

```
bx510: MMIO W 05c000 sz4 = a1000000
bx510: MMIO W 05c004 sz4 = 0
bx510: MMIO W 05c008 sz4 = a000
bx510: MMIO W 05c00c sz4 = 0
bx510: MMIO R 05c020 sz4
bx510: MMIO W 05c020 sz4 = 1                  <- doorbell (post #3)
bx510: MMIO R 008034 sz4                      \
... 8 lines: the BIM group0/group1 interrupt dance   <- the FE IRQ is taken
bx510: MMIO W 008030 sz4 = 40000              /
bx510: MMIO R 05c800 sz4
bx510: unimplemented read 0x7005c800 (4)      <- MODEL RETURNS 0: the latch is empty
bx510: MMIO R 05c804 sz4
bx510: MMIO W 05c804 sz4 = 10000
bx510: unimplemented write 0x7005c804 = 0x10000 (4)
bx510: MMIO R 05c804 sz4
bx510: MMIO W 05c804 sz4 = 10000
bx510: unimplemented write 0x7005c804 = 0x10000 (4)
bx510: MMIO R 05c804 sz4
bx510: MMIO W 05c804 sz4 = 0
bx510: unimplemented write 0x7005c804 = 0x0 (4)
bx510: MMIO R 008034 sz4                       <- straight back to the BIM/timer idle loop
bx510: MMIO W 008034 sz4 = 8044000
```

Then 80 000 trace lines of `0x8030/0x8034/0x8138/0x813c/0x8154/0x8158` + console
(`KEXP3-…` symbol probes) with **no FE-block access at all**, ending at
`ata1.00: qc timeout (cmd 0xa1)` (console L621578) and post #4 (f7).

### 2.3 Classification against the three poll shapes (`fe-ata-cmd.md` §4.1)

| observation | shape it matches | verdict |
|---|---|---|
| `R 05c800` (mask) then `R/W` pairs on `0x5c804` with **no sleep and no other MMIO between** | shape 3 — **IRQ top-half drain** (`.text+0x34b0..34c8`) | **match.** Exactly one mask read ⇒ exactly one top-half entry |
| one `R` + one `W(same value)` then the `0x5c040` block | shape 1 — `chk_int_ldr` | matches posts #1 and #2 (536220/536221, 536605/536606), where the very first read was already `0x10000` |
| `R 05c804` → `W(0)` with no block read | shape 2 — `port_start` fast path | matches 537028/537029 (read returned 0) |
| no access at all after 541511 | — | neither `chk_int_ldr` nor `port_start` ever polls again |

**Was there ever a zero read?** Yes — three times, and each time it is meaningful:
`537028` (port_start, pre-cmd#3), and **`541510`** (the drain's terminating read). The
drain's *first* read was **not** zero: the driver took two nonzero reads before it saw a
zero, which is why the C95-era model's read-and-clear counter (`if (fe_booted && fe_msg < 2)
{ fe_msg++; return 0x10000; }`) produced exactly the observed 2×`0x10000` + 0 pattern. A
model that returns `MASK` exactly once (the C96 shape) will produce
`R→W=0x10000, R→W=0` — one pair shorter, and that is *correct* behaviour, not a defect:
the driver's loop is driven by the read value, not by a count.

**Did the top half ever run again after the first drain?** **No.** Not once — not at the
`f7`/`08` doorbells (#4..#13), not at any point in the remaining 2.24 M lines. Reason: the
C95 model answered the `0xa1`-with-args doorbell through the chk message-A/B path, raising
the pending bit once; after that single drain it never raised it again, and the driver has
no other `0x5c804` reader in the EH path. **Consequence for C96:** for posts #4..#13,
seeing a single `R 05c800 / R 05c804 = 0x10000 / W 0x10000 / R 05c040..04c` burst per post
is the decisive positive signal that the model is now serving them at all — C95 has *zero*
such bursts after 541511.

### 2.4 Model-relevant detail the drain exposes: the loop writes before it tests

`fe-ata-cmd.md` §2.2 renders the drain as

```
0x34b4 ldr r3,[0x5c804] ; 0x34bc cmp r3,#0 ; beq exit ; 0x34c0 str r3,[0x5c804]
```

i.e. *exit before the W1C*. The trace's third pair is `R 05c804` (zero) **followed by**
`W 05c804 = 0`, so the executed order is **read → W1C(write back what was read) → test**.
Two readings, and the trace does not distinguish them:

* the store sits at the loop bottom (`R; W; bne loop`), or
* after a zero read the taken branch lands on a store that writes the zero back.

**Neither changes the model:** a W1C of `0` is a no-op, and the model only has to return
`MASK` while a message is staged and `0` once consumed. Worth recording because anyone
modelling a *sticky* `0x5c804` (returning `MASK` forever) should expect the driver to keep
writing `0x10000` and drain-looping — which is the documented 4.4 GB storm shape.

### 2.5 Why no reply was ever observed in C95 (the mechanism, confirmed)

`0x5c800` has exactly **4** accesses in the run: `W 0` at 296105 (driver init),
`W 0xfffffff0` at 537000 (`port_start`), `R` at 537026 and `R` at 541502. The last one —
the top half's mask read — went to the **unimplemented** path and returned 0, so
`latched = 0x10000 & 0 = 0` (`.text+0x34b8`), `priv+0x22c` never got bit16, and the bottom
half returned at `.text+0x4630` without touching `0x5c040-4c`. The trace's own proof: after
541511 the driver reads `0x5c040` **zero more times in the entire run** (3 reads total:
448839 boot status, 536223 post #1, 536608 post #2). This is `fe-ata-cmd.md` §0 defect #2,
now shown end-to-end in an ordered trace rather than inferred from the C95 signature.

---

## 3. Q3 — the `0x5108`/`0x5110` pair: AUDIO DSP index/data, one bulk download

### 3.1 What it is (settled by the interleaved console)

`0x5110` = **index/address**, `0x5108` = **data**, `0x5100` = channel command/mode (`0x20`
once), `0x510c` = mode (`0x2` once). All of it belongs to the **audio HAL**: the console
lines that bracket the whole episode are

```
L3075499  [OSAL_STUB] init_static_memory(_ucAdspWorkingBuffer, flag=1, size=8929280, align=1048576) -> bf07f54
L3076338  [OSAL_STUB] Assert FIRED: (u4DspStartAddr & 0xFFFFF)==0 (src/driver/aud/hal/aud_hal_8560.c:258)
L3086751  [the 2037-word download starts]
L3091483  [AUD][AUD_IF] Audio Init Thread is created.
L3091723  [OSAL_STUB] Assert FIRED: 0 (src/driver/aud/hal/aud_hal_8560.c:389)   <- x20
L3097708  [OSAL_STUB] alloc x_mem_alloc -> c62f0000 size=6768
L3099420  [OSAL_STUB] x_thread_delay #256 arg=1 caller=_AudDrvThread
L3101805  [OSAL_STUB] x_mem_memset dst=c62f0000 n=0x1a70 caller=i4PBBUFComp_Init
```

`ADSP` = audio DSP (`_ucAdspWorkingBuffer`, `_AudDrvThread`, `i4PBBUFComp_Init`). **There is
no SATA/FE connection in this pair**, and no `0xa1` semantics to read into it.

### 3.2 The exact structure (all 4074/4075 accesses fall in VM 3 076 751 .. 3 102 745)

| phase | VM lines | accesses | shape |
|---|---|---|---|
| pre | 3075488, 3076311 | `W 0514c=0`, `W 051cc=0xe800` (×2) | clock/DSP start-address register pair |
| **download** | 3086751..3091458 | `W 05100=0x20`, then **2037 × (`W 05110=idx`, `W 05108=data`)**, then `W 0510c=0x2` | index ramp `0x0..0x7f4`, strictly `+1`, one word per index; **no reads, no polling, no per-entry handshake** |
| **verify** | 3091718..3102743 | **2037 × (`W 05110=idx`, `R 05108`)**, then `W 05110 = 0` at 3102744 (index reset) | index ramp `0x0..0x7f4` again; **every read returns 0** (unmodelled) → verify fails → `Assert FIRED … aud_hal_8560.c:389` |
| post | 3102745, 3103494 | `W 05100 = 0` (channel off), then `W 0514c = 0` / `W 051cc = 0xe800` | channel teardown/restart |

Verbatim head of the download (VM 3086751):

```
bx510: MMIO W 005100 sz4 = 20
bx510: MMIO W 005110 sz4 = 0
bx510: MMIO W 005108 sz4 = 5af7b3d3
bx510: MMIO W 005110 sz4 = 1
bx510: MMIO W 005108 sz4 = 4b99b693
     ... (an IRQ dance and one console line land mid-stream; the ramp never restarts)
bx510: MMIO W 005110 sz4 = 2
bx510: MMIO W 005108 sz4 = 7b02bbd9
```

Verbatim head of the verify (VM 3091718) — the fatal shape:

```
bx510: MMIO W 005110 sz4 = 0
bx510: MMIO R 005108 sz4            <- returns 0
   (console, 250 trace lines: "[OSAL_STUB] Assert FIRED: 0 (src/driver/aud/hal/aud_hal_8560.c:389)")
bx510: MMIO W 005110 sz4 = 1
bx510: MMIO R 005108 sz4            <- returns 0
   (assert again) ...
```

**Periodic or burst-per-event?** Neither — it is **one contiguous burst per event**, twice
(download, then verify), each burst 2037 entries long, with zero timer coupling: the
interleaved IRQ/console traffic lands *inside* the bursts but never paces them, and there
is no repeat afterwards. The 20 asserts are the guest retrying the verify (49, 690, 975,
303, then 20 single-read attempts = 2037 reads exactly), not a periodic poll.

### 3.3 The "low byte `0xa1`" pattern — corrected

`run-c94-c95.md` recorded "`0x5108` written 2037× (values all carry low byte `0xa1`, e.g.
`0x8ca8f1a1`)" and "`0x5110` written 4075× (values `0xa1, 0x1a1..0x7a1`)". Measured:

* `0x5108`: **2037 data writes**, low-byte histogram is **uniform** (top value 29/2037);
  exactly **4** of 2037 words have low byte `0xa1` — i.e. 1/256, chance. `0x8ca8f1a1` *is*
  present (one word out of 2037) — the note generalised from a single sample; 2036 of the
  2037 words are distinct.
* `0x5110`: **4075 index writes** = 2037 (download, `0..2036`) + 2037 (verify, `0..2036`) +
  1 (final reset to 0). Values with low byte `0xa1` are the 8 indices
  `0xa1,0x1a1,…,0x7a1`, each written twice = **16** — again a 1/256 artefact of a
  monotonic ramp, not a protocol constant.

So: **there is no `0xa1` pattern here**, and this pair must not be tied to the ATA command
byte. The only arithmetic relation between consecutive writes is `index += 1`; consecutive
data words have no relation (xor of consecutive words is uniform over all 256 low-byte
values), and the block is high-entropy (no ASCII runs in either endianness) — consistent
with compressed/encrypted DSP microcode, not a taskfile.

**Model consequence (a separate row, not the FE row):** `0x5110`/`0x5108` want a plain
**index/data register-RAM echo** — store 2037 words by index, return them on readback.
That alone clears the 20 `aud_hal_8560.c:389` asserts. `0x5100`/`0x510c`/`0x514c`/`0x51cc`
are mode/control writes: accept and store. The earlier audio assert about
`u4DspStartAddr` (L3076338) suggests `0x514c`/`0x51cc` also need to *look* non-zero on
read — INFERRED, its own experiment.

---

## 4. Q4 (bonus) — the pre-handshake era: no `0x5c0xx` before the first post

### 4.1 The literal answer

* The **first 100 trace lines** are pure console: `R 0080e8`, then `R 00c004 / W 00c000`
character bursts spelling `Uncompressing Linux…`. No device register is touched.
* In the 536 197 lines before the first mailbox post there are **22 accesses in the whole
  `0x5cxxx` block, and not one of them is in `0x5c000..0x5c0ff`.** The first `0x5c0xx`
  access in the entire run is the first post itself (`W 05c000 = 0xa1000000`, VM 536198),
  and the first `R 05c020` (doorbell RMW) is at 536202 — 4 lines later.
  **So no: on a cold boot the driver never reads the doorbell before its first post.**

### 4.2 The 22 pre-post accesses (the FE bring-up handshake), verbatim order

| VM line | access | console correlation |
|---|---|---|
| 296105 | `W 05c800 = 0` | `[IDE]set ARM1 SATA driver init flag...` — the driver parks the mask at **0** at init |
| 296160 | `W 05c708 = 0` | `SVOIF driver init` / `frontend FW buffer = 0xdd900000, DRAM Addr = 0xdfc00000` |
| 440054 / 440056 | `R 05c708` / `W 05c708 = 0x10` | `set FE RSTI = 1` … `set XTAL` |
| 440144 / 440146 | `R 05c704` / `W 05c704 = 0xa01` | `set HBUS on` / `set IPLL register` (note: `0xa01`, not `0x601`) |
| 445281 / 445283 | `R 05c708` / `W 05c708 = 0` | after `reset IPLL` |
| 445784 | `W 05c500 = 0x7f` | `[IDE]set DRAM Wrapper, phy_addr = 0x1fc00000, offset = 127` — **exact corroboration** of `phys = (pgn&0xff)<<22` with pgn=0x7f |
| 445785 / 445787 | `R 05c600` / `W 05c600 = 0x808080` | `_pbPwrOnParm = TAG0ACNO0000` |
| 445788 / 445790 | `R 05c604` / `W 05c604 = 0x80` | (same) |
| 445791 / 445792 | `R 05c804` / `W 05c804 = 0x10000` | `[IDE]clear default interrupt = 0x10000` — the read got `0x10000` (the C95 model's `fe_booted` arm) and W1C'd it |
| 445970 / 445972 | `R 05c704` / `W 05c704 = 0x601` | `release frontend reset done` (wait for `& 0x601`) |
| 447611 / 447613 | `R 05c780` / `W 05c780 = 0x103` | `<init_int_ldr>init end` |
| 447614 / 447616 | `R 05c704` / `W 05c704 = 0` | (same) |
| 448715 … 448837 | `R 05c804` … `W 05c804 = 0x10000` | `[IDE]int_val = 0x10000` — 122 trace lines between read and W1C |
| 448839 | `R 05c040` | `[IDE]Receive frontend boot up status:0x0` — a **status** read, not a reply; no post precedes it |

Two things worth carrying forward:

* **`0x5c704` is read, not just written** (three times: 440144, 445970, 447614) and the
  C95 model had no read case for it — these land on the unimplemented path. Harmless in
  C95 (`val & 0x601` is only tested on the write side), but a read-back model is cheap and
  removes a class of "why does init not converge" ambiguity.
* The mask register is written **twice in the whole run**: `0` at driver init (296105) and
  `0xfffffff0` in `port_start` (537000). Its reset default in the model is therefore not
  observable from this trace — any default that keeps bit16 is consistent with the
  evidence, and a `0` default reproduces the C95 failure exactly (`fe-ata-cmd.md` §0
  defect #2).

---

## 5. Bonus — the `fe-ata-cmd.md` §3.3 settling experiment, resolved

§3.3 left INFERRED *which builder posted cmd#3*, with the experiment: look for a
`05c40c/05c400/05c404` descriptor triple immediately before the next `0xa1` post.

**Whole-run counts: `0x5c400`, `0x5c404`, `0x5c408`, `0x5c40c` — zero accesses of any
kind (read or write), in all 5 766 311 lines.** (`grep -c '05c5'` = 1 = the single
`W 05c500 = 0x7f`; the FE DMA descriptor block is never touched.)

Therefore cmd#3 was **not** `data_xfer`'s READ-CD branch (`.text+0x5800..0x5874`); it was a
`send_ata_cmd`-shaped post carrying a taskfile image (`w1 = 0`, `w2 = {lba2=0x00,
device=0xa0}`), and the a-window/descriptor machinery is absent from this firmware state
exactly as `fe-ata-cmd.md` §1.3 argued. This also means the C97 read path's descriptor arm
(`c97-read-path.md` §1) is **untested by C95** — C95 never reached a READ, so it neither
confirms nor refutes that decode.

---

## 6. What this changes for the C96 model (no re-decode, just the deltas these traces force)

| # | observation | model action |
|---|---|---|
| 1 | `0x5c800` read returned **0** at the only moment that mattered (541502) | keep the C96 mask default with bit16 set; **a `0x5c800` read must return the last written value, and the default must not be 0** — this one register is the entire difference between C95 and a served reply |
| 2 | drain is 3 reads in C95 because the old model read-and-cleared with a 2-hit counter | return `MASK` while a message is staged, `0` after — the driver's loop follows the value, and a shorter (1-pair) drain is correct |
| 3 | drain writes the terminating zero back | W1C of 0 must be a no-op (it already is); do not treat a `W 05c804 = 0` as "no message" |
| 4 | `0xf7` and `0x08` arrive **with `w2 = 0xa000`** and identical args to cmd#3 | key the reply **only on `w0` byte3** for these two; args are stale and must be ignored |
| 5 | posts #4..#13 produce no `0x5c804` access at all in C95 | in C96 each should produce one `R 05c800 / R 05c804 = 0x10000 / W / R 05c040..04c` burst: that burst per EH post is the pass signal for the reset path |
| 6 | `0x5c704` is **read** 3× pre-post, `0x5c500` written once (`0x7f`, corroborated by the console), `0x5c780`/`0x5c600`/`0x5c604` written once each | optional read-backs (all values are already known from the writes); no behaviour depends on them in C95 |
| 7 | `0x5110`/`0x5108` are the AUDSP index/data pair, 2037 words, verify-readback | model as an index/data RAM echo. **Do not** encode any `0xa1` pattern — that claim was a sampling artefact (§3.3). Not on the ATA path |
| 8 | `0x242xx`: 12 945 reads of `0x2420c` after `{0x111, 0xe1, 0x200}` + `0x24218←1` | unchanged; that lane belongs to `decode/hal-csr-242xx.md`, not to this analysis |

---

## 7. Remaining open items (with their experiments)

| item | label | experiment |
|---|---|---|
| drain loop order (`R;W;test` vs `R;test;W`) | INFERRED (trace shows `W 0` after a zero read) | disassemble `.text+0x34b0..0x34d8` with an ARM-capable objdump (the VM has x86 binutils only; `sata.dis` from the decode session is gone from `/tmp` — regenerate with `objdump`-equivalent on the Mac or re-stage an ARM toolchain). **No model behaviour depends on it.** |
| `0x514c`/`0x51cc` need a non-zero read-back for `u4DspStartAddr` | INFERRED | C96 trace: does `Assert FIRED: (u4DspStartAddr & 0xFFFFF)==0 (aud_hal_8560.c:258)` disappear when those reads return the written value |
| whether `0x5108` readback echo alone clears all 20 `aud_hal_8560.c:389` asserts | INFERRED | same C96 trace, assert count |
| absolute timing of the EH cadence | not in this trace | needs timestamps: re-fire with a trace format that carries them (or correlate with a VM-side `date`-stamped console) |

---

## 8. Reproduction

Everything above comes from three artifacts plus two VM-side extractions. The extractor is
one linear pass over the log (165 MB, ~60 s on the VM):

```
# VM: build the event index (UART chars, 0x5cxxx, 0x5108/0x5110, 0x242xx) with line numbers
python3 /tmp/c95_extract.py /tmp/c95_extract.txt      # script reproduced below
scp → pull /tmp/c95_extract.txt locally

# whole-run counts (VM)
grep -c 'W 05c000' /tmp/bdpdrv-runC95.mmio.log        # 13
grep -c '05c020'   /tmp/bdpdrv-runC95.mmio.log        # 26
grep -c '05c804'   /tmp/bdpdrv-runC95.mmio.log        # 24 (16 accesses + 8 unimplemented-write lines)
grep -c '05c50'    /tmp/bdpdrv-runC95.mmio.log        # 1   = the single W 05c500 (and '05c40' = 0
                                                     #      -> zero 0x5c4xx accesses anywhere)
```

Extractor (as run):

```python
LOG = "/tmp/bdpdrv-runC95.mmio.log"
access_re = re.compile(r"^bx510: MMIO ([RW]) ([0-9a-f]{6}) sz(\d)(?: = ([0-9a-f]+))?$")
for n, line in enumerate(open(LOG, errors="replace"), 1):
    m = access_re.match(line.rstrip("\n"))
    if not m: continue
    d, reg, sz, val = m.groups(); r = int(reg, 16)
    if   r == 0x00C000 and d == "W": uart.append((n, int(val, 16)))      # console chars
    elif 0x05C000 <= r <= 0x05C8FF:  fe.append((n, d, r, val, sz))
    elif 0x05100 <= r <= 0x051FF:    adsp.append((n, d, r, val, sz))
    elif 0x024200 <= r <= 0x0242FF:  hal.append((n, d, r, val, sz))
```

Console reconstruction = accumulate `W 00c000` bytes, split on `0x0a`; it reproduces the
1878 lines of `bdpdrv-runC95.uart.log` exactly, which is the validity check for every
correlation in §1, §3 and §4.

**Evidence files:** `bdpdrv-runC95.uart.log`, `bdpdrv-runC95.meta.json`,
`decode/bdpdrv-runC95.posthandshake.mmio.gz` (VM lines 541511+, i.e. the C95-model drain
tail through every EH post and the whole ADSP episode). The pre-post census (§4) and the
posts #1..#3 lines exist only in the VM-side full log — re-fire with `BX510_TRACE=1` to
regenerate if the VM reboots (`run-c94-c95.md` has the command).
