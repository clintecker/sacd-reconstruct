00021da4 <sacd_dev_input_open>:
   21da4: e92d4800     	push	{r11, lr}
   21da8: e28db004     	add	r11, sp, #4
   21dac: e24dd010     	sub	sp, sp, #16
   21db0: e50b0010     	str	r0, [r11, #-0x10]
   21db4: e3a00008     	mov	r0, #8
   21db8: e3a01001     	mov	r1, #1
   21dbc: ebffa966     	bl	0xc35c <calloc@plt>     @ imm = #-0x15a68
   21dc0: e1a03000     	mov	r3, r0
   21dc4: e50b3008     	str	r3, [r11, #-0x8]
   21dc8: e51b3008     	ldr	r3, [r11, #-0x8]
   21dcc: e3530000     	cmp	r3, #0
   21dd0: 1a000008     	bne	0x21df8 <sacd_dev_input_open+0x54> @ imm = #0x20
   21dd4: e59f20a0     	ldr	r2, [pc, #0xa0]         @ 0x21e7c <sacd_dev_input_open+0xd8>
   21dd8: e59f30a0     	ldr	r3, [pc, #0xa0]         @ 0x21e80 <sacd_dev_input_open+0xdc>
   21ddc: e5933000     	ldr	r3, [r3]
   21de0: e1a00002     	mov	r0, r2
   21de4: e3a01001     	mov	r1, #1
   21de8: e3a02028     	mov	r2, #40
   21dec: ebffa9ff     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x15804
   21df0: e3a03000     	mov	r3, #0
   21df4: ea00001d     	b	0x21e70 <sacd_dev_input_open+0xcc> @ imm = #0x74
   21df8: e51b0010     	ldr	r0, [r11, #-0x10]
   21dfc: e3a01000     	mov	r1, #0
   21e00: ebffa9dc     	bl	0xc578 <open64@plt>     @ imm = #-0x15890
   21e04: e1a02000     	mov	r2, r0
   21e08: e51b3008     	ldr	r3, [r11, #-0x8]
   21e0c: e5832000     	str	r2, [r3]
   21e10: e51b3008     	ldr	r3, [r11, #-0x8]
   21e14: e5933000     	ldr	r3, [r3]
   21e18: e3530000     	cmp	r3, #0
   21e1c: ba00000f     	blt	0x21e60 <sacd_dev_input_open+0xbc> @ imm = #0x3c
   21e20: e59f305c     	ldr	r3, [pc, #0x5c]         @ 0x21e84 <sacd_dev_input_open+0xe0>
   21e24: e5932000     	ldr	r2, [r3]
   21e28: e59f3058     	ldr	r3, [pc, #0x58]         @ 0x21e88 <sacd_dev_input_open+0xe4>
   21e2c: e1520003     	cmp	r2, r3
   21e30: 1a000008     	bne	0x21e58 <sacd_dev_input_open+0xb4> @ imm = #0x20
   21e34: ebfffc55     	bl	0x20f90 <init_sacd>     @ imm = #-0xeac
   21e38: e1a03000     	mov	r3, r0
   21e3c: e3530000     	cmp	r3, #0
   21e40: aa000004     	bge	0x21e58 <sacd_dev_input_open+0xb4> @ imm = #0x10
   21e44: e51b3008     	ldr	r3, [r11, #-0x8]
   21e48: e5933000     	ldr	r3, [r3]
   21e4c: e1a00003     	mov	r0, r3
   21e50: ebffa9e3     	bl	0xc5e4 <close@plt>      @ imm = #-0x15874
   21e54: ea000002     	b	0x21e64 <sacd_dev_input_open+0xc0> @ imm = #0x8
   21e58: e51b3008     	ldr	r3, [r11, #-0x8]
   21e5c: ea000003     	b	0x21e70 <sacd_dev_input_open+0xcc> @ imm = #0xc
   21e60: e1a00000     	mov	r0, r0
   21e64: e51b0008     	ldr	r0, [r11, #-0x8]
   21e68: ebffa96b     	bl	0xc41c <free@plt>       @ imm = #-0x15a54
   21e6c: e3a03000     	mov	r3, #0
   21e70: e1a00003     	mov	r0, r3
   21e74: e24bd004     	sub	sp, r11, #4
   21e78: e8bd8800     	pop	{r11, pc}
   21e7c: 68 54 03 00  	.word	0x00035468
   21e80: f8 6d 05 00  	.word	0x00056df8
   21e84: 04 9e 05 00  	.word	0x00059e04
   21e88: 28 20 02 00  	.word	0x00022028

