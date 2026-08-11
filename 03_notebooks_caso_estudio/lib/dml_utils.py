"""Double Machine Learning helpers (PLR) for Notebook A2.

Prefers EconML ``LinearDML`` when available, with optional DoubleML and a
sklearn-only cross-fitting fallback so smoke tests remain kernel-less.
"""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional, Sequence, Tuple, Union

import numpy as np
import pandas as pd
from joblib import dump, load
from sklearn.base import BaseEstimator, clone
from sklearn.ensemble import (
    GradientBoostingClassifier,
    GradientBoostingRegressor,
    HistGradientBoostingClassifier,
    HistGradientBoostingRegressor,
)
from sklearn.linear_model import LassoCV, LogisticRegressionCV
from sklearn.model_selection import KFold

from .paths import RANDOM_STATE, ensure_dir

ArrayLike = Union[Sequence[float], np.ndarray, pd.Series]
MatrixLike = Union[pd.DataFrame, np.ndarray]


def _as_y(a: ArrayLike) -> np.ndarray:
    return np.asarray(a, dtype=float).reshape(-1)


def _as_t(a: ArrayLike) -> np.ndarray:
    return np.asarray(a, dtype=float).reshape(-1)


def _as_X(X: MatrixLike) -> Tuple[np.ndarray, Optional[List[str]]]:
    if isinstance(X, pd.DataFrame):
        return X.to_numpy(dtype=float), list(X.columns)
    arr = np.asarray(X, dtype=float)
    if arr.ndim == 1:
        arr = arr.reshape(-1, 1)
    return arr, None


def default_model_y(kind: str = "lasso", random_state: int = RANDOM_STATE):
    """Nuisance model for E[Y|X]."""
    kind = kind.lower()
    if kind == "lasso":
        return LassoCV(cv=5, random_state=random_state, max_iter=5000)
    if kind in ("gbr", "gbm", "boosting"):
        return GradientBoostingRegressor(random_state=random_state)
    if kind in ("hgb", "hist"):
        return HistGradientBoostingRegressor(random_state=random_state)
    raise ValueError(f"Unknown model_y kind: {kind!r}")


def default_model_t(kind: str = "lasso", random_state: int = RANDOM_STATE):
    """Nuisance model for E[T|X] (regression or classifier for binary T)."""
    kind = kind.lower()
    if kind == "lasso":
        # Linear propensity via continuous regression works for PLR residualization.
        return LassoCV(cv=5, random_state=random_state, max_iter=5000)
    if kind in ("logistic", "logit"):
        return LogisticRegressionCV(
            cv=5, max_iter=1000, random_state=random_state
        )
    if kind in ("gbr", "gbm", "boosting"):
        return GradientBoostingClassifier(random_state=random_state)
    if kind in ("hgb", "hist"):
        return HistGradientBoostingClassifier(random_state=random_state)
    raise ValueError(f"Unknown model_t kind: {kind!r}")


@dataclass
class DMLResult:
    """Container for PLR / DML estimation output."""

    ate: float
    se: Optional[float] = None
    ci_low: Optional[float] = None
    ci_high: Optional[float] = None
    method: str = "plr"
    n: int = 0
    n_folds: int = 0
    y_residual: Optional[np.ndarray] = field(default=None, repr=False)
    t_residual: Optional[np.ndarray] = field(default=None, repr=False)
    extra: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        d = {
            "ate": self.ate,
            "se": self.se,
            "ci_low": self.ci_low,
            "ci_high": self.ci_high,
            "method": self.method,
            "n": self.n,
            "n_folds": self.n_folds,
        }
        d.update(self.extra)
        return d


