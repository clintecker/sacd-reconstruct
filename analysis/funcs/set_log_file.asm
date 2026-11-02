00014b5c <set_log_file>:
   14b5c: e92d4800     	push	{r11, lr}
   14b60: e28db004     	add	r11, sp, #4
   14b64: e24dd010     	sub	sp, sp, #16
   14b68: e50b0010     	str	r0, [r11, #-0x10]
   14b6c: e59f3090     	ldr	r3, [pc, #0x90]         @ 0x14c04 <set_log_file+0xa8>
   14b70: e51b0010     	ldr	r0, [r11, #-0x10]
   14b74: e1a01003     	mov	r1, r3
   14b78: ebffde6c     	bl	0xc530 <fopen64@plt>    @ imm = #-0x8650
   14b7c: e1a03000     	mov	r3, r0
   14b80: e50b3008     	str	r3, [r11, #-0x8]
   14b84: e51b3008     	ldr	r3, [r11, #-0x8]
   14b88: e3530000     	cmp	r3, #0
   14b8c: 1a000001     	bne	0x14b98 <set_log_file+0x3c> @ imm = #0x4
   14b90: e3e03000     	mvn	r3, #0
   14b94: ea000017     	b	0x14bf8 <set_log_file+0x9c> @ imm = #0x5c
   14b98: e59f3068     	ldr	r3, [pc, #0x68]         @ 0x14c08 <set_log_file+0xac>
   14b9c: e5933000     	ldr	r3, [r3]
   14ba0: e3530000     	cmp	r3, #0
   14ba4: 0a00000f     	beq	0x14be8 <set_log_file+0x8c> @ imm = #0x3c
   14ba8: e59f3058     	ldr	r3, [pc, #0x58]         @ 0x14c08 <set_log_file+0xac>
   14bac: e5932000     	ldr	r2, [r3]
   14bb0: e59f3054     	ldr	r3, [pc, #0x54]         @ 0x14c0c <set_log_file+0xb0>
   14bb4: e5933000     	ldr	r3, [r3]
   14bb8: e1520003     	cmp	r2, r3
   14bbc: 0a000009     	beq	0x14be8 <set_log_file+0x8c> @ imm = #0x24
   14bc0: e59f3040     	ldr	r3, [pc, #0x40]         @ 0x14c08 <set_log_file+0xac>
   14bc4: e5932000     	ldr	r2, [r3]
   14bc8: e59f3040     	ldr	r3, [pc, #0x40]         @ 0x14c10 <set_log_file+0xb4>
   14bcc: e5933000     	ldr	r3, [r3]
   14bd0: e1520003     	cmp	r2, r3
   14bd4: 0a000003     	beq	0x14be8 <set_log_file+0x8c> @ imm = #0xc
   14bd8: e59f3028     	ldr	r3, [pc, #0x28]         @ 0x14c08 <set_log_file+0xac>
   14bdc: e5933000     	ldr	r3, [r3]
   14be0: e1a00003     	mov	r0, r3
   14be4: ebffddbe     	bl	0xc2e4 <fclose@plt>     @ imm = #-0x8908
   14be8: e59f3018     	ldr	r3, [pc, #0x18]         @ 0x14c08 <set_log_file+0xac>
   14bec: e51b2008     	ldr	r2, [r11, #-0x8]
   14bf0: e5832000     	str	r2, [r3]
   14bf4: e3a03000     	mov	r3, #0
   14bf8: e1a00003     	mov	r0, r3
   14bfc: e24bd004     	sub	sp, r11, #4
   14c00: e8bd8800     	pop	{r11, pc}
   14c04: d8 29 03 00  	.word	0x000329d8
   14c08: 54 73 05 00  	.word	0x00057354
   14c0c: f4 6d 05 00  	.word	0x00056df4
   14c10: f8 6d 05 00  	.word	0x00056df8

