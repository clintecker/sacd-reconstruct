#!/bin/sh
# sr_read_ladder.sh — C103 guest-side READ(10) ladder. MEASURES ONLY.
# Every oracle comparison happens Mac-side (decode/read10_verdict.sh): the guest
# has no copy of the 2 GiB ISO, and the oracles are recorded constants
# (decode/firebird-fixture.md §5).
#
# Two phases, run in two places on purpose (evidence separation):
#   PHASE=pre   legs (a)(a2)(b)(c)(d): capacity, the block layer's own READ(10)
#               via dd, then the CDB-controlled SG_IO oracles and the 2064
#               SG_IO differential (e0). Nothing here involves bdpdrv's SACD
#               ioctl path, so a PASS attributes the bytes to libata/sr/FE.
#   PHASE=post  leg (e), the daemon's own ioctl 0x40105303 path (2064-byte
#               frames via /dev/sacd_read).
#
# ORDERING NOTE (deviation from decode/read10-orchestration.md §6.2): the fire
# script's stages are appended after the whole guest stack (osal_stub_a ->
# drvcli -> osal_stub -> bdpdrv), not spliced before bdpdrv, so PHASE=pre runs
# with bdpdrv already resident. That is harmless for the measurements — they
# are read-only CDB/ioctl probes and bdpdrv does not own /dev/sr0 — but a
# PHASE=pre PASS can no longer be attributed to libata/sr/FE *alone*; it is
# labelled that way in run-c103.md. PHASE=post needs bdpdrv resident anyway.
#
# Output contract (one space-separated field list per line, no padding):
#   SRREAD   mode=size|read10 lba= nsec= len= rc= sense= host= driver= file=
#   SACDREAD cmd=0x401053.. lba= nsec= len= ret= errno= result= file=
#   MD5      name=<label> off=<offset in dump> hash=<md5 of the 2048 B there>
#   MD5      name=<label> off=<offset> hash=<md5 of nsec x 2048 B>  (plain legs)
#   MD5      name=<label> head16=<md5 of the first 16 B>
#   LADDER   <step> PASS|FAIL <detail>   (PASS = the measurement was taken,
#                                         NOT that the md5 matched)
#   LADDER   e MEASURED <detail>         (leg e ran; the verdict keys on this)
#   LADDER   done <measured>/<attempted>
#
# Env: SR0=/dev/sr0  SACD=/dev/sacd_read  HELPER=/res/shim/srread
#      OUT=<dump dir>  PHASE=pre|post  SACD_DIFF=1
SR0=${SR0:-/dev/sr0}
SACD=${SACD:-/dev/sacd_read}
HELPER=${HELPER:-/res/shim/srread}
OUT=${OUT:-/res/c103}
PHASE=${PHASE:-pre}
SACD_DIFF=${SACD_DIFF:-1}
mkdir -p "$OUT"
ok=0; total=0

# hash_at <file> <offset> <len> — byte comparison via md5. This rootfs has
# md5sum, head, dd and shell builtins but NO tail and NO cut (C103 attempt 2:
# 'line 130: cut: not found' => every MD5 line printed an empty hash;
# run-c103.md §6.1: the 2048-byte window used 'tail -c +N' and tail is also
# absent, so the 2048-byte hashes were md5("") too). The digest is lifted with
# POSIX parameter expansion and the byte window with dd bs=1 (exact at these
# sizes; 20480 B costs 20480 read syscalls, seconds inside the emulator).
md5_hex() { _h=$(md5sum); echo "${_h%% *}"; }
hash_at() {
  dd if="$1" bs=1 skip="$2" count="$3" 2>/dev/null | md5_hex
}
# md5_of <label> <file> <offset within the dump> [len] — len defaults to one
# logical sector; the multi-sector rungs hash nsec x 2048 because the recorded
# oracle (firebird-fixture.md §5.1) is the hash of the whole batch, not of its
# first sector.
md5_of() {
  _len=${4:-2048}
  echo "MD5 name=$1 off=$3 hash=$(hash_at "$2" "$3" "$_len")"
}
head16_of() { # head16_of <label> <file> — the 0xbb poison canary
  echo "MD5 name=$1 head16=$(head -c 16 "$2" | md5_hex)"
}
step() { total=$((total + 1)); ok=$((ok + 1)); echo "LADDER $1 PASS $2"; }

