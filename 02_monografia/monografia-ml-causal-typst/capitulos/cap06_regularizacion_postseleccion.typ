// Capítulo 6 — Regularización, selección de variables y sesgo post-selección
#import "../template/template.typ": *

#chapter[Regularización, selección de variables y sesgo post-selección]
<cap-regularizacion>

#theorem-number-reset()

// Alias de etiqueta preservado del original
#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*Problema:*], [Sesgo post-selección al inferir después de seleccionar variables],
    [*Estimando:*], [$theta_0$ en regresión de alta dimensión],
    [*Identificación:*], [Sparsity aproximada],
    [*Método:*], [LASSO, Post-LASSO OLS],
    [*Nuisance:*], [Selección de variables],
    [*Garantía:*], [Tasa $ell_2$ bajo _restricted eigenvalue_ (@bickel2009simultaneous, Bickel et al. 2009); consistencia de *selección* solo bajo irrepresentabilidad (@zhao2006model, Zhao & Yu 2006, condición mucho más fuerte)],
    [*Librerías:*], [scikit-learn, statsmodels],
    [*Validación:*], [Monte Carlo, sensibilidad a $lambda$],
  )
]

#notatecnica[
El @cap-prediccion-causalidad estableció que responder una pregunta causal en alta dimensión requiere seleccionar controles sin sesgar la inferencia. Este capítulo formaliza precisamente ese problema —selección de variables y el sesgo post-selección que induce— y es, junto con el capítulo anterior, el prerrequisito técnico para Double Machine Learning (@cap-dml, Parte II).
]

== Problema causal, estimando e identificación
<sec-cap06_problema>

Una economista laboral desea estimar el efecto de un programa de capacitación sobre el salario posterior. Dispone de un panel con 80 variables de control potenciales: características demográficas, historial laboral, sector, región, características del empleador, expectativas subjetivas, y un conjunto de variables administrativas. No sabe cuáles de estas variables son realmente confusoras (correlacionadas con la asignación al programa y con el salario) y cuáles son irrelevantes. La intuición clásica sugeriría incluir todas en la regresión, pero con 80 controles y $n = 1\,000$ observaciones, OLS sufre de alta varianza y potencia estadística reducida.

La solución aparentemente natural es seleccionar variables con LASSO y luego correr OLS con las seleccionadas. Esta intuición, sin embargo, es metodológicamente peligrosa: la selección de variables induce un sesgo en la inferencia posterior conocido como _post-selection inference_ o _selective inference_. El problema fue formalizado por @leeb2006can y @potscher2009confidence, quienes mostraron que los intervalos de confianza construidos después de selección con LASSO pueden tener cobertura dramáticamente inferior a la nominal, incluso con muestras grandes.

Este capítulo desarrolla tres ideas centrales. Primero, presentamos LASSO, Ridge y Elastic Net como métodos de regularización con propiedades estadísticas distintas. Segundo, formalizamos el problema del sesgo post-selección y mostramos por qué la inferencia naïve es inválida. Tercero, anticipamos la solución—Post-Double-Selection de Belloni, Chernozhukov y Hansen (2014), que se desarrolla plenamente en el capítulo @cap-pds— como ejemplo paradigmático de cómo el ML puede integrarse con inferencia válida cuando se diseñan procedimientos que respetan la estructura del problema causal.

== Teoría, supuestos y garantías
<sec-cap06_teoria>

=== Supuestos
<sec-cap06_supuestos>

Para que LASSO sea consistente en alta dimensión, se requiere el supuesto de _sparsity_: solo unas pocas componentes de $beta$ son distintas de cero.

#assumption(name: [Sparsity aproximada])[
  El vector verdadero $beta_0$ tiene a lo más $s << n$ componentes no nulas, con $s log p = o(n)$.
] <asu-sparsity>

=== Estimador y score
<sec-cap06_estimador>

