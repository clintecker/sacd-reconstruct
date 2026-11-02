00029200 <get_music_filename>:
   29200: e92d4800     	push	{r11, lr}
   29204: e28db004     	add	r11, sp, #4
   29208: e24dd0e8     	sub	sp, sp, #232
   2920c: e50b00d8     	str	r0, [r11, #-0xd8]
   29210: e50b10dc     	str	r1, [r11, #-0xdc]
   29214: e50b20e0     	str	r2, [r11, #-0xe0]
   29218: e50b30e4     	str	r3, [r11, #-0xe4]
   2921c: e51b30d8     	ldr	r3, [r11, #-0xd8]
   29220: e2833010     	add	r3, r3, #16
   29224: e50b3010     	str	r3, [r11, #-0x10]
   29228: e3a03000     	mov	r3, #0
   2922c: e50b300c     	str	r3, [r11, #-0xc]
   29230: e51b3010     	ldr	r3, [r11, #-0x10]
   29234: e5933000     	ldr	r3, [r3]
   29238: e3530000     	cmp	r3, #0
   2923c: 0a000003     	beq	0x29250 <get_music_filename+0x50> @ imm = #0xc
   29240: e51b3010     	ldr	r3, [r11, #-0x10]
   29244: e5933000     	ldr	r3, [r3]
   29248: e50b300c     	str	r3, [r11, #-0xc]
   2924c: ea000016     	b	0x292ac <get_music_filename+0xac> @ imm = #0x58
   29250: e51b3010     	ldr	r3, [r11, #-0x10]
   29254: e5933004     	ldr	r3, [r3, #0x4]
   29258: e3530000     	cmp	r3, #0
   2925c: 0a000003     	beq	0x29270 <get_music_filename+0x70> @ imm = #0xc
   29260: e51b3010     	ldr	r3, [r11, #-0x10]
   29264: e5933004     	ldr	r3, [r3, #0x4]
   29268: e50b300c     	str	r3, [r11, #-0xc]
   2926c: ea00000e     	b	0x292ac <get_music_filename+0xac> @ imm = #0x38
   29270: e51b3010     	ldr	r3, [r11, #-0x10]
   29274: e5933020     	ldr	r3, [r3, #0x20]
   29278: e3530000     	cmp	r3, #0
   2927c: 0a000003     	beq	0x29290 <get_music_filename+0x90> @ imm = #0xc
   29280: e51b3010     	ldr	r3, [r11, #-0x10]
   29284: e5933020     	ldr	r3, [r3, #0x20]
   29288: e50b300c     	str	r3, [r11, #-0xc]
   2928c: ea000006     	b	0x292ac <get_music_filename+0xac> @ imm = #0x18
   29290: e51b3010     	ldr	r3, [r11, #-0x10]
   29294: e5933024     	ldr	r3, [r3, #0x24]
   29298: e3530000     	cmp	r3, #0
   2929c: 0a000002     	beq	0x292ac <get_music_filename+0xac> @ imm = #0x8
   292a0: e51b3010     	ldr	r3, [r11, #-0x10]
   292a4: e5933024     	ldr	r3, [r3, #0x24]
   292a8: e50b300c     	str	r3, [r11, #-0xc]
   292ac: e24b3050     	sub	r3, r11, #80
   292b0: e1a00003     	mov	r0, r3
   292b4: e3a01000     	mov	r1, #0
   292b8: e3a0203c     	mov	r2, #60
   292bc: ebff8c38     	bl	0xc3a4 <memset@plt>     @ imm = #-0x1cf20
   292c0: e51bc0dc     	ldr	r12, [r11, #-0xdc]
   292c4: e51b30e0     	ldr	r3, [r11, #-0xe0]
   292c8: e51b00d8     	ldr	r0, [r11, #-0xd8]
   292cc: e3a01074     	mov	r1, #116
   292d0: e1a02183     	lsl	r2, r3, #3
   292d4: e1a03182     	lsl	r3, r2, #3
   292d8: e0623003     	rsb	r3, r2, r3
   292dc: e59f2314     	ldr	r2, [pc, #0x314]        @ 0x295f8 <get_music_filename+0x3f8>
   292e0: e0020c92     	mul	r2, r2, r12
   292e4: e0833002     	add	r3, r3, r2
   292e8: e0803003     	add	r3, r0, r3
   292ec: e0833001     	add	r3, r3, r1
   292f0: e5933000     	ldr	r3, [r3]
   292f4: e50b3014     	str	r3, [r11, #-0x14]
   292f8: e51b3014     	ldr	r3, [r11, #-0x14]
   292fc: e3530000     	cmp	r3, #0
   29300: 0a000005     	beq	0x2931c <get_music_filename+0x11c> @ imm = #0x14
   29304: e51b3014     	ldr	r3, [r11, #-0x14]
   29308: e24b2050     	sub	r2, r11, #80
   2930c: e1a00002     	mov	r0, r2
   29310: e1a01003     	mov	r1, r3
   29314: e3a0203b     	mov	r2, #59
   29318: ebff8bee     	bl	0xc2d8 <strncpy@plt>    @ imm = #-0x1d048
   2931c: e24b308c     	sub	r3, r11, #140
   29320: e1a00003     	mov	r0, r3
   29324: e3a01000     	mov	r1, #0
   29328: e3a0203c     	mov	r2, #60
   2932c: ebff8c1c     	bl	0xc3a4 <memset@plt>     @ imm = #-0x1cf90
   29330: e51bc0dc     	ldr	r12, [r11, #-0xdc]
   29334: e51b30e0     	ldr	r3, [r11, #-0xe0]
   29338: e51b00d8     	ldr	r0, [r11, #-0xd8]
   2933c: e3a01070     	mov	r1, #112
   29340: e1a02183     	lsl	r2, r3, #3
   29344: e1a03182     	lsl	r3, r2, #3
   29348: e0623003     	rsb	r3, r2, r3
   2934c: e59f22a4     	ldr	r2, [pc, #0x2a4]        @ 0x295f8 <get_music_filename+0x3f8>
   29350: e0020c92     	mul	r2, r2, r12
   29354: e0833002     	add	r3, r3, r2
   29358: e0803003     	add	r3, r0, r3
   2935c: e0833001     	add	r3, r3, r1
   29360: e5933000     	ldr	r3, [r3]
   29364: e50b3014     	str	r3, [r11, #-0x14]
   29368: e51b3014     	ldr	r3, [r11, #-0x14]
   2936c: e3530000     	cmp	r3, #0
   29370: 0a000005     	beq	0x2938c <get_music_filename+0x18c> @ imm = #0x14
   29374: e51b3014     	ldr	r3, [r11, #-0x14]
   29378: e24b208c     	sub	r2, r11, #140
   2937c: e1a00002     	mov	r0, r2
   29380: e1a01003     	mov	r1, r3
   29384: e3a0203b     	mov	r2, #59
   29388: ebff8bd2     	bl	0xc2d8 <strncpy@plt>    @ imm = #-0x1d0b8
   2938c: e24b30c8     	sub	r3, r11, #200
   29390: e1a00003     	mov	r0, r3
   29394: e3a01000     	mov	r1, #0
   29398: e3a0203c     	mov	r2, #60
   2939c: ebff8c00     	bl	0xc3a4 <memset@plt>     @ imm = #-0x1d000
   293a0: e51b300c     	ldr	r3, [r11, #-0xc]
   293a4: e3530000     	cmp	r3, #0
   293a8: 0a000018     	beq	0x29410 <get_music_filename+0x210> @ imm = #0x60
   293ac: e51b000c     	ldr	r0, [r11, #-0xc]
   293b0: e3a0103b     	mov	r1, #59
   293b4: ebff8bdc     	bl	0xc32c <strchr@plt>     @ imm = #-0x1d090
   293b8: e1a03000     	mov	r3, r0
   293bc: e50b3008     	str	r3, [r11, #-0x8]
   293c0: e51b3008     	ldr	r3, [r11, #-0x8]
   293c4: e3530000     	cmp	r3, #0
   293c8: 1a000005     	bne	0x293e4 <get_music_filename+0x1e4> @ imm = #0x14
   293cc: e51b000c     	ldr	r0, [r11, #-0xc]
   293d0: ebff8c41     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1cefc
   293d4: e1a03000     	mov	r3, r0
   293d8: e51b200c     	ldr	r2, [r11, #-0xc]
   293dc: e0823003     	add	r3, r2, r3
   293e0: e50b3008     	str	r3, [r11, #-0x8]
   293e4: e51b200c     	ldr	r2, [r11, #-0xc]
   293e8: e51b1008     	ldr	r1, [r11, #-0x8]
   293ec: e51b300c     	ldr	r3, [r11, #-0xc]
   293f0: e0633001     	rsb	r3, r3, r1
   293f4: e353003b     	cmp	r3, #59
   293f8: a3a0303b     	movge	r3, #59
   293fc: e24b10c8     	sub	r1, r11, #200
   29400: e1a00001     	mov	r0, r1
   29404: e1a01002     	mov	r1, r2
   29408: e1a02003     	mov	r2, r3
   2940c: ebff8bb1     	bl	0xc2d8 <strncpy@plt>    @ imm = #-0x1d13c
   29410: e59f21e4     	ldr	r2, [pc, #0x1e4]        @ 0x295fc <get_music_filename+0x3fc>
   29414: e51b30d8     	ldr	r3, [r11, #-0xd8]
   29418: e5933008     	ldr	r3, [r3, #0x8]
   2941c: e5d31078     	ldrb	r1, [r3, #0x78]
   29420: e5d33079     	ldrb	r3, [r3, #0x79]
   29424: e1a03403     	lsl	r3, r3, #8
   29428: e1833001     	orr	r3, r3, r1
   2942c: e6ff3073     	uxth	r3, r3
   29430: e24b10d0     	sub	r1, r11, #208
   29434: e1a00001     	mov	r0, r1
   29438: e3a01005     	mov	r1, #5
   2943c: ebff8cbf     	bl	0xc740 <snprintf@plt>   @ imm = #-0x1cd04
   29440: e24b3050     	sub	r3, r11, #80
   29444: e1a00003     	mov	r0, r3
   29448: ebff9fc4     	bl	0x11360 <sanitize_filename> @ imm = #-0x180f0
   2944c: e24b30c8     	sub	r3, r11, #200
   29450: e1a00003     	mov	r0, r3
   29454: ebff9fc1     	bl	0x11360 <sanitize_filename> @ imm = #-0x180fc
   29458: e24b308c     	sub	r3, r11, #140
   2945c: e1a00003     	mov	r0, r3
   29460: ebff9fbe     	bl	0x11360 <sanitize_filename> @ imm = #-0x18108
   29464: e51b30e4     	ldr	r3, [r11, #-0xe4]
   29468: e3530000     	cmp	r3, #0
   2946c: 0a00000f     	beq	0x294b0 <get_music_filename+0x2b0> @ imm = #0x3c
   29470: e51b30e4     	ldr	r3, [r11, #-0xe4]
   29474: e5d33000     	ldrb	r3, [r3]
   29478: e3530000     	cmp	r3, #0
   2947c: 0a00000b     	beq	0x294b0 <get_music_filename+0x2b0> @ imm = #0x2c
   29480: e51b30e0     	ldr	r3, [r11, #-0xe0]
   29484: e2831001     	add	r1, r3, #1
   29488: e24b20d0     	sub	r2, r11, #208
   2948c: e24b3050     	sub	r3, r11, #80
   29490: e24b00c8     	sub	r0, r11, #200
   29494: e58d0000     	str	r0, [sp]
   29498: e51b00e4     	ldr	r0, [r11, #-0xe4]
   2949c: e58d0004     	str	r0, [sp, #0x4]
   294a0: e59f0158     	ldr	r0, [pc, #0x158]        @ 0x29600 <get_music_filename+0x400>
   294a4: ebff9c9b     	bl	0x10718 <parse_format>  @ imm = #-0x18d94
   294a8: e1a03000     	mov	r3, r0
   294ac: ea00004e     	b	0x295ec <get_music_filename+0x3ec> @ imm = #0x138
   294b0: e24b3050     	sub	r3, r11, #80
   294b4: e5d33000     	ldrb	r3, [r3]
   294b8: e3530000     	cmp	r3, #0
   294bc: 0a00000f     	beq	0x29500 <get_music_filename+0x300> @ imm = #0x3c
   294c0: e24b308c     	sub	r3, r11, #140
   294c4: e5d33000     	ldrb	r3, [r3]
   294c8: e3530000     	cmp	r3, #0
   294cc: 0a00000b     	beq	0x29500 <get_music_filename+0x300> @ imm = #0x2c
   294d0: e51b30e0     	ldr	r3, [r11, #-0xe0]
   294d4: e2831001     	add	r1, r3, #1
   294d8: e24b20d0     	sub	r2, r11, #208
   294dc: e24b3050     	sub	r3, r11, #80
   294e0: e24b00c8     	sub	r0, r11, #200
   294e4: e58d0000     	str	r0, [sp]
   294e8: e24b008c     	sub	r0, r11, #140
   294ec: e58d0004     	str	r0, [sp, #0x4]
   294f0: e59f010c     	ldr	r0, [pc, #0x10c]        @ 0x29604 <get_music_filename+0x404>
   294f4: ebff9c87     	bl	0x10718 <parse_format>  @ imm = #-0x18de4
   294f8: e1a03000     	mov	r3, r0
   294fc: ea00003a     	b	0x295ec <get_music_filename+0x3ec> @ imm = #0xe8
   29500: e24b3050     	sub	r3, r11, #80
   29504: e5d33000     	ldrb	r3, [r3]
   29508: e3530000     	cmp	r3, #0
   2950c: 0a00000b     	beq	0x29540 <get_music_filename+0x340> @ imm = #0x2c
   29510: e51b30e0     	ldr	r3, [r11, #-0xe0]
   29514: e2831001     	add	r1, r3, #1
   29518: e24b20d0     	sub	r2, r11, #208
   2951c: e24b3050     	sub	r3, r11, #80
   29520: e24b00c8     	sub	r0, r11, #200
   29524: e58d0000     	str	r0, [sp]
   29528: e24b008c     	sub	r0, r11, #140
   2952c: e58d0004     	str	r0, [sp, #0x4]
   29530: e59f00d0     	ldr	r0, [pc, #0xd0]         @ 0x29608 <get_music_filename+0x408>
   29534: ebff9c77     	bl	0x10718 <parse_format>  @ imm = #-0x18e24
   29538: e1a03000     	mov	r3, r0
   2953c: ea00002a     	b	0x295ec <get_music_filename+0x3ec> @ imm = #0xa8
   29540: e24b308c     	sub	r3, r11, #140
   29544: e5d33000     	ldrb	r3, [r3]
   29548: e3530000     	cmp	r3, #0
   2954c: 0a00000b     	beq	0x29580 <get_music_filename+0x380> @ imm = #0x2c
   29550: e51b30e0     	ldr	r3, [r11, #-0xe0]
   29554: e2831001     	add	r1, r3, #1
   29558: e24b20d0     	sub	r2, r11, #208
   2955c: e24b3050     	sub	r3, r11, #80
   29560: e24b00c8     	sub	r0, r11, #200
   29564: e58d0000     	str	r0, [sp]
   29568: e24b008c     	sub	r0, r11, #140
   2956c: e58d0004     	str	r0, [sp, #0x4]
   29570: e59f0088     	ldr	r0, [pc, #0x88]         @ 0x29600 <get_music_filename+0x400>
   29574: ebff9c67     	bl	0x10718 <parse_format>  @ imm = #-0x18e64
   29578: e1a03000     	mov	r3, r0
   2957c: ea00001a     	b	0x295ec <get_music_filename+0x3ec> @ imm = #0x68
   29580: e24b30c8     	sub	r3, r11, #200
   29584: e5d33000     	ldrb	r3, [r3]
   29588: e3530000     	cmp	r3, #0
   2958c: 0a00000b     	beq	0x295c0 <get_music_filename+0x3c0> @ imm = #0x2c
   29590: e51b30e0     	ldr	r3, [r11, #-0xe0]
   29594: e2831001     	add	r1, r3, #1
   29598: e24b20d0     	sub	r2, r11, #208
   2959c: e24b3050     	sub	r3, r11, #80
   295a0: e24b00c8     	sub	r0, r11, #200
   295a4: e58d0000     	str	r0, [sp]
   295a8: e24b008c     	sub	r0, r11, #140
   295ac: e58d0004     	str	r0, [sp, #0x4]
   295b0: e59f0054     	ldr	r0, [pc, #0x54]         @ 0x2960c <get_music_filename+0x40c>
   295b4: ebff9c57     	bl	0x10718 <parse_format>  @ imm = #-0x18ea4
   295b8: e1a03000     	mov	r3, r0
   295bc: ea00000a     	b	0x295ec <get_music_filename+0x3ec> @ imm = #0x28
   295c0: e51b30e0     	ldr	r3, [r11, #-0xe0]
   295c4: e2831001     	add	r1, r3, #1
   295c8: e24b20d0     	sub	r2, r11, #208
   295cc: e24b3050     	sub	r3, r11, #80
   295d0: e24b00c8     	sub	r0, r11, #200
   295d4: e58d0000     	str	r0, [sp]
   295d8: e24b008c     	sub	r0, r11, #140
   295dc: e58d0004     	str	r0, [sp, #0x4]
   295e0: e59f0028     	ldr	r0, [pc, #0x28]         @ 0x29610 <get_music_filename+0x410>
   295e4: ebff9c4b     	bl	0x10718 <parse_format>  @ imm = #-0x18ed4
   295e8: e1a03000     	mov	r3, r0
   295ec: e1a00003     	mov	r0, r3
   295f0: e24bd004     	sub	sp, r11, #4
   295f4: e8bd8800     	pop	{r11, pc}
   295f8: f0 37 00 00  	.word	0x000037f0
   295fc: 4c 58 03 00  	.word	0x0003584c
   29600: 74 58 03 00  	.word	0x00035874
   29604: 7c 58 03 00  	.word	0x0003587c
   29608: 8c 58 03 00  	.word	0x0003588c
   2960c: 94 58 03 00  	.word	0x00035894
   29610: 9c 58 03 00  	.word	0x0003589c

