000221ec <sacd_net_input_decrypt>:
   221ec: e52db004     	str	r11, [sp, #-0x4]!
   221f0: e28db000     	add	r11, sp, #0
   221f4: e24dd014     	sub	sp, sp, #20
   221f8: e50b0008     	str	r0, [r11, #-0x8]
   221fc: e50b100c     	str	r1, [r11, #-0xc]
   22200: e50b2010     	str	r2, [r11, #-0x10]
   22204: e3a03000     	mov	r3, #0
   22208: e1a00003     	mov	r0, r3
   2220c: e28bd000     	add	sp, r11, #0
   22210: e8bd0800     	ldm	sp!, {r11}
   22214: e12fff1e     	bx	lr

