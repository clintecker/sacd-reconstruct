0000faa0 <pb_dec_string>:
    faa0: e92d4800     	push	{r11, lr}
    faa4: e28db004     	add	r11, sp, #4
    faa8: e24dd018     	sub	sp, sp, #24
    faac: e50b0010     	str	r0, [r11, #-0x10]
    fab0: e50b1014     	str	r1, [r11, #-0x14]
    fab4: e50b2018     	str	r2, [r11, #-0x18]
    fab8: e24b300c     	sub	r3, r11, #12
    fabc: e51b0010     	ldr	r0, [r11, #-0x10]
    fac0: e1a01003     	mov	r1, r3
    fac4: ebfffb96     	bl	0xe924 <pb_decode_varint32> @ imm = #-0x11a8
    fac8: e1a03000     	mov	r3, r0
    facc: e2233001     	eor	r3, r3, #1
    fad0: e6ef3073     	uxtb	r3, r3
    fad4: e3530000     	cmp	r3, #0
    fad8: 0a000001     	beq	0xfae4 <pb_dec_string+0x44> @ imm = #0x4
    fadc: e3a03000     	mov	r3, #0
    fae0: ea00001e     	b	0xfb60 <pb_dec_string+0xc0> @ imm = #0x78
    fae4: e51b3014     	ldr	r3, [r11, #-0x14]
    fae8: e5d32004     	ldrb	r2, [r3, #0x4]
    faec: e5d31005     	ldrb	r1, [r3, #0x5]
    faf0: e1a01401     	lsl	r1, r1, #8
    faf4: e1812002     	orr	r2, r1, r2
    faf8: e5d31006     	ldrb	r1, [r3, #0x6]
    fafc: e1a01801     	lsl	r1, r1, #16
    fb00: e1812002     	orr	r2, r1, r2
    fb04: e5d33007     	ldrb	r3, [r3, #0x7]
    fb08: e1a03c03     	lsl	r3, r3, #24
    fb0c: e1833002     	orr	r3, r3, r2
    fb10: e2432001     	sub	r2, r3, #1
    fb14: e51b300c     	ldr	r3, [r11, #-0xc]
    fb18: e1520003     	cmp	r2, r3
    fb1c: 2a000001     	bhs	0xfb28 <pb_dec_string+0x88> @ imm = #0x4
    fb20: e3a03000     	mov	r3, #0
    fb24: ea00000d     	b	0xfb60 <pb_dec_string+0xc0> @ imm = #0x34
    fb28: e51b2018     	ldr	r2, [r11, #-0x18]
    fb2c: e51b300c     	ldr	r3, [r11, #-0xc]
    fb30: e51b0010     	ldr	r0, [r11, #-0x10]
    fb34: e1a01002     	mov	r1, r2
    fb38: e1a02003     	mov	r2, r3
    fb3c: ebfffb26     	bl	0xe7dc <pb_read>        @ imm = #-0x1368
    fb40: e1a03000     	mov	r3, r0
    fb44: e54b3005     	strb	r3, [r11, #-0x5]
    fb48: e51b2018     	ldr	r2, [r11, #-0x18]
    fb4c: e51b300c     	ldr	r3, [r11, #-0xc]
    fb50: e0823003     	add	r3, r2, r3
    fb54: e3a02000     	mov	r2, #0
    fb58: e5c32000     	strb	r2, [r3]
    fb5c: e55b3005     	ldrb	r3, [r11, #-0x5]
    fb60: e1a00003     	mov	r0, r3
    fb64: e24bd004     	sub	sp, r11, #4
    fb68: e8bd8800     	pop	{r11, pc}

