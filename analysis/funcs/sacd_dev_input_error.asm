00021e8c <sacd_dev_input_error>:
   21e8c: e52db004     	str	r11, [sp, #-0x4]!
   21e90: e28db000     	add	r11, sp, #0
   21e94: e24dd00c     	sub	sp, sp, #12
   21e98: e50b0008     	str	r0, [r11, #-0x8]
   21e9c: e59f300c     	ldr	r3, [pc, #0xc]          @ 0x21eb0 <sacd_dev_input_error+0x24>
   21ea0: e1a00003     	mov	r0, r3
   21ea4: e28bd000     	add	sp, r11, #0
   21ea8: e8bd0800     	ldm	sp!, {r11}
   21eac: e12fff1e     	bx	lr
   21eb0: 94 54 03 00  	.word	0x00035494

