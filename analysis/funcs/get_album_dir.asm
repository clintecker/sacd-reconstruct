00028e64 <get_album_dir>:
   28e64: e92d4800     	push	{r11, lr}
   28e68: e28db004     	add	r11, sp, #4
   28e6c: e24dd0a8     	sub	sp, sp, #168
   28e70: e50b00a0     	str	r0, [r11, #-0xa0]
   28e74: e51b30a0     	ldr	r3, [r11, #-0xa0]
   28e78: e2833010     	add	r3, r3, #16
   28e7c: e50b3018     	str	r3, [r11, #-0x18]
   28e80: e3a03000     	mov	r3, #0
   28e84: e50b3014     	str	r3, [r11, #-0x14]
   28e88: e3a03000     	mov	r3, #0
   28e8c: e50b3010     	str	r3, [r11, #-0x10]
   28e90: e51b3018     	ldr	r3, [r11, #-0x18]
   28e94: e5933008     	ldr	r3, [r3, #0x8]
   28e98: e3530000     	cmp	r3, #0
   28e9c: 0a000003     	beq	0x28eb0 <get_album_dir+0x4c> @ imm = #0xc
   28ea0: e51b3018     	ldr	r3, [r11, #-0x18]
   28ea4: e5933008     	ldr	r3, [r3, #0x8]
   28ea8: e50b3014     	str	r3, [r11, #-0x14]
   28eac: ea000016     	b	0x28f0c <get_album_dir+0xa8> @ imm = #0x58
   28eb0: e51b3018     	ldr	r3, [r11, #-0x18]
   28eb4: e593300c     	ldr	r3, [r3, #0xc]
   28eb8: e3530000     	cmp	r3, #0
   28ebc: 0a000003     	beq	0x28ed0 <get_album_dir+0x6c> @ imm = #0xc
   28ec0: e51b3018     	ldr	r3, [r11, #-0x18]
   28ec4: e593300c     	ldr	r3, [r3, #0xc]
   28ec8: e50b3014     	str	r3, [r11, #-0x14]
   28ecc: ea00000e     	b	0x28f0c <get_album_dir+0xa8> @ imm = #0x38
   28ed0: e51b3018     	ldr	r3, [r11, #-0x18]
   28ed4: e5933028     	ldr	r3, [r3, #0x28]
   28ed8: e3530000     	cmp	r3, #0
   28edc: 0a000003     	beq	0x28ef0 <get_album_dir+0x8c> @ imm = #0xc
   28ee0: e51b3018     	ldr	r3, [r11, #-0x18]
   28ee4: e5933028     	ldr	r3, [r3, #0x28]
   28ee8: e50b3014     	str	r3, [r11, #-0x14]
   28eec: ea000006     	b	0x28f0c <get_album_dir+0xa8> @ imm = #0x18
   28ef0: e51b3018     	ldr	r3, [r11, #-0x18]
   28ef4: e593302c     	ldr	r3, [r3, #0x2c]
   28ef8: e3530000     	cmp	r3, #0
   28efc: 0a000002     	beq	0x28f0c <get_album_dir+0xa8> @ imm = #0x8
   28f00: e51b3018     	ldr	r3, [r11, #-0x18]
   28f04: e593302c     	ldr	r3, [r3, #0x2c]
   28f08: e50b3014     	str	r3, [r11, #-0x14]
   28f0c: e51b3018     	ldr	r3, [r11, #-0x18]
   28f10: e5933000     	ldr	r3, [r3]
   28f14: e3530000     	cmp	r3, #0
   28f18: 0a000003     	beq	0x28f2c <get_album_dir+0xc8> @ imm = #0xc
   28f1c: e51b3018     	ldr	r3, [r11, #-0x18]
   28f20: e5933000     	ldr	r3, [r3]
   28f24: e50b3010     	str	r3, [r11, #-0x10]
   28f28: ea000016     	b	0x28f88 <get_album_dir+0x124> @ imm = #0x58
   28f2c: e51b3018     	ldr	r3, [r11, #-0x18]
   28f30: e5933004     	ldr	r3, [r3, #0x4]
   28f34: e3530000     	cmp	r3, #0
   28f38: 0a000003     	beq	0x28f4c <get_album_dir+0xe8> @ imm = #0xc
   28f3c: e51b3018     	ldr	r3, [r11, #-0x18]
   28f40: e5933004     	ldr	r3, [r3, #0x4]
   28f44: e50b3010     	str	r3, [r11, #-0x10]
   28f48: ea00000e     	b	0x28f88 <get_album_dir+0x124> @ imm = #0x38
   28f4c: e51b3018     	ldr	r3, [r11, #-0x18]
   28f50: e5933020     	ldr	r3, [r3, #0x20]
   28f54: e3530000     	cmp	r3, #0
   28f58: 0a000003     	beq	0x28f6c <get_album_dir+0x108> @ imm = #0xc
   28f5c: e51b3018     	ldr	r3, [r11, #-0x18]
   28f60: e5933020     	ldr	r3, [r3, #0x20]
   28f64: e50b3010     	str	r3, [r11, #-0x10]
   28f68: ea000006     	b	0x28f88 <get_album_dir+0x124> @ imm = #0x18
   28f6c: e51b3018     	ldr	r3, [r11, #-0x18]
   28f70: e5933024     	ldr	r3, [r3, #0x24]
   28f74: e3530000     	cmp	r3, #0
   28f78: 0a000002     	beq	0x28f88 <get_album_dir+0x124> @ imm = #0x8
   28f7c: e51b3018     	ldr	r3, [r11, #-0x18]
   28f80: e5933024     	ldr	r3, [r3, #0x24]
   28f84: e50b3010     	str	r3, [r11, #-0x10]
   28f88: e24b3058     	sub	r3, r11, #88
   28f8c: e1a00003     	mov	r0, r3
   28f90: e3a01000     	mov	r1, #0
   28f94: e3a0203c     	mov	r2, #60
   28f98: ebff8d01     	bl	0xc3a4 <memset@plt>     @ imm = #-0x1cbfc
   28f9c: e51b3014     	ldr	r3, [r11, #-0x14]
   28fa0: e3530000     	cmp	r3, #0
   28fa4: 0a000018     	beq	0x2900c <get_album_dir+0x1a8> @ imm = #0x60
   28fa8: e51b0014     	ldr	r0, [r11, #-0x14]
   28fac: e3a0103b     	mov	r1, #59
   28fb0: ebff8cdd     	bl	0xc32c <strchr@plt>     @ imm = #-0x1cc8c
   28fb4: e1a03000     	mov	r3, r0
   28fb8: e50b300c     	str	r3, [r11, #-0xc]
   28fbc: e51b300c     	ldr	r3, [r11, #-0xc]
   28fc0: e3530000     	cmp	r3, #0
   28fc4: 1a000005     	bne	0x28fe0 <get_album_dir+0x17c> @ imm = #0x14
   28fc8: e51b0014     	ldr	r0, [r11, #-0x14]
   28fcc: ebff8d42     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1caf8
   28fd0: e1a03000     	mov	r3, r0
   28fd4: e51b2014     	ldr	r2, [r11, #-0x14]
   28fd8: e0823003     	add	r3, r2, r3
   28fdc: e50b300c     	str	r3, [r11, #-0xc]
   28fe0: e51b2014     	ldr	r2, [r11, #-0x14]
   28fe4: e51b100c     	ldr	r1, [r11, #-0xc]
   28fe8: e51b3014     	ldr	r3, [r11, #-0x14]
   28fec: e0633001     	rsb	r3, r3, r1
   28ff0: e353003b     	cmp	r3, #59
   28ff4: a3a0303b     	movge	r3, #59
   28ff8: e24b1058     	sub	r1, r11, #88
   28ffc: e1a00001     	mov	r0, r1
   29000: e1a01002     	mov	r1, r2
   29004: e1a02003     	mov	r2, r3
   29008: ebff8cb2     	bl	0xc2d8 <strncpy@plt>    @ imm = #-0x1cd38
   2900c: e24b3094     	sub	r3, r11, #148
   29010: e1a00003     	mov	r0, r3
   29014: e3a01000     	mov	r1, #0
   29018: e3a0203c     	mov	r2, #60
   2901c: ebff8ce0     	bl	0xc3a4 <memset@plt>     @ imm = #-0x1cc80
   29020: e51b3010     	ldr	r3, [r11, #-0x10]
   29024: e3530000     	cmp	r3, #0
   29028: 0a000018     	beq	0x29090 <get_album_dir+0x22c> @ imm = #0x60
   2902c: e51b0010     	ldr	r0, [r11, #-0x10]
   29030: e3a0103b     	mov	r1, #59
   29034: ebff8cbc     	bl	0xc32c <strchr@plt>     @ imm = #-0x1cd10
   29038: e1a03000     	mov	r3, r0
   2903c: e50b3008     	str	r3, [r11, #-0x8]
   29040: e51b3008     	ldr	r3, [r11, #-0x8]
   29044: e3530000     	cmp	r3, #0
   29048: 1a000005     	bne	0x29064 <get_album_dir+0x200> @ imm = #0x14
   2904c: e51b0010     	ldr	r0, [r11, #-0x10]
   29050: ebff8d21     	bl	0xc4dc <strlen@plt>     @ imm = #-0x1cb7c
   29054: e1a03000     	mov	r3, r0
   29058: e51b2010     	ldr	r2, [r11, #-0x10]
   2905c: e0823003     	add	r3, r2, r3
   29060: e50b3008     	str	r3, [r11, #-0x8]
   29064: e51b2010     	ldr	r2, [r11, #-0x10]
   29068: e51b1008     	ldr	r1, [r11, #-0x8]
   2906c: e51b3010     	ldr	r3, [r11, #-0x10]
   29070: e0633001     	rsb	r3, r3, r1
   29074: e353003b     	cmp	r3, #59
   29078: a3a0303b     	movge	r3, #59
   2907c: e24b1094     	sub	r1, r11, #148
   29080: e1a00001     	mov	r0, r1
   29084: e1a01002     	mov	r1, r2
   29088: e1a02003     	mov	r2, r3
   2908c: ebff8c91     	bl	0xc2d8 <strncpy@plt>    @ imm = #-0x1cdbc
   29090: e59f2154     	ldr	r2, [pc, #0x154]        @ 0x291ec <get_album_dir+0x388>
   29094: e51b30a0     	ldr	r3, [r11, #-0xa0]
   29098: e5933008     	ldr	r3, [r3, #0x8]
   2909c: e5d31078     	ldrb	r1, [r3, #0x78]
   290a0: e5d33079     	ldrb	r3, [r3, #0x79]
   290a4: e1a03403     	lsl	r3, r3, #8
   290a8: e1833001     	orr	r3, r3, r1
   290ac: e6ff3073     	uxth	r3, r3
   290b0: e24b109c     	sub	r1, r11, #156
   290b4: e1a00001     	mov	r0, r1
   290b8: e3a01005     	mov	r1, #5
   290bc: ebff8d9f     	bl	0xc740 <snprintf@plt>   @ imm = #-0x1c984
   290c0: e24b3058     	sub	r3, r11, #88
   290c4: e1a00003     	mov	r0, r3
   290c8: ebffa0a4     	bl	0x11360 <sanitize_filename> @ imm = #-0x17d70
   290cc: e24b3094     	sub	r3, r11, #148
   290d0: e1a00003     	mov	r0, r3
   290d4: ebffa0a1     	bl	0x11360 <sanitize_filename> @ imm = #-0x17d7c
   290d8: e24b3058     	sub	r3, r11, #88
   290dc: e5d33000     	ldrb	r3, [r3]
   290e0: e3530000     	cmp	r3, #0
   290e4: 0a00000f     	beq	0x29128 <get_album_dir+0x2c4> @ imm = #0x3c
   290e8: e24b3094     	sub	r3, r11, #148
   290ec: e5d33000     	ldrb	r3, [r3]
   290f0: e3530000     	cmp	r3, #0
   290f4: 0a00000b     	beq	0x29128 <get_album_dir+0x2c4> @ imm = #0x2c
   290f8: e24b209c     	sub	r2, r11, #156
   290fc: e24b3058     	sub	r3, r11, #88
   29100: e24b1094     	sub	r1, r11, #148
   29104: e58d1000     	str	r1, [sp]
   29108: e3a01000     	mov	r1, #0
   2910c: e58d1004     	str	r1, [sp, #0x4]
   29110: e59f00d8     	ldr	r0, [pc, #0xd8]         @ 0x291f0 <get_album_dir+0x38c>
   29114: e3a01000     	mov	r1, #0
   29118: ebff9d7e     	bl	0x10718 <parse_format>  @ imm = #-0x18a08
   2911c: e1a03000     	mov	r3, r0
   29120: e50b301c     	str	r3, [r11, #-0x1c]
   29124: ea00002a     	b	0x291d4 <get_album_dir+0x370> @ imm = #0xa8
   29128: e24b3058     	sub	r3, r11, #88
   2912c: e5d33000     	ldrb	r3, [r3]
   29130: e3530000     	cmp	r3, #0
   29134: 0a00000b     	beq	0x29168 <get_album_dir+0x304> @ imm = #0x2c
   29138: e24b209c     	sub	r2, r11, #156
   2913c: e24b3058     	sub	r3, r11, #88
   29140: e24b1094     	sub	r1, r11, #148
   29144: e58d1000     	str	r1, [sp]
   29148: e3a01000     	mov	r1, #0
   2914c: e58d1004     	str	r1, [sp, #0x4]
   29150: e59f009c     	ldr	r0, [pc, #0x9c]         @ 0x291f4 <get_album_dir+0x390>
   29154: e3a01000     	mov	r1, #0
   29158: ebff9d6e     	bl	0x10718 <parse_format>  @ imm = #-0x18a48
   2915c: e1a03000     	mov	r3, r0
   29160: e50b301c     	str	r3, [r11, #-0x1c]
   29164: ea00001a     	b	0x291d4 <get_album_dir+0x370> @ imm = #0x68
   29168: e24b3094     	sub	r3, r11, #148
   2916c: e5d33000     	ldrb	r3, [r3]
   29170: e3530000     	cmp	r3, #0
   29174: 0a00000b     	beq	0x291a8 <get_album_dir+0x344> @ imm = #0x2c
   29178: e24b209c     	sub	r2, r11, #156
   2917c: e24b3058     	sub	r3, r11, #88
   29180: e24b1094     	sub	r1, r11, #148
   29184: e58d1000     	str	r1, [sp]
   29188: e3a01000     	mov	r1, #0
   2918c: e58d1004     	str	r1, [sp, #0x4]
   29190: e59f0060     	ldr	r0, [pc, #0x60]         @ 0x291f8 <get_album_dir+0x394>
   29194: e3a01000     	mov	r1, #0
   29198: ebff9d5e     	bl	0x10718 <parse_format>  @ imm = #-0x18a88
   2919c: e1a03000     	mov	r3, r0
   291a0: e50b301c     	str	r3, [r11, #-0x1c]
   291a4: ea00000a     	b	0x291d4 <get_album_dir+0x370> @ imm = #0x28
   291a8: e24b209c     	sub	r2, r11, #156
   291ac: e24b3058     	sub	r3, r11, #88
   291b0: e24b1094     	sub	r1, r11, #148
   291b4: e58d1000     	str	r1, [sp]
   291b8: e3a01000     	mov	r1, #0
   291bc: e58d1004     	str	r1, [sp, #0x4]
   291c0: e59f0034     	ldr	r0, [pc, #0x34]         @ 0x291fc <get_album_dir+0x398>
   291c4: e3a01000     	mov	r1, #0
   291c8: ebff9d52     	bl	0x10718 <parse_format>  @ imm = #-0x18ab8
   291cc: e1a03000     	mov	r3, r0
   291d0: e50b301c     	str	r3, [r11, #-0x1c]
   291d4: e51b001c     	ldr	r0, [r11, #-0x1c]
   291d8: ebffa0c7     	bl	0x114fc <sanitize_filepath> @ imm = #-0x17ce4
   291dc: e51b301c     	ldr	r3, [r11, #-0x1c]
   291e0: e1a00003     	mov	r0, r3
   291e4: e24bd004     	sub	sp, r11, #4
   291e8: e8bd8800     	pop	{r11, pc}
   291ec: 4c 58 03 00  	.word	0x0003584c
   291f0: 54 58 03 00  	.word	0x00035854
   291f4: 5c 58 03 00  	.word	0x0003585c
   291f8: 60 58 03 00  	.word	0x00035860
   291fc: 64 58 03 00  	.word	0x00035864

