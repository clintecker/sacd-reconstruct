#!/usr/bin/env python3
"""Verify sacd_client.py 1.0 positive baselines and BX510 two-sector captures."""
import argparse
from contextlib import ExitStack
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import struct

BLOCK = 2048
RAW = 2064
OPEN, CLOSE, READ, SIZE = 1, 2, 3, 4


def require(ok, message):
    if not ok:
        raise ValueError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def varint(n):
    require(type(n) is int and 0 <= n <= 0xffffffffffffffff, "invalid unsigned wire integer")
    out = bytearray()
    while n >= 128:
        out.append(128 | (n & 127))
        n >>= 7
    out.append(n)
    return bytes(out)


def iso_bytes(iso, lsn, count):
    iso.seek(lsn * BLOCK)
    data = iso.read(count * BLOCK)
    require(len(data) == count * BLOCK, f"short ISO read at LSN {lsn}")
    return data


def baseline(path, iso):
    manifest = json.loads(path.read_text())
    sectors = manifest["disc_size_sectors"]
    require(type(sectors) is int and 0 < sectors <= 0xffffffff, f"{path}: invalid disc size")
    if iso:
        require(iso.seek(0, 2) == sectors * BLOCK, f"{path}: disc size differs from ISO")
    mid = sectors // 2
    expected = [(OPEN, 0, 0), (SIZE, 0, 0), (READ, 0, 1), (READ, 0, 128),
                (READ, mid, 1), (CLOSE, 0, 0), (OPEN, 0, 0), (READ, mid, 1), (CLOSE, 0, 0)]
    frames, reads = manifest["frames"], manifest["reads"]
    require(len(frames) == len(expected) and len(reads) == 4, f"{path}: incomplete/unknown baseline")
    wire = []
    read_hashes = []
    for index, (frame, (op, lsn, count)) in enumerate(zip(frames, expected), 1):
        where = f"{path} frame {index}, request {op} at LSN {lsn}"
        req, resp = frame["request"], frame["response"]
        require((req["type"], req["sector_offset"], req["sector_count"]) == (op, lsn, count),
                where + ": unexpected request or order")
        request = b"\x08"+varint(op)+b"\x10"+varint(lsn)+b"\x18"+varint(count)+b"\0"
        require(bytes.fromhex(frame["request_frame_hex"]) == request, where + ": request wire mismatch")
        result = resp["result"]
        require(resp["type"] == op and type(result) is int and result >= 0, where + ": failed response")
        payload = b""
        data_len = 0
        response_prefix = b"\x08"+varint(op)+b"\x10"+varint(result)
        if op == READ:
            require(0 < result <= count and lsn + result <= sectors, where + ": invalid returned count")
            data_len = result * BLOCK
            row = reads[len(read_hashes)]
            require((row["lsn"], row["requested_sectors"], row["returned_sectors"], row["data_len"])
                    == (lsn, count, result, data_len), where + ": read record disagrees with response")
            payload_hash = row["payload_sha256"]
            require(isinstance(payload_hash, str) and re.fullmatch("[0-9a-f]{64}", payload_hash),
                    where + ": invalid payload digest")
            read_hashes.append(payload_hash)
            response_prefix += b"\x1a" + varint(data_len)
            if iso:
                payload = iso_bytes(iso, lsn, result)
                require(sha(payload) == payload_hash, where + ": payload differs from ISO")
        elif op == SIZE:
            require(result == sectors, where + ": inconsistent size")
        else:
            require(result == 0, where + ": unexpected OPEN/CLOSE result")
        digest = frame["response_frame_sha256"]
        require(isinstance(digest, str) and re.fullmatch("[0-9a-f]{64}", digest), where + ": invalid wire digest")
        require(resp["data_len"] == data_len and frame["response_frame_len"] == len(response_prefix)+data_len+1,
                where + ": frame length mismatch")
        if not data_len or iso:
            require(sha(response_prefix + payload + b"\0") == digest, where + ": response wire hash mismatch")
        wire.append((request, digest, result, data_len))
    require(read_hashes[-2] == read_hashes[-1] and wire[4] == wire[7], f"{path}: reconnect differs")
    require(manifest["disc_fingerprint_lsn0_128"] == read_hashes[1], f"{path}: inconsistent fingerprint")
    print(f"PASS {path}: 9 exchanges, 4 reads, {sectors} sectors, reconnect identical")
    return wire, read_hashes


