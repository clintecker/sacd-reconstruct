/* bx510_feboot.c — TOMBSTONE. STATUS: OPTION A — NOT LOADED, NOT BUILT.
 *
 * This is the formerly untracked, VM-only instrument module: it lived only at
 * /tmp/osal_d/bx510_feboot.c on the lab VM (md5 d4071d4e5a0cb22494bf6d25c1082448,
 * built .ko md5 b1a562e1697cbf5bded3d37986a98307, vermagic
 * "2.6.35 preempt mod_unload ARMv6"). It is tracked here so a rebuilt VM cannot
 * silently lose the artifact, and as the record of what it did.
 *
 * WHY IT IS OUT of the fire pipeline — evidence/bx510-guest/bdpdrv/decode/feboot-marshal.md
 * §1/§4 option A, with the confirmation in
 * evidence/bx510-guest/bdpdrv/decode/feboot-option-a.md:
 *   - IT FORGES THE OBSERVABLE. `_fg_fe_bootup = 1` runs unconditionally at
 *     init, before bdpdrv is loaded, so "[v4IdeDrvInitThread]FE boot up OK !!"
 *     was this module's assertion — not evidence that the FE handshake ran.
 *     Demonstrated in the existing artifacts: in C54/C55/C96 the SATA port never
 *     started ("polling frontend reset interrupt timeout !!", "failed to start
 *     port 0 (errno=-5)") and the real flag was cleared to 0, yet all three runs
 *     printed "FE boot up OK !!".
 *   - IT SHADOWS THE REAL PROC TREE. proc_mkdir("driver", NULL) collides with
 *     the kernel's own /proc/driver (fs/proc/root.c:126). proc_register() WARNs
 *     (fs/proc/generic.c:583) but still head-inserts the duplicate, so every
 *     later /proc/driver/<x> lookup resolves into a directory holding only
 *     sata/ — hiding the kernel built-ins' rtc/nvram/mmc/usb and eleven of
 *     sata_bltin's twelve entries.
 *   - IT IS REDUNDANT. The built-in sata_bltin creates the same
 *     /proc/driver/sata/fe_bootup at boot (sata_bltin.c:640,699) and the real
 *     flag is written by sata_mt85xx_port_start (.text+0x32c0, fast-boot path).
 * The only problem it ever solved was a proc MOUNT failure (C50-C53
 * ROOTPROC=255), and that was fixed in the probe, not here.
 *
 * NOT wired into tools/bx510_stub_build.sh on purpose: option A neither builds
 * nor loads it, so there is no build stanza. Option B (the fix: no proc_mkdir
 * calls, no flag write, a non-colliding entry name) would add one at that time.
 *
 * Everything below the marker is the artifact verbatim — do not edit it.
 */

/* ---------------------------- artifact (verbatim) ---------------------------- */
/* bx510_feboot.ko — STUB/INSTRUMENT: the ODD front-end "booted" marker.
 *
 * Real chain: sata_bltin (kernel built-in) creates /proc/driver/sata +
 * fe_bootup; sata_mt85xx_mod's _mt85xx_xfer_int_ldr_fw sets it to 1.
 * bdpdrv's v4IdeDrvInitThread polls the file for '1'.
 *
 * Run C55 finding (VERIFIED): the guest proc tree has NO driver/sata at
 * all (procc.sh: /proc/driver MISSING) — sata_bltin's proc_init chain
 * failed BEFORE creating the dir (its boot log shows buffers allocated
 * but no proc prints). The FEB module must create the FULL path from
 * proc root: proc_mkdir("driver", NULL) then proc_mkdir("sata", dir),
 * then fe_bootup under it. (2.6.35 proc_mkdir does NOT split paths:
 * xlate_proc_name requires every component to already exist.)
 */
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/proc_fs.h>

extern int _fg_fe_bootup;

static int feboot_read(char *page, char **start, off_t off, int count,
                       int *eof, void *data)
{
  int len = sprintf(page, "%d", _fg_fe_bootup);
  *eof = 1;
  return len;
}

static int __init feboot_init(void)
{
  struct proc_dir_entry *drv, *sat, *ent;
  printk(KERN_INFO "[FEB] up (INSTRUMENT)\n");
  drv = proc_mkdir("driver", NULL);
  if (!drv) {
    printk(KERN_ERR "[FEB] proc_mkdir(driver) failed\n");
    return 0;
  }
  sat = proc_mkdir("sata", drv);
  if (!sat) {
    printk(KERN_ERR "[FEB] proc_mkdir(sata) failed\n");
    return 0;
  }
  ent = create_proc_read_entry("fe_bootup", 0444, sat, feboot_read, NULL);
  if (!ent) {
    printk(KERN_ERR "[FEB] create fe_bootup failed\n");
    return 0;
  }
  _fg_fe_bootup = 1;
  printk(KERN_INFO "[FEB] /proc/driver/sata/fe_bootup created, flag = 1\n");
  return 0;
}
static void __exit feboot_exit(void) { }
module_init(feboot_init);
module_exit(feboot_exit);
MODULE_LICENSE("Proprietary");
MODULE_AUTHOR("aftermath (instrument)");
MODULE_DESCRIPTION("BX510 ODD FE bootup flag + full proc path (INSTRUMENT)");
