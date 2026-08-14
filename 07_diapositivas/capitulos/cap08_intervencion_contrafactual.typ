// =============================================================================
// Diapositivas · Capítulo 8 — Razonamiento intervencional y contrafactual
// Fuente: 02_monografia/.../capitulos/cap02c_intervencion_contrafactual.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 8"
// Sesión S7 · Lab L07 · sin entrega · Variante A · ★ camino crítico
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 8, titulo: "Razonamiento intervencional y contrafactual",
  parte: "I", sesion: "S7", variant: "A", critico: true)

#cap-progreso-curso(cap-actual: 8)
#cap-portada(num: 8, titulo: "Razonamiento intervencional y contrafactual",
  parte: "I", sesion: "S7", variant: "A", critico: true)

#cap-roadmap(
  objetivos: (
    [Aplicar el criterio de puerta trasera para validar un conjunto de control.],
    [Enunciar las tres reglas del cálculo-do y explicar su completitud.],
    [Ejecutar abducción-acción-predicción sobre un ejemplo numérico.],
  ),
  agenda: (
    [Qué controles incluir para recuperar P(y\|do(x))],
    [Criterio de puerta trasera + buenos/malos controles],
    [Las tres reglas del cálculo-do y su completitud],
    [Puerta delantera: cuando la puerta trasera falla],
    [Abducción-acción-predicción],
  ),
  lectura: "Cap. 8 — Intervención y contrafactual (@cap-intervencion-contrafactual)",
  lab: "L07", entrega: "—",
)

#cap-motivacion(
  problema: "Dado un grafo causal y variables observadas, ¿cómo se determina qué
    controles incluir para que un ajuste recupere P(y\|do(x)) y no P(y\|x)? \"Controlar
    por todo lo que se pueda medir\" es no solo insuficiente sino activamente
    peligroso.",
  gancho: "Hay variables que, controladas, introducen sesgo donde no lo había.",
  caso: "Card (1995): test_score medido después de educ como control candidato.",
)

#cap-definicion(
  titulo-def: "Criterio de puerta trasera",
  cuerpo: "Z satisface el criterio de puerta trasera relativo a (X,Y) si: (i) ningún
    nodo de Z es descendiente de X, y (ii) Z bloquea todo camino entre X e Y que
    contenga una flecha hacia X.",
  eq: $P(y | "do"(x)) = sum_z P(y|x,z) thin P(z)$,
)

#cap-supuestos(supuestos: (
  ([Confusor], [Necesario para puerta trasera], [Causa común de X e Y]),
  ([Mediador], [NO controlar — bloquea parte del efecto], [Ruta X→M→Y]),
  ([Collider], [NO controlar — crea asociación espuria], [Afectado por X e Y]),
  ([Post-tratamiento], [NO controlar por defecto], [Riesgo de ser mediador/collider]),
))

#cap-teorema(
  titulo: "Las tres reglas del cálculo-do (Pearl)",
  enunciado: "Regla 1 (inserción/eliminación de observaciones), Regla 2 (intercambio de
    acción por observación — convierte do() en condicionamiento ordinario), Regla 3
    (inserción/eliminación de acciones). Son válidas y COMPLETAS: si un efecto es
    identificable, existe una secuencia finita de las 3 reglas que produce su fórmula;
    si no existe tal secuencia, el efecto no es identificable con ese grafo, por
    ningún método.",
)

#cap-demostracion(pasos: (
  [Regla 2 justifica reemplazar P(y\|do(x),z) por P(y\|x,z): condicionar en Z bloquea
   las rutas de puerta trasera.],
  [Regla 3 justifica que P(z\|do(x)) = P(z): ningún nodo de Z es descendiente de X.],
  [Sumando sobre z se recupera la fórmula de ajuste de puerta trasera como corolario de
   las 3 reglas — no como resultado independiente.],
))

#cap-interactivo(
  tipo: "Conceptual",
  pregunta: "Puerta delantera: X→M→Y con confusor no observado U afectando a X e Y.
    ¿Por qué M ofrece una vía de identificación que ningún ajuste por covariables
    observadas puede dar?",
)

