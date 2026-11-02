00011d40 <pb_encode_varint>:
   11d40: e92d4830     	push	{r4, r5, r11, lr}
   11d44: e28db00c     	add	r11, sp, #12
   11d48: e24dd020     	sub	sp, sp, #32
   11d4c: e50b0020     	str	r0, [r11, #-0x20]
   11d50: e14b22fc     	strd	r2, r3, [r11, #-44]
   11d54: e3a03000     	mov	r3, #0
   11d58: e50b3010     	str	r3, [r11, #-0x10]
   11d5c: e14b02dc     	ldrd	r0, r1, [r11, #-44]
   11d60: e1a03000     	mov	r3, r0
   11d64: e1833001     	orr	r3, r3, r1
   11d68: e3530000     	cmp	r3, #0
   11d6c: 1a00001b     	bne	0x11de0 <pb_encode_varint+0xa0> @ imm = #0x6c
   11d70: e24b302c     	sub	r3, r11, #44
   11d74: e51b0020     	ldr	r0, [r11, #-0x20]
   11d78: e1a01003     	mov	r1, r3
   11d7c: e3a02001     	mov	r2, #1
   11d80: ebfffe44     	bl	0x11698 <pb_write>      @ imm = #-0x6f0
   11d84: e1a03000     	mov	r3, r0
   11d88: ea000030     	b	0x11e50 <pb_encode_varint+0x110> @ imm = #0xc0
   11d8c: e51b1010     	ldr	r1, [r11, #-0x10]
   11d90: e14b22dc     	ldrd	r2, r3, [r11, #-44]
   11d94: e6ef3072     	uxtb	r3, r2
   11d98: e1e03c83     	mvn	r3, r3, lsl #25
   11d9c: e1e03ca3     	mvn	r3, r3, lsr #25
   11da0: e6ef2073     	uxtb	r2, r3
   11da4: e3e0300f     	mvn	r3, #15
   11da8: e24b000c     	sub	r0, r11, #12
   11dac: e0801001     	add	r1, r0, r1
   11db0: e0813003     	add	r3, r1, r3
   11db4: e5c32000     	strb	r2, [r3]
   11db8: e14b22dc     	ldrd	r2, r3, [r11, #-44]
   11dbc: e1a01c83     	lsl	r1, r3, #25
   11dc0: e1a043a2     	lsr	r4, r2, #7
   11dc4: e1814004     	orr	r4, r1, r4
   11dc8: e1a053a3     	lsr	r5, r3, #7
   11dcc: e14b42fc     	strd	r4, r5, [r11, #-44]
   11dd0: e51b3010     	ldr	r3, [r11, #-0x10]
   11dd4: e2833001     	add	r3, r3, #1
   11dd8: e50b3010     	str	r3, [r11, #-0x10]
   11ddc: ea000000     	b	0x11de4 <pb_encode_varint+0xa4> @ imm = #0x0
   11de0: e1a00000     	mov	r0, r0
   11de4: e14b02dc     	ldrd	r0, r1, [r11, #-44]
   11de8: e1a03000     	mov	r3, r0
   11dec: e1833001     	orr	r3, r3, r1
   11df0: e3530000     	cmp	r3, #0
   11df4: 1affffe4     	bne	0x11d8c <pb_encode_varint+0x4c> @ imm = #-0x70
   11df8: e51b3010     	ldr	r3, [r11, #-0x10]
   11dfc: e2431001     	sub	r1, r3, #1
   11e00: e51b3010     	ldr	r3, [r11, #-0x10]
   11e04: e2432001     	sub	r2, r3, #1
   11e08: e3e0300f     	mvn	r3, #15
   11e0c: e24b000c     	sub	r0, r11, #12
   11e10: e0802002     	add	r2, r0, r2
   11e14: e0823003     	add	r3, r2, r3
   11e18: e5d33000     	ldrb	r3, [r3]
   11e1c: e203307f     	and	r3, r3, #127
   11e20: e3e0200f     	mvn	r2, #15
   11e24: e24b000c     	sub	r0, r11, #12
   11e28: e0801001     	add	r1, r0, r1
   11e2c: e0812002     	add	r2, r1, r2
   11e30: e5c23000     	strb	r3, [r2]
   11e34: e51b3010     	ldr	r3, [r11, #-0x10]
   11e38: e24b201c     	sub	r2, r11, #28
   11e3c: e51b0020     	ldr	r0, [r11, #-0x20]
   11e40: e1a01002     	mov	r1, r2
   11e44: e1a02003     	mov	r2, r3
   11e48: ebfffe12     	bl	0x11698 <pb_write>      @ imm = #-0x7b8
   11e4c: e1a03000     	mov	r3, r0
   11e50: e1a00003     	mov	r0, r3
   11e54: e24bd00c     	sub	sp, r11, #12
   11e58: e8bd8830     	pop	{r4, r5, r11, pc}

