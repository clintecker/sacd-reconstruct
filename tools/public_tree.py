#!/usr/bin/env python3
"""public_tree.py — assemble the PUBLIC tree for the standalone repo.

Every file is either INCLUDED, EXCLUDED (with a reason) or SCRUBBED; the result
is written to --dest together with PUBLIC-MANIFEST.txt recording, per file:
destination path, bytes, sha256, class and action. Deterministic: same repo
state in, byte-identical tree out.

Policy (why each rule exists):
  Sony binaries          excluded -- we do not redistribute Sony's daemon, their
                         kernel module or the firmware; PROVENANCE.md records
                         their SHA-256 so a reader can verify against their own
                         device.
  >1 MiB test images     excluded -- regenerable from the shipped generator;
                         150 MB of NAND images does not belong in a git repo.
  big logs / raw dumps   excluded -- regenerable, and they carry LAN addresses.
  photos                 HEIC -> PNG (EXIF-free); HEIC originals dropped.
  text                   identifiers scrubbed: IPv4 -> RFC-5737 documentation
                         addresses, MAC -> aa:bb:cc:00:11:22, /Users/<name> ->
                         /Users/you, player hostname -> player.local.
  incoming/              excluded -- third-party team packages, not ours to
                         publish.
  analysis/              excluded -- regenerable from the scripts; see
                         docs/REPRODUCE.md.
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys

BIG = 1024 * 1024

# ---- include/exclude rules, in order (first match wins) --------------------
RULES = [
    # (regex, action, reason)
    (r"^original/", "exclude", "Sony binary (sha recorded in PROVENANCE.md)"),
    (r"/sacd_read\.ko$", "exclude", "Sony kernel module"),
    (r"^incoming/", "exclude", "third-party team package"),
    (r"^analysis/", "exclude", "regenerable disassembly dumps"),
    (r"^AGENTS\.md$", "exclude", "internal process/policy doc"),
    (r"^NOTES\.md$", "exclude", "internal session notes"),
    (r"^RESEARCH-BRIEF\.md$", "exclude", "internal brief"),
    (r"^evidence/.+\.(bin|img|iso|o|a)$", "exclude", "regenerable binary fixture"),
    (r"^evidence/.+\.HEIC$", "exclude", "HEIC original (PNG copy is included)"),
    (r"^evidence/.+\.ppm$", "exclude", "regenerable raw capture (PNG is included)"),
    (r"^public/", "include", "public root docs"),
    (r"^(docs|reconstruct|tools|emulator-kit|gccbuild|emulator-handoff)/", "include", "ours"),
    (r"^DELTA\.md$", "scrub", "reconstruction delta, identifiers scrubbed"),
    (r"^Makefile$", "scrub", "build targets, identifiers scrubbed"),
    (r"^evidence/.+", "include", "evidence (logs filtered by size below)"),
]

SCRUB = [
    (re.compile(r"\b10\.\d{1,3}\.\d{1,3}\.\d{1,3}\b"), "192.0.2.10"),   # RFC5737 TEST-NET-1
    (re.compile(r"\b192\.168\.\d{1,3}\.\d{1,3}\b"), "192.0.2.11"),
    (re.compile(r"\b172\.(1[6-9]|2\d|3[01])\.\d{1,3}\.\d{1,3}\b"), "192.0.2.12"),
    (re.compile(r"\b([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}\b"), "aa:bb:cc:00:11:22"),
    (re.compile(r"/Users/[A-Za-z0-9._-]+"), "/Users/you"),
    (re.compile(r"\bbx510-emulator\b"), "player.local"),
    # internal names -> reader-friendly equivalents
    (re.compile(r"\blab VM\b", re.I), "build host"),
    (re.compile(r"\bsacd-verify\b"), "the verification tree"),
    (re.compile(r"\bsacd-enhanced\b"), "the repaired tree"),
    (re.compile(r"\bsubagent\b", re.I), "helper process"),
    (re.compile(r"\bthe team\b", re.I), "the maintainers"),
    (re.compile(r"\bThe team\b"), "The maintainers"),
    (re.compile(r"\b10\.20\.1\.236\b"), "192.0.2.10"),
    (re.compile(r"/home/[A-Za-z0-9._-]+"), "/home/you"),
    (re.compile(r"\b[A-Za-z0-9._-]+@(10\.20|192\.0\.2)"), "user@\\1"),
    (re.compile(r"\baftermath@"), "user@"),
    (re.compile(r"\b(?:[0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2}\b"), "aa:bb:cc:00:11:22"),
    (re.compile(r"\bsony-bx510\b"), "player.local"),
]


def tracked(src):
    out = subprocess.run(["git", "-C", src, "ls-files"], capture_output=True, text=True)
    return [l for l in out.stdout.splitlines() if l]


def classify(path, size):
    for rx, action, reason in RULES:
        if re.search(rx, path):
            if action == "include" and size > BIG:
                return "exclude", "regenerable blob >1 MiB"
            return action, reason
    return "exclude", "not matched by any include rule"


def is_text(path):
    try:
        with open(path, "rb") as f:
            chunk = f.read(4096)
        return b"\0" not in chunk
    except Exception:
        return False


def sha(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default=".")
    ap.add_argument("--dest", required=True)
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    manifest = []
    counts = {}
    for f in tracked(a.src):
        p = os.path.join(a.src, f)
        if not os.path.exists(p):
            continue
        size = os.path.getsize(p)
        action, reason = classify(f, size)
        counts[action] = counts.get(action, 0) + 1
        dest = f
        if f.startswith("public/"):
            dest = f[len("public/"):]          # README/LICENSE/THIRD_PARTY at root
        if action == "exclude":
            manifest.append((f, size, sha(p), "exclude", reason))
            continue
        out = os.path.join(a.dest, dest)
        os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
        if action in ("scrub", "include") and is_text(p):
            with open(p, "r", encoding="utf-8", errors="ignore") as fh:
                t = fh.read()
            for rx, rep in SCRUB:
                t = rx.sub(rep, t)
            with open(out, "w", encoding="utf-8") as fh:
                fh.write(t)
            manifest.append((dest, size, hashlib.sha256(t.encode()).hexdigest(),
                             "scrub", reason))
        elif f.lower().endswith((".heic", ".png", ".jpg", ".jpeg")):
            png = os.path.splitext(dest)[0] + ".png"
            out = os.path.join(a.dest, png)
            tmp = out + ".tmp.png"
            subprocess.run(["sips", "-s", "format", "png", p, "--out", tmp],
                           capture_output=True)
            try:                                  # re-save -> no EXIF/GPS
                from PIL import Image
                im = Image.open(tmp)
                im.save(out, exif=b"")
                os.unlink(tmp)
            except Exception:
                shutil.move(tmp, out)
            manifest.append((png, size, sha(out), "convert", "image -> PNG (metadata stripped)"))
        else:
            shutil.copy2(p, out)
            manifest.append((dest, size, sha(out), "include", reason))

    if not a.dry_run:
        with open(os.path.join(a.dest, "PUBLIC-MANIFEST.txt"), "w") as fh:
            fh.write("# PUBLIC-MANIFEST: path\tbytes\tsha256\taction\treason\n")
            for row in manifest:
                fh.write("\t".join(str(x) for x in row) + "\n")
    print("actions:", json.dumps(counts))
    inc = [m for m in manifest if m[3] != "exclude"]
    print("included %d files, %.1f MiB" % (len(inc), sum(m[1] for m in inc) / 1048576))
    print("excluded %d files, %.1f MiB" % (len(manifest) - len(inc),
                                           sum(m[1] for m in manifest if m[3] == "exclude") / 1048576))


if __name__ == "__main__":
    main()
