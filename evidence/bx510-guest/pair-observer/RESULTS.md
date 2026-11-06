# Pair-observer guest reproduction — the silent hardware miss does NOT reproduce against the real stack in QEMU

Date: 2026-11-04. Rig: lab VM (`~/bx510-emu/emulator`, QEMU sony-bx510,
Sony kernel 2.6.35, squashfs root), harness
`tools/bx510_pair_repro.py` (new; modeled on `tools/bx510_phase0_probe.py`,
which is NOT modified), in-guest client `tools/bx510_guest_client.c` with a
new additive `pair` argv mode (count-2 reads at arbitrary decimal LSNs,
built with the gnuarm toolchain exactly as gate2 builds it).
Transcripts: `runA.log`–`runD.log` in this directory (full UART; markers
`PR_*`, `PAIR_REPRO_DONE`).

Question: on real hardware (2026-11-03 session) the LD_PRELOAD pair
observer `bx510_pair.so` never wrote its 8,240-byte pair file, although the
daemon served a count-2 read at the armed LSN 600 perfectly through the
preload. The observer was only ever tested against a SYNTHETIC lower ioctl
provider. Does the miss reproduce when the REAL embedded `sacd_read.ko`
module + the REAL original daemon run (the QEMU guest combination)?

## Answer: NO — the observer fires correctly against the real module.

Four boots, one condition each. Daemon = pinned original
(SHA-256 `0fdcefdb…cddb45`), module = the daemon's own embedded
`sacd_read.ko` insmod'd by the daemon itself (Live in `/proc/modules`,
`bx510_bdpvirt` provider), fixture = 86,200 sectors, encrypted track range
80000–86000, area TOC at LSN 600 (`bx510_mkfixture.c`). Client reads were
count 2 — the observer's `SECTORS`.

