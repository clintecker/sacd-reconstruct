00015a48 <peek_lock>:
   15a48: e52db004     	str	r11, [sp, #-0x4]!
   15a4c: e28db000     	add	r11, sp, #0
   15a50: e24dd00c     	sub	sp, sp, #12
   15a54: e50b0008     	str	r0, [r11, #-0x8]
   15a58: e51b3008     	ldr	r3, [r11, #-0x8]
   15a5c: e5933048     	ldr	r3, [r3, #0x48]
   15a60: e1a00003     	mov	r0, r3
   15a64: e28bd000     	add	sp, r11, #0
   15a68: e8bd0800     	ldm	sp!, {r11}
   15a6c: e12fff1e     	bx	lr

