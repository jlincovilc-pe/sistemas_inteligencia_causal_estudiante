---
language: es
tags:
  - causal-inference
  - double-machine-learning
  - treatment-effect
  - education
license: mit
library_name: sklearn
---

# Model card causal — Estimador DML (Serie A2 → B1/B2)

> **Curso:** Sistema de Inteligencia Causal (ECO-490 / ECON-540)  
> **Artefacto:** `dml_estimator.joblib` (PLR / partialling-out)  
> **Servicio:** B1 FastAPI (`/predict`, `/health`, `/metadata`)  
> **Uso previsto: profesional / educativo — NO uso clínico.** Este estimador entrena sobre un benchmark sintético (IHDP-*style*) y sirve para practicar el flujo estimar→servir→documentar de un sistema causal en producción; no está validado para decidir tratamientos clínicos ni políticas públicas reales.

## 1. Estimando

| Campo | Valor |
|---|---|
| **Estimando** | ATE (Average Treatment Effect) |
| **Modelo** | Partially Linear Regression (PLR) / DML |
| **Tratamiento** | `treatment` (binario) |
| **Outcome** | `outcome` (continuo) |
| **Población de entrenamiento** | Split **train** del escenario `synthetic/inference/ihdp_medium` (n=1200) |
| **scenario_id** | `synthetic_inference_ihdp_medium` |
| **Semilla curso** | 42 |
| **ATE punto (train, referencia A2)** | ≈ 3.528 |
| **IC 95% (ref. A2)** | [2.886, 4.169] |
| **Backend** | `plr_sklearn_crossfit` (LassoCV nuisances, K=5) |

## 2. Supuestos de identificación (declarados)

1. **Ignorabilidad condicional:** \(Y(0), Y(1) \perp T \mid X\) — *cierta por diseño del SEM sintético*; **no** demostrada en datos clínicos reales.  
2. **Overlap / positividad:** \(0 < e(x) < 1\).  
3. **SUTVA:** sin interferencia entre unidades; versión estable del tratamiento.  
4. **Especificación PLR:** \(Y = \theta T + g(X) + \varepsilon\), \(T = m(X) + \eta\), con ortogonalidad de Neyman y cross-fitting.

El archivo `identification.json` del benchmark es una **anotación de diseño del simulador**, no una prueba empírica de ignorabilidad en el mundo real.

## 3. Datos

- **Origen:** monorepo `causal_benchmark_synthetic` (IHDP-*style*).  
- **Qué es real:** orden de magnitud / inspiración Hill (2011), dimensionalidad (25 covars).  
- **Qué es sintético:** **todos** los valores numéricos.  
- **No usar** para decisiones clínicas, de política pública real, ni claims de validez externa fuera del SEM.  
- **Uso profesional / no clínico:** válido como práctica de ingeniería (estimar, servir, versionar, documentar); inválido como evidencia clínica o regulatoria.

## 4. Entradas y salidas del servicio (B1)

**Input** (`POST /predict`):

```json
{"features": {"x0": 0.0, "x1": 0.0, "...": 0.0, "x24": 0.0}}
```

**Output:**

```json
{
  "effect": 3.528,
  "ate": 3.528,
  "se": 0.327,
  "ci_low": 2.886,
  "ci_high": 4.169,
  "method": "plr_sklearn_crossfit",
  "estimand": "ATE"
}
```

Bajo PLR homogéneo, `effect` es constante en \(x\) (el ATE estimado).

## 5. Métricas y evaluación

| Chequeo | Resultado de referencia |
|---|---|
| AE vs `ate_true` del escenario (~3.97) | ≈ 0.44 (dentro de umbral A2) |
| Cobertura IC | el IC de entrenamiento contiene `ate_true` en la corrida de referencia |
| Humo B1 | `grade_b1.py` 11/11 |

## 6. Límites de validez externa

- No transportar el efecto a poblaciones reales de IHDP clínico.  
- No reentrenar sin actualizar esta card (estimando, splits, supuestos, ATE).  
- El servicio **no** calibra CATE individual; para targeting ver A4/B3.  
- Drift de covariables puede invalidar el solapamiento → ver B4.

## 7. Uso ético y responsabilidad

Material **docente**, de uso **profesional / no clínico**. Quien reutilice el artefacto debe preservar este model card y el aviso de datos sintéticos, y no presentarlo como evidencia clínica o de política pública real.

## 8. Citas

- Chernozhukov et al. (2018), Double/debiased ML.  
- Hill (2011), IHDP benchmark (inspiración).  
- Plan del curso: `PLAN_CURSO_COMPLETO.md` del monorepo.

## 9. Contacto / mantenimiento

Actualizar esta card en el **mismo PR** que cambie el joblib o el pipeline A2/B1.
