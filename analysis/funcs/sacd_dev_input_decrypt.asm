00021d2c <sacd_dev_input_decrypt>:
   21d2c: e92d4800     	push	{r11, lr}
   21d30: e28db004     	add	r11, sp, #4
   21d34: e24dd018     	sub	sp, sp, #24
   21d38: e50b0010     	str	r0, [r11, #-0x10]
   21d3c: e50b1014     	str	r1, [r11, #-0x14]
   21d40: e50b2018     	str	r2, [r11, #-0x18]
   21d44: e51b0018     	ldr	r0, [r11, #-0x18]
   21d48: e51b1014     	ldr	r1, [r11, #-0x14]
   21d4c: ebfffd04     	bl	0x21164 <decrypt_sacd>  @ imm = #-0xbf0
   21d50: e1a03000     	mov	r3, r0
   21d54: e50b3008     	str	r3, [r11, #-0x8]
   21d58: e51b3008     	ldr	r3, [r11, #-0x8]
   21d5c: e3530000     	cmp	r3, #0
   21d60: aa000009     	bge	0x21d8c <sacd_dev_input_decrypt+0x60> @ imm = #0x24
   21d64: e59f3030     	ldr	r3, [pc, #0x30]         @ 0x21d9c <sacd_dev_input_decrypt+0x70>
   21d68: e5933000     	ldr	r3, [r3]
   21d6c: e5933004     	ldr	r3, [r3, #0x4]
   21d70: e3530001     	cmp	r3, #1
   21d74: 9a000002     	bls	0x21d84 <sacd_dev_input_decrypt+0x58> @ imm = #0x8
   21d78: e59f0020     	ldr	r0, [pc, #0x20]         @ 0x21da0 <sacd_dev_input_decrypt+0x74>
   21d7c: e51b1008     	ldr	r1, [r11, #-0x8]
   21d80: ebffcbcb     	bl	0x14cb4 <log_print>     @ imm = #-0xd0d4
   21d84: e3e03000     	mvn	r3, #0
   21d88: ea000000     	b	0x21d90 <sacd_dev_input_decrypt+0x64> @ imm = #0x0
   21d8c: e3a03000     	mov	r3, #0
   21d90: e1a00003     	mov	r0, r3
   21d94: e24bd004     	sub	sp, r11, #4
   21d98: e8bd8800     	pop	{r11, pc}
   21d9c: 5c 73 05 00  	.word	0x0005735c
   21da0: 50 54 03 00  	.word	0x00035450

