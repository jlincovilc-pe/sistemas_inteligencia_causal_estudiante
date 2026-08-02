"""L12 — Stub de predicción estilo B1 (sin Docker): encode + ATE del artefacto A2."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Dict, List

import numpy as np

_LABS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(_LABS))
from lab_harness import REPO_ROOT, ensure_b1

B1 = ensure_b1()


def load_b1_model():
    # Prefer B1 inference stack
    sys.path.insert(0, str(B1))
    from app.inference import load_model

    return load_model()


def stub_predict(features: Dict[str, float]) -> dict:
    """Pure function: feature map → effect (same contract as B1 /predict)."""
    model = load_b1_model()
    from app.inference import encode_features, predict_effects

    X = encode_features(features, model.feature_names)
    res = predict_effects(model, X)
    return {
        "effect": res.effect,
        "ate": res.ate,
        "ci_low": res.ci_low,
        "ci_high": res.ci_high,
        "n": res.n,
        "method": res.method,
    }


def zero_features(n: int = 25) -> Dict[str, float]:
    return {f"x{i}": 0.0 for i in range(n)}


def run_lab() -> dict:
    feats = zero_features()
    out = stub_predict(feats)
    meta_path = B1 / "artifacts" / "training_meta.json"
    meta = json.loads(meta_path.read_text()) if meta_path.is_file() else {}
    return {
        "predict": out,
        "matches_meta_ate": abs(out["ate"] - float(meta.get("ate_point_estimate", out["ate"])))
        < 1e-6,
        "n_features": 25,
        "lesson": (
            "Separar encode_features + predict_effects del router HTTP "
            "(training-serving skew). B1 añade FastAPI/Docker encima de esto."
        ),
    }


if __name__ == "__main__":
    print(json.dumps(run_lab(), indent=2, default=str))
