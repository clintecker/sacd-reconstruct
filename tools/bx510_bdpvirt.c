/* bdpvirt.c — bdpdrv-stack provider module for the BX510 guest (bdpvirt).
 *
 * The real sacd_read.ko resolves 13 functions from the bdpdrv stack at
 * module init via kallsyms_lookup_name (loose coupling; full contract
 * decoded from its init + ioctl disassembly and live behavior; see
 * evidence/bx510-guest/PHASE0-RESULTS.md). On a real player those live in
 * the 8 MB bdpdrv.ko, which needs the initramfs-provided OSAL base we
 * cannot load. kallsyms_lookup_name also searches loaded modules'
 * symbol tables, so THIS module satisfies the lookups — the kernel-space
 * seam for the virtual optical front-end.
 *
 * Decoded contracts (from sacd_read.ko disassembly + live call logs):
 *  - init_module gate: GetInstHandleFromCompId(compid=0) must return -1
 *    ("compid free"; anything else -> "compid = %d is used. Try
 *    another." + -EBUSY).
 *  - CPSA_SACDCmdEnable (5301 INIT): i4CPSA_Inst_Connect(363, 201, 360,
 *    201) must be >= 0; then GetInstHandleFromCompId(minor=201) ->
 *    handle; then CPSMode_Ctrl(handle, 64, 1) must be >= 0.
 *  - CPSA_SACDCmdDecrypt: GetInstHandleFromCompId(minor) -> handle;
 *    _i4CPSA_Inst_Decrypt(handle, src, dst, len) must be >= 0.
 *  - CPSA_SACDCmdSetCtrl (5302 AUTH): calls eSacdGetVersion then
 *    vSacdDecryptEnable.
 *  - 5306 DISC: _IDECLI_OddTestUnitReadyLoop(a=0x4e20, &out) — arg0 is
 *    NOT a string (a %s printk of it oopsed the kernel live); return 0
 *    with the daemon's poll reporting "Disc inserted".
 *
 * Behavior status: x_memset full; data path (_IDECLI_OddRead,
 * _i4CPSA_Inst_Decrypt) returns honest failure (-1) until the virtual
 * ODD exists — the daemon reports read errors, never fabricated data.
 *
 * Build: Sony GPL linux-2.6.35, mediatek_defconfig, SMP off,
 * -march=armv6, vermagic token patched ARMv7->ARMv6 (same length);
 * bdpswap.py moves a sacrificial tail marker into the final symtab slot
 * (Sony's 2.6.35 kallsyms off-by-one drops the last module symtab entry).
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

/* ---- CPSA mode control ---- */
int i4CPSA_Inst_CPSMode_Ctrl(unsigned handle, unsigned a, unsigned b)
{
    printk(KERN_INFO "bdpvirt: CPSMode_Ctrl handle=%u a=%u b=%u -> 0\n",
           handle, a, b);
    return 0;
}
EXPORT_SYMBOL(i4CPSA_Inst_CPSMode_Ctrl);

/* ---- instance handles ---- */
unsigned u4CPSA_Inst_GetInstHandleFromCompId(unsigned compid)
{
    if (compid == 0) {
        /* module-init gate: compid 0 must read as "free" (-1) */
        printk(KERN_INFO "bdpvirt: GetInstHandle compid=0 -> free (-1)\n");
        return (unsigned)-1;
    }
    printk(KERN_INFO "bdpvirt: GetInstHandle compid=%u -> handle 1\n", compid);
    return 1;
}
EXPORT_SYMBOL(u4CPSA_Inst_GetInstHandleFromCompId);

/* ---- component connect/disconnect ---- */
int i4CPSA_Inst_Connect(unsigned a, unsigned b, unsigned c, unsigned d)
{
    printk(KERN_INFO "bdpvirt: Connect(%u, %u, %u, %u) -> 0\n", a, b, c, d);
    return 0;
}
EXPORT_SYMBOL(i4CPSA_Inst_Connect);

int i4CPSA_Inst_Disconnect(unsigned a, unsigned b, unsigned c)
{
    return 0;
}
EXPORT_SYMBOL(i4CPSA_Inst_Disconnect);

/* ---- virtual ODD: raw 2064-byte frame service ----
 * The real _IDECLI_OddRead (bdpdrv) reads raw frames from the optical
 * drive: 12-byte header + 2048 logical bytes + 4 trailing, per the
 * module-contract disassembly (.text+0x318) and the on-player pair
 * capture design. This implementation serves the same shape from the
 * tmpfs fixture (/res/dev/sr0 — the same bytes userspace reads through
 * the tmpredir map), with the synthetic header proven accepted by the
 * daemon in the qemu-user rig: 3-byte LE LSN, 0x5a marker, zero pad.
 * Return 0 on success (decoded: ioctl 5303 checks result == 0).
 */
#include <linux/fs.h>
#include <linux/slab.h>

#define FRAME_SIZE 2064
#define LOGICAL_SIZE 2048

