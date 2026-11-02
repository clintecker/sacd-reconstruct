#!/usr/bin/env python3
"""sacd_client.py — wire-level client for the sacd_extract port-2002 daemon.

Protocol (from the reconstructed source, verified against the reference
binary): nanopb-encoded protobuf messages over TCP, each frame terminated
by a single 0x00 tag byte. No length prefix.

  ServerRequest:  08 <type> 10 <offset> 18 <count> 00
  ServerResponse: 08 <type> 10 <result:int64> [1A <len> <data>] 00

Types: 1=DISC_OPEN 2=DISC_CLOSE 3=DISC_READ 4=DISC_SIZE
       responses: 1=DISC_OPENED 2=DISC_CLOSED 3=DISC_READ 4=DISC_SIZE
DISC_READ returns `result` = sectors read and `data` = result * 2048 bytes.
The server clamps block_size to MAX_PROCESSING_BLOCK_SIZE (128) and to the
disc encryption-range boundaries, so requested != returned must be recorded.
The server closes the connection after DISC_CLOSE.

Subcommands:
  capture   run the baseline sequence against a daemon, save evidence
  compare   diff two capture manifests
  selftest  run the capture sequence against an in-process fake server

Python 3.8+, stdlib only (macOS + Linux).
"""

import argparse
import datetime
import hashlib
import json
import os
import socket
import struct
import sys
import threading

CLIENT_VERSION = "sacd_client.py 1.0"

REQ_DISC_OPEN = 1
REQ_DISC_CLOSE = 2
REQ_DISC_READ = 3
REQ_DISC_SIZE = 4

RESP_NAMES = {
    1: "DISC_OPENED",
    2: "DISC_CLOSED",
    3: "DISC_READ",
    4: "DISC_SIZE",
}

LSN_SIZE = 2048


# ---------------------------------------------------------------- varints

def uvarint_encode(value):
    if value < 0:
        raise ValueError("use svarint_encode for negatives")
    out = bytearray()
    while True:
        b = value & 0x7F
        value >>= 7
        if value:
            out.append(b | 0x80)
        else:
            out.append(b)
            return bytes(out)


def uvarint_decode(buf, pos):
    """decode unsigned varint -> (value, newpos)"""
    result = 0
    shift = 0
    while True:
        if pos >= len(buf):
            raise ValueError("truncated varint")
        b = buf[pos]
        pos += 1
        result |= (b & 0x7F) << shift
        if not (b & 0x80):
            return result, pos
        shift += 7
        if shift > 63:
            raise ValueError("varint too long")


def svarint_encode(value):
    """int64 -> 10-byte two's-complement varint for negatives"""
    if value >= 0:
        return uvarint_encode(value)
    return uvarint_encode(value & ((1 << 64) - 1))


def svarint_decode(buf, pos):
    u, pos = uvarint_decode(buf, pos)
    if u >= (1 << 63):
        u -= (1 << 64)
    return u, pos


# ---------------------------------------------------------------- frames

def encode_request(req_type, sector_offset=0, sector_count=0):
    out = bytearray()
    out += b"\x08" + uvarint_encode(req_type)          # 1: type
    out += b"\x10" + uvarint_encode(sector_offset)     # 2: uint32
    out += b"\x18" + uvarint_encode(sector_count)      # 3: uint32
    out += b"\x00"                                     # end-of-request tag
    return bytes(out)


def parse_response(buf):
    """Parse one complete response frame (including trailing 0x00).

    Returns dict {type, result, has_data, data} or raises ValueError if
    the buffer is not a complete, well-formed frame.
    """
    pos = 0
    resp = {"type": None, "result": None, "has_data": False, "data": b""}
    while True:
        if pos >= len(buf):
            raise ValueError("incomplete frame")
        tag_wire, pos = uvarint_decode(buf, pos)
        if tag_wire == 0:
            if pos != len(buf):
                raise ValueError("trailing bytes after zero tag")
            if resp["type"] is None:
                raise ValueError("missing type field")
            if resp["result"] is None:
                raise ValueError("missing result field")
            return resp
        field = tag_wire >> 3
        wire = tag_wire & 7
        if field == 1 and wire == 0:
            resp["type"], pos = uvarint_decode(buf, pos)
        elif field == 2 and wire == 0:
            resp["result"], pos = svarint_decode(buf, pos)
        elif field == 3 and wire == 2:
            length, pos = uvarint_decode(buf, pos)
            if pos + length > len(buf):
                raise ValueError("incomplete data field")
            resp["data"] = bytes(buf[pos:pos + length])
            resp["has_data"] = True
            pos += length
        else:
            raise ValueError("unexpected field %d wire %d" % (field, wire))


