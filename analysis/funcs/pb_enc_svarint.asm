00012074 <pb_enc_svarint>:
   12074: e92d4800     	push	{r11, lr}
   12078: e28db004     	add	r11, sp, #4
   1207c: e24dd030     	sub	sp, sp, #48
   12080: e50b0028     	str	r0, [r11, #-0x28]
   12084: e50b102c     	str	r1, [r11, #-0x2c]
   12088: e50b2030     	str	r2, [r11, #-0x30]
   1208c: e3a02000     	mov	r2, #0
   12090: e3a03000     	mov	r3, #0
   12094: e14b22f4     	strd	r2, r3, [r11, #-36]
   12098: e51b302c     	ldr	r3, [r11, #-0x2c]
   1209c: e5d32004     	ldrb	r2, [r3, #0x4]
   120a0: e5d31005     	ldrb	r1, [r3, #0x5]
   120a4: e1a01401     	lsl	r1, r1, #8
   120a8: e1812002     	orr	r2, r1, r2
   120ac: e5d31006     	ldrb	r1, [r3, #0x6]
   120b0: e1a01801     	lsl	r1, r1, #16
   120b4: e1812002     	orr	r2, r1, r2
   120b8: e5d33007     	ldrb	r3, [r3, #0x7]
   120bc: e1a03c03     	lsl	r3, r3, #24
   120c0: e1833002     	orr	r3, r3, r2
   120c4: e24b2024     	sub	r2, r11, #36
   120c8: e1a00002     	mov	r0, r2
   120cc: e51b1030     	ldr	r1, [r11, #-0x30]
   120d0: e3a02008     	mov	r2, #8
   120d4: ebffffb9     	bl	0x11fc0 <endian_copy>   @ imm = #-0x11c
   120d8: e51b302c     	ldr	r3, [r11, #-0x2c]
   120dc: e5d32004     	ldrb	r2, [r3, #0x4]
   120e0: e5d31005     	ldrb	r1, [r3, #0x5]
   120e4: e1a01401     	lsl	r1, r1, #8
   120e8: e1812002     	orr	r2, r1, r2
   120ec: e5d31006     	ldrb	r1, [r3, #0x6]
   120f0: e1a01801     	lsl	r1, r1, #16
   120f4: e1812002     	orr	r2, r1, r2
   120f8: e5d33007     	ldrb	r3, [r3, #0x7]
   120fc: e1a03c03     	lsl	r3, r3, #24
   12100: e1833002     	orr	r3, r3, r2
   12104: e243321e     	sub	r3, r3, #-536870911
   12108: e1a03183     	lsl	r3, r3, #3
   1210c: e2432020     	sub	r2, r3, #32
   12110: e3a01080     	mov	r1, #128
   12114: e1a01211     	lsl	r1, r1, r2
   12118: e2630020     	rsb	r0, r3, #32
   1211c: e3a0c080     	mov	r12, #128
   12120: e1a0003c     	lsr	r0, r12, r0
   12124: e3a0c000     	mov	r12, #0
   12128: e1a0c31c     	lsl	r12, r12, r3
   1212c: e18c0000     	orr	r0, r12, r0
   12130: e50b0010     	str	r0, [r11, #-0x10]
   12134: e51b0010     	ldr	r0, [r11, #-0x10]
   12138: e3520000     	cmp	r2, #0
   1213c: b1a02000     	movlt	r2, r0
   12140: a1a02001     	movge	r2, r1
   12144: e50b2010     	str	r2, [r11, #-0x10]
   12148: e3a02080     	mov	r2, #128
   1214c: e1a03312     	lsl	r3, r2, r3
   12150: e50b3014     	str	r3, [r11, #-0x14]
   12154: e51b302c     	ldr	r3, [r11, #-0x2c]
   12158: e5d32004     	ldrb	r2, [r3, #0x4]
   1215c: e5d31005     	ldrb	r1, [r3, #0x5]
   12160: e1a01401     	lsl	r1, r1, #8
   12164: e1812002     	orr	r2, r1, r2
   12168: e5d31006     	ldrb	r1, [r3, #0x6]
   1216c: e1a01801     	lsl	r1, r1, #16
   12170: e1812002     	orr	r2, r1, r2
   12174: e5d33007     	ldrb	r3, [r3, #0x7]
   12178: e1a03c03     	lsl	r3, r3, #24
   1217c: e1833002     	orr	r3, r3, r2
   12180: e2633008     	rsb	r3, r3, #8
   12184: e1a03183     	lsl	r3, r3, #3
   12188: e2432020     	sub	r2, r3, #32
   1218c: e3e01000     	mvn	r1, #0
   12190: e1a01231     	lsr	r1, r1, r2
   12194: e2630020     	rsb	r0, r3, #32
   12198: e3e0c000     	mvn	r12, #0
   1219c: e1a0001c     	lsl	r0, r12, r0
   121a0: e3e0c000     	mvn	r12, #0
   121a4: e1a0c33c     	lsr	r12, r12, r3
   121a8: e18c0000     	orr	r0, r12, r0
   121ac: e50b000c     	str	r0, [r11, #-0xc]
   121b0: e51b000c     	ldr	r0, [r11, #-0xc]
   121b4: e3520000     	cmp	r2, #0
   121b8: b1a02000     	movlt	r2, r0
   121bc: a1a02001     	movge	r2, r1
   121c0: e50b200c     	str	r2, [r11, #-0xc]
   121c4: e3e02000     	mvn	r2, #0
   121c8: e1a03332     	lsr	r3, r2, r3
   121cc: e50b3008     	str	r3, [r11, #-0x8]
   121d0: e14b02d4     	ldrd	r0, r1, [r11, #-36]
   121d4: e14b21d4     	ldrd	r2, r3, [r11, #-20]
   121d8: e0000002     	and	r0, r0, r2
   121dc: e0011003     	and	r1, r1, r3
   121e0: e1a03000     	mov	r3, r0
   121e4: e1833001     	orr	r3, r3, r1
   121e8: e3530000     	cmp	r3, #0
   121ec: 0a00000d     	beq	0x12228 <pb_enc_svarint+0x1b4> @ imm = #0x34
   121f0: e14b02d4     	ldrd	r0, r1, [r11, #-36]
   121f4: e14b20dc     	ldrd	r2, r3, [r11, #-12]
   121f8: e0222000     	eor	r2, r2, r0
   121fc: e0233001     	eor	r3, r3, r1
   12200: e0922002     	adds	r2, r2, r2
   12204: e0a33003     	adc	r3, r3, r3
   12208: e1a00002     	mov	r0, r2
   1220c: e1a01003     	mov	r1, r3
   12210: e3a02001     	mov	r2, #1
   12214: e3a03000     	mov	r3, #0
   12218: e1822000     	orr	r2, r2, r0
   1221c: e1833001     	orr	r3, r3, r1
   12220: e14b21fc     	strd	r2, r3, [r11, #-28]
   12224: ea000003     	b	0x12238 <pb_enc_svarint+0x1c4> @ imm = #0xc
   12228: e14b22d4     	ldrd	r2, r3, [r11, #-36]
   1222c: e0922002     	adds	r2, r2, r2
   12230: e0a33003     	adc	r3, r3, r3
   12234: e14b21fc     	strd	r2, r3, [r11, #-28]
   12238: e51b0028     	ldr	r0, [r11, #-0x28]
   1223c: e14b21dc     	ldrd	r2, r3, [r11, #-28]
   12240: ebfffebe     	bl	0x11d40 <pb_encode_varint> @ imm = #-0x508
   12244: e1a03000     	mov	r3, r0
   12248: e1a00003     	mov	r0, r3
   1224c: e24bd004     	sub	sp, r11, #4
   12250: e8bd8800     	pop	{r11, pc}

