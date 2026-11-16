# libata EH recovery map — what the driver does after a failed IDENTIFY, and how to read a C99 UART at a glance

Decode of `/tmp/bdpdrv/libata.ko` (2.6.35 ARM, unstripped; `ata_eh_reset` `.text+0xf090`,
`ata_eh_recover` `.text+0x100fc`, `ata_scsi_error` `.text+0x11270`, `ata_dev_disable`
`.text+0xd9c0`) and `/tmp/bdpdrv/sata_mt85xx_mod.ko` (`sata_mt85xx_softreset` `.text+0x4b18`,
`sata_mt85xx_tf_read` `.text+0x5f50`), cross-read against
`bdpdrv-runC94/C95/C97/C98/C99.uart.log`.

**Extends, does not re-derive**, `libata-probe.md` §1-2 (hook order, timeout tables, the
`-EBUSY` mechanism, the 3-warn/4-`SRST failed` cadence) and `id-validity-check.md` §1/§5 (the
`id[0]` validity ladder and the stale-bounce-buffer proof). Only the *recovery loop* is new
here.

**Address convention** as in those docs: section-relative (`libata .text+0x…`,
`sata .text+0x…`). Reproduce any site with

```
/opt/homebrew/opt/llvm/bin/llvm-objdump -d -r --section=.text /tmp/bdpdrv/libata.ko
```

ARM `REL` relocations: the addend is the in-place word at the reloc site, which is how every
string below was mapped to the branch that prints it.

---

## 0. Bottom line — the seven facts a C99 reader needs

1. **Three nesting levels, not one.** One *scsi EH invocation* (`ata_scsi_error` →
   `ata_eh_recover`) may contain **several reset+identify passes**; each pass calls
   `ata_eh_reset` **once**, and that one call may itself run up to **4 reset attempts**
   (`ata_eh_reset_timeouts` = `{10000,10000,35000,5000,ULONG_MAX}` ms — the attempt budget is
   *counted out of the table at runtime*, `.text+0xf0f8..0xf124`, so 4 attempts).
2. **A pass's UART frame is fixed**: `[IDE]<sata_mt85xx_prereset>ch:0, deadline:0x… start`
   → `… end` → `[IDE]<sata_mt85xx_softreset>ch:0 start` → `… end, class=N` → **verdict line (or
   silence)**. C97/C98/C99 all show exactly three such frames at the same line numbers:
   **285-289 / 290-294 / 295-298** (C94/C95 start at 285 too, then run long — §4.1).
3. **The retry budget is `tries[]`, initialised per EH invocation to 3** (`.text+0x10138
   mov r7,#1; 0x1013c mov r5,#3; 0x10180/0x10184` select 1 or 3 on `link-><+0x10> & 0x20`).
   It is decremented on every failed device verdict (`.text+0x10bd0 sub r2,r2,#1`) — except
   `-EAGAIN`.
4. **`-EINVAL` (“device reports invalid type”) does not spend the budget down to zero**: after
   the decrement the value is *capped at 1* (`.text+0x10f28 cmp r2,#1; 0x10f2c movge r2,#1`),
   i.e. an invalid-type verdict buys one more pass. That is why C97/C98/C99 stop at **three**
   frames — the third pass never returned (no verdict, and no `EH complete` anywhere in those
   logs).
5. **The `%s resetting link` banner is a new-invocation marker, not a per-attempt one.** It is
   gated on `verbose = !(ehc->i.flags & ATA_EHI_QUIET)` (`.text+0xf0ec`, `0xf3cc..0xf428`).
   C94/C95 passes 1-2 print **no** banner (same EH invocation, quiet); pass 3 prints one banner
   *per reset attempt* (lines 311/315/319/323) because it is a **new** invocation.
6. **Give-up / success are both single lines at the *recover* level**: `ata1: reset failed,
   giving up` (`.text+0x103c0`, after `ata_eh_reset` returns non-zero) then `ata1: EH complete`
   (`.text+0x11a98`, unconditional at the end of `ata_scsi_error`). Success is
   `ATAPI: …` + `configured for …` + `EH complete`, with **no second reset frame** — a late
   pass's IDENTIFY landing is absorbed inside the pass loop, not by restarting EH.
