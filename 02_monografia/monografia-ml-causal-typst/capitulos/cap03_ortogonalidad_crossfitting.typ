// Capítulo 10 — Ortogonalidad de Neyman, cross-fitting e influence functions
// (La numeración `cap03` del nombre de archivo es histórica: proviene de la edición corta anterior y se conserva para no romper referencias.)
#import "../template/template.typ": *

#chapter[Ortogonalidad de Neyman, cross-fitting e influence functions]
<cap-ortogonalidad>

#theorem-number-reset()

#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*Problema:*], [Doble sesgo al estimar $theta_0$ con ML],
    [*Estimando:*], [$theta_0$ en PLR],
    [*Identificación:*], [No confusión, ortogonalidad],
    [*Método:*], [Score ortogonal, cross-fitting],
    [*Nuisance:*], [$g_0(X), m_0(X)$],
    [*Garantía:*], [$sqrt(n) (hat(theta) - theta_0) arrow.r.double N(0, cal(V))$ bajo $sqrt(n) a_n^2 -> 0$],
    [*Librerías:*], [#code[scikit-learn] (implementación manual del score); #code[DoubleML] y #code[econml] en el @cap-dml],
    [*Validación:*], [Monte Carlo de sesgo y cobertura; comparación con y sin cross-fitting],
  )
]

#notatecnica[
Con el criterio de puerta trasera (@cap-intervencion-contrafactual) y la auditoría de _features_ (@cap-features-sin-fuga) resueltos, la Parte I dejó pendiente una pregunta puramente estadística: ¿cómo combinar _learners_ de ML flexibles para estimar un efecto causal sin que el sesgo de esos _learners_ contamine la inferencia? Este capítulo, que abre la Parte II, responde exactamente eso.
]

== Problema causal, estimando e identificación
<sec-cap03_problema>

Una consultora económica está evaluando el efecto de una reforma tributaria sobre la inversión empresarial. Dispone de un panel de $5\,000$ firmas con 200 covariables (características financieras, sectoriales, de propiedad, de gobernanza). La asignación de la reforma no fue aleatoria: las firmas grandes y rentables fueron más propensas a ser tratadas. El estimador ideal debería: (i) usar ML para modelar flexiblemente la relación entre covariables y asignación al tratamiento (_propensity score_), (ii) usar ML para modelar la relación entre covariables e inversión en ausencia de tratamiento (_outcome regression_), (iii) combinar ambas estimaciones para obtener un estimador del efecto causal con inferencia válida.

El problema es que si simplemente "enchufamos" los estimadores de ML en una fórmula causal estándar—por ejemplo, el estimador de doubly-robust $hat(theta) = n^(-1) sum_i [hat(mu)_1(X_i) - hat(mu)_0(X_i) + D_i (Y_i - hat(mu)_1(X_i)) / hat(e)(X_i) - (1 - D_i)(Y_i - hat(mu)_0(X_i)) / (1 - hat(e)(X_i))]$— la inferencia resultante no es válida en general. El motivo es sutil: los errores de estimación de $hat(mu)_d$ y $hat(e)$ _contaminan_ la estimación del efecto causal en el primer orden, introduciendo un sesgo que no desaparece con muestras grandes.

Este capítulo formaliza el problema del _doble sesgo_ y presenta la solución conceptual central del ML causal moderno: la *ortogonalidad de Neyman*. Mostramos que existe una manera de construir un _score_ (función de momento) cuya derivada respecto a los parámetros _nuisance_ es cero en el valor verdadero, de modo que los errores de estimación de los _nuisance_ solo afectan la inferencia causal en el segundo orden. Esta propiedad, combinada con _cross-fitting_ (capítulo @cap-dml), permite construir estimadores $sqrt(n)$-consistentes y asintóticamente normales incluso cuando los _nuisance_ se estiman con ML a tasas más lentas que $sqrt(n)$.

== Teoría, supuestos y garantías
<sec-cap03_teoria>

=== El problema del doble sesgo
<sec-cap03_doble_sesgo>

