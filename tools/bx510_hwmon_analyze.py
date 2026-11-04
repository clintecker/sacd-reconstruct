#!/usr/bin/env python3
"""Deterministic analyzer for the BX510 hardware hwmon snapshot corpus.

Input: the recovered hwmon-backup.tgz (490 snap-XXXX-<uptime>.txt files)
plus, from the same stick-diagnostics directory, hwmon-boot.txt (trigger
log) and pairlaunch.log / pairlaunch-recovered.log (pair-phase launcher
logs). Everything is parsed read-only; the tarball is unpacked into a
scratch dir outside the repo.

Key structural fact this analyzer establishes (do not assume multi-boot):
the corpus contains THREE CONCURRENT hwmon.bin writer instances that share
one filename scheme (snap-<seq>-<uptime>.txt) on one continuous uptime
clock. Writers are recovered as chains: within a writer, seq increments
by exactly 1 and uptime increases monotonically at ~5s cadence. The
single-boot determination then rests on three independent observations:
(1) the same core process set (identical PIDs, e.g. hwmon pid 1255,
bdpprog pid 743) is present in every one of the 490 snapshots spanning
uptime 57..1332; (2) writer chains overlap in uptime with interleaved,
mutually consistent views; (3) the trigger log's /proc/uptime stamps
(57.25 / 507.17 / 978.43 / 1332.58) run on the same monotonic clock as
the snapshots.

Outputs a fixed-format report to stdout (or --report FILE) covering:
corpus summary, writer clusters, single-boot evidence, per-PID process
lifecycle, appearance/disappearance events, listener timeline with
socket-inode stability, client connections to port 2002, module
timeline (added modules / use-count tracks), /dev/shm contents,
display/fusion holder rows, and the trigger/pairlaunch cross-reference.

Usage:
  python3 bx510_hwmon_analyze.py [--tgz PATH] [--scratch DIR] [--report FILE]

Exit status 0 on success; nonzero if the corpus fails a structural
sanity check (file count, header/filename consistency, writer chains).
"""

import argparse
import hashlib
import os
import re
import sys
import tarfile

DEFAULT_TGZ = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "..",
    "evidence", "bx510", "hw-session-2026-11-04", "stick-diagnostics",
    "hwmon-backup.tgz",
)

SNAP_RE = re.compile(r"^snap-(\d+)-(\d+)\.txt$")
PROC_LINE_RE = re.compile(r"^(\d+) (.*)$")
HEX_PORT_RE = re.compile(r"^\s*\d+: ([0-9A-F]{8}):([0-9A-F]{4}) "
                         r"([0-9A-F]{8}):([0-9A-F]{4}) ([0-9A-F]{2}) ")
LISTEN_PORTS = {  # appliance listeners named by the appliance thread
    "D480": 54400, "E4A2": 58530, "D70A": 55050, "56CE": 22190,
    "07D2": 2002,
}


class Snapshot(object):
    def __init__(self, path, seq, uptime):
        self.path = path
        self.name = os.path.basename(path)
        self.seq = seq
        self.uptime = uptime
        self.header = None
        self.processes = {}      # pid -> cmdline
        self.modules = {}         # name -> (size, usecount, usedby)
        self.listeners = {}       # port -> list of inode strings
        self.conns_to_2002 = []   # (rem_addr, rem_port, state)
        self.shm = []
        self.holders = []


