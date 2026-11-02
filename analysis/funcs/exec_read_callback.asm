0002dde8 <exec_read_callback>:
   2dde8: e92d4800     	push	{r11, lr}
   2ddec: e28db004     	add	r11, sp, #4
   2ddf0: e24dd010     	sub	sp, sp, #16
   2ddf4: e50b0008     	str	r0, [r11, #-0x8]
   2ddf8: e50b100c     	str	r1, [r11, #-0xc]
   2ddfc: e50b2010     	str	r2, [r11, #-0x10]
   2de00: e51b2008     	ldr	r2, [r11, #-0x8]
   2de04: e59f30d4     	ldr	r3, [pc, #0xd4]         @ 0x2dee0 <exec_read_callback+0xf8>
   2de08: e7923003     	ldr	r3, [r2, r3]
   2de0c: e3530000     	cmp	r3, #0
   2de10: 0a000030     	beq	0x2ded8 <exec_read_callback+0xf0> @ imm = #0xc0
   2de14: e51b2008     	ldr	r2, [r11, #-0x8]
   2de18: e59f30c4     	ldr	r3, [pc, #0xc4]         @ 0x2dee4 <exec_read_callback+0xfc>
   2de1c: e7923003     	ldr	r3, [r2, r3]
   2de20: e3530000     	cmp	r3, #0
   2de24: da00002b     	ble	0x2ded8 <exec_read_callback+0xf0> @ imm = #0xac
   2de28: e51b2008     	ldr	r2, [r11, #-0x8]
   2de2c: e59f30b4     	ldr	r3, [pc, #0xb4]         @ 0x2dee8 <exec_read_callback+0x100>
   2de30: e7923003     	ldr	r3, [r2, r3]
   2de34: e3530000     	cmp	r3, #0
   2de38: 0a000004     	beq	0x2de50 <exec_read_callback+0x68> @ imm = #0x10
   2de3c: e51b2008     	ldr	r2, [r11, #-0x8]
   2de40: e59f30a4     	ldr	r3, [pc, #0xa4]         @ 0x2deec <exec_read_callback+0x104>
   2de44: e7923003     	ldr	r3, [r2, r3]
   2de48: e3530000     	cmp	r3, #0
   2de4c: 0a000011     	beq	0x2de98 <exec_read_callback+0xb0> @ imm = #0x44
   2de50: e51b2008     	ldr	r2, [r11, #-0x8]
   2de54: e59f308c     	ldr	r3, [pc, #0x8c]         @ 0x2dee8 <exec_read_callback+0x100>
   2de58: e7923003     	ldr	r3, [r2, r3]
   2de5c: e3530000     	cmp	r3, #0
   2de60: 1a00001c     	bne	0x2ded8 <exec_read_callback+0xf0> @ imm = #0x70
   2de64: e51b2008     	ldr	r2, [r11, #-0x8]
   2de68: e59f3074     	ldr	r3, [pc, #0x74]         @ 0x2dee4 <exec_read_callback+0xfc>
   2de6c: e7922003     	ldr	r2, [r2, r3]
   2de70: e59f3078     	ldr	r3, [pc, #0x78]         @ 0x2def0 <exec_read_callback+0x108>
   2de74: e0c31293     	smull	r1, r3, r3, r2
   2de78: e1a015c3     	asr	r1, r3, #11
   2de7c: e1a03fc2     	asr	r3, r2, #31
   2de80: e0633001     	rsb	r3, r3, r1
   2de84: e59f1068     	ldr	r1, [pc, #0x68]         @ 0x2def4 <exec_read_callback+0x10c>
   2de88: e0030391     	mul	r3, r1, r3
   2de8c: e0633002     	rsb	r3, r3, r2
   2de90: e3530000     	cmp	r3, #0
   2de94: 1a00000f     	bne	0x2ded8 <exec_read_callback+0xf0> @ imm = #0x3c
   2de98: e51b2008     	ldr	r2, [r11, #-0x8]
   2de9c: e59f303c     	ldr	r3, [pc, #0x3c]         @ 0x2dee0 <exec_read_callback+0xf8>
   2dea0: e3a01000     	mov	r1, #0
   2dea4: e7821003     	str	r1, [r2, r3]
   2dea8: e51b2008     	ldr	r2, [r11, #-0x8]
   2deac: e59f3044     	ldr	r3, [pc, #0x44]         @ 0x2def8 <exec_read_callback+0x110>
   2deb0: e7922003     	ldr	r2, [r2, r3]
   2deb4: e51b1008     	ldr	r1, [r11, #-0x8]
   2deb8: e59f3024     	ldr	r3, [pc, #0x24]         @ 0x2dee4 <exec_read_callback+0xfc>
   2debc: e7913003     	ldr	r3, [r1, r3]
   2dec0: e51bc00c     	ldr	r12, [r11, #-0xc]
   2dec4: e51b0008     	ldr	r0, [r11, #-0x8]
   2dec8: e1a01002     	mov	r1, r2
   2decc: e1a02003     	mov	r2, r3
   2ded0: e51b3010     	ldr	r3, [r11, #-0x10]
   2ded4: e12fff3c     	blx	r12
   2ded8: e24bd004     	sub	sp, r11, #4
   2dedc: e8bd8800     	pop	{r11, pc}
   2dee0: 44 70 00 00  	.word	0x00007044
   2dee4: 40 70 00 00  	.word	0x00007040
   2dee8: 50 70 00 00  	.word	0x00007050
   2deec: 48 70 00 00  	.word	0x00007048
   2def0: 27 ae 74 6f  	.word	0x6f74ae27
   2def4: 60 12 00 00  	.word	0x00001260
   2def8: 3c 70 00 00  	.word	0x0000703c

