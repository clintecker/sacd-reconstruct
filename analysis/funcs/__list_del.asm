0001c214 <__list_del>:
   1c214: e52db004     	str	r11, [sp, #-0x4]!
   1c218: e28db000     	add	r11, sp, #0
   1c21c: e24dd00c     	sub	sp, sp, #12
   1c220: e50b0008     	str	r0, [r11, #-0x8]
   1c224: e50b100c     	str	r1, [r11, #-0xc]
   1c228: e51b300c     	ldr	r3, [r11, #-0xc]
   1c22c: e51b2008     	ldr	r2, [r11, #-0x8]
   1c230: e5832004     	str	r2, [r3, #0x4]
   1c234: e51b3008     	ldr	r3, [r11, #-0x8]
   1c238: e51b200c     	ldr	r2, [r11, #-0xc]
   1c23c: e5832000     	str	r2, [r3]
   1c240: e28bd000     	add	sp, r11, #0
   1c244: e8bd0800     	ldm	sp!, {r11}
   1c248: e12fff1e     	bx	lr

