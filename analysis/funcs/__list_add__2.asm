000277b8 <__list_add>:
   277b8: e52db004     	str	r11, [sp, #-0x4]!
   277bc: e28db000     	add	r11, sp, #0
   277c0: e24dd014     	sub	sp, sp, #20
   277c4: e50b0008     	str	r0, [r11, #-0x8]
   277c8: e50b100c     	str	r1, [r11, #-0xc]
   277cc: e50b2010     	str	r2, [r11, #-0x10]
   277d0: e51b3010     	ldr	r3, [r11, #-0x10]
   277d4: e51b2008     	ldr	r2, [r11, #-0x8]
   277d8: e5832004     	str	r2, [r3, #0x4]
   277dc: e51b3008     	ldr	r3, [r11, #-0x8]
   277e0: e51b2010     	ldr	r2, [r11, #-0x10]
   277e4: e5832000     	str	r2, [r3]
   277e8: e51b3008     	ldr	r3, [r11, #-0x8]
   277ec: e51b200c     	ldr	r2, [r11, #-0xc]
   277f0: e5832004     	str	r2, [r3, #0x4]
   277f4: e51b300c     	ldr	r3, [r11, #-0xc]
   277f8: e51b2008     	ldr	r2, [r11, #-0x8]
   277fc: e5832000     	str	r2, [r3]
   27800: e28bd000     	add	sp, r11, #0
   27804: e8bd0800     	ldm	sp!, {r11}
   27808: e12fff1e     	bx	lr

