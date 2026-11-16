#!/bin/sh
# bx510_ui_stage.sh — put the rendered guest script INTO the payload tgz.
#
# The guest console truncates a long one-line command mid-word (measured: run
# uiloop3 died at `/bin/sh: slee: not found` ~1200 bytes in, and everything
# after it silently never ran), so the scenario cannot travel as a command —
# it travels as a member of the tgz the fire already stages, and the fire's
# command is the 85-byte `tar -xzf … ; sh /res/shim/<name>`.
#
# This is a repack of the nested tgz on the VM (python3 there, tarfile only),
# so it costs a second and changes exactly one member: shim/<name>.
#
# Usage: sh tools/bx510_ui_stage.sh /tmp/bx510_ui_guest-<runid>.sh
set -eu

REPO=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$REPO"

SCRIPT=${1:?usage: sh tools/bx510_ui_stage.sh <rendered-guest-script>}
[ -f "$SCRIPT" ] || { echo "FATAL: no rendered script at $SCRIPT" >&2; exit 2; }
NAME=$(basename "$SCRIPT")

H="${VM_USER:-aftermath}@${VM_HOST:-192.0.2.10}"
TAM=/tmp/bx510-daemon-payload.tgz

# Same host lock the fire takes: this script rewrites the tgz the fire is about
# to stage, so it must not interleave with another lane's fire or repack.
LOCK=/tmp/bx510-fire.lock
if ! mkdir "$LOCK" 2>/dev/null; then
    echo "REFUSING: another fire holds $LOCK (the tgz is shared state)." >&2
    exit 3
fi
trap 'rmdir "$LOCK" 2>/dev/null || true' EXIT INT TERM

scp -q -o BatchMode=yes -P "${VM_PORT:-2222}" "$SCRIPT" "$H:/tmp/$NAME"
ssh -o BatchMode=yes -p "${VM_PORT:-2222}" "$H" "TAM=$TAM NAME=$NAME python3 -" <<'PY'
import io, os, tarfile
tam, name = os.environ["TAM"], os.environ["NAME"]
src = f"/tmp/{name}"
blob = open(src, "rb").read()
with tarfile.open(tam, "r:gz") as arc:
    members = [(m.name, arc.extractfile(m).read()) for m in arc.getmembers()]
replaced = False
packed = []
for mname, data in members:
    if mname == f"shim/{name}":
        data, replaced = blob, True
    packed.append((mname, data))
if not replaced:
    packed.append((f"shim/{name}", blob))
buf = io.BytesIO()
with tarfile.open(fileobj=buf, mode="w:gz", format=tarfile.USTAR_FORMAT) as arc:
    for mname, data in packed:
        e = tarfile.TarInfo(mname)
        e.size, e.mode = len(data), 0o755
        arc.addfile(e, io.BytesIO(data))
open(tam, "wb").write(buf.getvalue())
print(f"tgz {tam} {len(buf.getvalue())} B, {len(packed)} members "
      f"(shim/{name} {'replaced' if replaced else 'added'})")
PY
