0000c934 <client_thread>:
    c934: e92d4800     	push	{r11, lr}
    c938: e28db004     	add	r11, sp, #4
    c93c: e24dd0b0     	sub	sp, sp, #176
    c940: e50b0098     	str	r0, [r11, #-0x98]
    c944: e51b3098     	ldr	r3, [r11, #-0x98]
    c948: e50b303c     	str	r3, [r11, #-0x3c]
    c94c: e3a03000     	mov	r3, #0
    c950: e54b306d     	strb	r3, [r11, #-0x6d]
    c954: e59f0634     	ldr	r0, [pc, #0x634]        @ 0xcf90 <client_thread+0x65c>
    c958: ebffff42     	bl	0xc668 <malloc@plt>     @ imm = #-0x2f8
    c95c: e1a03000     	mov	r3, r0
    c960: e50b3038     	str	r3, [r11, #-0x38]
    c964: e24b307c     	sub	r3, r11, #124
    c968: e1a00003     	mov	r0, r3
    c96c: e51b103c     	ldr	r1, [r11, #-0x3c]
    c970: eb004fa2     	bl	0x20800 <pb_istream_from_socket> @ imm = #0x13e88
    c974: e3a03000     	mov	r3, #0
    c978: e50b3034     	str	r3, [r11, #-0x34]
    c97c: e3a03000     	mov	r3, #0
    c980: e50b3030     	str	r3, [r11, #-0x30]
    c984: e3a03000     	mov	r3, #0
    c988: e50b302c     	str	r3, [r11, #-0x2c]
    c98c: e3a03000     	mov	r3, #0
    c990: e50b3028     	str	r3, [r11, #-0x28]
    c994: e3a03000     	mov	r3, #0
    c998: e50b3024     	str	r3, [r11, #-0x24]
    c99c: e3a03000     	mov	r3, #0
    c9a0: e50b3020     	str	r3, [r11, #-0x20]
    c9a4: e3a03000     	mov	r3, #0
    c9a8: e50b301c     	str	r3, [r11, #-0x1c]
    c9ac: e3a03000     	mov	r3, #0
    c9b0: e50b3018     	str	r3, [r11, #-0x18]
    c9b4: e3a03000     	mov	r3, #0
    c9b8: e50b3014     	str	r3, [r11, #-0x14]
    c9bc: e3a03000     	mov	r3, #0
    c9c0: e50b3010     	str	r3, [r11, #-0x10]
    c9c4: e59f35c8     	ldr	r3, [pc, #0x5c8]        @ 0xcf94 <client_thread+0x660>
    c9c8: e3a02001     	mov	r2, #1
    c9cc: e5832000     	str	r2, [r3]
    c9d0: e59f05c0     	ldr	r0, [pc, #0x5c0]        @ 0xcf98 <client_thread+0x664>
    c9d4: ebffff23     	bl	0xc668 <malloc@plt>     @ imm = #-0x374
    c9d8: e1a03000     	mov	r3, r0
    c9dc: e50b3054     	str	r3, [r11, #-0x54]
    c9e0: ea000000     	b	0xc9e8 <client_thread+0xb4> @ imm = #0x0
    c9e4: e1a00000     	mov	r0, r0
    c9e8: e24b207c     	sub	r2, r11, #124
    c9ec: e24b3048     	sub	r3, r11, #72
    c9f0: e1a00002     	mov	r0, r2
    c9f4: e59f15a0     	ldr	r1, [pc, #0x5a0]        @ 0xcf9c <client_thread+0x668>
    c9f8: e1a02003     	mov	r2, r3
    c9fc: eb000af4     	bl	0xf5d4 <pb_decode>      @ imm = #0x2bd0
    ca00: e1a03000     	mov	r3, r0
    ca04: e2233001     	eor	r3, r3, #1
    ca08: e6ef3073     	uxtb	r3, r3
    ca0c: e3530000     	cmp	r3, #0
    ca10: 1a000141     	bne	0xcf1c <client_thread+0x5e8> @ imm = #0x504
    ca14: e3a03000     	mov	r3, #0
    ca18: e54b305c     	strb	r3, [r11, #-0x5c]
    ca1c: e3a03000     	mov	r3, #0
    ca20: e50b3058     	str	r3, [r11, #-0x58]
    ca24: e3e02000     	mvn	r2, #0
    ca28: e3e03000     	mvn	r3, #0
    ca2c: e14b26f4     	strd	r2, r3, [r11, #-100]
    ca30: e51b3048     	ldr	r3, [r11, #-0x48]
    ca34: e2433001     	sub	r3, r3, #1
    ca38: e3530003     	cmp	r3, #3
    ca3c: 979ff103     	ldrls	pc, [pc, r3, lsl #2]
    ca40: ea0000fe     	b	0xce40 <client_thread+0x50c> @ imm = #0x3f8
    ca44: 38 cc 00 00  	.word	0x0000cc38
    ca48: a4 cd 00 00  	.word	0x0000cda4
    ca4c: 54 ca 00 00  	.word	0x0000ca54
    ca50: f4 cd 00 00  	.word	0x0000cdf4
    ca54: e3a03003     	mov	r3, #3
    ca58: e50b306c     	str	r3, [r11, #-0x6c]
    ca5c: e51b3030     	ldr	r3, [r11, #-0x30]
    ca60: e3530000     	cmp	r3, #0
    ca64: 0a0000ee     	beq	0xce24 <client_thread+0x4f0> @ imm = #0x3b8
    ca68: e51b3034     	ldr	r3, [r11, #-0x34]
    ca6c: e3530000     	cmp	r3, #0
    ca70: 0a0000ed     	beq	0xce2c <client_thread+0x4f8> @ imm = #0x3b4
    ca74: e3a03000     	mov	r3, #0
    ca78: e50b300c     	str	r3, [r11, #-0xc]
    ca7c: e51b2044     	ldr	r2, [r11, #-0x44]
    ca80: e51b3040     	ldr	r3, [r11, #-0x40]
    ca84: e0823003     	add	r3, r2, r3
    ca88: e50b3010     	str	r3, [r11, #-0x10]
    ca8c: e51b2044     	ldr	r2, [r11, #-0x44]
    ca90: e51b3024     	ldr	r3, [r11, #-0x24]
    ca94: e1520003     	cmp	r2, r3
    ca98: 2a000008     	bhs	0xcac0 <client_thread+0x18c> @ imm = #0x20
    ca9c: e51b3044     	ldr	r3, [r11, #-0x44]
    caa0: e51b2024     	ldr	r2, [r11, #-0x24]
    caa4: e0633002     	rsb	r3, r3, r2
    caa8: e3530080     	cmp	r3, #128
    caac: 23a03080     	movhs	r3, #128
    cab0: e50b3014     	str	r3, [r11, #-0x14]
    cab4: e3a03000     	mov	r3, #0
    cab8: e50b300c     	str	r3, [r11, #-0xc]
    cabc: ea000033     	b	0xcb90 <client_thread+0x25c> @ imm = #0xcc
    cac0: e51b2044     	ldr	r2, [r11, #-0x44]
    cac4: e51b3024     	ldr	r3, [r11, #-0x24]
    cac8: e1520003     	cmp	r2, r3
    cacc: 3a00000d     	blo	0xcb08 <client_thread+0x1d4> @ imm = #0x34
    cad0: e51b2044     	ldr	r2, [r11, #-0x44]
    cad4: e51b301c     	ldr	r3, [r11, #-0x1c]
    cad8: e1520003     	cmp	r2, r3
    cadc: 8a000009     	bhi	0xcb08 <client_thread+0x1d4> @ imm = #0x24
    cae0: e51b3044     	ldr	r3, [r11, #-0x44]
    cae4: e51b201c     	ldr	r2, [r11, #-0x1c]
    cae8: e0633002     	rsb	r3, r3, r2
    caec: e2833001     	add	r3, r3, #1
    caf0: e3530080     	cmp	r3, #128
    caf4: 23a03080     	movhs	r3, #128
    caf8: e50b3014     	str	r3, [r11, #-0x14]
    cafc: e3a03001     	mov	r3, #1
    cb00: e50b300c     	str	r3, [r11, #-0xc]
    cb04: ea000021     	b	0xcb90 <client_thread+0x25c> @ imm = #0x84
    cb08: e51b2044     	ldr	r2, [r11, #-0x44]
    cb0c: e51b301c     	ldr	r3, [r11, #-0x1c]
    cb10: e1520003     	cmp	r2, r3
    cb14: 9a00000c     	bls	0xcb4c <client_thread+0x218> @ imm = #0x30
    cb18: e51b2044     	ldr	r2, [r11, #-0x44]
    cb1c: e51b3020     	ldr	r3, [r11, #-0x20]
    cb20: e1520003     	cmp	r2, r3
    cb24: 2a000008     	bhs	0xcb4c <client_thread+0x218> @ imm = #0x20
    cb28: e51b3044     	ldr	r3, [r11, #-0x44]
    cb2c: e51b2020     	ldr	r2, [r11, #-0x20]
    cb30: e0633002     	rsb	r3, r3, r2
    cb34: e3530080     	cmp	r3, #128
    cb38: 23a03080     	movhs	r3, #128
    cb3c: e50b3014     	str	r3, [r11, #-0x14]
    cb40: e3a03000     	mov	r3, #0
    cb44: e50b300c     	str	r3, [r11, #-0xc]
    cb48: ea000010     	b	0xcb90 <client_thread+0x25c> @ imm = #0x40
    cb4c: e51b2044     	ldr	r2, [r11, #-0x44]
    cb50: e51b3020     	ldr	r3, [r11, #-0x20]
    cb54: e1520003     	cmp	r2, r3
    cb58: 3a00000c     	blo	0xcb90 <client_thread+0x25c> @ imm = #0x30
    cb5c: e51b2044     	ldr	r2, [r11, #-0x44]
    cb60: e51b3018     	ldr	r3, [r11, #-0x18]
    cb64: e1520003     	cmp	r2, r3
    cb68: 8a000008     	bhi	0xcb90 <client_thread+0x25c> @ imm = #0x20
    cb6c: e51b3044     	ldr	r3, [r11, #-0x44]
    cb70: e51b2018     	ldr	r2, [r11, #-0x18]
    cb74: e0633002     	rsb	r3, r3, r2
    cb78: e2833001     	add	r3, r3, #1
    cb7c: e3530080     	cmp	r3, #128
    cb80: 23a03080     	movhs	r3, #128
    cb84: e50b3014     	str	r3, [r11, #-0x14]
    cb88: e3a03001     	mov	r3, #1
    cb8c: e50b300c     	str	r3, [r11, #-0xc]
    cb90: e51b3044     	ldr	r3, [r11, #-0x44]
    cb94: e51b2010     	ldr	r2, [r11, #-0x10]
    cb98: e0633002     	rsb	r3, r3, r2
    cb9c: e51b2014     	ldr	r2, [r11, #-0x14]
    cba0: e1520003     	cmp	r2, r3
    cba4: 31a03002     	movlo	r3, r2
    cba8: e50b3014     	str	r3, [r11, #-0x14]
    cbac: e51b2044     	ldr	r2, [r11, #-0x44]
    cbb0: e51b3054     	ldr	r3, [r11, #-0x54]
    cbb4: e51b0034     	ldr	r0, [r11, #-0x34]
    cbb8: e1a01002     	mov	r1, r2
    cbbc: e51b2014     	ldr	r2, [r11, #-0x14]
    cbc0: eb0087f7     	bl	0x2eba4 <sacd_read_block_raw64> @ imm = #0x21fdc
    cbc4: e1a03000     	mov	r3, r0
    cbc8: e1a02003     	mov	r2, r3
    cbcc: e1a03fc2     	asr	r3, r2, #31
    cbd0: e14b26f4     	strd	r2, r3, [r11, #-100]
    cbd4: e14b26d4     	ldrd	r2, r3, [r11, #-100]
    cbd8: e3a01000     	mov	r1, #0
    cbdc: e3530000     	cmp	r3, #0
    cbe0: ca000005     	bgt	0xcbfc <client_thread+0x2c8> @ imm = #0x14
    cbe4: e3530000     	cmp	r3, #0
    cbe8: 1a000005     	bne	0xcc04 <client_thread+0x2d0> @ imm = #0x14
    cbec: e3520000     	cmp	r2, #0
    cbf0: 1a000001     	bne	0xcbfc <client_thread+0x2c8> @ imm = #0x4
    cbf4: e3520000     	cmp	r2, #0
    cbf8: ea000001     	b	0xcc04 <client_thread+0x2d0> @ imm = #0x4
    cbfc: e3a03001     	mov	r3, #1
    cc00: e1a01003     	mov	r1, r3
    cc04: e6ef3071     	uxtb	r3, r1
    cc08: e54b305c     	strb	r3, [r11, #-0x5c]
    cc0c: e14b26d4     	ldrd	r2, r3, [r11, #-100]
    cc10: e1a03002     	mov	r3, r2
    cc14: e1a03583     	lsl	r3, r3, #11
    cc18: e50b3058     	str	r3, [r11, #-0x58]
    cc1c: e51b2054     	ldr	r2, [r11, #-0x54]
    cc20: e51b3014     	ldr	r3, [r11, #-0x14]
    cc24: e51b0034     	ldr	r0, [r11, #-0x34]
    cc28: e1a01002     	mov	r1, r2
    cc2c: e1a02003     	mov	r2, r3
    cc30: eb008818     	bl	0x2ec98 <sacd_decrypt>  @ imm = #0x22060
    cc34: ea000081     	b	0xce40 <client_thread+0x50c> @ imm = #0x204
    cc38: e3a03001     	mov	r3, #1
    cc3c: e50b306c     	str	r3, [r11, #-0x6c]
    cc40: e59f0358     	ldr	r0, [pc, #0x358]        @ 0xcfa0 <client_thread+0x66c>
    cc44: eb00868a     	bl	0x2e674 <sacd_open>     @ imm = #0x21a28
    cc48: e1a03000     	mov	r3, r0
    cc4c: e50b3034     	str	r3, [r11, #-0x34]
    cc50: e51b3034     	ldr	r3, [r11, #-0x34]
    cc54: e3530000     	cmp	r3, #0
    cc58: 0a000075     	beq	0xce34 <client_thread+0x500> @ imm = #0x1d4
    cc5c: e51b0034     	ldr	r0, [r11, #-0x34]
    cc60: e3a01000     	mov	r1, #0
    cc64: eb0072d4     	bl	0x297bc <scarletbook_open> @ imm = #0x1cb50
    cc68: e1a03000     	mov	r3, r0
    cc6c: e50b3030     	str	r3, [r11, #-0x30]
    cc70: e3a03000     	mov	r3, #0
    cc74: e50b3028     	str	r3, [r11, #-0x28]
    cc78: e3a03000     	mov	r3, #0
    cc7c: e50b302c     	str	r3, [r11, #-0x2c]
    cc80: e51b3030     	ldr	r3, [r11, #-0x30]
    cc84: e3530000     	cmp	r3, #0
    cc88: 0a00006b     	beq	0xce3c <client_thread+0x508> @ imm = #0x1ac
    cc8c: e51b3030     	ldr	r3, [r11, #-0x30]
    cc90: e5933060     	ldr	r3, [r3, #0x60]
    cc94: e3530000     	cmp	r3, #0
    cc98: 0a000019     	beq	0xcd04 <client_thread+0x3d0> @ imm = #0x64
    cc9c: e51b3030     	ldr	r3, [r11, #-0x30]
    cca0: e5933060     	ldr	r3, [r3, #0x60]
    cca4: e5d32048     	ldrb	r2, [r3, #0x48]
    cca8: e5d31049     	ldrb	r1, [r3, #0x49]
    ccac: e1a01401     	lsl	r1, r1, #8
    ccb0: e1812002     	orr	r2, r1, r2
    ccb4: e5d3104a     	ldrb	r1, [r3, #0x4a]
    ccb8: e1a01801     	lsl	r1, r1, #16
    ccbc: e1812002     	orr	r2, r1, r2
    ccc0: e5d3304b     	ldrb	r3, [r3, #0x4b]
    ccc4: e1a03c03     	lsl	r3, r3, #24
    ccc8: e1833002     	orr	r3, r3, r2
    cccc: e50b3024     	str	r3, [r11, #-0x24]
    ccd0: e51b3030     	ldr	r3, [r11, #-0x30]
    ccd4: e5933060     	ldr	r3, [r3, #0x60]
    ccd8: e5d3204c     	ldrb	r2, [r3, #0x4c]
    ccdc: e5d3104d     	ldrb	r1, [r3, #0x4d]
    cce0: e1a01401     	lsl	r1, r1, #8
    cce4: e1812002     	orr	r2, r1, r2
    cce8: e5d3104e     	ldrb	r1, [r3, #0x4e]
    ccec: e1a01801     	lsl	r1, r1, #16
    ccf0: e1812002     	orr	r2, r1, r2
    ccf4: e5d3304f     	ldrb	r3, [r3, #0x4f]
    ccf8: e1a03c03     	lsl	r3, r3, #24
    ccfc: e1833002     	orr	r3, r3, r2
    cd00: e50b301c     	str	r3, [r11, #-0x1c]
    cd04: e51b2030     	ldr	r2, [r11, #-0x30]
    cd08: e59f3294     	ldr	r3, [pc, #0x294]        @ 0xcfa4 <client_thread+0x670>
    cd0c: e7923003     	ldr	r3, [r2, r3]
    cd10: e3530000     	cmp	r3, #0
    cd14: 0a00001b     	beq	0xcd88 <client_thread+0x454> @ imm = #0x6c
    cd18: e51b2030     	ldr	r2, [r11, #-0x30]
    cd1c: e59f3280     	ldr	r3, [pc, #0x280]        @ 0xcfa4 <client_thread+0x670>
    cd20: e7923003     	ldr	r3, [r2, r3]
    cd24: e5d32048     	ldrb	r2, [r3, #0x48]
    cd28: e5d31049     	ldrb	r1, [r3, #0x49]
    cd2c: e1a01401     	lsl	r1, r1, #8
    cd30: e1812002     	orr	r2, r1, r2
    cd34: e5d3104a     	ldrb	r1, [r3, #0x4a]
    cd38: e1a01801     	lsl	r1, r1, #16
    cd3c: e1812002     	orr	r2, r1, r2
    cd40: e5d3304b     	ldrb	r3, [r3, #0x4b]
    cd44: e1a03c03     	lsl	r3, r3, #24
    cd48: e1833002     	orr	r3, r3, r2
    cd4c: e50b3020     	str	r3, [r11, #-0x20]
    cd50: e51b2030     	ldr	r2, [r11, #-0x30]
    cd54: e59f3248     	ldr	r3, [pc, #0x248]        @ 0xcfa4 <client_thread+0x670>
    cd58: e7923003     	ldr	r3, [r2, r3]
    cd5c: e5d3204c     	ldrb	r2, [r3, #0x4c]
    cd60: e5d3104d     	ldrb	r1, [r3, #0x4d]
    cd64: e1a01401     	lsl	r1, r1, #8
    cd68: e1812002     	orr	r2, r1, r2
    cd6c: e5d3104e     	ldrb	r1, [r3, #0x4e]
    cd70: e1a01801     	lsl	r1, r1, #16
    cd74: e1812002     	orr	r2, r1, r2
    cd78: e5d3304f     	ldrb	r3, [r3, #0x4f]
    cd7c: e1a03c03     	lsl	r3, r3, #24
    cd80: e1833002     	orr	r3, r3, r2
    cd84: e50b3018     	str	r3, [r11, #-0x18]
    cd88: e51b0034     	ldr	r0, [r11, #-0x34]
    cd8c: eb0087ac     	bl	0x2ec44 <sacd_authenticate> @ imm = #0x21eb0
    cd90: e1a03000     	mov	r3, r0
    cd94: e1a02003     	mov	r2, r3
    cd98: e1a03fc2     	asr	r3, r2, #31
    cd9c: e14b26f4     	strd	r2, r3, [r11, #-100]
    cda0: ea000026     	b	0xce40 <client_thread+0x50c> @ imm = #0x98
    cda4: e3a03002     	mov	r3, #2
    cda8: e50b306c     	str	r3, [r11, #-0x6c]
    cdac: e51b3030     	ldr	r3, [r11, #-0x30]
    cdb0: e3530000     	cmp	r3, #0
    cdb4: 0a000003     	beq	0xcdc8 <client_thread+0x494> @ imm = #0xc
    cdb8: e51b0030     	ldr	r0, [r11, #-0x30]
    cdbc: eb007471     	bl	0x29f88 <scarletbook_close> @ imm = #0x1d1c4
    cdc0: e3a03000     	mov	r3, #0
    cdc4: e50b3030     	str	r3, [r11, #-0x30]
    cdc8: e51b3034     	ldr	r3, [r11, #-0x34]
    cdcc: e3530000     	cmp	r3, #0
    cdd0: 0a000003     	beq	0xcde4 <client_thread+0x4b0> @ imm = #0xc
    cdd4: e51b0034     	ldr	r0, [r11, #-0x34]
    cdd8: eb008733     	bl	0x2eaac <sacd_close>    @ imm = #0x21ccc
    cddc: e3a03000     	mov	r3, #0
    cde0: e50b3034     	str	r3, [r11, #-0x34]
    cde4: e3a02000     	mov	r2, #0
    cde8: e3a03000     	mov	r3, #0
    cdec: e14b26f4     	strd	r2, r3, [r11, #-100]
    cdf0: ea000012     	b	0xce40 <client_thread+0x50c> @ imm = #0x48
    cdf4: e3a03004     	mov	r3, #4
    cdf8: e50b306c     	str	r3, [r11, #-0x6c]
    cdfc: e51b3034     	ldr	r3, [r11, #-0x34]
    ce00: e3530000     	cmp	r3, #0
    ce04: 0a00000d     	beq	0xce40 <client_thread+0x50c> @ imm = #0x34
    ce08: e51b0034     	ldr	r0, [r11, #-0x34]
    ce0c: eb0087ba     	bl	0x2ecfc <sacd_get_total_sectors> @ imm = #0x21ee8
    ce10: e1a03000     	mov	r3, r0
    ce14: e1a02003     	mov	r2, r3
    ce18: e3a03000     	mov	r3, #0
    ce1c: e14b26f4     	strd	r2, r3, [r11, #-100]
    ce20: ea000006     	b	0xce40 <client_thread+0x50c> @ imm = #0x18
    ce24: e1a00000     	mov	r0, r0
    ce28: ea000004     	b	0xce40 <client_thread+0x50c> @ imm = #0x10
    ce2c: e1a00000     	mov	r0, r0
    ce30: ea000002     	b	0xce40 <client_thread+0x50c> @ imm = #0x8
    ce34: e1a00000     	mov	r0, r0
    ce38: ea000000     	b	0xce40 <client_thread+0x50c> @ imm = #0x0
    ce3c: e1a00000     	mov	r0, r0
    ce40: e24b30ac     	sub	r3, r11, #172
    ce44: e1a00003     	mov	r0, r3
    ce48: e51b1038     	ldr	r1, [r11, #-0x38]
    ce4c: e59f213c     	ldr	r2, [pc, #0x13c]        @ 0xcf90 <client_thread+0x65c>
    ce50: eb0011f9     	bl	0x1163c <pb_ostream_from_buffer> @ imm = #0x47e4
    ce54: e24bc08c     	sub	r12, r11, #140
    ce58: e24b30ac     	sub	r3, r11, #172
    ce5c: e893000f     	ldm	r3, {r0, r1, r2, r3}
    ce60: e88c000f     	stm	r12, {r0, r1, r2, r3}
    ce64: e24b208c     	sub	r2, r11, #140
    ce68: e24b306c     	sub	r3, r11, #108
    ce6c: e1a00002     	mov	r0, r2
    ce70: e59f1130     	ldr	r1, [pc, #0x130]        @ 0xcfa8 <client_thread+0x674>
    ce74: e1a02003     	mov	r2, r3
    ce78: eb001303     	bl	0x11a8c <pb_encode>     @ imm = #0x4c0c
    ce7c: e1a03000     	mov	r3, r0
    ce80: e2233001     	eor	r3, r3, #1
    ce84: e6ef3073     	uxtb	r3, r3
    ce88: e3530000     	cmp	r3, #0
    ce8c: 1a000024     	bne	0xcf24 <client_thread+0x5f0> @ imm = #0x90
    ce90: e24b208c     	sub	r2, r11, #140
    ce94: e24b306d     	sub	r3, r11, #109
    ce98: e1a00002     	mov	r0, r2
    ce9c: e1a01003     	mov	r1, r3
    cea0: e3a02001     	mov	r2, #1
    cea4: eb0011fb     	bl	0x11698 <pb_write>      @ imm = #0x47ec
    cea8: e51b2080     	ldr	r2, [r11, #-0x80]
    ceac: e24b3090     	sub	r3, r11, #144
    ceb0: e3a01000     	mov	r1, #0
    ceb4: e58d1000     	str	r1, [sp]
    ceb8: e3a01000     	mov	r1, #0
    cebc: e58d1004     	str	r1, [sp, #0x4]
    cec0: e51b003c     	ldr	r0, [r11, #-0x3c]
    cec4: e51b1038     	ldr	r1, [r11, #-0x38]
    cec8: eb0017f8     	bl	0x12eb0 <socket_send>   @ imm = #0x5fe0
    cecc: e1a03000     	mov	r3, r0
    ced0: e3530000     	cmp	r3, #0
    ced4: 1a000005     	bne	0xcef0 <client_thread+0x5bc> @ imm = #0x14
    ced8: e51b2080     	ldr	r2, [r11, #-0x80]
    cedc: e51b3090     	ldr	r3, [r11, #-0x90]
    cee0: e1520003     	cmp	r2, r3
    cee4: 1a000001     	bne	0xcef0 <client_thread+0x5bc> @ imm = #0x4
    cee8: e3a03001     	mov	r3, #1
    ceec: ea000000     	b	0xcef4 <client_thread+0x5c0> @ imm = #0x0
    cef0: e3a03000     	mov	r3, #0
    cef4: e54b3005     	strb	r3, [r11, #-0x5]
    cef8: e55b3005     	ldrb	r3, [r11, #-0x5]
    cefc: e2233001     	eor	r3, r3, #1
    cf00: e6ef3073     	uxtb	r3, r3
    cf04: e3530000     	cmp	r3, #0
    cf08: 1a000007     	bne	0xcf2c <client_thread+0x5f8> @ imm = #0x1c
    cf0c: e51b3048     	ldr	r3, [r11, #-0x48]
    cf10: e3530002     	cmp	r3, #2
    cf14: 1afffeb2     	bne	0xc9e4 <client_thread+0xb0> @ imm = #-0x538
    cf18: ea000004     	b	0xcf30 <client_thread+0x5fc> @ imm = #0x10
    cf1c: e1a00000     	mov	r0, r0
    cf20: ea000002     	b	0xcf30 <client_thread+0x5fc> @ imm = #0x8
    cf24: e1a00000     	mov	r0, r0
    cf28: ea000000     	b	0xcf30 <client_thread+0x5fc> @ imm = #0x0
    cf2c: e1a00000     	mov	r0, r0
    cf30: e51b3030     	ldr	r3, [r11, #-0x30]
    cf34: e3530000     	cmp	r3, #0
    cf38: 0a000001     	beq	0xcf44 <client_thread+0x610> @ imm = #0x4
    cf3c: e51b0030     	ldr	r0, [r11, #-0x30]
    cf40: eb007410     	bl	0x29f88 <scarletbook_close> @ imm = #0x1d040
    cf44: e51b3034     	ldr	r3, [r11, #-0x34]
    cf48: e3530000     	cmp	r3, #0
    cf4c: 0a000001     	beq	0xcf58 <client_thread+0x624> @ imm = #0x4
    cf50: e51b0034     	ldr	r0, [r11, #-0x34]
    cf54: eb0086d4     	bl	0x2eaac <sacd_close>    @ imm = #0x21b50
    cf58: e51b3054     	ldr	r3, [r11, #-0x54]
    cf5c: e1a00003     	mov	r0, r3
    cf60: ebfffd2d     	bl	0xc41c <free@plt>       @ imm = #-0xb4c
    cf64: e51b0038     	ldr	r0, [r11, #-0x38]
    cf68: ebfffd2b     	bl	0xc41c <free@plt>       @ imm = #-0xb54
    cf6c: e51b303c     	ldr	r3, [r11, #-0x3c]
    cf70: e5933000     	ldr	r3, [r3]
    cf74: e1a00003     	mov	r0, r3
    cf78: ebfffd99     	bl	0xc5e4 <close@plt>      @ imm = #-0x99c
    cf7c: e59f3010     	ldr	r3, [pc, #0x10]         @ 0xcf94 <client_thread+0x660>
    cf80: e3a02000     	mov	r2, #0
    cf84: e5832000     	str	r2, [r3]
    cf88: e3a00000     	mov	r0, #0
    cf8c: ebfffcbf     	bl	0xc290 <pthread_exit@plt> @ imm = #-0xd04
    cf90: 00 04 04 00  	.word	0x00040400
    cf94: 04 6e 05 00  	.word	0x00056e04
    cf98: 00 08 04 00  	.word	0x00040800
    cf9c: 90 52 03 00  	.word	0x00035290
    cfa0: a0 19 03 00  	.word	0x000319a0
    cfa4: 50 38 00 00  	.word	0x00003850
    cfa8: c4 52 03 00  	.word	0x000352c4

