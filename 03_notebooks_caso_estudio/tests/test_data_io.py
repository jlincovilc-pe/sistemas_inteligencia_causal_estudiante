"""Unit tests for lib.paths and lib.data_io (no notebook kernel)."""

from __future__ import annotations

import sys
from pathlib import Path

import pandas as pd
import pytest

# Ensure package root is on sys.path when running pytest from monorepo root
# or from 03_notebooks_caso_estudio/.
_PKG = Path(__file__).resolve().parents[1]
if str(_PKG) not in sys.path:
    sys.path.insert(0, str(_PKG))

from lib.data_io import (  # noqa: E402
    assert_no_truth_columns,
    get_ytx,
    infer_covariate_columns,
    infer_outcome_column,
    load_observed,
    load_scenario,
    load_truth,
    resolve_scenario_paths,
)
from lib.paths import (  # noqa: E402
    DATA_ROOT,
    RANDOM_STATE,
    SCENARIO_A1,
    SCENARIO_A2,
    SCENARIO_A3,
    data_root,
    package_root,
    relative_to_repo,
    repo_root,
    resolve_repo_path,
    scenario_dir,
)

SCENARIOS = [SCENARIO_A1, SCENARIO_A2, SCENARIO_A3]


def test_random_state_default():
    assert RANDOM_STATE == 42


def test_repo_and_data_root_exist():
    assert package_root().name == "03_notebooks_caso_estudio"
    assert repo_root().is_dir()
    root = data_root()
    assert root == DATA_ROOT
    assert root.is_dir(), f"DATA_ROOT missing: {root}"
    assert (root / "real" / "jobs").is_dir()


def test_scenario_dir_rejects_traversal():
    with pytest.raises(ValueError):
        scenario_dir("../etc/passwd")


@pytest.mark.parametrize("scenario", SCENARIOS)
def test_load_scenario_shapes(scenario):
    bundle = load_scenario(scenario)
    assert bundle.scenario == scenario
    assert bundle.scenario_id
    assert len(bundle.train) > 0
    assert len(bundle.validation) > 0
    assert len(bundle.test) > 0
    assert bundle.paths is not None
    assert bundle.paths.root.is_dir()
    # Student bundle must not include truth frames
    assert "y0" not in bundle.train.columns
    assert "tau" not in bundle.train.columns
    assert_no_truth_columns(bundle.train)


@pytest.mark.parametrize("scenario", SCENARIOS)
def test_load_observed_splits(scenario):
    train = load_observed(scenario, "train")
    val = load_observed(scenario, "validation")
    test = load_observed(scenario, "test")
    assert isinstance(train, pd.DataFrame)
    assert len(train) >= len(val)
    assert "treatment" in train.columns
    all_df = load_observed(scenario, "all")
    assert len(all_df) >= len(train)


@pytest.mark.parametrize("scenario", SCENARIOS)
def test_load_truth_evaluation_only(scenario):
    truth = load_truth(scenario, "test")
    for col in ("y0", "y1", "tau"):
        assert col in truth.columns, f"missing {col} in {scenario}"
    assert len(truth) == len(load_observed(scenario, "test"))


def test_jobs_columns_and_ate_meta():
    b = load_scenario(SCENARIO_A1)
    assert b.scenario_id == "real_jobs"
    assert infer_outcome_column(b.train) == "re78"
    covs = infer_covariate_columns(b.train)
    assert "age" in covs and "re75" in covs
    assert "treatment" not in covs and "re78" not in covs
    assert "ate_true" in b.meta
    assert abs(float(b.meta["ate_true"]) - 1600.26) < 1.0
    y, t, X = b.ytx("train")
    assert len(y) == len(t) == len(X) == len(b.train)
    # Plan shapes: train 1033 / val 344 / test 345
    assert len(b.train) == 1033
    assert len(b.validation) == 344
    assert len(b.test) == 345
    assert "treatment" in b.train.columns and "re78" in b.train.columns


def test_ihdp_medium_columns():
    b = load_scenario(SCENARIO_A2)
    assert b.scenario_id == "synthetic_inference_ihdp_medium"
    assert infer_outcome_column(b.train) == "outcome"
    covs = infer_covariate_columns(b.train)
    assert len(covs) == 25
    assert all(c.startswith("x") for c in covs)
    y, t, X = get_ytx(b.train)
    assert X.shape == (len(b.train), 25)
    # Plan shapes: 1200 / 400 / 400
    assert len(b.train) == 1200
    assert len(b.validation) == 400
    assert len(b.test) == 400
    assert "treatment" in b.train.columns and "outcome" in b.train.columns


def test_real_ihdp_columns():
    b = load_scenario(SCENARIO_A3)
    assert b.scenario_id == "real_ihdp"
    assert "bw" in b.train.columns
    assert infer_outcome_column(b.train) == "outcome"
    assert abs(float(b.meta["ate_true"]) - 3.92) < 0.05
    # Plan shapes: 448 / 149 / 150
    assert len(b.train) == 448
    assert len(b.validation) == 149
    assert len(b.test) == 150


def test_truth_loader_separate_from_scenario():
    """Truth is only via load_truth; load_scenario must not attach truth frames."""
    b = load_scenario(SCENARIO_A1)
    assert not hasattr(b, "truth_train") or getattr(b, "truth_train", None) is None
    assert "truth" not in b.__dataclass_fields__  # type: ignore[attr-defined]
    truth = load_truth(SCENARIO_A1, "test")
    assert set(("y0", "y1", "tau")).issubset(set(truth.columns))
    # Observed and truth row counts match per split
    assert len(truth) == len(b.test)


def test_resolve_paths_and_missing_scenario():
    paths = resolve_scenario_paths(SCENARIO_A1)
    assert paths.observed_train.is_file()
    assert paths.metadata.is_file()
    with pytest.raises(FileNotFoundError):
        load_scenario("real/does_not_exist_xyz")


def test_resolve_repo_path_monorepo_relative():
    """export_meta paths like '03_notebooks_caso_estudio/artifacts/...' must resolve."""
    target = package_root() / "artifacts" / "A4" / "policy.joblib"
    if not target.is_file():
        pytest.skip("A4 policy artifact not exported yet")
    rel = relative_to_repo(target)
    resolved = resolve_repo_path(rel)
    assert resolved.is_file()
    assert resolved.resolve() == target.resolve()


def test_load_policy_accepts_repo_relative_path():
    from lib.policy_utils import load_policy

    target = package_root() / "artifacts" / "A4" / "policy.joblib"
    if not target.is_file():
        pytest.skip("A4 policy artifact not exported yet")
    pol = load_policy(relative_to_repo(target))
    assert hasattr(pol, "predict")
