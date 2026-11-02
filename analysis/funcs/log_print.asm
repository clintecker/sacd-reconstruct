00014cb4 <log_print>:
   14cb4: e92d000f     	push	{r0, r1, r2, r3}
   14cb8: e92d4830     	push	{r4, r5, r11, lr}
   14cbc: e28db00c     	add	r11, sp, #12
   14cc0: e24dde26     	sub	sp, sp, #608
   14cc4: e3a03000     	mov	r3, #0
   14cc8: e50b301c     	str	r3, [r11, #-0x1c]
   14ccc: e3a03000     	mov	r3, #0
   14cd0: e50b3018     	str	r3, [r11, #-0x18]
   14cd4: e3a03000     	mov	r3, #0
   14cd8: e50b3010     	str	r3, [r11, #-0x10]
   14cdc: e59f3428     	ldr	r3, [pc, #0x428]        @ 0x1510c <log_print+0x458>
   14ce0: e5933000     	ldr	r3, [r3]
   14ce4: e3530000     	cmp	r3, #0
   14ce8: 0a000102     	beq	0x150f8 <log_print+0x444> @ imm = #0x408
   14cec: e59f341c     	ldr	r3, [pc, #0x41c]        @ 0x15110 <log_print+0x45c>
   14cf0: e5933000     	ldr	r3, [r3]
   14cf4: e3530000     	cmp	r3, #0
   14cf8: 0a000021     	beq	0x14d84 <log_print+0xd0> @ imm = #0x84
   14cfc: e24b3f89     	sub	r3, r11, #548
   14d00: e1a00003     	mov	r0, r3
   14d04: ebffde42     	bl	0xc614 <time@plt>       @ imm = #-0x86f8
   14d08: e24b3f89     	sub	r3, r11, #548
   14d0c: e1a00003     	mov	r0, r3
   14d10: ebffdd52     	bl	0xc260 <localtime@plt>  @ imm = #-0x8ab8
   14d14: e1a03000     	mov	r3, r0
   14d18: e24bce25     	sub	r12, r11, #592
   14d1c: e1a0e003     	mov	lr, r3
   14d20: e8be000f     	ldm	lr!, {r0, r1, r2, r3}
   14d24: e8ac000f     	stm	r12!, {r0, r1, r2, r3}
   14d28: e8be000f     	ldm	lr!, {r0, r1, r2, r3}
   14d2c: e8ac000f     	stm	r12!, {r0, r1, r2, r3}
   14d30: e89e0007     	ldm	lr, {r0, r1, r2}
   14d34: e88c0007     	stm	r12, {r0, r1, r2}
   14d38: e59f23d4     	ldr	r2, [pc, #0x3d4]        @ 0x15114 <log_print+0x460>
   14d3c: e51b323c     	ldr	r3, [r11, #-0x23c]
   14d40: e51b1240     	ldr	r1, [r11, #-0x240]
   14d44: e2815001     	add	r5, r1, #1
   14d48: e51b4244     	ldr	r4, [r11, #-0x244]
   14d4c: e51be248     	ldr	lr, [r11, #-0x248]
   14d50: e51bc24c     	ldr	r12, [r11, #-0x24c]
   14d54: e51b0250     	ldr	r0, [r11, #-0x250]
   14d58: e24b1e22     	sub	r1, r11, #544
   14d5c: e58d5000     	str	r5, [sp]
   14d60: e58d4004     	str	r4, [sp, #0x4]
   14d64: e58de008     	str	lr, [sp, #0x8]
   14d68: e58dc00c     	str	r12, [sp, #0xc]
   14d6c: e58d0010     	str	r0, [sp, #0x10]
   14d70: e1a00001     	mov	r0, r1
   14d74: e59f139c     	ldr	r1, [pc, #0x39c]        @ 0x15118 <log_print+0x464>
   14d78: ebffde70     	bl	0xc740 <snprintf@plt>   @ imm = #-0x8640
   14d7c: e1a03000     	mov	r3, r0
   14d80: e50b3018     	str	r3, [r11, #-0x18]
   14d84: e24b2e22     	sub	r2, r11, #544
   14d88: e51b3018     	ldr	r3, [r11, #-0x18]
   14d8c: e0822003     	add	r2, r2, r3
   14d90: e51b3018     	ldr	r3, [r11, #-0x18]
   14d94: e2633f7f     	rsb	r3, r3, #508
   14d98: e2833003     	add	r3, r3, #3
   14d9c: e59fc378     	ldr	r12, [pc, #0x378]       @ 0x1511c <log_print+0x468>
   14da0: e1a00002     	mov	r0, r2
   14da4: e1a01003     	mov	r1, r3
   14da8: e1a0200c     	mov	r2, r12
   14dac: e51b3010     	ldr	r3, [r11, #-0x10]
   14db0: ebffde62     	bl	0xc740 <snprintf@plt>   @ imm = #-0x8678
   14db4: e1a03000     	mov	r3, r0
   14db8: e51b2018     	ldr	r2, [r11, #-0x18]
   14dbc: e0823003     	add	r3, r2, r3
   14dc0: e50b3018     	str	r3, [r11, #-0x18]
   14dc4: e28b3008     	add	r3, r11, #8
   14dc8: e50b3020     	str	r3, [r11, #-0x20]
   14dcc: e24b2e22     	sub	r2, r11, #544
   14dd0: e51b3018     	ldr	r3, [r11, #-0x18]
   14dd4: e0822003     	add	r2, r2, r3
   14dd8: e51b3018     	ldr	r3, [r11, #-0x18]
   14ddc: e2633f7f     	rsb	r3, r3, #508
   14de0: e2833003     	add	r3, r3, #3
   14de4: e1a00002     	mov	r0, r2
   14de8: e1a01003     	mov	r1, r3
   14dec: e59b2004     	ldr	r2, [r11, #0x4]
   14df0: e51b3020     	ldr	r3, [r11, #-0x20]
   14df4: ebffdd34     	bl	0xc2cc <vsnprintf@plt>  @ imm = #-0x8b30
   14df8: e1a03000     	mov	r3, r0
   14dfc: e1a02003     	mov	r2, r3
   14e00: e51b3018     	ldr	r3, [r11, #-0x18]
   14e04: e0823003     	add	r3, r2, r3
   14e08: e50b3014     	str	r3, [r11, #-0x14]
   14e0c: e51b2014     	ldr	r2, [r11, #-0x14]
   14e10: e59f3308     	ldr	r3, [pc, #0x308]        @ 0x15120 <log_print+0x46c>
   14e14: e1520003     	cmp	r2, r3
   14e18: 1a00000a     	bne	0x14e48 <log_print+0x194> @ imm = #0x28
   14e1c: e3a00a01     	mov	r0, #4096
   14e20: ebffde10     	bl	0xc668 <malloc@plt>     @ imm = #-0x87c0
   14e24: e1a03000     	mov	r3, r0
   14e28: e50b301c     	str	r3, [r11, #-0x1c]
   14e2c: e28b3008     	add	r3, r11, #8
   14e30: e50b3020     	str	r3, [r11, #-0x20]
   14e34: e51b001c     	ldr	r0, [r11, #-0x1c]
   14e38: e3a01c02     	mov	r1, #512
   14e3c: e59b2004     	ldr	r2, [r11, #0x4]
   14e40: e51b3020     	ldr	r3, [r11, #-0x20]
   14e44: ebffdd20     	bl	0xc2cc <vsnprintf@plt>  @ imm = #-0x8b80
   14e48: e51b301c     	ldr	r3, [r11, #-0x1c]
   14e4c: e3530000     	cmp	r3, #0
   14e50: 0a00004e     	beq	0x14f90 <log_print+0x2dc> @ imm = #0x138
   14e54: e51b001c     	ldr	r0, [r11, #-0x1c]
   14e58: ebffdd9f     	bl	0xc4dc <strlen@plt>     @ imm = #-0x8984
   14e5c: e1a03000     	mov	r3, r0
   14e60: e50b3014     	str	r3, [r11, #-0x14]
   14e64: e59f32b8     	ldr	r3, [pc, #0x2b8]        @ 0x15124 <log_print+0x470>
   14e68: e5933000     	ldr	r3, [r3]
   14e6c: e3530000     	cmp	r3, #0
   14e70: 0a000015     	beq	0x14ecc <log_print+0x218> @ imm = #0x54
   14e74: e59f32a8     	ldr	r3, [pc, #0x2a8]        @ 0x15124 <log_print+0x470>
   14e78: e5931000     	ldr	r1, [r3]
   14e7c: e59f32a4     	ldr	r3, [pc, #0x2a4]        @ 0x15128 <log_print+0x474>
   14e80: e5933000     	ldr	r3, [r3]
   14e84: e1a02003     	mov	r2, r3
   14e88: e59f3294     	ldr	r3, [pc, #0x294]        @ 0x15124 <log_print+0x470>
   14e8c: e5933000     	ldr	r3, [r3]
   14e90: e0633002     	rsb	r3, r3, r2
   14e94: e1a02003     	mov	r2, r3
   14e98: e59f326c     	ldr	r3, [pc, #0x26c]        @ 0x1510c <log_print+0x458>
   14e9c: e5933000     	ldr	r3, [r3]
   14ea0: e1a00001     	mov	r0, r1
   14ea4: e3a01001     	mov	r1, #1
   14ea8: ebffddd0     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x88c0
   14eac: e59f3258     	ldr	r3, [pc, #0x258]        @ 0x1510c <log_print+0x458>
   14eb0: e5933000     	ldr	r3, [r3]
   14eb4: e1a00003     	mov	r0, r3
   14eb8: ebffdd75     	bl	0xc494 <fflush@plt>     @ imm = #-0x8a2c
   14ebc: e59f3260     	ldr	r3, [pc, #0x260]        @ 0x15124 <log_print+0x470>
   14ec0: e5932000     	ldr	r2, [r3]
   14ec4: e59f325c     	ldr	r3, [pc, #0x25c]        @ 0x15128 <log_print+0x474>
   14ec8: e5832000     	str	r2, [r3]
   14ecc: e59f3238     	ldr	r3, [pc, #0x238]        @ 0x1510c <log_print+0x458>
   14ed0: e5933000     	ldr	r3, [r3]
   14ed4: e24b2e22     	sub	r2, r11, #544
   14ed8: e1a00002     	mov	r0, r2
   14edc: e3a01001     	mov	r1, #1
   14ee0: e51b2018     	ldr	r2, [r11, #-0x18]
   14ee4: ebffddc1     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x88fc
   14ee8: e59f321c     	ldr	r3, [pc, #0x21c]        @ 0x1510c <log_print+0x458>
   14eec: e5933000     	ldr	r3, [r3]
   14ef0: e1a00003     	mov	r0, r3
   14ef4: ebffdd66     	bl	0xc494 <fflush@plt>     @ imm = #-0x8a68
   14ef8: e59f320c     	ldr	r3, [pc, #0x20c]        @ 0x1510c <log_print+0x458>
   14efc: e5933000     	ldr	r3, [r3]
   14f00: e51b001c     	ldr	r0, [r11, #-0x1c]
   14f04: e3a01001     	mov	r1, #1
   14f08: e51b2014     	ldr	r2, [r11, #-0x14]
   14f0c: ebffddb7     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x8924
   14f10: e59f31f4     	ldr	r3, [pc, #0x1f4]        @ 0x1510c <log_print+0x458>
   14f14: e5933000     	ldr	r3, [r3]
   14f18: e1a00003     	mov	r0, r3
   14f1c: ebffdd5c     	bl	0xc494 <fflush@plt>     @ imm = #-0x8a90
   14f20: e51b3014     	ldr	r3, [r11, #-0x14]
   14f24: e3530000     	cmp	r3, #0
   14f28: 0a000006     	beq	0x14f48 <log_print+0x294> @ imm = #0x18
   14f2c: e51b3014     	ldr	r3, [r11, #-0x14]
   14f30: e2433001     	sub	r3, r3, #1
   14f34: e51b201c     	ldr	r2, [r11, #-0x1c]
   14f38: e0823003     	add	r3, r2, r3
   14f3c: e5d33000     	ldrb	r3, [r3]
   14f40: e353000a     	cmp	r3, #10
   14f44: 0a00000e     	beq	0x14f84 <log_print+0x2d0> @ imm = #0x38
   14f48: e3a0300a     	mov	r3, #10
   14f4c: e54b3254     	strb	r3, [r11, #-0x254]
   14f50: e3a03000     	mov	r3, #0
   14f54: e54b3253     	strb	r3, [r11, #-0x253]
   14f58: e59f31ac     	ldr	r3, [pc, #0x1ac]        @ 0x1510c <log_print+0x458>
   14f5c: e5933000     	ldr	r3, [r3]
   14f60: e24b2f95     	sub	r2, r11, #596
   14f64: e1a00002     	mov	r0, r2
   14f68: e3a01001     	mov	r1, #1
   14f6c: e3a02001     	mov	r2, #1
   14f70: ebffdd9e     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x8988
   14f74: e59f3190     	ldr	r3, [pc, #0x190]        @ 0x1510c <log_print+0x458>
   14f78: e5933000     	ldr	r3, [r3]
   14f7c: e1a00003     	mov	r0, r3
   14f80: ebffdd43     	bl	0xc494 <fflush@plt>     @ imm = #-0x8af4
   14f84: e51b001c     	ldr	r0, [r11, #-0x1c]
   14f88: ebffdd23     	bl	0xc41c <free@plt>       @ imm = #-0x8b74
   14f8c: ea000057     	b	0x150f0 <log_print+0x43c> @ imm = #0x15c
   14f90: e51b3014     	ldr	r3, [r11, #-0x14]
   14f94: e3530000     	cmp	r3, #0
   14f98: 0a000019     	beq	0x15004 <log_print+0x350> @ imm = #0x64
   14f9c: e51b3014     	ldr	r3, [r11, #-0x14]
   14fa0: e2432001     	sub	r2, r3, #1
   14fa4: e59f3180     	ldr	r3, [pc, #0x180]        @ 0x1512c <log_print+0x478>
   14fa8: e24b100c     	sub	r1, r11, #12
   14fac: e0812002     	add	r2, r1, r2
   14fb0: e0823003     	add	r3, r2, r3
   14fb4: e5d33000     	ldrb	r3, [r3]
   14fb8: e353000a     	cmp	r3, #10
   14fbc: 0a000010     	beq	0x15004 <log_print+0x350> @ imm = #0x40
   14fc0: e51b2014     	ldr	r2, [r11, #-0x14]
   14fc4: e59f3160     	ldr	r3, [pc, #0x160]        @ 0x1512c <log_print+0x478>
   14fc8: e24b100c     	sub	r1, r11, #12
   14fcc: e0812002     	add	r2, r1, r2
   14fd0: e0823003     	add	r3, r2, r3
   14fd4: e3a0200a     	mov	r2, #10
   14fd8: e5c32000     	strb	r2, [r3]
   14fdc: e51b3014     	ldr	r3, [r11, #-0x14]
   14fe0: e2833001     	add	r3, r3, #1
   14fe4: e50b3014     	str	r3, [r11, #-0x14]
   14fe8: e51b2014     	ldr	r2, [r11, #-0x14]
   14fec: e59f3138     	ldr	r3, [pc, #0x138]        @ 0x1512c <log_print+0x478>
   14ff0: e24b100c     	sub	r1, r11, #12
   14ff4: e0812002     	add	r2, r1, r2
   14ff8: e0823003     	add	r3, r2, r3
   14ffc: e3a02000     	mov	r2, #0
   15000: e5c32000     	strb	r2, [r3]
   15004: e59f3118     	ldr	r3, [pc, #0x118]        @ 0x15124 <log_print+0x470>
   15008: e5933000     	ldr	r3, [r3]
   1500c: e3530000     	cmp	r3, #0
   15010: 1a00000b     	bne	0x15044 <log_print+0x390> @ imm = #0x2c
   15014: e59f30f0     	ldr	r3, [pc, #0xf0]         @ 0x1510c <log_print+0x458>
   15018: e5933000     	ldr	r3, [r3]
   1501c: e24b2e22     	sub	r2, r11, #544
   15020: e1a00002     	mov	r0, r2
   15024: e3a01001     	mov	r1, #1
   15028: e51b2014     	ldr	r2, [r11, #-0x14]
   1502c: ebffdd6f     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x8a44
   15030: e59f30d4     	ldr	r3, [pc, #0xd4]         @ 0x1510c <log_print+0x458>
   15034: e5933000     	ldr	r3, [r3]
   15038: e1a00003     	mov	r0, r3
   1503c: ebffdd14     	bl	0xc494 <fflush@plt>     @ imm = #-0x8bb0
   15040: ea00002a     	b	0x150f0 <log_print+0x43c> @ imm = #0xa8
   15044: e59f30dc     	ldr	r3, [pc, #0xdc]         @ 0x15128 <log_print+0x474>
   15048: e5932000     	ldr	r2, [r3]
   1504c: e51b3014     	ldr	r3, [r11, #-0x14]
   15050: e0822003     	add	r2, r2, r3
   15054: e59f30d4     	ldr	r3, [pc, #0xd4]         @ 0x15130 <log_print+0x47c>
   15058: e5933000     	ldr	r3, [r3]
   1505c: e1520003     	cmp	r2, r3
   15060: 9a000015     	bls	0x150bc <log_print+0x408> @ imm = #0x54
   15064: e59f30b8     	ldr	r3, [pc, #0xb8]         @ 0x15124 <log_print+0x470>
   15068: e5931000     	ldr	r1, [r3]
   1506c: e59f30b4     	ldr	r3, [pc, #0xb4]         @ 0x15128 <log_print+0x474>
   15070: e5933000     	ldr	r3, [r3]
   15074: e1a02003     	mov	r2, r3
   15078: e59f30a4     	ldr	r3, [pc, #0xa4]         @ 0x15124 <log_print+0x470>
   1507c: e5933000     	ldr	r3, [r3]
   15080: e0633002     	rsb	r3, r3, r2
   15084: e1a02003     	mov	r2, r3
   15088: e59f307c     	ldr	r3, [pc, #0x7c]         @ 0x1510c <log_print+0x458>
   1508c: e5933000     	ldr	r3, [r3]
   15090: e1a00001     	mov	r0, r1
   15094: e3a01001     	mov	r1, #1
   15098: ebffdd54     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x8ab0
   1509c: e59f3068     	ldr	r3, [pc, #0x68]         @ 0x1510c <log_print+0x458>
   150a0: e5933000     	ldr	r3, [r3]
   150a4: e1a00003     	mov	r0, r3
   150a8: ebffdcf9     	bl	0xc494 <fflush@plt>     @ imm = #-0x8c1c
   150ac: e59f3070     	ldr	r3, [pc, #0x70]         @ 0x15124 <log_print+0x470>
   150b0: e5932000     	ldr	r2, [r3]
   150b4: e59f306c     	ldr	r3, [pc, #0x6c]         @ 0x15128 <log_print+0x474>
   150b8: e5832000     	str	r2, [r3]
   150bc: e59f3064     	ldr	r3, [pc, #0x64]         @ 0x15128 <log_print+0x474>
   150c0: e5932000     	ldr	r2, [r3]
   150c4: e24b3e22     	sub	r3, r11, #544
   150c8: e1a00002     	mov	r0, r2
   150cc: e1a01003     	mov	r1, r3
   150d0: e51b2014     	ldr	r2, [r11, #-0x14]
   150d4: ebffdd0c     	bl	0xc50c <memcpy@plt>     @ imm = #-0x8bd0
   150d8: e59f3048     	ldr	r3, [pc, #0x48]         @ 0x15128 <log_print+0x474>
   150dc: e5932000     	ldr	r2, [r3]
   150e0: e51b3014     	ldr	r3, [r11, #-0x14]
   150e4: e0822003     	add	r2, r2, r3
   150e8: e59f3038     	ldr	r3, [pc, #0x38]         @ 0x15128 <log_print+0x474>
   150ec: e5832000     	str	r2, [r3]
   150f0: eb00000f     	bl	0x15134 <log_flush>     @ imm = #0x3c
   150f4: ea000000     	b	0x150fc <log_print+0x448> @ imm = #0x0
   150f8: e1a00000     	mov	r0, r0
   150fc: e24bd00c     	sub	sp, r11, #12
   15100: e8bd4830     	pop	{r4, r5, r11, lr}
   15104: e28dd010     	add	sp, sp, #16
   15108: e12fff1e     	bx	lr
   1510c: 54 73 05 00  	.word	0x00057354
   15110: 58 73 05 00  	.word	0x00057358
   15114: dc 29 03 00  	.word	0x000329dc
   15118: ff 01 00 00  	.word	0x000001ff
   1511c: 00 2a 03 00  	.word	0x00032a00
   15120: fe 01 00 00  	.word	0x000001fe
   15124: 48 73 05 00  	.word	0x00057348
   15128: 4c 73 05 00  	.word	0x0005734c
   1512c: ec fd ff ff  	.word	0xfffffdec
   15130: 50 73 05 00  	.word	0x00057350