Consideremos el modelo lineal de alta dimensión $bold(Y) = bold(X) beta + epsilon$ con $bold(X) in R^(n times p)$ y $beta in R^p$. Cuando $p$ es comparable a $n$ o mayor, OLS tiene alta varianza o no está siquiera definido ($p > n$). Los estimadores penalizados resuelven esto añadiendo una penalización que contrae los coeficientes hacia cero.

#definition(name: [LASSO])[
  El estimador LASSO @tibshirani1996lasso resuelve
  $
  hat(beta)_("LASSO") = "argmin"_(beta in R^p) { (1 / (2n)) norm(Y - X beta)_2^2 + lambda norm(beta)_1 },
  $
  donde $norm(beta)_1 = sum_j abs(beta_j)$ es la norma $ell_1$ y $lambda >= 0$ es el hiperparámetro de penalización.
] <def-lasso>

#definition(name: [Ridge])[
  El estimador Ridge @hoerl1970ridge usa penalización $ell_2$:
  $
  hat(beta)_("Ridge") = "argmin"_beta { (1 / (2n)) norm(Y - X beta)_2^2 + lambda norm(beta)_2^2 }.
  $
] <def-ridge>

#definition(name: [Elastic Net])[
  Elastic Net @zou2005elasticnet combina ambas penalizaciones:
  $
  hat(beta)_("EN") = "argmin"_beta { (1 / (2n)) norm(Y - X beta)_2^2 + lambda [ alpha norm(beta)_1 + (1 - alpha) norm(beta)_2^2 ] },
  $
  con $alpha in [0,1]$ mezclando las dos penalizaciones.
] <def-elasticnet>

La diferencia clave es que LASSO produce _selección de variables_ (algunos $hat(beta)_j = 0$ exactamente), mientras que Ridge solo contrae los coeficientes sin hacer selección. Elastic Net combina ambos comportamientos y es preferible cuando hay grupos de variables altamente correlacionadas.

=== Garantías
<sec-cap06_garantias>

Bajo sparsity y condiciones regulares (designado _restricted eigenvalue condition_, @bickel2009simultaneous), LASSO satisface:

#theorem(name: [Tasa de convergencia de LASSO])[
  Bajo el supuesto de _sparsity_ y _restricted eigenvalue condition_ con constante $kappa > 0$, si $lambda asymp sqrt(log p / n)$, entonces con probabilidad alta:
  $
  norm(hat(beta)_("LASSO") - beta_0)_1 = O_(p)(s sqrt(log p / n)), quad
  norm(hat(beta)_("LASSO") - beta_0)_2 = O_(p)(sqrt(s log p / n)).
  $
] <thm-lasso-rate>

La tasa $sqrt(s log p / n)$ es óptima en el sentido minimax. Sin embargo, el teorema garantiza consistencia en norma $ell_2$ — no consistencia componente a componente, y mucho menos consistencia del *conjunto seleccionado*. Esto es crucial: aunque $hat(beta)_("LASSO")$ se acerca a $beta_0$ en norma global, las componentes individuales pueden tener sesgo sustancial, especialmente las que LASSO selecciona incorrectamente.

==== Recuperar el soporte exige mucho más que recuperar el vector

Conviene separar nítidamente dos garantías que se confunden con frecuencia, porque la diferencia entre ambas es exactamente lo que motiva el resto del capítulo. El teorema de la tasa de convergencia acota el error de *estimación* bajo la _restricted eigenvalue condition_ de @bickel2009simultaneous, una condición relativamente débil que solo exige que la matriz de diseño se comporte bien en un cono alrededor del soporte verdadero. Recuperar el *soporte* $S_0 = {j : beta_(0,j) != 0}$ —es decir, que $hat(S) = S_0$ con probabilidad tendiente a uno— requiere una condición estrictamente más fuerte sobre la correlación entre variables dentro y fuera del soporte.

#assumption(name: [Condición de irrepresentabilidad])[
  Sea $X_(S_0)$ la submatriz de columnas activas y $X_(S_0^c)$ la de las inactivas. Existe $eta in (0,1]$ tal que
  $
  norm(X_(S_0^c)^T X_(S_0) (X_(S_0)^T X_(S_0))^(-1) "sign"(beta_(0,S_0)))_infinity <= 1 - eta.
  $
] <asu-irrepresentable>

