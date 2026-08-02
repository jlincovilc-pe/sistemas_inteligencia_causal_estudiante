"""CATE meta-learners and causal forest wrappers for Notebook A3.

Implements didactic S/T/X/R-learners with sklearn base learners and an
optional EconML ``CausalForestDML``. Includes a placebo permutation check.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Sequence, Tuple, Union

import numpy as np
import pandas as pd
from sklearn.base import BaseEstimator, clone
from sklearn.ensemble import (
    GradientBoostingRegressor,
    RandomForestRegressor,
)
from sklearn.linear_model import LassoCV
from sklearn.model_selection import KFold

from .paths import RANDOM_STATE

ArrayLike = Union[Sequence[float], np.ndarray, pd.Series]
MatrixLike = Union[pd.DataFrame, np.ndarray]


def _as_1d(a: ArrayLike) -> np.ndarray:
    return np.asarray(a, dtype=float).reshape(-1)


def _as_X(X: MatrixLike) -> np.ndarray:
    arr = np.asarray(X, dtype=float)
    if arr.ndim == 1:
        arr = arr.reshape(-1, 1)
    return arr


def default_regressor(
    kind: str = "rf",
    random_state: int = RANDOM_STATE,
) -> BaseEstimator:
    kind = kind.lower()
    if kind in ("rf", "forest"):
        return RandomForestRegressor(
            n_estimators=100,
            min_samples_leaf=5,
            random_state=random_state,
            n_jobs=-1,
        )
    if kind in ("gbr", "gbm", "boosting"):
        return GradientBoostingRegressor(random_state=random_state)
    if kind == "lasso":
        return LassoCV(cv=5, random_state=random_state, max_iter=5000)
    raise ValueError(f"Unknown regressor kind: {kind!r}")


@dataclass
class CATEModel:
    """Fitted CATE estimator with a uniform ``predict`` interface."""

    name: str
    _predict_fn: Any = field(repr=False)
    extra: Dict[str, Any] = field(default_factory=dict)

    def predict(self, X: MatrixLike) -> np.ndarray:
        """Return CATE scores ``tau_hat(x)`` for each row of ``X``."""
        X_arr = _as_X(X)
        out = np.asarray(self._predict_fn(X_arr), dtype=float).reshape(-1)
        if out.shape[0] != X_arr.shape[0]:
            raise RuntimeError(
                f"{self.name}: predict length {out.shape[0]} != n={X_arr.shape[0]}"
            )
        return out


def fit_s_learner(
    y: ArrayLike,
    t: ArrayLike,
    X: MatrixLike,
    *,
    base_estimator: Optional[BaseEstimator] = None,
    random_state: int = RANDOM_STATE,
) -> CATEModel:
    """S-learner: single model μ(x, t); CATE = μ(x,1) − μ(x,0)."""
    y_a, t_a, X_arr = _as_1d(y), _as_1d(t), _as_X(X)
    # Use `is None` — unfitted ensembles are falsy via __len__ in some sklearn versions.
    base = (
        default_regressor(random_state=random_state)
        if base_estimator is None
        else base_estimator
    )
    model = clone(base)
    design = np.column_stack([X_arr, t_a])
    model.fit(design, y_a)

    def _predict(X_new: np.ndarray) -> np.ndarray:
        n = X_new.shape[0]
        ones = np.ones(n)
        zeros = np.zeros(n)
        mu1 = model.predict(np.column_stack([X_new, ones]))
        mu0 = model.predict(np.column_stack([X_new, zeros]))
        return mu1 - mu0

    return CATEModel(name="s_learner", _predict_fn=_predict, extra={"model": model})


def fit_t_learner(
    y: ArrayLike,
    t: ArrayLike,
    X: MatrixLike,
    *,
    base_estimator: Optional[BaseEstimator] = None,
    random_state: int = RANDOM_STATE,
) -> CATEModel:
    """T-learner: separate μ1(x), μ0(x); CATE = μ1 − μ0."""
    y_a, t_a, X_arr = _as_1d(y), _as_1d(t), _as_X(X)
    mask1 = t_a == 1
    mask0 = t_a == 0
    if not mask1.any() or not mask0.any():
        raise ValueError("T-learner requires both treatment arms")

    # Use `is None` — unfitted ensembles are falsy via __len__ in some sklearn versions.
    if base_estimator is None:
        m1 = clone(default_regressor(random_state=random_state))
        m0 = clone(default_regressor(random_state=random_state + 1))
    else:
        m1 = clone(base_estimator)
        m0 = clone(base_estimator)
    m1.fit(X_arr[mask1], y_a[mask1])
    m0.fit(X_arr[mask0], y_a[mask0])

    def _predict(X_new: np.ndarray) -> np.ndarray:
        return m1.predict(X_new) - m0.predict(X_new)

    return CATEModel(
        name="t_learner",
        _predict_fn=_predict,
        extra={"model_1": m1, "model_0": m0},
    )


def fit_x_learner(
    y: ArrayLike,
    t: ArrayLike,
    X: MatrixLike,
    *,
    base_estimator: Optional[BaseEstimator] = None,
    propensity_estimator: Optional[BaseEstimator] = None,
    random_state: int = RANDOM_STATE,
) -> CATEModel:
    """X-learner (Kunzel et al.): imputed effects + propensity weighting."""
    from sklearn.linear_model import LogisticRegression

    y_a, t_a, X_arr = _as_1d(y), _as_1d(t), _as_X(X)
    mask1 = t_a == 1
    mask0 = t_a == 0
    if not mask1.any() or not mask0.any():
        raise ValueError("X-learner requires both treatment arms")

    # Use `is None` — unfitted ensembles are falsy via __len__ in some sklearn versions.
    base = (
        default_regressor(random_state=random_state)
        if base_estimator is None
        else base_estimator
    )
    m1 = clone(base)
    m0 = clone(base)
    m1.fit(X_arr[mask1], y_a[mask1])
    m0.fit(X_arr[mask0], y_a[mask0])

    # Imputed treatment effects
    d1 = y_a[mask1] - m0.predict(X_arr[mask1])
    d0 = m1.predict(X_arr[mask0]) - y_a[mask0]

    tau1 = clone(base)
    tau0 = clone(base)
    tau1.fit(X_arr[mask1], d1)
    tau0.fit(X_arr[mask0], d0)

    if propensity_estimator is None:
        prop = LogisticRegression(max_iter=1000, random_state=random_state)
    else:
        prop = clone(propensity_estimator)
    prop.fit(X_arr, t_a.astype(int))

    def _predict(X_new: np.ndarray) -> np.ndarray:
        if hasattr(prop, "predict_proba"):
            e = prop.predict_proba(X_new)[:, 1]
        else:
            e = np.asarray(prop.predict(X_new), dtype=float).reshape(-1)
        e = np.clip(e, 1e-6, 1 - 1e-6)
        return e * tau0.predict(X_new) + (1.0 - e) * tau1.predict(X_new)

    return CATEModel(
        name="x_learner",
        _predict_fn=_predict,
        extra={"tau1": tau1, "tau0": tau0, "propensity": prop},
    )


def fit_r_learner(
    y: ArrayLike,
    t: ArrayLike,
    X: MatrixLike,
    *,
    model_y: Optional[BaseEstimator] = None,
    model_t: Optional[BaseEstimator] = None,
    model_tau: Optional[BaseEstimator] = None,
    n_folds: int = 5,
    random_state: int = RANDOM_STATE,
) -> CATEModel:
    """Simplified R-learner: residual-on-residual with cross-fitting.

    Solves a weighted regression of (Y − m̂(x)) on (T − ê(x)) for τ(x).
    """
    from sklearn.linear_model import LogisticRegression

    y_a, t_a, X_arr = _as_1d(y), _as_1d(t), _as_X(X)
    n = y_a.shape[0]
    # Use `is None` — unfitted ensembles are falsy via __len__ in some sklearn versions.
    my = clone(
        default_regressor(random_state=random_state)
        if model_y is None
        else model_y
    )
    # Propensity / E[T|X]
    if model_t is None:
        mt: BaseEstimator = LogisticRegression(
            max_iter=1000, random_state=random_state
        )
    else:
        mt = clone(model_t)

    y_hat = np.zeros(n)
    t_hat = np.zeros(n)
    kf = KFold(n_splits=n_folds, shuffle=True, random_state=random_state)
    for tr, te in kf.split(X_arr):
        my_f = clone(my)
        mt_f = clone(mt)
        my_f.fit(X_arr[tr], y_a[tr])
        mt_f.fit(X_arr[tr], t_a[tr].astype(int) if hasattr(mt_f, "predict_proba") else t_a[tr])
        y_hat[te] = my_f.predict(X_arr[te])
        if hasattr(mt_f, "predict_proba"):
            t_hat[te] = mt_f.predict_proba(X_arr[te])[:, 1]
        else:
            t_hat[te] = mt_f.predict(X_arr[te])

    y_res = y_a - y_hat
    t_res = t_a - t_hat
    # Avoid near-zero denominators: use residual product weights for RF/GBM
    # Fit τ on X predicting y_res / t_res with sample_weight t_res^2 (Robinson)
    tau_model = clone(
        default_regressor(kind="rf", random_state=random_state)
        if model_tau is None
        else model_tau
    )
    # Pseudo-outcome R-learner form: target = y_res / t_res, weight = t_res^2
    eps = 1e-6
    safe = np.abs(t_res) > eps
    if safe.sum() < 10:
        # fallback: unweighted residual regression tau * t_res ≈ y_res via OLS on X*t_res
        design = X_arr * t_res.reshape(-1, 1)
        from sklearn.linear_model import LinearRegression

        lin = LinearRegression()
        lin.fit(design, y_res)

        def _predict_lin(X_new: np.ndarray) -> np.ndarray:
            # approximate constant tau from linear form is not ideal; use mean
            return np.full(X_new.shape[0], float(np.mean(y_res / np.where(np.abs(t_res) < eps, np.nan, t_res))), dtype=float)

        return CATEModel(name="r_learner", _predict_fn=_predict_lin, extra={"fallback": True})

    target = np.zeros(n)
    target[safe] = y_res[safe] / t_res[safe]
    weights = t_res ** 2
    try:
        tau_model.fit(X_arr[safe], target[safe], sample_weight=weights[safe])
    except TypeError:
        tau_model.fit(X_arr[safe], target[safe])

    def _predict(X_new: np.ndarray) -> np.ndarray:
        return np.asarray(tau_model.predict(X_new), dtype=float).reshape(-1)

    return CATEModel(
        name="r_learner",
        _predict_fn=_predict,
        extra={"tau_model": tau_model, "n_folds": n_folds},
    )


def fit_causal_forest(
    y: ArrayLike,
    t: ArrayLike,
    X: MatrixLike,
    *,
    n_estimators: int = 100,
    min_samples_leaf: int = 10,
    cv: int = 3,
    random_state: int = RANDOM_STATE,
) -> CATEModel:
    """EconML CausalForestDML wrapper; falls back to T-learner RF if missing.

    Smoke / CPU-friendly defaults: ``n_estimators=100``, ``cv=3``. For a fuller
    classroom run, raise ``n_estimators`` (e.g. 200–400) if wall-time allows.
    """
    y_a, t_a, X_arr = _as_1d(y), _as_1d(t), _as_X(X)
    try:
        from econml.dml import CausalForestDML  # type: ignore
        from sklearn.ensemble import RandomForestClassifier

        est = CausalForestDML(
            model_y=RandomForestRegressor(
                n_estimators=50,
                min_samples_leaf=5,
                random_state=random_state,
                n_jobs=-1,
            ),
            model_t=RandomForestClassifier(
                n_estimators=50,
                min_samples_leaf=5,
                random_state=random_state,
                n_jobs=-1,
            ),
            n_estimators=n_estimators,
            min_samples_leaf=min_samples_leaf,
            cv=cv,
            random_state=random_state,
            discrete_treatment=True,
        )
        est.fit(y_a, t_a, X=X_arr, W=None)

        def _predict(X_new: np.ndarray) -> np.ndarray:
            return np.asarray(est.effect(X_new), dtype=float).reshape(-1)

        return CATEModel(
            name="causal_forest",
            _predict_fn=_predict,
            extra={"estimator": est, "backend": "econml"},
        )
    except ImportError:
        # Transparent fallback: T-learner RF (documented in extra["backend"]).
        # Use module-level RandomForestRegressor (do not re-import inside try).
        model = fit_t_learner(
            y_a,
            t_a,
            X_arr,
            base_estimator=RandomForestRegressor(
                n_estimators=n_estimators,
                min_samples_leaf=min_samples_leaf,
                random_state=random_state,
                n_jobs=-1,
            ),
            random_state=random_state,
        )
        model.name = "causal_forest_fallback_t_learner"
        model.extra["backend"] = "sklearn_fallback"
        model.extra["note"] = (
            "econml not installed; causal_forest uses T-learner RF fallback"
        )
        return model


def fit_meta_learners(
    y: ArrayLike,
    t: ArrayLike,
    X: MatrixLike,
    *,
    learners: Optional[Sequence[str]] = None,
    random_state: int = RANDOM_STATE,
    include_causal_forest: bool = True,
) -> Dict[str, CATEModel]:
    """Fit a dictionary of named CATE models."""
    names = list(learners) if learners is not None else ["s", "t", "x", "r"]
    out: Dict[str, CATEModel] = {}
    mapping = {
        "s": fit_s_learner,
        "s_learner": fit_s_learner,
        "t": fit_t_learner,
        "t_learner": fit_t_learner,
        "x": fit_x_learner,
        "x_learner": fit_x_learner,
        "r": fit_r_learner,
        "r_learner": fit_r_learner,
    }
    for name in names:
        key = name.lower()
        if key not in mapping:
            raise ValueError(f"Unknown learner {name!r}")
        model = mapping[key](y, t, X, random_state=random_state)
        out[model.name] = model
    if include_causal_forest:
        cf = fit_causal_forest(y, t, X, random_state=random_state)
        out[cf.name] = cf
    return out


def predict_cate_table(
    models: Dict[str, CATEModel],
    X: MatrixLike,
    row_ids: Optional[ArrayLike] = None,
) -> pd.DataFrame:
    """Stack CATE predictions as columns ``tau_hat_<name>``."""
    X_arr = _as_X(X)
    data: Dict[str, Any] = {}
    if row_ids is not None:
        data["row_id"] = _as_1d(row_ids)
    for name, model in models.items():
        col = f"tau_hat_{name}"
        data[col] = model.predict(X_arr)
    return pd.DataFrame(data)


def placebo_permute_treatment(
    y: ArrayLike,
    t: ArrayLike,
    X: MatrixLike,
    *,
    learner: str = "t",
    n_perm: int = 1,
    random_state: int = RANDOM_STATE,
) -> Dict[str, Any]:
    """Placebo test: permute treatment and re-estimate CATE/ATE.

    Under a correct procedure with no true signal after shuffle, the mean
    of ``tau_hat`` should be near zero.

    Returns
    -------
    dict
        ``ate_placebo``, ``mean_abs_tau``, ``tau_hat`` (last permutation),
        and optionally list of ATEs if ``n_perm > 1``.
    """
    y_a, t_a, X_arr = _as_1d(y), _as_1d(t), _as_X(X)
    rng = np.random.RandomState(random_state)
    ates: List[float] = []
    last_tau: Optional[np.ndarray] = None

    fit_fn = {
        "s": fit_s_learner,
        "t": fit_t_learner,
        "x": fit_x_learner,
        "r": fit_r_learner,
    }.get(learner.lower())
    if fit_fn is None:
        raise ValueError(f"learner must be s/t/x/r, got {learner!r}")

    for i in range(n_perm):
        t_perm = rng.permutation(t_a)
        model = fit_fn(y_a, t_perm, X_arr, random_state=random_state + i)
        tau = model.predict(X_arr)
        last_tau = tau
        ates.append(float(np.mean(tau)))

    return {
        "ate_placebo": float(ates[-1]),
        "mean_abs_tau": float(np.mean(np.abs(last_tau))) if last_tau is not None else float("nan"),
        "ates": ates,
        "tau_hat": last_tau,
        "learner": learner,
        "n_perm": n_perm,
    }


# ---------------------------------------------------------------------------
# Artifact export for A3 → A4 (and optional B3 via A4)
# ---------------------------------------------------------------------------

DEFAULT_METHOD_SELECTED = "t_learner"


def export_a3_artifacts(
    scenario: str = "real/ihdp",
    out_dir: Optional[Union[str, Path]] = None,
    *,
    method_selected: str = DEFAULT_METHOD_SELECTED,
    random_state: int = RANDOM_STATE,
    include_causal_forest: bool = True,
    n_estimators_cf: int = 100,
    save_plots: bool = True,
) -> Dict[str, Any]:
    """Fit meta-learners on train, score test, write A3 artifacts.

    Writes under ``artifacts/A3/`` (by default)::

        cate_scores_test.csv   # row_id, tau_hat_<method>..., method_selected
        qini_plot.png          # Qini for method_selected on validation
        cate_comparison.png    # overlaid CATE histograms on test

    Parameters
    ----------
    scenario:
        Scenario key (default ``real/ihdp``).
    out_dir:
        Output directory; defaults to ``artifacts/A3`` under package root.
    method_selected:
        Official course choice for A4 (default ``t_learner``).
    save_plots:
        If True, write PNG figures (requires matplotlib).

    Returns
    -------
    dict
        Paths and summary stats (no truth-based metrics).
    """
    from pathlib import Path

    from .data_io import load_scenario
    from .metrics import qini_auc, qini_curve
    from .paths import artifacts_dir, ensure_dir

    bundle = load_scenario(scenario)
    y_tr, t_tr, X_tr = bundle.ytx("train")
    y_va, t_va, X_va = bundle.ytx("validation")
    _, _, X_te = bundle.ytx("test")

    models = fit_meta_learners(
        y_tr,
        t_tr,
        X_tr,
        random_state=random_state,
        include_causal_forest=include_causal_forest,
    )
    # Optional: re-fit CF with explicit n_estimators if present
    if include_causal_forest and "causal_forest" in models:
        models["causal_forest"] = fit_causal_forest(
            y_tr,
            t_tr,
            X_tr,
            n_estimators=n_estimators_cf,
            random_state=random_state,
        )
    elif include_causal_forest:
        # fallback name may differ
        for k in list(models.keys()):
            if k.startswith("causal_forest"):
                models[k] = fit_causal_forest(
                    y_tr,
                    t_tr,
                    X_tr,
                    n_estimators=n_estimators_cf,
                    random_state=random_state,
                )

    row_ids = (
        bundle.test["row_id"].to_numpy()
        if "row_id" in bundle.test.columns
        else np.arange(len(bundle.test))
    )
    scores = predict_cate_table(models, X_te, row_ids=row_ids)

    # Resolve method_selected column
    col_sel = f"tau_hat_{method_selected}"
    if col_sel not in scores.columns:
        # try first tau column if preferred method missing
        tau_cols = [c for c in scores.columns if c.startswith("tau_hat_")]
        if not tau_cols:
            raise RuntimeError("No CATE columns produced")
        # prefer t_learner-like
        preferred = [c for c in tau_cols if "t_learner" in c]
        col_sel = preferred[0] if preferred else tau_cols[0]
        method_selected = col_sel.replace("tau_hat_", "", 1)
    scores["method_selected"] = method_selected

    out = Path(out_dir) if out_dir is not None else artifacts_dir("A3")
    ensure_dir(out)
    scores_path = out / "cate_scores_test.csv"
    scores.to_csv(scores_path, index=False)

    # Qini on validation with selected method (observed only)
    model_sel = models.get(method_selected)
    if model_sel is None:
        # fuzzy match
        for name, m in models.items():
            if name == method_selected or method_selected in name:
                model_sel = m
                break
    if model_sel is None:
        model_sel = next(iter(models.values()))

    score_va = model_sel.predict(X_va)
    curve = qini_curve(y_va, t_va, score_va)
    q_auc = qini_auc(curve)

    qini_path = out / "qini_plot.png"
    cate_path = out / "cate_comparison.png"
    if save_plots:
        try:
            import matplotlib

            matplotlib.use("Agg")
            import matplotlib.pyplot as plt

            from .plotting import plot_cate_distributions, plot_qini

            # Qini
            fig1, ax1 = plt.subplots(figsize=(7.0, 4.5))
            plot_qini(
                curve,
                ax=ax1,
                title=f"Qini curve (val) — {method_selected}",
            )
            fig1.tight_layout()
            fig1.savefig(qini_path, dpi=120)
            plt.close(fig1)

            # CATE comparison on test
            cate_dict = {
                name: m.predict(X_te) for name, m in models.items()
            }
            fig2, ax2 = plt.subplots(figsize=(8.0, 5.0))
            plot_cate_distributions(
                cate_dict,
                ax=ax2,
                title="CATE distributions on test (observed fit on train)",
            )
            fig2.tight_layout()
            fig2.savefig(cate_path, dpi=120)
            plt.close(fig2)
        except Exception as exc:  # pragma: no cover
            qini_path = None  # type: ignore
            cate_path = None  # type: ignore
            plot_error = str(exc)
        else:
            plot_error = None
    else:
        plot_error = "save_plots=False"

    means = {
        name: float(np.mean(m.predict(X_te))) for name, m in models.items()
    }
    placebo = placebo_permute_treatment(
        y_tr, t_tr, X_tr, learner="t", random_state=random_state
    )

    return {
        "scores_path": str(scores_path),
        "qini_path": str(qini_path) if qini_path else None,
        "cate_comparison_path": str(cate_path) if cate_path else None,
        "method_selected": method_selected,
        "model_names": list(models.keys()),
        "mean_tau_test": means,
        "qini_auc_val": float(q_auc),
        "placebo_ate": float(placebo["ate_placebo"]),
        "placebo_mean_abs_tau": float(placebo["mean_abs_tau"]),
        "n_train": int(len(y_tr)),
        "n_test": int(len(X_te)),
        "scenario": scenario,
        "scenario_id": bundle.scenario_id,
        "random_state": random_state,
        "plot_error": plot_error,
        "cf_backend": next(
            (
                m.extra.get("backend")
                for name, m in models.items()
                if "causal_forest" in name
            ),
            None,
        ),
    }
