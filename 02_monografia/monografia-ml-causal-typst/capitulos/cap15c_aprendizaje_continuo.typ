// Capítulo 31 (nuevo) — Aprendizaje continuo y panorama de RL causal
// Plantilla híbrida A/B: Sesión 27.
#import "../template/template.typ": *

#chapter[Aprendizaje continuo y panorama de _Reinforcement Learning_ causal]
<cap-aprendizaje-continuo>

#theorem-number-reset()

#cuadrosinoptico[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*[Problema]*], [Cuándo y cómo actualizar un sistema causal; cómo la PCH se extiende a decisiones secuenciales],
    [*[Parte I]*], [Aprendizaje continuo — decisión de ingeniería (Plantilla B)],
    [*[Parte II]*], [RL causal — panorama conceptual (Plantilla A, sin implementación completa)],
    [*[Herramientas]*], [_Shadow deployment_, _champion-challenger_; bandits causales como caso introductorio de RL causal],
    [*[Alcance]*], [La Parte II es deliberadamente un panorama: RL causal es un programa de investigación activo, no una receta cerrada],
  )
]

Este capítulo tiene una estructura distinta al resto del libro porque combina una decisión de ingeniería concreta —cuándo reentrenar un sistema causal, y cómo hacerlo sin ponerlo en riesgo— con un panorama conceptual de una frontera de investigación activa: qué pasa cuando las "acciones" no son una elección única sino una secuencia de decisiones que se retroalimentan con el entorno, el problema que estudia el _Reinforcement Learning_ (RL).

== Parte I: Aprendizaje continuo para sistemas causales
<sec-continuo-parte1>

=== El problema de diseño
<sec-continuo-problema>

El @cap-monitoreo-causal dejó una pregunta abierta: cuando el reporte de monitoreo marca `requiere_atencion`, ¿qué se hace? @huyen2022dmls (Capítulo 9, "Continual Learning and Test in Production") describe el espectro de respuestas posibles, desde no hacer nada hasta reentrenar automáticamente en cada lote de datos nuevo. Para un sistema *causal*, este capítulo ya adelantó en el @cap-anatomia-sistema por qué la respuesta no es trivial: reentrenar con datos nuevos puede cambiar silenciosamente la población para la cual el efecto es válido, no solo su varianza.

=== Opciones y trade-offs
<sec-continuo-opciones>

#opciones[
  - *Reentrenamiento automático periódico.* El estimador se reajusta con los datos más recientes en un cronograma fijo (semanal, mensual), sin intervención humana. Minimiza el trabajo operativo pero, para un sistema causal, corre el riesgo de que el nuevo estimador refleje una población o un mecanismo distintos sin que nadie lo audite antes de publicarlo — el problema exacto que el Capítulo 20 buscaba prevenir con pruebas automatizadas, pero que una prueba de placebo sola no basta para descartar (un cambio genuino y legítimo en el efecto también pasaría el placebo).
  - *_Champion-challenger_ con validación humana.* El modelo reentrenado ("challenger") se evalúa en paralelo al modelo en producción ("champion") sobre el mismo período de datos, y solo reemplaza al champion si supera un chequeo explícito —incluyendo, para un sistema causal, una revisión de que los supuestos de identificación siguen siendo defendibles para los datos nuevos, no solo una comparación de métricas—. Es más lento y requiere mantener ambos modelos corriendo simultáneamente, pero es la opción que preserva la posibilidad de que un humano intercepte un cambio de población antes de que afecte a producción.
]

=== Decisión de referencia para el curso
<sec-continuo-decision>

El curso adopta el patrón _champion-challenger_: ninguna actualización del modelo reemplaza al servicio en producción automáticamente. El _challenger_ se entrena sobre datos recientes, se somete a las mismas pruebas del @cap-cicd-causal más una comparación explícita de su población de entrenamiento contra la del _champion_ (usando el chequeo de balance del @cap-datos-entrenamiento-causales), y solo se promueve tras esa doble validación.

#figure(
  kind: raw,
  caption: [Comparación champion-challenger antes de promover un reentrenamiento.],
  ```python
def evaluar_challenger(champion, challenger, df_reciente, schema, alpha=0.05):
    resultado = {
        "pasa_tests_estadisticos": True,  # asumir que ya paso CI/CD (Cap. 20)
        "poblacion_comparable": True,
    }
    # Comparar covariables de entrenamiento del challenger vs. champion
    from scipy import stats
    for c in schema.covariates:
        _, p = stats.ks_2samp(champion.datos_entrenamiento[c], df_reciente[c])
        if p < alpha:
            resultado["poblacion_comparable"] = False
    resultado["promover"] = resultado["pasa_tests_estadisticos"] and resultado["poblacion_comparable"]
    if not resultado["promover"]:
        resultado["accion"] = "Revision humana requerida antes de promover"
    return resultado
```
) <lst-champion-challenger>