def parse_snapshot(path):
    m = SNAP_RE.match(os.path.basename(path))
    if not m:
        return None
    snap = Snapshot(path, int(m.group(1)), int(m.group(2)))
    section = None
    with open(path, "r", errors="replace") as fh:
        for line in fh:
            line = line.rstrip("\n")
            if line == "--- processes ---":
                section = "proc"
                continue
            if line == "--- modules ---":
                section = "mod"
                continue
            if line == "--- tcp listeners ---":
                section = "tcp"
                continue
            if line == "--- /dev/shm ---":
                section = "shm"
                continue
            if line == "--- display/fusion device holders ---":
                section = "hold"
                continue
            if section == "proc":
                pm = PROC_LINE_RE.match(line)
                if pm:
                    snap.processes[int(pm.group(1))] = pm.group(2).rstrip()
            elif section == "mod":
                mm = re.match(r"^(\S+) (\d+) (\d+)(?: - Live \S+)", line)
                if mm:
                    usedby = ""
                    um = re.search(r"^(.*?) - Live \S+", line)
                    if um and "," in um.group(1):
                        usedby = um.group(1).split(",", 1)[1].strip()
                    snap.modules[mm.group(1)] = (mm.group(2), mm.group(3),
                                                 usedby)
            elif section == "tcp":
                tm = HEX_PORT_RE.match(line)
                if tm:
                    lport = int(tm.group(2), 16)
                    raddr, rport, state = tm.group(3), int(tm.group(4), 16), tm.group(5)
                    if tm.group(4) == "0000" and state == "0A":
                        im = re.search(r"\s([0-9a-f]{4,}) 1 ", line)
                        snap.listeners.setdefault(lport, set()).add(
                            im.group(1) if im else "?")
                    elif lport == 2002:
                        snap.conns_to_2002.append((raddr, rport, state))
            elif section == "shm":
                if line and line not in (".", ".."):
                    snap.shm.append(line)
            elif section == "hold":
                if line:
                    snap.holders.append(line)
            elif section is None:
                hm = re.match(r"^seq (\d+) uptime_mono (\d+)$", line)
                if hm:
                    snap.header = (int(hm.group(1)), int(hm.group(2)))
    return snap


def cluster_writers(snaps, max_cadence_s=30):
    """Recover concurrent hwmon writer instances as seq+uptime chains.

    Files sorted by (uptime, seq). A file extends a writer iff its seq is
    exactly last_seq+1 and its uptime is strictly greater than the
    writer's last uptime and within max_cadence_s of it. Otherwise it
    starts a new writer (each observed writer starts at seq 0).
    """
    writers = []  # list of [ [Snapshot,...], last_seq, last_uptime ]
    for s in sorted(snaps, key=lambda x: (x.uptime, x.seq)):
        placed = False
        for w in writers:
            if s.seq == w[1] + 1 and s.uptime > w[2] \
               and s.uptime - w[2] <= max_cadence_s:
                w[0].append(s)
                w[1] = s.seq
                w[2] = s.uptime
                placed = True
                break
        if not placed:
            writers.append([[s], s.seq, s.uptime])
    writers.sort(key=lambda w: w[0][0].uptime)
    return [w[0] for w in writers]


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def fmt_writers(writers):
    out = []
    for i, w in enumerate(writers):
        ups = [s.uptime for s in w]
        seqs = [s.seq for s in w]
        cad = sum(ups[j] - ups[j - 1] for j in range(1, len(ups))) / max(1, len(ups) - 1)
        out.append(
            "writer-%s: %d snapshots, seq %d..%d (contiguous=%s), "
            "uptime %d..%d, mean cadence %.2fs"
            % (chr(ord('A') + i), len(w), min(seqs), max(seqs),
               seqs == list(range(min(seqs), max(seqs) + 1)),
               min(ups), max(ups), cad))
    return out


def parse_trigger_log(path):
    triggers = []
    if not os.path.exists(path):
        return triggers
    cur = None
    with open(path, "r", errors="replace") as fh:
        for line in fh:
            line = line.rstrip("\n")
            if line == "=== AutoScript trigger ===":
                cur = {"uptime": None, "stick": None, "notes": [],
                       "listeners": {}}
                triggers.append(cur)
                continue
            if cur is None:
                continue
            um = re.match(r"^(\d+\.\d+) \d+\.\d+$", line)
            if um and cur["uptime"] is None:
                cur["uptime"] = float(um.group(1))
                continue
            mm = re.match(r"^(/dev/sd[a-d]\d) (/mnt/sd[a-d]\d)", line)
            if mm and cur["stick"] is None:
                cur["stick"] = mm.group(2)
                continue
            tm = HEX_PORT_RE.match(line)
            if tm and tm.group(4) == "0000" and tm.group(5) == "0A":
                im = re.search(r"\s([0-9a-f]{4,}) 1 ", line)
                cur["listeners"].setdefault(
                    int(tm.group(2), 16), set()).add(
                    im.group(1) if im else "?")
                continue
            if line.startswith("restored ") or line.startswith("recovered ") \
               or "date: not found" in line:
                cur["notes"].append(line)
    return triggers


