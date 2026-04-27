# RAFAELOS — Manual Operacional Vivo (IA + Humanos)

## Objetivo

Este manual define o caminho vivo de evolução do núcleo RAFAELOS com disciplina obrigatória:

1. Codificar no fonte real.
2. Medir resultado real.
3. Documentar realizado real (sem placeholders).
4. Registrar pendências, bugs e roadmap.
5. Liberar release notes rastreáveis.

## 1) Dois pontos de vista: IA e Humanos

### 1.1 Perspectiva IA (executor formal)

- Processa por invariantes, estados e transições.
- Deve priorizar:
  - determinismo,
  - custo computacional previsível,
  - ausência de overhead estrutural,
  - preservação do contrato matemático em `T^7`.
- Ciclo obrigatório:
  - `generic -> identificar -> transmutar -> adaptação absoluta -> endereçamento/registradores/estado`.

### 1.2 Perspectiva Humana (executor contextual)

- Processa por semântica, intenção e impacto operacional.
- Deve priorizar:
  - legibilidade técnica,
  - segurança operacional,
  - rastreabilidade de decisão,
  - transferência de conhecimento entre equipes.
- Ciclo obrigatório:
  - problema real -> hipótese -> patch mínimo -> validação -> documentação -> revisão.

## 2) Fonte vs Dados codificados

### 2.1 O que é código-fonte (fonte da verdade)

- `rafaelos.asm`: fonte executável de baixo nível.
- `docs/rafaelos_unified_map.md`: contrato matemático das 50 equações.
- `README.md`: acesso primário no root e instruções de integração.

### 2.2 O que é dado codificado (resultado)

- saída textual por passo (`STEP`, `PHI`),
- contadores agregados por bucket (`LOW/MID/HIGH`),
- artefatos de build (`.o`, binário) somente transitórios.

## 3) Metodologia obrigatória de implementação

1. **Sem heap no núcleo**: apenas `.bss`/`.rodata`/registradores.
2. **Sem libc**: syscalls Linux diretas.
3. **Sem GC** e sem runtime externo.
4. **Sem abstrações desnecessárias**: operadores inline preferenciais.
5. **Sem dependências externas** para o binário do núcleo.
6. **Flags compiler-friendly** para reduzir fricção hardware/SO.

## 4) Build/flags recomendados

```bash
nasm -f elf64 -Ox -w+all -w+error rafaelos.asm -o rafaelos.o
ld -O2 rafaelos.o -o rafaelos
```

Observações:

- `-w+error` força tratamento de warning como erro na montagem.
- `-Ox` no NASM reduz fricção na expansão e layout de código.
- `-O2` no `ld` melhora organização final do binário.

## 5) Agrupamento por resultado (coletivo)

O modelo agrupa `phi` em buckets operacionais:

- LOW: `[0.0000, 0.1000)`
- MID: `[0.1000, 0.3000)`
- HIGH: `[0.3000, 1.0000)`

Esse agrupamento fornece leitura coletiva dos 42 passos do atrator e reduz ruído para análise profissional de estabilidade.

## 6) Segurança operacional e técnica de trabalho

Checklist por entrega:

- [ ] Build limpo sem warning.
- [ ] Execução local concluída.
- [ ] Agrupamento final emitido no stdout.
- [ ] Bugs lógicos revisados e mapa atualizado.
- [ ] Pendências revisadas e roadmap atualizado.
- [ ] Release notes atualizadas com o que foi realmente feito.

## 7) Convergência do conhecimento

No contexto multilíngue/multissensorial, o conhecimento carregado no sistema é o invariante dinâmico entre formas:

- estado toroidal,
- coerência-entropia,
- assinatura espectral,
- integridade hash/merkle,
- rastreabilidade de transição.

