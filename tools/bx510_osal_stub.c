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
#include <linux/semaphore.h>
#include <linux/wait.h>
#include <linux/kthread.h>
#include <linux/hardirq.h>
#include <linux/jiffies.h>
#include <linux/delay.h>
#include <linux/ktime.h>
#include <linux/ctype.h>
#include <linux/time.h>
#include <linux/mmzone.h>
#include <linux/mm.h>
#include <linux/mm_types.h>
#include <asm/outercache.h>
#include <stdarg.h>


/* ==== TWO-PART BUILD (Run C33+) =====================================
   The stub compiles twice:
     STUB_PART_A  - tiny provider loaded FIRST: exports only what the
                    real drvcli.ko needs (UTIL_Printf + the two log
                    switches drvcli imports and nothing in the guest
                    kernel or BDP set provides).
     default (B)  - the full stub MINUS the CLI framework symbols
                    (real drvcli provides them) and minus part-A's.
   Order in the probe: drvcli.ko -> osal_stub_a.ko -> osal_stub.ko -> bdpdrv.
   ==================================================================== */
#ifdef STUB_PART_A
unsigned int g_u4disable_log;
EXPORT_SYMBOL(g_u4disable_log);
unsigned int g_u4enable_log_droped;
EXPORT_SYMBOL(g_u4enable_log_droped);

MODULE_LICENSE("Proprietary");
MODULE_AUTHOR("aftermath (instrument)");
MODULE_DESCRIPTION("BX510 OSAL stub part A: drvcli provider (INSTRUMENT)");

/* UTIL_Printf: drvcli.ko imports it; defined here (part A) so the REAL
   CLI framework links against a live print primitive. */
static int osal_stub_vprintk_a(const char *tag, const char *fmt, va_list ap)
{
  if (!fmt) {
    printk(KERN_INFO "[OSAL_STUB] %s: <NULL fmt>\n", tag);
    return 0;
  }
  return vprintk(fmt, ap);
}
int UTIL_Printf(const char *fmt, ...)
{
  va_list ap; int rc;
  va_start(ap, fmt);
  rc = osal_stub_vprintk_a("UTIL", fmt, ap);
  va_end(ap);
  return rc;
}
EXPORT_SYMBOL(UTIL_Printf);

static int __init osal_stub_init(void)
{
  printk(KERN_INFO "[OSAL_STUB] part A loaded (provider for drvcli)\n");
  return 0;
}
static void __exit osal_stub_exit(void) { }
module_init(osal_stub_init);
module_exit(osal_stub_exit);
#else

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
void *x_memset(void *dst, int c, unsigned long n, ...) {
  STUB_ONCE();
  if (n >= 0x1000)
    printk(KERN_INFO "[OSAL_STUB] x_memset dst=%px n=%#lx caller=%pf\n",
           dst, n, __builtin_return_address(0));
  return memset(dst, c, n);
}
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
/* VERIFIED (Run C2 root cause, bdpdrv i4IdeDrvInit 0x987e8): Sony's OSAL
   exports x_crit_start/x_crit_end as FUNCTION-POINTER VARIABLES, not
   functions. bdpdrv (121 ABS32 sites each, zero direct calls) does
   ldr r3,[lit->&sym]; ldr r3,[r3]; blx r3 — the deref loads the pointer
   VALUE. When the stub exported a function, r3 loaded the function's own
   prologue word (0xe92d000f = push {r0-r3}) and blx jumped to it as a
   thumb address -> Oops PC=0xe92d000e. These must be data objects whose
   value is a function address. The matrix tool (bx510_ko_classify_matrix)
   shows drvuart.ko and splitter.ko deref-call them the same way. */
/* Run C3 lesson (hypothesis for post-init hang): Sony critical sections
   NEST. A non-recursive spin lock self-deadlocks when a path takes it
   twice. Count depth UP-side: only take the raw lock on 0->1, release on
   1->0; print the first few transitions with depth so a nesting hang is
   visible in the UART. */
static int g_crit_depth;
static unsigned long g_crit_nest_flags;
static int g_crit_prints;
unsigned long x_crit_start_impl(unsigned long a0, ...) {
  unsigned long flags;
  if (g_crit_depth == 0) {
    spin_lock_irqsave(&g_crit_lock, flags);
    g_crit_nest_flags = flags;
  }
  g_crit_depth++;
  if (g_crit_prints < 8)
    printk(KERN_INFO "[OSAL_STUB] crit_start depth=%d n=%d\n", g_crit_depth, ++g_crit_prints);
  return (unsigned long)g_crit_depth;
}
void x_crit_end_impl(unsigned long token, ...) {
  if (g_crit_depth > 0 && (unsigned long)g_crit_depth == token) {
    g_crit_depth--;
    if (g_crit_depth == 0) spin_unlock_irqrestore(&g_crit_lock, g_crit_nest_flags);
  }
  if (g_crit_prints < 16)
    printk(KERN_INFO "[OSAL_STUB] crit_end depth=%d\n", g_crit_depth);
}
unsigned long (*x_crit_start)(unsigned long, ...) = x_crit_start_impl;
EXPORT_SYMBOL(x_crit_start);
void (*x_crit_end)(unsigned long, ...) = x_crit_end_impl;
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
int vdbg_printf(const char *fmt, ...) { va_list ap; int rc; STUB_ONCE(); va_start(ap, fmt); rc = osal_stub_vprintk("vdbg_printf", fmt, ap); va_end(ap); return rc; }
EXPORT_SYMBOL(vdbg_printf);
/* VERIFIED convention CORRECTION (Run C6 prep; overturns the C2-era
   reading): Assert is called ONLY when the condition already failed —
   the call site branches on the condition first (e.g. drv_MemUtil_Init
   0x127064: cmp r3,#0; bne skip; then Assert) — and passes
   (r0=expr STRING, r1=file STRING, r2=line NUMBER). Verified at
   0x545b8 ("0", "src/driver/cpsa/cpsa_main.c", 0x2d9) and 0x127078
   (expr, file, 0x525). The old stub read r0 as a condition and never
   fired (string pointers are never 0), silently swallowing every
   failing assert. Now: every call IS a fired assert. */
