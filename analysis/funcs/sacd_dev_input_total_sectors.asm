000220e0 <sacd_dev_input_total_sectors>:
   220e0: e92d4bf0     	push	{r4, r5, r6, r7, r8, r9, r11, lr}
   220e4: e28db01c     	add	r11, sp, #28
   220e8: e24dd070     	sub	sp, sp, #112
   220ec: e50b0088     	str	r0, [r11, #-0x88]
   220f0: e51b3088     	ldr	r3, [r11, #-0x88]
   220f4: e3530000     	cmp	r3, #0
   220f8: 1a000001     	bne	0x22104 <sacd_dev_input_total_sectors+0x24> @ imm = #0x4
   220fc: e3a03000     	mov	r3, #0
   22100: ea00002c     	b	0x221b8 <sacd_dev_input_total_sectors+0xd8> @ imm = #0xb0
   22104: e51b3088     	ldr	r3, [r11, #-0x88]
   22108: e5932000     	ldr	r2, [r3]
   2210c: e24b3084     	sub	r3, r11, #132
   22110: e1a00002     	mov	r0, r2
   22114: e1a01003     	mov	r1, r3
   22118: eb003e19     	bl	0x31984 <fstat64>       @ imm = #0xf864
   2211c: e1a03000     	mov	r3, r0
   22120: e3530000     	cmp	r3, #0
   22124: aa000001     	bge	0x22130 <sacd_dev_input_total_sectors+0x50> @ imm = #0x4
   22128: e3a03000     	mov	r3, #0
   2212c: ea000021     	b	0x221b8 <sacd_dev_input_total_sectors+0xd8> @ imm = #0x84
   22130: e14b05d4     	ldrd	r0, r1, [r11, #-84]
   22134: e1a03000     	mov	r3, r0
   22138: e1833001     	orr	r3, r3, r1
   2213c: e3530000     	cmp	r3, #0
   22140: 1a00000c     	bne	0x22178 <sacd_dev_input_total_sectors+0x98> @ imm = #0x30
   22144: e51b3088     	ldr	r3, [r11, #-0x88]
   22148: e5932000     	ldr	r2, [r3]
   2214c: e24b3084     	sub	r3, r11, #132
   22150: e2833030     	add	r3, r3, #48
   22154: e1a00002     	mov	r0, r2
   22158: e59f1064     	ldr	r1, [pc, #0x64]         @ 0x221c4 <sacd_dev_input_total_sectors+0xe4>
   2215c: e1a02003     	mov	r2, r3
   22160: ebffa8d1     	bl	0xc4ac <ioctl@plt>      @ imm = #-0x15cbc
   22164: e1a03000     	mov	r3, r0
   22168: e3530000     	cmp	r3, #0
   2216c: aa000001     	bge	0x22178 <sacd_dev_input_total_sectors+0x98> @ imm = #0x4
   22170: e3a03000     	mov	r3, #0
   22174: ea00000f     	b	0x221b8 <sacd_dev_input_total_sectors+0xd8> @ imm = #0x3c
   22178: e14b25d4     	ldrd	r2, r3, [r11, #-84]
   2217c: e1a00003     	mov	r0, r3
   22180: e1a01fc0     	asr	r1, r0, #31
   22184: e1a08fc1     	asr	r8, r1, #31
   22188: e1a09fc1     	asr	r9, r1, #31
   2218c: e1a06aa9     	lsr	r6, r9, #21
   22190: e3a07000     	mov	r7, #0
   22194: e0922006     	adds	r2, r2, r6
   22198: e0a33007     	adc	r3, r3, r7
   2219c: e1a01a83     	lsl	r1, r3, #21
   221a0: e1a045a2     	lsr	r4, r2, #11
   221a4: e1814004     	orr	r4, r1, r4
   221a8: e1a055c3     	asr	r5, r3, #11
   221ac: e1a02004     	mov	r2, r4
   221b0: e1a03005     	mov	r3, r5
   221b4: e1a03002     	mov	r3, r2
   221b8: e1a00003     	mov	r0, r3
   221bc: e24bd01c     	sub	sp, r11, #28
   221c0: e8bd8bf0     	pop	{r4, r5, r6, r7, r8, r9, r11, pc}
   221c4: 72 12 04 80  	.word	0x80041272

