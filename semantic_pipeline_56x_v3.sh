#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_SRC="${ROOT_DIR}/core.c"
BUILD_DIR="${ROOT_DIR}/build"
REPORTS_DIR="${ROOT_DIR}/reports"

mkdir -p "${BUILD_DIR}" "${REPORTS_DIR}"

FLAGS_SET=(
  "-O0"
  "-O1"
  "-O2"
  "-O3"
  "-Os"
  "-Oz"
  "-O2 -fomit-frame-pointer"
  "-O2 -fno-stack-protector"
  "-O2 -fno-tree-vectorize"
  "-O2 -march=native"
)

FUNCTIONS=(add loop_sum update_state state_step)

normalize_name() {
  sed -E 's/[^a-zA-Z0-9]+/_/g; s/^_+//; s/_+$//' <<<"$1"
}

dump_fn_block() {
  local obj="$1"
  local fn="$2"
  objdump -d -M intel "$obj" | sed -n "/<$fn>:/,/^$/p"
}

dump_fn_hash() {
  local obj="$1"
  local fn="$2"
  dump_fn_block "$obj" "$fn" \
    | sed -E 's/^[[:space:]]*[0-9a-f]+:[[:space:]]+//' \
    | sha256sum | awk '{print $1}'
}

analyze_build() {
  local name="$1"
  local flags="$2"

  local obj="${BUILD_DIR}/core_${name}.o"
  local bin="${BUILD_DIR}/core_${name}.bin"
  local asm="${REPORTS_DIR}/${name}.asm"
  local opt="${REPORTS_DIR}/${name}.opt.log"
  local rep="${REPORTS_DIR}/${name}.report.txt"

  {
    echo "=================================================="
    echo "BUILD: $name"
    echo "FLAGS: $flags"
    echo "=================================================="
  } | tee "$rep"

  gcc ${flags} -fopt-info-optimized -fopt-info-vec-optimized -fopt-info-vec-missed \
    -c "$CORE_SRC" -o "$obj" 2> "$opt"
  gcc ${flags} "$CORE_SRC" -o "$bin"

  objdump -d -M intel "$obj" > "$asm"

  {
    echo "[SIZE]"
    size "$bin"

    echo "[SHA256 BIN]"
    sha256sum "$bin"

    echo "[LIBC CHECK]"
    readelf -d "$bin" 2>/dev/null | grep NEEDED || echo "Sem NEEDED detectado"

    echo "[PLT CHECK]"
    objdump -d -M intel "$bin" | grep '@plt' || echo "Sem PLT detectado"

    echo "[SIMD/FMA CHECK]"
    grep -Ei 'vfmadd|fmadd|xmm|ymm|zmm|neon|vadd|vmul|fmla' "$asm" || echo "Nenhum SIMD/FMA detectado"

    echo "[OPT REPORT]"
    cat "$opt"

    echo "[FUNCTION HASHES]"
    for fn in "${FUNCTIONS[@]}"; do
      if dump_fn_block "$obj" "$fn" | grep -q "<$fn>:"; then
        local fn_hash
        fn_hash="$(dump_fn_hash "$obj" "$fn")"
        echo "$fn: $fn_hash"

        dump_fn_block "$obj" "$fn" > "${REPORTS_DIR}/${name}.${fn}.asm"
        dump_fn_block "$obj" "$fn" | awk '/^[[:space:]]*[0-9a-f]+:/ {print $2, $3, $4, $5, $6, $7}' > "${REPORTS_DIR}/${name}.${fn}.hex"
      else
        echo "$fn: ausente"
      fi
    done

    echo "[RUN]"
    set +e
    if command -v /usr/bin/time >/dev/null 2>&1; then
      /usr/bin/time -f "elapsed=%e user=%U sys=%S maxrss=%M" "$bin"
      RET=$?
    else
      time "$bin"
      RET=$?
    fi
    set -e
    echo "Retorno real: $RET"
  } | tee -a "$rep"
}

if [[ ! -f "$CORE_SRC" ]]; then
  echo "ERRO: core.c não encontrado em $CORE_SRC" >&2
  exit 1
fi

for flags in "${FLAGS_SET[@]}"; do
  name="$(normalize_name "$flags")"
  analyze_build "$name" "$flags"
done

echo "Comparação de roundtrip (O2 vs O3):"
if [[ -f "${REPORTS_DIR}/O2.update_state.asm" && -f "${REPORTS_DIR}/O3.update_state.asm" ]]; then
  diff -u "${REPORTS_DIR}/O2.update_state.asm" "${REPORTS_DIR}/O3.update_state.asm" || true
else
  echo "Arquivos de comparação update_state.asm não disponíveis"
fi
