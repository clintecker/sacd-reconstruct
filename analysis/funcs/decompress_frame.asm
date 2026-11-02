0001c75c <decompress_frame>:
   1c75c: e52db004     	str	r11, [sp, #-0x4]!
   1c760: e28db000     	add	r11, sp, #0
   1c764: e24dd00c     	sub	sp, sp, #12
   1c768: e50b0008     	str	r0, [r11, #-0x8]
   1c76c: e3e03000     	mvn	r3, #0
   1c770: e1a00003     	mov	r0, r3
   1c774: e28bd000     	add	sp, r11, #0
   1c778: e8bd0800     	ldm	sp!, {r11}
   1c77c: e12fff1e     	bx	lr

