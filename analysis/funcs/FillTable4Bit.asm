00016814 <FillTable4Bit>:
   16814: e92d4800     	push	{r11, lr}
   16818: e28db004     	add	r11, sp, #4
   1681c: e24dd030     	sub	sp, sp, #48
   16820: e50b0028     	str	r0, [r11, #-0x28]
   16824: e50b102c     	str	r1, [r11, #-0x2c]
   16828: e50b2030     	str	r2, [r11, #-0x30]
   1682c: e50b3034     	str	r3, [r11, #-0x34]
   16830: e3a03000     	mov	r3, #0
   16834: e50b301c     	str	r3, [r11, #-0x1c]
   16838: ea000073     	b	0x16a0c <FillTable4Bit+0x1f8> @ imm = #0x1cc
   1683c: e51b2034     	ldr	r2, [r11, #-0x34]
   16840: e51b301c     	ldr	r3, [r11, #-0x1c]
   16844: e3a01c93     	mov	r1, #37632
   16848: e0030391     	mul	r3, r1, r3
   1684c: e0823003     	add	r3, r2, r3
   16850: e50b3008     	str	r3, [r11, #-0x8]
   16854: e3a03000     	mov	r3, #0
   16858: e50b3018     	str	r3, [r11, #-0x18]
   1685c: e3a03000     	mov	r3, #0
   16860: e50b3014     	str	r3, [r11, #-0x14]
   16864: ea000042     	b	0x16974 <FillTable4Bit+0x160> @ imm = #0x108
   16868: e51b201c     	ldr	r2, [r11, #-0x1c]
   1686c: e51b3018     	ldr	r3, [r11, #-0x18]
   16870: e51b1030     	ldr	r1, [r11, #-0x30]
   16874: e1a02182     	lsl	r2, r2, #3
   16878: e0823003     	add	r3, r2, r3
   1687c: e2832036     	add	r2, r3, #54
   16880: e3a03004     	mov	r3, #4
   16884: e1a02102     	lsl	r2, r2, #2
   16888: e0812002     	add	r2, r1, r2
   1688c: e0823003     	add	r3, r2, r3
   16890: e5933000     	ldr	r3, [r3]
   16894: e54b3009     	strb	r3, [r11, #-0x9]
   16898: e51b3030     	ldr	r3, [r11, #-0x30]
   1689c: e5933000     	ldr	r3, [r3]
   168a0: e1a03183     	lsl	r3, r3, #3
   168a4: e51b101c     	ldr	r1, [r11, #-0x1c]
   168a8: e51b2018     	ldr	r2, [r11, #-0x18]
   168ac: e51b0030     	ldr	r0, [r11, #-0x30]
   168b0: e1a01181     	lsl	r1, r1, #3
   168b4: e0811002     	add	r1, r1, r2
   168b8: e3a02004     	mov	r2, #4
   168bc: e1a01101     	lsl	r1, r1, #2
   168c0: e0801001     	add	r1, r0, r1
   168c4: e0812002     	add	r2, r1, r2
   168c8: e5922000     	ldr	r2, [r2]
   168cc: e0020392     	mul	r2, r2, r3
   168d0: e51b3014     	ldr	r3, [r11, #-0x14]
   168d4: e0823003     	add	r3, r2, r3
   168d8: e50b3010     	str	r3, [r11, #-0x10]
   168dc: e51b3014     	ldr	r3, [r11, #-0x14]
   168e0: e50b3020     	str	r3, [r11, #-0x20]
   168e4: ea00000a     	b	0x16914 <FillTable4Bit+0x100> @ imm = #0x28
   168e8: e51b301c     	ldr	r3, [r11, #-0x1c]
   168ec: e3a02c93     	mov	r2, #37632
   168f0: e0030392     	mul	r3, r2, r3
   168f4: e51b2034     	ldr	r2, [r11, #-0x34]
   168f8: e0822003     	add	r2, r2, r3
   168fc: e51b3020     	ldr	r3, [r11, #-0x20]
   16900: e55b1009     	ldrb	r1, [r11, #-0x9]
   16904: e7c21003     	strb	r1, [r2, r3]
   16908: e51b3020     	ldr	r3, [r11, #-0x20]
   1690c: e2833001     	add	r3, r3, #1
   16910: e50b3020     	str	r3, [r11, #-0x20]
   16914: e51b2020     	ldr	r2, [r11, #-0x20]
   16918: e51b3010     	ldr	r3, [r11, #-0x10]
   1691c: e1520003     	cmp	r2, r3
   16920: bafffff0     	blt	0x168e8 <FillTable4Bit+0xd4> @ imm = #-0x40
   16924: e51b3030     	ldr	r3, [r11, #-0x30]
   16928: e5933000     	ldr	r3, [r3]
   1692c: e1a03183     	lsl	r3, r3, #3
   16930: e51b101c     	ldr	r1, [r11, #-0x1c]
   16934: e51b2018     	ldr	r2, [r11, #-0x18]
   16938: e51b0030     	ldr	r0, [r11, #-0x30]
   1693c: e1a01181     	lsl	r1, r1, #3
   16940: e0811002     	add	r1, r1, r2
   16944: e3a02004     	mov	r2, #4
   16948: e1a01101     	lsl	r1, r1, #2
   1694c: e0801001     	add	r1, r0, r1
   16950: e0812002     	add	r2, r1, r2
   16954: e5922000     	ldr	r2, [r2]
   16958: e0030392     	mul	r3, r2, r3
   1695c: e51b2014     	ldr	r2, [r11, #-0x14]
   16960: e0823003     	add	r3, r2, r3
   16964: e50b3014     	str	r3, [r11, #-0x14]
   16968: e51b3018     	ldr	r3, [r11, #-0x18]
   1696c: e2833001     	add	r3, r3, #1
   16970: e50b3018     	str	r3, [r11, #-0x18]
   16974: e51b301c     	ldr	r3, [r11, #-0x1c]
   16978: e51b1030     	ldr	r1, [r11, #-0x30]
   1697c: e2832030     	add	r2, r3, #48
   16980: e3a03004     	mov	r3, #4
   16984: e1a02102     	lsl	r2, r2, #2
   16988: e0812002     	add	r2, r1, r2
   1698c: e0823003     	add	r3, r2, r3
   16990: e5933000     	ldr	r3, [r3]
   16994: e2432001     	sub	r2, r3, #1
   16998: e51b3018     	ldr	r3, [r11, #-0x18]
   1699c: e1520003     	cmp	r2, r3
   169a0: caffffb0     	bgt	0x16868 <FillTable4Bit+0x54> @ imm = #-0x140
   169a4: e51b201c     	ldr	r2, [r11, #-0x1c]
   169a8: e51b3018     	ldr	r3, [r11, #-0x18]
   169ac: e51b1030     	ldr	r1, [r11, #-0x30]
   169b0: e1a02182     	lsl	r2, r2, #3
   169b4: e0823003     	add	r3, r2, r3
   169b8: e2832036     	add	r2, r3, #54
   169bc: e3a03004     	mov	r3, #4
   169c0: e1a02102     	lsl	r2, r2, #2
   169c4: e0812002     	add	r2, r1, r2
   169c8: e0823003     	add	r3, r2, r3
   169cc: e5933000     	ldr	r3, [r3]
   169d0: e54b3009     	strb	r3, [r11, #-0x9]
   169d4: e51b3014     	ldr	r3, [r11, #-0x14]
   169d8: e51b2008     	ldr	r2, [r11, #-0x8]
   169dc: e0821003     	add	r1, r2, r3
   169e0: e55b2009     	ldrb	r2, [r11, #-0x9]
   169e4: e51b002c     	ldr	r0, [r11, #-0x2c]
   169e8: e51b3014     	ldr	r3, [r11, #-0x14]
   169ec: e0633000     	rsb	r3, r3, r0
   169f0: e1a00001     	mov	r0, r1
   169f4: e1a01002     	mov	r1, r2
   169f8: e1a02003     	mov	r2, r3
   169fc: ebffd668     	bl	0xc3a4 <memset@plt>     @ imm = #-0xa660
   16a00: e51b301c     	ldr	r3, [r11, #-0x1c]
   16a04: e2833001     	add	r3, r3, #1
   16a08: e50b301c     	str	r3, [r11, #-0x1c]
   16a0c: e51b201c     	ldr	r2, [r11, #-0x1c]
   16a10: e51b3028     	ldr	r3, [r11, #-0x28]
   16a14: e1520003     	cmp	r2, r3
   16a18: baffff87     	blt	0x1683c <FillTable4Bit+0x28> @ imm = #-0x1e4
   16a1c: e24bd004     	sub	sp, r11, #4
   16a20: e8bd8800     	pop	{r11, pc}

