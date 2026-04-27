; ═══════════════════════════════════════════════════════════════════
; RAFAELOS CORE — x86_64 NASM
; Estado Toroidal T^7 em assembly puro
; Compilar : nasm -f elf64 rafaelos.asm -o rafaelos.o
; Linkar   : ld rafaelos.o -o rafaelos
; Sem libc, sem GC, sem abstração
; Syscalls Linux diretos (sys_write=1, sys_exit=60)
; ═══════════════════════════════════════════════════════════════════

BITS 64

SYS_WRITE  equ 1
SYS_EXIT   equ 60
STDOUT     equ 1

section .rodata
    align 8
    C_ALPHA      dq 0x3FD0000000000000  ; 0.25
    C_1MALPHA    dq 0x3FE8000000000000  ; 0.75
    C_ONE        dq 0x3FF0000000000000  ; 1.0
    C_ZERO       dq 0x0000000000000000  ; 0.0
    C_PHI        dq 0x3FF9E3779B97F4A8  ; φ
    C_SQRT3_2    dq 0x3FEBB67AE8584CCA  ; √3/2
    C_THR_LOW    dq 0x3FB999999999999A  ; 0.1
    C_THR_HIGH   dq 0x3FD3333333333333  ; 0.3

    FNV_PRIME    dq 0x00000100000001B3
    FNV_BASIS    dq 0xCBF29CE484222325

    msg_header   db "RAFAELOS T^7 — ASSEMBLER PURO", 10
                 db "==============================", 10
    msg_header_len equ $ - msg_header

    msg_step     db "STEP t=", 0
    msg_phi      db "PHI:   ", 0
    msg_newline  db 10, 0
    msg_group_hdr db "GROUP SUMMARY (phi buckets)", 10
    msg_group_hdr_len equ $ - msg_group_hdr
    msg_grp_low  db "LOW  [0.0000..0.1000): "
    msg_grp_low_len equ $ - msg_grp_low
    msg_grp_mid  db "MID  [0.1000..0.3000): "
    msg_grp_mid_len equ $ - msg_grp_mid
    msg_grp_high db "HIGH [0.3000..1.0000): "
    msg_grp_high_len equ $ - msg_grp_high

section .bss
    align 16
    state_u      resq 1
    state_v      resq 1
    state_psi    resq 1
    state_chi    resq 1
    state_rho    resq 1
    state_delta  resq 1
    state_sigma  resq 1

    input_vec    resq 7
    phi_val      resq 1
    step_count   resq 1
    num_buf      resb 32
    group_low    resq 1
    group_mid    resq 1
    group_high   resq 1

section .text
    global _start

_start:
    call    state_init

    mov     rdi, STDOUT
    mov     rsi, msg_header
    mov     rdx, msg_header_len
    mov     rax, SYS_WRITE
    syscall

    mov     qword [step_count], 0
    mov     qword [group_low], 0
    mov     qword [group_mid], 0
    mov     qword [group_high], 0

.main_loop:
    cmp     qword [step_count], 42
    jge     .done

    mov     rdi, [step_count]
    call    generate_input
    call    state_update
    call    calc_phi
    call    classify_phi
    call    print_step

    inc     qword [step_count]
    jmp     .main_loop

.done:
    call    print_group_summary
    mov     rax, SYS_EXIT
    xor     rdi, rdi
    syscall

state_init:
    movsd   xmm0, [C_ONE]
    divsd   xmm0, [C_PHI]
    movsd   [state_u], xmm0

    movsd   xmm0, [C_SQRT3_2]
    movsd   [state_v], xmm0

    movsd   xmm0, [C_ALPHA]
    movsd   [state_psi], xmm0

    movsd   xmm0, [C_ONE]
    movsd   xmm1, [C_ONE]
    addsd   xmm1, xmm1
    divsd   xmm0, xmm1
    movsd   [state_chi], xmm0

    movsd   xmm0, [C_1MALPHA]
    movsd   [state_rho], xmm0

    movsd   xmm0, [C_ONE]
    movsd   xmm1, [C_ONE]
    addsd   xmm1, [C_ONE]
    addsd   xmm1, [C_ONE]
    divsd   xmm0, xmm1
    movsd   [state_delta], xmm0

    movsd   xmm0, [C_SQRT3_2]
    divsd   xmm0, [C_PHI]
    movsd   [state_sigma], xmm0
    ret

generate_input:
    push    rbx
    push    rcx
    push    r12
    push    r13

    mov     r12, [FNV_BASIS]
    mov     r13, [FNV_PRIME]
    lea     rbx, [step_count]
    mov     rcx, 8

.fnv_loop:
    movzx   rax, byte [rbx]
    xor     r12, rax
    mov     rax, r12
    mul     r13
    mov     r12, rax
    inc     rbx
    dec     rcx
    jnz     .fnv_loop

    mov     rbx, r12
    xor     rcx, rcx

