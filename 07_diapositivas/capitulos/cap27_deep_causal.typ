// =============================================================================
// Diapositivas · Capítulo 27 — Deep learning para inferencia causal
// Fuente: 02_monografia/.../capitulos/cap13_deep_causal.typ
// Plan detallado: PLAN_SPRINT_DIAPOSITIVAS.md §3, "Cap. 27"
// Sin sesión propia — electivo avanzado (no bloquea HF). Variante A · ◇
// =============================================================================
#import "../plantilla_monografia.typ": *

#show: cap-theme

#cap-init(num: 27, titulo: "Deep learning para inferencia causal",
  parte: "VII", sesion: "electivo avanzado", variant: "A", critico: false)

#cap-portada(num: 27, titulo: "Deep learning para inferencia causal",
  parte: "VII", sesion: "electivo avanzado", variant: "A", critico: false)

#cap-roadmap(
  objetivos: (
    [Describir TARNet/CFRNet y el rol de la representación balanceada.],
    [Explicar por qué balancear no siempre ayuda — α como hiperparámetro a validar.],
    [Explicar por qué la inferencia válida con redes NO es un problema abierto.],
  ),
  agenda: (
    [Adherencia a medicamentos, recordatorios personalizados],
    [TARNet/CFRNet: representación compartida + balance IPM],
    [¿Balancear ayuda siempre? (Curth & van der Schaar, 2021)],
    [Inferencia válida: redes como nuisance dentro de DML],
  ),
  lectura: "Cap. 27 — Deep causal (@cap-deep-causal) — electivo avanzado, no bloquea
    el camino ★",
  lab: "—", entrega: "—",
)

#cap-motivacion(
  problema: "Plataforma de salud digital: efecto de recordatorios personalizados
    sobre adherencia a medicamentos. Efecto altamente no lineal — Causal Forest puede
    no capturar la estructura compleja.",
  gancho: "TARNet aprende una representación compartida Phi(X); CFRNet añade una
    penalización que fuerza a que Phi(X) se parezca entre tratados y controles.",
  caso: "DGP sintético con no linealidades e interacciones de alto orden.",
)

// Los dos giros pedagogicos mas importantes del capitulo.
#cap-teorema(
  titulo: "Dos correcciones al estado del arte de 2017",
  enunciado: "(1) Balancear no siempre ayuda (Curth & van der Schaar, 2021): la cota
    de Shalit et al. es LAXA — minimizarla no equivale a minimizar el error en tau.
    Alpha debe validarse, no activarse como interruptor; TARNet sin penalización es
    competidor serio. (2) La inferencia válida NO es un problema abierto: Farrell,
    Liang & Misra (2021) dan tasas para redes como nuisance dentro de DML; RieszNet
    (Chernozhukov et al., 2022) aprende el representador de Riesz en vez de derivarlo
    a mano.",
)

#cap-demostracion(pasos: (
  [Con alpha grande, la representación se vuelve tan balanceada como poco informativa
   — en el extremo, Phi constante logra balance perfecto y error máximo.],
  [Usar la red donde su capacidad de aproximación aporta: los nuisance de alta
   dimensión dentro de DML — y dejar la inferencia al aparato ortogonal del Cap. 10,
   que ya la tiene resuelta.],
  [RieszNet automatiza la construcción del score ortogonal para funcionales sin
   fórmula analítica derivada a mano.],
))

#cap-interactivo(
  tipo: "Conceptual",
  pregunta: "¿Por qué TARNet sin penalización de balance puede ser un competidor
    serio frente a CFRNet, si toda la motivación de CFRNet es forzar el balance?",
)

