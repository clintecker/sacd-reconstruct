# In-guest validation gates — results (positive + negative controls)

Date: 2026-11-03
Machine: full-system QEMU (sony-bx510), Sony kernel 2.6.35 + real SquashFS,
real `sacd_read.ko` loaded by each daemon via its own insmod, bdpvirt
virtual ODD, corrected synthetic Firebird fixture (86,200 sectors).

Reference binaries (pinned, SHA-stamped in the run manifests):
- original: `~/sacd-verify/original/sacd_extract_160`
- release:  `~/reconstruct/release/sacd_extract_160_release`

## Gate design (addresses reviewer finding #2)

Order is enforced: **per-transcript positive gates pass for BOTH binaries
before any transcript equality is considered.**

Positive gates (per binary, computed expectations — not transcript echoes):
- OPEN result==0, SIZE==86200
- single reads (lsn=0, lsn=43100): result==1, datalen==2048, FNV-1a64 ==
  hash of the independently computed synthetic sector
- 128-sector read: result==128, datalen==262144, hash == join of
  synthetic_sector(0..127)
- boundary read (lsn=79990 cnt=20): result==10 (clamped at the encrypted
  range), datalen==20480, hash == 10 synthetic sectors
- encrypted-range read (lsn=80000 cnt=2): result==2, datalen==4096, hash ==
  mock-plaintext (verbatim copy, labeled)
- beyond-EOF (lsn=86300): result==0 (expected-error scenario, explicit
  expectation)
