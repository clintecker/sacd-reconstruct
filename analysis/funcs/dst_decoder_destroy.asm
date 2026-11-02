0001b3c8 <dst_decoder_destroy>:
   1b3c8: e92d4800     	push	{r11, lr}
   1b3cc: e28db004     	add	r11, sp, #4
   1b3d0: e24dd008     	sub	sp, sp, #8
   1b3d4: e50b0008     	str	r0, [r11, #-0x8]
   1b3d8: e51b0008     	ldr	r0, [r11, #-0x8]
   1b3dc: ebffff6f     	bl	0x1b1a0 <finish_write_job> @ imm = #-0x244
   1b3e0: e51b0008     	ldr	r0, [r11, #-0x8]
   1b3e4: ebfffd82     	bl	0x1a9f4 <finish_decoding_jobs> @ imm = #-0x9f8
   1b3e8: e51b0008     	ldr	r0, [r11, #-0x8]
   1b3ec: ebffc40a     	bl	0xc41c <free@plt>       @ imm = #-0xefd8
   1b3f0: e24bd004     	sub	sp, r11, #4
   1b3f4: e8bd8800     	pop	{r11, pc}

