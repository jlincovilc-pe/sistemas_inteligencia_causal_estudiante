# Nota histórica — esqueleto y fuentes de verdad

## Qué es canónico (2026)

| Artefacto | Rol |
|---|---|
| [`monografia-ml-causal-typst/`](./monografia-ml-causal-typst/) | Fuentes Typst de la monografía (**32 capítulos**) |
| [`monografia_IA_Causal_en_Produccion.pdf`](./monografia_IA_Causal_en_Produccion.pdf) | PDF compilado |
| [`../01_silabo/`](../01_silabo/) | Sílabo alineado a Caps. 1–32 del PDF + labs A/B |
| [`../PLAN_INTEGRACION_MONOGRAFIA.md`](../PLAN_INTEGRACION_MONOGRAFIA.md) | Integración libro ↔ monorepo (enfoque profesional / HF) |
| [`../PLAN_CURSO_COMPLETO.md`](../PLAN_CURSO_COMPLETO.md) | Práctica: labs, Serie A/B, datos, DoD de código |

## Qué quedó histórico

En diseños previos del monorepo existía una carpeta del tipo `02_monografia_esqueleto/` con un **esqueleto de ~26 capítulos** y un mapeo sesión→capítulo de la edición corta. Ese documento:

- **No** es la monografía compilable.
- **Omitía** capítulos que hoy viven en el PDF (p. ej. PDS extendido, panel/DML-IV, deep causal, matrix completion).
- Usaba numeración “Typst Cap. N” que el sílabo antiguo citaba y que **ya no coincide** con el PDF de 32 caps.

Si aún tienes una copia local del esqueleto fuera de este árbol, trátala como **archivo de diseño**, no como guía de lectura del curso.

## Cómo navegar a partir de ahora

1. Leer el PDF por **título de capítulo** o número **1–32** del índice actual.  
2. Para la semana: sílabo (`silabo.pdf`) → columna *Lectura monografía* + *Lab* + *Entrega*.  
3. Para código: monorepo `03_` / `04_` / `05_` según el plan de práctica.

## Compilación

```bash
cd monografia-ml-causal-typst
typst compile main.typ monografia.pdf
cp monografia.pdf ../monografia_IA_Causal_en_Produccion.pdf
```
