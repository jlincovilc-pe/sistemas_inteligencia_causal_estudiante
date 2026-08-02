# Monografía del curso — IA Causal en Producción

| Artefacto | Ruta |
|---|---|
| **Fuentes Typst** | [`monografia-ml-causal-typst/`](./monografia-ml-causal-typst/) |
| **PDF compilado** | [`monografia_IA_Causal_en_Produccion.pdf`](./monografia_IA_Causal_en_Produccion.pdf) |
| PDF (también en carpeta del proyecto) | `monografia-ml-causal-typst/monografia.pdf` |
| **Nota histórica** | [`HISTORICO.md`](./HISTORICO.md) — qué es canónico vs esqueleto antiguo |

## Compilar de nuevo

```bash
cd monografia-ml-causal-typst
typst compile main.typ monografia.pdf
cp monografia.pdf ../monografia_IA_Causal_en_Produccion.pdf
```

Requiere [Typst](https://typst.app/) ≥ 0.12 (probado con 0.15.1).

## Contenido

32 capítulos · 9 partes · 8 apéndices · bibliografía Hayagriva · figuras PNG.

| Documento | Rol |
|---|---|
| [`../PLAN_INTEGRACION_MONOGRAFIA.md`](../PLAN_INTEGRACION_MONOGRAFIA.md) | Plan profesional de integración monografía × monorepo |
| [`../PLAN_CURSO_COMPLETO.md`](../PLAN_CURSO_COMPLETO.md) | Labs, Serie A/B, datos |

**Enfoque del curso:** profesionales · casos de estudio · producción en Hugging Face · utilidad de estimar el **efecto causal** (no solo predecir).