# read_one <label> <lba> <nsec> [--sacd] — the helper computes its own byte
# count (2048 x nsec, or 2064 x nsec with --sacd), always prints its SRREAD
# line, and exits non-zero on failure so this `if` sees the verdict.
read_one() {
  if $HELPER read10 "$SR0" "$2" "$3" "$OUT/$1.bin" "$4"; then
    if [ "$4" = "--sacd" ]; then
      i=0
      while [ $i -lt "$3" ]; do
        for d in 0 8 12 16; do
          md5_of "$1" "$OUT/$1.bin" $(( i * 2064 + d ))
        done
        i=$((i + 1))
      done
    else
      md5_of "$1" "$OUT/$1.bin" 0 $(( $3 * 2048 ))
      if [ "$3" = "1" ]; then head16_of "$1" "$OUT/$1.bin"; fi
    fi
    step "$1" "lba=$2 nsec=$3"
  else
    echo "LADDER $1 FAIL lba=$2 nsec=$3"
  fi
}

if [ "$PHASE" != post ]; then
  # ── (a) sr0 present: the block device must report the fixture's capacity ──
  if $HELPER size "$SR0"; then step a "size probed"; else echo "LADDER a FAIL size"; fi

  # ── (a2) the same read with no helper staged: dd through the block layer ──
  # dd's stderr is kept: 'dd failed' with no reason is not a measurement.
  if dd if="$SR0" of="$OUT/lba16.dd.bin" bs=2048 skip=16 count=1 2>"$OUT/dd.err"; then
    md5_of lba16.dd "$OUT/lba16.dd.bin" 0
    step a2 "dd LBA 16"
  else
    echo "LADDER a2 FAIL dd reason=$(head -1 "$OUT/dd.err" 2>/dev/null)"
  fi

  # ── (b)(c)(d) the 2048-byte oracles, CDB-controlled through SG_IO ─────────
  read_one lba16      16      1     # oracle 1: ISO9660 PVD
  read_one lba510     510     1     # oracle 2: SACDMTOC master TOC
  read_one lba532104  532104  1     # oracle 3: mid-disc audio sector
  read_one lba0       0       1     # all-zero sector: the poison control
  read_one lba510x10  510     10    # the daemon's master-TOC batch shape
  read_one lba1064207 1064207 1     # last valid LBA: a read that MUST work
  # past EOF: must FAIL with a sense triple, not return zeros (model row 23) —
  # here success is the failure, so the helper's non-zero exit is the PASS.
  if $HELPER read10 "$SR0" 1064208 1 "$OUT/past_eof.bin"; then
    echo "LADDER past_eof FAIL (LBA 1064208 returned data)"
  else
    step past_eof "rejected"
  fi
fi

if [ "$PHASE" = post ]; then
  # ── (e) the daemon's own path: /dev/sacd_read ioctl 0x40105303, 2064 x n ──
  $HELPER sacdread init "$SACD"
  if $HELPER sacdread read "$SACD" 510 2 "$OUT/sacd510.bin"; then
    for off in 0 4 8 12 16 24 2048 2064 2072 2076 2080 2088; do
      md5_of sacd510 "$OUT/sacd510.bin" $off
    done
    total=$((total + 1)); ok=$((ok + 1))
    echo "LADDER e MEASURED lba=510 nsec=2 len=4128 via ioctl 5303"
    # C105: the framing specimen rides the UART — the tmpfs dies with the
    # guest and /res/c103/sacd510.bin was unrecoverable after C104 (the
    # hashes were measured, the bytes were not). 64 B/line, off-keyed, so the
    # Mac-side decode can reassemble and detect loss.
    $HELPER hex "$OUT/sacd510.bin" sacd510
  else
    echo "LADDER e FAIL ioctl 5303"
  fi
  # ── (e0) differential: the same 2064 framing without sacd_read.ko's ioctl ──
  if [ "$SACD_DIFF" = 1 ]; then
    read_one sacd_sg 510 2 --sacd
  fi
  # ── (f) the decrypt leg: 5304 consumes the framed 5303 output ──────────
  # Level-0 acceptance: the TZ identity transform + the driver's own out+12
  # strip must reproduce the PLAIN ISO bytes for LBA 510+511 (4096 B).
  if [ -f "$OUT/sacd510.bin" ]; then
    if $HELPER sacdread decrypt "$SACD" 510 2 "$OUT/sacd510.bin" "$OUT/sacd510.dec"; then
      md5_of sacd510dec "$OUT/sacd510.dec" 0 4096
      total=$((total + 1)); ok=$((ok + 1))
      echo "LADDER f MEASURED lba=510 nsec=2 decrypt via ioctl 5304"
      $HELPER hex "$OUT/sacd510.dec" sacd510dec
    else
      echo "LADDER f FAIL ioctl 5304"
    fi
  fi
fi

echo "LADDER done $ok/$total"