def cross_fit_residuals(
    y: ArrayLike,
    t: ArrayLike,
    X: MatrixLike,
    model_y: BaseEstimator,
    model_t: BaseEstimator,
    *,
    n_folds: int = 5,
    random_state: int = RANDOM_STATE,
) -> Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    """K-fold cross-fitting: out-of-fold residuals for Y and T.

    Returns
    -------
    y_res, t_res, y_hat, t_hat
        All length-n arrays. Fold predictions never use the same fold's labels
        for training (no residual leakage across folds).
    """
    y_a = _as_y(y)
    t_a = _as_t(t)
    X_arr, _ = _as_X(X)
    n = y_a.shape[0]
    if not (t_a.shape[0] == n and X_arr.shape[0] == n):
        raise ValueError("y, t, X must share the same number of rows")

    y_hat = np.zeros(n, dtype=float)
    t_hat = np.zeros(n, dtype=float)
    kf = KFold(n_splits=n_folds, shuffle=True, random_state=random_state)

    for train_idx, test_idx in kf.split(X_arr):
        my = clone(model_y)
        mt = clone(model_t)
        my.fit(X_arr[train_idx], y_a[train_idx])
        mt.fit(X_arr[train_idx], t_a[train_idx])
        y_hat[test_idx] = np.asarray(my.predict(X_arr[test_idx]), dtype=float).reshape(
            -1
        )
        # Classifiers expose predict_proba
        if hasattr(mt, "predict_proba"):
            proba = mt.predict_proba(X_arr[test_idx])
            # binary: column 1; if single class edge-case, fall back
            if proba.ndim == 2 and proba.shape[1] >= 2:
                t_hat[test_idx] = proba[:, 1]
            else:
                t_hat[test_idx] = proba.reshape(-1)
        else:
            t_hat[test_idx] = np.asarray(
                mt.predict(X_arr[test_idx]), dtype=float
            ).reshape(-1)

    y_res = y_a - y_hat
    t_res = t_a - t_hat
    return y_res, t_res, y_hat, t_hat


def plr_from_residuals(
    y_res: np.ndarray,
    t_res: np.ndarray,
) -> DMLResult:
    """Final PLR stage: OLS of Y~ on T~ through origin (partialling-out)."""
    y_r = np.asarray(y_res, dtype=float).reshape(-1)
    t_r = np.asarray(t_res, dtype=float).reshape(-1)
    denom = float(np.dot(t_r, t_r))
    if denom <= 0:
        raise ValueError("Degenerate T residual; cannot estimate PLR theta")
    theta = float(np.dot(t_r, y_r) / denom)
    # Heteroskedasticity-robust SE (HC0-like for single coefficient)
    resid = y_r - theta * t_r
    n = y_r.size
    # Var(theta) ≈ (sum t_i^2 e_i^2) / (sum t_i^2)^2
    var = float(np.sum((t_r ** 2) * (resid ** 2)) / (denom ** 2))
    se = float(np.sqrt(max(var, 0.0)))
    z = 1.96
    return DMLResult(
        ate=theta,
        se=se,
        ci_low=theta - z * se,
        ci_high=theta + z * se,
        method="plr_sklearn_crossfit",
        n=n,
        y_residual=y_r,
        t_residual=t_r,
    )


def fit_plr_sklearn(
    y: ArrayLike,
    t: ArrayLike,
    X: MatrixLike,
    *,
    model_y: Optional[BaseEstimator] = None,
    model_t: Optional[BaseEstimator] = None,
    model_y_kind: str = "lasso",
    model_t_kind: str = "lasso",
    n_folds: int = 5,
    random_state: int = RANDOM_STATE,
) -> DMLResult:
    """PLR with manual cross-fitting (always available; no EconML required)."""
    my = model_y or default_model_y(model_y_kind, random_state=random_state)
    mt = model_t or default_model_t(model_t_kind, random_state=random_state)
    y_res, t_res, y_hat, t_hat = cross_fit_residuals(
        y, t, X, my, mt, n_folds=n_folds, random_state=random_state
    )
    result = plr_from_residuals(y_res, t_res)
    result.n_folds = n_folds
    result.extra["model_y"] = type(my).__name__
    result.extra["model_t"] = type(mt).__name__
    result.extra["y_hat_mean"] = float(np.mean(y_hat))
    result.extra["t_hat_mean"] = float(np.mean(t_hat))
    return result


def neyman_orthogonality_checks(
    y_res: ArrayLike,
    t_res: ArrayLike,
    y_hat: Optional[ArrayLike] = None,
    t_hat: Optional[ArrayLike] = None,
) -> Dict[str, float]:
    """Simple numerical checks for Neyman residual orthogonality.

    Reports correlation between residuals and nuisance predictions when
    available, plus residual means.
    """
    yr = _as_y(y_res)
    tr = _as_t(t_res)
    out: Dict[str, float] = {
        "mean_y_res": float(np.mean(yr)),
        "mean_t_res": float(np.mean(tr)),
        "corr_y_res_t_res": float(np.corrcoef(yr, tr)[0, 1])
        if yr.size > 1
        else float("nan"),
    }
    if y_hat is not None:
        yh = _as_y(y_hat)
        out["corr_y_res_y_hat"] = (
            float(np.corrcoef(yr, yh)[0, 1]) if yr.size > 1 else float("nan")
        )
    if t_hat is not None:
        th = _as_t(t_hat)
        out["corr_t_res_t_hat"] = (
            float(np.corrcoef(tr, th)[0, 1]) if tr.size > 1 else float("nan")
        )
    return out


