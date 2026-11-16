#!/usr/bin/env python3
"""bx510_cipher_check.py — the Level-1 cipher acceptance gates (spec §5.3).

Normative spec: evidence/bx510-guest/bdpdrv/decode/level1-cipher-spec.md §5.3.
Reads one fire's UART transcript plus the recorded oracle file and decides
PASS/FAIL on seven fatal gates. Every gate prints the row it checked; a single
failed gate exits 1 (all gates run — a diagnosis is worth more than the first
failure).

  --expect cipher-on   every row must equal the PLAIN column (§3.3)  -> c136/c137
  --expect cipher-off  every audio row must equal the CIPHERTEXT column and
                       DIFFER from the plain one, while the metadata row still
                       equals the plain column (area selectivity)     -> c135/c138

Gates:
  1 the served disc is --disc with 1064208 sectors (the model's attach line) —
    proves WHICH image the run really read, pairing c135/c136 and pinning c138;
  2 cipher-on: at least one `l1 block:` census line exists — no line means the
    stub in the box is the identity build (the stale-stub class, spec C3);
  3 every oracle row present in the transcript equals the selected column;
  4 cipher-off: every ENCRYPTED row differs from the plain column (anti-no-op —
    equal md5s would mean the derived disc was never encrypted);
  5 the metadata rows (510×10) equal the PLAIN column in BOTH modes — the
    area-selectivity proof (plaintext at rest, still plaintext on the wire
    even though it passed through the decrypt ioctl);
  6 cipher-on: the block starting at LSN 845 logs ks0=ca7c8729 and the one at
    745 logs ks0=63c3ab72 (§2.2) — the cross-language KAT, no payload needed;
  7 cipher-on: the EDGE read's blocks transform exactly the in-area frames
    (353750..353763 -> xform, 353764..353789 -> pass) — the only gate that can
    catch an off-by-one in the range table.

Rows are grouped by template: a fire runs ONE template, so the rows of the
template present in the transcript must all be there (a partially present
template is a truncated transcript -> gate 3 fails); rows of the other template
are reported as not-applicable rather than silently skipped. The same rule makes
gates 5/6/7 not-applicable when the fire performs none of their reads: the
510x10 metadata row and the 845/745/EDGE reads live in DIFFERENT client
templates (client_a_reconnect vs client_d_arearead), so one fire cannot exercise
all of them — c137 carries the metadata proof, c135/c136/c138 the audio ones.

--selftest builds synthetic transcripts and proves every gate BITES: four
positive cases (the c135/c136/c137/c138 shapes) pass, and each failure mode
(wrong disc, identity stub, no-op disc, corrupted metadata, wrong ks0, header
LSN lost, range off-by-one, truncated transcript) fails the intended gate. The
fixtures are a CONTROL for this tool and are never evidence — no fire transcript
is involved.
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from bx510_disc_cipher import (  # noqa: E402
    KAT, L1_ENC_END1, l1_in_area, l1_seed,
)

EXPECTED_SECTORS = 1064208
EDGE_LBA = 353750          # the straddle read: 353750..353789 (§3.3 EDGE row)
EDGE_CNT = 40

# the two discs the battery serves, and the reads each client template performs
# (the --selftest fixtures are built from these; nothing here is fire data)
DEFAULT_ORACLES = "evidence/bx510-guest/bdpdrv/decode/level1-cipher-oracles.json"
DERIVED_DISC = "/home/aftermath/sacd-verify/firebird-cipher.iso"
PLAIN_DISC = "/home/aftermath/sacd-verify/firebird.iso"
TEMPLATE_READS = {
    "client_d_arearead": (("A1", 845, 1), ("A32", 845, 32), ("TRK", 745, 128),
                          ("EDGE", EDGE_LBA, EDGE_CNT), ("RIP", 600, 1600)),
    "client_a_reconnect": (("S1", 510, 10), ("S2", 532104, 1), ("S3", 510, 10)),
}

ATTACH_RE = re.compile(
    r"bx510: SATA ATAPI drive attached: (\S+) \((\d+) sectors\)")
BLOCK_RE = re.compile(
    r"l1 block: count=(\d+) lsn=(\d+)\.\.(\d+) xform=(\d+) pass=(\d+) "
    r"armed=(\d+) ks0=([0-9a-fA-F]{8})")
MD5_LINE = re.compile(r"^([0-9a-f]{32})\b")


class Report:
    def __init__(self):
        self.failed = False
        self.gates_failed = set()

    def gate(self, num, name, ok, detail):
        """ok is True/False/None (None = not applicable in this mode)."""
        if ok is None:
            verdict = "N/A "
        elif ok:
            verdict = "PASS"
        else:
            verdict = "FAIL"
            self.failed = True
            self.gates_failed.add(num)
        print("GATE %d %s %-46s %s" % (num, verdict, name, detail))
        return bool(ok)

    def note(self, text):
        print("        %s" % text)


def md5_for_marker(lines, marker):
    """The md5 the template printed for `marker`, or None if absent.

    The client templates (bx510_client_*.sh.in) print `md5sum <file>` immediately
    before an `<MARKER>_MD5_END` sentinel, so the nearest md5 line above the
    sentinel is the row's value."""
    end = marker + "_MD5_END"
    for i in range(len(lines) - 1, -1, -1):
        if lines[i].strip() == end:
            for j in range(i - 1, max(-1, i - 6), -1):
                m = MD5_LINE.match(lines[j].strip())
                if m:
                    return m.group(1)
            return None
    return None


