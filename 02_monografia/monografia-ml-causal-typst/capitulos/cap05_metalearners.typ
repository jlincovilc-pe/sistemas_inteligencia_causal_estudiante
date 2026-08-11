// Capítulo 12 — Meta-learners para efectos de tratamiento heterogéneos
// (La numeración `cap05` del nombre de archivo es histórica: proviene de la edición corta anterior y se conserva para no romper referencias.)
#import "../template/template.typ": *

#chapter[Meta-learners para efectos de tratamiento heterogéneos]
<cap-meta-learners>

#theorem-number-reset()

// Alias de etiqueta preservado del original LaTeX (\label{cap:metalearners})
#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*Problema:*], [Estimar CATE sin asumir forma funcional],
    [*Estimando:*], [$tau(x) = E[Y(1) - Y(0) | X = x]$],
    [*Identificación:*], [No confusión, soporte común, SUTVA],
    [*Método:*], [S-learner, T-learner, X-learner, R-learner, DR-learner],
    [*Nuisance:*], [$mu_1(x), mu_0(x), e(x)$],
    [*Garantía:*], [Cuasi-oracle (R-learner); tasa oracle bajo producto de tasas (DR-learner); bootstrap (T, X)],
    [*Condición clave:*], [Ortogonalidad + cross-fitting (R-learner)],
    [*Librerías:*], [causalml, econml],
    [*Validación:*], [Calibración de CATE, placebos, Qini],
  )
]

#notatecnica[
El @cap-dml estimó un efecto promedio (ATE); este capítulo da el primer paso hacia la heterogeneidad, estimando el efecto condicional $tau(x) = E[Y(1)-Y(0) | X=x]$ mediante cuatro estrategias de meta-aprendizaje que reutilizan directamente los _learners_ ya vistos.
]

== Problema causal, estimando e identificación
<sec-cap05_problema>

Una organización no gubernamental debe decidir a cuál de dos variantes de un programa de microcrédito ofrecer a cada cliente. La variante A tiene tasas de interés más bajas pero requiere reuniones grupales semanales; la variante B tiene tasas más altas pero es individual. El efecto sobre el repago difiere según características del cliente (experiencia previa, red social, sector económico). La pregunta de política no es ``¿cuál es el efecto promedio de A vs B?'', sino ``¿a qué clientes conviene asignar A y a cuáles B?''.

Para responder a esta pregunta se necesita estimar el _CATE_ $tau(x) = E[Y(1) - Y(0) | X = x]$ como función de $X$, no solo el ATE. Los _meta-learners_—S-learner, T-learner, X-learner, R-learner— son estrategias para construir un estimador de $tau(x)$ a partir de cualquier algoritmo supervisado de ML. Fueron formalizados por @kunzel2019metalearners (S, T, X) y @nie2021quasi (R-learner).

Este capítulo presenta los cuatro _meta-learners_, sus propiedades estadísticas (sesgo, varianza, tasa de convergencia), y una comparación empírica sobre un dataset sintético con CATE conocido. Mostramos que ningún _meta-learner_ es uniformemente dominante: el S-learner sufre de _regularization bias_, el T-learner sufre de alta varianza cuando un grupo es pequeño, el X-learner mitiga ambos pero requiere estimación de propensity score, y el R-learner es asintóticamente eficiente pero requiere optimización global.

== Teoría, supuestos y garantías
<sec-cap05_teoria>

=== El S-learner
<sec-cap05_slearner>

El S-learner (_single-learner_) entrena un único modelo predictivo $hat(mu)(D, X)$ que toma $D$ como una covariable más. La estimación del CATE es:
$
hat(tau)_S(x) = hat(mu)(1, x) - hat(mu)(0, x).
$

*Ventajas.* Usa toda la muestra para entrenar; aprovecha cualquier algoritmo supervisado.

*Problema.* El algoritmo puede _ignorar_ $D$ si $D$ tiene poco poder predictivo sobre $Y$ comparado con $X$, especialmente bajo regularización. En el extremo, $hat(mu)(1, x) = hat(mu)(0, x)$ y $hat(tau)_S(x) = 0$ para todo $x$.

=== El T-learner
<sec-cap05_tlearner>

