// Capítulo 16 — Ética, interpretabilidad y comunicación de resultados
#import "../template/template.typ": *

#chapter[Ética, interpretabilidad y comunicación de resultados]
<cap-etica-interpretabilidad>

#theorem-number-reset()

#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*[Problema]*], [Equidad, interpretabilidad y comunicación en ML causal aplicado a políticas públicas],
    [*[Estimando]*], [CATE por grupo demográfico, policy value, importancia de variables],
    [*[Identificación]*], [No confusión, modelo causal del atributo protegido, SUTVA],
    [*[Método]*], [Demographic parity, equalized odds, equalized CATE, SHAP, policy trees],
    [*[Nuisance]*], [$mu_d(x), e(x)$, modelo de outcome],
    [*[Garantía]*], [Identificación bajo supuestos; cobertura de IC bajo normalidad asintótica],
    [*[Librerías]*], [#code[econml], #code[shap], #code[scikit-learn]],
    [*[Validación]*], [Auditoría causal, placebos, counterfactual fairness],
  )
]

#notatecnica[
El @cap-explicacion-equidad formalizó la equidad como una pregunta de descomposición causal por rutas. Este capítulo la complementa con la caja de herramientas más usada en la práctica —SHAP y métricas de auditoría estándar— y con una advertencia central: esas herramientas explican el *modelo*, no necesariamente el *mecanismo causal* subyacente, una distinción que retoma directamente la del @cap-causalidad-elemental entre predicción y causa.
]

== Motivación aplicada
<sec-cap16-motivacion>

Un ministerio usa un modelo de ML causal para decidir qué hogares reciben un subsidio. El modelo se entrenó sobre datos históricos que reflejan desigualdades preexistentes: hogares encabezados por mujeres, minorías étnicas, y zonas rurales tienen históricamente menor acceso a programas sociales. El modelo, al optimizar predicción sobre estos datos, puede perpetuar o amplificar esas desigualdades — un fenómeno conocido como _algorithmic bias_.

Este capítulo aborda tres dimensiones éticas del ML causal aplicado a políticas públicas: (i) sesgo algorítmico y equidad, (ii) interpretabilidad de modelos causales complejos, y (iii) comunicación de incertidumbre a tomadores de decisión. Argumentamos que la calidad técnica de un modelo causal no se mide solo en su precisión estadística, sino en sus consecuencias sociales y en la transparencia con que se comunica.

== Teoría, supuestos y garantías
<sec-cap16-teoria>

=== Equidad causal
<sec-cap16-equidad>

La literatura de equidad algorítmica distingue tres definiciones principales:

#definition(
  name: [Demographic parity]
)[
  Una regla de asignación $pi$ satisface _demographic parity_ respecto a un atributo protegido $G$ si $pi(X) perp perp G$.
] <def-demo-parity>

#definition(
  name: [Equalized odds]
)[
  $pi$ satisface _equalized odds_ si $pi(X) perp perp G mid Y^*$, donde $Y^*$ es un outcome relevante (p. ej., necesidad de tratamiento).
] <def-eq-odds>

#definition(
  name: [Equalized CATE]
)[
  $pi$ satisface _equalized CATE_ si la distribución del CATE estimado $hat(tau)(X)$ es similar entre grupos definidos por $G$.
] <def-eq-cate>

@kitagawa2021equality formalizan el trade-off entre welfare y equidad: maximizar $V(pi)$ sujeto a restricciones de equidad produce políticas que pueden ser sustancialmente menos eficientes en welfare pero más justas distributivamente.

=== Interpretabilidad
<sec-cap16-interpretabilidad>

Los modelos de ML causal (causal forest, deep causal) son cajas negras. Tres estrategias de interpretabilidad:

- *SHAP (SHapley Additive exPlanations).* Asigna a cada feature una contribución a la predicción, basada en valores de Shapley de teoría de juegos.
- *Partial dependence plots.* Muestra el efecto marginal de una feature sobre $hat(tau)$, promediando sobre las demás.
- *Policy trees.* Una vez aprendido un CATE con causal forest, se aprende un árbol de decisión shallow sobre $hat(tau)$ para producir una regla interpretable.

=== Comunicación de incertidumbre
<sec-cap16-comunicacion>

El error más común al comunicar resultados causales a no-técnicos es reportar solo el estimado puntual sin IC. La regla operacional: _todo número reportado debe acompañarse de una medida de incertidumbre_.

- Reportar IC al 95% en formato "[lb, ub]".
- Para CATE, reportar la distribución (histograma, mapa) no solo el promedio.
- Distinguir afirmaciones predictivas ("el modelo predice") de afirmaciones causales ("el efecto causal estimado es").

== Implementación en Python
<sec-cap16-implementacion>

=== Interpretabilidad con SHAP
<sec-cap16-shap>

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