Consideremos el modelo parcialmente lineal (PLR, _partial linear model_):
$
Y = D theta_0 + g_0(X) + epsilon, quad D = m_0(X) + v,
$ <eq-plr>
Definimos los residuos Robinson: $v_i = D_i - e_0(X_i)$ y $u_i = Y_i - l_0(X_i)$, con $l_0(X_i) = E[Y | X_i]$.

donde $Y$ es el resultado, $D$ es el tratamiento, $X$ son covariables, $g_0$ es la _outcome regression_ y $m_0$ es la _propensity function_ (no necesariamente una probabilidad — puede ser una función continua de $X$). Suponemos $E[epsilon | D, X] = 0$ y $E[v | X] = 0$.

Para $D$ binario, $m_0(x) = e_0(x) = P(D = 1 | X = x)$; en lo que sigue $e_0$ denota el propensity score.

El parámetro causal de interés es $theta_0$, el efecto del tratamiento. La pregunta es cómo estimarlo cuando $g_0$ y $m_0$ son funciones desconocidas de alta dimensión.

==== Enfoque naïve 1: OLS con ML para estimar $g_0$.

Si $g_0$ fuera conocido, $theta_0$ se estimaría por OLS de $Y - g_0(X)$ sobre $D$. Pero como $g_0$ se estima, sustituimos $g_0$ por $hat(g)$ obtenido con algún algoritmo de ML. El estimador resultante es:
$
tilde(theta) = (sum_i D_i^2)^(-1) sum_i D_i (Y_i - hat(g)(X_i)).
$

El problema: $hat(g)(X_i)$ tiene error $O_p(a_n)$ con $a_n >> n^(-1/2)$ en general (bosques aleatorios tienen $a_n = n^(-2/5)$ típicamente). Este error de primer orden contamina $tilde(theta)$:
$
tilde(theta) - theta_0 = underbrace((sum D_i^2)^(-1) sum D_i epsilon_i, "ruido " O_p(n^(-1/2))) + underbrace((sum D_i^2)^(-1) sum D_i (g_0(X_i) - hat(g)(X_i)), "sesgo " O_p(a_n)).
$

Como $a_n >> n^(-1/2)$, el sesgo domina la varianza asintótica y la inferencia basada en la distribución normal es inválida.

==== Enfoque naïve 2: OLS con ML para estimar $m_0$ (residuos de tratamiento).

Si proyectemos $D$ sobre $X$ con ML: $hat(v)_i = D_i - hat(m)(X_i)$, y luego regredimos $Y$ sobre $hat(v)$:
$
tilde(theta)' = (sum hat(v)_i^2)^(-1) sum hat(v)_i Y_i.
$

El mismo problema: el error $hat(m) - m_0$ contamina $tilde(theta)'$ en primer orden.

=== Ortogonalidad de Neyman
<sec-cap03_ortogonalidad_neyman>

La solución es construir un _score_ $psi(W, theta, eta)$, donde $W = (Y, D, X)$ y $eta = (g, m)$ son los _nuisance parameters_, que satisfaga:

#definition(name: [Score ortogonal de Neyman])[
  Un score $psi(W, theta, eta)$ es _ortogonal de Neyman_ respecto a $eta$ en $(theta_0, eta_0)$ si la derivada de Gateaux respecto a $eta$ se anula:
  $
  partial_eta E[psi(W, theta_0, eta)] |_(eta = eta_0) [r] = 0 quad "para toda perturbación " r.
  $ <eq-neyman-orth>
] <def-neyman-orth>

La propiedad de ortogonalidad implica que pequeñas desviaciones de $eta$ respecto a $eta_0$ _no afectan_ el valor esperado del score en primer orden. Esto es lo que permite que errores de estimación de $hat(eta)$ (que son $O_p(a_n)$) solo afecten la estimación de $theta$ en orden $a_n^2$ o $a_n dot.c n^(-1/2)$, preservando así la $sqrt(n)$-consistencia.

=== Construcción del score ortogonal para PLR
<sec-cap03_score_ortogonal>

