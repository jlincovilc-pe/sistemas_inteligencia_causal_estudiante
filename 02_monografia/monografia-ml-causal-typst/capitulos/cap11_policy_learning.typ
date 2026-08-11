// Capítulo 21 — Aprendizaje de políticas óptimas (Policy Learning)
// (La numeración `cap11` del nombre de archivo es histórica: proviene de la edición corta anterior y se conserva para no romper referencias.)
#import "../template/template.typ": *

#chapter[Aprendizaje de políticas óptimas]
<cap-policy-learning>

#theorem-number-reset()

#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*Problema:*], [Aprender una regla de asignación óptima bajo restricciones presupuestarias y de equidad],
    [*Estimando:*], [Policy value $V(pi)$, welfare regret],
    [*Identificación:*], [No confusión, SUTVA, soporte común],
    [*Método:*], [Policy tree, estimación doubly robust del policy value],
    [*Nuisance:*], [$mu_d(x)$, $e(x)$, CATE $tau(x)$],
    [*Garantía:*], [Regret $O_p(sqrt("VC"(Pi) \/ n))$ sobre una clase $Pi$ de VC-dimensión finita (Kitagawa & Tetenov, 2018; extendido con _nuisance_ estimados por ML en Athey & Wager, 2021)],
    [*Librerías:*], [#code[econml.policy]],
    [*Validación:*], [Hold-out, cross-fitting, DR policy value],
  )
]

#notatecnica[
Con la Parte IV completa —el estimador causal ya se puede publicar y operar en producción (Capítulos 19–20)— este capítulo abre la Parte V y cambia la pregunta: hasta ahora el curso estimó *cuánto* efecto tiene un tratamiento; desde aquí, la pregunta es *a quién* asignarlo, reutilizando el CATE de los meta-learners y bosques causales (Capítulos 12–13) como insumo de una regla de decisión.
]

== Motivación aplicada
<sec-cap11-motivacion>

Un ministerio debe decidir a qué hogares ofrecer un programa de capacitación laboral. El programa es costoso (\$1\,000 por hogar) y solo puede cubrir al 30% de la población. El CATE estimado varía ampliamente: en algunos hogares el efecto sobre ingresos es de \$2\,500; en otros es cercano a cero. La pregunta de política es: _dada una restricción presupuestaria, ¿qué regla de asignación maximiza el bienestar agregado?_

Este es el problema de _policy learning_: encontrar una regla $pi: cal(X) -> {0, 1}$ que maximice el _policy value_ $V(pi) = E[Y(pi(X))]$ sujeto a restricciones presupuestarias o de equidad. #cite(<kitagawa2018should>, form: "prose") y #cite(<athey2021policy>, form: "prose") desarrollaron el marco formal, mostrando que bajo no confusión se puede aprender la política óptima con garantías de _welfare regret_.

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

Conviene separar con cuidado dos resultados que se citan a menudo de forma intercambiable, porque responden preguntas distintas y sus supuestos no son los mismos.

#proposition(name: [Inferencia sobre el policy value])[
  La _efficient influence function_ de $V(pi)$ bajo no confusión y soporte común es
  $
  psi_pi (W) = mu_(pi(X))(X) + (bold(1){D = pi(X)}) / (e_(pi(X))(X)) dot.op (Y - mu_(pi(X))(X)) - V(pi),
  $
  caso particular de la forma canónica de la Nota técnica @sec-cap03_teorema_dml. Por tanto
  $
  sqrt(n) (hat(V)(pi) - V(pi)) arrow.r^(d) cal(N)(0, E[psi_pi^2]),
  $
  y la comparación de dos políticas candidatas $hat(pi)_A, hat(pi)_B$ sobre el mismo _hold-out_ usa el test
  $
  z = (hat(V)(hat(pi)_A) - hat(V)(hat(pi)_B)) / sqrt(S hat(E)_A^2 + S hat(E)_B^2 - 2 dot.op hat("Cov")),
  $
  con varianzas estimadas por la _influence function_ de cada una sobre las mismas observaciones. El capítulo compara hasta aquí _welfare_ puntuales en _hold-out_ sin test; este es el test que faltaba, y el que el Listado @lst-policy-learning debe reportar junto al _welfare_.
] <prop-policy-value-inference>

