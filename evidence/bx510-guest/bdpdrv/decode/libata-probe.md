# libata side of the `ata1.00` probe: hook order, timeouts, and the source of every observed line

Decode of `/tmp/bdpdrv/libata.ko` (2.6.35 ARM, **not stripped** — 885 symbols), cross-read
against `/tmp/bdpdrv/sata_mt85xx_mod.ko` (the SFF driver whose `ata_port_operations`
table the port actually runs) and against the C94/C95 UART logs
(`bdpdrv-runC94.uart.log`, `bdpdrv-runC95.uart.log`, lines 284-327).

This answers the *libata-side* questions only. The FE-mailbox recipe itself is
`fe-ata-cmd.md`; the driver's command/reply decode is `fe-ata-cmd.md` + `sata-fw-load.md`.

**Build identity (DECODED, hard evidence of the source tree):** `libata.ko`'s `.rodata.str1.4`
carries the `__FILE__` strings
`/home/aokino/MSB8G/msb8g_BX_R_0257/mtk/BDP_Linux_8560/linux-2.6.35/drivers/ata/libata-eh.c`
and `…/libata-core.c` (`.rodata.str1.4+0x1fec`, `+0x8`), so the source is
**Linux 2.6.35, MTK 8560 BDP tree (BX_R_0257)**. Every structural claim below is read out of
the instructions, not out of a kernel tree (none available offline); claims that could only
come from memory are labelled INFERRED.

**Address convention.** All `libata.ko` addresses are **section-relative**
(`.text+0x…`, `.rodata+0x…`, `.rodata.str1.4+0x…`). `sata_mt85xx_mod.ko` likewise
(`.text+0x…`, `.data+0x…`). `strings -t x` file offsets differ from `.rodata.str1.4`
section offsets by `+0x18ea0` (`'qc timeout'` is file `0x191f4` = section `+0x354`).

Reproduce any site with:

```
objdump -d -r -j .text /tmp/bdpdrv/libata.ko | sed -n '/<ata_wait_ready>:/,/^$/p'
```

---

## 0. Bottom line (five facts the C96 model turns on)

