0002e674 <sacd_open>:
   2e674: e92d4800     	push	{r11, lr}
   2e678: e28db004     	add	r11, sp, #4
   2e67c: e24dd098     	sub	sp, sp, #152
   2e680: e50b0098     	str	r0, [r11, #-0x98]
   2e684: e3a03000     	mov	r3, #0
   2e688: e50b3028     	str	r3, [r11, #-0x28]
   2e68c: e3a03000     	mov	r3, #0
   2e690: e50b3024     	str	r3, [r11, #-0x24]
   2e694: e51b3098     	ldr	r3, [r11, #-0x98]
   2e698: e3530000     	cmp	r3, #0
   2e69c: 1a000001     	bne	0x2e6a8 <sacd_open+0x34> @ imm = #0x4
   2e6a0: e3a03000     	mov	r3, #0
   2e6a4: ea0000f2     	b	0x2ea74 <sacd_open+0x400> @ imm = #0x3c8
   2e6a8: e51b0098     	ldr	r0, [r11, #-0x98]
   2e6ac: ebff77e7     	bl	0xc650 <strdup@plt>     @ imm = #-0x22064
   2e6b0: e1a03000     	mov	r3, r0
   2e6b4: e50b3020     	str	r3, [r11, #-0x20]
   2e6b8: e51b3020     	ldr	r3, [r11, #-0x20]
   2e6bc: e3530000     	cmp	r3, #0
   2e6c0: 1a000001     	bne	0x2e6cc <sacd_open+0x58> @ imm = #0x4
   2e6c4: e3a03000     	mov	r3, #0
   2e6c8: ea0000e9     	b	0x2ea74 <sacd_open+0x400> @ imm = #0x3a4
   2e6cc: e51b2020     	ldr	r2, [r11, #-0x20]
   2e6d0: e24b3094     	sub	r3, r11, #148
   2e6d4: e1a00002     	mov	r0, r2
   2e6d8: e1a01003     	mov	r1, r3
   2e6dc: eb000ca4     	bl	0x31974 <stat64>        @ imm = #0x3290
   2e6e0: e1a03000     	mov	r3, r0
   2e6e4: e50b302c     	str	r3, [r11, #-0x2c]
   2e6e8: e51b302c     	ldr	r3, [r11, #-0x2c]
   2e6ec: e3530000     	cmp	r3, #0
   2e6f0: aa00001b     	bge	0x2e764 <sacd_open+0xf0> @ imm = #0x6c
   2e6f4: e51b0020     	ldr	r0, [r11, #-0x20]
   2e6f8: e3a0103a     	mov	r1, #58
   2e6fc: ebff770a     	bl	0xc32c <strchr@plt>     @ imm = #-0x223d8
   2e700: e1a03000     	mov	r3, r0
   2e704: e3530000     	cmp	r3, #0
   2e708: 0a000007     	beq	0x2e72c <sacd_open+0xb8> @ imm = #0x1c
   2e70c: e51b0020     	ldr	r0, [r11, #-0x20]
   2e710: ebffffa3     	bl	0x2e5a4 <sacd_open_image_file> @ imm = #-0x174
   2e714: e1a03000     	mov	r3, r0
   2e718: e50b3028     	str	r3, [r11, #-0x28]
   2e71c: e51b0020     	ldr	r0, [r11, #-0x20]
   2e720: ebff773d     	bl	0xc41c <free@plt>       @ imm = #-0x2230c
   2e724: e51b3028     	ldr	r3, [r11, #-0x28]
   2e728: ea0000d1     	b	0x2ea74 <sacd_open+0x400> @ imm = #0x344
   2e72c: e59f334c     	ldr	r3, [pc, #0x34c]        @ 0x2ea80 <sacd_open+0x40c>
   2e730: e5933000     	ldr	r3, [r3]
   2e734: e1a02003     	mov	r2, r3
   2e738: e59f3344     	ldr	r3, [pc, #0x344]        @ 0x2ea84 <sacd_open+0x410>
   2e73c: e1a00002     	mov	r0, r2
   2e740: e1a01003     	mov	r1, r3
   2e744: e51b2020     	ldr	r2, [r11, #-0x20]
   2e748: ebff77bd     	bl	0xc644 <fprintf@plt>    @ imm = #-0x2210c
   2e74c: e59f0334     	ldr	r0, [pc, #0x334]        @ 0x2ea88 <sacd_open+0x414>
   2e750: ebff7719     	bl	0xc3bc <perror@plt>     @ imm = #-0x2239c
   2e754: e51b0020     	ldr	r0, [r11, #-0x20]
   2e758: ebff772f     	bl	0xc41c <free@plt>       @ imm = #-0x22344
   2e75c: e3a03000     	mov	r3, #0
   2e760: ea0000c3     	b	0x2ea74 <sacd_open+0x400> @ imm = #0x30c
   2e764: e51b3084     	ldr	r3, [r11, #-0x84]
   2e768: e2033a0f     	and	r3, r3, #61440
   2e76c: e3530a06     	cmp	r3, #24576
   2e770: 0a000007     	beq	0x2e794 <sacd_open+0x120> @ imm = #0x1c
   2e774: e51b3084     	ldr	r3, [r11, #-0x84]
   2e778: e2033a0f     	and	r3, r3, #61440
   2e77c: e3530a02     	cmp	r3, #8192
   2e780: 0a000003     	beq	0x2e794 <sacd_open+0x120> @ imm = #0xc
   2e784: e51b3084     	ldr	r3, [r11, #-0x84]
   2e788: e2033a0f     	and	r3, r3, #61440
   2e78c: e3530902     	cmp	r3, #32768
   2e790: 1a000007     	bne	0x2e7b4 <sacd_open+0x140> @ imm = #0x1c
   2e794: e51b0020     	ldr	r0, [r11, #-0x20]
   2e798: ebffff81     	bl	0x2e5a4 <sacd_open_image_file> @ imm = #-0x1fc
   2e79c: e1a03000     	mov	r3, r0
   2e7a0: e50b3028     	str	r3, [r11, #-0x28]
   2e7a4: e51b0020     	ldr	r0, [r11, #-0x20]
   2e7a8: ebff771b     	bl	0xc41c <free@plt>       @ imm = #-0x22394
   2e7ac: e51b3028     	ldr	r3, [r11, #-0x28]
   2e7b0: ea0000af     	b	0x2ea74 <sacd_open+0x400> @ imm = #0x2bc
   2e7b4: e51b3084     	ldr	r3, [r11, #-0x84]
   2e7b8: e2033a0f     	and	r3, r3, #61440
   2e7bc: e3530901     	cmp	r3, #16384
   2e7c0: 1a0000a0     	bne	0x2ea48 <sacd_open+0x3d4> @ imm = #0x280
   2e7c4: e3a03000     	mov	r3, #0
   2e7c8: e50b301c     	str	r3, [r11, #-0x1c]
   2e7cc: e51b0020     	ldr	r0, [r11, #-0x20]
   2e7d0: ebff779e     	bl	0xc650 <strdup@plt>     @ imm = #-0x22188
   2e7d4: e1a03000     	mov	r3, r0
   2e7d8: e50b3018     	str	r3, [r11, #-0x18]
   2e7dc: e51b3018     	ldr	r3, [r11, #-0x18]
   2e7e0: e3530000     	cmp	r3, #0
   2e7e4: 1a000003     	bne	0x2e7f8 <sacd_open+0x184> @ imm = #0xc
   2e7e8: e51b0020     	ldr	r0, [r11, #-0x20]
   2e7ec: ebff770a     	bl	0xc41c <free@plt>       @ imm = #-0x223d8
   2e7f0: e3a03000     	mov	r3, #0
   2e7f4: ea00009e     	b	0x2ea74 <sacd_open+0x400> @ imm = #0x278
   2e7f8: e59f028c     	ldr	r0, [pc, #0x28c]        @ 0x2ea8c <sacd_open+0x418>
   2e7fc: e3a01000     	mov	r1, #0
   2e800: ebff775c     	bl	0xc578 <open64@plt>     @ imm = #-0x22290
   2e804: e1a03000     	mov	r3, r0
   2e808: e50b300c     	str	r3, [r11, #-0xc]
   2e80c: e51b300c     	ldr	r3, [r11, #-0xc]
   2e810: e3530000     	cmp	r3, #0
   2e814: ba000017     	blt	0x2e878 <sacd_open+0x204> @ imm = #0x5c
   2e818: e51b0018     	ldr	r0, [r11, #-0x18]
   2e81c: ebff779a     	bl	0xc68c <chdir@plt>      @ imm = #-0x22198
   2e820: e59f0268     	ldr	r0, [pc, #0x268]        @ 0x2ea90 <sacd_open+0x41c>
   2e824: ebff778f     	bl	0xc668 <malloc@plt>     @ imm = #-0x221c4
   2e828: e1a03000     	mov	r3, r0
   2e82c: e50b3010     	str	r3, [r11, #-0x10]
   2e830: e51b3010     	ldr	r3, [r11, #-0x10]
   2e834: e3530000     	cmp	r3, #0
   2e838: 1a000003     	bne	0x2e84c <sacd_open+0x1d8> @ imm = #0xc
   2e83c: e51b0020     	ldr	r0, [r11, #-0x20]
   2e840: ebff76f5     	bl	0xc41c <free@plt>       @ imm = #-0x2242c
   2e844: e3a03000     	mov	r3, #0
   2e848: ea000089     	b	0x2ea74 <sacd_open+0x400> @ imm = #0x224
   2e84c: e51b0010     	ldr	r0, [r11, #-0x10]
   2e850: e3a01a01     	mov	r1, #4096
   2e854: ebff779b     	bl	0xc6c8 <getcwd@plt>     @ imm = #-0x22194
   2e858: e51b000c     	ldr	r0, [r11, #-0xc]
   2e85c: ebff77bd     	bl	0xc758 <fchdir@plt>     @ imm = #-0x2210c
   2e860: e51b000c     	ldr	r0, [r11, #-0xc]
   2e864: ebff775e     	bl	0xc5e4 <close@plt>      @ imm = #-0x22288
   2e868: e51b0018     	ldr	r0, [r11, #-0x18]
   2e86c: ebff76ea     	bl	0xc41c <free@plt>       @ imm = #-0x22458
   2e870: e51b3010     	ldr	r3, [r11, #-0x10]
   2e874: e50b3018     	str	r3, [r11, #-0x18]
   2e878: e51b0018     	ldr	r0, [r11, #-0x18]
   2e87c: ebff7716     	bl	0xc4dc <strlen@plt>     @ imm = #-0x223a8
   2e880: e1a03000     	mov	r3, r0
   2e884: e3530001     	cmp	r3, #1
   2e888: 9a000010     	bls	0x2e8d0 <sacd_open+0x25c> @ imm = #0x40
   2e88c: e51b0018     	ldr	r0, [r11, #-0x18]
   2e890: ebff7711     	bl	0xc4dc <strlen@plt>     @ imm = #-0x223bc
   2e894: e1a03000     	mov	r3, r0
   2e898: e2433001     	sub	r3, r3, #1
   2e89c: e51b2018     	ldr	r2, [r11, #-0x18]
   2e8a0: e0823003     	add	r3, r2, r3
   2e8a4: e5d33000     	ldrb	r3, [r3]
   2e8a8: e353002f     	cmp	r3, #47
   2e8ac: 1a000007     	bne	0x2e8d0 <sacd_open+0x25c> @ imm = #0x1c
   2e8b0: e51b0018     	ldr	r0, [r11, #-0x18]
   2e8b4: ebff7708     	bl	0xc4dc <strlen@plt>     @ imm = #-0x223e0
   2e8b8: e1a03000     	mov	r3, r0
   2e8bc: e2433001     	sub	r3, r3, #1
   2e8c0: e51b2018     	ldr	r2, [r11, #-0x18]
   2e8c4: e0823003     	add	r3, r2, r3
   2e8c8: e3a02000     	mov	r2, #0
   2e8cc: e5c32000     	strb	r2, [r3]
   2e8d0: e51b3018     	ldr	r3, [r11, #-0x18]
   2e8d4: e5d33000     	ldrb	r3, [r3]
   2e8d8: e3530000     	cmp	r3, #0
   2e8dc: 1a000006     	bne	0x2e8fc <sacd_open+0x288> @ imm = #0x18
   2e8e0: e51b3018     	ldr	r3, [r11, #-0x18]
   2e8e4: e3a0202f     	mov	r2, #47
   2e8e8: e5c32000     	strb	r2, [r3]
   2e8ec: e51b3018     	ldr	r3, [r11, #-0x18]
   2e8f0: e2833001     	add	r3, r3, #1
   2e8f4: e3a02000     	mov	r2, #0
   2e8f8: e5c32000     	strb	r2, [r3]
   2e8fc: e59f2190     	ldr	r2, [pc, #0x190]        @ 0x2ea94 <sacd_open+0x420>
   2e900: e59f3190     	ldr	r3, [pc, #0x190]        @ 0x2ea98 <sacd_open+0x424>
   2e904: e1a00002     	mov	r0, r2
   2e908: e1a01003     	mov	r1, r3
   2e90c: ebff7707     	bl	0xc530 <fopen64@plt>    @ imm = #-0x223e4
   2e910: e1a03000     	mov	r3, r0
   2e914: e50b3014     	str	r3, [r11, #-0x14]
   2e918: e51b3014     	ldr	r3, [r11, #-0x14]
   2e91c: e3530000     	cmp	r3, #0
   2e920: 0a000027     	beq	0x2e9c4 <sacd_open+0x350> @ imm = #0x9c
   2e924: ea00001d     	b	0x2e9a0 <sacd_open+0x32c> @ imm = #0x74
   2e928: e51b3008     	ldr	r3, [r11, #-0x8]
   2e92c: e5933004     	ldr	r3, [r3, #0x4]
   2e930: e1a00003     	mov	r0, r3
   2e934: e51b1018     	ldr	r1, [r11, #-0x18]
   2e938: ebff779e     	bl	0xc7b8 <strcmp@plt>     @ imm = #-0x22188
   2e93c: e1a03000     	mov	r3, r0
   2e940: e3530000     	cmp	r3, #0
   2e944: 1a000015     	bne	0x2e9a0 <sacd_open+0x32c> @ imm = #0x54
   2e948: e59f3130     	ldr	r3, [pc, #0x130]        @ 0x2ea80 <sacd_open+0x40c>
   2e94c: e5933000     	ldr	r3, [r3]
   2e950: e1a00003     	mov	r0, r3
   2e954: e59f1140     	ldr	r1, [pc, #0x140]        @ 0x2ea9c <sacd_open+0x428>
   2e958: e51b3008     	ldr	r3, [r11, #-0x8]
   2e95c: e5932000     	ldr	r2, [r3]
   2e960: e51b3008     	ldr	r3, [r11, #-0x8]
   2e964: e5933004     	ldr	r3, [r3, #0x4]
   2e968: ebff7735     	bl	0xc644 <fprintf@plt>    @ imm = #-0x2232c
   2e96c: e51b3008     	ldr	r3, [r11, #-0x8]
   2e970: e5933000     	ldr	r3, [r3]
   2e974: e1a00003     	mov	r0, r3
   2e978: ebffff09     	bl	0x2e5a4 <sacd_open_image_file> @ imm = #-0x3dc
   2e97c: e1a03000     	mov	r3, r0
   2e980: e50b301c     	str	r3, [r11, #-0x1c]
   2e984: e51b3008     	ldr	r3, [r11, #-0x8]
   2e988: e5933000     	ldr	r3, [r3]
   2e98c: e1a00003     	mov	r0, r3
   2e990: ebff772e     	bl	0xc650 <strdup@plt>     @ imm = #-0x22348
   2e994: e1a03000     	mov	r3, r0
   2e998: e50b3024     	str	r3, [r11, #-0x24]
   2e99c: ea000006     	b	0x2e9bc <sacd_open+0x348> @ imm = #0x18
   2e9a0: e51b0014     	ldr	r0, [r11, #-0x14]
   2e9a4: ebff773e     	bl	0xc6a4 <getmntent@plt>  @ imm = #-0x22308
   2e9a8: e1a03000     	mov	r3, r0
   2e9ac: e50b3008     	str	r3, [r11, #-0x8]
   2e9b0: e51b3008     	ldr	r3, [r11, #-0x8]
   2e9b4: e3530000     	cmp	r3, #0
   2e9b8: 1affffda     	bne	0x2e928 <sacd_open+0x2b4> @ imm = #-0x98
   2e9bc: e51b0014     	ldr	r0, [r11, #-0x14]
   2e9c0: ebff7647     	bl	0xc2e4 <fclose@plt>     @ imm = #-0x226e4
   2e9c4: e51b3024     	ldr	r3, [r11, #-0x24]
   2e9c8: e3530000     	cmp	r3, #0
   2e9cc: 1a000007     	bne	0x2e9f0 <sacd_open+0x37c> @ imm = #0x1c
   2e9d0: e59f20c8     	ldr	r2, [pc, #0xc8]         @ 0x2eaa0 <sacd_open+0x42c>
   2e9d4: e59f30a4     	ldr	r3, [pc, #0xa4]         @ 0x2ea80 <sacd_open+0x40c>
   2e9d8: e5933000     	ldr	r3, [r3]
   2e9dc: e1a00002     	mov	r0, r2
   2e9e0: e3a01001     	mov	r1, #1
   2e9e4: e3a02026     	mov	r2, #38
   2e9e8: ebff7700     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x22400
   2e9ec: ea00000a     	b	0x2ea1c <sacd_open+0x3a8> @ imm = #0x28
   2e9f0: e51b301c     	ldr	r3, [r11, #-0x1c]
   2e9f4: e3530000     	cmp	r3, #0
   2e9f8: 1a000007     	bne	0x2ea1c <sacd_open+0x3a8> @ imm = #0x1c
   2e9fc: e59f307c     	ldr	r3, [pc, #0x7c]         @ 0x2ea80 <sacd_open+0x40c>
   2ea00: e5933000     	ldr	r3, [r3]
   2ea04: e1a02003     	mov	r2, r3
   2ea08: e59f3094     	ldr	r3, [pc, #0x94]         @ 0x2eaa4 <sacd_open+0x430>
   2ea0c: e1a00002     	mov	r0, r2
   2ea10: e1a01003     	mov	r1, r3
   2ea14: e51b2024     	ldr	r2, [r11, #-0x24]
   2ea18: ebff7709     	bl	0xc644 <fprintf@plt>    @ imm = #-0x223dc
   2ea1c: e51b0024     	ldr	r0, [r11, #-0x24]
   2ea20: ebff767d     	bl	0xc41c <free@plt>       @ imm = #-0x2260c
   2ea24: e51b0018     	ldr	r0, [r11, #-0x18]
   2ea28: ebff767b     	bl	0xc41c <free@plt>       @ imm = #-0x22614
   2ea2c: e51b301c     	ldr	r3, [r11, #-0x1c]
   2ea30: e3530000     	cmp	r3, #0
   2ea34: 0a000003     	beq	0x2ea48 <sacd_open+0x3d4> @ imm = #0xc
   2ea38: e51b0020     	ldr	r0, [r11, #-0x20]
   2ea3c: ebff7676     	bl	0xc41c <free@plt>       @ imm = #-0x22628
   2ea40: e51b301c     	ldr	r3, [r11, #-0x1c]
   2ea44: ea00000a     	b	0x2ea74 <sacd_open+0x400> @ imm = #0x28
   2ea48: e59f3030     	ldr	r3, [pc, #0x30]         @ 0x2ea80 <sacd_open+0x40c>
   2ea4c: e5933000     	ldr	r3, [r3]
   2ea50: e1a02003     	mov	r2, r3
   2ea54: e59f304c     	ldr	r3, [pc, #0x4c]         @ 0x2eaa8 <sacd_open+0x434>
   2ea58: e1a00002     	mov	r0, r2
   2ea5c: e1a01003     	mov	r1, r3
   2ea60: e51b2020     	ldr	r2, [r11, #-0x20]
   2ea64: ebff76f6     	bl	0xc644 <fprintf@plt>    @ imm = #-0x22428
   2ea68: e51b0020     	ldr	r0, [r11, #-0x20]
   2ea6c: ebff766a     	bl	0xc41c <free@plt>       @ imm = #-0x22658
   2ea70: e3a03000     	mov	r3, #0
   2ea74: e1a00003     	mov	r0, r3
   2ea78: e24bd004     	sub	sp, r11, #4
   2ea7c: e8bd8800     	pop	{r11, pc}
   2ea80: f8 6d 05 00  	.word	0x00056df8
   2ea84: 40 5e 03 00  	.word	0x00035e40
   2ea88: 5c 5e 03 00  	.word	0x00035e5c
   2ea8c: 60 5e 03 00  	.word	0x00035e60
   2ea90: 01 10 00 00  	.word	0x00001001
   2ea94: 64 5e 03 00  	.word	0x00035e64
   2ea98: 70 5e 03 00  	.word	0x00035e70
   2ea9c: 74 5e 03 00  	.word	0x00035e74
   2eaa0: ac 5e 03 00  	.word	0x00035eac
   2eaa4: d4 5e 03 00  	.word	0x00035ed4
   2eaa8: fc 5e 03 00  	.word	0x00035efc

