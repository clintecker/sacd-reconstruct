0000f9d4 <pb_dec_bytes>:
    f9d4: e92d4800     	push	{r11, lr}
    f9d8: e28db004     	add	r11, sp, #4
    f9dc: e24dd018     	sub	sp, sp, #24
    f9e0: e50b0010     	str	r0, [r11, #-0x10]
    f9e4: e50b1014     	str	r1, [r11, #-0x14]
    f9e8: e50b2018     	str	r2, [r11, #-0x18]
    f9ec: e51b3018     	ldr	r3, [r11, #-0x18]
    f9f0: e50b3008     	str	r3, [r11, #-0x8]
    f9f4: e24b300c     	sub	r3, r11, #12
    f9f8: e51b0010     	ldr	r0, [r11, #-0x10]
    f9fc: e1a01003     	mov	r1, r3
    fa00: ebfffbc7     	bl	0xe924 <pb_decode_varint32> @ imm = #-0x10e4
    fa04: e1a03000     	mov	r3, r0
    fa08: e2233001     	eor	r3, r3, #1
    fa0c: e6ef3073     	uxtb	r3, r3
    fa10: e3530000     	cmp	r3, #0
    fa14: 0a000001     	beq	0xfa20 <pb_dec_bytes+0x4c> @ imm = #0x4
    fa18: e3a03000     	mov	r3, #0
    fa1c: ea00001c     	b	0xfa94 <pb_dec_bytes+0xc0> @ imm = #0x70
    fa20: e51b200c     	ldr	r2, [r11, #-0xc]
    fa24: e51b3008     	ldr	r3, [r11, #-0x8]
    fa28: e5832000     	str	r2, [r3]
    fa2c: e51b3008     	ldr	r3, [r11, #-0x8]
    fa30: e5932000     	ldr	r2, [r3]
    fa34: e51b3014     	ldr	r3, [r11, #-0x14]
    fa38: e5d31004     	ldrb	r1, [r3, #0x4]
    fa3c: e5d30005     	ldrb	r0, [r3, #0x5]
    fa40: e1a00400     	lsl	r0, r0, #8
    fa44: e1801001     	orr	r1, r0, r1
    fa48: e5d30006     	ldrb	r0, [r3, #0x6]
    fa4c: e1a00800     	lsl	r0, r0, #16
    fa50: e1801001     	orr	r1, r0, r1
    fa54: e5d33007     	ldrb	r3, [r3, #0x7]
    fa58: e1a03c03     	lsl	r3, r3, #24
    fa5c: e1833001     	orr	r3, r3, r1
    fa60: e1520003     	cmp	r2, r3
    fa64: 9a000001     	bls	0xfa70 <pb_dec_bytes+0x9c> @ imm = #0x4
    fa68: e3a03000     	mov	r3, #0
    fa6c: ea000008     	b	0xfa94 <pb_dec_bytes+0xc0> @ imm = #0x20
    fa70: e51b3008     	ldr	r3, [r11, #-0x8]
    fa74: e5932004     	ldr	r2, [r3, #0x4]
    fa78: e51b3008     	ldr	r3, [r11, #-0x8]
    fa7c: e5933000     	ldr	r3, [r3]
    fa80: e51b0010     	ldr	r0, [r11, #-0x10]
    fa84: e1a01002     	mov	r1, r2
    fa88: e1a02003     	mov	r2, r3
    fa8c: ebfffb52     	bl	0xe7dc <pb_read>        @ imm = #-0x12b8
    fa90: e1a03000     	mov	r3, r0
    fa94: e1a00003     	mov	r0, r3
    fa98: e24bd004     	sub	sp, r11, #4
    fa9c: e8bd8800     	pop	{r11, pc}

