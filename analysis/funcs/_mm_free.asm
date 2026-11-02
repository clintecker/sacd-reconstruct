00019e44 <_mm_free>:
   19e44: e92d4800     	push	{r11, lr}
   19e48: e28db004     	add	r11, sp, #4
   19e4c: e24dd008     	sub	sp, sp, #8
   19e50: e50b0008     	str	r0, [r11, #-0x8]
   19e54: e51b0008     	ldr	r0, [r11, #-0x8]
   19e58: ebffc96f     	bl	0xc41c <free@plt>       @ imm = #-0xda44
   19e5c: e24bd004     	sub	sp, r11, #4
   19e60: e8bd8800     	pop	{r11, pc}

