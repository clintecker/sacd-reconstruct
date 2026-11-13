# sacd_read.ko insmod + smoke stage — the runnable C100 stage

Date: 2026-11-13. Lane: the module between the resident bdpdrv (C99) and the real
daemon. Makes the stage runnable: the artifact, its staging budget, the exact
console contract, a guest smoke script that proves the bdpdrv hooks **without a
daemon**, the model-dependency answer, and the fire-command block.

**House rules.** **VERIFIED** = read out of an instruction, a symtab, a string
table, or a command whose output is quoted here. **INFERRED** = reasoned from a
pattern. Every claim below is re-derivable with §7.

---

## 0. Bottom line

1. **The module is not in the rootfs and never was.** `find /tmp/rootfs* -name
   "sacd_read*"` → nothing (the daemon embeds it, `sacdread-cpsa.md` §3.1). The
   only copies on the lab VM are the working trees; all three are byte-identical:
   **97,805 B, sha256 `b3d7a383e45d3bbe1a987a4a2e15ab7a68dd55e88d0319f7a0fd2e9cf0246dfa`**.
   Pulled Mac-side to `/tmp/sacdread/sacd_read.ko`, hash re-checked there.
   *VERIFIED.*
2. **Staging fits with ~274 KB to spare.** `--extra-file sacd_read.ko=…` +
   `--extra-file sacdgate=…` add **139,264 B** to the USTAR payload; the C97
   payload was 634,880 B in a 1,048,576 B `fe_test_data` partition → 774,144 B.
   *VERIFIED (size math §1.2).*
3. **The stage's hook proof is ioctl `0x40105301` (INIT) alone**, and its success
   value is **`0x68000000`** = `%d 1744830464` — positive, never 0; a `== 0`
   predicate reports a false FAIL. INIT reaches `Connect` → `i4CPSA_Inst_Create`
   → `i4CPSA_SACD_Create`/`SetCallback` and touches **no MMIO and no
   `/dev/sr0`**. *VERIFIED (§4.1).*
4. **CORRECTION to `sacdread-cpsa.md` §1 and `daemon-gate-experiments.md` gate 14:**
   `_SACDCLI_TestPhy` and `eSacdGetVersion` **are called** — from
   `CPSA_SACDCmdSetCtrl`, i.e. by the **AUTH** ioctl `0x40105302`, together with
   `vSacdDecryptEnable(TRUE)`. So AUTH is not a cheap no-hardware gate: it runs
   bdpdrv's whole SACD bring-up self-test (`/dev/sr0` `ioctl 0x8530` chain, TUR
   loop ≤ 20 s, PSP/PDM wait 5 s) and then the two register clusters.
   *VERIFIED (§3.3, §4.2).*
5. **Ordering is a safety rule, not a preference.** AUTH and UNINIT both take the
   instance handle from `u4CPSA_Inst_GetInstHandleFromCompId` (returns
   `0xFFFFFFFF` while the slot is free) and both callees **dereference it before
   validating the magic** (`bdpdrv 0x55908 ldr r2,[r0]`, `0x54b84 ldr r2,[r0]`).
   Firing either ioctl without a successful INIT **faults the guest kernel**.
   The smoke script gates AUTH/UNINIT on INIT passing. *VERIFIED (§3.2).*
6. **No new MMIO window.** The only registers the stage can touch are
   `0x70039000/4/8` and `0x70008154/0x7000815C`, all already swallowed by the
   model's 16 MiB peripheral region, with the doorbell read already answered 0.
   *VERIFIED (§4.3).*

---

## 1. The artifact and its staging budget

### 1.1 Where it is, and its identity

The task's `find /tmp/rootfs* -name "sacd_read*"` returns **nothing**: the
extracted rootfs ships no `sacd_read*` file (the daemon writes its embedded copy
to a `tmpnam()` file and insmods that — `daemon-ioctl-side.md` §3.1). A
filesystem-wide search found the working copies:

| path (lab VM) | size | sha256 |
|---|---|---|
| `/home/aftermath/sacd-verify/original/sacd_read.ko` | 97,805 | `b3d7a383…246dfa` |
| `/home/aftermath/reconstruct/sacd_read.ko` | 97,805 | `b3d7a383…246dfa` |
| `/home/aftermath/b03b08-arm/sacd_read.ko` | 97,805 | `b3d7a383…246dfa` |

`make vm-pull-file FILE=/home/aftermath/sacd-verify/original/sacd_read.ko
DEST=/tmp/sacdread` → Mac copy, `shasum -a 256` = the same digest, so the Mac
scratch copy is the artifact the daemon carries. *VERIFIED.*