1. **The probe does not run through `ata_bus_probe`.** The mt85xx port inherits
   `ata_sff_port_ops`, so `ap->ops->error_handler` is non-NULL, and
   `async_port_probe` takes the *EH* branch (set `ATA_PFLAG_LOADING`, clear
   `ATA_PFLAG_INITIALIZING` — bit positions decoded at `.text+0x5e40..0x5e50`, names from
   libata's enum; `ata_port_schedule_eh`, `ata_port_wait_eh`).
   The first reset+classify therefore happens inside `ata_eh_reset` → the driver's
   `prereset`/`softreset`, exactly as the C95 log shows
   (`[IDE]<sata_mt85xx_prereset>` before any banner).
2. **There is no hardreset hook on this port** (driver's `.data` ops table leaves slot
   `0x40` empty; nothing in the `ata_sff_port_ops` → `ata_base_port_ops` chain fills it).
   Every `forcing hardreset` message is therefore *inert*: `ata_eh_reset` can only ever
   retry `softreset`. There is no COMRESET on `ata1`, ever.
3. **The ~30 s knob is not one knob.** `qc timeout (cmd 0xa1)` is the
   `ata_exec_internal_sg` completion wait, whose length comes from
   `ata_internal_cmd_timeout(dev, 0xa1)` out of the IDENTIFY entry of
   `ata_eh_cmd_timeout_table` = **{5000, 10000, 30000, ∞} ms, escalating per attempt**.
   The SRST loop's timing comes from a *different* table,
   `ata_eh_reset_timeouts` = **{10000, 10000, 35000, 5000, ∞} ms → 4 attempts**, which is
   exactly the 4 `SRST failed` lines per EH cycle in the log.
4. **`errno=-16` (`-EBUSY`) is `ata_wait_ready()` running out its deadline**, not a bus
   error: `ata_sff_check_ready()` returns `0` ("still busy") for as long as the status byte
   has bit `0x80` set (and returns `-ENODEV` only for `0xff`). In mailbox mode that byte is
   **synthesised by the driver**, `sata_mt85xx_check_status`, and the only states that
   synthesise BSY are `priv+0x220 ∈ {4,1} → 0xd0`. So `-EBUSY` ⇔ `priv+0x220` parked in
   4 or 1. This is the one state the C96 model must never leave behind.
5. **`HZ = 1000`** (1 jiffy = 1 ms), proven twice: (a) the driver's own log prints its
   deadline (`deadline:0xfffbc336` = −278 514), which is only consistent with
   `jiffies ≈ −288 514` a few seconds after boot when `INITIAL_JIFFIES = −300·HZ`
   (HZ=1000 → −300 000; HZ=100 would need jiffies < −30 000, impossible); (b) the
   `ata_wait_ready` warning gate (below) reproduces the log's 3 warned + 1 silent attempt
   only at HZ=1000.

---

## 1. The post-activate probe sequence, in the order this port executes it

`ata_port_operations` layout, recovered from `ata_finalize_port_ops` (`.text+0xadc`):
58 pointer slots, struct size `0xe8`, `inherits` at `0xe8`; the loop copies each NULL
slot from the `inherits` chain, then NULLs any slot holding an `ERR_PTR`
(`cmn r2,#4096; strhi`) and clears `inherits`. Slot offsets used below are confirmed
against both tables: `ata_sff_port_ops` = `.rodata+0xb90` (relocations at `0xb98`→`qc_prep`
+0x08, `0xbc8`→`prereset` +0x38, `0xbcc`→`softreset` +0x3c, `0xbe8`→`error_handler` +0x58,
`0xc20`→`sff_dev_select` +0x90, `0xc28`→`sff_check_status` +0x98, …) and the driver's own
table at `sata_mt85xx_mod.ko .data+0x138` (relocations `0x1c8`→`dev_select` = +0x90,
`0x1d0`→`check_status` = +0x98, `0x1d4`→`check_altstatus` = +0x9c, `0x220`→`inherits` =
`ata_sff_port_ops` = +0xe8).

| # | step | site | notes |
|---|---|---|---|
| 1 | `ata_host_register` → async probe | `async_port_probe` `.text+0x5dc4` | |
| 2 | if `!(ap->host->flags & ATA_HOST_PARALLEL_SCAN) && ap->port_no != 0` → `async_synchronize_cookie` | `.text+0x5de8..0x5eb4` | serialises port probes |
| 3 | **`ap->ops->error_handler != NULL`** (slot `0x58`; = `ata_sff_error_handler`, inherited) → EH branch: `pflags &= ~ATA_PFLAG_INITIALIZING(1<<7)`, `pflags \|= ATA_PFLAG_LOADING(1<<4)`, `ata_port_schedule_eh`, `ata_port_wait_eh` | `.text+0x5df4..0x5e8c` (`ata_port_schedule_eh` reloc at `0x5e68`) | the *only* branch taken here; `ata_bus_probe` (`.text+0x5a64`) is dead code for this driver |
| 4 | `ata_scsi_error` → `ata_eh_recover` (`.text+0x100fc`) → **`ata_eh_reset`** (`.text+0xf090`) | | |
| 4a | `ap->ops->prereset` = `sata_mt85xx_prereset` (`sata .text+0x5124`) | mode-1 path `.text+0x51a4` | needs `priv+0x220 ∉ {0,5}` to post FE cmd `0xf7`; then `ata_sff_wait_ready` (libata `.text+0x1470c`) |
| 4b | `ap->ops->hardreset` = **NULL** | driver table slot `0x40` empty | never a COMRESET |
| 4c | `ap->ops->softreset` = `sata_mt85xx_softreset` (`sata .text+0x4b18`) | mode-1 path `.text+0x4f44` | posts FE cmd `0x08` (or loads the `EB140101` signature block at `priv+0x280` when `0x220 ∈ {0,5}`), then `ata_sff_wait_after_reset(link, 1, deadline)` (libata `.text+0x14718`), then `ata_sff_dev_classify(&link->device[0], 1, &err)` (libata `.text+0x12da4`) |
| 4d | `ap->ops->postreset` = `sata_mt85xx_postreset` (`sata .text+0x3568`) → `ata_std_postreset` | | |
| 5 | for each dev with class in {1,3,5,7}: **`ata_dev_read_id`** (`.text+0x3b54`), called from `ata_eh_recover` at `.text+0x108bc` (the only live caller; the other caller is `ata_bus_probe` `.text+0x5bf8`, which this port never reaches, and `ata_dev_reread_id` `.text+0x40f0`) | C95: `class=3` → **ATAPI** (driver's `softreset` printed `class=3`) | |
| 6 | `ata_exec_internal_sg` (`.text+0x323c`): tag `ATA_TAG_INTERNAL=31`, `qc->nbytes=512`, `ata_qc_issue`, `wait_for_completion_timeout` | | see §3 |
| 7 | success → `ata_dev_configure` (`.text+0x4138`) prints `ATAPI: …`; then `ata_do_set_mode` (`.text+0x5eec`) prints `configured for …` | | never reached in C94/C95 |

What is **not** in the sequence, and why it matters for modelling:

* **No `sata_link_resume`, no SError reads.** `sata_scr_valid()` is false for this port:
  the driver installs no `scr_read`/`scr_write` (nothing at slots `0xd0..0xdc` in its
  `.data+0x138` table) and neither does `ata_sff_port_ops` (`.rodata+0xb90`: relocations
  only at the slots listed above) nor `ata_base_port_ops` (`.rodata+0x754`: only
  `prereset` +0x38, `postreset` +0x44, `error_handler` +0x58). `ata_eh_reset`'s
  `sata_scr_read` calls (`.text+0xf5f8`, `0xf888`) and `sata_down_spd_limit` calls
  (`0xfa90`, `0xfaa8`, `0xfb1c`) are all guarded and return `-EOPNOTSUPP`. Independently,
  the driver's mode-1 `prereset` skips `ata_std_prereset` entirely (it only calls it on the
  mode-0 path, `sata .text+0x5168`), which is why C95 shows **no**
  `failed to resume link for reset (errno=…)` line — that string exists only inside
  `ata_std_prereset` (`.rodata.str1.4+0x1128`).
* **No `ata_sff_softreset` / `ata_sff_prereset` in the call graph.** The strings
  `SRST failed (errno=%d)` and `device not ready (errno=%d), forcing hardreset` *also exist
  inside `sata_mt85xx_mod.ko`* (its own `.rodata.str1.4`): `sata_mt85xx_prereset` and
  `sata_mt85xx_softreset` are **vendored copies** of the libata-sff functions with the mode-1
  FE path spliced in. The log's `[IDE]<sata_mt85xx_prereset>` / `<sata_mt85xx_softreset>`
  brackets prove which copy emitted them. `libata.ko` contains the same two strings
  (`.rodata.str1.4+0x2d70`, `+0x2d24`) in `ata_sff_prereset` (`.text+0x14a48`) /
  `ata_sff_softreset` (`.text+0x14850`) — those are **not** reached by this port.

### 1.1 Timeouts that apply, with values from the `.ko` literal pools

| constant | value | site | applies to |
|---|---|---|---|
| `ata_internal_cmd_timeout` default | **5000 ms** | `.text+0xd120` (`ldr r0,=0x1388`) | any cmd not in the table |
| `ata_eh_cmd_timeout_table` entry 0 | `{0xec, 0xa1, 0}` → **`{5000, 10000, 30000, ULONG_MAX}`** | table `.rodata+0xa94`…; command bytes `.data+0x238` = `ec a1 00 00`; timeouts `.rodata+0xb30` = `1388 2710 7530 ffffffff` | **IDENTIFY DEVICE / IDENTIFY PACKET DEVICE** (0xa1 = our case) |
| entry 1 | `{0xf8, 0x27}` → `{5000,10000,∞}` | `.data+0x23c`, `.rodata+0xb40` | READ NATIVE MAX (EXT) |
| entry 2 | `{0xf9, 0x37}` → `{5000,10000,∞}` | `.data+0x240`, `.rodata+0xb40` | SET MAX (EXT) |
| entry 3 | `{0xef}` → `{5000,10000,∞}` | `.data+0x244`, `.rodata+0xb40` | SET FEATURES |
| entry 4 | `{0x91}` → `{5000,10000,∞}` | `.data+0x248`, `.rodata+0xb40` | INIT DEV PARAMS |
| entry 5 | `{0xe7, 0xea}` → `{15000,15000,30000,∞}` | `.data+0x24c`, `.rodata+0xb4c` | FLUSH (EXT) |
| `ata_probe_timeout` (module param, `.bss+0x10`, default 0) | if set, **overrides** the table with `param × 1000` | `.text+0x3514..0x3530` | — |
| `ata_eh_identify_timeouts` | `{5000, 10000, 30000, ULONG_MAX}` | `.rodata+0xb30` | as above |
| `ata_eh_reset_timeouts` | `{10000, 10000, 35000, 5000, ULONG_MAX}` → **4 attempts** | `.rodata+0xb1c` (loaded at `.text+0xff18`, first element inlined at `.text+0xff20` = `0x2710`) | SRST/COMRESET deadline in `ata_eh_reset` |
| `ATA_WAIT_AFTER_RESET` | **150 ms** (`msleep(150)`) | `ata_sff_wait_after_reset` `.text+0x14724` | post-SRST settle before the first status poll |
| `ata_wait_ready` poll | `msleep(50)` | `.text+0x6bec` (`mov r0,#50`) | status poll cadence |
| `ata_wait_ready` warn deadline | `start + 5000 jiffies` = **5 s** | `.text+0x6bac..0x6bbc` (`add r9,r9,#4992; add r9,r9,#8`) | warning gate |
| `ata_wait_ready` warn gate #2 | warn only if **> 3000 jiffies (3 s) of deadline left** | `.text+0x6c48` (`ldr r1,=0xbb8; cmp r2,r1`) | see §2 |
| `ata_wait_ready` nodev deadline | `msecs_to_jiffies(2000)` with `ATA_HOST_PARALLEL_SCAN`, else `msecs_to_jiffies(800)` | `.text+0x6b88`, `.text+0x6c98` (`mov r0,#800`) | `-ENODEV` retry window while the link looks online |
| `ata_sff_busy_sleep` part 1 | 300 × `udelay(10)` = 3 ms BSY budget before the 1st `msleep` | `.text+0x12f18..0x12f58`, const `0x00a3d702` | not on the pre-reset path |
| `ata_sff_busy_sleep` warnings | `port is slow to respond (%lu secs, Status 0x%x)` `.rodata.str1.4+0x2b14`, `port is slow to respond … (Status 0x%x)` `+0x2b54` | `.text+0x1301c`, `0x13090` | **absent from the C94/C95 logs** — see §2 |

The escalation counter for the command table is per (device, table entry): the u32 at
`link + 0x114 + 4*(6*devno + i)` (`ata_internal_cmd_timeout` `.text+0xd0ec..0xd108`) is the
attempt index into `t->timeouts[]`; `ata_internal_cmd_timed_out` (`.text+0xd130`) increments
it but refuses to store the value whose next entry is `ULONG_MAX` (`.text+0xd190..0xd198`,
`cmn r1,#1`). So the ladder is **5 s → 10 s → 30 s → 30 s → …** (index saturates at 2), and
`ULONG_MAX` is never actually waited on. *The exact C identifier of that field is INFERRED*
(it lives in `link->eh_context`; the layout `[ATA_MAX_DEVICES][6]` is DECODED from the
`6*devno + i` scaling). **First-ever IDENTIFY on a fresh boot therefore waits 5 s**, not
30 s; a 30 s `qc timeout` means the counter had already been bumped (2nd/3rd EH attempt).

---

## 2. What produces each observed line, exactly

Producer map from `.rodata.str1.4` → owning function (every `R_ARM_ABS32 .rodata.str1.4`
pool word resolved to text):

| observed line (C94/C95) | format string | producer | trigger condition |
|---|---|---|---|
| `ata1.00: qc timeout (cmd 0xa1)` | `+0x354` `%sata%u.%02u: qc timeout (cmd 0x%x)` | **`ata_exec_internal_sg`** `.text+0x323c`, printk at `.text+0x3760` | `wait_for_completion_timeout` returned 0 **and** the internal qc was flagged timed-out (`tst` on `ap+0x1e44` bit 8 at `.text+0x35b0`) |
| `ata1.00: failed to IDENTIFY (I/O error, err_mask=0x4)` | `+0x4fc` | **`ata_dev_read_id`** `.text+0x3b54` | `err_mask != 0`; `0x4` = `AC_ERR_TIMEOUT` (the mask text `I/O error` is selected for that bit) |
| `ata1: link is slow to respond, please be patient (ready=0)` | `+0x1094` (link form) / `+0x104c` (dev form) | **`ata_wait_ready`** `.text+0x6b54`, printk `.text+0x6c90`/`0x6cec` | `now > start+5000 jiffies` **and** `deadline - now > 3000 jiffies`; `ready=%d` is the last `check_ready()` return = `0` |
| `ata1: device not ready (errno=-16), forcing hardreset` | `+0x2db0` / `+0x2d70` | `ata_sff_prereset` in libata `.text+0x14a48` — **here emitted by the driver's copy** `sata_mt85xx_prereset` (`sata .text+0x5244` / `0x5298`) | `rc = ata_sff_wait_ready(link, deadline)` non-zero and `!= -ENODEV` (`.text+0x51fc..0x5208`), then `link+0xa4 \|= 4` (`ATA_EH_HARDRESET`) at `.text+0x5248` |
| `ata1: SRST failed (errno=-16)` | `+0x2d4c` / `+0x2d24` | `ata_sff_softreset` in libata `.text+0x14850` — **here the driver's copy** `sata_mt85xx_softreset` (`sata .text+0x4e84` / `0x50b0`) | `ata_sff_wait_after_reset` returned non-zero and not `-ENODEV` (`.text+0x4e3c..0x4e48`) |
| `ata1: soft resetting link` | `+0x2528` / `+0x2500` | **`ata_eh_reset`** `.text+0xf090` (banner printk `.text+0xf428` for `%s resetting link`, `.text+0xf4f0` for `hard resetting link`) | banner is gated (`.text+0xf3f0..0xf428` reads a state field and can skip the print) — the *initial* probe cycle prints no banner, later error-driven cycles do, matching C95 (no banner before the first `prereset`, banners from line 311 on) |
| `ata1: reset failed, giving up` | `+0x28d0` / `+0x28f8` | **`ata_eh_recover`** `.text+0x100fc` | `ata_eh_reset` exhausted `ata_eh_reset_timeouts` |
| `ata1: EH complete` | `+0x2a54` | **`ata_scsi_error`** `.text+0x11270` | EH finished |
| `ata1: port is slow to respond, please be patient (Status 0x%x)` | `+0x2b54` | `ata_sff_busy_sleep` `.text+0x12f04` | **never appears in C94/C95** → no pre-reset `busy_sleep`; the waits were all `ata_wait_ready` |

### 2.1 The `-EBUSY` mechanism (the part that constrains the model)

`ata_wait_ready` (`.text+0x6b54`, args `link, deadline, check_ready`), decoded:

```
nodev_deadline = now + (host->flags & ATA_HOST_PARALLEL_SCAN ? 2 s : 800 ms)   /* 0x6b88 / 0x6c98 */
WARN_ON(link == link->ap->slave_link)                                          /* 0x6cf8 */
if (nodev_deadline > deadline) nodev_deadline = deadline
warn_deadline  = start + 5000 jiffies                                          /* 5 s @ HZ=1000 */
for (;;) {
        now = jiffies; rc = check_ready(link);
        if (rc > 0) return 0;                 /* READY */
        if (rc == -ENODEV) {                  /* 0xff seen */
                if (ata_link_online(link)) { /* keep waiting until nodev_deadline */ }
                else if (!(ap->flags & ATA_FLAG_SLAVE_POSS) ||
                         ata_link_offline(link)) return -ENODEV;
        }
        if (rc) return rc;                    /* other negative */
        if (time_after(now, deadline)) return -EBUSY;      /* .text+0x6cd4: mvn r0,#15 */
        if (!warned && time_after(now, warn_deadline) &&
            (deadline - now) > 3000 jiffies)
                ata_link_printk(… "link is slow to respond … (ready=%d)", rc);
        msleep(50);
}
```

and `ata_sff_check_ready` (`.text+0x11d8c`) is the *only* checker on this path
(`ata_sff_wait_ready` `.text+0x1470c` is a bare tail-call to `ata_wait_ready` passing it):

```
status = link->ap->ops->sff_check_status(link->ap);   /* [ap+0x04]->[ops+0x98] -> blx */
if (!(status & ATA_BUSY /*0x80*/)) return 1;          /* ready  */
return (status == 0xff) ? -ENODEV : 0;                /* no-dev vs still-busy */
```

So, mechanically:

* `-EBUSY` ⇔ **the status byte keeps bit `0x80` (BSY) set** until the deadline expires.
  It is *not* a port-frozen error, *not* `ata_sff_busy_sleep`'s `-ENXIO`, and has nothing to
  do with the qc.
* In mailbox mode (`priv+0x8 == 1`) that byte never comes from a register read: it is
  `sata_mt85xx_check_status` (`sata .text+0x5ce8`, mode-1 branch at `.text+0x5e04`)
  mapping `priv+0x220`: `{4,1} → 0xd0`, `{2,3} → 0x58`, `{5} → 0x51`, else `→ 0x50`
  (`.text+0x5e08..0x5e40`), and it *writes that byte into `*(ap->ioaddr.status_addr)`*
  (`ldr r3,[ap+0x40]; str r4,[r3]` at `.text+0x5e44..0x5e4c`).
  `sata_mt85xx_check_altstatus` (`sata .text+0x6388`) simply calls `check_status` when
  `priv+0x8 == 1`, so status and altstatus can never disagree in this mode.
* ⇒ **`-EBUSY` ⇔ `priv+0x220 ∈ {4,1}`.** The C95 signature is that the port is *parked* in
  `0xd0`: BSY set, so *every* `ata_wait_ready` (prereset, SRST) burns its full deadline,
  while `0xff` never appears (so no `-ENODEV` shortcut).
* The alternative (`priv+0x8 == 0`, mode-0 branch `.text+0x5d28`) returns the **raw**
  register value for `priv+0x220 ∉ {1..6}` (`.text+0x5d98`), so a model that returns `0x80`
  from that register would produce the identical `-EBUSY` chain with no `0xd0` in it. Which
  of the two ran in C94/C95 cannot be settled from the log text alone; C95's own MMIO decode
  (a-window never touched) says mode 1 — see §6.

### 2.2 Why the log has exactly 3 warnings and 4 `SRST failed` per cycle

`ata_eh_reset` retries with `{10000, 10000, 35000, 5000}` ms → 4 attempts. The warning gate
needs 5 s elapsed *and* >3 s of deadline left:

| attempt | deadline | warn at t=5 s? | matches log |
|---|---|---|---|
| 1 | 10 s | yes (5 s left) | `link is slow to respond` then `SRST failed (errno=-16)` |
| 2 | 10 s | yes | same |
| 3 | 35 s | yes (30 s left) | same |
| 4 | 5 s | **no** — deadline expires at 5 s, 0 s left | `SRST failed` with no preceding warning ✓ (log line 305 / 325) |

This triple-check (warning counts, 4 attempts, HZ=1000) is the strongest cross-validation in
this decode: the tables in §1.1 are *not* guesses, they reproduce the observed UART cadence.

---

## 3. What libata needs in order to call IDENTIFY successful

`ata_dev_read_id` (`.text+0x3b54`), decoded head:

```
class = *p_class
if (ap->[0x1e44] & 0x20) → special path (.text+0x3fbc)
__memzero(&tf, 20)
tf.protocol = ATA_PROT_PIO (2)                  /* .text+0x3c20 */
tf.ctl      = ap->ctl ([ap+0x58])               /* .text+0x3c14..0x3bd0 */
tf.device   = 0xa0 (dev0) / 0xb0 (dev1)         /* .text+0x3bbc..0x3bd4 */
class == 3 (ATAPI) → 0x3d6c ; class in {1,7} → 0x3c14
tf.command  = 0xec IDENTIFY DEVICE  (class 1/7) /* .text+0x3c18 / 0x4d */
            = 0xa1 IDENTIFY PACKET  (class 3)   /* 0x3d6c */
tf.flags   |= 0x46                              /* .text+0x3c34 */
ap->ops->read_id if installed (driver: none)    /* [ops+0x28] == NULL here */
```

`ata_exec_internal_sg` (`.text+0x323c`) then:

* takes `tag = ATA_TAG_INTERNAL (31)` when `ap->ops->error_handler` is set (`.text+0x32e4..0x32f0`), stamps the
  **512-byte** PIO-in payload length into the qc (`mov r3,#512; str r3,[qc+0x48]` at `.text+0x3320`/`0x334c`;
  field *name* `qc->nbytes`/`sect_size` is INFERRED, the *value* 512 is DECODED, and `ata_dev_read_id`
  passes the `u16 id[256]` = 512-byte buffer to `ata_exec_internal`, `.text+0x3ec0`),
  `qc->complete_fn = ata_qc_complete_internal`
  (pool `0x3774`), copies the tf and issues via `ata_qc_issue` (reloc at `.text+0x34e4`);
* waits `wait_for_completion_timeout(msecs_to_jiffies(timeout))` where `timeout` is the
  argument, else `ata_probe_timeout*1000`, else `ata_internal_cmd_timeout(dev, cmd)`
  (`.text+0x3504..0x3534`, `.text+0x36e4..0x36f8`);
* on timeout: `ata_sff_flush_pio_task`, if `qc->[0x114] & 1` then `ata_port_freeze` +
  `ata_sff_hsm_move`-side error bookkeeping (`.text+0x3570..0x35a8`), `ata_qc_free`,
  `ata_internal_cmd_timed_out(dev, cmd)`, `ata_qc_complete`, and the
  `qc timeout (cmd 0x%x)` printk (`.text+0x3738..0x3760`).

So IDENTIFY is **not** a polled register exercise on this driver: it is a *completion*. The
512-byte payload must arrive and the qc must complete inside the timeout window. Concretely
the HSM must see, in this order:

1. **data available**: `status & ATA_DRQ (0x08)` with `BSY` clear → the mode-1 synthesiser's
   `0x58` (`DRDY|DSC|DRQ`) is exactly that state (`priv+0x220 ∈ {2,3}`);
2. **the transfer**: `ata_sff_hsm_move` calls `ap->ops->sff_data_xfer(dev, buf, 512, READ)`
   (reloc `[ops+0xac]`, `.text+0x135c0`) — on this driver that is `sata_mt85xx_data_xfer`,
   i.e. the FE mailbox/window path, not a FIFO read;
3. **clean end**: after the data phase a status with `BSY=0, DRQ=0, ERR=0, DF=0` — the
   mode-1 map's `0x50` (`DRDY` only), which requires `priv+0x220 ∉ {1,…,6}` (i.e. 0/≥7).
   Anything with bit 0 set (`0x51`, state 5) is `ERR` and fails the command; a stuck `0x58`
   makes the HSM want another 512 bytes and the qc never completes; a `0xd0` freezes both.

`ata_sff_hsm_move` reaches the driver's hooks for its status reads (`[ops+0x98]` at
`.text+0x13534` and `.text+0x13aec`) — it does not read the register file itself.

