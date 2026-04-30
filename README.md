# RafCoder

**RAFAELOS native runtime research, low-level execution core and Android NDK bridge.**

RafCoder is a research-oriented repository that combines a deterministic low-level execution core, architecture-specific primitive routes, Android JNI/NDK integration, benchmark artifacts and legacy DeepSeek Coder compatibility material.

The current engineering direction is practical and measurable: compact state, explicit invariants, deterministic outputs, reproducible builds, ABI-aware native execution and documented safety constraints.

---

## 1. Project identity

RafCoder is not only a language-model fork. It is organized as a native runtime research stack with clear boundaries between executable code, inherited research material, mobile integration and governance.

| Layer | Purpose | Status |
| --- | --- | --- |
| RAFAELOS core | Deterministic state kernel in portable C. | Active |
| Architecture primitives | C fallback plus selected assembly routes. | Active |
| Android native bridge | Kotlin/JNI/NDK bridge for Android execution. | Active |
| Benchmarks and CI artifacts | Snapshot, reentrancy, primitive equivalence and timing artifacts. | Active |
| DeepSeek legacy compatibility | Upstream model/evaluation/fine-tuning material retained for research compatibility. | Preserved |
| Governance | Safety, license, dignity and responsible-use documentation. | Active |

---

## 2. Current technical status

### Implemented

- Low-level x86_64 NASM prototype in `rafaelos.asm`.
- Portable C core in `core/sector.c`.
- Public core state/API in `core/sector.h`.
- Architecture primitive interface in `core/arch/primitives.h`.
- C fallback primitives in `core/arch/primitives.c`.
- x86_64 assembly primitives in `core/arch/x86_64/primitives.S`.
- AArch64 assembly primitives in `core/arch/aarch64/primitives.S`.
- ARMv7 assembly primitives for `armeabi-v7a` in `core/arch/armv7/primitives.S`.
- Primitive equivalence test in `core/test_primitives_equivalence.c`.
- Deterministic snapshot test in `core/test_sector_snapshot.c`.
- Reentrancy/thread-safety regression test in `core/test_sector_reentrancy.c`.
- Native benchmark executable in `core/benchmark_run_sector.c` with CSV and JSON output.
- Android project in `android/`.
- JNI bridge calling `run_sector(42)` and displaying native output.
- Android CI workflow for APK and native library validation.
- Core CI workflow for primitive equivalence, deterministic snapshot and reentrancy validation.
- Core benchmark workflow that uploads `.json`, `.csv`, SHA256, binary-size and timing artifacts.
- Python reference benchmark for 40-sector grouping.
- Governance documents for licensing, safety, child protection and responsible use.

### Not yet complete

- NEON-optimized block routes for ARM32/ARM64.
- Device-level Android benchmark matrix for `armeabi-v7a` and `arm64-v8a`.
- Formal cross-runtime comparison: Python reference vs portable C vs x86_64 ASM vs ARMv7 ASM vs AArch64 ASM.
- Release-grade signed APK distribution policy beyond CI artifact generation.

---

## 3. Repository map

```text
android/                         Android app, Gradle, JNI and CMake bridge
core/                            Portable RAFAELOS C core, tests and benchmark executable
core/arch/                       C fallback and architecture-specific assembly routes
docs/                            Technical, operational and governance documentation
docs/governance/                 Safety, license, human protection and responsible-use docs
scripts/                         Build helper scripts
tools/                           Python reference and benchmark utilities
.github/workflows/               CI, Android build and benchmark artifact workflows
rafaelos.asm                     x86_64 NASM low-level prototype
requirements.txt                 Python research/evaluation dependencies
LICENSE-CODE                     Code license inherited from upstream base
LICENSE-MODEL                    Model license inherited from upstream base
```

---

## 4. RAFAELOS core contract

Primary callable:

```c
void run_sector(struct state* s, uint32_t iterations);
```

The state tracks:

- coherence in Q16 fixed-point form;
- entropy in Q16 fixed-point form;
- 64-bit hash state;
- CRC32;
- last entropy score;
- last invariant score;
- compact output vector.

The implementation uses deterministic byte payload evolution, FNV-style mixing, local CRC32, entropy approximation, coherence/entropy update and geometric invariant extraction.

---

## 5. Primitive routing

| Target | Route |
| --- | --- |
| unsupported/other host | C fallback |
| Linux x86_64 host | `core/arch/x86_64/primitives.S` |
| Android `armeabi-v7a` | `core/arch/armv7/primitives.S` |
| Android `arm64-v8a` | `core/arch/aarch64/primitives.S` |

Primitive coverage:

```text
core_xor_u64
core_mul_u64
core_rotl_u64
core_load_u8
core_store_u8
core_xor_block
```

Equivalence validation:

```bash
make -C core test_primitives_equivalence
./core/test_primitives_equivalence
```

---

## 6. Android native bridge

Current flow:

```text
MainActivity.kt
  -> nativeSectorReport(42)
  -> native-lib.cpp
  -> run_sector(&s, 42)
  -> core/sector.c
  -> core/arch/primitives.*
  -> report displayed in the Android UI
```

Supported Android ABIs:

- `armeabi-v7a`
- `arm64-v8a`

Build:

```bash
./scripts/android_build_matrix.sh
```

---

## 7. Core validation and benchmark artifacts

Core validation:

