0000c908 <requested_for_exit>:
    c908: e52db004     	str	r11, [sp, #-0x4]!
    c90c: e28db000     	add	r11, sp, #0
    c910: e24dd00c     	sub	sp, sp, #12
    c914: e50b0008     	str	r0, [r11, #-0x8]
    c918: e59f3010     	ldr	r3, [pc, #0x10]         @ 0xc930 <requested_for_exit+0x28>
    c91c: e51b2008     	ldr	r2, [r11, #-0x8]
    c920: e5832000     	str	r2, [r3]
    c924: e28bd000     	add	sp, r11, #0
    c928: e8bd0800     	ldm	sp!, {r11}
    c92c: e12fff1e     	bx	lr
    c930: 08 6e 05 00  	.word	0x00056e08