El T-learner (_two-learner_) entrena dos modelos separados:
$
hat(mu)_1(x) = "ML"(Y | X, D = 1), quad hat(mu)_0(x) = "ML"(Y | X, D = 0),
$
y estima $hat(tau)_T(x) = hat(mu)_1(x) - hat(mu)_0(x)$.

*Ventajas.* Garantiza que $D$ afecta la predicción (no puede ser ignorado).

*Problema.* Cada modelo se entrena solo con la submuestra correspondiente. Si un grupo es pequeño (p. ej., 10% tratados), $hat(mu)_1$ tiene alta varianza.

=== El X-learner
<sec-cap05_xlearner>

El X-learner @kunzel2019metalearners usa tres etapas:

+ Entrenar $hat(mu)_1$ y $hat(mu)_0$ como en el T-learner.
+ Para las unidades tratadas, computar $tilde(tau)_1^i = Y_i - hat(mu)_0(X_i)$; entrenar un modelo $hat(tau)_1(x) = "ML"(tilde(tau)_1 | X, D = 1)$. \
  Para las unidades control, computar $tilde(tau)_0^i = hat(mu)_1(X_i) - Y_i$; entrenar $hat(tau)_0(x) = "ML"(tilde(tau)_0 | X, D = 0)$.
+ Combinar: $hat(tau)_X(x) = hat(e)(x) hat(tau)_0(x) + (1 - hat(e)(x)) hat(tau)_1(x)$, donde $hat(e)(x)$ es el _propensity score_ estimado.

#intuicion[
  El paso 2 imputa efectos individuales usando el modelo del grupo opuesto. La combinación final pondera $hat(tau)_0(x)$ y $hat(tau)_1(x)$ según la confianza relativa en cada estimación. La elección $g(x) = hat(e)(x)$ es una convención común en algunas implementaciones, pero no debe describirse automáticamente como ``dar más peso al grupo más numeroso''. La ponderación óptima depende de las varianzas de $hat(tau)_0$ y $hat(tau)_1$. Si se desea una ponderación simple por tamaño efectivo de muestra y varianzas iguales, y si $hat(tau)_1$ se entrena con tratados y $hat(tau)_0$ con controles, los pesos proporcionales al tamaño serían aproximadamente $hat(e)(x)$ para $hat(tau)_1(x)$ y $1 - hat(e)(x)$ para $hat(tau)_0(x)$.
]

=== R-learner: Estimador y score
<sec-cap05_rlearner>

El R-learner @nie2021quasi optimiza directamente una _loss_ que aísla el CATE usando el score ortogonal de Robinson. La forma del score del R-learner deriva del **score de Robinson** (@robinson1988) —el mismo que el @cap-ortogonalidad usó para estimar un efecto constante, ahora con $theta$ reemplazado por una función $tau(dot.c)$ que se optimiza sobre una clase de funciones:
$
hat(tau)_R = "argmin"_tau { 1/n sum_i [ (Y_i - hat(m)_Y(X_i)) - tau(X_i) (D_i - hat(e)(X_i)) ]^2 + Lambda(tau) },
$ <eq-r-learner-loss>
donde $hat(m)_Y(X)$ es la _outcome regression_ de $Y$ sobre $X$, $hat(e)(X)$ es el _propensity score_, y $Lambda(tau)$ es un regularizador.

#theorem(name: [Nie & Wager, 2021])[
  Bajo no confusión, soporte común, y tasas de convergencia $norm(hat(m)_Y - m_Y)_(L^2) = O_p(a_n)$ y $norm(hat(e) - e)_(L^2) = O_p(a_n)$ con $sqrt(n) a_n^2 -> 0$, el R-learner alcanza tasas cuasi-oracle para $tau(dot.c)$ bajo condiciones de ortogonalidad, cross-fitting y tasas de convergencia apropiadas para los nuisance. La consistencia $sqrt(n)$ y la eficiencia semiparamétrica aplican a funcionales de dimensión finita, como el ATE, o a clases paramétricas de $tau(x)$. Para el CATE no paramétrico punto a punto, la tasa depende de la suavidad local, la dimensión de $X$ y el learner utilizado.
] <thm-r-learner>

El R-learner es preferible cuando se dispone de suficiente muestra para estimar $hat(m)_Y, hat(e)$ con precisión, y cuando se quiere inferencia asintótica válida sobre $tau(x)$.

=== El DR-learner
<sec-cap05_drlearner>

