0001c2d8 <find_frame_description>:
   1c2d8: e52db004     	str	r11, [sp, #-0x4]!
   1c2dc: e28db000     	add	r11, sp, #0
   1c2e0: e24dd014     	sub	sp, sp, #20
   1c2e4: e50b0010     	str	r0, [r11, #-0x10]
   1c2e8: e3a03000     	mov	r3, #0
   1c2ec: e50b3008     	str	r3, [r11, #-0x8]
   1c2f0: ea000016     	b	0x1c350 <find_frame_description+0x78> @ imm = #0x58
   1c2f4: e51b2008     	ldr	r2, [r11, #-0x8]
   1c2f8: e59f1070     	ldr	r1, [pc, #0x70]         @ 0x1c370 <find_frame_description+0x98>
   1c2fc: e1a03002     	mov	r3, r2
   1c300: e1a03083     	lsl	r3, r3, #1
   1c304: e0833002     	add	r3, r3, r2
   1c308: e1a03103     	lsl	r3, r3, #2
   1c30c: e0813003     	add	r3, r1, r3
   1c310: e5932000     	ldr	r2, [r3]
   1c314: e51b3010     	ldr	r3, [r11, #-0x10]
   1c318: e1520003     	cmp	r2, r3
   1c31c: 1a000008     	bne	0x1c344 <find_frame_description+0x6c> @ imm = #0x20
   1c320: e51b2008     	ldr	r2, [r11, #-0x8]
   1c324: e1a03002     	mov	r3, r2
   1c328: e1a03083     	lsl	r3, r3, #1
   1c32c: e0833002     	add	r3, r3, r2
   1c330: e1a03103     	lsl	r3, r3, #2
   1c334: e1a02003     	mov	r2, r3
   1c338: e59f3030     	ldr	r3, [pc, #0x30]         @ 0x1c370 <find_frame_description+0x98>
   1c33c: e0823003     	add	r3, r2, r3
   1c340: ea000006     	b	0x1c360 <find_frame_description+0x88> @ imm = #0x18
   1c344: e51b3008     	ldr	r3, [r11, #-0x8]
   1c348: e2833001     	add	r3, r3, #1
   1c34c: e50b3008     	str	r3, [r11, #-0x8]
   1c350: e51b3008     	ldr	r3, [r11, #-0x8]
   1c354: e353005b     	cmp	r3, #91
   1c358: daffffe5     	ble	0x1c2f4 <find_frame_description+0x1c> @ imm = #-0x6c
   1c35c: e3a03000     	mov	r3, #0
   1c360: e1a00003     	mov	r0, r3
   1c364: e28bd000     	add	sp, r11, #0
   1c368: e8bd0800     	ldm	sp!, {r11}
   1c36c: e12fff1e     	bx	lr
   1c370: 40 e8 03 00  	.word	0x0003e840