def parse_blocks(lines):
    out = []
    for line in lines:
        m = BLOCK_RE.search(line)
        if m:
            out.append({"count": int(m.group(1)), "lo": int(m.group(2)),
                        "hi": int(m.group(3)), "xform": int(m.group(4)),
                        "pass": int(m.group(5)), "armed": int(m.group(6)),
                        "ks0": m.group(7).lower()})
    return out


def check(uart_path, oracles_path, expect, disc):
    """Run the seven gates over one transcript; returns the Report."""
    text = Path(uart_path).read_text(errors="replace")
    lines = text.replace("\r\n", "\n").replace("\r", "\n").split("\n")
    orc = json.loads(Path(oracles_path).read_text())
    rep = Report()
    cipher_on = expect == "cipher-on"

    # ---- gate 1: which disc did the run really serve? ---------------------
    attach = ATTACH_RE.findall(text)
    want_path = os.path.normpath(disc)
    g1_ok = bool(attach) and all(
        os.path.normpath(p) == want_path and int(n) == EXPECTED_SECTORS
        for p, n in attach)
    rep.gate(1, "served disc == --disc, %d sectors" % EXPECTED_SECTORS, g1_ok,
             "%s (%d attach line(s))" % (disc, len(attach)))
    for p, n in attach:
        if os.path.normpath(p) != want_path or int(n) != EXPECTED_SECTORS:
            rep.note("saw: %s (%s sectors)" % (p, n))

    # ---- the oracle file's own integrity ----------------------------------
    kat_pub = {lns: "%08x" % seed for lns, seed, _md5 in KAT}
    kat_json = {int(k["lsn"]): k.get("seed", "").lower()
                for k in orc.get("kat", [])}
    kat_bad = [(lns, kat_json.get(lns), kat_pub[lns]) for lns in kat_pub
               if kat_json.get(lns) != kat_pub[lns]]

    # ---- gate 2: is the cipher-bearing stub in the box? -------------------
    blocks = parse_blocks(lines)
    if cipher_on:
        rep.gate(2, "`l1 block:` census present", bool(blocks),
                 "%d block line(s)" % len(blocks))
    else:
        rep.gate(2, "`l1 block:` census present", None,
                 "cipher-off: identity is the expected behaviour")

    # ---- gates 3/4/5: the oracle table ------------------------------------
    rows = orc["rows"]
    # Which column does this disc carry at rest? The DERIVED disc is ciphertext,
    # the SOURCE disc is plaintext — so a cipher-off fire against the real ISO
    # (c138, the Level-0 regression) carries the PLAIN column while a cipher-off
    # fire against the derived disc (c135) carries the ciphertext one. --expect
    # alone cannot express that distinction; the disc path can, and the oracle
    # file already records both paths (spec §3.3, IMPLEMENTER CORRECTION §5.3).
    derived_path = orc.get("derived", {}).get("path")
    source_path = orc.get("source", {}).get("path")
    is_derived = bool(derived_path) and \
        os.path.normpath(disc) == os.path.normpath(derived_path)
    is_source = bool(source_path) and \
        os.path.normpath(disc) == os.path.normpath(source_path)
    plain_disc = is_source and not is_derived
    col = "plain_md5" if (cipher_on or plain_disc) else "cipher_md5"
    templates = {}
    for row in rows:
        templates.setdefault(row["template"], []).append(row)
    present = {}
    for row in rows:
        present[row["id"]] = md5_for_marker(lines, row["marker"])
    which = {t: [r for r in rs if present[r["id"]] is not None]
             for t, rs in templates.items()}
    which = {t: rs for t, rs in which.items() if rs}

    g3_ok = bool(which)
    g3_detail = "rows checked: %d" % sum(len(rs) for rs in which.values())
    if not which:
        rep.note("no oracle row marker found in the transcript — wrong template, "
                 "or the client never ran")
    for t, rs in templates.items():
        got = which.get(t, [])
        if got and len(got) != len(rs):
            g3_ok = False
            missing = [r["id"] for r in rs if present[r["id"]] is None]
            rep.note("%s: TRUNCATED transcript, missing %s"
                     % (t, ",".join(missing)))
        if not got:
            rep.note("%s: not applicable (template absent from this fire)" % t)

    for row in rows:
        got = present[row["id"]]
        if got is None:
            continue
        want = row[col]
        ok = got == want
        g3_ok = g3_ok and ok
        rep.note("%-3s %6dx%-4d %-16s %s got %s want %s"
                 % (row["id"], row["lba"], row["cnt"], col, "ok " if ok else "MISMATCH",
                    got, want))
    rep.gate(3, "row md5 == %s column" % col.replace("_md5", ""), g3_ok, g3_detail)

    # gate 4 — cipher-off only: the derived disc must really be encrypted
    audio = [r for r in rows if r["encrypted"] and present[r["id"]] is not None]
    if cipher_on:
        rep.gate(4, "cipher-off audio rows differ from plain", None,
                 "cipher-on: this gate is gate 3's equality instead")
    elif plain_disc:
        rep.gate(4, "cipher-off audio rows differ from plain", None,
                 "the real ISO is plaintext at rest — the anti-no-op gate does "
                 "not apply to c138")
    else:
        g4_ok = bool(audio)
        for row in audio:
            if present[row["id"]] == row["plain_md5"]:
                g4_ok = False
                rep.note("%s: md5 EQUALS the plain column — the derived disc was "
                         "not encrypted at rest" % row["id"])
        rep.gate(4, "cipher-off audio rows differ from plain", g4_ok,
                 "%d audio row(s) checked" % len(audio))

    # gate 5 — the metadata rows are plaintext at rest AND on the wire
    meta = [r for r in rows if not r["encrypted"] and present[r["id"]] is not None]
    g5_ok = True
    for row in meta:
        ok = present[row["id"]] == row["plain_md5"]
        g5_ok = g5_ok and ok
        rep.note("%s: metadata %dx%d == plain %s"
                 % (row["id"], row["lba"], row["cnt"],
                    "yes (selectivity)" if ok else "NO — corrupted"))
    rep.gate(5, "metadata rows == plain column in both modes",
             g5_ok if meta else None,
             "%d metadata row(s) checked" % len(meta) if meta else
             "no metadata row in this fire's template (510x10 is an S-row)")

    # ---- gate 6: the KAT, read off the fire's own ks0 field ---------------
    applicable = {r["id"] for rs in which.values() for r in rs}
    kat_reads = {845: ("A1", "A32"), 745: ("TRK",)}
    kat_here = [lsn for lsn, ids in kat_reads.items() if applicable & set(ids)]
    if kat_bad:
        for lns, got, want in kat_bad:
            rep.note("oracle file kat lsn %d: %r != published %s"
                     % (lns, got, want))
        rep.gate(6, "ks0 KAT for lsn 845 / 745 (§2.2)", False,
                 "the oracle file's own KAT disagrees with spec §2.2")
    elif cipher_on and kat_here:
        g6_ok = True
        for lsn in kat_here:
            hits = [b for b in blocks if b["lo"] == lsn]
            want = kat_json.get(lsn) or kat_pub.get(lsn)
            if not hits:
                g6_ok = False
                rep.note("no `l1 block:` line starts at lsn %d — the header LSN "
                         "did not reach the stub (spec R1)" % lsn)
                continue
            if not all(b["ks0"] == want for b in hits):
                g6_ok = False
            rep.note("lsn %d: ks0=%s want %s (%d block(s))"
                     % (lsn, ",".join(b["ks0"] for b in hits), want, len(hits)))
        rep.gate(6, "ks0 KAT for lsn 845 / 745 (§2.2)", g6_ok,
                 "lsn %s: ks0 == l1_seed(lsn)"
                 % "/".join(str(n) for n in kat_here))
    elif cipher_on:
        rep.gate(6, "ks0 KAT for lsn 845 / 745 (§2.2)", None,
                 "this fire reads neither 845 nor 745 (no KAT block to read)")
    else:
        rep.gate(6, "ks0 KAT for lsn 845 / 745 (§2.2)", None,
                 "cipher-off: frames carry no LSN (hdr is Level-0 zeros)")

    # ---- gate 7: the EDGE straddle, per frame ----------------------------
    if cipher_on and "EDGE" in applicable:
        lo, hi = EDGE_LBA, EDGE_LBA + EDGE_CNT - 1
        strad = [b for b in blocks if b["lo"] <= hi and b["hi"] >= lo]
        covered = set()
        g7_ok = bool(strad)
        xf_total = ps_total = 0
        for b in strad:
            covered.update(range(b["lo"], b["hi"] + 1))
            want_xf = sum(1 for lsn in range(b["lo"], b["hi"] + 1)
                          if l1_in_area(lsn))
            xf_total += b["xform"]
            ps_total += b["pass"]
            if b["xform"] != want_xf:
                g7_ok = False
                rep.note("block %d..%d: xform=%d want %d (in-area frames)"
                         % (b["lo"], b["hi"], b["xform"], want_xf))
        if covered != set(range(lo, hi + 1)):
            g7_ok = False
            rep.note("EDGE read %d..%d is not fully covered by `l1 block:` lines "
                     "(covered %d of %d frames)"
                     % (lo, hi, len(covered & set(range(lo, hi + 1))), EDGE_CNT))
        in_area_frames = sum(1 for lsn in range(lo, hi + 1) if l1_in_area(lsn))
        if xf_total != in_area_frames:
            g7_ok = False
        rep.gate(7, "EDGE straddle: only in-area frames transformed", g7_ok,
                 "%d block(s), xform=%d pass=%d; want xform=%d pass=%d "
                 "(split at %d)" % (len(strad), xf_total, ps_total,
                                    in_area_frames, EDGE_CNT - in_area_frames,
                                    L1_ENC_END1 + 1))
    elif cipher_on:
        rep.gate(7, "EDGE straddle: only in-area frames transformed", None,
                 "this fire does not perform the EDGE straddle read")
    else:
        rep.gate(7, "EDGE straddle: only in-area frames transformed", None,
                 "cipher-off: nothing is transformed by construction")

    print("%s: %s (%s)" % ("FAIL" if rep.failed else "PASS", expect, uart_path))
    return rep


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--uart", help="the fire's UART transcript")
    ap.add_argument("--oracles",
                    help="decode/level1-cipher-oracles.json")
    ap.add_argument("--expect", choices=("cipher-on", "cipher-off"))
    ap.add_argument("--disc", help="the disc path the run was supposed to serve")
    ap.add_argument("--selftest", action="store_true",
                    help="prove every gate bites on synthetic transcripts")
    args = ap.parse_args(argv)

    if args.selftest:
        return cmd_selftest(args.oracles or DEFAULT_ORACLES)
    if not (args.uart and args.oracles and args.expect and args.disc):
        ap.error("--uart, --oracles, --expect and --disc are all required "
                 "(or pass --selftest)")
    return 1 if check(args.uart, args.oracles, args.expect, args.disc).failed else 0


