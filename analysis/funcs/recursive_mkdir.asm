00010e10 <recursive_mkdir>:
   10e10: e92d4800     	push	{r11, lr}
   10e14: e28db004     	add	r11, sp, #4
   10e18: e24dd018     	sub	sp, sp, #24
   10e1c: e50b0018     	str	r0, [r11, #-0x18]
   10e20: e50b101c     	str	r1, [r11, #-0x1c]
   10e24: e51b0018     	ldr	r0, [r11, #-0x18]
   10e28: ebffedab     	bl	0xc4dc <strlen@plt>     @ imm = #-0x4954
   10e2c: e1a03000     	mov	r3, r0
   10e30: e50b3010     	str	r3, [r11, #-0x10]
   10e34: e3a03000     	mov	r3, #0
   10e38: e50b3014     	str	r3, [r11, #-0x14]
   10e3c: ea00003b     	b	0x10f30 <recursive_mkdir+0x120> @ imm = #0xec
   10e40: e51b3014     	ldr	r3, [r11, #-0x14]
   10e44: e51b2018     	ldr	r2, [r11, #-0x18]
   10e48: e0823003     	add	r3, r2, r3
   10e4c: e5d33000     	ldrb	r3, [r3]
   10e50: e353002f     	cmp	r3, #47
   10e54: 1a000032     	bne	0x10f24 <recursive_mkdir+0x114> @ imm = #0xc8
   10e58: e51b3014     	ldr	r3, [r11, #-0x14]
   10e5c: e2833001     	add	r3, r3, #1
   10e60: e51b2018     	ldr	r2, [r11, #-0x18]
   10e64: e0823003     	add	r3, r2, r3
   10e68: e5d33000     	ldrb	r3, [r3]
   10e6c: e54b3005     	strb	r3, [r11, #-0x5]
   10e70: e51b3014     	ldr	r3, [r11, #-0x14]
   10e74: e2833001     	add	r3, r3, #1
   10e78: e51b2018     	ldr	r2, [r11, #-0x18]
   10e7c: e0823003     	add	r3, r2, r3
   10e80: e3a02000     	mov	r2, #0
   10e84: e5c32000     	strb	r2, [r3]
   10e88: e51b0018     	ldr	r0, [r11, #-0x18]
   10e8c: e51b101c     	ldr	r1, [r11, #-0x1c]
   10e90: ebffece3     	bl	0xc224 <mkdir@plt>      @ imm = #-0x4c74
   10e94: e1a03000     	mov	r3, r0
   10e98: e50b300c     	str	r3, [r11, #-0xc]
   10e9c: e51b0018     	ldr	r0, [r11, #-0x18]
   10ea0: e51b101c     	ldr	r1, [r11, #-0x1c]
   10ea4: ebffed4a     	bl	0xc3d4 <chmod@plt>      @ imm = #-0x4ad8
   10ea8: e51b3014     	ldr	r3, [r11, #-0x14]
   10eac: e2833001     	add	r3, r3, #1
   10eb0: e51b2018     	ldr	r2, [r11, #-0x18]
   10eb4: e0823003     	add	r3, r2, r3
   10eb8: e55b2005     	ldrb	r2, [r11, #-0x5]
   10ebc: e5c32000     	strb	r2, [r3]
   10ec0: e51b300c     	ldr	r3, [r11, #-0xc]
   10ec4: e3530000     	cmp	r3, #0
   10ec8: 0a000015     	beq	0x10f24 <recursive_mkdir+0x114> @ imm = #0x54
   10ecc: ebffee42     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x46f8
   10ed0: e1a03000     	mov	r3, r0
   10ed4: e5933000     	ldr	r3, [r3]
   10ed8: e3530011     	cmp	r3, #17
   10edc: 0a000010     	beq	0x10f24 <recursive_mkdir+0x114> @ imm = #0x40
   10ee0: ebffee3d     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x470c
   10ee4: e1a03000     	mov	r3, r0
   10ee8: e5933000     	ldr	r3, [r3]
   10eec: e3530015     	cmp	r3, #21
   10ef0: 0a00000b     	beq	0x10f24 <recursive_mkdir+0x114> @ imm = #0x2c
   10ef4: ebffee38     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x4720
   10ef8: e1a03000     	mov	r3, r0
   10efc: e5933000     	ldr	r3, [r3]
   10f00: e353000d     	cmp	r3, #13
   10f04: 0a000006     	beq	0x10f24 <recursive_mkdir+0x114> @ imm = #0x18
   10f08: ebffee33     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x4734
   10f0c: e1a03000     	mov	r3, r0
   10f10: e5933000     	ldr	r3, [r3]
   10f14: e353001e     	cmp	r3, #30
   10f18: 0a000001     	beq	0x10f24 <recursive_mkdir+0x114> @ imm = #0x4
   10f1c: e51b300c     	ldr	r3, [r11, #-0xc]
   10f20: ea00000f     	b	0x10f64 <recursive_mkdir+0x154> @ imm = #0x3c
   10f24: e51b3014     	ldr	r3, [r11, #-0x14]
   10f28: e2833001     	add	r3, r3, #1
   10f2c: e50b3014     	str	r3, [r11, #-0x14]
   10f30: e51b2014     	ldr	r2, [r11, #-0x14]
   10f34: e51b3010     	ldr	r3, [r11, #-0x10]
   10f38: e1520003     	cmp	r2, r3
   10f3c: baffffbf     	blt	0x10e40 <recursive_mkdir+0x30> @ imm = #-0x104
   10f40: e51b0018     	ldr	r0, [r11, #-0x18]
   10f44: e51b101c     	ldr	r1, [r11, #-0x1c]
   10f48: ebffecb5     	bl	0xc224 <mkdir@plt>      @ imm = #-0x4d2c
   10f4c: e1a03000     	mov	r3, r0
   10f50: e50b300c     	str	r3, [r11, #-0xc]
   10f54: e51b0018     	ldr	r0, [r11, #-0x18]
   10f58: e51b101c     	ldr	r1, [r11, #-0x1c]
   10f5c: ebffed1c     	bl	0xc3d4 <chmod@plt>      @ imm = #-0x4b90
   10f60: e51b300c     	ldr	r3, [r11, #-0xc]
   10f64: e1a00003     	mov	r0, r3
   10f68: e24bd004     	sub	sp, r11, #4
   10f6c: e8bd8800     	pop	{r11, pc}

