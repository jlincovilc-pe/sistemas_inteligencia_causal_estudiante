// Capítulo 5 — Predicción y causalidad: por qué el ML no es causal por defecto
// (Parte I. La numeración `cap01` del nombre de archivo es histórica: proviene
//  de la edición corta anterior y se conserva para no romper referencias.)
#import "../template/template.typ": *

#chapter[Predicción y causalidad: por qué el ML no es causal por defecto]
<cap-prediccion-causalidad>

#theorem-number-reset()

// Alias de etiqueta preservado del original LaTeX (\label{cap:prediccion_causalidad})
#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*Problema:*], [Distinguir predicción de efecto causal],
    [*Estimando:*], [$"ATE"$, $"CATE"(x)$],
    [*Identificación:*], [No confusión, soporte común, SUTVA],
    [*Método:*], [Comparación predictiva vs causal],
    [*Nuisance:*], [$mu_d(x)$],
    [*Garantía:*], [Identificación bajo supuestos],
    [*Librerías:*], [scikit-learn, statsmodels],
    [*Validación:*], [Simulación de collider, placebos],
  )
]

#notatecnica[
Este capítulo retoma, con el aparato formal de la econometría con _machine learning_, la distinción entre asociación y causalidad presentada de forma intuitiva en el @cap-causalidad-elemental y formalizada con SCM y la Jerarquía Causal de Pearl en el @cap-scm-pch. Aquí el foco pasa de "¿qué pregunta estoy haciendo?" a "¿cómo la respondo con datos de alta dimensión?" — la pregunta que estructura toda la Parte II del curso.
]

== Problema causal, estimando e identificación
<sec-cap01_problema>

Considere un economista del Ministerio de Desarrollo Social que debe decidir a qué hogares beneficiar con un programa de transferencias condicionadas. El programa tiene presupuesto limitado: solo puede cubrir al 30% de la población elegible. El analista dispone de cien variables socioeconómicas por hogar (ingresos, composición familiar, escolaridad, empleo, vivienda, salud) y un registro histórico de hogares que recibieron o no el programa, junto con el ingreso posterior observado. La pregunta relevante es _causal_: ¿qué hogares experimentarían el mayor incremento de ingresos si recibieran el programa? La pregunta _predictiva_ —qué hogares tendrán mayores ingresos en el futuro, independientemente del programa— es distinta y, para fines de focalización, equivocada.

La distinción es crucial porque los algoritmos estándar de _machine learning_ (regresión ridge, bosques aleatorios, _gradient boosting_, redes neuronales) están optimizados para predicción, no para estimación causal. Un bosque aleatorio que predice con alta precisión el ingreso futuro de un hogar puede ofrecer estimaciones sesgadas del efecto del programa, por dos razones estructurales. Primero, los algoritmos predictivos no distinguen entre variación explicada por el tratamiento y variación explicada por covariables correlacionadas con el tratamiento. Segundo, la regularización que mejora la predicción fuera de muestra introduce sesgo en la estimación de coeficientes causales, fenómeno conocido como _regularization-induced bias_.

Este capítulo introduce el marco conceptual que vertebra todo el curso. Argumentamos que *la inferencia causal requiere supuestos de identificación económicos, no estadísticos*, y que el aporte del ML consiste en flexibilizar la estimación de componentes auxiliares (_nuisance_) sin vulnerar esos supuestos. Establecemos la notación de resultados potenciales en el régimen de alta dimensionalidad, definimos los estimandos centrales del curso (ATE, ATT, CATE, _policy value_), y mostramos empíricamente con el dataset de Card (1995) sobre retornos a la educación que un modelo predictivo de alta dimensión puede arrojar respuestas radicalmente distintas a las de una estimación causal cuidadosa.

Conviene, sin embargo, evitar la conclusión simétrica y también equivocada: que la predicción sea siempre el instrumento inadecuado. La distinción fundamental entre problemas de predicción y problemas de política se formaliza en @kleinberg2015prediction (Kleinberg et al. 2015), quienes argumentan que existe una clase entera de problemas de política —los que llaman _prediction policy problems_— en los que la decisión depende de un pronóstico y *no* de un efecto causal. Su ejemplo canónico es la decisión de operar una cadera a un paciente terminal: el beneficio de la operación depende de cuánto vivirá el paciente, que es una pregunta puramente predictiva; el efecto causal de la operación sobre la movilidad puede darse por conocido. El criterio para distinguir ambos regímenes es preciso y vale la pena memorizarlo: *si la decisión cambia la variable sobre la que se razona, la pregunta es causal; si la decisión solo depende de un estado del mundo que ocurriría de todos modos, la pregunta es predictiva*. Focalizar un subsidio por "quién se beneficiaría más" es causal —asignar el subsidio cambia el ingreso—; focalizarlo por "quién es más pobre" es predictivo, porque la pobreza basal se realiza con o sin el programa. Muchos sistemas de _targeting_ en producción mezclan ambos criterios sin declararlo, y la tabla @tab-pred-causal existe precisamente para forzar esa declaración.

