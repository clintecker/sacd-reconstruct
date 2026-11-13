# feboot option A — the forged-flag module is out, and the real flag is the evidence

**Scope.** This pass owns three things and nothing else: (1) put the module source
under version control so the artifact survives a VM rebuild; (2) grep the C9x/C10x UART
logs for *every* consumer that depended on `bx510_feboot.ko` and turn that into the list
of observables the next fire must show; (3) close the one open risk option A carries —
does the **real** `_fg_fe_bootup` reach `1` in the emulated flow, so that
`[v4IdeDrvInitThread]FE boot up OK !!` keeps printing *as evidence* instead of as a
forgery?

**Not touched:** `tools/bx510_bdpdrv_stub_probe.py` (the one-line diff is
`decode/probe-seq-v2.md` §3.1, applied by the parent in `6fc4282`), `tools/bx510_stub_build.sh`
(option A builds nothing), `emulator-kit/sony-bx510.c`, any other `decode/*.md` —
except that §6 records two corrections to sibling docs, as cross-references, not edits.

**Inputs.** The module source `/tmp/osal_d/bx510_feboot.c` on the lab VM
(`10.20.0.18`), pulled with `make vm-pull-file`; `sata_mt85xx_mod.ko`
(`/tmp/sata_staging/sata_mt85xx_mod.ko`, md5 `96e3246cb604705726781264e8a93b11`);
`bdpdrv.ko` (`/tmp/bdpdrv.ko`); Sony's kernel tree `~/sony-kernel/linux-2.6.35`
(`sata_bltin.c`, `fs/proc/*`, `drivers/ata/libata-core.c`); the UART logs
`bdpdrv-runC50..C55`, `C91`, `C93..C101`; `decode/feboot-marshal.md`,
`decode/probe-seq-v2.md`, `decode/sata-fw-load.md`,
`decode/listings/sata_mt85xx_port_start.txt`; `emulator-kit/sony-bx510.c`.

**Method.** Deterministic only: ELF relocations and literal-pool values decoded by script
(§7), never hexdumps read by eye; log claims are grep counts over the evidence files.
**DECODED** = an instruction, a relocation or a kernel-source line fixes it;
**INFERRED** = consistent with everything seen, not closed by one observation.

---

## 0. TL;DR

1. **Source tracked** at `tools/bx510_feboot.c` as a tombstone — header states
   OPTION A (not loaded, not built), body byte-identical to the VM file
   (md5 `d4071d4e5a0cb22494bf6d25c1082448`). No build stanza, by design.
2. **Nothing in the pipeline depended on the module.** The complete `/proc/driver/*`
   surface named by the driver stack is two paths: `sata/fe_bootup` and `sata/force_eject`;
   no `KEXP*` check reads `/proc/driver` (they grep `/proc/kallsyms`); `sacd_read.ko` has
   no proc entries; nothing imports a symbol the module provides. The only *new* UART line
   the next fire should gain is `fe_bootup = 1` — `sata_bltin`'s own change-detecting
   printk, which has never appeared in a run because the real entry was never the one
   being read.
3. **The real flag does reach 1 in the emulated flow — DECODED and per-run proven.**
   `sata_mt85xx_port_start` is in the port-ops table (`.rel.data+0x1bc` →
   `.text+0x2fac`; `libata-core.c:5953` calls it from `ata_host_start`, *before*
   `scsi0 :` prints). It takes its **fast-boot branch** (`priv[+8] == 1`), whose own
   `printk`s — `[IDE]int_val = 0x10000` and `[IDE]Receive frontend boot up status:0x0` —
   are referenced from **that function's literal pool only**, then downloads the AACS
   code and stores `1` into `_fg_fe_bootup` at **`.text+0x32c0`**. All four markers sit in
   C91/C93/C94/C95/C97/C98/C99/C100/C101 in exactly that order, ahead of `scsi0 :`.
   So `bdpdrv`'s `filp_open` of the *real* `sata_bltin` entry will read `1`, and
   `FE boot up OK !!` + `End..` will still print — now traceable to the handshake in the
   same log.
