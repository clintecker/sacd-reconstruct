0001f234 <scarletbook_print_album_text>:
   1f234: e92d4830     	push	{r4, r5, r11, lr}
   1f238: e28db00c     	add	r11, sp, #12
   1f23c: e24dd010     	sub	sp, sp, #16
   1f240: e50b0018     	str	r0, [r11, #-0x18]
   1f244: e51b3018     	ldr	r3, [r11, #-0x18]
   1f248: e5933008     	ldr	r3, [r3, #0x8]
   1f24c: e50b3014     	str	r3, [r11, #-0x14]
   1f250: e51b3018     	ldr	r3, [r11, #-0x18]
   1f254: e2833010     	add	r3, r3, #16
   1f258: e50b3010     	str	r3, [r11, #-0x10]
   1f25c: e59f3248     	ldr	r3, [pc, #0x248]        @ 0x1f4ac <scarletbook_print_album_text+0x278>
   1f260: e5933000     	ldr	r3, [r3]
   1f264: e1a00003     	mov	r0, r3
   1f268: e59f1240     	ldr	r1, [pc, #0x240]        @ 0x1f4b0 <scarletbook_print_album_text+0x27c>
   1f26c: e51b3014     	ldr	r3, [r11, #-0x14]
   1f270: e5d33088     	ldrb	r3, [r3, #0x88]
   1f274: e1a02003     	mov	r2, r3
   1f278: e51b3014     	ldr	r3, [r11, #-0x14]
   1f27c: e5d33089     	ldrb	r3, [r3, #0x89]
   1f280: ebffb51f     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x12b84
   1f284: e51b3010     	ldr	r3, [r11, #-0x10]
   1f288: e5933000     	ldr	r3, [r3]
   1f28c: e3530000     	cmp	r3, #0
   1f290: 0a00000c     	beq	0x1f2c8 <scarletbook_print_album_text+0x94> @ imm = #0x30
   1f294: e59f3210     	ldr	r3, [pc, #0x210]        @ 0x1f4ac <scarletbook_print_album_text+0x278>
   1f298: e5933000     	ldr	r3, [r3]
   1f29c: e1a05003     	mov	r5, r3
   1f2a0: e59f420c     	ldr	r4, [pc, #0x20c]        @ 0x1f4b4 <scarletbook_print_album_text+0x280>
   1f2a4: e51b3010     	ldr	r3, [r11, #-0x10]
   1f2a8: e5933000     	ldr	r3, [r3]
   1f2ac: e1a00003     	mov	r0, r3
   1f2b0: ebffffc2     	bl	0x1f1c0 <ucs>           @ imm = #-0xf8
   1f2b4: e1a03000     	mov	r3, r0
   1f2b8: e1a00005     	mov	r0, r5
   1f2bc: e1a01004     	mov	r1, r4
   1f2c0: e1a02003     	mov	r2, r3
   1f2c4: ebffb50e     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x12bc8
   1f2c8: e51b3010     	ldr	r3, [r11, #-0x10]
   1f2cc: e5933004     	ldr	r3, [r3, #0x4]
   1f2d0: e3530000     	cmp	r3, #0
   1f2d4: 0a00000c     	beq	0x1f30c <scarletbook_print_album_text+0xd8> @ imm = #0x30
   1f2d8: e59f31cc     	ldr	r3, [pc, #0x1cc]        @ 0x1f4ac <scarletbook_print_album_text+0x278>
   1f2dc: e5933000     	ldr	r3, [r3]
   1f2e0: e1a05003     	mov	r5, r3
   1f2e4: e59f41cc     	ldr	r4, [pc, #0x1cc]        @ 0x1f4b8 <scarletbook_print_album_text+0x284>
   1f2e8: e51b3010     	ldr	r3, [r11, #-0x10]
   1f2ec: e5933004     	ldr	r3, [r3, #0x4]
   1f2f0: e1a00003     	mov	r0, r3
   1f2f4: ebffffb1     	bl	0x1f1c0 <ucs>           @ imm = #-0x13c
   1f2f8: e1a03000     	mov	r3, r0
   1f2fc: e1a00005     	mov	r0, r5
   1f300: e1a01004     	mov	r1, r4
   1f304: e1a02003     	mov	r2, r3
   1f308: ebffb4fd     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x12c0c
   1f30c: e51b3010     	ldr	r3, [r11, #-0x10]
   1f310: e5933008     	ldr	r3, [r3, #0x8]
   1f314: e3530000     	cmp	r3, #0
   1f318: 0a00000c     	beq	0x1f350 <scarletbook_print_album_text+0x11c> @ imm = #0x30
   1f31c: e59f3188     	ldr	r3, [pc, #0x188]        @ 0x1f4ac <scarletbook_print_album_text+0x278>
   1f320: e5933000     	ldr	r3, [r3]
   1f324: e1a05003     	mov	r5, r3
   1f328: e59f418c     	ldr	r4, [pc, #0x18c]        @ 0x1f4bc <scarletbook_print_album_text+0x288>
   1f32c: e51b3010     	ldr	r3, [r11, #-0x10]
   1f330: e5933008     	ldr	r3, [r3, #0x8]
   1f334: e1a00003     	mov	r0, r3
   1f338: ebffffa0     	bl	0x1f1c0 <ucs>           @ imm = #-0x180
   1f33c: e1a03000     	mov	r3, r0
   1f340: e1a00005     	mov	r0, r5
   1f344: e1a01004     	mov	r1, r4
   1f348: e1a02003     	mov	r2, r3
   1f34c: ebffb4ec     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x12c50
   1f350: e51b3010     	ldr	r3, [r11, #-0x10]
   1f354: e593300c     	ldr	r3, [r3, #0xc]
   1f358: e3530000     	cmp	r3, #0
   1f35c: 0a00000c     	beq	0x1f394 <scarletbook_print_album_text+0x160> @ imm = #0x30
   1f360: e59f3144     	ldr	r3, [pc, #0x144]        @ 0x1f4ac <scarletbook_print_album_text+0x278>
   1f364: e5933000     	ldr	r3, [r3]
   1f368: e1a05003     	mov	r5, r3
   1f36c: e59f414c     	ldr	r4, [pc, #0x14c]        @ 0x1f4c0 <scarletbook_print_album_text+0x28c>
   1f370: e51b3010     	ldr	r3, [r11, #-0x10]
   1f374: e593300c     	ldr	r3, [r3, #0xc]
   1f378: e1a00003     	mov	r0, r3
   1f37c: ebffff8f     	bl	0x1f1c0 <ucs>           @ imm = #-0x1c4
   1f380: e1a03000     	mov	r3, r0
   1f384: e1a00005     	mov	r0, r5
   1f388: e1a01004     	mov	r1, r4
   1f38c: e1a02003     	mov	r2, r3
   1f390: ebffb4db     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x12c94
   1f394: e51b3010     	ldr	r3, [r11, #-0x10]
   1f398: e5933010     	ldr	r3, [r3, #0x10]
   1f39c: e3530000     	cmp	r3, #0
   1f3a0: 0a00000c     	beq	0x1f3d8 <scarletbook_print_album_text+0x1a4> @ imm = #0x30
   1f3a4: e59f3100     	ldr	r3, [pc, #0x100]        @ 0x1f4ac <scarletbook_print_album_text+0x278>
   1f3a8: e5933000     	ldr	r3, [r3]
   1f3ac: e1a05003     	mov	r5, r3
   1f3b0: e59f410c     	ldr	r4, [pc, #0x10c]        @ 0x1f4c4 <scarletbook_print_album_text+0x290>
   1f3b4: e51b3010     	ldr	r3, [r11, #-0x10]
   1f3b8: e5933010     	ldr	r3, [r3, #0x10]
   1f3bc: e1a00003     	mov	r0, r3
   1f3c0: ebffff7e     	bl	0x1f1c0 <ucs>           @ imm = #-0x208
   1f3c4: e1a03000     	mov	r3, r0
   1f3c8: e1a00005     	mov	r0, r5
   1f3cc: e1a01004     	mov	r1, r4
   1f3d0: e1a02003     	mov	r2, r3
   1f3d4: ebffb4ca     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x12cd8
   1f3d8: e51b3010     	ldr	r3, [r11, #-0x10]
   1f3dc: e5933014     	ldr	r3, [r3, #0x14]
   1f3e0: e3530000     	cmp	r3, #0
   1f3e4: 0a00000c     	beq	0x1f41c <scarletbook_print_album_text+0x1e8> @ imm = #0x30
   1f3e8: e59f30bc     	ldr	r3, [pc, #0xbc]         @ 0x1f4ac <scarletbook_print_album_text+0x278>
   1f3ec: e5933000     	ldr	r3, [r3]
   1f3f0: e1a05003     	mov	r5, r3
   1f3f4: e59f40cc     	ldr	r4, [pc, #0xcc]         @ 0x1f4c8 <scarletbook_print_album_text+0x294>
   1f3f8: e51b3010     	ldr	r3, [r11, #-0x10]
   1f3fc: e5933014     	ldr	r3, [r3, #0x14]
   1f400: e1a00003     	mov	r0, r3
   1f404: ebffff6d     	bl	0x1f1c0 <ucs>           @ imm = #-0x24c
   1f408: e1a03000     	mov	r3, r0
   1f40c: e1a00005     	mov	r0, r5
   1f410: e1a01004     	mov	r1, r4
   1f414: e1a02003     	mov	r2, r3
   1f418: ebffb4b9     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x12d1c
   1f41c: e51b3010     	ldr	r3, [r11, #-0x10]
   1f420: e5933018     	ldr	r3, [r3, #0x18]
   1f424: e3530000     	cmp	r3, #0
   1f428: 0a00000c     	beq	0x1f460 <scarletbook_print_album_text+0x22c> @ imm = #0x30
   1f42c: e59f3078     	ldr	r3, [pc, #0x78]         @ 0x1f4ac <scarletbook_print_album_text+0x278>
   1f430: e5933000     	ldr	r3, [r3]
   1f434: e1a05003     	mov	r5, r3
   1f438: e59f408c     	ldr	r4, [pc, #0x8c]         @ 0x1f4cc <scarletbook_print_album_text+0x298>
   1f43c: e51b3010     	ldr	r3, [r11, #-0x10]
   1f440: e5933018     	ldr	r3, [r3, #0x18]
   1f444: e1a00003     	mov	r0, r3
   1f448: ebffff5c     	bl	0x1f1c0 <ucs>           @ imm = #-0x290
   1f44c: e1a03000     	mov	r3, r0
   1f450: e1a00005     	mov	r0, r5
   1f454: e1a01004     	mov	r1, r4
   1f458: e1a02003     	mov	r2, r3
   1f45c: ebffb4a8     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x12d60
   1f460: e51b3010     	ldr	r3, [r11, #-0x10]
   1f464: e593301c     	ldr	r3, [r3, #0x1c]
   1f468: e3530000     	cmp	r3, #0
   1f46c: 0a00000c     	beq	0x1f4a4 <scarletbook_print_album_text+0x270> @ imm = #0x30
   1f470: e59f3034     	ldr	r3, [pc, #0x34]         @ 0x1f4ac <scarletbook_print_album_text+0x278>
   1f474: e5933000     	ldr	r3, [r3]
   1f478: e1a05003     	mov	r5, r3
   1f47c: e59f404c     	ldr	r4, [pc, #0x4c]         @ 0x1f4d0 <scarletbook_print_album_text+0x29c>
   1f480: e51b3010     	ldr	r3, [r11, #-0x10]
   1f484: e593301c     	ldr	r3, [r3, #0x1c]
   1f488: e1a00003     	mov	r0, r3
   1f48c: ebffff4b     	bl	0x1f1c0 <ucs>           @ imm = #-0x2d4
   1f490: e1a03000     	mov	r3, r0
   1f494: e1a00005     	mov	r0, r5
   1f498: e1a01004     	mov	r1, r4
   1f49c: e1a02003     	mov	r2, r3
   1f4a0: ebffb497     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x12da4
   1f4a4: e24bd00c     	sub	sp, r11, #12
   1f4a8: e8bd8830     	pop	{r4, r5, r11, pc}
   1f4ac: f4 6d 05 00  	.word	0x00056df4
   1f4b0: b8 39 03 00  	.word	0x000339b8
   1f4b4: f4 39 03 00  	.word	0x000339f4
   1f4b8: 28 3a 03 00  	.word	0x00033a28
   1f4bc: 80 3a 03 00  	.word	0x00033a80
   1f4c0: b8 3a 03 00  	.word	0x00033ab8
   1f4c4: 14 3b 03 00  	.word	0x00033b14
   1f4c8: 58 3b 03 00  	.word	0x00033b58
   1f4cc: c0 3b 03 00  	.word	0x00033bc0
   1f4d0: 04 3c 03 00  	.word	0x00033c04

