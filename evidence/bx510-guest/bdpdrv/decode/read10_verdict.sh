#!/bin/sh
# read10_verdict.sh — post-fire gate for the C103 READ(10) ladder.
# Usage: sh read10_verdict.sh <uart.log> [<mmio.log>] [<meta.json>]
# Exit 0 = PASS, 1 = FAIL (a check broke), 2 = INCOMPLETE (a class never ran).
#
# Contract with the guest ladder (sr_read_ladder.sh + sr_read10 helper), one
# space-separated field list per line, no padding:
#   SRREAD   mode=size|read10 lba=<n> nsec=<n> len=<n> rc=<ret> sense=<6hex> host= driver=
#   SACDREAD cmd=0x401053.. lba=<n> nsec=<n> len=<n> ret=<ioctl ret> errno= result=
#   MD5      name=<label> off=<byte offset in the dump> hash=<md5 of 2048 bytes>
#   MD5      name=<label> head16=<md5 of the first 16 bytes>
#   LADDER   <step> PASS|FAIL <detail>   /   LADDER done <n>/<n>
# This script PRINTS the FRAMING verdict itself (§G) — it is decided here, not
# by the guest, which has no ISO to compare against.
#
# Oracles: decode/firebird-fixture.md §5.1/§5.2 (re-derived twice there);
# canary constants: md5(0xbb x 16) = 698c867c…, md5(0x00 x 16) = 4ae71336….
#
# LC_ALL=C: the UART transcript carries non-UTF8 bytes (boot banners, ANSI
# colour codes); a UTF-8 locale makes sed/awk abort mid-stream.
LC_ALL=C; export LC_ALL
# C104 lesson (run-c104.md): the guest console lines end CRLF, so every
# $-anchored BRE silently missed — oracles that MATCHED byte-for-byte read as
# 0 matches. Normalize once, grep the normalised copy.
U_RAW=${1:?usage: read10_verdict.sh <uart.log> [<mmio.log>] [<meta.json>]}
U=$(mktemp)
tr -d '\r' < "$U_RAW" > "$U"
M=${2:-}
J=${3:-}
STATE=0                      # 0 PASS, 1 FAIL, 2 INCOMPLETE

pass() { echo "PASS  $1  ($2)"; }
bad()  { echo "FAIL  $1  ($2)"; if [ "$STATE" != 2 ]; then STATE=1; fi; }
inc()  { echo "SKIP  $1  ($2)"; if [ "$STATE" = 0 ]; then STATE=2; fi; }

# want <count> <bre> <file> <label>
want() {
  n=$(grep -c "$2" "$3" 2>/dev/null)
  if [ "$n" = "$1" ]; then pass "$4" "$n"; else bad "$4" "want $1, got $n"; fi
}
# want_ge <min> <bre> <file> <label>  — counts an EH retry would legitimately change
want_ge() {
  n=$(grep -c "$2" "$3" 2>/dev/null)
  if [ "$n" -ge "$1" ] 2>/dev/null; then pass "$4" "$n"; else bad "$4" "want >=$1, got $n"; fi
}

# ── A. the run is the run: the disc the model was given is the pinned ISO ───
want 1 '^bx510: SATA ATAPI drive attached: .*firebird\.iso (1064208 sectors)$' "$U" \
     "disc attached (C100-R0)"

# ── B. leg (a): sr0 present. Behavioural, not string-keyed. RECALIBRATED
#       against this rig's FA-mode Sony sr.c (run-c103.md §2 + post-fire trace
#       resolution): the open path is open(2) -> GESN -> straight to READ(10)
#       and READ CAPACITY is NEVER issued (C103 full trace: zero 0x25 posts,
#       zero TURs, one GESN 0x4a). So the guest capacity is get_sectorsize()'s
#       documented fallback (0x1fffff x 512 = 1073741312, blkssz 512) — that
#       is the steady state, not a failure signature. The discriminator that
#       keeps this calibration honest is the want 0 nbytes=8 check below: if a
#       READ CAPACITY packet ever appears, the guest tree changed and B is
#       stale (attack-decay rule). NOTE: errno= sits BETWEEN rc= and
#       blkgetsize64=, so the two are not adjacent.
want_ge 1 '^SRREAD mode=size .* rc=0 errno=[0-9]* blkgetsize64=1073741312 blkssz=512$' "$U" \
     "sr0 capacity + block size (leg a, FA-mode fallback)"

