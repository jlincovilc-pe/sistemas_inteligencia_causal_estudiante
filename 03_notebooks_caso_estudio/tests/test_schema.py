"""Tests for lib.schema.CausalSchema."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_PKG = Path(__file__).resolve().parents[1]
if str(_PKG) not in sys.path:
    sys.path.insert(0, str(_PKG))

from lib.schema import CausalSchema  # noqa: E402
from lib.paths import SCENARIO_A1, SCENARIO_A2  # noqa: E402


def test_from_scenario_jobs():
    s = CausalSchema.from_scenario(SCENARIO_A1)
    assert s.treatment == "treatment"
    assert s.outcome == "re78"
    assert len(s.covariates) == 8
    assert "age" in s.covariates
    y, t, X = s.ytx_scenario(split="train")
    assert len(y) == len(t) == len(X) == 1033
    assert list(X.columns) == s.covariates


def test_from_scenario_ihdp_medium():
    s = CausalSchema.from_scenario(SCENARIO_A2)
    assert s.outcome == "outcome"
    assert len(s.covariates) == 25
    text = s.summary()
    assert "CausalSchema" in text
    assert s.feature_list() == s.covariates


def test_validate_missing_raises():
    s = CausalSchema.from_scenario(SCENARIO_A1)
    import pandas as pd

    bad = pd.DataFrame({"treatment": [0, 1], "re78": [1.0, 2.0]})
    with pytest.raises(KeyError):
        s.validate(bad)


def test_to_dict_roundtrip_keys():
    s = CausalSchema.from_scenario(SCENARIO_A1)
    d = s.to_dict()
    assert set(d) >= {"treatment", "outcome", "covariates", "instruments"}
