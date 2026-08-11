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
    [*Decisión:*], [Auditar cada _feature_ candidata contra el grafo causal antes de incluirla, no solo contra su poder predictivo],
    [*Alternativas:*], [Selección de _features_ por importancia predictiva vs. selección por rol causal],
    [*Trade-off clave:*], [Una _feature_ que mejora el ajuste predictivo puede empeorar la estimación causal],
    [*Stack:*], [pandas, el `CausalSchema` del @cap-ingenieria-datos-causales],
    [*Riesgo principal:*], [_Fuga_ (_leakage_) de información post-tratamiento disfrazada de covariable],
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

Todo notebook de estimación del curso extiende el `CausalSchema` del @cap-ingenieria-datos-causales con una etapa de *auditoría de features* obligatoria antes de construir cualquier matriz de covariables $X$: cada columna candidata se anota con su rol supuesto (confusor / mediador / collider / post-tratamiento / desconocido) y la auditoría produce, no una sino *dos* especificaciones de $X$:

- $X_"base"$, con las variables anotadas como *confusor* y medidas antes del tratamiento. Es la especificación sobre la que se reporta la estimación principal.
- $X_"ampliada" = X_"base" union {"desconocido"}$, que añade las candidatas cuyo rol el analista no pudo determinar, siempre que sean pre-tratamiento. Es la especificación sobre la que se reporta el *análisis de sensibilidad*.

Las anotadas como mediador, collider o post-tratamiento no entran en ninguna de las dos. La razón de exigir dos especificaciones en lugar de una regla única es que las dos decisiones posibles sobre una variable de rol desconocido tienen riesgos opuestos y no comparables: excluirla arriesga sesgo por confusión omitida; incluirla arriesga sesgo por mal control. Ningún criterio automático resuelve esa disyuntiva, pero reportar ambas estimaciones convierte la duda en información —si el efecto es estable entre $X_"base"$ y $X_"ampliada"$, la ambigüedad de rol no era material; si no lo es, el capítulo entero de identificación tiene que reabrirse antes de publicar nada.

== Implementación de referencia
<sec-featuresfuga-implementacion>

#figure(
  kind: raw,
  caption: [Auditoría de _features_ por marca de tiempo y por rol declarado.],
  ```python
import pandas as pd

# Roles que NUNCA entran en X: su inclusion sesga la estimacion
# (ver la clasificacion de controles del capitulo anterior).
ROLES_PROHIBIDOS = {"mediador", "collider", "post_tratamiento"}

def auditar_features(df: pd.DataFrame, treatment_time_col: str,
                     feature_time_cols: dict[str, str],
                     roles_declarados: dict[str, str]) -> pd.DataFrame:
    """Marca cada feature con riesgo de fuga temporal (medida despues
    del tratamiento) y con su rol causal declarado por el analista.

    Devuelve dos indicadores de inclusion, no uno:
      - incluir_en_X_base:     especificacion principal (solo confusores)
      - incluir_en_X_ampliada: especificacion de sensibilidad (base + rol
                               desconocido, siempre pre-tratamiento)
    """
    filas = []
    for feature, tiempo_col in feature_time_cols.items():
        posterior = (df[tiempo_col] > df[treatment_time_col]).mean()
        rol = roles_declarados.get(feature, "desconocido")
        pre_tratamiento = posterior == 0.0
        es_confusor = rol == "confusor"
        # "desconocido" NO se excluye de facto: entra en la especificacion
        # ampliada para el analisis de sensibilidad, como exige la decision
        # de referencia del capitulo.
        rol_ambiguo = rol == "desconocido"
        filas.append({
            "feature": feature,
            "pct_medida_despues_del_tratamiento": posterior,
            "riesgo_temporal": not pre_tratamiento,
            "rol_declarado": rol,
            "incluir_en_X_base": es_confusor and pre_tratamiento,
            "incluir_en_X_ampliada": (
                (es_confusor or rol_ambiguo)
                and pre_tratamiento
                and rol not in ROLES_PROHIBIDOS
            ),
        })
    resultado = pd.DataFrame(filas)

    riesgosas = resultado[resultado["riesgo_temporal"]
                          | (resultado["rol_declarado"] == "desconocido")]
    if len(riesgosas) > 0:
        print("ADVERTENCIA: features con riesgo de fuga o sin rol determinado:")
        print(riesgosas[["feature", "pct_medida_despues_del_tratamiento",
                         "rol_declarado", "incluir_en_X_base",
                         "incluir_en_X_ampliada"]])
    n_amb = (resultado["rol_declarado"] == "desconocido").sum()
    if n_amb:
        print(f"{n_amb} feature(s) de rol ambiguo -> reportar la estimacion "
              "con X_base y con X_ampliada, y comparar.")
    return resultado


def columnas_X(resultado: pd.DataFrame, especificacion: str = "base") -> list[str]:
    """Extrae la lista de covariables de una de las dos especificaciones."""
    col = f"incluir_en_X_{especificacion}"
    return resultado.loc[resultado[col], "feature"].tolist()
```
) <lst-auditoria-features>

La función no decide por el analista cuál de las dos especificaciones es la "correcta" —esa decisión sigue siendo suya, informada por el grafo— pero hace *imposible* que una variable post-tratamiento entre a $X$ en silencio, y hace igualmente imposible que una variable de rol ambiguo desaparezca sin dejar rastro: aparece en la especificación ampliada y obliga a reportar la comparación. Nótese que la condición de fuga temporal se aplica a *ambas* especificaciones: ninguna cantidad de análisis de sensibilidad rescata a una covariable medida después del tratamiento.

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

+ Aplique el listado @lst-auditoria-features al dataset que eligió para el Notebook A1, declarando roles causales para al menos 6 covariables candidatas, de las cuales al menos una debe quedar como `desconocido`. Reporte cuántas quedan excluidas de $X_"base"$ y por qué motivo cada una, y compare $X_"base"$ con $X_"ampliada"$.

+ Estime el efecto con ambas especificaciones ($X_"base"$ y $X_"ampliada"$) y compare los dos intervalos de confianza. Si se solapan ampliamente, ¿qué concluye sobre la variable de rol ambiguo? ¿Y si no se solapan? Explique por qué, en el segundo caso, *ninguna* de las dos estimaciones es defendible sin resolver antes la pregunta de identificación.

=== Notas bibliográficas
<sec-featuresfuga-notas>

#cite(<huyen2022dmls>, form: "prose"), Capítulo 5, cubre la ingeniería de _features_ genérica y la fuga de datos (_data leakage_) en su sentido predictivo estándar (por ejemplo, escalar antes de separar train/test); este capítulo extiende esa discusión al tipo de fuga específico de sistemas causales. La clasificación de controles retomada aquí se desarrolla en @bareinboim2025causalai y @pearl2009causality, ya citados en el @cap-intervencion-contrafactual.
