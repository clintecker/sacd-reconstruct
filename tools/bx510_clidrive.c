/* bx510_clidrive.c — STUB/INSTRUMENT runtime driver: exercises the REAL
 * Sony CLI framework (drvcli.ko) from kernel side and DUMPS the live
 * command tree via kallsyms_lookup_name (exported by this 2.6.35 kernel).
 *
 * Decoded entry layout (Run C50, from bdpdrv hdmitx table):
 *   struct cli_ent { char *name; char *alias; void *_z;
 *                    void *fn_or_sub; char *help; unsigned access; ... }
 *   0x30-byte entries; fn_or_sub is a SUBTABLE when the entry is a dir.
 * Globals (drvcli bss, visible in /proc/kallsyms):
 *   pt_cur_cmd_tbl (current dir), e_access_right, at_cli_mod_grp_info.
 */
#include <linux/module.h>
#include <linux/kernel.h>

extern int x_cli_set_mode(int mode);
extern int x_cli_parser(const char *cmd);
extern unsigned long x_cli_get_current_root(void);


struct cli_ent {
  char *name;
  char *alias;
  void *_z;
  void *fn_or_sub;
  char *help;
  unsigned access;
  unsigned pad[6];
};

static void dump_tbl(const char *path, const struct cli_ent *t, int depth)
{
  int i;
  if (!t || depth > 3) return;
  for (i = 0; i < 32; i++) {
    const struct cli_ent *e = &t[i];
    if (!e->name && !e->alias) break;
    printk(KERN_INFO "[CLIDRIVE] %s/%s (alias %s, access %u)%s\n",
           path, e->name ? e->name : "?", e->alias ? e->alias : "-",
           e->access, e->fn_or_sub ? "" : " <NULL fn>");
    if (e->fn_or_sub && e->name && e->help == NULL && depth < 3)
      dump_tbl(e->name, e->fn_or_sub, depth + 1);
  }
}

static int __init clidrive_init(void)
{
  unsigned long t0, t1;
  printk(KERN_INFO "[CLIDRIVE] up (INSTRUMENT)\n");
  x_cli_set_mode(0);   /* supervisor */
  t0 = x_cli_get_current_root();
  printk(KERN_INFO "[CLIDRIVE] root table = %#lx\n", t0);
  if (t0) dump_tbl("root", (const struct cli_ent *)t0, 0);
  printk(KERN_INFO "[CLIDRIVE] parser('driver') = %d\n", x_cli_parser("driver"));
  t1 = x_cli_get_current_root();
  printk(KERN_INFO "[CLIDRIVE] after 'driver': cur = %#lx\n", t1);
  if (t1 && t1 != t0) dump_tbl("driver", (const struct cli_ent *)t1, 0);
  return 0;
}
static void __exit clidrive_exit(void) { printk(KERN_INFO "[CLIDRIVE] down\n"); }
module_init(clidrive_init);
module_exit(clidrive_exit);
MODULE_LICENSE("Proprietary");
MODULE_AUTHOR("aftermath (instrument)");
MODULE_DESCRIPTION("BX510 CLI runtime driver + tree dump (INSTRUMENT)");
