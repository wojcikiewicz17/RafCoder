#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$ROOT_DIR/android"
WRAPPER_DIR="$ANDROID_DIR/gradle/wrapper"
WRAPPER_PROPERTIES="$WRAPPER_DIR/gradle-wrapper.properties"
WRAPPER_JAR="$WRAPPER_DIR/gradle-wrapper.jar"

if [[ ! -f "$WRAPPER_PROPERTIES" ]]; then
  echo "[ERR] Missing $WRAPPER_PROPERTIES"
  exit 1
fi

if [[ -f "$WRAPPER_JAR" ]]; then
  exit 0
fi

DIST_URL="$(sed -n 's/^distributionUrl=//p' "$WRAPPER_PROPERTIES" | head -n1)"
DIST_URL="${DIST_URL//\\:/:}"
DIST_FILE="${DIST_URL##*/}"
GRADLE_VERSION="${DIST_FILE#gradle-}"
GRADLE_VERSION="${GRADLE_VERSION%-bin.zip}"
GRADLE_VERSION="${GRADLE_VERSION%-all.zip}"

if [[ -z "$GRADLE_VERSION" || "$GRADLE_VERSION" == "$DIST_FILE" ]]; then
  echo "[ERR] Unable to parse Gradle version from distributionUrl: $DIST_URL"
  exit 1
fi

JAR_URL="https://raw.githubusercontent.com/gradle/gradle/v${GRADLE_VERSION}/gradle/wrapper/gradle-wrapper.jar"

mkdir -p "$WRAPPER_DIR"
echo "[INFO] Downloading Gradle wrapper jar ${GRADLE_VERSION}"
curl -fsSL "$JAR_URL" -o "$WRAPPER_JAR"
