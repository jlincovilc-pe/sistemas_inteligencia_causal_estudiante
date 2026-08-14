// Capítulo 13 — Árboles y bosques causales
#import "../template/template.typ": *

#chapter[Árboles y bosques causales]
<cap-causal-forests>

#theorem-number-reset()

// Alias de etiqueta preservado del original LaTeX (\label{cap:arboles_bosques})
#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*Problema:*], [Identificar subgrupos con efectos heterogéneos],
    [*Estimando:*], [$"CATE"(x)$],
    [*Identificación:*], [No confusión, soporte común, SUTVA],
    [*Método:*], [Causal trees, causal forests, GRF],
    [*Nuisance:*], [$mu_(d)(x), e(x)$],
    [*Garantía:*], [Normalidad asintótica local],
    [*Librerías:*], [#code[econml], #code[grf] (R)],
    [*Validación:*], [Honesty, feature importance, policy trees],
  )
]

#notatecnica[
Los meta-learners del @cap-meta-learners reutilizan _learners_ genéricos de fuera de la caja; este capítulo presenta una familia diseñada específicamente para CATE — árboles y bosques causales con partición _honesta_—, que suele ofrecer mejores garantías de inferencia a costa de mayor especialización.
]

== Motivación aplicada
<sec-cap13_motivacion>

Un organismo gubernamental desea identificar subgrupos de la población donde un programa de transferencias condicionadas tiene el mayor efecto sobre la asistencia escolar. El CATE promedio puede ser modesto (3 puntos porcentuales), pero la heterogeneidad podría ser grande: en algunos subgrupos el efecto es nulo, en otros supera los 10 puntos. Identificar esos subgrupos permite focalizar el programa y mejorar su costo-efectividad.

Los _causal trees_ @athey2016recursive y los _causal forests_ / _Generalized Random Forests_ @athey2019generalized son métodos diseñados específicamente para estimar CATEs con garantías de inferencia válidas. La innovación clave es la _honesty_: la partición del árbol se decide usando una submuestra distinta de la que se usa para estimar el efecto dentro de cada hoja. Esto evita el _overfitting_ estructural de los árboles estándar y permite construir intervalos de confianza asintóticamente válidos.

Conviene ubicar la contribución con precisión, porque el nombre "bosque causal" sugiere una analogía con el bosque aleatorio predictivo que es engañosa. Un bosque aleatorio predice promediando predicciones; un bosque causal, en su formulación canónica, *no* promedia estimaciones de $tau$ producidas por cada árbol. Lo que hace es usar la estructura de árboles para inducir una función de *pesos de vecindad* $omega_(i)(x)$ —cuán a menudo la observación $i$ cae en la misma hoja que el punto de consulta $x$— y luego resolver una ecuación de momento local ponderada con esos pesos. El bosque, en otras palabras, es un procedimiento adaptativo para elegir *qué vecinos son relevantes* para estimar el efecto en $x$; la estimación propiamente dicha la hace el score causal, no el árbol. Esta distinción, que la @sec-cap13_grf desarrolla, es la que explica por qué el método admite intervalos de confianza mientras que un T-learner con bosques aleatorios no.

Este capítulo desarrolla la teoría de árboles y bosques causales, presenta la implementación con #code[econml.dml.CausalForestDML], y discute cuándo el método es apropiado frente a alternativas como meta-learners o DML lineal.

== Teoría, supuestos y garantías
<sec-cap13_teoria>

=== Árboles causales honestos
<sec-cap13_arboles_causales>

Un _causal tree_ es un árbol de decisión que particiona el espacio de covariables $X$ en hojas $cal(L)_1, ..., cal(L)_M$. Dentro de cada hoja $cal(L)_m$, el CATE se estima como la diferencia de medias entre tratados y controles:
$
hat(tau)(cal(L)_m) = 1/n_(1,m) sum_(i in cal(L)_m, D_i = 1) Y_i - 1/n_(0,m) sum_(i in cal(L)_m, D_i = 0) Y_i.
$ <eq-causal-tree-tau>

