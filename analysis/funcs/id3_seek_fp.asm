0001e428 <id3_seek_fp>:
   1e428: e92d4800     	push	{r11, lr}
   1e42c: e28db004     	add	r11, sp, #4
   1e430: e24dd058     	sub	sp, sp, #88
   1e434: e50b0058     	str	r0, [r11, #-0x58]
   1e438: e50b105c     	str	r1, [r11, #-0x5c]
   1e43c: e51b3058     	ldr	r3, [r11, #-0x58]
   1e440: e5932020     	ldr	r2, [r3, #0x20]
   1e444: e51b305c     	ldr	r3, [r11, #-0x5c]
   1e448: e0822003     	add	r2, r2, r3
   1e44c: e51b3058     	ldr	r3, [r11, #-0x58]
   1e450: e593301c     	ldr	r3, [r3, #0x1c]
   1e454: e1520003     	cmp	r2, r3
   1e458: ca000005     	bgt	0x1e474 <id3_seek_fp+0x4c> @ imm = #0x14
   1e45c: e51b3058     	ldr	r3, [r11, #-0x58]
   1e460: e5932020     	ldr	r2, [r3, #0x20]
   1e464: e51b305c     	ldr	r3, [r11, #-0x5c]
   1e468: e0823003     	add	r3, r2, r3
   1e46c: e3530000     	cmp	r3, #0
   1e470: aa000001     	bge	0x1e47c <id3_seek_fp+0x54> @ imm = #0x4
   1e474: e3e03000     	mvn	r3, #0
   1e478: ea000043     	b	0x1e58c <id3_seek_fp+0x164> @ imm = #0x10c
   1e47c: e51b305c     	ldr	r3, [r11, #-0x5c]
   1e480: e3530000     	cmp	r3, #0
   1e484: da000025     	ble	0x1e520 <id3_seek_fp+0xf8> @ imm = #0x94
   1e488: e51b305c     	ldr	r3, [r11, #-0x5c]
   1e48c: e50b300c     	str	r3, [r11, #-0xc]
   1e490: ea00001e     	b	0x1e510 <id3_seek_fp+0xe8> @ imm = #0x78
   1e494: e51b300c     	ldr	r3, [r11, #-0xc]
   1e498: e3530040     	cmp	r3, #64
   1e49c: a3a03040     	movge	r3, #64
   1e4a0: e50b3008     	str	r3, [r11, #-0x8]
   1e4a4: e51b2008     	ldr	r2, [r11, #-0x8]
   1e4a8: e51b3058     	ldr	r3, [r11, #-0x58]
   1e4ac: e5933128     	ldr	r3, [r3, #0x128]
   1e4b0: e24b1050     	sub	r1, r11, #80
   1e4b4: e1a00001     	mov	r0, r1
   1e4b8: e3a01001     	mov	r1, #1
   1e4bc: ebffb8a2     	bl	0xc74c <fread@plt>      @ imm = #-0x11d78
   1e4c0: e1a03000     	mov	r3, r0
   1e4c4: e50b3010     	str	r3, [r11, #-0x10]
   1e4c8: e51b3010     	ldr	r3, [r11, #-0x10]
   1e4cc: e3530000     	cmp	r3, #0
   1e4d0: 1a00000a     	bne	0x1e500 <id3_seek_fp+0xd8> @ imm = #0x28
   1e4d4: e51b3058     	ldr	r3, [r11, #-0x58]
   1e4d8: e59f20b8     	ldr	r2, [pc, #0xb8]         @ 0x1e598 <id3_seek_fp+0x170>
   1e4dc: e5832024     	str	r2, [r3, #0x24]
   1e4e0: e59f30b4     	ldr	r3, [pc, #0xb4]         @ 0x1e59c <id3_seek_fp+0x174>
   1e4e4: e1a00003     	mov	r0, r3
   1e4e8: e59f10b0     	ldr	r1, [pc, #0xb0]         @ 0x1e5a0 <id3_seek_fp+0x178>
   1e4ec: e3a020e6     	mov	r2, #230
   1e4f0: e59f30a0     	ldr	r3, [pc, #0xa0]         @ 0x1e598 <id3_seek_fp+0x170>
   1e4f4: ebffb81c     	bl	0xc56c <printf@plt>     @ imm = #-0x11f90
   1e4f8: e3e03000     	mvn	r3, #0
   1e4fc: ea000022     	b	0x1e58c <id3_seek_fp+0x164> @ imm = #0x88
   1e500: e51b200c     	ldr	r2, [r11, #-0xc]
   1e504: e51b3010     	ldr	r3, [r11, #-0x10]
   1e508: e0633002     	rsb	r3, r3, r2
   1e50c: e50b300c     	str	r3, [r11, #-0xc]
   1e510: e51b300c     	ldr	r3, [r11, #-0xc]
   1e514: e3530000     	cmp	r3, #0
   1e518: caffffdd     	bgt	0x1e494 <id3_seek_fp+0x6c> @ imm = #-0x8c
   1e51c: ea000013     	b	0x1e570 <id3_seek_fp+0x148> @ imm = #0x4c
   1e520: e51b3058     	ldr	r3, [r11, #-0x58]
   1e524: e5933128     	ldr	r3, [r3, #0x128]
   1e528: e1a00003     	mov	r0, r3
   1e52c: e51b105c     	ldr	r1, [r11, #-0x5c]
   1e530: e3a02001     	mov	r2, #1
   1e534: ebffb7ca     	bl	0xc464 <fseek@plt>      @ imm = #-0x120d8
   1e538: e1a03000     	mov	r3, r0
   1e53c: e3730001     	cmn	r3, #1
   1e540: 1a00000a     	bne	0x1e570 <id3_seek_fp+0x148> @ imm = #0x28
   1e544: e51b3058     	ldr	r3, [r11, #-0x58]
   1e548: e59f2054     	ldr	r2, [pc, #0x54]         @ 0x1e5a4 <id3_seek_fp+0x17c>
   1e54c: e5832024     	str	r2, [r3, #0x24]
   1e550: e59f3044     	ldr	r3, [pc, #0x44]         @ 0x1e59c <id3_seek_fp+0x174>
   1e554: e1a00003     	mov	r0, r3
   1e558: e59f1040     	ldr	r1, [pc, #0x40]         @ 0x1e5a0 <id3_seek_fp+0x178>
   1e55c: e3a020f4     	mov	r2, #244
   1e560: e59f303c     	ldr	r3, [pc, #0x3c]         @ 0x1e5a4 <id3_seek_fp+0x17c>
   1e564: ebffb800     	bl	0xc56c <printf@plt>     @ imm = #-0x12000
   1e568: e3e03000     	mvn	r3, #0
   1e56c: ea000006     	b	0x1e58c <id3_seek_fp+0x164> @ imm = #0x18
   1e570: e51b3058     	ldr	r3, [r11, #-0x58]
   1e574: e5932020     	ldr	r2, [r3, #0x20]
   1e578: e51b305c     	ldr	r3, [r11, #-0x5c]
   1e57c: e0822003     	add	r2, r2, r3
   1e580: e51b3058     	ldr	r3, [r11, #-0x58]
   1e584: e5832020     	str	r2, [r3, #0x20]
   1e588: e3a03000     	mov	r3, #0
   1e58c: e1a00003     	mov	r0, r3
   1e590: e24bd004     	sub	sp, r11, #4
   1e594: e8bd8800     	pop	{r11, pc}
   1e598: 80 39 03 00  	.word	0x00033980
   1e59c: 34 39 03 00  	.word	0x00033934
   1e5a0: 4c 39 03 00  	.word	0x0003394c
   1e5a4: 18 39 03 00  	.word	0x00033918

