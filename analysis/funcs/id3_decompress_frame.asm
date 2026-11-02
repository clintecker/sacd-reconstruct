0001c780 <id3_decompress_frame>:
   1c780: e92d4800     	push	{r11, lr}
   1c784: e28db004     	add	r11, sp, #4
   1c788: e24dd008     	sub	sp, sp, #8
   1c78c: e50b0008     	str	r0, [r11, #-0x8]
   1c790: e51b3008     	ldr	r3, [r11, #-0x8]
   1c794: e5933008     	ldr	r3, [r3, #0x8]
   1c798: e2033080     	and	r3, r3, #128
   1c79c: e3530000     	cmp	r3, #0
   1c7a0: 1a000001     	bne	0x1c7ac <id3_decompress_frame+0x2c> @ imm = #0x4
   1c7a4: e3a03000     	mov	r3, #0
   1c7a8: ea000008     	b	0x1c7d0 <id3_decompress_frame+0x50> @ imm = #0x20
   1c7ac: e51b3008     	ldr	r3, [r11, #-0x8]
   1c7b0: e5933020     	ldr	r3, [r3, #0x20]
   1c7b4: e3530000     	cmp	r3, #0
   1c7b8: 0a000001     	beq	0x1c7c4 <id3_decompress_frame+0x44> @ imm = #0x4
   1c7bc: e3a03000     	mov	r3, #0
   1c7c0: ea000002     	b	0x1c7d0 <id3_decompress_frame+0x50> @ imm = #0x8
   1c7c4: e51b0008     	ldr	r0, [r11, #-0x8]
   1c7c8: ebffffe3     	bl	0x1c75c <decompress_frame> @ imm = #-0x74
   1c7cc: e1a03000     	mov	r3, r0
   1c7d0: e1a00003     	mov	r0, r3
   1c7d4: e24bd004     	sub	sp, r11, #4
   1c7d8: e8bd8800     	pop	{r11, pc}

