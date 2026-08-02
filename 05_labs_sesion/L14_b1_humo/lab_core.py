"""L14 — Humo del servicio B1 (TestClient) + nota CF light."""

from __future__ import annotations

import sys
from pathlib import Path

_LABS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(_LABS))
from lab_harness import ensure_b1, ensure_serie_a

ensure_serie_a()
B1 = ensure_b1()
sys.path.insert(0, str(B1))


def run_health_and_predict() -> dict:
    from fastapi.testclient import TestClient

    from app.main import app

    with TestClient(app) as client:
        h = client.get("/health")
        feats = {f"x{i}": 0.0 for i in range(25)}
        p = client.post("/predict", json={"features": feats})
        m = client.get("/metadata")
    return {
        "health_status": h.status_code,
        "health_body": h.json() if h.status_code == 200 else {},
        "predict_status": p.status_code,
        "predict_body": p.json() if p.status_code == 200 else {},
        "metadata_status": m.status_code,
        "n_features_meta": len(m.json().get("feature_names", [])) if m.status_code == 200 else 0,
    }


def run_lab() -> dict:
    api = run_health_and_predict()
    ok = (
        api["health_status"] == 200
        and api["health_body"].get("status") == "ok"
        and api["predict_status"] == 200
        and api["metadata_status"] == 200
        and api["n_features_meta"] == 25
    )
    return {
        "api": api,
        "humo_ok": ok,
        "ate": api["predict_body"].get("ate"),
        "next": "Empaquetar con Dockerfile B1; continuar A3 (meta-learners) en L13.",
    }


if __name__ == "__main__":
    import json

    print(json.dumps(run_lab(), indent=2, default=str))
