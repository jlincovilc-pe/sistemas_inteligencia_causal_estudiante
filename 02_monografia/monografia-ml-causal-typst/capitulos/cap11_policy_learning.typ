// Capítulo 11 — Aprendizaje de políticas óptimas (Policy Learning)
#import "../template/template.typ": *

#chapter[Aprendizaje de políticas óptimas]
<cap-policy-learning>

#theorem-number-reset()

#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*[Problema]*], [Aprender una regla de asignación óptima bajo restricciones presupuestarias y de equidad],
    [*[Estimando]*], [Policy value $V(pi)$, welfare regret],
    [*[Identificación]*], [No confusión, SUTVA, soporte común],
    [*[Método]*], [Policy tree, estimación doubly robust del policy value],
    [*[Nuisance]*], [$mu_d(x)$, $e(x)$, CATE $tau(x)$],
    [*[Garantía]*], [Regret $O_p(n^(-1/2))$ bajo VC-dim finita (Athey & Wager, 2021)],
    [*[Librerías]*], [#code[econml.policy]],
    [*[Validación]*], [Hold-out, cross-fitting, DR policy value],
  )
]

#notatecnica[
Con la Parte IV completa —el estimador causal ya se puede publicar y operar en producción (Capítulos 19–20)— este capítulo abre la Parte V y cambia la pregunta: hasta ahora el curso estimó *cuánto* efecto tiene un tratamiento; desde aquí, la pregunta es *a quién* asignarlo, reutilizando el CATE de los meta-learners y bosques causales (Capítulos 12–13) como insumo de una regla de decisión.
]

== Motivación aplicada
<sec-cap11-motivacion>

Un ministerio debe decidir a qué hogares ofrecer un programa de capacitación laboral. El programa es costoso (\$1\,000 por hogar) y solo puede cubrir al 30% de la población. El CATE estimado varía ampliamente: en algunos hogares el efecto sobre ingresos es de \$2\,500; en otros es cercano a cero. La pregunta de política es: _dada una restricción presupuestaria, ¿qué regla de asignación maximiza el bienestar agregado?_

Este es el problema de _policy learning_: encontrar una regla $pi: cal(X) -> {0, 1}$ que maximice el _policy value_ $V(pi) = E[Y(pi(X))]$ sujeto a restricciones presupuestarias o de equidad. @kitagawa2018should y @athey2021policy desarrollaron el marco formal, mostrando que bajo no confusión se puede aprender la política óptima con garantías de _welfare regret_.

Este capítulo desarrolla la teoría del policy learning, presenta la implementación con #code[econml.policy], y discute las extensiones a restricciones presupuestarias y equidad.

== Teoría, supuestos y garantías
<sec-cap11-teoria>

=== Policy value y welfare regret
<sec-cap11-policy-value>

Para una regla $pi$, el policy value es:
$
V(pi) = E[Y(pi(X))] = E[pi(X) mu_1(X) + (1 - pi(X)) mu_0(X)] = E[mu_0(X) + pi(X) tau(X)].
$

La política óptima es:
$
pi^*(x) = bold(1){tau(x) > 0}.
$

El _welfare regret_ mide cuánto pierde una regla $hat(pi)$ respecto a la óptima:
$
"Regret"(hat(pi)) = V(pi^*) - V(hat(pi)) = E[(pi^*(X) - hat(pi)(X)) tau(X)].
$

=== Estimación del policy value
<sec-cap11-estimacion>

Bajo no confusión, $V(pi)$ es identificable a partir de datos observacionales. El estimador _doubly robust_ es:
$
hat(V)(pi) = (1 / n) sum_i [ hat(mu)_(pi(X_i))(X_i) + (bold(1){D_i = pi(X_i)}) / (hat(e)_(pi(X_i))(X_i)) (Y_i - hat(mu)_(pi(X_i))(X_i)) ].
$ <eq-policy-value-dr>

#theorem(name: [Athey & Wager, 2021])[
  Bajo no confusión, soporte común, y tasas apropiadas para $hat(mu), hat(e)$ ($sqrt(n) a_n^2 -> 0$), el estimador @eq-policy-value-dr satisface:
  $
  sqrt(n)(hat(V)(hat(pi)) - V(pi^*)) = O_p(1).
  $
  Si además $hat(pi)$ se elige maximizando $hat(V)$ sobre una clase de políticas con complejidad controlada (VC-dimension finita), el regret es $O_p(n^(-1/2))$.
] <thm-policy-learning>

=== Restricciones presupuestarias
<sec-cap11-restricciones>

Si la restricción es tratar a lo más el 30% de la población, la política óptima es:
$
pi^*_"budget"(x) = bold(1){tau(x) > c},
$
donde $c$ es el cuantil 70% de $tau(X)$ (tratar a los que tienen $tau$ en el top 30%).

