0001bae8 <getbits>:
   1bae8: e52db004     	str	r11, [sp, #-0x4]!
   1baec: e28db000     	add	r11, sp, #0
   1baf0: e24dd024     	sub	sp, sp, #36
   1baf4: e50b0018     	str	r0, [r11, #-0x18]
   1baf8: e50b101c     	str	r1, [r11, #-0x1c]
   1bafc: e50b2020     	str	r2, [r11, #-0x20]
   1bb00: e51b3020     	ldr	r3, [r11, #-0x20]
   1bb04: e3530001     	cmp	r3, #1
   1bb08: 1a00002a     	bne	0x1bbb8 <getbits+0xd0>  @ imm = #0xa8
   1bb0c: e51b3018     	ldr	r3, [r11, #-0x18]
   1bb10: e593300c     	ldr	r3, [r3, #0xc]
   1bb14: e3530000     	cmp	r3, #0
   1bb18: 1a000016     	bne	0x1bb78 <getbits+0x90>  @ imm = #0x58
   1bb1c: e51b3018     	ldr	r3, [r11, #-0x18]
   1bb20: e5931000     	ldr	r1, [r3]
   1bb24: e51b3018     	ldr	r3, [r11, #-0x18]
   1bb28: e5933008     	ldr	r3, [r3, #0x8]
   1bb2c: e1a02003     	mov	r2, r3
   1bb30: e0812002     	add	r2, r1, r2
   1bb34: e5d21000     	ldrb	r1, [r2]
   1bb38: e51b2018     	ldr	r2, [r11, #-0x18]
   1bb3c: e5c21010     	strb	r1, [r2, #0x10]
   1bb40: e2832001     	add	r2, r3, #1
   1bb44: e51b3018     	ldr	r3, [r11, #-0x18]
   1bb48: e5832008     	str	r2, [r3, #0x8]
   1bb4c: e51b3018     	ldr	r3, [r11, #-0x18]
   1bb50: e5932008     	ldr	r2, [r3, #0x8]
   1bb54: e51b3018     	ldr	r3, [r11, #-0x18]
   1bb58: e5933004     	ldr	r3, [r3, #0x4]
   1bb5c: e1520003     	cmp	r2, r3
   1bb60: da000001     	ble	0x1bb6c <getbits+0x84>  @ imm = #0x4
   1bb64: e3e03000     	mvn	r3, #0
   1bb68: ea000074     	b	0x1bd40 <getbits+0x258> @ imm = #0x1d0
   1bb6c: e51b3018     	ldr	r3, [r11, #-0x18]
   1bb70: e3a02008     	mov	r2, #8
   1bb74: e583200c     	str	r2, [r3, #0xc]
   1bb78: e51b3018     	ldr	r3, [r11, #-0x18]
   1bb7c: e593300c     	ldr	r3, [r3, #0xc]
   1bb80: e2432001     	sub	r2, r3, #1
   1bb84: e51b3018     	ldr	r3, [r11, #-0x18]
   1bb88: e583200c     	str	r2, [r3, #0xc]
   1bb8c: e51b3018     	ldr	r3, [r11, #-0x18]
   1bb90: e5d33010     	ldrb	r3, [r3, #0x10]
   1bb94: e1a02003     	mov	r2, r3
   1bb98: e51b3018     	ldr	r3, [r11, #-0x18]
   1bb9c: e593300c     	ldr	r3, [r3, #0xc]
   1bba0: e1a03352     	asr	r3, r2, r3
   1bba4: e2032001     	and	r2, r3, #1
   1bba8: e51b301c     	ldr	r3, [r11, #-0x1c]
   1bbac: e5832000     	str	r2, [r3]
   1bbb0: e3a03000     	mov	r3, #0
   1bbb4: ea000061     	b	0x1bd40 <getbits+0x258> @ imm = #0x184
   1bbb8: e51b301c     	ldr	r3, [r11, #-0x1c]
   1bbbc: e3a02000     	mov	r2, #0
   1bbc0: e5832000     	str	r2, [r3]
   1bbc4: ea000059     	b	0x1bd30 <getbits+0x248> @ imm = #0x164
   1bbc8: e51b3018     	ldr	r3, [r11, #-0x18]
   1bbcc: e593300c     	ldr	r3, [r3, #0xc]
   1bbd0: e3530000     	cmp	r3, #0
   1bbd4: 1a000016     	bne	0x1bc34 <getbits+0x14c> @ imm = #0x58
   1bbd8: e51b3018     	ldr	r3, [r11, #-0x18]
   1bbdc: e5931000     	ldr	r1, [r3]
   1bbe0: e51b3018     	ldr	r3, [r11, #-0x18]
   1bbe4: e5933008     	ldr	r3, [r3, #0x8]
   1bbe8: e1a02003     	mov	r2, r3
   1bbec: e0812002     	add	r2, r1, r2
   1bbf0: e5d21000     	ldrb	r1, [r2]
   1bbf4: e51b2018     	ldr	r2, [r11, #-0x18]
   1bbf8: e5c21010     	strb	r1, [r2, #0x10]
   1bbfc: e2832001     	add	r2, r3, #1
   1bc00: e51b3018     	ldr	r3, [r11, #-0x18]
   1bc04: e5832008     	str	r2, [r3, #0x8]
   1bc08: e51b3018     	ldr	r3, [r11, #-0x18]
   1bc0c: e5932008     	ldr	r2, [r3, #0x8]
   1bc10: e51b3018     	ldr	r3, [r11, #-0x18]
   1bc14: e5933004     	ldr	r3, [r3, #0x4]
   1bc18: e1520003     	cmp	r2, r3
   1bc1c: da000001     	ble	0x1bc28 <getbits+0x140> @ imm = #0x4
   1bc20: e3e03000     	mvn	r3, #0
   1bc24: ea000045     	b	0x1bd40 <getbits+0x258> @ imm = #0x114
   1bc28: e51b3018     	ldr	r3, [r11, #-0x18]
   1bc2c: e3a02008     	mov	r2, #8
   1bc30: e583200c     	str	r2, [r3, #0xc]
   1bc34: e51b3018     	ldr	r3, [r11, #-0x18]
   1bc38: e593200c     	ldr	r2, [r3, #0xc]
   1bc3c: e51b3020     	ldr	r3, [r11, #-0x20]
   1bc40: e1520003     	cmp	r2, r3
   1bc44: b1a03002     	movlt	r3, r2
   1bc48: a1a03003     	movge	r3, r3
   1bc4c: e50b3010     	str	r3, [r11, #-0x10]
   1bc50: e51b3018     	ldr	r3, [r11, #-0x18]
   1bc54: e593200c     	ldr	r2, [r3, #0xc]
   1bc58: e51b3010     	ldr	r3, [r11, #-0x10]
   1bc5c: e0633002     	rsb	r3, r3, r2
   1bc60: e50b3008     	str	r3, [r11, #-0x8]
   1bc64: e51b2010     	ldr	r2, [r11, #-0x10]
   1bc68: e59f30e0     	ldr	r3, [pc, #0xe0]         @ 0x1bd50 <getbits+0x268>
   1bc6c: e7932102     	ldr	r2, [r3, r2, lsl #2]
   1bc70: e51b3008     	ldr	r3, [r11, #-0x8]
   1bc74: e1a03312     	lsl	r3, r2, r3
   1bc78: e50b300c     	str	r3, [r11, #-0xc]
   1bc7c: e51b2020     	ldr	r2, [r11, #-0x20]
   1bc80: e51b3010     	ldr	r3, [r11, #-0x10]
   1bc84: e0632002     	rsb	r2, r3, r2
   1bc88: e51b3008     	ldr	r3, [r11, #-0x8]
   1bc8c: e0633002     	rsb	r3, r3, r2
   1bc90: e50b3008     	str	r3, [r11, #-0x8]
   1bc94: e51b3008     	ldr	r3, [r11, #-0x8]
   1bc98: e3530000     	cmp	r3, #0
   1bc9c: ca00000d     	bgt	0x1bcd8 <getbits+0x1f0> @ imm = #0x34
   1bca0: e51b301c     	ldr	r3, [r11, #-0x1c]
   1bca4: e5932000     	ldr	r2, [r3]
   1bca8: e51b3018     	ldr	r3, [r11, #-0x18]
   1bcac: e5d33010     	ldrb	r3, [r3, #0x10]
   1bcb0: e1a01003     	mov	r1, r3
   1bcb4: e51b300c     	ldr	r3, [r11, #-0xc]
   1bcb8: e0011003     	and	r1, r1, r3
   1bcbc: e51b3008     	ldr	r3, [r11, #-0x8]
   1bcc0: e2633000     	rsb	r3, r3, #0
   1bcc4: e1a03351     	asr	r3, r1, r3
   1bcc8: e1822003     	orr	r2, r2, r3
   1bccc: e51b301c     	ldr	r3, [r11, #-0x1c]
   1bcd0: e5832000     	str	r2, [r3]
   1bcd4: ea00000b     	b	0x1bd08 <getbits+0x220> @ imm = #0x2c
   1bcd8: e51b301c     	ldr	r3, [r11, #-0x1c]
   1bcdc: e5932000     	ldr	r2, [r3]
   1bce0: e51b3018     	ldr	r3, [r11, #-0x18]
   1bce4: e5d33010     	ldrb	r3, [r3, #0x10]
   1bce8: e1a01003     	mov	r1, r3
   1bcec: e51b300c     	ldr	r3, [r11, #-0xc]
   1bcf0: e0011003     	and	r1, r1, r3
   1bcf4: e51b3008     	ldr	r3, [r11, #-0x8]
   1bcf8: e1a03311     	lsl	r3, r1, r3
   1bcfc: e1822003     	orr	r2, r2, r3
   1bd00: e51b301c     	ldr	r3, [r11, #-0x1c]
   1bd04: e5832000     	str	r2, [r3]
   1bd08: e51b2020     	ldr	r2, [r11, #-0x20]
   1bd0c: e51b3010     	ldr	r3, [r11, #-0x10]
   1bd10: e0633002     	rsb	r3, r3, r2
   1bd14: e50b3020     	str	r3, [r11, #-0x20]
   1bd18: e51b3018     	ldr	r3, [r11, #-0x18]
   1bd1c: e593200c     	ldr	r2, [r3, #0xc]
   1bd20: e51b3010     	ldr	r3, [r11, #-0x10]
   1bd24: e0632002     	rsb	r2, r3, r2
   1bd28: e51b3018     	ldr	r3, [r11, #-0x18]
   1bd2c: e583200c     	str	r2, [r3, #0xc]
   1bd30: e51b3020     	ldr	r3, [r11, #-0x20]
   1bd34: e3530000     	cmp	r3, #0
   1bd38: caffffa2     	bgt	0x1bbc8 <getbits+0xe0>  @ imm = #-0x178
   1bd3c: e3a03000     	mov	r3, #0
   1bd40: e1a00003     	mov	r0, r3
   1bd44: e28bd000     	add	sp, r11, #0
   1bd48: e8bd0800     	ldm	sp!, {r11}
   1bd4c: e12fff1e     	bx	lr
   1bd50: 1c e8 03 00  	.word	0x0003e81c

