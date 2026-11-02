000152ac <destroy_logging>:
   152ac: e92d4800     	push	{r11, lr}
   152b0: e28db004     	add	r11, sp, #4
   152b4: ebfffd60     	bl	0x1483c <log_destroy>   @ imm = #-0xa80
   152b8: e8bd8800     	pop	{r11, pc}