7. **`class=3` is re-derived every pass from live register bytes**, not remembered:
   `sata_mt85xx_softreset` calls `ata_sff_dev_classify(&link->device[0], 1, &err)` on every
   invocation (`sata .text+0x4eb4`), and `ata_dev_classify` (`.text+0x328`) returns 3 only for
   **`lbam == 0x14 && lbah == 0xeb`**. In ATAPI class libata then sends **`0xa1 IDENTIFY
   PACKET DEVICE`**; a `0x00/0x00` signature would make it class 1 and send **`0xec IDENTIFY
   DEVICE`** instead (`.text+0x3c14` vs `.text+0x3d6c`).

---

## 1. The state machine, decoded

### 1.1 Level A — the EH invocation (`ata_scsi_error`, `.text+0x11270`)

```
ata_scsi_error(ap):
    … reap timed-out qcs, ata_eh_analyze_* …
    ata_eh_recover(ap, prereset, softreset, hardreset, postreset, NULL)   /* .text+0x100fc */
    ata_eh_finish(ap)                                                     /* .text+0x111b4 */
    if (ap->pflags & ATA_PFLAG_EH_PENDING)                                 /* .text+0x11a44.. */
        if (++eh_tries < 5) goto repeat;
        printk("%sata%u: EH pending after %d tries, giving up")            /* .text+0x11ad0-0x11ae0, %d = 5 */
    ap->pflags &= ~ATA_PFLAG_EH_PENDING;
    printk(KERN_INFO "%sata%u: EH complete\n")                             /* .text+0x11a98 */
```

`EH complete` has **no gate**: if a run does not contain it, the EH thread never got to the end
of `ata_scsi_error` — the probe is still in flight (or wedged). C97/C98/C99 contain **zero**
`EH complete`; C91/C93/C94/C95 contain exactly one each.

### 1.2 Level B — the pass loop (`ata_eh_recover`)

Decoded, one EH invocation:

```
/* pre-pass, runs ONCE per invocation: .text+0x10120..0x10220 */
for each link:
    if (link->eh_context.i.action & ATA_EH_ENABLE_LINK) { … }           /* 0x10140 tst #8 */
    for each enabled dev:
        ehc->tries[devno] = (link-><+0x10> & 0x20) ? 1 : 3;             /* 0x10168..0x10184 */
        … clear per-dev action bits …

retry:                                                                  /* .text+0x10244 */
    for each link whose action has SOFTRESET|HARDRESET (0x10320 tst #6):
        nr_unknown = count(devs with dev->class == ATA_DEV_UNKNOWN)
        rc = ata_eh_reset(link, nr_unknown, prereset, softreset, hardreset, postreset)  /* 0x10384 */
        if (rc) { printk("%sata%u.%02u: reset failed, giving up\n"); stop this link }   /* 0x103c0 */

    nr_failed = 0;                                                       /* 0x1074c */
    for each link, for each enabled dev:
        if (dev->class ∈ {1,3,5,7})  ata_dev_revalidate(dev, …)           /* 0x1078c → 0x107e8 */
        else                         ata_dev_read_id(dev, &dev->class, POSTRESET, dev->id)  /* 0x10868 → 0x108bc */
        rc == 0        → ata_ering_clear; mark dev OK                    /* 0x108e8 */
        rc == -2       → ata_eh_thaw_port; next dev                      /* 0x10b90 (-ENOENT) */
        rc != 0        → failed_dev = dev; nr_failed++;
                         if (rc != -EAGAIN) ehc->tries[devno]--;         /* 0x10bd0 */
                         dispatch on rc (below)
    for each dev marked OK:
        dev->class = ehc->classes[devno]; ata_dev_configure(dev)         /* 0x10984/0x10998 */
        (failure → dev->class = 0; rc = -EINVAL; → failure handler)      /* 0x10fd8 */

    if (nr_failed != 0) goto retry;                                      /* 0x10c58 */
    … TEST UNIT READY / FLUSH retries, ata_set_mode, ata_dev_enable_pm …
```

The failure dispatch (`.text+0x10bd8..0x10be8`), with the *return values of `ata_dev_read_id`*:

