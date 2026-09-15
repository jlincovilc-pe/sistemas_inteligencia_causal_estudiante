# Guía del proyecto final (S29–S32)

**Peso:** 40% · **Plan:** [`../PLAN_CURSO_COMPLETO.md`](../PLAN_CURSO_COMPLETO.md)

## Objetivo

Entregar un **sistema de IA causal en producción** orientado a *profesionales*, que integre:

1. Pregunta causal + identificación (estilo A1)  
2. Estimación ATE y/o CATE (estilo A2/A3)  
3. Servicio o Space desplegable en **Hugging Face (vía preferida y recomendada)** — Hub o Space con URL pública; el **local documentado es vía de contingencia** ante fallas de conectividad, no una opción equivalente (estilo B1 y/o B3; rúbrica: 18 pts con push real vs 13 pts local)  
4. Model card causal (estilo B2 / Ap. G)  
5. Al menos una señal de monitoreo (estilo B4)  
6. **Sección obligatoria:** comparación *ranking predictivo vs política causal* bajo el mismo presupuesto (disrupción del efecto)  

**Criterios irrenunciables:** (a) prueba de humo; (b) sección predictivo vs causal con al menos una métrica (ver `rubrica_proyecto.md`).
## Datos

Solo monorepo `data_benchmark_causal/causal_benchmark_synthetic/datasets/`  
(o extensión documentada del mismo esquema). Transparencia sintético/real obligatoria.

## Milestones

| ID | Sesión | Entrega |
|---|---|---|
| **P1** | S29 | Repo + DAG/estimando + dataset elegido + baseline ATE |
| **P2** | S30 | Peer review de 2–3 proyectos (rúbrica) |
| **P3** | S31 | Sistema HF/local + defensa en video + model card |
| **P4** | S32 | Cierre: límites, trabajo futuro, encuesta curso |

## Estructura de repo sugerida

```text
proyecto_<apellido>/
  README.md
  model_card.md
  notebooks/
  src/                 # inference pura
  service/ o space/    # FastAPI o Gradio
  tests/test_humo.py
  artifacts/
```

## Reutilización del curso

Podéis **partir** de artefactos A2/A4 y B1–B4, pero el proyecto debe:

- Declarar qué reutilizáis y qué es original  
- Correr humo en CI o script local  
- No presentar datos sintéticos como clínicos reales  

Ver también [`rubrica_proyecto.md`](./rubrica_proyecto.md) y [`checklist_humo.md`](./checklist_humo.md).
