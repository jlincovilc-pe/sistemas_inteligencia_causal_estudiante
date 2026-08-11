// Capítulo 7 (nuevo) — Datos de entrenamiento en sistemas causales
// Plantilla B: Sesión 6.
#import "../template/template.typ": *

#chapter[Datos de entrenamiento en sistemas causales]
<cap-datos-entrenamiento-causales>

#theorem-number-reset()

#cuadrodecision[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*Decisión:*], [Tratar la asignación del tratamiento como parte del proceso de muestreo a auditar, no como un dato dado],
    [*Alternativas:*], [Usar los datos "tal como llegan" vs. auditar explícitamente el mecanismo de asignación],
    [*Trade-off clave:*], [Velocidad de arranque vs. riesgo de sesgo de selección no detectado],
    [*Stack:*], [pandas, `pandera`, tests de balance],
    [*Riesgo principal:*], [Confundir "faltante al azar" con "faltante por selección relacionada al tratamiento"],
  )
]

== El problema de diseño
<sec-datosentrenamiento-problema>

#cite(<huyen2022dmls>, form: "prose") dedica su Capítulo 4 a una idea que la comunidad de _machine learning_ tarda en internalizar: los datos de entrenamiento casi nunca son una muestra aleatoria simple del universo sobre el que luego se aplicará el modelo, y cómo se generaron esos datos —el proceso de muestreo, cómo se etiquetó, qué faltó y por qué— determina la validez de cualquier cosa que se entrene sobre ellos. En un sistema *causal*, este problema no es solo una amenaza a la precisión predictiva: es una amenaza directa a la *identificación*. Si la asignación del tratamiento en los datos históricos está relacionada con variables no observadas, ningún ajuste posterior por covariables observadas —por sofisticado que sea el estimador— corrige el problema. El problema de diseño de este capítulo es, entonces: ¿cómo se estructura el proceso de recolección y muestreo de datos de entrenamiento de forma que las amenazas a la identificación queden documentadas y, cuando sea posible, mitigadas, en lugar de descubrirse después de haber estimado el efecto?

== Opciones y trade-offs
<sec-datosentrenamiento-opciones>

#opciones[
  - *Usar los datos "tal como llegan".* Se toma el dataset disponible y se procede directamente a la estimación. Es la opción más rápida y, en la práctica, la más común. El riesgo es que el mecanismo de asignación del tratamiento —quién decidió, con qué información, a quién tratar— quede completamente implícito, y que cualquier sesgo de selección relacionado con variables no observadas nunca se detecte porque nadie lo buscó explícitamente.
  - *Auditar el mecanismo de asignación antes de estimar.* Se documenta explícitamente, para el dataset en cuestión: ¿la asignación fue aleatorizada, cuasi-aleatorizada (por ejemplo, un umbral administrativo) u observacional pura? ¿Qué información tenía quien decidió asignar el tratamiento, y coincide con las covariables observadas en los datos? Este paso no reemplaza el análisis de identificación de los capítulos anteriores; lo *precede*, y a menudo revela qué covariables son plausiblemente suficientes para el criterio de puerta trasera antes de intentar ajustar ningún modelo.
]

Un segundo trade-off, heredado de la discusión de #cite(<huyen2022dmls>, form: "prose") sobre "etiquetas naturales", es específico de los sistemas causales: en muchos casos, el "tratamiento" es una decisión que ya ocurrió en el pasado dentro de un proceso administrativo o de negocio (a quién se le otorgó un crédito, a quién se le dio un descuento). Estas asignaciones pasadas tienen la ventaja de estar disponibles a bajo costo, pero la desventaja de que la regla de decisión histórica —a menudo no documentada— es exactamente la fuente potencial de confusión que el análisis de identificación debe descubrir.

== Decisión de referencia para el curso
<sec-datosentrenamiento-decision>

Todo dataset usado en el curso se acompaña de una *ficha de procedencia del tratamiento* (una extensión del `CausalSchema` del Capítulo 4) que documenta, como mínimo: el mecanismo de asignación (aleatorizado / cuasi-experimental / observacional), la unidad temporal de la asignación respecto a la medición del resultado, y cualquier regla de elegibilidad conocida. Para el Notebook de caso de estudio A1 (@cap-ingenieria-datos-causales), completar esta ficha es un requisito de entrega antes de correr cualquier estimación — es, en efecto, la versión operacional del "problema causal, estimando e identificación" que abre cada capítulo de Plantilla A.

== Implementación de referencia
<sec-datosentrenamiento-implementacion>

La herramienta mínima para auditar el mecanismo de asignación es el *chequeo de balance*: comparar la distribución de cada covariable entre tratados y controles. Aquí conviene ser preciso sobre qué estadístico usar, porque la elección por defecto —un $t$-test por covariable— es la equivocada por dos razones independientes.

