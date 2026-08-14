// =============================================================================
// Diapositivas · Capítulo 2 — Anatomía de un sistema de ML en producción
// Fuente: 02_monografia/.../capitulos/cap00b_anatomia_sistema.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 2"
// Sesión S2 · Lab L02 · Entrega: Lab 0 · Variante B · ★ camino crítico
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 2, titulo: "Anatomía de un sistema de ML en producción",
  parte: "0", sesion: "S2", variant: "B", critico: true)

#cap-progreso-curso(cap-actual: 2)
#cap-portada(num: 2, titulo: "Anatomía de un sistema de ML en producción",
  parte: "0", sesion: "S2", variant: "B", critico: true)

#cap-roadmap(
  objetivos: (
    [Enumerar los componentes de un sistema de ML más allá del algoritmo (Huyen, 2022).],
    [Explicar por qué reentrenar es más delicado en un sistema causal que en uno
     predictivo.],
    [Dejar el esqueleto de repositorio del curso funcionando localmente (Lab 0).],
  ),
  agenda: (
    [El problema de diseño: modelo entrenado ≠ sistema en producción],
    [Model-centric vs. system-centric; proceso lineal vs. iterativo],
    [Decisión: los 4 requisitos DMLS en versión causal],
    [Esqueleto de repositorio del curso],
    [Qué cambia cuando el "modelo" estima un efecto],
  ),
  lectura: "Cap. 2 — Anatomía del sistema (@cap-anatomia-sistema)",
  lab: "L02", entrega: "Lab 0",
)

#cap-problema-diseno(
  decision: "Tratar el modelo como un componente de un sistema, no como el sistema
    entero.",
  alternativas: "Enfoque centrado en el modelo (model-centric) vs. enfoque centrado en
    el sistema (system-centric, DMLS).",
  tradeoff: "Velocidad de iteración académica vs. confiabilidad operativa.",
  stack: "Python, Git, Docker, cuenta en Hugging Face Hub (Lab 0).",
  riesgo: "Confundir \"el modelo entrena bien\" con \"el sistema está listo para
    producción\".",
)

#cap-opciones-tradeoffs(opciones: (
  ([Model-centric], [Mejorar especificación/algoritmo con datos y entorno fijos. Rápido
    de iterar; ignora todo lo anterior y posterior al modelo entrenado.]),
  ([System-centric (DMLS)], [Repartir el foco entre datos, modelo e infraestructura.
    Requiere invertir en formato, feature stores, logging, tests — el único enfoque que
    sobrevive datos y usuarios reales que cambian con el tiempo.]),
  ([Proceso lineal vs. iterativo], [Waterfall asume que el mundo no cambia tras el
    despliegue; DMLS asume que sí y construye monitoreo para detectarlo.]),
))

#cap-decision-referencia(
  decision: "Enfoque centrado en el sistema + proceso iterativo DMLS, con 4 requisitos
    reinterpretados en versión causal: confiabilidad del efecto, escalabilidad del
    pipeline, mantenibilidad de la identificación, adaptabilidad ante drift de
    supuestos.",
  justificacion: "Un sistema causal necesita, además de lo que exige DMLS a cualquier
    sistema, que el efecto siga siendo válido bajo los supuestos declarados — no solo
    que el servicio esté \"arriba\".",
)

