00021398 <cue_escape>:
   21398: e92d4800     	push	{r11, lr}
   2139c: e28db004     	add	r11, sp, #4
   213a0: e24dd010     	sub	sp, sp, #16
   213a4: e50b0010     	str	r0, [r11, #-0x10]
   213a8: e51b0010     	ldr	r0, [r11, #-0x10]
   213ac: e59f103c     	ldr	r1, [pc, #0x3c]         @ 0x213f0 <cue_escape+0x58>
   213b0: e59f203c     	ldr	r2, [pc, #0x3c]         @ 0x213f4 <cue_escape+0x5c>
   213b4: ebffc9b6     	bl	0x13a94 <str_replace>   @ imm = #-0xd928
   213b8: e1a03000     	mov	r3, r0
   213bc: e50b3008     	str	r3, [r11, #-0x8]
   213c0: e51b3008     	ldr	r3, [r11, #-0x8]
   213c4: e59f002c     	ldr	r0, [pc, #0x2c]         @ 0x213f8 <cue_escape+0x60>
   213c8: e1a01003     	mov	r1, r3
   213cc: ebffac5a     	bl	0xc53c <strcpy@plt>     @ imm = #-0x14e98
   213d0: e51b0008     	ldr	r0, [r11, #-0x8]
   213d4: ebffac10     	bl	0xc41c <free@plt>       @ imm = #-0x14fc0
   213d8: e59f0018     	ldr	r0, [pc, #0x18]         @ 0x213f8 <cue_escape+0x60>
   213dc: ebffca67     	bl	0x13d80 <trim_whitespace> @ imm = #-0xd664
   213e0: e59f3010     	ldr	r3, [pc, #0x10]         @ 0x213f8 <cue_escape+0x60>
   213e4: e1a00003     	mov	r0, r3
   213e8: e24bd004     	sub	sp, r11, #4
   213ec: e8bd8800     	pop	{r11, pc}
   213f0: 08 53 03 00  	.word	0x00035308
   213f4: 0c 53 03 00  	.word	0x0003530c
   213f8: c0 93 05 00  	.word	0x000593c0

