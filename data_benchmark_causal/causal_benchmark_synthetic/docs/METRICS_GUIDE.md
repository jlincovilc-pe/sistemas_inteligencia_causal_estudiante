# Guia de Metricas de Evaluacion

## 1. Metricas de Descubrimiento Causal

### Structural Hamming Distance (SHD)

**Definicion**: Numero minimo de operaciones necesarias para transformar el grafo estimado en el grafo verdadero.

**Operaciones**:
- Agregar un arco
- Eliminar un arco  
- Invertir la direccion de un arco

**Interpretacion**:
- SHD = 0: Recuperacion perfecta
- SHD bajo: Buena recuperacion
- SHD alto: Recuperacion pobre

**Formula**:
```
SHD(G_est, G_true) = sum sobre pares (i,j) de:
  - 0 si ambos arcos identicos
  - 1 si misma estructura subyacente, diferente direccion
  - |A_true[i,j] - A_est[i,j]| en otro caso
```

**Valores esperados**:

| Dataset | PC | FCI | GES | NOTEARS | GOLEM | LiNGAM |
|---------|-----|-----|-----|---------|-------|--------|
| Sachs (11 vars) | 3-6 | 4-7 | 3-5 | 2-5 | 2-4 | 3-6 |
| Alarm (37 vars) | 8-15 | 10-18 | 8-14 | 7-13 | 6-12 | N/A |
| 20_vars_ER | 5-12 | 7-15 | 5-11 | 4-10 | 4-9 | 6-12 |

---

### Precision y Recall de Skeleton

**Skeleton**: Grafo no dirigido subyacente (ignorando direccion de arcos).

**Precision**: Proporcion de arcos detectados que son verdaderos.
```
Precision = TP / (TP + FP)
```

**Recall**: Proporcion de arcos verdaderos que fueron detectados.
```
Recall = TP / (TP + FN)
```

**F1-Score**: Media armonica de precision y recall.
```
F1 = 2 * (Precision * Recall) / (Precision + Recall)
```

**Interpretacion**:
- F1 > 0.8: Excelente recuperacion del skeleton
- F1 0.6-0.8: Buena recuperacion
- F1 < 0.5: Recuperacion pobre

---

### Precision de Orientacion

**Definicion**: De los arcos cuyo skeleton es correcto, proporcion con direccion correcta.

**Importancia**: La orientacion es critica para identificacion causal.

**Nota**: Algunos arcos no pueden ser orientados de forma unica (CPDAG). Se reporta orientacion sobre v-structures y arcos dirigidos identificables.

---

### Structural Intervention Distance (SID)

**Definicion**: Numero de pares ordenados (i,j) donde una intervencion en i afecta a j de forma diferente entre G_est y G_true.

**Ventaja**: Penaliza errores que afectan conclusiones causales, no solo estructura.

**Desventaja**: Computacionalmente mas costoso que SHD.

---

## 2. Metricas de Inferencia Causal

### Error Absoluto del ATE

```
|ATE_true - ATE_estimado|
```

**Interpretacion**:
- < 0.1 * |ATE_true|: Excelente
- < 0.2 * |ATE_true|: Bueno
- < 0.5 * |ATE_true|: Aceptable
- > |ATE_true|: Pobre

**Valores esperados en IHDP**:

| Estimador | Error Absoluto |
|-----------|---------------|
| OLS | 0.5 - 1.0 |
| PSM | 0.3 - 0.7 |
| T-Learner | 0.2 - 0.5 |
| S-Learner | 0.2 - 0.5 |
| IPW | 0.2 - 0.5 |
| AIPW | 0.1 - 0.3 |
| DML | 0.05 - 0.2 |

---

### PEHE (Precision in Estimation of Heterogeneous Effects)

**Definicion**: Error cuadratico medio en la estimacion de efectos individuales (CATE).

```
PEHE = sqrt(mean((tau_i_true - tau_i_estimado)^2))
```

**Importancia**: Evalua la capacidad de detectar subgrupos con diferentes efectos.

---

### Cobertura del Intervalo de Confianza

**Definicion**: Proporcion de veces que el intervalo de confianza al 95% contiene el ATE verdadero.

**Esperado**: ~95% en datasets con muchas replicaciones.

**Interpretacion**:
- > 95%: Intervalos demasiado conservadores
- 90-95%: Buena cobertura
- < 90%: Intervalos demasiado estrechos (subcobertura)

---

### Longitud del Intervalo

**Definicion**: Amplitud del intervalo de confianza (CI_upper - CI_lower).

**Trade-off**: Con cobertura fija, intervalos mas cortos indican mayor precision.

---

### Sesgo

```
Sesgo = ATE_estimado - ATE_true
```

**Interpretacion**:
- Positivo: Sobrestimacion sistematica
- Negativo: Subestimacion sistematica
- Cercano a 0: Insesgado

---

## 3. Metricas del Agente (Pipeline Completo)

### Tasa de Abstencion Correcta

**Definicion**: Proporcion de casos no identificables donde el agente se abstiene.

**Importancia**: Evita conclusiones espurias cuando no hay set de ajuste valido.

**Prueba**: Dataset con M-graph (no identificable).

**Esperado**: 100% de abstencion en casos no identificables.

---

### Tasa de Refutacion Superada

**Definicion**: Proporcion de tests de refutacion que el estimador pasa.

**Tests**:
1. **Placebo Treatment**: El ATE con tratamiento aleatorio deberia ser ~0
2. **Random Common Cause**: Agregar confusor aleatorio no deberia cambiar ATE sustancialmente
3. **Data Subset**: El ATE en subconjuntos deberia ser consistente

