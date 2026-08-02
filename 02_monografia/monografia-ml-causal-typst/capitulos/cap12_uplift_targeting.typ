// Capítulo 12 — Uplift modeling y targeting económico
#import "../template/template.typ": *

#chapter[Uplift modeling y targeting económico]
<cap-uplift-targeting>

#theorem-number-reset()

#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*[Problema]*], [Asignación óptima de tratamientos con costos diferenciales y presupuesto],
    [*[Estimando]*], [CATE por tratamiento $tau_k(x)$, policy value $V(pi)$],
    [*[Identificación]*], [No confusión condicional + soporte común],
    [*[Método]*], [Uplift modeling, net score, Qini optimization],
    [*[Nuisance]*], [$hat(mu)_k(x)$, $hat(e)_k(x)$, costos $c_k$],
    [*[Garantía]*], [Convergencia de $hat(tau)_k$ a $tau_k$ bajo cross-fitting],
    [*[Librerías]*], [causalml, econml],
    [*[Validación]*], [Curva Qini, AUUC, análisis de costo-efectividad],
  )
]

#notatecnica[
El @cap-policy-learning formalizó la política óptima como problema de decisión restringido; este capítulo cierra la Parte V con la práctica de *targeting* de marketing y programas sociales, y con las mismas curvas Qini ya usadas para validación en el @cap-validacion, ahora como criterio de evaluación de la política y no solo del estimador.
]

== Motivación aplicada
<sec-cap12_motivacion>

Una empresa de telecomunicaciones desea reducir la _churn_ (baja de clientes). Dispone de tres acciones: (a) no hacer nada, (b) enviar un SMS con descuento, (c) llamar por teléfono con oferta personalizada. El costo de cada acción es distinto: SMS cuesta \$0.5, llamada cuesta \$8. El efecto sobre retención varía por cliente. La pregunta de política: ¿a qué clientes aplicar cada acción, sujeto a un presupuesto total de \$100\,000?

El _uplift modeling_ es el análogo del policy learning en contextos de marketing. La métrica clave es el _uplift_: la diferencia en la probabilidad de conversión (o retención) entre recibir y no recibir el tratamiento. Los métodos se han desarrollado en la industria [@radcliffe2007using; @gutierrez2017causal] y se han integrado con la literatura académica de ML causal [@athey2021policy].

Este capítulo presenta los métodos clásicos de uplift (two-model, transformed outcome, Qini optimization), su implementación con #code[causalml], y la extensión a múltiples tratamientos y restricciones presupuestarias.

== Marco teórico formal
<sec-cap12_marco_teorico>

=== Uplift y CATE
<sec-cap12_uplift_cate>

El _uplift_ es matemáticamente equivalente al CATE:
$
"uplift"(x) = E[Y(1) - Y(0) mid X = x] = tau(x).
$ <eq-uplift_cate>

La diferencia con el capítulo @cap-meta-learners es el foco aplicado: uplift modeling se preouniona por _ranking_ (qué clientes tienen mayor uplift) y por _cost-effectiveness_ (cuánto uplift se obtiene por dólar invertido), no solo por la estimación puntual del CATE.

=== Qini y AUUC: teoría, supuestos y garantías
<sec-cap12_qini_auuc>

La curva Qini y el AUUC (_Area Under Uplift Curve_) son las métricas estándar para evaluar modelos de uplift en ausencia de _ground truth_ individual.

*Definición.* Sea $cal(D)$ una muestra con $n$ unidades, cada una con tratamiento $D_i in {0, 1}$ y outcome observado $Y_i$. Ordenamos las unidades por $hat(tau)(x_i)$ descendente. Para cada punto de corte $p in [0, 1]$, el uplift acumulado se define como:
$
"uplift"(p) = (1 / n) sum_(i=1)^(floor(n p))
  (Y_i D_i / hat(e)(x_i) - (Y_i (1 - D_i)) / (1 - hat(e)(x_i))),
$ <eq-qini>
donde $hat(e)(x)$ es la propensión estimada. El AUUC integra esta curva sobre $p in [0, 1]$ y normaliza respecto a una asignación aleatoria:
$
"AUUC" = integral_0^1 ("uplift"(p) - "uplift"_"aleatorio"(p)) dif p.
$ <eq-auuc>

*Supuestos.* La validez de la curva Qini y el AUUC requiere:
- *Inconfundibilidad (unconfoundedness):* $Y(1), Y(0) perp perp D mid X$.
- *Soporte común (overlap):* $0 < e(x) < 1$ para todo $x$.
- *Propensity score correcto:* $hat(e)(x)$ es una estimación consistente de $e(x) = P(D = 1 mid X = x)$.

Bajo estos supuestos, la curva Qini ordena correctamente las unidades por su CATE esperado y permite comparar modelos de forma válida.