```bash
make -C core all
make -C core test_primitives_equivalence && ./core/test_primitives_equivalence
make -C core test_snapshot && ./core/test_snapshot
make -C core test_reentrancy && ./core/test_reentrancy
```

Benchmark:

```bash
make -C core benchmark_run_sector
./core/benchmark_run_sector --iterations 1000 --format csv
./core/benchmark_run_sector --iterations 1000 --format json
```

Workflow:

```text
.github/workflows/core-benchmarks.yml
```

Published artifact group:

```text
rafcoder-core-benchmarks
```

Artifact contents include:

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

CI measurements are runner-relative and intended for regression tracking, not universal hardware claims.

### Top-56 runtime artifact workflow (GCC/Clang)

Workflow:

```text
.github/workflows/benchmark-top56.yml
```

Current behavior:

- triggers on `workflow_dispatch`, `push` to `main` and `pull_request` for `core/**`, `scripts/benchmark_sector_top56.py` and the workflow file itself;
- runs a compiler matrix (`gcc`, `clang`) with `fail-fast: false`;
- generates per-compiler benchmark artifact folders (`benchmark_artifacts_gcc`, `benchmark_artifacts_clang`);
- enforces deterministic snapshot assertions by default (escape hatch: `--allow-nondeterminism`);
- emits `benchmark_top56.md`, `benchmark_top56.json`, `benchmark_snapshots.json`, `benchmark_matrix.csv`, `build_stdout.txt`, `build_stderr.txt`, `benchmark_sector_harness.c`;
- builds runtime packages `rafcoder-sector-runtime-linux-x86_64-gcc.tar.gz` and `rafcoder-sector-runtime-linux-x86_64-clang.tar.gz`;
- emits SHA256 files with matching names (`.tar.gz.sha256`);
- generates `ARTIFACT_MANIFEST.md` and `ARTIFACT_MANIFEST.json` for each runtime package;
- runs a smoke test (`rafcoder-sector-runtime 42 10`) and stores output in `runtime_smoke_test.txt`;
- uploads separate benchmark and runtime artifacts per compiler.

Published artifact names:

```text
rafcoder-top56-benchmark-report-gcc
rafcoder-top56-benchmark-report-clang
rafcoder-sector-runtime-linux-x86_64-gcc
rafcoder-sector-runtime-linux-x86_64-clang
```

---

## 8. Python reference benchmark

Reference script:

```text
tools/cron_fidelity_grouping.py
```

Example:

```bash
python tools/cron_fidelity_grouping.py --iterations 1000 --seed 42
```

This script is a research/reference baseline, not the performance-critical runtime.

---

## 9. Governance and safety

RafCoder treats safety and governance as engineering requirements.

Relevant documents:

- `SECURITY.md`
- `CONTRIBUTING.md`
- `CODE_OF_CONDUCT.md`
- `docs/governance/license_and_safety_matrix.md`
- `docs/governance/research_only_and_noncommercial_policy.md`
- `docs/governance/child_protection_and_global_inclusion_standard.md`
- `docs/governance/human_dignity_and_epistemic_integrity.md`
- `docs/repository_hygiene.md`

Core principles:

- preserve deterministic behavior where claimed;
- distinguish implemented, tested, planned and experimental behavior;
- keep native core dependencies minimal;
- avoid committed binary artifacts;
- preserve upstream license notices;
- document limitations honestly;
- keep child protection and human dignity as non-negotiable constraints.

---

## 10. Roadmap

### F de resolvido

- RAFAELOS low-level prototype exists.
- Portable C core exists.
- x86_64, ARMv7 and AArch64 assembly primitive routes exist.
- Android JNI bridge calls the C core.
- Snapshot, reentrancy and primitive equivalence tests exist.
- Core benchmark artifact workflow exists.
- Governance documentation exists.

### F de gap

- NEON routes are not yet implemented.
- Android device-level benchmark artifacts are not yet produced.
- Cross-runtime benchmark comparison is not yet formalized.
- Release publication policy still needs hardening.

### F de next

1. Add NEON block paths for ARM32/ARM64.
2. Add Android runtime benchmark instrumentation for both official ABIs.
3. Extend benchmark artifacts to compare Python, C fallback, x86_64 ASM, ARMv7 ASM and AArch64 ASM.

---

## 11. Upstream notice

This repository contains material derived from the DeepSeek Coder open-source release. License notices and model-use restrictions must be preserved according to `LICENSE-CODE`, `LICENSE-MODEL` and the applicable upstream terms.

RafCoder-specific additions focus on native runtime research, RAFAELOS low-level execution, Android integration, benchmark artifacts, operational documentation and safety governance.

---

## 12. Citation for upstream DeepSeek Coder

```bibtex
@misc{deepseek-coder,
  author = {Daya Guo, Qihao Zhu, Dejian Yang, Zhenda Xie, Kai Dong, Wentao Zhang, Guanting Chen, Xiao Bi, Y. Wu, Y.K. Li, Fuli Luo, Yingfei Xiong, Wenfeng Liang},
  title = {DeepSeek-Coder: When the Large Language Model Meets Programming -- The Rise of Code Intelligence},
  journal = {CoRR},
  volume = {abs/2401.14196},
  year = {2024},
  url = {https://arxiv.org/abs/2401.14196}
}
```

---

## 13. ZIP installation helper

Use the helper below to decode/extract the single root `.zip`, when present:

```bash
./scripts/install_root_zip.sh
```

Optional target directory:

```bash
./scripts/install_root_zip.sh android/
```