Para el modelo @eq-plr, el score ortogonal se construye con un truco algebraico. Primero, observemos que $Y - g_0(X) = theta_0 D + epsilon$ y $D - m_0(X) = v$, con $E[epsilon | X] = 0$ y $E[v | X] = 0$. Por la ley de expectativas iteradas, $E[v epsilon] = E[v E[epsilon | X, D]] = 0$ si $E[epsilon | D, X] = 0$ y $E[v | X] = 0$.

Multiplicando $Y - g_0(X) - theta_0 D = epsilon$ por $v = D - m_0(X)$ y tomando esperanza:
$
E[(D - m_0(X))(Y - g_0(X) - theta_0 D)] = E[v epsilon] = 0.
$

De aquí se despeja $theta_0$:
$
theta_0 = frac(E[(D - m_0(X))(Y - g_0(X))], E[(D - m_0(X)) D]).
$ <eq-plr-score>

Es crucial distinguir dos nuisance posibles.

+ Si se estima la regresión estructural
  $
  g_0(X) = E[Y - theta_0 D | X],
  $
  No confundir con $mu_d(x) = E[Y | X = x, D = d]$ de los @cap-prediccion-causalidad, @cap-meta-learners y @cap-causal-forests. Bajo el PLR, $mu_d(x) = g_0(x) + theta_0 d$, de modo que $mu_1(x) - mu_0(x) = theta_0$.
  entonces el score puede escribirse como
  $
  psi(D, X, Y, theta, eta) = (D - m(X))(Y - g(X) - theta D).
  $

+ En la implementación DML estándar, normalmente se estima
  $
  l_0(X) = E[Y | X] = g_0(X) + theta_0 m_0(X),
  $
  junto con
  $
  m_0(X) = E[D | X].
  $
  En ese caso, el score ortogonal correcto es el **score de Robinson** (@robinson1988, Robinson 1988):
  $
  psi(D, X, Y, theta, eta) = (D - m(X)) {Y - l(X) - theta (D - m(X))}.
  $
  #cite(<robinson1988>, form: "prose") introdujo esta transformación —proyectar tanto $Y$ como $D$ sobre $X$ y regresar residuo contra residuo— para el modelo parcialmente lineal con $g_0$ estimado no paramétricamente, y demostró que el estimador resultante es $sqrt(n)$-consistente pese a que las regresiones auxiliares convergen a tasas más lentas. Es el antecedente directo del score PLR de DML: lo que #cite(<chernozhukov2018double>, form: "prose") añaden es el *cross-fitting*, que permite reemplazar los estimadores kernel de Robinson por _learners_ de ML arbitrarios sin pagar el sesgo de sobreajuste que aparecería al estimar y evaluar en la misma muestra. El mismo score reaparecerá en el @cap-meta-learners como la función de pérdida del R-learner —la "R" es, precisamente, por Robinson.

El Listado @lst-dml-manual estima $l_0(X) = E[Y | X]$, por lo que debe usar la segunda forma. Usar $(D - m)(Y - l - theta D)$ cuando $l = E[Y | X]$ no preserva la ortogonalidad de Neyman respecto de $m$.

El score correspondiente es:
$
psi(W_i, theta, eta) = (D - m(X))(Y - g(X) - theta D).
$ <eq-plr-orth-score>

#theorem(name: [Ortogonalidad del score PLR])[
  El score @eq-plr-orth-score es ortogonal de Neyman respecto a $eta = (g, m)$ en $(theta_0, eta_0)$.
] <thm-plr-orth>

#proof[
  La derivada de Gateaux de $E[psi]$ respecto a $eta = (g, m)$ en dirección $(r_g, r_m)$ es
  $
  partial_eta E[psi] [r_g, r_m] &= partial_alpha E[(D - (m_0 + alpha r_m))(Y - (g_0 + alpha r_g) - theta_0 D)] |_(alpha=0) \
  &= -E[r_m epsilon] - E[v r_g] = 0,
  $
  donde hemos usado que $E[epsilon | D, X] = 0$ implica $E[r_m(X) epsilon] = 0$, y que $E[v | X] = 0$ implica $E[v r_g(X)] = 0$.
]

