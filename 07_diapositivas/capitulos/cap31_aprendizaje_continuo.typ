// =============================================================================
// Diapositivas · Capítulo 31 — Aprendizaje continuo y panorama de
// Reinforcement Learning causal
// Fuente: 02_monografia/.../capitulos/cap15c_aprendizaje_continuo.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 31"
// Sesión S27 · Lab L27 · Entrega: B4 · Variante HÍBRIDA A/B · ★ camino crítico
//
// Mazo híbrido: Parte I (aprendizaje continuo) sigue el esqueleto B; Parte II
// (panorama RL causal) sigue el esqueleto A ligero, sin teorema formal — el propio
// libro lo declara panorama conceptual, no receta cerrada.
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 31, titulo: "Aprendizaje continuo y panorama de Reinforcement Learning causal",
  parte: "VIII", sesion: "S27", variant: "B", critico: true)

#cap-progreso-curso(cap-actual: 31)
#cap-portada(num: 31, titulo: "Aprendizaje continuo y panorama de Reinforcement Learning causal",
  parte: "VIII", sesion: "S27", variant: "B", critico: true)

#cap-roadmap(
  objetivos: (
    [Implementar el patrón champion-challenger con doble validación.],
    [Explicar por qué un placebo no significativo no basta para promover un
     reentrenamiento.],
    [Describir por qué combinar datos observacionales e interventivos acelera la
     convergencia en bandits causales.],
  ),
  agenda: (
    [Parte I: cuándo y cómo reentrenar sin poner en riesgo el sistema],
    [Reentrenamiento automático vs. champion-challenger],
    [Doble validación: placebo + comparación de poblaciones],
    [Parte II: de decisiones únicas a secuenciales — panorama RL causal],
    [Bandits causales: combinar observacional + interventivo acelera la
     convergencia],
  ),
  lectura: "Cap. 31 — Aprendizaje continuo (@cap-aprendizaje-continuo)",
  lab: "L27", entrega: "B4",
)

// ===== Parte I: variante B =====
#cap-problema-diseno(
  decision: "Cuándo y cómo actualizar un sistema causal sin ponerlo en riesgo.",
  alternativas: "Reentrenamiento automático periódico vs. champion-challenger con
    validación humana.",
  tradeoff: "Reentrenar sin auditoría (rápido, arriesgado) vs. champion-challenger
    (más lento, preserva intercepción humana).",
  stack: "scipy.stats (KS para comparar poblaciones), el pipeline de CI del Cap. 20.",
  riesgo: "Que el nuevo estimador refleje una población o mecanismo distintos sin que
    nadie lo audite antes de publicarlo.",
)

#cap-opciones-tradeoffs(opciones: (
  ([Reentrenamiento automático], [Minimiza trabajo operativo. Riesgo: un cambio
    genuino y legítimo en el efecto también pasaría un placebo — la prueba de humo
    sola no basta para descartar un cambio de población.]),
  ([Champion-challenger], [El challenger se evalúa en paralelo; solo reemplaza al
    champion tras revisar que los supuestos de identificación siguen siendo
    defendibles, no solo comparar métricas.]),
))

#cap-decision-referencia(
  decision: "Champion-challenger: ninguna actualización reemplaza al servicio
    automáticamente. El challenger pasa las pruebas del Cap. 20 MÁS una comparación
    explícita de su población de entrenamiento contra la del champion (chequeo de
    balance del Cap. 7).",
  justificacion: "Un cambio de población puede ser perfectamente consistente con un
    placebo no significativo y, aun así, representar un efecto válido para una
    población distinta a la que el equipo cree estar sirviendo.",
)

#cap-codigo-parte(
  titulo: "evaluar_challenger()",
  snippet: "def evaluar_challenger(champion, challenger, df_reciente, schema, alpha=0.05):\n"
    + "    resultado = {\n"
    + "        \"pasa_tests_estadisticos\": True,  # ya paso CI/CD (Cap. 20)\n"
    + "        \"poblacion_comparable\": True,\n"
    + "    }\n"
    + "    from scipy import stats\n"
    + "    for c in schema.covariates:\n"
    + "        _, p = stats.ks_2samp(champion.datos_entrenamiento[c], df_reciente[c])\n"
    + "        if p < alpha:\n"
    + "            resultado[\"poblacion_comparable\"] = False\n"
    + "    resultado[\"promover\"] = (resultado[\"pasa_tests_estadisticos\"]\n"
    + "                             and resultado[\"poblacion_comparable\"])\n"
    + "    if not resultado[\"promover\"]:\n"
    + "        resultado[\"accion\"] = \"Revision humana requerida antes de promover\"\n"
    + "    return resultado",
  nota: "Doble validacion: las pruebas estadisticas del Cap. 20 (placebo) MAS la
    comparacion KS por covariable contra la poblacion de entrenamiento del champion.
    Un cambio de poblacion puede ser consistente con un placebo no significativo.",
)

