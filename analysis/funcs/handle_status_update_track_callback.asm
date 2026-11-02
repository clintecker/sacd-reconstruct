0000d6d8 <handle_status_update_track_callback>:
    d6d8: e92d4800     	push	{r11, lr}
    d6dc: e28db004     	add	r11, sp, #4
    d6e0: e24dd020     	sub	sp, sp, #32
    d6e4: e50b0010     	str	r0, [r11, #-0x10]
    d6e8: e50b1014     	str	r1, [r11, #-0x14]
    d6ec: e50b2018     	str	r2, [r11, #-0x18]
    d6f0: e51b0010     	ldr	r0, [r11, #-0x10]
    d6f4: ebfffb78     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1220
    d6f8: e1a03000     	mov	r3, r0
    d6fc: e51b0010     	ldr	r0, [r11, #-0x10]
    d700: e1a01003     	mov	r1, r3
    d704: e59f2040     	ldr	r2, [pc, #0x40]         @ 0xd74c <handle_status_update_track_callback+0x74>
    d708: e59f3040     	ldr	r3, [pc, #0x40]         @ 0xd750 <handle_status_update_track_callback+0x78>
    d70c: eb000378     	bl	0xe4f4 <charset_convert> @ imm = #0xde0
    d710: e1a03000     	mov	r3, r0
    d714: e50b3008     	str	r3, [r11, #-0x8]
    d718: e59f3034     	ldr	r3, [pc, #0x34]         @ 0xd754 <handle_status_update_track_callback+0x7c>
    d71c: e5933000     	ldr	r3, [r3]
    d720: e51b2018     	ldr	r2, [r11, #-0x18]
    d724: e58d2000     	str	r2, [sp]
    d728: e1a00003     	mov	r0, r3
    d72c: e59f1024     	ldr	r1, [pc, #0x24]         @ 0xd758 <handle_status_update_track_callback+0x80>
    d730: e51b2008     	ldr	r2, [r11, #-0x8]
    d734: e51b3014     	ldr	r3, [r11, #-0x14]
    d738: ebffffaf     	bl	0xd5fc <safe_fwprintf>  @ imm = #-0x144
    d73c: e51b0008     	ldr	r0, [r11, #-0x8]
    d740: ebfffb35     	bl	0xc41c <free@plt>       @ imm = #-0x132c
    d744: e24bd004     	sub	sp, r11, #4
    d748: e8bd8800     	pop	{r11, pc}
    d74c: dc 1a 03 00  	.word	0x00031adc
    d750: e4 1a 03 00  	.word	0x00031ae4
    d754: f4 6d 05 00  	.word	0x00056df4
    d758: ec 1a 03 00  	.word	0x00031aec

