000164c0 <LT_ACDecodeBit_Init>:
   164c0: e52db004     	str	r11, [sp, #-0x4]!
   164c4: e28db000     	add	r11, sp, #0
   164c8: e24dd014     	sub	sp, sp, #20
   164cc: e50b0008     	str	r0, [r11, #-0x8]
   164d0: e50b100c     	str	r1, [r11, #-0xc]
   164d4: e50b2010     	str	r2, [r11, #-0x10]
   164d8: e51b3008     	ldr	r3, [r11, #-0x8]
   164dc: e3a02000     	mov	r2, #0
   164e0: e5832000     	str	r2, [r3]
   164e4: e51b3008     	ldr	r3, [r11, #-0x8]
   164e8: e59f209c     	ldr	r2, [pc, #0x9c]         @ 0x1658c <LT_ACDecodeBit_Init+0xcc>
   164ec: e5832008     	str	r2, [r3, #0x8]
   164f0: e51b3008     	ldr	r3, [r11, #-0x8]
   164f4: e3a02000     	mov	r2, #0
   164f8: e5832004     	str	r2, [r3, #0x4]
   164fc: e51b3008     	ldr	r3, [r11, #-0x8]
   16500: e3a02001     	mov	r2, #1
   16504: e583200c     	str	r2, [r3, #0xc]
   16508: ea000018     	b	0x16570 <LT_ACDecodeBit_Init+0xb0> @ imm = #0x60
   1650c: e51b3008     	ldr	r3, [r11, #-0x8]
   16510: e5933004     	ldr	r3, [r3, #0x4]
   16514: e1a02083     	lsl	r2, r3, #1
   16518: e51b3008     	ldr	r3, [r11, #-0x8]
   1651c: e5832004     	str	r2, [r3, #0x4]
   16520: e51b3008     	ldr	r3, [r11, #-0x8]
   16524: e593200c     	ldr	r2, [r3, #0xc]
   16528: e51b3010     	ldr	r3, [r11, #-0x10]
   1652c: e1520003     	cmp	r2, r3
   16530: aa000009     	bge	0x1655c <LT_ACDecodeBit_Init+0x9c> @ imm = #0x24
   16534: e51b3008     	ldr	r3, [r11, #-0x8]
   16538: e5932004     	ldr	r2, [r3, #0x4]
   1653c: e51b3008     	ldr	r3, [r11, #-0x8]
   16540: e593300c     	ldr	r3, [r3, #0xc]
   16544: e51b100c     	ldr	r1, [r11, #-0xc]
   16548: e0813003     	add	r3, r1, r3
   1654c: e5d33000     	ldrb	r3, [r3]
   16550: e1822003     	orr	r2, r2, r3
   16554: e51b3008     	ldr	r3, [r11, #-0x8]
   16558: e5832004     	str	r2, [r3, #0x4]
   1655c: e51b3008     	ldr	r3, [r11, #-0x8]
   16560: e593300c     	ldr	r3, [r3, #0xc]
   16564: e2832001     	add	r2, r3, #1
   16568: e51b3008     	ldr	r3, [r11, #-0x8]
   1656c: e583200c     	str	r2, [r3, #0xc]
   16570: e51b3008     	ldr	r3, [r11, #-0x8]
   16574: e593300c     	ldr	r3, [r3, #0xc]
   16578: e353000c     	cmp	r3, #12
   1657c: daffffe2     	ble	0x1650c <LT_ACDecodeBit_Init+0x4c> @ imm = #-0x78
   16580: e28bd000     	add	sp, r11, #0
   16584: e8bd0800     	ldm	sp!, {r11}
   16588: e12fff1e     	bx	lr
   1658c: ff 0f 00 00  	.word	0x00000fff

