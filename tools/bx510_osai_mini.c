/* osai_mini.c — minimal x_memset provider for the BX510 guest.
 *
 * The real sacd_read.ko (embedded in sacd_extract_160, vermagic
 * "2.6.35 preempt mod_unload ARMv6", no MODVERSIONS) imports exactly one
 * non-kernel symbol: x_memset. On a real player that export comes from the
 * OSAL layer loaded by the system init (osai.ko in /lib/modules/2.6.35/BDP,
 * which itself needs initramfs-provided base modules we cannot yet load).
 * This stub provides the same export with the same semantics observed in
 * osai.ko's own disassembly (a plain memset passthrough returning dest),
 * letting the daemon's own real insmod complete and the module's genuine
 * init/hardware probing run. It deliberately provides NOTHING else.
 *
 * Build: against Sony's GPL linux-2.6.35 with mediatek_defconfig.
 */
#include <linux/module.h>
#include <linux/string.h>
#include <linux/types.h>

void *x_memset(void *s, int c, size_t n)
{
    return memset(s, c, n);
}
EXPORT_SYMBOL(x_memset);

static int __init osai_mini_init(void)
{
    printk(KERN_INFO "osai_mini: x_memset provider loaded\n");
    return 0;
}

static void __exit osai_mini_exit(void)
{
    printk(KERN_INFO "osai_mini: unloaded\n");
}

module_init(osai_mini_init);
module_exit(osai_mini_exit);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Minimal x_memset OSAL provider for sacd_read.ko");
