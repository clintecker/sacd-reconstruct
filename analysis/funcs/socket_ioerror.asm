00013654 <socket_ioerror>:
   13654: e92d4800     	push	{r11, lr}
   13658: e28db004     	add	r11, sp, #4
   1365c: e24dd008     	sub	sp, sp, #8
   13660: e50b0008     	str	r0, [r11, #-0x8]
   13664: e50b100c     	str	r1, [r11, #-0xc]
   13668: e51b000c     	ldr	r0, [r11, #-0xc]
   1366c: ebffffbd     	bl	0x13568 <socket_strerror> @ imm = #-0x10c
   13670: e1a03000     	mov	r3, r0
   13674: e1a00003     	mov	r0, r3
   13678: e24bd004     	sub	sp, r11, #4
   1367c: e8bd8800     	pop	{r11, pc}