# ---------------------------------------------------------------------------
# --selftest: the tool's own control. Synthetic transcripts, no fire evidence.
# ---------------------------------------------------------------------------


def _blocks(lba, cnt, armed, in_area, zero_lsn, bad_ks0):
    """One `l1 block:` line per frame — the shape every c134 census block had
    (count=1), which is also the shape that makes gate 7 non-trivial."""
    out = []
    for i in range(cnt):
        lsn = 0 if zero_lsn else lba + i
        xf = 1 if (armed and in_area(lba + i)) else 0
        ks = l1_seed(lsn)
        if bad_ks0 and i == 0:
            ks ^= 0xFFFFFFFF
        out.append("[OSAL_STUB] tz: l1 block: count=1 lsn=%d..%d xform=%d "
                   "pass=%d armed=%d ks0=%08x" % (lsn, lsn, xf, 1 - xf, armed, ks))
    return out


def _transcript(orc, template, armed, column, disc, in_area=None,
                zero_lsn=False, bad_ks0=False):
    """A c135/c136/c137-shaped transcript whose md5 rows come from `column`."""
    in_area = in_area or l1_in_area
    md5 = {r["id"]: r[column] for r in orc["rows"]}
    lines = ["bx510: SATA ATAPI drive attached: %s (%d sectors)"
             % (disc, EXPECTED_SECTORS)]
    lines += _blocks(510, 10, armed, in_area, zero_lsn, bad_ks0)   # the TOC read
    for rid, lba, cnt in TEMPLATE_READS[template]:
        lines += _blocks(lba, cnt, armed, in_area, zero_lsn, bad_ks0)
        lines.append("%s  /tmp/%s.bin" % (md5[rid], rid.lower()))
        lines.append("%s_MD5_END" % rid)
    return "\n".join(lines) + "\n"


