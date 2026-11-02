0001b59c <ResetReadingIndex>:
   1b59c: e52db004     	str	r11, [sp, #-0x4]!
   1b5a0: e28db000     	add	r11, sp, #0
   1b5a4: e24dd014     	sub	sp, sp, #20
   1b5a8: e50b0010     	str	r0, [r11, #-0x10]
   1b5ac: e3a03000     	mov	r3, #0
   1b5b0: e50b3008     	str	r3, [r11, #-0x8]
   1b5b4: e51b3010     	ldr	r3, [r11, #-0x10]
   1b5b8: e3a02000     	mov	r2, #0
   1b5bc: e583200c     	str	r2, [r3, #0xc]
   1b5c0: e51b3010     	ldr	r3, [r11, #-0x10]
   1b5c4: e3a02000     	mov	r2, #0
   1b5c8: e5832008     	str	r2, [r3, #0x8]
   1b5cc: e51b3010     	ldr	r3, [r11, #-0x10]
   1b5d0: e3a02000     	mov	r2, #0
   1b5d4: e5c32010     	strb	r2, [r3, #0x10]
   1b5d8: e51b3008     	ldr	r3, [r11, #-0x8]
   1b5dc: e1a00003     	mov	r0, r3
   1b5e0: e28bd000     	add	sp, r11, #0
   1b5e4: e8bd0800     	ldm	sp!, {r11}
   1b5e8: e12fff1e     	bx	lr

