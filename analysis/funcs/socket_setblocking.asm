00013318 <socket_setblocking>:
   13318: e92d4800     	push	{r11, lr}
   1331c: e28db004     	add	r11, sp, #4
   13320: e24dd010     	sub	sp, sp, #16
   13324: e50b0010     	str	r0, [r11, #-0x10]
   13328: e51b3010     	ldr	r3, [r11, #-0x10]
   1332c: e5933000     	ldr	r3, [r3]
   13330: e1a00003     	mov	r0, r3
   13334: e3a01003     	mov	r1, #3
   13338: e3a02000     	mov	r2, #0
   1333c: ebffe4ed     	bl	0xc6f8 <fcntl@plt>      @ imm = #-0x6c4c
   13340: e1a03000     	mov	r3, r0
   13344: e50b3008     	str	r3, [r11, #-0x8]
   13348: e51b3008     	ldr	r3, [r11, #-0x8]
   1334c: e3c33b02     	bic	r3, r3, #2048
   13350: e50b3008     	str	r3, [r11, #-0x8]
   13354: e51b3010     	ldr	r3, [r11, #-0x10]
   13358: e5933000     	ldr	r3, [r3]
   1335c: e1a00003     	mov	r0, r3
   13360: e3a01004     	mov	r1, #4
   13364: e51b2008     	ldr	r2, [r11, #-0x8]
   13368: ebffe4e2     	bl	0xc6f8 <fcntl@plt>      @ imm = #-0x6c78
   1336c: e24bd004     	sub	sp, r11, #4
   13370: e8bd8800     	pop	{r11, pc}

