000128e4 <socket_open>:
   128e4: e92d4800     	push	{r11, lr}
   128e8: e28db004     	add	r11, sp, #4
   128ec: e3a0000d     	mov	r0, #13
   128f0: e3a01001     	mov	r1, #1
   128f4: ebffe66e     	bl	0xc2b4 <signal@plt>     @ imm = #-0x6648
   128f8: e3a03001     	mov	r3, #1
   128fc: e1a00003     	mov	r0, r3
   12900: e8bd8800     	pop	{r11, pc}

