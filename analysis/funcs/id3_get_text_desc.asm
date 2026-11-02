0001d914 <id3_get_text_desc>:
   1d914: e92d4800     	push	{r11, lr}
   1d918: e28db004     	add	r11, sp, #4
   1d91c: e24dd008     	sub	sp, sp, #8
   1d920: e50b0008     	str	r0, [r11, #-0x8]
   1d924: e51b3008     	ldr	r3, [r11, #-0x8]
   1d928: e5933004     	ldr	r3, [r3, #0x4]
   1d92c: e5d33004     	ldrb	r3, [r3, #0x4]
   1d930: e3530054     	cmp	r3, #84
   1d934: 0a000001     	beq	0x1d940 <id3_get_text_desc+0x2c> @ imm = #0x4
   1d938: e3a03000     	mov	r3, #0
   1d93c: ea00001a     	b	0x1d9ac <id3_get_text_desc+0x98> @ imm = #0x68
   1d940: e51b3008     	ldr	r3, [r11, #-0x8]
   1d944: e5933004     	ldr	r3, [r3, #0x4]
   1d948: e5932000     	ldr	r2, [r3]
   1d94c: e59f3064     	ldr	r3, [pc, #0x64]         @ 0x1d9b8 <id3_get_text_desc+0xa4>
   1d950: e1520003     	cmp	r2, r3
   1d954: 0a000003     	beq	0x1d968 <id3_get_text_desc+0x54> @ imm = #0xc
   1d958: e51b3008     	ldr	r3, [r11, #-0x8]
   1d95c: e5933004     	ldr	r3, [r3, #0x4]
   1d960: e5933008     	ldr	r3, [r3, #0x8]
   1d964: ea000010     	b	0x1d9ac <id3_get_text_desc+0x98> @ imm = #0x40
   1d968: e51b0008     	ldr	r0, [r11, #-0x8]
   1d96c: ebfffb83     	bl	0x1c780 <id3_decompress_frame> @ imm = #-0x11f4
   1d970: e1a03000     	mov	r3, r0
   1d974: e3730001     	cmn	r3, #1
   1d978: 1a000001     	bne	0x1d984 <id3_get_text_desc+0x70> @ imm = #0x4
   1d97c: e3a03000     	mov	r3, #0
   1d980: ea000009     	b	0x1d9ac <id3_get_text_desc+0x98> @ imm = #0x24
   1d984: e51b3008     	ldr	r3, [r11, #-0x8]
   1d988: e5933010     	ldr	r3, [r3, #0x10]
   1d98c: e5d32000     	ldrb	r2, [r3]
   1d990: e51b3008     	ldr	r3, [r11, #-0x8]
   1d994: e5933010     	ldr	r3, [r3, #0x10]
   1d998: e2833001     	add	r3, r3, #1
   1d99c: e1a00002     	mov	r0, r2
   1d9a0: e1a01003     	mov	r1, r3
   1d9a4: ebfffeb1     	bl	0x1d470 <id3_string_decode> @ imm = #-0x53c
   1d9a8: e1a03000     	mov	r3, r0
   1d9ac: e1a00003     	mov	r0, r3
   1d9b0: e24bd004     	sub	sp, r11, #4
   1d9b4: e8bd8800     	pop	{r11, pc}
   1d9b8: 58 58 58 54  	.word	0x54585858

