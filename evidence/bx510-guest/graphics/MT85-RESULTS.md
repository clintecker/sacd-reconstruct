# MT85xx vendor-contract rung — results (2026-11-04)

Mission: make the SHIPPED retail `libdirectfb-1.2.so.0` +
`libdirectfb_mtk.so` (the device's own graphics stack, running in its own
guest OS) get through MT85xx vendor initialization and a live surface, by
implementing the vendor ioctl contract in the fbvirt guest module.

**Headline: rungs (a), (b), (c) demonstrated. DirectFBCreate returns OK —
the retail provider initializes end-to-end against our virtual MT85xx
device.** Rungs (d)/(e) are blocked by one remaining downstream failure
in the retail surface-manager allocation path (NOT in our ioctl
contract — every vendor request the provider issues is now answered;
details and targeting data below).

## The success ladder (evidence: mt85-run*.log alongside)

| Rung | State | Evidence |
|---|---|---|
| (a) DirectFB passes FBIO_INIT | **DEMONSTRATED** | `fbvirt-mt85: FBIO_INIT ok (requested 1280x720 x2880 virt, bpp 32; advertised mode stays 720x576@32)` (run2/3/4); no ENOTTY anywhere in the init path |
| (b) system_initialize completes past #237 | **DEMONSTRATED** | `( MediaTek/System: system_initialize: #237` … `mt85AdapterCmdBufGetCmdBuf: u4CmdbufLen = 0x80000` … `[5J] system_initialize -> map debug info` … `FBMT85: rung (b) DirectFBCreate rc=0 (OK)` |
| (c) DirectFBCreate succeeds / live surface | **DEMONSTRATED** | `DirectFBCreate rc=0 (OK)`; `FBMT85: rung (c) primary surface LIVE: 1280x720 fmt=4295684` (0x418c04 = DSPF_ARGB, confirmed against the retail binary's own DSPF table dump) |
| (d) FillRectangle presents | **NOT DEMONSTRATED** (call accepted, render aborted) | `SetColor+FillRectangle(0,0,1280,720) rc=0` BUT the deferred Genefx render fails: `(!) DirectFB/Genefx: Could not lock destination! --> General failure!` and `Flip rc=1` (`Core/LayerRegion: Could not lock region surface for SetRegion()!`). No pixels proven presented. |
| (e) pool pixels match independent expectation | **NOT REACHED** | capture step never runs (requires (d) to draw) |
| negative control (invalid selector/request/mmap must fail) | **DEMONSTRATED** | run2/3/4: `SETMMAPMETHOD=3 -> EINVAL`, `ioctl(0x4666) -> ENOTTY`, `mmap(len=0x400003) -> MAP_FAILED`, `NEGCTL PASS (failures=0)` — nothing hangs |
| raw-fbdev regression gate (pre-MT85 path unchanged) | **DEMONSTRATED (4 runs)** | `FBDRAW: full-frame md5: 7d19af14518cb5c201aedab2cf94e83d` — identical to the historical pinned md5 in RESULTS.md in every run, including after all MT85 changes |

Transcripts: `mt85-run1-published-contract-8mib.log` (first attempt,
published numbering — fails at GETMULTIPOOL, the discovery that started
the retail disassembly), `mt85-run2-retail-contract-8mib.log` (retail
numbering, first full a–c pass), `mt85-run3-retail-contract-32mib.log`
(pool enlarged), `mt85-run4-retail-contract-exactfit-probe.log`
(exact-fit probe).

## The big discovery: retail ≠ published numbering and layout

The task contract (from Sony's published DirectFB-1.2.7 source drop)
was implemented first and the retail provider STILL died at "Get memory
failed" — with **no corresponding ioctl ever reaching the module**.
Disassembly of the shipped provider (objdump + readelf against
`/tmp/rootfs/lib/directfb-1.2-0/systems/libdirectfb_mtk.so`, SHA
eca7a3e3…, kept at /tmp/mt85mod/mtk.asm on the VM) showed the retail
build is a **different source revision**. Every divergence below is
retail-verified from the binary (call-site decoded, not guessed):

| Request | Published | Retail (verified) | Evidence in retail binary |
|---|---|---|---|
| FBIO_INIT | 0x4630 | 0x4630 (same) | call site 0x2510, literal pool 0x2954 |
| FBIOGET_FSCREENINFO | std 0x4602 | same | literal 0x2958 |
| FBIO_GETIMAGEBUFFER | 0x4629 | 0x4629 (same) | literal 0x295c; arg = dfb_mt85+84 |
| **FBIO_GETMULTIPOOL** | 0x4654 | **0x4652** | issued immediately after the `UUU:CONFIG_DIRECTFB_MULTI_MEM_POOL` printf (0x257c); arg = &mt85_multi_pool; result's `num` checked, then the pool-mmap loop reads lengths from it |
| **FBIO_GETCMDBUFLEN** | 0x4651 | **0x464f** | mt85AdapterCmdBufGetCmdBuf stores into `&_gui4CmdbufLen` (GOT 0xf2a8) and mmaps the ring with that value (no zero-check — a failed GETCMDBUFLEN would mmap(0)) |
| **FBIO_RELCMDBUF** | 0x4652 | **0x4650** | mt85AdapterCmdBufUninit call site 0x29f4, literal 0x2a84 |
| FBIO_SET / GET / PLANE_ORDER GET/SET | 0x4627/0x4645/0x4642/0x4643 | same | literals present (matches ANALYSIS.md scan) |
| **FBIO_SETMMAPMETHOD** | 0x4655 | **never issued** | no selector ioctl anywhere in retail init; the ring map (0x1d88) and the 4096-byte debug map (0x28c8) are issued with plain mmap at offset 0 — **the retail driver dispatches mmap classes purely by length** |
| CMDBUFWAITDONE / DISPATCHHW / WR_UNLOCK | 0x464f/0x4653/0x4901 | retail numbers unobserved | not exercised by the software-rendering path |

The ANALYSIS.md "10/18 verbatim" table is hereby corrected: 0x4652 in
the retail binary is GETMULTIPOOL (not RELCMDBUF) and 0x464f is
GETCMDBUFLEN (not CMDBUFWAITDONE) — presence was right, meaning was
mis-assigned from the published header.

### Retail MULTI_POOL layout ≠ published

Published: 312 bytes, 15-entry arrays (phys@12, addr@72, size@132…).
Retail (three-way verified): `readelf -s` pins `mt85_multi_pool` at
**88 bytes**; the init pool-mmap loop reads mmap lengths from
**mp+40+4i** and stores the mmap results at **mp+24+4i**; mt85Lock
(retail 0x3a94) computes `lock->addr = mp[poolno+6]+offset` (= the
mmap results) and `lock->phys = mp[poolno+2]+offset`. So:

```
num@0, ref_num@4, phys[4]@8, addr[4]@24, size[4]@40, type[4]@56, handle[4]@72
```

Four-entry arrays (FB_MEM_SLICE_NUM=4 in the retail revision), and the
driver fills num/phys/size; addr[] belongs to userspace. Our module
serves exactly this on 0x4652 and the provider accepted it (pool
mmap succeeded, `mt85AdapterCmdBufGetCmdBuf: u4CmdbufLen = 0x80000`,
debug map mapped).

### Other retail facts pinned

- Retail `GFX_DRV_CMDBUF_T` prefix before the ring header is **32 bytes**
  (`prGfxMwCmdBuf = mmap_result + 32` at 0x1d90-0x1a4) — matches published.
- Retail flow does NOT check the cmdbuf mmap result (MAP_FAILED would be
  stored as the ring pointer); we return a valid length so it never
  bites.
- The retail provider prints its whole DSPF enum table at init
  (captured in run3's daemon.out) — handy free documentation:
  `DSPF_ARGB = 0x418c04`, confirming the layer format.

## What the module implements (bx510_fbvirt.c + bx510_fbvirt_mt85.h)

- All retail-verified requests: INIT (copy_from_user + validation, one
  consistent advertised mode 720x576@32 — see below), GETIMAGEBUFFER,
  GETMULTIPOOL (retail 88-byte layout), GETCMDBUFLEN (retail 0x464f),
  RELCMDBUF (no-op release), FBIO_GET (panel size 720x576, nested
  userspace pointer), FBIO_SET (masked apply, plane id validated, phys
  base translated into pool bounds and logged), PLANE_ORDER GET/SET/OSD,
  CMDBUF WR_LOCK/UNLOCK, GFX_FLUSH/WAIT, DISPATCHHW (published number
  only: consumes the ring without executing, logged honestly).
- Published-only numbers (0x4653/0x4654) stay **-ENOTTY and logged** —
  never fake success.
- Three mmap classes dispatched by the published length conventions
  (pool i ↔ `size[i] + i*0x1000`, ring ↔ GETCMDBUFLEN value, debug ↔
  4096), all at offset 0 — which the retail binary's no-selector flow
  proves is exactly how the real driver dispatches. **Per-fd selector
  state is impossible on this kernel**: 2.6.35's fb_ops carries no
  `struct file*` into fb_ioctl OR fb_mmap (verified in the Sony tree);
  documented in the source.
- Separate bounded storage: 32 MiB pool, 512 KiB ring (header
  initialized: maxcount 8188 items at 64 B/item, published-source
  estimate), 4 KiB debug — all distinct lengths, standard-fbdev mmap
  path byte-identical to pre-MT85 (regression md5 pinned across 4 runs).
- One consistent mode: 720x576@32bpp in fb_var AND fb_fix AND FBIO_GET
  panel size. FBIO_INIT's requested 1280x720x4-virt is validated,
  accepted, and NOT adopted (the provider never re-reads VSCREENINFO
  after INIT; DirectFB's layers come up at the provider's own 1280x720
  default regardless).

## The remaining blocker (rungs d/e) — what it is NOT

1. **Not pool exhaustion**: 8 MiB, 32 MiB, and an
   exact-one-surface 3,686,400-byte pool fail IDENTICALLY
   (`Genefx: Could not lock destination! -> General failure!`).
2. **Not the ioctl contract**: zero ENOTTYs / zero unhandled-request
   logs during the rung; every vendor request the retail provider
   issues is answered and the provider proceeds all the way to a live
   IDirectFBSurface object.
3. **Not the phys/addr translation**: mt85Lock reads addr[0] from the
   slot the provider's own pool mmap filled — the surface-object path
   works up to allocation time.

What it IS (demonstrated by the error chain): the destination (layer
region) surface's buffer never gets a valid allocation —
`dfb_surface_pools_allocate` returns DFB_FAILURE after every pool
declines, so the first Genefx lock of the destination fails and
`realize_region()`/SetRegion abort the flip. The decline happens inside
the retail `dfb_surfacemanager_allocate` (0x40e0) / `search_pool`
(0x3f68) pair compiled into the shipped provider.

Targeting data for the next pass (from the disassembly, saved at
/tmp/mt85mod/mtk.asm on the VM):
- `dfb_surfacemanager_allocate` entry gates before any chunk search:
  `ldrb r4, [r1, #88]` → if nonzero returns 0x21 immediately; a
  `[buffer+20] → [x+268] & 5 == 5` branch to 0x4338 (policy/caps gate);
  `m_avail[0] >= size` gate at 0x416c.
- `search_pool` semantics: walks chunks, immediate success only on
  EXACT length match, otherwise best-fit chunk returned via ret_chunk;
  the occupy/split path after 0x41bc was not yet decoded.
- The retail `dfb_surfacemanager_create` (0x3ca0) builds
  m_chunks[i]@+8+4i, m_offset[i]@+24+4i, m_length[i]@+40+4i,
  m_avail[i]@+56+4i from `mt85_multi_pool.size[i]` — verified our
  GETMULTIPOOL response feeds it correctly (32 MiB lengths observed).

## Demonstrated vs inferred (labeled)

- **Demonstrated**: everything in the ladder table above; the retail
  request numbers/layouts in the divergence table (call-site decoded);
  the raw-fbdev regression gate across all four runs.
- **Inferred**: retail numbering for RELCMDBUF 0x4650 (call site found
  in Uninit; semantics no-op for us either way); the ring item size
  (64 B, published-source estimate — the ring is never exercised by the
  software path); that the retail driver dispatches mmap purely by
  length (strong: the retail provider issues no selector ioctl at all).
- **Not claimed**: no DrawString, no accelerated rendering, no command
  execution, no HDMI/display-controller emulation, no hardware parity.

## Next steps (precisely scoped)

1. Decode the retail `dfb_surfacemanager_allocate` occupy/split path
   (0x40e0–0x44a0) and its entry gates; the failing gate is in there —
   three candidate gates already listed above.
2. If the gate is policy-related, try layer-buffer-mode/policy options
   via DirectFBSetOption (e.g. `layer-buffer-mode`, `surface-policy`) —
   cheap guest-side experiment, no rebuild.
3. Instrument from userspace: an LD_PRELOAD shim on the provider's
   allocate path (or DFB debug env, if the retail build honors it) to
   print which gate declines.
4. Once (d) draws: rung (e) is already wired — the harness captures the
   pool through the same published mmap convention and md5-compares
   against an independently built uniform-frame expectation.

## Reproduction

On the lab VM (module source: `experiments/sacd_reconstruct/tools/`,
built in /tmp/mt85mod2; harness: `tools/bx510_fbmt85_repro.py`):

```
cd ~/bx510-emu/emulator
python3 bx510_fbmt85_repro.py --qemu work/build/qemu-system-arm \
    --images ../images --shim /tmp/tmpredir.so --bgstart /tmp/bgstart \
    --fbmod /tmp/mt85mod2/bx510_fbvirt.ko --fbdraw /tmp/mt85mod2/fbdraw \
    --timeout 800 --log /tmp/mt85mod2/run.log
```

The harness (modeled on bx510_pair_repro.py; the phase0 probe is
untouched) runs the raw-fbdev regression gate, the negative controls,
and the no-hardware DirectFB rung in one boot, then the fbmt85hw
discovery variant under bgstart (bounded, never gating).

## RUNGS (d) AND (e): DEMONSTRATED (2026-11-04, the two-pool decode)

The rung-(d) blocker is decoded and closed
(MT85-SEARCHPOOL-DECODE.md has the full condition list): the retail
`dfb_surfacemanager_allocate` (0x40e0) gates primary/video-only
surfaces (caps & 5, per published layer_context.c:1509) on a
**num-pools >= 2** check that returns DR_TEMPUNAVAIL (26) —
primary/video-only surfaces may only allocate from pools 0..num-2.
With fbvirt's one-pool response the primary layer surface could NEVER
allocate, which is why every size hypothesis (8 MiB / 32 MiB /
exact-fit) failed identically: the count gate fires before any size
comparison. The fix is the minimal hardware-true topology: pool 0 =
one primary surface (PAGE_ALIGN(pitch*height+16) = 3,690,496 —
page-multiple or the length-dispatched pool mmap can never match),
pool 1 = the VALLOC "last" slice the retail skips for primary
surfaces (FB_MEM_SLICE_NUM=4 on real hardware; num=2 is minimal).

| Rung | Status | Transcript evidence |
|---|---|---|
| (d) FillRectangle presents | **DEMONSTRATED** | `FBMT85: rung (d) SetColor+FillRectangle(0,0,1280,720) rc=0` — no Genefx lock failure; presents through the retail software renderer |
| (e) pool pixels match independent expectation | **DEMONSTRATED** | `FBMT85: rung (e) pool capture MATCHES the independent expectation` — the scan-locate also measures the retail core's calc buffer size (alloc 3,686,416 at offset 4,080, carving from the pool's end) |
| negative control | **PASS** | `NEGCTL PASS (failures=0)` — SETMMAPMETHOD=3 EINVAL, 0x4666 ENOTTY, bad mmap MAP_FAILED |
| raw-fbdev regression | **PASS** | full-frame md5 `7d19af14518cb5c201aedab2cf94e83d` — identical to the pinned pre-MT85 value |

Logs: `mt85-run5-twopool-rung-d-e.log` (the discovery run, two
boots) and `mt85-run7-postalign-validation.log` (the committed
tree's validation after the pool-size page-alignment refinement,
two boots, all five checks PASS). VM run6 (not kept) failed on a
rig mistake worth recording: fbdraw was rebuilt -static, and the
static binary's dlopen of the retail libdirectfb died on
`__getpagesize: _dl_pagesize != 0` — **fbdraw must stay a dynamic
era-toolchain build** (the DirectFB rung shares the guest's real
glibc).

The full retail MT85xx graphics contract — GETMULTIPOOL 0x4652,
GETCMDBUFLEN 0x464f, RELCMDBUF 0x4650, three length-dispatched mmap
classes, WR_LOCK/UNLOCK/DISPATCHHW ring plumbing (honest no-op
interpreter), unknown requests ENOTTY+logged — is now demonstrated
end-to-end in the guest: the retail libdirectfb initializes,
creates a live 1280x720 ARGB primary surface, renders a filled
rectangle through its own software path, and the pixels read back
match. Next graphics step is the hardware leg: the fusion
adjudicator (inventory v2, on tonight's stick) decides join-vs-
native; the vendor-layer scratch-surface probe follows.

## HARDWARE LEG (2026-11-05): the vendor path draws on the real panel

The guest rungs above were answered on the player itself. Two hardware
findings that matter for this document:

1. **raw `/dev/fb0` is not the scan-out path** — a direct paint lands in the
   buffer (`cyberdraw` md5 `5be59ae2…`) but is overwritten within 2 s
   (`fbmd5` md5 `1656abea…`) and never appears on the panel.
2. **the retail stack does draw** — a 40 KB test linking the player's own
   `libdirectfb-1.2.so.0` + the MT85xx provider ran the exact init chain we
   reproduce in fbvirt (`MediaTek/System: system_initialize: #237`,
   `Graphics: MediaTek 85xx 1.2`, SaWMan layers) and put a 1920x1080
   DSPF_ARGB surface on the panel for 25 s (photo evidence).

Details: `evidence/bx510/hw-session-2026-11-05/RESULTS.md` and
`evidence/bx510/display-payload/DISPLAY-SPEC.md`.