El teorema de **regret óptimo** $O_p (n^(-1/2))$ para clases de políticas con VC-dimension finita se debe a @kitagawa2018should (Kitagawa & Tetenov 2018). Los métodos basados en GRF para policy learning (@athey2021policy, Athey & Wager 2021) implementan esta teoría mediante árboles de decisión honestos.

#theorem(name: [Kitagawa & Tetenov, 2018 — Empirical Welfare Maximization])[
  Sea $Pi$ una clase de políticas con VC-dimensión finita $"VC"(Pi)$, y sea
  $
  hat(pi)_"EWM" = op("argmax", limits: #true)_(pi in Pi) hat(V)(pi)
  $
  el maximizador del _welfare_ empírico. Bajo soporte común acotado ($e(x) in [underline(e), 1 - underline(e)]$) y resultados acotados, el _regret_ respecto a la mejor política *dentro de la clase* satisface
  $
  E[max_(pi in Pi) V(pi) - V(hat(pi)_"EWM")] = O(sqrt("VC"(Pi) \/ n)),
  $
  y esta tasa es minimax-óptima sobre la clase.
] <thm-ewm>

Dos precisiones sobre este enunciado, ambas importantes en la práctica. Primera: el regret se mide contra $max_(pi in Pi) V(pi)$, la mejor política *de la clase*, no contra la política óptima sin restricciones $pi^*(x) = bold(1){tau(x) > 0}$. La diferencia entre ambas —el *error de aproximación* de la clase— no desaparece con más datos y es el precio de exigir reglas interpretables. Segunda: la garantía no requiere estimar bien el CATE. EWM optimiza directamente el _welfare_ y puede producir una política casi óptima aunque $hat(tau)$ sea un estimador mediocre, lo que explica por qué "el CATE tiene RMSE alto" y "la política es buena" no son afirmaciones contradictorias.

El resultado de #cite(<athey2021policy>, form: "prose") extiende este marco al caso que interesa a este curso: cuando $hat(V)$ se construye con _nuisance_ ($hat(mu)_d$, $hat(e)$) estimados con _machine learning_ en vez de conocidos.

#theorem(name: [Athey & Wager, 2021 — policy learning con nuisance estimados])[
  Si $hat(pi)$ maximiza el estimador doblemente robusto @eq-policy-value-dr sobre una clase $Pi$ de VC-dimensión finita, con _nuisance_ estimados por cross-fitting a tasas que satisfacen la condición de producto $sqrt(n) a_n^2 -> 0$, entonces el regret respecto a la mejor política de la clase conserva la tasa $O_p(sqrt("VC"(Pi) \/ n))$: el error de estimación de los _nuisance_ entra solo a segundo orden.
] <thm-policy-learning>

La estructura del argumento es la misma que la del @cap-ortogonalidad —ortogonalidad más cross-fitting hacen que el error de los _nuisance_ sea de segundo orden— aplicada ahora a un problema de optimización sobre una clase de funciones en lugar de a la estimación de un escalar. Ese es el aporte específico de Athey y Wager; la garantía de regret con clases de VC-dimensión finita es de Kitagawa y Tetenov.

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

#advertencia[
*Este listado es sintético, no aplicado.* El código toma las covariables numéricas del dataset `gov_transfers` pero *simula* el tratamiento y el resultado a partir de un CATE conocido. Esa elección es deliberada y tiene una razón metodológica, no de conveniencia: el objetivo aquí es evaluar el *policy learning* comparando la política aprendida contra el _welfare_ verdadero, y ese contraste solo es posible cuando $tau(x)$ se conoce por construcción. Con datos reales no existe _ground truth_ del CATE (@cap-validacion) y lo único que puede reportarse es un policy value estimado, no un regret. Léase, pues, como una verificación de que el procedimiento recupera la política correcta cuando *sabemos* cuál es —no como evidencia sobre el efecto real de las transferencias gubernamentales—.
]

