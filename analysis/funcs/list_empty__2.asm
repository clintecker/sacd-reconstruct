000278cc <list_empty>:
   278cc: e52db004     	str	r11, [sp, #-0x4]!
   278d0: e28db000     	add	r11, sp, #0
   278d4: e24dd00c     	sub	sp, sp, #12
   278d8: e50b0008     	str	r0, [r11, #-0x8]
   278dc: e51b3008     	ldr	r3, [r11, #-0x8]
   278e0: e5932000     	ldr	r2, [r3]
   278e4: e51b3008     	ldr	r3, [r11, #-0x8]
   278e8: e1520003     	cmp	r2, r3
   278ec: 13a03000     	movne	r3, #0
   278f0: 03a03001     	moveq	r3, #1
   278f4: e1a00003     	mov	r0, r3
   278f8: e28bd000     	add	sp, r11, #0
   278fc: e8bd0800     	ldm	sp!, {r11}
   27900: e12fff1e     	bx	lr

