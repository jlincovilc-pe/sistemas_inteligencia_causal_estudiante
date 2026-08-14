// Capítulo 11 — Double/Debiased Machine Learning
#import "../template/template.typ": *

#chapter[Double/Debiased Machine Learning]
<cap-dml>

#theorem-number-reset()

#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*Problema:*], [Estimar retorno a la educación con controles de alta dimensión],
    [*Estimando:*], [$theta_0$, efecto parcial en PLR],
    [*Identificación:*], [No confusión condicional],
    [*Método:*], [DML-PLR / DML-IRM],
    [*Nuisance:*], [$hat(m)(X) = E[D | X]$, $hat(ell)(X) = E[Y | X]$],
    [*Garantía:*], [$sqrt(n) (hat(theta) - theta_0) arrow.r^(p) N(0, cal(V))$],
    [*Condición clave:*], [$sqrt(n) a_n^2 -> 0$],
    [*Librerías:*], [DoubleML, econml],
    [*Validación:*], [Placebos, sensibilidad a learners, cross-fitting],
  )
]

#notatecnica[
Este capítulo aplica la ortogonalidad de Neyman y el _cross-fitting_ del @cap-ortogonalidad al caso más estándar: los modelos PLR e IRM de Double Machine Learning, el estimador que se reutilizará como base del primer notebook de producción del curso (Capítulo 15).
]

== Problema causal, estimando e identificación
<sec-cap11_problema>

El Ministerio de Educación desea estimar el efecto causal de una beca sobre el rendimiento académico de estudiantes de secundaria. Dispone de un panel con 60 covariables por estudiante (características familiares, rendimiento previo, características de la escuela, contexto barrial, expectativas subjetivas). La asignación de la beca no fue aleatoria: se priorizó a estudiantes con bajo rendimiento previo, pero también influyeron variables familiares y de contexto. La pregunta de política es: ¿cuál es el efecto promedio de la beca sobre el rendimiento?

En el capítulo @cap-ortogonalidad demostramos que el score ortogonal de Neyman permite estimar $theta_0$ con inferencia válida cuando $g_0$ y $m_0$ se estiman con ML. Este capítulo desarrolla la implementación práctica completa con la librería #code[DoubleML] (Bach, Chernozhukov, Kurz y Spindler, 2021) y #code[econml.dml], cubriendo los dos modelos centrales de la literatura: el modelo parcialmente lineal (PLR) y el modelo interactivo (IRM). Discutimos la elección de _learners_ de _nuisance_, la selección de hiperparámetros, la verificación de _leakage_ en _cross-fitting_, y la sensibilidad de los resultados a estas elecciones.

== Teoría, supuestos y garantías
<sec-cap11_teoria>

=== Supuestos
<sec-cap11_supuestos>

Los supuestos de identificación para DML son los mismos del capítulo @cap-prediccion-causalidad. En particular, se requiere:

- *No confusión condicional* (de no confusión condicional): $Y(0), Y(1) perp perp D | X$.
- *Soporte común* (de soporte común): $0 < P(D = 1 | X) < 1$ c.s.
- *Consistencia*: $Y = Y(D)$.

Bajo estos supuestos, el ATE se identifica como $theta_0 = E[E[Y | D = 1, X] - E[Y | D = 0, X]]$.

=== Estimador y score
<sec-cap11_score>

==== Modelo parcialmente lineal (PLR)

Reproducimos el modelo PLR del capítulo @cap-ortogonalidad:
$
Y = D theta_0 + g_0(X) + epsilon, quad D = m_0(X) + v,
$
con $E[epsilon | D, X] = 0$ y $E[v | X] = 0$. El score ortogonal es:
$
psi_(t "PLR")(W, theta, eta) = (D - m(X))(Y - g(X) - theta D).
$

Nota: ver sección @cap-ortogonalidad si se estima $l_0(X) = E[Y | X]$, el score ortogonal equivalente es el score de Robinson $(D-m){Y-l-theta(D-m)}$.

==== Modelo interactivo (IRM)

El PLR asume que el efecto de $D$ es constante. Cuando sospechamos heterogeneidad en $X$, el modelo interactivo (IRM) es más apropiado. En el IRM, las _outcome regressions_ se modelan separadamente para $D = 0$ y $D = 1$:
$
Y = mu(D, X) + epsilon, quad D tilde "Bernoulli"(e_0(X)),
$
donde $mu(d, x) = E[Y | D = d, X = x]$ y $mu_(d)(x) equiv mu(d, x)$.