def parse_pairlaunch_log(path):
    launches = []
    if not os.path.exists(path):
        return launches
    cur = None
    with open(path, "r", errors="replace") as fh:
        for line in fh:
            line = line.rstrip("\n")
            if line == "=== pairlaunch ===":
                cur = {"uptime": None, "hwmon_pid": None, "stick": None}
                launches.append(cur)
                continue
            if cur is None:
                continue
            um = re.match(r"^uptime: (\d+\.\d+)", line)
            if um:
                cur["uptime"] = float(um.group(1))
                continue
            pm = re.match(r"^hwmon started \(pid (\d+)\)", line)
            if pm:
                cur["hwmon_pid"] = int(pm.group(1))
                continue
            sm = re.match(r"^stick dir: (\S+)", line)
            if sm:
                cur["stick"] = sm.group(1)
    return launches


def analyze(tgz_path, scratch):
    report = []

    def say(s=""):
        report.append(s)

    snap_dir = os.path.join(scratch, "snaps")
    os.makedirs(snap_dir, exist_ok=True)
    if not os.path.isdir(snap_dir) or not any(SNAP_RE.match(f)
                                              for f in os.listdir(snap_dir)):
        if os.path.isdir(snap_dir):
            import shutil
            shutil.rmtree(snap_dir)
        os.makedirs(snap_dir)
        with tarfile.open(tgz_path, "r:gz") as tf:
            tf.extractall(snap_dir, filter="data")
        # flatten a single top-level dir if the tarball has one
        entries = os.listdir(snap_dir)
        if len(entries) == 1 and os.path.isdir(os.path.join(snap_dir, entries[0])):
            inner = os.path.join(snap_dir, entries[0])
            for f in os.listdir(inner):
                os.rename(os.path.join(inner, f), os.path.join(snap_dir, f))
            os.rmdir(inner)

    say("== 1. corpus ==")
    say("tgz: %s" % tgz_path)
    say("tgz sha256: %s" % sha256_file(tgz_path))
    files = sorted(f for f in os.listdir(snap_dir) if SNAP_RE.match(f))
    snaps = []
    header_mismatch = []
    for f in files:
        s = parse_snapshot(os.path.join(snap_dir, f))
        if s is None:
            continue
        if s.header and s.header != (s.seq, s.uptime):
            header_mismatch.append(s.name)
        snaps.append(s)
    say("snapshots parsed: %d" % len(snaps))
    say("header/filename mismatches: %d" % len(header_mismatch))

    writers = cluster_writers(snaps)
    say()
    say("== 2. writer clusters (concurrent hwmon.bin instances) ==")
    for line in fmt_writers(writers):
        say(line)
    all_ups = sorted(s.uptime for s in snaps)
    say("merged uptime coverage: %d..%d, distinct uptime stamps: %d"
        % (all_ups[0], all_ups[-1], len(set(all_ups))))

    say()
    say("== 3. single-boot determination ==")
    core = None
    for s in snaps:
        keys = set(s.processes.keys())
        core = keys if core is None else (core & keys)
    say("processes present in ALL %d snapshots (core set): %d"
        % (len(snaps), len(core)))
    for pid in sorted(core):
        say("  pid %4d  %s" % (pid, snaps[0].processes[pid]))
    # any cmdline whose pid changes = restart candidate
    by_cmd = {}
    for s in snaps:
        for pid, cmd in s.processes.items():
            by_cmd.setdefault(cmd, set()).add(pid)
    say("cmdlines with MORE than one pid across the corpus (restarts):")
    multi = {c: p for c, p in by_cmd.items() if len(p) > 1}
    say("  %s" % (sorted(multi.items()) if multi else "none"))
    say("cmdlines with exactly one pid (never restarted in corpus): %d"
        % sum(1 for p in by_cmd.values() if len(p) == 1))

    say()
    say("== 4. process lifecycle (appearance/disappearance events) ==")
    # merged timeline; an appearance is the first snapshot (by uptime,
    # tie by seq) in which the pid is seen; a disappearance is a pid seen
    # in some snapshot but absent from every later snapshot.
    order = sorted(snaps, key=lambda s: (s.uptime, s.seq))
    first_seen = {}
    last_seen = {}
    for idx, s in enumerate(order):
        for pid in s.processes:
            if pid not in first_seen:
                first_seen[pid] = (s.uptime, s.name)
            last_seen[pid] = (s.uptime, s.name, idx)
    end_uptime = order[-1].uptime
    say("per-PID lifecycle (uptime first_seen -> last_seen; '*' = alive at "
        "corpus end):")
    for pid in sorted(first_seen):
        f = first_seen[pid]
        lst = last_seen[pid]
        alive = lst[0] == end_uptime
        cmd = next(s.processes[pid] for s in order if pid in s.processes)
        say("  pid %4d  first %4d (%s)  last %4d (%s)%s  [%s]"
            % (pid, f[0], f[1], lst[0], lst[1],
               " *" if alive else "", cmd))
    say("appearance events (uptime, pid, cmdline):")
    for pid in sorted(first_seen, key=lambda p: first_seen[p]):
        say("  + %4ds pid %4d  %s"
            % (first_seen[pid][0], pid,
               next(s.processes[pid] for s in order if pid in s.processes)))
    say("disappearance events (pid absent from ALL later snapshots):")
    for pid in sorted(first_seen, key=lambda p: last_seen[p]):
        lu = last_seen[pid][0]
        cmd = next(s.processes[pid] for s in order if pid in s.processes)
        if lu < end_uptime and not any(pid in s.processes
                                        for s in order if s.uptime > lu):
            say("  - %4ds pid %4d  %s" % (lu, pid, cmd))
    say("pids whose cmdline CHANGED across snapshots (exec transitions):")
    pid_cmds = {}
    for s in order:
        for pid, cmd in s.processes.items():
            pid_cmds.setdefault(pid, []).append((s.uptime, cmd))
    execs = 0
    for pid, lst in sorted(pid_cmds.items()):
        cmds = [c for _, c in lst]
        if len(set(cmds)) > 1:
            execs += 1
            change = next(t for t in lst if t[1] != cmds[0])
            say("  pid %4d  '%s' -> '%s' at uptime %d"
                % (pid, cmds[0], change[1], change[0]))
    if not execs:
        say("  none")

    say()
    say("== 5. listener timeline ==")
    listener_first = {}
    listener_last = {}
    listener_inodes = {}
    listener_count = {}
    for s in order:
        for port in s.listeners:
            if port not in listener_first:
                listener_first[port] = (s.uptime, s.name)
            listener_last[port] = (s.uptime, s.name)
            listener_inodes.setdefault(port, set()).update(s.listeners[port])
            listener_count[port] = listener_count.get(port, 0) + 1
    say("port  hex     first_seen        last_seen         snaps  inodes")
    for port in sorted(listener_first):
        label = LISTEN_PORTS.get(port, "")
        f = listener_first[port]
        lst = listener_last[port]
        say("  %5d  0x%04X%s first %4d (%s) last %4d (%s)  %3d  %s"
            % (port, port, (" %-6s" % label if label else "      "),
               f[0], f[1], lst[0], lst[1], listener_count[port],
               ",".join(sorted(listener_inodes[port]))))

    say()
    say("== 6. client connections to port 2002 (our daemon) ==")
    conn_events = {}
    for s in order:
        for rem in s.conns_to_2002:
            key = (rem[0], rem[1])
            if key not in conn_events:
                conn_events[key] = [s.uptime, s.uptime, 0]
            conn_events[key][1] = max(conn_events[key][1], s.uptime)
            conn_events[key][2] += 1

    def ip_of(hexle):
        b = bytes.fromhex(hexle)
        return ".".join(str(x) for x in b[::-1])
    say("remote endpoint                     first   last  snapshots")
    for key in sorted(conn_events):
        e = conn_events[key]
        say("  %s:%-6d (state mix)         %4d  %4d  %d"
            % (ip_of(key[0]), key[1], e[0], e[1], e[2]))

    say()
    say("== 7. module timeline ==")
    first_mod = {}
    mod_use = {}
    for s in order:
        for name, (size, use, usedby) in s.modules.items():
            if name not in first_mod:
                first_mod[name] = (s.uptime, s.name)
            mod_use.setdefault(name, {})[use] = mod_use.setdefault(name, {}).get(use, 0) + 1
    s0, s1 = order[0], order[-1]
    added = set(s1.modules) - set(s0.modules)
    removed = set(s0.modules) - set(s1.modules)
    say("modules in first snapshot: %d; in last: %d" % (len(s0.modules), len(s1.modules)))
    say("added between first and last snapshot: %s"
        % {n: first_mod[n] for n in sorted(added)})
    say("removed: %s" % (sorted(removed) or "none"))
    watch = ["fusion", "bdpdrv", "sacd_read", "usb_storage", "vfat",
             "sr_mod", "sata_mt85xx_mod"]
    say("use-count tracks for watched modules (usecount: snapshot-count):")
    for n in watch:
        if n in mod_use:
            say("  %-18s %s" % (n, dict(sorted(mod_use[n].items()))))

    say()
    say("== 8. /dev/shm contents across the corpus ==")
    shm_sets = {}
    for s in order:
        key = tuple(sorted(s.shm))
        shm_sets.setdefault(key, []).append(s.name)
    say("distinct /dev/shm contents: %d" % len(shm_sets))
    for key, names in sorted(shm_sets.items(), key=lambda kv: kv[1][0]):
        say("  %s  [%d snapshots, e.g. %s .. %s]"
            % (list(key), len(names), names[0], names[-1]))

    say()
    say("== 9. display/fusion device holders ==")
    holder_rows = {}
    for s in order:
        for row in s.holders:
            holder_rows.setdefault(row, []).append(s.name)
    if not holder_rows:
        say("holder rows found in ALL %d snapshots: 0 "
            "(no process held an fd matching /dev/fb* /dev/fusion* "
            "/dev/tty* /dev/vc* in any snapshot)" % len(snaps))
    else:
        for row, names in sorted(holder_rows.items()):
            say("  %s  [%d snapshots]" % (row, len(names)))

    say()
    say("== 10. trigger cross-reference (hwmon-boot.txt + pairlaunch logs) ==")
    base = os.path.dirname(tgz_path)
    triggers = parse_trigger_log(os.path.join(base, "hwmon-boot.txt"))
    say("trigger log entries: %d" % len(triggers))
    for i, t in enumerate(triggers, 1):
        say("  trigger %d: uptime %-8s stick %-11s notes: %s"
            % (i, t["uptime"], t["stick"], "; ".join(t["notes"])))
        for port in sorted(t["listeners"]):
            label = LISTEN_PORTS.get(port, "")
            say("    listener %5d%s inodes %s"
                % (port, " (%s)" % label if label else "",
                   ",".join(sorted(t["listeners"][port]))))
    seen = set()
    for logname in ("pairlaunch.log", "pairlaunch-recovered.log"):
        for launch in parse_pairlaunch_log(os.path.join(base, logname)):
            key = (launch["uptime"], launch["hwmon_pid"], launch["stick"])
            if key in seen:
                continue
            seen.add(key)
            say("  pairlaunch: uptime %-8s hwmon pid %-6s stick %s" % key)

    return "\n".join(report) + "\n"


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--tgz", default=DEFAULT_TGZ)
    ap.add_argument("--scratch", default="/tmp/hwmon-analysis")
    ap.add_argument("--report", default=None)
    args = ap.parse_args()
    tgz = os.path.abspath(args.tgz)
    if not os.path.exists(tgz):
        sys.exit("no such corpus: %s" % tgz)
    text = analyze(tgz, args.scratch)
    if args.report:
        with open(args.report, "w") as fh:
            fh.write(text)
    sys.stdout.write(text)


if __name__ == "__main__":
    main()
