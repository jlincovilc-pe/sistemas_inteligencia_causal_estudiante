// Apéndice F — Checklists por método
#import "../template/template.typ": *

#chapter[Checklists por método]
<ap-checklists>

#theorem-number-reset()

== Checklist DML
<sec-apF_dml>

#checklist[
  - Supuesto de no confusión justificado.
  - Soporte común verificado.
  - _Nuisance_ evaluado fuera de muestra.
  - _Cross-fitting_ correcto.
  - _Influence function_ calculada.
  - Intervalos de confianza reportados.
  - _Placebos_ realizados.
  - Sensibilidad a _learners_ reportada.
]

== Checklist meta-learners
<sec-apF_metalearners>

#checklist[
  - S-learner no confunde el efecto con las covariables (incluir interacciones).
  - T-learner no sufre por desbalance extremo entre grupos.
  - X-learner utilizado cuando hay desbalance entre tratados y controles.
  - R-learner implementado con _cross-fitting_ y _score_ ortogonal.
  - Modelos _nuisance_ evaluados fuera de muestra.
  - Meta-learner elegido según los supuestos del problema.
  - Intervalos de confianza construidos por _bootstrap_ o _influence function_.
]

== Checklist causal forest
<sec-apF_causal_forest>

#checklist[
  - _Honesty_ garantizada en la construcción de los árboles.
  - Número de árboles suficiente para estabilidad del CATE.
  - Criterio de _splitting_ basado en heterogeneidad de efectos.
  - _Propensity scores_ estimados y calibrados.
  - Supuesto de _overlap_ verificado.
  - BLP/BEST/CLAN ejecutados vía #code[econml.validate.DRtester]; $beta_2$ reportado con $p$-valor.
  - Inferencia válida para ATE y CATE.
]

== Checklist PDS
<sec-apF_pds>

#checklist[
  - Supuesto de _sparsity_ plausible en el contexto aplicado.
  - Doble selección correctamente implementada (_outcome_ y tratamiento).
  - Parámetro $lambda$ seleccionado por validación cruzada.
  - Inferencia post-selección válida (errores estándar no distorsionados).
  - Número de regresores menor que el tamaño muestral.
  - Errores estándar robustos a heterocedasticidad reportados.
]

== Checklist panel/DMLIV
<sec-apF_panel_dmliv>

#checklist[
  - Efectos fijos absorbentes de _shocks_ comunes no observados.
  - Errores estándar clusterizados a nivel de unidad _panel_.
  - Instrumento válido (exogeneidad y exclusión justificadas).
  - Instrumento relevante ($F$-statistic $> 10$ en primera etapa).
  - _Cross-fitting_ correcto para DMLIV.
  - Test de sobreidentificación reportado si aplica.
  - Inferencia robusta a instrumentos débiles si el $F$ es bajo.
]

== Checklist policy learning
<sec-apF_policy_learning>

#checklist[
  - Criterio de bienestar (_policy value_) formalmente definido.
  - Restricción de presupuesto especificada.
  - Restricciones de equidad consideradas en la optimización.
  - Política aprendida interpretable y comunicable.
  - _Welfare regret_ acotado.
  - Política evaluada fuera de muestra.
  - IC del _policy value_ vía _influence function_ (@sec-cap11-estimacion); test de diferencia al comparar dos políticas.
]

== Checklist uplift
<sec-apF_uplift>

#checklist[
  - Curva Qini reportada y visualizada.
  - Costos de intervención explícitamente definidos.
  - _Ranking_ de unidades estable en submuestras.
  - Tratamiento y control balanceados en cada _fold_.
  - AUUC reportado como métrica de _ranking_.
  - Comparación con asignación aleatoria como _baseline_.
]

== Checklist SCM/matrix completion
<sec-apF_scm_mc>

#checklist[
  - Tendencia pre-tratamiento paralela verificada visualmente.
  - _Pool_ de _donors_ adecuado y justificado.
  - Rango de la matriz seleccionado por validación cruzada.
  - _Placebo tests_ en unidades _donors_ reportados.
  - Ajuste pre-tratamiento evaluado (RMSE).
  - Sensibilidad a la composición del _donor pool_ analizada.
]

== Checklist causal discovery
<sec-apF_causal_discovery>

#checklist[
  - Supuestos del DAG explícitamente declarados.
  - Supuesto de _faithfulness_ razonable en el contexto.
  - Estabilidad del grafo evaluada con submuestras.
  - Confianza en aristas estimada por _bootstrap_.
  - SHD reportado comparado con grafo _benchmark_.
  - Orientación de aristas validada con conocimiento experto.
]
