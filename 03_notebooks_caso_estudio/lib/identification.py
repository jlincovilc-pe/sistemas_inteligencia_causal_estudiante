"""Identification diagnostics: propensity, balance (SMD), overlap.

Used primarily in Notebook A1. Pure sklearn/numpy; no truth required.
"""

from __future__ import annotations

from typing import Dict, List, Optional, Sequence, Tuple, Union

import numpy as np
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

from .paths import RANDOM_STATE

ArrayLike = Union[Sequence[float], np.ndarray, pd.Series]


def fit_propensity(
    X: Union[pd.DataFrame, np.ndarray],
    t: ArrayLike,
    *,
    random_state: int = RANDOM_STATE,
    C: float = 1.0,
    max_iter: int = 1000,
) -> Tuple[Pipeline, np.ndarray]:
    """Fit a logistic propensity model and return ``(model, e_hat)``.

    ``e_hat`` is P(T=1 | X) on the same rows as ``X``.
    """
    X_arr = np.asarray(X, dtype=float)
    t_arr = np.asarray(t, dtype=int).reshape(-1)
    if X_arr.ndim == 1:
        X_arr = X_arr.reshape(-1, 1)
    if X_arr.shape[0] != t_arr.shape[0]:
        raise ValueError("X and t length mismatch")

    model = Pipeline(
        steps=[
            ("scaler", StandardScaler()),
            (
                "clf",
                LogisticRegression(
                    C=C,
                    max_iter=max_iter,
                    random_state=random_state,
                    solver="lbfgs",
                ),
            ),
        ]
    )
    model.fit(X_arr, t_arr)
    e_hat = model.predict_proba(X_arr)[:, 1]
    return model, e_hat


def propensity_scores(
    X: Union[pd.DataFrame, np.ndarray],
    t: ArrayLike,
    **kwargs,
) -> np.ndarray:
    """Convenience: return only the propensity score vector."""
    _, e = fit_propensity(X, t, **kwargs)
    return e


def standardized_mean_difference(
    x: ArrayLike,
    t: ArrayLike,
) -> float:
    """SMD for one covariate: (mean_t - mean_c) / pooled_sd."""
    x_a = np.asarray(x, dtype=float).reshape(-1)
    t_a = np.asarray(t, dtype=int).reshape(-1)
    xt = x_a[t_a == 1]
    xc = x_a[t_a == 0]
    if xt.size == 0 or xc.size == 0:
        return float("nan")
    mt, mc = float(xt.mean()), float(xc.mean())
    vt = float(xt.var(ddof=1)) if xt.size > 1 else 0.0
    vc = float(xc.var(ddof=1)) if xc.size > 1 else 0.0
    pooled = np.sqrt(0.5 * (vt + vc))
    if pooled == 0.0 or not np.isfinite(pooled):
        return 0.0 if mt == mc else float("inf")
    return float((mt - mc) / pooled)


def balance_table(
    X: pd.DataFrame,
    t: ArrayLike,
    covariates: Optional[Sequence[str]] = None,
) -> pd.DataFrame:
    """SMD and means for each covariate by treatment group."""
    t_a = np.asarray(t, dtype=int).reshape(-1)
    cols = list(covariates) if covariates is not None else list(X.columns)
    rows = []
    for c in cols:
        x = X[c].to_numpy(dtype=float)
        xt = x[t_a == 1]
        xc = x[t_a == 0]
        rows.append(
            {
                "covariate": c,
                "mean_treated": float(xt.mean()) if xt.size else float("nan"),
                "mean_control": float(xc.mean()) if xc.size else float("nan"),
                "smd": standardized_mean_difference(x, t_a),
            }
        )
    out = pd.DataFrame(rows)
    out["abs_smd"] = out["smd"].abs()
    return out.sort_values("abs_smd", ascending=False).reset_index(drop=True)


def overlap_diagnostics(
    e_hat: ArrayLike,
    t: Optional[ArrayLike] = None,
    *,
    trim_low: float = 0.02,
    trim_high: float = 0.98,
) -> Dict[str, float]:
    """Summarize propensity support and optional trimming.

    Returns counts/fractions outside ``[trim_low, trim_high]`` and
    min/max/mean propensity. If ``t`` is provided, also reports rates
    within treated and control groups.
    """
    e = np.asarray(e_hat, dtype=float).reshape(-1)
    if e.size == 0:
        raise ValueError("Empty propensity vector")
    inside = (e >= trim_low) & (e <= trim_high)
    out: Dict[str, float] = {
        "n": float(e.size),
        "min": float(e.min()),
        "max": float(e.max()),
        "mean": float(e.mean()),
        "frac_inside_trim": float(inside.mean()),
        "frac_trimmed": float(1.0 - inside.mean()),
        "trim_low": float(trim_low),
        "trim_high": float(trim_high),
        "frac_strictly_interior": float(((e > 0.0) & (e < 1.0)).mean()),
    }
    if t is not None:
        t_a = np.asarray(t, dtype=int).reshape(-1)
        if t_a.shape != e.shape:
            raise ValueError("t and e_hat length mismatch")
        for label, mask in (("treated", t_a == 1), ("control", t_a == 0)):
            if mask.any():
                out[f"min_{label}"] = float(e[mask].min())
                out[f"max_{label}"] = float(e[mask].max())
                out[f"mean_{label}"] = float(e[mask].mean())
    return out


