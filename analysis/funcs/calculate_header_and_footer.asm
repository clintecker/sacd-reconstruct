0002303c <calculate_header_and_footer>:
   2303c: e92d4810     	push	{r4, r11, lr}
   23040: e28db008     	add	r11, sp, #8
   23044: e24dde46     	sub	sp, sp, #1120
   23048: e24dd004     	sub	sp, sp, #4
   2304c: e50b0460     	str	r0, [r11, #-0x460]
   23050: e51b3460     	ldr	r3, [r11, #-0x460]
   23054: e5933168     	ldr	r3, [r3, #0x168]
   23058: e50b3104     	str	r3, [r11, #-0x104]
   2305c: e51b3460     	ldr	r3, [r11, #-0x460]
   23060: e593305c     	ldr	r3, [r3, #0x5c]
   23064: e50b3100     	str	r3, [r11, #-0x100]
   23068: e51b3100     	ldr	r3, [r11, #-0x100]
   2306c: e5933000     	ldr	r3, [r3]
   23070: e3530000     	cmp	r3, #0
   23074: 1a000006     	bne	0x23094 <calculate_header_and_footer+0x58> @ imm = #0x18
   23078: e3a00901     	mov	r0, #16384
   2307c: e3a01001     	mov	r1, #1
   23080: ebffa4b5     	bl	0xc35c <calloc@plt>     @ imm = #-0x16d2c
   23084: e1a03000     	mov	r3, r0
   23088: e1a02003     	mov	r2, r3
   2308c: e51b3100     	ldr	r3, [r11, #-0x100]
   23090: e5832000     	str	r2, [r3]
   23094: e51b3100     	ldr	r3, [r11, #-0x100]
   23098: e5933008     	ldr	r3, [r3, #0x8]
   2309c: e3530000     	cmp	r3, #0
   230a0: 1a000006     	bne	0x230c0 <calculate_header_and_footer+0x84> @ imm = #0x18
   230a4: e3a00901     	mov	r0, #16384
   230a8: e3a01001     	mov	r1, #1
   230ac: ebffa4aa     	bl	0xc35c <calloc@plt>     @ imm = #-0x16d58
   230b0: e1a03000     	mov	r3, r0
   230b4: e1a02003     	mov	r2, r3
   230b8: e51b3100     	ldr	r3, [r11, #-0x100]
   230bc: e5832008     	str	r2, [r3, #0x8]
   230c0: e51b3100     	ldr	r3, [r11, #-0x100]
   230c4: e5933000     	ldr	r3, [r3]
   230c8: e50b310c     	str	r3, [r11, #-0x10c]
   230cc: e51b3100     	ldr	r3, [r11, #-0x100]
   230d0: e5933000     	ldr	r3, [r3]
   230d4: e50b3114     	str	r3, [r11, #-0x114]
   230d8: e51b3114     	ldr	r3, [r11, #-0x114]
   230dc: e3a02000     	mov	r2, #0
   230e0: e3822046     	orr	r2, r2, #70
   230e4: e5c32000     	strb	r2, [r3]
   230e8: e3a02000     	mov	r2, #0
   230ec: e3822052     	orr	r2, r2, #82
   230f0: e5c32001     	strb	r2, [r3, #0x1]
   230f4: e3a02000     	mov	r2, #0
   230f8: e382204d     	orr	r2, r2, #77
   230fc: e5c32002     	strb	r2, [r3, #0x2]
   23100: e3a02000     	mov	r2, #0
   23104: e3822038     	orr	r2, r2, #56
   23108: e5c32003     	strb	r2, [r3, #0x3]
   2310c: e51b3114     	ldr	r3, [r11, #-0x114]
   23110: e3a02000     	mov	r2, #0
   23114: e3822044     	orr	r2, r2, #68
   23118: e5c3200c     	strb	r2, [r3, #0xc]
   2311c: e3a02000     	mov	r2, #0
   23120: e3822053     	orr	r2, r2, #83
   23124: e5c3200d     	strb	r2, [r3, #0xd]
   23128: e3a02000     	mov	r2, #0
   2312c: e3822044     	orr	r2, r2, #68
   23130: e5c3200e     	strb	r2, [r3, #0xe]
   23134: e3a02000     	mov	r2, #0
   23138: e3822020     	orr	r2, r2, #32
   2313c: e5c3200f     	strb	r2, [r3, #0xf]
   23140: e51b3100     	ldr	r3, [r11, #-0x100]
   23144: e5933000     	ldr	r3, [r3]
   23148: e2833010     	add	r3, r3, #16
   2314c: e50b310c     	str	r3, [r11, #-0x10c]
   23150: e51b310c     	ldr	r3, [r11, #-0x10c]
   23154: e50b30fc     	str	r3, [r11, #-0xfc]
   23158: e51b30fc     	ldr	r3, [r11, #-0xfc]
   2315c: e3a02000     	mov	r2, #0
   23160: e3822046     	orr	r2, r2, #70
   23164: e5c32000     	strb	r2, [r3]
   23168: e3a02000     	mov	r2, #0
   2316c: e3822056     	orr	r2, r2, #86
   23170: e5c32001     	strb	r2, [r3, #0x1]
   23174: e3a02000     	mov	r2, #0
   23178: e3822045     	orr	r2, r2, #69
   2317c: e5c32002     	strb	r2, [r3, #0x2]
   23180: e3a02000     	mov	r2, #0
   23184: e3822052     	orr	r2, r2, #82
   23188: e5c32003     	strb	r2, [r3, #0x3]
   2318c: e59f1b4c     	ldr	r1, [pc, #0xb4c]        @ 0x23ce0 <calculate_header_and_footer+0xca4>
   23190: e3a02000     	mov	r2, #0
   23194: e3a03301     	mov	r3, #67108864
   23198: e24b000c     	sub	r0, r11, #12
   2319c: e18020f1     	strd	r2, r3, [r0, r1]
   231a0: e59f3b38     	ldr	r3, [pc, #0xb38]        @ 0x23ce0 <calculate_header_and_footer+0xca4>
   231a4: e24b100c     	sub	r1, r11, #12
   231a8: e18320d1     	ldrd	r2, r3, [r3, r1]
   231ac: e51b10fc     	ldr	r1, [r11, #-0xfc]
   231b0: e20200ff     	and	r0, r2, #255
   231b4: e3a0c000     	mov	r12, #0
   231b8: e18c0000     	orr	r0, r12, r0
   231bc: e5c10004     	strb	r0, [r1, #0x4]
   231c0: e1a00422     	lsr	r0, r2, #8
   231c4: e20000ff     	and	r0, r0, #255
   231c8: e3a0c000     	mov	r12, #0
   231cc: e18c0000     	orr	r0, r12, r0
   231d0: e5c10005     	strb	r0, [r1, #0x5]
   231d4: e1a00822     	lsr	r0, r2, #16
   231d8: e20000ff     	and	r0, r0, #255
   231dc: e3a0c000     	mov	r12, #0
   231e0: e18c0000     	orr	r0, r12, r0
   231e4: e5c10006     	strb	r0, [r1, #0x6]
   231e8: e1a00c22     	lsr	r0, r2, #24
   231ec: e3a0c000     	mov	r12, #0
   231f0: e18c0000     	orr	r0, r12, r0
   231f4: e5c10007     	strb	r0, [r1, #0x7]
   231f8: e20300ff     	and	r0, r3, #255
   231fc: e3a0c000     	mov	r12, #0
   23200: e18c0000     	orr	r0, r12, r0
   23204: e5c10008     	strb	r0, [r1, #0x8]
   23208: e1a00423     	lsr	r0, r3, #8
   2320c: e20000ff     	and	r0, r0, #255
   23210: e3a0c000     	mov	r12, #0
   23214: e18c0000     	orr	r0, r12, r0
   23218: e5c10009     	strb	r0, [r1, #0x9]
   2321c: e1a00823     	lsr	r0, r3, #16
   23220: e20000ff     	and	r0, r0, #255
   23224: e3a0c000     	mov	r12, #0
   23228: e18c0000     	orr	r0, r12, r0
   2322c: e5c1000a     	strb	r0, [r1, #0xa]
   23230: e1a03c23     	lsr	r3, r3, #24
   23234: e3a02000     	mov	r2, #0
   23238: e1823003     	orr	r3, r2, r3
   2323c: e5c1300b     	strb	r3, [r1, #0xb]
   23240: e59f4a9c     	ldr	r4, [pc, #0xa9c]        @ 0x23ce4 <calculate_header_and_footer+0xca8>
   23244: e1a02c24     	lsr	r2, r4, #24
   23248: e20438ff     	and	r3, r4, #16711680
   2324c: e1a03423     	lsr	r3, r3, #8
   23250: e1822003     	orr	r2, r2, r3
   23254: e2043cff     	and	r3, r4, #65280
   23258: e1a03403     	lsl	r3, r3, #8
   2325c: e1822003     	orr	r2, r2, r3
   23260: e1a03c04     	lsl	r3, r4, #24
   23264: e1822003     	orr	r2, r2, r3
   23268: e51b30fc     	ldr	r3, [r11, #-0xfc]
   2326c: e20210ff     	and	r1, r2, #255
   23270: e3a00000     	mov	r0, #0
   23274: e1801001     	orr	r1, r0, r1
   23278: e5c3100c     	strb	r1, [r3, #0xc]
   2327c: e1a01422     	lsr	r1, r2, #8
   23280: e20110ff     	and	r1, r1, #255
   23284: e3a00000     	mov	r0, #0
   23288: e1801001     	orr	r1, r0, r1
   2328c: e5c3100d     	strb	r1, [r3, #0xd]
   23290: e1a01822     	lsr	r1, r2, #16
   23294: e20110ff     	and	r1, r1, #255
   23298: e3a00000     	mov	r0, #0
   2329c: e1801001     	orr	r1, r0, r1
   232a0: e5c3100e     	strb	r1, [r3, #0xe]
   232a4: e1a02c22     	lsr	r2, r2, #24
   232a8: e3a01000     	mov	r1, #0
   232ac: e1812002     	orr	r2, r1, r2
   232b0: e5c3200f     	strb	r2, [r3, #0xf]
   232b4: e51b310c     	ldr	r3, [r11, #-0x10c]
   232b8: e2833010     	add	r3, r3, #16
   232bc: e50b310c     	str	r3, [r11, #-0x10c]
   232c0: e51b310c     	ldr	r3, [r11, #-0x10c]
   232c4: e50b3108     	str	r3, [r11, #-0x108]
   232c8: e51b310c     	ldr	r3, [r11, #-0x10c]
   232cc: e50b3110     	str	r3, [r11, #-0x110]
   232d0: e51b3110     	ldr	r3, [r11, #-0x110]
   232d4: e3a02000     	mov	r2, #0
   232d8: e3822050     	orr	r2, r2, #80
   232dc: e5c32000     	strb	r2, [r3]
   232e0: e3a02000     	mov	r2, #0
   232e4: e3822052     	orr	r2, r2, #82
   232e8: e5c32001     	strb	r2, [r3, #0x1]
   232ec: e3a02000     	mov	r2, #0
   232f0: e382204f     	orr	r2, r2, #79
   232f4: e5c32002     	strb	r2, [r3, #0x2]
   232f8: e3a02000     	mov	r2, #0
   232fc: e3822050     	orr	r2, r2, #80
   23300: e5c32003     	strb	r2, [r3, #0x3]
   23304: e51b3110     	ldr	r3, [r11, #-0x110]
   23308: e3a02000     	mov	r2, #0
   2330c: e3822053     	orr	r2, r2, #83
   23310: e5c3200c     	strb	r2, [r3, #0xc]
   23314: e3a02000     	mov	r2, #0
   23318: e382204e     	orr	r2, r2, #78
   2331c: e5c3200d     	strb	r2, [r3, #0xd]
   23320: e3a02000     	mov	r2, #0
   23324: e3822044     	orr	r2, r2, #68
   23328: e5c3200e     	strb	r2, [r3, #0xe]
   2332c: e3a02000     	mov	r2, #0
   23330: e3822020     	orr	r2, r2, #32
   23334: e5c3200f     	strb	r2, [r3, #0xf]
   23338: e51b310c     	ldr	r3, [r11, #-0x10c]
   2333c: e2833010     	add	r3, r3, #16
   23340: e50b310c     	str	r3, [r11, #-0x10c]
   23344: e51b310c     	ldr	r3, [r11, #-0x10c]
   23348: e50b30f8     	str	r3, [r11, #-0xf8]
   2334c: e51b30f8     	ldr	r3, [r11, #-0xf8]
   23350: e3a02000     	mov	r2, #0
   23354: e3822046     	orr	r2, r2, #70
   23358: e5c32000     	strb	r2, [r3]
   2335c: e3a02000     	mov	r2, #0
   23360: e3822053     	orr	r2, r2, #83
   23364: e5c32001     	strb	r2, [r3, #0x1]
   23368: e3a02000     	mov	r2, #0
   2336c: e3822020     	orr	r2, r2, #32
   23370: e5c32002     	strb	r2, [r3, #0x2]
   23374: e3a02000     	mov	r2, #0
   23378: e3822020     	orr	r2, r2, #32
   2337c: e5c32003     	strb	r2, [r3, #0x3]
   23380: e59f1960     	ldr	r1, [pc, #0x960]        @ 0x23ce8 <calculate_header_and_footer+0xcac>
   23384: e3a02000     	mov	r2, #0
   23388: e3a03301     	mov	r3, #67108864
   2338c: e24b000c     	sub	r0, r11, #12
   23390: e18020f1     	strd	r2, r3, [r0, r1]
   23394: e59f394c     	ldr	r3, [pc, #0x94c]        @ 0x23ce8 <calculate_header_and_footer+0xcac>
   23398: e24b100c     	sub	r1, r11, #12
   2339c: e18320d1     	ldrd	r2, r3, [r3, r1]
   233a0: e51b10f8     	ldr	r1, [r11, #-0xf8]
   233a4: e20200ff     	and	r0, r2, #255
   233a8: e3a0c000     	mov	r12, #0
   233ac: e18c0000     	orr	r0, r12, r0
   233b0: e5c10004     	strb	r0, [r1, #0x4]
   233b4: e1a00422     	lsr	r0, r2, #8
   233b8: e20000ff     	and	r0, r0, #255
   233bc: e3a0c000     	mov	r12, #0
   233c0: e18c0000     	orr	r0, r12, r0
   233c4: e5c10005     	strb	r0, [r1, #0x5]
   233c8: e1a00822     	lsr	r0, r2, #16
   233cc: e20000ff     	and	r0, r0, #255
   233d0: e3a0c000     	mov	r12, #0
   233d4: e18c0000     	orr	r0, r12, r0
   233d8: e5c10006     	strb	r0, [r1, #0x6]
   233dc: e1a00c22     	lsr	r0, r2, #24
   233e0: e3a0c000     	mov	r12, #0
   233e4: e18c0000     	orr	r0, r12, r0
   233e8: e5c10007     	strb	r0, [r1, #0x7]
   233ec: e20300ff     	and	r0, r3, #255
   233f0: e3a0c000     	mov	r12, #0
   233f4: e18c0000     	orr	r0, r12, r0
   233f8: e5c10008     	strb	r0, [r1, #0x8]
   233fc: e1a00423     	lsr	r0, r3, #8
   23400: e20000ff     	and	r0, r0, #255
   23404: e3a0c000     	mov	r12, #0
   23408: e18c0000     	orr	r0, r12, r0
   2340c: e5c10009     	strb	r0, [r1, #0x9]
   23410: e1a00823     	lsr	r0, r3, #16
   23414: e20000ff     	and	r0, r0, #255
   23418: e3a0c000     	mov	r12, #0
   2341c: e18c0000     	orr	r0, r12, r0
   23420: e5c1000a     	strb	r0, [r1, #0xa]
   23424: e1a03c23     	lsr	r3, r3, #24
   23428: e3a02000     	mov	r2, #0
   2342c: e1823003     	orr	r3, r2, r3
   23430: e5c1300b     	strb	r3, [r1, #0xb]
   23434: e59f48b0     	ldr	r4, [pc, #0x8b0]        @ 0x23cec <calculate_header_and_footer+0xcb0>
   23438: e1a02c24     	lsr	r2, r4, #24
   2343c: e20438ff     	and	r3, r4, #16711680
   23440: e1a03423     	lsr	r3, r3, #8
   23444: e1822003     	orr	r2, r2, r3
   23448: e2043cff     	and	r3, r4, #65280
   2344c: e1a03403     	lsl	r3, r3, #8
   23450: e1822003     	orr	r2, r2, r3
   23454: e1a03c04     	lsl	r3, r4, #24
   23458: e1822003     	orr	r2, r2, r3
   2345c: e51b30f8     	ldr	r3, [r11, #-0xf8]
   23460: e20210ff     	and	r1, r2, #255
   23464: e3a00000     	mov	r0, #0
   23468: e1801001     	orr	r1, r0, r1
   2346c: e5c3100c     	strb	r1, [r3, #0xc]
   23470: e1a01422     	lsr	r1, r2, #8
   23474: e20110ff     	and	r1, r1, #255
   23478: e3a00000     	mov	r0, #0
   2347c: e1801001     	orr	r1, r0, r1
   23480: e5c3100d     	strb	r1, [r3, #0xd]
   23484: e1a01822     	lsr	r1, r2, #16
   23488: e20110ff     	and	r1, r1, #255
   2348c: e3a00000     	mov	r0, #0
   23490: e1801001     	orr	r1, r0, r1
   23494: e5c3100e     	strb	r1, [r3, #0xe]
   23498: e1a02c22     	lsr	r2, r2, #24
   2349c: e3a01000     	mov	r1, #0
   234a0: e1812002     	orr	r2, r1, r2
   234a4: e5c3200f     	strb	r2, [r3, #0xf]
   234a8: e51b310c     	ldr	r3, [r11, #-0x10c]
   234ac: e2833010     	add	r3, r3, #16
   234b0: e50b310c     	str	r3, [r11, #-0x10c]
   234b4: e51b3460     	ldr	r3, [r11, #-0x460]
   234b8: e5932000     	ldr	r2, [r3]
   234bc: e51b1104     	ldr	r1, [r11, #-0x104]
   234c0: e3a03060     	mov	r3, #96
   234c4: e59f0840     	ldr	r0, [pc, #0x840]        @ 0x23d0c <calculate_header_and_footer+0xcd0>
   234c8: e0020290     	mul	r2, r0, r2
   234cc: e0812002     	add	r2, r1, r2
   234d0: e0823003     	add	r3, r2, r3
   234d4: e5933000     	ldr	r3, [r3]
   234d8: e5d33020     	ldrb	r3, [r3, #0x20]
   234dc: e54b30ed     	strb	r3, [r11, #-0xed]
   234e0: e51b310c     	ldr	r3, [r11, #-0x10c]
   234e4: e50b30ec     	str	r3, [r11, #-0xec]
   234e8: e51b30ec     	ldr	r3, [r11, #-0xec]
   234ec: e3a02000     	mov	r2, #0
   234f0: e3822043     	orr	r2, r2, #67
   234f4: e5c32000     	strb	r2, [r3]
   234f8: e3a02000     	mov	r2, #0
   234fc: e3822048     	orr	r2, r2, #72
   23500: e5c32001     	strb	r2, [r3, #0x1]
   23504: e3a02000     	mov	r2, #0
   23508: e382204e     	orr	r2, r2, #78
   2350c: e5c32002     	strb	r2, [r3, #0x2]
   23510: e3a02000     	mov	r2, #0
   23514: e382204c     	orr	r2, r2, #76
   23518: e5c32003     	strb	r2, [r3, #0x3]
   2351c: e55b30ed     	ldrb	r3, [r11, #-0xed]
   23520: e1a03083     	lsl	r3, r3, #1
   23524: e2833001     	add	r3, r3, #1
   23528: e1a03083     	lsl	r3, r3, #1
   2352c: e2033001     	and	r3, r3, #1
   23530: e6ef3073     	uxtb	r3, r3
   23534: e3530000     	cmp	r3, #0
   23538: 0a000005     	beq	0x23554 <calculate_header_and_footer+0x518> @ imm = #0x14
   2353c: e55b30ed     	ldrb	r3, [r11, #-0xed]
   23540: e1a03083     	lsl	r3, r3, #1
   23544: e2833001     	add	r3, r3, #1
   23548: e1a03083     	lsl	r3, r3, #1
   2354c: e2833001     	add	r3, r3, #1
   23550: ea000003     	b	0x23564 <calculate_header_and_footer+0x528> @ imm = #0xc
   23554: e55b30ed     	ldrb	r3, [r11, #-0xed]
   23558: e1a03083     	lsl	r3, r3, #1
   2355c: e2833001     	add	r3, r3, #1
   23560: e1a03083     	lsl	r3, r3, #1
   23564: e1a02003     	mov	r2, r3
   23568: e3a03000     	mov	r3, #0
   2356c: e59f177c     	ldr	r1, [pc, #0x77c]        @ 0x23cf0 <calculate_header_and_footer+0xcb4>
   23570: e24b000c     	sub	r0, r11, #12
   23574: e18020f1     	strd	r2, r3, [r0, r1]
   23578: e59f2770     	ldr	r2, [pc, #0x770]        @ 0x23cf0 <calculate_header_and_footer+0xcb4>
   2357c: e3a03004     	mov	r3, #4
   23580: e24b100c     	sub	r1, r11, #12
   23584: e0812002     	add	r2, r1, r2
   23588: e0823003     	add	r3, r2, r3
   2358c: e5934000     	ldr	r4, [r3]
   23590: e1a02c24     	lsr	r2, r4, #24
   23594: e20438ff     	and	r3, r4, #16711680
   23598: e1a03423     	lsr	r3, r3, #8
   2359c: e1822003     	orr	r2, r2, r3
   235a0: e2043cff     	and	r3, r4, #65280
   235a4: e1a03403     	lsl	r3, r3, #8
   235a8: e1822003     	orr	r2, r2, r3
   235ac: e1a03c04     	lsl	r3, r4, #24
   235b0: e1822003     	orr	r2, r2, r3
   235b4: e59f3738     	ldr	r3, [pc, #0x738]        @ 0x23cf4 <calculate_header_and_footer+0xcb8>
   235b8: e24b000c     	sub	r0, r11, #12
   235bc: e7802003     	str	r2, [r0, r3]
   235c0: e59f3728     	ldr	r3, [pc, #0x728]        @ 0x23cf0 <calculate_header_and_footer+0xcb4>
   235c4: e24b100c     	sub	r1, r11, #12
   235c8: e7914003     	ldr	r4, [r1, r3]
   235cc: e1a02c24     	lsr	r2, r4, #24
   235d0: e20438ff     	and	r3, r4, #16711680
   235d4: e1a03423     	lsr	r3, r3, #8
   235d8: e1822003     	orr	r2, r2, r3
   235dc: e2043cff     	and	r3, r4, #65280
   235e0: e1a03403     	lsl	r3, r3, #8
   235e4: e1822003     	orr	r2, r2, r3
   235e8: e1a03c04     	lsl	r3, r4, #24
   235ec: e1822003     	orr	r2, r2, r3
   235f0: e59f16fc     	ldr	r1, [pc, #0x6fc]        @ 0x23cf4 <calculate_header_and_footer+0xcb8>
   235f4: e3a03004     	mov	r3, #4
   235f8: e24b000c     	sub	r0, r11, #12
   235fc: e0801001     	add	r1, r0, r1
   23600: e0813003     	add	r3, r1, r3
   23604: e5832000     	str	r2, [r3]
   23608: e59f36e4     	ldr	r3, [pc, #0x6e4]        @ 0x23cf4 <calculate_header_and_footer+0xcb8>
   2360c: e24b100c     	sub	r1, r11, #12
   23610: e18320d1     	ldrd	r2, r3, [r3, r1]
   23614: e51b10ec     	ldr	r1, [r11, #-0xec]
   23618: e20200ff     	and	r0, r2, #255
   2361c: e3a0c000     	mov	r12, #0
   23620: e18c0000     	orr	r0, r12, r0
   23624: e5c10004     	strb	r0, [r1, #0x4]
   23628: e1a00422     	lsr	r0, r2, #8
   2362c: e20000ff     	and	r0, r0, #255
   23630: e3a0c000     	mov	r12, #0
   23634: e18c0000     	orr	r0, r12, r0
   23638: e5c10005     	strb	r0, [r1, #0x5]
   2363c: e1a00822     	lsr	r0, r2, #16
   23640: e20000ff     	and	r0, r0, #255
   23644: e3a0c000     	mov	r12, #0
   23648: e18c0000     	orr	r0, r12, r0
   2364c: e5c10006     	strb	r0, [r1, #0x6]
   23650: e1a00c22     	lsr	r0, r2, #24
   23654: e3a0c000     	mov	r12, #0
   23658: e18c0000     	orr	r0, r12, r0
   2365c: e5c10007     	strb	r0, [r1, #0x7]
   23660: e20300ff     	and	r0, r3, #255
   23664: e3a0c000     	mov	r12, #0
   23668: e18c0000     	orr	r0, r12, r0
   2366c: e5c10008     	strb	r0, [r1, #0x8]
   23670: e1a00423     	lsr	r0, r3, #8
   23674: e20000ff     	and	r0, r0, #255
   23678: e3a0c000     	mov	r12, #0
   2367c: e18c0000     	orr	r0, r12, r0
   23680: e5c10009     	strb	r0, [r1, #0x9]
   23684: e1a00823     	lsr	r0, r3, #16
   23688: e20000ff     	and	r0, r0, #255
   2368c: e3a0c000     	mov	r12, #0
   23690: e18c0000     	orr	r0, r12, r0
   23694: e5c1000a     	strb	r0, [r1, #0xa]
   23698: e1a03c23     	lsr	r3, r3, #24
   2369c: e3a02000     	mov	r2, #0
   236a0: e1823003     	orr	r3, r2, r3
   236a4: e5c1300b     	strb	r3, [r1, #0xb]
   236a8: e55b30ed     	ldrb	r3, [r11, #-0xed]
   236ac: e14b3eb6     	strh	r3, [r11, #-230]
   236b0: e15b3eb6     	ldrh	r3, [r11, #-230]
   236b4: e1a03423     	lsr	r3, r3, #8
   236b8: e6ff3073     	uxth	r3, r3
   236bc: e1a02003     	mov	r2, r3
   236c0: e15b3eb6     	ldrh	r3, [r11, #-230]
   236c4: e1a03403     	lsl	r3, r3, #8
   236c8: e1a03803     	lsl	r3, r3, #16
   236cc: e1a03823     	lsr	r3, r3, #16
   236d0: e1823003     	orr	r3, r2, r3
   236d4: e6ff2073     	uxth	r2, r3
   236d8: e51b30ec     	ldr	r3, [r11, #-0xec]
   236dc: e20210ff     	and	r1, r2, #255
   236e0: e3a00000     	mov	r0, #0
   236e4: e1801001     	orr	r1, r0, r1
   236e8: e5c3100c     	strb	r1, [r3, #0xc]
   236ec: e1a02422     	lsr	r2, r2, #8
   236f0: e6ff2072     	uxth	r2, r2
   236f4: e3a01000     	mov	r1, #0
   236f8: e1812002     	orr	r2, r1, r2
   236fc: e5c3200d     	strb	r2, [r3, #0xd]
   23700: e55b30ed     	ldrb	r3, [r11, #-0xed]
   23704: e3530005     	cmp	r3, #5
   23708: 0a00001e     	beq	0x23788 <calculate_header_and_footer+0x74c> @ imm = #0x78
   2370c: e3530006     	cmp	r3, #6
   23710: 0a00005e     	beq	0x23890 <calculate_header_and_footer+0x854> @ imm = #0x178
   23714: e3530002     	cmp	r3, #2
   23718: 1a0000ab     	bne	0x239cc <calculate_header_and_footer+0x990> @ imm = #0x2ac
   2371c: e51b30ec     	ldr	r3, [r11, #-0xec]
   23720: e3a02000     	mov	r2, #0
   23724: e3822053     	orr	r2, r2, #83
   23728: e5c3200e     	strb	r2, [r3, #0xe]
   2372c: e3a02000     	mov	r2, #0
   23730: e382204c     	orr	r2, r2, #76
   23734: e5c3200f     	strb	r2, [r3, #0xf]
   23738: e3a02000     	mov	r2, #0
   2373c: e3822046     	orr	r2, r2, #70
   23740: e5c32010     	strb	r2, [r3, #0x10]
   23744: e3a02000     	mov	r2, #0
   23748: e3822054     	orr	r2, r2, #84
   2374c: e5c32011     	strb	r2, [r3, #0x11]
   23750: e51b30ec     	ldr	r3, [r11, #-0xec]
   23754: e3a02000     	mov	r2, #0
   23758: e3822053     	orr	r2, r2, #83
   2375c: e5c32012     	strb	r2, [r3, #0x12]
   23760: e3a02000     	mov	r2, #0
   23764: e3822052     	orr	r2, r2, #82
   23768: e5c32013     	strb	r2, [r3, #0x13]
   2376c: e3a02000     	mov	r2, #0
   23770: e3822047     	orr	r2, r2, #71
   23774: e5c32014     	strb	r2, [r3, #0x14]
   23778: e3a02000     	mov	r2, #0
   2377c: e3822054     	orr	r2, r2, #84
   23780: e5c32015     	strb	r2, [r3, #0x15]
   23784: ea0000a5     	b	0x23a20 <calculate_header_and_footer+0x9e4> @ imm = #0x294
   23788: e51b30ec     	ldr	r3, [r11, #-0xec]
   2378c: e3a02000     	mov	r2, #0
   23790: e382204d     	orr	r2, r2, #77
   23794: e5c3200e     	strb	r2, [r3, #0xe]
   23798: e3a02000     	mov	r2, #0
   2379c: e382204c     	orr	r2, r2, #76
   237a0: e5c3200f     	strb	r2, [r3, #0xf]
   237a4: e3a02000     	mov	r2, #0
   237a8: e3822046     	orr	r2, r2, #70
   237ac: e5c32010     	strb	r2, [r3, #0x10]
   237b0: e3a02000     	mov	r2, #0
   237b4: e3822054     	orr	r2, r2, #84
   237b8: e5c32011     	strb	r2, [r3, #0x11]
   237bc: e51b30ec     	ldr	r3, [r11, #-0xec]
   237c0: e3a02000     	mov	r2, #0
   237c4: e382204d     	orr	r2, r2, #77
   237c8: e5c32012     	strb	r2, [r3, #0x12]
   237cc: e3a02000     	mov	r2, #0
   237d0: e3822052     	orr	r2, r2, #82
   237d4: e5c32013     	strb	r2, [r3, #0x13]
   237d8: e3a02000     	mov	r2, #0
   237dc: e3822047     	orr	r2, r2, #71
   237e0: e5c32014     	strb	r2, [r3, #0x14]
   237e4: e3a02000     	mov	r2, #0
   237e8: e3822054     	orr	r2, r2, #84
   237ec: e5c32015     	strb	r2, [r3, #0x15]
   237f0: e51b30ec     	ldr	r3, [r11, #-0xec]
   237f4: e3a02000     	mov	r2, #0
   237f8: e3822043     	orr	r2, r2, #67
   237fc: e5c32016     	strb	r2, [r3, #0x16]
   23800: e3a02000     	mov	r2, #0
   23804: e3822020     	orr	r2, r2, #32
   23808: e5c32017     	strb	r2, [r3, #0x17]
   2380c: e3a02000     	mov	r2, #0
   23810: e3822020     	orr	r2, r2, #32
   23814: e5c32018     	strb	r2, [r3, #0x18]
   23818: e3a02000     	mov	r2, #0
   2381c: e3822020     	orr	r2, r2, #32
   23820: e5c32019     	strb	r2, [r3, #0x19]
   23824: e51b30ec     	ldr	r3, [r11, #-0xec]
   23828: e3a02000     	mov	r2, #0
   2382c: e382204c     	orr	r2, r2, #76
   23830: e5c3201a     	strb	r2, [r3, #0x1a]
   23834: e3a02000     	mov	r2, #0
   23838: e3822053     	orr	r2, r2, #83
   2383c: e5c3201b     	strb	r2, [r3, #0x1b]
   23840: e3a02000     	mov	r2, #0
   23844: e3822020     	orr	r2, r2, #32
   23848: e5c3201c     	strb	r2, [r3, #0x1c]
   2384c: e3a02000     	mov	r2, #0
   23850: e3822020     	orr	r2, r2, #32
   23854: e5c3201d     	strb	r2, [r3, #0x1d]
   23858: e51b30ec     	ldr	r3, [r11, #-0xec]
   2385c: e3a02000     	mov	r2, #0
   23860: e3822052     	orr	r2, r2, #82
   23864: e5c3201e     	strb	r2, [r3, #0x1e]
   23868: e3a02000     	mov	r2, #0
   2386c: e3822053     	orr	r2, r2, #83
   23870: e5c3201f     	strb	r2, [r3, #0x1f]
   23874: e3a02000     	mov	r2, #0
   23878: e3822020     	orr	r2, r2, #32
   2387c: e5c32020     	strb	r2, [r3, #0x20]
   23880: e3a02000     	mov	r2, #0
   23884: e3822020     	orr	r2, r2, #32
   23888: e5c32021     	strb	r2, [r3, #0x21]
   2388c: ea000063     	b	0x23a20 <calculate_header_and_footer+0x9e4> @ imm = #0x18c
   23890: e51b30ec     	ldr	r3, [r11, #-0xec]
   23894: e3a02000     	mov	r2, #0
   23898: e382204d     	orr	r2, r2, #77
   2389c: e5c3200e     	strb	r2, [r3, #0xe]
   238a0: e3a02000     	mov	r2, #0
   238a4: e382204c     	orr	r2, r2, #76
   238a8: e5c3200f     	strb	r2, [r3, #0xf]
   238ac: e3a02000     	mov	r2, #0
   238b0: e3822046     	orr	r2, r2, #70
   238b4: e5c32010     	strb	r2, [r3, #0x10]
   238b8: e3a02000     	mov	r2, #0
   238bc: e3822054     	orr	r2, r2, #84
   238c0: e5c32011     	strb	r2, [r3, #0x11]
   238c4: e51b30ec     	ldr	r3, [r11, #-0xec]
   238c8: e3a02000     	mov	r2, #0
   238cc: e382204d     	orr	r2, r2, #77
   238d0: e5c32012     	strb	r2, [r3, #0x12]
   238d4: e3a02000     	mov	r2, #0
   238d8: e3822052     	orr	r2, r2, #82
   238dc: e5c32013     	strb	r2, [r3, #0x13]
   238e0: e3a02000     	mov	r2, #0
   238e4: e3822047     	orr	r2, r2, #71
   238e8: e5c32014     	strb	r2, [r3, #0x14]
   238ec: e3a02000     	mov	r2, #0
   238f0: e3822054     	orr	r2, r2, #84
   238f4: e5c32015     	strb	r2, [r3, #0x15]
   238f8: e51b30ec     	ldr	r3, [r11, #-0xec]
   238fc: e3a02000     	mov	r2, #0
   23900: e3822043     	orr	r2, r2, #67
   23904: e5c32016     	strb	r2, [r3, #0x16]
   23908: e3a02000     	mov	r2, #0
   2390c: e3822020     	orr	r2, r2, #32
   23910: e5c32017     	strb	r2, [r3, #0x17]
   23914: e3a02000     	mov	r2, #0
   23918: e3822020     	orr	r2, r2, #32
   2391c: e5c32018     	strb	r2, [r3, #0x18]
   23920: e3a02000     	mov	r2, #0
   23924: e3822020     	orr	r2, r2, #32
   23928: e5c32019     	strb	r2, [r3, #0x19]
   2392c: e51b30ec     	ldr	r3, [r11, #-0xec]
   23930: e3a02000     	mov	r2, #0
   23934: e382204c     	orr	r2, r2, #76
   23938: e5c3201a     	strb	r2, [r3, #0x1a]
   2393c: e3a02000     	mov	r2, #0
   23940: e3822046     	orr	r2, r2, #70
   23944: e5c3201b     	strb	r2, [r3, #0x1b]
   23948: e3a02000     	mov	r2, #0
   2394c: e3822045     	orr	r2, r2, #69
   23950: e5c3201c     	strb	r2, [r3, #0x1c]
   23954: e3a02000     	mov	r2, #0
   23958: e3822020     	orr	r2, r2, #32
   2395c: e5c3201d     	strb	r2, [r3, #0x1d]
   23960: e51b30ec     	ldr	r3, [r11, #-0xec]
   23964: e3a02000     	mov	r2, #0
   23968: e382204c     	orr	r2, r2, #76
   2396c: e5c3201e     	strb	r2, [r3, #0x1e]
   23970: e3a02000     	mov	r2, #0
   23974: e3822053     	orr	r2, r2, #83
   23978: e5c3201f     	strb	r2, [r3, #0x1f]
   2397c: e3a02000     	mov	r2, #0
   23980: e3822020     	orr	r2, r2, #32
   23984: e5c32020     	strb	r2, [r3, #0x20]
   23988: e3a02000     	mov	r2, #0
   2398c: e3822020     	orr	r2, r2, #32
   23990: e5c32021     	strb	r2, [r3, #0x21]
   23994: e51b30ec     	ldr	r3, [r11, #-0xec]
   23998: e3a02000     	mov	r2, #0
   2399c: e3822052     	orr	r2, r2, #82
   239a0: e5c32022     	strb	r2, [r3, #0x22]
   239a4: e3a02000     	mov	r2, #0
   239a8: e3822053     	orr	r2, r2, #83
   239ac: e5c32023     	strb	r2, [r3, #0x23]
   239b0: e3a02000     	mov	r2, #0
   239b4: e3822020     	orr	r2, r2, #32
   239b8: e5c32024     	strb	r2, [r3, #0x24]
   239bc: e3a02000     	mov	r2, #0
   239c0: e3822020     	orr	r2, r2, #32
   239c4: e5c32025     	strb	r2, [r3, #0x25]
   239c8: ea000014     	b	0x23a20 <calculate_header_and_footer+0x9e4> @ imm = #0x50
   239cc: e3a03000     	mov	r3, #0
   239d0: e50b30f4     	str	r3, [r11, #-0xf4]
   239d4: ea00000d     	b	0x23a10 <calculate_header_and_footer+0x9d4> @ imm = #0x34
   239d8: e51b30ec     	ldr	r3, [r11, #-0xec]
   239dc: e283300e     	add	r3, r3, #14
   239e0: e1a02003     	mov	r2, r3
   239e4: e51b30f4     	ldr	r3, [r11, #-0xf4]
   239e8: e1a03103     	lsl	r3, r3, #2
   239ec: e0822003     	add	r2, r2, r3
   239f0: e59f3300     	ldr	r3, [pc, #0x300]        @ 0x23cf8 <calculate_header_and_footer+0xcbc>
   239f4: e1a00002     	mov	r0, r2
   239f8: e1a01003     	mov	r1, r3
   239fc: e51b20f4     	ldr	r2, [r11, #-0xf4]
   23a00: ebffa37e     	bl	0xc800 <sprintf@plt>    @ imm = #-0x17208
   23a04: e51b30f4     	ldr	r3, [r11, #-0xf4]
   23a08: e2833001     	add	r3, r3, #1
   23a0c: e50b30f4     	str	r3, [r11, #-0xf4]
   23a10: e55b20ed     	ldrb	r2, [r11, #-0xed]
   23a14: e51b30f4     	ldr	r3, [r11, #-0xf4]
   23a18: e1520003     	cmp	r2, r3
   23a1c: caffffed     	bgt	0x239d8 <calculate_header_and_footer+0x99c> @ imm = #-0x4c
   23a20: e55b30ed     	ldrb	r3, [r11, #-0xed]
   23a24: e1a03103     	lsl	r3, r3, #2
   23a28: e283300e     	add	r3, r3, #14
   23a2c: e51b210c     	ldr	r2, [r11, #-0x10c]
   23a30: e0823003     	add	r3, r2, r3
   23a34: e50b310c     	str	r3, [r11, #-0x10c]
   23a38: e51b310c     	ldr	r3, [r11, #-0x10c]
   23a3c: e50b30e4     	str	r3, [r11, #-0xe4]
   23a40: e51b30e4     	ldr	r3, [r11, #-0xe4]
   23a44: e3a02000     	mov	r2, #0
   23a48: e3822043     	orr	r2, r2, #67
   23a4c: e5c32000     	strb	r2, [r3]
   23a50: e3a02000     	mov	r2, #0
   23a54: e382204d     	orr	r2, r2, #77
   23a58: e5c32001     	strb	r2, [r3, #0x1]
   23a5c: e3a02000     	mov	r2, #0
   23a60: e3822050     	orr	r2, r2, #80
   23a64: e5c32002     	strb	r2, [r3, #0x2]
   23a68: e3a02000     	mov	r2, #0
   23a6c: e3822052     	orr	r2, r2, #82
   23a70: e5c32003     	strb	r2, [r3, #0x3]
   23a74: e51b3460     	ldr	r3, [r11, #-0x460]
   23a78: e593303c     	ldr	r3, [r3, #0x3c]
   23a7c: e3530000     	cmp	r3, #0
   23a80: 0a000016     	beq	0x23ae0 <calculate_header_and_footer+0xaa4> @ imm = #0x58
   23a84: e51b30e4     	ldr	r3, [r11, #-0xe4]
   23a88: e3a02000     	mov	r2, #0
   23a8c: e3822044     	orr	r2, r2, #68
   23a90: e5c3200c     	strb	r2, [r3, #0xc]
   23a94: e3a02000     	mov	r2, #0
   23a98: e3822053     	orr	r2, r2, #83
   23a9c: e5c3200d     	strb	r2, [r3, #0xd]
   23aa0: e3a02000     	mov	r2, #0
   23aa4: e3822044     	orr	r2, r2, #68
   23aa8: e5c3200e     	strb	r2, [r3, #0xe]
   23aac: e3a02000     	mov	r2, #0
   23ab0: e3822020     	orr	r2, r2, #32
   23ab4: e5c3200f     	strb	r2, [r3, #0xf]
   23ab8: e51b30e4     	ldr	r3, [r11, #-0xe4]
   23abc: e3a0200e     	mov	r2, #14
   23ac0: e5c32010     	strb	r2, [r3, #0x10]
   23ac4: e51b30e4     	ldr	r3, [r11, #-0xe4]
   23ac8: e2833011     	add	r3, r3, #17
   23acc: e1a00003     	mov	r0, r3
   23ad0: e59f1224     	ldr	r1, [pc, #0x224]        @ 0x23cfc <calculate_header_and_footer+0xcc0>
   23ad4: e3a0200e     	mov	r2, #14
   23ad8: ebffa28b     	bl	0xc50c <memcpy@plt>     @ imm = #-0x175d4
   23adc: ea000015     	b	0x23b38 <calculate_header_and_footer+0xafc> @ imm = #0x54
   23ae0: e51b30e4     	ldr	r3, [r11, #-0xe4]
   23ae4: e3a02000     	mov	r2, #0
   23ae8: e3822044     	orr	r2, r2, #68
   23aec: e5c3200c     	strb	r2, [r3, #0xc]
   23af0: e3a02000     	mov	r2, #0
   23af4: e3822053     	orr	r2, r2, #83
   23af8: e5c3200d     	strb	r2, [r3, #0xd]
   23afc: e3a02000     	mov	r2, #0
   23b00: e3822054     	orr	r2, r2, #84
   23b04: e5c3200e     	strb	r2, [r3, #0xe]
   23b08: e3a02000     	mov	r2, #0
   23b0c: e3822020     	orr	r2, r2, #32
   23b10: e5c3200f     	strb	r2, [r3, #0xf]
   23b14: e51b30e4     	ldr	r3, [r11, #-0xe4]
   23b18: e3a0200b     	mov	r2, #11
   23b1c: e5c32010     	strb	r2, [r3, #0x10]
   23b20: e51b30e4     	ldr	r3, [r11, #-0xe4]
   23b24: e2833011     	add	r3, r3, #17
   23b28: e1a00003     	mov	r0, r3
   23b2c: e59f11cc     	ldr	r1, [pc, #0x1cc]        @ 0x23d00 <calculate_header_and_footer+0xcc4>
   23b30: e3a0200b     	mov	r2, #11
   23b34: ebffa274     	bl	0xc50c <memcpy@plt>     @ imm = #-0x17630
   23b38: e51b30e4     	ldr	r3, [r11, #-0xe4]
   23b3c: e5d33010     	ldrb	r3, [r3, #0x10]
   23b40: e2833005     	add	r3, r3, #5
   23b44: e2033001     	and	r3, r3, #1
   23b48: e6ef3073     	uxtb	r3, r3
   23b4c: e3530000     	cmp	r3, #0
   23b50: 0a000003     	beq	0x23b64 <calculate_header_and_footer+0xb28> @ imm = #0xc
   23b54: e51b30e4     	ldr	r3, [r11, #-0xe4]
   23b58: e5d33010     	ldrb	r3, [r3, #0x10]
   23b5c: e2833006     	add	r3, r3, #6
   23b60: ea000002     	b	0x23b70 <calculate_header_and_footer+0xb34> @ imm = #0x8
   23b64: e51b30e4     	ldr	r3, [r11, #-0xe4]
   23b68: e5d33010     	ldrb	r3, [r3, #0x10]
   23b6c: e2833005     	add	r3, r3, #5
   23b70: e1a02003     	mov	r2, r3
   23b74: e3a03000     	mov	r3, #0
   23b78: e59f1184     	ldr	r1, [pc, #0x184]        @ 0x23d04 <calculate_header_and_footer+0xcc8>
   23b7c: e24b000c     	sub	r0, r11, #12
   23b80: e18020f1     	strd	r2, r3, [r0, r1]
   23b84: e59f2178     	ldr	r2, [pc, #0x178]        @ 0x23d04 <calculate_header_and_footer+0xcc8>
   23b88: e3a03004     	mov	r3, #4
   23b8c: e24b100c     	sub	r1, r11, #12
   23b90: e0812002     	add	r2, r1, r2
   23b94: e0823003     	add	r3, r2, r3
   23b98: e5934000     	ldr	r4, [r3]
   23b9c: e1a02c24     	lsr	r2, r4, #24
   23ba0: e20438ff     	and	r3, r4, #16711680
   23ba4: e1a03423     	lsr	r3, r3, #8
   23ba8: e1822003     	orr	r2, r2, r3
   23bac: e2043cff     	and	r3, r4, #65280
   23bb0: e1a03403     	lsl	r3, r3, #8
   23bb4: e1822003     	orr	r2, r2, r3
   23bb8: e1a03c04     	lsl	r3, r4, #24
   23bbc: e1822003     	orr	r2, r2, r3
   23bc0: e59f3140     	ldr	r3, [pc, #0x140]        @ 0x23d08 <calculate_header_and_footer+0xccc>
   23bc4: e24b000c     	sub	r0, r11, #12
   23bc8: e7802003     	str	r2, [r0, r3]
   23bcc: e59f3130     	ldr	r3, [pc, #0x130]        @ 0x23d04 <calculate_header_and_footer+0xcc8>
   23bd0: e24b100c     	sub	r1, r11, #12
   23bd4: e7914003     	ldr	r4, [r1, r3]
   23bd8: e1a02c24     	lsr	r2, r4, #24
   23bdc: e20438ff     	and	r3, r4, #16711680
   23be0: e1a03423     	lsr	r3, r3, #8
   23be4: e1822003     	orr	r2, r2, r3
   23be8: e2043cff     	and	r3, r4, #65280
   23bec: e1a03403     	lsl	r3, r3, #8
   23bf0: e1822003     	orr	r2, r2, r3
   23bf4: e1a03c04     	lsl	r3, r4, #24
   23bf8: e1822003     	orr	r2, r2, r3
   23bfc: e59f1104     	ldr	r1, [pc, #0x104]        @ 0x23d08 <calculate_header_and_footer+0xccc>
   23c00: e3a03004     	mov	r3, #4
   23c04: e24b000c     	sub	r0, r11, #12
   23c08: e0801001     	add	r1, r0, r1
   23c0c: e0813003     	add	r3, r1, r3
   23c10: e5832000     	str	r2, [r3]
   23c14: e59f30ec     	ldr	r3, [pc, #0xec]         @ 0x23d08 <calculate_header_and_footer+0xccc>
   23c18: e24b100c     	sub	r1, r11, #12
   23c1c: e18320d1     	ldrd	r2, r3, [r3, r1]
   23c20: e51b10e4     	ldr	r1, [r11, #-0xe4]
   23c24: e20200ff     	and	r0, r2, #255
   23c28: e3a0c000     	mov	r12, #0
   23c2c: e18c0000     	orr	r0, r12, r0
   23c30: e5c10004     	strb	r0, [r1, #0x4]
   23c34: e1a00422     	lsr	r0, r2, #8
   23c38: e20000ff     	and	r0, r0, #255
   23c3c: e3a0c000     	mov	r12, #0
   23c40: e18c0000     	orr	r0, r12, r0
   23c44: e5c10005     	strb	r0, [r1, #0x5]
   23c48: e1a00822     	lsr	r0, r2, #16
   23c4c: e20000ff     	and	r0, r0, #255
   23c50: e3a0c000     	mov	r12, #0
   23c54: e18c0000     	orr	r0, r12, r0
   23c58: e5c10006     	strb	r0, [r1, #0x6]
   23c5c: e1a00c22     	lsr	r0, r2, #24
   23c60: e3a0c000     	mov	r12, #0
   23c64: e18c0000     	orr	r0, r12, r0
   23c68: e5c10007     	strb	r0, [r1, #0x7]
   23c6c: e20300ff     	and	r0, r3, #255
   23c70: e3a0c000     	mov	r12, #0
   23c74: e18c0000     	orr	r0, r12, r0
   23c78: e5c10008     	strb	r0, [r1, #0x8]
   23c7c: e1a00423     	lsr	r0, r3, #8
   23c80: e20000ff     	and	r0, r0, #255
   23c84: e3a0c000     	mov	r12, #0
   23c88: e18c0000     	orr	r0, r12, r0
   23c8c: e5c10009     	strb	r0, [r1, #0x9]
   23c90: e1a00823     	lsr	r0, r3, #16
   23c94: e20000ff     	and	r0, r0, #255
   23c98: e3a0c000     	mov	r12, #0
   23c9c: e18c0000     	orr	r0, r12, r0
   23ca0: e5c1000a     	strb	r0, [r1, #0xa]
   23ca4: e1a03c23     	lsr	r3, r3, #24
   23ca8: e3a02000     	mov	r2, #0
   23cac: e1823003     	orr	r3, r2, r3
   23cb0: e5c1300b     	strb	r3, [r1, #0xb]
   23cb4: e51b30e4     	ldr	r3, [r11, #-0xe4]
   23cb8: e5d33010     	ldrb	r3, [r3, #0x10]
   23cbc: e2833011     	add	r3, r3, #17
   23cc0: e2033001     	and	r3, r3, #1
   23cc4: e6ef3073     	uxtb	r3, r3
   23cc8: e3530000     	cmp	r3, #0
   23ccc: 0a000019     	beq	0x23d38 <calculate_header_and_footer+0xcfc> @ imm = #0x64
   23cd0: e51b30e4     	ldr	r3, [r11, #-0xe4]
   23cd4: e5d33010     	ldrb	r3, [r3, #0x10]
   23cd8: e2833012     	add	r3, r3, #18
   23cdc: ea000018     	b	0x23d44 <calculate_header_and_footer+0xd08> @ imm = #0x60
   23ce0: e8 fe ff ff  	.word	0xfffffee8
   23ce4: 00 00 05 01  	.word	0x01050000
   23ce8: d8 fe ff ff  	.word	0xfffffed8
   23cec: 00 11 2b 00  	.word	0x002b1100
   23cf0: d0 fe ff ff  	.word	0xfffffed0
   23cf4: c8 fe ff ff  	.word	0xfffffec8
   23cf8: 30 55 03 00  	.word	0x00035530
   23cfc: 38 55 03 00  	.word	0x00035538
   23d00: 48 55 03 00  	.word	0x00035548
   23d04: c0 fe ff ff  	.word	0xfffffec0
   23d08: b8 fe ff ff  	.word	0xfffffeb8
   23d0c: f0 37 00 00  	.word	0x000037f0
   23d10: a8 fe ff ff  	.word	0xfffffea8
   23d14: a0 fe ff ff  	.word	0xfffffea0
   23d18: 98 fe ff ff  	.word	0xfffffe98
   23d1c: 90 fe ff ff  	.word	0xfffffe90
   23d20: 88 fe ff ff  	.word	0xfffffe88
   23d24: 78 fe ff ff  	.word	0xfffffe78
   23d28: 70 fe ff ff  	.word	0xfffffe70
   23d2c: 68 fe ff ff  	.word	0xfffffe68
   23d30: 58 fe ff ff  	.word	0xfffffe58
   23d34: 60 fe ff ff  	.word	0xfffffe60
   23d38: e51b30e4     	ldr	r3, [r11, #-0xe4]
   23d3c: e5d33010     	ldrb	r3, [r3, #0x10]
   23d40: e2833011     	add	r3, r3, #17
   23d44: e51b210c     	ldr	r2, [r11, #-0x10c]
   23d48: e0823003     	add	r3, r2, r3
   23d4c: e50b310c     	str	r3, [r11, #-0x10c]
   23d50: e51b3460     	ldr	r3, [r11, #-0x460]
   23d54: e5932000     	ldr	r2, [r3]
   23d58: e51b1104     	ldr	r1, [r11, #-0x104]
   23d5c: e3a03060     	mov	r3, #96
   23d60: e51f005c     	ldr	r0, [pc, #-0x5c]        @ 0x23d0c <calculate_header_and_footer+0xcd0>
   23d64: e0020290     	mul	r2, r0, r2
   23d68: e0812002     	add	r2, r1, r2
   23d6c: e0823003     	add	r3, r2, r3
   23d70: e5933000     	ldr	r3, [r3]
   23d74: e5d33020     	ldrb	r3, [r3, #0x20]
   23d78: e54b30dd     	strb	r3, [r11, #-0xdd]
   23d7c: e51b310c     	ldr	r3, [r11, #-0x10c]
   23d80: e50b30dc     	str	r3, [r11, #-0xdc]
   23d84: e51b30dc     	ldr	r3, [r11, #-0xdc]
   23d88: e3a02000     	mov	r2, #0
   23d8c: e382204c     	orr	r2, r2, #76
   23d90: e5c32000     	strb	r2, [r3]
   23d94: e3a02000     	mov	r2, #0
   23d98: e3822053     	orr	r2, r2, #83
   23d9c: e5c32001     	strb	r2, [r3, #0x1]
   23da0: e3a02000     	mov	r2, #0
   23da4: e3822043     	orr	r2, r2, #67
   23da8: e5c32002     	strb	r2, [r3, #0x2]
   23dac: e3a02000     	mov	r2, #0
   23db0: e382204f     	orr	r2, r2, #79
   23db4: e5c32003     	strb	r2, [r3, #0x3]
   23db8: e51f10b0     	ldr	r1, [pc, #-0xb0]        @ 0x23d10 <calculate_header_and_footer+0xcd4>
   23dbc: e3a02000     	mov	r2, #0
   23dc0: e3a03402     	mov	r3, #33554432
   23dc4: e24b000c     	sub	r0, r11, #12
   23dc8: e18020f1     	strd	r2, r3, [r0, r1]
   23dcc: e51f30c4     	ldr	r3, [pc, #-0xc4]        @ 0x23d10 <calculate_header_and_footer+0xcd4>
   23dd0: e24b100c     	sub	r1, r11, #12
   23dd4: e18320d1     	ldrd	r2, r3, [r3, r1]
   23dd8: e51b10dc     	ldr	r1, [r11, #-0xdc]
   23ddc: e20200ff     	and	r0, r2, #255
   23de0: e3a0c000     	mov	r12, #0
   23de4: e18c0000     	orr	r0, r12, r0
   23de8: e5c10004     	strb	r0, [r1, #0x4]
   23dec: e1a00422     	lsr	r0, r2, #8
   23df0: e20000ff     	and	r0, r0, #255
   23df4: e3a0c000     	mov	r12, #0
   23df8: e18c0000     	orr	r0, r12, r0
   23dfc: e5c10005     	strb	r0, [r1, #0x5]
   23e00: e1a00822     	lsr	r0, r2, #16
   23e04: e20000ff     	and	r0, r0, #255
   23e08: e3a0c000     	mov	r12, #0
   23e0c: e18c0000     	orr	r0, r12, r0
   23e10: e5c10006     	strb	r0, [r1, #0x6]
   23e14: e1a00c22     	lsr	r0, r2, #24
   23e18: e3a0c000     	mov	r12, #0
   23e1c: e18c0000     	orr	r0, r12, r0
   23e20: e5c10007     	strb	r0, [r1, #0x7]
   23e24: e20300ff     	and	r0, r3, #255
   23e28: e3a0c000     	mov	r12, #0
   23e2c: e18c0000     	orr	r0, r12, r0
   23e30: e5c10008     	strb	r0, [r1, #0x8]
   23e34: e1a00423     	lsr	r0, r3, #8
   23e38: e20000ff     	and	r0, r0, #255
   23e3c: e3a0c000     	mov	r12, #0
   23e40: e18c0000     	orr	r0, r12, r0
   23e44: e5c10009     	strb	r0, [r1, #0x9]
   23e48: e1a00823     	lsr	r0, r3, #16
   23e4c: e20000ff     	and	r0, r0, #255
   23e50: e3a0c000     	mov	r12, #0
   23e54: e18c0000     	orr	r0, r12, r0
   23e58: e5c1000a     	strb	r0, [r1, #0xa]
   23e5c: e1a03c23     	lsr	r3, r3, #24
   23e60: e3a02000     	mov	r2, #0
   23e64: e1823003     	orr	r3, r2, r3
   23e68: e5c1300b     	strb	r3, [r1, #0xb]
   23e6c: e55b30dd     	ldrb	r3, [r11, #-0xdd]
   23e70: e3530005     	cmp	r3, #5
   23e74: 0a00001a     	beq	0x23ee4 <calculate_header_and_footer+0xea8> @ imm = #0x68
   23e78: e3530006     	cmp	r3, #6
   23e7c: 0a00002f     	beq	0x23f40 <calculate_header_and_footer+0xf04> @ imm = #0xbc
   23e80: e3530002     	cmp	r3, #2
   23e84: 1a000044     	bne	0x23f9c <calculate_header_and_footer+0xf60> @ imm = #0x110
   23e88: e3a03000     	mov	r3, #0
   23e8c: e14b3db8     	strh	r3, [r11, #-216]
   23e90: e15b3db8     	ldrh	r3, [r11, #-216]
   23e94: e1a03423     	lsr	r3, r3, #8
   23e98: e6ff3073     	uxth	r3, r3
   23e9c: e1a02003     	mov	r2, r3
   23ea0: e15b3db8     	ldrh	r3, [r11, #-216]
   23ea4: e1a03403     	lsl	r3, r3, #8
   23ea8: e1a03803     	lsl	r3, r3, #16
   23eac: e1a03823     	lsr	r3, r3, #16
   23eb0: e1823003     	orr	r3, r2, r3
   23eb4: e6ff2073     	uxth	r2, r3
   23eb8: e51b30dc     	ldr	r3, [r11, #-0xdc]
   23ebc: e20210ff     	and	r1, r2, #255
   23ec0: e3a00000     	mov	r0, #0
   23ec4: e1801001     	orr	r1, r0, r1
   23ec8: e5c3100c     	strb	r1, [r3, #0xc]
   23ecc: e1a02422     	lsr	r2, r2, #8
   23ed0: e6ff2072     	uxth	r2, r2
   23ed4: e3a01000     	mov	r1, #0
   23ed8: e1812002     	orr	r2, r1, r2
   23edc: e5c3200d     	strb	r2, [r3, #0xd]
   23ee0: ea000043     	b	0x23ff4 <calculate_header_and_footer+0xfb8> @ imm = #0x10c
   23ee4: e3a03003     	mov	r3, #3
   23ee8: e14b3db6     	strh	r3, [r11, #-214]
   23eec: e15b3db6     	ldrh	r3, [r11, #-214]
   23ef0: e1a03423     	lsr	r3, r3, #8
   23ef4: e6ff3073     	uxth	r3, r3
   23ef8: e1a02003     	mov	r2, r3
   23efc: e15b3db6     	ldrh	r3, [r11, #-214]
   23f00: e1a03403     	lsl	r3, r3, #8
   23f04: e1a03803     	lsl	r3, r3, #16
   23f08: e1a03823     	lsr	r3, r3, #16
   23f0c: e1823003     	orr	r3, r2, r3
   23f10: e6ff2073     	uxth	r2, r3
   23f14: e51b30dc     	ldr	r3, [r11, #-0xdc]
   23f18: e20210ff     	and	r1, r2, #255
   23f1c: e3a00000     	mov	r0, #0
   23f20: e1801001     	orr	r1, r0, r1
   23f24: e5c3100c     	strb	r1, [r3, #0xc]
   23f28: e1a02422     	lsr	r2, r2, #8
   23f2c: e6ff2072     	uxth	r2, r2
   23f30: e3a01000     	mov	r1, #0
   23f34: e1812002     	orr	r2, r1, r2
   23f38: e5c3200d     	strb	r2, [r3, #0xd]
   23f3c: ea00002c     	b	0x23ff4 <calculate_header_and_footer+0xfb8> @ imm = #0xb0
   23f40: e3a03004     	mov	r3, #4
   23f44: e14b3db4     	strh	r3, [r11, #-212]
   23f48: e15b3db4     	ldrh	r3, [r11, #-212]
   23f4c: e1a03423     	lsr	r3, r3, #8
   23f50: e6ff3073     	uxth	r3, r3
   23f54: e1a02003     	mov	r2, r3
   23f58: e15b3db4     	ldrh	r3, [r11, #-212]
   23f5c: e1a03403     	lsl	r3, r3, #8
   23f60: e1a03803     	lsl	r3, r3, #16
   23f64: e1a03823     	lsr	r3, r3, #16
   23f68: e1823003     	orr	r3, r2, r3
   23f6c: e6ff2073     	uxth	r2, r3
   23f70: e51b30dc     	ldr	r3, [r11, #-0xdc]
   23f74: e20210ff     	and	r1, r2, #255
   23f78: e3a00000     	mov	r0, #0
   23f7c: e1801001     	orr	r1, r0, r1
   23f80: e5c3100c     	strb	r1, [r3, #0xc]
   23f84: e1a02422     	lsr	r2, r2, #8
   23f88: e6ff2072     	uxth	r2, r2
   23f8c: e3a01000     	mov	r1, #0
   23f90: e1812002     	orr	r2, r1, r2
   23f94: e5c3200d     	strb	r2, [r3, #0xd]
   23f98: ea000015     	b	0x23ff4 <calculate_header_and_footer+0xfb8> @ imm = #0x54
   23f9c: e3e03000     	mvn	r3, #0
   23fa0: e14b3db2     	strh	r3, [r11, #-210]
   23fa4: e15b3db2     	ldrh	r3, [r11, #-210]
   23fa8: e1a03423     	lsr	r3, r3, #8
   23fac: e6ff3073     	uxth	r3, r3
   23fb0: e1a02003     	mov	r2, r3
   23fb4: e15b3db2     	ldrh	r3, [r11, #-210]
   23fb8: e1a03403     	lsl	r3, r3, #8
   23fbc: e1a03803     	lsl	r3, r3, #16
   23fc0: e1a03823     	lsr	r3, r3, #16
   23fc4: e1823003     	orr	r3, r2, r3
   23fc8: e6ff2073     	uxth	r2, r3
   23fcc: e51b30dc     	ldr	r3, [r11, #-0xdc]
   23fd0: e20210ff     	and	r1, r2, #255
   23fd4: e3a00000     	mov	r0, #0
   23fd8: e1801001     	orr	r1, r0, r1
   23fdc: e5c3100c     	strb	r1, [r3, #0xc]
   23fe0: e1a02422     	lsr	r2, r2, #8
   23fe4: e6ff2072     	uxth	r2, r2
   23fe8: e3a01000     	mov	r1, #0
   23fec: e1812002     	orr	r2, r1, r2
   23ff0: e5c3200d     	strb	r2, [r3, #0xd]
   23ff4: e51b310c     	ldr	r3, [r11, #-0x10c]
   23ff8: e283300e     	add	r3, r3, #14
   23ffc: e50b310c     	str	r3, [r11, #-0x10c]
   24000: e51b210c     	ldr	r2, [r11, #-0x10c]
   24004: e51b3108     	ldr	r3, [r11, #-0x108]
   24008: e0633002     	rsb	r3, r3, r2
   2400c: e243300c     	sub	r3, r3, #12
   24010: e2033001     	and	r3, r3, #1
   24014: e6ef3073     	uxtb	r3, r3
   24018: e3530000     	cmp	r3, #0
   2401c: 0a000004     	beq	0x24034 <calculate_header_and_footer+0xff8> @ imm = #0x10
   24020: e51b210c     	ldr	r2, [r11, #-0x10c]
   24024: e51b3108     	ldr	r3, [r11, #-0x108]
   24028: e0633002     	rsb	r3, r3, r2
   2402c: e243300b     	sub	r3, r3, #11
   24030: ea000003     	b	0x24044 <calculate_header_and_footer+0x1008> @ imm = #0xc
   24034: e51b210c     	ldr	r2, [r11, #-0x10c]
   24038: e51b3108     	ldr	r3, [r11, #-0x108]
   2403c: e0633002     	rsb	r3, r3, r2
   24040: e243300c     	sub	r3, r3, #12
   24044: e1a02003     	mov	r2, r3
   24048: e3a03000     	mov	r3, #0
   2404c: e51f1340     	ldr	r1, [pc, #-0x340]       @ 0x23d14 <calculate_header_and_footer+0xcd8>
   24050: e24b000c     	sub	r0, r11, #12
   24054: e18020f1     	strd	r2, r3, [r0, r1]
   24058: e51f234c     	ldr	r2, [pc, #-0x34c]       @ 0x23d14 <calculate_header_and_footer+0xcd8>
   2405c: e3a03004     	mov	r3, #4
   24060: e24b100c     	sub	r1, r11, #12
   24064: e0812002     	add	r2, r1, r2
   24068: e0823003     	add	r3, r2, r3
   2406c: e5934000     	ldr	r4, [r3]
   24070: e1a02c24     	lsr	r2, r4, #24
   24074: e20438ff     	and	r3, r4, #16711680
   24078: e1a03423     	lsr	r3, r3, #8
   2407c: e1822003     	orr	r2, r2, r3
   24080: e2043cff     	and	r3, r4, #65280
   24084: e1a03403     	lsl	r3, r3, #8
   24088: e1822003     	orr	r2, r2, r3
   2408c: e1a03c04     	lsl	r3, r4, #24
   24090: e1822003     	orr	r2, r2, r3
   24094: e51f3384     	ldr	r3, [pc, #-0x384]       @ 0x23d18 <calculate_header_and_footer+0xcdc>
   24098: e24b000c     	sub	r0, r11, #12
   2409c: e7802003     	str	r2, [r0, r3]
   240a0: e51f3394     	ldr	r3, [pc, #-0x394]       @ 0x23d14 <calculate_header_and_footer+0xcd8>
   240a4: e24b100c     	sub	r1, r11, #12
   240a8: e7914003     	ldr	r4, [r1, r3]
   240ac: e1a02c24     	lsr	r2, r4, #24
   240b0: e20438ff     	and	r3, r4, #16711680
   240b4: e1a03423     	lsr	r3, r3, #8
   240b8: e1822003     	orr	r2, r2, r3
   240bc: e2043cff     	and	r3, r4, #65280
   240c0: e1a03403     	lsl	r3, r3, #8
   240c4: e1822003     	orr	r2, r2, r3
   240c8: e1a03c04     	lsl	r3, r4, #24
   240cc: e1822003     	orr	r2, r2, r3
   240d0: e51f13c0     	ldr	r1, [pc, #-0x3c0]       @ 0x23d18 <calculate_header_and_footer+0xcdc>
   240d4: e3a03004     	mov	r3, #4
   240d8: e24b000c     	sub	r0, r11, #12
   240dc: e0801001     	add	r1, r0, r1
   240e0: e0813003     	add	r3, r1, r3
   240e4: e5832000     	str	r2, [r3]
   240e8: e51f33d8     	ldr	r3, [pc, #-0x3d8]       @ 0x23d18 <calculate_header_and_footer+0xcdc>
   240ec: e24b100c     	sub	r1, r11, #12
   240f0: e18320d1     	ldrd	r2, r3, [r3, r1]
   240f4: e51b1110     	ldr	r1, [r11, #-0x110]
   240f8: e20200ff     	and	r0, r2, #255
   240fc: e3a0c000     	mov	r12, #0
   24100: e18c0000     	orr	r0, r12, r0
   24104: e5c10004     	strb	r0, [r1, #0x4]
   24108: e1a00422     	lsr	r0, r2, #8
   2410c: e20000ff     	and	r0, r0, #255
   24110: e3a0c000     	mov	r12, #0
   24114: e18c0000     	orr	r0, r12, r0
   24118: e5c10005     	strb	r0, [r1, #0x5]
   2411c: e1a00822     	lsr	r0, r2, #16
   24120: e20000ff     	and	r0, r0, #255
   24124: e3a0c000     	mov	r12, #0
   24128: e18c0000     	orr	r0, r12, r0
   2412c: e5c10006     	strb	r0, [r1, #0x6]
   24130: e1a00c22     	lsr	r0, r2, #24
   24134: e3a0c000     	mov	r12, #0
   24138: e18c0000     	orr	r0, r12, r0
   2413c: e5c10007     	strb	r0, [r1, #0x7]
   24140: e20300ff     	and	r0, r3, #255
   24144: e3a0c000     	mov	r12, #0
   24148: e18c0000     	orr	r0, r12, r0
   2414c: e5c10008     	strb	r0, [r1, #0x8]
   24150: e1a00423     	lsr	r0, r3, #8
   24154: e20000ff     	and	r0, r0, #255
   24158: e3a0c000     	mov	r12, #0
   2415c: e18c0000     	orr	r0, r12, r0
   24160: e5c10009     	strb	r0, [r1, #0x9]
   24164: e1a00823     	lsr	r0, r3, #16
   24168: e20000ff     	and	r0, r0, #255
   2416c: e3a0c000     	mov	r12, #0
   24170: e18c0000     	orr	r0, r12, r0
   24174: e5c1000a     	strb	r0, [r1, #0xa]
   24178: e1a03c23     	lsr	r3, r3, #24
   2417c: e3a02000     	mov	r2, #0
   24180: e1823003     	orr	r3, r2, r3
   24184: e5c1300b     	strb	r3, [r1, #0xb]
   24188: e51b3460     	ldr	r3, [r11, #-0x460]
   2418c: e593303c     	ldr	r3, [r3, #0x3c]
   24190: e3530000     	cmp	r3, #0
   24194: 0a000071     	beq	0x24360 <calculate_header_and_footer+0x1324> @ imm = #0x1c4
   24198: e51b310c     	ldr	r3, [r11, #-0x10c]
   2419c: e50b30d0     	str	r3, [r11, #-0xd0]
   241a0: e51b30d0     	ldr	r3, [r11, #-0xd0]
   241a4: e3a02000     	mov	r2, #0
   241a8: e3822044     	orr	r2, r2, #68
   241ac: e5c32000     	strb	r2, [r3]
   241b0: e3a02000     	mov	r2, #0
   241b4: e3822053     	orr	r2, r2, #83
   241b8: e5c32001     	strb	r2, [r3, #0x1]
   241bc: e3a02000     	mov	r2, #0
   241c0: e3822044     	orr	r2, r2, #68
   241c4: e5c32002     	strb	r2, [r3, #0x2]
   241c8: e3a02000     	mov	r2, #0
   241cc: e3822020     	orr	r2, r2, #32
   241d0: e5c32003     	strb	r2, [r3, #0x3]
   241d4: e51b3100     	ldr	r3, [r11, #-0x100]
   241d8: e1c321d8     	ldrd	r2, r3, [r3, #24]
   241dc: e1a03002     	mov	r3, r2
   241e0: e2033001     	and	r3, r3, #1
   241e4: e6ef3073     	uxtb	r3, r3
   241e8: e3530000     	cmp	r3, #0
   241ec: 0a000006     	beq	0x2420c <calculate_header_and_footer+0x11d0> @ imm = #0x18
   241f0: e51b3100     	ldr	r3, [r11, #-0x100]
   241f4: e1c301d8     	ldrd	r0, r1, [r3, #24]
   241f8: e3a02001     	mov	r2, #1
   241fc: e3a03000     	mov	r3, #0
   24200: e0922000     	adds	r2, r2, r0
   24204: e0a33001     	adc	r3, r3, r1
   24208: ea000001     	b	0x24214 <calculate_header_and_footer+0x11d8> @ imm = #0x4
   2420c: e51b3100     	ldr	r3, [r11, #-0x100]
   24210: e1c321d8     	ldrd	r2, r3, [r3, #24]
   24214: e51f1500     	ldr	r1, [pc, #-0x500]       @ 0x23d1c <calculate_header_and_footer+0xce0>
   24218: e24b000c     	sub	r0, r11, #12
   2421c: e18020f1     	strd	r2, r3, [r0, r1]
   24220: e51f250c     	ldr	r2, [pc, #-0x50c]       @ 0x23d1c <calculate_header_and_footer+0xce0>
   24224: e3a03004     	mov	r3, #4
   24228: e24b100c     	sub	r1, r11, #12
   2422c: e0812002     	add	r2, r1, r2
   24230: e0823003     	add	r3, r2, r3
   24234: e5934000     	ldr	r4, [r3]
   24238: e1a02c24     	lsr	r2, r4, #24
   2423c: e20438ff     	and	r3, r4, #16711680
   24240: e1a03423     	lsr	r3, r3, #8
   24244: e1822003     	orr	r2, r2, r3
   24248: e2043cff     	and	r3, r4, #65280
   2424c: e1a03403     	lsl	r3, r3, #8
   24250: e1822003     	orr	r2, r2, r3
   24254: e1a03c04     	lsl	r3, r4, #24
   24258: e1822003     	orr	r2, r2, r3
   2425c: e51f3544     	ldr	r3, [pc, #-0x544]       @ 0x23d20 <calculate_header_and_footer+0xce4>
   24260: e24b000c     	sub	r0, r11, #12
   24264: e7802003     	str	r2, [r0, r3]
   24268: e51f3554     	ldr	r3, [pc, #-0x554]       @ 0x23d1c <calculate_header_and_footer+0xce0>
   2426c: e24b100c     	sub	r1, r11, #12
   24270: e7914003     	ldr	r4, [r1, r3]
   24274: e1a02c24     	lsr	r2, r4, #24
   24278: e20438ff     	and	r3, r4, #16711680
   2427c: e1a03423     	lsr	r3, r3, #8
   24280: e1822003     	orr	r2, r2, r3
   24284: e2043cff     	and	r3, r4, #65280
   24288: e1a03403     	lsl	r3, r3, #8
   2428c: e1822003     	orr	r2, r2, r3
   24290: e1a03c04     	lsl	r3, r4, #24
   24294: e1822003     	orr	r2, r2, r3
   24298: e51f1580     	ldr	r1, [pc, #-0x580]       @ 0x23d20 <calculate_header_and_footer+0xce4>
   2429c: e3a03004     	mov	r3, #4
   242a0: e24b000c     	sub	r0, r11, #12
   242a4: e0801001     	add	r1, r0, r1
   242a8: e0813003     	add	r3, r1, r3
   242ac: e5832000     	str	r2, [r3]
   242b0: e51f3598     	ldr	r3, [pc, #-0x598]       @ 0x23d20 <calculate_header_and_footer+0xce4>
   242b4: e24b100c     	sub	r1, r11, #12
   242b8: e18320d1     	ldrd	r2, r3, [r3, r1]
   242bc: e51b10d0     	ldr	r1, [r11, #-0xd0]
   242c0: e20200ff     	and	r0, r2, #255
   242c4: e3a0c000     	mov	r12, #0
   242c8: e18c0000     	orr	r0, r12, r0
   242cc: e5c10004     	strb	r0, [r1, #0x4]
   242d0: e1a00422     	lsr	r0, r2, #8
   242d4: e20000ff     	and	r0, r0, #255
   242d8: e3a0c000     	mov	r12, #0
   242dc: e18c0000     	orr	r0, r12, r0
   242e0: e5c10005     	strb	r0, [r1, #0x5]
   242e4: e1a00822     	lsr	r0, r2, #16
   242e8: e20000ff     	and	r0, r0, #255
   242ec: e3a0c000     	mov	r12, #0
   242f0: e18c0000     	orr	r0, r12, r0
   242f4: e5c10006     	strb	r0, [r1, #0x6]
   242f8: e1a00c22     	lsr	r0, r2, #24
   242fc: e3a0c000     	mov	r12, #0
   24300: e18c0000     	orr	r0, r12, r0
   24304: e5c10007     	strb	r0, [r1, #0x7]
   24308: e20300ff     	and	r0, r3, #255
   2430c: e3a0c000     	mov	r12, #0
   24310: e18c0000     	orr	r0, r12, r0
   24314: e5c10008     	strb	r0, [r1, #0x8]
   24318: e1a00423     	lsr	r0, r3, #8
   2431c: e20000ff     	and	r0, r0, #255
   24320: e3a0c000     	mov	r12, #0
   24324: e18c0000     	orr	r0, r12, r0
   24328: e5c10009     	strb	r0, [r1, #0x9]
   2432c: e1a00823     	lsr	r0, r3, #16
   24330: e20000ff     	and	r0, r0, #255
   24334: e3a0c000     	mov	r12, #0
   24338: e18c0000     	orr	r0, r12, r0
   2433c: e5c1000a     	strb	r0, [r1, #0xa]
   24340: e1a03c23     	lsr	r3, r3, #24
   24344: e3a02000     	mov	r2, #0
   24348: e1823003     	orr	r3, r2, r3
   2434c: e5c1300b     	strb	r3, [r1, #0xb]
   24350: e51b310c     	ldr	r3, [r11, #-0x10c]
   24354: e283300c     	add	r3, r3, #12
   24358: e50b310c     	str	r3, [r11, #-0x10c]
   2435c: ea0000eb     	b	0x24710 <calculate_header_and_footer+0x16d4> @ imm = #0x3ac
   24360: e51b310c     	ldr	r3, [r11, #-0x10c]
   24364: e50b30cc     	str	r3, [r11, #-0xcc]
   24368: e51b30cc     	ldr	r3, [r11, #-0xcc]
   2436c: e3a02000     	mov	r2, #0
   24370: e3822044     	orr	r2, r2, #68
   24374: e5c32000     	strb	r2, [r3]
   24378: e3a02000     	mov	r2, #0
   2437c: e3822053     	orr	r2, r2, #83
   24380: e5c32001     	strb	r2, [r3, #0x1]
   24384: e3a02000     	mov	r2, #0
   24388: e3822054     	orr	r2, r2, #84
   2438c: e5c32002     	strb	r2, [r3, #0x2]
   24390: e3a02000     	mov	r2, #0
   24394: e3822020     	orr	r2, r2, #32
   24398: e5c32003     	strb	r2, [r3, #0x3]
   2439c: e51b310c     	ldr	r3, [r11, #-0x10c]
   243a0: e283300c     	add	r3, r3, #12
   243a4: e50b310c     	str	r3, [r11, #-0x10c]
   243a8: e51b310c     	ldr	r3, [r11, #-0x10c]
   243ac: e50b30c8     	str	r3, [r11, #-0xc8]
   243b0: e51b30c8     	ldr	r3, [r11, #-0xc8]
   243b4: e3a02000     	mov	r2, #0
   243b8: e3822046     	orr	r2, r2, #70
   243bc: e5c32000     	strb	r2, [r3]
   243c0: e3a02000     	mov	r2, #0
   243c4: e3822052     	orr	r2, r2, #82
   243c8: e5c32001     	strb	r2, [r3, #0x1]
   243cc: e3a02000     	mov	r2, #0
   243d0: e3822054     	orr	r2, r2, #84
   243d4: e5c32002     	strb	r2, [r3, #0x2]
   243d8: e3a02000     	mov	r2, #0
   243dc: e3822045     	orr	r2, r2, #69
   243e0: e5c32003     	strb	r2, [r3, #0x3]
   243e4: e3a0304b     	mov	r3, #75
   243e8: e14b3cb2     	strh	r3, [r11, #-194]
   243ec: e15b3cb2     	ldrh	r3, [r11, #-194]
   243f0: e1a03423     	lsr	r3, r3, #8
   243f4: e6ff3073     	uxth	r3, r3
   243f8: e1a02003     	mov	r2, r3
   243fc: e15b3cb2     	ldrh	r3, [r11, #-194]
   24400: e1a03403     	lsl	r3, r3, #8
   24404: e1a03803     	lsl	r3, r3, #16
   24408: e1a03823     	lsr	r3, r3, #16
   2440c: e1823003     	orr	r3, r2, r3
   24410: e6ff2073     	uxth	r2, r3
   24414: e51b30c8     	ldr	r3, [r11, #-0xc8]
   24418: e20210ff     	and	r1, r2, #255
   2441c: e3a00000     	mov	r0, #0
   24420: e1801001     	orr	r1, r0, r1
   24424: e5c31010     	strb	r1, [r3, #0x10]
   24428: e1a02422     	lsr	r2, r2, #8
   2442c: e6ff2072     	uxth	r2, r2
   24430: e3a01000     	mov	r1, #0
   24434: e1812002     	orr	r2, r1, r2
   24438: e5c32011     	strb	r2, [r3, #0x11]
   2443c: e51b3100     	ldr	r3, [r11, #-0x100]
   24440: e5934010     	ldr	r4, [r3, #0x10]
   24444: e1a02c24     	lsr	r2, r4, #24
   24448: e20438ff     	and	r3, r4, #16711680
   2444c: e1a03423     	lsr	r3, r3, #8
   24450: e1822003     	orr	r2, r2, r3
   24454: e2043cff     	and	r3, r4, #65280
   24458: e1a03403     	lsl	r3, r3, #8
   2445c: e1822003     	orr	r2, r2, r3
   24460: e1a03c04     	lsl	r3, r4, #24
   24464: e1822003     	orr	r2, r2, r3
   24468: e51b30c8     	ldr	r3, [r11, #-0xc8]
   2446c: e20210ff     	and	r1, r2, #255
   24470: e3a00000     	mov	r0, #0
   24474: e1801001     	orr	r1, r0, r1
   24478: e5c3100c     	strb	r1, [r3, #0xc]
   2447c: e1a01422     	lsr	r1, r2, #8
   24480: e20110ff     	and	r1, r1, #255
   24484: e3a00000     	mov	r0, #0
   24488: e1801001     	orr	r1, r0, r1
   2448c: e5c3100d     	strb	r1, [r3, #0xd]
   24490: e1a01822     	lsr	r1, r2, #16
   24494: e20110ff     	and	r1, r1, #255
   24498: e3a00000     	mov	r0, #0
   2449c: e1801001     	orr	r1, r0, r1
   244a0: e5c3100e     	strb	r1, [r3, #0xe]
   244a4: e1a02c22     	lsr	r2, r2, #24
   244a8: e3a01000     	mov	r1, #0
   244ac: e1812002     	orr	r2, r1, r2
   244b0: e5c3200f     	strb	r2, [r3, #0xf]
   244b4: e51f1798     	ldr	r1, [pc, #-0x798]       @ 0x23d24 <calculate_header_and_footer+0xce8>
   244b8: e3a02000     	mov	r2, #0
   244bc: e3a03406     	mov	r3, #100663296
   244c0: e24b000c     	sub	r0, r11, #12
   244c4: e18020f1     	strd	r2, r3, [r0, r1]
   244c8: e51f37ac     	ldr	r3, [pc, #-0x7ac]       @ 0x23d24 <calculate_header_and_footer+0xce8>
   244cc: e24b100c     	sub	r1, r11, #12
   244d0: e18320d1     	ldrd	r2, r3, [r3, r1]
   244d4: e51b10c8     	ldr	r1, [r11, #-0xc8]
   244d8: e20200ff     	and	r0, r2, #255
   244dc: e3a0c000     	mov	r12, #0
   244e0: e18c0000     	orr	r0, r12, r0
   244e4: e5c10004     	strb	r0, [r1, #0x4]
   244e8: e1a00422     	lsr	r0, r2, #8
   244ec: e20000ff     	and	r0, r0, #255
   244f0: e3a0c000     	mov	r12, #0
   244f4: e18c0000     	orr	r0, r12, r0
   244f8: e5c10005     	strb	r0, [r1, #0x5]
   244fc: e1a00822     	lsr	r0, r2, #16
   24500: e20000ff     	and	r0, r0, #255
   24504: e3a0c000     	mov	r12, #0
   24508: e18c0000     	orr	r0, r12, r0
   2450c: e5c10006     	strb	r0, [r1, #0x6]
   24510: e1a00c22     	lsr	r0, r2, #24
   24514: e3a0c000     	mov	r12, #0
   24518: e18c0000     	orr	r0, r12, r0
   2451c: e5c10007     	strb	r0, [r1, #0x7]
   24520: e20300ff     	and	r0, r3, #255
   24524: e3a0c000     	mov	r12, #0
   24528: e18c0000     	orr	r0, r12, r0
   2452c: e5c10008     	strb	r0, [r1, #0x8]
   24530: e1a00423     	lsr	r0, r3, #8
   24534: e20000ff     	and	r0, r0, #255
   24538: e3a0c000     	mov	r12, #0
   2453c: e18c0000     	orr	r0, r12, r0
   24540: e5c10009     	strb	r0, [r1, #0x9]
   24544: e1a00823     	lsr	r0, r3, #16
   24548: e20000ff     	and	r0, r0, #255
   2454c: e3a0c000     	mov	r12, #0
   24550: e18c0000     	orr	r0, r12, r0
   24554: e5c1000a     	strb	r0, [r1, #0xa]
   24558: e1a03c23     	lsr	r3, r3, #24
   2455c: e3a02000     	mov	r2, #0
   24560: e1823003     	orr	r3, r2, r3
   24564: e5c1300b     	strb	r3, [r1, #0xb]
   24568: e51b3100     	ldr	r3, [r11, #-0x100]
   2456c: e1c301d8     	ldrd	r0, r1, [r3, #24]
   24570: e3a02012     	mov	r2, #18
   24574: e3a03000     	mov	r3, #0
   24578: e0922000     	adds	r2, r2, r0
   2457c: e0a33001     	adc	r3, r3, r1
   24580: e1a03002     	mov	r3, r2
   24584: e2033001     	and	r3, r3, #1
   24588: e6ef3073     	uxtb	r3, r3
   2458c: e3530000     	cmp	r3, #0
   24590: 0a000006     	beq	0x245b0 <calculate_header_and_footer+0x1574> @ imm = #0x18
   24594: e51b3100     	ldr	r3, [r11, #-0x100]
   24598: e1c301d8     	ldrd	r0, r1, [r3, #24]
   2459c: e3a02013     	mov	r2, #19
   245a0: e3a03000     	mov	r3, #0
   245a4: e0922000     	adds	r2, r2, r0
   245a8: e0a33001     	adc	r3, r3, r1
   245ac: ea000005     	b	0x245c8 <calculate_header_and_footer+0x158c> @ imm = #0x14
   245b0: e51b3100     	ldr	r3, [r11, #-0x100]
   245b4: e1c301d8     	ldrd	r0, r1, [r3, #24]
   245b8: e3a02012     	mov	r2, #18
   245bc: e3a03000     	mov	r3, #0
   245c0: e0922000     	adds	r2, r2, r0
   245c4: e0a33001     	adc	r3, r3, r1
   245c8: e51f18a8     	ldr	r1, [pc, #-0x8a8]       @ 0x23d28 <calculate_header_and_footer+0xcec>
   245cc: e24b000c     	sub	r0, r11, #12
   245d0: e18020f1     	strd	r2, r3, [r0, r1]
   245d4: e51f28b4     	ldr	r2, [pc, #-0x8b4]       @ 0x23d28 <calculate_header_and_footer+0xcec>
   245d8: e3a03004     	mov	r3, #4
   245dc: e24b100c     	sub	r1, r11, #12
   245e0: e0812002     	add	r2, r1, r2
   245e4: e0823003     	add	r3, r2, r3
   245e8: e5934000     	ldr	r4, [r3]
   245ec: e1a02c24     	lsr	r2, r4, #24
   245f0: e20438ff     	and	r3, r4, #16711680
   245f4: e1a03423     	lsr	r3, r3, #8
   245f8: e1822003     	orr	r2, r2, r3
   245fc: e2043cff     	and	r3, r4, #65280
   24600: e1a03403     	lsl	r3, r3, #8
   24604: e1822003     	orr	r2, r2, r3
   24608: e1a03c04     	lsl	r3, r4, #24
   2460c: e1822003     	orr	r2, r2, r3
   24610: e51f38ec     	ldr	r3, [pc, #-0x8ec]       @ 0x23d2c <calculate_header_and_footer+0xcf0>
   24614: e24b000c     	sub	r0, r11, #12
   24618: e7802003     	str	r2, [r0, r3]
   2461c: e51f38fc     	ldr	r3, [pc, #-0x8fc]       @ 0x23d28 <calculate_header_and_footer+0xcec>
   24620: e24b100c     	sub	r1, r11, #12
   24624: e7914003     	ldr	r4, [r1, r3]
   24628: e1a02c24     	lsr	r2, r4, #24
   2462c: e20438ff     	and	r3, r4, #16711680
   24630: e1a03423     	lsr	r3, r3, #8
   24634: e1822003     	orr	r2, r2, r3
   24638: e2043cff     	and	r3, r4, #65280
   2463c: e1a03403     	lsl	r3, r3, #8
   24640: e1822003     	orr	r2, r2, r3
   24644: e1a03c04     	lsl	r3, r4, #24
   24648: e1822003     	orr	r2, r2, r3
   2464c: e51f1928     	ldr	r1, [pc, #-0x928]       @ 0x23d2c <calculate_header_and_footer+0xcf0>
   24650: e3a03004     	mov	r3, #4
   24654: e24b000c     	sub	r0, r11, #12
   24658: e0801001     	add	r1, r0, r1
   2465c: e0813003     	add	r3, r1, r3
   24660: e5832000     	str	r2, [r3]
   24664: e51f3940     	ldr	r3, [pc, #-0x940]       @ 0x23d2c <calculate_header_and_footer+0xcf0>
   24668: e24b100c     	sub	r1, r11, #12
   2466c: e18320d1     	ldrd	r2, r3, [r3, r1]
   24670: e51b10cc     	ldr	r1, [r11, #-0xcc]
   24674: e20200ff     	and	r0, r2, #255
   24678: e3a0c000     	mov	r12, #0
   2467c: e18c0000     	orr	r0, r12, r0
   24680: e5c10004     	strb	r0, [r1, #0x4]
   24684: e1a00422     	lsr	r0, r2, #8
   24688: e20000ff     	and	r0, r0, #255
   2468c: e3a0c000     	mov	r12, #0
   24690: e18c0000     	orr	r0, r12, r0
   24694: e5c10005     	strb	r0, [r1, #0x5]
   24698: e1a00822     	lsr	r0, r2, #16
   2469c: e20000ff     	and	r0, r0, #255
   246a0: e3a0c000     	mov	r12, #0
   246a4: e18c0000     	orr	r0, r12, r0
   246a8: e5c10006     	strb	r0, [r1, #0x6]
   246ac: e1a00c22     	lsr	r0, r2, #24
   246b0: e3a0c000     	mov	r12, #0
   246b4: e18c0000     	orr	r0, r12, r0
   246b8: e5c10007     	strb	r0, [r1, #0x7]
   246bc: e20300ff     	and	r0, r3, #255
   246c0: e3a0c000     	mov	r12, #0
   246c4: e18c0000     	orr	r0, r12, r0
   246c8: e5c10008     	strb	r0, [r1, #0x8]
   246cc: e1a00423     	lsr	r0, r3, #8
   246d0: e20000ff     	and	r0, r0, #255
   246d4: e3a0c000     	mov	r12, #0
   246d8: e18c0000     	orr	r0, r12, r0
   246dc: e5c10009     	strb	r0, [r1, #0x9]
   246e0: e1a00823     	lsr	r0, r3, #16
   246e4: e20000ff     	and	r0, r0, #255
   246e8: e3a0c000     	mov	r12, #0
   246ec: e18c0000     	orr	r0, r12, r0
   246f0: e5c1000a     	strb	r0, [r1, #0xa]
   246f4: e1a03c23     	lsr	r3, r3, #24
   246f8: e3a02000     	mov	r2, #0
   246fc: e1823003     	orr	r3, r2, r3
   24700: e5c1300b     	strb	r3, [r1, #0xb]
   24704: e51b310c     	ldr	r3, [r11, #-0x10c]
   24708: e2833012     	add	r3, r3, #18
   2470c: e50b310c     	str	r3, [r11, #-0x10c]
   24710: e51b3100     	ldr	r3, [r11, #-0x100]
   24714: e3a02000     	mov	r2, #0
   24718: e583200c     	str	r2, [r3, #0xc]
   2471c: e51b3460     	ldr	r3, [r11, #-0x460]
   24720: e593303c     	ldr	r3, [r3, #0x3c]
   24724: e3530000     	cmp	r3, #0
   24728: 1a000168     	bne	0x24cd0 <calculate_header_and_footer+0x1c94> @ imm = #0x5a0
   2472c: e51b3100     	ldr	r3, [r11, #-0x100]
   24730: e5933010     	ldr	r3, [r3, #0x10]
   24734: e3530000     	cmp	r3, #0
   24738: 0a000164     	beq	0x24cd0 <calculate_header_and_footer+0x1c94> @ imm = #0x590
   2473c: e51b3100     	ldr	r3, [r11, #-0x100]
   24740: e5931008     	ldr	r1, [r3, #0x8]
   24744: e51b3100     	ldr	r3, [r11, #-0x100]
   24748: e5932024     	ldr	r2, [r3, #0x24]
   2474c: e1a03002     	mov	r3, r2
   24750: e1a03083     	lsl	r3, r3, #1
   24754: e0833002     	add	r3, r3, r2
   24758: e1a03103     	lsl	r3, r3, #2
   2475c: e2833901     	add	r3, r3, #16384
   24760: e1a00001     	mov	r0, r1
   24764: e1a01003     	mov	r1, r3
   24768: ebffa006     	bl	0xc788 <realloc@plt>    @ imm = #-0x17fe8
   2476c: e1a03000     	mov	r3, r0
   24770: e1a02003     	mov	r2, r3
   24774: e51b3100     	ldr	r3, [r11, #-0x100]
   24778: e5832008     	str	r2, [r3, #0x8]
   2477c: e51b3100     	ldr	r3, [r11, #-0x100]
   24780: e5932008     	ldr	r2, [r3, #0x8]
   24784: e51b3100     	ldr	r3, [r11, #-0x100]
   24788: e593300c     	ldr	r3, [r3, #0xc]
   2478c: e0823003     	add	r3, r2, r3
   24790: e50b30b8     	str	r3, [r11, #-0xb8]
   24794: e51b30b8     	ldr	r3, [r11, #-0xb8]
   24798: e50b30bc     	str	r3, [r11, #-0xbc]
   2479c: e51b30bc     	ldr	r3, [r11, #-0xbc]
   247a0: e3a02000     	mov	r2, #0
   247a4: e3822044     	orr	r2, r2, #68
   247a8: e5c32000     	strb	r2, [r3]
   247ac: e3a02000     	mov	r2, #0
   247b0: e3822053     	orr	r2, r2, #83
   247b4: e5c32001     	strb	r2, [r3, #0x1]
   247b8: e3a02000     	mov	r2, #0
   247bc: e3822054     	orr	r2, r2, #84
   247c0: e5c32002     	strb	r2, [r3, #0x2]
   247c4: e3a02000     	mov	r2, #0
   247c8: e3822049     	orr	r2, r2, #73
   247cc: e5c32003     	strb	r2, [r3, #0x3]
   247d0: e51b30b8     	ldr	r3, [r11, #-0xb8]
   247d4: e283300c     	add	r3, r3, #12
   247d8: e50b30b8     	str	r3, [r11, #-0xb8]
   247dc: e3a03000     	mov	r3, #0
   247e0: e50b30c0     	str	r3, [r11, #-0xc0]
   247e4: ea0000a3     	b	0x24a78 <calculate_header_and_footer+0x1a3c> @ imm = #0x28c
   247e8: e51b30b8     	ldr	r3, [r11, #-0xb8]
   247ec: e50b30b4     	str	r3, [r11, #-0xb4]
   247f0: e51b3100     	ldr	r3, [r11, #-0x100]
   247f4: e5931020     	ldr	r1, [r3, #0x20]
   247f8: e51b20c0     	ldr	r2, [r11, #-0xc0]
   247fc: e1a03002     	mov	r3, r2
   24800: e1a03083     	lsl	r3, r3, #1
   24804: e0833002     	add	r3, r3, r2
   24808: e1a03103     	lsl	r3, r3, #2
   2480c: e0813003     	add	r3, r1, r3
   24810: e5d32008     	ldrb	r2, [r3, #0x8]
   24814: e5d31009     	ldrb	r1, [r3, #0x9]
   24818: e1a01401     	lsl	r1, r1, #8
   2481c: e1812002     	orr	r2, r1, r2
   24820: e5d3100a     	ldrb	r1, [r3, #0xa]
   24824: e1a01801     	lsl	r1, r1, #16
   24828: e1812002     	orr	r2, r1, r2
   2482c: e5d3300b     	ldrb	r3, [r3, #0xb]
   24830: e1a03c03     	lsl	r3, r3, #24
   24834: e1833002     	orr	r3, r3, r2
   24838: e1a04003     	mov	r4, r3
   2483c: e1a02c24     	lsr	r2, r4, #24
   24840: e20438ff     	and	r3, r4, #16711680
   24844: e1a03423     	lsr	r3, r3, #8
   24848: e1822003     	orr	r2, r2, r3
   2484c: e2043cff     	and	r3, r4, #65280
   24850: e1a03403     	lsl	r3, r3, #8
   24854: e1822003     	orr	r2, r2, r3
   24858: e1a03c04     	lsl	r3, r4, #24
   2485c: e1822003     	orr	r2, r2, r3
   24860: e51b30b4     	ldr	r3, [r11, #-0xb4]
   24864: e20210ff     	and	r1, r2, #255
   24868: e3a00000     	mov	r0, #0
   2486c: e1801001     	orr	r1, r0, r1
   24870: e5c31008     	strb	r1, [r3, #0x8]
   24874: e1a01422     	lsr	r1, r2, #8
   24878: e20110ff     	and	r1, r1, #255
   2487c: e3a00000     	mov	r0, #0
   24880: e1801001     	orr	r1, r0, r1
   24884: e5c31009     	strb	r1, [r3, #0x9]
   24888: e1a01822     	lsr	r1, r2, #16
   2488c: e20110ff     	and	r1, r1, #255
   24890: e3a00000     	mov	r0, #0
   24894: e1801001     	orr	r1, r0, r1
   24898: e5c3100a     	strb	r1, [r3, #0xa]
   2489c: e1a02c22     	lsr	r2, r2, #24
   248a0: e3a01000     	mov	r1, #0
   248a4: e1812002     	orr	r2, r1, r2
   248a8: e5c3200b     	strb	r2, [r3, #0xb]
   248ac: e51b3100     	ldr	r3, [r11, #-0x100]
   248b0: e5931020     	ldr	r1, [r3, #0x20]
   248b4: e51b20c0     	ldr	r2, [r11, #-0xc0]
   248b8: e1a03002     	mov	r3, r2
   248bc: e1a03083     	lsl	r3, r3, #1
   248c0: e0833002     	add	r3, r3, r2
   248c4: e1a03103     	lsl	r3, r3, #2
   248c8: e0813003     	add	r3, r1, r3
   248cc: e5d32000     	ldrb	r2, [r3]
   248d0: e5d3c001     	ldrb	r12, [r3, #0x1]
   248d4: e1a0c40c     	lsl	r12, r12, #8
   248d8: e18c2002     	orr	r2, r12, r2
   248dc: e5d3c002     	ldrb	r12, [r3, #0x2]
   248e0: e1a0c80c     	lsl	r12, r12, #16
   248e4: e18c2002     	orr	r2, r12, r2
   248e8: e5d3c003     	ldrb	r12, [r3, #0x3]
   248ec: e1a0cc0c     	lsl	r12, r12, #24
   248f0: e18c2002     	orr	r2, r12, r2
   248f4: e1a00002     	mov	r0, r2
   248f8: e5d32004     	ldrb	r2, [r3, #0x4]
   248fc: e5d3c005     	ldrb	r12, [r3, #0x5]
   24900: e1a0c40c     	lsl	r12, r12, #8
   24904: e18c2002     	orr	r2, r12, r2
   24908: e5d3c006     	ldrb	r12, [r3, #0x6]
   2490c: e1a0c80c     	lsl	r12, r12, #16
   24910: e18c2002     	orr	r2, r12, r2
   24914: e5d33007     	ldrb	r3, [r3, #0x7]
   24918: e1a03c03     	lsl	r3, r3, #24
   2491c: e1833002     	orr	r3, r3, r2
   24920: e1a01003     	mov	r1, r3
   24924: e51f3bf8     	ldr	r3, [pc, #-0xbf8]       @ 0x23d34 <calculate_header_and_footer+0xcf8>
   24928: e24b200c     	sub	r2, r11, #12
   2492c: e18200f3     	strd	r0, r1, [r2, r3]
   24930: e51f2c04     	ldr	r2, [pc, #-0xc04]       @ 0x23d34 <calculate_header_and_footer+0xcf8>
   24934: e3a03004     	mov	r3, #4
   24938: e24b000c     	sub	r0, r11, #12
   2493c: e0802002     	add	r2, r0, r2
   24940: e0823003     	add	r3, r2, r3
   24944: e5934000     	ldr	r4, [r3]
   24948: e1a02c24     	lsr	r2, r4, #24
   2494c: e20438ff     	and	r3, r4, #16711680
   24950: e1a03423     	lsr	r3, r3, #8
   24954: e1822003     	orr	r2, r2, r3
   24958: e2043cff     	and	r3, r4, #65280
   2495c: e1a03403     	lsl	r3, r3, #8
   24960: e1822003     	orr	r2, r2, r3
   24964: e1a03c04     	lsl	r3, r4, #24
   24968: e1822003     	orr	r2, r2, r3
   2496c: e51f3c44     	ldr	r3, [pc, #-0xc44]       @ 0x23d30 <calculate_header_and_footer+0xcf4>
   24970: e24b100c     	sub	r1, r11, #12
   24974: e7812003     	str	r2, [r1, r3]
   24978: e51f3c4c     	ldr	r3, [pc, #-0xc4c]       @ 0x23d34 <calculate_header_and_footer+0xcf8>
   2497c: e24b200c     	sub	r2, r11, #12
   24980: e7924003     	ldr	r4, [r2, r3]
   24984: e1a02c24     	lsr	r2, r4, #24
   24988: e20438ff     	and	r3, r4, #16711680
   2498c: e1a03423     	lsr	r3, r3, #8
   24990: e1822003     	orr	r2, r2, r3
   24994: e2043cff     	and	r3, r4, #65280
   24998: e1a03403     	lsl	r3, r3, #8
   2499c: e1822003     	orr	r2, r2, r3
   249a0: e1a03c04     	lsl	r3, r4, #24
   249a4: e1822003     	orr	r2, r2, r3
   249a8: e59f18f4     	ldr	r1, [pc, #0x8f4]        @ 0x252a4 <calculate_header_and_footer+0x2268>
   249ac: e3a03004     	mov	r3, #4
   249b0: e24b000c     	sub	r0, r11, #12
   249b4: e0801001     	add	r1, r0, r1
   249b8: e0813003     	add	r3, r1, r3
   249bc: e5832000     	str	r2, [r3]
   249c0: e59f38dc     	ldr	r3, [pc, #0x8dc]        @ 0x252a4 <calculate_header_and_footer+0x2268>
   249c4: e24b100c     	sub	r1, r11, #12
   249c8: e18320d1     	ldrd	r2, r3, [r3, r1]
   249cc: e51b10b4     	ldr	r1, [r11, #-0xb4]
   249d0: e20200ff     	and	r0, r2, #255
   249d4: e3a0c000     	mov	r12, #0
   249d8: e18c0000     	orr	r0, r12, r0
   249dc: e5c10000     	strb	r0, [r1]
   249e0: e1a00422     	lsr	r0, r2, #8
   249e4: e20000ff     	and	r0, r0, #255
   249e8: e3a0c000     	mov	r12, #0
   249ec: e18c0000     	orr	r0, r12, r0
   249f0: e5c10001     	strb	r0, [r1, #0x1]
   249f4: e1a00822     	lsr	r0, r2, #16
   249f8: e20000ff     	and	r0, r0, #255
   249fc: e3a0c000     	mov	r12, #0
   24a00: e18c0000     	orr	r0, r12, r0
   24a04: e5c10002     	strb	r0, [r1, #0x2]
   24a08: e1a00c22     	lsr	r0, r2, #24
   24a0c: e3a0c000     	mov	r12, #0
   24a10: e18c0000     	orr	r0, r12, r0
   24a14: e5c10003     	strb	r0, [r1, #0x3]
   24a18: e20300ff     	and	r0, r3, #255
   24a1c: e3a0c000     	mov	r12, #0
   24a20: e18c0000     	orr	r0, r12, r0
   24a24: e5c10004     	strb	r0, [r1, #0x4]
   24a28: e1a00423     	lsr	r0, r3, #8
   24a2c: e20000ff     	and	r0, r0, #255
   24a30: e3a0c000     	mov	r12, #0
   24a34: e18c0000     	orr	r0, r12, r0
   24a38: e5c10005     	strb	r0, [r1, #0x5]
   24a3c: e1a00823     	lsr	r0, r3, #16
   24a40: e20000ff     	and	r0, r0, #255
   24a44: e3a0c000     	mov	r12, #0
   24a48: e18c0000     	orr	r0, r12, r0
   24a4c: e5c10006     	strb	r0, [r1, #0x6]
   24a50: e1a03c23     	lsr	r3, r3, #24
   24a54: e3a02000     	mov	r2, #0
   24a58: e1823003     	orr	r3, r2, r3
   24a5c: e5c13007     	strb	r3, [r1, #0x7]
   24a60: e51b30b8     	ldr	r3, [r11, #-0xb8]
   24a64: e283300c     	add	r3, r3, #12
   24a68: e50b30b8     	str	r3, [r11, #-0xb8]
   24a6c: e51b30c0     	ldr	r3, [r11, #-0xc0]
   24a70: e2833001     	add	r3, r3, #1
   24a74: e50b30c0     	str	r3, [r11, #-0xc0]
   24a78: e51b3100     	ldr	r3, [r11, #-0x100]
   24a7c: e5932010     	ldr	r2, [r3, #0x10]
   24a80: e51b30c0     	ldr	r3, [r11, #-0xc0]
   24a84: e1520003     	cmp	r2, r3
   24a88: 8affff56     	bhi	0x247e8 <calculate_header_and_footer+0x17ac> @ imm = #-0x2a8
   24a8c: e51b3100     	ldr	r3, [r11, #-0x100]
   24a90: e5933010     	ldr	r3, [r3, #0x10]
   24a94: e2832001     	add	r2, r3, #1
   24a98: e1a03002     	mov	r3, r2
   24a9c: e1a03083     	lsl	r3, r3, #1
   24aa0: e0833002     	add	r3, r3, r2
   24aa4: e1a03103     	lsl	r3, r3, #2
   24aa8: e243300c     	sub	r3, r3, #12
   24aac: e2033001     	and	r3, r3, #1
   24ab0: e6ef3073     	uxtb	r3, r3
   24ab4: e3530000     	cmp	r3, #0
   24ab8: 0a000008     	beq	0x24ae0 <calculate_header_and_footer+0x1aa4> @ imm = #0x20
   24abc: e51b3100     	ldr	r3, [r11, #-0x100]
   24ac0: e5933010     	ldr	r3, [r3, #0x10]
   24ac4: e2832001     	add	r2, r3, #1
   24ac8: e1a03002     	mov	r3, r2
   24acc: e1a03083     	lsl	r3, r3, #1
   24ad0: e0833002     	add	r3, r3, r2
   24ad4: e1a03103     	lsl	r3, r3, #2
   24ad8: e243300b     	sub	r3, r3, #11
   24adc: ea000007     	b	0x24b00 <calculate_header_and_footer+0x1ac4> @ imm = #0x1c
   24ae0: e51b3100     	ldr	r3, [r11, #-0x100]
   24ae4: e5933010     	ldr	r3, [r3, #0x10]
   24ae8: e2832001     	add	r2, r3, #1
   24aec: e1a03002     	mov	r3, r2
   24af0: e1a03083     	lsl	r3, r3, #1
   24af4: e0833002     	add	r3, r3, r2
   24af8: e1a03103     	lsl	r3, r3, #2
   24afc: e243300c     	sub	r3, r3, #12
   24b00: e1a02003     	mov	r2, r3
   24b04: e3a03000     	mov	r3, #0
   24b08: e59f1798     	ldr	r1, [pc, #0x798]        @ 0x252a8 <calculate_header_and_footer+0x226c>
   24b0c: e24b000c     	sub	r0, r11, #12
   24b10: e18020f1     	strd	r2, r3, [r0, r1]
   24b14: e59f278c     	ldr	r2, [pc, #0x78c]        @ 0x252a8 <calculate_header_and_footer+0x226c>
   24b18: e3a03004     	mov	r3, #4
   24b1c: e24b100c     	sub	r1, r11, #12
   24b20: e0812002     	add	r2, r1, r2
   24b24: e0823003     	add	r3, r2, r3
   24b28: e5934000     	ldr	r4, [r3]
   24b2c: e1a02c24     	lsr	r2, r4, #24
   24b30: e20438ff     	and	r3, r4, #16711680
   24b34: e1a03423     	lsr	r3, r3, #8
   24b38: e1822003     	orr	r2, r2, r3
   24b3c: e2043cff     	and	r3, r4, #65280
   24b40: e1a03403     	lsl	r3, r3, #8
   24b44: e1822003     	orr	r2, r2, r3
   24b48: e1a03c04     	lsl	r3, r4, #24
   24b4c: e1822003     	orr	r2, r2, r3
   24b50: e59f3754     	ldr	r3, [pc, #0x754]        @ 0x252ac <calculate_header_and_footer+0x2270>
   24b54: e24b000c     	sub	r0, r11, #12
   24b58: e7802003     	str	r2, [r0, r3]
   24b5c: e59f3744     	ldr	r3, [pc, #0x744]        @ 0x252a8 <calculate_header_and_footer+0x226c>
   24b60: e24b100c     	sub	r1, r11, #12
   24b64: e7914003     	ldr	r4, [r1, r3]
   24b68: e1a02c24     	lsr	r2, r4, #24
   24b6c: e20438ff     	and	r3, r4, #16711680
   24b70: e1a03423     	lsr	r3, r3, #8
   24b74: e1822003     	orr	r2, r2, r3
   24b78: e2043cff     	and	r3, r4, #65280
   24b7c: e1a03403     	lsl	r3, r3, #8
   24b80: e1822003     	orr	r2, r2, r3
   24b84: e1a03c04     	lsl	r3, r4, #24
   24b88: e1822003     	orr	r2, r2, r3
   24b8c: e59f1718     	ldr	r1, [pc, #0x718]        @ 0x252ac <calculate_header_and_footer+0x2270>
   24b90: e3a03004     	mov	r3, #4
   24b94: e24b000c     	sub	r0, r11, #12
   24b98: e0801001     	add	r1, r0, r1
   24b9c: e0813003     	add	r3, r1, r3
   24ba0: e5832000     	str	r2, [r3]
   24ba4: e59f3700     	ldr	r3, [pc, #0x700]        @ 0x252ac <calculate_header_and_footer+0x2270>
   24ba8: e24b100c     	sub	r1, r11, #12
   24bac: e18320d1     	ldrd	r2, r3, [r3, r1]
   24bb0: e51b10bc     	ldr	r1, [r11, #-0xbc]
   24bb4: e20200ff     	and	r0, r2, #255
   24bb8: e3a0c000     	mov	r12, #0
   24bbc: e18c0000     	orr	r0, r12, r0
   24bc0: e5c10004     	strb	r0, [r1, #0x4]
   24bc4: e1a00422     	lsr	r0, r2, #8
   24bc8: e20000ff     	and	r0, r0, #255
   24bcc: e3a0c000     	mov	r12, #0
   24bd0: e18c0000     	orr	r0, r12, r0
   24bd4: e5c10005     	strb	r0, [r1, #0x5]
   24bd8: e1a00822     	lsr	r0, r2, #16
   24bdc: e20000ff     	and	r0, r0, #255
   24be0: e3a0c000     	mov	r12, #0
   24be4: e18c0000     	orr	r0, r12, r0
   24be8: e5c10006     	strb	r0, [r1, #0x6]
   24bec: e1a00c22     	lsr	r0, r2, #24
   24bf0: e3a0c000     	mov	r12, #0
   24bf4: e18c0000     	orr	r0, r12, r0
   24bf8: e5c10007     	strb	r0, [r1, #0x7]
   24bfc: e20300ff     	and	r0, r3, #255
   24c00: e3a0c000     	mov	r12, #0
   24c04: e18c0000     	orr	r0, r12, r0
   24c08: e5c10008     	strb	r0, [r1, #0x8]
   24c0c: e1a00423     	lsr	r0, r3, #8
   24c10: e20000ff     	and	r0, r0, #255
   24c14: e3a0c000     	mov	r12, #0
   24c18: e18c0000     	orr	r0, r12, r0
   24c1c: e5c10009     	strb	r0, [r1, #0x9]
   24c20: e1a00823     	lsr	r0, r3, #16
   24c24: e20000ff     	and	r0, r0, #255
   24c28: e3a0c000     	mov	r12, #0
   24c2c: e18c0000     	orr	r0, r12, r0
   24c30: e5c1000a     	strb	r0, [r1, #0xa]
   24c34: e1a03c23     	lsr	r3, r3, #24
   24c38: e3a02000     	mov	r2, #0
   24c3c: e1823003     	orr	r3, r2, r3
   24c40: e5c1300b     	strb	r3, [r1, #0xb]
   24c44: e51b3100     	ldr	r3, [r11, #-0x100]
   24c48: e593200c     	ldr	r2, [r3, #0xc]
   24c4c: e51b10b8     	ldr	r1, [r11, #-0xb8]
   24c50: e51b3100     	ldr	r3, [r11, #-0x100]
   24c54: e5933008     	ldr	r3, [r3, #0x8]
   24c58: e0633001     	rsb	r3, r3, r1
   24c5c: e1a01003     	mov	r1, r3
   24c60: e51b3100     	ldr	r3, [r11, #-0x100]
   24c64: e593300c     	ldr	r3, [r3, #0xc]
   24c68: e0633001     	rsb	r3, r3, r1
   24c6c: e2033001     	and	r3, r3, #1
   24c70: e6ef3073     	uxtb	r3, r3
   24c74: e3530000     	cmp	r3, #0
   24c78: 0a000009     	beq	0x24ca4 <calculate_header_and_footer+0x1c68> @ imm = #0x24
   24c7c: e51b10b8     	ldr	r1, [r11, #-0xb8]
   24c80: e51b3100     	ldr	r3, [r11, #-0x100]
   24c84: e5933008     	ldr	r3, [r3, #0x8]
   24c88: e0633001     	rsb	r3, r3, r1
   24c8c: e1a01003     	mov	r1, r3
   24c90: e51b3100     	ldr	r3, [r11, #-0x100]
   24c94: e593300c     	ldr	r3, [r3, #0xc]
   24c98: e0633001     	rsb	r3, r3, r1
   24c9c: e2833001     	add	r3, r3, #1
   24ca0: ea000007     	b	0x24cc4 <calculate_header_and_footer+0x1c88> @ imm = #0x1c
   24ca4: e51b10b8     	ldr	r1, [r11, #-0xb8]
   24ca8: e51b3100     	ldr	r3, [r11, #-0x100]
   24cac: e5933008     	ldr	r3, [r3, #0x8]
   24cb0: e0633001     	rsb	r3, r3, r1
   24cb4: e1a01003     	mov	r1, r3
   24cb8: e51b3100     	ldr	r3, [r11, #-0x100]
   24cbc: e593300c     	ldr	r3, [r3, #0xc]
   24cc0: e0633001     	rsb	r3, r3, r1
   24cc4: e0822003     	add	r2, r2, r3
   24cc8: e51b3100     	ldr	r3, [r11, #-0x100]
   24ccc: e583200c     	str	r2, [r3, #0xc]
   24cd0: e51b3100     	ldr	r3, [r11, #-0x100]
   24cd4: e5932008     	ldr	r2, [r3, #0x8]
   24cd8: e51b3100     	ldr	r3, [r11, #-0x100]
   24cdc: e593300c     	ldr	r3, [r3, #0xc]
   24ce0: e0823003     	add	r3, r2, r3
   24ce4: e50b30b0     	str	r3, [r11, #-0xb0]
   24ce8: e51b30b0     	ldr	r3, [r11, #-0xb0]
   24cec: e50b30ac     	str	r3, [r11, #-0xac]
   24cf0: e51b30ac     	ldr	r3, [r11, #-0xac]
   24cf4: e3a02000     	mov	r2, #0
   24cf8: e3822044     	orr	r2, r2, #68
   24cfc: e5c32000     	strb	r2, [r3]
   24d00: e3a02000     	mov	r2, #0
   24d04: e3822049     	orr	r2, r2, #73
   24d08: e5c32001     	strb	r2, [r3, #0x1]
   24d0c: e3a02000     	mov	r2, #0
   24d10: e3822049     	orr	r2, r2, #73
   24d14: e5c32002     	strb	r2, [r3, #0x2]
   24d18: e3a02000     	mov	r2, #0
   24d1c: e382204e     	orr	r2, r2, #78
   24d20: e5c32003     	strb	r2, [r3, #0x3]
   24d24: e51b30b0     	ldr	r3, [r11, #-0xb0]
   24d28: e283300c     	add	r3, r3, #12
   24d2c: e50b30b0     	str	r3, [r11, #-0xb0]
   24d30: e51b3100     	ldr	r3, [r11, #-0x100]
   24d34: e5933028     	ldr	r3, [r3, #0x28]
   24d38: e3530000     	cmp	r3, #0
   24d3c: 0a000168     	beq	0x252e4 <calculate_header_and_footer+0x22a8> @ imm = #0x5a0
   24d40: e3a02000     	mov	r2, #0
   24d44: e3a03000     	mov	r3, #0
   24d48: e14b2af4     	strd	r2, r3, [r11, #-164]
   24d4c: e3a02000     	mov	r2, #0
   24d50: e3a03000     	mov	r3, #0
   24d54: e14b29fc     	strd	r2, r3, [r11, #-156]
   24d58: e51b30b0     	ldr	r3, [r11, #-0xb0]
   24d5c: e50b3090     	str	r3, [r11, #-0x90]
   24d60: e51b3090     	ldr	r3, [r11, #-0x90]
   24d64: e3a02000     	mov	r2, #0
   24d68: e3822045     	orr	r2, r2, #69
   24d6c: e5c32000     	strb	r2, [r3]
   24d70: e3a02000     	mov	r2, #0
   24d74: e382204d     	orr	r2, r2, #77
   24d78: e5c32001     	strb	r2, [r3, #0x1]
   24d7c: e3a02000     	mov	r2, #0
   24d80: e3822049     	orr	r2, r2, #73
   24d84: e5c32002     	strb	r2, [r3, #0x2]
   24d88: e3a02000     	mov	r2, #0
   24d8c: e3822044     	orr	r2, r2, #68
   24d90: e5c32003     	strb	r2, [r3, #0x3]
   24d94: e59f1514     	ldr	r1, [pc, #0x514]        @ 0x252b0 <calculate_header_and_footer+0x2274>
   24d98: e3a02000     	mov	r2, #0
   24d9c: e3a03000     	mov	r3, #0
   24da0: e24b000c     	sub	r0, r11, #12
   24da4: e18020f1     	strd	r2, r3, [r0, r1]
   24da8: e59f3500     	ldr	r3, [pc, #0x500]        @ 0x252b0 <calculate_header_and_footer+0x2274>
   24dac: e24b100c     	sub	r1, r11, #12
   24db0: e18320d1     	ldrd	r2, r3, [r3, r1]
   24db4: e51b1090     	ldr	r1, [r11, #-0x90]
   24db8: e20200ff     	and	r0, r2, #255
   24dbc: e3a0c000     	mov	r12, #0
   24dc0: e18c0000     	orr	r0, r12, r0
   24dc4: e5c10004     	strb	r0, [r1, #0x4]
   24dc8: e1a00422     	lsr	r0, r2, #8
   24dcc: e20000ff     	and	r0, r0, #255
   24dd0: e3a0c000     	mov	r12, #0
   24dd4: e18c0000     	orr	r0, r12, r0
   24dd8: e5c10005     	strb	r0, [r1, #0x5]
   24ddc: e1a00822     	lsr	r0, r2, #16
   24de0: e20000ff     	and	r0, r0, #255
   24de4: e3a0c000     	mov	r12, #0
   24de8: e18c0000     	orr	r0, r12, r0
   24dec: e5c10006     	strb	r0, [r1, #0x6]
   24df0: e1a00c22     	lsr	r0, r2, #24
   24df4: e3a0c000     	mov	r12, #0
   24df8: e18c0000     	orr	r0, r12, r0
   24dfc: e5c10007     	strb	r0, [r1, #0x7]
   24e00: e20300ff     	and	r0, r3, #255
   24e04: e3a0c000     	mov	r12, #0
   24e08: e18c0000     	orr	r0, r12, r0
   24e0c: e5c10008     	strb	r0, [r1, #0x8]
   24e10: e1a00423     	lsr	r0, r3, #8
   24e14: e20000ff     	and	r0, r0, #255
   24e18: e3a0c000     	mov	r12, #0
   24e1c: e18c0000     	orr	r0, r12, r0
   24e20: e5c10009     	strb	r0, [r1, #0x9]
   24e24: e1a00823     	lsr	r0, r3, #16
   24e28: e20000ff     	and	r0, r0, #255
   24e2c: e3a0c000     	mov	r12, #0
   24e30: e18c0000     	orr	r0, r12, r0
   24e34: e5c1000a     	strb	r0, [r1, #0xa]
   24e38: e1a03c23     	lsr	r3, r3, #24
   24e3c: e3a02000     	mov	r2, #0
   24e40: e1823003     	orr	r3, r2, r3
   24e44: e5c1300b     	strb	r3, [r1, #0xb]
   24e48: e51b30b0     	ldr	r3, [r11, #-0xb0]
   24e4c: e283300c     	add	r3, r3, #12
   24e50: e50b30b0     	str	r3, [r11, #-0xb0]
   24e54: e3a03000     	mov	r3, #0
   24e58: e50b30a8     	str	r3, [r11, #-0xa8]
   24e5c: ea000101     	b	0x25268 <calculate_header_and_footer+0x222c> @ imm = #0x404
   24e60: e51b3460     	ldr	r3, [r11, #-0x460]
   24e64: e5932000     	ldr	r2, [r3]
   24e68: e51b1104     	ldr	r1, [r11, #-0x104]
   24e6c: e3a03068     	mov	r3, #104
   24e70: e59f0450     	ldr	r0, [pc, #0x450]        @ 0x252c8 <calculate_header_and_footer+0x228c>
   24e74: e0020290     	mul	r2, r0, r2
   24e78: e0812002     	add	r2, r1, r2
   24e7c: e0823003     	add	r3, r2, r3
   24e80: e5933000     	ldr	r3, [r3]
   24e84: e2832008     	add	r2, r3, #8
   24e88: e51b30a8     	ldr	r3, [r11, #-0xa8]
   24e8c: e1a03103     	lsl	r3, r3, #2
   24e90: e0823003     	add	r3, r2, r3
   24e94: e50b308c     	str	r3, [r11, #-0x8c]
   24e98: e51b308c     	ldr	r3, [r11, #-0x8c]
   24e9c: e5d33000     	ldrb	r3, [r3]
   24ea0: e59f240c     	ldr	r2, [pc, #0x40c]        @ 0x252b4 <calculate_header_and_footer+0x2278>
   24ea4: e0010392     	mul	r1, r2, r3
   24ea8: e51b308c     	ldr	r3, [r11, #-0x8c]
   24eac: e5d33001     	ldrb	r3, [r3, #0x1]
   24eb0: e1a02003     	mov	r2, r3
   24eb4: e1a03002     	mov	r3, r2
   24eb8: e1a03103     	lsl	r3, r3, #2
   24ebc: e0833002     	add	r3, r3, r2
   24ec0: e1a02203     	lsl	r2, r3, #4
   24ec4: e0633002     	rsb	r3, r3, r2
   24ec8: e0812003     	add	r2, r1, r3
   24ecc: e51b308c     	ldr	r3, [r11, #-0x8c]
   24ed0: e5d33002     	ldrb	r3, [r3, #0x2]
   24ed4: e0823003     	add	r3, r2, r3
   24ed8: e1a02003     	mov	r2, r3
   24edc: e1a03fc2     	asr	r3, r2, #31
   24ee0: e14b2af4     	strd	r2, r3, [r11, #-164]
   24ee4: e51b308c     	ldr	r3, [r11, #-0x8c]
   24ee8: e5d33003     	ldrb	r3, [r3, #0x3]
   24eec: e1a03323     	lsr	r3, r3, #6
   24ef0: e2033001     	and	r3, r3, #1
   24ef4: e6ef3073     	uxtb	r3, r3
   24ef8: e1a02003     	mov	r2, r3
   24efc: e51b308c     	ldr	r3, [r11, #-0x8c]
   24f00: e5d33003     	ldrb	r3, [r3, #0x3]
   24f04: e1a031a3     	lsr	r3, r3, #3
   24f08: e2033001     	and	r3, r3, #1
   24f0c: e6ef3073     	uxtb	r3, r3
   24f10: e1a03083     	lsl	r3, r3, #1
   24f14: e6ff3073     	uxth	r3, r3
   24f18: e1823003     	orr	r3, r2, r3
   24f1c: e6ff2073     	uxth	r2, r3
   24f20: e51b308c     	ldr	r3, [r11, #-0x8c]
   24f24: e5d33003     	ldrb	r3, [r3, #0x3]
   24f28: e1a03223     	lsr	r3, r3, #4
   24f2c: e2033001     	and	r3, r3, #1
   24f30: e6ef3073     	uxtb	r3, r3
   24f34: e1a03103     	lsl	r3, r3, #2
   24f38: e6ff3073     	uxth	r3, r3
   24f3c: e1823003     	orr	r3, r2, r3
   24f40: e6ff2073     	uxth	r2, r3
   24f44: e51b308c     	ldr	r3, [r11, #-0x8c]
   24f48: e5d33003     	ldrb	r3, [r3, #0x3]
   24f4c: e1a032a3     	lsr	r3, r3, #5
   24f50: e2033001     	and	r3, r3, #1
   24f54: e6ef3073     	uxtb	r3, r3
   24f58: e1a03183     	lsl	r3, r3, #3
   24f5c: e6ff3073     	uxth	r3, r3
   24f60: e1823003     	orr	r3, r2, r3
   24f64: e6ff3073     	uxth	r3, r3
   24f68: e14b38b6     	strh	r3, [r11, #-134]
   24f6c: e51b3460     	ldr	r3, [r11, #-0x460]
   24f70: e5932000     	ldr	r2, [r3]
   24f74: e51b1104     	ldr	r1, [r11, #-0x104]
   24f78: e3a03068     	mov	r3, #104
   24f7c: e59f0344     	ldr	r0, [pc, #0x344]        @ 0x252c8 <calculate_header_and_footer+0x228c>
   24f80: e0020290     	mul	r2, r0, r2
   24f84: e0812002     	add	r2, r1, r2
   24f88: e0823003     	add	r3, r2, r3
   24f8c: e5933000     	ldr	r3, [r3]
   24f90: e2833b01     	add	r3, r3, #1024
   24f94: e2833004     	add	r3, r3, #4
   24f98: e51b20a8     	ldr	r2, [r11, #-0xa8]
   24f9c: e1a02102     	lsl	r2, r2, #2
   24fa0: e0833002     	add	r3, r3, r2
   24fa4: e50b308c     	str	r3, [r11, #-0x8c]
   24fa8: e51b308c     	ldr	r3, [r11, #-0x8c]
   24fac: e5d33000     	ldrb	r3, [r3]
   24fb0: e59f22fc     	ldr	r2, [pc, #0x2fc]        @ 0x252b4 <calculate_header_and_footer+0x2278>
   24fb4: e0010392     	mul	r1, r2, r3
   24fb8: e51b308c     	ldr	r3, [r11, #-0x8c]
   24fbc: e5d33001     	ldrb	r3, [r3, #0x1]
   24fc0: e1a02003     	mov	r2, r3
   24fc4: e1a03002     	mov	r3, r2
   24fc8: e1a03103     	lsl	r3, r3, #2
   24fcc: e0833002     	add	r3, r3, r2
   24fd0: e1a02203     	lsl	r2, r3, #4
   24fd4: e0633002     	rsb	r3, r3, r2
   24fd8: e0812003     	add	r2, r1, r3
   24fdc: e51b308c     	ldr	r3, [r11, #-0x8c]
   24fe0: e5d33002     	ldrb	r3, [r3, #0x2]
   24fe4: e0823003     	add	r3, r2, r3
   24fe8: e1a00003     	mov	r0, r3
   24fec: e1a01fc0     	asr	r1, r0, #31
   24ff0: e14b2ad4     	ldrd	r2, r3, [r11, #-164]
   24ff4: e0922000     	adds	r2, r2, r0
   24ff8: e0a33001     	adc	r3, r3, r1
   24ffc: e14b29fc     	strd	r2, r3, [r11, #-156]
   25000: e51b308c     	ldr	r3, [r11, #-0x8c]
   25004: e5d33003     	ldrb	r3, [r3, #0x3]
   25008: e1a03323     	lsr	r3, r3, #6
   2500c: e2033001     	and	r3, r3, #1
   25010: e6ef3073     	uxtb	r3, r3
   25014: e1a02003     	mov	r2, r3
   25018: e51b308c     	ldr	r3, [r11, #-0x8c]
   2501c: e5d33003     	ldrb	r3, [r3, #0x3]
   25020: e1a031a3     	lsr	r3, r3, #3
   25024: e2033001     	and	r3, r3, #1
   25028: e6ef3073     	uxtb	r3, r3
   2502c: e1a03083     	lsl	r3, r3, #1
   25030: e6ff3073     	uxth	r3, r3
   25034: e1823003     	orr	r3, r2, r3
   25038: e6ff2073     	uxth	r2, r3
   2503c: e51b308c     	ldr	r3, [r11, #-0x8c]
   25040: e5d33003     	ldrb	r3, [r3, #0x3]
   25044: e1a03223     	lsr	r3, r3, #4
   25048: e2033001     	and	r3, r3, #1
   2504c: e6ef3073     	uxtb	r3, r3
   25050: e1a03103     	lsl	r3, r3, #2
   25054: e6ff3073     	uxth	r3, r3
   25058: e1823003     	orr	r3, r2, r3
   2505c: e6ff2073     	uxth	r2, r3
   25060: e51b308c     	ldr	r3, [r11, #-0x8c]
   25064: e5d33003     	ldrb	r3, [r3, #0x3]
   25068: e1a032a3     	lsr	r3, r3, #5
   2506c: e2033001     	and	r3, r3, #1
   25070: e6ef3073     	uxtb	r3, r3
   25074: e1a03183     	lsl	r3, r3, #3
   25078: e6ff3073     	uxth	r3, r3
   2507c: e1823003     	orr	r3, r2, r3
   25080: e6ff3073     	uxth	r3, r3
   25084: e14b38b8     	strh	r3, [r11, #-136]
   25088: e51b30a8     	ldr	r3, [r11, #-0xa8]
   2508c: e3530000     	cmp	r3, #0
   25090: 1a00000a     	bne	0x250c0 <calculate_header_and_footer+0x2084> @ imm = #0x28
   25094: e3a03002     	mov	r3, #2
   25098: e58d3000     	str	r3, [sp]
   2509c: e15b38b6     	ldrh	r3, [r11, #-134]
   250a0: e58d3004     	str	r3, [sp, #0x4]
   250a4: e51b00b0     	ldr	r0, [r11, #-0xb0]
   250a8: e51b1460     	ldr	r1, [r11, #-0x460]
   250ac: e3a02000     	mov	r2, #0
   250b0: e3a03000     	mov	r3, #0
   250b4: ebfff6d7     	bl	0x22c18 <add_marker_chunk> @ imm = #-0x24a4
   250b8: e1a03000     	mov	r3, r0
   250bc: e50b30b0     	str	r3, [r11, #-0xb0]
   250c0: e3a03000     	mov	r3, #0
   250c4: e58d3000     	str	r3, [sp]
   250c8: e15b38b6     	ldrh	r3, [r11, #-134]
   250cc: e58d3004     	str	r3, [sp, #0x4]
   250d0: e51b00b0     	ldr	r0, [r11, #-0xb0]
   250d4: e51b1460     	ldr	r1, [r11, #-0x460]
   250d8: e14b2ad4     	ldrd	r2, r3, [r11, #-164]
   250dc: ebfff6cd     	bl	0x22c18 <add_marker_chunk> @ imm = #-0x24cc
   250e0: e1a03000     	mov	r3, r0
   250e4: e50b30b0     	str	r3, [r11, #-0xb0]
   250e8: e51b3460     	ldr	r3, [r11, #-0x460]
   250ec: e5932000     	ldr	r2, [r3]
   250f0: e51b1104     	ldr	r1, [r11, #-0x104]
   250f4: e3a03060     	mov	r3, #96
   250f8: e59f01c8     	ldr	r0, [pc, #0x1c8]        @ 0x252c8 <calculate_header_and_footer+0x228c>
   250fc: e0020290     	mul	r2, r0, r2
   25100: e0812002     	add	r2, r1, r2
   25104: e0823003     	add	r3, r2, r3
   25108: e5933000     	ldr	r3, [r3]
   2510c: e5d33045     	ldrb	r3, [r3, #0x45]
   25110: e2432001     	sub	r2, r3, #1
   25114: e51b30a8     	ldr	r3, [r11, #-0xa8]
   25118: e1520003     	cmp	r2, r3
   2511c: 0a000044     	beq	0x25234 <calculate_header_and_footer+0x21f8> @ imm = #0x110
   25120: e51b3460     	ldr	r3, [r11, #-0x460]
   25124: e5932000     	ldr	r2, [r3]
   25128: e51b1104     	ldr	r1, [r11, #-0x104]
   2512c: e3a03068     	mov	r3, #104
   25130: e59f0190     	ldr	r0, [pc, #0x190]        @ 0x252c8 <calculate_header_and_footer+0x228c>
   25134: e0020290     	mul	r2, r0, r2
   25138: e0812002     	add	r2, r1, r2
   2513c: e0823003     	add	r3, r2, r3
   25140: e5933000     	ldr	r3, [r3]
   25144: e2832008     	add	r2, r3, #8
   25148: e51b30a8     	ldr	r3, [r11, #-0xa8]
   2514c: e2833001     	add	r3, r3, #1
   25150: e1a03103     	lsl	r3, r3, #2
   25154: e0823003     	add	r3, r2, r3
   25158: e5d33000     	ldrb	r3, [r3]
   2515c: e59f2150     	ldr	r2, [pc, #0x150]        @ 0x252b4 <calculate_header_and_footer+0x2278>
   25160: e0010392     	mul	r1, r2, r3
   25164: e51b3460     	ldr	r3, [r11, #-0x460]
   25168: e5932000     	ldr	r2, [r3]
   2516c: e51b0104     	ldr	r0, [r11, #-0x104]
   25170: e3a03068     	mov	r3, #104
   25174: e59fc14c     	ldr	r12, [pc, #0x14c]       @ 0x252c8 <calculate_header_and_footer+0x228c>
   25178: e002029c     	mul	r2, r12, r2
   2517c: e0802002     	add	r2, r0, r2
   25180: e0823003     	add	r3, r2, r3
   25184: e5933000     	ldr	r3, [r3]
   25188: e2832008     	add	r2, r3, #8
   2518c: e51b30a8     	ldr	r3, [r11, #-0xa8]
   25190: e2833001     	add	r3, r3, #1
   25194: e1a03103     	lsl	r3, r3, #2
   25198: e0823003     	add	r3, r2, r3
   2519c: e5d33001     	ldrb	r3, [r3, #0x1]
   251a0: e1a02003     	mov	r2, r3
   251a4: e1a03002     	mov	r3, r2
   251a8: e1a03103     	lsl	r3, r3, #2
   251ac: e0833002     	add	r3, r3, r2
   251b0: e1a02203     	lsl	r2, r3, #4
   251b4: e0633002     	rsb	r3, r3, r2
   251b8: e0812003     	add	r2, r1, r3
   251bc: e51b3460     	ldr	r3, [r11, #-0x460]
   251c0: e5931000     	ldr	r1, [r3]
   251c4: e51b0104     	ldr	r0, [r11, #-0x104]
   251c8: e3a03068     	mov	r3, #104
   251cc: e59fc0f4     	ldr	r12, [pc, #0xf4]        @ 0x252c8 <calculate_header_and_footer+0x228c>
   251d0: e001019c     	mul	r1, r12, r1
   251d4: e0801001     	add	r1, r0, r1
   251d8: e0813003     	add	r3, r1, r3
   251dc: e5933000     	ldr	r3, [r3]
   251e0: e2831008     	add	r1, r3, #8
   251e4: e51b30a8     	ldr	r3, [r11, #-0xa8]
   251e8: e2833001     	add	r3, r3, #1
   251ec: e1a03103     	lsl	r3, r3, #2
   251f0: e0813003     	add	r3, r1, r3
   251f4: e5d33002     	ldrb	r3, [r3, #0x2]
   251f8: e0823003     	add	r3, r2, r3
   251fc: e1a02003     	mov	r2, r3
   25200: e1a03fc2     	asr	r3, r2, #31
   25204: e51b1098     	ldr	r1, [r11, #-0x98]
   25208: e1510003     	cmp	r1, r3
   2520c: 3a000008     	blo	0x25234 <calculate_header_and_footer+0x21f8> @ imm = #0x20
   25210: e51b1098     	ldr	r1, [r11, #-0x98]
   25214: e1510003     	cmp	r1, r3
   25218: 1a00000f     	bne	0x2525c <calculate_header_and_footer+0x2220> @ imm = #0x3c
   2521c: e51b109c     	ldr	r1, [r11, #-0x9c]
   25220: e1510002     	cmp	r1, r2
   25224: 3a000002     	blo	0x25234 <calculate_header_and_footer+0x21f8> @ imm = #0x8
   25228: e51b109c     	ldr	r1, [r11, #-0x9c]
   2522c: e1510002     	cmp	r1, r2
   25230: ea000009     	b	0x2525c <calculate_header_and_footer+0x2220> @ imm = #0x24
   25234: e3a03001     	mov	r3, #1
   25238: e58d3000     	str	r3, [sp]
   2523c: e15b38b8     	ldrh	r3, [r11, #-136]
   25240: e58d3004     	str	r3, [sp, #0x4]
   25244: e51b00b0     	ldr	r0, [r11, #-0xb0]
   25248: e51b1460     	ldr	r1, [r11, #-0x460]
   2524c: e14b29dc     	ldrd	r2, r3, [r11, #-156]
   25250: ebfff670     	bl	0x22c18 <add_marker_chunk> @ imm = #-0x2640
   25254: e1a03000     	mov	r3, r0
   25258: e50b30b0     	str	r3, [r11, #-0xb0]
   2525c: e51b30a8     	ldr	r3, [r11, #-0xa8]
   25260: e2833001     	add	r3, r3, #1
   25264: e50b30a8     	str	r3, [r11, #-0xa8]
   25268: e51b3460     	ldr	r3, [r11, #-0x460]
   2526c: e5932000     	ldr	r2, [r3]
   25270: e51b1104     	ldr	r1, [r11, #-0x104]
   25274: e3a03060     	mov	r3, #96
   25278: e59f0048     	ldr	r0, [pc, #0x48]         @ 0x252c8 <calculate_header_and_footer+0x228c>
   2527c: e0020290     	mul	r2, r0, r2
   25280: e0812002     	add	r2, r1, r2
   25284: e0823003     	add	r3, r2, r3
   25288: e5933000     	ldr	r3, [r3]
   2528c: e5d33045     	ldrb	r3, [r3, #0x45]
   25290: e1a02003     	mov	r2, r3
   25294: e51b30a8     	ldr	r3, [r11, #-0xa8]
   25298: e1520003     	cmp	r2, r3
   2529c: cafffeef     	bgt	0x24e60 <calculate_header_and_footer+0x1e24> @ imm = #-0x444
   252a0: ea0000ed     	b	0x2565c <calculate_header_and_footer+0x2620> @ imm = #0x3b4
   252a4: 58 fe ff ff  	.word	0xfffffe58
   252a8: 50 fe ff ff  	.word	0xfffffe50
   252ac: 48 fe ff ff  	.word	0xfffffe48
   252b0: 38 fe ff ff  	.word	0xfffffe38
   252b4: 94 11 00 00  	.word	0x00001194
   252b8: 28 fe ff ff  	.word	0xfffffe28
   252bc: 89 88 88 88  	.word	0x88888889
   252c0: 20 fe ff ff  	.word	0xfffffe20
   252c4: 18 fe ff ff  	.word	0xfffffe18
   252c8: f0 37 00 00  	.word	0x000037f0
   252cc: 54 55 03 00  	.word	0x00035554
   252d0: 5c 55 03 00  	.word	0x0003555c
   252d4: 10 fe ff ff  	.word	0xfffffe10
   252d8: 08 fe ff ff  	.word	0xfffffe08
   252dc: 00 fe ff ff  	.word	0xfffffe00
   252e0: f8 fd ff ff  	.word	0xfffffdf8
   252e4: e51b30b0     	ldr	r3, [r11, #-0xb0]
   252e8: e50b3084     	str	r3, [r11, #-0x84]
   252ec: e51b3460     	ldr	r3, [r11, #-0x460]
   252f0: e5932000     	ldr	r2, [r3]
   252f4: e51b1104     	ldr	r1, [r11, #-0x104]
   252f8: e3a03068     	mov	r3, #104
   252fc: e51f003c     	ldr	r0, [pc, #-0x3c]        @ 0x252c8 <calculate_header_and_footer+0x228c>
   25300: e0020290     	mul	r2, r0, r2
   25304: e0812002     	add	r2, r1, r2
   25308: e0823003     	add	r3, r2, r3
   2530c: e5933000     	ldr	r3, [r3]
   25310: e2833b01     	add	r3, r3, #1024
   25314: e2833004     	add	r3, r3, #4
   25318: e51b2460     	ldr	r2, [r11, #-0x460]
   2531c: e5922004     	ldr	r2, [r2, #0x4]
   25320: e1a02102     	lsl	r2, r2, #2
   25324: e0833002     	add	r3, r3, r2
   25328: e50b3080     	str	r3, [r11, #-0x80]
   2532c: e51b3084     	ldr	r3, [r11, #-0x84]
   25330: e3a02000     	mov	r2, #0
   25334: e382204d     	orr	r2, r2, #77
   25338: e5c32000     	strb	r2, [r3]
   2533c: e3a02000     	mov	r2, #0
   25340: e3822041     	orr	r2, r2, #65
   25344: e5c32001     	strb	r2, [r3, #0x1]
   25348: e3a02000     	mov	r2, #0
   2534c: e3822052     	orr	r2, r2, #82
   25350: e5c32002     	strb	r2, [r3, #0x2]
   25354: e3a02000     	mov	r2, #0
   25358: e382204b     	orr	r2, r2, #75
   2535c: e5c32003     	strb	r2, [r3, #0x3]
   25360: e51f10b0     	ldr	r1, [pc, #-0xb0]        @ 0x252b8 <calculate_header_and_footer+0x227c>
   25364: e3a02000     	mov	r2, #0
   25368: e3a03416     	mov	r3, #369098752
   2536c: e24b000c     	sub	r0, r11, #12
   25370: e18020f1     	strd	r2, r3, [r0, r1]
   25374: e51f30c4     	ldr	r3, [pc, #-0xc4]        @ 0x252b8 <calculate_header_and_footer+0x227c>
   25378: e24b100c     	sub	r1, r11, #12
   2537c: e18320d1     	ldrd	r2, r3, [r3, r1]
   25380: e51b1084     	ldr	r1, [r11, #-0x84]
   25384: e20200ff     	and	r0, r2, #255
   25388: e3a0c000     	mov	r12, #0
   2538c: e18c0000     	orr	r0, r12, r0
   25390: e5c10004     	strb	r0, [r1, #0x4]
   25394: e1a00422     	lsr	r0, r2, #8
   25398: e20000ff     	and	r0, r0, #255
   2539c: e3a0c000     	mov	r12, #0
   253a0: e18c0000     	orr	r0, r12, r0
   253a4: e5c10005     	strb	r0, [r1, #0x5]
   253a8: e1a00822     	lsr	r0, r2, #16
   253ac: e20000ff     	and	r0, r0, #255
   253b0: e3a0c000     	mov	r12, #0
   253b4: e18c0000     	orr	r0, r12, r0
   253b8: e5c10006     	strb	r0, [r1, #0x6]
   253bc: e1a00c22     	lsr	r0, r2, #24
   253c0: e3a0c000     	mov	r12, #0
   253c4: e18c0000     	orr	r0, r12, r0
   253c8: e5c10007     	strb	r0, [r1, #0x7]
   253cc: e20300ff     	and	r0, r3, #255
   253d0: e3a0c000     	mov	r12, #0
   253d4: e18c0000     	orr	r0, r12, r0
   253d8: e5c10008     	strb	r0, [r1, #0x8]
   253dc: e1a00423     	lsr	r0, r3, #8
   253e0: e20000ff     	and	r0, r0, #255
   253e4: e3a0c000     	mov	r12, #0
   253e8: e18c0000     	orr	r0, r12, r0
   253ec: e5c10009     	strb	r0, [r1, #0x9]
   253f0: e1a00823     	lsr	r0, r3, #16
   253f4: e20000ff     	and	r0, r0, #255
   253f8: e3a0c000     	mov	r12, #0
   253fc: e18c0000     	orr	r0, r12, r0
   25400: e5c1000a     	strb	r0, [r1, #0xa]
   25404: e1a03c23     	lsr	r3, r3, #24
   25408: e3a02000     	mov	r2, #0
   2540c: e1823003     	orr	r3, r2, r3
   25410: e5c1300b     	strb	r3, [r1, #0xb]
   25414: e51b3080     	ldr	r3, [r11, #-0x80]
   25418: e5d32000     	ldrb	r2, [r3]
   2541c: e51f3168     	ldr	r3, [pc, #-0x168]       @ 0x252bc <calculate_header_and_footer+0x2280>
   25420: e0830293     	umull	r0, r3, r3, r2
   25424: e1a032a3     	lsr	r3, r3, #5
   25428: e6ef3073     	uxtb	r3, r3
   2542c: e14b37ba     	strh	r3, [r11, #-122]
   25430: e15b37ba     	ldrh	r3, [r11, #-122]
   25434: e1a03423     	lsr	r3, r3, #8
   25438: e6ff3073     	uxth	r3, r3
   2543c: e1a02003     	mov	r2, r3
   25440: e15b37ba     	ldrh	r3, [r11, #-122]
   25444: e1a03403     	lsl	r3, r3, #8
   25448: e1a03803     	lsl	r3, r3, #16
   2544c: e1a03823     	lsr	r3, r3, #16
   25450: e1823003     	orr	r3, r2, r3
   25454: e6ff2073     	uxth	r2, r3
   25458: e51b3084     	ldr	r3, [r11, #-0x84]
   2545c: e20210ff     	and	r1, r2, #255
   25460: e3a00000     	mov	r0, #0
   25464: e1801001     	orr	r1, r0, r1
   25468: e5c3100c     	strb	r1, [r3, #0xc]
   2546c: e1a02422     	lsr	r2, r2, #8
   25470: e6ff2072     	uxth	r2, r2
   25474: e3a01000     	mov	r1, #0
   25478: e1812002     	orr	r2, r1, r2
   2547c: e5c3200d     	strb	r2, [r3, #0xd]
   25480: e51b3080     	ldr	r3, [r11, #-0x80]
   25484: e5d32000     	ldrb	r2, [r3]
   25488: e51f31d4     	ldr	r3, [pc, #-0x1d4]       @ 0x252bc <calculate_header_and_footer+0x2280>
   2548c: e0831293     	umull	r1, r3, r3, r2
   25490: e1a032a3     	lsr	r3, r3, #5
   25494: e1a01103     	lsl	r1, r3, #2
   25498: e1a03201     	lsl	r3, r1, #4
   2549c: e0613003     	rsb	r3, r1, r3
   254a0: e0633002     	rsb	r3, r3, r2
   254a4: e6ef2073     	uxtb	r2, r3
   254a8: e51b3084     	ldr	r3, [r11, #-0x84]
   254ac: e5c3200e     	strb	r2, [r3, #0xe]
   254b0: e51b3080     	ldr	r3, [r11, #-0x80]
   254b4: e5d32001     	ldrb	r2, [r3, #0x1]
   254b8: e51b3084     	ldr	r3, [r11, #-0x84]
   254bc: e5c3200f     	strb	r2, [r3, #0xf]
   254c0: e51b3080     	ldr	r3, [r11, #-0x80]
   254c4: e5d33002     	ldrb	r3, [r3, #0x2]
   254c8: e3a02c93     	mov	r2, #37632
   254cc: e0030392     	mul	r3, r2, r3
   254d0: e1a04003     	mov	r4, r3
   254d4: e1a02c24     	lsr	r2, r4, #24
   254d8: e20438ff     	and	r3, r4, #16711680
   254dc: e1a03423     	lsr	r3, r3, #8
   254e0: e1822003     	orr	r2, r2, r3
   254e4: e2043cff     	and	r3, r4, #65280
   254e8: e1a03403     	lsl	r3, r3, #8
   254ec: e1822003     	orr	r2, r2, r3
   254f0: e1a03c04     	lsl	r3, r4, #24
   254f4: e1822003     	orr	r2, r2, r3
   254f8: e51b3084     	ldr	r3, [r11, #-0x84]
   254fc: e20210ff     	and	r1, r2, #255
   25500: e3a00000     	mov	r0, #0
   25504: e1801001     	orr	r1, r0, r1
   25508: e5c31010     	strb	r1, [r3, #0x10]
   2550c: e1a01422     	lsr	r1, r2, #8
   25510: e20110ff     	and	r1, r1, #255
   25514: e3a00000     	mov	r0, #0
   25518: e1801001     	orr	r1, r0, r1
   2551c: e5c31011     	strb	r1, [r3, #0x11]
   25520: e1a01822     	lsr	r1, r2, #16
   25524: e20110ff     	and	r1, r1, #255
   25528: e3a00000     	mov	r0, #0
   2552c: e1801001     	orr	r1, r0, r1
   25530: e5c31012     	strb	r1, [r3, #0x12]
   25534: e1a02c22     	lsr	r2, r2, #24
   25538: e3a01000     	mov	r1, #0
   2553c: e1812002     	orr	r2, r1, r2
   25540: e5c32013     	strb	r2, [r3, #0x13]
   25544: e51b3084     	ldr	r3, [r11, #-0x84]
   25548: e3a02000     	mov	r2, #0
   2554c: e5c32014     	strb	r2, [r3, #0x14]
   25550: e3a02000     	mov	r2, #0
   25554: e5c32015     	strb	r2, [r3, #0x15]
   25558: e3a02000     	mov	r2, #0
   2555c: e5c32016     	strb	r2, [r3, #0x16]
   25560: e3a02000     	mov	r2, #0
   25564: e5c32017     	strb	r2, [r3, #0x17]
   25568: e3a03004     	mov	r3, #4
   2556c: e14b37b8     	strh	r3, [r11, #-120]
   25570: e15b37b8     	ldrh	r3, [r11, #-120]
   25574: e1a03423     	lsr	r3, r3, #8
   25578: e6ff3073     	uxth	r3, r3
   2557c: e1a02003     	mov	r2, r3
   25580: e15b37b8     	ldrh	r3, [r11, #-120]
   25584: e1a03403     	lsl	r3, r3, #8
   25588: e1a03803     	lsl	r3, r3, #16
   2558c: e1a03823     	lsr	r3, r3, #16
   25590: e1823003     	orr	r3, r2, r3
   25594: e6ff2073     	uxth	r2, r3
   25598: e51b3084     	ldr	r3, [r11, #-0x84]
   2559c: e20210ff     	and	r1, r2, #255
   255a0: e3a00000     	mov	r0, #0
   255a4: e1801001     	orr	r1, r0, r1
   255a8: e5c31018     	strb	r1, [r3, #0x18]
   255ac: e1a02422     	lsr	r2, r2, #8
   255b0: e6ff2072     	uxth	r2, r2
   255b4: e3a01000     	mov	r1, #0
   255b8: e1812002     	orr	r2, r1, r2
   255bc: e5c32019     	strb	r2, [r3, #0x19]
   255c0: e3a03000     	mov	r3, #0
   255c4: e14b37b6     	strh	r3, [r11, #-118]
   255c8: e15b37b6     	ldrh	r3, [r11, #-118]
   255cc: e1a03423     	lsr	r3, r3, #8
   255d0: e6ff3073     	uxth	r3, r3
   255d4: e1a02003     	mov	r2, r3
   255d8: e15b37b6     	ldrh	r3, [r11, #-118]
   255dc: e1a03403     	lsl	r3, r3, #8
   255e0: e1a03803     	lsl	r3, r3, #16
   255e4: e1a03823     	lsr	r3, r3, #16
   255e8: e1823003     	orr	r3, r2, r3
   255ec: e6ff2073     	uxth	r2, r3
   255f0: e51b3084     	ldr	r3, [r11, #-0x84]
   255f4: e20210ff     	and	r1, r2, #255
   255f8: e3a00000     	mov	r0, #0
   255fc: e1801001     	orr	r1, r0, r1
   25600: e5c3101a     	strb	r1, [r3, #0x1a]
   25604: e1a02422     	lsr	r2, r2, #8
   25608: e6ff2072     	uxth	r2, r2
   2560c: e3a01000     	mov	r1, #0
   25610: e1812002     	orr	r2, r1, r2
   25614: e5c3201b     	strb	r2, [r3, #0x1b]
   25618: e51b3084     	ldr	r3, [r11, #-0x84]
   2561c: e3a02000     	mov	r2, #0
   25620: e5c3201c     	strb	r2, [r3, #0x1c]
   25624: e3a02000     	mov	r2, #0
   25628: e5c3201d     	strb	r2, [r3, #0x1d]
   2562c: e51b3084     	ldr	r3, [r11, #-0x84]
   25630: e3a02000     	mov	r2, #0
   25634: e5c3201e     	strb	r2, [r3, #0x1e]
   25638: e3a02000     	mov	r2, #0
   2563c: e5c3201f     	strb	r2, [r3, #0x1f]
   25640: e3a02000     	mov	r2, #0
   25644: e5c32020     	strb	r2, [r3, #0x20]
   25648: e3a02000     	mov	r2, #0
   2564c: e5c32021     	strb	r2, [r3, #0x21]
   25650: e51b30b0     	ldr	r3, [r11, #-0xb0]
   25654: e2833022     	add	r3, r3, #34
   25658: e50b30b0     	str	r3, [r11, #-0xb0]
   2565c: e51b30b0     	ldr	r3, [r11, #-0xb0]
   25660: e50b3074     	str	r3, [r11, #-0x74]
   25664: e3a03000     	mov	r3, #0
   25668: e50b3070     	str	r3, [r11, #-0x70]
   2566c: e51b3100     	ldr	r3, [r11, #-0x100]
   25670: e5933028     	ldr	r3, [r3, #0x28]
   25674: e3530000     	cmp	r3, #0
   25678: 1a00000f     	bne	0x256bc <calculate_header_and_footer+0x2680> @ imm = #0x3c
   2567c: e51b3460     	ldr	r3, [r11, #-0x460]
   25680: e593c000     	ldr	r12, [r3]
   25684: e51b3460     	ldr	r3, [r11, #-0x460]
   25688: e5933004     	ldr	r3, [r3, #0x4]
   2568c: e51b0104     	ldr	r0, [r11, #-0x104]
   25690: e3a01074     	mov	r1, #116
   25694: e1a02183     	lsl	r2, r3, #3
   25698: e1a03182     	lsl	r3, r2, #3
   2569c: e0623003     	rsb	r3, r2, r3
   256a0: e51f23e0     	ldr	r2, [pc, #-0x3e0]       @ 0x252c8 <calculate_header_and_footer+0x228c>
   256a4: e0020c92     	mul	r2, r2, r12
   256a8: e0833002     	add	r3, r3, r2
   256ac: e0803003     	add	r3, r0, r3
   256b0: e0833001     	add	r3, r3, r1
   256b4: e5933000     	ldr	r3, [r3]
   256b8: e50b3070     	str	r3, [r11, #-0x70]
   256bc: e51b3070     	ldr	r3, [r11, #-0x70]
   256c0: e3530000     	cmp	r3, #0
   256c4: 1a000041     	bne	0x257d0 <calculate_header_and_footer+0x2794> @ imm = #0x104
   256c8: e51b3104     	ldr	r3, [r11, #-0x104]
   256cc: e2833010     	add	r3, r3, #16
   256d0: e50b306c     	str	r3, [r11, #-0x6c]
   256d4: e51b306c     	ldr	r3, [r11, #-0x6c]
   256d8: e5933008     	ldr	r3, [r3, #0x8]
   256dc: e3530000     	cmp	r3, #0
   256e0: 0a000003     	beq	0x256f4 <calculate_header_and_footer+0x26b8> @ imm = #0xc
   256e4: e51b306c     	ldr	r3, [r11, #-0x6c]
   256e8: e5933008     	ldr	r3, [r3, #0x8]
   256ec: e50b3070     	str	r3, [r11, #-0x70]
   256f0: ea000036     	b	0x257d0 <calculate_header_and_footer+0x2794> @ imm = #0xd8
   256f4: e51b306c     	ldr	r3, [r11, #-0x6c]
   256f8: e593300c     	ldr	r3, [r3, #0xc]
   256fc: e3530000     	cmp	r3, #0
   25700: 0a000003     	beq	0x25714 <calculate_header_and_footer+0x26d8> @ imm = #0xc
   25704: e51b306c     	ldr	r3, [r11, #-0x6c]
   25708: e593300c     	ldr	r3, [r3, #0xc]
   2570c: e50b3070     	str	r3, [r11, #-0x70]
   25710: ea00002e     	b	0x257d0 <calculate_header_and_footer+0x2794> @ imm = #0xb8
   25714: e51b306c     	ldr	r3, [r11, #-0x6c]
   25718: e5933028     	ldr	r3, [r3, #0x28]
   2571c: e3530000     	cmp	r3, #0
   25720: 0a000003     	beq	0x25734 <calculate_header_and_footer+0x26f8> @ imm = #0xc
   25724: e51b306c     	ldr	r3, [r11, #-0x6c]
   25728: e5933028     	ldr	r3, [r3, #0x28]
   2572c: e50b3070     	str	r3, [r11, #-0x70]
   25730: ea000026     	b	0x257d0 <calculate_header_and_footer+0x2794> @ imm = #0x98
   25734: e51b306c     	ldr	r3, [r11, #-0x6c]
   25738: e593302c     	ldr	r3, [r3, #0x2c]
   2573c: e3530000     	cmp	r3, #0
   25740: 0a000003     	beq	0x25754 <calculate_header_and_footer+0x2718> @ imm = #0xc
   25744: e51b306c     	ldr	r3, [r11, #-0x6c]
   25748: e593302c     	ldr	r3, [r3, #0x2c]
   2574c: e50b3070     	str	r3, [r11, #-0x70]
   25750: ea00001e     	b	0x257d0 <calculate_header_and_footer+0x2794> @ imm = #0x78
   25754: e51b306c     	ldr	r3, [r11, #-0x6c]
   25758: e5933000     	ldr	r3, [r3]
   2575c: e3530000     	cmp	r3, #0
   25760: 0a000003     	beq	0x25774 <calculate_header_and_footer+0x2738> @ imm = #0xc
   25764: e51b306c     	ldr	r3, [r11, #-0x6c]
   25768: e5933000     	ldr	r3, [r3]
   2576c: e50b3070     	str	r3, [r11, #-0x70]
   25770: ea000016     	b	0x257d0 <calculate_header_and_footer+0x2794> @ imm = #0x58
   25774: e51b306c     	ldr	r3, [r11, #-0x6c]
   25778: e5933004     	ldr	r3, [r3, #0x4]
   2577c: e3530000     	cmp	r3, #0
   25780: 0a000003     	beq	0x25794 <calculate_header_and_footer+0x2758> @ imm = #0xc
   25784: e51b306c     	ldr	r3, [r11, #-0x6c]
   25788: e5933004     	ldr	r3, [r3, #0x4]
   2578c: e50b3070     	str	r3, [r11, #-0x70]
   25790: ea00000e     	b	0x257d0 <calculate_header_and_footer+0x2794> @ imm = #0x38
   25794: e51b306c     	ldr	r3, [r11, #-0x6c]
   25798: e5933020     	ldr	r3, [r3, #0x20]
   2579c: e3530000     	cmp	r3, #0
   257a0: 0a000003     	beq	0x257b4 <calculate_header_and_footer+0x2778> @ imm = #0xc
   257a4: e51b306c     	ldr	r3, [r11, #-0x6c]
   257a8: e5933020     	ldr	r3, [r3, #0x20]
   257ac: e50b3070     	str	r3, [r11, #-0x70]
   257b0: ea000006     	b	0x257d0 <calculate_header_and_footer+0x2794> @ imm = #0x18
   257b4: e51b306c     	ldr	r3, [r11, #-0x6c]
   257b8: e5933024     	ldr	r3, [r3, #0x24]
   257bc: e3530000     	cmp	r3, #0
   257c0: 0a000002     	beq	0x257d0 <calculate_header_and_footer+0x2794> @ imm = #0x8
   257c4: e51b306c     	ldr	r3, [r11, #-0x6c]
   257c8: e5933024     	ldr	r3, [r3, #0x24]
   257cc: e50b3070     	str	r3, [r11, #-0x70]
   257d0: e51b3070     	ldr	r3, [r11, #-0x70]
   257d4: e3530000     	cmp	r3, #0
   257d8: 0a0000a9     	beq	0x25a84 <calculate_header_and_footer+0x2a48> @ imm = #0x2a4
   257dc: e51b0070     	ldr	r0, [r11, #-0x70]
   257e0: ebff9b3d     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1930c
   257e4: e1a03000     	mov	r3, r0
   257e8: e51b0070     	ldr	r0, [r11, #-0x70]
   257ec: e1a01003     	mov	r1, r3
   257f0: e51f252c     	ldr	r2, [pc, #-0x52c]       @ 0x252cc <calculate_header_and_footer+0x2290>
   257f4: e51f352c     	ldr	r3, [pc, #-0x52c]       @ 0x252d0 <calculate_header_and_footer+0x2294>
   257f8: ebffa33d     	bl	0xe4f4 <charset_convert> @ imm = #-0x1730c
   257fc: e1a03000     	mov	r3, r0
   25800: e50b3068     	str	r3, [r11, #-0x68]
   25804: e51b0068     	ldr	r0, [r11, #-0x68]
   25808: ebff9b33     	bl	0xc4dc <strlen@plt>     @ imm = #-0x19334
   2580c: e1a03000     	mov	r3, r0
   25810: e50b3064     	str	r3, [r11, #-0x64]
   25814: e51b3074     	ldr	r3, [r11, #-0x74]
   25818: e3a02000     	mov	r2, #0
   2581c: e3822044     	orr	r2, r2, #68
   25820: e5c32000     	strb	r2, [r3]
   25824: e3a02000     	mov	r2, #0
   25828: e3822049     	orr	r2, r2, #73
   2582c: e5c32001     	strb	r2, [r3, #0x1]
   25830: e3a02000     	mov	r2, #0
   25834: e3822041     	orr	r2, r2, #65
   25838: e5c32002     	strb	r2, [r3, #0x2]
   2583c: e3a02000     	mov	r2, #0
   25840: e3822052     	orr	r2, r2, #82
   25844: e5c32003     	strb	r2, [r3, #0x3]
   25848: e51b3064     	ldr	r3, [r11, #-0x64]
   2584c: e2833004     	add	r3, r3, #4
   25850: e2033001     	and	r3, r3, #1
   25854: e6ef3073     	uxtb	r3, r3
   25858: e3530000     	cmp	r3, #0
   2585c: 0a000002     	beq	0x2586c <calculate_header_and_footer+0x2830> @ imm = #0x8
   25860: e51b3064     	ldr	r3, [r11, #-0x64]
   25864: e2833005     	add	r3, r3, #5
   25868: ea000001     	b	0x25874 <calculate_header_and_footer+0x2838> @ imm = #0x4
   2586c: e51b3064     	ldr	r3, [r11, #-0x64]
   25870: e2833004     	add	r3, r3, #4
   25874: e1a02003     	mov	r2, r3
   25878: e3a03000     	mov	r3, #0
   2587c: e51f15c4     	ldr	r1, [pc, #-0x5c4]       @ 0x252c0 <calculate_header_and_footer+0x2284>
   25880: e24b000c     	sub	r0, r11, #12
   25884: e18020f1     	strd	r2, r3, [r0, r1]
   25888: e51f25d0     	ldr	r2, [pc, #-0x5d0]       @ 0x252c0 <calculate_header_and_footer+0x2284>
   2588c: e3a03004     	mov	r3, #4
   25890: e24b100c     	sub	r1, r11, #12
   25894: e0812002     	add	r2, r1, r2
   25898: e0823003     	add	r3, r2, r3
   2589c: e5934000     	ldr	r4, [r3]
   258a0: e1a02c24     	lsr	r2, r4, #24
   258a4: e20438ff     	and	r3, r4, #16711680
   258a8: e1a03423     	lsr	r3, r3, #8
   258ac: e1822003     	orr	r2, r2, r3
   258b0: e2043cff     	and	r3, r4, #65280
   258b4: e1a03403     	lsl	r3, r3, #8
   258b8: e1822003     	orr	r2, r2, r3
   258bc: e1a03c04     	lsl	r3, r4, #24
   258c0: e1822003     	orr	r2, r2, r3
   258c4: e51f3608     	ldr	r3, [pc, #-0x608]       @ 0x252c4 <calculate_header_and_footer+0x2288>
   258c8: e24b000c     	sub	r0, r11, #12
   258cc: e7802003     	str	r2, [r0, r3]
   258d0: e51f3618     	ldr	r3, [pc, #-0x618]       @ 0x252c0 <calculate_header_and_footer+0x2284>
   258d4: e24b100c     	sub	r1, r11, #12
   258d8: e7914003     	ldr	r4, [r1, r3]
   258dc: e1a02c24     	lsr	r2, r4, #24
   258e0: e20438ff     	and	r3, r4, #16711680
   258e4: e1a03423     	lsr	r3, r3, #8
   258e8: e1822003     	orr	r2, r2, r3
   258ec: e2043cff     	and	r3, r4, #65280
   258f0: e1a03403     	lsl	r3, r3, #8
   258f4: e1822003     	orr	r2, r2, r3
   258f8: e1a03c04     	lsl	r3, r4, #24
   258fc: e1822003     	orr	r2, r2, r3
   25900: e51f1644     	ldr	r1, [pc, #-0x644]       @ 0x252c4 <calculate_header_and_footer+0x2288>
   25904: e3a03004     	mov	r3, #4
   25908: e24b000c     	sub	r0, r11, #12
   2590c: e0801001     	add	r1, r0, r1
   25910: e0813003     	add	r3, r1, r3
   25914: e5832000     	str	r2, [r3]
   25918: e51f365c     	ldr	r3, [pc, #-0x65c]       @ 0x252c4 <calculate_header_and_footer+0x2288>
   2591c: e24b100c     	sub	r1, r11, #12
   25920: e18320d1     	ldrd	r2, r3, [r3, r1]
   25924: e51b1074     	ldr	r1, [r11, #-0x74]
   25928: e20200ff     	and	r0, r2, #255
   2592c: e3a0c000     	mov	r12, #0
   25930: e18c0000     	orr	r0, r12, r0
   25934: e5c10004     	strb	r0, [r1, #0x4]
   25938: e1a00422     	lsr	r0, r2, #8
   2593c: e20000ff     	and	r0, r0, #255
   25940: e3a0c000     	mov	r12, #0
   25944: e18c0000     	orr	r0, r12, r0
   25948: e5c10005     	strb	r0, [r1, #0x5]
   2594c: e1a00822     	lsr	r0, r2, #16
   25950: e20000ff     	and	r0, r0, #255
   25954: e3a0c000     	mov	r12, #0
   25958: e18c0000     	orr	r0, r12, r0
   2595c: e5c10006     	strb	r0, [r1, #0x6]
   25960: e1a00c22     	lsr	r0, r2, #24
   25964: e3a0c000     	mov	r12, #0
   25968: e18c0000     	orr	r0, r12, r0
   2596c: e5c10007     	strb	r0, [r1, #0x7]
   25970: e20300ff     	and	r0, r3, #255
   25974: e3a0c000     	mov	r12, #0
   25978: e18c0000     	orr	r0, r12, r0
   2597c: e5c10008     	strb	r0, [r1, #0x8]
   25980: e1a00423     	lsr	r0, r3, #8
   25984: e20000ff     	and	r0, r0, #255
   25988: e3a0c000     	mov	r12, #0
   2598c: e18c0000     	orr	r0, r12, r0
   25990: e5c10009     	strb	r0, [r1, #0x9]
   25994: e1a00823     	lsr	r0, r3, #16
   25998: e20000ff     	and	r0, r0, #255
   2599c: e3a0c000     	mov	r12, #0
   259a0: e18c0000     	orr	r0, r12, r0
   259a4: e5c1000a     	strb	r0, [r1, #0xa]
   259a8: e1a03c23     	lsr	r3, r3, #24
   259ac: e3a02000     	mov	r2, #0
   259b0: e1823003     	orr	r3, r2, r3
   259b4: e5c1300b     	strb	r3, [r1, #0xb]
   259b8: e51b4064     	ldr	r4, [r11, #-0x64]
   259bc: e1a02c24     	lsr	r2, r4, #24
   259c0: e20438ff     	and	r3, r4, #16711680
   259c4: e1a03423     	lsr	r3, r3, #8
   259c8: e1822003     	orr	r2, r2, r3
   259cc: e2043cff     	and	r3, r4, #65280
   259d0: e1a03403     	lsl	r3, r3, #8
   259d4: e1822003     	orr	r2, r2, r3
   259d8: e1a03c04     	lsl	r3, r4, #24
   259dc: e1822003     	orr	r2, r2, r3
   259e0: e51b3074     	ldr	r3, [r11, #-0x74]
   259e4: e20210ff     	and	r1, r2, #255
   259e8: e3a00000     	mov	r0, #0
   259ec: e1801001     	orr	r1, r0, r1
   259f0: e5c3100c     	strb	r1, [r3, #0xc]
   259f4: e1a01422     	lsr	r1, r2, #8
   259f8: e20110ff     	and	r1, r1, #255
   259fc: e3a00000     	mov	r0, #0
   25a00: e1801001     	orr	r1, r0, r1
   25a04: e5c3100d     	strb	r1, [r3, #0xd]
   25a08: e1a01822     	lsr	r1, r2, #16
   25a0c: e20110ff     	and	r1, r1, #255
   25a10: e3a00000     	mov	r0, #0
   25a14: e1801001     	orr	r1, r0, r1
   25a18: e5c3100e     	strb	r1, [r3, #0xe]
   25a1c: e1a02c22     	lsr	r2, r2, #24
   25a20: e3a01000     	mov	r1, #0
   25a24: e1812002     	orr	r2, r1, r2
   25a28: e5c3200f     	strb	r2, [r3, #0xf]
   25a2c: e51b30b0     	ldr	r3, [r11, #-0xb0]
   25a30: e2833010     	add	r3, r3, #16
   25a34: e50b30b0     	str	r3, [r11, #-0xb0]
   25a38: e51b3064     	ldr	r3, [r11, #-0x64]
   25a3c: e51b00b0     	ldr	r0, [r11, #-0xb0]
   25a40: e51b1068     	ldr	r1, [r11, #-0x68]
   25a44: e1a02003     	mov	r2, r3
   25a48: ebff9aaf     	bl	0xc50c <memcpy@plt>     @ imm = #-0x19544
   25a4c: e51b3064     	ldr	r3, [r11, #-0x64]
   25a50: e2033001     	and	r3, r3, #1
   25a54: e6ef3073     	uxtb	r3, r3
   25a58: e3530000     	cmp	r3, #0
   25a5c: 0a000002     	beq	0x25a6c <calculate_header_and_footer+0x2a30> @ imm = #0x8
   25a60: e51b3064     	ldr	r3, [r11, #-0x64]
   25a64: e2833001     	add	r3, r3, #1
   25a68: ea000000     	b	0x25a70 <calculate_header_and_footer+0x2a34> @ imm = #0x0
   25a6c: e51b3064     	ldr	r3, [r11, #-0x64]
   25a70: e51b20b0     	ldr	r2, [r11, #-0xb0]
   25a74: e0823003     	add	r3, r2, r3
   25a78: e50b30b0     	str	r3, [r11, #-0xb0]
   25a7c: e51b0068     	ldr	r0, [r11, #-0x68]
   25a80: ebff9a65     	bl	0xc41c <free@plt>       @ imm = #-0x1966c
   25a84: e51b30b0     	ldr	r3, [r11, #-0xb0]
   25a88: e50b3060     	str	r3, [r11, #-0x60]
   25a8c: e3a03000     	mov	r3, #0
   25a90: e50b305c     	str	r3, [r11, #-0x5c]
   25a94: e51b3100     	ldr	r3, [r11, #-0x100]
   25a98: e5933028     	ldr	r3, [r3, #0x28]
   25a9c: e3530000     	cmp	r3, #0
   25aa0: 1a00000f     	bne	0x25ae4 <calculate_header_and_footer+0x2aa8> @ imm = #0x3c
   25aa4: e51b3460     	ldr	r3, [r11, #-0x460]
   25aa8: e593c000     	ldr	r12, [r3]
   25aac: e51b3460     	ldr	r3, [r11, #-0x460]
   25ab0: e5933004     	ldr	r3, [r3, #0x4]
   25ab4: e51b0104     	ldr	r0, [r11, #-0x104]
   25ab8: e3a01070     	mov	r1, #112
   25abc: e1a02183     	lsl	r2, r3, #3
   25ac0: e1a03182     	lsl	r3, r2, #3
   25ac4: e0623003     	rsb	r3, r2, r3
   25ac8: e51f2808     	ldr	r2, [pc, #-0x808]       @ 0x252c8 <calculate_header_and_footer+0x228c>
   25acc: e0020c92     	mul	r2, r2, r12
   25ad0: e0833002     	add	r3, r3, r2
   25ad4: e0803003     	add	r3, r0, r3
   25ad8: e0833001     	add	r3, r3, r1
   25adc: e5933000     	ldr	r3, [r3]
   25ae0: e50b305c     	str	r3, [r11, #-0x5c]
   25ae4: e51b305c     	ldr	r3, [r11, #-0x5c]
   25ae8: e3530000     	cmp	r3, #0
   25aec: 1a000021     	bne	0x25b78 <calculate_header_and_footer+0x2b3c> @ imm = #0x84
   25af0: e51b3104     	ldr	r3, [r11, #-0x104]
   25af4: e2833010     	add	r3, r3, #16
   25af8: e50b3058     	str	r3, [r11, #-0x58]
   25afc: e51b3058     	ldr	r3, [r11, #-0x58]
   25b00: e5933000     	ldr	r3, [r3]
   25b04: e3530000     	cmp	r3, #0
   25b08: 0a000003     	beq	0x25b1c <calculate_header_and_footer+0x2ae0> @ imm = #0xc
   25b0c: e51b3058     	ldr	r3, [r11, #-0x58]
   25b10: e5933000     	ldr	r3, [r3]
   25b14: e50b305c     	str	r3, [r11, #-0x5c]
   25b18: ea000016     	b	0x25b78 <calculate_header_and_footer+0x2b3c> @ imm = #0x58
   25b1c: e51b3058     	ldr	r3, [r11, #-0x58]
   25b20: e5933004     	ldr	r3, [r3, #0x4]
   25b24: e3530000     	cmp	r3, #0
   25b28: 0a000003     	beq	0x25b3c <calculate_header_and_footer+0x2b00> @ imm = #0xc
   25b2c: e51b3058     	ldr	r3, [r11, #-0x58]
   25b30: e5933004     	ldr	r3, [r3, #0x4]
   25b34: e50b305c     	str	r3, [r11, #-0x5c]
   25b38: ea00000e     	b	0x25b78 <calculate_header_and_footer+0x2b3c> @ imm = #0x38
   25b3c: e51b3058     	ldr	r3, [r11, #-0x58]
   25b40: e5933020     	ldr	r3, [r3, #0x20]
   25b44: e3530000     	cmp	r3, #0
   25b48: 0a000003     	beq	0x25b5c <calculate_header_and_footer+0x2b20> @ imm = #0xc
   25b4c: e51b3058     	ldr	r3, [r11, #-0x58]
   25b50: e5933020     	ldr	r3, [r3, #0x20]
   25b54: e50b305c     	str	r3, [r11, #-0x5c]
   25b58: ea000006     	b	0x25b78 <calculate_header_and_footer+0x2b3c> @ imm = #0x18
   25b5c: e51b3058     	ldr	r3, [r11, #-0x58]
   25b60: e5933024     	ldr	r3, [r3, #0x24]
   25b64: e3530000     	cmp	r3, #0
   25b68: 0a000002     	beq	0x25b78 <calculate_header_and_footer+0x2b3c> @ imm = #0x8
   25b6c: e51b3058     	ldr	r3, [r11, #-0x58]
   25b70: e5933024     	ldr	r3, [r3, #0x24]
   25b74: e50b305c     	str	r3, [r11, #-0x5c]
   25b78: e51b305c     	ldr	r3, [r11, #-0x5c]
   25b7c: e3530000     	cmp	r3, #0
   25b80: 0a0000a9     	beq	0x25e2c <calculate_header_and_footer+0x2df0> @ imm = #0x2a4
   25b84: e51b005c     	ldr	r0, [r11, #-0x5c]
   25b88: ebff9a53     	bl	0xc4dc <strlen@plt>     @ imm = #-0x196b4
   25b8c: e1a03000     	mov	r3, r0
   25b90: e51b005c     	ldr	r0, [r11, #-0x5c]
   25b94: e1a01003     	mov	r1, r3
   25b98: e51f28d4     	ldr	r2, [pc, #-0x8d4]       @ 0x252cc <calculate_header_and_footer+0x2290>
   25b9c: e51f38d4     	ldr	r3, [pc, #-0x8d4]       @ 0x252d0 <calculate_header_and_footer+0x2294>
   25ba0: ebffa253     	bl	0xe4f4 <charset_convert> @ imm = #-0x176b4
   25ba4: e1a03000     	mov	r3, r0
   25ba8: e50b3050     	str	r3, [r11, #-0x50]
   25bac: e51b0050     	ldr	r0, [r11, #-0x50]
   25bb0: ebff9a49     	bl	0xc4dc <strlen@plt>     @ imm = #-0x196dc
   25bb4: e1a03000     	mov	r3, r0
   25bb8: e50b3054     	str	r3, [r11, #-0x54]
   25bbc: e51b3060     	ldr	r3, [r11, #-0x60]
   25bc0: e3a02000     	mov	r2, #0
   25bc4: e3822044     	orr	r2, r2, #68
   25bc8: e5c32000     	strb	r2, [r3]
   25bcc: e3a02000     	mov	r2, #0
   25bd0: e3822049     	orr	r2, r2, #73
   25bd4: e5c32001     	strb	r2, [r3, #0x1]
   25bd8: e3a02000     	mov	r2, #0
   25bdc: e3822054     	orr	r2, r2, #84
   25be0: e5c32002     	strb	r2, [r3, #0x2]
   25be4: e3a02000     	mov	r2, #0
   25be8: e3822049     	orr	r2, r2, #73
   25bec: e5c32003     	strb	r2, [r3, #0x3]
   25bf0: e51b3054     	ldr	r3, [r11, #-0x54]
   25bf4: e2833004     	add	r3, r3, #4
   25bf8: e2033001     	and	r3, r3, #1
   25bfc: e6ef3073     	uxtb	r3, r3
   25c00: e3530000     	cmp	r3, #0
   25c04: 0a000002     	beq	0x25c14 <calculate_header_and_footer+0x2bd8> @ imm = #0x8
   25c08: e51b3054     	ldr	r3, [r11, #-0x54]
   25c0c: e2833005     	add	r3, r3, #5
   25c10: ea000001     	b	0x25c1c <calculate_header_and_footer+0x2be0> @ imm = #0x4
   25c14: e51b3054     	ldr	r3, [r11, #-0x54]
   25c18: e2833004     	add	r3, r3, #4
   25c1c: e1a02003     	mov	r2, r3
   25c20: e3a03000     	mov	r3, #0
   25c24: e51f1958     	ldr	r1, [pc, #-0x958]       @ 0x252d4 <calculate_header_and_footer+0x2298>
   25c28: e24b000c     	sub	r0, r11, #12
   25c2c: e18020f1     	strd	r2, r3, [r0, r1]
   25c30: e51f2964     	ldr	r2, [pc, #-0x964]       @ 0x252d4 <calculate_header_and_footer+0x2298>
   25c34: e3a03004     	mov	r3, #4
   25c38: e24b100c     	sub	r1, r11, #12
   25c3c: e0812002     	add	r2, r1, r2
   25c40: e0823003     	add	r3, r2, r3
   25c44: e5934000     	ldr	r4, [r3]
   25c48: e1a02c24     	lsr	r2, r4, #24
   25c4c: e20438ff     	and	r3, r4, #16711680
   25c50: e1a03423     	lsr	r3, r3, #8
   25c54: e1822003     	orr	r2, r2, r3
   25c58: e2043cff     	and	r3, r4, #65280
   25c5c: e1a03403     	lsl	r3, r3, #8
   25c60: e1822003     	orr	r2, r2, r3
   25c64: e1a03c04     	lsl	r3, r4, #24
   25c68: e1822003     	orr	r2, r2, r3
   25c6c: e51f399c     	ldr	r3, [pc, #-0x99c]       @ 0x252d8 <calculate_header_and_footer+0x229c>
   25c70: e24b000c     	sub	r0, r11, #12
   25c74: e7802003     	str	r2, [r0, r3]
   25c78: e51f39ac     	ldr	r3, [pc, #-0x9ac]       @ 0x252d4 <calculate_header_and_footer+0x2298>
   25c7c: e24b100c     	sub	r1, r11, #12
   25c80: e7914003     	ldr	r4, [r1, r3]
   25c84: e1a02c24     	lsr	r2, r4, #24
   25c88: e20438ff     	and	r3, r4, #16711680
   25c8c: e1a03423     	lsr	r3, r3, #8
   25c90: e1822003     	orr	r2, r2, r3
   25c94: e2043cff     	and	r3, r4, #65280
   25c98: e1a03403     	lsl	r3, r3, #8
   25c9c: e1822003     	orr	r2, r2, r3
   25ca0: e1a03c04     	lsl	r3, r4, #24
   25ca4: e1822003     	orr	r2, r2, r3
   25ca8: e51f19d8     	ldr	r1, [pc, #-0x9d8]       @ 0x252d8 <calculate_header_and_footer+0x229c>
   25cac: e3a03004     	mov	r3, #4
   25cb0: e24b000c     	sub	r0, r11, #12
   25cb4: e0801001     	add	r1, r0, r1
   25cb8: e0813003     	add	r3, r1, r3
   25cbc: e5832000     	str	r2, [r3]
   25cc0: e51f39f0     	ldr	r3, [pc, #-0x9f0]       @ 0x252d8 <calculate_header_and_footer+0x229c>
   25cc4: e24b100c     	sub	r1, r11, #12
   25cc8: e18320d1     	ldrd	r2, r3, [r3, r1]
   25ccc: e51b1060     	ldr	r1, [r11, #-0x60]
   25cd0: e20200ff     	and	r0, r2, #255
   25cd4: e3a0c000     	mov	r12, #0
   25cd8: e18c0000     	orr	r0, r12, r0
   25cdc: e5c10004     	strb	r0, [r1, #0x4]
   25ce0: e1a00422     	lsr	r0, r2, #8
   25ce4: e20000ff     	and	r0, r0, #255
   25ce8: e3a0c000     	mov	r12, #0
   25cec: e18c0000     	orr	r0, r12, r0
   25cf0: e5c10005     	strb	r0, [r1, #0x5]
   25cf4: e1a00822     	lsr	r0, r2, #16
   25cf8: e20000ff     	and	r0, r0, #255
   25cfc: e3a0c000     	mov	r12, #0
   25d00: e18c0000     	orr	r0, r12, r0
   25d04: e5c10006     	strb	r0, [r1, #0x6]
   25d08: e1a00c22     	lsr	r0, r2, #24
   25d0c: e3a0c000     	mov	r12, #0
   25d10: e18c0000     	orr	r0, r12, r0
   25d14: e5c10007     	strb	r0, [r1, #0x7]
   25d18: e20300ff     	and	r0, r3, #255
   25d1c: e3a0c000     	mov	r12, #0
   25d20: e18c0000     	orr	r0, r12, r0
   25d24: e5c10008     	strb	r0, [r1, #0x8]
   25d28: e1a00423     	lsr	r0, r3, #8
   25d2c: e20000ff     	and	r0, r0, #255
   25d30: e3a0c000     	mov	r12, #0
   25d34: e18c0000     	orr	r0, r12, r0
   25d38: e5c10009     	strb	r0, [r1, #0x9]
   25d3c: e1a00823     	lsr	r0, r3, #16
   25d40: e20000ff     	and	r0, r0, #255
   25d44: e3a0c000     	mov	r12, #0
   25d48: e18c0000     	orr	r0, r12, r0
   25d4c: e5c1000a     	strb	r0, [r1, #0xa]
   25d50: e1a03c23     	lsr	r3, r3, #24
   25d54: e3a02000     	mov	r2, #0
   25d58: e1823003     	orr	r3, r2, r3
   25d5c: e5c1300b     	strb	r3, [r1, #0xb]
   25d60: e51b4054     	ldr	r4, [r11, #-0x54]
   25d64: e1a02c24     	lsr	r2, r4, #24
   25d68: e20438ff     	and	r3, r4, #16711680
   25d6c: e1a03423     	lsr	r3, r3, #8
   25d70: e1822003     	orr	r2, r2, r3
   25d74: e2043cff     	and	r3, r4, #65280
   25d78: e1a03403     	lsl	r3, r3, #8
   25d7c: e1822003     	orr	r2, r2, r3
   25d80: e1a03c04     	lsl	r3, r4, #24
   25d84: e1822003     	orr	r2, r2, r3
   25d88: e51b3060     	ldr	r3, [r11, #-0x60]
   25d8c: e20210ff     	and	r1, r2, #255
   25d90: e3a00000     	mov	r0, #0
   25d94: e1801001     	orr	r1, r0, r1
   25d98: e5c3100c     	strb	r1, [r3, #0xc]
   25d9c: e1a01422     	lsr	r1, r2, #8
   25da0: e20110ff     	and	r1, r1, #255
   25da4: e3a00000     	mov	r0, #0
   25da8: e1801001     	orr	r1, r0, r1
   25dac: e5c3100d     	strb	r1, [r3, #0xd]
   25db0: e1a01822     	lsr	r1, r2, #16
   25db4: e20110ff     	and	r1, r1, #255
   25db8: e3a00000     	mov	r0, #0
   25dbc: e1801001     	orr	r1, r0, r1
   25dc0: e5c3100e     	strb	r1, [r3, #0xe]
   25dc4: e1a02c22     	lsr	r2, r2, #24
   25dc8: e3a01000     	mov	r1, #0
   25dcc: e1812002     	orr	r2, r1, r2
   25dd0: e5c3200f     	strb	r2, [r3, #0xf]
   25dd4: e51b30b0     	ldr	r3, [r11, #-0xb0]
   25dd8: e2833010     	add	r3, r3, #16
   25ddc: e50b30b0     	str	r3, [r11, #-0xb0]
   25de0: e51b3054     	ldr	r3, [r11, #-0x54]
   25de4: e51b00b0     	ldr	r0, [r11, #-0xb0]
   25de8: e51b1050     	ldr	r1, [r11, #-0x50]
   25dec: e1a02003     	mov	r2, r3
   25df0: ebff99c5     	bl	0xc50c <memcpy@plt>     @ imm = #-0x198ec
   25df4: e51b3054     	ldr	r3, [r11, #-0x54]
   25df8: e2033001     	and	r3, r3, #1
   25dfc: e6ef3073     	uxtb	r3, r3
   25e00: e3530000     	cmp	r3, #0
   25e04: 0a000002     	beq	0x25e14 <calculate_header_and_footer+0x2dd8> @ imm = #0x8
   25e08: e51b3054     	ldr	r3, [r11, #-0x54]
   25e0c: e2833001     	add	r3, r3, #1
   25e10: ea000000     	b	0x25e18 <calculate_header_and_footer+0x2ddc> @ imm = #0x0
   25e14: e51b3054     	ldr	r3, [r11, #-0x54]
   25e18: e51b20b0     	ldr	r2, [r11, #-0xb0]
   25e1c: e0823003     	add	r3, r2, r3
   25e20: e50b30b0     	str	r3, [r11, #-0xb0]
   25e24: e51b0050     	ldr	r0, [r11, #-0x50]
   25e28: ebff997b     	bl	0xc41c <free@plt>       @ imm = #-0x19a14
   25e2c: e51b20b0     	ldr	r2, [r11, #-0xb0]
   25e30: e51b3100     	ldr	r3, [r11, #-0x100]
   25e34: e5933008     	ldr	r3, [r3, #0x8]
   25e38: e0633002     	rsb	r3, r3, r2
   25e3c: e1a02003     	mov	r2, r3
   25e40: e51b3100     	ldr	r3, [r11, #-0x100]
   25e44: e593300c     	ldr	r3, [r3, #0xc]
   25e48: e0633002     	rsb	r3, r3, r2
   25e4c: e243300c     	sub	r3, r3, #12
   25e50: e2033001     	and	r3, r3, #1
   25e54: e6ef3073     	uxtb	r3, r3
   25e58: e3530000     	cmp	r3, #0
   25e5c: 0a000009     	beq	0x25e88 <calculate_header_and_footer+0x2e4c> @ imm = #0x24
   25e60: e51b20b0     	ldr	r2, [r11, #-0xb0]
   25e64: e51b3100     	ldr	r3, [r11, #-0x100]
   25e68: e5933008     	ldr	r3, [r3, #0x8]
   25e6c: e0633002     	rsb	r3, r3, r2
   25e70: e1a02003     	mov	r2, r3
   25e74: e51b3100     	ldr	r3, [r11, #-0x100]
   25e78: e593300c     	ldr	r3, [r3, #0xc]
   25e7c: e0633002     	rsb	r3, r3, r2
   25e80: e243300b     	sub	r3, r3, #11
   25e84: ea000008     	b	0x25eac <calculate_header_and_footer+0x2e70> @ imm = #0x20
   25e88: e51b20b0     	ldr	r2, [r11, #-0xb0]
   25e8c: e51b3100     	ldr	r3, [r11, #-0x100]
   25e90: e5933008     	ldr	r3, [r3, #0x8]
   25e94: e0633002     	rsb	r3, r3, r2
   25e98: e1a02003     	mov	r2, r3
   25e9c: e51b3100     	ldr	r3, [r11, #-0x100]
   25ea0: e593300c     	ldr	r3, [r3, #0xc]
   25ea4: e0633002     	rsb	r3, r3, r2
   25ea8: e243300c     	sub	r3, r3, #12
   25eac: e1a02003     	mov	r2, r3
   25eb0: e3a03000     	mov	r3, #0
   25eb4: e51f1be0     	ldr	r1, [pc, #-0xbe0]       @ 0x252dc <calculate_header_and_footer+0x22a0>
   25eb8: e24b000c     	sub	r0, r11, #12
   25ebc: e18020f1     	strd	r2, r3, [r0, r1]
   25ec0: e51f2bec     	ldr	r2, [pc, #-0xbec]       @ 0x252dc <calculate_header_and_footer+0x22a0>
   25ec4: e3a03004     	mov	r3, #4
   25ec8: e24b100c     	sub	r1, r11, #12
   25ecc: e0812002     	add	r2, r1, r2
   25ed0: e0823003     	add	r3, r2, r3
   25ed4: e5934000     	ldr	r4, [r3]
   25ed8: e1a02c24     	lsr	r2, r4, #24
   25edc: e20438ff     	and	r3, r4, #16711680
   25ee0: e1a03423     	lsr	r3, r3, #8
   25ee4: e1822003     	orr	r2, r2, r3
   25ee8: e2043cff     	and	r3, r4, #65280
   25eec: e1a03403     	lsl	r3, r3, #8
   25ef0: e1822003     	orr	r2, r2, r3
   25ef4: e1a03c04     	lsl	r3, r4, #24
   25ef8: e1822003     	orr	r2, r2, r3
   25efc: e51f3c24     	ldr	r3, [pc, #-0xc24]       @ 0x252e0 <calculate_header_and_footer+0x22a4>
   25f00: e24b000c     	sub	r0, r11, #12
   25f04: e7802003     	str	r2, [r0, r3]
   25f08: e51f3c34     	ldr	r3, [pc, #-0xc34]       @ 0x252dc <calculate_header_and_footer+0x22a0>
   25f0c: e24b100c     	sub	r1, r11, #12
   25f10: e7914003     	ldr	r4, [r1, r3]
   25f14: e1a02c24     	lsr	r2, r4, #24
   25f18: e20438ff     	and	r3, r4, #16711680
   25f1c: e1a03423     	lsr	r3, r3, #8
   25f20: e1822003     	orr	r2, r2, r3
   25f24: e2043cff     	and	r3, r4, #65280
   25f28: e1a03403     	lsl	r3, r3, #8
   25f2c: e1822003     	orr	r2, r2, r3
   25f30: e1a03c04     	lsl	r3, r4, #24
   25f34: e1822003     	orr	r2, r2, r3
   25f38: e51f1c60     	ldr	r1, [pc, #-0xc60]       @ 0x252e0 <calculate_header_and_footer+0x22a4>
   25f3c: e3a03004     	mov	r3, #4
   25f40: e24b000c     	sub	r0, r11, #12
   25f44: e0801001     	add	r1, r0, r1
   25f48: e0813003     	add	r3, r1, r3
   25f4c: e5832000     	str	r2, [r3]
   25f50: e51f3c78     	ldr	r3, [pc, #-0xc78]       @ 0x252e0 <calculate_header_and_footer+0x22a4>
   25f54: e24b100c     	sub	r1, r11, #12
   25f58: e18320d1     	ldrd	r2, r3, [r3, r1]
   25f5c: e51b10ac     	ldr	r1, [r11, #-0xac]
   25f60: e20200ff     	and	r0, r2, #255
   25f64: e3a0c000     	mov	r12, #0
   25f68: e18c0000     	orr	r0, r12, r0
   25f6c: e5c10004     	strb	r0, [r1, #0x4]
   25f70: e1a00422     	lsr	r0, r2, #8
   25f74: e20000ff     	and	r0, r0, #255
   25f78: e3a0c000     	mov	r12, #0
   25f7c: e18c0000     	orr	r0, r12, r0
   25f80: e5c10005     	strb	r0, [r1, #0x5]
   25f84: e1a00822     	lsr	r0, r2, #16
   25f88: e20000ff     	and	r0, r0, #255
   25f8c: e3a0c000     	mov	r12, #0
   25f90: e18c0000     	orr	r0, r12, r0
   25f94: e5c10006     	strb	r0, [r1, #0x6]
   25f98: e1a00c22     	lsr	r0, r2, #24
   25f9c: e3a0c000     	mov	r12, #0
   25fa0: e18c0000     	orr	r0, r12, r0
   25fa4: e5c10007     	strb	r0, [r1, #0x7]
   25fa8: e20300ff     	and	r0, r3, #255
   25fac: e3a0c000     	mov	r12, #0
   25fb0: e18c0000     	orr	r0, r12, r0
   25fb4: e5c10008     	strb	r0, [r1, #0x8]
   25fb8: e1a00423     	lsr	r0, r3, #8
   25fbc: e20000ff     	and	r0, r0, #255
   25fc0: e3a0c000     	mov	r12, #0
   25fc4: e18c0000     	orr	r0, r12, r0
   25fc8: e5c10009     	strb	r0, [r1, #0x9]
   25fcc: e1a00823     	lsr	r0, r3, #16
   25fd0: e20000ff     	and	r0, r0, #255
   25fd4: e3a0c000     	mov	r12, #0
   25fd8: e18c0000     	orr	r0, r12, r0
   25fdc: e5c1000a     	strb	r0, [r1, #0xa]
   25fe0: e1a03c23     	lsr	r3, r3, #24
   25fe4: e3a02000     	mov	r2, #0
   25fe8: e1823003     	orr	r3, r2, r3
   25fec: e5c1300b     	strb	r3, [r1, #0xb]
   25ff0: e51b3100     	ldr	r3, [r11, #-0x100]
   25ff4: e593200c     	ldr	r2, [r3, #0xc]
   25ff8: e51b10b0     	ldr	r1, [r11, #-0xb0]
   25ffc: e51b3100     	ldr	r3, [r11, #-0x100]
   26000: e5933008     	ldr	r3, [r3, #0x8]
   26004: e0633001     	rsb	r3, r3, r1
   26008: e1a01003     	mov	r1, r3
   2600c: e51b3100     	ldr	r3, [r11, #-0x100]
   26010: e593300c     	ldr	r3, [r3, #0xc]
   26014: e0633001     	rsb	r3, r3, r1
   26018: e2033001     	and	r3, r3, #1
   2601c: e6ef3073     	uxtb	r3, r3
   26020: e3530000     	cmp	r3, #0
   26024: 0a000009     	beq	0x26050 <calculate_header_and_footer+0x3014> @ imm = #0x24
   26028: e51b10b0     	ldr	r1, [r11, #-0xb0]
   2602c: e51b3100     	ldr	r3, [r11, #-0x100]
   26030: e5933008     	ldr	r3, [r3, #0x8]
   26034: e0633001     	rsb	r3, r3, r1
   26038: e1a01003     	mov	r1, r3
   2603c: e51b3100     	ldr	r3, [r11, #-0x100]
   26040: e593300c     	ldr	r3, [r3, #0xc]
   26044: e0633001     	rsb	r3, r3, r1
   26048: e2833001     	add	r3, r3, #1
   2604c: ea000007     	b	0x26070 <calculate_header_and_footer+0x3034> @ imm = #0x1c
   26050: e51b10b0     	ldr	r1, [r11, #-0xb0]
   26054: e51b3100     	ldr	r3, [r11, #-0x100]
   26058: e5933008     	ldr	r3, [r3, #0x8]
   2605c: e0633001     	rsb	r3, r3, r1
   26060: e1a01003     	mov	r1, r3
   26064: e51b3100     	ldr	r3, [r11, #-0x100]
   26068: e593300c     	ldr	r3, [r3, #0xc]
   2606c: e0633001     	rsb	r3, r3, r1
   26070: e0822003     	add	r2, r2, r3
   26074: e51b3100     	ldr	r3, [r11, #-0x100]
   26078: e583200c     	str	r2, [r3, #0xc]
   2607c: e51b3100     	ldr	r3, [r11, #-0x100]
   26080: e5932008     	ldr	r2, [r3, #0x8]
   26084: e51b3100     	ldr	r3, [r11, #-0x100]
   26088: e593300c     	ldr	r3, [r3, #0xc]
   2608c: e0823003     	add	r3, r2, r3
   26090: e50b3040     	str	r3, [r11, #-0x40]
   26094: e51b3040     	ldr	r3, [r11, #-0x40]
   26098: e50b303c     	str	r3, [r11, #-0x3c]
   2609c: e51b303c     	ldr	r3, [r11, #-0x3c]
   260a0: e3a02000     	mov	r2, #0
   260a4: e3822043     	orr	r2, r2, #67
   260a8: e5c32000     	strb	r2, [r3]
   260ac: e3a02000     	mov	r2, #0
   260b0: e382204f     	orr	r2, r2, #79
   260b4: e5c32001     	strb	r2, [r3, #0x1]
   260b8: e3a02000     	mov	r2, #0
   260bc: e382204d     	orr	r2, r2, #77
   260c0: e5c32002     	strb	r2, [r3, #0x2]
   260c4: e3a02000     	mov	r2, #0
   260c8: e3822054     	orr	r2, r2, #84
   260cc: e5c32003     	strb	r2, [r3, #0x3]
   260d0: e3a03002     	mov	r3, #2
   260d4: e14b33b6     	strh	r3, [r11, #-54]
   260d8: e15b33b6     	ldrh	r3, [r11, #-54]
   260dc: e1a03423     	lsr	r3, r3, #8
   260e0: e6ff3073     	uxth	r3, r3
   260e4: e1a02003     	mov	r2, r3
   260e8: e15b33b6     	ldrh	r3, [r11, #-54]
   260ec: e1a03403     	lsl	r3, r3, #8
   260f0: e1a03803     	lsl	r3, r3, #16
   260f4: e1a03823     	lsr	r3, r3, #16
   260f8: e1823003     	orr	r3, r2, r3
   260fc: e6ff2073     	uxth	r2, r3
   26100: e51b303c     	ldr	r3, [r11, #-0x3c]
   26104: e20210ff     	and	r1, r2, #255
   26108: e3a00000     	mov	r0, #0
   2610c: e1801001     	orr	r1, r0, r1
   26110: e5c3100c     	strb	r1, [r3, #0xc]
   26114: e1a02422     	lsr	r2, r2, #8
   26118: e6ff2072     	uxth	r2, r2
   2611c: e3a01000     	mov	r1, #0
   26120: e1812002     	orr	r2, r1, r2
   26124: e5c3200d     	strb	r2, [r3, #0xd]
   26128: e51b3040     	ldr	r3, [r11, #-0x40]
   2612c: e283300e     	add	r3, r3, #14
   26130: e50b3040     	str	r3, [r11, #-0x40]
   26134: e24b3f86     	sub	r3, r11, #536
   26138: e1a00003     	mov	r0, r3
   2613c: ebff9934     	bl	0xc614 <time@plt>       @ imm = #-0x19b30
   26140: e24b3f86     	sub	r3, r11, #536
   26144: e1a00003     	mov	r0, r3
   26148: ebff9844     	bl	0xc260 <localtime@plt>  @ imm = #-0x19ef0
   2614c: e1a03000     	mov	r3, r0
   26150: e50b304c     	str	r3, [r11, #-0x4c]
   26154: e51b3040     	ldr	r3, [r11, #-0x40]
   26158: e50b3048     	str	r3, [r11, #-0x48]
   2615c: e51b3104     	ldr	r3, [r11, #-0x104]
   26160: e5933008     	ldr	r3, [r3, #0x8]
   26164: e5d32078     	ldrb	r2, [r3, #0x78]
   26168: e5d33079     	ldrb	r3, [r3, #0x79]
   2616c: e1a03403     	lsl	r3, r3, #8
   26170: e1833002     	orr	r3, r3, r2
   26174: e14b33b4     	strh	r3, [r11, #-52]
   26178: e15b33b4     	ldrh	r3, [r11, #-52]
   2617c: e1a03423     	lsr	r3, r3, #8
   26180: e6ff3073     	uxth	r3, r3
   26184: e1a02003     	mov	r2, r3
   26188: e15b33b4     	ldrh	r3, [r11, #-52]
   2618c: e1a03403     	lsl	r3, r3, #8
   26190: e1a03803     	lsl	r3, r3, #16
   26194: e1a03823     	lsr	r3, r3, #16
   26198: e1823003     	orr	r3, r2, r3
   2619c: e6ff2073     	uxth	r2, r3
   261a0: e51b3048     	ldr	r3, [r11, #-0x48]
   261a4: e20210ff     	and	r1, r2, #255
   261a8: e3a00000     	mov	r0, #0
   261ac: e1801001     	orr	r1, r0, r1
   261b0: e5c31000     	strb	r1, [r3]
   261b4: e1a02422     	lsr	r2, r2, #8
   261b8: e6ff2072     	uxth	r2, r2
   261bc: e3a01000     	mov	r1, #0
   261c0: e1812002     	orr	r2, r1, r2
   261c4: e5c32001     	strb	r2, [r3, #0x1]
   261c8: e51b3104     	ldr	r3, [r11, #-0x104]
   261cc: e5933008     	ldr	r3, [r3, #0x8]
   261d0: e5d3207a     	ldrb	r2, [r3, #0x7a]
   261d4: e51b3048     	ldr	r3, [r11, #-0x48]
   261d8: e5c32002     	strb	r2, [r3, #0x2]
   261dc: e51b3104     	ldr	r3, [r11, #-0x104]
   261e0: e5933008     	ldr	r3, [r3, #0x8]
   261e4: e5d3207b     	ldrb	r2, [r3, #0x7b]
   261e8: e51b3048     	ldr	r3, [r11, #-0x48]
   261ec: e5c32003     	strb	r2, [r3, #0x3]
   261f0: e51b3048     	ldr	r3, [r11, #-0x48]
   261f4: e3a02000     	mov	r2, #0
   261f8: e5c32004     	strb	r2, [r3, #0x4]
   261fc: e51b3048     	ldr	r3, [r11, #-0x48]
   26200: e3a02000     	mov	r2, #0
   26204: e5c32005     	strb	r2, [r3, #0x5]
   26208: e3a03003     	mov	r3, #3
   2620c: e14b33b2     	strh	r3, [r11, #-50]
   26210: e15b33b2     	ldrh	r3, [r11, #-50]
   26214: e1a03423     	lsr	r3, r3, #8
   26218: e6ff3073     	uxth	r3, r3
   2621c: e1a02003     	mov	r2, r3
   26220: e15b33b2     	ldrh	r3, [r11, #-50]
   26224: e1a03403     	lsl	r3, r3, #8
   26228: e1a03803     	lsl	r3, r3, #16
   2622c: e1a03823     	lsr	r3, r3, #16
   26230: e1823003     	orr	r3, r2, r3
   26234: e6ff2073     	uxth	r2, r3
   26238: e51b3048     	ldr	r3, [r11, #-0x48]
   2623c: e20210ff     	and	r1, r2, #255
   26240: e3a00000     	mov	r0, #0
   26244: e1801001     	orr	r1, r0, r1
   26248: e5c31006     	strb	r1, [r3, #0x6]
   2624c: e1a02422     	lsr	r2, r2, #8
   26250: e6ff2072     	uxth	r2, r2
   26254: e3a01000     	mov	r1, #0
   26258: e1812002     	orr	r2, r1, r2
   2625c: e5c32007     	strb	r2, [r3, #0x7]
   26260: e3a03000     	mov	r3, #0
   26264: e14b33b0     	strh	r3, [r11, #-48]
   26268: e15b33b0     	ldrh	r3, [r11, #-48]
   2626c: e1a03423     	lsr	r3, r3, #8
   26270: e6ff3073     	uxth	r3, r3
   26274: e1a02003     	mov	r2, r3
   26278: e15b33b0     	ldrh	r3, [r11, #-48]
   2627c: e1a03403     	lsl	r3, r3, #8
   26280: e1a03803     	lsl	r3, r3, #16
   26284: e1a03823     	lsr	r3, r3, #16
   26288: e1823003     	orr	r3, r2, r3
   2628c: e6ff2073     	uxth	r2, r3
   26290: e51b3048     	ldr	r3, [r11, #-0x48]
   26294: e20210ff     	and	r1, r2, #255
   26298: e3a00000     	mov	r0, #0
   2629c: e1801001     	orr	r1, r0, r1
   262a0: e5c31008     	strb	r1, [r3, #0x8]
   262a4: e1a02422     	lsr	r2, r2, #8
   262a8: e6ff2072     	uxth	r2, r2
   262ac: e3a01000     	mov	r1, #0
   262b0: e1812002     	orr	r2, r1, r2
   262b4: e5c32009     	strb	r2, [r3, #0x9]
   262b8: e51b0104     	ldr	r0, [r11, #-0x104]
   262bc: ebfff23a     	bl	0x22bac <get_mtoc_title_text> @ imm = #-0x3718
   262c0: e1a03000     	mov	r3, r0
   262c4: e50b3044     	str	r3, [r11, #-0x44]
   262c8: e51b0044     	ldr	r0, [r11, #-0x44]
   262cc: ebff9882     	bl	0xc4dc <strlen@plt>     @ imm = #-0x19df8
   262d0: e1a03000     	mov	r3, r0
   262d4: e51b0044     	ldr	r0, [r11, #-0x44]
   262d8: e1a01003     	mov	r1, r3
   262dc: e59f2ce4     	ldr	r2, [pc, #0xce4]        @ 0x26fc8 <calculate_header_and_footer+0x3f8c>
   262e0: e59f3ce4     	ldr	r3, [pc, #0xce4]        @ 0x26fcc <calculate_header_and_footer+0x3f90>
   262e4: ebffa082     	bl	0xe4f4 <charset_convert> @ imm = #-0x17df8
   262e8: e1a03000     	mov	r3, r0
   262ec: e50b3044     	str	r3, [r11, #-0x44]
   262f0: e59f3cd8     	ldr	r3, [pc, #0xcd8]        @ 0x26fd0 <calculate_header_and_footer+0x3f94>
   262f4: e24b2e45     	sub	r2, r11, #1104
   262f8: e242200c     	sub	r2, r2, #12
   262fc: e1a00002     	mov	r0, r2
   26300: e1a01003     	mov	r1, r3
   26304: e51b2044     	ldr	r2, [r11, #-0x44]
   26308: ebff993c     	bl	0xc800 <sprintf@plt>    @ imm = #-0x19b10
   2630c: e51b0044     	ldr	r0, [r11, #-0x44]
   26310: ebff9841     	bl	0xc41c <free@plt>       @ imm = #-0x19efc
   26314: e24b3e45     	sub	r3, r11, #1104
   26318: e243300c     	sub	r3, r3, #12
   2631c: e1a00003     	mov	r0, r3
   26320: ebff986d     	bl	0xc4dc <strlen@plt>     @ imm = #-0x19e4c
   26324: e1a04000     	mov	r4, r0
   26328: e1a02c24     	lsr	r2, r4, #24
   2632c: e20438ff     	and	r3, r4, #16711680
   26330: e1a03423     	lsr	r3, r3, #8
   26334: e1822003     	orr	r2, r2, r3
   26338: e2043cff     	and	r3, r4, #65280
   2633c: e1a03403     	lsl	r3, r3, #8
   26340: e1822003     	orr	r2, r2, r3
   26344: e1a03c04     	lsl	r3, r4, #24
   26348: e1822003     	orr	r2, r2, r3
   2634c: e51b3048     	ldr	r3, [r11, #-0x48]
   26350: e20210ff     	and	r1, r2, #255
   26354: e3a00000     	mov	r0, #0
   26358: e1801001     	orr	r1, r0, r1
   2635c: e5c3100a     	strb	r1, [r3, #0xa]
   26360: e1a01422     	lsr	r1, r2, #8
   26364: e20110ff     	and	r1, r1, #255
   26368: e3a00000     	mov	r0, #0
   2636c: e1801001     	orr	r1, r0, r1
   26370: e5c3100b     	strb	r1, [r3, #0xb]
   26374: e1a01822     	lsr	r1, r2, #16
   26378: e20110ff     	and	r1, r1, #255
   2637c: e3a00000     	mov	r0, #0
   26380: e1801001     	orr	r1, r0, r1
   26384: e5c3100c     	strb	r1, [r3, #0xc]
   26388: e1a02c22     	lsr	r2, r2, #24
   2638c: e3a01000     	mov	r1, #0
   26390: e1812002     	orr	r2, r1, r2
   26394: e5c3200d     	strb	r2, [r3, #0xd]
   26398: e51b3048     	ldr	r3, [r11, #-0x48]
   2639c: e283400e     	add	r4, r3, #14
   263a0: e24b3e45     	sub	r3, r11, #1104
   263a4: e243300c     	sub	r3, r3, #12
   263a8: e1a00003     	mov	r0, r3
   263ac: ebff984a     	bl	0xc4dc <strlen@plt>     @ imm = #-0x19ed8
   263b0: e1a03000     	mov	r3, r0
   263b4: e24b2e45     	sub	r2, r11, #1104
   263b8: e242200c     	sub	r2, r2, #12
   263bc: e1a00004     	mov	r0, r4
   263c0: e1a01002     	mov	r1, r2
   263c4: e1a02003     	mov	r2, r3
   263c8: ebff984f     	bl	0xc50c <memcpy@plt>     @ imm = #-0x19ec4
   263cc: e24b3e45     	sub	r3, r11, #1104
   263d0: e243300c     	sub	r3, r3, #12
   263d4: e1a00003     	mov	r0, r3
   263d8: ebff983f     	bl	0xc4dc <strlen@plt>     @ imm = #-0x19f04
   263dc: e1a03000     	mov	r3, r0
   263e0: e283300e     	add	r3, r3, #14
   263e4: e2033001     	and	r3, r3, #1
   263e8: e6ef3073     	uxtb	r3, r3
   263ec: e3530000     	cmp	r3, #0
   263f0: 0a000006     	beq	0x26410 <calculate_header_and_footer+0x33d4> @ imm = #0x18
   263f4: e24b3e45     	sub	r3, r11, #1104
   263f8: e243300c     	sub	r3, r3, #12
   263fc: e1a00003     	mov	r0, r3
   26400: ebff9835     	bl	0xc4dc <strlen@plt>     @ imm = #-0x19f2c
   26404: e1a03000     	mov	r3, r0
   26408: e283300f     	add	r3, r3, #15
   2640c: ea000005     	b	0x26428 <calculate_header_and_footer+0x33ec> @ imm = #0x14
   26410: e24b3e45     	sub	r3, r11, #1104
   26414: e243300c     	sub	r3, r3, #12
   26418: e1a00003     	mov	r0, r3
   2641c: ebff982e     	bl	0xc4dc <strlen@plt>     @ imm = #-0x19f48
   26420: e1a03000     	mov	r3, r0
   26424: e283300e     	add	r3, r3, #14
   26428: e51b2040     	ldr	r2, [r11, #-0x40]
   2642c: e0823003     	add	r3, r2, r3
   26430: e50b3040     	str	r3, [r11, #-0x40]
   26434: e51b3040     	ldr	r3, [r11, #-0x40]
   26438: e50b3048     	str	r3, [r11, #-0x48]
   2643c: e51b304c     	ldr	r3, [r11, #-0x4c]
   26440: e5933014     	ldr	r3, [r3, #0x14]
   26444: e6ff3073     	uxth	r3, r3
   26448: e2833e76     	add	r3, r3, #1888
   2644c: e283300c     	add	r3, r3, #12
   26450: e14b32be     	strh	r3, [r11, #-46]
   26454: e15b32be     	ldrh	r3, [r11, #-46]
   26458: e1a03423     	lsr	r3, r3, #8
   2645c: e6ff3073     	uxth	r3, r3
   26460: e1a02003     	mov	r2, r3
   26464: e15b32be     	ldrh	r3, [r11, #-46]
   26468: e1a03403     	lsl	r3, r3, #8
   2646c: e1a03803     	lsl	r3, r3, #16
   26470: e1a03823     	lsr	r3, r3, #16
   26474: e1823003     	orr	r3, r2, r3
   26478: e6ff2073     	uxth	r2, r3
   2647c: e51b3048     	ldr	r3, [r11, #-0x48]
   26480: e20210ff     	and	r1, r2, #255
   26484: e3a00000     	mov	r0, #0
   26488: e1801001     	orr	r1, r0, r1
   2648c: e5c31000     	strb	r1, [r3]
   26490: e1a02422     	lsr	r2, r2, #8
   26494: e6ff2072     	uxth	r2, r2
   26498: e3a01000     	mov	r1, #0
   2649c: e1812002     	orr	r2, r1, r2
   264a0: e5c32001     	strb	r2, [r3, #0x1]
   264a4: e51b304c     	ldr	r3, [r11, #-0x4c]
   264a8: e5933010     	ldr	r3, [r3, #0x10]
   264ac: e6ef2073     	uxtb	r2, r3
   264b0: e51b3048     	ldr	r3, [r11, #-0x48]
   264b4: e5c32002     	strb	r2, [r3, #0x2]
   264b8: e51b304c     	ldr	r3, [r11, #-0x4c]
   264bc: e593300c     	ldr	r3, [r3, #0xc]
   264c0: e6ef2073     	uxtb	r2, r3
   264c4: e51b3048     	ldr	r3, [r11, #-0x48]
   264c8: e5c32003     	strb	r2, [r3, #0x3]
   264cc: e51b304c     	ldr	r3, [r11, #-0x4c]
   264d0: e5933008     	ldr	r3, [r3, #0x8]
   264d4: e6ef2073     	uxtb	r2, r3
   264d8: e51b3048     	ldr	r3, [r11, #-0x48]
   264dc: e5c32004     	strb	r2, [r3, #0x4]
   264e0: e51b304c     	ldr	r3, [r11, #-0x4c]
   264e4: e5933004     	ldr	r3, [r3, #0x4]
   264e8: e6ef2073     	uxtb	r2, r3
   264ec: e51b3048     	ldr	r3, [r11, #-0x48]
   264f0: e5c32005     	strb	r2, [r3, #0x5]
   264f4: e3a03003     	mov	r3, #3
   264f8: e14b32bc     	strh	r3, [r11, #-44]
   264fc: e15b32bc     	ldrh	r3, [r11, #-44]
   26500: e1a03423     	lsr	r3, r3, #8
   26504: e6ff3073     	uxth	r3, r3
   26508: e1a02003     	mov	r2, r3
   2650c: e15b32bc     	ldrh	r3, [r11, #-44]
   26510: e1a03403     	lsl	r3, r3, #8
   26514: e1a03803     	lsl	r3, r3, #16
   26518: e1a03823     	lsr	r3, r3, #16
   2651c: e1823003     	orr	r3, r2, r3
   26520: e6ff2073     	uxth	r2, r3
   26524: e51b3048     	ldr	r3, [r11, #-0x48]
   26528: e20210ff     	and	r1, r2, #255
   2652c: e3a00000     	mov	r0, #0
   26530: e1801001     	orr	r1, r0, r1
   26534: e5c31006     	strb	r1, [r3, #0x6]
   26538: e1a02422     	lsr	r2, r2, #8
   2653c: e6ff2072     	uxth	r2, r2
   26540: e3a01000     	mov	r1, #0
   26544: e1812002     	orr	r2, r1, r2
   26548: e5c32007     	strb	r2, [r3, #0x7]
   2654c: e3a03002     	mov	r3, #2
   26550: e14b32ba     	strh	r3, [r11, #-42]
   26554: e15b32ba     	ldrh	r3, [r11, #-42]
   26558: e1a03423     	lsr	r3, r3, #8
   2655c: e6ff3073     	uxth	r3, r3
   26560: e1a02003     	mov	r2, r3
   26564: e15b32ba     	ldrh	r3, [r11, #-42]
   26568: e1a03403     	lsl	r3, r3, #8
   2656c: e1a03803     	lsl	r3, r3, #16
   26570: e1a03823     	lsr	r3, r3, #16
   26574: e1823003     	orr	r3, r2, r3
   26578: e6ff2073     	uxth	r2, r3
   2657c: e51b3048     	ldr	r3, [r11, #-0x48]
   26580: e20210ff     	and	r1, r2, #255
   26584: e3a00000     	mov	r0, #0
   26588: e1801001     	orr	r1, r0, r1
   2658c: e5c31008     	strb	r1, [r3, #0x8]
   26590: e1a02422     	lsr	r2, r2, #8
   26594: e6ff2072     	uxth	r2, r2
   26598: e3a01000     	mov	r1, #0
   2659c: e1812002     	orr	r2, r1, r2
   265a0: e5c32009     	strb	r2, [r3, #0x9]
   265a4: e59f3a28     	ldr	r3, [pc, #0xa28]        @ 0x26fd4 <calculate_header_and_footer+0x3f98>
   265a8: e24b2e45     	sub	r2, r11, #1104
   265ac: e242200c     	sub	r2, r2, #12
   265b0: e1a00002     	mov	r0, r2
   265b4: e1a01003     	mov	r1, r3
   265b8: e3a0206f     	mov	r2, #111
   265bc: ebff97d2     	bl	0xc50c <memcpy@plt>     @ imm = #-0x1a0b8
   265c0: e24b3e45     	sub	r3, r11, #1104
   265c4: e243300c     	sub	r3, r3, #12
   265c8: e1a00003     	mov	r0, r3
   265cc: ebff97c2     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1a0f8
   265d0: e1a04000     	mov	r4, r0
   265d4: e1a02c24     	lsr	r2, r4, #24
   265d8: e20438ff     	and	r3, r4, #16711680
   265dc: e1a03423     	lsr	r3, r3, #8
   265e0: e1822003     	orr	r2, r2, r3
   265e4: e2043cff     	and	r3, r4, #65280
   265e8: e1a03403     	lsl	r3, r3, #8
   265ec: e1822003     	orr	r2, r2, r3
   265f0: e1a03c04     	lsl	r3, r4, #24
   265f4: e1822003     	orr	r2, r2, r3
   265f8: e51b3048     	ldr	r3, [r11, #-0x48]
   265fc: e20210ff     	and	r1, r2, #255
   26600: e3a00000     	mov	r0, #0
   26604: e1801001     	orr	r1, r0, r1
   26608: e5c3100a     	strb	r1, [r3, #0xa]
   2660c: e1a01422     	lsr	r1, r2, #8
   26610: e20110ff     	and	r1, r1, #255
   26614: e3a00000     	mov	r0, #0
   26618: e1801001     	orr	r1, r0, r1
   2661c: e5c3100b     	strb	r1, [r3, #0xb]
   26620: e1a01822     	lsr	r1, r2, #16
   26624: e20110ff     	and	r1, r1, #255
   26628: e3a00000     	mov	r0, #0
   2662c: e1801001     	orr	r1, r0, r1
   26630: e5c3100c     	strb	r1, [r3, #0xc]
   26634: e1a02c22     	lsr	r2, r2, #24
   26638: e3a01000     	mov	r1, #0
   2663c: e1812002     	orr	r2, r1, r2
   26640: e5c3200d     	strb	r2, [r3, #0xd]
   26644: e51b3048     	ldr	r3, [r11, #-0x48]
   26648: e283400e     	add	r4, r3, #14
   2664c: e24b3e45     	sub	r3, r11, #1104
   26650: e243300c     	sub	r3, r3, #12
   26654: e1a00003     	mov	r0, r3
   26658: ebff979f     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1a184
   2665c: e1a03000     	mov	r3, r0
   26660: e24b2e45     	sub	r2, r11, #1104
   26664: e242200c     	sub	r2, r2, #12
   26668: e1a00004     	mov	r0, r4
   2666c: e1a01002     	mov	r1, r2
   26670: e1a02003     	mov	r2, r3
   26674: ebff97a4     	bl	0xc50c <memcpy@plt>     @ imm = #-0x1a170
   26678: e24b3e45     	sub	r3, r11, #1104
   2667c: e243300c     	sub	r3, r3, #12
   26680: e1a00003     	mov	r0, r3
   26684: ebff9794     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1a1b0
   26688: e1a03000     	mov	r3, r0
   2668c: e283300e     	add	r3, r3, #14
   26690: e2033001     	and	r3, r3, #1
   26694: e6ef3073     	uxtb	r3, r3
   26698: e3530000     	cmp	r3, #0
   2669c: 0a000006     	beq	0x266bc <calculate_header_and_footer+0x3680> @ imm = #0x18
   266a0: e24b3e45     	sub	r3, r11, #1104
   266a4: e243300c     	sub	r3, r3, #12
   266a8: e1a00003     	mov	r0, r3
   266ac: ebff978a     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1a1d8
   266b0: e1a03000     	mov	r3, r0
   266b4: e283300f     	add	r3, r3, #15
   266b8: ea000005     	b	0x266d4 <calculate_header_and_footer+0x3698> @ imm = #0x14
   266bc: e24b3e45     	sub	r3, r11, #1104
   266c0: e243300c     	sub	r3, r3, #12
   266c4: e1a00003     	mov	r0, r3
   266c8: ebff9783     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1a1f4
   266cc: e1a03000     	mov	r3, r0
   266d0: e283300e     	add	r3, r3, #14
   266d4: e51b2040     	ldr	r2, [r11, #-0x40]
   266d8: e0823003     	add	r3, r2, r3
   266dc: e50b3040     	str	r3, [r11, #-0x40]
   266e0: e51b2040     	ldr	r2, [r11, #-0x40]
   266e4: e51b3100     	ldr	r3, [r11, #-0x100]
   266e8: e5933008     	ldr	r3, [r3, #0x8]
   266ec: e0633002     	rsb	r3, r3, r2
   266f0: e1a02003     	mov	r2, r3
   266f4: e51b3100     	ldr	r3, [r11, #-0x100]
   266f8: e593300c     	ldr	r3, [r3, #0xc]
   266fc: e0633002     	rsb	r3, r3, r2
   26700: e243300c     	sub	r3, r3, #12
   26704: e2033001     	and	r3, r3, #1
   26708: e6ef3073     	uxtb	r3, r3
   2670c: e3530000     	cmp	r3, #0
   26710: 0a000009     	beq	0x2673c <calculate_header_and_footer+0x3700> @ imm = #0x24
   26714: e51b2040     	ldr	r2, [r11, #-0x40]
   26718: e51b3100     	ldr	r3, [r11, #-0x100]
   2671c: e5933008     	ldr	r3, [r3, #0x8]
   26720: e0633002     	rsb	r3, r3, r2
   26724: e1a02003     	mov	r2, r3
   26728: e51b3100     	ldr	r3, [r11, #-0x100]
   2672c: e593300c     	ldr	r3, [r3, #0xc]
   26730: e0633002     	rsb	r3, r3, r2
   26734: e243300b     	sub	r3, r3, #11
   26738: ea000008     	b	0x26760 <calculate_header_and_footer+0x3724> @ imm = #0x20
   2673c: e51b2040     	ldr	r2, [r11, #-0x40]
   26740: e51b3100     	ldr	r3, [r11, #-0x100]
   26744: e5933008     	ldr	r3, [r3, #0x8]
   26748: e0633002     	rsb	r3, r3, r2
   2674c: e1a02003     	mov	r2, r3
   26750: e51b3100     	ldr	r3, [r11, #-0x100]
   26754: e593300c     	ldr	r3, [r3, #0xc]
   26758: e0633002     	rsb	r3, r3, r2
   2675c: e243300c     	sub	r3, r3, #12
   26760: e1a02003     	mov	r2, r3
   26764: e3a03000     	mov	r3, #0
   26768: e59f1868     	ldr	r1, [pc, #0x868]        @ 0x26fd8 <calculate_header_and_footer+0x3f9c>
   2676c: e24b000c     	sub	r0, r11, #12
   26770: e18020f1     	strd	r2, r3, [r0, r1]
   26774: e59f285c     	ldr	r2, [pc, #0x85c]        @ 0x26fd8 <calculate_header_and_footer+0x3f9c>
   26778: e3a03004     	mov	r3, #4
   2677c: e24b100c     	sub	r1, r11, #12
   26780: e0812002     	add	r2, r1, r2
   26784: e0823003     	add	r3, r2, r3
   26788: e5934000     	ldr	r4, [r3]
   2678c: e1a02c24     	lsr	r2, r4, #24
   26790: e20438ff     	and	r3, r4, #16711680
   26794: e1a03423     	lsr	r3, r3, #8
   26798: e1822003     	orr	r2, r2, r3
   2679c: e2043cff     	and	r3, r4, #65280
   267a0: e1a03403     	lsl	r3, r3, #8
   267a4: e1822003     	orr	r2, r2, r3
   267a8: e1a03c04     	lsl	r3, r4, #24
   267ac: e1822003     	orr	r2, r2, r3
   267b0: e59f3824     	ldr	r3, [pc, #0x824]        @ 0x26fdc <calculate_header_and_footer+0x3fa0>
   267b4: e24b000c     	sub	r0, r11, #12
   267b8: e7802003     	str	r2, [r0, r3]
   267bc: e59f3814     	ldr	r3, [pc, #0x814]        @ 0x26fd8 <calculate_header_and_footer+0x3f9c>
   267c0: e24b100c     	sub	r1, r11, #12
   267c4: e7914003     	ldr	r4, [r1, r3]
   267c8: e1a02c24     	lsr	r2, r4, #24
   267cc: e20438ff     	and	r3, r4, #16711680
   267d0: e1a03423     	lsr	r3, r3, #8
   267d4: e1822003     	orr	r2, r2, r3
   267d8: e2043cff     	and	r3, r4, #65280
   267dc: e1a03403     	lsl	r3, r3, #8
   267e0: e1822003     	orr	r2, r2, r3
   267e4: e1a03c04     	lsl	r3, r4, #24
   267e8: e1822003     	orr	r2, r2, r3
   267ec: e59f17e8     	ldr	r1, [pc, #0x7e8]        @ 0x26fdc <calculate_header_and_footer+0x3fa0>
   267f0: e3a03004     	mov	r3, #4
   267f4: e24b000c     	sub	r0, r11, #12
   267f8: e0801001     	add	r1, r0, r1
   267fc: e0813003     	add	r3, r1, r3
   26800: e5832000     	str	r2, [r3]
   26804: e59f37d0     	ldr	r3, [pc, #0x7d0]        @ 0x26fdc <calculate_header_and_footer+0x3fa0>
   26808: e24b100c     	sub	r1, r11, #12
   2680c: e18320d1     	ldrd	r2, r3, [r3, r1]
   26810: e51b103c     	ldr	r1, [r11, #-0x3c]
   26814: e20200ff     	and	r0, r2, #255
   26818: e3a0c000     	mov	r12, #0
   2681c: e18c0000     	orr	r0, r12, r0
   26820: e5c10004     	strb	r0, [r1, #0x4]
   26824: e1a00422     	lsr	r0, r2, #8
   26828: e20000ff     	and	r0, r0, #255
   2682c: e3a0c000     	mov	r12, #0
   26830: e18c0000     	orr	r0, r12, r0
   26834: e5c10005     	strb	r0, [r1, #0x5]
   26838: e1a00822     	lsr	r0, r2, #16
   2683c: e20000ff     	and	r0, r0, #255
   26840: e3a0c000     	mov	r12, #0
   26844: e18c0000     	orr	r0, r12, r0
   26848: e5c10006     	strb	r0, [r1, #0x6]
   2684c: e1a00c22     	lsr	r0, r2, #24
   26850: e3a0c000     	mov	r12, #0
   26854: e18c0000     	orr	r0, r12, r0
   26858: e5c10007     	strb	r0, [r1, #0x7]
   2685c: e20300ff     	and	r0, r3, #255
   26860: e3a0c000     	mov	r12, #0
   26864: e18c0000     	orr	r0, r12, r0
   26868: e5c10008     	strb	r0, [r1, #0x8]
   2686c: e1a00423     	lsr	r0, r3, #8
   26870: e20000ff     	and	r0, r0, #255
   26874: e3a0c000     	mov	r12, #0
   26878: e18c0000     	orr	r0, r12, r0
   2687c: e5c10009     	strb	r0, [r1, #0x9]
   26880: e1a00823     	lsr	r0, r3, #16
   26884: e20000ff     	and	r0, r0, #255
   26888: e3a0c000     	mov	r12, #0
   2688c: e18c0000     	orr	r0, r12, r0
   26890: e5c1000a     	strb	r0, [r1, #0xa]
   26894: e1a03c23     	lsr	r3, r3, #24
   26898: e3a02000     	mov	r2, #0
   2689c: e1823003     	orr	r3, r2, r3
   268a0: e5c1300b     	strb	r3, [r1, #0xb]
   268a4: e51b3100     	ldr	r3, [r11, #-0x100]
   268a8: e593200c     	ldr	r2, [r3, #0xc]
   268ac: e51b1040     	ldr	r1, [r11, #-0x40]
   268b0: e51b3100     	ldr	r3, [r11, #-0x100]
   268b4: e5933008     	ldr	r3, [r3, #0x8]
   268b8: e0633001     	rsb	r3, r3, r1
   268bc: e1a01003     	mov	r1, r3
   268c0: e51b3100     	ldr	r3, [r11, #-0x100]
   268c4: e593300c     	ldr	r3, [r3, #0xc]
   268c8: e0633001     	rsb	r3, r3, r1
   268cc: e2033001     	and	r3, r3, #1
   268d0: e6ef3073     	uxtb	r3, r3
   268d4: e3530000     	cmp	r3, #0
   268d8: 0a000009     	beq	0x26904 <calculate_header_and_footer+0x38c8> @ imm = #0x24
   268dc: e51b1040     	ldr	r1, [r11, #-0x40]
   268e0: e51b3100     	ldr	r3, [r11, #-0x100]
   268e4: e5933008     	ldr	r3, [r3, #0x8]
   268e8: e0633001     	rsb	r3, r3, r1
   268ec: e1a01003     	mov	r1, r3
   268f0: e51b3100     	ldr	r3, [r11, #-0x100]
   268f4: e593300c     	ldr	r3, [r3, #0xc]
   268f8: e0633001     	rsb	r3, r3, r1
   268fc: e2833001     	add	r3, r3, #1
   26900: ea000007     	b	0x26924 <calculate_header_and_footer+0x38e8> @ imm = #0x1c
   26904: e51b1040     	ldr	r1, [r11, #-0x40]
   26908: e51b3100     	ldr	r3, [r11, #-0x100]
   2690c: e5933008     	ldr	r3, [r3, #0x8]
   26910: e0633001     	rsb	r3, r3, r1
   26914: e1a01003     	mov	r1, r3
   26918: e51b3100     	ldr	r3, [r11, #-0x100]
   2691c: e593300c     	ldr	r3, [r3, #0xc]
   26920: e0633001     	rsb	r3, r3, r1
   26924: e0822003     	add	r2, r2, r3
   26928: e51b3100     	ldr	r3, [r11, #-0x100]
   2692c: e583200c     	str	r2, [r3, #0xc]
   26930: e51b3100     	ldr	r3, [r11, #-0x100]
   26934: e5933028     	ldr	r3, [r3, #0x28]
   26938: e3530000     	cmp	r3, #0
   2693c: 0a0000bf     	beq	0x26c40 <calculate_header_and_footer+0x3c04> @ imm = #0x2fc
   26940: e3a03000     	mov	r3, #0
   26944: e50b3028     	str	r3, [r11, #-0x28]
   26948: ea0000ad     	b	0x26c04 <calculate_header_and_footer+0x3bc8> @ imm = #0x2b4
   2694c: e51b3100     	ldr	r3, [r11, #-0x100]
   26950: e5932008     	ldr	r2, [r3, #0x8]
   26954: e51b3100     	ldr	r3, [r11, #-0x100]
   26958: e593300c     	ldr	r3, [r3, #0xc]
   2695c: e0823003     	add	r3, r2, r3
   26960: e50b301c     	str	r3, [r11, #-0x1c]
   26964: e51b301c     	ldr	r3, [r11, #-0x1c]
   26968: e50b3024     	str	r3, [r11, #-0x24]
   2696c: e51b3024     	ldr	r3, [r11, #-0x24]
   26970: e3a02000     	mov	r2, #0
   26974: e3822049     	orr	r2, r2, #73
   26978: e5c32000     	strb	r2, [r3]
   2697c: e3a02000     	mov	r2, #0
   26980: e3822044     	orr	r2, r2, #68
   26984: e5c32001     	strb	r2, [r3, #0x1]
   26988: e3a02000     	mov	r2, #0
   2698c: e3822033     	orr	r2, r2, #51
   26990: e5c32002     	strb	r2, [r3, #0x2]
   26994: e3a02000     	mov	r2, #0
   26998: e3822020     	orr	r2, r2, #32
   2699c: e5c32003     	strb	r2, [r3, #0x3]
   269a0: e51b301c     	ldr	r3, [r11, #-0x1c]
   269a4: e283200c     	add	r2, r3, #12
   269a8: e51b3460     	ldr	r3, [r11, #-0x460]
   269ac: e5933000     	ldr	r3, [r3]
   269b0: e51b0104     	ldr	r0, [r11, #-0x104]
   269b4: e1a01002     	mov	r1, r2
   269b8: e1a02003     	mov	r2, r3
   269bc: e51b3028     	ldr	r3, [r11, #-0x28]
   269c0: ebffe7a2     	bl	0x20850 <scarletbook_id3_tag_render> @ imm = #-0x6178
   269c4: e1a03000     	mov	r3, r0
   269c8: e50b3020     	str	r3, [r11, #-0x20]
   269cc: e51b3020     	ldr	r3, [r11, #-0x20]
   269d0: e2033001     	and	r3, r3, #1
   269d4: e6ef3073     	uxtb	r3, r3
   269d8: e3530000     	cmp	r3, #0
   269dc: 0a000002     	beq	0x269ec <calculate_header_and_footer+0x39b0> @ imm = #0x8
   269e0: e51b3020     	ldr	r3, [r11, #-0x20]
   269e4: e2833001     	add	r3, r3, #1
   269e8: ea000000     	b	0x269f0 <calculate_header_and_footer+0x39b4> @ imm = #0x0
   269ec: e51b3020     	ldr	r3, [r11, #-0x20]
   269f0: e1a02003     	mov	r2, r3
   269f4: e1a03fc2     	asr	r3, r2, #31
   269f8: e59f15e0     	ldr	r1, [pc, #0x5e0]        @ 0x26fe0 <calculate_header_and_footer+0x3fa4>
   269fc: e24b000c     	sub	r0, r11, #12
   26a00: e18020f1     	strd	r2, r3, [r0, r1]
   26a04: e59f25d4     	ldr	r2, [pc, #0x5d4]        @ 0x26fe0 <calculate_header_and_footer+0x3fa4>
   26a08: e3a03004     	mov	r3, #4
   26a0c: e24b100c     	sub	r1, r11, #12
   26a10: e0812002     	add	r2, r1, r2
   26a14: e0823003     	add	r3, r2, r3
   26a18: e5934000     	ldr	r4, [r3]
   26a1c: e1a02c24     	lsr	r2, r4, #24
   26a20: e20438ff     	and	r3, r4, #16711680
   26a24: e1a03423     	lsr	r3, r3, #8
   26a28: e1822003     	orr	r2, r2, r3
   26a2c: e2043cff     	and	r3, r4, #65280
   26a30: e1a03403     	lsl	r3, r3, #8
   26a34: e1822003     	orr	r2, r2, r3
   26a38: e1a03c04     	lsl	r3, r4, #24
   26a3c: e1822003     	orr	r2, r2, r3
   26a40: e59f359c     	ldr	r3, [pc, #0x59c]        @ 0x26fe4 <calculate_header_and_footer+0x3fa8>
   26a44: e24b000c     	sub	r0, r11, #12
   26a48: e7802003     	str	r2, [r0, r3]
   26a4c: e59f358c     	ldr	r3, [pc, #0x58c]        @ 0x26fe0 <calculate_header_and_footer+0x3fa4>
   26a50: e24b100c     	sub	r1, r11, #12
   26a54: e7914003     	ldr	r4, [r1, r3]
   26a58: e1a02c24     	lsr	r2, r4, #24
   26a5c: e20438ff     	and	r3, r4, #16711680
   26a60: e1a03423     	lsr	r3, r3, #8
   26a64: e1822003     	orr	r2, r2, r3
   26a68: e2043cff     	and	r3, r4, #65280
   26a6c: e1a03403     	lsl	r3, r3, #8
   26a70: e1822003     	orr	r2, r2, r3
   26a74: e1a03c04     	lsl	r3, r4, #24
   26a78: e1822003     	orr	r2, r2, r3
   26a7c: e59f1560     	ldr	r1, [pc, #0x560]        @ 0x26fe4 <calculate_header_and_footer+0x3fa8>
   26a80: e3a03004     	mov	r3, #4
   26a84: e24b000c     	sub	r0, r11, #12
   26a88: e0801001     	add	r1, r0, r1
   26a8c: e0813003     	add	r3, r1, r3
   26a90: e5832000     	str	r2, [r3]
   26a94: e59f3548     	ldr	r3, [pc, #0x548]        @ 0x26fe4 <calculate_header_and_footer+0x3fa8>
   26a98: e24b100c     	sub	r1, r11, #12
   26a9c: e18320d1     	ldrd	r2, r3, [r3, r1]
   26aa0: e51b1024     	ldr	r1, [r11, #-0x24]
   26aa4: e20200ff     	and	r0, r2, #255
   26aa8: e3a0c000     	mov	r12, #0
   26aac: e18c0000     	orr	r0, r12, r0
   26ab0: e5c10004     	strb	r0, [r1, #0x4]
   26ab4: e1a00422     	lsr	r0, r2, #8
   26ab8: e20000ff     	and	r0, r0, #255
   26abc: e3a0c000     	mov	r12, #0
   26ac0: e18c0000     	orr	r0, r12, r0
   26ac4: e5c10005     	strb	r0, [r1, #0x5]
   26ac8: e1a00822     	lsr	r0, r2, #16
   26acc: e20000ff     	and	r0, r0, #255
   26ad0: e3a0c000     	mov	r12, #0
   26ad4: e18c0000     	orr	r0, r12, r0
   26ad8: e5c10006     	strb	r0, [r1, #0x6]
   26adc: e1a00c22     	lsr	r0, r2, #24
   26ae0: e3a0c000     	mov	r12, #0
   26ae4: e18c0000     	orr	r0, r12, r0
   26ae8: e5c10007     	strb	r0, [r1, #0x7]
   26aec: e20300ff     	and	r0, r3, #255
   26af0: e3a0c000     	mov	r12, #0
   26af4: e18c0000     	orr	r0, r12, r0
   26af8: e5c10008     	strb	r0, [r1, #0x8]
   26afc: e1a00423     	lsr	r0, r3, #8
   26b00: e20000ff     	and	r0, r0, #255
   26b04: e3a0c000     	mov	r12, #0
   26b08: e18c0000     	orr	r0, r12, r0
   26b0c: e5c10009     	strb	r0, [r1, #0x9]
   26b10: e1a00823     	lsr	r0, r3, #16
   26b14: e20000ff     	and	r0, r0, #255
   26b18: e3a0c000     	mov	r12, #0
   26b1c: e18c0000     	orr	r0, r12, r0
   26b20: e5c1000a     	strb	r0, [r1, #0xa]
   26b24: e1a03c23     	lsr	r3, r3, #24
   26b28: e3a02000     	mov	r2, #0
   26b2c: e1823003     	orr	r3, r2, r3
   26b30: e5c1300b     	strb	r3, [r1, #0xb]
   26b34: e51b3020     	ldr	r3, [r11, #-0x20]
   26b38: e283300c     	add	r3, r3, #12
   26b3c: e2033001     	and	r3, r3, #1
   26b40: e6ef3073     	uxtb	r3, r3
   26b44: e3530000     	cmp	r3, #0
   26b48: 0a000002     	beq	0x26b58 <calculate_header_and_footer+0x3b1c> @ imm = #0x8
   26b4c: e51b3020     	ldr	r3, [r11, #-0x20]
   26b50: e283300d     	add	r3, r3, #13
   26b54: ea000001     	b	0x26b60 <calculate_header_and_footer+0x3b24> @ imm = #0x4
   26b58: e51b3020     	ldr	r3, [r11, #-0x20]
   26b5c: e283300c     	add	r3, r3, #12
   26b60: e51b201c     	ldr	r2, [r11, #-0x1c]
   26b64: e0823003     	add	r3, r2, r3
   26b68: e50b301c     	str	r3, [r11, #-0x1c]
   26b6c: e51b3100     	ldr	r3, [r11, #-0x100]
   26b70: e593200c     	ldr	r2, [r3, #0xc]
   26b74: e51b101c     	ldr	r1, [r11, #-0x1c]
   26b78: e51b3100     	ldr	r3, [r11, #-0x100]
   26b7c: e5933008     	ldr	r3, [r3, #0x8]
   26b80: e0633001     	rsb	r3, r3, r1
   26b84: e1a01003     	mov	r1, r3
   26b88: e51b3100     	ldr	r3, [r11, #-0x100]
   26b8c: e593300c     	ldr	r3, [r3, #0xc]
   26b90: e0633001     	rsb	r3, r3, r1
   26b94: e2033001     	and	r3, r3, #1
   26b98: e6ef3073     	uxtb	r3, r3
   26b9c: e3530000     	cmp	r3, #0
   26ba0: 0a000009     	beq	0x26bcc <calculate_header_and_footer+0x3b90> @ imm = #0x24
   26ba4: e51b101c     	ldr	r1, [r11, #-0x1c]
   26ba8: e51b3100     	ldr	r3, [r11, #-0x100]
   26bac: e5933008     	ldr	r3, [r3, #0x8]
   26bb0: e0633001     	rsb	r3, r3, r1
   26bb4: e1a01003     	mov	r1, r3
   26bb8: e51b3100     	ldr	r3, [r11, #-0x100]
   26bbc: e593300c     	ldr	r3, [r3, #0xc]
   26bc0: e0633001     	rsb	r3, r3, r1
   26bc4: e2833001     	add	r3, r3, #1
   26bc8: ea000007     	b	0x26bec <calculate_header_and_footer+0x3bb0> @ imm = #0x1c
   26bcc: e51b101c     	ldr	r1, [r11, #-0x1c]
   26bd0: e51b3100     	ldr	r3, [r11, #-0x100]
   26bd4: e5933008     	ldr	r3, [r3, #0x8]
   26bd8: e0633001     	rsb	r3, r3, r1
   26bdc: e1a01003     	mov	r1, r3
   26be0: e51b3100     	ldr	r3, [r11, #-0x100]
   26be4: e593300c     	ldr	r3, [r3, #0xc]
   26be8: e0633001     	rsb	r3, r3, r1
   26bec: e0822003     	add	r2, r2, r3
   26bf0: e51b3100     	ldr	r3, [r11, #-0x100]
   26bf4: e583200c     	str	r2, [r3, #0xc]
   26bf8: e51b3028     	ldr	r3, [r11, #-0x28]
   26bfc: e2833001     	add	r3, r3, #1
   26c00: e50b3028     	str	r3, [r11, #-0x28]
   26c04: e51b3460     	ldr	r3, [r11, #-0x460]
   26c08: e5932000     	ldr	r2, [r3]
   26c0c: e51b1104     	ldr	r1, [r11, #-0x104]
   26c10: e3a03060     	mov	r3, #96
   26c14: e59f03cc     	ldr	r0, [pc, #0x3cc]        @ 0x26fe8 <calculate_header_and_footer+0x3fac>
   26c18: e0020290     	mul	r2, r0, r2
   26c1c: e0812002     	add	r2, r1, r2
   26c20: e0823003     	add	r3, r2, r3
   26c24: e5933000     	ldr	r3, [r3]
   26c28: e5d33045     	ldrb	r3, [r3, #0x45]
   26c2c: e1a02003     	mov	r2, r3
   26c30: e51b3028     	ldr	r3, [r11, #-0x28]
   26c34: e1520003     	cmp	r2, r3
   26c38: caffff43     	bgt	0x2694c <calculate_header_and_footer+0x3910> @ imm = #-0x2f4
   26c3c: ea0000a9     	b	0x26ee8 <calculate_header_and_footer+0x3eac> @ imm = #0x2a4
   26c40: e51b3100     	ldr	r3, [r11, #-0x100]
   26c44: e5932008     	ldr	r2, [r3, #0x8]
   26c48: e51b3100     	ldr	r3, [r11, #-0x100]
   26c4c: e593300c     	ldr	r3, [r3, #0xc]
   26c50: e0823003     	add	r3, r2, r3
   26c54: e50b3010     	str	r3, [r11, #-0x10]
   26c58: e51b3010     	ldr	r3, [r11, #-0x10]
   26c5c: e50b3018     	str	r3, [r11, #-0x18]
   26c60: e51b3018     	ldr	r3, [r11, #-0x18]
   26c64: e3a02000     	mov	r2, #0
   26c68: e3822049     	orr	r2, r2, #73
   26c6c: e5c32000     	strb	r2, [r3]
   26c70: e3a02000     	mov	r2, #0
   26c74: e3822044     	orr	r2, r2, #68
   26c78: e5c32001     	strb	r2, [r3, #0x1]
   26c7c: e3a02000     	mov	r2, #0
   26c80: e3822033     	orr	r2, r2, #51
   26c84: e5c32002     	strb	r2, [r3, #0x2]
   26c88: e3a02000     	mov	r2, #0
   26c8c: e3822020     	orr	r2, r2, #32
   26c90: e5c32003     	strb	r2, [r3, #0x3]
   26c94: e51b3010     	ldr	r3, [r11, #-0x10]
   26c98: e283100c     	add	r1, r3, #12
   26c9c: e51b3460     	ldr	r3, [r11, #-0x460]
   26ca0: e5932000     	ldr	r2, [r3]
   26ca4: e51b3460     	ldr	r3, [r11, #-0x460]
   26ca8: e5933004     	ldr	r3, [r3, #0x4]
   26cac: e51b0104     	ldr	r0, [r11, #-0x104]
   26cb0: ebffe6e6     	bl	0x20850 <scarletbook_id3_tag_render> @ imm = #-0x6468
   26cb4: e1a03000     	mov	r3, r0
   26cb8: e50b3014     	str	r3, [r11, #-0x14]
   26cbc: e51b3014     	ldr	r3, [r11, #-0x14]
   26cc0: e2033001     	and	r3, r3, #1
   26cc4: e6ef3073     	uxtb	r3, r3
   26cc8: e3530000     	cmp	r3, #0
   26ccc: 0a000002     	beq	0x26cdc <calculate_header_and_footer+0x3ca0> @ imm = #0x8
   26cd0: e51b3014     	ldr	r3, [r11, #-0x14]
   26cd4: e2833001     	add	r3, r3, #1
   26cd8: ea000000     	b	0x26ce0 <calculate_header_and_footer+0x3ca4> @ imm = #0x0
   26cdc: e51b3014     	ldr	r3, [r11, #-0x14]
   26ce0: e1a02003     	mov	r2, r3
   26ce4: e1a03fc2     	asr	r3, r2, #31
   26ce8: e59f12fc     	ldr	r1, [pc, #0x2fc]        @ 0x26fec <calculate_header_and_footer+0x3fb0>
   26cec: e24b000c     	sub	r0, r11, #12
   26cf0: e18020f1     	strd	r2, r3, [r0, r1]
   26cf4: e59f22f0     	ldr	r2, [pc, #0x2f0]        @ 0x26fec <calculate_header_and_footer+0x3fb0>
   26cf8: e3a03004     	mov	r3, #4
   26cfc: e24b100c     	sub	r1, r11, #12
   26d00: e0812002     	add	r2, r1, r2
   26d04: e0823003     	add	r3, r2, r3
   26d08: e5934000     	ldr	r4, [r3]
   26d0c: e1a02c24     	lsr	r2, r4, #24
   26d10: e20438ff     	and	r3, r4, #16711680
   26d14: e1a03423     	lsr	r3, r3, #8
   26d18: e1822003     	orr	r2, r2, r3
   26d1c: e2043cff     	and	r3, r4, #65280
   26d20: e1a03403     	lsl	r3, r3, #8
   26d24: e1822003     	orr	r2, r2, r3
   26d28: e1a03c04     	lsl	r3, r4, #24
   26d2c: e1822003     	orr	r2, r2, r3
   26d30: e59f32b8     	ldr	r3, [pc, #0x2b8]        @ 0x26ff0 <calculate_header_and_footer+0x3fb4>
   26d34: e24b000c     	sub	r0, r11, #12
   26d38: e7802003     	str	r2, [r0, r3]
   26d3c: e59f32a8     	ldr	r3, [pc, #0x2a8]        @ 0x26fec <calculate_header_and_footer+0x3fb0>
   26d40: e24b100c     	sub	r1, r11, #12
   26d44: e7914003     	ldr	r4, [r1, r3]
   26d48: e1a02c24     	lsr	r2, r4, #24
   26d4c: e20438ff     	and	r3, r4, #16711680
   26d50: e1a03423     	lsr	r3, r3, #8
   26d54: e1822003     	orr	r2, r2, r3
   26d58: e2043cff     	and	r3, r4, #65280
   26d5c: e1a03403     	lsl	r3, r3, #8
   26d60: e1822003     	orr	r2, r2, r3
   26d64: e1a03c04     	lsl	r3, r4, #24
   26d68: e1822003     	orr	r2, r2, r3
   26d6c: e59f127c     	ldr	r1, [pc, #0x27c]        @ 0x26ff0 <calculate_header_and_footer+0x3fb4>
   26d70: e3a03004     	mov	r3, #4
   26d74: e24b000c     	sub	r0, r11, #12
   26d78: e0801001     	add	r1, r0, r1
   26d7c: e0813003     	add	r3, r1, r3
   26d80: e5832000     	str	r2, [r3]
   26d84: e59f3264     	ldr	r3, [pc, #0x264]        @ 0x26ff0 <calculate_header_and_footer+0x3fb4>
   26d88: e24b100c     	sub	r1, r11, #12
   26d8c: e18320d1     	ldrd	r2, r3, [r3, r1]
   26d90: e51b1018     	ldr	r1, [r11, #-0x18]
   26d94: e20200ff     	and	r0, r2, #255
   26d98: e3a0c000     	mov	r12, #0
   26d9c: e18c0000     	orr	r0, r12, r0
   26da0: e5c10004     	strb	r0, [r1, #0x4]
   26da4: e1a00422     	lsr	r0, r2, #8
   26da8: e20000ff     	and	r0, r0, #255
   26dac: e3a0c000     	mov	r12, #0
   26db0: e18c0000     	orr	r0, r12, r0
   26db4: e5c10005     	strb	r0, [r1, #0x5]
   26db8: e1a00822     	lsr	r0, r2, #16
   26dbc: e20000ff     	and	r0, r0, #255
   26dc0: e3a0c000     	mov	r12, #0
   26dc4: e18c0000     	orr	r0, r12, r0
   26dc8: e5c10006     	strb	r0, [r1, #0x6]
   26dcc: e1a00c22     	lsr	r0, r2, #24
   26dd0: e3a0c000     	mov	r12, #0
   26dd4: e18c0000     	orr	r0, r12, r0
   26dd8: e5c10007     	strb	r0, [r1, #0x7]
   26ddc: e20300ff     	and	r0, r3, #255
   26de0: e3a0c000     	mov	r12, #0
   26de4: e18c0000     	orr	r0, r12, r0
   26de8: e5c10008     	strb	r0, [r1, #0x8]
   26dec: e1a00423     	lsr	r0, r3, #8
   26df0: e20000ff     	and	r0, r0, #255
   26df4: e3a0c000     	mov	r12, #0
   26df8: e18c0000     	orr	r0, r12, r0
   26dfc: e5c10009     	strb	r0, [r1, #0x9]
   26e00: e1a00823     	lsr	r0, r3, #16
   26e04: e20000ff     	and	r0, r0, #255
   26e08: e3a0c000     	mov	r12, #0
   26e0c: e18c0000     	orr	r0, r12, r0
   26e10: e5c1000a     	strb	r0, [r1, #0xa]
   26e14: e1a03c23     	lsr	r3, r3, #24
   26e18: e3a02000     	mov	r2, #0
   26e1c: e1823003     	orr	r3, r2, r3
   26e20: e5c1300b     	strb	r3, [r1, #0xb]
   26e24: e51b3014     	ldr	r3, [r11, #-0x14]
   26e28: e283300c     	add	r3, r3, #12
   26e2c: e2033001     	and	r3, r3, #1
   26e30: e6ef3073     	uxtb	r3, r3
   26e34: e3530000     	cmp	r3, #0
   26e38: 0a000002     	beq	0x26e48 <calculate_header_and_footer+0x3e0c> @ imm = #0x8
   26e3c: e51b3014     	ldr	r3, [r11, #-0x14]
   26e40: e283300d     	add	r3, r3, #13
   26e44: ea000001     	b	0x26e50 <calculate_header_and_footer+0x3e14> @ imm = #0x4
   26e48: e51b3014     	ldr	r3, [r11, #-0x14]
   26e4c: e283300c     	add	r3, r3, #12
   26e50: e51b2010     	ldr	r2, [r11, #-0x10]
   26e54: e0823003     	add	r3, r2, r3
   26e58: e50b3010     	str	r3, [r11, #-0x10]
   26e5c: e51b3100     	ldr	r3, [r11, #-0x100]
   26e60: e593200c     	ldr	r2, [r3, #0xc]
   26e64: e51b1010     	ldr	r1, [r11, #-0x10]
   26e68: e51b3100     	ldr	r3, [r11, #-0x100]
   26e6c: e5933008     	ldr	r3, [r3, #0x8]
   26e70: e0633001     	rsb	r3, r3, r1
   26e74: e1a01003     	mov	r1, r3
   26e78: e51b3100     	ldr	r3, [r11, #-0x100]
   26e7c: e593300c     	ldr	r3, [r3, #0xc]
   26e80: e0633001     	rsb	r3, r3, r1
   26e84: e2033001     	and	r3, r3, #1
   26e88: e6ef3073     	uxtb	r3, r3
   26e8c: e3530000     	cmp	r3, #0
   26e90: 0a000009     	beq	0x26ebc <calculate_header_and_footer+0x3e80> @ imm = #0x24
   26e94: e51b1010     	ldr	r1, [r11, #-0x10]
   26e98: e51b3100     	ldr	r3, [r11, #-0x100]
   26e9c: e5933008     	ldr	r3, [r3, #0x8]
   26ea0: e0633001     	rsb	r3, r3, r1
   26ea4: e1a01003     	mov	r1, r3
   26ea8: e51b3100     	ldr	r3, [r11, #-0x100]
   26eac: e593300c     	ldr	r3, [r3, #0xc]
   26eb0: e0633001     	rsb	r3, r3, r1
   26eb4: e2833001     	add	r3, r3, #1
   26eb8: ea000007     	b	0x26edc <calculate_header_and_footer+0x3ea0> @ imm = #0x1c
   26ebc: e51b1010     	ldr	r1, [r11, #-0x10]
   26ec0: e51b3100     	ldr	r3, [r11, #-0x100]
   26ec4: e5933008     	ldr	r3, [r3, #0x8]
   26ec8: e0633001     	rsb	r3, r3, r1
   26ecc: e1a01003     	mov	r1, r3
   26ed0: e51b3100     	ldr	r3, [r11, #-0x100]
   26ed4: e593300c     	ldr	r3, [r3, #0xc]
   26ed8: e0633001     	rsb	r3, r3, r1
   26edc: e0822003     	add	r2, r2, r3
   26ee0: e51b3100     	ldr	r3, [r11, #-0x100]
   26ee4: e583200c     	str	r2, [r3, #0xc]
   26ee8: e51b210c     	ldr	r2, [r11, #-0x10c]
   26eec: e51b3100     	ldr	r3, [r11, #-0x100]
   26ef0: e5933000     	ldr	r3, [r3]
   26ef4: e0633002     	rsb	r3, r3, r2
   26ef8: e2033001     	and	r3, r3, #1
   26efc: e6ef3073     	uxtb	r3, r3
   26f00: e3530000     	cmp	r3, #0
   26f04: 0a000005     	beq	0x26f20 <calculate_header_and_footer+0x3ee4> @ imm = #0x14
   26f08: e51b210c     	ldr	r2, [r11, #-0x10c]
   26f0c: e51b3100     	ldr	r3, [r11, #-0x100]
   26f10: e5933000     	ldr	r3, [r3]
   26f14: e0633002     	rsb	r3, r3, r2
   26f18: e2833001     	add	r3, r3, #1
   26f1c: ea000003     	b	0x26f30 <calculate_header_and_footer+0x3ef4> @ imm = #0xc
   26f20: e51b210c     	ldr	r2, [r11, #-0x10c]
   26f24: e51b3100     	ldr	r3, [r11, #-0x100]
   26f28: e5933000     	ldr	r3, [r3]
   26f2c: e0633002     	rsb	r3, r3, r2
   26f30: e51b2100     	ldr	r2, [r11, #-0x100]
   26f34: e5823004     	str	r3, [r2, #0x4]
   26f38: e51b3100     	ldr	r3, [r11, #-0x100]
   26f3c: e5932004     	ldr	r2, [r3, #0x4]
   26f40: e51b3100     	ldr	r3, [r11, #-0x100]
   26f44: e593300c     	ldr	r3, [r3, #0xc]
   26f48: e0823003     	add	r3, r2, r3
   26f4c: e1a00003     	mov	r0, r3
   26f50: e3a01000     	mov	r1, #0
   26f54: e51b3100     	ldr	r3, [r11, #-0x100]
   26f58: e1c321d8     	ldrd	r2, r3, [r3, #24]
   26f5c: e0900002     	adds	r0, r0, r2
   26f60: e0a11003     	adc	r1, r1, r3
   26f64: e3e0200b     	mvn	r2, #11
   26f68: e3e03000     	mvn	r3, #0
   26f6c: e0922000     	adds	r2, r2, r0
   26f70: e0a33001     	adc	r3, r3, r1
   26f74: e1a03002     	mov	r3, r2
   26f78: e2033001     	and	r3, r3, #1
   26f7c: e6ef3073     	uxtb	r3, r3
   26f80: e3530000     	cmp	r3, #0
   26f84: 0a00001c     	beq	0x26ffc <calculate_header_and_footer+0x3fc0> @ imm = #0x70
   26f88: e51b3100     	ldr	r3, [r11, #-0x100]
   26f8c: e5932004     	ldr	r2, [r3, #0x4]
   26f90: e51b3100     	ldr	r3, [r11, #-0x100]
   26f94: e593300c     	ldr	r3, [r3, #0xc]
   26f98: e0823003     	add	r3, r2, r3
   26f9c: e1a00003     	mov	r0, r3
   26fa0: e3a01000     	mov	r1, #0
   26fa4: e51b3100     	ldr	r3, [r11, #-0x100]
   26fa8: e1c321d8     	ldrd	r2, r3, [r3, #24]
   26fac: e0900002     	adds	r0, r0, r2
   26fb0: e0a11003     	adc	r1, r1, r3
   26fb4: e3e0200a     	mvn	r2, #10
   26fb8: e3e03000     	mvn	r3, #0
   26fbc: e0922000     	adds	r2, r2, r0
   26fc0: e0a33001     	adc	r3, r3, r1
   26fc4: ea00001b     	b	0x27038 <calculate_header_and_footer+0x3ffc> @ imm = #0x6c
   26fc8: 54 55 03 00  	.word	0x00035554
   26fcc: 5c 55 03 00  	.word	0x0003555c
   26fd0: 68 55 03 00  	.word	0x00035568
   26fd4: 88 55 03 00  	.word	0x00035588
   26fd8: e8 fd ff ff  	.word	0xfffffde8
   26fdc: e0 fd ff ff  	.word	0xfffffde0
   26fe0: d8 fd ff ff  	.word	0xfffffdd8
   26fe4: d0 fd ff ff  	.word	0xfffffdd0
   26fe8: f0 37 00 00  	.word	0x000037f0
   26fec: c8 fd ff ff  	.word	0xfffffdc8
   26ff0: c0 fd ff ff  	.word	0xfffffdc0
   26ff4: b8 fd ff ff  	.word	0xfffffdb8
   26ff8: b0 fd ff ff  	.word	0xfffffdb0
   26ffc: e51b3100     	ldr	r3, [r11, #-0x100]
   27000: e5932004     	ldr	r2, [r3, #0x4]
   27004: e51b3100     	ldr	r3, [r11, #-0x100]
   27008: e593300c     	ldr	r3, [r3, #0xc]
   2700c: e0823003     	add	r3, r2, r3
   27010: e1a00003     	mov	r0, r3
   27014: e3a01000     	mov	r1, #0
   27018: e51b3100     	ldr	r3, [r11, #-0x100]
   2701c: e1c321d8     	ldrd	r2, r3, [r3, #24]
   27020: e0900002     	adds	r0, r0, r2
   27024: e0a11003     	adc	r1, r1, r3
   27028: e3e0200b     	mvn	r2, #11
   2702c: e3e03000     	mvn	r3, #0
   27030: e0922000     	adds	r2, r2, r0
   27034: e0a33001     	adc	r3, r3, r1
   27038: e51f104c     	ldr	r1, [pc, #-0x4c]        @ 0x26ff4 <calculate_header_and_footer+0x3fb8>
   2703c: e24b000c     	sub	r0, r11, #12
   27040: e18020f1     	strd	r2, r3, [r0, r1]
   27044: e51f2058     	ldr	r2, [pc, #-0x58]        @ 0x26ff4 <calculate_header_and_footer+0x3fb8>
   27048: e3a03004     	mov	r3, #4
   2704c: e24b100c     	sub	r1, r11, #12
   27050: e0812002     	add	r2, r1, r2
   27054: e0823003     	add	r3, r2, r3
   27058: e5934000     	ldr	r4, [r3]
   2705c: e1a02c24     	lsr	r2, r4, #24
   27060: e20438ff     	and	r3, r4, #16711680
   27064: e1a03423     	lsr	r3, r3, #8
   27068: e1822003     	orr	r2, r2, r3
   2706c: e2043cff     	and	r3, r4, #65280
   27070: e1a03403     	lsl	r3, r3, #8
   27074: e1822003     	orr	r2, r2, r3
   27078: e1a03c04     	lsl	r3, r4, #24
   2707c: e1822003     	orr	r2, r2, r3
   27080: e51f3090     	ldr	r3, [pc, #-0x90]        @ 0x26ff8 <calculate_header_and_footer+0x3fbc>
   27084: e24b000c     	sub	r0, r11, #12
   27088: e7802003     	str	r2, [r0, r3]
   2708c: e51f30a0     	ldr	r3, [pc, #-0xa0]        @ 0x26ff4 <calculate_header_and_footer+0x3fb8>
   27090: e24b100c     	sub	r1, r11, #12
   27094: e7914003     	ldr	r4, [r1, r3]
   27098: e1a02c24     	lsr	r2, r4, #24
   2709c: e20438ff     	and	r3, r4, #16711680
   270a0: e1a03423     	lsr	r3, r3, #8
   270a4: e1822003     	orr	r2, r2, r3
   270a8: e2043cff     	and	r3, r4, #65280
   270ac: e1a03403     	lsl	r3, r3, #8
   270b0: e1822003     	orr	r2, r2, r3
   270b4: e1a03c04     	lsl	r3, r4, #24
   270b8: e1822003     	orr	r2, r2, r3
   270bc: e51f10cc     	ldr	r1, [pc, #-0xcc]        @ 0x26ff8 <calculate_header_and_footer+0x3fbc>
   270c0: e3a03004     	mov	r3, #4
   270c4: e24b000c     	sub	r0, r11, #12
   270c8: e0801001     	add	r1, r0, r1
   270cc: e0813003     	add	r3, r1, r3
   270d0: e5832000     	str	r2, [r3]
   270d4: e51f30e4     	ldr	r3, [pc, #-0xe4]        @ 0x26ff8 <calculate_header_and_footer+0x3fbc>
   270d8: e24b100c     	sub	r1, r11, #12
   270dc: e18320d1     	ldrd	r2, r3, [r3, r1]
   270e0: e51b1114     	ldr	r1, [r11, #-0x114]
   270e4: e20200ff     	and	r0, r2, #255
   270e8: e3a0c000     	mov	r12, #0
   270ec: e18c0000     	orr	r0, r12, r0
   270f0: e5c10004     	strb	r0, [r1, #0x4]
   270f4: e1a00422     	lsr	r0, r2, #8
   270f8: e20000ff     	and	r0, r0, #255
   270fc: e3a0c000     	mov	r12, #0
   27100: e18c0000     	orr	r0, r12, r0
   27104: e5c10005     	strb	r0, [r1, #0x5]
   27108: e1a00822     	lsr	r0, r2, #16
   2710c: e20000ff     	and	r0, r0, #255
   27110: e3a0c000     	mov	r12, #0
   27114: e18c0000     	orr	r0, r12, r0
   27118: e5c10006     	strb	r0, [r1, #0x6]
   2711c: e1a00c22     	lsr	r0, r2, #24
   27120: e3a0c000     	mov	r12, #0
   27124: e18c0000     	orr	r0, r12, r0
   27128: e5c10007     	strb	r0, [r1, #0x7]
   2712c: e20300ff     	and	r0, r3, #255
   27130: e3a0c000     	mov	r12, #0
   27134: e18c0000     	orr	r0, r12, r0
   27138: e5c10008     	strb	r0, [r1, #0x8]
   2713c: e1a00423     	lsr	r0, r3, #8
   27140: e20000ff     	and	r0, r0, #255
   27144: e3a0c000     	mov	r12, #0
   27148: e18c0000     	orr	r0, r12, r0
   2714c: e5c10009     	strb	r0, [r1, #0x9]
   27150: e1a00823     	lsr	r0, r3, #16
   27154: e20000ff     	and	r0, r0, #255
   27158: e3a0c000     	mov	r12, #0
   2715c: e18c0000     	orr	r0, r12, r0
   27160: e5c1000a     	strb	r0, [r1, #0xa]
   27164: e1a03c23     	lsr	r3, r3, #24
   27168: e3a02000     	mov	r2, #0
   2716c: e1823003     	orr	r3, r2, r3
   27170: e5c1300b     	strb	r3, [r1, #0xb]
   27174: e3a03000     	mov	r3, #0
   27178: e1a00003     	mov	r0, r3
   2717c: e24bd008     	sub	sp, r11, #8
   27180: e8bd8810     	pop	{r4, r11, pc}

