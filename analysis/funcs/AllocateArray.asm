00019ef8 <AllocateArray>:
   19ef8: e92d000e     	push	{r1, r2, r3}
   19efc: e92d4810     	push	{r4, r11, lr}
   19f00: e28db008     	add	r11, sp, #8
   19f04: e24dd028     	sub	sp, sp, #40
   19f08: e50b002c     	str	r0, [r11, #-0x2c]
   19f0c: e51b002c     	ldr	r0, [r11, #-0x2c]
   19f10: e3a01004     	mov	r1, #4
   19f14: ebffffd2     	bl	0x19e64 <MemoryAllocate> @ imm = #-0xb8
   19f18: e1a03000     	mov	r3, r0
   19f1c: e50b300c     	str	r3, [r11, #-0xc]
   19f20: e28b3008     	add	r3, r11, #8
   19f24: e50b3024     	str	r3, [r11, #-0x24]
   19f28: e3a03000     	mov	r3, #0
   19f2c: e50b3018     	str	r3, [r11, #-0x18]
   19f30: ea00000b     	b	0x19f64 <AllocateArray+0x6c> @ imm = #0x2c
   19f34: e51b3018     	ldr	r3, [r11, #-0x18]
   19f38: e1a03103     	lsl	r3, r3, #2
   19f3c: e51b200c     	ldr	r2, [r11, #-0xc]
   19f40: e0822003     	add	r2, r2, r3
   19f44: e51b3024     	ldr	r3, [r11, #-0x24]
   19f48: e2831004     	add	r1, r3, #4
   19f4c: e50b1024     	str	r1, [r11, #-0x24]
   19f50: e5933000     	ldr	r3, [r3]
   19f54: e5823000     	str	r3, [r2]
   19f58: e51b3018     	ldr	r3, [r11, #-0x18]
   19f5c: e2833001     	add	r3, r3, #1
   19f60: e50b3018     	str	r3, [r11, #-0x18]
   19f64: e51b2018     	ldr	r2, [r11, #-0x18]
   19f68: e51b302c     	ldr	r3, [r11, #-0x2c]
   19f6c: e1520003     	cmp	r2, r3
   19f70: baffffef     	blt	0x19f34 <AllocateArray+0x3c> @ imm = #-0x44
   19f74: e51b002c     	ldr	r0, [r11, #-0x2c]
   19f78: e3a01004     	mov	r1, #4
   19f7c: ebffffb8     	bl	0x19e64 <MemoryAllocate> @ imm = #-0x120
   19f80: e1a03000     	mov	r3, r0
   19f84: e50b3020     	str	r3, [r11, #-0x20]
   19f88: e3a03001     	mov	r3, #1
   19f8c: e50b3010     	str	r3, [r11, #-0x10]
   19f90: e3a03000     	mov	r3, #0
   19f94: e50b3018     	str	r3, [r11, #-0x18]
   19f98: ea000013     	b	0x19fec <AllocateArray+0xf4> @ imm = #0x4c
   19f9c: e51b3018     	ldr	r3, [r11, #-0x18]
   19fa0: e1a03103     	lsl	r3, r3, #2
   19fa4: e51b200c     	ldr	r2, [r11, #-0xc]
   19fa8: e0823003     	add	r3, r2, r3
   19fac: e5932000     	ldr	r2, [r3]
   19fb0: e51b3010     	ldr	r3, [r11, #-0x10]
   19fb4: e0030392     	mul	r3, r2, r3
   19fb8: e50b3010     	str	r3, [r11, #-0x10]
   19fbc: e51b3018     	ldr	r3, [r11, #-0x18]
   19fc0: e1a03103     	lsl	r3, r3, #2
   19fc4: e51b2020     	ldr	r2, [r11, #-0x20]
   19fc8: e0824003     	add	r4, r2, r3
   19fcc: e51b0010     	ldr	r0, [r11, #-0x10]
   19fd0: e3a01004     	mov	r1, #4
   19fd4: ebffffa2     	bl	0x19e64 <MemoryAllocate> @ imm = #-0x178
   19fd8: e1a03000     	mov	r3, r0
   19fdc: e5843000     	str	r3, [r4]
   19fe0: e51b3018     	ldr	r3, [r11, #-0x18]
   19fe4: e2833001     	add	r3, r3, #1
   19fe8: e50b3018     	str	r3, [r11, #-0x18]
   19fec: e51b302c     	ldr	r3, [r11, #-0x2c]
   19ff0: e2432001     	sub	r2, r3, #1
   19ff4: e51b3018     	ldr	r3, [r11, #-0x18]
   19ff8: e1520003     	cmp	r2, r3
   19ffc: caffffe6     	bgt	0x19f9c <AllocateArray+0xa4> @ imm = #-0x68
   1a000: e51b3018     	ldr	r3, [r11, #-0x18]
   1a004: e1a03103     	lsl	r3, r3, #2
   1a008: e51b200c     	ldr	r2, [r11, #-0xc]
   1a00c: e0823003     	add	r3, r2, r3
   1a010: e5932000     	ldr	r2, [r3]
   1a014: e51b3010     	ldr	r3, [r11, #-0x10]
   1a018: e0030392     	mul	r3, r2, r3
   1a01c: e50b3010     	str	r3, [r11, #-0x10]
   1a020: e51b3018     	ldr	r3, [r11, #-0x18]
   1a024: e1a03103     	lsl	r3, r3, #2
   1a028: e51b2020     	ldr	r2, [r11, #-0x20]
   1a02c: e0824003     	add	r4, r2, r3
   1a030: e51b0010     	ldr	r0, [r11, #-0x10]
   1a034: e59b1004     	ldr	r1, [r11, #0x4]
   1a038: ebffff89     	bl	0x19e64 <MemoryAllocate> @ imm = #-0x1dc
   1a03c: e1a03000     	mov	r3, r0
   1a040: e5843000     	str	r3, [r4]
   1a044: e3a03001     	mov	r3, #1
   1a048: e50b3010     	str	r3, [r11, #-0x10]
   1a04c: e3a03000     	mov	r3, #0
   1a050: e50b3018     	str	r3, [r11, #-0x18]
   1a054: ea00002e     	b	0x1a114 <AllocateArray+0x21c> @ imm = #0xb8
   1a058: e51b3018     	ldr	r3, [r11, #-0x18]
   1a05c: e1a03103     	lsl	r3, r3, #2
   1a060: e51b200c     	ldr	r2, [r11, #-0xc]
   1a064: e0823003     	add	r3, r2, r3
   1a068: e5932000     	ldr	r2, [r3]
   1a06c: e51b3010     	ldr	r3, [r11, #-0x10]
   1a070: e0030392     	mul	r3, r2, r3
   1a074: e50b3010     	str	r3, [r11, #-0x10]
   1a078: e3a03000     	mov	r3, #0
   1a07c: e50b3014     	str	r3, [r11, #-0x14]
   1a080: ea00001c     	b	0x1a0f8 <AllocateArray+0x200> @ imm = #0x70
   1a084: e51b3018     	ldr	r3, [r11, #-0x18]
   1a088: e1a03103     	lsl	r3, r3, #2
   1a08c: e51b2020     	ldr	r2, [r11, #-0x20]
   1a090: e0823003     	add	r3, r2, r3
   1a094: e5932000     	ldr	r2, [r3]
   1a098: e51b3014     	ldr	r3, [r11, #-0x14]
   1a09c: e1a03103     	lsl	r3, r3, #2
   1a0a0: e0823003     	add	r3, r2, r3
   1a0a4: e51b2018     	ldr	r2, [r11, #-0x18]
   1a0a8: e2822001     	add	r2, r2, #1
   1a0ac: e1a02102     	lsl	r2, r2, #2
   1a0b0: e51b1020     	ldr	r1, [r11, #-0x20]
   1a0b4: e0812002     	add	r2, r1, r2
   1a0b8: e5921000     	ldr	r1, [r2]
   1a0bc: e51b2018     	ldr	r2, [r11, #-0x18]
   1a0c0: e2822001     	add	r2, r2, #1
   1a0c4: e1a02102     	lsl	r2, r2, #2
   1a0c8: e51b000c     	ldr	r0, [r11, #-0xc]
   1a0cc: e0802002     	add	r2, r0, r2
   1a0d0: e5922000     	ldr	r2, [r2]
   1a0d4: e51b0014     	ldr	r0, [r11, #-0x14]
   1a0d8: e0020290     	mul	r2, r0, r2
   1a0dc: e59b0004     	ldr	r0, [r11, #0x4]
   1a0e0: e0020290     	mul	r2, r0, r2
   1a0e4: e0812002     	add	r2, r1, r2
   1a0e8: e5832000     	str	r2, [r3]
   1a0ec: e51b3014     	ldr	r3, [r11, #-0x14]
   1a0f0: e2833001     	add	r3, r3, #1
   1a0f4: e50b3014     	str	r3, [r11, #-0x14]
   1a0f8: e51b2014     	ldr	r2, [r11, #-0x14]
   1a0fc: e51b3010     	ldr	r3, [r11, #-0x10]
   1a100: e1520003     	cmp	r2, r3
   1a104: baffffde     	blt	0x1a084 <AllocateArray+0x18c> @ imm = #-0x88
   1a108: e51b3018     	ldr	r3, [r11, #-0x18]
   1a10c: e2833001     	add	r3, r3, #1
   1a110: e50b3018     	str	r3, [r11, #-0x18]
   1a114: e51b302c     	ldr	r3, [r11, #-0x2c]
   1a118: e2432001     	sub	r2, r3, #1
   1a11c: e51b3018     	ldr	r3, [r11, #-0x18]
   1a120: e1520003     	cmp	r2, r3
   1a124: caffffcb     	bgt	0x1a058 <AllocateArray+0x160> @ imm = #-0xd4
   1a128: e51b3020     	ldr	r3, [r11, #-0x20]
   1a12c: e5933000     	ldr	r3, [r3]
   1a130: e50b301c     	str	r3, [r11, #-0x1c]
   1a134: e51b0020     	ldr	r0, [r11, #-0x20]
   1a138: ebffff66     	bl	0x19ed8 <MemoryFree>    @ imm = #-0x268
   1a13c: e51b000c     	ldr	r0, [r11, #-0xc]
   1a140: ebffff64     	bl	0x19ed8 <MemoryFree>    @ imm = #-0x270
   1a144: e51b301c     	ldr	r3, [r11, #-0x1c]
   1a148: e1a00003     	mov	r0, r3
   1a14c: e24bd008     	sub	sp, r11, #8
   1a150: e8bd4810     	pop	{r4, r11, lr}
   1a154: e28dd00c     	add	sp, sp, #12
   1a158: e12fff1e     	bx	lr