La _honesty_ exige que la muestra usada para decidir las divisiones (_splitting subsample_) sea distinta de la usada para estimar $hat(tau)$ (_estimation subsample_). Esto se logra dividiendo la muestra de entrenamiento en dos mitades antes de construir el árbol.

#definition(name: [Honesty])[
  Un árbol causal es _honest_ si las decisiones de partición son independientes (en muestra) de las estimaciones de $hat(tau)$ dentro de cada hoja. Formalmente, existe una partición de la muestra de entrenamiento $S = S_("split") union S_("est")$ tal que el árbol se construye usando $S_("split")$ y los efectos se estiman usando $S_("est")$.
] <def-honesty>

*Por qué importa la honestidad.* Sin honestidad, el árbol selecciona divisiones que maximizan la diferencia de medias _observada_ entre tratados y controles, lo que introduce un sesgo de selección: los CATEs estimados en hojas seleccionadas tienden a ser mayores (en valor absoluto) que los verdaderos. Con honestidad, las divisiones se seleccionan usando una muestra independiente, evitando este sesgo.

#algorithm("Causal tree honesto")[
  #kwin[Entrada][Muestra ${(Y_i, D_i, X_i)}_(i=1)^n$, tamaño mínimo de hoja $n_(min)$, mínimo de tratados por hoja $n_(1,min)$, mínimo de controles por hoja $n_(0,min)$.]
  #kwout[Salida][Árbol $cal(T)$ con hojas $cal(L)_1, ..., cal(L)_M$ y estimaciones $hat(tau)(cal(L)_m)$.]
  Dividir la muestra en $S_("split")$ (splitting) y $S_("est")$ (estimación). \
  Inicializar $cal(T)$ con una sola hoja (raíz) que contiene $S_("split")$. \
  *while* haya hojas factibles sin dividir: \
  #h(1.5em) Seleccionar una hoja $cal(L)$ de $cal(T)$. \
  #h(1.5em) *for* cada posible división binaria $X_j <= c$: \
  #h(3em) Calcular la varianza entre hojas $hat(V)_tau$ usando @eq-causal-tree-criterion sobre $S_("split")$. \
  #h(1.5em) Elegir la división que maximiza $hat(V)_tau$. \
  #h(1.5em) Si la división respeta $n_(min), n_(1,min), n_(0,min)$, aplicarla y crear dos nuevas hojas. \
  *for* cada hoja $cal(L)_m$ del árbol final: \
  #h(1.5em) Estimar $hat(tau)(cal(L)_m)$ usando $S_("est")$ según @eq-causal-tree-tau. \
  #return-stmt[$cal(T)$ con $hat(tau)(cal(L)_m)$ por hoja.]
] <alg-causal-tree-honest>

=== El criterio de splitting
<sec-cap13_splitting>

El criterio estándar para árboles predictivos es la reducción de varianza. Para árboles causales, @athey2016recursive proponen maximizar la varianza _entre hojas_ del CATE estimado, que es un estimador de la varianza del CATE verdadero:
$
hat(V)_tau = 1/|S_("split")| sum_(i in S_("split")) (hat(tau)(X_i) - overline(tau))^2,
$ <eq-causal-tree-criterion>
donde $overline(tau)$ es el CATE promedio. La división óptima maximiza $hat(V)_tau$ sujeto a restricciones de tamaño mínimo de hoja y balance entre tratados y controles.

== Estimador y score
<sec-cap13_estimador>

=== Causal forests y Generalized Random Forests
<sec-cap13_grf>

Un _causal forest_ es un ensemble de $B$ árboles causales honestos, cada uno entrenado en una submuestra bootstrap. El CATE estimado es el promedio sobre los árboles:
$
hat(tau)_("CF")(x) = 1/B sum_(b=1)^B hat(tau)_(b)(x).
$ <eq-cf-average>

