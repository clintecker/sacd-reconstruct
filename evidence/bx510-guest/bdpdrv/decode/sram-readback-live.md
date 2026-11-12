# BX510 FE-SRAM readback — live debugger evidence: the address, the values, and the model bug

Decisive live experiment for the one open question left by `sata-fw-load.md` §5(a):
the FE boot-code download writes 16 KiB through `0xfd324184`, the driver's own
readback verify reports `SRAM[%04x] WR(0x%02x) != RD(0x00)` for every byte, and the
QEMU model's read case for that offset appeared never to run. **Question: is the
readback actually aimed at a different address (decode error), or does the model
mis-handle a correct address (model bug)?**

**Answer: the model mis-handles a correct address. `0xfd324184` is exactly right,
the reads do reach the model (32,768 of them in one run), and they return 0 because
the model implements *pop-on-read* FIFO semantics that the driver's read-pointer
reset is never applied to.**

**Module under decode (pinned, unchanged):** `/tmp/bdpdrv/sata_mt85xx_mod.ko`,
sha256 `8a0253eb…5456657`, ET_REL, Linux 2.6.35 ARM EABI5.

**Rig:** lab VM `aftermath@10.20.0.18:2222`, `qemu-system-arm` from
`~/bx510-emu/emulator/work/build/` (built 19:26 today, model
`~/bx510-emu/emulator/sony-bx510.c` — it *does* contain both FIFO cases, verified
with `strings`: `bx510: FE-SRAM FIFO wptr=%u` and `bx510: FE-SRAM FIFO read idx=%u`).
Guest run **gdb-run2** = the Run-C77 recipe (`/tmp/runC69.sh` shape) with the images
`/tmp/images-fe` (a checksum-valid FE fixture — this run prints
`FE firmware CheckSum OK !!` / `Tag Version 0x24`, so unlike C55 it reaches the SRAM
stage) plus `--qemu-extra "-s -d unimp,guest_errors"`.

Evidence artifacts (this directory):

| file | what |
|---|---|
| `listings/sram-readback-rsp-transcript.txt` | the raw GDB-RSP session: every packet, every register dump |
| `listings/sram-fifo-guest_errors.txt` | the model-side counters for the same run (`-d unimp,guest_errors`) |
| `tools/bx510_gdb_rsp.py` (repo root) | the instrument — see §2 |
| `tools/test_bx510_gdb_rsp.py` (repo root) | its selftest: framing/checksum + register decode against an in-process fake stub, with two mutants (checksum, endianness) that must fail |

---

## 1. Bottom line

1. **The effective address of the readback read is `0xfd324184` (PA `0x70324184`),
   verified live, not inferred.** Both `ldr`s that touch the FIFO data register —
   `.init.text+0x58c` (inside the *write* loop) and `.init.text+0x5cc` (the readback
   loop) — evaluate to `0xfd324fff - 0xe7b = 0xfd324184`. `sata-fw-load.md` §5(a) is
   correct; **there is no decode error.**
2. **The reads reach the model.** In gdb-run2 the model logged **32,768
   `bx510: FE-SRAM FIFO read` lines** through the boot-code pass (16,384 from the
   write loop + 16,384 from the readback loop) alongside the known 16,386 `wptr`
   lines. The instruction at `.init.text+0x58c` returned the byte just written
   (`0xcd`), proving the read path works *and* that it consumes the cursor.
3. **`RD(0x00)` is a model bug of FIFO semantics, not of addressing.** The model
   returns `sram_fifo[sram_ridx++]` on every read, so the 16,384 dummy readbacks the
   compiler left inside the write loop exhaust the 16 KiB FIFO; the driver's
   **read-cursor reset** — `*[0xfd324180] = 0` at `.init.text+0x5bc`, immediately
   before the verify loop — only resets `sram_wptr` in the model, not `sram_ridx`.
   The verify loop therefore reads from index 16,384 onward, i.e. past the end, and
   gets 0 for all 16,384 bytes.
4. **Next fix (2 lines, `emulator-kit/sony-bx510.c`, not applied here):** in the
   write case for `0x324180`, mirror the pointer into the read cursor
   (`s->sram_ridx = val;`). §5 gives the patch and the validation expectations.

The SRAM verify is **not** what blocks port-up: a mismatch prints but does not abort
(`sata-fw-load.md` §5(a)) and this run continues into the AACS download and
`sata_mt85xx_xfer_int_ldr_fw`. It is a rig-fidelity bug that will matter the moment
anything gates on the FE boot code loading correctly.