#notatecnica[
  *Forma canónica del score ortogonal.* Todos los scores que el libro deriva en capítulos distintos son instancias de un único objeto: un funcional $psi(W, theta, eta)$ con $E[psi(W, theta_0, eta_0)] = 0$ y derivada de Gateaux nula respecto a $eta$ en $(theta_0, eta_0)$ (Def. de la @sec-cap03_ortogonalidad_neyman). La tabla reúne las instancias del curso:
]

#figure(
  caption: [Instancias del score ortogonal canónico a lo largo del curso.],
  table(
    columns: (1.5fr, 2.6fr, 1fr),
    align: (left, left, left),
    stroke: 0.5pt + gray.lighten(60%),
    table.hline(stroke: 0.8pt),
    table.header([*Estimando*], [*$psi(W, theta, eta)$*], [*$eta$*]),
    table.hline(stroke: 0.4pt),
    [PLR / ATE constante (@cap-dml)], [$(D - m(X))(Y - l(X) - theta (D - m(X)))$], [$(l, m)$],
    [ATE bajo IRM (@cap-dml)], [$mu(1,X) - mu(0,X) + (D(Y - mu(1,X))) / e(X) - ((1-D)(Y - mu(0,X))) / (1 - e(X)) - theta$], [$(mu, e)$],
    [CATE, DR-learner (@cap-meta-learners)], [$Gamma_i$ = score IRM antes de promediar], [$(mu, e)$],
    [CATE, R-learner (@cap-meta-learners)], [$[(Y - m_Y(X)) - tau(X)(D - e(X))]^2$], [$(m_Y, e)$],
    [PLIV (@cap-panel-dmliv)], [$(Z - r(X))(Y - g(X) - theta D)$], [$(g, r, m)$],
    [Policy value (@cap-policy-learning)], [$mu_(pi(X))(X) + (bold(1){D = pi(X)}) / (e_(pi(X))(X)) dot.op (Y - mu_(pi(X))(X)) - V(pi)$], [$(mu, e)$],
    table.hline(stroke: 0.8pt),
  )
) <tab-score-canonico>

*Consecuencia operativa.* El _cross-fitting_, la condición de tasa $sqrt(n) dot.op a_n^2 arrow.r 0$ y el error estándar vía _influence function_ (algoritmo de cross-fitting de la @sec-cap03_crossfitting) son idénticos en todas las filas de la tabla @tab-score-canonico. Cuando el curso presenta un "nuevo" estimador (@cap-dml, @cap-meta-learners, @cap-panel-dmliv, @cap-policy-learning), lo que cambia es $psi$ y el estimando — no el aparato de inferencia. Esta es la perspectiva de funcionales de Riesz que el @cap-deep-causal retoma: el score ortogonal de cada fila es el representador de Riesz de su funcional.

=== Teorema central de DML
<sec-cap03_teorema_dml>

El teorema central de @chernozhukov2018double combina ortogonalidad con _cross-fitting_:

#theorem(name: [DML — versión simplificada])[
  Sea $hat(eta)_0$ un estimador de $eta_0$ obtenido en una muestra auxiliar independiente de la muestra principal, con $norm(hat(eta)_0 - eta_0)_(L^2) = O_p(a_n)$ para algún $a_n -> 0$ con $sqrt(n) a_n^2 -> 0$. Sea $hat(theta)$ solución de
  $
  (1 / n) sum_(i=1)^n psi(W_i, hat(theta), hat(eta)_0) = 0.
  $
  Entonces, bajo regularidad estándar y la condición de ortogonalidad @eq-neyman-orth:
  $
  sqrt(n) (hat(theta) - theta_0) arrow.r^(d) cal(N)(0, sigma^2),
  $
  donde $sigma^2 = E[psi(W, theta_0, eta_0)^2] / (E[partial_theta psi])^2$.
] <thm-dml-main>

#proof(kind: "sketch")[
  **Sketch de prueba (cross-fitting):**  
  El cross-fitting garantiza que los residuos $tilde(D)_i$ y $tilde(Y)_i$ sean independientes de los predictores $hat(m)$ y $hat(l)$ en la muestra donde se evalúan. Esto elimina el sesgo de overfitting de orden $O_p (n^(-1/2))$, permitiendo que la tasa $sqrt(n) dot.op a_n^2 arrow.r 0$ sea suficiente (en lugar de $n dot.op a_n^2 arrow.r 0$ sin cross-fitting). La prueba formal requiere la expansión del influence function con ortogonalidad de Neyman; ver @chernozhukov2018double §3.2. $qed$
]

