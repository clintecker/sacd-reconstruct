0001a91c <processor_count>:
   1a91c: e92d4800     	push	{r11, lr}
   1a920: e28db004     	add	r11, sp, #4
   1a924: ebffc644     	bl	0xc23c <get_nprocs@plt> @ imm = #-0xe6f0
   1a928: e1a03000     	mov	r3, r0
   1a92c: e1a00003     	mov	r0, r3
   1a930: e8bd8800     	pop	{r11, pc}

