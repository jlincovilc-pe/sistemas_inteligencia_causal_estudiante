// =============================================================================
// Diapositivas · Capítulo 6 — Regularización, selección de variables y sesgo
// post-selección
// Fuente: 02_monografia/.../capitulos/cap02_regularizacion_postseleccion.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 6"
// Sesión S5 (+ Cap. 16 ◇ como ampliación) · Lab L05 · Entrega: A1 · Variante A · ★
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 6, titulo: "Regularización, selección de variables y sesgo post-selección",
  parte: "I", sesion: "S5", variant: "A", critico: true)

#cap-progreso-curso(cap-actual: 6)
#cap-portada(num: 6, titulo: "Regularización, selección de variables y sesgo post-selección",
  parte: "I", sesion: "S5", variant: "A", critico: true)

#cap-roadmap(
  objetivos: (
    [Enunciar LASSO/Ridge/Elastic Net y qué garantiza cada uno.],
    [Distinguir la tasa ℓ2 (restricted eigenvalue) de la consistencia de *selección*
     (irrepresentabilidad) — y por qué la segunda casi nunca se verifica.],
    [Explicar por qué Post-Double-Selection no necesita que LASSO acierte el soporte
     exacto.],
  ),
  agenda: (
    [80 covariables, n=1000: ¿incluir todas?],
    [LASSO / Ridge / Elastic Net],
    [Tasa ℓ2 vs. consistencia de selección],
    [El problema de Leeb & Pötscher],
    [De la selección ingenua a Post-Double-Selection],
  ),
  lectura: "Cap. 6 — Regularización (@cap-regularizacion) (+ Cap. 16 PDS avanzado ◇)",
  lab: "L05", entrega: "A1",
)

#cap-motivacion(
  problema: "80 variables de control potenciales, n=1000. No se sabe cuáles son
    confusoras y cuáles irrelevantes. Incluir todas da alta varianza; seleccionar con
    LASSO y correr OLS con las seleccionadas es metodológicamente peligroso.",
  gancho: "La selección de variables induce sesgo en la inferencia posterior — el
    problema fue formalizado por Leeb & Pötscher.",
  caso: "Programa de capacitación laboral, efecto sobre salario, 80 controles
    candidatos.",
)

#cap-glosario(terminos: (
  ([Sparsity aproximada], [El vector verdadero β0 tiene a lo más s ≪ n componentes no
    nulas, s·log(p) = o(n).]),
  ([Restricted eigenvalue], [Condición débil sobre la matriz de diseño; da la tasa ℓ2,
    no la selección del soporte.]),
  ([Irrepresentabilidad], [Condición fuerte, no verificable en la práctica; necesaria y
    esencialmente suficiente para recuperar el soporte exacto.]),
))

#cap-definicion(
  titulo-def: "LASSO",
  cuerpo: "β̂_LASSO = argmin_β { (1/2n)‖Y−Xβ‖² + λ‖β‖1 }. Produce selección de variables
    (algunos β̂_j = 0 exactamente); Ridge solo contrae, no selecciona.",
  eq: $hat(beta)_"LASSO" = "argmin"_beta { (1/(2n)) norm(Y - X beta)_2^2 + lambda norm(beta)_1 }$,
)

// Los dos teoremas del capítulo — la corrección más importante de la mejora de
// contenido: NO son el mismo resultado, y confundirlos es el error central del
// capítulo original.
#cap-supuestos(supuestos: (
  ([Restricted eigenvalue], [Solo da la tasa ‖β̂−β0‖ℓ2 = O(√(s·log p/n))],
   [Débil: se comporta bien en un cono alrededor del soporte]),
  ([Irrepresentabilidad], [Necesaria y esenc. suficiente para sign(β̂)=sign(β0)],
   [No verificable: depende de S0, lo desconocido]),
))

#cap-teorema(
  titulo: "Irrepresentabilidad y su recíproca (Zhao & Yu, 2006)",
  enunciado: "Bajo irrepresentabilidad, el LASSO es sign-consistent. Recíprocamente, si
    la condición se viola en la dirección opuesta, el LASSO NO recupera el soporte
    verdadero con probabilidad tendiente a uno, para NINGÚN valor de λ. Por eso ningún
    procedimiento causal debería depender de que la selección sea exactamente
    correcta.",
)

