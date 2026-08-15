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


def check_hf_setup() -> Dict:
    """Ítem opcional: ¿la cuenta de Hugging Face quedó autenticada (S2)?

    Delega en ``04_notebooks_produccion_hf/B2_hub_cicd/scripts/hf_refuerzos.py
    setup`` (el mismo contrato que el refuerzo HF de la sesión 2 del sílabo):
    corre el subcomando como subproceso, captura la salida y reporta si la
    cuenta quedó autenticada o no. El script degrada con aviso cuando no hay
    token o falta ``huggingface_hub``, así que este ítem **nunca bloquea el
    lab**: sin token devuelve ``ok=False`` con un detalle legible y el resto
    del checklist sigue en verde (``optional=True``).
    """
    root = Path(__file__).resolve().parents[2]
    script = (
        root
        / "04_notebooks_produccion_hf"
        / "B2_hub_cicd"
        / "scripts"
        / "hf_refuerzos.py"
    )
    if not script.is_file():
        return {
            "tool": "hf_setup",
            "ok": False,
            "optional": True,
            "detail": f"no existe {script.relative_to(root)}",
        }
    try:
        proc = subprocess.run(
            [sys.executable, str(script), "setup"],
            capture_output=True,
            text=True,
            timeout=60,
        )
        out = ((proc.stdout or "") + (proc.stderr or "")).strip()
        authed = proc.returncode == 0 and "autenticada" in out
        detail = out.splitlines()[-1] if out else f"exit={proc.returncode}"
        return {"tool": "hf_setup", "ok": authed, "optional": True, "detail": detail}
    except subprocess.TimeoutExpired:
        return {"tool": "hf_setup", "ok": False, "optional": True, "detail": "timeout (60s)"}
    except Exception as exc:  # pragma: no cover
        return {"tool": "hf_setup", "ok": False, "optional": True, "detail": repr(exc)}


def checklist() -> List[Dict]:
    return [
        check_git(),
        check_python(),
        check_core_packages(),
        check_docker_optional(),
        check_repo_layout(),
        check_hf_setup(),  # opcional: no bloquea el lab si falta token
    ]


def run_lab() -> dict:
    items = checklist()
    required_ok = all(i["ok"] for i in items if not i.get("optional"))
    return {
        "items": items,
        "required_ok": required_ok,
        "hf_note": (
            "Crear la cuenta en huggingface.co y configurar el token "
            "(`notebook_login` / `huggingface-cli login`) es OBLIGATORIO en S2: "
            "es la llave de todo el hilo de producción del curso (datasets en S5 "
            "y S8, modelo en S13, Spaces en S23). No es un trámite para B2/B3: "
            "sin token no se puede subir nada al Hub."
        ),
        "session": "S2",
    }


if __name__ == "__main__":
    import json

    print(json.dumps(run_lab(), indent=2, default=str))