#intuicion[
  La expresión anterior corresponde a la intuición de bosque causal clásico: promediar predicciones de árboles honestos. Bajo honesty y condiciones de submuestreo, este promedio puede ser consistente. Sin embargo, en Generalized Random Forests [@athey2019generalized], la formulación canónica no se presenta como un simple promedio de $hat(tau)_(b)(x)$, sino como un estimador local ponderado. El bosque induce pesos adaptativos $omega_(i)(x)$, y $hat(theta)(x)$ se obtiene resolviendo una ecuación de momento local:

  $
  sum_i omega_(i)(x) psi_(i)(hat(theta)(x)) = 0.
  $

  Para CATE, esto equivale a una estimación local ortogonalizada usando pesos de vecindad inducidos por el bosque.
]

#cite(<athey2019generalized>, form: "prose") generalizan el marco a _Generalized Random Forests_ (GRF), que permite estimar cualquier parámetro definido por ecuaciones de momento locales ponderadas. El CATE es un caso particular, pero GRF también estima efectos locales promedio (LATE), efectos cuantiles, y otros estimandos.

#theorem(name: [Normalidad asintótica local de Causal Forest])[
  Bajo condiciones de honesty, submuestreo, soporte común y suavidad local, existe una varianza estimada $hat(V)(x)$ tal que
  $
  (hat(tau)_("CF")(x) - tau(x)) / sqrt(hat(V)(x)) arrow.r^(d) N(0, 1).
  $

  La tasa de convergencia es local y depende de la probabilidad de caer en hojas cercanas a $x$, del tamaño de submuestra y de la suavidad de $tau(x)$. No debe presentarse como una normalización $sqrt(n)$ universal para CATE no paramétrico.
] <thm-cf-normality>

=== Comparación con meta-learners
<sec-cap13_comparacion_metalearners>

#figure(
  caption: [Causal Forest vs. meta-learners.],
  table(
    columns: (1.3fr, 1.6fr, 1.6fr),
    align: (left, left, left),
    stroke: none,
    table.hline(stroke: 0.8pt),
    table.header([*Dimensión*], [*Causal Forest*], [*Meta-learners (S/T/X/R)*]),
    table.hline(stroke: 0.4pt),
    [Inferencia sobre $tau(x)$], [Asintótica local vía influence function/varianza estimada], [Solo bootstrap (T, X), asintótica (R)],
    [Heterogeneidad estructurada], [Captura automáticamente], [Requiere especificar base functions],
    [Honesty], [Implementada por defecto], [No],
    [Interpretación], [Caja negra], [Caja negra],
    [Caso ideal], [Muchas variables, no lineal], [Estructura conocida o simple],
    table.hline(stroke: 0.8pt),
  )
) <tab-cf-vs-meta>

== Implementación en Python
<sec-cap13_implementacion>

=== Estimación con CausalForestDML
<sec-cap13_causaldml>

#figure(
  kind: raw,
  caption: [Causal Forest sobre NSW con mapas de heterogeneidad.],
  ```python
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from econml.dml import CausalForestDML
from sklearn.ensemble import GradientBoostingRegressor, GradientBoostingClassifier

df = pd.read_csv("../data/datasets/real/public_causaldata/nsw_mixtape/data.csv")
Y = df["re78"].values
D = df["treat"].values
X = df[["age", "educ", "black", "hisp", "marr", "nodegree", "re74", "re75"]].values

cf = CausalForestDML(
    model_y=GradientBoostingRegressor(n_estimators=200, max_depth=4, random_state=42),
    model_t=GradientBoostingClassifier(n_estimators=200, max_depth=4, random_state=42),
    discrete_treatment=True,
    n_estimators=400,
    min_samples_leaf=20,
    max_depth=8,
    cv=5,
    random_state=42,
)
cf.fit(Y, D, X=X)

# ATE
ate = cf.ate(X=X); lb, ub = cf.ate_interval(X=X, alpha=0.05)
print(f"ATE: {ate:.2f}  IC 95%: [{lb:.2f}, {ub:.2f}]")

# CATE
cate = cf.effect(X)
cate_lb, cate_ub = cf.effect_interval(X, alpha=0.05)
# cate_lb y cate_ub pueden usarse para graficar intervalos de confianza
# en mapas de heterogeneidad (no mostrado aquí).

# Mapa de heterogeneidad: CATE vs edad y educacion
fig, axes = plt.subplots(1, 2, figsize=(12, 5))
axes[0].scatter(df["age"], cate, c=cate, cmap="viridis", alpha=0.6)
axes[0].set_xlabel("Edad"); axes[0].set_ylabel("CATE estimado")
axes[0].set_title("Heterogeneidad por edad")
axes[1].scatter(df["educ"], cate, c=cate, cmap="viridis", alpha=0.6)
axes[1].set_xlabel("Educacion"); axes[1].set_ylabel("CATE estimado")
axes[1].set_title("Heterogeneidad por educacion")
plt.tight_layout()
plt.savefig("figuras/cf_heterogeneity_nsw.png", dpi=120, bbox_inches="tight")
plt.show()
```
) <lst-causal-forest-nsw>

