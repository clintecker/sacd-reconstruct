#!/bin/sh
# rig_pull.sh — pull a finished sacd-rig run's artifacts from the VM and run
# the comparison verdicts. Extracted from the sacd-rig make target because a
# make recipe's backslash-continued lines each run in their own shell: the
# RIGDIR/RIGVM variables set on one line were empty on the next, and the tar
# -C "" pulls degraded to "mkdir /: Read-only file system". One shell, one job.
#
# Usage: sh tools/rig_pull.sh [rig-vm-dir]   (default /tmp/sacd-rig)
set -eu
REPO=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$REPO"
RIGVM=${1:-/tmp/sacd-rig}
RIGDIR="$REPO/evidence/qemu-rig/$(date -u +%Y%m%d-%H%M%S)"
mkdir -p "$RIGDIR"

H="${VM_USER:-aftermath}@${VM_HOST:-192.0.2.10}"
SSH="ssh -o BatchMode=yes -p ${VM_PORT:-2222} $H"

for d in capture-orig capture-cand overlap-orig overlap-cand; do
    mkdir -p "$RIGDIR/$d"
    $SSH "tar -C $RIGVM/$d -cf - ." | tar -C "$RIGDIR/$d" -xf -
done
$SSH "for l in daemon-orig.log daemon-cand.log daemon-orig2.log daemon-cand2.log; do tar -C $RIGVM -cf - \$l 2>/dev/null; done" | tar -C "$RIGDIR" -xf - 2>/dev/null || true
echo "evidence: $RIGDIR"

python3 "$REPO/tools/sacd_client.py" compare "$RIGDIR/capture-orig/manifest.json" "$RIGDIR/capture-cand/manifest.json"
python3 "$REPO/tools/sacd_client.py" compare "$RIGDIR/overlap-orig/manifest.json" "$RIGDIR/overlap-cand/manifest.json"
