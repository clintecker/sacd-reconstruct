#!/usr/bin/env python3
"""fakesacd.py — fake BX510 daemon for the client selftest (pre-staging check).

Replays the protocol-decode §10 predicted bytes: DISC_OPEN ok, DISC_SIZE,
DISC_READ from the Firebird fixture (LBA 510 x10 -> md5 45ccd7df...), CLOSE.
Verifies the client's request bytes byte-for-byte against the §9 table.
"""
import socket
import sys

REQ_OPEN = bytes.fromhex("080110001800 00".replace(" ", ""))
REQ_SIZE = bytes.fromhex("080410001800 00".replace(" ", ""))
# DISC_READ lba=510 cnt=10: 08 03 10 fe 03 18 0a 00
REQ_READ_510_10 = bytes.fromhex("080310 fe03 180a 00".replace(" ", ""))
REQ_CLOSE = bytes.fromhex("080210001800 00".replace(" ", ""))

REP_OPEN = bytes.fromhex("08011000 00".replace(" ", ""))           # type=1 result=0
# 1_064_208 varint: 0x103DB0 -> B0 FB 04
REP_SIZE = bytes.fromhex("080410 90fa40 00".replace(" ", ""))      # type=4 result=1_064_208
REP_CLOSE = bytes.fromhex("08021000 00".replace(" ", ""))          # type=2

FIXTURE = sys.argv[1] if len(sys.argv) > 1 else None
if FIXTURE:
    with open(FIXTURE, "rb") as f:
        f.seek(510 * 2048)
        TOC10 = f.read(10 * 2048)
    assert len(TOC10) == 20480, len(TOC10)
else:
    TOC10 = bytes(range(256)) * 80

# response: type=3 (08 03), result=10 (10 0a), data len=20480 (1a 80 a0 01),
# payload, terminator 00
REP_READ = bytes([0x08, 0x03, 0x10, 0x0A, 0x1A, 0x80, 0xA0, 0x01]) + TOC10 + b"\x00"

EXPECTED = [REQ_OPEN, REQ_SIZE, REQ_READ_510_10, REQ_CLOSE]
REPLIES = [REP_OPEN, REP_SIZE, REP_READ, REP_CLOSE]

failures = []

def serve(conn):
    for i, (want, reply) in enumerate(zip(EXPECTED, REPLIES)):
        got = b""
        while len(got) < len(want):
            d = conn.recv(4096)
            if not d:
                failures.append(f"client sent {len(got)}B, wanted {len(want)}B at step {i}")
                conn.close()
                return
            got += d
        if got != want:
            failures.append(f"step {i}: got {got.hex()} want {want.hex()}")
        conn.sendall(reply)
    conn.close()   # the daemon closes after DISC_CLOSE (protocol §3.2)

srv = socket.socket()
srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind(("127.0.0.1", 20222))
srv.listen(1)
print("fakesacd listening on 20222", flush=True)
c, _ = srv.accept()
serve(c)
srv.close()
for f in failures:
    print("MISMATCH:", f, flush=True)
print("FAKE_DONE_OK" if not failures else "FAKE_DONE_FAIL")
