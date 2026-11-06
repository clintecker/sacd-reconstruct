# Hardware session 2026-11-05 — candidate acceptance, standby, and the display leg

Player: Sony BDP-BX510, firmware M15.R.0257, `10.20.1.236`.
Disc: Tomita Firebird SACD (ISO 2,179,497,984 bytes = 1,064,208 sectors).
Kernel: Linux 2.6.35, armv6l, glibc 2.12.2 (inventory report).

This session answered four questions that had been open for weeks. Everything
below is hardware-observed, with the artifact named.

## 1. THE CANDIDATE ACCEPTANCE — PASS

The reconstructed release binary `e91720fb…` served the real disc on the
player, byte-identically to the original `0fdcefdb…`:

```
OPEN 0   SIZE 1064208
lsn0 1-sector   e5a00aa9991ac8a5     (== ISO bytes)
lsn0 128-sector a28db88d35dbf586     (== original binary's value)
lsn 532104      72e971d9ca072881     (== ISO bytes)
beyond-EOF refused (got=0), reconnect clean
```

Both manifests (`evidence/bx510-baseline/`, `evidence/bx510-candidate/`) hold
10 frames each; a frame-by-frame comparison is **identical**, and the two
single-sector reads match the reference ISO byte-for-byte. Acceptance
condition met: the reconstruction is a drop-in on the player.

## 2. STANDBY — the daemon survives sleep

With the daemon serving, a single power press (standby):

- port **2002 stayed open** across 5 × 5 s checks while the player was asleep;
- a full capture run **in standby** returned the same ISO-identical frame set;
- wake was **instant** and the appliance UI returned.

So standby pauses the appliance, not the daemon: process and CPSA survive the
sleep transition. (The earlier "2002 closed in standby" observation came from
a boot where the script never ran at all.)

## 3. WHY THE DAEMON KEPT DYING IN 1 s — `compid`, not our code

Every launch (original **and** candidate) died before binding:

```
insmod: can't insert '/tmp/…': Device or resource busy
[0]: install_modules: mknod/insmod filed
rmmod: can't unload 'sacd_read': unknown symbol in module, or unknown parameter
[0]: Can not install modules
```

Probing the extracted blob directly (`insmod sacd_read.ko [minor=201]`) gave
the same **EBUSY (16)** with `/proc/misc` clean and no `sacd_read` loaded.
Disassembling `init_module` decoded the cause (tools, not guesses): the blob
looks up `u4CPSA_Inst_GetInstHandleFromCompId(compid)` and, if a handle
already exists, prints

```
[%s] compid = %d is used. Try another.
```

and returns `-EBUSY` **before `misc_register`**. The module has a `compid`
parameter (`GCPU Compute ID (0-3)`, default 0) — the appliance owns compid 0
on this boot. Passing a free compid loads the module; the daemon then finds it
already operational, validates the device, and serves. This is what made the
candidate trial possible at all, and the stock launch line hides it (no
redirection → the message dies with ipcd's console).

## 4. MTK CLI SCRIPTS ARE TRUNCATED BY LENGTH

A 13-line / 628-byte display AutoScript ran `hwmon_restore` (line 4) and then
**nothing** — no hwmon, no wrapper, no `cyberdraw` process, in three
consecutive triggers. Every script that has ever worked is 9–11 lines /
≤ 454 bytes. The display leg now keeps the proven 9-line shape and is armed by
a flag file (`AutoScript/displayanim`) that `hwmon_restore.sh` acts on.

## 5. THE DISPLAY LEG — raw fbdev loses, the real stack wins

Framebuffer facts from the panel itself (`/proc/fb`: `0 mt8530`;
`/dev/fb0` char 29,0; `/sys/class/graphics/fb0/`): **1920x1080, 32 bpp,
stride 7680, virtual 1920x2160, state 0 (not blanked)**.

- `cyberdraw --static` drew and hashed its own frame:
  `5be59ae255a692ffb0ab197915ce0656` — **nothing appeared on the TV**.
- `fbmd5` (read-only, same region, +2 s): `1656abeafafe88b4b216e300a2b710c5`
  — **different**. Something is actively rewriting `/dev/fb0`; our frame does
  not survive two seconds. `--anim` (45 s, 15 fps) was equally invisible.
- **`dfbhello` — the player's own DirectFB 1.2.7 stack** (`libdirectfb_mtk.so`
  provider → MT85xx image pool) created a primary surface, filled it and
  flipped: **the pattern appeared on the panel for the full 25 s hold.**

