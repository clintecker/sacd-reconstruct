# bx510_feboot.ko — what the [FEB] module actually does (and what its WARNING means)

**Scope:** `bx510_feboot.ko` only — its symbols, init steps, what it creates, what the
`proc_dir_entry '/proc/driver' already registered` WARNING is, whether the pipeline
needs it, and whether its proc insert damages the tree for later modules.
**Not touched:** `tools/` (no edit — the one-line probe change that would settle §5 is
*proposed*, not applied), other workers' files, `emulator-kit/`, `build/`.
**Inputs:** the source on the lab VM (`/tmp/osal_d/bx510_feboot.c`, md5
`d4071d4e5a0cb22494bf6d25c1082448`, built `.ko` md5 `b1a562e1697cbf5bded3d37986a98307`);
Sony's kernel tree on the VM (`~/sony-kernel/linux-2.6.35`); the C5x/C9x UART logs;
`bdpdrv.ko`, `sata_mt85xx_mod.ko`, `sacd_read.ko` symbol/string tables.

**Headline:** the module is *not* the thing that makes `bdpdrv` see "FE boot up OK", it
is the thing that makes that message *unfalsifiable*. It creates a **duplicate**
`/proc/driver` at the head of the proc subdir list, which shadows the kernel's real
`/proc/driver` subtree from every path lookup, and it forces the FE-ready flag to `1`
before `bdpdrv` reads it.

---

## 0. Provenance (first finding: the source is untracked)

| fact | evidence |
|---|---|
| source lives **only on the VM**: `/tmp/bx510_feboot.c` + `/tmp/osal_d/` | `git ls-files | grep -i feboot` → empty; repo-wide grep for `feboot_init` matches only `decode/probe-injection.md`, `run-c94-c95.md` |
| `tools/bx510_stub_build.sh` does **not** build it (it builds parts A/B + clidrive → `/tmp/osal_a`, `/tmp/osal_b`, `/tmp/osal_c`) | the script, read in full |
| it is nevertheless **loaded in every C50+ fire** | `tools/bx510_bdpdrv_stub_probe.py:183` `insmod /res/shim/bx510_feboot.ko`; the binary travels as `--extra-file bx510_feboot.ko=/tmp/osal_d/bx510_feboot.ko` |
| vermagic `2.6.35 preempt mod_unload ARMv6` (i.e. built with the ARMv6-patched cross toolchain, not vermagic-patched after the fact) | `strings -a bx510_feboot.ko | grep vermagic` |

A VM rebuild that drops `/tmp/osal_d/` loses the only copy: the module would silently
stop existing and the probe would fail at `FEB_INSMOD`, exactly as in C50.

---

## 1. What the module does

### 1.1 Every symbol (from the built `.ko`, `readelf -sW`)

| symbol | kind | size | note |
|---|---|---|---|
| `init_module` / `feboot_init` | FUNC `.init.text` | 160 B | all the behaviour; the trace pins it: `feboot_init+0x18/0xa0` |
| `feboot_read` | FUNC `.text` | 44 B | `sprintf(page,"%d",_fg_fe_bootup); *eof=1;` |
| `cleanup_module` / `feboot_exit` | FUNC `.exit.text` | 4 B | **body is empty** — nothing is ever removed |
| `__this_module`, `__mod_{license,author,description,vermagic}`, `__module_depends` | data | — | `depends=` empty; `MODULE_LICENSE("Proprietary")` |
| **UND** `_fg_fe_bootup` | import | — | the *only* external data; resolved from the built-in `sata_bltin` |
| **UND** `proc_mkdir`, `create_proc_entry`, `printk`, `sprintf`, `__aeabi_unwind_cpp_pr0` | imports | — | `create_proc_entry` (not `create_proc_read_entry`: that is a 2.6.35 `static inline` in `include/linux/proc_fs.h`) |

Relocations confirm the shape: `.rel.init.text` has exactly two `proc_mkdir` calls, one
`create_proc_entry`, two `printk`; `.rel.text` has `sprintf` + `R_ARM_ABS32 _fg_fe_bootup`.

### 1.2 Every init step, in order

```
printk "[FEB] up (INSTRUMENT)"
drv = proc_mkdir("driver", NULL)        // ← COLLIDES with the kernel's own /proc/driver
if (!drv) { printk KERN_ERR; return 0; } // ← returns SUCCESS anyway
sat = proc_mkdir("sata", drv)            // child of the duplicate, not of the real dir
ent = create_proc_read_entry("fe_bootup", 0444, sat, feboot_read, NULL)
_fg_fe_bootup = 1;                       // ← forges the FE-bootup handshake flag
printk "[FEB] /proc/driver/sata/fe_bootup created, flag = 1"
return 0;
```