| rc | value | site | what libata does |
|---|---|---|---|
| `-EAGAIN` | −11 | `cmn r7,#11` → `0x10bb8` | **no** `tries` decrement; continue |
| `-ENODEV` | −19 | `cmn r7,#19` → `0x10f04` | `ehc->i.probe_mask \|= 1<<devno` (`link+0xb4`), then fall into the −EINVAL code (this is what turns the *next* pass's rejection into `NODEV after polling detection`) |
| `-EIO` | −5 | `cmn r7,#5` → `0x10ec4` | if `tries == 1`: `sata_down_spd_limit()` + (if `dev-><+0x30> > 8`) `ata_down_xfermask_limit()` (that byte is set to 8 by `ata_eh_reset` itself, `.text+0xf1d4`, so the second call is normally skipped). On this port both are no-ops (no SCR hooks, `sata_scr_read` → `-EOPNOTSUPP`), so **the UART shows nothing new** |
| `-EINVAL` | −22 | `cmn r7,#22` → `0x10f18` | `tries = min(tries, 1)` (the cap in §0.4) then continue |
| anything else (e.g. −22 from `ata_dev_configure`) | | `0x10fd8` | `dev->class = 0` then the same handler |

Then the common tail (`.text+0x10bec`):

```
if (dev->class ∈ {1,3,5,7})            /* ATA / ATAPI / PMP / SEMB */
    if (ehc->tries[devno] == 0) → ata_dev_disable(dev)  + schedule-probe / detach   /* 0x10fec */
link->eh_context.i.action |= SOFTRESET|HARDRESET   /* .text+0x10c20 orr #6 */  → another pass
```

**Note the trap (DECODED):** `ata_dev_read_id` always stores `dev->class = 0` on return
(`.text+0x108d4`, and again on the configure-failure path `.text+0x10fe0`). After a failed
IDENTIFY the class test above therefore sees **0**, so the `tries == 0 → ata_dev_disable`
branch is **not** taken — the pass just re-arms `action |= 6` and loops. In the EINVAL runs
(C97/C98/C99) the device is never disabled and `ata1.00: disabled` never prints.

### 1.3 Level C — the reset-attempt ladder (`ata_eh_reset`)

```
      verbose = !(ehc->i.flags & ATA_EHI_QUIET)              /* .text+0xf0ec, flags at link+0xb0 */
      max_tries = count(ata_eh_reset_timeouts[] != ULONG_MAX) /* .text+0xf0f8..0xf124 = 4 */
      action = link-><+0x10>
      if (action & 2) hardreset = NULL;   if (action & 4) softreset = NULL   /* 0xf130..0xf140 */
      for each dev: dev-><+0x30> = 8 ; ehc->classes[] = ATA_DEV_UNKNOWN
      ata_eh_about_to_do(link, NULL, 6)                       /* 0xf1b4 */

retry:                                                        /* .text+0xf1xx */
      if (try) { deadline = jiffies + ata_eh_reset_timeouts[try]; try++ }  /* 0xf3a8..0xf3c4 */
      link->eh_context.i.action &= ~(SOFTRESET|HARDRESET);                /* 0xf20c bic #6 */
      rc = prereset(link, deadline)                                        /* ata_do_reset 0xc8c8 */
          → "prereset failed (errno=%d)" on hard error                    /* 0xf2c0 */
          → "-ENOENT" = skip reset                                        /* libata-probe §1 */
      if (verbose) printk("%s %s resetting link")                          /* 0xf420 / 0xf4ec */
      rc = reset(link, devmask=1, deadline)          /* = sata_mt85xx_softreset, sata .text+0x4b18 */
          → on failure with time left on the deadline:
                printk("reset failed (errno=%d), retrying in %u secs")      /* 0xfa50 */
                schedule_timeout_uninterruptible(remaining)                /* 0xfa70 */
          → if (try == max_tries) goto give_up                             /* 0xfa7c-0xfa84 */
      postreset(link)                                                      /* ata_std_postreset */
      classification: dev->class = ata_sff_dev_classify(dev, present=1)    /* for this port, inside
                                                                            the driver's own softreset */
      if (classify && misclassified)                                       /* 0xf7f8..0xf804 */
          printk("link online but %d devices misclassified, retrying")      /* 0xf83c */
          rc = -EAGAIN → retry (bounded by try == max_tries)                /* 0xf854, 0xf808 */
give_up:
      return -EIO/-ENODEV → caller prints "reset failed, giving up"
```

Two consequences that matter for log reading:

* `deadline:0x…` printed by the driver's prereset is **jiffies at entry + 10000** (attempt 1's
  entry in `ata_eh_reset_timeouts`). With `HZ = 1000`, `deadline` is therefore a millisecond
  clock: **subtracting two rounds' deadlines gives the wall time between the round starts.**
