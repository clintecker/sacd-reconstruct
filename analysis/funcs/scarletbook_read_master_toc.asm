0002a1fc <scarletbook_read_master_toc>:
   2a1fc: e92d4810     	push	{r4, r11, lr}
   2a200: e28db008     	add	r11, sp, #8
   2a204: e24dd07c     	sub	sp, sp, #124
   2a208: e50b0078     	str	r0, [r11, #-0x78]
   2a20c: e3a00a05     	mov	r0, #20480
   2a210: ebff8914     	bl	0xc668 <malloc@plt>     @ imm = #-0x1dbb0
   2a214: e1a03000     	mov	r3, r0
   2a218: e1a02003     	mov	r2, r3
   2a21c: e51b3078     	ldr	r3, [r11, #-0x78]
   2a220: e5832004     	str	r2, [r3, #0x4]
   2a224: e51b3078     	ldr	r3, [r11, #-0x78]
   2a228: e5933004     	ldr	r3, [r3, #0x4]
   2a22c: e3530000     	cmp	r3, #0
   2a230: 1a000001     	bne	0x2a23c <scarletbook_read_master_toc+0x40> @ imm = #0x4
   2a234: e3a03000     	mov	r3, #0
   2a238: ea0007a8     	b	0x2c0e0 <scarletbook_read_master_toc+0x1ee4> @ imm = #0x1ea0
   2a23c: e51b3078     	ldr	r3, [r11, #-0x78]
   2a240: e5933000     	ldr	r3, [r3]
   2a244: e1a02003     	mov	r2, r3
   2a248: e51b3078     	ldr	r3, [r11, #-0x78]
   2a24c: e5933004     	ldr	r3, [r3, #0x4]
   2a250: e1a00002     	mov	r0, r2
   2a254: e59f1db4     	ldr	r1, [pc, #0xdb4]        @ 0x2b010 <scarletbook_read_master_toc+0xe14>
   2a258: e3a0200a     	mov	r2, #10
   2a25c: eb001228     	bl	0x2eb04 <sacd_read_block_raw> @ imm = #0x48a0
   2a260: e1a03000     	mov	r3, r0
   2a264: e3530000     	cmp	r3, #0
   2a268: 1a000001     	bne	0x2a274 <scarletbook_read_master_toc+0x78> @ imm = #0x4
   2a26c: e3a03000     	mov	r3, #0
   2a270: ea00079a     	b	0x2c0e0 <scarletbook_read_master_toc+0x1ee4> @ imm = #0x1e68
   2a274: e51b3078     	ldr	r3, [r11, #-0x78]
   2a278: e5933004     	ldr	r3, [r3, #0x4]
   2a27c: e1a02003     	mov	r2, r3
   2a280: e51b3078     	ldr	r3, [r11, #-0x78]
   2a284: e5832008     	str	r2, [r3, #0x8]
   2a288: e51b3078     	ldr	r3, [r11, #-0x78]
   2a28c: e5933008     	ldr	r3, [r3, #0x8]
   2a290: e50b3068     	str	r3, [r11, #-0x68]
   2a294: e51b3068     	ldr	r3, [r11, #-0x68]
   2a298: e59f0d74     	ldr	r0, [pc, #0xd74]        @ 0x2b014 <scarletbook_read_master_toc+0xe18>
   2a29c: e1a01003     	mov	r1, r3
   2a2a0: e3a02008     	mov	r2, #8
   2a2a4: ebff8931     	bl	0xc770 <strncmp@plt>    @ imm = #-0x1db3c
   2a2a8: e1a03000     	mov	r3, r0
   2a2ac: e3530000     	cmp	r3, #0
   2a2b0: 0a000008     	beq	0x2a2d8 <scarletbook_read_master_toc+0xdc> @ imm = #0x20
   2a2b4: e59f2d5c     	ldr	r2, [pc, #0xd5c]        @ 0x2b018 <scarletbook_read_master_toc+0xe1c>
   2a2b8: e59f3dd4     	ldr	r3, [pc, #0xdd4]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2a2bc: e5933000     	ldr	r3, [r3]
   2a2c0: e1a00002     	mov	r0, r2
   2a2c4: e3a01001     	mov	r1, #1
   2a2c8: e3a02025     	mov	r2, #37
   2a2cc: ebff88c7     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x1dce4
   2a2d0: e3a03000     	mov	r3, #0
   2a2d4: ea000781     	b	0x2c0e0 <scarletbook_read_master_toc+0x1ee4> @ imm = #0x1e04
   2a2d8: e51b3068     	ldr	r3, [r11, #-0x68]
   2a2dc: e5d32010     	ldrb	r2, [r3, #0x10]
   2a2e0: e5d33011     	ldrb	r3, [r3, #0x11]
   2a2e4: e1a03403     	lsl	r3, r3, #8
   2a2e8: e1833002     	orr	r3, r3, r2
   2a2ec: e14b36b2     	strh	r3, [r11, #-98]
   2a2f0: e15b36b2     	ldrh	r3, [r11, #-98]
   2a2f4: e1a03423     	lsr	r3, r3, #8
   2a2f8: e6ff3073     	uxth	r3, r3
   2a2fc: e1a02003     	mov	r2, r3
   2a300: e15b36b2     	ldrh	r3, [r11, #-98]
   2a304: e1a03403     	lsl	r3, r3, #8
   2a308: e1a03803     	lsl	r3, r3, #16
   2a30c: e1a03823     	lsr	r3, r3, #16
   2a310: e1823003     	orr	r3, r2, r3
   2a314: e6ff2073     	uxth	r2, r3
   2a318: e51b3068     	ldr	r3, [r11, #-0x68]
   2a31c: e20210ff     	and	r1, r2, #255
   2a320: e3a00000     	mov	r0, #0
   2a324: e1801001     	orr	r1, r0, r1
   2a328: e5c31010     	strb	r1, [r3, #0x10]
   2a32c: e1a02422     	lsr	r2, r2, #8
   2a330: e6ff2072     	uxth	r2, r2
   2a334: e3a01000     	mov	r1, #0
   2a338: e1812002     	orr	r2, r1, r2
   2a33c: e5c32011     	strb	r2, [r3, #0x11]
   2a340: e51b3068     	ldr	r3, [r11, #-0x68]
   2a344: e5d32012     	ldrb	r2, [r3, #0x12]
   2a348: e5d33013     	ldrb	r3, [r3, #0x13]
   2a34c: e1a03403     	lsl	r3, r3, #8
   2a350: e1833002     	orr	r3, r3, r2
   2a354: e14b36b0     	strh	r3, [r11, #-96]
   2a358: e15b36b0     	ldrh	r3, [r11, #-96]
   2a35c: e1a03423     	lsr	r3, r3, #8
   2a360: e6ff3073     	uxth	r3, r3
   2a364: e1a02003     	mov	r2, r3
   2a368: e15b36b0     	ldrh	r3, [r11, #-96]
   2a36c: e1a03403     	lsl	r3, r3, #8
   2a370: e1a03803     	lsl	r3, r3, #16
   2a374: e1a03823     	lsr	r3, r3, #16
   2a378: e1823003     	orr	r3, r2, r3
   2a37c: e6ff2073     	uxth	r2, r3
   2a380: e51b3068     	ldr	r3, [r11, #-0x68]
   2a384: e20210ff     	and	r1, r2, #255
   2a388: e3a00000     	mov	r0, #0
   2a38c: e1801001     	orr	r1, r0, r1
   2a390: e5c31012     	strb	r1, [r3, #0x12]
   2a394: e1a02422     	lsr	r2, r2, #8
   2a398: e6ff2072     	uxth	r2, r2
   2a39c: e3a01000     	mov	r1, #0
   2a3a0: e1812002     	orr	r2, r1, r2
   2a3a4: e5c32013     	strb	r2, [r3, #0x13]
   2a3a8: e51b3068     	ldr	r3, [r11, #-0x68]
   2a3ac: e5d32040     	ldrb	r2, [r3, #0x40]
   2a3b0: e5d31041     	ldrb	r1, [r3, #0x41]
   2a3b4: e1a01401     	lsl	r1, r1, #8
   2a3b8: e1812002     	orr	r2, r1, r2
   2a3bc: e5d31042     	ldrb	r1, [r3, #0x42]
   2a3c0: e1a01801     	lsl	r1, r1, #16
   2a3c4: e1812002     	orr	r2, r1, r2
   2a3c8: e5d33043     	ldrb	r3, [r3, #0x43]
   2a3cc: e1a03c03     	lsl	r3, r3, #24
   2a3d0: e1833002     	orr	r3, r3, r2
   2a3d4: e1a04003     	mov	r4, r3
   2a3d8: e1a02c24     	lsr	r2, r4, #24
   2a3dc: e20438ff     	and	r3, r4, #16711680
   2a3e0: e1a03423     	lsr	r3, r3, #8
   2a3e4: e1822003     	orr	r2, r2, r3
   2a3e8: e2043cff     	and	r3, r4, #65280
   2a3ec: e1a03403     	lsl	r3, r3, #8
   2a3f0: e1822003     	orr	r2, r2, r3
   2a3f4: e1a03c04     	lsl	r3, r4, #24
   2a3f8: e1822003     	orr	r2, r2, r3
   2a3fc: e51b3068     	ldr	r3, [r11, #-0x68]
   2a400: e20210ff     	and	r1, r2, #255
   2a404: e3a00000     	mov	r0, #0
   2a408: e1801001     	orr	r1, r0, r1
   2a40c: e5c31040     	strb	r1, [r3, #0x40]
   2a410: e1a01422     	lsr	r1, r2, #8
   2a414: e20110ff     	and	r1, r1, #255
   2a418: e3a00000     	mov	r0, #0
   2a41c: e1801001     	orr	r1, r0, r1
   2a420: e5c31041     	strb	r1, [r3, #0x41]
   2a424: e1a01822     	lsr	r1, r2, #16
   2a428: e20110ff     	and	r1, r1, #255
   2a42c: e3a00000     	mov	r0, #0
   2a430: e1801001     	orr	r1, r0, r1
   2a434: e5c31042     	strb	r1, [r3, #0x42]
   2a438: e1a02c22     	lsr	r2, r2, #24
   2a43c: e3a01000     	mov	r1, #0
   2a440: e1812002     	orr	r2, r1, r2
   2a444: e5c32043     	strb	r2, [r3, #0x43]
   2a448: e51b3068     	ldr	r3, [r11, #-0x68]
   2a44c: e5d32044     	ldrb	r2, [r3, #0x44]
   2a450: e5d31045     	ldrb	r1, [r3, #0x45]
   2a454: e1a01401     	lsl	r1, r1, #8
   2a458: e1812002     	orr	r2, r1, r2
   2a45c: e5d31046     	ldrb	r1, [r3, #0x46]
   2a460: e1a01801     	lsl	r1, r1, #16
   2a464: e1812002     	orr	r2, r1, r2
   2a468: e5d33047     	ldrb	r3, [r3, #0x47]
   2a46c: e1a03c03     	lsl	r3, r3, #24
   2a470: e1833002     	orr	r3, r3, r2
   2a474: e1a04003     	mov	r4, r3
   2a478: e1a02c24     	lsr	r2, r4, #24
   2a47c: e20438ff     	and	r3, r4, #16711680
   2a480: e1a03423     	lsr	r3, r3, #8
   2a484: e1822003     	orr	r2, r2, r3
   2a488: e2043cff     	and	r3, r4, #65280
   2a48c: e1a03403     	lsl	r3, r3, #8
   2a490: e1822003     	orr	r2, r2, r3
   2a494: e1a03c04     	lsl	r3, r4, #24
   2a498: e1822003     	orr	r2, r2, r3
   2a49c: e51b3068     	ldr	r3, [r11, #-0x68]
   2a4a0: e20210ff     	and	r1, r2, #255
   2a4a4: e3a00000     	mov	r0, #0
   2a4a8: e1801001     	orr	r1, r0, r1
   2a4ac: e5c31044     	strb	r1, [r3, #0x44]
   2a4b0: e1a01422     	lsr	r1, r2, #8
   2a4b4: e20110ff     	and	r1, r1, #255
   2a4b8: e3a00000     	mov	r0, #0
   2a4bc: e1801001     	orr	r1, r0, r1
   2a4c0: e5c31045     	strb	r1, [r3, #0x45]
   2a4c4: e1a01822     	lsr	r1, r2, #16
   2a4c8: e20110ff     	and	r1, r1, #255
   2a4cc: e3a00000     	mov	r0, #0
   2a4d0: e1801001     	orr	r1, r0, r1
   2a4d4: e5c31046     	strb	r1, [r3, #0x46]
   2a4d8: e1a02c22     	lsr	r2, r2, #24
   2a4dc: e3a01000     	mov	r1, #0
   2a4e0: e1812002     	orr	r2, r1, r2
   2a4e4: e5c32047     	strb	r2, [r3, #0x47]
   2a4e8: e51b3068     	ldr	r3, [r11, #-0x68]
   2a4ec: e5d32054     	ldrb	r2, [r3, #0x54]
   2a4f0: e5d33055     	ldrb	r3, [r3, #0x55]
   2a4f4: e1a03403     	lsl	r3, r3, #8
   2a4f8: e1833002     	orr	r3, r3, r2
   2a4fc: e14b35be     	strh	r3, [r11, #-94]
   2a500: e15b35be     	ldrh	r3, [r11, #-94]
   2a504: e1a03423     	lsr	r3, r3, #8
   2a508: e6ff3073     	uxth	r3, r3
   2a50c: e1a02003     	mov	r2, r3
   2a510: e15b35be     	ldrh	r3, [r11, #-94]
   2a514: e1a03403     	lsl	r3, r3, #8
   2a518: e1a03803     	lsl	r3, r3, #16
   2a51c: e1a03823     	lsr	r3, r3, #16
   2a520: e1823003     	orr	r3, r2, r3
   2a524: e6ff2073     	uxth	r2, r3
   2a528: e51b3068     	ldr	r3, [r11, #-0x68]
   2a52c: e20210ff     	and	r1, r2, #255
   2a530: e3a00000     	mov	r0, #0
   2a534: e1801001     	orr	r1, r0, r1
   2a538: e5c31054     	strb	r1, [r3, #0x54]
   2a53c: e1a02422     	lsr	r2, r2, #8
   2a540: e6ff2072     	uxth	r2, r2
   2a544: e3a01000     	mov	r1, #0
   2a548: e1812002     	orr	r2, r1, r2
   2a54c: e5c32055     	strb	r2, [r3, #0x55]
   2a550: e51b3068     	ldr	r3, [r11, #-0x68]
   2a554: e5d32048     	ldrb	r2, [r3, #0x48]
   2a558: e5d31049     	ldrb	r1, [r3, #0x49]
   2a55c: e1a01401     	lsl	r1, r1, #8
   2a560: e1812002     	orr	r2, r1, r2
   2a564: e5d3104a     	ldrb	r1, [r3, #0x4a]
   2a568: e1a01801     	lsl	r1, r1, #16
   2a56c: e1812002     	orr	r2, r1, r2
   2a570: e5d3304b     	ldrb	r3, [r3, #0x4b]
   2a574: e1a03c03     	lsl	r3, r3, #24
   2a578: e1833002     	orr	r3, r3, r2
   2a57c: e1a04003     	mov	r4, r3
   2a580: e1a02c24     	lsr	r2, r4, #24
   2a584: e20438ff     	and	r3, r4, #16711680
   2a588: e1a03423     	lsr	r3, r3, #8
   2a58c: e1822003     	orr	r2, r2, r3
   2a590: e2043cff     	and	r3, r4, #65280
   2a594: e1a03403     	lsl	r3, r3, #8
   2a598: e1822003     	orr	r2, r2, r3
   2a59c: e1a03c04     	lsl	r3, r4, #24
   2a5a0: e1822003     	orr	r2, r2, r3
   2a5a4: e51b3068     	ldr	r3, [r11, #-0x68]
   2a5a8: e20210ff     	and	r1, r2, #255
   2a5ac: e3a00000     	mov	r0, #0
   2a5b0: e1801001     	orr	r1, r0, r1
   2a5b4: e5c31048     	strb	r1, [r3, #0x48]
   2a5b8: e1a01422     	lsr	r1, r2, #8
   2a5bc: e20110ff     	and	r1, r1, #255
   2a5c0: e3a00000     	mov	r0, #0
   2a5c4: e1801001     	orr	r1, r0, r1
   2a5c8: e5c31049     	strb	r1, [r3, #0x49]
   2a5cc: e1a01822     	lsr	r1, r2, #16
   2a5d0: e20110ff     	and	r1, r1, #255
   2a5d4: e3a00000     	mov	r0, #0
   2a5d8: e1801001     	orr	r1, r0, r1
   2a5dc: e5c3104a     	strb	r1, [r3, #0x4a]
   2a5e0: e1a02c22     	lsr	r2, r2, #24
   2a5e4: e3a01000     	mov	r1, #0
   2a5e8: e1812002     	orr	r2, r1, r2
   2a5ec: e5c3204b     	strb	r2, [r3, #0x4b]
   2a5f0: e51b3068     	ldr	r3, [r11, #-0x68]
   2a5f4: e5d3204c     	ldrb	r2, [r3, #0x4c]
   2a5f8: e5d3104d     	ldrb	r1, [r3, #0x4d]
   2a5fc: e1a01401     	lsl	r1, r1, #8
   2a600: e1812002     	orr	r2, r1, r2
   2a604: e5d3104e     	ldrb	r1, [r3, #0x4e]
   2a608: e1a01801     	lsl	r1, r1, #16
   2a60c: e1812002     	orr	r2, r1, r2
   2a610: e5d3304f     	ldrb	r3, [r3, #0x4f]
   2a614: e1a03c03     	lsl	r3, r3, #24
   2a618: e1833002     	orr	r3, r3, r2
   2a61c: e1a04003     	mov	r4, r3
   2a620: e1a02c24     	lsr	r2, r4, #24
   2a624: e20438ff     	and	r3, r4, #16711680
   2a628: e1a03423     	lsr	r3, r3, #8
   2a62c: e1822003     	orr	r2, r2, r3
   2a630: e2043cff     	and	r3, r4, #65280
   2a634: e1a03403     	lsl	r3, r3, #8
   2a638: e1822003     	orr	r2, r2, r3
   2a63c: e1a03c04     	lsl	r3, r4, #24
   2a640: e1822003     	orr	r2, r2, r3
   2a644: e51b3068     	ldr	r3, [r11, #-0x68]
   2a648: e20210ff     	and	r1, r2, #255
   2a64c: e3a00000     	mov	r0, #0
   2a650: e1801001     	orr	r1, r0, r1
   2a654: e5c3104c     	strb	r1, [r3, #0x4c]
   2a658: e1a01422     	lsr	r1, r2, #8
   2a65c: e20110ff     	and	r1, r1, #255
   2a660: e3a00000     	mov	r0, #0
   2a664: e1801001     	orr	r1, r0, r1
   2a668: e5c3104d     	strb	r1, [r3, #0x4d]
   2a66c: e1a01822     	lsr	r1, r2, #16
   2a670: e20110ff     	and	r1, r1, #255
   2a674: e3a00000     	mov	r0, #0
   2a678: e1801001     	orr	r1, r0, r1
   2a67c: e5c3104e     	strb	r1, [r3, #0x4e]
   2a680: e1a02c22     	lsr	r2, r2, #24
   2a684: e3a01000     	mov	r1, #0
   2a688: e1812002     	orr	r2, r1, r2
   2a68c: e5c3204f     	strb	r2, [r3, #0x4f]
   2a690: e51b3068     	ldr	r3, [r11, #-0x68]
   2a694: e5d32056     	ldrb	r2, [r3, #0x56]
   2a698: e5d33057     	ldrb	r3, [r3, #0x57]
   2a69c: e1a03403     	lsl	r3, r3, #8
   2a6a0: e1833002     	orr	r3, r3, r2
   2a6a4: e14b35bc     	strh	r3, [r11, #-92]
   2a6a8: e15b35bc     	ldrh	r3, [r11, #-92]
   2a6ac: e1a03423     	lsr	r3, r3, #8
   2a6b0: e6ff3073     	uxth	r3, r3
   2a6b4: e1a02003     	mov	r2, r3
   2a6b8: e15b35bc     	ldrh	r3, [r11, #-92]
   2a6bc: e1a03403     	lsl	r3, r3, #8
   2a6c0: e1a03803     	lsl	r3, r3, #16
   2a6c4: e1a03823     	lsr	r3, r3, #16
   2a6c8: e1823003     	orr	r3, r2, r3
   2a6cc: e6ff2073     	uxth	r2, r3
   2a6d0: e51b3068     	ldr	r3, [r11, #-0x68]
   2a6d4: e20210ff     	and	r1, r2, #255
   2a6d8: e3a00000     	mov	r0, #0
   2a6dc: e1801001     	orr	r1, r0, r1
   2a6e0: e5c31056     	strb	r1, [r3, #0x56]
   2a6e4: e1a02422     	lsr	r2, r2, #8
   2a6e8: e6ff2072     	uxth	r2, r2
   2a6ec: e3a01000     	mov	r1, #0
   2a6f0: e1812002     	orr	r2, r1, r2
   2a6f4: e5c32057     	strb	r2, [r3, #0x57]
   2a6f8: e51b3068     	ldr	r3, [r11, #-0x68]
   2a6fc: e5d32078     	ldrb	r2, [r3, #0x78]
   2a700: e5d33079     	ldrb	r3, [r3, #0x79]
   2a704: e1a03403     	lsl	r3, r3, #8
   2a708: e1833002     	orr	r3, r3, r2
   2a70c: e14b35ba     	strh	r3, [r11, #-90]
   2a710: e15b35ba     	ldrh	r3, [r11, #-90]
   2a714: e1a03423     	lsr	r3, r3, #8
   2a718: e6ff3073     	uxth	r3, r3
   2a71c: e1a02003     	mov	r2, r3
   2a720: e15b35ba     	ldrh	r3, [r11, #-90]
   2a724: e1a03403     	lsl	r3, r3, #8
   2a728: e1a03803     	lsl	r3, r3, #16
   2a72c: e1a03823     	lsr	r3, r3, #16
   2a730: e1823003     	orr	r3, r2, r3
   2a734: e6ff2073     	uxth	r2, r3
   2a738: e51b3068     	ldr	r3, [r11, #-0x68]
   2a73c: e20210ff     	and	r1, r2, #255
   2a740: e3a00000     	mov	r0, #0
   2a744: e1801001     	orr	r1, r0, r1
   2a748: e5c31078     	strb	r1, [r3, #0x78]
   2a74c: e1a02422     	lsr	r2, r2, #8
   2a750: e6ff2072     	uxth	r2, r2
   2a754: e3a01000     	mov	r1, #0
   2a758: e1812002     	orr	r2, r1, r2
   2a75c: e5c32079     	strb	r2, [r3, #0x79]
   2a760: e51b3068     	ldr	r3, [r11, #-0x68]
   2a764: e5d33008     	ldrb	r3, [r3, #0x8]
   2a768: e3530001     	cmp	r3, #1
   2a76c: 8a000003     	bhi	0x2a780 <scarletbook_read_master_toc+0x584> @ imm = #0xc
   2a770: e51b3068     	ldr	r3, [r11, #-0x68]
   2a774: e5d33009     	ldrb	r3, [r3, #0x9]
   2a778: e3530014     	cmp	r3, #20
   2a77c: 9a00000b     	bls	0x2a7b0 <scarletbook_read_master_toc+0x5b4> @ imm = #0x2c
   2a780: e59f390c     	ldr	r3, [pc, #0x90c]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2a784: e5933000     	ldr	r3, [r3]
   2a788: e1a00003     	mov	r0, r3
   2a78c: e59f1888     	ldr	r1, [pc, #0x888]        @ 0x2b01c <scarletbook_read_master_toc+0xe20>
   2a790: e51b3068     	ldr	r3, [r11, #-0x68]
   2a794: e5d33008     	ldrb	r3, [r3, #0x8]
   2a798: e1a02003     	mov	r2, r3
   2a79c: e51b3068     	ldr	r3, [r11, #-0x68]
   2a7a0: e5d33009     	ldrb	r3, [r3, #0x9]
   2a7a4: ebff87a6     	bl	0xc644 <fprintf@plt>    @ imm = #-0x1e168
   2a7a8: e3a03000     	mov	r3, #0
   2a7ac: ea00064b     	b	0x2c0e0 <scarletbook_read_master_toc+0x1ee4> @ imm = #0x192c
   2a7b0: e51b3068     	ldr	r3, [r11, #-0x68]
   2a7b4: e283300a     	add	r3, r3, #10
   2a7b8: e59f0860     	ldr	r0, [pc, #0x860]        @ 0x2b020 <scarletbook_read_master_toc+0xe24>
   2a7bc: e1a01003     	mov	r1, r3
   2a7c0: e3a02006     	mov	r2, #6
   2a7c4: ebff86ab     	bl	0xc278 <memcmp@plt>     @ imm = #-0x1e554
   2a7c8: e1a03000     	mov	r3, r0
   2a7cc: e3530000     	cmp	r3, #0
   2a7d0: 0a000025     	beq	0x2a86c <scarletbook_read_master_toc+0x670> @ imm = #0x94
   2a7d4: e59f38b8     	ldr	r3, [pc, #0x8b8]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2a7d8: e5933000     	ldr	r3, [r3]
   2a7dc: e1a02003     	mov	r2, r3
   2a7e0: e59f383c     	ldr	r3, [pc, #0x83c]        @ 0x2b024 <scarletbook_read_master_toc+0xe28>
   2a7e4: e59f183c     	ldr	r1, [pc, #0x83c]        @ 0x2b028 <scarletbook_read_master_toc+0xe2c>
   2a7e8: e58d1000     	str	r1, [sp]
   2a7ec: e1a00002     	mov	r0, r2
   2a7f0: e1a01003     	mov	r1, r3
   2a7f4: e59f2830     	ldr	r2, [pc, #0x830]        @ 0x2b02c <scarletbook_read_master_toc+0xe30>
   2a7f8: e3a03c01     	mov	r3, #256
   2a7fc: ebff8790     	bl	0xc644 <fprintf@plt>    @ imm = #-0x1e1c0
   2a800: e3a03000     	mov	r3, #0
   2a804: e50b3058     	str	r3, [r11, #-0x58]
   2a808: ea00000f     	b	0x2a84c <scarletbook_read_master_toc+0x650> @ imm = #0x3c
   2a80c: e59f3880     	ldr	r3, [pc, #0x880]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2a810: e5933000     	ldr	r3, [r3]
   2a814: e1a01003     	mov	r1, r3
   2a818: e59f2870     	ldr	r2, [pc, #0x870]        @ 0x2b090 <scarletbook_read_master_toc+0xe94>
   2a81c: e51b3068     	ldr	r3, [r11, #-0x68]
   2a820: e283000a     	add	r0, r3, #10
   2a824: e51b3058     	ldr	r3, [r11, #-0x58]
   2a828: e0803003     	add	r3, r0, r3
   2a82c: e5d33000     	ldrb	r3, [r3]
   2a830: e1a00001     	mov	r0, r1
   2a834: e1a01002     	mov	r1, r2
   2a838: e1a02003     	mov	r2, r3
   2a83c: ebff8780     	bl	0xc644 <fprintf@plt>    @ imm = #-0x1e200
   2a840: e51b3058     	ldr	r3, [r11, #-0x58]
   2a844: e2833001     	add	r3, r3, #1
   2a848: e50b3058     	str	r3, [r11, #-0x58]
   2a84c: e51b3058     	ldr	r3, [r11, #-0x58]
   2a850: e3530005     	cmp	r3, #5
   2a854: 9affffec     	bls	0x2a80c <scarletbook_read_master_toc+0x610> @ imm = #-0x50
   2a858: e59f3834     	ldr	r3, [pc, #0x834]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2a85c: e5933000     	ldr	r3, [r3]
   2a860: e3a0000a     	mov	r0, #10
   2a864: e1a01003     	mov	r1, r3
   2a868: ebff8790     	bl	0xc6b0 <fputc@plt>      @ imm = #-0x1e1c0
   2a86c: e51b3068     	ldr	r3, [r11, #-0x68]
   2a870: e2833014     	add	r3, r3, #20
   2a874: e59f07a4     	ldr	r0, [pc, #0x7a4]        @ 0x2b020 <scarletbook_read_master_toc+0xe24>
   2a878: e1a01003     	mov	r1, r3
   2a87c: e3a02004     	mov	r2, #4
   2a880: ebff867c     	bl	0xc278 <memcmp@plt>     @ imm = #-0x1e610
   2a884: e1a03000     	mov	r3, r0
   2a888: e3530000     	cmp	r3, #0
   2a88c: 0a000025     	beq	0x2a928 <scarletbook_read_master_toc+0x72c> @ imm = #0x94
   2a890: e59f37fc     	ldr	r3, [pc, #0x7fc]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2a894: e5933000     	ldr	r3, [r3]
   2a898: e1a02003     	mov	r2, r3
   2a89c: e59f3780     	ldr	r3, [pc, #0x780]        @ 0x2b024 <scarletbook_read_master_toc+0xe28>
   2a8a0: e59f1788     	ldr	r1, [pc, #0x788]        @ 0x2b030 <scarletbook_read_master_toc+0xe34>
   2a8a4: e58d1000     	str	r1, [sp]
   2a8a8: e1a00002     	mov	r0, r2
   2a8ac: e1a01003     	mov	r1, r3
   2a8b0: e59f2774     	ldr	r2, [pc, #0x774]        @ 0x2b02c <scarletbook_read_master_toc+0xe30>
   2a8b4: e59f3778     	ldr	r3, [pc, #0x778]        @ 0x2b034 <scarletbook_read_master_toc+0xe38>
   2a8b8: ebff8761     	bl	0xc644 <fprintf@plt>    @ imm = #-0x1e27c
   2a8bc: e3a03000     	mov	r3, #0
   2a8c0: e50b3054     	str	r3, [r11, #-0x54]
   2a8c4: ea00000f     	b	0x2a908 <scarletbook_read_master_toc+0x70c> @ imm = #0x3c
   2a8c8: e59f37c4     	ldr	r3, [pc, #0x7c4]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2a8cc: e5933000     	ldr	r3, [r3]
   2a8d0: e1a01003     	mov	r1, r3
   2a8d4: e59f27b4     	ldr	r2, [pc, #0x7b4]        @ 0x2b090 <scarletbook_read_master_toc+0xe94>
   2a8d8: e51b3068     	ldr	r3, [r11, #-0x68]
   2a8dc: e2830014     	add	r0, r3, #20
   2a8e0: e51b3054     	ldr	r3, [r11, #-0x54]
   2a8e4: e0803003     	add	r3, r0, r3
   2a8e8: e5d33000     	ldrb	r3, [r3]
   2a8ec: e1a00001     	mov	r0, r1
   2a8f0: e1a01002     	mov	r1, r2
   2a8f4: e1a02003     	mov	r2, r3
   2a8f8: ebff8751     	bl	0xc644 <fprintf@plt>    @ imm = #-0x1e2bc
   2a8fc: e51b3054     	ldr	r3, [r11, #-0x54]
   2a900: e2833001     	add	r3, r3, #1
   2a904: e50b3054     	str	r3, [r11, #-0x54]
   2a908: e51b3054     	ldr	r3, [r11, #-0x54]
   2a90c: e3530003     	cmp	r3, #3
   2a910: 9affffec     	bls	0x2a8c8 <scarletbook_read_master_toc+0x6cc> @ imm = #-0x50
   2a914: e59f3778     	ldr	r3, [pc, #0x778]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2a918: e5933000     	ldr	r3, [r3]
   2a91c: e3a0000a     	mov	r0, #10
   2a920: e1a01003     	mov	r1, r3
   2a924: ebff8761     	bl	0xc6b0 <fputc@plt>      @ imm = #-0x1e27c
   2a928: e51b3068     	ldr	r3, [r11, #-0x68]
   2a92c: e2833038     	add	r3, r3, #56
   2a930: e59f06e8     	ldr	r0, [pc, #0x6e8]        @ 0x2b020 <scarletbook_read_master_toc+0xe24>
   2a934: e1a01003     	mov	r1, r3
   2a938: e3a02008     	mov	r2, #8
   2a93c: ebff864d     	bl	0xc278 <memcmp@plt>     @ imm = #-0x1e6cc
   2a940: e1a03000     	mov	r3, r0
   2a944: e3530000     	cmp	r3, #0
   2a948: 0a000025     	beq	0x2a9e4 <scarletbook_read_master_toc+0x7e8> @ imm = #0x94
   2a94c: e59f3740     	ldr	r3, [pc, #0x740]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2a950: e5933000     	ldr	r3, [r3]
   2a954: e1a02003     	mov	r2, r3
   2a958: e59f36c4     	ldr	r3, [pc, #0x6c4]        @ 0x2b024 <scarletbook_read_master_toc+0xe28>
   2a95c: e59f16d4     	ldr	r1, [pc, #0x6d4]        @ 0x2b038 <scarletbook_read_master_toc+0xe3c>
   2a960: e58d1000     	str	r1, [sp]
   2a964: e1a00002     	mov	r0, r2
   2a968: e1a01003     	mov	r1, r3
   2a96c: e59f26b8     	ldr	r2, [pc, #0x6b8]        @ 0x2b02c <scarletbook_read_master_toc+0xe30>
   2a970: e59f36c4     	ldr	r3, [pc, #0x6c4]        @ 0x2b03c <scarletbook_read_master_toc+0xe40>
   2a974: ebff8732     	bl	0xc644 <fprintf@plt>    @ imm = #-0x1e338
   2a978: e3a03000     	mov	r3, #0
   2a97c: e50b3050     	str	r3, [r11, #-0x50]
   2a980: ea00000f     	b	0x2a9c4 <scarletbook_read_master_toc+0x7c8> @ imm = #0x3c
   2a984: e59f3708     	ldr	r3, [pc, #0x708]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2a988: e5933000     	ldr	r3, [r3]
   2a98c: e1a01003     	mov	r1, r3
   2a990: e59f26f8     	ldr	r2, [pc, #0x6f8]        @ 0x2b090 <scarletbook_read_master_toc+0xe94>
   2a994: e51b3068     	ldr	r3, [r11, #-0x68]
   2a998: e2830038     	add	r0, r3, #56
   2a99c: e51b3050     	ldr	r3, [r11, #-0x50]
   2a9a0: e0803003     	add	r3, r0, r3
   2a9a4: e5d33000     	ldrb	r3, [r3]
   2a9a8: e1a00001     	mov	r0, r1
   2a9ac: e1a01002     	mov	r1, r2
   2a9b0: e1a02003     	mov	r2, r3
   2a9b4: ebff8722     	bl	0xc644 <fprintf@plt>    @ imm = #-0x1e378
   2a9b8: e51b3050     	ldr	r3, [r11, #-0x50]
   2a9bc: e2833001     	add	r3, r3, #1
   2a9c0: e50b3050     	str	r3, [r11, #-0x50]
   2a9c4: e51b3050     	ldr	r3, [r11, #-0x50]
   2a9c8: e3530007     	cmp	r3, #7
   2a9cc: 9affffec     	bls	0x2a984 <scarletbook_read_master_toc+0x788> @ imm = #-0x50
   2a9d0: e59f36bc     	ldr	r3, [pc, #0x6bc]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2a9d4: e5933000     	ldr	r3, [r3]
   2a9d8: e3a0000a     	mov	r0, #10
   2a9dc: e1a01003     	mov	r1, r3
   2a9e0: ebff8732     	bl	0xc6b0 <fputc@plt>      @ imm = #-0x1e338
   2a9e4: e51b3068     	ldr	r3, [r11, #-0x68]
   2a9e8: e2833051     	add	r3, r3, #81
   2a9ec: e59f062c     	ldr	r0, [pc, #0x62c]        @ 0x2b020 <scarletbook_read_master_toc+0xe24>
   2a9f0: e1a01003     	mov	r1, r3
   2a9f4: e3a02003     	mov	r2, #3
   2a9f8: ebff861e     	bl	0xc278 <memcmp@plt>     @ imm = #-0x1e788
   2a9fc: e1a03000     	mov	r3, r0
   2aa00: e3530000     	cmp	r3, #0
   2aa04: 0a000025     	beq	0x2aaa0 <scarletbook_read_master_toc+0x8a4> @ imm = #0x94
   2aa08: e59f3684     	ldr	r3, [pc, #0x684]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2aa0c: e5933000     	ldr	r3, [r3]
   2aa10: e1a02003     	mov	r2, r3
   2aa14: e59f3608     	ldr	r3, [pc, #0x608]        @ 0x2b024 <scarletbook_read_master_toc+0xe28>
   2aa18: e59f1620     	ldr	r1, [pc, #0x620]        @ 0x2b040 <scarletbook_read_master_toc+0xe44>
   2aa1c: e58d1000     	str	r1, [sp]
   2aa20: e1a00002     	mov	r0, r2
   2aa24: e1a01003     	mov	r1, r3
   2aa28: e59f25fc     	ldr	r2, [pc, #0x5fc]        @ 0x2b02c <scarletbook_read_master_toc+0xe30>
   2aa2c: e59f3610     	ldr	r3, [pc, #0x610]        @ 0x2b044 <scarletbook_read_master_toc+0xe48>
   2aa30: ebff8703     	bl	0xc644 <fprintf@plt>    @ imm = #-0x1e3f4
   2aa34: e3a03000     	mov	r3, #0
   2aa38: e50b304c     	str	r3, [r11, #-0x4c]
   2aa3c: ea00000f     	b	0x2aa80 <scarletbook_read_master_toc+0x884> @ imm = #0x3c
   2aa40: e59f364c     	ldr	r3, [pc, #0x64c]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2aa44: e5933000     	ldr	r3, [r3]
   2aa48: e1a01003     	mov	r1, r3
   2aa4c: e59f263c     	ldr	r2, [pc, #0x63c]        @ 0x2b090 <scarletbook_read_master_toc+0xe94>
   2aa50: e51b3068     	ldr	r3, [r11, #-0x68]
   2aa54: e2830051     	add	r0, r3, #81
   2aa58: e51b304c     	ldr	r3, [r11, #-0x4c]
   2aa5c: e0803003     	add	r3, r0, r3
   2aa60: e5d33000     	ldrb	r3, [r3]
   2aa64: e1a00001     	mov	r0, r1
   2aa68: e1a01002     	mov	r1, r2
   2aa6c: e1a02003     	mov	r2, r3
   2aa70: ebff86f3     	bl	0xc644 <fprintf@plt>    @ imm = #-0x1e434
   2aa74: e51b304c     	ldr	r3, [r11, #-0x4c]
   2aa78: e2833001     	add	r3, r3, #1
   2aa7c: e50b304c     	str	r3, [r11, #-0x4c]
   2aa80: e51b304c     	ldr	r3, [r11, #-0x4c]
   2aa84: e3530002     	cmp	r3, #2
   2aa88: 9affffec     	bls	0x2aa40 <scarletbook_read_master_toc+0x844> @ imm = #-0x50
   2aa8c: e59f3600     	ldr	r3, [pc, #0x600]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2aa90: e5933000     	ldr	r3, [r3]
   2aa94: e3a0000a     	mov	r0, #10
   2aa98: e1a01003     	mov	r1, r3
   2aa9c: ebff8703     	bl	0xc6b0 <fputc@plt>      @ imm = #-0x1e3f4
   2aaa0: e51b3068     	ldr	r3, [r11, #-0x68]
   2aaa4: e283307c     	add	r3, r3, #124
   2aaa8: e59f0570     	ldr	r0, [pc, #0x570]        @ 0x2b020 <scarletbook_read_master_toc+0xe24>
   2aaac: e1a01003     	mov	r1, r3
   2aab0: e3a02004     	mov	r2, #4
   2aab4: ebff85ef     	bl	0xc278 <memcmp@plt>     @ imm = #-0x1e844
   2aab8: e1a03000     	mov	r3, r0
   2aabc: e3530000     	cmp	r3, #0
   2aac0: 0a000025     	beq	0x2ab5c <scarletbook_read_master_toc+0x960> @ imm = #0x94
   2aac4: e59f35c8     	ldr	r3, [pc, #0x5c8]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2aac8: e5933000     	ldr	r3, [r3]
   2aacc: e1a02003     	mov	r2, r3
   2aad0: e59f354c     	ldr	r3, [pc, #0x54c]        @ 0x2b024 <scarletbook_read_master_toc+0xe28>
   2aad4: e59f156c     	ldr	r1, [pc, #0x56c]        @ 0x2b048 <scarletbook_read_master_toc+0xe4c>
   2aad8: e58d1000     	str	r1, [sp]
   2aadc: e1a00002     	mov	r0, r2
   2aae0: e1a01003     	mov	r1, r3
   2aae4: e59f2540     	ldr	r2, [pc, #0x540]        @ 0x2b02c <scarletbook_read_master_toc+0xe30>
   2aae8: e3a03f41     	mov	r3, #260
   2aaec: ebff86d4     	bl	0xc644 <fprintf@plt>    @ imm = #-0x1e4b0
   2aaf0: e3a03000     	mov	r3, #0
   2aaf4: e50b3048     	str	r3, [r11, #-0x48]
   2aaf8: ea00000f     	b	0x2ab3c <scarletbook_read_master_toc+0x940> @ imm = #0x3c
   2aafc: e59f3590     	ldr	r3, [pc, #0x590]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2ab00: e5933000     	ldr	r3, [r3]
   2ab04: e1a01003     	mov	r1, r3
   2ab08: e59f2580     	ldr	r2, [pc, #0x580]        @ 0x2b090 <scarletbook_read_master_toc+0xe94>
   2ab0c: e51b3068     	ldr	r3, [r11, #-0x68]
   2ab10: e283007c     	add	r0, r3, #124
   2ab14: e51b3048     	ldr	r3, [r11, #-0x48]
   2ab18: e0803003     	add	r3, r0, r3
   2ab1c: e5d33000     	ldrb	r3, [r3]
   2ab20: e1a00001     	mov	r0, r1
   2ab24: e1a01002     	mov	r1, r2
   2ab28: e1a02003     	mov	r2, r3
   2ab2c: ebff86c4     	bl	0xc644 <fprintf@plt>    @ imm = #-0x1e4f0
   2ab30: e51b3048     	ldr	r3, [r11, #-0x48]
   2ab34: e2833001     	add	r3, r3, #1
   2ab38: e50b3048     	str	r3, [r11, #-0x48]
   2ab3c: e51b3048     	ldr	r3, [r11, #-0x48]
   2ab40: e3530003     	cmp	r3, #3
   2ab44: 9affffec     	bls	0x2aafc <scarletbook_read_master_toc+0x900> @ imm = #-0x50
   2ab48: e59f3544     	ldr	r3, [pc, #0x544]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2ab4c: e5933000     	ldr	r3, [r3]
   2ab50: e3a0000a     	mov	r0, #10
   2ab54: e1a01003     	mov	r1, r3
   2ab58: ebff86d4     	bl	0xc6b0 <fputc@plt>      @ imm = #-0x1e4b0
   2ab5c: e51b3068     	ldr	r3, [r11, #-0x68]
   2ab60: e2833081     	add	r3, r3, #129
   2ab64: e59f04b4     	ldr	r0, [pc, #0x4b4]        @ 0x2b020 <scarletbook_read_master_toc+0xe24>
   2ab68: e1a01003     	mov	r1, r3
   2ab6c: e3a02007     	mov	r2, #7
   2ab70: ebff85c0     	bl	0xc278 <memcmp@plt>     @ imm = #-0x1e900
   2ab74: e1a03000     	mov	r3, r0
   2ab78: e3530000     	cmp	r3, #0
   2ab7c: 0a000025     	beq	0x2ac18 <scarletbook_read_master_toc+0xa1c> @ imm = #0x94
   2ab80: e59f350c     	ldr	r3, [pc, #0x50c]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2ab84: e5933000     	ldr	r3, [r3]
   2ab88: e1a02003     	mov	r2, r3
   2ab8c: e59f3490     	ldr	r3, [pc, #0x490]        @ 0x2b024 <scarletbook_read_master_toc+0xe28>
   2ab90: e59f14b4     	ldr	r1, [pc, #0x4b4]        @ 0x2b04c <scarletbook_read_master_toc+0xe50>
   2ab94: e58d1000     	str	r1, [sp]
   2ab98: e1a00002     	mov	r0, r2
   2ab9c: e1a01003     	mov	r1, r3
   2aba0: e59f2484     	ldr	r2, [pc, #0x484]        @ 0x2b02c <scarletbook_read_master_toc+0xe30>
   2aba4: e59f34a4     	ldr	r3, [pc, #0x4a4]        @ 0x2b050 <scarletbook_read_master_toc+0xe54>
   2aba8: ebff86a5     	bl	0xc644 <fprintf@plt>    @ imm = #-0x1e56c
   2abac: e3a03000     	mov	r3, #0
   2abb0: e50b3044     	str	r3, [r11, #-0x44]
   2abb4: ea00000f     	b	0x2abf8 <scarletbook_read_master_toc+0x9fc> @ imm = #0x3c
   2abb8: e59f34d4     	ldr	r3, [pc, #0x4d4]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2abbc: e5933000     	ldr	r3, [r3]
   2abc0: e1a01003     	mov	r1, r3
   2abc4: e59f24c4     	ldr	r2, [pc, #0x4c4]        @ 0x2b090 <scarletbook_read_master_toc+0xe94>
   2abc8: e51b3068     	ldr	r3, [r11, #-0x68]
   2abcc: e2830081     	add	r0, r3, #129
   2abd0: e51b3044     	ldr	r3, [r11, #-0x44]
   2abd4: e0803003     	add	r3, r0, r3
   2abd8: e5d33000     	ldrb	r3, [r3]
   2abdc: e1a00001     	mov	r0, r1
   2abe0: e1a01002     	mov	r1, r2
   2abe4: e1a02003     	mov	r2, r3
   2abe8: ebff8695     	bl	0xc644 <fprintf@plt>    @ imm = #-0x1e5ac
   2abec: e51b3044     	ldr	r3, [r11, #-0x44]
   2abf0: e2833001     	add	r3, r3, #1
   2abf4: e50b3044     	str	r3, [r11, #-0x44]
   2abf8: e51b3044     	ldr	r3, [r11, #-0x44]
   2abfc: e3530006     	cmp	r3, #6
   2ac00: 9affffec     	bls	0x2abb8 <scarletbook_read_master_toc+0x9bc> @ imm = #-0x50
   2ac04: e59f3488     	ldr	r3, [pc, #0x488]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2ac08: e5933000     	ldr	r3, [r3]
   2ac0c: e3a0000a     	mov	r0, #10
   2ac10: e1a01003     	mov	r1, r3
   2ac14: ebff86a5     	bl	0xc6b0 <fputc@plt>      @ imm = #-0x1e56c
   2ac18: e3a03000     	mov	r3, #0
   2ac1c: e50b3070     	str	r3, [r11, #-0x70]
   2ac20: ea0000be     	b	0x2af20 <scarletbook_read_master_toc+0xd24> @ imm = #0x2f8
   2ac24: e51b3070     	ldr	r3, [r11, #-0x70]
   2ac28: e283300a     	add	r3, r3, #10
   2ac2c: e1a03103     	lsl	r3, r3, #2
   2ac30: e51b2068     	ldr	r2, [r11, #-0x68]
   2ac34: e0823003     	add	r3, r2, r3
   2ac38: e2833001     	add	r3, r3, #1
   2ac3c: e59f03dc     	ldr	r0, [pc, #0x3dc]        @ 0x2b020 <scarletbook_read_master_toc+0xe24>
   2ac40: e1a01003     	mov	r1, r3
   2ac44: e3a02002     	mov	r2, #2
   2ac48: ebff858a     	bl	0xc278 <memcmp@plt>     @ imm = #-0x1e9d8
   2ac4c: e1a03000     	mov	r3, r0
   2ac50: e3530000     	cmp	r3, #0
   2ac54: 0a00002a     	beq	0x2ad04 <scarletbook_read_master_toc+0xb08> @ imm = #0xa8
   2ac58: e59f3434     	ldr	r3, [pc, #0x434]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2ac5c: e5933000     	ldr	r3, [r3]
   2ac60: e1a02003     	mov	r2, r3
   2ac64: e59f33b8     	ldr	r3, [pc, #0x3b8]        @ 0x2b024 <scarletbook_read_master_toc+0xe28>
   2ac68: e59f13e4     	ldr	r1, [pc, #0x3e4]        @ 0x2b054 <scarletbook_read_master_toc+0xe58>
   2ac6c: e58d1000     	str	r1, [sp]
   2ac70: e1a00002     	mov	r0, r2
   2ac74: e1a01003     	mov	r1, r3
   2ac78: e59f23ac     	ldr	r2, [pc, #0x3ac]        @ 0x2b02c <scarletbook_read_master_toc+0xe30>
   2ac7c: e3a03f42     	mov	r3, #264
   2ac80: ebff866f     	bl	0xc644 <fprintf@plt>    @ imm = #-0x1e644
   2ac84: e3a03000     	mov	r3, #0
   2ac88: e50b3040     	str	r3, [r11, #-0x40]
   2ac8c: ea000014     	b	0x2ace4 <scarletbook_read_master_toc+0xae8> @ imm = #0x50
   2ac90: e59f33fc     	ldr	r3, [pc, #0x3fc]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2ac94: e5933000     	ldr	r3, [r3]
   2ac98: e1a01003     	mov	r1, r3
   2ac9c: e59f23ec     	ldr	r2, [pc, #0x3ec]        @ 0x2b090 <scarletbook_read_master_toc+0xe94>
   2aca0: e51b3070     	ldr	r3, [r11, #-0x70]
   2aca4: e283300a     	add	r3, r3, #10
   2aca8: e1a03103     	lsl	r3, r3, #2
   2acac: e51b0068     	ldr	r0, [r11, #-0x68]
   2acb0: e0803003     	add	r3, r0, r3
   2acb4: e2833001     	add	r3, r3, #1
   2acb8: e1a00003     	mov	r0, r3
   2acbc: e51b3040     	ldr	r3, [r11, #-0x40]
   2acc0: e0803003     	add	r3, r0, r3
   2acc4: e5d33000     	ldrb	r3, [r3]
   2acc8: e1a00001     	mov	r0, r1
   2accc: e1a01002     	mov	r1, r2
   2acd0: e1a02003     	mov	r2, r3
   2acd4: ebff865a     	bl	0xc644 <fprintf@plt>    @ imm = #-0x1e698
   2acd8: e51b3040     	ldr	r3, [r11, #-0x40]
   2acdc: e2833001     	add	r3, r3, #1
   2ace0: e50b3040     	str	r3, [r11, #-0x40]
   2ace4: e51b3040     	ldr	r3, [r11, #-0x40]
   2ace8: e3530001     	cmp	r3, #1
   2acec: 9affffe7     	bls	0x2ac90 <scarletbook_read_master_toc+0xa94> @ imm = #-0x64
   2acf0: e59f339c     	ldr	r3, [pc, #0x39c]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2acf4: e5933000     	ldr	r3, [r3]
   2acf8: e3a0000a     	mov	r0, #10
   2acfc: e1a01003     	mov	r1, r3
   2ad00: ebff866a     	bl	0xc6b0 <fputc@plt>      @ imm = #-0x1e658
   2ad04: e51b3070     	ldr	r3, [r11, #-0x70]
   2ad08: e283301a     	add	r3, r3, #26
   2ad0c: e1a03103     	lsl	r3, r3, #2
   2ad10: e51b2068     	ldr	r2, [r11, #-0x68]
   2ad14: e0823003     	add	r3, r2, r3
   2ad18: e2833001     	add	r3, r3, #1
   2ad1c: e59f02fc     	ldr	r0, [pc, #0x2fc]        @ 0x2b020 <scarletbook_read_master_toc+0xe24>
   2ad20: e1a01003     	mov	r1, r3
   2ad24: e3a02002     	mov	r2, #2
   2ad28: ebff8552     	bl	0xc278 <memcmp@plt>     @ imm = #-0x1eab8
   2ad2c: e1a03000     	mov	r3, r0
   2ad30: e3530000     	cmp	r3, #0
   2ad34: 0a00002a     	beq	0x2ade4 <scarletbook_read_master_toc+0xbe8> @ imm = #0xa8
   2ad38: e59f3354     	ldr	r3, [pc, #0x354]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2ad3c: e5933000     	ldr	r3, [r3]
   2ad40: e1a02003     	mov	r2, r3
   2ad44: e59f32d8     	ldr	r3, [pc, #0x2d8]        @ 0x2b024 <scarletbook_read_master_toc+0xe28>
   2ad48: e59f1308     	ldr	r1, [pc, #0x308]        @ 0x2b058 <scarletbook_read_master_toc+0xe5c>
   2ad4c: e58d1000     	str	r1, [sp]
   2ad50: e1a00002     	mov	r0, r2
   2ad54: e1a01003     	mov	r1, r3
   2ad58: e59f22cc     	ldr	r2, [pc, #0x2cc]        @ 0x2b02c <scarletbook_read_master_toc+0xe30>
   2ad5c: e59f32f8     	ldr	r3, [pc, #0x2f8]        @ 0x2b05c <scarletbook_read_master_toc+0xe60>
   2ad60: ebff8637     	bl	0xc644 <fprintf@plt>    @ imm = #-0x1e724
   2ad64: e3a03000     	mov	r3, #0
   2ad68: e50b303c     	str	r3, [r11, #-0x3c]
   2ad6c: ea000014     	b	0x2adc4 <scarletbook_read_master_toc+0xbc8> @ imm = #0x50
   2ad70: e59f331c     	ldr	r3, [pc, #0x31c]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2ad74: e5933000     	ldr	r3, [r3]
   2ad78: e1a01003     	mov	r1, r3
   2ad7c: e59f230c     	ldr	r2, [pc, #0x30c]        @ 0x2b090 <scarletbook_read_master_toc+0xe94>
   2ad80: e51b3070     	ldr	r3, [r11, #-0x70]
   2ad84: e283301a     	add	r3, r3, #26
   2ad88: e1a03103     	lsl	r3, r3, #2
   2ad8c: e51b0068     	ldr	r0, [r11, #-0x68]
   2ad90: e0803003     	add	r3, r0, r3
   2ad94: e2833001     	add	r3, r3, #1
   2ad98: e1a00003     	mov	r0, r3
   2ad9c: e51b303c     	ldr	r3, [r11, #-0x3c]
   2ada0: e0803003     	add	r3, r0, r3
   2ada4: e5d33000     	ldrb	r3, [r3]
   2ada8: e1a00001     	mov	r0, r1
   2adac: e1a01002     	mov	r1, r2
   2adb0: e1a02003     	mov	r2, r3
   2adb4: ebff8622     	bl	0xc644 <fprintf@plt>    @ imm = #-0x1e778
   2adb8: e51b303c     	ldr	r3, [r11, #-0x3c]
   2adbc: e2833001     	add	r3, r3, #1
   2adc0: e50b303c     	str	r3, [r11, #-0x3c]
   2adc4: e51b303c     	ldr	r3, [r11, #-0x3c]
   2adc8: e3530001     	cmp	r3, #1
   2adcc: 9affffe7     	bls	0x2ad70 <scarletbook_read_master_toc+0xb74> @ imm = #-0x64
   2add0: e59f32bc     	ldr	r3, [pc, #0x2bc]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2add4: e5933000     	ldr	r3, [r3]
   2add8: e3a0000a     	mov	r0, #10
   2addc: e1a01003     	mov	r1, r3
   2ade0: ebff8632     	bl	0xc6b0 <fputc@plt>      @ imm = #-0x1e738
   2ade4: e51b2070     	ldr	r2, [r11, #-0x70]
   2ade8: e51b3068     	ldr	r3, [r11, #-0x68]
   2adec: e282200a     	add	r2, r2, #10
   2adf0: e7d33102     	ldrb	r3, [r3, r2, lsl #2]
   2adf4: e3530003     	cmp	r3, #3
   2adf8: 9a00000a     	bls	0x2ae28 <scarletbook_read_master_toc+0xc2c> @ imm = #0x28
   2adfc: e59f3290     	ldr	r3, [pc, #0x290]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2ae00: e5933000     	ldr	r3, [r3]
   2ae04: e1a02003     	mov	r2, r3
   2ae08: e59f3250     	ldr	r3, [pc, #0x250]        @ 0x2b060 <scarletbook_read_master_toc+0xe64>
   2ae0c: e59f1250     	ldr	r1, [pc, #0x250]        @ 0x2b064 <scarletbook_read_master_toc+0xe68>
   2ae10: e58d1000     	str	r1, [sp]
   2ae14: e1a00002     	mov	r0, r2
   2ae18: e1a01003     	mov	r1, r3
   2ae1c: e59f2208     	ldr	r2, [pc, #0x208]        @ 0x2b02c <scarletbook_read_master_toc+0xe30>
   2ae20: e59f3240     	ldr	r3, [pc, #0x240]        @ 0x2b068 <scarletbook_read_master_toc+0xe6c>
   2ae24: ebff8606     	bl	0xc644 <fprintf@plt>    @ imm = #-0x1e7e8
   2ae28: e51b2070     	ldr	r2, [r11, #-0x70]
   2ae2c: e51b3068     	ldr	r3, [r11, #-0x68]
   2ae30: e282201a     	add	r2, r2, #26
   2ae34: e7d33102     	ldrb	r3, [r3, r2, lsl #2]
   2ae38: e3530003     	cmp	r3, #3
   2ae3c: 9a00000a     	bls	0x2ae6c <scarletbook_read_master_toc+0xc70> @ imm = #0x28
   2ae40: e59f324c     	ldr	r3, [pc, #0x24c]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2ae44: e5933000     	ldr	r3, [r3]
   2ae48: e1a02003     	mov	r2, r3
   2ae4c: e59f320c     	ldr	r3, [pc, #0x20c]        @ 0x2b060 <scarletbook_read_master_toc+0xe64>
   2ae50: e59f1214     	ldr	r1, [pc, #0x214]        @ 0x2b06c <scarletbook_read_master_toc+0xe70>
   2ae54: e58d1000     	str	r1, [sp]
   2ae58: e1a00002     	mov	r0, r2
   2ae5c: e1a01003     	mov	r1, r3
   2ae60: e59f21c4     	ldr	r2, [pc, #0x1c4]        @ 0x2b02c <scarletbook_read_master_toc+0xe30>
   2ae64: e59f3204     	ldr	r3, [pc, #0x204]        @ 0x2b070 <scarletbook_read_master_toc+0xe74>
   2ae68: ebff85f5     	bl	0xc644 <fprintf@plt>    @ imm = #-0x1e82c
   2ae6c: e51b3070     	ldr	r3, [r11, #-0x70]
   2ae70: e51b1068     	ldr	r1, [r11, #-0x68]
   2ae74: e283200a     	add	r2, r3, #10
   2ae78: e3a03003     	mov	r3, #3
   2ae7c: e1a02102     	lsl	r2, r2, #2
   2ae80: e0812002     	add	r2, r1, r2
   2ae84: e0823003     	add	r3, r2, r3
   2ae88: e5d33000     	ldrb	r3, [r3]
   2ae8c: e353001d     	cmp	r3, #29
   2ae90: 9a00000a     	bls	0x2aec0 <scarletbook_read_master_toc+0xcc4> @ imm = #0x28
   2ae94: e59f31f8     	ldr	r3, [pc, #0x1f8]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2ae98: e5933000     	ldr	r3, [r3]
   2ae9c: e1a02003     	mov	r2, r3
   2aea0: e59f31b8     	ldr	r3, [pc, #0x1b8]        @ 0x2b060 <scarletbook_read_master_toc+0xe64>
   2aea4: e59f11c8     	ldr	r1, [pc, #0x1c8]        @ 0x2b074 <scarletbook_read_master_toc+0xe78>
   2aea8: e58d1000     	str	r1, [sp]
   2aeac: e1a00002     	mov	r0, r2
   2aeb0: e1a01003     	mov	r1, r3
   2aeb4: e59f2170     	ldr	r2, [pc, #0x170]        @ 0x2b02c <scarletbook_read_master_toc+0xe30>
   2aeb8: e3a03f43     	mov	r3, #268
   2aebc: ebff85e0     	bl	0xc644 <fprintf@plt>    @ imm = #-0x1e880
   2aec0: e51b3070     	ldr	r3, [r11, #-0x70]
   2aec4: e51b1068     	ldr	r1, [r11, #-0x68]
   2aec8: e283201a     	add	r2, r3, #26
   2aecc: e3a03003     	mov	r3, #3
   2aed0: e1a02102     	lsl	r2, r2, #2
   2aed4: e0812002     	add	r2, r1, r2
   2aed8: e0823003     	add	r3, r2, r3
   2aedc: e5d33000     	ldrb	r3, [r3]
   2aee0: e353001d     	cmp	r3, #29
   2aee4: 9a00000a     	bls	0x2af14 <scarletbook_read_master_toc+0xd18> @ imm = #0x28
   2aee8: e59f31a4     	ldr	r3, [pc, #0x1a4]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2aeec: e5933000     	ldr	r3, [r3]
   2aef0: e1a02003     	mov	r2, r3
   2aef4: e59f3164     	ldr	r3, [pc, #0x164]        @ 0x2b060 <scarletbook_read_master_toc+0xe64>
   2aef8: e59f1178     	ldr	r1, [pc, #0x178]        @ 0x2b078 <scarletbook_read_master_toc+0xe7c>
   2aefc: e58d1000     	str	r1, [sp]
   2af00: e1a00002     	mov	r0, r2
   2af04: e1a01003     	mov	r1, r3
   2af08: e59f211c     	ldr	r2, [pc, #0x11c]        @ 0x2b02c <scarletbook_read_master_toc+0xe30>
   2af0c: e59f3168     	ldr	r3, [pc, #0x168]        @ 0x2b07c <scarletbook_read_master_toc+0xe80>
   2af10: ebff85cb     	bl	0xc644 <fprintf@plt>    @ imm = #-0x1e8d4
   2af14: e51b3070     	ldr	r3, [r11, #-0x70]
   2af18: e2833001     	add	r3, r3, #1
   2af1c: e50b3070     	str	r3, [r11, #-0x70]
   2af20: e51b3070     	ldr	r3, [r11, #-0x70]
   2af24: e3530003     	cmp	r3, #3
   2af28: daffff3d     	ble	0x2ac24 <scarletbook_read_master_toc+0xa28> @ imm = #-0x30c
   2af2c: e51b3068     	ldr	r3, [r11, #-0x68]
   2af30: e5d33080     	ldrb	r3, [r3, #0x80]
   2af34: e3530008     	cmp	r3, #8
   2af38: 9a00000a     	bls	0x2af68 <scarletbook_read_master_toc+0xd6c> @ imm = #0x28
   2af3c: e59f3150     	ldr	r3, [pc, #0x150]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2af40: e5933000     	ldr	r3, [r3]
   2af44: e1a02003     	mov	r2, r3
   2af48: e59f3110     	ldr	r3, [pc, #0x110]        @ 0x2b060 <scarletbook_read_master_toc+0xe64>
   2af4c: e59f112c     	ldr	r1, [pc, #0x12c]        @ 0x2b080 <scarletbook_read_master_toc+0xe84>
   2af50: e58d1000     	str	r1, [sp]
   2af54: e1a00002     	mov	r0, r2
   2af58: e1a01003     	mov	r1, r3
   2af5c: e59f20c8     	ldr	r2, [pc, #0xc8]         @ 0x2b02c <scarletbook_read_master_toc+0xe30>
   2af60: e3a03e11     	mov	r3, #272
   2af64: ebff85b6     	bl	0xc644 <fprintf@plt>    @ imm = #-0x1e928
   2af68: e51b3078     	ldr	r3, [r11, #-0x78]
   2af6c: e5933004     	ldr	r3, [r3, #0x4]
   2af70: e2833b02     	add	r3, r3, #2048
   2af74: e50b306c     	str	r3, [r11, #-0x6c]
   2af78: e3a03000     	mov	r3, #0
   2af7c: e50b3070     	str	r3, [r11, #-0x70]
   2af80: ea000444     	b	0x2c098 <scarletbook_read_master_toc+0x1e9c> @ imm = #0x1110
   2af84: e51b306c     	ldr	r3, [r11, #-0x6c]
   2af88: e50b3038     	str	r3, [r11, #-0x38]
   2af8c: e51b3038     	ldr	r3, [r11, #-0x38]
   2af90: e59f00ec     	ldr	r0, [pc, #0xec]         @ 0x2b084 <scarletbook_read_master_toc+0xe88>
   2af94: e1a01003     	mov	r1, r3
   2af98: e3a02008     	mov	r2, #8
   2af9c: ebff85f3     	bl	0xc770 <strncmp@plt>    @ imm = #-0x1e834
   2afa0: e1a03000     	mov	r3, r0
   2afa4: e3530000     	cmp	r3, #0
   2afa8: 0a000001     	beq	0x2afb4 <scarletbook_read_master_toc+0xdb8> @ imm = #0x4
   2afac: e3a03000     	mov	r3, #0
   2afb0: ea00044a     	b	0x2c0e0 <scarletbook_read_master_toc+0x1ee4> @ imm = #0x1128
   2afb4: e51b3038     	ldr	r3, [r11, #-0x38]
   2afb8: e2833008     	add	r3, r3, #8
   2afbc: e59f005c     	ldr	r0, [pc, #0x5c]         @ 0x2b020 <scarletbook_read_master_toc+0xe24>
   2afc0: e1a01003     	mov	r1, r3
   2afc4: e3a02008     	mov	r2, #8
   2afc8: ebff84aa     	bl	0xc278 <memcmp@plt>     @ imm = #-0x1ed58
   2afcc: e1a03000     	mov	r3, r0
   2afd0: e3530000     	cmp	r3, #0
   2afd4: 0a000049     	beq	0x2b100 <scarletbook_read_master_toc+0xf04> @ imm = #0x124
   2afd8: e59f30b4     	ldr	r3, [pc, #0xb4]         @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2afdc: e5933000     	ldr	r3, [r3]
   2afe0: e1a02003     	mov	r2, r3
   2afe4: e59f3038     	ldr	r3, [pc, #0x38]         @ 0x2b024 <scarletbook_read_master_toc+0xe28>
   2afe8: e59f1098     	ldr	r1, [pc, #0x98]         @ 0x2b088 <scarletbook_read_master_toc+0xe8c>
   2afec: e58d1000     	str	r1, [sp]
   2aff0: e1a00002     	mov	r0, r2
   2aff4: e1a01003     	mov	r1, r3
   2aff8: e59f202c     	ldr	r2, [pc, #0x2c]         @ 0x2b02c <scarletbook_read_master_toc+0xe30>
   2affc: e59f3088     	ldr	r3, [pc, #0x88]         @ 0x2b08c <scarletbook_read_master_toc+0xe90>
   2b000: ebff858f     	bl	0xc644 <fprintf@plt>    @ imm = #-0x1e9c4
   2b004: e3a03000     	mov	r3, #0
   2b008: e50b3034     	str	r3, [r11, #-0x34]
   2b00c: ea000033     	b	0x2b0e0 <scarletbook_read_master_toc+0xee4> @ imm = #0xcc
   2b010: fe 01 00 00  	.word	0x000001fe
   2b014: 70 59 03 00  	.word	0x00035970
   2b018: 7c 59 03 00  	.word	0x0003597c
   2b01c: a4 59 03 00  	.word	0x000359a4
   2b020: c0 95 05 00  	.word	0x000595c0
   2b024: d0 59 03 00  	.word	0x000359d0
   2b028: 34 5a 03 00  	.word	0x00035a34
   2b02c: 00 5a 03 00  	.word	0x00035a00
   2b030: 54 5a 03 00  	.word	0x00035a54
   2b034: 01 01 00 00  	.word	0x00000101
   2b038: 6c 5a 03 00  	.word	0x00035a6c
   2b03c: 02 01 00 00  	.word	0x00000102
   2b040: 84 5a 03 00  	.word	0x00035a84
   2b044: 03 01 00 00  	.word	0x00000103
   2b048: 9c 5a 03 00  	.word	0x00035a9c
   2b04c: b4 5a 03 00  	.word	0x00035ab4
   2b050: 05 01 00 00  	.word	0x00000105
   2b054: cc 5a 03 00  	.word	0x00035acc
   2b058: f0 5a 03 00  	.word	0x00035af0
   2b05c: 09 01 00 00  	.word	0x00000109
   2b060: 14 5b 03 00  	.word	0x00035b14
   2b064: 58 5b 03 00  	.word	0x00035b58
   2b068: 0a 01 00 00  	.word	0x0000010a
   2b06c: 94 5b 03 00  	.word	0x00035b94
   2b070: 0b 01 00 00  	.word	0x0000010b
   2b074: d0 5b 03 00  	.word	0x00035bd0
   2b078: 04 5c 03 00  	.word	0x00035c04
   2b07c: 0d 01 00 00  	.word	0x0000010d
   2b080: 38 5c 03 00  	.word	0x00035c38
   2b084: 6c 5c 03 00  	.word	0x00035c6c
   2b088: 78 5c 03 00  	.word	0x00035c78
   2b08c: 1f 01 00 00  	.word	0x0000011f
   2b090: 4c 5a 03 00  	.word	0x00035a4c
   2b094: f8 6d 05 00  	.word	0x00056df8
   2b098: 38 ef 03 00  	.word	0x0003ef38
   2b09c: 90 5c 03 00  	.word	0x00035c90
   2b0a0: e51f3014     	ldr	r3, [pc, #-0x14]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2b0a4: e5933000     	ldr	r3, [r3]
   2b0a8: e1a01003     	mov	r1, r3
   2b0ac: e51f2024     	ldr	r2, [pc, #-0x24]        @ 0x2b090 <scarletbook_read_master_toc+0xe94>
   2b0b0: e51b3038     	ldr	r3, [r11, #-0x38]
   2b0b4: e2830008     	add	r0, r3, #8
   2b0b8: e51b3034     	ldr	r3, [r11, #-0x34]
   2b0bc: e0803003     	add	r3, r0, r3
   2b0c0: e5d33000     	ldrb	r3, [r3]
   2b0c4: e1a00001     	mov	r0, r1
   2b0c8: e1a01002     	mov	r1, r2
   2b0cc: e1a02003     	mov	r2, r3
   2b0d0: ebff855b     	bl	0xc644 <fprintf@plt>    @ imm = #-0x1ea94
   2b0d4: e51b3034     	ldr	r3, [r11, #-0x34]
   2b0d8: e2833001     	add	r3, r3, #1
   2b0dc: e50b3034     	str	r3, [r11, #-0x34]
   2b0e0: e51b3034     	ldr	r3, [r11, #-0x34]
   2b0e4: e3530007     	cmp	r3, #7
   2b0e8: 9affffec     	bls	0x2b0a0 <scarletbook_read_master_toc+0xea4> @ imm = #-0x50
   2b0ec: e51f3060     	ldr	r3, [pc, #-0x60]        @ 0x2b094 <scarletbook_read_master_toc+0xe98>
   2b0f0: e5933000     	ldr	r3, [r3]
   2b0f4: e3a0000a     	mov	r0, #10
   2b0f8: e1a01003     	mov	r1, r3
   2b0fc: ebff856b     	bl	0xc6b0 <fputc@plt>      @ imm = #-0x1ea54
   2b100: e51b3038     	ldr	r3, [r11, #-0x38]
   2b104: e5d32010     	ldrb	r2, [r3, #0x10]
   2b108: e5d33011     	ldrb	r3, [r3, #0x11]
   2b10c: e1a03403     	lsl	r3, r3, #8
   2b110: e1833002     	orr	r3, r3, r2
   2b114: e14b33b0     	strh	r3, [r11, #-48]
   2b118: e15b33b0     	ldrh	r3, [r11, #-48]
   2b11c: e1a03423     	lsr	r3, r3, #8
   2b120: e6ff3073     	uxth	r3, r3
   2b124: e1a02003     	mov	r2, r3
   2b128: e15b33b0     	ldrh	r3, [r11, #-48]
   2b12c: e1a03403     	lsl	r3, r3, #8
   2b130: e1a03803     	lsl	r3, r3, #16
   2b134: e1a03823     	lsr	r3, r3, #16
   2b138: e1823003     	orr	r3, r2, r3
   2b13c: e6ff2073     	uxth	r2, r3
   2b140: e51b3038     	ldr	r3, [r11, #-0x38]
   2b144: e20210ff     	and	r1, r2, #255
   2b148: e3a00000     	mov	r0, #0
   2b14c: e1801001     	orr	r1, r0, r1
   2b150: e5c31010     	strb	r1, [r3, #0x10]
   2b154: e1a02422     	lsr	r2, r2, #8
   2b158: e6ff2072     	uxth	r2, r2
   2b15c: e3a01000     	mov	r1, #0
   2b160: e1812002     	orr	r2, r1, r2
   2b164: e5c32011     	strb	r2, [r3, #0x11]
   2b168: e51b3038     	ldr	r3, [r11, #-0x38]
   2b16c: e5d32018     	ldrb	r2, [r3, #0x18]
   2b170: e5d33019     	ldrb	r3, [r3, #0x19]
   2b174: e1a03403     	lsl	r3, r3, #8
   2b178: e1833002     	orr	r3, r3, r2
   2b17c: e14b32be     	strh	r3, [r11, #-46]
   2b180: e15b32be     	ldrh	r3, [r11, #-46]
   2b184: e1a03423     	lsr	r3, r3, #8
   2b188: e6ff3073     	uxth	r3, r3
   2b18c: e1a02003     	mov	r2, r3
   2b190: e15b32be     	ldrh	r3, [r11, #-46]
   2b194: e1a03403     	lsl	r3, r3, #8
   2b198: e1a03803     	lsl	r3, r3, #16
   2b19c: e1a03823     	lsr	r3, r3, #16
   2b1a0: e1823003     	orr	r3, r2, r3
   2b1a4: e6ff2073     	uxth	r2, r3
   2b1a8: e51b3038     	ldr	r3, [r11, #-0x38]
   2b1ac: e20210ff     	and	r1, r2, #255
   2b1b0: e3a00000     	mov	r0, #0
   2b1b4: e1801001     	orr	r1, r0, r1
   2b1b8: e5c31018     	strb	r1, [r3, #0x18]
   2b1bc: e1a02422     	lsr	r2, r2, #8
   2b1c0: e6ff2072     	uxth	r2, r2
   2b1c4: e3a01000     	mov	r1, #0
   2b1c8: e1812002     	orr	r2, r1, r2
   2b1cc: e5c32019     	strb	r2, [r3, #0x19]
   2b1d0: e51b3038     	ldr	r3, [r11, #-0x38]
   2b1d4: e5d32012     	ldrb	r2, [r3, #0x12]
   2b1d8: e5d33013     	ldrb	r3, [r3, #0x13]
   2b1dc: e1a03403     	lsl	r3, r3, #8
   2b1e0: e1833002     	orr	r3, r3, r2
   2b1e4: e14b32bc     	strh	r3, [r11, #-44]
   2b1e8: e15b32bc     	ldrh	r3, [r11, #-44]
   2b1ec: e1a03423     	lsr	r3, r3, #8
   2b1f0: e6ff3073     	uxth	r3, r3
   2b1f4: e1a02003     	mov	r2, r3
   2b1f8: e15b32bc     	ldrh	r3, [r11, #-44]
   2b1fc: e1a03403     	lsl	r3, r3, #8
   2b200: e1a03803     	lsl	r3, r3, #16
   2b204: e1a03823     	lsr	r3, r3, #16
   2b208: e1823003     	orr	r3, r2, r3
   2b20c: e6ff2073     	uxth	r2, r3
   2b210: e51b3038     	ldr	r3, [r11, #-0x38]
   2b214: e20210ff     	and	r1, r2, #255
   2b218: e3a00000     	mov	r0, #0
   2b21c: e1801001     	orr	r1, r0, r1
   2b220: e5c31012     	strb	r1, [r3, #0x12]
   2b224: e1a02422     	lsr	r2, r2, #8
   2b228: e6ff2072     	uxth	r2, r2
   2b22c: e3a01000     	mov	r1, #0
   2b230: e1812002     	orr	r2, r1, r2
   2b234: e5c32013     	strb	r2, [r3, #0x13]
   2b238: e51b3038     	ldr	r3, [r11, #-0x38]
   2b23c: e5d3201a     	ldrb	r2, [r3, #0x1a]
   2b240: e5d3301b     	ldrb	r3, [r3, #0x1b]
   2b244: e1a03403     	lsl	r3, r3, #8
   2b248: e1833002     	orr	r3, r3, r2
   2b24c: e14b32ba     	strh	r3, [r11, #-42]
   2b250: e15b32ba     	ldrh	r3, [r11, #-42]
   2b254: e1a03423     	lsr	r3, r3, #8
   2b258: e6ff3073     	uxth	r3, r3
   2b25c: e1a02003     	mov	r2, r3
   2b260: e15b32ba     	ldrh	r3, [r11, #-42]
   2b264: e1a03403     	lsl	r3, r3, #8
   2b268: e1a03803     	lsl	r3, r3, #16
   2b26c: e1a03823     	lsr	r3, r3, #16
   2b270: e1823003     	orr	r3, r2, r3
   2b274: e6ff2073     	uxth	r2, r3
   2b278: e51b3038     	ldr	r3, [r11, #-0x38]
   2b27c: e20210ff     	and	r1, r2, #255
   2b280: e3a00000     	mov	r0, #0
   2b284: e1801001     	orr	r1, r0, r1
   2b288: e5c3101a     	strb	r1, [r3, #0x1a]
   2b28c: e1a02422     	lsr	r2, r2, #8
   2b290: e6ff2072     	uxth	r2, r2
   2b294: e3a01000     	mov	r1, #0
   2b298: e1812002     	orr	r2, r1, r2
   2b29c: e5c3201b     	strb	r2, [r3, #0x1b]
   2b2a0: e51b3038     	ldr	r3, [r11, #-0x38]
   2b2a4: e5d32014     	ldrb	r2, [r3, #0x14]
   2b2a8: e5d33015     	ldrb	r3, [r3, #0x15]
   2b2ac: e1a03403     	lsl	r3, r3, #8
   2b2b0: e1833002     	orr	r3, r3, r2
   2b2b4: e14b32b8     	strh	r3, [r11, #-40]
   2b2b8: e15b32b8     	ldrh	r3, [r11, #-40]
   2b2bc: e1a03423     	lsr	r3, r3, #8
   2b2c0: e6ff3073     	uxth	r3, r3
   2b2c4: e1a02003     	mov	r2, r3
   2b2c8: e15b32b8     	ldrh	r3, [r11, #-40]
   2b2cc: e1a03403     	lsl	r3, r3, #8
   2b2d0: e1a03803     	lsl	r3, r3, #16
   2b2d4: e1a03823     	lsr	r3, r3, #16
   2b2d8: e1823003     	orr	r3, r2, r3
   2b2dc: e6ff2073     	uxth	r2, r3
   2b2e0: e51b3038     	ldr	r3, [r11, #-0x38]
   2b2e4: e20210ff     	and	r1, r2, #255
   2b2e8: e3a00000     	mov	r0, #0
   2b2ec: e1801001     	orr	r1, r0, r1
   2b2f0: e5c31014     	strb	r1, [r3, #0x14]
   2b2f4: e1a02422     	lsr	r2, r2, #8
   2b2f8: e6ff2072     	uxth	r2, r2
   2b2fc: e3a01000     	mov	r1, #0
   2b300: e1812002     	orr	r2, r1, r2
   2b304: e5c32015     	strb	r2, [r3, #0x15]
   2b308: e51b3038     	ldr	r3, [r11, #-0x38]
   2b30c: e5d3201c     	ldrb	r2, [r3, #0x1c]
   2b310: e5d3301d     	ldrb	r3, [r3, #0x1d]
   2b314: e1a03403     	lsl	r3, r3, #8
   2b318: e1833002     	orr	r3, r3, r2
   2b31c: e14b32b6     	strh	r3, [r11, #-38]
   2b320: e15b32b6     	ldrh	r3, [r11, #-38]
   2b324: e1a03423     	lsr	r3, r3, #8
   2b328: e6ff3073     	uxth	r3, r3
   2b32c: e1a02003     	mov	r2, r3
   2b330: e15b32b6     	ldrh	r3, [r11, #-38]
   2b334: e1a03403     	lsl	r3, r3, #8
   2b338: e1a03803     	lsl	r3, r3, #16
   2b33c: e1a03823     	lsr	r3, r3, #16
   2b340: e1823003     	orr	r3, r2, r3
   2b344: e6ff2073     	uxth	r2, r3
   2b348: e51b3038     	ldr	r3, [r11, #-0x38]
   2b34c: e20210ff     	and	r1, r2, #255
   2b350: e3a00000     	mov	r0, #0
   2b354: e1801001     	orr	r1, r0, r1
   2b358: e5c3101c     	strb	r1, [r3, #0x1c]
   2b35c: e1a02422     	lsr	r2, r2, #8
   2b360: e6ff2072     	uxth	r2, r2
   2b364: e3a01000     	mov	r1, #0
   2b368: e1812002     	orr	r2, r1, r2
   2b36c: e5c3201d     	strb	r2, [r3, #0x1d]
   2b370: e51b3038     	ldr	r3, [r11, #-0x38]
   2b374: e5d32016     	ldrb	r2, [r3, #0x16]
   2b378: e5d33017     	ldrb	r3, [r3, #0x17]
   2b37c: e1a03403     	lsl	r3, r3, #8
   2b380: e1833002     	orr	r3, r3, r2
   2b384: e14b32b4     	strh	r3, [r11, #-36]
   2b388: e15b32b4     	ldrh	r3, [r11, #-36]
   2b38c: e1a03423     	lsr	r3, r3, #8
   2b390: e6ff3073     	uxth	r3, r3
   2b394: e1a02003     	mov	r2, r3
   2b398: e15b32b4     	ldrh	r3, [r11, #-36]
   2b39c: e1a03403     	lsl	r3, r3, #8
   2b3a0: e1a03803     	lsl	r3, r3, #16
   2b3a4: e1a03823     	lsr	r3, r3, #16
   2b3a8: e1823003     	orr	r3, r2, r3
   2b3ac: e6ff2073     	uxth	r2, r3
   2b3b0: e51b3038     	ldr	r3, [r11, #-0x38]
   2b3b4: e20210ff     	and	r1, r2, #255
   2b3b8: e3a00000     	mov	r0, #0
   2b3bc: e1801001     	orr	r1, r0, r1
   2b3c0: e5c31016     	strb	r1, [r3, #0x16]
   2b3c4: e1a02422     	lsr	r2, r2, #8
   2b3c8: e6ff2072     	uxth	r2, r2
   2b3cc: e3a01000     	mov	r1, #0
   2b3d0: e1812002     	orr	r2, r1, r2
   2b3d4: e5c32017     	strb	r2, [r3, #0x17]
   2b3d8: e51b3038     	ldr	r3, [r11, #-0x38]
   2b3dc: e5d3201e     	ldrb	r2, [r3, #0x1e]
   2b3e0: e5d3301f     	ldrb	r3, [r3, #0x1f]
   2b3e4: e1a03403     	lsl	r3, r3, #8
   2b3e8: e1833002     	orr	r3, r3, r2
   2b3ec: e14b32b2     	strh	r3, [r11, #-34]
   2b3f0: e15b32b2     	ldrh	r3, [r11, #-34]
   2b3f4: e1a03423     	lsr	r3, r3, #8
   2b3f8: e6ff3073     	uxth	r3, r3
   2b3fc: e1a02003     	mov	r2, r3
   2b400: e15b32b2     	ldrh	r3, [r11, #-34]
   2b404: e1a03403     	lsl	r3, r3, #8
   2b408: e1a03803     	lsl	r3, r3, #16
   2b40c: e1a03823     	lsr	r3, r3, #16
   2b410: e1823003     	orr	r3, r2, r3
   2b414: e6ff2073     	uxth	r2, r3
   2b418: e51b3038     	ldr	r3, [r11, #-0x38]
   2b41c: e20210ff     	and	r1, r2, #255
   2b420: e3a00000     	mov	r0, #0
   2b424: e1801001     	orr	r1, r0, r1
   2b428: e5c3101e     	strb	r1, [r3, #0x1e]
   2b42c: e1a02422     	lsr	r2, r2, #8
   2b430: e6ff2072     	uxth	r2, r2
   2b434: e3a01000     	mov	r1, #0
   2b438: e1812002     	orr	r2, r1, r2
   2b43c: e5c3201f     	strb	r2, [r3, #0x1f]
   2b440: e51b3038     	ldr	r3, [r11, #-0x38]
   2b444: e5d32020     	ldrb	r2, [r3, #0x20]
   2b448: e5d33021     	ldrb	r3, [r3, #0x21]
   2b44c: e1a03403     	lsl	r3, r3, #8
   2b450: e1833002     	orr	r3, r3, r2
   2b454: e14b32b0     	strh	r3, [r11, #-32]
   2b458: e15b32b0     	ldrh	r3, [r11, #-32]
   2b45c: e1a03423     	lsr	r3, r3, #8
   2b460: e6ff3073     	uxth	r3, r3
   2b464: e1a02003     	mov	r2, r3
   2b468: e15b32b0     	ldrh	r3, [r11, #-32]
   2b46c: e1a03403     	lsl	r3, r3, #8
   2b470: e1a03803     	lsl	r3, r3, #16
   2b474: e1a03823     	lsr	r3, r3, #16
   2b478: e1823003     	orr	r3, r2, r3
   2b47c: e6ff2073     	uxth	r2, r3
   2b480: e51b3038     	ldr	r3, [r11, #-0x38]
   2b484: e20210ff     	and	r1, r2, #255
   2b488: e3a00000     	mov	r0, #0
   2b48c: e1801001     	orr	r1, r0, r1
   2b490: e5c31020     	strb	r1, [r3, #0x20]
   2b494: e1a02422     	lsr	r2, r2, #8
   2b498: e6ff2072     	uxth	r2, r2
   2b49c: e3a01000     	mov	r1, #0
   2b4a0: e1812002     	orr	r2, r1, r2
   2b4a4: e5c32021     	strb	r2, [r3, #0x21]
   2b4a8: e51b3038     	ldr	r3, [r11, #-0x38]
   2b4ac: e5d32028     	ldrb	r2, [r3, #0x28]
   2b4b0: e5d33029     	ldrb	r3, [r3, #0x29]
   2b4b4: e1a03403     	lsl	r3, r3, #8
   2b4b8: e1833002     	orr	r3, r3, r2
   2b4bc: e14b31be     	strh	r3, [r11, #-30]
   2b4c0: e15b31be     	ldrh	r3, [r11, #-30]
   2b4c4: e1a03423     	lsr	r3, r3, #8
   2b4c8: e6ff3073     	uxth	r3, r3
   2b4cc: e1a02003     	mov	r2, r3
   2b4d0: e15b31be     	ldrh	r3, [r11, #-30]
   2b4d4: e1a03403     	lsl	r3, r3, #8
   2b4d8: e1a03803     	lsl	r3, r3, #16
   2b4dc: e1a03823     	lsr	r3, r3, #16
   2b4e0: e1823003     	orr	r3, r2, r3
   2b4e4: e6ff2073     	uxth	r2, r3
   2b4e8: e51b3038     	ldr	r3, [r11, #-0x38]
   2b4ec: e20210ff     	and	r1, r2, #255
   2b4f0: e3a00000     	mov	r0, #0
   2b4f4: e1801001     	orr	r1, r0, r1
   2b4f8: e5c31028     	strb	r1, [r3, #0x28]
   2b4fc: e1a02422     	lsr	r2, r2, #8
   2b500: e6ff2072     	uxth	r2, r2
   2b504: e3a01000     	mov	r1, #0
   2b508: e1812002     	orr	r2, r1, r2
   2b50c: e5c32029     	strb	r2, [r3, #0x29]
   2b510: e51b3038     	ldr	r3, [r11, #-0x38]
   2b514: e5d32022     	ldrb	r2, [r3, #0x22]
   2b518: e5d33023     	ldrb	r3, [r3, #0x23]
   2b51c: e1a03403     	lsl	r3, r3, #8
   2b520: e1833002     	orr	r3, r3, r2
   2b524: e14b31bc     	strh	r3, [r11, #-28]
   2b528: e15b31bc     	ldrh	r3, [r11, #-28]
   2b52c: e1a03423     	lsr	r3, r3, #8
   2b530: e6ff3073     	uxth	r3, r3
   2b534: e1a02003     	mov	r2, r3
   2b538: e15b31bc     	ldrh	r3, [r11, #-28]
   2b53c: e1a03403     	lsl	r3, r3, #8
   2b540: e1a03803     	lsl	r3, r3, #16
   2b544: e1a03823     	lsr	r3, r3, #16
   2b548: e1823003     	orr	r3, r2, r3
   2b54c: e6ff2073     	uxth	r2, r3
   2b550: e51b3038     	ldr	r3, [r11, #-0x38]
   2b554: e20210ff     	and	r1, r2, #255
   2b558: e3a00000     	mov	r0, #0
   2b55c: e1801001     	orr	r1, r0, r1
   2b560: e5c31022     	strb	r1, [r3, #0x22]
   2b564: e1a02422     	lsr	r2, r2, #8
   2b568: e6ff2072     	uxth	r2, r2
   2b56c: e3a01000     	mov	r1, #0
   2b570: e1812002     	orr	r2, r1, r2
   2b574: e5c32023     	strb	r2, [r3, #0x23]
   2b578: e51b3038     	ldr	r3, [r11, #-0x38]
   2b57c: e5d3202a     	ldrb	r2, [r3, #0x2a]
   2b580: e5d3302b     	ldrb	r3, [r3, #0x2b]
   2b584: e1a03403     	lsl	r3, r3, #8
   2b588: e1833002     	orr	r3, r3, r2
   2b58c: e14b31ba     	strh	r3, [r11, #-26]
   2b590: e15b31ba     	ldrh	r3, [r11, #-26]
   2b594: e1a03423     	lsr	r3, r3, #8
   2b598: e6ff3073     	uxth	r3, r3
   2b59c: e1a02003     	mov	r2, r3
   2b5a0: e15b31ba     	ldrh	r3, [r11, #-26]
   2b5a4: e1a03403     	lsl	r3, r3, #8
   2b5a8: e1a03803     	lsl	r3, r3, #16
   2b5ac: e1a03823     	lsr	r3, r3, #16
   2b5b0: e1823003     	orr	r3, r2, r3
   2b5b4: e6ff2073     	uxth	r2, r3
   2b5b8: e51b3038     	ldr	r3, [r11, #-0x38]
   2b5bc: e20210ff     	and	r1, r2, #255
   2b5c0: e3a00000     	mov	r0, #0
   2b5c4: e1801001     	orr	r1, r0, r1
   2b5c8: e5c3102a     	strb	r1, [r3, #0x2a]
   2b5cc: e1a02422     	lsr	r2, r2, #8
   2b5d0: e6ff2072     	uxth	r2, r2
   2b5d4: e3a01000     	mov	r1, #0
   2b5d8: e1812002     	orr	r2, r1, r2
   2b5dc: e5c3202b     	strb	r2, [r3, #0x2b]
   2b5e0: e51b3038     	ldr	r3, [r11, #-0x38]
   2b5e4: e5d32024     	ldrb	r2, [r3, #0x24]
   2b5e8: e5d33025     	ldrb	r3, [r3, #0x25]
   2b5ec: e1a03403     	lsl	r3, r3, #8
   2b5f0: e1833002     	orr	r3, r3, r2
   2b5f4: e14b31b8     	strh	r3, [r11, #-24]
   2b5f8: e15b31b8     	ldrh	r3, [r11, #-24]
   2b5fc: e1a03423     	lsr	r3, r3, #8
   2b600: e6ff3073     	uxth	r3, r3
   2b604: e1a02003     	mov	r2, r3
   2b608: e15b31b8     	ldrh	r3, [r11, #-24]
   2b60c: e1a03403     	lsl	r3, r3, #8
   2b610: e1a03803     	lsl	r3, r3, #16
   2b614: e1a03823     	lsr	r3, r3, #16
   2b618: e1823003     	orr	r3, r2, r3
   2b61c: e6ff2073     	uxth	r2, r3
   2b620: e51b3038     	ldr	r3, [r11, #-0x38]
   2b624: e20210ff     	and	r1, r2, #255
   2b628: e3a00000     	mov	r0, #0
   2b62c: e1801001     	orr	r1, r0, r1
   2b630: e5c31024     	strb	r1, [r3, #0x24]
   2b634: e1a02422     	lsr	r2, r2, #8
   2b638: e6ff2072     	uxth	r2, r2
   2b63c: e3a01000     	mov	r1, #0
   2b640: e1812002     	orr	r2, r1, r2
   2b644: e5c32025     	strb	r2, [r3, #0x25]
   2b648: e51b3038     	ldr	r3, [r11, #-0x38]
   2b64c: e5d3202c     	ldrb	r2, [r3, #0x2c]
   2b650: e5d3302d     	ldrb	r3, [r3, #0x2d]
   2b654: e1a03403     	lsl	r3, r3, #8
   2b658: e1833002     	orr	r3, r3, r2
   2b65c: e14b31b6     	strh	r3, [r11, #-22]
   2b660: e15b31b6     	ldrh	r3, [r11, #-22]
   2b664: e1a03423     	lsr	r3, r3, #8
   2b668: e6ff3073     	uxth	r3, r3
   2b66c: e1a02003     	mov	r2, r3
   2b670: e15b31b6     	ldrh	r3, [r11, #-22]
   2b674: e1a03403     	lsl	r3, r3, #8
   2b678: e1a03803     	lsl	r3, r3, #16
   2b67c: e1a03823     	lsr	r3, r3, #16
   2b680: e1823003     	orr	r3, r2, r3
   2b684: e6ff2073     	uxth	r2, r3
   2b688: e51b3038     	ldr	r3, [r11, #-0x38]
   2b68c: e20210ff     	and	r1, r2, #255
   2b690: e3a00000     	mov	r0, #0
   2b694: e1801001     	orr	r1, r0, r1
   2b698: e5c3102c     	strb	r1, [r3, #0x2c]
   2b69c: e1a02422     	lsr	r2, r2, #8
   2b6a0: e6ff2072     	uxth	r2, r2
   2b6a4: e3a01000     	mov	r1, #0
   2b6a8: e1812002     	orr	r2, r1, r2
   2b6ac: e5c3202d     	strb	r2, [r3, #0x2d]
   2b6b0: e51b3038     	ldr	r3, [r11, #-0x38]
   2b6b4: e5d32026     	ldrb	r2, [r3, #0x26]
   2b6b8: e5d33027     	ldrb	r3, [r3, #0x27]
   2b6bc: e1a03403     	lsl	r3, r3, #8
   2b6c0: e1833002     	orr	r3, r3, r2
   2b6c4: e14b31b4     	strh	r3, [r11, #-20]
   2b6c8: e15b31b4     	ldrh	r3, [r11, #-20]
   2b6cc: e1a03423     	lsr	r3, r3, #8
   2b6d0: e6ff3073     	uxth	r3, r3
   2b6d4: e1a02003     	mov	r2, r3
   2b6d8: e15b31b4     	ldrh	r3, [r11, #-20]
   2b6dc: e1a03403     	lsl	r3, r3, #8
   2b6e0: e1a03803     	lsl	r3, r3, #16
   2b6e4: e1a03823     	lsr	r3, r3, #16
   2b6e8: e1823003     	orr	r3, r2, r3
   2b6ec: e6ff2073     	uxth	r2, r3
   2b6f0: e51b3038     	ldr	r3, [r11, #-0x38]
   2b6f4: e20210ff     	and	r1, r2, #255
   2b6f8: e3a00000     	mov	r0, #0
   2b6fc: e1801001     	orr	r1, r0, r1
   2b700: e5c31026     	strb	r1, [r3, #0x26]
   2b704: e1a02422     	lsr	r2, r2, #8
   2b708: e6ff2072     	uxth	r2, r2
   2b70c: e3a01000     	mov	r1, #0
   2b710: e1812002     	orr	r2, r1, r2
   2b714: e5c32027     	strb	r2, [r3, #0x27]
   2b718: e51b3038     	ldr	r3, [r11, #-0x38]
   2b71c: e5d3202e     	ldrb	r2, [r3, #0x2e]
   2b720: e5d3302f     	ldrb	r3, [r3, #0x2f]
   2b724: e1a03403     	lsl	r3, r3, #8
   2b728: e1833002     	orr	r3, r3, r2
   2b72c: e14b31b2     	strh	r3, [r11, #-18]
   2b730: e15b31b2     	ldrh	r3, [r11, #-18]
   2b734: e1a03423     	lsr	r3, r3, #8
   2b738: e6ff3073     	uxth	r3, r3
   2b73c: e1a02003     	mov	r2, r3
   2b740: e15b31b2     	ldrh	r3, [r11, #-18]
   2b744: e1a03403     	lsl	r3, r3, #8
   2b748: e1a03803     	lsl	r3, r3, #16
   2b74c: e1a03823     	lsr	r3, r3, #16
   2b750: e1823003     	orr	r3, r2, r3
   2b754: e6ff2073     	uxth	r2, r3
   2b758: e51b3038     	ldr	r3, [r11, #-0x38]
   2b75c: e20210ff     	and	r1, r2, #255
   2b760: e3a00000     	mov	r0, #0
   2b764: e1801001     	orr	r1, r0, r1
   2b768: e5c3102e     	strb	r1, [r3, #0x2e]
   2b76c: e1a02422     	lsr	r2, r2, #8
   2b770: e6ff2072     	uxth	r2, r2
   2b774: e3a01000     	mov	r1, #0
   2b778: e1812002     	orr	r2, r1, r2
   2b77c: e5c3202f     	strb	r2, [r3, #0x2f]
   2b780: e51b3070     	ldr	r3, [r11, #-0x70]
   2b784: e3530000     	cmp	r3, #0
   2b788: 1a00023c     	bne	0x2c080 <scarletbook_read_master_toc+0x1e84> @ imm = #0x8f0
   2b78c: e51b3078     	ldr	r3, [r11, #-0x78]
   2b790: e5931008     	ldr	r1, [r3, #0x8]
   2b794: e51b3070     	ldr	r3, [r11, #-0x70]
   2b798: e2832022     	add	r2, r3, #34
   2b79c: e3a03002     	mov	r3, #2
   2b7a0: e1a02102     	lsl	r2, r2, #2
   2b7a4: e0812002     	add	r2, r1, r2
   2b7a8: e0823003     	add	r3, r2, r3
   2b7ac: e5d33000     	ldrb	r3, [r3]
   2b7b0: e2032007     	and	r2, r3, #7
   2b7b4: e51f3724     	ldr	r3, [pc, #-0x724]       @ 0x2b098 <scarletbook_read_master_toc+0xe9c>
   2b7b8: e7933102     	ldr	r3, [r3, r2, lsl #2]
   2b7bc: e50b3010     	str	r3, [r11, #-0x10]
   2b7c0: e51b3038     	ldr	r3, [r11, #-0x38]
   2b7c4: e5d32010     	ldrb	r2, [r3, #0x10]
   2b7c8: e5d33011     	ldrb	r3, [r3, #0x11]
   2b7cc: e1a03403     	lsl	r3, r3, #8
   2b7d0: e1833002     	orr	r3, r3, r2
   2b7d4: e6ff3073     	uxth	r3, r3
   2b7d8: e3530000     	cmp	r3, #0
   2b7dc: 0a00001a     	beq	0x2b84c <scarletbook_read_master_toc+0x1650> @ imm = #0x68
   2b7e0: e51b2038     	ldr	r2, [r11, #-0x38]
   2b7e4: e51b3038     	ldr	r3, [r11, #-0x38]
   2b7e8: e5d31010     	ldrb	r1, [r3, #0x10]
   2b7ec: e5d33011     	ldrb	r3, [r3, #0x11]
   2b7f0: e1a03403     	lsl	r3, r3, #8
   2b7f4: e1833001     	orr	r3, r3, r1
   2b7f8: e6ff3073     	uxth	r3, r3
   2b7fc: e0824003     	add	r4, r2, r3
   2b800: e51b2038     	ldr	r2, [r11, #-0x38]
   2b804: e51b3038     	ldr	r3, [r11, #-0x38]
   2b808: e5d31010     	ldrb	r1, [r3, #0x10]
   2b80c: e5d33011     	ldrb	r3, [r3, #0x11]
   2b810: e1a03403     	lsl	r3, r3, #8
   2b814: e1833001     	orr	r3, r3, r1
   2b818: e6ff3073     	uxth	r3, r3
   2b81c: e0823003     	add	r3, r2, r3
   2b820: e1a00003     	mov	r0, r3
   2b824: ebff832c     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1f350
   2b828: e1a03000     	mov	r3, r0
   2b82c: e1a00004     	mov	r0, r4
   2b830: e1a01003     	mov	r1, r3
   2b834: e51b2010     	ldr	r2, [r11, #-0x10]
   2b838: e51f37a4     	ldr	r3, [pc, #-0x7a4]       @ 0x2b09c <scarletbook_read_master_toc+0xea0>
   2b83c: ebff8b2c     	bl	0xe4f4 <charset_convert> @ imm = #-0x1d350
   2b840: e1a02000     	mov	r2, r0
   2b844: e51b3078     	ldr	r3, [r11, #-0x78]
   2b848: e5832010     	str	r2, [r3, #0x10]
   2b84c: e51b3038     	ldr	r3, [r11, #-0x38]
   2b850: e5d32018     	ldrb	r2, [r3, #0x18]
   2b854: e5d33019     	ldrb	r3, [r3, #0x19]
   2b858: e1a03403     	lsl	r3, r3, #8
   2b85c: e1833002     	orr	r3, r3, r2
   2b860: e6ff3073     	uxth	r3, r3
   2b864: e3530000     	cmp	r3, #0
   2b868: 0a00001a     	beq	0x2b8d8 <scarletbook_read_master_toc+0x16dc> @ imm = #0x68
   2b86c: e51b2038     	ldr	r2, [r11, #-0x38]
   2b870: e51b3038     	ldr	r3, [r11, #-0x38]
   2b874: e5d31018     	ldrb	r1, [r3, #0x18]
   2b878: e5d33019     	ldrb	r3, [r3, #0x19]
   2b87c: e1a03403     	lsl	r3, r3, #8
   2b880: e1833001     	orr	r3, r3, r1
   2b884: e6ff3073     	uxth	r3, r3
   2b888: e0824003     	add	r4, r2, r3
   2b88c: e51b2038     	ldr	r2, [r11, #-0x38]
   2b890: e51b3038     	ldr	r3, [r11, #-0x38]
   2b894: e5d31018     	ldrb	r1, [r3, #0x18]
   2b898: e5d33019     	ldrb	r3, [r3, #0x19]
   2b89c: e1a03403     	lsl	r3, r3, #8
   2b8a0: e1833001     	orr	r3, r3, r1
   2b8a4: e6ff3073     	uxth	r3, r3
   2b8a8: e0823003     	add	r3, r2, r3
   2b8ac: e1a00003     	mov	r0, r3
   2b8b0: ebff8309     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1f3dc
   2b8b4: e1a03000     	mov	r3, r0
   2b8b8: e1a00004     	mov	r0, r4
   2b8bc: e1a01003     	mov	r1, r3
   2b8c0: e51b2010     	ldr	r2, [r11, #-0x10]
   2b8c4: e51f3830     	ldr	r3, [pc, #-0x830]       @ 0x2b09c <scarletbook_read_master_toc+0xea0>
   2b8c8: ebff8b09     	bl	0xe4f4 <charset_convert> @ imm = #-0x1d3dc
   2b8cc: e1a02000     	mov	r2, r0
   2b8d0: e51b3078     	ldr	r3, [r11, #-0x78]
   2b8d4: e5832014     	str	r2, [r3, #0x14]
   2b8d8: e51b3038     	ldr	r3, [r11, #-0x38]
   2b8dc: e5d32012     	ldrb	r2, [r3, #0x12]
   2b8e0: e5d33013     	ldrb	r3, [r3, #0x13]
   2b8e4: e1a03403     	lsl	r3, r3, #8
   2b8e8: e1833002     	orr	r3, r3, r2
   2b8ec: e6ff3073     	uxth	r3, r3
   2b8f0: e3530000     	cmp	r3, #0
   2b8f4: 0a00001a     	beq	0x2b964 <scarletbook_read_master_toc+0x1768> @ imm = #0x68
   2b8f8: e51b2038     	ldr	r2, [r11, #-0x38]
   2b8fc: e51b3038     	ldr	r3, [r11, #-0x38]
   2b900: e5d31012     	ldrb	r1, [r3, #0x12]
   2b904: e5d33013     	ldrb	r3, [r3, #0x13]
   2b908: e1a03403     	lsl	r3, r3, #8
   2b90c: e1833001     	orr	r3, r3, r1
   2b910: e6ff3073     	uxth	r3, r3
   2b914: e0824003     	add	r4, r2, r3
   2b918: e51b2038     	ldr	r2, [r11, #-0x38]
   2b91c: e51b3038     	ldr	r3, [r11, #-0x38]
   2b920: e5d31012     	ldrb	r1, [r3, #0x12]
   2b924: e5d33013     	ldrb	r3, [r3, #0x13]
   2b928: e1a03403     	lsl	r3, r3, #8
   2b92c: e1833001     	orr	r3, r3, r1
   2b930: e6ff3073     	uxth	r3, r3
   2b934: e0823003     	add	r3, r2, r3
   2b938: e1a00003     	mov	r0, r3
   2b93c: ebff82e6     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1f468
   2b940: e1a03000     	mov	r3, r0
   2b944: e1a00004     	mov	r0, r4
   2b948: e1a01003     	mov	r1, r3
   2b94c: e51b2010     	ldr	r2, [r11, #-0x10]
   2b950: e51f38bc     	ldr	r3, [pc, #-0x8bc]       @ 0x2b09c <scarletbook_read_master_toc+0xea0>
   2b954: ebff8ae6     	bl	0xe4f4 <charset_convert> @ imm = #-0x1d468
   2b958: e1a02000     	mov	r2, r0
   2b95c: e51b3078     	ldr	r3, [r11, #-0x78]
   2b960: e5832018     	str	r2, [r3, #0x18]
   2b964: e51b3038     	ldr	r3, [r11, #-0x38]
   2b968: e5d3201a     	ldrb	r2, [r3, #0x1a]
   2b96c: e5d3301b     	ldrb	r3, [r3, #0x1b]
   2b970: e1a03403     	lsl	r3, r3, #8
   2b974: e1833002     	orr	r3, r3, r2
   2b978: e6ff3073     	uxth	r3, r3
   2b97c: e3530000     	cmp	r3, #0
   2b980: 0a00001a     	beq	0x2b9f0 <scarletbook_read_master_toc+0x17f4> @ imm = #0x68
   2b984: e51b2038     	ldr	r2, [r11, #-0x38]
   2b988: e51b3038     	ldr	r3, [r11, #-0x38]
   2b98c: e5d3101a     	ldrb	r1, [r3, #0x1a]
   2b990: e5d3301b     	ldrb	r3, [r3, #0x1b]
   2b994: e1a03403     	lsl	r3, r3, #8
   2b998: e1833001     	orr	r3, r3, r1
   2b99c: e6ff3073     	uxth	r3, r3
   2b9a0: e0824003     	add	r4, r2, r3
   2b9a4: e51b2038     	ldr	r2, [r11, #-0x38]
   2b9a8: e51b3038     	ldr	r3, [r11, #-0x38]
   2b9ac: e5d3101a     	ldrb	r1, [r3, #0x1a]
   2b9b0: e5d3301b     	ldrb	r3, [r3, #0x1b]
   2b9b4: e1a03403     	lsl	r3, r3, #8
   2b9b8: e1833001     	orr	r3, r3, r1
   2b9bc: e6ff3073     	uxth	r3, r3
   2b9c0: e0823003     	add	r3, r2, r3
   2b9c4: e1a00003     	mov	r0, r3
   2b9c8: ebff82c3     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1f4f4
   2b9cc: e1a03000     	mov	r3, r0
   2b9d0: e1a00004     	mov	r0, r4
   2b9d4: e1a01003     	mov	r1, r3
   2b9d8: e51b2010     	ldr	r2, [r11, #-0x10]
   2b9dc: e51f3948     	ldr	r3, [pc, #-0x948]       @ 0x2b09c <scarletbook_read_master_toc+0xea0>
   2b9e0: ebff8ac3     	bl	0xe4f4 <charset_convert> @ imm = #-0x1d4f4
   2b9e4: e1a02000     	mov	r2, r0
   2b9e8: e51b3078     	ldr	r3, [r11, #-0x78]
   2b9ec: e583201c     	str	r2, [r3, #0x1c]
   2b9f0: e51b3038     	ldr	r3, [r11, #-0x38]
   2b9f4: e5d32014     	ldrb	r2, [r3, #0x14]
   2b9f8: e5d33015     	ldrb	r3, [r3, #0x15]
   2b9fc: e1a03403     	lsl	r3, r3, #8
   2ba00: e1833002     	orr	r3, r3, r2
   2ba04: e6ff3073     	uxth	r3, r3
   2ba08: e3530000     	cmp	r3, #0
   2ba0c: 0a00001a     	beq	0x2ba7c <scarletbook_read_master_toc+0x1880> @ imm = #0x68
   2ba10: e51b2038     	ldr	r2, [r11, #-0x38]
   2ba14: e51b3038     	ldr	r3, [r11, #-0x38]
   2ba18: e5d31014     	ldrb	r1, [r3, #0x14]
   2ba1c: e5d33015     	ldrb	r3, [r3, #0x15]
   2ba20: e1a03403     	lsl	r3, r3, #8
   2ba24: e1833001     	orr	r3, r3, r1
   2ba28: e6ff3073     	uxth	r3, r3
   2ba2c: e0824003     	add	r4, r2, r3
   2ba30: e51b2038     	ldr	r2, [r11, #-0x38]
   2ba34: e51b3038     	ldr	r3, [r11, #-0x38]
   2ba38: e5d31014     	ldrb	r1, [r3, #0x14]
   2ba3c: e5d33015     	ldrb	r3, [r3, #0x15]
   2ba40: e1a03403     	lsl	r3, r3, #8
   2ba44: e1833001     	orr	r3, r3, r1
   2ba48: e6ff3073     	uxth	r3, r3
   2ba4c: e0823003     	add	r3, r2, r3
   2ba50: e1a00003     	mov	r0, r3
   2ba54: ebff82a0     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1f580
   2ba58: e1a03000     	mov	r3, r0
   2ba5c: e1a00004     	mov	r0, r4
   2ba60: e1a01003     	mov	r1, r3
   2ba64: e51b2010     	ldr	r2, [r11, #-0x10]
   2ba68: e51f39d4     	ldr	r3, [pc, #-0x9d4]       @ 0x2b09c <scarletbook_read_master_toc+0xea0>
   2ba6c: ebff8aa0     	bl	0xe4f4 <charset_convert> @ imm = #-0x1d580
   2ba70: e1a02000     	mov	r2, r0
   2ba74: e51b3078     	ldr	r3, [r11, #-0x78]
   2ba78: e5832020     	str	r2, [r3, #0x20]
   2ba7c: e51b3038     	ldr	r3, [r11, #-0x38]
   2ba80: e5d3201c     	ldrb	r2, [r3, #0x1c]
   2ba84: e5d3301d     	ldrb	r3, [r3, #0x1d]
   2ba88: e1a03403     	lsl	r3, r3, #8
   2ba8c: e1833002     	orr	r3, r3, r2
   2ba90: e6ff3073     	uxth	r3, r3
   2ba94: e3530000     	cmp	r3, #0
   2ba98: 0a00001a     	beq	0x2bb08 <scarletbook_read_master_toc+0x190c> @ imm = #0x68
   2ba9c: e51b2038     	ldr	r2, [r11, #-0x38]
   2baa0: e51b3038     	ldr	r3, [r11, #-0x38]
   2baa4: e5d3101c     	ldrb	r1, [r3, #0x1c]
   2baa8: e5d3301d     	ldrb	r3, [r3, #0x1d]
   2baac: e1a03403     	lsl	r3, r3, #8
   2bab0: e1833001     	orr	r3, r3, r1
   2bab4: e6ff3073     	uxth	r3, r3
   2bab8: e0824003     	add	r4, r2, r3
   2babc: e51b2038     	ldr	r2, [r11, #-0x38]
   2bac0: e51b3038     	ldr	r3, [r11, #-0x38]
   2bac4: e5d3101c     	ldrb	r1, [r3, #0x1c]
   2bac8: e5d3301d     	ldrb	r3, [r3, #0x1d]
   2bacc: e1a03403     	lsl	r3, r3, #8
   2bad0: e1833001     	orr	r3, r3, r1
   2bad4: e6ff3073     	uxth	r3, r3
   2bad8: e0823003     	add	r3, r2, r3
   2badc: e1a00003     	mov	r0, r3
   2bae0: ebff827d     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1f60c
   2bae4: e1a03000     	mov	r3, r0
   2bae8: e1a00004     	mov	r0, r4
   2baec: e1a01003     	mov	r1, r3
   2baf0: e51b2010     	ldr	r2, [r11, #-0x10]
   2baf4: e51f3a60     	ldr	r3, [pc, #-0xa60]       @ 0x2b09c <scarletbook_read_master_toc+0xea0>
   2baf8: ebff8a7d     	bl	0xe4f4 <charset_convert> @ imm = #-0x1d60c
   2bafc: e1a02000     	mov	r2, r0
   2bb00: e51b3078     	ldr	r3, [r11, #-0x78]
   2bb04: e5832024     	str	r2, [r3, #0x24]
   2bb08: e51b3038     	ldr	r3, [r11, #-0x38]
   2bb0c: e5d32016     	ldrb	r2, [r3, #0x16]
   2bb10: e5d33017     	ldrb	r3, [r3, #0x17]
   2bb14: e1a03403     	lsl	r3, r3, #8
   2bb18: e1833002     	orr	r3, r3, r2
   2bb1c: e6ff3073     	uxth	r3, r3
   2bb20: e3530000     	cmp	r3, #0
   2bb24: 0a00001a     	beq	0x2bb94 <scarletbook_read_master_toc+0x1998> @ imm = #0x68
   2bb28: e51b2038     	ldr	r2, [r11, #-0x38]
   2bb2c: e51b3038     	ldr	r3, [r11, #-0x38]
   2bb30: e5d31016     	ldrb	r1, [r3, #0x16]
   2bb34: e5d33017     	ldrb	r3, [r3, #0x17]
   2bb38: e1a03403     	lsl	r3, r3, #8
   2bb3c: e1833001     	orr	r3, r3, r1
   2bb40: e6ff3073     	uxth	r3, r3
   2bb44: e0824003     	add	r4, r2, r3
   2bb48: e51b2038     	ldr	r2, [r11, #-0x38]
   2bb4c: e51b3038     	ldr	r3, [r11, #-0x38]
   2bb50: e5d31016     	ldrb	r1, [r3, #0x16]
   2bb54: e5d33017     	ldrb	r3, [r3, #0x17]
   2bb58: e1a03403     	lsl	r3, r3, #8
   2bb5c: e1833001     	orr	r3, r3, r1
   2bb60: e6ff3073     	uxth	r3, r3
   2bb64: e0823003     	add	r3, r2, r3
   2bb68: e1a00003     	mov	r0, r3
   2bb6c: ebff825a     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1f698
   2bb70: e1a03000     	mov	r3, r0
   2bb74: e1a00004     	mov	r0, r4
   2bb78: e1a01003     	mov	r1, r3
   2bb7c: e51b2010     	ldr	r2, [r11, #-0x10]
   2bb80: e51f3aec     	ldr	r3, [pc, #-0xaec]       @ 0x2b09c <scarletbook_read_master_toc+0xea0>
   2bb84: ebff8a5a     	bl	0xe4f4 <charset_convert> @ imm = #-0x1d698
   2bb88: e1a02000     	mov	r2, r0
   2bb8c: e51b3078     	ldr	r3, [r11, #-0x78]
   2bb90: e5832028     	str	r2, [r3, #0x28]
   2bb94: e51b3038     	ldr	r3, [r11, #-0x38]
   2bb98: e5d3201e     	ldrb	r2, [r3, #0x1e]
   2bb9c: e5d3301f     	ldrb	r3, [r3, #0x1f]
   2bba0: e1a03403     	lsl	r3, r3, #8
   2bba4: e1833002     	orr	r3, r3, r2
   2bba8: e6ff3073     	uxth	r3, r3
   2bbac: e3530000     	cmp	r3, #0
   2bbb0: 0a00001a     	beq	0x2bc20 <scarletbook_read_master_toc+0x1a24> @ imm = #0x68
   2bbb4: e51b2038     	ldr	r2, [r11, #-0x38]
   2bbb8: e51b3038     	ldr	r3, [r11, #-0x38]
   2bbbc: e5d3101e     	ldrb	r1, [r3, #0x1e]
   2bbc0: e5d3301f     	ldrb	r3, [r3, #0x1f]
   2bbc4: e1a03403     	lsl	r3, r3, #8
   2bbc8: e1833001     	orr	r3, r3, r1
   2bbcc: e6ff3073     	uxth	r3, r3
   2bbd0: e0824003     	add	r4, r2, r3
   2bbd4: e51b2038     	ldr	r2, [r11, #-0x38]
   2bbd8: e51b3038     	ldr	r3, [r11, #-0x38]
   2bbdc: e5d3101e     	ldrb	r1, [r3, #0x1e]
   2bbe0: e5d3301f     	ldrb	r3, [r3, #0x1f]
   2bbe4: e1a03403     	lsl	r3, r3, #8
   2bbe8: e1833001     	orr	r3, r3, r1
   2bbec: e6ff3073     	uxth	r3, r3
   2bbf0: e0823003     	add	r3, r2, r3
   2bbf4: e1a00003     	mov	r0, r3
   2bbf8: ebff8237     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1f724
   2bbfc: e1a03000     	mov	r3, r0
   2bc00: e1a00004     	mov	r0, r4
   2bc04: e1a01003     	mov	r1, r3
   2bc08: e51b2010     	ldr	r2, [r11, #-0x10]
   2bc0c: e51f3b78     	ldr	r3, [pc, #-0xb78]       @ 0x2b09c <scarletbook_read_master_toc+0xea0>
   2bc10: ebff8a37     	bl	0xe4f4 <charset_convert> @ imm = #-0x1d724
   2bc14: e1a02000     	mov	r2, r0
   2bc18: e51b3078     	ldr	r3, [r11, #-0x78]
   2bc1c: e583202c     	str	r2, [r3, #0x2c]
   2bc20: e51b3038     	ldr	r3, [r11, #-0x38]
   2bc24: e5d32020     	ldrb	r2, [r3, #0x20]
   2bc28: e5d33021     	ldrb	r3, [r3, #0x21]
   2bc2c: e1a03403     	lsl	r3, r3, #8
   2bc30: e1833002     	orr	r3, r3, r2
   2bc34: e6ff3073     	uxth	r3, r3
   2bc38: e3530000     	cmp	r3, #0
   2bc3c: 0a00001a     	beq	0x2bcac <scarletbook_read_master_toc+0x1ab0> @ imm = #0x68
   2bc40: e51b2038     	ldr	r2, [r11, #-0x38]
   2bc44: e51b3038     	ldr	r3, [r11, #-0x38]
   2bc48: e5d31020     	ldrb	r1, [r3, #0x20]
   2bc4c: e5d33021     	ldrb	r3, [r3, #0x21]
   2bc50: e1a03403     	lsl	r3, r3, #8
   2bc54: e1833001     	orr	r3, r3, r1
   2bc58: e6ff3073     	uxth	r3, r3
   2bc5c: e0824003     	add	r4, r2, r3
   2bc60: e51b2038     	ldr	r2, [r11, #-0x38]
   2bc64: e51b3038     	ldr	r3, [r11, #-0x38]
   2bc68: e5d31020     	ldrb	r1, [r3, #0x20]
   2bc6c: e5d33021     	ldrb	r3, [r3, #0x21]
   2bc70: e1a03403     	lsl	r3, r3, #8
   2bc74: e1833001     	orr	r3, r3, r1
   2bc78: e6ff3073     	uxth	r3, r3
   2bc7c: e0823003     	add	r3, r2, r3
   2bc80: e1a00003     	mov	r0, r3
   2bc84: ebff8214     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1f7b0
   2bc88: e1a03000     	mov	r3, r0
   2bc8c: e1a00004     	mov	r0, r4
   2bc90: e1a01003     	mov	r1, r3
   2bc94: e51b2010     	ldr	r2, [r11, #-0x10]
   2bc98: e51f3c04     	ldr	r3, [pc, #-0xc04]       @ 0x2b09c <scarletbook_read_master_toc+0xea0>
   2bc9c: ebff8a14     	bl	0xe4f4 <charset_convert> @ imm = #-0x1d7b0
   2bca0: e1a02000     	mov	r2, r0
   2bca4: e51b3078     	ldr	r3, [r11, #-0x78]
   2bca8: e5832030     	str	r2, [r3, #0x30]
   2bcac: e51b3038     	ldr	r3, [r11, #-0x38]
   2bcb0: e5d32028     	ldrb	r2, [r3, #0x28]
   2bcb4: e5d33029     	ldrb	r3, [r3, #0x29]
   2bcb8: e1a03403     	lsl	r3, r3, #8
   2bcbc: e1833002     	orr	r3, r3, r2
   2bcc0: e6ff3073     	uxth	r3, r3
   2bcc4: e3530000     	cmp	r3, #0
   2bcc8: 0a00001a     	beq	0x2bd38 <scarletbook_read_master_toc+0x1b3c> @ imm = #0x68
   2bccc: e51b2038     	ldr	r2, [r11, #-0x38]
   2bcd0: e51b3038     	ldr	r3, [r11, #-0x38]
   2bcd4: e5d31028     	ldrb	r1, [r3, #0x28]
   2bcd8: e5d33029     	ldrb	r3, [r3, #0x29]
   2bcdc: e1a03403     	lsl	r3, r3, #8
   2bce0: e1833001     	orr	r3, r3, r1
   2bce4: e6ff3073     	uxth	r3, r3
   2bce8: e0824003     	add	r4, r2, r3
   2bcec: e51b2038     	ldr	r2, [r11, #-0x38]
   2bcf0: e51b3038     	ldr	r3, [r11, #-0x38]
   2bcf4: e5d31028     	ldrb	r1, [r3, #0x28]
   2bcf8: e5d33029     	ldrb	r3, [r3, #0x29]
   2bcfc: e1a03403     	lsl	r3, r3, #8
   2bd00: e1833001     	orr	r3, r3, r1
   2bd04: e6ff3073     	uxth	r3, r3
   2bd08: e0823003     	add	r3, r2, r3
   2bd0c: e1a00003     	mov	r0, r3
   2bd10: ebff81f1     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1f83c
   2bd14: e1a03000     	mov	r3, r0
   2bd18: e1a00004     	mov	r0, r4
   2bd1c: e1a01003     	mov	r1, r3
   2bd20: e51b2010     	ldr	r2, [r11, #-0x10]
   2bd24: e51f3c90     	ldr	r3, [pc, #-0xc90]       @ 0x2b09c <scarletbook_read_master_toc+0xea0>
   2bd28: ebff89f1     	bl	0xe4f4 <charset_convert> @ imm = #-0x1d83c
   2bd2c: e1a02000     	mov	r2, r0
   2bd30: e51b3078     	ldr	r3, [r11, #-0x78]
   2bd34: e5832034     	str	r2, [r3, #0x34]
   2bd38: e51b3038     	ldr	r3, [r11, #-0x38]
   2bd3c: e5d32022     	ldrb	r2, [r3, #0x22]
   2bd40: e5d33023     	ldrb	r3, [r3, #0x23]
   2bd44: e1a03403     	lsl	r3, r3, #8
   2bd48: e1833002     	orr	r3, r3, r2
   2bd4c: e6ff3073     	uxth	r3, r3
   2bd50: e3530000     	cmp	r3, #0
   2bd54: 0a00001a     	beq	0x2bdc4 <scarletbook_read_master_toc+0x1bc8> @ imm = #0x68
   2bd58: e51b2038     	ldr	r2, [r11, #-0x38]
   2bd5c: e51b3038     	ldr	r3, [r11, #-0x38]
   2bd60: e5d31022     	ldrb	r1, [r3, #0x22]
   2bd64: e5d33023     	ldrb	r3, [r3, #0x23]
   2bd68: e1a03403     	lsl	r3, r3, #8
   2bd6c: e1833001     	orr	r3, r3, r1
   2bd70: e6ff3073     	uxth	r3, r3
   2bd74: e0824003     	add	r4, r2, r3
   2bd78: e51b2038     	ldr	r2, [r11, #-0x38]
   2bd7c: e51b3038     	ldr	r3, [r11, #-0x38]
   2bd80: e5d31022     	ldrb	r1, [r3, #0x22]
   2bd84: e5d33023     	ldrb	r3, [r3, #0x23]
   2bd88: e1a03403     	lsl	r3, r3, #8
   2bd8c: e1833001     	orr	r3, r3, r1
   2bd90: e6ff3073     	uxth	r3, r3
   2bd94: e0823003     	add	r3, r2, r3
   2bd98: e1a00003     	mov	r0, r3
   2bd9c: ebff81ce     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1f8c8
   2bda0: e1a03000     	mov	r3, r0
   2bda4: e1a00004     	mov	r0, r4
   2bda8: e1a01003     	mov	r1, r3
   2bdac: e51b2010     	ldr	r2, [r11, #-0x10]
   2bdb0: e51f3d1c     	ldr	r3, [pc, #-0xd1c]       @ 0x2b09c <scarletbook_read_master_toc+0xea0>
   2bdb4: ebff89ce     	bl	0xe4f4 <charset_convert> @ imm = #-0x1d8c8
   2bdb8: e1a02000     	mov	r2, r0
   2bdbc: e51b3078     	ldr	r3, [r11, #-0x78]
   2bdc0: e5832038     	str	r2, [r3, #0x38]
   2bdc4: e51b3038     	ldr	r3, [r11, #-0x38]
   2bdc8: e5d3202a     	ldrb	r2, [r3, #0x2a]
   2bdcc: e5d3302b     	ldrb	r3, [r3, #0x2b]
   2bdd0: e1a03403     	lsl	r3, r3, #8
   2bdd4: e1833002     	orr	r3, r3, r2
   2bdd8: e6ff3073     	uxth	r3, r3
   2bddc: e3530000     	cmp	r3, #0
   2bde0: 0a00001a     	beq	0x2be50 <scarletbook_read_master_toc+0x1c54> @ imm = #0x68
   2bde4: e51b2038     	ldr	r2, [r11, #-0x38]
   2bde8: e51b3038     	ldr	r3, [r11, #-0x38]
   2bdec: e5d3102a     	ldrb	r1, [r3, #0x2a]
   2bdf0: e5d3302b     	ldrb	r3, [r3, #0x2b]
   2bdf4: e1a03403     	lsl	r3, r3, #8
   2bdf8: e1833001     	orr	r3, r3, r1
   2bdfc: e6ff3073     	uxth	r3, r3
   2be00: e0824003     	add	r4, r2, r3
   2be04: e51b2038     	ldr	r2, [r11, #-0x38]
   2be08: e51b3038     	ldr	r3, [r11, #-0x38]
   2be0c: e5d3102a     	ldrb	r1, [r3, #0x2a]
   2be10: e5d3302b     	ldrb	r3, [r3, #0x2b]
   2be14: e1a03403     	lsl	r3, r3, #8
   2be18: e1833001     	orr	r3, r3, r1
   2be1c: e6ff3073     	uxth	r3, r3
   2be20: e0823003     	add	r3, r2, r3
   2be24: e1a00003     	mov	r0, r3
   2be28: ebff81ab     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1f954
   2be2c: e1a03000     	mov	r3, r0
   2be30: e1a00004     	mov	r0, r4
   2be34: e1a01003     	mov	r1, r3
   2be38: e51b2010     	ldr	r2, [r11, #-0x10]
   2be3c: e51f3da8     	ldr	r3, [pc, #-0xda8]       @ 0x2b09c <scarletbook_read_master_toc+0xea0>
   2be40: ebff89ab     	bl	0xe4f4 <charset_convert> @ imm = #-0x1d954
   2be44: e1a02000     	mov	r2, r0
   2be48: e51b3078     	ldr	r3, [r11, #-0x78]
   2be4c: e583203c     	str	r2, [r3, #0x3c]
   2be50: e51b3038     	ldr	r3, [r11, #-0x38]
   2be54: e5d32024     	ldrb	r2, [r3, #0x24]
   2be58: e5d33025     	ldrb	r3, [r3, #0x25]
   2be5c: e1a03403     	lsl	r3, r3, #8
   2be60: e1833002     	orr	r3, r3, r2
   2be64: e6ff3073     	uxth	r3, r3
   2be68: e3530000     	cmp	r3, #0
   2be6c: 0a00001a     	beq	0x2bedc <scarletbook_read_master_toc+0x1ce0> @ imm = #0x68
   2be70: e51b2038     	ldr	r2, [r11, #-0x38]
   2be74: e51b3038     	ldr	r3, [r11, #-0x38]
   2be78: e5d31024     	ldrb	r1, [r3, #0x24]
   2be7c: e5d33025     	ldrb	r3, [r3, #0x25]
   2be80: e1a03403     	lsl	r3, r3, #8
   2be84: e1833001     	orr	r3, r3, r1
   2be88: e6ff3073     	uxth	r3, r3
   2be8c: e0824003     	add	r4, r2, r3
   2be90: e51b2038     	ldr	r2, [r11, #-0x38]
   2be94: e51b3038     	ldr	r3, [r11, #-0x38]
   2be98: e5d31024     	ldrb	r1, [r3, #0x24]
   2be9c: e5d33025     	ldrb	r3, [r3, #0x25]
   2bea0: e1a03403     	lsl	r3, r3, #8
   2bea4: e1833001     	orr	r3, r3, r1
   2bea8: e6ff3073     	uxth	r3, r3
   2beac: e0823003     	add	r3, r2, r3
   2beb0: e1a00003     	mov	r0, r3
   2beb4: ebff8188     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1f9e0
   2beb8: e1a03000     	mov	r3, r0
   2bebc: e1a00004     	mov	r0, r4
   2bec0: e1a01003     	mov	r1, r3
   2bec4: e51b2010     	ldr	r2, [r11, #-0x10]
   2bec8: e51f3e34     	ldr	r3, [pc, #-0xe34]       @ 0x2b09c <scarletbook_read_master_toc+0xea0>
   2becc: ebff8988     	bl	0xe4f4 <charset_convert> @ imm = #-0x1d9e0
   2bed0: e1a02000     	mov	r2, r0
   2bed4: e51b3078     	ldr	r3, [r11, #-0x78]
   2bed8: e5832040     	str	r2, [r3, #0x40]
   2bedc: e51b3038     	ldr	r3, [r11, #-0x38]
   2bee0: e5d3202c     	ldrb	r2, [r3, #0x2c]
   2bee4: e5d3302d     	ldrb	r3, [r3, #0x2d]
   2bee8: e1a03403     	lsl	r3, r3, #8
   2beec: e1833002     	orr	r3, r3, r2
   2bef0: e6ff3073     	uxth	r3, r3
   2bef4: e3530000     	cmp	r3, #0
   2bef8: 0a00001a     	beq	0x2bf68 <scarletbook_read_master_toc+0x1d6c> @ imm = #0x68
   2befc: e51b2038     	ldr	r2, [r11, #-0x38]
   2bf00: e51b3038     	ldr	r3, [r11, #-0x38]
   2bf04: e5d3102c     	ldrb	r1, [r3, #0x2c]
   2bf08: e5d3302d     	ldrb	r3, [r3, #0x2d]
   2bf0c: e1a03403     	lsl	r3, r3, #8
   2bf10: e1833001     	orr	r3, r3, r1
   2bf14: e6ff3073     	uxth	r3, r3
   2bf18: e0824003     	add	r4, r2, r3
   2bf1c: e51b2038     	ldr	r2, [r11, #-0x38]
   2bf20: e51b3038     	ldr	r3, [r11, #-0x38]
   2bf24: e5d3102c     	ldrb	r1, [r3, #0x2c]
   2bf28: e5d3302d     	ldrb	r3, [r3, #0x2d]
   2bf2c: e1a03403     	lsl	r3, r3, #8
   2bf30: e1833001     	orr	r3, r3, r1
   2bf34: e6ff3073     	uxth	r3, r3
   2bf38: e0823003     	add	r3, r2, r3
   2bf3c: e1a00003     	mov	r0, r3
   2bf40: ebff8165     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1fa6c
   2bf44: e1a03000     	mov	r3, r0
   2bf48: e1a00004     	mov	r0, r4
   2bf4c: e1a01003     	mov	r1, r3
   2bf50: e51b2010     	ldr	r2, [r11, #-0x10]
   2bf54: e59f3190     	ldr	r3, [pc, #0x190]        @ 0x2c0ec <scarletbook_read_master_toc+0x1ef0>
   2bf58: ebff8965     	bl	0xe4f4 <charset_convert> @ imm = #-0x1da6c
   2bf5c: e1a02000     	mov	r2, r0
   2bf60: e51b3078     	ldr	r3, [r11, #-0x78]
   2bf64: e5832044     	str	r2, [r3, #0x44]
   2bf68: e51b3038     	ldr	r3, [r11, #-0x38]
   2bf6c: e5d32026     	ldrb	r2, [r3, #0x26]
   2bf70: e5d33027     	ldrb	r3, [r3, #0x27]
   2bf74: e1a03403     	lsl	r3, r3, #8
   2bf78: e1833002     	orr	r3, r3, r2
   2bf7c: e6ff3073     	uxth	r3, r3
   2bf80: e3530000     	cmp	r3, #0
   2bf84: 0a00001a     	beq	0x2bff4 <scarletbook_read_master_toc+0x1df8> @ imm = #0x68
   2bf88: e51b2038     	ldr	r2, [r11, #-0x38]
   2bf8c: e51b3038     	ldr	r3, [r11, #-0x38]
   2bf90: e5d31026     	ldrb	r1, [r3, #0x26]
   2bf94: e5d33027     	ldrb	r3, [r3, #0x27]
   2bf98: e1a03403     	lsl	r3, r3, #8
   2bf9c: e1833001     	orr	r3, r3, r1
   2bfa0: e6ff3073     	uxth	r3, r3
   2bfa4: e0824003     	add	r4, r2, r3
   2bfa8: e51b2038     	ldr	r2, [r11, #-0x38]
   2bfac: e51b3038     	ldr	r3, [r11, #-0x38]
   2bfb0: e5d31026     	ldrb	r1, [r3, #0x26]
   2bfb4: e5d33027     	ldrb	r3, [r3, #0x27]
   2bfb8: e1a03403     	lsl	r3, r3, #8
   2bfbc: e1833001     	orr	r3, r3, r1
   2bfc0: e6ff3073     	uxth	r3, r3
   2bfc4: e0823003     	add	r3, r2, r3
   2bfc8: e1a00003     	mov	r0, r3
   2bfcc: ebff8142     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1faf8
   2bfd0: e1a03000     	mov	r3, r0
   2bfd4: e1a00004     	mov	r0, r4
   2bfd8: e1a01003     	mov	r1, r3
   2bfdc: e51b2010     	ldr	r2, [r11, #-0x10]
   2bfe0: e59f3104     	ldr	r3, [pc, #0x104]        @ 0x2c0ec <scarletbook_read_master_toc+0x1ef0>
   2bfe4: ebff8942     	bl	0xe4f4 <charset_convert> @ imm = #-0x1daf8
   2bfe8: e1a02000     	mov	r2, r0
   2bfec: e51b3078     	ldr	r3, [r11, #-0x78]
   2bff0: e5832048     	str	r2, [r3, #0x48]
   2bff4: e51b3038     	ldr	r3, [r11, #-0x38]
   2bff8: e5d3202e     	ldrb	r2, [r3, #0x2e]
   2bffc: e5d3302f     	ldrb	r3, [r3, #0x2f]
   2c000: e1a03403     	lsl	r3, r3, #8
   2c004: e1833002     	orr	r3, r3, r2
   2c008: e6ff3073     	uxth	r3, r3
   2c00c: e3530000     	cmp	r3, #0
   2c010: 0a00001a     	beq	0x2c080 <scarletbook_read_master_toc+0x1e84> @ imm = #0x68
   2c014: e51b2038     	ldr	r2, [r11, #-0x38]
   2c018: e51b3038     	ldr	r3, [r11, #-0x38]
   2c01c: e5d3102e     	ldrb	r1, [r3, #0x2e]
   2c020: e5d3302f     	ldrb	r3, [r3, #0x2f]
   2c024: e1a03403     	lsl	r3, r3, #8
   2c028: e1833001     	orr	r3, r3, r1
   2c02c: e6ff3073     	uxth	r3, r3
   2c030: e0824003     	add	r4, r2, r3
   2c034: e51b2038     	ldr	r2, [r11, #-0x38]
   2c038: e51b3038     	ldr	r3, [r11, #-0x38]
   2c03c: e5d3102e     	ldrb	r1, [r3, #0x2e]
   2c040: e5d3302f     	ldrb	r3, [r3, #0x2f]
   2c044: e1a03403     	lsl	r3, r3, #8
   2c048: e1833001     	orr	r3, r3, r1
   2c04c: e6ff3073     	uxth	r3, r3
   2c050: e0823003     	add	r3, r2, r3
   2c054: e1a00003     	mov	r0, r3
   2c058: ebff811f     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1fb84
   2c05c: e1a03000     	mov	r3, r0
   2c060: e1a00004     	mov	r0, r4
   2c064: e1a01003     	mov	r1, r3
   2c068: e51b2010     	ldr	r2, [r11, #-0x10]
   2c06c: e59f3078     	ldr	r3, [pc, #0x78]         @ 0x2c0ec <scarletbook_read_master_toc+0x1ef0>
   2c070: ebff891f     	bl	0xe4f4 <charset_convert> @ imm = #-0x1db84
   2c074: e1a02000     	mov	r2, r0
   2c078: e51b3078     	ldr	r3, [r11, #-0x78]
   2c07c: e583204c     	str	r2, [r3, #0x4c]
   2c080: e51b306c     	ldr	r3, [r11, #-0x6c]
   2c084: e2833b02     	add	r3, r3, #2048
   2c088: e50b306c     	str	r3, [r11, #-0x6c]
   2c08c: e51b3070     	ldr	r3, [r11, #-0x70]
   2c090: e2833001     	add	r3, r3, #1
   2c094: e50b3070     	str	r3, [r11, #-0x70]
   2c098: e51b3070     	ldr	r3, [r11, #-0x70]
   2c09c: e3530007     	cmp	r3, #7
   2c0a0: dafffbb7     	ble	0x2af84 <scarletbook_read_master_toc+0xd88> @ imm = #-0x1124
   2c0a4: e51b206c     	ldr	r2, [r11, #-0x6c]
   2c0a8: e51b3078     	ldr	r3, [r11, #-0x78]
   2c0ac: e583200c     	str	r2, [r3, #0xc]
   2c0b0: e51b3078     	ldr	r3, [r11, #-0x78]
   2c0b4: e593300c     	ldr	r3, [r3, #0xc]
   2c0b8: e59f0030     	ldr	r0, [pc, #0x30]         @ 0x2c0f0 <scarletbook_read_master_toc+0x1ef4>
   2c0bc: e1a01003     	mov	r1, r3
   2c0c0: e3a02008     	mov	r2, #8
   2c0c4: ebff81a9     	bl	0xc770 <strncmp@plt>    @ imm = #-0x1f95c
   2c0c8: e1a03000     	mov	r3, r0
   2c0cc: e3530000     	cmp	r3, #0
   2c0d0: 0a000001     	beq	0x2c0dc <scarletbook_read_master_toc+0x1ee0> @ imm = #0x4
   2c0d4: e3a03000     	mov	r3, #0
   2c0d8: ea000000     	b	0x2c0e0 <scarletbook_read_master_toc+0x1ee4> @ imm = #0x0
   2c0dc: e3a03001     	mov	r3, #1
   2c0e0: e1a00003     	mov	r0, r3
   2c0e4: e24bd008     	sub	sp, r11, #8
   2c0e8: e8bd8810     	pop	{r4, r11, pc}
   2c0ec: 90 5c 03 00  	.word	0x00035c90
   2c0f0: 98 5c 03 00  	.word	0x00035c98

