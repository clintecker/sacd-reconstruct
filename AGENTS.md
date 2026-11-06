# AGENTS.md — operating rules for AI agents working in Aftermath

You are extending an automated security-research system that finds real
vulnerabilities in widely-deployed server software. Read this file first,
then `docs/playbook.md` (the full method) and `docs/prd.md` (the mission).
Everything here exists because it was violated or proven the hard way.

## Binding policies — never violate

1. **NEVER disclose any finding.** No maintainer contact, no publication,
   no CVE requests. Everything stays in this private collection.
   `docs/disclosure.md` governs. Standing state: NOT PUBLISHED.
2. **Wire-level or it didn't happen.** Client-library observations caused
   two misreads (Unicorn, uvicorn). Claims about framing/protocol behavior
   require raw-socket byte evidence. Raw bytes go in the evidence bundle.
3. **Score only demonstrated behavior.** Untested dimensions score N.
   Variants are labeled. All CVSS via the `cvss` Python library — commit
   vector strings, never hand-computed numbers. `docs/scoring.md`.
4. **Composition analysis is Step 0** for every finding: what does this
   compose with, what mediates it, what suppresses it? `docs/chaining.md`,
   `findings/CHAINS.md`. A finding that only fires under direct exposure
   (no front-end) is a *different, weaker finding* — say so in the score.
5. **Chains require decisive experiments**, defined before running:
   candidate → decisive-experiment-defined → proven / ruled-out. CHAIN-1
   and CHAIN-2 both died in a day; negatives stay in the ledger as
   targeting data. Run the experiment immediately when a chain candidate
   is defined.
6. **Honest negatives get the same evidence bundle as findings**: probe
   set + counts + parity + logs. "Clean" is a claim that needs evidence.
7. **Decode bytes with tools, never by squinting at hexdumps.** Wire
   captures, netlink attributes, and binary formats go through the
   deterministic decoders (`tools/harness/netlink_decode.py` is the
   netlink one; registry GENERATED from kernel headers + source via
   `--gen`, never hand-typed). LLM eyeball-reading of byte dumps is a
   last resort for forming a hypothesis, never for claiming a result —
   this session's counter endianness (NLA_BE64) and enum selection bugs
   were each invisible to intuition and obvious to the decoder.
8. **Label inferred vs verified.** Same CVE, different build → different
   impact (CVE-2020-8794: OpenBSD root-RCE vs portable-build daemon-crash
   — score what YOUR rig demonstrated, label the rest inferred).

## Delegation scope (binding for anyone doling out worker tasks)

Workers get STAGES, not lanes. The 30-minute wall is fixed; a child whose
scope cannot fit it WILL time out (this month's evidence: 100% of lanes
did, at least once). The unit of delegation is one artifact class with a
seam artifact as the only handoff:

1. **Stage-1 analyst** (Mac-side): advisory+patch+source read →
   `gt-plan.md` (mechanism, preconditions, exact trigger, expected
   observable, differential plan) + rig recipe. No VM access needed.
2. **Stage-2 rig builder**: consume the recipe → build, controls,
   `rig/manifest.json` + `RIG-READY.txt`. The marker is the handoff.
3. **Stage-3 GT fire**: the PARENT's job, via `make gt-fire RIG=<hunt>`
   (five enforced gates, ~5 minutes) — never burn a child's box on it.
4. **Stage-4 battery**: consumes the validated rig, next session.

Rules: stage briefs carry LESS setup reading (a rig builder doesn't need
the CVE history — it lives in the seam artifact); the seam artifact is
written or the stage isn't done; **two timeouts in the same stage = split
the stage further, never resume a third time**; if you find yourself
briefing one child with four deliverable classes, stop and re-slice.
Full table + rationale: docs/campaign-kit.md "The lane-pipeline doctrine".

## How to work a target (the proven loop)

Read `docs/playbook.md` for the full phases. The core loop:

