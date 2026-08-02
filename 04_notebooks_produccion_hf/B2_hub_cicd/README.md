# B2 — Hub, model card causal y CI/CD

| | |
|---|---|
| **Sesiones** | S17–S18 |
| **Lectura monografía** | Cap. **19** Model cards y HF Hub · Cap. **20** CI/CD · **Ap. G** |
| **Labs** | L17 · L18 |
| **Insumo** | B1 + artefacto A2 |
| **Planes** | [`PLAN_INTEGRACION_MONOGRAFIA.md`](../../PLAN_INTEGRACION_MONOGRAFIA.md) |

### Pregunta de valor (disrupción)

> *Publicar un modelo sin supuestos es transferir riesgo a quien lo consume.*  
> *Una model card causal + CI que bloquea humo roto convierten el efecto en un **activo versionado**.*

## Contenido

| Archivo | Rol |
|---|---|
| [`model_card/MODEL_CARD.md`](./model_card/MODEL_CARD.md) | Model card **causal** (estimando, supuestos, límites) |
| [`templates/b1_smoke.yml`](./templates/b1_smoke.yml) | Plantilla educativa de humo B1 (no CI en la nube del monorepo) |
| [`scripts/prepare_hub_bundle.sh`](./scripts/prepare_hub_bundle.sh) | Empaqueta archivos para un Hub **opcional** |

## Checklist estudiante (local)

1. Personalizar `MODEL_CARD.md` con **tus** números de A2.  
2. Correr humo **en local**: `pytest` B1 + `python ../autograder/grade_b1.py`.  
3. Revisar la plantilla `templates/b1_smoke.yml` (concepto CI; el monorepo del curso **no** se publica a GitHub).  
4. Push a HF Hub: **opcional y manual** (solo en la cuenta del estudiante, si aplica).

## Humo B2

```bash
python ../autograder/grade_b2.py
```

- [x] Model card con estimando + supuestos + población + límites  
- [x] Plantilla de workflow definida (educativa)  
- [ ] Push real a HF (manual y opcional; no requerido por el monorepo)  
