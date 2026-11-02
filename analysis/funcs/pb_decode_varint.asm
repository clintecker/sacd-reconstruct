0000e96c <pb_decode_varint>:
    e96c: e92d49f0     	push	{r4, r5, r6, r7, r8, r11, lr}
    e970: e28db018     	add	r11, sp, #24
    e974: e24dd014     	sub	sp, sp, #20
    e978: e50b0028     	str	r0, [r11, #-0x28]
    e97c: e50b102c     	str	r1, [r11, #-0x2c]
    e980: e3a03000     	mov	r3, #0
    e984: e54b301d     	strb	r3, [r11, #-0x1d]
    e988: e51b102c     	ldr	r1, [r11, #-0x2c]
    e98c: e3a02000     	mov	r2, #0
    e990: e3a03000     	mov	r3, #0
    e994: e1c120f0     	strd	r2, r3, [r1]
    e998: ea00001f     	b	0xea1c <pb_decode_varint+0xb0> @ imm = #0x7c
    e99c: e51b302c     	ldr	r3, [r11, #-0x2c]
    e9a0: e1c360d0     	ldrd	r6, r7, [r3]
    e9a4: e55b301e     	ldrb	r3, [r11, #-0x1e]
    e9a8: e20300ff     	and	r0, r3, #255
    e9ac: e3a01000     	mov	r1, #0
    e9b0: e3a0207f     	mov	r2, #127
    e9b4: e3a03000     	mov	r3, #0
    e9b8: e0022000     	and	r2, r2, r0
    e9bc: e0033001     	and	r3, r3, r1
    e9c0: e55b101d     	ldrb	r1, [r11, #-0x1d]
    e9c4: e2410020     	sub	r0, r1, #32
    e9c8: e1a0c012     	lsl	r12, r2, r0
    e9cc: e2618020     	rsb	r8, r1, #32
    e9d0: e1a08832     	lsr	r8, r2, r8
    e9d4: e1a05113     	lsl	r5, r3, r1
    e9d8: e1885005     	orr	r5, r8, r5
    e9dc: e3500000     	cmp	r0, #0
    e9e0: a1a0500c     	movge	r5, r12
    e9e4: e1a04112     	lsl	r4, r2, r1
    e9e8: e1862004     	orr	r2, r6, r4
    e9ec: e1873005     	orr	r3, r7, r5
    e9f0: e51b102c     	ldr	r1, [r11, #-0x2c]
    e9f4: e1c120f0     	strd	r2, r3, [r1]
    e9f8: e55b301d     	ldrb	r3, [r11, #-0x1d]
    e9fc: e2833007     	add	r3, r3, #7
    ea00: e54b301d     	strb	r3, [r11, #-0x1d]
    ea04: e55b301e     	ldrb	r3, [r11, #-0x1e]
    ea08: e6af3073     	sxtb	r3, r3
    ea0c: e3530000     	cmp	r3, #0
    ea10: ba000001     	blt	0xea1c <pb_decode_varint+0xb0> @ imm = #0x4
    ea14: e3a03001     	mov	r3, #1
    ea18: ea00000b     	b	0xea4c <pb_decode_varint+0xe0> @ imm = #0x2c
    ea1c: e55b301d     	ldrb	r3, [r11, #-0x1d]
    ea20: e353003f     	cmp	r3, #63
    ea24: 8a000007     	bhi	0xea48 <pb_decode_varint+0xdc> @ imm = #0x1c
    ea28: e24b301e     	sub	r3, r11, #30
    ea2c: e51b0028     	ldr	r0, [r11, #-0x28]
    ea30: e1a01003     	mov	r1, r3
    ea34: e3a02001     	mov	r2, #1
    ea38: ebffff67     	bl	0xe7dc <pb_read>        @ imm = #-0x264
    ea3c: e1a03000     	mov	r3, r0
    ea40: e3530000     	cmp	r3, #0
    ea44: 1affffd4     	bne	0xe99c <pb_decode_varint+0x30> @ imm = #-0xb0
    ea48: e3a03000     	mov	r3, #0
    ea4c: e1a00003     	mov	r0, r3
    ea50: e24bd018     	sub	sp, r11, #24
    ea54: e8bd89f0     	pop	{r4, r5, r6, r7, r8, r11, pc}

