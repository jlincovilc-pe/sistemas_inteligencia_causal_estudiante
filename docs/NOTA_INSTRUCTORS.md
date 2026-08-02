# Nota para instructors — camino profesional ★ vs electivos ◇

**Curso:** IA Causal en Producción (ECO-490 / ECON-540, 2026)  
**Audiencia:** profesionales (data / ML / product / analytics / risk / ops), no perfil de investigación básica.

## Fuentes de verdad

| Pregunta | Documento |
|---|---|
| Calendario y evaluación | `01_silabo/silabo.pdf` |
| Caps. monografía (1–32) | `02_monografia/monografia_IA_Causal_en_Produccion.pdf` |
| Integración libro↔repo | `PLAN_INTEGRACION_MONOGRAFIA.md` |
| Labs / A / B / datos | `PLAN_CURSO_COMPLETO.md` |
| Esqueleto antiguo | `02_monografia/HISTORICO.md` (**no canónico**) |

## Promesa del curso (mensaje en vivo)

> Deja de priorizar solo con scores predictivos. Estima **efectos**, documenta supuestos y despliega en **Hugging Face** — con monitoreo de cuándo el efecto deja de valer.

Cierra cada bloque con: *si solo predijéramos, ¿a quién trataríamos? Con el efecto, ¿cambia la decisión?*

## Camino crítico ★ (obligatorio)

Hilo de producto **CDS**:

```text
A1 Jobs → A2 DML → B1 API → B2 Hub/CI → A3 CATE → A4 policy → B3 Space → B4 monitor → Proyecto HF
```

- **Labs L01–L15, L17–L28** (sin L16 = examen): formativos; no sustituyen A/B.  
- **Serie A (20%)** + **Serie B (15%)** + **Proyecto (40%)** con sección **predictivo vs causal** irrenunciable.  
- Datos solo monorepo (`data_benchmark_causal/.../datasets/`).

## Electivos ◇ (no bloquean aprobar / HF)

| Cap. monografía | Tema | Cuándo usarlo |
|---:|---|---|
| 5 | Predicción y causalidad (refuerzo) | Lectura extra tras S1; en vivo priorizar Cap. 1 |
| 16 | PDS extendido | Cohorte muy econométrica; si no, L05 + Cap. 6 bastan |
| 17 | Panel / DML-IV | Oficina de proyectos sectoriales |
| 18 | Mapa de decisión metodológica | Guía de proyecto final |
| 27 | Deep causal | Solo si el caso de negocio lo exige |
| 28 | SCM / matrix completion | Idem |

**Regla:** el profesional puede completar el curso y el proyecto HF **sin** dominar 17/27/28.

## Navegación semanal (plantilla instructor)

1. Sílabo: sesión → **Cap. N (título del PDF)** + Lab Lxx + entrega.  
2. No digas “Typst Cap. 4” de la edición corta: esa numeración **está obsoleta**.  
3. Código: monorepo `03_` / `04_` / `05_`.  
4. Contrato de datos del libro vs repo: CSV + `lib` / `CausalSchema.from_scenario` (no Parquet obligatorio).

## Evaluación — recordatorios

| Componente | Peso | Criterio duro |
|---|---:|---|
| Proyecto | 40% | Humo + sección **predictivo vs causal** |
| Serie A | 20% | Metodología + autograder |
| Serie B | 15% | Humo API/Space/CI/monitor |
| Peer / quizzes / Hub | 25% | Según sílabo |

## Checklist de la primera semana

- [ ] Entregar `silabo.pdf` + link al monorepo  
- [ ] Mostrar tabla maestra (sílabo §7 o plan de integración §3)  
- [ ] Lab 0 (L02): entorno + monorepo  
- [ ] Anunciar electivos ◇ y que no entran al parcial de camino ★  
- [ ] Demo de 5 min: predicción vs efecto (L01 / Cap. 1)  

## Contacto de integridad técnica

```bash
bash scripts/audit_repo.sh   # debe terminar en AUDIT PASS
```
