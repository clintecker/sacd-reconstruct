00022080 <sacd_dev_input_close>:
   22080: e92d4800     	push	{r11, lr}
   22084: e28db004     	add	r11, sp, #4
   22088: e24dd010     	sub	sp, sp, #16
   2208c: e50b0010     	str	r0, [r11, #-0x10]
   22090: e51b3010     	ldr	r3, [r11, #-0x10]
   22094: e5933000     	ldr	r3, [r3]
   22098: e1a00003     	mov	r0, r3
   2209c: ebffa950     	bl	0xc5e4 <close@plt>      @ imm = #-0x15ac0
   220a0: e1a03000     	mov	r3, r0
   220a4: e50b3008     	str	r3, [r11, #-0x8]
   220a8: e59f3028     	ldr	r3, [pc, #0x28]         @ 0x220d8 <sacd_dev_input_close+0x58>
   220ac: e5932000     	ldr	r2, [r3]
   220b0: e59f3024     	ldr	r3, [pc, #0x24]         @ 0x220dc <sacd_dev_input_close+0x5c>
   220b4: e1520003     	cmp	r2, r3
   220b8: 1a000000     	bne	0x220c0 <sacd_dev_input_close+0x40> @ imm = #0x0
   220bc: ebfffc52     	bl	0x2120c <uninit_sacd>   @ imm = #-0xeb8
   220c0: e51b0010     	ldr	r0, [r11, #-0x10]
   220c4: ebffa8d4     	bl	0xc41c <free@plt>       @ imm = #-0x15cb0
   220c8: e51b3008     	ldr	r3, [r11, #-0x8]
   220cc: e1a00003     	mov	r0, r3
   220d0: e24bd004     	sub	sp, r11, #4
   220d4: e8bd8800     	pop	{r11, pc}
   220d8: 04 9e 05 00  	.word	0x00059e04
   220dc: 28 20 02 00  	.word	0x00022028