`.modinfo` (strings): `license=GPL`, `author=SYM`, `depends=` (empty),
`vermagic=2.6.35 preempt mod_unload ARMv6 `, and exactly **two** parameters
(§2.2).

### 1.2 The tar staging budget

`tools/bx510_bdpdrv_stub_probe.py` builds the guest payload as a USTAR archive
(`build_tar`, `shim/<NAME>` members, mode 0755) and refuses when
`len(payload) > part["size"]`. Adding this stage's two extras:

| member | bytes | tar member (512 hdr + 512-rounded data) |
|---|---|---|
| `shim/sacd_read.ko` | 97,805 | 98,816 |
| `shim/sacdgate` (ARM helper, built §7) | 38,710 | 39,424 |
| end-of-archive | — | 1,024 |
| **added to the payload** | | **139,264** |

Against the last recognised fire (`bdpdrv-runC97.meta.json`: `payload_size`
634,880, `size` 1,048,576): **774,144 B used, 274,432 B headroom**. No partition
change, no new image. *VERIFIED (arithmetic + the recorded meta).*

---

## 2. The init sequence, as the console will show it

### 2.1 The command line

The daemon's own line is `insmod %s minor=201` (no `compid`) on its embedded
copy. For this stage, byte-identical semantics on the staged copy:

```sh
insmod /res/shim/sacd_read.ko minor=201
```

Both halves must agree with the node: `minor=201` is stored into
`sacd_read_dev.minor` **only if non-zero** (`.init.text+0x8`), else the `.data`
default `0xFF` (`MISC_DYNAMIC_MINOR`) stands and the daemon's hard-coded
`c 10 201` node points at nothing.

### 2.2 Parameters (all of them)

| param | type | default | effect |
|---|---|---|---|
| `minor` | int | **0** (`.bss+0x34`, NOBITS ⇒ 0) | 0 leaves `MISC_DYNAMIC_MINOR` (0xFF) in force; the daemon always passes 201 |
| `compid` | int | **0** (`.bss+0x24`, NOBITS ⇒ 0) | GCPU compute id 0-3 (`parm=compid:GCPU Compute ID (0-3)`); the daemon never passes it. This stage omits it too; only pass `COMPID=1..3` to escape `-EBUSY` |

There is no third parameter. *VERIFIED (modinfo strings + the two `.bss` objects).*

### 2.3 Expected success prints (UART/console)

Init prints a three-line header, the separator twice, then one line per
`kallsyms_lookup_name_diag` call (13 mandatory + 1 optional), then registers the
misc device. `%s` is the shared `__func__` token `SACDREAD`:

```
[SACDREAD] ========================================
[SACDREAD] minor = 201
[SACDREAD] compid = 0
[SACDREAD] ========================================
[SACDREAD]Symbol "i4CPSA_Inst_CPSMode_Ctrl" address is 0x........
[SACDREAD]Symbol "_IDECLI_OddRead" address is 0x........
[SACDREAD]Symbol "_i4CPSA_Inst_Decrypt" address is 0x........
[SACDREAD]Symbol "i4CPSA_Inst_SetSACDControl" address is 0x........
[SACDREAD]Symbol "u4CPSA_Inst_GetInstHandleFromCompId" address is 0x........
[SACDREAD]Symbol "i4CPSA_Inst_Connect" address is 0x........
[SACDREAD]Symbol "i4CPSA_Inst_Disconnect" address is 0x........
[SACDREAD]Symbol "vSacdDecryptEnable" address is 0x........
[SACDREAD]Symbol "_SACDCLI_TestPhy" address is 0x........
[SACDREAD]Symbol "eSacdGetVersion" address is 0x........
[SACDREAD]Symbol "_SACDCLI_FindTag" address is 0x........
[SACDREAD]Symbol "_IDECLI_OddTestUnitReadyLoop" address is 0x........
[SACDREAD]Symbol "_IDECLI_OddGetProfile" address is 0x........
[SACDREAD]Symbol "__ksymtab_disable_print" not found in /proc/allsyms!!
```

The last line is the **optional** lookup: `__ksymtab_disable_print` is in no
module of the rootfs, so `ppdisable_print` stays NULL and the "silence the CPSA
logger" step is skipped — **non-fatal**. The gate must accept either form
(PHASE0-RESULTS P2 once saw it resolve), which is why the smoke script checks 13
+ the link-time imports, not 14.

### 2.4 The failure signatures, and what the insmod text looks like

