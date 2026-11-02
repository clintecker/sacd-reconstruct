0000e72c <charset_from_utf8>:
    e72c: e92d4800     	push	{r11, lr}
    e730: e28db004     	add	r11, sp, #4
    e734: e24dd008     	sub	sp, sp, #8
    e738: e50b0008     	str	r0, [r11, #-0x8]
    e73c: e51b3008     	ldr	r3, [r11, #-0x8]
    e740: e3530000     	cmp	r3, #0
    e744: 1a000001     	bne	0xe750 <charset_from_utf8+0x24> @ imm = #0x4
    e748: e3a03000     	mov	r3, #0
    e74c: ea000008     	b	0xe774 <charset_from_utf8+0x48> @ imm = #0x20
    e750: e51b0008     	ldr	r0, [r11, #-0x8]
    e754: ebfff760     	bl	0xc4dc <strlen@plt>     @ imm = #-0x2280
    e758: e1a03000     	mov	r3, r0
    e75c: e51b0008     	ldr	r0, [r11, #-0x8]
    e760: e1a01003     	mov	r1, r3
    e764: e59f2014     	ldr	r2, [pc, #0x14]         @ 0xe780 <charset_from_utf8+0x54>
    e768: e3a03000     	mov	r3, #0
    e76c: ebffff60     	bl	0xe4f4 <charset_convert> @ imm = #-0x280
    e770: e1a03000     	mov	r3, r0
    e774: e1a00003     	mov	r0, r3
    e778: e24bd004     	sub	sp, r11, #4
    e77c: e8bd8800     	pop	{r11, pc}
    e780: 40 27 03 00  	.word	0x00032740

