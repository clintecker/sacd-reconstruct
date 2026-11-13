# kernel-fb-enumeration.md — what the guest kernel does when `_mt8530fb_probe` calls `register_framebuffer`

**Question answered:** `fb-surface.md` §4.3 claims "the fb probe needs NO model
rows" and gates success on two UART lines. This document verifies that claim
against the *kernel side* — the fbdev core in the actual guest kernel image —
and re-derives the gate, because **the two UART lines `fb-surface.md` gates on
are dead code in this build** (§5, VERIFIED). G2 is still gateable, from a
different observable.

Every claim is labelled **VERIFIED** (instruction site / live capture in this
repo's logs) or **INFERRED** (reasoning that names the experiment which would
settle it).

**Subject artifacts**

| Artifact | Identity | How obtained |
|---|---|---|
| guest kernel | `kernel.uImage` sha256 `10bb0fba4eb26c5b1ebf798f4d4669dc8b5899d520be294d333c318a360be2d7` 2,285,632 B | `make vm-pull-file FILE=/tmp/images-fe/kernel.uImage DEST=/tmp/kimg/` |
| raw vmlinux | sha256 `cd1cf0cb47d88c14877d49beb0c10a1507424c51892e7fec35347b26c05577de`, 4,676,960 B, no ELF headers | `decode/kernel_decode_image.py /tmp/kimg/kernel.uImage /tmp/kimg/kdec` |
| kernel symbols | 25,817 built-in symbols | `decode/kernel_decode_kallsyms.py /tmp/kimg/kdec/vmlinux.bin` |
| driver | `bdpdrv.ko` sha256 `6604f6cd…a72cf54` (same subject as `fb-surface.md`) | `/tmp/bdpdrv/bdpdrv.ko` (Mac scratch, cited by address) |
| live runs | `bdpdrv-run{C50..C55,C91,C93,C94,C95}.uart.log` | this repo |

Kernel banner (from the image and the runs): `Linux version 2.6.35
(aokino@rvds241) (gcc version 4.5.1) #1 PREEMPT Thu Sep 20 09:03:01 JST 2018`,
x86-host emulated `ARMv6-compatible processor [410fb767] ARMv7`, `mem=512M`.

---

## 0. Verdict in one screen

| Question | Answer | Status |
|---|---|---|
| Does this kernel have a complete fbdev core? | **Yes** — `fbmem_init`, `register_framebuffer`, `unregister_framebuffer`, `fb_init_device`, `fb_alloc_cmap`/`fb_dealloc_cmap`, `__ksymtab_fb_class`, `fb_fops`, `/proc/fb` — all present (§2) | VERIFIED |
| Is the sysfs/device path `register_framebuffer` uses present? | **Yes** — `device_create` → `device_create_vargs` → `device_add` → `kobject_add` → `sysfs_create_dir`, plus `device_create_file` for the 12 fb attributes | VERIFIED |
| Can `register_framebuffer` fail here? | **It has exactly four return paths**: `-ENXIO` (num_registered_fb == 32), `-ENOSYS` (foreign-endian flag), `-ENODEV` (`fbops == NULL`), and `0`. None of the three failures is reachable in this rig, and **none is influenced by anything the emulated machine provides** (§3) | VERIFIED |
| Does fb registration need `/sys`? | **No.** Every sysfs/device failure is *non-fatal* (warn + continue, still returns 0), and `fb_init_device` cannot return an error at all (§4) | VERIFIED (branch) / INFERRED (sysfs-unmounted is not a device_add error) |
| Does the model owe anything for G2? | **No rows, no state.** The whole probe is `vFBDbgLog` × 4 + `register_framebuffer`; the kernel path touches no MMIO | VERIFIED |
| Is G2 gateable from UART? | **Not with the strings `fb-surface.md` names** — they sit behind `g_fgEnableDebug`, which is **0 and has no writer in the module**. G2 *is* gateable from UART via `cat /proc/fb` → `0 mt8530` (§5, §6) | VERIFIED |
| Is `BDPDRV_INSMOD=0` evidence of registration? | **No.** `mt8530fb_init` discards `_mt8530fb_probe`'s return value and always returns 0 | VERIFIED (§5.2) |

---

## 1. Provenance, and a correction to the task's assumption

The task suggested using "the `/proc/kallsyms` capture in the C9x runs
(60,697 symbols)". **Those runs never captured the symbol table.** What they
captured is the *count* plus two greps:

```
/res/proc/kallsyms                                     bdpdrv-runC93.uart.log:1839
208            <- grep -c sata  /res/proc/kallsyms      :1846
60697          <- grep -c .     /res/proc/kallsyms      :1847
```

60,697 is `grep -c .` over the live table with `libata.ko`, `sata_mt85xx_mod.ko`,
`osal_stub*.ko`, `drvcli.ko`, `bdpdrv.ko` loaded (kernel alone decodes to
25,817). There is no fb symbol grep anywhere in any run.