**Interpretacion**:
- 3/3 tests: Robustez fuerte
- 2/3 tests: Robustez moderada
- 0-1/3 tests: Robustez debil

---

### E-value

**Definicion**: Valor minimo de asociacion (RR) que un confusor no medido necesitaria con tratamiento y outcome para explicar el efecto observado.

**Interpretacion**:
- E-value > 2: El resultado sobrevive a confusores moderados
- E-value 1.5-2: Sensible a confusores no medidos
- E-value < 1.5: Muy sensible

---

### Determinismo

**Definicion**: Verificacion de que dos ejecuciones con la misma semilla producen resultados identicos.

**Prueba**: Ejecutar pipeline dos veces con seed=42 y comparar:
- ATE estimado (diferencia < epsilon)
- Estructura del grafo (mismos arcos)
- Clase de robustez (identica)

**Esperado**: Resultados bit-a-bit identicos.

---

## 4. Metricas Computacionales

### Tiempo de Ejecucion

**Medida**: Tiempo wall-clock para completar el pipeline.

**Valores de referencia (CPU single-core)**:

| Dataset | Lite Mode | Full Mode |
|---------|-----------|-----------|
| 10 variables, 1000 muestras | < 5s | < 10s |
| 20 variables, 2000 muestras | < 15s | < 30s |
| 50 variables, 5000 muestras | < 60s | < 120s |
| 100 variables, 10000 muestras | < 300s | < 600s |

---

### Uso de Memoria

**Medida**: Pico de memoria RAM durante la ejecucion.

**Formula aproximada**:
```
Memoria (MB) ≈ n_samples * n_features * 8 bytes / 1e6 * 3
```

El factor 3 considera: datos originales + copias + matrices intermedias.

---

## 5. Tablas de Referencia

### Descubrimiento: Resultados Esperados por Algoritmo

#### Datasets Lineales Gaussianos

| Algoritmo | SHD | F1 Skeleton | F1 Dirigido | Tiempo |
|-----------|-----|-------------|-------------|--------|
| PC | Bajo | Alto | Medio | Medio |
| FCI | Bajo-Medio | Alto | Medio | Alto |
| GES | Bajo | Alto | Medio-Alto | Medio |
| NOTEARS | Medio | Medio-Alto | Medio | Bajo |
| GOLEM | Bajo | Alto | Alto | Alto |
| LiNGAM | Medio | Medio | Medio | Medio |

#### Datasets No Gaussianos

| Algoritmo | SHD | F1 Skeleton | F1 Dirigido | Tiempo |
|-----------|-----|-------------|-------------|--------|
| PC | Bajo | Alto | Medio | Medio |
| LiNGAM | **Muy bajo** | **Alto** | **Alto** | Medio |
| ICA-LiNGAM | **Muy bajo** | **Alto** | **Alto** | Medio |
| NOTEARS | Medio | Medio-Alto | Medio | Bajo |

#### Datasets No Lineales

| Algoritmo | SHD | F1 Skeleton | F1 Dirigido | Tiempo |
|-----------|-----|-------------|-------------|--------|
| GES | Medio | Medio-Alto | Medio | Medio |
| NOTEARS-MLP | **Bajo** | **Alto** | Medio-Alto | Medio-Alto |
| GOLEM | **Bajo** | **Alto** | **Alto** | Alto |
| PC (lineal) | Medio-Alto | Medio | Medio | Medio |

### Inferencia: Resultados Esperados por Estimador

#### IHDP (ATE)

| Estimador | Error ATE | PEHE | Cobertura 95% | Tiempo |
|-----------|-----------|------|---------------|--------|
| OLS | 0.5-1.0 | Alto | 85-90% | Bajo |
| PSM | 0.3-0.7 | Alto | 85-95% | Bajo |
| S-Learner | 0.2-0.5 | Medio | 88-95% | Medio |
| T-Learner | 0.2-0.5 | Medio | 88-95% | Medio |
| X-Learner | 0.15-0.4 | Medio | 90-95% | Medio |
| IPW | 0.2-0.5 | Alto | 90-95% | Bajo |
| AIPW | 0.1-0.3 | Medio | 92-96% | Medio |
| DML | **0.05-0.2** | **Bajo** | **93-97%** | Alto |

### Comparativa: Lite vs Full Mode

| Metrica | Lite Mode | Full Mode |
|---------|-----------|-----------|
| Dependencias | NumPy/scikit-learn | +causal-learn,+lingam,+gCastle |
| Setup time | < 1s | 5-30s (imports) |
| Precision PC | Similar | Similar |
| Precision LiNGAM | Moderada | Alta (FastICA optimizado) |
| GOLEM | No disponible | Disponible |
| FCI (latentes) | No disponible | Disponible |
| Memoria | ~100-500 MB | ~200-1000 MB |

---

## 6. Protocolo de Evaluacion

### Para Descubrimiento Causal

1. Ejecutar cada algoritmo 10 veces con semillas diferentes
2. Reportar media y desviacion estandar de SHD y F1
3. Verificar determinismo: misma semilla = mismos resultados
4. Medir tiempo de ejecucion promedio

### Para Inferencia Causal

1. Ejecutar en 100 replicaciones Bootstrap
2. Reportar: MAE del ATE, PEHE, cobertura del IC
3. Verificar que el IC contiene el ATE verdadero ~95% de veces
4. Ejecutar tests de refutacion en cada replicacion

### Para Pipeline Completo

1. Ejecutar pipeline end-to-end
2. Verificar todos los checkpoints HITL (si no --no-human)
3. Confirmar generacion de reportes (MD, JSON)
4. Verificar checkpoint.json es reproducible
