0002dcf4 <scarletbook_frame_init>:
   2dcf4: e92d4800     	push	{r11, lr}
   2dcf8: e28db004     	add	r11, sp, #4
   2dcfc: e24dd008     	sub	sp, sp, #8
   2dd00: e50b0008     	str	r0, [r11, #-0x8]
   2dd04: e51b2008     	ldr	r2, [r11, #-0x8]
   2dd08: e59f3048     	ldr	r3, [pc, #0x48]         @ 0x2dd58 <scarletbook_frame_init+0x64>
   2dd0c: e3a01000     	mov	r1, #0
   2dd10: e7821003     	str	r1, [r2, r3]
   2dd14: e51b2008     	ldr	r2, [r11, #-0x8]
   2dd18: e59f303c     	ldr	r3, [pc, #0x3c]         @ 0x2dd5c <scarletbook_frame_init+0x68>
   2dd1c: e3a01000     	mov	r1, #0
   2dd20: e7821003     	str	r1, [r2, r3]
   2dd24: e51b2008     	ldr	r2, [r11, #-0x8]
   2dd28: e59f3030     	ldr	r3, [pc, #0x30]         @ 0x2dd60 <scarletbook_frame_init+0x6c>
   2dd2c: e3a01000     	mov	r1, #0
   2dd30: e7821003     	str	r1, [r2, r3]
   2dd34: e51b3008     	ldr	r3, [r11, #-0x8]
   2dd38: e2833a07     	add	r3, r3, #28672
   2dd3c: e2833054     	add	r3, r3, #84
   2dd40: e1a00003     	mov	r0, r3
   2dd44: e3a01000     	mov	r1, #0
   2dd48: e3a0202b     	mov	r2, #43
   2dd4c: ebff7994     	bl	0xc3a4 <memset@plt>     @ imm = #-0x219b0
   2dd50: e24bd004     	sub	sp, r11, #4
   2dd54: e8bd8800     	pop	{r11, pc}
   2dd58: 80 70 00 00  	.word	0x00007080
   2dd5c: 40 70 00 00  	.word	0x00007040
   2dd60: 44 70 00 00  	.word	0x00007044

