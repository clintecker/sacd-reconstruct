0001b55c <GetDSTDataPointer>:
   1b55c: e52db004     	str	r11, [sp, #-0x4]!
   1b560: e28db000     	add	r11, sp, #0
   1b564: e24dd014     	sub	sp, sp, #20
   1b568: e50b0010     	str	r0, [r11, #-0x10]
   1b56c: e50b1014     	str	r1, [r11, #-0x14]
   1b570: e3a03000     	mov	r3, #0
   1b574: e50b3008     	str	r3, [r11, #-0x8]
   1b578: e51b3010     	ldr	r3, [r11, #-0x10]
   1b57c: e5932000     	ldr	r2, [r3]
   1b580: e51b3014     	ldr	r3, [r11, #-0x14]
   1b584: e5832000     	str	r2, [r3]
   1b588: e51b3008     	ldr	r3, [r11, #-0x8]
   1b58c: e1a00003     	mov	r0, r3
   1b590: e28bd000     	add	sp, r11, #0
   1b594: e8bd0800     	ldm	sp!, {r11}
   1b598: e12fff1e     	bx	lr

