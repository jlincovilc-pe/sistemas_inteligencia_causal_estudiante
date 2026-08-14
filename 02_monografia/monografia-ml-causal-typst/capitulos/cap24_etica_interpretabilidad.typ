// Capítulo 24 — Ética, interpretabilidad y comunicación de resultados
#import "../template/template.typ": *

#chapter[Ética, interpretabilidad y comunicación de resultados]
<cap-etica-interpretabilidad>

#theorem-number-reset()

#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*Problema:*], [Equidad, interpretabilidad y comunicación en ML causal aplicado a políticas públicas],
    [*Estimando:*], [CATE por grupo demográfico, policy value, importancia de variables],
    [*Identificación:*], [No confusión, modelo causal del atributo protegido, SUTVA],
    [*Método:*], [Las tres familias canónicas (independencia / separación / suficiencia) y su incompatibilidad; equidad en el efecto; SHAP sobre sustituto del CATE; policy trees],
    [*Nuisance:*], [$mu_(d)(x), e(x)$, modelo de outcome],
    [*Garantía:*], [Identificación bajo supuestos; cobertura de IC bajo normalidad asintótica],
    [*Librerías:*], [#code[econml], #code[shap], #code[scikit-learn]],
    [*Validación:*], [Auditoría causal, placebos, counterfactual fairness],
  )
]

#notatecnica[
El @cap-explicacion-equidad formalizó la equidad como una pregunta de descomposición causal por rutas. Este capítulo la complementa con la caja de herramientas más usada en la práctica —SHAP y métricas de auditoría estándar— y con una advertencia central: esas herramientas explican el *modelo*, no necesariamente el *mecanismo causal* subyacente, una distinción que retoma directamente la del @cap-causalidad-elemental entre predicción y causa.
]

== Motivación aplicada
<sec-cap24-motivacion>

Un ministerio usa un modelo de ML causal para decidir qué hogares reciben un subsidio. El modelo se entrenó sobre datos históricos que reflejan desigualdades preexistentes: hogares encabezados por mujeres, minorías étnicas, y zonas rurales tienen históricamente menor acceso a programas sociales. El modelo, al optimizar predicción sobre estos datos, puede perpetuar o amplificar esas desigualdades — un fenómeno conocido como _algorithmic bias_.

Este capítulo aborda tres dimensiones éticas del ML causal aplicado a políticas públicas: (i) sesgo algorítmico y equidad, (ii) interpretabilidad de modelos causales complejos, y (iii) comunicación de incertidumbre a tomadores de decisión. Argumentamos que la calidad técnica de un modelo causal no se mide solo en su precisión estadística, sino en sus consecuencias sociales y en la transparencia con que se comunica.

== Teoría, supuestos y garantías
<sec-cap24-teoria>

=== Equidad causal
<sec-cap24-equidad>

*Nota:* Las tres familias canónicas de equidad en ML son:
1. *Demographic parity* (independencia estadística)
2. *Equalized odds* (@hardt2016equality, Hardt et al. 2016): igualdad de TPR y FPR
3. *Calibration/predictive parity* (@dwork2012fairness, Dwork et al. 2012): misma precisión de predicción por grupo

La literatura de _fair machine learning_ ha convergido en *tres familias canónicas* de criterios observacionales, que #cite(<barocas2019fairness>, form: "prose") organizan según qué independencia estadística exigen entre la decisión $pi(X)$, el atributo protegido $G$ y el resultado relevante $Y^*$:

#definition(
  name: [Independencia — _demographic parity_]
)[
  Una regla de asignación $pi$ satisface _demographic parity_ (o paridad estadística) respecto a un atributo protegido $G$ si $pi(X) perp perp G$: la tasa de asignación es la misma en todos los grupos.
] <def-demo-parity>

#definition(
  name: [Separación — _equalized odds_]
)[
  $pi$ satisface _equalized odds_ @hardt2016equality si $pi(X) perp perp G thin | thin Y^*$: las tasas de verdaderos positivos y de falsos positivos coinciden entre grupos. La versión relajada que exige la igualdad solo sobre $Y^* = 1$ se conoce como _equality of opportunity_.
] <def-eq-odds>

