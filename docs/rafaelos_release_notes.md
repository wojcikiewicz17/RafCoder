# RAFAELOS — Release Notes

## v0.2.0 (current)

### Implementado
- Agrupamento por resultado (`phi`) em três buckets: LOW/MID/HIGH.
- Contadores agregados em memória fixa (`group_low`, `group_mid`, `group_high`).
- Emissão de resumo final coletivo no stdout ao final dos 42 passos.
- Manual operacional vivo (IA + Humanos) com metodologia obrigatória.
- Mapa de bugs e pendências versionado.

### Técnica
- Mantido: sem libc, sem heap no núcleo, sem GC.
- Mantido: syscalls Linux diretas, estado em `.bss`, constantes em `.rodata`.

### Riscos conhecidos
- Dependência de SSE4.1 para `roundsd`.
- Aproximação de entropia simplificada.

## v0.1.0

### Implementado
- Núcleo toroidal `T^7` base em NASM x86_64.
- Atualização EMA com `α=0.25`.
- Geração determinística de input por hash FNV.
- Cálculo de `phi` e saída textual por passo.
- Documento formal unificado com 50 equações.