* **MMIO: none.** No `ioremap`, no register access, no IRQ, no thread, no buffer. The
  module is 100 % procfs + one `int` store. (`grep` of the source and the `.ko`'s
  relocation tables: not one MMIO symbol.)
* **Failure handling:** every error path `printk`s and `return 0`, so a failed init still
  reports `FEB_INSMOD=0`. Only `[FEB] ... failed` in the UART distinguishes it.
* **Teardown:** `feboot_exit` is empty — the entries leak, and the module can never be
  cleanly unloaded (`mod_unload` is allowed by the vermagic).

### 1.3 The `/proc/driver` WARNING — the collision is with the *kernel*, not with SATA

The module's own header comment says the guest has "NO driver/sata at all … `/proc/driver`
MISSING" and that it must therefore rebuild the path from proc root. **That premise is
false, and the warning is the proof.** Sources of truth, read on the VM:

| fact | kernel source |
|---|---|
| `/proc/driver` is created **unconditionally at every boot** by `proc_root_init()` | `fs/proc/root.c:126` — `proc_mkdir("driver", NULL);` (called from `vfs_caches_init()`, i.e. before any `module_init`) |
| this kernel's `proc_register()` **WARNs on a duplicate name but does not fail**: it `break`s out of the scan and then *still* links the new entry — `dp->next = dir->subdir; dir->subdir = dp;` — and returns 0 | `fs/proc/generic.c:559-591`, the `WARN(1, "proc_dir_entry '%s/%s' already registered")` sits at **line 583** — exactly the line the guest trace names (`generic.c:583 proc_register+0x1a0/0x220`) |
| so `proc_mkdir("driver", NULL)` returns a **valid pde for a second, duplicate `/proc/driver`** | `proc_mkdir_mode()` only NULLs the entry when `proc_register` returns < 0 (`generic.c:625-637`), which it never does here |
| name resolution takes the **first** match walking `dir->subdir` from the head | `proc_lookup_de()`, `fs/proc/generic.c:445` |
| new entries are inserted **at the head** | `proc_register()`, `generic.c:585-587` |
| therefore **after feboot loads, `/proc/driver` resolves to feboot's duplicate** | head insertion + head-first lookup |
| `readdir` does **not** dedupe — `ls /proc` lists `driver` twice | `proc_readdir_de()`, `generic.c:460-528` |
| dentries are deliberately volatile, so the next `open()` re-runs lookup | `proc_delete_dentry()` returns 1 |

And the real SATA proc tree is built by a **built-in** driver at boot, not by any module
we load:

```
drivers/sata_bltin/sata_bltin.c:120-121   int _fg_fe_bootup = 0;  EXPORT_SYMBOL(_fg_fe_bootup);
drivers/sata_bltin/sata_bltin.c:638-706   sata_bltin_init_procfs(): sata_proc_dir = proc_mkdir("driver/sata", NULL)
                                          → media_present, eject_pressed, module_installed, read_log,
                                            ide_log_en, cmd_timeout, fe_bootup, fe_fw_mem, tray_status,
                                            pb_buf_time, force_eject, stop_detect_oc
drivers/sata_bltin/sata_bltin.c:916-934   sata_bltin_init() { init_buffer(); init_procfs(); }  module_init(...)
```

`sata_bltin_init_procfs()` resolves the `driver` component through `__xlate_proc_name()`
(the pde tree, mount-independent), so it succeeds as long as `/proc/driver` exists — which
it always does. Its return value is ignored by `sata_bltin_init()`, and it prints nothing,
which is why "sata_bltin's proc prints are missing" was never evidence of failure.

**Answer to the asked question:** it is *not* a collision with the real SATA driver's proc
dir — it is a collision with the kernel's own `/proc/driver`, and it is **not harmless**:
the insert succeeds, and because the duplicate lands at the head of the list, every later
path lookup of `/proc/driver/<anything>` resolves into feboot's dir, which contains only
`sata/fe_bootup`.

The C50–C53 "MISSING" that the module was written to fix was a **mount** artifact, not a
missing proc tree:

* C50 (`bdpdrv-runC50.uart.log:168-171`): `mkdir -p /proc` → `Read-only file system`,
  `mount: mounting proc on /proc failed`, `ROOTPROC=255`; feboot was absent entirely
  (`:201-202` `can't open '/res/shim/bx510_feboot.ko'`, `FEB_INSMOD=1`).