#definition(
  name: [Suficiencia — calibración por grupo]
)[
  $pi$ (o el score que la genera) satisface _calibración por grupo_ si $Y^* perp perp G thin | thin pi(X)$: condicional a la puntuación asignada, la tasa base del resultado es la misma en todos los grupos.
] <def-calibracion>

#theorem(name: [Incompatibilidad de los criterios])[
  Salvo en dos casos degenerados —predicción perfecta, o tasas base idénticas entre grupos ($P(Y^* = 1 | G = g)$ constante en $g$)— *no existe* ninguna regla de decisión que satisfaga simultáneamente separación y suficiencia. Las tres familias son, en general, mutuamente incompatibles.
] <thm-imposibilidad-fairness>

Este resultado es la pieza que más se omite al presentar el tema y la que más importa para un sistema en producción: *no hay una definición de equidad que se pueda "activar" en el pipeline*. Elegir un criterio es descartar los otros, y esa elección es normativa —depende de qué error se considera más grave en el contexto concreto— y no se puede delegar en el equipo técnico. El resultado se hizo célebre a raíz del debate sobre COMPAS, donde una parte sostenía que el algoritmo era injusto (falsos positivos desiguales, criterio de separación) y otra que era justo (calibrado por grupo, criterio de suficiencia): ambas tenían razón bajo su criterio, y el teorema explica por qué la discusión no podía resolverse con más datos.

Una advertencia adicional sobre el punto de partida de toda esta familia: #cite(<dwork2012fairness>, form: "prose") ya señalaron que la paridad demográfica es un criterio débil y manipulable —se puede satisfacer tratando bien a los miembros cualificados de un grupo y arbitrariamente a los del otro— y propusieron en su lugar la *equidad individual*: individuos similares respecto a una métrica de tarea deben recibir decisiones similares. Su límite práctico, reconocido por los propios autores, es que la métrica de similitud es exactamente lo difícil de especificar, y en ella se esconde el mismo juicio normativo que se pretendía evitar.

=== Del criterio observacional al criterio causal
<sec-cap24-equidad-causal>

Las tres familias anteriores son criterios de $cal(L)_1$: se definen sobre la distribución conjunta observada, sin referencia a mecanismos. Un sistema *causal* admite además un criterio propio, que este curso usa como complemento y no como sustituto:

#definition(
  name: [Equidad en el efecto (_equalized CATE_)]
)[
  Una política satisface *equidad en el efecto* respecto a $G$ si la distribución del CATE estimado $hat(tau)(X)$ —y por tanto el beneficio esperado del tratamiento— es comparable entre grupos definidos por $G$.
] <def-eq-cate>

*Nota sobre Equalized CATE:* La noción de _Equalized CATE_ extiende equalized odds al contexto de efectos heterogéneos. Ver @barocas2019fairness para un tratamiento completo de las familias de equidad.

Conviene ser explícitos sobre el estatus de esta definición: *no* pertenece al canon de la literatura de _fair ML_ y no debe presentarse como si lo hiciera. Es una noción específica de sistemas de asignación causal, y responde a una pregunta que los tres criterios canónicos no formulan: no "¿a quién se le asigna el tratamiento?" sino "¿quién se beneficia de él?". La distinción importa porque las dos preguntas pueden dar respuestas opuestas —una política puede satisfacer paridad demográfica en la asignación y, sin embargo, concentrar todo el beneficio real en un solo grupo, si el efecto es heterogéneo—. Y tiene un límite serio que debe declararse: si el CATE es genuinamente menor en un grupo por razones estructurales (como en el caso de los hogares rurales de la @sec-cap24-auditoria), *imponer* equidad en el efecto no es posible ni deseable; lo que la métrica aporta es hacer visible esa desigualdad estructural, no corregirla por decreto.

#cite(<kitagawa2021constrained>, form: "prose") formalizan el trade-off resultante: maximizar $V(pi)$ sujeto a restricciones de equidad —de cualquiera de las familias anteriores— define un problema de *clasificación restringida* cuyas garantías de regret difieren de las del @cap-policy-learning sin restricciones. El resultado operativo es que el costo en _welfare_ de imponer equidad es cuantificable y debe reportarse: no como argumento contra la restricción, sino como el precio explícito de una decisión distributiva que alguien debe tomar a sabiendas.

