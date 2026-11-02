0000f818 <pb_dec_varint>:
    f818: e92d4800     	push	{r11, lr}
    f81c: e28db004     	add	r11, sp, #4
    f820: e24dd020     	sub	sp, sp, #32
    f824: e50b0018     	str	r0, [r11, #-0x18]
    f828: e50b101c     	str	r1, [r11, #-0x1c]
    f82c: e50b2020     	str	r2, [r11, #-0x20]
    f830: e24b3014     	sub	r3, r11, #20
    f834: e51b0018     	ldr	r0, [r11, #-0x18]
    f838: e1a01003     	mov	r1, r3
    f83c: ebfffc4a     	bl	0xe96c <pb_decode_varint> @ imm = #-0xed8
    f840: e1a03000     	mov	r3, r0
    f844: e54b3005     	strb	r3, [r11, #-0x5]
    f848: e51b301c     	ldr	r3, [r11, #-0x1c]
    f84c: e5d32004     	ldrb	r2, [r3, #0x4]
    f850: e5d31005     	ldrb	r1, [r3, #0x5]
    f854: e1a01401     	lsl	r1, r1, #8
    f858: e1812002     	orr	r2, r1, r2
    f85c: e5d31006     	ldrb	r1, [r3, #0x6]
    f860: e1a01801     	lsl	r1, r1, #16
    f864: e1812002     	orr	r2, r1, r2
    f868: e5d33007     	ldrb	r3, [r3, #0x7]
    f86c: e1a03c03     	lsl	r3, r3, #24
    f870: e1833002     	orr	r3, r3, r2
    f874: e24b2014     	sub	r2, r11, #20
    f878: e51b0020     	ldr	r0, [r11, #-0x20]
    f87c: e1a01002     	mov	r1, r2
    f880: e1a02003     	mov	r2, r3
    f884: e3a03008     	mov	r3, #8
    f888: ebffffd5     	bl	0xf7e4 <endian_copy>    @ imm = #-0xac
    f88c: e55b3005     	ldrb	r3, [r11, #-0x5]
    f890: e1a00003     	mov	r0, r3
    f894: e24bd004     	sub	sp, r11, #4
    f898: e8bd8800     	pop	{r11, pc}