| console print | insmod text | init return | meaning |
|---|---|---|---|
| `[SACDREAD]Symbol "X" not found in /proc/allsyms!!` (once per missing name) | `insmod: …: Bad address` | `-EFAULT` | a mandatory lookup is NULL — bdpdrv not resident, or one of the 13 absent. The `"X"` in the line names the culprit |
| `[SACDREAD] compid = N is used. Try another.` | `insmod: …: Device or resource busy` | `-EBUSY` | `_au4CpsaInst[N] != -1`: the slot is owned (usually a second load without `rmmod`). Retry `compid=1..3` |
| `<3>[SACDREAD]Unable to register misc device` | propagated errno | `misc_register` err | minor 201 already taken (a resident `sacd_read`) |
| (no printk — the loader rejects it) | `insmod: …: Invalid module format` | — | vermagic mismatch (must be `2.6.35 preempt mod_unload ARMv6`) |
| (no printk) | `insmod: …: Unknown symbol …` | — | a link-time import is missing (`x_memset`) |

*VERIFIED (`.init.text` return codes `mvn r4,#13` / `mvn r4,#15`; the strings;
the PHASE0-RESULTS P2 execution record).*

**`-EFAULT` here means "bdpdrv is not the stack we thought"** — it is the gate
that catches a wrong bdpdrv build, and it is why this stage runs *after* the CLI
probes rather than in the same command block as them.

---

## 3. The smoke test without the daemon

### 3.1 The script

New guest-side file: **`decode/sacdread_smoke.sh`** (POSIX/busybox sh, written
alongside this doc). It reuses `decode/sacd_gate_ioctl.c` **unmodified** — the
same `open("/dev/sacd_read") → ioctl → read u4Result` helper `daemon_gate.sh`
drives, which already refuses the two payload-carrying commands (`5303` READ,
`5304` DECRYPT) and prints the one-line contract

```
IOCTL cmd=0x%08x ret=%d errno=%d result=%d raw=%08x %08x %08x %08x dev=%s
```

`ret` is the `ioctl(2)` return (**0 on success, `-22` `-EINVAL` for a non-`0x53`
command, `-14` `-EFAULT` on a copy failure** — the CPSA code is *never* the ioctl
return; `sacd_read_ioctl` stores it in `u4Result` and returns 0, `mvn r4,#24` at
`.text+0x644` for the bad-command path). `result` is `u4Result`, the field the
daemon reads back. *VERIFIED (`.text+0x2f0` case nr=1, `.text+0x5dc` tail
`__copy_to_user` → `r4=0`).*

### 3.2 The twelve gates

| gate | what it proves | PASS predicate |
|---|---|---|
| S01 proc-mount | `/proc/modules` + `/proc/misc` readable | files readable |
| S02 bdpdrv-resident | the 13 lookups have a home, and `i4CPSA_Init` already ran (it is what fills the slots with `-1`) | `^bdpdrv` in `/proc/modules` |
| S03 module-imports | `x_memset` + `x_thread_create` resolvable — the only link-time imports the load and INIT need | both in `/proc/kallsyms` |
| S04 module-image | the staged tar member is whole | size **== 97,805** |
| S05 module-load | `insmod minor=201` rc 0 **and** `/proc/misc` reports `sacd_read` on **201** | both; failure text classified (§2.4) |
| S06 sacd-read-node | the node the daemon mknods opens | `c 10 201` opens `O_RDONLY` |
| **S07 sacd-init** | **the hook proof**: `Connect(0x16b,compid,360,compid)` + `CPSMode_Ctrl(handle,0x40,TRUE)` → `i4CPSA_SACD_Create` + `SetCallback`, with a GCPU worker thread, event groups and a 10-deep msg queue | `ret == 0` **and** `result >= 0` (expect `1744830464` = `0x68000000`) |
| S08 sacd-auth | `SetSACDControl` → `i4CPSA_SACD_EnableControl`, then `_SACDCLI_TestPhy` and (if that returns 0) `eSacdGetVersion` + `vSacdDecryptEnable(TRUE)` | `ret == 0` and `result >= 0`; **only runs if S07 passed** |
| S09 sacd-uninit | `vSacdDecryptEnable(FALSE)` + `CPSMode_Ctrl(FALSE)` + `Disconnect` | `ret >= 0` (the daemon ignores this value) |
| S10 sacd-reinit | **decisive teardown proof**: a second INIT succeeds ⇒ `_au4CpsaInst[compid]` is back to `-1`, i.e. the slot did not leak | `ret == 0` and `result >= 0` |
| S11 dmesg | kernel-side copy of the `[SACDREAD]` lines when the guest has `dmesg` | present (else SKIP) |
| S12 module-unload | `rmmod` clears `/proc/misc`, so the daemon's own `insmod` cannot hit EEXIST | `sacd_read` gone from `/proc/misc` |

