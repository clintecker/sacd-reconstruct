#!/bin/sh
# bx510-fire.sh — the braindead fire+capture loop (parent-side).
#
# One command stages everything, fires the probe on the VM, lifts the
# verdict markers, and pulls the evidence home. No ad-hoc quoting.
#
# Usage: make bx510-fire RUNID=c123 GCMD_FILE=/tmp/g123.txt [TIMEOUT=240] [PORT=...]
#   GCMD_FILE: one line of guest shell (the single fast-fire command)
#   DRYRUN=1:  render the guest command list + the REAL staging arithmetic
#              (the probe builds the payload it would stage) and stop before
#              QEMU. `make bx510-ui-build` uses this as its fe_test_data budget
#              gate, so the budget is never a second, drifting estimate.
#   The script refuses to run without a GCMD_FILE or without --guest-cmd
#   support in the staged probe.
set -eu

REPO=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$REPO"
RUNID=${RUNID:?usage: make bx510-fire RUNID=c123 GCMD_FILE=/tmp/g123.txt}
GCMD_FILE=${GCMD_FILE:?missing GCMD_FILE (one line of guest shell)}
TIMEOUT=${TIMEOUT:-240}
DRYRUN=${DRYRUN:-0}
# Expanded into the VM-side runner: a leading space keeps the empty case from
# leaving a stray continuation token on the probe's argv line.
PROBE_EXTRA=""
[ "$DRYRUN" = "1" ] && PROBE_EXTRA=" --print-commands"

# DISC: the disc image the emulated drive serves. Default is the real Firebird
# ISO — the Level-0 oracle ground truth, which every fire MUST leave untouched
# (read-only: blk_new_open(..., 0, ...), emulator-kit/sony-bx510.c:1667-1670).
# CIPHER=1 arms the model's sacd-cipher property AND therefore the guest stub's
# transform: only ever pair it with an encrypted-at-rest derived disc
# (evidence/bx510-guest/bdpdrv/decode/level1-cipher-spec.md §3).
# Both spellings work: BX510_DISC/BX510_CIPHER (the spec's names) and the short
# DISC/CIPHER the battery call sites pass. Non-empty wins; DISC falls back to
# the real ISO and CIPHER to 0 (property off, the Level-0 behaviour).
DISC="${BX510_DISC:-${DISC:-/home/aftermath/sacd-verify/firebird.iso}}"
# QEMU bool properties parse 'on'/'off' (not '1'/'0') — measured, run c136:
# 'sacd-cipher=1' died with "Parameter 'sacd-cipher' expects 'on' or 'off'".
# The env contract stays 1/0 (the spec's and the battery call sites' spelling).
CIPHER_OPT=""
CIPHER_STATE=off
case "${BX510_CIPHER:-${CIPHER:-0}}" in
1) CIPHER_OPT=",sacd-cipher=on"; CIPHER_STATE=on ;;
*) : ;;
esac

EVID=evidence/bx510-guest/bdpdrv
VM=aftermath@10.20.0.18
SSH="ssh -o BatchMode=yes -p 2222 $VM"
SCP="scp -o BatchMode=yes -P 2222"

# ONE fire at a time per host. A fire owns the staged runner, the guest command
# file, the run's traces AND `pkill -f qemu-system-arm`; two concurrent fires
# therefore corrupt each other rather than queue — observed: a sibling run's
# fire SIGTERMed a live run mid-scenario (FIRE_RC=143) and the trace rotation
# deleted the logs of the run beside it. Fail loudly instead.
LOCK=/tmp/bx510-fire.lock
if ! mkdir "$LOCK" 2>/dev/null; then
    echo "REFUSING: another fire holds $LOCK." >&2
    echo "  Concurrent fires collide: shared /tmp runners + pkill qemu-system-arm." >&2
    echo "  Wait for it, or delete $LOCK if that fire is dead (ps: qemu-system-arm)." >&2
    exit 3
fi
trap 'rmdir "$LOCK" 2>/dev/null || true' EXIT INT TERM

# 1. stage the moving parts (probe, fastfire, guest command) — every staged
#    name is runid-scoped so a run can never read another run's command
GCMD_REMOTE=/tmp/guest-cmd-$RUNID.txt
VMFIRE=/tmp/bx510-vm-fire-$RUNID.sh
$SCP tools/bx510_bdpdrv_stub_probe.py "$VM:/tmp/"
$SCP "$GCMD_FILE" "$VM:$GCMD_REMOTE"

# 2. fire (VM-side runner reads $GCMD_REMOTE; trace rotation inside)
cat > "$VMFIRE" <<EOF
#!/bin/sh
R=$RUNID T=$TIMEOUT
export BX510_TRACE=1
export BX510_MACHINE_OPTS="sata-disc=$DISC$CIPHER_OPT"
echo "bx510-fire: run \$R — disc=$DISC cipher=$CIPHER_STATE"
cd /home/aftermath || exit 1
ls -t /tmp/bdpdrv-run*.mmio.log 2>/dev/null | grep -v "\$R" | tail -n +3 | xargs -r rm -f
ls -t /tmp/bdpdrv-run*.uart.log 2>/dev/null | grep -v "\$R" | tail -n +5 | xargs -r rm -f
GCMD=\$(cat $GCMD_REMOTE)
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
  $PROBE_EXTRA \\
  --uart /tmp/bdpdrv-run\$R.uart.log --unimp /tmp/bdpdrv-run\$R.mmio.log \\
  --meta /tmp/bdpdrv-run\$R.meta.json --timeout \$T
echo FIRE_RC=\$?
pkill -f qemu-system-arm 2>/dev/null || true
EOF
$SCP "$VMFIRE" "$VM:/tmp/"
VMFIRE_REMOTE=/tmp/$(basename "$VMFIRE")
if [ "$DRYRUN" = "1" ]; then
    echo "== DRYRUN $RUNID (guest command list + real payload arithmetic; no QEMU) =="
    $SSH "sh $VMFIRE_REMOTE" 2>&1
    exit 0
fi
echo "== FIRE $RUNID =="
$SSH "sh $VMFIRE_REMOTE" 2>&1 | tee "$EVID/bdpdrv-run$RUNID.fire.txt" | grep -av "cache_avail\|x_thread_delay\|x_sema_lock\|IRRC\|VFD\|mq_\|Assert" | tail -40 || true

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