La tabla @tab-pred-causal sistematiza la diferencia entre el régimen predictivo y el régimen causal. Esta distinción estructura todo el curso.

#figure(
  caption: [Régimen predictivo vs. régimen causal.],
  table(
    columns: (1.2fr, 1.5fr, 1.8fr),
    align: (left, left, left),
    stroke: none,
    table.hline(stroke: 0.8pt),
    table.header(
      [*Dimensión*], [*Predicción*], [*Causalidad*]
    ),
    table.hline(stroke: 0.4pt),
    [Objetivo], [Minimizar error fuera de muestra], [Estimar $tau(x)$ con IC válido],
    [Estimando], [$E[Y | X]$], [$E[Y(1) - Y(0) | X]$],
    [Métrica de éxito], [RMSE, accuracy, AUC], [Sesgo, cobertura, RMSE en $tau$],
    [Datos requeridos], [Solo $Y, X$ observados], [Requiere $Y(0), Y(1)$ que no se observan simultáneamente],
    [Supuestos clave], [IID, estacionariedad], [No confusión, soporte común, SUTVA],
    [Regularización], [Bienvenida (mejora generalización)], [Peligrosa (introduce sesgo en $tau$)],
    [Validación], [Cross-validation estándar], [Placebos, Qini, comparación con benchmarks],
    table.hline(stroke: 0.8pt),
  )
) <tab-pred-causal>

== Teoría, supuestos y garantías
<sec-cap01_teoria>

=== Supuestos
<sec-cap01_supuestos>

Adoptamos el marco de @neyman1923 y @rubin1974. Para cada unidad $i$ se definen dos resultados potenciales: $Y_i(1)$ si recibe tratamiento y $Y_i(0)$ si no lo recibe. La asignación observada es $D_i in {0,1}$ y el resultado observado obedece la restricción de consistencia $Y_i = D_i Y_i(1) + (1-D_i) Y_i(0)$. Las covariables pre-tratamiento $X_i in R^p$ son un vector de dimensión $p$, donde en este curso $p$ puede ser grande (decenas o cientos) e incluso crecer con $n$.

Los supuestos económicos que permiten identificar $tau(x)$ a partir de datos observacionales son tres.

#assumption(name: [No confusión condicional])[
  $Y(0), Y(1) perp perp D | X$.
] <asu-unconfoundedness>

#assumption(name: [Soporte común])[
  Existe $underline(e) > 0$ tal que $underline(e) < P(D = 1 | X = x) < 1 - underline(e)$ para todo $x$ en el soporte de $X$.
] <asu-overlap>

#assumption(name: [SUTVA / No interferencia])[
  $Y_i(d) = Y_i(d, d_(-i))$ para todo $d$ y todo $i$, donde $d_(-i)$ son los tratamientos de las demás unidades.
] <asu-sutva>

Estos supuestos son _económicos_: su validez depende del contexto sustantivo, no de la cantidad de datos. El supuesto de no confusión condicional exige que el investigador observe todas las variables que afectan simultáneamente la asignación al tratamiento y el resultado; el supuesto de soporte común requiere que haya unidades tratadas y no tratadas en cada región del espacio de covariables; el supuesto de SUTVA / no interferencia prohíbe efectos cruzados entre unidades. La responsabilidad de justificarlos recae en el economista, no en el algoritmo.

=== Estimador y score
<sec-cap01_estimador>

#definition(name: [Estimandos causales centrales])[
  Bajo no interferencia (SUTVA), los estimandos de interés son:
  $
  "ATE": & quad theta = E[Y(1) - Y(0)], \
  "ATT": & quad theta_("ATT") = E[Y(1) - Y(0) | D = 1], \
  "CATE": & quad tau(x) = E[Y(1) - Y(0) | X = x], \
  "Policy value": & quad V(pi) = E[Y(pi(X))],
  $
  donde $pi: R^p -> {0,1}$ es una regla de asignación de tratamiento.
]

