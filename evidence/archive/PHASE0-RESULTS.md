# Phase 0/2 results — the daemon and its real kernel module inside the full-system guest

Date: 2026-11-03. Rig: lab VM (`make sacd-emu-build` QEMU sony-bx510,
Sony kernel 2.6.35 from the M15.R.0257 NAND), probe
`tools/bx510_phase0_probe.py` (observe-driven, marker-split to defeat the
shell's command echo), artifacts `/tmp/p0v*-uart.log`, `p0v*-probe.out`
on the VM; unimp baseline: 29 unique MMIO lines, all boot-time.

## Guest environment facts (all new, all Sony-image facts)

- The squashfs root has **no /proc, /dev, /sys, /mnt, /tmp**. A real
  player's entire VFS skeleton comes from the initramfs (the same
  initrd_1 we cannot yet unpack). Minimal `init=/bin/sh` boots must
  create everything under `/res` (tmpfs) — the only standard mountpoint
  that exists is `/res`.
- Sony's `/bin/sh` aborts every background job at `/dev/null` open, so
  daemons must be started via a fork-exec wrapper (`tools/bx510_bgstart.c`).
- Sony's `/bin/mknod` is statically linked → LD_PRELOAD does not reach
  it; `/sbin/insmod` is dynamic and honors it.
- `ls -ld /tmp` → absent; `tmpnam()` therefore fails (glibc tmpnam
  ignores TMPDIR: `__path_search(..., try_tmpdir=0)` in glibc 2.9
  sources) leaving `strcpy(mod_file,"/tmp/")` → open EISDIR. The shim
  (`tools/bx510_tmpredir.c`) provides tmpnam + /tmp→/res/tmp and
  /dev→/res/dev redirects at the libc boundary. mknod without S_IFCHR
  creates a REGULAR file (vfs_mknod falls back to vfs_create) — the node
  must be created with S_IFCHR|0666 (bgstart).

## P1 — does the daemon serve in the guest? YES (server path), with the gate still to pass honestly

With install bypassed by the accidental regular-file node, the daemon
ran its full server path inside Sony's OS: LISTEN on 00000000:07D2 in
/proc/net/tcp (state 0A) and the genuine status loop:

    SACD Daemon 0.37 active. Client none. Tray is empty.

pthread create/bind/listen/status all work under Sony's kernel. With the
S_IFCHR node (honest gate) install fails and the daemon correctly
refuses to serve — so honest serving requires the module to load (below).

## P2 — the real module: dependency chain walked, contract pinned

- sacd_read.ko (embedded, extracted; vermagic `2.6.35 preempt mod_unload
  ARMv6`, **no __versions → CONFIG_MODVERSIONS off**, name-only binding)
  imports exactly one non-kernel symbol: **x_memset**.
- The full module dependency graph of /lib/modules/2.6.35/BDP computed
  offline (nm bipartite graph): load order drvcli → kmem → osai →
  drvuart/cbagent/rm → bdpdrv; but the chain's base (`UTIL_Printf`,
  `SYS_Printf`, `Assert`, `get_dynamic_memory`...) is defined by NO
  module in the squashfs → the OSAL base lives in the initramfs.
  hst_*.ko are the Atheros WiFi stack (wmi_*), not OSAL.
- **osai_mini stub** (`tools/bx510_osai_mini.c`, built against Sony's
  GPL linux-2.6.35 drop + mediatek_defconfig, SMP off, -march=armv6,
  vermagic token patched ARMv7→ARMv6 same-length in .modinfo):
  `this_module` size **0x148 exact match** with every Sony module
  (struct module layout proven), x_memset instruction-identical to
  osai.ko's own. Loaded Live in the guest first try.
