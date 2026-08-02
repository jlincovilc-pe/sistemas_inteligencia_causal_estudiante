#!/usr/bin/env bash
# Empaqueta model card + artefactos A2 + puntero al servicio B1 para HF Hub.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
B2="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${B2}/hub_bundle"
A2="${ROOT}/03_notebooks_caso_estudio/artifacts/A2"

rm -rf "${OUT}"
mkdir -p "${OUT}"
cp "${B2}/model_card/MODEL_CARD.md" "${OUT}/README.md"
if [[ -d "${A2}" ]]; then
  cp "${A2}/dml_estimator.joblib" "${A2}/feature_list.json" "${A2}/training_meta.json" "${OUT}/" 2>/dev/null || true
fi
cat > "${OUT}/SERVICE.md" << 'EOF'
# Servicio

El endpoint de inferencia vive en `04_notebooks_produccion_hf/B1_fastapi_dml/`.

```bash
docker build -f 04_notebooks_produccion_hf/B1_fastapi_dml/Dockerfile -t causal-b1 .
docker run --rm -p 8000:8000 causal-b1
```
EOF
echo "Bundle listo en ${OUT}"
ls -la "${OUT}"
