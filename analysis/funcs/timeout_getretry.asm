0000ffb4 <timeout_getretry>:
    ffb4: e92d4870     	push	{r4, r5, r6, r11, lr}
    ffb8: e28db010     	add	r11, sp, #16
    ffbc: e24dd024     	sub	sp, sp, #36
    ffc0: e50b0030     	str	r0, [r11, #-0x30]
    ffc4: e51b3030     	ldr	r3, [r11, #-0x30]
    ffc8: e1c320d0     	ldrd	r2, r3, [r3]
    ffcc: e3a01000     	mov	r1, #0
    ffd0: e1a04001     	mov	r4, r1
    ffd4: e1a00002     	mov	r0, r2
    ffd8: e1a01003     	mov	r1, r3
    ffdc: e3a02000     	mov	r2, #0
    ffe0: e3a03000     	mov	r3, #0
    ffe4: eb008246     	bl	0x30904 <__aeabi_dcmplt> @ imm = #0x20918
    ffe8: e1a03000     	mov	r3, r0
    ffec: e3530000     	cmp	r3, #0
    fff0: 0a000001     	beq	0xfffc <timeout_getretry+0x48> @ imm = #0x4
    fff4: e3a03001     	mov	r3, #1
    fff8: e1a04003     	mov	r4, r3
    fffc: e6ef3074     	uxtb	r3, r4
   10000: e3530000     	cmp	r3, #0
   10004: 0a000014     	beq	0x1005c <timeout_getretry+0xa8> @ imm = #0x50
   10008: e51b3030     	ldr	r3, [r11, #-0x30]
   1000c: e1c320d8     	ldrd	r2, r3, [r3, #8]
   10010: e3a01000     	mov	r1, #0
   10014: e1a04001     	mov	r4, r1
   10018: e1a00002     	mov	r0, r2
   1001c: e1a01003     	mov	r1, r3
   10020: e3a02000     	mov	r2, #0
   10024: e3a03000     	mov	r3, #0
   10028: eb008235     	bl	0x30904 <__aeabi_dcmplt> @ imm = #0x208d4
   1002c: e1a03000     	mov	r3, r0
   10030: e3530000     	cmp	r3, #0
   10034: 0a000001     	beq	0x10040 <timeout_getretry+0x8c> @ imm = #0x4
   10038: e3a03001     	mov	r3, #1
   1003c: e1a04003     	mov	r4, r3
   10040: e6ef3074     	uxtb	r3, r4
   10044: e3530000     	cmp	r3, #0
   10048: 0a000003     	beq	0x1005c <timeout_getretry+0xa8> @ imm = #0xc
   1004c: e3a02000     	mov	r2, #0
   10050: e3a034bf     	mov	r3, #-1090519040
   10054: e283360f     	add	r3, r3, #15728640
   10058: ea0000b3     	b	0x1032c <timeout_getretry+0x378> @ imm = #0x2cc
   1005c: e51b3030     	ldr	r3, [r11, #-0x30]
   10060: e1c320d0     	ldrd	r2, r3, [r3]
   10064: e3a01000     	mov	r1, #0
   10068: e1a04001     	mov	r4, r1
   1006c: e1a00002     	mov	r0, r2
   10070: e1a01003     	mov	r1, r3
   10074: e3a02000     	mov	r2, #0
   10078: e3a03000     	mov	r3, #0
   1007c: eb008220     	bl	0x30904 <__aeabi_dcmplt> @ imm = #0x20880
   10080: e1a03000     	mov	r3, r0
   10084: e3530000     	cmp	r3, #0
   10088: 0a000001     	beq	0x10094 <timeout_getretry+0xe0> @ imm = #0x4
   1008c: e3a03001     	mov	r3, #1
   10090: e1a04003     	mov	r4, r3
   10094: e6ef3074     	uxtb	r3, r4
   10098: e3530000     	cmp	r3, #0
   1009c: 0a000024     	beq	0x10134 <timeout_getretry+0x180> @ imm = #0x90
   100a0: e51b3030     	ldr	r3, [r11, #-0x30]
   100a4: e1c340d8     	ldrd	r4, r5, [r3, #8]
   100a8: eb0000b0     	bl	0x10370 <timeout_gettime> @ imm = #0x2c0
   100ac: e1a02000     	mov	r2, r0
   100b0: e1a03001     	mov	r3, r1
   100b4: e1a00004     	mov	r0, r4
   100b8: e1a01005     	mov	r1, r5
   100bc: eb007fd2     	bl	0x3000c <__subdf3>      @ imm = #0x1ff48
   100c0: e1a02000     	mov	r2, r0
   100c4: e1a03001     	mov	r3, r1
   100c8: e1a00002     	mov	r0, r2
   100cc: e1a01003     	mov	r1, r3
   100d0: e51b3030     	ldr	r3, [r11, #-0x30]
   100d4: e1c321d0     	ldrd	r2, r3, [r3, #16]
   100d8: eb007fcc     	bl	0x30010 <__aeabi_dadd>  @ imm = #0x1ff30
   100dc: e1a02000     	mov	r2, r0
   100e0: e1a03001     	mov	r3, r1
   100e4: e14b22fc     	strd	r2, r3, [r11, #-44]
   100e8: e3a03000     	mov	r3, #0
   100ec: e1a04003     	mov	r4, r3
   100f0: e14b02dc     	ldrd	r0, r1, [r11, #-44]
   100f4: e3a02000     	mov	r2, #0
   100f8: e3a03000     	mov	r3, #0
   100fc: eb00820f     	bl	0x30940 <__aeabi_dcmpgt> @ imm = #0x2083c
   10100: e1a03000     	mov	r3, r0
   10104: e3530000     	cmp	r3, #0
   10108: 0a000001     	beq	0x10114 <timeout_getretry+0x160> @ imm = #0x4
   1010c: e3a03001     	mov	r3, #1
   10110: e1a04003     	mov	r4, r3
   10114: e6ef3074     	uxtb	r3, r4
   10118: e3530000     	cmp	r3, #0
   1011c: 0a000001     	beq	0x10128 <timeout_getretry+0x174> @ imm = #0x4
   10120: e14b22dc     	ldrd	r2, r3, [r11, #-44]
   10124: ea000001     	b	0x10130 <timeout_getretry+0x17c> @ imm = #0x4
   10128: e3a02000     	mov	r2, #0
   1012c: e3a03000     	mov	r3, #0
   10130: ea00007d     	b	0x1032c <timeout_getretry+0x378> @ imm = #0x1f4
   10134: e51b3030     	ldr	r3, [r11, #-0x30]
   10138: e1c320d8     	ldrd	r2, r3, [r3, #8]
   1013c: e3a01000     	mov	r1, #0
   10140: e1a04001     	mov	r4, r1
   10144: e1a00002     	mov	r0, r2
   10148: e1a01003     	mov	r1, r3
   1014c: e3a02000     	mov	r2, #0
   10150: e3a03000     	mov	r3, #0
   10154: eb0081ea     	bl	0x30904 <__aeabi_dcmplt> @ imm = #0x207a8
   10158: e1a03000     	mov	r3, r0
   1015c: e3530000     	cmp	r3, #0
   10160: 0a000001     	beq	0x1016c <timeout_getretry+0x1b8> @ imm = #0x4
   10164: e3a03001     	mov	r3, #1
   10168: e1a04003     	mov	r4, r3
   1016c: e6ef3074     	uxtb	r3, r4
   10170: e3530000     	cmp	r3, #0
   10174: 0a000024     	beq	0x1020c <timeout_getretry+0x258> @ imm = #0x90
   10178: e51b3030     	ldr	r3, [r11, #-0x30]
   1017c: e1c340d0     	ldrd	r4, r5, [r3]
   10180: eb00007a     	bl	0x10370 <timeout_gettime> @ imm = #0x1e8
   10184: e1a02000     	mov	r2, r0
   10188: e1a03001     	mov	r3, r1
   1018c: e1a00004     	mov	r0, r4
   10190: e1a01005     	mov	r1, r5
   10194: eb007f9c     	bl	0x3000c <__subdf3>      @ imm = #0x1fe70
   10198: e1a02000     	mov	r2, r0
   1019c: e1a03001     	mov	r3, r1
   101a0: e1a00002     	mov	r0, r2
   101a4: e1a01003     	mov	r1, r3
   101a8: e51b3030     	ldr	r3, [r11, #-0x30]
   101ac: e1c321d0     	ldrd	r2, r3, [r3, #16]
   101b0: eb007f96     	bl	0x30010 <__aeabi_dadd>  @ imm = #0x1fe58
   101b4: e1a02000     	mov	r2, r0
   101b8: e1a03001     	mov	r3, r1
   101bc: e14b22f4     	strd	r2, r3, [r11, #-36]
   101c0: e3a03000     	mov	r3, #0
   101c4: e1a04003     	mov	r4, r3
   101c8: e14b02d4     	ldrd	r0, r1, [r11, #-36]
   101cc: e3a02000     	mov	r2, #0
   101d0: e3a03000     	mov	r3, #0
   101d4: eb0081d9     	bl	0x30940 <__aeabi_dcmpgt> @ imm = #0x20764
   101d8: e1a03000     	mov	r3, r0
   101dc: e3530000     	cmp	r3, #0
   101e0: 0a000001     	beq	0x101ec <timeout_getretry+0x238> @ imm = #0x4
   101e4: e3a03001     	mov	r3, #1
   101e8: e1a04003     	mov	r4, r3
   101ec: e6ef3074     	uxtb	r3, r4
   101f0: e3530000     	cmp	r3, #0
   101f4: 0a000001     	beq	0x10200 <timeout_getretry+0x24c> @ imm = #0x4
   101f8: e14b22d4     	ldrd	r2, r3, [r11, #-36]
   101fc: ea000001     	b	0x10208 <timeout_getretry+0x254> @ imm = #0x4
   10200: e3a02000     	mov	r2, #0
   10204: e3a03000     	mov	r3, #0
   10208: ea000047     	b	0x1032c <timeout_getretry+0x378> @ imm = #0x11c
   1020c: e51b3030     	ldr	r3, [r11, #-0x30]
   10210: e1c340d8     	ldrd	r4, r5, [r3, #8]
   10214: eb000055     	bl	0x10370 <timeout_gettime> @ imm = #0x154
   10218: e1a02000     	mov	r2, r0
   1021c: e1a03001     	mov	r3, r1
   10220: e1a00004     	mov	r0, r4
   10224: e1a01005     	mov	r1, r5
   10228: eb007f77     	bl	0x3000c <__subdf3>      @ imm = #0x1fddc
   1022c: e1a02000     	mov	r2, r0
   10230: e1a03001     	mov	r3, r1
   10234: e1a00002     	mov	r0, r2
   10238: e1a01003     	mov	r1, r3
   1023c: e51b3030     	ldr	r3, [r11, #-0x30]
   10240: e1c321d0     	ldrd	r2, r3, [r3, #16]
   10244: eb007f71     	bl	0x30010 <__aeabi_dadd>  @ imm = #0x1fdc4
   10248: e1a02000     	mov	r2, r0
   1024c: e1a03001     	mov	r3, r1
   10250: e14b21fc     	strd	r2, r3, [r11, #-28]
   10254: e51b3030     	ldr	r3, [r11, #-0x30]
   10258: e1c340d0     	ldrd	r4, r5, [r3]
   1025c: e3a03000     	mov	r3, #0
   10260: e1a06003     	mov	r6, r3
   10264: e14b01dc     	ldrd	r0, r1, [r11, #-28]
   10268: e3a02000     	mov	r2, #0
   1026c: e3a03000     	mov	r3, #0
   10270: eb0081b2     	bl	0x30940 <__aeabi_dcmpgt> @ imm = #0x206c8
   10274: e1a03000     	mov	r3, r0
   10278: e3530000     	cmp	r3, #0
   1027c: 0a000001     	beq	0x10288 <timeout_getretry+0x2d4> @ imm = #0x4
   10280: e3a03001     	mov	r3, #1
   10284: e1a06003     	mov	r6, r3
   10288: e6ef3076     	uxtb	r3, r6
   1028c: e3530000     	cmp	r3, #0
   10290: 0a000001     	beq	0x1029c <timeout_getretry+0x2e8> @ imm = #0x4
   10294: e14b21dc     	ldrd	r2, r3, [r11, #-28]
   10298: ea000001     	b	0x102a4 <timeout_getretry+0x2f0> @ imm = #0x4
   1029c: e3a02000     	mov	r2, #0
   102a0: e3a03000     	mov	r3, #0
   102a4: e3a01000     	mov	r1, #0
   102a8: e1a06001     	mov	r6, r1
   102ac: e1a00004     	mov	r0, r4
   102b0: e1a01005     	mov	r1, r5
   102b4: eb008192     	bl	0x30904 <__aeabi_dcmplt> @ imm = #0x20648
   102b8: e1a03000     	mov	r3, r0
   102bc: e3530000     	cmp	r3, #0
   102c0: 0a000001     	beq	0x102cc <timeout_getretry+0x318> @ imm = #0x4
   102c4: e3a03001     	mov	r3, #1
   102c8: e1a06003     	mov	r6, r3
   102cc: e6ef3076     	uxtb	r3, r6
   102d0: e3530000     	cmp	r3, #0
   102d4: 0a000002     	beq	0x102e4 <timeout_getretry+0x330> @ imm = #0x8
   102d8: e51b3030     	ldr	r3, [r11, #-0x30]
   102dc: e1c320d0     	ldrd	r2, r3, [r3]
   102e0: ea000011     	b	0x1032c <timeout_getretry+0x378> @ imm = #0x44
   102e4: e3a03000     	mov	r3, #0
   102e8: e1a04003     	mov	r4, r3
   102ec: e14b01dc     	ldrd	r0, r1, [r11, #-28]
   102f0: e3a02000     	mov	r2, #0
   102f4: e3a03000     	mov	r3, #0
   102f8: eb008190     	bl	0x30940 <__aeabi_dcmpgt> @ imm = #0x20640
   102fc: e1a03000     	mov	r3, r0
   10300: e3530000     	cmp	r3, #0
   10304: 0a000001     	beq	0x10310 <timeout_getretry+0x35c> @ imm = #0x4
   10308: e3a03001     	mov	r3, #1
   1030c: e1a04003     	mov	r4, r3
   10310: e6ef3074     	uxtb	r3, r4
   10314: e3530000     	cmp	r3, #0
   10318: 0a000001     	beq	0x10324 <timeout_getretry+0x370> @ imm = #0x4
   1031c: e14b21dc     	ldrd	r2, r3, [r11, #-28]
   10320: ea000001     	b	0x1032c <timeout_getretry+0x378> @ imm = #0x4
   10324: e3a02000     	mov	r2, #0
   10328: e3a03000     	mov	r3, #0
   1032c: e1a00002     	mov	r0, r2
   10330: e1a01003     	mov	r1, r3
   10334: e24bd010     	sub	sp, r11, #16
   10338: e8bd8870     	pop	{r4, r5, r6, r11, pc}

