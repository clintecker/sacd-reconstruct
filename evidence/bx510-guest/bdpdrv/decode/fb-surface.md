# fb-surface.md — the bdpdrv framebuffer contract, decoded

What the guest's `/dev/fb0` actually is, what a pixel write has to travel
through, and what our QEMU model (`emulator-kit/sony-bx510.c`) would have to
answer for that path to run. Every claim below names the instruction site or
artifact it came from; anything unresolved is labelled **INFERRED** with the
experiment that settles it.

**Subject:** `bdpdrv.ko` sha256
`6604f6cd6c204c3399ac047f389f47162b06a3f6576159f21b4e8aaf3a72cf54`.
Addresses are **section-relative** (ET_REL: every section has VMA 0), so
`.text 0x1460b8` is `_mt8530fb_probe+0x18`, not a load address.

## 0. Verdict in one screen

| Question | Answer | Status |
|---|---|---|
| How many framebuffers? | exactly ONE: `_fb_info` (.bss+0x82234), the only `register_framebuffer` call in the module | VERIFIED (`fb-functions.txt` .text 0x1460b8) |
| Geometry | 1920x1080, 32 bpp, `line_length` 7680, `yres_virtual` = 2x yres (2160) → double buffered | VERIFIED binary + sysfs (`hw-session-2026-11-05/RESULTS.md:78-80`) |
| Pixel format | R8G8B8A8, offsets 0/8/16/24, lengths 8, msb_right 0 → bytes B,G,R,A | VERIFIED (.text 0x146204) |
| `fix.id` | `"mt8530"` | VERIFIED (.text 0x14616c) + `/proc/fb`: `0 mt8530` |
| fbops completeness | 15 of 22 slots populated; `fb_imageblit`, `fb_blank`, `fb_read`, `fb_write`, `fb_sync`, `fb_get_caps`, `fb_destroy` NULL | VERIFIED (`_mt8530fb_ops` dump, .data+0x57f20, 88 B) |
| Where the surface lives | allocated on **first open**, 4 pool slots; `screen_base = pool.addr[0]`, `smem_start = pool.addr[0]+0x40000000`, `smem_len` = 16 MiB | decode VERIFIED, numeric value **INFERRED** (§3.2) |
| MMIO from the fb ops themselves | **none** — every `_mt8530fb_*` access resolves NOT-MMIO; hardware is programmed by the OSD/GFX layers they schedule | VERIFIED (`resolve_addrs.py --func`, §2.5) |
| Model gaps for the fb **probe** | **none** — probe = `vFBDbgLog` + `register_framebuffer` | VERIFIED (§4.3) |
| Model gaps for fb **pixels** | GFX window rows R1-R11, plus there is no display/engine consumer at all (§4.2) | partly VERIFIED, partly INFERRED |

## 1. Inputs and provenance

| Artifact | What it is | Regenerate with |
|---|---|---|
| `decode/fb-functions.txt` | curated finding table: owning function + instruction address per finding (70 lines) | `fb_decode_functions.py > fb-functions.txt` |
| `decode/fb_decode_{common,functions,fbinfo,mmap,chardev,ioctl}.py` | the decoders that produced it (ELF/reloc access, finding table, fb_info field map, mmap classes, chardev inventory, ioctl chain) | — |
| `decode/resolve_addrs.py` | forward register-value dataflow → concrete physical address (`virt - 0x8d000000`, calibrated against the Run C50 trace) | `resolve_addrs.py --all` / `--func NAME` / `--reach ADDR` |
| `/tmp/bdpdrv/osd_gfx_acc.txt` | per-instruction resolved-access dump for the GFX/OSD/VDP function families (1728 rows, 473 with a resolved phys address). **Mac-side scratch, not tracked** — cited by address only | `resolve_addrs.py --all` |
| `decode/map.txt` | 602-row access map — **SATA/FE/BIM windows only** (`0xfd05cfff`, `0xfd024000`, `0xfd00a000`, `0xfd060000`, `0xfd090000`, `0xfd324fff`) | — |
| `emulator-kit/sony-bx510.c` | the model under review (gfx cases: reads 413-416, writes 629-647) | — |
| `tools/bx510_fbvirt_mt85.h`, `tools/bx510_fbvirt.c` | the vendor ABI extracted from Sony's published DirectFB-1.2.7 drop, and the guest-kernel stand-in module built on it | — |

> **Correction worth recording:** `map.txt` contains **no** gfx-window
> offsets — a `grep -i 'gfx\|0x4000'` over it returns only two unrelated
> SATA lines. The gfx-window evidence lives in the `resolve_addrs` dump, not
> in `map.txt`. Two workers have now searched `map.txt` for this; don't be
> the third.

## 2. The fb contract

### 2.1 One framebuffer, registered at bdpdrv init, with two log lines

`_mt8530fb_probe` (.text 0x1460a0, 108 B) is the whole registration story and
it is 27 instructions long:

