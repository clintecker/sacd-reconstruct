#!/bin/sh
# bx510-fire.sh — the braindead fire+capture loop (parent-side).
#
# One command stages everything, fires the probe on the VM, lifts the
# verdict markers, and pulls the evidence home. No ad-hoc quoting.
#
# Usage: make bx510-fire RUNID=c123 GCMD_FILE=/tmp/g123.txt [TIMEOUT=240] [PORT=...]
#   GCMD_FILE: one line of guest shell (the single fast-fire command)
#   The script refuses to run without a GCMD_FILE or without --guest-cmd
#   support in the staged probe.
set -eu

REPO=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$REPO"
RUNID=${RUNID:?usage: make bx510-fire RUNID=c123 GCMD_FILE=/tmp/g123.txt}
GCMD_FILE=${GCMD_FILE:?missing GCMD_FILE (one line of guest shell)}
TIMEOUT=${TIMEOUT:-240}

EVID=evidence/bx510-guest/bdpdrv
VM=aftermath@10.20.0.18
SSH="ssh -o BatchMode=yes -p 2222 $VM"
SCP="scp -o BatchMode=yes -P 2222"

# 1. stage the moving parts (probe, fastfire, guest command)
$SCP tools/bx510_bdpdrv_stub_probe.py "$VM:/tmp/"
$SCP "$GCMD_FILE" "$VM:/tmp/guest-cmd.txt"

# 2. fire (VM-side runner reads guest-cmd.txt; trace rotation inside)
cat > /tmp/bx510-vm-fire.sh <<EOF
#!/bin/sh
R=$RUNID T=$TIMEOUT
export BX510_TRACE=1
export BX510_MACHINE_OPTS='sata-disc=/home/aftermath/sacd-verify/firebird.iso'
cd /home/aftermath || exit 1
ls -t /tmp/bdpdrv-run*.mmio.log 2>/dev/null | grep -v "\$R" | tail -n +3 | xargs -r rm -f
ls -t /tmp/bdpdrv-run*.uart.log 2>/dev/null | grep -v "\$R" | tail -n +5 | xargs -r rm -f
GCMD=\$(cat /tmp/guest-cmd.txt)
PYTHONPATH=~/bx510-emu/emulator python3 /tmp/bx510_bdpdrv_stub_probe.py \\
  --qemu ~/bx510-emu/emulator/work/build/qemu-system-arm --images /tmp/images-fe \\
  --stubko /tmp/osal_b/bx510_osal_stub.ko --stuba-ko /tmp/osal_a/bx510_osal_stub_a.ko \\
  --kscript /tmp/kcheck.sh \\
  --pre-file libata.ko=/tmp/sata_staging/libata.ko \\
  --pre-file sata_mt85xx_mod.ko=/tmp/sata_staging/sata_mt85xx_mod.ko \\
  --extra-file bx510_clidrive.ko=/tmp/osal_c/bx510_clidrive.ko \\
  --extra-file bx510_cpsa_peer.ko=/tmp/osal_d/bx510_cpsa_peer.ko \\
  --extra-file sr_fa_mode=/tmp/sr_fa_mode \\
  --extra-file daemon_payload.tgz=/tmp/bx510-daemon-payload.tgz \\
  --bdpdrv-host /tmp/rootfs/lib/modules/2.6.35/BDP/bdpdrv.ko \\
  --bdpdrv-guest /lib/modules/2.6.35/BDP/bdpdrv.ko \\
  --clidrive-mode PROBE_SEQ --odd-tail \\
  --guest-cmd "\$GCMD" \\
  --uart /tmp/bdpdrv-run\$R.uart.log --unimp /tmp/bdpdrv-run\$R.mmio.log \\
  --meta /tmp/bdpdrv-run\$R.meta.json --timeout \$T
echo FIRE_RC=\$?
pkill -f qemu-system-arm 2>/dev/null || true
EOF
$SCP /tmp/bx510-vm-fire.sh "$VM:/tmp/"
echo "== FIRE $RUNID =="
$SSH "sh /tmp/bx510-vm-fire.sh" 2>&1 | tee "$EVID/bdpdrv-run$RUNID.fire.txt" | grep -av "cache_avail\|x_thread_delay\|x_sema_lock\|IRRC\|VFD\|mq_\|Assert" | tail -40 || true

# 3. pull evidence home (uart + meta; mmio stays VM-side per policy)
$SCP "$VM:/tmp/bdpdrv-run$RUNID.uart.log" "$EVID/" || echo "uart pull failed"
$SCP "$VM:/tmp/bdpdrv-run$RUNID.meta.json" "$EVID/" || echo "meta pull failed"

# 4. verdict markers (fire output + pulled log — both committed as evidence)
U="$EVID/bdpdrv-run$RUNID.uart.log"
F="$EVID/bdpdrv-run$RUNID.fire.txt"
echo "== VERDICT $RUNID =="
for m in FIRE_RC DAEMON_PID CLIENT_RC CLIENT_PASS DAEMON_ORACLE GUEST_CLIENT_DONE STUB_DONE; do
    grep -ah "$m" "$F" "$U" 2>/dev/null | head -2 || true
done
echo "(full mmio census on the VM: /tmp/bdpdrv-run$RUNID.mmio.log)"
