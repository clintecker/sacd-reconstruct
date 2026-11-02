0001d310 <id3_get_url_desc>:
   1d310: e92d4800     	push	{r11, lr}
   1d314: e28db004     	add	r11, sp, #4
   1d318: e24dd008     	sub	sp, sp, #8
   1d31c: e50b0008     	str	r0, [r11, #-0x8]
   1d320: e51b3008     	ldr	r3, [r11, #-0x8]
   1d324: e5933004     	ldr	r3, [r3, #0x4]
   1d328: e5d33004     	ldrb	r3, [r3, #0x4]
   1d32c: e3530057     	cmp	r3, #87
   1d330: 0a000001     	beq	0x1d33c <id3_get_url_desc+0x2c> @ imm = #0x4
   1d334: e3a03000     	mov	r3, #0
   1d338: ea00001a     	b	0x1d3a8 <id3_get_url_desc+0x98> @ imm = #0x68
   1d33c: e51b3008     	ldr	r3, [r11, #-0x8]
   1d340: e5933004     	ldr	r3, [r3, #0x4]
   1d344: e5932000     	ldr	r2, [r3]
   1d348: e59f3064     	ldr	r3, [pc, #0x64]         @ 0x1d3b4 <id3_get_url_desc+0xa4>
   1d34c: e1520003     	cmp	r2, r3
   1d350: 0a000003     	beq	0x1d364 <id3_get_url_desc+0x54> @ imm = #0xc
   1d354: e51b3008     	ldr	r3, [r11, #-0x8]
   1d358: e5933004     	ldr	r3, [r3, #0x4]
   1d35c: e5933008     	ldr	r3, [r3, #0x8]
   1d360: ea000010     	b	0x1d3a8 <id3_get_url_desc+0x98> @ imm = #0x40
   1d364: e51b0008     	ldr	r0, [r11, #-0x8]
   1d368: ebfffd04     	bl	0x1c780 <id3_decompress_frame> @ imm = #-0xbf0
   1d36c: e1a03000     	mov	r3, r0
   1d370: e3730001     	cmn	r3, #1
   1d374: 1a000001     	bne	0x1d380 <id3_get_url_desc+0x70> @ imm = #0x4
   1d378: e3a03000     	mov	r3, #0
   1d37c: ea000009     	b	0x1d3a8 <id3_get_url_desc+0x98> @ imm = #0x24
   1d380: e51b3008     	ldr	r3, [r11, #-0x8]
   1d384: e5933010     	ldr	r3, [r3, #0x10]
   1d388: e5d32000     	ldrb	r2, [r3]
   1d38c: e51b3008     	ldr	r3, [r11, #-0x8]
   1d390: e5933010     	ldr	r3, [r3, #0x10]
   1d394: e2833001     	add	r3, r3, #1
   1d398: e1a00002     	mov	r0, r2
   1d39c: e1a01003     	mov	r1, r3
   1d3a0: eb000032     	bl	0x1d470 <id3_string_decode> @ imm = #0xc8
   1d3a4: e1a03000     	mov	r3, r0
   1d3a8: e1a00003     	mov	r0, r3
   1d3ac: e24bd004     	sub	sp, r11, #4
   1d3b0: e8bd8800     	pop	{r11, pc}
   1d3b4: 58 58 58 57  	.word	0x57585858

