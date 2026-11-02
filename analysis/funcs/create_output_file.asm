0002801c <create_output_file>:
   2801c: e92d4830     	push	{r4, r5, r11, lr}
   28020: e28db00c     	add	r11, sp, #12
   28024: e24dd010     	sub	sp, sp, #16
   28028: e50b0018     	str	r0, [r11, #-0x18]
   2802c: e51b3018     	ldr	r3, [r11, #-0x18]
   28030: e5933014     	ldr	r3, [r3, #0x14]
   28034: e1a02003     	mov	r2, r3
   28038: e59f3124     	ldr	r3, [pc, #0x124]        @ 0x28164 <create_output_file+0x148>
   2803c: e1a00002     	mov	r0, r2
   28040: e1a01003     	mov	r1, r3
   28044: ebff9139     	bl	0xc530 <fopen64@plt>    @ imm = #-0x1bb1c
   28048: e1a02000     	mov	r2, r0
   2804c: e51b3018     	ldr	r3, [r11, #-0x18]
   28050: e583201c     	str	r2, [r3, #0x1c]
   28054: e51b3018     	ldr	r3, [r11, #-0x18]
   28058: e593301c     	ldr	r3, [r3, #0x1c]
   2805c: e3530000     	cmp	r3, #0
   28060: 1a000014     	bne	0x280b8 <create_output_file+0x9c> @ imm = #0x50
   28064: e59f30fc     	ldr	r3, [pc, #0xfc]         @ 0x28168 <create_output_file+0x14c>
   28068: e5933000     	ldr	r3, [r3]
   2806c: e5933004     	ldr	r3, [r3, #0x4]
   28070: e3530001     	cmp	r3, #1
   28074: 9a000035     	bls	0x28150 <create_output_file+0x134> @ imm = #0xd4
   28078: e51b3018     	ldr	r3, [r11, #-0x18]
   2807c: e5935014     	ldr	r5, [r3, #0x14]
   28080: ebff91d5     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x1b8ac
   28084: e1a03000     	mov	r3, r0
   28088: e5934000     	ldr	r4, [r3]
   2808c: ebff91d2     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x1b8b8
   28090: e1a03000     	mov	r3, r0
   28094: e5933000     	ldr	r3, [r3]
   28098: e1a00003     	mov	r0, r3
   2809c: ebff905d     	bl	0xc218 <strerror@plt>   @ imm = #-0x1be8c
   280a0: e1a03000     	mov	r3, r0
   280a4: e59f00c0     	ldr	r0, [pc, #0xc0]         @ 0x2816c <create_output_file+0x150>
   280a8: e1a01005     	mov	r1, r5
   280ac: e1a02004     	mov	r2, r4
   280b0: ebffb2ff     	bl	0x14cb4 <log_print>     @ imm = #-0x13404
   280b4: ea000026     	b	0x28154 <create_output_file+0x138> @ imm = #0x98
   280b8: e3a00601     	mov	r0, #1048576
   280bc: ebff9169     	bl	0xc668 <malloc@plt>     @ imm = #-0x1ba5c
   280c0: e1a03000     	mov	r3, r0
   280c4: e1a02003     	mov	r2, r3
   280c8: e51b3018     	ldr	r3, [r11, #-0x18]
   280cc: e5832020     	str	r2, [r3, #0x20]
   280d0: e51b3018     	ldr	r3, [r11, #-0x18]
   280d4: e593201c     	ldr	r2, [r3, #0x1c]
   280d8: e51b3018     	ldr	r3, [r11, #-0x18]
   280dc: e5933020     	ldr	r3, [r3, #0x20]
   280e0: e1a00002     	mov	r0, r2
   280e4: e1a01003     	mov	r1, r3
   280e8: e3a02000     	mov	r2, #0
   280ec: e3a03601     	mov	r3, #1048576
   280f0: ebff914a     	bl	0xc620 <setvbuf@plt>    @ imm = #-0x1bad8
   280f4: e51b3018     	ldr	r3, [r11, #-0x18]
   280f8: e5933058     	ldr	r3, [r3, #0x58]
   280fc: e3a00001     	mov	r0, #1
   28100: e1a01003     	mov	r1, r3
   28104: ebff9094     	bl	0xc35c <calloc@plt>     @ imm = #-0x1bdb0
   28108: e1a03000     	mov	r3, r0
   2810c: e1a02003     	mov	r2, r3
   28110: e51b3018     	ldr	r3, [r11, #-0x18]
   28114: e583205c     	str	r2, [r3, #0x5c]
   28118: e51b3018     	ldr	r3, [r11, #-0x18]
   2811c: e5933048     	ldr	r3, [r3, #0x48]
   28120: e3530000     	cmp	r3, #0
   28124: 0a000005     	beq	0x28140 <create_output_file+0x124> @ imm = #0x14
   28128: e51b3018     	ldr	r3, [r11, #-0x18]
   2812c: e5933048     	ldr	r3, [r3, #0x48]
   28130: e51b0018     	ldr	r0, [r11, #-0x18]
   28134: e12fff33     	blx	r3
   28138: e1a03000     	mov	r3, r0
   2813c: ea000000     	b	0x28144 <create_output_file+0x128> @ imm = #0x0
   28140: e3a03000     	mov	r3, #0
   28144: e50b3010     	str	r3, [r11, #-0x10]
   28148: e51b3010     	ldr	r3, [r11, #-0x10]
   2814c: ea000001     	b	0x28158 <create_output_file+0x13c> @ imm = #0x4
   28150: e1a00000     	mov	r0, r0
   28154: e3e03000     	mvn	r3, #0
   28158: e1a00003     	mov	r0, r3
   2815c: e24bd00c     	sub	sp, r11, #12
   28160: e8bd8830     	pop	{r4, r5, r11, pc}
   28164: 20 57 03 00  	.word	0x00035720
   28168: 5c 73 05 00  	.word	0x0005735c
   2816c: 24 57 03 00  	.word	0x00035724

