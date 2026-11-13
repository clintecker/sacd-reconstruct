# The AUD DSP `0x5110`/`0x5108` readback path — what it compares, what the model must return, and whether it blocks

**Decode, not trace analysis.** Takes `decode/trace-analysis-c95.md` §3 (the `0x5108`/`0x5110`
pair, "2037-word download, 2037-index verify, 20 `aud_hal_8560.c:389` asserts") and answers the
four questions it left as INFERRED: which function owns the loop, what the readback compares
against, what the model rows are, which of the 2037 verify iterations trip the assert, and
whether the whole episode is load-bearing.

**Headline (all four answers):** the owner is `vAudHalSetDspLoadTable()` (`aud_hal_8560.c`,
`0x4b340`), selector `0`; the verify is a **strict per-word equality compare against the source
blob `scm`** — no magic, no nonzero test; the model needs an **index-keyed shadow RAM** (a
last-value register *cannot* pass it); the **20 prints are the stub's rate limit, not the failure
count** — all **2037** compares fail; and the block is **purely cosmetic** (no abort, no retry, no
return value — control flow proceeds to the DSP reset either way).

**Inputs**

| input | what it is |
|---|---|
| `/tmp/bdpdrv/text.dis`, `/tmp/bdpdrv/text.disr` | capstone disassembly of `bdpdrv.ko` `.text` (section-relative VAs, matches `nm_defined.txt`); `text.disr` carries the relocation lines, which is the only way to name `bl` targets (every `bl` renders as `imm = #-0x8` otherwise) |
| `/tmp/bdpdrv/nm_defined.txt` | symbol table (name → VA, size) |
| `/tmp/bdpdrv/all_access.txt` | static MMIO census (site, R/W, EA, owner fn) — from `decode/scan.py` |
| `decode/bdpdrv-runC95.posthandshake.mmio.gz` | committed C95 tail (`gz line N == VM line 541510+N`) — contains the whole ADSP episode |
| `bdpdrv-runC95.uart.log` | console (1878 lines) — assert print positions and the run's continuation |
| `tools/bx510_osal_stub.c` | the guest-side stub that implements `Assert` (decisive for §3) |
| `emulator-kit/sony-bx510.c` | **read only** — the current model rows (working-tree lines 96, 544–547, 778–781; the file is mid-C96-edit, so `grep -n adsp ` beats trusting those numbers) |

**Method.** Static: name the owner from `all_access.txt` (register → function), then read the
function with `text.disr` so the `bl`/`b` targets resolve, and resolve the assert's three literal
operands out of `.rodata.str1.1` by address. Dynamic: one linear pass over the decompressed tail
reconstructing the console inline (the `W 00c000` byte stream) and printing every `0x5100–0x51ff`
access with the console lines emitted between accesses — the same correlation trick
`trace-analysis-c95.md` §Method validated (1878 console lines, exact match). All `0x51xx` counts
below reproduce from that pass: `0x5110` 4075 W, `0x5108` 2037 W + **2037 R**, `0x5100` 2 W,
`0x510c` 1 W, `0x514c`/`0x51cc` 3 W each, and **zero** reads of `0x5100`/`0x510c`/`0x5110`.

---

## 1. The download and the readback

### 1.1 Ownership — one function, one selector, one caller

`0xfd005108` (2 sites) and `0xfd005110` (3 sites) — **five static access sites in the entire
13 MB `bdpdrv.ko`, all inside one function** (`all_access.txt`; the `0x5100`/`0x510c` sites are
included for completeness):

```
0x004b3d0 W4 0xfd005100   str   vAudHalSetDspLoadTable
0x004b3e0 W4 0xfd005110   str   vAudHalSetDspLoadTable     <- download index
0x004b3ec W4 0xfd005108   str   vAudHalSetDspLoadTable     <- download data
0x004b400 W4 0xfd00510c   str   vAudHalSetDspLoadTable
0x004b40c W4 0xfd005110   str   vAudHalSetDspLoadTable     <- verify index
0x004b410 R4 0xfd005108   ldr   vAudHalSetDspLoadTable     <- verify read  (the only read, anywhere)
0x004b444 W4 0xfd005110   str   vAudHalSetDspLoadTable
0x004b448 W4 0xfd005100   str   vAudHalSetDspLoadTable
```

