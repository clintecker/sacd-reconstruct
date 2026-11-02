00018544 <ReadTableMappingData>:
   18544: e92d4800     	push	{r11, lr}
   18548: e28db004     	add	r11, sp, #4
   1854c: e24dd020     	sub	sp, sp, #32
   18550: e50b0018     	str	r0, [r11, #-0x18]
   18554: e50b101c     	str	r1, [r11, #-0x1c]
   18558: e50b2020     	str	r2, [r11, #-0x20]
   1855c: e50b3024     	str	r3, [r11, #-0x24]
   18560: e3a03001     	mov	r3, #1
   18564: e50b3010     	str	r3, [r11, #-0x10]
   18568: e3a03001     	mov	r3, #1
   1856c: e50b300c     	str	r3, [r11, #-0xc]
   18570: e51b3024     	ldr	r3, [r11, #-0x24]
   18574: e3a02000     	mov	r2, #0
   18578: e58320dc     	str	r2, [r3, #0xdc]
   1857c: e51b0018     	ldr	r0, [r11, #-0x18]
   18580: e3a01001     	mov	r1, #1
   18584: e59b2008     	ldr	r2, [r11, #0x8]
   18588: eb000ca8     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x32a0
   1858c: e1a03000     	mov	r3, r0
   18590: e3530000     	cmp	r3, #0
   18594: 0a000001     	beq	0x185a0 <ReadTableMappingData+0x5c> @ imm = #0x4
   18598: e3a03001     	mov	r3, #1
   1859c: ea0000d7     	b	0x18900 <ReadTableMappingData+0x3bc> @ imm = #0x35c
   185a0: e59b3008     	ldr	r3, [r11, #0x8]
   185a4: e5933000     	ldr	r3, [r3]
   185a8: e3530001     	cmp	r3, #1
   185ac: 1a000070     	bne	0x18774 <ReadTableMappingData+0x230> @ imm = #0x1c0
   185b0: e3a03001     	mov	r3, #1
   185b4: e50b3008     	str	r3, [r11, #-0x8]
   185b8: ea000031     	b	0x18684 <ReadTableMappingData+0x140> @ imm = #0xc4
   185bc: e51b0010     	ldr	r0, [r11, #-0x10]
   185c0: ebfffd09     	bl	0x179ec <Log2RoundUp>   @ imm = #-0xbdc
   185c4: e1a03000     	mov	r3, r0
   185c8: e50b300c     	str	r3, [r11, #-0xc]
   185cc: e51b3024     	ldr	r3, [r11, #-0x24]
   185d0: e28330dc     	add	r3, r3, #220
   185d4: e1a02003     	mov	r2, r3
   185d8: e51b3008     	ldr	r3, [r11, #-0x8]
   185dc: e1a03103     	lsl	r3, r3, #2
   185e0: e0823003     	add	r3, r2, r3
   185e4: e51b0018     	ldr	r0, [r11, #-0x18]
   185e8: e51b100c     	ldr	r1, [r11, #-0xc]
   185ec: e1a02003     	mov	r2, r3
   185f0: eb000c8e     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x3238
   185f4: e1a03000     	mov	r3, r0
   185f8: e3530000     	cmp	r3, #0
   185fc: 0a000001     	beq	0x18608 <ReadTableMappingData+0xc4> @ imm = #0x4
   18600: e3a03001     	mov	r3, #1
   18604: ea0000bd     	b	0x18900 <ReadTableMappingData+0x3bc> @ imm = #0x2f4
   18608: e51b3008     	ldr	r3, [r11, #-0x8]
   1860c: e51b1024     	ldr	r1, [r11, #-0x24]
   18610: e2832036     	add	r2, r3, #54
   18614: e3a03004     	mov	r3, #4
   18618: e1a02102     	lsl	r2, r2, #2
   1861c: e0812002     	add	r2, r1, r2
   18620: e0823003     	add	r3, r2, r3
   18624: e5932000     	ldr	r2, [r3]
   18628: e51b3010     	ldr	r3, [r11, #-0x10]
   1862c: e1520003     	cmp	r2, r3
   18630: 1a000003     	bne	0x18644 <ReadTableMappingData+0x100> @ imm = #0xc
   18634: e51b3010     	ldr	r3, [r11, #-0x10]
   18638: e2833001     	add	r3, r3, #1
   1863c: e50b3010     	str	r3, [r11, #-0x10]
   18640: ea00000c     	b	0x18678 <ReadTableMappingData+0x134> @ imm = #0x30
   18644: e51b3008     	ldr	r3, [r11, #-0x8]
   18648: e51b1024     	ldr	r1, [r11, #-0x24]
   1864c: e2832036     	add	r2, r3, #54
   18650: e3a03004     	mov	r3, #4
   18654: e1a02102     	lsl	r2, r2, #2
   18658: e0812002     	add	r2, r1, r2
   1865c: e0823003     	add	r3, r2, r3
   18660: e5932000     	ldr	r2, [r3]
   18664: e51b3010     	ldr	r3, [r11, #-0x10]
   18668: e1520003     	cmp	r2, r3
   1866c: da000001     	ble	0x18678 <ReadTableMappingData+0x134> @ imm = #0x4
   18670: e3a03006     	mov	r3, #6
   18674: ea0000a1     	b	0x18900 <ReadTableMappingData+0x3bc> @ imm = #0x284
   18678: e51b3008     	ldr	r3, [r11, #-0x8]
   1867c: e2833001     	add	r3, r3, #1
   18680: e50b3008     	str	r3, [r11, #-0x8]
   18684: e51b3024     	ldr	r3, [r11, #-0x24]
   18688: e59320c4     	ldr	r2, [r3, #0xc4]
   1868c: e51b3008     	ldr	r3, [r11, #-0x8]
   18690: e1520003     	cmp	r2, r3
   18694: caffffc8     	bgt	0x185bc <ReadTableMappingData+0x78> @ imm = #-0xe0
   18698: e3a03001     	mov	r3, #1
   1869c: e50b3014     	str	r3, [r11, #-0x14]
   186a0: ea00002e     	b	0x18760 <ReadTableMappingData+0x21c> @ imm = #0xb8
   186a4: e51b3014     	ldr	r3, [r11, #-0x14]
   186a8: e51b1024     	ldr	r1, [r11, #-0x24]
   186ac: e2832030     	add	r2, r3, #48
   186b0: e3a03004     	mov	r3, #4
   186b4: e1a02102     	lsl	r2, r2, #2
   186b8: e0812002     	add	r2, r1, r2
   186bc: e0823003     	add	r3, r2, r3
   186c0: e5932000     	ldr	r2, [r3]
   186c4: e51b3024     	ldr	r3, [r11, #-0x24]
   186c8: e59330c4     	ldr	r3, [r3, #0xc4]
   186cc: e1520003     	cmp	r2, r3
   186d0: 0a000001     	beq	0x186dc <ReadTableMappingData+0x198> @ imm = #0x4
   186d4: e3a03007     	mov	r3, #7
   186d8: ea000088     	b	0x18900 <ReadTableMappingData+0x3bc> @ imm = #0x220
   186dc: e3a03000     	mov	r3, #0
   186e0: e50b3008     	str	r3, [r11, #-0x8]
   186e4: ea000015     	b	0x18740 <ReadTableMappingData+0x1fc> @ imm = #0x54
   186e8: e51b1014     	ldr	r1, [r11, #-0x14]
   186ec: e51b3008     	ldr	r3, [r11, #-0x8]
   186f0: e51b2008     	ldr	r2, [r11, #-0x8]
   186f4: e51bc024     	ldr	r12, [r11, #-0x24]
   186f8: e2820036     	add	r0, r2, #54
   186fc: e3a02004     	mov	r2, #4
   18700: e1a00100     	lsl	r0, r0, #2
   18704: e08c0000     	add	r0, r12, r0
   18708: e0802002     	add	r2, r0, r2
   1870c: e5922000     	ldr	r2, [r2]
   18710: e51b0024     	ldr	r0, [r11, #-0x24]
   18714: e1a01181     	lsl	r1, r1, #3
   18718: e0813003     	add	r3, r1, r3
   1871c: e2831036     	add	r1, r3, #54
   18720: e3a03004     	mov	r3, #4
   18724: e1a01101     	lsl	r1, r1, #2
   18728: e0801001     	add	r1, r0, r1
   1872c: e0813003     	add	r3, r1, r3
   18730: e5832000     	str	r2, [r3]
   18734: e51b3008     	ldr	r3, [r11, #-0x8]
   18738: e2833001     	add	r3, r3, #1
   1873c: e50b3008     	str	r3, [r11, #-0x8]
   18740: e51b3024     	ldr	r3, [r11, #-0x24]
   18744: e59320c4     	ldr	r2, [r3, #0xc4]
   18748: e51b3008     	ldr	r3, [r11, #-0x8]
   1874c: e1520003     	cmp	r2, r3
   18750: caffffe4     	bgt	0x186e8 <ReadTableMappingData+0x1a4> @ imm = #-0x70
   18754: e51b3014     	ldr	r3, [r11, #-0x14]
   18758: e2833001     	add	r3, r3, #1
   1875c: e50b3014     	str	r3, [r11, #-0x14]
   18760: e51b2014     	ldr	r2, [r11, #-0x14]
   18764: e51b301c     	ldr	r3, [r11, #-0x1c]
   18768: e1520003     	cmp	r2, r3
   1876c: baffffcc     	blt	0x186a4 <ReadTableMappingData+0x160> @ imm = #-0xd0
   18770: ea000058     	b	0x188d8 <ReadTableMappingData+0x394> @ imm = #0x160
   18774: e3a03000     	mov	r3, #0
   18778: e50b3014     	str	r3, [r11, #-0x14]
   1877c: ea000051     	b	0x188c8 <ReadTableMappingData+0x384> @ imm = #0x144
   18780: e3a03000     	mov	r3, #0
   18784: e50b3008     	str	r3, [r11, #-0x8]
   18788: ea000040     	b	0x18890 <ReadTableMappingData+0x34c> @ imm = #0x100
   1878c: e51b3014     	ldr	r3, [r11, #-0x14]
   18790: e3530000     	cmp	r3, #0
   18794: 1a000002     	bne	0x187a4 <ReadTableMappingData+0x260> @ imm = #0x8
   18798: e51b3008     	ldr	r3, [r11, #-0x8]
   1879c: e3530000     	cmp	r3, #0
   187a0: 0a000037     	beq	0x18884 <ReadTableMappingData+0x340> @ imm = #0xdc
   187a4: e51b0010     	ldr	r0, [r11, #-0x10]
   187a8: ebfffc8f     	bl	0x179ec <Log2RoundUp>   @ imm = #-0xdc4
   187ac: e1a03000     	mov	r3, r0
   187b0: e50b300c     	str	r3, [r11, #-0xc]
   187b4: e51b3024     	ldr	r3, [r11, #-0x24]
   187b8: e28330dc     	add	r3, r3, #220
   187bc: e1a02003     	mov	r2, r3
   187c0: e51b3014     	ldr	r3, [r11, #-0x14]
   187c4: e1a01183     	lsl	r1, r3, #3
   187c8: e51b3008     	ldr	r3, [r11, #-0x8]
   187cc: e0813003     	add	r3, r1, r3
   187d0: e1a03103     	lsl	r3, r3, #2
   187d4: e0823003     	add	r3, r2, r3
   187d8: e51b0018     	ldr	r0, [r11, #-0x18]
   187dc: e51b100c     	ldr	r1, [r11, #-0xc]
   187e0: e1a02003     	mov	r2, r3
   187e4: eb000c11     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x3044
   187e8: e1a03000     	mov	r3, r0
   187ec: e3530000     	cmp	r3, #0
   187f0: 0a000001     	beq	0x187fc <ReadTableMappingData+0x2b8> @ imm = #0x4
   187f4: e3a03001     	mov	r3, #1
   187f8: ea000040     	b	0x18900 <ReadTableMappingData+0x3bc> @ imm = #0x100
   187fc: e51b2014     	ldr	r2, [r11, #-0x14]
   18800: e51b3008     	ldr	r3, [r11, #-0x8]
   18804: e51b1024     	ldr	r1, [r11, #-0x24]
   18808: e1a02182     	lsl	r2, r2, #3
   1880c: e0823003     	add	r3, r2, r3
   18810: e2832036     	add	r2, r3, #54
   18814: e3a03004     	mov	r3, #4
   18818: e1a02102     	lsl	r2, r2, #2
   1881c: e0812002     	add	r2, r1, r2
   18820: e0823003     	add	r3, r2, r3
   18824: e5932000     	ldr	r2, [r3]
   18828: e51b3010     	ldr	r3, [r11, #-0x10]
   1882c: e1520003     	cmp	r2, r3
   18830: 1a000003     	bne	0x18844 <ReadTableMappingData+0x300> @ imm = #0xc
   18834: e51b3010     	ldr	r3, [r11, #-0x10]
   18838: e2833001     	add	r3, r3, #1
   1883c: e50b3010     	str	r3, [r11, #-0x10]
   18840: ea00000f     	b	0x18884 <ReadTableMappingData+0x340> @ imm = #0x3c
   18844: e51b2014     	ldr	r2, [r11, #-0x14]
   18848: e51b3008     	ldr	r3, [r11, #-0x8]
   1884c: e51b1024     	ldr	r1, [r11, #-0x24]
   18850: e1a02182     	lsl	r2, r2, #3
   18854: e0823003     	add	r3, r2, r3
   18858: e2832036     	add	r2, r3, #54
   1885c: e3a03004     	mov	r3, #4
   18860: e1a02102     	lsl	r2, r2, #2
   18864: e0812002     	add	r2, r1, r2
   18868: e0823003     	add	r3, r2, r3
   1886c: e5932000     	ldr	r2, [r3]
   18870: e51b3010     	ldr	r3, [r11, #-0x10]
   18874: e1520003     	cmp	r2, r3
   18878: da000001     	ble	0x18884 <ReadTableMappingData+0x340> @ imm = #0x4
   1887c: e3a03006     	mov	r3, #6
   18880: ea00001e     	b	0x18900 <ReadTableMappingData+0x3bc> @ imm = #0x78
   18884: e51b3008     	ldr	r3, [r11, #-0x8]
   18888: e2833001     	add	r3, r3, #1
   1888c: e50b3008     	str	r3, [r11, #-0x8]
   18890: e51b3014     	ldr	r3, [r11, #-0x14]
   18894: e51b1024     	ldr	r1, [r11, #-0x24]
   18898: e2832030     	add	r2, r3, #48
   1889c: e3a03004     	mov	r3, #4
   188a0: e1a02102     	lsl	r2, r2, #2
   188a4: e0812002     	add	r2, r1, r2
   188a8: e0823003     	add	r3, r2, r3
   188ac: e5932000     	ldr	r2, [r3]
   188b0: e51b3008     	ldr	r3, [r11, #-0x8]
   188b4: e1520003     	cmp	r2, r3
   188b8: caffffb3     	bgt	0x1878c <ReadTableMappingData+0x248> @ imm = #-0x134
   188bc: e51b3014     	ldr	r3, [r11, #-0x14]
   188c0: e2833001     	add	r3, r3, #1
   188c4: e50b3014     	str	r3, [r11, #-0x14]
   188c8: e51b2014     	ldr	r2, [r11, #-0x14]
   188cc: e51b301c     	ldr	r3, [r11, #-0x1c]
   188d0: e1520003     	cmp	r2, r3
   188d4: baffffa9     	blt	0x18780 <ReadTableMappingData+0x23c> @ imm = #-0x15c
   188d8: e51b2010     	ldr	r2, [r11, #-0x10]
   188dc: e51b3020     	ldr	r3, [r11, #-0x20]
   188e0: e1520003     	cmp	r2, r3
   188e4: da000001     	ble	0x188f0 <ReadTableMappingData+0x3ac> @ imm = #0x4
   188e8: e3a03005     	mov	r3, #5
   188ec: ea000003     	b	0x18900 <ReadTableMappingData+0x3bc> @ imm = #0xc
   188f0: e59b3004     	ldr	r3, [r11, #0x4]
   188f4: e51b2010     	ldr	r2, [r11, #-0x10]
   188f8: e5832000     	str	r2, [r3]
   188fc: e3a03000     	mov	r3, #0
   18900: e1a00003     	mov	r0, r3
   18904: e24bd004     	sub	sp, r11, #4
   18908: e8bd8800     	pop	{r11, pc}

