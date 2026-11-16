#!/usr/bin/env python3
"""docs_audit.py — documentation-orientation audit for the public tree.

A repository for public consumption must read like documentation, not like a
session transcript. This tool classifies every tracked markdown file and
flags, per class, the defects that make a doc unusable for a public reader:

  COACH   second-person operator coaching ("your stick", "YOUR TEST STICK",
          "you should send me ...") — belongs in a private runbook, not docs
  SESSION session-speak ("tonight", "this session", "the team", "my Mac",
          "yesterday") — a public reader has no session to refer back to
  INFRA   private infrastructure identifiers (10.x addresses, /Users/<name>,
          aftermath@) — scrubbed forms belong in their place
  EXTLINK links to ephemeral external workspaces (chatgpt.com library etc.)
  STALE   stale-current claims: old parity counts or release SHAs stated
          without history/superseded markers
  DEVLINK relative links that do not resolve inside the tree

Classes of file:
  CANONICAL  docs/, root README/DELTA, tools/README, emulator-kit/README
             — the public reading path; every defect here is a finding
  LABNOTE    evidence/** — the engineering record; INFRA/EXTLINK are
             findings, COACH/SESSION are judged by the same rule (a public
             reader still reads these)
  PROCESS    the known session-workspace docs — expected to carry defects;
             the finding is that they are in the tree at all

Usage:
  python3 tools/docs_audit.py [--tree public-branch]        # audit refs/heads/public
  python3 tools/docs_audit.py --src .                       # audit a working tree
Exit 0 = clean, 1 = findings.
"""
import argparse
import os
import posixpath
import re
import subprocess
import sys

# ---- defect patterns -------------------------------------------------------
COACH = [
    re.compile(r"\byour (current |test |spare |working |ripping |normal |existing )?(stick|mac|session|setup|usb)", re.I),
    re.compile(r"\b(YOUR|Your) (TEST|SPARE|WORKING)[A-Z ]*STICK"),
    re.compile(r"\byou should (send|run|copy|try|use|collect)", re.I),
    re.compile(r"\bOpen Terminal in\b"),
    re.compile(r"\bSend that (marker|log)\b"),
]
SESSION = [
    re.compile(r"\btonight\b", re.I),
    re.compile(r"\bthis session\b"),
    re.compile(r"\blast night\b", re.I),
    re.compile(r"\bthe team's\b|\bour team\b", re.I),
    re.compile(r"\bmy (Mac|machine|repo|session)\b", re.I),
]
INFRA = [
    re.compile(r"\b10\.20\.\d{1,3}\.\d{1,3}\b"),
    re.compile(r"\b192\.168\.\d{1,3}\.\d{1,3}\b"),
    re.compile(r"/Users/(?!you\b)[A-Za-z0-9._-]+"),
    re.compile(r"\baftermath@"),
    re.compile(r"\baftermath\b(?=@| VM| user|@\d)"),
]
EXTLINK = [
    re.compile(r"chatgpt\.com/library"),
]
# vague-time markers a public reader cannot anchor: "recently", "soon",
# "currently" (status claims that rot), "now supports" (stales quickly),
# "as discussed" / "as mentioned" (refers to a conversation the reader lacks)
VAGUE = [
    re.compile(r"\b(recently (added|updated|fixed|landed|changed)|a recent (run|session))\b", re.I),
    re.compile(r"\bwill (soon|shortly)\b", re.I),
    re.compile(r"\bas (discussed|mentioned|noted) (above|earlier|before)\b", re.I),
    re.compile(r"\bcoming soon\b", re.I),
]
STALE = [
    re.compile(r"38[588]/390|377/390|369/390"),
    re.compile(r"e91720fb"),
]

# mirror of tools/public_tree.py SCRUB (the publish pipeline's rewrites);
# src-mode audits apply these first so findings reflect the public reader's view
SCRUB_SIM = [
    (re.compile(r"\b10\.\d{1,3}\.\d{1,3}\.\d{1,3}\b"), "192.0.2.10"),
    (re.compile(r"\b192\.168\.\d{1,3}\.\d{1,3}\b"), "192.0.2.11"),
    (re.compile(r"\b172\.(1[6-9]|2\d|3[01])\.\d{1,3}\.\d{1,3}\b"), "192.0.2.12"),
    (re.compile(r"/Users/[A-Za-z0-9._-]+"), "/Users/you"),
    (re.compile(r"\baftermath@"), "user@"),
]

def apply_scrub(line):
    for rx, rep in SCRUB_SIM:
        line = rx.sub(rep, line)
    return line

CLASS_RULES = [
    (re.compile(r"^(docs/|README\.md$|DELTA\.md$|tools/README\.md$|emulator-kit/README\.md$)"), "CANONICAL"),
    (re.compile(r"^(evidence/)"), "LABNOTE"),
    (re.compile(r"^emulator-handoff/(AT-HOME|HANDOFF-README|screen/README)"), "PROCESS"),
    (re.compile(r"^(AGENTS\.md$|NOTES\.md$|RESEARCH-BRIEF\.md$)"), "INTERNAL"),
]


def classify(path):
    for rx, cls in CLASS_RULES:
        if rx.search(path):
            return cls
    return "OTHER"


