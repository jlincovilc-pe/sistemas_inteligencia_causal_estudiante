# Rúbrica — Notebook A3: CATE (meta-learners y bosque causal)

**Curso:** IA Causal en Producción (ECO-490 / ECON-540)  
**Notebook:** `notebooks/A3_cate_meta_learners_ihdp.ipynb`  
**Dataset:** `real/ihdp` (`scenario_id`: `real_ihdp`)  
**Peso total:** 100 puntos  
**Autograder de apoyo:** `autograder/grade_a3.py` (no sustituye la evaluación metodológica escrita)

---

## Resumen de pesos

| # | Criterio | Puntos |
|---|----------|-------:|
| 1 | Meta-learners correctos (S/T/X/R) | 30 |
| 2 | Bosque causal (o fallback documentado) | 15 |
| 3 | Qini + placebo (validación sin truth) | 25 |
| 4 | PEHE / comparación (sección final) | 15 |
| 5 | Discusión metodológica | 15 |
|   | **Total** | **100** |

---

## 1. Meta-learners correctos (30 pts)

| Nivel | Pts | Descripción |
|-------|----:|-------------|
| Excelente | 27–30 | Implementa o invoca correctamente S-, T-, X- y R-learner sobre el mismo split train; CATE en test; roles \(Y\)=`outcome`, \(T\)=`treatment`, \(X\)=covars Hill-style; sin truth en estimación. |
| Suficiente | 18–26 | Al menos tres meta-learners correctos; o cuatro con documentación incompleta. |
| Insuficiente | 0–17 | Confunde CATE con ATE único; omite la mayoría de learners; o usa `y0`/`y1`/`tau` para entrenar. |

**Evidencia:** celdas de `lib.cate_utils` (`fit_s_learner` / `fit_t_learner` / `fit_x_learner` / `fit_r_learner` o `fit_meta_learners`).

---

## 2. Bosque causal (15 pts)

| Nivel | Pts | Descripción |
|-------|----:|-------------|
| Excelente | 13–15 | `CausalForestDML` (EconML) o **fallback T-learner RF** explícitamente documentado si `econml` no está; distribución de \(\hat\tau(x)\) comparada con meta-learners. |
| Suficiente | 8–12 | Hay un quinto estimador tipo forest/RF pero sin notar el backend. |
| Insuficiente | 0–7 | No hay bosque causal ni fallback. |

**Nota de runtime:** hiperparámetros moderados (`n_estimators` ~100, `cv`~3) son aceptables en CPU; documentar si se usan ajustes “smoke”.

---

## 3. Qini + placebo (25 pts)

| Nivel | Pts | Descripción |
|-------|----:|-------------|
| Excelente | 22–25 | Curva Qini (o uplift) en validation/test con ranking por \(\hat\tau\); prueba placebo (permutar `treatment`, reestimar T-learner) con interpretación de ATE ≈ 0; sin usar truth. |
| Suficiente | 14–21 | Qini o placebo presentes pero uno de los dos incompleto o mal interpretado. |
| Insuficiente | 0–13 | No hay validación offline; o se “valida” solo con PEHE en el cuerpo principal. |

**Autograder (apoyo, `expected_ranges.yaml` → `a3_ihdp`):**

- \(|\widehat{\mathrm{ATE}}_{\mathrm{placebo}}| < 0.5\) (escala IHDP)

---

## 4. PEHE / comparación (15 pts)

| Nivel | Pts | Descripción |
|-------|----:|-------------|
| Excelente | 13–15 | Sección final **marcada** de evaluación con truth; PEHE y/o MAE(\(\tau\)) por método; compara con `scorecard.json` (`inference_t_learner_random_forest.pehe` ≈ 3.91). |
| Suficiente | 8–12 | Calcula PEHE de un método sin tabla comparativa. |
| Insuficiente | 0–7 | No hay sección PEHE, o truth se usa fuera de la sección marcada. |

**Autograder (apoyo):**

- PEHE del T-learner de referencia en test \(< 8.0\) (techo; no se exige batir el scorecard)

---

## 5. Discusión metodológica (15 pts)

| Nivel | Pts | Descripción |
|-------|----:|-------------|
| Excelente | 13–15 | Elige learner para A4 (por defecto del curso: **T-learner**) con argumento (desbalance, Qini, estabilidad de distribuciones); comenta límites de validación sin truth. |
| Suficiente | 8–12 | Hay reflexión breve pero genérica. |
| Insuficiente | 0–7 | Sin discusión; solo código. |

**Artefactos esperados (insumo A4):**

```text
artifacts/A3/cate_scores_test.csv
artifacts/A3/qini_plot.png
artifacts/A3/cate_comparison.png
```

Columnas mínimas del CSV: `row_id`, `tau_hat_<method>` (varios), `method_selected`.

---

## Penalizaciones transversales

| Incumplimiento | Penalización orientativa |
|----------------|--------------------------|
| Uso de `y0` / `y1` / `tau` en celdas de estimación (fuera de § evaluación final / PEHE) | −15 a −30 (fuga de truth) |
| Paths absolutos de máquina o descargas externas | −5 a −10 |
| Notebook no ejecutable (import / rutas) | Hasta −20 según gravedad |
| Artefacto `cate_scores_test.csv` ausente o sin columnas CATE | −10 a −15 |

---

## Qué evalúa el autograder vs. el humano

| Chequeo | Autograder | Revisor humano |
|---------|:----------:|:--------------:|
| Truth no usado en estimación (grep notebook) | Sí | Sí |
| Placebo \|ATE\| bajo umbral | Sí | Interpretación |
| PEHE T-learner techo | Sí | Comparación con scorecard |
| Artefactos A3 (CSV + plots) | Sí | Contrato A4 |
| Calidad de Qini / discusión X vs T | Heurística | **Sí (peso alto)** |
| Transparencia de datos sintéticos | Heurística | **Sí** |

La nota final la define la rúbrica humana; `grade_a3.py` es un **filtro de sanidad** y apoyo a la corrección a escala.

---

## Entregables esperados del estudiante

1. Notebook completado (S/T/X/R + bosque causal + Qini + placebo).  
2. Gráfico comparativo de distribuciones de CATE.  
3. `artifacts/A3/cate_scores_test.csv` (y plots) para A4.  
4. Discusión de elección de learner + sección final PEHE marcada.
