00016a6c <LT_InitCoefTablesI>:
   16a6c: e52db004     	str	r11, [sp, #-0x4]!
   16a70: e28db000     	add	r11, sp, #0
   16a74: e24dd02c     	sub	sp, sp, #44
   16a78: e50b0028     	str	r0, [r11, #-0x28]
   16a7c: e50b102c     	str	r1, [r11, #-0x2c]
   16a80: e3a03000     	mov	r3, #0
   16a84: e50b3020     	str	r3, [r11, #-0x20]
   16a88: ea00005f     	b	0x16c0c <LT_InitCoefTablesI+0x1a0> @ imm = #0x17c
   16a8c: e51b3020     	ldr	r3, [r11, #-0x20]
   16a90: e51b1028     	ldr	r1, [r11, #-0x28]
   16a94: e2832004     	add	r2, r3, #4
   16a98: e3a03004     	mov	r3, #4
   16a9c: e1a02102     	lsl	r2, r2, #2
   16aa0: e0812002     	add	r2, r1, r2
   16aa4: e0823003     	add	r3, r2, r3
   16aa8: e5933000     	ldr	r3, [r3]
   16aac: e50b301c     	str	r3, [r11, #-0x1c]
   16ab0: e3a03000     	mov	r3, #0
   16ab4: e50b3018     	str	r3, [r11, #-0x18]
   16ab8: ea00004d     	b	0x16bf4 <LT_InitCoefTablesI+0x188> @ imm = #0x134
   16abc: e51b3018     	ldr	r3, [r11, #-0x18]
   16ac0: e1a03183     	lsl	r3, r3, #3
   16ac4: e2632000     	rsb	r2, r3, #0
   16ac8: e51b301c     	ldr	r3, [r11, #-0x1c]
   16acc: e0823003     	add	r3, r2, r3
   16ad0: e50b3014     	str	r3, [r11, #-0x14]
   16ad4: e51b3014     	ldr	r3, [r11, #-0x14]
   16ad8: e3530008     	cmp	r3, #8
   16adc: da000002     	ble	0x16aec <LT_InitCoefTablesI+0x80> @ imm = #0x8
   16ae0: e3a03008     	mov	r3, #8
   16ae4: e50b3014     	str	r3, [r11, #-0x14]
   16ae8: ea000004     	b	0x16b00 <LT_InitCoefTablesI+0x94> @ imm = #0x10
   16aec: e51b3014     	ldr	r3, [r11, #-0x14]
   16af0: e3530000     	cmp	r3, #0
   16af4: aa000001     	bge	0x16b00 <LT_InitCoefTablesI+0x94> @ imm = #0x4
   16af8: e3a03000     	mov	r3, #0
   16afc: e50b3014     	str	r3, [r11, #-0x14]
   16b00: e3a03000     	mov	r3, #0
   16b04: e50b3010     	str	r3, [r11, #-0x10]
   16b08: ea000033     	b	0x16bdc <LT_InitCoefTablesI+0x170> @ imm = #0xcc
   16b0c: e3a03000     	mov	r3, #0
   16b10: e50b3008     	str	r3, [r11, #-0x8]
   16b14: e3a03000     	mov	r3, #0
   16b18: e50b300c     	str	r3, [r11, #-0xc]
   16b1c: ea00001a     	b	0x16b8c <LT_InitCoefTablesI+0x120> @ imm = #0x68
   16b20: e51b2010     	ldr	r2, [r11, #-0x10]
   16b24: e51b300c     	ldr	r3, [r11, #-0xc]
   16b28: e1a03352     	asr	r3, r2, r3
   16b2c: e2033001     	and	r3, r3, #1
   16b30: e1a03083     	lsl	r3, r3, #1
   16b34: e2433001     	sub	r3, r3, #1
   16b38: e51b2028     	ldr	r2, [r11, #-0x28]
   16b3c: e5921074     	ldr	r1, [r2, #0x74]
   16b40: e51b2020     	ldr	r2, [r11, #-0x20]
   16b44: e1a02102     	lsl	r2, r2, #2
   16b48: e0812002     	add	r2, r1, r2
   16b4c: e5921000     	ldr	r1, [r2]
   16b50: e51b2018     	ldr	r2, [r11, #-0x18]
   16b54: e1a00182     	lsl	r0, r2, #3
   16b58: e51b200c     	ldr	r2, [r11, #-0xc]
   16b5c: e0802002     	add	r2, r0, r2
   16b60: e1a02082     	lsl	r2, r2, #1
   16b64: e0812002     	add	r2, r1, r2
   16b68: e1d220b0     	ldrh	r2, [r2]
   16b6c: e6bf2072     	sxth	r2, r2
   16b70: e0030392     	mul	r3, r2, r3
   16b74: e51b2008     	ldr	r2, [r11, #-0x8]
   16b78: e0823003     	add	r3, r2, r3
   16b7c: e50b3008     	str	r3, [r11, #-0x8]
   16b80: e51b300c     	ldr	r3, [r11, #-0xc]
   16b84: e2833001     	add	r3, r3, #1
   16b88: e50b300c     	str	r3, [r11, #-0xc]
   16b8c: e51b200c     	ldr	r2, [r11, #-0xc]
   16b90: e51b3014     	ldr	r3, [r11, #-0x14]
   16b94: e1520003     	cmp	r2, r3
   16b98: baffffe0     	blt	0x16b20 <LT_InitCoefTablesI+0xb4> @ imm = #-0x80
   16b9c: e51b3020     	ldr	r3, [r11, #-0x20]
   16ba0: e1a03683     	lsl	r3, r3, #13
   16ba4: e51b202c     	ldr	r2, [r11, #-0x2c]
   16ba8: e0821003     	add	r1, r2, r3
   16bac: e51b0018     	ldr	r0, [r11, #-0x18]
   16bb0: e51b3010     	ldr	r3, [r11, #-0x10]
   16bb4: e51b2008     	ldr	r2, [r11, #-0x8]
   16bb8: e6ff2072     	uxth	r2, r2
   16bbc: e1a00400     	lsl	r0, r0, #8
   16bc0: e0803003     	add	r3, r0, r3
   16bc4: e1a03083     	lsl	r3, r3, #1
   16bc8: e0813003     	add	r3, r1, r3
   16bcc: e1c320b0     	strh	r2, [r3]
   16bd0: e51b3010     	ldr	r3, [r11, #-0x10]
   16bd4: e2833001     	add	r3, r3, #1
   16bd8: e50b3010     	str	r3, [r11, #-0x10]
   16bdc: e51b3010     	ldr	r3, [r11, #-0x10]
   16be0: e35300ff     	cmp	r3, #255
   16be4: daffffc8     	ble	0x16b0c <LT_InitCoefTablesI+0xa0> @ imm = #-0xe0
   16be8: e51b3018     	ldr	r3, [r11, #-0x18]
   16bec: e2833001     	add	r3, r3, #1
   16bf0: e50b3018     	str	r3, [r11, #-0x18]
   16bf4: e51b3018     	ldr	r3, [r11, #-0x18]
   16bf8: e353000f     	cmp	r3, #15
   16bfc: daffffae     	ble	0x16abc <LT_InitCoefTablesI+0x50> @ imm = #-0x148
   16c00: e51b3020     	ldr	r3, [r11, #-0x20]
   16c04: e2833001     	add	r3, r3, #1
   16c08: e50b3020     	str	r3, [r11, #-0x20]
   16c0c: e51b3028     	ldr	r3, [r11, #-0x28]
   16c10: e5932008     	ldr	r2, [r3, #0x8]
   16c14: e51b3020     	ldr	r3, [r11, #-0x20]
   16c18: e1520003     	cmp	r2, r3
   16c1c: caffff9a     	bgt	0x16a8c <LT_InitCoefTablesI+0x20> @ imm = #-0x198
   16c20: e28bd000     	add	sp, r11, #0
   16c24: e8bd0800     	ldm	sp!, {r11}
   16c28: e12fff1e     	bx	lr

