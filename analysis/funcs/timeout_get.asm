0000fc88 <timeout_get>:
    fc88: e92d4870     	push	{r4, r5, r6, r11, lr}
    fc8c: e28db010     	add	r11, sp, #16
    fc90: e24dd01c     	sub	sp, sp, #28
    fc94: e50b0028     	str	r0, [r11, #-0x28]
    fc98: e51b3028     	ldr	r3, [r11, #-0x28]
    fc9c: e1c320d0     	ldrd	r2, r3, [r3]
    fca0: e3a01000     	mov	r1, #0
    fca4: e1a04001     	mov	r4, r1
    fca8: e1a00002     	mov	r0, r2
    fcac: e1a01003     	mov	r1, r3
    fcb0: e3a02000     	mov	r2, #0
    fcb4: e3a03000     	mov	r3, #0
    fcb8: eb008311     	bl	0x30904 <__aeabi_dcmplt> @ imm = #0x20c44
    fcbc: e1a03000     	mov	r3, r0
    fcc0: e3530000     	cmp	r3, #0
    fcc4: 0a000001     	beq	0xfcd0 <timeout_get+0x48> @ imm = #0x4
    fcc8: e3a03001     	mov	r3, #1
    fccc: e1a04003     	mov	r4, r3
    fcd0: e6ef3074     	uxtb	r3, r4
    fcd4: e3530000     	cmp	r3, #0
    fcd8: 0a000014     	beq	0xfd30 <timeout_get+0xa8> @ imm = #0x50
    fcdc: e51b3028     	ldr	r3, [r11, #-0x28]
    fce0: e1c320d8     	ldrd	r2, r3, [r3, #8]
    fce4: e3a01000     	mov	r1, #0
    fce8: e1a04001     	mov	r4, r1
    fcec: e1a00002     	mov	r0, r2
    fcf0: e1a01003     	mov	r1, r3
    fcf4: e3a02000     	mov	r2, #0
    fcf8: e3a03000     	mov	r3, #0
    fcfc: eb008300     	bl	0x30904 <__aeabi_dcmplt> @ imm = #0x20c00
    fd00: e1a03000     	mov	r3, r0
    fd04: e3530000     	cmp	r3, #0
    fd08: 0a000001     	beq	0xfd14 <timeout_get+0x8c> @ imm = #0x4
    fd0c: e3a03001     	mov	r3, #1
    fd10: e1a04003     	mov	r4, r3
    fd14: e6ef3074     	uxtb	r3, r4
    fd18: e3530000     	cmp	r3, #0
    fd1c: 0a000003     	beq	0xfd30 <timeout_get+0xa8> @ imm = #0xc
    fd20: e3a02000     	mov	r2, #0
    fd24: e3a034bf     	mov	r3, #-1090519040
    fd28: e283360f     	add	r3, r3, #15728640
    fd2c: ea000091     	b	0xff78 <timeout_get+0x2f0> @ imm = #0x244
    fd30: e51b3028     	ldr	r3, [r11, #-0x28]
    fd34: e1c320d0     	ldrd	r2, r3, [r3]
    fd38: e3a01000     	mov	r1, #0
    fd3c: e1a04001     	mov	r4, r1
    fd40: e1a00002     	mov	r0, r2
    fd44: e1a01003     	mov	r1, r3
    fd48: e3a02000     	mov	r2, #0
    fd4c: e3a03000     	mov	r3, #0
    fd50: eb0082eb     	bl	0x30904 <__aeabi_dcmplt> @ imm = #0x20bac
    fd54: e1a03000     	mov	r3, r0
    fd58: e3530000     	cmp	r3, #0
    fd5c: 0a000001     	beq	0xfd68 <timeout_get+0xe0> @ imm = #0x4
    fd60: e3a03001     	mov	r3, #1
    fd64: e1a04003     	mov	r4, r3
    fd68: e6ef3074     	uxtb	r3, r4
    fd6c: e3530000     	cmp	r3, #0
    fd70: 0a000024     	beq	0xfe08 <timeout_get+0x180> @ imm = #0x90
    fd74: e51b3028     	ldr	r3, [r11, #-0x28]
    fd78: e1c340d8     	ldrd	r4, r5, [r3, #8]
    fd7c: eb00017b     	bl	0x10370 <timeout_gettime> @ imm = #0x5ec
    fd80: e1a02000     	mov	r2, r0
    fd84: e1a03001     	mov	r3, r1
    fd88: e1a00004     	mov	r0, r4
    fd8c: e1a01005     	mov	r1, r5
    fd90: eb00809d     	bl	0x3000c <__subdf3>      @ imm = #0x20274
    fd94: e1a02000     	mov	r2, r0
    fd98: e1a03001     	mov	r3, r1
    fd9c: e1a00002     	mov	r0, r2
    fda0: e1a01003     	mov	r1, r3
    fda4: e51b3028     	ldr	r3, [r11, #-0x28]
    fda8: e1c321d0     	ldrd	r2, r3, [r3, #16]
    fdac: eb008097     	bl	0x30010 <__aeabi_dadd>  @ imm = #0x2025c
    fdb0: e1a02000     	mov	r2, r0
    fdb4: e1a03001     	mov	r3, r1
    fdb8: e14b22f4     	strd	r2, r3, [r11, #-36]
    fdbc: e3a03000     	mov	r3, #0
    fdc0: e1a04003     	mov	r4, r3
    fdc4: e14b02d4     	ldrd	r0, r1, [r11, #-36]
    fdc8: e3a02000     	mov	r2, #0
    fdcc: e3a03000     	mov	r3, #0
    fdd0: eb0082da     	bl	0x30940 <__aeabi_dcmpgt> @ imm = #0x20b68
    fdd4: e1a03000     	mov	r3, r0
    fdd8: e3530000     	cmp	r3, #0
    fddc: 0a000001     	beq	0xfde8 <timeout_get+0x160> @ imm = #0x4
    fde0: e3a03001     	mov	r3, #1
    fde4: e1a04003     	mov	r4, r3
    fde8: e6ef3074     	uxtb	r3, r4
    fdec: e3530000     	cmp	r3, #0
    fdf0: 0a000001     	beq	0xfdfc <timeout_get+0x174> @ imm = #0x4
    fdf4: e14b22d4     	ldrd	r2, r3, [r11, #-36]
    fdf8: ea000001     	b	0xfe04 <timeout_get+0x17c> @ imm = #0x4
    fdfc: e3a02000     	mov	r2, #0
    fe00: e3a03000     	mov	r3, #0
    fe04: ea00005b     	b	0xff78 <timeout_get+0x2f0> @ imm = #0x16c
    fe08: e51b3028     	ldr	r3, [r11, #-0x28]
    fe0c: e1c320d8     	ldrd	r2, r3, [r3, #8]
    fe10: e3a01000     	mov	r1, #0
    fe14: e1a04001     	mov	r4, r1
    fe18: e1a00002     	mov	r0, r2
    fe1c: e1a01003     	mov	r1, r3
    fe20: e3a02000     	mov	r2, #0
    fe24: e3a03000     	mov	r3, #0
    fe28: eb0082b5     	bl	0x30904 <__aeabi_dcmplt> @ imm = #0x20ad4
    fe2c: e1a03000     	mov	r3, r0
    fe30: e3530000     	cmp	r3, #0
    fe34: 0a000001     	beq	0xfe40 <timeout_get+0x1b8> @ imm = #0x4
    fe38: e3a03001     	mov	r3, #1
    fe3c: e1a04003     	mov	r4, r3
    fe40: e6ef3074     	uxtb	r3, r4
    fe44: e3530000     	cmp	r3, #0
    fe48: 0a000002     	beq	0xfe58 <timeout_get+0x1d0> @ imm = #0x8
    fe4c: e51b3028     	ldr	r3, [r11, #-0x28]
    fe50: e1c320d0     	ldrd	r2, r3, [r3]
    fe54: ea000047     	b	0xff78 <timeout_get+0x2f0> @ imm = #0x11c
    fe58: e51b3028     	ldr	r3, [r11, #-0x28]
    fe5c: e1c340d8     	ldrd	r4, r5, [r3, #8]
    fe60: eb000142     	bl	0x10370 <timeout_gettime> @ imm = #0x508
    fe64: e1a02000     	mov	r2, r0
    fe68: e1a03001     	mov	r3, r1
    fe6c: e1a00004     	mov	r0, r4
    fe70: e1a01005     	mov	r1, r5
    fe74: eb008064     	bl	0x3000c <__subdf3>      @ imm = #0x20190
    fe78: e1a02000     	mov	r2, r0
    fe7c: e1a03001     	mov	r3, r1
    fe80: e1a00002     	mov	r0, r2
    fe84: e1a01003     	mov	r1, r3
    fe88: e51b3028     	ldr	r3, [r11, #-0x28]
    fe8c: e1c321d0     	ldrd	r2, r3, [r3, #16]
    fe90: eb00805e     	bl	0x30010 <__aeabi_dadd>  @ imm = #0x20178
    fe94: e1a02000     	mov	r2, r0
    fe98: e1a03001     	mov	r3, r1
    fe9c: e14b21fc     	strd	r2, r3, [r11, #-28]
    fea0: e51b3028     	ldr	r3, [r11, #-0x28]
    fea4: e1c340d0     	ldrd	r4, r5, [r3]
    fea8: e3a03000     	mov	r3, #0
    feac: e1a06003     	mov	r6, r3
    feb0: e14b01dc     	ldrd	r0, r1, [r11, #-28]
    feb4: e3a02000     	mov	r2, #0
    feb8: e3a03000     	mov	r3, #0
    febc: eb00829f     	bl	0x30940 <__aeabi_dcmpgt> @ imm = #0x20a7c
    fec0: e1a03000     	mov	r3, r0
    fec4: e3530000     	cmp	r3, #0
    fec8: 0a000001     	beq	0xfed4 <timeout_get+0x24c> @ imm = #0x4
    fecc: e3a03001     	mov	r3, #1
    fed0: e1a06003     	mov	r6, r3
    fed4: e6ef3076     	uxtb	r3, r6
    fed8: e3530000     	cmp	r3, #0
    fedc: 0a000001     	beq	0xfee8 <timeout_get+0x260> @ imm = #0x4
    fee0: e14b21dc     	ldrd	r2, r3, [r11, #-28]
    fee4: ea000001     	b	0xfef0 <timeout_get+0x268> @ imm = #0x4
    fee8: e3a02000     	mov	r2, #0
    feec: e3a03000     	mov	r3, #0
    fef0: e3a01000     	mov	r1, #0
    fef4: e1a06001     	mov	r6, r1
    fef8: e1a00004     	mov	r0, r4
    fefc: e1a01005     	mov	r1, r5
    ff00: eb00827f     	bl	0x30904 <__aeabi_dcmplt> @ imm = #0x209fc
    ff04: e1a03000     	mov	r3, r0
    ff08: e3530000     	cmp	r3, #0
    ff0c: 0a000001     	beq	0xff18 <timeout_get+0x290> @ imm = #0x4
    ff10: e3a03001     	mov	r3, #1
    ff14: e1a06003     	mov	r6, r3
    ff18: e6ef3076     	uxtb	r3, r6
    ff1c: e3530000     	cmp	r3, #0
    ff20: 0a000002     	beq	0xff30 <timeout_get+0x2a8> @ imm = #0x8
    ff24: e51b3028     	ldr	r3, [r11, #-0x28]
    ff28: e1c320d0     	ldrd	r2, r3, [r3]
    ff2c: ea000011     	b	0xff78 <timeout_get+0x2f0> @ imm = #0x44
    ff30: e3a03000     	mov	r3, #0
    ff34: e1a04003     	mov	r4, r3
    ff38: e14b01dc     	ldrd	r0, r1, [r11, #-28]
    ff3c: e3a02000     	mov	r2, #0
    ff40: e3a03000     	mov	r3, #0
    ff44: eb00827d     	bl	0x30940 <__aeabi_dcmpgt> @ imm = #0x209f4
    ff48: e1a03000     	mov	r3, r0
    ff4c: e3530000     	cmp	r3, #0
    ff50: 0a000001     	beq	0xff5c <timeout_get+0x2d4> @ imm = #0x4
    ff54: e3a03001     	mov	r3, #1
    ff58: e1a04003     	mov	r4, r3
    ff5c: e6ef3074     	uxtb	r3, r4
    ff60: e3530000     	cmp	r3, #0
    ff64: 0a000001     	beq	0xff70 <timeout_get+0x2e8> @ imm = #0x4
    ff68: e14b21dc     	ldrd	r2, r3, [r11, #-28]
    ff6c: ea000001     	b	0xff78 <timeout_get+0x2f0> @ imm = #0x4
    ff70: e3a02000     	mov	r2, #0
    ff74: e3a03000     	mov	r3, #0
    ff78: e1a00002     	mov	r0, r2
    ff7c: e1a01003     	mov	r1, r3
    ff80: e24bd010     	sub	sp, r11, #16
    ff84: e8bd8870     	pop	{r4, r5, r6, r11, pc}

