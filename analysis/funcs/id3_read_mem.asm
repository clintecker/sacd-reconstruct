0001e138 <id3_read_mem>:
   1e138: e92d4800     	push	{r11, lr}
   1e13c: e28db004     	add	r11, sp, #4
   1e140: e24dd018     	sub	sp, sp, #24
   1e144: e50b0010     	str	r0, [r11, #-0x10]
   1e148: e50b1014     	str	r1, [r11, #-0x14]
   1e14c: e50b2018     	str	r2, [r11, #-0x18]
   1e150: e51b3010     	ldr	r3, [r11, #-0x10]
   1e154: e5933128     	ldr	r3, [r3, #0x128]
   1e158: e50b3008     	str	r3, [r11, #-0x8]
   1e15c: e51b3010     	ldr	r3, [r11, #-0x10]
   1e160: e5932020     	ldr	r2, [r3, #0x20]
   1e164: e51b3018     	ldr	r3, [r11, #-0x18]
   1e168: e0822003     	add	r2, r2, r3
   1e16c: e51b3010     	ldr	r3, [r11, #-0x10]
   1e170: e593301c     	ldr	r3, [r3, #0x1c]
   1e174: e1520003     	cmp	r2, r3
   1e178: da000001     	ble	0x1e184 <id3_read_mem+0x4c> @ imm = #0x4
   1e17c: e3a03000     	mov	r3, #0
   1e180: ea00001b     	b	0x1e1f4 <id3_read_mem+0xbc> @ imm = #0x6c
   1e184: e51b3014     	ldr	r3, [r11, #-0x14]
   1e188: e3530000     	cmp	r3, #0
   1e18c: 0a00000b     	beq	0x1e1c0 <id3_read_mem+0x88> @ imm = #0x2c
   1e190: e51b3018     	ldr	r3, [r11, #-0x18]
   1e194: e3530a02     	cmp	r3, #8192
   1e198: da000001     	ble	0x1e1a4 <id3_read_mem+0x6c> @ imm = #0x4
   1e19c: e3a03000     	mov	r3, #0
   1e1a0: ea000013     	b	0x1e1f4 <id3_read_mem+0xbc> @ imm = #0x4c
   1e1a4: e51b3010     	ldr	r3, [r11, #-0x10]
   1e1a8: e5932128     	ldr	r2, [r3, #0x128]
   1e1ac: e51b3018     	ldr	r3, [r11, #-0x18]
   1e1b0: e51b0014     	ldr	r0, [r11, #-0x14]
   1e1b4: e1a01002     	mov	r1, r2
   1e1b8: e1a02003     	mov	r2, r3
   1e1bc: ebffb8d2     	bl	0xc50c <memcpy@plt>     @ imm = #-0x11cb8
   1e1c0: e51b3010     	ldr	r3, [r11, #-0x10]
   1e1c4: e5932128     	ldr	r2, [r3, #0x128]
   1e1c8: e51b3018     	ldr	r3, [r11, #-0x18]
   1e1cc: e0822003     	add	r2, r2, r3
   1e1d0: e51b3010     	ldr	r3, [r11, #-0x10]
   1e1d4: e5832128     	str	r2, [r3, #0x128]
   1e1d8: e51b3010     	ldr	r3, [r11, #-0x10]
   1e1dc: e5932020     	ldr	r2, [r3, #0x20]
   1e1e0: e51b3018     	ldr	r3, [r11, #-0x18]
   1e1e4: e0822003     	add	r2, r2, r3
   1e1e8: e51b3010     	ldr	r3, [r11, #-0x10]
   1e1ec: e5832020     	str	r2, [r3, #0x20]
   1e1f0: e51b3008     	ldr	r3, [r11, #-0x8]
   1e1f4: e1a00003     	mov	r0, r3
   1e1f8: e24bd004     	sub	sp, r11, #4
   1e1fc: e8bd8800     	pop	{r11, pc}

