/* bx510_clidrive.c — STUB/INSTRUMENT runtime driver: exercises the REAL
 * Sony CLI framework (drvcli.ko) from kernel side and DUMPS the live
 * command tree. Everything here is derived from
 * evidence/bx510-guest/bdpdrv/decode/drvcli-surface.md (cited per change);
 * no part of the table walk is assumed any more.
 *
 * Path into the parser (decode §0.3/§5): drvcli has NO read/write fops, so
 * shell redirection can never drive it. The two live routes are
 * ioctl(0x00045102) or a kernel-side call of the EXPORTED x_cli_parser();
 * this module takes the second one, resolving the address with
 * kallsyms_lookup_name — FUNCTIONS ONLY. The data symbols the old shim
 * commented about (pt_cur_cmd_tbl, apt_cli_array, e_access_right,
 * at_cli_mod_grp_info, _arDefaultCmdTbl) are absent from the guest
 * kallsyms (CONFIG_KALLSYMS_ALL off, decode §5/§6), so the tree is read by
 * ASKING the parser (`ls`, dir names) instead of walking pointers.
 *
 * Return codes (decode §0.2): 0 = handler ran, 1 = matched a directory and
 * dumped its help, -10 = no match, -1 = drvcli not initialised.
 *
 * Probe-sequence mode (ladder below): insmod this module with
 * clidrive_args=PROBE_SEQ (the same argument goes in the AutoScript line on
 * the player) to run P0 -> P3 as SEPARATE x_cli_parser() calls. Each
 * call is separate on purpose: the parser carries directory state
 * (cd-like semantics), so batching the strings would not be equivalent.
 * Without the flag the module keeps the C50/C93/C95-known instrument
 * output (root sentinel + parser('driver')), byte-identical to those logs.
 */
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/kallsyms.h>
#include <linux/string.h>

/* decode §2.1 — entry layout DECODED from _parse_cmd (0x15b8/0x15dc/0x153c),
 * 24-byte stride, NULL-name terminated. The old struct put fn_or_sub at
 * +0x0c (i.e. it read only `sub`), which is why leaf commands always
 * reported "<NULL fn>". There is no third word: fn is +0x08, sub is +0x0c.
 */
struct cli_ent {
  char *name;                        /* +0x00 */
  char *alias;                       /* +0x04 */
  int (*fn)(int argc, char **argv);  /* +0x08 leaf handler */
  struct cli_ent *sub;               /* +0x0c subtable (directory) */
  char *help;                        /* +0x10 */
  unsigned access;                   /* +0x14 access-right index (§2.2) */
};

/* decode §2.1 asserts 24 bytes; keep the build honest if the header/libc
 * ever changes the padding (last entry of every table is all-zero). */
typedef char cli_ent_must_be_24_bytes[sizeof(struct cli_ent) == 24 ? 1 : -1];

/* decode §5 — parser/state entry points, resolved by name at init */
typedef int (*cli_parser_fn)(const char *cmd);
typedef int (*cli_set_mode_fn)(int mode);
typedef unsigned long (*cli_get_root_fn)(void);

/* decode §5 — one probe in the acceptance ladder. */
struct cli_probe {
  const char *id;
  const char *cmd;                   /* exact string handed to x_cli_parser() */
  const char *expect;
};

