0000d0c8 <has_two_channel>:
    d0c8: e52db004     	str	r11, [sp, #-0x4]!
    d0cc: e28db000     	add	r11, sp, #0
    d0d0: e24dd00c     	sub	sp, sp, #12
    d0d4: e50b0008     	str	r0, [r11, #-0x8]
    d0d8: e51b3008     	ldr	r3, [r11, #-0x8]
    d0dc: e5933050     	ldr	r3, [r3, #0x50]
    d0e0: e3730001     	cmn	r3, #1
    d0e4: 03a03000     	moveq	r3, #0
    d0e8: 13a03001     	movne	r3, #1
    d0ec: e1a00003     	mov	r0, r3
    d0f0: e28bd000     	add	sp, r11, #0
    d0f4: e8bd0800     	ldm	sp!, {r11}
    d0f8: e12fff1e     	bx	lr

