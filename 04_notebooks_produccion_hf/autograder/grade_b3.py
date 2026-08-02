#!/usr/bin/env python3
"""Autograder B3 — policy Space (smoke sin requerir HF cloud)."""

from __future__ import annotations

import sys
from pathlib import Path

B3 = Path(__file__).resolve().parents[1] / "B3_policy_space"
if str(B3) not in sys.path:
    sys.path.insert(0, str(B3))


def _check(name, ok, detail, rows):
    rows.append((name, ok))
    print(f"  [{'PASS' if ok else 'FAIL'}] {name}: {detail}")


def main() -> int:
    print("=" * 60)
    print("B3 Autograder — Policy Gradio / smoke")
    print("=" * 60)
    rows = []

    app = B3 / "app.py"
    svc = B3 / "policy_service.py"
    job = B3 / "artifacts" / "policy.joblib"
    card = B3 / "artifacts" / "policy_card.md"
    req = B3 / "requirements.txt"

    _check("structure_app", app.is_file(), str(app), rows)
    _check("structure_service", svc.is_file(), str(svc), rows)
    _check("structure_requirements", req.is_file(), str(req), rows)
    _check("artifact_policy", job.is_file(), str(job), rows)
    _check("artifact_card", card.is_file(), str(card), rows)

    # Disclaimer in app
    app_txt = app.read_text(encoding="utf-8") if app.is_file() else ""
    _check(
        "disclaimer_present",
        "sintético" in app_txt.lower() or "sintetico" in app_txt.lower() or "synthetic" in app_txt.lower() or "docente" in app_txt.lower(),
        "disclaimer language in app.py",
        rows,
    )
    _check("gradio_import", "gradio" in app_txt, "uses gradio", rows)

    try:
        from policy_service import load_policy, smoke_three_cases

        pol = load_policy()
        cases = smoke_three_cases(pol)
        _check("smoke_three_cases", len(cases) == 3, str(cases), rows)
        _check(
            "decisions_binary",
            all(c["decision"] in (0, 1) for c in cases),
            str([c["decision"] for c in cases]),
            rows,
        )
        _check(
            "budget_20",
            abs(float(pol.budget_fraction) - 0.2) < 1e-6,
            f"B={pol.budget_fraction}",
            rows,
        )
        # interface keys
        import numpy as np

        out = pol.predict(X=np.zeros((2, len(pol.feature_names))))
        _check(
            "predict_keys",
            "decision" in out and "uplift_score" in out,
            list(out.keys()),
            rows,
        )
    except Exception as exc:
        _check("policy_runtime", False, repr(exc), rows)

    n_ok = sum(1 for _, ok in rows if ok)
    n = len(rows)
    print("-" * 60)
    print(f"Result: {'PASS' if n_ok == n else 'FAIL'} ({n_ok}/{n} checks)")
    return 0 if n_ok == n else 1


if __name__ == "__main__":
    raise SystemExit(main())
