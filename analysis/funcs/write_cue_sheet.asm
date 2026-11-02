000213fc <write_cue_sheet>:
   213fc: e92d4810     	push	{r4, r11, lr}
   21400: e28db008     	add	r11, sp, #8
   21404: e24dd03c     	sub	sp, sp, #60
   21408: e50b0030     	str	r0, [r11, #-0x30]
   2140c: e50b1034     	str	r1, [r11, #-0x34]
   21410: e50b2038     	str	r2, [r11, #-0x38]
   21414: e50b303c     	str	r3, [r11, #-0x3c]
   21418: e51b203c     	ldr	r2, [r11, #-0x3c]
   2141c: e59f3850     	ldr	r3, [pc, #0x850]        @ 0x21c74 <write_cue_sheet+0x878>
   21420: e1a00002     	mov	r0, r2
   21424: e1a01003     	mov	r1, r3
   21428: ebffac40     	bl	0xc530 <fopen64@plt>    @ imm = #-0x14f00
   2142c: e1a03000     	mov	r3, r0
   21430: e50b3028     	str	r3, [r11, #-0x28]
   21434: e51b3028     	ldr	r3, [r11, #-0x28]
   21438: e3530000     	cmp	r3, #0
   2143c: 1a000001     	bne	0x21448 <write_cue_sheet+0x4c> @ imm = #0x4
   21440: e3e03000     	mvn	r3, #0
   21444: ea000207     	b	0x21c68 <write_cue_sheet+0x86c> @ imm = #0x81c
   21448: e3a000ef     	mov	r0, #239
   2144c: e51b1028     	ldr	r1, [r11, #-0x28]
   21450: ebffac96     	bl	0xc6b0 <fputc@plt>      @ imm = #-0x14da8
   21454: e3a000bb     	mov	r0, #187
   21458: e51b1028     	ldr	r1, [r11, #-0x28]
   2145c: ebffac93     	bl	0xc6b0 <fputc@plt>      @ imm = #-0x14db4
   21460: e3a000bf     	mov	r0, #191
   21464: e51b1028     	ldr	r1, [r11, #-0x28]
   21468: ebffac90     	bl	0xc6b0 <fputc@plt>      @ imm = #-0x14dc0
   2146c: e59f3804     	ldr	r3, [pc, #0x804]        @ 0x21c78 <write_cue_sheet+0x87c>
   21470: e1a00003     	mov	r0, r3
   21474: e3a01001     	mov	r1, #1
   21478: e3a02031     	mov	r2, #49
   2147c: e51b3028     	ldr	r3, [r11, #-0x28]
   21480: ebffac5a     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x14e98
   21484: e51b3030     	ldr	r3, [r11, #-0x30]
   21488: e5933008     	ldr	r3, [r3, #0x8]
   2148c: e5d3306b     	ldrb	r3, [r3, #0x6b]
   21490: e3530000     	cmp	r3, #0
   21494: 0a00000a     	beq	0x214c4 <write_cue_sheet+0xc8> @ imm = #0x28
   21498: e59f27dc     	ldr	r2, [pc, #0x7dc]        @ 0x21c7c <write_cue_sheet+0x880>
   2149c: e51b3030     	ldr	r3, [r11, #-0x30]
   214a0: e5933008     	ldr	r3, [r3, #0x8]
   214a4: e5d3306b     	ldrb	r3, [r3, #0x6b]
   214a8: e1a01003     	mov	r1, r3
   214ac: e59f37cc     	ldr	r3, [pc, #0x7cc]        @ 0x21c80 <write_cue_sheet+0x884>
   214b0: e7933101     	ldr	r3, [r3, r1, lsl #2]
   214b4: e51b0028     	ldr	r0, [r11, #-0x28]
   214b8: e1a01002     	mov	r1, r2
   214bc: e1a02003     	mov	r2, r3
   214c0: ebffac5f     	bl	0xc644 <fprintf@plt>    @ imm = #-0x14e84
   214c4: e51b3030     	ldr	r3, [r11, #-0x30]
   214c8: e5933008     	ldr	r3, [r3, #0x8]
   214cc: e5d32078     	ldrb	r2, [r3, #0x78]
   214d0: e5d33079     	ldrb	r3, [r3, #0x79]
   214d4: e1a03403     	lsl	r3, r3, #8
   214d8: e1833002     	orr	r3, r3, r2
   214dc: e6ff3073     	uxth	r3, r3
   214e0: e3530000     	cmp	r3, #0
   214e4: 0a000011     	beq	0x21530 <write_cue_sheet+0x134> @ imm = #0x44
   214e8: e59f1794     	ldr	r1, [pc, #0x794]        @ 0x21c84 <write_cue_sheet+0x888>
   214ec: e51b3030     	ldr	r3, [r11, #-0x30]
   214f0: e5933008     	ldr	r3, [r3, #0x8]
   214f4: e5d32078     	ldrb	r2, [r3, #0x78]
   214f8: e5d33079     	ldrb	r3, [r3, #0x79]
   214fc: e1a03403     	lsl	r3, r3, #8
   21500: e1833002     	orr	r3, r3, r2
   21504: e6ff3073     	uxth	r3, r3
   21508: e1a02003     	mov	r2, r3
   2150c: e51b3030     	ldr	r3, [r11, #-0x30]
   21510: e5933008     	ldr	r3, [r3, #0x8]
   21514: e5d3307a     	ldrb	r3, [r3, #0x7a]
   21518: e51b0030     	ldr	r0, [r11, #-0x30]
   2151c: e5900008     	ldr	r0, [r0, #0x8]
   21520: e5d0007b     	ldrb	r0, [r0, #0x7b]
   21524: e58d0000     	str	r0, [sp]
   21528: e51b0028     	ldr	r0, [r11, #-0x28]
   2152c: ebffac44     	bl	0xc644 <fprintf@plt>    @ imm = #-0x14ef0
   21530: e51b3030     	ldr	r3, [r11, #-0x30]
   21534: e5933038     	ldr	r3, [r3, #0x38]
   21538: e3530000     	cmp	r3, #0
   2153c: 0a000009     	beq	0x21568 <write_cue_sheet+0x16c> @ imm = #0x24
   21540: e59f4740     	ldr	r4, [pc, #0x740]        @ 0x21c88 <write_cue_sheet+0x88c>
   21544: e51b3030     	ldr	r3, [r11, #-0x30]
   21548: e5933038     	ldr	r3, [r3, #0x38]
   2154c: e1a00003     	mov	r0, r3
   21550: ebffff90     	bl	0x21398 <cue_escape>    @ imm = #-0x1c0
   21554: e1a03000     	mov	r3, r0
   21558: e51b0028     	ldr	r0, [r11, #-0x28]
   2155c: e1a01004     	mov	r1, r4
   21560: e1a02003     	mov	r2, r3
   21564: ebffac36     	bl	0xc644 <fprintf@plt>    @ imm = #-0x14f28
   21568: e51b3030     	ldr	r3, [r11, #-0x30]
   2156c: e5933030     	ldr	r3, [r3, #0x30]
   21570: e3530000     	cmp	r3, #0
   21574: 0a000009     	beq	0x215a0 <write_cue_sheet+0x1a4> @ imm = #0x24
   21578: e59f470c     	ldr	r4, [pc, #0x70c]        @ 0x21c8c <write_cue_sheet+0x890>
   2157c: e51b3030     	ldr	r3, [r11, #-0x30]
   21580: e5933030     	ldr	r3, [r3, #0x30]
   21584: e1a00003     	mov	r0, r3
   21588: ebffff82     	bl	0x21398 <cue_escape>    @ imm = #-0x1f8
   2158c: e1a03000     	mov	r3, r0
   21590: e51b0028     	ldr	r0, [r11, #-0x28]
   21594: e1a01004     	mov	r1, r4
   21598: e1a02003     	mov	r2, r3
   2159c: ebffac28     	bl	0xc644 <fprintf@plt>    @ imm = #-0x14f60
   215a0: e51b3030     	ldr	r3, [r11, #-0x30]
   215a4: e5933008     	ldr	r3, [r3, #0x8]
   215a8: e2833058     	add	r3, r3, #88
   215ac: e5d33000     	ldrb	r3, [r3]
   215b0: e3530000     	cmp	r3, #0
   215b4: 0a00000f     	beq	0x215f8 <write_cue_sheet+0x1fc> @ imm = #0x3c
   215b8: e59f46d0     	ldr	r4, [pc, #0x6d0]        @ 0x21c90 <write_cue_sheet+0x894>
   215bc: e51b3030     	ldr	r3, [r11, #-0x30]
   215c0: e5933008     	ldr	r3, [r3, #0x8]
   215c4: e2833058     	add	r3, r3, #88
   215c8: e1a00003     	mov	r0, r3
   215cc: e3a01000     	mov	r1, #0
   215d0: e3a02010     	mov	r2, #16
   215d4: ebffc8f5     	bl	0x139b0 <substr>        @ imm = #-0xdc2c
   215d8: e1a03000     	mov	r3, r0
   215dc: e1a00003     	mov	r0, r3
   215e0: ebffff6c     	bl	0x21398 <cue_escape>    @ imm = #-0x250
   215e4: e1a03000     	mov	r3, r0
   215e8: e51b0028     	ldr	r0, [r11, #-0x28]
   215ec: e1a01004     	mov	r1, r4
   215f0: e1a02003     	mov	r2, r3
   215f4: ebffac12     	bl	0xc644 <fprintf@plt>    @ imm = #-0x14fb8
   215f8: e59f4694     	ldr	r4, [pc, #0x694]        @ 0x21c94 <write_cue_sheet+0x898>
   215fc: e51b0034     	ldr	r0, [r11, #-0x34]
   21600: ebffff64     	bl	0x21398 <cue_escape>    @ imm = #-0x270
   21604: e1a03000     	mov	r3, r0
   21608: e51b0028     	ldr	r0, [r11, #-0x28]
   2160c: e1a01004     	mov	r1, r4
   21610: e1a02003     	mov	r2, r3
   21614: ebffac0a     	bl	0xc644 <fprintf@plt>    @ imm = #-0x14fd8
   21618: e51b2038     	ldr	r2, [r11, #-0x38]
   2161c: e51b1030     	ldr	r1, [r11, #-0x30]
   21620: e3a03060     	mov	r3, #96
   21624: e59f066c     	ldr	r0, [pc, #0x66c]        @ 0x21c98 <write_cue_sheet+0x89c>
   21628: e0020290     	mul	r2, r0, r2
   2162c: e0812002     	add	r2, r1, r2
   21630: e0823003     	add	r3, r2, r3
   21634: e5933000     	ldr	r3, [r3]
   21638: e5d33045     	ldrb	r3, [r3, #0x45]
   2163c: e50b3020     	str	r3, [r11, #-0x20]
   21640: e3a02000     	mov	r2, #0
   21644: e3a03000     	mov	r3, #0
   21648: e14b21fc     	strd	r2, r3, [r11, #-28]
   2164c: e3a03000     	mov	r3, #0
   21650: e50b3024     	str	r3, [r11, #-0x24]
   21654: ea00017c     	b	0x21c4c <write_cue_sheet+0x850> @ imm = #0x5f0
   21658: e51b2038     	ldr	r2, [r11, #-0x38]
   2165c: e51b1030     	ldr	r1, [r11, #-0x30]
   21660: e3a03068     	mov	r3, #104
   21664: e59f062c     	ldr	r0, [pc, #0x62c]        @ 0x21c98 <write_cue_sheet+0x89c>
   21668: e0020290     	mul	r2, r0, r2
   2166c: e0812002     	add	r2, r1, r2
   21670: e0823003     	add	r3, r2, r3
   21674: e5933000     	ldr	r3, [r3]
   21678: e2832008     	add	r2, r3, #8
   2167c: e51b3024     	ldr	r3, [r11, #-0x24]
   21680: e1a03103     	lsl	r3, r3, #2
   21684: e0823003     	add	r3, r2, r3
   21688: e50b3014     	str	r3, [r11, #-0x14]
   2168c: e59f2608     	ldr	r2, [pc, #0x608]        @ 0x21c9c <write_cue_sheet+0x8a0>
   21690: e51b3024     	ldr	r3, [r11, #-0x24]
   21694: e2833001     	add	r3, r3, #1
   21698: e51b0028     	ldr	r0, [r11, #-0x28]
   2169c: e1a01002     	mov	r1, r2
   216a0: e1a02003     	mov	r2, r3
   216a4: ebffabe6     	bl	0xc644 <fprintf@plt>    @ imm = #-0x15068
   216a8: e51bc038     	ldr	r12, [r11, #-0x38]
   216ac: e51b3024     	ldr	r3, [r11, #-0x24]
   216b0: e51b0030     	ldr	r0, [r11, #-0x30]
   216b4: e3a01070     	mov	r1, #112
   216b8: e1a02183     	lsl	r2, r3, #3
   216bc: e1a03182     	lsl	r3, r2, #3
   216c0: e0623003     	rsb	r3, r2, r3
   216c4: e59f25cc     	ldr	r2, [pc, #0x5cc]        @ 0x21c98 <write_cue_sheet+0x89c>
   216c8: e0020c92     	mul	r2, r2, r12
   216cc: e0833002     	add	r3, r3, r2
   216d0: e0803003     	add	r3, r0, r3
   216d4: e0833001     	add	r3, r3, r1
   216d8: e5933000     	ldr	r3, [r3]
   216dc: e3530000     	cmp	r3, #0
   216e0: 0a000014     	beq	0x21738 <write_cue_sheet+0x33c> @ imm = #0x50
   216e4: e59f45b4     	ldr	r4, [pc, #0x5b4]        @ 0x21ca0 <write_cue_sheet+0x8a4>
   216e8: e51bc038     	ldr	r12, [r11, #-0x38]
   216ec: e51b3024     	ldr	r3, [r11, #-0x24]
   216f0: e51b0030     	ldr	r0, [r11, #-0x30]
   216f4: e3a01070     	mov	r1, #112
   216f8: e1a02183     	lsl	r2, r3, #3
   216fc: e1a03182     	lsl	r3, r2, #3
   21700: e0623003     	rsb	r3, r2, r3
   21704: e59f258c     	ldr	r2, [pc, #0x58c]        @ 0x21c98 <write_cue_sheet+0x89c>
   21708: e0020c92     	mul	r2, r2, r12
   2170c: e0833002     	add	r3, r3, r2
   21710: e0803003     	add	r3, r0, r3
   21714: e0833001     	add	r3, r3, r1
   21718: e5933000     	ldr	r3, [r3]
   2171c: e1a00003     	mov	r0, r3
   21720: ebffff1c     	bl	0x21398 <cue_escape>    @ imm = #-0x390
   21724: e1a03000     	mov	r3, r0
   21728: e51b0028     	ldr	r0, [r11, #-0x28]
   2172c: e1a01004     	mov	r1, r4
   21730: e1a02003     	mov	r2, r3
   21734: ebffabc2     	bl	0xc644 <fprintf@plt>    @ imm = #-0x150f8
   21738: e51bc038     	ldr	r12, [r11, #-0x38]
   2173c: e51b3024     	ldr	r3, [r11, #-0x24]
   21740: e51b0030     	ldr	r0, [r11, #-0x30]
   21744: e3a01074     	mov	r1, #116
   21748: e1a02183     	lsl	r2, r3, #3
   2174c: e1a03182     	lsl	r3, r2, #3
   21750: e0623003     	rsb	r3, r2, r3
   21754: e59f253c     	ldr	r2, [pc, #0x53c]        @ 0x21c98 <write_cue_sheet+0x89c>
   21758: e0020c92     	mul	r2, r2, r12
   2175c: e0833002     	add	r3, r3, r2
   21760: e0803003     	add	r3, r0, r3
   21764: e0833001     	add	r3, r3, r1
   21768: e5933000     	ldr	r3, [r3]
   2176c: e3530000     	cmp	r3, #0
   21770: 0a000014     	beq	0x217c8 <write_cue_sheet+0x3cc> @ imm = #0x50
   21774: e59f4528     	ldr	r4, [pc, #0x528]        @ 0x21ca4 <write_cue_sheet+0x8a8>
   21778: e51bc038     	ldr	r12, [r11, #-0x38]
   2177c: e51b3024     	ldr	r3, [r11, #-0x24]
   21780: e51b0030     	ldr	r0, [r11, #-0x30]
   21784: e3a01074     	mov	r1, #116
   21788: e1a02183     	lsl	r2, r3, #3
   2178c: e1a03182     	lsl	r3, r2, #3
   21790: e0623003     	rsb	r3, r2, r3
   21794: e59f24fc     	ldr	r2, [pc, #0x4fc]        @ 0x21c98 <write_cue_sheet+0x89c>
   21798: e0020c92     	mul	r2, r2, r12
   2179c: e0833002     	add	r3, r3, r2
   217a0: e0803003     	add	r3, r0, r3
   217a4: e0833001     	add	r3, r3, r1
   217a8: e5933000     	ldr	r3, [r3]
   217ac: e1a00003     	mov	r0, r3
   217b0: ebfffef8     	bl	0x21398 <cue_escape>    @ imm = #-0x420
   217b4: e1a03000     	mov	r3, r0
   217b8: e51b0028     	ldr	r0, [r11, #-0x28]
   217bc: e1a01004     	mov	r1, r4
   217c0: e1a02003     	mov	r2, r3
   217c4: ebffab9e     	bl	0xc644 <fprintf@plt>    @ imm = #-0x15188
   217c8: e51b2038     	ldr	r2, [r11, #-0x38]
   217cc: e51b1030     	ldr	r1, [r11, #-0x30]
   217d0: e59f34d0     	ldr	r3, [pc, #0x4d0]        @ 0x21ca8 <write_cue_sheet+0x8ac>
   217d4: e59f04bc     	ldr	r0, [pc, #0x4bc]        @ 0x21c98 <write_cue_sheet+0x89c>
   217d8: e0020290     	mul	r2, r0, r2
   217dc: e0812002     	add	r2, r1, r2
   217e0: e0823003     	add	r3, r2, r3
   217e4: e5930000     	ldr	r0, [r3]
   217e8: e51b2024     	ldr	r2, [r11, #-0x24]
   217ec: e3a01008     	mov	r1, #8
   217f0: e1a03002     	mov	r3, r2
   217f4: e1a03083     	lsl	r3, r3, #1
   217f8: e0833002     	add	r3, r3, r2
   217fc: e1a03103     	lsl	r3, r3, #2
   21800: e0803003     	add	r3, r0, r3
   21804: e0833001     	add	r3, r3, r1
   21808: e5d33000     	ldrb	r3, [r3]
   2180c: e3530000     	cmp	r3, #0
   21810: 0a00001b     	beq	0x21884 <write_cue_sheet+0x488> @ imm = #0x6c
   21814: e59f4490     	ldr	r4, [pc, #0x490]        @ 0x21cac <write_cue_sheet+0x8b0>
   21818: e51b2038     	ldr	r2, [r11, #-0x38]
   2181c: e51b1030     	ldr	r1, [r11, #-0x30]
   21820: e59f3480     	ldr	r3, [pc, #0x480]        @ 0x21ca8 <write_cue_sheet+0x8ac>
   21824: e59f046c     	ldr	r0, [pc, #0x46c]        @ 0x21c98 <write_cue_sheet+0x89c>
   21828: e0020290     	mul	r2, r0, r2
   2182c: e0812002     	add	r2, r1, r2
   21830: e0823003     	add	r3, r2, r3
   21834: e5931000     	ldr	r1, [r3]
   21838: e51b2024     	ldr	r2, [r11, #-0x24]
   2183c: e1a03002     	mov	r3, r2
   21840: e1a03083     	lsl	r3, r3, #1
   21844: e0833002     	add	r3, r3, r2
   21848: e1a03103     	lsl	r3, r3, #2
   2184c: e2833008     	add	r3, r3, #8
   21850: e0813003     	add	r3, r1, r3
   21854: e1a00003     	mov	r0, r3
   21858: e3a01000     	mov	r1, #0
   2185c: e3a0200c     	mov	r2, #12
   21860: ebffc852     	bl	0x139b0 <substr>        @ imm = #-0xdeb8
   21864: e1a03000     	mov	r3, r0
   21868: e1a00003     	mov	r0, r3
   2186c: ebfffec9     	bl	0x21398 <cue_escape>    @ imm = #-0x4dc
   21870: e1a03000     	mov	r3, r0
   21874: e51b0028     	ldr	r0, [r11, #-0x28]
   21878: e1a01004     	mov	r1, r4
   2187c: e1a02003     	mov	r2, r3
   21880: ebffab6f     	bl	0xc644 <fprintf@plt>    @ imm = #-0x15244
   21884: e51b2038     	ldr	r2, [r11, #-0x38]
   21888: e51b1030     	ldr	r1, [r11, #-0x30]
   2188c: e3a03068     	mov	r3, #104
   21890: e59f0400     	ldr	r0, [pc, #0x400]        @ 0x21c98 <write_cue_sheet+0x89c>
   21894: e0020290     	mul	r2, r0, r2
   21898: e0812002     	add	r2, r1, r2
   2189c: e0823003     	add	r3, r2, r3
   218a0: e5933000     	ldr	r3, [r3]
   218a4: e2832008     	add	r2, r3, #8
   218a8: e51b3024     	ldr	r3, [r11, #-0x24]
   218ac: e1a03103     	lsl	r3, r3, #2
   218b0: e0823003     	add	r3, r2, r3
   218b4: e5d33000     	ldrb	r3, [r3]
   218b8: e59f23f0     	ldr	r2, [pc, #0x3f0]        @ 0x21cb0 <write_cue_sheet+0x8b4>
   218bc: e0010392     	mul	r1, r2, r3
   218c0: e51b2038     	ldr	r2, [r11, #-0x38]
   218c4: e51b0030     	ldr	r0, [r11, #-0x30]
   218c8: e3a03068     	mov	r3, #104
   218cc: e59fc3c4     	ldr	r12, [pc, #0x3c4]       @ 0x21c98 <write_cue_sheet+0x89c>
   218d0: e002029c     	mul	r2, r12, r2
   218d4: e0802002     	add	r2, r0, r2
   218d8: e0823003     	add	r3, r2, r3
   218dc: e5933000     	ldr	r3, [r3]
   218e0: e2832008     	add	r2, r3, #8
   218e4: e51b3024     	ldr	r3, [r11, #-0x24]
   218e8: e1a03103     	lsl	r3, r3, #2
   218ec: e0823003     	add	r3, r2, r3
   218f0: e5d33001     	ldrb	r3, [r3, #0x1]
   218f4: e1a02003     	mov	r2, r3
   218f8: e1a03002     	mov	r3, r2
   218fc: e1a03103     	lsl	r3, r3, #2
   21900: e0833002     	add	r3, r3, r2
   21904: e1a02203     	lsl	r2, r3, #4
   21908: e0633002     	rsb	r3, r3, r2
   2190c: e0812003     	add	r2, r1, r3
   21910: e51b1038     	ldr	r1, [r11, #-0x38]
   21914: e51b0030     	ldr	r0, [r11, #-0x30]
   21918: e3a03068     	mov	r3, #104
   2191c: e59fc374     	ldr	r12, [pc, #0x374]       @ 0x21c98 <write_cue_sheet+0x89c>
   21920: e001019c     	mul	r1, r12, r1
   21924: e0801001     	add	r1, r0, r1
   21928: e0813003     	add	r3, r1, r3
   2192c: e5933000     	ldr	r3, [r3]
   21930: e2831008     	add	r1, r3, #8
   21934: e51b3024     	ldr	r3, [r11, #-0x24]
   21938: e1a03103     	lsl	r3, r3, #2
   2193c: e0813003     	add	r3, r1, r3
   21940: e5d33002     	ldrb	r3, [r3, #0x2]
   21944: e0823003     	add	r3, r2, r3
   21948: e1a02003     	mov	r2, r3
   2194c: e1a03fc2     	asr	r3, r2, #31
   21950: e51b1018     	ldr	r1, [r11, #-0x18]
   21954: e1510003     	cmp	r1, r3
   21958: 3a000008     	blo	0x21980 <write_cue_sheet+0x584> @ imm = #0x20
   2195c: e51b1018     	ldr	r1, [r11, #-0x18]
   21960: e1510003     	cmp	r1, r3
   21964: 1a000041     	bne	0x21a70 <write_cue_sheet+0x674> @ imm = #0x104
   21968: e51b101c     	ldr	r1, [r11, #-0x1c]
   2196c: e1510002     	cmp	r1, r2
   21970: 3a000002     	blo	0x21980 <write_cue_sheet+0x584> @ imm = #0x8
   21974: e51b101c     	ldr	r1, [r11, #-0x1c]
   21978: e1510002     	cmp	r1, r2
   2197c: ea00003b     	b	0x21a70 <write_cue_sheet+0x674> @ imm = #0xec
   21980: e14b21dc     	ldrd	r2, r3, [r11, #-28]
   21984: e1a00002     	mov	r0, r2
   21988: e1a01003     	mov	r1, r3
   2198c: e3a0204b     	mov	r2, #75
   21990: e3a03000     	mov	r3, #0
   21994: eb003d7f     	bl	0x30f98 <__aeabi_uldivmod> @ imm = #0xf5fc
   21998: e1a02000     	mov	r2, r0
   2199c: e1a03001     	mov	r3, r1
   219a0: e1a03002     	mov	r3, r2
   219a4: e50b3010     	str	r3, [r11, #-0x10]
   219a8: e59f4304     	ldr	r4, [pc, #0x304]        @ 0x21cb4 <write_cue_sheet+0x8b8>
   219ac: e51b3010     	ldr	r3, [r11, #-0x10]
   219b0: e59f2300     	ldr	r2, [pc, #0x300]        @ 0x21cb8 <write_cue_sheet+0x8bc>
   219b4: e0c21392     	smull	r1, r2, r2, r3
   219b8: e0822003     	add	r2, r2, r3
   219bc: e1a022c2     	asr	r2, r2, #5
   219c0: e1a03fc3     	asr	r3, r3, #31
   219c4: e063e002     	rsb	lr, r3, r2
   219c8: e51b3010     	ldr	r3, [r11, #-0x10]
   219cc: e59f22e4     	ldr	r2, [pc, #0x2e4]        @ 0x21cb8 <write_cue_sheet+0x8bc>
   219d0: e0c21392     	smull	r1, r2, r2, r3
   219d4: e0822003     	add	r2, r2, r3
   219d8: e1a012c2     	asr	r1, r2, #5
   219dc: e1a02fc3     	asr	r2, r3, #31
   219e0: e062c001     	rsb	r12, r2, r1
   219e4: e1a0200c     	mov	r2, r12
   219e8: e1a01102     	lsl	r1, r2, #2
   219ec: e1a02201     	lsl	r2, r1, #4
   219f0: e0612002     	rsb	r2, r1, r2
   219f4: e062c003     	rsb	r12, r2, r3
   219f8: e51b101c     	ldr	r1, [r11, #-0x1c]
   219fc: e59f32b8     	ldr	r3, [pc, #0x2b8]        @ 0x21cbc <write_cue_sheet+0x8c0>
   21a00: e0c32193     	smull	r2, r3, r3, r1
   21a04: e1a021c3     	asr	r2, r3, #3
   21a08: e1a03fc1     	asr	r3, r1, #31
   21a0c: e0632002     	rsb	r2, r3, r2
   21a10: e1a03002     	mov	r3, r2
   21a14: e1a03103     	lsl	r3, r3, #2
   21a18: e0833002     	add	r3, r3, r2
   21a1c: e1a02203     	lsl	r2, r3, #4
   21a20: e0632002     	rsb	r2, r3, r2
   21a24: e0622001     	rsb	r2, r2, r1
   21a28: e58d2000     	str	r2, [sp]
   21a2c: e51b0028     	ldr	r0, [r11, #-0x28]
   21a30: e1a01004     	mov	r1, r4
   21a34: e1a0200e     	mov	r2, lr
   21a38: e1a0300c     	mov	r3, r12
   21a3c: ebffab00     	bl	0xc644 <fprintf@plt>    @ imm = #-0x15400
   21a40: e59f1278     	ldr	r1, [pc, #0x278]        @ 0x21cc0 <write_cue_sheet+0x8c4>
   21a44: e51b3014     	ldr	r3, [r11, #-0x14]
   21a48: e5d33000     	ldrb	r3, [r3]
   21a4c: e1a02003     	mov	r2, r3
   21a50: e51b3014     	ldr	r3, [r11, #-0x14]
   21a54: e5d33001     	ldrb	r3, [r3, #0x1]
   21a58: e51b0014     	ldr	r0, [r11, #-0x14]
   21a5c: e5d00002     	ldrb	r0, [r0, #0x2]
   21a60: e58d0000     	str	r0, [sp]
   21a64: e51b0028     	ldr	r0, [r11, #-0x28]
   21a68: ebffaaf5     	bl	0xc644 <fprintf@plt>    @ imm = #-0x1542c
   21a6c: ea00000a     	b	0x21a9c <write_cue_sheet+0x6a0> @ imm = #0x28
   21a70: e59f1248     	ldr	r1, [pc, #0x248]        @ 0x21cc0 <write_cue_sheet+0x8c4>
   21a74: e51b3014     	ldr	r3, [r11, #-0x14]
   21a78: e5d33000     	ldrb	r3, [r3]
   21a7c: e1a02003     	mov	r2, r3
   21a80: e51b3014     	ldr	r3, [r11, #-0x14]
   21a84: e5d33001     	ldrb	r3, [r3, #0x1]
   21a88: e51b0014     	ldr	r0, [r11, #-0x14]
   21a8c: e5d00002     	ldrb	r0, [r0, #0x2]
   21a90: e58d0000     	str	r0, [sp]
   21a94: e51b0028     	ldr	r0, [r11, #-0x28]
   21a98: ebffaae9     	bl	0xc644 <fprintf@plt>    @ imm = #-0x1545c
   21a9c: e51b2038     	ldr	r2, [r11, #-0x38]
   21aa0: e51b1030     	ldr	r1, [r11, #-0x30]
   21aa4: e3a03068     	mov	r3, #104
   21aa8: e59f01e8     	ldr	r0, [pc, #0x1e8]        @ 0x21c98 <write_cue_sheet+0x89c>
   21aac: e0020290     	mul	r2, r0, r2
   21ab0: e0812002     	add	r2, r1, r2
   21ab4: e0823003     	add	r3, r2, r3
   21ab8: e5933000     	ldr	r3, [r3]
   21abc: e2832008     	add	r2, r3, #8
   21ac0: e51b3024     	ldr	r3, [r11, #-0x24]
   21ac4: e1a03103     	lsl	r3, r3, #2
   21ac8: e0823003     	add	r3, r2, r3
   21acc: e5d33000     	ldrb	r3, [r3]
   21ad0: e59f21d8     	ldr	r2, [pc, #0x1d8]        @ 0x21cb0 <write_cue_sheet+0x8b4>
   21ad4: e0010392     	mul	r1, r2, r3
   21ad8: e51b2038     	ldr	r2, [r11, #-0x38]
   21adc: e51b0030     	ldr	r0, [r11, #-0x30]
   21ae0: e3a03068     	mov	r3, #104
   21ae4: e59fc1ac     	ldr	r12, [pc, #0x1ac]       @ 0x21c98 <write_cue_sheet+0x89c>
   21ae8: e002029c     	mul	r2, r12, r2
   21aec: e0802002     	add	r2, r0, r2
   21af0: e0823003     	add	r3, r2, r3
   21af4: e5933000     	ldr	r3, [r3]
   21af8: e2832008     	add	r2, r3, #8
   21afc: e51b3024     	ldr	r3, [r11, #-0x24]
   21b00: e1a03103     	lsl	r3, r3, #2
   21b04: e0823003     	add	r3, r2, r3
   21b08: e5d33001     	ldrb	r3, [r3, #0x1]
   21b0c: e1a02003     	mov	r2, r3
   21b10: e1a03002     	mov	r3, r2
   21b14: e1a03103     	lsl	r3, r3, #2
   21b18: e0833002     	add	r3, r3, r2
   21b1c: e1a02203     	lsl	r2, r3, #4
   21b20: e0633002     	rsb	r3, r3, r2
   21b24: e0812003     	add	r2, r1, r3
   21b28: e51b1038     	ldr	r1, [r11, #-0x38]
   21b2c: e51b0030     	ldr	r0, [r11, #-0x30]
   21b30: e3a03068     	mov	r3, #104
   21b34: e59fc15c     	ldr	r12, [pc, #0x15c]       @ 0x21c98 <write_cue_sheet+0x89c>
   21b38: e001019c     	mul	r1, r12, r1
   21b3c: e0801001     	add	r1, r0, r1
   21b40: e0813003     	add	r3, r1, r3
   21b44: e5933000     	ldr	r3, [r3]
   21b48: e2831008     	add	r1, r3, #8
   21b4c: e51b3024     	ldr	r3, [r11, #-0x24]
   21b50: e1a03103     	lsl	r3, r3, #2
   21b54: e0813003     	add	r3, r1, r3
   21b58: e5d33002     	ldrb	r3, [r3, #0x2]
   21b5c: e0821003     	add	r1, r2, r3
   21b60: e51b2038     	ldr	r2, [r11, #-0x38]
   21b64: e51b0030     	ldr	r0, [r11, #-0x30]
   21b68: e3a03068     	mov	r3, #104
   21b6c: e59fc124     	ldr	r12, [pc, #0x124]       @ 0x21c98 <write_cue_sheet+0x89c>
   21b70: e002029c     	mul	r2, r12, r2
   21b74: e0802002     	add	r2, r0, r2
   21b78: e0823003     	add	r3, r2, r3
   21b7c: e5933000     	ldr	r3, [r3]
   21b80: e2833b01     	add	r3, r3, #1024
   21b84: e2833004     	add	r3, r3, #4
   21b88: e51b2024     	ldr	r2, [r11, #-0x24]
   21b8c: e1a02102     	lsl	r2, r2, #2
   21b90: e0833002     	add	r3, r3, r2
   21b94: e5d33000     	ldrb	r3, [r3]
   21b98: e59f2110     	ldr	r2, [pc, #0x110]        @ 0x21cb0 <write_cue_sheet+0x8b4>
   21b9c: e0000392     	mul	r0, r2, r3
   21ba0: e51b2038     	ldr	r2, [r11, #-0x38]
   21ba4: e51bc030     	ldr	r12, [r11, #-0x30]
   21ba8: e3a03068     	mov	r3, #104
   21bac: e59fe0e4     	ldr	lr, [pc, #0xe4]         @ 0x21c98 <write_cue_sheet+0x89c>
   21bb0: e002029e     	mul	r2, lr, r2
   21bb4: e08c2002     	add	r2, r12, r2
   21bb8: e0823003     	add	r3, r2, r3
   21bbc: e5933000     	ldr	r3, [r3]
   21bc0: e2833b01     	add	r3, r3, #1024
   21bc4: e2833004     	add	r3, r3, #4
   21bc8: e51b2024     	ldr	r2, [r11, #-0x24]
   21bcc: e1a02102     	lsl	r2, r2, #2
   21bd0: e0833002     	add	r3, r3, r2
   21bd4: e5d33001     	ldrb	r3, [r3, #0x1]
   21bd8: e1a02003     	mov	r2, r3
   21bdc: e1a03002     	mov	r3, r2
   21be0: e1a03103     	lsl	r3, r3, #2
   21be4: e0833002     	add	r3, r3, r2
   21be8: e1a02203     	lsl	r2, r3, #4
   21bec: e0633002     	rsb	r3, r3, r2
   21bf0: e0802003     	add	r2, r0, r3
   21bf4: e51b0038     	ldr	r0, [r11, #-0x38]
   21bf8: e51bc030     	ldr	r12, [r11, #-0x30]
   21bfc: e3a03068     	mov	r3, #104
   21c00: e59fe090     	ldr	lr, [pc, #0x90]         @ 0x21c98 <write_cue_sheet+0x89c>
   21c04: e000009e     	mul	r0, lr, r0
   21c08: e08c0000     	add	r0, r12, r0
   21c0c: e0803003     	add	r3, r0, r3
   21c10: e5933000     	ldr	r3, [r3]
   21c14: e2833b01     	add	r3, r3, #1024
   21c18: e2833004     	add	r3, r3, #4
   21c1c: e51b0024     	ldr	r0, [r11, #-0x24]
   21c20: e1a00100     	lsl	r0, r0, #2
   21c24: e0833000     	add	r3, r3, r0
   21c28: e5d33002     	ldrb	r3, [r3, #0x2]
   21c2c: e0823003     	add	r3, r2, r3
   21c30: e0813003     	add	r3, r1, r3
   21c34: e1a02003     	mov	r2, r3
   21c38: e1a03fc2     	asr	r3, r2, #31
   21c3c: e14b21fc     	strd	r2, r3, [r11, #-28]
   21c40: e51b3024     	ldr	r3, [r11, #-0x24]
   21c44: e2833001     	add	r3, r3, #1
   21c48: e50b3024     	str	r3, [r11, #-0x24]
   21c4c: e51b2024     	ldr	r2, [r11, #-0x24]
   21c50: e51b3020     	ldr	r3, [r11, #-0x20]
   21c54: e1520003     	cmp	r2, r3
   21c58: bafffe7e     	blt	0x21658 <write_cue_sheet+0x25c> @ imm = #-0x608
   21c5c: e51b0028     	ldr	r0, [r11, #-0x28]
   21c60: ebffa99f     	bl	0xc2e4 <fclose@plt>     @ imm = #-0x15984
   21c64: e3a03000     	mov	r3, #0
   21c68: e1a00003     	mov	r0, r3
   21c6c: e24bd008     	sub	sp, r11, #8
   21c70: e8bd8810     	pop	{r4, r11, pc}
   21c74: 10 53 03 00  	.word	0x00035310
   21c78: 14 53 03 00  	.word	0x00035314
   21c7c: 48 53 03 00  	.word	0x00035348
   21c80: 58 ef 03 00  	.word	0x0003ef58
   21c84: 58 53 03 00  	.word	0x00035358
   21c88: 74 53 03 00  	.word	0x00035374
   21c8c: 84 53 03 00  	.word	0x00035384
   21c90: 90 53 03 00  	.word	0x00035390
   21c94: 9c 53 03 00  	.word	0x0003539c
   21c98: f0 37 00 00  	.word	0x000037f0
   21c9c: ac 53 03 00  	.word	0x000353ac
   21ca0: c0 53 03 00  	.word	0x000353c0
   21ca4: d4 53 03 00  	.word	0x000353d4
   21ca8: 38 38 00 00  	.word	0x00003838
   21cac: ec 53 03 00  	.word	0x000353ec
   21cb0: 94 11 00 00  	.word	0x00001194
   21cb4: fc 53 03 00  	.word	0x000353fc
   21cb8: 89 88 88 88  	.word	0x88888889
   21cbc: b5 81 4e 1b  	.word	0x1b4e81b5
   21cc0: 1c 54 03 00  	.word	0x0003541c

