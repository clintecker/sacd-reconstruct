# Optical evidence for the full-system machine

Use the qemu-user team's capture client and real sector fixtures for the application reference. The full-system hardware model still needs the block device used for TOC reads, the drive-side read of raw frames, and the vendor decryption path. The tools here collect evidence at those boundaries. They do not implement the drive.

| Boundary in the reference image | Unit | Verification |
|---|---|---|
| Master and area TOC reads through `/dev/sr0` | 2,048-byte logical sectors | The original `scarletbook_read_master_toc` calls `sacd_read_block_raw` at 0x2a25c. It uses the seek/read backend. The master is at LSN 510. Read the area addresses from that particular disc. |
| `SACD_IOC_READ` of `/dev/sacd_read` | 2,064-byte frames | In the embedded module, `.text+0x318` loads 2064, `+0x368` calls the resolved `_IDECLI_OddRead`, and `+0x3cc` copies the frames to the original user pointer. |
| `SACD_IOC_DECRYPT` of the same buffer | 2,048-byte payloads | The module processes each 2064-byte input, calls `CPSA_SACDCmdDecrypt` at `+0x4e4`, and copies 2048 bytes from output offset 12 per frame (`+0x4b4`, `+0x4e8`, `+0x500`). Raw frame metadata and ciphertext cannot be verified from an ISO alone. |

The exact module SHA-256 is `b3d7a383e45d3bbe1a987a4a2e15ab7a68dd55e88d0319f7a0fd2e9cf0246dfa`. At 128 sectors, 0x40800 bytes are raw, 0x40000 are logical, and the daemon reserves 0x40400 for the encoded network response. On the block device, the daemon falls back to `BLKGETSIZE64` when `fstat64` reports zero size. The server calls decrypt after its read and does not use the decrypt return value to decide the wire result. A matching wire transcript alone cannot establish successful device crypto. [Device code and module](https://github.com/clintecker/sacd-reconstruct/tree/40e146700bbc239fd949dd9916120f13ffdddba7/reconstruct)

## Check earlier captures

```sh
python3 optical/media_check.py baseline real/manifest.json --against rig/manifest.json --iso "/path/to/Firebird.iso"
```

Each manifest must contain the original client’s nine-exchange positive baseline, including reconnect. The verifier checks the ordered request bytes, response type/result/length, response-frame hashes and each returned sector count. It permits valid boundary clamping, reads only those ISO sectors, and uses their bytes to verify both payload and wire hashes. Failure captures and overlapping-client stress runs are separate experiments. If no ISO is supplied, data-bearing wire hashes can only be compared across the inputs.

## Capture two frames on a subsequent player run

1. Complete the untouched original-daemon baseline first. Pick two adjacent LSNs **inside** a track range parsed from Firebird’s area TOC. The area TOC's own address (reported as 353764 on the team's image) identifies metadata. A track's `track_start` identifies a candidate audio sector.
2. Use a separate test startup of the original daemon, with the normal daemon stopped. Copy this optical folder to USB. From an existing player shell/launcher hook, start the following once, substituting the actual USB directory, the path to the verified original daemon, and the decimal LSN. The example assumes the optical folder was copied as `/mnt/sda1/AutoScript/optical`.

```sh
/bin/sh /mnt/sda1/AutoScript/optical/trace-launch.sh \
    /path/to/original/sacd_extract_160 "$LSN" /mnt/sda1/firebird.pair -S
```

3. From the Mac, with the same decimal LSN, run

```sh
python3 optical/media_check.py request-pair --client /path/to/tools/sacd_client.py --host 10.20.1.236 --lsn "$LSN"
```

4. After the request closes and the USB is safely available, run

```sh
python3 optical/media_check.py pair /Volumes/NAME/firebird.pair --iso "/path/to/Firebird.iso"
```

Return the 8,240-byte pair, LSN, disc identifier and the wire hash printed in step 3. The file contains the magic `BX5PAIR1`, little-endian LSN and count, 4,128 raw bytes, and 4,096 logical bytes. An existing output is never overwritten. The observer requires a successful two-sector read at the requested LSN and a successful decrypt of the same original pointer on the same worker. The observer saves caller fields before forwarding, since the module may overwrite the ioctl structure before returning. It forwards other ioctls with the original ARM argument registers. If no file appears, retain the client transcript. The original tty status code and module calls still execute.

The shipped ARM observer was tested in the stock Sony userspace under full-system QEMU. A synthetic lower ioctl provider changed the returned pointer and interleaved two workers. The captured raw and logical bytes, errno, ordinary ioctl forwarding, existing-file protection and the unmodified original's help output were verified. This test uses a synthetic lower driver. A physical Firebird capture is outstanding. To rebuild the observer, use Zig 0.13.0 and `sh optical/build_trace.sh /path/to/extracted-root/lib optical/bx510_pair.so`. The ARM linker recipe specifies contiguous relocation tables and eager binding for the old loader.

Another source of paired samples is SacdImageCreator, whose maintainer lists the BX510 as working and documents separate 2064-byte `.raw` and 2048-byte `.iso` outputs. For matching files from one run, two sectors at LSN N start at offsets `2064*N` and `2048*N` respectively. [SacdImageCreator](https://github.com/saramibreak/SacdImageCreator)
