00010f70 <recursive_parent_mkdir>:
   10f70: e92d4800     	push	{r11, lr}
   10f74: e28db004     	add	r11, sp, #4
   10f78: e24dd018     	sub	sp, sp, #24
   10f7c: e50b0018     	str	r0, [r11, #-0x18]
   10f80: e50b101c     	str	r1, [r11, #-0x1c]
   10f84: e3a03000     	mov	r3, #0
   10f88: e50b300c     	str	r3, [r11, #-0xc]
   10f8c: e3a03001     	mov	r3, #1
   10f90: e50b3008     	str	r3, [r11, #-0x8]
   10f94: e51b0018     	ldr	r0, [r11, #-0x18]
   10f98: ebffed4f     	bl	0xc4dc <strlen@plt>     @ imm = #-0x4ac4
   10f9c: e1a03000     	mov	r3, r0
   10fa0: e2433001     	sub	r3, r3, #1
   10fa4: e50b3010     	str	r3, [r11, #-0x10]
   10fa8: ea000022     	b	0x11038 <recursive_parent_mkdir+0xc8> @ imm = #0x88
   10fac: e51b3010     	ldr	r3, [r11, #-0x10]
   10fb0: e51b2018     	ldr	r2, [r11, #-0x18]
   10fb4: e0823003     	add	r3, r2, r3
   10fb8: e5d33000     	ldrb	r3, [r3]
   10fbc: e353002f     	cmp	r3, #47
   10fc0: 0a000001     	beq	0x10fcc <recursive_parent_mkdir+0x5c> @ imm = #0x4
   10fc4: e3a03001     	mov	r3, #1
   10fc8: e50b300c     	str	r3, [r11, #-0xc]
   10fcc: e51b3010     	ldr	r3, [r11, #-0x10]
   10fd0: e51b2018     	ldr	r2, [r11, #-0x18]
   10fd4: e0823003     	add	r3, r2, r3
   10fd8: e5d33000     	ldrb	r3, [r3]
   10fdc: e353002f     	cmp	r3, #47
   10fe0: 1a000011     	bne	0x1102c <recursive_parent_mkdir+0xbc> @ imm = #0x44
   10fe4: e51b300c     	ldr	r3, [r11, #-0xc]
   10fe8: e3530000     	cmp	r3, #0
   10fec: 0a00000e     	beq	0x1102c <recursive_parent_mkdir+0xbc> @ imm = #0x38
   10ff0: e51b3010     	ldr	r3, [r11, #-0x10]
   10ff4: e51b2018     	ldr	r2, [r11, #-0x18]
   10ff8: e0823003     	add	r3, r2, r3
   10ffc: e3a02000     	mov	r2, #0
   11000: e5c32000     	strb	r2, [r3]
   11004: e51b0018     	ldr	r0, [r11, #-0x18]
   11008: e51b101c     	ldr	r1, [r11, #-0x1c]
   1100c: ebffec84     	bl	0xc224 <mkdir@plt>      @ imm = #-0x4df0
   11010: e1a03000     	mov	r3, r0
   11014: e50b3008     	str	r3, [r11, #-0x8]
   11018: e51b3010     	ldr	r3, [r11, #-0x10]
   1101c: e51b2018     	ldr	r2, [r11, #-0x18]
   11020: e0823003     	add	r3, r2, r3
   11024: e3a0202f     	mov	r2, #47
   11028: e5c32000     	strb	r2, [r3]
   1102c: e51b3010     	ldr	r3, [r11, #-0x10]
   11030: e2433001     	sub	r3, r3, #1
   11034: e50b3010     	str	r3, [r11, #-0x10]
   11038: e51b3010     	ldr	r3, [r11, #-0x10]
   1103c: e3530000     	cmp	r3, #0
   11040: aaffffd9     	bge	0x10fac <recursive_parent_mkdir+0x3c> @ imm = #-0x9c
   11044: e51b3008     	ldr	r3, [r11, #-0x8]
   11048: e1a00003     	mov	r0, r3
   1104c: e24bd004     	sub	sp, r11, #4
   11050: e8bd8800     	pop	{r11, pc}

