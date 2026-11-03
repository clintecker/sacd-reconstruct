#!/bin/sh
# rig_run.sh — QEMU protocol rig driver (issue #5).
#
# Runs the daemon (original and release candidate) under qemu-arm-static
# with the sacd_rig.so device layer, then replays the identical client
# sequence against both and compares the transcripts.
#
# Usage: sh tools/rig_run.sh <original.elf> <candidate.elf> <out-dir> [disc]
#        disc: optional real ISO image (e.g. a Scarlet Book rip) used as
#        the device fixture; defaults to the synthetic fixture generated
#        by tools/fixture_gen.py.
set -eu
DISC=${4:-}

ORIG=${1:?original elf}
CAND=${2:?candidate elf}
OUT=${3:?output dir}
HERE=$(cd "$(dirname "$0")" && pwd)
CSROOT=${CSROOT:-$HOME/arm-2009q3/arm-none-linux-gnueabi/libc}
CC=${CC:-$HOME/gnuarm/bin/arm-none-linux-gnueabi-gcc}
PY=${PY:-python3}
PORT=${PORT:-2002}
# The listener binds $PORT HARDCODED (daemon source; the original behaves
# identically) and sets no SO_REUSEADDR, so the second leg's bind hits the
# first leg's TIME_WAIT sockets with EADDRINUSE. Wait for the port to clear
# between legs (recorded in DELTA.md: a fast daemon restart on the player
# would fail to bind for the same reason).
wait_port_free() {
    i=0
    while ss -tan 2>/dev/null | grep ":$PORT " | grep -qE "TIME-WAIT|LISTEN|ESTAB"; do
        i=$((i+1))
        [ $i -gt 150 ] && return 1
        sleep 1
    done
    return 0
}

mkdir -p "$OUT"
RIG_SO="$OUT/sacd_rig.so"

# hygiene: a wedged daemon from an aborted run holds port 2002 and makes
# the next listener-wait time out (hit twice before codifying)
pkill -f "qemu-arm-static.*sacd" 2>/dev/null || true
sleep 1
wait_port_free || { echo "port $PORT not free even after stale daemons died"; exit 1; }
DEVFILE="$OUT/rig_dev"

echo "--- building rig DSO (ARM)"
"$CC" -O2 -fPIC -shared -o "$RIG_SO" "$HERE/qemu_rig.c" -I"$HERE" -ldl

if [ -n "$DISC" ]; then
    echo "--- real disc fixture: $DISC"
    DEVFILE="$DISC"
else
    echo "--- synthetic fixture disc"
    $PY "$HERE/fixture_gen.py" "$DEVFILE"
fi

run_daemon() {
    elf=$1; tag=$2; port=$3
    qemu-arm-static -L "$CSROOT" \
        -E LD_PRELOAD="$RIG_SO" -E RIG_DEVFILE="$DEVFILE" \
        -E LANG=C -E LC_ALL=C \
        "$elf" -S > "$OUT/daemon-$tag.log" 2>&1 &
    DPID=$!
    # wait for the listener
    i=0
    while ! nc -z 127.0.0.1 "$port" 2>/dev/null; do
        i=$((i+1))
        [ $i -gt 50 ] && { echo "listener never came up for $tag"; kill $DPID 2>/dev/null || true; return 1; }
        sleep 0.2
    done
    sleep 0.5
    return 0
}

stop_daemon() {
    kill "$1" 2>/dev/null || true
    wait "$1" 2>/dev/null || true
}

echo "=== original daemon under rig (port $PORT)"
run_daemon "$ORIG" orig "$PORT"
$PY "$HERE/sacd_client.py" capture --host 127.0.0.1 --port "$PORT" \
    --out "$OUT/capture-orig" --label orig-rig \
    --firmware "qemu-rig" --disc-id "rig-fixture" || { stop_daemon $DPID; exit 1; }
stop_daemon $DPID
wait_port_free || { echo "port $PORT stuck in TIME_WAIT past 150s"; exit 1; }

echo "=== release candidate under rig (port $PORT)"
run_daemon "$CAND" cand "$PORT"
$PY "$HERE/sacd_client.py" capture --host 127.0.0.1 --port "$PORT" \
    --out "$OUT/capture-cand" --label cand-rig \
    --firmware "qemu-rig" --disc-id "rig-fixture" || { stop_daemon $DPID; exit 1; }
stop_daemon $DPID

echo "=== comparing"
$PY "$HERE/sacd_client.py" compare \
    "$OUT/capture-orig/manifest.json" "$OUT/capture-cand/manifest.json"