*Garantías.* @radcliffe2007using demuestra que la pendiente de la curva Qini en el origen es proporcional al CATE promedio en la cola superior de la ordenación. @gutierrez2017causal establece que el AUUC es equivalente al coeficiente de Gini del uplift bajo normalización. En la práctica, la curva Qini permite comparar modelos de uplift: curvas más arriba indican mejor capacidad de ranking. Cuando se utilizan intervalos de confianza por bootstrap, es posible evaluar si las diferencias entre modelos son estadísticamente significativas.

*Cost-weighted uplift.* Cuando los costos del tratamiento varían entre individuos, se pondera el uplift por el costo unitario:
$
"CW-uplift"(x) = (hat(tau)(x)) / (c(x)),
$ <eq-cw-uplift>
donde $c(x)$ es el costo del tratamiento para el cliente $x$. Esta métrica permite priorizar acciones con mayor retorno por dólar invertido.

=== Multi-treatment uplift
<sec-cap12_multitreatment>

Cuando hay $K$ tratamientos posibles, el problema se extiende a estimar $tau_k(x) = E[Y(k) - Y(0) mid X = x]$ para $k = 1, ..., K$. La política óptima asigna a cada cliente el tratamiento con mayor $tau_k(x) - c_k(x)$, donde $c_k$ es el costo del tratamiento $k$.

#intuicion[
  *Caja de profundización 12.1: Bootstrap para la curva Qini y embeddings como covariables*

  *Bootstrap para la curva Qini.* Una forma de comparar modelos de uplift con incertidumbre:
  + Remuestrear los datos 200 veces.
  + Cada vez, recalcular la curva Qini y el AUUC.
  + Reportar el AUUC promedio con intervalo de confianza.

  Esto evita confiar en un solo número que puede ser ruidoso.

  *Embeddings como covariables.* Si tenemos texto, imágenes o datos no estructurados, podemos usar embeddings (representaciones numéricas) como covariables $X$ para estimar CATE. Pero cuidado: un embedding puede ser proxy de variables sensibles como género o raza.
]

== Algoritmo: Asignación por net score con presupuesto
<sec-cap12_algoritmo>

Resolver la asignación óptima de tratamientos con costos distintos y un presupuesto limitado requiere un enfoque de optimización. El método de _net score_ introduce un costo sombra $lambda$ que equilibra el beneficio marginal del tratamiento con su costo.

El problema formal: tenemos $K$ tratamientos con costos $c_k$ y un presupuesto $B$. Queremos asignar a cada persona el tratamiento que maximice el uplift neto—beneficio menos costo— sin exceder $B$.

#algorithm("Asignación por net score con presupuesto")[
  #kwin[Entrada][$hat(tau)_k(x)$ para cada tratamiento $k = 1, dots, K$, costos $c_k$, presupuesto $B$, datos $cal(D)$ con $N$ observaciones]
  #kwout[Salida][Asignación $pi(x) in {0, 1, dots, K}$ que maximiza el uplift total sujeto a $sum_(i=1)^N c_(pi(x_i)) <= B$]
  Inicializar $lambda <- 0$ y $lambda_"max" <- max_k c_k^(-1) B$ \
  *repeat* #h(2pt) hasta $|G - B| < epsilon$ o $lambda_"max" - lambda_"min" < delta$: \
  #h(1.5em) $lambda <- (lambda + lambda_"max") / 2$ \
  #h(1.5em) Calcular net score $s_k(x) = hat(tau)_k(x) - lambda dot.c c_k(x)$ para cada $x$ y $k$ \
  #h(1.5em) Asignar $pi(x) = "argmax"_k s_k(x)$ \
  #h(1.5em) Calcular gasto total $G = sum_(i=1)^N c_(pi(x_i))$ \
  #h(1.5em) *if* #h(2pt) $G > B$ *then* #h(2pt) $lambda_"min" <- lambda$ \
  #h(1.5em) *else if* #h(2pt) $G < B$ *then* #h(2pt) $lambda_"max" <- lambda$ \
  #return-stmt[$pi(x)$ para cada $x$.]
] <alg-net-score>

El parámetro $lambda$ es el multiplicador de Lagrange (costo sombra) de la restricción presupuestaria. Cuando $lambda = 0$, el algoritmo asigna según el uplift bruto; al aumentar $lambda$, se penalizan los tratamientos costosos, favoreciendo acciones más baratas. La búsqueda por bisección garantiza convergencia al valor de $lambda$ que satura la restricción.

La solución de net score es equivalente a resolver:
$
pi^*(x) = "argmax"_k { tau_k(x) - lambda^* c_k(x) },
$ <eq-net-score-opt>
donde $lambda^*$ es el costo sombra que agota el presupuesto $B$. Nótese que $lambda^*$ no es una penalización de regularización (como en LASSO), sino el precio implícito de relajar la restricción presupuestaria en una unidad.

