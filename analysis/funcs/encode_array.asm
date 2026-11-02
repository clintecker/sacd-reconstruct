00011744 <encode_array>:
   11744: e92d4800     	push	{r11, lr}
   11748: e28db004     	add	r11, sp, #4
   1174c: e24dd030     	sub	sp, sp, #48
   11750: e50b0028     	str	r0, [r11, #-0x28]
   11754: e50b102c     	str	r1, [r11, #-0x2c]
   11758: e50b2030     	str	r2, [r11, #-0x30]
   1175c: e50b3034     	str	r3, [r11, #-0x34]
   11760: e51b3034     	ldr	r3, [r11, #-0x34]
   11764: e3530000     	cmp	r3, #0
   11768: 1a000001     	bne	0x11774 <encode_array+0x30> @ imm = #0x4
   1176c: e3a03001     	mov	r3, #1
   11770: ea0000c2     	b	0x11a80 <encode_array+0x33c> @ imm = #0x308
   11774: e51b302c     	ldr	r3, [r11, #-0x2c]
   11778: e5d33001     	ldrb	r3, [r3, #0x1]
   1177c: e203300f     	and	r3, r3, #15
   11780: e3530003     	cmp	r3, #3
   11784: ca00008c     	bgt	0x119bc <encode_array+0x278> @ imm = #0x230
   11788: e51b302c     	ldr	r3, [r11, #-0x2c]
   1178c: e5d33000     	ldrb	r3, [r3]
   11790: e51b0028     	ldr	r0, [r11, #-0x28]
   11794: e3a01002     	mov	r1, #2
   11798: e1a02003     	mov	r2, r3
   1179c: eb0001ae     	bl	0x11e5c <pb_encode_tag> @ imm = #0x6b8
   117a0: e1a03000     	mov	r3, r0
   117a4: e2233001     	eor	r3, r3, #1
   117a8: e6ef3073     	uxtb	r3, r3
   117ac: e3530000     	cmp	r3, #0
   117b0: 0a000001     	beq	0x117bc <encode_array+0x78> @ imm = #0x4
   117b4: e3a03000     	mov	r3, #0
   117b8: ea0000b0     	b	0x11a80 <encode_array+0x33c> @ imm = #0x2c0
   117bc: e51b302c     	ldr	r3, [r11, #-0x2c]
   117c0: e5d33001     	ldrb	r3, [r3, #0x1]
   117c4: e203300f     	and	r3, r3, #15
   117c8: e3530002     	cmp	r3, #2
   117cc: 1a000003     	bne	0x117e0 <encode_array+0x9c> @ imm = #0xc
   117d0: e51b3034     	ldr	r3, [r11, #-0x34]
   117d4: e1a03103     	lsl	r3, r3, #2
   117d8: e50b3008     	str	r3, [r11, #-0x8]
   117dc: ea000039     	b	0x118c8 <encode_array+0x184> @ imm = #0xe4
   117e0: e51b302c     	ldr	r3, [r11, #-0x2c]
   117e4: e5d33001     	ldrb	r3, [r3, #0x1]
   117e8: e203300f     	and	r3, r3, #15
   117ec: e3530003     	cmp	r3, #3
   117f0: 1a000003     	bne	0x11804 <encode_array+0xc0> @ imm = #0xc
   117f4: e51b3034     	ldr	r3, [r11, #-0x34]
   117f8: e1a03183     	lsl	r3, r3, #3
   117fc: e50b3008     	str	r3, [r11, #-0x8]
   11800: ea000030     	b	0x118c8 <encode_array+0x184> @ imm = #0xc0
   11804: e3a03000     	mov	r3, #0
   11808: e50b3020     	str	r3, [r11, #-0x20]
   1180c: e3a03000     	mov	r3, #0
   11810: e50b301c     	str	r3, [r11, #-0x1c]
   11814: e3a03000     	mov	r3, #0
   11818: e50b3018     	str	r3, [r11, #-0x18]
   1181c: e3a03000     	mov	r3, #0
   11820: e50b3014     	str	r3, [r11, #-0x14]
   11824: e51b3030     	ldr	r3, [r11, #-0x30]
   11828: e50b300c     	str	r3, [r11, #-0xc]
   1182c: e3a03000     	mov	r3, #0
   11830: e50b3010     	str	r3, [r11, #-0x10]
   11834: ea00001d     	b	0x118b0 <encode_array+0x16c> @ imm = #0x74
   11838: e24b2020     	sub	r2, r11, #32
   1183c: e59b3004     	ldr	r3, [r11, #0x4]
   11840: e1a00002     	mov	r0, r2
   11844: e51b102c     	ldr	r1, [r11, #-0x2c]
   11848: e51b200c     	ldr	r2, [r11, #-0xc]
   1184c: e12fff33     	blx	r3
   11850: e1a03000     	mov	r3, r0
   11854: e2233001     	eor	r3, r3, #1
   11858: e6ef3073     	uxtb	r3, r3
   1185c: e3530000     	cmp	r3, #0
   11860: 0a000001     	beq	0x1186c <encode_array+0x128> @ imm = #0x4
   11864: e3a03000     	mov	r3, #0
   11868: ea000084     	b	0x11a80 <encode_array+0x33c> @ imm = #0x210
   1186c: e51b302c     	ldr	r3, [r11, #-0x2c]
   11870: e5d32004     	ldrb	r2, [r3, #0x4]
   11874: e5d31005     	ldrb	r1, [r3, #0x5]
   11878: e1a01401     	lsl	r1, r1, #8
   1187c: e1812002     	orr	r2, r1, r2
   11880: e5d31006     	ldrb	r1, [r3, #0x6]
   11884: e1a01801     	lsl	r1, r1, #16
   11888: e1812002     	orr	r2, r1, r2
   1188c: e5d33007     	ldrb	r3, [r3, #0x7]
   11890: e1a03c03     	lsl	r3, r3, #24
   11894: e1833002     	orr	r3, r3, r2
   11898: e51b200c     	ldr	r2, [r11, #-0xc]
   1189c: e0823003     	add	r3, r2, r3
   118a0: e50b300c     	str	r3, [r11, #-0xc]
   118a4: e51b3010     	ldr	r3, [r11, #-0x10]
   118a8: e2833001     	add	r3, r3, #1
   118ac: e50b3010     	str	r3, [r11, #-0x10]
   118b0: e51b2010     	ldr	r2, [r11, #-0x10]
   118b4: e51b3034     	ldr	r3, [r11, #-0x34]
   118b8: e1520003     	cmp	r2, r3
   118bc: 3affffdd     	blo	0x11838 <encode_array+0xf4> @ imm = #-0x8c
   118c0: e51b3014     	ldr	r3, [r11, #-0x14]
   118c4: e50b3008     	str	r3, [r11, #-0x8]
   118c8: e51b3008     	ldr	r3, [r11, #-0x8]
   118cc: e1a02003     	mov	r2, r3
   118d0: e3a03000     	mov	r3, #0
   118d4: e51b0028     	ldr	r0, [r11, #-0x28]
   118d8: eb000118     	bl	0x11d40 <pb_encode_varint> @ imm = #0x460
   118dc: e1a03000     	mov	r3, r0
   118e0: e2233001     	eor	r3, r3, #1
   118e4: e6ef3073     	uxtb	r3, r3
   118e8: e3530000     	cmp	r3, #0
   118ec: 0a000001     	beq	0x118f8 <encode_array+0x1b4> @ imm = #0x4
   118f0: e3a03000     	mov	r3, #0
   118f4: ea000061     	b	0x11a80 <encode_array+0x33c> @ imm = #0x184
   118f8: e51b3028     	ldr	r3, [r11, #-0x28]
   118fc: e5933000     	ldr	r3, [r3]
   11900: e3530000     	cmp	r3, #0
   11904: 1a000005     	bne	0x11920 <encode_array+0x1dc> @ imm = #0x14
   11908: e51b0028     	ldr	r0, [r11, #-0x28]
   1190c: e3a01000     	mov	r1, #0
   11910: e51b2008     	ldr	r2, [r11, #-0x8]
   11914: ebffff5f     	bl	0x11698 <pb_write>      @ imm = #-0x284
   11918: e1a03000     	mov	r3, r0
   1191c: ea000057     	b	0x11a80 <encode_array+0x33c> @ imm = #0x15c
   11920: e51b3030     	ldr	r3, [r11, #-0x30]
   11924: e50b300c     	str	r3, [r11, #-0xc]
   11928: e3a03000     	mov	r3, #0
   1192c: e50b3010     	str	r3, [r11, #-0x10]
   11930: ea00001c     	b	0x119a8 <encode_array+0x264> @ imm = #0x70
   11934: e59b3004     	ldr	r3, [r11, #0x4]
   11938: e51b0028     	ldr	r0, [r11, #-0x28]
   1193c: e51b102c     	ldr	r1, [r11, #-0x2c]
   11940: e51b200c     	ldr	r2, [r11, #-0xc]
   11944: e12fff33     	blx	r3
   11948: e1a03000     	mov	r3, r0
   1194c: e2233001     	eor	r3, r3, #1
   11950: e6ef3073     	uxtb	r3, r3
   11954: e3530000     	cmp	r3, #0
   11958: 0a000001     	beq	0x11964 <encode_array+0x220> @ imm = #0x4
   1195c: e3a03000     	mov	r3, #0
   11960: ea000046     	b	0x11a80 <encode_array+0x33c> @ imm = #0x118
   11964: e51b302c     	ldr	r3, [r11, #-0x2c]
   11968: e5d32004     	ldrb	r2, [r3, #0x4]
   1196c: e5d31005     	ldrb	r1, [r3, #0x5]
   11970: e1a01401     	lsl	r1, r1, #8
   11974: e1812002     	orr	r2, r1, r2
   11978: e5d31006     	ldrb	r1, [r3, #0x6]
   1197c: e1a01801     	lsl	r1, r1, #16
   11980: e1812002     	orr	r2, r1, r2
   11984: e5d33007     	ldrb	r3, [r3, #0x7]
   11988: e1a03c03     	lsl	r3, r3, #24
   1198c: e1833002     	orr	r3, r3, r2
   11990: e51b200c     	ldr	r2, [r11, #-0xc]
   11994: e0823003     	add	r3, r2, r3
   11998: e50b300c     	str	r3, [r11, #-0xc]
   1199c: e51b3010     	ldr	r3, [r11, #-0x10]
   119a0: e2833001     	add	r3, r3, #1
   119a4: e50b3010     	str	r3, [r11, #-0x10]
   119a8: e51b2010     	ldr	r2, [r11, #-0x10]
   119ac: e51b3034     	ldr	r3, [r11, #-0x34]
   119b0: e1520003     	cmp	r2, r3
   119b4: 3affffde     	blo	0x11934 <encode_array+0x1f0> @ imm = #-0x88
   119b8: ea00002f     	b	0x11a7c <encode_array+0x338> @ imm = #0xbc
   119bc: e51b3030     	ldr	r3, [r11, #-0x30]
   119c0: e50b300c     	str	r3, [r11, #-0xc]
   119c4: e3a03000     	mov	r3, #0
   119c8: e50b3010     	str	r3, [r11, #-0x10]
   119cc: ea000026     	b	0x11a6c <encode_array+0x328> @ imm = #0x98
   119d0: e51b0028     	ldr	r0, [r11, #-0x28]
   119d4: e51b102c     	ldr	r1, [r11, #-0x2c]
   119d8: eb000134     	bl	0x11eb0 <pb_encode_tag_for_field> @ imm = #0x4d0
   119dc: e1a03000     	mov	r3, r0
   119e0: e2233001     	eor	r3, r3, #1
   119e4: e6ef3073     	uxtb	r3, r3
   119e8: e3530000     	cmp	r3, #0
   119ec: 0a000001     	beq	0x119f8 <encode_array+0x2b4> @ imm = #0x4
   119f0: e3a03000     	mov	r3, #0
   119f4: ea000021     	b	0x11a80 <encode_array+0x33c> @ imm = #0x84
   119f8: e59b3004     	ldr	r3, [r11, #0x4]
   119fc: e51b0028     	ldr	r0, [r11, #-0x28]
   11a00: e51b102c     	ldr	r1, [r11, #-0x2c]
   11a04: e51b200c     	ldr	r2, [r11, #-0xc]
   11a08: e12fff33     	blx	r3
   11a0c: e1a03000     	mov	r3, r0
   11a10: e2233001     	eor	r3, r3, #1
   11a14: e6ef3073     	uxtb	r3, r3
   11a18: e3530000     	cmp	r3, #0
   11a1c: 0a000001     	beq	0x11a28 <encode_array+0x2e4> @ imm = #0x4
   11a20: e3a03000     	mov	r3, #0
   11a24: ea000015     	b	0x11a80 <encode_array+0x33c> @ imm = #0x54
   11a28: e51b302c     	ldr	r3, [r11, #-0x2c]
   11a2c: e5d32004     	ldrb	r2, [r3, #0x4]
   11a30: e5d31005     	ldrb	r1, [r3, #0x5]
   11a34: e1a01401     	lsl	r1, r1, #8
   11a38: e1812002     	orr	r2, r1, r2
   11a3c: e5d31006     	ldrb	r1, [r3, #0x6]
   11a40: e1a01801     	lsl	r1, r1, #16
   11a44: e1812002     	orr	r2, r1, r2
   11a48: e5d33007     	ldrb	r3, [r3, #0x7]
   11a4c: e1a03c03     	lsl	r3, r3, #24
   11a50: e1833002     	orr	r3, r3, r2
   11a54: e51b200c     	ldr	r2, [r11, #-0xc]
   11a58: e0823003     	add	r3, r2, r3
   11a5c: e50b300c     	str	r3, [r11, #-0xc]
   11a60: e51b3010     	ldr	r3, [r11, #-0x10]
   11a64: e2833001     	add	r3, r3, #1
   11a68: e50b3010     	str	r3, [r11, #-0x10]
   11a6c: e51b2010     	ldr	r2, [r11, #-0x10]
   11a70: e51b3034     	ldr	r3, [r11, #-0x34]
   11a74: e1520003     	cmp	r2, r3
   11a78: 3affffd4     	blo	0x119d0 <encode_array+0x28c> @ imm = #-0xb0
   11a7c: e3a03001     	mov	r3, #1
   11a80: e1a00003     	mov	r0, r3
   11a84: e24bd004     	sub	sp, r11, #4
   11a88: e8bd8800     	pop	{r11, pc}