def cmd_selftest(oracles=DEFAULT_ORACLES):
    import contextlib
    import io
    import tempfile

    orc = json.loads(Path(oracles).read_text())
    cases = []
    # the fires the battery will run
    cases.append(("c136 cipher-on, arearead", _transcript(
        orc, "client_d_arearead", 1, "plain_md5", DERIVED_DISC), "cipher-on",
        DERIVED_DISC, ()))
    cases.append(("c135 cipher-off, arearead", _transcript(
        orc, "client_d_arearead", 0, "cipher_md5", DERIVED_DISC), "cipher-off",
        DERIVED_DISC, ()))
    cases.append(("c137 cipher-on, reconnect", _transcript(
        orc, "client_a_reconnect", 1, "plain_md5", DERIVED_DISC), "cipher-on",
        DERIVED_DISC, ()))
    cases.append(("c138 cipher-off, real ISO", _transcript(
        orc, "client_d_arearead", 0, "plain_md5", PLAIN_DISC), "cipher-off",
        PLAIN_DISC, ()))
    # and the seven ways a fire can lie
    cases.append(("gate 1: wrong disc served", _transcript(
        orc, "client_d_arearead", 1, "plain_md5", PLAIN_DISC), "cipher-on",
        DERIVED_DISC, (1,)))
    noline = "\n".join(
        ["bx510: SATA ATAPI drive attached: %s (%d sectors)"
         % (DERIVED_DISC, EXPECTED_SECTORS)] +
        ["%s  /tmp/%s.bin\n%s_MD5_END" % (r["plain_md5"], r["id"].lower(), r["id"])
         for r in orc["rows"] if r["template"] == "client_d_arearead"]) + "\n"
    cases.append(("gate 2: identity stub, no census", noline, "cipher-on",
                  DERIVED_DISC, (2,)))
    cases.append(("gate 3/4: disc never encrypted", _transcript(
        orc, "client_d_arearead", 0, "plain_md5", DERIVED_DISC), "cipher-off",
        DERIVED_DISC, (4,)))
    cases.append(("gate 5: metadata row corrupted", _transcript(
        orc, "client_a_reconnect", 0, "cipher_md5", DERIVED_DISC).replace(
            orc["rows"][5]["cipher_md5"], "0" * 32), "cipher-off",
        DERIVED_DISC, (5,)))
    cases.append(("gate 6: ks0 is not l1_seed", _transcript(
        orc, "client_d_arearead", 1, "plain_md5", DERIVED_DISC,
        bad_ks0=True), "cipher-on", DERIVED_DISC, (6,)))
    cases.append(("gate 6: header LSN lost (R1)", _transcript(
        orc, "client_d_arearead", 1, "cipher_md5", DERIVED_DISC,
        in_area=lambda lsn: l1_in_area(0), zero_lsn=True), "cipher-on",
        DERIVED_DISC, (6,)))
    cases.append(("gate 7: range off-by-one at 353764", _transcript(
        orc, "client_d_arearead", 1, "plain_md5", DERIVED_DISC,
        in_area=lambda lsn: l1_in_area(lsn) or lsn == EDGE_LBA + 14), "cipher-on",
        DERIVED_DISC, (7,)))
    cases.append(("gate 3: truncated transcript", _transcript(
        orc, "client_d_arearead", 1, "plain_md5", DERIVED_DISC).replace(
            "RIP_MD5_END", "RIP_END"), "cipher-on", DERIVED_DISC, (3,)))

    bad = 0
    with tempfile.TemporaryDirectory() as tmp:
        for i, (name, text, expect, disc, want_gates) in enumerate(cases):
            path = os.path.join(tmp, "fx%02d.uart.log" % i)
            Path(path).write_text(text)
            buf = io.StringIO()
            with contextlib.redirect_stdout(buf):
                rep = check(path, oracles, expect, disc)
            ok = (not rep.failed) if not want_gates else \
                set(want_gates) <= rep.gates_failed
            bad += 0 if ok else 1
            print("selftest %-38s %s%s"
                  % (name, "PASS" if ok else "FAIL",
                     "" if not rep.gates_failed else
                     "  (gates failing: %s)"
                     % ",".join(str(g) for g in sorted(rep.gates_failed))))
            if not ok:
                print(buf.getvalue())
    if bad:
        print("SELFTEST FAIL: %d case(s)" % bad)
        return 1
    print("SELFTEST PASS: %d cases — every gate passes its positive and fails "
          "its negative (synthetic transcripts, not evidence)" % len(cases))
    return 0
if __name__ == "__main__":
    sys.exit(main())
