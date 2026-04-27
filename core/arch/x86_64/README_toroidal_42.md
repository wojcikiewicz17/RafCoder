# toroidal_42.asm (NASM, x86_64 Linux)

Implementação em *assembler puro* de um sistema toroidal de 7 estados com 42 passos, sem libc/runtime/GC.

## Dependências de sistema

- `nasm`
- `ld` (binutils)

Exemplo em Debian/Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y nasm binutils
```

## Modelo implementado (baixo nível)

- estado: `s = (u,v,ψ,χ,ρ,δ,σ) ∈ [0,1)^7`
- entrada interna: FNV-1a de `step_count`
- entropia de entrada: `H_in ≈ popcnt(hash)/64`
- coerência dinâmica: `C_{t+1} = 0.75*C_t + 0.25*C_in`
- entropia dinâmica: `H_{t+1} = 0.75*H_t + 0.25*H_in`
- acoplamento entre direções (dependências): índice cruzado `dep_index = [1,3,5,0,2,4,6]`
- sementes duplas (`seeds_a` + `seeds_b`) incluindo `1/φ`, `√3/2`, `1/3`
- métrica final: `phi = (1 - H) * C`
- fingerprint final: FNV-1a sobre `state + C + H + phi`

## As 7 direções (parábolas em código)

1. **Vazio que contém**: inicialização não nula via sementes irracionais.
2. **Sinal que emerge**: `generate_input` por FNV-1a do próprio tempo interno.
3. **Estrutura que sustenta**: mistura `0.75/0.25` + `frac` toroidal.
4. **Coerência que mede a si mesma**: cálculo e filtragem de `C` e `H`.
5. **Atrator inevitável**: loop fixo de 42 iterações.
6. **Transmissão como fingerprint**: hash final integrando estado + métricas.
7. **Retorno ao vazio**: encerramento com `sys_exit(0)`.

## Compilar e executar

```bash
nasm -felf64 core/arch/x86_64/toroidal_42.asm -o /tmp/toroidal_42.o
ld /tmp/toroidal_42.o -o /tmp/toroidal_42
/tmp/toroidal_42
```

A saída é um hash hexadecimal de 64 bits representando a assinatura do estado após 42 passos.