* `reset failed (errno=…), retrying in N secs` only appears when a reset attempt failed *fast*
  (deadline not yet exhausted). It is **absent** from C94/C95 because every attempt there burned
  its full deadline; it is absent from C97/C98/C99 because every reset there **succeeded**.

---

## 2. Timings, and the measured round clock

| quantity | value | site |
|---|---|---|
| reset attempts per `ata_eh_reset` | **4** (counted from the table) | `.text+0xf0f8..0xf124` |
| per-attempt deadline (prereset + reset share it) | `{10000, 10000, 35000, 5000}` ms | `.text+0xff18` load, `.rodata+0xb1c` |
| `ATA_WAIT_AFTER_RESET` (post-SRST settle) | 150 ms | `ata_sff_wait_after_reset` `.text+0x14724` |
| status poll cadence in `ata_wait_ready` | `msleep(50)` | `.text+0x6bec` |
| "link is slow to respond" gate | elapsed > 5 s **and** > 3 s of deadline left | `.text+0x6bac`, `0x6c48` |
| IDENTIFY (`0xa1`) internal-cmd timeout, 1st time | **5000 ms**, then 10 s, 30 s, 30 s … | `.text+0xd0b0..0xd124`, `.text+0xd130..0xd1b0` |
| `tries[]` init | 3 (or 1 if `link-><+0x10> & 0x20`) | `.text+0x1013c..0x10184` |
| re-probe after disable restores `tries` + clears the cmd-timeout ladder | `tries=3`, `memzero(link+0x114+24*devno, 24)` | `.text+0x1102c..0x1103c` |
| EH-invocation repeat limit before "EH pending after %d tries" | 5 | `.text+0x11ad0` |

Measured round clocks (deadline deltas, HZ = 1000 → ms):

| run | R1→R2 | R2→R3 | reading |
|---|---|---|---|
| C94 | `0xfffbbb72`→`0xfffbcfab` = **5177 ms** | →`0xfffce209` = **70238 ms** | R1 = IDENTIFY timed out at its **5 s** first-attempt timeout; R2 = prereset 10 s + 10+10+35+5 s softreset ladder = **70 s**, exactly |
| C95 | 5186 ms | 70202 ms | same |
| C97 | 267 ms | 257 ms | reset + IDENTIFY both complete; only the payload verdict fails |
| C98 | 267 ms | 257 ms | same |
| C99 | 266 ms | 257 ms | same |

⇒ ~260 ms per pass is the healthy "reset+identify round trip" cost on this rig (150 ms settle +
polls + the FE reply). Anything in the **seconds** range per pass is a deadline burn, i.e. a BSY
or SError-style wait, not an IDENTIFY verdict problem.

---

## 3. Where `class=3` comes from, and whether the model controls it per pass

`ata_dev_classify` (`libata .text+0x328`, called from `ata_sff_dev_classify` `.text+0x12da4`)
compares the signature **word** at taskfile offset 14, i.e. `lbam | lbah<<8`:

| `(lbam, lbah)` | class | meaning |
|---|---|---|
| `(0x00, 0x00)` | **1** | `ATA_DEV_ATA` → `ata_dev_read_id` sends **`0xec` IDENTIFY DEVICE** (`.text+0x3c14`) |
| `(0x14, 0xeb)` | **3** | `ATA_DEV_ATAPI` → sends **`0xa1` IDENTIFY PACKET DEVICE** (`.text+0x3d6c`) |
| `(0x69, 0x96)` | 5 | PMP |
| `(0x3c, 0xc3)` | 7 | SEMB |
| anything else | 0 | `ATA_DEV_UNKNOWN` → `read_id` prints `unsupported class`, returns `-ENODEV` |

(Constants decoded at `.text+0x338 ldr r2,=0xeb14`, `0x348 =0x9669`, `0x354 =0xc33c`.)

The driver's softreset (`sata .text+0x4b18`) has two mutually exclusive sources for those bytes
on its mode-1 (mailbox) path:

