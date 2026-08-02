# B3 — Política óptima como Space (Gradio)

| | |
|---|---|
| **Sesiones** | S23–S26 |
| **Lectura monografía** | Cap. **21** Policy · Cap. **22** Uplift · Cap. **15** (contexto servicio) |
| **Labs** | L22 · L23 |
| **Insumo** | Serie A4: `policy.joblib` + `policy_card.md` |
| **Planes** | [`PLAN_INTEGRACION_MONOGRAFIA.md`](../../PLAN_INTEGRACION_MONOGRAFIA.md) |

### Pregunta de valor (disrupción)

> *Con capacidad para tratar solo el 20%, un score de riesgo y un CATE **no** eligen a las mismas personas.*  
> *B3 pone la política causal en manos de un decisor no técnico (Space), con disclaimer de validez.*

## Local

```bash
cd 04_notebooks_produccion_hf/B3_policy_space
python scripts/sync_a4_artifacts.py
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
export PYTHONPATH="../../03_notebooks_caso_estudio:$PYTHONPATH"
python app.py
# → http://127.0.0.1:7860
```

## Tests / autograder

```bash
export PYTHONPATH="../../03_notebooks_caso_estudio:$PYTHONPATH"
pytest tests/ -q
python ../autograder/grade_b3.py
```

## Hugging Face Spaces (manual)

1. Crear Space Gradio (CPU).  
2. Subir `app.py`, `policy_service.py`, `requirements.txt`, `artifacts/`.  
3. Asegurar unpickle de `Policy` (path a `lib` o shim).  
4. Mantener el disclaimer de la UI.

## Humo

- [x] `policy.predict` → `{decision, uplift_score}`  
- [x] 3 casos de prueba finitos  
- [x] policy_card + disclaimer docente  
