0000e2d8 <main>:
    e2d8: e92d4800     	push	{r11, lr}
    e2dc: e28db004     	add	r11, sp, #4
    e2e0: e24dd010     	sub	sp, sp, #16
    e2e4: e50b0010     	str	r0, [r11, #-0x10]
    e2e8: e50b1014     	str	r1, [r11, #-0x14]
    e2ec: ebfffda1     	bl	0xd978 <init>           @ imm = #-0x97c
    e2f0: e51b0010     	ldr	r0, [r11, #-0x10]
    e2f4: e51b1014     	ldr	r1, [r11, #-0x14]
    e2f8: ebfffb8c     	bl	0xd130 <parse_options>  @ imm = #-0x11d0
    e2fc: e1a03000     	mov	r3, r0
    e300: e3530000     	cmp	r3, #0
    e304: 0a000051     	beq	0xe450 <main+0x178>     @ imm = #0x144
    e308: eb008598     	bl	0x2f970 <install_modules> @ imm = #0x21660
    e30c: e1a03000     	mov	r3, r0
    e310: e3530000     	cmp	r3, #0
    e314: ba000046     	blt	0xe434 <main+0x15c>     @ imm = #0x118
    e318: e3a00006     	mov	r0, #6
    e31c: e59f1158     	ldr	r1, [pc, #0x158]        @ 0xe47c <main+0x1a4>
    e320: ebfff87c     	bl	0xc518 <setlocale@plt>  @ imm = #-0x1e10
    e324: e59f3154     	ldr	r3, [pc, #0x154]        @ 0xe480 <main+0x1a8>
    e328: e5933000     	ldr	r3, [r3]
    e32c: e1a00003     	mov	r0, r3
    e330: e3a01001     	mov	r1, #1
    e334: ebfff7db     	bl	0xc2a8 <fwide@plt>      @ imm = #-0x2094
    e338: e1a03000     	mov	r3, r0
    e33c: e3530000     	cmp	r3, #0
    e340: aa000006     	bge	0xe360 <main+0x88>      @ imm = #0x18
    e344: e59f2138     	ldr	r2, [pc, #0x138]        @ 0xe484 <main+0x1ac>
    e348: e59f3138     	ldr	r3, [pc, #0x138]        @ 0xe488 <main+0x1b0>
    e34c: e5933000     	ldr	r3, [r3]
    e350: e1a00002     	mov	r0, r2
    e354: e3a01001     	mov	r1, #1
    e358: e3a0201f     	mov	r2, #31
    e35c: ebfff8a3     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x1d74
    e360: e59f3124     	ldr	r3, [pc, #0x124]        @ 0xe48c <main+0x1b4>
    e364: e593332c     	ldr	r3, [r3, #0x32c]
    e368: e3530000     	cmp	r3, #0
    e36c: 0a000015     	beq	0xe3c8 <main+0xf0>      @ imm = #0x54
    e370: e24b300c     	sub	r3, r11, #12
    e374: e1a00003     	mov	r0, r3
    e378: e3a01000     	mov	r1, #0
    e37c: e59f210c     	ldr	r2, [pc, #0x10c]        @ 0xe490 <main+0x1b8>
    e380: e3a03000     	mov	r3, #0
    e384: ebfff85d     	bl	0xc500 <pthread_create@plt> @ imm = #-0x1e8c
    e388: e1a03000     	mov	r3, r0
    e38c: e50b3008     	str	r3, [r11, #-0x8]
    e390: e51b3008     	ldr	r3, [r11, #-0x8]
    e394: e3530000     	cmp	r3, #0
    e398: 0a000008     	beq	0xe3c0 <main+0xe8>      @ imm = #0x20
    e39c: e59f30f0     	ldr	r3, [pc, #0xf0]         @ 0xe494 <main+0x1bc>
    e3a0: e5933000     	ldr	r3, [r3]
    e3a4: e5933004     	ldr	r3, [r3, #0x4]
    e3a8: e3530001     	cmp	r3, #1
    e3ac: 9a000007     	bls	0xe3d0 <main+0xf8>      @ imm = #0x1c
    e3b0: e59f00e0     	ldr	r0, [pc, #0xe0]         @ 0xe498 <main+0x1c0>
    e3b4: e51b1008     	ldr	r1, [r11, #-0x8]
    e3b8: eb001a3d     	bl	0x14cb4 <log_print>     @ imm = #0x68f4
    e3bc: ea000004     	b	0xe3d4 <main+0xfc>      @ imm = #0x10
    e3c0: ebffff7b     	bl	0xe1b4 <server_loop>    @ imm = #-0x214
    e3c4: ea000002     	b	0xe3d4 <main+0xfc>      @ imm = #0x8
    e3c8: ebfffda3     	bl	0xda5c <main_loop>      @ imm = #-0x974
    e3cc: ea000000     	b	0xe3d4 <main+0xfc>      @ imm = #0x0
    e3d0: e1a00000     	mov	r0, r0
    e3d4: e59f20c0     	ldr	r2, [pc, #0xc0]         @ 0xe49c <main+0x1c4>
    e3d8: e59f30a0     	ldr	r3, [pc, #0xa0]         @ 0xe480 <main+0x1a8>
    e3dc: e5933000     	ldr	r3, [r3]
    e3e0: e3a00000     	mov	r0, #0
    e3e4: e1a01002     	mov	r1, r2
    e3e8: e1a02003     	mov	r2, r3
    e3ec: ebfff8a0     	bl	0xc674 <freopen64@plt>  @ imm = #-0x1d80
    e3f0: e59f3088     	ldr	r3, [pc, #0x88]         @ 0xe480 <main+0x1a8>
    e3f4: e5933000     	ldr	r3, [r3]
    e3f8: e1a00003     	mov	r0, r3
    e3fc: e3e01000     	mvn	r1, #0
    e400: ebfff7a8     	bl	0xc2a8 <fwide@plt>      @ imm = #-0x2160
    e404: e1a03000     	mov	r3, r0
    e408: e3530000     	cmp	r3, #0
    e40c: ba000006     	blt	0xe42c <main+0x154>     @ imm = #0x18
    e410: e59f2088     	ldr	r2, [pc, #0x88]         @ 0xe4a0 <main+0x1c8>
    e414: e59f306c     	ldr	r3, [pc, #0x6c]         @ 0xe488 <main+0x1b0>
    e418: e5933000     	ldr	r3, [r3]
    e41c: e1a00002     	mov	r0, r2
    e420: e3a01001     	mov	r1, #1
    e424: e3a02028     	mov	r2, #40
    e428: ebfff870     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x1e40
    e42c: eb0085c3     	bl	0x2fb40 <remove_modules> @ imm = #0x2170c
    e430: ea000006     	b	0xe450 <main+0x178>     @ imm = #0x18
    e434: e59f3058     	ldr	r3, [pc, #0x58]         @ 0xe494 <main+0x1bc>
    e438: e5933000     	ldr	r3, [r3]
    e43c: e5933004     	ldr	r3, [r3, #0x4]
    e440: e3530001     	cmp	r3, #1
    e444: 9a000001     	bls	0xe450 <main+0x178>     @ imm = #0x4
    e448: e59f0054     	ldr	r0, [pc, #0x54]         @ 0xe4a4 <main+0x1cc>
    e44c: eb001a18     	bl	0x14cb4 <log_print>     @ imm = #0x6860
    e450: e59f3050     	ldr	r3, [pc, #0x50]         @ 0xe4a8 <main+0x1d0>
    e454: e5933000     	ldr	r3, [r3]
    e458: e1a00003     	mov	r0, r3
    e45c: eb001d83     	bl	0x15a70 <free_lock>     @ imm = #0x760c
    e460: eb001b91     	bl	0x152ac <destroy_logging> @ imm = #0x6e44
    e464: e3a0000a     	mov	r0, #10
    e468: ebfff7b2     	bl	0xc338 <putchar@plt>    @ imm = #-0x2138
    e46c: e3a03000     	mov	r3, #0
    e470: e1a00003     	mov	r0, r3
    e474: e24bd004     	sub	sp, r11, #4
    e478: e8bd8800     	pop	{r11, pc}
    e47c: 5c 1f 03 00  	.word	0x00031f5c
    e480: f4 6d 05 00  	.word	0x00056df4
    e484: 60 1f 03 00  	.word	0x00031f60
    e488: f8 6d 05 00  	.word	0x00056df8
    e48c: 0c 6e 05 00  	.word	0x00056e0c
    e490: ac cf 00 00  	.word	0x0000cfac
    e494: 5c 73 05 00  	.word	0x0005735c
    e498: 80 1f 03 00  	.word	0x00031f80
    e49c: b4 1f 03 00  	.word	0x00031fb4
    e4a0: b8 1f 03 00  	.word	0x00031fb8
    e4a4: e4 1f 03 00  	.word	0x00031fe4
    e4a8: 3c 71 05 00  	.word	0x0005713c

