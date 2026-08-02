#!/usr/bin/env python3
"""Autograder B1 — humo de servicio DML (local, sin Docker obligatorio)."""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

B1 = Path(__file__).resolve().parents[1] / "B1_fastapi_dml"
if str(B1) not in sys.path:
    sys.path.insert(0, str(B1))

# Tolerances
ATE_REF = 3.5276555470477944  # A2 training_meta
ATE_TOL = 0.15
PREDICT_MAX_S = 2.0


def _check(name: str, ok: bool, detail: str, rows: list) -> None:
    status = "PASS" if ok else "FAIL"
    rows.append((name, ok, detail))
    print(f"  [{status}] {name}: {detail}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Grade B1 FastAPI DML service")
    parser.add_argument(
        "--base-url",
        default=None,
        help="If set, grade a live HTTP server instead of TestClient",
    )
    args = parser.parse_args()

    print("=" * 60)
    print("B1 Autograder — FastAPI DML service")
    print("=" * 60)
    rows = []

    # --- structure ---
    app_py = B1 / "app" / "main.py"
    docker = B1 / "Dockerfile"
    req = B1 / "requirements.txt"
    arts = B1 / "artifacts" / "dml_estimator.joblib"
    _check("structure_app", app_py.is_file(), str(app_py), rows)
    _check("structure_dockerfile", docker.is_file(), str(docker), rows)
    _check("structure_requirements", req.is_file(), str(req), rows)
    _check("artifacts_joblib", arts.is_file(), str(arts), rows)

    # --- pure inference ---
    try:
        from app.inference import load_model, encode_features, predict_effects

        model = load_model()
        ate = model.ate
        _check(
            "load_model_ate",
            abs(ate - ATE_REF) < ATE_TOL,
            f"ate={ate:.4f} ref={ATE_REF:.4f} tol={ATE_TOL}",
            rows,
        )
        _check(
            "n_features_25",
            len(model.feature_names) == 25,
            f"n={len(model.feature_names)}",
            rows,
        )
        X = encode_features({f: 0.0 for f in model.feature_names}, model.feature_names)
        t0 = time.perf_counter()
        res = predict_effects(model, X)
        dt = time.perf_counter() - t0
        _check(
            "predict_latency",
            dt < PREDICT_MAX_S,
            f"{dt:.4f}s < {PREDICT_MAX_S}s",
            rows,
        )
        _check(
            "predict_matches_ate",
            abs(res.effect - ate) < 1e-6,
            f"effect={res.effect} ate={ate}",
            rows,
        )
    except Exception as exc:
        _check("inference_pipeline", False, repr(exc), rows)

    # --- API ---
    try:
        if args.base_url:
            import httpx

            base = args.base_url.rstrip("/")
            t0 = time.perf_counter()
            h = httpx.get(f"{base}/health", timeout=10.0)
            dt = time.perf_counter() - t0
            body = h.json()
            _check("http_health", h.status_code == 200 and body.get("status") == "ok", str(body)[:120], rows)
            feats = {f"x{i}": 0.0 for i in range(25)}
            t0 = time.perf_counter()
            p = httpx.post(f"{base}/predict", json={"features": feats}, timeout=10.0)
            dt = time.perf_counter() - t0
            _check(
                "http_predict",
                p.status_code == 200 and dt < PREDICT_MAX_S,
                f"status={p.status_code} {dt:.4f}s body={p.json()}",
                rows,
            )
        else:
            from fastapi.testclient import TestClient
            from app.main import app

            with TestClient(app) as client:
                h = client.get("/health")
                _check(
                    "api_health",
                    h.status_code == 200 and h.json().get("status") == "ok",
                    str(h.json())[:160],
                    rows,
                )
                feats = {f"x{i}": 0.0 for i in range(25)}
                t0 = time.perf_counter()
                p = client.post("/predict", json={"features": feats})
                dt = time.perf_counter() - t0
                ok = p.status_code == 200 and dt < PREDICT_MAX_S
                pj = p.json() if p.status_code == 200 else {}
                _check(
                    "api_predict",
                    ok and abs(pj.get("ate", 0) - ATE_REF) < ATE_TOL,
                    f"status={p.status_code} {dt:.4f}s ate={pj.get('ate')}",
                    rows,
                )
                meta = client.get("/metadata")
                _check(
                    "api_metadata",
                    meta.status_code == 200 and len(meta.json().get("feature_names", [])) == 25,
                    f"status={meta.status_code}",
                    rows,
                )
    except Exception as exc:
        _check("api_layer", False, repr(exc), rows)

    n_pass = sum(1 for _, ok, _ in rows if ok)
    n = len(rows)
    print("-" * 60)
    print(f"Result: {'PASS' if n_pass == n else 'FAIL'} ({n_pass}/{n} checks)")
    return 0 if n_pass == n else 1


if __name__ == "__main__":
    raise SystemExit(main())
