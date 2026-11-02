000166ec <LT_ACDecodeBit_Flush>:
   166ec: e52db004     	str	r11, [sp, #-0x4]!
   166f0: e28db000     	add	r11, sp, #0
   166f4: e24dd014     	sub	sp, sp, #20
   166f8: e50b0008     	str	r0, [r11, #-0x8]
   166fc: e50b100c     	str	r1, [r11, #-0xc]
   16700: e50b2010     	str	r2, [r11, #-0x10]
   16704: e50b3014     	str	r3, [r11, #-0x14]
   16708: e51b3008     	ldr	r3, [r11, #-0x8]
   1670c: e3a02001     	mov	r2, #1
   16710: e5832000     	str	r2, [r3]
   16714: e51b3008     	ldr	r3, [r11, #-0x8]
   16718: e593200c     	ldr	r2, [r3, #0xc]
   1671c: e59b3004     	ldr	r3, [r11, #0x4]
   16720: e2433007     	sub	r3, r3, #7
   16724: e1520003     	cmp	r2, r3
   16728: aa000003     	bge	0x1673c <LT_ACDecodeBit_Flush+0x50> @ imm = #0xc
   1672c: e51b300c     	ldr	r3, [r11, #-0xc]
   16730: e3a02000     	mov	r2, #0
   16734: e5c32000     	strb	r2, [r3]
   16738: ea00001b     	b	0x167ac <LT_ACDecodeBit_Flush+0xc0> @ imm = #0x6c
   1673c: e51b300c     	ldr	r3, [r11, #-0xc]
   16740: e3a02001     	mov	r2, #1
   16744: e5c32000     	strb	r2, [r3]
   16748: ea00000e     	b	0x16788 <LT_ACDecodeBit_Flush+0x9c> @ imm = #0x38
   1674c: e51b3008     	ldr	r3, [r11, #-0x8]
   16750: e593300c     	ldr	r3, [r3, #0xc]
   16754: e51b2014     	ldr	r2, [r11, #-0x14]
   16758: e0823003     	add	r3, r2, r3
   1675c: e5d33000     	ldrb	r3, [r3]
   16760: e3530000     	cmp	r3, #0
   16764: 0a000002     	beq	0x16774 <LT_ACDecodeBit_Flush+0x88> @ imm = #0x8
   16768: e51b300c     	ldr	r3, [r11, #-0xc]
   1676c: e3a02001     	mov	r2, #1
   16770: e5c32000     	strb	r2, [r3]
   16774: e51b3008     	ldr	r3, [r11, #-0x8]
   16778: e593300c     	ldr	r3, [r3, #0xc]
   1677c: e2832001     	add	r2, r3, #1
   16780: e51b3008     	ldr	r3, [r11, #-0x8]
   16784: e583200c     	str	r2, [r3, #0xc]
   16788: e51b3008     	ldr	r3, [r11, #-0x8]
   1678c: e593200c     	ldr	r2, [r3, #0xc]
   16790: e59b3004     	ldr	r3, [r11, #0x4]
   16794: e1520003     	cmp	r2, r3
   16798: aa000003     	bge	0x167ac <LT_ACDecodeBit_Flush+0xc0> @ imm = #0xc
   1679c: e51b300c     	ldr	r3, [r11, #-0xc]
   167a0: e5d33000     	ldrb	r3, [r3]
   167a4: e3530001     	cmp	r3, #1
   167a8: 0affffe7     	beq	0x1674c <LT_ACDecodeBit_Flush+0x60> @ imm = #-0x64
   167ac: e28bd000     	add	sp, r11, #0
   167b0: e8bd0800     	ldm	sp!, {r11}
   167b4: e12fff1e     	bx	lr

