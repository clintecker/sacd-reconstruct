00018cd4 <ReadFilterCoefSets>:
   18cd4: e92d4800     	push	{r11, lr}
   18cd8: e28db004     	add	r11, sp, #4
   18cdc: e24dd030     	sub	sp, sp, #48
   18ce0: e50b0028     	str	r0, [r11, #-0x28]
   18ce4: e50b102c     	str	r1, [r11, #-0x2c]
   18ce8: e50b2030     	str	r2, [r11, #-0x30]
   18cec: e50b3034     	str	r3, [r11, #-0x34]
   18cf0: e3a03000     	mov	r3, #0
   18cf4: e50b3014     	str	r3, [r11, #-0x14]
   18cf8: ea000152     	b	0x19248 <ReadFilterCoefSets+0x574> @ imm = #0x548
   18cfc: e51b3030     	ldr	r3, [r11, #-0x30]
   18d00: e2832014     	add	r2, r3, #20
   18d04: e51b3014     	ldr	r3, [r11, #-0x14]
   18d08: e1a03103     	lsl	r3, r3, #2
   18d0c: e0823003     	add	r3, r2, r3
   18d10: e51b0028     	ldr	r0, [r11, #-0x28]
   18d14: e3a01007     	mov	r1, #7
   18d18: e1a02003     	mov	r2, r3
   18d1c: eb000ac3     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x2b0c
   18d20: e1a03000     	mov	r3, r0
   18d24: e3530000     	cmp	r3, #0
   18d28: 0a000001     	beq	0x18d34 <ReadFilterCoefSets+0x60> @ imm = #0x4
   18d2c: e3a03001     	mov	r3, #1
   18d30: ea00016a     	b	0x192e0 <ReadFilterCoefSets+0x60c> @ imm = #0x5a8
   18d34: e51b3014     	ldr	r3, [r11, #-0x14]
   18d38: e51b0030     	ldr	r0, [r11, #-0x30]
   18d3c: e2831004     	add	r1, r3, #4
   18d40: e3a02004     	mov	r2, #4
   18d44: e1a01101     	lsl	r1, r1, #2
   18d48: e0801001     	add	r1, r0, r1
   18d4c: e0812002     	add	r2, r1, r2
   18d50: e5922000     	ldr	r2, [r2]
   18d54: e2822001     	add	r2, r2, #1
   18d58: e51b0030     	ldr	r0, [r11, #-0x30]
   18d5c: e2831004     	add	r1, r3, #4
   18d60: e3a03004     	mov	r3, #4
   18d64: e1a01101     	lsl	r1, r1, #2
   18d68: e0801001     	add	r1, r0, r1
   18d6c: e0813003     	add	r3, r1, r3
   18d70: e5832000     	str	r2, [r3]
   18d74: e51b3034     	ldr	r3, [r11, #-0x34]
   18d78: e5932008     	ldr	r2, [r3, #0x8]
   18d7c: e51b3014     	ldr	r3, [r11, #-0x14]
   18d80: e1a03103     	lsl	r3, r3, #2
   18d84: e0823003     	add	r3, r2, r3
   18d88: e51b0028     	ldr	r0, [r11, #-0x28]
   18d8c: e3a01001     	mov	r1, #1
   18d90: e1a02003     	mov	r2, r3
   18d94: eb000aa5     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x2a94
   18d98: e1a03000     	mov	r3, r0
   18d9c: e3530000     	cmp	r3, #0
   18da0: 0a000001     	beq	0x18dac <ReadFilterCoefSets+0xd8> @ imm = #0x4
   18da4: e3a03001     	mov	r3, #1
   18da8: ea00014c     	b	0x192e0 <ReadFilterCoefSets+0x60c> @ imm = #0x530
   18dac: e51b3034     	ldr	r3, [r11, #-0x34]
   18db0: e5932008     	ldr	r2, [r3, #0x8]
   18db4: e51b3014     	ldr	r3, [r11, #-0x14]
   18db8: e1a03103     	lsl	r3, r3, #2
   18dbc: e0823003     	add	r3, r2, r3
   18dc0: e5933000     	ldr	r3, [r3]
   18dc4: e3530000     	cmp	r3, #0
   18dc8: 1a00002a     	bne	0x18e78 <ReadFilterCoefSets+0x1a4> @ imm = #0xa8
   18dcc: e51b3034     	ldr	r3, [r11, #-0x34]
   18dd0: e593200c     	ldr	r2, [r3, #0xc]
   18dd4: e51b3014     	ldr	r3, [r11, #-0x14]
   18dd8: e1a03103     	lsl	r3, r3, #2
   18ddc: e0823003     	add	r3, r2, r3
   18de0: e3e02000     	mvn	r2, #0
   18de4: e5832000     	str	r2, [r3]
   18de8: e3a03000     	mov	r3, #0
   18dec: e50b3018     	str	r3, [r11, #-0x18]
   18df0: ea000014     	b	0x18e48 <ReadFilterCoefSets+0x174> @ imm = #0x50
   18df4: e51b3030     	ldr	r3, [r11, #-0x30]
   18df8: e5932074     	ldr	r2, [r3, #0x74]
   18dfc: e51b3014     	ldr	r3, [r11, #-0x14]
   18e00: e1a03103     	lsl	r3, r3, #2
   18e04: e0823003     	add	r3, r2, r3
   18e08: e5932000     	ldr	r2, [r3]
   18e0c: e51b3018     	ldr	r3, [r11, #-0x18]
   18e10: e1a03083     	lsl	r3, r3, #1
   18e14: e0823003     	add	r3, r2, r3
   18e18: e51b0028     	ldr	r0, [r11, #-0x28]
   18e1c: e3a01009     	mov	r1, #9
   18e20: e1a02003     	mov	r2, r3
   18e24: eb000aeb     	bl	0x1b9d8 <FIO_BitGetShortSigned> @ imm = #0x2bac
   18e28: e1a03000     	mov	r3, r0
   18e2c: e3530000     	cmp	r3, #0
   18e30: 0a000001     	beq	0x18e3c <ReadFilterCoefSets+0x168> @ imm = #0x4
   18e34: e3a03001     	mov	r3, #1
   18e38: ea000128     	b	0x192e0 <ReadFilterCoefSets+0x60c> @ imm = #0x4a0
   18e3c: e51b3018     	ldr	r3, [r11, #-0x18]
   18e40: e2833001     	add	r3, r3, #1
   18e44: e50b3018     	str	r3, [r11, #-0x18]
   18e48: e51b3014     	ldr	r3, [r11, #-0x14]
   18e4c: e51b1030     	ldr	r1, [r11, #-0x30]
   18e50: e2832004     	add	r2, r3, #4
   18e54: e3a03004     	mov	r3, #4
   18e58: e1a02102     	lsl	r2, r2, #2
   18e5c: e0812002     	add	r2, r1, r2
   18e60: e0823003     	add	r3, r2, r3
   18e64: e5932000     	ldr	r2, [r3]
   18e68: e51b3018     	ldr	r3, [r11, #-0x18]
   18e6c: e1520003     	cmp	r2, r3
   18e70: caffffdf     	bgt	0x18df4 <ReadFilterCoefSets+0x120> @ imm = #-0x84
   18e74: ea0000e0     	b	0x191fc <ReadFilterCoefSets+0x528> @ imm = #0x380
   18e78: e51b3034     	ldr	r3, [r11, #-0x34]
   18e7c: e593200c     	ldr	r2, [r3, #0xc]
   18e80: e51b3014     	ldr	r3, [r11, #-0x14]
   18e84: e1a03103     	lsl	r3, r3, #2
   18e88: e0823003     	add	r3, r2, r3
   18e8c: e51b0028     	ldr	r0, [r11, #-0x28]
   18e90: e3a01002     	mov	r1, #2
   18e94: e1a02003     	mov	r2, r3
   18e98: eb000a64     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x2990
   18e9c: e1a03000     	mov	r3, r0
   18ea0: e3530000     	cmp	r3, #0
   18ea4: 0a000001     	beq	0x18eb0 <ReadFilterCoefSets+0x1dc> @ imm = #0x4
   18ea8: e3a03001     	mov	r3, #1
   18eac: ea00010b     	b	0x192e0 <ReadFilterCoefSets+0x60c> @ imm = #0x42c
   18eb0: e51b3034     	ldr	r3, [r11, #-0x34]
   18eb4: e593200c     	ldr	r2, [r3, #0xc]
   18eb8: e51b3014     	ldr	r3, [r11, #-0x14]
   18ebc: e1a03103     	lsl	r3, r3, #2
   18ec0: e0823003     	add	r3, r2, r3
   18ec4: e5933000     	ldr	r3, [r3]
   18ec8: e50b3008     	str	r3, [r11, #-0x8]
   18ecc: e51b3034     	ldr	r3, [r11, #-0x34]
   18ed0: e5932000     	ldr	r2, [r3]
   18ed4: e51b3008     	ldr	r3, [r11, #-0x8]
   18ed8: e1a03103     	lsl	r3, r3, #2
   18edc: e0823003     	add	r3, r2, r3
   18ee0: e5932000     	ldr	r2, [r3]
   18ee4: e51b3014     	ldr	r3, [r11, #-0x14]
   18ee8: e51b0030     	ldr	r0, [r11, #-0x30]
   18eec: e2831004     	add	r1, r3, #4
   18ef0: e3a03004     	mov	r3, #4
   18ef4: e1a01101     	lsl	r1, r1, #2
   18ef8: e0801001     	add	r1, r0, r1
   18efc: e0813003     	add	r3, r1, r3
   18f00: e5933000     	ldr	r3, [r3]
   18f04: e1520003     	cmp	r2, r3
   18f08: ba000001     	blt	0x18f14 <ReadFilterCoefSets+0x240> @ imm = #0x4
   18f0c: e3a03009     	mov	r3, #9
   18f10: ea0000f2     	b	0x192e0 <ReadFilterCoefSets+0x60c> @ imm = #0x3c8
   18f14: e3a03000     	mov	r3, #0
   18f18: e50b3018     	str	r3, [r11, #-0x18]
   18f1c: ea000014     	b	0x18f74 <ReadFilterCoefSets+0x2a0> @ imm = #0x50
   18f20: e51b3030     	ldr	r3, [r11, #-0x30]
   18f24: e5932074     	ldr	r2, [r3, #0x74]
   18f28: e51b3014     	ldr	r3, [r11, #-0x14]
   18f2c: e1a03103     	lsl	r3, r3, #2
   18f30: e0823003     	add	r3, r2, r3
   18f34: e5932000     	ldr	r2, [r3]
   18f38: e51b3018     	ldr	r3, [r11, #-0x18]
   18f3c: e1a03083     	lsl	r3, r3, #1
   18f40: e0823003     	add	r3, r2, r3
   18f44: e51b0028     	ldr	r0, [r11, #-0x28]
   18f48: e3a01009     	mov	r1, #9
   18f4c: e1a02003     	mov	r2, r3
   18f50: eb000aa0     	bl	0x1b9d8 <FIO_BitGetShortSigned> @ imm = #0x2a80
   18f54: e1a03000     	mov	r3, r0
   18f58: e3530000     	cmp	r3, #0
   18f5c: 0a000001     	beq	0x18f68 <ReadFilterCoefSets+0x294> @ imm = #0x4
   18f60: e3a03001     	mov	r3, #1
   18f64: ea0000dd     	b	0x192e0 <ReadFilterCoefSets+0x60c> @ imm = #0x374
   18f68: e51b3018     	ldr	r3, [r11, #-0x18]
   18f6c: e2833001     	add	r3, r3, #1
   18f70: e50b3018     	str	r3, [r11, #-0x18]
   18f74: e51b3034     	ldr	r3, [r11, #-0x34]
   18f78: e5932000     	ldr	r2, [r3]
   18f7c: e51b3008     	ldr	r3, [r11, #-0x8]
   18f80: e1a03103     	lsl	r3, r3, #2
   18f84: e0823003     	add	r3, r2, r3
   18f88: e5932000     	ldr	r2, [r3]
   18f8c: e51b3018     	ldr	r3, [r11, #-0x18]
   18f90: e1520003     	cmp	r2, r3
   18f94: caffffe1     	bgt	0x18f20 <ReadFilterCoefSets+0x24c> @ imm = #-0x7c
   18f98: e51b3034     	ldr	r3, [r11, #-0x34]
   18f9c: e5932010     	ldr	r2, [r3, #0x10]
   18fa0: e51b3014     	ldr	r3, [r11, #-0x14]
   18fa4: e1a03103     	lsl	r3, r3, #2
   18fa8: e0823003     	add	r3, r2, r3
   18fac: e5932000     	ldr	r2, [r3]
   18fb0: e51b3008     	ldr	r3, [r11, #-0x8]
   18fb4: e1a03103     	lsl	r3, r3, #2
   18fb8: e0823003     	add	r3, r2, r3
   18fbc: e51b0028     	ldr	r0, [r11, #-0x28]
   18fc0: e3a01003     	mov	r1, #3
   18fc4: e1a02003     	mov	r2, r3
   18fc8: eb000a18     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x2860
   18fcc: e1a03000     	mov	r3, r0
   18fd0: e3530000     	cmp	r3, #0
   18fd4: 0a000001     	beq	0x18fe0 <ReadFilterCoefSets+0x30c> @ imm = #0x4
   18fd8: e3a03001     	mov	r3, #1
   18fdc: ea0000bf     	b	0x192e0 <ReadFilterCoefSets+0x60c> @ imm = #0x2fc
   18fe0: e51b3034     	ldr	r3, [r11, #-0x34]
   18fe4: e5932000     	ldr	r2, [r3]
   18fe8: e51b3008     	ldr	r3, [r11, #-0x8]
   18fec: e1a03103     	lsl	r3, r3, #2
   18ff0: e0823003     	add	r3, r2, r3
   18ff4: e5933000     	ldr	r3, [r3]
   18ff8: e50b3018     	str	r3, [r11, #-0x18]
   18ffc: ea000073     	b	0x191d0 <ReadFilterCoefSets+0x4fc> @ imm = #0x1cc
   19000: e3a03000     	mov	r3, #0
   19004: e50b3010     	str	r3, [r11, #-0x10]
   19008: e3a03000     	mov	r3, #0
   1900c: e50b300c     	str	r3, [r11, #-0xc]
   19010: ea00001e     	b	0x19090 <ReadFilterCoefSets+0x3bc> @ imm = #0x78
   19014: e51b3034     	ldr	r3, [r11, #-0x34]
   19018: e5932004     	ldr	r2, [r3, #0x4]
   1901c: e51b3008     	ldr	r3, [r11, #-0x8]
   19020: e1a03103     	lsl	r3, r3, #2
   19024: e0823003     	add	r3, r2, r3
   19028: e5932000     	ldr	r2, [r3]
   1902c: e51b3010     	ldr	r3, [r11, #-0x10]
   19030: e1a03103     	lsl	r3, r3, #2
   19034: e0823003     	add	r3, r2, r3
   19038: e5933000     	ldr	r3, [r3]
   1903c: e51b2030     	ldr	r2, [r11, #-0x30]
   19040: e5921074     	ldr	r1, [r2, #0x74]
   19044: e51b2014     	ldr	r2, [r11, #-0x14]
   19048: e1a02102     	lsl	r2, r2, #2
   1904c: e0812002     	add	r2, r1, r2
   19050: e5921000     	ldr	r1, [r2]
   19054: e51b0018     	ldr	r0, [r11, #-0x18]
   19058: e51b2010     	ldr	r2, [r11, #-0x10]
   1905c: e0622000     	rsb	r2, r2, r0
   19060: e2422001     	sub	r2, r2, #1
   19064: e1a02082     	lsl	r2, r2, #1
   19068: e0812002     	add	r2, r1, r2
   1906c: e1d220b0     	ldrh	r2, [r2]
   19070: e6bf2072     	sxth	r2, r2
   19074: e0030392     	mul	r3, r2, r3
   19078: e51b200c     	ldr	r2, [r11, #-0xc]
   1907c: e0823003     	add	r3, r2, r3
   19080: e50b300c     	str	r3, [r11, #-0xc]
   19084: e51b3010     	ldr	r3, [r11, #-0x10]
   19088: e2833001     	add	r3, r3, #1
   1908c: e50b3010     	str	r3, [r11, #-0x10]
   19090: e51b3034     	ldr	r3, [r11, #-0x34]
   19094: e5932000     	ldr	r2, [r3]
   19098: e51b3008     	ldr	r3, [r11, #-0x8]
   1909c: e1a03103     	lsl	r3, r3, #2
   190a0: e0823003     	add	r3, r2, r3
   190a4: e5932000     	ldr	r2, [r3]
   190a8: e51b3010     	ldr	r3, [r11, #-0x10]
   190ac: e1520003     	cmp	r2, r3
   190b0: caffffd7     	bgt	0x19014 <ReadFilterCoefSets+0x340> @ imm = #-0xa4
   190b4: e51b300c     	ldr	r3, [r11, #-0xc]
   190b8: e3530000     	cmp	r3, #0
   190bc: ba000016     	blt	0x1911c <ReadFilterCoefSets+0x448> @ imm = #0x58
   190c0: e51b3034     	ldr	r3, [r11, #-0x34]
   190c4: e5932010     	ldr	r2, [r3, #0x10]
   190c8: e51b3014     	ldr	r3, [r11, #-0x14]
   190cc: e1a03103     	lsl	r3, r3, #2
   190d0: e0823003     	add	r3, r2, r3
   190d4: e5932000     	ldr	r2, [r3]
   190d8: e51b3008     	ldr	r3, [r11, #-0x8]
   190dc: e1a03103     	lsl	r3, r3, #2
   190e0: e0823003     	add	r3, r2, r3
   190e4: e5933000     	ldr	r3, [r3]
   190e8: e51b0028     	ldr	r0, [r11, #-0x28]
   190ec: e1a01003     	mov	r1, r3
   190f0: ebfffa0c     	bl	0x17928 <RiceDecode>    @ imm = #-0x17d0
   190f4: e1a02000     	mov	r2, r0
   190f8: e51b300c     	ldr	r3, [r11, #-0xc]
   190fc: e2833004     	add	r3, r3, #4
   19100: e2831007     	add	r1, r3, #7
   19104: e3530000     	cmp	r3, #0
   19108: b1a03001     	movlt	r3, r1
   1910c: e1a031c3     	asr	r3, r3, #3
   19110: e0633002     	rsb	r3, r3, r2
   19114: e50b3020     	str	r3, [r11, #-0x20]
   19118: ea000015     	b	0x19174 <ReadFilterCoefSets+0x4a0> @ imm = #0x54
   1911c: e51b3034     	ldr	r3, [r11, #-0x34]
   19120: e5932010     	ldr	r2, [r3, #0x10]
   19124: e51b3014     	ldr	r3, [r11, #-0x14]
   19128: e1a03103     	lsl	r3, r3, #2
   1912c: e0823003     	add	r3, r2, r3
   19130: e5932000     	ldr	r2, [r3]
   19134: e51b3008     	ldr	r3, [r11, #-0x8]
   19138: e1a03103     	lsl	r3, r3, #2
   1913c: e0823003     	add	r3, r2, r3
   19140: e5933000     	ldr	r3, [r3]
   19144: e51b0028     	ldr	r0, [r11, #-0x28]
   19148: e1a01003     	mov	r1, r3
   1914c: ebfff9f5     	bl	0x17928 <RiceDecode>    @ imm = #-0x182c
   19150: e1a02000     	mov	r2, r0
   19154: e51b300c     	ldr	r3, [r11, #-0xc]
   19158: e2633003     	rsb	r3, r3, #3
   1915c: e2831007     	add	r1, r3, #7
   19160: e3530000     	cmp	r3, #0
   19164: b1a03001     	movlt	r3, r1
   19168: e1a031c3     	asr	r3, r3, #3
   1916c: e0823003     	add	r3, r2, r3
   19170: e50b3020     	str	r3, [r11, #-0x20]
   19174: e51b3020     	ldr	r3, [r11, #-0x20]
   19178: e3730c01     	cmn	r3, #256
   1917c: ba000002     	blt	0x1918c <ReadFilterCoefSets+0x4b8> @ imm = #0x8
   19180: e51b3020     	ldr	r3, [r11, #-0x20]
   19184: e35300ff     	cmp	r3, #255
   19188: da000001     	ble	0x19194 <ReadFilterCoefSets+0x4c0> @ imm = #0x4
   1918c: e3a0300a     	mov	r3, #10
   19190: ea000052     	b	0x192e0 <ReadFilterCoefSets+0x60c> @ imm = #0x148
   19194: e51b3030     	ldr	r3, [r11, #-0x30]
   19198: e5932074     	ldr	r2, [r3, #0x74]
   1919c: e51b3014     	ldr	r3, [r11, #-0x14]
   191a0: e1a03103     	lsl	r3, r3, #2
   191a4: e0823003     	add	r3, r2, r3
   191a8: e5932000     	ldr	r2, [r3]
   191ac: e51b3018     	ldr	r3, [r11, #-0x18]
   191b0: e1a03083     	lsl	r3, r3, #1
   191b4: e0823003     	add	r3, r2, r3
   191b8: e51b2020     	ldr	r2, [r11, #-0x20]
   191bc: e6ff2072     	uxth	r2, r2
   191c0: e1c320b0     	strh	r2, [r3]
   191c4: e51b3018     	ldr	r3, [r11, #-0x18]
   191c8: e2833001     	add	r3, r3, #1
   191cc: e50b3018     	str	r3, [r11, #-0x18]
   191d0: e51b3014     	ldr	r3, [r11, #-0x14]
   191d4: e51b1030     	ldr	r1, [r11, #-0x30]
   191d8: e2832004     	add	r2, r3, #4
   191dc: e3a03004     	mov	r3, #4
   191e0: e1a02102     	lsl	r2, r2, #2
   191e4: e0812002     	add	r2, r1, r2
   191e8: e0823003     	add	r3, r2, r3
   191ec: e5932000     	ldr	r2, [r3]
   191f0: e51b3018     	ldr	r3, [r11, #-0x18]
   191f4: e1520003     	cmp	r2, r3
   191f8: caffff80     	bgt	0x19000 <ReadFilterCoefSets+0x32c> @ imm = #-0x200
   191fc: e51b3030     	ldr	r3, [r11, #-0x30]
   19200: e5932074     	ldr	r2, [r3, #0x74]
   19204: e51b3014     	ldr	r3, [r11, #-0x14]
   19208: e1a03103     	lsl	r3, r3, #2
   1920c: e0823003     	add	r3, r2, r3
   19210: e5932000     	ldr	r2, [r3]
   19214: e51b3018     	ldr	r3, [r11, #-0x18]
   19218: e1a03083     	lsl	r3, r3, #1
   1921c: e0822003     	add	r2, r2, r3
   19220: e51b3018     	ldr	r3, [r11, #-0x18]
   19224: e2633080     	rsb	r3, r3, #128
   19228: e1a03083     	lsl	r3, r3, #1
   1922c: e1a00002     	mov	r0, r2
   19230: e3a01000     	mov	r1, #0
   19234: e1a02003     	mov	r2, r3
   19238: ebffcc59     	bl	0xc3a4 <memset@plt>     @ imm = #-0xce9c
   1923c: e51b3014     	ldr	r3, [r11, #-0x14]
   19240: e2833001     	add	r3, r3, #1
   19244: e50b3014     	str	r3, [r11, #-0x14]
   19248: e51b3030     	ldr	r3, [r11, #-0x30]
   1924c: e5932008     	ldr	r2, [r3, #0x8]
   19250: e51b3014     	ldr	r3, [r11, #-0x14]
   19254: e1520003     	cmp	r2, r3
   19258: cafffea7     	bgt	0x18cfc <ReadFilterCoefSets+0x28> @ imm = #-0x564
   1925c: e3a03000     	mov	r3, #0
   19260: e50b301c     	str	r3, [r11, #-0x1c]
   19264: ea000018     	b	0x192cc <ReadFilterCoefSets+0x5f8> @ imm = #0x60
   19268: e51b301c     	ldr	r3, [r11, #-0x1c]
   1926c: e51b101c     	ldr	r1, [r11, #-0x1c]
   19270: e51b0030     	ldr	r0, [r11, #-0x30]
   19274: e3a02e19     	mov	r2, #400
   19278: e1a01281     	lsl	r1, r1, #5
   1927c: e0801001     	add	r1, r0, r1
   19280: e0812002     	add	r2, r1, r2
   19284: e5922000     	ldr	r2, [r2]
   19288: e51b0030     	ldr	r0, [r11, #-0x30]
   1928c: e2821004     	add	r1, r2, #4
   19290: e3a02004     	mov	r2, #4
   19294: e1a01101     	lsl	r1, r1, #2
   19298: e0801001     	add	r1, r0, r1
   1929c: e0812002     	add	r2, r1, r2
   192a0: e5922000     	ldr	r2, [r2]
   192a4: e51b0030     	ldr	r0, [r11, #-0x30]
   192a8: e2831026     	add	r1, r3, #38
   192ac: e3a03004     	mov	r3, #4
   192b0: e1a01101     	lsl	r1, r1, #2
   192b4: e0801001     	add	r1, r0, r1
   192b8: e0813003     	add	r3, r1, r3
   192bc: e5832000     	str	r2, [r3]
   192c0: e51b301c     	ldr	r3, [r11, #-0x1c]
   192c4: e2833001     	add	r3, r3, #1
   192c8: e50b301c     	str	r3, [r11, #-0x1c]
   192cc: e51b201c     	ldr	r2, [r11, #-0x1c]
   192d0: e51b302c     	ldr	r3, [r11, #-0x2c]
   192d4: e1520003     	cmp	r2, r3
   192d8: baffffe2     	blt	0x19268 <ReadFilterCoefSets+0x594> @ imm = #-0x78
   192dc: e3a03000     	mov	r3, #0
   192e0: e1a00003     	mov	r0, r3
   192e4: e24bd004     	sub	sp, r11, #4
   192e8: e8bd8800     	pop	{r11, pc}