`vAudHalSetDspLoadTable(sel, count, u32 *buf)` is a **28-way jump table** on `sel`
(`0x4b34c cmp r0,#27 ; 0x4b350 ldrls pc,[pc,r0,lsl #2]`). Only **selector 0** drives the
register port (`0x4b3c8..0x4b44c`). The other selectors are *not* this path — they tail-call DRAM
writers, which is why the C95 trace has exactly one burst:

| sel | block | what it does |
|---|---|---|
| **0** | `0x4b3c8` | **register port**: `0x5100←0x20`, 2037×(`0x5110←i`, `0x5108←buf[i]`), `0x510c←2`, 2037×(`0x5110←i`, read `0x5108`, compare), `0x5110←0`, `0x5100←0` |
| **18** | `0x4b520` | the **DSP-C twin**: same shape, base `0xfd047fff` ⇒ effective `0xfd0471{00,08,0c,10}`, its own verify, assert at `aud_hal_8560.c:475`. **Not exercised in C95** (zero `0xfd0471xx` accesses) |
| 1 | `0x4b494` | `WriteDspPSramDramEx(0, buf, count)` — DRAM copy, no MMIO |
| 2 / 3 / 20 | `0x4b450` / `0x4b464` / `0x4b5e0` | `WriteCommon1CacheDramEx` / `WriteCommon2CacheDramEx` / `WriteCommon3CacheDramEx` |
| 6,8,10,22,23,24 | `0x4b4a8`… | `WriteDspCommDramEx(size, …)`, sizes `0x2000 / 0x800 / 0xe00 / 0x16800 / 0x4400 / 0x4420` |
| 9 · 11 · 12 · 13 | `0x4b4c0`… | `WriteDspDecDramEx` · `WriteDec2CacheDramEx` · `WriteDspDec2DramEx` · `WriteDspReencDataDramEx` |
| 14,21,25 | `0x4b510`… | `WriteDspPostCacheDramEx(0x600 / 0xe00 / 0)` |
| 4,19 · 5,26 | `0x4b5a8`… | `WriteReenc2CacheDramEx` · `WriteDec1CacheDramEx` |
| 27 | `0x4b5f4` | `AUD_IsLog(0, "Load aac+ digout code\n")` — log only |
| 7,15,16,17 | `0x4b614` | `return` (no-op) |

Caller chain (relocations resolved):

```
vADSPTaskMain            0x13b74   ("ADSPTask Thread", created during bdpdrv audio bring-up)
 └─ vDspMainInit         0x13b90
     └─ vDspABCommCodeInit   0x1fe0
         ├─ 0x1ffc  vAudHalSetDspLoadTable(0, 0x7f5, &scm)   <- the episode
         ├─ 0x200c  vAudHalSetDspLoadTable(1, 0x7f5, &scm)   -> WriteDspPSramDramEx
         ├─ 0x201c  vAudHalSetDspLoadTable(2, …)             -> WriteCommon1CacheDramEx
         └─ … 0x2098/0x20a8 (sel 23/24) -> WriteDspCommDramEx
     └─ vAudSeInit, vDspInitAvdUiSetting, HdRstDsp_AB(0x134f0) -> vAudHalTriggerDSPAB
```

The count is a **literal**: pool `0x20c8 = 0x000007f5 = 2037`. The buffer is a symbol:
pool `0x20cc = R_ARM_ABS32 scm`, and `scm` is `.rodata` `0x8dc98`, size `0x1fd4` = **8148 bytes =
2037 words exactly** — so the blob length *is* the loop bound; the verify walks the same 2037
words it wrote. (Consistent with a high-entropy compressed/encrypted DSP microcode image, §3.3 of
the trace analysis.)

### 1.2 The loops, verbatim