```
0x1460a4  ldr  r0, [pc,#0x48]   ; '_mt8530fb_probe'  (vFBDbgLog tag)
0x1460ac  ldr  r2, [pc,#0x48]   ; 1717  (line number)
0x1460b0  bl   vFBDbgLog
0x1460b4  ldr  r0, [pc,#0x44]   ; &_fb_info  (.bss+0x82234, ABS32:.bss)
0x1460b8  bl   register_framebuffer
0x1460bc  cmp  r0, #0
0x1460c0  bge  0x1460d4         ; r0 >= 0  -> success
0x1460c4  ldr  r0, [pc,#0x38]   ; '_mt8530fb_probe() fail: cannot register mt53fb!\n'
0x1460c8  bl   vFBDbgLog
0x1460cc  mvn  r0, #5           ; return -6 (-ENXIO)
0x1460d0  pop  {r3, pc}
0x1460d4  ...                   ; success: vFBDbgLog(tag, line 1744)
0x1460e4  ldr  r0, [pc,#0x1c]   ; '_mt8530fb_probe(): probe init OK!\n'
0x1460e8  bl   vFBDbgLog
0x1460ec  mov  r0, #0
```

The two strings are `.rodata.str1.1+0x54ea5` (fail) and `.rodata.str1.1+0x54ed6`
(success) — resolved from the literal pool at 0x146104 / 0x146108, not guessed.
(Note for cross-checking: `fb-functions.txt` lists site `0x1460f4` for the fail
message; that is this **pool slot**, not an instruction — the load is at
`0x1460c4`. The distinction matters if anyone ever tries to breakpoint the
message.)

**The success observable is therefore a UART line, and its absence is not
evidence:** `_mt8530fb_probe(): probe init OK!` on success,
`_mt8530fb_probe() fail: cannot register mt53fb!` + probe returning -6 on
failure. (`vFBDbgLog` is the driver's own logger; the same tag-plus-line shape
is used by every `_mt8530fb_*` entry, so `grep _mt8530fb_probe` in a UART log
separates "reached probe" from "registered".)

Callers / lifecycle (from the module symtab + relocations):

| Edge | Site |
|---|---|
| `vDriverInit` → `mt8530fb_init` | `.text 0x8b4b0` (`vDriverInit+0x44c`) |
| `u4Fbinit` → `mt8530fb_init` | `.text 0x149fd4` |
| `mt8530fb_init` → `mt8530fb_reset` → `_mt8530fb_init_fbinfo` | `.init.text 0x2c`, `.text 0x147758` (`mt8530fb_reset+0x80`) |
| `u4FbProbeInit` → `_mt8530fb_init_fbinfo`, `_mt8530fb_probe` | `.text 0x149fb0`, `.text 0x149fb4` |
| `mt8530fb_init` → `_mt8530fb_probe` | `.init.text 0x34` |
| `mt8530fb_uninit` / `u4FbProbeUninit` → `_mt8530fb_probe_uninit` → `unregister_framebuffer` | `.init.text 0xa8`, `.text 0x149fa0`, `.text 0x147594` |

So the framebuffer is registered **at driver load**, from bdpdrv's own init,
not lazily on first ioctl. Live corroboration from a modeled boot: the stub
trace prints `[OSAL_STUB] x_memset dst=c6259020 n=0x1000 caller=mt8530fb_init`
(`bdpdrv-runC50.uart.log:911`) — the init path really runs in the boots we
already have.

`mt8530fb_init` also parses a mode table: it loads the string
`'0 60 0 0 1080p60 1 1080i60 1 1080i60 1 480i720'` (`.init.text+0x10`) and
reaches `strtoargv` (which logs through `vFBDbgLog` at `.text 0x147624`).
1080p60 is the first entry — consistent with the geometry below.

### 2.2 The whole state is one instance, reached through one base register

None of these functions reference their globals directly; they load **one**
`.bss` base (`t_pal`, `.bss+0x81d30`) and reach everything with
`[base_r, #imm]` (this is why an immediate decodes to an exact field):

| Object | Symbol | `.bss` addr | Relative to `t_pal` | Size |
|---|---|---|---|---|
| private driver struct | `fbinfo` | 0x82190 | +0x460 | 160 B |
| the framebuffer | `_fb_info` | 0x82234 | +0x504 | 584 B (0x248) |
| palette store | `pseudo_palette` | 0x8247c | +0x74c | 1024 B |

`_mt8530fb_ops` is the only object outside `.bss`: `.data+0x57f20`, 88 bytes
(§2.4). `fb_info.fbops` ← `&_mt8530fb_ops` at `.text 0x146140`
(`str r7,[t_pal+0x720]` → fb_info+0x21c);
`fb_info.pseudo_palette` ← `&pseudo_palette` at `.text 0x146160`
(`str r3,[t_pal+0x738]` → fb_info+0x234). Those two self-naming stores anchor
the whole field map used by `fb_decode_fbinfo.py`.

### 2.3 var/fix as decoded (`_mt8530fb_init_fbinfo`, .text 0x146118, 392 B)

| Field | Value | Site |
|---|---|---|
| `fb_info.flags` | 1 | .text 0x146164 |
| `fix.id` | `"mt8530"` (memcpy to fb_info+0xc0, len 7) | .text 0x14616c |
| `fix.type` / `type_aux` | 0 / 0 → FB_TYPE_PACKED_PIXELS, no aux | .text 0x1461a0 |
| `var` (160 B) | `__memzero(var = fb_info+0x20, 160)` first — every unset field is 0 | .text 0x1461b4 |
| `var.xres`, `var.yres`, bpp | copied/derived from the private `fbinfo` | .text 0x1461c0 |
| `var.yres_virtual` | `2 * yres` → **double buffered** | .text 0x1461fc |
| `var.red/green/blue/transp` | offsets 0/8/16/24, lengths 8, msb_right 0 → **R8G8B8A8** | .text 0x146204 |
| `fix.line_length` | `xres*bits/8` (zeroed at 0x1461a8, written here) | .text 0x14621c |
| `var.bits_per_pixel` | `8 * bytesperpixel` | .text 0x14622c |
| `var.vmode` | 0 — cleared by the memzero, never set | .text 0x146254 |

