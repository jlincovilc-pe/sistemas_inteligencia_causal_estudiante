"""L25 — KS drift en 3 covariables (prep B4)."""

from __future__ import annotations

import sys
from pathlib import Path

_LABS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(_LABS))
from lab_harness import REPO_ROOT, ensure_serie_a

ensure_serie_a()


def run_lab() -> dict:
    # Reuse B4 monitor_core
    b4 = REPO_ROOT / "04_notebooks_produccion_hf" / "B4_monitoring_dashboard"
    sys.path.insert(0, str(b4))
    from monitor_core import simulate_and_count_alerts

    rep = simulate_and_count_alerts(
        n_windows=12,
        drift_start=6,
        ks_threshold=0.12,
    )
    return {
        "n_alerts": int(rep["n_alerts"]),
        "max_ks_after_drift": float(rep["max_ks_after_drift"]),
        "ks_threshold": float(rep["ks_threshold"]),
        "alerts_triggered": rep["n_alerts"] >= 1,
        "feeds": "B4 dashboard",
        "session": "S25",
    }


if __name__ == "__main__":
    import json

    print(json.dumps(run_lab(), indent=2))
