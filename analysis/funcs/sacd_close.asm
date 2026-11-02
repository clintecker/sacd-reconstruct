0002eaac <sacd_close>:
   2eaac: e92d4800     	push	{r11, lr}
   2eab0: e28db004     	add	r11, sp, #4
   2eab4: e24dd008     	sub	sp, sp, #8
   2eab8: e50b0008     	str	r0, [r11, #-0x8]
   2eabc: e51b3008     	ldr	r3, [r11, #-0x8]
   2eac0: e3530000     	cmp	r3, #0
   2eac4: 0a00000b     	beq	0x2eaf8 <sacd_close+0x4c> @ imm = #0x2c
   2eac8: e51b3008     	ldr	r3, [r11, #-0x8]
   2eacc: e5933004     	ldr	r3, [r3, #0x4]
   2ead0: e3530000     	cmp	r3, #0
   2ead4: 0a000005     	beq	0x2eaf0 <sacd_close+0x44> @ imm = #0x14
   2ead8: e59f3020     	ldr	r3, [pc, #0x20]         @ 0x2eb00 <sacd_close+0x54>
   2eadc: e5933000     	ldr	r3, [r3]
   2eae0: e51b2008     	ldr	r2, [r11, #-0x8]
   2eae4: e5922004     	ldr	r2, [r2, #0x4]
   2eae8: e1a00002     	mov	r0, r2
   2eaec: e12fff33     	blx	r3
   2eaf0: e51b0008     	ldr	r0, [r11, #-0x8]
   2eaf4: ebff7648     	bl	0xc41c <free@plt>       @ imm = #-0x226e0
   2eaf8: e24bd004     	sub	sp, r11, #4
   2eafc: e8bd8800     	pop	{r11, pc}
   2eb00: 18 9e 05 00  	.word	0x00059e18

