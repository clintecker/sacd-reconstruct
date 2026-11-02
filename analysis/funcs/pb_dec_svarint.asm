0000f89c <pb_dec_svarint>:
    f89c: e92d4830     	push	{r4, r5, r11, lr}
    f8a0: e28db00c     	add	r11, sp, #12
    f8a4: e24dd020     	sub	sp, sp, #32
    f8a8: e50b0020     	str	r0, [r11, #-0x20]
    f8ac: e50b1024     	str	r1, [r11, #-0x24]
    f8b0: e50b2028     	str	r2, [r11, #-0x28]
    f8b4: e24b301c     	sub	r3, r11, #28
    f8b8: e51b0020     	ldr	r0, [r11, #-0x20]
    f8bc: e1a01003     	mov	r1, r3
    f8c0: ebfffc29     	bl	0xe96c <pb_decode_varint> @ imm = #-0xf5c
    f8c4: e1a03000     	mov	r3, r0
    f8c8: e54b300d     	strb	r3, [r11, #-0xd]
    f8cc: e14b21dc     	ldrd	r2, r3, [r11, #-28]
    f8d0: e1b010a3     	lsrs	r1, r3, #1
    f8d4: e1a00062     	rrx	r0, r2
    f8d8: e14b21dc     	ldrd	r2, r3, [r11, #-28]
    f8dc: e1a04002     	mov	r4, r2
    f8e0: e1a05003     	mov	r5, r3
    f8e4: e3a02001     	mov	r2, #1
    f8e8: e3a03000     	mov	r3, #0
    f8ec: e0022004     	and	r2, r2, r4
    f8f0: e0033005     	and	r3, r3, r5
    f8f4: e2722000     	rsbs	r2, r2, #0
    f8f8: e2e33000     	rsc	r3, r3, #0
    f8fc: e0222000     	eor	r2, r2, r0
    f900: e0233001     	eor	r3, r3, r1
    f904: e14b21fc     	strd	r2, r3, [r11, #-28]
    f908: e51b3024     	ldr	r3, [r11, #-0x24]
    f90c: e5d32004     	ldrb	r2, [r3, #0x4]
    f910: e5d31005     	ldrb	r1, [r3, #0x5]
    f914: e1a01401     	lsl	r1, r1, #8
    f918: e1812002     	orr	r2, r1, r2
    f91c: e5d31006     	ldrb	r1, [r3, #0x6]
    f920: e1a01801     	lsl	r1, r1, #16
    f924: e1812002     	orr	r2, r1, r2
    f928: e5d33007     	ldrb	r3, [r3, #0x7]
    f92c: e1a03c03     	lsl	r3, r3, #24
    f930: e1833002     	orr	r3, r3, r2
    f934: e24b201c     	sub	r2, r11, #28
    f938: e51b0028     	ldr	r0, [r11, #-0x28]
    f93c: e1a01002     	mov	r1, r2
    f940: e1a02003     	mov	r2, r3
    f944: e3a03008     	mov	r3, #8
    f948: ebffffa5     	bl	0xf7e4 <endian_copy>    @ imm = #-0x16c
    f94c: e55b300d     	ldrb	r3, [r11, #-0xd]
    f950: e1a00003     	mov	r0, r3
    f954: e24bd00c     	sub	sp, r11, #12
    f958: e8bd8830     	pop	{r4, r5, r11, pc}