```
sata_mt85xx_softreset(link, devmask, deadline):
 4f44: if (priv+0x8 == 1)                          /* mailbox mode */
 4f48:     if (priv+0x220 == 0) goto synth;        /* FL_* idle */
 4f54:     if (priv+0x220 == 5) goto synth;        /* FL_* error/unknown */
 4f5c:     priv+0x48 = 0;  _sata_mt85xx_hw_chg_st(priv, …)
 4f6c:     priv+0x29c = 8;  _svoif_mt85xx_send_ata_cmd(priv)   /* FE opcode 0x08 = SRST */
 4e2c:  rc = ata_sff_wait_after_reset(link, devmask=1, deadline)   /* 150 ms + polls */
 4e44:  if (rc == -ENODEV) …
 4e70:  printk("SRST failed (errno=%d)") on any other rc          /* C94/C95 line 297 etc. */
 4eb4:  class = ata_sff_dev_classify(&link->device[0], 1, &err)
 4ec4:  *r_err = rc;
 4ed0:  if (ide_log_en & 1) printk("[IDE]<%s>ch:%d end, class=%d")   /* C97 line 288 etc. */
 synth: 0x4fa0  __memzero(priv+0x274, 60);
        0x4fb0  priv+0x284 = 1 ; priv+0x288 = 1        /* nsect = 0x01 */
        0x4fbc  priv+0x28c = 0x14                      /* lbam  = 0x14 */
        0x4fc8  priv+0x290 = 0xeb                      /* lbah  = 0xeb */
        0x4fc0  priv+0x298 = 0x50 ; priv+0x2a0 = 0x50  /* DRDY-only status */
```

So, per pass:

* **Normal case (`priv+0x220 ∉ {0,5}`)** the driver posts FE opcode `0x08` and then classifies
  whatever the FE reply left in the register file. `sata_mt85xx_tf_read` (`.text+0x5f50`)
  copies the low byte of each ioaddr register (`ap+0x24` error, `+0x2c` nsect, `+0x30` lbal,
  `+0x34` lbam, `+0x38` lbah, `+0x3c` device) into the taskfile, i.e. **the model's a-window
  writes at the lbam/lbah slots are what classify reads.** ⇒ **the model fully controls the
  class, per pass.** C97 line 288 `class=3` is proof the model was returning `lbam=0x14,
  lbah=0xeb` at that moment (id-validity-check.md §2).
* **Degenerate case (`priv+0x220 ∈ {0,5}`)** the driver **does not talk to the FE at all** and
  fabricates `nsect=0x01, lbam=0x14, lbah=0xeb, status=0x50` at `priv+0x280`. That hard-codes
  **class=3** no matter what the model does. A run whose softreset frame is suspiciously fast
  and always `class=3` while the FE is silent is this branch.
* **`ata_eh_reset` re-classifies every pass too** — it is handed `classify = nr_unknown` (the
  number of enabled devices whose `dev->class == 0`), and the driver's softreset classifies
  *inside itself* on every call, so the `class=N` in each frame is a fresh measurement, never a
  cached value.

**Why the class matters downstream:** `ata_dev_read_id`'s dispatch is on `*p_class`:
class 3 → `tf.command = 0xa1` (`.text+0x3d6c`, `mvn r3,#94`); class 1 or 7 →
`tf.command = 0xec` (`.text+0x3c14`, `mvn r3,#19`); class 0/4/6/8 → `unsupported class` +
`-ENODEV` (`.text+0x3bf0`). A model that mis-signatures the device therefore changes **which
IDENTIFY lands on the wire** (and the validity ladder that judges the reply:
`id-validity-check.md` §1.1 — class 3 tests only `id[0]` bit 15; class 1 additionally accepts
`0x844a`/`0x848a`/CFA).

---

## 4. Give-up, disable, and success — what each looks like

### 4.1 Reset gives up (C94/C95)

* The 4th softreset attempt fails → `ata_eh_reset` returns non-zero → `ata_eh_recover` prints
  **`ata1: reset failed, giving up`** (`.text+0x103c0`, dev form; `.text+0x110c0` link form).
* The invocation then returns to `ata_scsi_error`, which prints **`ata1: EH complete`**.
* C94/C95: lines **306** and **326** are the two `reset failed, giving up`; **327** is
  `EH complete`. The second one (326) is the *second EH invocation* (a new scsi EH pass for the
  same probe command), which is why its 4 attempts carry the `soft resetting link` banners
  (311/315/319/323) that the quiet first invocation did not.

### 4.2 Device disabled

`ata_dev_disable` (`.text+0xd9c0`):