/* The acceptance ladder, re-derived in C100 from two decodes:
 *
 *   P0 — p0-scan-decode.md §0.1/§3.1/§5. `read` is a LEAF inside group 5, not
 *        a root command: the root array carries only the mandatory table plus
 *        the group DIRECTORY entries (§1.2), so the old spelling
 *        `read 0x1000 16` could only ever return -10 from `_parse_cmd` 0x1678.
 *        The corrected spelling is the dot-joined path: `_search_tbl` matches
 *        argv[0] only up to the first '.' and `_parse_cmd` recurses into the
 *        matched sub-table when that byte IS a '.', so ONE call descends
 *        (p0-scan-decode.md §4.3, ide-cli-lane.md §2.2). Length 0 is
 *        deliberate: `_CmdMemRead` ORs the address with 0xF0000000 and derefs
 *        with no probe (§3.2), and 0xF0001000 sits in the guest's vmalloc
 *        window, unmapped — with length 0 the handler returns at 0x2aec
 *        BEFORE the first load, so P0 stays a zero-risk rig control (§3.3).
 *   P1 — kept byte-identical to the C50/C93/C95 reference help dump.
 *   P2 — group 5 directory. Its dump is 57 lines: 45 bdpdrv lanes + drvcli's
 *        8-command default table + 4 test entries (p0-scan-decode.md §1.4).
 *        `read(r):                Memory read(word)` inside that dump is the
 *        standing proof that P0's fix targets a live entry — grep it.
 *   P3 — the IDE-HAL transport leg (ide-cli-lane.md §0/§4, its P5-d row): the
 *        full dot path reaches `_IDECLI_Init` with argc=4 in ONE call, no `cd`
 *        sequencing. It programs the 0x7000a000 window, reads the ATA
 *        signature, posts IDENTIFY 0xA1 and takes the BOUNDED wait — flags
 *        0x31 means flags&3==1, so it never reaches the untimed PIO-in spin
 *        (ide-cli-lane.md §7.1). It is LAST in the ladder because
 *        `_fgSataDev`/`_fgSataHwInit`/`_fgUseQueMode[]` are sticky globals
 *        (§7.3) and this module is the last one loaded in the fire. If P3
 *        returns -10 the lane was never attached; the diagnostic for that is
 *        the directory spelling `drv.ide.pri_ver` (rc=1, 33 help lines).
 */
static const struct cli_probe cli_probes[] = {
  { "P0", "drv.read 0x1000 0",
    "rc=0 + 'Read addr = 0x00001000, length = 0' and NO payload row "
    "(length 0 => no deref)" },
  { "P1", "driver",
    "[Help] + hdmitx(hdmitx):         Hdmi Tx command (rc=1)" },
  { "P2", "drv",
    "[Help] + 57 lines incl 'read(r):                Memory read(word)' (rc=1)" },
  { "P3", "drv.ide.pri_ver.initial 0 s 0",
    "rc=0 + '[i4IdeHalTestInit]Signature:0x......' + 'CH:0, SataDev:1, "
    "UseQueue:0 Done!'; today also 'CmdWaitEvtRet'/'TIMEOUT !!' (model rows "
    "a+00c / a+220), or 'ModelName:' if the wait completed" },
};

static char *clidrive_args = "";
module_param(clidrive_args, charp, 0444);
MODULE_PARM_DESC(clidrive_args,
                 "\"PROBE_SEQ\" runs the P0->P3 acceptance ladder "
                 "(decode p0-scan-decode.md section 5, ide-cli-lane.md section 6)");

/* decode §0.2 return-code table, as text, so the UART line is self-describing */
static const char *cli_rc_meaning(int rc)
{
  switch (rc) {
  case 0:   return "handler ran";
  case 1:   return "directory matched, help dumped";
  case -10: return "no match (-EAGAIN)";
  case -1:  return "drvcli not initialised";
  default:  return "unexpected";
  }
}

/* decode §5 rule 4 — kallsyms_lookup_name only for FUNCTIONS; each lookup
 * is printed so an unresolved name is evidence, not a guess. */
static void *cli_sym(const char *name)
{
  void *a = (void *)kallsyms_lookup_name(name);
  printk(KERN_INFO "[CLIDRIVE] sym %-20s = %p\n", name, a);
  return a;
}

/* decode §2.1/§5 — walk ONE 24-byte-entry table. A group slot can also be a
 * table ARRAY (§2.4 _is_cmd_tbl_array); that shape is only reachable through
 * the parser, never by pointer walking, so this dump is entered only for the
 * single-table current-dir case (depth-limited, sub-only recursion).
 */