#theorem(name: [Consistencia de selección del LASSO])[
  Bajo la condición de irrepresentabilidad anterior, condiciones de regularidad sobre el ruido y un $lambda$ apropiadamente elegido, el LASSO es _sign-consistent_: $P("sign"(hat(beta)_("LASSO")) = "sign"(beta_0)) -> 1$. Recíprocamente, si la condición se viola con desigualdad estricta en la dirección opuesta, el LASSO *no* recupera el soporte verdadero con probabilidad tendiente a uno, para ningún valor de $lambda$.
] <thm-irrepresentable>

Este resultado, de #cite(<zhao2006model>, form: "prose"), es una mala noticia disfrazada de teorema: la condición de irrepresentabilidad es esencialmente *no verificable* en la práctica (depende de $S_0$, que es justamente lo desconocido) y falla precisamente en el escenario que más importa para inferencia causal —cuando una variable irrelevante está fuertemente correlacionada con las confusoras verdaderas—. La parte recíproca es la clave: no se trata de que el LASSO necesite más datos, sino de que existen diseños donde ninguna elección de $lambda$ recupera el soporte. La lección operativa para el resto del curso es directa: *nunca se debe interpretar el conjunto seleccionado por LASSO como "las variables que verdaderamente importan"*, y ningún procedimiento causal debería depender de que la selección sea exactamente correcta. Post-Double-Selection (@cap-pds) está diseñado exactamente bajo esa premisa: no necesita $hat(S) = S_0$, solo necesita que $hat(S)$ *contenga* las confusoras relevantes con alta probabilidad.

==== El problema de Leeb & Pötscher

#cite(<leeb2006can>, form: "prose") demostraron un resultado perturbador: la inferencia post-selección basada en LASSO es fundamentalmente problemática. La intuición es la siguiente. Supongamos que LASSO selecciona un conjunto $hat(S) subset.eq {1, ..., p}$ de variables activas. Si luego corremos OLS sobre $hat(S)$ y reportamos IC al 95% basados en la distribución $t$-Student estándar, la cobertura real puede ser dramáticamente inferior.

#theorem(name: [Leeb & Pötscher, informal])[
  Para procedimientos de selección de modelo consistentes, la cobertura de intervalos construidos después de la selección no es uniforme en el parámetro. Para cualquier nivel nominal $1 - alpha$ y cualquier $epsilon > 0$, existen secuencias de parámetros y distribuciones de los datos tales que la cobertura límite del intervalo post-selección es inferior a $epsilon$. En particular, la cobertura real puede ser arbitrariamente menor que la nominal.
] <thm-leeb-potscher>

#intuicion[
  Imagine que el verdadero $beta_j$ es positivo pero muy pequeño. LASSO lo selecciona solo si la estimación preliminar de $beta_j$ es suficientemente grande. Condicionado a ser seleccionado, $hat(beta)_j$ tiende a ser mayor que $beta_j$ — un sesgo de selección análogo al sesgo de publicación. El IC post-selección, al no condicionar en este hecho, queda centrado en un valor sesgado.
]

==== Dos familias de respuestas a la inferencia post-selección

La literatura posterior a Leeb y Pötscher desarrolló dos estrategias distintas frente a este problema, y conviene situar la del curso dentro de ese mapa antes de continuar.

La primera es la *inferencia selectiva condicional*: aceptar que la selección ocurrió y hacer inferencia sobre la distribución de $hat(beta)_j$ *condicionada al evento de selección*. #cite(<lee2016exact>, form: "prose") muestran que, para el LASSO con $lambda$ fijo, ese evento de selección es un politopo en el espacio de $Y$, lo que permite construir intervalos con cobertura exacta condicional mediante una distribución normal truncada. Es una solución elegante, pero condiciona en un evento aleatorio y produce intervalos que pueden ser muy anchos.

