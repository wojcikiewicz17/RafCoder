#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORE_DIR="$ROOT_DIR/core"
OUT_DIR="${1:-$ROOT_DIR/artifacts/core-metrics}"
ITERATIONS="${RAFCODER_BENCH_ITERATIONS:-1000}"

mkdir -p "$OUT_DIR"

make -C "$CORE_DIR" clean
make -C "$CORE_DIR" all test_primitives_equivalence test_snapshot test_reentrancy benchmark_run_sector

"$CORE_DIR/test_primitives_equivalence" > "$OUT_DIR/primitives-equivalence.txt"
"$CORE_DIR/test_snapshot" > "$OUT_DIR/snapshot.txt"
"$CORE_DIR/test_reentrancy" > "$OUT_DIR/reentrancy.txt"
"$CORE_DIR/benchmark_run_sector" --iterations "$ITERATIONS" --format csv > "$OUT_DIR/benchmark-run-sector.csv"
"$CORE_DIR/benchmark_run_sector" --iterations "$ITERATIONS" --format json > "$OUT_DIR/benchmark-run-sector.json"

{
  echo "metric,value"
  echo "arch,$(uname -m)"
  echo "os,$(uname -s)"
  echo "iterations_per_run,$ITERATIONS"
  echo "cc,$(${CC:-cc} --version | head -n 1 | tr ',' ';')"
} > "$OUT_DIR/environment.csv"

{
  echo "file,size_bytes"
  find "$CORE_DIR" -maxdepth 1 -type f \
    \( -name 'libsector_core.a' -o -name 'test_primitives_equivalence' -o -name 'test_snapshot' -o -name 'test_reentrancy' -o -name 'benchmark_run_sector' \) \
    -print0 | sort -z | while IFS= read -r -d '' file; do
      size_bytes="$(wc -c < "$file" | tr -d ' ')"
      printf '%s,%s\n' "${file#$ROOT_DIR/}" "$size_bytes"
    done
} > "$OUT_DIR/binary-sizes.csv"

find "$CORE_DIR" -maxdepth 1 -type f \
  \( -name 'libsector_core.a' -o -name 'test_primitives_equivalence' -o -name 'test_snapshot' -o -name 'test_reentrancy' -o -name 'benchmark_run_sector' \) \
  -print0 | sort -z | xargs -0 sha256sum > "$OUT_DIR/sha256sums.txt"

if command -v nm >/dev/null 2>&1; then
  nm -S --size-sort "$CORE_DIR/libsector_core.a" > "$OUT_DIR/libsector-core-nm.txt" || true
fi

if command -v size >/dev/null 2>&1; then
  size "$CORE_DIR/libsector_core.a" "$CORE_DIR/benchmark_run_sector" > "$OUT_DIR/elf-size.txt" || true
fi

cat > "$OUT_DIR/manifest.json" <<EOF
{
  "component": "rafcoder-core",
  "arch": "$(uname -m)",
  "os": "$(uname -s)",
  "iterations_per_run": $ITERATIONS,
  "artifacts": [
    "primitives-equivalence.txt",
    "snapshot.txt",
    "reentrancy.txt",
    "benchmark-run-sector.csv",
    "benchmark-run-sector.json",
    "environment.csv",
    "binary-sizes.csv",
    "sha256sums.txt",
    "libsector-core-nm.txt",
    "elf-size.txt"
  ]
}
EOF

printf 'Core metrics written to %s\n' "$OUT_DIR"
