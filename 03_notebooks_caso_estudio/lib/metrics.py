"""Evaluation metrics for Serie A (ATE, PEHE, uplift/Qini, coverage).

Truth-based metrics (PEHE, ATE absolute error vs true ATE) are intended for
autograder and marked evaluation sections only.
"""

from __future__ import annotations

from typing import Dict, Optional, Sequence, Tuple, Union

import numpy as np
import pandas as pd

ArrayLike = Union[Sequence[float], np.ndarray, pd.Series]


def _as_1d(a: ArrayLike) -> np.ndarray:
    arr = np.asarray(a, dtype=float).reshape(-1)
    return arr


def ate_absolute_error(
    ate_hat: float,
    ate_true: float,
) -> float:
    """Absolute error of an ATE estimate: ``|ate_hat - ate_true|``."""
    return float(abs(float(ate_hat) - float(ate_true)))


def ate_from_tau(tau: ArrayLike) -> float:
    """Empirical ATE as mean of individual treatment effects."""
    return float(np.mean(_as_1d(tau)))


def pehe(tau_hat: ArrayLike, tau_true: ArrayLike) -> float:
    """Precision in Estimation of Heterogeneous Effects.

    PEHE = sqrt(mean((tau_hat - tau_true)^2))
    """
    th = _as_1d(tau_hat)
    tt = _as_1d(tau_true)
    if th.shape != tt.shape:
        raise ValueError(
            f"Shape mismatch: tau_hat {th.shape} vs tau_true {tt.shape}"
        )
    if th.size == 0:
        raise ValueError("Empty arrays for PEHE")
    return float(np.sqrt(np.mean((th - tt) ** 2)))


def mae_tau(tau_hat: ArrayLike, tau_true: ArrayLike) -> float:
    """Mean absolute error of CATE estimates."""
    th = _as_1d(tau_hat)
    tt = _as_1d(tau_true)
    if th.shape != tt.shape:
        raise ValueError(
            f"Shape mismatch: tau_hat {th.shape} vs tau_true {tt.shape}"
        )
    return float(np.mean(np.abs(th - tt)))


def coverage_indicator(
    low: float,
    high: float,
    true_value: float,
) -> bool:
    """Whether ``true_value`` lies in the closed interval ``[low, high]``."""
    lo, hi = float(low), float(high)
    if lo > hi:
        lo, hi = hi, lo
    return bool(lo <= float(true_value) <= hi)


def coverage_rate(
    lows: ArrayLike,
    highs: ArrayLike,
    true_values: ArrayLike,
) -> float:
    """Fraction of intervals covering the corresponding true values."""
    lo = _as_1d(lows)
    hi = _as_1d(highs)
    tv = _as_1d(true_values)
    if not (lo.shape == hi.shape == tv.shape):
        raise ValueError("lows, highs, true_values must share shape")
    if lo.size == 0:
        return float("nan")
    covered = (lo <= tv) & (tv <= hi)
    return float(np.mean(covered))


def uplift_curve(
    y: ArrayLike,
    t: ArrayLike,
    score: ArrayLike,
    n_bins: int = 10,
) -> pd.DataFrame:
    """Bin units by descending uplift score and compute incremental outcomes.

    Uses the two-model / treated-control difference within score quantiles
    (simple observational uplift table; not doubly robust).

    Returns a DataFrame with columns:
    ``bin, n, n_treated, n_control, mean_y_t, mean_y_c, uplift, cum_uplift``.
    """
    y_a = _as_1d(y)
    t_a = _as_1d(t).astype(int)
    s_a = _as_1d(score)
    if not (y_a.shape == t_a.shape == s_a.shape):
        raise ValueError("y, t, score must have the same length")
    n = y_a.size
    if n == 0:
        return pd.DataFrame(
            columns=[
                "bin",
                "n",
                "n_treated",
                "n_control",
                "mean_y_t",
                "mean_y_c",
                "uplift",
                "cum_uplift",
            ]
        )

    order = np.argsort(-s_a, kind="mergesort")
    y_s, t_s = y_a[order], t_a[order]
    # Equal-size bins along ranked list
    edges = np.linspace(0, n, num=n_bins + 1, dtype=int)
    rows = []
    cum_t_sum = 0.0
    cum_c_sum = 0.0
    cum_nt = 0
    cum_nc = 0
    for b in range(n_bins):
        lo, hi = edges[b], edges[b + 1]
        if hi <= lo:
            continue
        yb, tb = y_s[lo:hi], t_s[lo:hi]
        nt = int(tb.sum())
        nc = int(len(tb) - nt)
        yt = float(yb[tb == 1].mean()) if nt > 0 else float("nan")
        yc = float(yb[tb == 0].mean()) if nc > 0 else float("nan")
        up = yt - yc if (nt > 0 and nc > 0) else float("nan")
        cum_t_sum += float(yb[tb == 1].sum()) if nt else 0.0
        cum_c_sum += float(yb[tb == 0].sum()) if nc else 0.0
        cum_nt += nt
        cum_nc += nc
        cum_up = (
            (cum_t_sum / cum_nt - cum_c_sum / cum_nc)
            if (cum_nt > 0 and cum_nc > 0)
            else float("nan")
        )
        rows.append(
            {
                "bin": b + 1,
                "n": int(hi - lo),
                "n_treated": nt,
                "n_control": nc,
                "mean_y_t": yt,
                "mean_y_c": yc,
                "uplift": up,
                "cum_uplift": cum_up,
            }
        )
    return pd.DataFrame(rows)


