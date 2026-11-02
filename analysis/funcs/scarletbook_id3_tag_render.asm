00020850 <scarletbook_id3_tag_render>:
   20850: e92d4810     	push	{r4, r11, lr}
   20854: e28db008     	add	r11, sp, #8
   20858: e24ddf63     	sub	sp, sp, #396
   2085c: e50b0180     	str	r0, [r11, #-0x180]
   20860: e50b1184     	str	r1, [r11, #-0x184]
   20864: e50b2188     	str	r2, [r11, #-0x188]
   20868: e50b318c     	str	r3, [r11, #-0x18c]
   2086c: e59f36dc     	ldr	r3, [pc, #0x6dc]        @ 0x20f50 <scarletbook_id3_tag_render+0x700>
   20870: e24b10b4     	sub	r1, r11, #180
   20874: e1a02003     	mov	r2, r3
   20878: e3a0307c     	mov	r3, #124
   2087c: e1a00001     	mov	r0, r1
   20880: e1a01002     	mov	r1, r2
   20884: e1a02003     	mov	r2, r3
   20888: ebffaf1f     	bl	0xc50c <memcpy@plt>     @ imm = #-0x14384
   2088c: e3a00000     	mov	r0, #0
   20890: e3a01002     	mov	r1, #2
   20894: ebfff786     	bl	0x1e6b4 <id3_open_mem>  @ imm = #-0x21e8
   20898: e1a03000     	mov	r3, r0
   2089c: e50b3038     	str	r3, [r11, #-0x38]
   208a0: e24b3f5f     	sub	r3, r11, #380
   208a4: e1a00003     	mov	r0, r3
   208a8: e3a01000     	mov	r1, #0
   208ac: e3a020c8     	mov	r2, #200
   208b0: ebffaebb     	bl	0xc3a4 <memset@plt>     @ imm = #-0x14514
   208b4: e51bc188     	ldr	r12, [r11, #-0x188]
   208b8: e51b318c     	ldr	r3, [r11, #-0x18c]
   208bc: e51b0180     	ldr	r0, [r11, #-0x180]
   208c0: e3a01070     	mov	r1, #112
   208c4: e1a02183     	lsl	r2, r3, #3
   208c8: e1a03182     	lsl	r3, r2, #3
   208cc: e0623003     	rsb	r3, r2, r3
   208d0: e59f267c     	ldr	r2, [pc, #0x67c]        @ 0x20f54 <scarletbook_id3_tag_render+0x704>
   208d4: e0020c92     	mul	r2, r2, r12
   208d8: e0833002     	add	r3, r3, r2
   208dc: e0803003     	add	r3, r0, r3
   208e0: e0833001     	add	r3, r3, r1
   208e4: e5933000     	ldr	r3, [r3]
   208e8: e3530000     	cmp	r3, #0
   208ec: 0a00002e     	beq	0x209ac <scarletbook_id3_tag_render+0x15c> @ imm = #0xb8
   208f0: e51bc188     	ldr	r12, [r11, #-0x188]
   208f4: e51b318c     	ldr	r3, [r11, #-0x18c]
   208f8: e51b0180     	ldr	r0, [r11, #-0x180]
   208fc: e3a01070     	mov	r1, #112
   20900: e1a02183     	lsl	r2, r3, #3
   20904: e1a03182     	lsl	r3, r2, #3
   20908: e0623003     	rsb	r3, r2, r3
   2090c: e59f2640     	ldr	r2, [pc, #0x640]        @ 0x20f54 <scarletbook_id3_tag_render+0x704>
   20910: e0020c92     	mul	r2, r2, r12
   20914: e0833002     	add	r3, r3, r2
   20918: e0803003     	add	r3, r0, r3
   2091c: e0833001     	add	r3, r3, r1
   20920: e5934000     	ldr	r4, [r3]
   20924: e51bc188     	ldr	r12, [r11, #-0x188]
   20928: e51b318c     	ldr	r3, [r11, #-0x18c]
   2092c: e51b0180     	ldr	r0, [r11, #-0x180]
   20930: e3a01070     	mov	r1, #112
   20934: e1a02183     	lsl	r2, r3, #3
   20938: e1a03182     	lsl	r3, r2, #3
   2093c: e0623003     	rsb	r3, r2, r3
   20940: e59f260c     	ldr	r2, [pc, #0x60c]        @ 0x20f54 <scarletbook_id3_tag_render+0x704>
   20944: e0020c92     	mul	r2, r2, r12
   20948: e0833002     	add	r3, r3, r2
   2094c: e0803003     	add	r3, r0, r3
   20950: e0833001     	add	r3, r3, r1
   20954: e5933000     	ldr	r3, [r3]
   20958: e1a00003     	mov	r0, r3
   2095c: ebffaede     	bl	0xc4dc <strlen@plt>     @ imm = #-0x14488
   20960: e1a03000     	mov	r3, r0
   20964: e1a00004     	mov	r0, r4
   20968: e1a01003     	mov	r1, r3
   2096c: e59f25e4     	ldr	r2, [pc, #0x5e4]        @ 0x20f58 <scarletbook_id3_tag_render+0x708>
   20970: e59f35e4     	ldr	r3, [pc, #0x5e4]        @ 0x20f5c <scarletbook_id3_tag_render+0x70c>
   20974: ebffb6de     	bl	0xe4f4 <charset_convert> @ imm = #-0x12488
   20978: e1a03000     	mov	r3, r0
   2097c: e50b302c     	str	r3, [r11, #-0x2c]
   20980: e51b0038     	ldr	r0, [r11, #-0x38]
   20984: e59f15d4     	ldr	r1, [pc, #0x5d4]        @ 0x20f60 <scarletbook_id3_tag_render+0x710>
   20988: ebffefd1     	bl	0x1c8d4 <id3_add_frame> @ imm = #-0x40bc
   2098c: e1a03000     	mov	r3, r0
   20990: e50b3034     	str	r3, [r11, #-0x34]
   20994: e51b0034     	ldr	r0, [r11, #-0x34]
   20998: e51b102c     	ldr	r1, [r11, #-0x2c]
   2099c: ebfff42f     	bl	0x1da60 <id3_set_text>  @ imm = #-0x2f44
   209a0: e51b002c     	ldr	r0, [r11, #-0x2c]
   209a4: ebffae9c     	bl	0xc41c <free@plt>       @ imm = #-0x14590
   209a8: ea00003a     	b	0x20a98 <scarletbook_id3_tag_render+0x248> @ imm = #0xe8
   209ac: e51b3180     	ldr	r3, [r11, #-0x180]
   209b0: e2833010     	add	r3, r3, #16
   209b4: e50b3028     	str	r3, [r11, #-0x28]
   209b8: e3a03000     	mov	r3, #0
   209bc: e50b3024     	str	r3, [r11, #-0x24]
   209c0: e51b3028     	ldr	r3, [r11, #-0x28]
   209c4: e5933000     	ldr	r3, [r3]
   209c8: e3530000     	cmp	r3, #0
   209cc: 0a000003     	beq	0x209e0 <scarletbook_id3_tag_render+0x190> @ imm = #0xc
   209d0: e51b3028     	ldr	r3, [r11, #-0x28]
   209d4: e5933000     	ldr	r3, [r3]
   209d8: e50b3024     	str	r3, [r11, #-0x24]
   209dc: ea000016     	b	0x20a3c <scarletbook_id3_tag_render+0x1ec> @ imm = #0x58
   209e0: e51b3028     	ldr	r3, [r11, #-0x28]
   209e4: e5933004     	ldr	r3, [r3, #0x4]
   209e8: e3530000     	cmp	r3, #0
   209ec: 0a000003     	beq	0x20a00 <scarletbook_id3_tag_render+0x1b0> @ imm = #0xc
   209f0: e51b3028     	ldr	r3, [r11, #-0x28]
   209f4: e5933004     	ldr	r3, [r3, #0x4]
   209f8: e50b3024     	str	r3, [r11, #-0x24]
   209fc: ea00000e     	b	0x20a3c <scarletbook_id3_tag_render+0x1ec> @ imm = #0x38
   20a00: e51b3028     	ldr	r3, [r11, #-0x28]
   20a04: e5933020     	ldr	r3, [r3, #0x20]
   20a08: e3530000     	cmp	r3, #0
   20a0c: 0a000003     	beq	0x20a20 <scarletbook_id3_tag_render+0x1d0> @ imm = #0xc
   20a10: e51b3028     	ldr	r3, [r11, #-0x28]
   20a14: e5933020     	ldr	r3, [r3, #0x20]
   20a18: e50b3024     	str	r3, [r11, #-0x24]
   20a1c: ea000006     	b	0x20a3c <scarletbook_id3_tag_render+0x1ec> @ imm = #0x18
   20a20: e51b3028     	ldr	r3, [r11, #-0x28]
   20a24: e5933024     	ldr	r3, [r3, #0x24]
   20a28: e3530000     	cmp	r3, #0
   20a2c: 0a000002     	beq	0x20a3c <scarletbook_id3_tag_render+0x1ec> @ imm = #0x8
   20a30: e51b3028     	ldr	r3, [r11, #-0x28]
   20a34: e5933024     	ldr	r3, [r3, #0x24]
   20a38: e50b3024     	str	r3, [r11, #-0x24]
   20a3c: e51b3024     	ldr	r3, [r11, #-0x24]
   20a40: e3530000     	cmp	r3, #0
   20a44: 0a000013     	beq	0x20a98 <scarletbook_id3_tag_render+0x248> @ imm = #0x4c
   20a48: e51b0038     	ldr	r0, [r11, #-0x38]
   20a4c: e59f150c     	ldr	r1, [pc, #0x50c]        @ 0x20f60 <scarletbook_id3_tag_render+0x710>
   20a50: ebffef9f     	bl	0x1c8d4 <id3_add_frame> @ imm = #-0x4184
   20a54: e1a03000     	mov	r3, r0
   20a58: e50b3034     	str	r3, [r11, #-0x34]
   20a5c: e51b0024     	ldr	r0, [r11, #-0x24]
   20a60: ebffae9d     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1458c
   20a64: e1a03000     	mov	r3, r0
   20a68: e51b0024     	ldr	r0, [r11, #-0x24]
   20a6c: e1a01003     	mov	r1, r3
   20a70: e59f24e0     	ldr	r2, [pc, #0x4e0]        @ 0x20f58 <scarletbook_id3_tag_render+0x708>
   20a74: e59f34e0     	ldr	r3, [pc, #0x4e0]        @ 0x20f5c <scarletbook_id3_tag_render+0x70c>
   20a78: ebffb69d     	bl	0xe4f4 <charset_convert> @ imm = #-0x1258c
   20a7c: e1a03000     	mov	r3, r0
   20a80: e50b3024     	str	r3, [r11, #-0x24]
   20a84: e51b0034     	ldr	r0, [r11, #-0x34]
   20a88: e51b1024     	ldr	r1, [r11, #-0x24]
   20a8c: ebfff3f3     	bl	0x1da60 <id3_set_text>  @ imm = #-0x3034
   20a90: e51b0024     	ldr	r0, [r11, #-0x24]
   20a94: ebffae60     	bl	0xc41c <free@plt>       @ imm = #-0x14680
   20a98: e51bc188     	ldr	r12, [r11, #-0x188]
   20a9c: e51b318c     	ldr	r3, [r11, #-0x18c]
   20aa0: e51b0180     	ldr	r0, [r11, #-0x180]
   20aa4: e3a01074     	mov	r1, #116
   20aa8: e1a02183     	lsl	r2, r3, #3
   20aac: e1a03182     	lsl	r3, r2, #3
   20ab0: e0623003     	rsb	r3, r2, r3
   20ab4: e59f2498     	ldr	r2, [pc, #0x498]        @ 0x20f54 <scarletbook_id3_tag_render+0x704>
   20ab8: e0020c92     	mul	r2, r2, r12
   20abc: e0833002     	add	r3, r3, r2
   20ac0: e0803003     	add	r3, r0, r3
   20ac4: e0833001     	add	r3, r3, r1
   20ac8: e5933000     	ldr	r3, [r3]
   20acc: e3530000     	cmp	r3, #0
   20ad0: 0a000022     	beq	0x20b60 <scarletbook_id3_tag_render+0x310> @ imm = #0x88
   20ad4: e51bc188     	ldr	r12, [r11, #-0x188]
   20ad8: e51b318c     	ldr	r3, [r11, #-0x18c]
   20adc: e51b0180     	ldr	r0, [r11, #-0x180]
   20ae0: e3a01074     	mov	r1, #116
   20ae4: e1a02183     	lsl	r2, r3, #3
   20ae8: e1a03182     	lsl	r3, r2, #3
   20aec: e0623003     	rsb	r3, r2, r3
   20af0: e59f245c     	ldr	r2, [pc, #0x45c]        @ 0x20f54 <scarletbook_id3_tag_render+0x704>
   20af4: e0020c92     	mul	r2, r2, r12
   20af8: e0833002     	add	r3, r3, r2
   20afc: e0803003     	add	r3, r0, r3
   20b00: e0833001     	add	r3, r3, r1
   20b04: e5933000     	ldr	r3, [r3]
   20b08: e50b3020     	str	r3, [r11, #-0x20]
   20b0c: e51b0038     	ldr	r0, [r11, #-0x38]
   20b10: e59f144c     	ldr	r1, [pc, #0x44c]        @ 0x20f64 <scarletbook_id3_tag_render+0x714>
   20b14: ebffef6e     	bl	0x1c8d4 <id3_add_frame> @ imm = #-0x4248
   20b18: e1a03000     	mov	r3, r0
   20b1c: e50b3034     	str	r3, [r11, #-0x34]
   20b20: e51b0020     	ldr	r0, [r11, #-0x20]
   20b24: ebffae6c     	bl	0xc4dc <strlen@plt>     @ imm = #-0x14650
   20b28: e1a03000     	mov	r3, r0
   20b2c: e51b0020     	ldr	r0, [r11, #-0x20]
   20b30: e1a01003     	mov	r1, r3
   20b34: e59f241c     	ldr	r2, [pc, #0x41c]        @ 0x20f58 <scarletbook_id3_tag_render+0x708>
   20b38: e59f341c     	ldr	r3, [pc, #0x41c]        @ 0x20f5c <scarletbook_id3_tag_render+0x70c>
   20b3c: ebffb66c     	bl	0xe4f4 <charset_convert> @ imm = #-0x12650
   20b40: e1a03000     	mov	r3, r0
   20b44: e50b3020     	str	r3, [r11, #-0x20]
   20b48: e51b0034     	ldr	r0, [r11, #-0x34]
   20b4c: e51b1020     	ldr	r1, [r11, #-0x20]
   20b50: ebfff3c2     	bl	0x1da60 <id3_set_text>  @ imm = #-0x30f8
   20b54: e51b0020     	ldr	r0, [r11, #-0x20]
   20b58: ebffae2f     	bl	0xc41c <free@plt>       @ imm = #-0x14744
   20b5c: ea00005a     	b	0x20ccc <scarletbook_id3_tag_render+0x47c> @ imm = #0x168
   20b60: e51b3180     	ldr	r3, [r11, #-0x180]
   20b64: e2833010     	add	r3, r3, #16
   20b68: e50b301c     	str	r3, [r11, #-0x1c]
   20b6c: e3a03000     	mov	r3, #0
   20b70: e50b3018     	str	r3, [r11, #-0x18]
   20b74: e51b301c     	ldr	r3, [r11, #-0x1c]
   20b78: e5933000     	ldr	r3, [r3]
   20b7c: e3530000     	cmp	r3, #0
   20b80: 0a000003     	beq	0x20b94 <scarletbook_id3_tag_render+0x344> @ imm = #0xc
   20b84: e51b301c     	ldr	r3, [r11, #-0x1c]
   20b88: e5933000     	ldr	r3, [r3]
   20b8c: e50b3018     	str	r3, [r11, #-0x18]
   20b90: ea000036     	b	0x20c70 <scarletbook_id3_tag_render+0x420> @ imm = #0xd8
   20b94: e51b301c     	ldr	r3, [r11, #-0x1c]
   20b98: e5933004     	ldr	r3, [r3, #0x4]
   20b9c: e3530000     	cmp	r3, #0
   20ba0: 0a000003     	beq	0x20bb4 <scarletbook_id3_tag_render+0x364> @ imm = #0xc
   20ba4: e51b301c     	ldr	r3, [r11, #-0x1c]
   20ba8: e5933004     	ldr	r3, [r3, #0x4]
   20bac: e50b3018     	str	r3, [r11, #-0x18]
   20bb0: ea00002e     	b	0x20c70 <scarletbook_id3_tag_render+0x420> @ imm = #0xb8
   20bb4: e51b301c     	ldr	r3, [r11, #-0x1c]
   20bb8: e5933020     	ldr	r3, [r3, #0x20]
   20bbc: e3530000     	cmp	r3, #0
   20bc0: 0a000003     	beq	0x20bd4 <scarletbook_id3_tag_render+0x384> @ imm = #0xc
   20bc4: e51b301c     	ldr	r3, [r11, #-0x1c]
   20bc8: e5933020     	ldr	r3, [r3, #0x20]
   20bcc: e50b3018     	str	r3, [r11, #-0x18]
   20bd0: ea000026     	b	0x20c70 <scarletbook_id3_tag_render+0x420> @ imm = #0x98
   20bd4: e51b301c     	ldr	r3, [r11, #-0x1c]
   20bd8: e5933024     	ldr	r3, [r3, #0x24]
   20bdc: e3530000     	cmp	r3, #0
   20be0: 0a000003     	beq	0x20bf4 <scarletbook_id3_tag_render+0x3a4> @ imm = #0xc
   20be4: e51b301c     	ldr	r3, [r11, #-0x1c]
   20be8: e5933024     	ldr	r3, [r3, #0x24]
   20bec: e50b3018     	str	r3, [r11, #-0x18]
   20bf0: ea00001e     	b	0x20c70 <scarletbook_id3_tag_render+0x420> @ imm = #0x78
   20bf4: e51b301c     	ldr	r3, [r11, #-0x1c]
   20bf8: e5933008     	ldr	r3, [r3, #0x8]
   20bfc: e3530000     	cmp	r3, #0
   20c00: 0a000003     	beq	0x20c14 <scarletbook_id3_tag_render+0x3c4> @ imm = #0xc
   20c04: e51b301c     	ldr	r3, [r11, #-0x1c]
   20c08: e5933008     	ldr	r3, [r3, #0x8]
   20c0c: e50b3018     	str	r3, [r11, #-0x18]
   20c10: ea000016     	b	0x20c70 <scarletbook_id3_tag_render+0x420> @ imm = #0x58
   20c14: e51b301c     	ldr	r3, [r11, #-0x1c]
   20c18: e593300c     	ldr	r3, [r3, #0xc]
   20c1c: e3530000     	cmp	r3, #0
   20c20: 0a000003     	beq	0x20c34 <scarletbook_id3_tag_render+0x3e4> @ imm = #0xc
   20c24: e51b301c     	ldr	r3, [r11, #-0x1c]
   20c28: e593300c     	ldr	r3, [r3, #0xc]
   20c2c: e50b3018     	str	r3, [r11, #-0x18]
   20c30: ea00000e     	b	0x20c70 <scarletbook_id3_tag_render+0x420> @ imm = #0x38
   20c34: e51b301c     	ldr	r3, [r11, #-0x1c]
   20c38: e5933028     	ldr	r3, [r3, #0x28]
   20c3c: e3530000     	cmp	r3, #0
   20c40: 0a000003     	beq	0x20c54 <scarletbook_id3_tag_render+0x404> @ imm = #0xc
   20c44: e51b301c     	ldr	r3, [r11, #-0x1c]
   20c48: e5933028     	ldr	r3, [r3, #0x28]
   20c4c: e50b3018     	str	r3, [r11, #-0x18]
   20c50: ea000006     	b	0x20c70 <scarletbook_id3_tag_render+0x420> @ imm = #0x18
   20c54: e51b301c     	ldr	r3, [r11, #-0x1c]
   20c58: e593302c     	ldr	r3, [r3, #0x2c]
   20c5c: e3530000     	cmp	r3, #0
   20c60: 0a000002     	beq	0x20c70 <scarletbook_id3_tag_render+0x420> @ imm = #0x8
   20c64: e51b301c     	ldr	r3, [r11, #-0x1c]
   20c68: e593302c     	ldr	r3, [r3, #0x2c]
   20c6c: e50b3018     	str	r3, [r11, #-0x18]
   20c70: e51b3018     	ldr	r3, [r11, #-0x18]
   20c74: e3530000     	cmp	r3, #0
   20c78: 0a000013     	beq	0x20ccc <scarletbook_id3_tag_render+0x47c> @ imm = #0x4c
   20c7c: e51b0038     	ldr	r0, [r11, #-0x38]
   20c80: e59f12dc     	ldr	r1, [pc, #0x2dc]        @ 0x20f64 <scarletbook_id3_tag_render+0x714>
   20c84: ebffef12     	bl	0x1c8d4 <id3_add_frame> @ imm = #-0x43b8
   20c88: e1a03000     	mov	r3, r0
   20c8c: e50b3034     	str	r3, [r11, #-0x34]
   20c90: e51b0018     	ldr	r0, [r11, #-0x18]
   20c94: ebffae10     	bl	0xc4dc <strlen@plt>     @ imm = #-0x147c0
   20c98: e1a03000     	mov	r3, r0
   20c9c: e51b0018     	ldr	r0, [r11, #-0x18]
   20ca0: e1a01003     	mov	r1, r3
   20ca4: e59f22ac     	ldr	r2, [pc, #0x2ac]        @ 0x20f58 <scarletbook_id3_tag_render+0x708>
   20ca8: e59f32ac     	ldr	r3, [pc, #0x2ac]        @ 0x20f5c <scarletbook_id3_tag_render+0x70c>
   20cac: ebffb610     	bl	0xe4f4 <charset_convert> @ imm = #-0x127c0
   20cb0: e1a03000     	mov	r3, r0
   20cb4: e50b3018     	str	r3, [r11, #-0x18]
   20cb8: e51b0034     	ldr	r0, [r11, #-0x34]
   20cbc: e51b1018     	ldr	r1, [r11, #-0x18]
   20cc0: ebfff366     	bl	0x1da60 <id3_set_text>  @ imm = #-0x3268
   20cc4: e51b0018     	ldr	r0, [r11, #-0x18]
   20cc8: ebffadd3     	bl	0xc41c <free@plt>       @ imm = #-0x148b4
   20ccc: e51b3180     	ldr	r3, [r11, #-0x180]
   20cd0: e2833010     	add	r3, r3, #16
   20cd4: e50b3014     	str	r3, [r11, #-0x14]
   20cd8: e3a03000     	mov	r3, #0
   20cdc: e50b3010     	str	r3, [r11, #-0x10]
   20ce0: e51b3014     	ldr	r3, [r11, #-0x14]
   20ce4: e5933000     	ldr	r3, [r3]
   20ce8: e3530000     	cmp	r3, #0
   20cec: 0a000003     	beq	0x20d00 <scarletbook_id3_tag_render+0x4b0> @ imm = #0xc
   20cf0: e51b3014     	ldr	r3, [r11, #-0x14]
   20cf4: e5933000     	ldr	r3, [r3]
   20cf8: e50b3010     	str	r3, [r11, #-0x10]
   20cfc: ea000016     	b	0x20d5c <scarletbook_id3_tag_render+0x50c> @ imm = #0x58
   20d00: e51b3014     	ldr	r3, [r11, #-0x14]
   20d04: e5933004     	ldr	r3, [r3, #0x4]
   20d08: e3530000     	cmp	r3, #0
   20d0c: 0a000003     	beq	0x20d20 <scarletbook_id3_tag_render+0x4d0> @ imm = #0xc
   20d10: e51b3014     	ldr	r3, [r11, #-0x14]
   20d14: e5933004     	ldr	r3, [r3, #0x4]
   20d18: e50b3010     	str	r3, [r11, #-0x10]
   20d1c: ea00000e     	b	0x20d5c <scarletbook_id3_tag_render+0x50c> @ imm = #0x38
   20d20: e51b3014     	ldr	r3, [r11, #-0x14]
   20d24: e5933020     	ldr	r3, [r3, #0x20]
   20d28: e3530000     	cmp	r3, #0
   20d2c: 0a000003     	beq	0x20d40 <scarletbook_id3_tag_render+0x4f0> @ imm = #0xc
   20d30: e51b3014     	ldr	r3, [r11, #-0x14]
   20d34: e5933020     	ldr	r3, [r3, #0x20]
   20d38: e50b3010     	str	r3, [r11, #-0x10]
   20d3c: ea000006     	b	0x20d5c <scarletbook_id3_tag_render+0x50c> @ imm = #0x18
   20d40: e51b3014     	ldr	r3, [r11, #-0x14]
   20d44: e5933024     	ldr	r3, [r3, #0x24]
   20d48: e3530000     	cmp	r3, #0
   20d4c: 0a000002     	beq	0x20d5c <scarletbook_id3_tag_render+0x50c> @ imm = #0x8
   20d50: e51b3014     	ldr	r3, [r11, #-0x14]
   20d54: e5933024     	ldr	r3, [r3, #0x24]
   20d58: e50b3010     	str	r3, [r11, #-0x10]
   20d5c: e51b3010     	ldr	r3, [r11, #-0x10]
   20d60: e3530000     	cmp	r3, #0
   20d64: 0a000013     	beq	0x20db8 <scarletbook_id3_tag_render+0x568> @ imm = #0x4c
   20d68: e51b0038     	ldr	r0, [r11, #-0x38]
   20d6c: e59f11f4     	ldr	r1, [pc, #0x1f4]        @ 0x20f68 <scarletbook_id3_tag_render+0x718>
   20d70: ebffeed7     	bl	0x1c8d4 <id3_add_frame> @ imm = #-0x44a4
   20d74: e1a03000     	mov	r3, r0
   20d78: e50b3034     	str	r3, [r11, #-0x34]
   20d7c: e51b0010     	ldr	r0, [r11, #-0x10]
   20d80: ebffadd5     	bl	0xc4dc <strlen@plt>     @ imm = #-0x148ac
   20d84: e1a03000     	mov	r3, r0
   20d88: e51b0010     	ldr	r0, [r11, #-0x10]
   20d8c: e1a01003     	mov	r1, r3
   20d90: e59f21c0     	ldr	r2, [pc, #0x1c0]        @ 0x20f58 <scarletbook_id3_tag_render+0x708>
   20d94: e59f31c0     	ldr	r3, [pc, #0x1c0]        @ 0x20f5c <scarletbook_id3_tag_render+0x70c>
   20d98: ebffb5d5     	bl	0xe4f4 <charset_convert> @ imm = #-0x128ac
   20d9c: e1a03000     	mov	r3, r0
   20da0: e50b3010     	str	r3, [r11, #-0x10]
   20da4: e51b0034     	ldr	r0, [r11, #-0x34]
   20da8: e51b1010     	ldr	r1, [r11, #-0x10]
   20dac: ebfff32b     	bl	0x1da60 <id3_set_text>  @ imm = #-0x3354
   20db0: e51b0010     	ldr	r0, [r11, #-0x10]
   20db4: ebffad98     	bl	0xc41c <free@plt>       @ imm = #-0x149a0
   20db8: e51b0038     	ldr	r0, [r11, #-0x38]
   20dbc: e59f11a8     	ldr	r1, [pc, #0x1a8]        @ 0x20f6c <scarletbook_id3_tag_render+0x71c>
   20dc0: ebffeec3     	bl	0x1c8d4 <id3_add_frame> @ imm = #-0x44f4
   20dc4: e1a03000     	mov	r3, r0
   20dc8: e50b3034     	str	r3, [r11, #-0x34]
   20dcc: e51b2188     	ldr	r2, [r11, #-0x188]
   20dd0: e51b1180     	ldr	r1, [r11, #-0x180]
   20dd4: e59f3194     	ldr	r3, [pc, #0x194]        @ 0x20f70 <scarletbook_id3_tag_render+0x720>
   20dd8: e59f0174     	ldr	r0, [pc, #0x174]        @ 0x20f54 <scarletbook_id3_tag_render+0x704>
   20ddc: e0020290     	mul	r2, r0, r2
   20de0: e0812002     	add	r2, r1, r2
   20de4: e0823003     	add	r3, r2, r3
   20de8: e5931000     	ldr	r1, [r3]
   20dec: e51b318c     	ldr	r3, [r11, #-0x18c]
   20df0: e2832c03     	add	r2, r3, #768
   20df4: e3a03003     	mov	r3, #3
   20df8: e1a02102     	lsl	r2, r2, #2
   20dfc: e0812002     	add	r2, r1, r2
   20e00: e0823003     	add	r3, r2, r3
   20e04: e5d33000     	ldrb	r3, [r3]
   20e08: e203201f     	and	r2, r3, #31
   20e0c: e3e030a7     	mvn	r3, #167
   20e10: e1a02102     	lsl	r2, r2, #2
   20e14: e24b100c     	sub	r1, r11, #12
   20e18: e0812002     	add	r2, r1, r2
   20e1c: e0823003     	add	r3, r2, r3
   20e20: e5932000     	ldr	r2, [r3]
   20e24: e59f3148     	ldr	r3, [pc, #0x148]        @ 0x20f74 <scarletbook_id3_tag_render+0x724>
   20e28: e7933102     	ldr	r3, [r3, r2, lsl #2]
   20e2c: e51b0034     	ldr	r0, [r11, #-0x34]
   20e30: e1a01003     	mov	r1, r3
   20e34: ebfff309     	bl	0x1da60 <id3_set_text>  @ imm = #-0x33dc
   20e38: e59f2138     	ldr	r2, [pc, #0x138]        @ 0x20f78 <scarletbook_id3_tag_render+0x728>
   20e3c: e51b3180     	ldr	r3, [r11, #-0x180]
   20e40: e5933008     	ldr	r3, [r3, #0x8]
   20e44: e5d31078     	ldrb	r1, [r3, #0x78]
   20e48: e5d33079     	ldrb	r3, [r3, #0x79]
   20e4c: e1a03403     	lsl	r3, r3, #8
   20e50: e1833001     	orr	r3, r3, r1
   20e54: e6ff3073     	uxth	r3, r3
   20e58: e24b1f5f     	sub	r1, r11, #380
   20e5c: e1a00001     	mov	r0, r1
   20e60: e3a010c8     	mov	r1, #200
   20e64: ebffae35     	bl	0xc740 <snprintf@plt>   @ imm = #-0x1472c
   20e68: e51b0038     	ldr	r0, [r11, #-0x38]
   20e6c: e59f1108     	ldr	r1, [pc, #0x108]        @ 0x20f7c <scarletbook_id3_tag_render+0x72c>
   20e70: ebffee97     	bl	0x1c8d4 <id3_add_frame> @ imm = #-0x45a4
   20e74: e1a03000     	mov	r3, r0
   20e78: e50b3034     	str	r3, [r11, #-0x34]
   20e7c: e24b3f5f     	sub	r3, r11, #380
   20e80: e51b0034     	ldr	r0, [r11, #-0x34]
   20e84: e1a01003     	mov	r1, r3
   20e88: ebfff2f4     	bl	0x1da60 <id3_set_text>  @ imm = #-0x3430
   20e8c: e59f20ec     	ldr	r2, [pc, #0xec]         @ 0x20f80 <scarletbook_id3_tag_render+0x730>
   20e90: e51b3180     	ldr	r3, [r11, #-0x180]
   20e94: e5933008     	ldr	r3, [r3, #0x8]
   20e98: e5d3307a     	ldrb	r3, [r3, #0x7a]
   20e9c: e51b1180     	ldr	r1, [r11, #-0x180]
   20ea0: e5911008     	ldr	r1, [r1, #0x8]
   20ea4: e5d1107b     	ldrb	r1, [r1, #0x7b]
   20ea8: e1a00001     	mov	r0, r1
   20eac: e24b1f5f     	sub	r1, r11, #380
   20eb0: e58d0000     	str	r0, [sp]
   20eb4: e1a00001     	mov	r0, r1
   20eb8: e3a010c8     	mov	r1, #200
   20ebc: ebffae1f     	bl	0xc740 <snprintf@plt>   @ imm = #-0x14784
   20ec0: e51b0038     	ldr	r0, [r11, #-0x38]
   20ec4: e59f10b8     	ldr	r1, [pc, #0xb8]         @ 0x20f84 <scarletbook_id3_tag_render+0x734>
   20ec8: ebffee81     	bl	0x1c8d4 <id3_add_frame> @ imm = #-0x45fc
   20ecc: e1a03000     	mov	r3, r0
   20ed0: e50b3034     	str	r3, [r11, #-0x34]
   20ed4: e24b3f5f     	sub	r3, r11, #380
   20ed8: e51b0034     	ldr	r0, [r11, #-0x34]
   20edc: e1a01003     	mov	r1, r3
   20ee0: ebfff2de     	bl	0x1da60 <id3_set_text>  @ imm = #-0x3488
   20ee4: e59f209c     	ldr	r2, [pc, #0x9c]         @ 0x20f88 <scarletbook_id3_tag_render+0x738>
   20ee8: e51b318c     	ldr	r3, [r11, #-0x18c]
   20eec: e2833001     	add	r3, r3, #1
   20ef0: e24b1f5f     	sub	r1, r11, #380
   20ef4: e1a00001     	mov	r0, r1
   20ef8: e3a010c8     	mov	r1, #200
   20efc: ebffae0f     	bl	0xc740 <snprintf@plt>   @ imm = #-0x147c4
   20f00: e51b0038     	ldr	r0, [r11, #-0x38]
   20f04: e59f1080     	ldr	r1, [pc, #0x80]         @ 0x20f8c <scarletbook_id3_tag_render+0x73c>
   20f08: ebffee71     	bl	0x1c8d4 <id3_add_frame> @ imm = #-0x463c
   20f0c: e1a03000     	mov	r3, r0
   20f10: e50b3034     	str	r3, [r11, #-0x34]
   20f14: e24b3f5f     	sub	r3, r11, #380
   20f18: e51b0034     	ldr	r0, [r11, #-0x34]
   20f1c: e1a01003     	mov	r1, r3
   20f20: ebfff2ce     	bl	0x1da60 <id3_set_text>  @ imm = #-0x34c8
   20f24: e51b0038     	ldr	r0, [r11, #-0x38]
   20f28: e51b1184     	ldr	r1, [r11, #-0x184]
   20f2c: ebfff6ed     	bl	0x1eae8 <id3_write_tag> @ imm = #-0x244c
   20f30: e1a03000     	mov	r3, r0
   20f34: e50b3030     	str	r3, [r11, #-0x30]
   20f38: e51b0038     	ldr	r0, [r11, #-0x38]
   20f3c: ebfff692     	bl	0x1e98c <id3_close>     @ imm = #-0x25b8
   20f40: e51b3030     	ldr	r3, [r11, #-0x30]
   20f44: e1a00003     	mov	r0, r3
   20f48: e24bd008     	sub	sp, r11, #8
   20f4c: e8bd8810     	pop	{r4, r11, pc}
   20f50: 0c 52 03 00  	.word	0x0003520c
   20f54: f0 37 00 00  	.word	0x000037f0
   20f58: e0 51 03 00  	.word	0x000351e0
   20f5c: e8 51 03 00  	.word	0x000351e8
   20f60: 32 54 49 54  	.word	0x54495432
   20f64: 31 45 50 54  	.word	0x54504531
   20f68: 42 4c 41 54  	.word	0x54414c42
   20f6c: 4e 4f 43 54  	.word	0x54434f4e
   20f70: 38 38 00 00  	.word	0x00003838
   20f74: 90 4f 03 00  	.word	0x00034f90
   20f78: f4 51 03 00  	.word	0x000351f4
   20f7c: 52 45 59 54  	.word	0x54594552
   20f80: fc 51 03 00  	.word	0x000351fc
   20f84: 54 41 44 54  	.word	0x54444154
   20f88: 08 52 03 00  	.word	0x00035208
   20f8c: 4b 43 52 54  	.word	0x5452434b