#cap-codigo-parte(
  titulo: "Verificación del criterio de puerta trasera",
  snippet: "import networkx as nx\n"
    + "\n"
    + "# ability (confusor) -> educ, wage; educ -> wage;\n"
    + "# test_score (mediador): educ -> test_score -> wage\n"
    + "G = nx.DiGraph([(\"ability\", \"educ\"), (\"ability\", \"wage\"),\n"
    + "                (\"educ\", \"wage\"), (\"educ\", \"test_score\"),\n"
    + "                (\"test_score\", \"wage\")])\n"
    + "\n"
    + "def satisface_puerta_trasera(G, X, Y, Z):\n"
    + "    G_sin_salientes_X = G.copy()\n"
    + "    G_sin_salientes_X.remove_edges_from(list(G.out_edges(X)))\n"
    + "    # (i) ningun nodo de Z es descendiente de X\n"
    + "    if any(z in nx.descendants(G, X) for z in Z):\n"
    + "        return False, \"Z contiene un descendiente de X (mediador)\"\n"
    + "    # (ii) Z d-separa X de Y en el grafo sin aristas salientes de X\n"
    + "    bloqueado = not nx.has_path(G_sin_salientes_X.to_undirected(), X, Y) or \\\n"
    + "                nx.is_d_separator(G_sin_salientes_X, {X}, {Y}, set(Z))\n"
    + "    if not bloqueado:\n"
    + "        return False, \"Z no bloquea todos los caminos de puerta trasera\"\n"
    + "    return True, \"Z satisface el criterio de puerta trasera\"\n"
    + "\n"
    + "print(satisface_puerta_trasera(G, \"educ\", \"wage\", {\"ability\"}))\n"
    + "print(satisface_puerta_trasera(G, \"educ\", \"wage\", {\"ability\", \"test_score\"}))\n"
    + "# El segundo caso debe fallar: test_score es un mediador (descendiente de X)",
)

#cap-caso-resolucion(
  titulo: "test_score como mediador parcial",
  contexto: "Incluir test_score (tomado después de completar los años de educación)
    como control en la regresión de wage sobre educ.",
  resultado: "{ability, test_score} FALLA el criterio de puerta trasera; {ability} solo
    lo satisface — verificado con el listado de networkx.",
  interpretacion: "Sesga el coeficiente de educ hacia abajo: parte del efecto de la
    educación sobre el salario opera precisamente vía las habilidades que la prueba
    mide.",
)

#cap-mapeo-pch-activo(
  nivel: "L2 (intervención) — con puente a L3 (contrafactual)",
  metrica: "P(y | do(x)) vía fórmula de ajuste; P(y_x | e) vía abducción-acción-predicción",
  pregunta-activa: "Si dowhy responde \"no identificable\" para un grafo dado, ¿qué
    significa esa respuesta — una limitación del software o una afirmación
    matemática?",
)

#cap-errores-transiciones(
  errores: (
    ("crítico", ["Más controles siempre es más seguro" es falso: un mediador o
      collider puede introducir sesgo donde una especificación más parca no lo
      tenía.]),
    ("advertencia", [Confundir un instrumento con un confusor: no debe controlarse
      directamente como covariable de puerta trasera.]),
    ("advertencia", [El grafo es siempre una hipótesis — ningún algoritmo lo genera
      desde los datos solos sin supuestos adicionales.]),
  ),
  conexiones: "El Cap. 9 aplica esta misma clasificación de controles como auditoría
    obligatoria en el pipeline de features real.",
)

#cap-discusion-ejercicio(
  pregunta: "Explique por qué condicionar en un collider crea una correlación
    espuria, retomando el ejemplo del tamaño del pie y la lectura (Cap. 1) con un
    collider explícito.",
  ejercicio: "Instale dowhy y reproduzca la verificación del listado usando
    identify_effect() en vez de la función manual. Compare el conjunto de ajuste
    identificado automáticamente con el usado en el capítulo.",
)

#cap-cierre-narrativo(
  resumen: (
    [El criterio de puerta trasera formaliza qué controlar; la clasificación de
     controles (confusor/mediador/collider/instrumento) organiza el error más
     frecuente en la práctica aplicada.],
    [Las tres reglas del cálculo-do son válidas y completas — no hay un método
     alternativo que identifique más de lo que ellas permiten.],
    [Puerta delantera identifica vía un mediador cuando la puerta trasera no tiene
     ningún conjunto de ajuste válido.],
  ),
  refs: (
    [Pearl (2009), *Causality*, Cap. 3],
    [Bareinboim (2025), clasificación de buenos y malos controles],
    [Elwert & Winship (2014), sesgo por collider],
  ),
  transicion: "Cap. 9 — Ingeniería de features sin fuga causal",
  gancho: "Puerta trasera dice qué controlar en el grafo; falta la versión operacional
    en el pipeline de features real, donde el grafo no viene etiquetado.",
)
