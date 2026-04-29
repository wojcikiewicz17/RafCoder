.syntax unified
.arch armv7-a
.arm
.text

.global core_xor_u64
.type core_xor_u64, %function
core_xor_u64:
    eor r0, r0, r2
    eor r1, r1, r3
    bx lr

.global core_mul_u64
.type core_mul_u64, %function
core_mul_u64:
    push {r4, lr}
    mov r4, r0
    umull r0, r1, r0, r2
    mla r1, r4, r3, r1
    mla r1, r2, r1, r1
    pop {r4, pc}

.global core_rotl_u64
.type core_rotl_u64, %function
core_rotl_u64:
    and r2, r2, #63
    cmp r2, #0
    bxeq lr
    cmp r2, #32
    blt 1f
    cmp r2, #32
    beq 2f
    sub r2, r2, #32
    rsb r3, r2, #32
    mov r12, r0
    lsl r0, r0, r2
    orr r0, r0, r1, lsr r3
    lsl r1, r1, r2
    orr r1, r1, r12, lsr r3
    bx lr
2:
    mov r3, r0
    mov r0, r1
    mov r1, r3
    bx lr
1:
    rsb r3, r2, #32
    mov r12, r0
    lsl r0, r0, r2
    orr r0, r0, r1, lsr r3
    lsl r1, r1, r2
    orr r1, r1, r12, lsr r3
    bx lr

.global core_load_u8
.type core_load_u8, %function
core_load_u8:
    ldrb r0, [r0]
    bx lr

.global core_store_u8
.type core_store_u8, %function
core_store_u8:
    strb r1, [r0]
    bx lr

.global core_xor_block
.type core_xor_block, %function
core_xor_block:
    cmp r2, #0
    bxeq lr
1:
    ldrb r3, [r0]
    ldrb r12, [r1]
    eor r3, r3, r12
    strb r3, [r0]
    add r0, r0, #1
    add r1, r1, #1
    subs r2, r2, #1
    bne 1b
    bx lr
