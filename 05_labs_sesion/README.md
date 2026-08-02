# Labs de sesión (L01–L28)

**Plan canónico:** [`../PLAN_CURSO_COMPLETO.md`](../PLAN_CURSO_COMPLETO.md)

Labs formativos (30–50 min). **No** sustituyen entregas A/B (4+4).  
**Sin L16** (S16 = examen parcial).

## Suite completa — 27 labs con smoke ✅

```bash
export PYTHONPATH="$PWD/05_labs_sesion:$PWD/03_notebooks_caso_estudio:$PWD/04_notebooks_produccion_hf/B1_fastapi_dml:$PWD/04_notebooks_produccion_hf/B4_monitoring_dashboard"
pytest 05_labs_sesion/tests/ -q
# → 27 passed
```

| Lab | Sesión | Tema |
|---|---|---|
| L01 | S1 | Correlación ≠ causación + Simpson |
| L02 | S2 | Entorno Git/Python/monorepo (+ Docker opcional) |
| L03 | S3 | Clasificar preguntas PCH (10 ítems) |
| L04–L06 | S4–S6 | Jobs → A1 |
| L07 | S7 | Backdoor vs latente |
| L08–L11 | S8–S11 | → A2 |
| L12, L14 | S12, S14 | → B1 |
| L13, L15 | S13, S15 | → A3 + checklist |
| L17–L18 | S17–S18 | → B2 |
| L19–L20 | S19–S20 | Explicación / importancia asociativa |
| L21–L23 | S21–S23 | → A4 / B3 |
| L24 | S24 | Transportabilidad |
| L25 | S25 | KS drift → B4 |
| L26 | S26 | Esqueleto discovery |
| L27 | S27 | Reentrenar vs alertar |
| L28 | S28 | Comunicar ATE |

Cada lab: `lab_core.py` + `checks.py` + **`lab.ipynb`** (generado).

```bash
# Regenerar notebooks de estudiante
python 05_labs_sesion/scripts/generate_lab_notebooks.py
```
