.text

.global core_xor_u64
.type core_xor_u64, @function
core_xor_u64:
    mov %rdi, %rax
    xor %rsi, %rax
    ret

.global core_mul_u64
.type core_mul_u64, @function
core_mul_u64:
    mov %rdi, %rax
    imul %rsi, %rax
    ret

.global core_rotl_u64
.type core_rotl_u64, @function
core_rotl_u64:
    mov %rdi, %rax
    mov %sil, %cl
    rol %cl, %rax
    ret

.global core_load_u8
.type core_load_u8, @function
core_load_u8:
    movzbl (%rdi), %eax
    ret

.global core_store_u8
.type core_store_u8, @function
core_store_u8:
    mov %sil, (%rdi)
    ret

.global core_xor_block
.type core_xor_block, @function
core_xor_block:
    test %rdx, %rdx
    je .Ldone
.Lloop:
    movzbl (%rsi), %eax
    xorb %al, (%rdi)
    inc %rdi
    inc %rsi
    dec %rdx
    jne .Lloop
.Ldone:
    ret
