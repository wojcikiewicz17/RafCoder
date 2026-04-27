; Toroidal 7-state attractor demo in pure x86_64 NASM (Linux)
; - no libc
; - no malloc
; - direct syscalls only
; - SSE2 scalar FP ops
; - 42-step cycle, coupled 7-direction state dynamics

BITS 64
default rel

global _start

section .rodata
    ; EMA weights (alpha = 0.25)
    alpha           dq 0.25
    one_minus_alpha dq 0.75
    one             dq 1.0

    ; normalization constants
    inv_two32       dq 2.3283064365386963e-10    ; 1 / 2^32
    inv_sixtyfour   dq 0.015625                  ; 1 / 64
    inv_seven       dq 0.14285714285714285       ; 1 / 7

    ; base seeds ("vazio fértil" -> non-zero initialization)
    ; includes: 1/phi, sqrt(3)/2, 1/3 and additional irrational-ish seeds
    seeds_a         dq 0.6180339887498948, 0.8660254037844386, 0.3333333333333333
                    dq 0.7071067811865475, 0.2718281828459045, 0.1414213562373095
                    dq 0.5772156649015329

    ; additional seeds (requested: "outras sementes")
    seeds_b         dq 0.3819660112501052, 0.7320508075688772, 0.2360679774997897
                    dq 0.4142135623730950, 0.1618033988749895, 0.0987654320987654
                    dq 0.2192235935955849

    biases          dq 0.00390625, 0.0078125, 0.01171875, 0.015625
                    dq 0.01953125, 0.0234375, 0.02734375

    ; coupling / dependencies across the 7 directions
    dep_gain        dq 0.125
    link_gain       dq 0.0625
    dep_index       db 1, 3, 5, 0, 2, 4, 6

    ; geometric spiral factors r_n = (sqrt(3)/2)^n
    spiral          dq 1.0000000000000000, 0.8660254037844386, 0.7500000000000000
                    dq 0.6495190528383290, 0.5625000000000000, 0.4871392896287468
                    dq 0.4218750000000000

    fnv_offset      dq 0xcbf29ce484222325
    fnv_prime       dq 0x100000001b3

    hex_chars       db '0123456789abcdef'

section .data
    state           times 7 dq 0.0
    tmp_in          times 7 dq 0.0

    coherence_c     dq 0.0
    entropy_h       dq 0.0
    phi_value       dq 0.0

    step_count      dq 0
    last_hash       dq 0

    outbuf          times 16 db '0'
                    db 10

section .text
_start:
    call state_init

    xor r15d, r15d
.loop:
    cmp r15d, 42
    jge .done

    mov [step_count], r15
    call generate_input            ; xmm0 <- input in [0,1), last_hash updated
    call compute_entropy_in        ; xmm6 <- H_in in [0,1]
    call state_update              ; updates state, C, H, phi

    inc r15d
    jmp .loop

.done:
    call print_fingerprint

    mov eax, 60                    ; sys_exit
    xor edi, edi                   ; code 0
    syscall

; ------------------------------------------------------------
; state_init:
; state_i <- frac(seeds_a_i + seeds_b_i)
; initialize C,H,phi coherently from initial state
; ------------------------------------------------------------
state_init:
    mov rsi, seeds_a
    mov rdi, seeds_b
    mov rbx, state
    mov ecx, 7
.init_loop:
    movsd xmm2, [rsi]
    addsd xmm2, [rdi]
    call frac_xmm2
    movsd [rbx], xmm2

    add rsi, 8
    add rdi, 8
    add rbx, 8
    dec ecx
    jnz .init_loop

    ; C = mean(s^2)
    xorpd xmm4, xmm4
    mov rbx, state
    mov ecx, 7
.init_c_loop:
    movsd xmm1, [rbx]
    mulsd xmm1, xmm1
    addsd xmm4, xmm1
    add rbx, 8
    dec ecx
    jnz .init_c_loop
    mulsd xmm4, [inv_seven]
    movsd [coherence_c], xmm4

    ; H starts at 0 (void with max possibility, min committed entropy)
    xorpd xmm0, xmm0
    movsd [entropy_h], xmm0

    ; phi = (1 - H) * C
    movsd xmm1, [one]
    subsd xmm1, [entropy_h]
    mulsd xmm1, [coherence_c]
    movsd [phi_value], xmm1
    ret

; ------------------------------------------------------------
; generate_input:
; FNV-1a over 8 bytes of step_count, map hash -> [0,1)
; return xmm0 = normalized input, store hash in last_hash
; ------------------------------------------------------------
generate_input:
    mov rbx, [fnv_offset]
    mov r8, [step_count]
    mov ecx, 8
