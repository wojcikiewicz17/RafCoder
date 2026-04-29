# RafCoder Architecture Baseline

## 1. Architectural Scope
RafCoder is structured as an integrated runtime system with explicit separation between native execution, platform integration, inherited research material, and governance constraints.

Primary layers:
1. RAFAELOS portable runtime core (C)
2. Architecture-specific primitive layer (C + assembly)
3. Android JNI/NDK integration layer
4. Compatibility/research layer inherited from DeepSeek material
5. Governance and operational documentation layer

## 2. Runtime Topology
```text
MainActivity (Kotlin)
  -> JNI bridge (native-lib.cpp)
  -> run_sector(struct state*, uint32_t)
  -> core execution + primitive dispatch
  -> formatted native report to Android UI
```

## 3. Core Contract
Primary callable:
```c
void run_sector(struct state* s, uint32_t iterations);
```

Responsibilities:
- deterministic payload transformation;
- entropy/coherence update;
- invariant scoring and compact output generation;
- architecture primitive usage through stable interfaces.

## 4. Primitive Routing
Current routing behavior:
- `arm64-v8a`: assembly path available (`core/arch/aarch64/primitives.S`)
- `armeabi-v7a`: C fallback (`core/arch/primitives.c`)
- `x86_64`: assembly route for host-side/core studies (`core/arch/x86_64/primitives.S`)

Planned:
- dedicated ARM32 assembly route for `armeabi-v7a`

## 5. Android Delivery Contract
Official mobile outputs require:
- build success for `armeabi-v7a` and `arm64-v8a`;
- APK generation in debug and release modes;
- signed release generation when signing material is available.

Reference process: `docs/android_native_build_release.md`.

## 6. Repository Hygiene Standard
Project root files must remain intentional and classified under one of the following:
- runtime source;
- build/release infrastructure;
- documentation/governance;
- compatibility/research assets.

Ad-hoc exploratory notes must be relocated to `docs/` or removed to avoid ambiguity in the release chain.