With xres=1920 / 32 bpp that is `line_length` 7680 and `yres_virtual` 2160,
which is exactly what the panel advertises:

```
/proc/fb: 0 mt8530    /dev/fb0 char 29,0
/sys/class/graphics/fb0/stride: 7680      virtual_size: 1920,2160    state 0
```
(`evidence/bx510/hw-session-2026-11-05/RESULTS.md:78-80`;
`evidence/bx510/display-payload/2026-11-04-displaylaunch-hardware.log:10-11`)

The decoded field semantics and the device's own sysfs agree on every field
the model needs, so the geometry is not an inference: **1920x1080x32, stride
7680, virtual 2160, 16 MiB of smem for 15.82 MiB of double-buffered surface**
(1920*1080*4 = 8,294,400 B per frame; x2 = 16,588,800 ≤ 0x1000000).

One observed differential belongs here: later captures in the same log show
`FBMD5: /dev/fb0 1280x720 bpp=32 stride=7680` (lines 166, 170) and
`virtual_size: 1280,2880` (line 177) — i.e. after the retail DirectFB
requested 1280x720, `var.xres` moved but `fix.line_length` stayed 7680. `_mt8530fb_set_par` recomputes
`fix.line_length = var.xres*var.bpp/8` (.text 0x14596c) and would have made it
5120; the INIT ioctl path only rewrites the *private* `fbinfo.line_length`
(`_mt8530fb_init` .text 0x145ff0). **INFERRED:** the provider drives geometry
through the vendor INIT ioctl (0x4630), not through `fb_set_par`, so the panel
pitch stays 7680. Cheap check: `strace`-free — read
`/sys/class/graphics/fb0/stride` before/after a DirectFB run.

### 2.4 The fbops table — every slot, from the binary

Dumped from `_mt8530fb_ops` (`.data+0x57f20`, 88 B = 22 pointer slots, Linux
2.6.35 `struct fb_ops` layout) by reading the ABS32 relocations of each word:

| Off | Member | Value | What MMIO it touches |
|---|---|---|---|
| 0x00 | `owner` | `__this_module` | — |
| 0x04 | `fb_open` | `_mt8530fb_open` | none directly — calls the driver's pool allocator (§3.2) |
| 0x08 | `fb_release` | `_mt8530fb_release` | none directly — frees the pools, calls `mt8530_OSD_uninit` |
| 0x0c | `fb_read` | **NULL** | fbdev core read (memcpy from screen_base) |
| 0x10 | `fb_write` | **NULL** | fbdev core write |
| 0x14 | `fb_check_var` | `_mt8530fb_check_var` | none (25 resolved accesses, all NOT-MMIO struct fields) |
| 0x18 | `fb_set_par` | `_mt8530fb_set_par` | none (recomputes `fix.line_length`; `bpp ∈ {1,2,4,8,16,32}` else `__bug`) |
| 0x1c | `fb_setcolreg` | `_mt8530fb_setcolreg` | none (writes `pseudo_palette`) |
| 0x20 | `fb_setcmap` | **NULL** | — |
| 0x24 | `fb_blank` | **NULL** | blanking is not wired: it must go through the vendor ioctls |
| 0x28 | `fb_pan_display` | `_mt8530fb_pan_display` | schedules an OSD flip: `OsdFlipPlaneInVsync(fbinfo.plane, 1, buf[yoffset?1:0])` ×2 (.text 0x1458ec) |
| 0x2c | `fb_fillrect` | `Mt8530fb_FillRect` | GFX command ring: `_MT8530_Gfx_FramBuf_FillRect` + `vGfx_CmdBuf_DispatchHw` (`u4Fb_GfxHandle`) |
| 0x30 | `fb_copyarea` | `Mt8530fb_copyarea` | same ring, `_MT8530_Gfx_FramBuf_Bitblt` |
| 0x34 | `fb_imageblit` | **NULL** | blit is ioctl-only (0x4622 `imageblit_ioctl`) — confirmed by the dump |
| 0x38 | `fb_cursor` | `_mt8530fb_soft_cursor` | none (software cursor over screen_base) |
| 0x3c | `fb_rotate` | **NULL** | — |
| 0x40 | `fb_sync` | **NULL** | waiting is `CHECKFLUSH` (ioctl 0x464d) instead |
| 0x44 | `fb_ioctl` | `_mt8530fb_ioctl` | the OSD/GFX surface: see §3.3 |
| 0x48 | `fb_compat_ioctl` | **NULL** | no 32/64 compat layer (ARM ILP32 only) |
| 0x4c | `fb_mmap` | `_mt8530fb_mmap` | none — pure `remap_pfn_range` (§3.1) |
| 0x50 | `fb_get_caps` | **NULL** | — |
| 0x54 | `fb_destroy` | **NULL** | teardown is `_mt8530fb_probe_uninit` + release |