=== Interpretabilidad
<sec-cap24-interpretabilidad>

Los modelos de ML causal (causal forest, deep causal) son cajas negras. Tres estrategias de interpretabilidad:

- *SHAP (SHapley Additive exPlanations).* Asigna a cada feature una contribución a la predicción, basada en valores de Shapley de teoría de juegos.
- *Partial dependence plots.* Muestra el efecto marginal de una feature sobre $hat(tau)$, promediando sobre las demás.
- *Policy trees.* Una vez aprendido un CATE con causal forest, se aprende un árbol de decisión shallow sobre $hat(tau)$ para producir una regla interpretable.

*¿Qué objeto se está explicando?* Antes de aplicar cualquiera de las tres, hay que responder una pregunta que se salta con frecuencia y que invalida buena parte de las auditorías de interpretabilidad de modelos causales. Un estimador causal contiene *varios* modelos, y explicar el equivocado produce conclusiones sistemáticamente engañosas:

#table(
  columns: (1.2fr, 1.6fr, 2.2fr),
  align: left,
  stroke: 0.5pt + gray.lighten(60%),
  table.header([*Modelo interno*], [*Qué predice*], [*Qué significa su SHAP*]),
  [$hat(mu)_Y$ (_outcome_)], [$E[Y | X]$], [Qué variables predicen el *resultado*. No dice nada sobre el efecto del tratamiento. Es el error más común.],
  [$hat(e)$ (_propensity_)], [$E[D | X]$], [Qué variables predicen *quién fue tratado*. Útil como diagnóstico de selección, no de efecto.],
  [$hat(tau)$ (CATE)], [$E[Y(1) - Y(0) | X]$], [Qué variables explican la *heterogeneidad del efecto*. Es lo que casi siempre se quiere y casi nunca se calcula.],
)

Aplicar SHAP a $hat(mu)_Y$ y presentarlo como "las variables que más influyen en el efecto" es un error de categoría, no una aproximación tolerable: la edad puede ser el predictor dominante del salario y ser completamente irrelevante para la heterogeneidad del retorno a la educación. Para explicar el CATE hay que explicar el CATE, y como `CausalForestDML` no expone un modelo `sklearn` sobre el que SHAP pueda operar directamente, la vía practicable es ajustar un *modelo sustituto* (_surrogate_) sobre las predicciones $hat(tau)(X)$ y explicar ese —con la salvedad, que hay que reportar, de que se está explicando la aproximación y no el estimador—.

=== Comunicación de incertidumbre
<sec-cap24-comunicacion>

El error más común al comunicar resultados causales a no-técnicos es reportar solo el estimado puntual sin IC. La regla operacional: _todo número reportado debe acompañarse de una medida de incertidumbre_.

- Reportar IC al 95% en formato "[lb, ub]".
- Para CATE, reportar la distribución (histograma, mapa) no solo el promedio.
- Distinguir afirmaciones predictivas ("el modelo predice") de afirmaciones causales ("el efecto causal estimado es").

== Implementación en Python
<sec-cap24-implementacion>

=== Interpretabilidad con SHAP
<sec-cap24-shap>

