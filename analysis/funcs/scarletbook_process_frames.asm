0002defc <scarletbook_process_frames>:
   2defc: e92d4810     	push	{r4, r11, lr}
   2df00: e28db008     	add	r11, sp, #8
   2df04: e24dd024     	sub	sp, sp, #36
   2df08: e50b0020     	str	r0, [r11, #-0x20]
   2df0c: e50b1024     	str	r1, [r11, #-0x24]
   2df10: e50b2028     	str	r2, [r11, #-0x28]
   2df14: e50b302c     	str	r3, [r11, #-0x2c]
   2df18: ea00016c     	b	0x2e4d0 <scarletbook_process_frames+0x5d4> @ imm = #0x5b0
   2df1c: e51b3024     	ldr	r3, [r11, #-0x24]
   2df20: e50b3014     	str	r3, [r11, #-0x14]
   2df24: e51b2020     	ldr	r2, [r11, #-0x20]
   2df28: e59f35ec     	ldr	r3, [pc, #0x5ec]        @ 0x2e51c <scarletbook_process_frames+0x620>
   2df2c: e7922003     	ldr	r2, [r2, r3]
   2df30: e51b1020     	ldr	r1, [r11, #-0x20]
   2df34: e59f35e4     	ldr	r3, [pc, #0x5e4]        @ 0x2e520 <scarletbook_process_frames+0x624>
   2df38: e7d13003     	ldrb	r3, [r1, r3]
   2df3c: e1a032a3     	lsr	r3, r3, #5
   2df40: e6ef3073     	uxtb	r3, r3
   2df44: e1520003     	cmp	r2, r3
   2df48: 1a0000ac     	bne	0x2e200 <scarletbook_process_frames+0x304> @ imm = #0x2b0
   2df4c: e51b2020     	ldr	r2, [r11, #-0x20]
   2df50: e59f35c4     	ldr	r3, [pc, #0x5c4]        @ 0x2e51c <scarletbook_process_frames+0x620>
   2df54: e3a01000     	mov	r1, #0
   2df58: e7821003     	str	r1, [r2, r3]
   2df5c: e51b3020     	ldr	r3, [r11, #-0x20]
   2df60: e2833a07     	add	r3, r3, #28672
   2df64: e2833054     	add	r3, r3, #84
   2df68: e1a00003     	mov	r0, r3
   2df6c: e51b1014     	ldr	r1, [r11, #-0x14]
   2df70: e3a02001     	mov	r2, #1
   2df74: ebff7964     	bl	0xc50c <memcpy@plt>     @ imm = #-0x21a70
   2df78: e51b3014     	ldr	r3, [r11, #-0x14]
   2df7c: e2833001     	add	r3, r3, #1
   2df80: e50b3014     	str	r3, [r11, #-0x14]
   2df84: e3a03000     	mov	r3, #0
   2df88: e50b301c     	str	r3, [r11, #-0x1c]
   2df8c: ea000057     	b	0x2e0f0 <scarletbook_process_frames+0x1f4> @ imm = #0x15c
   2df90: e51b301c     	ldr	r3, [r11, #-0x1c]
   2df94: e51b2014     	ldr	r2, [r11, #-0x14]
   2df98: e5d22000     	ldrb	r2, [r2]
   2df9c: e1a023a2     	lsr	r2, r2, #7
   2dfa0: e6ef2072     	uxtb	r2, r2
   2dfa4: e2022001     	and	r2, r2, #1
   2dfa8: e6ef1072     	uxtb	r1, r2
   2dfac: e51b0020     	ldr	r0, [r11, #-0x20]
   2dfb0: e2833b0e     	add	r3, r3, #14336
   2dfb4: e2833028     	add	r3, r3, #40
   2dfb8: e3a02005     	mov	r2, #5
   2dfbc: e1a03083     	lsl	r3, r3, #1
   2dfc0: e0803003     	add	r3, r0, r3
   2dfc4: e0832002     	add	r2, r3, r2
   2dfc8: e5d23000     	ldrb	r3, [r2]
   2dfcc: e2011001     	and	r1, r1, #1
   2dfd0: e3c33001     	bic	r3, r3, #1
   2dfd4: e1813003     	orr	r3, r1, r3
   2dfd8: e5c23000     	strb	r3, [r2]
   2dfdc: e51b301c     	ldr	r3, [r11, #-0x1c]
   2dfe0: e51b2014     	ldr	r2, [r11, #-0x14]
   2dfe4: e5d22000     	ldrb	r2, [r2]
   2dfe8: e1a021a2     	lsr	r2, r2, #3
   2dfec: e6ef2072     	uxtb	r2, r2
   2dff0: e2022007     	and	r2, r2, #7
   2dff4: e6ef2072     	uxtb	r2, r2
   2dff8: e2022007     	and	r2, r2, #7
   2dffc: e2022007     	and	r2, r2, #7
   2e000: e6ef2072     	uxtb	r2, r2
   2e004: e51b0020     	ldr	r0, [r11, #-0x20]
   2e008: e2833b0e     	add	r3, r3, #14336
   2e00c: e2833028     	add	r3, r3, #40
   2e010: e3a01005     	mov	r1, #5
   2e014: e1a03083     	lsl	r3, r3, #1
   2e018: e0803003     	add	r3, r0, r3
   2e01c: e0831001     	add	r1, r3, r1
   2e020: e5d13000     	ldrb	r3, [r1]
   2e024: e2022007     	and	r2, r2, #7
   2e028: e3c3301c     	bic	r3, r3, #28
   2e02c: e1a02102     	lsl	r2, r2, #2
   2e030: e1823003     	orr	r3, r2, r3
   2e034: e5c13000     	strb	r3, [r1]
   2e038: e51b001c     	ldr	r0, [r11, #-0x1c]
   2e03c: e51b3014     	ldr	r3, [r11, #-0x14]
   2e040: e5d33000     	ldrb	r3, [r3]
   2e044: e2033007     	and	r3, r3, #7
   2e048: e1a03403     	lsl	r3, r3, #8
   2e04c: e6ff2073     	uxth	r2, r3
   2e050: e51b3014     	ldr	r3, [r11, #-0x14]
   2e054: e2833001     	add	r3, r3, #1
   2e058: e5d33000     	ldrb	r3, [r3]
   2e05c: e1823003     	orr	r3, r2, r3
   2e060: e6ff3073     	uxth	r3, r3
   2e064: e6ff3073     	uxth	r3, r3
   2e068: e1a03a83     	lsl	r3, r3, #21
   2e06c: e1a03aa3     	lsr	r3, r3, #21
   2e070: e6ff1073     	uxth	r1, r3
   2e074: e51b2020     	ldr	r2, [r11, #-0x20]
   2e078: e2803b0e     	add	r3, r0, #14336
   2e07c: e2833028     	add	r3, r3, #40
   2e080: e201c007     	and	r12, r1, #7
   2e084: e3a00005     	mov	r0, #5
   2e088: e1a04083     	lsl	r4, r3, #1
   2e08c: e0824004     	add	r4, r2, r4
   2e090: e0840000     	add	r0, r4, r0
   2e094: e1a0c28c     	lsl	r12, r12, #5
   2e098: e5d04000     	ldrb	r4, [r0]
   2e09c: e204401f     	and	r4, r4, #31
   2e0a0: e184c00c     	orr	r12, r4, r12
   2e0a4: e5c0c000     	strb	r12, [r0]
   2e0a8: e1a011a1     	lsr	r1, r1, #3
   2e0ac: e6ff1071     	uxth	r1, r1
   2e0b0: e20100ff     	and	r0, r1, #255
   2e0b4: e3a01006     	mov	r1, #6
   2e0b8: e1a03083     	lsl	r3, r3, #1
   2e0bc: e0823003     	add	r3, r2, r3
   2e0c0: e0833001     	add	r3, r3, r1
   2e0c4: e3a02000     	mov	r2, #0
   2e0c8: e1a01002     	mov	r1, r2
   2e0cc: e1a02000     	mov	r2, r0
   2e0d0: e1812002     	orr	r2, r1, r2
   2e0d4: e5c32000     	strb	r2, [r3]
   2e0d8: e51b3014     	ldr	r3, [r11, #-0x14]
   2e0dc: e2833002     	add	r3, r3, #2
   2e0e0: e50b3014     	str	r3, [r11, #-0x14]
   2e0e4: e51b301c     	ldr	r3, [r11, #-0x1c]
   2e0e8: e2833001     	add	r3, r3, #1
   2e0ec: e50b301c     	str	r3, [r11, #-0x1c]
   2e0f0: e51b2020     	ldr	r2, [r11, #-0x20]
   2e0f4: e59f3424     	ldr	r3, [pc, #0x424]        @ 0x2e520 <scarletbook_process_frames+0x624>
   2e0f8: e7d23003     	ldrb	r3, [r2, r3]
   2e0fc: e1a032a3     	lsr	r3, r3, #5
   2e100: e6ef3073     	uxtb	r3, r3
   2e104: e1a02003     	mov	r2, r3
   2e108: e51b301c     	ldr	r3, [r11, #-0x1c]
   2e10c: e1520003     	cmp	r2, r3
   2e110: caffff9e     	bgt	0x2df90 <scarletbook_process_frames+0x94> @ imm = #-0x188
   2e114: e51b2020     	ldr	r2, [r11, #-0x20]
   2e118: e59f3400     	ldr	r3, [pc, #0x400]        @ 0x2e520 <scarletbook_process_frames+0x624>
   2e11c: e7d23003     	ldrb	r3, [r2, r3]
   2e120: e2033001     	and	r3, r3, #1
   2e124: e3530000     	cmp	r3, #0
   2e128: 0a000017     	beq	0x2e18c <scarletbook_process_frames+0x290> @ imm = #0x5c
   2e12c: e51b3020     	ldr	r3, [r11, #-0x20]
   2e130: e2833a07     	add	r3, r3, #28672
   2e134: e2833063     	add	r3, r3, #99
   2e138: e51b1020     	ldr	r1, [r11, #-0x20]
   2e13c: e59f23dc     	ldr	r2, [pc, #0x3dc]        @ 0x2e520 <scarletbook_process_frames+0x624>
   2e140: e7d12002     	ldrb	r2, [r1, r2]
   2e144: e1a02122     	lsr	r2, r2, #2
   2e148: e2022007     	and	r2, r2, #7
   2e14c: e6ef2072     	uxtb	r2, r2
   2e150: e1a02102     	lsl	r2, r2, #2
   2e154: e1a00003     	mov	r0, r3
   2e158: e51b1014     	ldr	r1, [r11, #-0x14]
   2e15c: ebff78ea     	bl	0xc50c <memcpy@plt>     @ imm = #-0x21c58
   2e160: e51b2020     	ldr	r2, [r11, #-0x20]
   2e164: e59f33b4     	ldr	r3, [pc, #0x3b4]        @ 0x2e520 <scarletbook_process_frames+0x624>
   2e168: e7d23003     	ldrb	r3, [r2, r3]
   2e16c: e1a03123     	lsr	r3, r3, #2
   2e170: e2033007     	and	r3, r3, #7
   2e174: e6ef3073     	uxtb	r3, r3
   2e178: e1a03103     	lsl	r3, r3, #2
   2e17c: e51b2014     	ldr	r2, [r11, #-0x14]
   2e180: e0823003     	add	r3, r2, r3
   2e184: e50b3014     	str	r3, [r11, #-0x14]
   2e188: ea00001c     	b	0x2e200 <scarletbook_process_frames+0x304> @ imm = #0x70
   2e18c: e3a03000     	mov	r3, #0
   2e190: e50b301c     	str	r3, [r11, #-0x1c]
   2e194: ea00000f     	b	0x2e1d8 <scarletbook_process_frames+0x2dc> @ imm = #0x3c
   2e198: e51b3020     	ldr	r3, [r11, #-0x20]
   2e19c: e2833a07     	add	r3, r3, #28672
   2e1a0: e2833063     	add	r3, r3, #99
   2e1a4: e51b201c     	ldr	r2, [r11, #-0x1c]
   2e1a8: e1a02102     	lsl	r2, r2, #2
   2e1ac: e0833002     	add	r3, r3, r2
   2e1b0: e1a00003     	mov	r0, r3
   2e1b4: e51b1014     	ldr	r1, [r11, #-0x14]
   2e1b8: e3a02003     	mov	r2, #3
   2e1bc: ebff78d2     	bl	0xc50c <memcpy@plt>     @ imm = #-0x21cb8
   2e1c0: e51b3014     	ldr	r3, [r11, #-0x14]
   2e1c4: e2833003     	add	r3, r3, #3
   2e1c8: e50b3014     	str	r3, [r11, #-0x14]
   2e1cc: e51b301c     	ldr	r3, [r11, #-0x1c]
   2e1d0: e2833001     	add	r3, r3, #1
   2e1d4: e50b301c     	str	r3, [r11, #-0x1c]
   2e1d8: e51b2020     	ldr	r2, [r11, #-0x20]
   2e1dc: e59f333c     	ldr	r3, [pc, #0x33c]        @ 0x2e520 <scarletbook_process_frames+0x624>
   2e1e0: e7d23003     	ldrb	r3, [r2, r3]
   2e1e4: e1a03123     	lsr	r3, r3, #2
   2e1e8: e2033007     	and	r3, r3, #7
   2e1ec: e6ef3073     	uxtb	r3, r3
   2e1f0: e1a02003     	mov	r2, r3
   2e1f4: e51b301c     	ldr	r3, [r11, #-0x1c]
   2e1f8: e1520003     	cmp	r2, r3
   2e1fc: caffffe5     	bgt	0x2e198 <scarletbook_process_frames+0x29c> @ imm = #-0x6c
   2e200: e3a03000     	mov	r3, #0
   2e204: e50b3018     	str	r3, [r11, #-0x18]
   2e208: ea0000a3     	b	0x2e49c <scarletbook_process_frames+0x5a0> @ imm = #0x28c
   2e20c: e51b3020     	ldr	r3, [r11, #-0x20]
   2e210: e2833a07     	add	r3, r3, #28672
   2e214: e2833055     	add	r3, r3, #85
   2e218: e51b1020     	ldr	r1, [r11, #-0x20]
   2e21c: e59f22f8     	ldr	r2, [pc, #0x2f8]        @ 0x2e51c <scarletbook_process_frames+0x620>
   2e220: e7912002     	ldr	r2, [r1, r2]
   2e224: e1a02082     	lsl	r2, r2, #1
   2e228: e0833002     	add	r3, r3, r2
   2e22c: e50b3010     	str	r3, [r11, #-0x10]
   2e230: e51b3010     	ldr	r3, [r11, #-0x10]
   2e234: e5d33000     	ldrb	r3, [r3]
   2e238: e1a03123     	lsr	r3, r3, #2
   2e23c: e2033007     	and	r3, r3, #7
   2e240: e6ef3073     	uxtb	r3, r3
   2e244: e3530002     	cmp	r3, #2
   2e248: 1a000081     	bne	0x2e454 <scarletbook_process_frames+0x558> @ imm = #0x204
   2e24c: e51b3010     	ldr	r3, [r11, #-0x10]
   2e250: e5d33000     	ldrb	r3, [r3]
   2e254: e2033001     	and	r3, r3, #1
   2e258: e3530000     	cmp	r3, #0
   2e25c: 0a000033     	beq	0x2e330 <scarletbook_process_frames+0x434> @ imm = #0xcc
   2e260: e51b0020     	ldr	r0, [r11, #-0x20]
   2e264: e59b1004     	ldr	r1, [r11, #0x4]
   2e268: e59b2008     	ldr	r2, [r11, #0x8]
   2e26c: ebfffedd     	bl	0x2dde8 <exec_read_callback> @ imm = #-0x48c
   2e270: e51b2020     	ldr	r2, [r11, #-0x20]
   2e274: e59f32a8     	ldr	r3, [pc, #0x2a8]        @ 0x2e524 <scarletbook_process_frames+0x628>
   2e278: e3a01000     	mov	r1, #0
   2e27c: e7821003     	str	r1, [r2, r3]
   2e280: e51b2020     	ldr	r2, [r11, #-0x20]
   2e284: e59f3294     	ldr	r3, [pc, #0x294]        @ 0x2e520 <scarletbook_process_frames+0x624>
   2e288: e7d23003     	ldrb	r3, [r2, r3]
   2e28c: e2033001     	and	r3, r3, #1
   2e290: e6ef3073     	uxtb	r3, r3
   2e294: e1a01003     	mov	r1, r3
   2e298: e51b2020     	ldr	r2, [r11, #-0x20]
   2e29c: e59f3284     	ldr	r3, [pc, #0x284]        @ 0x2e528 <scarletbook_process_frames+0x62c>
   2e2a0: e7821003     	str	r1, [r2, r3]
   2e2a4: e51b3018     	ldr	r3, [r11, #-0x18]
   2e2a8: e51b1020     	ldr	r1, [r11, #-0x20]
   2e2ac: e2833b07     	add	r3, r3, #7168
   2e2b0: e2833016     	add	r3, r3, #22
   2e2b4: e3a0200e     	mov	r2, #14
   2e2b8: e1a03103     	lsl	r3, r3, #2
   2e2bc: e0813003     	add	r3, r1, r3
   2e2c0: e0833002     	add	r3, r3, r2
   2e2c4: e5d33000     	ldrb	r3, [r3]
   2e2c8: e1a03123     	lsr	r3, r3, #2
   2e2cc: e203301f     	and	r3, r3, #31
   2e2d0: e6ef3073     	uxtb	r3, r3
   2e2d4: e1a01003     	mov	r1, r3
   2e2d8: e51b2020     	ldr	r2, [r11, #-0x20]
   2e2dc: e59f3248     	ldr	r3, [pc, #0x248]        @ 0x2e52c <scarletbook_process_frames+0x630>
   2e2e0: e7821003     	str	r1, [r2, r3]
   2e2e4: e51b3020     	ldr	r3, [r11, #-0x20]
   2e2e8: e2833a07     	add	r3, r3, #28672
   2e2ec: e2833063     	add	r3, r3, #99
   2e2f0: e51b2018     	ldr	r2, [r11, #-0x18]
   2e2f4: e1a02102     	lsl	r2, r2, #2
   2e2f8: e0833002     	add	r3, r3, r2
   2e2fc: e1a00003     	mov	r0, r3
   2e300: ebfffe97     	bl	0x2dd64 <get_channel_count> @ imm = #-0x5a4
   2e304: e1a01000     	mov	r1, r0
   2e308: e51b2020     	ldr	r2, [r11, #-0x20]
   2e30c: e59f321c     	ldr	r3, [pc, #0x21c]        @ 0x2e530 <scarletbook_process_frames+0x634>
   2e310: e7821003     	str	r1, [r2, r3]
   2e314: e51b2020     	ldr	r2, [r11, #-0x20]
   2e318: e59f3214     	ldr	r3, [pc, #0x214]        @ 0x2e534 <scarletbook_process_frames+0x638>
   2e31c: e3a01001     	mov	r1, #1
   2e320: e7821003     	str	r1, [r2, r3]
   2e324: e51b3018     	ldr	r3, [r11, #-0x18]
   2e328: e2833001     	add	r3, r3, #1
   2e32c: e50b3018     	str	r3, [r11, #-0x18]
   2e330: e51b2020     	ldr	r2, [r11, #-0x20]
   2e334: e59f31f8     	ldr	r3, [pc, #0x1f8]        @ 0x2e534 <scarletbook_process_frames+0x638>
   2e338: e7923003     	ldr	r3, [r2, r3]
   2e33c: e3530000     	cmp	r3, #0
   2e340: 0a000043     	beq	0x2e454 <scarletbook_process_frames+0x558> @ imm = #0x10c
   2e344: e51b2020     	ldr	r2, [r11, #-0x20]
   2e348: e59f31d4     	ldr	r3, [pc, #0x1d4]        @ 0x2e524 <scarletbook_process_frames+0x628>
   2e34c: e7922003     	ldr	r2, [r2, r3]
   2e350: e51b3010     	ldr	r3, [r11, #-0x10]
   2e354: e5d31000     	ldrb	r1, [r3]
   2e358: e1a012a1     	lsr	r1, r1, #5
   2e35c: e6ef1071     	uxtb	r1, r1
   2e360: e5d33001     	ldrb	r3, [r3, #0x1]
   2e364: e1a03183     	lsl	r3, r3, #3
   2e368: e1833001     	orr	r3, r3, r1
   2e36c: e6ff3073     	uxth	r3, r3
   2e370: e0822003     	add	r2, r2, r3
   2e374: e59f31bc     	ldr	r3, [pc, #0x1bc]        @ 0x2e538 <scarletbook_process_frames+0x63c>
   2e378: e1520003     	cmp	r2, r3
   2e37c: ca00002e     	bgt	0x2e43c <scarletbook_process_frames+0x540> @ imm = #0xb8
   2e380: e51b2020     	ldr	r2, [r11, #-0x20]
   2e384: e59f31b0     	ldr	r3, [pc, #0x1b0]        @ 0x2e53c <scarletbook_process_frames+0x640>
   2e388: e7922003     	ldr	r2, [r2, r3]
   2e38c: e51b1020     	ldr	r1, [r11, #-0x20]
   2e390: e59f318c     	ldr	r3, [pc, #0x18c]        @ 0x2e524 <scarletbook_process_frames+0x628>
   2e394: e7913003     	ldr	r3, [r1, r3]
   2e398: e0822003     	add	r2, r2, r3
   2e39c: e51b3010     	ldr	r3, [r11, #-0x10]
   2e3a0: e5d31000     	ldrb	r1, [r3]
   2e3a4: e1a012a1     	lsr	r1, r1, #5
   2e3a8: e6ef1071     	uxtb	r1, r1
   2e3ac: e5d33001     	ldrb	r3, [r3, #0x1]
   2e3b0: e1a03183     	lsl	r3, r3, #3
   2e3b4: e1833001     	orr	r3, r3, r1
   2e3b8: e6ff3073     	uxth	r3, r3
   2e3bc: e1a00002     	mov	r0, r2
   2e3c0: e51b1014     	ldr	r1, [r11, #-0x14]
   2e3c4: e1a02003     	mov	r2, r3
   2e3c8: ebff784f     	bl	0xc50c <memcpy@plt>     @ imm = #-0x21ec4
   2e3cc: e51b2020     	ldr	r2, [r11, #-0x20]
   2e3d0: e59f314c     	ldr	r3, [pc, #0x14c]        @ 0x2e524 <scarletbook_process_frames+0x628>
   2e3d4: e7922003     	ldr	r2, [r2, r3]
   2e3d8: e51b3010     	ldr	r3, [r11, #-0x10]
   2e3dc: e5d31000     	ldrb	r1, [r3]
   2e3e0: e1a012a1     	lsr	r1, r1, #5
   2e3e4: e6ef1071     	uxtb	r1, r1
   2e3e8: e5d33001     	ldrb	r3, [r3, #0x1]
   2e3ec: e1a03183     	lsl	r3, r3, #3
   2e3f0: e1833001     	orr	r3, r3, r1
   2e3f4: e6ff3073     	uxth	r3, r3
   2e3f8: e0821003     	add	r1, r2, r3
   2e3fc: e51b2020     	ldr	r2, [r11, #-0x20]
   2e400: e59f311c     	ldr	r3, [pc, #0x11c]        @ 0x2e524 <scarletbook_process_frames+0x628>
   2e404: e7821003     	str	r1, [r2, r3]
   2e408: e51b2020     	ldr	r2, [r11, #-0x20]
   2e40c: e59f3114     	ldr	r3, [pc, #0x114]        @ 0x2e528 <scarletbook_process_frames+0x62c>
   2e410: e7923003     	ldr	r3, [r2, r3]
   2e414: e3530000     	cmp	r3, #0
   2e418: 0a00000c     	beq	0x2e450 <scarletbook_process_frames+0x554> @ imm = #0x30
   2e41c: e51b2020     	ldr	r2, [r11, #-0x20]
   2e420: e59f3104     	ldr	r3, [pc, #0x104]        @ 0x2e52c <scarletbook_process_frames+0x630>
   2e424: e7923003     	ldr	r3, [r2, r3]
   2e428: e2431001     	sub	r1, r3, #1
   2e42c: e51b2020     	ldr	r2, [r11, #-0x20]
   2e430: e59f30f4     	ldr	r3, [pc, #0xf4]         @ 0x2e52c <scarletbook_process_frames+0x630>
   2e434: e7821003     	str	r1, [r2, r3]
   2e438: ea000005     	b	0x2e454 <scarletbook_process_frames+0x558> @ imm = #0x14
   2e43c: e51b2020     	ldr	r2, [r11, #-0x20]
   2e440: e59f30ec     	ldr	r3, [pc, #0xec]         @ 0x2e534 <scarletbook_process_frames+0x638>
   2e444: e3a01000     	mov	r1, #0
   2e448: e7821003     	str	r1, [r2, r3]
   2e44c: ea000000     	b	0x2e454 <scarletbook_process_frames+0x558> @ imm = #0x0
   2e450: e1a00000     	mov	r0, r0
   2e454: e51b3010     	ldr	r3, [r11, #-0x10]
   2e458: e5d32000     	ldrb	r2, [r3]
   2e45c: e1a022a2     	lsr	r2, r2, #5
   2e460: e6ef2072     	uxtb	r2, r2
   2e464: e5d33001     	ldrb	r3, [r3, #0x1]
   2e468: e1a03183     	lsl	r3, r3, #3
   2e46c: e1833002     	orr	r3, r3, r2
   2e470: e6ff3073     	uxth	r3, r3
   2e474: e51b2014     	ldr	r2, [r11, #-0x14]
   2e478: e0823003     	add	r3, r2, r3
   2e47c: e50b3014     	str	r3, [r11, #-0x14]
   2e480: e51b2020     	ldr	r2, [r11, #-0x20]
   2e484: e59f3090     	ldr	r3, [pc, #0x90]         @ 0x2e51c <scarletbook_process_frames+0x620>
   2e488: e7923003     	ldr	r3, [r2, r3]
   2e48c: e2831001     	add	r1, r3, #1
   2e490: e51b2020     	ldr	r2, [r11, #-0x20]
   2e494: e59f3080     	ldr	r3, [pc, #0x80]         @ 0x2e51c <scarletbook_process_frames+0x620>
   2e498: e7821003     	str	r1, [r2, r3]
   2e49c: e51b2020     	ldr	r2, [r11, #-0x20]
   2e4a0: e59f3074     	ldr	r3, [pc, #0x74]         @ 0x2e51c <scarletbook_process_frames+0x620>
   2e4a4: e7922003     	ldr	r2, [r2, r3]
   2e4a8: e51b1020     	ldr	r1, [r11, #-0x20]
   2e4ac: e59f306c     	ldr	r3, [pc, #0x6c]         @ 0x2e520 <scarletbook_process_frames+0x624>
   2e4b0: e7d13003     	ldrb	r3, [r1, r3]
   2e4b4: e1a032a3     	lsr	r3, r3, #5
   2e4b8: e6ef3073     	uxtb	r3, r3
   2e4bc: e1520003     	cmp	r2, r3
   2e4c0: baffff51     	blt	0x2e20c <scarletbook_process_frames+0x310> @ imm = #-0x2bc
   2e4c4: e51b3024     	ldr	r3, [r11, #-0x24]
   2e4c8: e2833b02     	add	r3, r3, #2048
   2e4cc: e50b3024     	str	r3, [r11, #-0x24]
   2e4d0: e51b3028     	ldr	r3, [r11, #-0x28]
   2e4d4: e3530000     	cmp	r3, #0
   2e4d8: 03a03000     	moveq	r3, #0
   2e4dc: 13a03001     	movne	r3, #1
   2e4e0: e6ef3073     	uxtb	r3, r3
   2e4e4: e51b2028     	ldr	r2, [r11, #-0x28]
   2e4e8: e2422001     	sub	r2, r2, #1
   2e4ec: e50b2028     	str	r2, [r11, #-0x28]
   2e4f0: e3530000     	cmp	r3, #0
   2e4f4: 1afffe88     	bne	0x2df1c <scarletbook_process_frames+0x20> @ imm = #-0x5e0
   2e4f8: e51b302c     	ldr	r3, [r11, #-0x2c]
   2e4fc: e3530000     	cmp	r3, #0
   2e500: 0a000003     	beq	0x2e514 <scarletbook_process_frames+0x618> @ imm = #0xc
   2e504: e51b0020     	ldr	r0, [r11, #-0x20]
   2e508: e59b1004     	ldr	r1, [r11, #0x4]
   2e50c: e59b2008     	ldr	r2, [r11, #0x8]
   2e510: ebfffe34     	bl	0x2dde8 <exec_read_callback> @ imm = #-0x730
   2e514: e24bd008     	sub	sp, r11, #8
   2e518: e8bd8810     	pop	{r4, r11, pc}
   2e51c: 80 70 00 00  	.word	0x00007080
   2e520: 54 70 00 00  	.word	0x00007054
   2e524: 40 70 00 00  	.word	0x00007040
   2e528: 50 70 00 00  	.word	0x00007050
   2e52c: 48 70 00 00  	.word	0x00007048
   2e530: 4c 70 00 00  	.word	0x0000704c
   2e534: 44 70 00 00  	.word	0x00007044
   2e538: ff ff 00 00  	.word	0x0000ffff
   2e53c: 3c 70 00 00  	.word	0x0000703c