4. **The sharpest proof of the forgery is already in the artifacts:** in **C54, C55 and
   C96** the SATA port never started (`polling frontend reset interrupt timeout !!` →
   `failed to start port 0 (errno=-5)` → `ata_host_activate err`; no `scsi0`, no `ata1`),
   the shared failure exit set `_fg_fe_bootup = 0` — **and all three runs still printed
   `FE boot up OK !!`.** That is the module's assertion, and option A is what removes it.
5. **The risk is bounded and named** (§5): `v4IdeDrvInitThread` content-polls `'1'` with
   no iteration cap (`probe-seq-v2.md` §3.3), so a run whose handshake fails will lose
   `FE boot up OK !!`/`End..` and leave that thread polling — that is the correct
   observable, not a rig failure. Read it with `[IDE]int_val`/`failed to start port`.

---

## 1. The tracked artifact

| fact | value |
|---|---|
| repo path | **`tools/bx510_feboot.c`** (new file) |
| status header | `STATUS: OPTION A — NOT LOADED, NOT BUILT`, plus what it forged, how it shadowed `/proc/driver`, and the "no build stanza on purpose" note |
| body provenance | everything below the `artifact (verbatim)` marker is byte-identical to the VM file — verified: `tail -n +38 tools/bx510_feboot.c \| md5` → `d4071d4e5a0cb22494bf6d25c1082448` |
| source pulled from | VM `/tmp/osal_d/bx510_feboot.c` via `make vm-pull-file FILE=/tmp/osal_d/bx510_feboot.c DEST=/tmp/` |
| built `.ko` (VM) | `/tmp/osal_d/bx510_feboot.ko`, md5 `b1a562e1697cbf5bded3d37986a98307`, vermagic `2.6.35 preempt mod_unload ARMv6` |
| build recipe | **none added.** `tools/bx510_stub_build.sh` builds parts A/B + clidrive only; option A does not build this module, so a stanza here would be dead weight (option B would add one when/if chosen) |
| remaining references in `tools/` | none outside this file: `grep -rn feboot tools/` matches this file plus the removal comment at `tools/bx510_bdpdrv_stub_probe.py:183` (commit `6fc4282`) |
| commit state | **left unstaged / uncommitted for the parent** — this repo commits through `make sacd-commit` |

**The tracked file still builds to the same code** (one-off check in `/tmp/febcheck` on the VM, *not* a
build stanza and never staged into `/res/shim`): with the stub-build script's flags
(`CROSS_COMPILE=$HOME/gnuarm/bin/arm-none-linux-gnueabi-`, `-march=armv6 -Wa,-march=armv6`,
`KDIR=$HOME/sony-kernel/linux-2.6.35`) the tracked source compiles clean, and its
`.init.text` / `.text` / `.exit.text` section dumps are **byte-identical** to the VM artifact's
(`readelf -x` diff, empty). The `.ko` md5 differs (`09b4f79e…` vs `b1a562e1…`, 55,199 vs 55,187 B)
only because this rebuild's vermagic reads `ARMv7` where the original carries `ARMv6` — the
original came through the ARMv6 toolchain/patch path. The header is a pure comment: the string
`TOMBSTONE`/`OPTION A` does not appear in the built module.

Why a tombstone rather than a delete: `decode/feboot-marshal.md` §0 established the file
existed **only** on the VM, so a rebuilt `/tmp` would have destroyed the only copy of the
thing every C50–C101 conclusion is read against. It is also the exhibit for §4's forgery
claim, and option B (the fix) starts from this text.

---

## 2. What actually depended on the module — the grep

**Every `/proc/driver*` path the loaded driver stack names** (decoded from the binaries,
not from memory):

