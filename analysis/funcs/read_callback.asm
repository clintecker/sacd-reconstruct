00020674 <read_callback>:
   20674: e92d4800     	push	{r11, lr}
   20678: e28db004     	add	r11, sp, #4
   2067c: e24dd028     	sub	sp, sp, #40
   20680: e50b0018     	str	r0, [r11, #-0x18]
   20684: e50b101c     	str	r1, [r11, #-0x1c]
   20688: e50b2020     	str	r2, [r11, #-0x20]
   2068c: e3a03000     	mov	r3, #0
   20690: e50b3010     	str	r3, [r11, #-0x10]
   20694: e51b3018     	ldr	r3, [r11, #-0x18]
   20698: e5933004     	ldr	r3, [r3, #0x4]
   2069c: e50b3008     	str	r3, [r11, #-0x8]
   206a0: e51b301c     	ldr	r3, [r11, #-0x1c]
   206a4: e3530000     	cmp	r3, #0
   206a8: 1a00001f     	bne	0x2072c <read_callback+0xb8> @ imm = #0x7c
   206ac: e51b3020     	ldr	r3, [r11, #-0x20]
   206b0: e3530000     	cmp	r3, #0
   206b4: 03a03000     	moveq	r3, #0
   206b8: 13a03001     	movne	r3, #1
   206bc: e6ef3073     	uxtb	r3, r3
   206c0: e51b2020     	ldr	r2, [r11, #-0x20]
   206c4: e2422001     	sub	r2, r2, #1
   206c8: e50b2020     	str	r2, [r11, #-0x20]
   206cc: e3530000     	cmp	r3, #0
   206d0: 0a00000f     	beq	0x20714 <read_callback+0xa0> @ imm = #0x3c
   206d4: e24b2011     	sub	r2, r11, #17
   206d8: e24b3010     	sub	r3, r11, #16
   206dc: e3a01c01     	mov	r1, #256
   206e0: e58d1000     	str	r1, [sp]
   206e4: e3a01000     	mov	r1, #0
   206e8: e58d1004     	str	r1, [sp, #0x4]
   206ec: e51b0008     	ldr	r0, [r11, #-0x8]
   206f0: e1a01002     	mov	r1, r2
   206f4: e3a02001     	mov	r2, #1
   206f8: ebffca7c     	bl	0x130f0 <socket_recv>   @ imm = #-0xd610
   206fc: e1a03000     	mov	r3, r0
   20700: e3530000     	cmp	r3, #0
   20704: 1a000002     	bne	0x20714 <read_callback+0xa0> @ imm = #0x8
   20708: e51b3010     	ldr	r3, [r11, #-0x10]
   2070c: e3530001     	cmp	r3, #1
   20710: 0affffe5     	beq	0x206ac <read_callback+0x38> @ imm = #-0x6c
   20714: e51b3020     	ldr	r3, [r11, #-0x20]
   20718: e3530000     	cmp	r3, #0
   2071c: 13a03000     	movne	r3, #0
   20720: 03a03001     	moveq	r3, #1
   20724: e6ef3073     	uxtb	r3, r3
   20728: ea00001b     	b	0x2079c <read_callback+0x128> @ imm = #0x6c
   2072c: e24b3010     	sub	r3, r11, #16
   20730: e3a02c01     	mov	r2, #256
   20734: e58d2000     	str	r2, [sp]
   20738: e3a02000     	mov	r2, #0
   2073c: e58d2004     	str	r2, [sp, #0x4]
   20740: e51b0008     	ldr	r0, [r11, #-0x8]
   20744: e51b101c     	ldr	r1, [r11, #-0x1c]
   20748: e51b2020     	ldr	r2, [r11, #-0x20]
   2074c: ebffca67     	bl	0x130f0 <socket_recv>   @ imm = #-0xd664
   20750: e1a03000     	mov	r3, r0
   20754: e50b300c     	str	r3, [r11, #-0xc]
   20758: e51b300c     	ldr	r3, [r11, #-0xc]
   2075c: e3530000     	cmp	r3, #0
   20760: 0a000002     	beq	0x20770 <read_callback+0xfc> @ imm = #0x8
   20764: e51b3018     	ldr	r3, [r11, #-0x18]
   20768: e3a02000     	mov	r2, #0
   2076c: e5832008     	str	r2, [r3, #0x8]
   20770: e51b2010     	ldr	r2, [r11, #-0x10]
   20774: e51b3020     	ldr	r3, [r11, #-0x20]
   20778: e1520003     	cmp	r2, r3
   2077c: 1a000004     	bne	0x20794 <read_callback+0x120> @ imm = #0x10
   20780: e51b300c     	ldr	r3, [r11, #-0xc]
   20784: e3530000     	cmp	r3, #0
   20788: 1a000001     	bne	0x20794 <read_callback+0x120> @ imm = #0x4
   2078c: e3a03001     	mov	r3, #1
   20790: ea000000     	b	0x20798 <read_callback+0x124> @ imm = #0x0
   20794: e3a03000     	mov	r3, #0
   20798: e6ef3073     	uxtb	r3, r3
   2079c: e1a00003     	mov	r0, r3
   207a0: e24bd004     	sub	sp, r11, #4
   207a4: e8bd8800     	pop	{r11, pc}

