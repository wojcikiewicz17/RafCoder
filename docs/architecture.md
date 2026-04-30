# RafCoder Architecture Baseline

## 1. Purpose

This document defines the current technical architecture of RafCoder as a native runtime research repository. It separates implemented behavior from planned optimization work so the repository remains auditable, navigable and safe to extend.

## 2. Architectural Scope

RafCoder is structured as an integrated runtime system with explicit separation between native execution, platform integration, inherited research material, benchmark evidence and governance constraints.

| Layer | Responsibility | Current status |
| --- | --- | --- |
| RAFAELOS portable runtime core | Deterministic state transition kernel in C. | Implemented |
| Architecture primitive layer | Stable primitive ABI with C fallback and assembly routes. | Implemented |
| Android JNI/NDK bridge | Mobile bridge from Kotlin to native RAFAELOS core. | Implemented |
| Core validation and benchmarks | Snapshot, reentrancy, primitive equivalence and timing artifacts. | Implemented |
| Compatibility/research material | DeepSeek-derived research assets preserved under upstream notices. | Preserved |
| Governance and safety | Security, license, human dignity and responsible-use constraints. | Implemented |

## 3. Runtime Topology

```text
MainActivity.kt
  -> System.loadLibrary("rafcoder_native")
  -> nativeSectorReport(iterations)
  -> native-lib.cpp
  -> run_sector(struct state*, uint32_t)
  -> core/sector.c
  -> core/arch/primitives.h
  -> architecture route or C fallback
  -> formatted native report to Android UI
```

## 4. Core Contract

Primary callable:

```c
void run_sector(struct state* s, uint32_t iterations);
```

Responsibilities:

- deterministic payload transformation;
- entropy/coherence update;
- invariant scoring and compact output generation;
- architecture primitive usage through stable interfaces;
- reentrant execution when each caller owns its `state` instance.

The core is intentionally compact and dependency-light. It is suitable for host tests, Android NDK integration and low-level architecture experiments.

## 5. Primitive Routing

Stable primitive surface:

```text
core_xor_u64
core_mul_u64
core_rotl_u64
core_load_u8
core_store_u8
core_xor_block
```

Current routing behavior:

| Target | Route | Notes |
| --- | --- | --- |
| Generic unsupported host | `core/arch/primitives.c` | Portable C fallback. |
| Linux `x86_64` host | `core/arch/x86_64/primitives.S` | Host-side assembly route. |
| Android `armeabi-v7a` / ARMv7 | `core/arch/armv7/primitives.S` | Dedicated ARM32 route. |
| Android `arm64-v8a` / AArch64 | `core/arch/aarch64/primitives.S` | Dedicated AArch64 route. |

Validation target:

```bash
make -C core test_primitives_equivalence
./core/test_primitives_equivalence
```

The equivalence test compares primitive behavior against reference C semantics for XOR, multiplication, rotation, byte load/store and block XOR.

## 6. Android Delivery Contract

Official Android output scope:

- `armeabi-v7a`
- `arm64-v8a`

Build expectations:

- native `.so` output exists for each official ABI;
- debug APK artifacts are generated per ABI;
- unsigned release APK artifacts are generated per ABI;
- signed release APK artifacts are generated per ABI when signing secrets are available;
- SHA256 checksum artifacts are uploaded for traceability.

Reference process: `docs/android_native_build_release.md`.

## 7. CI and Evidence Chain

Core CI:

```text
.github/workflows/core-ci.yml
```

Required checks:

- static core build;
- primitive equivalence test;
- deterministic snapshot test;
- reentrancy test.

Benchmark artifact workflow:

```text
.github/workflows/core-benchmarks.yml
```

Published artifact group:

```text
rafcoder-core-benchmarks
```

Expected benchmark files:

- `run-sector.csv`
- `run-sector.json`
- `metrics-summary.csv`
- `metrics-manifest.json`
- `binary-size.csv`
- `sha256sum.txt`
- `abi-build-metadata.csv`
- `snapshot.txt`
- `reentrancy.txt`
- `primitives-equivalence.txt`

CI measurements are valid for regression tracking inside the same CI environment. They are not universal device-performance claims.

## 8. Current Limitations

- NEON-optimized block routes are not yet implemented.
- Device-level Android runtime benchmarks are not yet produced.
- Cross-runtime comparison between Python reference, portable C, x86_64 ASM, ARMv7 ASM and AArch64 ASM is not yet formalized.
- Signed release publication is conditional on repository secrets and remains a CI artifact process, not a full distribution policy.

## 9. Repository Hygiene Standard

Project root files must remain intentional and classified under one of the following:

- runtime source;
- build/release infrastructure;
- documentation/governance;
- compatibility/research assets.

Ad-hoc exploratory notes must be relocated to `docs/` or removed to avoid ambiguity in the release chain.

## 10. Next Architecture Targets

1. Add NEON block paths for ARM32 and ARM64.
2. Add Android runtime benchmark instrumentation for both official ABIs.
3. Extend benchmark artifacts to compare Python, C fallback, x86_64 ASM, ARMv7 ASM and AArch64 ASM.
