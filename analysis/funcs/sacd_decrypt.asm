0002ec98 <sacd_decrypt>:
   2ec98: e92d4800     	push	{r11, lr}
   2ec9c: e28db004     	add	r11, sp, #4
   2eca0: e24dd010     	sub	sp, sp, #16
   2eca4: e50b0008     	str	r0, [r11, #-0x8]
   2eca8: e50b100c     	str	r1, [r11, #-0xc]
   2ecac: e50b2010     	str	r2, [r11, #-0x10]
   2ecb0: e51b3008     	ldr	r3, [r11, #-0x8]
   2ecb4: e5933004     	ldr	r3, [r3, #0x4]
   2ecb8: e3530000     	cmp	r3, #0
   2ecbc: 1a000001     	bne	0x2ecc8 <sacd_decrypt+0x30> @ imm = #0x4
   2ecc0: e3a03000     	mov	r3, #0
   2ecc4: ea000008     	b	0x2ecec <sacd_decrypt+0x54> @ imm = #0x20
   2ecc8: e59f3028     	ldr	r3, [pc, #0x28]         @ 0x2ecf8 <sacd_decrypt+0x60>
   2eccc: e5933000     	ldr	r3, [r3]
   2ecd0: e51b2008     	ldr	r2, [r11, #-0x8]
   2ecd4: e5922004     	ldr	r2, [r2, #0x4]
   2ecd8: e1a00002     	mov	r0, r2
   2ecdc: e51b100c     	ldr	r1, [r11, #-0xc]
   2ece0: e51b2010     	ldr	r2, [r11, #-0x10]
   2ece4: e12fff33     	blx	r3
   2ece8: e1a03000     	mov	r3, r0
   2ecec: e1a00003     	mov	r0, r3
   2ecf0: e24bd004     	sub	sp, r11, #4
   2ecf4: e8bd8800     	pop	{r11, pc}
   2ecf8: fc 9d 05 00  	.word	0x00059dfc