- With x_memset provided, the daemon's own insmod of the REAL
  sacd_read.ko **passed symbol resolution and its init executed**:
  init resolves **16 symbols via kallsyms_lookup_name** (loose coupling
  into the bdpdrv stack) and returns **-EFAULT if any is NULL** — the
  observed "insmod: Bad address". 9 are missing (all bdpdrv functions):

      u4CPSA_Inst_GetInstHandleFromCompId, i4CPSA_Inst_Connect,
      i4CPSA_Inst_Disconnect, vSacdDecryptEnable, _SACDCLI_TestPhy,
      eSacdGetVersion, _SACDCLI_FindTag, _IDECLI_OddTestUnitReadyLoop,
      _IDECLI_OddGetProfile

  (`__ksymtab_disable_print` was found in the kernel — used to silence
  bdpdrv's printk). After the lookups, init calls the first-resolved
  function with the `minor` module param (201), expects **-1 as its
  success sentinel**, then misc_register's minor 201.
- The module itself CONTAINS `CPSA_SACDCmdDecrypt`, `CPSA_SACDCmdEnable/
  Disable/SetCtrl` and its own `_IDECLI_OddRead` raw-2064-frame path
  (per the handoff's optical disassembly) — the kallsyms symbols are the
  stack glue above it.

## The super-right path, now concrete

`kallsyms_lookup_name` also searches loaded modules' symbol tables, so a
"bdpvirt" provider module defining the 9 missing symbols satisfies the
lookup — in kernel space, exactly at the seam the Phase-2 design wanted.
Behavior contract to derive from bdpdrv.ko (unstripped, 8 MB, local in
BX510-Inputs) per function; `_SACDCLI_TestPhy(201)` must return -1.
After init completes: misc_register(201) → daemon's open("/dev/sacd_read")
succeeds against the REAL module → honest serving → ioctl READ/DECRYPT
run the module's own code path (raw 2064-byte frames) → hardware-facing
probes appear in the QEMU unimp log → iterate sony-bx510.c stubs from
there. The qemu-user rig (raw-frame contract, offset-12 packing) remains
the reference for what those paths must produce.

## Verdict

- P1: **server path proven in-guest** (bind/listen/status); honest
  module-gated serving pending the 9-symbol provider.
- P2: **module executes in-guest past symbol resolution**; its full
  runtime dependency contract is now pinned with disassembly evidence.

## Update (later same day): FULL HONEST CHAIN COMPLETE

After three decoded gates, the daemon now serves in Sony's guest OS with
the REAL kernel module loaded:

    sacd_read 4976 1 - Live 0xbf006000
    bx510_bdpvirt 3844 1 sacd_read, Live 0xbf000000
    0: 00000000:07D2 00000000:0000 0A   (LISTEN 2002)

Evidence: p0v12-uart.log (full transcript), daemon.out contains only the
harmless static-mknod error (node pre-created by bgstart).

Gates decoded along the way (all from live behavior + disassembly):

1. **kallsyms table**: all 13 bdpdrv names resolved from the bdpvirt
   provider module (kallsyms_lookup_name searches loaded modules'
   symtabs — the seam works exactly as designed).
2. **Sony kernel off-by-one (new hardware-behavior fact)**: 2.6.35's
   layout_symtab/add_kallsyms run `for (ndst = i = 1; i < nsrc; ++i,
   ++src)` with src starting at index 0 — they examine entries 0..nsrc-2
   and DROP the LAST symtab entry of every loaded module from kallsyms.
   Observed live: eSacdGetVersion (readelf index 113 = final entry)
   vanished; /proc/kallsyms on real players loses bdpdrv's own last
   symbol the same way. Fix: bdpswap.py swaps a sacrificial tail marker
   into the final symtab slot post-link (symtab order is semantically
   neutral; no duplicate names).
3. **Init gate semantics**: init calls u4CPSA_Inst_GetInstHandleFromCompId
   with the module's compid param (0 when the daemon insmods with only
   minor=201) and requires **-1** ("compid free") to proceed to
   misc_register; any other value prints "compid = %d is used. Try
   another." and fails -EBUSY.

Current bdpvirt behavior contract (tools/bx510_bdpvirt.c):
  - x_memset: full implementation.
  - GetInstHandleFromCompId: -1 (compid free).
  - CPSMode_Ctrl: -1 (observed called with compid at init; keep -1).
  - _IDECLI_OddRead / _i4CPSA_Inst_Decrypt: honest failure (-1) until
    the virtual ODD exists — the daemon will report read errors, never
    fabricated data.
  - others: benign presence stubs (0) — contracts to be derived from
    bdpdrv.ko as each is exercised by real ioctl traffic.

Remaining ladder:
  1. In-guest static client (port sacd_client.py's nanopb wire format to
     C, run over 127.0.0.1:2002) → full-protocol differential inside the
     real guest OS, original vs release daemon.
  2. Virtual ODD: implement _IDECLI_OddRead (+ decrypt path) in bdpvirt
     against a backing ISO serving raw 2064-byte frames — then the daemon
     serves real sector data through the real module end to end.

## FINAL UPDATE (same day): FULL END-TO-END PROTOCOL IN THE GUEST — with two real findings

The complete chain now works inside Sony's guest OS:

    client (loopback) -> daemon -> ScarletBook validators -> REAL sacd_read.ko
    -> bdpvirt virtual ODD -> raw 2064-byte frames -> decrypt-pack -> wire

v36 transcript (p0v36-uart.log):

    GC: connected 127.0.0.1:2002
    GC: OPEN  -> type=1 result=0
    GC: SIZE  -> type=4 result=86200 (sectors)
    GC: READ lsn=0 cnt=1     -> type=3 result=1 datalen=2048
    GC: data[0..15]: e7 c2 04 c3 2b e6 59 30 c5 8c 0c 9f 6f 5a 11 dc
    GC: READ lsn=43100 cnt=1 -> type=3 result=1 datalen=2048
    GC: CLOSE -> type=2 result=0
    GC: post-close read -> 0 (EOF)          <- daemon closes after DISC_CLOSE
    GC: DONE

data[0..15] is BYTE-IDENTICAL to the fixture's synthetic(0) logical sector
(verified by regeneration), proving the payload path end to end.

### Finding 1 (latent fixture bug caught by the third leg):
The original daemon's master-TOC validator failed reserved06 with the
year bytes in it. Root cause: fixture_gen.py (and its C port) used
20-byte genre arrays (5-byte genre_table_t), but the real struct uses
4-byte genre_table_t (category u8 + reserved u16 + genre u8) — confirmed
against the real Firebird disc: year at 120-123, text_area_count at 128,
reserved06 at 129-136, locales at 136-168. The qemu-user rig NEVER caught
this because both binaries failed OPEN identically — equal failures
compare identical. The full-system guest exposed it via the daemon's
own validator. Both generators fixed (master TOC = 168 bytes, + the
required 'SACD_Man' block at LSN 519 — the validator's silent final
check, also real-disc confirmed).

### Finding 2 (client port bug, mine):
My in-guest C client's protobuf parser mis-consumed the data field (used
the pre-varint position), making GOOD daemon frames look corrupt. The
daemon was correct all along; raw-byte logging (gc-raw.bin) proved the
frames were perfect: 08 03 10 01 1a 80 10 + 2048 + 00.