#intuicion[
  La condición $sqrt(n) a_n^2 -> 0$ es la clave. Para bosques aleatorios, $a_n = n^(-2/5)$, así que $sqrt(n) a_n^2 = n^(1/2 - 4/5) = n^(-3/10) -> 0$. Para LASSO bajo sparsity, $a_n = sqrt(s log p / n)$, así que $sqrt(n) a_n^2 = s log p / sqrt(n) -> 0$ si $s log p = o(sqrt(n))$. La magia de la ortogonalidad es que _no necesitamos_ estimar $eta$ a tasa $sqrt(n)$ — basta una tasa más lenta pero con $a_n^2 = o(n^(-1/2))$.
]

#notatecnica[
  *Condiciones completas y variante DML2.* El Teorema central de DML enunciado arriba está deliberadamente simplificado. Las condiciones completas (@chernozhukov2018double, Teorema 3.1) son:

  + (C1) *Ortogonalidad de Neyman* del score (Def. de la @sec-cap03_ortogonalidad_neyman).
  + (C2) *Identificabilidad local:* $abs(E[partial_theta psi(W, theta, eta_0)]) >= c > 0$ en una vecindad de $theta_0$.
  + (C3) *Tasas de nuisance:* $norm(hat(eta) - eta_0)^2 = o_p(n^(-1/2))$, equivalentemente $sqrt(n) dot.op a_n^2 arrow.r 0$.
  + (C4) *Momentos acotados:* $E[psi^2] < infinity$ y $E[abs(partial_theta psi)^2]$ acotado en una vecindad de $theta_0$.

  Dos decisiones de implementación que la literatura distingue y el curso debe nombrar. Sea $hat(theta)_k$ la solución del score restringida al _fold_ $k$:

  - *DML1* reporta la mediana de ${hat(theta)_k}$; *DML2* reporta el estimador del momento promediado sobre toda la muestra (equivalente al promedio ponderado por tamaño de _fold_). La recomendación de @chernozhukov2018double (§6) es *DML2*, con *repeated cross-fitting*: repetir la partición K-fold $R$ veces ($R = 5$--10) y promediar, reduciendo la varianza inducida por la partición aleatoria. La Figura @fig-cap4-sensibilidad-K —varianza creciente a $K$ bajo— es la manifestación empírica de ese término de varianza; el _repeated cross-fitting_ es su mitigación formal, no solo empírica.
]

#notatecnica[
  La expansión de influence function permite escribir
  $
  hat(theta) - theta_0 = (1/n) sum_i psi(W_i, theta_0, eta_0) + O_p(n^(-1/2)).
  $
]

== Algoritmo e implementación
<sec-cap03_algoritmo>

=== El rol del cross-fitting
<sec-cap03_crossfitting>

El teorema central de DML asume que $hat(eta)$ se estima en una muestra _independiente_ de la muestra principal. En la práctica, no queremos desperdiciar datos. La solución es el _cross-fitting_: dividir la muestra en $K$ _folds_; para cada _fold_ $k$, estimar $hat(eta)_(-k)$ en los otros $K - 1$ _folds_ y evaluar el score en el _fold_ $k$. Esto preserva la independencia entre $hat(eta)$ y los datos sobre los que se evalúa, sin perder datos.

#algorithm("Double Machine Learning con cross-fitting (K-fold)")[
  #kwin[Entrada][Datos ${(Y_i, D_i, X_i)}_(i=1)^n$, score ortogonal $psi$, número de _folds_ $K$, learners para $hat(g), hat(m)$.]
  #kwout[Salida][Estimador $hat(theta)$ y error estándar $hat(sigma)$.]
  Dividir ${1, ..., n}$ en $K$ _folds_ $I_1, ..., I_K$. \
  #for-loop(`k`, 1, `K`)[
    Entrenar $hat(g)_(-k), hat(m)_(-k)$ en ${i : i ∉ I_k}$. \
    Predecir $hat(g)_(-k)(X_i), hat(m)_(-k)(X_i)$ para $i in I_k$.
  ]
  Resolver $hat(theta)$ tal que $(1/n) sum_i psi(W_i, hat(theta), (hat(g)_(-k(i))(X_i), hat(m)_(-k(i))(X_i))) = 0$. \
  Estimar $hat(sigma)^2 = hat(E[psi^2]) / hat(E[partial_theta psi])^2$. \
  #return-stmt[$(hat(theta), hat(sigma) / sqrt(n))$]
] <alg-dml-cf>

