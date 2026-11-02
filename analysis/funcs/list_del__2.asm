00027878 <list_del>:
   27878: e92d4800     	push	{r11, lr}
   2787c: e28db004     	add	r11, sp, #4
   27880: e24dd008     	sub	sp, sp, #8
   27884: e50b0008     	str	r0, [r11, #-0x8]
   27888: e51b3008     	ldr	r3, [r11, #-0x8]
   2788c: e5932004     	ldr	r2, [r3, #0x4]
   27890: e51b3008     	ldr	r3, [r11, #-0x8]
   27894: e5933000     	ldr	r3, [r3]
   27898: e1a00002     	mov	r0, r2
   2789c: e1a01003     	mov	r1, r3
   278a0: ebffffe6     	bl	0x27840 <__list_del>    @ imm = #-0x68
   278a4: e51b3008     	ldr	r3, [r11, #-0x8]
   278a8: e59f2014     	ldr	r2, [pc, #0x14]         @ 0x278c4 <list_del+0x4c>
   278ac: e5832000     	str	r2, [r3]
   278b0: e51b3008     	ldr	r3, [r11, #-0x8]
   278b4: e59f200c     	ldr	r2, [pc, #0xc]          @ 0x278c8 <list_del+0x50>
   278b8: e5832004     	str	r2, [r3, #0x4]
   278bc: e24bd004     	sub	sp, r11, #4
   278c0: e8bd8800     	pop	{r11, pc}
   278c4: 00 01 10 00  	.word	0x00100100
   278c8: 00 02 20 00  	.word	0x00200200

