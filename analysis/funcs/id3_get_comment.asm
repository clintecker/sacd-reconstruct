0001dde4 <id3_get_comment>:
   1dde4: e92d4800     	push	{r11, lr}
   1dde8: e28db004     	add	r11, sp, #4
   1ddec: e24dd010     	sub	sp, sp, #16
   1ddf0: e50b0010     	str	r0, [r11, #-0x10]
   1ddf4: e51b3010     	ldr	r3, [r11, #-0x10]
   1ddf8: e5933004     	ldr	r3, [r3, #0x4]
   1ddfc: e5932000     	ldr	r2, [r3]
   1de00: e59f30e4     	ldr	r3, [pc, #0xe4]         @ 0x1deec <id3_get_comment+0x108>
   1de04: e1520003     	cmp	r2, r3
   1de08: 0a000001     	beq	0x1de14 <id3_get_comment+0x30> @ imm = #0x4
   1de0c: e3a03000     	mov	r3, #0
   1de10: ea000032     	b	0x1dee0 <id3_get_comment+0xfc> @ imm = #0xc8
   1de14: e51b0010     	ldr	r0, [r11, #-0x10]
   1de18: ebfffa58     	bl	0x1c780 <id3_decompress_frame> @ imm = #-0x16a0
   1de1c: e1a03000     	mov	r3, r0
   1de20: e3730001     	cmn	r3, #1
   1de24: 1a000001     	bne	0x1de30 <id3_get_comment+0x4c> @ imm = #0x4
   1de28: e3a03000     	mov	r3, #0
   1de2c: ea00002b     	b	0x1dee0 <id3_get_comment+0xfc> @ imm = #0xac
   1de30: e51b3010     	ldr	r3, [r11, #-0x10]
   1de34: e5933014     	ldr	r3, [r3, #0x14]
   1de38: e3530004     	cmp	r3, #4
   1de3c: ca000001     	bgt	0x1de48 <id3_get_comment+0x64> @ imm = #0x4
   1de40: e3a03000     	mov	r3, #0
   1de44: ea000025     	b	0x1dee0 <id3_get_comment+0xfc> @ imm = #0x94
   1de48: e3a03003     	mov	r3, #3
   1de4c: e50b3008     	str	r3, [r11, #-0x8]
   1de50: e51b3010     	ldr	r3, [r11, #-0x10]
   1de54: e5933010     	ldr	r3, [r3, #0x10]
   1de58: e5d32000     	ldrb	r2, [r3]
   1de5c: e51b3010     	ldr	r3, [r11, #-0x10]
   1de60: e5933010     	ldr	r3, [r3, #0x10]
   1de64: e1a01003     	mov	r1, r3
   1de68: e51b3008     	ldr	r3, [r11, #-0x8]
   1de6c: e2833001     	add	r3, r3, #1
   1de70: e0813003     	add	r3, r1, r3
   1de74: e1a00002     	mov	r0, r2
   1de78: e1a01003     	mov	r1, r3
   1de7c: ebfffd4d     	bl	0x1d3b8 <id3_string_size> @ imm = #-0xacc
   1de80: e1a02000     	mov	r2, r0
   1de84: e51b3008     	ldr	r3, [r11, #-0x8]
   1de88: e0823003     	add	r3, r2, r3
   1de8c: e50b3008     	str	r3, [r11, #-0x8]
   1de90: e51b3010     	ldr	r3, [r11, #-0x10]
   1de94: e5932014     	ldr	r2, [r3, #0x14]
   1de98: e51b3008     	ldr	r3, [r11, #-0x8]
   1de9c: e1520003     	cmp	r2, r3
   1dea0: ca000001     	bgt	0x1deac <id3_get_comment+0xc8> @ imm = #0x4
   1dea4: e3a03000     	mov	r3, #0
   1dea8: ea00000c     	b	0x1dee0 <id3_get_comment+0xfc> @ imm = #0x30
   1deac: e51b3010     	ldr	r3, [r11, #-0x10]
   1deb0: e5933010     	ldr	r3, [r3, #0x10]
   1deb4: e5d32000     	ldrb	r2, [r3]
   1deb8: e51b3010     	ldr	r3, [r11, #-0x10]
   1debc: e5933010     	ldr	r3, [r3, #0x10]
   1dec0: e1a01003     	mov	r1, r3
   1dec4: e51b3008     	ldr	r3, [r11, #-0x8]
   1dec8: e2833001     	add	r3, r3, #1
   1decc: e0813003     	add	r3, r1, r3
   1ded0: e1a00002     	mov	r0, r2
   1ded4: e1a01003     	mov	r1, r3
   1ded8: ebfffd64     	bl	0x1d470 <id3_string_decode> @ imm = #-0xa70
   1dedc: e1a03000     	mov	r3, r0
   1dee0: e1a00003     	mov	r0, r3
   1dee4: e24bd004     	sub	sp, r11, #4
   1dee8: e8bd8800     	pop	{r11, pc}
   1deec: 4d 4d 4f 43  	.word	0x434f4d4d