def trim_by_propensity(
    df: pd.DataFrame,
    e_hat: ArrayLike,
    *,
    trim_low: float = 0.02,
    trim_high: float = 0.98,
) -> Tuple[pd.DataFrame, np.ndarray]:
    """Return rows with propensity in ``[trim_low, trim_high]`` and boolean mask."""
    e = np.asarray(e_hat, dtype=float).reshape(-1)
    if len(df) != e.size:
        raise ValueError("df and e_hat length mismatch")
    mask = (e >= trim_low) & (e <= trim_high)
    return df.loc[mask].copy(), mask


def diff_in_means(y: ArrayLike, t: ArrayLike) -> float:
    """Naive ATE: mean(Y|T=1) - mean(Y|T=0)."""
    y_a = np.asarray(y, dtype=float).reshape(-1)
    t_a = np.asarray(t, dtype=int).reshape(-1)
    yt = y_a[t_a == 1]
    yc = y_a[t_a == 0]
    if yt.size == 0 or yc.size == 0:
        raise ValueError("Both treatment arms required")
    return float(yt.mean() - yc.mean())


def ols_ate(
    y: ArrayLike,
    t: ArrayLike,
    X: Union[pd.DataFrame, np.ndarray],
) -> float:
    """ATE from linear regression of Y on T + X (coefficient on T)."""
    from sklearn.linear_model import LinearRegression

    y_a = np.asarray(y, dtype=float).reshape(-1)
    t_a = np.asarray(t, dtype=float).reshape(-1, 1)
    X_arr = np.asarray(X, dtype=float)
    if X_arr.ndim == 1:
        X_arr = X_arr.reshape(-1, 1)
    design = np.hstack([t_a, X_arr])
    reg = LinearRegression()
    reg.fit(design, y_a)
    return float(reg.coef_[0])


def post_double_selection_ate(
    y: ArrayLike,
    t: ArrayLike,
    X: Union[pd.DataFrame, np.ndarray],
    *,
    random_state: int = RANDOM_STATE,
    max_iter: int = 5000,
) -> Dict[str, object]:
    """Simple Post-Double-Selection ATE (Belloni et al. style).

    1. Lasso Y ~ X → selected controls S_y
    2. Lasso T ~ X → selected controls S_t
    3. OLS Y ~ T + X_{S_y ∪ S_t}

    Returns dict with ``ate``, ``selected``, ``n_selected``.
    """
    from sklearn.linear_model import LassoCV, LinearRegression

    y_a = np.asarray(y, dtype=float).reshape(-1)
    t_a = np.asarray(t, dtype=float).reshape(-1)
    X_arr = np.asarray(X, dtype=float)
    if X_arr.ndim == 1:
        X_arr = X_arr.reshape(-1, 1)
    n, p = X_arr.shape
    names: List[str]
    if isinstance(X, pd.DataFrame):
        names = list(X.columns)
    else:
        names = [f"x{i}" for i in range(p)]

    # Standardize X for Lasso stability
    scaler = StandardScaler()
    Xs = scaler.fit_transform(X_arr)

    las_y = LassoCV(cv=5, random_state=random_state, max_iter=max_iter)
    las_t = LassoCV(cv=5, random_state=random_state, max_iter=max_iter)
    las_y.fit(Xs, y_a)
    las_t.fit(Xs, t_a)

    sel_y = np.where(np.abs(las_y.coef_) > 1e-8)[0]
    sel_t = np.where(np.abs(las_t.coef_) > 1e-8)[0]
    selected_idx = sorted(set(sel_y.tolist()) | set(sel_t.tolist()))
    selected_names = [names[i] for i in selected_idx]

    if selected_idx:
        X_sel = X_arr[:, selected_idx]
        design = np.column_stack([t_a, X_sel])
    else:
        design = t_a.reshape(-1, 1)

    ols = LinearRegression()
    ols.fit(design, y_a)
    ate = float(ols.coef_[0])
    return {
        "ate": ate,
        "selected": selected_names,
        "n_selected": len(selected_names),
        "selected_y": [names[i] for i in sel_y],
        "selected_t": [names[i] for i in sel_t],
    }
