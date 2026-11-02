00022c18 <add_marker_chunk>:
   22c18: e92d4810     	push	{r4, r11, lr}
   22c1c: e28db008     	add	r11, sp, #8
   22c20: e24dd03c     	sub	sp, sp, #60
   22c24: e50b0038     	str	r0, [r11, #-0x38]
   22c28: e50b103c     	str	r1, [r11, #-0x3c]
   22c2c: e14b24f4     	strd	r2, r3, [r11, #-68]
   22c30: e51b3038     	ldr	r3, [r11, #-0x38]
   22c34: e50b3020     	str	r3, [r11, #-0x20]
   22c38: e14b24d4     	ldrd	r2, r3, [r11, #-68]
   22c3c: e1a00002     	mov	r0, r2
   22c40: e1a01003     	mov	r1, r3
   22c44: e3a0204b     	mov	r2, #75
   22c48: e3a03000     	mov	r3, #0
   22c4c: eb0038d1     	bl	0x30f98 <__aeabi_uldivmod> @ imm = #0xe344
   22c50: e1a02000     	mov	r2, r0
   22c54: e1a03001     	mov	r3, r1
   22c58: e1a03002     	mov	r3, r2
   22c5c: e50b301c     	str	r3, [r11, #-0x1c]
   22c60: e51b301c     	ldr	r3, [r11, #-0x1c]
   22c64: e59f23c8     	ldr	r2, [pc, #0x3c8]        @ 0x23034 <add_marker_chunk+0x41c>
   22c68: e0c21392     	smull	r1, r2, r2, r3
   22c6c: e0822003     	add	r2, r2, r3
   22c70: e1a015c2     	asr	r1, r2, #11
   22c74: e1a02fc3     	asr	r2, r3, #31
   22c78: e0622001     	rsb	r2, r2, r1
   22c7c: e3a01ee1     	mov	r1, #3600
   22c80: e0020291     	mul	r2, r1, r2
   22c84: e0623003     	rsb	r3, r2, r3
   22c88: e50b3018     	str	r3, [r11, #-0x18]
   22c8c: e51b3020     	ldr	r3, [r11, #-0x20]
   22c90: e3a02000     	mov	r2, #0
   22c94: e382204d     	orr	r2, r2, #77
   22c98: e5c32000     	strb	r2, [r3]
   22c9c: e3a02000     	mov	r2, #0
   22ca0: e3822041     	orr	r2, r2, #65
   22ca4: e5c32001     	strb	r2, [r3, #0x1]
   22ca8: e3a02000     	mov	r2, #0
   22cac: e3822052     	orr	r2, r2, #82
   22cb0: e5c32002     	strb	r2, [r3, #0x2]
   22cb4: e3a02000     	mov	r2, #0
   22cb8: e382204b     	orr	r2, r2, #75
   22cbc: e5c32003     	strb	r2, [r3, #0x3]
   22cc0: e51b3020     	ldr	r3, [r11, #-0x20]
   22cc4: e3a02000     	mov	r2, #0
   22cc8: e5c32014     	strb	r2, [r3, #0x14]
   22ccc: e3a02000     	mov	r2, #0
   22cd0: e5c32015     	strb	r2, [r3, #0x15]
   22cd4: e3a02000     	mov	r2, #0
   22cd8: e5c32016     	strb	r2, [r3, #0x16]
   22cdc: e3a02000     	mov	r2, #0
   22ce0: e5c32017     	strb	r2, [r3, #0x17]
   22ce4: e51b301c     	ldr	r3, [r11, #-0x1c]
   22ce8: e59f2344     	ldr	r2, [pc, #0x344]        @ 0x23034 <add_marker_chunk+0x41c>
   22cec: e0c21392     	smull	r1, r2, r2, r3
   22cf0: e0822003     	add	r2, r2, r3
   22cf4: e1a025c2     	asr	r2, r2, #11
   22cf8: e1a03fc3     	asr	r3, r3, #31
   22cfc: e0633002     	rsb	r3, r3, r2
   22d00: e14b31b4     	strh	r3, [r11, #-20]
   22d04: e15b31b4     	ldrh	r3, [r11, #-20]
   22d08: e1a03423     	lsr	r3, r3, #8
   22d0c: e6ff3073     	uxth	r3, r3
   22d10: e1a02003     	mov	r2, r3
   22d14: e15b31b4     	ldrh	r3, [r11, #-20]
   22d18: e1a03403     	lsl	r3, r3, #8
   22d1c: e1a03803     	lsl	r3, r3, #16
   22d20: e1a03823     	lsr	r3, r3, #16
   22d24: e1823003     	orr	r3, r2, r3
   22d28: e6ff2073     	uxth	r2, r3
   22d2c: e51b3020     	ldr	r3, [r11, #-0x20]
   22d30: e20210ff     	and	r1, r2, #255
   22d34: e3a00000     	mov	r0, #0
   22d38: e1801001     	orr	r1, r0, r1
   22d3c: e5c3100c     	strb	r1, [r3, #0xc]
   22d40: e1a02422     	lsr	r2, r2, #8
   22d44: e6ff2072     	uxth	r2, r2
   22d48: e3a01000     	mov	r1, #0
   22d4c: e1812002     	orr	r2, r1, r2
   22d50: e5c3200d     	strb	r2, [r3, #0xd]
   22d54: e51b3018     	ldr	r3, [r11, #-0x18]
   22d58: e59f22d8     	ldr	r2, [pc, #0x2d8]        @ 0x23038 <add_marker_chunk+0x420>
   22d5c: e0c21392     	smull	r1, r2, r2, r3
   22d60: e0822003     	add	r2, r2, r3
   22d64: e1a022c2     	asr	r2, r2, #5
   22d68: e1a03fc3     	asr	r3, r3, #31
   22d6c: e0633002     	rsb	r3, r3, r2
   22d70: e6ef2073     	uxtb	r2, r3
   22d74: e51b3020     	ldr	r3, [r11, #-0x20]
   22d78: e5c3200e     	strb	r2, [r3, #0xe]
   22d7c: e51b3018     	ldr	r3, [r11, #-0x18]
   22d80: e59f22b0     	ldr	r2, [pc, #0x2b0]        @ 0x23038 <add_marker_chunk+0x420>
   22d84: e0c21392     	smull	r1, r2, r2, r3
   22d88: e0822003     	add	r2, r2, r3
   22d8c: e1a012c2     	asr	r1, r2, #5
   22d90: e1a02fc3     	asr	r2, r3, #31
   22d94: e0622001     	rsb	r2, r2, r1
   22d98: e1a01102     	lsl	r1, r2, #2
   22d9c: e1a02201     	lsl	r2, r1, #4
   22da0: e0612002     	rsb	r2, r1, r2
   22da4: e0622003     	rsb	r2, r2, r3
   22da8: e6ef2072     	uxtb	r2, r2
   22dac: e51b3020     	ldr	r3, [r11, #-0x20]
   22db0: e5c3200f     	strb	r2, [r3, #0xf]
   22db4: e14b24d4     	ldrd	r2, r3, [r11, #-68]
   22db8: e1a00002     	mov	r0, r2
   22dbc: e1a01003     	mov	r1, r3
   22dc0: e3a0204b     	mov	r2, #75
   22dc4: e3a03000     	mov	r3, #0
   22dc8: eb003872     	bl	0x30f98 <__aeabi_uldivmod> @ imm = #0xe1c8
   22dcc: e1a03002     	mov	r3, r2
   22dd0: e3a02c93     	mov	r2, #37632
   22dd4: e0040392     	mul	r4, r2, r3
   22dd8: e1a02c24     	lsr	r2, r4, #24
   22ddc: e20438ff     	and	r3, r4, #16711680
   22de0: e1a03423     	lsr	r3, r3, #8
   22de4: e1822003     	orr	r2, r2, r3
   22de8: e2043cff     	and	r3, r4, #65280
   22dec: e1a03403     	lsl	r3, r3, #8
   22df0: e1822003     	orr	r2, r2, r3
   22df4: e1a03c04     	lsl	r3, r4, #24
   22df8: e1822003     	orr	r2, r2, r3
   22dfc: e51b3020     	ldr	r3, [r11, #-0x20]
   22e00: e20210ff     	and	r1, r2, #255
   22e04: e3a00000     	mov	r0, #0
   22e08: e1801001     	orr	r1, r0, r1
   22e0c: e5c31010     	strb	r1, [r3, #0x10]
   22e10: e1a01422     	lsr	r1, r2, #8
   22e14: e20110ff     	and	r1, r1, #255
   22e18: e3a00000     	mov	r0, #0
   22e1c: e1801001     	orr	r1, r0, r1
   22e20: e5c31011     	strb	r1, [r3, #0x11]
   22e24: e1a01822     	lsr	r1, r2, #16
   22e28: e20110ff     	and	r1, r1, #255
   22e2c: e3a00000     	mov	r0, #0
   22e30: e1801001     	orr	r1, r0, r1
   22e34: e5c31012     	strb	r1, [r3, #0x12]
   22e38: e1a02c22     	lsr	r2, r2, #24
   22e3c: e3a01000     	mov	r1, #0
   22e40: e1812002     	orr	r2, r1, r2
   22e44: e5c32013     	strb	r2, [r3, #0x13]
   22e48: e1db30b4     	ldrh	r3, [r11, #4]
   22e4c: e14b31b2     	strh	r3, [r11, #-18]
   22e50: e15b31b2     	ldrh	r3, [r11, #-18]
   22e54: e1a03423     	lsr	r3, r3, #8
   22e58: e6ff3073     	uxth	r3, r3
   22e5c: e1a02003     	mov	r2, r3
   22e60: e15b31b2     	ldrh	r3, [r11, #-18]
   22e64: e1a03403     	lsl	r3, r3, #8
   22e68: e1a03803     	lsl	r3, r3, #16
   22e6c: e1a03823     	lsr	r3, r3, #16
   22e70: e1823003     	orr	r3, r2, r3
   22e74: e6ff2073     	uxth	r2, r3
   22e78: e51b3020     	ldr	r3, [r11, #-0x20]
   22e7c: e20210ff     	and	r1, r2, #255
   22e80: e3a00000     	mov	r0, #0
   22e84: e1801001     	orr	r1, r0, r1
   22e88: e5c31018     	strb	r1, [r3, #0x18]
   22e8c: e1a02422     	lsr	r2, r2, #8
   22e90: e6ff2072     	uxth	r2, r2
   22e94: e3a01000     	mov	r1, #0
   22e98: e1812002     	orr	r2, r1, r2
   22e9c: e5c32019     	strb	r2, [r3, #0x19]
   22ea0: e3a03000     	mov	r3, #0
   22ea4: e14b31b0     	strh	r3, [r11, #-16]
   22ea8: e15b31b0     	ldrh	r3, [r11, #-16]
   22eac: e1a03423     	lsr	r3, r3, #8
   22eb0: e6ff3073     	uxth	r3, r3
   22eb4: e1a02003     	mov	r2, r3
   22eb8: e15b31b0     	ldrh	r3, [r11, #-16]
   22ebc: e1a03403     	lsl	r3, r3, #8
   22ec0: e1a03803     	lsl	r3, r3, #16
   22ec4: e1a03823     	lsr	r3, r3, #16
   22ec8: e1823003     	orr	r3, r2, r3
   22ecc: e6ff2073     	uxth	r2, r3
   22ed0: e51b3020     	ldr	r3, [r11, #-0x20]
   22ed4: e20210ff     	and	r1, r2, #255
   22ed8: e3a00000     	mov	r0, #0
   22edc: e1801001     	orr	r1, r0, r1
   22ee0: e5c3101a     	strb	r1, [r3, #0x1a]
   22ee4: e1a02422     	lsr	r2, r2, #8
   22ee8: e6ff2072     	uxth	r2, r2
   22eec: e3a01000     	mov	r1, #0
   22ef0: e1812002     	orr	r2, r1, r2
   22ef4: e5c3201b     	strb	r2, [r3, #0x1b]
   22ef8: e1db30b8     	ldrh	r3, [r11, #8]
   22efc: e14b30be     	strh	r3, [r11, #-14]
   22f00: e15b30be     	ldrh	r3, [r11, #-14]
   22f04: e1a03423     	lsr	r3, r3, #8
   22f08: e6ff3073     	uxth	r3, r3
   22f0c: e1a02003     	mov	r2, r3
   22f10: e15b30be     	ldrh	r3, [r11, #-14]
   22f14: e1a03403     	lsl	r3, r3, #8
   22f18: e1a03803     	lsl	r3, r3, #16
   22f1c: e1a03823     	lsr	r3, r3, #16
   22f20: e1823003     	orr	r3, r2, r3
   22f24: e6ff2073     	uxth	r2, r3
   22f28: e51b3020     	ldr	r3, [r11, #-0x20]
   22f2c: e20210ff     	and	r1, r2, #255
   22f30: e3a00000     	mov	r0, #0
   22f34: e1801001     	orr	r1, r0, r1
   22f38: e5c3101c     	strb	r1, [r3, #0x1c]
   22f3c: e1a02422     	lsr	r2, r2, #8
   22f40: e6ff2072     	uxth	r2, r2
   22f44: e3a01000     	mov	r1, #0
   22f48: e1812002     	orr	r2, r1, r2
   22f4c: e5c3201d     	strb	r2, [r3, #0x1d]
   22f50: e51b3020     	ldr	r3, [r11, #-0x20]
   22f54: e3a02000     	mov	r2, #0
   22f58: e5c3201e     	strb	r2, [r3, #0x1e]
   22f5c: e3a02000     	mov	r2, #0
   22f60: e5c3201f     	strb	r2, [r3, #0x1f]
   22f64: e3a02000     	mov	r2, #0
   22f68: e5c32020     	strb	r2, [r3, #0x20]
   22f6c: e3a02000     	mov	r2, #0
   22f70: e5c32021     	strb	r2, [r3, #0x21]
   22f74: e3a02000     	mov	r2, #0
   22f78: e3a03416     	mov	r3, #369098752
   22f7c: e14b23f4     	strd	r2, r3, [r11, #-52]
   22f80: e14b23d4     	ldrd	r2, r3, [r11, #-52]
   22f84: e51b1020     	ldr	r1, [r11, #-0x20]
   22f88: e20200ff     	and	r0, r2, #255
   22f8c: e3a0c000     	mov	r12, #0
   22f90: e18c0000     	orr	r0, r12, r0
   22f94: e5c10004     	strb	r0, [r1, #0x4]
   22f98: e1a00422     	lsr	r0, r2, #8
   22f9c: e20000ff     	and	r0, r0, #255
   22fa0: e3a0c000     	mov	r12, #0
   22fa4: e18c0000     	orr	r0, r12, r0
   22fa8: e5c10005     	strb	r0, [r1, #0x5]
   22fac: e1a00822     	lsr	r0, r2, #16
   22fb0: e20000ff     	and	r0, r0, #255
   22fb4: e3a0c000     	mov	r12, #0
   22fb8: e18c0000     	orr	r0, r12, r0
   22fbc: e5c10006     	strb	r0, [r1, #0x6]
   22fc0: e1a00c22     	lsr	r0, r2, #24
   22fc4: e3a0c000     	mov	r12, #0
   22fc8: e18c0000     	orr	r0, r12, r0
   22fcc: e5c10007     	strb	r0, [r1, #0x7]
   22fd0: e20300ff     	and	r0, r3, #255
   22fd4: e3a0c000     	mov	r12, #0
   22fd8: e18c0000     	orr	r0, r12, r0
   22fdc: e5c10008     	strb	r0, [r1, #0x8]
   22fe0: e1a00423     	lsr	r0, r3, #8
   22fe4: e20000ff     	and	r0, r0, #255
   22fe8: e3a0c000     	mov	r12, #0
   22fec: e18c0000     	orr	r0, r12, r0
   22ff0: e5c10009     	strb	r0, [r1, #0x9]
   22ff4: e1a00823     	lsr	r0, r3, #16
   22ff8: e20000ff     	and	r0, r0, #255
   22ffc: e3a0c000     	mov	r12, #0
   23000: e18c0000     	orr	r0, r12, r0
   23004: e5c1000a     	strb	r0, [r1, #0xa]
   23008: e1a03c23     	lsr	r3, r3, #24
   2300c: e3a02000     	mov	r2, #0
   23010: e1823003     	orr	r3, r2, r3
   23014: e5c1300b     	strb	r3, [r1, #0xb]
   23018: e51b3038     	ldr	r3, [r11, #-0x38]
   2301c: e2833022     	add	r3, r3, #34
   23020: e50b3038     	str	r3, [r11, #-0x38]
   23024: e51b3038     	ldr	r3, [r11, #-0x38]
   23028: e1a00003     	mov	r0, r3
   2302c: e24bd008     	sub	sp, r11, #8
   23030: e8bd8810     	pop	{r4, r11, pc}
   23034: c5 b3 a2 91  	.word	0x91a2b3c5
   23038: 89 88 88 88  	.word	0x88888889

