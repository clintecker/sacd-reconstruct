000271f0 <dsdiff_create>:
   271f0: e92d4800     	push	{r11, lr}
   271f4: e28db004     	add	r11, sp, #4
   271f8: e24dd010     	sub	sp, sp, #16
   271fc: e50b0010     	str	r0, [r11, #-0x10]
   27200: e51b0010     	ldr	r0, [r11, #-0x10]
   27204: ebffef8c     	bl	0x2303c <calculate_header_and_footer> @ imm = #-0x41d0
   27208: e1a03000     	mov	r3, r0
   2720c: e50b300c     	str	r3, [r11, #-0xc]
   27210: e51b3010     	ldr	r3, [r11, #-0x10]
   27214: e593305c     	ldr	r3, [r3, #0x5c]
   27218: e50b3008     	str	r3, [r11, #-0x8]
   2721c: e51b3008     	ldr	r3, [r11, #-0x8]
   27220: e5931000     	ldr	r1, [r3]
   27224: e51b3008     	ldr	r3, [r11, #-0x8]
   27228: e5932004     	ldr	r2, [r3, #0x4]
   2722c: e51b3010     	ldr	r3, [r11, #-0x10]
   27230: e593301c     	ldr	r3, [r3, #0x1c]
   27234: e1a00001     	mov	r0, r1
   27238: e3a01001     	mov	r1, #1
   2723c: ebff94eb     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x1ac54
   27240: e51b300c     	ldr	r3, [r11, #-0xc]
   27244: e1a00003     	mov	r0, r3
   27248: e24bd004     	sub	sp, r11, #4
   2724c: e8bd8800     	pop	{r11, pc}

