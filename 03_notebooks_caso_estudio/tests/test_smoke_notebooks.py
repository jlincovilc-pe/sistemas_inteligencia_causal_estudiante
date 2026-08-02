"""Kernel-less smoke tests for Serie A (imports, notebooks, critical paths).

Full ``nbconvert --execute`` of A1–A4 can exceed 20 minutes and may need
optional deps (econml). This module therefore provides a **smoke mode**:

1. Import every ``lib.*`` module without a Jupyter kernel.
2. Parse notebooks with ``json`` (nbformat optional) and assert structure.
3. Exercise critical pure-Python estimation paths on real datasets offline.
4. Assert Serie B handoff artifacts (A2 → B1, A4 → B3) exist and load.
5. Assert each ``autograder/grade_a*.py`` exposes a CLI ``main()``.

Run from package root::

    pytest tests/ -q
    pytest tests/test_smoke_notebooks.py -q

Optional heavy mode (env)::

    SERIE_A_NBCONVERT=1 pytest tests/test_smoke_notebooks.py -q -k nbconvert
"""

from __future__ import annotations

import importlib
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, List

import numpy as np
import pytest

# Package root on sys.path (pytest from monorepo root or base_dir).
_PKG = Path(__file__).resolve().parents[1]
if str(_PKG) not in sys.path:
    sys.path.insert(0, str(_PKG))

from lib.paths import (  # noqa: E402
    RANDOM_STATE,
    SCENARIO_A1,
    SCENARIO_A2,
    SCENARIO_A3,
    SCENARIO_A4,
    artifacts_dir,
    notebooks_dir,
    package_root,
)

LIB_MODULES = (
    "lib",
    "lib.paths",
    "lib.data_io",
    "lib.metrics",
    "lib.identification",
    "lib.dml_utils",
    "lib.cate_utils",
    "lib.policy_utils",
    "lib.plotting",
)

NOTEBOOKS = (
    "A1_identificacion_jobs.ipynb",
    "A2_dml_ihdp_medium.ipynb",
    "A3_cate_meta_learners_ihdp.ipynb",
    "A4_policy_uplift_ihdp.ipynb",
)

AUTOGRADERS = (
    "grade_a1.py",
    "grade_a2.py",
    "grade_a3.py",
    "grade_a4.py",
)


# ---------------------------------------------------------------------------
# 1. Imports
# ---------------------------------------------------------------------------


@pytest.mark.parametrize("modname", LIB_MODULES)
def test_import_lib_module(modname: str):
    mod = importlib.import_module(modname)
    assert mod is not None


def test_random_state_is_42():
    assert RANDOM_STATE == 42


# ---------------------------------------------------------------------------
# 2. Notebook presence + static structure (no kernel)
# ---------------------------------------------------------------------------


def _load_nb(path: Path) -> Dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def _cell_source(cell: dict) -> str:
    src = cell.get("source", "")
    if isinstance(src, list):
        return "".join(src)
    return str(src)


@pytest.mark.parametrize("nb_name", NOTEBOOKS)
def test_notebook_exists_and_parses(nb_name: str):
    path = notebooks_dir() / nb_name
    assert path.is_file(), f"Missing notebook: {path}"
    nb = _load_nb(path)
    assert nb.get("nbformat") == 4
    cells = nb.get("cells", [])
    assert len(cells) >= 8, f"{nb_name}: expected substantive outline"
    # At least one code + one markdown cell
    types = {c.get("cell_type") for c in cells}
    assert "code" in types and "markdown" in types


@pytest.mark.parametrize("nb_name", NOTEBOOKS)
def test_notebook_mentions_scenario_and_no_hardcoded_abs_paths(nb_name: str):
    path = notebooks_dir() / nb_name
    nb = _load_nb(path)
    blob = "\n".join(_cell_source(c) for c in nb.get("cells", []))
    # Machine-specific absolute paths must not be hardcoded in student notebooks.
    assert "/Users/" not in blob
    assert "C:\\\\" not in blob and "C:/" not in blob
    # Scenario key or load helper present
    assert any(
        token in blob
        for token in (
            "load_scenario",
            "SCENARIO_A",
            "real/jobs",
            "ihdp_medium",
            "real/ihdp",
        )
    ), f"{nb_name}: missing data-loading markers"


def test_notebook_optional_nbformat_read():
    """If nbformat is installed, validate via that API too; else skip gracefully."""
    nbformat = pytest.importorskip("nbformat")
    path = notebooks_dir() / NOTEBOOKS[0]
    nb = nbformat.read(path, as_version=4)
    assert len(nb.cells) >= 1


# ---------------------------------------------------------------------------
# 3. Critical pure-Python paths (offline datasets)
# ---------------------------------------------------------------------------


