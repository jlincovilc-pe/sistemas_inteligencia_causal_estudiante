// =============================================================================
// Diapositivas · Capítulo 28 — Control sintético y matrix completion
// Fuente: 02_monografia/.../capitulos/cap14_scm_matrix_completion.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 28"
// Sin sesión propia — electivo (evaluación de programas con paneles). Variante A · ◇
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 28, titulo: "Control sintético y matrix completion",
  parte: "VII", sesion: "electivo", variant: "A", critico: false)

#cap-portada(num: 28, titulo: "Control sintético y matrix completion",
  parte: "VII", sesion: "electivo", variant: "A", critico: false)

#cap-roadmap(
  objetivos: (
    [Distinguir SCM clásico de matrix completion y cuándo preferir cada uno.],
    [Elegir r/lambda por validación cruzada con enmascaramiento en bloque.],
    [Aplicar inferencia por permutación de placebos y su cota de p-valor.],
  ),
  agenda: (
    [Reforma tributaria regional, sin control perfecto],
    [SCM clásico: combinación convexa],
    [Matrix completion: norma nuclear como envolvente convexa del rango],
    [Elegir r/lambda: el hiperparámetro que fija el contrafactual],
    [Inferencia por permutación: p-valor mínimo 1/(J+1)],
  ),
  lectura: "Cap. 28 — SCM / matrix completion (@cap-scm-mc) — electivo",
  lab: "—", entrega: "—",
)

#cap-motivacion(
  problema: "Reforma tributaria en una región específica sobre recaudación. Sin
    región de control perfecta: todas tienen trayectorias distintas.",
  gancho: "SCM clásico requiere fit pre-tratamiento perfecto y no maneja múltiples
    unidades tratadas fácilmente; matrix completion lo hace con bajo rango.",
  caso: "Panel sintético N=20, T=30, T0=15, efecto verdadero 2.5.",
)

#cap-teorema(
  titulo: "Norma nuclear como envolvente convexa del rango",
  enunciado: "El problema con restricción de rango explícita es no convexo e
    intratable. Igual que la norma L1 es la envolvente convexa de L0 (induciendo
    esparsidad en LASSO), la norma nuclear es la envolvente convexa del rango sobre
    la bola espectral (Recht et al., 2010) — induce soluciones de rango bajo. Y, como
    LASSO, contrae los valores singulares hacia cero, sesgando L_hat.",
)

// Contenido central: la eleccion de r/lambda determina literalmente el contrafactual.
#cap-demostracion(pasos: (
  [Lambda muy alto (r efectivo bajo): modelo rígido, mal ajuste pre-tratamiento
   VISIBLE.],
  [Lambda muy bajo (r efectivo alto): ajusta el ruido pre-tratamiento; al extrapolar,
   el "efecto" puede ser en buena parte ese sobreajuste proyectado.],
  [Procedimiento recomendado: validación cruzada con enmascaramiento EN BLOQUE
   (últimos periodos pre-tratamiento de los controles) — no celdas dispersas al
   azar, porque el problema real es extrapolación temporal.],
))