**Tier-1 display takeover on real hardware: DEMONSTRATED.** Photo:
`photos/2026-11-04-dfbhello-on-panel.{HEIC,png}` (SHA-256 in
`photos/SHA256SUMS.txt`): teal background, red/green/blue blocks, white frame —
a pattern no appliance UI can produce.

Observed after exit: the panel dropped to a blank background rather than
returning to the appliance UI (operator observation; the log's post-run state
dump is the recorded half). Not yet explained — the appliance may not repaint
after a foreign DirectFB session releases.

A second run with the layout fix (blue block inside the panel, layout taken
from `GetSize`) drew correctly — operator-observed "perfectly framed" — but its
log was lost to H7 (zero-byte write on a full ramfs), so the recorded log is
the first run's (`display-payload/2026-11-04-displaylaunch-hardware.log`).

## Findings this session produced (for the ledger)

| # | Finding | Evidence |
|---|---|---|
| H1 | `sacd_read.ko` fails `-EBUSY` before `misc_register` when the appliance holds its CPSA compid; `compid` 1–3 loads fine | insmod stderr, `init_module` disassembly, `/proc/misc` clean |
| H2 | The stock AutoScript line hides the module-load error (no redirection) → silent 1 s daemon deaths | `candlaunch.log`, exit status 0 |
| H3 | MTK CLI truncates longer scripts (~628 B/13 lines → first 4 lines only) | three triggers with no hwmon/wrapper, 9-line control works |
| H4 | `/dev/fb0` is actively rewritten by another writer (our frame gone in <2 s) | `cyberdraw` md5 vs `fbmd5` md5 |
| H5 | Raw fbdev paint never reaches the panel; the retail DirectFB stack does | TV photo vs identical raw-fbdev attempts |
| H6 | Standby pauses the appliance, not the daemon; 2002 serves while asleep | 5 listener checks + in-standby capture |
| H7 | The player's rw ramfs FILLS across triggers (`/tmp/hwmon-data` never pruned) — after enough triggers both writers produce ZERO-BYTE outputs while the programs still run | `displaylaunch.log` 0 B + `inventory-active-2466.txt` 0 B in one trigger; fixed by pruning `/tmp/hwmon-data` each trigger |

## Reproduce

Payload: `evidence/bx510/display-payload/` (`cyberdraw`, `fbmd5`, `dfbhello`,
`displaylaunch.sh`; SHAs pinned in `tools/sacd_hardware.sh`, build recipes in
`DISPLAY-SPEC.md` and the sources' headers). Stick: `make sacd-usb-display-mode`
proves the arm; the leg runs from `hwmon_restore.sh` on the flag file.

Build notes worth keeping:
- `dfbhello` links the PLAYER's libs (`-L/tmp/rootfs/lib -ldirectfb -ldirect
  -lfusion`) and needs DirectFB 1.2.7 headers **configured** (the tarball's
  `lib/direct/*.h` need the generated `build.h`; run `./configure
  --host=arm-none-linux-gnueabi` once in the source tree).
- Layout must come from `GetSize`, not from the requested size: the first
  build's margins pushed the blue block off the 1920-wide panel (operator
  observation, source fixed; binary re-pinned).

## Honest negatives

- A raw `/dev/fb0` paint is NOT a display path on this device — the cyberdraw
  route is dead for hardware, whatever it proves in the guest.
- The animation never reached the panel even at 15 fps.
- Whether a foreign DirectFB session can coexist with the appliance UI (SaWMan)
  is still untested; this run drew with the UI up and the UI did not return
  afterwards.
