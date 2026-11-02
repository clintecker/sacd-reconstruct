0002780c <list_add_tail>:
   2780c: e92d4800     	push	{r11, lr}
   27810: e28db004     	add	r11, sp, #4
   27814: e24dd008     	sub	sp, sp, #8
   27818: e50b0008     	str	r0, [r11, #-0x8]
   2781c: e50b100c     	str	r1, [r11, #-0xc]
   27820: e51b300c     	ldr	r3, [r11, #-0xc]
   27824: e5933004     	ldr	r3, [r3, #0x4]
   27828: e51b0008     	ldr	r0, [r11, #-0x8]
   2782c: e1a01003     	mov	r1, r3
   27830: e51b200c     	ldr	r2, [r11, #-0xc]
   27834: ebffffdf     	bl	0x277b8 <__list_add>    @ imm = #-0x84
   27838: e24bd004     	sub	sp, r11, #4
   2783c: e8bd8800     	pop	{r11, pc}