def fit_plr_econml(
    y: ArrayLike,
    t: ArrayLike,
    X: MatrixLike,
    *,
    model_y: Optional[BaseEstimator] = None,
    model_t: Optional[BaseEstimator] = None,
    model_y_kind: str = "lasso",
    model_t_kind: str = "lasso",
    cv: int = 5,
    random_state: int = RANDOM_STATE,
) -> Tuple[Any, DMLResult]:
    """Fit EconML ``LinearDML`` if installed; raise ImportError otherwise."""
    try:
        from econml.dml import LinearDML
    except ImportError as exc:
        raise ImportError(
            "econml is not installed; use fit_plr_sklearn or install econml"
        ) from exc

    my = model_y or default_model_y(model_y_kind, random_state=random_state)
    mt = model_t or default_model_t(model_t_kind, random_state=random_state)
    y_a = _as_y(y)
    t_a = _as_t(t)
    X_arr, _ = _as_X(X)

    est = LinearDML(
        model_y=my,
        model_t=mt,
        cv=cv,
        random_state=random_state,
    )
    # W=None: all controls in X; discrete_treatment for binary T
    est.fit(y_a, t_a, X=None, W=X_arr)

    ate = float(np.asarray(est.ate(X=None)).reshape(-1)[0]) if hasattr(est, "ate") else float(
        est.const_marginal_ate()
    )
    # Prefer const_marginal_ate for intercept-only
    try:
        ate = float(np.asarray(est.const_marginal_ate()).reshape(-1)[0])
    except Exception:
        pass

    se = None
    ci_low = ci_high = None
    try:
        inf = est.const_marginal_ate_inference()
        # With X=None (intercept-only ATE), econml returns a
        # PopulationSummaryResults, whose stderr/CI live under the
        # "_mean" names (stderr_mean / conf_int_mean), not the
        # per-point NormalInferenceResults names (stderr / conf_int).
        if hasattr(inf, "stderr_mean"):
            se = float(np.asarray(inf.stderr_mean).reshape(-1)[0])
            band = inf.conf_int_mean(alpha=0.05)
        else:
            se = float(np.asarray(inf.stderr).reshape(-1)[0])
            band = inf.conf_int(alpha=0.05)
        # conf_int may be (2,) or nested
        band_arr = np.asarray(band, dtype=float).reshape(-1)
        if band_arr.size >= 2:
            ci_low, ci_high = float(band_arr[0]), float(band_arr[1])
    except Exception:
        pass

    result = DMLResult(
        ate=ate,
        se=se,
        ci_low=ci_low,
        ci_high=ci_high,
        method="econml_LinearDML",
        n=int(y_a.size),
        n_folds=cv,
        extra={
            "model_y": type(my).__name__,
            "model_t": type(mt).__name__,
        },
    )
    return est, result


def _normalize_plr_kwargs(kwargs: Dict[str, Any], *, for_econml: bool) -> Dict[str, Any]:
    """Map ``cv`` / ``n_folds`` aliases so auto-backend fallbacks share kwargs."""
    out = dict(kwargs)
    if for_econml:
        if "n_folds" in out and "cv" not in out:
            out["cv"] = out.pop("n_folds")
        else:
            out.pop("n_folds", None)
    else:
        if "cv" in out and "n_folds" not in out:
            out["n_folds"] = out.pop("cv")
        else:
            out.pop("cv", None)
    return out


