0002fb40 <remove_modules>:
   2fb40: e92d4800     	push	{r11, lr}
   2fb44: e28db004     	add	r11, sp, #4
   2fb48: e24dd008     	sub	sp, sp, #8
   2fb4c: e59f0058     	ldr	r0, [pc, #0x58]         @ 0x2fbac <remove_modules+0x6c>
   2fb50: ebff71f2     	bl	0xc320 <system@plt>     @ imm = #-0x23838
   2fb54: e59f0054     	ldr	r0, [pc, #0x54]         @ 0x2fbb0 <remove_modules+0x70>
   2fb58: e3a01000     	mov	r1, #0
   2fb5c: ebff7285     	bl	0xc578 <open64@plt>     @ imm = #-0x235ec
   2fb60: e1a03000     	mov	r3, r0
   2fb64: e50b3008     	str	r3, [r11, #-0x8]
   2fb68: e51b3008     	ldr	r3, [r11, #-0x8]
   2fb6c: e3530000     	cmp	r3, #0
   2fb70: ba000009     	blt	0x2fb9c <remove_modules+0x5c> @ imm = #0x24
   2fb74: e51b0008     	ldr	r0, [r11, #-0x8]
   2fb78: ebff7299     	bl	0xc5e4 <close@plt>      @ imm = #-0x2359c
   2fb7c: e59f3030     	ldr	r3, [pc, #0x30]         @ 0x2fbb4 <remove_modules+0x74>
   2fb80: e5933000     	ldr	r3, [r3]
   2fb84: e5933004     	ldr	r3, [r3, #0x4]
   2fb88: e3530001     	cmp	r3, #1
   2fb8c: 9a000002     	bls	0x2fb9c <remove_modules+0x5c> @ imm = #0x8
   2fb90: e59f0020     	ldr	r0, [pc, #0x20]         @ 0x2fbb8 <remove_modules+0x78>
   2fb94: e59f1020     	ldr	r1, [pc, #0x20]         @ 0x2fbbc <remove_modules+0x7c>
   2fb98: ebff9445     	bl	0x14cb4 <log_print>     @ imm = #-0x1aeec
   2fb9c: e59f001c     	ldr	r0, [pc, #0x1c]         @ 0x2fbc0 <remove_modules+0x80>
   2fba0: ebff71de     	bl	0xc320 <system@plt>     @ imm = #-0x23888
   2fba4: e24bd004     	sub	sp, r11, #4
   2fba8: e8bd8800     	pop	{r11, pc}
   2fbac: c8 62 03 00  	.word	0x000362c8
   2fbb0: 78 62 03 00  	.word	0x00036278
   2fbb4: 5c 73 05 00  	.word	0x0005735c
   2fbb8: d8 62 03 00  	.word	0x000362d8
   2fbbc: 00 63 03 00  	.word	0x00036300
   2fbc0: e8 62 03 00  	.word	0x000362e8

