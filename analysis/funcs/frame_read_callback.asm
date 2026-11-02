00028440 <frame_read_callback>:
   28440: e92d4800     	push	{r11, lr}
   28444: e28db004     	add	r11, sp, #4
   28448: e24dd018     	sub	sp, sp, #24
   2844c: e50b0010     	str	r0, [r11, #-0x10]
   28450: e50b1014     	str	r1, [r11, #-0x14]
   28454: e50b2018     	str	r2, [r11, #-0x18]
   28458: e50b301c     	str	r3, [r11, #-0x1c]
   2845c: e51b301c     	ldr	r3, [r11, #-0x1c]
   28460: e50b3008     	str	r3, [r11, #-0x8]
   28464: e51b3008     	ldr	r3, [r11, #-0x8]
   28468: e593303c     	ldr	r3, [r3, #0x3c]
   2846c: e3530000     	cmp	r3, #0
   28470: 0a00000a     	beq	0x284a0 <frame_read_callback+0x60> @ imm = #0x28
   28474: e51b3008     	ldr	r3, [r11, #-0x8]
   28478: e5933038     	ldr	r3, [r3, #0x38]
   2847c: e3530000     	cmp	r3, #0
   28480: 0a000006     	beq	0x284a0 <frame_read_callback+0x60> @ imm = #0x18
   28484: e51b3008     	ldr	r3, [r11, #-0x8]
   28488: e5933164     	ldr	r3, [r3, #0x164]
   2848c: e1a00003     	mov	r0, r3
   28490: e51b1014     	ldr	r1, [r11, #-0x14]
   28494: e51b2018     	ldr	r2, [r11, #-0x18]
   28498: ebffcbd6     	bl	0x1b3f8 <dst_decoder_decode> @ imm = #-0xd0a8
   2849c: ea000003     	b	0x284b0 <frame_read_callback+0x70> @ imm = #0xc
   284a0: e51b0008     	ldr	r0, [r11, #-0x8]
   284a4: e51b1014     	ldr	r1, [r11, #-0x14]
   284a8: e51b2018     	ldr	r2, [r11, #-0x18]
   284ac: ebffff90     	bl	0x282f4 <write_block>   @ imm = #-0x1c0
   284b0: e24bd004     	sub	sp, r11, #4
   284b4: e8bd8800     	pop	{r11, pc}

