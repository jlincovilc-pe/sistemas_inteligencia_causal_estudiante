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
    [*Decisión:*], [Monitorear la validez de los supuestos causales, no solo la distribución de entradas y salidas],
    [*Alternativas:*], [Monitoreo genérico de ML (drift de _inputs_/_outputs_) vs. monitoreo causal-aware (drift de identificación)],
    [*Trade-off clave:*], [Costo de cómputo del monitoreo adicional vs. riesgo de servir estimaciones inválidas sin saberlo],
    [*Stack:*], [`scipy.stats`, Streamlit/Gradio para el dashboard],
    [*Riesgo principal:*], [Que el servicio siga respondiendo con normalidad mientras el efecto que reporta ya no es válido],
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
  - *Monitoreo causal-aware.* Extiende el monitoreo genérico con métricas específicas: reejecutar el chequeo de balance del @cap-datos-entrenamiento-causales sobre los datos recientes, verificar que el soporte común no se haya erosionado, y —cuando aplica— verificar que la fuerza del instrumento (el $F$-estadístico de la primera etapa, @cap-panel-dmliv) no haya caído por debajo de los umbrales convencionales. Es más costoso de mantener y requiere mantener disponible el pipeline de estimación completo, no solo el servicio de predicción, para poder recalcular estas métricas periódicamente.
]

== Decisión de referencia para el curso
<sec-monitoreo-decision>

El sistema de referencia del curso monitorea cuatro métricas causales específicas, además del monitoreo genérico de _inputs_: *(i)* _drift_ de covariables por variable; *(ii)* _drift_ de la relación *entre* covariables y tratamiento, que es la que sostiene el supuesto de identificación; *(iii)* fuerza de la relación tratamiento-instrumento en la ventana reciente, cuando el diseño la usa; *(iv)* estabilidad del efecto *reestimado* en ventanas móviles, contrastada mediante un test formal y no por inspección de si un número cae dentro de un intervalo.

Tres precisiones sobre el diseño de estas métricas, porque la versión ingenua de cada una falla de forma característica.

*Sobre (i): el test KS no es suficiente y su $p$-valor engaña.* Con ventanas grandes, el test de Kolmogorov–Smirnov rechaza ante diferencias irrelevantes; con ventanas pequeñas, no detecta diferencias materiales. Es el mismo problema que el $t$-test tenía en el chequeo de balance del @cap-datos-entrenamiento-causales, y admite la misma solución: reportar un *tamaño de efecto* junto al $p$-valor. Las dos medidas convencionales son la *ASMD* (diferencia media estandarizada absoluta, la SMD ya usada en aquel capítulo, aplicada ahora entre entrenamiento y ventana reciente) y el *PSI* (_Population Stability Index_), $"PSI" = sum_b (p_b - q_b) log(p_b \/ q_b)$ sobre una discretización en _bins_, cuyos umbrales convencionales en la industria son $"PSI" < 0.1$ (estable), $0.1$–$0.25$ (revisar) y $> 0.25$ (deriva material).

*Sobre (ii): el drift que rompe la identificación puede no mover ninguna marginal.* Esta es la métrica que distingue el monitoreo causal del genérico, y suele omitirse. La no confusión no depende de la distribución marginal de cada covariable sino de la *relación* entre covariables y asignación al tratamiento. Si el criterio con que se asigna el tratamiento cambia —un nuevo equipo comercial prioriza distinto, se modifica una regla de elegibilidad— la distribución de cada $X_j$ puede permanecer idéntica y aun así el supuesto de identificación haber dejado de sostenerse. La forma económica de vigilarlo es monitorear el *poder discriminativo del propensity score*: reajustar $hat(e)(X)$ sobre la ventana reciente y comparar su AUC contra la de entrenamiento. Un salto en esa AUC indica que las covariables predicen la asignación mejor (o peor) que antes, es decir, que el mecanismo de asignación cambió.

