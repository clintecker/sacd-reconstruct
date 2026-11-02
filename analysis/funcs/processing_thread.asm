000284b8 <processing_thread>:
   284b8: e92d4800     	push	{r11, lr}
   284bc: e28db004     	add	r11, sp, #4
   284c0: e24dd048     	sub	sp, sp, #72
   284c4: e50b0040     	str	r0, [r11, #-0x40]
   284c8: e51b3040     	ldr	r3, [r11, #-0x40]
   284cc: e50b303c     	str	r3, [r11, #-0x3c]
   284d0: e51b303c     	ldr	r3, [r11, #-0x3c]
   284d4: e593303c     	ldr	r3, [r3, #0x3c]
   284d8: e50b3038     	str	r3, [r11, #-0x38]
   284dc: e3a03000     	mov	r3, #0
   284e0: e50b302c     	str	r3, [r11, #-0x2c]
   284e4: e3a03000     	mov	r3, #0
   284e8: e50b3028     	str	r3, [r11, #-0x28]
   284ec: e51b303c     	ldr	r3, [r11, #-0x3c]
   284f0: e3a02001     	mov	r2, #1
   284f4: e5832014     	str	r2, [r3, #0x14]
   284f8: ea0001bb     	b	0x28bec <processing_thread+0x734> @ imm = #0x6ec
   284fc: e51b303c     	ldr	r3, [r11, #-0x3c]
   28500: e5933000     	ldr	r3, [r3]
   28504: e50b3034     	str	r3, [r11, #-0x34]
   28508: e51b3034     	ldr	r3, [r11, #-0x34]
   2850c: e2433e17     	sub	r3, r3, #368
   28510: e50b3030     	str	r3, [r11, #-0x30]
   28514: e51b0034     	ldr	r0, [r11, #-0x34]
   28518: ebfffcd6     	bl	0x27878 <list_del>      @ imm = #-0xca8
   2851c: e51b3030     	ldr	r3, [r11, #-0x30]
   28520: e593303c     	ldr	r3, [r3, #0x3c]
   28524: e3530000     	cmp	r3, #0
   28528: 0a00000d     	beq	0x28564 <processing_thread+0xac> @ imm = #0x34
   2852c: e51b3030     	ldr	r3, [r11, #-0x30]
   28530: e5933038     	ldr	r3, [r3, #0x38]
   28534: e3530000     	cmp	r3, #0
   28538: 0a000009     	beq	0x28564 <processing_thread+0xac> @ imm = #0x24
   2853c: e51b3030     	ldr	r3, [r11, #-0x30]
   28540: e5933018     	ldr	r3, [r3, #0x18]
   28544: e1a00003     	mov	r0, r3
   28548: e59f16d0     	ldr	r1, [pc, #0x6d0]        @ 0x28c20 <processing_thread+0x768>
   2854c: e59f26d0     	ldr	r2, [pc, #0x6d0]        @ 0x28c24 <processing_thread+0x76c>
   28550: e51b3030     	ldr	r3, [r11, #-0x30]
   28554: ebffcb60     	bl	0x1b2dc <dst_decoder_create> @ imm = #-0xd280
   28558: e1a02000     	mov	r2, r0
   2855c: e51b3030     	ldr	r3, [r11, #-0x30]
   28560: e5832164     	str	r2, [r3, #0x164]
   28564: e51b3030     	ldr	r3, [r11, #-0x30]
   28568: e593200c     	ldr	r2, [r3, #0xc]
   2856c: e51b303c     	ldr	r3, [r11, #-0x3c]
   28570: e5832028     	str	r2, [r3, #0x28]
   28574: e51b303c     	ldr	r3, [r11, #-0x3c]
   28578: e3a02000     	mov	r2, #0
   2857c: e583202c     	str	r2, [r3, #0x2c]
   28580: e51b303c     	ldr	r3, [r11, #-0x3c]
   28584: e593301c     	ldr	r3, [r3, #0x1c]
   28588: e2832001     	add	r2, r3, #1
   2858c: e51b303c     	ldr	r3, [r11, #-0x3c]
   28590: e583201c     	str	r2, [r3, #0x1c]
   28594: e51b303c     	ldr	r3, [r11, #-0x3c]
   28598: e5933034     	ldr	r3, [r3, #0x34]
   2859c: e3530000     	cmp	r3, #0
   285a0: 0a000008     	beq	0x285c8 <processing_thread+0x110> @ imm = #0x20
   285a4: e51b303c     	ldr	r3, [r11, #-0x3c]
   285a8: e5933034     	ldr	r3, [r3, #0x34]
   285ac: e51b2030     	ldr	r2, [r11, #-0x30]
   285b0: e5920014     	ldr	r0, [r2, #0x14]
   285b4: e51b203c     	ldr	r2, [r11, #-0x3c]
   285b8: e592101c     	ldr	r1, [r2, #0x1c]
   285bc: e51b203c     	ldr	r2, [r11, #-0x3c]
   285c0: e5922018     	ldr	r2, [r2, #0x18]
   285c4: e12fff33     	blx	r3
   285c8: e51b0038     	ldr	r0, [r11, #-0x38]
   285cc: eb0015c8     	bl	0x2dcf4 <scarletbook_frame_init> @ imm = #0x5720
   285d0: e51b0030     	ldr	r0, [r11, #-0x30]
   285d4: ebfffe90     	bl	0x2801c <create_output_file> @ imm = #-0x5c0
   285d8: e1a03000     	mov	r3, r0
   285dc: e3530000     	cmp	r3, #0
   285e0: 1a00013e     	bne	0x28ae0 <processing_thread+0x628> @ imm = #0x4f8
   285e4: e3a03000     	mov	r3, #0
   285e8: e50b301c     	str	r3, [r11, #-0x1c]
   285ec: e3a03000     	mov	r3, #0
   285f0: e50b3018     	str	r3, [r11, #-0x18]
   285f4: e3a03000     	mov	r3, #0
   285f8: e50b3014     	str	r3, [r11, #-0x14]
   285fc: e3a03000     	mov	r3, #0
   28600: e50b3010     	str	r3, [r11, #-0x10]
   28604: e51b3038     	ldr	r3, [r11, #-0x38]
   28608: e5933060     	ldr	r3, [r3, #0x60]
   2860c: e3530000     	cmp	r3, #0
   28610: 0a000019     	beq	0x2867c <processing_thread+0x1c4> @ imm = #0x64
   28614: e51b3038     	ldr	r3, [r11, #-0x38]
   28618: e5933060     	ldr	r3, [r3, #0x60]
   2861c: e5d32048     	ldrb	r2, [r3, #0x48]
   28620: e5d31049     	ldrb	r1, [r3, #0x49]
   28624: e1a01401     	lsl	r1, r1, #8
   28628: e1812002     	orr	r2, r1, r2
   2862c: e5d3104a     	ldrb	r1, [r3, #0x4a]
   28630: e1a01801     	lsl	r1, r1, #16
   28634: e1812002     	orr	r2, r1, r2
   28638: e5d3304b     	ldrb	r3, [r3, #0x4b]
   2863c: e1a03c03     	lsl	r3, r3, #24
   28640: e1833002     	orr	r3, r3, r2
   28644: e50b301c     	str	r3, [r11, #-0x1c]
   28648: e51b3038     	ldr	r3, [r11, #-0x38]
   2864c: e5933060     	ldr	r3, [r3, #0x60]
   28650: e5d3204c     	ldrb	r2, [r3, #0x4c]
   28654: e5d3104d     	ldrb	r1, [r3, #0x4d]
   28658: e1a01401     	lsl	r1, r1, #8
   2865c: e1812002     	orr	r2, r1, r2
   28660: e5d3104e     	ldrb	r1, [r3, #0x4e]
   28664: e1a01801     	lsl	r1, r1, #16
   28668: e1812002     	orr	r2, r1, r2
   2866c: e5d3304f     	ldrb	r3, [r3, #0x4f]
   28670: e1a03c03     	lsl	r3, r3, #24
   28674: e1833002     	orr	r3, r3, r2
   28678: e50b3014     	str	r3, [r11, #-0x14]
   2867c: e51b2038     	ldr	r2, [r11, #-0x38]
   28680: e59f35a0     	ldr	r3, [pc, #0x5a0]        @ 0x28c28 <processing_thread+0x770>
   28684: e7923003     	ldr	r3, [r2, r3]
   28688: e3530000     	cmp	r3, #0
   2868c: 0a00001b     	beq	0x28700 <processing_thread+0x248> @ imm = #0x6c
   28690: e51b2038     	ldr	r2, [r11, #-0x38]
   28694: e59f358c     	ldr	r3, [pc, #0x58c]        @ 0x28c28 <processing_thread+0x770>
   28698: e7923003     	ldr	r3, [r2, r3]
   2869c: e5d32048     	ldrb	r2, [r3, #0x48]
   286a0: e5d31049     	ldrb	r1, [r3, #0x49]
   286a4: e1a01401     	lsl	r1, r1, #8
   286a8: e1812002     	orr	r2, r1, r2
   286ac: e5d3104a     	ldrb	r1, [r3, #0x4a]
   286b0: e1a01801     	lsl	r1, r1, #16
   286b4: e1812002     	orr	r2, r1, r2
   286b8: e5d3304b     	ldrb	r3, [r3, #0x4b]
   286bc: e1a03c03     	lsl	r3, r3, #24
   286c0: e1833002     	orr	r3, r3, r2
   286c4: e50b3018     	str	r3, [r11, #-0x18]
   286c8: e51b2038     	ldr	r2, [r11, #-0x38]
   286cc: e59f3554     	ldr	r3, [pc, #0x554]        @ 0x28c28 <processing_thread+0x770>
   286d0: e7923003     	ldr	r3, [r2, r3]
   286d4: e5d3204c     	ldrb	r2, [r3, #0x4c]
   286d8: e5d3104d     	ldrb	r1, [r3, #0x4d]
   286dc: e1a01401     	lsl	r1, r1, #8
   286e0: e1812002     	orr	r2, r1, r2
   286e4: e5d3104e     	ldrb	r1, [r3, #0x4e]
   286e8: e1a01801     	lsl	r1, r1, #16
   286ec: e1812002     	orr	r2, r1, r2
   286f0: e5d3304f     	ldrb	r3, [r3, #0x4f]
   286f4: e1a03c03     	lsl	r3, r3, #24
   286f8: e1833002     	orr	r3, r3, r2
   286fc: e50b3010     	str	r3, [r11, #-0x10]
   28700: e51b3030     	ldr	r3, [r11, #-0x30]
   28704: e5932008     	ldr	r2, [r3, #0x8]
   28708: e51b3030     	ldr	r3, [r11, #-0x30]
   2870c: e5832010     	str	r2, [r3, #0x10]
   28710: e51b3030     	ldr	r3, [r11, #-0x30]
   28714: e5932008     	ldr	r2, [r3, #0x8]
   28718: e51b3030     	ldr	r3, [r11, #-0x30]
   2871c: e593300c     	ldr	r3, [r3, #0xc]
   28720: e0823003     	add	r3, r2, r3
   28724: e50b3020     	str	r3, [r11, #-0x20]
   28728: e51b303c     	ldr	r3, [r11, #-0x3c]
   2872c: e3a02000     	mov	r2, #0
   28730: e5832010     	str	r2, [r3, #0x10]
   28734: ea0000e3     	b	0x28ac8 <processing_thread+0x610> @ imm = #0x38c
   28738: e51b3030     	ldr	r3, [r11, #-0x30]
   2873c: e5932010     	ldr	r2, [r3, #0x10]
   28740: e51b3020     	ldr	r3, [r11, #-0x20]
   28744: e1520003     	cmp	r2, r3
   28748: 2a0000e3     	bhs	0x28adc <processing_thread+0x624> @ imm = #0x38c
   2874c: e51b3030     	ldr	r3, [r11, #-0x30]
   28750: e5932010     	ldr	r2, [r3, #0x10]
   28754: e51b301c     	ldr	r3, [r11, #-0x1c]
   28758: e1520003     	cmp	r2, r3
   2875c: 2a000009     	bhs	0x28788 <processing_thread+0x2d0> @ imm = #0x24
   28760: e51b3030     	ldr	r3, [r11, #-0x30]
   28764: e5933010     	ldr	r3, [r3, #0x10]
   28768: e51b201c     	ldr	r2, [r11, #-0x1c]
   2876c: e0633002     	rsb	r3, r3, r2
   28770: e3530080     	cmp	r3, #128
   28774: 23a03080     	movhs	r3, #128
   28778: e50b3024     	str	r3, [r11, #-0x24]
   2877c: e3a03000     	mov	r3, #0
   28780: e50b300c     	str	r3, [r11, #-0xc]
   28784: ea000041     	b	0x28890 <processing_thread+0x3d8> @ imm = #0x104
   28788: e51b3030     	ldr	r3, [r11, #-0x30]
   2878c: e5932010     	ldr	r2, [r3, #0x10]
   28790: e51b301c     	ldr	r3, [r11, #-0x1c]
   28794: e1520003     	cmp	r2, r3
   28798: 3a00000f     	blo	0x287dc <processing_thread+0x324> @ imm = #0x3c
   2879c: e51b3030     	ldr	r3, [r11, #-0x30]
   287a0: e5932010     	ldr	r2, [r3, #0x10]
   287a4: e51b3014     	ldr	r3, [r11, #-0x14]
   287a8: e1520003     	cmp	r2, r3
   287ac: 8a00000a     	bhi	0x287dc <processing_thread+0x324> @ imm = #0x28
   287b0: e51b3030     	ldr	r3, [r11, #-0x30]
   287b4: e5933010     	ldr	r3, [r3, #0x10]
   287b8: e51b2014     	ldr	r2, [r11, #-0x14]
   287bc: e0633002     	rsb	r3, r3, r2
   287c0: e2833001     	add	r3, r3, #1
   287c4: e3530080     	cmp	r3, #128
   287c8: 23a03080     	movhs	r3, #128
   287cc: e50b3024     	str	r3, [r11, #-0x24]
   287d0: e3a03001     	mov	r3, #1
   287d4: e50b300c     	str	r3, [r11, #-0xc]
   287d8: ea00002c     	b	0x28890 <processing_thread+0x3d8> @ imm = #0xb0
   287dc: e51b3030     	ldr	r3, [r11, #-0x30]
   287e0: e5932010     	ldr	r2, [r3, #0x10]
   287e4: e51b3014     	ldr	r3, [r11, #-0x14]
   287e8: e1520003     	cmp	r2, r3
   287ec: 9a00000e     	bls	0x2882c <processing_thread+0x374> @ imm = #0x38
   287f0: e51b3030     	ldr	r3, [r11, #-0x30]
   287f4: e5932010     	ldr	r2, [r3, #0x10]
   287f8: e51b3018     	ldr	r3, [r11, #-0x18]
   287fc: e1520003     	cmp	r2, r3
   28800: 2a000009     	bhs	0x2882c <processing_thread+0x374> @ imm = #0x24
   28804: e51b3030     	ldr	r3, [r11, #-0x30]
   28808: e5933010     	ldr	r3, [r3, #0x10]
   2880c: e51b2018     	ldr	r2, [r11, #-0x18]
   28810: e0633002     	rsb	r3, r3, r2
   28814: e3530080     	cmp	r3, #128
   28818: 23a03080     	movhs	r3, #128
   2881c: e50b3024     	str	r3, [r11, #-0x24]
   28820: e3a03000     	mov	r3, #0
   28824: e50b300c     	str	r3, [r11, #-0xc]
   28828: ea000018     	b	0x28890 <processing_thread+0x3d8> @ imm = #0x60
   2882c: e51b3030     	ldr	r3, [r11, #-0x30]
   28830: e5932010     	ldr	r2, [r3, #0x10]
   28834: e51b3018     	ldr	r3, [r11, #-0x18]
   28838: e1520003     	cmp	r2, r3
   2883c: 3a00000f     	blo	0x28880 <processing_thread+0x3c8> @ imm = #0x3c
   28840: e51b3030     	ldr	r3, [r11, #-0x30]
   28844: e5932010     	ldr	r2, [r3, #0x10]
   28848: e51b3010     	ldr	r3, [r11, #-0x10]
   2884c: e1520003     	cmp	r2, r3
   28850: 8a00000a     	bhi	0x28880 <processing_thread+0x3c8> @ imm = #0x28
   28854: e51b3030     	ldr	r3, [r11, #-0x30]
   28858: e5933010     	ldr	r3, [r3, #0x10]
   2885c: e51b2010     	ldr	r2, [r11, #-0x10]
   28860: e0633002     	rsb	r3, r3, r2
   28864: e2833001     	add	r3, r3, #1
   28868: e3530080     	cmp	r3, #128
   2886c: 23a03080     	movhs	r3, #128
   28870: e50b3024     	str	r3, [r11, #-0x24]
   28874: e3a03001     	mov	r3, #1
   28878: e50b300c     	str	r3, [r11, #-0xc]
   2887c: ea000003     	b	0x28890 <processing_thread+0x3d8> @ imm = #0xc
   28880: e3a03080     	mov	r3, #128
   28884: e50b3024     	str	r3, [r11, #-0x24]
   28888: e3a03000     	mov	r3, #0
   2888c: e50b300c     	str	r3, [r11, #-0xc]
   28890: e51b3030     	ldr	r3, [r11, #-0x30]
   28894: e5933010     	ldr	r3, [r3, #0x10]
   28898: e51b2020     	ldr	r2, [r11, #-0x20]
   2889c: e0633002     	rsb	r3, r3, r2
   288a0: e51b2024     	ldr	r2, [r11, #-0x24]
   288a4: e1520003     	cmp	r2, r3
   288a8: 31a03002     	movlo	r3, r2
   288ac: e50b3024     	str	r3, [r11, #-0x24]
   288b0: e51b300c     	ldr	r3, [r11, #-0xc]
   288b4: e3530000     	cmp	r3, #0
   288b8: 0a00001f     	beq	0x2893c <processing_thread+0x484> @ imm = #0x7c
   288bc: e51b3028     	ldr	r3, [r11, #-0x28]
   288c0: e3530000     	cmp	r3, #0
   288c4: 1a00001c     	bne	0x2893c <processing_thread+0x484> @ imm = #0x70
   288c8: e51b3030     	ldr	r3, [r11, #-0x30]
   288cc: e5932000     	ldr	r2, [r3]
   288d0: e51b1038     	ldr	r1, [r11, #-0x38]
   288d4: e3a03060     	mov	r3, #96
   288d8: e59f034c     	ldr	r0, [pc, #0x34c]        @ 0x28c2c <processing_thread+0x774>
   288dc: e0020290     	mul	r2, r0, r2
   288e0: e0812002     	add	r2, r1, r2
   288e4: e0823003     	add	r3, r2, r3
   288e8: e5933000     	ldr	r3, [r3]
   288ec: e5d33015     	ldrb	r3, [r3, #0x15]
   288f0: e203300f     	and	r3, r3, #15
   288f4: e6ef3073     	uxtb	r3, r3
   288f8: e2433002     	sub	r3, r3, #2
   288fc: e3530001     	cmp	r3, #1
   28900: 8a00000b     	bhi	0x28934 <processing_thread+0x47c> @ imm = #0x2c
   28904: e51b303c     	ldr	r3, [r11, #-0x3c]
   28908: e5933008     	ldr	r3, [r3, #0x8]
   2890c: e2833010     	add	r3, r3, #16
   28910: e1c300d0     	ldrd	r0, r1, [r3]
   28914: e3a03000     	mov	r3, #0
   28918: e50b302c     	str	r3, [r11, #-0x2c]
   2891c: e1a03000     	mov	r3, r0
   28920: e1833001     	orr	r3, r3, r1
   28924: e3530000     	cmp	r3, #0
   28928: 1a000001     	bne	0x28934 <processing_thread+0x47c> @ imm = #0x4
   2892c: e3a03001     	mov	r3, #1
   28930: e50b302c     	str	r3, [r11, #-0x2c]
   28934: e3a03001     	mov	r3, #1
   28938: e50b3028     	str	r3, [r11, #-0x28]
   2893c: e51b3030     	ldr	r3, [r11, #-0x30]
   28940: e5933168     	ldr	r3, [r3, #0x168]
   28944: e5933000     	ldr	r3, [r3]
   28948: e1a01003     	mov	r1, r3
   2894c: e51b3030     	ldr	r3, [r11, #-0x30]
   28950: e5932010     	ldr	r2, [r3, #0x10]
   28954: e51b303c     	ldr	r3, [r11, #-0x3c]
   28958: e5933008     	ldr	r3, [r3, #0x8]
   2895c: e1a00001     	mov	r0, r1
   28960: e1a01002     	mov	r1, r2
   28964: e51b2024     	ldr	r2, [r11, #-0x24]
   28968: eb00188d     	bl	0x2eba4 <sacd_read_block_raw64> @ imm = #0x6234
   2896c: e1a03000     	mov	r3, r0
   28970: e50b3024     	str	r3, [r11, #-0x24]
   28974: e51b3030     	ldr	r3, [r11, #-0x30]
   28978: e5932010     	ldr	r2, [r3, #0x10]
   2897c: e51b3024     	ldr	r3, [r11, #-0x24]
   28980: e0822003     	add	r2, r2, r3
   28984: e51b3030     	ldr	r3, [r11, #-0x30]
   28988: e5832010     	str	r2, [r3, #0x10]
   2898c: e51b303c     	ldr	r3, [r11, #-0x3c]
   28990: e5932024     	ldr	r2, [r3, #0x24]
   28994: e51b3024     	ldr	r3, [r11, #-0x24]
   28998: e0822003     	add	r2, r2, r3
   2899c: e51b303c     	ldr	r3, [r11, #-0x3c]
   289a0: e5832024     	str	r2, [r3, #0x24]
   289a4: e51b303c     	ldr	r3, [r11, #-0x3c]
   289a8: e593202c     	ldr	r2, [r3, #0x2c]
   289ac: e51b3024     	ldr	r3, [r11, #-0x24]
   289b0: e0822003     	add	r2, r2, r3
   289b4: e51b303c     	ldr	r3, [r11, #-0x3c]
   289b8: e583202c     	str	r2, [r3, #0x2c]
   289bc: e51b3030     	ldr	r3, [r11, #-0x30]
   289c0: e5933168     	ldr	r3, [r3, #0x168]
   289c4: e5933000     	ldr	r3, [r3]
   289c8: e1a01003     	mov	r1, r3
   289cc: e51b303c     	ldr	r3, [r11, #-0x3c]
   289d0: e5932008     	ldr	r2, [r3, #0x8]
   289d4: e51b3024     	ldr	r3, [r11, #-0x24]
   289d8: e1a00001     	mov	r0, r1
   289dc: e1a01002     	mov	r1, r2
   289e0: e1a02003     	mov	r2, r3
   289e4: eb0018ab     	bl	0x2ec98 <sacd_decrypt>  @ imm = #0x62ac
   289e8: e51b3030     	ldr	r3, [r11, #-0x30]
   289ec: e5933054     	ldr	r3, [r3, #0x54]
   289f0: e2033002     	and	r3, r3, #2
   289f4: e3530000     	cmp	r3, #0
   289f8: 1a000004     	bne	0x28a10 <processing_thread+0x558> @ imm = #0x10
   289fc: e51b3030     	ldr	r3, [r11, #-0x30]
   28a00: e5933054     	ldr	r3, [r3, #0x54]
   28a04: e2033004     	and	r3, r3, #4
   28a08: e3530000     	cmp	r3, #0
   28a0c: 0a000010     	beq	0x28a54 <processing_thread+0x59c> @ imm = #0x40
   28a10: e51b3030     	ldr	r3, [r11, #-0x30]
   28a14: e5930168     	ldr	r0, [r3, #0x168]
   28a18: e51b303c     	ldr	r3, [r11, #-0x3c]
   28a1c: e5931008     	ldr	r1, [r3, #0x8]
   28a20: e51b2024     	ldr	r2, [r11, #-0x24]
   28a24: e51b3030     	ldr	r3, [r11, #-0x30]
   28a28: e593c010     	ldr	r12, [r3, #0x10]
   28a2c: e51b3020     	ldr	r3, [r11, #-0x20]
   28a30: e15c0003     	cmp	r12, r3
   28a34: 13a03000     	movne	r3, #0
   28a38: 03a03001     	moveq	r3, #1
   28a3c: e59fc1ec     	ldr	r12, [pc, #0x1ec]       @ 0x28c30 <processing_thread+0x778>
   28a40: e58dc000     	str	r12, [sp]
   28a44: e51bc030     	ldr	r12, [r11, #-0x30]
   28a48: e58dc004     	str	r12, [sp, #0x4]
   28a4c: eb00152a     	bl	0x2defc <scarletbook_process_frames> @ imm = #0x54a8
   28a50: ea00000b     	b	0x28a84 <processing_thread+0x5cc> @ imm = #0x2c
   28a54: e51b3030     	ldr	r3, [r11, #-0x30]
   28a58: e5933054     	ldr	r3, [r3, #0x54]
   28a5c: e2033001     	and	r3, r3, #1
   28a60: e6ef3073     	uxtb	r3, r3
   28a64: e3530000     	cmp	r3, #0
   28a68: 0a000005     	beq	0x28a84 <processing_thread+0x5cc> @ imm = #0x14
   28a6c: e51b303c     	ldr	r3, [r11, #-0x3c]
   28a70: e5933008     	ldr	r3, [r3, #0x8]
   28a74: e51b0030     	ldr	r0, [r11, #-0x30]
   28a78: e1a01003     	mov	r1, r3
   28a7c: e51b2024     	ldr	r2, [r11, #-0x24]
   28a80: ebfffe1b     	bl	0x282f4 <write_block>   @ imm = #-0x794
   28a84: e51b303c     	ldr	r3, [r11, #-0x3c]
   28a88: e5933030     	ldr	r3, [r3, #0x30]
   28a8c: e3530000     	cmp	r3, #0
   28a90: 0a00000b     	beq	0x28ac4 <processing_thread+0x60c> @ imm = #0x2c
   28a94: e51b303c     	ldr	r3, [r11, #-0x3c]
   28a98: e593c030     	ldr	r12, [r3, #0x30]
   28a9c: e51b303c     	ldr	r3, [r11, #-0x3c]
   28aa0: e5930020     	ldr	r0, [r3, #0x20]
   28aa4: e51b303c     	ldr	r3, [r11, #-0x3c]
   28aa8: e5931024     	ldr	r1, [r3, #0x24]
   28aac: e51b303c     	ldr	r3, [r11, #-0x3c]
   28ab0: e5932028     	ldr	r2, [r3, #0x28]
   28ab4: e51b303c     	ldr	r3, [r11, #-0x3c]
   28ab8: e593302c     	ldr	r3, [r3, #0x2c]
   28abc: e12fff3c     	blx	r12
   28ac0: ea000000     	b	0x28ac8 <processing_thread+0x610> @ imm = #0x0
   28ac4: e1a00000     	mov	r0, r0
   28ac8: e51b303c     	ldr	r3, [r11, #-0x3c]
   28acc: e5933010     	ldr	r3, [r3, #0x10]
   28ad0: e3530000     	cmp	r3, #0
   28ad4: 0affff17     	beq	0x28738 <processing_thread+0x280> @ imm = #-0x3a4
   28ad8: ea000000     	b	0x28ae0 <processing_thread+0x628> @ imm = #0x0
   28adc: e1a00000     	mov	r0, r0
   28ae0: e51b303c     	ldr	r3, [r11, #-0x3c]
   28ae4: e5933010     	ldr	r3, [r3, #0x10]
   28ae8: e3530001     	cmp	r3, #1
   28aec: 1a000030     	bne	0x28bb4 <processing_thread+0x6fc> @ imm = #0xc0
   28af0: e51b3030     	ldr	r3, [r11, #-0x30]
   28af4: e5933014     	ldr	r3, [r3, #0x14]
   28af8: e1a00003     	mov	r0, r3
   28afc: ebff8ed3     	bl	0xc650 <strdup@plt>     @ imm = #-0x1c4b4
   28b00: e1a03000     	mov	r3, r0
   28b04: e50b3008     	str	r3, [r11, #-0x8]
   28b08: e51b303c     	ldr	r3, [r11, #-0x3c]
   28b0c: e3a02000     	mov	r2, #0
   28b10: e5832014     	str	r2, [r3, #0x14]
   28b14: e51b3030     	ldr	r3, [r11, #-0x30]
   28b18: e593303c     	ldr	r3, [r3, #0x3c]
   28b1c: e3530000     	cmp	r3, #0
   28b20: 0a000007     	beq	0x28b44 <processing_thread+0x68c> @ imm = #0x1c
   28b24: e51b3030     	ldr	r3, [r11, #-0x30]
   28b28: e5933038     	ldr	r3, [r3, #0x38]
   28b2c: e3530000     	cmp	r3, #0
   28b30: 0a000003     	beq	0x28b44 <processing_thread+0x68c> @ imm = #0xc
   28b34: e51b3030     	ldr	r3, [r11, #-0x30]
   28b38: e5933164     	ldr	r3, [r3, #0x164]
   28b3c: e1a00003     	mov	r0, r3
   28b40: ebffca20     	bl	0x1b3c8 <dst_decoder_destroy> @ imm = #-0xd780
   28b44: e51b0030     	ldr	r0, [r11, #-0x30]
   28b48: ebfffd88     	bl	0x28170 <close_output_file> @ imm = #-0x9e0
   28b4c: e51b0008     	ldr	r0, [r11, #-0x8]
   28b50: ebff8eac     	bl	0xc608 <remove@plt>     @ imm = #-0x1c550
   28b54: e1a03000     	mov	r3, r0
   28b58: e3530000     	cmp	r3, #0
   28b5c: 0a00000e     	beq	0x28b9c <processing_thread+0x6e4> @ imm = #0x38
   28b60: e59f30cc     	ldr	r3, [pc, #0xcc]         @ 0x28c34 <processing_thread+0x77c>
   28b64: e5933000     	ldr	r3, [r3]
   28b68: e5933004     	ldr	r3, [r3, #0x4]
   28b6c: e3530001     	cmp	r3, #1
   28b70: 9a000009     	bls	0x28b9c <processing_thread+0x6e4> @ imm = #0x24
   28b74: ebff8f18     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x1c3a0
   28b78: e1a03000     	mov	r3, r0
   28b7c: e5933000     	ldr	r3, [r3]
   28b80: e1a00003     	mov	r0, r3
   28b84: ebff8da3     	bl	0xc218 <strerror@plt>   @ imm = #-0x1c974
   28b88: e1a03000     	mov	r3, r0
   28b8c: e59f00a4     	ldr	r0, [pc, #0xa4]         @ 0x28c38 <processing_thread+0x780>
   28b90: e51b1008     	ldr	r1, [r11, #-0x8]
   28b94: e1a02003     	mov	r2, r3
   28b98: ebffb045     	bl	0x14cb4 <log_print>     @ imm = #-0x13eec
   28b9c: e51b0008     	ldr	r0, [r11, #-0x8]
   28ba0: ebff8e1d     	bl	0xc41c <free@plt>       @ imm = #-0x1c78c
   28ba4: e51b003c     	ldr	r0, [r11, #-0x3c]
   28ba8: ebfffb79     	bl	0x27994 <destroy_ripping_queue> @ imm = #-0x121c
   28bac: e3a00000     	mov	r0, #0
   28bb0: ebff8db6     	bl	0xc290 <pthread_exit@plt> @ imm = #-0x1c928
   28bb4: e51b3030     	ldr	r3, [r11, #-0x30]
   28bb8: e593303c     	ldr	r3, [r3, #0x3c]
   28bbc: e3530000     	cmp	r3, #0
   28bc0: 0a000007     	beq	0x28be4 <processing_thread+0x72c> @ imm = #0x1c
   28bc4: e51b3030     	ldr	r3, [r11, #-0x30]
   28bc8: e5933038     	ldr	r3, [r3, #0x38]
   28bcc: e3530000     	cmp	r3, #0
   28bd0: 0a000003     	beq	0x28be4 <processing_thread+0x72c> @ imm = #0xc
   28bd4: e51b3030     	ldr	r3, [r11, #-0x30]
   28bd8: e5933164     	ldr	r3, [r3, #0x164]
   28bdc: e1a00003     	mov	r0, r3
   28be0: ebffc9f8     	bl	0x1b3c8 <dst_decoder_destroy> @ imm = #-0xd820
   28be4: e51b0030     	ldr	r0, [r11, #-0x30]
   28be8: ebfffd60     	bl	0x28170 <close_output_file> @ imm = #-0xa80
   28bec: e51b303c     	ldr	r3, [r11, #-0x3c]
   28bf0: e1a00003     	mov	r0, r3
   28bf4: ebfffb34     	bl	0x278cc <list_empty>    @ imm = #-0x1330
   28bf8: e1a03000     	mov	r3, r0
   28bfc: e3530000     	cmp	r3, #0
   28c00: 0afffe3d     	beq	0x284fc <processing_thread+0x44> @ imm = #-0x70c
   28c04: e51b003c     	ldr	r0, [r11, #-0x3c]
   28c08: ebfffb61     	bl	0x27994 <destroy_ripping_queue> @ imm = #-0x127c
   28c0c: e51b303c     	ldr	r3, [r11, #-0x3c]
   28c10: e3a02000     	mov	r2, #0
   28c14: e5832014     	str	r2, [r3, #0x14]
   28c18: e3a00000     	mov	r0, #0
   28c1c: ebff8d9b     	bl	0xc290 <pthread_exit@plt> @ imm = #-0x1c994
   28c20: 78 83 02 00  	.word	0x00028378
   28c24: b0 83 02 00  	.word	0x000283b0
   28c28: 50 38 00 00  	.word	0x00003850
   28c2c: f0 37 00 00  	.word	0x000037f0
   28c30: 40 84 02 00  	.word	0x00028440
   28c34: 5c 73 05 00  	.word	0x0005735c
   28c38: bc 57 03 00  	.word	0x000357bc

