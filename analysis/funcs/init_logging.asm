00015268 <init_logging>:
   15268: e92d4800     	push	{r11, lr}
   1526c: e28db004     	add	r11, sp, #4
   15270: e59f0024     	ldr	r0, [pc, #0x24]         @ 0x1529c <init_logging+0x34>
   15274: e59f1024     	ldr	r1, [pc, #0x24]         @ 0x152a0 <init_logging+0x38>
   15278: e3a02000     	mov	r2, #0
   1527c: ebffdd4a     	bl	0xc7ac <setenv@plt>     @ imm = #-0x8ad8
   15280: e59f001c     	ldr	r0, [pc, #0x1c]         @ 0x152a4 <init_logging+0x3c>
   15284: ebfffe12     	bl	0x14ad4 <create_log_module> @ imm = #-0x7b8
   15288: e1a02000     	mov	r2, r0
   1528c: e59f3014     	ldr	r3, [pc, #0x14]         @ 0x152a8 <init_logging+0x40>
   15290: e5832000     	str	r2, [r3]
   15294: ebfffc94     	bl	0x144ec <log_init>      @ imm = #-0xdb0
   15298: e8bd8800     	pop	{r11, pc}
   1529c: 38 2a 03 00  	.word	0x00032a38
   152a0: 44 2a 03 00  	.word	0x00032a44
   152a4: 4c 2a 03 00  	.word	0x00032a4c
   152a8: 5c 73 05 00  	.word	0x0005735c

