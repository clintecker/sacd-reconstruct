/* bdpvirt.c — bdpdrv-stack provider module for the BX510 guest (bdpvirt).
 *
 * The real sacd_read.ko resolves 13 functions from the bdpdrv stack at
 * module init via kallsyms_lookup_name (loose coupling; full contract
 * decoded from its init disassembly, evidence/bx510-guest/PHASE0-RESULTS.md).
 * On a real player those live in the 8 MB bdpdrv.ko, which needs the
 * initramfs-provided OSAL base we cannot load. kallsyms_lookup_name also
 * searches loaded modules' symbol tables, so THIS module satisfies the
 * lookups — the kernel-space seam for the virtual optical front-end.
 *
 * Behavior status (honest, minimal):
 *  - x_memset: full implementation, instruction-identical to osai.ko's.
 *  - i4CPSA_Inst_CPSMode_Ctrl: the init gate — called with the module
 *    `minor` param (201); must return -1 for the module to proceed to
 *    misc_register (decoded: cmp r0 == -1 sentinel).
 *  - _IDECLI_OddRead / _i4CPSA_Inst_Decrypt: return failure (-1) until
 *    the real virtual-ODD implementation exists — the daemon reports
 *    read errors rather than fabricated data. HONEST FAILURE ONLY.
 *  - the rest: benign presence stubs (return 0 / a handle) so the
 *    lookups resolve; their call-site contracts get derived from
 *    bdpdrv.ko as each is exercised.
 *
 * Build: Sony GPL linux-2.6.35, mediatek_defconfig, SMP off, -march=armv6,
 * vermagic token patched ARMv7->ARMv6 (same length). this_module 0x148.
 */
#include <linux/module.h>
#include <linux/string.h>
#include <linux/types.h>

/* ---- osai base ---- */
void *x_memset(void *s, int c, size_t n)
{
    return memset(s, c, n);
}
EXPORT_SYMBOL(x_memset);

/* ---- init gate ----
 * Called at module init with the module's compid param (the daemon
 * insmods with only minor=201, so compid=0) and must return -1 for the
 * module to accept the component id and proceed to misc_register
 * (decoded from init_module: cmn r0,#1 -> beq success; failure prints
 * "compid = %d is used. Try another." and returns -EBUSY). Observed live.
 */
int i4CPSA_Inst_CPSMode_Ctrl(int compid)
{
    printk(KERN_INFO "bdpvirt: CPSMode_Ctrl compid=%d\n", compid);
    return -1;
}
EXPORT_SYMBOL(i4CPSA_Inst_CPSMode_Ctrl);

/* ---- data path: honest failure until the virtual ODD exists ---- */
int _IDECLI_OddRead(unsigned lsn, unsigned blocks, void *buf,
                    unsigned len, unsigned flag)
{
    printk(KERN_INFO "bdpvirt: OddRead lsn=%u blocks=%u -> not implemented\n",
           lsn, blocks);
    return -1;
}
EXPORT_SYMBOL(_IDECLI_OddRead);

int _i4CPSA_Inst_Decrypt(unsigned a, void *b, void *c, unsigned d)
{
    printk(KERN_INFO "bdpvirt: Inst_Decrypt -> not implemented\n");
    return -1;
}
EXPORT_SYMBOL(_i4CPSA_Inst_Decrypt);

/* ---- presence stubs ---- */
int i4CPSA_Inst_SetSACDControl(int x)
{
    return 0;
}
EXPORT_SYMBOL(i4CPSA_Inst_SetSACDControl);

unsigned u4CPSA_Inst_GetInstHandleFromCompId(unsigned compid)
{
    /* Decisive live evidence: sacd_read's init gate calls THIS function
     * with the module's compid param (0 when the daemon insmods with only
     * minor=201) and requires -1 to accept the compid and proceed to
     * misc_register (init_module: cmn r0,#1 -> beq success). Any other
     * value prints "compid = %d is used. Try another." and fails -EBUSY.
     */
    printk(KERN_INFO "bdpvirt: GetInstHandleFromCompId compid=%u -> free (-1)\n",
           compid);
    return (unsigned)-1;
}
EXPORT_SYMBOL(u4CPSA_Inst_GetInstHandleFromCompId);

int i4CPSA_Inst_Connect(unsigned a, unsigned b, unsigned c)
{
    return 0;
}
EXPORT_SYMBOL(i4CPSA_Inst_Connect);

int i4CPSA_Inst_Disconnect(unsigned a, unsigned b, unsigned c)
{
    return 0;
}
EXPORT_SYMBOL(i4CPSA_Inst_Disconnect);

void vSacdDecryptEnable(void)
{
}
EXPORT_SYMBOL(vSacdDecryptEnable);

int _SACDCLI_TestPhy(int x)
{
    printk(KERN_INFO "bdpvirt: TestPhy %d\n", x);
    return 0;
}
EXPORT_SYMBOL(_SACDCLI_TestPhy);

int eSacdGetVersion(void *out)
{
    return 0;
}
EXPORT_SYMBOL(eSacdGetVersion);

int _SACDCLI_FindTag(unsigned a, unsigned b, unsigned c, unsigned d)
{
    return 0;
}
EXPORT_SYMBOL(_SACDCLI_FindTag);

int _IDECLI_OddTestUnitReadyLoop(const char *what, void *out)
{
    printk(KERN_INFO "bdpvirt: TestUnitReadyLoop(%s)\n", what);
    return 0;
}
EXPORT_SYMBOL(_IDECLI_OddTestUnitReadyLoop);

int _IDECLI_OddGetProfile(void *out)
{
    printk(KERN_INFO "bdpvirt: GetProfile\n");
    return 0;
}
EXPORT_SYMBOL(_IDECLI_OddGetProfile);

/* Sony's 2.6.35 layout_symtab/add_kallsyms contain an off-by-one: the loops
 * run 'for (ndst = i = 1; i < nsrc; ++i, ++src)' starting src at index 0, so
 * they examine entries 0..nsrc-2 and DROP THE LAST symtab entry of every
 * loaded module (observed live: eSacdGetVersion, readelf index 113 = final
 * entry, vanished from /proc/kallsyms while every neighbor resolved).
 * Tail markers guarantee no provider symbol is ever the victim. */
void bdpvirt_tail_marker_1(void)
{
}
EXPORT_SYMBOL(bdpvirt_tail_marker_1);

void bdpvirt_tail_marker_2(void)
{
}
EXPORT_SYMBOL(bdpvirt_tail_marker_2);

static int __init bdpvirt_init(void)
{
    printk(KERN_INFO "bdpvirt: bdpdrv-stack provider loaded\n");
    return 0;
}

static void __exit bdpvirt_exit(void)
{
    printk(KERN_INFO "bdpvirt: unloaded\n");
}

module_init(bdpvirt_init);
module_exit(bdpvirt_exit);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Virtual bdpdrv-stack provider for sacd_read.ko (BX510 guest)");