def audit_file(path, text, all_files):
    findings = []

    def add(kind, lineno, line):
        findings.append((kind, lineno, line.strip()[:110]))

    # src-mode simulates the publish pipeline's scrub so the audit measures
    # what the public reader will actually see (verbatim command transcripts
    # in evidence carry real addresses; the pipeline rewrites them).
    lines = [apply_scrub(ln) for ln in text.splitlines()]
    for i, line in enumerate(lines, 1):
        for rx in COACH:
            if rx.search(line):
                add("COACH", i, line)
                break
        for rx in SESSION:
            if rx.search(line):
                add("SESSION", i, line)
                break
        for rx in INFRA:
            if rx.search(line):
                add("INFRA", i, line)
                break
        for rx in EXTLINK:
            if rx.search(line):
                add("EXTLINK", i, line)
                break
        for rx in VAGUE:
            if rx.search(line):
                add("VAGUE", i, line)
                break
    # STALE: only counts when no history/superseded marker appears on the
    # line itself or within the surrounding 3 lines (the marker convention
    # used across this repo: "superseded ...", "history:", "(then-current)")
    MARKERS = ("history", "superseded", "then-", "was current", "corrected",
               "chronological", "session-log", "nov-5", "2026-11-05",
               "pre-divergence", "session 2", "session 3", "2026-11 run", "rerun this check",
               "then current", "dated session record", "historical values from")
    for i, line in enumerate(lines, 1):
        if not any(rx.search(line) for rx in STALE):
            continue
        ctx = "\n".join(lines[max(0, i - 7):i + 7]).lower()
        if any(m in ctx for m in MARKERS):
            continue
        add("STALE", i, line)
    # DEVLINK: relative links that do not resolve
    base = posixpath.dirname(path)
    for m in re.finditer(r"\]\(([^)#]+?)(?:#[^)]*)?\)", text):
        t = m.group(1).strip()
        if t.startswith(("http://", "https://", "mailto:")):
            continue
        if not re.search(r"\.(md|py|sh|c|h|json|txt|png|gif|log)$", t):
            continue
        r = posixpath.normpath(posixpath.join(base, t))
        known = r in all_files
        # public/-prefixed files ship at repo root on the public branch, and
        # root-named links resolve there; accept either mapping
        if not known and posixpath.basename(r) in all_files:
            known = True
        if not known and ("public/" + r) in all_files:
            known = True
        if not known:
            add("DEVLINK", 0, t)
    return findings


def load_files(src, ref=None):
    """-> ({path: text}, all_paths) for every tracked .md file.

    With --ref, audit the ref's committed tree. Otherwise audit the WORKING
    TREE (what a commit would ship) - the pre-commit use case.
    """
    rev = ref or "HEAD"
    out = subprocess.run(["git", "-C", src, "ls-tree", "-r", "--name-only", rev],
                         capture_output=True, text=True, check=True).stdout.split()
    all_files = set(out)
    files = {}
    for p in out:
        if not p.endswith(".md"):
            continue
        if ref:
            files[p] = subprocess.run(["git", "-C", src, "show", f"{rev}:{p}"],
                                      capture_output=True, text=True, check=True).stdout
        else:
            files[p] = open(os.path.join(src, p), encoding="utf-8",
                            errors="replace").read()
    return files, all_files


def orphans(files):
    """Canonical docs not reachable from the reading path (README/DELTA/LIFECYCLE/REPRODUCE)."""
    seeds = [f for f in ("README.md", "DELTA.md", "docs/LIFECYCLE.md",
                         "docs/REPRODUCE.md") if f in files]
    seen = set()

    def walk(f):
        if f in seen:
            return
        seen.add(f)
        for m in re.finditer(r"\]\(([^)#]+?)(?:#[^)]*)?\)", files[f]):
            t = m.group(1).strip()
            if t.startswith(("http://", "https://", "mailto:")):
                continue
            r = posixpath.normpath(posixpath.join(posixpath.dirname(f), t))
            if (r in files and r.endswith(".md")
                    and not r.startswith(("evidence/", "emulator-handoff/",
                                          "public/"))):
                walk(r)

    for s in seeds:
        walk(s)
    return sorted(f for f in files
                  if f.startswith("docs/") and f.endswith(".md")
                  and f not in seen)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default=".", help="working tree to audit")
    ap.add_argument("--ref", default=None,
                    help="audit a git ref's tree instead (e.g. refs/heads/public)")
    ap.add_argument("--orphans", action="store_true",
                    help="list canonical docs unreachable from the reading path")
    a = ap.parse_args()
    files, all_paths = load_files(a.src, a.ref)
    if a.orphans:
        o = orphans(files)
        print("\n".join(o) if o else "no orphan canonical docs")
        return 1 if o else 0

    by_class = {}
    for path, text in list(files.items()):
        # public/README.md lives at repo root on the public branch; audit it
        # under its public-branch name so root-relative links resolve
        key = "README.md" if path == "public/README.md" else path
        text = files.pop(path) if key != path else text
        findings = audit_file(key, text, all_paths | {key})
        if findings:
            by_class.setdefault(classify(key), []).append((key, findings))

    total = 0
    for cls in ("CANONICAL", "LABNOTE", "PROCESS", "OTHER", "INTERNAL"):
        if cls not in by_class:
            continue
        counted = cls not in ("PROCESS", "INTERNAL")
        print(f"== {cls}" + ("" if counted else "  (expected defects — not counted)"))
        for path, findings in sorted(by_class[cls]):
            kinds = {}
            for k, _, _ in findings:
                kinds[k] = kinds.get(k, 0) + 1
            if counted:
                total += len(findings)
            print(f"  {path}  {dict(sorted(kinds.items()))}")
            for k, ln, line in findings:
                print(f"    {k:8s} L{ln:<4} {line}")
    print(f"\n{total} findings across {len(files)} markdown files")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
