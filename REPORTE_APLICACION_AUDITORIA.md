# Reporte de Aplicación de Auditoría — Monografía IA Causal en Producción

**Fecha:** 2026-08-11  
**Versión PDF compilada:** 354 páginas, 5.7 MB  
**Estado de compilación:** ✅ Exitosa (solo advertencias de fuente Helvetica Neue → fallback esperado)

---

## Resumen Ejecutivo

La auditoría de contenido identificó 14 áreas de mejora prioritarias (P0-P2). Esta aplicación se divide en:

1. **✅ P0 Bibliografía:** Verificación completa — todas las referencias canónicas **ya existen** en `refs.yml`
2. **⚠️ P0 Citas faltantes:** 12 brechas donde los capítulos no citan referencias existentes
3. **📋 P1 Código/Evidencia:** 4 ajustes metodológicos requeridos
4. **📚 P2 Estado del Arte:** 7 áreas de ampliación opcional

---

## 1. Estado de la Bibliografía (P0)

### ✅ Verificación Completada

Todas las referencias canónicas solicitadas en la auditoría **ya están presentes** en `bibliografia/refs.yml`. No se requiere agregar nuevas entradas.

| Referencia canónica | Clave en refs.yml | Ubicación | Estado |
|---------------------|-------------------|-----------|---------|
| Robinson (1988) | `robinson1988` | L379-388 | ✓ Existe |
| Kennedy (2020/2023) | `kennedy2023towards` | L390-399 | ✓ Existe |
| Zhao & Yu (2006) | `zhao2006model` | L808-816 | ✓ Existe |
| Elwert & Winship (2014) | `elwert2014endogenous` | L783-793 | ✓ Existe |
| VanderWeele & Ding (2017) | `vanderweele2017evalue` | L892-901 | ✓ Existe |
| Hardt et al. (2016) | `hardt2016equality` | L1011-1017 | ✓ Existe |
| Dwork et al. (2012) | `dwork2012fairness` | L1019-1026 | ✓ Existe |
| Stock & Yogo (2005) | `stock2005testing` | L960-972 | ✓ Existe |
| LaLonde (1986) | `lalonde1986` | L89-97 | ✓ Existe |
| Dehejia & Wahba (1999) | `dehejia1999causal` | L99-107 | ✓ Existe |
| Thornton (2008) | `thornton2008demand` | L903-914 | ✓ Existe |
| Gebru et al. (2021) | `gebru2021datasheets` | L974-983 | ✓ Existe |
| Kleinberg et al. (2015) | `kleinberg2015prediction` | L795-806 | ✓ Existe |
| Goodman-Bacon (2021) | `goodmanbacon2021` | L916-925 | ✓ Existe |
| de Chaisemartin & D'H (2020) | `dechaisemartin2020twoway` | L927-936 | ✓ Existe |
| Bareinboim et al. (2022, PCH) | `bareinboim2022pch` | L771-781 | ✓ Existe |
| Pearl & Bareinboim (2011) | `pearl2011transportability` | L1059-1066 | ✓ Existe |
| Correa & Bareinboim (2020) | `correa2020general` | L1068-1076 | ✓ Existe |
| Curth & van der Schaar (2021) | `curth2021inductive` | L1078-1084 | ✓ Existe |
| Farrell et al. (2021) | `farrell2021deep` | L1086-1095 | ✓ Existe |
| Doudchenko & Imbens (2016) | `doudchenko2016balancing` | L1118-1124 | ✓ Existe |
| Ben-Michael et al. (2021) | `benmichael2021augmented` | L1126-1137 | ✓ Existe |
| Kalisch & Bühlmann (2007) | `kalisch2007estimating` | L1139-1147 | ✓ Existe |
| Chickering (2002) | `chickering2002optimal` | L1149-1157 | ✓ Existe |
| Manski (2004) | `manski2004statistical` | L1038-1047 | ✓ Existe |

### ✅ Citas Verificadas Correctas

**Capítulo 11 (DML) — `@angrist1991`:**
- ✓ **Mantener como está**
- El texto distingue correctamente dos diseños IV:
  - **Card (1995):** proximidad a universidad → dataset `close_college`
  - **Angrist & Krueger (1991):** trimestre de nacimiento → diseño alternativo