---

## 2. Method — why a hand-written RSP client, and how to re-run

`/usr/bin/gdb` on the lab VM is an **x86-only** build; it cannot debug the ARM guest:

```
(gdb) target remote :1234
warning: while parsing target description (at line 1): Target description
         specified unknown architecture "arm"
(gdb) set architecture arm
Undefined item: "arm".
```

No ARM gdb exists on the VM (the `~/arm-2009q3` tree carries only `libc`), and
installing one means an outbound package fetch the lab policy does not cover for
tooling. QEMU's gdbstub speaks plain ASCII RSP, so `tools/bx510_gdb_rsp.py` drives it
directly: `g` register reads, `Z1` hardware breakpoints, `Z2/Z3/Z4` watchpoints,
`s`/`c`, and RAM reads. It prints every packet in both directions, so the transcript
*is* the evidence. Commands come from stdin, so a FIFO makes the session interactive
while the guest runs — needed because the window of interest is ~10 s into boot.
The client's framing and register decode are locked by
`tools/test_bx510_gdb_rsp.py` (run it directly or through pytest; two mutants —
checksum off-by-one, big-endian register decode — must fail).

Two properties make this cheap and repeatable:

* the watchpoint address `0xfd324184` is a **fixed guest virtual address** (the kernel
  maps `0xfd000000..0xfdffffff` → `0x70000000..` as one section, `kernel-iomap.md` §2),
  so nothing has to be known about the module before it loads;
* the module's `.init.text` runtime base falls out of the first hit — PC minus the
  known section offset — and is then *confirmed* by reading the instruction bytes back
  through the stub and comparing with the `.ko`.

```
# VM, three shells (or setsid'ed), same second:
/tmp/runC80.sh                                  # probe with --qemu-extra "-s -d unimp,guest_errors"
python3 -u tools/bx510_gdb_rsp.py < $FIFO       # attaches ~2 s after qemu starts
echo 'watch 0xfd324184 4' >> $FIFO ; echo c >> $FIFO
```

---

## 3. Static anchors (what the machine code says)

From `listings/sata_mt85xx_init_int_ldr.txt` (`.init.text`, `sata_mt85xx_init_int_ldr`
= st_value `0x204`, size `0x584`; literal pool entry `.init.text+0x760 = 0xfd324fff`):

| addr | instruction | meaning |
|---|---|---|
| `+0x534` | `ldr r0,[pc,#0x220]; mov r2,#16384; bl printk` | `[IDE]download boot code to SRAM (0x%x, 0x%x)` |
| `+0x56c` | `str r4,[lr,#0x188]` (r4=69) | `*[0xfd024188] = 69` (SRAM clock) |
| `+0x570` | `str r12,[r1,#-0xe7f]` (r12=0) | `*[0xfd324180] = 0` — pointer := 0 |
| `+0x574` | `str r3,[r2,#-0xe7f]` | `*[0xfd324180] = i` — **pointer := i, every iteration** |
| `+0x578` | `ldrb r1,[r0,r3]` | byte from `fw[BOOT.f0 + i]` (r0 = `sata_int_ldr_fw`) |
| `+0x584` | `str r1,[r2,#-0xe7b]` | `*[0xfd324184] = byte` — the FIFO write |
| `+0x588` | `ldr r4,[pc,#0x1d0]` | r4 = `0xfd324fff` (reload) |
| **`+0x58c`** | **`ldr r1,[r2,#-0xe7b]`** | **`*[0xfd324184]` READ, once per write, value discarded** |
| `+0x590` | `bne +0x574` | loop, 16,384 iterations |
| `+0x5a8` | `bl __get_free_pages` | `p` = 16 KiB readback buffer (GFP `0x40d0`, order 2) |
| `+0x5bc` | `str r2,[r4,#-0xe7f]` (r2=0) | **`*[0xfd324180] = 0` — read-cursor reset before the verify** |
| **`+0x5cc`** | **`ldr r2,[r1,#-0xe7b]`** | **`*[0xfd324184]` READ — the readback loop (r1 = `0xfd324fff`)** |
| `+0x5d0` | `strb r2,[r3],#1` | `p[i] = byte` |
| `+0x5d4`/`+0x5d8` | `cmp r3,r0` / `bne +0x5cc` | 16,384 iterations |
| `+0x5fc`..`+0x640` | compare `p[i]` vs `fw[…]`, print on mismatch | `[IDE]SRAM[%04x] WR(0x%02x) != RD(0x%02x)` |
| `+0x644`..`+0x670` | `[IDE]verify boot code -- %s` (`OK`/`NG`), `r10` = mismatch flag | |

