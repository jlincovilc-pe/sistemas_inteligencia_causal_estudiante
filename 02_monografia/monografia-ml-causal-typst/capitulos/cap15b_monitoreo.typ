// Capítulo 30 (nuevo) — Monitoreo de supuestos causales en producción
// Plantilla B: Sesión 25. Notebook de producción HF #4 (parte 1).
#import "../template/template.typ": *

#chapter[Monitoreo de supuestos causales en producción]
<cap-monitoreo-causal>

#theorem-number-reset()

#cuadrodecision[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*[Decisión]*], [Monitorear la validez de los supuestos causales, no solo la distribución de entradas y salidas],
    [*[Alternativas]*], [Monitoreo genérico de ML (drift de _inputs_/_outputs_) vs. monitoreo causal-aware (drift de identificación)],
    [*[Trade-off clave]*], [Costo de cómputo del monitoreo adicional vs. riesgo de servir estimaciones inválidas sin saberlo],
    [*[Stack]*], [`scipy.stats`, Streamlit/Gradio para el dashboard],
    [*[Riesgo principal]*], [Que el servicio siga respondiendo con normalidad mientras el efecto que reporta ya no es válido],
  )
]

#monorepo[
  Dashboard de referencia: #code[04_notebooks_produccion_hf/B4_monitoring_dashboard/] (Streamlit; KS de covariables, tasa de tratamiento, proxy de estabilidad). Labs #code[L25] y #code[L27] (reentrenar vs alertar). Humo: #code[grade_b4.py]. El monitoreo del curso es *docente y simulado* sobre el benchmark; en un sistema real se conecta al tráfico del endpoint B1.
]

== El problema de diseño
<sec-monitoreo-problema>

El monitoreo estándar de sistemas de ML en producción —el que describe @kastner2024mlip en su discusión de _data distribution shifts_— vigila si la distribución de las variables de entrada o de las predicciones se aleja de la observada en entrenamiento. Ese monitoreo es necesario pero *no suficiente* para un sistema causal: el servicio del Capítulo 15 puede seguir respondiendo con total normalidad —mismo formato, mismo rango de valores, ninguna alerta de _drift_ estándar— mientras el efecto que reporta dejó de ser válido, porque cambió algo que ningún monitoreo de _drift_ genérico observa: la fuerza de un instrumento, el soporte común entre tratados y controles, o la estabilidad del efecto estimado en ventanas recientes de datos. El problema de diseño de este capítulo es definir qué métricas, específicas de validez causal y no solo de distribución de datos, deben monitorearse continuamente.

== Opciones y trade-offs
<sec-monitoreo-opciones>

#opciones[
  - *Monitoreo genérico.* Vigila solo la distribución univariada de las covariables de entrada (tests de Kolmogorov-Smirnov o similares) y, si acaso, la distribución de las predicciones. Es barato de implementar y es lo que ofrecen la mayoría de las herramientas de MLOps por defecto. No detecta, por construcción, ningún problema de identificación: un cambio en la relación entre covariables y tratamiento —que rompe el supuesto de no confusión sin alterar la distribución marginal de ninguna variable por separado— pasa completamente inadvertido.
  - *Monitoreo causal-aware.* Extiende el monitoreo genérico con métricas específicas: reejecutar el chequeo de balance del @cap-datos-entrenamiento-causales sobre los datos recientes, verificar que el soporte común no se haya erosionado, y —cuando aplica— verificar que la fuerza del instrumento (el $F$-estadístico de la primera etapa, capítulo 17) no haya caído por debajo de los umbrales convencionales. Es más costoso de mantener y requiere mantener disponible el pipeline de estimación completo, no solo el servicio de predicción, para poder recalcular estas métricas periódicamente.
]

== Decisión de referencia para el curso
<sec-monitoreo-decision>

El sistema de referencia del curso monitorea tres métricas causales específicas, además del monitoreo genérico de _inputs_: *(i)* _drift_ de covariables por variable (test KS individual, no solo agregado); *(ii)* fuerza de la relación tratamiento-instrumento en la ventana reciente, cuando el diseño la usa; *(iii)* estabilidad del efecto estimado en ventanas móviles, recalculando el estimador sobre subconjuntos recientes de datos y comparando contra el intervalo de confianza original.

== Implementación de referencia
<sec-monitoreo-implementacion>

