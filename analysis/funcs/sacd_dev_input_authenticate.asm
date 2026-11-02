00021cc4 <sacd_dev_input_authenticate>:
   21cc4: e92d4800     	push	{r11, lr}
   21cc8: e28db004     	add	r11, sp, #4
   21ccc: e24dd010     	sub	sp, sp, #16
   21cd0: e50b0010     	str	r0, [r11, #-0x10]
   21cd4: ebfffcd1     	bl	0x21020 <auth_sacd>     @ imm = #-0xcbc
   21cd8: e1a03000     	mov	r3, r0
   21cdc: e50b3008     	str	r3, [r11, #-0x8]
   21ce0: e51b3008     	ldr	r3, [r11, #-0x8]
   21ce4: e3530000     	cmp	r3, #0
   21ce8: aa000009     	bge	0x21d14 <sacd_dev_input_authenticate+0x50> @ imm = #0x24
   21cec: e59f3030     	ldr	r3, [pc, #0x30]         @ 0x21d24 <sacd_dev_input_authenticate+0x60>
   21cf0: e5933000     	ldr	r3, [r3]
   21cf4: e5933004     	ldr	r3, [r3, #0x4]
   21cf8: e3530001     	cmp	r3, #1
   21cfc: 9a000002     	bls	0x21d0c <sacd_dev_input_authenticate+0x48> @ imm = #0x8
   21d00: e59f0020     	ldr	r0, [pc, #0x20]         @ 0x21d28 <sacd_dev_input_authenticate+0x64>
   21d04: e51b1008     	ldr	r1, [r11, #-0x8]
   21d08: ebffcbe9     	bl	0x14cb4 <log_print>     @ imm = #-0xd05c
   21d0c: e51b3008     	ldr	r3, [r11, #-0x8]
   21d10: ea000000     	b	0x21d18 <sacd_dev_input_authenticate+0x54> @ imm = #0x0
   21d14: e3a03000     	mov	r3, #0
   21d18: e1a00003     	mov	r0, r3
   21d1c: e24bd004     	sub	sp, r11, #4
   21d20: e8bd8800     	pop	{r11, pc}
   21d24: 5c 73 05 00  	.word	0x0005735c
   21d28: 3c 54 03 00  	.word	0x0003543c