def test_critical_path_a1_identification():
    from lib.data_io import assert_no_truth_columns, load_scenario
    from lib.identification import (
        diff_in_means,
        fit_propensity,
        ols_ate,
        overlap_diagnostics,
        post_double_selection_ate,
    )

    b = load_scenario(SCENARIO_A1)
    assert_no_truth_columns(b.train)
    y, t, X = b.ytx("train")
    dim = diff_in_means(y, t)
    ols = ols_ate(y, t, X)
    pds = post_double_selection_ate(y, t, X, random_state=RANDOM_STATE)
    _, e = fit_propensity(X, t, random_state=RANDOM_STATE)
    diag = overlap_diagnostics(e, t)
    assert np.isfinite(dim) and np.isfinite(ols)
    assert np.isfinite(float(pds["ate"]))
    assert 0.0 < diag["frac_strictly_interior"] <= 1.0


def test_critical_path_a2_dml_sklearn():
    from lib.data_io import load_scenario
    from lib.dml_utils import fit_plr
    from lib.metrics import ate_absolute_error

    b = load_scenario(SCENARIO_A2)
    y, t, X = b.ytx("train")
    # Force sklearn backend for offline smoke (no econml required).
    _, res = fit_plr(
        y,
        t,
        X,
        backend="sklearn",
        model_y_kind="lasso",
        model_t_kind="lasso",
        n_folds=3,
        random_state=RANDOM_STATE,
    )
    ate_true = float(b.meta.get("ate_true", 3.97))
    ae = ate_absolute_error(res.ate, ate_true)
    assert np.isfinite(res.ate)
    # Generous smoke ceiling (grader uses 0.5; smoke allows training noise).
    assert ae < 2.0, f"DML AE={ae} too large for smoke"


def test_critical_path_a3_t_learner_pehe():
    from lib.cate_utils import fit_t_learner, placebo_permute_treatment
    from lib.data_io import load_scenario, load_truth
    from lib.metrics import pehe

    b = load_scenario(SCENARIO_A3)
    y, t, X = b.ytx("train")
    y_te, _, X_te = b.ytx("test")
    model = fit_t_learner(y, t, X, random_state=RANDOM_STATE)
    tau_hat = model.predict(X_te)
    truth = load_truth(SCENARIO_A3, "test")
    pehe_val = pehe(tau_hat, truth["tau"].to_numpy())
    assert pehe_val < 8.0
    placebo = placebo_permute_treatment(
        y, t, X, learner="t", n_perm=1, random_state=RANDOM_STATE
    )
    assert abs(float(placebo["ate_placebo"])) < 1.5  # soft smoke bound


def test_critical_path_a4_policy_budget():
    from lib.data_io import load_scenario
    from lib.policy_utils import make_threshold_policy, random_policy

    b = load_scenario(SCENARIO_A4)
    # Use a simple synthetic score correlated with nothing special: row index noise
    rng = np.random.RandomState(RANDOM_STATE)
    n = len(b.test)
    scores = rng.normal(size=n)
    B = 0.20
    pol = make_threshold_policy(scores, budget_fraction=B, mode="topk")
    out = pol.predict(scores=scores)
    rate = float(np.mean(out["decision"]))
    assert abs(rate - B) <= 0.02 + 1e-9
    assert set(np.unique(out["decision"])).issubset({0, 1})
    rand = random_policy(n, B, random_state=RANDOM_STATE)
    assert abs(float(np.mean(rand)) - B) <= 0.02 + 1e-9


# ---------------------------------------------------------------------------
# 4. Serie B artifacts (A2 → B1, A4 → B3)
# ---------------------------------------------------------------------------


def test_a2_artifacts_for_b1():
    art = artifacts_dir("A2")
    joblib_path = art / "dml_estimator.joblib"
    fl_path = art / "feature_list.json"
    meta_path = art / "training_meta.json"
    assert joblib_path.is_file(), "Missing A2 joblib (export via scripts/export_a2_artifacts.py)"
    assert fl_path.is_file()
    assert meta_path.is_file()

    from lib.dml_utils import load_dml_artifact

    est = load_dml_artifact(joblib_path)
    assert hasattr(est, "const_marginal_ate") or hasattr(est, "ate") or hasattr(
        est, "predict"
    )
    if hasattr(est, "const_marginal_ate"):
        ate = float(np.asarray(est.const_marginal_ate()).reshape(-1)[0])
    elif hasattr(est, "ate"):
        ate = float(np.asarray(est.ate()).reshape(-1)[0])
    else:
        ate = float(np.mean(est.predict(np.zeros((3, 25)))))
    assert np.isfinite(ate)

    with fl_path.open("r", encoding="utf-8") as f:
        fl = json.load(f)
    assert isinstance(fl, list) and len(fl) == 25

    with meta_path.open("r", encoding="utf-8") as f:
        meta = json.load(f)
    for key in ("scenario_id", "seed", "ate_point_estimate", "estimand"):
        assert key in meta
    # Prefer repo-relative package_root if present
    if "package_root" in meta:
        pr = str(meta["package_root"])
        assert not pr.startswith("/Users/"), "package_root must not be machine-absolute"


