/* bx510_osal_stub.c — STUB/INSTRUMENT: export placeholder OSAL/HAL symbols
 *
 * This module is a deliberate INSTRUMENT: it exports symbols missing
 * from the Sony BX510 2.6.35 kernel export set so that bdpdrv.ko can
 * load far enough to exercise its probe path and emit MMIO.
 *
 * It is NOT part of any reconstruction and must not be treated as such.
 */
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/slab.h>
#include <linux/vmalloc.h>
#include <linux/string.h>
#include <linux/mutex.h>
#include <linux/spinlock.h>
#include <linux/jiffies.h>
#include <linux/delay.h>
#include <linux/ktime.h>
#include <linux/ctype.h>
#include <linux/time.h>
#include <linux/mmzone.h>
#include <linux/mm_types.h>
#include <asm/outercache.h>
#include <stdarg.h>

MODULE_LICENSE("Proprietary");
MODULE_AUTHOR("aftermath (instrument)");
MODULE_DESCRIPTION("BX510 OSAL/HAL symbol stub exports (INSTRUMENT)");

#define STUB_ONCE() do { \
  static int __once; \
  if (!__once) { __once = 1; printk(KERN_INFO "[OSAL_STUB] %s called\n", __func__); } \
} while (0)

static DEFINE_SPINLOCK(g_crit_lock);

/* ---- data symbols (best-effort plausible values) ---- */
unsigned int g_u4Ch1DramSize = 0x08000000; /* 128 MiB */
EXPORT_SYMBOL(g_u4Ch1DramSize);
unsigned int g_u4Ch2DramSize = 0x08000000; /* 128 MiB */
EXPORT_SYMBOL(g_u4Ch2DramSize);
unsigned int g_hSecureHandle = 1;
EXPORT_SYMBOL(g_hSecureHandle);
static DEFINE_MUTEX(g_hwdecode_mutex);
struct mutex *pHwDecode_mutex = &g_hwdecode_mutex;
EXPORT_SYMBOL(pHwDecode_mutex);
/* These are normally core-kernel data symbols; here we define placeholder
 * objects with matching types so the module can link. */
struct kmem_cache kmalloc_caches[KMALLOC_CACHES];
EXPORT_SYMBOL(kmalloc_caches);
struct outer_cache_fns outer_cache;
EXPORT_SYMBOL(outer_cache);
struct pglist_data contig_page_data;
EXPORT_SYMBOL(contig_page_data);
struct mm_struct init_mm;
EXPORT_SYMBOL(init_mm);
const char *usb_cust_model = "BX510";
EXPORT_SYMBOL(usb_cust_model);
unsigned int svoif_int_ldr_dram = 0;
EXPORT_SYMBOL(svoif_int_ldr_dram);

/* ---- helpers ---- */
static int ascii_tolower(int c) { return (c >= 'A' && c <= 'Z') ? (c - 'A' + 'a') : c; }
static int strcasecmp_k(const char *a, const char *b) {
  for (;; a++, b++) {
    int ca = ascii_tolower(*a), cb = ascii_tolower(*b);
    if (ca != cb) return ca - cb;
    if (!ca) return 0;
  }
}

