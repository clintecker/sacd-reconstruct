0002f970 <install_modules>:
   2f970: e92d4800     	push	{r11, lr}
   2f974: e28db004     	add	r11, sp, #4
   2f978: e24dde21     	sub	sp, sp, #528
   2f97c: e3a03000     	mov	r3, #0
   2f980: e50b300c     	str	r3, [r11, #-0xc]
   2f984: e59f2180     	ldr	r2, [pc, #0x180]        @ 0x2fb0c <install_modules+0x19c>
   2f988: e59f3180     	ldr	r3, [pc, #0x180]        @ 0x2fb10 <install_modules+0x1a0>
   2f98c: e0633002     	rsb	r3, r3, r2
   2f990: e50b3008     	str	r3, [r11, #-0x8]
   2f994: e59f3178     	ldr	r3, [pc, #0x178]        @ 0x2fb14 <install_modules+0x1a4>
   2f998: e59f0178     	ldr	r0, [pc, #0x178]        @ 0x2fb18 <install_modules+0x1a8>
   2f99c: e1a01003     	mov	r1, r3
   2f9a0: e3a02006     	mov	r2, #6
   2f9a4: ebff72d8     	bl	0xc50c <memcpy@plt>     @ imm = #-0x234a0
   2f9a8: e59f0168     	ldr	r0, [pc, #0x168]        @ 0x2fb18 <install_modules+0x1a8>
   2f9ac: ebff728e     	bl	0xc3ec <tmpnam@plt>     @ imm = #-0x235c8
   2f9b0: e59f0160     	ldr	r0, [pc, #0x160]        @ 0x2fb18 <install_modules+0x1a8>
   2f9b4: e59f1160     	ldr	r1, [pc, #0x160]        @ 0x2fb1c <install_modules+0x1ac>
   2f9b8: ebff72ee     	bl	0xc578 <open64@plt>     @ imm = #-0x23448
   2f9bc: e1a03000     	mov	r3, r0
   2f9c0: e50b3010     	str	r3, [r11, #-0x10]
   2f9c4: e51b3010     	ldr	r3, [r11, #-0x10]
   2f9c8: e3530000     	cmp	r3, #0
   2f9cc: ba00003c     	blt	0x2fac4 <install_modules+0x154> @ imm = #0xf0
   2f9d0: e51b0010     	ldr	r0, [r11, #-0x10]
   2f9d4: e59f1134     	ldr	r1, [pc, #0x134]        @ 0x2fb10 <install_modules+0x1a0>
   2f9d8: e51b2008     	ldr	r2, [r11, #-0x8]
   2f9dc: ebff7294     	bl	0xc434 <write@plt>      @ imm = #-0x235b0
   2f9e0: e1a02000     	mov	r2, r0
   2f9e4: e51b3008     	ldr	r3, [r11, #-0x8]
   2f9e8: e1520003     	cmp	r2, r3
   2f9ec: 1a000025     	bne	0x2fa88 <install_modules+0x118> @ imm = #0x94
   2f9f0: e51b0010     	ldr	r0, [r11, #-0x10]
   2f9f4: ebff72fa     	bl	0xc5e4 <close@plt>      @ imm = #-0x23418
   2f9f8: e59f0120     	ldr	r0, [pc, #0x120]        @ 0x2fb20 <install_modules+0x1b0>
   2f9fc: ebff7247     	bl	0xc320 <system@plt>     @ imm = #-0x236e4
   2fa00: e59f311c     	ldr	r3, [pc, #0x11c]        @ 0x2fb24 <install_modules+0x1b4>
   2fa04: e24b2e21     	sub	r2, r11, #528
   2fa08: e1a00002     	mov	r0, r2
   2fa0c: e1a01003     	mov	r1, r3
   2fa10: e59f2100     	ldr	r2, [pc, #0x100]        @ 0x2fb18 <install_modules+0x1a8>
   2fa14: ebff7379     	bl	0xc800 <sprintf@plt>    @ imm = #-0x2321c
   2fa18: e24b3e21     	sub	r3, r11, #528
   2fa1c: e1a00003     	mov	r0, r3
   2fa20: ebff723e     	bl	0xc320 <system@plt>     @ imm = #-0x23708
   2fa24: e59f00ec     	ldr	r0, [pc, #0xec]         @ 0x2fb18 <install_modules+0x1a8>
   2fa28: ebff72b1     	bl	0xc4f4 <unlink@plt>     @ imm = #-0x2353c
   2fa2c: e59f00f4     	ldr	r0, [pc, #0xf4]         @ 0x2fb28 <install_modules+0x1b8>
   2fa30: e3a01000     	mov	r1, #0
   2fa34: ebff72cf     	bl	0xc578 <open64@plt>     @ imm = #-0x234c4
   2fa38: e1a03000     	mov	r3, r0
   2fa3c: e50b3010     	str	r3, [r11, #-0x10]
   2fa40: e51b3010     	ldr	r3, [r11, #-0x10]
   2fa44: e3530000     	cmp	r3, #0
   2fa48: ba000002     	blt	0x2fa58 <install_modules+0xe8> @ imm = #0x8
   2fa4c: e51b0010     	ldr	r0, [r11, #-0x10]
   2fa50: ebff72e3     	bl	0xc5e4 <close@plt>      @ imm = #-0x23474
   2fa54: ea000028     	b	0x2fafc <install_modules+0x18c> @ imm = #0xa0
   2fa58: e59f30cc     	ldr	r3, [pc, #0xcc]         @ 0x2fb2c <install_modules+0x1bc>
   2fa5c: e5933000     	ldr	r3, [r3]
   2fa60: e5933004     	ldr	r3, [r3, #0x4]
   2fa64: e3530001     	cmp	r3, #1
   2fa68: 9a000002     	bls	0x2fa78 <install_modules+0x108> @ imm = #0x8
   2fa6c: e59f00bc     	ldr	r0, [pc, #0xbc]         @ 0x2fb30 <install_modules+0x1c0>
   2fa70: e59f10bc     	ldr	r1, [pc, #0xbc]         @ 0x2fb34 <install_modules+0x1c4>
   2fa74: ebff948e     	bl	0x14cb4 <log_print>     @ imm = #-0x1adc8
   2fa78: eb000030     	bl	0x2fb40 <remove_modules> @ imm = #0xc0
   2fa7c: e3e03000     	mvn	r3, #0
   2fa80: e50b300c     	str	r3, [r11, #-0xc]
   2fa84: ea00001c     	b	0x2fafc <install_modules+0x18c> @ imm = #0x70
   2fa88: ebff7353     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x232b4
   2fa8c: e1a03000     	mov	r3, r0
   2fa90: e5933000     	ldr	r3, [r3]
   2fa94: e2633000     	rsb	r3, r3, #0
   2fa98: e50b300c     	str	r3, [r11, #-0xc]
   2fa9c: e59f3088     	ldr	r3, [pc, #0x88]         @ 0x2fb2c <install_modules+0x1bc>
   2faa0: e5933000     	ldr	r3, [r3]
   2faa4: e5933004     	ldr	r3, [r3, #0x4]
   2faa8: e3530001     	cmp	r3, #1
   2faac: 9a000012     	bls	0x2fafc <install_modules+0x18c> @ imm = #0x48
   2fab0: e59f0080     	ldr	r0, [pc, #0x80]         @ 0x2fb38 <install_modules+0x1c8>
   2fab4: e59f1078     	ldr	r1, [pc, #0x78]         @ 0x2fb34 <install_modules+0x1c4>
   2fab8: e51b200c     	ldr	r2, [r11, #-0xc]
   2fabc: ebff947c     	bl	0x14cb4 <log_print>     @ imm = #-0x1ae10
   2fac0: ea00000d     	b	0x2fafc <install_modules+0x18c> @ imm = #0x34
   2fac4: ebff7344     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x232f0
   2fac8: e1a03000     	mov	r3, r0
   2facc: e5933000     	ldr	r3, [r3]
   2fad0: e2633000     	rsb	r3, r3, #0
   2fad4: e50b300c     	str	r3, [r11, #-0xc]
   2fad8: e59f304c     	ldr	r3, [pc, #0x4c]         @ 0x2fb2c <install_modules+0x1bc>
   2fadc: e5933000     	ldr	r3, [r3]
   2fae0: e5933004     	ldr	r3, [r3, #0x4]
   2fae4: e3530001     	cmp	r3, #1
   2fae8: 9a000003     	bls	0x2fafc <install_modules+0x18c> @ imm = #0xc
   2faec: e59f0048     	ldr	r0, [pc, #0x48]         @ 0x2fb3c <install_modules+0x1cc>
   2faf0: e59f103c     	ldr	r1, [pc, #0x3c]         @ 0x2fb34 <install_modules+0x1c4>
   2faf4: e51b200c     	ldr	r2, [r11, #-0xc]
   2faf8: ebff946d     	bl	0x14cb4 <log_print>     @ imm = #-0x1ae4c
   2fafc: e51b300c     	ldr	r3, [r11, #-0xc]
   2fb00: e1a00003     	mov	r0, r3
   2fb04: e24bd004     	sub	sp, r11, #4
   2fb08: e8bd8800     	pop	{r11, pc}
   2fb0c: e9 6d 05 00  	.word	0x00056de9
   2fb10: dc ef 03 00  	.word	0x0003efdc
   2fb14: 34 62 03 00  	.word	0x00036234
   2fb18: c0 9d 05 00  	.word	0x00059dc0
   2fb1c: 41 02 00 00  	.word	0x00000241
   2fb20: 3c 62 03 00  	.word	0x0003623c
   2fb24: 64 62 03 00  	.word	0x00036264
   2fb28: 78 62 03 00  	.word	0x00036278
   2fb2c: 5c 73 05 00  	.word	0x0005735c
   2fb30: 88 62 03 00  	.word	0x00036288
   2fb34: 10 63 03 00  	.word	0x00036310
   2fb38: a0 62 03 00  	.word	0x000362a0
   2fb3c: b4 62 03 00  	.word	0x000362b4