| artifact | paths found |
|---|---|
| `bdpdrv.ko` (`strings -a \| grep -o "/proc/driver…"`) | `/proc/driver/sata/fe_bootup` ×2 (the path + the `Can't open` format), `/proc/driver/sata/force_eject` ×1 |
| `bdpdrv.ko`, other proc paths | `/proc/mtd` ×9, `/proc/bus/usb/000/000` ×1 — neither is under `/proc/driver`, unaffected |
| `sata_bltin` (built-in, `sata_bltin.c:640,646-743`) | creates `driver/sata` and **12** entries: `media_present`, `eject_pressed`, `module_installed`, `read_log`, `ide_log_en`, `cmd_timeout`, `fe_bootup`, `fe_fw_mem`, `tray_status`, `pb_buf_time`, `force_eject`, `stop_detect_oc` |
| `sata_mt85xx_mod.ko` | names no `/proc` path; it **writes** the flag directly (`R_ARM_ABS32 _fg_fe_bootup` from `port_start`, `_sata_mt85xx_hw_chg_st`, `sata_mt85xx_exit` — §4.2) |
| `sacd_read.ko` | registers no proc entries at all (`feboot-marshal.md` §3) |
| `tools/kcheck.sh` (KEXP rows) | greps **`/res/proc/kallsyms`** only. `grep -wq _fg_fe_bootup` is line 23 and reads `no` in every C9x run — a kallsyms query, **not** a `/proc/driver` read, so option A cannot move it |
| `tools/procc.sh` (staged by the probe) | `cat /proc/driver/sata/fe_bootup` (line 7 → `CAT_FB`), then three existence checks (`PROCCHECK-…=EXISTS`) |

**Consumer-by-consumer verdict**

| # | consumer | with feboot | after option A | class |
|---|---|---|---|---|
| 1 | feboot's own `[FEB] up (INSTRUMENT)` / `[FEB] …flag = 1` | present | **gone** | DECODED (it is the module's printk) |
| 2 | `FEB_INSMOD=$?` echo | present | **gone** | DECODED (deleted line; no script in the repo greps it — checked: only `feboot-marshal.md` / `probe-seq-v2.md` prose) |
| 3 | `WARNING: at …/fs/proc/generic.c:583 proc_register+0x1a0/0x220` + `dump_stack` block | present (C101:316-327) | **gone** | DECODED (rides `proc_mkdir("driver", NULL)`, `feboot-marshal.md` §1.3) |
| 4 | `bdpdrv`'s `v4IdeDrvInitThread` → `filp_open("/proc/driver/sata/fe_bootup")` | resolves to feboot's **duplicate** entry, which `sprintf`s the forged flag | resolves to **`sata_bltin`'s real entry**, same symbol | DECODED (§4) |
| 5 | `[IDE]fe_bootup = %d` (`sata_bltin.c:486-487`, printed when the value changed since the last read; init `-1`) | **never printed in any run** | **expected on the first real read: `fe_bootup = 1`** | DECODED (kernel source) |
| 6 | `procc.sh` line 7 `cat /proc/driver/sata/fe_bootup` → `CAT_FB` | `1CAT_FB=0` (C101:1795) | `1CAT_FB=0` — same byte, real entry | DECODED (both entries read the same `int`) |
| 7 | `PROCCHECK-{…fe_bootup, …/sata, …/driver}=EXISTS` | EXISTS×3 (C101:1799-1805) | EXISTS×3 — the real pdes exist from boot | DECODED |
| 8 | kernel built-ins' `/proc/driver/{rtc,nvram,mmc/*,usb/*}` + 11 of the 12 `sata_bltin` entries | path-unreachable (shadowed by the head-inserted duplicate) | **reachable again** | DECODED (`feboot-marshal.md` §3: `proc_register` head-insert + `generic.c:445` head-first lookup) |
| 9 | `bdpdrv`'s `/proc/driver/sata/force_eject` | would `ENOENT` (shadowed) | succeeds | **INFERRED** — the string exists in `bdpdrv.ko`, but **no log line has ever shown it being opened**, so a behaviour change here would be information, not alarm |
| 10 | `sata_bltin`'s `/proc/driver/sata/*` read side (the other entries) | unreachable | reachable | DECODED by #8; no current script lists them |
| 11 | module-load ordering | `stub_a → drvcli → stub_b → feboot → bdpdrv` | `stub_a → drvcli → stub_b → bdpdrv` | DECODED: `bx510_feboot.ko` has `depends=` empty and **imports** `_fg_fe_bootup` (it provides no symbol), so nothing can depend on its presence |
| 12 | MMIO trace | — | unchanged: the module performed **no** MMIO (no `ioremap`, no register access, no IRQ, no thread) | DECODED (`feboot-marshal.md` §1.2) |

