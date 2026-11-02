00010400 <make_filename>:
   10400: e92d4830     	push	{r4, r5, r11, lr}
   10404: e28db00c     	add	r11, sp, #12
   10408: e24dd028     	sub	sp, sp, #40
   1040c: e50b0028     	str	r0, [r11, #-0x28]
   10410: e50b102c     	str	r1, [r11, #-0x2c]
   10414: e50b2030     	str	r2, [r11, #-0x30]
   10418: e50b3034     	str	r3, [r11, #-0x34]
   1041c: e3a03001     	mov	r3, #1
   10420: e50b3020     	str	r3, [r11, #-0x20]
   10424: e3a03000     	mov	r3, #0
   10428: e50b301c     	str	r3, [r11, #-0x1c]
   1042c: e3a03000     	mov	r3, #0
   10430: e50b3018     	str	r3, [r11, #-0x18]
   10434: e51b3028     	ldr	r3, [r11, #-0x28]
   10438: e3530000     	cmp	r3, #0
   1043c: 0a000007     	beq	0x10460 <make_filename+0x60> @ imm = #0x1c
   10440: e51b0028     	ldr	r0, [r11, #-0x28]
   10444: ebfff024     	bl	0xc4dc <strlen@plt>     @ imm = #-0x3f70
   10448: e1a03000     	mov	r3, r0
   1044c: e1a02003     	mov	r2, r3
   10450: e51b3020     	ldr	r3, [r11, #-0x20]
   10454: e0823003     	add	r3, r2, r3
   10458: e2833001     	add	r3, r3, #1
   1045c: e50b3020     	str	r3, [r11, #-0x20]
   10460: e51b302c     	ldr	r3, [r11, #-0x2c]
   10464: e3530000     	cmp	r3, #0
   10468: 0a000006     	beq	0x10488 <make_filename+0x88> @ imm = #0x18
   1046c: e51b002c     	ldr	r0, [r11, #-0x2c]
   10470: ebfff019     	bl	0xc4dc <strlen@plt>     @ imm = #-0x3f9c
   10474: e1a02000     	mov	r2, r0
   10478: e51b3020     	ldr	r3, [r11, #-0x20]
   1047c: e0823003     	add	r3, r2, r3
   10480: e2833001     	add	r3, r3, #1
   10484: e50b3020     	str	r3, [r11, #-0x20]
   10488: e51b3030     	ldr	r3, [r11, #-0x30]
   1048c: e3530000     	cmp	r3, #0
   10490: 0a000005     	beq	0x104ac <make_filename+0xac> @ imm = #0x14
   10494: e51b0030     	ldr	r0, [r11, #-0x30]
   10498: ebfff00f     	bl	0xc4dc <strlen@plt>     @ imm = #-0x3fc4
   1049c: e1a02000     	mov	r2, r0
   104a0: e51b3020     	ldr	r3, [r11, #-0x20]
   104a4: e0823003     	add	r3, r2, r3
   104a8: e50b3020     	str	r3, [r11, #-0x20]
   104ac: e51b3034     	ldr	r3, [r11, #-0x34]
   104b0: e3530000     	cmp	r3, #0
   104b4: 0a000006     	beq	0x104d4 <make_filename+0xd4> @ imm = #0x18
   104b8: e51b0034     	ldr	r0, [r11, #-0x34]
   104bc: ebfff006     	bl	0xc4dc <strlen@plt>     @ imm = #-0x3fe8
   104c0: e1a02000     	mov	r2, r0
   104c4: e51b3020     	ldr	r3, [r11, #-0x20]
   104c8: e0823003     	add	r3, r2, r3
   104cc: e2833001     	add	r3, r3, #1
   104d0: e50b3020     	str	r3, [r11, #-0x20]
   104d4: e51b3020     	ldr	r3, [r11, #-0x20]
   104d8: e2833001     	add	r3, r3, #1
   104dc: e1a00003     	mov	r0, r3
   104e0: ebfff060     	bl	0xc668 <malloc@plt>     @ imm = #-0x3e80
   104e4: e1a03000     	mov	r3, r0
   104e8: e50b301c     	str	r3, [r11, #-0x1c]
   104ec: e51b301c     	ldr	r3, [r11, #-0x1c]
   104f0: e3530000     	cmp	r3, #0
   104f4: 1a000006     	bne	0x10514 <make_filename+0x114> @ imm = #0x18
   104f8: e59f3210     	ldr	r3, [pc, #0x210]        @ 0x10710 <make_filename+0x310>
   104fc: e5933000     	ldr	r3, [r3]
   10500: e5933004     	ldr	r3, [r3, #0x4]
   10504: e3530001     	cmp	r3, #1
   10508: 9a000001     	bls	0x10514 <make_filename+0x114> @ imm = #0x4
   1050c: e59f0200     	ldr	r0, [pc, #0x200]        @ 0x10714 <make_filename+0x314>
   10510: eb0011e7     	bl	0x14cb4 <log_print>     @ imm = #0x479c
   10514: e51b3028     	ldr	r3, [r11, #-0x28]
   10518: e3530000     	cmp	r3, #0
   1051c: 0a000017     	beq	0x10580 <make_filename+0x180> @ imm = #0x5c
   10520: e51b3018     	ldr	r3, [r11, #-0x18]
   10524: e51b201c     	ldr	r2, [r11, #-0x1c]
   10528: e0824003     	add	r4, r2, r3
   1052c: e51b0028     	ldr	r0, [r11, #-0x28]
   10530: ebffefe9     	bl	0xc4dc <strlen@plt>     @ imm = #-0x405c
   10534: e1a03000     	mov	r3, r0
   10538: e1a00004     	mov	r0, r4
   1053c: e51b1028     	ldr	r1, [r11, #-0x28]
   10540: e1a02003     	mov	r2, r3
   10544: ebffef63     	bl	0xc2d8 <strncpy@plt>    @ imm = #-0x4274
   10548: e51b0028     	ldr	r0, [r11, #-0x28]
   1054c: ebffefe2     	bl	0xc4dc <strlen@plt>     @ imm = #-0x4078
   10550: e1a02000     	mov	r2, r0
   10554: e51b3018     	ldr	r3, [r11, #-0x18]
   10558: e0823003     	add	r3, r2, r3
   1055c: e50b3018     	str	r3, [r11, #-0x18]
   10560: e51b3018     	ldr	r3, [r11, #-0x18]
   10564: e51b201c     	ldr	r2, [r11, #-0x1c]
   10568: e0823003     	add	r3, r2, r3
   1056c: e3a0202f     	mov	r2, #47
   10570: e5c32000     	strb	r2, [r3]
   10574: e51b3018     	ldr	r3, [r11, #-0x18]
   10578: e2833001     	add	r3, r3, #1
   1057c: e50b3018     	str	r3, [r11, #-0x18]
   10580: e51b302c     	ldr	r3, [r11, #-0x2c]
   10584: e3530000     	cmp	r3, #0
   10588: 0a000020     	beq	0x10610 <make_filename+0x210> @ imm = #0x80
   1058c: e51b002c     	ldr	r0, [r11, #-0x2c]
   10590: ebfff02e     	bl	0xc650 <strdup@plt>     @ imm = #-0x3f48
   10594: e1a03000     	mov	r3, r0
   10598: e50b3014     	str	r3, [r11, #-0x14]
   1059c: e51b0014     	ldr	r0, [r11, #-0x14]
   105a0: eb0003d5     	bl	0x114fc <sanitize_filepath> @ imm = #0xf54
   105a4: e51b3018     	ldr	r3, [r11, #-0x18]
   105a8: e51b201c     	ldr	r2, [r11, #-0x1c]
   105ac: e0825003     	add	r5, r2, r3
   105b0: e51b4014     	ldr	r4, [r11, #-0x14]
   105b4: e51b0014     	ldr	r0, [r11, #-0x14]
   105b8: ebffefc7     	bl	0xc4dc <strlen@plt>     @ imm = #-0x40e4
   105bc: e1a03000     	mov	r3, r0
   105c0: e1a00005     	mov	r0, r5
   105c4: e1a01004     	mov	r1, r4
   105c8: e1a02003     	mov	r2, r3
   105cc: ebffef41     	bl	0xc2d8 <strncpy@plt>    @ imm = #-0x42fc
   105d0: e51b0014     	ldr	r0, [r11, #-0x14]
   105d4: ebffefc0     	bl	0xc4dc <strlen@plt>     @ imm = #-0x4100
   105d8: e1a02000     	mov	r2, r0
   105dc: e51b3018     	ldr	r3, [r11, #-0x18]
   105e0: e0823003     	add	r3, r2, r3
   105e4: e50b3018     	str	r3, [r11, #-0x18]
   105e8: e51b3018     	ldr	r3, [r11, #-0x18]
   105ec: e51b201c     	ldr	r2, [r11, #-0x1c]
   105f0: e0823003     	add	r3, r2, r3
   105f4: e3a0202f     	mov	r2, #47
   105f8: e5c32000     	strb	r2, [r3]
   105fc: e51b3018     	ldr	r3, [r11, #-0x18]
   10600: e2833001     	add	r3, r3, #1
   10604: e50b3018     	str	r3, [r11, #-0x18]
   10608: e51b0014     	ldr	r0, [r11, #-0x14]
   1060c: ebffef82     	bl	0xc41c <free@plt>       @ imm = #-0x41f8
   10610: e51b3030     	ldr	r3, [r11, #-0x30]
   10614: e3530000     	cmp	r3, #0
   10618: 0a000018     	beq	0x10680 <make_filename+0x280> @ imm = #0x60
   1061c: e51b0030     	ldr	r0, [r11, #-0x30]
   10620: ebfff00a     	bl	0xc650 <strdup@plt>     @ imm = #-0x3fd8
   10624: e1a03000     	mov	r3, r0
   10628: e50b3010     	str	r3, [r11, #-0x10]
   1062c: e51b0010     	ldr	r0, [r11, #-0x10]
   10630: eb00034a     	bl	0x11360 <sanitize_filename> @ imm = #0xd28
   10634: e51b3018     	ldr	r3, [r11, #-0x18]
   10638: e51b201c     	ldr	r2, [r11, #-0x1c]
   1063c: e0825003     	add	r5, r2, r3
   10640: e51b4010     	ldr	r4, [r11, #-0x10]
   10644: e51b0010     	ldr	r0, [r11, #-0x10]
   10648: ebffefa3     	bl	0xc4dc <strlen@plt>     @ imm = #-0x4174
   1064c: e1a03000     	mov	r3, r0
   10650: e1a00005     	mov	r0, r5
   10654: e1a01004     	mov	r1, r4
   10658: e1a02003     	mov	r2, r3
   1065c: ebffef1d     	bl	0xc2d8 <strncpy@plt>    @ imm = #-0x438c
   10660: e51b0010     	ldr	r0, [r11, #-0x10]
   10664: ebffef9c     	bl	0xc4dc <strlen@plt>     @ imm = #-0x4190
   10668: e1a02000     	mov	r2, r0
   1066c: e51b3018     	ldr	r3, [r11, #-0x18]
   10670: e0823003     	add	r3, r2, r3
   10674: e50b3018     	str	r3, [r11, #-0x18]
   10678: e51b0010     	ldr	r0, [r11, #-0x10]
   1067c: ebffef66     	bl	0xc41c <free@plt>       @ imm = #-0x4268
   10680: e51b3034     	ldr	r3, [r11, #-0x34]
   10684: e3530000     	cmp	r3, #0
   10688: 0a000017     	beq	0x106ec <make_filename+0x2ec> @ imm = #0x5c
   1068c: e51b3018     	ldr	r3, [r11, #-0x18]
   10690: e51b201c     	ldr	r2, [r11, #-0x1c]
   10694: e0823003     	add	r3, r2, r3
   10698: e3a0202e     	mov	r2, #46
   1069c: e5c32000     	strb	r2, [r3]
   106a0: e51b3018     	ldr	r3, [r11, #-0x18]
   106a4: e2833001     	add	r3, r3, #1
   106a8: e50b3018     	str	r3, [r11, #-0x18]
   106ac: e51b3018     	ldr	r3, [r11, #-0x18]
   106b0: e51b201c     	ldr	r2, [r11, #-0x1c]
   106b4: e0824003     	add	r4, r2, r3
   106b8: e51b0034     	ldr	r0, [r11, #-0x34]
   106bc: ebffef86     	bl	0xc4dc <strlen@plt>     @ imm = #-0x41e8
   106c0: e1a03000     	mov	r3, r0
   106c4: e1a00004     	mov	r0, r4
   106c8: e51b1034     	ldr	r1, [r11, #-0x34]
   106cc: e1a02003     	mov	r2, r3
   106d0: ebffef00     	bl	0xc2d8 <strncpy@plt>    @ imm = #-0x4400
   106d4: e51b0034     	ldr	r0, [r11, #-0x34]
   106d8: ebffef7f     	bl	0xc4dc <strlen@plt>     @ imm = #-0x4204
   106dc: e1a02000     	mov	r2, r0
   106e0: e51b3018     	ldr	r3, [r11, #-0x18]
   106e4: e0823003     	add	r3, r2, r3
   106e8: e50b3018     	str	r3, [r11, #-0x18]
   106ec: e51b3018     	ldr	r3, [r11, #-0x18]
   106f0: e51b201c     	ldr	r2, [r11, #-0x1c]
   106f4: e0823003     	add	r3, r2, r3
   106f8: e3a02000     	mov	r2, #0
   106fc: e5c32000     	strb	r2, [r3]
   10700: e51b301c     	ldr	r3, [r11, #-0x1c]
   10704: e1a00003     	mov	r0, r3
   10708: e24bd00c     	sub	sp, r11, #12
   1070c: e8bd8830     	pop	{r4, r5, r11, pc}
   10710: 5c 73 05 00  	.word	0x0005735c
   10714: 64 27 03 00  	.word	0x00032764