#cap-interactivo(
  tipo: "Conceptual",
  pregunta: "¿Por qué un placebo no significativo no es evidencia suficiente de que
    un modelo reentrenado sea seguro de promover a producción?",
)

// ===== Parte II: variante A ligera (panorama, sin teorema formal) =====
#cap-motivacion(
  problema: "Todo el curso trató la decisión como elección única: estimar, elegir
    política, desplegar. RL estudia decisiones SECUENCIALES, donde cada acción afecta
    el estado futuro y, por tanto, las decisiones siguientes.",
  gancho: "El RL clásico asume, casi siempre implícitamente, que el entorno reacciona
    sin confusión oculta entre decisiones pasadas y recompensas futuras — un supuesto
    que falla con frecuencia en datos observacionales.",
  caso: "Bandits causales: puente natural desde el policy learning del Cap. 21.",
)

// Contenido nuevo: combinar observacional + interventivo ACELERA, no solo evita sesgo.
#cap-teorema(
  titulo: "Bandits causales: por qué combinar datos ayuda, no solo evita sesgo",
  enunciado: "Bareinboim, Forney & Pearl muestran que combinar la distribución
    observacional P(y|x) con la interventiva P(y|do(x)) que el agente genera
    experimentando produce COTAS más estrechas sobre la recompensa de cada brazo que
    cualquiera de las dos fuentes por separado — y un agente que explota esas cotas
    converge más rápido que uno que ignora los datos históricos. La brecha entre lo
    observacional y lo interventivo es información explotable sobre la existencia de
    un confusor.",
)

#cap-caso-resolucion(
  titulo: "Por qué el curso se detiene en panorama",
  contexto: "RL causal es, en 2026, un programa de investigación activo — a
    diferencia de DML o meta-learners, que ya cuentan con implementaciones estándar y
    práctica de industria asentada.",
  resultado: "Regímenes de tratamiento dinámicos (Zhang & Bareinboim, 2019): una
    variable puede ser simultáneamente confusor de una decisión posterior y mediador
    de una anterior.",
  interpretacion: "Entender POR QUÉ la confusión importa en RL, sin pretender una
    cobertura de implementación que la madurez del campo no respalda todavía.",
)

#cap-mapeo-pch-activo(
  nivel: "L2 secuencial (champion-challenger); L2/L3 con confusión (bandits/RL)",
  metrica: "poblacion_comparable + pasa_tests_estadisticos; regret del bandit
    causal",
  pregunta-activa: "¿Por qué la pregunta \"¿puedo promover este challenger?\" es,
    formalmente, la misma pregunta de transportabilidad del Cap. 26?",
)

#cap-discusion-ejercicio(
  pregunta: "Describa un escenario donde ignorar la confusión en los datos
    históricos de un bandit lleve a subestimar sistemáticamente el valor de un
    brazo poco explorado.",
  ejercicio: "Implemente evaluar_challenger() sobre dos versiones del modelo del
    Notebook A2 (entrenadas sobre submuestras deliberadamente distintas). Verifique
    que el sistema marca correctamente la necesidad de revisión humana.",
)

#cap-cierre-narrativo(
  resumen: (
    [Champion-challenger preserva intercepción humana; un placebo solo no basta.],
    [La comparación de poblaciones (Cap. 7) es la segunda validación obligatoria
     antes de promover.],
    [Bandits causales: combinar datos observacionales e interventivos acelera la
     convergencia, no solo evita sesgo.],
  ),
  refs: (
    [Huyen (2022), Cap. 9, continual learning],
    [Bareinboim, Forney & Pearl (2015), bandits causales],
    [Zhang & Bareinboim (2019), regímenes de tratamiento dinámicos],
  ),
  transicion: "Cap. 32 — El lado humano de los sistemas causales",
  gancho: "El sistema ya sabe cuándo y cómo actualizarse. Falta el último paso, casi
    nunca técnico: comunicar el resultado a quien debe decidir con él.",
)
