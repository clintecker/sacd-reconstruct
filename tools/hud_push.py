#!/usr/bin/env python3
"""hud_push.py — host-side pusher for the BX510 SACD HUD (H3, T2 host channel).

Sends capture-job state as UDP datagrams to the player's HUD, which binds
UDP 20023 (tools/bx510_sacd_hud.c, HUD_UDP_PORT) and parses them in
udp_poll() -> host_push_parse(). One datagram per line, ASCII.

Wire grammar (VERIFIED against host_push_parse(); the C parser is the
authority, this file's parse_host_push() is its line-for-line mirror):

    RANGE done=<n> total=<n>      sectors ripped so far / disc total sectors
    RATE  mbs=<x.x>               measured throughput, MB/s (decimal float)
    VERIFY status=ok|fail|run     verify result (optionally " bad=<n>" after
                                  the status token; the HUD keeps status only)
    ETA   s=<n>                   seconds remaining

Unknown lines are ignored by the host-push parser and fall through to the
legacy "READ lsn=..." client-report handling. Unknown KEY=value shapes on a
known verb are rejected by sscanf and left unhandled (hpush_have stays 0).

RANGE and VERIFY lines are also echoed into the HUD event stream / event
matrix (a verify FAIL lights the ERROR class); RATE and ETA only update the
panels — RATE repeats every second during a capture and would flood the
ticker.

Usage:
    hud_push.py --host 10.20.1.236 --range 532104 1064208 --rate 4.7 \
                --verify ok --eta 120
    hud_push.py --host 10.20.1.236 --demo            # fake capture progression
    hud_push.py --selftest                           # loopback round-trip test

`hostctl/` (HUD-DESIGN.md T2, phase-2 skeleton) is the intended caller; this
script is also usable by hand and by the Mac-side selftest.
"""
import argparse
import os
import re
import socket
import sys
import time

DEFAULT_PORT = 20023
DEFAULT_HOST = os.environ.get("HUD_PUSH_HOST", "127.0.0.1")


# ---- line formatters (single source of the wire grammar) --------------------
def range_line(done, total):
    return f"RANGE done={int(done)} total={int(total)}"


def rate_line(mbs):
    return f"RATE mbs={float(mbs):.2f}"


def verify_line(status, bad=None):
    ln = f"VERIFY status={status}"
    if bad is not None:
        ln += f" bad={int(bad)}"
    return ln


def eta_line(seconds):
    return f"ETA s={int(seconds)}"


# ---- parser: mirror of host_push_parse() in bx510_sacd_hud.c ---------------
# Same prefixes, same "sscanf" shapes. Returns a dict per line, None if the
# line is not a well-formed host-push verb (the HUD would then treat it as a
# legacy client-report line instead).
_RANGE_RE = re.compile(r"^done=(\d+)\s+total=(\d+)")
_RATE_RE = re.compile(r"^mbs=(\d+(?:\.\d+)?)")
_VERIFY_RE = re.compile(r"^status=(\S+)")
_ETA_RE = re.compile(r"^s=(\d+)")


def parse_host_push(line):
    """Mirror of the C parser. Returns a dict with the verb's fields, or None."""
    b = line.rstrip("\r\n")
    if b.startswith("RANGE "):
        m = _RANGE_RE.match(b[6:])
        if m:
            return {"verb": "RANGE", "done": int(m.group(1)), "total": int(m.group(2))}
        return None
    if b.startswith("RATE "):
        m = _RATE_RE.match(b[5:])
        if m:
            return {"verb": "RATE", "mbs": float(m.group(1))}
        return None
    if b.startswith("VERIFY "):
        m = _VERIFY_RE.match(b[7:])
        if m:
            return {"verb": "VERIFY", "status": m.group(1)}
        return None
    if b.startswith("ETA "):
        m = _ETA_RE.match(b[4:])
        if m:
            return {"verb": "ETA", "s": int(m.group(1))}
        return None
    return None


