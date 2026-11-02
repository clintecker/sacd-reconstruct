0001e98c <id3_close>:
   1e98c: e92d4800     	push	{r11, lr}
   1e990: e28db004     	add	r11, sp, #4
   1e994: e24dd010     	sub	sp, sp, #16
   1e998: e50b0010     	str	r0, [r11, #-0x10]
   1e99c: e3a03000     	mov	r3, #0
   1e9a0: e50b3008     	str	r3, [r11, #-0x8]
   1e9a4: e51b3010     	ldr	r3, [r11, #-0x10]
   1e9a8: e5933000     	ldr	r3, [r3]
   1e9ac: e3530003     	cmp	r3, #3
   1e9b0: 979ff103     	ldrls	pc, [pc, r3, lsl #2]
   1e9b4: ea000018     	b	0x1ea1c <id3_close+0x90> @ imm = #0x60
   1e9b8: f0 e9 01 00  	.word	0x0001e9f0
   1e9bc: 1c ea 01 00  	.word	0x0001ea1c
   1e9c0: c8 e9 01 00  	.word	0x0001e9c8
   1e9c4: dc e9 01 00  	.word	0x0001e9dc
   1e9c8: e51b3010     	ldr	r3, [r11, #-0x10]
   1e9cc: e593312c     	ldr	r3, [r3, #0x12c]
   1e9d0: e1a00003     	mov	r0, r3
   1e9d4: ebffb690     	bl	0xc41c <free@plt>       @ imm = #-0x125c0
   1e9d8: ea00000f     	b	0x1ea1c <id3_close+0x90> @ imm = #0x3c
   1e9dc: e51b3010     	ldr	r3, [r11, #-0x10]
   1e9e0: e593312c     	ldr	r3, [r3, #0x12c]
   1e9e4: e1a00003     	mov	r0, r3
   1e9e8: ebffb68b     	bl	0xc41c <free@plt>       @ imm = #-0x125d4
   1e9ec: ea00000a     	b	0x1ea1c <id3_close+0x90> @ imm = #0x28
   1e9f0: e51b3010     	ldr	r3, [r11, #-0x10]
   1e9f4: e59f2040     	ldr	r2, [pc, #0x40]         @ 0x1ea3c <id3_close+0xb0>
   1e9f8: e5832024     	str	r2, [r3, #0x24]
   1e9fc: e59f303c     	ldr	r3, [pc, #0x3c]         @ 0x1ea40 <id3_close+0xb4>
   1ea00: e1a00003     	mov	r0, r3
   1ea04: e59f1038     	ldr	r1, [pc, #0x38]         @ 0x1ea44 <id3_close+0xb8>
   1ea08: e59f2038     	ldr	r2, [pc, #0x38]         @ 0x1ea48 <id3_close+0xbc>
   1ea0c: e59f3028     	ldr	r3, [pc, #0x28]         @ 0x1ea3c <id3_close+0xb0>
   1ea10: ebffb6d5     	bl	0xc56c <printf@plt>     @ imm = #-0x124ac
   1ea14: e3e03000     	mvn	r3, #0
   1ea18: e50b3008     	str	r3, [r11, #-0x8]
   1ea1c: e51b0010     	ldr	r0, [r11, #-0x10]
   1ea20: ebfff7e6     	bl	0x1c9c0 <id3_destroy_frames> @ imm = #-0x2068
   1ea24: e51b0010     	ldr	r0, [r11, #-0x10]
   1ea28: ebffb67b     	bl	0xc41c <free@plt>       @ imm = #-0x12614
   1ea2c: e51b3008     	ldr	r3, [r11, #-0x8]
   1ea30: e1a00003     	mov	r0, r3
   1ea34: e24bd004     	sub	sp, r11, #4
   1ea38: e8bd8800     	pop	{r11, pc}
   1ea3c: 90 39 03 00  	.word	0x00033990
   1ea40: 34 39 03 00  	.word	0x00033934
   1ea44: 4c 39 03 00  	.word	0x0003394c
   1ea48: e9 01 00 00  	.word	0x000001e9