def fit_plr(
    y: ArrayLike,
    t: ArrayLike,
    X: MatrixLike,
    *,
    backend: str = "auto",
    **kwargs,
) -> Tuple[Optional[Any], DMLResult]:
    """Fit PLR with backend ``auto`` | ``econml`` | ``sklearn`` | ``doubleml``.

    Returns ``(estimator_or_None, DMLResult)``.
    Accepts either ``cv`` or ``n_folds`` for the number of cross-fit folds.
    """
    backend = backend.lower()
    if backend == "auto":
        try:
            return fit_plr_econml(
                y, t, X, **_normalize_plr_kwargs(kwargs, for_econml=True)
            )
        except ImportError:
            result = fit_plr_sklearn(
                y, t, X, **_normalize_plr_kwargs(kwargs, for_econml=False)
            )
            return None, result
    if backend == "econml":
        return fit_plr_econml(
            y, t, X, **_normalize_plr_kwargs(kwargs, for_econml=True)
        )
    if backend == "sklearn":
        return None, fit_plr_sklearn(
            y, t, X, **_normalize_plr_kwargs(kwargs, for_econml=False)
        )
    if backend == "doubleml":
        return fit_plr_doubleml(
            y, t, X, **_normalize_plr_kwargs(kwargs, for_econml=False)
        )
    raise ValueError(f"Unknown backend {backend!r}")


def fit_plr_doubleml(
    y: ArrayLike,
    t: ArrayLike,
    X: MatrixLike,
    *,
    model_y: Optional[BaseEstimator] = None,
    model_t: Optional[BaseEstimator] = None,
    model_y_kind: str = "lasso",
    model_t_kind: str = "lasso",
    n_folds: int = 5,
    random_state: int = RANDOM_STATE,
) -> Tuple[Any, DMLResult]:
    """Fit DoubleML PLR if ``doubleml`` is installed."""
    try:
        import doubleml as dml
        from sklearn.base import clone as sk_clone
    except ImportError as exc:
        raise ImportError(
            "doubleml is not installed; use fit_plr_sklearn or install doubleml"
        ) from exc

    my = model_y or default_model_y(model_y_kind, random_state=random_state)
    mt = model_t or default_model_t(model_t_kind, random_state=random_state)
    y_a = _as_y(y)
    t_a = _as_t(t)
    X_arr, feat_names = _as_X(X)
    if feat_names is None:
        feat_names = [f"x{i}" for i in range(X_arr.shape[1])]

    df = pd.DataFrame(X_arr, columns=feat_names)
    df["y"] = y_a
    df["t"] = t_a
    dml_data = dml.DoubleMLData(
        df, y_col="y", d_cols="t", x_cols=feat_names
    )
    ml_l = sk_clone(my)
    ml_m = sk_clone(mt)
    plr = dml.DoubleMLPLR(dml_data, ml_l, ml_m, n_folds=n_folds)
    plr.fit()
    ate = float(np.asarray(plr.coef).reshape(-1)[0])
    se = float(np.asarray(plr.se).reshape(-1)[0])
    try:
        ci = plr.confint(level=0.95)
        ci_low = float(np.asarray(ci)[0, 0])
        ci_high = float(np.asarray(ci)[0, 1])
    except Exception:
        ci_low = ate - 1.96 * se
        ci_high = ate + 1.96 * se

    result = DMLResult(
        ate=ate,
        se=se,
        ci_low=ci_low,
        ci_high=ci_high,
        method="doubleml_PLR",
        n=int(y_a.size),
        n_folds=n_folds,
        extra={"model_y": type(my).__name__, "model_t": type(mt).__name__},
    )
    return plr, result


