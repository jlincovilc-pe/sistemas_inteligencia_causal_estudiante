"""L27 — ¿Reentrenar o solo alertar? política simple de umbrales."""

from __future__ import annotations

from dataclasses import dataclass
from typing import List


@dataclass
class WindowAlert:
    window: int
    ks_max: float
    treat_rate: float
    ate_proxy_delta: float


def decide_action(
    alerts: List[WindowAlert],
    *,
    ks_threshold: float = 0.15,
    n_consecutive: int = 3,
    ate_delta_threshold: float = 0.5,
) -> dict:
    """Rule:
    - If KS exceeds threshold for n_consecutive windows → RETRAIN
    - Elif single KS spike or moderate ate drift → ALERT only
    - Else → OK
    """
    consecutive = 0
    max_run = 0
    any_spike = False
    for a in alerts:
        if a.ks_max >= ks_threshold:
            consecutive += 1
            max_run = max(max_run, consecutive)
            any_spike = True
        else:
            consecutive = 0
        if abs(a.ate_proxy_delta) >= ate_delta_threshold:
            any_spike = True

    if max_run >= n_consecutive:
        action = "RETRAIN"
        reason = f"KS≥{ks_threshold} durante {max_run} ventanas consecutivas"
    elif any_spike:
        action = "ALERT"
        reason = "Spike aislado de drift o cambio de proxy de efecto"
    else:
        action = "OK"
        reason = "Métricas dentro de umbral"

    return {
        "action": action,
        "reason": reason,
        "max_consecutive_ks": max_run,
        "ks_threshold": ks_threshold,
        "n_consecutive_required": n_consecutive,
    }


def simulate_series() -> List[WindowAlert]:
    # 5 calm + 4 drifted
    out = []
    for w in range(9):
        if w < 5:
            out.append(WindowAlert(w, ks_max=0.05, treat_rate=0.4, ate_proxy_delta=0.1))
        else:
            out.append(
                WindowAlert(w, ks_max=0.25, treat_rate=0.42, ate_proxy_delta=0.8)
            )
    return out


def run_lab() -> dict:
    series = simulate_series()
    decision = decide_action(series)
    # single spike series
    spike = [
        WindowAlert(0, 0.05, 0.4, 0.0),
        WindowAlert(1, 0.30, 0.4, 0.2),
        WindowAlert(2, 0.05, 0.4, 0.0),
    ]
    d2 = decide_action(spike)
    return {
        "sustained_drift": decision,
        "single_spike": d2,
        "expect_retrain": decision["action"] == "RETRAIN",
        "expect_alert_on_spike": d2["action"] == "ALERT",
        "session": "S27",
        "feeds": "B4 thresholds / continual learning discussion",
    }


if __name__ == "__main__":
    import json

    print(json.dumps(run_lab(), indent=2))
