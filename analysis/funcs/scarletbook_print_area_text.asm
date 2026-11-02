0001fb2c <scarletbook_print_area_text>:
   1fb2c: e92d4830     	push	{r4, r5, r11, lr}
   1fb30: e28db00c     	add	r11, sp, #12
   1fb34: e24dd010     	sub	sp, sp, #16
   1fb38: e50b0018     	str	r0, [r11, #-0x18]
   1fb3c: e50b101c     	str	r1, [r11, #-0x1c]
   1fb40: e59f346c     	ldr	r3, [pc, #0x46c]        @ 0x1ffb4 <scarletbook_print_area_text+0x488>
   1fb44: e5933000     	ldr	r3, [r3]
   1fb48: e1a02003     	mov	r2, r3
   1fb4c: e59f3464     	ldr	r3, [pc, #0x464]        @ 0x1ffb8 <scarletbook_print_area_text+0x48c>
   1fb50: e1a00002     	mov	r0, r2
   1fb54: e1a01003     	mov	r1, r3
   1fb58: e51b201c     	ldr	r2, [r11, #-0x1c]
   1fb5c: ebffb2e8     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x13460
   1fb60: e3a03000     	mov	r3, #0
   1fb64: e50b3014     	str	r3, [r11, #-0x14]
   1fb68: ea000102     	b	0x1ff78 <scarletbook_print_area_text+0x44c> @ imm = #0x408
   1fb6c: e51b201c     	ldr	r2, [r11, #-0x1c]
   1fb70: e1a03002     	mov	r3, r2
   1fb74: e1a01383     	lsl	r1, r3, #7
   1fb78: e1a03181     	lsl	r3, r1, #3
   1fb7c: e0613003     	rsb	r3, r1, r3
   1fb80: e0623003     	rsb	r3, r2, r3
   1fb84: e2833001     	add	r3, r3, #1
   1fb88: e1a03203     	lsl	r3, r3, #4
   1fb8c: e2833058     	add	r3, r3, #88
   1fb90: e51b2018     	ldr	r2, [r11, #-0x18]
   1fb94: e0823003     	add	r3, r2, r3
   1fb98: e2832008     	add	r2, r3, #8
   1fb9c: e51b3014     	ldr	r3, [r11, #-0x14]
   1fba0: e1a03183     	lsl	r3, r3, #3
   1fba4: e1a01183     	lsl	r1, r3, #3
   1fba8: e0633001     	rsb	r3, r3, r1
   1fbac: e0823003     	add	r3, r2, r3
   1fbb0: e50b3010     	str	r3, [r11, #-0x10]
   1fbb4: e51b3010     	ldr	r3, [r11, #-0x10]
   1fbb8: e5933000     	ldr	r3, [r3]
   1fbbc: e3530000     	cmp	r3, #0
   1fbc0: 0a00000c     	beq	0x1fbf8 <scarletbook_print_area_text+0xcc> @ imm = #0x30
   1fbc4: e59f33e8     	ldr	r3, [pc, #0x3e8]        @ 0x1ffb4 <scarletbook_print_area_text+0x488>
   1fbc8: e5933000     	ldr	r3, [r3]
   1fbcc: e1a05003     	mov	r5, r3
   1fbd0: e59f43e4     	ldr	r4, [pc, #0x3e4]        @ 0x1ffbc <scarletbook_print_area_text+0x490>
   1fbd4: e51b3010     	ldr	r3, [r11, #-0x10]
   1fbd8: e5933000     	ldr	r3, [r3]
   1fbdc: e1a00003     	mov	r0, r3
   1fbe0: ebfffd76     	bl	0x1f1c0 <ucs>           @ imm = #-0xa28
   1fbe4: e1a03000     	mov	r3, r0
   1fbe8: e1a00005     	mov	r0, r5
   1fbec: e1a01004     	mov	r1, r4
   1fbf0: e51b2014     	ldr	r2, [r11, #-0x14]
   1fbf4: ebffb2c2     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x134f8
   1fbf8: e51b3010     	ldr	r3, [r11, #-0x10]
   1fbfc: e593301c     	ldr	r3, [r3, #0x1c]
   1fc00: e3530000     	cmp	r3, #0
   1fc04: 0a00000c     	beq	0x1fc3c <scarletbook_print_area_text+0x110> @ imm = #0x30
   1fc08: e59f33a4     	ldr	r3, [pc, #0x3a4]        @ 0x1ffb4 <scarletbook_print_area_text+0x488>
   1fc0c: e5933000     	ldr	r3, [r3]
   1fc10: e1a05003     	mov	r5, r3
   1fc14: e59f43a4     	ldr	r4, [pc, #0x3a4]        @ 0x1ffc0 <scarletbook_print_area_text+0x494>
   1fc18: e51b3010     	ldr	r3, [r11, #-0x10]
   1fc1c: e593301c     	ldr	r3, [r3, #0x1c]
   1fc20: e1a00003     	mov	r0, r3
   1fc24: ebfffd65     	bl	0x1f1c0 <ucs>           @ imm = #-0xa6c
   1fc28: e1a03000     	mov	r3, r0
   1fc2c: e1a00005     	mov	r0, r5
   1fc30: e1a01004     	mov	r1, r4
   1fc34: e51b2014     	ldr	r2, [r11, #-0x14]
   1fc38: ebffb2b1     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x1353c
   1fc3c: e51b3010     	ldr	r3, [r11, #-0x10]
   1fc40: e5933004     	ldr	r3, [r3, #0x4]
   1fc44: e3530000     	cmp	r3, #0
   1fc48: 0a00000c     	beq	0x1fc80 <scarletbook_print_area_text+0x154> @ imm = #0x30
   1fc4c: e59f3360     	ldr	r3, [pc, #0x360]        @ 0x1ffb4 <scarletbook_print_area_text+0x488>
   1fc50: e5933000     	ldr	r3, [r3]
   1fc54: e1a05003     	mov	r5, r3
   1fc58: e59f4364     	ldr	r4, [pc, #0x364]        @ 0x1ffc4 <scarletbook_print_area_text+0x498>
   1fc5c: e51b3010     	ldr	r3, [r11, #-0x10]
   1fc60: e5933004     	ldr	r3, [r3, #0x4]
   1fc64: e1a00003     	mov	r0, r3
   1fc68: ebfffd54     	bl	0x1f1c0 <ucs>           @ imm = #-0xab0
   1fc6c: e1a03000     	mov	r3, r0
   1fc70: e1a00005     	mov	r0, r5
   1fc74: e1a01004     	mov	r1, r4
   1fc78: e51b2014     	ldr	r2, [r11, #-0x14]
   1fc7c: ebffb2a0     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x13580
   1fc80: e51b3010     	ldr	r3, [r11, #-0x10]
   1fc84: e5933020     	ldr	r3, [r3, #0x20]
   1fc88: e3530000     	cmp	r3, #0
   1fc8c: 0a00000c     	beq	0x1fcc4 <scarletbook_print_area_text+0x198> @ imm = #0x30
   1fc90: e59f331c     	ldr	r3, [pc, #0x31c]        @ 0x1ffb4 <scarletbook_print_area_text+0x488>
   1fc94: e5933000     	ldr	r3, [r3]
   1fc98: e1a05003     	mov	r5, r3
   1fc9c: e59f4324     	ldr	r4, [pc, #0x324]        @ 0x1ffc8 <scarletbook_print_area_text+0x49c>
   1fca0: e51b3010     	ldr	r3, [r11, #-0x10]
   1fca4: e5933020     	ldr	r3, [r3, #0x20]
   1fca8: e1a00003     	mov	r0, r3
   1fcac: ebfffd43     	bl	0x1f1c0 <ucs>           @ imm = #-0xaf4
   1fcb0: e1a03000     	mov	r3, r0
   1fcb4: e1a00005     	mov	r0, r5
   1fcb8: e1a01004     	mov	r1, r4
   1fcbc: e51b2014     	ldr	r2, [r11, #-0x14]
   1fcc0: ebffb28f     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x135c4
   1fcc4: e51b3010     	ldr	r3, [r11, #-0x10]
   1fcc8: e5933008     	ldr	r3, [r3, #0x8]
   1fccc: e3530000     	cmp	r3, #0
   1fcd0: 0a00000c     	beq	0x1fd08 <scarletbook_print_area_text+0x1dc> @ imm = #0x30
   1fcd4: e59f32d8     	ldr	r3, [pc, #0x2d8]        @ 0x1ffb4 <scarletbook_print_area_text+0x488>
   1fcd8: e5933000     	ldr	r3, [r3]
   1fcdc: e1a05003     	mov	r5, r3
   1fce0: e59f42e4     	ldr	r4, [pc, #0x2e4]        @ 0x1ffcc <scarletbook_print_area_text+0x4a0>
   1fce4: e51b3010     	ldr	r3, [r11, #-0x10]
   1fce8: e5933008     	ldr	r3, [r3, #0x8]
   1fcec: e1a00003     	mov	r0, r3
   1fcf0: ebfffd32     	bl	0x1f1c0 <ucs>           @ imm = #-0xb38
   1fcf4: e1a03000     	mov	r3, r0
   1fcf8: e1a00005     	mov	r0, r5
   1fcfc: e1a01004     	mov	r1, r4
   1fd00: e51b2014     	ldr	r2, [r11, #-0x14]
   1fd04: ebffb27e     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x13608
   1fd08: e51b3010     	ldr	r3, [r11, #-0x10]
   1fd0c: e5933024     	ldr	r3, [r3, #0x24]
   1fd10: e3530000     	cmp	r3, #0
   1fd14: 0a00000c     	beq	0x1fd4c <scarletbook_print_area_text+0x220> @ imm = #0x30
   1fd18: e59f3294     	ldr	r3, [pc, #0x294]        @ 0x1ffb4 <scarletbook_print_area_text+0x488>
   1fd1c: e5933000     	ldr	r3, [r3]
   1fd20: e1a05003     	mov	r5, r3
   1fd24: e59f42a4     	ldr	r4, [pc, #0x2a4]        @ 0x1ffd0 <scarletbook_print_area_text+0x4a4>
   1fd28: e51b3010     	ldr	r3, [r11, #-0x10]
   1fd2c: e5933024     	ldr	r3, [r3, #0x24]
   1fd30: e1a00003     	mov	r0, r3
   1fd34: ebfffd21     	bl	0x1f1c0 <ucs>           @ imm = #-0xb7c
   1fd38: e1a03000     	mov	r3, r0
   1fd3c: e1a00005     	mov	r0, r5
   1fd40: e1a01004     	mov	r1, r4
   1fd44: e51b2014     	ldr	r2, [r11, #-0x14]
   1fd48: ebffb26d     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x1364c
   1fd4c: e51b3010     	ldr	r3, [r11, #-0x10]
   1fd50: e593300c     	ldr	r3, [r3, #0xc]
   1fd54: e3530000     	cmp	r3, #0
   1fd58: 0a00000c     	beq	0x1fd90 <scarletbook_print_area_text+0x264> @ imm = #0x30
   1fd5c: e59f3250     	ldr	r3, [pc, #0x250]        @ 0x1ffb4 <scarletbook_print_area_text+0x488>
   1fd60: e5933000     	ldr	r3, [r3]
   1fd64: e1a05003     	mov	r5, r3
   1fd68: e59f4264     	ldr	r4, [pc, #0x264]        @ 0x1ffd4 <scarletbook_print_area_text+0x4a8>
   1fd6c: e51b3010     	ldr	r3, [r11, #-0x10]
   1fd70: e593300c     	ldr	r3, [r3, #0xc]
   1fd74: e1a00003     	mov	r0, r3
   1fd78: ebfffd10     	bl	0x1f1c0 <ucs>           @ imm = #-0xbc0
   1fd7c: e1a03000     	mov	r3, r0
   1fd80: e1a00005     	mov	r0, r5
   1fd84: e1a01004     	mov	r1, r4
   1fd88: e51b2014     	ldr	r2, [r11, #-0x14]
   1fd8c: ebffb25c     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x13690
   1fd90: e51b3010     	ldr	r3, [r11, #-0x10]
   1fd94: e5933028     	ldr	r3, [r3, #0x28]
   1fd98: e3530000     	cmp	r3, #0
   1fd9c: 0a00000c     	beq	0x1fdd4 <scarletbook_print_area_text+0x2a8> @ imm = #0x30
   1fda0: e59f320c     	ldr	r3, [pc, #0x20c]        @ 0x1ffb4 <scarletbook_print_area_text+0x488>
   1fda4: e5933000     	ldr	r3, [r3]
   1fda8: e1a05003     	mov	r5, r3
   1fdac: e59f4224     	ldr	r4, [pc, #0x224]        @ 0x1ffd8 <scarletbook_print_area_text+0x4ac>
   1fdb0: e51b3010     	ldr	r3, [r11, #-0x10]
   1fdb4: e5933028     	ldr	r3, [r3, #0x28]
   1fdb8: e1a00003     	mov	r0, r3
   1fdbc: ebfffcff     	bl	0x1f1c0 <ucs>           @ imm = #-0xc04
   1fdc0: e1a03000     	mov	r3, r0
   1fdc4: e1a00005     	mov	r0, r5
   1fdc8: e1a01004     	mov	r1, r4
   1fdcc: e51b2014     	ldr	r2, [r11, #-0x14]
   1fdd0: ebffb24b     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x136d4
   1fdd4: e51b3010     	ldr	r3, [r11, #-0x10]
   1fdd8: e5933010     	ldr	r3, [r3, #0x10]
   1fddc: e3530000     	cmp	r3, #0
   1fde0: 0a00000c     	beq	0x1fe18 <scarletbook_print_area_text+0x2ec> @ imm = #0x30
   1fde4: e59f31c8     	ldr	r3, [pc, #0x1c8]        @ 0x1ffb4 <scarletbook_print_area_text+0x488>
   1fde8: e5933000     	ldr	r3, [r3]
   1fdec: e1a05003     	mov	r5, r3
   1fdf0: e59f41e4     	ldr	r4, [pc, #0x1e4]        @ 0x1ffdc <scarletbook_print_area_text+0x4b0>
   1fdf4: e51b3010     	ldr	r3, [r11, #-0x10]
   1fdf8: e5933010     	ldr	r3, [r3, #0x10]
   1fdfc: e1a00003     	mov	r0, r3
   1fe00: ebfffcee     	bl	0x1f1c0 <ucs>           @ imm = #-0xc48
   1fe04: e1a03000     	mov	r3, r0
   1fe08: e1a00005     	mov	r0, r5
   1fe0c: e1a01004     	mov	r1, r4
   1fe10: e51b2014     	ldr	r2, [r11, #-0x14]
   1fe14: ebffb23a     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x13718
   1fe18: e51b3010     	ldr	r3, [r11, #-0x10]
   1fe1c: e593302c     	ldr	r3, [r3, #0x2c]
   1fe20: e3530000     	cmp	r3, #0
   1fe24: 0a00000c     	beq	0x1fe5c <scarletbook_print_area_text+0x330> @ imm = #0x30
   1fe28: e59f3184     	ldr	r3, [pc, #0x184]        @ 0x1ffb4 <scarletbook_print_area_text+0x488>
   1fe2c: e5933000     	ldr	r3, [r3]
   1fe30: e1a05003     	mov	r5, r3
   1fe34: e59f41a4     	ldr	r4, [pc, #0x1a4]        @ 0x1ffe0 <scarletbook_print_area_text+0x4b4>
   1fe38: e51b3010     	ldr	r3, [r11, #-0x10]
   1fe3c: e593302c     	ldr	r3, [r3, #0x2c]
   1fe40: e1a00003     	mov	r0, r3
   1fe44: ebfffcdd     	bl	0x1f1c0 <ucs>           @ imm = #-0xc8c
   1fe48: e1a03000     	mov	r3, r0
   1fe4c: e1a00005     	mov	r0, r5
   1fe50: e1a01004     	mov	r1, r4
   1fe54: e51b2014     	ldr	r2, [r11, #-0x14]
   1fe58: ebffb229     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x1375c
   1fe5c: e51b3010     	ldr	r3, [r11, #-0x10]
   1fe60: e5933014     	ldr	r3, [r3, #0x14]
   1fe64: e3530000     	cmp	r3, #0
   1fe68: 0a00000c     	beq	0x1fea0 <scarletbook_print_area_text+0x374> @ imm = #0x30
   1fe6c: e59f3140     	ldr	r3, [pc, #0x140]        @ 0x1ffb4 <scarletbook_print_area_text+0x488>
   1fe70: e5933000     	ldr	r3, [r3]
   1fe74: e1a05003     	mov	r5, r3
   1fe78: e59f4164     	ldr	r4, [pc, #0x164]        @ 0x1ffe4 <scarletbook_print_area_text+0x4b8>
   1fe7c: e51b3010     	ldr	r3, [r11, #-0x10]
   1fe80: e5933014     	ldr	r3, [r3, #0x14]
   1fe84: e1a00003     	mov	r0, r3
   1fe88: ebfffccc     	bl	0x1f1c0 <ucs>           @ imm = #-0xcd0
   1fe8c: e1a03000     	mov	r3, r0
   1fe90: e1a00005     	mov	r0, r5
   1fe94: e1a01004     	mov	r1, r4
   1fe98: e51b2014     	ldr	r2, [r11, #-0x14]
   1fe9c: ebffb218     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x137a0
   1fea0: e51b3010     	ldr	r3, [r11, #-0x10]
   1fea4: e5933030     	ldr	r3, [r3, #0x30]
   1fea8: e3530000     	cmp	r3, #0
   1feac: 0a00000c     	beq	0x1fee4 <scarletbook_print_area_text+0x3b8> @ imm = #0x30
   1feb0: e59f30fc     	ldr	r3, [pc, #0xfc]         @ 0x1ffb4 <scarletbook_print_area_text+0x488>
   1feb4: e5933000     	ldr	r3, [r3]
   1feb8: e1a05003     	mov	r5, r3
   1febc: e59f4124     	ldr	r4, [pc, #0x124]        @ 0x1ffe8 <scarletbook_print_area_text+0x4bc>
   1fec0: e51b3010     	ldr	r3, [r11, #-0x10]
   1fec4: e5933030     	ldr	r3, [r3, #0x30]
   1fec8: e1a00003     	mov	r0, r3
   1fecc: ebfffcbb     	bl	0x1f1c0 <ucs>           @ imm = #-0xd14
   1fed0: e1a03000     	mov	r3, r0
   1fed4: e1a00005     	mov	r0, r5
   1fed8: e1a01004     	mov	r1, r4
   1fedc: e51b2014     	ldr	r2, [r11, #-0x14]
   1fee0: ebffb207     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x137e4
   1fee4: e51b3010     	ldr	r3, [r11, #-0x10]
   1fee8: e5933018     	ldr	r3, [r3, #0x18]
   1feec: e3530000     	cmp	r3, #0
   1fef0: 0a00000c     	beq	0x1ff28 <scarletbook_print_area_text+0x3fc> @ imm = #0x30
   1fef4: e59f30b8     	ldr	r3, [pc, #0xb8]         @ 0x1ffb4 <scarletbook_print_area_text+0x488>
   1fef8: e5933000     	ldr	r3, [r3]
   1fefc: e1a05003     	mov	r5, r3
   1ff00: e59f40e4     	ldr	r4, [pc, #0xe4]         @ 0x1ffec <scarletbook_print_area_text+0x4c0>
   1ff04: e51b3010     	ldr	r3, [r11, #-0x10]
   1ff08: e5933018     	ldr	r3, [r3, #0x18]
   1ff0c: e1a00003     	mov	r0, r3
   1ff10: ebfffcaa     	bl	0x1f1c0 <ucs>           @ imm = #-0xd58
   1ff14: e1a03000     	mov	r3, r0
   1ff18: e1a00005     	mov	r0, r5
   1ff1c: e1a01004     	mov	r1, r4
   1ff20: e51b2014     	ldr	r2, [r11, #-0x14]
   1ff24: ebffb1f6     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x13828
   1ff28: e51b3010     	ldr	r3, [r11, #-0x10]
   1ff2c: e5933034     	ldr	r3, [r3, #0x34]
   1ff30: e3530000     	cmp	r3, #0
   1ff34: 0a00000c     	beq	0x1ff6c <scarletbook_print_area_text+0x440> @ imm = #0x30
   1ff38: e59f3074     	ldr	r3, [pc, #0x74]         @ 0x1ffb4 <scarletbook_print_area_text+0x488>
   1ff3c: e5933000     	ldr	r3, [r3]
   1ff40: e1a05003     	mov	r5, r3
   1ff44: e59f40a4     	ldr	r4, [pc, #0xa4]         @ 0x1fff0 <scarletbook_print_area_text+0x4c4>
   1ff48: e51b3010     	ldr	r3, [r11, #-0x10]
   1ff4c: e5933034     	ldr	r3, [r3, #0x34]
   1ff50: e1a00003     	mov	r0, r3
   1ff54: ebfffc99     	bl	0x1f1c0 <ucs>           @ imm = #-0xd9c
   1ff58: e1a03000     	mov	r3, r0
   1ff5c: e1a00005     	mov	r0, r5
   1ff60: e1a01004     	mov	r1, r4
   1ff64: e51b2014     	ldr	r2, [r11, #-0x14]
   1ff68: ebffb1e5     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x1386c
   1ff6c: e51b3014     	ldr	r3, [r11, #-0x14]
   1ff70: e2833001     	add	r3, r3, #1
   1ff74: e50b3014     	str	r3, [r11, #-0x14]
   1ff78: e51b201c     	ldr	r2, [r11, #-0x1c]
   1ff7c: e51b1018     	ldr	r1, [r11, #-0x18]
   1ff80: e3a03060     	mov	r3, #96
   1ff84: e59f0068     	ldr	r0, [pc, #0x68]         @ 0x1fff4 <scarletbook_print_area_text+0x4c8>
   1ff88: e0020290     	mul	r2, r0, r2
   1ff8c: e0812002     	add	r2, r1, r2
   1ff90: e0823003     	add	r3, r2, r3
   1ff94: e5933000     	ldr	r3, [r3]
   1ff98: e5d33045     	ldrb	r3, [r3, #0x45]
   1ff9c: e1a02003     	mov	r2, r3
   1ffa0: e51b3014     	ldr	r3, [r11, #-0x14]
   1ffa4: e1520003     	cmp	r2, r3
   1ffa8: cafffeef     	bgt	0x1fb6c <scarletbook_print_area_text+0x40> @ imm = #-0x444
   1ffac: e24bd00c     	sub	sp, r11, #12
   1ffb0: e8bd8830     	pop	{r4, r5, r11, pc}
   1ffb4: f4 6d 05 00  	.word	0x00056df4
   1ffb8: 40 3f 03 00  	.word	0x00033f40
   1ffbc: 8c 3f 03 00  	.word	0x00033f8c
   1ffc0: d4 3f 03 00  	.word	0x00033fd4
   1ffc4: 40 40 03 00  	.word	0x00034040
   1ffc8: 98 40 03 00  	.word	0x00034098
   1ffcc: 14 41 03 00  	.word	0x00034114
   1ffd0: 70 41 03 00  	.word	0x00034170
   1ffd4: f0 41 03 00  	.word	0x000341f0
   1ffd8: 44 42 03 00  	.word	0x00034244
   1ffdc: bc 42 03 00  	.word	0x000342bc
   1ffe0: 10 43 03 00  	.word	0x00034310
   1ffe4: 88 43 03 00  	.word	0x00034388
   1ffe8: d8 43 03 00  	.word	0x000343d8
   1ffec: 4c 44 03 00  	.word	0x0003444c
   1fff0: b4 44 03 00  	.word	0x000344b4
   1fff4: f0 37 00 00  	.word	0x000037f0

