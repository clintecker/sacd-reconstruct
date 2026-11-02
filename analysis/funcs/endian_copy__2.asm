00011fc0 <endian_copy>:
   11fc0: e92d4800     	push	{r11, lr}
   11fc4: e28db004     	add	r11, sp, #4
   11fc8: e24dd010     	sub	sp, sp, #16
   11fcc: e50b0008     	str	r0, [r11, #-0x8]
   11fd0: e50b100c     	str	r1, [r11, #-0xc]
   11fd4: e50b2010     	str	r2, [r11, #-0x10]
   11fd8: e50b3014     	str	r3, [r11, #-0x14]
   11fdc: e51b0008     	ldr	r0, [r11, #-0x8]
   11fe0: e51b100c     	ldr	r1, [r11, #-0xc]
   11fe4: e51b2014     	ldr	r2, [r11, #-0x14]
   11fe8: ebffe947     	bl	0xc50c <memcpy@plt>     @ imm = #-0x5ae4
   11fec: e24bd004     	sub	sp, r11, #4
   11ff0: e8bd8800     	pop	{r11, pc}