### Session bugs fixed along the way (all documented in source):
- guest UART line length (~62 chars safe; long lines garble via the
  64-byte ring), observe marker-in-echo trip, stale-probe-copy runs,
  non-idempotent patch scripts, implicit-isb from asm/uaccess.h (use
  kernel_read's internal set_fs instead), static-binary partition limits.

### Rig seam inventory (what stands between this and hardware truth):
- bdpvirt: 13 kallsyms-provided bdpdrv functions (contracts decoded for
  GetInstHandleFromCompId, CPSMode_Ctrl, Connect, OddRead(=implemented),
  Inst_Decrypt(=verbatim copy), TestUnitReadyLoop, GetProfile; the rest
  are presence stubs until traffic exercises them).
- The virtual ODD serves plaintext fixtures only; real CPSA decrypt
  output remains the on-player pair capture's ground truth.
- Remaining next rung: the in-guest DIFFERENTIAL — same session against
  the release candidate, transcript-for-transcript.

## THE COMBINED MILESTONE (agreed with the virtual-drive team): in-guest differential — IDENTICAL

Both pinned ELFs ran the complete guest session — each loading its own
real embedded sacd_read.ko through its own install path, against the same
ISO-backed fixture, inside Sony's kernel and libc:

    original  0fdcefdb84ae818b...  -> transcript-orig.txt
    release   e91720fbbbd59250...  -> transcript-rel.txt
    diff -> TRANSCRIPTS: IDENTICAL (17 steps each, payload hashes equal)

Steps covered: OPEN=0, SIZE=86200, 1-sector reads (byte-verified logical
payloads), 128-sector read (result=128, 262144 bytes), encryption-boundary
clamp (79990/20 -> result=10 exactly per the daemon's boundary logic),
encrypted-range read (80000/2 -> decrypt path fired, mock plaintext),
beyond-EOF (graceful result=0), CLOSE=0, post-close EOF, reconnect after
1s (OPEN#2/READ#2/CLOSE#2 all clean).

This is the fourth verification dimension for the release decision:
  1. sacd-verify: clean build + 388/390 fn + interface + pool audit
  2. sacd-rig: qemu-user protocol replay, both replays IDENTICAL
  3. sacd-emu-*: guest execution (--help identical) + THIS differential
  4. pending: hardware baseline + pair capture (the only ground truth
     for real CPSA decrypt output)
