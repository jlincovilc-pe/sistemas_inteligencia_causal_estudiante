"""Resolve monorepo paths for A2 artifacts and Serie A ``lib`` (joblib unpickle)."""

from __future__ import annotations

import os
import sys
from pathlib import Path
from typing import Optional


def b1_root() -> Path:
    """``…/B1_fastapi_dml/``."""
    return Path(__file__).resolve().parents[1]


def serie_b_root() -> Path:
    """``…/04_notebooks_produccion_hf/``."""
    return b1_root().parent


def repo_root() -> Path:
    """Monorepo root (parent of ``04_notebooks_produccion_hf``)."""
    return serie_b_root().parent


def serie_a_root() -> Path:
    """``…/03_notebooks_caso_estudio/`` (provides ``lib`` for joblib)."""
    return repo_root() / "03_notebooks_caso_estudio"


def ensure_serie_a_on_path() -> Path:
    """Insert Serie A package root on ``sys.path`` so ``import lib`` works."""
    root = serie_a_root().resolve()
    s = str(root)
    if s not in sys.path:
        sys.path.insert(0, s)
    return root


def default_artifacts_dir() -> Path:
    """Local B1 artifacts (copied from A2) or override via env."""
    env = os.environ.get("B1_ARTIFACTS_DIR")
    if env:
        return Path(env).expanduser().resolve()
    return b1_root() / "artifacts"


def artifact_paths(artifacts_dir: Optional[Path] = None) -> dict[str, Path]:
    d = Path(artifacts_dir) if artifacts_dir is not None else default_artifacts_dir()
    return {
        "joblib": d / "dml_estimator.joblib",
        "feature_list": d / "feature_list.json",
        "training_meta": d / "training_meta.json",
    }
