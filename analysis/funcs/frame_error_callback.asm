000283b0 <frame_error_callback>:
   283b0: e92d4800     	push	{r11, lr}
   283b4: e28db004     	add	r11, sp, #4
   283b8: e24dd018     	sub	sp, sp, #24
   283bc: e50b0010     	str	r0, [r11, #-0x10]
   283c0: e50b1014     	str	r1, [r11, #-0x14]
   283c4: e50b2018     	str	r2, [r11, #-0x18]
   283c8: e50b301c     	str	r3, [r11, #-0x1c]
   283cc: e51b301c     	ldr	r3, [r11, #-0x1c]
   283d0: e50b300c     	str	r3, [r11, #-0xc]
   283d4: e51b0018     	ldr	r0, [r11, #-0x18]
   283d8: ebff903f     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1bf04
   283dc: e1a03000     	mov	r3, r0
   283e0: e51b0018     	ldr	r0, [r11, #-0x18]
   283e4: e1a01003     	mov	r1, r3
   283e8: e59f2040     	ldr	r2, [pc, #0x40]         @ 0x28430 <frame_error_callback+0x80>
   283ec: e59f3040     	ldr	r3, [pc, #0x40]         @ 0x28434 <frame_error_callback+0x84>
   283f0: ebff983f     	bl	0xe4f4 <charset_convert> @ imm = #-0x19f04
   283f4: e1a03000     	mov	r3, r0
   283f8: e50b3008     	str	r3, [r11, #-0x8]
   283fc: e51b300c     	ldr	r3, [r11, #-0xc]
   28400: e593c16c     	ldr	r12, [r3, #0x16c]
   28404: e59f302c     	ldr	r3, [pc, #0x2c]         @ 0x28438 <frame_error_callback+0x88>
   28408: e5933000     	ldr	r3, [r3]
   2840c: e1a00003     	mov	r0, r3
   28410: e59f1024     	ldr	r1, [pc, #0x24]         @ 0x2843c <frame_error_callback+0x8c>
   28414: e51b2008     	ldr	r2, [r11, #-0x8]
   28418: e51b3010     	ldr	r3, [r11, #-0x10]
   2841c: e12fff3c     	blx	r12
   28420: e51b0008     	ldr	r0, [r11, #-0x8]
   28424: ebff8ffc     	bl	0xc41c <free@plt>       @ imm = #-0x1c010
   28428: e24bd004     	sub	sp, r11, #4
   2842c: e8bd8800     	pop	{r11, pc}
   28430: 48 57 03 00  	.word	0x00035748
   28434: 50 57 03 00  	.word	0x00035750
   28438: f8 6d 05 00  	.word	0x00056df8
   2843c: 58 57 03 00  	.word	0x00035758

