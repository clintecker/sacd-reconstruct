# C99 payload-episode trace analysis — the memcpy fired, `data_xfer` was handed 512 **zero** bytes

**Trace analysis, not static decode.** Answers the five questions in the C99 brief from the
wire (MMIO) record, cross-read against `hsm-buffer-seq.md` §1/§3.3-A, `fe-ata-cmd.md` §2.3/§5,
`id-validity-check.md` §0/§1, and the model source (read-only, `~/bx510-emu/emulator/sony-bx510.c`).

**Inputs**

| input | what it is |
|---|---|
| `decode/bdpdrv-runC99.postident.mmio.gz` | committed tail, 3 009 132 lines |
| `/tmp/bdpdrv-runC99.mmio.log` (VM) | full trace, 3 562 531 lines — used for the whole-run `05cxx` census and the `05c500`/`05c010` anchors |
| `bdpdrv-runC99.uart.log` (95 224 B) | console, 2 × `failed to IDENTIFY` |
| `bdpdrv-runC99.meta.json` | run identity (bdpdrv `6604f6cd…`, qemu `…/work/build/qemu-system-arm`, ts 2026-11-13T04:51:23Z) |
| model source `sony-bx510.c` | mtime 04:50:46.5, binary 04:50:47.7, run 04:51:23 → **the source read here is the binary that ran** |

## Method and the line-number convention (one correction)

Console is reconstructed inline from the `W 00c000` byte stream exactly as
`trace-analysis-c95.md` did (one `W 00c000` per character, `0x0a` splits lines); in this window
it reproduces the committed `.uart.log` character for character (the two `invalid type` lines,
their order and their neighbours all match).

**Correction to the brief's mapping.** The brief says `gz line N == VM line 553400+N`. Measured
against the full log, it is **`gz line N == VM line 553399+N`**. Three anchors:

| gz line | content | VM line |
|---|---|---|
| 1 | `R 00c004` | 553400 (553398/553400/553401 are all `R 00c004`) |
| 3 | `W 00c000 = 20` | 553402 |
| 1236 | `W 05c010 = 4f474f4c` ("LOGO") | 554622 (full-log `grep -n`: 554623 is the `unimplemented write 0x7005c010` echo line) |

**Every line number below is a VM line number in the full log** (already corrected); subtract
553 399 for the `.gz`.

---

## 0. Bottom line — the five answers

1. **Q1** — the episode is **two mailbox posts, two top-half drains, two status-block reads**, in
   that order, per IDENTIFY qc (§1). The second block read is the surprise: `hsm-buffer-seq.md`
   §1.6/§3.2 predicted at most one.
2. **Q2** — after the ACK post the model answers with **message B = type 0, byte3 0, args 0**
   (`sony-bx510.c:332-336`, the `type == 0x10` row of §5.2), and **the driver consumed it**: a
   second `R 05c040/044/048/04c` quadruple at VM 558406-558409 (episode 1) and 563342-563345
   (episode 2). The type-0 branch ran, `hw_chg_st(priv,2)` ran, `check_status` returned `0x58`
   (DRDY|DSC|**DRQ**), libata's HSM took the data phase. The state machine was **not** poisoned.
3. **Q3** — **zero** `05c400/404/408/40c` accesses in the entire run (and only one extra
   `05c0xx` outside the mailbox/status block: `W 05c010` at 554622). Between quadruple #1 and the
   next post there is **no** FE mailbox traffic at all other than the driver's own ACK post.
   What `data_xfer` was handed: **512 zero bytes**. The source of the zeros is the model's
   `identify[]`, which was never built in this run (§3.3); the trace cannot exclude the
   degenerate `r10 == 0` copy *into an already-zero* bounce buffer, which is observationally
   identical (§3.3 residual).
4. **Q4** — **B was consumed, twice** (once per EH round), and it did exactly what §1.3 predicts.
   The `invalid type ×2` is *not* two rounds poisoned by B; it is libata's ordinary EH retry, and
   both rounds are byte-for-byte identical in MMIO shape (§4, §5).