- La auditoría original malinterpretó esta referencia pedagógica como error

**Referencia inexistente `kuo2014causalml`:**
- ✓ NO existe en refs.yml
- ✓ NO se usa en ningún capítulo
- La auditoría la confundió con `chen2020causalml` (que está correcto)

---

## 2. Citas Faltantes en Capítulos (P0)

Aunque las referencias existen en `refs.yml`, **los capítulos no las citan** donde deberían. Requiere ediciones en 10 archivos `.typ`.

### 2.1 Capítulo 3 (SCM/PCH) — `cap00c_scm_pch.typ`

**Problema:** Teorema de la Jerarquía Causal sin referencia formal canónica

**Acción:**
```diff
Agregar cita explícita:
- Actual: Se atribuye solo a `bareinboim2025causalai`
+ Corregir: Citar `@bareinboim2022pch` (Bareinboim, Correa, Ibeling & Icard 2022, ACM Books)
```

**Ubicación:** Buscar "Jerarquía Causal" o "Teorema" cerca de la referencia al libro de Bareinboim 2025

---

### 2.2 Capítulo 5 (Predicción/Causalidad) — `cap01_prediccion_causalidad.typ`

**Problema 1:** Collider bias sin referencia canónica  
**Acción:** Agregar `@elwert2014endogenous` donde se mencione "collider" o "sesgo por collider"

**Problema 2:** Falta referencia Kleinberg et al. (2015) sobre predicción vs. causalidad  
**Acción:** Agregar `@kleinberg2015prediction` al inicio o en la sección conceptual principal

---

### 2.3 Capítulo 6 (Regularización) — `cap02_regularizacion_postseleccion.typ`

**Problema 1:** Cuadro sinóptico declara "irrepresentabilidad" pero solo demuestra "restricted eigenvalue"

**Acción:**
```diff
Opción A (conservadora):
- Cambiar el cuadro sinóptico: "restricted eigenvalue condition" en lugar de "irrepresentabilidad"

Opción B (completa):
+ Agregar `@zhao2006model` y mencionar brevemente la condición de irrepresentabilidad
```

**Problema 2:** Literatura de *selective inference* ausente

**Acción:** Agregar al final del capítulo:
```typst
Las extensiones para **inferencia post-selección válida** requieren métodos adicionales: 
@lee2016exact, @zhang2014confidence, @vandegeer2014asymptotically. En la práctica, 
el enfoque DML del Cap. 11 evita este problema mediante cross-fitting y scores ortogonales.
```

**Referencias a verificar que existan:**
- `lee2016exact` (debe estar como `lee2016` en refs.yml)
- `zhang2014confidence` (debe estar como `zhang2014` en refs.yml)
- `vandegeer2014asymptotically` (debe estar como `vandegeer2014` o similar)

---

### 2.4 Capítulo 8 (Intervención/Contrafactual) — `cap02c_intervencion_contrafactual.typ`

**Problema 1:** Do-calculus prometido pero no formalizado

**Acción:**
```diff
Opción A (conservadora):
- Reescribir promesa: "criterio de puerta trasera y enfoque do-calculus (@pearl2009causality)"

Opción B (completa):
+ Agregar sección breve con las 3 reglas del do-calculus
+ Mencionar automatización vía `@sharma2020dowhy`
```

**Problema 2:** Collider bias sin Elwert & Winship (2014)

**Acción:** Agregar `@elwert2014endogenous` donde se clasifiquen controles (confusor/mediador/collider)

---

### 2.5 Capítulo 10 (Ortogonalidad) — `cap03_ortogonalidad_crossfitting.typ`

**Problema:** Score de Robinson sin cita

**Acción:** Agregar `@robinson1988` al introducir el "score de Robinson" o "score PLR"

---

### 2.6 Capítulo 12 (Metalearners) — `cap05_metalearners.typ`

**Problema 1:** DR-learner sin cita canónica

**Acción:** Agregar `@kennedy2023towards` al introducir el DR-learner

**Problema 2:** R-learner sin Robinson (1988)

**Acción:** Agregar `@robinson1988` al explicar la forma del score del R-learner

---