# ---- send path --------------------------------------------------------------
def send(host, port, lines, timeout=2.0):
    """Send one datagram per line. Returns the socket used (already closed)."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(timeout)
    try:
        for ln in lines:
            s.sendto(ln.encode("ascii"), (host, port))
    finally:
        s.close()


def demo_lines(steps=20, rate=4.7, total=1064208):
    """A plausible capture progression: RANGE grows, ETA falls, VERIFY ok."""
    lines = []
    for i in range(1, steps + 1):
        done = total * i // steps
        lines.append(range_line(done, total))
        lines.append(rate_line(rate))
        remaining = max(0, int((total - done) / (rate * 1024 * 1024 / 2048)))
        lines.append(eta_line(remaining))
    lines.append(verify_line("ok"))
    return lines


def selftest():
    """Loopback round-trip: formatters -> real UDP datagrams -> mirror parser.

    Exercises the exact send path (sendto over 127.0.0.1) and the exact
    grammar strings the C parser must accept. The C side itself is checked by
    tools/test_hud_push.py, which runs this script's output through a
    HUD_SIM build of bx510_sacd_hud.c (HUD_INGEST).
    """
    cases = [
        (range_line(532104, 1064208), {"verb": "RANGE", "done": 532104, "total": 1064208}),
        (rate_line(4.7), {"verb": "RATE", "mbs": 4.7}),
        (verify_line("ok"), {"verb": "VERIFY", "status": "ok"}),
        (verify_line("fail", bad=3), {"verb": "VERIFY", "status": "fail"}),
        (verify_line("run"), {"verb": "VERIFY", "status": "run"}),
        (eta_line(120), {"verb": "ETA", "s": 120}),
    ]
    srv = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    srv.bind(("127.0.0.1", 0))
    srv.settimeout(5.0)
    port = srv.getsockname()[1]
    send("127.0.0.1", port, [ln for ln, _ in cases])
    ok = True
    for ln, want in cases:
        data, _addr = srv.recvfrom(2048)
        got = parse_host_push(data.decode("ascii"))
        if got != want:
            print(f"FAIL {ln!r}: parsed {got!r}, want {want!r}")
            ok = False
        else:
            print(f"ok   {ln!r} -> {got}")
    # negatives: unknown verb, known verb with a malformed body
    negatives = ("WAT done=1 total=2", "RANGE done=1", "VERIFY status=")
    send("127.0.0.1", port, list(negatives))
    for ln in negatives:
        data, _addr = srv.recvfrom(2048)
        got = parse_host_push(data.decode("ascii"))
        if got is not None:
            print(f"FAIL negative {ln!r}: parsed {got!r}, want None")
            ok = False
        else:
            print(f"ok   {ln!r} -> None (falls through to legacy handling)")
    srv.close()
    print("SELFTEST: PASS" if ok else "SELFTEST: FAIL")
    return 0 if ok else 1


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--host", default=DEFAULT_HOST,
                    help=f"HUD host (default {DEFAULT_HOST}, env HUD_PUSH_HOST)")
    ap.add_argument("--port", type=int, default=DEFAULT_PORT,
                    help=f"HUD UDP port (default {DEFAULT_PORT})")
    ap.add_argument("--range", nargs=2, type=int, metavar=("DONE", "TOTAL"))
    ap.add_argument("--rate", type=float, metavar="MBS")
    ap.add_argument("--verify", choices=("ok", "fail", "run"))
    ap.add_argument("--bad", type=int, help="failed-sector count with --verify fail")
    ap.add_argument("--eta", type=int, metavar="SECONDS")
    ap.add_argument("--demo", action="store_true",
                    help="send a fake capture progression instead of one-shot flags")
    ap.add_argument("--steps", type=int, default=20, help="demo progression steps")
    ap.add_argument("--interval", type=float, default=0.25,
                    help="seconds between demo datagrams")
    ap.add_argument("--selftest", action="store_true", help="loopback round-trip test")
    args = ap.parse_args(argv)

    if args.selftest:
        return selftest()

    lines = []
    if args.demo:
        lines = demo_lines(steps=args.steps)
    else:
        if args.range:
            lines.append(range_line(args.range[0], args.range[1]))
        if args.rate is not None:
            lines.append(rate_line(args.rate))
        if args.verify:
            lines.append(verify_line(args.verify, bad=args.bad))
        if args.eta is not None:
            lines.append(eta_line(args.eta))
    if not lines:
        ap.error("nothing to send: use --range/--rate/--verify/--eta or --demo")
    for ln in lines:
        send(args.host, args.port, [ln])
        if args.demo and args.interval > 0:
            time.sleep(args.interval)
    print(f"HUD-PUSH: sent {len(lines)} datagram(s) to {args.host}:{args.port}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
