0000ebb4 <read_raw_value>:
    ebb4: e92d4800     	push	{r11, lr}
    ebb8: e28db004     	add	r11, sp, #4
    ebbc: e24dd018     	sub	sp, sp, #24
    ebc0: e50b0010     	str	r0, [r11, #-0x10]
    ebc4: e50b1014     	str	r1, [r11, #-0x14]
    ebc8: e50b2018     	str	r2, [r11, #-0x18]
    ebcc: e50b301c     	str	r3, [r11, #-0x1c]
    ebd0: e51b301c     	ldr	r3, [r11, #-0x1c]
    ebd4: e5933000     	ldr	r3, [r3]
    ebd8: e50b3008     	str	r3, [r11, #-0x8]
    ebdc: e51b3014     	ldr	r3, [r11, #-0x14]
    ebe0: e3530001     	cmp	r3, #1
    ebe4: 0a000029     	beq	0xec90 <read_raw_value+0xdc> @ imm = #0xa4
    ebe8: e3530001     	cmp	r3, #1
    ebec: 3a000002     	blo	0xebfc <read_raw_value+0x48> @ imm = #0x8
    ebf0: e3530005     	cmp	r3, #5
    ebf4: 0a00002e     	beq	0xecb4 <read_raw_value+0x100> @ imm = #0xb8
    ebf8: ea000036     	b	0xecd8 <read_raw_value+0x124> @ imm = #0xd8
    ebfc: e51b301c     	ldr	r3, [r11, #-0x1c]
    ec00: e3a02000     	mov	r2, #0
    ec04: e5832000     	str	r2, [r3]
    ec08: e51b301c     	ldr	r3, [r11, #-0x1c]
    ec0c: e5933000     	ldr	r3, [r3]
    ec10: e2832001     	add	r2, r3, #1
    ec14: e51b301c     	ldr	r3, [r11, #-0x1c]
    ec18: e5832000     	str	r2, [r3]
    ec1c: e51b301c     	ldr	r3, [r11, #-0x1c]
    ec20: e5932000     	ldr	r2, [r3]
    ec24: e51b3008     	ldr	r3, [r11, #-0x8]
    ec28: e1520003     	cmp	r2, r3
    ec2c: 9a000001     	bls	0xec38 <read_raw_value+0x84> @ imm = #0x4
    ec30: e3a03000     	mov	r3, #0
    ec34: ea000028     	b	0xecdc <read_raw_value+0x128> @ imm = #0xa0
    ec38: e51b0010     	ldr	r0, [r11, #-0x10]
    ec3c: e51b1018     	ldr	r1, [r11, #-0x18]
    ec40: e3a02001     	mov	r2, #1
    ec44: ebfffee4     	bl	0xe7dc <pb_read>        @ imm = #-0x470
    ec48: e1a03000     	mov	r3, r0
    ec4c: e2233001     	eor	r3, r3, #1
    ec50: e6ef3073     	uxtb	r3, r3
    ec54: e3530000     	cmp	r3, #0
    ec58: 0a000001     	beq	0xec64 <read_raw_value+0xb0> @ imm = #0x4
    ec5c: e3a03000     	mov	r3, #0
    ec60: ea00001d     	b	0xecdc <read_raw_value+0x128> @ imm = #0x74
    ec64: e51b3018     	ldr	r3, [r11, #-0x18]
    ec68: e5d33000     	ldrb	r3, [r3]
    ec6c: e1a033a3     	lsr	r3, r3, #7
    ec70: e6ef3073     	uxtb	r3, r3
    ec74: e51b2018     	ldr	r2, [r11, #-0x18]
    ec78: e2822001     	add	r2, r2, #1
    ec7c: e50b2018     	str	r2, [r11, #-0x18]
    ec80: e3530000     	cmp	r3, #0
    ec84: 1affffdf     	bne	0xec08 <read_raw_value+0x54> @ imm = #-0x84
    ec88: e3a03001     	mov	r3, #1
    ec8c: ea000012     	b	0xecdc <read_raw_value+0x128> @ imm = #0x48
    ec90: e51b301c     	ldr	r3, [r11, #-0x1c]
    ec94: e3a02008     	mov	r2, #8
    ec98: e5832000     	str	r2, [r3]
    ec9c: e51b0010     	ldr	r0, [r11, #-0x10]
    eca0: e51b1018     	ldr	r1, [r11, #-0x18]
    eca4: e3a02008     	mov	r2, #8
    eca8: ebfffecb     	bl	0xe7dc <pb_read>        @ imm = #-0x4d4
    ecac: e1a03000     	mov	r3, r0
    ecb0: ea000009     	b	0xecdc <read_raw_value+0x128> @ imm = #0x24
    ecb4: e51b301c     	ldr	r3, [r11, #-0x1c]
    ecb8: e3a02004     	mov	r2, #4
    ecbc: e5832000     	str	r2, [r3]
    ecc0: e51b0010     	ldr	r0, [r11, #-0x10]
    ecc4: e51b1018     	ldr	r1, [r11, #-0x18]
    ecc8: e3a02004     	mov	r2, #4
    eccc: ebfffec2     	bl	0xe7dc <pb_read>        @ imm = #-0x4f8
    ecd0: e1a03000     	mov	r3, r0
    ecd4: ea000000     	b	0xecdc <read_raw_value+0x128> @ imm = #0x0
    ecd8: e3a03000     	mov	r3, #0
    ecdc: e1a00003     	mov	r0, r3
    ece0: e24bd004     	sub	sp, r11, #4
    ece4: e8bd8800     	pop	{r11, pc}