#figure(
  kind: raw,
  caption: [Las tres métricas de monitoreo causal sobre una ventana reciente de datos.],
  ```python
import numpy as np
import pandas as pd
from scipy import stats

def drift_covariables(df_entrenamiento, df_reciente, covariables, alpha=0.05):
    alertas = {}
    for c in covariables:
        _, p = stats.ks_2samp(df_entrenamiento[c].dropna(), df_reciente[c].dropna())
        alertas[c] = p < alpha
    return alertas

def fuerza_instrumento(df_reciente, instrumento, tratamiento, covariables, umbral_f=10):
    import statsmodels.api as sm
    X = sm.add_constant(df_reciente[[instrumento] + covariables])
    modelo = sm.OLS(df_reciente[tratamiento], X).fit()
    f_stat = modelo.fvalue
    return {"f_stat": f_stat, "alerta_debil": f_stat < umbral_f}

def estabilidad_efecto(modelo, df_entrenamiento_efecto, df_reciente, covariables, ic_original):
    efecto_reciente = modelo.effect(df_reciente[covariables]).mean()
    ic_inf, ic_sup = ic_original
    fuera_de_rango = not (ic_inf <= efecto_reciente <= ic_sup)
    return {"efecto_reciente": efecto_reciente, "fuera_del_ic_original": fuera_de_rango}

def reporte_monitoreo(df_entrenamiento, df_reciente, schema, modelo, ic_original, instrumento=None):
    reporte = {
        "drift_covariables": drift_covariables(df_entrenamiento, df_reciente, schema.covariates),
        "estabilidad_efecto": estabilidad_efecto(modelo, df_entrenamiento, df_reciente,
                                                   schema.covariates, ic_original),
    }
    if instrumento:
        reporte["fuerza_instrumento"] = fuerza_instrumento(
            df_reciente, instrumento, schema.treatment, schema.covariates)
    n_alertas = sum(reporte["drift_covariables"].values()) + \
                int(reporte["estabilidad_efecto"]["fuera_del_ic_original"])
    reporte["requiere_atencion"] = n_alertas > 0
    return reporte
```
) <lst-monitoreo-causal>

Las tres funciones reutilizan directamente infraestructura ya construida en capítulos anteriores: `drift_covariables` es, literalmente, el chequeo de balance del @cap-datos-entrenamiento-causales aplicado a datos recientes en lugar de a la comparación tratados/controles; `estabilidad_efecto` reutiliza el `CausalSchema` del @cap-ingenieria-datos-causales y el propio modelo servido en el @cap-despliegue-servicio.

== Aplicación al sistema causal del curso
<sec-monitoreo-aplicacion>

El Notebook de producción B4 despliega la función `reporte_monitoreo` del listado @lst-monitoreo-causal como un dashboard (Streamlit o Gradio) sobre un escenario simulado de _drift_ gradual, donde las covariables se alejan progresivamente de la distribución de entrenamiento. El ejercicio pedagógico central es observar que las alertas de `drift_covariables` suelen dispararse *antes* de que `estabilidad_efecto` detecte un problema — el _drift_ de covariables es, con frecuencia, la señal temprana de que el efecto reportado empezará a ser poco confiable, y monitorear solo el efecto final sin monitorear también sus insumos deja al sistema reaccionando tarde.

== Señales de alerta y checklist operativo
<sec-monitoreo-alertas>

#checklist[
  - El sistema solo monitorea la disponibilidad del endpoint (¿responde?), no la validez estadística de lo que responde.
  - El chequeo de balance del entrenamiento nunca se vuelve a ejecutar sobre datos de producción.
  - No existe una ventana de referencia fija para comparar la estabilidad del efecto; cada comparación usa un punto de referencia distinto, haciendo las alertas no comparables en el tiempo.
  - Las alertas de monitoreo se generan pero nadie las revisa —no hay un proceso definido de qué hacer cuando `requiere_atencion` es verdadero (retomado en el @cap-aprendizaje-continuo).
]

== Ejercicios y notas bibliográficas
<sec-monitoreo-ejercicios>

=== Ejercicios conceptuales
<sec-monitoreo-ejercicios-conceptuales>

+ Explique por qué el monitoreo genérico de _drift_ de predicciones (vigilar solo la distribución de $hat(Y)$) puede no detectar un problema de validez causal aunque la distribución de $hat(Y)$ se mantenga estable.

+ Para el sistema del Notebook A2 (DML sobre retornos a la educación), proponga un escenario concreto de cambio en los datos que dispare una alerta de `fuerza_instrumento` sin disparar ninguna alerta de `drift_covariables`.

=== Ejercicio de infraestructura (Lab, arranca Notebook B4)
<sec-monitoreo-ejercicios-infra>

+ Implemente el listado @lst-monitoreo-causal sobre su modelo del Notebook A2/B1, simulando una ventana de datos recientes con _drift_ deliberado en al menos una covariable. Verifique que el reporte detecta el _drift_ introducido.

=== Notas bibliográficas
<sec-monitoreo-notas>

@kastner2024mlip y @huyen2022dmls (Capítulo 8, "Data Distribution Shifts and Monitoring") desarrollan el monitoreo de _drift_ genérico que este capítulo extiende. El umbral convencional de $F>10$ para descartar instrumentos débiles proviene de la literatura de variables instrumentales, ya introducida en el Capítulo 17 de este curso.
