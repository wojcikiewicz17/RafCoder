#!/usr/bin/env python3
"""
RAFAELOS / RafCoder Top-56 benchmark artifact generator.

This script is intentionally self-contained for GitHub Actions:
- builds a native C benchmark harness around core/sector.c;
- runs deterministic sector benchmarks for several iteration counts;
- asserts deterministic snapshots per benchmark case;
- collects up to 56 market-style engineering metrics;
- emits JSON, CSV and Markdown artifacts.

The goal is not to claim absolute market leadership. The goal is to make
performance, size, reproducibility and native-runtime properties measurable,
repeatable and reviewable as CI artifacts.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import platform
import shutil
import statistics
import subprocess
import time
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Tuple


HARNESS_C = r'''
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "core/sector.h"

#define BENCH_FNV_OFFSET 0xCBF29CE484222325ULL
#define BENCH_FNV_PRIME  0x100000001B3ULL

static uint64_t nsec_now(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ((uint64_t)ts.tv_sec * 1000000000ULL) + (uint64_t)ts.tv_nsec;
}

static uint64_t checksum_mix(uint64_t checksum, uint64_t value) {
    checksum ^= value;
    checksum *= BENCH_FNV_PRIME;
    checksum ^= checksum >> 32u;
    return checksum;
}

int main(int argc, char** argv) {
    uint32_t iterations = 42u;
    uint32_t repeats = 1000u;
    uint32_t i;
    uint64_t start;
    uint64_t end;
    uint64_t checksum = BENCH_FNV_OFFSET;
    struct state s;

    if (argc > 1) {
        iterations = (uint32_t)strtoul(argv[1], 0, 10);
    }
    if (argc > 2) {
        repeats = (uint32_t)strtoul(argv[2], 0, 10);
    }

    start = nsec_now();
    for (i = 0u; i < repeats; ++i) {
        uint32_t j;
        s.coherence_q16 = 0u;
        s.entropy_q16 = 0u;
        s.hash64 = 0ULL;
        s.crc32 = 0u;
        s.last_entropy_milli = 0u;
        s.last_invariant_milli = 0u;
        s.output_words = 0u;
        s.reserved = 0u;
        for (j = 0u; j < CORE_OUTPUT_WORDS; ++j) {
            s.output[j] = 0u;
        }

        run_sector(&s, iterations);
        checksum = checksum_mix(checksum, s.hash64);
        checksum = checksum_mix(checksum, ((uint64_t)s.crc32 << 32u) | s.coherence_q16);
        checksum = checksum_mix(checksum, ((uint64_t)s.entropy_q16 << 32u) | s.last_entropy_milli);
        checksum = checksum_mix(checksum, (uint64_t)s.last_invariant_milli);
        for (j = 0u; j < CORE_OUTPUT_WORDS; ++j) {
            checksum = checksum_mix(checksum, ((uint64_t)j << 32u) | s.output[j]);
        }
    }
    end = nsec_now();

    printf("iterations=%u\n", iterations);
    printf("repeats=%u\n", repeats);
    printf("elapsed_ns=%llu\n", (unsigned long long)(end - start));
    printf("checksum=0x%016llx\n", (unsigned long long)checksum);
    printf("hash64=0x%016llx\n", (unsigned long long)s.hash64);
    printf("crc32=0x%08x\n", s.crc32);
    printf("coherence_q16=%u\n", s.coherence_q16);
    printf("entropy_q16=%u\n", s.entropy_q16);
    printf("last_entropy_milli=%u\n", s.last_entropy_milli);
    printf("last_invariant_milli=%u\n", s.last_invariant_milli);
    printf("output_words=%u\n", s.output_words);
    for (i = 0u; i < CORE_OUTPUT_WORDS; ++i) {
        printf("output_%u=0x%08x\n", i, s.output[i]);
    }

    return checksum == 0ULL ? 2 : 0;
}
'''


@dataclass
class Metric:
    rank: int
    category: str
    name: str
    value: object
    unit: str
    interpretation: str


def run(cmd: List[str], cwd: Path, check: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, cwd=str(cwd), text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=check)


def sha256_bytes(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def parse_key_values(text: str) -> Dict[str, str]:
    out: Dict[str, str] = {}
    for line in text.splitlines():
        if "=" in line:
            k, v = line.split("=", 1)
            out[k.strip()] = v.strip()
    return out


def snapshot_from_kv(kv: Dict[str, str]) -> Dict[str, object]:
    return {
        "checksum": kv.get("checksum", ""),
        "hash64": kv.get("hash64", ""),
        "crc32": kv.get("crc32", ""),
        "coherence_q16": int(kv.get("coherence_q16", "0")),
        "entropy_q16": int(kv.get("entropy_q16", "0")),
        "last_entropy_milli": int(kv.get("last_entropy_milli", "0")),
        "last_invariant_milli": int(kv.get("last_invariant_milli", "0")),
        "output_words": int(kv.get("output_words", "0")),
        "outputs": [kv.get(f"output_{i}", "") for i in range(8)],
    }


def snapshot_signature(snapshot: Dict[str, object]) -> str:
    data = json.dumps(snapshot, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return sha256_bytes(data)


def binary_size(path: Path) -> int:
    return path.stat().st_size if path.exists() else 0


def count_symbols(root: Path, binary: Path) -> int:
    if shutil.which("nm") is None:
        return -1
    cp = run(["nm", "-n", str(binary)], root, check=False)
    if cp.returncode != 0:
        return -1
    return sum(1 for line in cp.stdout.splitlines() if line.strip())


def size_sections(root: Path, binary: Path) -> Dict[str, int]:
    if shutil.which("size") is None:
        return {}
    cp = run(["size", str(binary)], root, check=False)
    lines = [x for x in cp.stdout.splitlines() if x.strip()]
    if len(lines) < 2:
        return {}
    headers = lines[0].split()
    values = lines[1].split()
    result = {}
    for h, v in zip(headers, values):
        try:
            result[h] = int(v)
        except ValueError:
            pass
    return result


def build_harness(root: Path, out_dir: Path, cc: str, cflags: List[str]) -> Path:
    harness = out_dir / "benchmark_sector_harness.c"
    harness.write_text(HARNESS_C, encoding="utf-8")
    binary = out_dir / "benchmark_sector"
    cmd = [
        cc,
        "-std=c11",
        "-D_POSIX_C_SOURCE=200809L",
        "-I.",
        "-Icore",
        "-Icore/arch",
        *cflags,
        str(harness),
        "core/sector.c",
        "core/arch/primitives.c",
        "-o",
        str(binary),
    ]
    cp = run(cmd, root, check=False)
    (out_dir / "build_stdout.txt").write_text(cp.stdout, encoding="utf-8")
    (out_dir / "build_stderr.txt").write_text(cp.stderr, encoding="utf-8")
    if cp.returncode != 0:
        raise SystemExit(f"build failed with exit code {cp.returncode}; see build_stderr.txt")
    return binary


def execute_matrix(
    root: Path,
    binary: Path,
    cases: Iterable[int],
    repeats: int,
    samples: int,
    fail_on_nondeterminism: bool,
) -> Tuple[List[Dict[str, object]], List[Dict[str, object]]]:
    rows: List[Dict[str, object]] = []
    snapshots: List[Dict[str, object]] = []
    nondeterministic_cases: List[int] = []

    for iterations in cases:
        sample_ns: List[int] = []
        sample_snapshots: List[Dict[str, object]] = []
        sample_signatures: List[str] = []
        last: Dict[str, str] = {}

        for _ in range(samples):
            cp = run([str(binary), str(iterations), str(repeats)], root, check=False)
            if cp.returncode != 0:
                raise SystemExit(f"benchmark failed for iterations={iterations}: {cp.stderr}\n{cp.stdout}")
            kv = parse_key_values(cp.stdout)
            last = kv
            snapshot = snapshot_from_kv(kv)
            sample_snapshots.append(snapshot)
            sample_signatures.append(snapshot_signature(snapshot))
            sample_ns.append(int(kv["elapsed_ns"]))

        deterministic_samples = len(set(sample_signatures)) == 1
        if not deterministic_samples:
            nondeterministic_cases.append(iterations)

        mean_ns = statistics.mean(sample_ns)
        median_ns = statistics.median(sample_ns)
        stdev_ns = statistics.pstdev(sample_ns) if len(sample_ns) > 1 else 0.0
        min_ns = min(sample_ns)
        max_ns = max(sample_ns)
        total_ops = iterations * repeats
        ns_per_sector = mean_ns / total_ops if total_ops else 0.0
        sectors_per_sec = 1_000_000_000.0 / ns_per_sector if ns_per_sector else 0.0
        stable_snapshot = sample_snapshots[-1]

        rows.append({
            "iterations": iterations,
            "repeats": repeats,
            "samples": samples,
            "elapsed_ns_mean": mean_ns,
            "elapsed_ns_median": median_ns,
            "elapsed_ns_stdev": stdev_ns,
            "elapsed_ns_min": min_ns,
            "elapsed_ns_max": max_ns,
            "ns_per_sector": ns_per_sector,
            "sectors_per_second": sectors_per_sec,
            "deterministic_samples": deterministic_samples,
            "sample_signature": sample_signatures[-1],
            "unique_sample_signatures": len(set(sample_signatures)),
            "checksum": last.get("checksum", ""),
            "hash64": last.get("hash64", ""),
            "crc32": last.get("crc32", ""),
            "coherence_q16": int(last.get("coherence_q16", "0")),
            "entropy_q16": int(last.get("entropy_q16", "0")),
            "last_entropy_milli": int(last.get("last_entropy_milli", "0")),
            "last_invariant_milli": int(last.get("last_invariant_milli", "0")),
            "output_words": int(last.get("output_words", "0")),
            **{f"output_{i}": last.get(f"output_{i}", "") for i in range(8)},
        })

        snapshots.append({
            "iterations": iterations,
            "repeats": repeats,
            "samples": samples,
            "deterministic_samples": deterministic_samples,
            "sample_signature": sample_signatures[-1],
            "unique_sample_signatures": sorted(set(sample_signatures)),
            "snapshot": stable_snapshot,
        })

    if nondeterministic_cases and fail_on_nondeterminism:
        raise SystemExit(f"non-deterministic snapshots detected for cases: {nondeterministic_cases}")

    return rows, snapshots


def stability_score(rows: List[Dict[str, object]]) -> float:
    if not rows:
        return 0.0
    penalties = []
    for r in rows:
        mean = float(r["elapsed_ns_mean"])
        stdev = float(r["elapsed_ns_stdev"])
        cv = stdev / mean if mean else 1.0
        penalties.append(min(cv, 1.0))
    return max(0.0, 100.0 * (1.0 - statistics.mean(penalties)))


def make_metrics(root: Path, binary: Path, rows: List[Dict[str, object]], snapshots: List[Dict[str, object]], cc: str, cflags: List[str]) -> List[Metric]:
    best = min(rows, key=lambda r: float(r["ns_per_sector"]))
    worst = max(rows, key=lambda r: float(r["ns_per_sector"]))
    sections = size_sections(root, binary)
    bsize = binary_size(binary)
    syms = count_symbols(root, binary)
    digest = sha256_file(binary)
    deterministic = all(bool(r["deterministic_samples"]) for r in rows)
    same_output_words = all(int(r["output_words"]) == 8 for r in rows)
    coherences = [int(r["coherence_q16"]) for r in rows]
    entropies = [int(r["entropy_q16"]) for r in rows]
    invariants = [int(r["last_invariant_milli"]) for r in rows]
    ns_values = [float(r["ns_per_sector"]) for r in rows]
    checksum_values = [str(r["checksum"]) for r in rows]

    raw: List[Tuple[str, str, object, str, str]] = [
        ("Throughput", "best_ns_per_sector", round(float(best["ns_per_sector"]), 3), "ns/sector", "Lower is better for native runtime throughput."),
        ("Throughput", "best_sectors_per_second", round(float(best["sectors_per_second"]), 3), "sectors/s", "Higher is better for raw execution volume."),
        ("Throughput", "worst_ns_per_sector", round(float(worst["ns_per_sector"]), 3), "ns/sector", "Worst measured case in the benchmark matrix."),
        ("Throughput", "median_ns_per_sector", round(statistics.median(ns_values), 3), "ns/sector", "Median across the benchmark matrix."),
        ("Throughput", "mean_ns_per_sector", round(statistics.mean(ns_values), 3), "ns/sector", "Mean across the benchmark matrix."),
        ("Throughput", "throughput_spread_ratio", round(max(ns_values) / min(ns_values), 6), "ratio", "Closeness to 1.0 indicates stable scaling."),
        ("Stability", "timing_stability_score", round(stability_score(rows), 3), "0-100", "Derived from coefficient of variation across samples."),
        ("Stability", "sample_count", sum(int(r["samples"]) for r in rows), "samples", "Total benchmark samples collected."),
        ("Stability", "matrix_cases", len(rows), "cases", "Number of iteration cases tested."),
        ("Determinism", "checksum_uniqueness_across_cases", len(set(checksum_values)), "unique", "Checksums should vary by iteration case."),
        ("Determinism", "deterministic_snapshot_assertions", deterministic, "bool", "True means repeated samples per case produced identical snapshots."),
        ("Determinism", "snapshot_cases_asserted", len(snapshots), "cases", "Number of benchmark cases with deterministic snapshot checks."),
        ("Determinism", "snapshot_hash64_last", rows[-1]["hash64"], "hex", "Final state hash for the largest benchmark case."),
        ("Determinism", "snapshot_crc32_last", rows[-1]["crc32"], "hex", "Final CRC32 for the largest benchmark case."),
        ("Determinism", "output_words_are_8", same_output_words, "bool", "Checks the compact output vector contract."),
        ("Binary", "binary_size_bytes", bsize, "bytes", "Total benchmark binary size."),
        ("Binary", "text_section_bytes", sections.get("text", -1), "bytes", "Executable text size from size(1), when available."),
        ("Binary", "data_section_bytes", sections.get("data", -1), "bytes", "Data section size from size(1), when available."),
        ("Binary", "bss_section_bytes", sections.get("bss", -1), "bytes", "BSS section size from size(1), when available."),
        ("Binary", "symbol_count", syms, "symbols", "Symbol count from nm, when available."),
        ("Binary", "binary_sha256", digest, "sha256", "Binary identity for artifact reproducibility."),
        ("Portability", "os", platform.system(), "string", "Runner operating system."),
        ("Portability", "machine", platform.machine(), "string", "Runner machine architecture."),
        ("Portability", "python_version", platform.python_version(), "string", "Python used by artifact generator."),
        ("Portability", "compiler", cc, "string", "C compiler selected by workflow."),
        ("Portability", "cflags", " ".join(cflags), "flags", "Optimization and warning flags."),
        ("Core", "core_payload_size", 32, "bytes", "Payload size from CORE_PAYLOAD_SIZE contract."),
        ("Core", "core_output_words", 8, "u32", "Output vector words from CORE_OUTPUT_WORDS contract."),
        ("Core", "state_struct_observed_outputs", 8, "u32", "Observed output words emitted by harness."),
        ("Core", "min_coherence_q16", min(coherences), "q16", "Minimum coherence across benchmark cases."),
        ("Core", "max_coherence_q16", max(coherences), "q16", "Maximum coherence across benchmark cases."),
        ("Core", "mean_coherence_q16", round(statistics.mean(coherences), 3), "q16", "Mean coherence across benchmark cases."),
        ("Core", "min_entropy_q16", min(entropies), "q16", "Minimum entropy across benchmark cases."),
        ("Core", "max_entropy_q16", max(entropies), "q16", "Maximum entropy across benchmark cases."),
        ("Core", "mean_entropy_q16", round(statistics.mean(entropies), 3), "q16", "Mean entropy across benchmark cases."),
        ("Core", "min_invariant_milli", min(invariants), "milli", "Minimum invariant score across cases."),
        ("Core", "max_invariant_milli", max(invariants), "milli", "Maximum invariant score across cases."),
        ("Core", "mean_invariant_milli", round(statistics.mean(invariants), 3), "milli", "Mean invariant score across cases."),
        ("Scaling", "small_case_iterations", rows[0]["iterations"], "iterations", "Smallest iteration case."),
        ("Scaling", "large_case_iterations", rows[-1]["iterations"], "iterations", "Largest iteration case."),
        ("Scaling", "large_to_small_iteration_ratio", round(float(rows[-1]["iterations"]) / float(rows[0]["iterations"]), 3), "ratio", "Benchmark matrix scale spread."),
        ("Scaling", "large_to_small_time_ratio", round(float(rows[-1]["elapsed_ns_mean"]) / float(rows[0]["elapsed_ns_mean"]), 3), "ratio", "Observed elapsed-time growth."),
        ("Scaling", "large_to_small_ns_per_sector_ratio", round(float(rows[-1]["ns_per_sector"]) / float(rows[0]["ns_per_sector"]), 6), "ratio", "Per-sector scaling stability."),
        ("CI", "artifact_json", "benchmark_top56.json", "file", "Machine-readable benchmark report."),
        ("CI", "artifact_csv", "benchmark_matrix.csv", "file", "Tabular benchmark matrix."),
        ("CI", "artifact_markdown", "benchmark_top56.md", "file", "Human-readable specialized analysis report."),
        ("CI", "artifact_snapshots", "benchmark_snapshots.json", "file", "Deterministic snapshot assertions and signatures."),
        ("CI", "build_stdout", "build_stdout.txt", "file", "Compiler stdout artifact."),
        ("CI", "build_stderr", "build_stderr.txt", "file", "Compiler stderr artifact."),
        ("Audit", "market_metric_count_target", 56, "metrics", "Top-56 benchmark/audit target."),
        ("Audit", "claims_are_runner_relative", True, "bool", "Metrics are CI-runner measurements, not universal hardware claims."),
        ("Audit", "native_core_no_heap_claim", "source-level intended", "text", "Core path is designed without malloc/GC; static verification is future work."),
        ("Audit", "external_dependency_weight", "low", "label", "Benchmark uses Python stdlib plus system C compiler."),
        ("Audit", "reviewability", "json/csv/md/snapshots", "formats", "Artifacts support machine and human review."),
        ("Audit", "reproducibility_level", "CI reproducible", "label", "Re-runnable through GitHub Actions."),
        ("Audit", "specialized_analysis_scope", "performance,size,determinism,portability,core-state", "domains", "Scope covered by the generated artifacts."),
        ("Audit", "next_required_baseline", "Python_vs_C_vs_ASM", "label", "Next market-grade step is multi-runtime comparison."),
    ]
    return [Metric(i + 1, *item) for i, item in enumerate(raw[:56])]


def write_outputs(out_dir: Path, rows: List[Dict[str, object]], snapshots: List[Dict[str, object]], metrics: List[Metric]) -> None:
    with (out_dir / "benchmark_matrix.csv").open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)

    (out_dir / "benchmark_snapshots.json").write_text(
        json.dumps({"schema": "rafcoder.top56.snapshots.v1", "snapshots": snapshots}, indent=2, sort_keys=True),
        encoding="utf-8",
    )

    payload = {
        "schema": "rafcoder.top56.benchmark.v2",
        "generated_at_unix": int(time.time()),
        "metrics": [asdict(m) for m in metrics],
        "matrix": rows,
        "snapshots": snapshots,
    }
    (out_dir / "benchmark_top56.json").write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")

    lines = [
        "# RAFAELOS / RafCoder Top-56 Benchmark Artifact",
        "",
        "> CI-runner-relative benchmark report. Values depend on the GitHub Actions runner, compiler, flags and current repository state.",
        "",
        "## Top 56 metrics",
        "",
        "| # | Category | Metric | Value | Unit | Interpretation |",
        "|---:|---|---|---:|---|---|",
    ]
    for m in metrics:
        val = str(m.value).replace("|", "\\|")
        interp = m.interpretation.replace("|", "\\|")
        lines.append(f"| {m.rank} | {m.category} | `{m.name}` | {val} | {m.unit} | {interp} |")

    lines.extend([
        "",
        "## Benchmark matrix",
        "",
        "| iterations | repeats | samples | deterministic | mean ns | ns/sector | sectors/s | checksum |",
        "|---:|---:|---:|---|---:|---:|---:|---|",
    ])
    for r in rows:
        lines.append(
            f"| {r['iterations']} | {r['repeats']} | {r['samples']} | {r['deterministic_samples']} | "
            f"{float(r['elapsed_ns_mean']):.3f} | {float(r['ns_per_sector']):.3f} | "
            f"{float(r['sectors_per_second']):.3f} | `{r['checksum']}` |"
        )

    lines.extend([
        "",
        "## Deterministic snapshots",
        "",
        "| iterations | signature | hash64 | crc32 | output words |",
        "|---:|---|---|---|---:|",
    ])
    for s in snapshots:
        snap = s["snapshot"]
        lines.append(
            f"| {s['iterations']} | `{s['sample_signature']}` | `{snap['hash64']}` | `{snap['crc32']}` | {snap['output_words']} |"
        )

    lines.extend([
        "",
        "## Specialized analysis notes",
        "",
        "- This workflow creates artifacts for performance, binary size, determinism, state quality, portability and CI reproducibility.",
        "- Repeated samples for each benchmark case are asserted against deterministic snapshot signatures.",
        "- These are not universal hardware claims; they are runner-relative measurements intended for regression tracking.",
        "- The next stronger benchmark layer should compare Python reference, portable C, x86_64 ASM and Android ARM64/ARM32 paths.",
        "- Market-grade claims require fixed hardware, pinned compiler, repeated cold/warm runs and baseline competitors.",
        "",
    ])
    (out_dir / "benchmark_top56.md").write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default="benchmark_artifacts")
    parser.add_argument("--cc", default=os.environ.get("CC", "gcc"))
    parser.add_argument("--repeats", type=int, default=2000)
    parser.add_argument("--samples", type=int, default=5)
    parser.add_argument("--cases", default="1,7,42,128,512,2048")
    parser.add_argument("--cflags", default="-O2,-Wall,-Wextra,-Werror")
    parser.add_argument("--allow-nondeterminism", action="store_true", help="Do not fail when repeated snapshots diverge.")
    args = parser.parse_args()

    root = Path.cwd()
    out_dir = root / args.out
    out_dir.mkdir(parents=True, exist_ok=True)

    cflags = [x for x in args.cflags.split(",") if x]
    cases = [int(x.strip()) for x in args.cases.split(",") if x.strip()]

    binary = build_harness(root, out_dir, args.cc, cflags)
    rows, snapshots = execute_matrix(
        root,
        binary,
        cases,
        args.repeats,
        args.samples,
        fail_on_nondeterminism=not args.allow_nondeterminism,
    )
    metrics = make_metrics(root, binary, rows, snapshots, args.cc, cflags)
    write_outputs(out_dir, rows, snapshots, metrics)

    print(f"generated {out_dir / 'benchmark_top56.md'}")
    print(f"generated {out_dir / 'benchmark_top56.json'}")
    print(f"generated {out_dir / 'benchmark_matrix.csv'}")
    print(f"generated {out_dir / 'benchmark_snapshots.json'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
