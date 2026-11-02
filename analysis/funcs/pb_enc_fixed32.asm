00012290 <pb_enc_fixed32>:
   12290: e92d4800     	push	{r11, lr}
   12294: e28db004     	add	r11, sp, #4
   12298: e24dd010     	sub	sp, sp, #16
   1229c: e50b0008     	str	r0, [r11, #-0x8]
   122a0: e50b100c     	str	r1, [r11, #-0xc]
   122a4: e50b2010     	str	r2, [r11, #-0x10]
   122a8: e51b3010     	ldr	r3, [r11, #-0x10]
   122ac: e51b0008     	ldr	r0, [r11, #-0x8]
   122b0: e1a01003     	mov	r1, r3
   122b4: e3a02004     	mov	r2, #4
   122b8: ebfffcf6     	bl	0x11698 <pb_write>      @ imm = #-0xc28
   122bc: e1a03000     	mov	r3, r0
   122c0: e1a00003     	mov	r0, r3
   122c4: e24bd004     	sub	sp, r11, #4
   122c8: e8bd8800     	pop	{r11, pc}