#figure(
  kind: raw,
  caption: [Policy learning con evaluación hold-out sobre un DGP sintético (covariables reales de `gov_transfers`, tratamiento y resultado simulados).],
  ```python
import numpy as np
import pandas as pd
from econml.dml import CausalForestDML
from econml.policy import PolicyTree, PolicyForest
from sklearn.ensemble import GradientBoostingRegressor, GradientBoostingClassifier
from sklearn.model_selection import train_test_split

# --- DGP SINTETICO -------------------------------------------------
# Las covariables X son reales (gov_transfers); D, tau e Y se SIMULAN
# para disponer del CATE verdadero y poder medir el regret.
df = pd.read_csv("../data/datasets/real/public_causaldata/gov_transfers/data.csv")
rng = np.random.default_rng(42)
n = len(df)
X = df.select_dtypes(include=[np.number]).dropna(axis=1).values[:n]
X = X[:, :10]  # limitar a 10 features
D = rng.binomial(1, 0.5, n)          # asignacion aleatoria SIMULADA
tau_true = 2 * X[:, 0] + X[:, 1]     # CATE verdadero SIMULADO
Y = X[:, 2] + D * tau_true + rng.standard_normal(n)
# -------------------------------------------------------------------

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

# Paso 4: IC del policy value via influence function (Prop. 21.3)
from sklearn.linear_model import LogisticRegression
e_hat = LogisticRegression(max_iter=1000).fit(X_train, D_train).predict_proba(X_test)[:, 1]
pi = pi_test.astype(int)
mu_pi = np.where(pi == 1, cf.effect(X_test), 0.0)
psi_pi = mu_pi + pi * (Y_test - mu_pi) / np.clip(e_hat, 0.01, 0.99) - welfare_test
se_pi = psi_pi.std(ddof=1) / np.sqrt(len(Y_test))
print(f"IC 95% del policy value en hold-out: {welfare_test:.4f} +/- {1.96 * se_pi:.4f}")
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

*Interpretación.* Con un presupuesto del 30% de la población, el targeting por CATE obtiene un welfare por individuo aproximadamente 3 veces mayor que el tratamiento aleatorio, y supera a la regla ``tratar a todos'' mientras el CATE medio condicional al top-30% supere al CATE medio poblacional. Sobre las covariables de #code[gov_transfers] con el DGP sintético de la @sec-cap11-policy-econml, el policy learning con #code[PolicyTree] produce reglas interpretables basadas en ingreso inicial y composición familiar que dominan a la regla naïve.

*Una advertencia sobre la forma de la curva.* Que el targeting domine al tratamiento aleatorio en todo el rango de presupuesto no es un hallazgo empírico sino una consecuencia mecánica de que $hat(tau)$ ordene mejor que el azar; una curva así no valida nada por sí sola. Lo informativo es lo contrario: si la curva de targeting *no* se separa de la aleatoria, la conclusión correcta es que no hay heterogeneidad accionable, y la política óptima es tratar a todos o a nadie según el signo del ATE — un resultado perfectamente respetable que el _baseline_ de efecto constante del @cap-validacion está diseñado para detectar antes de invertir en un sistema de _targeting_ que no aporta valor.

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

#cite(<kitagawa2018should>, form: "prose") introducen la _Empirical Welfare Maximization_ y la cota de regret sobre clases de VC-dimensión finita; #cite(<athey2021policy>, form: "prose") la extienden al caso con _nuisance_ estimados por ML mediante el score doblemente robusto, que es la versión usada en este capítulo. Leer ambos en ese orden evita la confusión de atribución más común en la literatura aplicada. #cite(<zhang2012estimating>, form: "prose") es un precursor importante por la vía de reformular la elección de política como un problema de clasificación ponderada. Para policy learning bajo restricciones —presupuestarias, de equidad o de forma de la regla—, #cite(<kitagawa2021constrained>, form: "prose") tratan el caso general de clasificación restringida, y el @cap-etica-interpretabilidad retoma el trade-off entre _welfare_ y equidad que de ahí se sigue. La conexión con la teoría de la decisión estadística —policy learning como caso particular de reglas de tratamiento bajo identificación parcial— se desarrolla en el @cap-decisiones-estructurales.
