"""L02 — Checklist de entorno (Git, Python, HF, Docker) — Lab 0."""

from __future__ import annotations

import importlib.util
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Dict, List


def _has_cmd(name: str) -> bool:
    return shutil.which(name) is not None


def _has_mod(name: str) -> bool:
    return importlib.util.find_spec(name) is not None


def check_git() -> Dict:
    ok = _has_cmd("git")
    version = None
    if ok:
        try:
            version = (
                subprocess.check_output(["git", "--version"], text=True).strip()
            )
        except Exception:
            ok = False
    return {"tool": "git", "ok": ok, "detail": version}


def check_python() -> Dict:
    return {
        "tool": "python",
        "ok": sys.version_info >= (3, 10) or sys.version_info >= (3, 9),
        "detail": sys.version.split()[0],
    }


def check_core_packages() -> Dict:
    pkgs = ["numpy", "pandas", "sklearn", "joblib"]
    present = {p: _has_mod(p if p != "sklearn" else "sklearn") for p in pkgs}
    return {
        "tool": "core_packages",
        "ok": all(present.values()),
        "detail": present,
    }


def check_docker_optional() -> Dict:
    return {"tool": "docker", "ok": _has_cmd("docker"), "optional": True}


def check_repo_layout() -> Dict:
    root = Path(__file__).resolve().parents[2]
    needed = [
        "03_notebooks_caso_estudio",
        "04_notebooks_produccion_hf",
        "data_benchmark_causal",
        "PLAN_CURSO_COMPLETO.md",
    ]
    found = {n: (root / n).exists() for n in needed}
    return {"tool": "monorepo_layout", "ok": all(found.values()), "detail": found}


def checklist() -> List[Dict]:
    return [
        check_git(),
        check_python(),
        check_core_packages(),
        check_docker_optional(),
        check_repo_layout(),
    ]


def run_lab() -> dict:
    items = checklist()
    required_ok = all(i["ok"] for i in items if not i.get("optional"))
    return {
        "items": items,
        "required_ok": required_ok,
        "hf_note": (
            "Crear cuenta en huggingface.co y `huggingface-cli login` "
            "cuando se aborde B2/B3 (opcional en S2)."
        ),
        "session": "S2",
    }


if __name__ == "__main__":
    import json

    print(json.dumps(run_lab(), indent=2, default=str))
