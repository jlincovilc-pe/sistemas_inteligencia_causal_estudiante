"""Path resolution for Serie A notebooks (kernel-less, monorepo-relative).

All dataset paths are resolved from this file's location so notebooks and
tests work regardless of the current working directory. No machine-specific
absolute paths are hardcoded.
"""

from __future__ import annotations

from pathlib import Path
from typing import Optional, Union

PathLike = Union[str, Path]

# Global reproducibility seed for course code (dataset generator seeds live in metadata).
RANDOM_STATE: int = 42

# Canonical scenario keys used by notebooks A1–A4.
SCENARIO_A1: str = "real/jobs"
SCENARIO_A2: str = "synthetic/inference/ihdp_medium"
SCENARIO_A3: str = "real/ihdp"
SCENARIO_A4: str = "real/ihdp"

SCENARIO_IDS = {
    SCENARIO_A1: "real_jobs",
    SCENARIO_A2: "synthetic_inference_ihdp_medium",
    SCENARIO_A3: "real_ihdp",
    SCENARIO_A4: "real_ihdp",
}


def package_root() -> Path:
    """Return ``03_notebooks_caso_estudio/`` (directory containing ``lib/``)."""
    return Path(__file__).resolve().parent.parent


def repo_root() -> Path:
    """Return monorepo root (parent of ``03_notebooks_caso_estudio``)."""
    return package_root().parent


def data_root() -> Path:
    """Return root of causal benchmark datasets.

    Resolves to::

        <repo>/data_benchmark_causal/causal_benchmark_synthetic/datasets
    """
    return (
        repo_root()
        / "data_benchmark_causal"
        / "causal_benchmark_synthetic"
        / "datasets"
    )


# Public alias used in plan docs.
DATA_ROOT: Path = data_root()


def scenario_dir(scenario: str) -> Path:
    """Resolve a scenario path under :func:`data_root`.

    Parameters
    ----------
    scenario:
        Relative scenario key, e.g. ``'real/jobs'``,
        ``'synthetic/inference/ihdp_medium'``, ``'real/ihdp'``.
        Leading/trailing slashes are stripped. Backslashes are normalized.

    Returns
    -------
    pathlib.Path
        Absolute path to the scenario directory (not required to exist yet).

    Raises
    ------
    ValueError
        If ``scenario`` is empty or attempts path traversal outside DATA_ROOT.
    """
    if scenario is None:
        raise ValueError("scenario must be a non-empty string")
    key = str(scenario).strip().replace("\\", "/").strip("/")
    if not key:
        raise ValueError("scenario must be a non-empty string")
    if ".." in Path(key).parts:
        raise ValueError(f"scenario must not contain '..': {scenario!r}")

    root = data_root().resolve()
    path = (root / key).resolve()
    try:
        path.relative_to(root)
    except ValueError as exc:
        raise ValueError(
            f"scenario path escapes DATA_ROOT: {scenario!r}"
        ) from exc
    return path


def artifacts_dir(notebook_id: Optional[str] = None) -> Path:
    """Return ``artifacts/`` or ``artifacts/<notebook_id>/`` under package root."""
    base = package_root() / "artifacts"
    if notebook_id is None:
        return base
    return base / str(notebook_id)


def notebooks_dir() -> Path:
    """Return ``notebooks/`` under package root."""
    return package_root() / "notebooks"


def autograder_dir() -> Path:
    """Return ``autograder/`` under package root."""
    return package_root() / "autograder"


def ensure_dir(path: PathLike) -> Path:
    """Create directory (and parents) if missing; return Path."""
    p = Path(path)
    p.mkdir(parents=True, exist_ok=True)
    return p


def relative_to_repo(path: PathLike) -> str:
    """Return path as a POSIX string relative to monorepo root when possible."""
    p = Path(path).resolve()
    try:
        return p.relative_to(repo_root().resolve()).as_posix()
    except ValueError:
        return p.as_posix()


def resolve_repo_path(path: PathLike) -> Path:
    """Resolve a path that may be absolute, cwd-relative, or monorepo-relative.

    Order of attempts:
    1. As given (absolute or relative to cwd) if it exists.
    2. Relative to monorepo root.
    3. Relative to package root (``03_notebooks_caso_estudio/``).
    4. Fallback: resolved path as given (may not exist yet).
    """
    p = Path(path)
    if p.is_absolute() and p.exists():
        return p.resolve()
    if p.exists():
        return p.resolve()
    cand = repo_root() / p
    if cand.exists():
        return cand.resolve()
    cand = package_root() / p
    if cand.exists():
        return cand.resolve()
    # Prefer monorepo-relative resolution for paths that start with package name
    return (repo_root() / p).resolve()
