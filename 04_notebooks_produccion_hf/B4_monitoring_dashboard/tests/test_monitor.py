"""Tests for B4 monitoring core (no Streamlit server)."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

B4 = Path(__file__).resolve().parents[1]
if str(B4) not in sys.path:
    sys.path.insert(0, str(B4))

from monitor_core import simulate_and_count_alerts  # noqa: E402


def test_drift_triggers_alerts():
    rep = simulate_and_count_alerts(
        n_windows=12,
        drift_start=6,
        ks_threshold=0.12,
    )
    assert rep["n_alerts"] >= 1
    assert rep["max_ks_after_drift"] >= rep["ks_threshold"]


def test_no_drift_fewer_alerts():
    # drift_start beyond last window → no injected drift
    rep = simulate_and_count_alerts(
        n_windows=8,
        drift_start=99,
        ks_threshold=0.25,
    )
    # may have random KS noise; allow 0 or few
    assert rep["n_alerts"] <= 3
