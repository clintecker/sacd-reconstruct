00013c20 <replace_double_space_with_single>:
   13c20: e92d4800     	push	{r11, lr}
   13c24: e28db004     	add	r11, sp, #4
   13c28: e24dd010     	sub	sp, sp, #16
   13c2c: e50b0010     	str	r0, [r11, #-0x10]
   13c30: e51b0010     	ldr	r0, [r11, #-0x10]
   13c34: e59f1058     	ldr	r1, [pc, #0x58]         @ 0x13c94 <replace_double_space_with_single+0x74>
   13c38: e59f2058     	ldr	r2, [pc, #0x58]         @ 0x13c98 <replace_double_space_with_single+0x78>
   13c3c: ebffff94     	bl	0x13a94 <str_replace>   @ imm = #-0x1b0
   13c40: e1a03000     	mov	r3, r0
   13c44: e50b3008     	str	r3, [r11, #-0x8]
   13c48: e51b3008     	ldr	r3, [r11, #-0x8]
   13c4c: e3530000     	cmp	r3, #0
   13c50: 0a000005     	beq	0x13c6c <replace_double_space_with_single+0x4c> @ imm = #0x14
   13c54: e51b3008     	ldr	r3, [r11, #-0x8]
   13c58: e51b0010     	ldr	r0, [r11, #-0x10]
   13c5c: e1a01003     	mov	r1, r3
   13c60: ebffe235     	bl	0xc53c <strcpy@plt>     @ imm = #-0x772c
   13c64: e51b0008     	ldr	r0, [r11, #-0x8]
   13c68: ebffe1eb     	bl	0xc41c <free@plt>       @ imm = #-0x7854
   13c6c: e51b0010     	ldr	r0, [r11, #-0x10]
   13c70: e59f101c     	ldr	r1, [pc, #0x1c]         @ 0x13c94 <replace_double_space_with_single+0x74>
   13c74: ebffe254     	bl	0xc5cc <strstr@plt>     @ imm = #-0x76b0
   13c78: e1a03000     	mov	r3, r0
   13c7c: e50b300c     	str	r3, [r11, #-0xc]
   13c80: e51b300c     	ldr	r3, [r11, #-0xc]
   13c84: e3530000     	cmp	r3, #0
   13c88: 1affffe8     	bne	0x13c30 <replace_double_space_with_single+0x10> @ imm = #-0x60
   13c8c: e24bd004     	sub	sp, r11, #4
   13c90: e8bd8800     	pop	{r11, pc}
   13c94: e4 28 03 00  	.word	0x000328e4
   13c98: e8 28 03 00  	.word	0x000328e8

