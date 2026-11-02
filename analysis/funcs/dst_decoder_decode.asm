0001b3f8 <dst_decoder_decode>:
   1b3f8: e92d4800     	push	{r11, lr}
   1b3fc: e28db004     	add	r11, sp, #4
   1b400: e24dd018     	sub	sp, sp, #24
   1b404: e50b0010     	str	r0, [r11, #-0x10]
   1b408: e50b1014     	str	r1, [r11, #-0x14]
   1b40c: e50b2018     	str	r2, [r11, #-0x18]
   1b410: e3a00018     	mov	r0, #24
   1b414: ebffc493     	bl	0xc668 <malloc@plt>     @ imm = #-0xedb4
   1b418: e1a03000     	mov	r3, r0
   1b41c: e50b3008     	str	r3, [r11, #-0x8]
   1b420: e51b3008     	ldr	r3, [r11, #-0x8]
   1b424: e3530000     	cmp	r3, #0
   1b428: 1a000001     	bne	0x1b434 <dst_decoder_decode+0x3c> @ imm = #0x4
   1b42c: e3a00001     	mov	r0, #1
   1b430: ebffc4e3     	bl	0xc7c4 <exit@plt>       @ imm = #-0xec74
   1b434: e51b3008     	ldr	r3, [r11, #-0x8]
   1b438: e3a02000     	mov	r2, #0
   1b43c: e5832004     	str	r2, [r3, #0x4]
   1b440: e51b3010     	ldr	r3, [r11, #-0x10]
   1b444: e5932008     	ldr	r2, [r3, #0x8]
   1b448: e51b3008     	ldr	r3, [r11, #-0x8]
   1b44c: e5832000     	str	r2, [r3]
   1b450: e51b3010     	ldr	r3, [r11, #-0x10]
   1b454: e283300c     	add	r3, r3, #12
   1b458: e1a00003     	mov	r0, r3
   1b45c: ebffeb23     	bl	0x160f0 <buffer_pool_get_space> @ imm = #-0x5374
   1b460: e1a02000     	mov	r2, r0
   1b464: e51b3008     	ldr	r3, [r11, #-0x8]
   1b468: e583200c     	str	r2, [r3, #0xc]
   1b46c: e51b3008     	ldr	r3, [r11, #-0x8]
   1b470: e593300c     	ldr	r3, [r3, #0xc]
   1b474: e5933004     	ldr	r3, [r3, #0x4]
   1b478: e1a00003     	mov	r0, r3
   1b47c: e51b1014     	ldr	r1, [r11, #-0x14]
   1b480: e51b2018     	ldr	r2, [r11, #-0x18]
   1b484: ebffc420     	bl	0xc50c <memcpy@plt>     @ imm = #-0xef80
   1b488: e51b3008     	ldr	r3, [r11, #-0x8]
   1b48c: e593300c     	ldr	r3, [r3, #0xc]
   1b490: e51b2018     	ldr	r2, [r11, #-0x18]
   1b494: e5832008     	str	r2, [r3, #0x8]
   1b498: e51b3008     	ldr	r3, [r11, #-0x8]
   1b49c: e3a02000     	mov	r2, #0
   1b4a0: e5832010     	str	r2, [r3, #0x10]
   1b4a4: e51b3008     	ldr	r3, [r11, #-0x8]
   1b4a8: e3a02001     	mov	r2, #1
   1b4ac: e5832008     	str	r2, [r3, #0x8]
   1b4b0: e51b3010     	ldr	r3, [r11, #-0x10]
   1b4b4: e5933008     	ldr	r3, [r3, #0x8]
   1b4b8: e2832001     	add	r2, r3, #1
   1b4bc: e51b3010     	ldr	r3, [r11, #-0x10]
   1b4c0: e5832008     	str	r2, [r3, #0x8]
   1b4c4: e51b3010     	ldr	r3, [r11, #-0x10]
   1b4c8: e5932048     	ldr	r2, [r3, #0x48]
   1b4cc: e51b3010     	ldr	r3, [r11, #-0x10]
   1b4d0: e5933000     	ldr	r3, [r3]
   1b4d4: e1520003     	cmp	r2, r3
   1b4d8: aa000007     	bge	0x1b4fc <dst_decoder_decode+0x104> @ imm = #0x1c
   1b4dc: e59f0074     	ldr	r0, [pc, #0x74]         @ 0x1b558 <dst_decoder_decode+0x160>
   1b4e0: e51b1010     	ldr	r1, [r11, #-0x10]
   1b4e4: ebffe9f0     	bl	0x15cac <launch>        @ imm = #-0x5840
   1b4e8: e51b3010     	ldr	r3, [r11, #-0x10]
   1b4ec: e5933048     	ldr	r3, [r3, #0x48]
   1b4f0: e2832001     	add	r2, r3, #1
   1b4f4: e51b3010     	ldr	r3, [r11, #-0x10]
   1b4f8: e5832048     	str	r2, [r3, #0x48]
   1b4fc: e51b3010     	ldr	r3, [r11, #-0x10]
   1b500: e5933034     	ldr	r3, [r3, #0x34]
   1b504: e1a00003     	mov	r0, r3
   1b508: ebffe8a8     	bl	0x157b0 <possess>       @ imm = #-0x5d60
   1b50c: e51b3008     	ldr	r3, [r11, #-0x8]
   1b510: e3a02000     	mov	r2, #0
   1b514: e5832014     	str	r2, [r3, #0x14]
   1b518: e51b3010     	ldr	r3, [r11, #-0x10]
   1b51c: e593303c     	ldr	r3, [r3, #0x3c]
   1b520: e51b2008     	ldr	r2, [r11, #-0x8]
   1b524: e5832000     	str	r2, [r3]
   1b528: e51b3008     	ldr	r3, [r11, #-0x8]
   1b52c: e2832014     	add	r2, r3, #20
   1b530: e51b3010     	ldr	r3, [r11, #-0x10]
   1b534: e583203c     	str	r2, [r3, #0x3c]
   1b538: e51b3010     	ldr	r3, [r11, #-0x10]
   1b53c: e5933034     	ldr	r3, [r3, #0x34]
   1b540: e1a00003     	mov	r0, r3
   1b544: e3a01001     	mov	r1, #1
   1b548: e3a02001     	mov	r2, #1
   1b54c: ebffe8b7     	bl	0x15830 <twist>         @ imm = #-0x5d24
   1b550: e24bd004     	sub	sp, r11, #4
   1b554: e8bd8800     	pop	{r11, pc}
   1b558: 98 ab 01 00  	.word	0x0001ab98