El curso se centra casi exclusivamente en $tau(x)$ y $V(pi)$, porque son los estimandos que el ML permite abordar de manera genuinamente nueva: la heterogeneidad del efecto causal y la optimización de políticas basadas en esa heterogeneidad.

Bajo los supuestos de no confusión condicional–de soporte común, el CATE es identificable como diferencia de dos funciones de regresión condicional:
$
tau(x) = mu_1(x) - mu_0(x), quad mu_d(x) = E[Y | X = x, D = d].
$

Si estimamos $hat(mu)_0$ y $hat(mu)_1$ con un método de ML flexible (bosque aleatorio, _gradient boosting_, red neuronal) y calculamos $hat(tau)(x) = hat(mu)_1(x) - hat(mu)_0(x)$, se obtiene el _T-learner_ que estudiaremos en el capítulo @cap-meta-learners. La pregunta crítica es: ¿bajo qué condiciones $hat(tau)(x) -> tau(x)$ en alta dimensión?

=== Garantías
<sec-cap01_garantias>

El problema es que los algoritmos de ML regularizan para optimizar predicción, no estimación de efectos. #cite(<athey2017beyond>, form: "prose") ilustra esto con un ejemplo simple: si $X$ contiene una variable fuertemente correlacionada con $D$ pero sin efecto causal sobre $Y$, el algoritmo predictivo puede _descartar_ $D$ en la regresión de $Y$ (porque $X$ ya explica $Y$ casi igual de bien), generando un $hat(mu)_d$ que ignora el efecto del tratamiento. La predicción de $Y$ mejora, pero la estimación de $tau$ se degrada.

#theorem(name: [Sesgo de regularización en T-learner, versión informal])[
  Sea $hat(mu)_d$ un estimador de ML con error $norm(hat(mu)_d - mu_d)_(L^2) = O_p(a_n)$ donde $a_n -> 0$. Entonces el T-learner $hat(tau) = hat(mu)_1 - hat(mu)_0$ satisface
  $
  norm(hat(tau) - tau)_(L^2) <= norm(hat(mu)_1 - mu_1)_(L^2) + norm(hat(mu)_0 - mu_0)_(L^2) = O_p(a_n).
  $
  Sin embargo, la _distribución_ asintótica de $hat(tau)$ no es $sqrt(n)$-Gaussiana en general: la regularización introduce un sesgo de orden $a_n$ que puede dominar la varianza $sqrt(n)$.
] <thm-reg-bias>

La consecuencia operacional es directa: no se pueden construir intervalos de confianza válidos para $tau(x) approx hat(tau)(x) plus.minus 1.96 hat("SE")(hat(tau))$ si el sesgo de regularización domina la varianza. Se requieren mecanismos adicionales—ortogonalización y _cross-fitting_, que estudiaremos en los capítulos @cap-ortogonalidad y @cap-dml— para recuperar la $sqrt(n)$-consistencia y la validez de la inferencia.

== Algoritmo e implementación
<sec-cap01_algoritmo>

==== Pseudocódigo

El método conceptual de este capítulo no requiere pseudocódigo; las implementaciones prácticas se presentan en los siguientes capítulos.

=== Implementación en Python
<sec-cap01_implementacion>

Para hacer concreta la distinción entre predicción y causalidad, comparamos dos enfoques sobre el dataset de @card1995 sobre retornos a la educación. La pregunta económica es: ¿cuál es el efecto causal de un año adicional de educación sobre el logaritmo del salario? El dataset #code[close_college] contiene una variable instrumental #code[nearc4] (proximidad a una universidad de cuatro años) que usaremos solo como referencia, pero el foco aquí es contrastar la respuesta predictiva de un bosque aleatorio con la respuesta causal de una regresión OLS con controles.

