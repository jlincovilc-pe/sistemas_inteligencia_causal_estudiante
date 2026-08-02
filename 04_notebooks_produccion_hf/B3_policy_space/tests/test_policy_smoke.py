"""Smoke tests for B3 policy (kernel-less, no Gradio server)."""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pytest

B3 = Path(__file__).resolve().parents[1]
if str(B3) not in sys.path:
    sys.path.insert(0, str(B3))

from policy_service import load_policy, predict_rows, smoke_three_cases  # noqa: E402


@pytest.fixture(scope="module")
def policy():
    path = B3 / "artifacts" / "policy.joblib"
    if not path.is_file():
        pytest.skip("A4 policy not synced")
    return load_policy(path)


def test_load_policy(policy):
    assert hasattr(policy, "predict")
    assert 0 < policy.budget_fraction <= 1
    assert policy.feature_names is not None
    assert len(policy.feature_names) == 25


def test_predict_zeros(policy):
    X = np.zeros((1, 25))
    out = predict_rows(policy, X)
    assert out["decision"].shape == (1,)
    assert out["uplift_score"].shape == (1,)
    assert out["decision"][0] in (0, 1)


def test_three_cases_humo(policy):
    cases = smoke_three_cases(policy)
    assert len(cases) == 3
    for c in cases:
        assert c["decision"] in (0, 1)
        assert np.isfinite(c["uplift_score"])


def test_treat_rate_on_test_approx(policy):
    """On A4 test design, top-20% policy should treat ~20% of random normal rows is not guaranteed;
    instead check threshold is finite and budget metadata."""
    assert np.isfinite(policy.threshold)
    assert abs(policy.budget_fraction - 0.20) < 1e-6


def test_policy_card_exists():
    assert (B3 / "artifacts" / "policy_card.md").is_file()
