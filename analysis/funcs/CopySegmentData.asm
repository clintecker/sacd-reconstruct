000181b8 <CopySegmentData>:
   181b8: e52db004     	str	r11, [sp, #-0x4]!
   181bc: e28db000     	add	r11, sp, #0
   181c0: e24dd024     	sub	sp, sp, #36
   181c4: e50b0020     	str	r0, [r11, #-0x20]
   181c8: e51b3020     	ldr	r3, [r11, #-0x20]
   181cc: e2833bdd     	add	r3, r3, #226304
   181d0: e2833f45     	add	r3, r3, #276
   181d4: e50b3014     	str	r3, [r11, #-0x14]
   181d8: e51b3020     	ldr	r3, [r11, #-0x20]
   181dc: e2833f5e     	add	r3, r3, #376
   181e0: e50b3010     	str	r3, [r11, #-0x10]
   181e4: e51b3020     	ldr	r3, [r11, #-0x20]
   181e8: e59310b4     	ldr	r1, [r3, #0xb4]
   181ec: e51b2020     	ldr	r2, [r11, #-0x20]
   181f0: e59f3210     	ldr	r3, [pc, #0x210]        @ 0x18408 <CopySegmentData+0x250>
   181f4: e7821003     	str	r1, [r2, r3]
   181f8: e51b2020     	ldr	r2, [r11, #-0x20]
   181fc: e59f3208     	ldr	r3, [pc, #0x208]        @ 0x1840c <CopySegmentData+0x254>
   18200: e3a01001     	mov	r1, #1
   18204: e7821003     	str	r1, [r2, r3]
   18208: e3a03000     	mov	r3, #0
   1820c: e50b301c     	str	r3, [r11, #-0x1c]
   18210: ea000072     	b	0x183e0 <CopySegmentData+0x228> @ imm = #0x1c8
   18214: e51b301c     	ldr	r3, [r11, #-0x1c]
   18218: e1a03103     	lsl	r3, r3, #2
   1821c: e51b2014     	ldr	r2, [r11, #-0x14]
   18220: e0823003     	add	r3, r2, r3
   18224: e51b201c     	ldr	r2, [r11, #-0x1c]
   18228: e1a02102     	lsl	r2, r2, #2
   1822c: e51b1010     	ldr	r1, [r11, #-0x10]
   18230: e0812002     	add	r2, r1, r2
   18234: e5922000     	ldr	r2, [r2]
   18238: e5832000     	str	r2, [r3]
   1823c: e51b301c     	ldr	r3, [r11, #-0x1c]
   18240: e1a03103     	lsl	r3, r3, #2
   18244: e51b2014     	ldr	r2, [r11, #-0x14]
   18248: e0823003     	add	r3, r2, r3
   1824c: e5933000     	ldr	r3, [r3]
   18250: e3530008     	cmp	r3, #8
   18254: da000001     	ble	0x18260 <CopySegmentData+0xa8> @ imm = #0x4
   18258: e3a03002     	mov	r3, #2
   1825c: ea000065     	b	0x183f8 <CopySegmentData+0x240> @ imm = #0x194
   18260: e51b301c     	ldr	r3, [r11, #-0x1c]
   18264: e1a03103     	lsl	r3, r3, #2
   18268: e51b2014     	ldr	r2, [r11, #-0x14]
   1826c: e0823003     	add	r3, r2, r3
   18270: e5932000     	ldr	r2, [r3]
   18274: e51b3014     	ldr	r3, [r11, #-0x14]
   18278: e5933000     	ldr	r3, [r3]
   1827c: e1520003     	cmp	r2, r3
   18280: 0a000003     	beq	0x18294 <CopySegmentData+0xdc> @ imm = #0xc
   18284: e51b2020     	ldr	r2, [r11, #-0x20]
   18288: e59f317c     	ldr	r3, [pc, #0x17c]        @ 0x1840c <CopySegmentData+0x254>
   1828c: e3a01000     	mov	r1, #0
   18290: e7821003     	str	r1, [r2, r3]
   18294: e3a03000     	mov	r3, #0
   18298: e50b3018     	str	r3, [r11, #-0x18]
   1829c: ea000044     	b	0x183b4 <CopySegmentData+0x1fc> @ imm = #0x110
   182a0: e51b3020     	ldr	r3, [r11, #-0x20]
   182a4: e2833bdd     	add	r3, r3, #226304
   182a8: e2833054     	add	r3, r3, #84
   182ac: e1a02003     	mov	r2, r3
   182b0: e51b301c     	ldr	r3, [r11, #-0x1c]
   182b4: e1a03283     	lsl	r3, r3, #5
   182b8: e0823003     	add	r3, r2, r3
   182bc: e50b300c     	str	r3, [r11, #-0xc]
   182c0: e51b3020     	ldr	r3, [r11, #-0x20]
   182c4: e28330b8     	add	r3, r3, #184
   182c8: e1a02003     	mov	r2, r3
   182cc: e51b301c     	ldr	r3, [r11, #-0x1c]
   182d0: e1a03283     	lsl	r3, r3, #5
   182d4: e0823003     	add	r3, r2, r3
   182d8: e50b3008     	str	r3, [r11, #-0x8]
   182dc: e51b3018     	ldr	r3, [r11, #-0x18]
   182e0: e1a03103     	lsl	r3, r3, #2
   182e4: e51b200c     	ldr	r2, [r11, #-0xc]
   182e8: e0823003     	add	r3, r2, r3
   182ec: e51b2018     	ldr	r2, [r11, #-0x18]
   182f0: e1a02102     	lsl	r2, r2, #2
   182f4: e51b1008     	ldr	r1, [r11, #-0x8]
   182f8: e0812002     	add	r2, r1, r2
   182fc: e5922000     	ldr	r2, [r2]
   18300: e5832000     	str	r2, [r3]
   18304: e51b3018     	ldr	r3, [r11, #-0x18]
   18308: e1a03103     	lsl	r3, r3, #2
   1830c: e51b200c     	ldr	r2, [r11, #-0xc]
   18310: e0823003     	add	r3, r2, r3
   18314: e5933000     	ldr	r3, [r3]
   18318: e3530000     	cmp	r3, #0
   1831c: 0a00000d     	beq	0x18358 <CopySegmentData+0x1a0> @ imm = #0x34
   18320: e51b2020     	ldr	r2, [r11, #-0x20]
   18324: e59f30dc     	ldr	r3, [pc, #0xdc]         @ 0x18408 <CopySegmentData+0x250>
   18328: e7923003     	ldr	r3, [r2, r3]
   1832c: e1a03183     	lsl	r3, r3, #3
   18330: e51b2018     	ldr	r2, [r11, #-0x18]
   18334: e1a02102     	lsl	r2, r2, #2
   18338: e51b100c     	ldr	r1, [r11, #-0xc]
   1833c: e0812002     	add	r2, r1, r2
   18340: e5922000     	ldr	r2, [r2]
   18344: e0030392     	mul	r3, r2, r3
   18348: e353001f     	cmp	r3, #31
   1834c: ca000001     	bgt	0x18358 <CopySegmentData+0x1a0> @ imm = #0x4
   18350: e3a03004     	mov	r3, #4
   18354: ea000027     	b	0x183f8 <CopySegmentData+0x240> @ imm = #0x9c
   18358: e51b3018     	ldr	r3, [r11, #-0x18]
   1835c: e1a03103     	lsl	r3, r3, #2
   18360: e51b200c     	ldr	r2, [r11, #-0xc]
   18364: e0823003     	add	r3, r2, r3
   18368: e5932000     	ldr	r2, [r3]
   1836c: e51b3018     	ldr	r3, [r11, #-0x18]
   18370: e51b0020     	ldr	r0, [r11, #-0x20]
   18374: e2833cdd     	add	r3, r3, #56576
   18378: e2833014     	add	r3, r3, #20
   1837c: e3a01004     	mov	r1, #4
   18380: e1a03103     	lsl	r3, r3, #2
   18384: e0803003     	add	r3, r0, r3
   18388: e0833001     	add	r3, r3, r1
   1838c: e5933000     	ldr	r3, [r3]
   18390: e1520003     	cmp	r2, r3
   18394: 0a000003     	beq	0x183a8 <CopySegmentData+0x1f0> @ imm = #0xc
   18398: e51b2020     	ldr	r2, [r11, #-0x20]
   1839c: e59f3068     	ldr	r3, [pc, #0x68]         @ 0x1840c <CopySegmentData+0x254>
   183a0: e3a01000     	mov	r1, #0
   183a4: e7821003     	str	r1, [r2, r3]
   183a8: e51b3018     	ldr	r3, [r11, #-0x18]
   183ac: e2833001     	add	r3, r3, #1
   183b0: e50b3018     	str	r3, [r11, #-0x18]
   183b4: e51b301c     	ldr	r3, [r11, #-0x1c]
   183b8: e1a03103     	lsl	r3, r3, #2
   183bc: e51b2014     	ldr	r2, [r11, #-0x14]
   183c0: e0823003     	add	r3, r2, r3
   183c4: e5932000     	ldr	r2, [r3]
   183c8: e51b3018     	ldr	r3, [r11, #-0x18]
   183cc: e1520003     	cmp	r2, r3
   183d0: caffffb2     	bgt	0x182a0 <CopySegmentData+0xe8> @ imm = #-0x138
   183d4: e51b301c     	ldr	r3, [r11, #-0x1c]
   183d8: e2833001     	add	r3, r3, #1
   183dc: e50b301c     	str	r3, [r11, #-0x1c]
   183e0: e51b3020     	ldr	r3, [r11, #-0x20]
   183e4: e5932004     	ldr	r2, [r3, #0x4]
   183e8: e51b301c     	ldr	r3, [r11, #-0x1c]
   183ec: e1520003     	cmp	r2, r3
   183f0: caffff87     	bgt	0x18214 <CopySegmentData+0x5c> @ imm = #-0x1e4
   183f4: e3a03000     	mov	r3, #0
   183f8: e1a00003     	mov	r0, r3
   183fc: e28bd000     	add	sp, r11, #0
   18400: e8bd0800     	ldm	sp!, {r11}
   18404: e12fff1e     	bx	lr
   18408: 50 74 03 00  	.word	0x00037450
   1840c: fc e7 06 00  	.word	0x0006e7fc

