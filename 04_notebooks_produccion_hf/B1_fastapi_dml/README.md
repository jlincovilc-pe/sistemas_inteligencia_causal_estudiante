# B1 — Primer endpoint: servir el estimador DML

| | |
|---|---|
| **Sesiones** | S12–S14 |
| **Lectura monografía** | Cap. **15** — Despliegue de un estimador causal como servicio · **Ap. H** (checklist de arquitectura de despliegue) |
| **Labs** | L12 · L14 |
| **Insumo** | Serie A2: `artifacts/A2/dml_estimator.joblib` + `feature_list.json` + `training_meta.json` |
| **Planes** | [`PLAN_CURSO_COMPLETO.md`](../../PLAN_CURSO_COMPLETO.md) · [`PLAN_INTEGRACION_MONOGRAFIA.md`](../../PLAN_INTEGRACION_MONOGRAFIA.md) |

### Pregunta de valor (disrupción)

> *Un ATE en un notebook no cambia operaciones hasta que alguien puede **consultarlo** de forma reproducible.*  
> *B1 convierte el efecto en un servicio (`/predict`) con el mismo encoding que el entrenamiento.*

## Qué hace

Servicio **FastAPI** que carga el estimador PLR de A2:

| Ruta | Método | Descripción |
|---|---|---|
| `/health` | GET | Estado + ATE cargado |
| `/metadata` | GET | Features, IC, training_meta, supuestos |
| `/predict` | POST | Covariables → efecto (ATE PLR) + IC |

La codificación de features está en `app/inference.py` (función pura), separada del router HTTP (*training–serving skew*).

## Setup local

```bash
cd 04_notebooks_produccion_hf/B1_fastapi_dml
python scripts/sync_a2_artifacts.py
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

```bash
curl -s http://127.0.0.1:8000/health | python -m json.tool
```

## Tests y autograder

```bash
pytest tests/ -q
python ../autograder/grade_b1.py
```

## Docker (desde la raíz del monorepo)

```bash
docker build -f 04_notebooks_produccion_hf/B1_fastapi_dml/Dockerfile -t causal-b1 .
docker run --rm -p 8000:8000 causal-b1
```

## Hugging Face Spaces (manual)

1. Crear Space en Hugging Face con **SDK: Docker** (CPU).  
2. Subir el `Dockerfile` de esta carpeta y el código de `app/` (más `requirements.txt` y el artefacto `artifacts/dml_estimator.joblib`).  
3. HF Spaces con SDK Docker espera el servicio en el puerto **7860**: el `Dockerfile` actual expone `8000` (`EXPOSE 8000` y `CMD … --port 8000`), por lo que hay que alinearlo (cambiar a `--port 7860` y `EXPOSE 7860`, o mapear) para que el Space responda en `https://<usuario>-<space>.hf.space/`.  
4. Confirmar en la pestaña *App* que `/health`, `/metadata` y `/predict` responden; el humo local (`grade_b1.py`) sigue siendo la prueba de validación.

## Humo (DoD B1)

- [x] `GET /health` → `status=ok`
- [x] `POST /predict` < 2 s
- [x] ATE ≈ training_meta de A2
- [x] Dockerfile presente