Si `poblacion_comparable` es falso, el sistema no promueve automáticamente al _challenger_ aunque haya pasado todas las pruebas estadísticas de placebo — precisamente porque un cambio de población puede ser perfectamente consistente con un placebo no significativo y, aun así, representar un efecto válido para una población distinta a la que el equipo cree estar sirviendo.

== Parte II: Panorama de _Reinforcement Learning_ causal
<sec-continuo-parte2>

=== De decisiones únicas a decisiones secuenciales
<sec-continuo-rl-motivacion>

Todo el curso, hasta este punto, trató la decisión como una elección única: estimar un efecto, elegir una política, desplegarla. El RL estudia el caso donde un agente toma una *secuencia* de decisiones, cada una afectando el estado futuro del entorno y, por tanto, las decisiones siguientes —por ejemplo, un sistema de recomendación que decide qué mostrar en cada visita, sabiendo que la decisión de hoy afecta qué datos se observarán mañana—. El RL clásico optimiza esta secuencia asumiendo, casi siempre implícitamente, que el entorno reacciona a las acciones sin confusión oculta entre las decisiones pasadas del agente y las recompensas futuras. Bareinboim (@bareinboim2025causalai, Capítulos 8–9) muestra que este supuesto falla con frecuencia en RL aplicado a datos observacionales —por ejemplo, cuando los datos de entrenamiento provienen de un agente humano anterior cuyas decisiones estaban confundidas por información que el nuevo agente no observa—, y que ignorar esta confusión produce políticas sistemáticamente sesgadas.

=== Bandits causales: el caso introductorio más simple
<sec-continuo-bandits>

El caso más simple de esta frontera —un puente natural desde el _policy learning_ del Capítulo 21— son los *bandits causales* (@bareinboim2015bandits): una versión del clásico problema de bandidos de múltiples brazos donde existen variables de contexto no observadas por el agente pero que sí afectaron las decisiones registradas en los datos históricos con los que se pre-entrena. Ignorar esta confusión —tratar los datos históricos como si las decisiones pasadas hubieran sido aleatorias— produce estimaciones de recompensa esperada por brazo tan sesgadas como ignorar la confusión en cualquier otro estimador de este curso; la solución, en el espíritu del @cap-intervencion-contrafactual, es identificar qué información de contexto es segura de condicionar y cuál introduce sesgo de puerta trasera en la política aprendida.

=== Por qué este curso se detiene aquí
<sec-continuo-alcance>

RL causal es, en 2026, un programa de investigación activo más que un conjunto de recetas maduras y ampliamente adoptadas en producción —a diferencia de DML o los meta-learners de la Parte II, que ya cuentan con implementaciones estándar y una práctica de la industria asentada—. Este curso se detiene deliberadamente en el nivel de panorama conceptual: entender *por qué* la confusión importa en RL, y *cómo* se conecta con todo lo aprendido sobre identificación causal, sin pretender una cobertura de implementación que la madurez actual del campo no respalda todavía.

== Ejercicios y notas bibliográficas
<sec-continuo-ejercicios>

=== Ejercicios conceptuales
<sec-continuo-ejercicios-conceptuales>

+ Explique por qué una prueba de placebo no significativa (Capítulo 14) no es evidencia suficiente de que un modelo reentrenado sea seguro de promover a producción, en el sentido del patrón _champion-challenger_ de este capítulo.

+ Para el ejemplo de bandits causales de la @sec-continuo-bandits, describa un escenario concreto (puede ser hipotético) donde ignorar la confusión en los datos históricos llevaría a un agente a subestimar sistemáticamente el valor de un brazo/acción poco explorada.

=== Ejercicio de infraestructura
<sec-continuo-ejercicios-infra>

+ Implemente el listado @lst-champion-challenger sobre dos versiones de su modelo del Notebook A2 (entrenadas sobre dos submuestras deliberadamente distintas del dataset, simulando un cambio de población). Verifique que el sistema correctamente marca la necesidad de revisión humana.

=== Notas bibliográficas
<sec-continuo-notas>

@huyen2022dmls, Capítulo 9, desarrolla en profundidad los patrones de aprendizaje continuo y pruebas en producción (incluyendo _champion-challenger_ y _shadow deployment_) en su versión genérica para ML. @bareinboim2025causalai, Capítulos 8–9, es la referencia central del panorama de RL causal de este capítulo; @bareinboim2015bandits formaliza el caso introductorio de bandits causales.
