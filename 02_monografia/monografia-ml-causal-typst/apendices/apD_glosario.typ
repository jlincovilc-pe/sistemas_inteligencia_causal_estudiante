// Apéndice D — Glosario de estimandos, supuestos y métodos
#import "../template/template.typ": *

#chapter[Glosario de estimandos, supuestos y métodos]
<ap-glosario>

#theorem-number-reset()

== Estimandos

#table(
  columns: (auto, 1fr),
  align: (left, left),
  stroke: none,
  table.hline(stroke: 0.8pt),
  [*ATE (Average Treatment Effect)*], [$theta = E[Y(1) - Y(0)]$. Efecto promedio del tratamiento en la población.],
  [*ATT (Average Treatment Effect on the Treated)*], [$theta_("ATT") = E[Y(1) - Y(0) | D = 1]$. Efecto promedio en los tratados.],
  [*CATE (Conditional Average Treatment Effect)*], [$tau(x) = E[Y(1) - Y(0) | X = x]$. Efecto promedio condicional en $X = x$. Estimando central del curso.],
  [*LATE (Local Average Treatment Effect)*], [Efecto del tratamiento en los _compliers_: individuos cuyo tratamiento es afectado por el instrumento.],
  [*ETT (Effect of Treatment on the Treated)*], [$E[Y(1) - Y(0) | D = 1]$.],
  [*Policy value*], [$V(pi) = E[Y(pi(X))]$. Bienestar esperado bajo la regla de asignación $pi$.],
  [*Uplift*], [En marketing, sinónimo de CATE. Diferencia en probabilidad de conversión entre tratados y controles condicional en covariables.],
  [*Regret (welfare regret)*], [$"Regret"(hat(pi)) = V(pi^*) - V(hat(pi))$. Pérdida de bienestar por usar $hat(pi)$ en lugar de $pi^*$.],
  table.hline(stroke: 0.8pt),
)

== Supuestos

#table(
  columns: (auto, 1fr),
  align: (left, left),
  stroke: none,
  table.hline(stroke: 0.8pt),
  [*Unconfoundedness*], [$Y(0), Y(1) perp perp D | X$. Supuesto de que no hay confusores no observados condicional en $X$.],
  [*Overlap / soporte común*], [Supuesto de que $eta < P(D = 1 | X = x) < 1 - eta$ para algún $eta > 0$ y todo $x$. Garantiza que hay información tanto de tratados como de controles en cada región del espacio de covariables.],
  [*$underline(e)$*], [Cota inferior de soporte común: $underline(e) < P(D = 1 | X = x) < 1 - underline(e)$ para todo $x$.],
  [*SUTVA (Stable Unit Treatment Value Assumption)*], [Supuesto de no interferencia entre unidades y de versiones únicas del tratamiento.],
  [*Causal sufficiency*], [Supuesto de que no hay confusores no observados que afecten a dos o más variables del grafo causal. Requerido por algoritmos de _causal discovery_.],
  [*Sparsity*], [Supuesto de que el vector verdadero de coeficientes tiene pocas componentes no nulas. Requerido por LASSO y PDS.],
  [*Restricted eigenvalue (RE)*], [Condición sobre la matriz de diseño que garantiza la *tasa* de convergencia $ell_2$ del LASSO. Relativamente débil. No basta para recuperar el soporte.],
  [*Irrepresentabilidad*], [Condición sobre la correlación entre variables activas e inactivas, necesaria y esencialmente suficiente para que el LASSO recupere el *conjunto* de variables verdaderamente no nulas. Mucho más fuerte que RE y no verificable en la práctica (@cap-regularizacion).],
  [*Faithfulness*], [Supuesto de que toda independencia condicional presente en la distribución corresponde a una $d$-separación en el grafo. Requerido por los algoritmos de descubrimiento basados en restricciones.],
  [*Transportabilidad*], [Validez de un efecto estimado en un dominio $Pi$ cuando se aplica a un dominio distinto $Pi^*$. Se decide sobre un *diagrama de selección* (@cap-generalizacion-transportabilidad).],
  [*Generalización (validez externa)*], [Caso particular de transportabilidad en que el problema es la *selección muestral*: si el efecto estimado sobre la muestra observada vale para la población de la que se extrajo.],
  [*Equidad contrafactual*], [Una decisión es justa si no cambia al modificar solo el atributo protegido, manteniendo lo que no depende causalmente de él.],
  table.hline(stroke: 0.8pt),
)

== Métodos

