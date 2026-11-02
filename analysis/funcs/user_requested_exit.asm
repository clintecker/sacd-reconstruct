0000c8e4 <user_requested_exit>:
    c8e4: e52db004     	str	r11, [sp, #-0x4]!
    c8e8: e28db000     	add	r11, sp, #0
    c8ec: e59f3010     	ldr	r3, [pc, #0x10]         @ 0xc904 <user_requested_exit+0x20>
    c8f0: e5933000     	ldr	r3, [r3]
    c8f4: e1a00003     	mov	r0, r3
    c8f8: e28bd000     	add	sp, r11, #0
    c8fc: e8bd0800     	ldm	sp!, {r11}
    c900: e12fff1e     	bx	lr
    c904: 08 6e 05 00  	.word	0x00056e08

