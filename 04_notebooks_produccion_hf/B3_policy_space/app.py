"""B3 — Gradio Space: policy de targeting (artefacto A4).

Run local::

    cd 04_notebooks_produccion_hf/B3_policy_space
    python app.py

Or::

    gradio app.py
"""

from __future__ import annotations

import os
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import numpy as np

B3_ROOT = Path(__file__).resolve().parent
REPO = B3_ROOT.parents[1]
SERIE_A = REPO / "03_notebooks_caso_estudio"
if str(SERIE_A) not in sys.path:
    sys.path.insert(0, str(SERIE_A))

# ---------------------------------------------------------------------------
# Paths / load
# ---------------------------------------------------------------------------

ARTIFACTS = Path(os.environ.get("B3_ARTIFACTS_DIR", B3_ROOT / "artifacts"))
POLICY_PATH = ARTIFACTS / "policy.joblib"
CARD_PATH = ARTIFACTS / "policy_card.md"
UPLIFT_PNG = ARTIFACTS / "uplift_curve.png"

# Default feature order (IHDP real scenario)
DEFAULT_FEATURES: List[str] = [
    "bw",
    "b.head",
    "preterm",
    "birth.o",
    "nnhealth",
    "momage",
    "sex",
    "twin",
    "b.marr",
    "mom.lths",
    "mom.hs",
    "mom.scoll",
    "cig",
    "first",
    "booze",
    "drugs",
    "work.dur",
    "prenatal",
    "ark",
    "ein",
    "har",
    "mia",
    "pen",
    "tex",
    "was",
]

# Etiquetas en español + explicación corta para quien no conoce el dataset IHDP.
# Los 6 primeros campos son continuos y están estandarizados (~N(0,1)); el resto
# son indicadores binarios (0/1). No requieren interpretación clínica individual.
FEATURE_INFO: Dict[str, Dict[str, str]] = {
    "bw": {"label": "Peso al nacer", "info": "Valor estandarizado (~N(0,1)), no gramos reales"},
    "b.head": {"label": "Circunferencia craneal al nacer", "info": "Valor estandarizado"},
    "preterm": {"label": "Semanas de prematuridad", "info": "Valor estandarizado"},
    "birth.o": {"label": "Orden de nacimiento", "info": "Valor estandarizado"},
    "nnhealth": {"label": "Índice de salud neonatal", "info": "Valor estandarizado"},
    "momage": {"label": "Edad de la madre", "info": "Valor estandarizada"},
    "sex": {"label": "Sexo del bebé", "info": "0 / 1"},
    "twin": {"label": "Nacimiento múltiple (gemelar)", "info": "0 = no, 1 = sí"},
    "b.marr": {"label": "Madre casada al nacer", "info": "0 = no, 1 = sí"},
    "mom.lths": {"label": "Madre sin secundaria completa", "info": "0 = no, 1 = sí"},
    "mom.hs": {"label": "Madre con secundaria completa", "info": "0 = no, 1 = sí"},
    "mom.scoll": {"label": "Madre con estudios superiores parciales", "info": "0 = no, 1 = sí"},
    "cig": {"label": "Madre fumó durante el embarazo", "info": "0 = no, 1 = sí"},
    "first": {"label": "Primer hijo/a", "info": "0 = no, 1 = sí"},
    "booze": {"label": "Madre consumió alcohol en el embarazo", "info": "0 = no, 1 = sí"},
    "drugs": {"label": "Madre consumió drogas en el embarazo", "info": "0 = no, 1 = sí"},
    "work.dur": {"label": "Madre trabajó durante el embarazo", "info": "0 = no, 1 = sí"},
    "prenatal": {"label": "Cuidado prenatal adecuado", "info": "0 = no, 1 = sí"},
    "ark": {"label": "Sitio del estudio: ark", "info": "Indicador binario de centro (sin lectura clínica individual)"},
    "ein": {"label": "Sitio del estudio: ein", "info": "Indicador binario de centro (sin lectura clínica individual)"},
    "har": {"label": "Sitio del estudio: har", "info": "Indicador binario de centro (sin lectura clínica individual)"},
    "mia": {"label": "Sitio del estudio: mia", "info": "Indicador binario de centro (sin lectura clínica individual)"},
    "pen": {"label": "Sitio del estudio: pen", "info": "Indicador binario de centro (sin lectura clínica individual)"},
    "tex": {"label": "Sitio del estudio: tex", "info": "Indicador binario de centro (sin lectura clínica individual)"},
    "was": {"label": "Sitio del estudio: was", "info": "Indicador binario de centro (sin lectura clínica individual)"},
}


def load_policy_obj():
    from lib.policy_utils import load_policy

    if not POLICY_PATH.is_file():
        raise FileNotFoundError(
            f"Missing {POLICY_PATH}. Sync A4 artifacts first "
            "(scripts/sync_a4_artifacts.py)."
        )
    return load_policy(POLICY_PATH)


def feature_names(policy) -> List[str]:
    names = getattr(policy, "feature_names", None)
    if names:
        return list(names)
    return list(DEFAULT_FEATURES)


