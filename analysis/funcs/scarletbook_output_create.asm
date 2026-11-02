00028c3c <scarletbook_output_create>:
   28c3c: e92d4800     	push	{r11, lr}
   28c40: e28db004     	add	r11, sp, #4
   28c44: e24dd018     	sub	sp, sp, #24
   28c48: e50b0010     	str	r0, [r11, #-0x10]
   28c4c: e50b1014     	str	r1, [r11, #-0x14]
   28c50: e50b2018     	str	r2, [r11, #-0x18]
   28c54: e50b301c     	str	r3, [r11, #-0x1c]
   28c58: e3a00001     	mov	r0, #1
   28c5c: e3a01040     	mov	r1, #64
   28c60: ebff8dbd     	bl	0xc35c <calloc@plt>     @ imm = #-0x1c90c
   28c64: e1a03000     	mov	r3, r0
   28c68: e50b3008     	str	r3, [r11, #-0x8]
   28c6c: e51b3008     	ldr	r3, [r11, #-0x8]
   28c70: e1a00003     	mov	r0, r3
   28c74: ebfffac2     	bl	0x27784 <INIT_LIST_HEAD> @ imm = #-0x14f8
   28c78: e59f0050     	ldr	r0, [pc, #0x50]         @ 0x28cd0 <scarletbook_output_create+0x94>
   28c7c: ebff8e79     	bl	0xc668 <malloc@plt>     @ imm = #-0x1c61c
   28c80: e1a03000     	mov	r3, r0
   28c84: e1a02003     	mov	r2, r3
   28c88: e51b3008     	ldr	r3, [r11, #-0x8]
   28c8c: e5832008     	str	r2, [r3, #0x8]
   28c90: e51b3008     	ldr	r3, [r11, #-0x8]
   28c94: e51b2010     	ldr	r2, [r11, #-0x10]
   28c98: e583203c     	str	r2, [r3, #0x3c]
   28c9c: e51b3008     	ldr	r3, [r11, #-0x8]
   28ca0: e51b2014     	ldr	r2, [r11, #-0x14]
   28ca4: e5832034     	str	r2, [r3, #0x34]
   28ca8: e51b3008     	ldr	r3, [r11, #-0x8]
   28cac: e51b2018     	ldr	r2, [r11, #-0x18]
   28cb0: e5832030     	str	r2, [r3, #0x30]
   28cb4: e51b3008     	ldr	r3, [r11, #-0x8]
   28cb8: e51b201c     	ldr	r2, [r11, #-0x1c]
   28cbc: e5832038     	str	r2, [r3, #0x38]
   28cc0: e51b3008     	ldr	r3, [r11, #-0x8]
   28cc4: e1a00003     	mov	r0, r3
   28cc8: e24bd004     	sub	sp, r11, #4
   28ccc: e8bd8800     	pop	{r11, pc}
   28cd0: 00 08 04 00  	.word	0x00040800

