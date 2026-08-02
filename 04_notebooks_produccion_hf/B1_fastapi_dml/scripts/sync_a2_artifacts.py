#!/usr/bin/env python3
"""Copy A2 artifacts into B1_fastapi_dml/artifacts/."""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

B1 = Path(__file__).resolve().parents[1]
REPO = B1.parents[1]
SRC = REPO / "03_notebooks_caso_estudio" / "artifacts" / "A2"
DST = B1 / "artifacts"

FILES = ("dml_estimator.joblib", "feature_list.json", "training_meta.json")


def main() -> int:
    if not SRC.is_dir():
        print(f"ERROR: A2 artifacts missing at {SRC}", file=sys.stderr)
        return 1
    DST.mkdir(parents=True, exist_ok=True)
    for name in FILES:
        s = SRC / name
        if not s.is_file():
            print(f"ERROR: missing {s}", file=sys.stderr)
            return 1
        shutil.copy2(s, DST / name)
        print(f"copied {name} -> {DST / name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