**Correction to `sata-fw-load.md` §5(a):** that table lists the write loop as
`+0x578..+0x590 for i: *[0xfd324184] = fw[…]` and mentions only the readback loop's
read at `+0x5cc`. The write loop **also reads** `0xfd324184` on every iteration
(`+0x58c`). That read is invisible in the driver's own logic (its result is loaded into
`r1` and then immediately overwritten at `+0x5b0`), but it is not invisible to hardware
or to the model — it is the whole reason the verify reads zeros. Also note
`0x324180` is used as a **random-access index**, not an auto-incrementing write
pointer: the driver stores `i` into it before writing byte `i`.

---

## 4. Live evidence (gdb-run2, transcript in `listings/sram-readback-rsp-transcript.txt`)

`.init.text` runtime base = **`0xbf040000`**, derived from stop 1 (PC − 0x584) and
*confirmed* by reading the code back: `m bf04058c,8` → `e5121e7b 1afffff7`, the
`.ko` bytes at `.init.text+0x58c` / `+0x590`.

| # | stop | PC (runtime) | = section | registers that matter | loaded / written value |
|---|---|---|---|---|---|
| 1 | `Z4,fd324184,4` watchpoint hit (`T05thread:01;awatch:fd324184;`) | `0xbf040584` | `.init.text+0x584` | `r1=0x000000cd`, `r2=0xfd324fff` → **EA `0xfd324184`**, `r3=1`, `r4=0x45`, `r0=0xdd900000` (`sata_int_ldr_fw`) | byte being written = `0xcd` (= `fw[0]`) |
| 2 | `Z1,bf04058c` | `0xbf04058c` | `.init.text+0x58c` | `r2=0xfd324fff` → **EA `0xfd324184`** | — |
| 3 | one `s` from stop 2 | `0xbf040590` | `.init.text+0x590` | `r1=0x000000cd` | **write-loop read returned the byte just written** |
| 4 | `Z1,bf0405cc` | `0xbf0405cc` | `.init.text+0x5cc` | `r1=0xfd324fff` → **EA `0xfd324184`**, `r5=0xddb10000` (p), `r0=0xddb14000` (p+0x4000), `r3=0xddb10000` | — |
| 5 | 3 × (`s`…`s`) | `0xbf0405cc` ×3 | `.init.text+0x5cc` | `r1=0xfd324fff` each, `r3` → `0xddb10001`, `0xddb10002` | **`r2=0x00000000` on all three iterations** |
| 6 | `Z1,bf040644` (after the compare loop) | `0xbf040644` | `.init.text+0x644` | `r10=0xffffffff` (mismatch), `r4=0x00004000`, `r5=0xddb10000` | readback buffer `0xddb10000` first 32 B = all `00` |