```
pick target (docs/target-survey.md, by deployment evidence + GT anchors)
→ fastest baseline (distro package; get it SPEAKING the protocol)
→ probe family: ~200 lines of raw-socket protocol lib + controls FIRST
→ hostile sweep on baseline AND ASan build, parity-checked
→ GT archaeology if a known CVE exists (validates the whole rig)
→ results doc + evidence bundle + commit — even (especially) for negatives
```

Rules that keep this loop honest:
- **Controls before attacks, every suite.** A hostile result is meaningless
  until the benign path passes. When a control fails, suspect the RIG
  first (three rig bugs found this way: single-request evil server wedging
  its own keepalive pool; /tmp not shared into Lima; empty stderr capture).
- **Harness noise ≠ target bug.** Misconfigured delivery perms (root
  recipient, unowned maildir, wrong privsep users) produce failures that
  mimic target bugs exactly. Diagnose the rig before claiming the target.
- **Verify your observable end-to-end** (mail actually delivered, file
  actually created) — "server said 250" is not evidence.
- **Era-match archaeology builds**: old base distros that just went EOL
  404 on live mirrors → point sources at immutable
  `archive.debian.org` + `-o Acquire::Check-Valid-Until=false`; pre-2020
  code needs `-fcommon` on GCC 10+; portable tarballs are the p-suffixed
  ones (the plain name may be a source-only tree with no configure);
  companion libs may need separate builds first (libasr for 6.6.x opensmtpd).
- **In binary-protocol compositions, buffer BYTE LAYOUT is attack
  surface.** CVE-2019-11043: identical directives, different fastcgi
  param order = different corruption target = different target. When an
  archaeology exploit won't trigger: (1) verify prerequisites
  independently, (2) look for partial-corruption tells (env names
  leaking as values), (3) sweep the layout knob before concluding
  "invulnerable."
- **The adversarial-responder rig** (`findings/minrepro/smtpd/evil_server.rb`
  is the template): when the bug is in the target's CLIENT code, the probe
  is the server. Hostile upstream replies are a standing angle class
  (LEAD-8), proven Critical-grade by CVE-2020-8794.
- **"A reply arrived" is not "negotiation succeeded"**: daemons that
  greet on accept make rejected frames look accepted. Verify protocol
  success by server log state. (Proven the hard way: ActiveMQ 6.x
  silently rejected every lego handshake while replying.)
- **Wedge/hang claims need timing + EOF classification**: instant-close,
  hold-then-close, and buffered-hold are different behaviors. "Empty
  response" is not a classification.
- **Differentials are cheap and mandatory**: same probe against the
  fixed version (or a front-end) whenever one exists.

## When a technique works, codify it

If a method proves itself (era-source hunting, a probe pattern, a
differential trick), it becomes documented + tooled the same session:
a script under `tools/`, a playbook section, and a pointer in the table
above. Techniques that live only in session history are lost techniques.

## Lab VM network policy (binding)

1. **No outbound internet from the lab VM** beyond the OS-upkeep
   allowlist (Debian security mirrors for apt). Everything else is
   fetched on the Mac and enters the VM via the private channel
   (tar-pipe / rsync over SSH).
2. **No third-party prebuilt images.** GT targets build from source in
   our own Dockerfiles with our own recipes — a prebuilt vulnerable
   image is a supply-chain root on an untrusted box plus a metadata
   trail (a Docker pull names our research direction to third parties).
3. **Exposure log:** any accidental outbound contact gets recorded in
   `docs/vm-session-notes.md` — hosts touched, purpose, date.

## Environment facts (macOS arm64, Docker via Lima)

- Every bash call starts at repo root — `cd` explicitly before relative paths.
- Docker is Lima-backed: **only `$HOME` is volume-shared**. Never mount
  from `/tmp` (silently empty in the VM). Mount from the repo.
- `.dockerignore` excludes `findings/` — a fixture under findings/ needs
  an explicit `!findings/minrepro/<dir>/` whitelist line.
- Capture container logs as stdout+stderr (DockerTarget `logs()` does).
  Historically stderr was dropped and all evidence files were empty.
- ASan containers need `--security-opt seccomp=unconfined` (shadow-memory
  syscalls violate default profiles) and typically
  `ASAN_OPTIONS=detect_leaks=0:abort_on_error=1`.
