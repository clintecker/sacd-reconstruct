000273b8 <dsdiff_write_frame>:
   273b8: e92d4810     	push	{r4, r11, lr}
   273bc: e28db008     	add	r11, sp, #8
   273c0: e24dd044     	sub	sp, sp, #68
   273c4: e50b0040     	str	r0, [r11, #-0x40]
   273c8: e50b1044     	str	r1, [r11, #-0x44]
   273cc: e50b2048     	str	r2, [r11, #-0x48]
   273d0: e51b3040     	ldr	r3, [r11, #-0x40]
   273d4: e593305c     	ldr	r3, [r3, #0x5c]
   273d8: e50b3018     	str	r3, [r11, #-0x18]
   273dc: e51b3018     	ldr	r3, [r11, #-0x18]
   273e0: e5933010     	ldr	r3, [r3, #0x10]
   273e4: e2832001     	add	r2, r3, #1
   273e8: e51b3018     	ldr	r3, [r11, #-0x18]
   273ec: e5832010     	str	r2, [r3, #0x10]
   273f0: e51b3040     	ldr	r3, [r11, #-0x40]
   273f4: e593303c     	ldr	r3, [r3, #0x3c]
   273f8: e3530000     	cmp	r3, #0
   273fc: 0a000012     	beq	0x2744c <dsdiff_write_frame+0x94> @ imm = #0x48
   27400: e51b3040     	ldr	r3, [r11, #-0x40]
   27404: e593301c     	ldr	r3, [r3, #0x1c]
   27408: e51b0044     	ldr	r0, [r11, #-0x44]
   2740c: e3a01001     	mov	r1, #1
   27410: e51b2048     	ldr	r2, [r11, #-0x48]
   27414: ebff9475     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x1ae2c
   27418: e1a03000     	mov	r3, r0
   2741c: e50b3014     	str	r3, [r11, #-0x14]
   27420: e51b3018     	ldr	r3, [r11, #-0x18]
   27424: e1c301d8     	ldrd	r0, r1, [r3, #24]
   27428: e51b3014     	ldr	r3, [r11, #-0x14]
   2742c: e1a02003     	mov	r2, r3
   27430: e3a03000     	mov	r3, #0
   27434: e0922000     	adds	r2, r2, r0
   27438: e0a33001     	adc	r3, r3, r1
   2743c: e51b1018     	ldr	r1, [r11, #-0x18]
   27440: e1c121f8     	strd	r2, r3, [r1, #24]
   27444: e51b3014     	ldr	r3, [r11, #-0x14]
   27448: ea0000b9     	b	0x27734 <dsdiff_write_frame+0x37c> @ imm = #0x2e4
   2744c: e59f32ec     	ldr	r3, [pc, #0x2ec]        @ 0x27740 <dsdiff_write_frame+0x388>
   27450: e50b3024     	str	r3, [r11, #-0x24]
   27454: e51b3048     	ldr	r3, [r11, #-0x48]
   27458: e1a02003     	mov	r2, r3
   2745c: e3a03000     	mov	r3, #0
   27460: e14b22fc     	strd	r2, r3, [r11, #-44]
   27464: e51b4028     	ldr	r4, [r11, #-0x28]
   27468: e1a02c24     	lsr	r2, r4, #24
   2746c: e20438ff     	and	r3, r4, #16711680
   27470: e1a03423     	lsr	r3, r3, #8
   27474: e1822003     	orr	r2, r2, r3
   27478: e2043cff     	and	r3, r4, #65280
   2747c: e1a03403     	lsl	r3, r3, #8
   27480: e1822003     	orr	r2, r2, r3
   27484: e1a03c04     	lsl	r3, r4, #24
   27488: e1823003     	orr	r3, r2, r3
   2748c: e50b3034     	str	r3, [r11, #-0x34]
   27490: e51b402c     	ldr	r4, [r11, #-0x2c]
   27494: e1a02c24     	lsr	r2, r4, #24
   27498: e20438ff     	and	r3, r4, #16711680
   2749c: e1a03423     	lsr	r3, r3, #8
   274a0: e1822003     	orr	r2, r2, r3
   274a4: e2043cff     	and	r3, r4, #65280
   274a8: e1a03403     	lsl	r3, r3, #8
   274ac: e1822003     	orr	r2, r2, r3
   274b0: e1a03c04     	lsl	r3, r4, #24
   274b4: e1823003     	orr	r3, r2, r3
   274b8: e50b3030     	str	r3, [r11, #-0x30]
   274bc: e14b23d4     	ldrd	r2, r3, [r11, #-52]
   274c0: e1a01002     	mov	r1, r2
   274c4: e50b1020     	str	r1, [r11, #-0x20]
   274c8: e50b301c     	str	r3, [r11, #-0x1c]
   274cc: e51b3018     	ldr	r3, [r11, #-0x18]
   274d0: e5932010     	ldr	r2, [r3, #0x10]
   274d4: e51b3018     	ldr	r3, [r11, #-0x18]
   274d8: e5933024     	ldr	r3, [r3, #0x24]
   274dc: e1520003     	cmp	r2, r3
   274e0: 9a000014     	bls	0x27538 <dsdiff_write_frame+0x180> @ imm = #0x50
   274e4: e51b3018     	ldr	r3, [r11, #-0x18]
   274e8: e5933024     	ldr	r3, [r3, #0x24]
   274ec: e2833c27     	add	r3, r3, #9984
   274f0: e2833010     	add	r3, r3, #16
   274f4: e51b2018     	ldr	r2, [r11, #-0x18]
   274f8: e5823024     	str	r3, [r2, #0x24]
   274fc: e51b3018     	ldr	r3, [r11, #-0x18]
   27500: e5931020     	ldr	r1, [r3, #0x20]
   27504: e51b3018     	ldr	r3, [r11, #-0x18]
   27508: e5932024     	ldr	r2, [r3, #0x24]
   2750c: e1a03002     	mov	r3, r2
   27510: e1a03083     	lsl	r3, r3, #1
   27514: e0833002     	add	r3, r3, r2
   27518: e1a03103     	lsl	r3, r3, #2
   2751c: e1a00001     	mov	r0, r1
   27520: e1a01003     	mov	r1, r3
   27524: ebff9497     	bl	0xc788 <realloc@plt>    @ imm = #-0x1ada4
   27528: e1a03000     	mov	r3, r0
   2752c: e1a02003     	mov	r2, r3
   27530: e51b3018     	ldr	r3, [r11, #-0x18]
   27534: e5832020     	str	r2, [r3, #0x20]
   27538: e51b3018     	ldr	r3, [r11, #-0x18]
   2753c: e5931020     	ldr	r1, [r3, #0x20]
   27540: e51b3018     	ldr	r3, [r11, #-0x18]
   27544: e5933010     	ldr	r3, [r3, #0x10]
   27548: e2432001     	sub	r2, r3, #1
   2754c: e1a03002     	mov	r3, r2
   27550: e1a03083     	lsl	r3, r3, #1
   27554: e0833002     	add	r3, r3, r2
   27558: e1a03103     	lsl	r3, r3, #2
   2755c: e0813003     	add	r3, r1, r3
   27560: e55b2048     	ldrb	r2, [r11, #-0x48]
   27564: e3a01000     	mov	r1, #0
   27568: e1812002     	orr	r2, r1, r2
   2756c: e5c32008     	strb	r2, [r3, #0x8]
   27570: e55b2047     	ldrb	r2, [r11, #-0x47]
   27574: e3a01000     	mov	r1, #0
   27578: e1812002     	orr	r2, r1, r2
   2757c: e5c32009     	strb	r2, [r3, #0x9]
   27580: e55b2046     	ldrb	r2, [r11, #-0x46]
   27584: e3a01000     	mov	r1, #0
   27588: e1812002     	orr	r2, r1, r2
   2758c: e5c3200a     	strb	r2, [r3, #0xa]
   27590: e55b2045     	ldrb	r2, [r11, #-0x45]
   27594: e3a01000     	mov	r1, #0
   27598: e1812002     	orr	r2, r1, r2
   2759c: e5c3200b     	strb	r2, [r3, #0xb]
   275a0: e51b3018     	ldr	r3, [r11, #-0x18]
   275a4: e5931020     	ldr	r1, [r3, #0x20]
   275a8: e51b3018     	ldr	r3, [r11, #-0x18]
   275ac: e5933010     	ldr	r3, [r3, #0x10]
   275b0: e2432001     	sub	r2, r3, #1
   275b4: e1a03002     	mov	r3, r2
   275b8: e1a03083     	lsl	r3, r3, #1
   275bc: e0833002     	add	r3, r3, r2
   275c0: e1a03103     	lsl	r3, r3, #2
   275c4: e0814003     	add	r4, r1, r3
   275c8: e51b3040     	ldr	r3, [r11, #-0x40]
   275cc: e593301c     	ldr	r3, [r3, #0x1c]
   275d0: e1a00003     	mov	r0, r3
   275d4: ebff934e     	bl	0xc314 <ftello64@plt>   @ imm = #-0x1b2c8
   275d8: e3a0200c     	mov	r2, #12
   275dc: e3a03000     	mov	r3, #0
   275e0: e0922000     	adds	r2, r2, r0
   275e4: e0a33001     	adc	r3, r3, r1
   275e8: e20210ff     	and	r1, r2, #255
   275ec: e3a00000     	mov	r0, #0
   275f0: e1801001     	orr	r1, r0, r1
   275f4: e5c41000     	strb	r1, [r4]
   275f8: e1a01422     	lsr	r1, r2, #8
   275fc: e20110ff     	and	r1, r1, #255
   27600: e3a00000     	mov	r0, #0
   27604: e1801001     	orr	r1, r0, r1
   27608: e5c41001     	strb	r1, [r4, #0x1]
   2760c: e1a01822     	lsr	r1, r2, #16
   27610: e20110ff     	and	r1, r1, #255
   27614: e3a00000     	mov	r0, #0
   27618: e1801001     	orr	r1, r0, r1
   2761c: e5c41002     	strb	r1, [r4, #0x2]
   27620: e1a01c22     	lsr	r1, r2, #24
   27624: e3a00000     	mov	r0, #0
   27628: e1801001     	orr	r1, r0, r1
   2762c: e5c41003     	strb	r1, [r4, #0x3]
   27630: e20310ff     	and	r1, r3, #255
   27634: e3a00000     	mov	r0, #0
   27638: e1801001     	orr	r1, r0, r1
   2763c: e5c41004     	strb	r1, [r4, #0x4]
   27640: e1a01423     	lsr	r1, r3, #8
   27644: e20110ff     	and	r1, r1, #255
   27648: e3a00000     	mov	r0, #0
   2764c: e1801001     	orr	r1, r0, r1
   27650: e5c41005     	strb	r1, [r4, #0x5]
   27654: e1a01823     	lsr	r1, r3, #16
   27658: e20110ff     	and	r1, r1, #255
   2765c: e3a00000     	mov	r0, #0
   27660: e1801001     	orr	r1, r0, r1
   27664: e5c41006     	strb	r1, [r4, #0x6]
   27668: e1a03c23     	lsr	r3, r3, #24
   2766c: e3a02000     	mov	r2, #0
   27670: e1823003     	orr	r3, r2, r3
   27674: e5c43007     	strb	r3, [r4, #0x7]
   27678: e51b3040     	ldr	r3, [r11, #-0x40]
   2767c: e593301c     	ldr	r3, [r3, #0x1c]
   27680: e24b2024     	sub	r2, r11, #36
   27684: e1a00002     	mov	r0, r2
   27688: e3a01001     	mov	r1, #1
   2768c: e3a0200c     	mov	r2, #12
   27690: ebff93d6     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x1b0a8
   27694: e1a03000     	mov	r3, r0
   27698: e50b3010     	str	r3, [r11, #-0x10]
   2769c: e51b3040     	ldr	r3, [r11, #-0x40]
   276a0: e593301c     	ldr	r3, [r3, #0x1c]
   276a4: e51b0044     	ldr	r0, [r11, #-0x44]
   276a8: e3a01001     	mov	r1, #1
   276ac: e51b2048     	ldr	r2, [r11, #-0x48]
   276b0: ebff93ce     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x1b0c8
   276b4: e1a03000     	mov	r3, r0
   276b8: e51b2010     	ldr	r2, [r11, #-0x10]
   276bc: e0823003     	add	r3, r2, r3
   276c0: e50b3010     	str	r3, [r11, #-0x10]
   276c4: e51b3048     	ldr	r3, [r11, #-0x48]
   276c8: e2033001     	and	r3, r3, #1
   276cc: e6ef3073     	uxtb	r3, r3
   276d0: e3530000     	cmp	r3, #0
   276d4: 0a00000c     	beq	0x2770c <dsdiff_write_frame+0x354> @ imm = #0x30
   276d8: e3a03000     	mov	r3, #0
   276dc: e54b3035     	strb	r3, [r11, #-0x35]
   276e0: e51b3040     	ldr	r3, [r11, #-0x40]
   276e4: e593301c     	ldr	r3, [r3, #0x1c]
   276e8: e24b2035     	sub	r2, r11, #53
   276ec: e1a00002     	mov	r0, r2
   276f0: e3a01001     	mov	r1, #1
   276f4: e3a02001     	mov	r2, #1
   276f8: ebff93bc     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x1b110
   276fc: e1a03000     	mov	r3, r0
   27700: e51b2010     	ldr	r2, [r11, #-0x10]
   27704: e0823003     	add	r3, r2, r3
   27708: e50b3010     	str	r3, [r11, #-0x10]
   2770c: e51b3018     	ldr	r3, [r11, #-0x18]
   27710: e1c301d8     	ldrd	r0, r1, [r3, #24]
   27714: e51b3010     	ldr	r3, [r11, #-0x10]
   27718: e1a02003     	mov	r2, r3
   2771c: e3a03000     	mov	r3, #0
   27720: e0922000     	adds	r2, r2, r0
   27724: e0a33001     	adc	r3, r3, r1
   27728: e51b1018     	ldr	r1, [r11, #-0x18]
   2772c: e1c121f8     	strd	r2, r3, [r1, #24]
   27730: e51b3010     	ldr	r3, [r11, #-0x10]
   27734: e1a00003     	mov	r0, r3
   27738: e24bd008     	sub	sp, r11, #8
   2773c: e8bd8810     	pop	{r4, r11, pc}
   27740: 44 53 54 46  	.word	0x46545344

