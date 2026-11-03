# sacd-reconstruct — hardware-session orchestration (Mac-side)
# The full build/verification targets live in the private repo; this public
# Makefile carries the on-player session tooling that operates on this
# checkout's ELFs, ISO cross-checks, and the BX510 itself.
# Env knobs: HW_HOST (10.20.1.236) HW_PORT (2002) USB (/Volumes/SONYUSB)
#            PLAYER_MOUNT (/mnt/sda1) PAIR_LSN (600) SESSION_DIR (~/bx510-session)
#            HW_ISO (the Firebird rip) DISK (/dev/diskN for usb-build)

EXP := $(CURDIR)

## hardware :: help :: list targets
.PHONY: help
help:
	@grep -E '^## ' Makefile | sed 's/^## //'

## hardware :: preflight :: ISO + both pinned ELF SHAs + client selftest
.PHONY: preflight
preflight:
	USB_VOLUMES= $(EXP) sh $(EXP)/tools/sacd_hardware.sh preflight

## hardware :: usb-build :: DESTRUCTIVE: make sacd-usb-build DISK=/dev/diskN CONFIRM=ERASE
.PHONY: usb-build
usb-build:
	DISK="$(DISK)" CONFIRM="$(CONFIRM)" sh tools/sacd_hardware.sh usb-build

## hardware :: usb-check :: verify stick contents (daemon SHA, mode, kit)
.PHONY: usb-check
usb-check:
	sh tools/sacd_hardware.sh usb-check

## hardware :: usb-baseline-mode :: AutoScript -> normal daemon line
.PHONY: usb-baseline-mode
usb-baseline-mode:
	sh tools/sacd_hardware.sh usb-baseline-mode

## hardware :: usb-pair-mode :: AutoScript -> instrumented trace-launch (PAIR_LSN=600)
.PHONY: usb-pair-mode
usb-pair-mode:
	PAIR_LSN="$(PAIR_LSN)" sh tools/sacd_hardware.sh usb-pair-mode

## hardware :: usb-original :: original ELF (0fdcefdb…) onto the stick
.PHONY: usb-original
usb-original:
	sh tools/sacd_hardware.sh usb-original

## hardware :: usb-candidate :: release candidate (e91720fb…) onto the stick
.PHONY: usb-candidate
usb-candidate:
	sh tools/sacd_hardware.sh usb-candidate

## hardware :: wait :: block until the daemon listens at HW_HOST:HW_PORT
.PHONY: wait
wait:
	HW_HOST="$(HW_HOST)" HW_PORT="$(HW_PORT)" sh tools/sacd_hardware.sh wait

## hardware :: baseline :: on-player baseline capture (console teed to SESSION_DIR)
.PHONY: baseline
baseline:
	HW_HOST="$(HW_HOST)" HW_PORT="$(HW_PORT)" SESSION_DIR="$(SESSION_DIR)" USB="$(USB)" sh tools/sacd_hardware.sh baseline

## hardware :: baseline-retry :: retry capture (fresh out dir + label)
.PHONY: baseline-retry
baseline-retry:
	HW_HOST="$(HW_HOST)" HW_PORT="$(HW_PORT)" SESSION_DIR="$(SESSION_DIR)" USB="$(USB)" sh tools/sacd_hardware.sh baseline-retry

## hardware :: pair :: ground-truth pair capture at PAIR_LSN
.PHONY: pair
pair:
	HW_HOST="$(HW_HOST)" HW_PORT="$(HW_PORT)" SESSION_DIR="$(SESSION_DIR)" PAIR_LSN="$(PAIR_LSN)" sh tools/sacd_hardware.sh pair

## hardware :: analyze :: validate pair + baseline against the ISO
.PHONY: analyze
analyze:
	HW_ISO="$(HW_ISO)" USB="$(USB)" sh tools/sacd_hardware.sh analyze

## hardware :: collect :: assemble + verify the handoff folder (SESSION_DIR)
.PHONY: collect
collect:
	SESSION_DIR="$(SESSION_DIR)" USB="$(USB)" sh tools/sacd_hardware.sh collect
