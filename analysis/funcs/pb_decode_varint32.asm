0000e924 <pb_decode_varint32>:
    e924: e92d4800     	push	{r11, lr}
    e928: e28db004     	add	r11, sp, #4
    e92c: e24dd018     	sub	sp, sp, #24
    e930: e50b0018     	str	r0, [r11, #-0x18]
    e934: e50b101c     	str	r1, [r11, #-0x1c]
    e938: e24b3014     	sub	r3, r11, #20
    e93c: e51b0018     	ldr	r0, [r11, #-0x18]
    e940: e1a01003     	mov	r1, r3
    e944: eb000008     	bl	0xe96c <pb_decode_varint> @ imm = #0x20
    e948: e1a03000     	mov	r3, r0
    e94c: e54b3005     	strb	r3, [r11, #-0x5]
    e950: e14b21d4     	ldrd	r2, r3, [r11, #-20]
    e954: e51b301c     	ldr	r3, [r11, #-0x1c]
    e958: e5832000     	str	r2, [r3]
    e95c: e55b3005     	ldrb	r3, [r11, #-0x5]
    e960: e1a00003     	mov	r0, r3
    e964: e24bd004     	sub	sp, r11, #4
    e968: e8bd8800     	pop	{r11, pc}

