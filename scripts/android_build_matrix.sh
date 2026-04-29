#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$ROOT_DIR/android"
REQUIRED_ABIS=("armeabi-v7a" "arm64-v8a")
DEBUG_JNI_LIBS_DIR="$ANDROID_DIR/app/build/intermediates/merged_native_libs/debug/mergeDebugNativeLibs/out/lib"
RELEASE_JNI_LIBS_DIR="$ANDROID_DIR/app/build/intermediates/merged_native_libs/release/mergeReleaseNativeLibs/out/lib"
ARTIFACTS_DIR="$ROOT_DIR/artifacts"
UNSIGNED_ARTIFACTS_DIR="$ARTIFACTS_DIR/unsigned-release"
SIGNED_ARTIFACTS_DIR="$ARTIFACTS_DIR/signed-release"

"$ROOT_DIR/scripts/ensure_gradle_wrapper_jar.sh"

if [[ ! -x "$ANDROID_DIR/gradlew" ]]; then
  echo "[ERR] Gradle Wrapper não encontrado em $ANDROID_DIR/gradlew."
  exit 1
fi

"$ROOT_DIR/scripts/bootstrap_gradle_wrapper.sh"

if [[ -z "${ANDROID_HOME:-}" && -f "$ANDROID_DIR/local.properties" ]]; then
  export ANDROID_HOME="$(sed -n 's/^sdk.dir=//p' "$ANDROID_DIR/local.properties" | head -n1 | sed 's#\\#/#g')"
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

collect_apk_artifacts() {
  local target_dir="$1"
  shift

  mkdir -p "$target_dir"
  rm -f "$target_dir"/*.apk

  local pattern
  for pattern in "$@"; do
    find "$ANDROID_DIR/app/build/outputs/apk" -type f -path "$pattern" -name '*.apk' -exec cp -f {} "$target_dir/" \;
  done

  echo "Artifacts em $target_dir:"
  find "$target_dir" -maxdepth 1 -type f -name '*.apk' -print | sort
}

build_unsigned_release() {
  echo "[build_unsigned_release] Iniciando build deterministico unsigned (clean + debug + release)..."
  "$ANDROID_DIR/gradlew" --project-dir "$ANDROID_DIR" --no-daemon :app:clean :app:assembleDebug :app:assembleRelease

  check_required_abis "$DEBUG_JNI_LIBS_DIR" "debug-unsigned"
  check_required_abis "$RELEASE_JNI_LIBS_DIR" "release-unsigned"

  collect_apk_artifacts "$UNSIGNED_ARTIFACTS_DIR" "*/debug/*.apk" "*/release/*.apk"
}

build_signed_release() {
  local required_vars=(
    ANDROID_KEYSTORE_PATH
    ANDROID_KEYSTORE_PASSWORD
    ANDROID_KEY_ALIAS
    ANDROID_KEY_PASSWORD
  )

  local var
  for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
      echo "[build_signed_release] Variável obrigatória ausente: ${var}. Build assinado será ignorado."
      return 0
    fi
  done

  if [[ ! -f "$ANDROID_KEYSTORE_PATH" ]]; then
    echo "[build_signed_release] Keystore não encontrado em ANDROID_KEYSTORE_PATH: $ANDROID_KEYSTORE_PATH"
    return 1
  fi

  echo "[build_signed_release] Iniciando build signed deterministico (clean + release)..."
  "$ANDROID_DIR/gradlew" --project-dir "$ANDROID_DIR" --no-daemon :app:clean :app:assembleRelease

  check_required_abis "$RELEASE_JNI_LIBS_DIR" "release-signed"

  collect_apk_artifacts "$SIGNED_ARTIFACTS_DIR" "*/release/*.apk"
}

build_unsigned_release
build_signed_release
