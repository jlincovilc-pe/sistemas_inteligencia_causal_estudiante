#!/usr/bin/env python3
"""Autograder B2 — model card causal + workflow CI (sin push HF)."""

from __future__ import annotations

import re
import sys
from pathlib import Path

B2 = Path(__file__).resolve().parents[1] / "B2_hub_cicd"


def _check(name, ok, detail, rows):
    rows.append((name, ok))
    print(f"  [{'PASS' if ok else 'FAIL'}] {name}: {detail}")


def main() -> int:
    print("=" * 60)
    print("B2 Autograder — model card + CI workflow")
    print("=" * 60)
    rows = []

    card = B2 / "model_card" / "MODEL_CARD.md"
    # Plantilla local (sin .github del monorepo — curso solo en máquina)
    wf = B2 / "templates" / "b1_smoke.yml"
    if not wf.is_file():
        wf = B2 / ".github" / "workflows" / "b1_smoke.yml"
    readme = B2 / "README.md"

    _check("model_card_exists", card.is_file(), str(card), rows)
    _check("workflow_exists", wf.is_file(), str(wf), rows)
    _check("readme_exists", readme.is_file(), str(readme), rows)

    text = card.read_text(encoding="utf-8").lower() if card.is_file() else ""
    required = [
        ("estimando_ate", "ate" in text or "estimando" in text),
        ("supuestos", "ignorabilidad" in text or "supuesto" in text or "sutva" in text),
        ("poblacion", "población" in text or "poblacion" in text or "train" in text),
        ("limites", "límite" in text or "limite" in text or "sintético" in text or "sintetico" in text),
        ("no_solo_accuracy", "accuracy" in text or "identific" in text),
    ]
    for name, ok in required:
        _check(f"card_{name}", ok, name, rows)

    wf_txt = wf.read_text(encoding="utf-8") if wf.is_file() else ""
    _check("workflow_pytest", "pytest" in wf_txt, "runs pytest", rows)
    _check("workflow_grade_b1", "grade_b1" in wf_txt, "runs grade_b1", rows)
    _check("workflow_on_push", "push" in wf_txt or "pull_request" in wf_txt, "trigger", rows)

    n_ok = sum(1 for _, ok in rows if ok)
    n = len(rows)
    print("-" * 60)
    print(f"Result: {'PASS' if n_ok == n else 'FAIL'} ({n_ok}/{n} checks)")
    return 0 if n_ok == n else 1


if __name__ == "__main__":
    raise SystemExit(main())
