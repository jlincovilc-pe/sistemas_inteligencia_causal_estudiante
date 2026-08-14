#!/usr/bin/env bash
# build.sh — Compila los mazos de diapositivas de "IA Causal en Producción".
#
# Uso:
#   ./build.sh              # compila los 32 capítulos a build/*.pdf
#   ./build.sh cap11        # compila solo capitulos/cap11_*.typ (match por prefijo)
#   ./build.sh --watch cap11_dml   # typst watch sobre un capítulo (recompila al guardar)
#
# Requiere: typst >= 0.15 con los paquetes touying 0.5.5, cetz 0.3.4, fletcher 0.5.3
# accesibles (cache local en ~/.cache/typst/packages o red disponible).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

OUT_DIR="build"
mkdir -p "$OUT_DIR"

if [[ "${1:-}" == "--watch" ]]; then
  pattern="${2:-}"
  file=$(ls capitulos/*"${pattern}"*.typ 2>/dev/null | head -1)
  if [[ -z "$file" ]]; then
    echo "No se encontró ningún capítulo que matchee '${pattern}' en capitulos/" >&2
    exit 1
  fi
  echo "Watch: $file -> ${OUT_DIR}/$(basename "${file%.typ}").pdf"
  exec typst watch --root . "$file" "${OUT_DIR}/$(basename "${file%.typ}").pdf"
fi

pattern="${1:-}"
files=(capitulos/*"${pattern}"*.typ)

ok=0
fail=0
for f in "${files[@]}"; do
  [[ -e "$f" ]] || continue
  name=$(basename "${f%.typ}")
  out="${OUT_DIR}/${name}.pdf"
  if typst compile --root . "$f" "$out" 2>"${OUT_DIR}/${name}.log"; then
    pages=$(pdfinfo "$out" 2>/dev/null | awk '/^Pages:/{print $2}')
    printf "OK    %-45s %s pág.\n" "$name" "${pages:-?}"
    ok=$((ok+1))
    rm -f "${OUT_DIR}/${name}.log"
  else
    printf "FAIL  %-45s ver %s\n" "$name" "${OUT_DIR}/${name}.log"
    fail=$((fail+1))
  fi
done

echo "---"
echo "OK: $ok · FAIL: $fail · salida en ${OUT_DIR}/"
[[ $fail -eq 0 ]]
