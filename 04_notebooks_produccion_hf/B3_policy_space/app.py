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

Esta interfaz es un **artefacto docente** del curso *IA Causal en Producción*.

- Los datos del escenario IHDP en el monorepo son **sintéticos** (nombres estilo Hill).
- La política refleja un **presupuesto del 20%** y la población de entrenamiento/test del Notebook A4.
- **No** es una recomendación clínica ni un sistema de producción validado.
"""


def build_demo():
    import gradio as gr

    policy = load_policy_obj()
    names = feature_names(policy)
    # Use a small subset of sliders for UX; full vector still 25 dims with zeros for rest
    # Better: expose all 25 with defaults 0 (IHDP covariates are ~N(0,1) style)
    inputs = [
        gr.Number(value=0.0, label=n, precision=4) for n in names
    ]

    def _run(*vals):
        values = {n: float(v) for n, v in zip(names, vals)}
        r = predict_one(policy, values)
        decision_txt = (
            "**TRATAR** (π=1)" if r["recommend_treat"] else "**NO tratar** (π=0)"
        )
        md = (
            f"### Decisión: {decision_txt}\n\n"
            f"- **uplift_score** ŝ(x) = `{r['uplift_score']:.4f}`\n"
            f"- **umbral λ** = `{r['threshold']:.4f}`\n"
            f"- **presupuesto B** = `{r['budget_fraction']:.0%}`\n"
            f"- **método CATE** = `{r['method']}`\n\n"
            f"Regla: tratar si ŝ(x) ≥ λ (top-k calibrado en A4)."
        )
        return md, r["decision"], r["uplift_score"]

    with gr.Blocks(title="B3 — Policy Space (IHDP-style)") as demo:
        gr.Markdown("# B3 — Política óptima (uplift / targeting)")
        gr.Markdown(
            "Insumo: `artifacts/A4/policy.joblib` · Curso ECO-490 / ECON-540"
        )
        gr.Markdown(DISCLAIMER)

        with gr.Row():
            with gr.Column(scale=2):
                gr.Markdown("### Covariables (escala del benchmark; ~N(0,1) sintético)")
                in_boxes = inputs
                btn = gr.Button("Evaluar política", variant="primary")
            with gr.Column(scale=2):
                out_md = gr.Markdown()
                out_d = gr.Number(label="decision (0/1)")
                out_s = gr.Number(label="uplift_score")
                if UPLIFT_PNG.is_file():
                    gr.Image(value=str(UPLIFT_PNG), label="Curva Qini/uplift de referencia (A4)")

        btn.click(_run, inputs=in_boxes, outputs=[out_md, out_d, out_s])

        with gr.Accordion("Policy card (extracto)", open=False):
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
