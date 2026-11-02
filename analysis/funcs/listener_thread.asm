0000cfac <listener_thread>:
    cfac: e92d4800     	push	{r11, lr}
    cfb0: e28db004     	add	r11, sp, #4
    cfb4: e24dd028     	sub	sp, sp, #40
    cfb8: e50b0028     	str	r0, [r11, #-0x28]
    cfbc: e24b301c     	sub	r3, r11, #28
    cfc0: e1a00003     	mov	r0, r3
    cfc4: e3a01000     	mov	r1, #0
    cfc8: e3a02010     	mov	r2, #16
    cfcc: ebfffcf4     	bl	0xc3a4 <memset@plt>     @ imm = #-0xc30
    cfd0: e3a03002     	mov	r3, #2
    cfd4: e14b31bc     	strh	r3, [r11, #-28]
    cfd8: e59f00e0     	ldr	r0, [pc, #0xe0]         @ 0xd0c0 <listener_thread+0x114>
    cfdc: ebfffced     	bl	0xc398 <htons@plt>      @ imm = #-0xc4c
    cfe0: e1a03000     	mov	r3, r0
    cfe4: e14b31ba     	strh	r3, [r11, #-26]
    cfe8: e3a00000     	mov	r0, #0
    cfec: ebfffdc7     	bl	0xc710 <htonl@plt>      @ imm = #-0x8e4
    cff0: e1a03000     	mov	r3, r0
    cff4: e50b3018     	str	r3, [r11, #-0x18]
    cff8: e3a00002     	mov	r0, #2
    cffc: e3a01001     	mov	r1, #1
    d000: e3a02006     	mov	r2, #6
    d004: ebfffd1f     	bl	0xc488 <socket@plt>     @ imm = #-0xb84
    d008: e1a03000     	mov	r3, r0
    d00c: e50b3008     	str	r3, [r11, #-0x8]
    d010: e24b201c     	sub	r2, r11, #28
    d014: e3a03000     	mov	r3, #0
    d018: e1a03002     	mov	r3, r2
    d01c: e51b0008     	ldr	r0, [r11, #-0x8]
    d020: e1a01003     	mov	r1, r3
    d024: e3a02010     	mov	r2, #16
    d028: ebfffd64     	bl	0xc5c0 <bind@plt>       @ imm = #-0xa70
    d02c: e1a03000     	mov	r3, r0
    d030: e3730001     	cmn	r3, #1
    d034: 0a000005     	beq	0xd050 <listener_thread+0xa4> @ imm = #0x14
    d038: e51b0008     	ldr	r0, [r11, #-0x8]
    d03c: e3a01001     	mov	r1, #1
    d040: ebfffcc2     	bl	0xc350 <listen@plt>     @ imm = #-0xcf8
    d044: e1a03000     	mov	r3, r0
    d048: e3730001     	cmn	r3, #1
    d04c: 1a000012     	bne	0xd09c <listener_thread+0xf0> @ imm = #0x48
    d050: e3a00000     	mov	r0, #0
    d054: ebfffc8d     	bl	0xc290 <pthread_exit@plt> @ imm = #-0xdcc
    d058: e3a03000     	mov	r3, #0
    d05c: e51b0008     	ldr	r0, [r11, #-0x8]
    d060: e1a01003     	mov	r1, r3
    d064: e3a02000     	mov	r2, #0
    d068: ebfffd00     	bl	0xc470 <accept@plt>     @ imm = #-0xc00
    d06c: e1a03000     	mov	r3, r0
    d070: e50b3020     	str	r3, [r11, #-0x20]
    d074: e51b3020     	ldr	r3, [r11, #-0x20]
    d078: e3530000     	cmp	r3, #0
    d07c: da000007     	ble	0xd0a0 <listener_thread+0xf4> @ imm = #0x1c
    d080: e24b200c     	sub	r2, r11, #12
    d084: e24b3020     	sub	r3, r11, #32
    d088: e1a00002     	mov	r0, r2
    d08c: e3a01000     	mov	r1, #0
    d090: e59f202c     	ldr	r2, [pc, #0x2c]         @ 0xd0c4 <listener_thread+0x118>
    d094: ebfffd19     	bl	0xc500 <pthread_create@plt> @ imm = #-0xb9c
    d098: ea000000     	b	0xd0a0 <listener_thread+0xf4> @ imm = #0x0
    d09c: e1a00000     	mov	r0, r0
    d0a0: ebfffe0f     	bl	0xc8e4 <user_requested_exit> @ imm = #-0x7c4
    d0a4: e1a03000     	mov	r3, r0
    d0a8: e3530000     	cmp	r3, #0
    d0ac: 0affffe9     	beq	0xd058 <listener_thread+0xac> @ imm = #-0x5c
    d0b0: e51b0008     	ldr	r0, [r11, #-0x8]
    d0b4: ebfffd4a     	bl	0xc5e4 <close@plt>      @ imm = #-0xad8
    d0b8: e3a00000     	mov	r0, #0
    d0bc: ebfffc73     	bl	0xc290 <pthread_exit@plt> @ imm = #-0xe34
    d0c0: d2 07 00 00  	.word	0x000007d2
    d0c4: 34 c9 00 00  	.word	0x0000c934