void Assert(const char *expr, const char *file, unsigned long line) {
  /* Globally rate-limited (Run C40: four hot sites interleave, defeating
     single-site memory; the flood itself interleaved probe output).
     First 24 asserts print; then every 4096th carries a summary. */
  static unsigned long __tot;
  __tot++;
  if (__tot <= 24) {
    printk(KERN_INFO "[OSAL_STUB] Assert FIRED: %s (%s:%lu)\n",
           expr ? expr : "(null)", file ? file : "(null)", line);
    return;
  }
  if ((__tot & 0xfff) == 0)
    printk(KERN_INFO "[OSAL_STUB] Assert x%lu total (last: %s:%lu)\n",
           __tot, file ? file : "?", line);
}
EXPORT_SYMBOL(Assert);

/* ---- data-class exports (VERIFIED usage-classified via
   tools/bx510_ko_symbol_classify.py against bdpdrv.ko + all 69 BDP
   siblings, Run C3 prep). These were function stubs in stub v2 and are
   now plain data objects: bdpdrv addresses them ABS32-only, no call of
   either kind (_fgHWByDrv/_fgHWBySquash are strb-written byte flags,
   _gBspGetFuncID gets str r2,[r3,#8] as a fielded object). Defaults are
   honest placeholders. */
unsigned long _SupportiPod;    /* data: bdpdrv+usbcore address it, never call */
EXPORT_SYMBOL(_SupportiPod);
unsigned long _fgHWBySquash;   /* data: bdpdrv writes it */
EXPORT_SYMBOL(_fgHWBySquash);
unsigned long _gBspGetFuncID[4]; /* data: bdpdrv writes field [1] (str r2,[r3,#8]) */
EXPORT_SYMBOL(_gBspGetFuncID);
unsigned long _fgHWByDrv;      /* data: bdpdrv writes it (lit@0x1c6cac) */
EXPORT_SYMBOL(_fgHWByDrv);

/* NOTE (Run C33+): cli_init / x_cli_attach_cmd_tbl / x_cli_detach_cmd_tbl /
   x_cli_parser / x_cli_parser_arg / StrToHex / StrToInt are NOT stubbed —
   the real drvcli.ko (guest rootfs BDP set, zero undefined syms) provides
   them and is insmodded BEFORE this stub so bdpdrv links against the REAL
   CLI framework (a live runtime command channel instead of no-ops). */