5. **Q5** — verdict: **the payload plumbing worked; the payload was empty.** The C100 change is
   not a protocol change — attach the disc (or build `identify[]` unconditionally) and gate the
   run on `bx510: SATA ATAPI drive attached` before reading any IDENTIFY outcome. Recipe rows in
   §6; the model file is untouched.

**The uncomfortable corollary.** `bx510: SATA ATAPI drive attached` last appears in **C93**; it is
absent from **C95, C97, C98, C99**. `bx510_sata_build_identify()` is called only inside
`if (s->sata_disc_path && s->sata_disc_path[0])` (`sony-bx510.c:933-945`), and it is the *only*
writer of `s->identify[]`; QOM zero-fills the struct and `bx510_reset()`
(`sony-bx510.c`, the reset body immediately after `bx510_sata_build_identify`) does not touch it. So from C95 on the "IDENTIFY table" the model posted
was **512 zeros**. C99 delivered those zeros through a *fully correct* mailbox exchange and
libata said `device reports invalid type, err_mask=0x0` — **the same line C97 and C98 produced
while the payload never arrived at all.** That UART line is content-blind and could never have
separated the three runs; only the `05cxx` MMIO shape can.

---

## 1. Q1 — the full episode timeline (console reconstructed inline)

`↳UART` = the console line whose last character was written at that VM line.

### Episode 1 (round-2 `read_id`; the one the brief starts at)

| VM line | access | what it is |
|---|---|---|
| 558088 | ↳UART `[IDE]<sata_mt85xx_softreset>ch:0 end, class=3` | SRST done, class 3 = ATAPI |
| **558286** | `W 05c000 = a1000000` | **the IDENTIFY PACKET post** (`exec_command` → `send_ata_cmd`, `w2 = 0x0000a000`) |
| 558287-558289 | `W 05c004/008/00c = 0, a000, 0` | rest of the command block |
| 558290-558291 | `R 05c020`, `W 05c020 = 1` | doorbell → **model stages message A** (type 0x10) |
| 558308 | `R 05c800` | top-half mask read |
| 558309-558312 | `R 05c804` (=MASK), `W = 10000`, `R 05c804` (=0), `W = 0` | **top-half drain #1** (`+0x34b0..0x34c8`, trailing `W=0` unconditional) |
| 558313 | `R 05c808` | secondary word → `priv+0x234[n]` |
| **558344-558347** | `R 05c040 / 044 / 048 / 04c` | **status-block read #1 = message A** (`+0x4640`; the `05c04c` read retires A in the model) |
| 558364 | `W 05c000 = 100000` | **the driver's ACK** (`+0x47f0` → `_svoif_mt85xx_send_table_data_ack_cmd`) |
| 558365-558367 | `W 05c004/008/00c = 0,0,0` | ACK args all zero |
| 558384-558385 | `R 05c020`, `W 05c020 = 1` | ACK doorbell → **model stages message B** (`type==0x10` row) |
| 558392 | `R 05c800` | top-half, second entry |
| 558393-558396 | `R 05c804` (=MASK), `W = 10000`, `R 05c804` (=0), `W = 0` | **top-half drain #2** (B's latch) |
| 558397 | `R 05c808` | |
| **558406-558409** | `R 05c040 / 044 / 048 / 04c` | **status-block read #2 = message B** — the driver consumed the type-0 completion |
| *(silence)* | — | `hw_chg_st(priv,2)`, `port_intr`, `check_status` = `0x58`, HSM, `data_xfer(512)`, `ata_dev_read_id` validity ladder: **all memory-only, zero MMIO** |
| 558854 | ↳UART **`ata1.00: failed to IDENTIFY (device reports invalid type, err_mask=0x0)`** | |
| 560290 | ↳UART `[IDE]<sata_mt85xx_prereset>ch:0, deadline:0xfffbc42b start` | EH retry begins |
| 560453 / 560629 / 563232 | ↳UART prereset end / softreset start / `end, class=3` | |

### Episode 2 (round-3 `read_id`) — structurally identical