Los cuatro meta-learners anteriores comparten un límite: ninguno separa nítidamente la estimación de los _nuisance_ de la estimación del CATE mismo, de modo que el error de los primeros se propaga al segundo a primer orden. El **DR-learner** (@kennedy2023towards, Kennedy 2023) combina los residuos del outcome y propensity score para lograr eficiencia semiparamétrica. #cite(<kennedy2023towards>, form: "prose") cierra ese hueco aplicando al CATE la misma lógica que DML aplicó al ATE: construir un pseudo-resultado cuyo valor esperado condicional *es* el CATE, y luego regresarlo sobre $X$ con cualquier método supervisado.

El procedimiento tiene tres etapas, todas con cross-fitting:

+ Estimar los _nuisance_ $hat(mu)_0, hat(mu)_1, hat(e)$ en particiones ajenas.
+ Construir, para cada observación, el *pseudo-resultado doblemente robusto*
  $
  Gamma_i = hat(mu)_1(X_i) - hat(mu)_0(X_i) + (D_i (Y_i - hat(mu)_1(X_i))) / hat(e)(X_i) - ((1 - D_i)(Y_i - hat(mu)_0(X_i))) / (1 - hat(e)(X_i)).
  $
+ Estimar $hat(tau)_"DR"(x) = hat(E)[Gamma | X = x]$ mediante una regresión ordinaria de $Gamma$ sobre $X$.

La observación clave es que $Gamma_i$ es exactamente el score IRM del @cap-dml *antes* de promediar: promediarlo sobre toda la muestra da el ATE; regresarlo sobre $X$ da el CATE. La doble robustez se hereda punto a punto: $E[Gamma | X = x] = tau(x)$ si $hat(mu)_d$ *o* $hat(e)$ es correcto, no necesariamente ambos — caso particular de la forma canónica de la Nota técnica @sec-cap03_teorema_dml.

#theorem(name: [Kennedy, 2023 — tasa oracle del DR-learner])[
  Bajo no confusión, soporte común y cross-fitting, el error del DR-learner se acota por la suma de dos términos: el error que tendría un *oracle* que observara los verdaderos pseudo-resultados $Gamma_i^*$ (construidos con $mu_d$ y $e$ verdaderos), más un término de segundo orden proporcional al *producto* de los errores de $hat(mu)_d$ y $hat(e)$. En particular, si ambos _nuisance_ convergen a tasa $a_n$ con $a_n^2$ menor que la tasa oracle de la regresión final, el DR-learner alcanza esa tasa oracle.
] <thm-dr-learner>

La estructura de *producto* de errores es lo que distingue al DR-learner del T- y el X-learner, cuyos errores dependen de los _nuisance_ de forma aditiva y de primer orden. En la práctica esto significa que el DR-learner tolera _nuisance_ mediocres siempre que no fallen los dos a la vez, y es la razón por la que es el meta-learner por defecto cuando se quiere una garantía y no solo un estimador razonable. Su costo es la inestabilidad heredada del término IPW: cuando $hat(e)(x)$ se acerca a 0 o 1, $Gamma_i$ explota, y sin _trimming_ o recorte de pesos el estimador puede tener varianza inaceptable — el mismo diagnóstico de soporte común que el @cap-dml exige antes de reportar un ATE se vuelve aquí obligatorio antes de reportar un CATE (@sec-cap04_soporte_comun para el protocolo cuantitativo).

En `econml`, la implementación es `DRLearner` (y su variante `LinearDRLearner`, `ForestDRLearner` según el regresor de la tercera etapa); en `causalml`, `BaseDRRegressor`.

=== Comparación de propiedades
<sec-cap05_comparacion>

