# RafCoder

**RAFAELOS native runtime research, low-level execution core and Android NDK bridge.**

RafCoder is a research-oriented repository that combines a low-level deterministic execution core, architecture-specific primitives, Android JNI/NDK integration, and legacy DeepSeek Coder compatibility material.

The project is maintained with a technical focus on reproducibility, portable native execution, explicit state transitions, safety governance and human dignity by design.

---

## 1. Project identity

RafCoder is not only a language-model fork. In its current form, the repository is organized around four complementary layers:

| Layer | Purpose |
| --- | --- |
| RAFAELOS core | Low-level deterministic state kernel in C/ASM. |
| Architecture primitives | Portable primitive layer with C fallback and selected assembly routes. |
| Android native bridge | JNI/NDK application bridge for `armeabi-v7a` and `arm64-v8a`. |
| DeepSeek legacy compatibility | Upstream model/evaluation/fine-tuning material preserved for research compatibility. |

The active engineering direction is the RAFAELOS native runtime: compact state, deterministic outputs, low overhead, explicit invariants and architecture-aware execution.

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
- Android project in `android/`.
- JNI bridge calling `run_sector(42)` and displaying native output.
- CI workflow for Android APK artifacts.
- GitHub Actions workflow that builds a Linux x86_64 runtime binary during CI execution and uploads benchmark/report artifacts.
- Python reference benchmark for 40-sector grouping.
- Governance documents for licensing, safety, child protection and responsible use.

### Not yet complete

- Dedicated ARM32 assembly primitives for `armeabi-v7a`.
- NEON-optimized routes for block operations.
- Reentrant/thread-safe workspace for `run_sector()`.
- Deterministic C snapshot test in CI.
- Formal benchmark comparison between Python, C and assembly outputs.
- Android ARM64/ARM32 runtime binary artifact packages from the benchmark workflow.

---

## 3. Repository map

```text
android/                         Android app, Gradle, JNI and CMake bridge
core/                            Portable RAFAELOS C core
core/arch/                       Architecture primitives and assembly routes
docs/                            Technical, operational and governance documentation
docs/governance/                 Safety, license, human protection and responsible-use docs
scripts/                         Build helper scripts
tools/                           Python reference and benchmark utilities
rafaelos.asm                     x86_64 NASM low-level prototype
requirements.txt                 Python research/evaluation dependencies
LICENSE-CODE                     Code license inherited from upstream base
LICENSE-MODEL                    Model license inherited from upstream base
```

---

## 4. RAFAELOS core

The portable core is centered on:

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

## 5. Android native bridge

The Android app now loads the native library and calls the RAFAELOS C core through JNI.

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

Supported Android ABIs in the Gradle configuration:

- `armeabi-v7a`
- `arm64-v8a`

Current behavior:

- `arm64-v8a` can use the AArch64 primitive assembly route.
- `armeabi-v7a` currently uses the C fallback until dedicated ARM32 primitives are added.

Build:

```bash
./scripts/android_build_matrix.sh
```

---

## 6. Native prototype build

The standalone x86_64 NASM prototype can be built with:

```bash
nasm -f elf64 rafaelos.asm -o rafaelos.o
ld rafaelos.o -o rafaelos
./rafaelos
```

This prototype is useful as a low-level reference, but the portable C core is the preferred integration target for Android and cross-architecture work.

---

## 7. Top-56 runtime benchmark artifacts

The repository includes a GitHub Actions workflow that builds a native runtime binary during CI execution, runs a benchmark matrix and uploads both the runtime package and specialized reports as artifacts.

Workflow:

```text
.github/workflows/benchmark-top56.yml
```

Generator:

```text
scripts/benchmark_sector_top56.py
```

Detailed documentation:

```text
docs/benchmark_top56_runtime_artifacts.md
```

The workflow runs on `push`, `pull_request` and manual `workflow_dispatch`. It compiles the sector runtime inside the Actions runner, executes a smoke test, packages the runtime and uploads two artifact groups:

```text
rafcoder-top56-benchmark-report
rafcoder-sector-runtime-linux-x86_64
```

The report artifact contains Markdown, JSON and CSV outputs for up to 56 metrics covering:

- throughput;
- timing stability;
- deterministic output snapshots;
- binary size;
- section size;
- symbol count;
- portability;
- core state quality;
- scaling behavior;
- CI reproducibility;
- audit readiness.

