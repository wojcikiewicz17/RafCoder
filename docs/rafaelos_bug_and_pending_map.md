# RAFAELOS — Mapa de Bugs Lógicos e Pendências

## Bugs lógicos conhecidos

### BL-001 — Dependência de SSE4.1 (`roundsd`)
- **Local:** `mod_one`, `f64_to_dec4` em `rafaelos.asm`.
- **Risco:** hardware legado sem SSE4.1 falha na execução.
- **Impacto:** incompatibilidade de arquitetura.
- **Ação:** criar fallback SSE2 para trunc/floor sem `roundsd`.
- **Status:** aberto.

### BL-002 — Aproximação de entropia por `H ≈ 1-C`
- **Local:** `calc_phi`.
- **Risco:** simplificação pode distorcer análise teórica em cenários não uniformes.
- **Impacto:** divergência entre formalismo completo e núcleo mínimo.
- **Ação:** incluir modo opcional de cálculo entrópico mais fiel (ainda sem libc).
- **Status:** aberto.

### BL-003 — Conversão decimal simplificada
- **Local:** `f64_to_dec4`.
- **Risco:** sem arredondamento bancário, pode haver viés de impressão.
- **Impacto:** observabilidade textual, não estado interno.
- **Ação:** implementar arredondamento determinístico de 4 casas.
- **Status:** aberto.

## Pendências técnicas

1. Exportar fingerprint FNV final junto do resumo de grupos.
2. Adicionar alvo `make rafaelos` dedicado com flags rígidas.
3. Criar suíte mínima de verificação determinística por snapshot de saída.
4. Versão “strict no-SSE4.1” para compatibilidade ampliada.
5. Documento de threat model para uso operacional.

## Pendências de documentação

1. Matriz de compatibilidade por microarquitetura x86_64.
2. Guia de integração com pipelines de CI sem dependências externas.
3. Tabela de rastreabilidade equação->rotina de assembly.

