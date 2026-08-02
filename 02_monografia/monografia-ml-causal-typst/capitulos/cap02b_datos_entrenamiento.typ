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
    [*[Decisión]*], [Tratar la asignación del tratamiento como parte del proceso de muestreo a auditar, no como un dato dado],
    [*[Alternativas]*], [Usar los datos "tal como llegan" vs. auditar explícitamente el mecanismo de asignación],
    [*[Trade-off clave]*], [Velocidad de arranque vs. riesgo de sesgo de selección no detectado],
    [*[Stack]*], [pandas, `pandera`, tests de balance],
    [*[Riesgo principal]*], [Confundir "faltante al azar" con "faltante por selección relacionada al tratamiento"],
  )
]

== El problema de diseño
<sec-datosentrenamiento-problema>

@huyen2022dmls dedica su Capítulo 4 a una idea que la comunidad de _machine learning_ tarda en internalizar: los datos de entrenamiento casi nunca son una muestra aleatoria simple del universo sobre el que luego se aplicará el modelo, y cómo se generaron esos datos —el proceso de muestreo, cómo se etiquetó, qué faltó y por qué— determina la validez de cualquier cosa que se entrene sobre ellos. En un sistema *causal*, este problema no es solo una amenaza a la precisión predictiva: es una amenaza directa a la *identificación*. Si la asignación del tratamiento en los datos históricos está relacionada con variables no observadas, ningún ajuste posterior por covariables observadas —por sofisticado que sea el estimador— corrige el problema. El problema de diseño de este capítulo es, entonces: ¿cómo se estructura el proceso de recolección y muestreo de datos de entrenamiento de forma que las amenazas a la identificación queden documentadas y, cuando sea posible, mitigadas, en lugar de descubrirse después de haber estimado el efecto?

== Opciones y trade-offs
<sec-datosentrenamiento-opciones>

#opciones[
  - *Usar los datos "tal como llegan".* Se toma el dataset disponible y se procede directamente a la estimación. Es la opción más rápida y, en la práctica, la más común. El riesgo es que el mecanismo de asignación del tratamiento —quién decidió, con qué información, a quién tratar— quede completamente implícito, y que cualquier sesgo de selección relacionado con variables no observadas nunca se detecte porque nadie lo buscó explícitamente.
  - *Auditar el mecanismo de asignación antes de estimar.* Se documenta explícitamente, para el dataset en cuestión: ¿la asignación fue aleatorizada, cuasi-aleatorizada (por ejemplo, un umbral administrativo) u observacional pura? ¿Qué información tenía quien decidió asignar el tratamiento, y coincide con las covariables observadas en los datos? Este paso no reemplaza el análisis de identificación de los capítulos anteriores; lo *precede*, y a menudo revela qué covariables son plausiblemente suficientes para el criterio de puerta trasera antes de intentar ajustar ningún modelo.
]

Un segundo trade-off, heredado de la discusión de @huyen2022dmls sobre "etiquetas naturales", es específico de los sistemas causales: en muchos casos, el "tratamiento" es una decisión que ya ocurrió en el pasado dentro de un proceso administrativo o de negocio (a quién se le otorgó un crédito, a quién se le dio un descuento). Estas asignaciones pasadas tienen la ventaja de estar disponibles a bajo costo, pero la desventaja de que la regla de decisión histórica —a menudo no documentada— es exactamente la fuente potencial de confusión que el análisis de identificación debe descubrir.

== Decisión de referencia para el curso
<sec-datosentrenamiento-decision>

Todo dataset usado en el curso se acompaña de una *ficha de procedencia del tratamiento* (una extensión del `CausalSchema` del Capítulo 4) que documenta, como mínimo: el mecanismo de asignación (aleatorizado / cuasi-experimental / observacional), la unidad temporal de la asignación respecto a la medición del resultado, y cualquier regla de elegibilidad conocida. Para el Notebook de caso de estudio A1 (@cap-ingenieria-datos-causales), completar esta ficha es un requisito de entrega antes de correr cualquier estimación — es, en efecto, la versión operacional del "problema causal, estimando e identificación" que abre cada capítulo de Plantilla A.

== Implementación de referencia
<sec-datosentrenamiento-implementacion>

#figure(
  kind: raw,
  caption: [Chequeo de balance como auditoría mínima del mecanismo de asignación.],
  ```python
import pandas as pd
from scipy import stats

def chequeo_balance(df: pd.DataFrame, treatment: str, covariates: list[str],
                     alpha: float = 0.05) -> pd.DataFrame:
    """Compara covariables entre tratados y controles.
    Muchas diferencias significativas sugieren que la asignacion
    no es 'como aleatorizada' condicional en esas covariables."""
    filas = []
    tratados = df[df[treatment] == 1]
    controles = df[df[treatment] == 0]
    for cov in covariates:
        t_stat, p_val = stats.ttest_ind(
            tratados[cov].dropna(), controles[cov].dropna(), equal_var=False
        )
        filas.append({
            "covariable": cov,
            "media_tratados": tratados[cov].mean(),
            "media_controles": controles[cov].mean(),
            "p_valor": p_val,
            "desbalance": p_val < alpha,
        })
    resultado = pd.DataFrame(filas)
    n_desbalanceadas = resultado["desbalance"].sum()
    print(f"{n_desbalanceadas}/{len(covariates)} covariables desbalanceadas (p<{alpha})")
    return resultado
```
) <lst-chequeo-balance>

Un número alto de covariables desbalanceadas no invalida por sí solo el análisis observacional —es, de hecho, la situación esperada cuando la asignación no fue aleatoria—, pero si covariables que *deberían* ser irrelevantes para la asignación (por ejemplo, una característica administrativa sin relación aparente con el criterio de elegibilidad) resultan fuertemente desbalanceadas, es una señal de que el mecanismo de asignación real difiere del documentado, y amerita revisar el DAG propuesto antes de proceder al @cap-dml.

== Aplicación al sistema causal del curso
<sec-datosentrenamiento-aplicacion>

El Notebook A1 usa el dataset de Lalonde/NSW precisamente porque permite ilustrar este capítulo de forma directa: la submuestra experimental tiene asignación aleatorizada por diseño (el chequeo de balance debería mostrar covariables balanceadas), mientras que la extensión observacional de Dehejia y Wahba no la tiene (el mismo chequeo debería mostrar desbalances sustanciales) — permitiendo comparar, con el mismo par de grupos de tratamiento, qué tan distinto luce un dataset "como aleatorizado" de uno que no lo es.

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

+ Aplique el listado @lst-chequeo-balance a las dos versiones del dataset de Lalonde (experimental y observacional). Reporte cuántas covariables resultan desbalanceadas en cada una y relacione el resultado con el mecanismo de asignación de cada submuestra.

=== Notas bibliográficas
<sec-datosentrenamiento-notas>

@huyen2022dmls, Capítulo 4, desarrolla en detalle el rol del muestreo y las "etiquetas naturales" en sistemas de ML generales. La lógica del chequeo de balance como diagnóstico de identificación es estándar en la literatura de evaluación de programas; véase @imbens2015causal para su tratamiento formal.