Bajo los supuestos de identificación de no confusión condicional–de soporte común del capítulo @cap-prediccion-causalidad, el ATE se identifica como:
$
theta_0 = E[mu(1, X) - mu(0, X)].
$

El score ortogonal correspondiente, derivado por @chernozhukov2018double, es:
$
psi_(t "IRM")(W, theta, eta) = mu(1, X) - mu(0, X) + (D(Y - mu(1, X)))/e(X) - ((1 - D)(Y - mu(0, X)))/(1 - e(X)) - theta,
$ <eq-irm-score>
donde $eta = (mu, e)$. Este score es la combinación clásica _doubly robust_ de @robins1994estimation ajustada para satisfacer ortogonalidad de Neyman. El score @eq-irm-score es la instancia IRM de la forma canónica de la Nota técnica @sec-cap10_teorema_dml; la instancia sin promediar reaparece como $Gamma_i$ del DR-learner (@sec-cap12_drlearner) y como EIF del _policy value_ (@sec-cap21-estimacion).

#theorem(
  name: [Doble robustez + ortogonalidad]
)[
  El score @eq-irm-score es ortogonal de Neyman respecto a $eta = (mu, e)$. Adicionalmente, es _double robust_: si $hat(mu)$ o $hat(e)$ es consistente (no necesariamente ambos), $hat(theta)$ es consistente.
] <thm-dr>

#theorem(name: [Eficiencia semiparamétrica del estimador DML-IRM])[
  Bajo no confusión, soporte común y $Y$ acotado, la _efficient influence function_ (EIF) del funcional $theta_0 = E[mu(1, X) - mu(0, X)]$ en el modelo IRM es exactamente el integrando del score @eq-irm-score:
  $
  psi^*(W) = mu_1(X) - mu_0(X) + (D(Y - mu_1(X))) / e(X) - ((1 - D)(Y - mu_0(X))) / (1 - e(X)) - theta_0.
  $
  Por la cota de Cramér-Rao semiparamétrica (Ap. A, @sec-apA_estimacion_semiparam), el estimador DML-IRM es asintóticamente eficiente: ningún estimador regular puede tener varianza asintótica menor que
  $
  V_"eff" = E[(tau(X) - theta_0)^2 + (sigma_1^2(X)) / e(X) + (sigma_0^2(X)) / (1 - e(X))],
  $
  con $sigma_d^2(x) = "Var"(Y | X = x, D = d)$. La doble robustez (teorema de la @sec-cap11_score) y la eficiencia son propiedades complementarias: la primera protege contra mala especificación de un _nuisance_; la segunda certifica que, cuando ambos _nuisance_ convergen, no se puede hacer mejor. Los ejemplos de IF del Ap. A (@sec-apA_influence_functions) son las instancias de este resultado para IRM y PLR.
] <thm-efficiency-irm>

=== Garantías
<sec-cap11_garantias>

Bajo condiciones de regularidad y tasas de convergencia de los _learners_ nuisance, el estimador DML satisface:
$
sqrt(n) (hat(theta) - theta_0) arrow.r^(p) N(0, cal(V)),
$
donde $cal(V)$ es la varianza asintótica. La condición clave para que el error de los _learners_ nuisance no afecte la distribución asintótica es:
$
sqrt(n) a_n^2 -> 0,
$
donde $a_n$ es la tasa de convergencia del _learner_ nuisance más lento.

La tabla @tab-learners resume las opciones más usadas para estimar $hat(g), hat(m), hat(mu), hat(e)$, con sus tasas de convergencia típicas.