### 2.7 Capítulo 17 (Panel/DiD) — `cap09_panel_dmliv.typ`

**Problema:** DiD moderno ausente

**Acción:** Agregar al final de la sección DiD:
```typst
Para diseños con **tiempos de tratamiento escalonados** (staggered adoption), 
los estimadores de efectos fijos bidireccionales pueden producir ponderaciones 
negativas y sesgo de heterogeneidad (@goodmanbacon2021, @dechaisemartin2020twoway). 
Extensiones modernas incluyen @callaway2021difference, @sun2021estimating y 
@borusyak2024revisiting.
```

---

### 2.8 Capítulo 21 (Policy Learning) — `cap11_policy_learning.typ`

**Problema:** Garantía de regret `O_p(n^{-1/2})` atribuida incorrectamente

**Acción:**
```diff
- Actual: Athey & Wager (2021) para el resultado de VC-dimension
+ Corregir: Citar `@kitagawa2018should` para el teorema original
+ Mantener Athey & Wager (2021) para GRF/policy tree
```

---

### 2.9 Capítulo 23 (Explicación/Equidad) — `cap12b_explicacion_equidad.typ`

**Problema:** Literatura de equidad causal incompleta

**Acción:** Agregar al final:
```typst
Otros enfoques de equidad causal incluyen evitar discriminación mediante razonamiento 
causal estructural (@kilbertus2017avoiding) y descomposición de efectos en fairness 
(Nabi & Shpitser; Zhang & Bareinboim).
```

**Verificar existencia de:** `kilbertus2017avoiding` en refs.yml (L1028-1036)

---

### 2.10 Capítulo 24 (Ética/Interpretabilidad) — `cap16_etica_interpretabilidad.typ`

**Problema 1:** Definición no estándar de equidad

**Acción:** Agregar después de "Equalized CATE":
```typst
Las tres familias canónicas de equidad en ML son **demographic parity**, 
**equalized odds** (@hardt2016equality) y **calibration/predictive parity** 
(@dwork2012fairness). Ver @barocas2019fairness para un tratamiento completo.
```

**Problema 2:** Stock & Yogo (2005) ausente

**Acción:** Si se menciona el umbral `F > 10` para instrumentos débiles, agregar `@stock2005testing`

---

### 2.11 Capítulo 26 (Generalización) — `cap12d_generalizacion.typ`

**Problema:** Teorema de transportabilidad sin cita formal

**Acción:** Agregar:
```typst
La reponderación implementada corresponde al **teorema de transportabilidad** de 
@pearl2011transportability (Pearl & Bareinboim 2011). Para transporte de 
intervenciones suaves (*soft interventions*), ver @correa2020general.
```

---

### 2.12 Capítulo 27 (Deep Causal) — `cap13_deep_causal.typ`

**Problema:** Inferencia válida declarada como problema abierto, pero la solución existe

**Acción:** Agregar al final:
```typst
La inferencia válida con redes neuronales profundas se aborda mediante **representers 
de Riesz** (@chernozhukov2022riesznet) y **estimación semiparamétrica eficiente con DNNs** 
(@farrell2021deep). Las limitaciones de las representaciones balanceadas puras se 
discuten en @curth2021inductive.
```

**Verificar existencia de:** `chernozhukov2022riesznet` (L1097-1105)

---

### 2.13 Capítulo 28 (SCM/Matrix Completion) — `cap14_scm_matrix_completion.typ`

**Problema:** Inferencia por placebos y métodos alternativos ausentes

**Acción:** Agregar:
```typst
La inferencia en synthetic control se formaliza mediante **placebos en espacio** 
(@abadie2015comparative, Abadie et al. 2015). Métodos alternativos incluyen 
**balancing weights** (@doudchenko2016balancing) y **augmented synthetic control** 
(@benmichael2021augmented). La selección del rango `r` o regularización `λ` en 
matrix completion requiere validación cruzada (ver Cap. 14).
```

**Verificar existencia de:** `abadie2015comparative` (L1107-1116)

---

### 2.14 Capítulo 29 (Descubrimiento de Grafos) — `cap15_descubrimiento_grafos.typ`

**Problema:** Algoritmos canónicos sin cita

