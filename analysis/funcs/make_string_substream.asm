0000ece8 <make_string_substream>:
    ece8: e92d4800     	push	{r11, lr}
    ecec: e28db004     	add	r11, sp, #4
    ecf0: e24dd010     	sub	sp, sp, #16
    ecf4: e50b0010     	str	r0, [r11, #-0x10]
    ecf8: e50b1014     	str	r1, [r11, #-0x14]
    ecfc: e24b3008     	sub	r3, r11, #8
    ed00: e51b0010     	ldr	r0, [r11, #-0x10]
    ed04: e1a01003     	mov	r1, r3
    ed08: ebffff05     	bl	0xe924 <pb_decode_varint32> @ imm = #-0x3ec
    ed0c: e1a03000     	mov	r3, r0
    ed10: e2233001     	eor	r3, r3, #1
    ed14: e6ef3073     	uxtb	r3, r3
    ed18: e3530000     	cmp	r3, #0
    ed1c: 0a000001     	beq	0xed28 <make_string_substream+0x40> @ imm = #0x4
    ed20: e3a03000     	mov	r3, #0
    ed24: ea000014     	b	0xed7c <make_string_substream+0x94> @ imm = #0x50
    ed28: e51b3014     	ldr	r3, [r11, #-0x14]
    ed2c: e51b2010     	ldr	r2, [r11, #-0x10]
    ed30: e8920007     	ldm	r2, {r0, r1, r2}
    ed34: e8830007     	stm	r3, {r0, r1, r2}
    ed38: e51b3014     	ldr	r3, [r11, #-0x14]
    ed3c: e5932008     	ldr	r2, [r3, #0x8]
    ed40: e51b3008     	ldr	r3, [r11, #-0x8]
    ed44: e1520003     	cmp	r2, r3
    ed48: 2a000001     	bhs	0xed54 <make_string_substream+0x6c> @ imm = #0x4
    ed4c: e3a03000     	mov	r3, #0
    ed50: ea000009     	b	0xed7c <make_string_substream+0x94> @ imm = #0x24
    ed54: e51b2008     	ldr	r2, [r11, #-0x8]
    ed58: e51b3014     	ldr	r3, [r11, #-0x14]
    ed5c: e5832008     	str	r2, [r3, #0x8]
    ed60: e51b3010     	ldr	r3, [r11, #-0x10]
    ed64: e5932008     	ldr	r2, [r3, #0x8]
    ed68: e51b3008     	ldr	r3, [r11, #-0x8]
    ed6c: e0632002     	rsb	r2, r3, r2
    ed70: e51b3010     	ldr	r3, [r11, #-0x10]
    ed74: e5832008     	str	r2, [r3, #0x8]
    ed78: e3a03001     	mov	r3, #1
    ed7c: e1a00003     	mov	r0, r3
    ed80: e24bd004     	sub	sp, r11, #4
    ed84: e8bd8800     	pop	{r11, pc}