#figure(
  caption: [Comparación de meta-learners.],
  table(
    columns: (1.3fr, 1fr, 1fr, 1fr, 1.5fr),
    align: (left, left, left, left, left),
    stroke: none,
    table.hline(stroke: 0.8pt),
    table.header([*Propiedad*], [S-learner], [T-learner], [X-learner], [R-learner], [DR-learner]),
    table.hline(stroke: 0.4pt),
    [Sesgo], [Alto (regularización)], [Medio], [Bajo], [Bajo], [Bajo],
    [Varianza], [Bajo], [Alto (grupo pequeño)], [Medio], [Medio], [Alta si $hat(e)$ extremo],
    [Requiere $hat(e)$], [No], [No], [Sí], [Sí], [Sí],
    [Dependencia de los _nuisance_], [1.er orden], [1.er orden], [1.er orden], [2.º orden], [2.º orden (producto)],
    [Inferencia válida], [No], [Bootstrap], [Bootstrap], [Asintótica local bajo condiciones], [Asintótica local; oracle bajo tasas],
    [Tasa $tau(x)$], [$a_n$], [$a_n$], [$a_n$], [cuasi-oracle/local; $sqrt(n)$ solo para ATE/funcionales], [oracle de la regresión final si $a_n^2$ es despreciable],
    [Implementación], [Trivial], [Simple], [Media], [Compleja], [Media],
    table.hline(stroke: 0.8pt),
  )
) <tab-meta-comparison>

La fila decisiva es la de *dependencia de los nuisance*. S, T y X heredan el error de $hat(mu)_d$ (y de $hat(e)$, en el caso de X) de forma aditiva: si los _learners_ auxiliares convergen a tasa $a_n$, el CATE estimado también, y no mejor. R y DR lo heredan a segundo orden —el producto de los errores en el caso del DR-learner—, que es la misma propiedad que hace funcionar a DML y la razón por la que son los únicos dos de la familia con garantías del tipo "el ML puede ser mediocre y el estimador causal seguir siendo bueno".

#intuicion[
  *Caja de profundización 5.1: calibración de efectos y ETT*

  *Objetivo.* Verificar si los efectos estimados tienen sentido, y distinguir el estimando poblacional del estimando sobre los tratados.

  *Calibración de CATE.* Una forma simple de verificar si los CATE tienen sentido:
  + Ordenar individuos por $hat(tau)(x)$ de menor a mayor.
  + Dividir en 10 grupos (decilas).
  + Calcular el uplift promedio observado en cada decila.
  + Graficar: si el modelo es bueno, el uplift observado debe aumentar con las decilas.

  *ETT (Effect on the Treated).* No solo importa el ATE. A veces queremos saber: ¿cuánto afectó el tratamiento a quienes realmente lo recibieron?
  $
  "ETT" = E[Y(1) - Y(0) | D = 1]
  $
]

== Algoritmo e implementación
<sec-cap05_algoritmo>

=== Pseudocódigo

#algorithm("X-learner")[
  #kwin[Entrada][Datos $(Y_i, D_i, X_i)_(i=1)^n$, modelos ML para $hat(mu)_1, hat(mu)_0, hat(tau)_1, hat(tau)_0$, estimador de propensity $hat(e)$.]
  #kwout[Salida][Estimación $hat(tau)_X(x)$ del CATE.]
  Entrenar $hat(mu)_1(x)$ con $(X_i, Y_i)$ para $D_i = 1$. \
  Entrenar $hat(mu)_0(x)$ con $(X_i, Y_i)$ para $D_i = 0$. \
  Para cada $i : D_i = 1$: $tilde(tau)_1^i arrow.l Y_i - hat(mu)_0(X_i)$. \
  Para cada $i : D_i = 0$: $tilde(tau)_0^i arrow.l hat(mu)_1(X_i) - Y_i$. \
  Entrenar $hat(tau)_1(x)$ con $(tilde(tau)_1^i, X_i)$ para $D_i = 1$. \
  Entrenar $hat(tau)_0(x)$ con $(tilde(tau)_0^i, X_i)$ para $D_i = 0$. \
  Estimar $hat(e)(x)$ con todos los datos. \
  #return-stmt[$hat(tau)_X(x) = hat(e)(x) hat(tau)_0(x) + (1 - hat(e)(x)) hat(tau)_1(x)$.]
] <alg-x-learner>

=== Implementación en Python
<sec-cap05_implementacion>

