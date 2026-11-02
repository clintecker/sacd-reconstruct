0001bd54 <get_in_bitcount>:
   1bd54: e52db004     	str	r11, [sp, #-0x4]!
   1bd58: e28db000     	add	r11, sp, #0
   1bd5c: e24dd00c     	sub	sp, sp, #12
   1bd60: e50b0008     	str	r0, [r11, #-0x8]
   1bd64: e51b3008     	ldr	r3, [r11, #-0x8]
   1bd68: e5933008     	ldr	r3, [r3, #0x8]
   1bd6c: e1a02183     	lsl	r2, r3, #3
   1bd70: e51b3008     	ldr	r3, [r11, #-0x8]
   1bd74: e593300c     	ldr	r3, [r3, #0xc]
   1bd78: e0633002     	rsb	r3, r3, r2
   1bd7c: e1a00003     	mov	r0, r3
   1bd80: e28bd000     	add	sp, r11, #0
   1bd84: e8bd0800     	ldm	sp!, {r11}
   1bd88: e12fff1e     	bx	lr

