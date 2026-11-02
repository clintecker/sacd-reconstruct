00015720 <new_lock>:
   15720: e92d4800     	push	{r11, lr}
   15724: e28db004     	add	r11, sp, #4
   15728: e24dd010     	sub	sp, sp, #16
   1572c: e50b0010     	str	r0, [r11, #-0x10]
   15730: e3a00050     	mov	r0, #80
   15734: ebffffe5     	bl	0x156d0 <my_malloc>     @ imm = #-0x6c
   15738: e1a03000     	mov	r3, r0
   1573c: e50b3008     	str	r3, [r11, #-0x8]
   15740: e51b3008     	ldr	r3, [r11, #-0x8]
   15744: e1a00003     	mov	r0, r3
   15748: e3a01000     	mov	r1, #0
   1574c: ebffdb95     	bl	0xc5a8 <pthread_mutex_init@plt> @ imm = #-0x91ac
   15750: e1a03000     	mov	r3, r0
   15754: e50b300c     	str	r3, [r11, #-0xc]
   15758: e51b300c     	ldr	r3, [r11, #-0xc]
   1575c: e3530000     	cmp	r3, #0
   15760: 1a000009     	bne	0x1578c <new_lock+0x6c> @ imm = #0x24
   15764: e51b3008     	ldr	r3, [r11, #-0x8]
   15768: e2833018     	add	r3, r3, #24
   1576c: e1a00003     	mov	r0, r3
   15770: e3a01000     	mov	r1, #0
   15774: ebffdbfa     	bl	0xc764 <pthread_cond_init@plt> @ imm = #-0x9018
   15778: e1a03000     	mov	r3, r0
   1577c: e50b300c     	str	r3, [r11, #-0xc]
   15780: e51b300c     	ldr	r3, [r11, #-0xc]
   15784: e3530000     	cmp	r3, #0
   15788: 0a000001     	beq	0x15794 <new_lock+0x74> @ imm = #0x4
   1578c: e51b000c     	ldr	r0, [r11, #-0xc]
   15790: ebffff92     	bl	0x155e0 <fail>          @ imm = #-0x1b8
   15794: e51b3008     	ldr	r3, [r11, #-0x8]
   15798: e51b2010     	ldr	r2, [r11, #-0x10]
   1579c: e5832048     	str	r2, [r3, #0x48]
   157a0: e51b3008     	ldr	r3, [r11, #-0x8]
   157a4: e1a00003     	mov	r0, r3
   157a8: e24bd004     	sub	sp, r11, #4
   157ac: e8bd8800     	pop	{r11, pc}

