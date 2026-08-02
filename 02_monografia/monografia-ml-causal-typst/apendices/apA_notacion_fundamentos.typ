// Apéndice A — Notación, convenciones y fundamentos matemáticos
#import "../template/template.typ": *

#chapter[Notación, convenciones y fundamentos matemáticos]
<ap-fundamentos>

#theorem-number-reset()

== Notación general
<sec-apA_notacion_general>

A lo largo de esta monografía se emplean las siguientes convenciones notacionales, salvo que se indique explícitamente lo contrario.

#figure(
  caption: [Símbolos y convenciones notacionales.],
  table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    table.hline(stroke: 0.8pt),
    table.header([*Símbolo*], [*Significado*]),
    table.hline(stroke: 0.4pt),
    [$R$], [Conjunto de los números reales],
    [$N$], [Conjunto de los números naturales],
    [$bold(1){dot.c}$], [Función indicadora],
    [$P(dot.c)$], [Medida de probabilidad],
    [$E[dot.c]$], [Esperanza matemática],
    [$"Var"(dot.c)$], [Varianza],
    [$"Cov"(dot.c, dot.c)$], [Covarianza],
    [$bb(P)_n$], [Medida empírica $(1 / n) sum_(i=1)^n delta_(W_i)$],
    [$bb(G)_n$], [Proceso empírico $sqrt(n)(bb(P)_n - P)$],
    [$O_p(dot.c)$, $o_p(dot.c)$], [Órdenes en probabilidad],
    [$O(dot.c)$, $o(dot.c)$], [Órdenes deterministas],
    [$arrow.r^(p)$], [Convergencia en probabilidad],
    [$arrow.r^(d)$], [Convergencia en distribución],
    [$arrow.r^(L^2)$], [Convergencia en media cuadrática],
    [$arrow.r^("a.s.")$], [Convergencia casi segura],
    [$perp perp$], [Independencia],
    [$mid$], [Condicionamiento],
    [$norm(x)_p$], [Norma $p$ de un vector ($norm(x)_2$ euclídea)],
    [$norm(M)_F$], [Norma de Frobenius de una matriz],
    [$norm(M)_*$], [Norma nuclear de una matriz],
    [$nabla$], [Gradiente],
    [$partial$], [Derivada parcial o derivada de Fréchet],
    [$bold(1)_n$], [Vector de unos de longitud $n$],
    [$I_n$], [Matriz identidad de $n times n$],
    [$a_n ≲ b_n$], [$a_n <= C b_n$ para alguna constante $C > 0$],
    [$a_n asymp b_n$], [$a_n ≲ b_n$ y $b_n ≲ a_n$],
    table.hline(stroke: 0.8pt),
  )
) <tab-apA-notacion>

Para variables aleatorias se usan mayúsculas ($X$, $Y$, $D$) y para realizaciones concretas minúsculas ($x$, $y$, $d$). Los vectores y matrices se denotan en negrita ($bold(X)$, $bold(beta)$). La norma $L^2(P)$ de una función $f$ se escribe $norm(f)_(P, 2) = sqrt(integral f^2 dif P)$.

== Modos de convergencia
<sec-apA_modos_convergencia>

#definition(name: [Convergencia en probabilidad])[
  $X_n arrow.r^(p) X$ si para todo $epsilon > 0$, $P(norm(X_n - X) > epsilon) -> 0$.
]

#definition(name: [Convergencia en distribución])[
  $X_n arrow.r^(d) X$ si $F_(X_n)(x) -> F_X(x)$ en todos los puntos de continuidad de $F_X$.
]

#definition(name: [Convergencia en $L^2$])[
  $X_n arrow.r^(L^2) X$ si $E[(X_n - X)^2] -> 0$.
]

La cadena de implicaciones es: $L^2 arrow.r.double p arrow.r.double d$. Las tasas de convergencia se expresan con la notación $O_p$ y $o_p$.