.gen_loop:
    cmp     rcx, 7
    jge     .gen_done

    mov     rax, rbx
    rol     rax, 11
    xor     rax, rcx
    imul    rax, [FNV_PRIME]
    mov     rbx, rax

    mov     rax, rbx
    shr     rax, 12
    mov     rdx, 0x3FF0000000000000
    or      rax, rdx
    movq    xmm0, rax
    subsd   xmm0, [C_ONE]

    movsd   [input_vec + rcx*8], xmm0

    inc     rcx
    jmp     .gen_loop

.gen_done:
    pop     r13
    pop     r12
    pop     rcx
    pop     rbx
    ret

state_update:
    movsd   xmm4, [C_1MALPHA]
    movsd   xmm5, [C_ALPHA]

    movsd   xmm0, [state_u]
    movsd   xmm1, [input_vec + 0]
    mulsd   xmm0, xmm4
    mulsd   xmm1, xmm5
    addsd   xmm0, xmm1
    call    mod_one
    movsd   [state_u], xmm0

    movsd   xmm0, [state_v]
    movsd   xmm1, [input_vec + 8]
    mulsd   xmm0, xmm4
    mulsd   xmm1, xmm5
    addsd   xmm0, xmm1
    call    mod_one
    movsd   [state_v], xmm0

    movsd   xmm0, [state_psi]
    movsd   xmm1, [input_vec + 16]
    mulsd   xmm0, xmm4
    mulsd   xmm1, xmm5
    addsd   xmm0, xmm1
    call    mod_one
    movsd   [state_psi], xmm0

    movsd   xmm0, [state_chi]
    movsd   xmm1, [input_vec + 24]
    mulsd   xmm0, xmm4
    mulsd   xmm1, xmm5
    addsd   xmm0, xmm1
    call    mod_one
    movsd   [state_chi], xmm0

    movsd   xmm0, [state_rho]
    movsd   xmm1, [input_vec + 32]
    mulsd   xmm0, xmm4
    mulsd   xmm1, xmm5
    addsd   xmm0, xmm1
    call    mod_one
    movsd   [state_rho], xmm0

    movsd   xmm0, [state_delta]
    movsd   xmm1, [input_vec + 40]
    mulsd   xmm0, xmm4
    mulsd   xmm1, xmm5
    addsd   xmm0, xmm1
    call    mod_one
    movsd   [state_delta], xmm0

    movsd   xmm0, [state_sigma]
    movsd   xmm1, [input_vec + 48]
    mulsd   xmm0, xmm4
    mulsd   xmm1, xmm5
    addsd   xmm0, xmm1
    call    mod_one
    movsd   [state_sigma], xmm0
    ret

mod_one:
    movsd   xmm3, xmm0
    roundsd xmm3, xmm3, 1
    subsd   xmm0, xmm3
    maxsd   xmm0, [C_ZERO]
    ret

calc_phi:
    movsd   xmm6, [state_u]
    mulsd   xmm6, [state_u]

    movsd   xmm7, [state_v]
    mulsd   xmm7, [state_v]
    addsd   xmm6, xmm7

    movsd   xmm7, [state_psi]
    mulsd   xmm7, [state_psi]
    addsd   xmm6, xmm7

    movsd   xmm7, [state_chi]
    mulsd   xmm7, [state_chi]
    addsd   xmm6, xmm7

    movsd   xmm7, [state_rho]
    mulsd   xmm7, [state_rho]
    addsd   xmm6, xmm7

    movsd   xmm7, [state_delta]
    mulsd   xmm7, [state_delta]
    addsd   xmm6, xmm7

    movsd   xmm7, [state_sigma]
    mulsd   xmm7, [state_sigma]
    addsd   xmm6, xmm7

    movsd   xmm7, [C_ONE]
    addsd   xmm7, [C_ONE]
    addsd   xmm7, [C_ONE]
    addsd   xmm7, [C_ONE]
    addsd   xmm7, [C_ONE]
    addsd   xmm7, [C_ONE]
    addsd   xmm7, [C_ONE]
    divsd   xmm6, xmm7

    movsd   xmm0, xmm6
    mulsd   xmm0, xmm6
    movsd   [phi_val], xmm0
    ret

classify_phi:
    movsd   xmm0, [phi_val]
    ucomisd xmm0, [C_THR_LOW]
    jb      .low
    ucomisd xmm0, [C_THR_HIGH]
    jb      .mid
    inc     qword [group_high]
    ret
.low:
    inc     qword [group_low]
    ret
.mid:
    inc     qword [group_mid]
    ret

