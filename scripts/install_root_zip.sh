#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="${1:-$ROOT_DIR}"

mapfile -t ZIP_FILES < <(find "$ROOT_DIR" -maxdepth 1 -type f \( -iname '*.zip' \))

if [[ ${#ZIP_FILES[@]} -eq 0 ]]; then
  echo "ERRO: nenhum arquivo .zip encontrado na raiz do projeto: $ROOT_DIR" >&2
  exit 2
fi

if [[ ${#ZIP_FILES[@]} -gt 1 ]]; then
  echo "ERRO: mais de um .zip encontrado. Informe apenas um zip na raiz:" >&2
  printf ' - %s\n' "${ZIP_FILES[@]}" >&2
  exit 3
fi

ZIP_FILE="${ZIP_FILES[0]}"
mkdir -p "$TARGET_DIR"

echo "Instalando pacote: $ZIP_FILE"
echo "Destino: $TARGET_DIR"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

unzip -q "$ZIP_FILE" -d "$TMP_DIR"

if [[ -d "$TMP_DIR/__MACOSX" ]]; then
  rm -rf "$TMP_DIR/__MACOSX"
fi

shopt -s dotglob nullglob
CONTENTS=("$TMP_DIR"/*)

if [[ ${#CONTENTS[@]} -eq 1 && -d "${CONTENTS[0]}" ]]; then
  SRC_DIR="${CONTENTS[0]}"
else
  SRC_DIR="$TMP_DIR"
fi

cp -a "$SRC_DIR"/. "$TARGET_DIR"/

echo "Pacote instalado com sucesso."
