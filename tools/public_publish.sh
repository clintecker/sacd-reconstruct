#!/bin/sh
# public_publish.sh — refresh the PUBLIC branch of the standalone repo.
#
#   staging branch (main locally)  --public_tree.py-->  public branch
#
# Sony binaries, big fixtures and internal docs never enter `public`; text is
# scrubbed and images are re-encoded EXIF-free (see tools/public_tree.py).
# The audit runs first: a tree that leaks anything does not get published.
set -eu
STANDALONE=${STANDALONE:-/Users/clint/code/sacd-reconstruct}
HERE="$(cd "$(dirname "$0")" && pwd)"
MSG=${MSG:-"public: refresh from staging"}

cd "$STANDALONE"
git checkout -q main
git pull -q --ff-only origin main 2>/dev/null || true

TMP=$(mktemp -d)
python3 "$HERE/public_tree.py" --src "$STANDALONE" --dest "$TMP"
rm -rf "$TMP/.git"

# gate: no leaks, no oversized blobs, no Sony binaries beyond the font
cd "$TMP"
git init -q .
git add -A
python3 "$HERE/audit_public.py" . || { echo "AUDIT FAILED — not publishing"; exit 1; }

cd "$STANDALONE"
git checkout -q public
find . -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
rsync -a --exclude '.git' "$TMP/" .
git add -A
if [ -z "$(git status --porcelain)" ]; then
    echo "public already current"
else
    git commit -q -m "$MSG"
    git push -q origin public
    echo "public pushed: $(git rev-parse --short HEAD) ($(git ls-files | wc -l | tr -d ' ') files)"
fi
git checkout -q main
rm -rf "$TMP"
