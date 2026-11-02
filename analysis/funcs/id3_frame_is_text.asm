0001dd74 <id3_frame_is_text>:
   1dd74: e52db004     	str	r11, [sp, #-0x4]!
   1dd78: e28db000     	add	r11, sp, #0
   1dd7c: e24dd00c     	sub	sp, sp, #12
   1dd80: e50b0008     	str	r0, [r11, #-0x8]
   1dd84: e51b3008     	ldr	r3, [r11, #-0x8]
   1dd88: e3530000     	cmp	r3, #0
   1dd8c: 0a00000f     	beq	0x1ddd0 <id3_frame_is_text+0x5c> @ imm = #0x3c
   1dd90: e51b3008     	ldr	r3, [r11, #-0x8]
   1dd94: e5933004     	ldr	r3, [r3, #0x4]
   1dd98: e3530000     	cmp	r3, #0
   1dd9c: 0a00000b     	beq	0x1ddd0 <id3_frame_is_text+0x5c> @ imm = #0x2c
   1dda0: e51b3008     	ldr	r3, [r11, #-0x8]
   1dda4: e5933004     	ldr	r3, [r3, #0x4]
   1dda8: e5d33004     	ldrb	r3, [r3, #0x4]
   1ddac: e3530054     	cmp	r3, #84
   1ddb0: 0a000004     	beq	0x1ddc8 <id3_frame_is_text+0x54> @ imm = #0x10
   1ddb4: e51b3008     	ldr	r3, [r11, #-0x8]
   1ddb8: e5933004     	ldr	r3, [r3, #0x4]
   1ddbc: e5d33004     	ldrb	r3, [r3, #0x4]
   1ddc0: e3530057     	cmp	r3, #87
   1ddc4: 1a000001     	bne	0x1ddd0 <id3_frame_is_text+0x5c> @ imm = #0x4
   1ddc8: e3a03001     	mov	r3, #1
   1ddcc: ea000000     	b	0x1ddd4 <id3_frame_is_text+0x60> @ imm = #0x0
   1ddd0: e3a03000     	mov	r3, #0
   1ddd4: e1a00003     	mov	r0, r3
   1ddd8: e28bd000     	add	sp, r11, #0
   1dddc: e8bd0800     	ldm	sp!, {r11}
   1dde0: e12fff1e     	bx	lr