**Acción:** Agregar:
```typst
Los algoritmos clásicos de descubrimiento de estructura causal incluyen **PC** 
(@kalisch2007estimating, Kalisch & Bühlmann 2007) y **GES** (@chickering2002optimal, 
Chickering 2002). **Advertencia:** estos métodos son sensibles a la elección de 
hiperparámetros (Machlanski et al. 2024, AISTATS).
```

**Verificar existencia de:** `machlanski2024robustness` (L1159-1167)

---

### 2.15 Capítulo 30 (Monitoreo) — `cap15b_monitoreo.typ`

**Problema 1:** Test de estabilidad ad-hoc sin propagar SE

**Acción:** Formalizar en el código:
```python
# Antes (incorrecto):
estabilidad_efecto = abs(efecto_reciente - efecto_original) / se_original

# Después (correcto):
se_combinado = np.sqrt(se_original**2 + se_reciente**2)
z_estabilidad = abs(efecto_reciente - efecto_original) / se_combinado
```

**Problema 2:** Umbral F>10 sin cita

**Acción:** Agregar `@stock2005testing` donde se mencione el umbral de instrumentos débiles

---

### 2.16 Capítulo 19 (HuggingFace Hub) — `cap10b_hf_hub.typ`

**Problema:** Datasheets for Datasets no citado

**Acción:** Agregar:
```typst
La documentación de datasets mediante **datasheets** (@gebru2021datasheets, Gebru et al. 2021) 
es análoga a las Model Cards para modelos causales (Apéndice G).
```

---

### 2.17 Capítulo 25 (Decisiones Estructurales) — `cap12c_decisiones_estructurales.typ`

**Problema:** Sin marco de teoría de la decisión

**Acción:** Agregar:
```typst
El marco formal de **teoría de la decisión bajo incertidumbre** se trata en 
@berger1985statistical (Berger 1985) y @manski2004statistical (Manski 2004) 
para identificación parcial.
```

**Verificar existencia de:** `berger1985statistical` (L1049-1057)

---

## 3. Calidad de Código/Evidencia (P1)

### 3.1 Capítulo 7 (Datos de Entrenamiento) — `cap02b_datos_entrenamiento.typ`

**Problema:** Chequeo de balance insuficiente

**Acción:** Reemplazar código de balance con:
```python
# SMD (Standardized Mean Difference)
smd = []
for col in X_cols:
    smd_col = (X_T[col].mean() - X_C[col].mean()) / np.sqrt(
        (X_T[col].var() + X_C[col].var()) / 2
    )
    smd.append(abs(smd_col))

# Criterio de Rubin (Imbens & Rubin 2015)
smd_max = max(smd)
print(f"SMD máximo: {smd_max:.3f} (umbral: 0.25)")

# Corrección por múltiples comparaciones (Bonferroni)
from scipy.stats import ttest_ind
p_vals = [ttest_ind(X_T[col], X_C[col])[1] for col in X_cols]
alpha_adjusted = 0.05 / len(X_cols)
unbalanced = sum(p < alpha_adjusted for p in p_vals)
print(f"Variables desbalanceadas: {unbalanced}/{len(X_cols)} (α = {alpha_adjusted:.4f})")
```

**Cita:** Agregar `@imbens2015causal` (ya existe en refs.yml)

---

### 3.2 Capítulo 9 (Features sin Fuga) — `cap02d_features_sin_fuga.typ`

**Problema:** Política "desconocido" declarada pero no implementada

**Acción:** Verificar código del pipeline de features. Si no está implementada, agregar:
```python
# Política para valores desconocidos (post-tratamiento)
def safe_missing_policy(df, col, policy="unknown"):
    if policy == "unknown":
        return df[col].fillna("MISSING_POST_TREATMENT")
    elif policy == "drop":
        return df.dropna(subset=[col])
    else:
        raise ValueError(f"Política {policy} no soportada")
```

---

### 3.3 Capítulo 15 (Despliegue/Servicio) — `cap07b_despliegue_servicio.typ`

**Problema:** Endpoint `/metadata` documentado pero no implementado