=== Comparación con meta-learners
<sec-cap13_comparacion_implementacion>

#figure(
  kind: raw,
  caption: [Causal Forest vs. R-learner en datos sintéticos.],
  ```python
from econml.metalearners import XLearner
# DGP con heterogeneidad estructurada
def make_heterogeneous_dgp(n=2000, seed=0):
    rng = np.random.default_rng(seed)
    X = rng.uniform(-1, 1, (n, 5))
    tau = 2 * X[:, 0] + X[:, 1] * X[:, 2]
    e = 0.5 + 0.3 * np.tanh(X[:, 3])
    D = (rng.uniform(size=n) < e).astype(int)
    Y = X[:, 4] + D * tau + rng.standard_normal(n) * 0.5
    return Y, D, X, tau

Y, D, X, tau_true = make_heterogeneous_dgp(2000, seed=42)
# Causal Forest
cf = CausalForestDML(n_estimators=400, min_samples_leaf=20, random_state=42,
                     model_y=GradientBoostingRegressor(),
                     model_t=GradientBoostingClassifier(),
                     discrete_treatment=True).fit(Y, D, X=X)
tau_cf = cf.effect(X)
# X-learner
xl = XLearner(models=GradientBoostingRegressor(),
              propensity_model=GradientBoostingClassifier()).fit(Y, D, X)
tau_xl = xl.effect(X)

print(f"CF RMSE: {np.sqrt(np.mean((tau_cf - tau_true)**2)):.4f}")
print(f"XL RMSE: {np.sqrt(np.mean((tau_xl - tau_true)**2)):.4f}")
```
) <lst-cf-vs-r>

== Caso empírico y validación
<sec-cap13_caso_empirico>

=== Identificación de subgrupos con #code[feature_importances\_]
<sec-cap13_feature_importance>

#figure(
  kind: raw,
  caption: [Importancia de variables en causal forest.],
  ```python
importances = cf.feature_importances_
features = ["age", "educ", "black", "hisp", "marr", "nodegree", "re74", "re75"]
order = np.argsort(importances)[::-1]
for i in order:
    print(f"{features[i]:>12}: {importances[i]:.4f}")
```
) <lst-cf-importance>

=== Heterogeneidad en efectos del programa NSW
<sec-cap13_nsw>

*Réplica propia sobre el dataset del repositorio.* Hemos aplicado #code[CausalForestDML] al dataset #code[nsw_mixtape] (Lalonde, 1986), $n = 445$ (185 tratados, 260 controles), con 8 controles observables. Los resultados son:

- ATE estimado: \$2,226, IC 95% [\$14, \$4,438].
- CATE: media \$2,226, desv. estándar \$1,035, rango [\$780, \$4,078].
- Variables más importantes (_feature importance_): #code[age] (0.43), #code[educ] (0.24), #code[re75] (0.22), #code[re74] (0.08).

