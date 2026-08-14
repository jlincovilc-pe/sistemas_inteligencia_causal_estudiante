// =============================================================================
// Diapositivas · Capítulo 16 — Post-Double-Selection LASSO
// Fuente: 02_monografia/.../capitulos/cap08_pds.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 16"
// Sin sesión propia — ampliación opcional de S5. Variante A · ◇ profundización electiva
//
// Esqueleto REDUCIDO (◇): sin cap-progreso-curso. Usar para ampliar S5 si el cohorte
// es muy econométrico; si no, L05 + Cap. 6 bastan y este capítulo queda como lectura.
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 16, titulo: "Post-Double-Selection LASSO",
  parte: "III", sesion: "ampliación de S5", variant: "A", critico: false)

#cap-portada(num: 16, titulo: "Post-Double-Selection LASSO",
  parte: "III", sesion: "ampliación de S5", variant: "A", critico: false)

#cap-roadmap(
  objetivos: (
    [Aplicar PDS: doble selección LASSO + OLS final.],
    [Elegir entre λ por validación cruzada y λ teóricamente justificado — y por qué
     reportar ambos.],
    [Comparar PDS con DML y saber cuándo cada uno es preferible.],
  ),
  agenda: (
    [NHEFS: 51 covariables, ¿cuáles son confusoras?],
    [Post-Double-Selection: tres pasos],
    [Teorema (Belloni, Chernozhukov & Hansen, 2014)],
    [λ_CV vs. λ_BCH: la elección no es un detalle],
    [Caso: efecto de dejar de fumar sobre el peso],
  ),
  lectura: "Cap. 16 — Post-Double-Selection (@cap-pds) — profundización, no bloquea el
    camino ★",
  lab: "—", entrega: "—",
)

#cap-motivacion(
  problema: "NHEFS: 51 covariables tras excluir post-tratamiento. No todas son
    confusoras; algunas no afectan ni a D ni a Y, otras solo a Y. ¿Cómo seleccionar
    automáticamente las relevantes sin el sesgo post-selección del Cap. 6?",
  gancho: "Las confusoras son las variables que predicen TANTO al tratamiento COMO al
    resultado — seleccionar por separado y tomar la unión diluye el sesgo de selección
    individual.",
  caso: "Efecto de dejar de fumar sobre el cambio de peso (NHEFS).",
)

#cap-teorema(
  titulo: "Post-Double-Selection (Belloni, Chernozhukov & Hansen, 2014)",
  enunciado: "Bajo sparsity aproximada de γ0 y β0, restricted eigenvalue, y
    regularidad estándar: √n(θ̂_PDS − θ0) →^d N(0,V). La inferencia t-Student
    estándar es válida. Tres pasos: (1) LASSO de Y sobre X → S_Y; (2) LASSO de D
    sobre X → S_D; (3) OLS de Y sobre D y S_Y∪S_D.",
)

// Contenido nuevo, el más importante del capítulo: la eleccion de lambda no es un
// detalle de implementacion.
#cap-demostracion(pasos: (
  [$lambda_"CV"$ minimiza error de PREDICCIÓN — tiende a ser más pequeño que el
   teóricamente justificado, seleccionando de más.],
  [$lambda_"BCH" = (c dot sigma)/sqrt(n) dot Phi^(-1)(1-gamma/(2p))$ — calibrado para
   dominar el "ruido máximo" entre las $p$ variables candidatas (ajuste tipo
   Bonferroni).],
  [Recomendación operativa: reportar AMBAS estimaciones. Si coinciden, la elección era
   inmaterial; si difieren, la discrepancia es información sobre cuántos controles se
   admiten.],
))

#cap-caso-resolucion(
  titulo: "NHEFS: dejar de fumar y cambio de peso",
  contexto: "n=1566, 51 controles potenciales.",
  resultado: "OLS sin controles 2.54 kg; manual (5 controles) 3.20 kg; PDS 3.22 kg (18
    variables); DML-GBM 3.13 kg.",
  interpretacion: "Consistentes entre métodos con controles (3.13-3.22 kg) — valida la
    robustez del efecto pese a las distintas estrategias de selección.",
)

#cap-mapeo-pch-activo(
  nivel: "L2 (no confusión condicional, bajo esparsidad y linealidad)",
  metrica: "θ̂_PDS con IC t-Student",
  pregunta-activa: "PDS no usa cross-fitting como DML — ¿por qué la teoría de BCH no
    lo necesita, y qué le cuesta esa decisión cuando la linealidad falla?",
)

#cap-discusion-ejercicio(
  pregunta: "¿Cuándo preferir PDS sobre DML, y viceversa?",
  ejercicio: "Implemente la penalización teórica de BCH y compare, sobre nhefs, el
    λ_BCH resultante con el λ_CV. ¿Cambia el efecto estimado o solo el tamaño del
    conjunto seleccionado?",
)

#cap-cierre-narrativo(
  resumen: (
    [PDS selecciona confusoras dos veces (Y y D) y toma la unión — diluye el sesgo de
     selección individual del Cap. 6.],
    [λ por CV y λ teórico (BCH) responden preguntas distintas; reportar ambos.],
    [PDS falla bajo confusión densa; ahí DML (Cap. 11) es preferible.],
  ),
  refs: (
    [Belloni, Chernozhukov & Hansen (2014), Post-Double-Selection],
  ),
  transicion: "Cap. 17 — Machine learning causal en datos de panel",
  gancho: "PDS resuelve alta dimensión bajo linealidad y esparsidad; cuando los datos
    son un panel o hay endogeneidad, se necesita otra estructura.",
)
