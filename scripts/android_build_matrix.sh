#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$ROOT_DIR/android"
REQUIRED_ABIS=("armeabi-v7a" "arm64-v8a")
DEBUG_JNI_LIBS_DIR="$ANDROID_DIR/app/build/intermediates/merged_native_libs/debug/mergeDebugNativeLibs/out/lib"
RELEASE_JNI_LIBS_DIR="$ANDROID_DIR/app/build/intermediates/merged_native_libs/release/mergeReleaseNativeLibs/out/lib"
WRAPPER_JAR="$ANDROID_DIR/gradle/wrapper/gradle-wrapper.jar"
DEBUG_ARTIFACTS_DIR="$ANDROID_DIR/artifacts/debug"
UNSIGNED_ARTIFACTS_DIR="$ANDROID_DIR/artifacts/unsigned-release"
SIGNED_ARTIFACTS_DIR="$ANDROID_DIR/artifacts/signed-release"

cleanup_wrapper_jar() {
  if [[ -f "$WRAPPER_JAR" ]]; then
    rm -f "$WRAPPER_JAR"
    echo "[INFO] Removed ephemeral Gradle wrapper jar: $WRAPPER_JAR"
  fi
}
trap cleanup_wrapper_jar EXIT

if [[ ! -x "$ANDROID_DIR/gradlew" ]]; then
  echo "[ERR] Gradle Wrapper not found or not executable: $ANDROID_DIR/gradlew"
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

resolve_apk() {
  local abi="$1"
  local variant_dir="$2"
  local output_name="$3"

  local split_apk="$ANDROID_DIR/app/build/outputs/apk/${variant_dir}/app-${abi}-${output_name}.apk"
  local universal_apk="$ANDROID_DIR/app/build/outputs/apk/${variant_dir}/app-${output_name}.apk"

  if [[ -f "$split_apk" ]]; then
    echo "$split_apk"
    return 0
  fi

  if [[ -f "$universal_apk" ]]; then
    echo "$universal_apk"
    return 0
  fi

  echo "ERROR: Missing APK for ABI ${abi} (${variant_dir}/${output_name})" >&2
  find "$ANDROID_DIR/app/build/outputs/apk" -type f -name '*.apk' -print | sort >&2 || true
  return 1
}

stage_unsigned_artifacts() {
  mkdir -p "$DEBUG_ARTIFACTS_DIR" "$UNSIGNED_ARTIFACTS_DIR"
  rm -f "$DEBUG_ARTIFACTS_DIR"/*.apk "$UNSIGNED_ARTIFACTS_DIR"/*.apk "$ANDROID_DIR/artifacts/unsigned-apk-sha256sum.txt"

  local abi
  for abi in "${REQUIRED_ABIS[@]}"; do
    local debug_apk
    local unsigned_release_apk
    debug_apk="$(resolve_apk "$abi" debug debug)"
    unsigned_release_apk="$(resolve_apk "$abi" release release-unsigned)"

    cp -v "$debug_apk" "$DEBUG_ARTIFACTS_DIR/rafcoder-${abi}-debug.apk"
    cp -v "$unsigned_release_apk" "$UNSIGNED_ARTIFACTS_DIR/rafcoder-${abi}-release-unsigned.apk"
  done

  sha256sum "$DEBUG_ARTIFACTS_DIR"/*.apk "$UNSIGNED_ARTIFACTS_DIR"/*.apk > "$ANDROID_DIR/artifacts/unsigned-apk-sha256sum.txt"
}

stage_signed_artifacts() {
  mkdir -p "$SIGNED_ARTIFACTS_DIR"
  rm -f "$SIGNED_ARTIFACTS_DIR"/*.apk "$ANDROID_DIR/artifacts/signed-apk-sha256sum.txt"

  local abi
  for abi in "${REQUIRED_ABIS[@]}"; do
    local signed_apk
    signed_apk="$(resolve_apk "$abi" release release)"
    cp -v "$signed_apk" "$SIGNED_ARTIFACTS_DIR/rafcoder-${abi}-release-signed.apk"
  done

  sha256sum "$SIGNED_ARTIFACTS_DIR"/*.apk > "$ANDROID_DIR/artifacts/signed-apk-sha256sum.txt"
}

build_unsigned_release() {
  echo "[build_unsigned_release] Starting deterministic unsigned build: clean + debug + release"
  "$ANDROID_DIR/gradlew" --project-dir "$ANDROID_DIR" --no-daemon :app:clean :app:assembleDebug :app:assembleRelease

  check_required_abis "$DEBUG_JNI_LIBS_DIR" "debug-unsigned"
  check_required_abis "$RELEASE_JNI_LIBS_DIR" "release-unsigned"
  stage_unsigned_artifacts
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
      echo "[build_signed_release] Missing optional signing variable: ${var}. Signed build skipped."
      return 0
    fi
  done

  if [[ ! -f "$ANDROID_KEYSTORE_PATH" ]]; then
    echo "ERROR: Signing store not found at configured path."
    return 1
  fi

  echo "[build_signed_release] Starting deterministic signed build: clean + release"
  "$ANDROID_DIR/gradlew" --project-dir "$ANDROID_DIR" --no-daemon :app:clean :app:assembleRelease

  check_required_abis "$RELEASE_JNI_LIBS_DIR" "release-signed"
  stage_signed_artifacts
}

build_unsigned_release
build_signed_release
