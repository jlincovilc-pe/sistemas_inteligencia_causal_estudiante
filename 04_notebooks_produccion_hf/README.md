# Serie B — Producción en Hugging Face

**Enfoque:** profesionales · efecto causal operable · HF Hub / Spaces / CI.

| ID | Carpeta | Caps. monografía | Labs | Insumo | Autograder |
|---|---|---|---|---|---|
| **B1** | [`B1_fastapi_dml/`](./B1_fastapi_dml/) | **15** | L12, L14 | A2 joblib | `grade_b1` 11/11 |
| **B2** | [`B2_hub_cicd/`](./B2_hub_cicd/) | **19–20**, Ap. G | L17, L18 | B1 + A2 | `grade_b2` 11/11 |
| **B3** | [`B3_policy_space/`](./B3_policy_space/) | **21–22** | L22, L23 | A4 policy | `grade_b3` 11/11 |
| **B4** | [`B4_monitoring_dashboard/`](./B4_monitoring_dashboard/) | **30–32** | L25, L27, L28 | drift sim. | `grade_b4` 8/8 |

### Hilo de valor

```text
A2 ATE ──► B1 API ──► B2 card/CI
                 └──► B4 monitor (¿sigue valiendo el efecto?)
A4 policy ──► B3 Space (¿quién tratar con 20% capacidad?)
```

Planes: [`../PLAN_CURSO_COMPLETO.md`](../PLAN_CURSO_COMPLETO.md) · [`../PLAN_INTEGRACION_MONOGRAFIA.md`](../PLAN_INTEGRACION_MONOGRAFIA.md).
