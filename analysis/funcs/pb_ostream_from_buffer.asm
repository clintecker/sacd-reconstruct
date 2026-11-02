0001163c <pb_ostream_from_buffer>:
   1163c: e92d0810     	push	{r4, r11}
   11640: e28db004     	add	r11, sp, #4
   11644: e24dd018     	sub	sp, sp, #24
   11648: e1a0c000     	mov	r12, r0
   1164c: e50b1018     	str	r1, [r11, #-0x18]
   11650: e50b201c     	str	r2, [r11, #-0x1c]
   11654: e59f3038     	ldr	r3, [pc, #0x38]         @ 0x11694 <pb_ostream_from_buffer+0x58>
   11658: e50b3014     	str	r3, [r11, #-0x14]
   1165c: e51b3018     	ldr	r3, [r11, #-0x18]
   11660: e50b3010     	str	r3, [r11, #-0x10]
   11664: e51b301c     	ldr	r3, [r11, #-0x1c]
   11668: e50b300c     	str	r3, [r11, #-0xc]
   1166c: e3a03000     	mov	r3, #0
   11670: e50b3008     	str	r3, [r11, #-0x8]
   11674: e1a0400c     	mov	r4, r12
   11678: e24b3014     	sub	r3, r11, #20
   1167c: e893000f     	ldm	r3, {r0, r1, r2, r3}
   11680: e884000f     	stm	r4, {r0, r1, r2, r3}
   11684: e1a0000c     	mov	r0, r12
   11688: e24bd004     	sub	sp, r11, #4
   1168c: e8bd0810     	pop	{r4, r11}
   11690: e12fff1e     	bx	lr
   11694: e4 15 01 00  	.word	0x000115e4

