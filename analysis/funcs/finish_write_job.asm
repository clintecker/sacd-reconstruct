0001b1a0 <finish_write_job>:
   1b1a0: e92d4800     	push	{r11, lr}
   1b1a4: e28db004     	add	r11, sp, #4
   1b1a8: e24dd010     	sub	sp, sp, #16
   1b1ac: e50b0010     	str	r0, [r11, #-0x10]
   1b1b0: e3a00018     	mov	r0, #24
   1b1b4: ebffc52b     	bl	0xc668 <malloc@plt>     @ imm = #-0xeb54
   1b1b8: e1a03000     	mov	r3, r0
   1b1bc: e50b3008     	str	r3, [r11, #-0x8]
   1b1c0: e51b3008     	ldr	r3, [r11, #-0x8]
   1b1c4: e3530000     	cmp	r3, #0
   1b1c8: 1a000001     	bne	0x1b1d4 <finish_write_job+0x34> @ imm = #0x4
   1b1cc: e3a00001     	mov	r0, #1
   1b1d0: ebffc57b     	bl	0xc7c4 <exit@plt>       @ imm = #-0xea14
   1b1d4: e51b3008     	ldr	r3, [r11, #-0x8]
   1b1d8: e3a02000     	mov	r2, #0
   1b1dc: e5832004     	str	r2, [r3, #0x4]
   1b1e0: e51b3010     	ldr	r3, [r11, #-0x10]
   1b1e4: e5932008     	ldr	r2, [r3, #0x8]
   1b1e8: e51b3008     	ldr	r3, [r11, #-0x8]
   1b1ec: e5832000     	str	r2, [r3]
   1b1f0: e51b3008     	ldr	r3, [r11, #-0x8]
   1b1f4: e3a02000     	mov	r2, #0
   1b1f8: e583200c     	str	r2, [r3, #0xc]
   1b1fc: e51b3008     	ldr	r3, [r11, #-0x8]
   1b200: e3a02000     	mov	r2, #0
   1b204: e5832010     	str	r2, [r3, #0x10]
   1b208: e51b3008     	ldr	r3, [r11, #-0x8]
   1b20c: e3a02000     	mov	r2, #0
   1b210: e5832008     	str	r2, [r3, #0x8]
   1b214: e51b3010     	ldr	r3, [r11, #-0x10]
   1b218: e5933008     	ldr	r3, [r3, #0x8]
   1b21c: e2832001     	add	r2, r3, #1
   1b220: e51b3010     	ldr	r3, [r11, #-0x10]
   1b224: e5832008     	str	r2, [r3, #0x8]
   1b228: e51b3010     	ldr	r3, [r11, #-0x10]
   1b22c: e5932048     	ldr	r2, [r3, #0x48]
   1b230: e51b3010     	ldr	r3, [r11, #-0x10]
   1b234: e5933000     	ldr	r3, [r3]
   1b238: e1520003     	cmp	r2, r3
   1b23c: aa000007     	bge	0x1b260 <finish_write_job+0xc0> @ imm = #0x1c
   1b240: e59f0090     	ldr	r0, [pc, #0x90]         @ 0x1b2d8 <finish_write_job+0x138>
   1b244: e51b1010     	ldr	r1, [r11, #-0x10]
   1b248: ebffea97     	bl	0x15cac <launch>        @ imm = #-0x55a4
   1b24c: e51b3010     	ldr	r3, [r11, #-0x10]
   1b250: e5933048     	ldr	r3, [r3, #0x48]
   1b254: e2832001     	add	r2, r3, #1
   1b258: e51b3010     	ldr	r3, [r11, #-0x10]
   1b25c: e5832048     	str	r2, [r3, #0x48]
   1b260: e51b3010     	ldr	r3, [r11, #-0x10]
   1b264: e5933034     	ldr	r3, [r3, #0x34]
   1b268: e1a00003     	mov	r0, r3
   1b26c: ebffe94f     	bl	0x157b0 <possess>       @ imm = #-0x5ac4
   1b270: e51b3008     	ldr	r3, [r11, #-0x8]
   1b274: e3a02000     	mov	r2, #0
   1b278: e5832014     	str	r2, [r3, #0x14]
   1b27c: e51b3010     	ldr	r3, [r11, #-0x10]
   1b280: e593303c     	ldr	r3, [r3, #0x3c]
   1b284: e51b2008     	ldr	r2, [r11, #-0x8]
   1b288: e5832000     	str	r2, [r3]
   1b28c: e51b3008     	ldr	r3, [r11, #-0x8]
   1b290: e2832014     	add	r2, r3, #20
   1b294: e51b3010     	ldr	r3, [r11, #-0x10]
   1b298: e583203c     	str	r2, [r3, #0x3c]
   1b29c: e51b3010     	ldr	r3, [r11, #-0x10]
   1b2a0: e5933034     	ldr	r3, [r3, #0x34]
   1b2a4: e1a00003     	mov	r0, r3
   1b2a8: e3a01001     	mov	r1, #1
   1b2ac: e3a02001     	mov	r2, #1
   1b2b0: ebffe95e     	bl	0x15830 <twist>         @ imm = #-0x5a88
   1b2b4: e51b3010     	ldr	r3, [r11, #-0x10]
   1b2b8: e593304c     	ldr	r3, [r3, #0x4c]
   1b2bc: e1a00003     	mov	r0, r3
   1b2c0: ebffead1     	bl	0x15e0c <join>          @ imm = #-0x54bc
   1b2c4: e51b3010     	ldr	r3, [r11, #-0x10]
   1b2c8: e3a02000     	mov	r2, #0
   1b2cc: e583204c     	str	r2, [r3, #0x4c]
   1b2d0: e24bd004     	sub	sp, r11, #4
   1b2d4: e8bd8800     	pop	{r11, pc}
   1b2d8: 98 ab 01 00  	.word	0x0001ab98

