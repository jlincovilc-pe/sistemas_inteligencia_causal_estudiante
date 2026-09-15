# Cronograma semana a semana — Sistema de Inteligencia Causal

**Curso:** ECO-490 / ECON-540 · Edición 2026 · 16 semanas · 32 sesiones  
**Audiencia:** profesionales · **Norte:** casos de estudio + producción en Hugging Face + utilidad del **efecto causal**

| Fuente de verdad | Ruta |
|---|---|
| Sílabo PDF | `01_silabo/silabo.pdf` |
| Monografía PDF | `02_monografia/monografia_IA_Causal_en_Produccion.pdf` |
| Labs | `05_labs_sesion/Lxx/lab.ipynb` (+ `lab_core.py`) |
| Serie A | `03_notebooks_caso_estudio/notebooks/` |
| Serie B | `04_notebooks_produccion_hf/` |
| Diapositivas | `07_diapositivas/capitulos/` (mazo Touying por capítulo) |
| Proyecto | `06_proyecto_final/` |
| Integración | `PLAN_INTEGRACION_MONOGRAFIA.md` |
| Instructors | `docs/NOTA_INSTRUCTORS.md` |

### Leyenda

| Símbolo | Significado |
|---|---|
| ★ | Camino crítico profesional |
| ◇ | Lectura electiva (no bloquea HF) |
| **A1–A4** | Entrega sumativa Serie A |
| **B1–B4** | Entrega sumativa Serie B (HF) |
| Lab Lxx | Práctica formativa (~30–50 min) |

### Rutina semanal tipo (ambas partes)

| Quién | Antes de la sesión | Durante (1 h 30) | Después |
|---|---|---|---|
| **Profesor** | Revisar Cap. PDF + lab; preparar 1 pregunta de valor de negocio | 20′ concepto · 50–60′ lab guiado · 10–20′ cierre (disrupción) | Resolver dudas del hilo CDS; no retrasar entregas A/B |
| **Estudiante** | Leer Cap. indicado (título/número del PDF 32 caps.) | Hacer el lab en vivo o asíncrono | Completar lab + avanzar entrega A/B del bloque |

**Pregunta de cierre obligatoria (cada semana):**  
*Si solo predijéramos el outcome, ¿a quién trataríamos? Con el efecto, ¿cambia la decisión?*

---

## Semana 1 — Arranque (Módulo 0) ★

| | S1 | S2 |
|---|---|---|
| **Tema** | Correlación ≠ causación; problema fundamental; escalera de Pearl | Anatomía de un sistema ML en producción |
| **Monografía** | Cap. **1** | Cap. **2** |
| **Lab** | L01 | L02 (Lab 0 entorno) |
| **Entrega** | — | — |

### Profesor
- Presentar promesa del curso y monorepo; mostrar `silabo.pdf` + tabla Cap/Lab.
- **No** pedir notebook de entrega esta semana.
- S2: verificar que todos clonan el monorepo y pasan L02 (Git, Python, paths).

### Estudiante
- Leer Caps. 1–2 del PDF.
- Completar `05_labs_sesion/L01_…/lab.ipynb` y `L02_…/lab.ipynb`.
- Crear cuenta Hugging Face (puede ser solo registro; push en B2).

---

## Semana 2 — Fundamentos (Módulo 1) ★

| | S3 | S4 |
|---|---|---|
| **Tema** | SCM y PCH | Ingeniería de datos causal |
| **Monografía** | Cap. **3** | Cap. **4** (+ callout monorepo) |
| **Lab** | L03 | L04 |
| **Entrega** | — | **A1 arranca** |

### Profesor
- S3: ejercicio de clasificación PCH (L03).
- S4: presentar Jobs como *caso de decisión* (programa de empleo); abrir A1.
- Introducir `CausalSchema.from_scenario("real/jobs")` / `load_scenario`.

### Estudiante
- Labs L03–L04.
- Empezar A1: EDA, roles T/Y/X, borrador de DAG y estimando ATE.
- Datos: `datasets/real/jobs/`.

---

## Semana 3 — Identificación y A1 ★

| | S5 | S6 |
|---|---|---|
| **Tema** | Regularización y PDS | Datos de entrenamiento / splits |
| **Monografía** | Cap. **6** (+ Cap. **16** PDS ◇ opcional) | Cap. **7** |
| **Lab** | L05 | L06 |
| **Entrega** | A1 en curso | **A1 entrega** |

### Profesor
- Enfatizar: Cap. 16 es profundización; en vivo basta Cap. 6 + L05.
- Rúbrica A1: identificación escrita + PDS + sin usar truth en estimación.

### Estudiante
- Labs L05–L06.
- **Entregar A1** (notebook + justificación de identificación).
- Checklist: solo `observed_*`; splits oficiales.

---

## Semana 4 — Do-calculus y arranque A2 ★

| | S7 | S8 |
|---|---|---|
| **Tema** | Intervención / contrafactual | Features sin fuga |
| **Monografía** | Cap. **8** | Cap. **9** |
| **Lab** | L07 | L08 |
| **Entrega** | — | **A2 arranca** |

