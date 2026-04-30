# Benchmark Top-56 Runtime Binary Artifacts

This document describes the GitHub Actions workflow that builds the RAFAELOS/RafCoder sector runtime binary during CI execution, runs benchmark analysis, asserts deterministic snapshots, and publishes both runtime packages and specialized reports as workflow artifacts.

## Workflow

```text
.github/workflows/benchmark-top56.yml
```

The workflow is named:

```text
Benchmark Top-56 Runtime Binary Artifacts
```

## Purpose

The workflow turns the native core into an auditable CI artifact pipeline:

```text
push / pull_request / manual execution
  -> checkout repository
  -> install native toolchains
  -> generate benchmark harness
  -> compile runtime binary inside GitHub Actions
  -> execute benchmark matrix
  -> assert deterministic snapshots per case
  -> run smoke test
  -> generate Top-56 report
  -> package runtime binary
  -> generate SHA256 checksum
  -> generate Markdown and JSON manifests
  -> upload GitHub artifacts
```

The binary is generated during the workflow runtime. It is not committed to the repository.

## Compiler matrix

The workflow currently runs the same benchmark artifact pipeline with:

| Compiler | Artifact suffix |
| --- | --- |
| `gcc` | `gcc` |
| `clang` | `clang` |

The matrix is configured with `fail-fast: false`, so a failure in one compiler job does not hide the result of the other compiler job.

## Trigger modes

The workflow runs on:

- `workflow_dispatch`: manual execution from the GitHub Actions tab;
- `push` to `main`, when relevant core, benchmark or workflow files change;
- `pull_request`, when relevant core, benchmark or workflow files change.

Relevant paths:

```text
core/**
scripts/benchmark_sector_top56.py
.github/workflows/benchmark-top56.yml
```

## Manual inputs

Manual runs support these inputs:

| Input | Default | Meaning |
| --- | ---: | --- |
| `repeats` | `2000` | Number of benchmark repeats per iteration case. |
| `samples` | `5` | Number of samples per iteration case. |
| `cases` | `1,7,42,128,512,2048` | Comma-separated sector iteration cases. |

## Runtime binary packages

The workflow creates one package per compiler:

```text
rafcoder-sector-runtime-linux-x86_64-gcc.tar.gz
rafcoder-sector-runtime-linux-x86_64-clang.tar.gz
```

Each package contains:

```text
rafcoder-sector-runtime-linux-x86_64-{compiler}/
  rafcoder-sector-runtime
  benchmark_sector_harness.c
  benchmark_top56.md
  benchmark_top56.json
  benchmark_snapshots.json
  benchmark_matrix.csv
  build_stdout.txt
  build_stderr.txt
  ARTIFACT_MANIFEST.md
  ARTIFACT_MANIFEST.json
  runtime_smoke_test.txt
```

## Deterministic snapshot assertions

The benchmark generator executes repeated samples for each iteration case and computes a deterministic snapshot signature from:

- checksum;
- hash64;
- CRC32;
- coherence Q16;
- entropy Q16;
- last entropy score;
- last invariant score;
- compact output words.

If repeated samples for the same iteration case diverge, the benchmark fails by default. This turns determinism from a claim into a CI assertion.

Snapshot output:

```text
benchmark_snapshots.json
```

## Runtime smoke test

Before upload, each generated runtime binary executes:

```bash
rafcoder-sector-runtime 42 10
```

The output is saved as:

```text
runtime_smoke_test.txt
```

This proves that the generated runtime binary can execute inside the GitHub Actions environment before being published as an artifact.

## Uploaded artifacts

### 1. Benchmark report artifacts

Artifact names:

```text
rafcoder-top56-benchmark-report-gcc
rafcoder-top56-benchmark-report-clang
```

Each contains:

```text
benchmark_top56.md
benchmark_top56.json
benchmark_snapshots.json
benchmark_matrix.csv
build_stdout.txt
build_stderr.txt
benchmark_sector_harness.c
```

### 2. Runtime binary package artifacts

Artifact names:

```text
rafcoder-sector-runtime-linux-x86_64-gcc
rafcoder-sector-runtime-linux-x86_64-clang
```

Each contains:

```text
rafcoder-sector-runtime-linux-x86_64-{compiler}.tar.gz
rafcoder-sector-runtime-linux-x86_64-{compiler}.tar.gz.sha256
ARTIFACT_MANIFEST.md
ARTIFACT_MANIFEST.json
runtime_smoke_test.txt
```

## Top-56 benchmark scope

The report covers up to 56 metrics across these categories:

- throughput;
- timing stability;
- deterministic output snapshots;
- binary size;
- section size;
- symbol count;
- runtime portability;
- core state quality;
- scaling behavior;
- CI artifact reproducibility;
- audit readiness.

These metrics are CI-runner-relative. They are intended for regression tracking, artifact review and engineering comparison. They are not universal hardware claims.

## Current limitations

- The current package target is Linux x86_64 on GitHub-hosted Ubuntu runners.
- Android ARM64 and ARM32 binary artifacts are not yet produced by this workflow.
- The benchmark is experimental and should be treated as a reproducibility and regression baseline.
- Market-grade comparison still requires fixed hardware, pinned compiler versions, cold/warm run separation and competitor baselines.

## Recommended next steps

1. Add a cross-compile package for ARM32 and ARM64 where toolchains are available.
2. Add Python-vs-C-vs-ASM comparison artifacts.
3. Add historical benchmark comparison between commits.
4. Add trend visualization from previous workflow artifacts.
5. Add Android NDK benchmark jobs for `arm64-v8a` and `armeabi-v7a`.

## Engineering rule

The repository should keep source, scripts and documentation committed. Runtime binaries should be generated by CI and distributed only through GitHub Actions artifacts or release assets with checksums and manifests.