def predict_one(policy, values: Dict[str, float]) -> Dict[str, Any]:
    names = feature_names(policy)
    row = [float(values[n]) for n in names]
    X = np.asarray([row], dtype=float)
    out = policy.predict(X=X)
    decision = int(np.asarray(out["decision"]).reshape(-1)[0])
    score = float(np.asarray(out["uplift_score"]).reshape(-1)[0])
    return {
        "decision": decision,
        "uplift_score": score,
        "recommend_treat": bool(decision == 1),
        "threshold": float(getattr(policy, "threshold", float("nan"))),
        "budget_fraction": float(getattr(policy, "budget_fraction", 0.2)),
        "method": str(getattr(policy, "method_name", "cate")),
    }


def load_card_excerpt(max_chars: int = 2500) -> str:
    if not CARD_PATH.is_file():
        return "_policy_card.md no encontrado_"
    text = CARD_PATH.read_text(encoding="utf-8")
    if len(text) > max_chars:
        return text[:max_chars] + "\n\n…_(recortado)_"
    return text


# ---------------------------------------------------------------------------
# Gradio UI
# ---------------------------------------------------------------------------

DISCLAIMER = """
### Aviso (obligatorio)

Esta interfaz es un **artefacto docente** del curso *IA Causal en Producción*, pensado para que un **decisor de negocio** (no solo un analista) explore la política sin código.

- Los datos del escenario IHDP en el monorepo son **sintéticos** (nombres estilo Hill).
- La política refleja una **capacidad limitada: solo se puede atender al 20% de la población**, y prioriza por **efecto estimado**, no por quién tiene peor pronóstico.
- **No** es una recomendación clínica ni un sistema de producción validado.
"""


def build_demo():
    import gradio as gr

    policy = load_policy_obj()
    names = feature_names(policy)
    # Un input por covariable, con etiqueta en español + explicación corta
    # (FEATURE_INFO) en vez de exponer el nombre técnico crudo del dataset.
    inputs = [
        gr.Number(
            value=0.0,
            label=FEATURE_INFO.get(n, {}).get("label", n),
            info=FEATURE_INFO.get(n, {}).get("info"),
            precision=4,
        )
        for n in names
    ]

    def _run(*vals):
        values = {n: float(v) for n, v in zip(names, vals)}
        r = predict_one(policy, values)
        decision_txt = (
            "✅ **Sí, incluir en el programa**" if r["recommend_treat"]
            else "❌ **No incluir, por ahora**"
        )
        md = (
            f"### Recomendación: {decision_txt}\n\n"
            f"- **Beneficio estimado de intervenir** (uplift): `{r['uplift_score']:.4f}` "
            f"— cuanto más alto, más se espera que esta unidad se beneficie de la intervención frente a no recibirla.\n"
            f"- **Corte de decisión**: `{r['threshold']:.4f}` — calibrado para no exceder la capacidad disponible.\n"
            f"- **Capacidad del programa**: se puede atender al `{r['budget_fraction']:.0%}` de la población; "
            f"esta regla prioriza a quienes más se benefician, **no** a quienes tienen peor pronóstico.\n"
            f"- **Método usado para estimar el efecto**: `{r['method']}`\n\n"
            f"En una frase: se recomienda tratar cuando el beneficio estimado de esta unidad está entre el "
            f"`{r['budget_fraction']:.0%}` más alto de toda la población evaluada."
        )
        return md, r["decision"], r["uplift_score"]

    with gr.Blocks(title="B3 — Política de asignación (IHDP-style)") as demo:
        gr.Markdown("# B3 — ¿A quién conviene tratar con presupuesto limitado?")
        gr.Markdown(
            "Simulador de decisión: dado un perfil, indica si conviene incluirlo en el programa "
            "según el **efecto estimado**, no según su pronóstico. "
            "Insumo: `artifacts/A4/policy.joblib` · Curso ECO-490 / ECON-540"
        )
        gr.Markdown(DISCLAIMER)

        with gr.Row():
            with gr.Column(scale=2):
                gr.Markdown(
                    "### Perfil de la unidad a evaluar\n"
                    "Valores estandarizados del benchmark sintético (no datos reales de una persona)."
                )
                in_boxes = inputs
                btn = gr.Button("Evaluar política", variant="primary")
            with gr.Column(scale=2):
                out_md = gr.Markdown()
                out_d = gr.Number(label="Decisión (0 = no tratar, 1 = tratar)")
                out_s = gr.Number(label="Beneficio estimado (uplift score)")
                if UPLIFT_PNG.is_file():
                    gr.Image(value=str(UPLIFT_PNG), label="Curva Qini/uplift de referencia (A4)")

        btn.click(_run, inputs=in_boxes, outputs=[out_md, out_d, out_s])

        with gr.Accordion("Policy card (detalle técnico, para auditoría)", open=False):
            gr.Markdown(load_card_excerpt())

        gr.Markdown(
            "Handoff Serie A4 → B3 · Ver `PLAN_CURSO_COMPLETO.md` y `policy_card.md`."
        )

    return demo


def main():
    demo = build_demo()
    demo.launch(
        server_name=os.environ.get("GRADIO_SERVER_NAME", "127.0.0.1"),
        server_port=int(os.environ.get("GRADIO_SERVER_PORT", "7860")),
        share=os.environ.get("GRADIO_SHARE", "0") == "1",
    )


if __name__ == "__main__":
    main()
