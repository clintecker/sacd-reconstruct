0002f950 <dsf_format_fn>:
   2f950: e52db004     	str	r11, [sp, #-0x4]!
   2f954: e28db000     	add	r11, sp, #0
   2f958: e59f300c     	ldr	r3, [pc, #0xc]          @ 0x2f96c <dsf_format_fn+0x1c>
   2f95c: e1a00003     	mov	r0, r3
   2f960: e28bd000     	add	sp, r11, #0
   2f964: e8bd0800     	ldm	sp!, {r11}
   2f968: e12fff1e     	bx	lr
   2f96c: 1c ef 03 00  	.word	0x0003ef1c

