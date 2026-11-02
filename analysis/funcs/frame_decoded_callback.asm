00028378 <frame_decoded_callback>:
   28378: e92d4800     	push	{r11, lr}
   2837c: e28db004     	add	r11, sp, #4
   28380: e24dd018     	sub	sp, sp, #24
   28384: e50b0010     	str	r0, [r11, #-0x10]
   28388: e50b1014     	str	r1, [r11, #-0x14]
   2838c: e50b2018     	str	r2, [r11, #-0x18]
   28390: e51b3018     	ldr	r3, [r11, #-0x18]
   28394: e50b3008     	str	r3, [r11, #-0x8]
   28398: e51b0008     	ldr	r0, [r11, #-0x8]
   2839c: e51b1010     	ldr	r1, [r11, #-0x10]
   283a0: e51b2014     	ldr	r2, [r11, #-0x14]
   283a4: ebffffd2     	bl	0x282f4 <write_block>   @ imm = #-0xb8
   283a8: e24bd004     	sub	sp, r11, #4
   283ac: e8bd8800     	pop	{r11, pc}

