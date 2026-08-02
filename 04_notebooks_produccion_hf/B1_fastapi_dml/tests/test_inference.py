"""Unit tests for B1 pure inference (no server required)."""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pytest

B1 = Path(__file__).resolve().parents[1]
if str(B1) not in sys.path:
    sys.path.insert(0, str(B1))

from app.inference import (  # noqa: E402
    encode_features,
    load_model,
    predict_effects,
)
from app.paths import artifact_paths  # noqa: E402


@pytest.fixture(scope="module")
def model():
    paths = artifact_paths()
    if not paths["joblib"].is_file():
        pytest.skip("A2 artifacts not synced into B1/artifacts")
    return load_model()


def test_load_model_ate(model):
    ate = model.ate
    assert 2.0 < ate < 6.0  # ihdp-scale ATE
    assert len(model.feature_names) == 25


def test_encode_and_predict_single(model):
    row = {f: 0.0 for f in model.feature_names}
    X = encode_features(row, model.feature_names)
    assert X.shape == (1, 25)
    res = predict_effects(model, X)
    assert res.n == 1
    assert abs(res.effect - res.ate) < 1e-9  # homogeneous PLR
    assert abs(res.ate - model.ate) < 1e-9


def test_predict_batch(model):
    X = np.zeros((3, 25), dtype=float)
    res = predict_effects(model, X)
    assert res.n == 3
    assert len(res.effects) == 3


def test_encode_missing_feature_raises(model):
    bad = {f: 0.0 for f in model.feature_names[:-1]}
    with pytest.raises(ValueError, match="missing"):
        encode_features(bad, model.feature_names)


def test_ate_matches_training_meta(model):
    meta_ate = model.meta.get("ate_point_estimate")
    if meta_ate is None:
        pytest.skip("no ate_point_estimate in training_meta")
    assert abs(model.ate - float(meta_ate)) < 1e-6