static void dump_tbl(const char *path, const struct cli_ent *t, int depth)
{
  int i;
  if (!t || depth > 3) return;
  for (i = 0; i < 32; i++) {
    const struct cli_ent *e = &t[i];
    if (!e->name && !e->alias) break;
    printk(KERN_INFO
           "[CLIDRIVE] %s/%s (alias %s, access %u, fn %p, sub %p)\n",
           path, e->name ? e->name : "?", e->alias ? e->alias : "-",
           e->access, (void *)e->fn, (void *)e->sub);
    if (e->sub) dump_tbl(e->name ? e->name : "?", e->sub, depth + 1);
  }
}

/* decode §5 — run one ladder entry as its own parser call and report both the
 * return code and the directory state the call left behind. */
static void run_probe(cli_parser_fn parser, cli_get_root_fn get_root,
                      const struct cli_probe *p)
{
  int rc = parser(p->cmd);
  unsigned long cur = get_root ? get_root() : 0;

  printk(KERN_INFO "[CLIDRIVE] parser('%s %s') = %d\n", p->id, p->cmd, rc);
  printk(KERN_INFO "[CLIDRIVE] %s: %s; cur = %#lx; expect %s\n",
         p->id, cli_rc_meaning(rc), cur, p->expect);
}

static int __init clidrive_init(void)
{
  cli_parser_fn x_cli_parser;
  cli_set_mode_fn x_cli_set_mode;
  cli_get_root_fn x_cli_get_current_root;
  unsigned long t0, t1;
  int i;

  printk(KERN_INFO "[CLIDRIVE] up (INSTRUMENT)\n");

  /* decode §5 rule 4: functions resolve, data does not. CLI_GetDefaultCmdTbl
   * and CLI_GetCusDrvCmdTbl are the two drvcli table getters the parser is
   * built on (§3.2); resolving them (not dereferencing) documents that the
   * function-level seam is intact in this guest. */
  x_cli_parser = (cli_parser_fn)cli_sym("x_cli_parser");
  x_cli_set_mode = (cli_set_mode_fn)cli_sym("x_cli_set_mode");
  x_cli_get_current_root = (cli_get_root_fn)cli_sym("x_cli_get_current_root");
  cli_sym("cli_parser");
  cli_sym("CLI_GetDefaultCmdTbl");
  cli_sym("CLI_GetCusDrvCmdTbl");
  if (!x_cli_parser) {
    printk(KERN_INFO
           "[CLIDRIVE] x_cli_parser unresolved - drvcli.ko not loaded; "
           "nothing to drive\n");
    return 0;
  }

  /* decode §2.2: access index 0 = supervisor, the highest privilege; the
   * parser rejects an entry when entry->access < e_access_right. */
  if (x_cli_set_mode) x_cli_set_mode(0);

  /* decode §0.1: 0 is the ROOT SENTINEL, not a failure — print and move on. */
  t0 = x_cli_get_current_root ? x_cli_get_current_root() : 0;
  printk(KERN_INFO "[CLIDRIVE] root table = %#lx\n", t0);
  if (t0) dump_tbl("root", (const struct cli_ent *)t0, 0);

  if (strstr(clidrive_args, "PROBE_SEQ")) {
    printk(KERN_INFO "[CLIDRIVE] mode = PROBE_SEQ (%d probes, dotted ladder)\n",
           (int)ARRAY_SIZE(cli_probes));
    for (i = 0; i < (int)ARRAY_SIZE(cli_probes); i++)
      run_probe(x_cli_parser, x_cli_get_current_root, &cli_probes[i]);
    t1 = x_cli_get_current_root ? x_cli_get_current_root() : 0;
    printk(KERN_INFO "[CLIDRIVE] after PROBE_SEQ: cur = %#lx\n", t1);
    return 0;
  }

  /* default instrument mode — this is the line C50/C93/C95 logged, kept
   * byte-identical so the known-good reference stays reproducible (§0.2) */
  printk(KERN_INFO "[CLIDRIVE] parser('driver') = %d\n", x_cli_parser("driver"));
  t1 = x_cli_get_current_root ? x_cli_get_current_root() : 0;
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
