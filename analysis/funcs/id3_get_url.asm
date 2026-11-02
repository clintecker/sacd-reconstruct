0001d21c <id3_get_url>:
   1d21c: e92d4800     	push	{r11, lr}
   1d220: e28db004     	add	r11, sp, #4
   1d224: e24dd010     	sub	sp, sp, #16
   1d228: e50b0010     	str	r0, [r11, #-0x10]
   1d22c: e3a03000     	mov	r3, #0
   1d230: e50b3008     	str	r3, [r11, #-0x8]
   1d234: e51b3010     	ldr	r3, [r11, #-0x10]
   1d238: e5933004     	ldr	r3, [r3, #0x4]
   1d23c: e5d33004     	ldrb	r3, [r3, #0x4]
   1d240: e3530057     	cmp	r3, #87
   1d244: 0a000001     	beq	0x1d250 <id3_get_url+0x34> @ imm = #0x4
   1d248: e3a03000     	mov	r3, #0
   1d24c: ea00002b     	b	0x1d300 <id3_get_url+0xe4> @ imm = #0xac
   1d250: e51b0010     	ldr	r0, [r11, #-0x10]
   1d254: ebfffd49     	bl	0x1c780 <id3_decompress_frame> @ imm = #-0xadc
   1d258: e1a03000     	mov	r3, r0
   1d25c: e3730001     	cmn	r3, #1
   1d260: 1a000001     	bne	0x1d26c <id3_get_url+0x50> @ imm = #0x4
   1d264: e3a03000     	mov	r3, #0
   1d268: ea000024     	b	0x1d300 <id3_get_url+0xe4> @ imm = #0x90
   1d26c: e51b3010     	ldr	r3, [r11, #-0x10]
   1d270: e5933004     	ldr	r3, [r3, #0x4]
   1d274: e5932000     	ldr	r2, [r3]
   1d278: e59f308c     	ldr	r3, [pc, #0x8c]         @ 0x1d30c <id3_get_url+0xf0>
   1d27c: e1520003     	cmp	r2, r3
   1d280: 1a000011     	bne	0x1d2cc <id3_get_url+0xb0> @ imm = #0x44
   1d284: e51b3010     	ldr	r3, [r11, #-0x10]
   1d288: e5933010     	ldr	r3, [r3, #0x10]
   1d28c: e5d32000     	ldrb	r2, [r3]
   1d290: e51b3010     	ldr	r3, [r11, #-0x10]
   1d294: e5933010     	ldr	r3, [r3, #0x10]
   1d298: e2833001     	add	r3, r3, #1
   1d29c: e1a00002     	mov	r0, r2
   1d2a0: e1a01003     	mov	r1, r3
   1d2a4: eb000043     	bl	0x1d3b8 <id3_string_size> @ imm = #0x10c
   1d2a8: e1a03000     	mov	r3, r0
   1d2ac: e50b3008     	str	r3, [r11, #-0x8]
   1d2b0: e51b3010     	ldr	r3, [r11, #-0x10]
   1d2b4: e5932014     	ldr	r2, [r3, #0x14]
   1d2b8: e51b3008     	ldr	r3, [r11, #-0x8]
   1d2bc: e1520003     	cmp	r2, r3
   1d2c0: ca000001     	bgt	0x1d2cc <id3_get_url+0xb0> @ imm = #0x4
   1d2c4: e3a03000     	mov	r3, #0
   1d2c8: ea00000c     	b	0x1d300 <id3_get_url+0xe4> @ imm = #0x30
   1d2cc: e51b3010     	ldr	r3, [r11, #-0x10]
   1d2d0: e5933010     	ldr	r3, [r3, #0x10]
   1d2d4: e5d32000     	ldrb	r2, [r3]
   1d2d8: e51b3010     	ldr	r3, [r11, #-0x10]
   1d2dc: e5933010     	ldr	r3, [r3, #0x10]
   1d2e0: e1a01003     	mov	r1, r3
   1d2e4: e51b3008     	ldr	r3, [r11, #-0x8]
   1d2e8: e2833001     	add	r3, r3, #1
   1d2ec: e0813003     	add	r3, r1, r3
   1d2f0: e1a00002     	mov	r0, r2
   1d2f4: e1a01003     	mov	r1, r3
   1d2f8: eb00005c     	bl	0x1d470 <id3_string_decode> @ imm = #0x170
   1d2fc: e1a03000     	mov	r3, r0
   1d300: e1a00003     	mov	r0, r3
   1d304: e24bd004     	sub	sp, r11, #4
   1d308: e8bd8800     	pop	{r11, pc}
   1d30c: 58 58 58 57  	.word	0x57585858

