0001d14c <convert_from_utf16>:
   1d14c: e92d4800     	push	{r11, lr}
   1d150: e28db004     	add	r11, sp, #4
   1d154: e24dd010     	sub	sp, sp, #16
   1d158: e50b0010     	str	r0, [r11, #-0x10]
   1d15c: e3a03000     	mov	r3, #0
   1d160: e50b300c     	str	r3, [r11, #-0xc]
   1d164: e51b3010     	ldr	r3, [r11, #-0x10]
   1d168: e5d33000     	ldrb	r3, [r3]
   1d16c: e1a03403     	lsl	r3, r3, #8
   1d170: e6ff2073     	uxth	r2, r3
   1d174: e51b3010     	ldr	r3, [r11, #-0x10]
   1d178: e2833001     	add	r3, r3, #1
   1d17c: e5d33000     	ldrb	r3, [r3]
   1d180: e1823003     	orr	r3, r2, r3
   1d184: e6ff3073     	uxth	r3, r3
   1d188: e14b30b6     	strh	r3, [r11, #-6]
   1d18c: e15b20b6     	ldrh	r2, [r11, #-6]
   1d190: e59f304c     	ldr	r3, [pc, #0x4c]         @ 0x1d1e4 <convert_from_utf16+0x98>
   1d194: e1520003     	cmp	r2, r3
   1d198: 1a000002     	bne	0x1d1a8 <convert_from_utf16+0x5c> @ imm = #0x8
   1d19c: e3a03001     	mov	r3, #1
   1d1a0: e50b300c     	str	r3, [r11, #-0xc]
   1d1a4: ea000007     	b	0x1d1c8 <convert_from_utf16+0x7c> @ imm = #0x1c
   1d1a8: e15b20b6     	ldrh	r2, [r11, #-6]
   1d1ac: e59f3034     	ldr	r3, [pc, #0x34]         @ 0x1d1e8 <convert_from_utf16+0x9c>
   1d1b0: e1520003     	cmp	r2, r3
   1d1b4: 0a000003     	beq	0x1d1c8 <convert_from_utf16+0x7c> @ imm = #0xc
   1d1b8: e59f002c     	ldr	r0, [pc, #0x2c]         @ 0x1d1ec <convert_from_utf16+0xa0>
   1d1bc: ebffbd23     	bl	0xc650 <strdup@plt>     @ imm = #-0x10b74
   1d1c0: e1a03000     	mov	r3, r0
   1d1c4: ea000003     	b	0x1d1d8 <convert_from_utf16+0x8c> @ imm = #0xc
   1d1c8: e51b0010     	ldr	r0, [r11, #-0x10]
   1d1cc: e51b100c     	ldr	r1, [r11, #-0xc]
   1d1d0: ebffff6e     	bl	0x1cf90 <to_ascii>      @ imm = #-0x248
   1d1d4: e1a03000     	mov	r3, r0
   1d1d8: e1a00003     	mov	r0, r3
   1d1dc: e24bd004     	sub	sp, r11, #4
   1d1e0: e8bd8800     	pop	{r11, pc}
   1d1e4: fe ff 00 00  	.word	0x0000fffe
   1d1e8: ff fe 00 00  	.word	0x0000feff
   1d1ec: 10 39 03 00  	.word	0x00033910

