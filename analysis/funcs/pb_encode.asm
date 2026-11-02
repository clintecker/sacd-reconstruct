00011a8c <pb_encode>:
   11a8c: e92d4800     	push	{r11, lr}
   11a90: e28db004     	add	r11, sp, #4
   11a94: e24dd030     	sub	sp, sp, #48
   11a98: e50b0020     	str	r0, [r11, #-0x20]
   11a9c: e50b1024     	str	r1, [r11, #-0x24]
   11aa0: e50b2028     	str	r2, [r11, #-0x28]
   11aa4: e51b3024     	ldr	r3, [r11, #-0x24]
   11aa8: e50b301c     	str	r3, [r11, #-0x1c]
   11aac: e51b3028     	ldr	r3, [r11, #-0x28]
   11ab0: e50b3018     	str	r3, [r11, #-0x18]
   11ab4: e3a03000     	mov	r3, #0
   11ab8: e50b3010     	str	r3, [r11, #-0x10]
   11abc: ea000096     	b	0x11d1c <pb_encode+0x290> @ imm = #0x258
   11ac0: e51b301c     	ldr	r3, [r11, #-0x1c]
   11ac4: e5d33002     	ldrb	r3, [r3, #0x2]
   11ac8: e1a02003     	mov	r2, r3
   11acc: e51b3010     	ldr	r3, [r11, #-0x10]
   11ad0: e0823003     	add	r3, r2, r3
   11ad4: e51b2018     	ldr	r2, [r11, #-0x18]
   11ad8: e0823003     	add	r3, r2, r3
   11adc: e50b3018     	str	r3, [r11, #-0x18]
   11ae0: e51b301c     	ldr	r3, [r11, #-0x1c]
   11ae4: e5d33003     	ldrb	r3, [r3, #0x3]
   11ae8: e6af3073     	sxtb	r3, r3
   11aec: e51b2018     	ldr	r2, [r11, #-0x18]
   11af0: e0823003     	add	r3, r2, r3
   11af4: e50b3014     	str	r3, [r11, #-0x14]
   11af8: e51b301c     	ldr	r3, [r11, #-0x1c]
   11afc: e5d32004     	ldrb	r2, [r3, #0x4]
   11b00: e5d31005     	ldrb	r1, [r3, #0x5]
   11b04: e1a01401     	lsl	r1, r1, #8
   11b08: e1812002     	orr	r2, r1, r2
   11b0c: e5d31006     	ldrb	r1, [r3, #0x6]
   11b10: e1a01801     	lsl	r1, r1, #16
   11b14: e1812002     	orr	r2, r1, r2
   11b18: e5d33007     	ldrb	r3, [r3, #0x7]
   11b1c: e1a03c03     	lsl	r3, r3, #24
   11b20: e1833002     	orr	r3, r3, r2
   11b24: e50b3010     	str	r3, [r11, #-0x10]
   11b28: e51b301c     	ldr	r3, [r11, #-0x1c]
   11b2c: e5d33001     	ldrb	r3, [r3, #0x1]
   11b30: e20330f0     	and	r3, r3, #240
   11b34: e3530020     	cmp	r3, #32
   11b38: 1a000005     	bne	0x11b54 <pb_encode+0xc8> @ imm = #0x14
   11b3c: e51b301c     	ldr	r3, [r11, #-0x1c]
   11b40: e5d33008     	ldrb	r3, [r3, #0x8]
   11b44: e1a02003     	mov	r2, r3
   11b48: e51b3010     	ldr	r3, [r11, #-0x10]
   11b4c: e0030392     	mul	r3, r2, r3
   11b50: e50b3010     	str	r3, [r11, #-0x10]
   11b54: e51b301c     	ldr	r3, [r11, #-0x1c]
   11b58: e5d33001     	ldrb	r3, [r3, #0x1]
   11b5c: e203200f     	and	r2, r3, #15
   11b60: e59f31d4     	ldr	r3, [pc, #0x1d4]        @ 0x11d3c <pb_encode+0x2b0>
   11b64: e7933102     	ldr	r3, [r3, r2, lsl #2]
   11b68: e50b300c     	str	r3, [r11, #-0xc]
   11b6c: e51b301c     	ldr	r3, [r11, #-0x1c]
   11b70: e5d33001     	ldrb	r3, [r3, #0x1]
   11b74: e20330f0     	and	r3, r3, #240
   11b78: e3530010     	cmp	r3, #16
   11b7c: 0a00001f     	beq	0x11c00 <pb_encode+0x174> @ imm = #0x7c
   11b80: e3530010     	cmp	r3, #16
   11b84: ca000002     	bgt	0x11b94 <pb_encode+0x108> @ imm = #0x8
   11b88: e3530000     	cmp	r3, #0
   11b8c: 0a000005     	beq	0x11ba8 <pb_encode+0x11c> @ imm = #0x14
   11b90: ea00005e     	b	0x11d10 <pb_encode+0x284> @ imm = #0x178
   11b94: e3530020     	cmp	r3, #32
   11b98: 0a000032     	beq	0x11c68 <pb_encode+0x1dc> @ imm = #0xc8
   11b9c: e3530030     	cmp	r3, #48
   11ba0: 0a00003f     	beq	0x11ca4 <pb_encode+0x218> @ imm = #0xfc
   11ba4: ea000059     	b	0x11d10 <pb_encode+0x284> @ imm = #0x164
   11ba8: e51b0020     	ldr	r0, [r11, #-0x20]
   11bac: e51b101c     	ldr	r1, [r11, #-0x1c]
   11bb0: eb0000be     	bl	0x11eb0 <pb_encode_tag_for_field> @ imm = #0x2f8
   11bb4: e1a03000     	mov	r3, r0
   11bb8: e2233001     	eor	r3, r3, #1
   11bbc: e6ef3073     	uxtb	r3, r3
   11bc0: e3530000     	cmp	r3, #0
   11bc4: 0a000001     	beq	0x11bd0 <pb_encode+0x144> @ imm = #0x4
   11bc8: e3a03000     	mov	r3, #0
   11bcc: ea000057     	b	0x11d30 <pb_encode+0x2a4> @ imm = #0x15c
   11bd0: e51b300c     	ldr	r3, [r11, #-0xc]
   11bd4: e51b0020     	ldr	r0, [r11, #-0x20]
   11bd8: e51b101c     	ldr	r1, [r11, #-0x1c]
   11bdc: e51b2018     	ldr	r2, [r11, #-0x18]
   11be0: e12fff33     	blx	r3
   11be4: e1a03000     	mov	r3, r0
   11be8: e2233001     	eor	r3, r3, #1
   11bec: e6ef3073     	uxtb	r3, r3
   11bf0: e3530000     	cmp	r3, #0
   11bf4: 0a00003e     	beq	0x11cf4 <pb_encode+0x268> @ imm = #0xf8
   11bf8: e3a03000     	mov	r3, #0
   11bfc: ea00004b     	b	0x11d30 <pb_encode+0x2a4> @ imm = #0x12c
   11c00: e51b3014     	ldr	r3, [r11, #-0x14]
   11c04: e5d33000     	ldrb	r3, [r3]
   11c08: e3530000     	cmp	r3, #0
   11c0c: 0a00003a     	beq	0x11cfc <pb_encode+0x270> @ imm = #0xe8
   11c10: e51b0020     	ldr	r0, [r11, #-0x20]
   11c14: e51b101c     	ldr	r1, [r11, #-0x1c]
   11c18: eb0000a4     	bl	0x11eb0 <pb_encode_tag_for_field> @ imm = #0x290
   11c1c: e1a03000     	mov	r3, r0
   11c20: e2233001     	eor	r3, r3, #1
   11c24: e6ef3073     	uxtb	r3, r3
   11c28: e3530000     	cmp	r3, #0
   11c2c: 0a000001     	beq	0x11c38 <pb_encode+0x1ac> @ imm = #0x4
   11c30: e3a03000     	mov	r3, #0
   11c34: ea00003d     	b	0x11d30 <pb_encode+0x2a4> @ imm = #0xf4
   11c38: e51b300c     	ldr	r3, [r11, #-0xc]
   11c3c: e51b0020     	ldr	r0, [r11, #-0x20]
   11c40: e51b101c     	ldr	r1, [r11, #-0x1c]
   11c44: e51b2018     	ldr	r2, [r11, #-0x18]
   11c48: e12fff33     	blx	r3
   11c4c: e1a03000     	mov	r3, r0
   11c50: e2233001     	eor	r3, r3, #1
   11c54: e6ef3073     	uxtb	r3, r3
   11c58: e3530000     	cmp	r3, #0
   11c5c: 0a000028     	beq	0x11d04 <pb_encode+0x278> @ imm = #0xa0
   11c60: e3a03000     	mov	r3, #0
   11c64: ea000031     	b	0x11d30 <pb_encode+0x2a4> @ imm = #0xc4
   11c68: e51b3014     	ldr	r3, [r11, #-0x14]
   11c6c: e5933000     	ldr	r3, [r3]
   11c70: e51b200c     	ldr	r2, [r11, #-0xc]
   11c74: e58d2000     	str	r2, [sp]
   11c78: e51b0020     	ldr	r0, [r11, #-0x20]
   11c7c: e51b101c     	ldr	r1, [r11, #-0x1c]
   11c80: e51b2018     	ldr	r2, [r11, #-0x18]
   11c84: ebfffeae     	bl	0x11744 <encode_array>  @ imm = #-0x548
   11c88: e1a03000     	mov	r3, r0
   11c8c: e2233001     	eor	r3, r3, #1
   11c90: e6ef3073     	uxtb	r3, r3
   11c94: e3530000     	cmp	r3, #0
   11c98: 0a00001b     	beq	0x11d0c <pb_encode+0x280> @ imm = #0x6c
   11c9c: e3a03000     	mov	r3, #0
   11ca0: ea000022     	b	0x11d30 <pb_encode+0x2a4> @ imm = #0x88
   11ca4: e51b3018     	ldr	r3, [r11, #-0x18]
   11ca8: e50b3008     	str	r3, [r11, #-0x8]
   11cac: e51b3008     	ldr	r3, [r11, #-0x8]
   11cb0: e5933000     	ldr	r3, [r3]
   11cb4: e3530000     	cmp	r3, #0
   11cb8: 0a000014     	beq	0x11d10 <pb_encode+0x284> @ imm = #0x50
   11cbc: e51b3008     	ldr	r3, [r11, #-0x8]
   11cc0: e5933000     	ldr	r3, [r3]
   11cc4: e51b2008     	ldr	r2, [r11, #-0x8]
   11cc8: e5922004     	ldr	r2, [r2, #0x4]
   11ccc: e51b0020     	ldr	r0, [r11, #-0x20]
   11cd0: e51b101c     	ldr	r1, [r11, #-0x1c]
   11cd4: e12fff33     	blx	r3
   11cd8: e1a03000     	mov	r3, r0
   11cdc: e2233001     	eor	r3, r3, #1
   11ce0: e6ef3073     	uxtb	r3, r3
   11ce4: e3530000     	cmp	r3, #0
   11ce8: 0a000008     	beq	0x11d10 <pb_encode+0x284> @ imm = #0x20
   11cec: e3a03000     	mov	r3, #0
   11cf0: ea00000e     	b	0x11d30 <pb_encode+0x2a4> @ imm = #0x38
   11cf4: e1a00000     	mov	r0, r0
   11cf8: ea000004     	b	0x11d10 <pb_encode+0x284> @ imm = #0x10
   11cfc: e1a00000     	mov	r0, r0
   11d00: ea000002     	b	0x11d10 <pb_encode+0x284> @ imm = #0x8
   11d04: e1a00000     	mov	r0, r0
   11d08: ea000000     	b	0x11d10 <pb_encode+0x284> @ imm = #0x0
   11d0c: e1a00000     	mov	r0, r0
   11d10: e51b301c     	ldr	r3, [r11, #-0x1c]
   11d14: e283300d     	add	r3, r3, #13
   11d18: e50b301c     	str	r3, [r11, #-0x1c]
   11d1c: e51b301c     	ldr	r3, [r11, #-0x1c]
   11d20: e5d33000     	ldrb	r3, [r3]
   11d24: e3530000     	cmp	r3, #0
   11d28: 1affff64     	bne	0x11ac0 <pb_encode+0x34> @ imm = #-0x270
   11d2c: e3a03001     	mov	r3, #1
   11d30: e1a00003     	mov	r0, r3
   11d34: e24bd004     	sub	sp, r11, #4
   11d38: e8bd8800     	pop	{r11, pc}
   11d3c: 30 28 03 00  	.word	0x00032830

