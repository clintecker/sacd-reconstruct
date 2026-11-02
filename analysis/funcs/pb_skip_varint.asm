0000ea58 <pb_skip_varint>:
    ea58: e92d4800     	push	{r11, lr}
    ea5c: e28db004     	add	r11, sp, #4
    ea60: e24dd010     	sub	sp, sp, #16
    ea64: e50b0010     	str	r0, [r11, #-0x10]
    ea68: e24b3005     	sub	r3, r11, #5
    ea6c: e51b0010     	ldr	r0, [r11, #-0x10]
    ea70: e1a01003     	mov	r1, r3
    ea74: e3a02001     	mov	r2, #1
    ea78: ebffff57     	bl	0xe7dc <pb_read>        @ imm = #-0x2a4
    ea7c: e1a03000     	mov	r3, r0
    ea80: e2233001     	eor	r3, r3, #1
    ea84: e6ef3073     	uxtb	r3, r3
    ea88: e3530000     	cmp	r3, #0
    ea8c: 0a000001     	beq	0xea98 <pb_skip_varint+0x40> @ imm = #0x4
    ea90: e3a03000     	mov	r3, #0
    ea94: ea000004     	b	0xeaac <pb_skip_varint+0x54> @ imm = #0x10
    ea98: e55b3005     	ldrb	r3, [r11, #-0x5]
    ea9c: e6af3073     	sxtb	r3, r3
    eaa0: e3530000     	cmp	r3, #0
    eaa4: baffffef     	blt	0xea68 <pb_skip_varint+0x10> @ imm = #-0x44
    eaa8: e3a03001     	mov	r3, #1
    eaac: e1a00003     	mov	r0, r3
    eab0: e24bd004     	sub	sp, r11, #4
    eab4: e8bd8800     	pop	{r11, pc}