### Profesor
- S7: cuándo *abstenerse* (latente no identificable).
- S8: demo de leakage; abrir A2 (ihdp_medium).

### Estudiante
- Labs L07–L08.
- Empezar A2: sin fugas en X; leer Caps. 9–10.

---

## Semana 5 — DML (núcleo de estimación) ★

| | S9 | S10 |
|---|---|---|
| **Tema** | Neyman / cross-fitting | DML PLR/IRM |
| **Monografía** | Cap. **10** | Cap. **11** |
| **Lab** | L09 | L10 |
| **Entrega** | A2 en curso | A2 en curso |

### Profesor
- Insistir en cross-fitting y ortogonalidad (no “solo un XGBoost del outcome”).
- Conectar con disrupción: ATE con IC para go/no-go.

### Estudiante
- Labs L09–L10.
- Avanzar A2 (PLR, K-fold, dos learners).

---

## Semana 6 — Cierre A2 y B1 ★

| | S11 | S12 |
|---|---|---|
| **Tema** | Eval offline (Qini, placebo) | Despliegue FastAPI + Docker |
| **Monografía** | Cap. **14** | Cap. **15** |
| **Lab** | L11 | L12 |
| **Entrega** | **A2 entrega** | **B1 arranca** |

### Profesor
- S11: cerrar A2; serialización joblib.
- S12: demo B1 `/health` y `/predict`; training–serving skew.

### Estudiante
- **Entregar A2** (joblib + meta en `artifacts/A2/`).
- Lab L11–L12; clonar/ejecutar `04_…/B1_fastapi_dml`.
- Sync: `python scripts/sync_a2_artifacts.py`.

---

## Semana 7 — CATE y entrega B1 ★

| | S13 | S14 |
|---|---|---|
| **Tema** | Meta-learners | Bosques causales + humo B1 |
| **Monografía** | Cap. **12** | Cap. **13** (+ 15) |
| **Lab** | L13 | L14 |
| **Entrega** | **A3 arranca** | **B1 entrega** |

### Profesor
- Ranking por CATE ≠ ranking por riesgo predicho (mensaje de disrupción).
- S14: cerrar B1 con autograder / Docker opcional.

### Estudiante
- Empezar A3 (IHDP, T-learner default).
- **Entregar B1** (API humo en verde).
- Lab L13–L14.

---

## Semana 8 — Checkpoint ★

| | S15 | S16 |
|---|---|---|
| **Tema** | Integración sistema causal | Examen parcial |
| **Monografía** | Repaso Caps. 1–15 | — |
| **Lab** | L15 | — |
| **Entrega** | **A3 entrega** | Parcial (camino ★) |

### Profesor
- S15: checklist A1–A3 + B1 (L15).
- S16: parcial **sin** caps. electivos 17/27/28 como núcleo.

### Estudiante
- **Entregar A3** (scores CATE para A4).
- Lab L15.
- Estudiar camino ★ (no deep causal).

---

## Semana 9 — Hugging Face Hub y CI ★

| | S17 | S18 |
|---|---|---|
| **Tema** | Model cards causales + Hub | CI/CD Actions |
| **Monografía** | Cap. **19** · Ap. G | Cap. **20** |
| **Lab** | L17 | L18 |
| **Entrega** | B2 en curso | **B2 entrega** |

### Profesor
- Model card = supuestos + población + límites (no solo accuracy).
- Demo: workflow que falla si humo B1 falla.

### Estudiante
- Labs L17–L18.
- **Entregar B2** (card + CI documentado; push HF si hay token).

---

## Semana 10 — Explicación y fairness ★

| | S19 | S20 |
|---|---|---|
| **Tema** | Explicación causal vs asociativa | Interpretabilidad / fairness |
| **Monografía** | Cap. **23** | Cap. **24** |
| **Lab** | L19 | L20 |
| **Entrega** | — | — |

### Profesor
- Dejar claro: SHAP sobre $\hat Y$ **no** es efecto causal.
- Preparar mentalmente el bloque policy (S21–S23).

### Estudiante
- Labs L19–L20.
- Opcional: releer model card B2 con ojo de “mal uso”.

---

## Semana 11 — Decisión y policy ★

| | S21 | S22 |
|---|---|---|
| **Tema** | Decisiones bajo incertidumbre | Policy learning / presupuesto |
| **Monografía** | Cap. **25** | Cap. **21** |
| **Lab** | L21 | L22 |
| **Entrega** | — | **A4 arranca** |

### Profesor
- Formalizar decisión de negocio antes del umbral λ.
- Introducir B = 20% como restricción de capacidad.

### Estudiante
- Labs L21–L22.
- Empezar A4 con scores de A3.

---

## Semana 12 — Uplift, A4 y Space ★

| | S23 | S24 |
|---|---|---|
| **Tema** | Uplift / targeting + Space | Transportabilidad |
| **Monografía** | Cap. **22** | Cap. **26** |
| **Lab** | L23 | L24 |
| **Entrega** | **A4 entrega** · **B3 arranca** | — |

