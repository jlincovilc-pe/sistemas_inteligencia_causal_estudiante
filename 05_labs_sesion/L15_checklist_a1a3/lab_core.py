"""L15 — Checklist de integración A1–A3 + humo de artefactos."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any, Dict, List

_LABS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(_LABS))
from lab_harness import REPO_ROOT, SERIE_A, ensure_serie_a

ensure_serie_a()


def _exists(rel: str) -> bool:
    return (REPO_ROOT / rel).is_file()


def checklist() -> List[Dict[str, Any]]:
    items = [
        {
            "id": "A1_notebook",
            "path": "03_notebooks_caso_estudio/notebooks/A1_identificacion_jobs.ipynb",
            "ok": _exists("03_notebooks_caso_estudio/notebooks/A1_identificacion_jobs.ipynb"),
        },
        {
            "id": "A2_notebook",
            "path": "03_notebooks_caso_estudio/notebooks/A2_dml_ihdp_medium.ipynb",
            "ok": _exists("03_notebooks_caso_estudio/notebooks/A2_dml_ihdp_medium.ipynb"),
        },
        {
            "id": "A3_notebook",
            "path": "03_notebooks_caso_estudio/notebooks/A3_cate_meta_learners_ihdp.ipynb",
            "ok": _exists("03_notebooks_caso_estudio/notebooks/A3_cate_meta_learners_ihdp.ipynb"),
        },
        {
            "id": "A2_joblib",
            "path": "03_notebooks_caso_estudio/artifacts/A2/dml_estimator.joblib",
            "ok": _exists("03_notebooks_caso_estudio/artifacts/A2/dml_estimator.joblib"),
        },
        {
            "id": "A2_meta",
            "path": "03_notebooks_caso_estudio/artifacts/A2/training_meta.json",
            "ok": _exists("03_notebooks_caso_estudio/artifacts/A2/training_meta.json"),
        },
        {
            "id": "A3_scores",
            "path": "03_notebooks_caso_estudio/artifacts/A3/cate_scores_test.csv",
            "ok": _exists("03_notebooks_caso_estudio/artifacts/A3/cate_scores_test.csv"),
        },
        {
            "id": "B1_app",
            "path": "04_notebooks_produccion_hf/B1_fastapi_dml/app/main.py",
            "ok": _exists("04_notebooks_produccion_hf/B1_fastapi_dml/app/main.py"),
        },
        {
            "id": "datasets_jobs",
            "path": "data_benchmark_causal/causal_benchmark_synthetic/datasets/real/jobs/observed_train.csv",
            "ok": _exists(
                "data_benchmark_causal/causal_benchmark_synthetic/datasets/real/jobs/observed_train.csv"
            ),
        },
        {
            "id": "datasets_ihdp",
            "path": "data_benchmark_causal/causal_benchmark_synthetic/datasets/real/ihdp/observed_train.csv",
            "ok": _exists(
                "data_benchmark_causal/causal_benchmark_synthetic/datasets/real/ihdp/observed_train.csv"
            ),
        },
    ]
    return items


def validate_a2_meta() -> Dict[str, Any]:
    p = SERIE_A / "artifacts" / "A2" / "training_meta.json"
    if not p.is_file():
        return {"ok": False, "error": "missing training_meta"}
    meta = json.loads(p.read_text(encoding="utf-8"))
    ate = float(meta.get("ate_point_estimate", float("nan")))
    return {
        "ok": 2.5 < ate < 5.5,
        "ate": ate,
        "scenario_id": meta.get("scenario_id"),
        "estimand": meta.get("estimand"),
    }


def validate_a3_scores() -> Dict[str, Any]:
    import pandas as pd

    p = SERIE_A / "artifacts" / "A3" / "cate_scores_test.csv"
    if not p.is_file():
        return {"ok": False, "error": "missing scores"}
    df = pd.read_csv(p)
    cols = list(df.columns)
    has_tau = any(c.startswith("tau_hat") for c in cols)
    return {
        "ok": has_tau and len(df) >= 100,
        "n_rows": len(df),
        "columns": cols[:12],
        "method_selected": df["method_selected"].iloc[0]
        if "method_selected" in df.columns
        else None,
    }


def common_bugs() -> List[str]:
    return [
        "Usar truth (y0/y1/tau) en celdas de estimación → invalidación A1–A3",
        "Re-particionar Jobs/IHDP en lugar de splits oficiales",
        "Incluir outcome o treatment como 'feature' de X (fuga, L08)",
        "Olvidar cross-fitting en DML (fuga entre folds)",
        "Serializar estimador sin feature_list.json / training_meta.json",
        "Confundir ATE homogéneo (A2) con CATE individual (A3/A4)",
    ]


def run_lab() -> dict:
    items = checklist()
    n_ok = sum(1 for i in items if i["ok"])
    a2 = validate_a2_meta()
    a3 = validate_a3_scores()
    return {
        "checklist": items,
        "n_ok": n_ok,
        "n_items": len(items),
        "all_green": n_ok == len(items) and a2["ok"] and a3["ok"],
        "a2_meta": a2,
        "a3_scores": a3,
        "common_bugs": common_bugs(),
        "session": "S15",
    }


if __name__ == "__main__":
    print(json.dumps(run_lab(), indent=2, default=str))