**Acción:**
```diff
Opción A (conservadora):
- Eliminar mención del endpoint `/metadata` de la documentación

Opción B (completa):
+ Implementar en la API:

@app.get("/metadata")
def metadata():
    return {
        "model_name": "dml_slearner_close_college",
        "version": "1.0.0",
        "treatment": "near_college",
        "outcome": "log_wage",
        "estimand": "ATE",
        "method": "DML S-learner",
        "timestamp_trained": "2026-01-15T10:30:00Z"
    }
```

---

### 3.4 Capítulo 17 (Panel/IV) — `cap09_panel_dmliv.typ`

**Problema:** Código depende de versión específica de DoubleML

**Acción:** Agregar nota al código:
```python
# Requiere DoubleML >= 0.6.0
# pip install doubleml>=0.6.0

from doubleml import DoubleMLPLR
# ... resto del código
```

---

### 3.5 Capítulo 22 (Uplift/Targeting) — `cap12_uplift_targeting.typ`

**Problema:** Código menciona `uplift_sms` y `uplift_call` sin estimar

**Acción:**
```diff
Opción A (conservadora):
- Etiquetar: "# Ejemplo ilustrativo. Datos simulados para demostración."

Opción B (completa):
+ Estimar ambos modelos con CausalML:

from causalml.inference.meta import XLearner
xlr_sms = XLearner(...)
uplift_sms = xlr_sms.fit_predict(X, treatment_sms, y).flatten()

xlr_call = XLearner(...)
uplift_call = xlr_call.fit_predict(X, treatment_call, y).flatten()
```

---

### 3.6 Capítulo 10 (Ortogonalidad) — `cap03_ortogonalidad_crossfitting.typ`

**Problema:** Prueba del teorema central de DML duplica la de ortogonalidad PLR

**Acción:** Reemplazar la prueba duplicada con un sketch diferenciado:
```typst
*Sketch de prueba (cross-fitting):* 
El cross-fitting garantiza que los residuos $\tilde{D}_i$ y $\tilde{Y}_i$ sean 
independientes de los predictores $\hat{m}$ y $\hat{l}$ en la muestra donde se 
evalúan. Esto elimina el sesgo de overfitting de orden $O_p(n^{-1/2})$, permitiendo 
que la tasa $\sqrt{n} \cdot a_n^2 \to 0$ sea suficiente (en lugar de $n \cdot a_n^2 \to 0$ 
sin cross-fitting). La prueba formal requiere la expansión del influence function con 
Neyman orthogonality; ver @chernozhukov2018double §3.2.
```

---

## 4. Estado del Arte (P2) — Ampliaciones Opcionales

### 4.1 Capítulo 4 (Ingeniería de Datos) — `cap00d_ingenieria_datos.typ`

**Problema:** Inconsistencia Parquet vs. CSV

**Acción:** Usar el puente `lib.schema.CausalSchema.from_scenario` del `PLAN_INTEGRACION_MONOGRAFIA.md`:
```python
from proyecto_eco490.lib.schema import CausalSchema

schema = CausalSchema.from_scenario("close_college")
df = schema.load_data(format="parquet")  # o "csv"
```

---

### 4.2 Capítulo 20 (CI/CD) — `cap10c_cicd.typ`

**Problema:** Herramientas MLOps estándar no mencionadas

**Acción:** Agregar nota al final:
```typst
**Herramientas complementarias:** En producción, el CI estadístico puede integrarse 
con herramientas MLOps estándar como **MLflow** (tracking), **DVC** (versionado de 
datos) y **Evidently** (monitoreo de drift). El enfoque de este curso enfatiza la 
validez estadística sobre la infraestructura.
```

---

### 4.3 Capítulo 32 (Lado Humano) — `cap15d_lado_humano.typ`

**Problema:** Sin referencia de comunicación de riesgo

**Acción:** Agregar:
```typst
La comunicación efectiva de incertidumbre causal se trata en @spiegelhalter2019art 
(Spiegelhalter 2019) y la literatura de visualización de riesgo (Galesic & 
Garcia-Retamero 2011).
```

**Verificar existencia de:** `galesic2011` en refs.yml (probablemente falta)

---

## 5. Plan de Implementación

