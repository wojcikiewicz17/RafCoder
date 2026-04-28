# Android Native Core Bridge — RAFAELOS acoplado ao RafCoder

Este documento registra o acoplamento inicial entre o projeto Android e o núcleo C do RAFAELOS.

## Estado anterior

A camada Android possuía um `native-lib.cpp` funcional apenas como prova de carga JNI/NDK.

A função nativa retornava uma mensagem fixa:

```cpp
RafCoder Native Core OK (armeabi-v7a + arm64-v8a)
```

Isso provava que a biblioteca nativa carregava, mas ainda não executava o núcleo `core/sector.c`.

## Estado atual

O Android agora compila a biblioteca nativa incluindo o núcleo RAFAELOS:

```text
android/app/src/main/cpp/native-lib.cpp
core/sector.c
core/arch/primitives.c
core/arch/aarch64/primitives.S     // quando ABI = arm64-v8a
core/arch/x86_64/primitives.S      // quando ABI = x86_64
```

Para `armeabi-v7a`, o build usa o fallback C em `core/arch/primitives.c` até existir rota ARM32 dedicada.

## Fluxo atual

```text
MainActivity.kt
   ↓
nativeSectorReport(42)
   ↓
native-lib.cpp
   ↓
run_sector(&s, 42)
   ↓
core/sector.c
   ↓
core/arch/primitives.*
   ↓
relatório exibido na tela Android
```

## Saída exibida pelo app

O app passa a exibir:

- status da bridge JNI;
- número de iterações;
- `hash64`;
- `crc32`;
- `coherence_q16`;
- `entropy_q16`;
- `last_entropy_milli`;
- `last_invariant_milli`;
- `spread_milli`;
- `output_words`;
- `output[0..7]`.

## Arquivos alterados

```text
android/app/src/main/cpp/CMakeLists.txt
android/app/src/main/cpp/native-lib.cpp
android/app/src/main/java/com/rafcoder/app/MainActivity.kt
```

## Decisão técnica

A primeira integração foi feita de forma conservadora:

- sem novas dependências;
- sem binários versionados;
- sem alterar ainda a ABI pública de `core/sector.h`;
- sem trocar a estrutura do app Android;
- sem exigir assinatura para APK release unsigned;
- preservando compatibilidade com `armeabi-v7a` e `arm64-v8a`.

## Gaps restantes

1. Tornar `run_sector()` reentrante/thread-safe.
2. Criar `core/arch/armv7/primitives.S` para ARM32 real.
3. Adicionar rota NEON para blocos.
4. Criar teste determinístico de snapshot.
5. Criar workflow específico para o core C.
6. Comparar baseline Python vs C/ASM.

## F DE RESOLVIDO

O Android deixou de ser apenas uma prova de carga JNI e passou a executar o núcleo RAFAELOS C.

## F DE GAP

O motor ainda usa fallback C em `armeabi-v7a` e ainda precisa de workspace reentrante para paralelismo seguro.

## F DE NEXT

1. Refatorar `core/sector.c` para remover globais estáticos mutáveis.
2. Criar primitivas ARM32 em `core/arch/armv7/primitives.S`.
3. Adicionar teste determinístico com snapshot de `run_sector(42)`.
