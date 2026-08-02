# Catalogo de Datasets de Benchmark

> ⚠️ **TRANSPARENCIA SOBRE EL ORIGEN DE LOS DATOS**
>
> Los datasets en la carpeta `datasets/real/` NO contienen datos observacionales reales.
> **Todos son generados sinteticamente.** Lo que es autentico de la literatura es:
> - Las **estructuras causales** (grafos) validadas experimentalmente
> - Los **valores de ATE de referencia** reportados en estudios originales
> - Los **nombres de variables y dominios de aplicacion**
>
> Para cada dataset se detalla explicitamente qué es real y qué es sintetico.

---

## Datasets de Descubrimiento Causal (Estructura)

### 1. Sachs Protein Signaling Network

| Atributo | Valor |
|----------|-------|
| **Variables** | 11 proteinas |
| **Instancias** | 7,466 (generadas sinteticamente) |
| **Arcos (ground truth)** | 18 arcos validados experimentalmente |
| **Tipo** | Continuo (simulado) |
| **Fuente del grafo** | Sachs et al. (2005), Science |
| **Datos** | ⚠️ **SINTETICOS** - SEM Lineal Gaussiano + transformacion exp() |

**Descripcion**: Dataset basado en la red de senalizacion proteica en celulas del sistema inmune humano de Sachs et al. (2005). Cada variable representa el nivel de expresion de una proteina. El grafo causal de 18 arcos fue validado mediante intervenciones experimentales en el paper original.

**Que es REAL**:
- El grafo causal (17-18 arcos validados experimentalmente)
- Los nombres de las 11 proteinas (Raf, Mek, PLCg, PIP2, PIP3, Erk, Akt, PKA, PKC, P38, Jnk)
- Las 9 condiciones de perturbacion (citoquinas y farmacos)
- Las relaciones causales direccionales

**Que es SINTETICO**:
- Todos los valores numericos de las proteinas
- Generados con `generate_linear_gaussian_sem()` con pesos U(0.3, 1.5) y ruido N(0, 0.5)
- Transformados con exp() para simular escala de citometria de flujo

**Variables**:
- Raf, Mek, PLCg, PIP2, PIP3, Erk, Akt, PKA, PKC, P38, Jnk

**Usos**:
- Evaluar precision de orientacion de arcos
- Probar robustez ante datos con ruido controlado
- Validar bootstrap de estabilidad de arcos

**Metricas esperadas** (para metodos modernos):
- SHD < 10
- F1 (skeleton) > 0.7
- F1 (dirigido) > 0.5

---

### 2. ALARM Network

| Atributo | Valor |
|----------|-------|
| **Variables** | 37 |
| **Instancias** | 20,000 (generadas sinteticamente) |
| **Arcos** | 46 |
| **Tipo** | Continuo (aproximacion de red discreta) |
| **Fuente del grafo** | Beinlich et al. (1989) |
| **Datos** | ⚠️ **SINTETICOS** - SEM Lineal Gaussiano |

**Descripcion**: Red bayesiana para monitorizacion de pacientes en UCI. El grafo original es una red bayesiana discreta publicada en 1989. Este dataset genera datos continuos como aproximacion.

**Que es REAL**: La topologia de la red (37 nodos, 46 arcos), los nombres de las variables, el dominio medico.

**Que es SINTETICO**: Todos los valores numericos. El ALARM original es una red discreta; aqui se aproxima con SEM lineal continuo.

**Usos**:
- Evaluar escalabilidad a ~40 variables
- Probar con estructuras medicas complejas
- Validar deteccion de v-structures

---

### 3. CHILD Network

| Atributo | Valor |
|----------|-------|
| **Variables** | 20 |
| **Instancias** | 10,000 (generadas sinteticamente) |
| **Arcos** | 25 |
| **Tipo** | Continuo (aproximacion de red discreta) |
| **Fuente del grafo** | Spiegelhalter et al. (1993) |
| **Datos** | ⚠️ **SINTETICOS** - SEM Lineal Gaussiano |

**Descripcion**: Red bayesiana para diagnostico de enfermedad cardiaca congenita en ninos, del proyecto BUGS.

**Que es REAL**: La topologia de la red (20 nodos, 25 arcos).

**Que es SINTETICO**: Todos los valores numericos.

---

### 4. Insurance Network

| Atributo | Valor |
|----------|-------|
| **Variables** | 27 |
| **Instancias** | 20,000 (generadas sinteticamente) |
| **Arcos** | 52 |
| **Tipo** | Continuo (aproximacion de red discreta) |
| **Fuente del grafo** | Binder et al. (1997) |
| **Datos** | ⚠️ **SINTETICOS** - SEM Lineal Gaussiano |

**Descripcion**: Red de evaluacion de riesgos para companias de seguros de automoviles.

**Que es REAL**: La topologia de la red (27 nodos, 52 arcos).

**Que es SINTETICO**: Todos los valores numericos.

---

## Datasets de Inferencia Causal (Tratamiento)

### 5. IHDP (Infant Health and Development Program)