#intuicion[
  *Caja de profundización 11.1: Evaluación de políticas con datos históricos*

  *Objetivo.* Aprender a estimar cuánto valdría una política sin tener que implementarla.

  *El problema.* Tenemos una política $pi(x)$ que decide a quién tratar. Queremos saber su valor esperado $V(pi) = E[Y(pi(X))]$, pero solo observamos $Y$ bajo la política original, no bajo la nueva.

  *Tres formas de estimar $V(pi)$ sin implementar la política:*
  - *IPS (Inverse Propensity Scoring):* ponderar cada observación por la probabilidad de haber recibido el tratamiento que la nueva política asignaría. Si la política decide tratar a $i$, pesamos por $1 / e(X_i)$.
  - *SNIPS (Self-Normalized IPS):* igual que IPS pero normalizando los pesos para mayor estabilidad.
  - *DR (Doubly Robust):* combina la predicción directa con IPS. Si el modelo de outcome o el propensity es correcto, el estimador es consistente.

  *Precaución.* Si la nueva política trata a personas muy diferentes a las que fueron tratadas originalmente (poco solapamiento), los estimadores IPS/DR pueden ser inestables. Es como hacer una extrapolación.
]

== Implementación en Python
<sec-cap11-implementacion>

=== Policy learning con econml
<sec-cap11-policy-econml>

#figure(
  kind: raw,
  caption: [Policy learning sobre gov\_transfers con evaluaci\'on hold-out.],
  ```python
import numpy as np
import pandas as pd
from econml.dml import CausalForestDML
from econml.policy import PolicyTree, PolicyForest
from sklearn.ensemble import GradientBoostingRegressor, GradientBoostingClassifier
from sklearn.model_selection import train_test_split

df = pd.read_csv("../data/datasets/real/public_causaldata/gov_transfers/data.csv")
# Identificar columnas
# Asumamos que la variable de tratamiento se llama 'treat' y resultado 'y'
print(df.columns.tolist()[:10])
# Para este ejemplo, simularemos un outcome y tratamiento si no estan claros
rng = np.random.default_rng(42)
n = len(df)
X = df.select_dtypes(include=[np.number]).dropna(axis=1).values[:n]
X = X[:, :10]  # limitar a 10 features
D = rng.binomial(1, 0.5, n)  # tratamiento aleatorio simulado
tau_true = 2 * X[:, 0] + X[:, 1]  # CATE verdadero simulado
Y = X[:, 2] + D * tau_true + rng.standard_normal(n)

# Separar muestra hold-out
X_train, X_test, Y_train, Y_test, D_train, D_test, tau_train, tau_test = train_test_split(
    X, Y, D, tau_true, test_size=0.3, random_state=42
)

# Paso 1: estimar CATE en train
cf = CausalForestDML(
    model_y=GradientBoostingRegressor(n_estimators=200, random_state=42),
    model_t=GradientBoostingClassifier(n_estimators=200, random_state=42),
    discrete_treatment=True,
    n_estimators=400,
    min_samples_leaf=20,
    cv=5,
    random_state=42
).fit(Y_train, D_train, X=X_train)

# Paso 2: aprender politica en train
policy = PolicyTree(max_depth=3, min_samples_leaf=50, random_state=42)
policy.fit(X_train, cf.effect(X_train))

# Paso 3: evaluar la politica en test (hold-out)
pi_test = policy.predict(X_test)

# Evaluacion con ground truth sintetico
welfare_test = tau_test[pi_test == 1].mean() * pi_test.mean()

print(f"Welfare estimado en hold-out: {welfare_test:.4f}")
print(f"Fraccion tratada en hold-out: {pi_test.mean():.3f}")
```
) <lst-policy-learning>

#algorithm("Policy tree con restricción presupuestaria")[
  #kwin[Entrada][Datos $(X_i, hat(tau)_i)_(i=1)^n$, presupuesto $beta in (0, 1)$, profundidad máxima $d_"max"$, tamaño mínimo de hoja $n_"min"$]
  #kwout[Salida][Política $hat(pi): cal(X) -> {0, 1}$ que maximiza el welfare tratando a lo sumo $beta$ de la población]
  Estimar $hat(tau)_i$ mediante Causal Forest o DR-learner con cross-fitting \
  Ordenar $hat(tau)_(1) >= hat(tau)_(2) >= dots >= hat(tau)_(n)$ \
  Fijar umbral $c <- hat(tau)_(ceil(beta n))$ (cuantil $1 - beta$ de los CATEs) \
  Construir árbol de decisión $cal(T)$ con variable objetivo $hat(tau)_i$ y profundidad máxima $d_"max"$ \
  #for-loop(`m`, 1, `M`)[
    $overline(tau)_m <- (1 / |cal(L)_m|) sum_(i in cal(L)_m) hat(tau)_i$ \
    Asignar $hat(pi)(x) <- bold(1){overline(tau)_m > c}$ para todo $x in cal(L)_m$
  ]
  Estimar $hat(V)(hat(pi))$ mediante DR en muestra hold-out \
  #return-stmt[$hat(pi)$.]
] <alg-policy-tree-budget>