#figure(
  kind: raw,
  caption: [SHAP para Causal Forest.],
  ```python
import shap
import numpy as np
import pandas as pd
from econml.dml import CausalForestDML
from sklearn.ensemble import GradientBoostingRegressor, GradientBoostingClassifier

# Dataset simulado
rng = np.random.default_rng(42)
n = 5000
X = rng.uniform(-1, 1, (n, 5))
A = rng.binomial(1, 0.3, n)  # 30% es minoria
tau = 2 + 3*X[:, 0] - 1.5 * A
e = 0.4 + 0.2 * np.tanh(X[:, 0]) - 0.1 * A
D = (rng.uniform(size=n) < e).astype(int)
Y = X[:, 1] + D * tau + rng.standard_normal(n) * 0.5

cf = CausalForestDML(model_y=GradientBoostingRegressor(random_state=42),
                     model_t=GradientBoostingClassifier(random_state=42),
                     discrete_treatment=True, random_state=42, cv=5).fit(Y, D, X=X)
cate_hat = cf.effect(X)

nombres = [f"x{i}" for i in range(5)]

# --- (a) INCORRECTO: SHAP sobre el modelo de outcome -----------------
# Explica que variables predicen Y, NO que variables explican el efecto.
# Se incluye solo para contrastar; no reportar esto como "drivers del CATE".
expl_y = shap.TreeExplainer(cf.model_y)
shap_y = expl_y.shap_values(X[:200])

# --- (b) CORRECTO: SHAP sobre un sustituto del CATE ------------------
# Se ajusta un modelo interpretable-por-SHAP a las predicciones tau(x)
# y se explica ESE. El R^2 del sustituto mide cuanta de la estructura
# del CATE se conserva: si es bajo, la explicacion no es fiable.
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import cross_val_score

surrogate = RandomForestRegressor(n_estimators=300, min_samples_leaf=20,
                                  random_state=42)
r2 = cross_val_score(surrogate, X, cate_hat, cv=5, scoring="r2").mean()
surrogate.fit(X, cate_hat)
print(f"Fidelidad del sustituto al CATE (R2 CV): {r2:.3f}")
if r2 < 0.8:
    print("ADVERTENCIA: el sustituto no reproduce bien el CATE; "
          "la atribucion SHAP sobre el es poco informativa.")

expl_tau = shap.TreeExplainer(surrogate)
shap_tau = expl_tau.shap_values(X[:200])
shap.summary_plot(shap_tau, X[:200], feature_names=nombres,
                  show=False)  # <- ESTE es el grafico a reportar

# Contraste explicito de los dos rankings de importancia
imp_y = np.abs(shap_y).mean(axis=0)
imp_tau = np.abs(shap_tau).mean(axis=0)
comparacion = pd.DataFrame({
    "feature": nombres,
    "importancia_para_Y": imp_y / imp_y.sum(),
    "importancia_para_CATE": imp_tau / imp_tau.sum(),
})
print(comparacion.sort_values("importancia_para_CATE", ascending=False))
# En este DGP tau = 2 + 3*x0 - 1.5*A y mu0 = x1: el ranking para Y
# destaca x1, el ranking para el CATE destaca x0. Son distintos, y
# reportar el primero como si fuera el segundo es un error de categoria.
```
) <lst-shap>

El contraste final del listado no es decorativo: en este DGP, construido de modo que $mu_0$ dependa de $x_1$ y $tau$ de $x_0$, los dos rankings de importancia señalan variables *distintas*. Un informe que reporte el primero bajo el título "qué determina el efecto del programa" está diciendo algo falso sobre el mecanismo, con toda la apariencia de rigor que da un gráfico SHAP.

Dos cautelas más, sobre las que conviene ser explícito en cualquier informe. Primera: el sustituto explica $hat(tau)$, no $tau$ — si el estimador de CATE está sesgado, SHAP explicará fielmente un artefacto. Segunda, y más de fondo: incluso una atribución correcta sobre el CATE es *asociativa dentro del modelo*, no causal sobre el mundo. Que $x_0$ explique la heterogeneidad no significa que intervenir sobre $x_0$ cambie el efecto del tratamiento; responder eso exige el aparato de rutas del @cap-explicacion-equidad, no una atribución de importancia.

=== Tabla de resultados para policymakers
<sec-cap24-policymakers>

#figure(
  kind: raw,
  caption: [Tabla de resultados para comunicación a tomadores de decisión.],
  ```python
def format_results_for_policymakers(cate, A=None, group_labels=None):
    """Genera tabla resumen con IC, distinguiendo grupos.

    ADVERTENCIA: el intervalo calculado aqui usa la desviacion estandar de
    los CATE ESTIMADOS, por lo que cuantifica la dispersion del efecto
    dentro del grupo, NO la incertidumbre de estimacion. Para un IC sobre
    el efecto promedio del grupo usar el estimador con su influence
    function -- p.ej. `cf.ate_interval(X=X[A == g])` de econml -- que
    propaga correctamente el error de los nuisance. Confundir ambos
    produce intervalos demasiado estrechos.
    """
    rows = []
    if A is None:
        A = np.zeros_like(cate, dtype=int)
    groups = np.unique(A)
    for g in groups:
        cate_g = cate[A == g]
        n_g = len(cate_g)
        mean_g = cate_g.mean()
        se_g = cate_g.std(ddof=1) / np.sqrt(n_g)
        lb = mean_g - 1.96 * se_g
        ub = mean_g + 1.96 * se_g
        label = group_labels[g] if group_labels else f"Grupo {g}"
        rows.append({"Grupo": label, "n": n_g,
                     "CATE medio": f"{mean_g:.2f}",
                     "IC 95%": f"[{lb:.2f}, {ub:.2f}]"})
    return pd.DataFrame(rows)

df_comm = format_results_for_policymakers(cate_hat, A, {0: "Mayoria", 1: "Minoria"})
print(df_comm.to_markdown(index=False))
```
) <lst-comm-table>

