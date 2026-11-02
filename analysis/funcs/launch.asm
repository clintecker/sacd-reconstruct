00015cac <launch>:
   15cac: e92d4800     	push	{r11, lr}
   15cb0: e28db004     	add	r11, sp, #4
   15cb4: e24dd038     	sub	sp, sp, #56
   15cb8: e50b0038     	str	r0, [r11, #-0x38]
   15cbc: e50b103c     	str	r1, [r11, #-0x3c]
   15cc0: e3a00008     	mov	r0, #8
   15cc4: ebfffe81     	bl	0x156d0 <my_malloc>     @ imm = #-0x5fc
   15cc8: e1a03000     	mov	r3, r0
   15ccc: e50b3008     	str	r3, [r11, #-0x8]
   15cd0: e51b3008     	ldr	r3, [r11, #-0x8]
   15cd4: e51b2038     	ldr	r2, [r11, #-0x38]
   15cd8: e5832000     	str	r2, [r3]
   15cdc: e51b3008     	ldr	r3, [r11, #-0x8]
   15ce0: e51b203c     	ldr	r2, [r11, #-0x3c]
   15ce4: e5832004     	str	r2, [r3, #0x4]
   15ce8: e59f0110     	ldr	r0, [pc, #0x110]        @ 0x15e00 <launch+0x154>
   15cec: ebfffeaf     	bl	0x157b0 <possess>       @ imm = #-0x544
   15cf0: e3a0000c     	mov	r0, #12
   15cf4: ebfffe75     	bl	0x156d0 <my_malloc>     @ imm = #-0x62c
   15cf8: e1a03000     	mov	r3, r0
   15cfc: e50b300c     	str	r3, [r11, #-0xc]
   15d00: e24b3034     	sub	r3, r11, #52
   15d04: e1a00003     	mov	r0, r3
   15d08: ebffda62     	bl	0xc698 <pthread_attr_init@plt> @ imm = #-0x9678
   15d0c: e1a03000     	mov	r3, r0
   15d10: e50b3010     	str	r3, [r11, #-0x10]
   15d14: e51b3010     	ldr	r3, [r11, #-0x10]
   15d18: e3530000     	cmp	r3, #0
   15d1c: 1a000025     	bne	0x15db8 <launch+0x10c>  @ imm = #0x94
   15d20: e24b3034     	sub	r3, r11, #52
   15d24: e1a00003     	mov	r0, r3
   15d28: e3a01601     	mov	r1, #1048576
   15d2c: ebffda32     	bl	0xc5fc <pthread_attr_setstacksize@plt> @ imm = #-0x9738
   15d30: e1a03000     	mov	r3, r0
   15d34: e50b3010     	str	r3, [r11, #-0x10]
   15d38: e51b3010     	ldr	r3, [r11, #-0x10]
   15d3c: e3530000     	cmp	r3, #0
   15d40: 1a00001c     	bne	0x15db8 <launch+0x10c>  @ imm = #0x70
   15d44: e24b3034     	sub	r3, r11, #52
   15d48: e1a00003     	mov	r0, r3
   15d4c: e3a01000     	mov	r1, #0
   15d50: ebffd94b     	bl	0xc284 <pthread_attr_setdetachstate@plt> @ imm = #-0x9ad4
   15d54: e1a03000     	mov	r3, r0
   15d58: e50b3010     	str	r3, [r11, #-0x10]
   15d5c: e51b3010     	ldr	r3, [r11, #-0x10]
   15d60: e3530000     	cmp	r3, #0
   15d64: 1a000013     	bne	0x15db8 <launch+0x10c>  @ imm = #0x4c
   15d68: e51b200c     	ldr	r2, [r11, #-0xc]
   15d6c: e24b3034     	sub	r3, r11, #52
   15d70: e1a00002     	mov	r0, r2
   15d74: e1a01003     	mov	r1, r3
   15d78: e59f2084     	ldr	r2, [pc, #0x84]         @ 0x15e04 <launch+0x158>
   15d7c: e51b3008     	ldr	r3, [r11, #-0x8]
   15d80: ebffd9de     	bl	0xc500 <pthread_create@plt> @ imm = #-0x9888
   15d84: e1a03000     	mov	r3, r0
   15d88: e50b3010     	str	r3, [r11, #-0x10]
   15d8c: e51b3010     	ldr	r3, [r11, #-0x10]
   15d90: e3530000     	cmp	r3, #0
   15d94: 1a000007     	bne	0x15db8 <launch+0x10c>  @ imm = #0x1c
   15d98: e24b3034     	sub	r3, r11, #52
   15d9c: e1a00003     	mov	r0, r3
   15da0: ebffda5d     	bl	0xc71c <pthread_attr_destroy@plt> @ imm = #-0x968c
   15da4: e1a03000     	mov	r3, r0
   15da8: e50b3010     	str	r3, [r11, #-0x10]
   15dac: e51b3010     	ldr	r3, [r11, #-0x10]
   15db0: e3530000     	cmp	r3, #0
   15db4: 0a000001     	beq	0x15dc0 <launch+0x114>  @ imm = #0x4
   15db8: e51b0010     	ldr	r0, [r11, #-0x10]
   15dbc: ebfffe07     	bl	0x155e0 <fail>          @ imm = #-0x7e4
   15dc0: e51b300c     	ldr	r3, [r11, #-0xc]
   15dc4: e3a02000     	mov	r2, #0
   15dc8: e5832004     	str	r2, [r3, #0x4]
   15dcc: e59f3034     	ldr	r3, [pc, #0x34]         @ 0x15e08 <launch+0x15c>
   15dd0: e5932000     	ldr	r2, [r3]
   15dd4: e51b300c     	ldr	r3, [r11, #-0xc]
   15dd8: e5832008     	str	r2, [r3, #0x8]
   15ddc: e59f3024     	ldr	r3, [pc, #0x24]         @ 0x15e08 <launch+0x15c>
   15de0: e51b200c     	ldr	r2, [r11, #-0xc]
   15de4: e5832000     	str	r2, [r3]
   15de8: e59f0010     	ldr	r0, [pc, #0x10]         @ 0x15e00 <launch+0x154>
   15dec: ebfffe7f     	bl	0x157f0 <release>       @ imm = #-0x604
   15df0: e51b300c     	ldr	r3, [r11, #-0xc]
   15df4: e1a00003     	mov	r0, r3
   15df8: e24bd004     	sub	sp, r11, #4
   15dfc: e8bd8800     	pop	{r11, pc}
   15e00: 68 73 05 00  	.word	0x00057368
   15e04: e4 5b 01 00  	.word	0x00015be4
   15e08: b8 73 05 00  	.word	0x000573b8