```c
if (dev->class ∉ {1,3,5,7}) return;                    /* 0xd9c8..0xd9e0 */
if (ap->msg_enable & 1) printk("%sata%u.%02u: disabled\n");   /* 0xda34, string .rodata.str1.4+0x2078 */
ata_down_xfermask_limit(dev, 0x80000004 /*ATA_DNXFER_QUIET|…*/);
dev->class++;                                          /* 3 → 4 == ATA_DEV_ATAPI_UNSUP */
ata_ering_clear(&dev->ering);
```

It is reached from exactly one site: `.text+0x10c18 → 0x10fec`, guarded by
`dev->class ∈ {1,3,5,7} && ehc->tries[devno] == 0`. Because a failed `ata_dev_read_id`
always leaves `dev->class == 0` (`.text+0x108d4`), **the invalid-type and timeout verdicts never
reach it**; it is reachable from the post-configure paths (`TEST_UNIT_READY` failure at
`.text+0x10eb4`, which sets `rc = -EIO` without zeroing the class). After disabling, if the
physical link is still online the device is queued for a fresh probe
(`ata_eh_schedule_probe`, `.text+0x1100c`) and `tries[devno]` is **reset to 3** plus the
per-device internal-command-timeout ladder is zeroed (`.text+0x1102c..0x1103c`) — i.e. the next
probe's IDENTIFY gets a fresh 5 s window, not the escalated 30 s. If the link is offline the
device is detached (`ata_eh_detach_dev`, `.text+0x11078`).

### 4.3 Success (what a landed IDENTIFY looks like)

Inside the same pass loop (`nr_failed` stays 0 for that dev):

```
ata1.00: ATAPI: SONY    BDPSACDEMUL, 1.00, max UDMA/33      /* ata_dev_configure, .text+0x4f6c;
                                                              gated on ATA_EHI_PRINTINFO + ATA_MSG_DRV */
ata1.00: configured for UDMA/33                             /* ata_do_set_mode, .text+0x6538 */
ata1: EH complete                                           /* ata_scsi_error, .text+0x11a98 */
```

**No further `[IDE]<prereset>`/`<softreset>` frame appears** — the loop falls through to
`ata_set_mode`/`ata_dev_enable_pm` and returns. So a late pass landing cleanly looks like:
one extra ~260 ms frame whose verdict line is `ATAPI:` instead of `failed to IDENTIFY`, then the
two configure lines and one `EH complete`. It does **not** restart EH and does **not** re-run a
reset beyond the frame it was already in. (`ATAPI:` can legitimately be missing if
`ATA_EHI_PRINTINFO` is clear — `configured for` + `EH complete` still means pass; see
`id-validity-check.md` §6.)

Expect post-configure mailbox traffic (`SET FEATURES 0xef` xfer-mode qcs); their failures append
`" (device error ignored)"` to `configured for` rather than failing the probe.

---

## 5. The C99 interpretation guide (one paragraph + the five signatures)

**Given the corrected FE message protocol, expect exactly one frame and no recovery at all**: a
single `[IDE]<sata_mt85xx_prereset>ch:0, deadline:0x… start/end`, a single
`[IDE]<sata_mt85xx_softreset>ch:0 start` / `… end, class=3`, then `ata1.00: ATAPI:
SONY    BDPSACDEMUL, 1.00, max UDMA/33`, `ata1.00: configured for UDMA/33`, `ata1: EH
complete` — with `failed to IDENTIFY`, `unsupported CDB len`, `qc timeout`, `soft resetting
link`, `reset failed` **all absent**, and only **one** `deadline:0x…` value in the whole probe.
Read the UART in this order: **(a)** count `prereset` frames — 1 = clean
probe, ≥2 = the payload or the verdict is still wrong and libata is re-trying, and the count is
itself a diagnosis (frame *k*'s verdict line names the defect); **(b)** for each frame read only
the verdict line — `qc timeout (cmd 0xa1)` + `err_mask=0x4` = the command never completed
(HSM/state-machine), `err_mask=0x0` + `device reports invalid type` = the 512 bytes never were
the model's table (`id-validity-check.md` §5), `unsupported CDB len` = the payload arrived but
`id[0] & 3 ∉ {0,1}` (also stale bytes), `link is slow to respond` / `SRST failed (errno=-16)` =
the status synthesiser was parked in BSY (`priv+0x220 ∈ {4,1}`), `link online but N devices
misclassified` = the signature bytes themselves are junk; **(c)** require `ata1: EH complete` —
its absence means EH never returned, so the last frame's IDENTIFY hung rather than failed (in
C97/C98/C99 the third frame has no verdict at all and no `EH complete`, so the run cannot be
scored as anything but "still in flight"); **(d)** use the deadline deltas to separate a fast
verdict (~260 ms ⇒ the FE answered and libata rejected the payload) from a deadline burn
(seconds ⇒ BSY).