**The list of observables the next run must show, and how to read them**

| # | line | expectation | if it fails |
|---|---|---|---|
| a | `WARNING … proc_register` / `cut here` block | **absent** | feboot is somehow still loading — check the staged `/res/shim` and the command list |
| b | `[FEB] …` / `FEB_INSMOD=` | **absent** | same as (a) |
| c | `[v4IdeDrvInitThread]Can't open /proc/driver/sata/fe_bootup` | **absent** | the "sata_bltin provides the path" premise is falsified ⇒ option **B**, and `/proc` mount state must be re-checked (`ROOTPROC`) |
| d | `[IDE]fe_bootup = 1` | **present once**, from the real entry | absent ⇒ nothing read the real entry (suspicious); `fe_bootup = 0` ⇒ the flag genuinely did not get set |
| e | `[v4IdeDrvInitThread]FE boot up OK !!` **and** `End..` | **present** in a C98-class boot (handshake ran, §4) | both absent together ⇒ the handshake failed; look for `[IDE]int_val`/`polling frontend reset interrupt timeout !!` in the same log (see §5) |
| f | `PROCCHECK-…=EXISTS` ×3, `CAT_FB` | unchanged | any `MISSING` ⇒ the real proc tree is not there ⇒ option B |
| g | `[IDE]set _fg_fe_bootup = 0` | **still absent** (it has never appeared) | its appearance means a hardware-change/eject path fired and cleared the flag — informative, not a regression |

---

## 3. Why "FE boot up OK" was unfalsifiable — already provable from the old logs

Differential across the existing runs (grep counts; `int_val` and AACS are §4's
fast-boot markers, `scsi0` is libata registering the started host):

| run | `[IDE]int_val` | AACS download | `scsi0 :` | port start result | `FE boot up OK !!` |
|---|---|---|---|---|---|
| C54 | — | — | — | `polling frontend reset interrupt timeout !!` → `failed to start port 0 (errno=-5)` | **printed** |
| C55 | — | — | — | same failure (C55:265-267) | **printed** |
| C96 | — | — | — | same failure (C96:276-278) | **printed** |
| C91, C93, C94, C95, C97 | 1 | yes | yes | started (fast-boot branch) | printed |
| C98, C99, C100, C101 | 1 | yes | yes | started (fast-boot branch) | printed |

So in three runs the FE handshake demonstrably **failed** — `sata_mt85xx_port_start`
returned `-EIO` through the shared failure exit that clears `_fg_fe_bootup` — and
`bdpdrv` still reported "FE boot up OK". The forged `_fg_fe_bootup = 1` at
`feboot_init` is the only thing that can explain it. After option A those three runs
would read `0` and the message would be **absent**, which is exactly the property that
makes it evidence.

---

## 4. The real-flag confirmation (the risk option A carries)

**The question.** `bdpdrv`'s `v4IdeDrvInitThread` opens `/proc/driver/sata/fe_bootup` and
waits for the byte `'1'` (`probe-seq-v2.md` §3.3). With feboot gone it reads
`sata_bltin`'s entry, i.e. the *real* `_fg_fe_bootup`. Does the emulated flow ever set it?

### 4.1 `sata_mt85xx_port_start` is registered and therefore called — DECODED

| fact | evidence |
|---|---|
| it is in the port-ops table | `.rel.data` entry `+0x1bc  R_ARM_ABS32  0x00002fac  sata_mt85xx_port_start` |
| libata calls that slot, before the host is registered | `drivers/ata/libata-core.c:5953-5954` — `if (ap->ops->port_start) { rc = ap->ops->port_start(ap); … }` inside `ata_host_start()`; the `scsi%d :` line comes later from `ata_host_register()` |
| the function's own extent | `.text+0x2fac`, size 1216 (`0x4c0`) → `0x2fac..0x346c`, from the symbol table |

### 4.2 Which branch the emulated flow takes, and where the flag is written — DECODED

Entry test (`decode/listings/sata_mt85xx_port_start.txt`, lines 5-21 of the listing):