class Connection:
    """One TCP connection to the daemon; records every raw frame.

    frame_sink: optional shared list collecting frames across connections.
    """

    def __init__(self, host, port, timeout=20.0, frame_sink=None):
        self.frames = []
        self.frame_sink = frame_sink
        self.sock = socket.create_connection((host, port), timeout=timeout)
        self.sock.settimeout(timeout)
        self.host = host
        self.port = port

    def close(self):
        try:
            self.sock.close()
        except OSError:
            pass

    def request(self, req_type, sector_offset=0, sector_count=0):
        wire = encode_request(req_type, sector_offset, sector_count)
        self.sock.sendall(wire)
        resp, raw = self._read_frame()
        frame = {
            "request": {
                "type": req_type,
                "sector_offset": sector_offset,
                "sector_count": sector_count,
            },
            "response": {
                "type": resp["type"],
                "type_name": RESP_NAMES.get(resp["type"], "?"),
                "result": resp["result"],
                "data_len": len(resp["data"]),
            },
            "request_frame_hex": wire.hex(),
            "response_frame_sha256": hashlib.sha256(raw).hexdigest(),
            "response_frame_len": len(raw),
        }
        self.frames.append(frame)
        if self.frame_sink is not None:
            self.frame_sink.append(frame)
        return resp

    def _read_frame(self):
        buf = bytearray()
        while True:
            try:
                chunk = self.sock.recv(65536)
            except socket.timeout:
                raise RuntimeError(
                    "timeout waiting for response frame (got %d bytes so far)"
                    % len(buf))
            if not chunk:
                raise RuntimeError(
                    "server closed connection mid-frame (got %d bytes)"
                    % len(buf))
            buf += chunk
            try:
                resp = parse_response(bytes(buf))
                return resp, bytes(buf)
            except ValueError:
                continue


# ---------------------------------------------------------------- capture