```
        ; ---- download ----
0x4b3c8  ldr  r2,[pc,#0x248]     ; r2 = 0xfd005000        (pool 0x4b618)
0x4b3cc  mov  r3,#32
0x4b3d0  str  r3,[r2,#0x100]     ; 0x5100 <- 0x20          port/channel open
0x4b3d4  mov  r1,r6              ; r1 = buf
0x4b3d8  mov  r3,#0
0x4b3dc  b    0x4b3f0
0x4b3e0  str  r3,[r2,#0x110]     ; 0x5110 <- index
0x4b3e4  ldr  r0,[r1],#4         ; word = *buf++
0x4b3e8  add  r3,r3,#1
0x4b3ec  str  r0,[r2,#0x108]     ; 0x5108 <- word
0x4b3f0  cmp  r3,r4              ; index < count ?
0x4b3f4  blo  0x4b3e0
        ; ---- mode + verify ----
0x4b3f8  ldr  r7,[pc,#0x218]     ; r7 = 0xfd005000
0x4b3fc  mov  r3,#2
0x4b400  str  r3,[r7,#0x10c]     ; 0x510c <- 2             mode: read-back/verify
0x4b404  mov  r5,#0
0x4b408  b    0x4b434
0x4b40c  str  r5,[r7,#0x110]     ; 0x5110 <- index
0x4b410  ldr  r2,[r7,#0x108]     ; r2 = read data         <-- the readback
0x4b414  ldr  r3,[r6],#4         ; r3 = expected = *buf++
0x4b418  cmp  r2,r3              ; **EQUALS THE WRITTEN WORD**
0x4b41c  beq  0x4b430            ; equal -> next iteration
0x4b420  ldr  r0,[pc,#0x1f4]     ; "0"
0x4b424  ldr  r1,[pc,#0x1f4]     ; "src/driver/aud/hal/aud_hal_8560.c"
0x4b428  ldr  r2,[pc,#0x1f4]     ; 0x185 = 389
0x4b42c  bl   Assert             ; <-- the tripwire, 2037x on a wrong model
0x4b430  add  r5,r5,#1
0x4b434  cmp  r5,r4
0x4b438  blo  0x4b40c
        ; ---- teardown ----
0x4b43c  ldr  r3,[pc,#0x1d4]
0x4b440  mov  r2,#0
0x4b444  str  r2,[r3,#0x110]     ; 0x5110 <- 0
0x4b448  str  r2,[r3,#0x100]     ; 0x5100 <- 0
0x4b44c  pop  {r4,r5,r6,r7,r8,pc}
```

Note the register discipline the download establishes and the verify depends on: **the index is
written before every data access, in both directions.** There is no auto-increment and no
per-word handshake — the port is a plain index/data address pair, and the driver re-drives the
index each time (4075 index writes = 2037 + 2037 + 1).

### 1.3 What the assert actually is

The three operands are literals in the function's own pool, resolved out of `.rodata.str1.1`:

| pool | relocation | value |
|---|---|---|
| `0x4b61c` | `.rodata.str1.1 + 0x1fd69` | `"0"` (the expression string) |
| `0x4b620` | `.rodata.str1.1 + 0x1fd47` | `"src/driver/aud/hal/aud_hal_8560.c"` |
| `0x4b624` | immediate | `0x185` = **389** |
| `0x4b42c` | `R_ARM_CALL Assert` | — |

So the C source is

```c
if (readback != expected)
    AUD_ASSERT(0, "src/driver/aud/hal/aud_hal_8560.c", 389);
```

— a bare `assert(0)` in the mismatch branch. **It carries no condition, no expected value and no
actual value**: the console string `Assert FIRED: 0 (…aud_hal_8560.c:389)` is the whole
information content of the tripwire. Nothing about *which* word failed or *what* came back can
ever be recovered from the console — only from the trace's index sequence plus a model.

### 1.4 Control-flow meaning: it does not abort anything

`Assert` is a normal `void` call (`tools/bx510_osal_stub.c`, `EXPORT_SYMBOL(Assert)`); it returns.
After `0x4b42c` the very next executed instruction is `0x4b430 add r5,r5,#1` → `cmp r5,r4` →
`blo`. Therefore:

* the failing iteration is **not retried** (the retry at `0x4b40c` is for the *next* index),
* the download is **not re-run** (the download loop is behind us — the readback cannot undo it),
* **nothing is returned** (`vAudHalSetDspLoadTable` is `void`; the caller cannot see the failure),
* the teardown (`0x5110←0`, `0x5100←0`) and the caller's continuation (`vAudSeInit`,
  `vDspInitAvdUiSetting`, `HdRstDsp_AB`) run **unconditionally**.

Trace confirmation: after the first assert print the loop is still advancing index
`0x0 → 0x1 → 0x2 …` (gz `2550502 / 2550780 / 2551058 …`), and it runs all the way to index
`0x7f4` (gz `2561232`) before the teardown. The assert is a **log line in the middle of a loop**,
not an abort path.

---

## 2. Model rows — exact semantics and storage shape

### 2.1 Required semantics

