// Apéndice E — Plantilla de proyecto final y rúbrica
#import "../template/template.typ": *

#chapter[Plantilla de proyecto final y rúbrica]
<ap-proyecto-rubrica>

#theorem-number-reset()

// Alias de etiqueta preservado del original LaTeX (\label{ap:proyecto})
== Estructura del informe
<sec-apE_estructura>

El proyecto final debe seguir la siguiente estructura (10--15 páginas + apéndices):

+ *Resumen ejecutivo* (1 página). Pregunta económica, método principal, resultado central, recomendación de política.
+ *Introducción* (1--2 páginas). Motivación económica, contexto, pregunta causal precisa, contribución.
+ *Marco de identificación* (2 páginas). Supuestos de identificación, justificación económica, DAG si aplica, estimando objetivo.
+ *Datos* (1--2 páginas). Descripción del dataset, _dataset card_, estadísticas descriptivas, balance observacional.
+ *Método* (2--3 páginas). Justificación metodológica usando el mapa del capítulo @cap-mapa-decision, especificación del estimador, selección de hiperparámetros.
+ *Resultados* (2--3 páginas). Estimación del ATE/CATE con IC, análisis de heterogeneidad, mapas de CATE si aplica.
+ *Validación* (1--2 páginas). _Placebos_, comparación con _benchmarks_ clásicos, sensibilidad a hiperparámetros.
+ *Discusión* (1 página). Limitaciones, robustez, implicancias de política, consideraciones éticas.
+ *Conclusión* (0.5 página). Síntesis de hallazgos y recomendación final.
+ *Apéndices.* Código reproducible, gráficos adicionales, análisis de sensibilidad extendido.

== Capa causal de la pregunta
<sec-apE_capa_causal>

El estudiante debe indicar:

- ¿La pregunta es de asociación, intervención o contrafactual?
- Estimando objetivo: ATE, ATT, CATE, LATE o _policy value_.
- Nivel en la jerarquía de Pearl (PCH) al que pertenece la pregunta.

== DAG o supuesto estructural
<sec-apE_dag>

Incluir:

- Grafo causal del problema.
- Variables observadas y no observadas.
- Criterio de identificación utilizado (_back-door_, _front-door_, instrumento, etc.).
- Justificación económica de cada arista incluida en el grafo.

== Identificación
<sec-apE_identificacion>

El estudiante debe detallar:

- Estimando objetivo formalmente definido.
- Supuestos de identificación y su justificación económica.
- Expresión del estimando en términos de la distribución observada.
- Si aplica, derivación del _score_ ortogonal o función de influencia.
- Discusión de identificación parcial o sensible si los supuestos son débiles.

== Estimación
<sec-apE_estimacion>

Incluir:

- Elección del método justificada con el mapa de decisión del curso.
- Especificación de _learners_ _nuisance_ y criterios de selección de hiperparámetros.
- Estrategia de _cross-fitting_ (número de _folds_).
- Construcción de intervalos de confianza.
- Código reproducible con semillas fijadas.

== Validación y refutación
<sec-apE_validacion>

Incluir al menos dos de las siguientes pruebas:

- _Placebo treatment_ (el ATE debe ser cero).
- _Random common cause_ (el ATE no debe cambiar).
- _Subset validation_ (resultado estable en submuestras).

Además, se recomienda:

- Comparación con estimadores clásicos (OLS, IPW, _matching_).
- Validación fuera de muestra de las predicciones _nuisance_.
- Pruebas de sensibilidad a la definición de tratamiento.

== Análisis de sensibilidad
<sec-apE_sensibilidad>

Incluir:

- Sensibilidad a hiperparámetros de los _learners_.
- Sensibilidad a _trimming_ de _propensities_ extremos.
- _E-value_ o análisis de confusión no observada.

== Transportabilidad
<sec-apE_transportabilidad>

Incluir:

- Población de entrenamiento y población objetivo.
- Riesgos de desplegar el modelo fuera de la población de entrenamiento.
- Supuestos bajo los cuales el efecto se transporta (p.\ ej., RCT frente a población objetivo).

== Ética y comunicación
<sec-apE_etica>

Incluir:

- Auditoría de equidad: CATE promedio por grupo protegido.
- Explicación contrafactual de al menos una decisión.
- _Model card_ o ficha del modelo con limitaciones.
- Tabla para tomadores de decisión con intervalos de confianza.

== Criterios de evaluación
<sec-apE_criterios>

#figure(
  caption: [Rúbrica de evaluación del proyecto final.],
  table(
    columns: (1.2fr, 2.4fr, 0.6fr),
    align: (left, left, center),
    stroke: none,
    table.hline(stroke: 0.8pt),
    table.header([*Dimensión*], [*Criterio*], [*Peso*]),
    table.hline(stroke: 0.4pt),
    [Pregunta económica], [Clara, relevante, bien delimitada], [10%],
    [Identificación], [Supuestos justificados económicamente, DAG si aplica], [15%],
    [Método], [Justificado con mapa de decisión, hiperparámetros documentados], [20%],
    [Reproducibilidad], [Código corre limpio, semillas fijadas, versiones declaradas], [15%],
    [Validación], [_Placebos_, sensibilidad, comparación con _benchmarks_], [15%],
    [Heterogeneidad], [CATE estimado con IC, subgrupos identificados], [10%],
    [Comunicación], [Tablas claras, IC reportados, distinción predicción/causalidad], [10%],
    [Ética], [Equidad discutida, sesgo algorítmico abordado si aplica], [5%],
    table.hline(stroke: 0.8pt),
  )
) <tab-apE-rubrica>

== Entregables
<sec-apE_entregables>

+ *Informe PDF* (10--15 páginas) siguiendo la estructura anterior.
+ *Notebook Jupyter* reproducible con código completo, comentarios y conclusiones.
+ *Datos* (o _script_ de descarga si el dataset es externo).
+ *Defensa oral* (15 min + 5 min preguntas).

== Ejemplos de problemas aplicados
<sec-apE_ejemplos>

- Efecto de un programa de capacitación sobre empleabilidad, con heterogeneidad por sector.
- Efecto de una reforma tributaria sobre inversión empresarial, con _staggered adoption_.
- Efecto de becas sobre deserción universitaria, con CATE por características socioeconómicas.
- Efecto de recordatorios sobre adherencia médica, con múltiples tratamientos.
- Efecto de una política monetaria sobre inflación, con variable instrumental.
- Optimización de _targeting_ de transferencias gubernamentales bajo restricciones de equidad.

== Plazos sugeridos
<sec-apE_plazos>

- *Semana 10:* propuesta de problema y dataset (1 página).
- *Semana 12:* entrega intermedia: identificación + EDA + método tentativo.
- *Semana 14:* entrega del borrador completo para revisión por pares.
- *Semana 16:* entrega final + defensa oral.
