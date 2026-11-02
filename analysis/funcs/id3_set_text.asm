0001da60 <id3_set_text>:
   1da60: e92d4800     	push	{r11, lr}
   1da64: e28db004     	add	r11, sp, #4
   1da68: e24dd008     	sub	sp, sp, #8
   1da6c: e50b0008     	str	r0, [r11, #-0x8]
   1da70: e50b100c     	str	r1, [r11, #-0xc]
   1da74: e51b3008     	ldr	r3, [r11, #-0x8]
   1da78: e5933004     	ldr	r3, [r3, #0x4]
   1da7c: e5d33004     	ldrb	r3, [r3, #0x4]
   1da80: e3530054     	cmp	r3, #84
   1da84: 0a000001     	beq	0x1da90 <id3_set_text+0x30> @ imm = #0x4
   1da88: e3e03000     	mvn	r3, #0
   1da8c: ea00002e     	b	0x1db4c <id3_set_text+0xec> @ imm = #0xb8
   1da90: e51b0008     	ldr	r0, [r11, #-0x8]
   1da94: ebfffc32     	bl	0x1cb64 <id3_frame_clear_data> @ imm = #-0xf38
   1da98: e51b000c     	ldr	r0, [r11, #-0xc]
   1da9c: ebffba8e     	bl	0xc4dc <strlen@plt>     @ imm = #-0x115c8
   1daa0: e1a03000     	mov	r3, r0
   1daa4: e2832001     	add	r2, r3, #1
   1daa8: e51b3008     	ldr	r3, [r11, #-0x8]
   1daac: e583201c     	str	r2, [r3, #0x1c]
   1dab0: e51b3008     	ldr	r3, [r11, #-0x8]
   1dab4: e593301c     	ldr	r3, [r3, #0x1c]
   1dab8: e2833001     	add	r3, r3, #1
   1dabc: e1a00003     	mov	r0, r3
   1dac0: ebffbae8     	bl	0xc668 <malloc@plt>     @ imm = #-0x11460
   1dac4: e1a03000     	mov	r3, r0
   1dac8: e1a02003     	mov	r2, r3
   1dacc: e51b3008     	ldr	r3, [r11, #-0x8]
   1dad0: e5832018     	str	r2, [r3, #0x18]
   1dad4: e51b3008     	ldr	r3, [r11, #-0x8]
   1dad8: e5933018     	ldr	r3, [r3, #0x18]
   1dadc: e3a02000     	mov	r2, #0
   1dae0: e5c32000     	strb	r2, [r3]
   1dae4: e51b3008     	ldr	r3, [r11, #-0x8]
   1dae8: e5933018     	ldr	r3, [r3, #0x18]
   1daec: e2832001     	add	r2, r3, #1
   1daf0: e51b3008     	ldr	r3, [r11, #-0x8]
   1daf4: e593301c     	ldr	r3, [r3, #0x1c]
   1daf8: e1a00002     	mov	r0, r2
   1dafc: e51b100c     	ldr	r1, [r11, #-0xc]
   1db00: e1a02003     	mov	r2, r3
   1db04: ebffba80     	bl	0xc50c <memcpy@plt>     @ imm = #-0x11600
   1db08: e51b3008     	ldr	r3, [r11, #-0x8]
   1db0c: e3a02001     	mov	r2, #1
   1db10: e5c3200e     	strb	r2, [r3, #0xe]
   1db14: e51b3008     	ldr	r3, [r11, #-0x8]
   1db18: e5933000     	ldr	r3, [r3]
   1db1c: e3a02001     	mov	r2, #1
   1db20: e583200c     	str	r2, [r3, #0xc]
   1db24: e51b3008     	ldr	r3, [r11, #-0x8]
   1db28: e5932018     	ldr	r2, [r3, #0x18]
   1db2c: e51b3008     	ldr	r3, [r11, #-0x8]
   1db30: e5832010     	str	r2, [r3, #0x10]
   1db34: e51b3008     	ldr	r3, [r11, #-0x8]
   1db38: e593301c     	ldr	r3, [r3, #0x1c]
   1db3c: e1a02003     	mov	r2, r3
   1db40: e51b3008     	ldr	r3, [r11, #-0x8]
   1db44: e5832014     	str	r2, [r3, #0x14]
   1db48: e3a03000     	mov	r3, #0
   1db4c: e1a00003     	mov	r0, r3
   1db50: e24bd004     	sub	sp, r11, #4
   1db54: e8bd8800     	pop	{r11, pc}