> `0x5108` is a **word of DSP program RAM at the address latched by `0x5110`**, not a data
> register. `0x5110` selects the word; `0x5108` reads/writes that word.

Formally, with `adsp_ram[N]` and `adsp_idx`:

| access | must do |
|---|---|
| `W 0x5110 = i` | `adsp_idx = i` (last-written echo on read is fine — no reader exists) |
| `W 0x5108 = v` | `adsp_ram[adsp_idx & (N-1)] = v` — **store at the current index** |
| `R 0x5108` | `return adsp_ram[adsp_idx & (N-1)]` — **return the word at the current index** |
| `W/R 0x5100`, `W/R 0x510c` | last-written echo (already the model's behaviour; nothing reads either in this path) |

Storage shape: **`uint32_t adsp_ram[2048]`** (8 KiB), zero-initialised in `bx510_reset`, index
masked to the low 11 bits. Justification for 2048: the only observed index range is
`0x0..0x7f4` (2037 words — the `scm` blob is `0x1fd4` bytes = 2037 × 4, so the loop bound *is*
the blob length), and 2048 is the smallest power of two above it, i.e. an 11-bit index field. The **real** depth is INFERRED —
nothing in C95 or in `text.dis` exposes it (the driver never writes an out-of-range index and
never reads an unwritten one). Masking is therefore the honest choice: it keeps a stray index
from corrupting adjacent model state, and it cannot affect any observed access.

### 2.2 Why the current rows cannot pass (this is the whole defect)

`emulator-kit/sony-bx510.c` today (working-tree lines 96 / 544–547 / 778–781 — locate them with
`grep -n adsp emulator-kit/sony-bx510.c`, the file is mid-C96-edit and lines will shift):

```c
uint32_t adsp_port, adsp_idx, adsp_data, adsp_mode;   /* line 96  — "last-written-value"  */
case 0x5108: return s->adsp_data;                     /* line 545 — readback verify       */
case 0x5108: s->adsp_data = val; break;               /* line 779 — no index in the store */
```

`adsp_data` is a **single** register. During the verify loop `0x5108` is only *read*, so it
returns the last word the *download* wrote, `scm[2036] = 0x90810162`, for **all 2037** indices.
Against `expected = scm[i]` that fails for every `i`. (The blob has exactly one duplicate word,
`0x961369e9`, twice — and it is not the last word, so literally zero iterations pass.)

| model | failing compares | console `Assert FIRED` lines added |
|---|---|---|
| C95 (single last-value register) | **2037** | 20 (print cap, §3) |
| returns constant 0 (the trace analysis' assumption) | **2037** | 20 |
| **index-keyed `adsp_ram[]` (this recipe)** | **0** | 0 |

Both wrong models produce the *identical* console signature — which is exactly why the trace alone
could not distinguish "unmodelled, returns 0" from "modelled wrong, returns stale". The binary
does distinguish it (§3.2).

### 2.3 Recipe (rows, in the style of `model-c96-diff.md`; **not applied here — read-only file**)

| # | reg | model must | where |
|---|---|---|---|
| A1 | — | add `uint32_t adsp_ram[2048];` and keep `adsp_idx/port/mode` | `Bx510State`, near line 96 (replace the `adsp_data` field) |
| A2 | `0x5110` W | `s->adsp_idx = val & 0x7ff;` | line 781 (add the mask) |
| A3 | `0x5108` W | `s->adsp_ram[s->adsp_idx & 0x7ff] = val;` | line 779 |
| A4 | `0x5108` R | `return s->adsp_ram[s->adsp_idx & 0x7ff];` | line 545 |
| A5 | `0x5100`/`0x510c` | unchanged (last-written echo) | 544, 546, 778, 780 |
| A6 | reset | `memset(s->adsp_ram, 0, sizeof s->adsp_ram); s->adsp_idx = 0;` | `bx510_reset` |
| A7 *(optional, not required)* | `0x514c` `0x51cc` | accept-and-store (writes only; `0x514c←0`, `0x51cc←0xE800` from `vAudHalSetDspABBootUpAddress`) | add to the accepted-silently write case list |

A7 is cosmetic (it removes 6 `unimplemented write` log lines); **no read of `0x514c`/`0x51cc`
exists anywhere in the run**, so no read-back row is wanted. The 3× click of
`0x514c=0 / 0x51cc=0xE800` is the DSP-AB boot-address program: once from `vDspMainInit`'s
`vAudHalSetDspABBootUpAddress` call (gz `2533978`), once from `vAudHalSetDspBootUpAddress`
(gz `2534801`), once from `HdRstDsp_AB → vAudHalResetAndHoldDSPAB` at the end of `vDspMainInit`
(gz `2561984..2561986`).

**Do not** model any `0xa1` behaviour here, and **do not** auto-increment the index on a data
access — the driver re-writes `0x5110` before every data access in both loops. `0x510c = 2` is a
mode select for the read-back direction; nothing observable distinguishes values, only that the
write happens between the two loops.

---

## 3. The 20 asserts — which indices, and why the count is 20 and not 2037

### 3.1 The correlation (assert print vs verify index)

Assert prints land at `bdpdrv-runC95.uart.log` lines **657–677** (20 lines, one gap at 666 where
the `AudInit` thread-creation line interleaves). Against the trace, each print sits **between the
read of index *i* and the index write of *i+1***:

```
   console: [AUD][AUD_IF] Audio Init Thread is created.        (other thread; uart 656)
gz 2550208   W 05110 = 0x000
gz 2550209   R 05108                 <- returns the model's stale word, != scm[0]
   console: [OSAL_STUB] Assert FIRED: 0 (…aud_hal_8560.c:389)  (uart 657)
gz 2550502   W 05110 = 0x001
gz 2550503   R 05108                 <- != scm[1]
   console: Assert FIRED …                                      (uart 658)
gz 2550780   W 05110 = 0x002
...
gz 2555802   W 05110 = 0x013 ; gz 2555803 R 05108   <- iteration 20 (index 0x13)
gz 2556080   Print #20 lands here  -> the LAST print of this site
gz 2556080   W 05110 = 0x014 ; gz 2556081 R 05108   -> iteration 21, NO print
gz 2556082   W 05110 = 0x015 ; gz 2556083 R 05108   -> NO print
      … loop continues to index 0x7f4 with no further prints …
gz 2561233   R 05108 (i = 0x7f4)     <- last compare, still no print
gz 2561234   W 05110 = 0 ; W 05100 = 0   (teardown)
```

So the printed indices are **`0x000..0x013`, contiguous, at the head of the readback** — one print
per iteration, no clustering, no gaps in the index sequence, and **not spread through the loop**.
Nothing in `vAudHalSetDspLoadTable` singles out the first 20 (the loop body is identical for all
2037 iterations, `cmp`/`beq`/`Assert`), so the cutoff cannot be in the driver.

### 3.2 The cutoff is the stub's print budget — proven arithmetically

`tools/bx510_osal_stub.c` `Assert()`:

```c
/* Globally rate-limited (Run C40: four hot sites interleave, defeating
   single-site memory; the flood itself interleaved probe output).
   First 24 asserts print; then every 4096th carries a summary. */
static unsigned long __tot;
__tot++;
if (__tot <= 24) { printk("… Assert FIRED: %s (%s:%lu)\n", …); return; }
if ((__tot & 0xfff) == 0) printk("… Assert x%lu total (last: %s:%lu)\n", …);
```

In this run **exactly 4 asserts fire before this site** — `fbm_main.c:4679`, `drv_init_ko.c:918`,
`km_utility.c:2091`, `aud_hal_8560.c:258` — and the console contains exactly **24** `Assert FIRED`
lines in total, i.e. `24 − 4 = 20` from this site, and then nothing more. The later
`Assert x4096 total / x8192 / …` summary lines in the same log (from the IR thread,
`irrx_if.c:1637`) confirm the counter mechanism is live in this configuration. 4 + 2037 = 2041
< 4096, so not even a summary line was due.

**Therefore: all 2037 verify iterations call `Assert`.** The "20 tripwires" are a
console-instrumentation artefact.

### 3.3 Correction to `trace-analysis-c95.md` §3

That section states the readback "every read returns 0 (unmodelled)" and calls the pair
"unmodelled". The source says otherwise, and the trace agrees with the source:

* `emulator-kit/sony-bx510.c` at **C95 time** (`git show 3437275:emulator-kit/sony-bx510.c`,
  lines 388–391 and 629–632) already had `case 0x5108: return s->adsp_data;` and the matching
  write case — a **single last-value register**. The value it returned was
  `0x90810162` (`scm[2036]`), not 0.
* Corroboration in the trace: there is **no** `unimplemented read 0x70005108` line anywhere in the
  tail, and the `unimp_logs` budget was *not* exhausted (the last line of the tail is still an
  `unimplemented read 0x7002420c`). A read with no case would have logged.

Nothing downstream changes — both wrong models fail all 2037 compares, and the assert text is
identical either way — but the recorded cause ("unmodelled → 0") should read
"modelled as a single register, not as index-addressed RAM". The §7 open item
("whether `0x5108` readback echo alone clears all 20 asserts") is answered **no**: echo alone is
exactly what C95 did.

### 3.4 What a correct model makes them do

Zero `Assert` calls — `2037` compares, `2037` `beq`s taken, loop falls through to teardown,
`vAudHalSetDspLoadTable` returns void having verified the whole blob. The console loses lines
657–677 and nothing else: no new print, no state change, no different branch. The whole-run
`Assert FIRED` count drops **24 → 4** and `aud_hal_8560.c:389` disappears entirely.

---

## 4. Does this block anything? — **Verdict: cosmetic. Not load-bearing, not even a delay.**

### 4.1 Where it sits in the init graph

```
bdpdrv module init (insmod thread)
 ├─ AUD_HwInit, AUD_AoutCfg, AUD_SetDecMemBuffer …        (uart 601–620)
 ├─ i4AudInit_TaskCreate  -> creates "ADSPTask Thread" (vADSPTaskMain)   [uart 627]
 ├─ creates AudDrv0/1/2, AudEff, AudEsm threads, "Audio Init flow: register pm ops"   [uart 640–652]
 └─ returns                                 <-- insmod thread does NOT wait on the ADSP thread
ADSPTask Thread (concurrent, its own thread)
 └─ vADSPTaskMain: vDspMainInit
     ├─ alloc 8929280 B working buffer, SetDspABBootUpAddress, BlkRegInit, HwRegInit, …
     ├─ vDspABCommCodeInit  -> vAudHalSetDspLoadTable(0, 2037, scm)   <-- the episode
     ├─ vAudSeInit, vDspInitAvdUiSetting, HdRstDsp_AB  (DSP reset + trigger)
     ├─ u1AsvDspReady / AReady / BReady / AAoutOn / ReencReady / EncoderReady
     └─ loop { vDspState(); if no _fgDsp{A,B,Uop,HUop}Int -> vDspWaitEvent(3) }
```

So it is **inside the ADSP task thread's own init path**, spawned by bdpdrv's audio bring-up — it
is **not** on the CLI-attach path and **not** on the insmod thread. (The userland CLI probes in the
same log are at uart lines 1545+; `drvcli 144692 1 bdpdrv` shows bdpdrv already resident — this
subsystem is initialised long before anyone talks to `/res/clidev`.)

### 4.2 The C95 run continues past it — evidenced, not assumed

| after the last verify read (gz `2561233`) | console |
|---|---|
| gz `2561234/2561235` | teardown `0x5110←0`, `0x5100←0` |
| gz `2561984/2561986` | `0x514c←0`, `0x51cc←0xE800` — `HdRstDsp_AB` DSP reset/trigger |
| uart 678+ | `alloc x_mem_alloc -> c62f0000 size=6768` … `i4PBBUFComp_Init` ×4 (`x_memset … n=0x1a70`) |
| uart 700–720 | `ev_wait #3/#4 … caller=vDspWaitEvent`, `thread created: DMX0_TH`, `[AUD][AUD_IF] Audio Init Thread is destroyed automatically.`, `x_thread_exit` |
| uart 749–756 | `[HDMI_CTRL][QUICKSTARTMODE]`, `thread created: HDMITask Thread`, `[HDMI]Dual TX re-open …` |
| uart 1000+ | IR thread assert storm, kallsyms probes, CLI `help`/`ver` all working |

The audio init thread **completes and exits**, the ADSP task thread **parks in
`vDspWaitEvent(3)`** (its normal idle state — the model raises no ADSP interrupt and does not
need to), and the driver keeps running for the rest of the 5.77 M-line trace.

The only residual cost is the **loop itself**: 2037 × (2 MMIO writes) + 2037 × (1 write + 1 read)
≈ 8 k emulated accesses, sub-millisecond — no `x_thread_delay`, no timeout, no poll. Not a delay
in any meaningful sense.

### 4.3 The load-bearing question, stated honestly

* **Load-bearing for real hardware audio?** Yes, in principle — 2037 words of DSP microcode are
  the DSP's program; a device that drops them would have a dead DSP. Labelled **inferred**: this
  rig cannot demonstrate it (no DSP is modelled, so no DSP ever executes anything).
* **Load-bearing for the emulator's forward progress?** **No.** Nothing downstream reads the
  verify result, and the driver resets and triggers the DSP as if the load had succeeded. The
  20-line assert storm is the *only* observable.
* **So:** fix the row for **console hygiene and decode honesty** (it stopped a 20-line red herring
  from being read as an audio-init failure), not to unblock a later guest stage. There is no
  later stage it was blocking.

**Pass criterion for the C96 fire:** `bdpdrv-runC96.uart.log` contains **4** `Assert FIRED` lines
(`fbm_main.c:4679`, `drv_init_ko.c:918`, `km_utility.c:2091`, `aud_hal_8560.c:258`) and **no**
`aud_hal_8560.c:389`; the trace still shows `W 05100/05110/05108 … 0510c=2 … 2037×(W 05110, R 05108)
… 05110=0, 05100=0` with the same 2037 index values (`0..0x7f4` twice + final 0).

---

## 5. Open items

| item | label | experiment |
|---|---|---|
| real DSP-RAM depth / index field width (2048 assumed, 2037 used) | INFERRED | invisible to the driver; any `N ≥ 2037` with masking works. Only a decoder of the DSP itself could settle it |
| does a model that returns the *right* word change any behaviour downstream? | **no, by construction** — no branch depends on the verify result (§1.4) and the caller reads no return value; expected C96 delta is exactly −20 console lines, 0 trace-shape changes (INFERRED until the C96 fire) |
| selector 18 (DSP-C twin at `0xfd0471xx`, assert line 475) readback | unexercised, INFERRED symmetric | if a later run instantiates the C-DSP, the same index/data+verify shape applies; needs its own bank |
| `0x514c`/`0x51cc` readback | not needed — writes only, zero reads in 5.77 M lines | — |
| `aud_hal_8560.c:258` `(u4DspStartAddr & 0xFFFFF)==0` | **different cause, not MMIO**: the stub's `init_static_memory` returns `bf07f544`, which is not 1 MB-aligned although the caller asked `align=1048576` (`tools/bx510_osal_stub.c` arena is vmalloc+`align` honoured from the arena offset only). Fix belongs to the stub, not the device model | align the arena base, re-fire, expect that assert to vanish |

## 6. Reproduction

```
# decompress the committed tail (gzip -dc, not zcat: the .gz name confuses zcat on this host)
gzip -dc evidence/bx510-guest/bdpdrv/decode/bdpdrv-runC95.posthandshake.mmio.gz > /tmp/c95tail.log

# counts
grep -c "MMIO W 005108 sz4" /tmp/c95tail.log        # 2037  (download data)
grep -c "MMIO R 005108 sz4" /tmp/c95tail.log        # 2037  (verify reads, the only reads)
grep -c "MMIO W 005110 sz4" /tmp/c95tail.log        # 4075  (2037+2037+1)
grep -c "Assert FIRED" evidence/bx510-guest/bdpdrv/bdpdrv-runC95.uart.log            # 24 (= stub cap)
grep -c "aud_hal_8560.c:389" evidence/bx510-guest/bdpdrv/bdpdrv-runC95.uart.log     # 20 (= 24-4)
awk 'NR<657' evidence/bx510-guest/bdpdrv/bdpdrv-runC95.uart.log | grep -c "Assert FIRED"   # 4

# the interleaved console+MMIO view used for every correlation above: /tmp/c95_adsp.py
# (linear pass; console rebuilt from W 00c000 bytes, reprinted before the first access that
#  follows each completed line — 1878 lines, exact match with the committed uart log)

# static attribution
grep "0xfd005108\|0xfd005110" /tmp/bdpdrv/all_access.txt        # 2 + 3 sites, one function
grep -n "vAudHalSetDspLoadTable" /tmp/bdpdrv/nm_defined.txt     # 0004b340 000002f8 T
# bl targets require /tmp/bdpdrv/text.disr (relocation lines), not text.dis:
#   0x4b42c R_ARM_CALL Assert
#   0x1ffc  R_ARM_CALL vAudHalSetDspLoadTable   (r0=0, r1=0x7f5, r2=&scm)
```