*Sobre (iv): comparar un punto contra un intervalo no es un test.* Verificar si el efecto reciente cae dentro del IC original ignora por completo la incertidumbre del efecto reciente, y por tanto ni controla el error de tipo I ni tiene potencia interpretable. El contraste correcto es entre dos estimaciones, cada una con su error estándar: bajo independencia de las dos ventanas, $ z = (hat(theta)_"rec" - hat(theta)_"orig") \/ sqrt("SE"_"rec"^2 + "SE"_"orig"^2) $ es aproximadamente normal estándar bajo la hipótesis nula de efecto estable. Esto exige *reestimar* el efecto en la ventana reciente —no solo predecir con el modelo antiguo, que por construcción devuelve el efecto antiguo— y es la razón por la que el monitoreo causal requiere mantener disponible el pipeline de estimación completo y no solo el servicio de inferencia.

== Implementación de referencia
<sec-monitoreo-implementacion>

#figure(
  kind: raw,
  caption: [Las cuatro métricas de monitoreo causal sobre una ventana reciente de datos.],
  ```python
import numpy as np
import pandas as pd
import statsmodels.api as sm
from scipy import stats
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import cross_val_predict

# --- (i) Drift marginal de covariables: tamano de efecto + p-valor ----
def drift_covariables(df_train, df_rec, covariables, psi_bins=10):
    """PSI y ASMD por covariable. El p-valor KS se reporta pero NO se usa
    como criterio: con ventanas grandes rechaza ante diferencias
    irrelevantes (mismo problema que el t-test en el chequeo de balance)."""
    filas = []
    for c in covariables:
        a, b = df_train[c].dropna(), df_rec[c].dropna()
        s_pool = np.sqrt((a.var(ddof=1) + b.var(ddof=1)) / 2)
        asmd = abs(a.mean() - b.mean()) / s_pool if s_pool > 0 else 0.0
        # PSI sobre bins definidos por los cuantiles de ENTRENAMIENTO
        bordes = np.unique(np.quantile(a, np.linspace(0, 1, psi_bins + 1)))
        p = np.histogram(a, bins=bordes)[0] / len(a)
        q = np.histogram(b, bins=bordes)[0] / len(b)
        eps = 1e-6
        p, q = np.clip(p, eps, None), np.clip(q, eps, None)
        psi = float(((p - q) * np.log(p / q)).sum())
        filas.append({
            "covariable": c, "asmd": asmd, "psi": psi,
            "p_ks": stats.ks_2samp(a, b).pvalue,
            # Umbrales convencionales; declararlos, no descubrirlos
            "alerta": (psi > 0.25) or (asmd > 0.25),
        })
    return pd.DataFrame(filas).sort_values("psi", ascending=False)

# --- (ii) Drift de la relacion X -> D (lo que rompe la identificacion) -
def drift_mecanismo_asignacion(df_train, df_rec, covariables, tratamiento,
                               tolerancia=0.05):
    """Compara el poder discriminativo del propensity score entre ambas
    ventanas. Un cambio detecta que el mecanismo de asignacion cambio,
    incluso si NINGUNA distribucion marginal se movio."""
    def auc(df):
        p = cross_val_predict(LogisticRegression(max_iter=1000),
                              df[covariables], df[tratamiento],
                              cv=5, method="predict_proba")[:, 1]
        return roc_auc_score(df[tratamiento], p)
    auc_train, auc_rec = auc(df_train), auc(df_rec)
    return {"auc_entrenamiento": auc_train, "auc_reciente": auc_rec,
            "delta_auc": auc_rec - auc_train,
            "alerta": abs(auc_rec - auc_train) > tolerancia}

# --- (iii) Fuerza del instrumento -------------------------------------
def fuerza_instrumento(df_rec, instrumento, tratamiento, covariables, umbral_f=10):
    """F de la PRIMERA ETAPA sobre el instrumento excluido. Umbral
    convencional F > 10 (criterio de @stock2005testing, Stock & Yogo 2005).
    Doble umbral operativo: F > 10 sano; F en (5, 10) atencion (reportar
    tambien el IC de Anderson--Rubin, Cap. 17); F < 5 alerta."""
    X = sm.add_constant(df_rec[[instrumento] + covariables])
    modelo = sm.OLS(df_rec[tratamiento], X).fit()
    # f_test sobre el instrumento, NO el F global del modelo: el F global
    # mide el ajuste conjunto de TODOS los regresores e infla el
    # diagnostico cuando las covariables predicen bien el tratamiento.
    restriccion = np.zeros((1, X.shape[1]))
    restriccion[0, list(X.columns).index(instrumento)] = 1
    f_stat = float(modelo.f_test(restriccion).fvalue)
    return {"f_primera_etapa": f_stat, "alerta_debil": f_stat < umbral_f}

# --- (iv) Estabilidad del efecto: contraste formal entre ventanas ------
def estabilidad_efecto(reestimar, df_rec, theta_orig, se_orig, alpha=0.05):
    """Reestima el efecto en la ventana reciente y contrasta H0: los dos
    efectos son iguales, propagando AMBOS errores estandar.

    `reestimar(df) -> (theta, se)` corre el pipeline completo del Cap. 11.
    No basta con predecir con el modelo antiguo: eso devuelve, por
    construccion, el efecto antiguo.
    """
    theta_rec, se_rec = reestimar(df_rec)
    # Test de estabilidad del efecto (propagando SE)
    se_combinado = np.sqrt(se_orig**2 + se_rec**2)
    z_estabilidad = abs(theta_rec - theta_orig) / se_combinado
    p_estabilidad = 2 * (1 - stats.norm.cdf(abs(z_estabilidad)))
    
    # Impresiones de diagnóstico
    print(f"Cambio absoluto: {abs(theta_rec - theta_orig):.4f}")
    print(f"SE combinado: {se_combinado:.4f}")
    print(f"Z-estadístico: {z_estabilidad:.2f}")
    print(f"P-valor: {p_estabilidad:.4f}")
    
    if p_estabilidad < 0.05:
        print("⚠️ Efecto significativamente diferente (drift detectado)")
    else:
        print("✓ Efecto estable")
    
    return {"theta_original": theta_orig, "theta_reciente": theta_rec,
            "se_reciente": se_rec, "z": z_estabilidad, "p_valor": p_estabilidad,
            "alerta": p_estabilidad < alpha}

def reporte_monitoreo(df_train, df_rec, schema, reestimar, theta_orig, se_orig,
                      instrumento=None):
    drift = drift_covariables(df_train, df_rec, schema.covariates)
    reporte = {
        "drift_covariables": drift,
        "drift_mecanismo_asignacion": drift_mecanismo_asignacion(
            df_train, df_rec, schema.covariates, schema.treatment),
        "estabilidad_efecto": estabilidad_efecto(
            reestimar, df_rec, theta_orig, se_orig),
    }
    if instrumento:
        reporte["fuerza_instrumento"] = fuerza_instrumento(
            df_rec, instrumento, schema.treatment, schema.covariates)
    reporte["requiere_atencion"] = bool(
        drift["alerta"].any()
        or reporte["drift_mecanismo_asignacion"]["alerta"]
        or reporte["estabilidad_efecto"]["alerta"]
        or reporte.get("fuerza_instrumento", {}).get("alerta_debil", False)
    )
    return reporte
```
) <lst-monitoreo-causal>

