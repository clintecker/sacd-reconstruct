00028cfc <scarletbook_output_start>:
   28cfc: e92d4800     	push	{r11, lr}
   28d00: e28db004     	add	r11, sp, #4
   28d04: e24dd010     	sub	sp, sp, #16
   28d08: e50b0010     	str	r0, [r11, #-0x10]
   28d0c: e3a03000     	mov	r3, #0
   28d10: e50b3008     	str	r3, [r11, #-0x8]
   28d14: e51b0010     	ldr	r0, [r11, #-0x10]
   28d18: ebfffd3e     	bl	0x28218 <scarletbook_output_init_stats> @ imm = #-0xb08
   28d1c: e51b3010     	ldr	r3, [r11, #-0x10]
   28d20: e283300c     	add	r3, r3, #12
   28d24: e1a00003     	mov	r0, r3
   28d28: e3a01000     	mov	r1, #0
   28d2c: e59f2048     	ldr	r2, [pc, #0x48]         @ 0x28d7c <scarletbook_output_start+0x80>
   28d30: e51b3010     	ldr	r3, [r11, #-0x10]
   28d34: ebff8df1     	bl	0xc500 <pthread_create@plt> @ imm = #-0x1c83c
   28d38: e1a03000     	mov	r3, r0
   28d3c: e50b3008     	str	r3, [r11, #-0x8]
   28d40: e51b3008     	ldr	r3, [r11, #-0x8]
   28d44: e3530000     	cmp	r3, #0
   28d48: 0a000007     	beq	0x28d6c <scarletbook_output_start+0x70> @ imm = #0x1c
   28d4c: e59f302c     	ldr	r3, [pc, #0x2c]         @ 0x28d80 <scarletbook_output_start+0x84>
   28d50: e5933000     	ldr	r3, [r3]
   28d54: e5933004     	ldr	r3, [r3, #0x4]
   28d58: e3530001     	cmp	r3, #1
   28d5c: 9a000002     	bls	0x28d6c <scarletbook_output_start+0x70> @ imm = #0x8
   28d60: e59f001c     	ldr	r0, [pc, #0x1c]         @ 0x28d84 <scarletbook_output_start+0x88>
   28d64: e51b1008     	ldr	r1, [r11, #-0x8]
   28d68: ebffafd1     	bl	0x14cb4 <log_print>     @ imm = #-0x140bc
   28d6c: e51b3008     	ldr	r3, [r11, #-0x8]
   28d70: e1a00003     	mov	r0, r3
   28d74: e24bd004     	sub	sp, r11, #4
   28d78: e8bd8800     	pop	{r11, pc}
   28d7c: b8 84 02 00  	.word	0x000284b8
   28d80: 5c 73 05 00  	.word	0x0005735c
   28d84: e8 57 03 00  	.word	0x000357e8

