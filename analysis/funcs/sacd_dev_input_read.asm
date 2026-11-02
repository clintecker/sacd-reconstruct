00021eb4 <sacd_dev_input_read>:
   21eb4: e92d4830     	push	{r4, r5, r11, lr}
   21eb8: e28db00c     	add	r11, sp, #12
   21ebc: e24dd030     	sub	sp, sp, #48
   21ec0: e50b0028     	str	r0, [r11, #-0x28]
   21ec4: e50b102c     	str	r1, [r11, #-0x2c]
   21ec8: e50b2030     	str	r2, [r11, #-0x30]
   21ecc: e50b3034     	str	r3, [r11, #-0x34]
   21ed0: e51b3028     	ldr	r3, [r11, #-0x28]
   21ed4: e5931000     	ldr	r1, [r3]
   21ed8: e51b302c     	ldr	r3, [r11, #-0x2c]
   21edc: e1a02003     	mov	r2, r3
   21ee0: e1a03fc2     	asr	r3, r2, #31
   21ee4: e1a00aa2     	lsr	r0, r2, #21
   21ee8: e1a05583     	lsl	r5, r3, #11
   21eec: e1805005     	orr	r5, r0, r5
   21ef0: e1a04582     	lsl	r4, r2, #11
   21ef4: e3a03000     	mov	r3, #0
   21ef8: e58d3000     	str	r3, [sp]
   21efc: e1a00001     	mov	r0, r1
   21f00: e1a02004     	mov	r2, r4
   21f04: e1a03005     	mov	r3, r5
   21f08: ebffa9d3     	bl	0xc65c <lseek64@plt>    @ imm = #-0x158b4
   21f0c: e1a02000     	mov	r2, r0
   21f10: e1a03001     	mov	r3, r1
   21f14: e1a03002     	mov	r3, r2
   21f18: e50b3020     	str	r3, [r11, #-0x20]
   21f1c: e51b3020     	ldr	r3, [r11, #-0x20]
   21f20: e3530000     	cmp	r3, #0
   21f24: aa000001     	bge	0x21f30 <sacd_dev_input_read+0x7c> @ imm = #0x4
   21f28: e3a03000     	mov	r3, #0
   21f2c: ea00003a     	b	0x2201c <sacd_dev_input_read+0x168> @ imm = #0xe8
   21f30: e51b3030     	ldr	r3, [r11, #-0x30]
   21f34: e1a03583     	lsl	r3, r3, #11
   21f38: e50b301c     	str	r3, [r11, #-0x1c]
   21f3c: ea000032     	b	0x2200c <sacd_dev_input_read+0x158> @ imm = #0xc8
   21f40: e51b3028     	ldr	r3, [r11, #-0x28]
   21f44: e5932000     	ldr	r2, [r3]
   21f48: e51b301c     	ldr	r3, [r11, #-0x1c]
   21f4c: e1a00002     	mov	r0, r2
   21f50: e51b1034     	ldr	r1, [r11, #-0x34]
   21f54: e1a02003     	mov	r2, r3
   21f58: ebffa932     	bl	0xc428 <read@plt>       @ imm = #-0x15b38
   21f5c: e1a03000     	mov	r3, r0
   21f60: e50b3020     	str	r3, [r11, #-0x20]
   21f64: e51b3020     	ldr	r3, [r11, #-0x20]
   21f68: e3530000     	cmp	r3, #0
   21f6c: aa000001     	bge	0x21f78 <sacd_dev_input_read+0xc4> @ imm = #0x4
   21f70: e51b3020     	ldr	r3, [r11, #-0x20]
   21f74: ea000028     	b	0x2201c <sacd_dev_input_read+0x168> @ imm = #0xa0
   21f78: e51b3020     	ldr	r3, [r11, #-0x20]
   21f7c: e3530000     	cmp	r3, #0
   21f80: 1a00001d     	bne	0x21ffc <sacd_dev_input_read+0x148> @ imm = #0x74
   21f84: e51b3030     	ldr	r3, [r11, #-0x30]
   21f88: e1a02583     	lsl	r2, r3, #11
   21f8c: e51b301c     	ldr	r3, [r11, #-0x1c]
   21f90: e0633002     	rsb	r3, r3, r2
   21f94: e50b3018     	str	r3, [r11, #-0x18]
   21f98: e51b3018     	ldr	r3, [r11, #-0x18]
   21f9c: e1a02fc3     	asr	r2, r3, #31
   21fa0: e1a02aa2     	lsr	r2, r2, #21
   21fa4: e0833002     	add	r3, r3, r2
   21fa8: e1a03a83     	lsl	r3, r3, #21
   21fac: e1a03aa3     	lsr	r3, r3, #21
   21fb0: e0623003     	rsb	r3, r2, r3
   21fb4: e2633000     	rsb	r3, r3, #0
   21fb8: e1a02003     	mov	r2, r3
   21fbc: e1a03fc2     	asr	r3, r2, #31
   21fc0: e14b21f4     	strd	r2, r3, [r11, #-20]
   21fc4: e51b3028     	ldr	r3, [r11, #-0x28]
   21fc8: e5933000     	ldr	r3, [r3]
   21fcc: e3a02001     	mov	r2, #1
   21fd0: e58d2000     	str	r2, [sp]
   21fd4: e1a00003     	mov	r0, r3
   21fd8: e14b21d4     	ldrd	r2, r3, [r11, #-20]
   21fdc: ebffa99e     	bl	0xc65c <lseek64@plt>    @ imm = #-0x15988
   21fe0: e51b3018     	ldr	r3, [r11, #-0x18]
   21fe4: e2832e7f     	add	r2, r3, #2032
   21fe8: e282200f     	add	r2, r2, #15
   21fec: e3530000     	cmp	r3, #0
   21ff0: b1a03002     	movlt	r3, r2
   21ff4: e1a035c3     	asr	r3, r3, #11
   21ff8: ea000007     	b	0x2201c <sacd_dev_input_read+0x168> @ imm = #0x1c
   21ffc: e51b201c     	ldr	r2, [r11, #-0x1c]
   22000: e51b3020     	ldr	r3, [r11, #-0x20]
   22004: e0633002     	rsb	r3, r3, r2
   22008: e50b301c     	str	r3, [r11, #-0x1c]
   2200c: e51b301c     	ldr	r3, [r11, #-0x1c]
   22010: e3530000     	cmp	r3, #0
   22014: caffffc9     	bgt	0x21f40 <sacd_dev_input_read+0x8c> @ imm = #-0xdc
   22018: e51b3030     	ldr	r3, [r11, #-0x30]
   2201c: e1a00003     	mov	r0, r3
   22020: e24bd00c     	sub	sp, r11, #12
   22024: e8bd8830     	pop	{r4, r5, r11, pc}

