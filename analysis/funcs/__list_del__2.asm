00027840 <__list_del>:
   27840: e52db004     	str	r11, [sp, #-0x4]!
   27844: e28db000     	add	r11, sp, #0
   27848: e24dd00c     	sub	sp, sp, #12
   2784c: e50b0008     	str	r0, [r11, #-0x8]
   27850: e50b100c     	str	r1, [r11, #-0xc]
   27854: e51b300c     	ldr	r3, [r11, #-0xc]
   27858: e51b2008     	ldr	r2, [r11, #-0x8]
   2785c: e5832004     	str	r2, [r3, #0x4]
   27860: e51b3008     	ldr	r3, [r11, #-0x8]
   27864: e51b200c     	ldr	r2, [r11, #-0xc]
   27868: e5832000     	str	r2, [r3]
   2786c: e28bd000     	add	sp, r11, #0
   27870: e8bd0800     	ldm	sp!, {r11}
   27874: e12fff1e     	bx	lr