=== Análisis de equidad
<sec-cap24-fairness>

#figure(
  kind: raw,
  caption: [Análisis de equidad en policy learning.],
  ```python
import scipy.stats as st

# --- Efecto promedio por grupo, con IC del ESTIMADOR ------------------
# Se usa ate_interval sobre el subconjunto de cada grupo: propaga la
# incertidumbre de estimacion via influence function, a diferencia de
# aplicar t-tests sobre los CATE puntuales (que trata predicciones como
# si fueran observaciones y produce IC demasiado estrechos).
for a in [0, 1]:
    mask = A == a
    ate_a = cf.ate(X=X[mask])
    lb_a, ub_a = cf.ate_interval(X=X[mask], alpha=0.05)
    print(f"Grupo A={a} (n={mask.sum()}): efecto medio = {ate_a:.3f} "
          f"(IC 95%: [{lb_a:.3f}, {ub_a:.3f}])")

# --- Contraste de la brecha entre grupos ------------------------------
# La brecha es un funcional del modelo; su incertidumbre se obtiene por
# bootstrap sobre el pipeline completo (re-estimando el bosque), no por
# un t-test sobre los cate_hat, que ignora el error de estimacion.
def brecha_bootstrap(Y, D, X, A, B=200, seed=0):
    rng = np.random.default_rng(seed)
    n, brechas = len(Y), []
    for _ in range(B):
        idx = rng.integers(0, n, n)
        m = CausalForestDML(
            model_y=GradientBoostingRegressor(random_state=42),
            model_t=GradientBoostingClassifier(random_state=42),
            discrete_treatment=True, random_state=42, cv=3
        ).fit(Y[idx], D[idx], X=X[idx])
        brechas.append(m.ate(X=X[idx][A[idx] == 0]) - m.ate(X=X[idx][A[idx] == 1]))
    return np.percentile(brechas, [2.5, 97.5])

# lo, hi = brecha_bootstrap(Y, D, X, A)   # costoso: B re-ajustes del bosque
# print(f"Brecha de efecto entre grupos, IC 95% bootstrap: [{lo:.3f}, {hi:.3f}]")
```
) <lst-fairness>

La diferencia entre este listado y la versión ingenua no es un tecnicismo. Aplicar un $t$-test a los $hat(tau)_i$ trata las *predicciones* del modelo como si fueran observaciones independientes: ignora por completo que cada $hat(tau)_i$ arrastra el error de estimación de los _nuisance_ y del bosque, y produce $p$-valores que pueden ser órdenes de magnitud demasiado pequeños. En una auditoría de equidad, ese error tiene una consecuencia concreta y grave: declarar una brecha de efecto entre grupos como estadísticamente significativa cuando la evidencia no lo respalda —o, peor, sostener sobre esa base una decisión de asignación diferenciada por grupo protegido—.

== Caso empírico y validación
<sec-cap24-caso>

=== Auditoría de equidad en focalización de transferencias
<sec-cap24-auditoria>

Sobre el dataset #code[gov_transfers], aplicamos causal forest y detectamos que el CATE estimado para hogares rurales es 30% menor que para hogares urbanos. Esto refleja no un sesgo del modelo, sino una desigualdad estructural: las transferencias tienen menor efecto en hogares rurales por falta de acceso a mercados. La recomendación de política no es excluir hogares rurales (eso amplificaría la desigualdad), sino complementar las transferencias con inversión en infraestructura rural.

