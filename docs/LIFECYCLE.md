# The build/test lifecycle — from idea to the USB stick

This is the workflow document for every agent working in this repo. It maps
the path every change takes from an idea to real hardware, names the gate
that guards each step, and states the rule each gate enforces. The gates
are `make` targets; the discipline is that **a change may not skip a
stage** — each stage's evidence is what makes the next stage's verdict
trustworthy.

The one-sentence version:

> **Prove it on the Mac in unit tests, prove it in the emulator at wire
> level, and only then spend a hardware session — never the reverse.**

---

## The ladder (six rungs, cheapest first)

```
R0  idea/design        docs + spec; the design contract IS the test oracle
R1  unit tests         uv run pytest -m "not smoke"   (Mac, seconds)
R2  Mac SIM renders    make ui-regress                (Mac, seconds)
R3  emulator fires     make bx510-fire / bx510-ui-loop (VM, ~90 s to minutes)
R4  guest gates        the daemon gates + verdicts     (VM, minutes)
R5  hardware stick     make sacd-usb-* / sacd-hw-*     (real player, expensive)
```

Cost rises ~1000× per rung. That is the whole point: **every bug found at
rung N costs 1000× less than the same bug at rung N+1.** The ladder only
works if the lower rungs are *actually* enforced — hence the gates below.

---

## R0 — idea / design: the spec is the oracle

Before code, the design gets a machine-readable contract that later stages
can check against. Anything a human would otherwise eyeball gets written
down as data:

| artifact | what it pins | consumed by |
|---|---|---|
| `tools/ui_layout_spec.json` | regions, palette, rules, motion regions, ink floors | `ui_regress.py` (R2), anim/parity checks (R3) |
| `decode/*.md` docs | wire protocols, register maps, field layouts (VERIFIED/INFERRED-labelled) | every implementer + reviewer |
| `reconstruct/libsacd/sacd_ripper.proto` | the port-2002 message schema | the daemon, the client, the fakes |

**Rules:**
- A decode claim is either VERIFIED (from an instruction, literal pool word,
  or symbol table, with the address cited) or INFERRED (labelled as such).
  Never unlabeled. `docs/ARCHITECTURE.md` and the decode notes show the form.
- **Decode bytes with tools, never by squinting.** `tools/decode_errno.py`,
  `kernel_decode_kallsyms.py`, and the varint mistake caught twice this
  session (`90fa40`, not the guessed `b0fb04`) are the standing proof.
- Design constants live in ONE place. If two files need the same region
  rectangle or the same CDB, one imports/reads it from the other — the
  spec is the single source (the `ui_motion_regions` fork was rejected for
  exactly this reason).

## R1 — unit tests: everything that can be tested without the VM

```sh
uv run pytest -m "not smoke"     # 77 tests, must be green to commit
```

What belongs here (the current suite demonstrates each class):

- **Pure-function checks**: protocol encode/decode (`sacd-selftest`'s fake
  server, varint round-trips), rate-window math, event-transition tables
  (`tools/test_sacd_ui_events.py`), parsers against fixture bytes.
- **Alteration controls — the important ones.** A PASS is only meaningful if
  the tooling *detects a deliberately corrupted input* (`tools/test_bx510_gate.py`:
  applying alterations to both transcripts must FAIL; if it passes, the
  comparator is broken, not the target). Every checker gets at least one
  positive control (corrupt → fails) and one negative control (clean → passes).
- **Fixture-driven renderer checks** (`tools/test_ui_regress.py`): synthetic
  PPMs exercise each invariant — a shifted panel fails with the named region,
  a rogue color fails, blink-period detection works on synthetic series.
- **Harness self-tests with no hardware**: the ui-loop's 13 controls run the
  whole build→capture→verdict chain against a file-backed fake framebuffer.

**Rules:**
- New logic lands with its tests in the same commit; `commit-unit` runs the
  suite and refuses otherwise.
- Tests are deterministic: same inputs → same verdict, no sleeps, no
  network, no wall-clock (SIM mode pins the event clock at 0 for this reason).
- The `smoke` marker is reserved for tests that need QEMU or the VM.

## R2 — Mac-side rendering/design regression: golden discipline

For anything with pixels or layout (currently the UI):

```sh
make ui-regress          # scenes -> goldens -> invariants (seconds)
make ui-golden GOLDEN=accept   # ONLY after a deliberate, reviewed design change
```

The accepted frames are viewable in `evidence/bx510-guest/graphics/gallery/`
(indexed by `docs/GRAPHICS-GALLERY.md`), which also carries the guest-side
captures for R3.

- **Goldens change only via explicit accept.** A passing run rewrites
  nothing (mtime-verified). An intentional redesign is one loud command
  that stamps the manifest with the renderer sha, spec sha, and date.
- **The checker validates against the spec, never hand-mirrored constants.**
  The renderer's own `SACD_UI_SPEC_DUMP` records rects/colors at the
  drawing primitives — if the C and the spec drift, the regression names
  the region.
