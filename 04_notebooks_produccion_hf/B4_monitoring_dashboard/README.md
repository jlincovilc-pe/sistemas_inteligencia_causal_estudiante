# B4 — Dashboard de monitoreo causal

| | |
|---|---|
| **Sesiones** | S25–S28 |
| **Lectura monografía** | Cap. **30** Monitoreo · Cap. **31** Continual learning · Cap. **32** Lado humano |
| **Labs** | L25 · L27 · L28 |
| **Insumo** | Baseline `ihdp_medium` + drift simulado (docente) |
| **Planes** | [`PLAN_INTEGRACION_MONOGRAFIA.md`](../../PLAN_INTEGRACION_MONOGRAFIA.md) |

### Pregunta de valor (disrupción)

> *Un endpoint que “sigue respondiendo 200 OK” puede estar sirviendo un efecto **ya inválido**.*  
> *B4 enseña a alertar por drift de supuestos y a decidir: reentrenar vs solo alertar.*

## Local

```bash
cd 04_notebooks_produccion_hf/B4_monitoring_dashboard
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
export PYTHONPATH="../../03_notebooks_caso_estudio:$PYTHONPATH"
streamlit run app.py
```

## Tests / autograder

```bash
export PYTHONPATH="../../03_notebooks_caso_estudio:$PYTHONPATH"
pytest tests/ -q
python ../autograder/grade_b4.py
```

## Métricas

1. **KS** por covariable (drift)  
2. **Tasa de tratamiento** en ventana  
3. **Proxy de contraste** (ilustrativo; no sustituye ATE de B1)

Humo: con drift inyectado, ≥1 alerta KS sobre umbral configurable.
