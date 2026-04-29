#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$ROOT_DIR/android"
WRAPPER_DIR="$ANDROID_DIR/gradle/wrapper"
PROPS_FILE="$WRAPPER_DIR/gradle-wrapper.properties"
JAR_FILE="$WRAPPER_DIR/gradle-wrapper.jar"

if [[ -f "$JAR_FILE" ]]; then
  exit 0
fi

if [[ ! -f "$PROPS_FILE" ]]; then
  echo "[ERR] gradle-wrapper.properties não encontrado em $PROPS_FILE"
  exit 1
fi

DIST_URL="$(sed -n 's/^distributionUrl=//p' "$PROPS_FILE" | head -n1 | sed 's#\\:#:#g')"
if [[ -z "$DIST_URL" ]]; then
  echo "[ERR] distributionUrl ausente em $PROPS_FILE"
  exit 1
fi

VERSION="$(printf '%s' "$DIST_URL" | sed -n 's#.*gradle-\([0-9][0-9.]*\)-.*#\1#p')"
if [[ -z "$VERSION" ]]; then
  echo "[ERR] Não foi possível extrair versão do Gradle a partir de distributionUrl=$DIST_URL"
  exit 1
fi

JAR_URL="https://raw.githubusercontent.com/gradle/gradle/v${VERSION}/gradle/wrapper/gradle-wrapper.jar"
mkdir -p "$WRAPPER_DIR"

echo "[INFO] gradle-wrapper.jar ausente; baixando de $JAR_URL"
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$JAR_URL" -o "$JAR_FILE"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$JAR_FILE" "$JAR_URL"
else
  echo "[ERR] curl ou wget é necessário para bootstrap do gradle-wrapper.jar"
  exit 1
fi

if [[ ! -s "$JAR_FILE" ]]; then
  echo "[ERR] Falha ao baixar gradle-wrapper.jar"
  exit 1
fi
