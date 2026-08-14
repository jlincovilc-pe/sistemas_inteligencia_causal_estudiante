// =============================================================================
// Diapositivas · Capítulo 29 — Descubrimiento causal y grafos
// Fuente: 02_monografia/.../capitulos/cap15_descubrimiento_grafos.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 29"
// Sesión S26 · Lab L26 · Entrega: B3 cierre · Variante A · ★ camino crítico
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 29, titulo: "Descubrimiento causal y grafos",
  parte: "VIII", sesion: "S26", variant: "A", critico: true)

#cap-progreso-curso(cap-actual: 29)
#cap-portada(num: 29, titulo: "Descubrimiento causal y grafos",
  parte: "VIII", sesion: "S26", variant: "A", critico: true)

#cap-roadmap(
  objetivos: (
    [Ejecutar PC y NOTEARS y leer una CPDAG correctamente.],
    [Explicar la sensibilidad a hiperparámetros y por qué invalida comparaciones
     ingenuas entre algoritmos.],
    [Situar el descubrimiento como exploración, no reemplazo del razonamiento causal
     sustantivo.],
  ),
  agenda: (
    [Determinantes de la pobreza infantil: ¿qué es causa y qué consecuencia?],
    [PC: esqueleto + orientación de colisionadores],
    [NOTEARS: optimización continua con restricción de aciclicidad],
    [CPDAG = misma clase de equivalencia del Cap. 3, vista desde la estructura],
    [Sensibilidad a hiperparámetros (Machlanski et al., 2024)],
  ),
  lectura: "Cap. 29 — Descubrimiento de grafos (@cap-descubrimiento-grafos)",
  lab: "L26", entrega: "B3 cierre",
)

#cap-motivacion(
  problema: "30 variables sobre pobreza infantil. A diferencia de todo el curso
    hasta aquí, donde el grafo se asume conocido, ahora el grafo mismo es el objeto
    de estimación.",
  gancho: "El supuesto de causal sufficiency (sin confusores no observados) es fuerte
    y raramente plausible en economía — el descubrimiento es exploración, no
    reemplazo del razonamiento sustantivo.",
  caso: "DAG sintético con estructura conocida para validar PC/NOTEARS.",
)

#cap-definicion(
  titulo-def: "CPDAG",
  cuerpo: "Output del algoritmo PC: grafo parcialmente dirigido que representa la
    clase de equivalencia de Markov — DAGs que no pueden distinguirse
    observacionalmente. Mismo fenómeno del Teorema de la Jerarquía Causal (Cap. 3)
    visto desde la estructura: si dos grafos inducen las mismas independencias
    condicionales, ningún algoritmo que solo mire P(v) puede separarlos.",
)

#cap-supuestos(supuestos: (
  ([Faithfulness], [Toda independencia condicional corresponde a d-separación],
   [Requerido por métodos basados en restricciones]),
  ([Causal sufficiency], [Sin confusores no observados afectando 2+ variables],
   [Raramente plausible en datos económicos]),
))

// Contenido nuevo: tercera familia (score-based) y sensibilidad a hiperparametros.
#cap-teorema(
  titulo: "GES: tercera familia (basada en score) y sensibilidad a hiperparámetros",
  enunciado: "GES (Chickering, 2002) maximiza un criterio de ajuste penalizado (BIC)
    de forma voraz sobre el espacio de DAGs, y es CONSISTENTE pese a ser voraz — más
    robusta que PC en muestras pequeñas porque no arrastra errores en cascada de
    decisiones discretas irreversibles. Machlanski et al. (2024): el efecto de los
    hiperparámetros (alpha en PC, lambda en NOTEARS) puede ser COMPARABLE O MAYOR que
    las diferencias entre algoritmos — buena parte de las comparaciones publicadas no
    son replicables fuera de la configuración exacta del estudio.",
)

#cap-interactivo(
  tipo: "Conceptual",
  pregunta: "Si un benchmark publicado dice \"NOTEARS supera a PC\", ¿qué pregunta
    hay que hacer antes de aceptar esa conclusión?",
)

