# Run C105 — the 5303 specimen, and the origin question CLOSED: **stale heap.**

**Verdict: the run adds one decisive measurement and closes run-c104.md's
biggest OPEN.** The 4128-byte `sacd510` dump — C104's "real, structured,
non-ISO data with both descriptor transfers refused" — is **not a framing
specimen at all: it is an UNFILLED buffer.** The ioctl's kmalloc'd result
buffer was never written (the FE refused both 2064-byte transfers, exactly as
modelled), the driver returned success anyway, and the allocator handed back
a recycled chunk holding the tar-staged `sacdread_smoke.sh` text, one 512-byte
block still carrying the driver's `0xbb` poison.

Run identity: `ts_utc 2026-11-13T16:52Z` fire, same C104 line with two
deltas: `srread` rebuilt (41 728 B) with the new `hex <file> <label>` mode
(64 B/line `DUMPHEX` rows through the UART — the guest has no host-visible
filesystem, `/res` dies with the guest, and C104's dump was unrecoverable
from its tmpfs), and the ladder's leg (e) now emits the dump after hashing
it. Reassembly: 65 rows + `total=4128`, lossless, md5(4128) =
`7abdaaffb790c8fd5249b5f98cb69f95`.

## 1. The stale-heap identification (three independent strings, not one)

The dump's printable runs are verbatim smoke-script lines:

```
elif mknod -m0666 "$DEV" c 10 "$MINOR" 2>/dev/null && [ -c "$DEV" ]; then
    g06d="created $DEV c 10 $MINOR"
gate S06 sacd-read-node "$g06" "$g06d"
#  ioctl 0x40105301 INIT: the bdpdrv hook proof
# CPSA_SACDCmdEnable(compid): Connect(0x16b,compid,360,0) ->
```

— i.e. the extracted `/res/shim/sacdread_smoke.sh` content (page cache the
tmpfs extraction left behind), with the frame-0 header the only surviving
`0xbb` poison block. The verdict gate now names this state: a `want >0` check
greps the reassembled DUMPHEX bytes for the staged-file text and fails G as
**`5303 buffer unfilled (stale-heap signature)`** — a different, more
actionable failure than the old `unresolved`. On this run: 3 signature hits,
row fires.

## 2. What this resolves, and what it re-opens

| item | C104 state | C105 state |
|---|---|---|
| the 5303 dump's origin | OPEN (driver state? a-window? GCPU?) | **CLOSED: stale heap** — unfilled buffer, string-matched to the staged smoke script (VERIFIED, three independent lines + poison block) |
| the dump as framing evidence | "first real specimen" | **WITHDRAWN** — it measures the allocator's recency, not SACD framing; the layout stays `unresolved` and the decode lane waits for a real transfer |
| the false-positive class | not named | **NAMED + gated**: a ret=0 read with an unfilled buffer is now a gate-visible failure |
| plain-read oracles, past-EOF, poison, EH | all green | **all green again** (28 PASS / 2 FAIL: framing unresolved + the new stale row) |

The model is **exonerated and correct** on this path: it refused the 2064
transfers by name, the guest recorded the errors, and the "success" is the
driver's own unfilled-buffer return — which is exactly the behaviour a real
BX510's driver would show against a drive that refuses its SACD reads. The
remaining work is unchanged from C104 §7, with one clarification: the
framing lane needs the **GCPU/Connect leg first** (CPSA Connect `0xE8000000`
is still the gate), because a real 2064 transfer may only happen once the
decrypt pipeline is live.

## 3. Reproduce

Same fire line as C104 §6 with `runC105` names; the helper hex mode and the
gate's stale row are the only tooling deltas. `DUMPHEX` reassembly one-liner
and the signature grep are in `decode/read10_verdict.sh` §G.

## 4. Next

| # | change | owner | settling observable |
|---|---|---|---|
| 1 | **GCPU/Connect model** — decode doc in flight (`decode/gcpu-connect-path.md`), then the model answers Connect until `result=1744830464` | decode worker + model | INIT returns `0x68000000` |
| 2 | identity decrypt behind Connect (Level 0), then the synthetic-cipher upgrade (Level 1) | model + fixture | a 5303 dump whose layout test *passes*, post-decrypt md5s unchanged |
| 3 | framing decode | waits on 1-2 | a dump that is NOT stale-heap |
| 4 | daemon stage | after 1 | the daemon's READ traffic in the FE census |