#figure(
  kind: raw,
  caption: [Comparación predictivo vs. causal sobre datos de Card (1995).],
  ```python
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor

import statsmodels.api as sm

# Cargar dataset del repositorio
df = pd.read_csv("../data/datasets/real/public_causaldata/close_college/data.csv")
# Variables: nearc4 (IV), educ (tratamiento), lwage (resultado), controles
Y = df["lwage"].values
D = df["educ"].values
X = df[["black", "smsa", "south", "married", "exper"]].values

# --- Enfoque predictivo: bosque aleatorio que ignora el rol causal de D ---
rf = RandomForestRegressor(n_estimators=200, random_state=42)
# Entrenamos sobre [D, X] y predecimos Y
DX = np.column_stack([D, X])
rf.fit(DX, Y)
# "Efecto" predictivo: derivada numerica respecto a D
D_plus = D + 1
DX_plus = np.column_stack([D_plus, X])
efecto_pred = (rf.predict(DX_plus) - rf.predict(DX)).mean()
print(f"Efecto predictivo (RF): {efecto_pred:.4f}")

# --- Enfoque causal: OLS con controles (sin IV, solo comparacion) ---
Xc = sm.add_constant(np.column_stack([D, X]))
ols = sm.OLS(Y, Xc).fit(cov_type="HC1")
efecto_ols = ols.params[1]
se_ols = ols.bse[1]
print(f"Efecto OLS (HC1): {efecto_ols:.4f} (SE={se_ols:.4f})")
print(f"IC 95% OLS: [{efecto_ols - 1.96*se_ols:.4f}, {efecto_ols + 1.96*se_ols:.4f}]")
```
) <lst-card-comparison>

El _output_ típico de este ejercicio muestra una divergencia instructiva. El bosque aleatorio reporta un "efecto" predictivo que mezcla la variación causal de la educación con la variación espuria introducida por la correlación entre educación y covariables omitidas. OLS con controles, al imponer una forma funcional lineal y un coeficiente constante, aísla la variación atribuible a la educación pero asume linealidad y homogeneidad. La lección no es que OLS sea superior—ambos son aproximaciones imperfectas— sino que responden a preguntas distintas y producen números distintos. Confiar ciegamente en el _output_ del bosque aleatorio como estimación causal sería un error metodológico.

==== Diagnósticos de nuisance

Los diagnósticos de componentes _nuisance_ (propensity score, outcome regression) se desarrollan en detalle en el capítulo @cap-dml, donde se presentan las herramientas específicas para evaluar la calidad de los estimadores auxiliares.

== Caso empírico y validación
<sec-cap01_caso>

=== Datos y preprocesamiento
<sec-cap01_datos>

#cite(<card1995>, form: "prose") es un caso paradigmático porque combina un instrumento (#code[nearc4]) con un set de controles de dimensión moderada. En su análisis original, Card reporta un retorno a la educación de aproximadamente 7.5% usando IV. Estudios posteriores con más controles (Belloni, Chernozhukov y Hansen, 2014) muestran que la selección de controles afecta la estimación en no menos de 1.5 puntos porcentuales.

=== Estimación principal
<sec-cap01_estimacion_principal>

En nuestra aplicación con #code[close_college], OLS con cinco controles básicos reporta un coeficiente de aproximadamente 0.07 (7%) con error estándar robusto de 0.004. El bosque aleatorio, al no distinguir el rol causal de #code[educ], reporta un "efecto predictivo" de aproximadamente 0.04, sustancialmente menor. La diferencia se debe a que el bosque estima una derivada parcial predictiva que no aísla el efecto causal de educ: mezcla variación causal con correlaciones observadas (por ejemplo, exper) y no controla por confusores no observados (por ejemplo, habilidad). Adicionalmente, la regularización puede contraer el efecto estimado de educ si otras covariables predicen bien el salario. Desde el punto de vista predictivo esto es correcto (mejora el RMSE), pero desde el punto de vista causal es un sesgo por variable de confusión no controlada adecuadamente.

Este ejemplo motivará el desarrollo del curso: ¿cómo combinar la flexibilidad del bosque aleatorio para estimar $mu_d(x)$ con la garantía de inferencia válida para $tau$? La respuesta, que se desarrolla en los capítulos @cap-ortogonalidad–@cap-dml, es la _ortogonalización de Neyman_ combinada con _cross-fitting_.

=== Validación
<sec-cap01_validacion>

#figure(
  kind: raw,
  caption: [Simulación de sesgo por collider.],
  ```python
import numpy as np
import pandas as pd

rng = np.random.default_rng(42)
n = 10000

# Dos variables independientes
A = rng.normal(size=n)
B = rng.normal(size=n)

# C es collider (causa común): A -> C <- B
C = 0.8 * A + 0.8 * B + rng.normal(size=n)

df = pd.DataFrame({"A": A, "B": B, "C": C})

print("Corr(A,B) sin condicionar:", df["A"].corr(df["B"]))
print("Corr(A,B | C alto):",
      df[df["C"] > df["C"].quantile(0.8)]["A"].corr(
      df[df["C"] > df["C"].quantile(0.8)]["B"]))
# NOTA: condicionar en un collider crea una correlacion espuria
```
) <lst-collider-simulation>

