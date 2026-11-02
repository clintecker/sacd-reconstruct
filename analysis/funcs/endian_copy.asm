0000f7e4 <endian_copy>:
    f7e4: e92d4800     	push	{r11, lr}
    f7e8: e28db004     	add	r11, sp, #4
    f7ec: e24dd010     	sub	sp, sp, #16
    f7f0: e50b0008     	str	r0, [r11, #-0x8]
    f7f4: e50b100c     	str	r1, [r11, #-0xc]
    f7f8: e50b2010     	str	r2, [r11, #-0x10]
    f7fc: e50b3014     	str	r3, [r11, #-0x14]
    f800: e51b0008     	ldr	r0, [r11, #-0x8]
    f804: e51b100c     	ldr	r1, [r11, #-0xc]
    f808: e51b2010     	ldr	r2, [r11, #-0x10]
    f80c: ebfff33e     	bl	0xc50c <memcpy@plt>     @ imm = #-0x3308
    f810: e24bd004     	sub	sp, r11, #4
    f814: e8bd8800     	pop	{r11, pc}

