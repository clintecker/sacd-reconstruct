/* bx510_cpsa_peer.c — STUB/INSTRUMENT: register the CPSA peer Im entry.
 *
 * Route A of decode/gcpu-connect-path.md: bdpdrv's i4CPSA_Inst_Create
 * registers itself under (0x16b, compid, 1) and then binds a peer under
 * (0x168=360, compid, 0) — and NO ONE in bdpdrv registers type 0x168, so the
 * Im query returns -3 and Connect fails 0xE8000000 (cpsa_main.c:895). This
 * module makes the peer entry exist: kallsyms_lookup_name
 * ("i4ImRegisterInterface2"), one call with the wildcard compid.
 *
 *   i4ImRegisterInterface2(0x168, 0xFFFFFFFF, 0, &fnslot, ctx)
 *   *(u32*)&fnslot = &peer_fn   — called once as peer_fn(ctx, 0x16b, compid),
 *                                 return value ignored (0x548c0..0x548d4).
 *
 * The record's +0x18/+0x1c hooks are left 0: i4ImRegisterInterface2 does
 * exactly that and both consumers NULL-check (recipe rows A1-A3, VERIFIED).
 *
 * Load AFTER bdpdrv, BEFORE the first INIT ioctl — the sacdread smoke script
 * insmods it at S06b for exactly that window. Re-insmod after a bdpdrv
 * reload is harmless only if the Im table survived; the fire keeps one
 * bdpdrv per run, so the module is written for exactly one registration.
 *
 * It is NOT part of any reconstruction and must not be treated as such.
 */
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/kallsyms.h>

typedef unsigned long (*im_reg_fn)(unsigned long type, unsigned long compid,
                                   unsigned long op, void *fnslot, void *ctx);

static unsigned long peer_fnslot[4];

/* The Im fnslot is a FUNCTION TABLE, not a single pointer (C106 oops decode:
 * i4ImQueryInterface hands out &slot and the consumers index it — Create's
 * generator call reads slot[0], i4CPSA_Inst_Destroy+0x12c reads slot[1] and
 * calls it UNCHECKED — a 1-word slot let slot[1] fall into zeroed .bss and
 * PC=0'd the guest). Every entry is a logged no-op returning 0; the calls'
 * return values are ignored per the decode (0x548c0..0x548d4, 0x54a54). */
static int peer_op(void *ctx, unsigned long type, unsigned long compid)
{
	static int once;

	if (!once) {
		once = 1;
		printk(KERN_INFO "[CPSA_PEER] op call: ctx=%p type=%#lx compid=%lu\n",
		       ctx, type, compid);
	}
	return 0;
}

static int __init cpsa_peer_init(void)
{
	im_reg_fn reg;
	int rc;

	reg = (im_reg_fn)kallsyms_lookup_name("i4ImRegisterInterface2");
	if (!reg) {
		printk(KERN_ERR "[CPSA_PEER] i4ImRegisterInterface2 not found — is bdpdrv loaded?\n");
		return -ENOENT;
	}
	peer_fnslot[0] = (unsigned long)peer_op;   /* generator (Create) */
	peer_fnslot[1] = (unsigned long)peer_op;   /* release (Destroy+0x12c) */
	peer_fnslot[2] = (unsigned long)peer_op;   /* further ops: guarded no-op */
	peer_fnslot[3] = (unsigned long)peer_op;
	rc = (int)reg(0x168, 0xFFFFFFFF, 0, peer_fnslot, NULL);
	/* The function's return is ignored by the recipe (A1): the record's
	 * existence is what matters, and a duplicate registration after a
	 * bdpdrv reload would also land here. Log it either way. */
	printk(KERN_INFO "[CPSA_PEER] registered (0x168, 0xFFFFFFFF, 0) rc=%d fnslot=%px\n",
	       rc, &peer_fnslot);
	return 0;
}

static void __exit cpsa_peer_exit(void)
{
	/* The (0x16b, compid, 1) self-registration is never unlinked by the
	 * driver either (A4); symmetry, not science. */
	printk(KERN_INFO "[CPSA_PEER] exit\n");
}

module_init(cpsa_peer_init);
module_exit(cpsa_peer_exit);
MODULE_LICENSE("GPL");
