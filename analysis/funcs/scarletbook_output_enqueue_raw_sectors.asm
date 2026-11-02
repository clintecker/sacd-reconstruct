00027ef8 <scarletbook_output_enqueue_raw_sectors>:
   27ef8: e92d4800     	push	{r11, lr}
   27efc: e28db004     	add	r11, sp, #4
   27f00: e24dd020     	sub	sp, sp, #32
   27f04: e50b0018     	str	r0, [r11, #-0x18]
   27f08: e50b101c     	str	r1, [r11, #-0x1c]
   27f0c: e50b2020     	str	r2, [r11, #-0x20]
   27f10: e50b3024     	str	r3, [r11, #-0x24]
   27f14: e51b3018     	ldr	r3, [r11, #-0x18]
   27f18: e593303c     	ldr	r3, [r3, #0x3c]
   27f1c: e50b3008     	str	r3, [r11, #-0x8]
   27f20: e59b0004     	ldr	r0, [r11, #0x4]
   27f24: ebfffe76     	bl	0x27904 <find_output_format> @ imm = #-0x628
   27f28: e1a03000     	mov	r3, r0
   27f2c: e50b3010     	str	r3, [r11, #-0x10]
   27f30: e51b3010     	ldr	r3, [r11, #-0x10]
   27f34: e3530000     	cmp	r3, #0
   27f38: 0a000031     	beq	0x28004 <scarletbook_output_enqueue_raw_sectors+0x10c> @ imm = #0xc4
   27f3c: e3a00f5e     	mov	r0, #376
   27f40: e3a01001     	mov	r1, #1
   27f44: ebff9104     	bl	0xc35c <calloc@plt>     @ imm = #-0x1bbf0
   27f48: e1a03000     	mov	r3, r0
   27f4c: e50b300c     	str	r3, [r11, #-0xc]
   27f50: e51b300c     	ldr	r3, [r11, #-0xc]
   27f54: e51b2008     	ldr	r2, [r11, #-0x8]
   27f58: e5832168     	str	r2, [r3, #0x168]
   27f5c: e51b3018     	ldr	r3, [r11, #-0x18]
   27f60: e5932038     	ldr	r2, [r3, #0x38]
   27f64: e51b300c     	ldr	r3, [r11, #-0xc]
   27f68: e583216c     	str	r2, [r3, #0x16c]
   27f6c: e51b200c     	ldr	r2, [r11, #-0xc]
   27f70: e51b3010     	ldr	r3, [r11, #-0x10]
   27f74: e282c040     	add	r12, r2, #64
   27f78: e1a0e003     	mov	lr, r3
   27f7c: e8be000f     	ldm	lr!, {r0, r1, r2, r3}
   27f80: e8ac000f     	stm	r12!, {r0, r1, r2, r3}
   27f84: e89e0007     	ldm	lr, {r0, r1, r2}
   27f88: e88c0007     	stm	r12, {r0, r1, r2}
   27f8c: e51b0024     	ldr	r0, [r11, #-0x24]
   27f90: ebff91ae     	bl	0xc650 <strdup@plt>     @ imm = #-0x1b948
   27f94: e1a03000     	mov	r3, r0
   27f98: e1a02003     	mov	r2, r3
   27f9c: e51b300c     	ldr	r3, [r11, #-0xc]
   27fa0: e5832014     	str	r2, [r3, #0x14]
   27fa4: e51b201c     	ldr	r2, [r11, #-0x1c]
   27fa8: e51b300c     	ldr	r3, [r11, #-0xc]
   27fac: e5832008     	str	r2, [r3, #0x8]
   27fb0: e51b2020     	ldr	r2, [r11, #-0x20]
   27fb4: e51b300c     	ldr	r3, [r11, #-0xc]
   27fb8: e583200c     	str	r2, [r3, #0xc]
   27fbc: e59f3050     	ldr	r3, [pc, #0x50]         @ 0x28014 <scarletbook_output_enqueue_raw_sectors+0x11c>
   27fc0: e5933000     	ldr	r3, [r3]
   27fc4: e5933004     	ldr	r3, [r3, #0x4]
   27fc8: e3530003     	cmp	r3, #3
   27fcc: 9a000004     	bls	0x27fe4 <scarletbook_output_enqueue_raw_sectors+0xec> @ imm = #0x10
   27fd0: e59f0040     	ldr	r0, [pc, #0x40]         @ 0x28018 <scarletbook_output_enqueue_raw_sectors+0x120>
   27fd4: e51b1024     	ldr	r1, [r11, #-0x24]
   27fd8: e51b201c     	ldr	r2, [r11, #-0x1c]
   27fdc: e51b3020     	ldr	r3, [r11, #-0x20]
   27fe0: ebffb333     	bl	0x14cb4 <log_print>     @ imm = #-0x13334
   27fe4: e51b300c     	ldr	r3, [r11, #-0xc]
   27fe8: e2832e17     	add	r2, r3, #368
   27fec: e51b3018     	ldr	r3, [r11, #-0x18]
   27ff0: e1a00002     	mov	r0, r2
   27ff4: e1a01003     	mov	r1, r3
   27ff8: ebfffe03     	bl	0x2780c <list_add_tail> @ imm = #-0x7f4
   27ffc: e3a03000     	mov	r3, #0
   28000: ea000000     	b	0x28008 <scarletbook_output_enqueue_raw_sectors+0x110> @ imm = #0x0
   28004: e3e03000     	mvn	r3, #0
   28008: e1a00003     	mov	r0, r3
   2800c: e24bd004     	sub	sp, r11, #4
   28010: e8bd8800     	pop	{r11, pc}
   28014: 5c 73 05 00  	.word	0x0005735c
   28018: f0 56 03 00  	.word	0x000356f0

