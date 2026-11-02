0001483c <log_destroy>:
   1483c: e92d4800     	push	{r11, lr}
   14840: e28db004     	add	r11, sp, #4
   14844: e24dd008     	sub	sp, sp, #8
   14848: e59f30d4     	ldr	r3, [pc, #0xd4]         @ 0x14924 <log_destroy+0xe8>
   1484c: e5933000     	ldr	r3, [r3]
   14850: e50b300c     	str	r3, [r11, #-0xc]
   14854: eb000236     	bl	0x15134 <log_flush>     @ imm = #0x8d8
   14858: e59f30c8     	ldr	r3, [pc, #0xc8]         @ 0x14928 <log_destroy+0xec>
   1485c: e5933000     	ldr	r3, [r3]
   14860: e3530000     	cmp	r3, #0
   14864: 0a00000f     	beq	0x148a8 <log_destroy+0x6c> @ imm = #0x3c
   14868: e59f30b8     	ldr	r3, [pc, #0xb8]         @ 0x14928 <log_destroy+0xec>
   1486c: e5932000     	ldr	r2, [r3]
   14870: e59f30b4     	ldr	r3, [pc, #0xb4]         @ 0x1492c <log_destroy+0xf0>
   14874: e5933000     	ldr	r3, [r3]
   14878: e1520003     	cmp	r2, r3
   1487c: 0a000009     	beq	0x148a8 <log_destroy+0x6c> @ imm = #0x24
   14880: e59f30a0     	ldr	r3, [pc, #0xa0]         @ 0x14928 <log_destroy+0xec>
   14884: e5932000     	ldr	r2, [r3]
   14888: e59f30a0     	ldr	r3, [pc, #0xa0]         @ 0x14930 <log_destroy+0xf4>
   1488c: e5933000     	ldr	r3, [r3]
   14890: e1520003     	cmp	r2, r3
   14894: 0a000003     	beq	0x148a8 <log_destroy+0x6c> @ imm = #0xc
   14898: e59f3088     	ldr	r3, [pc, #0x88]         @ 0x14928 <log_destroy+0xec>
   1489c: e5933000     	ldr	r3, [r3]
   148a0: e1a00003     	mov	r0, r3
   148a4: ebffde8e     	bl	0xc2e4 <fclose@plt>     @ imm = #-0x85c8
   148a8: e59f3078     	ldr	r3, [pc, #0x78]         @ 0x14928 <log_destroy+0xec>
   148ac: e3a02000     	mov	r2, #0
   148b0: e5832000     	str	r2, [r3]
   148b4: e59f3078     	ldr	r3, [pc, #0x78]         @ 0x14934 <log_destroy+0xf8>
   148b8: e5933000     	ldr	r3, [r3]
   148bc: e3530000     	cmp	r3, #0
   148c0: 0a00000f     	beq	0x14904 <log_destroy+0xc8> @ imm = #0x3c
   148c4: e59f3068     	ldr	r3, [pc, #0x68]         @ 0x14934 <log_destroy+0xf8>
   148c8: e5933000     	ldr	r3, [r3]
   148cc: e1a00003     	mov	r0, r3
   148d0: ebffded1     	bl	0xc41c <free@plt>       @ imm = #-0x84bc
   148d4: ea00000a     	b	0x14904 <log_destroy+0xc8> @ imm = #0x28
   148d8: e51b300c     	ldr	r3, [r11, #-0xc]
   148dc: e5933008     	ldr	r3, [r3, #0x8]
   148e0: e50b3008     	str	r3, [r11, #-0x8]
   148e4: e51b300c     	ldr	r3, [r11, #-0xc]
   148e8: e5933000     	ldr	r3, [r3]
   148ec: e1a00003     	mov	r0, r3
   148f0: ebffdec9     	bl	0xc41c <free@plt>       @ imm = #-0x84dc
   148f4: e51b000c     	ldr	r0, [r11, #-0xc]
   148f8: ebffdec7     	bl	0xc41c <free@plt>       @ imm = #-0x84e4
   148fc: e51b3008     	ldr	r3, [r11, #-0x8]
   14900: e50b300c     	str	r3, [r11, #-0xc]
   14904: e51b300c     	ldr	r3, [r11, #-0xc]
   14908: e3530000     	cmp	r3, #0
   1490c: 1afffff1     	bne	0x148d8 <log_destroy+0x9c> @ imm = #-0x3c
   14910: e59f300c     	ldr	r3, [pc, #0xc]          @ 0x14924 <log_destroy+0xe8>
   14914: e3a02000     	mov	r2, #0
   14918: e5832000     	str	r2, [r3]
   1491c: e24bd004     	sub	sp, r11, #4
   14920: e8bd8800     	pop	{r11, pc}
   14924: 44 73 05 00  	.word	0x00057344
   14928: 54 73 05 00  	.word	0x00057354
   1492c: f4 6d 05 00  	.word	0x00056df4
   14930: f8 6d 05 00  	.word	0x00056df8
   14934: 48 73 05 00  	.word	0x00057348

