# RafCoder Architecture

## 1. Overview

RafCoder is organized as a layered research and runtime repository.

Its current architecture combines:

1. a portable RAFAELOS C core;
2. architecture-specific primitive routes;
3. an Android JNI/NDK bridge;
4. a low-level x86_64 NASM prototype;
5. Python reference tooling;
6. inherited DeepSeek Coder compatibility material;
7. governance and responsible-use documentation.

The architectural goal is to keep experimental semantics, low-level execution and safety governance separated but traceable.

---

## 2. Layer map

```text
┌────────────────────────────────────────────────────────────┐
│ Governance and documentation                               │
│ docs/, docs/governance/                                    │
└────────────────────────────────────────────────────────────┘
                            ↓
┌────────────────────────────────────────────────────────────┐
│ Android application layer                                  │
│ android/app/src/main/java/com/rafcoder/app/MainActivity.kt │
└────────────────────────────────────────────────────────────┘
                            ↓ JNI
┌────────────────────────────────────────────────────────────┐
│ Native bridge                                              │
│ android/app/src/main/cpp/native-lib.cpp                    │
└────────────────────────────────────────────────────────────┘
                            ↓ C ABI
┌────────────────────────────────────────────────────────────┐
│ Portable RAFAELOS core                                     │
│ core/sector.c, core/sector.h                               │
└────────────────────────────────────────────────────────────┘
                            ↓ primitive interface
┌────────────────────────────────────────────────────────────┐
│ Architecture primitives                                    │
│ core/arch/primitives.c                                     │
│ core/arch/x86_64/primitives.S                              │
│ core/arch/aarch64/primitives.S                             │
│ planned: core/arch/armv7/primitives.S                      │
└────────────────────────────────────────────────────────────┘
```

---

## 3. RAFAELOS core contract

The main portable entry point is:

```c
void run_sector(struct state* s, uint32_t iterations);
```

The core is responsible for:

- deterministic payload evolution;
- FNV-style hash mixing;
- CRC32 computation;
- entropy approximation;
- coherence/entropy update;
- geometric invariant extraction;
- compact output vector generation.

The state structure is intentionally compact and suitable for native transport across JNI boundaries.

---

## 4. Android bridge contract

The Android bridge exposes:

```kotlin
external fun nativeMessage(): String
external fun nativeSectorReport(iterations: Int): String
```

The report function executes `run_sector()` and formats the native state for UI inspection.

This is currently an observability bridge, not yet a performance benchmark harness.

A dedicated benchmark harness now exists in `core/benchmark_run_sector.c` with fixed warmup/sample counts and CSV/JSON output, strictly for timing observation of `run_sector()` under controlled iteration load.

---

## 5. Architecture primitive selection

Current CMake selection:

| ABI | Primitive route |
| --- | --- |
| `arm64-v8a` | `core/arch/aarch64/primitives.S` plus shared C sources |
| `armeabi-v7a` | C fallback in `core/arch/primitives.c` |
| `x86_64` | `core/arch/x86_64/primitives.S` plus shared C sources |

The ARM32 route is planned but not yet implemented.

---

## 6. Upstream DeepSeek compatibility

The repository preserves upstream DeepSeek Coder files and documentation for research compatibility.

This layer is not the same as the RAFAELOS native runtime layer. It should be treated as inherited compatibility material with its own license and model-use constraints.

---

## 7. Governance layer

The governance layer defines project constraints for:

- licensing;
- responsible use;
- child protection;
- human dignity;
- epistemic integrity;
- safe abstention/refusal behavior;
- professional release discipline.

This layer is part of the architecture because it constrains what the system may claim, expose or automate.

---

## 8. Implemented vs planned

| Component | Status |
| --- | --- |
| `rafaelos.asm` x86_64 prototype | Implemented |
| `core/sector.c` portable C core | Implemented |
| Android JNI call into C core | Integrated |
| Android APK CI | Implemented |
| ARM64 primitive assembly | Implemented |
| ARM32 primitive assembly | Planned |
| NEON block operations | Planned |
| Reentrant sector workspace | Planned |
| Deterministic snapshot CI | Planned |

---

## 9. F de resolvido

The repository now has a documented architectural identity separating runtime, primitives, Android, upstream compatibility and governance.

## 10. F de gap

The architecture documentation still needs to be connected to tests, CI status badges and pull-request review templates.

## 11. F de next

1. Add deterministic snapshot tests.
2. Add ARM32 primitive implementation.
3. Add PR checklist enforcing architecture and governance distinctions.
