// Capítulo 9 (nuevo) — Ingeniería de features sin fuga causal
// Plantilla B: Sesión 8. Arranca el Notebook de caso de estudio #2.
#import "../template/template.typ": *

#chapter[Ingeniería de _features_ sin fuga causal]
<cap-features-sin-fuga>

#theorem-number-reset()

#cuadrodecision[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*[Decisión]*], [Auditar cada _feature_ candidata contra el grafo causal antes de incluirla, no solo contra su poder predictivo],
    [*[Alternativas]*], [Selección de _features_ por importancia predictiva vs. selección por rol causal],
    [*[Trade-off clave]*], [Una _feature_ que mejora el ajuste predictivo puede empeorar la estimación causal],
    [*[Stack]*], [pandas, el `CausalSchema` del @cap-ingenieria-datos-causales],
    [*[Riesgo principal]*], [_Fuga_ (_leakage_) de información post-tratamiento disfrazada de covariable],
  )
]

#monorepo[
  Lab #code[L08] planta fugas deliberadas (outcome, tratamiento, interacciones) y las detecta antes de estimar. La Serie A2 (DML) y el escenario #code[ihdp_medium] asumen covariables solo pre-tratamiento. No usar columnas de ground truth (#code[y0], #code[y1], #code[tau]) fuera de celdas de evaluación. Rutas: #code[05_labs_sesion/L08_leakage_ihdp/] y notebook A2 en #code[03_notebooks_caso_estudio/notebooks/].
]

== El problema de diseño
<sec-featuresfuga-problema>

La ingeniería de _features_ estándar —la de @huyen2022dmls Capítulo 5— evalúa una _feature_ candidata por un solo criterio: ¿mejora el desempeño predictivo del modelo fuera de muestra? Bajo ese criterio, cualquier variable disponible en el momento de entrenar que esté correlacionada con $Y$ es, en principio, bienvenida. El @cap-intervencion-contrafactual mostró por qué ese criterio es *insuficiente y a veces contraproducente* para un sistema causal: una _feature_ puede reducir el error de predicción y, al mismo tiempo, ser un mediador o un collider que sesga la estimación del efecto. El problema de diseño de este capítulo es construir un proceso de ingeniería de _features_ que audite cada variable candidata contra su *rol en el grafo causal*, no solo contra su poder predictivo — la versión operacional, en el pipeline de _features_, de la clasificación de controles del capítulo anterior.

== Opciones y trade-offs
<sec-featuresfuga-opciones>

#opciones[
  - *Selección por importancia predictiva.* Se agregan _features_ mientras mejoren una métrica de validación cruzada (RMSE, AUC). Es el flujo de trabajo estándar en _machine learning_ aplicado y el más rápido de ejecutar. Su riesgo específico en un contexto causal ya se discutió en el @cap-prediccion-causalidad: un modelo puede predecir excelente y estimar el efecto causal con sesgo severo, precisamente porque la importancia predictiva no distingue entre variación causal y variación espuria.
  - *Selección por rol causal, informada por el grafo.* Cada _feature_ candidata se clasifica primero según la @sec-intervcontra-controles del capítulo anterior (confusor / mediador / collider / post-tratamiento) y solo después se evalúa su aporte predictivo *dentro* de la categoría de controles legítimos. Requiere tener, aunque sea de forma preliminar, un DAG propuesto —lo cual no siempre es cómodo cuando se está en la fase exploratoria de un proyecto— pero previene sistemáticamente la clase de error más costosa de este curso.
]

== Decisión de referencia para el curso
<sec-featuresfuga-decision>

Todo notebook de estimación del curso extiende el `CausalSchema` del @cap-ingenieria-datos-causales con una etapa de *auditoría de features* obligatoria antes de construir cualquier matriz de covariables $X$: cada columna candidata se anota con su rol supuesto (confusor / post-tratamiento / desconocido) y solo las anotadas como confusor —o "desconocido, incluida con advertencia explícita para análisis de sensibilidad"— entran en $X$.

== Implementación de referencia
<sec-featuresfuga-implementacion>