def run_sequence(host, port, log, frame_sink=None):
    """The baseline sequence. Returns per-read records."""
    reads = []

    def do_read(conn, lsn, count, label):
        resp = conn.request(REQ_DISC_READ, lsn, count)
        rec = {
            "label": label,
            "lsn": lsn,
            "requested_sectors": count,
            "returned_sectors": resp["result"],
            "data_len": len(resp["data"]),
            "payload_sha256": hashlib.sha256(resp["data"]).hexdigest()
            if resp["has_data"] else None,
        }
        reads.append(rec)
        log("  READ %-22s lsn=%d want=%d got=%s len=%d sha=%s" %
            (label, lsn, count, resp["result"], len(resp["data"]),
             (rec["payload_sha256"] or "")[:16]))
        return resp

    conn = Connection(host, port, frame_sink=frame_sink)
    try:
        resp = conn.request(REQ_DISC_OPEN)
        log("  OPEN  result=%s" % resp["result"])
        if resp["result"] is None or resp["result"] < 0:
            log("  !! DISC_OPEN returned %s — no disc / open failed" % resp["result"])

        resp = conn.request(REQ_DISC_SIZE)
        size = resp["result"]
        log("  SIZE  total_sectors=%s" % size)

        # 1-sector read at LSN 0
        do_read(conn, 0, 1, "one-sector @ 0")
        # 128-sector read at LSN 0 (server block cap; doubles as disc fingerprint)
        do_read(conn, 0, 128, "128-sector @ 0")
        # 1-sector read at mid-disc
        mid = max(0, (size or 0) // 2)
        do_read(conn, mid, 1, "one-sector @ mid(%d)" % mid)
        # reconnect test: close, reconnect, open, repeat the mid read
        resp = conn.request(REQ_DISC_CLOSE)
        log("  CLOSE result=%s" % resp["result"])
    finally:
        conn.close()

    # server closes the connection after DISC_CLOSE
    conn = Connection(host, port, frame_sink=frame_sink)
    try:
        resp = conn.request(REQ_DISC_OPEN)
        log("  OPEN  (reconnect) result=%s" % resp["result"])
        do_read(conn, mid, 1, "one-sector @ mid repeat (reconnect)")
        conn.request(REQ_DISC_CLOSE)
        log("  CLOSE (reconnect)")
    finally:
        conn.close()

    fingerprint = None
    for r in reads:
        if r["label"] == "128-sector @ 0":
            fingerprint = r["payload_sha256"]
    return {
        "disc_size_sectors": size,
        "reads": reads,
        "disc_fingerprint_lsn0_128": fingerprint,
    }


def cmd_capture(args):
    def log(msg):
        print(msg)
        with open(os.path.join(args.out, "capture.log"), "a") as f:
            f.write(msg + "\n")

    os.makedirs(args.out, exist_ok=True)
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime(
        "%Y-%m-%dT%H:%M:%SZ")
    log("sacd capture %s -> %s:%d" % (stamp, args.host, args.port))

    all_frames = []
    conn_seq = run_sequence(args.host, args.port, log, frame_sink=all_frames)

    manifest = {
        "client": CLIENT_VERSION,
        "captured_at": stamp,
        "target": {"host": args.host, "port": args.port},
        "firmware": args.firmware,
        "disc_id": args.disc_id,
        "label": args.label,
        "reference_daemon_sha256": args.daemon_sha,
        "disc_size_sectors": conn_seq.get("disc_size_sectors"),
        "disc_fingerprint_lsn0_128": conn_seq.get("disc_fingerprint_lsn0_128"),
        "reads": conn_seq["reads"],
        "frames": all_frames,
    }
    path = os.path.join(args.out, "manifest.json")
    with open(path, "w") as f:
        json.dump(manifest, f, indent=2)
    log("wrote %s" % path)
    return manifest


# ---------------------------------------------------------------- compare

def cmd_compare(args):
    a = json.load(open(args.a))
    b = json.load(open(args.b))
    print("A: %s  (firmware=%s disc=%s)" %
          (args.a, a.get("firmware"), a.get("disc_id")))
    print("B: %s  (firmware=%s disc=%s)" %
          (args.b, b.get("firmware"), b.get("disc_id")))
    ok = True
    ra = {(r["label"], r["lsn"], r["requested_sectors"]): r for r in a["reads"]}
    rb = {(r["label"], r["lsn"], r["requested_sectors"]): r for r in b["reads"]}
    if set(ra) != set(rb):
        ok = False
        print("READ SETS DIFFER: A-only=%s B-only=%s" %
              (set(ra) - set(rb), set(rb) - set(ra)))
    print("%-38s %-9s %-9s %-9s %s" %
          ("read", "A got", "B got", "A sha", "verdict"))
    for key in sorted(set(ra) & set(rb)):
        x, y = ra[key], rb[key]
        same = (x["returned_sectors"] == y["returned_sectors"]
                and x["payload_sha256"] == y["payload_sha256"])
        ok &= same
        print("%-38s %-9s %-9s %-9s %s" %
              (key[0], x["returned_sectors"], y["returned_sectors"],
               (x["payload_sha256"] or "")[:9],
               "IDENTICAL" if same else "DIFFERS"))
    if a.get("disc_size_sectors") != b.get("disc_size_sectors"):
        ok = False
    print("disc_size: %s vs %s" %
          (a.get("disc_size_sectors"), b.get("disc_size_sectors")))
    print("VERDICT:", "IDENTICAL" if ok else "DIFFERS")
    return 0 if ok else 1


# ---------------------------------------------------------------- selftest

def fake_sector(lsn, count):
    """Deterministic fake disc bytes."""
    out = bytearray()
    for i in range(count):
        hdr = struct.pack("<QII", 0xFAA0FAA0FAA0FAA0, lsn + i, 0x5A5A5A5A)
        body = bytes([0x41 + ((lsn + i) & 0x3F)]) * (LSN_SIZE - len(hdr))
        out += hdr + body
    return bytes(out)


class FakeServer(threading.Thread):
    """Implements the daemon protocol semantics (open/size/read/close)
    against a deterministic fake disc, to validate the client."""

    TOTAL = 10000

    def __init__(self):
        super().__init__(daemon=True)
        self.sock = socket.socket()
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.sock.bind(("127.0.0.1", 0))
        self.sock.listen(4)
        self.port = self.sock.getsockname()[1]
        self.stop = False

    def run(self):
        while not self.stop:
            try:
                client, _ = self.sock.accept()
            except OSError:
                return
            threading.Thread(target=self.serve, args=(client,),
                             daemon=True).start()

    def serve(self, client):
        try:
            buf = bytearray()
            opened = False
            while True:
                while True:
                    try:
                        req = parse_request(bytes(buf))
                        break
                    except ValueError:
                        chunk = client.recv(65536)
                        if not chunk:
                            return
                        buf += chunk
                buf = buf[req["consumed"]:]
                t = req["type"]
                if t == REQ_DISC_OPEN:
                    opened = True
                    data, result = b"", 0
                elif t == REQ_DISC_SIZE:
                    result, data = self.TOTAL, b""
                elif t == REQ_DISC_READ:
                    if not opened:
                        result, data = -1, b""
                    else:
                        n = min(req["sector_count"], self.TOTAL - req["sector_offset"],
                                128)
                        data = fake_sector(req["sector_offset"], max(0, n))
                        result = n
                elif t == REQ_DISC_CLOSE:
                    opened = False
                    result, data = 0, b""
                else:
                    result, data = -1, b""
                rtype = {1: 1, 2: 2, 3: 3, 4: 4}[t]
                out = bytearray()
                out += b"\x08" + uvarint_encode(rtype)
                out += b"\x10" + svarint_encode(result)
                if data:
                    out += b"\x1A" + uvarint_encode(len(data)) + data
                out += b"\x00"
                client.sendall(bytes(out))
                if t == REQ_DISC_CLOSE:
                    client.close()
                    return
        finally:
            try:
                client.close()
            except OSError:
                pass


def parse_request(buf):
    pos = 0
    req = {"type": None, "sector_offset": 0, "sector_count": 0}
    while True:
        if pos >= len(buf):
            raise ValueError("incomplete")
        tag, pos = uvarint_decode(buf, pos)
        if tag == 0:
            req["consumed"] = pos
            if req["type"] is None:
                raise ValueError("no type")
            return req
        field, wire = tag >> 3, tag & 7
        if field == 1 and wire == 0:
            req["type"], pos = uvarint_decode(buf, pos)
        elif field == 2 and wire == 0:
            req["sector_offset"], pos = uvarint_decode(buf, pos)
        elif field == 3 and wire == 0:
            req["sector_count"], pos = uvarint_decode(buf, pos)
        else:
            raise ValueError("bad request field")


def cmd_selftest(args):
    srv = FakeServer()
    srv.start()
    out = os.path.join(args.out, "selftest")
    os.makedirs(out, exist_ok=True)
    manifest = cmd_capture(argparse.Namespace(
        host="127.0.0.1", port=srv.port, out=out,
        firmware="fake", disc_id="selftest", label="selftest",
        daemon_sha=None))
    srv.stop = True
    expected = {
        "one-sector @ 0": hashlib.sha256(fake_sector(0, 1)).hexdigest(),
        "128-sector @ 0": hashlib.sha256(fake_sector(0, 128)).hexdigest(),
    }
    ok = True
    seen = {}
    for r in manifest["reads"]:
        want = hashlib.sha256(
            fake_sector(r["lsn"], r["requested_sectors"])).hexdigest()
        if r["payload_sha256"] != want or r["returned_sectors"] < 1:
            ok = False
            print("SELFTEST FAIL: %s (want %s)" % (r, want[:16]))
        seen.setdefault(r["label"], []).append(r["payload_sha256"])
    # the reconnect repeat must return the same payload as the first mid read
    mid_first = [v for k, v in seen.items()
                 if k.startswith("one-sector @ mid(") and "repeat" not in k]
    mid_rep = seen.get("one-sector @ mid repeat (reconnect)", [])
    if mid_first and mid_rep and mid_rep[0] != mid_first[0][0]:
        ok = False
        print("SELFTEST FAIL: reconnect repeat hash mismatch")
    if manifest["disc_size_sectors"] != srv.TOTAL:
        ok = False
        print("SELFTEST FAIL: size")
    print("SELFTEST:", "PASS" if ok else "FAIL")
    return 0 if ok else 1


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    sub = ap.add_subparsers(dest="cmd", required=True)

    c = sub.add_parser("capture", help="run baseline sequence, save evidence")
    c.add_argument("--host", required=True)
    c.add_argument("--port", type=int, default=2002)
    c.add_argument("--out", required=True, help="evidence output directory")
    c.add_argument("--firmware", default=None,
                   help="player model + firmware version (manual)")
    c.add_argument("--disc-id", default=None,
                   help="disc identifier, e.g. album + catalog no (manual)")
    c.add_argument("--label", default="baseline",
                   help="'baseline' (original daemon) or 'candidate'")
    c.add_argument("--daemon-sha", default=None,
                   help="SHA-256 of the daemon ELF running on the target")
    c.set_defaults(func=cmd_capture)

    m = sub.add_parser("compare", help="diff two capture manifests")
    m.add_argument("a")
    m.add_argument("b")
    m.set_defaults(func=cmd_compare)

    s = sub.add_parser("selftest", help="validate client against a fake server")
    s.add_argument("--out", default="/tmp")
    s.set_defaults(func=cmd_selftest)

    args = ap.parse_args()
    sys.exit(args.func(args))


if __name__ == "__main__":
    main()
