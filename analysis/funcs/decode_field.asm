0000efec <decode_field>:
    efec: e92d4800     	push	{r11, lr}
    eff0: e28db004     	add	r11, sp, #4
    eff4: e24dd070     	sub	sp, sp, #112
    eff8: e50b0058     	str	r0, [r11, #-0x58]
    effc: e50b105c     	str	r1, [r11, #-0x5c]
    f000: e50b2060     	str	r2, [r11, #-0x60]
    f004: e51b3060     	ldr	r3, [r11, #-0x60]
    f008: e5933004     	ldr	r3, [r3, #0x4]
    f00c: e5d33001     	ldrb	r3, [r3, #0x1]
    f010: e203200f     	and	r2, r3, #15
    f014: e59f33f4     	ldr	r3, [pc, #0x3f4]        @ 0xf410 <decode_field+0x424>
    f018: e7933102     	ldr	r3, [r3, r2, lsl #2]
    f01c: e50b301c     	str	r3, [r11, #-0x1c]
    f020: e51b3060     	ldr	r3, [r11, #-0x60]
    f024: e5933004     	ldr	r3, [r3, #0x4]
    f028: e5d33001     	ldrb	r3, [r3, #0x1]
    f02c: e20330f0     	and	r3, r3, #240
    f030: e3530010     	cmp	r3, #16
    f034: 0a000012     	beq	0xf084 <decode_field+0x98> @ imm = #0x48
    f038: e3530010     	cmp	r3, #16
    f03c: ca000002     	bgt	0xf04c <decode_field+0x60> @ imm = #0x8
    f040: e3530000     	cmp	r3, #0
    f044: 0a000005     	beq	0xf060 <decode_field+0x74> @ imm = #0x14
    f048: ea0000ec     	b	0xf400 <decode_field+0x414> @ imm = #0x3b0
    f04c: e3530020     	cmp	r3, #32
    f050: 0a000018     	beq	0xf0b8 <decode_field+0xcc> @ imm = #0x60
    f054: e3530030     	cmp	r3, #48
    f058: 0a000093     	beq	0xf2ac <decode_field+0x2c0> @ imm = #0x24c
    f05c: ea0000e7     	b	0xf400 <decode_field+0x414> @ imm = #0x39c
    f060: e51b3060     	ldr	r3, [r11, #-0x60]
    f064: e5931004     	ldr	r1, [r3, #0x4]
    f068: e51b3060     	ldr	r3, [r11, #-0x60]
    f06c: e5932010     	ldr	r2, [r3, #0x10]
    f070: e51b301c     	ldr	r3, [r11, #-0x1c]
    f074: e51b0058     	ldr	r0, [r11, #-0x58]
    f078: e12fff33     	blx	r3
    f07c: e1a03000     	mov	r3, r0
    f080: ea0000df     	b	0xf404 <decode_field+0x418> @ imm = #0x37c
    f084: e51b3060     	ldr	r3, [r11, #-0x60]
    f088: e5933014     	ldr	r3, [r3, #0x14]
    f08c: e3a02001     	mov	r2, #1
    f090: e5c32000     	strb	r2, [r3]
    f094: e51b3060     	ldr	r3, [r11, #-0x60]
    f098: e5931004     	ldr	r1, [r3, #0x4]
    f09c: e51b3060     	ldr	r3, [r11, #-0x60]
    f0a0: e5932010     	ldr	r2, [r3, #0x10]
    f0a4: e51b301c     	ldr	r3, [r11, #-0x1c]
    f0a8: e51b0058     	ldr	r0, [r11, #-0x58]
    f0ac: e12fff33     	blx	r3
    f0b0: e1a03000     	mov	r3, r0
    f0b4: ea0000d2     	b	0xf404 <decode_field+0x418> @ imm = #0x348
    f0b8: e51b305c     	ldr	r3, [r11, #-0x5c]
    f0bc: e3530002     	cmp	r3, #2
    f0c0: 1a00004c     	bne	0xf1f8 <decode_field+0x20c> @ imm = #0x130
    f0c4: e51b3060     	ldr	r3, [r11, #-0x60]
    f0c8: e5933004     	ldr	r3, [r3, #0x4]
    f0cc: e5d33001     	ldrb	r3, [r3, #0x1]
    f0d0: e203300f     	and	r3, r3, #15
    f0d4: e3530003     	cmp	r3, #3
    f0d8: ca000046     	bgt	0xf1f8 <decode_field+0x20c> @ imm = #0x118
    f0dc: e51b3060     	ldr	r3, [r11, #-0x60]
    f0e0: e5933014     	ldr	r3, [r3, #0x14]
    f0e4: e50b3018     	str	r3, [r11, #-0x18]
    f0e8: e24b3028     	sub	r3, r11, #40
    f0ec: e51b0058     	ldr	r0, [r11, #-0x58]
    f0f0: e1a01003     	mov	r1, r3
    f0f4: ebfffefb     	bl	0xece8 <make_string_substream> @ imm = #-0x414
    f0f8: e1a03000     	mov	r3, r0
    f0fc: e2233001     	eor	r3, r3, #1
    f100: e6ef3073     	uxtb	r3, r3
    f104: e3530000     	cmp	r3, #0
    f108: 0a000029     	beq	0xf1b4 <decode_field+0x1c8> @ imm = #0xa4
    f10c: e3a03000     	mov	r3, #0
    f110: ea0000bb     	b	0xf404 <decode_field+0x418> @ imm = #0x2ec
    f114: e51b3060     	ldr	r3, [r11, #-0x60]
    f118: e5932010     	ldr	r2, [r3, #0x10]
    f11c: e51b3060     	ldr	r3, [r11, #-0x60]
    f120: e5933004     	ldr	r3, [r3, #0x4]
    f124: e5d31004     	ldrb	r1, [r3, #0x4]
    f128: e5d30005     	ldrb	r0, [r3, #0x5]
    f12c: e1a00400     	lsl	r0, r0, #8
    f130: e1801001     	orr	r1, r0, r1
    f134: e5d30006     	ldrb	r0, [r3, #0x6]
    f138: e1a00800     	lsl	r0, r0, #16
    f13c: e1801001     	orr	r1, r0, r1
    f140: e5d33007     	ldrb	r3, [r3, #0x7]
    f144: e1a03c03     	lsl	r3, r3, #24
    f148: e1833001     	orr	r3, r3, r1
    f14c: e51b1018     	ldr	r1, [r11, #-0x18]
    f150: e5911000     	ldr	r1, [r1]
    f154: e0030391     	mul	r3, r1, r3
    f158: e0823003     	add	r3, r2, r3
    f15c: e50b3014     	str	r3, [r11, #-0x14]
    f160: e51b3060     	ldr	r3, [r11, #-0x60]
    f164: e5932004     	ldr	r2, [r3, #0x4]
    f168: e24b1028     	sub	r1, r11, #40
    f16c: e51b301c     	ldr	r3, [r11, #-0x1c]
    f170: e1a00001     	mov	r0, r1
    f174: e1a01002     	mov	r1, r2
    f178: e51b2014     	ldr	r2, [r11, #-0x14]
    f17c: e12fff33     	blx	r3
    f180: e1a03000     	mov	r3, r0
    f184: e2233001     	eor	r3, r3, #1
    f188: e6ef3073     	uxtb	r3, r3
    f18c: e3530000     	cmp	r3, #0
    f190: 0a000001     	beq	0xf19c <decode_field+0x1b0> @ imm = #0x4
    f194: e3a03000     	mov	r3, #0
    f198: ea000099     	b	0xf404 <decode_field+0x418> @ imm = #0x264
    f19c: e51b3018     	ldr	r3, [r11, #-0x18]
    f1a0: e5933000     	ldr	r3, [r3]
    f1a4: e2832001     	add	r2, r3, #1
    f1a8: e51b3018     	ldr	r3, [r11, #-0x18]
    f1ac: e5832000     	str	r2, [r3]
    f1b0: ea000000     	b	0xf1b8 <decode_field+0x1cc> @ imm = #0x0
    f1b4: e1a00000     	mov	r0, r0
    f1b8: e51b3020     	ldr	r3, [r11, #-0x20]
    f1bc: e3530000     	cmp	r3, #0
    f1c0: 0a000006     	beq	0xf1e0 <decode_field+0x1f4> @ imm = #0x18
    f1c4: e51b3018     	ldr	r3, [r11, #-0x18]
    f1c8: e5932000     	ldr	r2, [r3]
    f1cc: e51b3060     	ldr	r3, [r11, #-0x60]
    f1d0: e5933004     	ldr	r3, [r3, #0x4]
    f1d4: e5d33008     	ldrb	r3, [r3, #0x8]
    f1d8: e1520003     	cmp	r2, r3
    f1dc: 3affffcc     	blo	0xf114 <decode_field+0x128> @ imm = #-0xd0
    f1e0: e51b3020     	ldr	r3, [r11, #-0x20]
    f1e4: e3530000     	cmp	r3, #0
    f1e8: 13a03000     	movne	r3, #0
    f1ec: 03a03001     	moveq	r3, #1
    f1f0: e6ef3073     	uxtb	r3, r3
    f1f4: ea000082     	b	0xf404 <decode_field+0x418> @ imm = #0x208
    f1f8: e51b3060     	ldr	r3, [r11, #-0x60]
    f1fc: e5933014     	ldr	r3, [r3, #0x14]
    f200: e50b3010     	str	r3, [r11, #-0x10]
    f204: e51b3060     	ldr	r3, [r11, #-0x60]
    f208: e5932010     	ldr	r2, [r3, #0x10]
    f20c: e51b3060     	ldr	r3, [r11, #-0x60]
    f210: e5933004     	ldr	r3, [r3, #0x4]
    f214: e5d31004     	ldrb	r1, [r3, #0x4]
    f218: e5d30005     	ldrb	r0, [r3, #0x5]
    f21c: e1a00400     	lsl	r0, r0, #8
    f220: e1801001     	orr	r1, r0, r1
    f224: e5d30006     	ldrb	r0, [r3, #0x6]
    f228: e1a00800     	lsl	r0, r0, #16
    f22c: e1801001     	orr	r1, r0, r1
    f230: e5d33007     	ldrb	r3, [r3, #0x7]
    f234: e1a03c03     	lsl	r3, r3, #24
    f238: e1833001     	orr	r3, r3, r1
    f23c: e51b1010     	ldr	r1, [r11, #-0x10]
    f240: e5911000     	ldr	r1, [r1]
    f244: e0030391     	mul	r3, r1, r3
    f248: e0823003     	add	r3, r2, r3
    f24c: e50b300c     	str	r3, [r11, #-0xc]
    f250: e51b3010     	ldr	r3, [r11, #-0x10]
    f254: e5932000     	ldr	r2, [r3]
    f258: e51b3060     	ldr	r3, [r11, #-0x60]
    f25c: e5933004     	ldr	r3, [r3, #0x4]
    f260: e5d33008     	ldrb	r3, [r3, #0x8]
    f264: e1520003     	cmp	r2, r3
    f268: 3a000001     	blo	0xf274 <decode_field+0x288> @ imm = #0x4
    f26c: e3a03000     	mov	r3, #0
    f270: ea000063     	b	0xf404 <decode_field+0x418> @ imm = #0x18c
    f274: e51b3010     	ldr	r3, [r11, #-0x10]
    f278: e5933000     	ldr	r3, [r3]
    f27c: e2832001     	add	r2, r3, #1
    f280: e51b3010     	ldr	r3, [r11, #-0x10]
    f284: e5832000     	str	r2, [r3]
    f288: e51b3060     	ldr	r3, [r11, #-0x60]
    f28c: e5932004     	ldr	r2, [r3, #0x4]
    f290: e51b301c     	ldr	r3, [r11, #-0x1c]
    f294: e51b0058     	ldr	r0, [r11, #-0x58]
    f298: e1a01002     	mov	r1, r2
    f29c: e51b200c     	ldr	r2, [r11, #-0xc]
    f2a0: e12fff33     	blx	r3
    f2a4: e1a03000     	mov	r3, r0
    f2a8: ea000055     	b	0xf404 <decode_field+0x418> @ imm = #0x154
    f2ac: e51b3060     	ldr	r3, [r11, #-0x60]
    f2b0: e5933010     	ldr	r3, [r3, #0x10]
    f2b4: e50b3008     	str	r3, [r11, #-0x8]
    f2b8: e51b3008     	ldr	r3, [r11, #-0x8]
    f2bc: e5933000     	ldr	r3, [r3]
    f2c0: e3530000     	cmp	r3, #0
    f2c4: 1a000004     	bne	0xf2dc <decode_field+0x2f0> @ imm = #0x10
    f2c8: e51b0058     	ldr	r0, [r11, #-0x58]
    f2cc: e51b105c     	ldr	r1, [r11, #-0x5c]
    f2d0: ebfffe10     	bl	0xeb18 <skip>           @ imm = #-0x7c0
    f2d4: e1a03000     	mov	r3, r0
    f2d8: ea000049     	b	0xf404 <decode_field+0x418> @ imm = #0x124
    f2dc: e51b305c     	ldr	r3, [r11, #-0x5c]
    f2e0: e3530002     	cmp	r3, #2
    f2e4: 1a000022     	bne	0xf374 <decode_field+0x388> @ imm = #0x88
    f2e8: e24b3034     	sub	r3, r11, #52
    f2ec: e51b0058     	ldr	r0, [r11, #-0x58]
    f2f0: e1a01003     	mov	r1, r3
    f2f4: ebfffe7b     	bl	0xece8 <make_string_substream> @ imm = #-0x614
    f2f8: e1a03000     	mov	r3, r0
    f2fc: e2233001     	eor	r3, r3, #1
    f300: e6ef3073     	uxtb	r3, r3
    f304: e3530000     	cmp	r3, #0
    f308: 0a000010     	beq	0xf350 <decode_field+0x364> @ imm = #0x40
    f30c: e3a03000     	mov	r3, #0
    f310: ea00003b     	b	0xf404 <decode_field+0x418> @ imm = #0xec
    f314: e51b3008     	ldr	r3, [r11, #-0x8]
    f318: e5933000     	ldr	r3, [r3]
    f31c: e51b2060     	ldr	r2, [r11, #-0x60]
    f320: e5921004     	ldr	r1, [r2, #0x4]
    f324: e51b2008     	ldr	r2, [r11, #-0x8]
    f328: e5922004     	ldr	r2, [r2, #0x4]
    f32c: e24b0034     	sub	r0, r11, #52
    f330: e12fff33     	blx	r3
    f334: e1a03000     	mov	r3, r0
    f338: e2233001     	eor	r3, r3, #1
    f33c: e6ef3073     	uxtb	r3, r3
    f340: e3530000     	cmp	r3, #0
    f344: 0a000002     	beq	0xf354 <decode_field+0x368> @ imm = #0x8
    f348: e3a03000     	mov	r3, #0
    f34c: ea00002c     	b	0xf404 <decode_field+0x418> @ imm = #0xb0
    f350: e1a00000     	mov	r0, r0
    f354: e51b302c     	ldr	r3, [r11, #-0x2c]
    f358: e3530000     	cmp	r3, #0
    f35c: 1affffec     	bne	0xf314 <decode_field+0x328> @ imm = #-0x50
    f360: e51b2030     	ldr	r2, [r11, #-0x30]
    f364: e51b3058     	ldr	r3, [r11, #-0x58]
    f368: e5832004     	str	r2, [r3, #0x4]
    f36c: e3a03001     	mov	r3, #1
    f370: ea000023     	b	0xf404 <decode_field+0x418> @ imm = #0x8c
    f374: e3a0300a     	mov	r3, #10
    f378: e50b3050     	str	r3, [r11, #-0x50]
    f37c: e51b105c     	ldr	r1, [r11, #-0x5c]
    f380: e24b204c     	sub	r2, r11, #76
    f384: e24b3050     	sub	r3, r11, #80
    f388: e51b0058     	ldr	r0, [r11, #-0x58]
    f38c: ebfffe08     	bl	0xebb4 <read_raw_value> @ imm = #-0x7e0
    f390: e1a03000     	mov	r3, r0
    f394: e2233001     	eor	r3, r3, #1
    f398: e6ef3073     	uxtb	r3, r3
    f39c: e3530000     	cmp	r3, #0
    f3a0: 0a000001     	beq	0xf3ac <decode_field+0x3c0> @ imm = #0x4
    f3a4: e3a03000     	mov	r3, #0
    f3a8: ea000015     	b	0xf404 <decode_field+0x418> @ imm = #0x54
    f3ac: e51b3050     	ldr	r3, [r11, #-0x50]
    f3b0: e24b1074     	sub	r1, r11, #116
    f3b4: e24b204c     	sub	r2, r11, #76
    f3b8: e1a00001     	mov	r0, r1
    f3bc: e1a01002     	mov	r1, r2
    f3c0: e1a02003     	mov	r2, r3
    f3c4: ebfffd41     	bl	0xe8d0 <pb_istream_from_buffer> @ imm = #-0xafc
    f3c8: e24b3040     	sub	r3, r11, #64
    f3cc: e24b2074     	sub	r2, r11, #116
    f3d0: e8920007     	ldm	r2, {r0, r1, r2}
    f3d4: e8830007     	stm	r3, {r0, r1, r2}
    f3d8: e51b3008     	ldr	r3, [r11, #-0x8]
    f3dc: e5933000     	ldr	r3, [r3]
    f3e0: e51b2060     	ldr	r2, [r11, #-0x60]
    f3e4: e5921004     	ldr	r1, [r2, #0x4]
    f3e8: e51b2008     	ldr	r2, [r11, #-0x8]
    f3ec: e5922004     	ldr	r2, [r2, #0x4]
    f3f0: e24b0040     	sub	r0, r11, #64
    f3f4: e12fff33     	blx	r3
    f3f8: e1a03000     	mov	r3, r0
    f3fc: ea000000     	b	0xf404 <decode_field+0x418> @ imm = #0x0
    f400: e3a03000     	mov	r3, #0
    f404: e1a00003     	mov	r0, r3
    f408: e24bd004     	sub	sp, r11, #4
    f40c: e8bd8800     	pop	{r11, pc}
    f410: 48 27 03 00  	.word	0x00032748