#table(
  columns: (auto, 1fr),
  align: (left, left),
  stroke: none,
  table.hline(stroke: 0.8pt),
  [*DML (Double/Debiased Machine Learning)*], [Marco de estimación causal que combina ortogonalidad de Neyman con _cross-fitting_ para permitir inferencia válida cuando los _nuisance_ se estiman con ML.],
  [*Cross-fitting*], [Partición de la muestra en $K$ _folds_; para cada _fold_ $k$, el _learner_ _nuisance_ se entrena en los $K - 1$ _folds_ restantes y predice en el _fold_ $k$. Evita _overfitting bias_ sin desperdiciar datos.],
  [*Sample splitting*], [División de la muestra en dos partes: una para estimar _nuisance_, otra para estimar el parámetro causal. Caso especial de _cross-fitting_ con $K = 2$.],
  [*Post-Double-Selection (PDS)*], [Procedimiento de Belloni, Chernozhukov & Hansen (2014) para selección de confusores en alta dimensión sin sesgo post-selección.],
  [*R-learner*], [Meta-learner que optimiza el _score_ ortogonal de Robinson. Alcanza tasas cuasi-oracle para CATE; la eficiencia $sqrt(n)$ aplica a funcionales como el ATE o clases paramétricas de $tau(x)$.],
  [*DR-learner*], [Meta-learner _doubly robust_ que regresa sobre $X$ el pseudo-_outcome_ $Gamma_i$ (score IRM antes de promediar). Su error depende de los _nuisance_ a través del *producto* de sus errores, no de su suma (@cap-meta-learners).],
  [*Score de Robinson*], [$psi = (D - m(X)){Y - l(X) - theta(D - m(X))}$, con $l_0(X) = E[Y|X]$ y $m_0(X) = E[D|X]$. Base del PLR de DML y de la _loss_ del R-learner.],
  [*Cálculo-$"do"$*], [Conjunto de tres reglas de reescritura que transforman expresiones con $"do"()$ en expresiones observacionales. *Completo*: si sus reglas no identifican el efecto, ningún método lo hace con ese grafo (@cap-intervencion-contrafactual).],
  [*Puerta trasera (_backdoor_)*], [Criterio gráfico para elegir un conjunto de ajuste $Z$ válido. Corolario del cálculo-$"do"$.],
  [*Puerta delantera (_front-door_)*], [Criterio de identificación vía un mediador que capta todo el efecto, aplicable cuando existe confusión no observada y ningún ajuste por covariables funciona.],
  [*EWM (Empirical Welfare Maximization)*], [Elección de la política que maximiza el _welfare_ empírico sobre una clase $Pi$ de VC-dimensión finita. Regret $O(sqrt("VC"(Pi)\/n))$ (Kitagawa & Tetenov, 2018).],
  [*Net score*], [$s_k (x) = tau_k (x) - lambda c_k (x)$, con $lambda$ el costo sombra de la restricción presupuestaria. Base de la asignación multi-tratamiento (@cap-uplift-targeting).],
  [*RA-learner*], [_Regression Adjustment_ learner: $hat(tau)(x) = hat(mu)_1(x) - hat(mu)_0(x)$.],
  [*Honesty (en árboles causales)*], [Restricción por la cual la partición del árbol se decide usando una submuestra distinta de la que se usa para estimar el efecto dentro de cada hoja. Garantiza validez asintótica de los IC.],
  [*IPW (Inverse Probability Weighting)*], [Estimador que usa el inverso del _propensity score_ para ponderar unidades y reconstruir el contrafactual.],
  [*IPM (Integral Probability Metric)*], [Métrica de distancia entre distribuciones. Usada en CFRNet para forzar balance entre representaciones de tratados y controles.],
  [*MMD (Maximum Mean Discrepancy)*], [Distancia entre distribuciones usada en CFRNet.],
  [*Propensity score*], [$e(x) = P(D = 1 | X = x)$. Probabilidad de recibir tratamiento condicional en covariables.],
  [*IPS (Inverse Propensity Scoring)*], [Ponderación por la inversa del _propensity score_.],
  [*SNIPS (Self-Normalized IPS)*], [Versión normalizada de IPS.],
  [*$e_0(x)$*], [Propensity score: $e_0(x) = E[D | X = x]$. En el modelo PLR se denota también como $m_0(x)$.],
  [*$mu_d(x)$*], [_Outcome_ condicional: $mu_d(x) = E[Y | X = x, D = d]$. Equivalente a $mu(d, x)$.],
  [*$omega_i(x)$*], [Pesos locales inducidos por un bosque causal / _Generalized Random Forest_. El estimador del CATE se obtiene resolviendo $sum_i omega_i(x) dot.c psi_i(hat(theta)(x)) = 0$.],
  [*$Y_i^star$ (_Transformed outcome_)*], [$Y_i^star = Y_i dot.c (D_i - e_0(X_i)) / (e_0(X_i)(1 - e_0(X_i)))$. Su esperanza condicional es $E[Y^star | X] = tau(X)$.],
  [*$cal(C)$*], [Conjunto de ajuste que satisface el criterio de puerta trasera de Pearl.],
  [*$zeta$*], [Error del instrumento en el modelo PLIV: $Z = r_0(X) + zeta$.],
  [*SCM (Structural Causal Model)*], [Modelo que describe cada variable como función de sus causas directas más ruido exógeno.],
  [*NCM (Neural Causal Model)*], [Red neuronal que parametriza un SCM.],
  [*DAG (Directed Acyclic Graph)*], [Grafo dirigido acíclico que representa relaciones causales directas entre variables.],
  [*PCH (Pearl Causal Hierarchy)*], [Jerarquía de tres niveles: asociación, intervención, contrafactual.],
  [*$"do"(X = x)$*], [Operador de intervención: representa la acción de fijar $X$ en el valor $x$, rompiendo sus causas.],
  [*Contrafactual*], [Resultado potencial bajo una intervención que no ocurrió: "¿Qué habría pasado si...?".],
  [*FCI (Fast Causal Inference)*], [Algoritmo de descubrimiento causal que permite variables latentes.],
  [*GES (Greedy Equivalence Search)*], [Algoritmo de descubrimiento basado en _score_.],
  [*Synthetic DiD*], [Combinación de control sintético y diferencias-en-diferencias.],
  [*RDD (Regression Discontinuity Design)*], [Diseño causal basado en un umbral.],
  [*Fuzzy RDD*], [RDD con cumplimiento imperfecto del umbral; se estima como IV local.],
  [*Off-policy evaluation*], [Estimación del valor de una política usando datos generados por otra política.],
  [*Nuclear norm*], [$norm(L)_* = sum_i sigma_i(L)$. Envolvente convexa del _rank_. Usada en _matrix completion_.],
  table.hline(stroke: 0.8pt),
)