print_group_summary:
    mov     rdi, STDOUT
    mov     rsi, msg_group_hdr
    mov     rdx, msg_group_hdr_len
    mov     rax, SYS_WRITE
    syscall

    mov     rdi, STDOUT
    mov     rsi, msg_grp_low
    mov     rdx, msg_grp_low_len
    mov     rax, SYS_WRITE
    syscall
    mov     rdi, [group_low]
    lea     rsi, [num_buf]
    call    u64_to_dec
    mov     rdi, STDOUT
    lea     rsi, [num_buf]
    mov     rdx, rax
    mov     rax, SYS_WRITE
    syscall
    mov     rdi, STDOUT
    mov     rsi, msg_newline
    mov     rdx, 1
    mov     rax, SYS_WRITE
    syscall

    mov     rdi, STDOUT
    mov     rsi, msg_grp_mid
    mov     rdx, msg_grp_mid_len
    mov     rax, SYS_WRITE
    syscall
    mov     rdi, [group_mid]
    lea     rsi, [num_buf]
    call    u64_to_dec
    mov     rdi, STDOUT
    lea     rsi, [num_buf]
    mov     rdx, rax
    mov     rax, SYS_WRITE
    syscall
    mov     rdi, STDOUT
    mov     rsi, msg_newline
    mov     rdx, 1
    mov     rax, SYS_WRITE
    syscall

    mov     rdi, STDOUT
    mov     rsi, msg_grp_high
    mov     rdx, msg_grp_high_len
    mov     rax, SYS_WRITE
    syscall
    mov     rdi, [group_high]
    lea     rsi, [num_buf]
    call    u64_to_dec
    mov     rdi, STDOUT
    lea     rsi, [num_buf]
    mov     rdx, rax
    mov     rax, SYS_WRITE
    syscall
    mov     rdi, STDOUT
    mov     rsi, msg_newline
    mov     rdx, 1
    mov     rax, SYS_WRITE
    syscall
    ret

print_step:
    mov     rdi, STDOUT
    mov     rsi, msg_step
    mov     rdx, 7
    mov     rax, SYS_WRITE
    syscall

    mov     rdi, [step_count]
    lea     rsi, [num_buf]
    call    u64_to_dec

    mov     rdi, STDOUT
    lea     rsi, [num_buf]
    mov     rdx, rax
    mov     rax, SYS_WRITE
    syscall

    mov     rdi, STDOUT
    mov     rsi, msg_newline
    mov     rdx, 1
    mov     rax, SYS_WRITE
    syscall

    mov     rdi, STDOUT
    mov     rsi, msg_phi
    mov     rdx, 7
    mov     rax, SYS_WRITE
    syscall

    movsd   xmm0, [phi_val]
    lea     rdi, [num_buf]
    call    f64_to_dec4

    mov     rdi, STDOUT
    lea     rsi, [num_buf]
    mov     rdx, rax
    mov     rax, SYS_WRITE
    syscall

    mov     rdi, STDOUT
    mov     rsi, msg_newline
    mov     rdx, 1
    mov     rax, SYS_WRITE
    syscall
    ret

u64_to_dec:
    push    rbx
    push    rcx
    push    rdx

    mov     rax, rdi
    lea     rbx, [rsi + 20]
    mov     byte [rbx], 0

    test    rax, rax
    jnz     .u_loop
    mov     byte [rsi], '0'
    mov     rax, 1
    jmp     .u_done

.u_loop:
    xor     rcx, rcx
.convert:
    xor     rdx, rdx
    mov     rcx, 10
    div     rcx
    add     rdx, '0'
    dec     rbx
    mov     [rbx], dl
    test    rax, rax
    jnz     .convert

    lea     rax, [rsi + 20]
    sub     rax, rbx
    mov     rcx, rax
.copy:
    mov     dl, [rbx]
    mov     [rsi], dl
    inc     rbx
    inc     rsi
    dec     rcx
    jnz     .copy

.u_done:
    pop     rdx
    pop     rcx
    pop     rbx
    ret

f64_to_dec4:
    push    rbx
    push    rcx
    push    rdx

    mov     rsi, rdi
    movsd   xmm1, xmm0
    roundsd xmm1, xmm1, 3
    cvttsd2si rbx, xmm1
    add     rbx, '0'
    mov     [rsi], bl
    inc     rsi
    mov     byte [rsi], '.'
    inc     rsi

    subsd   xmm0, xmm1
    mov     rcx, 4
.f_loop:
    movsd   xmm2, [C_ONE]
    addsd   xmm2, [C_ONE]
    addsd   xmm2, [C_ONE]
    addsd   xmm2, [C_ONE]
    addsd   xmm2, [C_ONE]
    addsd   xmm2, [C_ONE]
    addsd   xmm2, [C_ONE]
    addsd   xmm2, [C_ONE]
    addsd   xmm2, [C_ONE]
    addsd   xmm2, [C_ONE]
    mulsd   xmm0, xmm2

    movsd   xmm1, xmm0
    roundsd xmm1, xmm1, 3
    cvttsd2si rdx, xmm1
    add     rdx, '0'
    mov     [rsi], dl
    inc     rsi
    subsd   xmm0, xmm1

    dec     rcx
    jnz     .f_loop

    mov     rax, rsi
    sub     rax, rdi

    pop     rdx
    pop     rcx
    pop     rbx
    ret