Primero, el $t$-test responde la pregunta incorrecta. Su $p$-valor mezcla el tamaño de la diferencia con el tamaño de la muestra: con $n$ grande, diferencias irrelevantes resultan "significativas"; con $n$ pequeño, desbalances severos pasan el test. Pero lo que amenaza la identificación es la *magnitud* del desbalance —cuánta extrapolación tendrá que hacer el estimador— y no si esa magnitud es distinguible de cero. El estadístico apropiado es por tanto una medida de tamaño de efecto, la *diferencia media estandarizada* (SMD, también llamada _standardized bias_):
$
"SMD"_j = (overline(X)_(j,1) - overline(X)_(j,0)) / sqrt((s_(j,1)^2 + s_(j,0)^2) \/ 2),
$
que es invariante a $n$ y a las unidades de medida. #cite(<rubin2001using>, form: "prose") propone dos criterios operativos que se han vuelto convencionales: $|"SMD"_j| < 0.25$ (idealmente $< 0.1$) y una razón de varianzas $s_(j,1)^2 \/ s_(j,0)^2$ dentro de $[0.5, 2]$. El segundo criterio importa y suele olvidarse: dos grupos pueden tener la misma media y distribuciones tan distintas en dispersión que el soporte común sea escaso en las colas, lo que compromete el supuesto de solapamiento antes que el de no confusión.

Segundo, si aun así se reportan $p$-valores —y hay una razón legítima para hacerlo cuando la asignación *debería* haber sido aleatoria, como en la submuestra experimental de un RCT—, evaluar $p$ covariables al 5% produce por construcción $approx 0.05 p$ rechazos espurios. Con 40 covariables, esperar dos "desbalances significativos" bajo aleatorización perfecta es lo normal, no una anomalía. Cualquier lectura del chequeo debe corregir por comparaciones múltiples (Holm o Benjamini–Hochberg) o, mejor, apoyarse en la distribución completa de las SMD.

#figure(
  kind: raw,
  caption: [Chequeo de balance con SMD, razón de varianzas y corrección por comparaciones múltiples.],
  ```python
import numpy as np
import pandas as pd
from scipy import stats
from scipy.stats import ttest_ind

# Balance check: SMD (Standardized Mean Difference)
def compute_smd(X_T, X_C, col):
    """Calcula SMD para una covariable."""
    mean_diff = X_T[col].mean() - X_C[col].mean()
    pooled_std = np.sqrt((X_T[col].var() + X_C[col].var()) / 2)
    return mean_diff / pooled_std

# Ejemplo de uso con DataFrames X_T (tratados) y X_C (controles)
# X_cols es la lista de nombres de columnas de covariables

# Calcular SMD para cada covariable
smd = {}
for col in X_cols:
    smd[col] = abs(compute_smd(X_T, X_C, col))

smd_max = max(smd.values())
print(f"SMD máximo: {smd_max:.3f}")
print(f"Criterio de Rubin (@imbens2015causal): SMD < 0.25")

# Corrección por múltiples comparaciones (Bonferroni)
p_vals = {col: ttest_ind(X_T[col], X_C[col])[1] for col in X_cols}
alpha_adjusted = 0.05 / len(X_cols)
unbalanced = sum(1 for p in p_vals.values() if p < alpha_adjusted)

print(f"\nVariables desbalanceadas: {unbalanced}/{len(X_cols)}")
print(f"α ajustado (Bonferroni): {alpha_adjusted:.4f}")

if smd_max > 0.25:
    print("⚠️ Desbalance sustancial detectado")
```
) <lst-chequeo-balance>

Un número alto de covariables desbalanceadas no invalida por sí solo el análisis observacional —es, de hecho, la situación esperada cuando la asignación no fue aleatoria— y, sobre todo, *no es el chequeo el que identifica el efecto*: el balance en las covariables observadas no dice nada sobre las no observadas, que son las que rompen la no confusión. Lo que el chequeo aporta es más modesto y más útil: cuantifica cuánta corrección tendrá que hacer el estimador, y por tanto cuánto de la estimación final descansará en extrapolación del modelo en vez de en comparaciones respaldadas por datos. Un SMD de 1.5 en una covariable relevante advierte que el estimador estará comparando poblaciones con poco solapamiento efectivo, mucho antes de que un diagnóstico de _propensity score_ lo revele en el @cap-dml.

Dos lecturas específicas del reporte merecen atención. Si covariables que *deberían* ser irrelevantes para la asignación (por ejemplo, una característica administrativa sin relación aparente con el criterio de elegibilidad) resultan fuertemente desbalanceadas, es señal de que el mecanismo de asignación real difiere del documentado, y amerita revisar el DAG propuesto antes de proceder. Y si el porcentaje de faltantes difiere sistemáticamente entre tratados y controles, el problema ya no es de balance sino de *missingness* no aleatorio en el sentido de #cite(<rubin1976inference>, form: "prose"): ningún ajuste por covariables observadas corrige una selección que opera sobre quién aparece en los datos.