== Garantías

#table(
  columns: (auto, 1fr),
  align: (left, left),
  stroke: none,
  table.hline(stroke: 0.8pt),
  [*Neyman orthogonality*], [Propiedad de un _score_ cuya derivada de Gateaux respecto a los parámetros _nuisance_ es cero en el valor verdadero. Permite que errores de estimación de _nuisance_ solo afecten la inferencia causal en segundo orden.],
  [*EIF (Efficient Influence Function)*], [Proyección del _score_ del parámetro de interés sobre el espacio tangente. Determina el límite semiparamétrico de Cramér-Rao.],
  [*Doubly robust*], [Propiedad de un estimador que es consistente si al menos uno de dos modelos (_outcome regression_ o _propensity score_) es consistente. No requiere ambos.],
  [*$cal(V)$*], [Varianza asintótica de estimadores como DML o PDS: $sqrt(n) dot.c (hat(theta) - theta_0) arrow.r^(d) cal(N)(0, cal(V))$.],
  table.hline(stroke: 0.8pt),
)

== Diagnósticos

#table(
  columns: (auto, 1fr),
  align: (left, left),
  stroke: none,
  table.hline(stroke: 0.8pt),
  [*Curva Qini*], [_Qini curve_. Curva de validación de _ranking_ causal: _uplift_ acumulado en función de la fracción de muestra ordenada por CATE estimado. Mide la calidad del _ranking_, no la calibración absoluta de $hat(tau)$.],
  [*AUUC (Area Under Uplift Curve)*], [Área bajo la curva _uplift_. Métrica de *ranking*, no de calibración: es invariante a reescalar $hat(tau)$. Solo comparable entre modelos evaluados sobre la misma muestra.],
  [*Coeficiente Qini*], [AUUC normalizada restando el _baseline_ aleatorio y dividiendo por el modelo perfecto. Comparable entre datasets.],
  [*E-value*], [$"E" = "RR" + sqrt("RR"("RR"-1))$. Fuerza mínima de asociación que un confusor no observado debería tener con tratamiento y resultado para explicar el efecto observado. Cota necesaria, no suficiente (@cap-validacion).],
  [*SMD / ASMD*], [Diferencia media estandarizada (absoluta). Tamaño de efecto invariante a $n$ para medir desbalance. Criterio de Rubin: $|"SMD"| < 0.25$ y razón de varianzas en $[0.5, 2]$.],
  [*PSI (Population Stability Index)*], [$sum_b (p_b - q_b) log(p_b\/q_b)$ sobre _bins_. Convención de industria para _drift_: $< 0.1$ estable, $> 0.25$ deriva material. Sin respaldo teórico canónico.],
  [*Descomposición de Goodman-Bacon*], [Descomposición del estimador TWFE en comparaciones $2 times 2$ ponderadas; revela las comparaciones "prohibidas" contra unidades ya tratadas y los pesos negativos (@cap-panel-dmliv).],
  [*Equidad en el efecto (_equalized CATE_)*], [Métrica de equidad *específica de sistemas causales*: la distribución del CATE estimado es similar entre grupos. No pertenece al canon de _fair ML_ (@cap-etica-interpretabilidad).],
  [*SHD (Structural Hamming Distance)*], [Número de aristas que difieren entre dos grafos.],
  [*CPDAG*], [Grafo parcialmente dirigido que representa una clase de equivalencia de Markov: el máximo que puede identificarse de la estructura con datos observacionales.],
  table.hline(stroke: 0.8pt),
)
