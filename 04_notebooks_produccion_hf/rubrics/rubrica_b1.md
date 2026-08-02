# Rúbrica B1 — Endpoint DML (FastAPI + Docker)

| Criterio | Puntos | Notas |
|---|---:|---|
| Separación inference vs HTTP | 20 | `inference.py` puro; router delgado |
| Carga correcta del artefacto A2 | 20 | ATE ≈ training_meta |
| `/health` + `/predict` + `/metadata` | 25 | Contratos documentados |
| Latencia predict < 2 s | 10 | Autograder |
| Dockerfile + instrucciones | 15 | Build desde monorepo root |
| Discusión training–serving skew | 10 | Markdown en notebook o README |
| **Total** | **100** | |

Autograder de apoyo: `autograder/grade_b1.py`.
