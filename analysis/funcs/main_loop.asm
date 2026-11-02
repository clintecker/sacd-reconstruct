0000da5c <main_loop>:
    da5c: e92d4800     	push	{r11, lr}
    da60: e28db004     	add	r11, sp, #4
    da64: e24dd030     	sub	sp, sp, #48
    da68: e3a03000     	mov	r3, #0
    da6c: e50b302c     	str	r3, [r11, #-0x2c]
    da70: e3a03000     	mov	r3, #0
    da74: e50b3024     	str	r3, [r11, #-0x24]
    da78: e59f367c     	ldr	r3, [pc, #0x67c]        @ 0xe0fc <main_loop+0x6a0>
    da7c: e5933000     	ldr	r3, [r3]
    da80: e3530000     	cmp	r3, #0
    da84: 1a000006     	bne	0xdaa4 <main_loop+0x48> @ imm = #0x18
    da88: e59f366c     	ldr	r3, [pc, #0x66c]        @ 0xe0fc <main_loop+0x6a0>
    da8c: e5933004     	ldr	r3, [r3, #0x4]
    da90: e3530000     	cmp	r3, #0
    da94: 1a000002     	bne	0xdaa4 <main_loop+0x48> @ imm = #0x8
    da98: e59f365c     	ldr	r3, [pc, #0x65c]        @ 0xe0fc <main_loop+0x6a0>
    da9c: e3a02001     	mov	r2, #1
    daa0: e5832000     	str	r2, [r3]
    daa4: e59f3650     	ldr	r3, [pc, #0x650]        @ 0xe0fc <main_loop+0x6a0>
    daa8: e5933024     	ldr	r3, [r3, #0x24]
    daac: e1a00003     	mov	r0, r3
    dab0: eb0082ef     	bl	0x2e674 <sacd_open>     @ imm = #0x20bbc
    dab4: e1a03000     	mov	r3, r0
    dab8: e50b3018     	str	r3, [r11, #-0x18]
    dabc: e51b3018     	ldr	r3, [r11, #-0x18]
    dac0: e3530000     	cmp	r3, #0
    dac4: 0a000188     	beq	0xe0ec <main_loop+0x690> @ imm = #0x620
    dac8: e51b0018     	ldr	r0, [r11, #-0x18]
    dacc: e3a01000     	mov	r1, #0
    dad0: eb006f39     	bl	0x297bc <scarletbook_open> @ imm = #0x1bce4
    dad4: e1a02000     	mov	r2, r0
    dad8: e59f3620     	ldr	r3, [pc, #0x620]        @ 0xe100 <main_loop+0x6a4>
    dadc: e5832000     	str	r2, [r3]
    dae0: e59f3618     	ldr	r3, [pc, #0x618]        @ 0xe100 <main_loop+0x6a4>
    dae4: e5933000     	ldr	r3, [r3]
    dae8: e3530000     	cmp	r3, #0
    daec: 0a00017e     	beq	0xe0ec <main_loop+0x690> @ imm = #0x5f8
    daf0: e51b0018     	ldr	r0, [r11, #-0x18]
    daf4: eb008452     	bl	0x2ec44 <sacd_authenticate> @ imm = #0x21148
    daf8: e1a03000     	mov	r3, r0
    dafc: e50b3014     	str	r3, [r11, #-0x14]
    db00: e51b3014     	ldr	r3, [r11, #-0x14]
    db04: e3530000     	cmp	r3, #0
    db08: 0a000007     	beq	0xdb2c <main_loop+0xd0> @ imm = #0x1c
    db0c: e59f35f0     	ldr	r3, [pc, #0x5f0]        @ 0xe104 <main_loop+0x6a8>
    db10: e5933000     	ldr	r3, [r3]
    db14: e5933004     	ldr	r3, [r3, #0x4]
    db18: e3530001     	cmp	r3, #1
    db1c: 9a000002     	bls	0xdb2c <main_loop+0xd0> @ imm = #0x8
    db20: e59f05e0     	ldr	r0, [pc, #0x5e0]        @ 0xe108 <main_loop+0x6ac>
    db24: e51b1014     	ldr	r1, [r11, #-0x14]
    db28: eb001c61     	bl	0x14cb4 <log_print>     @ imm = #0x7184
    db2c: e59f35c8     	ldr	r3, [pc, #0x5c8]        @ 0xe0fc <main_loop+0x6a0>
    db30: e5933020     	ldr	r3, [r3, #0x20]
    db34: e3530000     	cmp	r3, #0
    db38: 0a000003     	beq	0xdb4c <main_loop+0xf0> @ imm = #0xc
    db3c: e59f35bc     	ldr	r3, [pc, #0x5bc]        @ 0xe100 <main_loop+0x6a4>
    db40: e5933000     	ldr	r3, [r3]
    db44: e1a00003     	mov	r0, r3
    db48: eb004a71     	bl	0x20514 <scarletbook_print> @ imm = #0x129c4
    db4c: e59f35a8     	ldr	r3, [pc, #0x5a8]        @ 0xe0fc <main_loop+0x6a0>
    db50: e5933008     	ldr	r3, [r3, #0x8]
    db54: e3530000     	cmp	r3, #0
    db58: 1a00000f     	bne	0xdb9c <main_loop+0x140> @ imm = #0x3c
    db5c: e59f3598     	ldr	r3, [pc, #0x598]        @ 0xe0fc <main_loop+0x6a0>
    db60: e5933014     	ldr	r3, [r3, #0x14]
    db64: e3530000     	cmp	r3, #0
    db68: 1a00000b     	bne	0xdb9c <main_loop+0x140> @ imm = #0x2c
    db6c: e59f3588     	ldr	r3, [pc, #0x588]        @ 0xe0fc <main_loop+0x6a0>
    db70: e5933010     	ldr	r3, [r3, #0x10]
    db74: e3530000     	cmp	r3, #0
    db78: 1a000007     	bne	0xdb9c <main_loop+0x140> @ imm = #0x1c
    db7c: e59f3578     	ldr	r3, [pc, #0x578]        @ 0xe0fc <main_loop+0x6a0>
    db80: e593300c     	ldr	r3, [r3, #0xc]
    db84: e3530000     	cmp	r3, #0
    db88: 1a000003     	bne	0xdb9c <main_loop+0x140> @ imm = #0xc
    db8c: e59f3568     	ldr	r3, [pc, #0x568]        @ 0xe0fc <main_loop+0x6a0>
    db90: e593301c     	ldr	r3, [r3, #0x1c]
    db94: e3530000     	cmp	r3, #0
    db98: 0a00014c     	beq	0xe0d0 <main_loop+0x674> @ imm = #0x530
    db9c: e59f355c     	ldr	r3, [pc, #0x55c]        @ 0xe100 <main_loop+0x6a4>
    dba0: e5933000     	ldr	r3, [r3]
    dba4: e1a00003     	mov	r0, r3
    dba8: e59f155c     	ldr	r1, [pc, #0x55c]        @ 0xe10c <main_loop+0x6b0>
    dbac: e59f255c     	ldr	r2, [pc, #0x55c]        @ 0xe110 <main_loop+0x6b4>
    dbb0: e59f355c     	ldr	r3, [pc, #0x55c]        @ 0xe114 <main_loop+0x6b8>
    dbb4: eb006c20     	bl	0x28c3c <scarletbook_output_create> @ imm = #0x1b080
    dbb8: e1a02000     	mov	r2, r0
    dbbc: e59f3554     	ldr	r3, [pc, #0x554]        @ 0xe118 <main_loop+0x6bc>
    dbc0: e5832000     	str	r2, [r3]
    dbc4: e59f3534     	ldr	r3, [pc, #0x534]        @ 0xe100 <main_loop+0x6a4>
    dbc8: e5933000     	ldr	r3, [r3]
    dbcc: e1a00003     	mov	r0, r3
    dbd0: ebfffd49     	bl	0xd0fc <has_multi_channel> @ imm = #-0xadc
    dbd4: e1a03000     	mov	r3, r0
    dbd8: e3530000     	cmp	r3, #0
    dbdc: 0a000003     	beq	0xdbf0 <main_loop+0x194> @ imm = #0xc
    dbe0: e59f3514     	ldr	r3, [pc, #0x514]        @ 0xe0fc <main_loop+0x6a0>
    dbe4: e5933004     	ldr	r3, [r3, #0x4]
    dbe8: e3530000     	cmp	r3, #0
    dbec: 1a000006     	bne	0xdc0c <main_loop+0x1b0> @ imm = #0x18
    dbf0: e59f3508     	ldr	r3, [pc, #0x508]        @ 0xe100 <main_loop+0x6a4>
    dbf4: e5933000     	ldr	r3, [r3]
    dbf8: e1a00003     	mov	r0, r3
    dbfc: ebfffd31     	bl	0xd0c8 <has_two_channel> @ imm = #-0xb3c
    dc00: e1a03000     	mov	r3, r0
    dc04: e3530000     	cmp	r3, #0
    dc08: 1a000003     	bne	0xdc1c <main_loop+0x1c0> @ imm = #0xc
    dc0c: e59f34ec     	ldr	r3, [pc, #0x4ec]        @ 0xe100 <main_loop+0x6a4>
    dc10: e5933000     	ldr	r3, [r3]
    dc14: e5933054     	ldr	r3, [r3, #0x54]
    dc18: ea000002     	b	0xdc28 <main_loop+0x1cc> @ imm = #0x8
    dc1c: e59f34dc     	ldr	r3, [pc, #0x4dc]        @ 0xe100 <main_loop+0x6a4>
    dc20: e5933000     	ldr	r3, [r3]
    dc24: e5933050     	ldr	r3, [r3, #0x50]
    dc28: e50b301c     	str	r3, [r11, #-0x1c]
    dc2c: e59f34e8     	ldr	r3, [pc, #0x4e8]        @ 0xe11c <main_loop+0x6c0>
    dc30: e5d33000     	ldrb	r3, [r3]
    dc34: e3530000     	cmp	r3, #0
    dc38: 0a000003     	beq	0xdc4c <main_loop+0x1f0> @ imm = #0xc
    dc3c: e59f04d8     	ldr	r0, [pc, #0x4d8]        @ 0xe11c <main_loop+0x6c0>
    dc40: ebfffa82     	bl	0xc650 <strdup@plt>     @ imm = #-0x15f8
    dc44: e1a03000     	mov	r3, r0
    dc48: ea000004     	b	0xdc60 <main_loop+0x204> @ imm = #0x10
    dc4c: e59f34ac     	ldr	r3, [pc, #0x4ac]        @ 0xe100 <main_loop+0x6a4>
    dc50: e5933000     	ldr	r3, [r3]
    dc54: e1a00003     	mov	r0, r3
    dc58: eb006c81     	bl	0x28e64 <get_album_dir> @ imm = #0x1b204
    dc5c: e1a03000     	mov	r3, r0
    dc60: e50b302c     	str	r3, [r11, #-0x2c]
    dc64: e59f3490     	ldr	r3, [pc, #0x490]        @ 0xe0fc <main_loop+0x6a0>
    dc68: e5933014     	ldr	r3, [r3, #0x14]
    dc6c: e3530000     	cmp	r3, #0
    dc70: 0a00001a     	beq	0xdce0 <main_loop+0x284> @ imm = #0x68
    dc74: e51b0018     	ldr	r0, [r11, #-0x18]
    dc78: eb00841f     	bl	0x2ecfc <sacd_get_total_sectors> @ imm = #0x2107c
    dc7c: e1a03000     	mov	r3, r0
    dc80: e50b3010     	str	r3, [r11, #-0x10]
    dc84: e24b302c     	sub	r3, r11, #44
    dc88: e1a00003     	mov	r0, r3
    dc8c: e59f148c     	ldr	r1, [pc, #0x48c]        @ 0xe120 <main_loop+0x6c4>
    dc90: eb000cef     	bl	0x11054 <get_unique_filename> @ imm = #0x33bc
    dc94: e51b302c     	ldr	r3, [r11, #-0x2c]
    dc98: e3a00000     	mov	r0, #0
    dc9c: e3a01000     	mov	r1, #0
    dca0: e1a02003     	mov	r2, r3
    dca4: e59f3474     	ldr	r3, [pc, #0x474]        @ 0xe120 <main_loop+0x6c4>
    dca8: eb0009d4     	bl	0x10400 <make_filename> @ imm = #0x2750
    dcac: e1a03000     	mov	r3, r0
    dcb0: e50b3024     	str	r3, [r11, #-0x24]
    dcb4: e59f345c     	ldr	r3, [pc, #0x45c]        @ 0xe118 <main_loop+0x6bc>
    dcb8: e5932000     	ldr	r2, [r3]
    dcbc: e51b3010     	ldr	r3, [r11, #-0x10]
    dcc0: e59f1458     	ldr	r1, [pc, #0x458]        @ 0xe120 <main_loop+0x6c4>
    dcc4: e58d1000     	str	r1, [sp]
    dcc8: e1a00002     	mov	r0, r2
    dccc: e3a01000     	mov	r1, #0
    dcd0: e1a02003     	mov	r2, r3
    dcd4: e51b3024     	ldr	r3, [r11, #-0x24]
    dcd8: eb006886     	bl	0x27ef8 <scarletbook_output_enqueue_raw_sectors> @ imm = #0x1a218
    dcdc: ea0000b1     	b	0xdfa8 <main_loop+0x54c> @ imm = #0x2c4
    dce0: e59f3414     	ldr	r3, [pc, #0x414]        @ 0xe0fc <main_loop+0x6a0>
    dce4: e593300c     	ldr	r3, [r3, #0xc]
    dce8: e3530000     	cmp	r3, #0
    dcec: 0a00002a     	beq	0xdd9c <main_loop+0x340> @ imm = #0xa8
    dcf0: e24b302c     	sub	r3, r11, #44
    dcf4: e1a00003     	mov	r0, r3
    dcf8: e59f1424     	ldr	r1, [pc, #0x424]        @ 0xe124 <main_loop+0x6c8>
    dcfc: eb000cd4     	bl	0x11054 <get_unique_filename> @ imm = #0x3350
    dd00: e51b302c     	ldr	r3, [r11, #-0x2c]
    dd04: e3a00000     	mov	r0, #0
    dd08: e3a01000     	mov	r1, #0
    dd0c: e1a02003     	mov	r2, r3
    dd10: e59f340c     	ldr	r3, [pc, #0x40c]        @ 0xe124 <main_loop+0x6c8>
    dd14: eb0009b9     	bl	0x10400 <make_filename> @ imm = #0x26e4
    dd18: e1a03000     	mov	r3, r0
    dd1c: e50b3024     	str	r3, [r11, #-0x24]
    dd20: e59f33f0     	ldr	r3, [pc, #0x3f0]        @ 0xe118 <main_loop+0x6bc>
    dd24: e5932000     	ldr	r2, [r3]
    dd28: e59f33cc     	ldr	r3, [pc, #0x3cc]        @ 0xe0fc <main_loop+0x6a0>
    dd2c: e5933018     	ldr	r3, [r3, #0x18]
    dd30: e3530000     	cmp	r3, #0
    dd34: 1a00000c     	bne	0xdd6c <main_loop+0x310> @ imm = #0x30
    dd38: e59f33c0     	ldr	r3, [pc, #0x3c0]        @ 0xe100 <main_loop+0x6a4>
    dd3c: e5930000     	ldr	r0, [r3]
    dd40: e51b101c     	ldr	r1, [r11, #-0x1c]
    dd44: e3a03060     	mov	r3, #96
    dd48: e59fc3d8     	ldr	r12, [pc, #0x3d8]       @ 0xe128 <main_loop+0x6cc>
    dd4c: e001019c     	mul	r1, r12, r1
    dd50: e0801001     	add	r1, r0, r1
    dd54: e0813003     	add	r3, r1, r3
    dd58: e5933000     	ldr	r3, [r3]
    dd5c: e5d33015     	ldrb	r3, [r3, #0x15]
    dd60: e203300f     	and	r3, r3, #15
    dd64: e3530000     	cmp	r3, #0
    dd68: 0a000001     	beq	0xdd74 <main_loop+0x318> @ imm = #0x4
    dd6c: e3a03001     	mov	r3, #1
    dd70: ea000000     	b	0xdd78 <main_loop+0x31c> @ imm = #0x0
    dd74: e3a03000     	mov	r3, #0
    dd78: e59f13ac     	ldr	r1, [pc, #0x3ac]        @ 0xe12c <main_loop+0x6d0>
    dd7c: e58d1000     	str	r1, [sp]
    dd80: e58d3004     	str	r3, [sp, #0x4]
    dd84: e1a00002     	mov	r0, r2
    dd88: e51b101c     	ldr	r1, [r11, #-0x1c]
    dd8c: e3a02000     	mov	r2, #0
    dd90: e51b3024     	ldr	r3, [r11, #-0x24]
    dd94: eb006715     	bl	0x279f0 <scarletbook_output_enqueue_track> @ imm = #0x19c54
    dd98: ea000082     	b	0xdfa8 <main_loop+0x54c> @ imm = #0x208
    dd9c: e59f3358     	ldr	r3, [pc, #0x358]        @ 0xe0fc <main_loop+0x6a0>
    dda0: e5933008     	ldr	r3, [r3, #0x8]
    dda4: e3530000     	cmp	r3, #0
    dda8: 1a000003     	bne	0xddbc <main_loop+0x360> @ imm = #0xc
    ddac: e59f3348     	ldr	r3, [pc, #0x348]        @ 0xe0fc <main_loop+0x6a0>
    ddb0: e5933010     	ldr	r3, [r3, #0x10]
    ddb4: e3530000     	cmp	r3, #0
    ddb8: 0a00007a     	beq	0xdfa8 <main_loop+0x54c> @ imm = #0x1e8
    ddbc: e24b302c     	sub	r3, r11, #44
    ddc0: e3a00000     	mov	r0, #0
    ddc4: e1a01003     	mov	r1, r3
    ddc8: eb000cfc     	bl	0x111c0 <get_unique_dir> @ imm = #0x33f0
    ddcc: e51b302c     	ldr	r3, [r11, #-0x2c]
    ddd0: e1a00003     	mov	r0, r3
    ddd4: e3a01f7f     	mov	r1, #508
    ddd8: eb000c0c     	bl	0x10e10 <recursive_mkdir> @ imm = #0x3030
    dddc: e3a03000     	mov	r3, #0
    dde0: e50b3020     	str	r3, [r11, #-0x20]
    dde4: ea000061     	b	0xdf70 <main_loop+0x514> @ imm = #0x184
    dde8: e59f330c     	ldr	r3, [pc, #0x30c]        @ 0xe0fc <main_loop+0x6a0>
    ddec: e5933228     	ldr	r3, [r3, #0x228]
    ddf0: e3530000     	cmp	r3, #0
    ddf4: 0a000007     	beq	0xde18 <main_loop+0x3bc> @ imm = #0x1c
    ddf8: e51b2020     	ldr	r2, [r11, #-0x20]
    ddfc: e59f12f8     	ldr	r1, [pc, #0x2f8]        @ 0xe0fc <main_loop+0x6a0>
    de00: e3a03f8a     	mov	r3, #552
    de04: e0812002     	add	r2, r1, r2
    de08: e0823003     	add	r3, r2, r3
    de0c: e5d33004     	ldrb	r3, [r3, #0x4]
    de10: e3530000     	cmp	r3, #0
    de14: 0a000051     	beq	0xdf60 <main_loop+0x504> @ imm = #0x144
    de18: e59f32e0     	ldr	r3, [pc, #0x2e0]        @ 0xe100 <main_loop+0x6a4>
    de1c: e5933000     	ldr	r3, [r3]
    de20: e1a00003     	mov	r0, r3
    de24: e51b101c     	ldr	r1, [r11, #-0x1c]
    de28: e51b2020     	ldr	r2, [r11, #-0x20]
    de2c: e59f32e8     	ldr	r3, [pc, #0x2e8]        @ 0xe11c <main_loop+0x6c0>
    de30: eb006cf2     	bl	0x29200 <get_music_filename> @ imm = #0x1b3c8
    de34: e1a03000     	mov	r3, r0
    de38: e50b3028     	str	r3, [r11, #-0x28]
    de3c: e59f32b8     	ldr	r3, [pc, #0x2b8]        @ 0xe0fc <main_loop+0x6a0>
    de40: e5933008     	ldr	r3, [r3, #0x8]
    de44: e3530000     	cmp	r3, #0
    de48: 0a000013     	beq	0xde9c <main_loop+0x440> @ imm = #0x4c
    de4c: e51b302c     	ldr	r3, [r11, #-0x2c]
    de50: e3a00000     	mov	r0, #0
    de54: e1a01003     	mov	r1, r3
    de58: e51b2028     	ldr	r2, [r11, #-0x28]
    de5c: e59f32cc     	ldr	r3, [pc, #0x2cc]        @ 0xe130 <main_loop+0x6d4>
    de60: eb000966     	bl	0x10400 <make_filename> @ imm = #0x2598
    de64: e1a03000     	mov	r3, r0
    de68: e50b3024     	str	r3, [r11, #-0x24]
    de6c: e59f32a4     	ldr	r3, [pc, #0x2a4]        @ 0xe118 <main_loop+0x6bc>
    de70: e5933000     	ldr	r3, [r3]
    de74: e59f22b4     	ldr	r2, [pc, #0x2b4]        @ 0xe130 <main_loop+0x6d4>
    de78: e58d2000     	str	r2, [sp]
    de7c: e3a02001     	mov	r2, #1
    de80: e58d2004     	str	r2, [sp, #0x4]
    de84: e1a00003     	mov	r0, r3
    de88: e51b101c     	ldr	r1, [r11, #-0x1c]
    de8c: e51b2020     	ldr	r2, [r11, #-0x20]
    de90: e51b3024     	ldr	r3, [r11, #-0x24]
    de94: eb0066d5     	bl	0x279f0 <scarletbook_output_enqueue_track> @ imm = #0x19b54
    de98: ea000029     	b	0xdf44 <main_loop+0x4e8> @ imm = #0xa4
    de9c: e59f3258     	ldr	r3, [pc, #0x258]        @ 0xe0fc <main_loop+0x6a0>
    dea0: e5933010     	ldr	r3, [r3, #0x10]
    dea4: e3530000     	cmp	r3, #0
    dea8: 0a000025     	beq	0xdf44 <main_loop+0x4e8> @ imm = #0x94
    deac: e51b302c     	ldr	r3, [r11, #-0x2c]
    deb0: e3a00000     	mov	r0, #0
    deb4: e1a01003     	mov	r1, r3
    deb8: e51b2028     	ldr	r2, [r11, #-0x28]
    debc: e59f3260     	ldr	r3, [pc, #0x260]        @ 0xe124 <main_loop+0x6c8>
    dec0: eb00094e     	bl	0x10400 <make_filename> @ imm = #0x2538
    dec4: e1a03000     	mov	r3, r0
    dec8: e50b3024     	str	r3, [r11, #-0x24]
    decc: e59f3244     	ldr	r3, [pc, #0x244]        @ 0xe118 <main_loop+0x6bc>
    ded0: e5932000     	ldr	r2, [r3]
    ded4: e59f3220     	ldr	r3, [pc, #0x220]        @ 0xe0fc <main_loop+0x6a0>
    ded8: e5933018     	ldr	r3, [r3, #0x18]
    dedc: e3530000     	cmp	r3, #0
    dee0: 1a00000c     	bne	0xdf18 <main_loop+0x4bc> @ imm = #0x30
    dee4: e59f3214     	ldr	r3, [pc, #0x214]        @ 0xe100 <main_loop+0x6a4>
    dee8: e5930000     	ldr	r0, [r3]
    deec: e51b101c     	ldr	r1, [r11, #-0x1c]
    def0: e3a03060     	mov	r3, #96
    def4: e59fc22c     	ldr	r12, [pc, #0x22c]       @ 0xe128 <main_loop+0x6cc>
    def8: e001019c     	mul	r1, r12, r1
    defc: e0801001     	add	r1, r0, r1
    df00: e0813003     	add	r3, r1, r3
    df04: e5933000     	ldr	r3, [r3]
    df08: e5d33015     	ldrb	r3, [r3, #0x15]
    df0c: e203300f     	and	r3, r3, #15
    df10: e3530000     	cmp	r3, #0
    df14: 0a000001     	beq	0xdf20 <main_loop+0x4c4> @ imm = #0x4
    df18: e3a03001     	mov	r3, #1
    df1c: ea000000     	b	0xdf24 <main_loop+0x4c8> @ imm = #0x0
    df20: e3a03000     	mov	r3, #0
    df24: e59f1208     	ldr	r1, [pc, #0x208]        @ 0xe134 <main_loop+0x6d8>
    df28: e58d1000     	str	r1, [sp]
    df2c: e58d3004     	str	r3, [sp, #0x4]
    df30: e1a00002     	mov	r0, r2
    df34: e51b101c     	ldr	r1, [r11, #-0x1c]
    df38: e51b2020     	ldr	r2, [r11, #-0x20]
    df3c: e51b3024     	ldr	r3, [r11, #-0x24]
    df40: eb0066aa     	bl	0x279f0 <scarletbook_output_enqueue_track> @ imm = #0x19aa8
    df44: e51b0028     	ldr	r0, [r11, #-0x28]
    df48: ebfff933     	bl	0xc41c <free@plt>       @ imm = #-0x1b34
    df4c: e51b0024     	ldr	r0, [r11, #-0x24]
    df50: ebfff931     	bl	0xc41c <free@plt>       @ imm = #-0x1b3c
    df54: e3a03000     	mov	r3, #0
    df58: e50b3024     	str	r3, [r11, #-0x24]
    df5c: ea000000     	b	0xdf64 <main_loop+0x508> @ imm = #0x0
    df60: e1a00000     	mov	r0, r0
    df64: e51b3020     	ldr	r3, [r11, #-0x20]
    df68: e2833001     	add	r3, r3, #1
    df6c: e50b3020     	str	r3, [r11, #-0x20]
    df70: e59f3188     	ldr	r3, [pc, #0x188]        @ 0xe100 <main_loop+0x6a4>
    df74: e5931000     	ldr	r1, [r3]
    df78: e51b201c     	ldr	r2, [r11, #-0x1c]
    df7c: e3a03060     	mov	r3, #96
    df80: e59f01a0     	ldr	r0, [pc, #0x1a0]        @ 0xe128 <main_loop+0x6cc>
    df84: e0020290     	mul	r2, r0, r2
    df88: e0812002     	add	r2, r1, r2
    df8c: e0823003     	add	r3, r2, r3
    df90: e5933000     	ldr	r3, [r3]
    df94: e5d33045     	ldrb	r3, [r3, #0x45]
    df98: e1a02003     	mov	r2, r3
    df9c: e51b3020     	ldr	r3, [r11, #-0x20]
    dfa0: e1520003     	cmp	r2, r3
    dfa4: caffff8f     	bgt	0xdde8 <main_loop+0x38c> @ imm = #-0x1c4
    dfa8: e59f314c     	ldr	r3, [pc, #0x14c]        @ 0xe0fc <main_loop+0x6a0>
    dfac: e593301c     	ldr	r3, [r3, #0x1c]
    dfb0: e3530000     	cmp	r3, #0
    dfb4: 0a00002f     	beq	0xe078 <main_loop+0x61c> @ imm = #0xbc
    dfb8: e51b302c     	ldr	r3, [r11, #-0x2c]
    dfbc: e3a00000     	mov	r0, #0
    dfc0: e3a01000     	mov	r1, #0
    dfc4: e1a02003     	mov	r2, r3
    dfc8: e59f3168     	ldr	r3, [pc, #0x168]        @ 0xe138 <main_loop+0x6dc>
    dfcc: eb00090b     	bl	0x10400 <make_filename> @ imm = #0x242c
    dfd0: e1a03000     	mov	r3, r0
    dfd4: e50b300c     	str	r3, [r11, #-0xc]
    dfd8: e51b000c     	ldr	r0, [r11, #-0xc]
    dfdc: ebfff93e     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1b08
    dfe0: e1a03000     	mov	r3, r0
    dfe4: e51b000c     	ldr	r0, [r11, #-0xc]
    dfe8: e1a01003     	mov	r1, r3
    dfec: e59f2148     	ldr	r2, [pc, #0x148]        @ 0xe13c <main_loop+0x6e0>
    dff0: e59f3148     	ldr	r3, [pc, #0x148]        @ 0xe140 <main_loop+0x6e4>
    dff4: eb00013e     	bl	0xe4f4 <charset_convert> @ imm = #0x4f8
    dff8: e1a03000     	mov	r3, r0
    dffc: e50b3008     	str	r3, [r11, #-0x8]
    e000: e59f313c     	ldr	r3, [pc, #0x13c]        @ 0xe144 <main_loop+0x6e8>
    e004: e5933000     	ldr	r3, [r3]
    e008: e1a02003     	mov	r2, r3
    e00c: e59f3134     	ldr	r3, [pc, #0x134]        @ 0xe148 <main_loop+0x6ec>
    e010: e1a00002     	mov	r0, r2
    e014: e1a01003     	mov	r1, r3
    e018: e51b2008     	ldr	r2, [r11, #-0x8]
    e01c: ebfff9b8     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x1920
    e020: e51b3024     	ldr	r3, [r11, #-0x24]
    e024: e3530000     	cmp	r3, #0
    e028: 1a000007     	bne	0xe04c <main_loop+0x5f0> @ imm = #0x1c
    e02c: e51b302c     	ldr	r3, [r11, #-0x2c]
    e030: e3a00000     	mov	r0, #0
    e034: e3a01000     	mov	r1, #0
    e038: e1a02003     	mov	r2, r3
    e03c: e59f30e0     	ldr	r3, [pc, #0xe0]         @ 0xe124 <main_loop+0x6c8>
    e040: eb0008ee     	bl	0x10400 <make_filename> @ imm = #0x23b8
    e044: e1a03000     	mov	r3, r0
    e048: e50b3024     	str	r3, [r11, #-0x24]
    e04c: e59f30ac     	ldr	r3, [pc, #0xac]         @ 0xe100 <main_loop+0x6a4>
    e050: e5933000     	ldr	r3, [r3]
    e054: e1a00003     	mov	r0, r3
    e058: e51b1024     	ldr	r1, [r11, #-0x24]
    e05c: e51b201c     	ldr	r2, [r11, #-0x1c]
    e060: e51b300c     	ldr	r3, [r11, #-0xc]
    e064: eb004ce4     	bl	0x213fc <write_cue_sheet> @ imm = #0x13390
    e068: e51b000c     	ldr	r0, [r11, #-0xc]
    e06c: ebfff8ea     	bl	0xc41c <free@plt>       @ imm = #-0x1c58
    e070: e51b0008     	ldr	r0, [r11, #-0x8]
    e074: ebfff8e8     	bl	0xc41c <free@plt>       @ imm = #-0x1c60
    e078: e51b0024     	ldr	r0, [r11, #-0x24]
    e07c: ebfff8e6     	bl	0xc41c <free@plt>       @ imm = #-0x1c68
    e080: e3a00000     	mov	r0, #0
    e084: ebfff962     	bl	0xc614 <time@plt>       @ imm = #-0x1a78
    e088: e1a02000     	mov	r2, r0
    e08c: e59f30b8     	ldr	r3, [pc, #0xb8]         @ 0xe14c <main_loop+0x6f0>
    e090: e5832000     	str	r2, [r3]
    e094: e59f307c     	ldr	r3, [pc, #0x7c]         @ 0xe118 <main_loop+0x6bc>
    e098: e5933000     	ldr	r3, [r3]
    e09c: e1a00003     	mov	r0, r3
    e0a0: eb006b15     	bl	0x28cfc <scarletbook_output_start> @ imm = #0x1ac54
    e0a4: e59f306c     	ldr	r3, [pc, #0x6c]         @ 0xe118 <main_loop+0x6bc>
    e0a8: e5933000     	ldr	r3, [r3]
    e0ac: e1a00003     	mov	r0, r3
    e0b0: eb006b3e     	bl	0x28db0 <scarletbook_output_destroy> @ imm = #0x1acf8
    e0b4: e59f2094     	ldr	r2, [pc, #0x94]         @ 0xe150 <main_loop+0x6f4>
    e0b8: e59f3084     	ldr	r3, [pc, #0x84]         @ 0xe144 <main_loop+0x6e8>
    e0bc: e5933000     	ldr	r3, [r3]
    e0c0: e1a00002     	mov	r0, r2
    e0c4: e3a01001     	mov	r1, #1
    e0c8: e3a02049     	mov	r2, #73
    e0cc: ebfff947     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x1ae4
    e0d0: e59f3028     	ldr	r3, [pc, #0x28]         @ 0xe100 <main_loop+0x6a4>
    e0d4: e5933000     	ldr	r3, [r3]
    e0d8: e1a00003     	mov	r0, r3
    e0dc: eb006fa9     	bl	0x29f88 <scarletbook_close> @ imm = #0x1bea4
    e0e0: e51b302c     	ldr	r3, [r11, #-0x2c]
    e0e4: e1a00003     	mov	r0, r3
    e0e8: ebfff8cb     	bl	0xc41c <free@plt>       @ imm = #-0x1cd4
    e0ec: e51b0018     	ldr	r0, [r11, #-0x18]
    e0f0: eb00826d     	bl	0x2eaac <sacd_close>    @ imm = #0x209b4
    e0f4: e24bd004     	sub	sp, r11, #4
    e0f8: e8bd8800     	pop	{r11, pc}
    e0fc: 0c 6e 05 00  	.word	0x00056e0c
    e100: f4 9d 05 00  	.word	0x00059df4
    e104: 5c 73 05 00  	.word	0x0005735c
    e108: 64 1c 03 00  	.word	0x00031c64
    e10c: d8 d6 00 00  	.word	0x0000d6d8
    e110: 5c d7 00 00  	.word	0x0000d75c
    e114: fc d5 00 00  	.word	0x0000d5fc
    e118: f8 9d 05 00  	.word	0x00059df8
    e11c: 34 6e 05 00  	.word	0x00056e34
    e120: 80 1c 03 00  	.word	0x00031c80
    e124: 84 1c 03 00  	.word	0x00031c84
    e128: f0 37 00 00  	.word	0x000037f0
    e12c: 88 1c 03 00  	.word	0x00031c88
    e130: 9c 1c 03 00  	.word	0x00031c9c
    e134: a0 1c 03 00  	.word	0x00031ca0
    e138: a8 1c 03 00  	.word	0x00031ca8
    e13c: dc 1a 03 00  	.word	0x00031adc
    e140: e4 1a 03 00  	.word	0x00031ae4
    e144: f4 6d 05 00  	.word	0x00056df4
    e148: ac 1c 03 00  	.word	0x00031cac
    e14c: 40 71 05 00  	.word	0x00057140
    e150: 18 1d 03 00  	.word	0x00031d18