El listado ilustra el fenómeno que #cite(<elwert2014endogenous>, form: "prose") llaman *sesgo de selección endógena*: dos variables marginalmente independientes se vuelven dependientes al condicionar en una causa común de ambas (o en un descendiente suyo). Es el mecanismo inverso al de la confusión —allí condicionar *elimina* una asociación espuria; aquí condicionar la *crea*— y explica por qué "controlar por todo lo disponible" no es una estrategia conservadora sino una fuente activa de sesgo. El @cap-intervencion-contrafactual formaliza cuándo ocurre cada caso mediante el criterio de puerta trasera; este listado solo pretende dejar la intuición numérica instalada antes de que llegue el aparato gráfico.

El sesgo por condicionamiento en un collider se trata formalmente en @elwert2014endogenous (Elwert & Winship 2014).

=== Interpretación económica
<sec-cap01_interpretacion>

#intuicion[
  *Caja de profundización 1.1: Modelos causales estructurales y jerarquía causal*

  *Objetivo.* Distinguir tres tipos de preguntas causales: las que solo observan, las que intervienen y las que imaginan escenarios alternativos.

  *Ejemplo económico.* Un gerente de banco quiere saber:
  + ¿Los clientes con más ingresos piden más crédito? (solo observamos)
  + ¿Qué pasa si bajamos la tasa de interés? (intervenimos)
  + ¿Este cliente específico habría pedido crédito si no le hubiéramos subido la tasa? (imaginamos)

  *Los tres niveles (Pearl).*
  $
  P(Y | X = x) != P(Y | "do"(X = x)) != P(Y_x | X = x', Y = y')
  $
  - *Nivel 1 – Asociación ("Ver"):* $P(Y | X)$. Ej: "los clientes con más ingresos piden más crédito."
  - *Nivel 2 – Intervención ("Hacer"):* $P(Y | "do"(X))$. Ej: "si bajamos la tasa, ¿cuánto aumenta el crédito?"
  - *Nivel 3 – Contrafactual ("Imaginar"):* $P(Y_x | X = x', Y = y')$. Ej: "Juan no pidió crédito con la tasa alta; ¿lo habría pedido con la tasa baja?"

  *Importante:* El ML predictivo opera en nivel 1. Para política pública (nivel 2) o responsabilidad individual (nivel 3) se necesitan supuestos causales adicionales.
]

== Riesgos, límites y sensibilidad
<sec-cap01_riesgos>

=== Tabla de riesgos
<sec-cap01_tabla_riesgos>

La tabla @tab-riesgos-cap01 resume los riesgos principales al confundir predicción con causalidad, junto con sus consecuencias, diagnósticos y estrategias de mitigación.

#riesgos[
  #figure(
    caption: [Riesgos al confundir predicción con causalidad.],
    table(
      columns: (1fr, 1fr, 1fr, 1.5fr),
      align: (left, left, left, left),
      stroke: none,
      table.hline(stroke: 0.8pt),
      table.header(
        [*Riesgo*], [*Consecuencia*], [*Diagnóstico*], [*Mitigación*]
      ),
      table.hline(stroke: 0.4pt),
      [Confundir predicción con causalidad],
      [Política errónea basada en efectos no causales],
      [Comparar el estimando predictivo ($partial E[Y | X,D] / partial D$) con el causal ($E[Y(1)-Y(0) | X]$)],
      [Definir explícitamente $Y(1), Y(0)$ y especificar el estimando causal de interés. Si se entrena un ML sobre $(Y,D,X)$ y se computa la derivada respecto a $D$, el resultado NO es un efecto causal, sino la derivada parcial de la mejor predicción de $Y$, que mezcla variación causal con variación espuria],
      table.hline(stroke: 0.4pt),
      [Omitir confusores],
      [Sesgo por variable omitida no corregible con más datos],
      [Construir un DAG y evaluar placebos],
      [Justificar el supuesto de no confusión con teoría económica o usar un diseño alternativo. El supuesto de no confusión condicional no se vuelve verdadero con más observaciones: requiere observar las covariables correctas. Si una variable confusora no está en $X$, ningún algoritmo la recupera],
      table.hline(stroke: 0.4pt),
      [Interpretar SHAP como causal],
      [Sobreinterpretación de la importancia de variables],
      [Incluir nota explícita de que SHAP es predictivo, no causal],
      [Usar CATE con validación en placebos],
      table.hline(stroke: 0.4pt),
      [Reportar RMSE como evidencia de calidad causal],
      [Falsa confianza en estimaciones sesgadas del efecto causal],
      [Comparar métricas predictivas (RMSE, $R^2$) con métricas causales (Qini, cobertura de intervalos de confianza)],
      [Validar con placebos, Qini y ground truth sintético. Un modelo puede predecir $Y$ con $R^2 = 0.99$ y producir estimaciones de CATE totalmente sesgadas],
      table.hline(stroke: 0.8pt),
    )
  ) <tab-riesgos-cap01>
]

