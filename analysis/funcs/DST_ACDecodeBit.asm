000152bc <DST_ACDecodeBit>:
   152bc: e52db004     	str	r11, [sp, #-0x4]!
   152c0: e28db000     	add	r11, sp, #0
   152c4: e24dd01c     	sub	sp, sp, #28
   152c8: e50b0010     	str	r0, [r11, #-0x10]
   152cc: e50b1014     	str	r1, [r11, #-0x14]
   152d0: e50b2018     	str	r2, [r11, #-0x18]
   152d4: e50b301c     	str	r3, [r11, #-0x1c]
   152d8: e51b3010     	ldr	r3, [r11, #-0x10]
   152dc: e5933000     	ldr	r3, [r3]
   152e0: e3530001     	cmp	r3, #1
   152e4: 1a000029     	bne	0x15390 <DST_ACDecodeBit+0xd4> @ imm = #0xa4
   152e8: e51b3010     	ldr	r3, [r11, #-0x10]
   152ec: e3a02000     	mov	r2, #0
   152f0: e5832000     	str	r2, [r3]
   152f4: e51b3010     	ldr	r3, [r11, #-0x10]
   152f8: e59f2280     	ldr	r2, [pc, #0x280]        @ 0x15580 <DST_ACDecodeBit+0x2c4>
   152fc: e5832008     	str	r2, [r3, #0x8]
   15300: e51b3010     	ldr	r3, [r11, #-0x10]
   15304: e3a02000     	mov	r2, #0
   15308: e5832004     	str	r2, [r3, #0x4]
   1530c: e51b3010     	ldr	r3, [r11, #-0x10]
   15310: e3a02001     	mov	r2, #1
   15314: e583200c     	str	r2, [r3, #0xc]
   15318: ea000018     	b	0x15380 <DST_ACDecodeBit+0xc4> @ imm = #0x60
   1531c: e51b3010     	ldr	r3, [r11, #-0x10]
   15320: e5933004     	ldr	r3, [r3, #0x4]
   15324: e1a02083     	lsl	r2, r3, #1
   15328: e51b3010     	ldr	r3, [r11, #-0x10]
   1532c: e5832004     	str	r2, [r3, #0x4]
   15330: e51b3010     	ldr	r3, [r11, #-0x10]
   15334: e593200c     	ldr	r2, [r3, #0xc]
   15338: e59b3004     	ldr	r3, [r11, #0x4]
   1533c: e1520003     	cmp	r2, r3
   15340: aa000009     	bge	0x1536c <DST_ACDecodeBit+0xb0> @ imm = #0x24
   15344: e51b3010     	ldr	r3, [r11, #-0x10]
   15348: e5932004     	ldr	r2, [r3, #0x4]
   1534c: e51b3010     	ldr	r3, [r11, #-0x10]
   15350: e593300c     	ldr	r3, [r3, #0xc]
   15354: e51b101c     	ldr	r1, [r11, #-0x1c]
   15358: e0813003     	add	r3, r1, r3
   1535c: e5d33000     	ldrb	r3, [r3]
   15360: e1822003     	orr	r2, r2, r3
   15364: e51b3010     	ldr	r3, [r11, #-0x10]
   15368: e5832004     	str	r2, [r3, #0x4]
   1536c: e51b3010     	ldr	r3, [r11, #-0x10]
   15370: e593300c     	ldr	r3, [r3, #0xc]
   15374: e2832001     	add	r2, r3, #1
   15378: e51b3010     	ldr	r3, [r11, #-0x10]
   1537c: e583200c     	str	r2, [r3, #0xc]
   15380: e51b3010     	ldr	r3, [r11, #-0x10]
   15384: e593300c     	ldr	r3, [r3, #0xc]
   15388: e353000c     	cmp	r3, #12
   1538c: daffffe2     	ble	0x1531c <DST_ACDecodeBit+0x60> @ imm = #-0x78
   15390: e59b3008     	ldr	r3, [r11, #0x8]
   15394: e3530000     	cmp	r3, #0
   15398: 1a00004c     	bne	0x154d0 <DST_ACDecodeBit+0x214> @ imm = #0x130
   1539c: e51b3010     	ldr	r3, [r11, #-0x10]
   153a0: e5933008     	ldr	r3, [r3, #0x8]
   153a4: e1a02423     	lsr	r2, r3, #8
   153a8: e51b3010     	ldr	r3, [r11, #-0x10]
   153ac: e5933008     	ldr	r3, [r3, #0x8]
   153b0: e1a033a3     	lsr	r3, r3, #7
   153b4: e2033001     	and	r3, r3, #1
   153b8: e1823003     	orr	r3, r2, r3
   153bc: e51b2018     	ldr	r2, [r11, #-0x18]
   153c0: e0030392     	mul	r3, r2, r3
   153c4: e50b300c     	str	r3, [r11, #-0xc]
   153c8: e51b3010     	ldr	r3, [r11, #-0x10]
   153cc: e5932008     	ldr	r2, [r3, #0x8]
   153d0: e51b300c     	ldr	r3, [r11, #-0xc]
   153d4: e0633002     	rsb	r3, r3, r2
   153d8: e50b3008     	str	r3, [r11, #-0x8]
   153dc: e51b3010     	ldr	r3, [r11, #-0x10]
   153e0: e5932004     	ldr	r2, [r3, #0x4]
   153e4: e51b3008     	ldr	r3, [r11, #-0x8]
   153e8: e1520003     	cmp	r2, r3
   153ec: 3a00000c     	blo	0x15424 <DST_ACDecodeBit+0x168> @ imm = #0x30
   153f0: e51b3014     	ldr	r3, [r11, #-0x14]
   153f4: e3a02000     	mov	r2, #0
   153f8: e5c32000     	strb	r2, [r3]
   153fc: e51b3010     	ldr	r3, [r11, #-0x10]
   15400: e5932004     	ldr	r2, [r3, #0x4]
   15404: e51b3008     	ldr	r3, [r11, #-0x8]
   15408: e0632002     	rsb	r2, r3, r2
   1540c: e51b3010     	ldr	r3, [r11, #-0x10]
   15410: e5832004     	str	r2, [r3, #0x4]
   15414: e51b3010     	ldr	r3, [r11, #-0x10]
   15418: e51b200c     	ldr	r2, [r11, #-0xc]
   1541c: e5832008     	str	r2, [r3, #0x8]
   15420: ea000024     	b	0x154b8 <DST_ACDecodeBit+0x1fc> @ imm = #0x90
   15424: e51b3014     	ldr	r3, [r11, #-0x14]
   15428: e3a02001     	mov	r2, #1
   1542c: e5c32000     	strb	r2, [r3]
   15430: e51b3010     	ldr	r3, [r11, #-0x10]
   15434: e51b2008     	ldr	r2, [r11, #-0x8]
   15438: e5832008     	str	r2, [r3, #0x8]
   1543c: ea00001d     	b	0x154b8 <DST_ACDecodeBit+0x1fc> @ imm = #0x74
   15440: e51b3010     	ldr	r3, [r11, #-0x10]
   15444: e5933008     	ldr	r3, [r3, #0x8]
   15448: e1a02083     	lsl	r2, r3, #1
   1544c: e51b3010     	ldr	r3, [r11, #-0x10]
   15450: e5832008     	str	r2, [r3, #0x8]
   15454: e51b3010     	ldr	r3, [r11, #-0x10]
   15458: e5933004     	ldr	r3, [r3, #0x4]
   1545c: e1a02083     	lsl	r2, r3, #1
   15460: e51b3010     	ldr	r3, [r11, #-0x10]
   15464: e5832004     	str	r2, [r3, #0x4]
   15468: e51b3010     	ldr	r3, [r11, #-0x10]
   1546c: e593200c     	ldr	r2, [r3, #0xc]
   15470: e59b3004     	ldr	r3, [r11, #0x4]
   15474: e1520003     	cmp	r2, r3
   15478: aa000009     	bge	0x154a4 <DST_ACDecodeBit+0x1e8> @ imm = #0x24
   1547c: e51b3010     	ldr	r3, [r11, #-0x10]
   15480: e5932004     	ldr	r2, [r3, #0x4]
   15484: e51b3010     	ldr	r3, [r11, #-0x10]
   15488: e593300c     	ldr	r3, [r3, #0xc]
   1548c: e51b101c     	ldr	r1, [r11, #-0x1c]
   15490: e0813003     	add	r3, r1, r3
   15494: e5d33000     	ldrb	r3, [r3]
   15498: e1822003     	orr	r2, r2, r3
   1549c: e51b3010     	ldr	r3, [r11, #-0x10]
   154a0: e5832004     	str	r2, [r3, #0x4]
   154a4: e51b3010     	ldr	r3, [r11, #-0x10]
   154a8: e593300c     	ldr	r3, [r3, #0xc]
   154ac: e2832001     	add	r2, r3, #1
   154b0: e51b3010     	ldr	r3, [r11, #-0x10]
   154b4: e583200c     	str	r2, [r3, #0xc]
   154b8: e51b3010     	ldr	r3, [r11, #-0x10]
   154bc: e5932008     	ldr	r2, [r3, #0x8]
   154c0: e59f30bc     	ldr	r3, [pc, #0xbc]         @ 0x15584 <DST_ACDecodeBit+0x2c8>
   154c4: e1520003     	cmp	r2, r3
   154c8: 9affffdc     	bls	0x15440 <DST_ACDecodeBit+0x184> @ imm = #-0x90
   154cc: ea000028     	b	0x15574 <DST_ACDecodeBit+0x2b8> @ imm = #0xa0
   154d0: e51b3010     	ldr	r3, [r11, #-0x10]
   154d4: e3a02001     	mov	r2, #1
   154d8: e5832000     	str	r2, [r3]
   154dc: e51b3010     	ldr	r3, [r11, #-0x10]
   154e0: e593200c     	ldr	r2, [r3, #0xc]
   154e4: e59b3004     	ldr	r3, [r11, #0x4]
   154e8: e2433007     	sub	r3, r3, #7
   154ec: e1520003     	cmp	r2, r3
   154f0: aa000003     	bge	0x15504 <DST_ACDecodeBit+0x248> @ imm = #0xc
   154f4: e51b3014     	ldr	r3, [r11, #-0x14]
   154f8: e3a02000     	mov	r2, #0
   154fc: e5c32000     	strb	r2, [r3]
   15500: ea00001b     	b	0x15574 <DST_ACDecodeBit+0x2b8> @ imm = #0x6c
   15504: e51b3014     	ldr	r3, [r11, #-0x14]
   15508: e3a02001     	mov	r2, #1
   1550c: e5c32000     	strb	r2, [r3]
   15510: ea00000e     	b	0x15550 <DST_ACDecodeBit+0x294> @ imm = #0x38
   15514: e51b3010     	ldr	r3, [r11, #-0x10]
   15518: e593300c     	ldr	r3, [r3, #0xc]
   1551c: e51b201c     	ldr	r2, [r11, #-0x1c]
   15520: e0823003     	add	r3, r2, r3
   15524: e5d33000     	ldrb	r3, [r3]
   15528: e3530000     	cmp	r3, #0
   1552c: 0a000002     	beq	0x1553c <DST_ACDecodeBit+0x280> @ imm = #0x8
   15530: e51b3014     	ldr	r3, [r11, #-0x14]
   15534: e3a02001     	mov	r2, #1
   15538: e5c32000     	strb	r2, [r3]
   1553c: e51b3010     	ldr	r3, [r11, #-0x10]
   15540: e593300c     	ldr	r3, [r3, #0xc]
   15544: e2832001     	add	r2, r3, #1
   15548: e51b3010     	ldr	r3, [r11, #-0x10]
   1554c: e583200c     	str	r2, [r3, #0xc]
   15550: e51b3010     	ldr	r3, [r11, #-0x10]
   15554: e593200c     	ldr	r2, [r3, #0xc]
   15558: e59b3004     	ldr	r3, [r11, #0x4]
   1555c: e1520003     	cmp	r2, r3
   15560: aa000003     	bge	0x15574 <DST_ACDecodeBit+0x2b8> @ imm = #0xc
   15564: e51b3014     	ldr	r3, [r11, #-0x14]
   15568: e5d33000     	ldrb	r3, [r3]
   1556c: e3530001     	cmp	r3, #1
   15570: 0affffe7     	beq	0x15514 <DST_ACDecodeBit+0x258> @ imm = #-0x64
   15574: e28bd000     	add	sp, r11, #0
   15578: e8bd0800     	ldm	sp!, {r11}
   1557c: e12fff1e     	bx	lr
   15580: ff 0f 00 00  	.word	0x00000fff
   15584: ff 07 00 00  	.word	0x000007ff