#intuicion[
  *Caja de profundización 3.1: Influence functions y por qué importan*

  *Objetivo.* Explicar de forma intuitiva qué son las influence functions y por qué la ortogonalidad permite usar ML para estimar efectos causales.

  *Idea clave.* Una influence function (función de influencia) nos dice cuánto cambiaría nuestro estimado si agregamos o quitamos una observación. Sirve para calcular errores estándar sin bootstrap.

  *Para el PLR:*
  $
  psi_i = v_i (u_i - theta v_i), quad v_i = D_i - hat(m)(X_i), quad u_i = Y_i - hat(l)(X_i)
  $
  El error estándar es $sqrt((1/n) sum_i psi_i^2)$.

  *¿Por qué la ortogonalidad es mágica?* Porque si cometemos errores al estimar $hat(m)$ o $hat(l)$, esos errores NO contaminan el estimado de $theta$ en primer orden. Solo afectan en segundo orden, lo que permite que el ML brille aunque sus predicciones no sean perfectas.
]

=== Pseudocódigo
<sec-cap03_pseudocodigo>

El siguiente algoritmo detalla los pasos concretos de DML manual con cross-fitting para PLR, utilizando el score de Robinson y los residuos del tratamiento y del _outcome_:

#algorithm("DML manual con cross-fitting para PLR")[
  #kwin[Entrada][Datos ${(Y_i, D_i, X_i)}_(i=1)^n$, número de _folds_ $K$, learners para $hat(l), hat(m)$.]
  #kwout[Salida][Estimador $hat(theta)$ y error estándar $hat(sigma)$.]
  Dividir ${1, ..., n}$ en $K$ _folds_ $I_1, ..., I_K$. \
  #for-loop(`k`, 1, `K`)[
    Entrenar $hat(l)_(-k)$ para $E[Y | X]$ en ${i : i ∉ I_k}$. \
    Entrenar $hat(m)_(-k)$ para $E[D | X]$ en ${i : i ∉ I_k}$. \
    Predecir $hat(l)_(-k)(X_i)$, $hat(m)_(-k)(X_i)$ para $i in I_k$.
  ]
  Calcular residuos: $hat(v)_i = D_i - hat(m)_(-k(i))(X_i)$, $hat(u)_i = Y_i - hat(l)_(-k(i))(X_i)$. \
  Estimar $hat(theta) = (sum_i hat(v)_i hat(u)_i) / (sum_i hat(v)_i^2)$. \
  Calcular $hat(sigma)^2 = (1/n) sum_i [hat(v)_i (hat(u)_i - hat(theta) hat(v)_i) / ((1/n) sum_i hat(v)_i^2)]^2$. \
  #return-stmt[$(hat(theta), hat(sigma) / sqrt(n))$]
] <alg-dml-manual-cf>

=== Implementación en Python
<sec-cap03_implementacion>

Implementamos manualmente un score ortogonal para PLR sobre un dataset sintético con confusores de alta dimensión.

