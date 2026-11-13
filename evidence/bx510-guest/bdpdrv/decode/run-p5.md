# Run C102 — P5 IDE-HAL transport leg (`drv.ide.pri_ver.initial 0 s 0`) on the variant-A a-window

**Scope.** One fire, one question: with the committed variant-A model (commit `996c5fc`:
`a+00c…a+018` serves the ONE D2H signature block `01/01/14/eb`) and the v2 dotted
`PROBE_SEQ` ladder, what do the P5 lines actually say — against **both** the old
prediction matrix (`decode/ide-cli-lane.md` §4.5/§6) and the corrections in
`decode/ide-hal-rows.md` §5?
**Not touched:** nothing in the repo. No commit, no staged files (evidence lives beside
this file only). `emulator-kit/sony-bx510.c` is *not* edited by this run — see §1.3.

**Inputs:** `decode/ide-hal-rows.md` §0/§5/§6, `decode/ide-cli-lane.md` §4.2–§4.5/§6,
`decode/probe-seq-v2.md` §1/§2, `decode/feboot-option-a.md` §3–§4,
`/tmp/bdpdrv/bdpdrv.ko` (IDE HAL, on the lab VM) via
`arm-none-linux-gnueabi-objdump -dr` + `nm` + ELF `.rel.text` scans.
**DECODED** = an instruction/reloc/byte fixes it. **INFERRED** = consistent with every
instruction seen, settling experiment named.

---

## 0. TL;DR

1. **Row 1 is PROVEN.** Guest printed `[i4IdeHalTestInit]Signature:0x140101`. The MMIO
   trace shows exactly the three `ldr` reads the decode predicted (`a+014`, `a+010`,
   `a+00c`, in that instruction order) and nothing else. Variant A is what the IDE HAL
   composes: **`0x140101`, not `0x140100`, not `0xeb1401`**.
2. **Row 2 (`a+220` bit5 completion) was NOT exercised.** The run never posted the
   command: **no write to `a+004/a+008/a+00c/a+010/a+014/a+01c` exists anywhere in the
   trace**, so `vIdeHalSendCmd` never ran and the `flags&3==1` wait never gated on bit5.
   `ide-hal-rows.md` §5.4's `(ERR)Ret:-5, ST:0x58` row is neither confirmed nor refuted.
3. **A new, earlier blocker — decoded to the instruction:** `i4IdeHalAtaCmd` clears
   event bit0 via `i4IdeOsEventClear(handle, 1)` (→ `x_ev_group_set_event(h, ~1, op=2)`);
   the OSAL stub's `x_ev_group_set_event` **ignores `op` and always ORs**, so the "clear"
   sets every other flag — including bit1, the HAL's *abort-pending* flag.
   `i4IdeHalSAtaReg` then reads the event value, sees bit1, and bails with
   `[i4IdeHalSAtaReg(1072)]ERR:-4` before `vIdeHalRegDmaEnable`/`SetXferReg`/`SendCmd`.
   `1072` is `__LINE__`, not a channel or a size (§3.1).