#figure(
  kind: raw,
  caption: [Comparación de meta-learners sobre dataset sintético.],
  ```python
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor
from sklearn.linear_model import LogisticRegressionCV
from econml.metalearners import XLearner, TLearner, SLearner
from econml.dml import CausalForestDML

def make_dgp(n=2000, p=10, seed=0):
    """CATE verdadero: tau(x) = 2 + 3*x1 - x2^2."""
    rng = np.random.default_rng(seed)
    X = rng.uniform(-1, 1, (n, p))
    e = 1 / (1 + np.exp(-1.0 - 0.5*X[:, 0]))  # propensity score
    D = (rng.uniform(size=n) < e).astype(int)
    tau = 2 + 3*X[:, 0] - X[:, 1]**2
    mu0 = X[:, 2] + 0.5 * X[:, 3]
    Y = mu0 + D * tau + rng.standard_normal(n) * 0.5
    return Y, D, X, tau

# Datos
Y, D, X, tau_true = make_dgp(n=2000, seed=42)

# Learners
ml = lambda: GradientBoostingRegressor(n_estimators=200, max_depth=4, random_state=42)
e_model = LogisticRegressionCV(cv=5)

# S-learner
s = SLearner(overall_model=ml()).fit(Y, D, X)
tau_s = s.effect(X)

# T-learner
t = TLearner(models=ml()).fit(Y, D, X)
tau_t = t.effect(X)

# X-learner
x = XLearner(models=ml(), propensity_model=e_model).fit(Y, D, X)
tau_x = x.effect(X)

# R-learner via CausalForestDML (proxy)
r = CausalForestDML(model_y=ml(), model_t=e_model, discrete_treatment=True,
                    n_estimators=200, random_state=42).fit(Y, D, X=X)
tau_r = r.effect(X)

# Evaluacion: RMSE respecto a CATE verdadero
for name, tau_hat in [("S", tau_s), ("T", tau_t), ("X", tau_x), ("R", tau_r)]:
    rmse = np.sqrt(np.mean((tau_hat - tau_true)**2))
    bias = np.mean(tau_hat - tau_true)
    print(f"{name}-learner: RMSE={rmse:.4f}  Bias={bias:.4f}")
```
) <lst-meta-comparison>

=== Análisis de sesgo y varianza por subgrupo
<sec-cap05_sesgo>

#figure(
  kind: raw,
  caption: [Sesgo del S-learner bajo regularización fuerte.],
  ```python
# Forzar regularizacion fuerte (alpha grande en Lasso)
from sklearn.linear_model import Lasso
ml_strong_reg = lambda: Lasso(alpha=0.5, max_iter=5000)

s_strong = SLearner(overall_model=ml_strong_reg()).fit(Y, D, X)
tau_s_strong = s_strong.effect(X)
print(f"S-learner (regularizado): RMSE={np.sqrt(np.mean((tau_s_strong - tau_true)**2)):.4f}")
print(f"  Fraccion de CATEs estimados en 0: {(np.abs(tau_s_strong) < 0.01).mean():.3f}")
```
) <lst-s-learner-bias>

El _output_ típico muestra que el S-learner con regularización fuerte colapsa los CATEs hacia cero (fracción cercana a 1 en cero), ilustrando el sesgo de regularización.

== Caso empírico y validación
<sec-cap05_caso>

Sobre el dataset #code[nsw_mixtape] ($n = 445$), estimamos el CATE del programa de capacitación sobre ingresos con #code[CausalForestDML]. Réplica propia: el ATE estimado es \$2,226 (IC 95% [\$14, \$4,438]), con heterogeneidad estructurada moderada. La tabla @tab-nsw-cate reporta CATE promedio por subgrupo, calculado sobre los CATEs individuales estimados.

#figure(
  caption: [CATE estimado por subgrupo en NSW (CausalForestDML). Réplica propia.],
  table(
    columns: (1fr, auto, auto),
    align: (left, right, right),
    stroke: none,
    table.hline(stroke: 0.8pt),
    table.header([Subgrupo], [CATE medio (USD)], [n]),
    table.hline(stroke: 0.4pt),
    [Educación < 10 años], [$1\,549$], [116],
    [Educación $>= 10$ años], [$2\,638$], [329],
    [Ingreso 1974 = 0], [$2\,387$], [334],
    [Ingreso 1974 > 0], [$1\,963$], [111],
    [Edad < 25], [$2\,269$], [131],
    [Edad $>= 25$], [$2\,205$], [314],
    table.hline(stroke: 0.8pt),
  )
) <tab-nsw-cate>

La conclusión de política: el programa es más efectivo para individuos con mayor educación previa (que pueden aprovechar mejor la capacitación) y para individuos sin ingresos previos (que tienen mayor margen de mejora). Esto justifica una focalización matizada: la regla naïve de ``tratar a los más pobres'' no es óptima; conviene incorporar la educación como criterio adicional.

