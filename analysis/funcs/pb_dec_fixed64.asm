0000f998 <pb_dec_fixed64>:
    f998: e92d4800     	push	{r11, lr}
    f99c: e28db004     	add	r11, sp, #4
    f9a0: e24dd010     	sub	sp, sp, #16
    f9a4: e50b0008     	str	r0, [r11, #-0x8]
    f9a8: e50b100c     	str	r1, [r11, #-0xc]
    f9ac: e50b2010     	str	r2, [r11, #-0x10]
    f9b0: e51b3010     	ldr	r3, [r11, #-0x10]
    f9b4: e51b0008     	ldr	r0, [r11, #-0x8]
    f9b8: e1a01003     	mov	r1, r3
    f9bc: e3a02008     	mov	r2, #8
    f9c0: ebfffb85     	bl	0xe7dc <pb_read>        @ imm = #-0x11ec
    f9c4: e1a03000     	mov	r3, r0
    f9c8: e1a00003     	mov	r0, r3
    f9cc: e24bd004     	sub	sp, r11, #4
    f9d0: e8bd8800     	pop	{r11, pc}