* C51–C53: identical `ROOTPROC=255`, feboot *did* load and *did* create the pdes
  (`:238/:241/:247` etc.), and `bdpdrv` still logged
  `[v4IdeDrvInitThread]Can't open /proc/driver/sata/fe_bootup` (C51:320, C52:326, C53:340).
  **The pde tree is per-kernel, not per-mount: with no procfs mounted at `/proc`, both
  userland and `bdpdrv`'s `filp_open` see nothing.**
* C54 onwards (`:187-188` `ROOTPROC=0`): `[v4IdeDrvInitThread]FE boot up OK !!`
  (C54:357, C55:367, C91:427, C93:428, C94:427, C95:427, C96:378, C97:398, C98:398, C99:398).

So the change that flipped the observable was **mounting /proc**, not loading feboot.

---

## 2. Needed, or vestigial?

`bdpdrv` uses the *path*, not the symbol — verified, not assumed:

| fact | evidence |
|---|---|
| `bdpdrv.ko` does **not** import `_fg_fe_bootup` (0 matches in its symtab) | `readelf -sW /tmp/bdpdrv.ko | grep -c fe_bootup` → `0` |
| it opens the file by name | `strings -a bdpdrv.ko` → `/proc/driver/sata/fe_bootup` (offset-index 16543) and the failure text `[%s]Can't open /proc/driver/sata/fe_bootup`; UND `filp_open` |
| it is a one-shot init wait, not a poll | `[v4IdeDrvInitThread]Start..` → open → either `Can't open` or `FE boot up OK` → `End..` (C50:265-273 vs C98:395-401); the "poll" wording in the module's comment is wrong for this code path |
| the flag it waits on is written by the real stack | `sata_mt85xx_mod.ko` string `[IDE]set _fg_fe_bootup = 0`; `sata_mt85xx_port_start` writes it (`decode/listings/sata_mt85xx_port_start.txt:145,206,249,256`, `R_ARM_ABS32 _fg_fe_bootup`) and `sata-fw-load.md:389-393` records the success path setting it to 1 |

**Verdict: vestigial for the pipeline, and load-bearing only for a *lie*.** Without the
module nothing breaks structurally: `sata_bltin` already created the same path at boot, so
with `/proc` mounted (C54+) `bdpdrv`'s `filp_open` would succeed on the real entry. What
the module *does* add is the ordering guarantee "the flag reads 1 at insmod time", because
`_fg_fe_bootup = 1` runs unconditionally before `bdpdrv` is loaded — i.e. **`FE boot up OK`
in every C54+ run is feboot's assertion, not evidence that the FE/inter-loader handshake
happened.**

The one differential that has never been run: `/proc` mounted **and** no feboot (§5).

---

## 3. Does the WARNING damage the tree for later modules?

Not the warning itself — the duplicate insert it rides on does.

| consumer | after feboot loads | verdict |
|---|---|---|
| kernel built-ins' `/proc/driver/*` (`rtc` from `drivers/char/rtc.c`, `nvram`, `mmc/*`, `usb/*` from `mtk_hcd_src.c`) | path lookups land in the duplicate → `ENOENT` | **shadowed** (source-certain; pde pointers already held in-kernel keep working) |
| `sata_bltin`'s real `/proc/driver/sata/{media_present,eject_pressed,module_installed,read_log,ide_log_en,cmd_timeout,fe_bootup,fe_fw_mem,tray_status,pb_buf_time,force_eject,stop_detect_oc}` | shadowed; only `fe_bootup` is re-created under the duplicate | **shadowed** |
| corroboration | `sata_bltin`'s `proc_read_fe_bootup()` printks `fe_bootup = %d` whenever the value changes (`sata_bltin.c:486-491`) — that line appears in **no** run log, i.e. the real entry was never the one being read (`grep -n "fe_bootup = " bdpdrv-run*.uart.log` → empty) | consistent with shadowing |
| `bdpdrv`'s `/proc/driver/sata/force_eject` read (string `31271`) | resolves into the duplicate → `ENOENT` | **inferred breakage** (the string exists; no log line proves when it is read — no `force_eject` error appears in C9x) |
| `sacd_read.ko` | registers **no proc entries at all** — 0 proc symbols in its symtab, and its only `/proc` string is the error text `[%s]Symbol "%s" not found in /proc/allsyms!!`; it publishes a char device (`/dev/sacd_read`, 10:201), not proc | **unaffected** — the task's premise that sacd_read registers proc entries is not supported by the binary |
| `remove_proc_entry("driver", NULL)` from any later module | would remove feboot's duplicate (first name match), leaving the kernel's dir — asymmetric but not corrupting | low risk |

