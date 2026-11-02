0000eab8 <pb_skip_string>:
    eab8: e92d4800     	push	{r11, lr}
    eabc: e28db004     	add	r11, sp, #4
    eac0: e24dd010     	sub	sp, sp, #16
    eac4: e50b0010     	str	r0, [r11, #-0x10]
    eac8: e24b3008     	sub	r3, r11, #8
    eacc: e51b0010     	ldr	r0, [r11, #-0x10]
    ead0: e1a01003     	mov	r1, r3
    ead4: ebffff92     	bl	0xe924 <pb_decode_varint32> @ imm = #-0x1b8
    ead8: e1a03000     	mov	r3, r0
    eadc: e2233001     	eor	r3, r3, #1
    eae0: e6ef3073     	uxtb	r3, r3
    eae4: e3530000     	cmp	r3, #0
    eae8: 0a000001     	beq	0xeaf4 <pb_skip_string+0x3c> @ imm = #0x4
    eaec: e3a03000     	mov	r3, #0
    eaf0: ea000005     	b	0xeb0c <pb_skip_string+0x54> @ imm = #0x14
    eaf4: e51b3008     	ldr	r3, [r11, #-0x8]
    eaf8: e51b0010     	ldr	r0, [r11, #-0x10]
    eafc: e3a01000     	mov	r1, #0
    eb00: e1a02003     	mov	r2, r3
    eb04: ebffff34     	bl	0xe7dc <pb_read>        @ imm = #-0x330
    eb08: e1a03000     	mov	r3, r0
    eb0c: e1a00003     	mov	r0, r3
    eb10: e24bd004     	sub	sp, r11, #4
    eb14: e8bd8800     	pop	{r11, pc}

