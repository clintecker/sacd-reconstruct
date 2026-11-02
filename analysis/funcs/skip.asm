0000eb18 <skip>:
    eb18: e92d4800     	push	{r11, lr}
    eb1c: e28db004     	add	r11, sp, #4
    eb20: e24dd008     	sub	sp, sp, #8
    eb24: e50b0008     	str	r0, [r11, #-0x8]
    eb28: e50b100c     	str	r1, [r11, #-0xc]
    eb2c: e51b300c     	ldr	r3, [r11, #-0xc]
    eb30: e3530005     	cmp	r3, #5
    eb34: 979ff103     	ldrls	pc, [pc, r3, lsl #2]
    eb38: ea000019     	b	0xeba4 <skip+0x8c>      @ imm = #0x64
    eb3c: 54 eb 00 00  	.word	0x0000eb54
    eb40: 64 eb 00 00  	.word	0x0000eb64
    eb44: 7c eb 00 00  	.word	0x0000eb7c
    eb48: a4 eb 00 00  	.word	0x0000eba4
    eb4c: a4 eb 00 00  	.word	0x0000eba4
    eb50: 8c eb 00 00  	.word	0x0000eb8c
    eb54: e51b0008     	ldr	r0, [r11, #-0x8]
    eb58: ebffffbe     	bl	0xea58 <pb_skip_varint> @ imm = #-0x108
    eb5c: e1a03000     	mov	r3, r0
    eb60: ea000010     	b	0xeba8 <skip+0x90>      @ imm = #0x40
    eb64: e51b0008     	ldr	r0, [r11, #-0x8]
    eb68: e3a01000     	mov	r1, #0
    eb6c: e3a02008     	mov	r2, #8
    eb70: ebffff19     	bl	0xe7dc <pb_read>        @ imm = #-0x39c
    eb74: e1a03000     	mov	r3, r0
    eb78: ea00000a     	b	0xeba8 <skip+0x90>      @ imm = #0x28
    eb7c: e51b0008     	ldr	r0, [r11, #-0x8]
    eb80: ebffffcc     	bl	0xeab8 <pb_skip_string> @ imm = #-0xd0
    eb84: e1a03000     	mov	r3, r0
    eb88: ea000006     	b	0xeba8 <skip+0x90>      @ imm = #0x18
    eb8c: e51b0008     	ldr	r0, [r11, #-0x8]
    eb90: e3a01000     	mov	r1, #0
    eb94: e3a02004     	mov	r2, #4
    eb98: ebffff0f     	bl	0xe7dc <pb_read>        @ imm = #-0x3c4
    eb9c: e1a03000     	mov	r3, r0
    eba0: ea000000     	b	0xeba8 <skip+0x90>      @ imm = #0x0
    eba4: e3a03000     	mov	r3, #0
    eba8: e1a00003     	mov	r0, r3
    ebac: e24bd004     	sub	sp, r11, #4
    ebb0: e8bd8800     	pop	{r11, pc}