| VM line | access |
|---|---|
| 563276-563280 | `W 05c000 = a1000000`, `W 004/008/00c = 0,a000,0`, `R 05c020` |
| 563281 | `W 05c020 = 1` — doorbell |
| 563288-563293 | top-half **drain #1** (`R 05c800`; `R/RW/W` on `05c804`; `R 05c808`) |
| **563312-563315** | **status-block read #1** (message A) |
| 563316-563319 | `W 05c000 = 100000`, `W 004/008/00c = 0,0,0` — **ACK** (1 line after `05c04c` this time) |
| 563320-563321 | `R 05c020`, `W 05c020 = 1` — doorbell → message B |
| 563328-563333 | top-half **drain #2** |
| **563342-563345** | **status-block read #2** (message B) — consumed |
| 563614 | ↳UART `ata1.00: failed to IDENTIFY (device reports invalid type, err_mask=0x0)` |
| 565376 / 565543 / 565725 | ↳UART prereset start / end / softreset start — **third reset with no further post** (probe gave up / module removed: `PRE_sata_mt85xx_mod.ko_RC=0`) |

**Whole-run `05cxx` census (full log).** Posts (`W 05c000`, 6): 553099 `a1000000` (the loader-phase
`chk_int_ldr` request — `arg == 0`) · 553483 `00100000` (its ACK) · **558286 `a1000000`** (IDENTIFY, round 2) ·
558364 `00100000` (ACK) · **563276 `a1000000`** (IDENTIFY, round 3) · 563316 `00100000` (ACK).
Status-block reads (`R 05c040`, 7): 465948 (boot-status word only — the `[IDE]int_val = 0x10000`
read, no `044/048/04c` follow-up) · 553123 and 553491 (loader phase: the polled chk read, then the
ACK-provoked type-0 read) · **558344, 558406** · **563312, 563342**. `R 05c044/048/04c` 6 each
(same six complete quadruples). Drains: `05c804` 26 lines total (13 R/W pairs, full-log `grep`);
`R 05c800` 5 (553924, 558308, 558392, 563288, 563328) and `W 05c800` 2 (311817 `= 0`, 553883
`= fffffff0`) — note 558308 is the **first** mask read in the IDENTIFY episode, i.e. the mask was
still `fffffff0`; `R 05c808` 4, and only the four IDENTIFY-episode drains read `05c808`. Other: `R 05c704` 3 / `W 05c704` 3 · `W 05c600`/`R 05c600`/
`W 05c604`/`R 05c604` 1 each · `W 05c780`/`R 05c780` 1 each · `W 05c500` 1 (VM 462927, `= 0x7f`)
· `W 05c010` 1 (VM 554622, `"LOGO"`, unimplemented) · **`05c4xx` 0**.

---

## 2. Q2 — the key sequence: what the model answers the ACK with, and what the driver does

**Model side (DECODED from the source that ran, `sony-bx510.c:314-372`).**

```
static void bx510_fe_dispatch(Bx510State *s) {
    code = (w0>>24)&0xff; type = (w0>>16)&0xff; arg = w1|w2|w3;
    if (type == 0x10) {                       /* the driver's table-data ACK  */
        bx510_fe_post(s, 0, 0, 0, 0);         /* ← MESSAGE B: type 0, byte3 0 */
        return;                               /*   ... and that is ALL it does */
    }
    if (code == 0xa1 && arg == 0) {           /* chk_int_ldr loader block     */
        write fe_reply_block @ FE_REPLY_OFF (0x1000);
        post(0x00100000, 0x1000, 0x200, 0);
    }
    if (code == 0xa1) {                       /* IDENTIFY PACKET (C99 path)   */
        write s->identify @ FE_IDENT_OFF (0x2000), 0x200 bytes;   /* ← zeros in C99 */
        post(0x00100000, 0x2000, 0x200, 0);   /*   message A, and NOTHING else */
    }
    post(0,0,0,0);                            /* 0xf7 / 0x08 / unknown        */
}
```

Two properties matter here, both verified in the trace:

* the `0xa1`-with-args branch posts **exactly one** message (no completion is staged with the
  payload), so the only type-0 message in the episode is the one the **ACK** provokes;
* `bx510_fe_post` stages into a 4-slot queue and only *raises* `0x5c804 |= MASK`; the queue is
  retired **on the `05c04c` read** (`sony-bx510.c:448-470`), which is why each message shows up as
  exactly one 4-register quadruple.

