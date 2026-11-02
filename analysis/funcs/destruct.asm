00016040 <destruct>:
   16040: e92d4800     	push	{r11, lr}
   16044: e28db004     	add	r11, sp, #4
   16048: e24dd010     	sub	sp, sp, #16
   1604c: e50b0010     	str	r0, [r11, #-0x10]
   16050: e51b3010     	ldr	r3, [r11, #-0x10]
   16054: e5933000     	ldr	r3, [r3]
   16058: e1a00003     	mov	r0, r3
   1605c: ebffd9e4     	bl	0xc7f4 <pthread_cancel@plt> @ imm = #-0x9870
   16060: e1a03000     	mov	r3, r0
   16064: e50b3008     	str	r3, [r11, #-0x8]
   16068: e51b3008     	ldr	r3, [r11, #-0x8]
   1606c: e3530000     	cmp	r3, #0
   16070: 0a000001     	beq	0x1607c <destruct+0x3c> @ imm = #0x4
   16074: e51b0008     	ldr	r0, [r11, #-0x8]
   16078: ebfffd58     	bl	0x155e0 <fail>          @ imm = #-0xaa0
   1607c: e51b0010     	ldr	r0, [r11, #-0x10]
   16080: ebffff61     	bl	0x15e0c <join>          @ imm = #-0x27c
   16084: e24bd004     	sub	sp, r11, #4
   16088: e8bd8800     	pop	{r11, pc}

