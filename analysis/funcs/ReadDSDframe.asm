000178b0 <ReadDSDframe>:
   178b0: e92d4800     	push	{r11, lr}
   178b4: e28db004     	add	r11, sp, #4
   178b8: e24dd018     	sub	sp, sp, #24
   178bc: e50b0010     	str	r0, [r11, #-0x10]
   178c0: e50b1014     	str	r1, [r11, #-0x14]
   178c4: e50b2018     	str	r2, [r11, #-0x18]
   178c8: e50b301c     	str	r3, [r11, #-0x1c]
   178cc: e51b3014     	ldr	r3, [r11, #-0x14]
   178d0: e51b2018     	ldr	r2, [r11, #-0x18]
   178d4: e0030392     	mul	r3, r2, r3
   178d8: e50b3008     	str	r3, [r11, #-0x8]
   178dc: e3a03000     	mov	r3, #0
   178e0: e50b300c     	str	r3, [r11, #-0xc]
   178e4: ea000009     	b	0x17910 <ReadDSDframe+0x60> @ imm = #0x24
   178e8: e51b300c     	ldr	r3, [r11, #-0xc]
   178ec: e51b201c     	ldr	r2, [r11, #-0x1c]
   178f0: e0823003     	add	r3, r2, r3
   178f4: e51b0010     	ldr	r0, [r11, #-0x10]
   178f8: e3a01008     	mov	r1, #8
   178fc: e1a02003     	mov	r2, r3
   17900: eb000f9d     	bl	0x1b77c <FIO_BitGetChrUnsigned> @ imm = #0x3e74
   17904: e51b300c     	ldr	r3, [r11, #-0xc]
   17908: e2833001     	add	r3, r3, #1
   1790c: e50b300c     	str	r3, [r11, #-0xc]
   17910: e51b200c     	ldr	r2, [r11, #-0xc]
   17914: e51b3008     	ldr	r3, [r11, #-0x8]
   17918: e1520003     	cmp	r2, r3
   1791c: bafffff1     	blt	0x178e8 <ReadDSDframe+0x38> @ imm = #-0x3c
   17920: e24bd004     	sub	sp, r11, #4
   17924: e8bd8800     	pop	{r11, pc}

