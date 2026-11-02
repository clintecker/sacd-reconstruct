0002c0f4 <scarletbook_read_area_toc>:
   2c0f4: e92d4810     	push	{r4, r11, lr}
   2c0f8: e28db008     	add	r11, sp, #8
   2c0fc: e24dd07c     	sub	sp, sp, #124
   2c100: e50b0078     	str	r0, [r11, #-0x78]
   2c104: e50b107c     	str	r1, [r11, #-0x7c]
   2c108: e3a03000     	mov	r3, #0
   2c10c: e50b3060     	str	r3, [r11, #-0x60]
   2c110: e51b3078     	ldr	r3, [r11, #-0x78]
   2c114: e283205c     	add	r2, r3, #92
   2c118: e51b307c     	ldr	r3, [r11, #-0x7c]
   2c11c: e59f1ea4     	ldr	r1, [pc, #0xea4]        @ 0x2cfc8 <scarletbook_read_area_toc+0xed4>
   2c120: e0030391     	mul	r3, r1, r3
   2c124: e0823003     	add	r3, r2, r3
   2c128: e50b305c     	str	r3, [r11, #-0x5c]
   2c12c: e51b305c     	ldr	r3, [r11, #-0x5c]
   2c130: e5933000     	ldr	r3, [r3]
   2c134: e50b3068     	str	r3, [r11, #-0x68]
   2c138: e51b3068     	ldr	r3, [r11, #-0x68]
   2c13c: e50b3064     	str	r3, [r11, #-0x64]
   2c140: e51b2068     	ldr	r2, [r11, #-0x68]
   2c144: e51b305c     	ldr	r3, [r11, #-0x5c]
   2c148: e5832004     	str	r2, [r3, #0x4]
   2c14c: e51b305c     	ldr	r3, [r11, #-0x5c]
   2c150: e5933004     	ldr	r3, [r3, #0x4]
   2c154: e50b306c     	str	r3, [r11, #-0x6c]
   2c158: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c15c: e59f0e68     	ldr	r0, [pc, #0xe68]        @ 0x2cfcc <scarletbook_read_area_toc+0xed8>
   2c160: e1a01003     	mov	r1, r3
   2c164: e3a02008     	mov	r2, #8
   2c168: ebff8180     	bl	0xc770 <strncmp@plt>    @ imm = #-0x1fa00
   2c16c: e1a03000     	mov	r3, r0
   2c170: e3530000     	cmp	r3, #0
   2c174: 0a000010     	beq	0x2c1bc <scarletbook_read_area_toc+0xc8> @ imm = #0x40
   2c178: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c17c: e59f0e4c     	ldr	r0, [pc, #0xe4c]        @ 0x2cfd0 <scarletbook_read_area_toc+0xedc>
   2c180: e1a01003     	mov	r1, r3
   2c184: e3a02008     	mov	r2, #8
   2c188: ebff8178     	bl	0xc770 <strncmp@plt>    @ imm = #-0x1fa20
   2c18c: e1a03000     	mov	r3, r0
   2c190: e3530000     	cmp	r3, #0
   2c194: 0a000008     	beq	0x2c1bc <scarletbook_read_area_toc+0xc8> @ imm = #0x20
   2c198: e59f2e34     	ldr	r2, [pc, #0xe34]        @ 0x2cfd4 <scarletbook_read_area_toc+0xee0>
   2c19c: e59f3e34     	ldr	r3, [pc, #0xe34]        @ 0x2cfd8 <scarletbook_read_area_toc+0xee4>
   2c1a0: e5933000     	ldr	r3, [r3]
   2c1a4: e1a00002     	mov	r0, r2
   2c1a8: e3a01001     	mov	r1, #1
   2c1ac: e3a02023     	mov	r2, #35
   2c1b0: ebff810e     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x1fbc8
   2c1b4: e3a03000     	mov	r3, #0
   2c1b8: ea0006ca     	b	0x2dce8 <scarletbook_read_area_toc+0x1bf4> @ imm = #0x1b28
   2c1bc: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c1c0: e5d3200a     	ldrb	r2, [r3, #0xa]
   2c1c4: e5d3300b     	ldrb	r3, [r3, #0xb]
   2c1c8: e1a03403     	lsl	r3, r3, #8
   2c1cc: e1833002     	orr	r3, r3, r2
   2c1d0: e14b35b4     	strh	r3, [r11, #-84]
   2c1d4: e15b35b4     	ldrh	r3, [r11, #-84]
   2c1d8: e1a03423     	lsr	r3, r3, #8
   2c1dc: e6ff3073     	uxth	r3, r3
   2c1e0: e1a02003     	mov	r2, r3
   2c1e4: e15b35b4     	ldrh	r3, [r11, #-84]
   2c1e8: e1a03403     	lsl	r3, r3, #8
   2c1ec: e1a03803     	lsl	r3, r3, #16
   2c1f0: e1a03823     	lsr	r3, r3, #16
   2c1f4: e1823003     	orr	r3, r2, r3
   2c1f8: e6ff2073     	uxth	r2, r3
   2c1fc: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c200: e20210ff     	and	r1, r2, #255
   2c204: e3a00000     	mov	r0, #0
   2c208: e1801001     	orr	r1, r0, r1
   2c20c: e5c3100a     	strb	r1, [r3, #0xa]
   2c210: e1a02422     	lsr	r2, r2, #8
   2c214: e6ff2072     	uxth	r2, r2
   2c218: e3a01000     	mov	r1, #0
   2c21c: e1812002     	orr	r2, r1, r2
   2c220: e5c3200b     	strb	r2, [r3, #0xb]
   2c224: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c228: e5d32048     	ldrb	r2, [r3, #0x48]
   2c22c: e5d31049     	ldrb	r1, [r3, #0x49]
   2c230: e1a01401     	lsl	r1, r1, #8
   2c234: e1812002     	orr	r2, r1, r2
   2c238: e5d3104a     	ldrb	r1, [r3, #0x4a]
   2c23c: e1a01801     	lsl	r1, r1, #16
   2c240: e1812002     	orr	r2, r1, r2
   2c244: e5d3304b     	ldrb	r3, [r3, #0x4b]
   2c248: e1a03c03     	lsl	r3, r3, #24
   2c24c: e1833002     	orr	r3, r3, r2
   2c250: e1a04003     	mov	r4, r3
   2c254: e1a02c24     	lsr	r2, r4, #24
   2c258: e20438ff     	and	r3, r4, #16711680
   2c25c: e1a03423     	lsr	r3, r3, #8
   2c260: e1822003     	orr	r2, r2, r3
   2c264: e2043cff     	and	r3, r4, #65280
   2c268: e1a03403     	lsl	r3, r3, #8
   2c26c: e1822003     	orr	r2, r2, r3
   2c270: e1a03c04     	lsl	r3, r4, #24
   2c274: e1822003     	orr	r2, r2, r3
   2c278: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c27c: e20210ff     	and	r1, r2, #255
   2c280: e3a00000     	mov	r0, #0
   2c284: e1801001     	orr	r1, r0, r1
   2c288: e5c31048     	strb	r1, [r3, #0x48]
   2c28c: e1a01422     	lsr	r1, r2, #8
   2c290: e20110ff     	and	r1, r1, #255
   2c294: e3a00000     	mov	r0, #0
   2c298: e1801001     	orr	r1, r0, r1
   2c29c: e5c31049     	strb	r1, [r3, #0x49]
   2c2a0: e1a01822     	lsr	r1, r2, #16
   2c2a4: e20110ff     	and	r1, r1, #255
   2c2a8: e3a00000     	mov	r0, #0
   2c2ac: e1801001     	orr	r1, r0, r1
   2c2b0: e5c3104a     	strb	r1, [r3, #0x4a]
   2c2b4: e1a02c22     	lsr	r2, r2, #24
   2c2b8: e3a01000     	mov	r1, #0
   2c2bc: e1812002     	orr	r2, r1, r2
   2c2c0: e5c3204b     	strb	r2, [r3, #0x4b]
   2c2c4: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c2c8: e5d3204c     	ldrb	r2, [r3, #0x4c]
   2c2cc: e5d3104d     	ldrb	r1, [r3, #0x4d]
   2c2d0: e1a01401     	lsl	r1, r1, #8
   2c2d4: e1812002     	orr	r2, r1, r2
   2c2d8: e5d3104e     	ldrb	r1, [r3, #0x4e]
   2c2dc: e1a01801     	lsl	r1, r1, #16
   2c2e0: e1812002     	orr	r2, r1, r2
   2c2e4: e5d3304f     	ldrb	r3, [r3, #0x4f]
   2c2e8: e1a03c03     	lsl	r3, r3, #24
   2c2ec: e1833002     	orr	r3, r3, r2
   2c2f0: e1a04003     	mov	r4, r3
   2c2f4: e1a02c24     	lsr	r2, r4, #24
   2c2f8: e20438ff     	and	r3, r4, #16711680
   2c2fc: e1a03423     	lsr	r3, r3, #8
   2c300: e1822003     	orr	r2, r2, r3
   2c304: e2043cff     	and	r3, r4, #65280
   2c308: e1a03403     	lsl	r3, r3, #8
   2c30c: e1822003     	orr	r2, r2, r3
   2c310: e1a03c04     	lsl	r3, r4, #24
   2c314: e1822003     	orr	r2, r2, r3
   2c318: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c31c: e20210ff     	and	r1, r2, #255
   2c320: e3a00000     	mov	r0, #0
   2c324: e1801001     	orr	r1, r0, r1
   2c328: e5c3104c     	strb	r1, [r3, #0x4c]
   2c32c: e1a01422     	lsr	r1, r2, #8
   2c330: e20110ff     	and	r1, r1, #255
   2c334: e3a00000     	mov	r0, #0
   2c338: e1801001     	orr	r1, r0, r1
   2c33c: e5c3104d     	strb	r1, [r3, #0x4d]
   2c340: e1a01822     	lsr	r1, r2, #16
   2c344: e20110ff     	and	r1, r1, #255
   2c348: e3a00000     	mov	r0, #0
   2c34c: e1801001     	orr	r1, r0, r1
   2c350: e5c3104e     	strb	r1, [r3, #0x4e]
   2c354: e1a02c22     	lsr	r2, r2, #24
   2c358: e3a01000     	mov	r1, #0
   2c35c: e1812002     	orr	r2, r1, r2
   2c360: e5c3204f     	strb	r2, [r3, #0x4f]
   2c364: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c368: e5d32090     	ldrb	r2, [r3, #0x90]
   2c36c: e5d33091     	ldrb	r3, [r3, #0x91]
   2c370: e1a03403     	lsl	r3, r3, #8
   2c374: e1833002     	orr	r3, r3, r2
   2c378: e14b35b2     	strh	r3, [r11, #-82]
   2c37c: e15b35b2     	ldrh	r3, [r11, #-82]
   2c380: e1a03423     	lsr	r3, r3, #8
   2c384: e6ff3073     	uxth	r3, r3
   2c388: e1a02003     	mov	r2, r3
   2c38c: e15b35b2     	ldrh	r3, [r11, #-82]
   2c390: e1a03403     	lsl	r3, r3, #8
   2c394: e1a03803     	lsl	r3, r3, #16
   2c398: e1a03823     	lsr	r3, r3, #16
   2c39c: e1823003     	orr	r3, r2, r3
   2c3a0: e6ff2073     	uxth	r2, r3
   2c3a4: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c3a8: e20210ff     	and	r1, r2, #255
   2c3ac: e3a00000     	mov	r0, #0
   2c3b0: e1801001     	orr	r1, r0, r1
   2c3b4: e5c31090     	strb	r1, [r3, #0x90]
   2c3b8: e1a02422     	lsr	r2, r2, #8
   2c3bc: e6ff2072     	uxth	r2, r2
   2c3c0: e3a01000     	mov	r1, #0
   2c3c4: e1812002     	orr	r2, r1, r2
   2c3c8: e5c32091     	strb	r2, [r3, #0x91]
   2c3cc: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c3d0: e5d32092     	ldrb	r2, [r3, #0x92]
   2c3d4: e5d33093     	ldrb	r3, [r3, #0x93]
   2c3d8: e1a03403     	lsl	r3, r3, #8
   2c3dc: e1833002     	orr	r3, r3, r2
   2c3e0: e14b35b0     	strh	r3, [r11, #-80]
   2c3e4: e15b35b0     	ldrh	r3, [r11, #-80]
   2c3e8: e1a03423     	lsr	r3, r3, #8
   2c3ec: e6ff3073     	uxth	r3, r3
   2c3f0: e1a02003     	mov	r2, r3
   2c3f4: e15b35b0     	ldrh	r3, [r11, #-80]
   2c3f8: e1a03403     	lsl	r3, r3, #8
   2c3fc: e1a03803     	lsl	r3, r3, #16
   2c400: e1a03823     	lsr	r3, r3, #16
   2c404: e1823003     	orr	r3, r2, r3
   2c408: e6ff2073     	uxth	r2, r3
   2c40c: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c410: e20210ff     	and	r1, r2, #255
   2c414: e3a00000     	mov	r0, #0
   2c418: e1801001     	orr	r1, r0, r1
   2c41c: e5c31092     	strb	r1, [r3, #0x92]
   2c420: e1a02422     	lsr	r2, r2, #8
   2c424: e6ff2072     	uxth	r2, r2
   2c428: e3a01000     	mov	r1, #0
   2c42c: e1812002     	orr	r2, r1, r2
   2c430: e5c32093     	strb	r2, [r3, #0x93]
   2c434: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c438: e5d32094     	ldrb	r2, [r3, #0x94]
   2c43c: e5d33095     	ldrb	r3, [r3, #0x95]
   2c440: e1a03403     	lsl	r3, r3, #8
   2c444: e1833002     	orr	r3, r3, r2
   2c448: e14b34be     	strh	r3, [r11, #-78]
   2c44c: e15b34be     	ldrh	r3, [r11, #-78]
   2c450: e1a03423     	lsr	r3, r3, #8
   2c454: e6ff3073     	uxth	r3, r3
   2c458: e1a02003     	mov	r2, r3
   2c45c: e15b34be     	ldrh	r3, [r11, #-78]
   2c460: e1a03403     	lsl	r3, r3, #8
   2c464: e1a03803     	lsl	r3, r3, #16
   2c468: e1a03823     	lsr	r3, r3, #16
   2c46c: e1823003     	orr	r3, r2, r3
   2c470: e6ff2073     	uxth	r2, r3
   2c474: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c478: e20210ff     	and	r1, r2, #255
   2c47c: e3a00000     	mov	r0, #0
   2c480: e1801001     	orr	r1, r0, r1
   2c484: e5c31094     	strb	r1, [r3, #0x94]
   2c488: e1a02422     	lsr	r2, r2, #8
   2c48c: e6ff2072     	uxth	r2, r2
   2c490: e3a01000     	mov	r1, #0
   2c494: e1812002     	orr	r2, r1, r2
   2c498: e5c32095     	strb	r2, [r3, #0x95]
   2c49c: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c4a0: e5d32096     	ldrb	r2, [r3, #0x96]
   2c4a4: e5d33097     	ldrb	r3, [r3, #0x97]
   2c4a8: e1a03403     	lsl	r3, r3, #8
   2c4ac: e1833002     	orr	r3, r3, r2
   2c4b0: e14b34bc     	strh	r3, [r11, #-76]
   2c4b4: e15b34bc     	ldrh	r3, [r11, #-76]
   2c4b8: e1a03423     	lsr	r3, r3, #8
   2c4bc: e6ff3073     	uxth	r3, r3
   2c4c0: e1a02003     	mov	r2, r3
   2c4c4: e15b34bc     	ldrh	r3, [r11, #-76]
   2c4c8: e1a03403     	lsl	r3, r3, #8
   2c4cc: e1a03803     	lsl	r3, r3, #16
   2c4d0: e1a03823     	lsr	r3, r3, #16
   2c4d4: e1823003     	orr	r3, r2, r3
   2c4d8: e6ff2073     	uxth	r2, r3
   2c4dc: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c4e0: e20210ff     	and	r1, r2, #255
   2c4e4: e3a00000     	mov	r0, #0
   2c4e8: e1801001     	orr	r1, r0, r1
   2c4ec: e5c31096     	strb	r1, [r3, #0x96]
   2c4f0: e1a02422     	lsr	r2, r2, #8
   2c4f4: e6ff2072     	uxth	r2, r2
   2c4f8: e3a01000     	mov	r1, #0
   2c4fc: e1812002     	orr	r2, r1, r2
   2c500: e5c32097     	strb	r2, [r3, #0x97]
   2c504: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c508: e5d32010     	ldrb	r2, [r3, #0x10]
   2c50c: e5d31011     	ldrb	r1, [r3, #0x11]
   2c510: e1a01401     	lsl	r1, r1, #8
   2c514: e1812002     	orr	r2, r1, r2
   2c518: e5d31012     	ldrb	r1, [r3, #0x12]
   2c51c: e1a01801     	lsl	r1, r1, #16
   2c520: e1812002     	orr	r2, r1, r2
   2c524: e5d33013     	ldrb	r3, [r3, #0x13]
   2c528: e1a03c03     	lsl	r3, r3, #24
   2c52c: e1833002     	orr	r3, r3, r2
   2c530: e1a04003     	mov	r4, r3
   2c534: e1a02c24     	lsr	r2, r4, #24
   2c538: e20438ff     	and	r3, r4, #16711680
   2c53c: e1a03423     	lsr	r3, r3, #8
   2c540: e1822003     	orr	r2, r2, r3
   2c544: e2043cff     	and	r3, r4, #65280
   2c548: e1a03403     	lsl	r3, r3, #8
   2c54c: e1822003     	orr	r2, r2, r3
   2c550: e1a03c04     	lsl	r3, r4, #24
   2c554: e1822003     	orr	r2, r2, r3
   2c558: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c55c: e20210ff     	and	r1, r2, #255
   2c560: e3a00000     	mov	r0, #0
   2c564: e1801001     	orr	r1, r0, r1
   2c568: e5c31010     	strb	r1, [r3, #0x10]
   2c56c: e1a01422     	lsr	r1, r2, #8
   2c570: e20110ff     	and	r1, r1, #255
   2c574: e3a00000     	mov	r0, #0
   2c578: e1801001     	orr	r1, r0, r1
   2c57c: e5c31011     	strb	r1, [r3, #0x11]
   2c580: e1a01822     	lsr	r1, r2, #16
   2c584: e20110ff     	and	r1, r1, #255
   2c588: e3a00000     	mov	r0, #0
   2c58c: e1801001     	orr	r1, r0, r1
   2c590: e5c31012     	strb	r1, [r3, #0x12]
   2c594: e1a02c22     	lsr	r2, r2, #24
   2c598: e3a01000     	mov	r1, #0
   2c59c: e1812002     	orr	r2, r1, r2
   2c5a0: e5c32013     	strb	r2, [r3, #0x13]
   2c5a4: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c5a8: e5d32080     	ldrb	r2, [r3, #0x80]
   2c5ac: e5d33081     	ldrb	r3, [r3, #0x81]
   2c5b0: e1a03403     	lsl	r3, r3, #8
   2c5b4: e1833002     	orr	r3, r3, r2
   2c5b8: e14b34ba     	strh	r3, [r11, #-74]
   2c5bc: e15b34ba     	ldrh	r3, [r11, #-74]
   2c5c0: e1a03423     	lsr	r3, r3, #8
   2c5c4: e6ff3073     	uxth	r3, r3
   2c5c8: e1a02003     	mov	r2, r3
   2c5cc: e15b34ba     	ldrh	r3, [r11, #-74]
   2c5d0: e1a03403     	lsl	r3, r3, #8
   2c5d4: e1a03803     	lsl	r3, r3, #16
   2c5d8: e1a03823     	lsr	r3, r3, #16
   2c5dc: e1823003     	orr	r3, r2, r3
   2c5e0: e6ff2073     	uxth	r2, r3
   2c5e4: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c5e8: e20210ff     	and	r1, r2, #255
   2c5ec: e3a00000     	mov	r0, #0
   2c5f0: e1801001     	orr	r1, r0, r1
   2c5f4: e5c31080     	strb	r1, [r3, #0x80]
   2c5f8: e1a02422     	lsr	r2, r2, #8
   2c5fc: e6ff2072     	uxth	r2, r2
   2c600: e3a01000     	mov	r1, #0
   2c604: e1812002     	orr	r2, r1, r2
   2c608: e5c32081     	strb	r2, [r3, #0x81]
   2c60c: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c610: e5d32082     	ldrb	r2, [r3, #0x82]
   2c614: e5d33083     	ldrb	r3, [r3, #0x83]
   2c618: e1a03403     	lsl	r3, r3, #8
   2c61c: e1833002     	orr	r3, r3, r2
   2c620: e14b34b8     	strh	r3, [r11, #-72]
   2c624: e15b34b8     	ldrh	r3, [r11, #-72]
   2c628: e1a03423     	lsr	r3, r3, #8
   2c62c: e6ff3073     	uxth	r3, r3
   2c630: e1a02003     	mov	r2, r3
   2c634: e15b34b8     	ldrh	r3, [r11, #-72]
   2c638: e1a03403     	lsl	r3, r3, #8
   2c63c: e1a03803     	lsl	r3, r3, #16
   2c640: e1a03823     	lsr	r3, r3, #16
   2c644: e1823003     	orr	r3, r2, r3
   2c648: e6ff2073     	uxth	r2, r3
   2c64c: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c650: e20210ff     	and	r1, r2, #255
   2c654: e3a00000     	mov	r0, #0
   2c658: e1801001     	orr	r1, r0, r1
   2c65c: e5c31082     	strb	r1, [r3, #0x82]
   2c660: e1a02422     	lsr	r2, r2, #8
   2c664: e6ff2072     	uxth	r2, r2
   2c668: e3a01000     	mov	r1, #0
   2c66c: e1812002     	orr	r2, r1, r2
   2c670: e5c32083     	strb	r2, [r3, #0x83]
   2c674: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c678: e5d32084     	ldrb	r2, [r3, #0x84]
   2c67c: e5d33085     	ldrb	r3, [r3, #0x85]
   2c680: e1a03403     	lsl	r3, r3, #8
   2c684: e1833002     	orr	r3, r3, r2
   2c688: e14b34b6     	strh	r3, [r11, #-70]
   2c68c: e15b34b6     	ldrh	r3, [r11, #-70]
   2c690: e1a03423     	lsr	r3, r3, #8
   2c694: e6ff3073     	uxth	r3, r3
   2c698: e1a02003     	mov	r2, r3
   2c69c: e15b34b6     	ldrh	r3, [r11, #-70]
   2c6a0: e1a03403     	lsl	r3, r3, #8
   2c6a4: e1a03803     	lsl	r3, r3, #16
   2c6a8: e1a03823     	lsr	r3, r3, #16
   2c6ac: e1823003     	orr	r3, r2, r3
   2c6b0: e6ff2073     	uxth	r2, r3
   2c6b4: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c6b8: e20210ff     	and	r1, r2, #255
   2c6bc: e3a00000     	mov	r0, #0
   2c6c0: e1801001     	orr	r1, r0, r1
   2c6c4: e5c31084     	strb	r1, [r3, #0x84]
   2c6c8: e1a02422     	lsr	r2, r2, #8
   2c6cc: e6ff2072     	uxth	r2, r2
   2c6d0: e3a01000     	mov	r1, #0
   2c6d4: e1812002     	orr	r2, r1, r2
   2c6d8: e5c32085     	strb	r2, [r3, #0x85]
   2c6dc: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c6e0: e283300c     	add	r3, r3, #12
   2c6e4: e59f08f0     	ldr	r0, [pc, #0x8f0]        @ 0x2cfdc <scarletbook_read_area_toc+0xee8>
   2c6e8: e1a01003     	mov	r1, r3
   2c6ec: e3a02004     	mov	r2, #4
   2c6f0: ebff7ee0     	bl	0xc278 <memcmp@plt>     @ imm = #-0x20480
   2c6f4: e1a03000     	mov	r3, r0
   2c6f8: e3530000     	cmp	r3, #0
   2c6fc: 0a000025     	beq	0x2c798 <scarletbook_read_area_toc+0x6a4> @ imm = #0x94
   2c700: e59f38d0     	ldr	r3, [pc, #0x8d0]        @ 0x2cfd8 <scarletbook_read_area_toc+0xee4>
   2c704: e5933000     	ldr	r3, [r3]
   2c708: e1a02003     	mov	r2, r3
   2c70c: e59f38cc     	ldr	r3, [pc, #0x8cc]        @ 0x2cfe0 <scarletbook_read_area_toc+0xeec>
   2c710: e59f18cc     	ldr	r1, [pc, #0x8cc]        @ 0x2cfe4 <scarletbook_read_area_toc+0xef0>
   2c714: e58d1000     	str	r1, [sp]
   2c718: e1a00002     	mov	r0, r2
   2c71c: e1a01003     	mov	r1, r3
   2c720: e59f28c0     	ldr	r2, [pc, #0x8c0]        @ 0x2cfe8 <scarletbook_read_area_toc+0xef4>
   2c724: e59f38c0     	ldr	r3, [pc, #0x8c0]        @ 0x2cfec <scarletbook_read_area_toc+0xef8>
   2c728: ebff7fc5     	bl	0xc644 <fprintf@plt>    @ imm = #-0x200ec
   2c72c: e3a03000     	mov	r3, #0
   2c730: e50b3044     	str	r3, [r11, #-0x44]
   2c734: ea00000f     	b	0x2c778 <scarletbook_read_area_toc+0x684> @ imm = #0x3c
   2c738: e59f3898     	ldr	r3, [pc, #0x898]        @ 0x2cfd8 <scarletbook_read_area_toc+0xee4>
   2c73c: e5933000     	ldr	r3, [r3]
   2c740: e1a01003     	mov	r1, r3
   2c744: e59f28a4     	ldr	r2, [pc, #0x8a4]        @ 0x2cff0 <scarletbook_read_area_toc+0xefc>
   2c748: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c74c: e283000c     	add	r0, r3, #12
   2c750: e51b3044     	ldr	r3, [r11, #-0x44]
   2c754: e0803003     	add	r3, r0, r3
   2c758: e5d33000     	ldrb	r3, [r3]
   2c75c: e1a00001     	mov	r0, r1
   2c760: e1a01002     	mov	r1, r2
   2c764: e1a02003     	mov	r2, r3
   2c768: ebff7fb5     	bl	0xc644 <fprintf@plt>    @ imm = #-0x2012c
   2c76c: e51b3044     	ldr	r3, [r11, #-0x44]
   2c770: e2833001     	add	r3, r3, #1
   2c774: e50b3044     	str	r3, [r11, #-0x44]
   2c778: e51b3044     	ldr	r3, [r11, #-0x44]
   2c77c: e3530003     	cmp	r3, #3
   2c780: 9affffec     	bls	0x2c738 <scarletbook_read_area_toc+0x644> @ imm = #-0x50
   2c784: e59f384c     	ldr	r3, [pc, #0x84c]        @ 0x2cfd8 <scarletbook_read_area_toc+0xee4>
   2c788: e5933000     	ldr	r3, [r3]
   2c78c: e3a0000a     	mov	r0, #10
   2c790: e1a01003     	mov	r1, r3
   2c794: ebff7fc5     	bl	0xc6b0 <fputc@plt>      @ imm = #-0x200ec
   2c798: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c79c: e2833016     	add	r3, r3, #22
   2c7a0: e59f0834     	ldr	r0, [pc, #0x834]        @ 0x2cfdc <scarletbook_read_area_toc+0xee8>
   2c7a4: e1a01003     	mov	r1, r3
   2c7a8: e3a0200a     	mov	r2, #10
   2c7ac: ebff7eb1     	bl	0xc278 <memcmp@plt>     @ imm = #-0x2053c
   2c7b0: e1a03000     	mov	r3, r0
   2c7b4: e3530000     	cmp	r3, #0
   2c7b8: 0a000025     	beq	0x2c854 <scarletbook_read_area_toc+0x760> @ imm = #0x94
   2c7bc: e59f3814     	ldr	r3, [pc, #0x814]        @ 0x2cfd8 <scarletbook_read_area_toc+0xee4>
   2c7c0: e5933000     	ldr	r3, [r3]
   2c7c4: e1a02003     	mov	r2, r3
   2c7c8: e59f3810     	ldr	r3, [pc, #0x810]        @ 0x2cfe0 <scarletbook_read_area_toc+0xeec>
   2c7cc: e59f1820     	ldr	r1, [pc, #0x820]        @ 0x2cff4 <scarletbook_read_area_toc+0xf00>
   2c7d0: e58d1000     	str	r1, [sp]
   2c7d4: e1a00002     	mov	r0, r2
   2c7d8: e1a01003     	mov	r1, r3
   2c7dc: e59f2804     	ldr	r2, [pc, #0x804]        @ 0x2cfe8 <scarletbook_read_area_toc+0xef4>
   2c7e0: e59f3810     	ldr	r3, [pc, #0x810]        @ 0x2cff8 <scarletbook_read_area_toc+0xf04>
   2c7e4: ebff7f96     	bl	0xc644 <fprintf@plt>    @ imm = #-0x201a8
   2c7e8: e3a03000     	mov	r3, #0
   2c7ec: e50b3040     	str	r3, [r11, #-0x40]
   2c7f0: ea00000f     	b	0x2c834 <scarletbook_read_area_toc+0x740> @ imm = #0x3c
   2c7f4: e59f37dc     	ldr	r3, [pc, #0x7dc]        @ 0x2cfd8 <scarletbook_read_area_toc+0xee4>
   2c7f8: e5933000     	ldr	r3, [r3]
   2c7fc: e1a01003     	mov	r1, r3
   2c800: e59f27e8     	ldr	r2, [pc, #0x7e8]        @ 0x2cff0 <scarletbook_read_area_toc+0xefc>
   2c804: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c808: e2830016     	add	r0, r3, #22
   2c80c: e51b3040     	ldr	r3, [r11, #-0x40]
   2c810: e0803003     	add	r3, r0, r3
   2c814: e5d33000     	ldrb	r3, [r3]
   2c818: e1a00001     	mov	r0, r1
   2c81c: e1a01002     	mov	r1, r2
   2c820: e1a02003     	mov	r2, r3
   2c824: ebff7f86     	bl	0xc644 <fprintf@plt>    @ imm = #-0x201e8
   2c828: e51b3040     	ldr	r3, [r11, #-0x40]
   2c82c: e2833001     	add	r3, r3, #1
   2c830: e50b3040     	str	r3, [r11, #-0x40]
   2c834: e51b3040     	ldr	r3, [r11, #-0x40]
   2c838: e3530009     	cmp	r3, #9
   2c83c: 9affffec     	bls	0x2c7f4 <scarletbook_read_area_toc+0x700> @ imm = #-0x50
   2c840: e59f3790     	ldr	r3, [pc, #0x790]        @ 0x2cfd8 <scarletbook_read_area_toc+0xee4>
   2c844: e5933000     	ldr	r3, [r3]
   2c848: e3a0000a     	mov	r0, #10
   2c84c: e1a01003     	mov	r1, r3
   2c850: ebff7f96     	bl	0xc6b0 <fputc@plt>      @ imm = #-0x201a8
   2c854: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c858: e2833024     	add	r3, r3, #36
   2c85c: e59f0778     	ldr	r0, [pc, #0x778]        @ 0x2cfdc <scarletbook_read_area_toc+0xee8>
   2c860: e1a01003     	mov	r1, r3
   2c864: e3a0200c     	mov	r2, #12
   2c868: ebff7e82     	bl	0xc278 <memcmp@plt>     @ imm = #-0x205f8
   2c86c: e1a03000     	mov	r3, r0
   2c870: e3530000     	cmp	r3, #0
   2c874: 0a000025     	beq	0x2c910 <scarletbook_read_area_toc+0x81c> @ imm = #0x94
   2c878: e59f3758     	ldr	r3, [pc, #0x758]        @ 0x2cfd8 <scarletbook_read_area_toc+0xee4>
   2c87c: e5933000     	ldr	r3, [r3]
   2c880: e1a02003     	mov	r2, r3
   2c884: e59f3754     	ldr	r3, [pc, #0x754]        @ 0x2cfe0 <scarletbook_read_area_toc+0xeec>
   2c888: e59f176c     	ldr	r1, [pc, #0x76c]        @ 0x2cffc <scarletbook_read_area_toc+0xf08>
   2c88c: e58d1000     	str	r1, [sp]
   2c890: e1a00002     	mov	r0, r2
   2c894: e1a01003     	mov	r1, r3
   2c898: e59f2748     	ldr	r2, [pc, #0x748]        @ 0x2cfe8 <scarletbook_read_area_toc+0xef4>
   2c89c: e59f375c     	ldr	r3, [pc, #0x75c]        @ 0x2d000 <scarletbook_read_area_toc+0xf0c>
   2c8a0: ebff7f67     	bl	0xc644 <fprintf@plt>    @ imm = #-0x20264
   2c8a4: e3a03000     	mov	r3, #0
   2c8a8: e50b303c     	str	r3, [r11, #-0x3c]
   2c8ac: ea00000f     	b	0x2c8f0 <scarletbook_read_area_toc+0x7fc> @ imm = #0x3c
   2c8b0: e59f3720     	ldr	r3, [pc, #0x720]        @ 0x2cfd8 <scarletbook_read_area_toc+0xee4>
   2c8b4: e5933000     	ldr	r3, [r3]
   2c8b8: e1a01003     	mov	r1, r3
   2c8bc: e59f272c     	ldr	r2, [pc, #0x72c]        @ 0x2cff0 <scarletbook_read_area_toc+0xefc>
   2c8c0: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c8c4: e2830024     	add	r0, r3, #36
   2c8c8: e51b303c     	ldr	r3, [r11, #-0x3c]
   2c8cc: e0803003     	add	r3, r0, r3
   2c8d0: e5d33000     	ldrb	r3, [r3]
   2c8d4: e1a00001     	mov	r0, r1
   2c8d8: e1a01002     	mov	r1, r2
   2c8dc: e1a02003     	mov	r2, r3
   2c8e0: ebff7f57     	bl	0xc644 <fprintf@plt>    @ imm = #-0x202a4
   2c8e4: e51b303c     	ldr	r3, [r11, #-0x3c]
   2c8e8: e2833001     	add	r3, r3, #1
   2c8ec: e50b303c     	str	r3, [r11, #-0x3c]
   2c8f0: e51b303c     	ldr	r3, [r11, #-0x3c]
   2c8f4: e353000b     	cmp	r3, #11
   2c8f8: 9affffec     	bls	0x2c8b0 <scarletbook_read_area_toc+0x7bc> @ imm = #-0x50
   2c8fc: e59f36d4     	ldr	r3, [pc, #0x6d4]        @ 0x2cfd8 <scarletbook_read_area_toc+0xee4>
   2c900: e5933000     	ldr	r3, [r3]
   2c904: e3a0000a     	mov	r0, #10
   2c908: e1a01003     	mov	r1, r3
   2c90c: ebff7f67     	bl	0xc6b0 <fputc@plt>      @ imm = #-0x20264
   2c910: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c914: e2833031     	add	r3, r3, #49
   2c918: e59f06bc     	ldr	r0, [pc, #0x6bc]        @ 0x2cfdc <scarletbook_read_area_toc+0xee8>
   2c91c: e1a01003     	mov	r1, r3
   2c920: e3a0200f     	mov	r2, #15
   2c924: ebff7e53     	bl	0xc278 <memcmp@plt>     @ imm = #-0x206b4
   2c928: e1a03000     	mov	r3, r0
   2c92c: e3530000     	cmp	r3, #0
   2c930: 0a000025     	beq	0x2c9cc <scarletbook_read_area_toc+0x8d8> @ imm = #0x94
   2c934: e59f369c     	ldr	r3, [pc, #0x69c]        @ 0x2cfd8 <scarletbook_read_area_toc+0xee4>
   2c938: e5933000     	ldr	r3, [r3]
   2c93c: e1a02003     	mov	r2, r3
   2c940: e59f3698     	ldr	r3, [pc, #0x698]        @ 0x2cfe0 <scarletbook_read_area_toc+0xeec>
   2c944: e59f16b8     	ldr	r1, [pc, #0x6b8]        @ 0x2d004 <scarletbook_read_area_toc+0xf10>
   2c948: e58d1000     	str	r1, [sp]
   2c94c: e1a00002     	mov	r0, r2
   2c950: e1a01003     	mov	r1, r3
   2c954: e59f268c     	ldr	r2, [pc, #0x68c]        @ 0x2cfe8 <scarletbook_read_area_toc+0xef4>
   2c958: e3a03f62     	mov	r3, #392
   2c95c: ebff7f38     	bl	0xc644 <fprintf@plt>    @ imm = #-0x20320
   2c960: e3a03000     	mov	r3, #0
   2c964: e50b3038     	str	r3, [r11, #-0x38]
   2c968: ea00000f     	b	0x2c9ac <scarletbook_read_area_toc+0x8b8> @ imm = #0x3c
   2c96c: e59f3664     	ldr	r3, [pc, #0x664]        @ 0x2cfd8 <scarletbook_read_area_toc+0xee4>
   2c970: e5933000     	ldr	r3, [r3]
   2c974: e1a01003     	mov	r1, r3
   2c978: e59f2670     	ldr	r2, [pc, #0x670]        @ 0x2cff0 <scarletbook_read_area_toc+0xefc>
   2c97c: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c980: e2830031     	add	r0, r3, #49
   2c984: e51b3038     	ldr	r3, [r11, #-0x38]
   2c988: e0803003     	add	r3, r0, r3
   2c98c: e5d33000     	ldrb	r3, [r3]
   2c990: e1a00001     	mov	r0, r1
   2c994: e1a01002     	mov	r1, r2
   2c998: e1a02003     	mov	r2, r3
   2c99c: ebff7f28     	bl	0xc644 <fprintf@plt>    @ imm = #-0x20360
   2c9a0: e51b3038     	ldr	r3, [r11, #-0x38]
   2c9a4: e2833001     	add	r3, r3, #1
   2c9a8: e50b3038     	str	r3, [r11, #-0x38]
   2c9ac: e51b3038     	ldr	r3, [r11, #-0x38]
   2c9b0: e353000e     	cmp	r3, #14
   2c9b4: 9affffec     	bls	0x2c96c <scarletbook_read_area_toc+0x878> @ imm = #-0x50
   2c9b8: e59f3618     	ldr	r3, [pc, #0x618]        @ 0x2cfd8 <scarletbook_read_area_toc+0xee4>
   2c9bc: e5933000     	ldr	r3, [r3]
   2c9c0: e3a0000a     	mov	r0, #10
   2c9c4: e1a01003     	mov	r1, r3
   2c9c8: ebff7f38     	bl	0xc6b0 <fputc@plt>      @ imm = #-0x20320
   2c9cc: e59f3608     	ldr	r3, [pc, #0x608]        @ 0x2cfdc <scarletbook_read_area_toc+0xee8>
   2c9d0: e5d32000     	ldrb	r2, [r3]
   2c9d4: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c9d8: e2833043     	add	r3, r3, #67
   2c9dc: e5d33000     	ldrb	r3, [r3]
   2c9e0: e1520003     	cmp	r2, r3
   2c9e4: 0a000025     	beq	0x2ca80 <scarletbook_read_area_toc+0x98c> @ imm = #0x94
   2c9e8: e59f35e8     	ldr	r3, [pc, #0x5e8]        @ 0x2cfd8 <scarletbook_read_area_toc+0xee4>
   2c9ec: e5933000     	ldr	r3, [r3]
   2c9f0: e1a02003     	mov	r2, r3
   2c9f4: e59f35e4     	ldr	r3, [pc, #0x5e4]        @ 0x2cfe0 <scarletbook_read_area_toc+0xeec>
   2c9f8: e59f1608     	ldr	r1, [pc, #0x608]        @ 0x2d008 <scarletbook_read_area_toc+0xf14>
   2c9fc: e58d1000     	str	r1, [sp]
   2ca00: e1a00002     	mov	r0, r2
   2ca04: e1a01003     	mov	r1, r3
   2ca08: e59f25d8     	ldr	r2, [pc, #0x5d8]        @ 0x2cfe8 <scarletbook_read_area_toc+0xef4>
   2ca0c: e59f35f8     	ldr	r3, [pc, #0x5f8]        @ 0x2d00c <scarletbook_read_area_toc+0xf18>
   2ca10: ebff7f0b     	bl	0xc644 <fprintf@plt>    @ imm = #-0x203d4
   2ca14: e3a03000     	mov	r3, #0
   2ca18: e50b3034     	str	r3, [r11, #-0x34]
   2ca1c: ea00000f     	b	0x2ca60 <scarletbook_read_area_toc+0x96c> @ imm = #0x3c
   2ca20: e59f35b0     	ldr	r3, [pc, #0x5b0]        @ 0x2cfd8 <scarletbook_read_area_toc+0xee4>
   2ca24: e5933000     	ldr	r3, [r3]
   2ca28: e1a01003     	mov	r1, r3
   2ca2c: e59f25bc     	ldr	r2, [pc, #0x5bc]        @ 0x2cff0 <scarletbook_read_area_toc+0xefc>
   2ca30: e51b306c     	ldr	r3, [r11, #-0x6c]
   2ca34: e2830043     	add	r0, r3, #67
   2ca38: e51b3034     	ldr	r3, [r11, #-0x34]
   2ca3c: e0803003     	add	r3, r0, r3
   2ca40: e5d33000     	ldrb	r3, [r3]
   2ca44: e1a00001     	mov	r0, r1
   2ca48: e1a01002     	mov	r1, r2
   2ca4c: e1a02003     	mov	r2, r3
   2ca50: ebff7efb     	bl	0xc644 <fprintf@plt>    @ imm = #-0x20414
   2ca54: e51b3034     	ldr	r3, [r11, #-0x34]
   2ca58: e2833001     	add	r3, r3, #1
   2ca5c: e50b3034     	str	r3, [r11, #-0x34]
   2ca60: e51b3034     	ldr	r3, [r11, #-0x34]
   2ca64: e3530000     	cmp	r3, #0
   2ca68: 0affffec     	beq	0x2ca20 <scarletbook_read_area_toc+0x92c> @ imm = #-0x50
   2ca6c: e59f3564     	ldr	r3, [pc, #0x564]        @ 0x2cfd8 <scarletbook_read_area_toc+0xee4>
   2ca70: e5933000     	ldr	r3, [r3]
   2ca74: e3a0000a     	mov	r0, #10
   2ca78: e1a01003     	mov	r1, r3
   2ca7c: ebff7f0b     	bl	0xc6b0 <fputc@plt>      @ imm = #-0x203d4
   2ca80: e51b306c     	ldr	r3, [r11, #-0x6c]
   2ca84: e2833046     	add	r3, r3, #70
   2ca88: e59f054c     	ldr	r0, [pc, #0x54c]        @ 0x2cfdc <scarletbook_read_area_toc+0xee8>
   2ca8c: e1a01003     	mov	r1, r3
   2ca90: e3a02002     	mov	r2, #2
   2ca94: ebff7df7     	bl	0xc278 <memcmp@plt>     @ imm = #-0x20824
   2ca98: e1a03000     	mov	r3, r0
   2ca9c: e3530000     	cmp	r3, #0
   2caa0: 0a000025     	beq	0x2cb3c <scarletbook_read_area_toc+0xa48> @ imm = #0x94
   2caa4: e59f352c     	ldr	r3, [pc, #0x52c]        @ 0x2cfd8 <scarletbook_read_area_toc+0xee4>
   2caa8: e5933000     	ldr	r3, [r3]
   2caac: e1a02003     	mov	r2, r3
   2cab0: e59f3528     	ldr	r3, [pc, #0x528]        @ 0x2cfe0 <scarletbook_read_area_toc+0xeec>
   2cab4: e59f1554     	ldr	r1, [pc, #0x554]        @ 0x2d010 <scarletbook_read_area_toc+0xf1c>
   2cab8: e58d1000     	str	r1, [sp]
   2cabc: e1a00002     	mov	r0, r2
   2cac0: e1a01003     	mov	r1, r3
   2cac4: e59f251c     	ldr	r2, [pc, #0x51c]        @ 0x2cfe8 <scarletbook_read_area_toc+0xef4>
   2cac8: e59f3544     	ldr	r3, [pc, #0x544]        @ 0x2d014 <scarletbook_read_area_toc+0xf20>
   2cacc: ebff7edc     	bl	0xc644 <fprintf@plt>    @ imm = #-0x20490
   2cad0: e3a03000     	mov	r3, #0
   2cad4: e50b3030     	str	r3, [r11, #-0x30]
   2cad8: ea00000f     	b	0x2cb1c <scarletbook_read_area_toc+0xa28> @ imm = #0x3c
   2cadc: e59f34f4     	ldr	r3, [pc, #0x4f4]        @ 0x2cfd8 <scarletbook_read_area_toc+0xee4>
   2cae0: e5933000     	ldr	r3, [r3]
   2cae4: e1a01003     	mov	r1, r3
   2cae8: e59f2500     	ldr	r2, [pc, #0x500]        @ 0x2cff0 <scarletbook_read_area_toc+0xefc>
   2caec: e51b306c     	ldr	r3, [r11, #-0x6c]
   2caf0: e2830046     	add	r0, r3, #70
   2caf4: e51b3030     	ldr	r3, [r11, #-0x30]
   2caf8: e0803003     	add	r3, r0, r3
   2cafc: e5d33000     	ldrb	r3, [r3]
   2cb00: e1a00001     	mov	r0, r1
   2cb04: e1a01002     	mov	r1, r2
   2cb08: e1a02003     	mov	r2, r3
   2cb0c: ebff7ecc     	bl	0xc644 <fprintf@plt>    @ imm = #-0x204d0
   2cb10: e51b3030     	ldr	r3, [r11, #-0x30]
   2cb14: e2833001     	add	r3, r3, #1
   2cb18: e50b3030     	str	r3, [r11, #-0x30]
   2cb1c: e51b3030     	ldr	r3, [r11, #-0x30]
   2cb20: e3530001     	cmp	r3, #1
   2cb24: 9affffec     	bls	0x2cadc <scarletbook_read_area_toc+0x9e8> @ imm = #-0x50
   2cb28: e59f34a8     	ldr	r3, [pc, #0x4a8]        @ 0x2cfd8 <scarletbook_read_area_toc+0xee4>
   2cb2c: e5933000     	ldr	r3, [r3]
   2cb30: e3a0000a     	mov	r0, #10
   2cb34: e1a01003     	mov	r1, r3
   2cb38: ebff7edc     	bl	0xc6b0 <fputc@plt>      @ imm = #-0x20490
   2cb3c: e51b306c     	ldr	r3, [r11, #-0x6c]
   2cb40: e2833051     	add	r3, r3, #81
   2cb44: e59f0490     	ldr	r0, [pc, #0x490]        @ 0x2cfdc <scarletbook_read_area_toc+0xee8>
   2cb48: e1a01003     	mov	r1, r3
   2cb4c: e3a02007     	mov	r2, #7
   2cb50: ebff7dc8     	bl	0xc278 <memcmp@plt>     @ imm = #-0x208e0
   2cb54: e1a03000     	mov	r3, r0
   2cb58: e3530000     	cmp	r3, #0
   2cb5c: 0a000025     	beq	0x2cbf8 <scarletbook_read_area_toc+0xb04> @ imm = #0x94
   2cb60: e59f3470     	ldr	r3, [pc, #0x470]        @ 0x2cfd8 <scarletbook_read_area_toc+0xee4>
   2cb64: e5933000     	ldr	r3, [r3]
   2cb68: e1a02003     	mov	r2, r3
   2cb6c: e59f346c     	ldr	r3, [pc, #0x46c]        @ 0x2cfe0 <scarletbook_read_area_toc+0xeec>
   2cb70: e59f14a0     	ldr	r1, [pc, #0x4a0]        @ 0x2d018 <scarletbook_read_area_toc+0xf24>
   2cb74: e58d1000     	str	r1, [sp]
   2cb78: e1a00002     	mov	r0, r2
   2cb7c: e1a01003     	mov	r1, r3
   2cb80: e59f2460     	ldr	r2, [pc, #0x460]        @ 0x2cfe8 <scarletbook_read_area_toc+0xef4>
   2cb84: e59f3490     	ldr	r3, [pc, #0x490]        @ 0x2d01c <scarletbook_read_area_toc+0xf28>
   2cb88: ebff7ead     	bl	0xc644 <fprintf@plt>    @ imm = #-0x2054c
   2cb8c: e3a03000     	mov	r3, #0
   2cb90: e50b302c     	str	r3, [r11, #-0x2c]
   2cb94: ea00000f     	b	0x2cbd8 <scarletbook_read_area_toc+0xae4> @ imm = #0x3c
   2cb98: e59f3438     	ldr	r3, [pc, #0x438]        @ 0x2cfd8 <scarletbook_read_area_toc+0xee4>
   2cb9c: e5933000     	ldr	r3, [r3]
   2cba0: e1a01003     	mov	r1, r3
   2cba4: e59f2444     	ldr	r2, [pc, #0x444]        @ 0x2cff0 <scarletbook_read_area_toc+0xefc>
   2cba8: e51b306c     	ldr	r3, [r11, #-0x6c]
   2cbac: e2830051     	add	r0, r3, #81
   2cbb0: e51b302c     	ldr	r3, [r11, #-0x2c]
   2cbb4: e0803003     	add	r3, r0, r3
   2cbb8: e5d33000     	ldrb	r3, [r3]
   2cbbc: e1a00001     	mov	r0, r1
   2cbc0: e1a01002     	mov	r1, r2
   2cbc4: e1a02003     	mov	r2, r3
   2cbc8: ebff7e9d     	bl	0xc644 <fprintf@plt>    @ imm = #-0x2058c
   2cbcc: e51b302c     	ldr	r3, [r11, #-0x2c]
   2cbd0: e2833001     	add	r3, r3, #1
   2cbd4: e50b302c     	str	r3, [r11, #-0x2c]
   2cbd8: e51b302c     	ldr	r3, [r11, #-0x2c]
   2cbdc: e3530006     	cmp	r3, #6
   2cbe0: 9affffec     	bls	0x2cb98 <scarletbook_read_area_toc+0xaa4> @ imm = #-0x50
   2cbe4: e59f33ec     	ldr	r3, [pc, #0x3ec]        @ 0x2cfd8 <scarletbook_read_area_toc+0xee4>
   2cbe8: e5933000     	ldr	r3, [r3]
   2cbec: e3a0000a     	mov	r0, #10
   2cbf0: e1a01003     	mov	r1, r3
   2cbf4: ebff7ead     	bl	0xc6b0 <fputc@plt>      @ imm = #-0x2054c
   2cbf8: e51b306c     	ldr	r3, [r11, #-0x6c]
   2cbfc: e2833086     	add	r3, r3, #134
   2cc00: e59f03d4     	ldr	r0, [pc, #0x3d4]        @ 0x2cfdc <scarletbook_read_area_toc+0xee8>
   2cc04: e1a01003     	mov	r1, r3
   2cc08: e3a0200a     	mov	r2, #10
   2cc0c: ebff7d99     	bl	0xc278 <memcmp@plt>     @ imm = #-0x2099c
   2cc10: e1a03000     	mov	r3, r0
   2cc14: e3530000     	cmp	r3, #0
   2cc18: 0a000025     	beq	0x2ccb4 <scarletbook_read_area_toc+0xbc0> @ imm = #0x94
   2cc1c: e59f33b4     	ldr	r3, [pc, #0x3b4]        @ 0x2cfd8 <scarletbook_read_area_toc+0xee4>
   2cc20: e5933000     	ldr	r3, [r3]
   2cc24: e1a02003     	mov	r2, r3
   2cc28: e59f33b0     	ldr	r3, [pc, #0x3b0]        @ 0x2cfe0 <scarletbook_read_area_toc+0xeec>
   2cc2c: e59f13ec     	ldr	r1, [pc, #0x3ec]        @ 0x2d020 <scarletbook_read_area_toc+0xf2c>
   2cc30: e58d1000     	str	r1, [sp]
   2cc34: e1a00002     	mov	r0, r2
   2cc38: e1a01003     	mov	r1, r3
   2cc3c: e59f23a4     	ldr	r2, [pc, #0x3a4]        @ 0x2cfe8 <scarletbook_read_area_toc+0xef4>
   2cc40: e3a03f63     	mov	r3, #396
   2cc44: ebff7e7e     	bl	0xc644 <fprintf@plt>    @ imm = #-0x20608
   2cc48: e3a03000     	mov	r3, #0
   2cc4c: e50b3028     	str	r3, [r11, #-0x28]
   2cc50: ea00000f     	b	0x2cc94 <scarletbook_read_area_toc+0xba0> @ imm = #0x3c
   2cc54: e59f337c     	ldr	r3, [pc, #0x37c]        @ 0x2cfd8 <scarletbook_read_area_toc+0xee4>
   2cc58: e5933000     	ldr	r3, [r3]
   2cc5c: e1a01003     	mov	r1, r3
   2cc60: e59f2388     	ldr	r2, [pc, #0x388]        @ 0x2cff0 <scarletbook_read_area_toc+0xefc>
   2cc64: e51b306c     	ldr	r3, [r11, #-0x6c]
   2cc68: e2830086     	add	r0, r3, #134
   2cc6c: e51b3028     	ldr	r3, [r11, #-0x28]
   2cc70: e0803003     	add	r3, r0, r3
   2cc74: e5d33000     	ldrb	r3, [r3]
   2cc78: e1a00001     	mov	r0, r1
   2cc7c: e1a01002     	mov	r1, r2
   2cc80: e1a02003     	mov	r2, r3
   2cc84: ebff7e6e     	bl	0xc644 <fprintf@plt>    @ imm = #-0x20648
   2cc88: e51b3028     	ldr	r3, [r11, #-0x28]
   2cc8c: e2833001     	add	r3, r3, #1
   2cc90: e50b3028     	str	r3, [r11, #-0x28]
   2cc94: e51b3028     	ldr	r3, [r11, #-0x28]
   2cc98: e3530009     	cmp	r3, #9
   2cc9c: 9affffec     	bls	0x2cc54 <scarletbook_read_area_toc+0xb60> @ imm = #-0x50
   2cca0: e59f3330     	ldr	r3, [pc, #0x330]        @ 0x2cfd8 <scarletbook_read_area_toc+0xee4>
   2cca4: e5933000     	ldr	r3, [r3]
   2cca8: e3a0000a     	mov	r0, #10
   2ccac: e1a01003     	mov	r1, r3
   2ccb0: ebff7e7e     	bl	0xc6b0 <fputc@plt>      @ imm = #-0x20608
   2ccb4: e51b305c     	ldr	r3, [r11, #-0x5c]
   2ccb8: e5931004     	ldr	r1, [r3, #0x4]
   2ccbc: e51b3060     	ldr	r3, [r11, #-0x60]
   2ccc0: e2832016     	add	r2, r3, #22
   2ccc4: e3a03002     	mov	r3, #2
   2ccc8: e1a02102     	lsl	r2, r2, #2
   2cccc: e0812002     	add	r2, r1, r2
   2ccd0: e0823003     	add	r3, r2, r3
   2ccd4: e5d33000     	ldrb	r3, [r3]
   2ccd8: e2032007     	and	r2, r3, #7
   2ccdc: e59f3340     	ldr	r3, [pc, #0x340]        @ 0x2d024 <scarletbook_read_area_toc+0xf30>
   2cce0: e7933102     	ldr	r3, [r3, r2, lsl #2]
   2cce4: e50b3058     	str	r3, [r11, #-0x58]
   2cce8: e51b306c     	ldr	r3, [r11, #-0x6c]
   2ccec: e5d32092     	ldrb	r2, [r3, #0x92]
   2ccf0: e5d33093     	ldrb	r3, [r3, #0x93]
   2ccf4: e1a03403     	lsl	r3, r3, #8
   2ccf8: e1833002     	orr	r3, r3, r2
   2ccfc: e6ff3073     	uxth	r3, r3
   2cd00: e3530000     	cmp	r3, #0
   2cd04: 0a00001b     	beq	0x2cd78 <scarletbook_read_area_toc+0xc84> @ imm = #0x6c
   2cd08: e51b206c     	ldr	r2, [r11, #-0x6c]
   2cd0c: e51b306c     	ldr	r3, [r11, #-0x6c]
   2cd10: e5d31092     	ldrb	r1, [r3, #0x92]
   2cd14: e5d33093     	ldrb	r3, [r3, #0x93]
   2cd18: e1a03403     	lsl	r3, r3, #8
   2cd1c: e1833001     	orr	r3, r3, r1
   2cd20: e6ff3073     	uxth	r3, r3
   2cd24: e0824003     	add	r4, r2, r3
   2cd28: e51b206c     	ldr	r2, [r11, #-0x6c]
   2cd2c: e51b306c     	ldr	r3, [r11, #-0x6c]
   2cd30: e5d31092     	ldrb	r1, [r3, #0x92]
   2cd34: e5d33093     	ldrb	r3, [r3, #0x93]
   2cd38: e1a03403     	lsl	r3, r3, #8
   2cd3c: e1833001     	orr	r3, r3, r1
   2cd40: e6ff3073     	uxth	r3, r3
   2cd44: e0823003     	add	r3, r2, r3
   2cd48: e1a00003     	mov	r0, r3
   2cd4c: ebff7de2     	bl	0xc4dc <strlen@plt>     @ imm = #-0x20878
   2cd50: e1a03000     	mov	r3, r0
   2cd54: e1a00004     	mov	r0, r4
   2cd58: e1a01003     	mov	r1, r3
   2cd5c: e51b2058     	ldr	r2, [r11, #-0x58]
   2cd60: e59f32cc     	ldr	r3, [pc, #0x2cc]        @ 0x2d034 <scarletbook_read_area_toc+0xf40>
   2cd64: ebff85e2     	bl	0xe4f4 <charset_convert> @ imm = #-0x1e878
   2cd68: e1a01000     	mov	r1, r0
   2cd6c: e51b205c     	ldr	r2, [r11, #-0x5c]
   2cd70: e59f32b0     	ldr	r3, [pc, #0x2b0]        @ 0x2d028 <scarletbook_read_area_toc+0xf34>
   2cd74: e7821003     	str	r1, [r2, r3]
   2cd78: e51b306c     	ldr	r3, [r11, #-0x6c]
   2cd7c: e5d32096     	ldrb	r2, [r3, #0x96]
   2cd80: e5d33097     	ldrb	r3, [r3, #0x97]
   2cd84: e1a03403     	lsl	r3, r3, #8
   2cd88: e1833002     	orr	r3, r3, r2
   2cd8c: e6ff3073     	uxth	r3, r3
   2cd90: e3530000     	cmp	r3, #0
   2cd94: 0a00001b     	beq	0x2ce08 <scarletbook_read_area_toc+0xd14> @ imm = #0x6c
   2cd98: e51b206c     	ldr	r2, [r11, #-0x6c]
   2cd9c: e51b306c     	ldr	r3, [r11, #-0x6c]
   2cda0: e5d31096     	ldrb	r1, [r3, #0x96]
   2cda4: e5d33097     	ldrb	r3, [r3, #0x97]
   2cda8: e1a03403     	lsl	r3, r3, #8
   2cdac: e1833001     	orr	r3, r3, r1
   2cdb0: e6ff3073     	uxth	r3, r3
   2cdb4: e0824003     	add	r4, r2, r3
   2cdb8: e51b206c     	ldr	r2, [r11, #-0x6c]
   2cdbc: e51b306c     	ldr	r3, [r11, #-0x6c]
   2cdc0: e5d31096     	ldrb	r1, [r3, #0x96]
   2cdc4: e5d33097     	ldrb	r3, [r3, #0x97]
   2cdc8: e1a03403     	lsl	r3, r3, #8
   2cdcc: e1833001     	orr	r3, r3, r1
   2cdd0: e6ff3073     	uxth	r3, r3
   2cdd4: e0823003     	add	r3, r2, r3
   2cdd8: e1a00003     	mov	r0, r3
   2cddc: ebff7dbe     	bl	0xc4dc <strlen@plt>     @ imm = #-0x20908
   2cde0: e1a03000     	mov	r3, r0
   2cde4: e1a00004     	mov	r0, r4
   2cde8: e1a01003     	mov	r1, r3
   2cdec: e51b2058     	ldr	r2, [r11, #-0x58]
   2cdf0: e59f323c     	ldr	r3, [pc, #0x23c]        @ 0x2d034 <scarletbook_read_area_toc+0xf40>
   2cdf4: ebff85be     	bl	0xe4f4 <charset_convert> @ imm = #-0x1e908
   2cdf8: e1a01000     	mov	r1, r0
   2cdfc: e51b205c     	ldr	r2, [r11, #-0x5c]
   2ce00: e59f3220     	ldr	r3, [pc, #0x220]        @ 0x2d028 <scarletbook_read_area_toc+0xf34>
   2ce04: e7821003     	str	r1, [r2, r3]
   2ce08: e51b306c     	ldr	r3, [r11, #-0x6c]
   2ce0c: e5d32090     	ldrb	r2, [r3, #0x90]
   2ce10: e5d33091     	ldrb	r3, [r3, #0x91]
   2ce14: e1a03403     	lsl	r3, r3, #8
   2ce18: e1833002     	orr	r3, r3, r2
   2ce1c: e6ff3073     	uxth	r3, r3
   2ce20: e3530000     	cmp	r3, #0
   2ce24: 0a00001b     	beq	0x2ce98 <scarletbook_read_area_toc+0xda4> @ imm = #0x6c
   2ce28: e51b206c     	ldr	r2, [r11, #-0x6c]
   2ce2c: e51b306c     	ldr	r3, [r11, #-0x6c]
   2ce30: e5d31090     	ldrb	r1, [r3, #0x90]
   2ce34: e5d33091     	ldrb	r3, [r3, #0x91]
   2ce38: e1a03403     	lsl	r3, r3, #8
   2ce3c: e1833001     	orr	r3, r3, r1
   2ce40: e6ff3073     	uxth	r3, r3
   2ce44: e0824003     	add	r4, r2, r3
   2ce48: e51b206c     	ldr	r2, [r11, #-0x6c]
   2ce4c: e51b306c     	ldr	r3, [r11, #-0x6c]
   2ce50: e5d31090     	ldrb	r1, [r3, #0x90]
   2ce54: e5d33091     	ldrb	r3, [r3, #0x91]
   2ce58: e1a03403     	lsl	r3, r3, #8
   2ce5c: e1833001     	orr	r3, r3, r1
   2ce60: e6ff3073     	uxth	r3, r3
   2ce64: e0823003     	add	r3, r2, r3
   2ce68: e1a00003     	mov	r0, r3
   2ce6c: ebff7d9a     	bl	0xc4dc <strlen@plt>     @ imm = #-0x20998
   2ce70: e1a03000     	mov	r3, r0
   2ce74: e1a00004     	mov	r0, r4
   2ce78: e1a01003     	mov	r1, r3
   2ce7c: e51b2058     	ldr	r2, [r11, #-0x58]
   2ce80: e59f31ac     	ldr	r3, [pc, #0x1ac]        @ 0x2d034 <scarletbook_read_area_toc+0xf40>
   2ce84: ebff859a     	bl	0xe4f4 <charset_convert> @ imm = #-0x1e998
   2ce88: e1a01000     	mov	r1, r0
   2ce8c: e51b205c     	ldr	r2, [r11, #-0x5c]
   2ce90: e59f3190     	ldr	r3, [pc, #0x190]        @ 0x2d028 <scarletbook_read_area_toc+0xf34>
   2ce94: e7821003     	str	r1, [r2, r3]
   2ce98: e51b306c     	ldr	r3, [r11, #-0x6c]
   2ce9c: e5d32094     	ldrb	r2, [r3, #0x94]
   2cea0: e5d33095     	ldrb	r3, [r3, #0x95]
   2cea4: e1a03403     	lsl	r3, r3, #8
   2cea8: e1833002     	orr	r3, r3, r2
   2ceac: e6ff3073     	uxth	r3, r3
   2ceb0: e3530000     	cmp	r3, #0
   2ceb4: 0a00001b     	beq	0x2cf28 <scarletbook_read_area_toc+0xe34> @ imm = #0x6c
   2ceb8: e51b206c     	ldr	r2, [r11, #-0x6c]
   2cebc: e51b306c     	ldr	r3, [r11, #-0x6c]
   2cec0: e5d31094     	ldrb	r1, [r3, #0x94]
   2cec4: e5d33095     	ldrb	r3, [r3, #0x95]
   2cec8: e1a03403     	lsl	r3, r3, #8
   2cecc: e1833001     	orr	r3, r3, r1
   2ced0: e6ff3073     	uxth	r3, r3
   2ced4: e0824003     	add	r4, r2, r3
   2ced8: e51b206c     	ldr	r2, [r11, #-0x6c]
   2cedc: e51b306c     	ldr	r3, [r11, #-0x6c]
   2cee0: e5d31094     	ldrb	r1, [r3, #0x94]
   2cee4: e5d33095     	ldrb	r3, [r3, #0x95]
   2cee8: e1a03403     	lsl	r3, r3, #8
   2ceec: e1833001     	orr	r3, r3, r1
   2cef0: e6ff3073     	uxth	r3, r3
   2cef4: e0823003     	add	r3, r2, r3
   2cef8: e1a00003     	mov	r0, r3
   2cefc: ebff7d76     	bl	0xc4dc <strlen@plt>     @ imm = #-0x20a28
   2cf00: e1a03000     	mov	r3, r0
   2cf04: e1a00004     	mov	r0, r4
   2cf08: e1a01003     	mov	r1, r3
   2cf0c: e51b2058     	ldr	r2, [r11, #-0x58]
   2cf10: e59f311c     	ldr	r3, [pc, #0x11c]        @ 0x2d034 <scarletbook_read_area_toc+0xf40>
   2cf14: ebff8576     	bl	0xe4f4 <charset_convert> @ imm = #-0x1ea28
   2cf18: e1a01000     	mov	r1, r0
   2cf1c: e51b205c     	ldr	r2, [r11, #-0x5c]
   2cf20: e59f3100     	ldr	r3, [pc, #0x100]        @ 0x2d028 <scarletbook_read_area_toc+0xf34>
   2cf24: e7821003     	str	r1, [r2, r3]
   2cf28: e51b306c     	ldr	r3, [r11, #-0x6c]
   2cf2c: e5d33008     	ldrb	r3, [r3, #0x8]
   2cf30: e3530001     	cmp	r3, #1
   2cf34: 8a000003     	bhi	0x2cf48 <scarletbook_read_area_toc+0xe54> @ imm = #0xc
   2cf38: e51b306c     	ldr	r3, [r11, #-0x6c]
   2cf3c: e5d33009     	ldrb	r3, [r3, #0x9]
   2cf40: e3530014     	cmp	r3, #20
   2cf44: 9a00000b     	bls	0x2cf78 <scarletbook_read_area_toc+0xe84> @ imm = #0x2c
   2cf48: e59f3088     	ldr	r3, [pc, #0x88]         @ 0x2cfd8 <scarletbook_read_area_toc+0xee4>
   2cf4c: e5933000     	ldr	r3, [r3]
   2cf50: e1a00003     	mov	r0, r3
   2cf54: e59f10d0     	ldr	r1, [pc, #0xd0]         @ 0x2d02c <scarletbook_read_area_toc+0xf38>
   2cf58: e51b306c     	ldr	r3, [r11, #-0x6c]
   2cf5c: e5d33008     	ldrb	r3, [r3, #0x8]
   2cf60: e1a02003     	mov	r2, r3
   2cf64: e51b306c     	ldr	r3, [r11, #-0x6c]
   2cf68: e5d33009     	ldrb	r3, [r3, #0x9]
   2cf6c: ebff7db4     	bl	0xc644 <fprintf@plt>    @ imm = #-0x20930
   2cf70: e3a03000     	mov	r3, #0
   2cf74: ea00035b     	b	0x2dce8 <scarletbook_read_area_toc+0x1bf4> @ imm = #0xd6c
   2cf78: e51b306c     	ldr	r3, [r11, #-0x6c]
   2cf7c: e5d33020     	ldrb	r3, [r3, #0x20]
   2cf80: e3530002     	cmp	r3, #2
   2cf84: 1a000008     	bne	0x2cfac <scarletbook_read_area_toc+0xeb8> @ imm = #0x20
   2cf88: e51b306c     	ldr	r3, [r11, #-0x6c]
   2cf8c: e5d33021     	ldrb	r3, [r3, #0x21]
   2cf90: e20330f8     	and	r3, r3, #248
   2cf94: e3530000     	cmp	r3, #0
   2cf98: 1a000003     	bne	0x2cfac <scarletbook_read_area_toc+0xeb8> @ imm = #0xc
   2cf9c: e51b3078     	ldr	r3, [r11, #-0x78]
   2cfa0: e51b207c     	ldr	r2, [r11, #-0x7c]
   2cfa4: e5832050     	str	r2, [r3, #0x50]
   2cfa8: ea000002     	b	0x2cfb8 <scarletbook_read_area_toc+0xec4> @ imm = #0x8
   2cfac: e51b3078     	ldr	r3, [r11, #-0x78]
   2cfb0: e51b207c     	ldr	r2, [r11, #-0x7c]
   2cfb4: e5832054     	str	r2, [r3, #0x54]
   2cfb8: e51b3064     	ldr	r3, [r11, #-0x64]
   2cfbc: e2833b02     	add	r3, r3, #2048
   2cfc0: e50b3064     	str	r3, [r11, #-0x64]
   2cfc4: ea000338     	b	0x2dcac <scarletbook_read_area_toc+0x1bb8> @ imm = #0xce0
   2cfc8: f0 37 00 00  	.word	0x000037f0
   2cfcc: a4 5c 03 00  	.word	0x00035ca4
   2cfd0: b0 5c 03 00  	.word	0x00035cb0
   2cfd4: bc 5c 03 00  	.word	0x00035cbc
   2cfd8: f8 6d 05 00  	.word	0x00056df8
   2cfdc: c0 95 05 00  	.word	0x000595c0
   2cfe0: d0 59 03 00  	.word	0x000359d0
   2cfe4: e0 5c 03 00  	.word	0x00035ce0
   2cfe8: 00 5a 03 00  	.word	0x00035a00
   2cfec: 85 01 00 00  	.word	0x00000185
   2cff0: 4c 5a 03 00  	.word	0x00035a4c
   2cff4: f8 5c 03 00  	.word	0x00035cf8
   2cff8: 86 01 00 00  	.word	0x00000186
   2cffc: 10 5d 03 00  	.word	0x00035d10
   2d000: 87 01 00 00  	.word	0x00000187
   2d004: 28 5d 03 00  	.word	0x00035d28
   2d008: 40 5d 03 00  	.word	0x00035d40
   2d00c: 89 01 00 00  	.word	0x00000189
   2d010: 58 5d 03 00  	.word	0x00035d58
   2d014: 8a 01 00 00  	.word	0x0000018a
   2d018: 70 5d 03 00  	.word	0x00035d70
   2d01c: 8b 01 00 00  	.word	0x0000018b
   2d020: 88 5d 03 00  	.word	0x00035d88
   2d024: 38 ef 03 00  	.word	0x0003ef38
   2d028: e8 37 00 00  	.word	0x000037e8
   2d02c: a0 5d 03 00  	.word	0x00035da0
   2d030: cc 5d 03 00  	.word	0x00035dcc
   2d034: 90 5c 03 00  	.word	0x00035c90
   2d038: d8 5d 03 00  	.word	0x00035dd8
   2d03c: dc 37 00 00  	.word	0x000037dc
   2d040: e4 5d 03 00  	.word	0x00035de4
   2d044: f0 5d 03 00  	.word	0x00035df0
   2d048: fc 5d 03 00  	.word	0x00035dfc
   2d04c: e51b0064     	ldr	r0, [r11, #-0x64]
   2d050: e51f1028     	ldr	r1, [pc, #-0x28]        @ 0x2d030 <scarletbook_read_area_toc+0xf3c>
   2d054: e3a02008     	mov	r2, #8
   2d058: ebff7dc4     	bl	0xc770 <strncmp@plt>    @ imm = #-0x208f0
   2d05c: e1a03000     	mov	r3, r0
   2d060: e3530000     	cmp	r3, #0
   2d064: 1a000235     	bne	0x2d940 <scarletbook_read_area_toc+0x184c> @ imm = #0x8d4
   2d068: e51b3060     	ldr	r3, [r11, #-0x60]
   2d06c: e3530000     	cmp	r3, #0
   2d070: 1a00022b     	bne	0x2d924 <scarletbook_read_area_toc+0x1830> @ imm = #0x8ac
   2d074: e3a03000     	mov	r3, #0
   2d078: e50b3074     	str	r3, [r11, #-0x74]
   2d07c: ea000222     	b	0x2d90c <scarletbook_read_area_toc+0x1818> @ imm = #0x888
   2d080: e51b2064     	ldr	r2, [r11, #-0x64]
   2d084: e51b305c     	ldr	r3, [r11, #-0x5c]
   2d088: e5832010     	str	r2, [r3, #0x10]
   2d08c: e51b305c     	ldr	r3, [r11, #-0x5c]
   2d090: e5933010     	ldr	r3, [r3, #0x10]
   2d094: e50b3024     	str	r3, [r11, #-0x24]
   2d098: e51b0074     	ldr	r0, [r11, #-0x74]
   2d09c: e51b2074     	ldr	r2, [r11, #-0x74]
   2d0a0: e51b3024     	ldr	r3, [r11, #-0x24]
   2d0a4: e2822004     	add	r2, r2, #4
   2d0a8: e7d31082     	ldrb	r1, [r3, r2, lsl #1]
   2d0ac: e3a0c001     	mov	r12, #1
   2d0b0: e1a02082     	lsl	r2, r2, #1
   2d0b4: e0833002     	add	r3, r3, r2
   2d0b8: e083300c     	add	r3, r3, r12
   2d0bc: e5d33000     	ldrb	r3, [r3]
   2d0c0: e1a03403     	lsl	r3, r3, #8
   2d0c4: e1833001     	orr	r3, r3, r1
   2d0c8: e14b31b6     	strh	r3, [r11, #-22]
   2d0cc: e15b31b6     	ldrh	r3, [r11, #-22]
   2d0d0: e1a03423     	lsr	r3, r3, #8
   2d0d4: e6ff3073     	uxth	r3, r3
   2d0d8: e1a02003     	mov	r2, r3
   2d0dc: e15b31b6     	ldrh	r3, [r11, #-22]
   2d0e0: e1a03403     	lsl	r3, r3, #8
   2d0e4: e1a03803     	lsl	r3, r3, #16
   2d0e8: e1a03823     	lsr	r3, r3, #16
   2d0ec: e1823003     	orr	r3, r2, r3
   2d0f0: e6ff1073     	uxth	r1, r3
   2d0f4: e51b3024     	ldr	r3, [r11, #-0x24]
   2d0f8: e2802004     	add	r2, r0, #4
   2d0fc: e20100ff     	and	r0, r1, #255
   2d100: e3a0c000     	mov	r12, #0
   2d104: e18c0000     	orr	r0, r12, r0
   2d108: e7c30082     	strb	r0, [r3, r2, lsl #1]
   2d10c: e1a01421     	lsr	r1, r1, #8
   2d110: e6ff0071     	uxth	r0, r1
   2d114: e3a01001     	mov	r1, #1
   2d118: e1a02082     	lsl	r2, r2, #1
   2d11c: e0833002     	add	r3, r3, r2
   2d120: e0833001     	add	r3, r3, r1
   2d124: e3a02000     	mov	r2, #0
   2d128: e1a01002     	mov	r1, r2
   2d12c: e1a02000     	mov	r2, r0
   2d130: e1812002     	orr	r2, r1, r2
   2d134: e5c32000     	strb	r2, [r3]
   2d138: e51b2074     	ldr	r2, [r11, #-0x74]
   2d13c: e51b3024     	ldr	r3, [r11, #-0x24]
   2d140: e2822004     	add	r2, r2, #4
   2d144: e7d31082     	ldrb	r1, [r3, r2, lsl #1]
   2d148: e3a00001     	mov	r0, #1
   2d14c: e1a02082     	lsl	r2, r2, #1
   2d150: e0833002     	add	r3, r3, r2
   2d154: e0833000     	add	r3, r3, r0
   2d158: e5d33000     	ldrb	r3, [r3]
   2d15c: e1a03403     	lsl	r3, r3, #8
   2d160: e1833001     	orr	r3, r3, r1
   2d164: e6ff3073     	uxth	r3, r3
   2d168: e3530000     	cmp	r3, #0
   2d16c: 0a0001e3     	beq	0x2d900 <scarletbook_read_area_toc+0x180c> @ imm = #0x78c
   2d170: e51b2074     	ldr	r2, [r11, #-0x74]
   2d174: e51b3024     	ldr	r3, [r11, #-0x24]
   2d178: e2822004     	add	r2, r2, #4
   2d17c: e7d31082     	ldrb	r1, [r3, r2, lsl #1]
   2d180: e3a00001     	mov	r0, #1
   2d184: e1a02082     	lsl	r2, r2, #1
   2d188: e0833002     	add	r3, r3, r2
   2d18c: e0833000     	add	r3, r3, r0
   2d190: e5d33000     	ldrb	r3, [r3]
   2d194: e1a03403     	lsl	r3, r3, #8
   2d198: e1833001     	orr	r3, r3, r1
   2d19c: e6ff3073     	uxth	r3, r3
   2d1a0: e51b2064     	ldr	r2, [r11, #-0x64]
   2d1a4: e0823003     	add	r3, r2, r3
   2d1a8: e50b301c     	str	r3, [r11, #-0x1c]
   2d1ac: e51b301c     	ldr	r3, [r11, #-0x1c]
   2d1b0: e5d33000     	ldrb	r3, [r3]
   2d1b4: e54b301d     	strb	r3, [r11, #-0x1d]
   2d1b8: e51b301c     	ldr	r3, [r11, #-0x1c]
   2d1bc: e2833004     	add	r3, r3, #4
   2d1c0: e50b301c     	str	r3, [r11, #-0x1c]
   2d1c4: e3a03000     	mov	r3, #0
   2d1c8: e50b3070     	str	r3, [r11, #-0x70]
   2d1cc: ea0001c7     	b	0x2d8f0 <scarletbook_read_area_toc+0x17fc> @ imm = #0x71c
   2d1d0: e51b301c     	ldr	r3, [r11, #-0x1c]
   2d1d4: e5d33000     	ldrb	r3, [r3]
   2d1d8: e54b301e     	strb	r3, [r11, #-0x1e]
   2d1dc: e51b301c     	ldr	r3, [r11, #-0x1c]
   2d1e0: e2833001     	add	r3, r3, #1
   2d1e4: e50b301c     	str	r3, [r11, #-0x1c]
   2d1e8: e51b301c     	ldr	r3, [r11, #-0x1c]
   2d1ec: e2833001     	add	r3, r3, #1
   2d1f0: e50b301c     	str	r3, [r11, #-0x1c]
   2d1f4: e51b301c     	ldr	r3, [r11, #-0x1c]
   2d1f8: e5d33000     	ldrb	r3, [r3]
   2d1fc: e3530000     	cmp	r3, #0
   2d200: 0a0001a2     	beq	0x2d890 <scarletbook_read_area_toc+0x179c> @ imm = #0x688
   2d204: e55b301e     	ldrb	r3, [r11, #-0x1e]
   2d208: e2433001     	sub	r3, r3, #1
   2d20c: e3530086     	cmp	r3, #134
   2d210: 979ff103     	ldrls	pc, [pc, r3, lsl #2]
   2d214: ea00019d     	b	0x2d890 <scarletbook_read_area_toc+0x179c> @ imm = #0x674
   2d218: 34 d4 02 00  	.word	0x0002d434
   2d21c: 84 d4 02 00  	.word	0x0002d484
   2d220: d4 d4 02 00  	.word	0x0002d4d4
   2d224: 24 d5 02 00  	.word	0x0002d524
   2d228: 74 d5 02 00  	.word	0x0002d574
   2d22c: c4 d5 02 00  	.word	0x0002d5c4
   2d230: 14 d6 02 00  	.word	0x0002d614
   2d234: 90 d8 02 00  	.word	0x0002d890
   2d238: 90 d8 02 00  	.word	0x0002d890
   2d23c: 90 d8 02 00  	.word	0x0002d890
   2d240: 90 d8 02 00  	.word	0x0002d890
   2d244: 90 d8 02 00  	.word	0x0002d890
   2d248: 90 d8 02 00  	.word	0x0002d890
   2d24c: 90 d8 02 00  	.word	0x0002d890
   2d250: 90 d8 02 00  	.word	0x0002d890
   2d254: 90 d8 02 00  	.word	0x0002d890
   2d258: 90 d8 02 00  	.word	0x0002d890
   2d25c: 90 d8 02 00  	.word	0x0002d890
   2d260: 90 d8 02 00  	.word	0x0002d890
   2d264: 90 d8 02 00  	.word	0x0002d890
   2d268: 90 d8 02 00  	.word	0x0002d890
   2d26c: 90 d8 02 00  	.word	0x0002d890
   2d270: 90 d8 02 00  	.word	0x0002d890
   2d274: 90 d8 02 00  	.word	0x0002d890
   2d278: 90 d8 02 00  	.word	0x0002d890
   2d27c: 90 d8 02 00  	.word	0x0002d890
   2d280: 90 d8 02 00  	.word	0x0002d890
   2d284: 90 d8 02 00  	.word	0x0002d890
   2d288: 90 d8 02 00  	.word	0x0002d890
   2d28c: 90 d8 02 00  	.word	0x0002d890
   2d290: 90 d8 02 00  	.word	0x0002d890
   2d294: 90 d8 02 00  	.word	0x0002d890
   2d298: 90 d8 02 00  	.word	0x0002d890
   2d29c: 90 d8 02 00  	.word	0x0002d890
   2d2a0: 90 d8 02 00  	.word	0x0002d890
   2d2a4: 90 d8 02 00  	.word	0x0002d890
   2d2a8: 90 d8 02 00  	.word	0x0002d890
   2d2ac: 90 d8 02 00  	.word	0x0002d890
   2d2b0: 90 d8 02 00  	.word	0x0002d890
   2d2b4: 90 d8 02 00  	.word	0x0002d890
   2d2b8: 90 d8 02 00  	.word	0x0002d890
   2d2bc: 90 d8 02 00  	.word	0x0002d890
   2d2c0: 90 d8 02 00  	.word	0x0002d890
   2d2c4: 90 d8 02 00  	.word	0x0002d890
   2d2c8: 90 d8 02 00  	.word	0x0002d890
   2d2cc: 90 d8 02 00  	.word	0x0002d890
   2d2d0: 90 d8 02 00  	.word	0x0002d890
   2d2d4: 90 d8 02 00  	.word	0x0002d890
   2d2d8: 90 d8 02 00  	.word	0x0002d890
   2d2dc: 90 d8 02 00  	.word	0x0002d890
   2d2e0: 90 d8 02 00  	.word	0x0002d890
   2d2e4: 90 d8 02 00  	.word	0x0002d890
   2d2e8: 90 d8 02 00  	.word	0x0002d890
   2d2ec: 90 d8 02 00  	.word	0x0002d890
   2d2f0: 90 d8 02 00  	.word	0x0002d890
   2d2f4: 90 d8 02 00  	.word	0x0002d890
   2d2f8: 90 d8 02 00  	.word	0x0002d890
   2d2fc: 90 d8 02 00  	.word	0x0002d890
   2d300: 90 d8 02 00  	.word	0x0002d890
   2d304: 90 d8 02 00  	.word	0x0002d890
   2d308: 90 d8 02 00  	.word	0x0002d890
   2d30c: 90 d8 02 00  	.word	0x0002d890
   2d310: 90 d8 02 00  	.word	0x0002d890
   2d314: 90 d8 02 00  	.word	0x0002d890
   2d318: 90 d8 02 00  	.word	0x0002d890
   2d31c: 90 d8 02 00  	.word	0x0002d890
   2d320: 90 d8 02 00  	.word	0x0002d890
   2d324: 90 d8 02 00  	.word	0x0002d890
   2d328: 90 d8 02 00  	.word	0x0002d890
   2d32c: 90 d8 02 00  	.word	0x0002d890
   2d330: 90 d8 02 00  	.word	0x0002d890
   2d334: 90 d8 02 00  	.word	0x0002d890
   2d338: 90 d8 02 00  	.word	0x0002d890
   2d33c: 90 d8 02 00  	.word	0x0002d890
   2d340: 90 d8 02 00  	.word	0x0002d890
   2d344: 90 d8 02 00  	.word	0x0002d890
   2d348: 90 d8 02 00  	.word	0x0002d890
   2d34c: 90 d8 02 00  	.word	0x0002d890
   2d350: 90 d8 02 00  	.word	0x0002d890
   2d354: 90 d8 02 00  	.word	0x0002d890
   2d358: 90 d8 02 00  	.word	0x0002d890
   2d35c: 90 d8 02 00  	.word	0x0002d890
   2d360: 90 d8 02 00  	.word	0x0002d890
   2d364: 90 d8 02 00  	.word	0x0002d890
   2d368: 90 d8 02 00  	.word	0x0002d890
   2d36c: 90 d8 02 00  	.word	0x0002d890
   2d370: 90 d8 02 00  	.word	0x0002d890
   2d374: 90 d8 02 00  	.word	0x0002d890
   2d378: 90 d8 02 00  	.word	0x0002d890
   2d37c: 90 d8 02 00  	.word	0x0002d890
   2d380: 90 d8 02 00  	.word	0x0002d890
   2d384: 90 d8 02 00  	.word	0x0002d890
   2d388: 90 d8 02 00  	.word	0x0002d890
   2d38c: 90 d8 02 00  	.word	0x0002d890
   2d390: 90 d8 02 00  	.word	0x0002d890
   2d394: 90 d8 02 00  	.word	0x0002d890
   2d398: 90 d8 02 00  	.word	0x0002d890
   2d39c: 90 d8 02 00  	.word	0x0002d890
   2d3a0: 90 d8 02 00  	.word	0x0002d890
   2d3a4: 90 d8 02 00  	.word	0x0002d890
   2d3a8: 90 d8 02 00  	.word	0x0002d890
   2d3ac: 90 d8 02 00  	.word	0x0002d890
   2d3b0: 90 d8 02 00  	.word	0x0002d890
   2d3b4: 90 d8 02 00  	.word	0x0002d890
   2d3b8: 90 d8 02 00  	.word	0x0002d890
   2d3bc: 90 d8 02 00  	.word	0x0002d890
   2d3c0: 90 d8 02 00  	.word	0x0002d890
   2d3c4: 90 d8 02 00  	.word	0x0002d890
   2d3c8: 90 d8 02 00  	.word	0x0002d890
   2d3cc: 90 d8 02 00  	.word	0x0002d890
   2d3d0: 90 d8 02 00  	.word	0x0002d890
   2d3d4: 90 d8 02 00  	.word	0x0002d890
   2d3d8: 90 d8 02 00  	.word	0x0002d890
   2d3dc: 90 d8 02 00  	.word	0x0002d890
   2d3e0: 90 d8 02 00  	.word	0x0002d890
   2d3e4: 90 d8 02 00  	.word	0x0002d890
   2d3e8: 90 d8 02 00  	.word	0x0002d890
   2d3ec: 90 d8 02 00  	.word	0x0002d890
   2d3f0: 90 d8 02 00  	.word	0x0002d890
   2d3f4: 90 d8 02 00  	.word	0x0002d890
   2d3f8: 90 d8 02 00  	.word	0x0002d890
   2d3fc: 90 d8 02 00  	.word	0x0002d890
   2d400: 90 d8 02 00  	.word	0x0002d890
   2d404: 90 d8 02 00  	.word	0x0002d890
   2d408: 90 d8 02 00  	.word	0x0002d890
   2d40c: 90 d8 02 00  	.word	0x0002d890
   2d410: 90 d8 02 00  	.word	0x0002d890
   2d414: 90 d8 02 00  	.word	0x0002d890
   2d418: 64 d6 02 00  	.word	0x0002d664
   2d41c: b4 d6 02 00  	.word	0x0002d6b4
   2d420: 04 d7 02 00  	.word	0x0002d704
   2d424: 54 d7 02 00  	.word	0x0002d754
   2d428: a4 d7 02 00  	.word	0x0002d7a4
   2d42c: f4 d7 02 00  	.word	0x0002d7f4
   2d430: 44 d8 02 00  	.word	0x0002d844
   2d434: e51b4074     	ldr	r4, [r11, #-0x74]
   2d438: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d43c: ebff7c26     	bl	0xc4dc <strlen@plt>     @ imm = #-0x20f68
   2d440: e1a03000     	mov	r3, r0
   2d444: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d448: e1a01003     	mov	r1, r3
   2d44c: e51b2058     	ldr	r2, [r11, #-0x58]
   2d450: e51f3424     	ldr	r3, [pc, #-0x424]       @ 0x2d034 <scarletbook_read_area_toc+0xf40>
   2d454: ebff8426     	bl	0xe4f4 <charset_convert> @ imm = #-0x1ef68
   2d458: e1a01000     	mov	r1, r0
   2d45c: e51bc05c     	ldr	r12, [r11, #-0x5c]
   2d460: e3a00014     	mov	r0, #20
   2d464: e1a03004     	mov	r3, r4
   2d468: e1a02183     	lsl	r2, r3, #3
   2d46c: e1a03182     	lsl	r3, r2, #3
   2d470: e0623003     	rsb	r3, r2, r3
   2d474: e08c3003     	add	r3, r12, r3
   2d478: e0833000     	add	r3, r3, r0
   2d47c: e5831000     	str	r1, [r3]
   2d480: ea000102     	b	0x2d890 <scarletbook_read_area_toc+0x179c> @ imm = #0x408
   2d484: e51b4074     	ldr	r4, [r11, #-0x74]
   2d488: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d48c: ebff7c12     	bl	0xc4dc <strlen@plt>     @ imm = #-0x20fb8
   2d490: e1a03000     	mov	r3, r0
   2d494: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d498: e1a01003     	mov	r1, r3
   2d49c: e51b2058     	ldr	r2, [r11, #-0x58]
   2d4a0: e51f3474     	ldr	r3, [pc, #-0x474]       @ 0x2d034 <scarletbook_read_area_toc+0xf40>
   2d4a4: ebff8412     	bl	0xe4f4 <charset_convert> @ imm = #-0x1efb8
   2d4a8: e1a01000     	mov	r1, r0
   2d4ac: e51bc05c     	ldr	r12, [r11, #-0x5c]
   2d4b0: e3a00018     	mov	r0, #24
   2d4b4: e1a03004     	mov	r3, r4
   2d4b8: e1a02183     	lsl	r2, r3, #3
   2d4bc: e1a03182     	lsl	r3, r2, #3
   2d4c0: e0623003     	rsb	r3, r2, r3
   2d4c4: e08c3003     	add	r3, r12, r3
   2d4c8: e0833000     	add	r3, r3, r0
   2d4cc: e5831000     	str	r1, [r3]
   2d4d0: ea0000ee     	b	0x2d890 <scarletbook_read_area_toc+0x179c> @ imm = #0x3b8
   2d4d4: e51b4074     	ldr	r4, [r11, #-0x74]
   2d4d8: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d4dc: ebff7bfe     	bl	0xc4dc <strlen@plt>     @ imm = #-0x21008
   2d4e0: e1a03000     	mov	r3, r0
   2d4e4: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d4e8: e1a01003     	mov	r1, r3
   2d4ec: e51b2058     	ldr	r2, [r11, #-0x58]
   2d4f0: e51f34c4     	ldr	r3, [pc, #-0x4c4]       @ 0x2d034 <scarletbook_read_area_toc+0xf40>
   2d4f4: ebff83fe     	bl	0xe4f4 <charset_convert> @ imm = #-0x1f008
   2d4f8: e1a01000     	mov	r1, r0
   2d4fc: e51bc05c     	ldr	r12, [r11, #-0x5c]
   2d500: e3a0001c     	mov	r0, #28
   2d504: e1a03004     	mov	r3, r4
   2d508: e1a02183     	lsl	r2, r3, #3
   2d50c: e1a03182     	lsl	r3, r2, #3
   2d510: e0623003     	rsb	r3, r2, r3
   2d514: e08c3003     	add	r3, r12, r3
   2d518: e0833000     	add	r3, r3, r0
   2d51c: e5831000     	str	r1, [r3]
   2d520: ea0000da     	b	0x2d890 <scarletbook_read_area_toc+0x179c> @ imm = #0x368
   2d524: e51b4074     	ldr	r4, [r11, #-0x74]
   2d528: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d52c: ebff7bea     	bl	0xc4dc <strlen@plt>     @ imm = #-0x21058
   2d530: e1a03000     	mov	r3, r0
   2d534: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d538: e1a01003     	mov	r1, r3
   2d53c: e51b2058     	ldr	r2, [r11, #-0x58]
   2d540: e51f3514     	ldr	r3, [pc, #-0x514]       @ 0x2d034 <scarletbook_read_area_toc+0xf40>
   2d544: ebff83ea     	bl	0xe4f4 <charset_convert> @ imm = #-0x1f058
   2d548: e1a01000     	mov	r1, r0
   2d54c: e51bc05c     	ldr	r12, [r11, #-0x5c]
   2d550: e3a00020     	mov	r0, #32
   2d554: e1a03004     	mov	r3, r4
   2d558: e1a02183     	lsl	r2, r3, #3
   2d55c: e1a03182     	lsl	r3, r2, #3
   2d560: e0623003     	rsb	r3, r2, r3
   2d564: e08c3003     	add	r3, r12, r3
   2d568: e0833000     	add	r3, r3, r0
   2d56c: e5831000     	str	r1, [r3]
   2d570: ea0000c6     	b	0x2d890 <scarletbook_read_area_toc+0x179c> @ imm = #0x318
   2d574: e51b4074     	ldr	r4, [r11, #-0x74]
   2d578: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d57c: ebff7bd6     	bl	0xc4dc <strlen@plt>     @ imm = #-0x210a8
   2d580: e1a03000     	mov	r3, r0
   2d584: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d588: e1a01003     	mov	r1, r3
   2d58c: e51b2058     	ldr	r2, [r11, #-0x58]
   2d590: e51f3564     	ldr	r3, [pc, #-0x564]       @ 0x2d034 <scarletbook_read_area_toc+0xf40>
   2d594: ebff83d6     	bl	0xe4f4 <charset_convert> @ imm = #-0x1f0a8
   2d598: e1a01000     	mov	r1, r0
   2d59c: e51bc05c     	ldr	r12, [r11, #-0x5c]
   2d5a0: e3a00024     	mov	r0, #36
   2d5a4: e1a03004     	mov	r3, r4
   2d5a8: e1a02183     	lsl	r2, r3, #3
   2d5ac: e1a03182     	lsl	r3, r2, #3
   2d5b0: e0623003     	rsb	r3, r2, r3
   2d5b4: e08c3003     	add	r3, r12, r3
   2d5b8: e0833000     	add	r3, r3, r0
   2d5bc: e5831000     	str	r1, [r3]
   2d5c0: ea0000b2     	b	0x2d890 <scarletbook_read_area_toc+0x179c> @ imm = #0x2c8
   2d5c4: e51b4074     	ldr	r4, [r11, #-0x74]
   2d5c8: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d5cc: ebff7bc2     	bl	0xc4dc <strlen@plt>     @ imm = #-0x210f8
   2d5d0: e1a03000     	mov	r3, r0
   2d5d4: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d5d8: e1a01003     	mov	r1, r3
   2d5dc: e51b2058     	ldr	r2, [r11, #-0x58]
   2d5e0: e51f35b4     	ldr	r3, [pc, #-0x5b4]       @ 0x2d034 <scarletbook_read_area_toc+0xf40>
   2d5e4: ebff83c2     	bl	0xe4f4 <charset_convert> @ imm = #-0x1f0f8
   2d5e8: e1a01000     	mov	r1, r0
   2d5ec: e51bc05c     	ldr	r12, [r11, #-0x5c]
   2d5f0: e3a00028     	mov	r0, #40
   2d5f4: e1a03004     	mov	r3, r4
   2d5f8: e1a02183     	lsl	r2, r3, #3
   2d5fc: e1a03182     	lsl	r3, r2, #3
   2d600: e0623003     	rsb	r3, r2, r3
   2d604: e08c3003     	add	r3, r12, r3
   2d608: e0833000     	add	r3, r3, r0
   2d60c: e5831000     	str	r1, [r3]
   2d610: ea00009e     	b	0x2d890 <scarletbook_read_area_toc+0x179c> @ imm = #0x278
   2d614: e51b4074     	ldr	r4, [r11, #-0x74]
   2d618: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d61c: ebff7bae     	bl	0xc4dc <strlen@plt>     @ imm = #-0x21148
   2d620: e1a03000     	mov	r3, r0
   2d624: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d628: e1a01003     	mov	r1, r3
   2d62c: e51b2058     	ldr	r2, [r11, #-0x58]
   2d630: e51f3604     	ldr	r3, [pc, #-0x604]       @ 0x2d034 <scarletbook_read_area_toc+0xf40>
   2d634: ebff83ae     	bl	0xe4f4 <charset_convert> @ imm = #-0x1f148
   2d638: e1a01000     	mov	r1, r0
   2d63c: e51bc05c     	ldr	r12, [r11, #-0x5c]
   2d640: e3a0002c     	mov	r0, #44
   2d644: e1a03004     	mov	r3, r4
   2d648: e1a02183     	lsl	r2, r3, #3
   2d64c: e1a03182     	lsl	r3, r2, #3
   2d650: e0623003     	rsb	r3, r2, r3
   2d654: e08c3003     	add	r3, r12, r3
   2d658: e0833000     	add	r3, r3, r0
   2d65c: e5831000     	str	r1, [r3]
   2d660: ea00008a     	b	0x2d890 <scarletbook_read_area_toc+0x179c> @ imm = #0x228
   2d664: e51b4074     	ldr	r4, [r11, #-0x74]
   2d668: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d66c: ebff7b9a     	bl	0xc4dc <strlen@plt>     @ imm = #-0x21198
   2d670: e1a03000     	mov	r3, r0
   2d674: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d678: e1a01003     	mov	r1, r3
   2d67c: e51b2058     	ldr	r2, [r11, #-0x58]
   2d680: e51f3654     	ldr	r3, [pc, #-0x654]       @ 0x2d034 <scarletbook_read_area_toc+0xf40>
   2d684: ebff839a     	bl	0xe4f4 <charset_convert> @ imm = #-0x1f198
   2d688: e1a01000     	mov	r1, r0
   2d68c: e51bc05c     	ldr	r12, [r11, #-0x5c]
   2d690: e3a00030     	mov	r0, #48
   2d694: e1a03004     	mov	r3, r4
   2d698: e1a02183     	lsl	r2, r3, #3
   2d69c: e1a03182     	lsl	r3, r2, #3
   2d6a0: e0623003     	rsb	r3, r2, r3
   2d6a4: e08c3003     	add	r3, r12, r3
   2d6a8: e0833000     	add	r3, r3, r0
   2d6ac: e5831000     	str	r1, [r3]
   2d6b0: ea000076     	b	0x2d890 <scarletbook_read_area_toc+0x179c> @ imm = #0x1d8
   2d6b4: e51b4074     	ldr	r4, [r11, #-0x74]
   2d6b8: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d6bc: ebff7b86     	bl	0xc4dc <strlen@plt>     @ imm = #-0x211e8
   2d6c0: e1a03000     	mov	r3, r0
   2d6c4: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d6c8: e1a01003     	mov	r1, r3
   2d6cc: e51b2058     	ldr	r2, [r11, #-0x58]
   2d6d0: e51f36a4     	ldr	r3, [pc, #-0x6a4]       @ 0x2d034 <scarletbook_read_area_toc+0xf40>
   2d6d4: ebff8386     	bl	0xe4f4 <charset_convert> @ imm = #-0x1f1e8
   2d6d8: e1a01000     	mov	r1, r0
   2d6dc: e51bc05c     	ldr	r12, [r11, #-0x5c]
   2d6e0: e3a00034     	mov	r0, #52
   2d6e4: e1a03004     	mov	r3, r4
   2d6e8: e1a02183     	lsl	r2, r3, #3
   2d6ec: e1a03182     	lsl	r3, r2, #3
   2d6f0: e0623003     	rsb	r3, r2, r3
   2d6f4: e08c3003     	add	r3, r12, r3
   2d6f8: e0833000     	add	r3, r3, r0
   2d6fc: e5831000     	str	r1, [r3]
   2d700: ea000062     	b	0x2d890 <scarletbook_read_area_toc+0x179c> @ imm = #0x188
   2d704: e51b4074     	ldr	r4, [r11, #-0x74]
   2d708: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d70c: ebff7b72     	bl	0xc4dc <strlen@plt>     @ imm = #-0x21238
   2d710: e1a03000     	mov	r3, r0
   2d714: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d718: e1a01003     	mov	r1, r3
   2d71c: e51b2058     	ldr	r2, [r11, #-0x58]
   2d720: e51f36f4     	ldr	r3, [pc, #-0x6f4]       @ 0x2d034 <scarletbook_read_area_toc+0xf40>
   2d724: ebff8372     	bl	0xe4f4 <charset_convert> @ imm = #-0x1f238
   2d728: e1a01000     	mov	r1, r0
   2d72c: e51bc05c     	ldr	r12, [r11, #-0x5c]
   2d730: e3a00038     	mov	r0, #56
   2d734: e1a03004     	mov	r3, r4
   2d738: e1a02183     	lsl	r2, r3, #3
   2d73c: e1a03182     	lsl	r3, r2, #3
   2d740: e0623003     	rsb	r3, r2, r3
   2d744: e08c3003     	add	r3, r12, r3
   2d748: e0833000     	add	r3, r3, r0
   2d74c: e5831000     	str	r1, [r3]
   2d750: ea00004e     	b	0x2d890 <scarletbook_read_area_toc+0x179c> @ imm = #0x138
   2d754: e51b4074     	ldr	r4, [r11, #-0x74]
   2d758: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d75c: ebff7b5e     	bl	0xc4dc <strlen@plt>     @ imm = #-0x21288
   2d760: e1a03000     	mov	r3, r0
   2d764: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d768: e1a01003     	mov	r1, r3
   2d76c: e51b2058     	ldr	r2, [r11, #-0x58]
   2d770: e51f3744     	ldr	r3, [pc, #-0x744]       @ 0x2d034 <scarletbook_read_area_toc+0xf40>
   2d774: ebff835e     	bl	0xe4f4 <charset_convert> @ imm = #-0x1f288
   2d778: e1a01000     	mov	r1, r0
   2d77c: e51bc05c     	ldr	r12, [r11, #-0x5c]
   2d780: e2843001     	add	r3, r4, #1
   2d784: e3a00004     	mov	r0, #4
   2d788: e1a02183     	lsl	r2, r3, #3
   2d78c: e1a03182     	lsl	r3, r2, #3
   2d790: e0623003     	rsb	r3, r2, r3
   2d794: e08c3003     	add	r3, r12, r3
   2d798: e0833000     	add	r3, r3, r0
   2d79c: e5831000     	str	r1, [r3]
   2d7a0: ea00003a     	b	0x2d890 <scarletbook_read_area_toc+0x179c> @ imm = #0xe8
   2d7a4: e51b4074     	ldr	r4, [r11, #-0x74]
   2d7a8: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d7ac: ebff7b4a     	bl	0xc4dc <strlen@plt>     @ imm = #-0x212d8
   2d7b0: e1a03000     	mov	r3, r0
   2d7b4: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d7b8: e1a01003     	mov	r1, r3
   2d7bc: e51b2058     	ldr	r2, [r11, #-0x58]
   2d7c0: e51f3794     	ldr	r3, [pc, #-0x794]       @ 0x2d034 <scarletbook_read_area_toc+0xf40>
   2d7c4: ebff834a     	bl	0xe4f4 <charset_convert> @ imm = #-0x1f2d8
   2d7c8: e1a01000     	mov	r1, r0
   2d7cc: e51bc05c     	ldr	r12, [r11, #-0x5c]
   2d7d0: e2843001     	add	r3, r4, #1
   2d7d4: e3a00008     	mov	r0, #8
   2d7d8: e1a02183     	lsl	r2, r3, #3
   2d7dc: e1a03182     	lsl	r3, r2, #3
   2d7e0: e0623003     	rsb	r3, r2, r3
   2d7e4: e08c3003     	add	r3, r12, r3
   2d7e8: e0833000     	add	r3, r3, r0
   2d7ec: e5831000     	str	r1, [r3]
   2d7f0: ea000026     	b	0x2d890 <scarletbook_read_area_toc+0x179c> @ imm = #0x98
   2d7f4: e51b4074     	ldr	r4, [r11, #-0x74]
   2d7f8: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d7fc: ebff7b36     	bl	0xc4dc <strlen@plt>     @ imm = #-0x21328
   2d800: e1a03000     	mov	r3, r0
   2d804: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d808: e1a01003     	mov	r1, r3
   2d80c: e51b2058     	ldr	r2, [r11, #-0x58]
   2d810: e51f37e4     	ldr	r3, [pc, #-0x7e4]       @ 0x2d034 <scarletbook_read_area_toc+0xf40>
   2d814: ebff8336     	bl	0xe4f4 <charset_convert> @ imm = #-0x1f328
   2d818: e1a01000     	mov	r1, r0
   2d81c: e51bc05c     	ldr	r12, [r11, #-0x5c]
   2d820: e3a00044     	mov	r0, #68
   2d824: e1a03004     	mov	r3, r4
   2d828: e1a02183     	lsl	r2, r3, #3
   2d82c: e1a03182     	lsl	r3, r2, #3
   2d830: e0623003     	rsb	r3, r2, r3
   2d834: e08c3003     	add	r3, r12, r3
   2d838: e0833000     	add	r3, r3, r0
   2d83c: e5831000     	str	r1, [r3]
   2d840: ea000012     	b	0x2d890 <scarletbook_read_area_toc+0x179c> @ imm = #0x48
   2d844: e51b4074     	ldr	r4, [r11, #-0x74]
   2d848: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d84c: ebff7b22     	bl	0xc4dc <strlen@plt>     @ imm = #-0x21378
   2d850: e1a03000     	mov	r3, r0
   2d854: e51b001c     	ldr	r0, [r11, #-0x1c]
   2d858: e1a01003     	mov	r1, r3
   2d85c: e51b2058     	ldr	r2, [r11, #-0x58]
   2d860: e51f3834     	ldr	r3, [pc, #-0x834]       @ 0x2d034 <scarletbook_read_area_toc+0xf40>
   2d864: ebff8322     	bl	0xe4f4 <charset_convert> @ imm = #-0x1f378
   2d868: e1a01000     	mov	r1, r0
   2d86c: e51bc05c     	ldr	r12, [r11, #-0x5c]
   2d870: e3a00048     	mov	r0, #72
   2d874: e1a03004     	mov	r3, r4
   2d878: e1a02183     	lsl	r2, r3, #3
   2d87c: e1a03182     	lsl	r3, r2, #3
   2d880: e0623003     	rsb	r3, r2, r3
   2d884: e08c3003     	add	r3, r12, r3
   2d888: e0833000     	add	r3, r3, r0
   2d88c: e5831000     	str	r1, [r3]
   2d890: e55b301d     	ldrb	r3, [r11, #-0x1d]
   2d894: e2432001     	sub	r2, r3, #1
   2d898: e51b3070     	ldr	r3, [r11, #-0x70]
   2d89c: e1520003     	cmp	r2, r3
   2d8a0: da00000f     	ble	0x2d8e4 <scarletbook_read_area_toc+0x17f0> @ imm = #0x3c
   2d8a4: ea000002     	b	0x2d8b4 <scarletbook_read_area_toc+0x17c0> @ imm = #0x8
   2d8a8: e51b301c     	ldr	r3, [r11, #-0x1c]
   2d8ac: e2833001     	add	r3, r3, #1
   2d8b0: e50b301c     	str	r3, [r11, #-0x1c]
   2d8b4: e51b301c     	ldr	r3, [r11, #-0x1c]
   2d8b8: e5d33000     	ldrb	r3, [r3]
   2d8bc: e3530000     	cmp	r3, #0
   2d8c0: 1afffff8     	bne	0x2d8a8 <scarletbook_read_area_toc+0x17b4> @ imm = #-0x20
   2d8c4: ea000002     	b	0x2d8d4 <scarletbook_read_area_toc+0x17e0> @ imm = #0x8
   2d8c8: e51b301c     	ldr	r3, [r11, #-0x1c]
   2d8cc: e2833001     	add	r3, r3, #1
   2d8d0: e50b301c     	str	r3, [r11, #-0x1c]
   2d8d4: e51b301c     	ldr	r3, [r11, #-0x1c]
   2d8d8: e5d33000     	ldrb	r3, [r3]
   2d8dc: e3530000     	cmp	r3, #0
   2d8e0: 0afffff8     	beq	0x2d8c8 <scarletbook_read_area_toc+0x17d4> @ imm = #-0x20
   2d8e4: e51b3070     	ldr	r3, [r11, #-0x70]
   2d8e8: e2833001     	add	r3, r3, #1
   2d8ec: e50b3070     	str	r3, [r11, #-0x70]
   2d8f0: e55b201d     	ldrb	r2, [r11, #-0x1d]
   2d8f4: e51b3070     	ldr	r3, [r11, #-0x70]
   2d8f8: e1520003     	cmp	r2, r3
   2d8fc: cafffe33     	bgt	0x2d1d0 <scarletbook_read_area_toc+0x10dc> @ imm = #-0x734
   2d900: e51b3074     	ldr	r3, [r11, #-0x74]
   2d904: e2833001     	add	r3, r3, #1
   2d908: e50b3074     	str	r3, [r11, #-0x74]
   2d90c: e51b306c     	ldr	r3, [r11, #-0x6c]
   2d910: e5d33045     	ldrb	r3, [r3, #0x45]
   2d914: e1a02003     	mov	r2, r3
   2d918: e51b3074     	ldr	r3, [r11, #-0x74]
   2d91c: e1520003     	cmp	r2, r3
   2d920: cafffdd6     	bgt	0x2d080 <scarletbook_read_area_toc+0xf8c> @ imm = #-0x8a8
   2d924: e51b3060     	ldr	r3, [r11, #-0x60]
   2d928: e2833001     	add	r3, r3, #1
   2d92c: e50b3060     	str	r3, [r11, #-0x60]
   2d930: e51b3064     	ldr	r3, [r11, #-0x64]
   2d934: e2833b02     	add	r3, r3, #2048
   2d938: e50b3064     	str	r3, [r11, #-0x64]
   2d93c: ea0000da     	b	0x2dcac <scarletbook_read_area_toc+0x1bb8> @ imm = #0x368
   2d940: e51b0064     	ldr	r0, [r11, #-0x64]
   2d944: e51f1914     	ldr	r1, [pc, #-0x914]       @ 0x2d038 <scarletbook_read_area_toc+0xf44>
   2d948: e3a02008     	mov	r2, #8
   2d94c: ebff7b87     	bl	0xc770 <strncmp@plt>    @ imm = #-0x211e4
   2d950: e1a03000     	mov	r3, r0
   2d954: e3530000     	cmp	r3, #0
   2d958: 1a000007     	bne	0x2d97c <scarletbook_read_area_toc+0x1888> @ imm = #0x1c
   2d95c: e51b1064     	ldr	r1, [r11, #-0x64]
   2d960: e51b205c     	ldr	r2, [r11, #-0x5c]
   2d964: e51f3930     	ldr	r3, [pc, #-0x930]       @ 0x2d03c <scarletbook_read_area_toc+0xf48>
   2d968: e7821003     	str	r1, [r2, r3]
   2d96c: e51b3064     	ldr	r3, [r11, #-0x64]
   2d970: e2833a01     	add	r3, r3, #4096
   2d974: e50b3064     	str	r3, [r11, #-0x64]
   2d978: ea0000cb     	b	0x2dcac <scarletbook_read_area_toc+0x1bb8> @ imm = #0x32c
   2d97c: e51b0064     	ldr	r0, [r11, #-0x64]
   2d980: e51f1948     	ldr	r1, [pc, #-0x948]       @ 0x2d040 <scarletbook_read_area_toc+0xf4c>
   2d984: e3a02008     	mov	r2, #8
   2d988: ebff7b78     	bl	0xc770 <strncmp@plt>    @ imm = #-0x21220
   2d98c: e1a03000     	mov	r3, r0
   2d990: e3530000     	cmp	r3, #0
   2d994: 1a000003     	bne	0x2d9a8 <scarletbook_read_area_toc+0x18b4> @ imm = #0xc
   2d998: e51b3064     	ldr	r3, [r11, #-0x64]
   2d99c: e2833801     	add	r3, r3, #65536
   2d9a0: e50b3064     	str	r3, [r11, #-0x64]
   2d9a4: ea0000c0     	b	0x2dcac <scarletbook_read_area_toc+0x1bb8> @ imm = #0x300
   2d9a8: e51b0064     	ldr	r0, [r11, #-0x64]
   2d9ac: e51f1970     	ldr	r1, [pc, #-0x970]       @ 0x2d044 <scarletbook_read_area_toc+0xf50>
   2d9b0: e3a02008     	mov	r2, #8
   2d9b4: ebff7b6d     	bl	0xc770 <strncmp@plt>    @ imm = #-0x2124c
   2d9b8: e1a03000     	mov	r3, r0
   2d9bc: e3530000     	cmp	r3, #0
   2d9c0: 1a0000a9     	bne	0x2dc6c <scarletbook_read_area_toc+0x1b78> @ imm = #0x2a4
   2d9c4: e51b2064     	ldr	r2, [r11, #-0x64]
   2d9c8: e51b305c     	ldr	r3, [r11, #-0x5c]
   2d9cc: e5832008     	str	r2, [r3, #0x8]
   2d9d0: e51b305c     	ldr	r3, [r11, #-0x5c]
   2d9d4: e5933008     	ldr	r3, [r3, #0x8]
   2d9d8: e50b3014     	str	r3, [r11, #-0x14]
   2d9dc: e3a03000     	mov	r3, #0
   2d9e0: e50b3074     	str	r3, [r11, #-0x74]
   2d9e4: ea000096     	b	0x2dc44 <scarletbook_read_area_toc+0x1b50> @ imm = #0x258
   2d9e8: e51b0074     	ldr	r0, [r11, #-0x74]
   2d9ec: e51b2074     	ldr	r2, [r11, #-0x74]
   2d9f0: e51b3014     	ldr	r3, [r11, #-0x14]
   2d9f4: e2822002     	add	r2, r2, #2
   2d9f8: e7d31102     	ldrb	r1, [r3, r2, lsl #2]
   2d9fc: e3a0c001     	mov	r12, #1
   2da00: e1a04102     	lsl	r4, r2, #2
   2da04: e0834004     	add	r4, r3, r4
   2da08: e084c00c     	add	r12, r4, r12
   2da0c: e5dcc000     	ldrb	r12, [r12]
   2da10: e1a0c40c     	lsl	r12, r12, #8
   2da14: e18c1001     	orr	r1, r12, r1
   2da18: e3a0c002     	mov	r12, #2
   2da1c: e1a04102     	lsl	r4, r2, #2
   2da20: e0834004     	add	r4, r3, r4
   2da24: e084c00c     	add	r12, r4, r12
   2da28: e5dcc000     	ldrb	r12, [r12]
   2da2c: e1a0c80c     	lsl	r12, r12, #16
   2da30: e18c1001     	orr	r1, r12, r1
   2da34: e3a0c003     	mov	r12, #3
   2da38: e1a02102     	lsl	r2, r2, #2
   2da3c: e0833002     	add	r3, r3, r2
   2da40: e083300c     	add	r3, r3, r12
   2da44: e5d33000     	ldrb	r3, [r3]
   2da48: e1a03c03     	lsl	r3, r3, #24
   2da4c: e1833001     	orr	r3, r3, r1
   2da50: e1a04003     	mov	r4, r3
   2da54: e1a02c24     	lsr	r2, r4, #24
   2da58: e20438ff     	and	r3, r4, #16711680
   2da5c: e1a03423     	lsr	r3, r3, #8
   2da60: e1822003     	orr	r2, r2, r3
   2da64: e2043cff     	and	r3, r4, #65280
   2da68: e1a03403     	lsl	r3, r3, #8
   2da6c: e1822003     	orr	r2, r2, r3
   2da70: e1a03c04     	lsl	r3, r4, #24
   2da74: e1821003     	orr	r1, r2, r3
   2da78: e51b3014     	ldr	r3, [r11, #-0x14]
   2da7c: e2802002     	add	r2, r0, #2
   2da80: e20100ff     	and	r0, r1, #255
   2da84: e3a0c000     	mov	r12, #0
   2da88: e18c0000     	orr	r0, r12, r0
   2da8c: e7c30102     	strb	r0, [r3, r2, lsl #2]
   2da90: e1a00421     	lsr	r0, r1, #8
   2da94: e200c0ff     	and	r12, r0, #255
   2da98: e3a00001     	mov	r0, #1
   2da9c: e1a04102     	lsl	r4, r2, #2
   2daa0: e0834004     	add	r4, r3, r4
   2daa4: e0840000     	add	r0, r4, r0
   2daa8: e3a04000     	mov	r4, #0
   2daac: e184c00c     	orr	r12, r4, r12
   2dab0: e5c0c000     	strb	r12, [r0]
   2dab4: e1a00821     	lsr	r0, r1, #16
   2dab8: e200c0ff     	and	r12, r0, #255
   2dabc: e3a00002     	mov	r0, #2
   2dac0: e1a04102     	lsl	r4, r2, #2
   2dac4: e0834004     	add	r4, r3, r4
   2dac8: e0840000     	add	r0, r4, r0
   2dacc: e3a04000     	mov	r4, #0
   2dad0: e184c00c     	orr	r12, r4, r12
   2dad4: e5c0c000     	strb	r12, [r0]
   2dad8: e1a00c21     	lsr	r0, r1, #24
   2dadc: e3a01003     	mov	r1, #3
   2dae0: e1a02102     	lsl	r2, r2, #2
   2dae4: e0833002     	add	r3, r3, r2
   2dae8: e0833001     	add	r3, r3, r1
   2daec: e3a02000     	mov	r2, #0
   2daf0: e1a01002     	mov	r1, r2
   2daf4: e1a02000     	mov	r2, r0
   2daf8: e1812002     	orr	r2, r1, r2
   2dafc: e5c32000     	strb	r2, [r3]
   2db00: e51b0074     	ldr	r0, [r11, #-0x74]
   2db04: e51b2074     	ldr	r2, [r11, #-0x74]
   2db08: e51b3014     	ldr	r3, [r11, #-0x14]
   2db0c: e2822c01     	add	r2, r2, #256
   2db10: e3a01004     	mov	r1, #4
   2db14: e1a0c102     	lsl	r12, r2, #2
   2db18: e083c00c     	add	r12, r3, r12
   2db1c: e08c1001     	add	r1, r12, r1
   2db20: e5d11000     	ldrb	r1, [r1]
   2db24: e3a0c005     	mov	r12, #5
   2db28: e1a04102     	lsl	r4, r2, #2
   2db2c: e0834004     	add	r4, r3, r4
   2db30: e084c00c     	add	r12, r4, r12
   2db34: e5dcc000     	ldrb	r12, [r12]
   2db38: e1a0c40c     	lsl	r12, r12, #8
   2db3c: e18c1001     	orr	r1, r12, r1
   2db40: e3a0c006     	mov	r12, #6
   2db44: e1a04102     	lsl	r4, r2, #2
   2db48: e0834004     	add	r4, r3, r4
   2db4c: e084c00c     	add	r12, r4, r12
   2db50: e5dcc000     	ldrb	r12, [r12]
   2db54: e1a0c80c     	lsl	r12, r12, #16
   2db58: e18c1001     	orr	r1, r12, r1
   2db5c: e3a0c007     	mov	r12, #7
   2db60: e1a02102     	lsl	r2, r2, #2
   2db64: e0833002     	add	r3, r3, r2
   2db68: e083300c     	add	r3, r3, r12
   2db6c: e5d33000     	ldrb	r3, [r3]
   2db70: e1a03c03     	lsl	r3, r3, #24
   2db74: e1833001     	orr	r3, r3, r1
   2db78: e1a04003     	mov	r4, r3
   2db7c: e1a02c24     	lsr	r2, r4, #24
   2db80: e20438ff     	and	r3, r4, #16711680
   2db84: e1a03423     	lsr	r3, r3, #8
   2db88: e1822003     	orr	r2, r2, r3
   2db8c: e2043cff     	and	r3, r4, #65280
   2db90: e1a03403     	lsl	r3, r3, #8
   2db94: e1822003     	orr	r2, r2, r3
   2db98: e1a03c04     	lsl	r3, r4, #24
   2db9c: e1821003     	orr	r1, r2, r3
   2dba0: e51b3014     	ldr	r3, [r11, #-0x14]
   2dba4: e2802c01     	add	r2, r0, #256
   2dba8: e201c0ff     	and	r12, r1, #255
   2dbac: e3a00004     	mov	r0, #4
   2dbb0: e1a04102     	lsl	r4, r2, #2
   2dbb4: e0834004     	add	r4, r3, r4
   2dbb8: e0840000     	add	r0, r4, r0
   2dbbc: e3a04000     	mov	r4, #0
   2dbc0: e184c00c     	orr	r12, r4, r12
   2dbc4: e5c0c000     	strb	r12, [r0]
   2dbc8: e1a00421     	lsr	r0, r1, #8
   2dbcc: e200c0ff     	and	r12, r0, #255
   2dbd0: e3a00005     	mov	r0, #5
   2dbd4: e1a04102     	lsl	r4, r2, #2
   2dbd8: e0834004     	add	r4, r3, r4
   2dbdc: e0840000     	add	r0, r4, r0
   2dbe0: e3a04000     	mov	r4, #0
   2dbe4: e184c00c     	orr	r12, r4, r12
   2dbe8: e5c0c000     	strb	r12, [r0]
   2dbec: e1a00821     	lsr	r0, r1, #16
   2dbf0: e200c0ff     	and	r12, r0, #255
   2dbf4: e3a00006     	mov	r0, #6
   2dbf8: e1a04102     	lsl	r4, r2, #2
   2dbfc: e0834004     	add	r4, r3, r4
   2dc00: e0840000     	add	r0, r4, r0
   2dc04: e3a04000     	mov	r4, #0
   2dc08: e184c00c     	orr	r12, r4, r12
   2dc0c: e5c0c000     	strb	r12, [r0]
   2dc10: e1a00c21     	lsr	r0, r1, #24
   2dc14: e3a01007     	mov	r1, #7
   2dc18: e1a02102     	lsl	r2, r2, #2
   2dc1c: e0833002     	add	r3, r3, r2
   2dc20: e0833001     	add	r3, r3, r1
   2dc24: e3a02000     	mov	r2, #0
   2dc28: e1a01002     	mov	r1, r2
   2dc2c: e1a02000     	mov	r2, r0
   2dc30: e1812002     	orr	r2, r1, r2
   2dc34: e5c32000     	strb	r2, [r3]
   2dc38: e51b3074     	ldr	r3, [r11, #-0x74]
   2dc3c: e2833001     	add	r3, r3, #1
   2dc40: e50b3074     	str	r3, [r11, #-0x74]
   2dc44: e51b306c     	ldr	r3, [r11, #-0x6c]
   2dc48: e5d33045     	ldrb	r3, [r3, #0x45]
   2dc4c: e1a02003     	mov	r2, r3
   2dc50: e51b3074     	ldr	r3, [r11, #-0x74]
   2dc54: e1520003     	cmp	r2, r3
   2dc58: caffff62     	bgt	0x2d9e8 <scarletbook_read_area_toc+0x18f4> @ imm = #-0x278
   2dc5c: e51b3064     	ldr	r3, [r11, #-0x64]
   2dc60: e2833b02     	add	r3, r3, #2048
   2dc64: e50b3064     	str	r3, [r11, #-0x64]
   2dc68: ea00000f     	b	0x2dcac <scarletbook_read_area_toc+0x1bb8> @ imm = #0x3c
   2dc6c: e51b0064     	ldr	r0, [r11, #-0x64]
   2dc70: e51f1c30     	ldr	r1, [pc, #-0xc30]       @ 0x2d048 <scarletbook_read_area_toc+0xf54>
   2dc74: e3a02008     	mov	r2, #8
   2dc78: ebff7abc     	bl	0xc770 <strncmp@plt>    @ imm = #-0x21510
   2dc7c: e1a03000     	mov	r3, r0
   2dc80: e3530000     	cmp	r3, #0
   2dc84: 1a000015     	bne	0x2dce0 <scarletbook_read_area_toc+0x1bec> @ imm = #0x54
   2dc88: e51b2064     	ldr	r2, [r11, #-0x64]
   2dc8c: e51b305c     	ldr	r3, [r11, #-0x5c]
   2dc90: e583200c     	str	r2, [r3, #0xc]
   2dc94: e51b305c     	ldr	r3, [r11, #-0x5c]
   2dc98: e593300c     	ldr	r3, [r3, #0xc]
   2dc9c: e50b3010     	str	r3, [r11, #-0x10]
   2dca0: e51b3064     	ldr	r3, [r11, #-0x64]
   2dca4: e2833b02     	add	r3, r3, #2048
   2dca8: e50b3064     	str	r3, [r11, #-0x64]
   2dcac: e51b306c     	ldr	r3, [r11, #-0x6c]
   2dcb0: e5d3200a     	ldrb	r2, [r3, #0xa]
   2dcb4: e5d3300b     	ldrb	r3, [r3, #0xb]
   2dcb8: e1a03403     	lsl	r3, r3, #8
   2dcbc: e1833002     	orr	r3, r3, r2
   2dcc0: e6ff3073     	uxth	r3, r3
   2dcc4: e1a03583     	lsl	r3, r3, #11
   2dcc8: e51b2068     	ldr	r2, [r11, #-0x68]
   2dccc: e0822003     	add	r2, r2, r3
   2dcd0: e51b3064     	ldr	r3, [r11, #-0x64]
   2dcd4: e1520003     	cmp	r2, r3
   2dcd8: 8afffcdb     	bhi	0x2d04c <scarletbook_read_area_toc+0xf58> @ imm = #-0xc94
   2dcdc: ea000000     	b	0x2dce4 <scarletbook_read_area_toc+0x1bf0> @ imm = #0x0
   2dce0: e1a00000     	mov	r0, r0
   2dce4: e3a03001     	mov	r3, #1
   2dce8: e1a00003     	mov	r0, r3
   2dcec: e24bd008     	sub	sp, r11, #8
   2dcf0: e8bd8810     	pop	{r4, r11, pc}