=== Restricción presupuestaria
<sec-cap11-budget-python>

#figure(
  kind: raw,
  caption: [Policy learning con restricción presupuestaria.],
  ```python
# Restriccion: tratar maximo al 30% con mayor CATE
cate = cf.effect(X)
threshold = np.quantile(cate, 0.70)  # top 30%
pi_budget = (cate > threshold).astype(int)
welfare_budget = cate[pi_budget == 1].mean() * pi_budget.mean()
print(f"Welfare con restriccion presupuestaria (30%): {welfare_budget:.4f}")
print(f"Welfare de tratar a todos: {cate.mean():.4f}")
print(f"Welfare de no tratar a nadie: 0.0")
```
) <lst-budget-policy>

== Caso empírico y validación
<sec-cap11-caso>

La figura @fig-cap11-policy-value muestra el policy value esperado en función del presupuesto (fracción tratada), comparando tres estrategias: (i) targeting óptimo por CATE (top por $hat(tau)$), (ii) tratamiento aleatorio al mismo presupuesto, y (iii) tratar a todos. La estrategia de targeting domina claramente a las alternativas cuando el presupuesto es escaso, y converge a ``tratar a todos'' cuando el presupuesto es abundante.

#figure(
  image("../figuras/fig_cap11_policy_value.png", width: 85%),
  caption: [Policy value vs. presupuesto de tratamiento. La línea azul es la estrategia óptima (targeting por CATE estimado); la gris punteada es tratamiento aleatorio; la roja punteada es ``tratar a todos''. DGP sintético que simula targeting de transferencias gubernamentales ($n = 5\,000$). Las curvas muestran el policy value esperado al variar la fracción de la población tratada.],
) <fig-cap11-policy-value>

*Interpretación.* Con un presupuesto del 30% de la población, el targeting por CATE obtiene un welfare por individuo aproximadamente 3 veces mayor que el tratamiento aleatorio, y supera a la regla ``tratar a todos'' mientras el CATE medio condicional al top-30% supere al CATE medio poblacional. Sobre el dataset #code[gov_transfers] del repositorio, el policy learning con #code[PolicyTree] produce reglas interpretables basadas en ingreso inicial y composición familiar que dominan a la regla naïve.

== Riesgos, límites y sensibilidad
<sec-cap11-riesgos>

#riesgos[
  #figure(
    caption: [Riesgos comunes en policy learning],
    table(
      columns: (1.4fr, 1.4fr, 1.4fr, 1.8fr),
      align: (left, left, left, left),
      stroke: none,
      table.hline(stroke: 0.8pt),
      table.header([*Riesgo*], [*Consecuencia*], [*Diagnóstico*], [*Mitigación*]),
      table.hline(stroke: 0.4pt),
      [Evaluar in-sample], [Welfare optimista (overfitting)], [Estimar el policy value en hold-out], [Usar cross-fitting y reportar welfare en muestra de evaluación],
      [Ignorar equidad], [Exclusión sistemática de grupos minoritarios], [Auditar la distribución demográfica de los tratados], [Imponer restricciones de paridad demográfica o equalized CATE],
      [CATE mal calibrado], [Política subóptima (umbral de tratamiento incorrecto)], [_Calibration plot_: comparar $hat(tau)(x)$ vs. resultados observados], [Usar DR-learner o Causal Forest con cross-fitting; recalibrar],
      table.hline(stroke: 0.8pt),
    )
  ) <tab-riesgos-cap11>
]

*Límites.* Policy learning requiere no confusión. Si hay variables confusoras no observadas, la política aprendida puede estar sesgada. Adicionalmente, las garantías de regret son asintóticas; con muestras pequeñas, la política aprendida puede estar lejos de la óptima.

== Ejercicios propuestos
<sec-cap11-ejercicios>

+ Replique el listado @lst-policy-learning sobre #code[nsw_mixtape]. ¿Qué regla de política se aprende?

+ Compare tres políticas: (a) tratar a todos, (b) tratar al azar al 30%, (c) tratar al top 30% por CATE estimado. ¿En cuánto mejora el welfare?

+ Construya un DGP donde la política óptima trate solo a un subgrupo pequeño. Verifique que el policy learning lo identifica.

+ Discuta: ¿cómo modificaría el algoritmo para imponer _equalized CATE_ entre dos grupos demográficos?

== Lecturas complementarias
<sec-cap11-lecturas>

@kitagawa2018should y @athey2021policy son las referencias centrales. @zhang2012estimating es un precursor importante. Para restricciones de equidad, @kitagawa2021equality.
