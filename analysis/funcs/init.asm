0000d978 <init>:
    d978: e92d4800     	push	{r11, lr}
    d97c: e28db004     	add	r11, sp, #4
    d980: e24dd090     	sub	sp, sp, #144
    d984: e59f30c0     	ldr	r3, [pc, #0xc0]         @ 0xda4c <init+0xd4>
    d988: e3a02000     	mov	r2, #0
    d98c: e5832000     	str	r2, [r3]
    d990: e59f30b4     	ldr	r3, [pc, #0xb4]         @ 0xda4c <init+0xd4>
    d994: e3a02000     	mov	r2, #0
    d998: e5832004     	str	r2, [r3, #0x4]
    d99c: e59f30a8     	ldr	r3, [pc, #0xa8]         @ 0xda4c <init+0xd4>
    d9a0: e3a02000     	mov	r2, #0
    d9a4: e5832008     	str	r2, [r3, #0x8]
    d9a8: e59f309c     	ldr	r3, [pc, #0x9c]         @ 0xda4c <init+0xd4>
    d9ac: e3a02000     	mov	r2, #0
    d9b0: e5832014     	str	r2, [r3, #0x14]
    d9b4: e59f3090     	ldr	r3, [pc, #0x90]         @ 0xda4c <init+0xd4>
    d9b8: e3a02000     	mov	r2, #0
    d9bc: e5832010     	str	r2, [r3, #0x10]
    d9c0: e59f3084     	ldr	r3, [pc, #0x84]         @ 0xda4c <init+0xd4>
    d9c4: e3a02000     	mov	r2, #0
    d9c8: e583200c     	str	r2, [r3, #0xc]
    d9cc: e59f3078     	ldr	r3, [pc, #0x78]         @ 0xda4c <init+0xd4>
    d9d0: e3a02000     	mov	r2, #0
    d9d4: e5832018     	str	r2, [r3, #0x18]
    d9d8: e59f306c     	ldr	r3, [pc, #0x6c]         @ 0xda4c <init+0xd4>
    d9dc: e3a02000     	mov	r2, #0
    d9e0: e583201c     	str	r2, [r3, #0x1c]
    d9e4: e59f3060     	ldr	r3, [pc, #0x60]         @ 0xda4c <init+0xd4>
    d9e8: e3a02000     	mov	r2, #0
    d9ec: e5832020     	str	r2, [r3, #0x20]
    d9f0: e59f3054     	ldr	r3, [pc, #0x54]         @ 0xda4c <init+0xd4>
    d9f4: e59f2054     	ldr	r2, [pc, #0x54]         @ 0xda50 <init+0xd8>
    d9f8: e5832024     	str	r2, [r3, #0x24]
    d9fc: e24b3090     	sub	r3, r11, #144
    da00: e1a00003     	mov	r0, r3
    da04: e3a01000     	mov	r1, #0
    da08: e3a0208c     	mov	r2, #140
    da0c: ebfffa64     	bl	0xc3a4 <memset@plt>     @ imm = #-0x1670
    da10: e59f303c     	ldr	r3, [pc, #0x3c]         @ 0xda54 <init+0xdc>
    da14: e50b3090     	str	r3, [r11, #-0x90]
    da18: e24b3090     	sub	r3, r11, #144
    da1c: e3a00002     	mov	r0, #2
    da20: e1a01003     	mov	r1, r3
    da24: e3a02000     	mov	r2, #0
    da28: ebfffb14     	bl	0xc680 <sigaction@plt>  @ imm = #-0x13b0
    da2c: eb001e0d     	bl	0x15268 <init_logging>  @ imm = #0x7834
    da30: e3a00000     	mov	r0, #0
    da34: eb001f39     	bl	0x15720 <new_lock>      @ imm = #0x7ce4
    da38: e1a02000     	mov	r2, r0
    da3c: e59f3014     	ldr	r3, [pc, #0x14]         @ 0xda58 <init+0xe0>
    da40: e5832000     	str	r2, [r3]
    da44: e24bd004     	sub	sp, r11, #4
    da48: e8bd8800     	pop	{r11, pc}
    da4c: 0c 6e 05 00  	.word	0x00056e0c
    da50: 58 1c 03 00  	.word	0x00031c58
    da54: 78 d6 00 00  	.word	0x0000d678
    da58: 3c 71 05 00  	.word	0x0005713c

