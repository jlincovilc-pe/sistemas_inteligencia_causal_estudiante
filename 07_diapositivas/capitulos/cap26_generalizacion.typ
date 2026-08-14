// =============================================================================
// Diapositivas · Capítulo 26 — Generalización y transportabilidad entre
// dominios
// Fuente: 02_monografia/.../capitulos/cap12d_generalizacion.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 26"
// Sesión S24 · Lab L24 · sin entrega · Variante A · ★ camino crítico
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 26, titulo: "Generalización y transportabilidad entre dominios",
  parte: "VI", sesion: "S24", variant: "A", critico: true)

#cap-progreso-curso(cap-actual: 26)
#cap-portada(num: 26, titulo: "Generalización y transportabilidad entre dominios",
  parte: "VI", sesion: "S24", variant: "A", critico: true)

#cap-roadmap(
  objetivos: (
    [Construir un diagrama de selección.],
    [Distinguir transportabilidad de generalización (selección muestral).],
    [Aplicar la fórmula de transporte por reponderación y verificar su condición de
     soporte.],
  ),
  agenda: (
    [Toda model card dice "no usar fuera de esta población" — ¿qué significa eso?],
    [Diagramas de selección],
    [Transportabilidad vs. generalización — dos preguntas distintas],
    [Reponderación: el teorema de generalización de Pearl-Bareinboim],
    [Intervenciones suaves: transportar una política, no un efecto puntual],
  ),
  lectura: "Cap. 26 — Generalización (@cap-generalizacion-transportabilidad)",
  lab: "L24", entrega: "—",
)

#cap-motivacion(
  problema: "Toda model card causal (Cap. 19) incluye \"población de entrenamiento\"
    con advertencia de no usar fuera de ese dominio. ¿Qué significa exactamente
    \"fuera de ese dominio\", y bajo qué condiciones un efecto SÍ se puede aplicar a
    otra población?",
  gancho: "La \"validez externa\" informal de la econometría aplicada tiene una
    versión formal y verificable en el marco de la PCH.",
  caso: "Retorno a la educación de Card (1995): mecanismo estable vs. distribución de
    covariables distinta.",
)

#cap-definicion(
  titulo-def: "Diagrama de selección",
  cuerpo: "Grafo causal aumentado con nodos S (uno por mecanismo que se sospecha
    difiere entre el dominio fuente y el destino), con una flecha S_i -> V_i indicando
    que el mecanismo de V_i puede diferir entre dominios. Variables sin nodo S
    entrante comparten mecanismo en ambos dominios.",
)

// Contenido central: distinguir transportabilidad de generalizacion, y cual teorema
// justifica la reponderacion del listado del capitulo.
#cap-teorema(
  titulo: "Transportabilidad vs. generalización",
  enunciado: "Transportabilidad: un efecto estimado en un dominio Pi vale en un
    dominio Pi* DISTINTO (Bareinboim & Pearl, 2013, algoritmo completo). Generalización:
    caso donde el nodo S apunta a un indicador de SELECCIÓN MUESTRAL, no a un
    mecanismo del destino — teorema de generalización de Pearl & Bareinboim (2011),
    que es el que justifica la reponderación por estratos del listado del capítulo, NO
    el algoritmo general de transportabilidad.",
)

#cap-demostracion(pasos: (
  [La reponderación del listado es válida bajo un diagrama muy específico: S apunta
   SOLO a la covariable de estratificación, nunca a una ecuación estructural.],
  [Bajo esa condición: ATE-destino = suma sobre estratos de ATE-fuente(x) ponderado
   por la distribución de x en el destino.],
  [Condición de soporte: los estratos presentes en el destino deben estar
   representados en el origen — el análogo, entre dominios, del soporte común dentro
   de un dominio.],
))

#cap-interactivo(
  tipo: "Conceptual",
  pregunta: "¿Por qué \"reentrenar el modelo con datos del dominio destino\" no está
    disponible en la mayoría de los casos que motivan la teoría de
    transportabilidad?",
)

