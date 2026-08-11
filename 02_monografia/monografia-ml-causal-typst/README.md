# IA Causal en Producción — Edición 2026 (Typst)

Monografía del Curso ECO-490 / ECON-540. Título anterior: *Machine Learning Causal para Economistas*. Esta edición integra la filosofía pedagógica de *Designing Machine Learning Systems* (Chip Huyen) y el aparato conceptual de *Causal Artificial Intelligence* (Elias Bareinboim) con el contenido original de estimación causal, con un balance de 50% teoría / 50% ingeniería de producción.

Ver `PLAN_CONSTRUCCION.md` para el historial completo de esta expansión: qué capítulos son nuevos, cuáles se reubicaron de la edición anterior, y qué verificaciones se corrieron sobre cada uno.

## Contenido

- 32 capítulos distribuidos en 9 partes temáticas (Parte 0 más Partes I–VIII)
- 8 apéndices (A–H; G y H son nuevos en esta edición)
- Frontmatter (portada, prefacio, cómo usar, notación)
- Bibliografía Hayagriva (119 referencias, todas citadas en el texto)
- 10 figuras PNG (heredadas de la edición anterior; los capítulos nuevos no incluyen figuras propias)
- Dos plantillas de capítulo: Plantilla A (teoría e identificación causal, con teoremas/definiciones/algoritmos) y Plantilla B (ingeniería y producción, con problema de diseño/opciones/decisión de referencia), documentadas en `frontmatter/como_usar.typ`

## Compilación

```bash
cd 02_monografia/monografia-ml-causal-typst
typst compile main.typ monografia.pdf
```

Requiere Typst ≥ 0.12 (compilado con **Typst 0.15.1**).

**Estado (2026-08-10):** compilación completa **OK** → `monografia.pdf` (~5,9 MB, **357 pp.**). Copia en `02_monografia/monografia_IA_Causal_en_Produccion.pdf`.

Última revisión de contenido: pasada de mejora teórica y metodológica capítulo a capítulo sobre la base de `auditoria_contenido.md` (ver `CHANGELOG_MEJORA.md`, Etapa 1).

Integración pro/HF: frontmatter (prefacio, cómo usar, portada) + callouts `#monorepo[...]` en Caps. 4, 9, 15, 19, 20, 30. Ver `PLAN_INTEGRACION_MONOGRAFIA.md`.

Ajustes aplicados para compilar en este entorno:

- Fuente sans: `Helvetica Neue` (DejaVu Sans no disponible en el sistema).
- Teoremas/definiciones: título con `name: [...]` (Typst no acepta el patrón LaTeX `][título]` en esos macros).
- Ángulos en SCM: `⟨…⟩` Unicode (el símbolo `angle.l` no es válido en esta versión).
- Operador do en math: `$"do"$` / `$"do"(…)$`.

## Estructura del proyecto

```
.
├── main.typ                       # Punto de entrada
├── PLAN_CONSTRUCCION.md           # Historial de la expansión a 32 capítulos
├── template/
│   └── template.typ               # Plantilla (incluye funciones de Plantilla B: disenio, opciones, decisionref, cuadrodecision)
├── frontmatter/
│   ├── portada.typ
│   ├── prefacio.typ
│   ├── como_usar.typ
│   └── notacion.typ
├── partes/
│   └── parte0.typ … parte8.typ    # 9 partes
├── capitulos/
│   └── cap00_causalidad_elemental.typ … cap15d_lado_humano.typ   # 32 capítulos
├── apendices/
│   └── apA_notacion_fundamentos.typ … apH_checklist_despliegue.typ  # 8 apéndices
├── bibliografia/
│   └── refs.yml                   # Hayagriva
└── figuras/
    └── fig_cap*.png
```

## Notas de la migración original (LaTeX → Typst)

- Paleta cromática preservada: navy, crimson, gray, light, accent, green, orange.
- Entornos personalizados (cuadrosinoptico, riesgos, diagnosticos, notatecnica, intuicion, advertencia) implementados como funciones Typst.
- Teoremas con numeración compartida (teorema, proposición, lema, corolario, definición, supuesto, ejemplo, observación).
- Bibliografía: BibLaTeX → Hayagriva manual, estilo `chicago-author-date`.
- Listados de código envueltos en `figure(kind: raw)` para ser referenciables.

## Conversiones aplicadas (edición original)

- `\E{}` → `E` (en math mode)
- `\ref{cap:xxx}` → `@cap-xxx` (con `-` en lugar de `:`)
- `\citet{key}` → `@key`, `\citep{key}` → `[@key]`
- `\textbf{x}` → `*x*`, `\emph{x}` → `_x_`, `\texttt{x}` → `#code[x]`
- `tabularx` → `table(columns: (auto, 1fr))`
- `tcolorbox` → funciones `#cuadrosinoptico[...]`, `#riesgos[...]`, etc.
- `algorithm2e` → `#algorithm("Title")[...]` con `#kwin`, `#kwout`, `#for-loop`