After a successful read, `ata_dev_read_id` validates the payload. The check that matters most for
an ATAPI device is at `.text+0x3d90..0x3dac`: with `id[0] & 0x8000` set, the value must be
**`0x848a` or `0x844a`** (the ATAPI packet-device magic the model's identify table already uses),
otherwise the device is rejected/ATAPI-downgraded before `ata_dev_configure` ever runs. The
remaining checks are the CFA/capability words `id[2]`, `id[6]`, `id[49]`, `id[83..88]`
(`.text+0x3cb8..0x3d2c`). After those:

* `ata_dev_configure` (`.text+0x4138`) prints
  `%sata%u.%02u: ATAPI: %s, %s, max %s%s%s%s` (`.rodata.str1.4+0xa4c`, pool `0x5120`) — the
  model string comes from `ata_id_c_string(id + 27 / 16)` (i.e. IDENTIFY words 27-46);
* `ata_do_set_mode` (`.text+0x5eec`) prints
  `%sata%u.%02u: configured for %s%s` (`.rodata.str1.4+0xf18`, pool `0x67c0`).

Neither line exists anywhere in C94/C95 → `ata_dev_configure` never ran → the failure is
purely "IDENTIFY never completed", exactly as the recipe assumed.

---

## 4. Which status source wins: altstatus vs status, and which `ioaddr` fields are live

`ata_finalize_port_ops` (`.text+0xadc`) only fills **NULL** slots, following `inherits`.
The mt85xx table (`sata .data+0x138`, `inherits = ata_sff_port_ops` at `+0xe8`) sets the SFF
hooks itself, so **the driver's hooks win for every SFF function-pointer call**:

| ops slot | libata default | this port's function |
|---|---|---|
| `0x90` `sff_dev_select` | `ata_sff_dev_select` `.text+0x12684` | `sata_mt85xx_dev_select` (`sata .text+0x2ecc`) |
| `0x98` `sff_check_status` | `ata_sff_check_status` `.text+0x11d44` | **`sata_mt85xx_check_status` (`.text+0x5ce8`)** |
| `0x9c` `sff_check_altstatus` | *(NULL in `ata_sff_port_ops`)* | **`sata_mt85xx_check_altstatus` (`.text+0x6388`)** |
| `0xa0` `sff_tf_load` | `ata_sff_tf_load` | `sata_mt85xx_tf_load` (shadow regs in mode 1) |
| `0xa4` `sff_tf_read` | `ata_sff_tf_read` | `sata_mt85xx_tf_read` (shadow regs in mode 1) |
| `0xa8` `sff_exec_command` | `ata_sff_exec_command` | `sata_mt85xx_exec_command` |
| `0xac` `sff_data_xfer` | `ata_sff_data_xfer` | `sata_mt85xx_data_xfer` (**the mailbox poster**, `fe-ata-cmd.md` §1) |
| `0xb0` `sff_irq_on` | `ata_sff_irq_on` | `sata_mt85xx_irq_on` |
| `0x3c` `softreset`, `0x38` `prereset`, `0x44` `postreset` | `ata_sff_*` | driver copies (see §1) |
| `0x40` `hardreset` | *(NULL in `ata_sff_port_ops`)* | **NULL — no COMRESET** |
| `0xd0..0xdc` `scr_read`/`scr_write` | *(NULL)* | **NULL — `sata_scr_valid()==0`** |

Who polls what, decoded:

* **status (slot `0x98`) — the probe/EH path.** `ata_sff_check_ready` `.text+0x11d9c`
  (`[ops+0x98]`) → used by `ata_wait_ready`, hence by *both* `ata_sff_wait_ready` calls on
  this port (driver prereset, `ata_sff_wait_after_reset`); `ata_sff_hsm_move`
  (`.text+0x13534`, `0x13aec`); `ata_sff_interrupt` (`.text+0x1431c`, `0x143e4`);
  `ata_sff_pio_task` (`.text+0x13bec`, `0x13c60`); `ata_sff_busy_sleep`
  (`.text+0x12f2c`, `0x12fb0`, `0x13060` — all `[ops+0x98]`).
* **altstatus (slot `0x9c`) — only the interrupt fast path.**
  `__ata_sff_port_intr` `.text+0x13d28..0x13d40` calls `[ops+0x9c]` **first** and only falls
  through to `[ops+0x98]` at `.text+0x13d50` when the altstatus hook is NULL; if the hook
  exists but reports `BSY` it takes the busy branch (`.text+0x13dc0`) without ever calling
  `check_status`. In mailbox mode the driver's altstatus *is* `check_status`
  (`sata .text+0x63bc`), so the two agree; but a model that special-cases one and not the
  other will wedge the IRQ path.
* **libata's own `ioaddr` dereferences are dead code on this port**, because every function
  that performs them is superseded: `ata_sff_check_status` reads `[ap+0x40]`
  (`status_addr`, `.text+0x11d44`), `ata_sff_altstatus`-alike reads `[ap+0x48]`
  (`altstatus_addr`, `.text+0x13de4`), `ata_sff_softreset` writes `[ap+0x4c]` (`ctl_addr`)
  and reads `[ap+0x58]`/`[ap+0x59]` (`ctl`/`last_ctl`) — none of these functions run here.
  The single libata function that *does* run and touches `ioaddr` directly is
  `ata_sff_wait_after_reset` (`.text+0x14718`): it reads `[ap+0x2c]` (`nsect_addr`) and
  `[ap+0x30]` (`lbal_addr`) to validate the device-1 signature
  (`.text+0x14764..0x147bc`) — **only when `devmask & 2`**. The driver's softreset passes
  `devmask = 1` (`sata .text+0x4e30`), so on `ata1` (single device) even this is skipped.

**Bottom line for the recipe rows:** in mailbox mode nothing in libata touches
`0x5c040-0x5c04c`, `0x5c800/0x5c804` or any `0xa000`-window register; the only ATA-visible
surface libata has is the *driver's* hooks + the synthesised status byte, and the driver's
`check_status` writes that byte back into `*ap->ioaddr.status_addr` on every call (which is
therefore a model-visible **write** stream during the whole probe).

---

## 5. Predicted C96 UART delta if `fe-ata-cmd.md` §5.2 is implemented, stated from the libata side

If the model answers the `0xa1` mailbox post with a real ATA completion — a `type 0x10`
reply carrying the 512-byte IDENTIFY PACKET block through the FE DRAM window, followed by
the `type 0 / byte3 == 0` reply that advances `priv+0x220` — then the `ata_exec_internal_sg`
completion arrives inside the **5 s** first-attempt window, so
`ata1.00: qc timeout (cmd 0xa1)` and `ata1.00: failed to IDENTIFY (I/O error, err_mask=0x4)`
**both vanish**; the byte that `check_status` synthesises during the data phase becomes
`0x58` (DRQ, `0x220 ∈ {2,3}`), the HSM performs exactly one 512-byte `data_xfer`, and after
`0x220` returns to 0 the synthesised byte is `0x50` (DRDY, no ERR/DF/BSY) so the qc completes
cleanly and `ata_dev_read_id` returns 0 → `ata_dev_configure` emits
`ata1.00: ATAPI: <model from id[27..46]>, <fw from id[23..26]>, max UDMA/…` and
`ata_do_set_mode` emits `ata1.00: configured for UDMA/33|UDMA/66` (whatever `id[88]`/`ata_id_xfermask`
yields for the table's `xfer_mask`), with `ata1: EH complete` still printed once (the EH
round that did the probe) and `SATA max UDMA/133` unchanged from the driver's own banner.
Everything downstream of the first `ata1.00:` line in the log **disappears wholesale**:
no `link is slow to respond … (ready=0)` (there is no wait left to be slow),
no `device not ready (errno=-16), forcing hardreset`, no `SRST failed (errno=-16)`, no
`soft resetting link`, no `reset failed, giving up`, and no second `[IDE]<sata_mt85xx_prereset>`
/ `<sata_mt85xx_softreset>` bracket after the first pair — the two bracketed pairs seen
today (lines 285-288 and 291-328) collapse to the single successful pair. The degenerate case
to guard against is a *partial* fix: if the model delivers the block but leaves `priv+0x220`
at 4 or 1 after the transfer, the timeout moves from "command never answered" to
"`0x58`/`0xd0` mishandled" and the UART shows the *same* `-16` SRST cascade with only the
first two lines changed — i.e. `state → 0` after the payload is as load-bearing as the
payload itself.

---

## 6. Certainty ledger and open items

**DECODED (instruction-level):** hook order in §1; all §1.1 table values and their pools;
the `-EBUSY` return path and its `-16`; `ata_sff_check_ready`'s BSY/`0xff` logic; the
`ata_wait_ready` warn gate and its jiffy constants; the driver's mode-1 status map and its
store into `ioaddr.status_addr`; slot numbers of every SFF hook and the `inherits` chain;
`class == 3 → 0xa1`; `qc->nbytes = 512`; the ops-table emptiness of `hardreset` and `scr_*`.

**INFERRED (consistent, not closed by one instruction):** the C identifier of the
per-(device, entry) timeout-attempt counter; the exact `ATA_EHI_*` flag that gates the
`… resetting link` banner (the *behaviour* — no banner on the initial probe cycle, banner on
error-driven cycles — matches the log); `AC_ERR_TIMEOUT` name for mask `0x4` (the value is
from the log).

**Open, and it matters for the model lane:**
1. The post-handshake MMIO capture (`bdpdrv-runC95.posthandshake.mmio.gz`, 5.22 M lines) does
   **not** cover the SRST window: it contains exactly **1** access to `0x5c804`, **0** to
   `0x5c040/44/48/4c`, **0** to any `0xa0xx` register, and its `0xc000/0xc004` traffic is the
   console byte stream (`61 74 61 31 2e 30` = `ata1.0`), not a status register. So it cannot
   confirm *which* branch of `sata_mt85xx_check_status` produced the `(ready=0)` busy status.
   A capture spanning the probe (or a one-shot instrument on `check_status`'s
   `str r4,[ap->ioaddr.status_addr]`) would close it. Until then both readings in §2.1 stay
   open: mailbox-mode `priv+0x220 ∈ {4,1}` (favoured — C95's a-window silence says mode 1) or
   mode-0 raw `0x80`.
2. `[IDE]<sata_mt85xx_softreset>ch:0 start` repeats without a matching `end` on failure, so
   the log's softreset attempt count is 4 per EH cycle only if the 4th prints before giving
   up; that matches `ata_eh_reset_timeouts`, but the 4th attempt's *deadline* is the one that
   discriminates it from a 3-attempt table — worth an instrumented re-run if the C96 delta is
   ever disputed.

---

## 7. Instruction-site index (every claim above)

| claim | site |
|---|---|
| `ata_port_operations` = 58 slots, size `0xe8`, `inherits` filled/null path | `.text+0xadc..0xba4` |
| `ata_sff_port_ops` at `.rodata+0xb90`; slot relocations +0x08/0x38/0x3c/0x44/0x58/0x90/0x98/0xa0/0xa4/0xa8/0xac/0xbc | `.rel.rodata` 0xb98…0xc4c |
| `ata_base_port_ops` at `.rodata+0x754` (prereset/postreset/error_handler only) | `.rel.rodata` 0x78c/0x798/0x7ac |
| driver ops table `.data+0x138`, `inherits` at `+0xe8` → `ata_sff_port_ops` | `sata_mt85xx_mod.ko` `.rel.data` 0x138…0x220 |
| `async_port_probe` EH-vs-`ata_bus_probe` branch on `ops->error_handler` | `.text+0x5df4..0x5e8c` |
| `ata_eh_reset` reset-timeout table load + `{soft,hard} resetting link` banner | `.text+0xff18`, `.text+0xff20`, `.text+0xf410..0xf428`, `.text+0xf4f0` |
| `ata_eh_recover` "reset failed, giving up" | `.text+0x11180` (dev form), `0x111a8` (link form) |
| `ata_scsi_error` "EH complete" | `.text+0x11b40` |
| `ata_internal_cmd_timeout` table walk + default 5000 | `.text+0xd0b0..0xd124` |
| `ata_internal_cmd_timed_out` escalation | `.text+0xd130..0xd1b0` |
| `ata_exec_internal_sg` timeout ladder + `ata_qc_issue` + completion + `qc timeout` printk | `.text+0x323c..0x3788` |
| `ata_dev_read_id` class→command map, 512-byte buffer, validation | `.text+0x3b54..0x40bc` |
| `ata_dev_configure` `ATAPI: %s, %s, max …` | `.text+0x4138`, pool `.text+0x5120` |
| `ata_do_set_mode` `configured for %s%s` | `.text+0x5eec`, pool `.text+0x67c0` |
| `ata_wait_ready` full state machine (warn gate, `-EBUSY`, nodev deadline) | `.text+0x6b54..0x6d2c` |
| `ata_sff_check_ready` (ops `0x98`, `0x80`, `0xff`) | `.text+0x11d8c..0x11dc0` |
| `ata_sff_wait_ready` = tail-call `ata_wait_ready(…, ata_sff_check_ready)` | `.text+0x1470c..0x14714` |
| `ata_sff_wait_after_reset` (150 ms, `ata_sff_wait_ready`, dev1 `ioaddr` signature probe) | `.text+0x14718..0x147e8` |
| `ata_sff_busy_sleep` (300×udelay, `port is slow to respond`) | `.text+0x12f04..0x130bc` |
| `ata_sff_softreset` (ctl writes, `SRST failed`, `ata_sff_dev_classify` calls) | `.text+0x14850..0x14a44` |
| `ata_sff_prereset` (`device not ready … forcing hardreset`) | `.text+0x14a48..0x14b20` |
| `__ata_sff_port_intr` altstatus-then-status preference | `.text+0x13d28..0x13d90` |
| `ata_sff_hsm_move` status source `[ops+0x98]`, `sff_data_xfer` call `[ops+0xac]` | `.text+0x13534`, `0x135c0`, `0x13aec` |
| driver `sata_mt85xx_check_status` mode-1 map + store to `ioaddr.status_addr` | `sata .text+0x5d1c`, `0x5e04..0x5e4c` |
| driver `sata_mt85xx_check_altstatus` = `check_status` in mode 1 | `sata .text+0x6388..0x63c0` |
| driver `sata_mt85xx_prereset` (cmd `0xf7`, `ata_sff_wait_ready`, `ATA_EH_HARDRESET`) | `sata .text+0x5124..0x52c4` |
| driver `sata_mt85xx_softreset` (cmd `0x08` / `EB140101`, `ata_sff_wait_after_reset`, `ata_sff_dev_classify`) | `sata .text+0x4b18`, `0x4f44..0x4fb4`, `0x4e2c..0x4ec4` |
| `HZ = 1000` | driver log `deadline:0xfffbc336` vs `INITIAL_JIFFIES = -300*HZ`; warn-gate cadence §2.2 |
