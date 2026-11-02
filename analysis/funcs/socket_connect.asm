00012c34 <socket_connect>:
   12c34: e92d4800     	push	{r11, lr}
   12c38: e28db004     	add	r11, sp, #4
   12c3c: e24dd018     	sub	sp, sp, #24
   12c40: e50b0010     	str	r0, [r11, #-0x10]
   12c44: e50b1014     	str	r1, [r11, #-0x14]
   12c48: e50b2018     	str	r2, [r11, #-0x18]
   12c4c: e50b301c     	str	r3, [r11, #-0x1c]
   12c50: e51b3010     	ldr	r3, [r11, #-0x10]
   12c54: e5933000     	ldr	r3, [r3]
   12c58: e3730001     	cmn	r3, #1
   12c5c: 1a000001     	bne	0x12c68 <socket_connect+0x34> @ imm = #0x4
   12c60: e3e03001     	mvn	r3, #1
   12c64: ea000043     	b	0x12d78 <socket_connect+0x144> @ imm = #0x10c
   12c68: e51b3010     	ldr	r3, [r11, #-0x10]
   12c6c: e5932000     	ldr	r2, [r3]
   12c70: e51b1014     	ldr	r1, [r11, #-0x14]
   12c74: e3a03000     	mov	r3, #0
   12c78: e1a03001     	mov	r3, r1
   12c7c: e1a00002     	mov	r0, r2
   12c80: e1a01003     	mov	r1, r3
   12c84: e51b2018     	ldr	r2, [r11, #-0x18]
   12c88: ebffe571     	bl	0xc254 <connect@plt>    @ imm = #-0x6a3c
   12c8c: e1a03000     	mov	r3, r0
   12c90: e3530000     	cmp	r3, #0
   12c94: 1a000001     	bne	0x12ca0 <socket_connect+0x6c> @ imm = #0x4
   12c98: e3a03000     	mov	r3, #0
   12c9c: ea000035     	b	0x12d78 <socket_connect+0x144> @ imm = #0xd4
   12ca0: ebffe6cd     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x64cc
   12ca4: e1a03000     	mov	r3, r0
   12ca8: e5933000     	ldr	r3, [r3]
   12cac: e50b3008     	str	r3, [r11, #-0x8]
   12cb0: e51b3008     	ldr	r3, [r11, #-0x8]
   12cb4: e3530004     	cmp	r3, #4
   12cb8: 0affffea     	beq	0x12c68 <socket_connect+0x34> @ imm = #-0x58
   12cbc: e51b3008     	ldr	r3, [r11, #-0x8]
   12cc0: e3530073     	cmp	r3, #115
   12cc4: 0a000004     	beq	0x12cdc <socket_connect+0xa8> @ imm = #0x10
   12cc8: e51b3008     	ldr	r3, [r11, #-0x8]
   12ccc: e353000b     	cmp	r3, #11
   12cd0: 0a000001     	beq	0x12cdc <socket_connect+0xa8> @ imm = #0x4
   12cd4: e51b3008     	ldr	r3, [r11, #-0x8]
   12cd8: ea000026     	b	0x12d78 <socket_connect+0x144> @ imm = #0x98
   12cdc: e51b301c     	ldr	r3, [r11, #-0x1c]
   12ce0: e1c320d0     	ldrd	r2, r3, [r3]
   12ce4: e1a00002     	mov	r0, r2
   12ce8: e1a01003     	mov	r1, r3
   12cec: e3a02000     	mov	r2, #0
   12cf0: e3a03000     	mov	r3, #0
   12cf4: eb0076fd     	bl	0x308f0 <__aeabi_dcmpeq> @ imm = #0x1dbf4
   12cf8: e1a03000     	mov	r3, r0
   12cfc: e3530000     	cmp	r3, #0
   12d00: 0a000001     	beq	0x12d0c <socket_connect+0xd8> @ imm = #0x4
   12d04: e3e03000     	mvn	r3, #0
   12d08: ea00001a     	b	0x12d78 <socket_connect+0x144> @ imm = #0x68
   12d0c: e51b0010     	ldr	r0, [r11, #-0x10]
   12d10: e3a01003     	mov	r1, #3
   12d14: e51b201c     	ldr	r2, [r11, #-0x1c]
   12d18: ebfffe14     	bl	0x12570 <socket_waitfd> @ imm = #-0x7b0
   12d1c: e1a03000     	mov	r3, r0
   12d20: e50b3008     	str	r3, [r11, #-0x8]
   12d24: e51b3008     	ldr	r3, [r11, #-0x8]
   12d28: e3730002     	cmn	r3, #2
   12d2c: 1a000010     	bne	0x12d74 <socket_connect+0x140> @ imm = #0x40
   12d30: e51b3010     	ldr	r3, [r11, #-0x10]
   12d34: e5932000     	ldr	r2, [r3]
   12d38: e24b3008     	sub	r3, r11, #8
   12d3c: e1a00002     	mov	r0, r2
   12d40: e1a01003     	mov	r1, r3
   12d44: e3a02000     	mov	r2, #0
   12d48: e3a03000     	mov	r3, #0
   12d4c: ebffe56a     	bl	0xc2fc <recv@plt>       @ imm = #-0x6a58
   12d50: e1a03000     	mov	r3, r0
   12d54: e3530000     	cmp	r3, #0
   12d58: 1a000001     	bne	0x12d64 <socket_connect+0x130> @ imm = #0x4
   12d5c: e3a03000     	mov	r3, #0
   12d60: ea000004     	b	0x12d78 <socket_connect+0x144> @ imm = #0x10
   12d64: ebffe69c     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x6590
   12d68: e1a03000     	mov	r3, r0
   12d6c: e5933000     	ldr	r3, [r3]
   12d70: ea000000     	b	0x12d78 <socket_connect+0x144> @ imm = #0x0
   12d74: e51b3008     	ldr	r3, [r11, #-0x8]
   12d78: e1a00003     	mov	r0, r3
   12d7c: e24bd004     	sub	sp, r11, #4
   12d80: e8bd8800     	pop	{r11, pc}