**Driver side.** Read #1 (`558344-558347`) returns type 0x10 ⇒ `+0x47ac` ⇒ dir path ⇒ `memcpy`
(§3) ⇒ `+0x47ec` ack ⇒ `W 05c000 = 00100000` (558364). Read #2 (`558406-558409`) returns type 0
with byte3 = 0 ⇒ `+0x4674` state not in {0,5} ⇒ `+0x468c` `priv+0x48 == 1` ⇒ `+0x48ec`
`BSP_InvDCacheRange(priv+0x4c, priv+0x54)` ⇒ `byte3 == 0` ⇒ `priv+0x48 != 0` ⇒ **`+0x46b8`
`hw_chg_st(priv,2)`** ⇒ `priv+0x220 = 2` ⇒ `check_status` mode-1 map `0x58`
(DRDY|DSC|**DRQ**) ⇒ tail `r9 != 0` ⇒ `disable_irq` → `ata_bmdma_port_intr` (`+0x4830`) →
`enable_irq` → return.

**Did ANY type-0 completion get consumed in this run?** **Yes — two of them** (one per EH round,
558406-558409 and 563342-563345). Consequence for `hsm-buffer-seq.md`: its §0.2/§1.6 claim that
"the handler never loops; every queueing of the work item consumes one message and returns" and
its §3.2 "any two-message scheme is wrong" are **falsified as predictions** — C99 is exactly the
observable §3.3-B named as the falsification test ("**two** `R 05c040/044/048/04c` quadruples
inside one IDENTIFY qc window"). The two-message scheme (payload A, then the ACK-provoked
completion B) **works**.

*Mechanism not resolved by this trace* (mark INFERRED, §8): whether the worker took the `+0x46d4
beq 0x4578` loop-back with `r9 == 0` and stayed alive in `wait_event` to catch B, or the work item
was queued a second time. The only `queue_delayed_work(priv+0x2e8)` site is `qc_issu_task
+0x7164`, and `qc_issu_task` runs once per `qc_issue` (one `0xa1` post per episode ⇒ one
`qc_issue`), so the loop-back is the likelier reading — but nothing in this MMIO window
distinguishes them.

---

## 3. Q3 — what `data_xfer` copied, and the `05c4xx` question

### 3.1 Every `05cxx` access between quadruple #1 and the next post

