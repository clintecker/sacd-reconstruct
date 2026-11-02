00029c6c <free_area>:
   29c6c: e92d4800     	push	{r11, lr}
   29c70: e28db004     	add	r11, sp, #4
   29c74: e24dd010     	sub	sp, sp, #16
   29c78: e50b0010     	str	r0, [r11, #-0x10]
   29c7c: e3a03000     	mov	r3, #0
   29c80: e50b3008     	str	r3, [r11, #-0x8]
   29c84: ea00009e     	b	0x29f04 <free_area+0x298> @ imm = #0x278
   29c88: e51b3008     	ldr	r3, [r11, #-0x8]
   29c8c: e51b0010     	ldr	r0, [r11, #-0x10]
   29c90: e3a01014     	mov	r1, #20
   29c94: e1a02183     	lsl	r2, r3, #3
   29c98: e1a03182     	lsl	r3, r2, #3
   29c9c: e0623003     	rsb	r3, r2, r3
   29ca0: e0803003     	add	r3, r0, r3
   29ca4: e0833001     	add	r3, r3, r1
   29ca8: e5933000     	ldr	r3, [r3]
   29cac: e1a00003     	mov	r0, r3
   29cb0: ebff89d9     	bl	0xc41c <free@plt>       @ imm = #-0x1d89c
   29cb4: e51b3008     	ldr	r3, [r11, #-0x8]
   29cb8: e51b0010     	ldr	r0, [r11, #-0x10]
   29cbc: e3a01018     	mov	r1, #24
   29cc0: e1a02183     	lsl	r2, r3, #3
   29cc4: e1a03182     	lsl	r3, r2, #3
   29cc8: e0623003     	rsb	r3, r2, r3
   29ccc: e0803003     	add	r3, r0, r3
   29cd0: e0833001     	add	r3, r3, r1
   29cd4: e5933000     	ldr	r3, [r3]
   29cd8: e1a00003     	mov	r0, r3
   29cdc: ebff89ce     	bl	0xc41c <free@plt>       @ imm = #-0x1d8c8
   29ce0: e51b3008     	ldr	r3, [r11, #-0x8]
   29ce4: e51b0010     	ldr	r0, [r11, #-0x10]
   29ce8: e3a0101c     	mov	r1, #28
   29cec: e1a02183     	lsl	r2, r3, #3
   29cf0: e1a03182     	lsl	r3, r2, #3
   29cf4: e0623003     	rsb	r3, r2, r3
   29cf8: e0803003     	add	r3, r0, r3
   29cfc: e0833001     	add	r3, r3, r1
   29d00: e5933000     	ldr	r3, [r3]
   29d04: e1a00003     	mov	r0, r3
   29d08: ebff89c3     	bl	0xc41c <free@plt>       @ imm = #-0x1d8f4
   29d0c: e51b3008     	ldr	r3, [r11, #-0x8]
   29d10: e51b0010     	ldr	r0, [r11, #-0x10]
   29d14: e3a01020     	mov	r1, #32
   29d18: e1a02183     	lsl	r2, r3, #3
   29d1c: e1a03182     	lsl	r3, r2, #3
   29d20: e0623003     	rsb	r3, r2, r3
   29d24: e0803003     	add	r3, r0, r3
   29d28: e0833001     	add	r3, r3, r1
   29d2c: e5933000     	ldr	r3, [r3]
   29d30: e1a00003     	mov	r0, r3
   29d34: ebff89b8     	bl	0xc41c <free@plt>       @ imm = #-0x1d920
   29d38: e51b3008     	ldr	r3, [r11, #-0x8]
   29d3c: e51b0010     	ldr	r0, [r11, #-0x10]
   29d40: e3a01024     	mov	r1, #36
   29d44: e1a02183     	lsl	r2, r3, #3
   29d48: e1a03182     	lsl	r3, r2, #3
   29d4c: e0623003     	rsb	r3, r2, r3
   29d50: e0803003     	add	r3, r0, r3
   29d54: e0833001     	add	r3, r3, r1
   29d58: e5933000     	ldr	r3, [r3]
   29d5c: e1a00003     	mov	r0, r3
   29d60: ebff89ad     	bl	0xc41c <free@plt>       @ imm = #-0x1d94c
   29d64: e51b3008     	ldr	r3, [r11, #-0x8]
   29d68: e51b0010     	ldr	r0, [r11, #-0x10]
   29d6c: e3a01028     	mov	r1, #40
   29d70: e1a02183     	lsl	r2, r3, #3
   29d74: e1a03182     	lsl	r3, r2, #3
   29d78: e0623003     	rsb	r3, r2, r3
   29d7c: e0803003     	add	r3, r0, r3
   29d80: e0833001     	add	r3, r3, r1
   29d84: e5933000     	ldr	r3, [r3]
   29d88: e1a00003     	mov	r0, r3
   29d8c: ebff89a2     	bl	0xc41c <free@plt>       @ imm = #-0x1d978
   29d90: e51b3008     	ldr	r3, [r11, #-0x8]
   29d94: e51b0010     	ldr	r0, [r11, #-0x10]
   29d98: e3a0102c     	mov	r1, #44
   29d9c: e1a02183     	lsl	r2, r3, #3
   29da0: e1a03182     	lsl	r3, r2, #3
   29da4: e0623003     	rsb	r3, r2, r3
   29da8: e0803003     	add	r3, r0, r3
   29dac: e0833001     	add	r3, r3, r1
   29db0: e5933000     	ldr	r3, [r3]
   29db4: e1a00003     	mov	r0, r3
   29db8: ebff8997     	bl	0xc41c <free@plt>       @ imm = #-0x1d9a4
   29dbc: e51b3008     	ldr	r3, [r11, #-0x8]
   29dc0: e51b0010     	ldr	r0, [r11, #-0x10]
   29dc4: e3a01030     	mov	r1, #48
   29dc8: e1a02183     	lsl	r2, r3, #3
   29dcc: e1a03182     	lsl	r3, r2, #3
   29dd0: e0623003     	rsb	r3, r2, r3
   29dd4: e0803003     	add	r3, r0, r3
   29dd8: e0833001     	add	r3, r3, r1
   29ddc: e5933000     	ldr	r3, [r3]
   29de0: e1a00003     	mov	r0, r3
   29de4: ebff898c     	bl	0xc41c <free@plt>       @ imm = #-0x1d9d0
   29de8: e51b3008     	ldr	r3, [r11, #-0x8]
   29dec: e51b0010     	ldr	r0, [r11, #-0x10]
   29df0: e3a01034     	mov	r1, #52
   29df4: e1a02183     	lsl	r2, r3, #3
   29df8: e1a03182     	lsl	r3, r2, #3
   29dfc: e0623003     	rsb	r3, r2, r3
   29e00: e0803003     	add	r3, r0, r3
   29e04: e0833001     	add	r3, r3, r1
   29e08: e5933000     	ldr	r3, [r3]
   29e0c: e1a00003     	mov	r0, r3
   29e10: ebff8981     	bl	0xc41c <free@plt>       @ imm = #-0x1d9fc
   29e14: e51b3008     	ldr	r3, [r11, #-0x8]
   29e18: e51b0010     	ldr	r0, [r11, #-0x10]
   29e1c: e3a01038     	mov	r1, #56
   29e20: e1a02183     	lsl	r2, r3, #3
   29e24: e1a03182     	lsl	r3, r2, #3
   29e28: e0623003     	rsb	r3, r2, r3
   29e2c: e0803003     	add	r3, r0, r3
   29e30: e0833001     	add	r3, r3, r1
   29e34: e5933000     	ldr	r3, [r3]
   29e38: e1a00003     	mov	r0, r3
   29e3c: ebff8976     	bl	0xc41c <free@plt>       @ imm = #-0x1da28
   29e40: e51b3008     	ldr	r3, [r11, #-0x8]
   29e44: e51b0010     	ldr	r0, [r11, #-0x10]
   29e48: e2833001     	add	r3, r3, #1
   29e4c: e3a01004     	mov	r1, #4
   29e50: e1a02183     	lsl	r2, r3, #3
   29e54: e1a03182     	lsl	r3, r2, #3
   29e58: e0623003     	rsb	r3, r2, r3
   29e5c: e0803003     	add	r3, r0, r3
   29e60: e0833001     	add	r3, r3, r1
   29e64: e5933000     	ldr	r3, [r3]
   29e68: e1a00003     	mov	r0, r3
   29e6c: ebff896a     	bl	0xc41c <free@plt>       @ imm = #-0x1da58
   29e70: e51b3008     	ldr	r3, [r11, #-0x8]
   29e74: e51b0010     	ldr	r0, [r11, #-0x10]
   29e78: e2833001     	add	r3, r3, #1
   29e7c: e3a01008     	mov	r1, #8
   29e80: e1a02183     	lsl	r2, r3, #3
   29e84: e1a03182     	lsl	r3, r2, #3
   29e88: e0623003     	rsb	r3, r2, r3
   29e8c: e0803003     	add	r3, r0, r3
   29e90: e0833001     	add	r3, r3, r1
   29e94: e5933000     	ldr	r3, [r3]
   29e98: e1a00003     	mov	r0, r3
   29e9c: ebff895e     	bl	0xc41c <free@plt>       @ imm = #-0x1da88
   29ea0: e51b3008     	ldr	r3, [r11, #-0x8]
   29ea4: e51b0010     	ldr	r0, [r11, #-0x10]
   29ea8: e3a01044     	mov	r1, #68
   29eac: e1a02183     	lsl	r2, r3, #3
   29eb0: e1a03182     	lsl	r3, r2, #3
   29eb4: e0623003     	rsb	r3, r2, r3
   29eb8: e0803003     	add	r3, r0, r3
   29ebc: e0833001     	add	r3, r3, r1
   29ec0: e5933000     	ldr	r3, [r3]
   29ec4: e1a00003     	mov	r0, r3
   29ec8: ebff8953     	bl	0xc41c <free@plt>       @ imm = #-0x1dab4
   29ecc: e51b3008     	ldr	r3, [r11, #-0x8]
   29ed0: e51b0010     	ldr	r0, [r11, #-0x10]
   29ed4: e3a01048     	mov	r1, #72
   29ed8: e1a02183     	lsl	r2, r3, #3
   29edc: e1a03182     	lsl	r3, r2, #3
   29ee0: e0623003     	rsb	r3, r2, r3
   29ee4: e0803003     	add	r3, r0, r3
   29ee8: e0833001     	add	r3, r3, r1
   29eec: e5933000     	ldr	r3, [r3]
   29ef0: e1a00003     	mov	r0, r3
   29ef4: ebff8948     	bl	0xc41c <free@plt>       @ imm = #-0x1dae0
   29ef8: e51b3008     	ldr	r3, [r11, #-0x8]
   29efc: e2833001     	add	r3, r3, #1
   29f00: e50b3008     	str	r3, [r11, #-0x8]
   29f04: e51b3010     	ldr	r3, [r11, #-0x10]
   29f08: e5933004     	ldr	r3, [r3, #0x4]
   29f0c: e5d33045     	ldrb	r3, [r3, #0x45]
   29f10: e1a02003     	mov	r2, r3
   29f14: e51b3008     	ldr	r3, [r11, #-0x8]
   29f18: e1520003     	cmp	r2, r3
   29f1c: caffff59     	bgt	0x29c88 <free_area+0x1c> @ imm = #-0x29c
   29f20: e51b2010     	ldr	r2, [r11, #-0x10]
   29f24: e59f304c     	ldr	r3, [pc, #0x4c]         @ 0x29f78 <free_area+0x30c>
   29f28: e7923003     	ldr	r3, [r2, r3]
   29f2c: e1a00003     	mov	r0, r3
   29f30: ebff8939     	bl	0xc41c <free@plt>       @ imm = #-0x1db1c
   29f34: e51b2010     	ldr	r2, [r11, #-0x10]
   29f38: e59f303c     	ldr	r3, [pc, #0x3c]         @ 0x29f7c <free_area+0x310>
   29f3c: e7923003     	ldr	r3, [r2, r3]
   29f40: e1a00003     	mov	r0, r3
   29f44: ebff8934     	bl	0xc41c <free@plt>       @ imm = #-0x1db30
   29f48: e51b2010     	ldr	r2, [r11, #-0x10]
   29f4c: e59f302c     	ldr	r3, [pc, #0x2c]         @ 0x29f80 <free_area+0x314>
   29f50: e7923003     	ldr	r3, [r2, r3]
   29f54: e1a00003     	mov	r0, r3
   29f58: ebff892f     	bl	0xc41c <free@plt>       @ imm = #-0x1db44
   29f5c: e51b2010     	ldr	r2, [r11, #-0x10]
   29f60: e59f301c     	ldr	r3, [pc, #0x1c]         @ 0x29f84 <free_area+0x318>
   29f64: e7923003     	ldr	r3, [r2, r3]
   29f68: e1a00003     	mov	r0, r3
   29f6c: ebff892a     	bl	0xc41c <free@plt>       @ imm = #-0x1db58
   29f70: e24bd004     	sub	sp, r11, #4
   29f74: e8bd8800     	pop	{r11, pc}
   29f78: e0 37 00 00  	.word	0x000037e0
   29f7c: e4 37 00 00  	.word	0x000037e4
   29f80: e8 37 00 00  	.word	0x000037e8
   29f84: ec 37 00 00  	.word	0x000037ec

