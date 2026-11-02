00016590 <LT_ACDecodeBit_Decode>:
   16590: e52db004     	str	r11, [sp, #-0x4]!
   16594: e28db000     	add	r11, sp, #0
   16598: e24dd01c     	sub	sp, sp, #28
   1659c: e50b0010     	str	r0, [r11, #-0x10]
   165a0: e50b1014     	str	r1, [r11, #-0x14]
   165a4: e50b2018     	str	r2, [r11, #-0x18]
   165a8: e50b301c     	str	r3, [r11, #-0x1c]
   165ac: e51b3010     	ldr	r3, [r11, #-0x10]
   165b0: e5933008     	ldr	r3, [r3, #0x8]
   165b4: e1a02423     	lsr	r2, r3, #8
   165b8: e51b3010     	ldr	r3, [r11, #-0x10]
   165bc: e5933008     	ldr	r3, [r3, #0x8]
   165c0: e1a033a3     	lsr	r3, r3, #7
   165c4: e2033001     	and	r3, r3, #1
   165c8: e1823003     	orr	r3, r2, r3
   165cc: e51b2018     	ldr	r2, [r11, #-0x18]
   165d0: e0030392     	mul	r3, r2, r3
   165d4: e50b300c     	str	r3, [r11, #-0xc]
   165d8: e51b3010     	ldr	r3, [r11, #-0x10]
   165dc: e5932008     	ldr	r2, [r3, #0x8]
   165e0: e51b300c     	ldr	r3, [r11, #-0xc]
   165e4: e0633002     	rsb	r3, r3, r2
   165e8: e50b3008     	str	r3, [r11, #-0x8]
   165ec: e51b3010     	ldr	r3, [r11, #-0x10]
   165f0: e5932004     	ldr	r2, [r3, #0x4]
   165f4: e51b3008     	ldr	r3, [r11, #-0x8]
   165f8: e1520003     	cmp	r2, r3
   165fc: 3a00000c     	blo	0x16634 <LT_ACDecodeBit_Decode+0xa4> @ imm = #0x30
   16600: e51b3014     	ldr	r3, [r11, #-0x14]
   16604: e3a02000     	mov	r2, #0
   16608: e5c32000     	strb	r2, [r3]
   1660c: e51b3010     	ldr	r3, [r11, #-0x10]
   16610: e5932004     	ldr	r2, [r3, #0x4]
   16614: e51b3008     	ldr	r3, [r11, #-0x8]
   16618: e0632002     	rsb	r2, r3, r2
   1661c: e51b3010     	ldr	r3, [r11, #-0x10]
   16620: e5832004     	str	r2, [r3, #0x4]
   16624: e51b3010     	ldr	r3, [r11, #-0x10]
   16628: e51b200c     	ldr	r2, [r11, #-0xc]
   1662c: e5832008     	str	r2, [r3, #0x8]
   16630: ea000024     	b	0x166c8 <LT_ACDecodeBit_Decode+0x138> @ imm = #0x90
   16634: e51b3014     	ldr	r3, [r11, #-0x14]
   16638: e3a02001     	mov	r2, #1
   1663c: e5c32000     	strb	r2, [r3]
   16640: e51b3010     	ldr	r3, [r11, #-0x10]
   16644: e51b2008     	ldr	r2, [r11, #-0x8]
   16648: e5832008     	str	r2, [r3, #0x8]
   1664c: ea00001d     	b	0x166c8 <LT_ACDecodeBit_Decode+0x138> @ imm = #0x74
   16650: e51b3010     	ldr	r3, [r11, #-0x10]
   16654: e5933008     	ldr	r3, [r3, #0x8]
   16658: e1a02083     	lsl	r2, r3, #1
   1665c: e51b3010     	ldr	r3, [r11, #-0x10]
   16660: e5832008     	str	r2, [r3, #0x8]
   16664: e51b3010     	ldr	r3, [r11, #-0x10]
   16668: e5933004     	ldr	r3, [r3, #0x4]
   1666c: e1a02083     	lsl	r2, r3, #1
   16670: e51b3010     	ldr	r3, [r11, #-0x10]
   16674: e5832004     	str	r2, [r3, #0x4]
   16678: e51b3010     	ldr	r3, [r11, #-0x10]
   1667c: e593200c     	ldr	r2, [r3, #0xc]
   16680: e59b3004     	ldr	r3, [r11, #0x4]
   16684: e1520003     	cmp	r2, r3
   16688: aa000009     	bge	0x166b4 <LT_ACDecodeBit_Decode+0x124> @ imm = #0x24
   1668c: e51b3010     	ldr	r3, [r11, #-0x10]
   16690: e5932004     	ldr	r2, [r3, #0x4]
   16694: e51b3010     	ldr	r3, [r11, #-0x10]
   16698: e593300c     	ldr	r3, [r3, #0xc]
   1669c: e51b101c     	ldr	r1, [r11, #-0x1c]
   166a0: e0813003     	add	r3, r1, r3
   166a4: e5d33000     	ldrb	r3, [r3]
   166a8: e1822003     	orr	r2, r2, r3
   166ac: e51b3010     	ldr	r3, [r11, #-0x10]
   166b0: e5832004     	str	r2, [r3, #0x4]
   166b4: e51b3010     	ldr	r3, [r11, #-0x10]
   166b8: e593300c     	ldr	r3, [r3, #0xc]
   166bc: e2832001     	add	r2, r3, #1
   166c0: e51b3010     	ldr	r3, [r11, #-0x10]
   166c4: e583200c     	str	r2, [r3, #0xc]
   166c8: e51b3010     	ldr	r3, [r11, #-0x10]
   166cc: e5932008     	ldr	r2, [r3, #0x8]
   166d0: e59f3010     	ldr	r3, [pc, #0x10]         @ 0x166e8 <LT_ACDecodeBit_Decode+0x158>
   166d4: e1520003     	cmp	r2, r3
   166d8: 9affffdc     	bls	0x16650 <LT_ACDecodeBit_Decode+0xc0> @ imm = #-0x90
   166dc: e28bd000     	add	sp, r11, #0
   166e0: e8bd0800     	ldm	sp!, {r11}
   166e4: e12fff1e     	bx	lr
   166e8: ff 07 00 00  	.word	0x000007ff

