0001a8ec <DST_CloseDecoder>:
   1a8ec: e92d4800     	push	{r11, lr}
   1a8f0: e28db004     	add	r11, sp, #4
   1a8f4: e24dd010     	sub	sp, sp, #16
   1a8f8: e50b0010     	str	r0, [r11, #-0x10]
   1a8fc: e3a03000     	mov	r3, #0
   1a900: e50b3008     	str	r3, [r11, #-0x8]
   1a904: e51b0010     	ldr	r0, [r11, #-0x10]
   1a908: ebfffe13     	bl	0x1a15c <FreeDecMemory> @ imm = #-0x7b4
   1a90c: e51b3008     	ldr	r3, [r11, #-0x8]
   1a910: e1a00003     	mov	r0, r3
   1a914: e24bd004     	sub	sp, r11, #4
   1a918: e8bd8800     	pop	{r11, pc}