The runtime artifact contains:

```text
rafcoder-sector-runtime-linux-x86_64.tar.gz
rafcoder-sector-runtime-linux-x86_64.tar.gz.sha256
ARTIFACT_MANIFEST.md
runtime_smoke_test.txt
```

Manual run path:

```text
GitHub -> Actions -> Benchmark Top-56 Runtime Binary Artifacts -> Run workflow
```

These measurements are CI-runner-relative and intended for regression tracking and artifact review. They are not universal hardware claims.

---

## 8. Python reference benchmark

A lightweight Python reference exists at:

```text
tools/cron_fidelity_grouping.py
```

Example:

```bash
python tools/cron_fidelity_grouping.py --iterations 1000 --seed 42
```

This script is intended as a research/reference baseline, not as the performance-critical runtime.

---

## 9. Governance and safety

RafCoder treats safety and governance as engineering requirements, not cosmetic documentation.

Relevant documents:

- `docs/governance/license_and_safety_matrix.md`
- `docs/governance/research_only_and_noncommercial_policy.md`
- `docs/governance/child_protection_and_global_inclusion_standard.md`
- `docs/governance/human_dignity_and_epistemic_integrity.md`
- `docs/repository_hygiene.md`

Core principles:

- human dignity is a non-negotiable constraint;
- child protection has highest operational priority;
- refusal, abstention and useful silence are valid outputs when they prevent falsehood, unsafe continuation or human harm;
- technical claims must remain testable, traceable and revisable;
- safety controls must be documented and auditable.

---

## 10. Development discipline

Every material change should preserve:

1. deterministic behavior where claimed;
2. clear separation between research, runtime and governance layers;
3. no unnecessary dependencies in the native core;
4. no committed binary artifacts;
5. documented limitations and known gaps;
6. license notices inherited from upstream components;
7. human and child safety constraints.

Preferred implementation style:

- small patches;
- measurable behavior;
- explicit state;
- reproducible build path;
- documented trade-offs;
- test before optimization.

---

## 11. Roadmap

### F de resolvido

- RAFAELOS low-level prototype exists.
- Portable C core exists.
- Android JNI bridge calls the C core.
- Governance documentation exists.
- Android CI artifact workflow exists.
- Top-56 benchmark workflow builds a Linux x86_64 runtime binary and publishes reports/artifacts.

### F de gap

- ARM32 dedicated primitive route is still missing.
- `run_sector()` still needs a reentrant workspace.
- CI must validate deterministic behavior, not only build artifacts.
- README/upstream identity must continue being curated as the project evolves.
- Top-56 artifact workflow still needs Android ARM64/ARM32 packages and multi-runtime baselines.

### F de next

1. Add deterministic C snapshot tests for `run_sector(42)`.
2. Refactor `run_sector()` to remove mutable global scratch state.
3. Add `core/arch/armv7/primitives.S` and later NEON block paths.
4. Extend benchmark artifacts to compare Python, portable C, x86_64 ASM and Android native routes.

---

## 12. Upstream notice

This repository contains material derived from the DeepSeek Coder open-source release. License notices and model-use restrictions must be preserved according to `LICENSE-CODE`, `LICENSE-MODEL` and the applicable upstream terms.

RafCoder-specific additions focus on native runtime research, RAFAELOS low-level execution, Android integration, operational documentation and safety governance.

---

## 13. Citation for upstream DeepSeek Coder

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

## 14. Instalação de ZIP da raiz

Use o script abaixo para decodificar/descompactar automaticamente o único `.zip` presente na raiz do repositório e instalar no projeto:

```bash
./scripts/install_root_zip.sh
```

Opcionalmente, informe um diretório de destino:

```bash
./scripts/install_root_zip.sh android/
```

---

## 15. Semantic pipeline 56x auditor

A standalone semantic build auditor is available at `semantic_pipeline_56x_v3.sh` with source separated in `core.c`.

It compiles a flag matrix, emits build artifacts to `build/`, evidences to `reports/`, and records:

- binary size and SHA256;
- ASM dump, per-function hashes and function-level assembly extracts;
- libc/runtime dynamic dependency checks (`NEEDED`) and PLT call checks;
- SIMD/FMA instruction detection by disassembly scan;
- GCC optimization reports;
- runtime measurement and real return code without masking failures.

Run:

```bash
./semantic_pipeline_56x_v3.sh
```
