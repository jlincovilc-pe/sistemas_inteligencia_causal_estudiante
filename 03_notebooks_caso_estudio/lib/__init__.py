"""Shared infrastructure for Serie A causal case-study notebooks.

Heavy submodules are imported lazily so that unpickling
``SerializablePLREstimator`` (used by Serie B / B1) only needs
``lib.dml_utils`` + numpy/joblib — not pandas/sklearn.

Usage::

    from lib.data_io import load_scenario
    from lib.paths import DATA_ROOT, RANDOM_STATE
    from lib.dml_utils import SerializablePLREstimator
"""

from __future__ import annotations

from typing import Any

__version__ = "0.1.0"

# Lightweight re-exports (no heavy deps)
from .paths import (  # noqa: F401
    DATA_ROOT,
    RANDOM_STATE,
    SCENARIO_A1,
    SCENARIO_A2,
    SCENARIO_A3,
    SCENARIO_A4,
    SCENARIO_IDS,
    artifacts_dir,
    data_root,
    package_root,
    repo_root,
    scenario_dir,
)

__all__ = [
    "DATA_ROOT",
    "RANDOM_STATE",
    "SCENARIO_A1",
    "SCENARIO_A2",
    "SCENARIO_A3",
    "SCENARIO_A4",
    "SCENARIO_IDS",
    "artifacts_dir",
    "data_root",
    "package_root",
    "repo_root",
    "scenario_dir",
    # lazy:
    "ScenarioBundle",
    "ScenarioPaths",
    "get_ytx",
    "infer_covariate_columns",
    "infer_outcome_column",
    "load_observed",
    "load_scenario",
    "load_truth",
    "SerializablePLREstimator",
    "CausalSchema",
]


def __getattr__(name: str) -> Any:
    """Lazy attribute access for heavy modules."""
    data_io_names = {
        "ScenarioBundle",
        "ScenarioPaths",
        "get_ytx",
        "infer_covariate_columns",
        "infer_outcome_column",
        "load_observed",
        "load_scenario",
        "load_truth",
    }
    if name in data_io_names:
        from . import data_io

        return getattr(data_io, name)
    if name == "SerializablePLREstimator":
        from .dml_utils import SerializablePLREstimator

        return SerializablePLREstimator
    if name == "CausalSchema":
        from .schema import CausalSchema

        return CausalSchema
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")
