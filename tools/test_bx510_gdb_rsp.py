#!/usr/bin/env python3
"""Selftest for tools/bx510_gdb_rsp.py — RSP framing + register decode.

The live evidence in `evidence/bx510-guest/bdpdrv/decode/sram-readback-live.md`
rests on this client: the effective address of the FE-SRAM read is computed as
`r1 - 0xe7b` out of a `g` packet, so a framing or decode error here would be
indistinguishable from a wrong address in the driver. This drives the client
against an in-process fake stub (no QEMU, no hardware) and locks the two things
that matter:

  1. checksum + ack handling (the stub acks with '+' before its reply, as QEMU
     does, so a client that does not skip acks would read 'garbage');
  2. little-endian register decode, r15 == pc, r16-of-`g` == cpsr, and the
     address arithmetic the evidence depends on (`0xfd324fff - 0xe7b`).

Run directly (python3 tools/test_bx510_gdb_rsp.py) or via pytest.
"""
import socket
import sys
import threading
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import bx510_gdb_rsp as rsp  # noqa: E402


def _packet(payload):
    data = payload.encode("latin-1")
    return b"$" + data + b"#%02x" % (sum(data) % 256)


class FakeStub:
    """Minimal RSP server: records every packet, answers from a script."""

    def __init__(self, replies):
        self.replies = list(replies)
        self.received = []          # [(payload, checksum-hex)]
        self._srv = socket.socket()
        self._srv.bind(("127.0.0.1", 0))
        self._srv.listen(1)
        self.port = self._srv.getsockname()[1]
        threading.Thread(target=self._run, daemon=True).start()

    def _run(self):
        conn, _ = self._srv.accept()
        buf = b""
        while True:
            while b"$" not in buf:
                chunk = conn.recv(4096)
                if not chunk:
                    return
                buf += chunk
            buf = buf[buf.index(b"$") + 1:]
            while buf.count(b"#") == 0 or len(buf.split(b"#", 1)[1]) < 2:
                chunk = conn.recv(4096)
                if not chunk:
                    return
                buf += chunk
            payload, rest = buf.split(b"#", 1)
            csum, buf = rest[:2], rest[2:]
            self.received.append((payload.decode("latin-1"), csum.decode()))
            n = len(self.received) - 1
            reply = self.replies[n] if n < len(self.replies) else "OK"
            # QEMU acks the client packet before answering; the client must
            # skip the '+' and still parse the packet that follows.
            conn.sendall(b"+" + _packet(reply))


def _g_packet(regs):
    return "".join(w.to_bytes(4, "little").hex() for w in regs)


def test_watchpoint_and_register_decode_match_the_ldr_evidence():
    regs = [0] * 17
    regs[0] = 0xDD900000    # r0 = sata_int_ldr_fw (fw staging buffer)
    regs[1] = 0xFD324FFF    # r1 = literal .init.text+0x760
    regs[2] = 0x00000000    # r2 = loaded byte at .init.text+0x5cc (observed 0)
    regs[15] = 0xBF0405CC   # pc = .init.text+0x5cc, .init.text base 0xbf040000
    regs[16] = 0x80000153   # cpsr: SVC (0x13), IRQ masked
    stub = FakeStub(["OK", _g_packet(regs)])

    client = rsp.Rsp(port=stub.port)
    assert client.cmd("Z4,fd324184,4") == "OK"
    vals = client.regs()

    # framing: payload verbatim, checksum = sum(payload) mod 256
    payload, csum = stub.received[0]
    assert payload == "Z4,fd324184,4"
    assert csum == "%02x" % (sum(payload.encode()) % 256)

    # decode
    assert vals["pc"] == 0xBF0405CC
    assert vals["cpsr"] == 0x80000153
    assert vals["pc"] - 0x5CC == 0xBF040000          # .init.text runtime base
    assert vals["r1"] - 0xE7B == 0xFD324184         # THE address under test
    assert vals["r2"] == 0x00000000                 # readback-loop value


if __name__ == "__main__":
    test_watchpoint_and_register_decode_match_the_ldr_evidence()
    print("PASS bx510_gdb_rsp selftest (framing + register decode)")