**None outside the mailbox/status registers, and no `05c4xx` at all.** Between VM 558347 (end of
quadruple #1) and VM 563276 (the next `W 05c000`, i.e. the next post) the only `05cxx` accesses are
the ones in §1: the ack post (`558364-558385`), the top-half drain #2 (`558392-558397`), quadruple
#2 (`558406-558409`) — then 4 866 trace lines of console/IRQ traffic until the next episode's post.
No `05c400/05c404/05c408/05c40c`, no `05c010`, nothing from the `0x5c0xx` command page.

**Whole run: `05c4xx` = 0 accesses.** So `data_xfer`'s mode-1 READ-CDB descriptor arm
(`+0x5800..0x587c`, `fe-ata-cmd.md` §1.2) never ran — the ATAPI branch at `+0x546c` needs
protocol ∈ {5,6,7} and IDENTIFY PACKET is protocol 2 → the copy that ran is the plain
`memcpy(libata_buf, priv+0x4c + priv+0x58, buflen)` at `+0x5560` (`hsm-buffer-seq.md` §2.3).
This independently re-confirms the C95 §5 closure ("`05c40c`/`05c400`/`05c404` triple absent ⇒
not `data_xfer`") on a run where the data phase *did* execute.

### 3.2 Did the memcpy at `+0x4878` fire? — yes (inference chain, each link trace-anchored)

1. **The qc *completed* with `err_mask = 0` and the HSM saw DRQ.** Proof: the UART line is
   `failed to IDENTIFY (device reports invalid type, err_mask=0x0)`. Per
   `id-validity-check.md` §0.1/§1 that string is emitted by the **validity ladder** at
   `ata_dev_read_id +0x3c…`, which only runs **after** `ata_do_dev_read_id` returned 0; the
   DRQ-less outcome is a *different* pair of strings
   (`failed to IDENTIFY (I/O error, err_mask=0x2)` + `ST_FIRST: !(DRQ|ERR|DF)`). Neither appears.
2. **DRQ ⇒ `priv+0x220 ∈ {2,3}` ⇒ `hw_chg_st(priv,2)` ran** at `+0x46b8` (the only writer of the
   value 2 on this path, `hsm-buffer-seq.md` §1.7/§1.3).
3. **`hw_chg_st(priv,2)` is reachable only through `+0x46a4/0x46ac`, which require
   `priv+0x48 != 0`** ⇒ at the moment of read #2, `priv+0x48 == 1` (protocol 2, `tf.flags & 8`
   clear — `qc_prep +0x2ef4..0x2f18`, decoded in §1.3).
4. **`priv+0x48` is written only by `qc_prep`**, and no second `qc_prep`/`qc_issue` ran between
   read #1 and read #2 (no post, one qc) ⇒ `priv+0x48 == 1` **also at read #1** ⇒ the type-0x10
   dispatch at `+0x47d8` took `beq 0x4850` (dir 1, FE→host), **not** the dir==0 drop (`+0x47ec`).
   The ACK post alone would be ambiguous (all three dirs ack); this is what removes the ambiguity.
5. ⇒ **`bl memcpy` at `+0x4878` executed**, with `r10 = min(priv+0x54, w2)` where `w2 = 0x200`
   (`FE_IDENT_LEN`) and `priv+0x54 = 0x200` (armed by `qc_issu_task +0x6cdc` from `qc->nbytes`,
   §2.2). So 512 bytes were copied from `*(svoif_int_ldr_dram) + w1`.

### 3.3 …but the 512 bytes were all zeros

`w1 = FE_IDENT_OFF = 0x2000` ⇒ phys `(0x7f << 22) + 0x2000 = 0x1FC02000`
(virt `0xdfc02000`; the guest writes `05c500 = 0x7f` at VM 462927, and the driver's own
`<sata_mt85xx_id_atapi_dev>copy from (0xdfc01000, 0x200)` at VM 553423 pins
`virt 0xdfc00000 ↔ phys 0x1FC00000 = 0x7f << 22` exactly). The source of that copy is
`s->identify[512]`, and **`s->identify[]` was never populated in this run**:

* `bx510_sata_build_identify()` — `memset(identify,0,…)` then `w[0] = 0x8580` etc. — is called
  **only** at `sony-bx510.c:942`, inside `if (s->sata_disc_path && s->sata_disc_path[0])`;
* the QEMU command line never sets it: `run.py:command()` emits `-M sony-bx510` plus
  `$BX510_MACHINE_OPTS` only, and the probe's `meta.json` has no machine-opt/disc key;
* the model's own announcement is **absent** from `bdpdrv-runC99.uart.log`:
  `grep -c "SATA ATAPI drive attached"` = **0**, while the same grep on C76/C77/C91/C93 = 1 each
  (`bx510: SATA ATAPI drive attached: /home/aftermath/sacd-verify/firebird.iso (1064208 sectors)`).
  The property exists (`sony-bx510.c:989`, `sata-disc`) and the ISO is still on the VM;
* `bx510_reset()` does not initialise `identify[]` (checked line by line), so it is QOM zero fill.

⇒ `bx510_fe_dram_write()` wrote 512 `0x00` bytes to `0x1FC02000`; the `+0x4878` memcpy copied
512 zeros into `priv+0x4c`; `data_xfer +0x5560` copied 512 zeros into `dev->id`; `id[0] = 0x0000`
⇒ `ldrsh`/`bge` (`libata .text+0x3cb8/0x3cc0`) ⇒ `device reports invalid type`, `err_mask = 0`.

**Cross-check that the DRAM-window mechanism itself is healthy in this very run:** the pre-IDENT
loader message used the identical path (`FE_REPLY_OFF = 0x1000` → virt `0xdfc01000`), the driver
read it, found `'BOOT'` / `0xeeee` and printed `[IDE]Internal loader boot code mode` +
`----- Loader is in manufacture mode !! -----` (VM 553630 / 553839). The window, the page
register, the type/offset/length words and the `memcpy` are all working; only the table was empty.

**Untestable residual:** the trace cannot distinguish "memcpy wrote 0x200 zero bytes" from
"`r10` was 0 and the bounce buffer already held zeros" — both produce identical MMIO and the
identical UART line. The first is favoured by the decode (`qc->nbytes = 0x200`, `w2 = 0x200`) and
is what §8 records.

---

## 4. Q4 — the ACK's own reply (message B): consumed, twice, correctly

| round | drain #2 | block read #2 | state after | console consequence |
|---|---|---|---|---|
| 1 | 558392-558397 | **558406-558409** | `priv+0x220 = 2` → `check_status 0x58` (DRQ) | 558854 `invalid type, err_mask=0x0` |
| 2 | 563328-563333 | **563342-563345** | idem | 563614 `invalid type, err_mask=0x0` |

So the answer to "did the driver consume message B this run" is **yes, once per EH round**. And
it is **not** the thing that breaks the next qc: B does exactly the one job it exists for
(payload-precedes-completion ⇒ the state advance to DRQ is the *last* transition before the data
phase). Round 2 is a fresh `prereset`/`softreset` (`class=3`) plus a fresh `0xa1` post; its MMIO
shape is identical to round 1's with no carry-over (the surface `05cxx` count shows exactly two
identical post/drain/read/ack/drain/read groups). The `×2` is libata's standard EH retry, not
state poisoning.