def compare(args):
    with ExitStack() as stack:
        iso = stack.enter_context(args.iso.open("rb")) if args.iso else None
        first = baseline(args.manifest, iso)
        if args.against:
            second = baseline(args.against, iso)
            for i, (a, b) in enumerate(zip(first[0], second[0]), 1):
                require(a == b, f"frame {i}: captures differ")
            require(first[1] == second[1], "payload digest lists differ")
            print("PASS ordered request bytes and response hashes match")
        if iso:
            print("PASS all sampled payloads and complete response hashes agree with ISO")


def pair(args):
    record = args.file.read_bytes()
    require(len(record) == 16 + 2*(RAW + BLOCK), "incomplete or unexpected pair length")
    magic, lsn, n = struct.unpack_from("<8sII", record)
    require(magic == b"BX5PAIR1" and n == 2, "unexpected pair header")
    raw, logical = record[16:16+2*RAW], record[16+2*RAW:]
    print(f"LSN {lsn}..{lsn+1}. Raw {len(raw)} bytes SHA-256 {sha(raw)}")
    print(f"Logical {len(logical)} bytes SHA-256 {sha(logical)}")
    if args.iso:
        with args.iso.open("rb") as iso:
            require(logical == iso_bytes(iso, lsn, n), "logical bytes differ from the ISO")
        print("PASS both logical sectors match the ISO byte for byte")


def request_pair(args):
    require(0 <= args.lsn < 0xffffffff, "enter a valid starting sector")
    spec = importlib.util.spec_from_file_location("sacd_capture_client", args.client)
    require(spec is not None and spec.loader is not None, "cannot load the capture client")
    client = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(client)
    conn = client.Connection(args.host, args.port)
    opened = False
    try:
        resp = conn.request(OPEN)
        require(resp["type"] == OPEN and resp["result"] == 0, "DISC_OPEN failed")
        opened = True
        resp = conn.request(READ, args.lsn, 2)
        require(resp["type"] == READ and resp["result"] == 2 and len(resp["data"]) == 2*BLOCK,
                "short/failed two-sector READ; choose two sectors inside the same audio area")
        print(f"Wire logical SHA-256 {sha(resp['data'])}, LSN {args.lsn}..{args.lsn+1}")
    finally:
        try:
            if opened:
                resp = conn.request(CLOSE)
                require(resp["type"] == CLOSE and resp["result"] == 0, "DISC_CLOSE failed")
        finally:
            conn.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="mode", required=True)
    cmd = sub.add_parser("baseline")
    cmd.add_argument("manifest", type=Path)
    cmd.add_argument("--against", type=Path)
    cmd.add_argument("--iso", type=Path)
    cmd.set_defaults(run=compare)
    cmd = sub.add_parser("pair")
    cmd.add_argument("file", type=Path)
    cmd.add_argument("--iso", type=Path)
    cmd.set_defaults(run=pair)
    cmd = sub.add_parser("request-pair")
    cmd.add_argument("--client", required=True, type=Path, help="existing tools/sacd_client.py")
    cmd.add_argument("--host", required=True)
    cmd.add_argument("--port", type=int, default=2002)
    cmd.add_argument("--lsn", required=True, type=int)
    cmd.set_defaults(run=request_pair)
    args = parser.parse_args()
    try:
        args.run(args)
    except (OSError, ValueError, KeyError, TypeError, RuntimeError) as error:
        parser.exit(1, f"FAIL: {error}\n")