La segunda es la *de-biasing* o *desregularización*: corregir explícitamente el sesgo que la penalización introduce en la componente de interés, construyendo un estimador $hat(beta)_j^("db")$ asintóticamente normal y centrado. #cite(<zhang2014confidence>, form: "prose") y #cite(<vandegeer2014asymptotically>, form: "prose") desarrollan esta vía, que produce inferencia *no condicional* y uniformemente válida sobre el parámetro de interés.

La segunda familia es la relevante para este curso, y por una razón conceptual, no solo técnica: en un problema causal no interesa hacer inferencia sobre "las variables que el LASSO seleccionó" sino sobre un parámetro estructural fijado *antes* de mirar los datos —el efecto de $D$ sobre $Y$—. Post-Double-Selection (@cap-pds) y Double Machine Learning (@cap-dml) son, ambos, instancias de la lógica de de-biasing: el primero corrige la selección incluyendo dos veces; el segundo, ortogonalizando el score. Ninguno de los dos intenta hacer que el LASSO seleccione bien; ambos construyen procedimientos cuya validez *no depende* de que lo haga.

==== Soluciones: de la selección ingenua al Post-Double-Selection

#cite(<belloni2014inference>, form: "prose") propusieron una solución elegante al problema del sesgo post-selección en contextos causales. La idea central es _no seleccionar variables una sola vez_, sino _dos veces_: una para predecir $Y$ a partir de $X$, otra para predecir $D$ a partir de $X$. Luego se corre OLS de $Y$ sobre $D$ y la unión de las variables seleccionadas en ambos pasos.

#theorem(name: [Post-Double-Selection LASSO, informal])[
  Bajo los supuestos de sparsity aproximada y regularidad estándar, el estimador PDS es asintóticamente normal:
  $
  sqrt(n) (hat(theta)_("PDS") - theta_0) arrow.r^(d) cal(N)(0, cal(V)),
  $
  donde $V$ es la varianza asintótica estándar de OLS con el conjunto de controles verdaderos. La inferencia basada en la distribución $t$-Student es válida.
] <thm-pds>

La clave del éxito de PDS es la _doble selección_: las variables confusoras son aquellas que predicen tanto $Y$ como $D$. Seleccionando por separado cada conjunto y tomando la unión, se capturan todas las confusoras relevantes con alta probabilidad, mientras que el sesgo de selección individual se diluye. Desarrollamos este método en detalle en el capítulo @cap-pds.

== Algoritmo e implementación
<sec-cap06_algoritmo>

=== Pseudocódigo

El procedimiento Post-LASSO OLS (o _naive_ post-selection) se describe a continuación. Este algoritmo refleja la práctica ingenua que induce sesgo post-selección, y sirve como base para contrastar con la corrección introducida por PDS en el capítulo @cap-pds.

#algorithm("Post-LASSO OLS (selección ingenua)")[
  #kwin[Entrada][Datos ${(Y_i, D_i, X_i)}_(i=1)^n$, hiperparámetro de penalización $lambda >= 0$, número de folds $K$ para validación cruzada (opcional).]
  #kwout[Salida][Estimador $hat(theta)$ y error estándar HC1 $hat(sigma)$]
  Ejecutar LASSO de $Y$ sobre $(D, X)$ con penalización $lambda$. \
  Identificar el conjunto de variables seleccionadas $hat(S) = {j : hat(beta)_j != 0} union {1}$ (forzar inclusión de $D$). \
  Estimar OLS de $Y$ sobre $D$ y las variables en $hat(S)$. \
  Calcular errores estándar robustos HC1. \
  #return-stmt[$hat(theta)_("OLS"), hat(sigma)_("HC1")$]
] <alg-post-lasso-ols>

=== Implementación en Python
<sec-cap06_implementacion>

Ilustramos el sesgo post-selección con un dataset sintético donde conocemos el verdadero $theta$.

