0001e200 <id3_seek_fd>:
   1e200: e92d4800     	push	{r11, lr}
   1e204: e28db004     	add	r11, sp, #4
   1e208: e24dd010     	sub	sp, sp, #16
   1e20c: e50b0008     	str	r0, [r11, #-0x8]
   1e210: e50b100c     	str	r1, [r11, #-0xc]
   1e214: e51b3008     	ldr	r3, [r11, #-0x8]
   1e218: e5932020     	ldr	r2, [r3, #0x20]
   1e21c: e51b300c     	ldr	r3, [r11, #-0xc]
   1e220: e0822003     	add	r2, r2, r3
   1e224: e51b3008     	ldr	r3, [r11, #-0x8]
   1e228: e593301c     	ldr	r3, [r3, #0x1c]
   1e22c: e1520003     	cmp	r2, r3
   1e230: ca000005     	bgt	0x1e24c <id3_seek_fd+0x4c> @ imm = #0x14
   1e234: e51b3008     	ldr	r3, [r11, #-0x8]
   1e238: e5932020     	ldr	r2, [r3, #0x20]
   1e23c: e51b300c     	ldr	r3, [r11, #-0xc]
   1e240: e0823003     	add	r3, r2, r3
   1e244: e3530000     	cmp	r3, #0
   1e248: aa000001     	bge	0x1e254 <id3_seek_fd+0x54> @ imm = #0x4
   1e24c: e3e03000     	mvn	r3, #0
   1e250: ea000020     	b	0x1e2d8 <id3_seek_fd+0xd8> @ imm = #0x80
   1e254: e51b3008     	ldr	r3, [r11, #-0x8]
   1e258: e5931128     	ldr	r1, [r3, #0x128]
   1e25c: e51b300c     	ldr	r3, [r11, #-0xc]
   1e260: e1a02003     	mov	r2, r3
   1e264: e1a03fc2     	asr	r3, r2, #31
   1e268: e3a00001     	mov	r0, #1
   1e26c: e58d0000     	str	r0, [sp]
   1e270: e1a00001     	mov	r0, r1
   1e274: ebffb8f8     	bl	0xc65c <lseek64@plt>    @ imm = #-0x11c20
   1e278: e1a02000     	mov	r2, r0
   1e27c: e1a03001     	mov	r3, r1
   1e280: e3720001     	cmn	r2, #1
   1e284: 1a00000c     	bne	0x1e2bc <id3_seek_fd+0xbc> @ imm = #0x30
   1e288: e3730001     	cmn	r3, #1
   1e28c: 1a00000a     	bne	0x1e2bc <id3_seek_fd+0xbc> @ imm = #0x28
   1e290: e51b3008     	ldr	r3, [r11, #-0x8]
   1e294: e59f2048     	ldr	r2, [pc, #0x48]         @ 0x1e2e4 <id3_seek_fd+0xe4>
   1e298: e5832024     	str	r2, [r3, #0x24]
   1e29c: e59f3044     	ldr	r3, [pc, #0x44]         @ 0x1e2e8 <id3_seek_fd+0xe8>
   1e2a0: e1a00003     	mov	r0, r3
   1e2a4: e59f1040     	ldr	r1, [pc, #0x40]         @ 0x1e2ec <id3_seek_fd+0xec>
   1e2a8: e3a02082     	mov	r2, #130
   1e2ac: e59f3030     	ldr	r3, [pc, #0x30]         @ 0x1e2e4 <id3_seek_fd+0xe4>
   1e2b0: ebffb8ad     	bl	0xc56c <printf@plt>     @ imm = #-0x11d4c
   1e2b4: e3e03000     	mvn	r3, #0
   1e2b8: ea000006     	b	0x1e2d8 <id3_seek_fd+0xd8> @ imm = #0x18
   1e2bc: e51b3008     	ldr	r3, [r11, #-0x8]
   1e2c0: e5932020     	ldr	r2, [r3, #0x20]
   1e2c4: e51b300c     	ldr	r3, [r11, #-0xc]
   1e2c8: e0822003     	add	r2, r2, r3
   1e2cc: e51b3008     	ldr	r3, [r11, #-0x8]
   1e2d0: e5832020     	str	r2, [r3, #0x20]
   1e2d4: e3a03000     	mov	r3, #0
   1e2d8: e1a00003     	mov	r0, r3
   1e2dc: e24bd004     	sub	sp, r11, #4
   1e2e0: e8bd8800     	pop	{r11, pc}
   1e2e4: 18 39 03 00  	.word	0x00033918
   1e2e8: 34 39 03 00  	.word	0x00033934
   1e2ec: 4c 39 03 00  	.word	0x0003394c