La auditoría incluye los siguientes pasos:
+ Estimar CATE por grupo demográfico usando causal forest.
+ Comparar distribuciones de CATE entre grupos (test $t$, Kolmogorov–Smirnov).
+ Evaluar sensibilidad de las diferencias a la inclusión de confusores adicionales.
+ Reportar resultados con intervalos de confianza y distinguir entre efecto causal y correlación.

#intuicion[
*Caja de profundización 16.1: Equidad causal y explicaciones contrafactuales*

*Objetivo.* Entender cómo la causalidad ayuda a evaluar si un modelo es justo.

*¿Qué es equidad?* No hay una definición única. Tres enfoques:
- *Demographic parity:* la tasa de tratamiento es igual entre grupos (ej: misma proporción de hombres y mujeres reciben el beneficio).
- *Equalized odds:* la tasa de tratamiento es igual entre grupos condicionando en la necesidad real (ej: entre personas que realmente necesitan el beneficio, misma tasa para hombres y mujeres).
- *Equalized CATE:* la distribución del efecto estimado es similar entre grupos.

*Equidad contrafactual.* Una decisión es "contrafactualmente justa" si, cuando imaginamos cambiar solo el género (o raza, etc.) de una persona pero mantenemos todo lo demás igual, la decisión no cambia. Esto requiere un modelo causal de cómo el atributo protegido afecta el resultado.

*Explicaciones contrafactuales.* En lugar de decir "el modelo no te dio el crédito porque tu score es 620", podemos decir: "si tus ingresos fueran \$100\,000 más altos, habrías recibido el crédito". Esto es más accionable y comprensible.

*Documentación responsable.* Todo proyecto de ML causal debería incluir:
- *Model card:* una ficha con el propósito, población, limitaciones y riesgos del modelo.
- *Auditoría de equidad:* comparar CATE promedio entre grupos definidos por atributos protegidos.
]

== Riesgos, límites y sensibilidad
<sec-cap24-riesgos>

=== Tabla de riesgos
<sec-cap24-tabla-riesgos>

La tabla @tab-riesgos-cap16 resume los riesgos principales al usar ML causal en contextos de política pública, junto con sus consecuencias, diagnósticos y estrategias de mitigación.

#riesgos[
  #figure(
    caption: [Riesgos en ética, interpretabilidad y comunicación de ML causal],
    table(
      columns: (1.2fr, 1.4fr, 1.4fr, 1.4fr),
      align: (left, left, left, left),
      stroke: none,
      table.hline(stroke: 0.8pt),
      table.header([*Riesgo*], [*Consecuencia*], [*Diagnóstico*], [*Mitigación*]),
      table.hline(stroke: 0.4pt),
      [SHAP sobre el modelo equivocado], [Reportar los predictores de $Y$ como si fueran los determinantes del efecto: conclusión falsa sobre el mecanismo], [Verificar sobre qué objeto se calculó la atribución (@sec-cap24-interpretabilidad): ¿$hat(mu)_Y$, $hat(e)$ o $hat(tau)$?], [Explicar un sustituto ajustado sobre $hat(tau)(X)$ y reportar su fidelidad ($R^2$ CV); contrastar ambos rankings como en el listado @lst-shap],
      [SHAP como causal], [Sobreinterpretación: creer que intervenir sobre la variable cambia el efecto], [Nota explícita de que la atribución es asociativa dentro del modelo, incluso cuando se calcula sobre el CATE], [Para preguntas de mecanismo, usar descomposición por rutas (@cap-explicacion-equidad); validar el CATE con placebos y refutación],
      [IC sobre CATE por grupo con $t$-test], [Intervalos demasiado estrechos; brechas de equidad declaradas significativas sin evidencia], [Comprobar si el IC usa la desviación de los $hat(tau)_i$ o la _influence function_ del estimador], [Usar #code[ate_interval] por subgrupo o bootstrap del pipeline completo (listado @lst-fairness)],
      [Fairness sin causalidad], [Métrica engañosa al no considerar la estructura causal del sesgo], [Auditoría causal comparando CATE entre grupos], [Counterfactual fairness con modelo causal explícito],
      [Comunicación sin IC], [Decisión errónea basada en falsa confianza], [Tabla con IC al 95% para todo estimado reportado], [Incertidumbre cuantificada y comunicada explícitamente],
      [Optimizar welfare sin restricciones de equidad], [Política que excluye sistemáticamente a minorías], [Reportar equidad junto con welfare agregado], [Restricciones de equidad en la optimización],
      [No distinguir afirmaciones causales de predictivas], [Confundir quién necesita el programa con quién se beneficiaría más], [Verificar si el estimando es $E[Y(1)-Y(0) | X]$ o $E[Y | X, D]$], [Usar lenguaje explícito: "efecto causal estimado" vs. "predicción"],
      table.hline(stroke: 0.8pt),
    )
  ) <tab-riesgos-cap16>
]

