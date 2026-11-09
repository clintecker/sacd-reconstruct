# MT85xx fbdev vendor-ioctl + command-ring contract (S1 extraction)

Run: 2026-11-08, Mac-side, from the staged retail binaries only.
Author: Stage-1 analyst run (S1 of the stock-leverage plan; feeds S3 rig work).

Inputs (sha256, recorded in `incoming/mt85-analyst/`):

| file | sha256 | role |
|---|---|---|
| `libdirectfb_mtk.so` | `eca7a3e3d9c4d64e4e92096e88e8165cc11baa5eb37a528362f7edcf7cdc2a42` | system provider (owns /dev/fb0, ioctl numbers, ring init) |
| `libdirectfb_mt85.so` | `298fa8f3352c853b901b4145fd75fa7334f0ae06e0942dbe716771bfc0ce97a3` | gfxdriver (writes items into the ring, issues DISPATCHHW/CHECKFLUSH/LOCK/UNLOCK) |
| `libdirectfb-1.2.so.0.7.0` | (staged; not needed for this contract) | DirectFB core |

The mtk.so hash matches the sha pinned in `MT85-RESULTS.md` (`eca7a3e3…`) —
this is the same binary whose contract fbvirt already serves.

## Method (deterministic; no eyeballing)

Everything below was derived with tools, in this order:

1. `llvm-readelf -r` → the `.rel.plt` table names every GOT slot directly
   (`0000f1e4 R_ARM_JUMP_SLOT ioctl@GLIBC_2.4` — the slot 0xf1e4 noted in
   `handoff-graphics-appliance.md` §3 is confirmed as `ioctl`).
2. `llvm-objdump -d --no-show-raw-insn` → the PLT entries carry symbol
   annotations (`00001834 <ioctl@plt>` in mtk.so, `00000e28 <ioctl@plt>` in
   mt85.so), so every call site is found by grep for `bl 0x1834` / `bl 0xe28`
   — 45 sites in mtk.so, 8 in mt85.so. (A capstone back-tracer stalled on
   the first invalid instruction; the objdump text listing is complete.)
3. For each call site, the r1 (request-number) definition was back-traced to
   a literal-pool load (`ldr r1, [pc, #imm] @ 0xADDR`), and the word at that
   address was read **out of the file bytes** with pyelftools — the number is
   never hand-derived (scripts: `/tmp/mt85_ioctl_extract.py`,
   `/tmp/mt85_strxref.py` this session; scripts and outputs retained under
   `evidence/bx510-guest/graphics/mt85-extraction/` — `mt85_ioctl_extract.py`,
   `mt85_strxref.py`, `mt85_annotate.py`, `mtk_ioctl.txt`, `mt85_ioctl.txt`,
   `mtk.strx`, `mt85.strx`).
4. Each ioctl's identity was confirmed by pairing its failure branch with the
   literal-pool string reference resolved through the same tracker
   (`add rX, pc, rY` base + signed offset word → string address; strings
   contain `\n`, which the first pass missed — fixed before trusting output).
5. Relocation types: `R_ARM_RELATIVE`/`GLOB_DAT`/`JUMP_SLOT` only; there are
   **no** `R_ARM_RELATIVE` pointer tables over the per-op name strings — those
   strings are dead data in the gfxdriver (referenced by nothing; see §3).

Every claim below is labeled **VERIFIED** (bytes/disassembly/string resolved)
or **INFERRED** (mechanism consistent with all evidence but not directly
pinned), per house rules.

---

## 1. Vendor ioctl numbers (retail binaries — these are the numbers that must be served)

### 1.1 System provider (`libdirectfb_mtk.so`), vendor ioctls on /dev/fb0