=== Cuándo no usar este método
<sec-cap01_cuando_no>

*Límites del marco.* El marco de resultados potenciales supone _no interferencia_ (supuesto de SUTVA / no interferencia). En contextos con efectos cruzados—epidemias, redes sociales, externalidades— este supuesto se vulnera y se requieren métodos específicos (inferencia causal bajo interferencia, diseño _cluster-randomized_). El curso no aborda estos casos; ver @aronow2017 para una referencia.

==== Checklist de validación

Ver el apéndice @ap-checklists para el checklist completo de validación de métodos causales.

== Ejercicios y notas bibliográficas
<sec-cap01_ejercicios>

=== Ejercicios teóricos
<sec-cap01_ejercicios_teoricos>

+ Clasifique cada pregunta en asociación, intervención o contrafactual: (a) ¿Los alumnos con mejores notas tienen mejor salario? (b) ¿Sirve dar becas para mejorar notas? (c) ¿María habría entrado a la universidad si le hubieran dado la beca?

=== Ejercicios computacionales
<sec-cap01_ejercicios_computacionales>

+ Replique la comparación predictivo vs. causal del listado @lst-card-comparison usando #code[GradientBoostingRegressor] en lugar de #code[RandomForestRegressor]. ¿La divergencia entre el "efecto predictivo" y el coeficiente OLS aumenta o disminuye? ¿Por qué?

+ Construya un dataset sintético donde el supuesto de no confusión se vulnere deliberadamente (una variable $U$ no observada afecta tanto a $D$ como a $Y$). Muestre que OLS y bosque aleatorio producen estimaciones sesgadas, y verifique que el sesgo no disminuye al aumentar $n$.

+ Ejecute el listado @lst-collider-simulation y explique por qué al condicionar en $C$ apareció una correlación espuria entre $A$ y $B$.

=== Ejercicios aplicados
<sec-cap01_ejercicios_aplicados>

+ Sobre el dataset #code[close_college], estime el retorno a la educación con: (a) OLS sin controles, (b) OLS con cinco controles, (c) OLS con la interacción #code[educ] $times$ #code[exper]. Compare los tres coeficientes y explique conceptualmente por qué difieren.

+ Sobre el dataset #code[nsw_mixtape] (Lalonde), calcule la diferencia de medias entre tratados y controles en la variable #code[re78]. Luego estime el ATE por OLS con los controles #code[age, educ, black, hisp, marr, nodegree, re74, re75]. ¿En cuánto cambia la estimación? ¿Qué dice esto sobre el balance observacional del dataset?

=== Notas bibliográficas
<sec-cap01_notas>

#cite(<athey2017beyond>, form: "prose") provee la motivación conceptual del campo. #cite(<imbens2015causal>, form: "prose") es la referencia canónica sobre resultados potenciales. #cite(<hernan2020whatif>, form: "prose") ofrece una introducción accesible al marco contrafactual. #cite(<mullainathan2017machine>, form: "prose") discute las diferencias prácticas entre predicción y estimación causal en políticas públicas, y #cite(<kleinberg2015prediction>, form: "prose") es la referencia obligada para el argumento simétrico —cuándo la pregunta de política es genuinamente predictiva y no causal— desarrollado en la @sec-cap01_problema. #cite(<elwert2014endogenous>, form: "prose") es el tratamiento de referencia del sesgo por _collider_ simulado en el listado @lst-collider-simulation. Para una revisión técnica moderna, véanse @athey2019econometric y @chernozhukov2018applied. Adicionalmente, @pearl2009causality (disponible en español como _Causalidad_) proporciona una exposición profunda de la jerarquía causal y los modelos estructurales, cubriendo los fundamentos conceptuales que subyacen a la distinción entre los niveles de asociación, intervención y contrafactual discutidos en este capítulo.
