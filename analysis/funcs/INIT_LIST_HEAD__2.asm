0001eea8 <INIT_LIST_HEAD>:
   1eea8: e52db004     	str	r11, [sp, #-0x4]!
   1eeac: e28db000     	add	r11, sp, #0
   1eeb0: e24dd00c     	sub	sp, sp, #12
   1eeb4: e50b0008     	str	r0, [r11, #-0x8]
   1eeb8: e51b3008     	ldr	r3, [r11, #-0x8]
   1eebc: e51b2008     	ldr	r2, [r11, #-0x8]
   1eec0: e5832000     	str	r2, [r3]
   1eec4: e51b3008     	ldr	r3, [r11, #-0x8]
   1eec8: e51b2008     	ldr	r2, [r11, #-0x8]
   1eecc: e5832004     	str	r2, [r3, #0x4]
   1eed0: e28bd000     	add	sp, r11, #0
   1eed4: e8bd0800     	ldm	sp!, {r11}
   1eed8: e12fff1e     	bx	lr