**CPU context.** Every stop is `cpsr` mode `0x13` = **SVC (process context)**, `I=1`
(IRQs masked by the driver around the download), `F=0`, and at the verify
`cpsr=0x80000153` with `sp=0xdda41ef8`. `thread_info` = `sp & ~0x1fff` = `0xdda40000`:
`flags=0`, **`preempt_count=0`** → not softirq/hardirq; `task=0xc617ee60` (the
module-init task on the 8 KiB kernel stack at `0xdda40000`; the task name was not
resolved — no ASCII `comm` inside the dumped window — so "process context, not
interrupt context" is the claim, VERIFIED by mode + preempt_count). No IRQ is
involved in the readback path.

**Cross-check that the reads really returned 0 everywhere.** The verify prints only
mismatches, and this run printed 16,320 mismatch lines, ending at `SRAM[3fff]`.
In the same boot-code pass, **64** of the 16,384 write-loop reads returned `val=00`
(16,448 `val=00` reads in the pass − 16,384 readback-loop reads). 16,384 − 64 =
16,320: the 64 fixture bytes that are already `0x00` compare equal and print
nothing. The two independent sides of the same event agree to the byte.

## 5. Model-side evidence (same run, `listings/sram-fifo-guest_errors.txt`)

`-d unimp,guest_errors` on the VM's 19:26 binary, boot-code pass only:

```
FE-SRAM FIFO wptr writes : 16386      (1 initial + 16384 in-loop + 1 reset)
FE-SRAM FIFO read  lines : 32768      (16384 write loop + 16384 readback loop)

read idx=0     val=cd     <- write loop: the byte just written
read idx=1     val=df
read idx=16382 val=8a
read idx=16383 val=d9
read idx=16384 val=00     <- readback loop: cursor pinned at end, every read 0
read idx=16384 val=00
...
read idx=16384 val=00     (last of the pass)
```

The wptr sequence shows the pointer reset that the model ignores for reads:
`… wptr=16382, wptr=16383, wptr=0` — the `wptr=0` at the end of the pass is
`.init.text+0x5bc`, i.e. the driver asking for the readback to start at index 0.

A **second** FIFO download follows in the same run —
`[IDE]download AACS code (0x0, 0x4000) ... start/end` — adding 16,385 wptr writes and
16,384 reads (write loop only; the AACS path has no verify loop), all still at
`idx=16384 → val=00`.

> Why the "zero reads" reading existed. What I can state as measured facts:
> (a) C76/C77's copied `*.mmio.log` artifacts are **0 bytes — no FIFO line and no
> `unimplemented` line at all** — while their UART transcripts show the SRAM stage ran,
> so logging was effectively off in those runs (mask or `-D` path, not the guest);
> (b) killing the probe before it copies QEMU's temp `-D` file loses the log wholesale
> (run-1's temp log reached 8.3 MB and no artifact was ever produced), because the probe
> copies at the end (`shutil.copyfile(unimp, a.unimp)` in `tools/bx510_bdpdrv_stub_probe.py`);
> (c) every artifact I could produce that contains `wptr` lines also contains the sibling
> `read` lines from the same handler (this run: 16,386 / 32,768).
> A log with 16,386 `wptr` lines and no `read` lines is therefore consistent only with a
> binary whose read path predates commit `0a4d6f5` (which added the `0x324184` read case;
> those reads then fall to `default:` at `LOG_UNIMP` and return 0, invisible under a `-d`
> mask without `unimp`). Neither state exists in the binary this doc was produced on.

## 6. The fix

`emulator-kit/sony-bx510.c` (write case; the read case already does
`sram_fifo[sram_ridx++]` with an end-of-FIFO guard):

```c
    case 0x324180: /* FE SRAM FIFO pointer. The driver uses it as a random-
                    * access index (stores i before byte i) and resets it to 0
                    * before the readback verify (.init.text+0x5bc). Reads of
                    * 0x324184 auto-increment the same cursor, so the reset must
                    * move the read cursor too — otherwise the 16,384 dummy
                    * readbacks at .init.text+0x58c exhaust it and the verify
                    * reads 0 forever (decode/sram-readback-live.md). */
        qemu_log_mask(LOG_GUEST_ERROR, "bx510: FE-SRAM FIFO wptr=%u\n", (unsigned)val);
        s->sram_wptr = val;
        s->sram_ridx = val;
        break;
```

Validation (PREDICTED, not yet run) — same recipe, expect:

* `wptr` 16,386 and `read` 32,768 unchanged in the model log;
* write-loop reads unchanged (`idx=i, val=fw[i]`); readback-loop reads now
  `idx=0..16383` returning the written stream in order;
* UART: **zero** `SRAM[…]) WR(…) != RD(…)` lines and `[IDE]verify boot code -- OK`;
* the loader then proceeds exactly as today (`xfer_int_ldr_fw`, AACS download,
  `port_start` polls).

Do **not** "fix" this by making the read non-popping: the driver reads
`0xfd324184` 16,384 times expecting the ascending stream (a sticky/random-access data
register would fail at index 1). Pointer-write-mirrors-read-cursor is the only
semantics that satisfies both phases of the driver.

## 7. Scope — what this changes and what it does not

* **Unchanged:** `SocVerifyMainCode`'s acceptance criteria, the blank-`fe_bin_1`
  conclusion for C55, the DRAM half, `port_start`'s two polls. Nothing here says
  anything about them.
* **Changed:** `sata-fw-load.md` §5(a)'s write-loop row (the in-loop read at `+0x58c`)
  and the implication that the verify's zeros mean the reads never happened.
* **Still open:** why the model logs 4.4 GB of `unimplemented write 0x7005c804 =
  0x10000` in the same run (a post-`port_start` poll loop; that storm is what makes
  `-d` artifacts dangerous to capture at all — cap or drop the log after the FE
  stage).
