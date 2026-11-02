00029614 <get_speaker_config_string>:
   29614: e52db004     	str	r11, [sp, #-0x4]!
   29618: e28db000     	add	r11, sp, #0
   2961c: e24dd00c     	sub	sp, sp, #12
   29620: e50b0008     	str	r0, [r11, #-0x8]
   29624: e51b3008     	ldr	r3, [r11, #-0x8]
   29628: e5d33020     	ldrb	r3, [r3, #0x20]
   2962c: e3530002     	cmp	r3, #2
   29630: 1a000006     	bne	0x29650 <get_speaker_config_string+0x3c> @ imm = #0x18
   29634: e51b3008     	ldr	r3, [r11, #-0x8]
   29638: e5d33021     	ldrb	r3, [r3, #0x21]
   2963c: e2033007     	and	r3, r3, #7
   29640: e3530000     	cmp	r3, #0
   29644: 1a000001     	bne	0x29650 <get_speaker_config_string+0x3c> @ imm = #0x4
   29648: e59f306c     	ldr	r3, [pc, #0x6c]         @ 0x296bc <get_speaker_config_string+0xa8>
   2964c: ea000016     	b	0x296ac <get_speaker_config_string+0x98> @ imm = #0x58
   29650: e51b3008     	ldr	r3, [r11, #-0x8]
   29654: e5d33020     	ldrb	r3, [r3, #0x20]
   29658: e3530005     	cmp	r3, #5
   2965c: 1a000006     	bne	0x2967c <get_speaker_config_string+0x68> @ imm = #0x18
   29660: e51b3008     	ldr	r3, [r11, #-0x8]
   29664: e5d33021     	ldrb	r3, [r3, #0x21]
   29668: e2033007     	and	r3, r3, #7
   2966c: e3530003     	cmp	r3, #3
   29670: 1a000001     	bne	0x2967c <get_speaker_config_string+0x68> @ imm = #0x4
   29674: e59f3044     	ldr	r3, [pc, #0x44]         @ 0x296c0 <get_speaker_config_string+0xac>
   29678: ea00000b     	b	0x296ac <get_speaker_config_string+0x98> @ imm = #0x2c
   2967c: e51b3008     	ldr	r3, [r11, #-0x8]
   29680: e5d33020     	ldrb	r3, [r3, #0x20]
   29684: e3530006     	cmp	r3, #6
   29688: 1a000006     	bne	0x296a8 <get_speaker_config_string+0x94> @ imm = #0x18
   2968c: e51b3008     	ldr	r3, [r11, #-0x8]
   29690: e5d33021     	ldrb	r3, [r3, #0x21]
   29694: e2033007     	and	r3, r3, #7
   29698: e3530004     	cmp	r3, #4
   2969c: 1a000001     	bne	0x296a8 <get_speaker_config_string+0x94> @ imm = #0x4
   296a0: e59f301c     	ldr	r3, [pc, #0x1c]         @ 0x296c4 <get_speaker_config_string+0xb0>
   296a4: ea000000     	b	0x296ac <get_speaker_config_string+0x98> @ imm = #0x0
   296a8: e59f3018     	ldr	r3, [pc, #0x18]         @ 0x296c8 <get_speaker_config_string+0xb4>
   296ac: e1a00003     	mov	r0, r3
   296b0: e28bd000     	add	sp, r11, #0
   296b4: e8bd0800     	ldm	sp!, {r11}
   296b8: e12fff1e     	bx	lr
   296bc: b0 58 03 00  	.word	0x000358b0
   296c0: b8 58 03 00  	.word	0x000358b8
   296c4: c0 58 03 00  	.word	0x000358c0
   296c8: c8 58 03 00  	.word	0x000358c8

