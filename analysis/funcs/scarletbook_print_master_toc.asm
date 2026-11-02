0001f774 <scarletbook_print_master_toc>:
   1f774: e92d4830     	push	{r4, r5, r11, lr}
   1f778: e28db00c     	add	r11, sp, #12
   1f77c: e24dd038     	sub	sp, sp, #56
   1f780: e50b0038     	str	r0, [r11, #-0x38]
   1f784: e51b3038     	ldr	r3, [r11, #-0x38]
   1f788: e5933008     	ldr	r3, [r3, #0x8]
   1f78c: e50b3018     	str	r3, [r11, #-0x18]
   1f790: e59f3364     	ldr	r3, [pc, #0x364]        @ 0x1fafc <scarletbook_print_master_toc+0x388>
   1f794: e5933000     	ldr	r3, [r3]
   1f798: e1a02003     	mov	r2, r3
   1f79c: e59f335c     	ldr	r3, [pc, #0x35c]        @ 0x1fb00 <scarletbook_print_master_toc+0x38c>
   1f7a0: e1a00002     	mov	r0, r2
   1f7a4: e1a01003     	mov	r1, r3
   1f7a8: ebffb3d5     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x130ac
   1f7ac: e59f3348     	ldr	r3, [pc, #0x348]        @ 0x1fafc <scarletbook_print_master_toc+0x388>
   1f7b0: e5933000     	ldr	r3, [r3]
   1f7b4: e1a00003     	mov	r0, r3
   1f7b8: e59f1344     	ldr	r1, [pc, #0x344]        @ 0x1fb04 <scarletbook_print_master_toc+0x390>
   1f7bc: e51b3018     	ldr	r3, [r11, #-0x18]
   1f7c0: e5d33008     	ldrb	r3, [r3, #0x8]
   1f7c4: e1a02003     	mov	r2, r3
   1f7c8: e51b3018     	ldr	r3, [r11, #-0x18]
   1f7cc: e5d33009     	ldrb	r3, [r3, #0x9]
   1f7d0: ebffb3cb     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x130d4
   1f7d4: e59f3320     	ldr	r3, [pc, #0x320]        @ 0x1fafc <scarletbook_print_master_toc+0x388>
   1f7d8: e5933000     	ldr	r3, [r3]
   1f7dc: e1a00003     	mov	r0, r3
   1f7e0: e59f1320     	ldr	r1, [pc, #0x320]        @ 0x1fb08 <scarletbook_print_master_toc+0x394>
   1f7e4: e51b3018     	ldr	r3, [r11, #-0x18]
   1f7e8: e5d32078     	ldrb	r2, [r3, #0x78]
   1f7ec: e5d33079     	ldrb	r3, [r3, #0x79]
   1f7f0: e1a03403     	lsl	r3, r3, #8
   1f7f4: e1833002     	orr	r3, r3, r2
   1f7f8: e6ff3073     	uxth	r3, r3
   1f7fc: e1a02003     	mov	r2, r3
   1f800: e51b3018     	ldr	r3, [r11, #-0x18]
   1f804: e5d3307a     	ldrb	r3, [r3, #0x7a]
   1f808: e51bc018     	ldr	r12, [r11, #-0x18]
   1f80c: e5dcc07b     	ldrb	r12, [r12, #0x7b]
   1f810: e58dc000     	str	r12, [sp]
   1f814: ebffb3ba     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x13118
   1f818: e51b3018     	ldr	r3, [r11, #-0x18]
   1f81c: e2833058     	add	r3, r3, #88
   1f820: e24b2030     	sub	r2, r11, #48
   1f824: e1a00002     	mov	r0, r2
   1f828: e1a01003     	mov	r1, r3
   1f82c: e3a02010     	mov	r2, #16
   1f830: ebffb2a8     	bl	0xc2d8 <strncpy@plt>    @ imm = #-0x13560
   1f834: e3a03000     	mov	r3, #0
   1f838: e54b3020     	strb	r3, [r11, #-0x20]
   1f83c: e59f32b8     	ldr	r3, [pc, #0x2b8]        @ 0x1fafc <scarletbook_print_master_toc+0x388>
   1f840: e5933000     	ldr	r3, [r3]
   1f844: e1a05003     	mov	r5, r3
   1f848: e59f42bc     	ldr	r4, [pc, #0x2bc]        @ 0x1fb0c <scarletbook_print_master_toc+0x398>
   1f84c: e24b3030     	sub	r3, r11, #48
   1f850: e1a00003     	mov	r0, r3
   1f854: ebfffe59     	bl	0x1f1c0 <ucs>           @ imm = #-0x69c
   1f858: e1a03000     	mov	r3, r0
   1f85c: e1a00005     	mov	r0, r5
   1f860: e1a01004     	mov	r1, r4
   1f864: e1a02003     	mov	r2, r3
   1f868: ebffb3a5     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x1316c
   1f86c: e3a03000     	mov	r3, #0
   1f870: e50b301c     	str	r3, [r11, #-0x1c]
   1f874: ea00002c     	b	0x1f92c <scarletbook_print_master_toc+0x1b8> @ imm = #0xb0
   1f878: e51b3018     	ldr	r3, [r11, #-0x18]
   1f87c: e2832068     	add	r2, r3, #104
   1f880: e51b301c     	ldr	r3, [r11, #-0x1c]
   1f884: e1a03103     	lsl	r3, r3, #2
   1f888: e0823003     	add	r3, r2, r3
   1f88c: e50b3014     	str	r3, [r11, #-0x14]
   1f890: e51b3014     	ldr	r3, [r11, #-0x14]
   1f894: e5d33000     	ldrb	r3, [r3]
   1f898: e3530000     	cmp	r3, #0
   1f89c: 0a00001f     	beq	0x1f920 <scarletbook_print_master_toc+0x1ac> @ imm = #0x7c
   1f8a0: e59f3254     	ldr	r3, [pc, #0x254]        @ 0x1fafc <scarletbook_print_master_toc+0x388>
   1f8a4: e5933000     	ldr	r3, [r3]
   1f8a8: e1a05003     	mov	r5, r3
   1f8ac: e59f425c     	ldr	r4, [pc, #0x25c]        @ 0x1fb10 <scarletbook_print_master_toc+0x39c>
   1f8b0: e51b3014     	ldr	r3, [r11, #-0x14]
   1f8b4: e5d33000     	ldrb	r3, [r3]
   1f8b8: e1a02003     	mov	r2, r3
   1f8bc: e59f3250     	ldr	r3, [pc, #0x250]        @ 0x1fb14 <scarletbook_print_master_toc+0x3a0>
   1f8c0: e7933102     	ldr	r3, [r3, r2, lsl #2]
   1f8c4: e1a00003     	mov	r0, r3
   1f8c8: ebfffe3c     	bl	0x1f1c0 <ucs>           @ imm = #-0x710
   1f8cc: e1a03000     	mov	r3, r0
   1f8d0: e1a00005     	mov	r0, r5
   1f8d4: e1a01004     	mov	r1, r4
   1f8d8: e1a02003     	mov	r2, r3
   1f8dc: ebffb388     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x131e0
   1f8e0: e59f3214     	ldr	r3, [pc, #0x214]        @ 0x1fafc <scarletbook_print_master_toc+0x388>
   1f8e4: e5933000     	ldr	r3, [r3]
   1f8e8: e1a05003     	mov	r5, r3
   1f8ec: e59f4224     	ldr	r4, [pc, #0x224]        @ 0x1fb18 <scarletbook_print_master_toc+0x3a4>
   1f8f0: e51b3014     	ldr	r3, [r11, #-0x14]
   1f8f4: e5d33003     	ldrb	r3, [r3, #0x3]
   1f8f8: e1a02003     	mov	r2, r3
   1f8fc: e59f3218     	ldr	r3, [pc, #0x218]        @ 0x1fb1c <scarletbook_print_master_toc+0x3a8>
   1f900: e7933102     	ldr	r3, [r3, r2, lsl #2]
   1f904: e1a00003     	mov	r0, r3
   1f908: ebfffe2c     	bl	0x1f1c0 <ucs>           @ imm = #-0x750
   1f90c: e1a03000     	mov	r3, r0
   1f910: e1a00005     	mov	r0, r5
   1f914: e1a01004     	mov	r1, r4
   1f918: e1a02003     	mov	r2, r3
   1f91c: ebffb378     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x13220
   1f920: e51b301c     	ldr	r3, [r11, #-0x1c]
   1f924: e2833001     	add	r3, r3, #1
   1f928: e50b301c     	str	r3, [r11, #-0x1c]
   1f92c: e51b301c     	ldr	r3, [r11, #-0x1c]
   1f930: e3530003     	cmp	r3, #3
   1f934: daffffcf     	ble	0x1f878 <scarletbook_print_master_toc+0x104> @ imm = #-0xc4
   1f938: e51b0038     	ldr	r0, [r11, #-0x38]
   1f93c: ebfffee4     	bl	0x1f4d4 <scarletbook_print_disc_text> @ imm = #-0x470
   1f940: e59f31b4     	ldr	r3, [pc, #0x1b4]        @ 0x1fafc <scarletbook_print_master_toc+0x388>
   1f944: e5933000     	ldr	r3, [r3]
   1f948: e1a02003     	mov	r2, r3
   1f94c: e59f31cc     	ldr	r3, [pc, #0x1cc]        @ 0x1fb20 <scarletbook_print_master_toc+0x3ac>
   1f950: e1a00002     	mov	r0, r2
   1f954: e1a01003     	mov	r1, r3
   1f958: ebffb369     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x1325c
   1f95c: e51b3018     	ldr	r3, [r11, #-0x18]
   1f960: e2833018     	add	r3, r3, #24
   1f964: e24b2030     	sub	r2, r11, #48
   1f968: e1a00002     	mov	r0, r2
   1f96c: e1a01003     	mov	r1, r3
   1f970: e3a02010     	mov	r2, #16
   1f974: ebffb257     	bl	0xc2d8 <strncpy@plt>    @ imm = #-0x136a4
   1f978: e3a03000     	mov	r3, #0
   1f97c: e54b3020     	strb	r3, [r11, #-0x20]
   1f980: e59f3174     	ldr	r3, [pc, #0x174]        @ 0x1fafc <scarletbook_print_master_toc+0x388>
   1f984: e5933000     	ldr	r3, [r3]
   1f988: e1a05003     	mov	r5, r3
   1f98c: e59f4178     	ldr	r4, [pc, #0x178]        @ 0x1fb0c <scarletbook_print_master_toc+0x398>
   1f990: e24b3030     	sub	r3, r11, #48
   1f994: e1a00003     	mov	r0, r3
   1f998: ebfffe08     	bl	0x1f1c0 <ucs>           @ imm = #-0x7e0
   1f99c: e1a03000     	mov	r3, r0
   1f9a0: e1a00005     	mov	r0, r5
   1f9a4: e1a01004     	mov	r1, r4
   1f9a8: e1a02003     	mov	r2, r3
   1f9ac: ebffb354     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x132b0
   1f9b0: e59f3144     	ldr	r3, [pc, #0x144]        @ 0x1fafc <scarletbook_print_master_toc+0x388>
   1f9b4: e5933000     	ldr	r3, [r3]
   1f9b8: e1a01003     	mov	r1, r3
   1f9bc: e59f2160     	ldr	r2, [pc, #0x160]        @ 0x1fb24 <scarletbook_print_master_toc+0x3b0>
   1f9c0: e51b3018     	ldr	r3, [r11, #-0x18]
   1f9c4: e5d30012     	ldrb	r0, [r3, #0x12]
   1f9c8: e5d33013     	ldrb	r3, [r3, #0x13]
   1f9cc: e1a03403     	lsl	r3, r3, #8
   1f9d0: e1833000     	orr	r3, r3, r0
   1f9d4: e6ff3073     	uxth	r3, r3
   1f9d8: e1a00001     	mov	r0, r1
   1f9dc: e1a01002     	mov	r1, r2
   1f9e0: e1a02003     	mov	r2, r3
   1f9e4: ebffb346     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x132e8
   1f9e8: e59f310c     	ldr	r3, [pc, #0x10c]        @ 0x1fafc <scarletbook_print_master_toc+0x388>
   1f9ec: e5933000     	ldr	r3, [r3]
   1f9f0: e1a01003     	mov	r1, r3
   1f9f4: e59f212c     	ldr	r2, [pc, #0x12c]        @ 0x1fb28 <scarletbook_print_master_toc+0x3b4>
   1f9f8: e51b3018     	ldr	r3, [r11, #-0x18]
   1f9fc: e5d30010     	ldrb	r0, [r3, #0x10]
   1fa00: e5d33011     	ldrb	r3, [r3, #0x11]
   1fa04: e1a03403     	lsl	r3, r3, #8
   1fa08: e1833000     	orr	r3, r3, r0
   1fa0c: e6ff3073     	uxth	r3, r3
   1fa10: e1a00001     	mov	r0, r1
   1fa14: e1a01002     	mov	r1, r2
   1fa18: e1a02003     	mov	r2, r3
   1fa1c: ebffb338     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x13320
   1fa20: e3a03000     	mov	r3, #0
   1fa24: e50b301c     	str	r3, [r11, #-0x1c]
   1fa28: ea00002c     	b	0x1fae0 <scarletbook_print_master_toc+0x36c> @ imm = #0xb0
   1fa2c: e51b3018     	ldr	r3, [r11, #-0x18]
   1fa30: e2832028     	add	r2, r3, #40
   1fa34: e51b301c     	ldr	r3, [r11, #-0x1c]
   1fa38: e1a03103     	lsl	r3, r3, #2
   1fa3c: e0823003     	add	r3, r2, r3
   1fa40: e50b3010     	str	r3, [r11, #-0x10]
   1fa44: e51b3010     	ldr	r3, [r11, #-0x10]
   1fa48: e5d33000     	ldrb	r3, [r3]
   1fa4c: e3530000     	cmp	r3, #0
   1fa50: 0a00001f     	beq	0x1fad4 <scarletbook_print_master_toc+0x360> @ imm = #0x7c
   1fa54: e59f30a0     	ldr	r3, [pc, #0xa0]         @ 0x1fafc <scarletbook_print_master_toc+0x388>
   1fa58: e5933000     	ldr	r3, [r3]
   1fa5c: e1a05003     	mov	r5, r3
   1fa60: e59f40a8     	ldr	r4, [pc, #0xa8]         @ 0x1fb10 <scarletbook_print_master_toc+0x39c>
   1fa64: e51b3010     	ldr	r3, [r11, #-0x10]
   1fa68: e5d33000     	ldrb	r3, [r3]
   1fa6c: e1a02003     	mov	r2, r3
   1fa70: e59f309c     	ldr	r3, [pc, #0x9c]         @ 0x1fb14 <scarletbook_print_master_toc+0x3a0>
   1fa74: e7933102     	ldr	r3, [r3, r2, lsl #2]
   1fa78: e1a00003     	mov	r0, r3
   1fa7c: ebfffdcf     	bl	0x1f1c0 <ucs>           @ imm = #-0x8c4
   1fa80: e1a03000     	mov	r3, r0
   1fa84: e1a00005     	mov	r0, r5
   1fa88: e1a01004     	mov	r1, r4
   1fa8c: e1a02003     	mov	r2, r3
   1fa90: ebffb31b     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x13394
   1fa94: e59f3060     	ldr	r3, [pc, #0x60]         @ 0x1fafc <scarletbook_print_master_toc+0x388>
   1fa98: e5933000     	ldr	r3, [r3]
   1fa9c: e1a05003     	mov	r5, r3
   1faa0: e59f4070     	ldr	r4, [pc, #0x70]         @ 0x1fb18 <scarletbook_print_master_toc+0x3a4>
   1faa4: e51b3010     	ldr	r3, [r11, #-0x10]
   1faa8: e5d33003     	ldrb	r3, [r3, #0x3]
   1faac: e1a02003     	mov	r2, r3
   1fab0: e59f3064     	ldr	r3, [pc, #0x64]         @ 0x1fb1c <scarletbook_print_master_toc+0x3a8>
   1fab4: e7933102     	ldr	r3, [r3, r2, lsl #2]
   1fab8: e1a00003     	mov	r0, r3
   1fabc: ebfffdbf     	bl	0x1f1c0 <ucs>           @ imm = #-0x904
   1fac0: e1a03000     	mov	r3, r0
   1fac4: e1a00005     	mov	r0, r5
   1fac8: e1a01004     	mov	r1, r4
   1facc: e1a02003     	mov	r2, r3
   1fad0: ebffb30b     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x133d4
   1fad4: e51b301c     	ldr	r3, [r11, #-0x1c]
   1fad8: e2833001     	add	r3, r3, #1
   1fadc: e50b301c     	str	r3, [r11, #-0x1c]
   1fae0: e51b301c     	ldr	r3, [r11, #-0x1c]
   1fae4: e3530003     	cmp	r3, #3
   1fae8: daffffcf     	ble	0x1fa2c <scarletbook_print_master_toc+0x2b8> @ imm = #-0xc4
   1faec: e51b0038     	ldr	r0, [r11, #-0x38]
   1faf0: ebfffdcf     	bl	0x1f234 <scarletbook_print_album_text> @ imm = #-0x8c4
   1faf4: e24bd00c     	sub	sp, r11, #12
   1faf8: e8bd8830     	pop	{r4, r5, r11, pc}
   1fafc: f4 6d 05 00  	.word	0x00056df4
   1fb00: 6c 3c 03 00  	.word	0x00033c6c
   1fb04: bc 3c 03 00  	.word	0x00033cbc
   1fb08: 0c 3d 03 00  	.word	0x00033d0c
   1fb0c: 88 3d 03 00  	.word	0x00033d88
   1fb10: e0 3d 03 00  	.word	0x00033de0
   1fb14: d0 ef 03 00  	.word	0x0003efd0
   1fb18: 20 3e 03 00  	.word	0x00033e20
   1fb1c: 58 ef 03 00  	.word	0x0003ef58
   1fb20: 54 3e 03 00  	.word	0x00033e54
   1fb24: ac 3e 03 00  	.word	0x00033eac
   1fb28: 04 3f 03 00  	.word	0x00033f04