---

## 5. Verdict

**The C99 model change worked at the protocol level and was invisible at the UART level.**

* worked: two posts per qc are both read; the ACK-provoked type-0 completion is delivered, drained
  and dispatched; the state machine advances to DRQ; libata runs the data phase; the payload
  `memcpy` (`+0x4878`) fires. This is variant **B** of `hsm-buffer-seq.md` §3.3, not variant **A**.
* not worked: the payload content. `identify[]` was empty because no `sata-disc` was configured —
  a condition that has been true since C95 and that no amount of mailbox tuning could reveal
  through the UART, because `err_mask=0x0` + `device reports invalid type` is exactly what C97
  and C98 printed while their payloads *never arrived*. The discriminating evidence is MMIO-only:
  the number of status-block quadruples per post.

---

## 6. Q5 — C100 recipe rows (model file **not** edited)

The change is a run-configuration row plus a preflight gate, not a protocol change.

| id | row | why | cost |
|---|---|---|---|
| **C100-R1** | **Attach the disc**: `BX510_MACHINE_OPTS='sata-disc=/home/aftermath/sacd-verify/firebird.iso'` (property `sata-disc`, `sony-bx510.c:989`; `run.py` prefixes `-M sony-bx510,`). | Builds `identify[]` via `bx510_sata_build_identify()` — restores the C91/C93 condition that has been silently missing since C95. Zero code change. | 1 env var |
| **C100-R0** (gate, do first) | After the run, `grep -q "bx510: SATA ATAPI drive attached" bdpdrv-runC100.uart.log` **or abort the interpretation**. | 5 runs of protocol work were interpreted against an empty table. The line is the model's own statement that the payload is non-empty. | 1 grep |
| **C100-R2** | If no ISO is wanted: call `bx510_sata_build_identify(s)` in `bx510_init` **outside** the `sata_disc_path` block (sectors = 0 when `s->sata_blk == NULL`). | Same table with a 0-sector capacity; the class/`id[0]` gate is what C100 is testing, capacity is not. | 2-line model change — needs approval, not in scope here |
| **C100-R3** | **Keep the two-message order as-is** (payload A, then the ACK-provoked type-0 B). Do **not** adopt §3.3-A (payload only). | C99 proves both messages are read; §3.3-A would delete the only transition to DRQ and re-introduce the `err_mask=0x2` / `ST_FIRST` outcome by construction. | none |
| **C100-R4** | Leave message B's content alone (`w0 = w1 = w2 = w3 = 0`, type 0, byte3 0 = success). No "silent no-reply" treatment for the ACK. | B is consumed and does the right thing; silencing it would strand `priv+0x220` at 1 and turn the DRQ poll into `err_mask=0x2`. | none |
| **C100-R5** (diagnostic) | If C100 still fails at IDENTIFY, vary **one** of: (a) `FE_IDENT_OFF` (0x2000 → e.g. 0x3000), (b) the identify `w[0]` value, and re-run with C100-R0. Count status-block quadruples per post again. | (a) tests whether `priv+0x4c` is re-armed between copy and `data_xfer` (variant-C hazard); (b) tests the validity ladder itself. | 1 run each |