#cap-codigo-parte(
  titulo: "PC y NOTEARS con causal-learn",
  snippet: "from causallearn.search.ConstraintBased.PC import pc\n"
    + "from causallearn.search.FCMBased import notears\n\n"
    + "# Datos sinteticos con estructura conocida: X0->X1->X2, X3->X2\n"
    + "rng = np.random.default_rng(42)\n"
    + "n, d = 1000, 5\n"
    + "W_true = np.zeros((d, d))\n"
    + "W_true[0, 1] = 2.0; W_true[1, 2] = 1.5; W_true[3, 2] = 1.0\n"
    + "X = rng.standard_normal((n, d)) @ np.linalg.inv(np.eye(d) - W_true)\n\n"
    + "# PC: esqueleto + orientacion de colisionadores -> CPDAG\n"
    + "pc_graph = pc(X, alpha=0.05, indep_test=\"fisherz\")\n\n"
    + "# NOTEARS: optimizacion continua; normalizar ANTES (sensible a escala)\n"
    + "W_est = notears.linear(X, lambda1=0.05, loss_type=\"l2\")\n"
    + "print(\"W estimado (NOTEARS):\", np.round(W_est, 2))",
  nota: "Normalizar las variables ANTES de NOTEARS: el grafo optimo cambia con las
    unidades de medida. `indep_test` permite fisherz/kci/chisq; reportar sensibilidad
    con varios alpha/lambda (Machlanski et al., 2024).",
)

#cap-caso-resolucion(
  titulo: "DAG de Card (1995) con confusor no observado",
  contexto: "Panel izquierdo: DAG explícito con U (habilidad) afectando educ y wage.",
  resultado: "Panel derecho: NOTEARS recupera correctamente la estructura sobre datos
    sintéticos con estructura conocida.",
  interpretacion: "Sobre datos reales, el grafo estimado es una guía exploratoria, no
    evidencia definitiva — causal sufficiency raramente se satisface.",
)

#cap-mapeo-pch-activo(
  nivel: "Estructural (precede a L1→L2; determina qué conjuntos de ajuste existen)",
  metrica: "CPDAG, SHD, precisión/recall frente a grafo verdadero",
  pregunta-activa: "Dos algoritmos con SHD similar pero configuraciones de
    hiperparámetros distintas — ¿es una comparación válida?",
)

#cap-errores-transiciones(
  errores: (
    ("crítico", [Interpretar la CPDAG como DAG: algunas aristas no se pueden orientar
      observacionalmente — presentarlas como dirigidas induce falsa certeza.]),
    ("crítico", [Aplicar NOTEARS sin normalizar: cambia el grafo óptimo según las
      unidades de medida.]),
    ("advertencia", [Un solo umbral de significación: reportar siempre sensibilidad
      con múltiples valores de alpha/lambda.]),
  ),
  conexiones: "El output del descubrimiento NO debe alimentar directamente la
    estimación — es una hipótesis para discutir con conocimiento de dominio, no un
    supuesto de identificación validado.",
)

#cap-discusion-ejercicio(
  pregunta: "¿En qué casos económicos el supuesto de causal sufficiency es plausible?
    Dé tres ejemplos donde no lo es.",
  ejercicio: "Construya un DAG para nhefs justificando las relaciones. Identifique el
    set de control óptimo vía el criterio de puerta trasera del Cap. 8.",
)

#cap-cierre-narrativo(
  resumen: (
    [PC (restricciones), NOTEARS (optimización continua) y GES (score) son tres
     familias con supuestos y garantías distintas.],
    [La CPDAG es el límite estructural de lo identificable — mismo fenómeno del
     Cap. 3.],
    [La sensibilidad a hiperparámetros exige reportar la familia de grafos, no un
     grafo único.],
  ),
  refs: (
    [Spirtes, Glymour & Scheines (2000), algoritmo PC],
    [Zheng et al. (2018), NOTEARS],
    [Machlanski et al. (2024), sensibilidad a hiperparámetros],
  ),
  transicion: "Cap. 30 — Monitoreo de supuestos causales en producción",
  gancho: "Con o sin grafo descubierto, el sistema ya está en producción. La
    pregunta cambia de identificación puntual a identificación continua: ¿sigue
    siendo válida mañana?",
)
