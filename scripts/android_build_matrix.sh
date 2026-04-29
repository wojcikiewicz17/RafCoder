#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$ROOT_DIR/android"
REQUIRED_ABIS=("armeabi-v7a" "arm64-v8a")
DEBUG_JNI_LIBS_DIR="$ANDROID_DIR/app/build/intermediates/merged_native_libs/debug/mergeDebugNativeLibs/out/lib"
RELEASE_JNI_LIBS_DIR="$ANDROID_DIR/app/build/intermediates/merged_native_libs/release/mergeReleaseNativeLibs/out/lib"
WRAPPER_JAR="$ANDROID_DIR/gradle/wrapper/gradle-wrapper.jar"

cleanup_wrapper_jar() {
  if [[ -f "$WRAPPER_JAR" ]]; then
    rm -f "$WRAPPER_JAR"
    echo "[INFO] Removed ephemeral Gradle wrapper jar: $WRAPPER_JAR"
  fi
}
trap cleanup_wrapper_jar EXIT

if [[ ! -x "$ANDROID_DIR/gradlew" ]]; then
  echo "[ERR] Gradle Wrapper não encontrado em $ANDROID_DIR/gradlew."
  exit 1
fi

"$ROOT_DIR/scripts/bootstrap_gradle_wrapper.sh"

if [[ -z "${ANDROID_HOME:-}" && -f "$ANDROID_DIR/local.properties" ]]; then
  export ANDROID_HOME="$(sed -n 's/^sdk.dir=//p' "$ANDROID_DIR/local.properties" | head -n1 | sed 's#\\#/#g')"
fi

HAS_SIGNING_VARS=false
if [[ -n "${ANDROID_KEYSTORE_PATH:-}" && -n "${ANDROID_KEYSTORE_PASSWORD:-}" && -n "${ANDROID_KEY_ALIAS:-}" && -n "${ANDROID_KEY_PASSWORD:-}" ]]; then
  HAS_SIGNING_VARS=true
fi

echo "[INFO] Executando build base (clean + debug + release)"
"$ANDROID_DIR/gradlew" --no-daemon -p "$ANDROID_DIR" clean :app:assembleDebug :app:assembleRelease

if [[ "$HAS_SIGNING_VARS" == true ]]; then
  echo "[INFO] Trilha produzida: debug + release signed (variáveis de signing detectadas)."
  if [[ "${BUILD_EXPLICIT_UNSIGNED_RELEASE:-false}" == "true" ]]; then
    echo "[WARN] BUILD_EXPLICIT_UNSIGNED_RELEASE=true definido, mas não há tarefa dedicated unsigned neste projeto."
    echo "[WARN] Para gerar release unsigned explícito sem ambiguidade, adicione uma tarefa Gradle dedicada e integre aqui."
  fi
else
  echo "[INFO] Trilha produzida: debug + release unsigned (variáveis de signing ausentes)."
fi

check_required_abis() {
  local libs_dir="$1"
  local variant="$2"

  echo "[${variant}] Native libs directory: ${libs_dir}"
  if [[ ! -d "$libs_dir" ]]; then
    echo "ERROR: [${variant}] native libs directory not found: ${libs_dir}"
    return 1
  fi

  find "$libs_dir" -mindepth 1 -maxdepth 2 -type f -name '*.so' -print | sort

  local abi
  for abi in "${REQUIRED_ABIS[@]}"; do
    if [[ ! -d "$libs_dir/$abi" ]]; then
      echo "ERROR: [${variant}] missing ABI directory: $libs_dir/$abi"
      return 1
    fi

    if ! find "$libs_dir/$abi" -mindepth 1 -maxdepth 1 -type f -name '*.so' | grep -q .; then
      echo "ERROR: [${variant}] no native .so found for ABI: ${abi} in ${libs_dir}/${abi}"
      return 1
    fi

    echo "OK: [${variant}] ABI ${abi} has native libraries"
  done
}

check_required_abis "$DEBUG_JNI_LIBS_DIR" "debug"
check_required_abis "$RELEASE_JNI_LIBS_DIR" "release"

echo "Built artifacts:"
find "$ANDROID_DIR/app/build/outputs/apk" -type f -name '*.apk' -print