- **Animation is a diff class, not a snapshot**: frame-to-frame changes must
  confine themselves to `motion_regions` (lamp/cursor/status-line). Anything
  else moving is a bug — this is how a stuck widget or a repaint storm gets
  caught without watching a video.
- **Guest parity closes the loop** (see R4): the emulated frame is compared
  to the SIM golden per-region; correlation ≥ threshold or the run fails.

## R3 — emulator fires: the wire-level proving ground

Everything else — protocol behavior, daemon interaction, module loads,
framebuffer output — is proven in the emulated BX510 (Sony's real kernel
and rootfs under our QEMU model) before hardware.

> **State (2026-11-16): R3 Level 0 complete and green (c130–c134); Level 1
> (the synthetic cipher) proven at wire level (c135–c138); the client rip
> works end to end (c139). Hardware rung R5: the 2026-11-05 session PASSED
> candidate acceptance + standby; the next hardware visit is a baseline
> confirmation only.**
> The full port-2002 story is proven at wire level against the real Firebird
> disc: DISC_OPEN -> DISC_SIZE -> Master TOC -> both area TOCs -> 2-channel
> music sectors through the decrypt-active branch (byte-exact vs ISO oracles,
> 13-chunk rip included) -> DISC_CLOSE -> reconnect -> repeat -> failure case
> (past-EOF = result 0) -> overlapping clients (2nd client REFUSED at OPEN;
> 1st wedges — the F-1 verdict, amended from the accept-aliasing prediction).
> The UI watches all of it live. One model bug was caught and fixed on the
> way (FE_DMA_MAX stale-bytes, run-c130-c134.md). Remaining to Level 1: the
> synthetic cipher (#10); to hardware: #6 parity, gated on #12/#2 literal
> scope.

```sh
# one experiment = one command (stages, fires, greps verdicts, pulls evidence)
make bx510-fire RUNID=cNNN GCMD_FILE=/tmp/g-cNNN.txt [TIMEOUT=240]

# the UI loop: build -> stage -> fire -> capture -> PNG/GIF + luminance verdict
make bx510-ui-loop RUNID=ui-N
```

**The mandatory checklists (each exists because it was once skipped and cost
a fire):**

1. **FA-latch clear in EVERY custom fire**: `sr_fa_mode /dev/sr0 clear` after
   `insmod sr_mod.ko`, BEFORE anything opens `/dev/sr0`. The `sdev->changed`
   latch has killed three separate runs (C113 EIO loop, C112b gate-13,
   c122f zero-FE-traffic). `daemon_gate.sh` GATE 12b enforces it in the
   daemon scenario; custom `--guest-cmd` fires must carry it themselves.
2. **Controls before attacks, every suite** (inherited from the house
   playbook): the benign path runs first; a hostile result is meaningless
   until the control passes; when a control fails, suspect the RIG first.
3. **Census before hypothesis**: when a read "produces nothing", count the
   CDBs in the mmio trace BEFORE theorizing about dispatchers. c122f had
   zero READ CDBs — the FE model was never broken.
4. **Verify the observable end-to-end**: "the daemon answered 250" is not
   evidence; the client's `md5sum` matching the fixture oracle is.
5. **The verdict is a marker in the transcript** (`CLIENT_PASS`,
   `READ10_VERDICT=PASS`, `UI_PASS`, `DAEMON_ORACLE=0`) — greppable,
   committed as evidence, never a prose claim.
6. **Trace hygiene**: rotate VM `/tmp` traces in every fire script; pull
   uart+meta home; big mmio logs stay VM-side and get grepped remotely.
7. **Budget gates refuse oversize staging** (the fe_test_data partition is
   1,048,576 B — the tgz budget check runs in the fire harness, not by hope).
8. **The guest flood will eat prompt-based synchronization** — fire scripts
   use marker-based verdicts, and a custom fire that must observe the guest
   captures what it needs INSIDE the guest command (the `cat /res/daemon.out`
   pattern), never via post-hoc shell interaction.

## R4 — guest gates: the daemon's own acceptance ladder

The daemon scenario has a 14-gate startup ladder (`decode/daemon_gate.sh`)
that must ALL pass before the daemon is declared healthy, plus the session
verdicts:

| gate | proves |
|---|---|
| 01–03 | procfs mounted, /tmp writable (md5-oracle), shell deps present |
| 04–09 | bdpdrv resident, symbols resolvable, sr0 + sacd_read nodes open |
| 10–12 | TUR clean, profile 0x10 accepted, CPSA INIT 0x68000000 |
| 12b | the FA latch is CLEAR before any sr0 read (the c122f lesson) |
| 13 | Master TOC 20480 B, SACDMTOC magic + whole-range md5 oracle |
| 14 | AUTH accepted |

Then the **client-leg session** (`sacdclient`): DISC_OPEN → DISC_SIZE →
DISC_READ (md5 45ccd7df… byte-exact vs the fixture) → DISC_CLOSE, and the
**reactive-UI fire**: listener up, client connect/gone with monotone event
seq, RIP progress, `UI_PASS`.

**Rules:**
- A gate that cannot fail is not a gate: every gate has a want-value
  discriminator (the `want 0` rows for FA-mode constants, the md5 oracles)
  and the alteration controls prove the harness detects corruption.
- **Parity/differential everywhere**: the original daemon and the
  reconstruction get the SAME transcript comparison (`evidence/bx510-guest/gates*/`,
  `docs/REPRODUCE.md` §3); `fn_diff` + `pool_audit` remain the binary-level
  referee with their own alteration controls.
- Version-drift rule: an expectation calibrated against firmware X is
  re-derived when X changes — never silently inherited.

## R5 — hardware: the USB stick, spent last

A hardware session is a *confirmation* of an already-proven stack, never an
experiment. The prep is entirely Mac-side and mechanical:

```sh
make sacd-hw-preflight     # ISO present + pinned ELF SHAs + client selftest + checklist
make sacd-usb-build DISK=/dev/diskN CONFIRM=ERASE   # DESTRUCTIVE, guarded
make sacd-usb-check        # daemon SHA vs both pinned ELFs, AutoScript shape
make sacd-hw-wait          # block until the player's daemon listens
make sacd-hw-baseline      # capture with full metadata, console teed
make sacd-hw-collect       # assemble + SHA-verify the handoff folder
```

**Rules:**
- Every payload SHA is verified against the repo (`sacd-hw-payload-check`
  runs automatically at staging; the AutoScript shape is asserted ≤9 lines
  ≤460 bytes because the player truncates longer MTK scripts).
- A hardware run mirrors a known emulator scenario (same client sequence,
  same verdicts) so the comparison is apples-to-apples; the rig carries the
  wire recorder for byte-level parity.
- Player quirks are codified, not rediscovered: the MTK CLI script format,
  the CPSA compid preload, the no-SO_REUSEADDR TIME_WAIT (wait ~90 s before
  a retry), the session-stick pruning (`sacd-usb-prune`) after collecting.

---

## The commit discipline (what makes the ladder auditable)

`make commit-unit MSGFILE=… [PATHS=…]` is the ONLY way a unit lands:

1. `docs-check` — the AGENTS.md targets block is generated from the Makefile;
   a new target without documentation refuses to commit.
2. `pytest -m "not smoke"` — R1 green, exit-code-checked (pipes mask
   failures; the gate unpipes).
3. private-remote check (repo-aware: `clintecker/sacd-reconstruct` here,
   `clintecker/aftermath` elsewhere).
4. One commit tells the whole story in its message: what was demonstrated,
   what is inferred, what is queued — honest negatives included.
5. Push to origin at the end of every session.

Evidence rules (binding):
- Conversation output is not an evidence bundle. Runs land as files:
  uart logs, meta json, fire transcripts, verdict markers, PNG/PNG frames.
- Every run doc states what was demonstrated, what is inferred, what is
  queued — negatives included, labelled.
- The next agent must be able to pick up the work from the docs alone.

---

## Delegation (how agents divide this ladder)

- **Workers get STAGES, not lanes** — one artifact class, one seam artifact
  as the only handoff. Two timeouts in the same stage = split the stage,
  never resume a third time.
- **File ownership is exclusive**: when two workers would touch one file,
  pin a substrate (`git show <commit>:<file>`) for one lane and hand the
  other a standalone patch (the regress/event conflict resolution of
  2026-11-15 is the template; the spec file is the shared contract, never
  forked).
- **The parent fires** the expensive stages (R3+); a child does not burn
  the shared VM.
- Every worker brief includes the pi-intercom standing rule and the
  VERIFIED/INFERRED labeling duty.
- Codify what proves itself the same session: a make target, a playbook
  line, a pointer from this table. A technique that lives only in session
  history is a lost technique.

## The trap catalogue (each cost at least one fire)

| trap | rule that prevents it |
|---|---|
| FA/be-quiet latch re-arms on every open | checklist 3.1 + GATE 12b |
| busybox `dd` prints three lines | md5-oracle checks, never parse dd output |
| guest rootfs lacks wc/od/tr/cut/tail | POSIX-only or dd-builtins in guest scripts |
| the daemon tgz carries its own gate script | rebuild the tgz after any gate edit |
| `set -u` + unset variable kills the gate | pre-initialise every variable |
| varint guessed by mental arithmetic | tools/decode_* + fixture oracles |
| `/proc/<pid>/io` does not exist on Sony | wire-level sources only; census first |
| static-once log gates hide second events | log EVERY occurrence |
| SIM golden drifts via wall-clock timestamps | pinned event clock; reproducibility gates |
| prompt-expect sync dies under console flood | marker-based pumping; in-guest capture |
| stale guest-cmd file across RUNIDs | RUNID-scoped staging in the fire harness |
| two clients vs the daemon's one accept slot | serialize client sessions; marker file |
| a "0 B" that means the COUNTER broke, not the read | md5 oracles prove length AND content |
