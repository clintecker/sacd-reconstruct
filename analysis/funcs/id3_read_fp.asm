0001e5a8 <id3_read_fp>:
   1e5a8: e92d4800     	push	{r11, lr}
   1e5ac: e28db004     	add	r11, sp, #4
   1e5b0: e24dd018     	sub	sp, sp, #24
   1e5b4: e50b0010     	str	r0, [r11, #-0x10]
   1e5b8: e50b1014     	str	r1, [r11, #-0x14]
   1e5bc: e50b2018     	str	r2, [r11, #-0x18]
   1e5c0: e51b3010     	ldr	r3, [r11, #-0x10]
   1e5c4: e5932020     	ldr	r2, [r3, #0x20]
   1e5c8: e51b3018     	ldr	r3, [r11, #-0x18]
   1e5cc: e0822003     	add	r2, r2, r3
   1e5d0: e51b3010     	ldr	r3, [r11, #-0x10]
   1e5d4: e593301c     	ldr	r3, [r3, #0x1c]
   1e5d8: e1520003     	cmp	r2, r3
   1e5dc: da000005     	ble	0x1e5f8 <id3_read_fp+0x50> @ imm = #0x14
   1e5e0: e51b3010     	ldr	r3, [r11, #-0x10]
   1e5e4: e593201c     	ldr	r2, [r3, #0x1c]
   1e5e8: e51b3010     	ldr	r3, [r11, #-0x10]
   1e5ec: e5933020     	ldr	r3, [r3, #0x20]
   1e5f0: e0633002     	rsb	r3, r3, r2
   1e5f4: e50b3018     	str	r3, [r11, #-0x18]
   1e5f8: e51b3014     	ldr	r3, [r11, #-0x14]
   1e5fc: e3530000     	cmp	r3, #0
   1e600: 1a000007     	bne	0x1e624 <id3_read_fp+0x7c> @ imm = #0x1c
   1e604: e51b3018     	ldr	r3, [r11, #-0x18]
   1e608: e3530a02     	cmp	r3, #8192
   1e60c: da000001     	ble	0x1e618 <id3_read_fp+0x70> @ imm = #0x4
   1e610: e3a03000     	mov	r3, #0
   1e614: ea000020     	b	0x1e69c <id3_read_fp+0xf4> @ imm = #0x80
   1e618: e51b3010     	ldr	r3, [r11, #-0x10]
   1e61c: e593312c     	ldr	r3, [r3, #0x12c]
   1e620: e50b3014     	str	r3, [r11, #-0x14]
   1e624: e51b2018     	ldr	r2, [r11, #-0x18]
   1e628: e51b3010     	ldr	r3, [r11, #-0x10]
   1e62c: e5933128     	ldr	r3, [r3, #0x128]
   1e630: e51b0014     	ldr	r0, [r11, #-0x14]
   1e634: e3a01001     	mov	r1, #1
   1e638: ebffb843     	bl	0xc74c <fread@plt>      @ imm = #-0x11ef4
   1e63c: e1a03000     	mov	r3, r0
   1e640: e50b3008     	str	r3, [r11, #-0x8]
   1e644: e51b2008     	ldr	r2, [r11, #-0x8]
   1e648: e51b3018     	ldr	r3, [r11, #-0x18]
   1e64c: e1520003     	cmp	r2, r3
   1e650: 0a00000a     	beq	0x1e680 <id3_read_fp+0xd8> @ imm = #0x28
   1e654: e51b3010     	ldr	r3, [r11, #-0x10]
   1e658: e59f2048     	ldr	r2, [pc, #0x48]         @ 0x1e6a8 <id3_read_fp+0x100>
   1e65c: e5832024     	str	r2, [r3, #0x24]
   1e660: e59f3044     	ldr	r3, [pc, #0x44]         @ 0x1e6ac <id3_read_fp+0x104>
   1e664: e1a00003     	mov	r0, r3
   1e668: e59f1040     	ldr	r1, [pc, #0x40]         @ 0x1e6b0 <id3_read_fp+0x108>
   1e66c: e3a02e12     	mov	r2, #288
   1e670: e59f3030     	ldr	r3, [pc, #0x30]         @ 0x1e6a8 <id3_read_fp+0x100>
   1e674: ebffb7bc     	bl	0xc56c <printf@plt>     @ imm = #-0x12110
   1e678: e3a03000     	mov	r3, #0
   1e67c: ea000006     	b	0x1e69c <id3_read_fp+0xf4> @ imm = #0x18
   1e680: e51b3010     	ldr	r3, [r11, #-0x10]
   1e684: e5932020     	ldr	r2, [r3, #0x20]
   1e688: e51b3008     	ldr	r3, [r11, #-0x8]
   1e68c: e0822003     	add	r2, r2, r3
   1e690: e51b3010     	ldr	r3, [r11, #-0x10]
   1e694: e5832020     	str	r2, [r3, #0x20]
   1e698: e51b3014     	ldr	r3, [r11, #-0x14]
   1e69c: e1a00003     	mov	r0, r3
   1e6a0: e24bd004     	sub	sp, r11, #4
   1e6a4: e8bd8800     	pop	{r11, pc}
   1e6a8: 80 39 03 00  	.word	0x00033980
   1e6ac: 34 39 03 00  	.word	0x00033934
   1e6b0: 4c 39 03 00  	.word	0x0003394c