== Teoremas límite fundamentales
<sec-apA_teoremas_limite>

#theorem(name: [Ley débil de los grandes números])[
  Si $X_1, ..., X_n$ son _i.i.d._ con $E norm(X_i) < infinity$, entonces $overline(X)_n arrow.r^(p) E[X]$.
]

#theorem(name: [Teorema central del límite])[
  Si $X_1, ..., X_n$ son _i.i.d._ con $"Var"(X_i) = sigma^2 < infinity$, entonces $sqrt(n)(overline(X)_n - mu) arrow.r^(d) cal(N)(0, sigma^2)$.
]

#theorem(name: [Slutsky])[
  Si $X_n arrow.r^(d) X$ e $Y_n arrow.r^(p) c$, entonces:
  - $X_n + Y_n arrow.r^(d) X + c$,
  - $X_n Y_n arrow.r^(d) c X$,
  - $X_n / Y_n arrow.r^(d) X / c$ si $c != 0$.
]

== Teoría asintótica semiparamétrica
<sec-apA_teoria_asintotica>

=== Espacios tangentes
<sec-apA_espacios_tangentes>

Sea $cal(P)$ una familia de distribuciones parametrizada por $(theta, eta)$, donde $theta in R^d$ es el parámetro de interés y $eta$ es un parámetro _nuisance_ infinito-dimensional. El _espacio tangente_ en $cal(P)_0$ es el _closure_ del espacio generado por los _scores_ de un submodelo paramétrico que pasa por $cal(P)_0$.

#definition(name: [Pathwise derivative])[
  Para un submodelo $t arrow.r P_t$ con $P_0 = P$, el score _pathwise_ es $s = (dif) / (dif t) log p_t mid_(t=0)$. El _efficient influence function_ (EIF) es la proyección del score de $theta$ sobre el espacio tangente.
]

=== Estimación semiparamétrica eficiente
<sec-apA_estimacion_semiparam>

#theorem(name: [Cota de Cramér-Rao semiparamétrica])[
  La varianza asintótica mínima de un estimador regular de $theta$ es $tilde(I)_theta^(-1)$, donde $tilde(I)_theta$ es la _información eficiente_: la varianza del EIF.
] <thm-semiparam-cr>

#theorem(name: [Bickel, Klaassen, Ritov & Wellner, 1993])[
  Bajo regularidad, un estimador $hat(theta)$ es _asintóticamente eficiente_ si y solo si su _influence function_ iguala el EIF.
]

== Ortogonalidad de Neyman
<sec-apA_ortogonalidad>

La ortogonalidad de Neyman (capítulo @cap-ortogonalidad) es una propiedad del _score_ que lo hace insensible en primer orden a errores de estimación de los _nuisance parameters_. Formalmente:

#definition(name: [Score Neyman-ortogonal])[
  Un score $psi(W, theta, eta)$ es Neyman-ortogonal en $(theta_0, eta_0)$ si para toda perturbación $eta - eta_0$ en una vecindad:
  $
  partial_(eta) E[psi(W, theta_0, eta)] mid_(eta = eta_0) [eta - eta_0] = 0.
  $
]

Esta propiedad es la base del teorema central de DML del capítulo @cap-ortogonalidad.

== Cross-fitting y sample splitting
<sec-apA_cross_fitting>

El _cross-fitting_ preserva la independencia entre el estimador de _nuisance_ y el score evaluado en la muestra principal. La idea es dividir la muestra en $K$ _folds_; para cada _fold_, estimar $hat(eta)$ en los $K - 1$ _folds_ restantes y evaluar el score en el _fold_ $k$. Esto evita el _overfitting bias_ sin desperdiciar datos.

== Honesty en árboles causales
<sec-apA_honesty>

La _honesty_ (capítulo @cap-causal-forests) es el análogo para árboles del _cross-fitting_: la muestra usada para decidir las divisiones del árbol es distinta de la usada para estimar el CATE dentro de cada hoja. Sin _honesty_, el árbol selecciona divisiones que maximizan la diferencia observada entre tratados y controles, introduciendo sesgo.

