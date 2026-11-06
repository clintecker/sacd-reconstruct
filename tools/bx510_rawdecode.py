#!/usr/bin/env python3
"""Decode the in-guest raw protocol capture from a bx510_phase0_probe UART log.

The probe's --rawdump mode pushes the full both-direction capture through
the UART as hex lines (16 bytes/line, 32 chars — within the guest's safe
line length). The RX stream (gc-raw.bin, all bytes received by the in-guest
client) is gzip-compressed when the guest has gzip; the TX stream (gc-tx.bin,
all request bytes) is tiny and dumped raw. Sizes and md5s are printed
in-transcript so the decode is self-verifying.

Usage:
    bx510_rawdecode.py LOGFILE OUT_PREFIX

Writes OUT_PREFIX-rx.bin and OUT_PREFIX-tx.bin, verifying md5 against the
in-transcript values. Exits non-zero on any mismatch or truncation.
"""
import gzip
import hashlib
import re
import sys

# hexdump -v -e '16/1 "%02x"' emits full 32-char lines and a SHORT
# final line when the file size is not a multiple of 16 — accept any
# even-length bare hex line (command echoes never match: they all carry
# non-hex characters).
HEXLINE = re.compile(r"^[0-9a-f]+$")
# kernel printk markers that may be glued onto a hex line mid-stream
NOISE = re.compile(r"bdpvirt:|sacd_read|TestUnitReadyLoop|GetProfile|Inst_Decrypt|OddRead")
WC = re.compile(r"^\s*(\d+)\s+/res/gc-(raw|tx)\.bin")
MD5 = re.compile(r"^([0-9a-f]{32})\s+/res/gc-(raw|tx)\.bin")


def parse(logfile):
    text = open(logfile, "rb").read().decode(errors="replace")
    if "P0_RAWFULL_BEGIN" not in text or "P0_RAWFULL_END" not in text:
        raise SystemExit("no rawdump block in log (was --rawdump passed?)")
    block = text.split("P0_RAWFULL_BEGIN", 1)[1].split("P0_RAWFULL_END", 1)[0]
    # the echoed command line contains the literal marker text, so match
    # the standalone OUTPUT line only
    gz = re.search(r"^P0_GZ=yes\s*$", block, re.M) is not None
    if re.search(r"^P0_GZ=no\s*$", block, re.M):
        gz = False
    sizes, md5s = {}, {}
    hexbytes = []
    tx_hexbytes = []
    recovered = 0
    in_tx = False
    for line in block.splitlines():
        line = line.strip()
        m = WC.match(line)
        if m:
            sizes[m.group(2)] = int(m.group(1))
            continue
        m = MD5.match(line)
        if m:
            md5s[m.group(2)] = m.group(1)
            continue
        if line == "P0_TX_BEGIN":
            in_tx = True
            continue
        if line == "P0_TX_END":
            in_tx = False
            continue
        if HEXLINE.match(line) and len(line) % 2 == 0:
            if len(line) > 64:
                raise SystemExit(f"unexpected long hex line (UART corruption?): {line[:64]}")
            (tx_hexbytes if in_tx else hexbytes).append(line)
            continue
        # Kernel printks share the UART console with the shell and can be
        # injected MID-LINE (observed: "<32 hex chars>bdpvirt: TestUnitReadyLoop...").
        # Recover the hex prefix when it is glued to a recognized noise
        # marker; the marker anchors the split so hex-valid letters inside
        # the printk ("bd...") cannot shift it.
        m = NOISE.search(line)
        if m:
            prefix = line[:m.start()]
            if prefix and HEXLINE.match(prefix) and len(prefix) % 2 == 0:
                (tx_hexbytes if in_tx else hexbytes).append(prefix)
                recovered += 1
                continue
    rx = bytes.fromhex("".join(hexbytes))
    tx = bytes.fromhex("".join(tx_hexbytes))
    if gz:
        rx = gzip.decompress(rx)
    return rx, tx, sizes, md5s, gz, recovered


def rvarint(b, p):
    v, s = 0, 0
    while True:
        x = b[p]
        p += 1
        v |= (x & 0x7f) << s
        s += 7
        if not (x & 0x80):
            return v, p