| Atributo | Valor |
|----------|-------|
| **Unidades** | 747 (generadas sinteticamente) |
| **Covariables** | 25 (~N(0,1)) |
| **Tratamiento** | Binario (logit PS model) |
| **Outcome** | Continuo (formula lineal) |
| **ATE verdadero** | ~ 3.92 (calculado de los datos generados) |
| **Fuente** | Hill (2011), JCGS (solo como inspiracion) |
| **Datos** | ⚠️ **100% SINTETICOS** |

**Descripcion**: Dataset completamente sintetico inspirado en el programa IHDP real. No contiene ningun dato real del estudio.

**Que es REAL (aproximado)**:
- Numero de unidades (747) y covariables (25) basado en Hill (2011)
- ATE esperado (~4.0) consistente con la literatura
- Nombres de covariables (bw, b.head, momage, etc.)

**Que es SINTETICO**:
- **Todas** las covariables: generadas como ~N(0, 1)
- **Tratamiento**: modelo logit con coeficientes fijos (no de datos reales)
- **Outcomes**: formulas lineales con efectos heterogeneos
  - Y0 = 50 + 10*X0 + 5*X1 + 3*X4 + ...
  - tau = 4.0 + 2.0*X0 + 1.5*X2 - X3
  - Y1 = Y0 + tau
- Ruido gaussiano agregado a los outcomes

**Ground truth**: Los outcomes potenciales Y(0) y Y(1) son generados y guardados, permitiendo calcular el error exacto del ATE estimado.

**Usos**:
- Benchmark principal para ATE (metodo mas usado en la literatura)
- Evaluar estimacion de efectos heterogeneos (CATE)
- Comparar cobertura de intervalos de confianza

**Metricas esperadas** (errores del ATE):
- OLS: ~ 0.5-1.0
- PSM: ~ 0.3-0.7
- AIPW: ~ 0.1-0.3
- DML: ~ 0.05-0.2

---

### 6. Jobs/LaLonde

| Atributo | Valor |
|----------|-------|
| **Unidades** | 1,722 (generadas sinteticamente) |
| **Covariables** | 8 (edad ~U(18,55), educ ~U(5,17), ingresos ~N(5000,3000), etc.) |
| **Tratamiento** | Binario (logit PS model) |
| **Outcome** | Continuo (formula lineal) |
| **ATE verdadero** | ~ 1,600 (calculado de los datos generados) |
| **Fuente** | LaLonde (1986), AER (solo como inspiracion) |
| **Datos** | ⚠️ **100% SINTETICOS** |

**Descripcion**: Dataset completamente sintetico inspirado en el National Supported Work Demonstration. No contiene datos reales del programa NSW ni del CPS.

**Que es REAL (aproximado)**:
- ATE esperado (~1,800 USD) basado en resultados experimentales de LaLonde (1986)
- Nombres de covariables (age, educ, black, hispan, married, nodegree, re74, re75)
- Estructura del programa (entrenamiento laboral, ingresos post-tratamiento)

**Que es SINTETICO**:
- Edad: ~U(18, 55)
- Educacion: ~U(5, 17)
- Raza: ~Bernoulli(0.25 negro, 0.15 hispano)
- Ingresos pre-tratamiento: 5*age + 200*educ + N(5000, 3000)
- Tratamiento: logit con sesgo hacia desempleados
- Outcome: formula lineal con ATE forzado a ~1800

**Usos**:
- Evaluar metodos de matching (PSM, CEM)
- Comparar resultados observacionales vs experimentales
- Probar sensibilidad a confusores no observados

---

### 7. Twins

| Atributo | Valor |
|----------|-------|
| **Pares de gemelos** | 5,700 (generados sinteticamente) |
| **Covariables** | 40 (edad madre ~U(15,45), gestacion ~N(38,2), etc.) |
| **Tratamiento** | Binario (bajo peso al nacer < 2500g) |
| **Outcome** | Binario (mortalidad, modelo logit) |
| **ATE verdadero** | ~ 0.0 (no se logra efecto sistematico en simulacion actual) |
| **Fuente** | Almond et al. (2005), NBER (solo como inspiracion) |
| **Datos** | ⚠️ **100% SINTETICOS** |

**Descripcion**: Dataset completamente sintetico que simula un estudio de gemelos. No contiene datos del NCHS.

**Que es REAL (aproximado)**:
- Diseno de estudio (pares de gemelos, comparacion intra-gemelar)
- Definicion de tratamiento (peso al nacer < 2500g)
- Outcome (mortalidad en el primer ano)
- Rango de ATE esperado (~0.05-0.08 de la literatura)

**Que es SINTETICO**:
- Edad de la madre: ~U(15, 45)
- Educacion de la madre: ~U(8, 20)
- Gestacion: ~N(38, 2)
- Peso al nacer: 2000 + 100*gestacion + N(0, 300)
- Mortalidad: modelo logit con coeficientes fijos
- ATE calculado por diferencia intra-gemelar (actualmente ~0.0 porque el peso al nacer se genera independientemente del tratamiento)

