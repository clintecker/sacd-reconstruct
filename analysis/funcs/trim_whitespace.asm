00013d80 <trim_whitespace>:
   13d80: e92d4800     	push	{r11, lr}
   13d84: e28db004     	add	r11, sp, #4
   13d88: e24dd010     	sub	sp, sp, #16
   13d8c: e50b0010     	str	r0, [r11, #-0x10]
   13d90: e51b3010     	ldr	r3, [r11, #-0x10]
   13d94: e50b300c     	str	r3, [r11, #-0xc]
   13d98: e51b000c     	ldr	r0, [r11, #-0xc]
   13d9c: ebffe1ce     	bl	0xc4dc <strlen@plt>     @ imm = #-0x78c8
   13da0: e1a03000     	mov	r3, r0
   13da4: e50b3008     	str	r3, [r11, #-0x8]
   13da8: ea000007     	b	0x13dcc <trim_whitespace+0x4c> @ imm = #0x1c
   13dac: e51b3008     	ldr	r3, [r11, #-0x8]
   13db0: e2433001     	sub	r3, r3, #1
   13db4: e50b3008     	str	r3, [r11, #-0x8]
   13db8: e51b3008     	ldr	r3, [r11, #-0x8]
   13dbc: e51b200c     	ldr	r2, [r11, #-0xc]
   13dc0: e0823003     	add	r3, r2, r3
   13dc4: e3a02000     	mov	r2, #0
   13dc8: e5c32000     	strb	r2, [r3]
   13dcc: ebffe216     	bl	0xc62c <__ctype_b_loc@plt> @ imm = #-0x77a8
   13dd0: e1a03000     	mov	r3, r0
   13dd4: e5932000     	ldr	r2, [r3]
   13dd8: e51b3008     	ldr	r3, [r11, #-0x8]
   13ddc: e2433001     	sub	r3, r3, #1
   13de0: e51b100c     	ldr	r1, [r11, #-0xc]
   13de4: e0813003     	add	r3, r1, r3
   13de8: e5d33000     	ldrb	r3, [r3]
   13dec: e1a03083     	lsl	r3, r3, #1
   13df0: e0823003     	add	r3, r2, r3
   13df4: e1d330b0     	ldrh	r3, [r3]
   13df8: e2033a02     	and	r3, r3, #8192
   13dfc: e3530000     	cmp	r3, #0
   13e00: 1affffe9     	bne	0x13dac <trim_whitespace+0x2c> @ imm = #-0x5c
   13e04: ea000005     	b	0x13e20 <trim_whitespace+0xa0> @ imm = #0x14
   13e08: e51b300c     	ldr	r3, [r11, #-0xc]
   13e0c: e2833001     	add	r3, r3, #1
   13e10: e50b300c     	str	r3, [r11, #-0xc]
   13e14: e51b3008     	ldr	r3, [r11, #-0x8]
   13e18: e2433001     	sub	r3, r3, #1
   13e1c: e50b3008     	str	r3, [r11, #-0x8]
   13e20: e51b300c     	ldr	r3, [r11, #-0xc]
   13e24: e5d33000     	ldrb	r3, [r3]
   13e28: e3530000     	cmp	r3, #0
   13e2c: 0a00000a     	beq	0x13e5c <trim_whitespace+0xdc> @ imm = #0x28
   13e30: ebffe1fd     	bl	0xc62c <__ctype_b_loc@plt> @ imm = #-0x780c
   13e34: e1a03000     	mov	r3, r0
   13e38: e5932000     	ldr	r2, [r3]
   13e3c: e51b300c     	ldr	r3, [r11, #-0xc]
   13e40: e5d33000     	ldrb	r3, [r3]
   13e44: e1a03083     	lsl	r3, r3, #1
   13e48: e0823003     	add	r3, r2, r3
   13e4c: e1d330b0     	ldrh	r3, [r3]
   13e50: e2033a02     	and	r3, r3, #8192
   13e54: e3530000     	cmp	r3, #0
   13e58: 1affffea     	bne	0x13e08 <trim_whitespace+0x88> @ imm = #-0x58
   13e5c: e51b3008     	ldr	r3, [r11, #-0x8]
   13e60: e2833001     	add	r3, r3, #1
   13e64: e51b0010     	ldr	r0, [r11, #-0x10]
   13e68: e51b100c     	ldr	r1, [r11, #-0xc]
   13e6c: e1a02003     	mov	r2, r3
   13e70: ebffe21d     	bl	0xc6ec <memmove@plt>    @ imm = #-0x778c
   13e74: e24bd004     	sub	sp, r11, #4
   13e78: e8bd8800     	pop	{r11, pc}

