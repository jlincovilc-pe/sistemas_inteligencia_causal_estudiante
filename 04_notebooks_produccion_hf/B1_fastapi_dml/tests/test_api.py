"""API smoke tests via FastAPI TestClient."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

B1 = Path(__file__).resolve().parents[1]
if str(B1) not in sys.path:
    sys.path.insert(0, str(B1))

from app.paths import artifact_paths  # noqa: E402


@pytest.fixture(scope="module")
def client():
    if not artifact_paths()["joblib"].is_file():
        pytest.skip("A2 artifacts not synced")
    from fastapi.testclient import TestClient

    from app.main import app

    with TestClient(app) as c:
        yield c


def test_health_ok(client):
    r = client.get("/health")
    assert r.status_code == 200
    body = r.json()
    assert body["status"] == "ok"
    assert body["model_loaded"] is True
    assert body["n_features"] == 25
    assert 2.0 < body["ate"] < 6.0


def test_metadata(client):
    r = client.get("/metadata")
    assert r.status_code == 200
    body = r.json()
    assert len(body["feature_names"]) == 25
    assert body["estimand"] == "ATE"


def test_predict_single(client):
    feats = {f"x{i}": 0.0 for i in range(25)}
    r = client.post("/predict", json={"features": feats})
    assert r.status_code == 200
    body = r.json()
    assert body["n"] == 1
    assert abs(body["effect"] - body["ate"]) < 1e-9
    # Within training CI ballpark
    assert body["ci_low"] is not None
    assert body["ci_low"] < body["ate"] < body["ci_high"]


def test_predict_batch(client):
    inst = [{f"x{i}": float(j) for i in range(25)} for j in range(3)]
    r = client.post("/predict", json={"instances": inst})
    assert r.status_code == 200
    assert r.json()["n"] == 3


def test_predict_matrix(client):
    matrix = [[0.0] * 25, [0.1] * 25]
    r = client.post("/predict", json={"matrix": matrix})
    assert r.status_code == 200
    assert r.json()["n"] == 2


def test_predict_empty_422(client):
    r = client.post("/predict", json={})
    assert r.status_code in (422, 400)
