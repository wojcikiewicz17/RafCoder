.text

.global core_xor_u64
.type core_xor_u64, %function
core_xor_u64:
    eor x0, x0, x1
    ret

.global core_mul_u64
.type core_mul_u64, %function
core_mul_u64:
    mul x0, x0, x1
    ret

.global core_rotl_u64
.type core_rotl_u64, %function
core_rotl_u64:
    and w1, w1, #63
    neg w2, w1
    ror x0, x0, w2
    ret

.global core_load_u8
.type core_load_u8, %function
core_load_u8:
    ldrb w0, [x0]
    ret

.global core_store_u8
.type core_store_u8, %function
core_store_u8:
    strb w1, [x0]
    ret

.global core_xor_block
.type core_xor_block, %function
core_xor_block:
    cbz x2, 2f
1:
    ldrb w3, [x0]
    ldrb w4, [x1]
    eor w3, w3, w4
    strb w3, [x0]
    add x0, x0, #1
    add x1, x1, #1
    subs x2, x2, #1
    b.ne 1b
2:
    ret