So the fb symbol inventory below comes from the **kernel image itself**, which
is strictly better evidence: it is the exact binary the runs booted, and the
kallsyms tables are present in the raw image even though the ELF headers were
stripped (`kernel_decode_kallsyms.py` locates every table from a structural
invariant: `token_index` fixpoint → `token_table` fixpoint → markers →
`num_syms` → addresses ending at `stext` = `0xc0008000`).

Decode report (reproducible):

```
image /tmp/kimg/kdec/vmlinux.bin
  stext           0xc0008000  (file 0)
  kallsyms_addrs  0x378200..0x391564  (25817 entries)
  kallsyms_num    0x391570  value 25817
  kallsyms_names  0x391580..0x3d77e0
  kallsyms_mark   0x3d77e0  (101 entries)
  token_table     0x3d7980..0x3d7d01
  token_index     0x3d7d10
```

**A correction to my own first read of the logs** (recorded so the next worker
does not repeat it): `bdpdrv-runC93.uart.log:1823` reads `1CAT_FB=0`. That is
**not** `/proc/fb`. The script that produced it (`/tmp/procc.sh` on the lab VM)
is:

```
7   cat /proc/driver/sata/fe_bootup; echo CAT_FB=$?
```

The `1` is the *content* of the SATA `fe_bootup` proc entry (printed without a
trailing newline), and `CAT_FB=0` is that `cat`'s exit status. **No run has
ever read `/proc/fb`.** The `1` is harness residue, not a registered
framebuffer.

---

## 2. The fb framework in this kernel build

Symbols decoded from the image (addresses are VAs, `stext = 0xc0008000`):

| Symbol | VA | Note |
|---|---|---|
| `fbmem_init` | `0xc0015310` | `fs_initcall` — registers `/proc/fb`, char major 29, `fb_class` |
| `register_framebuffer` | `0xc01a055c` | the call `_mt8530fb_probe` makes |
| `unregister_framebuffer` | `0xc01a0300` | teardown path (`_mt8530fb_probe_uninit`) |
| `remove_conflicting_framebuffers` | `0xc01a03e4` | called from `register_framebuffer`, **void** |
| `fb_init_device` | `0xc01a21c0` | creates the 12 sysfs attribute files |
| `fb_cleanup_device` | `0xc01a224c` | |
| `lock_fb_info` | `0xc019fa4c` | returns 0 when `fbops == NULL` |
| `fb_alloc_cmap` / `fb_dealloc_cmap` | `0xc01a1648` / `0xc01a1604` | **not on the registration path** |
| `fb_set_var`, `fb_ioctl`, `do_fb_ioctl`, `fb_open`, `fb_release`, `fb_mmap`, `fb_pan_display`, `fb_notifier_call_chain` | `0xc01a0754`, `0xc01a0ff0`, `0xc01a09e8`, `0xc019fa84`, `0xc019fa00`, `0xc019fbb0`, `0xc019f8d4`, `0xc019f644` | the ops the driver's 15 populated `fb_ops` slots dispatch into |
| `proc_fb_open`, `fb_seq_show` | `0xc01a01c4`, `0xc01a01d4` | `/proc/fb` reader |
| `__ksymtab_fb_class` | `0xc0423008` | `fb_class` is EXPORT_SYMBOL'd; the variable itself is **not** in kallsyms — this build has no `KALLSYMS_ALL` (decoded type letters: `T` 7700, `t` 9776, `r` 8191, `R` 41, `W` 108, `A` 1, and **0** of `b/B/d/D`) |

Device/sysfs path present:

| Symbol | VA |
|---|---|
| `sysfs_create_dir` | `0xc00e1274` |
| `kobject_add` / `kobject_init_and_add` | `0xc018ed18` / `0xc018ecb8` |
| `device_add` / `device_register` | `0xc01c266c` / `0xc01c2b2c` |
| `device_create` / `device_create_vargs` | `0xc01c2bfc` / `0xc01c2b44` |
| `device_create_file` / `device_remove_file` | `0xc01c2080` / `0xc01c1ffc` |
| `dev_set_name` / `dev_set_drvdata` | `0xc01c1a98` / `0xc01c4990` |
| `__class_create` | `0xc01c5b08` |
| `sysfs_init` | `0xc0011cb4` — `CONFIG_SYSFS` is built in |

**Absent, and it matters:** `grep -cE ' (fbcon|fb_console|cfb_|sys_fillrect|sys_copyarea|bitfill_aligned)$'`
over the 25,817 symbols returns **0**. There is **no framebuffer console** in
this kernel (boot log: `Console: colour dummy device 80x30`, `console [ttyMT0]
enabled`). Consequence: registering an fb cannot trigger fbcon binding
(`take_over_console`, nor any `fb_alloc_cmap` for a console palette) — the two
classic ways an fb registration disturbs the boot console are structurally
absent. It also means nothing in this build reads two `fb_info` fields the
kernel pokes at registration (§3.6).

---

## 3. `register_framebuffer` decoded — every failure path and whether the emulated box can reach it