#cap-demostracion(pasos: (
  [Escribir la matriz de correlación entre variables activas (S0) e inactivas (S0^c).],
  [Irrepresentabilidad: la correlación de las inactivas con el signo de las activas
   está acotada por 1−η.],
  [Sin esa cota, existe un diseño donde una variable irrelevante domina y ningún λ la
   excluye de forma consistente — de ahí la recíproca.],
))

#cap-interactivo(
  tipo: "Conceptual",
  pregunta: "¿Por qué el LASSO puede tener buena tasa ℓ2 y aun así seleccionar mal el
    conjunto de variables?",
)

#cap-codigo-parte(
  titulo: "Sesgo post-selección — Monte Carlo",
  snippet: "# TODO(sprint): pegar el listado @lst-post-selection-bias (línea 167 del
# capítulo fuente): generate_data(), post_selection_ate(), Monte Carlo de 1000 réplicas.",
  invariante: "# assert 0.85 <= cobertura_ic_post_seleccion.mean() <= 0.90  # ≠ 0.95 nominal",
  salida: "Sesgo post-selección: -0.05 a -0.10\nCobertura real IC: 0.85-0.90",
)

#cap-caso-resolucion(
  titulo: "Réplica propia: close_college y nhefs",
  contexto: "close_college (Card, 1995), n=3003. nhefs, n=1566, 51 covariables tras
    excluir post-tratamiento.",
  resultado: "close_college: OLS 0.071, IV 2SLS 0.124, DML-PLIV 0.145 (estimandos
    distintos, ver Cap. 11). nhefs: manual 3.20 kg, PDS 3.22 kg (18 variables
    seleccionadas, capturando confusoras adicionales).",
  interpretacion: "PDS no necesita acertar el soporte exacto — solo capturar
    confusoras con la unión de dos selecciones (Cap. 16).",
)

#cap-mapeo-pch-activo(
  nivel: "L2 (bajo no confusión condicional en covariables observadas)",
  metrica: "θ0 con IC válido tras selección",
  pregunta-activa: "Si reportáramos el IC del LASSO sin corregir por selección, ¿qué
    decisión de política estaríamos respaldando con falsa confianza?",
)

#cap-errores-transiciones(
  errores: (
    ("crítico", [Interpretar el conjunto seleccionado por LASSO como "las variables
      que verdaderamente importan".]),
    ("advertencia", [Reportar IC construidos después de selección LASSO sin
      corrección.]),
  ),
  conexiones: "La solución no es un LASSO mejor, es un procedimiento cuya validez no
    dependa de la selección: Post-Double-Selection (Cap. 16) y DML (Cap. 11).",
)

#cap-discusion-ejercicio(
  pregunta: "¿Por qué en un problema causal no interesa hacer inferencia sobre \"las
    variables que el LASSO seleccionó\" sino sobre un parámetro fijado antes de mirar
    los datos?",
  ejercicio: "Replique el Monte Carlo variando p ∈ {20, 50, 100, 200}. ¿Cómo cambian el
    sesgo y la cobertura con la dimensionalidad?",
)

#cap-cierre-narrativo(
  resumen: (
    [LASSO selecciona, Ridge contrae; ninguno da IC válidos sin corrección posterior.],
    [Restricted eigenvalue (tasa) e irrepresentabilidad (selección) son garantías
     distintas — la segunda, mucho más fuerte y no verificable.],
    [La respuesta no es "arreglar" LASSO sino diseñar procedimientos cuya validez no
     dependa de que acierte: PDS y DML.],
  ),
  refs: (
    [Tibshirani (1996), LASSO],
    [Zhao & Yu (2006), irrepresentabilidad y su recíproca],
    [Leeb & Pötscher (2006), inferencia post-selección],
  ),
  transicion: "Cap. 7 — Datos de entrenamiento en sistemas causales",
  gancho: "Seleccionar controles no basta si no sabemos si los datos con los que se
    seleccionó fueron, siquiera, comparables entre tratados y controles.",
)
