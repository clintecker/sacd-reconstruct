0002ecfc <sacd_get_total_sectors>:
   2ecfc: e92d4800     	push	{r11, lr}
   2ed00: e28db004     	add	r11, sp, #4
   2ed04: e24dd008     	sub	sp, sp, #8
   2ed08: e50b0008     	str	r0, [r11, #-0x8]
   2ed0c: e51b3008     	ldr	r3, [r11, #-0x8]
   2ed10: e5933004     	ldr	r3, [r3, #0x4]
   2ed14: e3530000     	cmp	r3, #0
   2ed18: 1a000001     	bne	0x2ed24 <sacd_get_total_sectors+0x28> @ imm = #0x4
   2ed1c: e3a03000     	mov	r3, #0
   2ed20: ea000006     	b	0x2ed40 <sacd_get_total_sectors+0x44> @ imm = #0x18
   2ed24: e59f3020     	ldr	r3, [pc, #0x20]         @ 0x2ed4c <sacd_get_total_sectors+0x50>
   2ed28: e5933000     	ldr	r3, [r3]
   2ed2c: e51b2008     	ldr	r2, [r11, #-0x8]
   2ed30: e5922004     	ldr	r2, [r2, #0x4]
   2ed34: e1a00002     	mov	r0, r2
   2ed38: e12fff33     	blx	r3
   2ed3c: e1a03000     	mov	r3, r0
   2ed40: e1a00003     	mov	r0, r3
   2ed44: e24bd004     	sub	sp, r11, #4
   2ed48: e8bd8800     	pop	{r11, pc}
   2ed4c: 00 9e 05 00  	.word	0x00059e00