`register_framebuffer` = `0xc01a055c..0xc01a0754` (504 B), the whole body
(2.6.35 inlined `do_register_framebuffer` into it — there is no
`do_register_framebuffer` symbol). Instruction-by-instruction:

| # | Site | What happens | Return |
|---|---|---|---|
| 1 | `0xc01a056c` `ldr r3,[num_registered_fb]`; `cmp r3,#32`; `mvneq r0,#5` | `num_registered_fb == FB_MAX(32)` → `-ENXIO` | **-6** |
| 2 | `0xc01a057c` `ands r5,r5,#0x100000`; `ldreq …`; `mvneq r0,#25`(`0xc01a0594`) | `flags & FBINFO_FOREIGN_ENDIAN` → `printk("%s: enable CONFIG_FB_BIG_ENDIAN to support this framebuffer\n", fix.id)` → `-ENOSYS` | **-38** |
| 3 | `0xc01a059c` `bl remove_conflicting_framebuffers` | `remove_conflicting_framebuffers(apertures, fix.id, flags&0x100000)` — **return value never tested** | — |
| 4 | `0xc01a05a8` | `num_registered_fb++` | — |
| 5 | `0xc01a05b4`–`0xc01a05cc` | scan `registered_fb[0..31]` for a NULL slot → `i` (`registered_fb` at `0xc0495520`, base of the `num_registered_fb`+array block) | — |
| 6 | `0xc01a05d8`,`0xc01a05e8`,`0xc01a05f8` | `fb_info->node = i`; `__mutex_init(&fb_info->lock, "&fb_info->lock")`; `__mutex_init(&fb_info->mm_lock, "&fb_info->mm_lock")` (mutexes at `fb_info+8` / `+0x14`) | — |
| 7 | `0xc01a0604`–`0xc01a0614` | `device_create(fb_class, fb_info->device, MKDEV(29,i), NULL, "fb%d", i)` — `r2 = i | 0x01d00000` ⇒ **FB_MAJOR = 29 hardcoded**; `r1 = [fb_info+0x220]` (parent `device`), `r3 = 0`, fmt `"fb%d"` @ `0xc04013a0` | — |
| 8 | `0xc01a0618` `cmn r0,#4096; bls` → `0xc01a0628` warn → `0xc01a0634` clear `fb_info->dev`; else `0xc01a0644 bl fb_init_device` | `IS_ERR(dev)` → `printk("<4>Unable to create device for framebuffer %d; errno = %ld\n")`, `fb_info->dev = NULL` — **non-fatal, falls through** | — |
| 9 | `0xc01a0648`–`0xc01a0690` | if `fb_info->pixmap.addr == NULL`: `kmalloc(FBPIXMAPSIZE=8192)`; on success set `size 8192/buf_align 1/scan_align 1/access_align 32/flags 1`; **failure ignored**; then `pixmap.offset = 0` | — |
| 10 | `0xc01a0694`,`0xc01a06a4` | `if (!*(int*)(fb_info+0x1bc)) *(int*)(fb_info+0x1bc) = -1;` and the same for `+0x1c0` — bare bookkeeping (see §3.6) | — |
| 11 | `0xc01a06b4`–`0xc01a06d4` | `INIT_LIST_HEAD(&fb_info->modelist)` (`+0x210/+0x214`) if unset | — |
| 12 | `0xc01a06dc`–`0xc01a06f0` | `fb_var_to_videomode(&mode, &fb_info->var)`; `fb_add_videomode(&mode, &fb_info->modelist)` — **return ignored** | — |
| 13 | `0xc01a0700` | `registered_fb[i] = fb_info` | — |
| 14 | `0xc01a0704`; `cmp r0,#0`; `mvneq r0,#18` | `if (!lock_fb_info(fb_info)) return -ENODEV` — i.e. `fb_info->fbops == NULL` | **-19** |
| 15 | `0xc01a071c`,`0xc01a0724`,`0xc01a0728` | `fb_notifier_call_chain(FB_EVENT_FB_REGISTERED = 5, &event)`; `mutex_unlock`; `mov r0,#0` | **0** |

`lock_fb_info` (`0xc019fa4c..0xc019fa84`) — VERIFIED:

```
c019fa5c bl mutex_lock
c019fa60 ldr r4,[r4,#0x21c]      ; fb_info->fbops (2.6.35 offset 0x21c)
c019fa64 cmp r4,#0                 ; NULL -> unlock, return 0
c019fa7c mov r0,#1                 ; else 1
```

**There is no other return path.** `r0` at `0xc01a072c` is either `-6`, `-38`,
`-19`, or `0`.

### 3.1 Can the emulated environment reach any of the three failures?