#cap-codigo-parte(
  titulo: "SCM clásico y matrix completion",
  snippet: "from scipy.optimize import minimize\n"
    + "from scipy.linalg import svd\n\n"
    + "def synthetic_control(Y_t_pre, Y_d_pre, Y_d_post):\n"
    + "    \"\"\"Pesos convexos: w >= 0, sum(w) = 1 (SCM clasico).\"\"\"\n"
    + "    N = Y_d_pre.shape[1]\n"
    + "    bounds = [(0, 1)] * N\n"
    + "    cons = [{\"type\": \"eq\", \"fun\": lambda w: np.sum(w) - 1}]\n"
    + "    obj = lambda w: np.sum((Y_t_pre - Y_d_pre @ w)**2)\n"
    + "    res = minimize(obj, np.ones(N)/N, method=\"SLSQP\", bounds=bounds, constraints=cons)\n"
    + "    return res.x, Y_d_post @ res.x   # pesos, contrafactual sintetico\n\n"
    + "def matrix_completion(Y, mask, lam=1.0, n_iter=100, tol=1e-4):\n"
    + "    \"\"\"Imputa faltantes con norma nuclear (SVD soft-thresholding).\"\"\"\n"
    + "    M = Y * mask\n"
    + "    for _ in range(n_iter):\n"
    + "        U, s, Vt = svd(M, full_matrices=False)\n"
    + "        M_new = (U * np.maximum(s - lam, 0)) @ Vt   # soft-threshold\n"
    + "        M_new = Y * mask + M_new * (1 - mask)       # preserva observados\n"
    + "        if np.linalg.norm(M_new - M) < tol:\n"
    + "            break\n"
    + "        M = M_new\n"
    + "    return M",
  nota: "Lam es el hiperparametro que fija el contrafactual: elegirlo por validacion
    cruzada con enmascaramiento EN BLOQUE (ultimos periodos pre-tratamiento), no
    celdas dispersas al azar.",
)

#cap-caso-resolucion(
  titulo: "Inferencia por permutación de placebos",
  contexto: "Con una sola unidad tratada, no hay muestra sobre la que aplicar un
    teorema central del límite.",
  resultado: "Test de aleatorización (Abadie et al., 2015): aplicar el procedimiento
    a cada control como si fuera tratado, construir la distribución de efectos
    placebo. Con J controles, el p-valor mínimo alcanzable es 1/(J+1).",
  interpretacion: "Con 10 donantes no se puede obtener p menor que 0.09, por grande
    que sea el efecto — hay que reportar ese límite, no dejarlo implícito.",
)

#cap-mapeo-pch-activo(
  nivel: "L2 (ATT por período post-tratamiento)",
  metrica: "tau_t; p-valor de permutación acotado por 1/(J+1)",
  pregunta-activa: "¿Qué significa un buen ajuste pre-tratamiento si, aun así, el
    error de imputación pre-tratamiento es comparable a la magnitud del efecto
    post-tratamiento?",
)

#cap-errores-transiciones(
  errores: (
    ("crítico", [Mal ajuste pre-tratamiento: el "efecto" mide el error de ajuste, no
      un efecto real.]),
    ("advertencia", [Pocos donantes: control débil y p-valor de placebo acotado por
      abajo.]),
    ("advertencia", [Unidad tratada fuera de la envolvente convexa de los donantes:
      ningún vector de pesos convexos la reproduce.]),
  ),
  conexiones: "Control sintético aumentado (Ben-Michael et al., 2021) corrige el
    sesgo residual del ajuste imperfecto con un modelo de resultado — la misma
    lógica de augmentation doblemente robusta del Cap. 11.",
)

#cap-discusion-ejercicio(
  pregunta: "¿Por qué el SCM clásico no puede reproducir bien la trayectoria de una
    unidad tratada que es extrema en alguna característica respecto a los
    donantes?",
  ejercicio: "Compare SCM clásico con matrix completion en RMSE sobre un dataset
    sintético con ground truth. Modifique el listado para incluir efectos fijos de
    unidad y de tiempo.",
)

#cap-cierre-narrativo(
  resumen: (
    [SCM clásico: combinación convexa, exige buen fit pre-tratamiento.],
    [Matrix completion: relajación convexa vía norma nuclear, natural para múltiples
     unidades tratadas.],
    [La elección de r/lambda determina el contrafactual — validar con
     enmascaramiento en bloque, no celdas dispersas.],
  ),
  refs: (
    [Abadie, Diamond & Hainmueller (2015), inferencia por permutación],
    [Athey et al. (2021), matrix completion],
    [Ben-Michael, Feller & Rothstein (2021), control sintético aumentado],
  ),
  transicion: "Cap. 29 — Descubrimiento causal y grafos (Parte VIII, S26)",
  gancho: "Hasta aquí, todo el curso asumió el grafo causal dado por conocimiento de
    dominio. La última parte relaja ese supuesto.",
)
