00013c9c <trim_chars>:
   13c9c: e92d4800     	push	{r11, lr}
   13ca0: e28db004     	add	r11, sp, #4
   13ca4: e24dd018     	sub	sp, sp, #24
   13ca8: e50b0018     	str	r0, [r11, #-0x18]
   13cac: e50b101c     	str	r1, [r11, #-0x1c]
   13cb0: e51b0018     	ldr	r0, [r11, #-0x18]
   13cb4: ebffe208     	bl	0xc4dc <strlen@plt>     @ imm = #-0x77e0
   13cb8: e1a03000     	mov	r3, r0
   13cbc: e50b300c     	str	r3, [r11, #-0xc]
   13cc0: e3a03000     	mov	r3, #0
   13cc4: e50b3008     	str	r3, [r11, #-0x8]
   13cc8: ea000024     	b	0x13d60 <trim_chars+0xc4> @ imm = #0x90
   13ccc: e3a03000     	mov	r3, #0
   13cd0: e50b3010     	str	r3, [r11, #-0x10]
   13cd4: e3a03000     	mov	r3, #0
   13cd8: e50b3014     	str	r3, [r11, #-0x14]
   13cdc: ea000017     	b	0x13d40 <trim_chars+0xa4> @ imm = #0x5c
   13ce0: e51b3014     	ldr	r3, [r11, #-0x14]
   13ce4: e51b2018     	ldr	r2, [r11, #-0x18]
   13ce8: e0823003     	add	r3, r2, r3
   13cec: e5d32000     	ldrb	r2, [r3]
   13cf0: e51b101c     	ldr	r1, [r11, #-0x1c]
   13cf4: e51b3008     	ldr	r3, [r11, #-0x8]
   13cf8: e0813003     	add	r3, r1, r3
   13cfc: e5d33000     	ldrb	r3, [r3]
   13d00: e1520003     	cmp	r2, r3
   13d04: 0a00000a     	beq	0x13d34 <trim_chars+0x98> @ imm = #0x28
   13d08: e51b3010     	ldr	r3, [r11, #-0x10]
   13d0c: e51b2018     	ldr	r2, [r11, #-0x18]
   13d10: e0823003     	add	r3, r2, r3
   13d14: e51b2014     	ldr	r2, [r11, #-0x14]
   13d18: e51b1018     	ldr	r1, [r11, #-0x18]
   13d1c: e0812002     	add	r2, r1, r2
   13d20: e5d22000     	ldrb	r2, [r2]
   13d24: e5c32000     	strb	r2, [r3]
   13d28: e51b3010     	ldr	r3, [r11, #-0x10]
   13d2c: e2833001     	add	r3, r3, #1
   13d30: e50b3010     	str	r3, [r11, #-0x10]
   13d34: e51b3014     	ldr	r3, [r11, #-0x14]
   13d38: e2833001     	add	r3, r3, #1
   13d3c: e50b3014     	str	r3, [r11, #-0x14]
   13d40: e51b300c     	ldr	r3, [r11, #-0xc]
   13d44: e2832001     	add	r2, r3, #1
   13d48: e51b3014     	ldr	r3, [r11, #-0x14]
   13d4c: e1520003     	cmp	r2, r3
   13d50: caffffe2     	bgt	0x13ce0 <trim_chars+0x44> @ imm = #-0x78
   13d54: e51b3008     	ldr	r3, [r11, #-0x8]
   13d58: e2833001     	add	r3, r3, #1
   13d5c: e50b3008     	str	r3, [r11, #-0x8]
   13d60: e51b001c     	ldr	r0, [r11, #-0x1c]
   13d64: ebffe1dc     	bl	0xc4dc <strlen@plt>     @ imm = #-0x7890
   13d68: e1a02000     	mov	r2, r0
   13d6c: e51b3008     	ldr	r3, [r11, #-0x8]
   13d70: e1520003     	cmp	r2, r3
   13d74: 8affffd4     	bhi	0x13ccc <trim_chars+0x30> @ imm = #-0xb0
   13d78: e24bd004     	sub	sp, r11, #4
   13d7c: e8bd8800     	pop	{r11, pc}