#figure(
  kind: raw,
  caption: [Ilustración del sesgo post-selección.],
  ```python
import numpy as np
import pandas as pd
import statsmodels.api as sm
from sklearn.linear_model import LassoCV
from sklearn.utils import check_random_state

def generate_data(n=500, p=100, n_confounders=5, seed=42):
    """DGP: theta=1; las primeras variables son confusoras; el resto ruido."""
    rng = check_random_state(seed)
    X = rng.standard_normal((n, p))

    beta_D = np.zeros(p)
    beta_D[:n_confounders] = 0.5

    gamma_Y = np.zeros(p)
    gamma_Y[:n_confounders] = 0.7

    D = (X @ beta_D + rng.standard_normal(n) > 0).astype(float)
    Y = 1.0 * D + X @ gamma_Y + rng.standard_normal(n)

    return Y, D, X

def post_selection_ate(Y, D, X):
    """Naive: LASSO de Y sobre [D, X], luego OLS HC1 con seleccionados."""
    DX = np.column_stack([D, X])

    lasso = LassoCV(cv=5).fit(DX, Y)
    selected = np.abs(lasso.coef_) > 1e-8

    # Forzar tratamiento en el modelo final
    selected[0] = True

    X_sel = sm.add_constant(DX[:, selected])
    ols = sm.OLS(Y, X_sel).fit(cov_type="HC1")

    # D es la primera variable después de la constante
    theta_hat = ols.params[1]
    se_hat = ols.bse[1]

    return theta_hat, se_hat

# La cobertura debe calcularse con el SE estimado en cada réplica.
# No usar results.std() como si fuera el error estándar del procedimiento.

# Monte Carlo: 1000 repeticiones
np.random.seed(0)

thetas = []
ses = []
covers = []

for b in range(1000):
    Y, D, X = generate_data(n=500, p=100, seed=b)
    theta_hat, se_hat = post_selection_ate(Y, D, X)

    thetas.append(theta_hat)
    ses.append(se_hat)
    covers.append(np.abs(theta_hat - 1.0) < 1.96 * se_hat)

thetas = np.array(thetas)
covers = np.array(covers)

print("Verdadero theta = 1.0")
print(f"Sesgo post-selección: {thetas.mean() - 1.0:.4f}")
print(f"Cobertura real IC post-selección: {covers.mean():.3f}")
```
) <lst-post-selection-bias>

El _output_ típico muestra un sesgo de aproximadamente $-0.05$ a $-0.10$ y cobertura real de aproximadamente 0.85–0.90, claramente inferior al nominal 0.95. La conclusión práctica: *no se debe reportar IC construidos después de selección LASSO sin corrección*.

=== Diagnósticos de nuisance
<sec-cap06_nuisance>

#intuicion[
  *Caja de profundización 2.1: Partialling-out y double lasso*

  *Objetivo.* Entender dos herramientas clave para limpiar el efecto de las covariables antes de estimar el efecto causal.

  *Idea intuitiva.* Para estimar el efecto de $D$ sobre $Y$, primero "limpiamos" $Y$ y $D$ de la influencia de $X$:
  $
  tilde(Y) = Y - E[Y | X], quad tilde(D) = D - E[D | X]
  $
  Luego estimamos $theta$ con la regresión de $tilde(Y)$ sobre $tilde(D)$ sin intercepto. Esto se llama *partialling-out* (Frisch-Waugh-Lovell).

  *Double lasso.* En alta dimensión, necesitamos seleccionar variables relevantes:
  + LASSO de $Y$ sobre $X$ $->$ obtengo $S_Y$ (variables que predicen $Y$)
  + LASSO de $D$ sobre $X$ $->$ obtengo $S_D$ (variables que predicen $D$)
  + Unión: $S = S_Y union S_D$ (variables que predicen cualquiera de los dos)
  + OLS de $Y$ sobre $D$ + controles en $S$

  *¿Por qué funciona?* Una confusora afecta TANTO a $Y$ COMO a $D$. Si seleccionamos las que afectan a cada uno, capturamos todas las confusoras relevantes. El "doble" lasso es la base del Post-Double-Selection, desarrollado en el @cap-pds.
]

