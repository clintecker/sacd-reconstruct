000207a8 <pb_ostream_from_socket>:
   207a8: e92d0810     	push	{r4, r11}
   207ac: e28db004     	add	r11, sp, #4
   207b0: e24dd018     	sub	sp, sp, #24
   207b4: e1a0c000     	mov	r12, r0
   207b8: e50b1018     	str	r1, [r11, #-0x18]
   207bc: e59f3038     	ldr	r3, [pc, #0x38]         @ 0x207fc <pb_ostream_from_socket+0x54>
   207c0: e50b3014     	str	r3, [r11, #-0x14]
   207c4: e51b3018     	ldr	r3, [r11, #-0x18]
   207c8: e50b3010     	str	r3, [r11, #-0x10]
   207cc: e3e03000     	mvn	r3, #0
   207d0: e50b300c     	str	r3, [r11, #-0xc]
   207d4: e3a03000     	mov	r3, #0
   207d8: e50b3008     	str	r3, [r11, #-0x8]
   207dc: e1a0400c     	mov	r4, r12
   207e0: e24b3014     	sub	r3, r11, #20
   207e4: e893000f     	ldm	r3, {r0, r1, r2, r3}
   207e8: e884000f     	stm	r4, {r0, r1, r2, r3}
   207ec: e1a0000c     	mov	r0, r12
   207f0: e24bd004     	sub	sp, r11, #4
   207f4: e8bd0810     	pop	{r4, r11}
   207f8: e12fff1e     	bx	lr
   207fc: f0 05 02 00  	.word	0x000205f0