def qini_curve(
    y: ArrayLike,
    t: ArrayLike,
    score: ArrayLike,
    n_grid: int = 100,
) -> pd.DataFrame:
    """Approximate Qini curve from ranked uplift scores.

    Definition (binary treatment)::

        Q(k) = (sum Y among top-k treated) / n_t_total
               - (sum Y among top-k control) / n_c_total * (n_t_top / n_c_top) ...

    We use the common incremental formulation:

        qini(p) = cum_sum(y * t) - cum_sum(y * (1-t)) * (n_t / n_c)

    evaluated on the population reordered by descending score, then scaled
    by sample size. Returns columns ``fraction, qini, random_qini``.
    """
    y_a = _as_1d(y)
    t_a = _as_1d(t).astype(float)
    s_a = _as_1d(score)
    n = y_a.size
    if n == 0:
        return pd.DataFrame(columns=["fraction", "qini", "random_qini"])

    order = np.argsort(-s_a, kind="mergesort")
    y_s = y_a[order]
    t_s = t_a[order]
    n_t = float(t_s.sum())
    n_c = float(n - n_t)
    if n_t == 0 or n_c == 0:
        raise ValueError("Qini requires both treated and control units")

    # Incremental gains: treated contribution minus control scaled by prop.
    # Classic: cum(y|t=1) - cum(y|t=0) * (N_t / N_c)
    cum_yt = np.cumsum(y_s * t_s)
    cum_yc = np.cumsum(y_s * (1.0 - t_s))
    qini = cum_yt - cum_yc * (n_t / n_c)

    # Subsample grid for plotting
    idx = np.unique(
        np.linspace(0, n - 1, num=min(n_grid, n), dtype=int)
    )
    fraction = (idx + 1) / n
    q_vals = qini[idx]
    # Random baseline: linear from 0 to qini_at_full
    q_full = float(qini[-1])
    random_q = fraction * q_full
    return pd.DataFrame(
        {"fraction": fraction, "qini": q_vals, "random_qini": random_q}
    )


def qini_auc(curve: pd.DataFrame) -> float:
    """Area under the Qini curve (trapezoidal) minus random baseline area.

    Positive values indicate ranking better than random.
    """
    if curve.empty:
        return float("nan")
    x = curve["fraction"].to_numpy(dtype=float)
    y = curve["qini"].to_numpy(dtype=float)
    y_rand = curve["random_qini"].to_numpy(dtype=float)
    # np.trapezoid (numpy>=2) with trapz fallback
    trapz = getattr(np, "trapezoid", None) or np.trapz
    area = float(trapz(y, x) - trapz(y_rand, x))
    return area


def summarize_ate_comparison(
    estimates: Dict[str, float],
    ate_true: Optional[float] = None,
) -> pd.DataFrame:
    """Build a small comparison table of named ATE estimates."""
    rows = []
    for name, val in estimates.items():
        row = {"estimator": name, "ate_hat": float(val)}
        if ate_true is not None:
            row["ate_true"] = float(ate_true)
            row["abs_error"] = ate_absolute_error(val, ate_true)
        rows.append(row)
    return pd.DataFrame(rows)