- CLOSE result==0; reconnect OPEN#2 result==0, READ#2 hash matches
- `sacdstat` direct ioctl(5307) check: ret=0 (reviewer finding #4)
- sector-510 md5 printed in every transcript — the disc state itself is
  in-evidence per run

Negative control (deterministic by construction): `mkfixture ... corrupt`
destroys the **SACDMTOC magic** (8×0xAA at sector 510, offset 0) inside the
fixture build — no valid state ever exists, so no poll-window / cached-handle
coupling can produce a false pass. Both binaries must fail OPEN
(`Not a ScarletBook disc!` in daemon.out, OPEN result=-1). The gate then
explicitly refuses to award successful-disc parity from the negative run
(equal-failure-equal is rejected as a parity claim).

Transcript equality is computed on protocol steps only; sweep lines are
reconnect characterization (below).

## Verdict

```
GATE: POSITIVE-PASS original   GATE: POSITIVE-PASS release
DIFF: TRANSCRIPTS IDENTICAL    (protocol steps)
GATE: NEGATIVE original: OPEN failed as required: True
GATE: NEGATIVE release:  OPEN failed as required: True
GATE: OVERALL VERDICT: PASS
```

Evidence: `gatev/gate-run-final.txt`, `g-orig.log`, `g-rel.log`,
`g-orig-neg.log`, `g-rel-neg.log` (full UART transcripts per run, including
mkfixture output, sector-510 hexdump, readlog, daemon.out, sacdstat).

## Two instrumentation bugs found while building the gate (the daemon was right both times)

1. **In-guest client payload offset was hardcoded to rbuf+7.** The response
   header length is NOT constant: `result=128` encodes as a 2-byte varint
   (`80 01`) and `datalen=262144` as a 3-byte varint (`80 80 10`), giving a
   9-byte header. The client hashed 2 header bytes and dropped the last 2
   payload bytes on such frames, producing bogus FNV values that made the
   gate fail on `cnt=128` and boundary reads. Proof: dumped payload began
   `80 10 e7 c2 04 c3 ...` — stray varint bytes followed by the correct
   synthetic(0) data. Fix: track the payload offset at parse time
   (`g_payload_off`). Wire data was always correct pure-logical.
2. **Initial negative control (reserved06=0xAA×8) was non-deterministic in
   effect** — the validator did reject it (daemon.out: `Zero check failed ...
   reserved06 = 0xaaaaaaaaaaaaaa`), but open/session coupling (poll retries,
   in-memory handles, the OPEN-result default) made some runs still serve a
   session. Replaced with the SACDMTOC-magic corruption above.

## Reconnect characterization (reviewer finding #5)

Separate from daemon-restart/TIME_WAIT: fresh connections to the SAME
listener, 3 attempts per delay {0, 100, 300, 1000 ms}, source ports
recorded, failure classes: `connect-err | send-err | read-err | eof |
parse-fail | ok`.

- **delay ≥ 100 ms: CLASS=ok in every attempt of every run, both binaries.**
  Source ports increment normally (39872-39875, 39774-39777, 49556-49559
  across runs). No TIME_WAIT/address-reuse effect at all.
- **delay = 0 ms: race window.** `CLASS=eof` (daemon accepts, then its
  single-session logic closes the new connection while the previous
  session's teardown is still running) vs `CLASS=ok` (teardown won). The
  outcome flips **within a single run for the same binary**:
  - run 3: original = eof, eof, ok; release = ok, ok, eof
  - run 4 (final): release = eof, ok, eof (positive); original = eof, ok, ok
    (negative); earlier runs also caught the original on `eof`.
  Both binaries exhibit both outcomes ⇒ scheduler timing in the teardown
  race, not a logic difference between binaries. This matches the
  qemu-user leg's starved-session result and is treated as characterization
  data, not protocol parity. The parity candidate preserves original daemon
  behavior (same code); nothing about the candidate was changed to "fix"
  this.
- Daemon restart remains separate: no SO_REUSEADDR in the original daemon
  (kept as-is), restart TIME_WAIT ~60 s, documented previously.

## Run counts (this session)

- Positive gate (both binaries, full boot each): 5 runs — all POSITIVE-PASS
  after the client offset fix; 2 earlier runs failed on the client hash bug
  (instrumentation), 1 mid-session run verified the fix.
- Negative control: 4 runs (1 reserved06 variant — validator fired but
  control rejected as non-deterministic; 3 magic variant — all pass).
- Cross-binary transcript diff: identical protocol steps in every run;
  sweep lines differ only in race outcome, both sides flipping.

## 128-sector / encrypted-range reads (reviewer question)

Both pass in-guest and are now HASH-VERIFIED, not just observed:
`cnt=128` result=128/262144 bytes/hash-verified; encrypted-range read
result=2 with the decrypt path firing (`Inst_Decrypt` mock, labeled);
boundary clamp result=10 hash-verified.

## Reviewer findings status

1. **bdpswap relocation corruption** — FIXED and re-proven: the swap now
   remaps every relocation symbol index in every SHT_REL section; a
   post-link checker verifies every `__ksymtab_*` export resolves to its
   own symbol. The negative control (entry-only swap) reproduces the
   reviewer's exact corruption table and is rejected by the checker.
   Original v38+ in-guest results were re-validated on the fixed pipeline:
   all protocol steps unchanged, so the kallsyms path was never affected.
2. **Permanent regression gates** — DONE (this file's gate design);
   deterministic negative control included; equal-failure-equal explicitly
   rejected.
3. **errno preservation in tmpredir** — DONE (save/restore around read
   instrumentation, lseek64 for offsets).
4. **OddGetProfile output init + SACD status ioctl** — DONE: stub writes
   0x10 (SACD profile) to the output arg; `sacdstat` direct 5307 check
   ret=0 in every transcript.
5. **Reconnect characterization** — DONE (above): client-reconnect race
   isolated from daemon-restart, classes + ports recorded, both binaries
   flip ⇒ teardown timing, not address reuse, not a binary difference.
6. **AHCI assumption / large-ISO transport** — OPEN, agreed: before any
   AHCI commitment, `sata_mt85xx_mod.ko` must be shown to drive QEMU's
   AHCI; near-term route is a synthetic read-only host-image interface
   shared by both disc-read paths. No work performed yet.

## Raw wire capture (both directions), added after reviewer evidence-format request

Full raw protocol capture is now part of every gate run: the in-guest client
logs all transmitted bytes (gc-tx.bin) and all received bytes (gc-raw.bin);
the probe pushes both through the UART as hexdump (gzip when the guest has
it — it does not, so plain hex with in-transcript sizes+md5s), and
`bx510_rawdecode.py` decodes + self-verifies against the in-transcript
md5s and can emit a frame table (`--frames`).

Verified decodes (sizes and md5s match the guest's own values):
- g-orig: rx=292,992 B, tx=179 B — FRAMES IDENTICAL to g-rel
- g-rel:  rx=292,992 B, tx=179 B
- g-orig-neg / g-rel-neg: rx=283 B, tx=179 B — FRAMES IDENTICAL to each other

`diff g-orig-frames.txt g-rel-frames.txt` → IDENTICAL (21 frames);
`diff g-orig-neg-frames.txt g-rel-neg-frames.txt` → IDENTICAL (22 frames).
This is wire-byte parity, one level beneath transcript parity: every
response frame's type, result, datalen and payload FNV-1a64 match between
the two binaries, including the nine delay>=100ms sweep responses; the
delay=0 sweep attempts produced no bytes in this run (all `CLASS=eof`).

Frame table (positive, both binaries identical):
```
frame 0: type=1 result=0                       (OPEN)
frame 1: type=4 result=86200                  (SIZE)
frame 2: type=3 result=1  datalen=2048    fnv=d97788e2a0c64108   (lsn=0)
frame 3: type=3 result=1  datalen=2048    fnv=bde82ababdb96703   (lsn=43100)
frame 4: type=3 result=128 datalen=262144 fnv=5dd84041102d0c25   (cnt=128)
frame 5: type=3 result=10 datalen=20480   fnv=2de6e18816a06325   (boundary clamp)
frame 6: type=3 result=2  datalen=4096    fnv=b93a0c83ce3b6325   (encrypted)
frame 7: type=3 result=0                       (beyond EOF)
frame 8: type=2 result=0                       (CLOSE)
frames 9-11: OPEN#2 / READ#2 (fnv=bde82ababdb96703) / CLOSE#2
frames 12-20: nine sweep OPENED responses (delay 100/300/1000 ms x 3)
```
Note frame 4's fnv (5dd84041102d0c25) equals the independently computed
hash of synthetic sectors 0..127 — the exact value the gate expects.

### Capture-evidence lesson: kernel printks interleave MID-LINE on the shared UART console

The first decode attempt failed md5 on both positive captures: 16-byte
hexdump lines went "missing". The bytes were never lost — the log showed
`<32 hex chars>bdpvirt: TestUnitReadyLoop(a=0x4e20)`: the daemon's poll
thread calls into the module every second, and the stub's printk is
emitted on the same UART console the hexdump is writing to, gluing itself
onto an in-flight hex line with no newline. The decoder now recovers
hex prefixes glued to recognized printk markers (9 and 15 recovered lines
in these captures; anchored split so hex-valid letters inside the printk
text cannot shift it), and the probe additionally lowers the console
loglevel before rawdump so module printks stay off the console entirely.

### Self-pair runs

Explicit original->original and release->release transcript diffs are now
part of gate2.sh (6 boots total): both self-pairs PASS the positive gates
and their protocol transcripts are identical to the cross-binary run.
Verdict aggregation requires cross-positive, negative control, and both
self-pairs to pass.

Invocation evidence: gate2.sh contents are reproduced in
gate-run-final.txt's transcript headers (reference path + sha256 per run);
pinned ELF hashes are verified at the top of every gate run and fail
loudly on mismatch.

## Gate hardening (virtual-drive team altered-log review, round 2)

The team fuzzed the gate with altered copies of the saved transcripts and
found four alterations that still produced PASS. All are fixed, and each
is now a permanent regression control (tools/test_bx510_gate.py, 11/11
passing; baselines are constructed from the gate's own generators, so the
hashes are computed, not copied from a run):

1. Complete ordered sequence + response types. The gate now requires the
   full ordered step list - OPEN, SIZE, five READs (with types), the
   data[0..15] line checked byte-for-byte against the generator, both
   CLOSEs, the reconnect OPEN#2/READ#2 (with length) and CLOSE#2, all 12
   sweep combinations (att-major order, each exactly once), and the
   GC: DONE completion marker. Removing STAT or CLOSE#2, setting every
   type to 99, reordering READs, or dropping DONE all fail validation.
   Removing DONE also exposed a real gate hole (the marker check only ran
   when a following line existed) - closed.
2. STAT record required in EVERY transcript, with both the syscall result
   (ret=0, errno=0) and the module operation result in arg[0] (a=0,
   signed - sacdstat now prints it signed). A nonzero arg[0] fails.
3. Sweep responses validated explicitly: positive delay>=100ms must be
   CLASS=ok type=1 result=0; negative must be result=-1; delay=0ms is the
   documented teardown-race window (eof or the mode's result). A missing
   result is a failure (the None!=0 laxity is gone).
4. Boundary and encrypted-range sectors now carry distinct nonzero data
   (synthetic sectors at 79990..79999; a differently-salted pattern at
   80000..80001, byte-identical in fixture_gen.py and bx510_mkfixture.c).
   The wire frames confirm: boundary fnv 25c3b776ddac07fd and encrypted
   fnv a4903e500a141a95 - both equal the gate's independently computed
   expectations, so wrong-sector reads and packing failures can no longer
   hide in zeros.
5. The exact runner is committed (tools/bx510_gate2.sh, mirrored in this
   evidence dir) and binary identity is enforced BY ROLE: the probe takes
   --role original|release and accepts only that role's pinned SHA-256
   (the either-digest laxity is gone); the runner independently verifies
   both pinned digests before booting, and every transcript header carries
   the role, the run's own digest, BOTH pinned digests, and the exact
   invocation.

Fresh 6-boot run under the hardened gate: OVERALL VERDICT: PASS - positive
gates both binaries, negative control fails OPEN on both, both self-pairs
identical, session frames (12 protocol steps) IDENTICAL in both modes.
Raw captures decode and verify with ZERO printk-glued lines (the console
loglevel quieting landed); the positive frame-table tails differ only in
this run's delay=0 race outcomes (original: eof/ok/ok, release: eof/eof/
eof - both classes documented, protocol frames unaffected).

Operational note: the first hardened-run attempt silently used a stale
runner (make vm-script stages the LOCAL script path, overwriting the
scp'd copy) - the gate then correctly rejected the old-format transcripts.
The local /tmp/gate2.sh must be refreshed from tools/bx510_gate2.sh
before every vm-script invocation.

## Runner improvements (team review round 4) + fresh evidence dir

Two review requests landed in the canonical runner (tools/bx510_gate2.sh):

1. **Failure propagation + fresh output directories.** The blanket `|| true`
   is gone. The probe now exits nonzero when P0_FINISHED never appears
   (execution failure - dead boot, UART loss, timeout), and the runner
   treats that as FATAL, printing the probe's tail. An expected negative
   protocol response lives INSIDE a completed run and is unaffected. Every
   invocation writes to a fresh timestamped directory
   (/tmp/gatev-<stamp>), so earlier valid evidence can never be silently
   overwritten or mixed with a new run; transcripts must be non-empty.
   The runner's own SHA-256 is printed and recorded in the verdict and in
   every transcript header, alongside role, both pinned ELF digests, and
   the exact probe invocation. Staging is from the tracked source
   (tools/bx510_gate2.sh -> /tmp/gate2.sh) - the stale-runner incident's
   structural fix.

2. **Raw-frame verification is part of the verdict.** After the six boots,
   the runner now decodes both captures per mode (self-verifying against
   the in-transcript md5s) and requires the deterministic session bytes
   (through CLOSE#2) and the complete request streams to be IDENTICAL
   before OVERALL PASS may print (bx510_rawdecode.py --session-diff;
   session span defined as the bytes through the second type=2 CLOSE
   response - everything after is the documented reconnect-sweep race
   window).

Fresh run under the improved runner: OVERALL VERDICT: PASS (gates,
self-pairs, raw-frame verification) - evidence in
gatev-20261103-211756/: session bytes identical (292,947 positive /
143 negative, through CLOSE#2), request streams identical (179 bytes),
all four comparisons pass, console quieting holding (0 printk-glued
lines).

The set -e interaction was caught during the change (a nonzero probe
exit would have aborted the script before the rc check) - all gate
calls now use the `|| rc=$?` pattern with initialized accumulators.
