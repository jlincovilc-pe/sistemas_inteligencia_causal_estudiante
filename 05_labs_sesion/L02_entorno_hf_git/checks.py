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


if __name__ == "__main__":
    test_env_required()
    print("L02 OK")
