#!/usr/bin/env python3
"""Minimal GDB remote-serial-protocol client for the BX510 QEMU rig.

Why this exists: the lab VM's /usr/bin/gdb is an x86-only build ("Target
description specified unknown architecture arm"), so it cannot debug the
guest ARM core.  QEMU's gdbstub (:1234, `-s`) speaks plain RSP, so this
drives it directly: register reads, hardware watchpoints, hardware
breakpoints, single-step, and RAM reads.  Every packet in both directions
is printed, so the transcript is evidence in itself.

First use: the FE-SRAM readback experiment in
`evidence/bx510-guest/bdpdrv/decode/sram-readback-live.md` (watch the fixed
guest VA 0xfd324184, then hbreak the module once its base falls out of the
first hit).

Commands (one per line, stdin; a FIFO works, so a session can be driven
interactively while the guest runs):

  q <payload>          raw RSP packet, prints the reply
  g                    read all registers (r0-r15, cpsr)
  watch <addr> [len]   Z4 access watchpoint (fires on read AND write)
  rwatch <addr> [len]  Z3 read watchpoint
  wwatch <addr> [len]  Z2 write watchpoint
  unwatch <addr> [len] removes the Z4 access watchpoint
  hb <addr>            Z1 hardware breakpoint (ARM, kind=4)
  unhb <addr>          z1 removal
  c                    continue, prints the stop reply
  s                    single-step, prints the stop reply
  m <addr> <len>       read guest memory (hex), prints hex bytes
  w <addr> <n>         read n 32-bit words, prints little-endian values
  # ...                comment / no-op
"""
import socket
import sys
import time

REGNAMES = ["r0", "r1", "r2", "r3", "r4", "r5", "r6", "r7",
            "r8", "r9", "r10", "r11", "r12", "sp", "lr", "pc"]


def out(*a):
    print(*a)
    sys.stdout.flush()


class Rsp:
    def __init__(self, host="127.0.0.1", port=1234, deadline_s=25.0):
        end = time.time() + deadline_s
        while True:
            try:
                self.s = socket.create_connection((host, port), timeout=5)
                break
            except OSError:
                if time.time() > end:
                    raise
                time.sleep(0.2)
        self.s.settimeout(600)

    def recv_packet(self):
        while True:
            c = self.s.recv(1)
            if not c:
                raise EOFError("gdbstub closed the connection")
            if c in (b"+", b"-"):
                continue
            if c == b"$":
                break
        payload = b""
        while True:
            c = self.s.recv(1)
            if c == b"#":
                break
            payload += c
        self.s.recv(2)          # checksum (not validated)
        self.s.sendall(b"+")
        return payload.decode("latin-1")

    def cmd(self, payload):
        data = payload.encode("latin-1")
        self.s.sendall(b"$" + data + b"#%02x" % (sum(data) % 256))
        reply = self.recv_packet()
        out(">> %-30s << %s" % (payload, reply))
        return reply

    def regs(self):
        g = self.cmd("g")
        words = [int.from_bytes(bytes.fromhex(g[i:i + 8]), "little")
                 for i in range(0, len(g), 8)]
        vals = {}
        for i, name in enumerate(REGNAMES):
            vals[name] = words[i]
        # ARM32 g packet = 17 regs: r0-r15 then cpsr
        vals["cpsr"] = words[16] if len(words) > 16 else 0
        vals["_nregs"] = len(words)
        out("   nregs=%d  " % len(words) +
            " ".join("%s=%08x" % (n, vals[n]) for n in REGNAMES) +
            " cpsr=%08x" % vals["cpsr"])
        return vals

    def read_mem(self, addr, length):
        r = self.cmd("m%x,%x" % (addr, length))
        if r.startswith("E"):
            return None
        return bytes.fromhex(r)


def main():
    r = Rsp()
    out("# connected to gdbstub")
    for line in sys.stdin:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        f = line.split()
        op = f[0]
        if op == "q":
            r.cmd(line[2:])
        elif op == "g":
            r.regs()
        elif op in ("watch", "rwatch", "wwatch"):
            t = {"watch": "4", "rwatch": "3", "wwatch": "2"}[op]
            length = int(f[2], 0) if len(f) > 2 else 4
            r.cmd("Z%s,%x,%x" % (t, int(f[1], 0), length))
        elif op == "unwatch":
            # unwatch <addr> [len]  -> removes the Z4 access watchpoint
            length = int(f[2], 0) if len(f) > 2 else 4
            r.cmd("z4,%x,%x" % (int(f[1], 0), length))
        elif op == "hb":
            r.cmd("Z1,%x,4" % int(f[1], 0))
        elif op == "unhb":
            r.cmd("z1,%x,4" % int(f[1], 0))
        elif op in ("c", "s"):
            reply = r.cmd(op)
            if reply.startswith("T"):
                for part in reply[3:].split(";"):
                    if part.startswith("watch:") or part.startswith("rwatch:") \
                            or part.startswith("awatch:"):
                        out("   [%s]" % part)
        elif op == "m":
            b = r.read_mem(int(f[1], 0), int(f[2], 0))
            out("   %s: %s" % (f[1], b.hex() if b is not None else "<err>"))
        elif op == "w":
            n = int(f[2], 0)
            b = r.read_mem(int(f[1], 0), 4 * n)
            if b is None:
                out("   <read error>")
            else:
                out("   " + " ".join(
                    "%08x" % int.from_bytes(b[i:i + 4], "little")
                    for i in range(0, 4 * n, 4)))
        else:
            out("# unknown command: %r" % line)
    out("# stdin closed, detaching")


if __name__ == "__main__":
    main()
