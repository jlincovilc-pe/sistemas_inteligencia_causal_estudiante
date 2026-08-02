#!/usr/bin/env python3
"""Autograder B4 — monitoring dashboard (smoke)."""

from __future__ import annotations

import sys
from pathlib import Path

B4 = Path(__file__).resolve().parents[1] / "B4_monitoring_dashboard"
if str(B4) not in sys.path:
    sys.path.insert(0, str(B4))


def _check(name, ok, detail, rows):
    rows.append((name, ok))
    print(f"  [{'PASS' if ok else 'FAIL'}] {name}: {detail}")


def main() -> int:
    print("=" * 60)
    print("B4 Autograder — monitoring / drift")
    print("=" * 60)
    rows = []

    app = B4 / "app.py"
    core = B4 / "monitor_core.py"
    req = B4 / "requirements.txt"
    _check("structure_app", app.is_file(), str(app), rows)
    _check("structure_core", core.is_file(), str(core), rows)
    _check("structure_req", req.is_file(), str(req), rows)

    app_txt = app.read_text(encoding="utf-8") if app.is_file() else ""
    _check("has_ks", "ks" in app_txt.lower() or "KS" in app_txt, "KS metric", rows)
    _check("has_streamlit", "streamlit" in app_txt, "streamlit UI", rows)
    _check("has_disclaimer", "docente" in app_txt.lower() or "sintético" in app_txt.lower() or "sintetico" in app_txt.lower(), "disclaimer", rows)

    try:
        from monitor_core import simulate_and_count_alerts

        rep = simulate_and_count_alerts(n_windows=12, drift_start=5, ks_threshold=0.12)
        _check("alerts_on_drift", rep["n_alerts"] >= 1, str(rep), rows)
        _check("ks_elevated", rep["max_ks_after_drift"] >= 0.12, str(rep), rows)
    except Exception as exc:
        _check("monitor_runtime", False, repr(exc), rows)

    n_ok = sum(1 for _, ok in rows if ok)
    n = len(rows)
    print("-" * 60)
    print(f"Result: {'PASS' if n_ok == n else 'FAIL'} ({n_ok}/{n} checks)")
    return 0 if n_ok == n else 1


if __name__ == "__main__":
    raise SystemExit(main())
