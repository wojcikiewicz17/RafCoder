#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$ROOT_DIR/android"
WRAPPER_JAR="$ANDROID_DIR/gradle/wrapper/gradle-wrapper.jar"
WRAPPER_JAR_URL="https://raw.githubusercontent.com/gradle/gradle/v8.7.0/gradle/wrapper/gradle-wrapper.jar"

REQUIRED_ABIS=("armeabi-v7a" "arm64-v8a")
DEBUG_JNI_LIBS_DIR="$ANDROID_DIR/app/build/intermediates/merged_native_libs/debug/mergeDebugNativeLibs/out/lib"
RELEASE_JNI_LIBS_DIR="$ANDROID_DIR/app/build/intermediates/merged_native_libs/release/mergeReleaseNativeLibs/out/lib"

if [[ ! -f "$WRAPPER_JAR" ]]; then
  mkdir -p "$(dirname "$WRAPPER_JAR")"
  curl -fsSL "$WRAPPER_JAR_URL" -o "$WRAPPER_JAR"
fi

if [[ -z "${ANDROID_HOME:-}" && -f "$ANDROID_DIR/local.properties" ]]; then
  export ANDROID_HOME="$(sed -n 's/^sdk.dir=//p' "$ANDROID_DIR/local.properties" | head -n1 | sed 's#\\#/#g')"
fi

"$ANDROID_DIR/gradlew" -p "$ANDROID_DIR" --no-daemon clean :app:assembleDebug :app:assembleRelease

if [[ -n "${ANDROID_KEYSTORE_PATH:-}" && -n "${ANDROID_KEYSTORE_PASSWORD:-}" && -n "${ANDROID_KEY_ALIAS:-}" && -n "${ANDROID_KEY_PASSWORD:-}" ]]; then
  "$ANDROID_DIR/gradlew" -p "$ANDROID_DIR" --no-daemon :app:assembleRelease
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
