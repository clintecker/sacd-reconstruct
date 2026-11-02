0000d130 <parse_options>:
    d130: e92d4800     	push	{r11, lr}
    d134: e28db004     	add	r11, sp, #4
    d138: e24dd028     	sub	sp, sp, #40
    d13c: e50b0020     	str	r0, [r11, #-0x20]
    d140: e50b1024     	str	r1, [r11, #-0x24]
    d144: e3a03000     	mov	r3, #0
    d148: e50b3018     	str	r3, [r11, #-0x18]
    d14c: e51b3024     	ldr	r3, [r11, #-0x24]
    d150: e5933000     	ldr	r3, [r3]
    d154: e1a00003     	mov	r0, r3
    d158: e3a0102f     	mov	r1, #47
    d15c: ebfffc93     	bl	0xc3b0 <strrchr@plt>    @ imm = #-0xdb4
    d160: e1a03000     	mov	r3, r0
    d164: e50b3018     	str	r3, [r11, #-0x18]
    d168: e51b3018     	ldr	r3, [r11, #-0x18]
    d16c: e3530000     	cmp	r3, #0
    d170: 0a000005     	beq	0xd18c <parse_options+0x5c> @ imm = #0x14
    d174: e51b3018     	ldr	r3, [r11, #-0x18]
    d178: e2833001     	add	r3, r3, #1
    d17c: e1a00003     	mov	r0, r3
    d180: ebfffd32     	bl	0xc650 <strdup@plt>     @ imm = #-0xb38
    d184: e1a03000     	mov	r3, r0
    d188: ea000004     	b	0xd1a0 <parse_options+0x70> @ imm = #0x10
    d18c: e51b3024     	ldr	r3, [r11, #-0x24]
    d190: e5933000     	ldr	r3, [r3]
    d194: e1a00003     	mov	r0, r3
    d198: ebfffd2c     	bl	0xc650 <strdup@plt>     @ imm = #-0xb50
    d19c: e1a03000     	mov	r3, r0
    d1a0: e50b3018     	str	r3, [r11, #-0x18]
    d1a4: ea0000e6     	b	0xd544 <parse_options+0x414> @ imm = #0x398
    d1a8: e51b301c     	ldr	r3, [r11, #-0x1c]
    d1ac: e2433032     	sub	r3, r3, #50
    d1b0: e3530043     	cmp	r3, #67
    d1b4: 979ff103     	ldrls	pc, [pc, r3, lsl #2]
    d1b8: ea0000e1     	b	0xd544 <parse_options+0x414> @ imm = #0x384
    d1bc: cc d2 00 00  	.word	0x0000d2cc
    d1c0: 44 d5 00 00  	.word	0x0000d544
    d1c4: 44 d5 00 00  	.word	0x0000d544
    d1c8: 44 d5 00 00  	.word	0x0000d544
    d1cc: 44 d5 00 00  	.word	0x0000d544
    d1d0: 44 d5 00 00  	.word	0x0000d544
    d1d4: 44 d5 00 00  	.word	0x0000d544
    d1d8: 44 d5 00 00  	.word	0x0000d544
    d1dc: 44 d5 00 00  	.word	0x0000d544
    d1e0: 44 d5 00 00  	.word	0x0000d544
    d1e4: 44 d5 00 00  	.word	0x0000d544
    d1e8: 44 d5 00 00  	.word	0x0000d544
    d1ec: 44 d5 00 00  	.word	0x0000d544
    d1f0: f4 d4 00 00  	.word	0x0000d4f4
    d1f4: 44 d5 00 00  	.word	0x0000d544
    d1f8: 44 d5 00 00  	.word	0x0000d544
    d1fc: 44 d5 00 00  	.word	0x0000d544
    d200: a0 d4 00 00  	.word	0x0000d4a0
    d204: 44 d5 00 00  	.word	0x0000d544
    d208: 44 d5 00 00  	.word	0x0000d544
    d20c: 44 d5 00 00  	.word	0x0000d544
    d210: 44 d5 00 00  	.word	0x0000d544
    d214: 44 d5 00 00  	.word	0x0000d544
    d218: 5c d4 00 00  	.word	0x0000d45c
    d21c: 44 d5 00 00  	.word	0x0000d544
    d220: 44 d5 00 00  	.word	0x0000d544
    d224: 44 d5 00 00  	.word	0x0000d544
    d228: 44 d5 00 00  	.word	0x0000d544
    d22c: 44 d5 00 00  	.word	0x0000d544
    d230: 44 d5 00 00  	.word	0x0000d544
    d234: d4 d4 00 00  	.word	0x0000d4d4
    d238: 44 d5 00 00  	.word	0x0000d544
    d23c: 44 d5 00 00  	.word	0x0000d544
    d240: e4 d4 00 00  	.word	0x0000d4e4
    d244: 44 d5 00 00  	.word	0x0000d544
    d248: 44 d5 00 00  	.word	0x0000d544
    d24c: 44 d5 00 00  	.word	0x0000d544
    d250: 44 d5 00 00  	.word	0x0000d544
    d254: 44 d5 00 00  	.word	0x0000d544
    d258: 44 d5 00 00  	.word	0x0000d544
    d25c: 44 d5 00 00  	.word	0x0000d544
    d260: 44 d5 00 00  	.word	0x0000d544
    d264: 44 d5 00 00  	.word	0x0000d544
    d268: 44 d5 00 00  	.word	0x0000d544
    d26c: 44 d5 00 00  	.word	0x0000d544
    d270: 44 d5 00 00  	.word	0x0000d544
    d274: 44 d5 00 00  	.word	0x0000d544
    d278: 44 d5 00 00  	.word	0x0000d544
    d27c: 44 d5 00 00  	.word	0x0000d544
    d280: 90 d4 00 00  	.word	0x0000d490
    d284: 44 d5 00 00  	.word	0x0000d544
    d288: ec d2 00 00  	.word	0x0000d2ec
    d28c: 44 d5 00 00  	.word	0x0000d544
    d290: 44 d5 00 00  	.word	0x0000d544
    d294: 44 d5 00 00  	.word	0x0000d544
    d298: b0 d4 00 00  	.word	0x0000d4b0
    d29c: 44 d5 00 00  	.word	0x0000d544
    d2a0: 44 d5 00 00  	.word	0x0000d544
    d2a4: 44 d5 00 00  	.word	0x0000d544
    d2a8: dc d2 00 00  	.word	0x0000d2dc
    d2ac: 44 d5 00 00  	.word	0x0000d544
    d2b0: 44 d5 00 00  	.word	0x0000d544
    d2b4: 2c d3 00 00  	.word	0x0000d32c
    d2b8: 44 d5 00 00  	.word	0x0000d544
    d2bc: 44 d5 00 00  	.word	0x0000d544
    d2c0: 60 d3 00 00  	.word	0x0000d360
    d2c4: 94 d3 00 00  	.word	0x0000d394
    d2c8: 1c d5 00 00  	.word	0x0000d51c
    d2cc: e59f32fc     	ldr	r3, [pc, #0x2fc]        @ 0xd5d0 <parse_options+0x4a0>
    d2d0: e3a02001     	mov	r2, #1
    d2d4: e5832000     	str	r2, [r3]
    d2d8: ea000099     	b	0xd544 <parse_options+0x414> @ imm = #0x264
    d2dc: e59f32ec     	ldr	r3, [pc, #0x2ec]        @ 0xd5d0 <parse_options+0x4a0>
    d2e0: e3a02001     	mov	r2, #1
    d2e4: e5832004     	str	r2, [r3, #0x4]
    d2e8: ea000095     	b	0xd544 <parse_options+0x414> @ imm = #0x254
    d2ec: e59f32dc     	ldr	r3, [pc, #0x2dc]        @ 0xd5d0 <parse_options+0x4a0>
    d2f0: e3a02001     	mov	r2, #1
    d2f4: e583200c     	str	r2, [r3, #0xc]
    d2f8: e59f32d0     	ldr	r3, [pc, #0x2d0]        @ 0xd5d0 <parse_options+0x4a0>
    d2fc: e3a02000     	mov	r2, #0
    d300: e5832010     	str	r2, [r3, #0x10]
    d304: e59f32c4     	ldr	r3, [pc, #0x2c4]        @ 0xd5d0 <parse_options+0x4a0>
    d308: e3a02000     	mov	r2, #0
    d30c: e5832008     	str	r2, [r3, #0x8]
    d310: e59f32b8     	ldr	r3, [pc, #0x2b8]        @ 0xd5d0 <parse_options+0x4a0>
    d314: e3a02000     	mov	r2, #0
    d318: e5832014     	str	r2, [r3, #0x14]
    d31c: e59f32ac     	ldr	r3, [pc, #0x2ac]        @ 0xd5d0 <parse_options+0x4a0>
    d320: e3a02001     	mov	r2, #1
    d324: e583201c     	str	r2, [r3, #0x1c]
    d328: ea000085     	b	0xd544 <parse_options+0x414> @ imm = #0x214
    d32c: e59f329c     	ldr	r3, [pc, #0x29c]        @ 0xd5d0 <parse_options+0x4a0>
    d330: e3a02000     	mov	r2, #0
    d334: e583200c     	str	r2, [r3, #0xc]
    d338: e59f3290     	ldr	r3, [pc, #0x290]        @ 0xd5d0 <parse_options+0x4a0>
    d33c: e3a02001     	mov	r2, #1
    d340: e5832010     	str	r2, [r3, #0x10]
    d344: e59f3284     	ldr	r3, [pc, #0x284]        @ 0xd5d0 <parse_options+0x4a0>
    d348: e3a02000     	mov	r2, #0
    d34c: e5832008     	str	r2, [r3, #0x8]
    d350: e59f3278     	ldr	r3, [pc, #0x278]        @ 0xd5d0 <parse_options+0x4a0>
    d354: e3a02000     	mov	r2, #0
    d358: e5832014     	str	r2, [r3, #0x14]
    d35c: ea000078     	b	0xd544 <parse_options+0x414> @ imm = #0x1e0
    d360: e59f3268     	ldr	r3, [pc, #0x268]        @ 0xd5d0 <parse_options+0x4a0>
    d364: e3a02000     	mov	r2, #0
    d368: e583200c     	str	r2, [r3, #0xc]
    d36c: e59f325c     	ldr	r3, [pc, #0x25c]        @ 0xd5d0 <parse_options+0x4a0>
    d370: e3a02000     	mov	r2, #0
    d374: e5832010     	str	r2, [r3, #0x10]
    d378: e59f3250     	ldr	r3, [pc, #0x250]        @ 0xd5d0 <parse_options+0x4a0>
    d37c: e3a02001     	mov	r2, #1
    d380: e5832008     	str	r2, [r3, #0x8]
    d384: e59f3244     	ldr	r3, [pc, #0x244]        @ 0xd5d0 <parse_options+0x4a0>
    d388: e3a02000     	mov	r2, #0
    d38c: e5832014     	str	r2, [r3, #0x14]
    d390: ea00006b     	b	0xd544 <parse_options+0x414> @ imm = #0x1ac
    d394: e3a03000     	mov	r3, #0
    d398: e50b3010     	str	r3, [r11, #-0x10]
    d39c: e59f3230     	ldr	r3, [pc, #0x230]        @ 0xd5d4 <parse_options+0x4a4>
    d3a0: e5932000     	ldr	r2, [r3]
    d3a4: e59f322c     	ldr	r3, [pc, #0x22c]        @ 0xd5d8 <parse_options+0x4a8>
    d3a8: e1a00002     	mov	r0, r2
    d3ac: e1a01003     	mov	r1, r3
    d3b0: ebfffcc1     	bl	0xc6bc <strtok@plt>     @ imm = #-0xcfc
    d3b4: e1a03000     	mov	r3, r0
    d3b8: e50b300c     	str	r3, [r11, #-0xc]
    d3bc: ea00001c     	b	0xd434 <parse_options+0x304> @ imm = #0x70
    d3c0: e51b000c     	ldr	r0, [r11, #-0xc]
    d3c4: ebfffc71     	bl	0xc590 <atoi@plt>       @ imm = #-0xe3c
    d3c8: e1a03000     	mov	r3, r0
    d3cc: e50b3014     	str	r3, [r11, #-0x14]
    d3d0: e59f3200     	ldr	r3, [pc, #0x200]        @ 0xd5d8 <parse_options+0x4a8>
    d3d4: e3a00000     	mov	r0, #0
    d3d8: e1a01003     	mov	r1, r3
    d3dc: ebfffcb6     	bl	0xc6bc <strtok@plt>     @ imm = #-0xd28
    d3e0: e1a03000     	mov	r3, r0
    d3e4: e50b300c     	str	r3, [r11, #-0xc]
    d3e8: e51b3014     	ldr	r3, [r11, #-0x14]
    d3ec: e3530000     	cmp	r3, #0
    d3f0: 0a00000e     	beq	0xd430 <parse_options+0x300> @ imm = #0x38
    d3f4: e51b3014     	ldr	r3, [r11, #-0x14]
    d3f8: e2433001     	sub	r3, r3, #1
    d3fc: e20330ff     	and	r3, r3, #255
    d400: e50b3014     	str	r3, [r11, #-0x14]
    d404: e51b2014     	ldr	r2, [r11, #-0x14]
    d408: e59f11c0     	ldr	r1, [pc, #0x1c0]        @ 0xd5d0 <parse_options+0x4a0>
    d40c: e3a03f8a     	mov	r3, #552
    d410: e0812002     	add	r2, r1, r2
    d414: e0823003     	add	r3, r2, r3
    d418: e3a02001     	mov	r2, #1
    d41c: e5c32004     	strb	r2, [r3, #0x4]
    d420: e51b3010     	ldr	r3, [r11, #-0x10]
    d424: e2833001     	add	r3, r3, #1
    d428: e50b3010     	str	r3, [r11, #-0x10]
    d42c: ea000000     	b	0xd434 <parse_options+0x304> @ imm = #0x0
    d430: e1a00000     	mov	r0, r0
    d434: e51b300c     	ldr	r3, [r11, #-0xc]
    d438: e3530000     	cmp	r3, #0
    d43c: 1affffdf     	bne	0xd3c0 <parse_options+0x290> @ imm = #-0x84
    d440: e51b3010     	ldr	r3, [r11, #-0x10]
    d444: e3530000     	cmp	r3, #0
    d448: 03a02000     	moveq	r2, #0
    d44c: 13a02001     	movne	r2, #1
    d450: e59f3178     	ldr	r3, [pc, #0x178]        @ 0xd5d0 <parse_options+0x4a0>
    d454: e5832228     	str	r2, [r3, #0x228]
    d458: ea000039     	b	0xd544 <parse_options+0x414> @ imm = #0xe4
    d45c: e59f316c     	ldr	r3, [pc, #0x16c]        @ 0xd5d0 <parse_options+0x4a0>
    d460: e3a02000     	mov	r2, #0
    d464: e583200c     	str	r2, [r3, #0xc]
    d468: e59f3160     	ldr	r3, [pc, #0x160]        @ 0xd5d0 <parse_options+0x4a0>
    d46c: e3a02000     	mov	r2, #0
    d470: e5832010     	str	r2, [r3, #0x10]
    d474: e59f3154     	ldr	r3, [pc, #0x154]        @ 0xd5d0 <parse_options+0x4a0>
    d478: e3a02000     	mov	r2, #0
    d47c: e5832008     	str	r2, [r3, #0x8]
    d480: e59f3148     	ldr	r3, [pc, #0x148]        @ 0xd5d0 <parse_options+0x4a0>
    d484: e3a02001     	mov	r2, #1
    d488: e5832014     	str	r2, [r3, #0x14]
    d48c: ea00002c     	b	0xd544 <parse_options+0x414> @ imm = #0xb0
    d490: e59f3138     	ldr	r3, [pc, #0x138]        @ 0xd5d0 <parse_options+0x4a0>
    d494: e3a02001     	mov	r2, #1
    d498: e5832018     	str	r2, [r3, #0x18]
    d49c: ea000028     	b	0xd544 <parse_options+0x414> @ imm = #0xa0
    d4a0: e59f3128     	ldr	r3, [pc, #0x128]        @ 0xd5d0 <parse_options+0x4a0>
    d4a4: e3a02001     	mov	r2, #1
    d4a8: e583201c     	str	r2, [r3, #0x1c]
    d4ac: ea000024     	b	0xd544 <parse_options+0x414> @ imm = #0x90
    d4b0: e59f311c     	ldr	r3, [pc, #0x11c]        @ 0xd5d4 <parse_options+0x4a4>
    d4b4: e5933000     	ldr	r3, [r3]
    d4b8: e1a00003     	mov	r0, r3
    d4bc: ebfffc63     	bl	0xc650 <strdup@plt>     @ imm = #-0xe74
    d4c0: e1a03000     	mov	r3, r0
    d4c4: e1a02003     	mov	r2, r3
    d4c8: e59f3100     	ldr	r3, [pc, #0x100]        @ 0xd5d0 <parse_options+0x4a0>
    d4cc: e5832024     	str	r2, [r3, #0x24]
    d4d0: ea00001b     	b	0xd544 <parse_options+0x414> @ imm = #0x6c
    d4d4: e59f30f4     	ldr	r3, [pc, #0xf4]         @ 0xd5d0 <parse_options+0x4a0>
    d4d8: e3a02001     	mov	r2, #1
    d4dc: e5832020     	str	r2, [r3, #0x20]
    d4e0: ea000017     	b	0xd544 <parse_options+0x414> @ imm = #0x5c
    d4e4: e59f30e4     	ldr	r3, [pc, #0xe4]         @ 0xd5d0 <parse_options+0x4a0>
    d4e8: e3a02001     	mov	r2, #1
    d4ec: e583232c     	str	r2, [r3, #0x32c]
    d4f0: ea000013     	b	0xd544 <parse_options+0x414> @ imm = #0x4c
    d4f4: e59f30e0     	ldr	r3, [pc, #0xe0]         @ 0xd5dc <parse_options+0x4ac>
    d4f8: e5933000     	ldr	r3, [r3]
    d4fc: e1a00003     	mov	r0, r3
    d500: e59f10d8     	ldr	r1, [pc, #0xd8]         @ 0xd5e0 <parse_options+0x4b0>
    d504: e51b2018     	ldr	r2, [r11, #-0x18]
    d508: ebfffc4d     	bl	0xc644 <fprintf@plt>    @ imm = #-0xecc
    d50c: e51b0018     	ldr	r0, [r11, #-0x18]
    d510: ebfffbc1     	bl	0xc41c <free@plt>       @ imm = #-0x10fc
    d514: e3a03000     	mov	r3, #0
    d518: ea000029     	b	0xd5c4 <parse_options+0x494> @ imm = #0xa4
    d51c: e59f30c0     	ldr	r3, [pc, #0xc0]         @ 0xd5e4 <parse_options+0x4b4>
    d520: e5933000     	ldr	r3, [r3]
    d524: e1a00003     	mov	r0, r3
    d528: e59f10b8     	ldr	r1, [pc, #0xb8]         @ 0xd5e8 <parse_options+0x4b8>
    d52c: e51b2018     	ldr	r2, [r11, #-0x18]
    d530: ebfffc43     	bl	0xc644 <fprintf@plt>    @ imm = #-0xef4
    d534: e51b0018     	ldr	r0, [r11, #-0x18]
    d538: ebfffbb7     	bl	0xc41c <free@plt>       @ imm = #-0x1124
    d53c: e3a03000     	mov	r3, #0
    d540: ea00001f     	b	0xd5c4 <parse_options+0x494> @ imm = #0x7c
    d544: e3a03000     	mov	r3, #0
    d548: e58d3000     	str	r3, [sp]
    d54c: e51b0020     	ldr	r0, [r11, #-0x20]
    d550: e51b1024     	ldr	r1, [r11, #-0x24]
    d554: e59f2090     	ldr	r2, [pc, #0x90]         @ 0xd5ec <parse_options+0x4bc>
    d558: e59f3090     	ldr	r3, [pc, #0x90]         @ 0xd5f0 <parse_options+0x4c0>
    d55c: ebfffbb7     	bl	0xc440 <getopt_long@plt> @ imm = #-0x1124
    d560: e1a03000     	mov	r3, r0
    d564: e50b301c     	str	r3, [r11, #-0x1c]
    d568: e51b301c     	ldr	r3, [r11, #-0x1c]
    d56c: e3530000     	cmp	r3, #0
    d570: aaffff0c     	bge	0xd1a8 <parse_options+0x78> @ imm = #-0x3d0
    d574: e59f3078     	ldr	r3, [pc, #0x78]         @ 0xd5f4 <parse_options+0x4c4>
    d578: e5932000     	ldr	r2, [r3]
    d57c: e51b3020     	ldr	r3, [r11, #-0x20]
    d580: e1520003     	cmp	r2, r3
    d584: aa00000d     	bge	0xd5c0 <parse_options+0x490> @ imm = #0x34
    d588: e59f3064     	ldr	r3, [pc, #0x64]         @ 0xd5f4 <parse_options+0x4c4>
    d58c: e5933000     	ldr	r3, [r3]
    d590: e1a02003     	mov	r2, r3
    d594: e1a02102     	lsl	r2, r2, #2
    d598: e51b1024     	ldr	r1, [r11, #-0x24]
    d59c: e0812002     	add	r2, r1, r2
    d5a0: e5922000     	ldr	r2, [r2]
    d5a4: e50b2008     	str	r2, [r11, #-0x8]
    d5a8: e2832001     	add	r2, r3, #1
    d5ac: e59f3040     	ldr	r3, [pc, #0x40]         @ 0xd5f4 <parse_options+0x4c4>
    d5b0: e5832000     	str	r2, [r3]
    d5b4: e59f003c     	ldr	r0, [pc, #0x3c]         @ 0xd5f8 <parse_options+0x4c8>
    d5b8: e51b1008     	ldr	r1, [r11, #-0x8]
    d5bc: ebfffbde     	bl	0xc53c <strcpy@plt>     @ imm = #-0x1088
    d5c0: e3a03001     	mov	r3, #1
    d5c4: e1a00003     	mov	r0, r3
    d5c8: e24bd004     	sub	sp, r11, #4
    d5cc: e8bd8800     	pop	{r11, pc}
    d5d0: 0c 6e 05 00  	.word	0x00056e0c
    d5d4: fc 6d 05 00  	.word	0x00056dfc
    d5d8: ac 19 03 00  	.word	0x000319ac
    d5dc: f4 6d 05 00  	.word	0x00056df4
    d5e0: fc 1f 03 00  	.word	0x00031ffc
    d5e4: f8 6d 05 00  	.word	0x00056df8
    d5e8: 14 24 03 00  	.word	0x00032414
    d5ec: 24 25 03 00  	.word	0x00032524
    d5f0: cc 25 03 00  	.word	0x000325cc
    d5f4: f0 6d 05 00  	.word	0x00056df0
    d5f8: 34 6e 05 00  	.word	0x00056e34

