# Public-readiness scan report

Reproduce with:

```sh
python3 tools/public_tree.py --src . --dest /tmp/pub     # assemble the public tree
cd /tmp/pub && python3 /path/to/audit_public.py .        # classify it
```

## Round 1 — rights and size

| Class | Found | Action |
|---|---|---|
| Sony binaries (daemon, `sacd_read.ko`, font asset) | 6 files, 0.8 MiB | daemon + module excluded, SHA-256 recorded in `PROVENANCE.md`; the Tiresias font is kept (freely distributable, and it is the device's real typeface) |
| Regenerable blobs >1 MiB (NAND/QEMU fixtures, raw dumps) | 12 files, 150.4 MiB | excluded; produced by `tools/fixture_gen.py` |
| Photos with camera/GPS EXIF | 2 files | re-encoded to EXIF-free PNG |
| Identifier leaks (IPv4, MAC, `/Users/<name>`) | 30 files | scrubbed: RFC 5737 addresses, `aa:bb:cc:00:11:22`, `/Users/you` |
| Internal process docs (`AGENTS.md`, `NOTES.md`, `RESEARCH-BRIEF.md`) | 4 | excluded |
| Vendored third-party | 2 | shipped with `THIRD_PARTY.md` |

## Round 2 — reachability and truthfulness

| Check | Found | Action |
|---|---|---|
| Broken references (docs pointing at unpublished paths) | 7 files | the referenced evidence (`bx510-baseline/`, `bx510-candidate/`, `pair-observer/`, `graphics/`) is now mirrored; two stale references rewritten |
| Secrets / tokens / private keys | 0 | — |
| CVE references (disclosure risk) | 0 | — |
| Internal jargon (`lab VM`, `sacd-verify`, `sacd-enhanced`, `subagent`, `the team`) | 47 files | scrubbed to reader-facing equivalents |
| Emails | 87 hits | all third-party or attribution strings, classified `EMAIL-VENDOR` (kernel/glibc/zlib/font headers) |

## Final state of the published tree

```
523 files, 13.1 MiB       (from 973 files / 190 MiB in the working tree)
Sony binaries:  0
blobs >1 MiB:   0
EXIF-bearing:   0
identifier leaks: 0
broken refs:    0
secrets/CVEs:   0
```

Every file's disposition (path, bytes, sha256, action, reason) is recorded in
`PUBLIC-MANIFEST.txt` at the repository root.