Cost paid in every fire regardless: a `WARN` + `dump_stack` in the UART/evidence bundle
(C98:317-328) that has to be re-explained each run, and it is the only `cut here` block in
the log, so it drowns real warnings.

---

## 4. Recommendation

**Fix (minimal, preferred over literal "drop") — stop creating `driver`, and stop forging
the flag.** Concretely, in the (currently untracked) source: delete the two `proc_mkdir`
calls and the `_fg_fe_bootup = 1` store; if an instrument marker is still wanted, register
a name that cannot collide, e.g. `create_proc_read_entry("feboot_instr", 0444, NULL,
feboot_read, NULL)` at proc root. Then **track the source** (`tools/bx510_feboot.c` + a
build stanza) so the module stops being a `/tmp` artifact.

| option | exact consequence |
|---|---|
| **A. Drop** (delete the `insmod` line, keep the file as a tombstone) | WARNING gone; `/proc/driver` intact for kernel built-ins, `sata_bltin` and `bdpdrv`'s `force_eject`; `bdpdrv` reads the **real** flag, so `FE boot up OK` becomes true evidence (and will *disappear* in runs where the handshake really did not complete — that is the point). Requires `/proc` mounted (already true from C54+). Nothing else in the load order depends on it. |
| **B. Fix** (as above: no `driver`/`sata` mkdir, no flag write, non-colliding entry name) | Keeps a `[FEB]` marker for grepping while removing both the shadowing and the forgery; keeps one printk. Same behavioural state as A for `bdpdrv`. |
| **C. Keep as-is** | Every fire keeps a false `FE boot up OK`, keeps `/proc/driver/*` (rtc/nvram/mmc/usb + 11 of 12 SATA entries) path-unreachable, keeps `bdpdrv`'s `force_eject` broken, and keeps a WARN dump in the evidence. Any conclusion that rests on "the driver saw the FE booted" is unsound while it is loaded. |

If A is chosen and the pipeline turns out to need the marker, B is the fallback — never C.

---

## 5. The decisive experiment (not run here — it is a probe edit, and `tools/` is out of scope)

Candidate: *feboot is unnecessary; `sata_bltin` already provides the path.*
One fire, one changed line, one command added:

```
- "insmod /res/shim/bx510_feboot.ko; echo FEB_INSMOD=$?",
+ "echo FEB_SKIPPED",                     # feboot not loaded at all
+ "ls -ld /proc/driver /proc/driver/sata | head -4; echo DRVLS=$?",
+ "ls /proc/driver/sata | tr '\\n' ' '; echo SATALS=$?",
+ "cat /proc/driver/sata/fe_bootup; echo CATREAL=$?",
```

* verdict **needed** if `[v4IdeDrvInitThread]Can't open /proc/driver/sata/fe_bootup`
  appears (and `SATALS` is empty).
* verdict **vestigial** if `[v4IdeDrvInitThread]FE boot up OK !!` appears with `SATALS`
  listing the twelve real entries (and `CATREAL` prints `0` — the real flag, un-forged).
* the `ls /proc/driver` listing also settles §3 directly: the shadowed case shows exactly
  one child (`sata`); the unshadowed case shows `rtc`, `nvram`, `mmc`, `usb`, `sata` where
  available.

Until that fire exists, this document's §3 shadowing claim rests on kernel source that was
read on the VM (not inferred from memory) plus the absence of `sata_bltin`'s own
`fe_bootup = %d` printk in every log.

---

## Correction to record (so the next worker does not re-derive it)

The module's header comment — "the guest proc tree has NO `driver/sata` at all
(`procc.sh: /proc/driver MISSING`) … the FEB module must create the FULL path" — conflates
*two different things*: (a) the kernel's proc **pde tree**, which exists from
`proc_root_init()` in every boot and which the C51+ `WARNING` proves exists, and (b) the
**procfs mount** at `/proc`, which failed (`ROOTPROC=255`) in C50–C53 because the rootfs
is read-only (`mkdir: can't create directory '/proc': Read-only file system`). Everything
feboot did in C50–C53 was invisible for lack of (b), and (b) was fixed in C54 by the probe,
not by the module.
