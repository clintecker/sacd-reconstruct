0001fff8 <scarletbook_print_area_toc>:
   1fff8: e92d4830     	push	{r4, r5, r11, lr}
   1fffc: e28db00c     	add	r11, sp, #12
   20000: e24dd028     	sub	sp, sp, #40
   20004: e50b0030     	str	r0, [r11, #-0x30]
   20008: e50b1034     	str	r1, [r11, #-0x34]
   2000c: e51b3030     	ldr	r3, [r11, #-0x30]
   20010: e283205c     	add	r2, r3, #92
   20014: e51b3034     	ldr	r3, [r11, #-0x34]
   20018: e59f1494     	ldr	r1, [pc, #0x494]        @ 0x204b4 <scarletbook_print_area_toc+0x4bc>
   2001c: e0030391     	mul	r3, r1, r3
   20020: e0823003     	add	r3, r2, r3
   20024: e50b3018     	str	r3, [r11, #-0x18]
   20028: e51b3018     	ldr	r3, [r11, #-0x18]
   2002c: e5933004     	ldr	r3, [r3, #0x4]
   20030: e50b3014     	str	r3, [r11, #-0x14]
   20034: e51b2018     	ldr	r2, [r11, #-0x18]
   20038: e59f3478     	ldr	r3, [pc, #0x478]        @ 0x204b8 <scarletbook_print_area_toc+0x4c0>
   2003c: e7923003     	ldr	r3, [r2, r3]
   20040: e50b3024     	str	r3, [r11, #-0x24]
   20044: e51b3018     	ldr	r3, [r11, #-0x18]
   20048: e5933008     	ldr	r3, [r3, #0x8]
   2004c: e50b3020     	str	r3, [r11, #-0x20]
   20050: e51b3018     	ldr	r3, [r11, #-0x18]
   20054: e593300c     	ldr	r3, [r3, #0xc]
   20058: e50b301c     	str	r3, [r11, #-0x1c]
   2005c: e59f3458     	ldr	r3, [pc, #0x458]        @ 0x204bc <scarletbook_print_area_toc+0x4c4>
   20060: e5933000     	ldr	r3, [r3]
   20064: e1a02003     	mov	r2, r3
   20068: e59f3450     	ldr	r3, [pc, #0x450]        @ 0x204c0 <scarletbook_print_area_toc+0x4c8>
   2006c: e1a00002     	mov	r0, r2
   20070: e1a01003     	mov	r1, r3
   20074: e51b2034     	ldr	r2, [r11, #-0x34]
   20078: ebffb1a1     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x1397c
   2007c: e59f3438     	ldr	r3, [pc, #0x438]        @ 0x204bc <scarletbook_print_area_toc+0x4c4>
   20080: e5933000     	ldr	r3, [r3]
   20084: e1a00003     	mov	r0, r3
   20088: e59f1434     	ldr	r1, [pc, #0x434]        @ 0x204c4 <scarletbook_print_area_toc+0x4cc>
   2008c: e51b3014     	ldr	r3, [r11, #-0x14]
   20090: e5d33008     	ldrb	r3, [r3, #0x8]
   20094: e1a02003     	mov	r2, r3
   20098: e51b3014     	ldr	r3, [r11, #-0x14]
   2009c: e5d33009     	ldrb	r3, [r3, #0x9]
   200a0: ebffb197     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x139a4
   200a4: e51b2018     	ldr	r2, [r11, #-0x18]
   200a8: e59f3418     	ldr	r3, [pc, #0x418]        @ 0x204c8 <scarletbook_print_area_toc+0x4d0>
   200ac: e7923003     	ldr	r3, [r2, r3]
   200b0: e3530000     	cmp	r3, #0
   200b4: 0a00000d     	beq	0x200f0 <scarletbook_print_area_toc+0xf8> @ imm = #0x34
   200b8: e59f33fc     	ldr	r3, [pc, #0x3fc]        @ 0x204bc <scarletbook_print_area_toc+0x4c4>
   200bc: e5933000     	ldr	r3, [r3]
   200c0: e1a05003     	mov	r5, r3
   200c4: e59f4400     	ldr	r4, [pc, #0x400]        @ 0x204cc <scarletbook_print_area_toc+0x4d4>
   200c8: e51b2018     	ldr	r2, [r11, #-0x18]
   200cc: e59f33f4     	ldr	r3, [pc, #0x3f4]        @ 0x204c8 <scarletbook_print_area_toc+0x4d0>
   200d0: e7923003     	ldr	r3, [r2, r3]
   200d4: e1a00003     	mov	r0, r3
   200d8: ebfffc38     	bl	0x1f1c0 <ucs>           @ imm = #-0xf20
   200dc: e1a03000     	mov	r3, r0
   200e0: e1a00005     	mov	r0, r5
   200e4: e1a01004     	mov	r1, r4
   200e8: e1a02003     	mov	r2, r3
   200ec: ebffb184     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x139f0
   200f0: e51b2018     	ldr	r2, [r11, #-0x18]
   200f4: e59f33d4     	ldr	r3, [pc, #0x3d4]        @ 0x204d0 <scarletbook_print_area_toc+0x4d8>
   200f8: e7923003     	ldr	r3, [r2, r3]
   200fc: e3530000     	cmp	r3, #0
   20100: 0a00000d     	beq	0x2013c <scarletbook_print_area_toc+0x144> @ imm = #0x34
   20104: e59f33b0     	ldr	r3, [pc, #0x3b0]        @ 0x204bc <scarletbook_print_area_toc+0x4c4>
   20108: e5933000     	ldr	r3, [r3]
   2010c: e1a05003     	mov	r5, r3
   20110: e59f43bc     	ldr	r4, [pc, #0x3bc]        @ 0x204d4 <scarletbook_print_area_toc+0x4dc>
   20114: e51b2018     	ldr	r2, [r11, #-0x18]
   20118: e59f33b0     	ldr	r3, [pc, #0x3b0]        @ 0x204d0 <scarletbook_print_area_toc+0x4d8>
   2011c: e7923003     	ldr	r3, [r2, r3]
   20120: e1a00003     	mov	r0, r3
   20124: ebfffc25     	bl	0x1f1c0 <ucs>           @ imm = #-0xf6c
   20128: e1a03000     	mov	r3, r0
   2012c: e1a00005     	mov	r0, r5
   20130: e1a01004     	mov	r1, r4
   20134: e1a02003     	mov	r2, r3
   20138: ebffb171     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x13a3c
   2013c: e51b2018     	ldr	r2, [r11, #-0x18]
   20140: e59f3390     	ldr	r3, [pc, #0x390]        @ 0x204d8 <scarletbook_print_area_toc+0x4e0>
   20144: e7923003     	ldr	r3, [r2, r3]
   20148: e3530000     	cmp	r3, #0
   2014c: 0a00000d     	beq	0x20188 <scarletbook_print_area_toc+0x190> @ imm = #0x34
   20150: e59f3364     	ldr	r3, [pc, #0x364]        @ 0x204bc <scarletbook_print_area_toc+0x4c4>
   20154: e5933000     	ldr	r3, [r3]
   20158: e1a05003     	mov	r5, r3
   2015c: e59f4378     	ldr	r4, [pc, #0x378]        @ 0x204dc <scarletbook_print_area_toc+0x4e4>
   20160: e51b2018     	ldr	r2, [r11, #-0x18]
   20164: e59f336c     	ldr	r3, [pc, #0x36c]        @ 0x204d8 <scarletbook_print_area_toc+0x4e0>
   20168: e7923003     	ldr	r3, [r2, r3]
   2016c: e1a00003     	mov	r0, r3
   20170: ebfffc12     	bl	0x1f1c0 <ucs>           @ imm = #-0xfb8
   20174: e1a03000     	mov	r3, r0
   20178: e1a00005     	mov	r0, r5
   2017c: e1a01004     	mov	r1, r4
   20180: e1a02003     	mov	r2, r3
   20184: ebffb15e     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x13a88
   20188: e51b2018     	ldr	r2, [r11, #-0x18]
   2018c: e59f334c     	ldr	r3, [pc, #0x34c]        @ 0x204e0 <scarletbook_print_area_toc+0x4e8>
   20190: e7923003     	ldr	r3, [r2, r3]
   20194: e3530000     	cmp	r3, #0
   20198: 0a00000d     	beq	0x201d4 <scarletbook_print_area_toc+0x1dc> @ imm = #0x34
   2019c: e59f3318     	ldr	r3, [pc, #0x318]        @ 0x204bc <scarletbook_print_area_toc+0x4c4>
   201a0: e5933000     	ldr	r3, [r3]
   201a4: e1a05003     	mov	r5, r3
   201a8: e59f4334     	ldr	r4, [pc, #0x334]        @ 0x204e4 <scarletbook_print_area_toc+0x4ec>
   201ac: e51b2018     	ldr	r2, [r11, #-0x18]
   201b0: e59f3328     	ldr	r3, [pc, #0x328]        @ 0x204e0 <scarletbook_print_area_toc+0x4e8>
   201b4: e7923003     	ldr	r3, [r2, r3]
   201b8: e1a00003     	mov	r0, r3
   201bc: ebfffbff     	bl	0x1f1c0 <ucs>           @ imm = #-0x1004
   201c0: e1a03000     	mov	r3, r0
   201c4: e1a00005     	mov	r0, r5
   201c8: e1a01004     	mov	r1, r4
   201cc: e1a02003     	mov	r2, r3
   201d0: ebffb14b     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x13ad4
   201d4: e59f32e0     	ldr	r3, [pc, #0x2e0]        @ 0x204bc <scarletbook_print_area_toc+0x4c4>
   201d8: e5933000     	ldr	r3, [r3]
   201dc: e1a01003     	mov	r1, r3
   201e0: e59f2300     	ldr	r2, [pc, #0x300]        @ 0x204e8 <scarletbook_print_area_toc+0x4f0>
   201e4: e51b3014     	ldr	r3, [r11, #-0x14]
   201e8: e5d33045     	ldrb	r3, [r3, #0x45]
   201ec: e1a00001     	mov	r0, r1
   201f0: e1a01002     	mov	r1, r2
   201f4: e1a02003     	mov	r2, r3
   201f8: ebffb141     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x13afc
   201fc: e59f32b8     	ldr	r3, [pc, #0x2b8]        @ 0x204bc <scarletbook_print_area_toc+0x4c4>
   20200: e5933000     	ldr	r3, [r3]
   20204: e1a02003     	mov	r2, r3
   20208: e59f32dc     	ldr	r3, [pc, #0x2dc]        @ 0x204ec <scarletbook_print_area_toc+0x4f4>
   2020c: e1a00002     	mov	r0, r2
   20210: e1a01003     	mov	r1, r3
   20214: ebffb13a     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x13b18
   20218: e51b3014     	ldr	r3, [r11, #-0x14]
   2021c: e5d33020     	ldrb	r3, [r3, #0x20]
   20220: e3530002     	cmp	r3, #2
   20224: 1a00000c     	bne	0x2025c <scarletbook_print_area_toc+0x264> @ imm = #0x30
   20228: e51b3014     	ldr	r3, [r11, #-0x14]
   2022c: e5d33021     	ldrb	r3, [r3, #0x21]
   20230: e2033007     	and	r3, r3, #7
   20234: e3530000     	cmp	r3, #0
   20238: 1a000007     	bne	0x2025c <scarletbook_print_area_toc+0x264> @ imm = #0x1c
   2023c: e59f3278     	ldr	r3, [pc, #0x278]        @ 0x204bc <scarletbook_print_area_toc+0x4c4>
   20240: e5933000     	ldr	r3, [r3]
   20244: e1a02003     	mov	r2, r3
   20248: e59f32a0     	ldr	r3, [pc, #0x2a0]        @ 0x204f0 <scarletbook_print_area_toc+0x4f8>
   2024c: e1a00002     	mov	r0, r2
   20250: e1a01003     	mov	r1, r3
   20254: ebffb12a     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x13b58
   20258: ea000028     	b	0x20300 <scarletbook_print_area_toc+0x308> @ imm = #0xa0
   2025c: e51b3014     	ldr	r3, [r11, #-0x14]
   20260: e5d33020     	ldrb	r3, [r3, #0x20]
   20264: e3530005     	cmp	r3, #5
   20268: 1a00000c     	bne	0x202a0 <scarletbook_print_area_toc+0x2a8> @ imm = #0x30
   2026c: e51b3014     	ldr	r3, [r11, #-0x14]
   20270: e5d33021     	ldrb	r3, [r3, #0x21]
   20274: e2033007     	and	r3, r3, #7
   20278: e3530003     	cmp	r3, #3
   2027c: 1a000007     	bne	0x202a0 <scarletbook_print_area_toc+0x2a8> @ imm = #0x1c
   20280: e59f3234     	ldr	r3, [pc, #0x234]        @ 0x204bc <scarletbook_print_area_toc+0x4c4>
   20284: e5933000     	ldr	r3, [r3]
   20288: e1a02003     	mov	r2, r3
   2028c: e59f3260     	ldr	r3, [pc, #0x260]        @ 0x204f4 <scarletbook_print_area_toc+0x4fc>
   20290: e1a00002     	mov	r0, r2
   20294: e1a01003     	mov	r1, r3
   20298: ebffb119     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x13b9c
   2029c: ea000017     	b	0x20300 <scarletbook_print_area_toc+0x308> @ imm = #0x5c
   202a0: e51b3014     	ldr	r3, [r11, #-0x14]
   202a4: e5d33020     	ldrb	r3, [r3, #0x20]
   202a8: e3530006     	cmp	r3, #6
   202ac: 1a00000c     	bne	0x202e4 <scarletbook_print_area_toc+0x2ec> @ imm = #0x30
   202b0: e51b3014     	ldr	r3, [r11, #-0x14]
   202b4: e5d33021     	ldrb	r3, [r3, #0x21]
   202b8: e2033007     	and	r3, r3, #7
   202bc: e3530004     	cmp	r3, #4
   202c0: 1a000007     	bne	0x202e4 <scarletbook_print_area_toc+0x2ec> @ imm = #0x1c
   202c4: e59f31f0     	ldr	r3, [pc, #0x1f0]        @ 0x204bc <scarletbook_print_area_toc+0x4c4>
   202c8: e5933000     	ldr	r3, [r3]
   202cc: e1a02003     	mov	r2, r3
   202d0: e59f3220     	ldr	r3, [pc, #0x220]        @ 0x204f8 <scarletbook_print_area_toc+0x500>
   202d4: e1a00002     	mov	r0, r2
   202d8: e1a01003     	mov	r1, r3
   202dc: ebffb108     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x13be0
   202e0: ea000006     	b	0x20300 <scarletbook_print_area_toc+0x308> @ imm = #0x18
   202e4: e59f31d0     	ldr	r3, [pc, #0x1d0]        @ 0x204bc <scarletbook_print_area_toc+0x4c4>
   202e8: e5933000     	ldr	r3, [r3]
   202ec: e1a02003     	mov	r2, r3
   202f0: e59f3204     	ldr	r3, [pc, #0x204]        @ 0x204fc <scarletbook_print_area_toc+0x504>
   202f4: e1a00002     	mov	r0, r2
   202f8: e1a01003     	mov	r1, r3
   202fc: ebffb100     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x13c00
   20300: e51b0030     	ldr	r0, [r11, #-0x30]
   20304: e51b1034     	ldr	r1, [r11, #-0x34]
   20308: ebfffe07     	bl	0x1fb2c <scarletbook_print_area_text> @ imm = #-0x7e4
   2030c: e3a03000     	mov	r3, #0
   20310: e50b3028     	str	r3, [r11, #-0x28]
   20314: ea00005e     	b	0x20494 <scarletbook_print_area_toc+0x49c> @ imm = #0x178
   20318: e51b3024     	ldr	r3, [r11, #-0x24]
   2031c: e2831008     	add	r1, r3, #8
   20320: e51b2028     	ldr	r2, [r11, #-0x28]
   20324: e1a03002     	mov	r3, r2
   20328: e1a03083     	lsl	r3, r3, #1
   2032c: e0833002     	add	r3, r3, r2
   20330: e1a03103     	lsl	r3, r3, #2
   20334: e0813003     	add	r3, r1, r3
   20338: e50b3010     	str	r3, [r11, #-0x10]
   2033c: e51b3010     	ldr	r3, [r11, #-0x10]
   20340: e5d33000     	ldrb	r3, [r3]
   20344: e3530000     	cmp	r3, #0
   20348: 0a00004e     	beq	0x20488 <scarletbook_print_area_toc+0x490> @ imm = #0x138
   2034c: e59f3168     	ldr	r3, [pc, #0x168]        @ 0x204bc <scarletbook_print_area_toc+0x4c4>
   20350: e5933000     	ldr	r3, [r3]
   20354: e1a02003     	mov	r2, r3
   20358: e59f31a0     	ldr	r3, [pc, #0x1a0]        @ 0x20500 <scarletbook_print_area_toc+0x508>
   2035c: e1a00002     	mov	r0, r2
   20360: e1a01003     	mov	r1, r3
   20364: e51b2028     	ldr	r2, [r11, #-0x28]
   20368: ebffb0e5     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x13c6c
   2036c: e59f3148     	ldr	r3, [pc, #0x148]        @ 0x204bc <scarletbook_print_area_toc+0x4c4>
   20370: e5933000     	ldr	r3, [r3]
   20374: e1a05003     	mov	r5, r3
   20378: e59f4184     	ldr	r4, [pc, #0x184]        @ 0x20504 <scarletbook_print_area_toc+0x50c>
   2037c: e51b3010     	ldr	r3, [r11, #-0x10]
   20380: e1a00003     	mov	r0, r3
   20384: e3a01000     	mov	r1, #0
   20388: e3a02002     	mov	r2, #2
   2038c: ebffcd87     	bl	0x139b0 <substr>        @ imm = #-0xc9e4
   20390: e1a03000     	mov	r3, r0
   20394: e1a00003     	mov	r0, r3
   20398: ebfffb88     	bl	0x1f1c0 <ucs>           @ imm = #-0x11e0
   2039c: e1a03000     	mov	r3, r0
   203a0: e1a00005     	mov	r0, r5
   203a4: e1a01004     	mov	r1, r4
   203a8: e1a02003     	mov	r2, r3
   203ac: ebffb0d4     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x13cb0
   203b0: e59f3104     	ldr	r3, [pc, #0x104]        @ 0x204bc <scarletbook_print_area_toc+0x4c4>
   203b4: e5933000     	ldr	r3, [r3]
   203b8: e1a05003     	mov	r5, r3
   203bc: e59f4144     	ldr	r4, [pc, #0x144]        @ 0x20508 <scarletbook_print_area_toc+0x510>
   203c0: e51b3010     	ldr	r3, [r11, #-0x10]
   203c4: e2833002     	add	r3, r3, #2
   203c8: e1a00003     	mov	r0, r3
   203cc: e3a01000     	mov	r1, #0
   203d0: e3a02003     	mov	r2, #3
   203d4: ebffcd75     	bl	0x139b0 <substr>        @ imm = #-0xca2c
   203d8: e1a03000     	mov	r3, r0
   203dc: e1a00003     	mov	r0, r3
   203e0: ebfffb76     	bl	0x1f1c0 <ucs>           @ imm = #-0x1228
   203e4: e1a03000     	mov	r3, r0
   203e8: e1a00005     	mov	r0, r5
   203ec: e1a01004     	mov	r1, r4
   203f0: e1a02003     	mov	r2, r3
   203f4: ebffb0c2     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x13cf8
   203f8: e59f30bc     	ldr	r3, [pc, #0xbc]         @ 0x204bc <scarletbook_print_area_toc+0x4c4>
   203fc: e5933000     	ldr	r3, [r3]
   20400: e1a05003     	mov	r5, r3
   20404: e59f4100     	ldr	r4, [pc, #0x100]        @ 0x2050c <scarletbook_print_area_toc+0x514>
   20408: e51b3010     	ldr	r3, [r11, #-0x10]
   2040c: e2833005     	add	r3, r3, #5
   20410: e1a00003     	mov	r0, r3
   20414: e3a01000     	mov	r1, #0
   20418: e3a02002     	mov	r2, #2
   2041c: ebffcd63     	bl	0x139b0 <substr>        @ imm = #-0xca74
   20420: e1a03000     	mov	r3, r0
   20424: e1a00003     	mov	r0, r3
   20428: ebfffb64     	bl	0x1f1c0 <ucs>           @ imm = #-0x1270
   2042c: e1a03000     	mov	r3, r0
   20430: e1a00005     	mov	r0, r5
   20434: e1a01004     	mov	r1, r4
   20438: e1a02003     	mov	r2, r3
   2043c: ebffb0b0     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x13d40
   20440: e59f3074     	ldr	r3, [pc, #0x74]         @ 0x204bc <scarletbook_print_area_toc+0x4c4>
   20444: e5933000     	ldr	r3, [r3]
   20448: e1a05003     	mov	r5, r3
   2044c: e59f40bc     	ldr	r4, [pc, #0xbc]         @ 0x20510 <scarletbook_print_area_toc+0x518>
   20450: e51b3010     	ldr	r3, [r11, #-0x10]
   20454: e2833007     	add	r3, r3, #7
   20458: e1a00003     	mov	r0, r3
   2045c: e3a01000     	mov	r1, #0
   20460: e3a02005     	mov	r2, #5
   20464: ebffcd51     	bl	0x139b0 <substr>        @ imm = #-0xcabc
   20468: e1a03000     	mov	r3, r0
   2046c: e1a00003     	mov	r0, r3
   20470: ebfffb52     	bl	0x1f1c0 <ucs>           @ imm = #-0x12b8
   20474: e1a03000     	mov	r3, r0
   20478: e1a00005     	mov	r0, r5
   2047c: e1a01004     	mov	r1, r4
   20480: e1a02003     	mov	r2, r3
   20484: ebffb09e     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x13d88
   20488: e51b3028     	ldr	r3, [r11, #-0x28]
   2048c: e2833001     	add	r3, r3, #1
   20490: e50b3028     	str	r3, [r11, #-0x28]
   20494: e51b3014     	ldr	r3, [r11, #-0x14]
   20498: e5d33045     	ldrb	r3, [r3, #0x45]
   2049c: e1a02003     	mov	r2, r3
   204a0: e51b3028     	ldr	r3, [r11, #-0x28]
   204a4: e1520003     	cmp	r2, r3
   204a8: caffff9a     	bgt	0x20318 <scarletbook_print_area_toc+0x320> @ imm = #-0x198
   204ac: e24bd00c     	sub	sp, r11, #12
   204b0: e8bd8830     	pop	{r4, r5, r11, pc}
   204b4: f0 37 00 00  	.word	0x000037f0
   204b8: dc 37 00 00  	.word	0x000037dc
   204bc: f4 6d 05 00  	.word	0x00056df4
   204c0: 40 45 03 00  	.word	0x00034540
   204c4: bc 3c 03 00  	.word	0x00033cbc
   204c8: e4 37 00 00  	.word	0x000037e4
   204cc: c0 3b 03 00  	.word	0x00033bc0
   204d0: ec 37 00 00  	.word	0x000037ec
   204d4: 04 3c 03 00  	.word	0x00033c04
   204d8: e0 37 00 00  	.word	0x000037e0
   204dc: a8 45 03 00  	.word	0x000345a8
   204e0: e8 37 00 00  	.word	0x000037e8
   204e4: 08 46 03 00  	.word	0x00034608
   204e8: 8c 46 03 00  	.word	0x0003468c
   204ec: d4 46 03 00  	.word	0x000346d4
   204f0: 1c 47 03 00  	.word	0x0003471c
   204f4: 48 47 03 00  	.word	0x00034748
   204f8: 74 47 03 00  	.word	0x00034774
   204fc: a0 47 03 00  	.word	0x000347a0
   20500: c4 47 03 00  	.word	0x000347c4
   20504: 1c 48 03 00  	.word	0x0003481c
   20508: 58 48 03 00  	.word	0x00034858
   2050c: 8c 48 03 00  	.word	0x0003488c
   20510: bc 48 03 00  	.word	0x000348bc

