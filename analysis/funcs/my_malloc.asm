000156d0 <my_malloc>:
   156d0: e92d4800     	push	{r11, lr}
   156d4: e28db004     	add	r11, sp, #4
   156d8: e24dd010     	sub	sp, sp, #16
   156dc: e50b0010     	str	r0, [r11, #-0x10]
   156e0: e59f3034     	ldr	r3, [pc, #0x34]         @ 0x1571c <my_malloc+0x4c>
   156e4: e5933000     	ldr	r3, [r3]
   156e8: e51b0010     	ldr	r0, [r11, #-0x10]
   156ec: e12fff33     	blx	r3
   156f0: e1a03000     	mov	r3, r0
   156f4: e50b3008     	str	r3, [r11, #-0x8]
   156f8: e51b3008     	ldr	r3, [r11, #-0x8]
   156fc: e3530000     	cmp	r3, #0
   15700: 1a000001     	bne	0x1570c <my_malloc+0x3c> @ imm = #0x4
   15704: e3a0000c     	mov	r0, #12
   15708: ebffffb4     	bl	0x155e0 <fail>          @ imm = #-0x130
   1570c: e51b3008     	ldr	r3, [r11, #-0x8]
   15710: e1a00003     	mov	r0, r3
   15714: e24bd004     	sub	sp, r11, #4
   15718: e8bd8800     	pop	{r11, pc}
   1571c: d4 e7 03 00  	.word	0x0003e7d4

