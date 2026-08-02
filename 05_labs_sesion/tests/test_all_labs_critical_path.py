"""Collect smoke checks for critical-path labs L04–L12, L14."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

import pytest

LABS_ROOT = Path(__file__).resolve().parents[1]
CRITICAL = [
    "L01_correlacion_causacion",
    "L02_entorno_hf_git",
    "L03_pch_clasificar",
    "L04_roles_eda_jobs",
    "L05_pds_jobs",
    "L06_splits_jobs",
    "L07_backdoor_latente",
    "L08_leakage_ihdp",
    "L09_neyman_residuals",
    "L10_plr_minimo",
    "L11_qini_placebo",
    "L12_fastapi_stub",
    "L13_t_learner_ihdp",
    "L14_b1_humo",
    "L15_checklist_a1a3",
    "L17_model_card_esqueleto",
    "L18_gha_humo_b1",
    "L19_explicacion_causal",
    "L20_shap_audit",
    "L21_formalizar_decision",
    "L22_policy_topk",
    "L23_uplift_gradio_stub",
    "L24_transportabilidad",
    "L25_ks_drift",
    "L26_discovery_pc",
    "L27_reentrenar_alertar",
    "L28_comunicar_ate",
]


def _load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    # Register so dataclasses/pickle see unique names if needed
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod


def _load_checks(lab_name: str):
    lab_dir = LABS_ROOT / lab_name
    checks_path = lab_dir / "checks.py"
    core_path = lab_dir / "lab_core.py"
    if not checks_path.is_file():
        pytest.skip(f"no checks.py for {lab_name}")

    # Labs root for lab_harness; do NOT leave previous lab_dir first on path
    # Clean previous lab paths from sys.path
    sys.path = [p for p in sys.path if "05_labs_sesion/L" not in p.replace("\\", "/")]
    if str(LABS_ROOT) not in sys.path:
        sys.path.insert(0, str(LABS_ROOT))

    # Load lab_core under a unique module name first
    if core_path.is_file():
        core = _load_module(f"labs.{lab_name}.lab_core", core_path)
        sys.modules["lab_core"] = core  # what checks.py imports

    checks = _load_module(f"labs.{lab_name}.checks", checks_path)
    return checks


@pytest.mark.parametrize("lab_name", CRITICAL)
def test_lab_checks(lab_name: str):
    mod = _load_checks(lab_name)
    tests = [getattr(mod, n) for n in dir(mod) if n.startswith("test_")]
    assert tests, f"no test_* in {lab_name}/checks.py"
    for fn in tests:
        fn()
