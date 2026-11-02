0000d75c <handle_status_update_progress_callback>:
    d75c: e92d4ff0     	push	{r4, r5, r6, r7, r8, r9, r10, r11, lr}
    d760: e28db020     	add	r11, sp, #32
    d764: e24dd03c     	sub	sp, sp, #60
    d768: e50b0028     	str	r0, [r11, #-0x28]
    d76c: e50b102c     	str	r1, [r11, #-0x2c]
    d770: e50b2030     	str	r2, [r11, #-0x30]
    d774: e50b3034     	str	r3, [r11, #-0x34]
    d778: e59f31ec     	ldr	r3, [pc, #0x1ec]        @ 0xd96c <handle_status_update_progress_callback+0x210>
    d77c: e593a000     	ldr	r10, [r3]
    d780: e51b3034     	ldr	r3, [r11, #-0x34]
    d784: e3a02064     	mov	r2, #100
    d788: e0030392     	mul	r3, r2, r3
    d78c: e1a00003     	mov	r0, r3
    d790: e51b1030     	ldr	r1, [r11, #-0x30]
    d794: eb00890a     	bl	0x2fbc4 <__udivsi3>     @ imm = #0x22428
    d798: e1a03000     	mov	r3, r0
    d79c: e1a08003     	mov	r8, r3
    d7a0: e51b0034     	ldr	r0, [r11, #-0x34]
    d7a4: eb008ac4     	bl	0x302bc <__floatunsidf> @ imm = #0x22b10
    d7a8: e1a02000     	mov	r2, r0
    d7ac: e1a03001     	mov	r3, r1
    d7b0: e1a00002     	mov	r0, r2
    d7b4: e1a01003     	mov	r1, r3
    d7b8: e3a02000     	mov	r2, #0
    d7bc: e3a03101     	mov	r3, #1073741824
    d7c0: e283360a     	add	r3, r3, #10485760
    d7c4: eb008afc     	bl	0x303bc <__muldf3>      @ imm = #0x22bf0
    d7c8: e1a02000     	mov	r2, r0
    d7cc: e1a03001     	mov	r3, r1
    d7d0: e1a00002     	mov	r0, r2
    d7d4: e1a01003     	mov	r1, r3
    d7d8: e3a02000     	mov	r2, #0
    d7dc: e3a03441     	mov	r3, #1090519040
    d7e0: e2833603     	add	r3, r3, #3145728
    d7e4: eb008b8f     	bl	0x30628 <__divdf3>      @ imm = #0x22e3c
    d7e8: e1a02000     	mov	r2, r0
    d7ec: e1a03001     	mov	r3, r1
    d7f0: e1a00002     	mov	r0, r2
    d7f4: e1a01003     	mov	r1, r3
    d7f8: eb008c6c     	bl	0x309b0 <__truncdfsf2>  @ imm = #0x231b0
    d7fc: e1a03000     	mov	r3, r0
    d800: e1a00003     	mov	r0, r3
    d804: eb008abf     	bl	0x30308 <__extendsfdf2> @ imm = #0x22afc
    d808: e1a06000     	mov	r6, r0
    d80c: e1a07001     	mov	r7, r1
    d810: e51b302c     	ldr	r3, [r11, #-0x2c]
    d814: e3a02064     	mov	r2, #100
    d818: e0030392     	mul	r3, r2, r3
    d81c: e1a00003     	mov	r0, r3
    d820: e51b1028     	ldr	r1, [r11, #-0x28]
    d824: eb0088e6     	bl	0x2fbc4 <__udivsi3>     @ imm = #0x22398
    d828: e1a03000     	mov	r3, r0
    d82c: e1a09003     	mov	r9, r3
    d830: e51b0030     	ldr	r0, [r11, #-0x30]
    d834: eb008aa0     	bl	0x302bc <__floatunsidf> @ imm = #0x22a80
    d838: e1a02000     	mov	r2, r0
    d83c: e1a03001     	mov	r3, r1
    d840: e1a00002     	mov	r0, r2
    d844: e1a01003     	mov	r1, r3
    d848: e3a02000     	mov	r2, #0
    d84c: e3a03101     	mov	r3, #1073741824
    d850: e283360a     	add	r3, r3, #10485760
    d854: eb008ad8     	bl	0x303bc <__muldf3>      @ imm = #0x22b60
    d858: e1a02000     	mov	r2, r0
    d85c: e1a03001     	mov	r3, r1
    d860: e1a00002     	mov	r0, r2
    d864: e1a01003     	mov	r1, r3
    d868: e3a02000     	mov	r2, #0
    d86c: e3a03441     	mov	r3, #1090519040
    d870: e2833603     	add	r3, r3, #3145728
    d874: eb008b6b     	bl	0x30628 <__divdf3>      @ imm = #0x22dac
    d878: e1a02000     	mov	r2, r0
    d87c: e1a03001     	mov	r3, r1
    d880: e1a00002     	mov	r0, r2
    d884: e1a01003     	mov	r1, r3
    d888: eb008c48     	bl	0x309b0 <__truncdfsf2>  @ imm = #0x23120
    d88c: e1a03000     	mov	r3, r0
    d890: e1a00003     	mov	r0, r3
    d894: eb008a9b     	bl	0x30308 <__extendsfdf2> @ imm = #0x22a6c
    d898: e1a04000     	mov	r4, r0
    d89c: e1a05001     	mov	r5, r1
    d8a0: e51b002c     	ldr	r0, [r11, #-0x2c]
    d8a4: eb008a84     	bl	0x302bc <__floatunsidf> @ imm = #0x22a10
    d8a8: e1a02000     	mov	r2, r0
    d8ac: e1a03001     	mov	r3, r1
    d8b0: e1a00002     	mov	r0, r2
    d8b4: e1a01003     	mov	r1, r3
    d8b8: e3a02000     	mov	r2, #0
    d8bc: e3a03101     	mov	r3, #1073741824
    d8c0: e283360a     	add	r3, r3, #10485760
    d8c4: eb008abc     	bl	0x303bc <__muldf3>      @ imm = #0x22af0
    d8c8: e1a02000     	mov	r2, r0
    d8cc: e1a03001     	mov	r3, r1
    d8d0: e1a00002     	mov	r0, r2
    d8d4: e1a01003     	mov	r1, r3
    d8d8: e3a02000     	mov	r2, #0
    d8dc: e3a03441     	mov	r3, #1090519040
    d8e0: e2833603     	add	r3, r3, #3145728
    d8e4: eb008b4f     	bl	0x30628 <__divdf3>      @ imm = #0x22d3c
    d8e8: e1a02000     	mov	r2, r0
    d8ec: e1a03001     	mov	r3, r1
    d8f0: e1a00002     	mov	r0, r2
    d8f4: e1a01003     	mov	r1, r3
    d8f8: eb008c2c     	bl	0x309b0 <__truncdfsf2>  @ imm = #0x230b0
    d8fc: e50b0038     	str	r0, [r11, #-0x38]
    d900: e3a00000     	mov	r0, #0
    d904: ebfffb42     	bl	0xc614 <time@plt>       @ imm = #-0x12f8
    d908: e1a02000     	mov	r2, r0
    d90c: e59f305c     	ldr	r3, [pc, #0x5c]         @ 0xd970 <handle_status_update_progress_callback+0x214>
    d910: e5933000     	ldr	r3, [r3]
    d914: e0633002     	rsb	r3, r3, r2
    d918: e1a00003     	mov	r0, r3
    d91c: eb008cb4     	bl	0x30bf4 <__floatsisf>   @ imm = #0x232d0
    d920: e1a03000     	mov	r3, r0
    d924: e51b0038     	ldr	r0, [r11, #-0x38]
    d928: e1a01003     	mov	r1, r3
    d92c: eb008d41     	bl	0x30e38 <__divsf3>      @ imm = #0x23504
    d930: e1a03000     	mov	r3, r0
    d934: e1a00003     	mov	r0, r3
    d938: eb008a72     	bl	0x30308 <__extendsfdf2> @ imm = #0x229c8
    d93c: e1a02000     	mov	r2, r0
    d940: e1a03001     	mov	r3, r1
    d944: e1cd60f0     	strd	r6, r7, [sp]
    d948: e58d9008     	str	r9, [sp, #0x8]
    d94c: e1cd41f0     	strd	r4, r5, [sp, #16]
    d950: e1cd21f8     	strd	r2, r3, [sp, #24]
    d954: e1a0000a     	mov	r0, r10
    d958: e59f1014     	ldr	r1, [pc, #0x14]         @ 0xd974 <handle_status_update_progress_callback+0x218>
    d95c: e1a02008     	mov	r2, r8
    d960: ebffff25     	bl	0xd5fc <safe_fwprintf>  @ imm = #-0x36c
    d964: e24bd020     	sub	sp, r11, #32
    d968: e8bd8ff0     	pop	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
    d96c: f4 6d 05 00  	.word	0x00056df4
    d970: 40 71 05 00  	.word	0x00057140
    d974: 60 1b 03 00  	.word	0x00031b60