**The five partial-fix signatures, in order of likelihood:**

| UART | meaning | fix direction |
|---|---|---|
| 1 frame, `softreset end, class=3`, then **silence**, no `EH complete` | IDENTIFY issued but the qc never completed (and no `qc timeout` inside the capture window) — the issue/drain handshake blocked | FE reply ordering (`priv+0x48`/`priv+0x54` arming vs. message drain) |
| 1 frame, `qc timeout (cmd 0xa1)`, `failed to IDENTIFY (I/O error, err_mask=0x4)` | command posted, no completion inside 5 s | same class, with the HSM never reaching DRQ |
| 2-3 frames, `err_mask=0x0`, `device reports invalid type` | data arrived, but stale bounce buffer (payload dropped) | `priv+0x54` length 0 or direction not armed |
| 1-2 frames, `unsupported CDB len` | payload arrived with `id[0] & 3 ∈ {2,3}` while bit 15 was set — also stale bytes, differing between passes | same as above; then the `id-validity-check.md` §3.3 word table |
| 1 frame, `link online but N devices misclassified, retrying` | the classify saw a signature that is neither ATA nor ATAPI | signature bytes at the a-window lbam/lbah slots |

A **fully working** fix removes the `[IDE]<sata_mt85xx_prereset>` after the first one; any run
that still shows a second frame is a partial fix regardless of which verdict line it carries.

---

## 6. Certainty ledger

**DECODED (instruction level):** the three-level structure and every branch cited above; the
attempt budget being *counted from* `ata_eh_reset_timeouts` (4); `tries[]` init 1-vs-3 on
`link-><+0x10> & 0x20` and its decrement site; the `-EINVAL/-ENODEV` "cap at 1" clamp
(`0x10f28/0x10f2c`) and the `-EIO` "tries == 1 → down_spd_limit/down_xfermask_limit" path; the
`tries == 0 → ata_dev_disable` site and its `class ∈ {1,3,5,7}` guard; `dev->class = 0` being
stored on both failure paths; the disable→`schedule_probe`→`tries = 3` + 24-byte cmd-timeout
ladder reset; `ata_dev_disable`'s guard, message and `class++`; the retry-print gate
(`jiffies < deadline`) and the `try == max_tries → give up` test; the banner gate
(`ATA_EHI_QUIET`); `EH complete` being ungated; `ata_dev_classify`'s four constants and the
`class 3 → 0xa1 / class 1|7 → 0xec` dispatch; `sata_mt85xx_softreset`'s `priv+0x8`/`priv+0x220`
dispatch, its `0x08` FE opcode, its `0x4eb4` classify call and the synthesized
`{1, 1, 0x14, 0xeb, …, 0x50}` block at `priv+0x280` (slot→register *labels* are INFERRED from
position; the values and the store order are DECODED); `sata_mt85xx_tf_read`'s per-register byte
sources. **Cross-checked numerically:** the 5.18 s and 70.2 s deadline deltas in C94/C95
reproduce `{5000}` and `{10000+10000+10000+35000+5000}` exactly.

**INFERRED (labelled, not closed by a single instruction):** the C field names `tries[]`,
`classes[]`, `i.action`, `i.flags`, `i.probe_mask`, `ATA_EH_SOFTRESET = 2`,
`ATA_EH_HARDRESET = 4`, `ATA_EHI_QUIET = 8`, `link->flags` bits 2/4/5/6, `dev-><+0x30>`; the
source-level shape of `ata_eh_recover`'s `retry:` label. Field *offsets* are decoded
(`eh_context.i` at `link+0x98` — proven by `ata_eh_done` `.text+0xdd04` `add r2,r0,#152` and
`ata_eh_about_to_do`; `i.action` at `link+0xa4`; `i.flags` at `link+0xb0`; `i.probe_mask` at
`link+0xb4`; `tries[]` at `link+0x10c`; cmd-timeout ladder at `link+0x114`; `classes[]` at
`link+0x144`).