**Predicted C100 observable** (with the table non-empty and the rest unchanged): the same twice-read
MMIO shape, then instead of `invalid type` the read_id validity ladder passes (`0x8580 & 0x8000 ≠ 0`)
and the probe should reach `ata1.00: ATAPI: SONY    BDPSACDEMUL, 1.00, max UDMA/…` and
`configured for UDMA/…` (`id-validity-check.md` §0.4/§6 — the string/serial byte-offset and
`w[53]`/`w[83]` bugs in that table are already fixed in the source that ran here).

---

## 7. Corrections to earlier docs (this run forces them)

1. **`hsm-buffer-seq.md` §0.2 / §1.6 / §3.2** — "the handler consumes exactly ONE status-block
   message per queueing" and "two messages per qc cannot work" are **falsified** by 558406-558409
   and 563342-563345: two quadruples, one `qc_issue`, one post. §3.3-B's stated falsification
   observable fired. The `priv+0x2dc`-never-cleared argument needs re-derivation (the loop-back at
   `+0x46d4` is *not* dead in this run).
2. **§3.4 recommendation ("drop the completion — variant A")** — must be withdrawn: the completion
   that the ACK provokes is the only thing that advances `priv+0x220` to 2, and C99 shows it
   arriving in a *second* block read, so variant A is strictly worse.
3. **`hsm-buffer-seq.md` §4.2 / `fe-ata-cmd.md` §6 diagnostic pair** — "ack post present +
   `err_mask=0x2` = payload dispatched but state-gated; `err_mask=0x0` + validated-but-wrong table
   = …" — needs a third row: **`err_mask=0x0` + `invalid type`** is what a *perfectly delivered*
   **empty** payload produces, and it is indistinguishable at UART level from "payload never
   arrived". Only the quadruple count separates them.
4. **Model-side gap worth a line of code** (not applied here): `bx510_sata_build_identify()` is the
   sole writer of `s->identify[]` and is gated on the disc; a one-line
   `if (!s->identify[3]) qemu_log_mask(LOG_GUEST_ERROR, …)` at the `0xa1` reply would have made
   this visible in C95.
5. **Brief line-number mapping** — `gz line N == VM line 553399+N`, not 553400+N (§Method).

---

## 8. Certainty ledger

**VERIFIED (trace, cited line numbers):** the two posts and their four-word command blocks; the
four top-half drains and their exact `R/RW/W` shape; the two status-block quadruples per episode;
the driver's ACK post in both episodes; the absence of every `05c4xx` access in the run; the
`05c500 = 0x7f` page write; the two UART outcomes and their inline positions; the presence of
`bx510: SATA ATAPI drive attached` in C76/C77/C91/C93 and its absence in C95/C97/C98/C99.

**DECODED (instruction/source level):** the model's per-code reply rows and its retire-on-`05c04c`
queue semantics; `hw_chg_st(priv,2)` reachability requiring `priv+0x48 != 0`; the `err_mask=0x0`
`invalid type` line being the post-read validity ladder; `bx510_fe_dram_write` skipping only when
`fe_dram_page == 0` (not the case here); `identify[]` having no writer other than the
disc-gated builder.

**INFERRED:** (a) that `r10` was `0x200` at `+0x4874` (three inputs decoded, none trace-visible;
if it were 0 the outcome is identical); (b) the mechanism by which the worker came back for
message B (loop-back vs. second queueing — the post count favours loop-back); (c)
`s->identify[]` being exactly zero rather than "some other non-zero garbage" — it is QOM-allocated
and never written, so zero.

**OPEN (settling experiment):** whether `priv+0x4c` is re-armed between the payload copy and
`data_xfer` on a *successful* read (variant-C hazard) — only reachable once C100 delivers a
non-empty table.
