0001f1c0 <ucs>:
   1f1c0: e92d4800     	push	{r11, lr}
   1f1c4: e28db004     	add	r11, sp, #4
   1f1c8: e24dd010     	sub	sp, sp, #16
   1f1cc: e50b0010     	str	r0, [r11, #-0x10]
   1f1d0: e59f3050     	ldr	r3, [pc, #0x50]         @ 0x1f228 <ucs+0x68>
   1f1d4: e50b300c     	str	r3, [r11, #-0xc]
   1f1d8: e51b0010     	ldr	r0, [r11, #-0x10]
   1f1dc: ebffb4be     	bl	0xc4dc <strlen@plt>     @ imm = #-0x12d08
   1f1e0: e1a03000     	mov	r3, r0
   1f1e4: e51b0010     	ldr	r0, [r11, #-0x10]
   1f1e8: e1a01003     	mov	r1, r3
   1f1ec: e59f2038     	ldr	r2, [pc, #0x38]         @ 0x1f22c <ucs+0x6c>
   1f1f0: e51b300c     	ldr	r3, [r11, #-0xc]
   1f1f4: ebffbcbe     	bl	0xe4f4 <charset_convert> @ imm = #-0x10d08
   1f1f8: e1a03000     	mov	r3, r0
   1f1fc: e50b3008     	str	r3, [r11, #-0x8]
   1f200: e51b3008     	ldr	r3, [r11, #-0x8]
   1f204: e59f0024     	ldr	r0, [pc, #0x24]         @ 0x1f230 <ucs+0x70>
   1f208: e1a01003     	mov	r1, r3
   1f20c: ebffb416     	bl	0xc26c <wcscpy@plt>     @ imm = #-0x12fa8
   1f210: e51b0008     	ldr	r0, [r11, #-0x8]
   1f214: ebffb480     	bl	0xc41c <free@plt>       @ imm = #-0x12e00
   1f218: e59f3010     	ldr	r3, [pc, #0x10]         @ 0x1f230 <ucs+0x70>
   1f21c: e1a00003     	mov	r0, r3
   1f220: e24bd004     	sub	sp, r11, #4
   1f224: e8bd8800     	pop	{r11, pc}
   1f228: a8 39 03 00  	.word	0x000339a8
   1f22c: b0 39 03 00  	.word	0x000339b0
   1f230: c0 73 05 00  	.word	0x000573c0