All numbers VERIFIED from literal words at the annotated pool addresses; the
identity of each is VERIFIED by its failure-string pairing (the `perror`
string hanging off that call site's failure branch).

| request | name | call sites | evidence (r1 literal @ pool addr) | failure string at branch target |
|---|---|---|---|---|
| `0x4630` | FBIO_INIT | 0x2510 | 0x2954 → 0x4630 | "DirectFB/MT85: FBIO_INIT failed!" (lit@0x2980) |
| `0x4602` | FBIOGET_FSCREENINFO (standard) | 0x1f14, 0x252c | 0x22a4 / 0x2958 → 0x4602 | "DirectFB/MT85: FBIOGET_FSCREENINFO failed!" (lit@0x22cc) |
| `0x4629` | FBIO_GETIMAGEBUFFER | 0x1f30, 0x2548 | 0x22a8 / 0x295c → 0x4629 | "DirectFB/MT85: FBIO_GETIMAGEBUFFER failed!" (lit@0x297c) |
| `0x4652` | FBIO_GETMULTIPOOL | 0x1f58, 0x257c | 0x22b0 / 0x2964 → 0x4652 | "DirectFB/MT85: FBIO_GETMULTIPOOL failed!" (lit@0x22d8); success path then prints "UUU:CONFIG_DIRECTFB_MULTI_MEM_POOL" |
| `0x464f` | FBIO_GETCMDBUFLEN | 0x1d30 (mt85AdapterCmdBufInit) | 0x1e14 → 0x464f | "MediaTek/Driver: FBIO_GETCMDBUFLEN failed!" (perror lit@0x1e30 → 0x6120) |
| `0x4650` | FBIO_RELCMDBUF | 0x29f4 (mt85AdapterCmdBufUninit) | 0x2a84 → 0x4650 | "MediaTek/Driver: FBIO_RELCMDBUF failed!" (lit@0x2a34 → 0x634c) |
| `0x4627` | FBIO_SET (masked apply) | 0x2eac, 0x316c, 0x321c, 0x3948 | 0x2f24 / 0x31c4 / 0x32a4 / 0x3a14 → 0x4627 | "DirectFB/MT85: FBIO_SET failed!" |
| `0x4628` | FBIO_SET-adjacent CLUT/palette upload | 0x37dc (`_mapColorFormat`) | 0x39fc → 0x4628 | return value ignored (no failure branch); see below |
| `0x4642` | plane-order GET (published name; retail verified number) | 0x2f80, 0x3438 | 0x3058 / 0x35c4 → 0x4642 | "DirectFB/MT85: FBIO_SET failed!" |
| `0x4643` | plane-order SET | 0x34d4 | 0x35c8 → 0x4643 | "DirectFB/MT85: FBIO_SET failed!" |
| `0x4645` | FBIO_GET (panel info, nested userspace pointer) | 0x30b8 | 0x3124 → 0x4645 | "DirectFB/MT85: FBIO_SET failed!" |

Notes per request (argument structures):

- **FBIO_INIT 0x4630** — arg (r2) = stack struct ≥ 0x88 bytes; fields stored
  VERIFIED at 0x24c4–0x250c: `+0x00 = 1280` (xres), `+0x04 = 720` (yres),
  `+0x08 = 1280` (xres_virtual), `+0x0c = 2880` (yres_virtual = 4×720),
  `+0x10 = 0`, `+0x14 = 0`, `+0x18 = 32` (bpp), `+0x84 = 12`. Field semantics
  beyond the first four INFERRED (fb_var-shaped). fbvirt already serves this
  (validated, not adopted) — matches the run-log line "requested 1280x720
  x2880 virt, bpp 32".
- **FBIOGET_FSCREENINFO 0x4602** — standard; arg = sysdata+12 where sysdata =
  `*dfb_mt85` (the 100-byte `calloc(1,100)` struct stored at `dfb_mt85[0]`,
  VERIFIED 0x1e9c–0x1ef8).
- **FBIO_GETIMAGEBUFFER 0x4629** — arg = **sysdata + 84** (VERIFIED
  `add r2, r2, #84` at 0x1f2c/0x2544). The provider never re-reads VSCREENINFO
  after INIT; the image-buffer response lives here (fbvirt fills it today).
- **FBIO_GETMULTIPOOL 0x4652** — arg = `&mt85_multi_pool` (VERIFIED: arg is
  the GOT-resolved symbol at 0xf3c8; response layout = the retail 88-byte
  structure already decoded and served in MT85-RESULTS:
  `num@0, ref_num@4, phys[4]@8, addr[4]@24, size[4]@40, type[4]@56, handle[4]@72`;
  the provider checks `num != 0` at 0x1f68 and reads mmap lengths at
  `mp+40+4i` — VERIFIED `ldr r1, [r5, #0x4]!` pre-indexed from mp+36 at 0x1fa8).
- **FBIO_GETCMDBUFLEN 0x464f** — arg = `&_gui4CmdbufLen` (VERIFIED: r2 =
  `[r4+0x13c]` = 0xf2a8). On success the provider `mmap(len, PROT_READ|WRITE,
  MAP_SHARED, fd, 0)` at offset 0 (VERIFIED 0x1d88: r2=3, r3=1, [sp]=fd,
  [sp+4]=0), stores the raw mapping in `_gptCmdbufDrv` (VERIFIED 0x1d9c) and
  `mmap_result + 32` into the adapter struct (next bullet).
- **Adapter struct / `_h_mt85_Ticket`** — VERIFIED: `mt85AdapterCmdBufInit`
  `malloc(20)`s a struct (`[+0x4]=0` byte, `[+0x8]=self`, `[+0xc]=10`,
  `[+0x10]=mmap+32`), stores it into `_h_mt85_Ticket` (bss 0xf3b8). The
  gfxdriver imports `_h_mt85_Ticket` **from libdirectfb_mtk.so** (dynsym:
  UND `_h_mt85_Ticket`) and reads the ring pointer from `ticket+0x10` — this
  is the cross-module handoff; there is no second open/mmap in the gfxdriver
  (it imports no `open`/`mmap` at all — VERIFIED dynsym).
- **FBIO_RELCMDBUF 0x4650** — arg = `ticket+0x10` (ring pointer), VERIFIED
  0x29f0; followed by munmap of the raw mapping (`[ptr->0x50]`... the
  provider's own bookkeeping).
- **FBIO_SET 0x4627** — arg = stack struct; mask field observed at struct
  +0x3c/+0x40 region (VERIFIED stores `[sp,#0x40]`/`[sp,#0x44]` with values
  `r3` and `0x100000` — the `0x100000` mask bit is printed by the provider as
  "FBIO_SET MT85FB_SET_MASK_SAFETY!", VERIFIED string 0x64cc + lit@0x3a1c).
  fbvirt's masked-apply implementation already matches (MT85-RESULTS).
- **0x4628 (CLUT/palette)** — VERIFIED call in `_mapColorFormat`: the caller
  builds 256 ARGB entries (byte-assembled `b0<<24|b1<<16|b2<<8|b3`, 1024
  bytes at sp+0) and one leading word, then `ioctl(0x4628, sp)`; the return
  value is **ignored** (`mov r0, #0` immediately after). Semantics INFERRED:
  OSD palette/CLUT upload. Not exercised by the demonstrated rungs.
- **0x4642/0x4643** — numbers VERIFIED; the published names
  (PLANE_ORDER GET/SET) are INFERRED from the prior published-header scan
  (`MT85-RESULTS.md` divergence table). fbvirt already serves both.
- **0x4645** — number VERIFIED; arg shape VERIFIED (r2 = sp+4 with a nested
  pointer at +0x8 → `[sp,#0xc]` = sp+16 — the "nested userspace pointer"
  fbvirt already serves for FBIO_GET panel size).

Standard (non-vendor) ioctls also issued by mtk.so, for completeness — all
VERIFIED as standard Linux numbers, NOT part of the vendor contract:
`0x460f/0x4610` (FBIOGET/PUT_CON2FBMAP), `0x5600–0x5608` (VT_OPENQRY…
VT_DISALLOCATE), `0x540e` (TIOCNXCL), `0x5422` (TIOCSCTTY), `0x4b3a`
(KDSETMODE, arg 1 = KD_GRAPHICS), `0x5605` (VT_RELDISP).

### 1.2 Gfxdriver (`libdirectfb_mt85.so`) — the ring ioctls

All four take the **ring header pointer** (`ticket+0x10` = cmdbuf mmap + 32)
as the ioctl argument — VERIFIED at every site.

| request | identity | call sites | evidence |
|---|---|---|---|
| `0x4900` | ring write-lock (published WR_LOCK name; see §2) | 0x1000 (top of the emit loop, once per iteration) | `mov r1, #18688` (=0x4900) VERIFIED; **return value never checked** |
| `0x4651` | **FBIO_DISPATCHHW** (retail gfxdriver revision) | 0x10f0, 0x1120, 0x1378 | lit@0x146c = 0x4651 VERIFIED; every failure branch (`blt`) lands on `puts("MediaTek/Driver: FBIO_DISPATCHHW failed!")` — the string pointer is stored at `[sp,#0x14]` at 0xfe8–0xfec and resolved to 0x7824 (VERIFIED) |
| `0x4901` | ring write-unlock (published WR_UNLOCK) | 0x1140, 0x11f4 | lit@0x1470 = 0x4901 VERIFIED; return never checked |
| `0x464d` | `_mt85CheckFlush` (consume+wait-flavor) | 0x555c (mt85EngineSync), 0x5748 (mt85CheckState) | lit@0x55e8/0x5c64 = 0x464d VERIFIED; failure path `puts("MediaTek/Driver: _mt85CheckFlush failed!")` (VERIFIED via base 0x103bc + signed lit@0x55ec = 0xffff76e8) |

**Numbering correction (important):** the retail gfxdriver issues DISPATCHHW
as **0x4651** — in the published header 0x4651 was GETCMDBUFLEN (and fbvirt
implements DISPATCHHW at the published 0x4653, returning ENOTTY for others).
The retail system provider uses 0x464f for GETCMDBUFLEN. The two retail
binaries are different source revisions of the vendor tree: the sys provider
is the revision MT85-RESULTS already pinned (0x464f/0x4650/0x4652), the
gfxdriver numbers its ring requests 0x4651/0x464d/0x4900/0x4901. A rig that
must run BOTH modules must serve **both** number sets. (0x4651 does not
collide with anything the sys provider issues, so one dispatch table can
carry both meanings without conflict — each module only issues its own set.)

---

## 2. The command-ring contract (FBIO_DISPATCHHW)

Everything in this section is from the gfxdriver's emit function
(0xf74–0x1470 in libdirectfb_mt85.so) and its helpers.

### 2.1 Mapped-region layout (the GETCMDBUFLEN mmap)

```
mmap base +0x000 : GFX_DRV_CMDBUF_T prefix, 32 bytes
                    (VERIFIED: mtk.so stores mmap+0 in _gptCmdbufDrv and
                     mmap+32 in ticket+0x10: add r2, r0, #32 @ 0x1d90)
mmap base +0x020 : ring header (r7 in the gfxdriver), 160 bytes
mmap base +0x0C0 : item slot 0 … maxcount-1 slots × 160 bytes each
                    (32-byte prefix + 160-byte header = 192 = 0xC0;
                     the +0x0A0 figure below is ring-relative)
```

The ring header fields (offsets from r7 = mmap+32), all u32:

| offset | field | owner | evidence |
|---|---|---|---|
| +0x04 | **maxcount** (capacity in items) | kernel (userspace only reads) | VERIFIED: modulus of the full test `(Wr+1) % [+0x4] == Rd` (helper 0x715c = `__aeabi_uidivmod` wrapper returning `(Wr+1) mod [+0x4]` in r1, compared against [+0x10] at 0x104c), and the wrap bound `cmp r8, r10; movhs r8, #0` at 0x11b8 |
| +0x10 | **RdPoint** (read index) | kernel | VERIFIED: read at 0x1010 (`ldr r9, [r7, #0x10]`) as B in the free-space formula (modulus is [+0x4], so B must be RdPoint) and in the full test at 0x104c/0x1058; never stored by userspace anywhere in either binary |
| +0x30 | **state / dispatch policy** | kernel | VERIFIED: compared `== 1` (dispatch-after-each-item path 0x11e0) and `== 3` (skip-DISPATCHHW-on-full path 0x1104–0x110c); EngineSync/CheckState assert it is `<= 3` (0x5528, 0x5714, `bhi` → `__assert_fail`) |
| +0x40 | **WrPoint** (write index) | userspace (gfxdriver) | VERIFIED: read 0x100c, advanced+wrapped 0x11b0–0x11c4 (`str r8, [r6, #0x40]`) |
| +0x60 | flag echo | userspace writes | VERIFIED: `str r3, [r7, #0x60]` at 0x1014, value = ticket+0x4 byte (0 at init). Purpose INFERRED (presence/alive marker); kernel may ignore |

### 2.2 Item slots (stride 160 bytes — NOT 64)

Item slot k lives at `ring + 160*(k+1)` (i.e. the first item sits at mmap
the first item sits at mmap +0x0C0 (prefix 32 + header 160; +0x0A0 is the
same point measured from the header at mmap+32). VERIFIED twice in the
emitter:

```
1048:  add r11, r11, r11, lsl #2      ; r11 = 5*(Wr+1)
1054:  add r0,  r7,  r11, lsl #5      ; item = ring + 160*(Wr+1)
1060:  str r5,  [r7, r11, lsl #5]     ; item->cmd_id (same offset)
```

The largest memcpy'd payload is 132 bytes at item+8 (8+132 = 140 ≤ 160), so a
64-byte item (the published-source estimate used for fbvirt's current ring
init) **cannot** be what this gfxdriver writes — a 132-byte payload would
overwrite the next item. The published 64-byte estimate is hereby corrected:
**retail item stride = 160 bytes** (VERIFIED arithmetic; the payload field
widths are consistent with it).

Item layout:

| offset | field | evidence |
|---|---|---|
| +0x00 | u32 **command id** | VERIFIED `str r5, [r7, r11, lsl #5]` (r5 = the emitter's cmd arg) |
| +0x04 | u32 **item flag**: `1` if the emit call's arg3 != 0, else `2` | VERIFIED 0x1064–0x1074 (`cmp r12,#0; moveq r3,#2; movne r3,#1; str r3,[r0,#0x4]`). Sync-flush items (see below) carry 1. Kernel-side meaning INFERRED (1 = flush/sync-flavored, 2 = render item). |
| +0x08 | payload, memcpy'd, size depends on command id (56–132 bytes) | VERIFIED per-case `memcpy(item+8, arg1, N)` — see §3 table |

### 2.3 The write-side handshake (gfxdriver loop, per item)

```
loop:
  ioctl(fd, 0x4900 WR_LOCK, ring)              ; unchecked        (0xff0–0x1000)
  Wr   = ring+0x40 ; C = ring+0x4 ; Rd = ring+0x10             (0x1004–0x1020)
  ring+0x60 = ticket->flagbyte                                 (0x1014)
  free = (Wr >= Rd) ? C + Rd - Wr : Rd - Wr                    (0x1024–0x1030)
  if ((Wr+1) % C == Rd)            ; ring FULL
      → ioctl(fd, 0x4651 DISPATCHHW, ring)   ; drain           (0x1104 path)
        if ring+0x30 == 3 → skip DISPATCHHW  ; policy          (0x1104–0x110c)
        → ioctl(fd, 0x4901 WR_UNLOCK, ring); usleep(1); retry loop
  write item at slot (Wr+1): cmd_id, flag, memcpy payload         (0x105c–…)
  Wr := (Wr+1) % C; store back to ring+0x40                       (0x11b0–0x11c4)
  if free == C (ring was EMPTY before this write)
      → ioctl(fd, 0x4651 DISPATCHHW, ring)                       (0x11cc–0x11d4 → 0x10e0)
  else if ring+0x30 == 1
      → ioctl(fd, 0x4651 DISPATCHHW, ring)                       (0x11d8–0x11e4 → 0x136c)
  ioctl(fd, 0x4901 WR_UNLOCK, ring)                               (0x11e8/0x1130)
  return 1   (or, on the full-retry path: usleep(1) and loop)     (0x11f8/0x1148)
```

Handshake semantics, each labeled:

- Empty test: `Wr == Rd` ⇒ empty (free == C) — VERIFIED formula + the
  `cmp r10(maxcount), r2(free); beq → dispatch` at 0x11d0.
- Full test: `(Wr+1) % C == Rd` — VERIFIED (modulo helper + compare at
  0x104c/0x1058: on full, the payload memcpy is SKIPPED and the code goes
  straight to the drain path).
- Items live in slots `(Rd, Wr]` (mod C): the writer writes slot `Wr+1` and
  then advances Wr; the kernel-side consumer must therefore read slots
  `(Rd, Wr]` in order and advance RdPoint to Wr. The reader half is INFERRED
  (the kernel is not in these binaries), but it is the only convention
  consistent with the writer's arithmetic: `Wr == Rd` empty, write-then-
  advance, full at `(Wr+1) % C == Rd`.
- DISPATCHHW (0x4651) is issued (a) when the ring was empty before the write,
  (b) when `ring+0x30 == 1`, or (c) when the ring is full (drain-to-retry).
  With `ring+0x30 == 1` ("immediate mode") every item is dispatched right
  after it is written — the recommended value for a virtual device (§4).
- WR_LOCK (0x4900) / WR_UNLOCK (0x4901) bracket every loop iteration; both
  returns ignored. Names: 0x4901 = WR_UNLOCK is the published number carried
  over (MT85-RESULTS divergence table); 0x4900 = WR_LOCK is INFERRED by
  position (top-of-loop before header reads) — the published lock number was
  not recorded in prior art.
- `_mt85CheckFlush` (0x464d): called by `mt85EngineSync` and `mt85CheckState`
  immediately after each emits the **sync command 0x191** (VERIFIED: both
  call the emitter with r2 = lit = 0x191, r1 = NULL payload, r3 = 1; then
  ioctl 0x464d). EngineSync only does this when the pending-flag byte (bss
  0x104d0, set by `mt85EmitCommands`, cleared after the flush — VERIFIED
  0x560c–0x5624, 0x54f8, 0x5568–0x5570) is nonzero. Semantics INFERRED:
  0x464d = "drain the ring and wait until the engine has consumed it"
  (the CMDBUFWAITDONE role). A virtual implementation: consume items and
  return 0.
- The sync item (cmd 0x191) is special-cased in the emitter: `mov r12, #1;
  stm r0, {r5, r12}` — writes only `{0x191, 1}` (cmd + flag), **no payload
  memcpy** (VERIFIED 0x141c–0x1424). Treat it as a flush/complete marker.
- `mt85EngineReset`, `mt85FlushTextureCache`, `mt85FlushReadCache` are `bx
  lr` no-ops (VERIFIED 0x5608, 0x54dc, 0x54e0).

### 2.4 Emitter entry points (for completeness)

- `mt85AdapterCmdBufSetCmd(ctx, payload, cmd_id, flag, devptr)` — the big
  emitter at 0xf74 (name VERIFIED from its assert string
  "mt85AdapterCmdBufSetCmd" referenced by every wrapper; the exported
  `mt85EmitCommands` is NOT this — it only sets the pending byte).
- ctx = `&_h_mt85_Ticket` (imported from mtk.so); `ctx+0x10` = ring pointer;
  `devptr` = pointer whose first word is the /dev/fb0 fd (passed through as
  the 5th argument, read back at `[sp,#0x48]` — VERIFIED).
- Returns 1 on success; 0xFFFFFFFE (-2) when asked for the sync command with
  no pending work (EngineSync treats -2 as "nothing to do", skips the
  0x464d ioctl, VERIFIED `cmn r0, #2` at 0x5548).

---

## 3. What the gfxdriver submits through the ring

### 3.1 Command-id table

The emitter switches on the command id with per-case payload memcpy sizes
(all VERIFIED from the switch at 0x1070–0x1348). The struct family per id is
VERIFIED from the assert expressions in the wrapper that issues it
(`rFill.pv_dst`, `rFillBlend.pv_dst`, `rBitblt.pv_src/pv_dst`,
`rStretch.pv_src/pv_dst`). The commercial names come from an unreferenced
(dead) string table in .rodata (0x73ec–0x76cc, pairs of identical names);
binding names to ids relies on the compiler having emitted the 18 wrapper
functions in the same order as the 18 name strings — labeled **INFERRED**
(strong: one .c file, contiguous, no reordering pressure — but not pinned by
a reference).

| cmd id | payload bytes (memcpy at item+8) | struct family (VERIFIED) | name (INFERRED) | wrapper |
|---|---|---|---|---|
| 0x01 | 56 | rFill | mt85FillRectangle | 0x5174 |
| 0x02 | 124 | rBitblt | mt85Blit | 0x22c0 |
| 0x03 | 128 | rBitblt | mt85BlitBlend | 0x3fd4 |
| 0x04 | 108 | — (no wrapper found) | OPEN | — |
| 0x0f | 108 | rStretch | mt85StretchBlit | 0x1f08 |
| 0x15 | 132 | — (no wrapper found) | OPEN | — |
| 0x16 | 132 | rStretch | (second path of mt85StretchBlitBlend) | 0x3e2c |
| 0x1d | 132 | — (no wrapper found) | OPEN | — |
| 0x27 | 128 | rFillBlend | mt85FillRectangleCompose | 0x17f8 |
| 0x28 | 56 | rFill | mt85DrawRectangle | 0x4380 |
| 0x29 | 128 | rFillBlend | mt85DrawRectangleCompose | 0x46d4 |
| 0x2c | 64 | rFill | mt85FillTriangle | 0x4abc |
| 0x2d | 72 | rFill | mt85FillTriangleCompose | 0x4e0c |
| 0x2e | 112 | rBitblt | mt85ColorKeyBlit | 0x30fc |
| 0x2f | 120 | rStretch | mt85ColorKeyStretchBlit | 0x2cfc |
| 0x30 | 60 | rFillBlend | mt85FillRectangleBlend | 0x1490 |
| 0x31 | 132 | rStretch | mt85StretchBlitBlend | 0x3dac |
| 0x32 | 56 | — (no wrapper found) | OPEN | — |
| 0x34 | 128 | (rect asserts only) | mt85BlitPM | 0x29cc |
| 0x35 | 128 | (rect asserts only) | mt85BlitBlendPM | 0x3854 |
| 0x36 | 128 | (rect asserts only) | mt85StretchBlitPM | 0x2648 |
| 0x38 | 128 | (rect asserts only) | mt85StretchBlitBlendPM | 0x34cc |
| 0x3a | 124 | rBitblt | mt85BlitColorize | 0x1b48 |
| 0x12e (302) | 108 | — (no wrapper found) | OPEN | — |
| 0x191 (401) | 8 (cmd+flag only, no memcpy) | sync marker | (EngineSync/CheckState flush) | 0x5544/0x5730 |

The five unrouted ids (4, 21, 29→0x1d, 50→0x32, 302) are accepted by the
emitter's switch but no caller in this binary was found issuing them (an
unanalyzed path or a second revision); record as OPEN with next technique:
trace the DirectFB core's graphics dispatch (libdirectfb-1.2.so.0.7.0 is
staged) for the missing function-table entries.

### 3.2 rFill payload (the FillRectangle item, cmd 0x01) — 56 bytes

Field offsets VERIFIED from the wrapper at 0x5174–0x52ec (payload built on
the stack at sp+0x10, 12 words zeroed first); semantics INFERRED from the
source registers.

**EMPIRICAL CORRECTION (S3 validation run, 2026-11-09 — VERIFIED by
observation, supersedes the static reading below):** the S3 rig executed a
retail FillRectangle through the ring and dumped the item payload; the word
observed at **+0x30 was the SetColor value (0xff3099e0 — the rung's exact
color)** and +0x34 was the 0x12345678 sentinel, while +0x00 held 0x174c0
(NOT the color). The static "color at +0x00" reading below is therefore
**disproven by observation**; the corrected empirical map used by the
fbvirt fill verifier (tools/bx510_fbdraw.c rung-d) is: color = payload
word 12 (+0x30), sentinel = word 13 (+0x34). The remaining static rows are
kept as the decode record; only the color row is overturned.

Static decode (superseded where contradicted above):

| offset | value | source |
|---|---|---|
| +0x00 | u32 color | global read via `*(*(base+GOT))` (the SetColor state) |
| +0x04 | u32 = 1 | constant |
| +0x08 | u32 = state->[+0x08] | DirectFB CardState arg (r4) |
| +0x0c | u32 = 0 | constant |
| +0x10 | u32 = rect->[+0x00] | rect arg (r5) — INFERRED x |
| +0x14 | u32 = rect->[+0x04] | — INFERRED y |
| +0x18 | u32 = state->[+0x0c] | CardState — INFERRED pitch/dst-pitch |
| +0x1c | u32 = 0 | constant |
| +0x20 | u32 = mapped color-format code | the DSPF→MT85-format switch (`cmp` against 0x214612 / 0x418c04 / 0x4011040b — DSPF enum values; 0x418c04 = DSPF_ARGB per the run3 table dump) |
| +0x24 | u8 = 0 | constant |
| +0x28 | u32 = rect->[+0x08] | — INFERRED width |
| +0x2c | u32 = rect->[+0x0c] | — INFERRED height |
| +0x30 | u32 = 0 | constant |
| +0x34 | u32 = **0x12345678** | literal word@0x54a0 — likely a magic/sentinel the kernel validates |

The other struct families (rBitblt 112–128 B, rStretch 108–132 B,
rFillBlend 60–128 B) follow the same shape (buffer pointers validated by
`pv_src`/`pv_dst` asserts, rect pairs, format code); their field maps are
NOT yet decoded — record as OPEN (next technique: same wrapper-window decode
per wrapper; each is 0x2c0–0x380 bytes of straight-line code).

---

## 4. Implementation checklist for fbvirt (S3)

Corrections and additions against the current `tools/bx510_fbvirt.c`
( + `bx510_fbvirt_mt85.h`, which lives VM-side), in priority order:

1. **Ring header geometry (correctness bug in the current init).** Current
   fbvirt initializes the ring as "maxcount 8188 items at 64 B/item" — that
   is the published-source estimate, and this gfxdriver will scribble past
   the mmap if it is used: items are 160 bytes and the driver wraps at
   whatever maxcount the header carries, writing up to
   `192 + 160*maxcount` bytes into the ring mmap. Initialize instead:
   - `maxcount = (ring_mmap_len - 192) / 160` (for the 512 KiB ring:
     (524288−192)/160 = **3275**, floor),
   - `RdPoint = 0` (+0x10), `WrPoint = 0` (+0x40),
   - `state = 1` (+0x30) — immediate-dispatch mode; the gfxdriver then
     issues DISPATCHHW after every item (VERIFIED path), which is the
     simplest correct behavior for a software interpreter,
   - leave +0x60 alone (gfxdriver writes it).
2. **Accept the gfxdriver's ring ioctls (currently ENOTTY → provider
   SIGSEGV in guest).** All four take the ring pointer (mmap+32) as arg:
   - `0x4651` = DISPATCHHW (retail gfxdriver): consume items `(Rd, Wr]` in
     order; for each, execute-or-log; then `RdPoint = Wr`. Execute at least
     cmd 0x191 (no-op flush) and 0x01 (rFill, layout §3.2) to keep the
     accelerated path from faulting; unknown ids: advance the ring anyway
     and log (never EINVAL mid-ring — the gfxdriver would retry forever
     against a full ring).
   - `0x464d` = _mt85CheckFlush: same consumption as DISPATCHHW (plus
     "wait" semantics — trivially satisfied by consuming synchronously).
   - `0x4900` / `0x4901` = WR_LOCK / WR_UNLOCK: return 0, no state change
     (the gfxdriver ignores the returns anyway).
   - Keep the published 0x4653 DISPATCHHW handler as-is (honest no-op
     consumer) so both revisions work.
3. **Keep every sys-provider number already demonstrated** (MT85-RESULTS
   rungs a–e): INIT 0x4630 (accept request, do not adopt the mode),
   GETIMAGEBUFFER 0x4629 → sysdata+84, GETMULTIPOOL 0x4652 (88-byte retail
   layout, ≥2 pools, page-aligned size[]), GETCMDBUFLEN 0x464f (return the
   ring mmap length; on mmap dispatch by length), RELCMDBUF 0x4650,
   FBIO_GET 0x4645 (nested pointer), FBIO_SET 0x4627 masked (+0x4642/0x4643
   plane order). New: consider accepting **0x4628** (CLUT upload; provider
   ignores the result — a `return 0` is sufficient and honest).
4. **Dispatch-table layout:** one ioctl switch carrying both revisions'
   numbers is safe — the sys provider never issues 0x4651/0x464d/0x4900/
   0x4901 and the gfxdriver never issues the sys set (VERIFIED call-site
   lists above). Unknown requests stay `-ENOTTY` + logged (the negative
   control rung depends on it).
5. **The mmap length classes stay as implemented** (pool i = size[i] +
   i*0x1000, ring = GETCMDBUFLEN value, debug = 4096, all at offset 0) —
   the retail provider issues no selector ioctl; length dispatch is the
   demonstrated mechanism (MT85-RESULTS).
6. **Negative control additions:** assert `0x4651` with a NULL/invalid ring
   pointer does not fault; assert the gfxdriver's full-ring retry
   (DISPATCHHW → usleep → re-lock) terminates once the consumer drains.

---

## 5. OPEN items (with reasons and next techniques)

1. **Exact payload layouts for rBitblt / rStretch / rFillBlend.** The
   field maps were only decoded for rFill (§3.2). Next technique: the same
   wrapper-window decode per wrapper (0x22c0, 0x1f08, 0x17f8, …) — each
   builds its payload on-stack with straight-line stores, exactly like
   0x5174 did.
2. **Unrouted emitter ids 4, 21 (0x15), 29 (0x1d), 50 (0x32), 302 (0x12e).**
   No caller found in libdirectfb_mt85.so. Next technique: find the
   GraphicsDeviceFuncs table construction inside the staged
   libdirectfb-1.2.so.0.7.0 (the core calls the driver through it) and
   check for additional driver entry points / a second gfxdriver on the
   device rootfs.
3. **GFX_DRV_CMDBUF_T 32-byte prefix contents.** Never read by either
   binary (VERIFIED: no loads from mmap+0..31 in either). Probably
   {prGfxCmdBuf, len}-style bookkeeping; treat as reserved/zero.
4. **Kernel-side read-half of the ring.** INFERRED from the writer
   arithmetic (§2.3). The real MT85xx kernel driver is not in our
   possession; if a rig observation contradicts the (Rd, Wr] convention,
   the alternative (Rd, Wr) with Wr = next-free would show up as a
   one-item lag in pool captures.
5. **`ring+0x30` state semantics beyond {1, 3}.** INFERRED policy values;
   harmless for fbvirt (we own the kernel side).

## Provenance of this document

- Disassembly listings: `/tmp/mtk.asm`, `/tmp/mt85.asm` (llvm-objdump -d
  --no-show-raw-insn, Homebrew LLVM 22.1.2, macOS arm64 host).
- Literal/string resolution: pyelftools 0.33 + the session scripts (retained
  under `evidence/bx510-guest/graphics/mt85-extraction/`; see Method step 3
  for the file list).
- Prior art consumed: `evidence/bx510-guest/graphics/MT85-RESULTS.md`
  (rungs a–e; the sys-provider retail numbers, here re-verified
  independently and extended), `docs/handoff-graphics-appliance.md` §3,
  `docs/STOCK-LEVERAGE-PLAN.md`, `tools/bx510_fbvirt.c`.
- No VM was used; no live/destructive command was run; nothing committed.
