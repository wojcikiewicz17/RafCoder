#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$ROOT_DIR/android"
WRAPPER_JAR="$ANDROID_DIR/gradle/wrapper/gradle-wrapper.jar"
WRAPPER_JAR_URL="https://raw.githubusercontent.com/gradle/gradle/v8.7.0/gradle/wrapper/gradle-wrapper.jar"

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

echo "Built artifacts:"
find "$ANDROID_DIR/app/build/outputs/apk" -type f -name '*.apk' -print
