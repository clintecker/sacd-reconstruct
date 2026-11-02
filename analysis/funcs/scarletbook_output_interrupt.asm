00028d88 <scarletbook_output_interrupt>:
   28d88: e52db004     	str	r11, [sp, #-0x4]!
   28d8c: e28db000     	add	r11, sp, #0
   28d90: e24dd00c     	sub	sp, sp, #12
   28d94: e50b0008     	str	r0, [r11, #-0x8]
   28d98: e51b3008     	ldr	r3, [r11, #-0x8]
   28d9c: e3a02001     	mov	r2, #1
   28da0: e5832010     	str	r2, [r3, #0x10]
   28da4: e28bd000     	add	sp, r11, #0
   28da8: e8bd0800     	ldm	sp!, {r11}
   28dac: e12fff1e     	bx	lr

