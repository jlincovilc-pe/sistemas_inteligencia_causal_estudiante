from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lab_core import run_lab


def test_env_required():
    out = run_lab()
    assert out["required_ok"] is True
    tools = {i["tool"]: i["ok"] for i in out["items"]}
    assert tools["git"] is True
    assert tools["monorepo_layout"] is True
    assert tools["core_packages"] is True


def test_hf_setup_item_optional():
    """El checklist incluye hf_setup como ítem opcional, no bloqueante.

    Sin token, hf_setup puede reportar ok=False y el lab sigue en verde
    (required_ok se calcula solo sobre ítems no opcionales).
    """
    out = run_lab()
    hf = next((i for i in out["items"] if i["tool"] == "hf_setup"), None)
    assert hf is not None, "checklist debe incluir el ítem hf_setup"
    assert hf["optional"] is True, "hf_setup es opcional (no bloqueante)"
    assert out["required_ok"] is True, "el lab no debe bloquearse por falta de token"


def test_hf_note_obligatoria_en_s2():
    """La nota HF refleja que cuenta + token son obligatorios en S2."""
    note = run_lab()["hf_note"].lower()
    assert "obligatorio" in note
    assert "opcional en s2" not in note


if __name__ == "__main__":
    test_env_required()
    test_hf_setup_item_optional()
    test_hf_note_obligatoria_en_s2()
    print("L02 OK")