.gen_loop:
    movzx edx, r8b
    xor rbx, rdx

    mov rdx, [fnv_prime]
    mov rax, rbx
    mul rdx
    mov rbx, rax

    shr r8, 8
    dec ecx
    jnz .gen_loop

    mov [last_hash], rbx

    mov eax, ebx                   ; lower 32 bits
    cvtsi2sd xmm0, rax
    mulsd xmm0, [inv_two32]
    ret

; ------------------------------------------------------------
; compute_entropy_in:
; H_in ~= popcount(hash) / 64
; return xmm6 in [0,1]
; ------------------------------------------------------------
compute_entropy_in:
    mov rax, [last_hash]
    popcnt rax, rax
    cvtsi2sd xmm6, rax
    mulsd xmm6, [inv_sixtyfour]
    ret

; ------------------------------------------------------------
; state_update:
; 1) x_i <- frac(input + bias_i + dep_gain*state[dep_i] + link_gain*spiral_i)
; 2) C_{t+1} = 0.75*C_t + 0.25*C_in
; 3) H_{t+1} = 0.75*H_t + 0.25*H_in
; 4) phi = (1 - H) * C
; 5) s_i <- frac(0.75*s_i + 0.25*x_i + phi*link_gain*spiral_i)
; ------------------------------------------------------------
state_update:
    ; build tmp input vector and C_in
    xorpd xmm4, xmm4               ; sumsq(tmp)
    xor edx, edx
.build_tmp:
    movapd xmm2, xmm0              ; input
    addsd xmm2, [biases + rdx*8]

    movzx eax, byte [dep_index + rdx]
    movsd xmm1, [state + rax*8]
    mulsd xmm1, [dep_gain]
    addsd xmm2, xmm1

    movsd xmm1, [spiral + rdx*8]
    mulsd xmm1, [link_gain]
    addsd xmm2, xmm1

    call frac_xmm2
    movsd [tmp_in + rdx*8], xmm2

    movapd xmm1, xmm2
    mulsd xmm1, xmm1
    addsd xmm4, xmm1

    inc edx
    cmp edx, 7
    jl .build_tmp

    ; C_in
    mulsd xmm4, [inv_seven]

    ; C = 0.75*C + 0.25*C_in
    movsd xmm1, [coherence_c]
    mulsd xmm1, [one_minus_alpha]
    movapd xmm2, xmm4
    mulsd xmm2, [alpha]
    addsd xmm1, xmm2
    movsd [coherence_c], xmm1

    ; H = 0.75*H + 0.25*H_in (xmm6)
    movsd xmm2, [entropy_h]
    mulsd xmm2, [one_minus_alpha]
    movapd xmm3, xmm6
    mulsd xmm3, [alpha]
    addsd xmm2, xmm3
    movsd [entropy_h], xmm2

    ; phi = (1 - H) * C
    movsd xmm3, [one]
    subsd xmm3, [entropy_h]
    mulsd xmm3, [coherence_c]
    movsd [phi_value], xmm3

    ; state_i <- frac(0.75*s_i + 0.25*tmp_i + phi*link_gain*spiral_i)
    xor edx, edx
.apply_state:
    movsd xmm1, [state + rdx*8]
    mulsd xmm1, [one_minus_alpha]

    movsd xmm2, [tmp_in + rdx*8]
    mulsd xmm2, [alpha]
    addsd xmm1, xmm2

    movsd xmm2, [spiral + rdx*8]
    mulsd xmm2, [link_gain]
    mulsd xmm2, [phi_value]
    addsd xmm1, xmm2

    movapd xmm2, xmm1
    call frac_xmm2
    movsd [state + rdx*8], xmm2

    inc edx
    cmp edx, 7
    jl .apply_state

    ret

; helper: xmm2 <- frac(xmm2) = x - floor(x)
frac_xmm2:
    roundsd xmm3, xmm2, 1          ; floor
    subsd xmm2, xmm3
    ret

; ------------------------------------------------------------
; print_fingerprint:
; FNV-1a over 80 bytes: state(56) + C(8) + H(8) + phi(8)
; prints 16 hex chars + '\n'
; ------------------------------------------------------------
print_fingerprint:
    mov rbx, [fnv_offset]
    mov rsi, state
    mov ecx, 80
.hash_loop:
    movzx eax, byte [rsi]
    xor rbx, rax

    mov rdx, [fnv_prime]
    mov rax, rbx
    mul rdx
    mov rbx, rax

    inc rsi
    dec ecx
    jnz .hash_loop

    ; hex encode hash in outbuf[0..15]
    mov rdi, outbuf
    add rdi, 15
    mov ecx, 16
.hex_loop:
    mov rax, rbx
    and eax, 0x0f
    mov al, [hex_chars + rax]
    mov [rdi], al
    shr rbx, 4
    dec rdi
    dec ecx
    jnz .hex_loop

    mov eax, 1                     ; sys_write
    mov edi, 1                     ; stdout
    mov rsi, outbuf
    mov edx, 17
    syscall
    ret