- Privilege-separated daemons: check `./configure --help` for EVERY
  user/group/path flag (opensmtpd needed user-smtpd, user-queue, AND
  group-queue — the missing group fails at runtime, not configure time).
  Hard-coded dir semantics: opensmtpd spool must be root:root mode 711.
- uWSGI ini must use `printf "..."` with double quotes (env expansion).
- Probe servers that advertise keepalive must LOOP per connection.
- `go install github.com/neex/phuip-fpizdam@latest` works for the
  CVE-2019-11043 GT (tool needs URL ending in .php).

## Where everything lives

| Thing | Place |
|---|---|
| Findings + scoring | `findings/FINDING-*.md`, `docs/scoring.md` |
| Chain ledger | `findings/CHAINS.md` |
| Evidence bundles | `findings/minrepro/<target>/` (each self-contained: rigs, probes, results docs) |
| **Operational targets (Makefile — GENERATED BLOCK BELOW)** | `make help` at repo root. The Makefile is the SINGLE SOURCE for target docs; the table below is generated from its `## ` doc lines via `make docs-sync`, and `make docs-check` (wired into `commit-unit` + the pre-commit hook) fails any commit that ships a new target without its AGENTS.md documentation. **Prefer these targets over adhoc commands** — they carry the flags, gates, and evidence-discipline that adhoc invocations keep forgetting. New repetitive patterns become targets the session they're noticed, then `make docs-sync` — never hand-edit the block. |**