== Norma nuclear y matrix completion
<sec-apA_norma_nuclear>

La _norma nuclear_ de una matriz $L$ es $norm(L)_* = sum_i sigma_i(L)$, donde $sigma_i$ son los valores singulares. Es la envolvente convexa del _rank_, lo que permite formular el problema de _matrix completion_ (capítulo @cap-scm-mc) como optimización convexa.

#theorem(name: [Recht, Fazel & Parrilo, 2010])[
  Bajo _incoherence_ y muestreo aleatorio suficientemente denso, la minimización de norma nuclear recupera exactamente la matriz de bajo rango subyacente.
]

== Modelos causales estructurales
<sec-apA_scm>

Un modelo causal estructural describe cada variable como función de sus causas directas más ruido:
$
X_j = f_j("PA"_j, U_j)
$
donde $"PA"_j$ son los padres causales de $X_j$ y $U_j$ son factores no observados independientes.

*Tres niveles de preguntas causales:*
+ Asociación: $P(Y mid X)$ --- "¿Qué dice la data?"
+ Intervención: $P(Y mid "do"(X = x))$ --- "¿Qué pasa si intervengo?"
+ Contrafactual: $P(Y_x mid X = x', Y = y')$ --- "¿Qué habría pasado si...?"

Para pasar del nivel 1 al 2 se necesitan supuestos de identificación (no confusión, exclusión, etc.). El ML predictivo opera en nivel 1; la evaluación de políticas requiere nivel 2.

== Influence functions
<sec-apA_influence_functions>

La _influence function_ (IF) de un estimador $hat(theta)$ nos dice cómo cambia $hat(theta)$ si modificamos una observación:
$
hat(theta) - theta_0 approx (1 / n) sum_(i=1)^n psi(W_i, theta_0, eta_0)
$

*Ejemplos:*
- *ATE bajo IRM:* $psi_i = mu_1(X_i) - mu_0(X_i) + (D_i (Y_i - mu_1(X_i))) / (e(X_i)) - ((1 - D_i)(Y_i - mu_0(X_i))) / (1 - e(X_i)) - theta$
- *PLR (Robinson):* $psi_i = v_i (u_i - theta v_i)$, con $v_i = D_i - e(X_i)$, $u_i = Y_i - l(X_i)$

La varianza asintótica es $cal(V) = E[psi_i^2]$. La ortogonalidad garantiza que errores en $eta$ no contaminan $theta$ en primer orden.

== Regresión Discontinua (RDD)
<sec-apA_rdd>

Cuando el tratamiento se asigna según un umbral $c$ en una variable continua $X$:
$
tau_"RD" = lim_(x -> c^+) E[Y mid X = x] - lim_(x -> c^-) E[Y mid X = x]
$

Si el cumplimiento es imperfecto (_fuzzy RDD_):
$
tau_"FRD" = (lim_(x -> c^+) E[Y mid X = x] - lim_(x -> c^-) E[Y mid X = x]) / (lim_(x -> c^+) E[D mid X = x] - lim_(x -> c^-) E[D mid X = x])
$
El RDD difuso puede interpretarse como IV local donde el umbral es el instrumento.

== Transportabilidad
<sec-apA_transportabilidad>

Un efecto causal estimado en población $A$ ¿puede aplicarse a población $B$? La respuesta depende de:

- *Covariate shift:* la distribución de $X$ cambia entre $A$ y $B$. Si el efecto es condicional en $X$ y $X$ captura toda la heterogeneidad, puede ser transportable.
- *Target shift:* la relación $Y_x mid X$ cambia entre poblaciones. Se requieren diagramas de selección para decidir.

Un diagrama de selección incluye un nodo $S$ que indica si una observación pertenece a la población fuente o destino. Si $Y perp perp S mid X$, el efecto es directamente transportable.