Output contract: `SMOKE <id> <PASS|FAIL|SKIP> <name> -- <detail>`, then
`SMOKE_N=`, `SMOKE_FAIL=`, `SMOKE_SKIP=`, `SMOKE_VERDICT=`. Exit 0 only on PASS;
`INCOMPLETE` (helper missing, `AUTH=0`, `dmesg` absent) exits 1 — a gate that did
not run is never a pass. Every gate is preceded by a `SMOKE_STEP=<id>` console
marker so the UART transcript can be sliced around it.

Env knobs: `PROC` `/proc`, `DEV` `/dev/sacd_read`, `SR0` `/dev/sr0`,
`KO` `/res/shim/sacd_read.ko`, `HELPER` `/res/shim/sacdgate`, `MINOR` `201`,
`COMPID` (empty = module default 0), `AUTH` `1`, `UNLOAD` `1`.

### 3.3 Which ioctl is which — and the AUTH correction

* `0x40105301` = **INIT**, `CPSA_SACDCmdEnable` (`sacdread-cpsa.md` §3.2, `init_sacd`).
* `0x40105302` = **AUTH**, `CPSA_SACDCmdSetCtrl` (`auth_sacd`) — not a version
  query, as `daemon-gate-experiments.md` §5 already ruled. But §5's *mechanism*
  ("`SetSACDControl` → `i4CPSA_SACD_EnableControl`, which returns `0x68000000`")
  is incomplete. The whole function is (`sacd_read.ko .text+0x6c`, 160 B):

  ```
  80: ldr r5,[r4,#0x8]        ; pi4CPSA_Inst_SetSACDControl
  88: ldr pc,[r4,#0x4]        ; u4CPSA_Inst_GetInstHandleFromCompId(compid)
  90: blx r5                  ; SetSACDControl(handle, &{fgEnable=TRUE})
  94: subs r5,r0,#0 ; blt -> printk "[%s]i4CPSA_Inst_SetSACDControl Fail:%d" ; return r5
  ac: ldr pc,[r4,#0xc]        ; _SACDCLI_TestPhy()          <-- the bring-up self-test
  b0: subs r5,r0,#0 ; beq 0xcc -> printk "[%s]eSacdGetVersion:%d" (d0: ldr pc,[r4,#0x10])
  b8: ... printk "[%s]_SACDCLI_TestPhy Fail:%d" ; return r5
  ec: ldr pc,[r4,#0x14]       ; vSacdDecryptEnable(TRUE)     <-- the MMIO leg
  ```

  The `.bss` slot names are the module's own symtab (`+0x0c` `p_SACDCLI_TestPhy`,
  `+0x10` `peSacdGetVersion`, `+0x14` `pvSacdDecryptEnable`), and the three
  printk strings sit at `.rodata.str1.1+0x2b/0x53/0x71` as quoted. `ldr
  pc,[r4,#0x0c|0x10|0x14]` appears **only** in this function, which is why the
  "looked up but never called" reading survives for `_SACDCLI_FindTag` and
  `ppdisable_print` but not for these two. *VERIFIED.*

  Consequences:
  * AUTH's `result >= 0` means **TestPhy returned 0** — the whole disc leg — not
    just the CPSA hook. With no `/dev/sr0`, AUTH returns negative with
    `[%s]Open ODD device failed: %d !!` on the console: informative, not a
    module defect. The smoke script says so in the gate detail.
  * **A SACD version line does exist in the AUTH path** (`eSacdGetVersion:%d`),
    which is the grain of truth in the original "version query" idea — but there
    is no ioctl for it and it only prints when TestPhy succeeds.

### 3.4 Why AUTH/UNINIT are gated on INIT (the fault, not the error)

```
u4CPSA_Inst_GetInstHandleFromCompId  bdpdrv 0x55a8c:
  55a8c: ldr r3,=.bss ; add r3,r3,r0,lsl#2 ; ldr r0,[r3,#8] ; bx lr    ; -> 0xFFFFFFFF when free
i4CPSA_Inst_SetSACDControl           bdpdrv 0x55900:
  55908: ldr r2,[r0]            <-- dereference of the handle, BEFORE any check
  5590c: cmp r2,#0x12043000 ; bne -> Assert ; return 0xE8000002
i4CPSA_Inst_CPSMode_Ctrl             bdpdrv 0x54b78:
  54b84: ldr r2,[r0]            <-- same shape (reached by UNINIT)
```

