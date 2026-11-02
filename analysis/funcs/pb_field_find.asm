0000ef7c <pb_field_find>:
    ef7c: e92d4800     	push	{r11, lr}
    ef80: e28db004     	add	r11, sp, #4
    ef84: e24dd010     	sub	sp, sp, #16
    ef88: e50b0010     	str	r0, [r11, #-0x10]
    ef8c: e50b1014     	str	r1, [r11, #-0x14]
    ef90: e51b3010     	ldr	r3, [r11, #-0x10]
    ef94: e5933008     	ldr	r3, [r3, #0x8]
    ef98: e50b3008     	str	r3, [r11, #-0x8]
    ef9c: e51b3010     	ldr	r3, [r11, #-0x10]
    efa0: e5933004     	ldr	r3, [r3, #0x4]
    efa4: e5d33000     	ldrb	r3, [r3]
    efa8: e1a02003     	mov	r2, r3
    efac: e51b3014     	ldr	r3, [r11, #-0x14]
    efb0: e1520003     	cmp	r2, r3
    efb4: 1a000001     	bne	0xefc0 <pb_field_find+0x44> @ imm = #0x4
    efb8: e3a03001     	mov	r3, #1
    efbc: ea000007     	b	0xefe0 <pb_field_find+0x64> @ imm = #0x1c
    efc0: e51b0010     	ldr	r0, [r11, #-0x10]
    efc4: ebffff95     	bl	0xee20 <pb_field_next>  @ imm = #-0x1ac
    efc8: e51b3010     	ldr	r3, [r11, #-0x10]
    efcc: e5932008     	ldr	r2, [r3, #0x8]
    efd0: e51b3008     	ldr	r3, [r11, #-0x8]
    efd4: e1520003     	cmp	r2, r3
    efd8: 1affffef     	bne	0xef9c <pb_field_find+0x20> @ imm = #-0x44
    efdc: e3a03000     	mov	r3, #0
    efe0: e1a00003     	mov	r0, r3
    efe4: e24bd004     	sub	sp, r11, #4
    efe8: e8bd8800     	pop	{r11, pc}

