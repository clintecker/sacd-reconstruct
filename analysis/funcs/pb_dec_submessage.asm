0000fb6c <pb_dec_submessage>:
    fb6c: e92d4800     	push	{r11, lr}
    fb70: e28db004     	add	r11, sp, #4
    fb74: e24dd020     	sub	sp, sp, #32
    fb78: e50b0018     	str	r0, [r11, #-0x18]
    fb7c: e50b101c     	str	r1, [r11, #-0x1c]
    fb80: e50b2020     	str	r2, [r11, #-0x20]
    fb84: e24b3014     	sub	r3, r11, #20
    fb88: e51b0018     	ldr	r0, [r11, #-0x18]
    fb8c: e1a01003     	mov	r1, r3
    fb90: ebfffc54     	bl	0xece8 <make_string_substream> @ imm = #-0xeb0
    fb94: e1a03000     	mov	r3, r0
    fb98: e2233001     	eor	r3, r3, #1
    fb9c: e6ef3073     	uxtb	r3, r3
    fba0: e3530000     	cmp	r3, #0
    fba4: 0a000001     	beq	0xfbb0 <pb_dec_submessage+0x44> @ imm = #0x4
    fba8: e3a03000     	mov	r3, #0
    fbac: ea000024     	b	0xfc44 <pb_dec_submessage+0xd8> @ imm = #0x90
    fbb0: e51b301c     	ldr	r3, [r11, #-0x1c]
    fbb4: e5d32009     	ldrb	r2, [r3, #0x9]
    fbb8: e5d3100a     	ldrb	r1, [r3, #0xa]
    fbbc: e1a01401     	lsl	r1, r1, #8
    fbc0: e1812002     	orr	r2, r1, r2
    fbc4: e5d3100b     	ldrb	r1, [r3, #0xb]
    fbc8: e1a01801     	lsl	r1, r1, #16
    fbcc: e1812002     	orr	r2, r1, r2
    fbd0: e5d3300c     	ldrb	r3, [r3, #0xc]
    fbd4: e1a03c03     	lsl	r3, r3, #24
    fbd8: e1833002     	orr	r3, r3, r2
    fbdc: e3530000     	cmp	r3, #0
    fbe0: 1a000001     	bne	0xfbec <pb_dec_submessage+0x80> @ imm = #0x4
    fbe4: e3a03000     	mov	r3, #0
    fbe8: ea000015     	b	0xfc44 <pb_dec_submessage+0xd8> @ imm = #0x54
    fbec: e51b301c     	ldr	r3, [r11, #-0x1c]
    fbf0: e5d32009     	ldrb	r2, [r3, #0x9]
    fbf4: e5d3100a     	ldrb	r1, [r3, #0xa]
    fbf8: e1a01401     	lsl	r1, r1, #8
    fbfc: e1812002     	orr	r2, r1, r2
    fc00: e5d3100b     	ldrb	r1, [r3, #0xb]
    fc04: e1a01801     	lsl	r1, r1, #16
    fc08: e1812002     	orr	r2, r1, r2
    fc0c: e5d3300c     	ldrb	r3, [r3, #0xc]
    fc10: e1a03c03     	lsl	r3, r3, #24
    fc14: e1833002     	orr	r3, r3, r2
    fc18: e24b2014     	sub	r2, r11, #20
    fc1c: e1a00002     	mov	r0, r2
    fc20: e1a01003     	mov	r1, r3
    fc24: e51b2020     	ldr	r2, [r11, #-0x20]
    fc28: ebfffe69     	bl	0xf5d4 <pb_decode>      @ imm = #-0x65c
    fc2c: e1a03000     	mov	r3, r0
    fc30: e54b3005     	strb	r3, [r11, #-0x5]
    fc34: e51b2010     	ldr	r2, [r11, #-0x10]
    fc38: e51b3018     	ldr	r3, [r11, #-0x18]
    fc3c: e5832004     	str	r2, [r3, #0x4]
    fc40: e55b3005     	ldrb	r3, [r11, #-0x5]
    fc44: e1a00003     	mov	r0, r3
    fc48: e24bd004     	sub	sp, r11, #4
    fc4c: e8bd8800     	pop	{r11, pc}