La heterogeneidad estructurada es consistente con la teoría: el CATE promedio por nivel educativo crece de \$1,174 (educ=7) a \$3,515 (educ=14), y los efectos son algo mayores en el cuartil de mayor ingreso previo. La figura @fig-cap13-heterogeneidad visualiza esta heterogeneidad.

#figure(
  image("../figuras/fig_cap13_heterogeneidad.png", width: 100%),
  caption: [Heterogeneidad de CATE estimado por #code[CausalForestDML] sobre #code[nsw_mixtape]. Izquierda: CATE promedio por subgrupo con IC al 95%. Derecha: superficie interpolada de CATE en función de edad y educación. Dataset: #code[nsw_mixtape] (Lalonde, 1986), $n = 445$.],
) <fig-cap13-heterogeneidad>

Sobre el dataset #code[gov_transfers], el Causal Forest revela patrones similares de heterogeneidad estructurada en el efecto de las transferencias sobre consumo. Los efectos son mayores en hogares con menor ingreso basal, lo que coincide con la teoría económica de la _función de consumo Keynesiana_ (mayor propensión marginal a consumir en hogares con menor riqueza).

=== Policy trees y validación de subgrupos
<sec-cap13_policy_trees>

#intuicion[
  *Caja de profundización 6.1: Variable importance y policy trees*

  *Objetivo.* Aprender a interpretar un causal forest más allá del CATE promedio.

  *¿Qué variables explican la heterogeneidad?* El causal forest registra con qué frecuencia cada variable se usa para partir los datos. Las variables más usadas son las que más explican diferencias en el efecto del tratamiento.

  *Policy trees: reglas simples para decidir.* Un policy tree es un árbol de decisión de poca profundidad (2 o 3 niveles) que se entrena sobre los CATE estimados. Produce reglas como:
  - ``Si edad $> 30$ Y educación $> 12$, tratar.''
  - ``Si no, no tratar.''

  #cite(<athey2021policy>, form: "prose") formalizan este objeto: la clase de árboles de profundidad acotada tiene dimensión VC finita, lo que permite acotar el _regret_ de la política aprendida respecto a la mejor política *dentro de esa clase*. El @cap-policy-learning desarrolla el resultado; aquí basta retener que la interpretabilidad del policy tree no es solo una concesión a la comunicación, sino la fuente misma de su garantía estadística — restringir la clase de políticas es lo que evita sobreajustar la regla de decisión al ruido del CATE estimado.

  *Cuidado con buscar subgrupos ``a ojo''.* Si miramos los datos, encontramos subgrupos con efectos grandes aunque no existan (_data mining_). Un policy tree con honestidad y validación cruzada evita este problema.

  *Comparación rápida.*
  - *Causal forest:* detecta heterogeneidad automáticamente, pero es caja negra.
  - *Meta-learners:* más flexibles, pero requieren especificar el modelo de CATE.
  - *Policy tree:* interpretable, pero puede perder heterogeneidad sutil.
]

== Riesgos, límites y sensibilidad
<sec-cap13_riesgos>

=== Tabla de riesgos
<sec-cap13_tabla_riesgos>

La tabla @tab-riesgos-cap06 resume los riesgos principales al usar árboles y bosques causales, junto con sus consecuencias, diagnósticos y estrategias de mitigación.

