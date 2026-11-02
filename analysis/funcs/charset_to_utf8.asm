0000e784 <charset_to_utf8>:
    e784: e92d4800     	push	{r11, lr}
    e788: e28db004     	add	r11, sp, #4
    e78c: e24dd008     	sub	sp, sp, #8
    e790: e50b0008     	str	r0, [r11, #-0x8]
    e794: e51b3008     	ldr	r3, [r11, #-0x8]
    e798: e3530000     	cmp	r3, #0
    e79c: 1a000001     	bne	0xe7a8 <charset_to_utf8+0x24> @ imm = #0x4
    e7a0: e3a03000     	mov	r3, #0
    e7a4: ea000008     	b	0xe7cc <charset_to_utf8+0x48> @ imm = #0x20
    e7a8: e51b0008     	ldr	r0, [r11, #-0x8]
    e7ac: ebfff74a     	bl	0xc4dc <strlen@plt>     @ imm = #-0x22d8
    e7b0: e1a03000     	mov	r3, r0
    e7b4: e51b0008     	ldr	r0, [r11, #-0x8]
    e7b8: e1a01003     	mov	r1, r3
    e7bc: e3a02000     	mov	r2, #0
    e7c0: e59f3010     	ldr	r3, [pc, #0x10]         @ 0xe7d8 <charset_to_utf8+0x54>
    e7c4: ebffff4a     	bl	0xe4f4 <charset_convert> @ imm = #-0x2d8
    e7c8: e1a03000     	mov	r3, r0
    e7cc: e1a00003     	mov	r0, r3
    e7d0: e24bd004     	sub	sp, r11, #4
    e7d4: e8bd8800     	pop	{r11, pc}
    e7d8: 40 27 03 00  	.word	0x00032740

