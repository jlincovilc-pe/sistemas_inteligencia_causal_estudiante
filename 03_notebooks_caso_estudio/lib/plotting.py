"""Consistent plotting helpers for Serie A notebooks."""

from __future__ import annotations

from typing import Optional, Sequence, Union

import numpy as np
import pandas as pd

ArrayLike = Union[Sequence[float], np.ndarray, pd.Series]

# Course-wide style defaults (applied when matplotlib is available).
COURSE_STYLE = {
    "figure.figsize": (7.0, 4.5),
    "axes.grid": True,
    "grid.alpha": 0.3,
    "axes.spines.top": False,
    "axes.spines.right": False,
    "font.size": 11,
    "axes.titlesize": 12,
    "axes.labelsize": 11,
}


def apply_course_style() -> None:
    """Apply matplotlib rcParams for consistent course figures."""
    import matplotlib as mpl

    mpl.rcParams.update(COURSE_STYLE)


def _get_ax(ax=None, figsize=None):
    import matplotlib.pyplot as plt

    if ax is not None:
        return ax
    _, ax = plt.subplots(figsize=figsize or COURSE_STYLE["figure.figsize"])
    return ax


def plot_propensity_overlap(
    e_hat: ArrayLike,
    t: ArrayLike,
    *,
    bins: int = 30,
    ax=None,
    title: str = "Propensity score overlap",
):
    """Histogram of propensity scores by treatment group."""
    apply_course_style()
    ax = _get_ax(ax)
    e = np.asarray(e_hat, dtype=float).reshape(-1)
    t_a = np.asarray(t, dtype=int).reshape(-1)
    ax.hist(
        e[t_a == 0],
        bins=bins,
        alpha=0.55,
        label="Control (T=0)",
        density=True,
        color="#4C72B0",
    )
    ax.hist(
        e[t_a == 1],
        bins=bins,
        alpha=0.55,
        label="Treated (T=1)",
        density=True,
        color="#DD8452",
    )
    ax.set_xlabel("e(x) = P(T=1 | X)")
    ax.set_ylabel("Density")
    ax.set_title(title)
    ax.legend()
    return ax


def plot_smd_balance(
    balance_df: pd.DataFrame,
    *,
    smd_col: str = "smd",
    name_col: str = "covariate",
    threshold: float = 0.1,
    ax=None,
    title: str = "Covariate balance (SMD)",
):
    """Horizontal bar chart of standardized mean differences."""
    apply_course_style()
    ax = _get_ax(ax, figsize=(7.0, max(3.5, 0.35 * len(balance_df))))
    df = balance_df.sort_values(smd_col, key=lambda s: s.abs())
    colors = [
        "#C44E52" if abs(v) > threshold else "#55A868" for v in df[smd_col]
    ]
    ax.barh(df[name_col].astype(str), df[smd_col], color=colors)
    ax.axvline(threshold, color="gray", ls="--", lw=1)
    ax.axvline(-threshold, color="gray", ls="--", lw=1)
    ax.axvline(0.0, color="black", lw=0.8)
    ax.set_xlabel("Standardized mean difference")
    ax.set_title(title)
    return ax


def plot_cate_distributions(
    cate_dict: dict,
    *,
    ax=None,
    title: str = "CATE distributions by method",
    bins: int = 30,
):
    """Overlay histograms/KDEs for multiple CATE estimate vectors.

    Parameters
    ----------
    cate_dict:
        Mapping name → 1d array of τ̂(x).
    """
    apply_course_style()
    ax = _get_ax(ax)
    for name, vals in cate_dict.items():
        v = np.asarray(vals, dtype=float).reshape(-1)
        ax.hist(v, bins=bins, alpha=0.35, density=True, label=str(name))
    ax.set_xlabel(r"$\hat{\tau}(x)$")
    ax.set_ylabel("Density")
    ax.set_title(title)
    ax.legend()
    return ax


def plot_qini(
    curve: pd.DataFrame,
    *,
    ax=None,
    title: str = "Qini curve",
):
    """Plot Qini curve vs random baseline.

    Expects columns from :func:`lib.metrics.qini_curve`:
    ``fraction``, ``qini``, ``random_qini``.
    """
    apply_course_style()
    ax = _get_ax(ax)
    ax.plot(curve["fraction"], curve["qini"], label="Model", lw=2)
    if "random_qini" in curve.columns:
        ax.plot(
            curve["fraction"],
            curve["random_qini"],
            label="Random",
            ls="--",
            color="gray",
        )
    ax.set_xlabel("Population fraction (ranked by score)")
    ax.set_ylabel("Qini")
    ax.set_title(title)
    ax.legend()
    return ax


def plot_uplift_bins(
    uplift_df: pd.DataFrame,
    *,
    ax=None,
    title: str = "Uplift by score bin",
):
    """Bar plot of per-bin uplift from :func:`lib.metrics.uplift_curve`."""
    apply_course_style()
    ax = _get_ax(ax)
    ax.bar(uplift_df["bin"].astype(str), uplift_df["uplift"], color="#4C72B0")
    ax.axhline(0.0, color="black", lw=0.8)
    ax.set_xlabel("Score bin (1 = highest uplift score)")
    ax.set_ylabel("Uplift (mean Y_t − mean Y_c)")
    ax.set_title(title)
    return ax


def plot_neyman_scatter(
    t_res: ArrayLike,
    y_res: ArrayLike,
    *,
    ax=None,
    title: str = "Neyman residuals (PLR)",
):
    """Scatter of partialled-out residuals for DML diagnostics."""
    apply_course_style()
    ax = _get_ax(ax)
    tr = np.asarray(t_res, dtype=float).reshape(-1)
    yr = np.asarray(y_res, dtype=float).reshape(-1)
    ax.scatter(tr, yr, alpha=0.35, s=12, edgecolors="none")
    ax.set_xlabel(r"$\tilde{T}$")
    ax.set_ylabel(r"$\tilde{Y}$")
    ax.set_title(title)
    return ax
