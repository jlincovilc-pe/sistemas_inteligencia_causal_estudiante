"""Unit tests for lib.metrics and light checks on identification helpers."""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pytest

_PKG = Path(__file__).resolve().parents[1]
if str(_PKG) not in sys.path:
    sys.path.insert(0, str(_PKG))

from lib.identification import (  # noqa: E402
    balance_table,
    diff_in_means,
    fit_propensity,
    overlap_diagnostics,
)
from lib.metrics import (  # noqa: E402
    ate_absolute_error,
    coverage_indicator,
    pehe,
    qini_auc,
    qini_curve,
    uplift_curve,
)
from lib.paths import SCENARIO_A1  # noqa: E402
from lib.data_io import load_scenario  # noqa: E402


def test_ate_absolute_error():
    """Fixed tiny arrays / scalars for ATE absolute error."""
    assert ate_absolute_error(10.0, 7.5) == pytest.approx(2.5)
    assert ate_absolute_error(0.0, 0.0) == pytest.approx(0.0)
    assert ate_absolute_error(-1.5, 1.5) == pytest.approx(3.0)


def test_pehe_perfect():
    tau = np.array([1.0, 2.0, 3.0])
    assert pehe(tau, tau) == pytest.approx(0.0)


def test_pehe_known():
    """PEHE on fixed tiny synthetic arrays."""
    hat = np.array([0.0, 0.0])
    true = np.array([3.0, 4.0])
    # sqrt((9+16)/2) = sqrt(12.5)
    assert pehe(hat, true) == pytest.approx(np.sqrt(12.5))


def test_pehe_shape_mismatch():
    with pytest.raises(ValueError):
        pehe(np.array([1.0, 2.0]), np.array([1.0]))


def test_coverage_indicator():
    assert coverage_indicator(0.0, 1.0, 0.5) is True
    assert coverage_indicator(0.0, 1.0, 2.0) is False


def test_uplift_helper_fixed_tiny_arrays():
    """Uplift curve on a tiny fixed design (deterministic, no RNG)."""
    # Ranked by score descending: unit0 (score 3), unit1 (2), unit2 (1), unit3 (0)
    y = np.array([10.0, 0.0, 8.0, 2.0])
    t = np.array([1, 0, 1, 0])
    score = np.array([3.0, 2.0, 1.0, 0.0])
    up = uplift_curve(y, t, score, n_bins=2)
    assert len(up) == 2
    assert list(up["bin"]) == [1, 2]
    assert "uplift" in up.columns
    # Bin 1 = top half (units 0,1): treated y=10, control y=0 → uplift 10
    assert up.loc[0, "uplift"] == pytest.approx(10.0)
    # Bin 2 = bottom half (units 2,3): treated y=8, control y=2 → uplift 6
    assert up.loc[1, "uplift"] == pytest.approx(6.0)


def test_uplift_and_qini_shapes():
    rng = np.random.RandomState(42)
    n = 200
    y = rng.normal(size=n)
    t = rng.binomial(1, 0.4, size=n)
    score = rng.normal(size=n)
    up = uplift_curve(y, t, score, n_bins=5)
    assert len(up) == 5
    assert "uplift" in up.columns
    q = qini_curve(y, t, score, n_grid=20)
    assert "qini" in q.columns
    assert np.isfinite(qini_auc(q))


def test_propensity_and_balance_on_jobs():
    b = load_scenario(SCENARIO_A1)
    y, t, X = b.ytx("train")
    _, e = fit_propensity(X, t)
    assert e.min() >= 0.0 and e.max() <= 1.0
    diag = overlap_diagnostics(e, t, trim_low=0.02, trim_high=0.98)
    assert diag["n"] == len(t)
    assert 0.0 <= diag["frac_inside_trim"] <= 1.0
    bal = balance_table(X, t)
    assert "smd" in bal.columns
    assert len(bal) == X.shape[1]
    # Sanity: naive ATE is finite
    assert np.isfinite(diff_in_means(y, t))
