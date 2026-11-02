0000c8c0 <is_client_connected>:
    c8c0: e52db004     	str	r11, [sp, #-0x4]!
    c8c4: e28db000     	add	r11, sp, #0
    c8c8: e59f3010     	ldr	r3, [pc, #0x10]         @ 0xc8e0 <is_client_connected+0x20>
    c8cc: e5933000     	ldr	r3, [r3]
    c8d0: e1a00003     	mov	r0, r3
    c8d4: e28bd000     	add	sp, r11, #0
    c8d8: e8bd0800     	ldm	sp!, {r11}
    c8dc: e12fff1e     	bx	lr
    c8e0: 04 6e 05 00  	.word	0x00056e04

