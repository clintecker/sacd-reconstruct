0001cb64 <id3_frame_clear_data>:
   1cb64: e92d4800     	push	{r11, lr}
   1cb68: e28db004     	add	r11, sp, #4
   1cb6c: e24dd008     	sub	sp, sp, #8
   1cb70: e50b0008     	str	r0, [r11, #-0x8]
   1cb74: e51b3008     	ldr	r3, [r11, #-0x8]
   1cb78: e5933018     	ldr	r3, [r3, #0x18]
   1cb7c: e3530000     	cmp	r3, #0
   1cb80: 0a000003     	beq	0x1cb94 <id3_frame_clear_data+0x30> @ imm = #0xc
   1cb84: e51b3008     	ldr	r3, [r11, #-0x8]
   1cb88: e5933018     	ldr	r3, [r3, #0x18]
   1cb8c: e1a00003     	mov	r0, r3
   1cb90: ebffbe21     	bl	0xc41c <free@plt>       @ imm = #-0x1077c
   1cb94: e51b3008     	ldr	r3, [r11, #-0x8]
   1cb98: e5933020     	ldr	r3, [r3, #0x20]
   1cb9c: e3530000     	cmp	r3, #0
   1cba0: 0a000003     	beq	0x1cbb4 <id3_frame_clear_data+0x50> @ imm = #0xc
   1cba4: e51b3008     	ldr	r3, [r11, #-0x8]
   1cba8: e5933020     	ldr	r3, [r3, #0x20]
   1cbac: e1a00003     	mov	r0, r3
   1cbb0: ebffbe19     	bl	0xc41c <free@plt>       @ imm = #-0x1079c
   1cbb4: e51b3008     	ldr	r3, [r11, #-0x8]
   1cbb8: e3a02000     	mov	r2, #0
   1cbbc: e5832018     	str	r2, [r3, #0x18]
   1cbc0: e51b3008     	ldr	r3, [r11, #-0x8]
   1cbc4: e3a02000     	mov	r2, #0
   1cbc8: e583201c     	str	r2, [r3, #0x1c]
   1cbcc: e51b3008     	ldr	r3, [r11, #-0x8]
   1cbd0: e3a02000     	mov	r2, #0
   1cbd4: e5832010     	str	r2, [r3, #0x10]
   1cbd8: e51b3008     	ldr	r3, [r11, #-0x8]
   1cbdc: e3a02000     	mov	r2, #0
   1cbe0: e5832014     	str	r2, [r3, #0x14]
   1cbe4: e51b3008     	ldr	r3, [r11, #-0x8]
   1cbe8: e3a02000     	mov	r2, #0
   1cbec: e5832020     	str	r2, [r3, #0x20]
   1cbf0: e51b3008     	ldr	r3, [r11, #-0x8]
   1cbf4: e3a02000     	mov	r2, #0
   1cbf8: e5832024     	str	r2, [r3, #0x24]
   1cbfc: e24bd004     	sub	sp, r11, #4
   1cc00: e8bd8800     	pop	{r11, pc}