#cap-codigo-parte(
  titulo: "TARNet en PyTorch",
  snippet: "class TARNet(nn.Module):\n"
    + "    def __init__(self, in_dim, rep_dim=64, hidden=128):\n"
    + "        super().__init__()\n"
    + "        self.rep = nn.Sequential(          # representacion compartida\n"
    + "            nn.Linear(in_dim, hidden), nn.ReLU(),\n"
    + "            nn.Linear(hidden, rep_dim),\n"
    + "        )\n"
    + "        self.h0 = nn.Sequential(nn.Linear(rep_dim, hidden), nn.ReLU(), nn.Linear(hidden, 1))\n"
    + "        self.h1 = nn.Sequential(nn.Linear(rep_dim, hidden), nn.ReLU(), nn.Linear(hidden, 1))\n\n"
    + "    def forward(self, X, D):               # solo la cabeza de su grupo\n"
    + "        Phi = self.rep(X)\n"
    + "        return torch.where(D.unsqueeze(-1) == 1, self.h1(Phi), self.h0(Phi)).squeeze(-1)\n\n"
    + "    def predict_cate(self, X):\n"
    + "        Phi = self.rep(X)\n"
    + "        return (self.h1(Phi) - self.h0(Phi)).squeeze()   # tau_hat(x)\n\n"
    + "# CFRNet: loss = MSE + alpha * MMD(Phi|D=0, Phi|D=1)  -- alpha a validar",
  nota: "CFRNet anade la penalizacion MMD entre Phi(X|D=0) y Phi(X|D=1) a la loss
    MSE. Alpha es hiperparametro a validar, no un interruptor \"balancear es bueno\"
    (Curth & van der Schaar, 2021).",
)

#cap-caso-resolucion(
  titulo: "Redes como nuisance dentro de DML",
  contexto: "En vez de estimar tau directamente con una red y buscar cómo hacer
    inferencia después.",
  resultado: "Usar la red como model_y/model_t dentro de LinearDML — teóricamente
    respaldado por Farrell, Liang & Misra (2021).",
  interpretacion: "Probablemente la forma más sensata de combinar deep learning e
    inferencia causal en producción hoy.",
)

#cap-mapeo-pch-activo(
  nivel: "L2 heterogéneo, vía representación aprendida",
  metrica: "RMSE(tau_hat, tau); R2 de fidelidad si se usa como nuisance",
  pregunta-activa: "¿Cuándo el deep causal supera a los árboles, y cuándo el costo de
    ajustar hiperparámetros no se justifica frente a un Causal Forest?",
)

#cap-errores-transiciones(
  errores: (
    ("advertencia", [Tratar alpha como interruptor "balancear es bueno" en vez de
      hiperparámetro a validar.]),
    ("advertencia", [Reportar el punto de tau_hat(x) sin ningún intervalo de
      confianza — mitigación: red como nuisance dentro de DML, bootstrap, o
      intervalos conformes para decisiones individuales (Cap. 14).]),
  ),
  conexiones: "Conecta con el Cap. 10 (ortogonalidad) por la vía de usar redes como
    nuisance en vez de estimador final.",
)

#cap-discusion-ejercicio(
  pregunta: "¿En qué punto el deep causal supera a los árboles a medida que crecen
    las no linealidades del DGP?",
  ejercicio: "Barra alpha en {0, 0.1, 1, 10, 100} y grafique RMSE en tau contra el
    MMD de la representación. Verifique que el alpha que minimiza el MMD no es el que
    minimiza el RMSE.",
)

#cap-cierre-narrativo(
  resumen: (
    [TARNet/CFRNet aprenden una representación compartida con balance opcional.],
    [Balancear más no siempre reduce el error — es un hiperparámetro, no un
     principio.],
    [La inferencia válida con redes tiene solución conocida: usarlas como nuisance
     dentro de DML.],
  ),
  refs: (
    [Shalit, Johansson & Sontag (2017), TARNet/CFRNet],
    [Curth & van der Schaar (2021), sesgos inductivos],
    [Farrell, Liang & Misra (2021), inferencia con redes profundas],
  ),
  transicion: "Cap. 28 — Control sintético y matrix completion",
  gancho: "TARNet/CFRNet estiman a nivel de unidad; el capítulo electivo que sigue
    trata el caso de una sola unidad tratada observada en el tiempo.",
)
