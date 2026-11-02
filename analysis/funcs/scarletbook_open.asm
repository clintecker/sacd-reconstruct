000297bc <scarletbook_open>:
   297bc: e92d4810     	push	{r4, r11, lr}
   297c0: e28db008     	add	r11, sp, #8
   297c4: e24dd014     	sub	sp, sp, #20
   297c8: e50b0018     	str	r0, [r11, #-0x18]
   297cc: e50b101c     	str	r1, [r11, #-0x1c]
   297d0: e59f0478     	ldr	r0, [pc, #0x478]        @ 0x29c50 <scarletbook_open+0x494>
   297d4: e3a01001     	mov	r1, #1
   297d8: ebff8adf     	bl	0xc35c <calloc@plt>     @ imm = #-0x1d484
   297dc: e1a03000     	mov	r3, r0
   297e0: e50b3010     	str	r3, [r11, #-0x10]
   297e4: e51b3010     	ldr	r3, [r11, #-0x10]
   297e8: e3530000     	cmp	r3, #0
   297ec: 1a000001     	bne	0x297f8 <scarletbook_open+0x3c> @ imm = #0x4
   297f0: e3a03000     	mov	r3, #0
   297f4: ea000112     	b	0x29c44 <scarletbook_open+0x488> @ imm = #0x448
   297f8: e3a00801     	mov	r0, #65536
   297fc: ebff8b99     	bl	0xc668 <malloc@plt>     @ imm = #-0x1d19c
   29800: e1a03000     	mov	r3, r0
   29804: e1a01003     	mov	r1, r3
   29808: e51b2010     	ldr	r2, [r11, #-0x10]
   2980c: e59f3440     	ldr	r3, [pc, #0x440]        @ 0x29c54 <scarletbook_open+0x498>
   29810: e7821003     	str	r1, [r2, r3]
   29814: e51b2010     	ldr	r2, [r11, #-0x10]
   29818: e59f3434     	ldr	r3, [pc, #0x434]        @ 0x29c54 <scarletbook_open+0x498>
   2981c: e7923003     	ldr	r3, [r2, r3]
   29820: e3530000     	cmp	r3, #0
   29824: 1a000001     	bne	0x29830 <scarletbook_open+0x74> @ imm = #0x4
   29828: e3a03000     	mov	r3, #0
   2982c: ea000104     	b	0x29c44 <scarletbook_open+0x488> @ imm = #0x410
   29830: e51b3010     	ldr	r3, [r11, #-0x10]
   29834: e51b2018     	ldr	r2, [r11, #-0x18]
   29838: e5832000     	str	r2, [r3]
   2983c: e51b3010     	ldr	r3, [r11, #-0x10]
   29840: e3e02000     	mvn	r2, #0
   29844: e5832050     	str	r2, [r3, #0x50]
   29848: e51b3010     	ldr	r3, [r11, #-0x10]
   2984c: e3e02000     	mvn	r2, #0
   29850: e5832054     	str	r2, [r3, #0x54]
   29854: e51b0010     	ldr	r0, [r11, #-0x10]
   29858: eb000267     	bl	0x2a1fc <scarletbook_read_master_toc> @ imm = #0x99c
   2985c: e1a03000     	mov	r3, r0
   29860: e3530000     	cmp	r3, #0
   29864: 1a00000a     	bne	0x29894 <scarletbook_open+0xd8> @ imm = #0x28
   29868: e59f23e8     	ldr	r2, [pc, #0x3e8]        @ 0x29c58 <scarletbook_open+0x49c>
   2986c: e59f33e8     	ldr	r3, [pc, #0x3e8]        @ 0x29c5c <scarletbook_open+0x4a0>
   29870: e5933000     	ldr	r3, [r3]
   29874: e1a00002     	mov	r0, r2
   29878: e3a01001     	mov	r1, #1
   2987c: e3a02024     	mov	r2, #36
   29880: ebff8b5a     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x1d298
   29884: e51b0010     	ldr	r0, [r11, #-0x10]
   29888: eb0001be     	bl	0x29f88 <scarletbook_close> @ imm = #0x6f8
   2988c: e3a03000     	mov	r3, #0
   29890: ea0000eb     	b	0x29c44 <scarletbook_open+0x488> @ imm = #0x3ac
   29894: e51b3010     	ldr	r3, [r11, #-0x10]
   29898: e5933008     	ldr	r3, [r3, #0x8]
   2989c: e5d32040     	ldrb	r2, [r3, #0x40]
   298a0: e5d31041     	ldrb	r1, [r3, #0x41]
   298a4: e1a01401     	lsl	r1, r1, #8
   298a8: e1812002     	orr	r2, r1, r2
   298ac: e5d31042     	ldrb	r1, [r3, #0x42]
   298b0: e1a01801     	lsl	r1, r1, #16
   298b4: e1812002     	orr	r2, r1, r2
   298b8: e5d33043     	ldrb	r3, [r3, #0x43]
   298bc: e1a03c03     	lsl	r3, r3, #24
   298c0: e1833002     	orr	r3, r3, r2
   298c4: e3530000     	cmp	r3, #0
   298c8: 0a000066     	beq	0x29a68 <scarletbook_open+0x2ac> @ imm = #0x198
   298cc: e51b3010     	ldr	r3, [r11, #-0x10]
   298d0: e5934058     	ldr	r4, [r3, #0x58]
   298d4: e51b3010     	ldr	r3, [r11, #-0x10]
   298d8: e5933008     	ldr	r3, [r3, #0x8]
   298dc: e5d32054     	ldrb	r2, [r3, #0x54]
   298e0: e5d33055     	ldrb	r3, [r3, #0x55]
   298e4: e1a03403     	lsl	r3, r3, #8
   298e8: e1833002     	orr	r3, r3, r2
   298ec: e6ff3073     	uxth	r3, r3
   298f0: e1a03583     	lsl	r3, r3, #11
   298f4: e1a00003     	mov	r0, r3
   298f8: ebff8b5a     	bl	0xc668 <malloc@plt>     @ imm = #-0x1d298
   298fc: e1a03000     	mov	r3, r0
   29900: e1a02003     	mov	r2, r3
   29904: e51b0010     	ldr	r0, [r11, #-0x10]
   29908: e3a0305c     	mov	r3, #92
   2990c: e59f134c     	ldr	r1, [pc, #0x34c]        @ 0x29c60 <scarletbook_open+0x4a4>
   29910: e0010491     	mul	r1, r1, r4
   29914: e0801001     	add	r1, r0, r1
   29918: e0813003     	add	r3, r1, r3
   2991c: e5832000     	str	r2, [r3]
   29920: e51b3010     	ldr	r3, [r11, #-0x10]
   29924: e5932058     	ldr	r2, [r3, #0x58]
   29928: e51b1010     	ldr	r1, [r11, #-0x10]
   2992c: e3a0305c     	mov	r3, #92
   29930: e59f0328     	ldr	r0, [pc, #0x328]        @ 0x29c60 <scarletbook_open+0x4a4>
   29934: e0020290     	mul	r2, r0, r2
   29938: e0812002     	add	r2, r1, r2
   2993c: e0823003     	add	r3, r2, r3
   29940: e5933000     	ldr	r3, [r3]
   29944: e3530000     	cmp	r3, #0
   29948: 1a000003     	bne	0x2995c <scarletbook_open+0x1a0> @ imm = #0xc
   2994c: e51b0010     	ldr	r0, [r11, #-0x10]
   29950: eb00018c     	bl	0x29f88 <scarletbook_close> @ imm = #0x630
   29954: e3a03000     	mov	r3, #0
   29958: ea0000b9     	b	0x29c44 <scarletbook_open+0x488> @ imm = #0x2e4
   2995c: e51b3010     	ldr	r3, [r11, #-0x10]
   29960: e5933008     	ldr	r3, [r3, #0x8]
   29964: e5d32040     	ldrb	r2, [r3, #0x40]
   29968: e5d31041     	ldrb	r1, [r3, #0x41]
   2996c: e1a01401     	lsl	r1, r1, #8
   29970: e1812002     	orr	r2, r1, r2
   29974: e5d31042     	ldrb	r1, [r3, #0x42]
   29978: e1a01801     	lsl	r1, r1, #16
   2997c: e1812002     	orr	r2, r1, r2
   29980: e5d33043     	ldrb	r3, [r3, #0x43]
   29984: e1a03c03     	lsl	r3, r3, #24
   29988: e1833002     	orr	r3, r3, r2
   2998c: e1a01003     	mov	r1, r3
   29990: e51b3010     	ldr	r3, [r11, #-0x10]
   29994: e5933008     	ldr	r3, [r3, #0x8]
   29998: e5d32054     	ldrb	r2, [r3, #0x54]
   2999c: e5d33055     	ldrb	r3, [r3, #0x55]
   299a0: e1a03403     	lsl	r3, r3, #8
   299a4: e1833002     	orr	r3, r3, r2
   299a8: e6ff3073     	uxth	r3, r3
   299ac: e1a02003     	mov	r2, r3
   299b0: e51b3010     	ldr	r3, [r11, #-0x10]
   299b4: e5930058     	ldr	r0, [r3, #0x58]
   299b8: e51bc010     	ldr	r12, [r11, #-0x10]
   299bc: e3a0305c     	mov	r3, #92
   299c0: e59fe298     	ldr	lr, [pc, #0x298]        @ 0x29c60 <scarletbook_open+0x4a4>
   299c4: e000009e     	mul	r0, lr, r0
   299c8: e08c0000     	add	r0, r12, r0
   299cc: e0803003     	add	r3, r0, r3
   299d0: e5933000     	ldr	r3, [r3]
   299d4: e51b0018     	ldr	r0, [r11, #-0x18]
   299d8: eb001449     	bl	0x2eb04 <sacd_read_block_raw> @ imm = #0x5124
   299dc: e1a03000     	mov	r3, r0
   299e0: e3530000     	cmp	r3, #0
   299e4: 1a00000a     	bne	0x29a14 <scarletbook_open+0x258> @ imm = #0x28
   299e8: e51b3010     	ldr	r3, [r11, #-0x10]
   299ec: e5933008     	ldr	r3, [r3, #0x8]
   299f0: e3a02000     	mov	r2, #0
   299f4: e5c32040     	strb	r2, [r3, #0x40]
   299f8: e3a02000     	mov	r2, #0
   299fc: e5c32041     	strb	r2, [r3, #0x41]
   29a00: e3a02000     	mov	r2, #0
   29a04: e5c32042     	strb	r2, [r3, #0x42]
   29a08: e3a02000     	mov	r2, #0
   29a0c: e5c32043     	strb	r2, [r3, #0x43]
   29a10: ea000014     	b	0x29a68 <scarletbook_open+0x2ac> @ imm = #0x50
   29a14: e51b3010     	ldr	r3, [r11, #-0x10]
   29a18: e5933058     	ldr	r3, [r3, #0x58]
   29a1c: e51b0010     	ldr	r0, [r11, #-0x10]
   29a20: e1a01003     	mov	r1, r3
   29a24: eb0009b2     	bl	0x2c0f4 <scarletbook_read_area_toc> @ imm = #0x26c8
   29a28: e1a03000     	mov	r3, r0
   29a2c: e3530000     	cmp	r3, #0
   29a30: 1a000007     	bne	0x29a54 <scarletbook_open+0x298> @ imm = #0x1c
   29a34: e59f2228     	ldr	r2, [pc, #0x228]        @ 0x29c64 <scarletbook_open+0x4a8>
   29a38: e59f321c     	ldr	r3, [pc, #0x21c]        @ 0x29c5c <scarletbook_open+0x4a0>
   29a3c: e5933000     	ldr	r3, [r3]
   29a40: e1a00002     	mov	r0, r2
   29a44: e3a01001     	mov	r1, #1
   29a48: e3a02024     	mov	r2, #36
   29a4c: ebff8ae7     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x1d464
   29a50: ea000004     	b	0x29a68 <scarletbook_open+0x2ac> @ imm = #0x10
   29a54: e51b3010     	ldr	r3, [r11, #-0x10]
   29a58: e5933058     	ldr	r3, [r3, #0x58]
   29a5c: e2832001     	add	r2, r3, #1
   29a60: e51b3010     	ldr	r3, [r11, #-0x10]
   29a64: e5832058     	str	r2, [r3, #0x58]
   29a68: e51b3010     	ldr	r3, [r11, #-0x10]
   29a6c: e5933008     	ldr	r3, [r3, #0x8]
   29a70: e5d32048     	ldrb	r2, [r3, #0x48]
   29a74: e5d31049     	ldrb	r1, [r3, #0x49]
   29a78: e1a01401     	lsl	r1, r1, #8
   29a7c: e1812002     	orr	r2, r1, r2
   29a80: e5d3104a     	ldrb	r1, [r3, #0x4a]
   29a84: e1a01801     	lsl	r1, r1, #16
   29a88: e1812002     	orr	r2, r1, r2
   29a8c: e5d3304b     	ldrb	r3, [r3, #0x4b]
   29a90: e1a03c03     	lsl	r3, r3, #24
   29a94: e1833002     	orr	r3, r3, r2
   29a98: e3530000     	cmp	r3, #0
   29a9c: 0a000067     	beq	0x29c40 <scarletbook_open+0x484> @ imm = #0x19c
   29aa0: e51b3010     	ldr	r3, [r11, #-0x10]
   29aa4: e5934058     	ldr	r4, [r3, #0x58]
   29aa8: e51b3010     	ldr	r3, [r11, #-0x10]
   29aac: e5933008     	ldr	r3, [r3, #0x8]
   29ab0: e5d32056     	ldrb	r2, [r3, #0x56]
   29ab4: e5d33057     	ldrb	r3, [r3, #0x57]
   29ab8: e1a03403     	lsl	r3, r3, #8
   29abc: e1833002     	orr	r3, r3, r2
   29ac0: e6ff3073     	uxth	r3, r3
   29ac4: e1a03583     	lsl	r3, r3, #11
   29ac8: e1a00003     	mov	r0, r3
   29acc: ebff8ae5     	bl	0xc668 <malloc@plt>     @ imm = #-0x1d46c
   29ad0: e1a03000     	mov	r3, r0
   29ad4: e1a02003     	mov	r2, r3
   29ad8: e51b0010     	ldr	r0, [r11, #-0x10]
   29adc: e3a0305c     	mov	r3, #92
   29ae0: e59f1178     	ldr	r1, [pc, #0x178]        @ 0x29c60 <scarletbook_open+0x4a4>
   29ae4: e0010491     	mul	r1, r1, r4
   29ae8: e0801001     	add	r1, r0, r1
   29aec: e0813003     	add	r3, r1, r3
   29af0: e5832000     	str	r2, [r3]
   29af4: e51b3010     	ldr	r3, [r11, #-0x10]
   29af8: e5932058     	ldr	r2, [r3, #0x58]
   29afc: e51b1010     	ldr	r1, [r11, #-0x10]
   29b00: e3a0305c     	mov	r3, #92
   29b04: e59f0154     	ldr	r0, [pc, #0x154]        @ 0x29c60 <scarletbook_open+0x4a4>
   29b08: e0020290     	mul	r2, r0, r2
   29b0c: e0812002     	add	r2, r1, r2
   29b10: e0823003     	add	r3, r2, r3
   29b14: e5933000     	ldr	r3, [r3]
   29b18: e3530000     	cmp	r3, #0
   29b1c: 1a000003     	bne	0x29b30 <scarletbook_open+0x374> @ imm = #0xc
   29b20: e51b0010     	ldr	r0, [r11, #-0x10]
   29b24: eb000117     	bl	0x29f88 <scarletbook_close> @ imm = #0x45c
   29b28: e3a03000     	mov	r3, #0
   29b2c: ea000044     	b	0x29c44 <scarletbook_open+0x488> @ imm = #0x110
   29b30: e51b3010     	ldr	r3, [r11, #-0x10]
   29b34: e5933008     	ldr	r3, [r3, #0x8]
   29b38: e5d32048     	ldrb	r2, [r3, #0x48]
   29b3c: e5d31049     	ldrb	r1, [r3, #0x49]
   29b40: e1a01401     	lsl	r1, r1, #8
   29b44: e1812002     	orr	r2, r1, r2
   29b48: e5d3104a     	ldrb	r1, [r3, #0x4a]
   29b4c: e1a01801     	lsl	r1, r1, #16
   29b50: e1812002     	orr	r2, r1, r2
   29b54: e5d3304b     	ldrb	r3, [r3, #0x4b]
   29b58: e1a03c03     	lsl	r3, r3, #24
   29b5c: e1833002     	orr	r3, r3, r2
   29b60: e1a01003     	mov	r1, r3
   29b64: e51b3010     	ldr	r3, [r11, #-0x10]
   29b68: e5933008     	ldr	r3, [r3, #0x8]
   29b6c: e5d32056     	ldrb	r2, [r3, #0x56]
   29b70: e5d33057     	ldrb	r3, [r3, #0x57]
   29b74: e1a03403     	lsl	r3, r3, #8
   29b78: e1833002     	orr	r3, r3, r2
   29b7c: e6ff3073     	uxth	r3, r3
   29b80: e1a02003     	mov	r2, r3
   29b84: e51b3010     	ldr	r3, [r11, #-0x10]
   29b88: e5930058     	ldr	r0, [r3, #0x58]
   29b8c: e51bc010     	ldr	r12, [r11, #-0x10]
   29b90: e3a0305c     	mov	r3, #92
   29b94: e59fe0c4     	ldr	lr, [pc, #0xc4]         @ 0x29c60 <scarletbook_open+0x4a4>
   29b98: e000009e     	mul	r0, lr, r0
   29b9c: e08c0000     	add	r0, r12, r0
   29ba0: e0803003     	add	r3, r0, r3
   29ba4: e5933000     	ldr	r3, [r3]
   29ba8: e51b0018     	ldr	r0, [r11, #-0x18]
   29bac: eb0013d4     	bl	0x2eb04 <sacd_read_block_raw> @ imm = #0x4f50
   29bb0: e1a03000     	mov	r3, r0
   29bb4: e3530000     	cmp	r3, #0
   29bb8: 1a00000b     	bne	0x29bec <scarletbook_open+0x430> @ imm = #0x2c
   29bbc: e51b3010     	ldr	r3, [r11, #-0x10]
   29bc0: e5933008     	ldr	r3, [r3, #0x8]
   29bc4: e3a02000     	mov	r2, #0
   29bc8: e5c32048     	strb	r2, [r3, #0x48]
   29bcc: e3a02000     	mov	r2, #0
   29bd0: e5c32049     	strb	r2, [r3, #0x49]
   29bd4: e3a02000     	mov	r2, #0
   29bd8: e5c3204a     	strb	r2, [r3, #0x4a]
   29bdc: e3a02000     	mov	r2, #0
   29be0: e5c3204b     	strb	r2, [r3, #0x4b]
   29be4: e51b3010     	ldr	r3, [r11, #-0x10]
   29be8: ea000015     	b	0x29c44 <scarletbook_open+0x488> @ imm = #0x54
   29bec: e51b3010     	ldr	r3, [r11, #-0x10]
   29bf0: e5933058     	ldr	r3, [r3, #0x58]
   29bf4: e51b0010     	ldr	r0, [r11, #-0x10]
   29bf8: e1a01003     	mov	r1, r3
   29bfc: eb00093c     	bl	0x2c0f4 <scarletbook_read_area_toc> @ imm = #0x24f0
   29c00: e1a03000     	mov	r3, r0
   29c04: e3530000     	cmp	r3, #0
   29c08: 1a000007     	bne	0x29c2c <scarletbook_open+0x470> @ imm = #0x1c
   29c0c: e59f2054     	ldr	r2, [pc, #0x54]         @ 0x29c68 <scarletbook_open+0x4ac>
   29c10: e59f3044     	ldr	r3, [pc, #0x44]         @ 0x29c5c <scarletbook_open+0x4a0>
   29c14: e5933000     	ldr	r3, [r3]
   29c18: e1a00002     	mov	r0, r2
   29c1c: e3a01001     	mov	r1, #1
   29c20: e3a02024     	mov	r2, #36
   29c24: ebff8a71     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x1d63c
   29c28: ea000004     	b	0x29c40 <scarletbook_open+0x484> @ imm = #0x10
   29c2c: e51b3010     	ldr	r3, [r11, #-0x10]
   29c30: e5933058     	ldr	r3, [r3, #0x58]
   29c34: e2832001     	add	r2, r3, #1
   29c38: e51b3010     	ldr	r3, [r11, #-0x10]
   29c3c: e5832058     	str	r2, [r3, #0x58]
   29c40: e51b3010     	ldr	r3, [r11, #-0x10]
   29c44: e1a00003     	mov	r0, r3
   29c48: e24bd008     	sub	sp, r11, #8
   29c4c: e8bd8810     	pop	{r4, r11, pc}
   29c50: 84 70 00 00  	.word	0x00007084
   29c54: 3c 70 00 00  	.word	0x0000703c
   29c58: f8 58 03 00  	.word	0x000358f8
   29c5c: f8 6d 05 00  	.word	0x00056df8
   29c60: f0 37 00 00  	.word	0x000037f0
   29c64: 20 59 03 00  	.word	0x00035920
   29c68: 48 59 03 00  	.word	0x00035948