#figure(
  kind: raw,
  caption: [Implementación manual de DML para PLR.],
  ```python
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import KFold

def dml_plr_manual(Y, D, X, n_folds=5, learner=None):
    """DML para Partial Linear Model con cross-fitting K-fold.

    Nuisances:
    l_hat(X) = E[Y | X]
    m_hat(X) = E[D | X]

    Score Robinson:
    psi_i = v_i * (u_i - theta * v_i) / E[v_i^2]
    donde v_i = D_i - m_hat(X_i), u_i = Y_i - l_hat(X_i).
    """
    if learner is None:
        learner = lambda: RandomForestRegressor(n_estimators=100,
                                                 min_samples_leaf=20,
                                                 random_state=42)
    n = len(Y)
    l_hat = np.zeros(n)   # regresión de Y sobre X: E[Y|X]
    m_hat = np.zeros(n)   # treatment regression D ~ X
    kf = KFold(n_splits=n_folds, shuffle=True, random_state=42)
    for train_idx, test_idx in kf.split(X):
        # Outcome regression
        m_l = learner().fit(X[train_idx], Y[train_idx])
        l_hat[test_idx] = m_l.predict(X[test_idx])
        # Treatment regression
        m_m = learner().fit(X[train_idx], D[train_idx])
        m_hat[test_idx] = m_m.predict(X[test_idx])
    # Residuos Robinson
    v_hat = D - m_hat          # residuos del tratamiento
    u_hat = Y - l_hat          # residuos del outcome
    # Score Robinson: theta = E[v*u] / E[v^2]
    den = np.mean(v_hat * v_hat)
    theta_hat = np.mean(v_hat * u_hat) / den
    # Influence function
    psi = v_hat * (u_hat - theta_hat * v_hat) / den
    # Error estándar robusto iid
    se = np.sqrt(np.mean(psi ** 2) / n)
    return theta_hat, se

# DGP sintético con confusores de alta dimensión
def make_dgp(n=2000, p=50, theta=2.0, seed=0):
    rng = np.random.default_rng(seed)
    X = rng.standard_normal((n, p))
    # g0(X) = sum de variables no lineal
    g0 = X[:, 0] + 0.5 * X[:, 1]**2 - X[:, 2] * X[:, 3]
    m0 = 0.5 + 0.3 * np.tanh(X[:, 0] + X[:, 4])
    D = m0 + rng.standard_normal(n) * 0.5
    Y = theta * D + g0 + rng.standard_normal(n)
    return Y, D, X

# Monte Carlo
np.random.seed(42)
ests, ses = [], []
for b in range(200):
    Y, D, X = make_dgp(n=2000, p=50, theta=2.0, seed=b)
    th, se = dml_plr_manual(Y, D, X)
    ests.append(th); ses.append(se)
ests = np.array(ests); ses = np.array(ses)
print(f"theta verdadero = 2.0")
print(f"Sesgo: {ests.mean() - 2.0:.4f}")
print(f"Cobertura 95%: {np.mean(np.abs(ests - 2.0) < 1.96*ses):.3f}")
```
) <lst-dml-manual>

El _output_ típico muestra sesgo cercano a cero y cobertura nominal de aproximadamente 0.94–0.96, demostrando la validez de la inferencia.

== Caso empírico y validación
<sec-cap03_caso>

Aplicamos DML-PLR al dataset #code[nsw_mixtape] (Lalonde). El estimando es el efecto del programa de capacitación sobre ingresos en 1978 (#code[re78]). Las covariables son edad, educación, raza, estado civil, diploma, e ingresos previos (#code[re74, re75]).

#figure(
  kind: raw,
  caption: [DML aplicado a NSW Lalonde.],
  ```python
import pandas as pd
from sklearn.ensemble import GradientBoostingRegressor

df = pd.read_csv("../data/datasets/real/public_causaldata/nsw_mixtape/data.csv")
Y = df["re78"].values
D = df["treat"].values
X = df[["age", "educ", "black", "hisp", "marr", "nodegree", "re74", "re75"]].values

theta, se = dml_plr_manual(Y, D, X, learner=lambda: GradientBoostingRegressor(
    n_estimators=200, max_depth=3, random_state=42))
print(f"ATE estimado: {theta:.2f}  (SE: {se:.2f})")
print(f"IC 95%: [{theta - 1.96*se:.2f}, {theta + 1.96*se:.2f}]")
```
) <lst-dml-nsw>

El resultado típico es un ATE de aproximadamente \$1\,600 USD con IC al 95% de [\$800, \$2\,400], consistente con la estimación clásica de @dehejia1999causal por _matching_.

== Riesgos, límites y sensibilidad
<sec-cap03_riesgos>

