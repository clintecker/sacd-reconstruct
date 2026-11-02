000296cc <get_frame_format_string>:
   296cc: e52db004     	str	r11, [sp, #-0x4]!
   296d0: e28db000     	add	r11, sp, #0
   296d4: e24dd00c     	sub	sp, sp, #12
   296d8: e50b0008     	str	r0, [r11, #-0x8]
   296dc: e51b3008     	ldr	r3, [r11, #-0x8]
   296e0: e5d33015     	ldrb	r3, [r3, #0x15]
   296e4: e203300f     	and	r3, r3, #15
   296e8: e3530002     	cmp	r3, #2
   296ec: 1a000001     	bne	0x296f8 <get_frame_format_string+0x2c> @ imm = #0x4
   296f0: e59f304c     	ldr	r3, [pc, #0x4c]         @ 0x29744 <get_frame_format_string+0x78>
   296f4: ea00000e     	b	0x29734 <get_frame_format_string+0x68> @ imm = #0x38
   296f8: e51b3008     	ldr	r3, [r11, #-0x8]
   296fc: e5d33015     	ldrb	r3, [r3, #0x15]
   29700: e203300f     	and	r3, r3, #15
   29704: e3530003     	cmp	r3, #3
   29708: 1a000001     	bne	0x29714 <get_frame_format_string+0x48> @ imm = #0x4
   2970c: e59f3034     	ldr	r3, [pc, #0x34]         @ 0x29748 <get_frame_format_string+0x7c>
   29710: ea000007     	b	0x29734 <get_frame_format_string+0x68> @ imm = #0x1c
   29714: e51b3008     	ldr	r3, [r11, #-0x8]
   29718: e5d33015     	ldrb	r3, [r3, #0x15]
   2971c: e203300f     	and	r3, r3, #15
   29720: e3530000     	cmp	r3, #0
   29724: 1a000001     	bne	0x29730 <get_frame_format_string+0x64> @ imm = #0x4
   29728: e59f301c     	ldr	r3, [pc, #0x1c]         @ 0x2974c <get_frame_format_string+0x80>
   2972c: ea000000     	b	0x29734 <get_frame_format_string+0x68> @ imm = #0x0
   29730: e59f3018     	ldr	r3, [pc, #0x18]         @ 0x29750 <get_frame_format_string+0x84>
   29734: e1a00003     	mov	r0, r3
   29738: e28bd000     	add	sp, r11, #0
   2973c: e8bd0800     	ldm	sp!, {r11}
   29740: e12fff1e     	bx	lr
   29744: d0 58 03 00  	.word	0x000358d0
   29748: dc 58 03 00  	.word	0x000358dc
   2974c: e8 58 03 00  	.word	0x000358e8
   29750: c8 58 03 00  	.word	0x000358c8

