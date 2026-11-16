# fn_diff literal policy + the sacd_read module's scope (issues #12 / #2)

Date: 2026-11-15. Machine: Mac (arm64, llvm-objdump 22). **Decode-first, Mac
side only — no VM fires, no emulator, no player.** Every number below was
produced by the commands in §7 against the tracked ELFs
(`original/sacd_extract_160`, `reconstruct/release/sacd_extract_160_release`).

Scope: the two questions standing between this repo and any hardware parity
claim (#6)

* **(#12) which literal values does the parity harness actually compare, and
  which must match?**
* **(#2) does the parity run cover the `sacd_read.ko` MODULE — included,
  excluded, or mis-attributed?**

## 0. TL;DR

1. `fn_diff` compares **4,417 instruction-encoded immediates exactly** (max
   encoded value `0xffc`) and **1,212 pool words as slots only** — a bare
   `.word`, never its value. That partition is correct by construction: at
   `-O0`/armv6z every constant above the rotated-immediate range and every
   address lands in the literal pool.
2. The pool literal contract therefore lives **entirely** in
   `tools/pool_audit.py`: **1,576 load sites** over 384 functions, classified
   into identity classes (string content, function-pointer symbol, section
   boundary, scalar value, bss-zero).
3. Three literal classes were **silently uncompared**, proven by mutants that
   passed BOTH tools before this session: function-pointer targets (58 sites),
   image-range values with no section behind them (153 sites — this is where
   `install_modules`' module-end literal lives), and the embedded
   `sacd_read.ko` blob itself (zero coverage).
4. The **module is not code to either tool** — it is 97,805 B of `.data` that
   `install_modules` writes to `/tmp` and `insmod`s. Module parity therefore
   **IS blob byte identity**, now checked (`module blob: identical …`) and
   byte-identical across all four ELFs in the tree today.
5. The fixes restored **384/384 clean** on the release image and left
   `fn_diff` at its then-documented 388/390 · 385/390 counts — no accepted
   residual moved, no new one appeared. (History: since 2026-11-16 the
   accepted list is three — `_start`, `call_gmon_start`, and the deliberate
   `recursive_mkdir` EPERM divergence; current count 387/390.)

## 1. What the harness compares today (code paths, not prose)

| stage | tool | seam |
|---|---|---|
| instructions | `tools/fn_diff.py:normalize()` | immediates kept verbatim; `.word 0x…` → `.word`; branches → `<in+0xNN>` / symbol |
| pool literals | `tools/pool_audit.py:ELF.describe_word()` + `site_failures()` | one key per load site, compared positionally |
| module | `tools/pool_audit.py:check_module_blob()` | byte identity of `_binary_sacd_read_ko_start` … `_end` |
| gate | `tools/sacd_parity.sh` ← `make sacd-parity` | fails on any non-accepted `fn_diff` mismatch, any pool site fail, any module byte, any mutant that is *not* caught |

The four stages are ordered so the cheap one speaks first; the mutant stage is
the harness's own control (controls before attacks, applied to the harness).

## 2. The literal partition, measured

`llvm-objdump -d` on the original, comment column stripped: 4,417 encoded
`#imm` operands, **maximum `0xffc`** — i.e. nothing above the ARM
rotated-immediate range is ever encoded in an instruction here; 1,212 `.word`
data lines, of which **0 carry a symbol annotation** under this backend.

`pool_audit` over the original (384 functions, 1,576 PC-relative load sites):

| class | sites | identity it carries | compared as |
|---|---|---|---|
| `scalar:<value>` | 496 | source constant | **exact value** |
| `bss-zero` | 460 | zero-initialised global | class only (identity unrecoverable) |
| `ascii:"…"` | 407 | narrow string literal | **exact decoded content** |
| `wide:"…"` | 86 | `L"…"` literal | **exact decoded content** |
| `code:<fn>` | 51 | taken function address | **symbol identity** |
| `symcontent:<bytes>` | 45 | object at/inside a symbol | masked content |
| `empty-string` | 16 | the shared `""` literal | exact content |
| `content:<sec>:<bytes>` | 7 | data window | masked content |
| `code-ptr` | 7 | *not* a function entry | class only |
| `secend:<section>` | 1 | one-past-section-end (`_edata`, module end) | **section identity** |

The original and the release image produce **identical class histograms** —
the classification is layout-blind, which is what makes it usable as a
parity key.

Correct policy, in one line each:

* **Must match exactly**: instruction immediates; decoded string content
  (`L"c"` vs `L"connected"`, `__FILE__` assert paths — the two misreads that
  motivated `pool_audit`); scalar pool values; the *symbol* a code pointer
  addresses; the section a boundary pointer sits at.
* **Must NOT be compared**: any absolute address (pool word value, branch
  target, `.word <sym+0xoff>` annotation offset), pool slot placement
  (`[pc, #imm]` offsets), and the content window of a data object whose
  neighbours move with link order (documented benign `.data`-order class,
  `DELTA.md`).
* **Accepted residuals**: `_start`, `call_gmon_start` (`fn_diff`, startup
  objects from the CS sysroot — `DELTA.md` "parity session 3"); and
  `__libc_csu_init` on the `_fsf` build, whose pool literals are per-build
  csu constants.

## 3. The three blind spots this session proved

All three mutants were applied to the **release image** and run through
`fn_diff` + `pool_audit` as they stood at `HEAD` (`a74c14f`): every one
returned `388/390` + `384/384 clean`, i.e. a full PASS.

| mutant | what it changes at runtime | old verdict | new verdict |
|---|---|---|---|
| **M1** `sacd_input_setup` sites 1↔5 (`sacd_net_input_open` ↔ `sacd_net_input_read`) | a function-pointer swap: every net-backed read becomes an open | PASS (`code-ptr` on both sides) | **FAIL** `sacd_input_setup` |
| **M2** `install_modules` site 0 (`_binary_sacd_read_ko_end` +4) | the size handed to `write()` for the embedded module → truncated `.ko` → `insmod` fails → daemon exits (`install_modules` → `"Can not install modules"`) | PASS (`layout-ptr` class, value ignored) | **FAIL** `install_modules` |
| **M3** flip one byte at blob offset `0x100` | the module the daemon installs is not the module the original shipped | PASS (nobody reads the blob) | **FAIL** `module blob: DIFFERS … offset 0x100` |

M1 is the `sacd_input_setup` "signal" seam `DELTA.md` already names — the
assignment that decides whether the device path uses the 64-bit read. It is
exactly the literal class a symbol-blind content key cannot see: two functions
with different bytes are different objects even when both are "some `.text`
address".

## 4. The fixes (each labelled with the finding that motivates it)

`tools/pool_audit.py`

* **M1 → `describe_word()` step 2 + `func_starts`**: a `code-ptr` word at an
  **exact `FUNC` entry point** becomes `code:<name>`. Entry-point-only is not
  cosmetic: 7 pool words do address `.text` without being function pointers
  (`0xffff`, `0xfffe`, `0xfeff`, `0xd7ff`, `0xdfff` — UTF-16 BOM/char
  constants — and `0xcc7c` in `__libc_csu_init`); a containment rule would
  have invented identities for all of them, and did, before this rule.
* **M2 → `describe_word()` step 3 + `section_ends`**: a word equal to a
  section end becomes `secend:<section>` (`_edata`,
  `_binary_sacd_read_ko_end` — layout-free, mutation-sensitive); a word inside
  the image range with **no section behind it** is not a pointer in that image
  and now compares as `scalar:<value>` instead of the opaque `layout-ptr`
  class.
* **`site_failures()` (extracted, shared with the tests)**: an **equal raw
  value** is still compared — only identity classes may contradict each other
  there (`ascii:`/`wide:`/`empty-string`/`bss-zero`/`code:`/`secend:`); a data
  window, a scalar that coincides with a `.data` address, or a value that is
  inside a section in one layout only are one value seen through two layouts.
  This keeps the documented benign classes passing while closing the
  equal-address-different-object hole.
* **`content_key()`**: `.bss` reads as `bss-zero`, not `empty-string` — a
  global-buffer pointer must never alias the shared `""` literal (476 sites
  used to share one class).
* **M3 → `embedded_module()` + `check_module_blob()`**: byte identity of the
  embedded blob, printed on every run and folded into the exit status;
  `--module` runs it alone.

`tools/fn_diff.py`

* **Policy → `.word` normalization**: `.word 0x… <sym+0xoff>` used to keep the
  annotation *with its offset* — the one layout-dependent literal value
  `fn_diff` compared. Pool words are now normalized to a bare `.word`
  (slot-only); identity is `pool_audit`'s contract. Verdict-neutral on every
  ELF in the tree (`388/390` release, `385/390` `_fsf`, unchanged) and immune
  to a GNU-objdump backend that annotates where llvm does not.
* Docstring states the partition so the next reader does not re-derive it.

`tools/sacd_parity.sh` — header + stage names now say what is covered
(literals, module blob, five mutants).

## 5. The sacd_read module's scope — the answer

**Coverage today: excluded, and correctly so — but until this session,
unchecked.**

* `fn_diff` walks the host ELF's *function symbols*: 390 normalized functions
  (384 with a disassembly `pool_audit` can read). The module contributes
  **zero** functions — it is not linked code, it is 97,805 B of `.data`
  (`_binary_sacd_read_ko_start = 0x3efdc` … `_end = 0x56de9` in the
  original; `0x3ef04` … `0x56d11` in the release image).
* The only way the module touches the tools is by **mis-attribution**: the
  original's `ReadTableSegmentData` straddles the `ABS`
  `_binary_sacd_read_ko_size` symbol, which is why `fn_diff` rewrites
  intra-function branch targets to `<in+0xNN>`; and the blob's end is a
  `secend:.data` pool literal (fix M2). Both are now named classes, not
  accidents.
* **The module's real parity contract is byte identity of the embedded blob**,
  because the daemon ships it: `install_modules` (`0x2f970`) writes it to a
  `tmpnam()` path under `/tmp` and `system("insmod %s minor=201")`s it — the
  daemon exits on failure (`"Can not install modules"`). The c130–c134 era
  confirms the runtime dependency and changes nothing about the coverage
  answer: the guest gates (`daemon-gate-experiments.md` rows 07–09,
  `daemon-install-erofs.md`) prove the *blob on disk* is what gets installed,
  and the C-run module-stack lanes used a staged copy of
  `original/sacd_read.ko` — a different lane from this parity harness.
* **Measured now**: `original/sacd_read.ko` == `reconstruct/sacd_read.ko`
  (SHA-256 `b3d7a383…46dfa`), and the embedded blob extracted from **all four**
  ELFs in the tree (`original/`, `reconstruct/sacd_extract_160`,
  `reconstruct/sacd_extract_160_fsf`, `reconstruct/release/…`) hashes to the
  same `b3d7a383…46dfa`. So the module leg is green — it was simply never
  asserted.
* If the module is ever **recompiled** rather than copied, the operative gate
  changes: `fn_diff.py`/`pool_audit.py` take any ELF pair, so
  `python3 tools/fn_diff.py original/sacd_read.ko rebuilt/sacd_read.ko` is the
  right comparison (the `.ko` is an unstripped relocatable with DWARF) — but
  the release build deliberately does **not** rebuild it
  (`tools/release_build.py` `.incbin`s the tracked blob), so blob identity is
  the complete gate today.

## 6. Residual risks / what remains open

1. **Equal-raw data windows** stay accepted (a scalar constant that coincides
   with a `.data` address, and the documented `.data` object-order class).
   Without app-level DWARF the pool word's *type* is not recoverable; treating
   these as failures would flag 5–6 sites on every layout-divergent build and
   prove nothing.
2. **Mid-function code pointers** (7 sites) keep the class-only `code-ptr`
   key. Taken addresses are entry points; a jump-table entry inside a function
   would still pass a swap.
3. **`bss-zero` identity** is unrecoverable: two zero-initialised globals are
   interchangeable to this audit (their *initialisers* are not compared — they
   are `.bss`, there are none).
4. **The VM release pipeline does not run the literal audit**:
   `tools/release_verify.sh` (issues #3/#4) runs `fn_diff` + interface +
   status + division + eager-binding, but neither `pool_audit` nor the module
   blob. Closing that is one line in `[2/5]`-style form —
   `"$VERIFY_PY" tools/pool_audit.py "$ORIG" "$IMG"` — and is **not** in this
   change (file is owned by the release lane).
5. `pool_audit`'s `OBJDUMP` backend is now env-overridable (`OBJDUMP=…`) like
   `fn_diff`'s, but it still resolves `llvm-readelf` from a fixed path.

Fixed in this pass, recorded so it does not come back: **the documented entry
point did not run in this checkout.** `Makefile:373` pinned
`SACD := experiments/sacd_reconstruct` — the *aftermath* layout, a sync
artifact — so bare `make sacd-parity` exited 127 here. It is now

```make
# Layout: the SACD lane is a subdirectory of the aftermath tree and the
# repo root of this standalone checkout. Keep both working.
SACD      := $(if $(wildcard experiments/sacd_reconstruct),experiments/sacd_reconstruct,.)
```

Bare `make sacd-parity` (PASS, module blob + 5 mutants) and bare
`make sacd-selftest` (PASS) both run in this checkout with that fallback;
`make docs-check` stays green (no `## ` doc line changed).

## 7. Reproduce

```sh
# the whole harness against the release image (Mac, ~5 s)
make sacd-parity

# the policy classes, site by site
python3 tools/pool_audit.py original/sacd_extract_160 \
    reconstruct/release/sacd_extract_160_release --verbose

# module leg alone
python3 tools/pool_audit.py --module original/sacd_extract_160 \
    reconstruct/release/sacd_extract_160_release

# the five mutants (A/B old-audit classes, C/D/E this session's classes)
python3 tools/test_pool_audit_regressions.py original/sacd_extract_160 \
    reconstruct/release/sacd_extract_160_release

# fn_diff literal partition: encoded immediates only, max 0xffc
/opt/homebrew/opt/llvm@22/bin/llvm-objdump -d --no-show-raw-insn \
    original/sacd_extract_160 | sed 's/@.*//' | grep -E "^\s+[0-9a-f]+:" \
    | grep -oE "#0x[0-9a-f]+" | sed 's/#//' \
    | python3 -c "import sys; v=[int(x,16) for x in sys.stdin]; \
        print(len(v), hex(max(v)))"
```