@dataclass
class SerializablePLREstimator:
    """Minimal ATE-only PLR payload for Serie B (B1) serving.

    Stores the partialling-out coefficient and optional robust SE / CI.
    Works without EconML: ``const_marginal_ate`` / ``ate`` return the scalar
    ATE; ``predict`` returns a constant vector of that ATE (length of rows).

    Attributes
    ----------
    ate_ :
        Point estimate of the ATE (θ in the PLR).
    se_ :
        Standard error (if available).
    ci_low_, ci_high_ :
        95% confidence interval bounds (if available).
    feature_names_ :
        Covariate names used at training time.
    method_ :
        Backend / learner label (e.g. ``plr_sklearn_crossfit``).
    n_folds_ :
        Cross-fitting folds.
    training_n_ :
        Sample size used to estimate θ.
    extra_ :
        Free-form metadata (learner names, etc.).
    """

    ate_: float
    se_: Optional[float] = None
    ci_low_: Optional[float] = None
    ci_high_: Optional[float] = None
    feature_names_: Optional[List[str]] = None
    method_: str = "plr"
    n_folds_: int = 0
    training_n_: int = 0
    extra_: Dict[str, Any] = field(default_factory=dict)

    def const_marginal_ate(self, X: Optional[MatrixLike] = None) -> float:
        """Return constant marginal ATE (ignores X for homogeneous PLR)."""
        return float(self.ate_)

    def ate(self, X: Optional[MatrixLike] = None) -> float:
        """Alias of :meth:`const_marginal_ate` (homogeneous effect)."""
        return self.const_marginal_ate(X)

    def predict(self, X: MatrixLike) -> np.ndarray:
        """Return a constant ATE vector with one entry per row of ``X``."""
        X_arr, _ = _as_X(X)
        n = int(X_arr.shape[0])
        return np.full(n, float(self.ate_), dtype=float)

    def conf_int(self, alpha: float = 0.05) -> Tuple[float, float]:
        """Return (low, high) CI; recomputes from SE if stored bounds missing."""
        if self.ci_low_ is not None and self.ci_high_ is not None:
            return float(self.ci_low_), float(self.ci_high_)
        if self.se_ is None:
            raise ValueError("No SE/CI stored on this estimator")
        # Only alpha=0.05 stored by default; scale if needed
        z = 1.96 if abs(alpha - 0.05) < 1e-9 else float(
            abs(__import__("scipy.stats", fromlist=["norm"]).norm.ppf(alpha / 2.0))
        )
        return float(self.ate_ - z * self.se_), float(self.ate_ + z * self.se_)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "ate": self.ate_,
            "se": self.se_,
            "ci_low": self.ci_low_,
            "ci_high": self.ci_high_,
            "feature_names": self.feature_names_,
            "method": self.method_,
            "n_folds": self.n_folds_,
            "training_n": self.training_n_,
            "extra": self.extra_,
        }


def wrap_plr_result(
    result: DMLResult,
    *,
    feature_list: Optional[Sequence[str]] = None,
    underlying: Any = None,
) -> SerializablePLREstimator:
    """Build a :class:`SerializablePLREstimator` from a :class:`DMLResult`.

    If ``underlying`` is an EconML / DoubleML object that already exposes
    ``const_marginal_ate``, prefer serializing that when calling
    :func:`save_dml_artifact`; this wrapper is the sklearn-safe default.
    """
    return SerializablePLREstimator(
        ate_=float(result.ate),
        se_=None if result.se is None else float(result.se),
        ci_low_=None if result.ci_low is None else float(result.ci_low),
        ci_high_=None if result.ci_high is None else float(result.ci_high),
        feature_names_=list(feature_list) if feature_list is not None else None,
        method_=str(result.method),
        n_folds_=int(result.n_folds or 0),
        training_n_=int(result.n or 0),
        extra_=dict(result.extra or {}),
    )


def save_dml_artifact(
    estimator: Any,
    path: Union[str, Path],
    *,
    feature_list: Optional[Sequence[str]] = None,
    training_meta: Optional[Dict[str, Any]] = None,
) -> Path:
    """Serialize estimator (+ sidecar JSON) for Serie B (B1).

    Writes::

        <path>                 # joblib of estimator (or SerializablePLREstimator)
        feature_list.json      # next to joblib if feature_list given
        training_meta.json     # next to joblib if training_meta given
    """
    path = Path(path)
    ensure_dir(path.parent)
    dump(estimator, path)

    if feature_list is not None:
        fl_path = path.parent / "feature_list.json"
        with fl_path.open("w", encoding="utf-8") as f:
            json.dump(list(feature_list), f, indent=2)

    if training_meta is not None:
        meta_path = path.parent / "training_meta.json"
        with meta_path.open("w", encoding="utf-8") as f:
            json.dump(training_meta, f, indent=2, default=str)

    return path


def load_dml_artifact(path: Union[str, Path]) -> Any:
    """Load a joblib DML artifact written by :func:`save_dml_artifact`."""
    return load(Path(path))