| Failure | Needs | Our state | Reachable by the model? |
|---|---|---|---|
| `-ENXIO` (`num_registered_fb == 32`) | 32 live framebuffers | this is the **first and only** registration applet; `registered_fb[]` is all-NULL at load (`/proc/fb` reader `fb_seq_show` walks exactly that array) | **No** — machine-independent |
| `-ENOSYS` (foreign endian flag) | `fb_info->flags & 0x100000` | driver writes `flags = 1` explicitly: `mov r8,#1` @ `0x14614c` → `str r8,[r4,#0x508]` @ `0x146164` (`t_pal+0x508` = `fb_info+4`); and `&_fb_info` is `memset` to 0 first (`mt8530fb_init`, `.init.text+0x28`) | **No** — the flag is a driver-written field, not a machine property |
| `-ENODEV` (`fbops == NULL`) | `fb_info->fbops == NULL` at registration | driver stores `&_mt8530fb_ops` (`.data+0x57f20`) into `fb_info+0x21c` at `0x146140` (`str r7,[r4,#0x720]`), inside `_mt8530fb_init_fbinfo`, which runs **before** the probe in both call chains (`mt8530fb_init` → `mt8530fb_reset` @ `.init.text+0x2c` → `_mt8530fb_init_fbinfo`, `fb-surface.md` §2.1; then `_mt8530fb_probe` @ `.init.text+0x34`; and `u4FbProbeInit` @ `.text 0x149fb0` / `0x149fb4`). It is the **only** store to that slot in the module | **No** — set by the driver, never cleared |

Every remaining branch (§3 table rows 3, 5, 8, 9, 12, 15) either ignores its
callee's return or handles the failure inline and continues to the `return 0`
at `0xc01a0728`. **In particular the two allocations on this path —
`kmalloc(8192)` for `fb_info->pixmap.addr` and the ~52 B `fb_videomode` — are
both non-fatal.** RAM is not a lever: the guest boots with `mem=512M`,
`Memory: 512460k/512460k available` (`bdpdrv-runC93.uart.log:16-18`).

`fb_alloc_cmap` is **not** on this path (it is a console/driver API); the
driver's probe does not call it either — the probe's complete relocation set is
`vFBDbgLog` × 4 + `register_framebuffer` × 1, VERIFIED:

```
0x1460a0 push {r3,lr}
0x1460a4/a8/ac  ldr r0/r1/r2 = (' %10s  %10d \n', "_mt8530fb_probe", 1717)
0x1460b0 bl  vFBDbgLog
0x1460b4 ldr r0,= &_fb_info (.bss 0x82234)
0x1460b8 bl  register_framebuffer          <-- the only kernel call
0x1460bc cmp r0,#0 ; 0x1460c0 bge success
0x1460c4 ldr r0,='_mt8530fb_probe() fail: cannot register mt53fb!\n'
0x1460c8 bl  vFBDbgLog
0x1460cc mvn r0,#5                          ; return -6 (-ENXIO), mirroring the kernel
0x1460d0 pop {r3,pc}
0x1460d4..0x1460e0  vFBDbgLog(' %10s  %10d \n', "_mt8530fb_probe", 1744)
0x1460e4 ldr r0,='_mt8530fb_probe(): probe init OK!\n'
0x1460e8 bl  vFBDbgLog
0x1460ec mov r0,#0
```

No load or store in the probe resolves to a physical address: the function body
is `0x6c` bytes of register moves, one literal-pool load of `&_fb_info`, and
five branches. (`fb-surface.md` §2.5 reached the same conclusion for the whole
`_mt8530fb_*` family via `resolve_addrs.py --func`.)

### 3.2 `fbmem_init` — the boot-time precondition

`0xc0015310..0xc00153b8`, VERIFIED:

```
0xc0015324 ldr r0,="fb"  (0xc0401406);  bl proc_create_data(...,&fb_proc_fops)  ; /proc/fb
0xc0015334 mov r0,#29    ; FB_MAJOR
0xc0015348 bl __register_chrdev(29, 0, 256, "fb", &fb_fops)
0xc001534c cmp r0,#0 ; beq skip
0xc001535c bl printk("<3>unable to get major %d for fb devs\n", 29)   ; NON-FATAL
0xc0015370 bl __class_create(0, "graphics", &fb_class)
0xc0015374 cmn r0,#4096 ; bls skip
0xc0015388 bl printk("<4>Unable to create fb class; errno = %ld\n")  ; NON-FATAL
0xc0015390 fb_class = NULL
0xc0015394 mov r0,#0    ; fbmem_init ALWAYS returns 0
```

Live corroboration that it ran: `/proc/devices` in the guest lists `29 fb`
(`bdpdrv-runC93.uart.log:1582`) — present in **all ten** bdpdrv runs
(C50–C55, C91, C93, C94, C95; `grep -c '29 fb'` = 1 in each, 0 in the
six stub/trace runs, which dump no `/proc/devices`). So the
char major is registered in the emulated boot, `fb_class` creation was reached,
and `/proc/fb` exists independently of whether any framebuffer is registered.

Note the asymmetry that makes §4 possible: **`fbmem_init` tolerates both of its
own failures** (missing major, missing class), and with `fb_class == NULL`
`device_create(NULL, …)` still succeeds — a device with no class directory.

---

## 4. Does registration need sysfs? No — three independent reasons