#figure(
  kind: raw,
  caption: [Partialling-out manual.],
  ```python
from sklearn.linear_model import LassoCV
import numpy as np

def partialling_out_theta(Y, D, X):
    """Estima theta limpiando Y y D con LASSO."""
    model_y = LassoCV(cv=5).fit(X, Y)
    model_d = LassoCV(cv=5).fit(X, D)

    y_res = Y - model_y.predict(X)
    d_res = D - model_d.predict(X)

    theta = np.mean(d_res * y_res) / np.mean(d_res * d_res)
    return theta
```
) <lst-partialling-out>

== Caso empírico y validación
<sec-cap06_caso>

#cite(<belloni2014inference>, form: "prose") aplicaron PDS al dataset de @card1995 sobre retornos a la educación. Encuentran un efecto positivo y significativo del orden de las estimaciones 2SLS clásicas, con diferencias moderadas entre PDS y los estimadores IV con controles seleccionados manualmente; las cifras exactas dependen del set de instrumentos y controles considerados y no se reproducen aquí para evitar imprecisiones.

*Réplica propia sobre el dataset del repositorio.* Sobre #code[close_college] ($n = 3\,003$), OLS con controles básicos da un coeficiente de 0.071 (HC1, IC 95% [0.064, 0.078]); IV 2SLS con #code[nearc4] da 0.124 (IC 95% [0.028, 0.221]); DML-PLIV con #code[GradientBoostingRegressor] da 0.145 (IC 95% [0.052, 0.237]). Estas son cifras de réplica propia, no del _paper_ original.

Sobre el dataset #code[nhefs] del repositorio, que tiene 51 covariables utilizables (tras excluir variables post-tratamiento y de fecha), podemos aplicar el mismo principio. La pregunta causal es: ¿cuál es el efecto de dejar de fumar sobre el cambio de peso? Réplica propia sobre $n = 1\,566$ observaciones: OLS con selección manual de 5 controles reporta un coeficiente de 3.20 kg (IC 95% [2.26, 4.14]); PDS con LASSO aplicado a los 51 controles reporta un coeficiente de 3.22 kg (IC 95% [2.29, 4.14]). La diferencia es pequeña en este caso, pero PDS selecciona 18 variables, capturando confusoras adicionales (estado civil, hábitos de alcohol, condiciones médicas) que el análisis manual omitía.

== Riesgos, límites y sensibilidad
<sec-cap06_riesgos>

=== Tabla de riesgos

#riesgos[
  #table(
    columns: (1fr, 1fr, 1fr, 1fr),
    align: (left, left, left, left),
    stroke: none,
    table.hline(stroke: 0.8pt),
    table.header(
      [*Riesgo*], [*Consecuencia*], [*Diagnóstico*], [*Mitigación*]
    ),
    table.hline(stroke: 0.4pt),
    [Inferir después de seleccionar], [Cobertura inválida], [Monte Carlo], [PDS/DML],
    [Interpretar coeficiente LASSO como causal], [Sesgo], [Regularización], [Post-LASSO/DML],
    [$lambda$ inestable], [Selección frágil], [Sensibilidad], [Varios $lambda$],
    table.hline(stroke: 0.8pt),
  )
]

=== Cuándo no usar este método

*Límites del enfoque.* PDS asume sparsity aproximada: que pocas variables son realmente confusoras. Si la estructura de confusión es densa (muchas variables pequeñas que colectivamente importan), PDS puede ser inconsistente. En tal caso se prefiere DML (capítulo @cap-dml), que no requiere sparsity estricta. Adicionalmente, PDS se limita a modelos lineales; para heterogeneidad estructurada en $X$ se requiere GRF (capítulo @cap-causal-forests) o meta-learners (capítulo @cap-meta-learners).

=== Checklist de validación

+ *Verificar cobertura empírica:* ejecutar un Monte Carlo bajo el DGP supuesto para confirmar que los IC post-selección alcanzan la cobertura nominal.

