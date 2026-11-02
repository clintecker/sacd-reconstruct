0001c18c <__list_add>:
   1c18c: e52db004     	str	r11, [sp, #-0x4]!
   1c190: e28db000     	add	r11, sp, #0
   1c194: e24dd014     	sub	sp, sp, #20
   1c198: e50b0008     	str	r0, [r11, #-0x8]
   1c19c: e50b100c     	str	r1, [r11, #-0xc]
   1c1a0: e50b2010     	str	r2, [r11, #-0x10]
   1c1a4: e51b3010     	ldr	r3, [r11, #-0x10]
   1c1a8: e51b2008     	ldr	r2, [r11, #-0x8]
   1c1ac: e5832004     	str	r2, [r3, #0x4]
   1c1b0: e51b3008     	ldr	r3, [r11, #-0x8]
   1c1b4: e51b2010     	ldr	r2, [r11, #-0x10]
   1c1b8: e5832000     	str	r2, [r3]
   1c1bc: e51b3008     	ldr	r3, [r11, #-0x8]
   1c1c0: e51b200c     	ldr	r2, [r11, #-0xc]
   1c1c4: e5832004     	str	r2, [r3, #0x4]
   1c1c8: e51b300c     	ldr	r3, [r11, #-0xc]
   1c1cc: e51b2008     	ldr	r2, [r11, #-0x8]
   1c1d0: e5832000     	str	r2, [r3]
   1c1d4: e28bd000     	add	sp, r11, #0
   1c1d8: e8bd0800     	ldm	sp!, {r11}
   1c1dc: e12fff1e     	bx	lr