**Open, and worth an instrumented run if it is ever disputed:**
1. Why the EINVAL path loops without ever disabling (§1.2 trap). Decoded behaviour says the
   `tries == 0` test is unreachable after a failed READ_ID because the class was already zeroed;
   the practical bound becomes a reset failure, a hang, or the platform. Predicting "N frames
   then stop" from `tries` alone is therefore **not** valid in the EINVAL case — C97/C98/C99 all
   stop at three because the third frame hung, not because a quota expired.
2. What the 3rd C99 frame is actually waiting on. No `qc timeout`, no verdict, no
   `EH complete`: either the qc never completed inside the captured window, or the issue path
   blocked (driver `qc_issu_task`/mailbox semaphore). Discriminator: a longer capture — a
   `qc timeout (cmd 0xa1)` ≤5 s later means "issued, never completed"; continued silence means
   "blocked before/inside issue".

---

## 7. Instruction-site index (everything claimed above)

| claim | site |
|---|---|
| `ata_scsi_error`: `EH complete` (ungated), `EH pending after %d tries` (%d = 5) | `.text+0x11a98`, `.text+0x11ad0..0x11ae0` |
| `ata_eh_recover`: prologue + `tries[]` init 3/1 | `.text+0x100fc..0x10220` |
| `retry:` label, reset-loop entry test `action & 6` | `.text+0x10244`, `.text+0x10320` |
| `classify = nr devs with class == 0` | `.text+0x10348..0x10360` |
| `ata_eh_reset` call + `reset failed, giving up` (dev) | `.text+0x10384`, `.text+0x103c0` |
| `reset failed, giving up` (link form) | `.text+0x110c0` |
| `nr_failed = 0` per pass | `.text+0x1074c` |
| `ata_dev_revalidate` / `ata_dev_read_id` calls | `.text+0x107e8` / `.text+0x108bc` |
| `ehc->classes[devno] = dev->class; dev->class = 0` | `.text+0x108d0..0x108d8` |
| failure handler: `nr_failed++`, `tries--`, rc dispatch | `.text+0x10b9c..0x10be8` |
| `-ENODEV` → `probe_mask \|= 1<<devno` | `.text+0x10f04..0x10f14` |
| `-EINVAL` → `tries = min(tries,1)` | `.text+0x10f18..0x10f30` |
| `-EIO` with `tries == 1` → `sata_down_spd_limit` / `ata_down_xfermask_limit` | `.text+0x10ec4..0x10efc` |
| class ∈ {1,3,5,7} && `tries == 0` → disable; else `action \|= 6` | `.text+0x10bec..0x10c24` |
| `nr_failed != 0 → retry` | `.text+0x10c50..0x10c5c` |
| disable → `schedule_probe` / `detach`; `tries = 3`; `memzero(…24)` | `.text+0x10fec..0x11040` |
| `ata_dev_disable`: class guard, message, `class++`, ering clear | `.text+0xd9c0..0xda3c` |
| `ata_eh_reset`: verbose gate, attempt count, action→fn-pointer masking | `.text+0xf0ec`, `0xf0f8..0xf124`, `0xf12c..0xf140` |
| `ata_eh_about_to_do(link,NULL,6)`, `bic action,#6`, `orr if hardreset` | `.text+0xf1b4`, `0xf20c..0xf224` |
| per-attempt deadline from the table | `.text+0xf3a8..0xf3c4` |
| `prereset failed (errno=%d)` | `.text+0xf2c0` |
| `%s resetting link` banner (verbose-gated) / `hard resetting link` | `.text+0xf420`, `0xf4ec` |
| `reset failed (errno=%d), retrying in %u secs` (only if time left) | `.text+0xf9f0..0xfa70` |
| `try == max_tries → give up` | `.text+0xfa7c..0xfa84` |
| `link online but %d devices misclassified, retrying` | `.text+0xf83c..0xf854` |
| `ata_dev_classify` constants 0xeb14 / 0x9669 / 0xc33c | `.text+0x328..0x360` |
| `class 3 → 0xa1`, `class 1|7 → 0xec`, `unsupported class` | `.text+0x3d6c`, `.text+0x3c14`, `.text+0x3bf0` |
| driver softreset mode-1 dispatch, FE opcode 8, classify, synthesized signature | `sata .text+0x4b18..0x4eec`, `0x4f44..0x4fa0`, `0x4fb0..0x4fe0` |
| driver `tf_read` per-register byte sources | `sata .text+0x5f50..0x602c` |
