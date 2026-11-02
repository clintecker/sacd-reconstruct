00012d84 <socket_accept>:
   12d84: e92d4800     	push	{r11, lr}
   12d88: e28db004     	add	r11, sp, #4
   12d8c: e24dd028     	sub	sp, sp, #40
   12d90: e50b0020     	str	r0, [r11, #-0x20]
   12d94: e50b1024     	str	r1, [r11, #-0x24]
   12d98: e50b2028     	str	r2, [r11, #-0x28]
   12d9c: e50b302c     	str	r3, [r11, #-0x2c]
   12da0: e3a03010     	mov	r3, #16
   12da4: e50b301c     	str	r3, [r11, #-0x1c]
   12da8: e51b3020     	ldr	r3, [r11, #-0x20]
   12dac: e5933000     	ldr	r3, [r3]
   12db0: e3730001     	cmn	r3, #1
   12db4: 1a000001     	bne	0x12dc0 <socket_accept+0x3c> @ imm = #0x4
   12db8: e3e03001     	mvn	r3, #1
   12dbc: ea000038     	b	0x12ea4 <socket_accept+0x120> @ imm = #0xe0
   12dc0: e51b3028     	ldr	r3, [r11, #-0x28]
   12dc4: e3530000     	cmp	r3, #0
   12dc8: 1a000001     	bne	0x12dd4 <socket_accept+0x50> @ imm = #0x4
   12dcc: e24b3018     	sub	r3, r11, #24
   12dd0: e50b3028     	str	r3, [r11, #-0x28]
   12dd4: e51b302c     	ldr	r3, [r11, #-0x2c]
   12dd8: e3530000     	cmp	r3, #0
   12ddc: 1a000003     	bne	0x12df0 <socket_accept+0x6c> @ imm = #0xc
   12de0: e24b301c     	sub	r3, r11, #28
   12de4: e50b302c     	str	r3, [r11, #-0x2c]
   12de8: ea000000     	b	0x12df0 <socket_accept+0x6c> @ imm = #0x0
   12dec: e1a00000     	mov	r0, r0
   12df0: e51b3020     	ldr	r3, [r11, #-0x20]
   12df4: e5932000     	ldr	r2, [r3]
   12df8: e51b1028     	ldr	r1, [r11, #-0x28]
   12dfc: e3a03000     	mov	r3, #0
   12e00: e1a03001     	mov	r3, r1
   12e04: e1a00002     	mov	r0, r2
   12e08: e1a01003     	mov	r1, r3
   12e0c: e51b202c     	ldr	r2, [r11, #-0x2c]
   12e10: ebffe596     	bl	0xc470 <accept@plt>     @ imm = #-0x69a8
   12e14: e1a02000     	mov	r2, r0
   12e18: e51b3024     	ldr	r3, [r11, #-0x24]
   12e1c: e5832000     	str	r2, [r3]
   12e20: e51b3024     	ldr	r3, [r11, #-0x24]
   12e24: e5933000     	ldr	r3, [r3]
   12e28: e3730001     	cmn	r3, #1
   12e2c: 0a000001     	beq	0x12e38 <socket_accept+0xb4> @ imm = #0x4
   12e30: e3a03000     	mov	r3, #0
   12e34: ea00001a     	b	0x12ea4 <socket_accept+0x120> @ imm = #0x68
   12e38: ebffe667     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x6664
   12e3c: e1a03000     	mov	r3, r0
   12e40: e5933000     	ldr	r3, [r3]
   12e44: e50b3008     	str	r3, [r11, #-0x8]
   12e48: e51b3008     	ldr	r3, [r11, #-0x8]
   12e4c: e3530004     	cmp	r3, #4
   12e50: 1a000001     	bne	0x12e5c <socket_accept+0xd8> @ imm = #0x4
   12e54: e1a00000     	mov	r0, r0
   12e58: eaffffe4     	b	0x12df0 <socket_accept+0x6c> @ imm = #-0x70
   12e5c: e51b3008     	ldr	r3, [r11, #-0x8]
   12e60: e353000b     	cmp	r3, #11
   12e64: 0a000004     	beq	0x12e7c <socket_accept+0xf8> @ imm = #0x10
   12e68: e51b3008     	ldr	r3, [r11, #-0x8]
   12e6c: e3530067     	cmp	r3, #103
   12e70: 0a000001     	beq	0x12e7c <socket_accept+0xf8> @ imm = #0x4
   12e74: e51b3008     	ldr	r3, [r11, #-0x8]
   12e78: ea000009     	b	0x12ea4 <socket_accept+0x120> @ imm = #0x24
   12e7c: e51b0020     	ldr	r0, [r11, #-0x20]
   12e80: e3a01001     	mov	r1, #1
   12e84: e59b2004     	ldr	r2, [r11, #0x4]
   12e88: ebfffdb8     	bl	0x12570 <socket_waitfd> @ imm = #-0x920
   12e8c: e1a03000     	mov	r3, r0
   12e90: e50b3008     	str	r3, [r11, #-0x8]
   12e94: e51b3008     	ldr	r3, [r11, #-0x8]
   12e98: e3530000     	cmp	r3, #0
   12e9c: 0affffd2     	beq	0x12dec <socket_accept+0x68> @ imm = #-0xb8
   12ea0: e51b3008     	ldr	r3, [r11, #-0x8]
   12ea4: e1a00003     	mov	r0, r3
   12ea8: e24bd004     	sub	sp, r11, #4
   12eac: e8bd8800     	pop	{r11, pc}

