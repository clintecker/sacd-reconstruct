# NFI read-side log + the FATB/harness collision, settled

Scope: `decode/tagfix-mtd-trace.md` §6(i) (the instrumentation handoff) and §2.2 (the
harness clobber). Two changes, both in the working tree, nothing committed:

| file | change |
|---|---|
| `emulator-kit/mt8560-nfi.c` | read/write-side NFI log, gated on `BX510_TRACE` (spec §6(i)) |
| `tools/bx510_bdpdrv_stub_probe.py` | opt-in `--fatb-fixture` restage (the §2.2 verdict's fix) |

Everything below is labelled **VERIFIED** (tool output / source cited) or **INFERRED**.
Disassembly is of `/tmp/sata_mt85xx_mod.ko`, sha256 `8a0253eb…f5456657` — the module
`fe-tags.md` pins and the one the C97 run loaded — via Apple `objdump -d`.

---

## 1. The patch (VERIFIED: it fires, compiled and linked on the VM)

`mt8560-nfi.c` had no flags of its own and no access to `Bx510State`, so the gate is a
one-shot `getenv("BX510_TRACE")` cached in a file-static, which is the same variable
`sony-bx510.c:883` (`s->trace_all = getenv("BX510_TRACE") != NULL;`) uses:

```c
static bool nfi_traced(void)
{
    static int traced = -1;
    if (traced < 0) {
        traced = getenv("BX510_TRACE") != NULL;
    }
    return traced;
}
```

Three log sites, all `qemu_log_mask(LOG_GUEST_ERROR, …)` (so they land in the `-D` log
whenever the caller passes `-d guest_errors`, which `bx510_bdpdrv_stub_probe.py`
already does — the same mechanism the `bx510:` lines use):

```
nfi: col=0x<val>                       nfi_write() case 0x34
nfi: row=0x<val>                       nfi_write() case 0x38
nfi-xfer: rd cfg=%x ctrl=%x sectors=%u size=%u dma=%x aut=%u row=0x%x col=0x%x page=%u
nfi-xfer: wr cfg=%x ctrl=%x sectors=%u size=%u dma=%x aut=%u row=0x%x col=0x%x
```

logged in `nfi_transfer()` before the bus loop, one line per transfer direction, with
`page` on the read line only (a write serves no page). The unsupported-transfer path
keeps its existing `LOG_UNIMP` line.

### 1.1 `page = row` — and tagfix §3's page formula is wrong (VERIFIED)

`tagfix-mtd-trace.md` §3 says `PAGE(addr) = addr >> 11 = (col>>11) | (row<<5)`, i.e. that
the column carries page bits 0..4. **That does not hold for this QEMU version.** From
`hw/block/nand.c` (qemu-9.2.4, the pinned tree on the VM):

```
line 121:  # define PAGE(addr)          ((addr) >> ADDR_SHIFT)
line 142:  # define ADDR_SHIFT          16          /* inside #if NAND_PAGE_SIZE == 2048 */
line 123:  # define PAGE_MASK           ((1 << ADDR_SHIFT) - 1)
line 126:  # define SECTOR(addr)        ((addr) >> (9 + ADDR_SHIFT - PAGE_SHIFT))
```

and `nand_setio()` (line 506 on) assembles the address as
`shift = s->addrlen * 8; s->addr = (s->addr & mask) | (value << shift)`, with the
`case 2` hook doing `s->addr <<= (s->buswidth - 1)` = `<< 0` for this 8-bit part. So the
five LP address cycles become `addr = col | (row << 16)`, and therefore

```
PAGE(addr) = addr >> 16 = row          ← the row register IS the page
PAGE_MASK  = 0xffff = the in-page byte offset (col)
```

Consequences: (a) `page` in the new log line is just `n->row`, no arithmetic to get
wrong; (b) a non-zero column is an **in-page** offset, not a page shift — the model is
less prone to the "32 pages away per row unit" failure mode §3/§4 hypothesis (a)
worried about, and the column only takes effect at 512-byte sector granularity
(`SECTOR(addr) = addr >> 14`, `SECTOR_OFFSET(addr) = addr & ((511 >> 11) << 8) = 0`).
The page/offset table in §3 (7168 / 7680 / 8192 for the three FE partitions) is
unaffected — those are row numbers and they are right.

`mt8560-nfi.c` is the only writer of the chip address (case 0x30 pushes exactly
`n->col` then `n->row`), so `row` cannot drift from what the chip was told.

### 1.2 Live proof the observable now exists (VERIFIED)

Rebuilt on the VM (`ninja libqemu-arm-softmmu.a.p/hw_arm_mt8560-nfi.c.o` clean, then
`ninja qemu-system-arm` links), then one plain shell boot with `BX510_TRACE=1` and
`-d guest_errors` (`-D /tmp/nfi-trace.log`, `snapshot=on`, no image write):

```
log lines: 7091648  nfi-xfer: 4622  nfi: 9254
  nfi-xfer: rd cfg=1303 ctrl=2180 sectors=2 size=2048 dma=dd8e8020 aut=1 row=0x1ffc0 col=0x0 page=131008
  nfi-xfer: rd cfg=1303 ctrl=2180 sectors=2 size=2048 dma=dd8e8020 aut=1 row=0x1ff80 col=0x0 page=130944
  nfi: col=0x0
  nfi: row=0x0
  nfi: row=0x1ffc0

transfers: 4622 {'rd': 4620, 'wr': 2}
cfg/ctrl pairs: [(('1303', '2180'), 4620), (('3301', '2280'), 2)]
unique rows: 4569 min 0x0 max 0x1ffc1 out of range: 0
top rows: [('0x1ffc0', 4), ('0x1ff80', 4), ('0x1ff40', 3), ('0x1ff00', 3), ...]
total row-register writes: 4627
```

Three things this settles in one shot:

1. The NFI window is no longer blind (C97 had 0 accesses; the same boot now yields 4622
   transfers and 9254 register writes).
2. `row` is a **page** number: every one of the 4569 distinct rows is < `pages`
   (0x20000). A byte address or a shifted page would have gone out of range immediately.
   The stride `0x40` (= one eraseblock of 64 pages) backwards from `0x1ffc0` is a
   boot-time whole-device eraseblock scan.
3. **The guest can program NAND through this model**: 2 write transfers
   (`cfg=3301 ctrl=2280`, 2×512 B sectors = 1024 B) during a plain boot. That is the
   precondition the in-guest restage in §2.3 depends on, and it is now evidenced rather
   than assumed.

Cost note: `BX510_TRACE=1` is the machine model's *full* MMIO flag, so the same run
produced 7.09 M log lines (C97, MMIO-only, was 3.5 M). The gate is shared on purpose —
spec §6(i) and this task both require the same env var — but whoever fires the next run
should expect ~2× C97 log volume.

---

## 2. The `fe_test_data` collision: FATB **cannot** coexist with the tar staging

### 2.1 The driver's FATB reader has no address parameter (VERIFIED)

`tagfix-mtd-trace.md` §2.1 says `MTDAdvRead` "walks eraseblocks from `start_addr` …
skips and keeps scanning". The disassembly says something narrower, and it is the whole
verdict:

| address | code | meaning |
|---|---|---|
| `0xb30` | `mov r4, r1` | 2nd argument (the "16/20/30" number) is loaded and never read again — dead, as `fe-tags.md` §2.2 says |
| `0xbf0`-`0xc20` | `r6=0; r5=0; r11=0; [sp,#0x18]=0` | offset starts at **0**, accumulated count 0, "latest record" 0 — no path stores `start_addr` into any of them |
| `0xc38`-`0xcc4` | loop head: `while (offset < mtd.size)`; `[sp,#0x58]` is `mtd_info_user.size`, `[sp,#0x5c]` is `erasesize` | the only limit is the partition size |
| `0xc44`-`0xc84` | `blk = offset & -erasesize`; `MEMGETBADBLOCK(fd, blk)` with a one-block cache | bad-block check is per eraseblock |
| `0xd90`-`0xdcc` | `pread64(fd, sata_mtd_read_buf, writesize, offset)`; `strncmp(buf, tag, 4)` | one page compared against the tag |
| `0xdd0`-`0xdd8` | match: `[sp,#0x18] = offset`; `offset += aligned` | `aligned` = `round_up(len, writesize)` computed at `0xbd8`-`0xc24` (0x2020 → 0x2800, 0x2000 → 0x2000 — the `Align len` figures in the C97 UART) |
| `0xe50`→`0x12b0`→`0xe5c` | **mismatch: print `TAG mismatched, Latest stored data in start_addr = 0x%08X`, then `offset = mtd.size`** | the scan **terminates** on the first page that does not match |
| `0xcc8`→`0x12e4` | exit: `Read from addr : 0x%08X, len : 0x%08X, Align len : 0x%08X` | summary line |
| `0xf98`-`0x1028` | second loop: `pread64` page by page from `[sp,#0x18]`, `offset += writesize` while `accumulated < len && offset < size` | the *linear* read-back |
| `0x10ac`-`0x10b8` | `memcpy(out + bytes_copied, sata_mtd_read_buf, min(len - bytes_copied, writesize))` | what the caller's buffer ends up with |

So the effective semantics are: **look for the record at offset 0, then only at
`0 + k*aligned` while it keeps matching; on the first miss, stop scanning and linearly
read `len` bytes from the last matching offset (0 if nothing ever matched).**

Three consequences, all of which the C97 UART confirms:

* **`MTDAdvRead` cannot be pointed at `0x80000`.** No argument sets the start address
  (dead 2nd arg), the loop starts at 0 unconditionally, and a record at 0x80000 is
  unreachable twice over: the scan aborts at page 0, and the linear read-back starts at
  0 regardless.
* **This is exactly why C97 printed `shim`.** Nothing matched at page 0 (the tar's first
  bytes are the ustar member name `shim/osal_stub.ko`), "latest stored data in
  start_addr" stayed `0x00000000` — the value C97 printed — and the linear read handed
  the caller page 0 of the partition, i.e. the tar. §2.2 of `tagfix-mtd-trace.md` is
  therefore *explained by the code*, not just by the coincidence of `b'shim'`.
* **`fe-tags.md` §4.3 gate 4 is unachievable.** "no `MTDAdvRead> TAG mismatched`
  anywhere" cannot pass for the FATB reader even with a perfect fixture: after the match
  at offset 0 the scan advances to `0x2800` (the next aligned slot, erased 0xFF), which
  mismatches, and the `TAG mismatched, Latest stored data in start_addr = 0x…` line is
  printed **on the success path too**. The achievable gate is the *caller-level* line
  (`no TAG mismatch:xxxx` and no `read FA table from FW offset`), which is gate 2.

### 2.2 Verdict

**NO — there is no offset inside `fe_test_data` where the FATB record can coexist with
the tar staging.** The only offset the driver reads is 0 (partition head), and that is
exactly where the ustar stream starts. "Pad the member name so page 0 is zeros" cannot
work either: the driver needs `46 41 54 42` (`FATB`) at page 0, not zeros — zeros are as
good as the tar bytes (both mismatch, both fall back to `latest = 0`).

Note the offset is not a *tuning* question, so no amount of partition-offset arithmetic
rescues it; the collision is structural. Two fixes exist, and the second one is
implemented here.

### 2.3 The fix implemented: restage the record from inside the tar (opt-in)

`tools/bx510_bdpdrv_stub_probe.py` gained `--fatb-fixture PATH`:

* the (0xFF-padded, whole-page) record rides **inside** the tar as `shim/fatb.bin`;
* immediately **after** `/bin/tar -xf`, the guest writes it back to the partition head:
  `/bin/dd if=/res/shim/fatb.bin of=/res/test-bdev bs=2048 count=<pages>`;
* `meta.json` grows a `fatb_fixture` block (`host_path`, `sha256`, `size`,
  `restage_pages`) — additive, existing keys unchanged.

Why this is the right shape:

* the record lands exactly where the driver looks (partition offset 0), and the tar has
  already served its purpose (modules are in tmpfs) when it is overwritten;
* it needs no partition war and no second scratch partition — `tagfix-mtd-trace.md` §5
  is right that none of the 25 partitions is genuinely free;
* the write path is proven to work in this model (§1.2: 2 page programs during a boot);
* nothing changes unless the flag is passed — the default run is byte-for-byte the old
  behaviour (fixtures applied to the image beforehand are still clobbered, as today).

Exact apply sequence (replaces the fe_test_data half of `apply_tag_fixtures.sh`):

```sh
# 1. build the records (unchanged)
python3 evidence/bx510-guest/bdpdrv/decode/build_fe_tag_fixtures.py \
    --outdir evidence/bx510-guest/bdpdrv/fixtures
# 2. image side: PARM + PWRC only (unchanged — their partitions are not staged into).
#    fe_test_data is now carried by the harness, so applying it to the image is pointless.
# 3. fire with the restage (8224 B record -> 5 pages):
python3 bx510_bdpdrv_stub_probe.py \
    --qemu work/build/qemu-system-arm --images /tmp/images-fe \
    --stubko /tmp/osal_b/bx510_osal_stub.ko --stuba-ko /tmp/osal_a/bx510_osal_stub_a.ko \
    --bdpdrv-host /tmp/rootfs/lib/modules/2.6.35/BDP/bdpdrv.ko \
    --bdpdrv-guest /lib/modules/2.6.35/BDP/bdpdrv.ko \
    --fatb-fixture fixtures/fe_test_data.bin \
    --uart /tmp/bdpdrv-runC98.uart.log --unimp /tmp/bdpdrv-runC98.mmio.log \
    --meta /tmp/bdpdrv-runC98.meta.json
```

Verification expectation on that run: `FATB_RESTAGE=0` in the UART, then **no**
`SocReadFaTable>(Error)TAG mismatch:shim` and **no** `read FA table from FW offset`
(fe-tags §4.3 gate 2), while `MTDAdvRead> TAG mismatched, Latest stored data in
start_addr = 0x00000000` **still prints** (§2.1 — that line is not a failure signal) and
the companion `nfi-xfer: rd … page=7168` line appears in the trace if `BX510_TRACE=1`.

Alternatives, if the parent prefers not to touch the guest write path:

* **move the staging partition** — `mknod … 31:<n>` for a partition no fixture uses
  (e.g. `upg_status`), leaving `fe_test_data` to the image-side fixture. Bigger change
  (partition size + guest-side risk), same effect;
* **drop the FATB fixture** — `tagfix-mtd-trace.md` §5.1's "cheapest correct move": the
  `fe_bin_1 + 0xFE000` fallback already succeeds, so the fixture is log hygiene only.

---

## 3. Doc corrections this pass produced

1. **`tagfix-mtd-trace.md` §3**: `PAGE(addr) = (col>>11) | (row<<5)` is wrong for
   qemu-9.2.4's `nand.c` — `ADDR_SHIFT` is 16 for the 2048-byte page, so
   `PAGE(addr) = addr >> 16 = row` and the column is the in-page byte offset (§1.1).
   The §3 page table (7168/7680/8192) stands; only the formula was wrong.
2. **`tagfix-mtd-trace.md` §2.1**: `MTDAdvRead` does not "skip and keep scanning". The
   tag scan **aborts** at the first mismatching page (`offset = mtd.size`) and the result
   is then a *linear* read of `len` bytes from the last matching offset — which is why a
   zero-match read returns partition page 0 verbatim (§2.1 table above).
3. **`fe-tags.md` §4.3 gate 4** ("no `MTDAdvRead> TAG mismatched` at all") cannot pass
   with any fixture; the reachable gate is gate 2 (no caller-level `TAG mismatch` and no
   `read FA table from FW offset`), because the reader probes the next aligned slot after
   a match by design.
4. **`tagfix-mtd-trace.md` §4 hypothesis (a)** ("the guest programs an 11-bit column and
   is 32 pages off per row unit") is now ruled out as a *model* failure mode: the column
   never moves the page. Whatever the guest asks for, `row` names the page — so the
   PWRC/PARM residue (`b6 7a 75 2c`, `ff ff ff ff`) is a read-path/guest-side question,
   and the tool to answer it is the log in §1 (fire C96/C97's replay with
   `BX510_TRACE=1` and compare the `page=` values against 8192 / 7680).

---

## 4. Reproduce

```sh
# build + link the model with the log (kit sources are staged by sacd-kit-stage)
sh ~/bx510-emu/emulator/build.sh ~/bx510-emu/emulator/work      # on the VM
cd ~/bx510-emu/emulator/work/build && ninja qemu-system-arm

# the observable, without staging anything (read-only boot, snapshot=on)
BX510_TRACE=1 python3 /tmp/nfi_trace_probe.py     # boots, greps -d guest_errors log
python3 /tmp/nfi_trace_stats.py /tmp/nfi-trace.log

# the FATB restage, Mac-side staging of the record
python3 evidence/bx510-guest/bdpdrv/decode/build_fe_tag_fixtures.py
python3 tools/bx510_bdpdrv_stub_probe.py … --fatb-fixture fixtures/fe_test_data.bin …
```

Scripts used for the evidence above: `/tmp/nfi_trace_probe.py` (boot + count) and
`/tmp/nfi_trace_stats.py` (histogram); both are throwaway harnesses, not committed —
the numbers they printed are quoted in §1.2.

---

## 5. Status / residual risks

* Working tree only, nothing committed (`mt8560-nfi.c`, `bx510_bdpdrv_stub_probe.py`).
* The VM's qemu tree + binary now carry the logging patch (kit copy
  `~/bx510-emu/emulator/mt8560-nfi.c` also updated, so `build.sh` reproduces it).
* The restage has not been fired against a guest: its two halves are verified
  independently (tar member + 0xFF padding + page count — local check, §2.3; NAND page
  program through the model — §1.2). The end-to-end gate is `FATB_RESTAGE=0` plus gate 2
  on the next full run.
* A shell boot already writes the flash twice (2 page programs, §1.2). Any run that is
  supposed to be read-only must keep `snapshot=on` — the model does honour writes.