1. **`device_create` failure is explicitly non-fatal.** `0xc01a0618` `cmn
   r0,#4096; bls fb_init_device` — i.e. *not* `IS_ERR` → call `fb_init_device`;
   the error arm at `0xc01a0628` only warns and clears `fb_info->dev`, then
   rejoins at `0xc01a0648`. Registration continues and returns 0. (VERIFIED.)
2. **`fb_init_device` cannot fail.** `0xc01a21c0..0xc01a224c`: it calls
   `dev_set_drvdata(dev, info)`, sets a bit at `fb_info+0x228`, then loops 12
   `device_create_file()` calls over the attribute table at `0xc046e9cc`
   (stride `0x14` = 20 B). On the first non-zero return it *rolls back* the
   files it already made (`device_remove_file` at `0xc01a221c`), clears the bit,
   and still executes `mov r0,#0` at `0xc01a2240`. There is no other epilogue —
   **one exit, `r0 = 0`**. And `register_framebuffer` ignores its return anyway.
   (VERIFIED.)
3. **`/proc/fb` is independent of sysfs.** It is created by `fbmem_init`
   (`proc_create_data`), and its only exit-point is `fb_seq_show`:
   `seq_printf(m, "%d %s\n", info->node, info->fix.id)` (format string at VA
   `0xc041574e` = `'%d %s\n'`, VERIFIED) — i.e. **`0 mt8530`** for this
   driver (`fix.id = "mt8530"`, `fb-surface.md` §2.3).

The 12 attribute files (VERIFIED names, from the `fb_attrs` table at
`0xc046e9cc`): `bits_per_pixel`, `blank`, `console`, `cursor`, `mode`, `modes`,
`pan`, `virtual_size`, `name`, `stride`, `rotate`, `state` — so
`/sys/class/graphics/fb0/{stride,virtual_size}` in `fb-surface.md`'s G4 is
exactly this table, and nothing else.

**State of `/sys` in the C-runs:** never mounted. `bdpdrv-runC93.uart.log:202-207`
shows the whole mount table at that point: `rootfs on /`, `tmpfs on /res`,
`tmpfs on /dev`. `/proc` is mounted later by `procc.sh`
(`proc on /res/proc`, `proc on /proc`). The runs therefore exercise
registration with no `/sys` present.

**INFERRED (settled by the G4 run below):** in 2.6.35 a missing sysfs *mount* is
not a `device_add` error — sysfs dirents are built in kernel memory whether or
not the filesystem is mounted, and `sysfs_create_dir` (`0xc00e1274`) falls back
to the root kset (`ldreq r6,=0xc04615e0`) when the kobject has no parent kset.
Either way §4.1/§4.2 mean it cannot fail the registration.

**Not needed for G2, but needed for G4:** `mkdir -p /sys && mount -t sysfs sysfs
/sys` (kernel support VERIFIED: `sysfs_init` @ `0xc0011cb4`).

---

## 5. The UART signature of SUCCESS vs FAIL — and the dead-logging trap

### 5.1 Kernel-side signatures (printk → ttyMT0 console)

`printk` output does reach the captured UART — `console [ttyMT0] enabled`,
`_mt85xx_uart_console_init:register console ok` and the whole boot log are in
the same files. The kernel can emit exactly four lines on our path:

| Line (exact) | Level | Meaning | Fatal? |
|---|---|---|---|
| `unable to get major 29 for fb devs` | `<3>` | `fbmem_init`: char major 29 gone — fbdev entirely unavailable | boot-time; would also kill G3 |
| `Unable to create fb class; errno = -<n>` | `<4>` | `fbmem_init`: no `/sys/class/graphics` | no |
| `Unable to create device for framebuffer 0; errno = -<n>` | `<4>` | `register_framebuffer`: `device_create` failed (sysfs/class) | **no** — registration still returns 0 |
| `mt8530: enable CONFIG_FB_BIG_ENDIAN to support this framebuffer` | `<3>` | `-ENOSYS` foreign-endian arm | would accompany the driver fail line |

**There is no success printk.** The string table of the image contains no
"frame buffer device" / "Console: switching to colour" text at all
(`strings -n 8 vmlinux.bin | grep -i 'frame buffer device'` → empty), and
`register_framebuffer`'s only two `printk` calls are the foreign-endian error
and the `device_create` warning. **A successful registration is silent at the
kernel level.**

### 5.2 Driver-side signatures — VERIFIED strings, but behind a gate that is OFF

Exact bytes (from `bdpdrv.ko`, `.rodata.str1.1`):

```
fail    +0x54ea5 : '_mt8530fb_probe() fail: cannot register mt53fb!\n'
success +0x54ed6 : '_mt8530fb_probe(): probe init OK!\n'
tagline +0x54a5c : ' %10s  %10d \n'      (args: "_mt8530fb_probe", 1717 / 1744)
```

`vFBDbgLog` (`0x149fe0`, 120 B) decides whether any of them is printed:

```
0x149fec  r4 = buf
0x149ffc  bl memcpy(buf, "[FB] ", 6)          ; .rodata+0x12b9cc = "[FB] "
0x14a00c  bl memset(buf+5, 0, 250)
0x14a010  ldr r3,= g_fgEnableDebug (.bss+0x82888)
0x14a014  ldrb r3,[r3]
0x14a018  cmp  r3,#0
0x14a01c  beq  0x14a040        <-- RETURNS WITHOUT PRINTING
0x14a034  bl vsnprintf(buf+5, 250, fmt, ap)
0x14a03c  bl UTIL_Printf(buf)  ; -> vprintk -> ttyMT0
```

So the emitted line is `"[FB] " + formatted`, and when the gate is 0 **nothing
is emitted at all** — not the success line, and not the fail line either.

`g_fgEnableDebug` is `.bss+0x82888`, `STB_GLOBAL`, 1 byte. Findings:

* **No writer exists in the module** (VERIFIED by whole-module scan): the only
  code sites that materialise the address `0x82888` are `vFBDbgLog` itself
  (feeds the `ldrb` above) and two ESM functions that use it as a base for the
  *next* object (`ldr r2,[r1,#4]!` → `0x8288c`); no `str`/`strb` targets it, no
  `movw/movt` sequence builds it, no data-section word points at it.
* **It is not exported** — absent from `bdp_exports.syms` (1,397 exported
  symbols), so no helper module can resolve it by name at load time.
* **Empirically it is 0**: `grep -l '\[FB\]' ` over **all 19** captured UART
  logs in `evidence/bx510-guest/bdpdrv/` matches **none**, while
  `bdpdrv.ko` definitely initialised (`BDPDRV_INSMOD=0`,
  `bdpdrv-runC93.uart.log:1533`; `[FBM]…` lines from the driver's own frame
  buffer manager at `:500-501`; and
  `[OSAL_STUB] x_memset … caller=mt8530fb_init` at `:1069`, where `%pf` is a
  kallsyms-resolved return address).