`0xFFFFFFFF` is not mapped, so AUTH-before-INIT is a **guest kernel data abort**
(and, in a QEMU run, a truncated stage that looks like a hang). Both ioctls are
therefore hard-gated on S07 in the script, and the `AUTH=0` / `UNINIT`-skip paths
are the only way they are bypassed. *VERIFIED both sides.* **INFERRED:** the
fault's exact console text depends on the guest's `show_unhandled_signals`
settings; the stage never relies on it, it just refuses to fire.

### 3.5 Time budget

| step | worst case | why |
|---|---|---|
| S05 insmod | < 1 s | 14 lookups + `misc_register` |
| S07 INIT | < 1 s | allocations + one thread |
| S08 AUTH | **≤ ~35 s** | `_IDECLI_OddTestUnitReadyLoop(20000)` polls 100 × 200 ms; `eSacdWaitPspPdmResult(5000)`; each ODD request times out at 10 s in the driver |
| S09/S10 | < 1 s | teardown + re-connect |
| S12 rmmod | < 1 s | — |

The fire's post-stage sleep must accommodate ~40 s; `AUTH=0` cuts it to ~3 s and
is the right default while C102 (sr0 enumeration) is still open.

---

## 4. Model-dependency check — what the stage asks of the QEMU model

### 4.1 INIT (S07): kernel bookkeeping only

`CPSA_SACDCmdEnable` → `i4CPSA_Inst_Connect` → `i4CPSA_Inst_Create`
(`bdpdrv 0x54724`):

| step | callee | hardware? |
|---|---|---|
| instance alloc 0x44 B, magic `0x12043000` | `x_mem_alloc` | no |
| **GCPU instance** | `i4GCPU_InstanceCreate` `0x173374` | no — slot scan over 10 entries, `x_sema_lock`, `x_ev_group_create` ×2, `x_msg_q_create` (10 deep), `x_thread_create` (32 KiB, prio 110), `x_mem_aligned_alloc(0x40)`, `x_snprintf`; **no `i4GCPU_HAL_RegWrite`, no `TzServiceCall`** |
| interface registration | `i4ImRegisterInterface2` / `i4ImQueryInterface` / `i4ImReleaseInterface` + one `blx` to the registered create callback | no — the SACD provider's callback is `i4CPSA_SACD_Create` |
| SACD ctx | `i4CPSA_SACD_Create` `0x55b74` (0x18 B, magic `0x12043007`, `byte[0x10]=compid`, `byte[4]=1`) + `i4CPSA_SACD_SetCallback` (`str r1,[r0,#8]; str r2,[r0,#12]`) | no |

The GCPU worker is created but **idle**: its only input is the message queue,
and a message only arrives from `i4GCPU_CmdExec` (the DECRYPT leg). So INIT
cannot reach the secure monitor. *VERIFIED for the call graph and the absence of
HAL/Tz calls; INFERRED for "the thread blocks on the queue".*

The five OSAL primitives it needs are all exported by the C-run's
`/tmp/osal_b/bx510_osal_stub.ko` (`x_thread_create`, `x_ev_group_create`,
`x_msg_q_create`, `x_sema_lock`, `x_mem_aligned_alloc` — `nm`), so INIT will not
die on a NULL import in this rig. *VERIFIED.*

### 4.2 AUTH (S08) / UNINIT (S09): the registers it touches

`vSacdDecryptEnable` is the only MMIO in the module (`bdpdrv 0xc6e30`), reached
by AUTH on success (`TRUE`) and by UNINIT unconditionally (`FALSE`):

| access | virt | phys | model status |
|---|---|---|---|
| write `0x17` | `0xFD039000` | `0x70039000` | default `bx510_ops` write: `LOG_UNIMP` line + ignored (`sony-bx510.c` `bx510_write` default arm) |
| write `0x12` / `0` | `0xFD039004` | `0x70039004` | same |
| read bits[2:1] (`eSacdGetVersion`) | `0xFD039008` | `0x70039008` | default read: `LOG_UNIMP` + returns **0** ⇒ "SACD_VER_10", inert |
| write `0x00800000` | `0xFD00815C`/`0xFD008154` | `0x70008154`/`0x7000815C` | writes fall through to the same default |
| poll bit 23 | `0xFD008154` | `0x70008154` | **implemented**: `case BX_BIM + 0x154: … return 0` (`sony-bx510.c:410`, `BX_BIM = 0x8000`) ⇒ self-clear exits on the first iteration |