```
r5 = priv; r2 = ide_log_en
tst r2,#8 ; bne 0x33e0          ; verbose "<%s>ch:%d start" print, then continue
r3 = [r5,#8] ; cmp r3,#1 ; beq 0x3230   ; priv[+8] == 1  →  FAST-BOOT branch
```

The flag's stores, exactly as decoded (one shared literal-pool slot, `.text+0x342c`, four
load sites):

| site | value | branch / trigger |
|---|---|---|
| **`.text+0x32c0`  `str r2,[r3]`, `r2 = #1`** | **1** | fast-boot branch, immediately after `bl sata_mt85xx_xfer_int_ldr_aacs_data` (0x32b0) returns — **this is the plane the emulator takes** |
| `.text+0x3354` | 0 | the no-device continuation at 0x331c-0x3358 (`phy_fsm == 34`, the cold branch's 50-iteration poll exit) |
| `.text+0x3368` | 0, then `return -EIO` (`mvn r0,#4` = -5) | the fast-boot status wait's timeout exit 0x335c → (0x33f4 prints `polling frontend reset interrupt timeout !!`) → 0x3368 — **the exit C54/C55/C96 printed** |

`_fg_fe_bootup` has exactly **three** relocation sites in the whole module: the
`port_start` pool above, `_sata_mt85xx_hw_chg_st` (`.text+0x41f4`, stores **0** and prints
`[IDE]set _fg_fe_bootup = 0`, `.rodata.str1.4+0x1228`) and `sata_mt85xx_exit`
(`.exit.text+0x24`, stores 0 at unload). So nothing silently re-forges it.

### 4.3 The emulated flow *is* the fast-boot branch — proven from the logs

The fast-boot branch's status poll prints through `ide_log_en`-gated formats whose only
reference in the module is that function's pool:

| string | referenced from | in the logs |
|---|---|---|
| `[IDE]int_val = 0x%x` (`.rodata.str1.4+0xe18`) | `.text+0x3450` — `sata_mt85xx_port_start+0x4a4`, and **nowhere else** (relocation scan of `.rel.text` + `.rel.init.text`) | `[IDE]int_val = 0x10000` — C101:277 |
| `[IDE]Receive frontend boot up status:0x%x` (`+0xe30`) | `.text+0x3454`, same function only | C101:278 |
| (the AACS download it then performs) | `sata_mt85xx_xfer_int_ldr_aacs_data`, called at 0x32b0 | `[IDE]download AACS code (0x0, 0x4000) … start/end` — C101:279-280 |
| then the store | `.text+0x32c0` | no printk — it is a plain `str` |

Order in the log is exactly the order in the code, and it is all **ahead** of the host
registration line the libata path prints afterwards:

```
C101:277  [IDE]int_val = 0x10000              <- fast-boot status poll, port_start
C101:278  [IDE]Receive frontend boot up status:0x0
C101:279  [IDE]download AACS code (0x0, 0x4000) ... start
C101:280  [IDE]download AACS code (0x0, 0x4000) ... end
          .text+0x32c0  _fg_fe_bootup = 1    <- the store, no print
C101:282  [IDE]Internal loader boot code mode
C101:284  scsi0 : sata_mt85xx                 <- ata_host_register, i.e. AFTER port_start
C101:290  ata1.00: ATAPI: SONY    BDPSACDEMUL, 1.00, max UDMA/33
```

The poll succeeds because the model serves it: `emulator-kit/sony-bx510.c:776-781` arms
`fe_irq |= FE_IRQ_MSG` (`0x10000`) on the FE reset release `(val & 0x601) == 0x601`, and
`case 0x5c804` returns `fe_irq & FE_IRQ_MSG` (line 428/436) — matching
`int_val = 0x10000` byte for byte.

**Verdict:** in the C98-class flow the real `_fg_fe_bootup` is `1` **before `bdpdrv` is
insmodded**, so with feboot absent `bdpdrv`'s `filp_open` reads `1` from `sata_bltin`'s
real entry, `[v4IdeDrvInitThread]FE boot up OK !!` and `End..` still print, and the same
log now contains the handshake that justifies them (`int_val = 0x10000` + the AACS
download). Option A does not cost the observable; it makes it falsifiable.

### 4.4 The trap this decode removes

`[IDE]<sata_mt85xx_port_start>ch:%d, i=%d, st=0x%x, signature=0x%x`
(`.rodata.str1.4+0xf00`) belongs to the **cold-boot** branch (`priv[+8] != 1`) and
therefore **never appears in any run we have** — including the healthy C91/C93/C98/C101
boots. Its absence is not evidence of failure. The fast-boot markers (`int_val`,
`Receive frontend boot up status`, `download AACS code`) are the ones to grep, and
`failed to start port 0 (errno=-5)` is the failure marker.

---

## 5. The one risk, and the confounds to keep out of the reading

| # | risk / confound | status | how the next run reads it |
|---|---|---|---|
| 1 | **`v4IdeDrvInitThread` polls `'1'` with no iteration cap** (`probe-seq-v2.md` §3.3: `vfs_read` 1 byte → `cmp #49` → `x_thread_delay(200)` → loop). With the real flag at `0` the thread never reaches `End..` | DECODED (that doc); §4 shows the flag is `1` in the C98-class flow, so this only bites in a *failed-handshake* boot | `FE boot up OK !!` **and** `End..` absent together, with `[IDE]int_val` absent or `failed to start port 0` present ⇒ handshake failure, not a wedged rig. Do not restart the rig for it |
| 2 | **`procc.sh` staging confound (harness, not feboot).** The probe stages `procc.sh` only if the file sits next to `kcheck.sh` (`bx510_bdpdrv_stub_probe.py:107-110`, i.e. `tools/procc.sh`) — and **`tools/procc.sh` does not exist in this tree** (the only copy is in the older tree at `…/aftermath-sacd/experiments/sacd_reconstruct/tools/procc.sh`). If it is not staged, `PROCCHECK-*`, `CAT_FB`, `MOUNT_DONE` and the `procc.sh` mount lines all vanish | VERIFIED (file absent; C101:1799-1806 proves it *was* staged for that run) | Before firing, confirm `tools/procc.sh` exists (or stage it), otherwise rows (f) of §2 disappear for a reason that has nothing to do with option A |
| 3 | **Model dependency.** The fast-boot poll needs the model's `0x5c804` bit16 arm; if a `sony-bx510.c` edit breaks the `(val & 0x601) == 0x601` arm, `port_start` times out, the real flag stays `0`, and the message correctly disappears | DECODED (model source cited in §4.3) | a *new* disappearance of (e) after a model change is a model regression report, not an option-A failure |
| 4 | **Flag can be cleared later** by `_sata_mt85xx_hw_chg_st` (`.text+0x41f4`) and by module unload (`.exit.text+0x24`) | DECODED | `[IDE]set _fg_fe_bootup = 0` appearing in a future log is real driver behaviour (hardware-change/eject path) — record it, do not treat it as noise |
| 5 | `bdpdrv`'s `force_eject` read becomes reachable (§2 row 9) | INFERRED | no run has ever logged it; if it now produces a line or a different IDE-init step, that is new information about the driver, worth a note in the results doc |

---

## 6. Confirmations and corrections for the sibling docs

| doc | claim | this pass |
|---|---|---|
| `feboot-marshal.md` §2 | "it is a one-shot init wait, not a poll" | **superseded** by `probe-seq-v2.md` §3.3 (content poll, no cap). §4/§5 here are written against the poll |
| `feboot-marshal.md` §2 | "the flag it waits on is written by the real stack … `sata-fw-load.md` records the success path setting it to 1" | **now decoded at instruction level and proven per run** (§4): the writer is `.text+0x32c0` on `port_start`'s fast-boot branch, and its markers are in every C91/C93-C95/C97-C101 log |
| `feboot-marshal.md` §4/§5 | the differential "`/proc` mounted **and** no feboot" had never been run | still true — this pass makes the prediction exact; `6fc4282` applies the change, the fire is the parent's |
| `probe-seq-v2.md` §3.3 row 5 | "`FE boot up OK !!` … only if the real `_fg_fe_bootup == 1` — i.e. if `sata_mt85xx_port_start`'s firmware-load path actually ran" | **refined**: in the current emulator the relevant path is the *fast-boot* branch (`priv[+8] == 1`), not the cold firmware-load path — the cold path's success printk (`.rodata.str1.4+0xf00`) appears in **no** run. The prediction stands (the flag is `1`), the mechanism name was off |
| `probe-seq-v2.md` §4 open risk 5 | "`_fg_fe_bootup`'s writer was not re-verified in this pass" | **closed for the C98-class flow** by §4 (relocation + pool scan + per-run marker order); the failure class (C54/C55/C96) is now decoded too |

---

## 7. Commands and scripts (all deterministic; nothing read by eye)

```sh
# the artifact
make vm-pull-file FILE=/tmp/osal_d/bx510_feboot.c DEST=/tmp/        # md5 d4071d4e…
cat <header> /tmp/bx510_feboot.c > tools/bx510_feboot.c
tail -n +38 tools/bx510_feboot.c | md5                              # d4071d4e… (body verbatim)

# what bdpdrv / sata_bltin name under /proc
make vm-script SCRIPT=<script with:> strings -a /tmp/bdpdrv.ko | grep -o "/proc/driver[A-Za-z0-9_/.]*"
gate: bdpdrv names exactly fe_bootup (×2) and force_eject (×1)

# the flag's writers: relocation sites → containing function
python3 /tmp/feb_refs.py        # .text+0x342c (port_start pool), .text+0x4510
                                # (_sata_mt85xx_hw_chg_st pool), .exit.text+0xcc
# which function owns a literal-pool slot / an address
python3 <ELF scan>              # symbol intervals from .symtab, relocs from .rel.text
                                # .rel.init.text/.rel.exit.text, pool values from .text
/opt/homebrew/opt/llvm/bin/llvm-objdump -d --triple=armv5-none-eabi \
    --start-address=0x32a0 --stop-address=0x32e0 /tmp/sata_mt85xx_mod.ko   # the 0x32c0 store

# kernel source confirmations (VM)
grep -n "_fg_fe_bootup" ~/sony-kernel/linux-2.6.35/drivers/sata_bltin/sata_bltin.c
grep -n "port_start"    ~/sony-kernel/linux-2.6.35/drivers/ata/libata-core.c
grep -n "create_proc"   ~/sony-kernel/linux-2.6.35/drivers/sata_bltin/sata_bltin.c

# the log differential (§3)
for f in evidence/bx510-guest/bdpdrv/bdpdrv-runC*.uart.log; do
  printf "%s int_val=%s aacs=%s scsi0=%s feOK=%s\n" "$f" \
    "$(grep -c 'int_val = ' $f)" "$(grep -c 'download AACS' $f)" \
    "$(grep -c 'scsi0 : ' $f)" "$(grep -c 'FE boot up OK' $f)"
done
grep -l "set _fg_fe_bootup" evidence/bx510-guest/bdpdrv/*.uart.log      # empty: never cleared

# the tracked source is still the artifact it claims to be (VM, one-off)
make vm-stage-file FILE=tools/bx510_feboot.c && make vm-script SCRIPT=<build check>
# -> .init.text/.text/.exit.text section dumps identical to /tmp/osal_d/bx510_feboot.ko
```

---

## 8. One-line summary

`tools/bx510_feboot.c` now tracks the module as an option-A tombstone (body md5
`d4071d4e…`, no build stanza); nothing in the pipeline depended on it — the only
`/proc/driver` paths the stack names are `sata/fe_bootup` and `sata/force_eject`, no KEXP
row reads `/proc/driver`, and the single *new* line the next fire should gain is
`sata_bltin`'s own `fe_bootup = 1`; and the real flag **is** set in the emulated flow —
`sata_mt85xx_port_start`'s fast-boot branch stores `1` at `.text+0x32c0` right after the
`[IDE]int_val = 0x10000` / `download AACS code` markers that are present in every
C91/C93-C95/C97-C101 log — so `FE boot up OK !!` keeps printing, now with its evidence in
the same UART, and it correctly disappears in the C54/C55/C96 failure class where the
forged module used to lie.