== Riesgos, límites y sensibilidad
<sec-cap05_riesgos>

#figure(
  caption: [Riesgos comunes en meta-learners],
  table(
    columns: (1.3fr, 1.3fr, 1.3fr, 1.3fr),
    align: (left, left, left, left),
    stroke: none,
    table.hline(stroke: 0.8pt),
    table.header([*Riesgo*], [*Consecuencia*], [*Diagnóstico*], [*Mitigación*]),
    table.hline(stroke: 0.4pt),
    [S-learner regularizado], [CATE colapsa a cero], [Fracción de CATE cero], [T/X/R-learner],
    [Propensity extremo], [Varianza alta], [Histograma], [Trimming],
    [Subgrupos sin IC], [Falsos hallazgos], [Intervalos], [Bootstrap/forest],
    table.hline(stroke: 0.8pt),
  )
) <tab-riesgos_metalearners>

*Límites.* Los meta-learners asumen no confusión. Si hay variables confusoras no observadas, los CATEs estimados son sesgados. Adicionalmente, los meta-learners S, T, X no tienen garantía de $sqrt(n)$-consistencia para CATE no paramétrico. El R-learner tiene garantía cuasi-oracle y el DR-learner alcanza la tasa oracle de su regresión final bajo la condición de producto de tasas; en ambos casos, la consistencia $sqrt(n)$ y la eficiencia aplican a funcionales como el ATE o a clases paramétricas de $tau(x)$, no al CATE punto a punto sin condiciones adicionales. Para inferencia rigurosa sobre CATE, preferir Causal Forest (capítulo @cap-causal-forests), R-learner o DR-learner.

*Cómo elegir en la práctica.* Una regla de trabajo defendible, en orden: (i) si el soporte común es bueno y hay muestra suficiente, DR-learner o R-learner, por sus garantías de segundo orden; (ii) si $hat(e)$ tiene masa cerca de 0 o 1, evitar DR-learner sin _trimming_ y preferir R-learner o bosque causal, que no dividen explícitamente por el _propensity_; (iii) el T-learner como _baseline_ obligatorio de comparación, porque es simple y su fallo es diagnóstico (si el DR-learner no lo supera, la heterogeneidad modelada probablemente sea ruido); (iv) el S-learner solo con _learners_ poco regularizados y nunca como única especificación, por el colapso a cero documentado en el listado @lst-s-learner-bias.

== Ejercicios y notas bibliográficas
<sec-cap05_ejercicios>

+ Replique el listado @lst-meta-comparison variando el tamaño muestral $n in {500, 1000, 2000, 5000}$. ¿Cómo cambia el ranking de meta-learners?

+ Modifique el DGP para que el propensity score sea extremo ($e(x) in [0.05, 0.15]$). ¿Qué meta-learner se degrada más?

+ Sobre el dataset #code[gov_transfers], estime el CATE de las transferencias gubernamentales sobre el consumo. ¿Qué subgrupos muestran efectos mayores?

+ Implemente el R-learner ``a mano'' (sin #code[econml]) usando #code[scikit-learn] para $hat(m)_Y, hat(e)$ y un #code[RandomForestRegressor] para $hat(tau)$. Compare con la implementación de #code[econml]. Use cross-fitting ($K = 5$) para estimar $hat(m)_Y$ y $hat(e)$ fuera de muestra antes de optimizar $hat(tau)$.

#cite(<kunzel2019metalearners>, form: "prose") es la referencia original para S/T/X-learners. #cite(<nie2021quasi>, form: "prose") introduce el R-learner, construido sobre el score de @robinson1988. #cite(<kennedy2023towards>, form: "prose") es la referencia canónica del DR-learner y de la tasa oracle de la @sec-cap05_drlearner; su lectura es especialmente recomendable porque sitúa a todos los meta-learners de este capítulo dentro de un marco común de pseudo-resultados. #cite(<foster2019orthogonal>, form: "prose") generaliza el principio subyacente a los dos anteriores —_orthogonal statistical learning_— a problemas de aprendizaje con parámetros de estorbo arbitrarios, y es la referencia teórica que explica *por qué* la familia R/DR tiene dependencia de segundo orden. Para una revisión comparativa, @athey2019econometric.
