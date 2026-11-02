00028cd4 <scarletbook_output_is_busy>:
   28cd4: e52db004     	str	r11, [sp, #-0x4]!
   28cd8: e28db000     	add	r11, sp, #0
   28cdc: e24dd00c     	sub	sp, sp, #12
   28ce0: e50b0008     	str	r0, [r11, #-0x8]
   28ce4: e51b3008     	ldr	r3, [r11, #-0x8]
   28ce8: e5933014     	ldr	r3, [r3, #0x14]
   28cec: e1a00003     	mov	r0, r3
   28cf0: e28bd000     	add	sp, r11, #0
   28cf4: e8bd0800     	ldm	sp!, {r11}
   28cf8: e12fff1e     	bx	lr

