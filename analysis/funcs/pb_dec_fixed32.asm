0000f95c <pb_dec_fixed32>:
    f95c: e92d4800     	push	{r11, lr}
    f960: e28db004     	add	r11, sp, #4
    f964: e24dd010     	sub	sp, sp, #16
    f968: e50b0008     	str	r0, [r11, #-0x8]
    f96c: e50b100c     	str	r1, [r11, #-0xc]
    f970: e50b2010     	str	r2, [r11, #-0x10]
    f974: e51b3010     	ldr	r3, [r11, #-0x10]
    f978: e51b0008     	ldr	r0, [r11, #-0x8]
    f97c: e1a01003     	mov	r1, r3
    f980: e3a02004     	mov	r2, #4
    f984: ebfffb94     	bl	0xe7dc <pb_read>        @ imm = #-0x11b0
    f988: e1a03000     	mov	r3, r0
    f98c: e1a00003     	mov	r0, r3
    f990: e24bd004     	sub	sp, r11, #4
    f994: e8bd8800     	pop	{r11, pc}

