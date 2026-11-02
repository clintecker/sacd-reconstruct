0002eba4 <sacd_read_block_raw64>:
   2eba4: e92d4800     	push	{r11, lr}
   2eba8: e28db004     	add	r11, sp, #4
   2ebac: e24dd018     	sub	sp, sp, #24
   2ebb0: e50b0010     	str	r0, [r11, #-0x10]
   2ebb4: e50b1014     	str	r1, [r11, #-0x14]
   2ebb8: e50b2018     	str	r2, [r11, #-0x18]
   2ebbc: e50b301c     	str	r3, [r11, #-0x1c]
   2ebc0: e51b3010     	ldr	r3, [r11, #-0x10]
   2ebc4: e5933004     	ldr	r3, [r3, #0x4]
   2ebc8: e3530000     	cmp	r3, #0
   2ebcc: 1a000008     	bne	0x2ebf4 <sacd_read_block_raw64+0x50> @ imm = #0x20
   2ebd0: e59f2060     	ldr	r2, [pc, #0x60]         @ 0x2ec38 <sacd_read_block_raw64+0x94>
   2ebd4: e59f3060     	ldr	r3, [pc, #0x60]         @ 0x2ec3c <sacd_read_block_raw64+0x98>
   2ebd8: e5933000     	ldr	r3, [r3]
   2ebdc: e1a00002     	mov	r0, r2
   2ebe0: e3a01001     	mov	r1, #1
   2ebe4: e3a02028     	mov	r2, #40
   2ebe8: ebff7680     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x22600
   2ebec: e3a03000     	mov	r3, #0
   2ebf0: ea00000d     	b	0x2ec2c <sacd_read_block_raw64+0x88> @ imm = #0x34
   2ebf4: e59f3044     	ldr	r3, [pc, #0x44]         @ 0x2ec40 <sacd_read_block_raw64+0x9c>
   2ebf8: e593c000     	ldr	r12, [r3]
   2ebfc: e51b3010     	ldr	r3, [r11, #-0x10]
   2ec00: e5931004     	ldr	r1, [r3, #0x4]
   2ec04: e51b2014     	ldr	r2, [r11, #-0x14]
   2ec08: e51b3018     	ldr	r3, [r11, #-0x18]
   2ec0c: e1a00001     	mov	r0, r1
   2ec10: e1a01002     	mov	r1, r2
   2ec14: e1a02003     	mov	r2, r3
   2ec18: e51b301c     	ldr	r3, [r11, #-0x1c]
   2ec1c: e12fff3c     	blx	r12
   2ec20: e1a03000     	mov	r3, r0
   2ec24: e50b3008     	str	r3, [r11, #-0x8]
   2ec28: e51b3008     	ldr	r3, [r11, #-0x8]
   2ec2c: e1a00003     	mov	r0, r3
   2ec30: e24bd004     	sub	sp, r11, #4
   2ec34: e8bd8800     	pop	{r11, pc}
   2ec38: 1c 5f 03 00  	.word	0x00035f1c
   2ec3c: f8 6d 05 00  	.word	0x00056df8
   2ec40: 04 9e 05 00  	.word	0x00059e04

