0000e4f4 <charset_convert>:
    e4f4: e92d4800     	push	{r11, lr}
    e4f8: e28db004     	add	r11, sp, #4
    e4fc: e24dd038     	sub	sp, sp, #56
    e500: e50b0028     	str	r0, [r11, #-0x28]
    e504: e50b102c     	str	r1, [r11, #-0x2c]
    e508: e50b2030     	str	r2, [r11, #-0x30]
    e50c: e50b3034     	str	r3, [r11, #-0x34]
    e510: e51b3028     	ldr	r3, [r11, #-0x28]
    e514: e50b3020     	str	r3, [r11, #-0x20]
    e518: e51b3028     	ldr	r3, [r11, #-0x28]
    e51c: e3530000     	cmp	r3, #0
    e520: 1a000001     	bne	0xe52c <charset_convert+0x38> @ imm = #0x4
    e524: e3a03000     	mov	r3, #0
    e528: ea000079     	b	0xe714 <charset_convert+0x220> @ imm = #0x1e4
    e52c: e51b3030     	ldr	r3, [r11, #-0x30]
    e530: e3530000     	cmp	r3, #0
    e534: 1a000002     	bne	0xe544 <charset_convert+0x50> @ imm = #0x8
    e538: ebffffdb     	bl	0xe4ac <charset_get_current> @ imm = #-0x94
    e53c: e1a03000     	mov	r3, r0
    e540: e50b3030     	str	r3, [r11, #-0x30]
    e544: e51b3034     	ldr	r3, [r11, #-0x34]
    e548: e3530000     	cmp	r3, #0
    e54c: 1a000002     	bne	0xe55c <charset_convert+0x68> @ imm = #0x8
    e550: ebffffd5     	bl	0xe4ac <charset_get_current> @ imm = #-0xac
    e554: e1a03000     	mov	r3, r0
    e558: e50b3034     	str	r3, [r11, #-0x34]
    e55c: e51b0034     	ldr	r0, [r11, #-0x34]
    e560: e51b1030     	ldr	r1, [r11, #-0x30]
    e564: ebfff88a     	bl	0xc794 <iconv_open@plt> @ imm = #-0x1dd8
    e568: e1a03000     	mov	r3, r0
    e56c: e50b3010     	str	r3, [r11, #-0x10]
    e570: e51b3010     	ldr	r3, [r11, #-0x10]
    e574: e3730001     	cmn	r3, #1
    e578: 1a00000c     	bne	0xe5b0 <charset_convert+0xbc> @ imm = #0x30
    e57c: e59f319c     	ldr	r3, [pc, #0x19c]        @ 0xe720 <charset_convert+0x22c>
    e580: e5933000     	ldr	r3, [r3]
    e584: e5933004     	ldr	r3, [r3, #0x4]
    e588: e3530001     	cmp	r3, #1
    e58c: 9a000003     	bls	0xe5a0 <charset_convert+0xac> @ imm = #0xc
    e590: e59f018c     	ldr	r0, [pc, #0x18c]        @ 0xe724 <charset_convert+0x230>
    e594: e51b1030     	ldr	r1, [r11, #-0x30]
    e598: e51b2034     	ldr	r2, [r11, #-0x34]
    e59c: eb0019c4     	bl	0x14cb4 <log_print>     @ imm = #0x6710
    e5a0: e51b0028     	ldr	r0, [r11, #-0x28]
    e5a4: ebfff829     	bl	0xc650 <strdup@plt>     @ imm = #-0x1f5c
    e5a8: e1a03000     	mov	r3, r0
    e5ac: ea000058     	b	0xe714 <charset_convert+0x220> @ imm = #0x160
    e5b0: e51b302c     	ldr	r3, [r11, #-0x2c]
    e5b4: e2833003     	add	r3, r3, #3
    e5b8: e3c33003     	bic	r3, r3, #3
    e5bc: e2833004     	add	r3, r3, #4
    e5c0: e50b3014     	str	r3, [r11, #-0x14]
    e5c4: e51b0014     	ldr	r0, [r11, #-0x14]
    e5c8: ebfff826     	bl	0xc668 <malloc@plt>     @ imm = #-0x1f68
    e5cc: e1a03000     	mov	r3, r0
    e5d0: e50b300c     	str	r3, [r11, #-0xc]
    e5d4: e51b3014     	ldr	r3, [r11, #-0x14]
    e5d8: e2433004     	sub	r3, r3, #4
    e5dc: e50b3018     	str	r3, [r11, #-0x18]
    e5e0: e51b300c     	ldr	r3, [r11, #-0xc]
    e5e4: e50b301c     	str	r3, [r11, #-0x1c]
    e5e8: e24b1020     	sub	r1, r11, #32
    e5ec: e24b202c     	sub	r2, r11, #44
    e5f0: e24b301c     	sub	r3, r11, #28
    e5f4: e24b0018     	sub	r0, r11, #24
    e5f8: e58d0000     	str	r0, [sp]
    e5fc: e51b0010     	ldr	r0, [r11, #-0x10]
    e600: ebfff770     	bl	0xc3c8 <iconv@plt>      @ imm = #-0x2240
    e604: e1a03000     	mov	r3, r0
    e608: e3730001     	cmn	r3, #1
    e60c: 1a000038     	bne	0xe6f4 <charset_convert+0x200> @ imm = #0xe0
    e610: ebfff871     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x1e3c
    e614: e1a03000     	mov	r3, r0
    e618: e5933000     	ldr	r3, [r3]
    e61c: e3530016     	cmp	r3, #22
    e620: 0a000032     	beq	0xe6f0 <charset_convert+0x1fc> @ imm = #0xc8
    e624: e3530054     	cmp	r3, #84
    e628: 0a000019     	beq	0xe694 <charset_convert+0x1a0> @ imm = #0x64
    e62c: e3530007     	cmp	r3, #7
    e630: 1a00001e     	bne	0xe6b0 <charset_convert+0x1bc> @ imm = #0x78
    e634: e51b301c     	ldr	r3, [r11, #-0x1c]
    e638: e1a02003     	mov	r2, r3
    e63c: e51b300c     	ldr	r3, [r11, #-0xc]
    e640: e0633002     	rsb	r3, r3, r2
    e644: e50b3008     	str	r3, [r11, #-0x8]
    e648: e51b3014     	ldr	r3, [r11, #-0x14]
    e64c: e243310a     	sub	r3, r3, #-2147483646
    e650: e1a03083     	lsl	r3, r3, #1
    e654: e50b3014     	str	r3, [r11, #-0x14]
    e658: e51b000c     	ldr	r0, [r11, #-0xc]
    e65c: e51b1014     	ldr	r1, [r11, #-0x14]
    e660: ebfff848     	bl	0xc788 <realloc@plt>    @ imm = #-0x1ee0
    e664: e1a03000     	mov	r3, r0
    e668: e50b300c     	str	r3, [r11, #-0xc]
    e66c: e51b3008     	ldr	r3, [r11, #-0x8]
    e670: e51b200c     	ldr	r2, [r11, #-0xc]
    e674: e0823003     	add	r3, r2, r3
    e678: e50b301c     	str	r3, [r11, #-0x1c]
    e67c: e51b3008     	ldr	r3, [r11, #-0x8]
    e680: e51b2014     	ldr	r2, [r11, #-0x14]
    e684: e0633002     	rsb	r3, r3, r2
    e688: e2433004     	sub	r3, r3, #4
    e68c: e50b3018     	str	r3, [r11, #-0x18]
    e690: eaffffd4     	b	0xe5e8 <charset_convert+0xf4> @ imm = #-0xb0
    e694: e51b3020     	ldr	r3, [r11, #-0x20]
    e698: e2833001     	add	r3, r3, #1
    e69c: e50b3020     	str	r3, [r11, #-0x20]
    e6a0: e51b302c     	ldr	r3, [r11, #-0x2c]
    e6a4: e2433001     	sub	r3, r3, #1
    e6a8: e50b302c     	str	r3, [r11, #-0x2c]
    e6ac: eaffffcd     	b	0xe5e8 <charset_convert+0xf4> @ imm = #-0xcc
    e6b0: e59f3068     	ldr	r3, [pc, #0x68]         @ 0xe720 <charset_convert+0x22c>
    e6b4: e5933000     	ldr	r3, [r3]
    e6b8: e5933004     	ldr	r3, [r3, #0x4]
    e6bc: e3530001     	cmp	r3, #1
    e6c0: 9a00000b     	bls	0xe6f4 <charset_convert+0x200> @ imm = #0x2c
    e6c4: ebfff844     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x1ef0
    e6c8: e1a03000     	mov	r3, r0
    e6cc: e5933000     	ldr	r3, [r3]
    e6d0: e1a00003     	mov	r0, r3
    e6d4: ebfff6cf     	bl	0xc218 <strerror@plt>   @ imm = #-0x24c4
    e6d8: e1a03000     	mov	r3, r0
    e6dc: e59f0044     	ldr	r0, [pc, #0x44]         @ 0xe728 <charset_convert+0x234>
    e6e0: e51b1028     	ldr	r1, [r11, #-0x28]
    e6e4: e1a02003     	mov	r2, r3
    e6e8: eb001971     	bl	0x14cb4 <log_print>     @ imm = #0x65c4
    e6ec: ea000000     	b	0xe6f4 <charset_convert+0x200> @ imm = #0x0
    e6f0: e1a00000     	mov	r0, r0
    e6f4: e51b301c     	ldr	r3, [r11, #-0x1c]
    e6f8: e1a00003     	mov	r0, r3
    e6fc: e3a01000     	mov	r1, #0
    e700: e3a02004     	mov	r2, #4
    e704: ebfff726     	bl	0xc3a4 <memset@plt>     @ imm = #-0x2368
    e708: e51b0010     	ldr	r0, [r11, #-0x10]
    e70c: ebfff76f     	bl	0xc4d0 <iconv_close@plt> @ imm = #-0x2244
    e710: e51b300c     	ldr	r3, [r11, #-0xc]
    e714: e1a00003     	mov	r0, r3
    e718: e24bd004     	sub	sp, r11, #4
    e71c: e8bd8800     	pop	{r11, pc}
    e720: 5c 73 05 00  	.word	0x0005735c
    e724: c0 26 03 00  	.word	0x000326c0
    e728: 00 27 03 00  	.word	0x00032700

