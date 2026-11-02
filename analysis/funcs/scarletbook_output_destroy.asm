00028db0 <scarletbook_output_destroy>:
   28db0: e92d4800     	push	{r11, lr}
   28db4: e28db004     	add	r11, sp, #4
   28db8: e24dd010     	sub	sp, sp, #16
   28dbc: e50b0010     	str	r0, [r11, #-0x10]
   28dc0: e3a03000     	mov	r3, #0
   28dc4: e50b3008     	str	r3, [r11, #-0x8]
   28dc8: e51b3010     	ldr	r3, [r11, #-0x10]
   28dcc: e3530000     	cmp	r3, #0
   28dd0: 1a000001     	bne	0x28ddc <scarletbook_output_destroy+0x2c> @ imm = #0x4
   28dd4: e3e03000     	mvn	r3, #0
   28dd8: ea00001c     	b	0x28e50 <scarletbook_output_destroy+0xa0> @ imm = #0x70
   28ddc: e51b0010     	ldr	r0, [r11, #-0x10]
   28de0: ebffffe8     	bl	0x28d88 <scarletbook_output_interrupt> @ imm = #-0x60
   28de4: e51b3010     	ldr	r3, [r11, #-0x10]
   28de8: e593200c     	ldr	r2, [r3, #0xc]
   28dec: e24b300c     	sub	r3, r11, #12
   28df0: e1a00002     	mov	r0, r2
   28df4: e1a01003     	mov	r1, r3
   28df8: ebff8e83     	bl	0xc80c <sprintf@plt+0xc> @ imm = #-0x1c5f4
   28dfc: e1a03000     	mov	r3, r0
   28e00: e50b3008     	str	r3, [r11, #-0x8]
   28e04: e51b3008     	ldr	r3, [r11, #-0x8]
   28e08: e3530000     	cmp	r3, #0
   28e0c: 0a000008     	beq	0x28e34 <scarletbook_output_destroy+0x84> @ imm = #0x20
   28e10: e59f3044     	ldr	r3, [pc, #0x44]         @ 0x28e5c <scarletbook_output_destroy+0xac>
   28e14: e5933000     	ldr	r3, [r3]
   28e18: e5933004     	ldr	r3, [r3, #0x4]
   28e1c: e3530001     	cmp	r3, #1
   28e20: 9a000003     	bls	0x28e34 <scarletbook_output_destroy+0x84> @ imm = #0xc
   28e24: e51b300c     	ldr	r3, [r11, #-0xc]
   28e28: e59f0030     	ldr	r0, [pc, #0x30]         @ 0x28e60 <scarletbook_output_destroy+0xb0>
   28e2c: e1a01003     	mov	r1, r3
   28e30: ebffaf9f     	bl	0x14cb4 <log_print>     @ imm = #-0x14184
   28e34: e51b3010     	ldr	r3, [r11, #-0x10]
   28e38: e5933008     	ldr	r3, [r3, #0x8]
   28e3c: e1a00003     	mov	r0, r3
   28e40: ebff8d75     	bl	0xc41c <free@plt>       @ imm = #-0x1ca2c
   28e44: e51b0010     	ldr	r0, [r11, #-0x10]
   28e48: ebff8d73     	bl	0xc41c <free@plt>       @ imm = #-0x1ca34
   28e4c: e51b3008     	ldr	r3, [r11, #-0x8]
   28e50: e1a00003     	mov	r0, r3
   28e54: e24bd004     	sub	sp, r11, #4
   28e58: e8bd8800     	pop	{r11, pc}
   28e5c: 5c 73 05 00  	.word	0x0005735c
   28e60: 1c 58 03 00  	.word	0x0003581c

