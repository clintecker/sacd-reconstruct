00022218 <sacd_net_input_open>:
   22218: e92d4830     	push	{r4, r5, r11, lr}
   2221c: e28db00c     	add	r11, sp, #12
   22220: e24dd088     	sub	sp, sp, #136
   22224: e50b0080     	str	r0, [r11, #-0x80]
   22228: e3a03000     	mov	r3, #0
   2222c: e50b3014     	str	r3, [r11, #-0x14]
   22230: e3a03000     	mov	r3, #0
   22234: e50b3010     	str	r3, [r11, #-0x10]
   22238: e3a03000     	mov	r3, #0
   2223c: e54b3079     	strb	r3, [r11, #-0x79]
   22240: e3a00008     	mov	r0, #8
   22244: e3a01001     	mov	r1, #1
   22248: ebffa843     	bl	0xc35c <calloc@plt>     @ imm = #-0x15ef4
   2224c: e1a03000     	mov	r3, r0
   22250: e50b3014     	str	r3, [r11, #-0x14]
   22254: e51b3014     	ldr	r3, [r11, #-0x14]
   22258: e3530000     	cmp	r3, #0
   2225c: 1a000008     	bne	0x22284 <sacd_net_input_open+0x6c> @ imm = #0x20
   22260: e59f22a8     	ldr	r2, [pc, #0x2a8]        @ 0x22510 <sacd_net_input_open+0x2f8>
   22264: e59f32a8     	ldr	r3, [pc, #0x2a8]        @ 0x22514 <sacd_net_input_open+0x2fc>
   22268: e5933000     	ldr	r3, [r3]
   2226c: e1a00002     	mov	r0, r2
   22270: e3a01001     	mov	r1, #1
   22274: e3a02028     	mov	r2, #40
   22278: ebffa8dc     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x15c90
   2227c: e3a03000     	mov	r3, #0
   22280: ea00009f     	b	0x22504 <sacd_net_input_open+0x2ec> @ imm = #0x27c
   22284: e59f028c     	ldr	r0, [pc, #0x28c]        @ 0x22518 <sacd_net_input_open+0x300>
   22288: ebffa8f6     	bl	0xc668 <malloc@plt>     @ imm = #-0x15c28
   2228c: e1a03000     	mov	r3, r0
   22290: e1a02003     	mov	r2, r3
   22294: e51b3014     	ldr	r3, [r11, #-0x14]
   22298: e5832004     	str	r2, [r3, #0x4]
   2229c: e51b3014     	ldr	r3, [r11, #-0x14]
   222a0: e5933004     	ldr	r3, [r3, #0x4]
   222a4: e3530000     	cmp	r3, #0
   222a8: 1a000007     	bne	0x222cc <sacd_net_input_open+0xb4> @ imm = #0x1c
   222ac: e59f225c     	ldr	r2, [pc, #0x25c]        @ 0x22510 <sacd_net_input_open+0x2f8>
   222b0: e59f325c     	ldr	r3, [pc, #0x25c]        @ 0x22514 <sacd_net_input_open+0x2fc>
   222b4: e5933000     	ldr	r3, [r3]
   222b8: e1a00002     	mov	r0, r2
   222bc: e3a01001     	mov	r1, #1
   222c0: e3a02028     	mov	r2, #40
   222c4: ebffa8c9     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x15cdc
   222c8: ea000088     	b	0x224f0 <sacd_net_input_open+0x2d8> @ imm = #0x220
   222cc: ebffc184     	bl	0x128e4 <socket_open>   @ imm = #-0xf9f0
   222d0: e51b3014     	ldr	r3, [r11, #-0x14]
   222d4: e1a00003     	mov	r0, r3
   222d8: e3a01002     	mov	r1, #2
   222dc: e3a02001     	mov	r2, #1
   222e0: e3a03000     	mov	r3, #0
   222e4: ebffc1ed     	bl	0x12aa0 <socket_create> @ imm = #-0xf84c
   222e8: e51b3014     	ldr	r3, [r11, #-0x14]
   222ec: e1a00003     	mov	r0, r3
   222f0: ebffc408     	bl	0x13318 <socket_setblocking> @ imm = #-0xefe0
   222f4: e24b305c     	sub	r3, r11, #92
   222f8: e1a00003     	mov	r0, r3
   222fc: ebffb80e     	bl	0x1033c <timeout_markstart> @ imm = #-0x11fc8
   22300: e51b5014     	ldr	r5, [r11, #-0x14]
   22304: e51b0080     	ldr	r0, [r11, #-0x80]
   22308: e3a0103a     	mov	r1, #58
   2230c: ebffa806     	bl	0xc32c <strchr@plt>     @ imm = #-0x15fe8
   22310: e1a03000     	mov	r3, r0
   22314: e1a02003     	mov	r2, r3
   22318: e51b3080     	ldr	r3, [r11, #-0x80]
   2231c: e0633002     	rsb	r3, r3, r2
   22320: e51b0080     	ldr	r0, [r11, #-0x80]
   22324: e3a01000     	mov	r1, #0
   22328: e1a02003     	mov	r2, r3
   2232c: ebffc59f     	bl	0x139b0 <substr>        @ imm = #-0xe984
   22330: e1a04000     	mov	r4, r0
   22334: e51b0080     	ldr	r0, [r11, #-0x80]
   22338: e3a0103a     	mov	r1, #58
   2233c: ebffa7fa     	bl	0xc32c <strchr@plt>     @ imm = #-0x16018
   22340: e1a03000     	mov	r3, r0
   22344: e2833001     	add	r3, r3, #1
   22348: e1a00003     	mov	r0, r3
   2234c: ebffa88f     	bl	0xc590 <atoi@plt>       @ imm = #-0x15dc4
   22350: e1a03000     	mov	r3, r0
   22354: e6ff2073     	uxth	r2, r3
   22358: e24b305c     	sub	r3, r11, #92
   2235c: e1a00005     	mov	r0, r5
   22360: e1a01004     	mov	r1, r4
   22364: ebffc4f0     	bl	0x1372c <inet_tryconnect> @ imm = #-0xec40
   22368: e1a03000     	mov	r3, r0
   2236c: e50b3010     	str	r3, [r11, #-0x10]
   22370: e51b3010     	ldr	r3, [r11, #-0x10]
   22374: e3530000     	cmp	r3, #0
   22378: 0a000007     	beq	0x2239c <sacd_net_input_open+0x184> @ imm = #0x1c
   2237c: e59f2198     	ldr	r2, [pc, #0x198]        @ 0x2251c <sacd_net_input_open+0x304>
   22380: e59f318c     	ldr	r3, [pc, #0x18c]        @ 0x22514 <sacd_net_input_open+0x2fc>
   22384: e5933000     	ldr	r3, [r3]
   22388: e1a00002     	mov	r0, r2
   2238c: e3a01001     	mov	r1, #1
   22390: e3a02012     	mov	r2, #18
   22394: ebffa895     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x15dac
   22398: ea000054     	b	0x224f0 <sacd_net_input_open+0x2d8> @ imm = #0x150
   2239c: e51b3014     	ldr	r3, [r11, #-0x14]
   223a0: e1a00003     	mov	r0, r3
   223a4: ebffc3db     	bl	0x13318 <socket_setblocking> @ imm = #-0xf094
   223a8: e51b3014     	ldr	r3, [r11, #-0x14]
   223ac: e24b2094     	sub	r2, r11, #148
   223b0: e1a00002     	mov	r0, r2
   223b4: e1a01003     	mov	r1, r3
   223b8: ebfff910     	bl	0x20800 <pb_istream_from_socket> @ imm = #-0x1bc0
   223bc: e24b3068     	sub	r3, r11, #104
   223c0: e24b2094     	sub	r2, r11, #148
   223c4: e8920007     	ldm	r2, {r0, r1, r2}
   223c8: e8830007     	stm	r3, {r0, r1, r2}
   223cc: e51b3014     	ldr	r3, [r11, #-0x14]
   223d0: e24b2094     	sub	r2, r11, #148
   223d4: e1a00002     	mov	r0, r2
   223d8: e1a01003     	mov	r1, r3
   223dc: ebfff8f1     	bl	0x207a8 <pb_ostream_from_socket> @ imm = #-0x1c3c
   223e0: e24bc078     	sub	r12, r11, #120
   223e4: e24b3094     	sub	r3, r11, #148
   223e8: e893000f     	ldm	r3, {r0, r1, r2, r3}
   223ec: e88c000f     	stm	r12, {r0, r1, r2, r3}
   223f0: e3a03001     	mov	r3, #1
   223f4: e50b3020     	str	r3, [r11, #-0x20]
   223f8: e24b2078     	sub	r2, r11, #120
   223fc: e24b3020     	sub	r3, r11, #32
   22400: e1a00002     	mov	r0, r2
   22404: e59f1114     	ldr	r1, [pc, #0x114]        @ 0x22520 <sacd_net_input_open+0x308>
   22408: e1a02003     	mov	r2, r3
   2240c: ebffbd9e     	bl	0x11a8c <pb_encode>     @ imm = #-0x10988
   22410: e1a03000     	mov	r3, r0
   22414: e2233001     	eor	r3, r3, #1
   22418: e6ef3073     	uxtb	r3, r3
   2241c: e3530000     	cmp	r3, #0
   22420: 0a000007     	beq	0x22444 <sacd_net_input_open+0x22c> @ imm = #0x1c
   22424: e59f20f8     	ldr	r2, [pc, #0xf8]         @ 0x22524 <sacd_net_input_open+0x30c>
   22428: e59f30e4     	ldr	r3, [pc, #0xe4]         @ 0x22514 <sacd_net_input_open+0x2fc>
   2242c: e5933000     	ldr	r3, [r3]
   22430: e1a00002     	mov	r0, r2
   22434: e3a01001     	mov	r1, #1
   22438: e3a02019     	mov	r2, #25
   2243c: ebffa86b     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x15e54
   22440: ea00002a     	b	0x224f0 <sacd_net_input_open+0x2d8> @ imm = #0xa8
   22444: e24b2078     	sub	r2, r11, #120
   22448: e24b3079     	sub	r3, r11, #121
   2244c: e1a00002     	mov	r0, r2
   22450: e1a01003     	mov	r1, r3
   22454: e3a02001     	mov	r2, #1
   22458: ebffbc8e     	bl	0x11698 <pb_write>      @ imm = #-0x10dc8
   2245c: e24b2068     	sub	r2, r11, #104
   22460: e24b3044     	sub	r3, r11, #68
   22464: e1a00002     	mov	r0, r2
   22468: e59f10b8     	ldr	r1, [pc, #0xb8]         @ 0x22528 <sacd_net_input_open+0x310>
   2246c: e1a02003     	mov	r2, r3
   22470: ebffb457     	bl	0xf5d4 <pb_decode>      @ imm = #-0x12ea4
   22474: e1a03000     	mov	r3, r0
   22478: e2233001     	eor	r3, r3, #1
   2247c: e6ef3073     	uxtb	r3, r3
   22480: e3530000     	cmp	r3, #0
   22484: 0a000007     	beq	0x224a8 <sacd_net_input_open+0x290> @ imm = #0x1c
   22488: e59f209c     	ldr	r2, [pc, #0x9c]         @ 0x2252c <sacd_net_input_open+0x314>
   2248c: e59f3080     	ldr	r3, [pc, #0x80]         @ 0x22514 <sacd_net_input_open+0x2fc>
   22490: e5933000     	ldr	r3, [r3]
   22494: e1a00002     	mov	r0, r2
   22498: e3a01001     	mov	r1, #1
   2249c: e3a0201a     	mov	r2, #26
   224a0: ebffa852     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x15eb8
   224a4: ea000011     	b	0x224f0 <sacd_net_input_open+0x2d8> @ imm = #0x44
   224a8: e14b03dc     	ldrd	r0, r1, [r11, #-60]
   224ac: e1a03000     	mov	r3, r0
   224b0: e1833001     	orr	r3, r3, r1
   224b4: e3530000     	cmp	r3, #0
   224b8: 1a000002     	bne	0x224c8 <sacd_net_input_open+0x2b0> @ imm = #0x8
   224bc: e51b3044     	ldr	r3, [r11, #-0x44]
   224c0: e3530001     	cmp	r3, #1
   224c4: 0a000007     	beq	0x224e8 <sacd_net_input_open+0x2d0> @ imm = #0x1c
   224c8: e59f2060     	ldr	r2, [pc, #0x60]         @ 0x22530 <sacd_net_input_open+0x318>
   224cc: e59f3040     	ldr	r3, [pc, #0x40]         @ 0x22514 <sacd_net_input_open+0x2fc>
   224d0: e5933000     	ldr	r3, [r3]
   224d4: e1a00002     	mov	r0, r2
   224d8: e3a01001     	mov	r1, #1
   224dc: e3a02028     	mov	r2, #40
   224e0: ebffa842     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x15ef8
   224e4: ea000001     	b	0x224f0 <sacd_net_input_open+0x2d8> @ imm = #0x4
   224e8: e51b3014     	ldr	r3, [r11, #-0x14]
   224ec: ea000004     	b	0x22504 <sacd_net_input_open+0x2ec> @ imm = #0x10
   224f0: e59f303c     	ldr	r3, [pc, #0x3c]         @ 0x22534 <sacd_net_input_open+0x31c>
   224f4: e5933000     	ldr	r3, [r3]
   224f8: e51b0014     	ldr	r0, [r11, #-0x14]
   224fc: e12fff33     	blx	r3
   22500: e3a03000     	mov	r3, #0
   22504: e1a00003     	mov	r0, r3
   22508: e24bd00c     	sub	sp, r11, #12
   2250c: e8bd8830     	pop	{r4, r5, r11, pc}
   22510: 68 54 03 00  	.word	0x00035468
   22514: f8 6d 05 00  	.word	0x00056df8
   22518: 00 04 04 00  	.word	0x00040400
   2251c: a4 54 03 00  	.word	0x000354a4
   22520: 90 52 03 00  	.word	0x00035290
   22524: b8 54 03 00  	.word	0x000354b8
   22528: c4 52 03 00  	.word	0x000352c4
   2252c: d4 54 03 00  	.word	0x000354d4
   22530: f0 54 03 00  	.word	0x000354f0
   22534: 18 9e 05 00  	.word	0x00059e18