#figure(
  caption: [Errores comunes en la implementación de DML-PLR.],
  table(
    columns: (1.3fr, 2fr),
    align: (left, left),
    stroke: none,
    table.hline(stroke: 0.8pt),
    table.header(
      [*Riesgo*], [*Descripción*]
    ),
    table.hline(stroke: 0.4pt),
    [Omitir cross-fitting], [Si se estiman $hat(g), hat(m)$ y se evalúa el score en la misma muestra, aparece _overfitting bias_: el score en muestra tiende a subestimar la varianza y los IC son demasiado estrechos.],
    [Usar un único _fold_], [Con $K=1$ (_single sample splitting_) se desperdicia información y la estimación es ineficiente. Se recomienda $K = 4$ o $K = 5$.],
    [Elegir learners sin verificar tasa de convergencia], [El teorema central de DML exige $sqrt(n) a_n^2 -> 0$. Bosques aleatorios con hojas muy pequeñas pueden tener tasa más lenta. Verificar empíricamente con _learning curves_.],
    [Score incorrecto para $l_0$], [Si el nuisance es $l_0(X) = E[Y | X]$, el score PLR ortogonal es $(D - m(X))(Y - l(X) - theta(D - m(X)))$. Mezclar la forma estructural con $g_0$ y la forma condicional con $l_0$ rompe la ortogonalidad respecto de $m(X)$.],
    table.hline(stroke: 0.8pt),
  )
) <tab-riesgos-dml>

*Límites.* El PLR supone que el efecto de $D$ es constante (lineal en $D$). Si el efecto es heterogéneo en $X$, se requiere el modelo interactivo (capítulo @cap-dml). Adicionalmente, la ortogonalidad no resuelve problemas de identificación: si el supuesto de no confusión se vulnera, ningún score ortogonal lo corrige.

== Ejercicios y notas bibliográficas
<sec-cap03_ejercicios>

+ Replique el Monte Carlo del listado @lst-dml-manual comparando: (a) DML con cross-fitting, (b) DML sin cross-fitting (misma muestra para nuisance y score). ¿En cuánto se degrada la cobertura sin cross-fitting?

+ Modifique el DGP para que $g_0$ sea lineal y compare DML con OLS. ¿En qué caso DML es equivalente a OLS?

+ Sobre el dataset #code[close_college], aplique DML-PLR para estimar el retorno a la educación. Use #code[GradientBoostingRegressor] para $hat(g)$ y $hat(m)$. Compare con OLS clásico.

  Construya un DGP donde $hat(g)$ tenga tasa $a_n = n^(-1/4)$ (más lento que $n^(-2/5)$). Verifique empíricamente que la cobertura de DML se degrada. Note que con $a_n = n^(-1/4)$ la condición $sqrt(n) a_n^2 arrow.r 0$ no se satisface y por lo tanto la cobertura de DML debe degradarse.

#cite(<neyman1959>, form: "prose") es la referencia original sobre ortogonalidad —la condición @eq-neyman-orth se conoce como "ortogonalidad de Neyman" por su test $C(alpha)$, construido con la misma idea de insensibilidad de primer orden a parámetros de estorbo—. #cite(<robinson1988>, form: "prose") es la referencia canónica del score de residuo-contra-residuo que este capítulo usa en el modelo parcialmente lineal y que reaparece en los Capítulos 12 (R-learner) y 17 (panel): es la pieza que suele darse por sabida sin citarse, y conviene leerla para ver que la idea de ortogonalización antecede en tres décadas al uso de _machine learning_. #cite(<chernozhukov2018double>, form: "prose") es el _paper_ fundacional de DML y contiene el desarrollo completo de la descomposición (a)–(c) esbozada arriba. #cite(<chernozhukov2016locally>, form: "prose") extiende el marco a estimandos más complejos. #cite(<newey1994asymmetric>, form: "prose") y #cite(<robins1995semiparametric>, form: "prose") son precursores importantes por la vía de la eficiencia semiparamétrica, y #cite(<bickel1993efficient>, form: "prose") es el tratamiento de referencia de esa teoría. Para una revisión pedagógica accesible, @chernozhukov2018applied.