/* ---- special-case function stubs ---- */
void *x_mem_alloc(unsigned long sz, ...) { STUB_ONCE(); if (!sz) sz = 1; return kmalloc(sz, GFP_KERNEL); }
EXPORT_SYMBOL(x_mem_alloc);
void *_x_mem_alloc(unsigned long sz, ...) { return x_mem_alloc(sz); }
EXPORT_SYMBOL(_x_mem_alloc);
void x_mem_free(void *p, ...) { STUB_ONCE(); kfree(p); }
EXPORT_SYMBOL(x_mem_free);
void _x_mem_free(void *p, ...) { x_mem_free(p); }
EXPORT_SYMBOL(_x_mem_free);
void *x_mem_calloc(unsigned long n, unsigned long sz, ...) { STUB_ONCE(); unsigned long total = n * sz; if (!total) total = 1; return kzalloc(total, GFP_KERNEL); }
EXPORT_SYMBOL(x_mem_calloc);
void *x_mem_realloc(void *p, unsigned long sz, ...) { STUB_ONCE(); return krealloc(p, sz, GFP_KERNEL); }
EXPORT_SYMBOL(x_mem_realloc);
void *_x_mem_realloc(void *p, unsigned long sz, ...) { return x_mem_realloc(p, sz); }
EXPORT_SYMBOL(_x_mem_realloc);
void *x_mem_aligned_alloc(unsigned long align, unsigned long sz, ...) { STUB_ONCE(); if (!sz) sz = 1; (void)align; return kmalloc(sz, GFP_KERNEL); }
EXPORT_SYMBOL(x_mem_aligned_alloc);
void x_mem_aligned_free(void *p, ...) { STUB_ONCE(); kfree(p); }
EXPORT_SYMBOL(x_mem_aligned_free);
void *x_mem_valloc(unsigned long sz, ...) { STUB_ONCE(); if (!sz) sz = 1; return vmalloc(sz); }
EXPORT_SYMBOL(x_mem_valloc);
void x_mem_vfree(void *p, ...) { STUB_ONCE(); vfree(p); }
EXPORT_SYMBOL(x_mem_vfree);
void *x_memset(void *dst, int c, unsigned long n, ...) { STUB_ONCE(); return memset(dst, c, n); }
EXPORT_SYMBOL(x_memset);
void *x_memcpy(void *dst, const void *src, unsigned long n, ...) { STUB_ONCE(); return memcpy(dst, src, n); }
EXPORT_SYMBOL(x_memcpy);
long x_memcmp(const void *a, const void *b, unsigned long n, ...) { STUB_ONCE(); return memcmp(a, b, n); }
EXPORT_SYMBOL(x_memcmp);
unsigned long x_strlen(const char *s, ...) { STUB_ONCE(); return strlen(s); }
EXPORT_SYMBOL(x_strlen);
long x_strcmp(const char *a, const char *b, ...) { STUB_ONCE(); return strcmp(a, b); }
EXPORT_SYMBOL(x_strcmp);
long x_strncmp(const char *a, const char *b, unsigned long n, ...) { STUB_ONCE(); return strncmp(a, b, n); }
EXPORT_SYMBOL(x_strncmp);
long x_strcasecmp(const char *a, const char *b, ...) { STUB_ONCE(); return strcasecmp_k(a, b); }
EXPORT_SYMBOL(x_strcasecmp);
long x_strncasecmp(const char *a, const char *b, unsigned long n, ...) { STUB_ONCE(); return strncasecmp(a, b, n); }
EXPORT_SYMBOL(x_strncasecmp);
char *x_strncpy(char *dst, const char *src, unsigned long n, ...) { STUB_ONCE(); return strncpy(dst, src, n); }
EXPORT_SYMBOL(x_strncpy);
char *x_strncat(char *dst, const char *src, unsigned long n, ...) { STUB_ONCE(); return strncat(dst, src, n); }
EXPORT_SYMBOL(x_strncat);
int x_snprintf(char *buf, unsigned long size, const char *fmt, ...) { STUB_ONCE(); va_list ap; int rc; va_start(ap, fmt); rc = vsnprintf(buf, size, fmt, ap); va_end(ap); return rc; }
EXPORT_SYMBOL(x_snprintf);
int x_vsnprintf(char *buf, unsigned long size, const char *fmt, va_list ap, ...) { STUB_ONCE(); return vsnprintf(buf, size, fmt, ap); }
EXPORT_SYMBOL(x_vsnprintf);
int x_sscanf(const char *buf, const char *fmt, ...) { STUB_ONCE(); va_list ap; int rc; va_start(ap, fmt); rc = vsscanf(buf, fmt, ap); va_end(ap); return rc; }
EXPORT_SYMBOL(x_sscanf);
unsigned long long x_strtoull(const char *s, char **endp, int base, ...) { STUB_ONCE(); return simple_strtoull(s, endp, base); }
EXPORT_SYMBOL(x_strtoull);
unsigned long x_os_get_sys_tick(unsigned long a0, ...) { STUB_ONCE(); return jiffies; }
EXPORT_SYMBOL(x_os_get_sys_tick);
unsigned long x_os_get_sys_tick_period(unsigned long a0, ...) { STUB_ONCE(); return (1000 / HZ); }
EXPORT_SYMBOL(x_os_get_sys_tick_period);
unsigned long x_crit_start(unsigned long a0, ...) { unsigned long flags; STUB_ONCE(); spin_lock_irqsave(&g_crit_lock, flags); return flags; }
EXPORT_SYMBOL(x_crit_start);
void x_crit_end(unsigned long flags, ...) { STUB_ONCE(); spin_unlock_irqrestore(&g_crit_lock, flags); }
EXPORT_SYMBOL(x_crit_end);
unsigned long HalCriticalStart(unsigned long a0, ...) { unsigned long flags; STUB_ONCE(); spin_lock_irqsave(&g_crit_lock, flags); return flags; }
EXPORT_SYMBOL(HalCriticalStart);
void HalCriticalEnd(unsigned long flags, ...) { STUB_ONCE(); spin_unlock_irqrestore(&g_crit_lock, flags); }
EXPORT_SYMBOL(HalCriticalEnd);
unsigned long HAL_GetTime(unsigned long a0, ...) {
  struct timeval tv;
  STUB_ONCE();
  do_gettimeofday(&tv);
  return (unsigned long)tv.tv_sec;
}
EXPORT_SYMBOL(HAL_GetTime);
unsigned long HAL_GetRawTime(unsigned long a0, ...) {
  struct timeval tv;
  STUB_ONCE();
  do_gettimeofday(&tv);
  /* microseconds since epoch (best-effort) */
  return (unsigned long)(tv.tv_sec * 1000000UL + tv.tv_usec);
}
EXPORT_SYMBOL(HAL_GetRawTime);
unsigned long HAL_GetFineTick(unsigned long a0, ...) {
  struct timeval tv;
  STUB_ONCE();
  do_gettimeofday(&tv);
  return (unsigned long)tv.tv_usec;
}
EXPORT_SYMBOL(HAL_GetFineTick);
unsigned long HAL_GetDeltaTime(unsigned long a, unsigned long b, ...) { STUB_ONCE(); return (b - a); }
EXPORT_SYMBOL(HAL_GetDeltaTime);
void HAL_Delay_us(unsigned long us, ...) { STUB_ONCE(); udelay(us); }
EXPORT_SYMBOL(HAL_Delay_us);
unsigned long CKGEN_AgtGetClk(unsigned long a0, ...) { STUB_ONCE(); return 27000000; }
EXPORT_SYMBOL(CKGEN_AgtGetClk);
unsigned long CKGEN_AgtSelClk(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(CKGEN_AgtSelClk);
unsigned long CKGEN_AgtOnClk(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(CKGEN_AgtOnClk);
unsigned long CKGEN_AgtOffClk(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(CKGEN_AgtOffClk);
unsigned long BIM_ClearIrq(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(BIM_ClearIrq);
unsigned long BIM_DisableIrq(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(BIM_DisableIrq);
unsigned long BIM_EnableIrq(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(BIM_EnableIrq);
unsigned long BIM_IsIrqEnabled(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(BIM_IsIrqEnabled);
unsigned long BIM_SetSysHaltResetMode(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(BIM_SetSysHaltResetMode);
unsigned long BIM_GetSysHaltResetMode(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(BIM_GetSysHaltResetMode);
unsigned long BIM_RegResetIrKey(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(BIM_RegResetIrKey);
unsigned long BIM_GetResetIrKey(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(BIM_GetResetIrKey);
unsigned long TzServiceCall(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(TzServiceCall);
static int osal_stub_vprintk(const char *tag, const char *fmt, va_list ap)
{
  if (!fmt) {
    printk(KERN_INFO "[OSAL_STUB] %s: <NULL fmt>\n", tag);
    return 0;
  }
  return vprintk(fmt, ap);
}

int Printf(const char *fmt, ...) { va_list ap; int rc; STUB_ONCE(); va_start(ap, fmt); rc = osal_stub_vprintk("Printf", fmt, ap); va_end(ap); return rc; }
EXPORT_SYMBOL(Printf);
int SYS_Printf(const char *fmt, ...) { va_list ap; int rc; STUB_ONCE(); va_start(ap, fmt); rc = osal_stub_vprintk("SYS_Printf", fmt, ap); va_end(ap); return rc; }
EXPORT_SYMBOL(SYS_Printf);
int UTIL_Printf(const char *fmt, ...) { va_list ap; int rc; STUB_ONCE(); va_start(ap, fmt); rc = osal_stub_vprintk("UTIL_Printf", fmt, ap); va_end(ap); return rc; }
EXPORT_SYMBOL(UTIL_Printf);
int vdbg_printf(const char *fmt, ...) { va_list ap; int rc; STUB_ONCE(); va_start(ap, fmt); rc = osal_stub_vprintk("vdbg_printf", fmt, ap); va_end(ap); return rc; }
EXPORT_SYMBOL(vdbg_printf);
void Assert(unsigned long a0, ...) { STUB_ONCE(); dump_stack(); }
EXPORT_SYMBOL(Assert);
unsigned long StrToHex(const char *s, ...) { STUB_ONCE(); return simple_strtoul(s, NULL, 16); }
EXPORT_SYMBOL(StrToHex);
long StrToInt(const char *s, ...) { STUB_ONCE(); return (long)simple_strtol(s, NULL, 10); }
EXPORT_SYMBOL(StrToInt);

/* ---- generic stubs for the remaining missing symbols ---- */
unsigned long _SupportiPod(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(_SupportiPod);
unsigned long x_cli_attach_cmd_tbl(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_cli_attach_cmd_tbl);
unsigned long _x_mem_part_create(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(_x_mem_part_create);
unsigned long GetCbkCmdTbl(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(GetCbkCmdTbl);
unsigned long _x_mem_ch2_alloc(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(_x_mem_ch2_alloc);
unsigned long x_sema_create(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_sema_create);
unsigned long x_rm_unreg_comp(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_rm_unreg_comp);
unsigned long x_timer_start(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_timer_start);
unsigned long x_sema_unlock(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_sema_unlock);
unsigned long x_kmem_block_aligned_alloc(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_kmem_block_aligned_alloc);
unsigned long init_static_memory(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(init_static_memory);
unsigned long x_msg_q_send(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_msg_q_send);
unsigned long x_kmem_addr_user_to_kernel(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_kmem_addr_user_to_kernel);
unsigned long x_rm_reg_conn_list(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_rm_reg_conn_list);
unsigned long x_kmem_create_handle(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_kmem_create_handle);
unsigned long x_ev_group_create(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_ev_group_create);
unsigned long x_cli_detach_cmd_tbl(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_cli_detach_cmd_tbl);
unsigned long x_ev_group_wait_event_timeout(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_ev_group_wait_event_timeout);
unsigned long x_mem_fill_caller(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_mem_fill_caller);
unsigned long u4HalGetTTB1(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(u4HalGetTTB1);
unsigned long x_cli_parser(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_cli_parser);
unsigned long addr_kernel_to_user(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(addr_kernel_to_user);
unsigned long x_thread_create(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_thread_create);
unsigned long x_ev_group_get_info(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_ev_group_get_info);
unsigned long _fgHWBySquash(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(_fgHWBySquash);
unsigned long x_reg_isr_ex(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_reg_isr_ex);
unsigned long HalFlushInvalidateDCache(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(HalFlushInvalidateDCache);
unsigned long x_kmem_block_info(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_kmem_block_info);
unsigned long x_rm_reg_group_type(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_rm_reg_group_type);
unsigned long x_msg_q_create(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_msg_q_create);
unsigned long x_sema_delete(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_sema_delete);
unsigned long vHalCounterStop(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(vHalCounterStop);
unsigned long u4HalGetTTB(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(u4HalGetTTB);
unsigned long x_rm_reg_smp_cb(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_rm_reg_smp_cb);
unsigned long x_msg_q_num_msgs(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_msg_q_num_msgs);
unsigned long _gBspGetFuncID(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(_gBspGetFuncID);
unsigned long x_rm_reg_comp(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_rm_reg_comp);
unsigned long x_kmem_block_handle(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_kmem_block_handle);
unsigned long i4LockDecryResource(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(i4LockDecryResource);
unsigned long x_timer_create(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_timer_create);
unsigned long x_thread_exit(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_thread_exit);
unsigned long x_ev_group_delete(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_ev_group_delete);
unsigned long x_thread_get_pri(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_thread_get_pri);
unsigned long _x_mem_part_alloc(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(_x_mem_part_alloc);
unsigned long vCBAgent_Cb_Nfy(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(vCBAgent_Cb_Nfy);
unsigned long x_thread_set_pri(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_thread_set_pri);
unsigned long vHalDCacheHitRateStart(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(vHalDCacheHitRateStart);
unsigned long x_thread_get_name(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_thread_get_name);
unsigned long fgHalCount1OverFlow(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(fgHalCount1OverFlow);
unsigned long vHalICacheHitRateStart(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(vHalICacheHitRateStart);
unsigned long x_msg_q_delete(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_msg_q_delete);
unsigned long x_kmem_sync_table(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_kmem_sync_table);
unsigned long x_timer_stop(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_timer_stop);
unsigned long x_rm_reg_comp_excl_list(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_rm_reg_comp_excl_list);
unsigned long fgHalCount0OverFlow(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(fgHalCount0OverFlow);
unsigned long GetRmkCmdTbl(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(GetRmkCmdTbl);
unsigned long x_sema_lock_timeout(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_sema_lock_timeout);
unsigned long x_mem_part_alloc(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_mem_part_alloc);
unsigned long x_sema_lock(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_sema_lock);
unsigned long x_kmem_block_sliced_aligned_alloc(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_kmem_block_sliced_aligned_alloc);
unsigned long x_timer_delete(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_timer_delete);
unsigned long x_reg_isr(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_reg_isr);
unsigned long u4Set_Jtag(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(u4Set_Jtag);
unsigned long u4HalGetCountRegister0(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(u4HalGetCountRegister0);
unsigned long u4HalGetCountRegister1(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(u4HalGetCountRegister1);
unsigned long x_kmem_block_alloc(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_kmem_block_alloc);
unsigned long os_cli_show_mem_all_detail(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(os_cli_show_mem_all_detail);
unsigned long cli_init(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(cli_init);
unsigned long x_mem_part_create(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_mem_part_create);
unsigned long x_kmem_destroy_handle(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_kmem_destroy_handle);
unsigned long _fgHWByDrv(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(_fgHWByDrv);
unsigned long x_ev_group_wait_event(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_ev_group_wait_event);
unsigned long x_thread_delay(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_thread_delay);
unsigned long x_ev_group_set_event(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_ev_group_set_event);
unsigned long x_rm_reg_group_name(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_rm_reg_group_name);
unsigned long u4Jtag_Condition(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(u4Jtag_Condition);
unsigned long vSet_Dram_BW(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(vSet_Dram_BW);
unsigned long x_kmem_block_aligned_free(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_kmem_block_aligned_free);
unsigned long x_thread_self(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_thread_self);
unsigned long addr_user_to_kernel(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(addr_user_to_kernel);
unsigned long vCBAgent_SyncCb_Nfy(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(vCBAgent_SyncCb_Nfy);
unsigned long x_rm_reg_conn_excl_list(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_rm_reg_conn_excl_list);
unsigned long x_kmem_kernel_address(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_kmem_kernel_address);
unsigned long x_kmem_block_free(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_kmem_block_free);
unsigned long x_msg_q_receive(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_msg_q_receive);
unsigned long x_cli_parser_arg(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_cli_parser_arg);
unsigned long GetOsCmdTbl(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(GetOsCmdTbl);

static int __init osal_stub_init(void) { printk(KERN_INFO "[OSAL_STUB] loaded (INSTRUMENT)\n"); return 0; }
static void __exit osal_stub_exit(void) { printk(KERN_INFO "[OSAL_STUB] unloaded\n"); }
module_init(osal_stub_init);
module_exit(osal_stub_exit);
