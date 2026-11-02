00016cb8 <DST_FramDSTDecode>:
   16cb8: e92d4800     	push	{r11, lr}
   16cbc: e28db004     	add	r11, sp, #4
   16cc0: e24dd906     	sub	sp, sp, #98304
   16cc4: e24dd0c0     	sub	sp, sp, #192
   16cc8: e59fcb64     	ldr	r12, [pc, #0xb64]       @ 0x17834 <DST_FramDSTDecode+0xb7c>
   16ccc: e24be004     	sub	lr, r11, #4
   16cd0: e78e000c     	str	r0, [lr, r12]
   16cd4: e59f0b5c     	ldr	r0, [pc, #0xb5c]        @ 0x17838 <DST_FramDSTDecode+0xb80>
   16cd8: e24bc004     	sub	r12, r11, #4
   16cdc: e78c1000     	str	r1, [r12, r0]
   16ce0: e59f1b54     	ldr	r1, [pc, #0xb54]        @ 0x1783c <DST_FramDSTDecode+0xb84>
   16ce4: e24be004     	sub	lr, r11, #4
   16ce8: e78e2001     	str	r2, [lr, r1]
   16cec: e59f2b4c     	ldr	r2, [pc, #0xb4c]        @ 0x17840 <DST_FramDSTDecode+0xb88>
   16cf0: e24b0004     	sub	r0, r11, #4
   16cf4: e7803002     	str	r3, [r0, r2]
   16cf8: e59b2004     	ldr	r2, [r11, #0x4]
   16cfc: e59f3b40     	ldr	r3, [pc, #0xb40]        @ 0x17844 <DST_FramDSTDecode+0xb8c>
   16d00: e7923003     	ldr	r3, [r2, r3]
   16d04: e50b3028     	str	r3, [r11, #-0x28]
   16d08: e59b3004     	ldr	r3, [r11, #0x4]
   16d0c: e5933004     	ldr	r3, [r3, #0x4]
   16d10: e50b3024     	str	r3, [r11, #-0x24]
   16d14: e59f3b1c     	ldr	r3, [pc, #0xb1c]        @ 0x17838 <DST_FramDSTDecode+0xb80>
   16d18: e24b1004     	sub	r1, r11, #4
   16d1c: e7913003     	ldr	r3, [r1, r3]
   16d20: e50b3020     	str	r3, [r11, #-0x20]
   16d24: e59b3004     	ldr	r3, [r11, #0x4]
   16d28: e59f2b10     	ldr	r2, [pc, #0xb10]        @ 0x17840 <DST_FramDSTDecode+0xb88>
   16d2c: e24bc004     	sub	r12, r11, #4
   16d30: e79c2002     	ldr	r2, [r12, r2]
   16d34: e5832000     	str	r2, [r3]
   16d38: e59b3004     	ldr	r3, [r11, #0x4]
   16d3c: e59f2af8     	ldr	r2, [pc, #0xaf8]        @ 0x1783c <DST_FramDSTDecode+0xb84>
   16d40: e24be004     	sub	lr, r11, #4
   16d44: e79e2002     	ldr	r2, [lr, r2]
   16d48: e583207c     	str	r2, [r3, #0x7c]
   16d4c: e59b3004     	ldr	r3, [r11, #0x4]
   16d50: e593307c     	ldr	r3, [r3, #0x7c]
   16d54: e1a02183     	lsl	r2, r3, #3
   16d58: e59b3004     	ldr	r3, [r11, #0x4]
   16d5c: e5832080     	str	r2, [r3, #0x80]
   16d60: e59f2acc     	ldr	r2, [pc, #0xacc]        @ 0x17834 <DST_FramDSTDecode+0xb7c>
   16d64: e59f3acc     	ldr	r3, [pc, #0xacc]        @ 0x17838 <DST_FramDSTDecode+0xb80>
   16d68: e59b0004     	ldr	r0, [r11, #0x4]
   16d6c: e24bc004     	sub	r12, r11, #4
   16d70: e79c1002     	ldr	r1, [r12, r2]
   16d74: e24be004     	sub	lr, r11, #4
   16d78: e79e2003     	ldr	r2, [lr, r3]
   16d7c: eb000b57     	bl	0x19ae0 <UnpackDSTframe> @ imm = #0x2d5c
   16d80: e1a03000     	mov	r3, r0
   16d84: e50b3034     	str	r3, [r11, #-0x34]
   16d88: e51b3034     	ldr	r3, [r11, #-0x34]
   16d8c: e3530000     	cmp	r3, #0
   16d90: 1a000293     	bne	0x177e4 <DST_FramDSTDecode+0xb2c> @ imm = #0xa4c
   16d94: e59b3004     	ldr	r3, [r11, #0x4]
   16d98: e5933078     	ldr	r3, [r3, #0x78]
   16d9c: e3530001     	cmp	r3, #1
   16da0: 1a00028f     	bne	0x177e4 <DST_FramDSTDecode+0xb2c> @ imm = #0xa3c
   16da4: e59b3004     	ldr	r3, [r11, #0x4]
   16da8: e28320b4     	add	r2, r3, #180
   16dac: e59b3004     	ldr	r3, [r11, #0x4]
   16db0: e2833e25     	add	r3, r3, #592
   16db4: e51b0024     	ldr	r0, [r11, #-0x24]
   16db8: e51b1028     	ldr	r1, [r11, #-0x28]
   16dbc: ebfffe94     	bl	0x16814 <FillTable4Bit> @ imm = #-0x5b0
   16dc0: e59b3004     	ldr	r3, [r11, #0x4]
   16dc4: e2832bdd     	add	r2, r3, #226304
   16dc8: e2822050     	add	r2, r2, #80
   16dcc: e59b3004     	ldr	r3, [r11, #0x4]
   16dd0: e2833bdd     	add	r3, r3, #226304
   16dd4: e2833f7b     	add	r3, r3, #492
   16dd8: e51b0024     	ldr	r0, [r11, #-0x24]
   16ddc: e51b1028     	ldr	r1, [r11, #-0x28]
   16de0: ebfffe8b     	bl	0x16814 <FillTable4Bit> @ imm = #-0x5d4
   16de4: e24b3906     	sub	r3, r11, #98304
   16de8: e2433004     	sub	r3, r3, #4
   16dec: e24330a8     	sub	r3, r3, #168
   16df0: e59b0004     	ldr	r0, [r11, #0x4]
   16df4: e1a01003     	mov	r1, r3
   16df8: ebffff1b     	bl	0x16a6c <LT_InitCoefTablesI> @ imm = #-0x394
   16dfc: e24b30ac     	sub	r3, r11, #172
   16e00: e59b0004     	ldr	r0, [r11, #0x4]
   16e04: e1a01003     	mov	r1, r3
   16e08: ebffff87     	bl	0x16c2c <LT_InitStatus> @ imm = #-0x1e4
   16e0c: e59b2004     	ldr	r2, [r11, #0x4]
   16e10: e59f3a30     	ldr	r3, [pc, #0xa30]        @ 0x17848 <DST_FramDSTDecode+0xb90>
   16e14: e7922003     	ldr	r2, [r2, r3]
   16e18: e59b1004     	ldr	r1, [r11, #0x4]
   16e1c: e59f3a28     	ldr	r3, [pc, #0xa28]        @ 0x1784c <DST_FramDSTDecode+0xb94>
   16e20: e7913003     	ldr	r3, [r1, r3]
   16e24: e24b1048     	sub	r1, r11, #72
   16e28: e1a00001     	mov	r0, r1
   16e2c: e1a01002     	mov	r1, r2
   16e30: e1a02003     	mov	r2, r3
   16e34: ebfffda1     	bl	0x164c0 <LT_ACDecodeBit_Init> @ imm = #-0x97c
   16e38: e59b3004     	ldr	r3, [r11, #0x4]
   16e3c: e5933074     	ldr	r3, [r3, #0x74]
   16e40: e5933000     	ldr	r3, [r3]
   16e44: e1d330b0     	ldrh	r3, [r3]
   16e48: e6bf3073     	sxth	r3, r3
   16e4c: e1a00003     	mov	r0, r3
   16e50: ebfffef3     	bl	0x16a24 <Reverse7LSBs>  @ imm = #-0x434
   16e54: e1a03000     	mov	r3, r0
   16e58: e6ff3073     	uxth	r3, r3
   16e5c: e6bf2073     	sxth	r2, r3
   16e60: e59b1004     	ldr	r1, [r11, #0x4]
   16e64: e59f39dc     	ldr	r3, [pc, #0x9dc]        @ 0x17848 <DST_FramDSTDecode+0xb90>
   16e68: e7913003     	ldr	r3, [r1, r3]
   16e6c: e59b0004     	ldr	r0, [r11, #0x4]
   16e70: e59f19d4     	ldr	r1, [pc, #0x9d4]        @ 0x1784c <DST_FramDSTDecode+0xb94>
   16e74: e790c001     	ldr	r12, [r0, r1]
   16e78: e24b0048     	sub	r0, r11, #72
   16e7c: e24b1035     	sub	r1, r11, #53
   16e80: e58dc000     	str	r12, [sp]
   16e84: ebfffdc1     	bl	0x16590 <LT_ACDecodeBit_Decode> @ imm = #-0x8fc
   16e88: e51b3028     	ldr	r3, [r11, #-0x28]
   16e8c: e51b2024     	ldr	r2, [r11, #-0x24]
   16e90: e0030392     	mul	r3, r2, r3
   16e94: e2832007     	add	r2, r3, #7
   16e98: e3530000     	cmp	r3, #0
   16e9c: b1a03002     	movlt	r3, r2
   16ea0: e1a031c3     	asr	r3, r3, #3
   16ea4: e51b0020     	ldr	r0, [r11, #-0x20]
   16ea8: e3a01000     	mov	r1, #0
   16eac: e1a02003     	mov	r2, r3
   16eb0: ebffd53b     	bl	0xc3a4 <memset@plt>     @ imm = #-0xab14
   16eb4: e3a03000     	mov	r3, #0
   16eb8: e50b3030     	str	r3, [r11, #-0x30]
   16ebc: ea000232     	b	0x1778c <DST_FramDSTDecode+0xad4> @ imm = #0x8c8
   16ec0: e51b3030     	ldr	r3, [r11, #-0x30]
   16ec4: e2832007     	add	r2, r3, #7
   16ec8: e3530000     	cmp	r3, #0
   16ecc: b1a03002     	movlt	r3, r2
   16ed0: e1a031c3     	asr	r3, r3, #3
   16ed4: e50b301c     	str	r3, [r11, #-0x1c]
   16ed8: e3a03000     	mov	r3, #0
   16edc: e50b302c     	str	r3, [r11, #-0x2c]
   16ee0: ea000222     	b	0x17770 <DST_FramDSTDecode+0xab8> @ imm = #0x888
   16ee4: e51b102c     	ldr	r1, [r11, #-0x2c]
   16ee8: e51b2030     	ldr	r2, [r11, #-0x30]
   16eec: e59b0004     	ldr	r0, [r11, #0x4]
   16ef0: e3a03e25     	mov	r3, #592
   16ef4: e3a0cc93     	mov	r12, #37632
   16ef8: e001019c     	mul	r1, r12, r1
   16efc: e0801001     	add	r1, r0, r1
   16f00: e0812002     	add	r2, r1, r2
   16f04: e0823003     	add	r3, r2, r3
   16f08: e5d33000     	ldrb	r3, [r3]
   16f0c: e50b3014     	str	r3, [r11, #-0x14]
   16f10: e51b1014     	ldr	r1, [r11, #-0x14]
   16f14: e51b202c     	ldr	r2, [r11, #-0x2c]
   16f18: e3e030a7     	mvn	r3, #167
   16f1c: e1a02202     	lsl	r2, r2, #4
   16f20: e24b0004     	sub	r0, r11, #4
   16f24: e0802002     	add	r2, r0, r2
   16f28: e0823003     	add	r3, r2, r3
   16f2c: e5d33000     	ldrb	r3, [r3]
   16f30: e1a02003     	mov	r2, r3
   16f34: e59f3914     	ldr	r3, [pc, #0x914]        @ 0x17850 <DST_FramDSTDecode+0xb98>
   16f38: e1a01601     	lsl	r1, r1, #12
   16f3c: e0812002     	add	r2, r1, r2
   16f40: e1a02082     	lsl	r2, r2, #1
   16f44: e24b1004     	sub	r1, r11, #4
   16f48: e0812002     	add	r2, r1, r2
   16f4c: e0823003     	add	r3, r2, r3
   16f50: e1d330b0     	ldrh	r3, [r3]
   16f54: e14b31b8     	strh	r3, [r11, #-24]
   16f58: e51b1014     	ldr	r1, [r11, #-0x14]
   16f5c: e51b202c     	ldr	r2, [r11, #-0x2c]
   16f60: e3e030a6     	mvn	r3, #166
   16f64: e1a02202     	lsl	r2, r2, #4
   16f68: e24bc004     	sub	r12, r11, #4
   16f6c: e08c2002     	add	r2, r12, r2
   16f70: e0823003     	add	r3, r2, r3
   16f74: e5d33000     	ldrb	r3, [r3]
   16f78: e1a02003     	mov	r2, r3
   16f7c: e59f38cc     	ldr	r3, [pc, #0x8cc]        @ 0x17850 <DST_FramDSTDecode+0xb98>
   16f80: e1a01601     	lsl	r1, r1, #12
   16f84: e0812002     	add	r2, r1, r2
   16f88: e2822c01     	add	r2, r2, #256
   16f8c: e1a02082     	lsl	r2, r2, #1
   16f90: e24be004     	sub	lr, r11, #4
   16f94: e08e2002     	add	r2, lr, r2
   16f98: e0823003     	add	r3, r2, r3
   16f9c: e1d330b0     	ldrh	r3, [r3]
   16fa0: e6ff2073     	uxth	r2, r3
   16fa4: e15b31b8     	ldrh	r3, [r11, #-24]
   16fa8: e0823003     	add	r3, r2, r3
   16fac: e6ff3073     	uxth	r3, r3
   16fb0: e14b31b8     	strh	r3, [r11, #-24]
   16fb4: e51b1014     	ldr	r1, [r11, #-0x14]
   16fb8: e51b302c     	ldr	r3, [r11, #-0x2c]
   16fbc: e1a03183     	lsl	r3, r3, #3
   16fc0: e2832001     	add	r2, r3, #1
   16fc4: e3e030a7     	mvn	r3, #167
   16fc8: e1a02082     	lsl	r2, r2, #1
   16fcc: e24b0004     	sub	r0, r11, #4
   16fd0: e0802002     	add	r2, r0, r2
   16fd4: e0823003     	add	r3, r2, r3
   16fd8: e5d33000     	ldrb	r3, [r3]
   16fdc: e1a02003     	mov	r2, r3
   16fe0: e59f3868     	ldr	r3, [pc, #0x868]        @ 0x17850 <DST_FramDSTDecode+0xb98>
   16fe4: e1a01601     	lsl	r1, r1, #12
   16fe8: e0812002     	add	r2, r1, r2
   16fec: e2822c02     	add	r2, r2, #512
   16ff0: e1a02082     	lsl	r2, r2, #1
   16ff4: e24b1004     	sub	r1, r11, #4
   16ff8: e0812002     	add	r2, r1, r2
   16ffc: e0823003     	add	r3, r2, r3
   17000: e1d330b0     	ldrh	r3, [r3]
   17004: e6ff2073     	uxth	r2, r3
   17008: e15b31b8     	ldrh	r3, [r11, #-24]
   1700c: e0823003     	add	r3, r2, r3
   17010: e6ff3073     	uxth	r3, r3
   17014: e14b31b8     	strh	r3, [r11, #-24]
   17018: e51b1014     	ldr	r1, [r11, #-0x14]
   1701c: e51b202c     	ldr	r2, [r11, #-0x2c]
   17020: e3e030a4     	mvn	r3, #164
   17024: e1a02202     	lsl	r2, r2, #4
   17028: e24bc004     	sub	r12, r11, #4
   1702c: e08c2002     	add	r2, r12, r2
   17030: e0823003     	add	r3, r2, r3
   17034: e5d33000     	ldrb	r3, [r3]
   17038: e1a02003     	mov	r2, r3
   1703c: e59f380c     	ldr	r3, [pc, #0x80c]        @ 0x17850 <DST_FramDSTDecode+0xb98>
   17040: e1a01601     	lsl	r1, r1, #12
   17044: e0812002     	add	r2, r1, r2
   17048: e2822c03     	add	r2, r2, #768
   1704c: e1a02082     	lsl	r2, r2, #1
   17050: e24be004     	sub	lr, r11, #4
   17054: e08e2002     	add	r2, lr, r2
   17058: e0823003     	add	r3, r2, r3
   1705c: e1d330b0     	ldrh	r3, [r3]
   17060: e6ff2073     	uxth	r2, r3
   17064: e15b31b8     	ldrh	r3, [r11, #-24]
   17068: e0823003     	add	r3, r2, r3
   1706c: e6ff3073     	uxth	r3, r3
   17070: e14b31b8     	strh	r3, [r11, #-24]
   17074: e51b1014     	ldr	r1, [r11, #-0x14]
   17078: e51b302c     	ldr	r3, [r11, #-0x2c]
   1707c: e1a03103     	lsl	r3, r3, #2
   17080: e2832001     	add	r2, r3, #1
   17084: e3e030a7     	mvn	r3, #167
   17088: e1a02102     	lsl	r2, r2, #2
   1708c: e24b0004     	sub	r0, r11, #4
   17090: e0802002     	add	r2, r0, r2
   17094: e0823003     	add	r3, r2, r3
   17098: e5d33000     	ldrb	r3, [r3]
   1709c: e1a02003     	mov	r2, r3
   170a0: e59f37a8     	ldr	r3, [pc, #0x7a8]        @ 0x17850 <DST_FramDSTDecode+0xb98>
   170a4: e1a01601     	lsl	r1, r1, #12
   170a8: e0812002     	add	r2, r1, r2
   170ac: e2822b01     	add	r2, r2, #1024
   170b0: e1a02082     	lsl	r2, r2, #1
   170b4: e24b1004     	sub	r1, r11, #4
   170b8: e0812002     	add	r2, r1, r2
   170bc: e0823003     	add	r3, r2, r3
   170c0: e1d330b0     	ldrh	r3, [r3]
   170c4: e6ff2073     	uxth	r2, r3
   170c8: e15b31b8     	ldrh	r3, [r11, #-24]
   170cc: e0823003     	add	r3, r2, r3
   170d0: e6ff3073     	uxth	r3, r3
   170d4: e14b31b8     	strh	r3, [r11, #-24]
   170d8: e51b1014     	ldr	r1, [r11, #-0x14]
   170dc: e51b202c     	ldr	r2, [r11, #-0x2c]
   170e0: e3e030a2     	mvn	r3, #162
   170e4: e1a02202     	lsl	r2, r2, #4
   170e8: e24bc004     	sub	r12, r11, #4
   170ec: e08c2002     	add	r2, r12, r2
   170f0: e0823003     	add	r3, r2, r3
   170f4: e5d33000     	ldrb	r3, [r3]
   170f8: e1a02003     	mov	r2, r3
   170fc: e59f374c     	ldr	r3, [pc, #0x74c]        @ 0x17850 <DST_FramDSTDecode+0xb98>
   17100: e1a01601     	lsl	r1, r1, #12
   17104: e0812002     	add	r2, r1, r2
   17108: e2822c05     	add	r2, r2, #1280
   1710c: e1a02082     	lsl	r2, r2, #1
   17110: e24be004     	sub	lr, r11, #4
   17114: e08e2002     	add	r2, lr, r2
   17118: e0823003     	add	r3, r2, r3
   1711c: e1d330b0     	ldrh	r3, [r3]
   17120: e6ff2073     	uxth	r2, r3
   17124: e15b31b8     	ldrh	r3, [r11, #-24]
   17128: e0823003     	add	r3, r2, r3
   1712c: e6ff3073     	uxth	r3, r3
   17130: e14b31b8     	strh	r3, [r11, #-24]
   17134: e51b1014     	ldr	r1, [r11, #-0x14]
   17138: e51b202c     	ldr	r2, [r11, #-0x2c]
   1713c: e3e030a1     	mvn	r3, #161
   17140: e1a02202     	lsl	r2, r2, #4
   17144: e24b0004     	sub	r0, r11, #4
   17148: e0802002     	add	r2, r0, r2
   1714c: e0823003     	add	r3, r2, r3
   17150: e5d33000     	ldrb	r3, [r3]
   17154: e1a02003     	mov	r2, r3
   17158: e59f36f0     	ldr	r3, [pc, #0x6f0]        @ 0x17850 <DST_FramDSTDecode+0xb98>
   1715c: e1a01601     	lsl	r1, r1, #12
   17160: e0812002     	add	r2, r1, r2
   17164: e2822c06     	add	r2, r2, #1536
   17168: e1a02082     	lsl	r2, r2, #1
   1716c: e24b1004     	sub	r1, r11, #4
   17170: e0812002     	add	r2, r1, r2
   17174: e0823003     	add	r3, r2, r3
   17178: e1d330b0     	ldrh	r3, [r3]
   1717c: e6ff2073     	uxth	r2, r3
   17180: e15b31b8     	ldrh	r3, [r11, #-24]
   17184: e0823003     	add	r3, r2, r3
   17188: e6ff3073     	uxth	r3, r3
   1718c: e14b31b8     	strh	r3, [r11, #-24]
   17190: e51b1014     	ldr	r1, [r11, #-0x14]
   17194: e51b202c     	ldr	r2, [r11, #-0x2c]
   17198: e3e030a0     	mvn	r3, #160
   1719c: e1a02202     	lsl	r2, r2, #4
   171a0: e24bc004     	sub	r12, r11, #4
   171a4: e08c2002     	add	r2, r12, r2
   171a8: e0823003     	add	r3, r2, r3
   171ac: e5d33000     	ldrb	r3, [r3]
   171b0: e1a02003     	mov	r2, r3
   171b4: e59f3694     	ldr	r3, [pc, #0x694]        @ 0x17850 <DST_FramDSTDecode+0xb98>
   171b8: e1a01601     	lsl	r1, r1, #12
   171bc: e0812002     	add	r2, r1, r2
   171c0: e2822c07     	add	r2, r2, #1792
   171c4: e1a02082     	lsl	r2, r2, #1
   171c8: e24be004     	sub	lr, r11, #4
   171cc: e08e2002     	add	r2, lr, r2
   171d0: e0823003     	add	r3, r2, r3
   171d4: e1d330b0     	ldrh	r3, [r3]
   171d8: e6ff2073     	uxth	r2, r3
   171dc: e15b31b8     	ldrh	r3, [r11, #-24]
   171e0: e0823003     	add	r3, r2, r3
   171e4: e6ff3073     	uxth	r3, r3
   171e8: e14b31b8     	strh	r3, [r11, #-24]
   171ec: e51b1014     	ldr	r1, [r11, #-0x14]
   171f0: e51b302c     	ldr	r3, [r11, #-0x2c]
   171f4: e1a03083     	lsl	r3, r3, #1
   171f8: e2832001     	add	r2, r3, #1
   171fc: e3e030a7     	mvn	r3, #167
   17200: e1a02182     	lsl	r2, r2, #3
   17204: e24b0004     	sub	r0, r11, #4
   17208: e0802002     	add	r2, r0, r2
   1720c: e0823003     	add	r3, r2, r3
   17210: e5d33000     	ldrb	r3, [r3]
   17214: e1a02003     	mov	r2, r3
   17218: e59f3630     	ldr	r3, [pc, #0x630]        @ 0x17850 <DST_FramDSTDecode+0xb98>
   1721c: e1a01601     	lsl	r1, r1, #12
   17220: e0812002     	add	r2, r1, r2
   17224: e2822b02     	add	r2, r2, #2048
   17228: e1a02082     	lsl	r2, r2, #1
   1722c: e24b1004     	sub	r1, r11, #4
   17230: e0812002     	add	r2, r1, r2
   17234: e0823003     	add	r3, r2, r3
   17238: e1d330b0     	ldrh	r3, [r3]
   1723c: e6ff2073     	uxth	r2, r3
   17240: e15b31b8     	ldrh	r3, [r11, #-24]
   17244: e0823003     	add	r3, r2, r3
   17248: e6ff3073     	uxth	r3, r3
   1724c: e14b31b8     	strh	r3, [r11, #-24]
   17250: e51b1014     	ldr	r1, [r11, #-0x14]
   17254: e51b202c     	ldr	r2, [r11, #-0x2c]
   17258: e3e0309e     	mvn	r3, #158
   1725c: e1a02202     	lsl	r2, r2, #4
   17260: e24bc004     	sub	r12, r11, #4
   17264: e08c2002     	add	r2, r12, r2
   17268: e0823003     	add	r3, r2, r3
   1726c: e5d33000     	ldrb	r3, [r3]
   17270: e1a02003     	mov	r2, r3
   17274: e59f35d4     	ldr	r3, [pc, #0x5d4]        @ 0x17850 <DST_FramDSTDecode+0xb98>
   17278: e1a01601     	lsl	r1, r1, #12
   1727c: e0812002     	add	r2, r1, r2
   17280: e2822c09     	add	r2, r2, #2304
   17284: e1a02082     	lsl	r2, r2, #1
   17288: e24be004     	sub	lr, r11, #4
   1728c: e08e2002     	add	r2, lr, r2
   17290: e0823003     	add	r3, r2, r3
   17294: e1d330b0     	ldrh	r3, [r3]
   17298: e6ff2073     	uxth	r2, r3
   1729c: e15b31b8     	ldrh	r3, [r11, #-24]
   172a0: e0823003     	add	r3, r2, r3
   172a4: e6ff3073     	uxth	r3, r3
   172a8: e14b31b8     	strh	r3, [r11, #-24]
   172ac: e51b1014     	ldr	r1, [r11, #-0x14]
   172b0: e51b202c     	ldr	r2, [r11, #-0x2c]
   172b4: e3e0309d     	mvn	r3, #157
   172b8: e1a02202     	lsl	r2, r2, #4
   172bc: e24b0004     	sub	r0, r11, #4
   172c0: e0802002     	add	r2, r0, r2
   172c4: e0823003     	add	r3, r2, r3
   172c8: e5d33000     	ldrb	r3, [r3]
   172cc: e1a02003     	mov	r2, r3
   172d0: e59f3578     	ldr	r3, [pc, #0x578]        @ 0x17850 <DST_FramDSTDecode+0xb98>
   172d4: e1a01601     	lsl	r1, r1, #12
   172d8: e0812002     	add	r2, r1, r2
   172dc: e2822c0a     	add	r2, r2, #2560
   172e0: e1a02082     	lsl	r2, r2, #1
   172e4: e24b1004     	sub	r1, r11, #4
   172e8: e0812002     	add	r2, r1, r2
   172ec: e0823003     	add	r3, r2, r3
   172f0: e1d330b0     	ldrh	r3, [r3]
   172f4: e6ff2073     	uxth	r2, r3
   172f8: e15b31b8     	ldrh	r3, [r11, #-24]
   172fc: e0823003     	add	r3, r2, r3
   17300: e6ff3073     	uxth	r3, r3
   17304: e14b31b8     	strh	r3, [r11, #-24]
   17308: e51b1014     	ldr	r1, [r11, #-0x14]
   1730c: e51b202c     	ldr	r2, [r11, #-0x2c]
   17310: e3e0309c     	mvn	r3, #156
   17314: e1a02202     	lsl	r2, r2, #4
   17318: e24bc004     	sub	r12, r11, #4
   1731c: e08c2002     	add	r2, r12, r2
   17320: e0823003     	add	r3, r2, r3
   17324: e5d33000     	ldrb	r3, [r3]
   17328: e1a02003     	mov	r2, r3
   1732c: e59f351c     	ldr	r3, [pc, #0x51c]        @ 0x17850 <DST_FramDSTDecode+0xb98>
   17330: e1a01601     	lsl	r1, r1, #12
   17334: e0812002     	add	r2, r1, r2
   17338: e2822c0b     	add	r2, r2, #2816
   1733c: e1a02082     	lsl	r2, r2, #1
   17340: e24be004     	sub	lr, r11, #4
   17344: e08e2002     	add	r2, lr, r2
   17348: e0823003     	add	r3, r2, r3
   1734c: e1d330b0     	ldrh	r3, [r3]
   17350: e6ff2073     	uxth	r2, r3
   17354: e15b31b8     	ldrh	r3, [r11, #-24]
   17358: e0823003     	add	r3, r2, r3
   1735c: e6ff3073     	uxth	r3, r3
   17360: e14b31b8     	strh	r3, [r11, #-24]
   17364: e51b1014     	ldr	r1, [r11, #-0x14]
   17368: e51b202c     	ldr	r2, [r11, #-0x2c]
   1736c: e3e0309b     	mvn	r3, #155
   17370: e1a02202     	lsl	r2, r2, #4
   17374: e24b0004     	sub	r0, r11, #4
   17378: e0802002     	add	r2, r0, r2
   1737c: e0823003     	add	r3, r2, r3
   17380: e5d33000     	ldrb	r3, [r3]
   17384: e1a02003     	mov	r2, r3
   17388: e59f34c0     	ldr	r3, [pc, #0x4c0]        @ 0x17850 <DST_FramDSTDecode+0xb98>
   1738c: e1a01601     	lsl	r1, r1, #12
   17390: e0812002     	add	r2, r1, r2
   17394: e2822b03     	add	r2, r2, #3072
   17398: e1a02082     	lsl	r2, r2, #1
   1739c: e24b1004     	sub	r1, r11, #4
   173a0: e0812002     	add	r2, r1, r2
   173a4: e0823003     	add	r3, r2, r3
   173a8: e1d330b0     	ldrh	r3, [r3]
   173ac: e6ff2073     	uxth	r2, r3
   173b0: e15b31b8     	ldrh	r3, [r11, #-24]
   173b4: e0823003     	add	r3, r2, r3
   173b8: e6ff3073     	uxth	r3, r3
   173bc: e14b31b8     	strh	r3, [r11, #-24]
   173c0: e51b1014     	ldr	r1, [r11, #-0x14]
   173c4: e51b202c     	ldr	r2, [r11, #-0x2c]
   173c8: e3e0309a     	mvn	r3, #154
   173cc: e1a02202     	lsl	r2, r2, #4
   173d0: e24bc004     	sub	r12, r11, #4
   173d4: e08c2002     	add	r2, r12, r2
   173d8: e0823003     	add	r3, r2, r3
   173dc: e5d33000     	ldrb	r3, [r3]
   173e0: e1a02003     	mov	r2, r3
   173e4: e59f3464     	ldr	r3, [pc, #0x464]        @ 0x17850 <DST_FramDSTDecode+0xb98>
   173e8: e1a01601     	lsl	r1, r1, #12
   173ec: e0812002     	add	r2, r1, r2
   173f0: e2822c0d     	add	r2, r2, #3328
   173f4: e1a02082     	lsl	r2, r2, #1
   173f8: e24be004     	sub	lr, r11, #4
   173fc: e08e2002     	add	r2, lr, r2
   17400: e0823003     	add	r3, r2, r3
   17404: e1d330b0     	ldrh	r3, [r3]
   17408: e6ff2073     	uxth	r2, r3
   1740c: e15b31b8     	ldrh	r3, [r11, #-24]
   17410: e0823003     	add	r3, r2, r3
   17414: e6ff3073     	uxth	r3, r3
   17418: e14b31b8     	strh	r3, [r11, #-24]
   1741c: e51b1014     	ldr	r1, [r11, #-0x14]
   17420: e51b202c     	ldr	r2, [r11, #-0x2c]
   17424: e3e03099     	mvn	r3, #153
   17428: e1a02202     	lsl	r2, r2, #4
   1742c: e24b0004     	sub	r0, r11, #4
   17430: e0802002     	add	r2, r0, r2
   17434: e0823003     	add	r3, r2, r3
   17438: e5d33000     	ldrb	r3, [r3]
   1743c: e1a02003     	mov	r2, r3
   17440: e59f3408     	ldr	r3, [pc, #0x408]        @ 0x17850 <DST_FramDSTDecode+0xb98>
   17444: e1a01601     	lsl	r1, r1, #12
   17448: e0812002     	add	r2, r1, r2
   1744c: e2822c0e     	add	r2, r2, #3584
   17450: e1a02082     	lsl	r2, r2, #1
   17454: e24b1004     	sub	r1, r11, #4
   17458: e0812002     	add	r2, r1, r2
   1745c: e0823003     	add	r3, r2, r3
   17460: e1d330b0     	ldrh	r3, [r3]
   17464: e6ff2073     	uxth	r2, r3
   17468: e15b31b8     	ldrh	r3, [r11, #-24]
   1746c: e0823003     	add	r3, r2, r3
   17470: e6ff3073     	uxth	r3, r3
   17474: e14b31b8     	strh	r3, [r11, #-24]
   17478: e51b1014     	ldr	r1, [r11, #-0x14]
   1747c: e51b202c     	ldr	r2, [r11, #-0x2c]
   17480: e3e03098     	mvn	r3, #152
   17484: e1a02202     	lsl	r2, r2, #4
   17488: e24bc004     	sub	r12, r11, #4
   1748c: e08c2002     	add	r2, r12, r2
   17490: e0823003     	add	r3, r2, r3
   17494: e5d33000     	ldrb	r3, [r3]
   17498: e1a02003     	mov	r2, r3
   1749c: e59f33ac     	ldr	r3, [pc, #0x3ac]        @ 0x17850 <DST_FramDSTDecode+0xb98>
   174a0: e1a01601     	lsl	r1, r1, #12
   174a4: e0812002     	add	r2, r1, r2
   174a8: e2822c0f     	add	r2, r2, #3840
   174ac: e1a02082     	lsl	r2, r2, #1
   174b0: e24be004     	sub	lr, r11, #4
   174b4: e08e2002     	add	r2, lr, r2
   174b8: e0823003     	add	r3, r2, r3
   174bc: e1d330b0     	ldrh	r3, [r3]
   174c0: e6ff2073     	uxth	r2, r3
   174c4: e15b31b8     	ldrh	r3, [r11, #-24]
   174c8: e0823003     	add	r3, r2, r3
   174cc: e6ff3073     	uxth	r3, r3
   174d0: e14b31b8     	strh	r3, [r11, #-24]
   174d4: e51b302c     	ldr	r3, [r11, #-0x2c]
   174d8: e59b1004     	ldr	r1, [r11, #0x4]
   174dc: e2832020     	add	r2, r3, #32
   174e0: e3a03004     	mov	r3, #4
   174e4: e1a02102     	lsl	r2, r2, #2
   174e8: e0812002     	add	r2, r1, r2
   174ec: e0823003     	add	r3, r2, r3
   174f0: e5933000     	ldr	r3, [r3]
   174f4: e3530000     	cmp	r3, #0
   174f8: 0a000018     	beq	0x17560 <DST_FramDSTDecode+0x8a8> @ imm = #0x60
   174fc: e51b302c     	ldr	r3, [r11, #-0x2c]
   17500: e59b1004     	ldr	r1, [r11, #0x4]
   17504: e2832026     	add	r2, r3, #38
   17508: e3a03004     	mov	r3, #4
   1750c: e1a02102     	lsl	r2, r2, #2
   17510: e0812002     	add	r2, r1, r2
   17514: e0823003     	add	r3, r2, r3
   17518: e5932000     	ldr	r2, [r3]
   1751c: e51b3030     	ldr	r3, [r11, #-0x30]
   17520: e1520003     	cmp	r2, r3
   17524: da00000d     	ble	0x17560 <DST_FramDSTDecode+0x8a8> @ imm = #0x34
   17528: e59b2004     	ldr	r2, [r11, #0x4]
   1752c: e59f3314     	ldr	r3, [pc, #0x314]        @ 0x17848 <DST_FramDSTDecode+0xb90>
   17530: e7923003     	ldr	r3, [r2, r3]
   17534: e59b1004     	ldr	r1, [r11, #0x4]
   17538: e59f230c     	ldr	r2, [pc, #0x30c]        @ 0x1784c <DST_FramDSTDecode+0xb94>
   1753c: e7910002     	ldr	r0, [r1, r2]
   17540: e24b1048     	sub	r1, r11, #72
   17544: e24b2049     	sub	r2, r11, #73
   17548: e58d0000     	str	r0, [sp]
   1754c: e1a00001     	mov	r0, r1
   17550: e1a01002     	mov	r1, r2
   17554: e3a02080     	mov	r2, #128
   17558: ebfffc0c     	bl	0x16590 <LT_ACDecodeBit_Decode> @ imm = #-0xfd0
   1755c: ea00002d     	b	0x17618 <DST_FramDSTDecode+0x960> @ imm = #0xb4
   17560: e51b102c     	ldr	r1, [r11, #-0x2c]
   17564: e51b2030     	ldr	r2, [r11, #-0x30]
   17568: e59b0004     	ldr	r0, [r11, #0x4]
   1756c: e59f32e0     	ldr	r3, [pc, #0x2e0]        @ 0x17854 <DST_FramDSTDecode+0xb9c>
   17570: e3a0cc93     	mov	r12, #37632
   17574: e001019c     	mul	r1, r12, r1
   17578: e0801001     	add	r1, r0, r1
   1757c: e0812002     	add	r2, r1, r2
   17580: e0823003     	add	r3, r2, r3
   17584: e5d33004     	ldrb	r3, [r3, #0x4]
   17588: e50b3010     	str	r3, [r11, #-0x10]
   1758c: e51b3010     	ldr	r3, [r11, #-0x10]
   17590: e59b1004     	ldr	r1, [r11, #0x4]
   17594: e2832010     	add	r2, r3, #16
   17598: e3a03004     	mov	r3, #4
   1759c: e1a02102     	lsl	r2, r2, #2
   175a0: e0812002     	add	r2, r1, r2
   175a4: e0823003     	add	r3, r2, r3
   175a8: e5933000     	ldr	r3, [r3]
   175ac: e15b21f8     	ldrsh	r2, [r11, #-24]
   175b0: e1a00002     	mov	r0, r2
   175b4: e1a01003     	mov	r1, r3
   175b8: ebfffc7e     	bl	0x167b8 <LT_ACGetPtableIndex> @ imm = #-0xe08
   175bc: e1a03000     	mov	r3, r0
   175c0: e50b300c     	str	r3, [r11, #-0xc]
   175c4: e59b2004     	ldr	r2, [r11, #0x4]
   175c8: e59f3288     	ldr	r3, [pc, #0x288]        @ 0x17858 <DST_FramDSTDecode+0xba0>
   175cc: e7922003     	ldr	r2, [r2, r3]
   175d0: e51b3010     	ldr	r3, [r11, #-0x10]
   175d4: e1a03103     	lsl	r3, r3, #2
   175d8: e0823003     	add	r3, r2, r3
   175dc: e5932000     	ldr	r2, [r3]
   175e0: e51b300c     	ldr	r3, [r11, #-0xc]
   175e4: e1a03103     	lsl	r3, r3, #2
   175e8: e0823003     	add	r3, r2, r3
   175ec: e5932000     	ldr	r2, [r3]
   175f0: e59b1004     	ldr	r1, [r11, #0x4]
   175f4: e59f324c     	ldr	r3, [pc, #0x24c]        @ 0x17848 <DST_FramDSTDecode+0xb90>
   175f8: e7913003     	ldr	r3, [r1, r3]
   175fc: e59b0004     	ldr	r0, [r11, #0x4]
   17600: e59f1244     	ldr	r1, [pc, #0x244]        @ 0x1784c <DST_FramDSTDecode+0xb94>
   17604: e790c001     	ldr	r12, [r0, r1]
   17608: e24b0048     	sub	r0, r11, #72
   1760c: e24b1049     	sub	r1, r11, #73
   17610: e58dc000     	str	r12, [sp]
   17614: ebfffbdd     	bl	0x16590 <LT_ACDecodeBit_Decode> @ imm = #-0x108c
   17618: e15b31b8     	ldrh	r3, [r11, #-24]
   1761c: e1a037a3     	lsr	r3, r3, #15
   17620: e6ff2073     	uxth	r2, r3
   17624: e55b3049     	ldrb	r3, [r11, #-0x49]
   17628: e0223003     	eor	r3, r2, r3
   1762c: e6ff3073     	uxth	r3, r3
   17630: e2033001     	and	r3, r3, #1
   17634: e14b31b6     	strh	r3, [r11, #-22]
   17638: e51b301c     	ldr	r3, [r11, #-0x1c]
   1763c: e51b2024     	ldr	r2, [r11, #-0x24]
   17640: e0020392     	mul	r2, r2, r3
   17644: e51b302c     	ldr	r3, [r11, #-0x2c]
   17648: e0823003     	add	r3, r2, r3
   1764c: e51b2020     	ldr	r2, [r11, #-0x20]
   17650: e0821003     	add	r1, r2, r3
   17654: e51b301c     	ldr	r3, [r11, #-0x1c]
   17658: e51b2024     	ldr	r2, [r11, #-0x24]
   1765c: e0020392     	mul	r2, r2, r3
   17660: e51b302c     	ldr	r3, [r11, #-0x2c]
   17664: e0823003     	add	r3, r2, r3
   17668: e51b2020     	ldr	r2, [r11, #-0x20]
   1766c: e0823003     	add	r3, r2, r3
   17670: e5d30000     	ldrb	r0, [r3]
   17674: e15bc1f6     	ldrsh	r12, [r11, #-22]
   17678: e51b2030     	ldr	r2, [r11, #-0x30]
   1767c: e1a03fc2     	asr	r3, r2, #31
   17680: e1a03ea3     	lsr	r3, r3, #29
   17684: e0822003     	add	r2, r2, r3
   17688: e2022007     	and	r2, r2, #7
   1768c: e0633002     	rsb	r3, r3, r2
   17690: e2633007     	rsb	r3, r3, #7
   17694: e1a0331c     	lsl	r3, r12, r3
   17698: e6ef3073     	uxtb	r3, r3
   1769c: e1803003     	orr	r3, r0, r3
   176a0: e6ef3073     	uxtb	r3, r3
   176a4: e5c13000     	strb	r3, [r1]
   176a8: e24b20ac     	sub	r2, r11, #172
   176ac: e51b302c     	ldr	r3, [r11, #-0x2c]
   176b0: e1a03203     	lsl	r3, r3, #4
   176b4: e0823003     	add	r3, r2, r3
   176b8: e50b3008     	str	r3, [r11, #-0x8]
   176bc: e51b3008     	ldr	r3, [r11, #-0x8]
   176c0: e283300c     	add	r3, r3, #12
   176c4: e51b2008     	ldr	r2, [r11, #-0x8]
   176c8: e282200c     	add	r2, r2, #12
   176cc: e5922000     	ldr	r2, [r2]
   176d0: e1a01082     	lsl	r1, r2, #1
   176d4: e51b2008     	ldr	r2, [r11, #-0x8]
   176d8: e2822008     	add	r2, r2, #8
   176dc: e5922000     	ldr	r2, [r2]
   176e0: e1a02fa2     	lsr	r2, r2, #31
   176e4: e1812002     	orr	r2, r1, r2
   176e8: e5832000     	str	r2, [r3]
   176ec: e51b3008     	ldr	r3, [r11, #-0x8]
   176f0: e2833008     	add	r3, r3, #8
   176f4: e51b2008     	ldr	r2, [r11, #-0x8]
   176f8: e2822008     	add	r2, r2, #8
   176fc: e5922000     	ldr	r2, [r2]
   17700: e1a01082     	lsl	r1, r2, #1
   17704: e51b2008     	ldr	r2, [r11, #-0x8]
   17708: e2822004     	add	r2, r2, #4
   1770c: e5922000     	ldr	r2, [r2]
   17710: e1a02fa2     	lsr	r2, r2, #31
   17714: e1812002     	orr	r2, r1, r2
   17718: e5832000     	str	r2, [r3]
   1771c: e51b3008     	ldr	r3, [r11, #-0x8]
   17720: e2833004     	add	r3, r3, #4
   17724: e51b2008     	ldr	r2, [r11, #-0x8]
   17728: e2822004     	add	r2, r2, #4
   1772c: e5922000     	ldr	r2, [r2]
   17730: e1a01082     	lsl	r1, r2, #1
   17734: e51b2008     	ldr	r2, [r11, #-0x8]
   17738: e5922000     	ldr	r2, [r2]
   1773c: e1a02fa2     	lsr	r2, r2, #31
   17740: e1812002     	orr	r2, r1, r2
   17744: e5832000     	str	r2, [r3]
   17748: e51b3008     	ldr	r3, [r11, #-0x8]
   1774c: e5933000     	ldr	r3, [r3]
   17750: e1a02083     	lsl	r2, r3, #1
   17754: e15b31f6     	ldrsh	r3, [r11, #-22]
   17758: e1822003     	orr	r2, r2, r3
   1775c: e51b3008     	ldr	r3, [r11, #-0x8]
   17760: e5832000     	str	r2, [r3]
   17764: e51b302c     	ldr	r3, [r11, #-0x2c]
   17768: e2833001     	add	r3, r3, #1
   1776c: e50b302c     	str	r3, [r11, #-0x2c]
   17770: e51b202c     	ldr	r2, [r11, #-0x2c]
   17774: e51b3024     	ldr	r3, [r11, #-0x24]
   17778: e1520003     	cmp	r2, r3
   1777c: bafffdd8     	blt	0x16ee4 <DST_FramDSTDecode+0x22c> @ imm = #-0x8a0
   17780: e51b3030     	ldr	r3, [r11, #-0x30]
   17784: e2833001     	add	r3, r3, #1
   17788: e50b3030     	str	r3, [r11, #-0x30]
   1778c: e51b2030     	ldr	r2, [r11, #-0x30]
   17790: e51b3028     	ldr	r3, [r11, #-0x28]
   17794: e1520003     	cmp	r2, r3
   17798: bafffdc8     	blt	0x16ec0 <DST_FramDSTDecode+0x208> @ imm = #-0x8e0
   1779c: e59b2004     	ldr	r2, [r11, #0x4]
   177a0: e59f30a0     	ldr	r3, [pc, #0xa0]         @ 0x17848 <DST_FramDSTDecode+0xb90>
   177a4: e7923003     	ldr	r3, [r2, r3]
   177a8: e59b1004     	ldr	r1, [r11, #0x4]
   177ac: e59f2098     	ldr	r2, [pc, #0x98]         @ 0x1784c <DST_FramDSTDecode+0xb94>
   177b0: e7910002     	ldr	r0, [r1, r2]
   177b4: e24b1048     	sub	r1, r11, #72
   177b8: e24b2035     	sub	r2, r11, #53
   177bc: e58d0000     	str	r0, [sp]
   177c0: e1a00001     	mov	r0, r1
   177c4: e1a01002     	mov	r1, r2
   177c8: e3a02000     	mov	r2, #0
   177cc: ebfffbc6     	bl	0x166ec <LT_ACDecodeBit_Flush> @ imm = #-0x10e8
   177d0: e55b3035     	ldrb	r3, [r11, #-0x35]
   177d4: e3530001     	cmp	r3, #1
   177d8: 0a000001     	beq	0x177e4 <DST_FramDSTDecode+0xb2c> @ imm = #0x4
   177dc: e3a0300f     	mov	r3, #15
   177e0: e50b3034     	str	r3, [r11, #-0x34]
   177e4: e51b3034     	ldr	r3, [r11, #-0x34]
   177e8: e3530000     	cmp	r3, #0
   177ec: 0a00000c     	beq	0x17824 <DST_FramDSTDecode+0xb6c> @ imm = #0x30
   177f0: e51b3028     	ldr	r3, [r11, #-0x28]
   177f4: e51b2024     	ldr	r2, [r11, #-0x24]
   177f8: e0030392     	mul	r3, r2, r3
   177fc: e2832007     	add	r2, r3, #7
   17800: e3530000     	cmp	r3, #0
   17804: b1a03002     	movlt	r3, r2
   17808: e1a031c3     	asr	r3, r3, #3
   1780c: e59f2024     	ldr	r2, [pc, #0x24]         @ 0x17838 <DST_FramDSTDecode+0xb80>
   17810: e24b1004     	sub	r1, r11, #4
   17814: e7910002     	ldr	r0, [r1, r2]
   17818: e3a01055     	mov	r1, #85
   1781c: e1a02003     	mov	r2, r3
   17820: ebffd2df     	bl	0xc3a4 <memset@plt>     @ imm = #-0xb484
   17824: e51b3034     	ldr	r3, [r11, #-0x34]
   17828: e1a00003     	mov	r0, r3
   1782c: e24bd004     	sub	sp, r11, #4
   17830: e8bd8800     	pop	{r11, pc}
   17834: 54 7f fe ff  	.word	0xfffe7f54
   17838: 50 7f fe ff  	.word	0xfffe7f50
   1783c: 4c 7f fe ff  	.word	0xfffe7f4c
   17840: 48 7f fe ff  	.word	0xfffe7f48
   17844: 1c e8 06 00  	.word	0x0006e81c
   17848: 6c e8 06 00  	.word	0x0006e86c
   1784c: 70 e8 06 00  	.word	0x0006e870
   17850: 58 7f fe ff  	.word	0xfffe7f58
   17854: e8 75 03 00  	.word	0x000375e8
   17858: 68 e8 06 00  	.word	0x0006e868