#cap-codigo-parte(
  titulo: "Transporte por reponderación",
  snippet: "def efecto_transportado_por_reponderacion(df_fuente, df_destino, covariable,\n"
    + "                                          tratamiento, resultado):\n"
    + "    \"\"\"Mecanismo Y=f(D,X) igual en ambos dominios; solo difiere P(X).\"\"\"\n"
    + "    efecto_por_estrato = df_fuente.groupby(covariable).apply(\n"
    + "        lambda g: g.loc[g[tratamiento] == 1, resultado].mean()\n"
    + "                  - g.loc[g[tratamiento] == 0, resultado].mean())\n"
    + "    peso_destino = df_destino[covariable].value_counts(normalize=True)\n"
    + "    # Condicion de soporte: estratos comunes antes de sumar\n"
    + "    comunes = efecto_por_estrato.index.intersection(peso_destino.index)\n"
    + "    return (efecto_por_estrato[comunes] * peso_destino[comunes]).sum()\n\n"
    + "# ATE* = sum_x ATE(x) * P*(x)  (Pearl & Bareinboim, 2011)",
  nota: "La condicion de soporte esta en `comunes`: si el destino tiene estratos que el
    origen no observo, no hay efecto condicional que reponderar y el resultado no es
    transportable por esta via — el analogo, entre dominios, del soporte comun.",
)

#cap-caso-resolucion(
  titulo: "Card (1995): ¿mecanismo estable o distribución distinta?",
  contexto: "Retorno a la educación estimado sobre hombres jóvenes en EE.UU. en los
    setenta.",
  resultado: "Aplicarlo a otro país o década exige preguntar: ¿el mecanismo
    (productividad, señalización, redes) es estable, o solo difiere la distribución
    de covariables?",
  interpretacion: "Si es lo primero, ninguna fórmula de transporte simple lo resuelve;
    si es lo segundo, la reponderación puede ser defendible.",
)

#cap-mapeo-pch-activo(
  nivel: "L2 (efecto transportado entre dominios)",
  metrica: "P*(y | do(x)) vía diagrama de selección",
  pregunta-activa: "¿Es lo mismo \"no hay evidencia de que el efecto difiera entre
    dominios\" que \"el efecto no difiere\"?",
)

#cap-errores-transiciones(
  errores: (
    ("crítico", [Asumir transportabilidad sin diagrama: aplicar un modelo entrenado
      en un contexto a otro sin justificación explícita es asumir un diagrama de
      selección vacío sin argumentarlo.]),
    ("advertencia", ["No hay evidencia de que difiera" no es evidencia de que no
      difiera — es ausencia de análisis.]),
    ("advertencia", [Sobreextender la fórmula de transporte a mecanismos no
      anticipados en el diagrama.]),
  ),
  conexiones: "El Cap. 31 (aprendizaje continuo) retoma esta misma pregunta al decidir
    si promover un modelo reentrenado sobre una población reciente.",
)

#cap-discusion-ejercicio(
  pregunta: "Para el ejemplo urbano-a-rural, dibuje el diagrama de selección y
    explique qué habría que medir en el dominio rural para aplicar la fórmula de
    transporte.",
  ejercicio: "Simule dos dominios con la misma ecuación estructural pero distinta
    distribución de X. Use la reponderación para transportar el efecto y compare
    contra el efecto verdadero simulado en el destino.",
)

#cap-cierre-narrativo(
  resumen: (
    [Un diagrama de selección declara qué mecanismos difieren entre dominios.],
    [Transportabilidad (dominios distintos) y generalización (selección muestral)
     son preguntas formalmente distintas.],
    [La reponderación por estratos es el caso más simple; el algoritmo general cubre
     casos donde el mecanismo mismo difiere.],
  ),
  refs: (
    [Pearl & Bareinboim (2011), teorema de generalización],
    [Bareinboim & Pearl (2013), algoritmo de transportabilidad],
    [Correa & Bareinboim (2020), intervenciones suaves],
  ),
  transicion: "Cap. 27 — Deep learning para inferencia causal (◇, electivo; en el
    libro abre la Parte VII)",
  gancho: "Hasta aquí, el curso cubrió estimación, decisión, equidad y generalización
    con los métodos \"estándar\". La Parte VII reúne dos familias más
    especializadas.",
)