### Profesor
- Exigir en A4 la comparación policy causal vs random vs outcome-only.
- Demo B3 Gradio (decisor no técnico).

### Estudiante
- **Entregar A4** (policy.joblib + policy card).
- Labs L23–L24; arrancar B3 Space.
- Framing: ¿el efecto vale en *mi* mercado? (S24).

---

## Semana 13 — Monitoreo y discovery ★

| | S25 | S26 |
|---|---|---|
| **Tema** | Drift / monitoreo de supuestos | Discovery (PC/NOTEARS; lab ligero) |
| **Monografía** | Cap. **30** | Cap. **29** |
| **Lab** | L25 | L26 |
| **Entrega** | **B4 arranca** | **B3 entrega** |

### Profesor
- “200 OK” no implica efecto válido.
- Cerrar B3; abrir B4.

### Estudiante
- **Entregar B3** (Space o demo local + humo).
- Labs L25–L26; avanzar B4.

---

## Semana 14 — Continual learning y cierre de B4 ★

| | S27 | S28 |
|---|---|---|
| **Tema** | Reentrenar vs alertar; panorama RL | Comunicación y lado humano |
| **Monografía** | Cap. **31** | Cap. **32** |
| **Lab** | L27 | L28 |
| **Entrega** | B4 en curso | **B4 entrega** |

### Profesor
- Reglas de ops (L27); plantilla de comunicación en 3 capas (L28 / Cap. 32).
- Presentar brief del **proyecto final** (S29–S32).

### Estudiante
- Labs L27–L28.
- **Entregar B4**.
- Empezar a elegir caso de proyecto (puede reutilizar A/B).

---

## Semana 15 — Proyecto final (P1–P2) ★

| | S29 | S30 |
|---|---|---|
| **Tema** | Trabajo autónomo + mentoría | Peer review |
| **Monografía** | Ap. E, G, H · `06_proyecto_final/` | Rúbrica |
| **Hito** | **P1** | **P2** (10%) |

### Profesor
- Office hours: identificación + humo + sección predictivo vs causal.
- Organizar pares de peer review.

### Estudiante
- **P1:** repo + pregunta causal + datos monorepo + baseline.
- **P2:** revisar 2–3 proyectos con rúbrica.
- Avanzar despliegue HF y model card.

---

## Semana 16 — Defensa y cierre ★

| | S31 | S32 |
|---|---|---|
| **Tema** | Presentaciones / defensa | Cierre y frontera |
| **Monografía** | — | Caps. electivos 27–28 solo si el caso lo pide ◇ |
| **Hito** | **P3 — entrega final 40%** | **P4** encuesta / límites |

### Profesor
- Evaluar humo + sección disrupción (irrenunciables).
- S32: límites, ética, qué no cubrió el curso.

### Estudiante
- **P3:** sistema en HF (o local documentado) + video + README 3 capas.
- Encuesta de cierre; no se exige deep causal.

---

## Calendario de entregas (vista rápida)

| Semana | Entrega | Peso relativo (bloque) |
|---:|---|---|
| 3 | **A1** | Serie A |
| 6 | **A2** | Serie A → B1 |
| 7 | **B1** | Serie B |
| 8 | **A3** | Serie A → A4 |
| 9 | **B2** | Serie B (HF Hub/CI) |
| 12 | **A4** | Serie A → B3 |
| 13 | **B3** | Serie B (Space) |
| 14 | **B4** | Serie B (monitor) |
| 15 | P1, P2 | Proyecto |
| 16 | **P3** (+ P4) | Proyecto 40% |

Serie A = 20% · Serie B = 15% · Proyecto = 40% · resto según sílabo.

---

## Checklist semanal del estudiante (plantilla)

```text
[ ] Leí el Cap. N del PDF (título correcto del índice 32 caps.)
[ ] Completé lab.ipynb / checks en verde
[ ] Avancé la entrega A/B del bloque (si aplica)
[ ] Escribí 3 líneas: predictivo vs efecto en este tema
[ ] No usé truth_* fuera de evaluación
```

## Checklist semanal del profesor (plantilla)

```text
[ ] Cap. + lab listos; 1 ejemplo de negocio del sector de la cohorte
[ ] Recordé numeración PDF (no “Typst Cap.” antiguo)
[ ] Cierre con pregunta de disrupción
[ ] Office hours solo si hay bloqueo de entrega A/B
[ ] Electivos ◇ no consumen el parcial de camino ★
```

---

## Rutas de apertura rápida por rol

### Primera vez (estudiante)
1. `01_silabo/silabo.pdf`  
2. Este cronograma (semana actual)  
3. Cap. monografía de la semana  
4. `05_labs_sesion/Lxx/lab.ipynb`  
5. Si hay entrega: notebook A o carpeta B  

### Primera vez (profesor)
1. `docs/NOTA_INSTRUCTORS.md`  
2. `silabo.pdf` + este cronograma  
3. `bash scripts/audit_repo.sh` (verificar monorepo sano)  
4. Demo de 10′: L01 + promesa del curso  

---

*Cronograma alineado a sílabo 2026, monografía 32 caps., labs L01–L28 y Serie A/B del monorepo.*
