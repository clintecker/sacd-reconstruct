0001b2dc <dst_decoder_create>:
   1b2dc: e92d4800     	push	{r11, lr}
   1b2e0: e28db004     	add	r11, sp, #4
   1b2e4: e24dd018     	sub	sp, sp, #24
   1b2e8: e50b0010     	str	r0, [r11, #-0x10]
   1b2ec: e50b1014     	str	r1, [r11, #-0x14]
   1b2f0: e50b2018     	str	r2, [r11, #-0x18]
   1b2f4: e50b301c     	str	r3, [r11, #-0x1c]
   1b2f8: e3a0005c     	mov	r0, #92
   1b2fc: e3a01001     	mov	r1, #1
   1b300: ebffc415     	bl	0xc35c <calloc@plt>     @ imm = #-0xefac
   1b304: e1a03000     	mov	r3, r0
   1b308: e50b3008     	str	r3, [r11, #-0x8]
   1b30c: e51b3008     	ldr	r3, [r11, #-0x8]
   1b310: e3530000     	cmp	r3, #0
   1b314: 1a000001     	bne	0x1b320 <dst_decoder_create+0x44> @ imm = #0x4
   1b318: e3a00001     	mov	r0, #1
   1b31c: ebffc528     	bl	0xc7c4 <exit@plt>       @ imm = #-0xeb60
   1b320: e51b3014     	ldr	r3, [r11, #-0x14]
   1b324: e3530000     	cmp	r3, #0
   1b328: 1a000004     	bne	0x1b340 <dst_decoder_create+0x64> @ imm = #0x10
   1b32c: e59f0080     	ldr	r0, [pc, #0x80]         @ 0x1b3b4 <dst_decoder_create+0xd8>
   1b330: e59f1080     	ldr	r1, [pc, #0x80]         @ 0x1b3b8 <dst_decoder_create+0xdc>
   1b334: e59f2080     	ldr	r2, [pc, #0x80]         @ 0x1b3bc <dst_decoder_create+0xe0>
   1b338: e59f3080     	ldr	r3, [pc, #0x80]         @ 0x1b3c0 <dst_decoder_create+0xe4>
   1b33c: ebffc427     	bl	0xc3e0 <__assert_fail@plt> @ imm = #-0xef64
   1b340: e51b3008     	ldr	r3, [r11, #-0x8]
   1b344: e51b2010     	ldr	r2, [r11, #-0x10]
   1b348: e5832004     	str	r2, [r3, #0x4]
   1b34c: e51b3008     	ldr	r3, [r11, #-0x8]
   1b350: e51b201c     	ldr	r2, [r11, #-0x1c]
   1b354: e5832058     	str	r2, [r3, #0x58]
   1b358: e51b3008     	ldr	r3, [r11, #-0x8]
   1b35c: e51b2014     	ldr	r2, [r11, #-0x14]
   1b360: e5832050     	str	r2, [r3, #0x50]
   1b364: e51b3008     	ldr	r3, [r11, #-0x8]
   1b368: e51b2018     	ldr	r2, [r11, #-0x18]
   1b36c: e5832054     	str	r2, [r3, #0x54]
   1b370: ebfffd69     	bl	0x1a91c <processor_count> @ imm = #-0xa5c
   1b374: e1a03000     	mov	r3, r0
   1b378: e1a02003     	mov	r2, r3
   1b37c: e51b3008     	ldr	r3, [r11, #-0x8]
   1b380: e5832000     	str	r2, [r3]
   1b384: e51b0008     	ldr	r0, [r11, #-0x8]
   1b388: ebfffd69     	bl	0x1a934 <setup_decoding_jobs> @ imm = #-0xa5c
   1b38c: e59f0030     	ldr	r0, [pc, #0x30]         @ 0x1b3c4 <dst_decoder_create+0xe8>
   1b390: e51b1008     	ldr	r1, [r11, #-0x8]
   1b394: ebffea44     	bl	0x15cac <launch>        @ imm = #-0x56f0
   1b398: e1a02000     	mov	r2, r0
   1b39c: e51b3008     	ldr	r3, [r11, #-0x8]
   1b3a0: e583204c     	str	r2, [r3, #0x4c]
   1b3a4: e51b3008     	ldr	r3, [r11, #-0x8]
   1b3a8: e1a00003     	mov	r0, r3
   1b3ac: e24bd004     	sub	sp, r11, #4
   1b3b0: e8bd8800     	pop	{r11, pc}
   1b3b4: 44 30 03 00  	.word	0x00033044
   1b3b8: e8 2e 03 00  	.word	0x00032ee8
   1b3bc: 63 01 00 00  	.word	0x00000163
   1b3c0: 5c 30 03 00  	.word	0x0003305c
   1b3c4: 38 af 01 00  	.word	0x0001af38