int _IDECLI_OddRead(unsigned lsn, unsigned blocks, void *buf,
                    unsigned len, unsigned flag)
{
    static struct file *fix;
    unsigned i;
    int err = 0;

    if (blocks == 0 || !buf)
        return -1;
    if (len < blocks * FRAME_SIZE)
        return -1;
    if (!fix) {
        /* O_LARGEFILE is REQUIRED: 2.6.35 generic_file_open rejects images
         * over MAX_NON_LFS (2 GiB) without it (fs/open.c:1083) — the real
         * Firebird ISO is 2.03 GiB. Caught via the virtual-drive team's
         * review before any large-image run. */
        fix = filp_open("/res/dev/sr0", O_RDONLY | O_LARGEFILE, 0);
        if (IS_ERR(fix)) {
            printk(KERN_ERR "bdpvirt: OddRead: no fixture (%ld)\n",
                   PTR_ERR(fix));
            fix = NULL;
            return -1;
        }
    }
    /* kernel_read performs the KERNEL_DS set_fs internally (2.6.35), so
     * no uaccess.h is needed here — pulling it in would compile V7-only
     * barriers (isb) into this ARMv6 module. */
    for (i = 0; i < blocks; i++) {
        uint8_t *frame = (uint8_t *)buf + i * FRAME_SIZE;
        unsigned l = lsn + i;
        unsigned long got;
        memset(frame, 0, FRAME_SIZE);
        frame[0] = (uint8_t)(l);
        frame[1] = (uint8_t)(l >> 8);
        frame[2] = (uint8_t)(l >> 16);
        frame[3] = 0x5a;
        /* Sony's tree backported the loff_t-offset kernel_read
         * (include/linux/fs.h: kernel_read(struct file *, loff_t, char *,
         * unsigned long)) — pass the 64-bit offset directly; a 32-bit
         * cast truncates past 2 GiB. */
        got = kernel_read(fix, (loff_t)l * LOGICAL_SIZE,
                          (char *)(frame + 12), LOGICAL_SIZE);
        if (got != LOGICAL_SIZE) {
            printk(KERN_ERR "bdpvirt: OddRead: got %lu at lsn %u\n", got, l);
            err = -1;
            break;
        }
    }
    printk(KERN_INFO "bdpvirt: OddRead lsn=%u blocks=%u -> %d\n",
           lsn, blocks, err);
    return err;
}
EXPORT_SYMBOL(_IDECLI_OddRead);

/* Decoded from CPSA_SACDCmdDecrypt: called as Decrypt(handle, src_frame,
 * slab, 2064) after GetInstHandleFromCompId(minor); must be >= 0. The
 * module then copies slab+12 (2048 logical bytes) — the offset-12 packing
 * the real CPSA hardware performs. A verbatim frame copy preserves the
 * header and leaves the logical payload exactly where the module's
 * memcpy takes it from. This is NOT real CPSA crypto: plaintext fixtures
 * only; real-hardware decrypt output remains the on-player pair
 * capture's ground truth.
 */
int _i4CPSA_Inst_Decrypt(unsigned handle, void *src, void *dst, unsigned len)
{
    if (len != FRAME_SIZE || !src || !dst)
        return -1;
    memcpy(dst, src, FRAME_SIZE);
    return 0;
}
EXPORT_SYMBOL(_i4CPSA_Inst_Decrypt);

/* ---- presence stubs ---- */
int i4CPSA_Inst_SetSACDControl(int x)
{
    return 0;
}
EXPORT_SYMBOL(i4CPSA_Inst_SetSACDControl);

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

int _IDECLI_OddTestUnitReadyLoop(unsigned long a, void *out)
{
    /* arg0 is NOT a string (live kernel oops from a %s printk of it);
     * return 0 -> daemon poll reports "Disc inserted" (observed). */
    printk(KERN_INFO "bdpvirt: TestUnitReadyLoop(a=0x%lx)\n", a);
    return 0;
}
EXPORT_SYMBOL(_IDECLI_OddTestUnitReadyLoop);

int _IDECLI_OddGetProfile(void *out)
{
    /* Team finding: sacd_read.ko's 5307 (SACD status) handler passes an
     * output pointer and subsequently compares the value with 0x10 (the
     * SACD profile). Returning success without writing the output left
     * the comparison reading uninitialized memory. Write the
     * SACD-present profile consistently; the direct 5307 ioctl check
     * (sacdstat) covers this contract on every run. */
    if (out)
        *(unsigned int *)out = 0x10;
    printk(KERN_INFO "bdpvirt: GetProfile(out=%p) -> profile 0x10\n", out);
    return 0;
}
EXPORT_SYMBOL(_IDECLI_OddGetProfile);

/* ---- sacrificial tail markers ----
 * Sony's 2.6.35 layout_symtab/add_kallsyms off-by-one drops the LAST
 * symtab entry of every loaded module from kallsyms; bdpswap.py moves
 * marker_2 into that slot so every provider symbol survives.
 */
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
