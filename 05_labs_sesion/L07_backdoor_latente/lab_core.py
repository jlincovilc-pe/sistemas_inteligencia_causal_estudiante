"""L07 — Backdoor vs confusor latente (contrajemplo no identificable)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

_LABS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(_LABS))
from lab_harness import ensure_serie_a

ensure_serie_a()

from lib.data_io import load_scenario
from lib.paths import scenario_dir


def inspect_latent_scenario() -> dict:
    key = "synthetic/edge_cases/latent_confounder"
    path = scenario_dir(key)
    meta = {}
    ident = {}
    if (path / "metadata.json").is_file():
        meta = json.loads((path / "metadata.json").read_text())
    if (path / "identification.json").is_file():
        ident = json.loads((path / "identification.json").read_text())
    # load observed to confirm no treatment columns for naive ATE
    try:
        b = load_scenario(key)
        cols = list(b.train.columns)
        n = len(b.train)
    except Exception as exc:
        cols, n = [], 0
        meta["load_error"] = str(exc)
    status = str(
        ident.get("identification_status")
        or meta.get("identification_status")
        or ""
    )
    return {
        "scenario": key,
        "n_rows_train": n,
        "columns": cols[:15],
        "identification_status": status,
        "not_identifiable": "not_identifiable" in status or "latent" in status,
        "lesson": (
            "Sin observar el confusor latente, el backdoor no se cierra; "
            "el benchmark marca el escenario como no identificable desde observables."
        ),
    }


def backdoor_checklist_jobs() -> dict:
    """Contrast: Jobs is identifiable by design with full covariate set."""
    key = "real/jobs"
    path = scenario_dir(key)
    ident = {}
    if (path / "identification.json").is_file():
        ident = json.loads((path / "identification.json").read_text())
    adj = ident.get("valid_adjustment_sets") or []
    return {
        "scenario": key,
        "status": ident.get("identification_status"),
        "has_adjustment_set": len(adj) > 0,
        "n_sets": len(adj),
        "lesson": "Con X pre-tratamiento completos (por diseño SEM), backdoor es defendible en el benchmark.",
    }


def run_lab() -> dict:
    latent = inspect_latent_scenario()
    jobs = backdoor_checklist_jobs()
    return {
        "latent": latent,
        "jobs": jobs,
        "contrast_ok": latent["not_identifiable"] and jobs["has_adjustment_set"],
        "session": "S7",
    }


if __name__ == "__main__":
    print(json.dumps(run_lab(), indent=2, default=str))