== Aplicación al sistema causal del curso
<sec-datosentrenamiento-aplicacion>

El Notebook A1 usa el dataset de Lalonde/NSW precisamente porque permite ilustrar este capítulo de forma directa. #cite(<lalonde1986>, form: "prose") comparó las estimaciones de métodos econométricos observacionales contra el _benchmark_ experimental del programa NSW y encontró que diferían sustancialmente —el resultado que fundó la literatura moderna de evaluación de programas—; #cite(<dehejia1999causal>, form: "prose") reexaminaron el mismo caso construyendo la extensión observacional (submuestras de CPS/PSID como controles) que sigue siendo el banco de pruebas estándar del campo.

Su utilidad pedagógica aquí es que ofrece los dos regímenes con el mismo tratamiento y el mismo resultado: la submuestra experimental tiene asignación aleatorizada por diseño (el chequeo de balance debería mostrar SMD pequeñas en todas las covariables), mientras que la extensión observacional no la tiene (el mismo chequeo debería mostrar SMD grandes, en varias covariables muy por encima de 0.25, y razones de varianzas fuera del rango de Rubin). Ejecutar el listado @lst-chequeo-balance sobre ambas versiones y comparar las dos distribuciones de SMD es la forma más directa de ver, en números y no en abstracto, qué significa que un dataset sea o no "como aleatorizado".

== Señales de alerta y checklist operativo
<sec-datosentrenamiento-alertas>

#checklist[
  - Nadie en el equipo puede explicar, en una oración, cómo se decidió históricamente quién recibía el tratamiento.
  - No se ejecutó ningún chequeo de balance de covariables antes de estimar el efecto.
  - Existen valores faltantes en el resultado $Y$ que están sistemáticamente relacionados con el tratamiento (posible sesgo de selección en el seguimiento, no solo en la asignación).
  - La ficha de procedencia del tratamiento no distingue si la asignación fue anterior o posterior a la medición de alguna covariable "de control".
]

== Ejercicios y notas bibliográficas
<sec-datosentrenamiento-ejercicios>

=== Ejercicios conceptuales
<sec-datosentrenamiento-ejercicios-conceptuales>

+ Para el dataset de becas del @cap-causalidad-elemental, redacte una ficha de procedencia del tratamiento hipotética, incluyendo el mecanismo de asignación más plausible.

+ Explique por qué un desbalance fuerte en una covariable *administrativa, sin relación aparente con el criterio de elegibilidad* es una señal de alerta más seria que un desbalance en una covariable directamente relacionada con dicho criterio.

=== Ejercicio computacional
<sec-datosentrenamiento-ejercicios-computacionales>

+ Aplique el listado @lst-chequeo-balance a las dos versiones del dataset de Lalonde (experimental y observacional). Reporte, para cada una, la distribución de SMD y cuántas covariables violan cada criterio de Rubin, y relacione el resultado con el mecanismo de asignación de cada submuestra.

+ Sobre la submuestra *experimental* (donde la asignación fue aleatoria por diseño), compare cuántas covariables resultan "significativas" con $p$ crudo al 5% frente a cuántas lo son con la corrección de Holm. Explique por qué el primer número no es evidencia de que la aleatorización haya fallado.

=== Notas bibliográficas
<sec-datosentrenamiento-notas>

#cite(<huyen2022dmls>, form: "prose"), Capítulo 4, desarrolla en detalle el rol del muestreo y las "etiquetas naturales" en sistemas de ML generales. La lógica del chequeo de balance como diagnóstico de identificación es estándar en la literatura de evaluación de programas: #cite(<imbens2015causal>, form: "prose") ofrece su tratamiento formal completo, y #cite(<rubin2001using>, form: "prose") es la fuente de los criterios operativos (SMD y razón de varianzas) adoptados en el listado @lst-chequeo-balance, en el contexto de diseño de estudios observacionales sin mirar el resultado. #cite(<rosenbaum1983central>, form: "prose") es la referencia fundacional del _propensity score_, que el @cap-dml usará como componente _nuisance_ y que ofrece la versión resumida de este mismo diagnóstico en una sola dimensión. #cite(<lalonde1986>, form: "prose") y #cite(<dehejia1999causal>, form: "prose") son las referencias del caso NSW usado en el Notebook A1. Sobre datos faltantes y la distinción MCAR/MAR/MNAR que subyace al diagnóstico de faltantes diferenciales, la referencia canónica es #cite(<rubin1976inference>, form: "prose").
