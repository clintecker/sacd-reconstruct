0001d4f8 <id3_get_encoding>:
   1d4f8: e92d4800     	push	{r11, lr}
   1d4fc: e28db004     	add	r11, sp, #4
   1d500: e24dd008     	sub	sp, sp, #8
   1d504: e50b0008     	str	r0, [r11, #-0x8]
   1d508: e51b0008     	ldr	r0, [r11, #-0x8]
   1d50c: eb000218     	bl	0x1dd74 <id3_frame_is_text> @ imm = #0x860
   1d510: e1a03000     	mov	r3, r0
   1d514: e3530000     	cmp	r3, #0
   1d518: 1a00003d     	bne	0x1d614 <id3_get_encoding+0x11c> @ imm = #0xf4
   1d51c: e51b3008     	ldr	r3, [r11, #-0x8]
   1d520: e5933004     	ldr	r3, [r3, #0x4]
   1d524: e5932000     	ldr	r2, [r3]
   1d528: e59f311c     	ldr	r3, [pc, #0x11c]        @ 0x1d64c <id3_get_encoding+0x154>
   1d52c: e1520003     	cmp	r2, r3
   1d530: 0a000037     	beq	0x1d614 <id3_get_encoding+0x11c> @ imm = #0xdc
   1d534: e51b3008     	ldr	r3, [r11, #-0x8]
   1d538: e5933004     	ldr	r3, [r3, #0x4]
   1d53c: e5932000     	ldr	r2, [r3]
   1d540: e59f3108     	ldr	r3, [pc, #0x108]        @ 0x1d650 <id3_get_encoding+0x158>
   1d544: e1520003     	cmp	r2, r3
   1d548: 0a000031     	beq	0x1d614 <id3_get_encoding+0x11c> @ imm = #0xc4
   1d54c: e51b3008     	ldr	r3, [r11, #-0x8]
   1d550: e5933004     	ldr	r3, [r3, #0x4]
   1d554: e5932000     	ldr	r2, [r3]
   1d558: e59f30f4     	ldr	r3, [pc, #0xf4]         @ 0x1d654 <id3_get_encoding+0x15c>
   1d55c: e1520003     	cmp	r2, r3
   1d560: 0a00002b     	beq	0x1d614 <id3_get_encoding+0x11c> @ imm = #0xac
   1d564: e51b3008     	ldr	r3, [r11, #-0x8]
   1d568: e5933004     	ldr	r3, [r3, #0x4]
   1d56c: e5932000     	ldr	r2, [r3]
   1d570: e59f30e0     	ldr	r3, [pc, #0xe0]         @ 0x1d658 <id3_get_encoding+0x160>
   1d574: e1520003     	cmp	r2, r3
   1d578: 0a000025     	beq	0x1d614 <id3_get_encoding+0x11c> @ imm = #0x94
   1d57c: e51b3008     	ldr	r3, [r11, #-0x8]
   1d580: e5933004     	ldr	r3, [r3, #0x4]
   1d584: e5932000     	ldr	r2, [r3]
   1d588: e59f30cc     	ldr	r3, [pc, #0xcc]         @ 0x1d65c <id3_get_encoding+0x164>
   1d58c: e1520003     	cmp	r2, r3
   1d590: 0a00001f     	beq	0x1d614 <id3_get_encoding+0x11c> @ imm = #0x7c
   1d594: e51b3008     	ldr	r3, [r11, #-0x8]
   1d598: e5933004     	ldr	r3, [r3, #0x4]
   1d59c: e5932000     	ldr	r2, [r3]
   1d5a0: e59f30b8     	ldr	r3, [pc, #0xb8]         @ 0x1d660 <id3_get_encoding+0x168>
   1d5a4: e1520003     	cmp	r2, r3
   1d5a8: 0a000019     	beq	0x1d614 <id3_get_encoding+0x11c> @ imm = #0x64
   1d5ac: e51b3008     	ldr	r3, [r11, #-0x8]
   1d5b0: e5933004     	ldr	r3, [r3, #0x4]
   1d5b4: e5932000     	ldr	r2, [r3]
   1d5b8: e59f30a4     	ldr	r3, [pc, #0xa4]         @ 0x1d664 <id3_get_encoding+0x16c>
   1d5bc: e1520003     	cmp	r2, r3
   1d5c0: 0a000013     	beq	0x1d614 <id3_get_encoding+0x11c> @ imm = #0x4c
   1d5c4: e51b3008     	ldr	r3, [r11, #-0x8]
   1d5c8: e5933004     	ldr	r3, [r3, #0x4]
   1d5cc: e5932000     	ldr	r2, [r3]
   1d5d0: e59f3090     	ldr	r3, [pc, #0x90]         @ 0x1d668 <id3_get_encoding+0x170>
   1d5d4: e1520003     	cmp	r2, r3
   1d5d8: 0a00000d     	beq	0x1d614 <id3_get_encoding+0x11c> @ imm = #0x34
   1d5dc: e51b3008     	ldr	r3, [r11, #-0x8]
   1d5e0: e5933004     	ldr	r3, [r3, #0x4]
   1d5e4: e5932000     	ldr	r2, [r3]
   1d5e8: e59f307c     	ldr	r3, [pc, #0x7c]         @ 0x1d66c <id3_get_encoding+0x174>
   1d5ec: e1520003     	cmp	r2, r3
   1d5f0: 0a000007     	beq	0x1d614 <id3_get_encoding+0x11c> @ imm = #0x1c
   1d5f4: e51b3008     	ldr	r3, [r11, #-0x8]
   1d5f8: e5933004     	ldr	r3, [r3, #0x4]
   1d5fc: e5932000     	ldr	r2, [r3]
   1d600: e59f3068     	ldr	r3, [pc, #0x68]         @ 0x1d670 <id3_get_encoding+0x178>
   1d604: e1520003     	cmp	r2, r3
   1d608: 0a000001     	beq	0x1d614 <id3_get_encoding+0x11c> @ imm = #0x4
   1d60c: e3a030ff     	mov	r3, #255
   1d610: ea000009     	b	0x1d63c <id3_get_encoding+0x144> @ imm = #0x24
   1d614: e51b0008     	ldr	r0, [r11, #-0x8]
   1d618: ebfffc58     	bl	0x1c780 <id3_decompress_frame> @ imm = #-0xea0
   1d61c: e1a03000     	mov	r3, r0
   1d620: e3730001     	cmn	r3, #1
   1d624: 1a000001     	bne	0x1d630 <id3_get_encoding+0x138> @ imm = #0x4
   1d628: e3a030ff     	mov	r3, #255
   1d62c: ea000002     	b	0x1d63c <id3_get_encoding+0x144> @ imm = #0x8
   1d630: e51b3008     	ldr	r3, [r11, #-0x8]
   1d634: e5933010     	ldr	r3, [r3, #0x10]
   1d638: e5d33000     	ldrb	r3, [r3]
   1d63c: e6af3073     	sxtb	r3, r3
   1d640: e1a00003     	mov	r0, r3
   1d644: e24bd004     	sub	sp, r11, #4
   1d648: e8bd8800     	pop	{r11, pc}
   1d64c: 58 58 58 57  	.word	0x57585858
   1d650: 53 4c 50 49  	.word	0x49504c53
   1d654: 54 4c 53 55  	.word	0x55534c54
   1d658: 54 4c 59 53  	.word	0x53594c54
   1d65c: 4d 4d 4f 43  	.word	0x434f4d4d
   1d660: 43 49 50 41  	.word	0x41504943
   1d664: 42 4f 45 47  	.word	0x47454f42
   1d668: 52 45 53 55  	.word	0x55534552
   1d66c: 45 4e 57 4f  	.word	0x4f574e45
   1d670: 52 4d 4f 43  	.word	0x434f4d52

