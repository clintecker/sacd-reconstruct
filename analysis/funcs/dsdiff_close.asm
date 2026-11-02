00027250 <dsdiff_close>:
   27250: e92d4800     	push	{r11, lr}
   27254: e28db004     	add	r11, sp, #4
   27258: e24dd010     	sub	sp, sp, #16
   2725c: e50b0010     	str	r0, [r11, #-0x10]
   27260: e51b3010     	ldr	r3, [r11, #-0x10]
   27264: e593305c     	ldr	r3, [r3, #0x5c]
   27268: e50b3008     	str	r3, [r11, #-0x8]
   2726c: e51b3008     	ldr	r3, [r11, #-0x8]
   27270: e3530000     	cmp	r3, #0
   27274: 1a000001     	bne	0x27280 <dsdiff_close+0x30> @ imm = #0x4
   27278: e3a03000     	mov	r3, #0
   2727c: ea00004a     	b	0x273ac <dsdiff_close+0x15c> @ imm = #0x128
   27280: e51b3008     	ldr	r3, [r11, #-0x8]
   27284: e1c321d8     	ldrd	r2, r3, [r3, #24]
   27288: e1a03002     	mov	r3, r2
   2728c: e2033001     	and	r3, r3, #1
   27290: e6ef3073     	uxtb	r3, r3
   27294: e3530000     	cmp	r3, #0
   27298: 0a000010     	beq	0x272e0 <dsdiff_close+0x90> @ imm = #0x40
   2729c: e3a03000     	mov	r3, #0
   272a0: e54b3009     	strb	r3, [r11, #-0x9]
   272a4: e51b3010     	ldr	r3, [r11, #-0x10]
   272a8: e593301c     	ldr	r3, [r3, #0x1c]
   272ac: e24b2009     	sub	r2, r11, #9
   272b0: e1a00002     	mov	r0, r2
   272b4: e3a01001     	mov	r1, #1
   272b8: e3a02001     	mov	r2, #1
   272bc: ebff94cb     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x1acd4
   272c0: e51b3008     	ldr	r3, [r11, #-0x8]
   272c4: e1c301d8     	ldrd	r0, r1, [r3, #24]
   272c8: e3a02001     	mov	r2, #1
   272cc: e3a03000     	mov	r3, #0
   272d0: e0922000     	adds	r2, r2, r0
   272d4: e0a33001     	adc	r3, r3, r1
   272d8: e51b1008     	ldr	r1, [r11, #-0x8]
   272dc: e1c121f8     	strd	r2, r3, [r1, #24]
   272e0: e51b0010     	ldr	r0, [r11, #-0x10]
   272e4: ebffef54     	bl	0x2303c <calculate_header_and_footer> @ imm = #-0x42b0
   272e8: e51b3008     	ldr	r3, [r11, #-0x8]
   272ec: e5931008     	ldr	r1, [r3, #0x8]
   272f0: e51b3008     	ldr	r3, [r11, #-0x8]
   272f4: e593200c     	ldr	r2, [r3, #0xc]
   272f8: e51b3010     	ldr	r3, [r11, #-0x10]
   272fc: e593301c     	ldr	r3, [r3, #0x1c]
   27300: e1a00001     	mov	r0, r1
   27304: e3a01001     	mov	r1, #1
   27308: ebff94b8     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x1ad20
   2730c: e51b3010     	ldr	r3, [r11, #-0x10]
   27310: e593301c     	ldr	r3, [r3, #0x1c]
   27314: e1a00003     	mov	r0, r3
   27318: e3a01000     	mov	r1, #0
   2731c: e3a02000     	mov	r2, #0
   27320: ebff944f     	bl	0xc464 <fseek@plt>      @ imm = #-0x1aec4
   27324: e51b3008     	ldr	r3, [r11, #-0x8]
   27328: e5931000     	ldr	r1, [r3]
   2732c: e51b3008     	ldr	r3, [r11, #-0x8]
   27330: e5932004     	ldr	r2, [r3, #0x4]
   27334: e51b3010     	ldr	r3, [r11, #-0x10]
   27338: e593301c     	ldr	r3, [r3, #0x1c]
   2733c: e1a00001     	mov	r0, r1
   27340: e3a01001     	mov	r1, #1
   27344: ebff94a9     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x1ad5c
   27348: e51b3008     	ldr	r3, [r11, #-0x8]
   2734c: e5933020     	ldr	r3, [r3, #0x20]
   27350: e3530000     	cmp	r3, #0
   27354: 0a000003     	beq	0x27368 <dsdiff_close+0x118> @ imm = #0xc
   27358: e51b3008     	ldr	r3, [r11, #-0x8]
   2735c: e5933020     	ldr	r3, [r3, #0x20]
   27360: e1a00003     	mov	r0, r3
   27364: ebff942c     	bl	0xc41c <free@plt>       @ imm = #-0x1af50
   27368: e51b3008     	ldr	r3, [r11, #-0x8]
   2736c: e5933000     	ldr	r3, [r3]
   27370: e3530000     	cmp	r3, #0
   27374: 0a000003     	beq	0x27388 <dsdiff_close+0x138> @ imm = #0xc
   27378: e51b3008     	ldr	r3, [r11, #-0x8]
   2737c: e5933000     	ldr	r3, [r3]
   27380: e1a00003     	mov	r0, r3
   27384: ebff9424     	bl	0xc41c <free@plt>       @ imm = #-0x1af70
   27388: e51b3008     	ldr	r3, [r11, #-0x8]
   2738c: e5933008     	ldr	r3, [r3, #0x8]
   27390: e3530000     	cmp	r3, #0
   27394: 0a000003     	beq	0x273a8 <dsdiff_close+0x158> @ imm = #0xc
   27398: e51b3008     	ldr	r3, [r11, #-0x8]
   2739c: e5933008     	ldr	r3, [r3, #0x8]
   273a0: e1a00003     	mov	r0, r3
   273a4: ebff941c     	bl	0xc41c <free@plt>       @ imm = #-0x1af90
   273a8: e3a03000     	mov	r3, #0
   273ac: e1a00003     	mov	r0, r3
   273b0: e24bd004     	sub	sp, r11, #4
   273b4: e8bd8800     	pop	{r11, pc}