**Consequence — this corrects `fb-surface.md` §4.3:** its G1 ("`_mt8530fb_probe`
tag appears without the fail line") and G2 ("`probe init OK!` present") are
**unsatisfiable in this build**. The strings exist and are decodable, but the
logger is dead. Do not read their absence as a failure of the fb path, and do
not read `BDPDRV_INSMOD=0` as a success:

```
mt8530fb_init (.init.text 0x0..0x88, reloc-resolved):
  +0x1c mov r1,#584                     ; sizeof(fb_info) = 0x248
  +0x24 ldr r0,= &_fb_info (.bss 0x82234)
  +0x28 bl  __memzero                   ; &_fb_info wiped before use
  +0x2c bl  mt8530fb_reset              ; -> _mt8530fb_init_fbinfo (flags, fbops)
  +0x34 bl  _mt8530fb_probe             ; UNCONDITIONAL; return value DISCARDED
  +0x40 bl  _MT8530_Gfx_FramBuf_GetCmdBuf
  +0x4c bl  kmem_cache_alloc            ; 4096-byte buffer
  +0x5c bl  x_memset(..., 0, 4096)      ; <-- the stub's "caller=mt8530fb_init" trace
  +0x64 bl  vFBDbgLog                   ; also gated
  +0x68 mov r0,r4                       ; r4 == 0; init ALWAYS returns 0
```

`mt8530fb_init` never inspects `_mt8530fb_probe`'s `r0`, so a `-6` from
`register_framebuffer` is invisible to the loader. (VERIFIED.)

**The `+0x5c` `x_memset` is the witness that the probe ran and returned.** It is
the post-probe allocation in `mt8530fb_init`, and it is traced by our own OSAL
stub as
`[OSAL_STUB] x_memset dst=c6259020 n=0x1000 caller=mt8530fb_init`
(`bdpdrv-runC93.uart.log:1069`; same line in C50–C55, C91, C94, C95) —
`n = 0x1000`, `dst` a lowmem `kmalloc` address, caller resolved by `%pf`. Any
trace line from *after* `+0x34` proves `_mt8530fb_probe` executed and returned
normally. It does **not** prove `r0 == 0` — only `/proc/fb` does (§5.3).

**VERIFIED:** `_mt8530fb_probe` ran and returned in the C-runs (the `+0x5c`
witness above).

**INFERRED:** `device_create`/sysfs succeeded in those runs — the only evidence
is the *absence*, in all nineteen logs, of the ungated
`<4>Unable to create device for framebuffer 0` printk. That inference has no
positive confirmation yet; `/proc/fb` (§5.3) is what settles it.

### 5.3 Gate that does work — `/proc/fb`, from the same UART log

| Gate | Command | PASS | FAIL |
|---|---|---|---|
| **G2** (primary, decisive) | `cat /proc/fb` | exactly one line: `0 mt8530` | empty (`0` lines) |
| G2 control (**run this too**) | `cat /proc/fb` *before* `insmod bdpdrv.ko` | empty | any line ⇒ the array was already occupied; the G2 comparison is void |
| G3 | `grep 29 /proc/devices`; `mknod /dev/fb0 c 29 0; ls -l /dev/fb0` | `29 fb`; `crw-r--r-- … 29, 0` | missing major / mknod fails |
| G3′ (optional, do **not** over-read) | `ls -l /dev/fb0` and stop | — | **do not `cat`/`open` it**: `fb_open` runs `_mt8530fb_open` (4 allocations, `fb-surface.md` §3.2) — a different lane |
| G4 (needs a mount) | `mkdir -p /sys && mount -t sysfs sysfs /sys && cat /sys/class/graphics/fb0/{name,stride,virtual_size,state}` | `mt8530`, `7680`, `1920,2160`, `0` | missing files ⇒ `device_create`/`fb_init_device` arm |

`/proc/devices` already shows `29 fb` in all ten bdpdrv runs, so G3's major line
is a **pre-existing** observation, not a new gate — only the `mknod` + `ls -l`
half is untested.

`state` is one of the 12 attribute names and is player-parity `0`
(`fb-surface.md` §2.3 quotes the same `state 0`); it is listed because it costs
nothing once `/sys` is mounted.

**Gate-numbering collision, worth stating once:** `decode/fb_gates.py` (a peer
artifact, untracked at the time of writing) numbers *different* gates —
G1 = `GFX_HwReset` complete, G2 = the UART registration lines, G3 =
`GFX_CmdQueAction`, G4 = `GFX_HwGetIdle` — while `fb-surface.md` §4.3 uses
G1/G2 for the two probe log lines and G3/G4 for `/proc/fb` and sysfs. **This
document uses `fb-surface.md`'s numbering.** Independent agreement worth
recording: `fb_gates.py:gate_g2()` reads the same `g_fgEnableDebug` gate
(`.text 0x14a010-0x14a01c`) and returns **INDETERMINATE** — not PASS, not FAIL —
for exactly the reason in §5.2.

Chosen greps (all safe under BusyBox `grep`, no `tail`, which the guest lacks —
`bdpdrv-runC93.uart.log:1661-1663` shows `/bin/sh: tail: not found`):

```
/proc/fb ................. grep -c . /proc/fb        -> 1        (PASS)  / 0 (FAIL)
/proc/fb content ......... grep '^0 mt8530$'         -> match
dead driver lines ........ grep '\[FB\] _mt8530fb_probe() fail'   -> must NOT match, but
                                                                    never matches anyway (gate off)
kernel warn .............. grep 'Unable to create device for framebuffer'  -> must NOT match
```

---

## 6. Verdict

**Is G2 gateable from UART alone? Yes — but only via `/proc/fb`, not via the
driver's log lines.**

* Registration success has **no kernel printk** in this build (§5.1) and the
  driver's own success line is behind a permanently-zero debug gate (§5.2).
  Therefore the *only* UART-visible, uncompromised witness of
  `register_framebuffer` returning 0 is the `/proc/fb` listing
  (`"%d %s\n"` → `0 mt8530`), which needs `/proc` mounted — already true in
  C54+ runs.
* G4 needs one extra guest step (`mount -t sysfs`), and is worth having because
  it reads the same 12 attributes the player exposes.
* The fail side is asymmetric: `-6` produces **no** UART output whatsoever
  (init discards the return; the log is gated). Only the *sysfs* failure arm
  leaves a printk. So G2 must be a **positive** gate (`0 mt8530` present), not
  an absence gate. Any brief that says "success = no fail line" is inverted.

**Does the model owe anything for G2? No.**

* The probe is `vFBDbgLog` ×4 + `register_framebuffer`; the entire kernel path
  touches **no MMIO**, no timer, no IRQ.
* All three `register_framebuffer` failure modes are decided by *driver-written
  fields* (`flags`, `fbops`) or by global bookkeeping (`num_registered_fb`) —
  none is a machine property. RAM (512 MB) and I/O topology are irrelevant.
* The kernel-side dependencies fbdev has on the machine are all **non-fatal**
  even if they break: `device_create`, `fb_init_device`, pixmap `kmalloc`,
  `fb_add_videomode`, `remove_conflicting_framebuffers`, the notifier chain.
* sysfs need not even be mounted.

So `fb-surface.md` §4.3's model-gap verdict stands as written ("nothing from the
model"), and its stated *failure diagnosis rule* stands too ("if G1 fires and G2
does not, the failure is on the kernel side — do not add MMIO rows"). What
changes is **how** G2 is observed.

---

## 7. Claims ledger

| Claim | Status | Receipt |
|---|---|---|
| fbdev core complete in this build; no fbcon, no cfb helpers | VERIFIED | §2 symbol table; `grep -cE ' (fbcon|fb_console|cfb_…)$'` = 0 over 25,817 symbols |
| `register_framebuffer` has exactly 4 returns: `-6`, `-38`, `-19`, `0` | VERIFIED | `0xc01a055c..0xc01a0754` full disassembly; §3 |
| None of the 3 failures is model-owned | VERIFIED | §3.1: driver writes `flags=1` @ `0x146164`, `fbops` @ `0x146140`; first registration |
| `device_create` failure is non-fatal | VERIFIED | `0xc01a0618` `cmn r0,#4096` / warn arm `0xc01a0628` |
| `fb_init_device` cannot return non-zero | VERIFIED | single epilogue `0xc01a2240 mov r0,#0`; rollback loop `0xc01a2214..0xc01a2230` |
| Registration does **not** need `/sys` | VERIFIED (non-fatal branches) + INFERRED (sysfs unmounted ≠ device_add error) | §4; the C-runs register with `/sys` absent |
| `/proc/fb` is created at boot independent of registration | VERIFIED | `fbmem_init` `0xc0015324` `proc_create_data`; live: `/proc/devices` `29 fb` |
| `/proc/fb` line format is `"%d %s\n"` → `0 mt8530` | VERIFIED | `fb_seq_show` `0xc01a01d4`; format string `0xc041574e` |
| Success printk exists at kernel level | **FALSE** | no such string in the image; only two printks on the path |
| Driver success/fail lines are observable today | **FALSE** | `g_fgEnableDebug` (`.bss+0x82888`) read @ `0x14a014`, gate-0 skip @ `0x14a01c`; no writer in module; not exported; `[FB]` absent from all 19 captured logs |
| `mt8530fb_init` ignores the probe's return and always returns 0 | VERIFIED | `.init.text 0x34` (bl) → `0x68` (`mov r0,r4`, `r4 = 0`) |
| `_mt8530fb_probe` actually ran and returned in the C-runs | VERIFIED | post-probe `x_memset` @ `.init.text+0x5c` traced as `x_memset … n=0x1000 caller=mt8530fb_init` (C93:1069, 10 runs) — it is downstream of the `bl` at `+0x34` |
| `register_framebuffer` returned 0 in the C-runs | **UNKNOWN — no evidence either way** | the probe's `r0` is discarded and its log is gated; settle with `cat /proc/fb` (§5.3) |
| `device_create` succeeded in the C-runs | **INFERRED** | absence of the ungated `<4>Unable to create device for framebuffer 0` printk in 19 logs |
| Identity of the two `fb_info` ints at `+0x1bc`/`+0x1c0` poked at `0xc01a0694`/`0xc01a06a4` | **UNRESOLVED, non-load-bearing** | nothing else in this build reads them (no fbcon/cfb); the branch has no failure path |
| `/proc/fb` was ever read in a prior run | **FALSE — correction** | `1CAT_FB=0` in C93/C95 is `cat /proc/driver/sata/fe_bootup`; `/tmp/procc.sh:7` |

---

## 8. Reproduction

```sh
# 1. kernel image -> raw vmlinux (Mac-side; VM is only the source of the image)
make vm-pull-file FILE=/tmp/images-fe/kernel.uImage DEST=/tmp/kimg/
file /tmp/kimg/kernel.uImage          # u-boot legacy uImage, Linux/ARM, comp=0
cd evidence/bx510-guest/bdpdrv/decode
python3 kernel_decode_image.py /tmp/kimg/kernel.uImage /tmp/kimg/kdec
python3 kernel_decode_kallsyms.py /tmp/kimg/kdec/vmlinux.bin --check
python3 kernel_decode_kallsyms.py /tmp/kimg/kdec/vmlinux.bin > /tmp/kimg/ksyms.txt

# 2. fb framework inventory
#    (data symbols are NOT in this kallsyms build — grep the __ksymtab_ entries)
grep -E ' (register_framebuffer|unregister_framebuffer|fb_alloc_cmap|fb_init_device|__ksymtab_fb_class)$' /tmp/kimg/ksyms.txt
grep -cE ' (fbcon|fb_console|cfb_|sys_fillrect|sys_copyarea|bitfill_aligned)$' /tmp/kimg/ksyms.txt   # 0

# 3. the functions (needs llvm at /opt/homebrew/opt/llvm/bin)
cp /tmp/kimg/kdec/vmlinux.bin /tmp/kdec/ && python3 kernel_decode_dis.py --prep
python3 kernel_decode_dis.py --sym register_framebuffer
python3 kernel_decode_dis.py --sym fb_init_device
python3 kernel_decode_dis.py --sym lock_fb_info
python3 kernel_decode_dis.py --sym fb_seq_show
python3 kernel_decode_dis.py --sym fbmem_init

# 4. driver side (bdpdrv.ko at /tmp/bdpdrv/, sha256 6604f6cd…)
#    Module() from decode/fb_decode_common.py gives reloc-resolved disassembly;
#    vFBDbgLog 0x149fe0, _mt8530fb_probe 0x1460a0, mt8530fb_init .init.text 0x0
```

**Live gate to run next (no model change, no new code):** in one boot, `cat
/proc/fb` before and after `insmod …/bdpdrv.ko`. Expect `0` lines then exactly
`0 mt8530`. Optionally `mkdir -p /sys && mount -t sysfs sysfs /sys` afterwards
for G4. Do not gate on `[FB] ` lines (§5.2), and do not open `/dev/fb0` in the
same run unless the fb-open lane is what you are measuring.