+ *Sensibilidad a $lambda$:* reportar resultados para varios valores de $lambda$ (e.g., $lambda plus.minus 1$ desviación estándar de CV) y verificar que la selección no cambia drásticamente.

+ *Estabilidad de la selección:* usar bootstrap o submuestreo para evaluar qué fracción de las veces cada variable es seleccionada.

+ *Comparar con OLS completo:* si $p < n$, comparar el estimador Post-LASSO con OLS sin selección para evaluar el costo de la regularización.

+ *Reportar ambos:* presentar siempre el estimador de Post-LASSO OLS junto con el de PDS para transparentar el efecto de la doble selección.

== Inferencia post-selección

La construcción de intervalos de confianza *válidos tras selección de variables* requiere métodos especializados que corrijan el sesgo condicional: @lee2016exact (Lee et al. 2016) para inferencia exacta post-LASSO, @zhang2014confidence (Zhang & Zhang 2014) para parámetros de baja dimensión en modelos de alta dimensión, y @vandegeer2014asymptotically (van de Geer et al. 2014) para regiones de confianza asintóticamente óptimas.

En la práctica del curso, el enfoque DML (Cap. 11) *evita este problema* mediante cross-fitting y scores ortogonales: la selección de variables ocurre en datos auxiliares separados, preservando la validez de la inferencia.

== Ejercicios y notas bibliográficas
<sec-cap06_ejercicios>

+ Replique el experimento Monte Carlo del listado @lst-post-selection-bias variando $p in {20, 50, 100, 200}$. ¿Cómo cambia el sesgo y la cobertura con la dimensionalidad?

  Implemente PDS (selección doble) sobre el mismo DGP sintético. Verifique que el sesgo se reduce sustancialmente y la cobertura se acerca al nominal 0.95. Calcule la cobertura como la fracción de réplicas en que el IC ingenuo post-OLS contiene el verdadero $theta$, usando el SE estimado en cada réplica.

+ Sobre el dataset #code[nhefs], aplique: (a) OLS con 5 controles seleccionados manualmente, (b) LASSO _naive_ (una sola selección), (c) PDS. Compare los tres estimadores y sus errores estándar.

+ Demuestre analíticamente que Ridge no hace selección de variables. ¿Por qué Ridge es preferible a LASSO cuando hay grupos de variables altamente correlacionadas?

+ Implemente la función #code[partialling_out_theta] del listado @lst-partialling-out y verifique que recupera el verdadero $theta$ en un DGP lineal. ¿Qué pasa si $X$ contiene variables irrelevantes (ruido puro)?

+ Compare PDS con el partialling-out ingenuo (un solo LASSO de $Y$ sobre $[D, X]$). Muestre que el partialling-out ingenuo tiene sesgo mientras que PDS no, en un Monte Carlo con $p=100$ y $s=5$.

#cite(<tibshirani1996lasso>, form: "prose") y #cite(<hoerl1970ridge>, form: "prose") son las referencias originales. #cite(<hastie2015statistical>, form: "prose") ofrece un tratamiento moderno de regularización en alta dimensión. #cite(<bickel2009simultaneous>, form: "prose") establece la tasa $ell_2$ bajo _restricted eigenvalue_ y #cite(<zhao2006model>, form: "prose") la condición de irrepresentabilidad y su recíproca para la consistencia de selección; leer ambos en secuencia es la forma más económica de internalizar por qué "el LASSO funciona" significa cosas muy distintas según qué se pida de él. #cite(<leeb2006can>, form: "prose") y #cite(<potscher2009confidence>, form: "prose") son las referencias obligatorias sobre el problema de inferencia post-selección; #cite(<lee2016exact>, form: "prose") desarrolla la vía de inferencia selectiva condicional, y #cite(<zhang2014confidence>, form: "prose") junto con #cite(<vandegeer2014asymptotically>, form: "prose") la de _de-biasing_, que es la que este curso sigue. #cite(<belloni2014inference>, form: "prose") introduce Post-Double-Selection. Para una revisión pedagógica, @chernozhukov2018applied.