def test_a4_artifacts_for_b3():
    art = artifacts_dir("A4")
    policy_path = art / "policy.joblib"
    card_path = art / "policy_card.md"
    assert policy_path.is_file(), "Missing A4 policy.joblib (export via scripts/export_a4_artifacts.py)"
    assert card_path.is_file() and card_path.stat().st_size > 100

    from lib.data_io import load_scenario
    from lib.policy_utils import load_policy

    pol = load_policy(policy_path)
    b = load_scenario(SCENARIO_A4)
    _, _, X = b.ytx("test")
    smoke = pol.predict(X=X.iloc[:3])
    assert "decision" in smoke and "uplift_score" in smoke
    assert len(smoke["decision"]) == 3
    assert set(np.unique(smoke["decision"])).issubset({0, 1})

    meta_path = art / "export_meta.json"
    if meta_path.is_file():
        with meta_path.open("r", encoding="utf-8") as f:
            meta = json.load(f)
        for key in ("policy_path", "scenario_id"):
            if key in meta and isinstance(meta[key], str):
                assert not str(meta[key]).startswith("/Users/")


def test_a3_scores_artifact_optional_but_preferred():
    scores = artifacts_dir("A3") / "cate_scores_test.csv"
    if not scores.is_file():
        pytest.skip("A3 cate_scores_test.csv not exported yet (optional for smoke)")
    import pandas as pd

    df = pd.read_csv(scores)
    assert "method_selected" in df.columns
    tau_cols = [c for c in df.columns if str(c).startswith("tau_hat_")]
    assert len(tau_cols) >= 1


# ---------------------------------------------------------------------------
# 5. Autograder CLI entry points (no kernel)
# ---------------------------------------------------------------------------


@pytest.mark.parametrize("script", AUTOGRADERS)
def test_autograder_has_cli_main(script: str):
    path = package_root() / "autograder" / script
    assert path.is_file()
    # Load as module via importlib from file path semantics: exec source check
    src = path.read_text(encoding="utf-8")
    assert "def main(" in src
    assert 'if __name__ == "__main__"' in src
    assert "argparse" in src


@pytest.mark.parametrize("script", AUTOGRADERS)
def test_autograder_cli_help(script: str):
    """Each grader answers --help without needing notebook kernel state."""
    path = package_root() / "autograder" / script
    proc = subprocess.run(
        [sys.executable, str(path), "--help"],
        cwd=str(package_root()),
        capture_output=True,
        text=True,
        timeout=60,
        env={**os.environ, "PYTHONPATH": str(package_root())},
    )
    assert proc.returncode == 0, proc.stderr
    assert "usage" in proc.stdout.lower() or "usage" in proc.stderr.lower()


def test_expected_ranges_yaml_loads():
    import yaml

    path = package_root() / "autograder" / "expected_ranges.yaml"
    assert path.is_file()
    with path.open("r", encoding="utf-8") as f:
        cfg = yaml.safe_load(f)
    for key in ("a1_jobs", "a2_ihdp_medium", "a3_ihdp", "a4_ihdp"):
        assert key in cfg


# ---------------------------------------------------------------------------
# 6. Optional nbconvert execute (heavy; opt-in)
# ---------------------------------------------------------------------------


@pytest.mark.skipif(
    os.environ.get("SERIE_A_NBCONVERT", "") not in ("1", "true", "TRUE", "yes"),
    reason="Set SERIE_A_NBCONVERT=1 to run full notebook execution (heavy)",
)
@pytest.mark.parametrize("nb_name", NOTEBOOKS)
def test_nbconvert_execute_opt_in(nb_name: str):
    pytest.importorskip("nbconvert")
    path = notebooks_dir() / nb_name
    proc = subprocess.run(
        [
            sys.executable,
            "-m",
            "nbconvert",
            "--to",
            "notebook",
            "--execute",
            "--ExecutePreprocessor.timeout=600",
            "--stdout",
            str(path),
        ],
        cwd=str(package_root()),
        capture_output=True,
        text=True,
        timeout=900,
        env={**os.environ, "PYTHONPATH": str(package_root())},
    )
    assert proc.returncode == 0, proc.stderr[-2000:]
