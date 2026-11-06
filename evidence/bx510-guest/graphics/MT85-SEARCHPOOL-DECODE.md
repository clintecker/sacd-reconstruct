# MT85-SEARCHPOOL-DECODE — why every pool declined (the rung-d blocker, decoded)

Date: 2026-11-04. Source: disassembly of the retail DirectFB provider
(the shipped `libdirectfb` mt85 system module, listing at
`/tmp/mt85mod/mtk.asm` on the VM), cross-checked against the published
DirectFB 1.2.7 source. This is the condition list the rung-(d) chase
produced; the fbvirt fix it drove is in `tools/bx510_fbvirt.c` (the
MULTI-POOL MODEL comment block). Validated by
`mt85-run5-twopool-rung-d-e.log` (two boots) and the post-fix re-run.

## The decline, precisely

The retail `dfb_surfacemanager_allocate` (0x40e0) dispatches on
`buffer->surface->config.caps & (DSCAPS_PRIMARY|DSCAPS_VIDEOONLY) == 5`:

- EVERY primary layer region surface carries exactly those caps — the
  published `layer_context.c:1509` builds the layer surface with
  `DSCAPS_VIDEOONLY|DSCAPS_PRIMARY`.
- That branch computes `num-2` and returns **DR_TEMPUNAVAIL (26)** if
  `num < 2`: **primary/video-only surfaces may ONLY allocate from
  pools 0..num-2** — the last pool is structurally skipped for them.

With fbvirt's previous ONE-pool GETMULTIPOOL response, the primary
layer surface could NEVER allocate: the gate fires **before any size
comparison**. This single fact explains the entire failed-hypothesis
ledger from the run1–4 era: 8 MiB, 32 MiB, and exact-fit one-pool
topologies all failed IDENTICALLY because none of them ever reached a
size check — the count check (num < 2) rejected them all.

The real MT85xx driver reports multiple memory slices (the ABI is
named `MULTI_MEM_POOL`; `FB_MEM_SLICE_NUM=4` in the retail revision),
so num=2 is the minimal hardware-true topology:
- **pool 0** — the slice primary/video-only surfaces allocate from,
  sized exactly one primary surface: `pitch*height + 16` bytes of
  overrun slack per the core's `dfb_gfxcard_calc_buffer_size`
  (5120x720+16 = 3,686,416; the +16 prefetch slack is published
  source; limits zeroed in no-hardware mode), **page-aligned up to
  3,690,496** (901 pages).
- **pool 1** — the "last" slice the retail skips for primary surfaces.
  The retail allocate never reads `type[]`; its skip-last rule
  embodies the published IOMMU branch's "skip FBMT_VALLOC pools"
  rule, so pool 1 is declared **VALLOC**.

## The second gate: page-alignment (run5's own lesson)

mmap lengths are `PAGE_ALIGN`'d by the kernel before the vma exists,
so a **non-page-multiple `size[i]` can NEVER match the length
dispatch** — with a 3,688,448-byte pool 0 (900.5 pages) the provider's
first pool mmap came back EINVAL and its own "Could not mmap pool!"
aborted init. The mmap-class dispatch (by the published,
collision-free length conventions: pool i requested with exactly
`size[i] + i*0x1000`, ring with the GETCMDBUFLEN value, debug info
with exactly 4096, all at offset 0) requires every `size[i]` to be
page-aligned. Fix: `MT85_POOL0_SIZE = PAGE_ALIGN(1280*720*4 + 16)`.

## The allocation geometry (a measurement instrument, for free)

The primary allocation carves **from the END** of the free chunk
(`offset = pool_size - alloc_length`), which the rung-(e) capture's
scan-locate turns into a length measurement of the retail core's
calculated buffer size: alloc length 3,686,416 lands at offset 4,080
in the 3,690,496-byte pool 0.

## Standing honesty notes (unchanged from run1–4)

- `FBIO_SETMMAPMETHOD` validates + records the requested selector as a
  cross-check, but this 2.6.35 kernel's fb_ops carries no
  `struct file*` into fb_ioctl/fb_mmap (verified in the Sony tree), so
  true per-open-file selector state is unreachable through fbdev; the
  length conventions are collision-free for the shipped provider's
  strictly-ordered single-fd sequence, so observable behavior is
  indistinguishable.
- The command ring's WR_LOCK/UNLOCK/DISPATCHHW/WAITDONE plumbing
  answers, but no command interpreter runs: DISPATCHHW advances
  RdPoint to WrPoint and logs what it consumed — an honest no-op
  (rungs d/e use DirectFB's software rendering; the accelerated path
  is future work).
- Unknown request numbers stay -ENOTTY and are logged with their
  arguments: the log IS the discovery instrument.

## Result

Two-pool topology + page-aligned sizes → rungs (d) and (e) DEMONSTRATED
(two boots in run5; see MT85-RESULTS.md): FillRectangle presents, and
the pool capture MATCHES the independent byte-level expectation.
