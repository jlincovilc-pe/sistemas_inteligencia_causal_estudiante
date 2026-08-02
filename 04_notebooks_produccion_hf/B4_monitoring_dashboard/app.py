"""B4 — Dashboard de monitoreo de supuestos causales (drift simulado).

Run::

    streamlit run app.py
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pandas as pd
import streamlit as st
from scipy import stats

B4 = Path(__file__).resolve().parent
REPO = B4.parents[1]
SERIE_A = REPO / "03_notebooks_caso_estudio"
if str(SERIE_A) not in sys.path:
    sys.path.insert(0, str(SERIE_A))

from lib.paths import RANDOM_STATE  # noqa: E402
from lib.data_io import load_scenario  # noqa: E402

SCENARIO = "synthetic/inference/ihdp_medium"


@st.cache_data
def load_baseline_train():
    bundle = load_scenario(SCENARIO)
    _, t, X = bundle.ytx("train")
    return X.copy(), t.copy()


def simulate_stream(
    X_base: pd.DataFrame,
    t_base: pd.Series,
    n_windows: int = 12,
    window_size: int = 200,
    drift_start: int = 6,
    drift_strength: float = 0.8,
    seed: int = RANDOM_STATE,
):
    """Generate sequential windows; after drift_start, shift first 3 covariates."""
    rng = np.random.default_rng(seed)
    X = X_base.to_numpy(dtype=float)
    t = t_base.to_numpy(dtype=int)
    n, p = X.shape
    feat_names = list(X_base.columns)
    rows = []
    for w in range(n_windows):
        idx = rng.integers(0, n, size=window_size)
        Xw = X[idx].copy()
        tw = t[idx].copy()
        if w >= drift_start:
            # gradual mean shift on first 3 features
            shift = drift_strength * (w - drift_start + 1)
            Xw[:, :3] = Xw[:, :3] + shift
        # "effect" proxy: simple residualized association (monitoring metric, not ATE claim)
        # Use difference in mean Y proxy: here we only have X,T — use treated rate + mean X0
        ate_proxy = float(Xw[tw == 1, 0].mean() - Xw[tw == 0, 0].mean()) if tw.sum() and (1 - tw).sum() else 0.0
        for j, name in enumerate(feat_names[:5]):  # monitor first 5 features
            # KS vs baseline sample
            base_idx = rng.integers(0, n, size=window_size)
            ks = stats.ks_2samp(X[base_idx, j], Xw[:, j]).statistic
            rows.append(
                {
                    "window": w,
                    "feature": name,
                    "ks": float(ks),
                    "treat_rate": float(tw.mean()),
                    "ate_proxy": ate_proxy,
                    "drift_injected": w >= drift_start,
                }
            )
    return pd.DataFrame(rows)


def main():
    st.set_page_config(page_title="B4 Monitoreo causal", layout="wide")
    st.title("B4 — Monitoreo de supuestos causales en producción")
    st.markdown(
        """
Dashboard **docente** (Serie B4). Simula tráfico de producción con *drift* controlado
sobre el escenario `ihdp_medium` del monorepo.

**No** es un sistema de alerta clínica. Las métricas ilustran:
1. Drift de covariables (KS)
2. Tasa de tratamiento en ventana
3. Proxy de estabilidad del contraste (no es el ATE de DML)
"""
    )

    X_base, t_base = load_baseline_train()
    c1, c2, c3 = st.columns(3)
    with c1:
        n_windows = st.slider("Ventanas", 6, 24, 12)
    with c2:
        drift_start = st.slider("Inicio del drift (ventana)", 1, n_windows - 1, max(4, n_windows // 2))
    with c3:
        ks_threshold = st.slider("Umbral alerta KS", 0.05, 0.5, 0.15, 0.01)

    df = simulate_stream(
        X_base,
        t_base,
        n_windows=n_windows,
        drift_start=drift_start,
        seed=RANDOM_STATE,
    )

    # Aggregate per window
    by_w = (
        df.groupby("window", as_index=False)
        .agg(
            max_ks=("ks", "max"),
            treat_rate=("treat_rate", "first"),
            ate_proxy=("ate_proxy", "first"),
            drift_injected=("drift_injected", "first"),
        )
    )
    by_w["alert_ks"] = by_w["max_ks"] >= ks_threshold

    st.subheader("1. Drift de covariables (KS máximo por ventana)")
    st.line_chart(by_w.set_index("window")[["max_ks"]])
    st.caption(f"Umbral = {ks_threshold:.2f}")

    st.subheader("2. Tasa de tratamiento en ventana")
    st.line_chart(by_w.set_index("window")[["treat_rate"]])

    st.subheader("3. Proxy de contraste (monitoreo, no ATE formal)")
    st.line_chart(by_w.set_index("window")[["ate_proxy"]])

    n_alerts = int(by_w["alert_ks"].sum())
    if n_alerts > 0:
        st.error(f"⚠ Alertas KS: {n_alerts} ventana(s) superan el umbral (drift simulado esperado tras w≥{drift_start}).")
    else:
        st.success("Sin alertas KS con el umbral actual.")

    st.subheader("Tabla de ventanas")
    st.dataframe(by_w, use_container_width=True)

    st.markdown("---")
    st.markdown(
        f"""
### Checklist operativo
- Drift detectado: **{"sí" if n_alerts else "no"}**
- ¿Reentrenar B1/A2 o solo alertar? (discusión S27 / L27)
- Scenario baseline: `{SCENARIO}` · seed={RANDOM_STATE}
"""
    )


if __name__ == "__main__":
    main()