#figure(
  kind: raw,
  caption: [Auditoría de _features_ por marca de tiempo y por rol declarado.],
  ```python
import pandas as pd

def auditar_features(df: pd.DataFrame, treatment_time_col: str,
                      feature_time_cols: dict[str, str],
                      roles_declarados: dict[str, str]) -> pd.DataFrame:
    """Marca cada feature con riesgo de fuga temporal (medida despues
    del tratamiento) y con su rol causal declarado por el analista."""
    filas = []
    for feature, tiempo_col in feature_time_cols.items():
        posterior = (df[tiempo_col] > df[treatment_time_col]).mean()
        filas.append({
            "feature": feature,
            "pct_medida_despues_del_tratamiento": posterior,
            "riesgo_temporal": posterior > 0.0,
            "rol_declarado": roles_declarados.get(feature, "SIN DECLARAR"),
            "incluir_en_X": roles_declarados.get(feature) == "confusor" and posterior == 0.0,
        })
    resultado = pd.DataFrame(filas)
    riesgosas = resultado[resultado["riesgo_temporal"] | (resultado["rol_declarado"] == "SIN DECLARAR")]
    if len(riesgosas) > 0:
        print("ADVERTENCIA: features con riesgo de fuga o sin rol declarado:")
        print(riesgosas[["feature", "pct_medida_despues_del_tratamiento", "rol_declarado"]])
    return resultado
```
) <lst-auditoria-features>

La función no decide automáticamente qué incluir —esa decisión sigue siendo del analista, informada por el grafo— pero hace *imposible* que una variable post-tratamiento entre a $X$ en silencio: cualquier _feature_ medida después del tratamiento, o sin rol declarado, genera una advertencia explícita.

== Aplicación al sistema causal del curso
<sec-featuresfuga-aplicacion>

El Notebook de caso de estudio A2 (Módulo 2, Double Machine Learning) exige ejecutar la auditoría del listado @lst-auditoria-features sobre la matriz de covariables *antes* de estimar el modelo PLR/IRM del @cap-dml. Esto conecta directamente con un punto que ese capítulo asume resuelto: la validez de la ortogonalidad de Neyman depende de que $X$ contenga controles legítimos, no mediadores ni colliders disfrazados de covariables predictivas.

== Señales de alerta y checklist operativo
<sec-featuresfuga-alertas>

#checklist[
  - Una _feature_ mejora sustancialmente el ajuste predictivo del modelo de resultado sin que exista una razón causal clara para incluirla.
  - Ninguna columna del dataset tiene una marca de tiempo que permita verificar si fue medida antes o después del tratamiento.
  - El equipo agregó una _feature_ "porque funcionaba mejor en las pruebas" sin volver a evaluar el DAG.
  - Existen _features_ derivadas (ingeniería de variables) cuya fórmula de construcción usa, aunque sea indirectamente, el propio resultado $Y$.
]

== Ejercicios y notas bibliográficas
<sec-featuresfuga-ejercicios>

=== Ejercicios conceptuales
<sec-featuresfuga-ejercicios-conceptuales>

+ Para el dataset de retornos a la educación, clasifique las siguientes variables candidatas a `covariates` según la tabla de la @sec-intervcontra-controles: habilidad cognitiva medida antes de ingresar a la escuela; puntaje de un examen de egreso universitario; cercanía geográfica a una universidad; ingreso de los padres.

+ Explique por qué una _feature_ construida como "promedio móvil del resultado en las últimas 4 semanas" es casi siempre una fuente de fuga en un sistema causal, incluso si en un sistema puramente predictivo sería una _feature_ razonable.

=== Ejercicio computacional
<sec-featuresfuga-ejercicios-computacionales>

+ Aplique el listado @lst-auditoria-features al dataset que eligió para el Notebook A1, declarando roles causales para al menos 6 covariables candidatas. Reporte cuántas quedan excluidas de $X$ tras la auditoría y por qué motivo cada una.

=== Notas bibliográficas
<sec-featuresfuga-notas>

@huyen2022dmls, Capítulo 5, cubre la ingeniería de _features_ genérica y la fuga de datos (_data leakage_) en su sentido predictivo estándar (por ejemplo, escalar antes de separar train/test); este capítulo extiende esa discusión al tipo de fuga específico de sistemas causales. La clasificación de controles retomada aquí se desarrolla en @bareinboim2025causalai y @pearl2009causality, ya citados en el @cap-intervencion-contrafactual.