| Run | Preload | Armed LSN | Reads | Pair file | Verdict |
|---|---|---|---|---|---|
| A (control) | none | — | 80000, 600 | — (by design) | both reads serve: `result=2 datalen=4096`, fnv1a64 `a4903e500a141a95` / `534721fbb717bcaa` |
| B | `bx510_pair.so` (prebuilt) | 80000 | 80000, 600 | **PRESENT** | header `BX5PAIR1`+lsn 80000+count 2; wire service byte-identical to control (same fnv hashes) |
| C | `bx510_pair_dbg.so` (debug build) | 80000 | 80000, 600 | **PRESENT, 8,240 bytes, mode 0600** | ioctl log: READ match=1 → SAVE ok → DECRYPT, same worker tid 527, same buffer |
| D | `bx510_pair_dbg.so` | **600** (hardware's LSN) | 600, 80000 | **PRESENT, 8,240 bytes** | header `BX5PAIR1`+lsn 600+count 2 — exact hardware conditions, observer fires |

Run D is the direct hardware-condition replay: armed at LSN 600, a
successful count-2 read at 600 → pair file written. Run C's instrumented
log (the naming instrument, `/res/pairlog` dumped into the transcript):

```
tid=512 CFG armed=1 lsn=600 out=/res/pairtest
tid=527 RD fd=11 rc=0 in[lsn=600 cnt=2 buf=0x411ea008] post[res=0 lsn=600 cnt=2 buf=0xc600c000] want_lsn=600 match=1 pending=0x7f320 pbuf=0x411ea008
tid=527 SAVE ok lsn=600 bytes=8240
tid=527 DC fd=11 rc=0 in[cnt=2 buf=0x411ea008] post[res=0 cnt=2 buf=0xc600c000] match=1 pbuf=0x411ea008
```

Facts named by the instrument (all demonstrated, none inferred):

1. The real module REPLACES `arg->buf` on return (`post buf=0xc600c000`,
   a kernel-mapped address) — exactly why the observer saves caller
   fields before forwarding; the saved pointer (`0x411ea008`) is what
   matches between READ and DECRYPT. Handled correctly.
2. READ and DECRYPT run on the SAME worker thread (tid 527, vs daemon
   main tid 512) with the SAME user buffer pointer. Handled correctly.
3. The daemon issues SACD_IOC_DECRYPT after EVERY count-2 read, in the
   unencrypted region too (LSN 600 read is followed by a DC ioctl — run
   C shows it for 600 while armed at 80000). The "daemon skips decrypt
   outside the encrypted range" hypothesis is refuted; the guest miss
   mechanism for LSN 600 does not exist.
4. Pass-through is transparent: with the observer preloaded, the wire
   payloads are byte-identical to the no-preload control (identical
   fnv1a64 for both LSNs, runs A vs B).
5. The prebuilt `bx510_pair.so` (the exact binary staged to the hardware
   USB stick) loads and works under the guest's vintage dynamic loader
   together with `tmpredir.so` in one `LD_PRELOAD`.

## What this means for the hardware miss

Everything the observer needs was demonstrated live against the real
module + real daemon: arming, request codes, count==2, buffer-pointer
match across the replaced `arg->buf`, same-thread READ→DECRYPT ordering,
O_EXCL save of a fresh 8,240-byte file. The hardware failure is therefore
NOT an observer-logic mismatch with the real stack. The remaining
hardware-side candidates, in order of plausibility:

- **The observer was never armed in the daemon process on hardware** —
  LD_PRELOAD load failure or env loss through the player's AutoScript →
  `trace-launch.sh` chain is SILENT by design: an unloaded preload and a
  transparent preload both yield identical wire service, so last night's
  "served perfectly through the preload" observation does NOT prove the
  preload was active. Discriminating evidence that may already exist:
  the hardware session's captured console (teed into `~/bx510-session`)
  would contain `ld.so: object … cannot be loaded` if loading failed.
- **Arming check failure** (`program_invocation_short_name` or
  `BX510_PAIR_*` env not surviving the launch chain) — same silence.
- Hardware module/firmware version differences — weakest: the daemon
  insmods its own embedded module, and the daemon binary is the same
  pinned original.

## Queued (hardware session follow-ups, not done here)

1. Inspect the hardware session console logs for an ld.so load-failure
   line at daemon start.
2. Re-run the hardware pair capture with `bx510_pair_dbg.so` (this
   directory; built with the guest rootfs libs + the
   `optical/build_trace.sh` link recipe, see below) and
   `BX510_PAIR_LOG=<usb path>` — the debug build makes every silent
   failure speak: arming decision + every READ/DECRYPT + save outcome.
   The guest proves the debug .so behaves identically to the original
   (same pair file, same pass-through).

## Reproduction

Debug observer build (no Zig on the VM; gnuarm gcc 4.4 needs
`-std=gnu99` and a typedef-array assert instead of `_Static_assert`;
GNU ld's default segment layout replaces lld's `--no-rosegment`,
`rel-arm.ld` keeps `.rel.dyn`/`.rel.plt` contiguous for the vintage
loader — verified adjacent in the built .so):

```sh
cd /tmp/pairrepro   # staged: tools/bx510_pair_debug.c, optical/ioctl_arm.S, optical/rel-arm.ld
export PATH=/home/aftermath/gnuarm/bin:$PATH
arm-none-linux-gnueabi-gcc -mcpu=arm1176jzf-s -marm -mfloat-abi=soft -O2 -fPIC \
    -fno-stack-protector -std=gnu99 -Wall -Wextra -Werror -c bx510_pair_debug.c -o debug.o
arm-none-linux-gnueabi-gcc -mcpu=arm1176jzf-s -marm -c ioctl_arm.S -o ioctl.o
arm-none-linux-gnueabi-ld -m armelf_linux_eabi -shared -soname bx510_pair_dbg.so \
    --as-needed --hash-style=both -z now -z defs -z noexecstack -z max-page-size=4096 \
    -T rel-arm.ld -o bx510_pair_dbg.so debug.o ioctl.o \
    /tmp/rootfs/lib/libdl.so.2 /tmp/rootfs/lib/libpthread.so.0 \
    /tmp/rootfs/lib/libc.so.6 /tmp/rootfs/lib/libgcc_s.so.1
# guest client (additive pair mode):
arm-none-linux-gnueabi-gcc -O2 -Wall -std=gnu99 -o gclient tools/bx510_guest_client.c
```

Harness (run from `~/bx510-emu/emulator`, four boots = control, prebuilt
armed 80000, debug armed 80000, debug armed 600):

```sh
python3 bx510_pair_repro.py --qemu work/build/qemu-system-arm --images ../images \
  --reference /home/aftermath/sacd-verify/original/sacd_extract_160 \
  --shim /tmp/tmpredir.so --bgstart /tmp/bgstart --stub /tmp/mod/bx510_bdpvirt.ko \
  --mkfixture /tmp/mkfixture --gclient /tmp/pairrepro/gclient --lo_up /tmp/lo_up \
  --pair-so none|/tmp/pairrepro/bx510_pair.so|/tmp/pairrepro/bx510_pair_dbg.so \
  --arm-lsn N --read-lsns 80000,600 [--pair-log] --timeout 900 --log /tmp/pairrepro/runX.log
```

VM run directory `/tmp/pairrepro` (fresh name; nothing prior overwritten).
Note: the guest busybox has no `wc`, so the pair-file size check in the
transcript is `ls -l` (8240 seen in runs C and D).

## Honesty ledger

- Demonstrated: everything above, from four full UART transcripts.
- Refuted (in the guest): "daemon skips DECRYPT for unencrypted LSNs";
  "observer cannot match the real module's buf replacement"; "observer
  cannot pair READ/DECRYPT on the real daemon's worker threads";
  "the miss reproduces in the guest at the hardware LSN".
- Inferred (labeled): the hardware miss cause is a hardware-session
  condition (most plausibly silent preload non-arming), NOT observer
  logic — inferred from the guest negatives plus the observer's
  silent-by-design failure modes; the discriminating evidence (hardware
  console, debug-observer hardware rerun) is queued, not yet collected.
- Not claimed: any fix. The debug observer is the instrument, not a fix.
