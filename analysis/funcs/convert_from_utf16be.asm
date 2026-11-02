0001d1f0 <convert_from_utf16be>:
   1d1f0: e92d4800     	push	{r11, lr}
   1d1f4: e28db004     	add	r11, sp, #4
   1d1f8: e24dd008     	sub	sp, sp, #8
   1d1fc: e50b0008     	str	r0, [r11, #-0x8]
   1d200: e51b0008     	ldr	r0, [r11, #-0x8]
   1d204: e3a01000     	mov	r1, #0
   1d208: ebffff60     	bl	0x1cf90 <to_ascii>      @ imm = #-0x280
   1d20c: e1a03000     	mov	r3, r0
   1d210: e1a00003     	mov	r0, r3
   1d214: e24bd004     	sub	sp, r11, #4
   1d218: e8bd8800     	pop	{r11, pc}

