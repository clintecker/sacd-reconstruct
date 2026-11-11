const CTX = [
"Repo: /Users/clint/code/sacd-reconstruct (standalone review mirror -- DO NOT COMMIT;",
"canonical is /Users/clint/code/aftermath-sacd, the parent mirrors+commits).",
"Lab VM: aftermath@10.20.0.18 port 2222 (keyed ssh). Images at",
"~/bx510-emu/images/ (nand.img 256MB, kernel.uImage, initrd_1.bin 532976B,",
"u-boot.bin, arm2-fastboot.bin, rootfs_normal_1.bin, manifest.json).",
"Sony rootfs unpacked READ-ONLY at VM:/tmp/rootfs.",
"House rules: decode bytes with tools, never eyeball; label VERIFIED vs",
"INFERRED; evidence = files pulled into evidence/, never conversation;",
"sha-pin every artifact; the wall is 30 minutes per child -- deliver the",
"phase artifact and stop rather than overrun; negative results are results."
].join("\n");

const [initrd, stubs] = await runs.all([
  {
    key: "initrd-decode",
    agent: "worker",
    model: "openai/gpt-5.2:high",
    cwd: "/Users/clint/code/sacd-reconstruct",
    output: "evidence/bx510-guest/u4-initrd/u4-run.md",
    task: CTX + `

U4 LANE: decode initrd_1.bin (532976 B). Goal: extract the OSAL base
(x_mem_*/BIM_*/CKGEN_*/HAL_* symbols) that bdpdrv.ko needs at insmod
(see evidence/bx510-guest/bdpdrv/missing.pre.syms -- 153 lines, the
missing-symbol list; 73 of them lack any provider in BDP/*.ko).

What is known (VERIFIED):
- The file has NO magic (starts b6 7a 75 2c...), high entropy, not
  gzip/cpio/ubifs; byte distribution near-uniform (encrypted or
  transformed, or headerless compression).
- manifest.json pins initrd_1 @ nand 0x1a00000, record size 532976,
  record sha256 == the extracted file's sha (manifest describes STORED
  bytes; any boot-time transform happens after read).
- u-boot.bin strings: "initrd_1"/"initrd_2" names, mt85xx_part_oper
  partition machinery, "appendXOR ... u4XorChecksum", "Ramdisk image is
  corrupt or invalid", bootargs default "noinitrd root=/dev/mtdblock7 ro"
  (interesting: default bootargs IGNORE the initrd -- initrd may serve
  the upgrade/rescue path), no AES/decrypt strings in u-boot.
- arm2-fastboot.bin (62 KB) is the preloader stage-2; its strings show
  Fastlogo/IDE loader, no obvious crypto.
- Sibling artifact rootfs_enc_it_1.bin (131072 B record in a 4 MiB
  partition) suggests an encrypted-rootfs mechanism exists in this
  platform family; same transform family may apply to initrd.

Attack order (tools only, no eyeballing):
1. Mac-side: pull initrd_1.bin + rootfs_enc_it_1.bin record + u-boot.bin +
   arm2-fastboot.bin to a work dir. Classify the transform: entropy per
   block, byte-histogram, chi2; check for block boundaries (16-byte
   periodicity), CBC/ECB artifacts (repeated ciphertext blocks), counter
   patterns.
2. Reverse the consumer: disassemble (llvm-objdump) the u-boot code paths
   around the initrd_1/mt85xx_boot/appendXOR strings; find the loader for
   the initrd partition (xref the string) and pin what transform it
   applies (XOR? AES? none -- maybe raw and the KERNEL unwraps it).
   Check the kernel too: does kernel.uImage contain an embedded
   initramfs (search for cpio/gzip magics inside) and/or an decrypt path?
3. If the transform is simple (XOR chain / constant-key), derive the key
   from known plaintext: initramfs headers are predictable
   ("070701" cpio magic, gzip 1f 8b 08). Known-plaintext the first bytes,
   then decrypt and validate with a cpio/gzip parse.
4. If AES: find the key schedule source (key_block_1/2 partitions at
   nand 0x800000/0x900000; or eFuse emulation). Record the derivation
   VERIFIED or mark OPEN with the exact gap.

Deliverables:
- evidence/bx510-guest/u4-initrd/: all scripts + outputs + pulled logs.
- docs/U4-INITRD.md: the transform spec (or the honest OPEN state with
  the exact blocker), and if decoded: the OSAL symbol table it exports
  (cross-checked against missing.pre.syms -- count how many of the 73
  it resolves).
- If the initrd decodes and contains the OSAL as a BINARY, extract it
  (nm/readelf it) and list its exports.`
  },
  {
    key: "stub-module",
    agent: "worker",
    model: "openai/gpt-5.2:medium",
    cwd: "/Users/clint/code/sacd-reconstruct",
    output: "evidence/bx510-guest/bdpdrv/stub-run.md",
    task: CTX + `

S5-PHASE-A-CONT LANE: build the OSAL symbol-stub module and run the
bdpdrv probe trace. This is a DELIBERATE INSTRUMENT (labeled as such):
fake exports exist only to get bdpdrv's module_init past link so the
probe path executes far enough to produce the real MMIO trace.

Inputs:
- evidence/bx510-guest/bdpdrv/missing.pre.syms (153 missing symbols),
  /tmp/missing73.txt on the VM side may not exist -- regenerate: the 73
  = missing symbols NOT covered by BDP/*.ko exports (the parent already
  computed 80/153 covered; recompute deterministically and record).
- The guest is init=/bin/sh boot; module machinery proven (sacd_read.ko,
  fusion.ko load). The guest kernel is Sony's 2.6.35 (build tools for
  out-of-tree modules: check for the kernel build dir on the VM or reuse
  the proven sacd_read.ko Makefile pattern from
  evidence/bx510-guest/artifacts/ or original/).

Build a stub module (osal_stub.ko) that EXPORTS each missing symbol:
- x_* memory/thread/semaphore functions: minimal working versions are
  BETTER than no-ops where cheap (x_mem_alloc -> kmalloc wrapper,
  x_thread_create -> kthread_run, x_sema_create -> struct semaphore)
  because the probe may call them. But any that would need real
  hardware/OSAL state: return plausible success values.
- BIM_* (interrupt): return success / enable-stub.
- CKGEN_* (clocks): return plausible frequency constants.
- HAL_* (time): wrap do_gettimeofday/ktime.
- Leading-underscore _x_mem_* variants: alias the x_mem_* impls.
- Data symbols (g_u4Ch1DramSize etc.): EXPORT_SYMBOL a variable with a
  plausible value (128 MB = 0x08000000 for DRAM size).
- Use EXPORT_SYMBOL for every one. Insmod osal_stub.ko FIRST, then
  insmod bdpdrv.ko; if link passes, capture the UART + MMIO trace
  (QEMU -d unimp, same as the prior runs) through probe success or
  failure. Record EVERYTHING honestly: which stubs got CALLED (add a
  printk-once per stub), the probe verdict, the trace.

Discipline:
- The stub module source lives in tools/ (bx510_osal_stub.c) and the
  run report in evidence/bx510-guest/bdpdrv/stub-run.md. Label the
  artifact: STUB (instrument, not reconstruction) everywhere.
- Mac-side first: generate the exact missing list, cross-check the 73
  count, then write the C with a symbol table so the exports are
  auditable.
- One boot cycle family; batch edits; if insmod still fails, capture
  WHICH symbols and why (check /proc/kallsyms after stub load).`
  },
]);

return { initrd, stubs };