def frame_table(rx):
    """Parse the RX stream into nanopb frames (response wire grammar:
    field1 type, field2 result, field3 data, 0x00 terminator; fields 2/3
    optional). Returns a list of (type, result, datalen, fnv1a64)."""
    frames = []
    p = 0
    while p < len(rx):
        if rx[p] == 0x00:
            p += 1
            continue
        assert rx[p] == 0x08, f"frame {len(frames)} @ {p}: bad tag {rx[p]:02x}"
        p += 1
        typ, p = rvarint(rx, p)
        res = dl = None
        payload = b""
        if p < len(rx) and rx[p] == 0x10:
            p += 1
            res, p = rvarint(rx, p)
        if p < len(rx) and rx[p] == 0x1a:
            p += 1
            dl, p = rvarint(rx, p)
            payload = rx[p:p + dl]
            assert len(payload) == dl, f"frame {len(frames)}: truncated payload"
            p += dl
        assert p < len(rx) and rx[p] == 0x00, f"frame {len(frames)} @ {p}: bad terminator"
        p += 1
        h = 0xcbf29ce484222325
        for byte in payload:
            h ^= byte
            h = (h * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF
        frames.append((typ, res, dl, h))
    return frames


def session_end(rx):
    """Byte offset of the end of the deterministic protocol session:
    through the second type=2 (CLOSE#2) response frame. The frames after
    it are the reconnect sweep, whose outcomes are documented race data."""
    frames = frame_table(rx)
    closes = [f for f in frames if f[0] == 2]
    if len(closes) < 2:
        raise SystemExit("session-diff: fewer than two CLOSE frames - "
                         "malformed capture")
    p = 0
    seen_close = 0
    while p < len(rx):
        if rx[p] == 0x00:
            p += 1
            continue
        p += 1  # 0x08
        typ, p = rvarint(rx, p)
        if p < len(rx) and rx[p] == 0x10:
            p += 1
            res, p = rvarint(rx, p)
        if p < len(rx) and rx[p] == 0x1a:
            p += 1
            dl, p = rvarint(rx, p)
            p += dl
        assert rx[p] == 0x00, f"bad terminator at {p}"
        p += 1
        if typ == 2:
            seen_close += 1
            if seen_close == 2:
                return p
    raise SystemExit("session-diff: never reached CLOSE#2")


def cmd_session_diff(loga, logb, pa, pb):
    """Decode + verify both captures, then require the deterministic
    session bytes and the complete request streams to be IDENTICAL.
    Writes the decoded captures/frames when prefixes are given."""
    global recovered_lines
    ok = True
    data = {}
    for log, prefix in ((loga, pa), (logb, pb)):
        rx, tx, sizes, md5s, gz, rec = parse(log)
        for name, blob in (("raw", rx), ("tx", tx)):
            if sizes.get(name) is not None and len(blob) != sizes[name]:
                print(f"SIZE MISMATCH {log} gc-{name}.bin")
                ok = False
            if md5s.get(name) and hashlib.md5(blob).hexdigest() != md5s[name]:
                print(f"MD5 MISMATCH {log} gc-{name}.bin")
                ok = False
        if prefix:
            open(prefix + "-rx.bin", "wb").write(rx)
            open(prefix + "-tx.bin", "wb").write(tx)
            with open(prefix + "-frames.txt", "w") as f:
                for i, (typ, res, dl, h) in enumerate(frame_table(rx)):
                    r = None if res is None else (res if res < 2 ** 63 else res - 2 ** 64)
                    f.write(f"frame {i}: type={typ} result={r} datalen={dl} "
                            f"fnv1a64={h:016x}\n")
        data[log] = (rx, tx, session_end(rx))
    (rxa, txa, enda), (rxb, txb, endb) = data[loga], data[logb]
    if enda != endb:
        print(f"SESSION LENGTH MISMATCH: {enda} != {endb}")
        ok = False
    elif rxa[:enda] != rxb[:endb]:
        print("SESSION BYTES DIFFER")
        for i in range(enda):
            if rxa[i] != rxb[i]:
                print(f"  first differing byte at {i}: "
                      f"{rxa[i]:02x} vs {rxb[i]:02x}")
                break
        ok = False
    else:
        print(f"SESSION BYTES IDENTICAL ({enda} bytes, through CLOSE#2)")
    if txa != txb:
        print("REQUEST STREAMS DIFFER")
        ok = False
    else:
        print(f"REQUEST STREAMS IDENTICAL ({len(txa)} bytes)")
    print("RAW-FRAME VERIFICATION: " + ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--session-diff":
        args = sys.argv[2:]
        if len(args) not in (2, 4):
            print("usage: bx510_rawdecode.py --session-diff LOG_A LOG_B "
                  "[PREFIX_A PREFIX_B]")
            return 2
        pa = args[2] if len(args) == 4 else None
        pb = args[3] if len(args) == 4 else None
        return cmd_session_diff(args[0], args[1], pa, pb)
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    logfile, prefix = sys.argv[1], sys.argv[2]
    global recovered_lines
    rx, tx, sizes, md5s, gz, recovered_lines = parse(logfile)
    if "--frames" in sys.argv:
        for i, (typ, res, dl, h) in enumerate(frame_table(rx)):
            r = None if res is None else (res if res < 2 ** 63 else res - 2 ** 64)
            print(f"frame {i}: type={typ} result={r} datalen={dl} fnv1a64={h:016x}")
        return 0
    ok = True
    for name, data in (("raw", rx), ("tx", tx)):
        if sizes.get(name) is not None and len(data) != sizes[name]:
            print(f"SIZE MISMATCH gc-{name}.bin: decoded {len(data)} != "
                  f"in-transcript {sizes[name]} (truncated dump?)")
            ok = False
        if md5s.get(name) and hashlib.md5(data).hexdigest() != md5s[name]:
            print(f"MD5 MISMATCH gc-{name}.bin: decode corrupted in transit")
            ok = False
    open(prefix + "-rx.bin", "wb").write(rx)
    open(prefix + "-tx.bin", "wb").write(tx)
    print(f"decoded: rx={len(rx)} bytes, tx={len(tx)} bytes, "
          f"gzip={'yes' if gz else 'no'}, printk-glued lines recovered: {recovered_lines}")
    if ok:
        print("VERIFY: sizes and md5s match in-transcript values")
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