== Aplicación con Python
<sec-cap12_python>

=== Uplift modeling con causalml
<sec-cap12_causalml>

La biblioteca #code[causalml] proporciona implementaciones de meta-learners (S-learner, T-learner, X-learner) y herramientas de validación como la curva Qini y el AUUC. El siguiente listado muestra un flujo completo de estimación y evaluación.

#figure(
  kind: raw,
  caption: [Uplift modeling con causalml.],
  ```python
import numpy as np
import pandas as pd
from causalml.inference.meta import XGBTRegressor, MLPTRegressor
# En causalml reciente, usar por ejemplo:
# from causalml.inference.meta import BaseXRegressor
# xlearner = BaseXRegressor(learner=XGBRegressor())
# Verificar version; si XGBTRegressor no esta disponible, usar BaseXRegressor.
from causalml.metrics import plot_qini, qini_score

# Dataset sintetico de churn
def make_churn_data(n=5000, seed=42):
    rng = np.random.default_rng(seed)
    X = rng.uniform(-1, 1, (n, 8))
    e = 0.5 + 0.2 * np.tanh(X[:, 0])  # propensity
    D = (rng.uniform(size=n) < e).astype(int)
    tau = 0.3 - 0.4 * X[:, 0] + 0.2 * X[:, 1]  # uplift (retencion)
    base = 0.5 + 0.1 * X[:, 2]  # baseline churn
    Y = (rng.uniform(size=n) < base + D * tau).astype(int)  # conversion
    return pd.DataFrame({"y": Y, "treatment": D,
                         **{f"x{i}": X[:, i] for i in range(X.shape[1])}})

df = make_churn_data(5000)
features = [f"x{i}" for i in range(8)]

# X-learner con XGBoost
xlearner = XGBTRegressor()
xlearner.fit(X=df[features].values, treatment=df["treatment"].values,
             y=df["y"].values)
df["uplift_xl"] = xlearner.predict(df[features].values)

# Qini score
qini = qini_score(df[["y", "treatment", "uplift_xl"]])
print(f"Qini score: {qini}")

# Visualizacion
plot_qini(df[["y", "treatment", "uplift_xl"]], uplift_col="uplift_xl",
          treatment_col="treatment", outcome_col="y")
```
) <lst-uplift>

=== Caso empírico y validación: costo-efectividad
<sec-cap12_costo_efectividad>

El análisis de costo-efectividad extiende la evaluación más allá del ranking: incorpora costos reales de las acciones y restricciones presupuestarias para derivar políticas concretas. El listado @lst-cost-effectiveness implementa la comparación de tres estrategias de targeting (SMS, llamada y mixta) utilizando el algoritmo de net score.

#figure(
  kind: raw,
  caption: [Analisis costo-efectividad de targeting.],
  ```python
# Costo: 0.5 USD por SMS, 8 USD por llamada
# Presupuesto: 100,000 USD
budget = 100_000
cost_sms = 0.5
cost_call = 8

n = len(df)

n_sms = min(int(budget / cost_sms), n)
n_calls = min(int(budget / cost_call), n)

n_calls_mix = min(int(budget * 0.5 / cost_call), n)
remaining = n - n_calls_mix
n_sms_mix = min(int(budget * 0.5 / cost_sms), max(remaining, 0))

# Estrategia A: SMS a todos
df_sorted = df.sort_values("uplift_xl", ascending=False)
top_sms = df_sorted.head(n_sms)
uplift_a = top_sms["uplift_xl"].sum()
print(f"Estrategia A (SMS a {n_sms} clientes): "
      f"uplift total = {uplift_a:.2f}")

# Estrategia B: llamadas a top por uplift
required_cols = ["uplift_sms", "uplift_call"]
missing = [col for col in required_cols if col not in df.columns]

if missing:
    raise ValueError(
        "Faltan columnas de uplift por tratamiento: "
        f"{missing}. Estime uplift_sms y uplift_call por separado."
    )

top_calls = df_sorted.head(n_calls)
uplift_b = top_calls["uplift_call"].sum()
print(f"Estrategia B (llamadas a {n_calls} clientes): "
      f"uplift total = {uplift_b:.2f}")

# Estrategia C: mixto - SMS a top, llamadas a top
top_calls_mix = df_sorted.head(n_calls_mix)
top_sms_mix = df_sorted.iloc[n_calls_mix:n_calls_mix + n_sms_mix]
uplift_c = (
    top_calls_mix["uplift_call"].sum()
    + top_sms_mix["uplift_sms"].sum()
)
print(f"Estrategia C (mixto): uplift total = {uplift_c:.2f}")
```
) <lst-cost-effectiveness>