**Free evidence, no kit change:** because four of these five accesses fall to the
default arm, the QEMU log will carry the prefix-decoded lines

```
bx510: unimplemented write 0x70039000 = 0x17
bx510: unimplemented write 0x70039004 = 0x12      (0 on the UNINIT leg)
bx510: unimplemented write 0x7000815c = 0x800000
bx510: unimplemented write 0x70008154 = 0x800000
bx510: unimplemented read 0x70039008
```

That is the stage's MMIO proof — AUTH reached `vSacdDecryptEnable(TRUE)` and
UNINIT reached it with `FALSE` — and it comes from the model's own address
arithmetic, not from reading a dump by eye. The `unimp_logs` cap is 200,000
lines per run, far above this stage's five. *VERIFIED (`bx510_read`/`bx510_write`
default arms, `memory_region_init_io(…, 0x1000000)` at `BX_IO_BASE = 0x70000000`).*

### 4.3 New MMIO windows: **none**

Both clusters live inside the model's single 16 MiB peripheral region at
`0x70000000` (`memory_region_init_io(…, 0x1000000)`), and the one read that could
hang is already answered with 0. What the model still owes this stage is **not
registers**:

1. `/dev/sr0` to exist for AUTH's TestPhy leg (C96/C97 enumeration → C102); without
   it AUTH returns negative and S08 FAILs with the ODD-open printk — the one
   *expected* red gate pre-C102.
2. SCSI answers on the already-modelled SATA path: TUR good (or CHECK CONDITION
   ASC 0x3A/0x30 while polling), GET CONFIGURATION current profile, READ(10)
   `0x98` (only for the READ ioctl, which this stage does not issue).
3. A GCPU worker that exists but does nothing — satisfied by INIT alone; the
   decrypt leg (`0x40105304`) still cannot be modelled (TrustZone SMC,
   `sacdread-cpsa.md` §4.3) and this stage never fires it.

**Recommendation:** staging the module needs no `emulator-kit` change. Fidelity
only (a `SACD/CPSA` block that latches `0x70039004` and answers `0x70039008`)
would be worth it later if a run needs to distinguish enable states; nothing in
this stage reads either back, and the `LOG_UNIMP` lines above are already a
sufficient record.

---

## 5. The fire-command block (PROPOSE — not applied)

Placement: **after the CLI probes (C95-C99), before any daemon launch.** The
script owns `insmod`/`mknod`/`rmmod`, so the command block stays two markers plus
a single `sh`, in the `probe-injection.md` style (intent echo on the UART, one
flag rather than a forked command list):

```diff
--- a/tools/bx510_bdpdrv_stub_probe.py
+++ b/tools/bx510_bdpdrv_stub_probe.py
@@ argparse — next to --stubko / --stuba-ko, the two existing staged modules
+    p.add_argument("--sacdread-ko", type=Path, default=None,
+                   help="host path to sacd_read.ko, staged as shim/sacd_read.ko "
+                        "for the C100 module stage (decode/sacdread-stage-plan.md); "
+                        "absent = the stage is not run")
+    p.add_argument("--sacdgate", type=Path, default=None,
+                   help="host path to the ARM-built sacdgate helper "
+                        "(decode/sacd_gate_ioctl.c), staged as shim/sacdgate")
+    p.add_argument("--sacd-auth", default="1", metavar="0|1",
+                   help="C100: '0' skips ioctl 0x40105302 (AUTH), which runs "
+                        "bdpdrv's whole SACD bring-up self-test and needs "
+                        "/dev/sr0 — red until C102; the other gates are "
+                        "hardware-free")
@@ the extra map (shim/kcheck.sh, shim/procc.sh)
     extra = {"shim/kcheck.sh": kscript_bytes,
              "shim/procc.sh": procc_bytes}
+    if a.sacdread_ko:
+        extra["shim/sacd_read.ko"] = a.sacdread_ko.read_bytes()
+    if a.sacdgate:
+        extra["shim/sacdgate"] = a.sacdgate.read_bytes()
@@ after the CLI probes, before "echo STUB_DONE"
         "sleep 3; echo CLI_DRAIN2",
+        # C100: the module between bdpdrv and the daemon. The script owns
+        # insmod/mknod/rmmod and prints one SMOKE line per gate; it self-gates
+        # AUTH/UNINIT on a successful INIT (handle deref, plan §3.4).
+        "echo SACDREAD_STAGE_BEGIN",
+        f"AUTH={a.sacd_auth} sh /res/shim/sacdread_smoke.sh; "
+        "echo SACDREAD_SMOKE_RC=$?",
+        "echo SACDREAD_STAGE_END",
         "echo STUB_DONE",
@@ meta.json
             "clidrive_mode": a.clidrive_mode or "DEFAULT",
+            "sacdread": None if not a.sacdread_ko else {
+                "sha256": sha256(a.sacdread_ko.resolve(strict=True)),
+                "size": a.sacdread_ko.stat().st_size,
+                "auth": a.sacd_auth,
+            },
```

