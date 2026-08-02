"""L18 — Validar workflow GitHub Actions de humo B1 (prep B2)."""

from __future__ import annotations

import sys
from pathlib import Path

_LABS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(_LABS))
from lab_harness import REPO_ROOT


def load_workflow() -> tuple:
    """Return ``(workflow_text, path_str)``; empty strings if missing."""
    candidates = [
        # Plantilla local del curso (sin publicar a GitHub)
        REPO_ROOT
        / "04_notebooks_produccion_hf"
        / "B2_hub_cicd"
        / "templates"
        / "b1_smoke.yml",
        REPO_ROOT
        / "04_notebooks_produccion_hf"
        / "B2_hub_cicd"
        / ".github"
        / "workflows"
        / "b1_smoke.yml",
        REPO_ROOT / ".github" / "workflows" / "b1_smoke.yml",
    ]
    for p in candidates:
        if p.is_file():
            return p.read_text(encoding="utf-8"), str(p)
    return "", ""


def validate_workflow(text: str) -> dict:
    checks = {
        "has_pytest": "pytest" in text,
        "has_grade_b1": "grade_b1" in text,
        "has_trigger": ("push" in text or "pull_request" in text or "workflow_dispatch" in text),
        "has_python_setup": "setup-python" in text or "python-version" in text,
        "mentions_b1": "B1" in text or "b1" in text,
    }
    return {
        "checks": checks,
        "ok": all(checks.values()),
        "n_ok": sum(1 for v in checks.values() if v),
    }


def run_lab() -> dict:
    text, path = load_workflow()
    val = validate_workflow(text) if text else {"ok": False, "checks": {}, "n_ok": 0}
    return {
        "workflow_path": path,
        "found": bool(text),
        "validation": val,
        "feeds": "B2 CI/CD",
        "session": "S18",
    }


if __name__ == "__main__":
    import json

    print(json.dumps(run_lab(), indent=2))