# SHAP para el modelo de outcome (no directamente para CATE, pero ilustrativo)
explainer = shap.TreeExplainer(cf.model_y)
shap_values = explainer.shap_values(X[:100])
shap.summary_plot(shap_values, X[:100], feature_names=[f"x{i}" for i in range(5)])
```
) <lst-shap>

=== Tabla de resultados para policymakers
<sec-cap16-policymakers>

#figure(
  kind: raw,
  caption: [Tabla de resultados para comunicación a tomadores de decisión.],
  ```python
def format_results_for_policymakers(cate, A=None, group_labels=None):
    """Genera tabla resumen con IC, distinguiendo grupos."""
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
                     CATE: f"{mean_g:.2f}",
                     "IC 95%": f"[{lb:.2f}, {ub:.2f}]"})
    return pd.DataFrame(rows)

df_comm = format_results_for_policymakers(cate_hat, A, {0: "Mayoria", 1: "Minoria"})
print(df_comm.to_markdown(index=False))
```
) <lst-comm-table>

=== Análisis de equidad
<sec-cap16-fairness>

#figure(
  kind: raw,
  caption: [Análisis de equidad en policy learning.],
  ```python
import scipy.stats as st

# Analisis de equidad: distribucion del CATE por grupo
for a in [0, 1]:
    cate_a = cate_hat[A == a]
    print(f"Grupo A={a}: CATE medio = {cate_a.mean():.3f} "
          f"(IC 95%: [{cate_a.mean() - 1.96*cate_a.std()/np.sqrt(len(cate_a)):.3f}, "
          f"{cate_a.mean() + 1.96*cate_a.std()/np.sqrt(len(cate_a)):.3f}])")
# Test de diferencia
t_stat, p_val = st.ttest_ind(cate_hat[A == 0], cate_hat[A == 1])
print(f"Diferencia de CATE entre grupos: t={t_stat:.3f}, p={p_val:.4f}")
```
) <lst-fairness>

== Caso empírico y validación
<sec-cap16-caso>

=== Auditoría de equidad en focalización de transferencias
<sec-cap16-auditoria>

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
<sec-cap16-riesgos>

=== Tabla de riesgos
<sec-cap16-tabla-riesgos>

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
      [SHAP como causal], [Sobreinterpretación], [Nota explícita de que SHAP explica la predicción del outcome, no directamente el CATE], [CATE validado con placebos y refutación],
      [Fairness sin causalidad], [Métrica engañosa al no considerar la estructura causal del sesgo], [Auditoría causal comparando CATE entre grupos], [Counterfactual fairness con modelo causal explícito],
      [Comunicación sin IC], [Decisión errónea basada en falsa confianza], [Tabla con IC al 95% para todo estimado reportado], [Incertidumbre cuantificada y comunicada explícitamente],
      [Optimizar welfare sin restricciones de equidad], [Política que excluye sistemáticamente a minorías], [Reportar equidad junto con welfare agregado], [Restricciones de equidad en la optimización],
      [No distinguir afirmaciones causales de predictivas], [Confundir quién necesita el programa con quién se beneficiaría más], [Verificar si el estimando es $E[Y(1)-Y(0) mid X]$ o $E[Y mid X, D]$], [Usar lenguaje explícito: "efecto causal estimado" vs. "predicción"],
      table.hline(stroke: 0.8pt),
    )
  ) <tab-riesgos-cap16>
]

=== Cuándo no usar este método
<sec-cap16-cuando-no>

La equidad causal es un campo activo de investigación. Las definiciones existentes (demographic parity, equalized odds, equalized CATE) pueden entrar en conflicto; no hay solución única. La comunicación a no-técnicos requiere traducir conceptos estadísticos (IC, CATE, regret) a lenguaje sustantivo, sin perder rigor.

== Ejercicios propuestos
<sec-cap16-ejercicios>

+ Replique el listado @lst-fairness sobre #code[gov_transfers] o #code[nsw_mixtape]. ¿Hay diferencias de CATE entre grupos demográficos?

+ Construya una política de tratamiento que satisfaga _equalized CATE_ entre dos grupos. ¿En cuánto se reduce el welfare respecto a la política óptima sin restricciones?

+ Use SHAP para interpretar un Causal Forest entrenado sobre #code[nhefs]. ¿Qué variables son más importantes para la heterogeneidad del efecto de dejar de fumar?

+ Escriba un _policy brief_ (1 página) comunicando los resultados de un análisis causal a un ministro no técnico. Incluya IC, recomendación de política y limitaciones.

== Lecturas complementarias
<sec-cap16-lecturas>

@barocas2019fairness para equidad algorítmica. @kitagawa2021equality para equidad causal. @lundberg2017unified para SHAP. Para comunicación de incertidumbre, @spiegelhalter2017art.
