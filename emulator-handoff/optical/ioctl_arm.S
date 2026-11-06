/* Forward unrelated variadic ioctl calls with the original ARM register/stack
 * arguments, even when the caller supplied no third argument.
 * SPDX-License-Identifier: GPL-2.0-or-later */
.syntax unified
.arm
.text
.global ioctl
.type ioctl, %function
.hidden bx_observe_ioctl
.hidden bx_next_ioctl
ioctl:
    ldr ip, =0x40105303
    cmp r1, ip
    beq bx_observe_ioctl
    add ip, ip, #1
    cmp r1, ip
    beq bx_observe_ioctl
    push {r0-r4, lr}
    bl bx_next_ioctl
    mov ip, r0
    pop {r0-r4, lr}
    bx ip
.size ioctl, .-ioctl
.ltorg
.section .note.GNU-stack,"",%progbits
