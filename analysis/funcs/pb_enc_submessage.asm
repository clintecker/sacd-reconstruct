00012368 <pb_enc_submessage>:
   12368: e92d4800     	push	{r11, lr}
   1236c: e28db004     	add	r11, sp, #4
   12370: e24dd028     	sub	sp, sp, #40
   12374: e50b0020     	str	r0, [r11, #-0x20]
   12378: e50b1024     	str	r1, [r11, #-0x24]
   1237c: e50b2028     	str	r2, [r11, #-0x28]
   12380: e3a03000     	mov	r3, #0
   12384: e50b301c     	str	r3, [r11, #-0x1c]
   12388: e3a03000     	mov	r3, #0
   1238c: e50b3018     	str	r3, [r11, #-0x18]
   12390: e3a03000     	mov	r3, #0
   12394: e50b3014     	str	r3, [r11, #-0x14]
   12398: e3a03000     	mov	r3, #0
   1239c: e50b3010     	str	r3, [r11, #-0x10]
   123a0: e51b3024     	ldr	r3, [r11, #-0x24]
   123a4: e5d32009     	ldrb	r2, [r3, #0x9]
   123a8: e5d3100a     	ldrb	r1, [r3, #0xa]
   123ac: e1a01401     	lsl	r1, r1, #8
   123b0: e1812002     	orr	r2, r1, r2
   123b4: e5d3100b     	ldrb	r1, [r3, #0xb]
   123b8: e1a01801     	lsl	r1, r1, #16
   123bc: e1812002     	orr	r2, r1, r2
   123c0: e5d3300c     	ldrb	r3, [r3, #0xc]
   123c4: e1a03c03     	lsl	r3, r3, #24
   123c8: e1833002     	orr	r3, r3, r2
   123cc: e3530000     	cmp	r3, #0
   123d0: 1a000001     	bne	0x123dc <pb_enc_submessage+0x74> @ imm = #0x4
   123d4: e3a03000     	mov	r3, #0
   123d8: ea000061     	b	0x12564 <pb_enc_submessage+0x1fc> @ imm = #0x184
   123dc: e51b3024     	ldr	r3, [r11, #-0x24]
   123e0: e5d32009     	ldrb	r2, [r3, #0x9]
   123e4: e5d3100a     	ldrb	r1, [r3, #0xa]
   123e8: e1a01401     	lsl	r1, r1, #8
   123ec: e1812002     	orr	r2, r1, r2
   123f0: e5d3100b     	ldrb	r1, [r3, #0xb]
   123f4: e1a01801     	lsl	r1, r1, #16
   123f8: e1812002     	orr	r2, r1, r2
   123fc: e5d3300c     	ldrb	r3, [r3, #0xc]
   12400: e1a03c03     	lsl	r3, r3, #24
   12404: e1833002     	orr	r3, r3, r2
   12408: e24b201c     	sub	r2, r11, #28
   1240c: e1a00002     	mov	r0, r2
   12410: e1a01003     	mov	r1, r3
   12414: e51b2028     	ldr	r2, [r11, #-0x28]
   12418: ebfffd9b     	bl	0x11a8c <pb_encode>     @ imm = #-0x994
   1241c: e1a03000     	mov	r3, r0
   12420: e2233001     	eor	r3, r3, #1
   12424: e6ef3073     	uxtb	r3, r3
   12428: e3530000     	cmp	r3, #0
   1242c: 0a000001     	beq	0x12438 <pb_enc_submessage+0xd0> @ imm = #0x4
   12430: e3a03000     	mov	r3, #0
   12434: ea00004a     	b	0x12564 <pb_enc_submessage+0x1fc> @ imm = #0x128
   12438: e51b3010     	ldr	r3, [r11, #-0x10]
   1243c: e50b300c     	str	r3, [r11, #-0xc]
   12440: e51b300c     	ldr	r3, [r11, #-0xc]
   12444: e1a02003     	mov	r2, r3
   12448: e3a03000     	mov	r3, #0
   1244c: e51b0020     	ldr	r0, [r11, #-0x20]
   12450: ebfffe3a     	bl	0x11d40 <pb_encode_varint> @ imm = #-0x718
   12454: e1a03000     	mov	r3, r0
   12458: e2233001     	eor	r3, r3, #1
   1245c: e6ef3073     	uxtb	r3, r3
   12460: e3530000     	cmp	r3, #0
   12464: 0a000001     	beq	0x12470 <pb_enc_submessage+0x108> @ imm = #0x4
   12468: e3a03000     	mov	r3, #0
   1246c: ea00003c     	b	0x12564 <pb_enc_submessage+0x1fc> @ imm = #0xf0
   12470: e51b3020     	ldr	r3, [r11, #-0x20]
   12474: e5933000     	ldr	r3, [r3]
   12478: e3530000     	cmp	r3, #0
   1247c: 1a000005     	bne	0x12498 <pb_enc_submessage+0x130> @ imm = #0x14
   12480: e51b0020     	ldr	r0, [r11, #-0x20]
   12484: e3a01000     	mov	r1, #0
   12488: e51b200c     	ldr	r2, [r11, #-0xc]
   1248c: ebfffc81     	bl	0x11698 <pb_write>      @ imm = #-0xdfc
   12490: e1a03000     	mov	r3, r0
   12494: ea000032     	b	0x12564 <pb_enc_submessage+0x1fc> @ imm = #0xc8
   12498: e51b3020     	ldr	r3, [r11, #-0x20]
   1249c: e593200c     	ldr	r2, [r3, #0xc]
   124a0: e51b300c     	ldr	r3, [r11, #-0xc]
   124a4: e0822003     	add	r2, r2, r3
   124a8: e51b3020     	ldr	r3, [r11, #-0x20]
   124ac: e5933008     	ldr	r3, [r3, #0x8]
   124b0: e1520003     	cmp	r2, r3
   124b4: 9a000001     	bls	0x124c0 <pb_enc_submessage+0x158> @ imm = #0x4
   124b8: e3a03000     	mov	r3, #0
   124bc: ea000028     	b	0x12564 <pb_enc_submessage+0x1fc> @ imm = #0xa0
   124c0: e51b3020     	ldr	r3, [r11, #-0x20]
   124c4: e5933000     	ldr	r3, [r3]
   124c8: e50b301c     	str	r3, [r11, #-0x1c]
   124cc: e51b3020     	ldr	r3, [r11, #-0x20]
   124d0: e5933004     	ldr	r3, [r3, #0x4]
   124d4: e50b3018     	str	r3, [r11, #-0x18]
   124d8: e51b300c     	ldr	r3, [r11, #-0xc]
   124dc: e50b3014     	str	r3, [r11, #-0x14]
   124e0: e3a03000     	mov	r3, #0
   124e4: e50b3010     	str	r3, [r11, #-0x10]
   124e8: e51b3024     	ldr	r3, [r11, #-0x24]
   124ec: e5d32009     	ldrb	r2, [r3, #0x9]
   124f0: e5d3100a     	ldrb	r1, [r3, #0xa]
   124f4: e1a01401     	lsl	r1, r1, #8
   124f8: e1812002     	orr	r2, r1, r2
   124fc: e5d3100b     	ldrb	r1, [r3, #0xb]
   12500: e1a01801     	lsl	r1, r1, #16
   12504: e1812002     	orr	r2, r1, r2
   12508: e5d3300c     	ldrb	r3, [r3, #0xc]
   1250c: e1a03c03     	lsl	r3, r3, #24
   12510: e1833002     	orr	r3, r3, r2
   12514: e24b201c     	sub	r2, r11, #28
   12518: e1a00002     	mov	r0, r2
   1251c: e1a01003     	mov	r1, r3
   12520: e51b2028     	ldr	r2, [r11, #-0x28]
   12524: ebfffd58     	bl	0x11a8c <pb_encode>     @ imm = #-0xaa0
   12528: e1a03000     	mov	r3, r0
   1252c: e54b3005     	strb	r3, [r11, #-0x5]
   12530: e51b3020     	ldr	r3, [r11, #-0x20]
   12534: e593200c     	ldr	r2, [r3, #0xc]
   12538: e51b3010     	ldr	r3, [r11, #-0x10]
   1253c: e0822003     	add	r2, r2, r3
   12540: e51b3020     	ldr	r3, [r11, #-0x20]
   12544: e583200c     	str	r2, [r3, #0xc]
   12548: e51b2010     	ldr	r2, [r11, #-0x10]
   1254c: e51b300c     	ldr	r3, [r11, #-0xc]
   12550: e1520003     	cmp	r2, r3
   12554: 0a000001     	beq	0x12560 <pb_enc_submessage+0x1f8> @ imm = #0x4
   12558: e3a03000     	mov	r3, #0
   1255c: ea000000     	b	0x12564 <pb_enc_submessage+0x1fc> @ imm = #0x0
   12560: e55b3005     	ldrb	r3, [r11, #-0x5]
   12564: e1a00003     	mov	r0, r3
   12568: e24bd004     	sub	sp, r11, #4
   1256c: e8bd8800     	pop	{r11, pc}

