# Rúbrica — Notebook A1: Identificación causal (Jobs)

**Curso:** IA Causal en Producción (ECO-490 / ECON-540)  
**Notebook:** `notebooks/A1_identificacion_jobs.ipynb`  
**Dataset:** `real/jobs` (`scenario_id`: `real_jobs`)  
**Peso total:** 100 puntos  
**Autograder de apoyo:** `autograder/grade_a1.py` (no sustituye la evaluación escrita)

---

## Resumen de pesos

| # | Criterio | Puntos |
|---|----------|-------:|
| 1 | Formulación de pregunta + estimando | 20 |
| 2 | DAG y supuestos defendibles | 25 |
| 3 | Diagnósticos de balance / overlap | 20 |
| 4 | Implementación MCO + PDS correcta | 20 |
| 5 | Interpretación y límites | 15 |
|   | **Total** | **100** |

---

## 1. Formulación de pregunta + estimando (20 pts)

| Nivel | Pts | Descripción |
|-------|----:|-------------|
| Excelente | 18–20 | Declara unidades, \(T\), \(Y\), población y estimando **ATE** con claridad; distingue explícitamente pregunta predictiva vs. causal. |
| Suficiente | 12–17 | Estimando ATE presente y roles de variables correctos; distinción predictivo/causal incompleta o vaga. |
| Insuficiente | 0–11 | Confunde ATE con predicción, ATT sin justificarlo, u omite elementos esenciales de la plantilla. |

**Evidencia en el notebook:** sección «Pregunta causal y estimando»; celdas markdown de plantilla no vacías.

---

## 2. DAG y supuestos defendibles (25 pts)

| Nivel | Pts | Descripción |
|-------|----:|-------------|
| Excelente | 22–25 | DAG coherente (confusores pre-tratamiento → \(T\) y \(Y\), flecha \(T \to Y\)); lista SUTVA + ignorabilidad condicional + overlap; discute *por diseño del SEM* vs. defensa en datos reales. |
| Suficiente | 14–21 | DAG o lista de supuestos presentes pero con lagunas (p. ej. omite overlap o no contrasta SEM vs. mundo real). |
| Insuficiente | 0–13 | Sin DAG usable; copia `identification.json` sin interpretación; o supone aleatorización sin argumentar. |

**Evidencia:** diagrama Mermaid y/o `networkx`; lectura de `identification.json` con comentario crítico.

---

## 3. Diagnósticos de balance / overlap (20 pts)

| Nivel | Pts | Descripción |
|-------|----:|-------------|
| Excelente | 18–20 | Tabla SMD (o equivalente) interpretada; propensity por grupo; comenta recorte y fracción en soporte común. |
| Suficiente | 12–17 | Ejecuta balance y propensity pero interpretación superficial o sin recorte/diagnóstico de colas. |
| Insuficiente | 0–11 | No hay diagnósticos, o se usan `y0`/`y1`/`tau` para «balancear». |

**Autograder (apoyo):** fracción con \(0 < e(x) < 1\) ≥ 95 % en train (umbral de sanidad).

---

## 4. Implementación MCO + PDS correcta (20 pts)

| Nivel | Pts | Descripción |
|-------|----:|-------------|
| Excelente | 18–20 | Diff-in-means, OLS con las 8 covars y PDS (idealmente con expansión de features) correctos; tabla comparativa; no usa truth en celdas de estimación. |
| Suficiente | 12–17 | OLS correcto; PDS incompleto (p. ej. solo un Lasso) o sin reportar controles seleccionados. |
| Insuficiente | 0–11 | Estimadores mal especificados, leakage de truth, o resultados numéricos fuera de tolerancia generosa. |

**Autograder (apoyo, `expected_ranges.yaml` → `a1_jobs`):**

- \(|\widehat{\mathrm{ATE}}_{\mathrm{OLS}} - 1600.26| < 250\)
- \(|\widehat{\mathrm{ATE}}_{\mathrm{PDS}} - 1600.26| < 250\)

(en train o test con observables del escenario; la tolerancia es deliberadamente generosa).

**Piso del curso:** comparar con `scorecard.json` (naive / OLS / IPW) sin copiar ciegamente.

---

## 5. Interpretación y límites (15 pts)

| Nivel | Pts | Descripción |
|-------|----:|-------------|
| Excelente | 13–15 | ~½ página: justifica identificación, interpreta la tabla de estimadores **sin** anclarse al truth en el cuerpo principal, y plantea **un** riesgo de validez externa. |
| Suficiente | 8–12 | Texto presente pero genérico; límites poco concretos. |
| Insuficiente | 0–7 | Celda vacía o solo parafrasea el scorecard/truth. |

**Autograder (apoyo):** heurística de longitud mínima en celdas markdown de identificación / justificación.

---

## Penalizaciones transversales

| Incumplimiento | Penalización orientativa |
|----------------|--------------------------|
| Uso de `y0` / `y1` / `tau` en celdas de estimación (fuera de § evaluación final) | −15 a −30 (fuga de truth) |
| Ausencia total de texto de identificación | −15 (criterio 5 en 0 + impacto en 1–2) |
| Paths absolutos de máquina o descargas externas | −5 a −10 |
| Notebook no ejecutable (errores de import / rutas) | Hasta −20 según gravedad |

---

## Qué evalúa el autograder vs. el humano

| Chequeo | Autograder | Revisor humano |
|---------|:----------:|:--------------:|
| Columnas truth no usadas en estimación (grep notebook) | Sí | Sí |
| AE de OLS / PDS vs `ate_true` | Sí | Opcional |
| Propensity interior ≥ 95 % | Sí | Complementa |
| Longitud mínima de markdown de ID | Heurística | Lectura completa |
| Calidad del DAG y argumentación | No | **Sí (peso alto)** |
| Interpretación y validez externa | No | **Sí** |

La nota final la define la rúbrica humana; el script `grade_a1.py` es un **filtro de sanidad** y apoyo a la corrección a escala.

---

## Entregables esperados del estudiante

1. Notebook completado (código + markdown de escritura no vacíos).  
2. DAG + lista de supuestos.  
3. Tabla de estimadores (DIM, OLS, PDS) y mención al scorecard.  
4. Justificación escrita de identificación (~½ página).
