0002eb04 <sacd_read_block_raw>:
   2eb04: e92d4800     	push	{r11, lr}
   2eb08: e28db004     	add	r11, sp, #4
   2eb0c: e24dd018     	sub	sp, sp, #24
   2eb10: e50b0010     	str	r0, [r11, #-0x10]
   2eb14: e50b1014     	str	r1, [r11, #-0x14]
   2eb18: e50b2018     	str	r2, [r11, #-0x18]
   2eb1c: e50b301c     	str	r3, [r11, #-0x1c]
   2eb20: e51b3010     	ldr	r3, [r11, #-0x10]
   2eb24: e5933004     	ldr	r3, [r3, #0x4]
   2eb28: e3530000     	cmp	r3, #0
   2eb2c: 1a000008     	bne	0x2eb54 <sacd_read_block_raw+0x50> @ imm = #0x20
   2eb30: e59f2060     	ldr	r2, [pc, #0x60]         @ 0x2eb98 <sacd_read_block_raw+0x94>
   2eb34: e59f3060     	ldr	r3, [pc, #0x60]         @ 0x2eb9c <sacd_read_block_raw+0x98>
   2eb38: e5933000     	ldr	r3, [r3]
   2eb3c: e1a00002     	mov	r0, r2
   2eb40: e3a01001     	mov	r1, #1
   2eb44: e3a02028     	mov	r2, #40
   2eb48: ebff76a8     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x22560
   2eb4c: e3a03000     	mov	r3, #0
   2eb50: ea00000d     	b	0x2eb8c <sacd_read_block_raw+0x88> @ imm = #0x34
   2eb54: e59f3044     	ldr	r3, [pc, #0x44]         @ 0x2eba0 <sacd_read_block_raw+0x9c>
   2eb58: e593c000     	ldr	r12, [r3]
   2eb5c: e51b3010     	ldr	r3, [r11, #-0x10]
   2eb60: e5931004     	ldr	r1, [r3, #0x4]
   2eb64: e51b2014     	ldr	r2, [r11, #-0x14]
   2eb68: e51b3018     	ldr	r3, [r11, #-0x18]
   2eb6c: e1a00001     	mov	r0, r1
   2eb70: e1a01002     	mov	r1, r2
   2eb74: e1a02003     	mov	r2, r3
   2eb78: e51b301c     	ldr	r3, [r11, #-0x1c]
   2eb7c: e12fff3c     	blx	r12
   2eb80: e1a03000     	mov	r3, r0
   2eb84: e50b3008     	str	r3, [r11, #-0x8]
   2eb88: e51b3008     	ldr	r3, [r11, #-0x8]
   2eb8c: e1a00003     	mov	r0, r3
   2eb90: e24bd004     	sub	sp, r11, #4
   2eb94: e8bd8800     	pop	{r11, pc}
   2eb98: 1c 5f 03 00  	.word	0x00035f1c
   2eb9c: f8 6d 05 00  	.word	0x00056df8
   2eba0: 14 9e 05 00  	.word	0x00059e14

