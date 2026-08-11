// =============================================================================
// Diapositivas · Capítulo 5 — Predicción y causalidad: por qué el ML no es
// causal por defecto
// Fuente: 02_monografia/.../capitulos/cap01_prediccion_causalidad.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 5"
// Sin sesión propia — lectura de refuerzo tras S1 (solapa con Cap. 1).
// Variante A · ◇ profundización electiva
//
// Esqueleto REDUCIDO (◇): sin cap-progreso-curso propio (se menciona como recuadro
// "◇" dentro del Cap. 1 que lo referencia). Usar en vivo solo si el cohorte necesita
// repaso econométrico antes de S5; si no, queda como lectura.
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 5, titulo: "Predicción y causalidad: por qué el ML no es causal por defecto",
  parte: "I", sesion: "refuerzo de S1", variant: "A", critico: false)

#cap-portada(num: 5, titulo: "Predicción y causalidad: por qué el ML no es causal por defecto",
  parte: "I", sesion: "refuerzo de S1", variant: "A", critico: false)

#cap-roadmap(
  objetivos: (
    [Diferenciar formalmente régimen predictivo vs. régimen causal.],
    [Reconocer cuándo una pregunta de política es genuinamente predictiva y no causal
     (Kleinberg et al., 2015).],
  ),
  agenda: (
    [Programa de transferencias: focalizar por riesgo vs. por efecto],
    [Tabla: predicción vs. causalidad],
    [Criterio de Kleinberg et al. para distinguir ambas],
    [Caso: Card (1995), OLS vs. bosque aleatorio],
  ),
  lectura: "Cap. 5 — Predicción y causalidad (@cap-prediccion-causalidad) — lectura de
    refuerzo, no bloquea el camino ★",
  lab: "—", entrega: "—",
)

#cap-motivacion(
  problema: "¿A qué hogares beneficiar con presupuesto limitado (30% de la población)?
    La pregunta relevante es causal: ¿quién experimentaría el mayor incremento de
    ingresos? La pregunta predictiva —quién tendrá mayores ingresos futuros,
    independientemente del programa— es distinta y, para focalización, equivocada.",
  gancho: "Un bosque aleatorio que predice el ingreso futuro con alta precisión puede
    ofrecer estimaciones sesgadas del efecto del programa.",
  caso: "Card (1995): OLS con controles da 0.07; el bosque aleatorio, al no distinguir
    el rol causal de educ, da un \"efecto predictivo\" de 0.04.",
)

#cap-definicion(
  titulo-def: "Régimen predictivo vs. régimen causal",
  cuerpo: "Objetivo: minimizar error fuera de muestra (predicción) vs. estimar τ(x) con
    IC válido (causalidad). Estimando: E[Y|X] vs. E[Y(1)-Y(0)|X]. Regularización:
    bienvenida en predicción, peligrosa en causalidad (sesga τ).
    // TODO(sprint): tabla completa @tab-pred-causal, líneas 41-61 del capítulo fuente.",
)

// TODO(sprint): contenido central del capítulo — el criterio de Kleinberg et al.
// (2015): \"si la decisión cambia la variable sobre la que se razona, la pregunta es
// causal; si la decisión solo depende de un estado del mundo que ocurriría de todos
// modos, la pregunta es predictiva\". Ejemplo: operar una cadera a un paciente
// terminal (predictivo) vs. focalizar un subsidio por quién se beneficia (causal).
#cap-teorema(
  titulo: "Criterio de Kleinberg, Ludwig, Mullainathan & Obermeyer (2015)",
  enunciado: "Si la decisión cambia la variable sobre la que se razona, la pregunta es
    causal; si la decisión solo depende de un estado del mundo que ocurriría de todos
    modos, la pregunta es predictiva. Focalizar por \"quién se beneficiaría más\" es
    causal; focalizar por \"quién es más pobre\" es predictivo.",
)

#cap-mapeo-pch-activo(
  nivel: "L1 (predicción) vs. L2 (intervención) — el eje completo del capítulo",
  metrica: "E[Y|X] vs. τ(x) = E[Y(1)-Y(0)|X]",
  pregunta-activa: "Para el sistema de targeting que está diseñando: ¿la decisión
    cambia la variable, o solo depende de un estado que ocurriría de todos modos?",
)

#cap-cierre-narrativo(
  resumen: (
    [Régimen predictivo y régimen causal responden preguntas distintas con el mismo
     tipo de dato.],
    [No toda decisión de política es causal: el criterio de Kleinberg et al. separa
     los dos casos.],
    [Card (1995): la divergencia OLS/bosque no es un defecto del bosque, es una
     pregunta distinta.],
  ),
  refs: (
    [Kleinberg, Ludwig, Mullainathan & Obermeyer (2015), "Prediction Policy Problems"],
    [Athey (2017), "Beyond Prediction"],
  ),
  transicion: "Vuelve al camino ★: Cap. 6 — Regularización y post-selección (S5)",
  gancho: "Vale para régimen causal en baja dimensión; con 80+ covariables candidatas,
    ¿cómo seleccionar sin sesgar la inferencia?",
)
