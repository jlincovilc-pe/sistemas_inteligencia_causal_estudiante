#!/usr/bin/env python3
"""Copy A4 policy artifacts into B3_policy_space/artifacts/."""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

B3 = Path(__file__).resolve().parents[1]
REPO = B3.parents[1]
SRC = REPO / "03_notebooks_caso_estudio" / "artifacts" / "A4"
DST = B3 / "artifacts"
FILES = (
    "policy.joblib",
    "policy_card.md",
    "uplift_curve.png",
    "equity_table.csv",
)


def main() -> int:
    if not SRC.is_dir():
        print(f"ERROR: {SRC}", file=sys.stderr)
        return 1
    DST.mkdir(parents=True, exist_ok=True)
    for name in FILES:
        s = SRC / name
        if not s.is_file():
            print(f"WARN: missing {s}", file=sys.stderr)
            continue
        shutil.copy2(s, DST / name)
        print(f"copied {name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
