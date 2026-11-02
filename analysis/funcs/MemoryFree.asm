00019ed8 <MemoryFree>:
   19ed8: e92d4800     	push	{r11, lr}
   19edc: e28db004     	add	r11, sp, #4
   19ee0: e24dd008     	sub	sp, sp, #8
   19ee4: e50b0008     	str	r0, [r11, #-0x8]
   19ee8: e51b0008     	ldr	r0, [r11, #-0x8]
   19eec: ebffffd4     	bl	0x19e44 <_mm_free>      @ imm = #-0xb0
   19ef0: e24bd004     	sub	sp, r11, #4
   19ef4: e8bd8800     	pop	{r11, pc}

