000192ec <ReadProbabilityTables>:
   192ec: e92d4800     	push	{r11, lr}
   192f0: e28db004     	add	r11, sp, #4
   192f4: e24dd028     	sub	sp, sp, #40
   192f8: e50b0020     	str	r0, [r11, #-0x20]
   192fc: e50b1024     	str	r1, [r11, #-0x24]
   19300: e50b2028     	str	r2, [r11, #-0x28]
   19304: e50b302c     	str	r3, [r11, #-0x2c]
   19308: e3a03000     	mov	r3, #0
   1930c: e50b3014     	str	r3, [r11, #-0x14]
   19310: ea000173     	b	0x198e4 <ReadProbabilityTables+0x5f8> @ imm = #0x5cc
   19314: e51b3024     	ldr	r3, [r11, #-0x24]
   19318: e2832044     	add	r2, r3, #68
   1931c: e51b3014     	ldr	r3, [r11, #-0x14]
   19320: e1a03103     	lsl	r3, r3, #2
   19324: e0823003     	add	r3, r2, r3
   19328: e51b0020     	ldr	r0, [r11, #-0x20]
   1932c: e3a01006     	mov	r1, #6
   19330: e1a02003     	mov	r2, r3
   19334: eb00093d     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x24f4
   19338: e1a03000     	mov	r3, r0
   1933c: e3530000     	cmp	r3, #0
   19340: 0a000001     	beq	0x1934c <ReadProbabilityTables+0x60> @ imm = #0x4
   19344: e3a03001     	mov	r3, #1
   19348: ea00016b     	b	0x198fc <ReadProbabilityTables+0x610> @ imm = #0x5ac
   1934c: e51b3014     	ldr	r3, [r11, #-0x14]
   19350: e51b0024     	ldr	r0, [r11, #-0x24]
   19354: e2831010     	add	r1, r3, #16
   19358: e3a02004     	mov	r2, #4
   1935c: e1a01101     	lsl	r1, r1, #2
   19360: e0801001     	add	r1, r0, r1
   19364: e0812002     	add	r2, r1, r2
   19368: e5922000     	ldr	r2, [r2]
   1936c: e2822001     	add	r2, r2, #1
   19370: e51b0024     	ldr	r0, [r11, #-0x24]
   19374: e2831010     	add	r1, r3, #16
   19378: e3a03004     	mov	r3, #4
   1937c: e1a01101     	lsl	r1, r1, #2
   19380: e0801001     	add	r1, r0, r1
   19384: e0813003     	add	r3, r1, r3
   19388: e5832000     	str	r2, [r3]
   1938c: e51b3014     	ldr	r3, [r11, #-0x14]
   19390: e51b1024     	ldr	r1, [r11, #-0x24]
   19394: e2832010     	add	r2, r3, #16
   19398: e3a03004     	mov	r3, #4
   1939c: e1a02102     	lsl	r2, r2, #2
   193a0: e0812002     	add	r2, r1, r2
   193a4: e0823003     	add	r3, r2, r3
   193a8: e5933000     	ldr	r3, [r3]
   193ac: e3530001     	cmp	r3, #1
   193b0: da00013a     	ble	0x198a0 <ReadProbabilityTables+0x5b4> @ imm = #0x4e8
   193b4: e51b3028     	ldr	r3, [r11, #-0x28]
   193b8: e5932008     	ldr	r2, [r3, #0x8]
   193bc: e51b3014     	ldr	r3, [r11, #-0x14]
   193c0: e1a03103     	lsl	r3, r3, #2
   193c4: e0823003     	add	r3, r2, r3
   193c8: e51b0020     	ldr	r0, [r11, #-0x20]
   193cc: e3a01001     	mov	r1, #1
   193d0: e1a02003     	mov	r2, r3
   193d4: eb000915     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x2454
   193d8: e1a03000     	mov	r3, r0
   193dc: e3530000     	cmp	r3, #0
   193e0: 0a000001     	beq	0x193ec <ReadProbabilityTables+0x100> @ imm = #0x4
   193e4: e3a03001     	mov	r3, #1
   193e8: ea000143     	b	0x198fc <ReadProbabilityTables+0x610> @ imm = #0x50c
   193ec: e51b3028     	ldr	r3, [r11, #-0x28]
   193f0: e5932008     	ldr	r2, [r3, #0x8]
   193f4: e51b3014     	ldr	r3, [r11, #-0x14]
   193f8: e1a03103     	lsl	r3, r3, #2
   193fc: e0823003     	add	r3, r2, r3
   19400: e5933000     	ldr	r3, [r3]
   19404: e3530000     	cmp	r3, #0
   19408: 1a000034     	bne	0x194e0 <ReadProbabilityTables+0x1f4> @ imm = #0xd0
   1940c: e51b3028     	ldr	r3, [r11, #-0x28]
   19410: e593200c     	ldr	r2, [r3, #0xc]
   19414: e51b3014     	ldr	r3, [r11, #-0x14]
   19418: e1a03103     	lsl	r3, r3, #2
   1941c: e0823003     	add	r3, r2, r3
   19420: e3e02000     	mvn	r2, #0
   19424: e5832000     	str	r2, [r3]
   19428: e3a03000     	mov	r3, #0
   1942c: e50b3018     	str	r3, [r11, #-0x18]
   19430: ea00001e     	b	0x194b0 <ReadProbabilityTables+0x1c4> @ imm = #0x78
   19434: e51b3014     	ldr	r3, [r11, #-0x14]
   19438: e1a03103     	lsl	r3, r3, #2
   1943c: e51b202c     	ldr	r2, [r11, #-0x2c]
   19440: e0823003     	add	r3, r2, r3
   19444: e5932000     	ldr	r2, [r3]
   19448: e51b3018     	ldr	r3, [r11, #-0x18]
   1944c: e1a03103     	lsl	r3, r3, #2
   19450: e0823003     	add	r3, r2, r3
   19454: e51b0020     	ldr	r0, [r11, #-0x20]
   19458: e3a01007     	mov	r1, #7
   1945c: e1a02003     	mov	r2, r3
   19460: eb0008f2     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x23c8
   19464: e1a03000     	mov	r3, r0
   19468: e3530000     	cmp	r3, #0
   1946c: 0a000001     	beq	0x19478 <ReadProbabilityTables+0x18c> @ imm = #0x4
   19470: e3a03001     	mov	r3, #1
   19474: ea000120     	b	0x198fc <ReadProbabilityTables+0x610> @ imm = #0x480
   19478: e51b3014     	ldr	r3, [r11, #-0x14]
   1947c: e1a03103     	lsl	r3, r3, #2
   19480: e51b202c     	ldr	r2, [r11, #-0x2c]
   19484: e0823003     	add	r3, r2, r3
   19488: e5932000     	ldr	r2, [r3]
   1948c: e51b3018     	ldr	r3, [r11, #-0x18]
   19490: e1a03103     	lsl	r3, r3, #2
   19494: e0823003     	add	r3, r2, r3
   19498: e5932000     	ldr	r2, [r3]
   1949c: e2822001     	add	r2, r2, #1
   194a0: e5832000     	str	r2, [r3]
   194a4: e51b3018     	ldr	r3, [r11, #-0x18]
   194a8: e2833001     	add	r3, r3, #1
   194ac: e50b3018     	str	r3, [r11, #-0x18]
   194b0: e51b3014     	ldr	r3, [r11, #-0x14]
   194b4: e51b1024     	ldr	r1, [r11, #-0x24]
   194b8: e2832010     	add	r2, r3, #16
   194bc: e3a03004     	mov	r3, #4
   194c0: e1a02102     	lsl	r2, r2, #2
   194c4: e0812002     	add	r2, r1, r2
   194c8: e0823003     	add	r3, r2, r3
   194cc: e5932000     	ldr	r2, [r3]
   194d0: e51b3018     	ldr	r3, [r11, #-0x18]
   194d4: e1520003     	cmp	r2, r3
   194d8: caffffd5     	bgt	0x19434 <ReadProbabilityTables+0x148> @ imm = #-0xac
   194dc: ea0000fd     	b	0x198d8 <ReadProbabilityTables+0x5ec> @ imm = #0x3f4
   194e0: e51b3028     	ldr	r3, [r11, #-0x28]
   194e4: e593200c     	ldr	r2, [r3, #0xc]
   194e8: e51b3014     	ldr	r3, [r11, #-0x14]
   194ec: e1a03103     	lsl	r3, r3, #2
   194f0: e0823003     	add	r3, r2, r3
   194f4: e51b0020     	ldr	r0, [r11, #-0x20]
   194f8: e3a01002     	mov	r1, #2
   194fc: e1a02003     	mov	r2, r3
   19500: eb0008ca     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x2328
   19504: e1a03000     	mov	r3, r0
   19508: e3530000     	cmp	r3, #0
   1950c: 0a000001     	beq	0x19518 <ReadProbabilityTables+0x22c> @ imm = #0x4
   19510: e3a03001     	mov	r3, #1
   19514: ea0000f8     	b	0x198fc <ReadProbabilityTables+0x610> @ imm = #0x3e0
   19518: e51b3028     	ldr	r3, [r11, #-0x28]
   1951c: e593200c     	ldr	r2, [r3, #0xc]
   19520: e51b3014     	ldr	r3, [r11, #-0x14]
   19524: e1a03103     	lsl	r3, r3, #2
   19528: e0823003     	add	r3, r2, r3
   1952c: e5933000     	ldr	r3, [r3]
   19530: e50b3008     	str	r3, [r11, #-0x8]
   19534: e51b3028     	ldr	r3, [r11, #-0x28]
   19538: e5932000     	ldr	r2, [r3]
   1953c: e51b3008     	ldr	r3, [r11, #-0x8]
   19540: e1a03103     	lsl	r3, r3, #2
   19544: e0823003     	add	r3, r2, r3
   19548: e5932000     	ldr	r2, [r3]
   1954c: e51b3014     	ldr	r3, [r11, #-0x14]
   19550: e51b0024     	ldr	r0, [r11, #-0x24]
   19554: e2831010     	add	r1, r3, #16
   19558: e3a03004     	mov	r3, #4
   1955c: e1a01101     	lsl	r1, r1, #2
   19560: e0801001     	add	r1, r0, r1
   19564: e0813003     	add	r3, r1, r3
   19568: e5933000     	ldr	r3, [r3]
   1956c: e1520003     	cmp	r2, r3
   19570: ba000001     	blt	0x1957c <ReadProbabilityTables+0x290> @ imm = #0x4
   19574: e3a0300b     	mov	r3, #11
   19578: ea0000df     	b	0x198fc <ReadProbabilityTables+0x610> @ imm = #0x37c
   1957c: e3a03000     	mov	r3, #0
   19580: e50b3018     	str	r3, [r11, #-0x18]
   19584: ea00001e     	b	0x19604 <ReadProbabilityTables+0x318> @ imm = #0x78
   19588: e51b3014     	ldr	r3, [r11, #-0x14]
   1958c: e1a03103     	lsl	r3, r3, #2
   19590: e51b202c     	ldr	r2, [r11, #-0x2c]
   19594: e0823003     	add	r3, r2, r3
   19598: e5932000     	ldr	r2, [r3]
   1959c: e51b3018     	ldr	r3, [r11, #-0x18]
   195a0: e1a03103     	lsl	r3, r3, #2
   195a4: e0823003     	add	r3, r2, r3
   195a8: e51b0020     	ldr	r0, [r11, #-0x20]
   195ac: e3a01007     	mov	r1, #7
   195b0: e1a02003     	mov	r2, r3
   195b4: eb00089d     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x2274
   195b8: e1a03000     	mov	r3, r0
   195bc: e3530000     	cmp	r3, #0
   195c0: 0a000001     	beq	0x195cc <ReadProbabilityTables+0x2e0> @ imm = #0x4
   195c4: e3a03001     	mov	r3, #1
   195c8: ea0000cb     	b	0x198fc <ReadProbabilityTables+0x610> @ imm = #0x32c
   195cc: e51b3014     	ldr	r3, [r11, #-0x14]
   195d0: e1a03103     	lsl	r3, r3, #2
   195d4: e51b202c     	ldr	r2, [r11, #-0x2c]
   195d8: e0823003     	add	r3, r2, r3
   195dc: e5932000     	ldr	r2, [r3]
   195e0: e51b3018     	ldr	r3, [r11, #-0x18]
   195e4: e1a03103     	lsl	r3, r3, #2
   195e8: e0823003     	add	r3, r2, r3
   195ec: e5932000     	ldr	r2, [r3]
   195f0: e2822001     	add	r2, r2, #1
   195f4: e5832000     	str	r2, [r3]
   195f8: e51b3018     	ldr	r3, [r11, #-0x18]
   195fc: e2833001     	add	r3, r3, #1
   19600: e50b3018     	str	r3, [r11, #-0x18]
   19604: e51b3028     	ldr	r3, [r11, #-0x28]
   19608: e5932000     	ldr	r2, [r3]
   1960c: e51b3008     	ldr	r3, [r11, #-0x8]
   19610: e1a03103     	lsl	r3, r3, #2
   19614: e0823003     	add	r3, r2, r3
   19618: e5932000     	ldr	r2, [r3]
   1961c: e51b3018     	ldr	r3, [r11, #-0x18]
   19620: e1520003     	cmp	r2, r3
   19624: caffffd7     	bgt	0x19588 <ReadProbabilityTables+0x29c> @ imm = #-0xa4
   19628: e51b3028     	ldr	r3, [r11, #-0x28]
   1962c: e5932010     	ldr	r2, [r3, #0x10]
   19630: e51b3014     	ldr	r3, [r11, #-0x14]
   19634: e1a03103     	lsl	r3, r3, #2
   19638: e0823003     	add	r3, r2, r3
   1963c: e5932000     	ldr	r2, [r3]
   19640: e51b3008     	ldr	r3, [r11, #-0x8]
   19644: e1a03103     	lsl	r3, r3, #2
   19648: e0823003     	add	r3, r2, r3
   1964c: e51b0020     	ldr	r0, [r11, #-0x20]
   19650: e3a01003     	mov	r1, #3
   19654: e1a02003     	mov	r2, r3
   19658: eb000874     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x21d0
   1965c: e1a03000     	mov	r3, r0
   19660: e3530000     	cmp	r3, #0
   19664: 0a000001     	beq	0x19670 <ReadProbabilityTables+0x384> @ imm = #0x4
   19668: e3a03001     	mov	r3, #1
   1966c: ea0000a2     	b	0x198fc <ReadProbabilityTables+0x610> @ imm = #0x288
   19670: e51b3028     	ldr	r3, [r11, #-0x28]
   19674: e5932000     	ldr	r2, [r3]
   19678: e51b3008     	ldr	r3, [r11, #-0x8]
   1967c: e1a03103     	lsl	r3, r3, #2
   19680: e0823003     	add	r3, r2, r3
   19684: e5933000     	ldr	r3, [r3]
   19688: e50b3018     	str	r3, [r11, #-0x18]
   1968c: ea000077     	b	0x19870 <ReadProbabilityTables+0x584> @ imm = #0x1dc
   19690: e51b3018     	ldr	r3, [r11, #-0x18]
   19694: e3530000     	cmp	r3, #0
   19698: ba000002     	blt	0x196a8 <ReadProbabilityTables+0x3bc> @ imm = #0x8
   1969c: e51b3018     	ldr	r3, [r11, #-0x18]
   196a0: e3530040     	cmp	r3, #64
   196a4: da000001     	ble	0x196b0 <ReadProbabilityTables+0x3c4> @ imm = #0x4
   196a8: e3a0300c     	mov	r3, #12
   196ac: ea000092     	b	0x198fc <ReadProbabilityTables+0x610> @ imm = #0x248
   196b0: e3a03000     	mov	r3, #0
   196b4: e50b3010     	str	r3, [r11, #-0x10]
   196b8: e3a03000     	mov	r3, #0
   196bc: e50b300c     	str	r3, [r11, #-0xc]
   196c0: ea00001c     	b	0x19738 <ReadProbabilityTables+0x44c> @ imm = #0x70
   196c4: e51b3028     	ldr	r3, [r11, #-0x28]
   196c8: e5932004     	ldr	r2, [r3, #0x4]
   196cc: e51b3008     	ldr	r3, [r11, #-0x8]
   196d0: e1a03103     	lsl	r3, r3, #2
   196d4: e0823003     	add	r3, r2, r3
   196d8: e5932000     	ldr	r2, [r3]
   196dc: e51b3010     	ldr	r3, [r11, #-0x10]
   196e0: e1a03103     	lsl	r3, r3, #2
   196e4: e0823003     	add	r3, r2, r3
   196e8: e5933000     	ldr	r3, [r3]
   196ec: e51b2014     	ldr	r2, [r11, #-0x14]
   196f0: e1a02102     	lsl	r2, r2, #2
   196f4: e51b102c     	ldr	r1, [r11, #-0x2c]
   196f8: e0812002     	add	r2, r1, r2
   196fc: e5921000     	ldr	r1, [r2]
   19700: e51b0018     	ldr	r0, [r11, #-0x18]
   19704: e51b2010     	ldr	r2, [r11, #-0x10]
   19708: e0622000     	rsb	r2, r2, r0
   1970c: e2422001     	sub	r2, r2, #1
   19710: e1a02102     	lsl	r2, r2, #2
   19714: e0812002     	add	r2, r1, r2
   19718: e5922000     	ldr	r2, [r2]
   1971c: e0030392     	mul	r3, r2, r3
   19720: e51b200c     	ldr	r2, [r11, #-0xc]
   19724: e0823003     	add	r3, r2, r3
   19728: e50b300c     	str	r3, [r11, #-0xc]
   1972c: e51b3010     	ldr	r3, [r11, #-0x10]
   19730: e2833001     	add	r3, r3, #1
   19734: e50b3010     	str	r3, [r11, #-0x10]
   19738: e51b3028     	ldr	r3, [r11, #-0x28]
   1973c: e5932000     	ldr	r2, [r3]
   19740: e51b3008     	ldr	r3, [r11, #-0x8]
   19744: e1a03103     	lsl	r3, r3, #2
   19748: e0823003     	add	r3, r2, r3
   1974c: e5932000     	ldr	r2, [r3]
   19750: e51b3010     	ldr	r3, [r11, #-0x10]
   19754: e1520003     	cmp	r2, r3
   19758: caffffd9     	bgt	0x196c4 <ReadProbabilityTables+0x3d8> @ imm = #-0x9c
   1975c: e51b300c     	ldr	r3, [r11, #-0xc]
   19760: e3530000     	cmp	r3, #0
   19764: ba000016     	blt	0x197c4 <ReadProbabilityTables+0x4d8> @ imm = #0x58
   19768: e51b3028     	ldr	r3, [r11, #-0x28]
   1976c: e5932010     	ldr	r2, [r3, #0x10]
   19770: e51b3014     	ldr	r3, [r11, #-0x14]
   19774: e1a03103     	lsl	r3, r3, #2
   19778: e0823003     	add	r3, r2, r3
   1977c: e5932000     	ldr	r2, [r3]
   19780: e51b3008     	ldr	r3, [r11, #-0x8]
   19784: e1a03103     	lsl	r3, r3, #2
   19788: e0823003     	add	r3, r2, r3
   1978c: e5933000     	ldr	r3, [r3]
   19790: e51b0020     	ldr	r0, [r11, #-0x20]
   19794: e1a01003     	mov	r1, r3
   19798: ebfff862     	bl	0x17928 <RiceDecode>    @ imm = #-0x1e78
   1979c: e1a02000     	mov	r2, r0
   197a0: e51b300c     	ldr	r3, [r11, #-0xc]
   197a4: e2833004     	add	r3, r3, #4
   197a8: e2831007     	add	r1, r3, #7
   197ac: e3530000     	cmp	r3, #0
   197b0: b1a03001     	movlt	r3, r1
   197b4: e1a031c3     	asr	r3, r3, #3
   197b8: e0633002     	rsb	r3, r3, r2
   197bc: e50b301c     	str	r3, [r11, #-0x1c]
   197c0: ea000015     	b	0x1981c <ReadProbabilityTables+0x530> @ imm = #0x54
   197c4: e51b3028     	ldr	r3, [r11, #-0x28]
   197c8: e5932010     	ldr	r2, [r3, #0x10]
   197cc: e51b3014     	ldr	r3, [r11, #-0x14]
   197d0: e1a03103     	lsl	r3, r3, #2
   197d4: e0823003     	add	r3, r2, r3
   197d8: e5932000     	ldr	r2, [r3]
   197dc: e51b3008     	ldr	r3, [r11, #-0x8]
   197e0: e1a03103     	lsl	r3, r3, #2
   197e4: e0823003     	add	r3, r2, r3
   197e8: e5933000     	ldr	r3, [r3]
   197ec: e51b0020     	ldr	r0, [r11, #-0x20]
   197f0: e1a01003     	mov	r1, r3
   197f4: ebfff84b     	bl	0x17928 <RiceDecode>    @ imm = #-0x1ed4
   197f8: e1a02000     	mov	r2, r0
   197fc: e51b300c     	ldr	r3, [r11, #-0xc]
   19800: e2633003     	rsb	r3, r3, #3
   19804: e2831007     	add	r1, r3, #7
   19808: e3530000     	cmp	r3, #0
   1980c: b1a03001     	movlt	r3, r1
   19810: e1a031c3     	asr	r3, r3, #3
   19814: e0823003     	add	r3, r2, r3
   19818: e50b301c     	str	r3, [r11, #-0x1c]
   1981c: e51b301c     	ldr	r3, [r11, #-0x1c]
   19820: e3530000     	cmp	r3, #0
   19824: da000002     	ble	0x19834 <ReadProbabilityTables+0x548> @ imm = #0x8
   19828: e51b301c     	ldr	r3, [r11, #-0x1c]
   1982c: e3530080     	cmp	r3, #128
   19830: da000001     	ble	0x1983c <ReadProbabilityTables+0x550> @ imm = #0x4
   19834: e3a0300c     	mov	r3, #12
   19838: ea00002f     	b	0x198fc <ReadProbabilityTables+0x610> @ imm = #0xbc
   1983c: e51b3014     	ldr	r3, [r11, #-0x14]
   19840: e1a03103     	lsl	r3, r3, #2
   19844: e51b202c     	ldr	r2, [r11, #-0x2c]
   19848: e0823003     	add	r3, r2, r3
   1984c: e5932000     	ldr	r2, [r3]
   19850: e51b3018     	ldr	r3, [r11, #-0x18]
   19854: e1a03103     	lsl	r3, r3, #2
   19858: e0823003     	add	r3, r2, r3
   1985c: e51b201c     	ldr	r2, [r11, #-0x1c]
   19860: e5832000     	str	r2, [r3]
   19864: e51b3018     	ldr	r3, [r11, #-0x18]
   19868: e2833001     	add	r3, r3, #1
   1986c: e50b3018     	str	r3, [r11, #-0x18]
   19870: e51b3014     	ldr	r3, [r11, #-0x14]
   19874: e51b1024     	ldr	r1, [r11, #-0x24]
   19878: e2832010     	add	r2, r3, #16
   1987c: e3a03004     	mov	r3, #4
   19880: e1a02102     	lsl	r2, r2, #2
   19884: e0812002     	add	r2, r1, r2
   19888: e0823003     	add	r3, r2, r3
   1988c: e5932000     	ldr	r2, [r3]
   19890: e51b3018     	ldr	r3, [r11, #-0x18]
   19894: e1520003     	cmp	r2, r3
   19898: caffff7c     	bgt	0x19690 <ReadProbabilityTables+0x3a4> @ imm = #-0x210
   1989c: ea00000d     	b	0x198d8 <ReadProbabilityTables+0x5ec> @ imm = #0x34
   198a0: e51b3014     	ldr	r3, [r11, #-0x14]
   198a4: e1a03103     	lsl	r3, r3, #2
   198a8: e51b202c     	ldr	r2, [r11, #-0x2c]
   198ac: e0823003     	add	r3, r2, r3
   198b0: e5933000     	ldr	r3, [r3]
   198b4: e3a02080     	mov	r2, #128
   198b8: e5832000     	str	r2, [r3]
   198bc: e51b3028     	ldr	r3, [r11, #-0x28]
   198c0: e593200c     	ldr	r2, [r3, #0xc]
   198c4: e51b3014     	ldr	r3, [r11, #-0x14]
   198c8: e1a03103     	lsl	r3, r3, #2
   198cc: e0823003     	add	r3, r2, r3
   198d0: e3e02000     	mvn	r2, #0
   198d4: e5832000     	str	r2, [r3]
   198d8: e51b3014     	ldr	r3, [r11, #-0x14]
   198dc: e2833001     	add	r3, r3, #1
   198e0: e50b3014     	str	r3, [r11, #-0x14]
   198e4: e51b3024     	ldr	r3, [r11, #-0x24]
   198e8: e593200c     	ldr	r2, [r3, #0xc]
   198ec: e51b3014     	ldr	r3, [r11, #-0x14]
   198f0: e1520003     	cmp	r2, r3
   198f4: cafffe86     	bgt	0x19314 <ReadProbabilityTables+0x28> @ imm = #-0x5e8
   198f8: e3a03000     	mov	r3, #0
   198fc: e1a00003     	mov	r0, r3
   19900: e24bd004     	sub	sp, r11, #4
   19904: e8bd8800     	pop	{r11, pc}