/* ---- generic stubs for the remaining missing symbols ---- */
unsigned long _x_mem_part_create(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(_x_mem_part_create);
unsigned long GetCbkCmdTbl(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(GetCbkCmdTbl);
unsigned long _x_mem_ch2_alloc(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(_x_mem_ch2_alloc);
unsigned long x_rm_unreg_comp(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_rm_unreg_comp);
unsigned long x_timer_start(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_timer_start);
/* init_static_memory(name, cached_flag, size, align) -> pointer.
   VERIFIED call convention from drv_MemUtil_Init (bdpdrv 0x12700c/0x127034/
   0x12704c): returns the carved pointer, 0 on failure; the driver asserts
   the returned pointers non-NULL ("g_pvAdspFifo != NULL && ..."). Named
   regions are carved once from one arena; repeated names return the same
   chunk (idempotent re-init safe). INSTRUMENT quality: arena is
   vmalloc-backed, cacheline-aligned start. */
static unsigned char *g_ism_pool;
static unsigned long g_ism_off, g_ism_size = (32u << 20);
struct ism_ent { char name[48]; unsigned long ptr, size; };
static struct ism_ent g_ism_tab[32];
static int g_ism_n;
unsigned long init_static_memory(const char *name, unsigned long flag,
                                 unsigned long size, unsigned long align) {
  unsigned long a = align ? align : 256;
  int i;
  STUB_ONCE();
  if (!g_ism_pool) g_ism_pool = vmalloc(g_ism_size);
  if (!g_ism_pool) return 0;
  for (i = 0; i < g_ism_n; i++)
    if (!strncmp(g_ism_tab[i].name, name, sizeof g_ism_tab[i].name))
      return g_ism_tab[i].ptr;
  if (g_ism_n >= (int)(sizeof g_ism_tab / sizeof g_ism_tab[0])) return 0;
  g_ism_off = (g_ism_off + a - 1) & ~(a - 1);
  if (g_ism_off + size > g_ism_size) return 0;
  strncpy(g_ism_tab[g_ism_n].name, name, sizeof g_ism_tab[g_ism_n].name - 1);
  g_ism_tab[g_ism_n].ptr = (unsigned long)(g_ism_pool + g_ism_off);
  g_ism_tab[g_ism_n].size = size;
  g_ism_off += size;
  printk(KERN_INFO "[OSAL_STUB] init_static_memory(%s, flag=%lu, size=%lu, align=%lu) -> %pad\n",
         name, flag, size, align, (void *)&g_ism_tab[g_ism_n].ptr);
  return g_ism_tab[g_ism_n++].ptr;
}
EXPORT_SYMBOL(init_static_memory);
unsigned long x_rm_reg_conn_list(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_rm_reg_conn_list);
unsigned long u4HalGetTTB1(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(u4HalGetTTB1);
unsigned long x_reg_isr_ex(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_reg_isr_ex);
unsigned long HalFlushInvalidateDCache(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(HalFlushInvalidateDCache);
unsigned long x_rm_reg_group_type(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_rm_reg_group_type);
unsigned long vHalCounterStop(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(vHalCounterStop);
unsigned long u4HalGetTTB(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(u4HalGetTTB);
unsigned long x_rm_reg_smp_cb(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_rm_reg_smp_cb);
unsigned long x_rm_reg_comp(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_rm_reg_comp);
unsigned long i4LockDecryResource(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(i4LockDecryResource);
unsigned long x_timer_create(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_timer_create);
unsigned long _x_mem_part_alloc(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(_x_mem_part_alloc);
unsigned long vCBAgent_Cb_Nfy(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(vCBAgent_Cb_Nfy);
unsigned long x_thread_set_pri(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_thread_set_pri);
unsigned long vHalDCacheHitRateStart(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(vHalDCacheHitRateStart);
unsigned long fgHalCount1OverFlow(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(fgHalCount1OverFlow);
unsigned long vHalICacheHitRateStart(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(vHalICacheHitRateStart);
unsigned long x_timer_stop(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_timer_stop);
unsigned long x_rm_reg_comp_excl_list(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_rm_reg_comp_excl_list);
unsigned long fgHalCount0OverFlow(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(fgHalCount0OverFlow);
unsigned long GetRmkCmdTbl(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(GetRmkCmdTbl);
unsigned long x_mem_part_alloc(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_mem_part_alloc);
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
unsigned long os_cli_show_mem_all_detail(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(os_cli_show_mem_all_detail);
unsigned long x_mem_part_create(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_mem_part_create);
unsigned long x_thread_self(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_thread_self);
/* Run C4 instrument: print-once hides hot loops. Counter-print the park
   primitives: first 4 calls by name, then every 256th with the count. */
#define STUB_COUNTED(name) do { \
  static unsigned long __n; \
  __n++; \
  if (__n <= 4) printk(KERN_INFO "[OSAL_STUB] %s called #%lu\n", name, __n); \
  else if ((__n & 0xff) == 0) printk(KERN_INFO "[OSAL_STUB] %s called #%lu\n", name, __n); \
} while (0)

unsigned long x_thread_delay(unsigned long a0, ...) {
  static unsigned long __n;
  unsigned long lr = (unsigned long)__builtin_return_address(0);
  __n++;
  if (__n <= 4 || (__n & 0xff) == 0)
    printk(KERN_INFO "[OSAL_STUB] x_thread_delay #%lu arg=%lu caller=%pf\n",
           __n, a0, (void *)lr);
  /* Run C17 decisive instrument: the vGCPU_InstanceDestroy bit2-poll site
     is at .ko offset 0x174394 (LR of the delay call). From LR we recover
     the module base and read the GCPU slot-0 state word (base+0xb18e4)
     the poller is spinning on. */
  if ((lr & 0xff) == 0x94 && a0 == 1) {
    unsigned long base = lr - 0x174394;
    unsigned int *w = (unsigned int *)(base + 0xb18e4);
    static unsigned long __p;
    __p++;
    if ((__p & 0xff) == 0)
      printk(KERN_INFO "[OSAL_STUB] gcpu slot0 state=%#x base=%#lx\n", *w, base);
  }
  msleep(a0 > 100 ? 100 : a0);
  return 0;
}
EXPORT_SYMBOL(x_thread_delay);
unsigned long x_rm_reg_group_name(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_rm_reg_group_name);
unsigned long u4Jtag_Condition(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(u4Jtag_Condition);
unsigned long vSet_Dram_BW(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(vSet_Dram_BW);
unsigned long vCBAgent_SyncCb_Nfy(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(vCBAgent_SyncCb_Nfy);
unsigned long x_rm_reg_conn_excl_list(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_rm_reg_conn_excl_list);
unsigned long x_mem_fill_caller(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_mem_fill_caller);
unsigned long GetOsCmdTbl(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(GetOsCmdTbl);


/* =====================================================================
   MINI-OSAL (Run C9+): real threads/semaphores/event-groups/msg-queues.
   ABIs VERIFIED from bdpdrv call sites + assert strings:
     x_sema_create(&h, type, state)              type=BINARY==2, state=UNLOCK==1 (observed 2,1)
     x_sema_lock(h, option)                      option=1 observed at all GCPU sites (WAIT)
     x_sema_unlock(h); x_sema_delete(h)
     x_ev_group_create(&h, name, 0)
     x_ev_group_set_event(h, mask, op)           op=3 observed (OR)
     x_ev_group_wait_event(h, mask, &got, op)    op=5 observed (OR_CONSUME)
     x_msg_q_create(&h, buf, msg_size, depth)    GCPU: (.., 0xc, 0xa)
     x_msg_q_send(h, msg, size, pri)             0 = OSR_OK
     x_msg_q_receive(&idx, &msg, &size, &h, cnt, option)  option=1 = WAIT
     x_thread_create(&h, name, stack, pri, fct, flag, arg)  (fct on stack arg 5)
     x_thread_exit(code); x_thread_get_name(h, char **ppName) -> stores
     POINTER to name (sites reload it for memcmp); x_thread_get_pri(h, &pri)
   All success returns are 0 (cmp r0,#0 / beq-ok patterns).
   Handles are kernel object pointers; 0 never returned on success.
   ===================================================================== */
struct osal_sema { struct semaphore sem; };
struct osal_ev { spinlock_t lock; wait_queue_head_t wq; unsigned long flags; };
struct osal_mq { spinlock_t lock; wait_queue_head_t wq; unsigned char *buf;
                 unsigned long msg_size, depth, head, tail, count; };
struct osal_thr { void (*fct)(void *); void *arg; struct completion started;
                  struct task_struct *tsk; struct list_head list; };
/* live-thread registry: get_name/get_pri must FAIL for dead handles
   (driver polls for thread exit by name lookup), and protects against
   UAF on exited kthreads. */
static LIST_HEAD(osal_threads);
static DEFINE_SPINLOCK(osal_threads_lock);
static int osal_thread_live(const struct task_struct *t)
{
  struct osal_thr *e; int live = 0; unsigned long f;
  spin_lock_irqsave(&osal_threads_lock, f);
  list_for_each_entry(e, &osal_threads, list)
    if (e->tsk == t) { live = 1; break; }
  spin_unlock_irqrestore(&osal_threads_lock, f);
  return live;
}
/* shared wake source for multi-queue receive */
static wait_queue_head_t osal_mq_wq;

unsigned long x_sema_create(unsigned long *ph, unsigned long type, unsigned long state, ...)
{
  struct osal_sema *o = kmalloc(sizeof *o, GFP_KERNEL);
  STUB_ONCE();
  if (!o) return 1;
  sema_init(&o->sem, 1);   /* STATE_UNLOCK => count 1; BINARY */
  *ph = (unsigned long)o;
  return 0;
}
EXPORT_SYMBOL(x_sema_create);
unsigned long x_sema_lock(unsigned long h, unsigned long option, ...)
{
  struct osal_sema *o = (struct osal_sema *)h;
  STUB_COUNTED("x_sema_lock");
  if (!o) return 1;
  if (option == 1) down(&o->sem);
  else if (down_trylock(&o->sem)) return 1;
  return 0;
}
EXPORT_SYMBOL(x_sema_lock);
unsigned long x_sema_unlock(unsigned long h, ...)
{
  struct osal_sema *o = (struct osal_sema *)h;
  if (!o) return 1;
  up(&o->sem);
  return 0;
}
EXPORT_SYMBOL(x_sema_unlock);
unsigned long x_sema_lock_timeout(unsigned long h, unsigned long option, ...)
{
  struct osal_sema *o = (struct osal_sema *)h;
  STUB_ONCE();
  if (!o) return 1;
  if (option == 1) down(&o->sem);
  else if (down_trylock(&o->sem)) return 1;
  return 0;
}
EXPORT_SYMBOL(x_sema_lock_timeout);
unsigned long x_sema_delete(unsigned long h, ...)
{
  STUB_ONCE();
  kfree((void *)h);
  return 0;
}
EXPORT_SYMBOL(x_sema_delete);

unsigned long x_ev_group_create(unsigned long *ph, const char *name, unsigned long flags, ...)
{
  struct osal_ev *o = kmalloc(sizeof *o, GFP_KERNEL);
  STUB_ONCE();
  if (!o) return 1;
  spin_lock_init(&o->lock);
  init_waitqueue_head(&o->wq);
  o->flags = 0;
  *ph = (unsigned long)o;
  return 0;
}
EXPORT_SYMBOL(x_ev_group_create);
unsigned long x_ev_group_set_event(unsigned long h, unsigned long mask, unsigned long op, ...)
{
  struct osal_ev *o = (struct osal_ev *)h;
  unsigned long f;
  if (!o) return 1;
  spin_lock_irqsave(&o->lock, f);
  o->flags |= mask;               /* observed op 3 = OR */
  spin_unlock_irqrestore(&o->lock, f);
  wake_up_all(&o->wq);
  return 0;
}
EXPORT_SYMBOL(x_ev_group_set_event);
unsigned long x_ev_group_wait_event(unsigned long h, unsigned long mask, unsigned long *got, unsigned long op, ...)
{
  struct osal_ev *o = (struct osal_ev *)h;
  unsigned long f, r;
  static unsigned long __n;
  __n++;
  if (__n <= 4 || (__n & 0xff) == 0)
    printk(KERN_INFO "[OSAL_STUB] ev_wait #%lu h=%px mask=%#lx op=%lu cur=%#lx caller=%pf\n",
           __n, o, mask, op, o ? o->flags : 0, __builtin_return_address(0));
  if (!o) return 1;
  /* observed op 5 = OR_CONSUME */
  wait_event(o->wq, ({ unsigned long fl;
      spin_lock_irqsave(&o->lock, fl);
      r = o->flags & mask;
      spin_unlock_irqrestore(&o->lock, fl);
      r; }));
  spin_lock_irqsave(&o->lock, f);
  if (got) *got = o->flags & mask;
  if (op == 5) o->flags &= ~(o->flags & mask);
  spin_unlock_irqrestore(&o->lock, f);
  return 0;
}
EXPORT_SYMBOL(x_ev_group_wait_event);
unsigned long x_ev_group_wait_event_timeout(unsigned long h, unsigned long mask, unsigned long *got, unsigned long op, unsigned long to, ...)
{
  struct osal_ev *o = (struct osal_ev *)h;
  unsigned long f, r;
  STUB_ONCE();
  if (!o) return 1;
  wait_event_timeout(o->wq, ({ unsigned long fl;
      spin_lock_irqsave(&o->lock, fl);
      r = o->flags & mask;
      spin_unlock_irqrestore(&o->lock, fl);
      r; }), to);
  spin_lock_irqsave(&o->lock, f);
  if (got) *got = o->flags & mask;
  if (op == 5) o->flags &= ~(o->flags & mask);
  spin_unlock_irqrestore(&o->lock, f);
  return (o->flags & mask) ? 0 : 1;
}
EXPORT_SYMBOL(x_ev_group_wait_event_timeout);
unsigned long x_ev_group_get_info(unsigned long h, unsigned long *pflags, ...)
{
  struct osal_ev *o = (struct osal_ev *)h;
  unsigned long f;
  STUB_ONCE();
  if (!o) return 1;
  spin_lock_irqsave(&o->lock, f);
  if (pflags) *pflags = o->flags;
  spin_unlock_irqrestore(&o->lock, f);
  return 0;
}
EXPORT_SYMBOL(x_ev_group_get_info);
unsigned long x_ev_group_delete(unsigned long h, ...)
{
  STUB_ONCE();
  kfree((void *)h);
  return 0;
}
EXPORT_SYMBOL(x_ev_group_delete);

unsigned long x_msg_q_create(unsigned long *ph, void *buf, unsigned long msg_size, unsigned long depth, ...)
{
  struct osal_mq *o;
  STUB_ONCE();
  if (!msg_size || !depth) return 1;
  o = kmalloc(sizeof *o, GFP_KERNEL);
  if (!o) return 1;
  o->buf = kmalloc(msg_size * depth, GFP_KERNEL);
  if (!o->buf) { kfree(o); return 1; }
  spin_lock_init(&o->lock);
  init_waitqueue_head(&o->wq);
  o->msg_size = msg_size; o->depth = depth;
  o->head = o->tail = o->count = 0;
  *ph = (unsigned long)o;
  return 0;
}
EXPORT_SYMBOL(x_msg_q_create);
unsigned long x_msg_q_send(unsigned long h, void *msg, unsigned long size, unsigned long pri, ...)
{
  struct osal_mq *o = (struct osal_mq *)h;
  unsigned long f;
  static unsigned long __n;
  __n++;
  if (!o || !msg) return 1;
  if (__n <= 8 || (__n & 0xff) == 0)
    printk(KERN_INFO "[OSAL_STUB] mq_send #%lu h=%px w0=%#x caller=%pf\n",
           __n, o, *(unsigned int *)msg, __builtin_return_address(0));
  spin_lock_irqsave(&o->lock, f);
  if (o->count >= o->depth) { spin_unlock_irqrestore(&o->lock, f); return 1; }
  memcpy(o->buf + o->tail * o->msg_size, msg, min(size, o->msg_size));
  o->tail = (o->tail + 1) % o->depth;
  o->count++;
  spin_unlock_irqrestore(&o->lock, f);
  /* receivers wait on the shared osal_mq_wq (Run C14: waking only the
     per-queue wq left the GCPU worker parked on an empty-wait forever) */
  wake_up_all(&osal_mq_wq);
  wake_up_all(&o->wq);
  return 0;
}
EXPORT_SYMBOL(x_msg_q_send);
unsigned long x_msg_q_receive(unsigned short *p_idx, void *msg, unsigned long *p_size,
                              unsigned long *ph, unsigned long cnt, unsigned long option, ...)
{
  struct osal_mq *chosen;
  unsigned long i, f;
  static unsigned long __n;
  __n++;
  if (__n <= 16 || (__n & 0xff) == 0)
    printk(KERN_INFO "[OSAL_STUB] mq_recv #%lu h0=%px cnt=%lu caller=%pf\n",
           __n, cnt ? (void *)ph[0] : NULL, cnt, __builtin_return_address(0));
  if (!ph || !cnt) return 1;
  /* option 1 = WAIT (observed): block until any queue has a message */
  wait_event(osal_mq_wq, ({ int have = 0;
      for (i = 0; i < cnt; i++) {
        struct osal_mq *o = (struct osal_mq *)ph[i];
        if (!o) continue;
        spin_lock_irqsave(&o->lock, f);
        if (o->count > 0) have = 1;
        spin_unlock_irqrestore(&o->lock, f);
        if (have) break;
      }
      have; }));
  chosen = NULL;
  for (i = 0; i < cnt; i++) {
    struct osal_mq *o = (struct osal_mq *)ph[i];
    if (!o) continue;
    spin_lock_irqsave(&o->lock, f);
    if (o->count > 0 && !chosen) {
      memcpy(msg, o->buf + o->head * o->msg_size, min(*p_size, o->msg_size));
      *p_size = o->msg_size;
      o->head = (o->head + 1) % o->depth;
      o->count--;
      if (p_idx) *p_idx = (unsigned short)i;
      chosen = o;
    }
    spin_unlock_irqrestore(&o->lock, f);
    if (chosen) break;
  }
  return chosen ? 0 : 1;
}
EXPORT_SYMBOL(x_msg_q_receive);
unsigned long x_msg_q_num_msgs(unsigned long h, unsigned long *pn, ...)
{
  struct osal_mq *o = (struct osal_mq *)h;
  unsigned long f;
  STUB_ONCE();
  if (!o) return 1;
  spin_lock_irqsave(&o->lock, f);
  if (pn) *pn = o->count;
  spin_unlock_irqrestore(&o->lock, f);
  return 0;
}
EXPORT_SYMBOL(x_msg_q_num_msgs);
unsigned long x_msg_q_delete(unsigned long h, ...)
{
  struct osal_mq *o = (struct osal_mq *)h;
  STUB_ONCE();
  if (o) { kfree(o->buf); kfree(o); }
  return 0;
}
EXPORT_SYMBOL(x_msg_q_delete);
static int osal_thread_fn(void *d)
{
  struct osal_thr *t = d;
  /* Sony semantics: the worker starts EAGERLY (priority preemption) and
     reads pv_data (which may point into the creator's stack frame) while
     the creator is still frozen inside x_thread_create. Emulate: signal
     'started' first (creator wakes only when we sleep — equal priority,
     UP), then run fct. The creator additionally parks 20ms after the
     handshake so entry reads see a live frame. */
  complete(&t->started);
  t->fct(t->arg);
  spin_lock(&osal_threads_lock);
  list_del(&t->list);
  spin_unlock(&osal_threads_lock);
  return 0;
}
unsigned long x_thread_create(unsigned long *ph, const char *name, unsigned long stack,
                              unsigned long pri, ...)
{
  struct osal_thr *t;
  va_list ap;
  void (*fct)(void *);
  void *arg;
  struct task_struct *tsk;
  STUB_ONCE();
  va_start(ap, pri);
  fct = va_arg(ap, void (*)(void *));
  (void)va_arg(ap, unsigned long);      /* flag */
  arg  = va_arg(ap, void *);
  va_end(ap);
  if (!fct || !ph) return 1;
  t = kmalloc(sizeof *t, GFP_KERNEL);
  if (!t) return 1;
  t->fct = fct; t->arg = arg;
  init_completion(&t->started);
  tsk = kthread_create(osal_thread_fn, t, "%s", name ? name : "osal-thr");
  if (IS_ERR(tsk)) { kfree(t); return 1; }
  t->tsk = tsk;
  spin_lock(&osal_threads_lock);
  list_add(&t->list, &osal_threads);
  spin_unlock(&osal_threads_lock);
  /* Sony OSAL starts the worker at HIGHER priority so it preempts the
     creator and reads pv_data (often a pointer into the creator's stack
     frame) before the creator returns. set_user_nice(-10) gives the
     worker that edge on UP (sched_setscheduler is GPL-only). */
  set_user_nice(tsk, -10);
  wake_up_process(tsk);
  /* park until the worker has started; then a REAL sleep (state set!) so
     entry reads see a live frame even if the worker blocks late. */
  wait_for_completion(&t->started);
  set_current_state(TASK_UNINTERRUPTIBLE);
  schedule_timeout(msecs_to_jiffies(20));
  set_current_state(TASK_RUNNING);
  *ph = (unsigned long)tsk;
  printk(KERN_INFO "[OSAL_STUB] thread created: %s fct=%pf\n", name ? name : "?", fct);
  return 0;
}
EXPORT_SYMBOL(x_thread_create);
unsigned long x_thread_exit(unsigned long code, ...)
{
  struct osal_thr *e;
  unsigned long f;
  STUB_ONCE();
  printk(KERN_INFO "[OSAL_STUB] x_thread_exit caller=%pf\n",
         __builtin_return_address(0));
  /* Sony threads always exit through here; complete_and_exit below means
     osal_thread_fn's cleanup never runs. Deregister NOW so get_name/get_pri
     on this handle fail (Run C18: vGCPU_InstanceDestroy polls get_name
     until it fails — a live-looking dead handle = infinite poll). */
  spin_lock_irqsave(&osal_threads_lock, f);
  list_for_each_entry(e, &osal_threads, list)
    if (e->tsk == current) { list_del(&e->list); kfree(e); break; }
  spin_unlock_irqrestore(&osal_threads_lock, f);
  /* do_exit is not EXPORTed to modules in 2.6.35; complete_and_exit is. */
  complete_and_exit(NULL, 0);
  return 0; /* unreachable */
}
EXPORT_SYMBOL(x_thread_exit);
unsigned long x_thread_get_name(unsigned long h, char **ppName, ...)
{
  struct task_struct *t = (struct task_struct *)h;
  STUB_ONCE();
  if (!t || !ppName) return 1;
  if (!osal_thread_live(t)) return 1;  /* dead handle: thread exited */
  /* VERIFIED ABI (Run C15 oops): second arg is char ** -- call sites
     re-load [sp] and pass it to x_memcmp, so we must STORE a pointer
     (to the task's comm), not copy a string into a buffer. */
  *ppName = t->comm;
  return 0;
}
EXPORT_SYMBOL(x_thread_get_name);
unsigned long x_thread_get_pri(unsigned long h, unsigned char *ppri, ...)
{
  struct task_struct *t = (struct task_struct *)h;
  STUB_ONCE();
  if (!t || !ppri) return 1;
  if (!osal_thread_live(t)) return 1;  /* dead handle */
  *ppri = (unsigned char)t->normal_prio;
  return 0;
}
EXPORT_SYMBOL(x_thread_get_pri);

/* Run C19 instrument: print EVERY allocation (ptr,size,caller) so an
   unmapped-page memset can be traced to the allocation that produced it. */
static void alloc_trace(const char *fn, void *p, unsigned long sz)
{
  static unsigned long __n;
  __n++;
  if (__n <= 512)
    printk(KERN_INFO "[OSAL_STUB] alloc %s -> %px size=%lu\n", fn, p, sz);
}

/* ---- memory: large allocations must not go through kmalloc (2.6.35
   kmalloc caps far below the 27.7 MB FBM request; Run C6 showed
   "x_alloc_aligned_ch1_mem fail, size=27734048"). Route big allocs to
   vmalloc; free discriminates via is_vmalloc_addr(). ---- */
void *x_mem_alloc(unsigned long sz, ...)
{
  void *p;
  STUB_ONCE();
  if (!sz) sz = 1;
  p = (sz > (256u << 10)) ? vmalloc(sz) : kmalloc(sz, GFP_KERNEL);
  alloc_trace("x_mem_alloc", p, sz);
  return p;
}
EXPORT_SYMBOL(x_mem_alloc);
void *_x_mem_alloc(unsigned long sz, ...) { return x_mem_alloc(sz); }
EXPORT_SYMBOL(_x_mem_alloc);
void x_mem_free(void *p, ...)
{
  STUB_ONCE();
  if (!p) return;
  if (is_vmalloc_addr(p)) vfree(p); else kfree(p);
}
EXPORT_SYMBOL(x_mem_free);
void _x_mem_free(void *p, ...) { x_mem_free(p); }
EXPORT_SYMBOL(_x_mem_free);
void *x_mem_calloc(unsigned long n, unsigned long sz, ...)
{
  unsigned long total = n * sz;
  void *p;
  STUB_ONCE();
  alloc_trace("x_mem_calloc", NULL, total);
  if (!total) total = 1;
  if (total > (256u << 10)) {
    p = vmalloc(total);
    if (p) memset(p, 0, total);
    return p;
  }
  return kzalloc(total, GFP_KERNEL);
}
EXPORT_SYMBOL(x_mem_calloc);
void *x_mem_realloc(void *p, unsigned long sz, ...)
{
  void *n;
  STUB_ONCE();
  if (!sz) sz = 1;
  n = x_mem_alloc(sz);
  if (n && p) {
    if (is_vmalloc_addr(p)) {
      /* no portable size query for vmalloc in 2.6.35; skip copy, warn once */
      STUB_ONCE();
    } else {
      unsigned long old = ksize(p);
      if (old > sz) old = sz;
      memcpy(n, p, old);
    }
    x_mem_free(p);
  }
  return n;
}
EXPORT_SYMBOL(x_mem_realloc);
void *_x_mem_realloc(void *p, unsigned long sz, ...) { return x_mem_realloc(p, sz); }
EXPORT_SYMBOL(_x_mem_realloc);
/* VERIFIED ABI order (Run C21): callers pass (SIZE, ALIGN) —
   vKmDrvInitGenData calls x_alloc_aligned_mem(0x10000, 0x20) and memsets
   0x10000 bytes; our old (align, sz) reading vmalloc'd the ALIGN (32
   bytes) and the 64KB memset ran off the end. */
void *x_mem_aligned_alloc(unsigned long sz, unsigned long align, ...)
{
  void *p;
  STUB_ONCE();
  if (!sz) sz = 1;
  if (align > 64 || sz > (256u << 10))
    p = vmalloc(sz);        /* page-aligned: satisfies align <= 4096 */
  else
    p = kmalloc(sz, GFP_KERNEL);
  alloc_trace("x_mem_aligned_alloc", p, sz);
  return p;
}
EXPORT_SYMBOL(x_mem_aligned_alloc);
void x_mem_aligned_free(void *p, ...)
{
  STUB_ONCE();
  if (!p) return;
  if (is_vmalloc_addr(p)) vfree(p); else kfree(p);
}
EXPORT_SYMBOL(x_mem_aligned_free);
void *x_mem_valloc(unsigned long sz, ...)
{
  void *p;
  STUB_ONCE();
  if (!sz) sz = 1;
  p = vmalloc(sz);
  alloc_trace("x_mem_valloc", p, sz);
  return p;
}
EXPORT_SYMBOL(x_mem_valloc);
void x_mem_vfree(void *p, ...)
{
  STUB_ONCE();
  vfree(p);
}
EXPORT_SYMBOL(x_mem_vfree);


/* ---- x_kmem_* block allocator (Run C26+).
   VERIFIED ABI (from assert strings + i4Gfx_CmdBuf_AllocFstMemBlk
   0x193244): x_kmem_block_alloc(chunk_size) / x_kmem_block_aligned_alloc
   (size, align) return a HANDLE (0 = fail); x_kmem_kernel_address(h_mem)
   converts a handle to a kernel pointer; the crash showed
   kernel_address(block_aligned_alloc(...)) must be nonzero and the
   driver writes fields at [ptr+0x24]. Handles here ARE kernel pointers
   (identity conversion). (size, align) order matches x_alloc_aligned_mem. */
void *x_kmem_block_aligned_alloc(unsigned long sz, unsigned long align, ...)
{
  void *p;
  STUB_COUNTED("x_kmem_block_aligned_alloc");
  if (!sz) sz = 1;
  if (align > 64 || sz > (256u << 10))
    p = vmalloc(sz);
  else
    p = kmalloc(sz, GFP_KERNEL);
  alloc_trace("x_kmem_block_aligned_alloc", p, sz);
  return p;
}
EXPORT_SYMBOL(x_kmem_block_aligned_alloc);
void x_kmem_block_aligned_free(void *h, ...)
{
  STUB_ONCE();
  if (!h) return;
  if (is_vmalloc_addr(h)) vfree(h); else kfree(h);
}
EXPORT_SYMBOL(x_kmem_block_aligned_free);
void *x_kmem_block_alloc(unsigned long chunk_size, ...)
{
  void *p;
  STUB_COUNTED("x_kmem_block_alloc");
  if (!chunk_size) chunk_size = 1;
  p = (chunk_size > (256u << 10)) ? vmalloc(chunk_size) : kmalloc(chunk_size, GFP_KERNEL);
  alloc_trace("x_kmem_block_alloc", p, chunk_size);
  return p;
}
EXPORT_SYMBOL(x_kmem_block_alloc);
void x_kmem_block_free(void *h, ...)
{
  STUB_ONCE();
  if (!h) return;
  if (is_vmalloc_addr(h)) vfree(h); else kfree(h);
}
EXPORT_SYMBOL(x_kmem_block_free);
unsigned long x_kmem_kernel_address(unsigned long h_mem, ...)
{
  STUB_COUNTED("x_kmem_kernel_address");
  return h_mem;   /* handles are kernel pointers in this instrument */
}
EXPORT_SYMBOL(x_kmem_kernel_address);
unsigned long x_kmem_create_handle(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_kmem_create_handle);
unsigned long x_kmem_destroy_handle(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_kmem_destroy_handle);
unsigned long x_kmem_block_handle(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_kmem_block_handle);
unsigned long x_kmem_block_info(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_kmem_block_info);
unsigned long x_kmem_block_sliced_aligned_alloc(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_kmem_block_sliced_aligned_alloc);
unsigned long x_kmem_sync_table(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_kmem_sync_table);
unsigned long x_kmem_addr_user_to_kernel(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(x_kmem_addr_user_to_kernel);
unsigned long addr_kernel_to_user(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(addr_kernel_to_user);
unsigned long addr_user_to_kernel(unsigned long a0, ...) { STUB_ONCE(); return 0; }
EXPORT_SYMBOL(addr_user_to_kernel);

static int __init osal_stub_init(void)
{
  int i;
  struct kmem_cache *c32;
  init_waitqueue_head(&osal_mq_wq);
  /* Run C10 lesson: the stub DEFINES kmalloc_caches[] (the guest kernel
     does not export it but 42 fs/usb BDP modules reference it), which
     hijacks the stub's OWN constant-size kmalloc inlines -> the crash in
     kmem_cache_alloc. Fill the array with REAL caches so the inline path
     works. Layout mirrors slub.c create_kmalloc_caches for this config:
     [1]=96, [2]=192, [5..13]=2^i (KMALLOC_MIN_SIZE=32, SLUB_PAGE_SHIFT=14);
     other indexes get the 32-byte cache as a canary. */
  c32 = kmem_cache_create("bx510-osal-32", 32, 0, 0, NULL);
  kmalloc_caches[1] = *kmem_cache_create("bx510-osal-96", 96, 0, 0, NULL);
  kmalloc_caches[2] = *kmem_cache_create("bx510-osal-192", 192, 0, 0, NULL);
  for (i = 5; i < SLUB_PAGE_SHIFT; i++) {
    char nm[24];
    struct kmem_cache *c;
    snprintf(nm, sizeof nm, "bx510-osal-%d", 1 << i);
    c = kmem_cache_create(nm, 1 << i, 0, 0, NULL);
    if (c) kmalloc_caches[i] = *c;
  }
  for (i = 0; i < KMALLOC_CACHES; i++)
    if (!kmalloc_caches[i].size && c32)
      kmalloc_caches[i] = *c32;
  printk(KERN_INFO "[OSAL_STUB] loaded (INSTRUMENT)\n");
  return 0;
}
static void __exit osal_stub_exit(void) { printk(KERN_INFO "[OSAL_STUB] unloaded\n"); }
module_init(osal_stub_init);
module_exit(osal_stub_exit);
#endif /* STUB_PART_A */