# ── C. no fatal libata signature (qc timeout / EH give-up / SRST) ───────────
want 0 '^ata1\.00: qc timeout'          "$U" "no qc timeout"
want 0 '^ata1: reset failed, giving up' "$U" "no EH give-up"
want 0 '^ata1\.00: SRST failed'         "$U" "no SRST failure"
want 0 '^ata1\.00: failed to IDENTIFY'  "$U" "no failed IDENTIFY"

# ── D. legs (b)(c)(d): the 2048-byte oracles ───────────────────────────────
# D0 first: if the three single-sector reads hash IDENTICALLY, the FE served
# one canned block (the IDENTIFY table) instead of disc bytes — the signature
# of an un-armed READ dispatch, and the reason the oracles are md5s and not
# eyeballed hexdumps.
nh=$(grep -hE '^MD5 name=lba(16|510|532104) off=0 hash=' "$U" 2>/dev/null \
     | sed 's/.*hash=//' | sort -u | grep -c .)
if [ "$nh" = 3 ]; then pass "three distinct payloads (no canned block)" "$nh"
else bad "three distinct payloads (no canned block)" "want 3, got $nh"; fi
want 1 '^MD5 name=lba16 off=0 hash=c117ce4cef54ab625e33583156605721$'      "$U" "oracle LBA 16 (PVD)"
want 1 '^MD5 name=lba510 off=0 hash=e56de1add53c90dd30cf9232b29ddc93$'     "$U" "oracle LBA 510 (SACDMTOC)"
want 1 '^MD5 name=lba532104 off=0 hash=9ed18b47f67232ea972515df65cb6ac5$'  "$U" "oracle LBA 532104 (mid-disc)"
want 1 '^MD5 name=lba510x10 off=0 hash=45ccd7dfbf433a79d28e877d7441677c$'  "$U" "oracle LBA 510 x10 (batch)"
want 1 '^MD5 name=lba1064207 off=0 hash=d1c54ec6c395d7092ce06f04705d33ae$' "$U" "oracle final sector (EOF boundary)"

# ── E. the 0xbb poison canary and the resident-zero control ────────────────
# 0xbb x 16 = 698c867c835081965870124d1b90f66e : a head that still hashes to
# this was never DMA'd (c97-read-path.md §3.3). A zero page is a CORRECT
# answer at LBA 0, so its head must hash to 0x00 x 16 = 4ae71336…, not 0xbb.
want 1 '^MD5 name=lba0 head16=4ae71336e44bf9bf79d2752e234818a5$' "$U" "LBA 0 served as real zeros"
want 0 'head16=698c867c835081965870124d1b90f66e'                  "$U" "0xbb poison in no head bytes"

# ── F. past-EOF must fail loudly (row 23), with a sense triple ─────────────
want 1 '^SRREAD mode=read10 lba=1064208 nsec=1 len=2048 rc=-1 ' "$U" "past-EOF rejected"
want 0 '^SRREAD mode=read10 lba=1064208 nsec=1 len=2048 rc=0 '  "$U" "past-EOF did not 'succeed'"
want 0 '^SRREAD mode=read10 lba=1064208 .* sense=000000'        "$U" "past-EOF carried a sense triple"

# ── G. leg (e): the /dev/sacd_read framing verdict — decided HERE, from the
# guest's measurements (the guest has no ISO to compare against; the Mac does
# not need one either, because the oracles are recorded constants).
O510=e56de1add53c90dd30cf9232b29ddc93      # LBA 510, 2048 logical
O511=68e5b97be9a6db48a3d477d77522d47d      # LBA 511, 2048 logical
h() { grep -h "^MD5 name=sacd510 off=$1 hash=" "$U" 2>/dev/null \
      | sed 's/.*hash=//' | head -1; }
b0_0=$(h 0);  b0_4=$(h 4);  b0_8=$(h 8);  b0_12=$(h 12);  b0_16=$(h 16);  b0_24=$(h 24)
b1_2048=$(h 2048); b1_2064=$(h 2064); b1_2072=$(h 2072); b1_2076=$(h 2076)
want 1 '^SACDREAD cmd=0x40105303 lba=510 nsec=2 len=4128 ret=0' "$U" "ioctl 5303 read succeeded"
want 1 '^LADDER e MEASURED'                                    "$U" "5303 dump + hashes emitted"
want_ge 1 '^LADDER done '                                      "$U" "ladder ran to completion"

