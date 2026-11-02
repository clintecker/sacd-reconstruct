0001033c <timeout_markstart>:
   1033c: e92d4800     	push	{r11, lr}
   10340: e28db004     	add	r11, sp, #4
   10344: e24dd008     	sub	sp, sp, #8
   10348: e50b0008     	str	r0, [r11, #-0x8]
   1034c: eb000007     	bl	0x10370 <timeout_gettime> @ imm = #0x1c
   10350: e1a02000     	mov	r2, r0
   10354: e1a03001     	mov	r3, r1
   10358: e51b1008     	ldr	r1, [r11, #-0x8]
   1035c: e1c121f0     	strd	r2, r3, [r1, #16]
   10360: e51b3008     	ldr	r3, [r11, #-0x8]
   10364: e1a00003     	mov	r0, r3
   10368: e24bd004     	sub	sp, r11, #4
   1036c: e8bd8800     	pop	{r11, pc}