#riesgos[
  #figure(
    caption: [Riesgos al usar árboles y bosques causales.],
    table(
      columns: (1.4fr, 1.4fr, 1.4fr, 1.8fr),
      align: (left, left, left, left),
      stroke: none,
      table.hline(stroke: 0.8pt),
      table.header([*Riesgo*], [*Consecuencia*], [*Diagnóstico*], [*Mitigación*]),
      table.hline(stroke: 0.4pt),
      [Árbol sin honesty],
      [Sesgo de selección: los CATEs estimados en hojas tienden a ser mayores que los verdaderos],
      [Comparar estimaciones con y sin honesty sobre la misma muestra],
      [Usar la opción #code[honest=true] o #code[inference_mode='stats'] en la implementación. La partición $S_("split") union S_("est")$ debe ser explícita],
      table.hline(stroke: 0.4pt),
      [Data dredging de subgrupos],
      [Falsos descubrimientos: encontrar efectos grandes donde no existen por búsqueda exhaustiva],
      [Pre-registrar los subgrupos de interés antes del análisis; reportar todos los subgrupos evaluados],
      [Validación fuera de muestra con placebos y Qini. Usar policy trees con honestidad y validación cruzada],
      table.hline(stroke: 0.4pt),
      [Múltiples subgrupos],
      [Inflación de errores tipo I al comparar efectos entre muchos subgrupos],
      [Ajustar los valores críticos por el número de comparaciones],
      [Bonferroni o FDR (_False Discovery Rate_). Pre-registrar un número limitado de subgrupos confirmatorios],
      table.hline(stroke: 0.4pt),
      [CATE fuera del soporte común],
      [El CATE no es identificable en regiones sin tratados o sin controles],
      [Reportar $hat(e)(x)$ para cada observación; inspeccionar la distribución del propensity score estimado],
      [Restringir el análisis al soporte común. No extrapolar CATEs a regiones sin solapamiento],
      table.hline(stroke: 0.4pt),
      [Muestra pequeña],
      [Intervalos de confianza demasiado amplios para ser útiles; inestabilidad del árbol],
      [Evaluar el ancho promedio del IC y la sensibilidad a la semilla bootstrap],
      [Agrupar subgrupos, aumentar $n_(min)$ o considerar métodos paramétricos más parsimoniosos],
      table.hline(stroke: 0.8pt),
    )
  ) <tab-riesgos-cap06>
]

=== Límites
<sec-cap13_limites>

Causal Forest asume no confusión. No maneja instrumentos (usar DMLIV). Para efectos dinámicos en el tiempo, requiere extensiones específicas. Para datos de panel con efectos fijos, usar #code[CausalForestDML] con within-transformation (capítulo @cap-panel-dmliv).

== Ejercicios propuestos
<sec-cap13_ejercicios>

+ Replique el listado @lst-causal-forest-nsw variando #code[min_samples_leaf] en ${5, 10, 20, 50}$. ¿Cómo cambia la heterogeneidad estimada?

+ Compare causal forest con R-learner sobre el dataset #code[cps_mixtape]. ¿Qué método identifica más heterogeneidad?

+ Use causal forest para estimar la heterogeneidad del efecto de primera etapa de #code[nearc4] sobre #code[educ] en el dataset #code[close_college]. ¿Qué subgrupos muestran mayor efecto del instrumento sobre la educación? Note que esto no es el CATE de #code[educ] sobre #code[lwage], sino la heterogeneidad en la primera etapa del diseño IV.

+ Implemente un árbol causal honesto ``a mano'' (sin #code[econml]) dividiendo la muestra en $S_("split")$ y $S_("est")$. Compare con la implementación de #code[econml].

== Lecturas complementarias
<sec-cap13_lecturas>

#cite(<athey2016recursive>, form: "prose") es el _paper_ fundacional de árboles causales y del criterio de partición honesto. #cite(<wager2018estimation>, form: "prose") establece la consistencia y la normalidad asintótica puntual de los bosques causales, con la estimación de varianza por _infinitesimal jackknife_ que hace posibles los intervalos de la @sec-cap13_grf. #cite(<athey2019generalized>, form: "prose") generaliza el marco a GRF, reinterpretando el bosque como generador de pesos adaptativos para una ecuación de momento local —la lectura que este capítulo adopta—. #cite(<athey2021policy>, form: "prose") es la referencia de los _policy trees_ mencionados en la caja de profundización y se desarrolla en el @cap-policy-learning. #cite(<oprescu2023econml>, form: "prose") documenta la implementación en #code[econml]; la implementación de referencia en R es el paquete `grf` de los propios autores.
