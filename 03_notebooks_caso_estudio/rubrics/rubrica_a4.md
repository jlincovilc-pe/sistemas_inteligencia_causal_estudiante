# Rúbrica — Notebook A4: Policy learning y uplift (IHDP)

**Curso:** Sistema de Inteligencia Causal (ECO-490 / ECON-540)  
**Notebook:** `notebooks/A4_policy_uplift_ihdp.ipynb`  
**Dataset:** `real/ihdp` (`scenario_id`: `real_ihdp`; continúa A3)  
**Peso total:** 100 puntos  
**Autograder de apoyo:** `autograder/grade_a4.py` (no sustituye la evaluación metodológica escrita)

---

## Resumen de pesos

| # | Criterio | Puntos |
|---|----------|-------:|
| 1 | De CATE a política bajo presupuesto \(B\) | 25 |
| 2 | Uplift / Qini | 20 |
| 3 | Baselines (random + outcome-only) | 20 |
| 4 | Equidad y límites | 20 |
| 5 | Serialización + policy card | 15 |
|   | **Total** | **100** |

---

## 1. De CATE a política bajo presupuesto \(B\) (25 pts)

| Nivel | Pts | Descripción |
|-------|----:|-------------|
| Excelente | 22–25 | Carga scores A3 (`cate_scores_test.csv`) o reestima T-learner documentado; calibra umbral / top-k a \(B\) (curso: 0.20); reporta treat rate ≈ \(B\); roles \(Y\)=`outcome`, \(T\)=`treatment`. |
| Suficiente | 14–21 | Hay política de umbral o top-k pero sin sensibilidad a \(B\) o sin reutilizar A3 cuando existe. |
| Insuficiente | 0–13 | Confunde política con ATE único; no hay restricción de presupuesto; o usa truth para calibrar \(\lambda\). |

**Evidencia:** `make_threshold_policy` / `threshold_from_budget` / `Policy.predict`.

**Autograder (`expected_ranges.yaml` → `a4_ihdp`):**

- fracción tratada ≈ `budget_fraction` ± `budget_tolerance` (0.20 ± 0.02)

---

## 2. Uplift / Qini (20 pts)

| Nivel | Pts | Descripción |
|-------|----:|-------------|
| Excelente | 18–20 | Curva Qini y/o uplift por bins en test (u otro split held-out) rankeando por \(\hat\tau\); figura exportada; interpreta que ranking ≠ identificación. |
| Suficiente | 11–17 | Una curva presente sin interpretación o sin export. |
| Insuficiente | 0–10 | No hay evaluación de ranking offline. |

**Artefacto esperado:** `artifacts/A4/uplift_curve.png`

---

## 3. Baselines (20 pts)

| Nivel | Pts | Descripción |
|-------|----:|-------------|
| Excelente | 18–20 | Compara política CATE vs **random** (misma \(B\)) y vs **outcome-only** (riesgo no causal); tabla de treat rates y value (IPW y/o oracle en sección marcada). |
| Suficiente | 11–17 | Solo un baseline o comparación incompleta. |
| Insuficiente | 0–10 | Sin baselines. |

**Autograder (apoyo):** welfare oracle `value(π) ≥ value(random) − holgura` cuando `welfare_beats_random: true`.

---

## 4. Equidad y límites (20 pts)

| Nivel | Pts | Descripción |
|-------|----:|-------------|
| Excelente | 18–20 | Tabla de treat rate por grupo (p.ej. terciles de `bw`, splits de `sex` / `b.marr`); discute concentración de beneficios y **límites** (descriptivo, no certificación de fairness); datos sintéticos reconocidos. |
| Suficiente | 11–17 | Tabla generada sin discusión de límites. |
| Insuficiente | 0–10 | Sin análisis de equidad ni reflexión. |

**Artefacto esperado:** `artifacts/A4/equity_table.csv` (existencia; no umbral moral automático).

---

## 5. Serialización + policy card (15 pts)

| Nivel | Pts | Descripción |
|-------|----:|-------------|
| Excelente | 13–15 | `policy.joblib` carga y `predict` devuelve `{decision, uplift_score}` sobre filas dummy/X; `policy_card.md` auditable (scope, features, \(B\), threshold, assumptions, risks, **non-claims**). |
| Suficiente | 8–12 | Joblib existe pero card mínimo o interfaz incompleta. |
| Insuficiente | 0–7 | Sin artefacto usable para B3. |

**Artefactos esperados (insumo B3):**

```text
artifacts/A4/policy.joblib
artifacts/A4/policy_card.md
artifacts/A4/uplift_curve.png
artifacts/A4/equity_table.csv
```

---

## Penalizaciones transversales

| Incumplimiento | Penalización orientativa |
|----------------|--------------------------|
| Uso de `y0` / `y1` / `tau` en celdas de estimación / calibración de política (fuera de § evaluación final) | −15 a −30 (fuga de truth) |
| Paths absolutos de máquina o descargas externas | −5 a −10 |
| Notebook no ejecutable (import / rutas) | Hasta −20 según gravedad |
| Policy card sin non-claims / sin declarar datos sintéticos | −5 a −10 |
| Artefacto `policy.joblib` ausente o `predict` roto | −10 a −15 |

---

## Qué evalúa el autograder vs. el humano

| Chequeo | Autograder | Revisor humano |
|---------|:----------:|:--------------:|
| Truth no usado en estimación (grep notebook) | Sí | Sí |
| Treat rate ≈ \(B\) | Sí | Interpretación |
| Welfare \(\pi\) vs random (oracle) | Sí | Diseño de baselines |
| Artefactos A4 + `predict` smoke | Sí | Contrato B3 |
| Calidad de equity / policy card | Heurística | **Sí (peso alto)** |
| Transparencia de datos sintéticos | Heurística | **Sí** |

La nota final la define la rúbrica humana; `grade_a4.py` es un **filtro de sanidad** y apoyo a la corrección a escala.

---

## Entregables esperados del estudiante

1. Notebook completado (política bajo \(B\), Qini/uplift, baselines, equidad).  
2. `artifacts/A4/policy.joblib` con interfaz `predict` → B3.  
3. `policy_card.md` auditable + `uplift_curve.png` + `equity_table.csv`.  
4. Discusión de límites + sección final de welfare oracle marcada.