> **Nota**: El ATE verdadero en esta simulacion actual es ~0.0, lo que NO coincide con el rango ~0.05-0.08 reportado en Almond et al. (2005). Esto se debe a que la generacion actual no modela adecuadamente la relacion entre bajo peso y mortalidad. Es un area de mejora para el generador.

**Usos**:
- Evaluar metodos con outcomes binarios
- Probar control de confusores no observados
- Validar resultados con comparacion intra-gemelar

---

## Datasets Sinteticos Controlados

Estos datasets son **explicitamente sinteticos** y no pretenden representar ningun dominio real.

### Lineal Gaussianos

| Configuracion | Variables | Arcos | Muestras | Tipo Grafo |
|---------------|-----------|-------|----------|------------|
| 10_vars_10_edges | 10 | 10 | 1,000 | Erdos-Renyi |
| 10_vars_20_edges | 10 | 20 | 1,000 | Erdos-Renyi |
| 20_vars_20_edges | 20 | 20 | 2,000 | Erdos-Renyi |
| 20_vars_40_edges | 20 | 40 | 2,000 | Erdos-Renyi |
| 50_vars_50_edges | 50 | 50 | 5,000 | Erdos-Renyi |
| 50_vars_100_edges | 50 | 100 | 5,000 | Erdos-Renyi |
| 100_vars_150_edges | 100 | 150 | 10,000 | Erdos-Renyi |
| 20_vars_sf | 20 | 30 | 2,000 | Scale-Free |
| 50_vars_sf | 50 | 75 | 5,000 | Scale-Free |

**Propiedades**:
- Pesos: U(0.5, 2.0)
- Ruido: N(0, 1)
- Grafo conocido exactamente (matriz de adyacencia incluida)

---

### No Gaussianos (LiNGAM)

| Configuracion | Variables | Arcos | Muestras | Ruido |
|---------------|-----------|-------|----------|-------|
| 10_vars_laplace | 10 | 15 | 1,000 | Laplace(0,1) |
| 20_vars_laplace | 20 | 30 | 2,000 | Laplace(0,1) |
| 10_vars_uniform | 10 | 15 | 1,000 | Uniform(-sqrt(3), sqrt(3)) |
| 20_vars_exponential | 20 | 30 | 2,000 | Exp(1) - 1 |
| 10_vars_gumbel | 10 | 15 | 1,000 | Gumbel(0,1) |

**Algoritmos target**: ICA-LiNGAM, DirectLiNGAM

---

### No Lineales

| Configuracion | Variables | Arcos | Muestras | Tipo |
|---------------|-----------|-------|----------|------|
| 10_vars_mlp | 10 | 15 | 1,000 | MLP (1 capa oculta) |
| 20_vars_mlp | 20 | 30 | 2,000 | MLP |
| 10_vars_polynomial | 10 | 15 | 1,000 | Polinomio grado 2 |
| 20_vars_polynomial | 20 | 30 | 2,000 | Polinomio grado 2 |
| 10_vars_gp | 10 | 15 | 1,000 | Proceso Gaussiano |
| 10_vars_heteroscedastic | 10 | 15 | 2,000 | Ruido heteroscedastico |

---

### Series Temporales (PCMCI)

| Configuracion | Variables | Lags | Muestras | Tipo |
|---------------|-----------|------|----------|------|
| 5_vars_2_lags | 5 | 2 | 1,000 | VAR lineal |
| 5_vars_3_lags | 5 | 3 | 1,000 | VAR lineal |
| 10_vars_2_lags | 10 | 2 | 2,000 | VAR lineal |
| 10_vars_3_lags | 10 | 3 | 2,000 | VAR lineal |
| 5_vars_nonlinear_ts | 5 | 1 | 1,000 | No lineal |

---

### Inferencia Causal (Sinteticos)

| Configuracion | Unidades | Covariables | ATE Verdadero | Tipo |
|---------------|----------|-------------|---------------|------|
| ihdp_small | 1,000 | 25 | ~4.0 | Efectos heterogeneos |
| ihdp_medium | 2,000 | 25 | ~4.0 | Efectos heterogeneos |
| ihdp_large | 5,000 | 25 | ~4.0 | Efectos heterogeneos |
| lalonde_small | 1,000 | 8 | ~1800 | Programa laboral |
| lalonde_medium | 2,000 | 8 | ~1800 | Programa laboral |
| twins_small | 2,000 | 40 | ~0.06 | Mortalidad infantil |
| twins_medium | 4,000 | 40 | ~0.06 | Mortalidad infantil |

---

## Casos de Borde

### Alta Colinealidad
- 15 variables con correlaciones > 0.8
- Prueba robustez de PC/NOTEARS ante datos degenerados
- Completamente sintetico

### Confusor Latente
- Grafo con confusor no observado que afecta tratamiento y outcome
- Prueba capacidad de FCI para detectar variables latentes
- Evalua sesgo por confusor omitido

### M-Graph (No Identificable)
- Estructura donde no existe set de ajuste valido
- Prueba capacidad de abstencion del agente
- El ATE no es identificable sin supuestos adicionales
