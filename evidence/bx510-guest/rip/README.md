# The rip artifacts (deliberately NOT committed: GitHub 100 MB file limit)

| file | bytes | md5 | source |
|---|---:|---|---|
| track1.dsf | 213,188,877 | d245d81e36acbd1be0cb8127aeba8793 | rip of 2ch track 1, DSF w/ DST->DSD (-s -c -t 1), against the release daemon under the qemu rig on the lab VM |
| track2.dsf | 301,154,576 | bea93a63b22d876bd5df518f98179458 | track 2, same shape |

Determinism: two independent rips of track 1 produced the identical md5.
DSF header verified: `DSD ` magic, DSD chunk size 28 (`1c000000`), file-size
field == actual size.

Reproduce (lab VM, after a rig daemon is up on 2002):
    qemu-arm-static -L /tmp/rootfs \
      -E LD_PRELOAD=/tmp/sacd-rig/sacd_rig.so \
      -E RIG_DEVFILE=/home/aftermath/sacd-verify/firebird.iso \
      ~/reconstruct/release/sacd_extract_160_release \
      -s -c -t 1 -i 127.0.0.1:2002 /tmp/ripout
