00029754 <has_two_channel>:
   29754: e52db004     	str	r11, [sp, #-0x4]!
   29758: e28db000     	add	r11, sp, #0
   2975c: e24dd00c     	sub	sp, sp, #12
   29760: e50b0008     	str	r0, [r11, #-0x8]
   29764: e51b3008     	ldr	r3, [r11, #-0x8]
   29768: e5933050     	ldr	r3, [r3, #0x50]
   2976c: e3730001     	cmn	r3, #1
   29770: 03a03000     	moveq	r3, #0
   29774: 13a03001     	movne	r3, #1
   29778: e1a00003     	mov	r0, r3
   2977c: e28bd000     	add	sp, r11, #0
   29780: e8bd0800     	ldm	sp!, {r11}
   29784: e12fff1e     	bx	lr

