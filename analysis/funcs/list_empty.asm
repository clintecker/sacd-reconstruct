0001c2a0 <list_empty>:
   1c2a0: e52db004     	str	r11, [sp, #-0x4]!
   1c2a4: e28db000     	add	r11, sp, #0
   1c2a8: e24dd00c     	sub	sp, sp, #12
   1c2ac: e50b0008     	str	r0, [r11, #-0x8]
   1c2b0: e51b3008     	ldr	r3, [r11, #-0x8]
   1c2b4: e5932000     	ldr	r2, [r3]
   1c2b8: e51b3008     	ldr	r3, [r11, #-0x8]
   1c2bc: e1520003     	cmp	r2, r3
   1c2c0: 13a03000     	movne	r3, #0
   1c2c4: 03a03001     	moveq	r3, #1
   1c2c8: e1a00003     	mov	r0, r3
   1c2cc: e28bd000     	add	sp, r11, #0
   1c2d0: e8bd0800     	ldm	sp!, {r11}
   1c2d4: e12fff1e     	bx	lr