<!-- BEGIN MAKE-TARGETS (generated by: make docs-sync — do not hand-edit) -->
| Target | Usage | What it does (learned-correct form) |
|---|---|---|
| `help` | `(no arguments)` | list every documented target, grouped by category |
| `agents-doc` | `(no arguments)` | print the AGENTS.md targets block (generated form) |
| `docs-sync` | `(no arguments)` | write the generated targets block into AGENTS.md (single source: this Makefile) |
| `docs-check` | `(no arguments)` | drift gate: FAIL if AGENTS.md block differs from the Makefile doc lines |
| `vm-exec` | `CMD='...'` | run a command on the lab VM — batch-mode keyed ssh (the prefix adhoc lines keep dropping) |
| `vm-stage-dir` | `DIR=path [BASE=.]` | tar-pipe a directory to the VM — the private channel — COPYFILE_DISABLE set, no outbound from the VM, lands under ~/ |
| `vm-script` | `SCRIPT=path` | stage a local script file and run it on the VM — kills the quoting-hell class — any VM operation more complex than a single flat command lives in a script file, never in a vm-exec CMD= one-liner (nested quotes broke vm-exec three times in one debug session) |
| `vm-stage-file` | `FILE=path` | scp one file to VM:/tmp/ — keyed scp for probes/batteries |
| `vm-pull-file` | `FILE=vm-path DEST=local-dir` | pull a file back from the VM — the evidence-return leg of the private channel |
| `vm-ports` | `(no arguments)` | docker ps state + port map of all rigs — run before every fire |
| `vm-recorder` | `PORT=nnnn` | verify the wire recorder is listening — fails loudly if absent — re-run the rig vm_up.sh before firing through it |
| `probe-fire` | `SCRIPT= PORT= MODE= EVIDENCE=path` | timeout-wrapped probe fire, teed to evidence — EVIDENCE is mandatory — conversation output is not an evidence bundle |
| `battery-selftest` | `DIR=path [VM_DIR=/tmp]` | run a battery selftest — the verdict gate — a non-PASS selftest blocks any live fire (controls apply to the harness too) |
| `battery-live` | `DIR=path PORT=n [HUNT5_ONLY=...] [OUT=]` | live battery fire — standard hold/idle/probe-cap envs; canary cadence is the battery's job |
| `controls-run` | `SCRIPT=vm-path` | run a rig's controls — controls before attacks, every suite; a failed control means suspect the RIG first |
| `evidence-logs` | `CONTAINER=c OUT=path` | pull a container's full logs to an evidence file — stdout+stderr (the old dropped-stderr lesson) |
| `asan-baseline` | `CONTAINER=c [LOGDIR=...]` | count/uniq ASan reports BEFORE firing — the noise-baseline rule — a probe is ASan-positive only for signatures NOT in this baseline |
| `asan-report-newest` | `CONTAINER=c SIGNATURE=s OUT=path` | extract the newest report matching a signature — no-match is an honest negative (evidenced absence), not a failure |
| `rig-asan-up` | `NAME=n IMAGE=i HPORT=h [CPORT=] [NOISE=1]` | start an ASan container — seccomp=unconfined + detect_leaks=0; abort_on_error=1 default, NOISE=1 switches halt_on_error=0 for known-noise rigs |
| `asan-build-gate` | `LOG=path BIN=path` | the two sanitizer build gates — fsanitize in the build log AND __asan_init in the linked binary (the silent-drop lesson) |
| `rig-restart-recontrol` | `NAME=c SCRIPT=vm-path` | restart a wedged rig, then re-run controls — the wedge-incident protocol — restart, re-control, only then continue |
| `sacd-decode` | `ERRNO=...` | deterministic errno decode (decimal/hex/two's-complement log residue like fffffff3) — never by mental arithmetic (the fffffff3 incident: errno eyeballed in prose mid-debug); name+meaning from the host errno module, the canonical source; bare hex residues (printf %x of a negative int) accepted; selftest: make sacd-decode ERRNO=-- --selftest —  |
| `sacd-py` | `SCRIPT=path` | run a local python script with CWD pinned to the repo root — THE CWD-reset fix for edit scripts — every bash call in this session starts at the session root (the MAIN security repo), and heredoc edits with relative paths kept failing or worse; write the script to /tmp (absolute path), reference repo files by repo-relative paths, and run it through this target so make -C guarantees the working directory |
| `sacd-commit` | `MSGFILE=path [PATHS=...]` | commit and push THIS repo through the identity gates — asserts the git top-level is the canonical SACD checkout AND origin is git@github.com:clintecker/aftermath.git before anything is staged — the a490e51 incident (a sacd sync commit landed in the main security repo from a reset CWD) is structurally impossible when commits only ever happen through this target; refuses on unclean prerequisites loudly |
| `sacd-sync-standalone` | `[MSG=...]` | mirror the canonical tree into the standalone review repo (tests there, commit, push) — the dual-repo discipline as one command — stages tools + gate/hdhost evidence + docs + kit + Makefile/AGENTS into clintecker/sacd-reconstruct, verifies ITS origin remote and top-level, runs the 11 alteration controls in that tree, and commits with the canonical hash; refuses if either repo has the wrong identity or the canonical tree is dirty |
| `sacd-stage` | `(no arguments)` | (no arguments) — stage every tracked guest-tool source to the VM in one shot |
| `sacd-kit-stage` | `(no arguments)` | (no arguments) — stage the tracked emulator-kit sources to the VM |
| `sacd-hdhost-qemu` | `(no arguments)` | (no arguments) — rebuild QEMU on the VM from the tracked kit state |
| `sacd-hdhost-mod` | `(no arguments)` | (no arguments) — build the HDHOST guest block-driver module through the proven pipeline |
| `sacd-hdhost-smoke` | `(no arguments)` | (no arguments) — HDHOST end-to-end smoke: sentinel image, guest boot with device checks, host-vs-guest md5 verdict |
| `sacd-gate4` | `(no arguments)` | (no arguments) — the 5 GiB boundary-sentinel battery — the team's final large-image validation |
| `sacd-gate3` | `(no arguments)` | (no arguments) — HDHOST intermediate gate: the canonical 6-boot validation with the disc served through the host-image interface |
| `sacd-gate` | `(no arguments)` | (no arguments) — the canonical 6-boot gate from tracked sources, end to end |
| `tests` | `(no arguments)` | the verbatim finished-unit test gate — uv run pytest -m "not smoke"; un-piped, exit-code-checked |
| `commit-unit` | `MSGFILE=path [PATHS=...]` | the full finished-unit gate chain — docs-check, then tests (exit-checked), then private-remote check, commit -F, push — the pipe-masking incident structurally prevented |
| `cvss` | `VECTOR='CVSS:4.0/...'` | score a CVSS 4.0 vector via the cvss library — mandatory metrics enforced (SC/SI/SA required, no S: scope metric — cost the writer three attempts) |
| `child-triage` | `ID=run-id` | the subagent hang-triage procedure — log-growth + process checks BEFORE any interrupt — elapsed tool time is a prompt to look, not a verdict (the 1-for-3 lesson) |
| `hunt-new` | `TARGET=name` | scaffold a new campaign — wraps tools/harness/new_hunt.py (hunt dir + battery skeleton + results template) |
| `gt-fire` | `[RIG=hunt] [FILTER='...'] [WHICH=asan] OR CONTAINER=c PORT=n` | the GT/probe decisive-fire pipeline — ordered sequence ENFORCED: ASan baseline -> canary control -> filtered fire -> report pull -> post-fire canary; RIG= reads rig/manifest.json (no retyping); stops at the first failed gate |
| `source-fetch` | `URL=... [SIGURL=...] DEST=dir [STAGE=1]` | fetch+verify+record an era source tarball ON THE MAC — network-policy in tooling: public fetches happen Mac-side only; records sha256+URL+date into DEST/PROVENANCE.md; STAGE=1 also scp's it to VM:/tmp/ |
| `evidence-pull` | `FILES='vm-path...' DEST=local-dir` | batch-pull evidence files from the VM — the standard post-fire ritual: JSONLs, ASan reports, logs - named once, pulled together |
| `sacd-sync` | `(no arguments)` | stage the sacd-verify tree + build sources to the lab VM — tar-pipe private channel — repo members go to ~/sacd-verify; reconstruct SOURCES stream directly into the VM build tree ~/reconstruct (never extract a directory member through the ~/sacd-verify/reconstruct symlink — GNU tar replaces the symlink with a real dir and orphans the build tree, which cost the release ELF once); release/ and build/ stay VM-owned |
| `sacd-verify` | `(no arguments)` | clean-checkout release build + every check, on the VM — make verify in reconstruct/ — builds from tracked sources, prints candidate SHA-256, runs fn_diff/interface/status/division/pool checks against that exact file; reproducible bit-identical across runs |
| `sacd-rig` | `[DISC=~/sacd-verify/firebird.iso] [OUT=<stamp>]` | QEMU protocol rig: original vs release candidate over the same disc fixture — replays DISC_OPEN→SIZE→READ×3→CLOSE→reconnect→repeat against both daemons under sacd_rig.so, compares transcripts (result codes, payload hashes), pulls manifests as evidence — pkill-stale hygiene included because a wedged daemon holds port 2002 |
| `sacd-parity` | `[ELF=$(SACD_CAND)]` | Mac-side parity harness against one ELF — fn_diff (390 normalized functions; only the accepted _start + call_gmon_start residuals may remain) + pool_audit (literal content, load-site positional) + both literal regression tests — the tool chain that caught the L"c" and __FILE__ misreads |
| `sacd-selftest` | `(no arguments)` | validate the TCP client against an in-process fake server — stdlib-only check of the wire protocol before any real capture — the same client runs on Mac (BX510 baseline) and Linux (VM rig) |
| `sacd-emu-build` | `(no arguments)` | build the full-system sony-bx510 QEMU on the lab VM — the pinned 9.2.4 tarball is pre-staged (SHA f3cc1c4e… verified at stage time) so build.sh performs no outbound fetch; JOBS=6 |
| `sacd-emu-smoke` | `(no arguments)` | full-system guest smoke tests — the emulator team's pinned PASS set — shell (Sony PID 1, kernel 2.6.35, bdpdrv.ko digest), handoff, fastboot, control-ramdisk |
| `sacd-emu-daemons` | `(no arguments)` | run both daemon ELFs inside Sony's real guest OS — the loader/libc compatibility proof — the original and the release candidate must produce identical --help bytes under Sony's shipped libraries with eager binding |
| `sacd-hw-payload-check` | `(no arguments)` | the stick gate — verifies EVERY payload SHA against the repo, asserts the AutoScript shape (<=9 lines / <=460 bytes), shell-syntax checks the wrappers, and fails loudly (staging calls it automatically) |
| `sacd-hud-anim` | `(no arguments)` | render the HUD as an animated GIF + MP4 — runs the host simulator for 40 frames (0.2 s apart) and assembles both; the panel animates the same way |
| `sacd-hud-build` | `(no arguments)` | build the HUD for the player (VM, era toolchain) and pull it into display-payload — one place for the flags (-std=gnu99, -Wno-pragmas, dynamic) that each cost a failed run |
| `sacd-hud-sim` | `(no arguments)` | render the HUD scene on the Mac (no DirectFB, no device) — real Sony font + fake telemetry -> PNG, for layout/text iteration in seconds |
| `sacd-usb-calib` | `(no arguments)` | arm the CALIBRATION pattern on the stick — sets AutoScript/hudcalib then display mode, so the next player run photographs a known pattern (grid/bars/edges) instead of the HUD |
| `sacd-hud-diff` | `(no arguments)` | does the rig predict the panel? — SSIM + luminance + best global shift between a device photo and a render; exits non-zero below MIN_SSIM (default 0.55) |
| `sacd-hud-guest` | `(no arguments)` | run the HUD in the real Sony guest and GATE it — asserts rc=0 and a non-black framebuffer (a black screenshot fails instead of being eyeballed); currently red because fbvirt's FBIO_DISPATCHHW is a no-op |
| `sacd-usb-prune` | `(no arguments)` | tidy the session stick back to payload-only — drops the player's own hwmon snapshots/backups, recovered logs and inventory reports (collect them first); reports the KiB freed |
| `sacd-hw-preflight` | `(no arguments)` | Mac preflight for the on-player session — ISO present + both pinned ELF SHAs + client selftest + next-steps checklist |
| `sacd-usb-build` | `(no arguments)` | DESTRUCTIVE: build the baseline USB from blank — usage: make sacd-usb-build DISK=/dev/diskN CONFIRM=ERASE — FAT32 erase + original daemon + observer kit + baseline AutoScript; refuses without CONFIRM=ERASE |
| `sacd-usb-check` | `(no arguments)` | verify the USB stick — daemon SHA vs both pinned ELFs, AutoScript mode, observer kit presence, stale pair file note |
| `sacd-usb-baseline-mode` | `(no arguments)` | set the AutoScript to the normal daemon line — the stock baseline launcher |
| `sacd-usb-pair-mode` | `(no arguments)` | set the AutoScript to the instrumented trace-launch line — LSN=600 by default; removes a stale firebird.pair (trace-launch refuses to overwrite) |
| `sacd-usb-debug-mode` | `(no arguments)` | set the AutoScript to the daemon-debug launcher — runs the stick's daemon with output captured + exit status + dmesg (candlaunch.sh) — for naming a fast on-player death |
| `sacd-usb-display-mode` | `(no arguments)` | set the AutoScript to the display leg — cyberdraw --anim on /dev/fb0 through displaylaunch.sh (DISPLAY_ANIM=45 default) — the TV photo/video test; the log names the cause when the screen stays black |
| `sacd-usb-original` | `(no arguments)` | put the ORIGINAL ELF on the stick — SHA-verified 0fdcefdb… — the baseline daemon |
| `sacd-usb-candidate` | `(no arguments)` | put the RELEASE CANDIDATE ELF on the stick — SHA-verified e91720fb… — for the #6 candidate trial after the baseline lands |
| `sacd-hw-wait` | `(no arguments)` | block until the player's daemon listens — HW_HOST=10.20.1.236 HW_PORT=2002 — run after powering the player on |
| `sacd-hw-baseline` | `(no arguments)` | run the on-player baseline capture — waits for the listener, captures with full metadata, tees the console into SESSION_DIR |
| `sacd-hw-baseline-retry` | `(no arguments)` | retry the baseline capture (fresh out dir + label) — for the zero-byte-DISC_OPEN case — wait ~90s first (no-SO_REUSEADDR TIME_WAIT) |
| `sacd-hw-pair` | `(no arguments)` | run the ground-truth pair capture — request-pair through the real module at PAIR_LSN=600; console teed into SESSION_DIR |
| `sacd-hw-analyze` | `(no arguments)` | validate pair + baseline against the ISO — media_check.py pair/baseline with the Firebird rip cross-check |
| `sacd-hw-collect` | `(no arguments)` | assemble + verify the handoff folder — copies pair/baselines/consoles into SESSION_DIR (~/bx510-session), writes a notes template, inventories + SHA-verifies everything |
Regenerate with `make docs-sync` after adding any target (the pre-commit hook enforces it).
<!-- END MAKE-TARGETS -->
| The method (full) | `docs/playbook.md` |
| Target queue + waves | `docs/target-survey.md` (waves 1-5: HTTP tier, protocol daemons, AI infra, OS tier, legacy web) |
| Leads (LEAD-1..9) | `controller/recon.py` (sourcemine) + `docs/technique-ledger.md` |
| Technique watch | `aftermath techwatch` (cve.now criticals → territory buckets) |
| Coverage + yield | `aftermath coverage` (gap worklist + per-angle yield table) |
| Adapters | `controller/adapters/__init__.py` |
| ASan recipes | `docker/*-asan.Dockerfile` (ruby, puma, unicorn, mosquitto, opensmtpd x2) |
| Adversarial-responder template | `findings/minrepro/smtpd/evil_server.rb` |
| Firmware HTTPD lane (GT + first finding) | `findings/minrepro/goahead/` (battery, bisect, matrix, era sources + Dockerfiles) |
| **Lab kit (wire-recorded, manifest-audited)** | `docs/labkit.md`, `aftermath lab <name>`, protocol legos in `tools/protocols/` |
| Kernel tier | `tools/harness/kernel-rig/` (build/boot/observe scripts), `docs/kernel-hypotheses.md`, `findings/minrepro/kernel_rig/` |
| Lab VM ops | `docs/vm-spec.md`, `docs/vm-session-notes.md` (issues for the server-admin bot) |
| Period review | `docs/post-mortem-2026-10-27.md` (accomplishments/kill ledgers, compute rules) |
| Harness vs state of the art | `docs/harness-assessment.md` (gap map: reachability is the next moat) |
| Era-source archaeology | `tools/harness/erasrc_hunt.py` (the ladder; playbook has the method) |
| **The campaign kit** | `docs/campaign-kit.md` (method + proven techniques + tool backlog), `tools/harness/new_hunt.py` (scaffolder), `tools/protocols/battery_lib.rb` (shared battery harness) |
| Env-mapping matrix | `findings/minrepro/cgi_envmap/ENVMAP.md` |
| Lessons from other ecosystems | `docs/lessons-*.md` |

## Compute placement rule

If a job runs >2 minutes, it belongs on the lab VM (native x86), not the
Mac (emulated amd64 is ~10-30x slower). Era builds, kernel builds, ASan
image builds, long sweeps: VM. Adapter development, quick parity checks,
session workflow: Mac. Snapshot the VM before every sweep; classify every
run with the observable scripts, never by manual grep.

## Expectation freshness (attack-decay rule)

Every expected-outcome override records the target version it was
calibrated against (`docs/scoring.md` rule 5b). When a target ships a new
release, re-derive expectations — a fixed bug turns a calibrated
expectation into silent noise or a stale-PASS assumption.

## Definition of a finished unit of work

1. Evidence exists as files (rigs, probes, raw results) — not just
   conversation output. Conversation output is not an evidence bundle.
2. A results doc states what was demonstrated, what is inferred, and
   what is queued — with honest negative results included.
3. `uv run pytest -m "not smoke"` passes.
4. One commit tells the whole story in its message.
5. The next agent could pick up the queue item from the docs alone.
6. Push to origin at the end of every session (verify the remote is the
   private one first) — the canonical backup must not lag local work.