4. **The v2 ladder itself is green:** P0 `rc=0` + `Read addr = 0x00001000, length = 0`
   with no payload row (the old shim's `-10` is gone), P1 `rc=1`, P2 `rc=1` with
   `[Help]` + 57 entries, P3 `rc=0`.
5. This is the **harness-noise class, not a target bug**: the a-window row and the
   model are fine; the OSAL stub's event-group op handling is the next lever.

---

## 1. Run identity

### 1.1 Run number — C102, and why

`ls /tmp/bdpdrv-runC*.uart.log` on `10.20.0.18` at 05:21Z: numerically the highest was
**C101** (`bdpdrv-runC101.uart.log`, 94,164 B, 05:05Z); no `bdpdrv-runC102.*` existed
and no `qemu-system-arm`/`bx510_bdpdrv_stub_probe` process was running, i.e. the
`c102-fire` worker had not fired. So **the next free number was C102** and it was taken;
artifacts were pulled to this bundle within seconds of the fire so a later C102 from a
peer cannot silently overwrite this evidence (a re-fire under a new number is the honest
response if that happens).

### 1.2 Artifacts (this bundle, `evidence/bx510-guest/bdpdrv/`)

| file | size | note |
|---|---|---|
| `bdpdrv-runC102.uart.log` | 95,413 B / 2,048 lines | the guest transcript |
| `bdpdrv-runC102.meta.json` | 923 B | `terminal_marker: true`, `clidrive_mode: PROBE_SEQ` |
| `bdpdrv-runC102.mmio.log.gz` | 1,615,690 B (102,321,909 B raw) | `BX510_TRACE=1` every-MMIO trace |
| `bdpdrv-runC102.fire.out` | 342 B | fire wrapper stdout |
| `disasm/bdpdrv-runC102.p5-awindow.trace.txt` | 3.8 KB | a-window slice of the trace (124 lines) |
| `disasm/bdpdrv-runC102.p5-uart-excerpt.txt` | 4.3 KB | UART lines 1836–2045 (the ladder + P5) |
| `disasm/p5-satareg.txt`, `p5-atacmd.txt`, `p5-testinit.txt` | 8.8–13.5 KB | function-scoped `objdump -dr` |

Built/staged identity captured immediately before the fire (05:21:50Z):

| item | value |
|---|---|
| QEMU | `work/build/qemu-system-arm`, md5 `db743cb62d61e007ebc12368efd9740d` |
| model source (build tree) | `sony-bx510.c` md5 **`3888f852fb1771596752ffa2636eca77`** = `git show HEAD:emulator-kit/sony-bx510.c` |
| clidrive shim (v2) | `/tmp/osal_c/bx510_clidrive.ko` md5 **`e1d14c2577fd7a65bf54d3d51ef22897`**; `strings` shows the mode banner `PROBE_SEQ (%d probes, dotted ladder)` + both dotted probes |
| osal stub part B | `/tmp/osal_b/bx510_osal_stub.ko`, sha256 `d78be553…` (same as C100/C101) |
| osal stub part A | `/tmp/osal_a/bx510_osal_stub_a.ko`, sha256 `63cdd078…` |
| bdpdrv.ko | sha256 `6604f6cd…`, 8,122,068 B (unchanged since C50) |
| disc | `firebird.iso` md5 `217ea92bdb6915dd229055facba43552` (the pinned fixture) |
| run window | 05:21:50Z → 05:22:29Z (39 s), `FIRE_RC=0`, `STUB_DONE` seen |

### 1.3 One deliberate recipe choice: the C101-era fire script (feboot retained)

The fire script used is the script **C101 itself ran** —
`~/bx510-emu/emulator/bx510_bdpdrv_stub_probe.py`, md5 `53320de8ea936b337ed184a0c5109a58`,
which is byte-identical to `git show 6fc4282^:tools/bx510_bdpdrv_stub_probe.py`. It still
stages and insmods `bx510_feboot.ko`; the run shows the expected feboot rows
(`[FEB] up`, the `proc_register` WARNING, `FEB_INSMOD=0`).

Reason: this run must differ from C101 in **exactly two** variables — the model
(variant A) and the shim (v2 ladder). Tracked HEAD's script has feboot-option-A applied
(`6fc4282`), which would add a third variable (real-vs-forged `_fg_fe_bootup`, the
`proc/driver` shadowing question, and its documented unbounded-poll risk) to a transport
measurement. Option-A is a separate experiment (`decode/feboot-option-a.md` §3.2's delta
table is its read-out), not a passenger on this one.

Side effects to record honestly: `tools/bx510_bdpdrv_stub_probe.py` (HEAD, md5
`574cb963…`, option A + `--clidrive-mode`) was scp'd to **VM `/tmp/` only**, replacing the
identical-content copy there; the emulator-directory copy the fire uses was left alone.
`tools/procc.sh` does not exist in the repo tree, but the VM's
`~/bx510-emu/emulator/procc.sh` (936 B) does, so `procc.sh` rows **are** present
(`PROCCHECK-*` ×6, `1CAT_FB=0`, `MOUNT_DONE`) — the `procc.sh` staging confound in
`feboot-option-a.md` §5 (confound 2) did not apply.

The repo working tree also carries an **uncommitted** 178-line change to
`emulator-kit/sony-bx510.c` (md5 `b41bb7ed…`) from another lane. The VM's copy and the
built binary are **HEAD** (`3888f852…`), so this run tests the committed variant A, not
that WIP.

---

## 2. The v2 ladder (P0→P3)

```
[CLIDRIVE] mode = PROBE_SEQ (4 probes, dotted ladder)
[CLIDRIVE] parser('P0 drv.read 0x1000 0') = 0
Read addr = 0x00001000, length = 0
[CLIDRIVE] P0: handler ran; cur = 0x0; expect rc=0 + ...
[CLIDRIVE] parser('P1 driver') = 1
...
[CLIDRIVE] parser('P2 drv') = 1
[CLIDRIVE] parser('P3 drv.ide.pri_ver.initial 0 s 0') = 0
```

| row | probe string | expected (probe-seq-v2 §1.1) | observed | verdict |
|---|---|---|---|---|
| P0 | `drv.read 0x1000 0` | rc 0 + `Read addr = 0x00001000, length = 0`, **no** payload row | rc **0**, line present, no payload row | **PASS** — dotted leaf dispatch works; C101's `read 0x1000 16` → `rc=-10` is dead |
| P1 | `driver` | rc 1, `[Help]` + `hdmitx(hdmitx)` | rc **1** | **PASS** |
| P2 | `drv` | rc **1** + 57 lane lines incl `read(r):` | rc **1**, `[Help]` + **57** entries (58 non-blank lines), `read(r):  Memory read(word)` present | **PASS** — confirms the v2 table's P2 row (57, not the old 48; the `-10` note was a mislabel) |
| P3 | `drv.ide.pri_ver.initial 0 s 0` | rc **0** + `Signature:` + `CH:0, SataDev:1, UseQueue:0 Done!` | rc **0** + both lines (see §3) | **PASS** (handler reached and ran; the transport itself stops one row later) |

So the shim on the VM is the v2 build (md5 matches, banner says 4 probes/dotted, P0's old
`-10` is gone) — no ambiguity about which binary fired.

---

## 3. The P5 lines, and the one blocker

### 3.1 The exact observed block (UART 2032–2038)

```
[CLIDRIVE] P2: directory matched, help dumped; ...
[i4IdeHalTestInit]Signature:0x140101
[OSAL_STUB] crit_end depth=0
[OSAL_STUB] x_ev_group_get_info called
[i4IdeHalSAtaReg(1072)]ERR:-4
[OSAL_STUB] crit_end depth=0
[i4IdeHalTestInit]CH:0, SataDev:1, UseQueue:0 Done!
```

`1072` is **`__LINE__`, not an argument of interest.** The format string family is
`[%s(%d)]ERR:%d` (`.rodata.str1.1` VMA `0x2e509`), `__FUNCTION__` is the
`.rodata` string at VMA `0x1296ec` (`"i4IdeHalSAtaReg"`, next to
`i4IdeHalPPktReg`/`i4IdeHalSPktReg`), and the pool slot at `i4IdeHalSAtaReg+0x3f4`
(`0x9ce10`) holds the literal `0x429` = **1065** for the sibling log site while the
site that fired loads `mov r2, #1072 ; 0x430` at `0x9caf4`. (DECODED)

### 3.2 Which instruction produced `-4` — DECODED

`i4IdeHalSAtaReg` prologue (`.text 0x9ca10`, `disasm/p5-satareg.txt`):

```
9ca34  bl  fgIdeHalNeedIntrq        ; flags 0x31 -> 1
9ca50  bl  vIdeHalEnableIntrq       ; W a+038  (seen in the trace)
9ca5c  bl  i4IdeHalFlushEvt(ch,0)   ; ISR unregistered -> drain a+220 via
                                    ;   _u4IdeHalHwIntStatus (READ, W1C, 3 readbacks)
9ca68  bge 9ca9c                    ; flush ok -> continue
9ca9c  ldr r0,[_hIdeHalChEvt + ch*4]; bl i4IdeOsEventValue(evt, &val)
9cab4  bne 9cb14                    ; EventValue failed -> continue
9cabc  tst r3,#2                    ;  v  val & 2  (ABORT-PENDING flag)
9cac0  beq 9cb14                    ; clear -> continue to DMA/Xfer/SendCmd
9cac4  mvn r3,#3 ; str r3,[sp,#28]  ;  ret = -4
9caf4  mov r2,#1072                 ;  <- the log's __LINE__
9cafc  bl  UTIL_Printf              ; "[i4IdeHalSAtaReg(%d)]ERR:%d"
9cb10  b   9cdf8                    ; RETURN — never reaches
9cb34  bl  vIdeHalRegDmaEnable      ;   the DMA enable,
                                    ;   the 512-B SetXferReg (a+24c), or SendCmd
```

`vIdeHalSendCmd` is the only writer of `a+004…a+01c`; the trace has **zero** writes to any
of those words for the whole boot (one `a+018 = 0` dev/head write, twice, is SelDev).
⇒ the ATAPI `0xa1` IDENTIFY PACKET command was never issued, so the `flags&3 == 1` wait
(`i4IdeHalWaitEvt`) never ran. (DECODED + trace)

### 3.3 Who set event bit1 — DECODED, and it is the OSAL stub

```
i4IdeHalInit      0x99c78  i4IdeOsEventCreate(ch)  -> x_ev_group_create(...); then
                                                    x_ev_group_set_event(h, 1, op=3)   => flags = 0x1
i4IdeHalAtaCmd    0x9a4c0  r1 = 1
                  0x9a4c8  i4IdeOsEventClear(evt, 1)
                           -> 0xa7020:  mvn r1,r1 (=0xFFFFFFFE) ; r2 = 2 ; b x_ev_group_set_event
tools/bx510_osal_stub.c:578  x_ev_group_set_event(h, mask, op) { ... o->flags |= mask; }   # op ignored
                           => flags = 0x1 | 0xFFFFFFFE = 0xFFFFFFFF      <-- bit1 now SET
i4IdeHalSAtaReg   0x9cab8  val = 0xFFFFFFFF ; tst #2 -> taken -> ERR:-4, return
```

The stub's own comment records why: *"op=3 observed (OR)"* — C50..C101 never exercised the
clear path, so the stub was written for OR only. This run is the first to call
`i4IdeOsEventClear`, and the operand shape (`~mask` with `op=2`) is exactly an AND-clear,
which `|=` cannot express. The same stale flag is also tested by
`i4IdeHalPollingStReg` at `0x9b060` (`tst #2` → `mvn r2,#2` = **-3**), so this bug would
have poisoned the next `SelDev` wait too.

**Classification:** HARNESS (OSAL stub semantics), not target, not model. It is the class
`AGENTS.md` calls out: *"Harness noise ≠ target bug"*. Label: **DECODED** for the call
shape and the instruction-level failure; **INFERRED** that `op==2` means "AND with the
supplied value" — settling experiment: fix the stub, re-fire, and read whether P3 now
posts `a+01c = 0xa1`.

### 3.4 The a-window trace of the P3 leg (wire-level record, `disasm/…p5-awindow.trace.txt`)

```
R a+400 ×4, W a+400=0x801, R a+400 …            ; vIdeHalSataDevSetup
R a+600, W a+600=0xa037414d, R a+600 ×6          ; PHY poll — passes (no Assert row)
R a+080, W a+080=4, R ×4, … , W a+080=0, R ×4    ; vIdeHalBusEnable
W a+018=0, R a+018 ×4                            ; i4IdeHalSelDev dev/head
R a+038                                          ; poll, single-shot pass (mask 0x80)
R a+01c                                          ; status classify read (model serves 0x50)
W a+018=0, R a+018 ×3                            ; second SelDev (GetSignature's)
R a+014, R a+010, R a+00c                        ; <- i4IdeHalGetSignature's three ldr's
R a+6a4, W a+6a4=0, R ×4                         ; i4IdeHalAtaCmd error-reg clear (unimplemented in model)
R a+038, W a+038=0, R ×4                         ; vIdeHalEnableIntrq (unimplemented in model)
R a+220, W a+220=0, R ×3                         ; FlushEvt drain (value 0 -> loop exits at once)
                                                 ; *** -4 here: no taskfile write, no a+01c write ***
```

Corroborating detail for row 1: the three signature reads appear **once each**, in the
composed order `a+014 → a+010 → a+00c`, exactly the `i4IdeHalGetSignature` instruction
order (`0x9a418/0x9a420/0x9a42c`) — this is the wire-level proof that the printed
`0x140101` came from the model's block and not from a cached/stale value.

Read values are not in the `BX510_TRACE=1` trace (offset+size only), so the composition
`(u8@+014)<<16 | (u8@+010)<<8 | (u8@+00c)` is evidenced by the guest print
(`0x140101`) plus the model source's `sig[4] = {01,01,14,eb}` / `guard i>=2` — not by
reading a value out of the trace.

---

## 4. Verdict table — against BOTH matrices

### 4.1 Against the OLD matrix (`ide-cli-lane.md` §4.5, and §6's table)

| old prediction / row | observed | verdict |
|---|---|---|
| `[i4IdeHalTestInit]Signature:0x140100` (model's `+010…+018` placement, `+00c`=0) | `Signature:`**`0x140101`** | **FALSIFIED** — variant A took; the a-window serves one D2H block and the HAL's slice is `+00c…+014` |
| `Signature:0xeb1401` ⇒ "HAL placement is `+0c/+10/+14`" (old alternative branch) | not observed | **FALSIFIED as an expectation** — `0xeb1401` is libata's recomposition (`lbah<<16|lbam<<8|lbal`), not what the HAL prints (`ide-hal-rows.md` §1.4) |
| `[i4IdeHalSAtaReg(0)](ERR)CmdWaitEvtRet:<n>` + `TIMEOUT !!`, no data phase | neither line appears | **NOT REACHED** (not "falsified": the command was never posted, §3.3) |
| `[i4IdeHalTestInit]CH:0, SataDev:1, UseQueue:0 Done!` | present, exactly | **CONFIRMED** |
| "if `ModelName:` appears, the two rows are disproved" | no `ModelName:`, no `Support UDMA Mode:` | **CONFIRMED absent** (trivially — no data phase happened) |
| §6 P5-e: guest-side `SATA WR a+01c sz4 = 0xa1` | **absent** | **FAILED as a gate** — and the trace says why, not the model |

### 4.2 Against `ide-hal-rows.md` §5's corrections

| §5 correction | observed | verdict |
|---|---|---|
| §5.4 `[i4IdeHalTestInit]Signature:0x140101` | present | **CONFIRMED** (this is the run's headline) |
| §5.4 `[i4IdeHalSAtaReg(0)](ERR)Ret:-5, ST:0x58` ("rows 1+2 landed; the post-wait status poll is the next row") | `[i4IdeHalSAtaReg(1072)]ERR:-4` instead | **NOT REACHED** — §5.1's "`a+01c` is a real gate → −5" is *untested* by this run |
| §5.1 "`a+038` spin is a silent single-shot pass" | exactly one `R a+038` at SelDev, no delay loop | **CONFIRMED** |
| §5.2 "the `a+6b8` spin is not on P5's path" | no `a+6b8` access at all | **CONFIRMED** |
| §5.3 "no data phase (DMA via `a+24c`), `ModelName:` is a later row" | no `a+24c`, no `a+000`, no `a+25c` access | **CONFIRMED** (no data phase existed) |
| verdict-matrix row "`a+01c` never written ⇒ the command never reached the window ⇒ look at `a+600`/`a+6b8`, not at the status row" | `a+600` poll passed (no Assert), `a+6b8` never touched ⇒ neither named suspect applies | **ROW HIT, DIAGNOSIS EXTENDED** — the real blocker is upstream of the window (§3.3) |

### 4.3 What this run does and does not settle

* **Settled:** the a-window signature row (row 1) and its exact value; the v2 ladder
  (P0/P1/P2/P3 rc + P0's line); the model's a+600 PHY answer, the a+038 silent pass, and
  "no data phase" are all still true after the rebase to variant A.
* **Not settled:** the `a+220` bit5 completion row (row 2) — unexercised. Whoever reads
  this as "row 2 is broken because the leg aborted" would be wrong in the same way the
  old `CmdWaitEvtRet` prediction was: the leg never got there.
* **Open row for the stub:** `x_ev_group_set_event`'s `op` handling (§3.3).

---

## 5. Residual risks / open questions

1. **The stub fix is a two-part change, not a one-liner I own.** `tools/bx510_osal_stub.c`
   §`x_ev_group_set_event` must branch on `op` (3 ⇒ `flags |= mask`; 2 ⇒ `flags &= mask`),
   then part B rebuilt and restaged (`/tmp/osal_b/bx510_osal_stub.ko`) and the run
   re-fired. That single change flips the P3 leg from "bails at idehal.c:1072" to
   "posts the command", and *then* row 2 becomes measurable. Recommend it as the next
   fire; do not bundle it with anything else.
2. **`op` semantics are INFERRED as AND.** If the real OSAL op-2 contract is something
   else, the stub fix could be wrong in a new way; the re-fire is the discriminator
   (P3 must post `a+01c = 0xa1` and must not print `ERR:-4`).
3. **P3's signature is a fingerprint of placement only.** Per `probe-seq-v2.md` §4.2 the
   a-window is shared with the C97 libata path; this boot's libata traffic ran
   (`class=3`, ATAPI enumerated) yet the trio still read `01/01/14/eb`, so no perturbation
   was observed here — but a boot with different disc traffic is not comparable.
4. **feboot was retained deliberately (§1.3).** This run therefore does not speak to
   option-A; `[v4IdeDrvInitThread]FE boot up OK !!` and `End..` printed because the module
   forged the flag (and/or the real one; undecidable in this recipe by construction).
5. **C102 is shared namespace.** If the `c102-fire` worker fires later under the same
   number it will collide on `/tmp/bdpdrv-runC102.*`; this bundle is already pulled, so
   the loss would be its evidence, not this one. A re-fire here should take the next free
   number at that time.

---

## 6. Reproduce

```sh
# identity (must all match §1.2 before believing a fire)
make vm-exec CMD='md5sum /tmp/osal_c/bx510_clidrive.ko'                  # e1d14c25… (v2)
make vm-exec CMD='md5sum /home/aftermath/bx510-emu/emulator/sony-bx510.c' # 3888f852… (HEAD)
make vm-exec CMD='md5sum /home/aftermath/bx510-emu/emulator/bx510_bdpdrv_stub_probe.py' # 53320de8… (C101-era)

# the fire (script staged with make vm-stage-file FILE=/tmp/p5-fire.sh; make vm-script)
cd ~/bx510-emu/emulator && BX510_TRACE=1 \
  BX510_MACHINE_OPTS='sata-disc=/home/aftermath/sacd-verify/firebird.iso' \
  python3 bx510_bdpdrv_stub_probe.py \
    --qemu work/build/qemu-system-arm --images /tmp/images-fe \
    --stubko /tmp/osal_b/bx510_osal_stub.ko --stuba-ko /tmp/osal_a/bx510_osal_stub_a.ko \
    --bdpdrv-host /tmp/rootfs/lib/modules/2.6.35/BDP/bdpdrv.ko \
    --bdpdrv-guest /lib/modules/2.6.35/BDP/bdpdrv.ko \
    --pre-file libata.ko=/tmp/sata_staging/libata.ko \
    --pre-file sata_mt85xx_mod.ko=/tmp/sata_staging/sata_mt85xx_mod.ko \
    --extra-file bx510_feboot.ko=/tmp/osal_d/bx510_feboot.ko \
    --extra-file bx510_clidrive.ko=/tmp/osal_c/bx510_clidrive.ko \
    --clidrive-mode PROBE_SEQ \
    --uart /tmp/bdpdrv-runC102.uart.log --unimp /tmp/bdpdrv-runC102.mmio.log \
    --meta /tmp/bdpdrv-runC102.meta.json --timeout 300

# verdict greps
grep -n 'mode = PROBE_SEQ\|parser(.P[0-3]\|Read addr =\|i4IdeHal' /tmp/bdpdrv-runC102.uart.log
gunzip -c /tmp/bdpdrv-runC102.mmio.log.gz | grep -E 'MMIO [RW] 00a[0-9a-f]{3}'   # no W to a+004..a+01c
gunzip -c /tmp/bdpdrv-runC102.mmio.log.gz | grep -c 'MMIO W 00a01c'            # 0

# the decode (§3.1–§3.3)
export PATH=$HOME/gnuarm/bin:$PATH
arm-none-linux-gnueabi-objdump -dr --start-address=0x9ca10 --stop-address=0x9ce60 \
  /tmp/rootfs/lib/modules/2.6.35/BDP/bdpdrv.ko     # i4IdeHalSAtaReg: -4 / line 1072
arm-none-linux-gnueabi-objdump -dr --start-address=0x9a470 --stop-address=0x9a500 \
  /tmp/rootfs/lib/modules/2.6.35/BDP/bdpdrv.ko     # i4IdeHalAtaCmd: Clear(evt,1)
arm-none-linux-gnueabi-objdump -dr --start-address=0xa7018 --stop-address=0xa7030 \
  /tmp/rootfs/lib/modules/2.6.35/BDP/bdpdrv.ko     # Clear wrapper: mvn r1,r1 ; op=2
```

---

## 7. One-line summary

C102 fired clean (v2 shim `e1d14c25…`, variant-A model `3888f852…`, C101 parity script):
P0/P1/P2/P3 = `0`/`1`/`1`/`0`, and P3 printed **`[i4IdeHalTestInit]Signature:0x140101`** —
variant A proven — but the leg stops one row *earlier* than either prediction matrix
expected: the OSAL stub's `x_ev_group_set_event` ignores `op`, so `i4IdeOsEventClear(evt,1)`
turns event flags into `0xFFFFFFFF`, `i4IdeHalSAtaReg` sees its abort bit and returns
`ERR:-4` at idehal.c:1072 without ever writing `a+01c`, leaving the `a+220` bit5 completion
row unexercised.
