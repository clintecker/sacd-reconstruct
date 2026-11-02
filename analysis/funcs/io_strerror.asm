00013680 <io_strerror>:
   13680: e52db004     	str	r11, [sp, #-0x4]!
   13684: e28db000     	add	r11, sp, #0
   13688: e24dd00c     	sub	sp, sp, #12
   1368c: e50b0008     	str	r0, [r11, #-0x8]
   13690: e51b3008     	ldr	r3, [r11, #-0x8]
   13694: e3730001     	cmn	r3, #1
   13698: 0a000008     	beq	0x136c0 <io_strerror+0x40> @ imm = #0x20
   1369c: e3530000     	cmp	r3, #0
   136a0: 0a000002     	beq	0x136b0 <io_strerror+0x30> @ imm = #0x8
   136a4: e3730002     	cmn	r3, #2
   136a8: 0a000002     	beq	0x136b8 <io_strerror+0x38> @ imm = #0x8
   136ac: ea000005     	b	0x136c8 <io_strerror+0x48> @ imm = #0x14
   136b0: e3a03000     	mov	r3, #0
   136b4: ea000004     	b	0x136cc <io_strerror+0x4c> @ imm = #0x10
   136b8: e59f301c     	ldr	r3, [pc, #0x1c]         @ 0x136dc <io_strerror+0x5c>
   136bc: ea000002     	b	0x136cc <io_strerror+0x4c> @ imm = #0x8
   136c0: e59f3018     	ldr	r3, [pc, #0x18]         @ 0x136e0 <io_strerror+0x60>
   136c4: ea000000     	b	0x136cc <io_strerror+0x4c> @ imm = #0x0
   136c8: e59f3014     	ldr	r3, [pc, #0x14]         @ 0x136e4 <io_strerror+0x64>
   136cc: e1a00003     	mov	r0, r3
   136d0: e28bd000     	add	sp, r11, #0
   136d4: e8bd0800     	ldm	sp!, {r11}
   136d8: e12fff1e     	bx	lr
   136dc: b0 28 03 00  	.word	0x000328b0
   136e0: b8 28 03 00  	.word	0x000328b8
   136e4: c0 28 03 00  	.word	0x000328c0