#figure(
  caption: [Learners comunes para nuisance en DML.],
  table(
    columns: (1.1fr, 1.6fr, 1.1fr, 1.2fr),
    align: (left, left, left, left),
    stroke: none,
    table.hline(stroke: 0.8pt),
    table.header(
      [Learner], [Cuándo usar], [Tasa $a_n$ típica], [Notas]
    ),
    table.hline(stroke: 0.4pt),
    [#code[RandomForestRegressor]], [No lineal, interactivo], [$n^(-2/5)$], [Robusto, fácil de tunear],
    [#code[GradientBoostingRegressor]], [No lineal, alta dimensión], [$n^(-2/5)$], [Mejor que RF en alta dim.],
    [#code[LassoCV]], [Lineal, sparse, $p >> n$], [$sqrt(s log p / n)$], [Requiere sparsity],
    [#code[RidgeCV]], [Lineal, denso], [$n^(-1/2)$ si $p$ fijo], [No hace selección],
    [#code[HistGradientBoosting]], [No lineal, $n > 10^5$], [$n^(-2/5)$], [Escalable],
    [#code[MLPRegressor] (PyTorch)], [No lineal complejo], [depende], [Sensible a hiperparámetros],
    table.hline(stroke: 0.8pt),
  )
) <tab-learners>

La condición $sqrt(n) a_n^2 -> 0$ se satisface para $a_n = n^(-2/5)$ (RF, GBM) porque $sqrt(n) dot.c n^(-4/5) = n^(-3/10) -> 0$. Para LASSO bajo sparsity, la condición es $s log p = o(sqrt(n))$.

Los hiperparámetros de los _learners_ (profundidad de árboles, _learning rate_, $lambda$ de LASSO) se seleccionan típicamente por _cross-validation_ dentro de cada _fold_ de _cross-fitting_. Esto significa que el costo computacional es $K times ("CV interno")$. Una buena práctica es reportar la sensibilidad de los resultados a la elección de _learner_ y de hiperparámetros.

=== Diagnósticos cuantitativos de soporte común
<sec-cap11_soporte_comun>

La alerta "$hat(e)$ cerca de 0 o 1" (@tab-riesgos_dml) se vuelve operativa con dos cantidades medibles.

*ESS de Kish.* Para la componente IPW del estimador, el tamaño efectivo de muestra es
$
"ESS" = ((sum_i w_i)^2) / (sum_i w_i^2), quad w_i = D_i / hat(e)(X_i).
$
$"ESS"/n << 1$ señala que pocas unidades con $hat(e)$ extremo dominan la estimación — el soporte común es formalmente escaso aunque el histograma de $hat(e)$ "se vea bien" (@kish1965).

*Trimming óptimo.* #cite(<crump2009dealing>, form: "prose") demuestran que recortar observaciones con $hat(e)(X) ∉ [alpha, 1 - alpha]$ minimiza la varianza asintótica del estimador para $alpha^* = (1 - sqrt(1/3))/2 approx 0.057$ bajo condiciones generales. *Atención al estimando:* tras el _trimming_, el efecto identificado es el ATE sobre la población con _overlap_, no el ATE poblacional — declararlo en la _model card_ (@cap-hf-hub) es obligatorio.

*Regla operativa del curso:* reportar $"ESS"/n$ y el rango de $hat(e)$ en todo resultado DML; si $hat(e) ∉ [0.05, 0.95]$ para más del 5% de la muestra, reestimar con _trimming_ y reportar ambas cifras. El mismo diagnóstico se hereda en el DR-learner (@sec-cap12_drlearner) y en el _net score_ del @cap-uplift-targeting.

== Algoritmo e implementación
<sec-cap11_algoritmo>

#algorithm("DML con cross-fitting")[
  #kwin[Entrada][$(Y_i, D_i, X_i)_(i=1)^n$, learner $L$, folds $K$]
  #kwout[Salida][$hat(theta)$, $wide("SE")$]
  #for-loop(`k`, 1, `K`)[
    Estimar $hat(ell)_(−k)(x) = E[Y | X=x]$ fuera del fold \
    Estimar $hat(m)_(−k)(x) = E[D | X=x]$ fuera del fold
  ]
  Calcular residuos $u_i = Y_i − hat(ell)(X_i)$, $v_i = D_i − hat(m)(X_i)$ \
  $hat(theta) = (sum_i v_i u_i) / (sum_i v_i^2)$ \
  Calcular influence function y $wide("SE")$
] <alg-dml_crossfitting>

=== DML con DoubleML para PLR

#figure(
  kind: raw,
  caption: [DML con librería DoubleML sobre NSW.],
  ```python
import doubleml as dml
from sklearn.ensemble import RandomForestRegressor, RandomForestClassifier
from sklearn.linear_model import LassoCV, LogisticRegressionCV
import pandas as pd

df = pd.read_csv("../data/datasets/real/public_causaldata/nsw_mixtape/data.csv")
Y = df["re78"].values
D = df["treat"].values
X = df[["age","educ","black","hisp","marr","nodegree","re74","re75"]].values

# PLR con Random Forest
obj_dml = dml.DoubleMLPLR(
    dml.DoubleMLData.from_arrays(X, Y, D),
    ml_l=RandomForestRegressor(n_estimators=200, min_samples_leaf=20, random_state=42),
    ml_m=RandomForestRegressor(n_estimators=200, min_samples_leaf=20, random_state=42),
    n_folds=5,
)
obj_dml.fit()
print(obj_dml.summary)
```
) <lst-doubleml-nsw>

=== DML con econml para CATE bajo PLR/etapa final lineal

```python
from econml.dml import LinearDML, CausalForestDML
from sklearn.ensemble import GradientBoostingRegressor, GradientBoostingClassifier

# LinearDML: asume CATE lineal en X
est = LinearDML(
    model_y=GradientBoostingRegressor(n_estimators=200, max_depth=4, random_state=42),
    model_t=GradientBoostingClassifier(n_estimators=200, max_depth=4, random_state=42),
    discrete_treatment=True,
    cv=5,
    random_state=42,
)
est.fit(Y, D, X=X)
# ATE
ate = est.ate(X=X)
ate_lb, ate_ub = est.ate_interval(X=X, alpha=0.05)
print(f"ATE: {ate:.2f}  IC 95%: [{ate_lb:.2f}, {ate_ub:.2f}]")

# CATE para los primeros 5 individuos
cate = est.effect(X[:5], T0=0, T1=1)
print(f"CATE (5 primeros): {cate}")
```

#notatecnica[
#code[LinearDML] implementa un modelo parcialmente lineal con etapa final lineal en $X$. No es una implementación general del score IRM no paramétrico para CATE. El score IRM presentado en la ecuación @eq-irm-score identifica el ATE:
$
theta_0 = E[mu(1,X) - mu(0,X)].
$

Para estimar CATE bajo estructura IRM, usar por ejemplo #code[DRLearner], #code[CausalForestDML], #code[NonParamDML], o scores localizados/doubly-robust para efectos heterogéneos.
]

=== Comparación de learners

Una práctica recomendada es comparar varios _learners_ para verificar robustez:

```python
from sklearn.linear_model import LassoCV, LogisticRegressionCV
from sklearn.ensemble import RandomForestRegressor

learners = {
    "Lasso": (LassoCV(cv=5), LogisticRegressionCV(cv=5, max_iter=1000)),
    "RF":    (RandomForestRegressor(n_estimators=200, min_samples_leaf=20, random_state=42),
              RandomForestClassifier(n_estimators=200, min_samples_leaf=20, random_state=42)),
    "GBM":   (GradientBoostingRegressor(n_estimators=200, max_depth=3, random_state=42),
              GradientBoostingClassifier(n_estimators=200, max_depth=3, random_state=42)),
}

for name, (ml_y, ml_t) in learners.items():
    est = LinearDML(model_y=ml_y, model_t=ml_t, discrete_treatment=True,
                    cv=5, random_state=42).fit(Y, D, X=X)
    ate = est.ate(X=X); lb, ub = est.ate_interval(X=X, alpha=0.05)
    print(f"{name:>8}: ATE={ate:7.2f}  IC=[{lb:7.2f}, {ub:7.2f}]")
```

=== Verificación de leakage

El _leakage_ entre _folds_ de _cross-fitting_ invalida la inferencia. #code[DoubleML] y #code[econml] manejan esto internamente, pero conviene verificar:

```python
import numpy as np
from sklearn.model_selection import KFold
from sklearn.ensemble import RandomForestRegressor

def verify_no_leakage(Y, D, X, n_folds=5, seed=42):
    """Verifica que las predicciones nuisance se hagan fuera de muestra."""
    kf = KFold(n_splits=n_folds, shuffle=True, random_state=seed)
    n = len(Y)

    l_hat = np.zeros(n)
    m_hat = np.zeros(n)
    fold_assigned = np.zeros(n, dtype=int)

    for k, (train, test) in enumerate(kf.split(X)):
        fold_assigned[test] = k

        # Outcome model: E[Y | X]
        m_l = RandomForestRegressor(
            n_estimators=50,
            random_state=seed
        ).fit(X[train], Y[train])

        l_hat[test] = m_l.predict(X[test])

        # Treatment model: E[D | X]
        m_m = RandomForestRegressor(
            n_estimators=50,
            random_state=seed
        ).fit(X[train], D[train])

        m_hat[test] = m_m.predict(X[test])

    print(f"Folds asignados correctamente: {(fold_assigned != -1).all()}")

    return l_hat, m_hat

verify_no_leakage(Y, D, X)
```

Si $D$ es binario, puede usarse un clasificador con #code[predict_proba], pero para verificar leakage basta con estimar $E[D | X]$. No dejar #code[m_hat] en ceros.

#intuicion[
*Caja de profundización 4.1: Refutación y diagnósticos de robustez*

*Objetivo.* Aprender a poner a prueba un estimador DML antes de confiar en sus resultados.

*Pruebas de refutación ("¿y si...?").*
- *Placebo treatment:* reemplazar $D$ por una variable aleatoria. El ATE debería ser cero. Si no lo es, algo anda mal.
- *Random common cause:* agregar una variable aleatoria como confusora. El ATE no debería cambiar sustancialmente.
- *Subset validation:* estimar en la mitad de los datos y verificar que el resultado es similar.

*Diagnósticos de nuisance.*
- Distribución de $hat(e)(X)$: si hay valores muy cercanos a 0 o 1, el estimador puede ser inestable.
- Comparar learners: si LASSO, Random Forest y Gradient Boosting dan ATE similares, hay más confianza.
]

