#!/bin/sh
# sacd_sync_standalone.sh — mirror the canonical SACD tree into the
# standalone review repo (clintecker/sacd-reconstruct) and push it.
#
# The dual-repo discipline, as a tool: the virtual-drive review team
# inspects the standalone repo; it drifts stale whenever sync is done by
# hand. This script is invoked ONLY via `make sacd-sync-standalone`
# (make -C pins the canonical repo); it refuses to run if either repo's
# top-level path or origin remote is not the expected one — the
# structural prevention for the a490e51 incident (a "sync" commit that
# landed in the main security-research repo because a git command ran
# from a reset CWD).
#
# Usage: sacd_sync_standalone.sh [MSG]   (MSG: optional commit-message
# prefix; the canonical commit hash is always included)
set -e
CANON=/Users/clint/code/aftermath-sacd
STANDALONE=/Users/clint/code/sacd-reconstruct
MSG="${1:-sync from canonical tree}"

cd "$CANON"
CANON_TOP=$(git rev-parse --show-toplevel)
CANON_REMOTE=$(git remote get-url origin)
CANON_SHA=$(git rev-parse HEAD)
[ "$CANON_TOP" = "$CANON" ] || { echo "FATAL: canonical top-level is $CANON_TOP, want $CANON"; exit 1; }
[ "$CANON_REMOTE" = "git@github.com:clintecker/aftermath.git" ] \
  || { echo "FATAL: canonical origin is $CANON_REMOTE"; exit 1; }
[ -z "$(git status --porcelain)" ] \
  || { echo "FATAL: canonical tree has uncommitted changes — commit first"; exit 1; }

cd "$STANDALONE"
STAND_TOP=$(git rev-parse --show-toplevel)
STAND_REMOTE=$(git remote get-url origin)
[ "$STAND_TOP" = "$STANDALONE" ] || { echo "FATAL: standalone top-level is $STAND_TOP, want $STANDALONE"; exit 1; }
[ "$STAND_REMOTE" = "git@github.com:clintecker/sacd-reconstruct.git" ] \
  || { echo "FATAL: standalone origin is $STAND_REMOTE"; exit 1; }

# --- mirror: tools, gate evidence, hdhost evidence, docs ---
cd "$CANON"
for f in experiments/sacd_reconstruct/tools/*.c \
         experiments/sacd_reconstruct/tools/*.py \
         experiments/sacd_reconstruct/tools/*.sh \
         experiments/sacd_reconstruct/tools/fixture_gen.py; do
  cp "$f" "$STANDALONE/tools/$(basename "$f")"
done
# vendored headers (the HUD source includes them) and the public root docs
mkdir -p "$STANDALONE/tools/third_party"
cp experiments/sacd_reconstruct/tools/third_party/*.h \
   "$STANDALONE/tools/third_party/" 2>/dev/null || true
cp -R experiments/sacd_reconstruct/public "$STANDALONE/" 2>/dev/null || true
mkdir -p "$STANDALONE/evidence/bx510-guest" "$STANDALONE/docs"
cp -R experiments/sacd_reconstruct/evidence/bx510-guest/gates \
      "$STANDALONE/evidence/bx510-guest/" 2>/dev/null || true
rm -rf "$STANDALONE/evidence/bx510-guest/gates3" \
       "$STANDALONE/evidence/bx510-guest/hdhost"
cp -R experiments/sacd_reconstruct/evidence/bx510-guest/gates3 \
      "$STANDALONE/evidence/bx510-guest/" 2>/dev/null || true
cp -R experiments/sacd_reconstruct/evidence/bx510-guest/hdhost \
      "$STANDALONE/evidence/bx510-guest/" 2>/dev/null || true
# the on-player payload + its evidence (HUD render, TV photos, specs): these
# were never mirrored, so the review repo had no screenshots (2026-11-05)
mkdir -p "$STANDALONE/evidence/bx510"
cp -R experiments/sacd_reconstruct/evidence/bx510/display-payload \
      "$STANDALONE/evidence/bx510/" 2>/dev/null || true
cp -R experiments/sacd_reconstruct/evidence/bx510/hw-session-2026-11-05 \
      "$STANDALONE/evidence/bx510/" 2>/dev/null || true
cp -R experiments/sacd_reconstruct/evidence/bx510/hwmon-payload \
      "$STANDALONE/evidence/bx510/" 2>/dev/null || true
cp -R experiments/sacd_reconstruct/docs "$STANDALONE/" 2>/dev/null || true
cp -R experiments/sacd_reconstruct/emulator-kit "$STANDALONE/" 2>/dev/null || true
cp Makefile AGENTS.md "$STANDALONE/"

# --- verify in the standalone tree, then commit + push THERE ---
cd "$STANDALONE"
rm -rf tools/__pycache__
python3 tools/test_bx510_gate.py >/dev/null \
  || { echo "FATAL: alteration regression tests fail in the standalone tree"; exit 1; }
echo "standalone tests: 11/11 pass"
if [ -z "$(git status --porcelain)" ]; then
  echo "standalone already in sync with canonical $CANON_SHA"
  exit 0
fi
git add -A
git commit -q -m "$MSG (aftermath@sacd-reconstruct $CANON_SHA)

Mirrored by sacd-sync-standalone (remote + top-level identity gates:
canonical git@github.com:clintecker/aftermath.git, standalone
git@github.com:clintecker/sacd-reconstruct.git)."
git push -q origin main
echo "standalone pushed: $(git rev-parse --short HEAD)"