// Código = árbol de directorios del esqueleto de repo (líneas 72-86 del capítulo
// fuente). No es Python ejecutable: se muestra como texto preformateado.
#cap-codigo-parte(
  titulo: "El esqueleto de repositorio del curso",
  snippet: "proyecto-causal/\n"
    + "├── data/                 # datos crudos y procesados (no versionados en git salvo muestras pequeñas)\n"
    + "├── notebooks/\n"
    + "│   ├── serie_a_caso_estudio/     # A1–A4: identificación y estimación\n"
    + "│   └── serie_b_produccion/       # B1–B4: despliegue en Hugging Face\n"
    + "├── src/\n"
    + "│   ├── identification/   # DAGs, diagnósticos de no confusión y soporte común\n"
    + "│   ├── estimation/       # DML, meta-learners, bosques causales\n"
    + "│   └── service/          # función de inferencia, app FastAPI\n"
    + "├── tests/                # pruebas de humo y de sanidad estadística\n"
    + "├── .github/workflows/    # CI/CD (se detalla en el Capítulo 20)\n"
    + "├── Dockerfile\n"
    + "└── model_card.md         # plantilla del Apéndice G",
  nota: "Lab 0: dejar este esqueleto funcionando localmente, con Docker verificado
    (docker run hello-world).",
)

#cap-caso-resolucion(
  titulo: "Qué cambia cuando el modelo estima un efecto",
  contexto: "Un sistema predictivo puede mostrar una predicción puntual sin más. Un
    sistema causal responsable debe comunicar el intervalo de confianza y, cuando sea
    posible, la población para la cual el efecto fue estimado.",
  resultado: "Tres cambios: (1) el artefacto servido incluye los supuestos de
    identificación, no solo los coeficientes; (2) la interfaz comunica algo más que un
    número; (3) reentrenar puede cambiar silenciosamente la población representada.",
  interpretacion: "Ninguno de los tres tiene análogo obligatorio en un sistema
    puramente predictivo — son específicos de que el objetivo sea un efecto causal.",
)

#cap-mapeo-pch-activo(
  nivel: "Transversal (infraestructura para operar cualquier nivel de la PCH)",
  metrica: "Los 4 requisitos DMLS-causal: confiabilidad / escalabilidad /
    mantenibilidad / adaptabilidad",
  pregunta-activa: "Si el estimador es impecable pero nadie puede auditar sus supuestos
    en producción, ¿está realmente listo?",
)

#cap-checklist-alertas(items: (
  [El notebook de estimación no tiene ninguna versión de datos ni código asociados.],
  [La función de features en entrenamiento y en producción no son literalmente la misma
   (riesgo de training-serving skew).],
  [No existe ningún documento que declare los supuestos de identificación asumidos.],
  [No hay mecanismo, ni manual, para detectar si las covariables de producción se
   parecen a las de entrenamiento.],
))

#cap-interactivo(
  tipo: "Aplicado",
  pregunta: "De los cuatro requisitos (confiabilidad, escalabilidad, mantenibilidad,
    adaptabilidad), ¿cuál es más fácil de descuidar en un proyecto real? Justifique.",
)

#cap-discusion-ejercicio(
  pregunta: "¿Por qué \"reentrenar con datos nuevos\" es una decisión más delicada en
    un sistema causal que en uno puramente predictivo?",
  ejercicio: "Complete el Lab 0: esqueleto de repositorio, Git inicializado, cuenta en
    Hugging Face Hub, Docker instalado y verificado. Entregue una captura de
    \"docker run hello-world\" corriendo exitosamente.",
)

#cap-cierre-narrativo(
  resumen: (
    [Un sistema de ML tiene componentes más allá del algoritmo: interfaz, datos,
     backend, infraestructura de despliegue/monitoreo (Huyen, 2022).],
    [Un sistema causal añade: supuestos de identificación viajando con el artefacto,
     comunicación de incertidumbre, y cautela al reentrenar.],
    [El esqueleto de repositorio del curso se usa sin cambios en las Series A y B.],
  ),
  refs: (
    [Huyen (2022), *Designing Machine Learning Systems*, Caps. 1-2],
    [Sculley et al. (2015), "Hidden Technical Debt in Machine Learning Systems"],
    [Breck et al. (2017), "The ML Test Score"],
  ),
  transicion: "Cap. 3 — SCM y Jerarquía Causal de Pearl",
  gancho: "Con el sistema listo, falta el lenguaje formal para razonar sobre el efecto
    que ese sistema va a operar.",
)
