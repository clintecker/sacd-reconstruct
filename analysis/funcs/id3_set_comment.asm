0001def0 <id3_set_comment>:
   1def0: e92d4810     	push	{r4, r11, lr}
   1def4: e28db008     	add	r11, sp, #8
   1def8: e24dd014     	sub	sp, sp, #20
   1defc: e50b0010     	str	r0, [r11, #-0x10]
   1df00: e50b1014     	str	r1, [r11, #-0x14]
   1df04: e50b2018     	str	r2, [r11, #-0x18]
   1df08: e51b3010     	ldr	r3, [r11, #-0x10]
   1df0c: e5933004     	ldr	r3, [r3, #0x4]
   1df10: e5d33004     	ldrb	r3, [r3, #0x4]
   1df14: e3530043     	cmp	r3, #67
   1df18: 0a000001     	beq	0x1df24 <id3_set_comment+0x34> @ imm = #0x4
   1df1c: e3e03000     	mvn	r3, #0
   1df20: ea000043     	b	0x1e034 <id3_set_comment+0x144> @ imm = #0x10c
   1df24: e51b0010     	ldr	r0, [r11, #-0x10]
   1df28: ebfffb0d     	bl	0x1cb64 <id3_frame_clear_data> @ imm = #-0x13cc
   1df2c: e51b0014     	ldr	r0, [r11, #-0x14]
   1df30: ebffb969     	bl	0xc4dc <strlen@plt>     @ imm = #-0x11a5c
   1df34: e1a04000     	mov	r4, r0
   1df38: e51b0018     	ldr	r0, [r11, #-0x18]
   1df3c: ebffb966     	bl	0xc4dc <strlen@plt>     @ imm = #-0x11a68
   1df40: e1a03000     	mov	r3, r0
   1df44: e0843003     	add	r3, r4, r3
   1df48: e2832002     	add	r2, r3, #2
   1df4c: e51b3010     	ldr	r3, [r11, #-0x10]
   1df50: e583201c     	str	r2, [r3, #0x1c]
   1df54: e51b3010     	ldr	r3, [r11, #-0x10]
   1df58: e593301c     	ldr	r3, [r3, #0x1c]
   1df5c: e2833001     	add	r3, r3, #1
   1df60: e1a00003     	mov	r0, r3
   1df64: ebffb9bf     	bl	0xc668 <malloc@plt>     @ imm = #-0x11904
   1df68: e1a03000     	mov	r3, r0
   1df6c: e1a02003     	mov	r2, r3
   1df70: e51b3010     	ldr	r3, [r11, #-0x10]
   1df74: e5832018     	str	r2, [r3, #0x18]
   1df78: e51b3010     	ldr	r3, [r11, #-0x10]
   1df7c: e5933018     	ldr	r3, [r3, #0x18]
   1df80: e3a02000     	mov	r2, #0
   1df84: e5c32000     	strb	r2, [r3]
   1df88: e51b3010     	ldr	r3, [r11, #-0x10]
   1df8c: e5933018     	ldr	r3, [r3, #0x18]
   1df90: e2834001     	add	r4, r3, #1
   1df94: e51b0014     	ldr	r0, [r11, #-0x14]
   1df98: ebffb94f     	bl	0xc4dc <strlen@plt>     @ imm = #-0x11ac4
   1df9c: e1a03000     	mov	r3, r0
   1dfa0: e2833001     	add	r3, r3, #1
   1dfa4: e1a00004     	mov	r0, r4
   1dfa8: e51b1014     	ldr	r1, [r11, #-0x14]
   1dfac: e1a02003     	mov	r2, r3
   1dfb0: ebffb955     	bl	0xc50c <memcpy@plt>     @ imm = #-0x11aac
   1dfb4: e51b3010     	ldr	r3, [r11, #-0x10]
   1dfb8: e5934018     	ldr	r4, [r3, #0x18]
   1dfbc: e51b0014     	ldr	r0, [r11, #-0x14]
   1dfc0: ebffb945     	bl	0xc4dc <strlen@plt>     @ imm = #-0x11aec
   1dfc4: e1a03000     	mov	r3, r0
   1dfc8: e2833002     	add	r3, r3, #2
   1dfcc: e0844003     	add	r4, r4, r3
   1dfd0: e51b0018     	ldr	r0, [r11, #-0x18]
   1dfd4: ebffb940     	bl	0xc4dc <strlen@plt>     @ imm = #-0x11b00
   1dfd8: e1a03000     	mov	r3, r0
   1dfdc: e2833001     	add	r3, r3, #1
   1dfe0: e1a00004     	mov	r0, r4
   1dfe4: e51b1018     	ldr	r1, [r11, #-0x18]
   1dfe8: e1a02003     	mov	r2, r3
   1dfec: ebffb946     	bl	0xc50c <memcpy@plt>     @ imm = #-0x11ae8
   1dff0: e51b3010     	ldr	r3, [r11, #-0x10]
   1dff4: e3a02001     	mov	r2, #1
   1dff8: e5c3200e     	strb	r2, [r3, #0xe]
   1dffc: e51b3010     	ldr	r3, [r11, #-0x10]
   1e000: e5933000     	ldr	r3, [r3]
   1e004: e3a02001     	mov	r2, #1
   1e008: e583200c     	str	r2, [r3, #0xc]
   1e00c: e51b3010     	ldr	r3, [r11, #-0x10]
   1e010: e5932018     	ldr	r2, [r3, #0x18]
   1e014: e51b3010     	ldr	r3, [r11, #-0x10]
   1e018: e5832010     	str	r2, [r3, #0x10]
   1e01c: e51b3010     	ldr	r3, [r11, #-0x10]
   1e020: e593301c     	ldr	r3, [r3, #0x1c]
   1e024: e1a02003     	mov	r2, r3
   1e028: e51b3010     	ldr	r3, [r11, #-0x10]
   1e02c: e5832014     	str	r2, [r3, #0x14]
   1e030: e3a03000     	mov	r3, #0
   1e034: e1a00003     	mov	r0, r3
   1e038: e24bd008     	sub	sp, r11, #8
   1e03c: e8bd8810     	pop	{r4, r11, pc}