El test de estabilidad compara el efecto estimado en la ventana reciente contra el efecto de entrenamiento original, *propagando el error estándar de ambas estimaciones* para construir un test Z válido.

Las cuatro funciones reutilizan directamente infraestructura ya construida en capítulos anteriores: `drift_covariables` es el chequeo de balance del @cap-datos-entrenamiento-causales —con los mismos estadísticos de tamaño de efecto— aplicado ahora a la comparación entrenamiento/reciente en lugar de tratados/controles; `drift_mecanismo_asignacion` reutiliza el _propensity score_ que el @cap-dml ya estima como _nuisance_; `fuerza_instrumento` es el diagnóstico de instrumentos débiles del @cap-panel-dmliv; y `estabilidad_efecto` requiere el pipeline de estimación completo, no solo el modelo servido en el @cap-despliegue-servicio.

Una observación sobre el orden de las alertas, que es lo que hace útil el reporte en vez de solo ruidoso. Las cuatro métricas no son intercambiables ni igual de graves: el _drift_ marginal (i) es una señal *temprana* y con frecuencia benigna —la población cambia y el modelo puede seguir siendo válido—; el _drift_ del mecanismo de asignación (ii) ataca directamente el supuesto de identificación y es el más serio aunque el efecto estimado todavía no se haya movido; la caída de fuerza del instrumento (iii) invalida la inferencia aunque el efecto puntual parezca estable; y el cambio en el efecto (iv) es la señal *tardía*, la que llega cuando el problema ya está afectando a las decisiones. Un sistema que solo monitorea (iv) reacciona siempre tarde; uno que solo monitorea (i) genera alertas constantes sin consecuencia. El valor del reporte está en leer las cuatro juntas.