def export_a2_artifacts(
    *,
    scenario: str = "synthetic/inference/ihdp_medium",
    out_dir: Optional[Union[str, Path]] = None,
    n_folds: int = 5,
    random_state: int = RANDOM_STATE,
    backend: str = "auto",
    model_y_kind: str = "lasso",
    model_t_kind: str = "lasso",
    prefer_split: str = "train",
) -> Dict[str, Any]:
    """Fit official course PLR (Lasso nuisances) and write A2 artifacts.

    Kernel-less entry point for notebooks, autograder and Serie B prep.

    Writes under ``artifacts/A2/`` (or ``out_dir``)::

        dml_estimator.joblib
        feature_list.json
        training_meta.json

    Returns a dict with paths and the :class:`DMLResult` summary.
    """
    # Local import avoids circular import at module load (data_io → paths only).
    from .data_io import load_scenario
    from .paths import artifacts_dir, relative_to_repo

    bundle = load_scenario(scenario)
    y, t, X = bundle.ytx(prefer_split)
    feature_list = list(X.columns) if hasattr(X, "columns") else [
        f"x{i}" for i in range(np.asarray(X).shape[1])
    ]

    est_obj, result = fit_plr(
        y,
        t,
        X,
        backend=backend,
        model_y_kind=model_y_kind,
        model_t_kind=model_t_kind,
        n_folds=n_folds,
        random_state=random_state,
    )

    # Prefer serializable wrapper (predictable B1 interface). If EconML fitted,
    # still wrap for a stable contract; store method label from result.
    payload = wrap_plr_result(result, feature_list=feature_list, underlying=est_obj)
    if est_obj is not None:
        payload.extra_["underlying_type"] = type(est_obj).__name__

    dest = Path(out_dir) if out_dir is not None else artifacts_dir("A2")
    ensure_dir(dest)
    joblib_path = dest / "dml_estimator.joblib"

    training_meta: Dict[str, Any] = {
        "notebook_id": "A2",
        "scenario": scenario,
        "scenario_id": bundle.scenario_id,
        "seed": int(random_state),
        "dataset_generator_seed": bundle.meta.get("seed"),
        "split_used": prefer_split,
        "n": int(result.n),
        "n_folds": int(result.n_folds or n_folds),
        "backend_method": result.method,
        "model_y_kind": model_y_kind,
        "model_t_kind": model_t_kind,
        "feature_list": feature_list,
        "ate_point_estimate": float(result.ate),
        "se": None if result.se is None else float(result.se),
        "ci_low": None if result.ci_low is None else float(result.ci_low),
        "ci_high": None if result.ci_high is None else float(result.ci_high),
        "ci_level": 0.95,
        "estimand": "ATE",
        "model": "PLR",
        "assumptions": [
            "conditional_ignorability",
            "overlap",
            "SUTVA",
            "PLR_specification",
        ],
        # Repo-relative path only (no machine-specific absolute paths).
        "package_root": "03_notebooks_caso_estudio",
        "artifacts_relpath": relative_to_repo(dest),
    }

    save_dml_artifact(
        payload,
        joblib_path,
        feature_list=feature_list,
        training_meta=training_meta,
    )

    return {
        "joblib": joblib_path,
        "feature_list": dest / "feature_list.json",
        "training_meta": dest / "training_meta.json",
        "result": result.to_dict(),
        "scenario_id": bundle.scenario_id,
    }


def compare_learners_plr(
    y: ArrayLike,
    t: ArrayLike,
    X: MatrixLike,
    *,
    learner_specs: Optional[Sequence[Tuple[str, str, str]]] = None,
    n_folds: int = 5,
    random_state: int = RANDOM_STATE,
    backend: str = "sklearn",
) -> pd.DataFrame:
    """Fit PLR under several nuisance learner pairs; return comparison table.

    Parameters
    ----------
    learner_specs:
        Sequence of ``(label, model_y_kind, model_t_kind)``. Default compares
        LassoCV vs HistGradientBoosting.
    """
    if learner_specs is None:
        learner_specs = (
            ("lasso", "lasso", "lasso"),
            ("hist_gb", "hgb", "hgb"),
        )
    rows = []
    for label, yk, tk in learner_specs:
        _, res = fit_plr(
            y,
            t,
            X,
            backend=backend,
            model_y_kind=yk,
            model_t_kind=tk,
            n_folds=n_folds,
            random_state=random_state,
        )
        rows.append(
            {
                "learner": label,
                "model_y": res.extra.get("model_y", yk),
                "model_t": res.extra.get("model_t", tk),
                "ate": res.ate,
                "se": res.se,
                "ci_low": res.ci_low,
                "ci_high": res.ci_high,
                "method": res.method,
                "n_folds": res.n_folds,
            }
        )
    return pd.DataFrame(rows)
