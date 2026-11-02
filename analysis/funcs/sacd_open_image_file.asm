0002e5a4 <sacd_open_image_file>:
   2e5a4: e92d4800     	push	{r11, lr}
   2e5a8: e28db004     	add	r11, sp, #4
   2e5ac: e24dd010     	sub	sp, sp, #16
   2e5b0: e50b0010     	str	r0, [r11, #-0x10]
   2e5b4: e51b0010     	ldr	r0, [r11, #-0x10]
   2e5b8: ebffd0e5     	bl	0x22954 <sacd_input_setup> @ imm = #-0xbc6c
   2e5bc: e59f30a0     	ldr	r3, [pc, #0xa0]         @ 0x2e664 <sacd_open_image_file+0xc0>
   2e5c0: e5933000     	ldr	r3, [r3]
   2e5c4: e51b0010     	ldr	r0, [r11, #-0x10]
   2e5c8: e12fff33     	blx	r3
   2e5cc: e1a03000     	mov	r3, r0
   2e5d0: e50b3008     	str	r3, [r11, #-0x8]
   2e5d4: e51b3008     	ldr	r3, [r11, #-0x8]
   2e5d8: e3530000     	cmp	r3, #0
   2e5dc: 1a000009     	bne	0x2e608 <sacd_open_image_file+0x64> @ imm = #0x24
   2e5e0: e59f3080     	ldr	r3, [pc, #0x80]         @ 0x2e668 <sacd_open_image_file+0xc4>
   2e5e4: e5933000     	ldr	r3, [r3]
   2e5e8: e1a02003     	mov	r2, r3
   2e5ec: e59f3078     	ldr	r3, [pc, #0x78]         @ 0x2e66c <sacd_open_image_file+0xc8>
   2e5f0: e1a00002     	mov	r0, r2
   2e5f4: e1a01003     	mov	r1, r3
   2e5f8: e51b2010     	ldr	r2, [r11, #-0x10]
   2e5fc: ebff7810     	bl	0xc644 <fprintf@plt>    @ imm = #-0x21fc0
   2e600: e3a03000     	mov	r3, #0
   2e604: ea000013     	b	0x2e658 <sacd_open_image_file+0xb4> @ imm = #0x4c
   2e608: e3a00008     	mov	r0, #8
   2e60c: ebff7815     	bl	0xc668 <malloc@plt>     @ imm = #-0x21fac
   2e610: e1a03000     	mov	r3, r0
   2e614: e50b300c     	str	r3, [r11, #-0xc]
   2e618: e51b300c     	ldr	r3, [r11, #-0xc]
   2e61c: e3530000     	cmp	r3, #0
   2e620: 1a000005     	bne	0x2e63c <sacd_open_image_file+0x98> @ imm = #0x14
   2e624: e59f3044     	ldr	r3, [pc, #0x44]         @ 0x2e670 <sacd_open_image_file+0xcc>
   2e628: e5933000     	ldr	r3, [r3]
   2e62c: e51b0008     	ldr	r0, [r11, #-0x8]
   2e630: e12fff33     	blx	r3
   2e634: e3a03000     	mov	r3, #0
   2e638: ea000006     	b	0x2e658 <sacd_open_image_file+0xb4> @ imm = #0x18
   2e63c: e51b300c     	ldr	r3, [r11, #-0xc]
   2e640: e3a02001     	mov	r2, #1
   2e644: e5832000     	str	r2, [r3]
   2e648: e51b300c     	ldr	r3, [r11, #-0xc]
   2e64c: e51b2008     	ldr	r2, [r11, #-0x8]
   2e650: e5832004     	str	r2, [r3, #0x4]
   2e654: e51b300c     	ldr	r3, [r11, #-0xc]
   2e658: e1a00003     	mov	r0, r3
   2e65c: e24bd004     	sub	sp, r11, #4
   2e660: e8bd8800     	pop	{r11, pc}
   2e664: 10 9e 05 00  	.word	0x00059e10
   2e668: f8 6d 05 00  	.word	0x00056df8
   2e66c: 18 5e 03 00  	.word	0x00035e18
   2e670: 18 9e 05 00  	.word	0x00059e18

