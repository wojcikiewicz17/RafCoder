# VECTRAS RMR Bridge Plan (RafCoder core)

## Objetivo
Consumir o núcleo nativo do RafCoder no Vectras-VM-Android por contrato, sem cópia manual de fonte e sem drift entre repositórios.

## Regras de acoplamento
- Não copiar código de Vectras para RafCoder.
- Não copiar código de RafCoder para Vectras sem contrato público versionado.
- A superfície pública mínima é `run_sector(struct state* s, uint32_t iterations)` em `core/sector.h`.

## Modelo A: Biblioteca estática
1. Gerar `core/libsector_core.a` por ABI alvo.
2. Exportar junto com `core/sector.h` e `core/arch/primitives.h`.
3. No Vectras, linkar `libsector_core.a` via CMake/NDK com include apontando para headers do contrato.
4. Travar versão por tag/release e sha256 do artefato.

## Modelo B: Submódulo Git
1. Adicionar RafCoder como submódulo em Vectras (ex.: `third_party/rafcoder`).
2. Vectras compila o core diretamente do submódulo, sem copiar arquivos.
3. Pin por commit SHA específico.
4. Atualização apenas por PR com diff explícito do submódulo.

## Modelo C: Export CMake
1. Expor `add_library(rafcoder_core STATIC ...)` no lado RafCoder.
2. Publicar target de include para `core/`.
3. No Vectras, consumir por `add_subdirectory()` (quando submódulo) ou pacote CMake externo.
4. Garantir que flags de ABI/NDK venham do consumidor, não hardcoded no core.

## Modelo D: Header bridge JNI/C
1. Criar header de bridge no Vectras (`rafcoder_bridge.h`) que encapsula chamadas ao contrato do core.
2. O bridge converte tipos/estado de Vectras para `struct state`.
3. Evitar expor detalhes internos além do contrato público.

## Garantias de compatibilidade
- Snapshot determinístico como gate obrigatório.
- Teste de equivalência das primitives para validar fallback C vs ASM.
- Não declarar NEON como completo enquanto não houver implementação e validação dedicadas.
- Benchmarks de CI são relativos ao host de execução (não universais).

## Artefato recomendado para integração externa
Consumir `rafcoder-core-contract.tar.gz` gerado em CI com:
- `core/sector.h`
- `core/arch/primitives.h`
- sumário de benchmark
- saída de snapshot determinístico
- `sha256sum.txt`
- licenças/notices relevantes
