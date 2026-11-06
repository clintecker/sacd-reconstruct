#!/usr/bin/env python3
"""audit_public.py — deterministic public-readiness audit for the standalone repo.

Classifies every tracked file and reports, per class, what a public reader would
see. Nothing is deleted: this only reports, so the decisions stay explicit.

Classes
  VENDOR-SONY   Sony binaries we did not write (original ELF, sacd_read.ko,
                retail .so/.ko, Sony font assets) -> redistribution question
  BLOB-LARGE    >1 MiB track content (test images) -> regenerable?
  EXIF          photos carrying camera/GPS metadata
  LEAK-ID       IPv4 / MAC / hostname / /Users/<name> paths in text
  INTERNAL      process/policy docs not meant for readers (AGENTS.md, DELTA...)
  VENDORED-3P   third-party source; needs a license file
  OK            everything else

Usage: audit_public.py <repo> [--json out.json]
"""
import json
import os
import re
import subprocess
import sys

# Sony assets only: their daemon, their kernel module, their font. Our own .so
# (bx510_pair.so) and our shims are NOT Sony.
SONY_NAMES = re.compile(r"(^|/)(original/sacd_extract_160|original/sacd_read\.ko|"
                        r".*sacd_read\.ko|.*sony-font\.(ttf|bin))$")
THIRD_PARTY = re.compile(r"(^|/)third_party/")
INTERNAL_DOC = re.compile(r"(^|/)(AGENTS\.md|DELTA\.md|RESEARCH-BRIEF\.md|NOTES\.md)$")
BINARY_EXT = re.compile(r"\.(ko|so|bin|img|iso|ppm|HEIC|heic|gif|mp4|o|a)$", re.I)

IP = re.compile(r"\b(10|192\.168|172\.(1[6-9]|2\d|3[01]))\.\d{1,3}\.\d{1,3}\b")
MAC = re.compile(r"\b([0-9a-f]{2}:){5}[0-9a-f]{2}\b", re.I)
USERPATH = re.compile(r"/Users/[A-Za-z0-9._-]+")
HOSTNAME = re.compile(r"\b(bx510-emulator|aftermath@)\b")
# our own scrub placeholders are benign, not leaks
BENIGN = ("aa:bb:cc:00:11:22", "/Users/you", "/home/you", "user@", "player.local")

# deeper classes: things that hurt a reader or leak, without being IP addresses
SECRET = re.compile(r"(sk-[A-Za-z0-9]{16,}|ghp_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{12,}|"
                    r"-----BEGIN [A-Z ]*PRIVATE KEY-----|xox[baprs]-[A-Za-z0-9-]{10,})")
EMAIL = re.compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b")
CVE = re.compile(r"\bCVE-\d{4}-\d{4,7}\b")
# narrow on purpose: "worker thread", "reviewer" etc. are legitimate English
JARGON = re.compile(r"\b(sacd-enhanced|sacd-verify|lab VM|subagent|"
                    r"LANE-[0-9]|STAGE-[0-9]|the team)\b", re.I)
BENIGN_EMAIL = ("git@github.com", "okir@monad.swb.de")
# a doc that points at something we excluded leaves the reader stranded
REF = re.compile(r"`((?:analysis|original|incoming|emulator-kit|reconstruct|tools|docs|"
                 r"evidence|emulator-handoff)/[A-Za-z0-9_./-]+)`")


def tracked(repo):
    out = subprocess.run(["git", "-C", repo, "ls-files"], capture_output=True, text=True)
    return [l for l in out.stdout.splitlines() if l]


def has_exif_sips(path):
    """PIL cannot read HEIC; sips is the reliable, deterministic check here."""
    try:
        out = subprocess.run(["sips", "-g", "all", path], capture_output=True, text=True)
        t = out.stdout.lower()
        return any(k in t for k in ("gps", "latitude", "longitude", "make", "model",
                                    "creation", "software"))
    except Exception:
        return False


def is_text(path):
    try:
        with open(path, "rb") as f:
            chunk = f.read(4096)
        if b"\0" in chunk:
            return False
        chunk.decode("utf-8", "ignore")
        return True
    except Exception:
        return False


def scan_text(path, limit=400_000):
    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            return f.read(limit)
    except Exception:
        return ""


def main():
    repo = sys.argv[1] if len(sys.argv) > 1 else "."
    report = {k: [] for k in ("VENDOR-SONY", "BLOB-LARGE", "EXIF", "LEAK-ID",
                              "INTERNAL", "VENDORED-3P", "OK")}
    for f in tracked(repo):
        p = os.path.join(repo, f)
        if not os.path.exists(p):
            continue
        size = os.path.getsize(p)
        cls = []
        if SONY_NAMES.search(f):
            cls.append("VENDOR-SONY")
        if size > 1024 * 1024:
            cls.append("BLOB-LARGE")
        if f.lower().endswith((".heic", ".jpg", ".jpeg", ".png")):
            if has_exif_sips(p):
                cls.append("EXIF")
        if INTERNAL_DOC.search(f):
            cls.append("INTERNAL")
        if THIRD_PARTY.search(f):
            cls.append("VENDORED-3P")
        if is_text(f) and size < 400_000:
            t = scan_text(p)
            hits = []
            tt = t
            for b in BENIGN + BENIGN_EMAIL:
                tt = tt.replace(b, "")
            if IP.search(tt): hits.append("ipv4")
            if MAC.search(tt): hits.append("mac")
            if USERPATH.search(tt): hits.append("userpath")
            if HOSTNAME.search(tt): hits.append("hostname")
            if hits:
                cls.append("LEAK-ID")
                report.setdefault("LEAK-DETAIL", []).append([f, sorted(set(hits))])
        # deeper text checks
        if is_text(f) and size < 400_000:
            t = scan_text(f)
            t_ben = t
            for b in BENIGN_EMAIL:
                t_ben = t_ben.replace(b, "")
            vendorish = f.startswith(("evidence/", "tools/third_party/"))
            for name, rx, body in (("SECRET", SECRET, t), ("EMAIL", EMAIL, t_ben),
                                   ("CVE", CVE, t), ("JARGON", JARGON, t)):
                m = rx.search(body)
                if m and name == "EMAIL" and vendorish:
                    name = "EMAIL-VENDOR"      # kernel/glibc/zlib strings, informational
                if m:
                    report.setdefault(name, []).append([f, size])
                    report.setdefault(name + "-DETAIL", []).append([f, m.group(0)[:60]])
            refs = set(REF.findall(t))
            missing = [r for r in refs if not os.path.exists(os.path.join(repo, r))]
            if missing:
                report.setdefault("BROKEN-REF", []).append([f, size])
                report.setdefault("BROKEN-REF-DETAIL", []).append([f, sorted(missing)[:6]])
        if not cls:
            cls = ["OK"]
        for c in cls:
            report[c].append([f, size])

    for k, v in report.items():
        if k.endswith("-DETAIL"):
            continue
        print("== %s: %d files, %.1f MiB" % (k, len(v), sum(x[1] for x in v) / 1048576))
        for f, s in sorted(v, key=lambda x: -x[1])[:12]:
            print("   %8.1f KiB  %s" % (s / 1024, f))
        if len(v) > 12:
            print("   ... %d more" % (len(v) - 12))
    if "--json" in sys.argv:
        out = sys.argv[sys.argv.index("--json") + 1]
        json.dump(report, open(out, "w"), indent=1)
        print("json:", out)


if __name__ == "__main__":
    main()
