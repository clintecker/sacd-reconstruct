00022954 <sacd_input_setup>:
   22954: e92d4800     	push	{r11, lr}
   22958: e28db004     	add	r11, sp, #4
   2295c: e24dd018     	sub	sp, sp, #24
   22960: e50b0018     	str	r0, [r11, #-0x18]
   22964: e3a03000     	mov	r3, #0
   22968: e50b3010     	str	r3, [r11, #-0x10]
   2296c: e3a03000     	mov	r3, #0
   22970: e50b300c     	str	r3, [r11, #-0xc]
   22974: e51b3018     	ldr	r3, [r11, #-0x18]
   22978: e50b3008     	str	r3, [r11, #-0x8]
   2297c: ea000010     	b	0x229c4 <sacd_input_setup+0x70> @ imm = #0x40
   22980: e51b300c     	ldr	r3, [r11, #-0xc]
   22984: e2833001     	add	r3, r3, #1
   22988: e50b300c     	str	r3, [r11, #-0xc]
   2298c: e51b300c     	ldr	r3, [r11, #-0xc]
   22990: e3530003     	cmp	r3, #3
   22994: 1a00000a     	bne	0x229c4 <sacd_input_setup+0x70> @ imm = #0x28
   22998: e51b3008     	ldr	r3, [r11, #-0x8]
   2299c: e2833001     	add	r3, r3, #1
   229a0: e1a00003     	mov	r0, r3
   229a4: e3a0103a     	mov	r1, #58
   229a8: ebffa65f     	bl	0xc32c <strchr@plt>     @ imm = #-0x16684
   229ac: e1a03000     	mov	r3, r0
   229b0: e3530000     	cmp	r3, #0
   229b4: 0a000002     	beq	0x229c4 <sacd_input_setup+0x70> @ imm = #0x8
   229b8: e3a03001     	mov	r3, #1
   229bc: e50b3010     	str	r3, [r11, #-0x10]
   229c0: ea000009     	b	0x229ec <sacd_input_setup+0x98> @ imm = #0x24
   229c4: e51b3008     	ldr	r3, [r11, #-0x8]
   229c8: e2833001     	add	r3, r3, #1
   229cc: e1a00003     	mov	r0, r3
   229d0: e3a0102e     	mov	r1, #46
   229d4: ebffa654     	bl	0xc32c <strchr@plt>     @ imm = #-0x166b0
   229d8: e1a03000     	mov	r3, r0
   229dc: e50b3008     	str	r3, [r11, #-0x8]
   229e0: e51b3008     	ldr	r3, [r11, #-0x8]
   229e4: e3530000     	cmp	r3, #0
   229e8: 1affffe4     	bne	0x22980 <sacd_input_setup+0x2c> @ imm = #-0x70
   229ec: e51b3010     	ldr	r3, [r11, #-0x10]
   229f0: e3530000     	cmp	r3, #0
   229f4: 0a000019     	beq	0x22a60 <sacd_input_setup+0x10c> @ imm = #0x64
   229f8: e59f3150     	ldr	r3, [pc, #0x150]        @ 0x22b50 <sacd_input_setup+0x1fc>
   229fc: e59f2150     	ldr	r2, [pc, #0x150]        @ 0x22b54 <sacd_input_setup+0x200>
   22a00: e5832000     	str	r2, [r3]
   22a04: e59f314c     	ldr	r3, [pc, #0x14c]        @ 0x22b58 <sacd_input_setup+0x204>
   22a08: e59f214c     	ldr	r2, [pc, #0x14c]        @ 0x22b5c <sacd_input_setup+0x208>
   22a0c: e5832000     	str	r2, [r3]
   22a10: e59f3148     	ldr	r3, [pc, #0x148]        @ 0x22b60 <sacd_input_setup+0x20c>
   22a14: e59f2148     	ldr	r2, [pc, #0x148]        @ 0x22b64 <sacd_input_setup+0x210>
   22a18: e5832000     	str	r2, [r3]
   22a1c: e59f3144     	ldr	r3, [pc, #0x144]        @ 0x22b68 <sacd_input_setup+0x214>
   22a20: e59f213c     	ldr	r2, [pc, #0x13c]        @ 0x22b64 <sacd_input_setup+0x210>
   22a24: e5832000     	str	r2, [r3]
   22a28: e59f313c     	ldr	r3, [pc, #0x13c]        @ 0x22b6c <sacd_input_setup+0x218>
   22a2c: e59f213c     	ldr	r2, [pc, #0x13c]        @ 0x22b70 <sacd_input_setup+0x21c>
   22a30: e5832000     	str	r2, [r3]
   22a34: e59f3138     	ldr	r3, [pc, #0x138]        @ 0x22b74 <sacd_input_setup+0x220>
   22a38: e59f2138     	ldr	r2, [pc, #0x138]        @ 0x22b78 <sacd_input_setup+0x224>
   22a3c: e5832000     	str	r2, [r3]
   22a40: e59f3134     	ldr	r3, [pc, #0x134]        @ 0x22b7c <sacd_input_setup+0x228>
   22a44: e59f2134     	ldr	r2, [pc, #0x134]        @ 0x22b80 <sacd_input_setup+0x22c>
   22a48: e5832000     	str	r2, [r3]
   22a4c: e59f3130     	ldr	r3, [pc, #0x130]        @ 0x22b84 <sacd_input_setup+0x230>
   22a50: e59f2130     	ldr	r2, [pc, #0x130]        @ 0x22b88 <sacd_input_setup+0x234>
   22a54: e5832000     	str	r2, [r3]
   22a58: e3a03001     	mov	r3, #1
   22a5c: ea000038     	b	0x22b44 <sacd_input_setup+0x1f0> @ imm = #0xe0
   22a60: e51b0018     	ldr	r0, [r11, #-0x18]
   22a64: e59f1120     	ldr	r1, [pc, #0x120]        @ 0x22b8c <sacd_input_setup+0x238>
   22a68: ebffa752     	bl	0xc7b8 <strcmp@plt>     @ imm = #-0x162b8
   22a6c: e1a03000     	mov	r3, r0
   22a70: e3530000     	cmp	r3, #0
   22a74: 1a000019     	bne	0x22ae0 <sacd_input_setup+0x18c> @ imm = #0x64
   22a78: e59f30d0     	ldr	r3, [pc, #0xd0]         @ 0x22b50 <sacd_input_setup+0x1fc>
   22a7c: e59f210c     	ldr	r2, [pc, #0x10c]        @ 0x22b90 <sacd_input_setup+0x23c>
   22a80: e5832000     	str	r2, [r3]
   22a84: e59f30cc     	ldr	r3, [pc, #0xcc]         @ 0x22b58 <sacd_input_setup+0x204>
   22a88: e59f2104     	ldr	r2, [pc, #0x104]        @ 0x22b94 <sacd_input_setup+0x240>
   22a8c: e5832000     	str	r2, [r3]
   22a90: e59f30c8     	ldr	r3, [pc, #0xc8]         @ 0x22b60 <sacd_input_setup+0x20c>
   22a94: e59f20fc     	ldr	r2, [pc, #0xfc]         @ 0x22b98 <sacd_input_setup+0x244>
   22a98: e5832000     	str	r2, [r3]
   22a9c: e59f30c4     	ldr	r3, [pc, #0xc4]         @ 0x22b68 <sacd_input_setup+0x214>
   22aa0: e59f20f4     	ldr	r2, [pc, #0xf4]         @ 0x22b9c <sacd_input_setup+0x248>
   22aa4: e5832000     	str	r2, [r3]
   22aa8: e59f30bc     	ldr	r3, [pc, #0xbc]         @ 0x22b6c <sacd_input_setup+0x218>
   22aac: e59f20bc     	ldr	r2, [pc, #0xbc]         @ 0x22b70 <sacd_input_setup+0x21c>
   22ab0: e5832000     	str	r2, [r3]
   22ab4: e59f30b8     	ldr	r3, [pc, #0xb8]         @ 0x22b74 <sacd_input_setup+0x220>
   22ab8: e59f20e0     	ldr	r2, [pc, #0xe0]         @ 0x22ba0 <sacd_input_setup+0x24c>
   22abc: e5832000     	str	r2, [r3]
   22ac0: e59f30b4     	ldr	r3, [pc, #0xb4]         @ 0x22b7c <sacd_input_setup+0x228>
   22ac4: e59f20d8     	ldr	r2, [pc, #0xd8]         @ 0x22ba4 <sacd_input_setup+0x250>
   22ac8: e5832000     	str	r2, [r3]
   22acc: e59f30b0     	ldr	r3, [pc, #0xb0]         @ 0x22b84 <sacd_input_setup+0x230>
   22ad0: e59f20d0     	ldr	r2, [pc, #0xd0]         @ 0x22ba8 <sacd_input_setup+0x254>
   22ad4: e5832000     	str	r2, [r3]
   22ad8: e3a03002     	mov	r3, #2
   22adc: ea000018     	b	0x22b44 <sacd_input_setup+0x1f0> @ imm = #0x60
   22ae0: e59f3068     	ldr	r3, [pc, #0x68]         @ 0x22b50 <sacd_input_setup+0x1fc>
   22ae4: e59f20a4     	ldr	r2, [pc, #0xa4]         @ 0x22b90 <sacd_input_setup+0x23c>
   22ae8: e5832000     	str	r2, [r3]
   22aec: e59f3064     	ldr	r3, [pc, #0x64]         @ 0x22b58 <sacd_input_setup+0x204>
   22af0: e59f209c     	ldr	r2, [pc, #0x9c]         @ 0x22b94 <sacd_input_setup+0x240>
   22af4: e5832000     	str	r2, [r3]
   22af8: e59f3060     	ldr	r3, [pc, #0x60]         @ 0x22b60 <sacd_input_setup+0x20c>
   22afc: e59f2094     	ldr	r2, [pc, #0x94]         @ 0x22b98 <sacd_input_setup+0x244>
   22b00: e5832000     	str	r2, [r3]
   22b04: e59f305c     	ldr	r3, [pc, #0x5c]         @ 0x22b68 <sacd_input_setup+0x214>
   22b08: e59f2088     	ldr	r2, [pc, #0x88]         @ 0x22b98 <sacd_input_setup+0x244>
   22b0c: e5832000     	str	r2, [r3]
   22b10: e59f3054     	ldr	r3, [pc, #0x54]         @ 0x22b6c <sacd_input_setup+0x218>
   22b14: e59f2054     	ldr	r2, [pc, #0x54]         @ 0x22b70 <sacd_input_setup+0x21c>
   22b18: e5832000     	str	r2, [r3]
   22b1c: e59f3050     	ldr	r3, [pc, #0x50]         @ 0x22b74 <sacd_input_setup+0x220>
   22b20: e59f2050     	ldr	r2, [pc, #0x50]         @ 0x22b78 <sacd_input_setup+0x224>
   22b24: e5832000     	str	r2, [r3]
   22b28: e59f304c     	ldr	r3, [pc, #0x4c]         @ 0x22b7c <sacd_input_setup+0x228>
   22b2c: e59f204c     	ldr	r2, [pc, #0x4c]         @ 0x22b80 <sacd_input_setup+0x22c>
   22b30: e5832000     	str	r2, [r3]
   22b34: e59f3048     	ldr	r3, [pc, #0x48]         @ 0x22b84 <sacd_input_setup+0x230>
   22b38: e59f2068     	ldr	r2, [pc, #0x68]         @ 0x22ba8 <sacd_input_setup+0x254>
   22b3c: e5832000     	str	r2, [r3]
   22b40: e3a03000     	mov	r3, #0
   22b44: e1a00003     	mov	r0, r3
   22b48: e24bd004     	sub	sp, r11, #4
   22b4c: e8bd8800     	pop	{r11, pc}
   22b50: 10 9e 05 00  	.word	0x00059e10
   22b54: 18 22 02 00  	.word	0x00022218
   22b58: 18 9e 05 00  	.word	0x00059e18
   22b5c: 38 25 02 00  	.word	0x00022538
   22b60: 14 9e 05 00  	.word	0x00059e14
   22b64: a0 27 02 00  	.word	0x000227a0
   22b68: 04 9e 05 00  	.word	0x00059e04
   22b6c: 08 9e 05 00  	.word	0x00059e08
   22b70: 8c 1e 02 00  	.word	0x00021e8c
   22b74: 0c 9e 05 00  	.word	0x00059e0c
   22b78: c8 21 02 00  	.word	0x000221c8
   22b7c: fc 9d 05 00  	.word	0x00059dfc
   22b80: ec 21 02 00  	.word	0x000221ec
   22b84: 00 9e 05 00  	.word	0x00059e00
   22b88: 94 26 02 00  	.word	0x00022694
   22b8c: 1c 55 03 00  	.word	0x0003551c
   22b90: a4 1d 02 00  	.word	0x00021da4
   22b94: 80 20 02 00  	.word	0x00022080
   22b98: b4 1e 02 00  	.word	0x00021eb4
   22b9c: 28 20 02 00  	.word	0x00022028
   22ba0: c4 1c 02 00  	.word	0x00021cc4
   22ba4: 2c 1d 02 00  	.word	0x00021d2c
   22ba8: e0 20 02 00  	.word	0x000220e0

