00027184 <dsdiff_create_edit_master>:
   27184: e92d4800     	push	{r11, lr}
   27188: e28db004     	add	r11, sp, #4
   2718c: e24dd010     	sub	sp, sp, #16
   27190: e50b0010     	str	r0, [r11, #-0x10]
   27194: e51b3010     	ldr	r3, [r11, #-0x10]
   27198: e593305c     	ldr	r3, [r3, #0x5c]
   2719c: e50b3008     	str	r3, [r11, #-0x8]
   271a0: e51b3008     	ldr	r3, [r11, #-0x8]
   271a4: e3a02001     	mov	r2, #1
   271a8: e5832028     	str	r2, [r3, #0x28]
   271ac: e51b0010     	ldr	r0, [r11, #-0x10]
   271b0: ebffefa1     	bl	0x2303c <calculate_header_and_footer> @ imm = #-0x417c
   271b4: e1a03000     	mov	r3, r0
   271b8: e50b300c     	str	r3, [r11, #-0xc]
   271bc: e51b3008     	ldr	r3, [r11, #-0x8]
   271c0: e5931000     	ldr	r1, [r3]
   271c4: e51b3008     	ldr	r3, [r11, #-0x8]
   271c8: e5932004     	ldr	r2, [r3, #0x4]
   271cc: e51b3010     	ldr	r3, [r11, #-0x10]
   271d0: e593301c     	ldr	r3, [r3, #0x1c]
   271d4: e1a00001     	mov	r0, r1
   271d8: e3a01001     	mov	r1, #1
   271dc: ebff9503     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x1abf4
   271e0: e51b300c     	ldr	r3, [r11, #-0xc]
   271e4: e1a00003     	mov	r0, r3
   271e8: e24bd004     	sub	sp, r11, #4
   271ec: e8bd8800     	pop	{r11, pc}