The three flags follow the tool's own existing idiom (`--stubko` / `--stuba-ko`:
host path → staged `shim/<name>` → `sha256` in the meta), so nothing is invented
and every existing fire line is unchanged when they are omitted:

| flag | default | purpose |
|---|---|---|
| `--sacdread-ko` | none | stages the 97,805 B module; omitting it leaves the stage dark |
| `--sacdgate` | none | stages the 38,710 B helper built on the VM (§7) |
| `--sacd-auth` | `1` | `0` skips S08 — the correct default while C102 is open |

The script's own env knobs (`PROC`, `DEV`, `SR0`, `KO`, `HELPER`, `MINOR`,
`COMPID`, `AUTH`, `UNLOAD`) stay at their defaults in the fire line, and the
script **echoes them on its second output line**, so the transcript records what
was used. If the C95-C99 command list relocated the mount points (the shell-mode
runs use `/res/proc` and sometimes `/res/dev`), that prefix is the one thing to
check against the previous fire before this stage's first run — a one-word change
in the fire line, not a code change.

**Proposed, not applied** (this lane may not touch `tools/`). One more one-line
safety fix belongs to whoever owns `decode/daemon_gate.sh`: gate 14 must require
`g12 = PASS`, for the §3.4 reason —

```diff
--- a/evidence/bx510-guest/bdpdrv/decode/daemon_gate.sh
+++ b/evidence/bx510-guest/bdpdrv/decode/daemon_gate.sh
@@ gate 14 (g14d="no valid Master TOC (gate 13) ..." / elif ioctl_run 0x40105302)
     g14d="no valid Master TOC (gate 13) — the daemon reaches AUTH only after it"
-elif ioctl_run 0x40105302; then
+elif [ "$g12" != "PASS" ]; then
+    g14d="not run: INIT (gate 12) did not pass — AUTH dereferences a 0xFFFFFFFF instance handle"
+elif ioctl_run 0x40105302; then
```

---

## 6. What this stage changes in the earlier decode docs

