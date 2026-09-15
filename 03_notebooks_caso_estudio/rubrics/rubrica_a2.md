# Rúbrica — Notebook A2: Double Machine Learning (PLR)

**Curso:** Sistema de Inteligencia Causal (ECO-490 / ECON-540)  
**Notebook:** `notebooks/A2_dml_ihdp_medium.ipynb`  
**Dataset:** `synthetic/inference/ihdp_medium` (`scenario_id`: `synthetic_inference_ihdp_medium`)  
**Peso total:** 100 puntos  
**Autograder de apoyo:** `autograder/grade_a2.py` (no sustituye la evaluación metodológica escrita)

---

## Resumen de pesos

| # | Criterio | Puntos |
|---|----------|-------:|
| 1 | Especificación PLR correcta | 20 |
| 2 | Cross-fitting sin fuga | 25 |
| 3 | Diagnóstico Neyman | 15 |
| 4 | Sensibilidad de learners | 20 |
| 5 | Interpretación + serialización | 20 |
|   | **Total** | **100** |

---

## 1. Especificación PLR correcta (20 pts)

| Nivel | Pts | Descripción |
|-------|----:|-------------|
| Excelente | 18–20 | Declara \(Y = \theta T + g(X)+\varepsilon\), \(T=m(X)+\eta\); estimando ATE; roles \(Y\)=`outcome`, \(T\)=`treatment`, \(X\)=`x0`…`x24`; baselines (DIM/OLS/IPW) coherentes. |
| Suficiente | 12–17 | PLR y ATE presentes; roles correctos; baselines incompletos o sin contraste con scorecard. |
| Insuficiente | 0–11 | Confunde DML con OLS simple sin residualizar; omite nuisances; o usa truth en estimación. |

**Evidencia:** secciones de modelo PLR + baselines; sin `y0`/`y1`/`tau` fuera de § evaluación final.

---

## 2. Cross-fitting sin fuga (25 pts)

| Nivel | Pts | Descripción |
|-------|----:|-------------|
| Excelente | 22–25 | K-fold (K=5) documentado; nuisances entrenados fuera del fold de residuales; usa `lib.dml_utils` o implementación equivalente auditable. |
| Suficiente | 14–21 | Cross-fitting presente pero mal documentado, o K distinto sin justificación. |
| Insuficiente | 0–13 | Entrena y predice residuales en la misma muestra sin OOF; o no hay DML real. |

**Autograder (apoyo):** reestimación de referencia con cross-fit; inspección estática de que el notebook invoca cross-fitting / `fit_plr` / `cross_fit_residuals`.

---

## 3. Diagnóstico Neyman (15 pts)

| Nivel | Pts | Descripción |
|-------|----:|-------------|
| Excelente | 13–15 | Residuales \(\tilde Y, \tilde T\); correlaciones con scores de nuisance; scatter residual-on-residual interpretado. |
| Suficiente | 8–12 | Calcula residuales o correlaciones sin interpretar. |
| Insuficiente | 0–7 | Sin diagnóstico de ortogonalidad. |

---

## 4. Sensibilidad de learners (20 pts)

| Nivel | Pts | Descripción |
|-------|----:|-------------|
| Excelente | 18–20 | Al menos dos pares de nuisances (p. ej. Lasso vs HistGB/RF/GBM); tabla ATE ± SE/IC; comenta estabilidad. |
| Suficiente | 12–17 | Dos learners corridos pero sin tabla o sin comentario. |
| Insuficiente | 0–11 | Una sola especificación sin sensibilidad. |

**Autograder (apoyo, `expected_ranges.yaml` → `a2_ihdp_medium`):**

- \(|\widehat{\mathrm{ATE}}_{\mathrm{DML}} - 3.9685| < 0.5\) (especificación Lasso / oficial del curso)
- IC reportado; cobertura del punto `ate_true` **o** longitud de IC documentada si falla por azar (soft)

---

## 5. Interpretación + serialización (20 pts)

| Nivel | Pts | Descripción |
|-------|----:|-------------|
| Excelente | 18–20 | Model card / reflexión con supuestos y límites; artefactos `dml_estimator.joblib`, `feature_list.json`, `training_meta.json`; interfaz `const_marginal_ate` / `predict` usable en B1. |
| Suficiente | 12–17 | Artefacto joblib presente; texto breve; sidecars incompletos. |
| Insuficiente | 0–11 | Sin serialización o sin texto metodológico. |

**Autograder (apoyo):**

- Existe `artifacts/A2/dml_estimator.joblib`
- `load` + `const_marginal_ate()` (o `ate` / `predict`) responde
- `feature_list.json` y `training_meta.json` presentes y coherentes

---

## Penalizaciones transversales

| Incumplimiento | Penalización orientativa |
|----------------|--------------------------|
| Uso de `y0` / `y1` / `tau` en celdas de estimación (fuera de § evaluación final) | −15 a −30 (fuga de truth) |
| Paths absolutos de máquina o descargas externas | −5 a −10 |
| Notebook no ejecutable (import / rutas) | Hasta −20 según gravedad |
| Artefacto no cargable en script estilo B1 | −10 a −15 |

---

## Qué evalúa el autograder vs. el humano

| Chequeo | Autograder | Revisor humano |
|---------|:----------:|:--------------:|
| Truth no usado en estimación (grep notebook) | Sí | Sí |
| AE del DML-Lasso vs `ate_true` | Sí | Opcional |
| Cross-fitting invocado / reestimado | Sí | Lectura de código |
| Artefactos A2 + interfaz B1 | Sí | Contrato |
| Calidad del diagnóstico Neyman y reflexión | Heurística | **Sí (peso alto)** |
| Interpretación de sensibilidad de learners | No | **Sí** |

La nota final la define la rúbrica humana; `grade_a2.py` es un **filtro de sanidad** y apoyo a la corrección a escala.

---

## Entregables esperados del estudiante

1. Notebook completado (DML + Neyman + learners + IC).  
2. Tabla comparativa de especificaciones.  
3. Artefactos en `artifacts/A2/` para B1.  
4. Model card / reflexión metodológica no vacía.
