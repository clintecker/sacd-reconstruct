00013e7c <hex_dump_to_buffer>:
   13e7c: e92d4810     	push	{r4, r11, lr}
   13e80: e28db008     	add	r11, sp, #8
   13e84: e24dd04c     	sub	sp, sp, #76
   13e88: e50b0040     	str	r0, [r11, #-0x40]
   13e8c: e50b1044     	str	r1, [r11, #-0x44]
   13e90: e50b2048     	str	r2, [r11, #-0x48]
   13e94: e50b304c     	str	r3, [r11, #-0x4c]
   13e98: e51b3040     	ldr	r3, [r11, #-0x40]
   13e9c: e50b3038     	str	r3, [r11, #-0x38]
   13ea0: e3a03000     	mov	r3, #0
   13ea4: e50b302c     	str	r3, [r11, #-0x2c]
   13ea8: e51b3048     	ldr	r3, [r11, #-0x48]
   13eac: e3530010     	cmp	r3, #16
   13eb0: 0a000004     	beq	0x13ec8 <hex_dump_to_buffer+0x4c> @ imm = #0x10
   13eb4: e51b3048     	ldr	r3, [r11, #-0x48]
   13eb8: e3530020     	cmp	r3, #32
   13ebc: 0a000001     	beq	0x13ec8 <hex_dump_to_buffer+0x4c> @ imm = #0x4
   13ec0: e3a03010     	mov	r3, #16
   13ec4: e50b3048     	str	r3, [r11, #-0x48]
   13ec8: e51b3044     	ldr	r3, [r11, #-0x44]
   13ecc: e3530000     	cmp	r3, #0
   13ed0: 0a00012f     	beq	0x14394 <hex_dump_to_buffer+0x518> @ imm = #0x4bc
   13ed4: e51b2044     	ldr	r2, [r11, #-0x44]
   13ed8: e51b3048     	ldr	r3, [r11, #-0x48]
   13edc: e1520003     	cmp	r2, r3
   13ee0: da000001     	ble	0x13eec <hex_dump_to_buffer+0x70> @ imm = #0x4
   13ee4: e51b3048     	ldr	r3, [r11, #-0x48]
   13ee8: e50b3044     	str	r3, [r11, #-0x44]
   13eec: e51b3044     	ldr	r3, [r11, #-0x44]
   13ef0: e1a00003     	mov	r0, r3
   13ef4: e51b104c     	ldr	r1, [r11, #-0x4c]
   13ef8: eb00703b     	bl	0x2ffec <__aeabi_idivmod> @ imm = #0x1c0ec
   13efc: e1a03001     	mov	r3, r1
   13f00: e3530000     	cmp	r3, #0
   13f04: 0a000001     	beq	0x13f10 <hex_dump_to_buffer+0x94> @ imm = #0x4
   13f08: e3a03001     	mov	r3, #1
   13f0c: e50b304c     	str	r3, [r11, #-0x4c]
   13f10: e51b304c     	ldr	r3, [r11, #-0x4c]
   13f14: e3530004     	cmp	r3, #4
   13f18: 0a000037     	beq	0x13ffc <hex_dump_to_buffer+0x180> @ imm = #0xdc
   13f1c: e3530008     	cmp	r3, #8
   13f20: 0a000002     	beq	0x13f30 <hex_dump_to_buffer+0xb4> @ imm = #0x8
   13f24: e3530002     	cmp	r3, #2
   13f28: 0a000064     	beq	0x140c0 <hex_dump_to_buffer+0x244> @ imm = #0x190
   13f2c: ea000094     	b	0x14184 <hex_dump_to_buffer+0x308> @ imm = #0x250
   13f30: e51b3040     	ldr	r3, [r11, #-0x40]
   13f34: e50b3024     	str	r3, [r11, #-0x24]
   13f38: e51b0044     	ldr	r0, [r11, #-0x44]
   13f3c: e51b104c     	ldr	r1, [r11, #-0x4c]
   13f40: eb006fa1     	bl	0x2fdcc <__divsi3>      @ imm = #0x1be84
   13f44: e1a03000     	mov	r3, r0
   13f48: e50b3020     	str	r3, [r11, #-0x20]
   13f4c: e3a03000     	mov	r3, #0
   13f50: e50b3030     	str	r3, [r11, #-0x30]
   13f54: ea00001d     	b	0x13fd0 <hex_dump_to_buffer+0x154> @ imm = #0x74
   13f58: e51b302c     	ldr	r3, [r11, #-0x2c]
   13f5c: e59b2004     	ldr	r2, [r11, #0x4]
   13f60: e0820003     	add	r0, r2, r3
   13f64: e59b2008     	ldr	r2, [r11, #0x8]
   13f68: e51b302c     	ldr	r3, [r11, #-0x2c]
   13f6c: e0633002     	rsb	r3, r3, r2
   13f70: e1a01003     	mov	r1, r3
   13f74: e59fe444     	ldr	lr, [pc, #0x444]        @ 0x143c0 <hex_dump_to_buffer+0x544>
   13f78: e51b3030     	ldr	r3, [r11, #-0x30]
   13f7c: e3530000     	cmp	r3, #0
   13f80: 0a000001     	beq	0x13f8c <hex_dump_to_buffer+0x110> @ imm = #0x4
   13f84: e59fc438     	ldr	r12, [pc, #0x438]       @ 0x143c4 <hex_dump_to_buffer+0x548>
   13f88: ea000000     	b	0x13f90 <hex_dump_to_buffer+0x114> @ imm = #0x0
   13f8c: e59fc434     	ldr	r12, [pc, #0x434]       @ 0x143c8 <hex_dump_to_buffer+0x54c>
   13f90: e51b3030     	ldr	r3, [r11, #-0x30]
   13f94: e1a03183     	lsl	r3, r3, #3
   13f98: e51b2024     	ldr	r2, [r11, #-0x24]
   13f9c: e0823003     	add	r3, r2, r3
   13fa0: e1c320d0     	ldrd	r2, r3, [r3]
   13fa4: e1cd20f0     	strd	r2, r3, [sp]
   13fa8: e1a0200e     	mov	r2, lr
   13fac: e1a0300c     	mov	r3, r12
   13fb0: ebffe1e2     	bl	0xc740 <snprintf@plt>   @ imm = #-0x7878
   13fb4: e1a03000     	mov	r3, r0
   13fb8: e51b202c     	ldr	r2, [r11, #-0x2c]
   13fbc: e0823003     	add	r3, r2, r3
   13fc0: e50b302c     	str	r3, [r11, #-0x2c]
   13fc4: e51b3030     	ldr	r3, [r11, #-0x30]
   13fc8: e2833001     	add	r3, r3, #1
   13fcc: e50b3030     	str	r3, [r11, #-0x30]
   13fd0: e51b2030     	ldr	r2, [r11, #-0x30]
   13fd4: e51b3020     	ldr	r3, [r11, #-0x20]
   13fd8: e1520003     	cmp	r2, r3
   13fdc: baffffdd     	blt	0x13f58 <hex_dump_to_buffer+0xdc> @ imm = #-0x8c
   13fe0: e51b2020     	ldr	r2, [r11, #-0x20]
   13fe4: e1a03002     	mov	r3, r2
   13fe8: e1a03203     	lsl	r3, r3, #4
   13fec: e0833002     	add	r3, r3, r2
   13ff0: e2833002     	add	r3, r3, #2
   13ff4: e50b3028     	str	r3, [r11, #-0x28]
   13ff8: ea0000a0     	b	0x14280 <hex_dump_to_buffer+0x404> @ imm = #0x280
   13ffc: e51b3040     	ldr	r3, [r11, #-0x40]
   14000: e50b301c     	str	r3, [r11, #-0x1c]
   14004: e51b0044     	ldr	r0, [r11, #-0x44]
   14008: e51b104c     	ldr	r1, [r11, #-0x4c]
   1400c: eb006f6e     	bl	0x2fdcc <__divsi3>      @ imm = #0x1bdb8
   14010: e1a03000     	mov	r3, r0
   14014: e50b3018     	str	r3, [r11, #-0x18]
   14018: e3a03000     	mov	r3, #0
   1401c: e50b3030     	str	r3, [r11, #-0x30]
   14020: ea00001b     	b	0x14094 <hex_dump_to_buffer+0x218> @ imm = #0x6c
   14024: e51b302c     	ldr	r3, [r11, #-0x2c]
   14028: e59b2004     	ldr	r2, [r11, #0x4]
   1402c: e0820003     	add	r0, r2, r3
   14030: e59b2008     	ldr	r2, [r11, #0x8]
   14034: e51b302c     	ldr	r3, [r11, #-0x2c]
   14038: e0633002     	rsb	r3, r3, r2
   1403c: e1a01003     	mov	r1, r3
   14040: e59f2384     	ldr	r2, [pc, #0x384]        @ 0x143cc <hex_dump_to_buffer+0x550>
   14044: e51b3030     	ldr	r3, [r11, #-0x30]
   14048: e3530000     	cmp	r3, #0
   1404c: 0a000001     	beq	0x14058 <hex_dump_to_buffer+0x1dc> @ imm = #0x4
   14050: e59f336c     	ldr	r3, [pc, #0x36c]        @ 0x143c4 <hex_dump_to_buffer+0x548>
   14054: ea000000     	b	0x1405c <hex_dump_to_buffer+0x1e0> @ imm = #0x0
   14058: e59f3368     	ldr	r3, [pc, #0x368]        @ 0x143c8 <hex_dump_to_buffer+0x54c>
   1405c: e51bc030     	ldr	r12, [r11, #-0x30]
   14060: e1a0c10c     	lsl	r12, r12, #2
   14064: e51be01c     	ldr	lr, [r11, #-0x1c]
   14068: e08ec00c     	add	r12, lr, r12
   1406c: e59cc000     	ldr	r12, [r12]
   14070: e58dc000     	str	r12, [sp]
   14074: ebffe1b1     	bl	0xc740 <snprintf@plt>   @ imm = #-0x793c
   14078: e1a03000     	mov	r3, r0
   1407c: e51b202c     	ldr	r2, [r11, #-0x2c]
   14080: e0823003     	add	r3, r2, r3
   14084: e50b302c     	str	r3, [r11, #-0x2c]
   14088: e51b3030     	ldr	r3, [r11, #-0x30]
   1408c: e2833001     	add	r3, r3, #1
   14090: e50b3030     	str	r3, [r11, #-0x30]
   14094: e51b2030     	ldr	r2, [r11, #-0x30]
   14098: e51b3018     	ldr	r3, [r11, #-0x18]
   1409c: e1520003     	cmp	r2, r3
   140a0: baffffdf     	blt	0x14024 <hex_dump_to_buffer+0x1a8> @ imm = #-0x84
   140a4: e51b2018     	ldr	r2, [r11, #-0x18]
   140a8: e1a03002     	mov	r3, r2
   140ac: e1a03183     	lsl	r3, r3, #3
   140b0: e0833002     	add	r3, r3, r2
   140b4: e2833002     	add	r3, r3, #2
   140b8: e50b3028     	str	r3, [r11, #-0x28]
   140bc: ea00006f     	b	0x14280 <hex_dump_to_buffer+0x404> @ imm = #0x1bc
   140c0: e51b3040     	ldr	r3, [r11, #-0x40]
   140c4: e50b3014     	str	r3, [r11, #-0x14]
   140c8: e51b0044     	ldr	r0, [r11, #-0x44]
   140cc: e51b104c     	ldr	r1, [r11, #-0x4c]
   140d0: eb006f3d     	bl	0x2fdcc <__divsi3>      @ imm = #0x1bcf4
   140d4: e1a03000     	mov	r3, r0
   140d8: e50b3010     	str	r3, [r11, #-0x10]
   140dc: e3a03000     	mov	r3, #0
   140e0: e50b3030     	str	r3, [r11, #-0x30]
   140e4: ea00001b     	b	0x14158 <hex_dump_to_buffer+0x2dc> @ imm = #0x6c
   140e8: e51b302c     	ldr	r3, [r11, #-0x2c]
   140ec: e59b2004     	ldr	r2, [r11, #0x4]
   140f0: e0820003     	add	r0, r2, r3
   140f4: e59b2008     	ldr	r2, [r11, #0x8]
   140f8: e51b302c     	ldr	r3, [r11, #-0x2c]
   140fc: e0633002     	rsb	r3, r3, r2
   14100: e1a01003     	mov	r1, r3
   14104: e59f22c4     	ldr	r2, [pc, #0x2c4]        @ 0x143d0 <hex_dump_to_buffer+0x554>
   14108: e51b3030     	ldr	r3, [r11, #-0x30]
   1410c: e3530000     	cmp	r3, #0
   14110: 0a000001     	beq	0x1411c <hex_dump_to_buffer+0x2a0> @ imm = #0x4
   14114: e59f32a8     	ldr	r3, [pc, #0x2a8]        @ 0x143c4 <hex_dump_to_buffer+0x548>
   14118: ea000000     	b	0x14120 <hex_dump_to_buffer+0x2a4> @ imm = #0x0
   1411c: e59f32a4     	ldr	r3, [pc, #0x2a4]        @ 0x143c8 <hex_dump_to_buffer+0x54c>
   14120: e51bc030     	ldr	r12, [r11, #-0x30]
   14124: e1a0c08c     	lsl	r12, r12, #1
   14128: e51be014     	ldr	lr, [r11, #-0x14]
   1412c: e08ec00c     	add	r12, lr, r12
   14130: e1dcc0b0     	ldrh	r12, [r12]
   14134: e58dc000     	str	r12, [sp]
   14138: ebffe180     	bl	0xc740 <snprintf@plt>   @ imm = #-0x7a00
   1413c: e1a03000     	mov	r3, r0
   14140: e51b202c     	ldr	r2, [r11, #-0x2c]
   14144: e0823003     	add	r3, r2, r3
   14148: e50b302c     	str	r3, [r11, #-0x2c]
   1414c: e51b3030     	ldr	r3, [r11, #-0x30]
   14150: e2833001     	add	r3, r3, #1
   14154: e50b3030     	str	r3, [r11, #-0x30]
   14158: e51b2030     	ldr	r2, [r11, #-0x30]
   1415c: e51b3010     	ldr	r3, [r11, #-0x10]
   14160: e1520003     	cmp	r2, r3
   14164: baffffdf     	blt	0x140e8 <hex_dump_to_buffer+0x26c> @ imm = #-0x84
   14168: e51b2010     	ldr	r2, [r11, #-0x10]
   1416c: e1a03002     	mov	r3, r2
   14170: e1a03103     	lsl	r3, r3, #2
   14174: e0833002     	add	r3, r3, r2
   14178: e2833002     	add	r3, r3, #2
   1417c: e50b3028     	str	r3, [r11, #-0x28]
   14180: ea00003e     	b	0x14280 <hex_dump_to_buffer+0x404> @ imm = #0xf8
   14184: e3a03000     	mov	r3, #0
   14188: e50b3030     	str	r3, [r11, #-0x30]
   1418c: ea000026     	b	0x1422c <hex_dump_to_buffer+0x3b0> @ imm = #0x98
   14190: e51b3030     	ldr	r3, [r11, #-0x30]
   14194: e51b2038     	ldr	r2, [r11, #-0x38]
   14198: e0823003     	add	r3, r2, r3
   1419c: e5d33000     	ldrb	r3, [r3]
   141a0: e54b3031     	strb	r3, [r11, #-0x31]
   141a4: e51b302c     	ldr	r3, [r11, #-0x2c]
   141a8: e59b2004     	ldr	r2, [r11, #0x4]
   141ac: e0823003     	add	r3, r2, r3
   141b0: e55b2031     	ldrb	r2, [r11, #-0x31]
   141b4: e1a02222     	lsr	r2, r2, #4
   141b8: e6ef2072     	uxtb	r2, r2
   141bc: e59f1210     	ldr	r1, [pc, #0x210]        @ 0x143d4 <hex_dump_to_buffer+0x558>
   141c0: e7d12002     	ldrb	r2, [r1, r2]
   141c4: e5c32000     	strb	r2, [r3]
   141c8: e51b302c     	ldr	r3, [r11, #-0x2c]
   141cc: e2833001     	add	r3, r3, #1
   141d0: e50b302c     	str	r3, [r11, #-0x2c]
   141d4: e51b302c     	ldr	r3, [r11, #-0x2c]
   141d8: e59b2004     	ldr	r2, [r11, #0x4]
   141dc: e0823003     	add	r3, r2, r3
   141e0: e55b2031     	ldrb	r2, [r11, #-0x31]
   141e4: e202200f     	and	r2, r2, #15
   141e8: e59f11e4     	ldr	r1, [pc, #0x1e4]        @ 0x143d4 <hex_dump_to_buffer+0x558>
   141ec: e7d12002     	ldrb	r2, [r1, r2]
   141f0: e5c32000     	strb	r2, [r3]
   141f4: e51b302c     	ldr	r3, [r11, #-0x2c]
   141f8: e2833001     	add	r3, r3, #1
   141fc: e50b302c     	str	r3, [r11, #-0x2c]
   14200: e51b302c     	ldr	r3, [r11, #-0x2c]
   14204: e59b2004     	ldr	r2, [r11, #0x4]
   14208: e0823003     	add	r3, r2, r3
   1420c: e3a02020     	mov	r2, #32
   14210: e5c32000     	strb	r2, [r3]
   14214: e51b302c     	ldr	r3, [r11, #-0x2c]
   14218: e2833001     	add	r3, r3, #1
   1421c: e50b302c     	str	r3, [r11, #-0x2c]
   14220: e51b3030     	ldr	r3, [r11, #-0x30]
   14224: e2833001     	add	r3, r3, #1
   14228: e50b3030     	str	r3, [r11, #-0x30]
   1422c: e51b2030     	ldr	r2, [r11, #-0x30]
   14230: e51b3044     	ldr	r3, [r11, #-0x44]
   14234: e1520003     	cmp	r2, r3
   14238: aa000004     	bge	0x14250 <hex_dump_to_buffer+0x3d4> @ imm = #0x10
   1423c: e51b302c     	ldr	r3, [r11, #-0x2c]
   14240: e2832003     	add	r2, r3, #3
   14244: e59b3008     	ldr	r3, [r11, #0x8]
   14248: e1520003     	cmp	r2, r3
   1424c: daffffcf     	ble	0x14190 <hex_dump_to_buffer+0x314> @ imm = #-0xc4
   14250: e51b3030     	ldr	r3, [r11, #-0x30]
   14254: e3530000     	cmp	r3, #0
   14258: 0a000002     	beq	0x14268 <hex_dump_to_buffer+0x3ec> @ imm = #0x8
   1425c: e51b302c     	ldr	r3, [r11, #-0x2c]
   14260: e2433001     	sub	r3, r3, #1
   14264: e50b302c     	str	r3, [r11, #-0x2c]
   14268: e51b2048     	ldr	r2, [r11, #-0x48]
   1426c: e1a03002     	mov	r3, r2
   14270: e1a03083     	lsl	r3, r3, #1
   14274: e0833002     	add	r3, r3, r2
   14278: e2833002     	add	r3, r3, #2
   1427c: e50b3028     	str	r3, [r11, #-0x28]
   14280: e59b300c     	ldr	r3, [r11, #0xc]
   14284: e3530000     	cmp	r3, #0
   14288: 1a000009     	bne	0x142b4 <hex_dump_to_buffer+0x438> @ imm = #0x24
   1428c: ea000041     	b	0x14398 <hex_dump_to_buffer+0x51c> @ imm = #0x104
   14290: e51b302c     	ldr	r3, [r11, #-0x2c]
   14294: e59b2004     	ldr	r2, [r11, #0x4]
   14298: e0823003     	add	r3, r2, r3
   1429c: e3a02020     	mov	r2, #32
   142a0: e5c32000     	strb	r2, [r3]
   142a4: e51b302c     	ldr	r3, [r11, #-0x2c]
   142a8: e2833001     	add	r3, r3, #1
   142ac: e50b302c     	str	r3, [r11, #-0x2c]
   142b0: ea000000     	b	0x142b8 <hex_dump_to_buffer+0x43c> @ imm = #0x0
   142b4: e1a00000     	mov	r0, r0
   142b8: e59b3008     	ldr	r3, [r11, #0x8]
   142bc: e2432001     	sub	r2, r3, #1
   142c0: e51b302c     	ldr	r3, [r11, #-0x2c]
   142c4: e1520003     	cmp	r2, r3
   142c8: da000004     	ble	0x142e0 <hex_dump_to_buffer+0x464> @ imm = #0x10
   142cc: e51b3028     	ldr	r3, [r11, #-0x28]
   142d0: e2432001     	sub	r2, r3, #1
   142d4: e51b302c     	ldr	r3, [r11, #-0x2c]
   142d8: e1520003     	cmp	r2, r3
   142dc: caffffeb     	bgt	0x14290 <hex_dump_to_buffer+0x414> @ imm = #-0x54
   142e0: e3a03000     	mov	r3, #0
   142e4: e50b3030     	str	r3, [r11, #-0x30]
   142e8: ea00001f     	b	0x1436c <hex_dump_to_buffer+0x4f0> @ imm = #0x7c
   142ec: e51b3030     	ldr	r3, [r11, #-0x30]
   142f0: e51b2038     	ldr	r2, [r11, #-0x38]
   142f4: e0823003     	add	r3, r2, r3
   142f8: e5d33000     	ldrb	r3, [r3]
   142fc: e54b3031     	strb	r3, [r11, #-0x31]
   14300: e51b302c     	ldr	r3, [r11, #-0x2c]
   14304: e59b2004     	ldr	r2, [r11, #0x4]
   14308: e0824003     	add	r4, r2, r3
   1430c: e55b3031     	ldrb	r3, [r11, #-0x31]
   14310: e3c3307f     	bic	r3, r3, #127
   14314: e3530000     	cmp	r3, #0
   14318: 1a00000b     	bne	0x1434c <hex_dump_to_buffer+0x4d0> @ imm = #0x2c
   1431c: ebffe0c2     	bl	0xc62c <__ctype_b_loc@plt> @ imm = #-0x7cf8
   14320: e1a03000     	mov	r3, r0
   14324: e5932000     	ldr	r2, [r3]
   14328: e55b3031     	ldrb	r3, [r11, #-0x31]
   1432c: e1a03083     	lsl	r3, r3, #1
   14330: e0823003     	add	r3, r2, r3
   14334: e1d330b0     	ldrh	r3, [r3]
   14338: e2033901     	and	r3, r3, #16384
   1433c: e3530000     	cmp	r3, #0
   14340: 0a000001     	beq	0x1434c <hex_dump_to_buffer+0x4d0> @ imm = #0x4
   14344: e55b3031     	ldrb	r3, [r11, #-0x31]
   14348: ea000000     	b	0x14350 <hex_dump_to_buffer+0x4d4> @ imm = #0x0
   1434c: e3a0302e     	mov	r3, #46
   14350: e5c43000     	strb	r3, [r4]
   14354: e51b302c     	ldr	r3, [r11, #-0x2c]
   14358: e2833001     	add	r3, r3, #1
   1435c: e50b302c     	str	r3, [r11, #-0x2c]
   14360: e51b3030     	ldr	r3, [r11, #-0x30]
   14364: e2833001     	add	r3, r3, #1
   14368: e50b3030     	str	r3, [r11, #-0x30]
   1436c: e51b2030     	ldr	r2, [r11, #-0x30]
   14370: e51b3044     	ldr	r3, [r11, #-0x44]
   14374: e1520003     	cmp	r2, r3
   14378: aa000006     	bge	0x14398 <hex_dump_to_buffer+0x51c> @ imm = #0x18
   1437c: e51b302c     	ldr	r3, [r11, #-0x2c]
   14380: e2832002     	add	r2, r3, #2
   14384: e59b3008     	ldr	r3, [r11, #0x8]
   14388: e1520003     	cmp	r2, r3
   1438c: baffffd6     	blt	0x142ec <hex_dump_to_buffer+0x470> @ imm = #-0xa8
   14390: ea000000     	b	0x14398 <hex_dump_to_buffer+0x51c> @ imm = #0x0
   14394: e1a00000     	mov	r0, r0
   14398: e51b302c     	ldr	r3, [r11, #-0x2c]
   1439c: e59b2004     	ldr	r2, [r11, #0x4]
   143a0: e0823003     	add	r3, r2, r3
   143a4: e3a02000     	mov	r2, #0
   143a8: e5c32000     	strb	r2, [r3]
   143ac: e51b302c     	ldr	r3, [r11, #-0x2c]
   143b0: e2833001     	add	r3, r3, #1
   143b4: e50b302c     	str	r3, [r11, #-0x2c]
   143b8: e24bd008     	sub	sp, r11, #8
   143bc: e8bd8810     	pop	{r4, r11, pc}
   143c0: 00 29 03 00  	.word	0x00032900
   143c4: e8 28 03 00  	.word	0x000328e8
   143c8: 0c 29 03 00  	.word	0x0003290c
   143cc: 10 29 03 00  	.word	0x00032910
   143d0: 18 29 03 00  	.word	0x00032918
   143d4: ec 28 03 00  	.word	0x000328ec