== Aplicación al sistema causal del curso
<sec-monitoreo-aplicacion>

El Notebook de producción B4 despliega la función `reporte_monitoreo` del listado @lst-monitoreo-causal como un dashboard (Streamlit o Gradio) sobre un escenario simulado de _drift_ gradual, donde las covariables se alejan progresivamente de la distribución de entrenamiento. El ejercicio pedagógico central es observar el *orden temporal* en que se encienden las alertas: `drift_covariables` primero, `estabilidad_efecto` bastante después —y a veces nunca, si el _drift_ ocurre en covariables que no modulan el efecto—. El _drift_ de covariables es, con frecuencia, la señal temprana de que el efecto reportado empezará a ser poco confiable, y monitorear solo el efecto final sin monitorear también sus insumos deja al sistema reaccionando tarde.

El segundo escenario del notebook es el complementario y el más instructivo: un _drift_ que altera la *regla de asignación* del tratamiento sin mover ninguna distribución marginal de covariables. Ahí `drift_covariables` no reporta nada —correctamente, porque nada marginal cambió— y solo `drift_mecanismo_asignacion` lo detecta. Es la demostración práctica de por qué un monitoreo de MLOps genérico, por completo que sea en su propio terreno, no basta para un sistema causal: el supuesto que se está violando no es una propiedad de los datos de entrada, sino de la relación entre ellos y la decisión que generó el tratamiento.

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

+ Construya un escenario simulado en el que la regla de asignación del tratamiento cambie (por ejemplo, que pase a depender de una covariable que antes no usaba) *manteniendo idénticas todas las distribuciones marginales de covariables*. Verifique que `drift_covariables` no reporta nada y que `drift_mecanismo_asignacion` sí. Explique qué supuesto de identificación se ha violado.

+ Compare, sobre una ventana con _drift_ leve, el veredicto del test formal de `estabilidad_efecto` con el del criterio ingenuo ("¿el efecto reciente cae dentro del IC original?"). Muestre un caso en que ambos difieran y argumente cuál de los dos debe gobernar la alerta.

=== Ejercicio de infraestructura (Lab, arranca Notebook B4)
<sec-monitoreo-ejercicios-infra>

+ Implemente el listado @lst-monitoreo-causal sobre su modelo del Notebook A2/B1, simulando una ventana de datos recientes con _drift_ deliberado en al menos una covariable. Verifique que el reporte detecta el _drift_ introducido.

=== Notas bibliográficas
<sec-monitoreo-notas>

#cite(<kastner2024mlip>, form: "prose") y #cite(<huyen2022dmls>, form: "prose") (Capítulo 8, "Data Distribution Shifts and Monitoring") desarrollan el monitoreo de _drift_ genérico que este capítulo extiende, incluida la taxonomía de _covariate shift_, _label shift_ y _concept drift_ que conviene tener presente al interpretar el reporte. El umbral convencional de $F > 10$ para descartar instrumentos débiles proviene de #cite(<stock2005testing>, form: "prose"), introducido en el @cap-panel-dmliv; recuérdese que está derivado para el caso de un instrumento y una primera etapa lineal, y que aplicarlo fuera de ese caso exige justificación adicional. Los criterios de balance sobre los que se apoya `drift_covariables` (ASMD y su umbral) son los de #cite(<rubin2001using>, form: "prose"), ya usados en el @cap-datos-entrenamiento-causales; el PSI, en cambio, no tiene una referencia académica canónica —es una convención de la industria del riesgo crediticio— y sus umbrales deben tratarse como reglas prácticas calibradas al dominio, no como criterios con respaldo teórico.
