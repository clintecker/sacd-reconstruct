000151dc <log_abort>:
   151dc: e92d4800     	push	{r11, lr}
   151e0: e28db004     	add	r11, sp, #4
   151e4: e59f0004     	ldr	r0, [pc, #0x4]          @ 0x151f0 <log_abort+0x14>
   151e8: ebfffeb1     	bl	0x14cb4 <log_print>     @ imm = #-0x53c
   151ec: ebffdc15     	bl	0xc248 <abort@plt>      @ imm = #-0x8fac
   151f0: 08 2a 03 00  	.word	0x00032a08