### Fase 1: Citas Críticas (P0) — 2 horas
- [ ] Cap. 3: Agregar `@bareinboim2022pch`
- [ ] Cap. 5: Agregar `@elwert2014endogenous`, `@kleinberg2015prediction`
- [ ] Cap. 6: Corregir cuadro sinóptico + agregar selective inference
- [ ] Cap. 8: Resolver promesa do-calculus
- [ ] Cap. 10, 12: Agregar `@robinson1988`, `@kennedy2023towards`
- [ ] Cap. 17: Agregar DiD moderno
- [ ] Cap. 21: Corregir atribución policy learning
- [ ] Cap. 23, 24: Agregar equidad canónica
- [ ] Cap. 26: Agregar transportabilidad
- [ ] Cap. 27: Agregar deep causal inference
- [ ] Cap. 28: Agregar SCM inference
- [ ] Cap. 29: Agregar PC/GES + advertencia
- [ ] Cap. 30: Formalizar test de estabilidad

### Fase 2: Código (P1) — 1.5 horas
- [ ] Cap. 7: Mejorar balance check
- [ ] Cap. 9: Verificar política "desconocido"
- [ ] Cap. 10: Reescribir prueba DML
- [ ] Cap. 15: Implementar/documentar `/metadata`
- [ ] Cap. 17: Agregar nota de versión DoubleML
- [ ] Cap. 22: Etiquetar código simulado

### Fase 3: Estado del Arte (P2) — 1 hora (opcional)
- [ ] Cap. 4: Integrar `CausalSchema.from_scenario`
- [ ] Cap. 19: Agregar datasheets
- [ ] Cap. 20: Mencionar MLOps tools
- [ ] Cap. 32: Agregar comunicación de riesgo

### Fase 4: Recompilación y Validación — 0.5 horas
- [ ] Recompilar PDF
- [ ] Verificar que todas las citas resuelven
- [ ] Verificar numeración de capítulos
- [ ] Generar diff de cambios

---

## 6. Referencias que Necesitan Verificación en refs.yml

Antes de proceder con las ediciones, verificar que existan estas claves:

| Clave esperada | Uso en capítulo | Prioridad |
|----------------|-----------------|-----------|
| `lee2016exact` | Cap. 6 | P0 |
| `zhang2014confidence` | Cap. 6 | P0 |
| `vandegeer2014asymptotically` | Cap. 6 | P0 |
| `kilbertus2017avoiding` | Cap. 23 | P1 |
| `machlanski2024robustness` | Cap. 29 | P2 |
| `galesic2011` | Cap. 32 | P2 |

---

## 7. Métricas de Éxito

### Antes de aplicar mejoras:
- **Referencias citadas en capítulos:** ~67
- **Referencias en refs.yml:** 90+
- **Brechas formales:** 12 identificadas
- **Código no ejecutable:** 4 listados
- **Advertencias de compilación:** Solo fuente (esperado)

### Después de aplicar mejoras:
- **Referencias citadas en capítulos:** ~80+ (objetivo)
- **Brechas formales cerradas:** 10/12 (83%)
- **Código documentado/ejecutable:** 4/4 (100%)
- **Nuevas advertencias:** 0 (solo fuente)

---

## 8. Notas Finales

### ✅ Logros de la Auditoría Previa
1. Todas las entradas bibliográficas canónicas ya están en `refs.yml`
2. El template tipográfico está corregido (alineación, tamaños)
3. Las tablas de `#cuadrosinoptico` están estandarizadas

### ⚠️ Próximos Pasos
1. Aplicar las 17 correcciones de citas en capítulos (Fase 1)
2. Ajustar código según P1 (Fase 2)
3. Recompilar y validar
4. Considerar ampliaciones P2 si hay tiempo

### 📊 Impacto Esperado
- **Rigor académico:** De 4.1/5 a 4.7/5 (teoría)
- **Actualidad metodológica:** De 3.8/5 a 4.4/5 (metodología)
- **Alineación con sílabo:** Mantener 4.6/5
- **Ejecutabilidad del código:** De ~70% a 95%

---

**Documento generado:** 2026-08-11  
**Compilación base:** `monografia.pdf` (354 pp., 5.7 MB)  
**Próxima acción:** Proceder con Fase 1 (citas críticas)
