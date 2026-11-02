0002ec44 <sacd_authenticate>:
   2ec44: e92d4800     	push	{r11, lr}
   2ec48: e28db004     	add	r11, sp, #4
   2ec4c: e24dd008     	sub	sp, sp, #8
   2ec50: e50b0008     	str	r0, [r11, #-0x8]
   2ec54: e51b3008     	ldr	r3, [r11, #-0x8]
   2ec58: e5933004     	ldr	r3, [r3, #0x4]
   2ec5c: e3530000     	cmp	r3, #0
   2ec60: 1a000001     	bne	0x2ec6c <sacd_authenticate+0x28> @ imm = #0x4
   2ec64: e3a03000     	mov	r3, #0
   2ec68: ea000006     	b	0x2ec88 <sacd_authenticate+0x44> @ imm = #0x18
   2ec6c: e59f3020     	ldr	r3, [pc, #0x20]         @ 0x2ec94 <sacd_authenticate+0x50>
   2ec70: e5933000     	ldr	r3, [r3]
   2ec74: e51b2008     	ldr	r2, [r11, #-0x8]
   2ec78: e5922004     	ldr	r2, [r2, #0x4]
   2ec7c: e1a00002     	mov	r0, r2
   2ec80: e12fff33     	blx	r3
   2ec84: e1a03000     	mov	r3, r0
   2ec88: e1a00003     	mov	r0, r3
   2ec8c: e24bd004     	sub	sp, r11, #4
   2ec90: e8bd8800     	pop	{r11, pc}
   2ec94: 0c 9e 05 00  	.word	0x00059e0c