LAYOUT=unresolved
if [ "$b0_12" = "$O510" ] && [ "$b1_2076" = "$O511" ]; then
  LAYOUT=payload_at_12_stride_2064
elif [ "$b0_0" = "$O510" ] && [ "$b1_2064" = "$O511" ]; then
  LAYOUT=payload_at_0_stride_2064          # 16 stale/trailing bytes per sector
elif [ "$b0_0" = "$O510" ] && [ "$b1_2048" = "$O511" ]; then
  LAYOUT=payload_at_0_stride_2048          # kernel re-packed, 2064 buffer tail stale
elif [ "$b0_16" = "$O510" ]; then
  LAYOUT=payload_at_16_stride_2064         # DAEMON-MAP's "16-byte header" phrasing
elif [ "$b0_24" = "$O510" ]; then
  LAYOUT=payload_at_24_stride_2064         # mode-2 subheader offset (2352 leak?)
elif [ "$b0_0" = "$O510" ]; then
  LAYOUT=payload_at_0_wrong_stride
fi
echo "FRAMING layout=$LAYOUT (b0:0=$b0_0 4=$b0_4 8=$b0_8 12=$b0_12 16=$b0_16 24=$b0_24 b1:2048=$b1_2048 2064=$b1_2064 2072=$b1_2072 2076=$b1_2076)"
if [ "$LAYOUT" = payload_at_12_stride_2064 ]; then
  pass "framing verdict" "$LAYOUT"
else
  bad "framing verdict" "$LAYOUT (accept is payload_at_12_stride_2064)"
fi

# ── H. model side: the armed descriptor carried THIS transfer ──────────────
if [ -n "$M" ] && [ -f "$M" ]; then
  want_ge 1 '^bx510: MMIO W 05c40c sz4 = 1$'      "$M" "descriptor armed (0x5c40c = 1)"
  want_ge 1 '^bx510: MMIO W 05c404 sz4 = 800$'    "$M" "plain read length 2048"
  want 1    '^bx510: MMIO W 05c404 sz4 = 5000$'   "$M" "batch read length 20480"
  want_ge 1 '^bx510: MMIO W 05c404 sz4 = 1020$'   "$M" "SACD ioctl length 2064x2 = 4128"
  want_ge 1 '^bx510: MMIO W 05c004 sz4 = 28$'     "$M" "CDB[0..3] = READ(10)"
  want_ge 1 '^bx510: MMIO W 05c008 sz4 = fe01$'   "$M" "CDB[4..7] = LBA 0x1FE, big-endian"
  want_ge 1 '^bx510: MMIO W 05c00c sz4 = 980002$' "$M" "CDB[8..11] = nsec 2 + vendor 0x98"
  # B's calibration anchor (see its comment): in this FA-mode tree READ
  # CAPACITY is never issued. A nbytes=8 packet appearing means the guest
  # tree changed — B's fallback-capacity expectation is then stale and the
  # run doc must re-derive it, not silently inherit this gate's PASS.
  want 0    '^bx510: FE PACKET .*nbytes=8 '        "$M" "no READ CAPACITY packet (FA-mode constant)"
else
  inc "model-side MMIO checks" "no mmio log supplied (pass it as \$2)"
fi

if [ -n "$J" ] && [ -f "$J" ]; then
  python3 - "$J" <<'PY'
import json, sys
m = json.load(open(sys.argv[1]))
print("INFO  terminal_marker =", m.get("terminal_marker"))
print("INFO  payload_size    =", m.get("fe_test_data", {}).get("payload_size"))
PY
fi

# record, do not gate: the sr attach printk string is not yet observed in any
# run (C101 reached 'scsi 0:0:0:0: CD-ROM' with sr_mod.ko absent), so the gate
# keys on capacity + a real read and this line is the evidence to promote it.
grep -n 'sr0' "$U" 2>/dev/null | grep -v ':# ' | head -3 | sed 's/^/INFO  attach: /'

case "$STATE" in
  0) echo "READ10_VERDICT=PASS";       exit 0 ;;
  2) echo "READ10_VERDICT=INCOMPLETE"; exit 2 ;;
  *) echo "READ10_VERDICT=FAIL";       exit 1 ;;
esac
