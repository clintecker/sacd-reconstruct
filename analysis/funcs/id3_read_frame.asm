0001c374 <id3_read_frame>:
   1c374: e92d4800     	push	{r11, lr}
   1c378: e28db004     	add	r11, sp, #4
   1c37c: e24dd018     	sub	sp, sp, #24
   1c380: e50b0018     	str	r0, [r11, #-0x18]
   1c384: e51b3018     	ldr	r3, [r11, #-0x18]
   1c388: e5933014     	ldr	r3, [r3, #0x14]
   1c38c: e3530002     	cmp	r3, #2
   1c390: 1a000003     	bne	0x1c3a4 <id3_read_frame+0x30> @ imm = #0xc
   1c394: e51b0018     	ldr	r0, [r11, #-0x18]
   1c398: eb00023a     	bl	0x1cc88 <id3_read_frame_v22> @ imm = #0x8e8
   1c39c: e1a03000     	mov	r3, r0
   1c3a0: ea0000b9     	b	0x1c68c <id3_read_frame+0x318> @ imm = #0x2e4
   1c3a4: e51b3018     	ldr	r3, [r11, #-0x18]
   1c3a8: e5933134     	ldr	r3, [r3, #0x134]
   1c3ac: e51b0018     	ldr	r0, [r11, #-0x18]
   1c3b0: e3a01000     	mov	r1, #0
   1c3b4: e3a0200a     	mov	r2, #10
   1c3b8: e12fff33     	blx	r3
   1c3bc: e1a03000     	mov	r3, r0
   1c3c0: e50b3008     	str	r3, [r11, #-0x8]
   1c3c4: e51b3008     	ldr	r3, [r11, #-0x8]
   1c3c8: e3530000     	cmp	r3, #0
   1c3cc: 1a000001     	bne	0x1c3d8 <id3_read_frame+0x64> @ imm = #0x4
   1c3d0: e3e03000     	mvn	r3, #0
   1c3d4: ea0000ac     	b	0x1c68c <id3_read_frame+0x318> @ imm = #0x2b0
   1c3d8: e51b3008     	ldr	r3, [r11, #-0x8]
   1c3dc: e5d33000     	ldrb	r3, [r3]
   1c3e0: e353002f     	cmp	r3, #47
   1c3e4: 9a000003     	bls	0x1c3f8 <id3_read_frame+0x84> @ imm = #0xc
   1c3e8: e51b3008     	ldr	r3, [r11, #-0x8]
   1c3ec: e5d33000     	ldrb	r3, [r3]
   1c3f0: e3530039     	cmp	r3, #57
   1c3f4: 9a000013     	bls	0x1c448 <id3_read_frame+0xd4> @ imm = #0x4c
   1c3f8: e51b3008     	ldr	r3, [r11, #-0x8]
   1c3fc: e5d33000     	ldrb	r3, [r3]
   1c400: e3530040     	cmp	r3, #64
   1c404: 9a000003     	bls	0x1c418 <id3_read_frame+0xa4> @ imm = #0xc
   1c408: e51b3008     	ldr	r3, [r11, #-0x8]
   1c40c: e5d33000     	ldrb	r3, [r3]
   1c410: e353005a     	cmp	r3, #90
   1c414: 9a00000b     	bls	0x1c448 <id3_read_frame+0xd4> @ imm = #0x2c
   1c418: e51b3018     	ldr	r3, [r11, #-0x18]
   1c41c: e5933130     	ldr	r3, [r3, #0x130]
   1c420: e51b2018     	ldr	r2, [r11, #-0x18]
   1c424: e592101c     	ldr	r1, [r2, #0x1c]
   1c428: e51b2018     	ldr	r2, [r11, #-0x18]
   1c42c: e5922020     	ldr	r2, [r2, #0x20]
   1c430: e0622001     	rsb	r2, r2, r1
   1c434: e51b0018     	ldr	r0, [r11, #-0x18]
   1c438: e1a01002     	mov	r1, r2
   1c43c: e12fff33     	blx	r3
   1c440: e3a03000     	mov	r3, #0
   1c444: ea000090     	b	0x1c68c <id3_read_frame+0x318> @ imm = #0x240
   1c448: e51b3008     	ldr	r3, [r11, #-0x8]
   1c44c: e5d33000     	ldrb	r3, [r3]
   1c450: e1a02c03     	lsl	r2, r3, #24
   1c454: e51b3008     	ldr	r3, [r11, #-0x8]
   1c458: e2833001     	add	r3, r3, #1
   1c45c: e5d33000     	ldrb	r3, [r3]
   1c460: e1a03803     	lsl	r3, r3, #16
   1c464: e1822003     	orr	r2, r2, r3
   1c468: e51b3008     	ldr	r3, [r11, #-0x8]
   1c46c: e2833002     	add	r3, r3, #2
   1c470: e5d33000     	ldrb	r3, [r3]
   1c474: e1a03403     	lsl	r3, r3, #8
   1c478: e1822003     	orr	r2, r2, r3
   1c47c: e51b3008     	ldr	r3, [r11, #-0x8]
   1c480: e2833003     	add	r3, r3, #3
   1c484: e5d33000     	ldrb	r3, [r3]
   1c488: e1823003     	orr	r3, r2, r3
   1c48c: e50b300c     	str	r3, [r11, #-0xc]
   1c490: e3a00030     	mov	r0, #48
   1c494: e3a01001     	mov	r1, #1
   1c498: ebffbfaf     	bl	0xc35c <calloc@plt>     @ imm = #-0x10144
   1c49c: e1a03000     	mov	r3, r0
   1c4a0: e50b3010     	str	r3, [r11, #-0x10]
   1c4a4: e51b3010     	ldr	r3, [r11, #-0x10]
   1c4a8: e51b2018     	ldr	r2, [r11, #-0x18]
   1c4ac: e5832000     	str	r2, [r3]
   1c4b0: e51b3008     	ldr	r3, [r11, #-0x8]
   1c4b4: e2833004     	add	r3, r3, #4
   1c4b8: e5d33000     	ldrb	r3, [r3]
   1c4bc: e1a02c03     	lsl	r2, r3, #24
   1c4c0: e51b3008     	ldr	r3, [r11, #-0x8]
   1c4c4: e2833005     	add	r3, r3, #5
   1c4c8: e5d33000     	ldrb	r3, [r3]
   1c4cc: e1a03803     	lsl	r3, r3, #16
   1c4d0: e1822003     	orr	r2, r2, r3
   1c4d4: e51b3008     	ldr	r3, [r11, #-0x8]
   1c4d8: e2833006     	add	r3, r3, #6
   1c4dc: e5d33000     	ldrb	r3, [r3]
   1c4e0: e1a03403     	lsl	r3, r3, #8
   1c4e4: e1822003     	orr	r2, r2, r3
   1c4e8: e51b3008     	ldr	r3, [r11, #-0x8]
   1c4ec: e2833007     	add	r3, r3, #7
   1c4f0: e5d33000     	ldrb	r3, [r3]
   1c4f4: e1823003     	orr	r3, r2, r3
   1c4f8: e1a02003     	mov	r2, r3
   1c4fc: e51b3010     	ldr	r3, [r11, #-0x10]
   1c500: e583201c     	str	r2, [r3, #0x1c]
   1c504: e51b3010     	ldr	r3, [r11, #-0x10]
   1c508: e593201c     	ldr	r2, [r3, #0x1c]
   1c50c: e59f3184     	ldr	r3, [pc, #0x184]        @ 0x1c698 <id3_read_frame+0x324>
   1c510: e1520003     	cmp	r2, r3
   1c514: 9a000003     	bls	0x1c528 <id3_read_frame+0x1b4> @ imm = #0xc
   1c518: e51b0010     	ldr	r0, [r11, #-0x10]
   1c51c: ebffbfbe     	bl	0xc41c <free@plt>       @ imm = #-0x10108
   1c520: e3e03000     	mvn	r3, #0
   1c524: ea000058     	b	0x1c68c <id3_read_frame+0x318> @ imm = #0x160
   1c528: e51b3008     	ldr	r3, [r11, #-0x8]
   1c52c: e2833008     	add	r3, r3, #8
   1c530: e5d33000     	ldrb	r3, [r3]
   1c534: e1a02403     	lsl	r2, r3, #8
   1c538: e51b3008     	ldr	r3, [r11, #-0x8]
   1c53c: e2833009     	add	r3, r3, #9
   1c540: e5d33000     	ldrb	r3, [r3]
   1c544: e1822003     	orr	r2, r2, r3
   1c548: e51b3010     	ldr	r3, [r11, #-0x10]
   1c54c: e5832008     	str	r2, [r3, #0x8]
   1c550: e51b000c     	ldr	r0, [r11, #-0xc]
   1c554: ebffff5f     	bl	0x1c2d8 <find_frame_description> @ imm = #-0x284
   1c558: e1a02000     	mov	r2, r0
   1c55c: e51b3010     	ldr	r3, [r11, #-0x10]
   1c560: e5832004     	str	r2, [r3, #0x4]
   1c564: e51b3010     	ldr	r3, [r11, #-0x10]
   1c568: e5933004     	ldr	r3, [r3, #0x4]
   1c56c: e3530000     	cmp	r3, #0
   1c570: 1a00000f     	bne	0x1c5b4 <id3_read_frame+0x240> @ imm = #0x3c
   1c574: e51b3018     	ldr	r3, [r11, #-0x18]
   1c578: e5933130     	ldr	r3, [r3, #0x130]
   1c57c: e51b2010     	ldr	r2, [r11, #-0x10]
   1c580: e592201c     	ldr	r2, [r2, #0x1c]
   1c584: e51b0018     	ldr	r0, [r11, #-0x18]
   1c588: e1a01002     	mov	r1, r2
   1c58c: e12fff33     	blx	r3
   1c590: e1a03000     	mov	r3, r0
   1c594: e3530000     	cmp	r3, #0
   1c598: aa000003     	bge	0x1c5ac <id3_read_frame+0x238> @ imm = #0xc
   1c59c: e51b0010     	ldr	r0, [r11, #-0x10]
   1c5a0: ebffbf9d     	bl	0xc41c <free@plt>       @ imm = #-0x1018c
   1c5a4: e3e03000     	mvn	r3, #0
   1c5a8: ea000037     	b	0x1c68c <id3_read_frame+0x318> @ imm = #0xdc
   1c5ac: e3a03000     	mov	r3, #0
   1c5b0: ea000035     	b	0x1c68c <id3_read_frame+0x318> @ imm = #0xd4
   1c5b4: e51b3010     	ldr	r3, [r11, #-0x10]
   1c5b8: e593301c     	ldr	r3, [r3, #0x1c]
   1c5bc: e2833002     	add	r3, r3, #2
   1c5c0: e1a00003     	mov	r0, r3
   1c5c4: e3a01001     	mov	r1, #1
   1c5c8: ebffbf63     	bl	0xc35c <calloc@plt>     @ imm = #-0x10274
   1c5cc: e1a03000     	mov	r3, r0
   1c5d0: e1a02003     	mov	r2, r3
   1c5d4: e51b3010     	ldr	r3, [r11, #-0x10]
   1c5d8: e5832018     	str	r2, [r3, #0x18]
   1c5dc: e51b3018     	ldr	r3, [r11, #-0x18]
   1c5e0: e5933134     	ldr	r3, [r3, #0x134]
   1c5e4: e51b2010     	ldr	r2, [r11, #-0x10]
   1c5e8: e5921018     	ldr	r1, [r2, #0x18]
   1c5ec: e51b2010     	ldr	r2, [r11, #-0x10]
   1c5f0: e592201c     	ldr	r2, [r2, #0x1c]
   1c5f4: e51b0018     	ldr	r0, [r11, #-0x18]
   1c5f8: e12fff33     	blx	r3
   1c5fc: e1a03000     	mov	r3, r0
   1c600: e3530000     	cmp	r3, #0
   1c604: 1a000007     	bne	0x1c628 <id3_read_frame+0x2b4> @ imm = #0x1c
   1c608: e51b3010     	ldr	r3, [r11, #-0x10]
   1c60c: e5933018     	ldr	r3, [r3, #0x18]
   1c610: e1a00003     	mov	r0, r3
   1c614: ebffbf80     	bl	0xc41c <free@plt>       @ imm = #-0x10200
   1c618: e51b0010     	ldr	r0, [r11, #-0x10]
   1c61c: ebffbf7e     	bl	0xc41c <free@plt>       @ imm = #-0x10208
   1c620: e3e03000     	mvn	r3, #0
   1c624: ea000018     	b	0x1c68c <id3_read_frame+0x318> @ imm = #0x60
   1c628: e51b3010     	ldr	r3, [r11, #-0x10]
   1c62c: e2832028     	add	r2, r3, #40
   1c630: e51b3018     	ldr	r3, [r11, #-0x18]
   1c634: e2833f4e     	add	r3, r3, #312
   1c638: e1a00002     	mov	r0, r2
   1c63c: e1a01003     	mov	r1, r3
   1c640: ebfffee6     	bl	0x1c1e0 <list_add_tail> @ imm = #-0x468
   1c644: e51b3010     	ldr	r3, [r11, #-0x10]
   1c648: e5933008     	ldr	r3, [r3, #0x8]
   1c64c: e2033080     	and	r3, r3, #128
   1c650: e3530000     	cmp	r3, #0
   1c654: 0a000001     	beq	0x1c660 <id3_read_frame+0x2ec> @ imm = #0x4
   1c658: e3a03000     	mov	r3, #0
   1c65c: ea00000a     	b	0x1c68c <id3_read_frame+0x318> @ imm = #0x28
   1c660: e51b0010     	ldr	r0, [r11, #-0x10]
   1c664: eb000120     	bl	0x1caec <id3_frame_get_dataptr> @ imm = #0x480
   1c668: e1a02000     	mov	r2, r0
   1c66c: e51b3010     	ldr	r3, [r11, #-0x10]
   1c670: e5832010     	str	r2, [r3, #0x10]
   1c674: e51b0010     	ldr	r0, [r11, #-0x10]
   1c678: eb00012c     	bl	0x1cb30 <id3_frame_get_size> @ imm = #0x4b0
   1c67c: e1a02000     	mov	r2, r0
   1c680: e51b3010     	ldr	r3, [r11, #-0x10]
   1c684: e5832014     	str	r2, [r3, #0x14]
   1c688: e3a03000     	mov	r3, #0
   1c68c: e1a00003     	mov	r0, r3
   1c690: e24bd004     	sub	sp, r11, #4
   1c694: e8bd8800     	pop	{r11, pc}
   1c698: 40 42 0f 00  	.word	0x000f4240