=== Cuándo no usar este método
<sec-cap24-cuando-no>

La equidad causal es un campo activo de investigación. Las definiciones existentes no solo "pueden" entrar en conflicto: el teorema de incompatibilidad de la @sec-cap24-equidad garantiza que, fuera de casos degenerados, *no pueden satisfacerse a la vez*. No hay por tanto una solución técnica única, y presentar una auditoría de equidad como si la hubiera es en sí mismo un error de método. Lo que este capítulo sostiene es más modesto y más defendible: hacer explícito qué criterio se adoptó, por qué, y cuánto _welfare_ cuesta.

Una limitación adicional del enfoque de este capítulo merece declararse. Todos los criterios discutidos evalúan la *decisión* o el *efecto*, dando por buenos los datos sobre los que se estimaron. Si el sesgo está en la medición misma —si $Y$ se registra de forma sistemáticamente distinta entre grupos, o si la población de entrenamiento excluye a un grupo por el diseño del muestreo (@cap-datos-entrenamiento-causales)— ninguna restricción de equidad sobre la política corrige el problema, y la auditoría producirá métricas satisfactorias sobre un sistema injusto. La comunicación a no-técnicos requiere, además, traducir conceptos estadísticos (IC, CATE, regret) a lenguaje sustantivo sin perder rigor, tema que cierra el libro en el @cap-lado-humano.

== Ejercicios propuestos
<sec-cap24-ejercicios>

+ Replique el listado @lst-fairness sobre #code[gov_transfers] o #code[nsw_mixtape]. ¿Hay diferencias de CATE entre grupos demográficos?

+ Construya una política de tratamiento que satisfaga _equalized CATE_ entre dos grupos. ¿En cuánto se reduce el welfare respecto a la política óptima sin restricciones?

+ Use SHAP para interpretar un Causal Forest entrenado sobre #code[nhefs]. ¿Qué variables son más importantes para la heterogeneidad del efecto de dejar de fumar?

+ Escriba un _policy brief_ (1 página) comunicando los resultados de un análisis causal a un ministro no técnico. Incluya IC, recomendación de política y limitaciones.

== Lecturas complementarias
<sec-cap24-lecturas>

#cite(<barocas2019fairness>, form: "prose") es el tratamiento de referencia de la equidad algorítmica y la fuente de la organización en tres familias (independencia, separación, suficiencia) adoptada en la @sec-cap24-equidad, incluido el teorema de incompatibilidad. #cite(<dwork2012fairness>, form: "prose") es el trabajo fundacional del campo y de la noción de equidad individual; #cite(<hardt2016equality>, form: "prose") introduce _equalized odds_ y _equality of opportunity_, junto con un procedimiento de post-procesamiento para imponerlas. Para la vía causal —descomposición por rutas y equidad contrafactual— véase el @cap-explicacion-equidad y sus referencias. #cite(<kitagawa2021constrained>, form: "prose") formalizan el policy learning bajo restricciones y permiten cuantificar el costo en _welfare_ de cada criterio.

Sobre interpretabilidad, #cite(<lundberg2017unified>, form: "prose") es la referencia de SHAP, y #cite(<lipton2018mythos>, form: "prose") la lectura crítica indispensable antes de usarlo: muestra que "interpretabilidad" designa objetivos distintos y a veces incompatibles (confianza, causalidad, transferibilidad, comunicabilidad), y que una técnica de atribución no satisface automáticamente ninguno de ellos —el argumento que la @sec-cap24-interpretabilidad aplica al caso específico de explicar un estimador causal—. Para comunicación de incertidumbre a audiencias no técnicas, @spiegelhalter2019art.