1. `sacdread-cpsa.md` §1, bullet 3: "`_SACDCLI_TestPhy`, `eSacdGetVersion`,
   `_SACDCLI_FindTag`, `ppdisable_print` … looked up but never called" — true for
   the last two, **false** for the first two: both are called from
   `CPSA_SACDCmdSetCtrl` (§3.3 here). The `VERIFIED` note there ("no
   `[r4,#0x0c|0x10]` load outside `.init.text`") missed `.text+0xac`/`0xd0`.
2. `daemon-gate-experiments.md` gate 14 ("`SetSACDControl` → `i4CPSA_SACD_EnableControl`")
   understates AUTH by two legs (TestPhy, decrypt-enable), and its PASS predicate
   therefore expects a value that a pre-C102 rig will not produce.
3. `sacdread-cpsa.md` §2.3's table for `CPSA_SACDCmdSetCtrl` needs the two extra
   steps and the `"[%s]_SACDCLI_TestPhy Fail:%d"` / `"[%s]eSacdGetVersion:%d"`
   strings.
4. New: the **ordering safety rule** (§3.4) — worth a line in
   `daemon-gate-experiments.md` §4 where it lists the preconditions.

None of these change the C96/C97 ATA decode; they change what the *module stage*
can prove and in which order it may fire.

---

## 7. Provenance and reproduce

Inputs: `original/sacd_read.ko` (sha256 `b3d7a383…`, 97,805 B, unstripped
DWARF + symtab), `bdpdrv.ko` (`/tmp/bdpdrv.ko` on the VM, sha256 `6604f6cd…`),
`decode/sacd_gate_ioctl.c` (3,740 B, unchanged), `decode/daemon_gate.sh` (the
helper contract this stage reuses), `decode/daemon-ioctl-side.md` §1.2/§3.1,
`decode/sacdread-cpsa.md` §1-§4.

```sh
# 1. the artifact (VERIFIED hashes above)
make vm-exec CMD='find /tmp/rootfs* -name "sacd_read*" 2>/dev/null'   # -> empty
make vm-exec CMD='sha256sum /home/aftermath/sacd-verify/original/sacd_read.ko'
make vm-pull-file FILE=/home/aftermath/sacd-verify/original/sacd_read.ko DEST=/tmp/sacdread
shasum -a 256 /tmp/sacdread/sacd_read.ko

# 2. params / strings (the two .bss objects, the vermagic, the parm lines)
/opt/homebrew/opt/llvm/bin/llvm-readelf -s /tmp/sacdread/sacd_read.ko | grep -E ' compid$| minor$'
strings -a /tmp/sacdread/sacd_read.ko | grep -E 'parm=|vermagic'

# 3. the AUTH correction (the three slot loads + the three format strings)
/opt/homebrew/opt/llvm/bin/llvm-objdump -d --no-show-raw-insn --section=.text \
    /tmp/sacdread/sacd_read.ko | awk '/<CPSA_SACDCmdSetCtrl>:/,/^$/'
python3 - <<'EOF'
d=open('/tmp/sacdread/sacd_read.ko','rb').read(); base=0xb0c   # .rodata.str1.1
for o in (0x22,0x2b,0x53,0x71): s=d[base+o:d.index(b'\0',base+o)]; print(hex(o), s)
EOF

# 4. the handle-deref rule (why AUTH/UNINIT need a successful INIT)
~/gnuarm/bin/arm-none-linux-gnueabi-objdump -d --no-show-raw-insn /tmp/bdpdrv.ko \
    --start-address=0x55900 --stop-address=0x55948    # ldr r2,[r0] first
~/gnuarm/bin/arm-none-linux-gnueabi-objdump -d --no-show-raw-insn /tmp/bdpdrv.ko \
    --start-address=0x55a8c --stop-address=0x55a9c    # GetInst -> .bss slot, may be -1

# 5. the INIT leg's hardware-freeness
~/gnuarm/bin/arm-none-linux-gnueabi-objdump -d --no-show-raw-insn /tmp/bdpdrv.ko \
    --start-address=0x54724 --stop-address=0x54900    # i4CPSA_Inst_Create
~/gnuarm/bin/arm-none-linux-gnueabi-objdump -d --no-show-raw-insn /tmp/bdpdrv.ko \
    --start-address=0x173374 --stop-address=0x1736b4  # i4GCPU_InstanceCreate
nm --defined-only /tmp/bdpdrv.ko | grep -E 'TzServiceCall|i4GCPU_HAL_RegWrite'

# 6. the stage script: syntax, lint, helper build, dry run
shellcheck -s sh -S style evidence/bx510-guest/bdpdrv/decode/sacdread_smoke.sh
make vm-stage-file FILE=evidence/bx510-guest/bdpdrv/decode/sacdread_smoke.sh
make vm-exec CMD='sh -n /tmp/sacdread_smoke.sh'                     # dash
make vm-exec CMD='~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -Wall -Wextra \
    -std=gnu99 -o /tmp/sacdgate /tmp/sacd_gate_ioctl.c'             # 38,710 B
```

---

## 8. Validation performed for this stage (no emulator fire)

| check | command | result |
|---|---|---|
| POSIX syntax, dash (the VM's `/bin/sh`) | `sh -n /tmp/sacdread_smoke.sh` on the VM | **rc=0** |
| shellcheck, `sh` dialect, style severity | `shellcheck -s sh -S style` | one informational finding (`IO_RC` assigned-not-read, same as `daemon_gate.sh`) |
| helper cross-build (unchanged source) | `arm-none-linux-gnueabi-gcc -O2 -Wall -Wextra -std=gnu99` | **rc=0**, warnings 0, 38,710 B, `ELF32 ARM EABI5 EXEC`, `NEEDED libc.so.6` only |
| script logic, three dry runs with a fake helper/procfs/ko | all-OK helper → `SMOKE_N=12/12`, `VERDICT=PASS`, rc 0; AUTH-fails helper → S08 `FAIL` with the `0xE8000002` hint; `AUTH=0` → `INCOMPLETE` (rc 1); missing module/helper → S04 FAIL, S07-S10 SKIP | counters and verdicts correct — this run also caught and fixed a real bug in the script (six `gate` calls passed name/status in the wrong order, so `PASSED` undercounted) |
| module identity on both sides | `sha256sum` VM + `shasum -a 256` Mac | identical (`b3d7a383…`) |

Not validated here (needs a fire, out of this lane): the guest-side insmod, the
ioctl round-trip against real bdpdrv, and the console prints. The gates that
will legitimately go red pre-C102 are **S08** (TestPhy needs `/dev/sr0`).