La figura @fig-cap12-uplift ilustra dos elementos clave del uplift modeling aplicado. El panel izquierdo muestra la curva de uplift acumulado: al ordenar la muestra por $hat(tau)$ descendente, el uplift acumulado crece rápidamente al inicio y se estabiliza, indicando que las unidades top concentran la mayor parte del uplift total. El panel derecho muestra el análisis de costo-efectividad: dada una mezcla presupuestaria entre dos acciones (SMS barato vs. llamada cara), existe una asignación óptima que maximiza el uplift total.

#figure(
  image("../figuras/fig_cap12_uplift.png", width: 100%),
  caption: [Izquierda: curva de uplift acumulado ordenando la muestra por CATE estimado (Causal Forest). Derecha: análisis de costo-efectividad de la mezcla entre SMS (\$0.5/unidad) y llamada (\$8/unidad) bajo un presupuesto total de \$100\,000. Dataset sintético tipo churn, $n = 5\,000$.],
) <fig-cap12-uplift>

*Interpretación.* La curva de uplift acumulado (panel izquierdo) muestra que el top 20% de la muestra por CATE estimado captura aproximadamente el 60% del uplift total, lo que justifica el targeting. El análisis de costo-efectividad (panel derecho) identifica la mezcla óptima: con un presupuesto fijo, conviene asignar la mayoría del presupuesto a SMS (más barato, mayor cobertura) y reservar llamadas para los casos de mayor uplift.

== Riesgos, límites y mitigación
<sec-cap12_riesgos>

El uso de uplift modeling para targeting con múltiples tratamientos y restricciones presupuestarias presenta riesgos metodológicos que deben diagnosticarse y mitigarse.

#riesgos[
  #figure(
    caption: [Riesgos comunes en uplift modeling y targeting],
    table(
      columns: (1.5fr, 1.5fr, 1.5fr, 1.8fr),
      align: (left, left, left, left),
      stroke: none,
      table.hline(stroke: 0.8pt),
      table.header([*Riesgo*], [*Consecuencia*], [*Diagnóstico*], [*Mitigación*]),
      table.hline(stroke: 0.4pt),
      [Multiplicar uplift ad hoc para inferir el efecto de otro tratamiento], [Comparación inválida entre acciones y política subóptima], [Verificar que cada tratamiento tiene su propia columna de $hat(tau)_k$ en los datos], [Estimar $tau_k(x)$ por separado para cada acción $k$ usando meta-learners],
      [Optimizar solo el ranking (AUUC) sin validar la magnitud del uplift], [Mala calibración; el gasto real no coincide con el proyectado], [Comparar _calibration_ del CATE: $E[Y mid D = 1, X] - E[Y mid D = 0, X]$ vs.\ $hat(tau)$], [Usar _transformed outcome_ para obtener estimaciones de magnitud insesgadas],
      [Medir costos de forma incorrecta o ignorar costos hundidos], [Política de asignación errónea; se gastan recursos en acciones con retorno negativo], [Análisis de sensibilidad variando $c_k$ en $plus.minus 20%$ y observando cambios en la política óptima], [Utilizar costos reales (contables u operativos) y modelar incertidumbre con bootstrap],
      table.hline(stroke: 0.8pt),
    )
  ) <tab-riesgos-cap12>
]

Además de los riesgos anteriores, es importante considerar la equidad: una estrategia que maximiza el uplift puede excluir sistemáticamente a grupos vulnerables. Se recomienda reportar la distribución demográfica de los tratados y evaluar si existen disparidades injustificadas en la asignación.

== Ejercicios propuestos
<sec-cap12_ejercicios>

+ Replique el listado @lst-uplift sobre #code[thornton_hiv]. ¿Cuál es el Qini score?

+ Construya un dataset con dos tratamientos (SMS vs llamada) y use #code[causalml] para estimar el CATE de cada uno. ¿Qué tratamiento es más efectivo en promedio? Use #code[BaseTRegressor] o #code[BaseXRegressor] de causalml (según versión) con un learner por tratamiento, o estime $tau_"sms"$ y $tau_"call"$ por separado.

+ Modifique el listado @lst-cost-effectiveness para imponer la restricción de tratar al menos al 20% de cada grupo demográfico. ¿Cómo cambia el uplift total?

+ Discuta: ¿en qué casos el uplift modeling es preferible al policy learning formal?

== Lecturas complementarias
<sec-cap12_lecturas>

@radcliffe2007using introduce la curva Qini. @gutierrez2017causal formaliza el transformed outcome. @kuo2014causalml documenta #code[causalml]. Para multi-treatment y policy learning con restricciones, @athey2021policy.