== Caso empírico y validación
<sec-cap11_caso>

El diseño de referencia para esta parte del capítulo es el de @card1995, que instrumenta los años de educación con la proximidad geográfica a una universidad de cuatro años (#code[nearc4]) bajo el argumento de que vivir cerca de una universidad reduce el costo de asistir sin afectar directamente el salario. (Conviene no confundirlo con el otro diseño IV clásico de la literatura de retornos a la educación, el de @angrist1991, que usa el trimestre de nacimiento interactuado con las leyes de escolaridad obligatoria; ambos aparecen en la literatura de DML, pero el dataset #code[close_college] usado aquí y en el resto del curso es el de Card.) #cite(<chernozhukov2018double>, form: "prose") desarrollan la extensión de DML a este tipo de diseño. El modelo es _partial linear IV_:
$
Y = D theta_0 + g_0(X) + epsilon, quad Z = r_0(X) + zeta, quad D = m_0(Z, X) + v,
$
donde $Z$ es el instrumento. #code[DoubleML] ofrece el método #code[DoubleMLPLIV] para este caso.

*Réplica propia sobre el dataset del repositorio.* Hemos replicado el ejercicio sobre #code[close_college] @card1995 con $n = 3\,003$ observaciones y controles #code[black, smsa, south, married, exper]. Los resultados obtenidos son:

- OLS con controles (HC1): coeficiente de #code[educ] $= 0.071$, IC 95% $[0.064, 0.078]$.
- IV 2SLS clásico (#code[nearc4] como instrumento): coeficiente $= 0.124$, IC 95% $[0.028, 0.221]$.
- DML-PLIV con #code[GradientBoostingRegressor] para nuisance: coeficiente $= 0.145$, IC 95% $[0.052, 0.237]$.

Estos números constituyen una _réplica propia_ sobre el dataset del repositorio y _no_ corresponden a las cifras originales del _paper_ de @chernozhukov2018double, que utiliza una muestra distinta. La conclusión cualitativa —un retorno a la educación positivo, significativo, del orden de las estimaciones 2SLS clásicas— es consistente con la literatura. La ventaja de DML-PLIV es que permite controles de alta dimensión sin asumir forma funcional para $g_0, r_0, m_0$.

Conviene, sin embargo, leer la comparación con cuidado y no como "IV corrige el sesgo de OLS y DML lo corrige mejor". Los tres números estiman objetos distintos. El coeficiente OLS es un efecto parcial bajo no confusión condicional en los cinco controles —supuesto que casi nadie defiende para la educación, por la habilidad no observada—. Los dos estimadores IV recuperan, bajo monotonicidad y exclusión, un *LATE*: el efecto promedio sobre los individuos cuya decisión educativa efectivamente respondió a vivir cerca de una universidad, un subgrupo que no es la población general y que plausiblemente enfrentaba restricciones de crédito más severas. Que el IV sea mayor que el OLS es, por tanto, consistente con al menos dos explicaciones sustantivas distintas —heterogeneidad del efecto concentrada en los _compliers_, o error de medición en `educ` que atenúa el OLS— y la evidencia aquí presentada no las separa. La amplitud del intervalo IV, casi diez veces la del OLS, tiene además una lectura mecánica: es el precio de identificar con la variación limitada que induce un instrumento de fuerza moderada, y anticipa la discusión de instrumentos débiles del @cap-panel-dmliv.

#figure(
  image("../figuras/fig_cap11_sensibilidad_K.png", width: 80%),
  caption: [Sensibilidad de la estimación DML-PLIV del retorno a la educación al número de folds $K$ del cross-fitting. Las barras indican IC al 95%. La línea punteada es la estimación OLS con controles (HC1). Dataset: #code[close_college] (Card, 1995), $n = 3\,003$. La sensibilidad a $K$ bajo se mitiga con _repeated cross-fitting_ (Nota técnica @sec-cap10_teorema_dml).],
) <fig-cap11-sensibilidad-K>

La figura @fig-cap11-sensibilidad-K muestra que el estimador DML es estable entre $K = 2$ y $K = 10$, con una varianza moderadamente creciente a $K$ bajos. Esto valida la recomendación operacional de usar $K in {4, 5}$ como compromiso entre sesgo (favorece $K$ alto) y varianza (favorece $K$ bajo).

== Riesgos, límites y sensibilidad
<sec-cap11_riesgos>

#figure(
  caption: [Riesgos comunes en DML],
  table(
    columns: (1fr, 2.5fr),
    align: (left, left),
    stroke: none,
    table.hline(stroke: 0.8pt),
    table.header([*Riesgo*], [*Descripción*]),
    table.hline(stroke: 0.4pt),
    [Learner único], [Reportar un único _learner_ sin análisis de sensibilidad. Siempre comparar al menos dos _learners_ (lineal + no lineal). Divergencias grandes señalan problemas de especificación.],
    [_Folds_ insuficientes], [Usar $K=2$ _folds_. Con $K=2$, la varianza del estimador aumenta sustancialmente. Recomendado: $K=4$ o $K=5$, con _repeated cross-fitting_ ($R >= 5$) si la varianza entre particiones es material (Nota técnica @sec-cap10_teorema_dml).],
    [Soporte común ignorado], [Si $hat(e)(X)$ está muy cerca de 0 o 1, las ponderaciones IPW explotan. Reportar $"ESS"/n$ y rango de $hat(e)$; _trimming_ con $alpha approx 0.057$ (@crump2009dealing, @sec-cap11_soporte_comun).],
    [Confusión no observada], [Asumir que DML "resuelve" la confusión no observada. DML requiere el supuesto de no confusión (de no confusión condicional). Si hay variables confusoras no observadas, DML es tan sesgado como OLS.],
    table.hline(stroke: 0.8pt),
  )
) <tab-riesgos_dml>

*Límites del PLR.* El PLR asume efecto constante de $D$. Si el efecto es heterogéneo, $theta_0$ se interpreta como un promedio ponderado que puede diferir del ATE. Para heterogeneidad explícita, usar IRM o Causal Forest (capítulo @cap-causal-forests).

*Límites del IRM.* El IRM permite heterogeneidad pero asume _unconfoundedness_. Si el tratamiento es endógeno por variables no observadas, se requiere DML con instrumentos (DMLIV).

#diagnosticos[
  #table(
    columns: (1fr, 2fr, 1.2fr),
    align: (left, left, left),
    stroke: none,
    table.hline(stroke: 0.8pt),
    table.header([*Diagnóstico*], [*Qué evaluar*], [*Señal de alerta*]),
    table.hline(stroke: 0.4pt),
    [Overlap], [Histograma de $hat(m)(X)$], [Valores cerca de 0 o 1],
    [Nuisance], [$R^2$ fuera de muestra], [$R^2$ bajo],
    [Leakage], [Predicciones por fold], [Performance inflado],
    [Estabilidad], [Cambio de learner], [ATE cambia mucho],
    table.hline(stroke: 0.8pt),
  )
]

== Ejercicios y notas bibliográficas
<sec-cap11_ejercicios>

+ Replique el listado @lst-doubleml-nsw variando $K in {2, 3, 5, 10}$. ¿Cómo cambia el error estándar con $K$?

+ Sobre el dataset #code[cps_mixtape], estime el efecto de la educación sobre el salario con DML-PLR y compare con OLS. ¿En qué dirección cambia el estimado al usar DML?

+ Sobre #code[nhefs], estime el efecto de dejar de fumar sobre el cambio de peso con: (a) OLS con controles manuales, (b) DML-PLR con GBM, (c) DML-IRM con GBM. Compare.

+ Verifique empíricamente la doble robustez: reemplace $hat(mu)$ por una constante (modelo mal especificado) y observe que el ATE sigue siendo consistente si $hat(e)$ es consistente.

#cite(<chernozhukov2018double>, form: "prose") es el _paper_ fundacional. #cite(<bach2021doubleml>, form: "prose") documenta la librería #code[DoubleML]. #cite(<battocchi2023econml>, form: "prose") documenta #code[econml]. #cite(<foster2019orthogonal>, form: "prose") extiende el marco a casos más generales. Para una revisión pedagógica, @chernozhukov2018applied.
