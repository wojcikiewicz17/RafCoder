#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$ROOT_DIR/android"

"$ROOT_DIR/scripts/ensure_gradle_wrapper_jar.sh"

if [[ ! -x "$ANDROID_DIR/gradlew" ]]; then
  echo "[ERR] Gradle Wrapper não encontrado em $ANDROID_DIR/gradlew."
  exit 1
fi

if [[ -z "${ANDROID_HOME:-}" && -f "$ANDROID_DIR/local.properties" ]]; then
  export ANDROID_HOME="$(sed -n 's/^sdk.dir=//p' "$ANDROID_DIR/local.properties" | head -n1 | sed 's#\\#/#g')"
fi

"$ANDROID_DIR/gradlew" --project-dir "$ANDROID_DIR" --no-daemon clean :app:assembleDebug :app:assembleRelease

if [[ -n "${ANDROID_KEYSTORE_PATH:-}" && -n "${ANDROID_KEYSTORE_PASSWORD:-}" && -n "${ANDROID_KEY_ALIAS:-}" && -n "${ANDROID_KEY_PASSWORD:-}" ]]; then
  "$ANDROID_DIR/gradlew" --project-dir "$ANDROID_DIR" --no-daemon :app:assembleRelease
fi

echo "Built artifacts:"
find "$ANDROID_DIR/app/build/outputs/apk" -type f -name '*.apk' -print
