# First physical display run

Operator-reported Sony BDP-S5100, M15.R.0257. Original daemon SHA-256 `0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45`. Two v1 wrapper launches, reporting daemon PIDs 1240 and 1503. The logs do not establish which event triggered either launch. The AutoScript copies the ELF, loads splitter.ko, requests the daemon with `-S &`, then issues its tray command. There was no port-2002 or disc-read attempt in this experiment.

| Observed on both runs | Value |
|---|---|
| DirectFB | 1.2.7 |
| Framebuffer identifier | mt8530 |
| Visible / virtual resolution | 1920×1080 / 1920×2160 |
| Offset, bits per pixel, pitch | 0,0; 32 bpp; 7,680 bytes |
| Reported framebuffer memory | 16,777,216 bytes |
| Probe info exit | 0 |

The operator saw the tray open at startup and pressed power. The tray closed and the TV lost HDMI signal. The last DirectFB message in both v1 runs was Fusion SHM initialization. Run 1 has no exit record. Run 2 ended with `Alarm clock` and `DRAW_EXIT=142`. No bars were observed. A standby Fusion master, a later window operation, and the reason for the second launch remain open. A larger virtual resolution and a successful information ioctl do not identify a writable active OSD surface.

The updated probe brackets every DirectFB operation with BEGIN/END records. The updated wrapper logs launch path, uptime and parent PID. First compare port 2002 and HDMI while Home is visible versus after the usual standby transition.