Two structural consequences worth stating plainly:

* **`fb_imageblit` NULL + `fb_fillrect`/`fb_copyarea` populated** means a
  generic fbdev client gets accelerated rect fill and copy but must use the
  vendor ioctl for blits/cursor-heavy work — which is why the retail provider
  bypasses the generic paths entirely.
* **`fb_blank` NULL** means `FBIOPUT_VSCREENINFO`-style blanking (and the
  kernel's console blanking) cannot blank this panel. Observed state on the
  player is `0` (not blanked) — the standby blanking seen in the field is some
  other layer's, not fbdev's.

### 2.5 The three MMIO layers behind the ops (and the proof the ops are clean)

`resolve_addrs.py --func` over every populated member returns **no phys
access at all** — `_mt8530fb_open`, `_mt8530fb_mmap`, `_mt8530fb_ioctl`,
`_mt8530fb_release`, `Mt8530fb_copyarea` resolve to nothing; `pan_display`,
`set_par`, `check_var`, `Mt8530fb_FillRect` resolve only to NOT-MMIO
struct-field offsets. Every `_mt8530fb_*` row in the wider access dump is
likewise NOT-MMIO. This is the same conclusion `post-aacs-state.md` §4.1
reached from the traces ("`_mt8530fb_*` contributes **no MMIO at all** — it is
a Linux `fb_info` / memory-manager client"), now with the per-instruction
receipts.

The hardware the ops *schedule* is reached through callees that do carry phys
addresses:

| Layer | Phys window | Owners (addresses from the access dump) |
|---|---|---|
| GFX command/status engine | `0x70004000` (engine 0), `0x70040000` (engine 1) | `GFX_HwReset`, `GFX_CmdQue{Reset,Action,Restore,Change}`, `GFX_HwResetEngine`, `GFX_HwResetCmdQue`, `GFX_SetFifo`, `GFX_HwSet*`, `vGfxSetMMU`, `GFX_MMUEnable` — 39 accesses on engine 0's word alone |
| OSD plane / region block | `0x70020000`-based | `OSD_BASE_Dump` (0x70020000..0x7002009c), `_GfxCmdDrawRect` (0x70020104, 0x70020204, 0x70020304, 0x70020a04, 0x70020b04), `OSD_PLA_Dump`, `vSetHDMIOSD5` |
| IOMMU / MMU programming | `0x7005f040-0x7005f050` | `vGfxSetMMU` |
| DRAM command ring | `gptGfxCmdBuf` (a DRAM address) | written by `_MT8530_Gfx_FramBuf_*`, consumed by the engine — **never by the CPU** |

Note the two engine bases are *not* `0x4000` and `0x4800`: `GFX_HwReset` picks
`0xfd004000` vs `0xfd040000` (literals at `.text 0x176aa4` / `0x176aa8`) and
`GFX_HwGetIdle` reads `0x70004004` vs `0x70040004` (`0x1777098` / `0x177709c`).
The model's second slot at `0x4800` (§4.1) is a *third* thing (the RLE/SE
block), so engine 1 at `0x70040000` is currently unmodelled.

## 3. What the guest must write to put pixels on screen

### 3.1 mmap: three classes, dispatched by **length** (not by `vm_pgoff`)

`_mt8530fb_mmap` (.text 0x1455d8, 788 B) never looks at `vm_pgoff` to pick a
class (it only logs it: `'----> vma->vm_pgoff = 0x%x'` at 0x145790). The order
is:

| Condition | Class | Result | Site |
|---|---|---|---|
| `length == gu4GfxCmdBufLen` | 1 — GFX command ring | map the ring (incl. the `mrc p15` cache walk) | .text 0x1455e8 |
| `length == 4096` | 2 — debug info | map the `_pcDfbDebugInfo` page | .text 0x145634 |
| otherwise `idx = (length>>12)&0xF`, kept 0..3 | 0 — image pool | `vma->vm_end -= idx*0x1000`, then `remap_pfn_range(vma, vm_start, pool.addr[idx]>>12, pool.size[idx], prot)` | .text 0x145694, 0x1456a8, 0x145758 |
| per-page path | 0 (fmt 8) | page-table-walk `remap_pfn_range` loop | .text 0x145860 |

Failures on the invalid paths go through `Assert(src/driver/drv_fb/mt8530fb.c)`
(0x145618, 0x14564c, 0x1456c0). The three classes have the published vendor
names `MT85_FB_MMAP_{MEMPOOL,GFXCMDBUF,DEBUGINFO}` = 0/1/2
(`tools/bx510_fbvirt_mt85.h:72-75`) — decode and ABI agree on *what* the three
classes are; they disagree on *how* they are selected (length, not a method
word). The binary wins.

`gu4GfxCmdBufLen` is **0x6000** in a modeled boot: the stub prints
`[_MT8530_Gfx_CmdBuf_GetInst] gu4GfxCmdBufLen = 0x6000` and
`gptGfxCmdBuf = 0xE67D1020` (`bdpdrv-runC50.uart.log:899-908`; the C51/C52/C53
runs print the same length), so a
24 KiB ring mapped by length `0x6000`.

The pool index and length are tied by the vendor convention
`length = pool.size[0] + idx*0x1000` (`tools/bx510_fbdraw.c:330`:
"GETMULTIPOOL, then mmap(size[0] + 0*0x1000)"), which makes
`(length>>12)&0xF == idx`. Two consequences that matter operationally:

* a plain `mmap(fix.smem_len)` on a 16 MiB surface lands on `idx = 0`
  (`0x1000000>>12 & 0xF == 0`) — the surface slot;
* the negative control in `tools/bx510_fbdraw.c:292-307` (length =
  `smem_len+0x1000+3`) lands on `idx = 1`, i.e. **a different pool slot, not
  an error** — the driver's own guard is the `Assert` paths, and "garbage
  length" is only garbage if it also exceeds the pool.

### 3.2 The surface allocation, and which physical address it lives at

The surface does **not** exist at probe time. The first `open` allocates the
whole thing (`_mt8530fb_open`, .text 0x1459e8, 1080 B):

| Site | Call | Type |
|---|---|---|
| .text 0x145a48 | `x_alloc_aligned_ch1_mem(0x400000*n, 4096)` | 5 |
| .text 0x145af4 | `x_alloc_aligned_ch2_mem(0x400000*n, 4096)` | 6 |
| .text 0x145ba8 | `x_mem_aligned_alloc(0x400000*n, 4096)` | 7 |
| .text 0x145c40 | `x_mem_valloc(0x1800000)` — the 24 MiB general pool | 8 |
| .text 0x145cc4 | `x_kmem_create_handle(buf, 0x1800000, 8)` | 8 |

Four allocations ⇒ four pool slots, which is exactly the shape of the pool
descriptor the driver hands userspace: 88 bytes, four-entry arrays,
`num@0, phys@8, addr@0x18, size@0x28`
(`tools/bx510_fbdraw.c:333-334`; the module's `GETMULTIPOOL` copies 88 bytes
at .text 0x147320; the published ABI's 15-entry/312-byte MULTI_POOL is a
different revision — the module serves the 4-slot one). Failure on any
allocation logs `'Fail'`/`'Get it'` pairs (.text 0x145a28-0x145c5c).

Then, at the end of open:

| Field | Value | Site |
|---|---|---|
| `fix.smem_start` | `pool.addr[0] + 0x40000000` | .text 0x145dd4 |
| `fix.smem_len` | `0x1000000` (16 MiB) | .text 0x145de0 |
| `fb_info.screen_base` | `pool.addr[0]` | .text 0x145de4 |

**Which address is "the" framebuffer:**

1. The address the CPU actually maps is `pool.addr[idx]` — it is handed
   straight to `remap_pfn_range` as a pfn (`.text 0x145758`), so `pool.addr[]`
   holds page-frame-able physical addresses, and the kernel-side
   `screen_base` is that same value in kernel VA form.
2. The value **advertised** to userspace in `fix.smem_start` is
   `pool.addr[0] + 0x40000000` — an alias, not the DMA address. Nothing in the
   driver dereferences `smem_start`; userspace tools map by *length*, not by
   address (`tools/bx510_cyberdraw.c:524`, `fbmd5.c:124`).
3. The DRAM the allocator hands out is the low/CPU view: the guest's own
   allocator prints physical 0 for the main framebuffer
   (`[FBM]Flag (0,1), Main FB(0x       0, 34471936)`,
   `bdpdrv-runC50.uart.log:341`).

**The numeric value of `pool.addr[0]` is INFERRED — no artifact we hold records
it.** The settling experiment, using a tool that already exists:

```
# on the player, one session, same open as the paint:
bx510_fbdraw fbmt85        # mt85_pool_capture(): GETMULTIPOOL -> mmap(size[0]+0*0x1000)
                           # prints: capture pool num=N size[0]=.. phys[0]=0x........
                           #         capture located surface at pool0+<bytes>
```

If the painted fill is found through the pool mapping, then `pool.phys[0]` is
the surface base, `pool.addr[0]`'s high bits are settled, and
`smem_start = phys[0] + 0x40000000` is confirmed as an alias rather than the
base. `fix.smem_start` itself is readable the same session via
`FBIOGET_FSCREENINFO` (`bx510_cyberdraw.c:516`, `bx510_fbmd5.c:121`) — one
extra `printf` of `finfo.smem_start` settles the advertised side. Both must be
taken in the **same** open: the pools are freed at release
(`x_free_aligned_ch1_ch2_mem` / `x_mem_aligned_free` / `x_mem_vfree`,
`_mt8530fb_release` .text 0x14748c), so the base can differ between opens.

### 3.3 The ioctl chain — the numbered contract

`_mt8530fb_ioctl` (.text 0x146a84, 2568 B) is a 17-command compare chain
(hand-built binary search, decoded from `cmp`-vs-literal plus the following
`beq`). The commands with sites in `fb-functions.txt`:

| `cmd` | Handler | Capability |
|---|---|---|
| 0x4620 | `fillrect_ioctl` (.text 0x146c28) | rect fill through the GFX ring |
| 0x4621 | `copyarea_ioctl` (.text 0x146c3c) | blit through the GFX ring |
| 0x4622 | `imageblit_ioctl` (.text 0x146c50) | image blit (fbops slot is NULL) |
| 0x4627 | SET, `__copy_from_user(68 B)` (.text 0x146c7c) | `struct mt85fb_set` (68 B, `bx510_fbvirt_mt85.h:13`) |
| 0x462d | `drawline_ioctl` (.text 0x146bf0) | line (GX ioctl form) |
| 0x462f | `drawrect_ioctl` (.text 0x146c04) | rect |
| 0x4630 | INIT → `_mt8530fb_init(arg)` (.text 0x145e88) | `__copy_from_user(160 B)` = a full `fb_var_screeninfo` from USER space (.text 0x145ecc), `_mt8530fb_check_var` (0x145f04), vmode→colormode switch (0x145f78), `line_length = xres*bytesperpixel` into the private `fbinfo` (0x145ff0) |
| 0x464d | CHECKFLUSH → `mt8530fb_CmdBuf_WaitDone` (.text 0x147388) | consume + wait |
| 0x464f | GETCMDBUFLEN → `mt8530fb_CmdBuf_GetLen` (.text 0x14737c) | ring length (0x6000) |
| 0x4651 | DISPATCHHW → `mt8530fb_CmdBuf_DispatchHw` (.text 0x147370 → `vGfx_CmdBuf_DispatchHw`) | **kick the ring** |
| 0x4652 | GETMULTIPOOL, `__copy_to_user(arg, sp, 88)` (.text 0x147320) | the 4-slot pool descriptor |
| default | log + **return 0** (.text 0x1473ac) | an unknown ioctl is not an error — a "silent success" shape to keep in mind when reading traces |

Six more handlers appear in the dispatch chain as callees — `mt8530fb_Stretchblit_ioctl`,
`mt8530fb_Alphablit_ioctl`, `mt8530fb_Flush_ioctl`, `mt8530fb_Stop_ioctl`,
`mt8530fb_CmdBuf_WR_Lock`, `mt8530fb_CmdBuf_WR_Unlock` — their numbers are not
in the curated table; the ABI header gives WR_LOCK/WR_UNLOCK as
0x4900/0x4901 from Sony's source (`bx510_fbvirt_mt85.h:55-56`), **not** from
our decode of this binary.
Treat any number not above as unverified.

The INIT/SET handlers are the ones that reach the display: the relocation list
of `_mt8530fb_ioctl` shows `mt8530_OSD_init`, `mt8530_OSD_uninit`,
`OSD_RGN_Set` ×10, `OSD_PLA_Enable`, `OSD_PLA_SetFading`,
`OsdFlipPlaneInVsync`, `OsdFlipPlaneInVsyncNowait_ForDFB`,
`OSDWaitForFlipInVsyncNoWait` — i.e. plane/region programming, not framebuffer
memory writes.

### 3.4 Why a raw `/dev/fb0` paint is not a display path (differential)

Measured on the player, not inferred: a full-frame paint into fb0 hashes back
intact on re-read and **nothing appears on the TV**, and the frame is
overwritten by something else within ~2 s
(`evidence/bx510/hw-session-2026-11-05/RESULTS.md:83-85,113,136`;
`evidence/bx510/display-payload/DISPLAY-SPEC.md:131`). The decode explains the
mechanism: fb0's pool is one surface among four, the OSD plane list — not the
fb's `screen_base` — decides what is scanned out, and the plane flip is a
separate ioctl path (§3.3). So "put pixels on screen" is two writes:
**(a)** into the pool slot (§3.2), **(b)** an OSD flip/region update so the
plane points at that slot. **INFERRED** which exact sequence the appliance
uses; the rail is INIT (0x4630) → RGN/plane ioctls → flip. The decisive
experiment is a player session that paints *and* issues the flip, gated on the
TV photo, not on the md5.

## 4. Model recipe rows — the GFX window

### 4.1 What the model answers today

`emulator-kit/sony-bx510.c` implements exactly six words in this window
(reads at 413-416, writes at 629-647), plus the RLE/SE slot — line numbers
as of this writing; that file is under concurrent edit, so **cite the case
values, not the lines** if they disagree:

| Model case | Behaviour | Covers |
|---|---|---|
| `0x4000` read | `gfx_kicked ? 0xa0000000 : 0` (line 414) | `GFX_HwReset`'s status poll |
| `0x4000` write | store, set `gfx_kicked` when value == 0 (629-633) | the kick protocol |
| `0x4010` write | store only (636) | `GFX_RiscPushBack`, `GFX_HwReset` |
| `0x4104` write | accepted silently (637-638) | `GFX_Init` |
| `0x4134` write | accepted silently (638) | `GFX_HwReset` |
| `0x4800` / `0x4810` / `0x4804` / `0x4834` | second engine (`gfx2_*`), lines 415-416, 639-647 | RLE/SE block (VERIFIED Run C22-25 per its comment) |

That is enough to survive `GFX_HwReset`, and we can now show *why* from the
driver side — the poll loop at `.text 0x17694c-0x17697c` requires

```
(st & 0xc0000000) == 0x80000000   AND   (st & 0x30000000) == 0x20000000
```

and `0xa0000000` satisfies both. `GFX_HwReset` writes `0xa0000000` first
(`mov r2,#-1610612736` at 0x176894) then `0xc00001f0` to `0x4010` (literal at
0x176ab8), which is where the model's comment about "0xa0000000/0xc00001f0
command words" comes from — the same word is both a write value and a status
value, and the model is right to serve it on read.

### 4.2 What is missing, ordered by what unblocks the next observable

New rows (all offsets are model `off`, i.e. phys − `0x70000000`):

| # | off | R/W | Owner in bdpdrv | Model today | What to add | Confidence |
|---|---|---|---|---|---|---|
| R1 | `0x4000` | R/W | 39 accesses: `GFX_HwReset`, `GFX_CmdQue{Reset,Action,Restore,Change}`, `GFX_HwResetEngine`, `GFX_HwResetCmdQue`, `GFX_SetFifo`, `GFX_HwSet*`, `vGfxSetMMU`, `GFX_MMUEnable` | answered | keep; consider a readback-last-written for the RMW users | VERIFIED sufficient for HwReset |
| R2 | `0x4004` | R | `GFX_HwGetIdle` — returns `val & 1` (0x177070-0x177094) | **unimplemented** → 0 → "busy" | return bit0 = 1 (idle) | polarity **INFERRED** (name + mask); settle with one blit trace |
| R3 | `0x4008` | W | `GFX_CmdQue{Reset,Restore,Change}` — queue base | **unimplemented** (LOG_UNIMP) | accept and store (the model has no engine to feed) | VERIFIED benign |
| R4 | `0x400c` | R/W | `GFX_CmdQueAction` (W), `GFX_HwReset` (R→modify→W, sets `0x10000000`) | **unimplemented** → reads 0 | readback-last-written (same pattern as the SATA `a604/a620/a634/a680` rows) | RMW-storage pattern, VERIFIED elsewhere in this model |
| R5 | `0x4010` | W | `GFX_HwReset` ×2, `GFX_RiscPushBack` | answered (636) | — | — |
| R6 | `0x4104` | W | `GFX_Init` | answered (637) | — | — |
| R7 | `0x4134` | R/W | `GFX_HwReset` (reads before writing, 0x176a3c) | write accepted, read → 0 | readback-last-written | **INFERRED** (value's meaning unknown) |
| R8 | `0x4258` | R | `_GfxHwRealIsr` (0x17686c) | unimplemented → 0 | leave 0 = "no GFX interrupt" — the correct idle answer; a real IRQ path would need a latch bit | VERIFIED benign-as-zero |
| R9 | `0x40a0`, `0x40d0-0x40dc`, `0x40e0/0x40e4/0x40ec` | R | `GFX_HwGetMemCompareResult`, `GFX_HwGetBpCompStopID`, `GFX_HwDbgInfo` | unimplemented → 0 | leave 0 (debug-only readers) | VERIFIED benign |
| R10 | `0x4800`+ | R/W | RLE/SE block | answered | — | — |
| R11 | `0x40000`, `0x40004`, `0x40010` | R/W | **GFX engine 1**: `GFX_HwReset` (literals `0xfd040000`/`0xfd040010`), `GFX_CmdQueAction`, `GFX_SetFifo`, `GFX_HwGetIdle` (`0xfd040004`), `GFX_HwGetHwVersion` | **falls into the default arm** (the model's second slot is `0x4800`, not `0x40000`) | mirror R1-R4 at +0x40000 *only if* a trace shows engine 1 used | INFERRED — no trace shows engine 1 |
| R12 | DRAM | — | the command ring (`gptGfxCmdBuf`, `gu4GfxCmdBufLen` = 0x6000) | not modelled: nothing reads the ring, no engine consumes it | **structural gap** — see below | VERIFIED gap |

R12 is the honest one. Even with R1-R11 answered, the model cannot make a
pixel appear: the GFX/OSD engine that consumes the ring is a *device*, and the
machine has no display model at all (`tools/bx510_fbvirt.c:5-14` says exactly
that: "The sony-bx510 QEMU machine has no display-controller model"). The
model's job ends at "the driver's polls are satisfied and the ring is written";
proving the pixels requires either the guest-side stand-in (§5) or a real
engine consumer.

### 4.3 What "the fb probe succeeds" actually requires

**Nothing from the model.** The proof is the probe's complete callee list:

* `_mt8530fb_probe`: `vFBDbgLog` ×4 + `register_framebuffer` (5 relocations,
  full disassembly in §2.1);
* `_mt8530fb_init_fbinfo`: `vFBDbgLog` ×5 + `memcpy` + `__memzero`;
* every `_mt8530fb_*` access resolves NOT-MMIO (§2.5).

`register_framebuffer` returning 0 is Linux bookkeeping over `_fb_info` —
`fix.id`, `fbops`, and a well-formed `var`. So the observable is reachable
**today**, with no new model rows, and the recipe is a *witness*, not an
implementation:

| Gate | Command | PASS looks like |
|---|---|---|
| G1 | boot the model, capture UART | `_mt8530fb_probe` tag appears **without** `... fail: cannot register mt53fb!` |
| G2 | same log | `_mt8530fb_probe(): probe init OK!` present (str +0x54ed6) |
| G3 | guest shell | `/proc/fb` contains `0 mt8530`; `/dev/fb0` major 29 |
| G4 | guest shell | `/sys/class/graphics/fb0/{stride,virtual_size}` = `7680`, `1920,2160` — geometry parity with the player |

If G1 fires and G2 does not, the failure is on the kernel side (fb major not
present, `fb_info` malformed), **not** the model — do not add MMIO rows to
"fix" it. G3/G4 are the real payoff: they would let the model advertise the
player's exact fb geometry, which is what the HUD rig has been faking (§5).

## 5. Relation to `sacd-hud-sim` / `sacd-hud-guest`

The HUD (`tools/bx510_sacd_hud.c`) never touches fb0's pool directly: it
draws through DirectFB, whose retail provider (`libdirectfb_mtk.so`) issues
this very ioctl/mmap contract — `GETMULTIPOOL`, `GETCMDBUFLEN`, `DISPATCHHW`,
the pool-length mmap — so this document is the ground truth for what the HUD's
provider is doing when it "works". But the code that actually runs in the
guest today is `tools/bx510_fbvirt.c`, a stand-in *kernel module* that
implements the same 18 vendor requests (`bx510_fbvirt.c:28`) and three mmap
classes with synthetic answers over vmalloc'd RAM (`bx510_fbvirt.c:1-24`, `:566`
for the GETMULTIPOOL handler), and it advertises the player's mode for parity
reasons (1920x1080, stride 7680, virtual 1920x2160 —
the same numbers §2.3 decodes from `_mt8530fb_init_fbinfo`). The two legs are
therefore: `sacd-hud-sim` (Makefile:481-482) renders the canvas on the Mac with
`-DHUD_SIM` and no driver at all — a layout oracle; `sacd-hud-guest`
(Makefile:497-498 → `tools/hud_guest_run.sh` → `bx510_hud_repro.py --fbmod
bx510_fbvirt.ko`) proves the userspace→provider→vendor-ABI path and gates on
HUD rc plus a non-black pool dump — red today because fbvirt's
`FBIO_DISPATCHHW` is a no-op (Makefile:495 — that target's own doc line says so). Neither
leg exercises the real driver, so neither can show whether the *real* fb path
works; conversely this writeup's rows R1-R11 plus the G1-G4 witnesses turn
"the HUD draws against fbvirt" into "the HUD draws against bdpdrv's fb with a
modelled GFX/OSD engine", which is the only version of the claim that predicts
player behaviour.

## 6. Claims ledger

| Claim | Status | Receipt |
|---|---|---|
| One framebuffer, one registration site | VERIFIED | `fb-functions.txt` 0x1460b4/0x1460b8; callers-of dump |
| Success/fail UART strings | VERIFIED | literals 0x146104/0x146108 → `.rodata.str1.1+0x54ea5` / `+0x54ed6` |
| fbops slots and their owners | VERIFIED | `_mt8530fb_ops` ABS32 reloc dump (.data+0x57f20, 88 B) |
| Geometry 1920x1080x32 / 7680 / 2160 | VERIFIED (decode + sysfs agree) | 0x1461c0-0x14622c; `hw-session-2026-11-05/RESULTS.md:78-80` |
| fb ops touch no MMIO | VERIFIED | `resolve_addrs.py --func` on all 12 populated members |
| mmap class selection is by length | VERIFIED | 0x1455e8/0x145634/0x145694; the `vm_pgoff` log at 0x145790 |
| Pool = 4 slots, 88-byte descriptor | VERIFIED | open's 4 allocations (0x145a48-0x145cc4); 88 B copy at 0x147320; `bx510_fbdraw.c:333-334` |
| `smem_start = pool.addr[0]+0x40000000`, `smem_len` 16 MiB, `screen_base = pool.addr[0]` | VERIFIED | 0x145dd4/0x145de0/0x145de4 |
| The **value** of `pool.addr[0]` (i.e. the surface's phys base) | **INFERRED** | no artifact records it; §3.2 settling experiment |
| The `+0x40000000` is an alias, not the DMA address | **INFERRED** | nothing dereferences `smem_start`; `remap_pfn_range` uses `pool.addr[idx]` |
| Provider drives geometry via INIT (0x4630), not `fb_set_par` | **INFERRED** | stride stayed 7680 at xres 1280 (`displaylaunch-hardware.log:166,170,177`); set_par would have made 5120 |
| GFX `0x4004` idle bit polarity | **INFERRED** | `GFX_HwGetIdle` returns `val & 1`; name implies 1 = idle |
| Engine 1 at `0x70040000` is used by the fb path | **UNKNOWN** (no trace) | literals `0xfd040000` in `GFX_HwReset`/`GFX_CmdQueAction`/`GFX_SetFifo` |
| ioctl numbers not listed in §3.3 | **UNVERIFIED here** | ABI header only (`bx510_fbvirt_mt85.h:42-56`) |
| A raw fb0 paint is not a display path | VERIFIED (measured) | `hw-session-2026-11-05/RESULTS.md:83-85,113,136`; mechanism INFERRED (§3.4) |

## 7. Next steps

1. **Cheapest, highest value:** run G1-G4 (§4.3) on the current model. If G2
   fires, the fb lane's kernel side already works and the remaining question is
   entirely "does anything consume the ring".
2. Settle the surface's physical base with the existing `bx510_fbdraw fbmt85`
   capture on the player (§3.2) — one session, no new code.
3. Only then add model rows R2/R3/R4/R7, and only if a trace shows
   `GFX_CmdQueAction`/`GFX_HwGetIdle` executing — R2 with the "wait" path is the
   only one that can *wedge* a driver loop, so it should be added with a
   trace-backed polarity, not a guess.
4. Do **not** model R12 (an engine that consumes the ring) until a pixel
   question actually needs it; the guest-side stand-in already answers the
   userspace-contract question, and an engine model is a project, not a row.
