0001e040 <INIT_LIST_HEAD>:
   1e040: e52db004     	str	r11, [sp, #-0x4]!
   1e044: e28db000     	add	r11, sp, #0
   1e048: e24dd00c     	sub	sp, sp, #12
   1e04c: e50b0008     	str	r0, [r11, #-0x8]
   1e050: e51b3008     	ldr	r3, [r11, #-0x8]
   1e054: e51b2008     	ldr	r2, [r11, #-0x8]
   1e058: e5832000     	str	r2, [r3]
   1e05c: e51b3008     	ldr	r3, [r11, #-0x8]
   1e060: e51b2008     	ldr	r2, [r11, #-0x8]
   1e064: e5832004     	str	r2, [r3, #0x4]
   1e068: e28bd000     	add	sp, r11, #0
   1e06c: e8bd0800     	ldm	sp!, {r11}
   1e070: e12fff1e     	bx	lr

