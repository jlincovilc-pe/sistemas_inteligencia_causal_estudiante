"""Data I/O for Serie A — observed vs truth separation.

Student-facing flow uses only ``observed_*.csv``. Ground truth
(``truth_*.csv`` with ``y0``, ``y1``, ``tau``) is for autograder and
clearly marked final evaluation cells only.

Scenario strings (relative to DATA_ROOT)::

    'real/jobs'
    'synthetic/inference/ihdp_medium'
    'real/ihdp'
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional, Sequence, Tuple, Union

import pandas as pd

from .paths import SCENARIO_IDS, data_root, scenario_dir

PathLike = Union[str, Path]

VALID_SPLITS = ("train", "validation", "test", "all")

# Column roles by family of scenarios (loader does not rename by default).
OUTCOME_COL_JOBS = "re78"
OUTCOME_COL_IHDP = "outcome"
TREATMENT_COL = "treatment"
TRUTH_COLS = ("y0", "y1", "tau")
ROW_ID_COL = "row_id"

# Columns never treated as covariates in observed frames.
_NON_COVARIATE = frozenset(
    {
        ROW_ID_COL,
        TREATMENT_COL,
        OUTCOME_COL_JOBS,
        OUTCOME_COL_IHDP,
        "y0",
        "y1",
        "tau",
        "ite",
        "mu0",
        "mu1",
    }
)


@dataclass
class ScenarioPaths:
    """Filesystem paths for one scenario."""

    root: Path
    observed_train: Path
    observed_validation: Path
    observed_test: Path
    truth_train: Path
    truth_validation: Path
    truth_test: Path
    metadata: Path
    identification: Path
    scorecard: Path
    splits: Path
    observed_all: Optional[Path] = None
    truth_all: Optional[Path] = None

    def as_dict(self) -> Dict[str, Path]:
        d = {
            "root": self.root,
            "observed_train": self.observed_train,
            "observed_validation": self.observed_validation,
            "observed_test": self.observed_test,
            "truth_train": self.truth_train,
            "truth_validation": self.truth_validation,
            "truth_test": self.truth_test,
            "metadata": self.metadata,
            "identification": self.identification,
            "scorecard": self.scorecard,
            "splits": self.splits,
        }
        if self.observed_all is not None:
            d["observed_all"] = self.observed_all
        if self.truth_all is not None:
            d["truth_all"] = self.truth_all
        return d


@dataclass
class ScenarioBundle:
    """In-memory bundle returned by :func:`load_scenario`.

    Attributes
    ----------
    scenario:
        Relative scenario key (e.g. ``'real/jobs'``).
    scenario_id:
        Canonical id from metadata / map (e.g. ``'real_jobs'``).
    train, validation, test:
        Observed DataFrames (student-safe).
    meta, identification, scorecard, splits:
        Parsed JSON dicts when files exist.
    paths:
        :class:`ScenarioPaths` for explicit I/O auditing.
    """

    scenario: str
    scenario_id: str
    train: pd.DataFrame
    validation: pd.DataFrame
    test: pd.DataFrame
    meta: Dict[str, Any] = field(default_factory=dict)
    identification: Dict[str, Any] = field(default_factory=dict)
    scorecard: Dict[str, Any] = field(default_factory=dict)
    splits: Dict[str, Any] = field(default_factory=dict)
    paths: Optional[ScenarioPaths] = None

    # Aliases for plan API naming (val)
    @property
    def val(self) -> pd.DataFrame:
        return self.validation

    def covariate_columns(self) -> List[str]:
        """Infer covariate column names from the train frame."""
        return infer_covariate_columns(self.train)

    def outcome_column(self) -> str:
        return infer_outcome_column(self.train)

    def treatment_column(self) -> str:
        return TREATMENT_COL

    def ytx(
        self, split: str = "train"
    ) -> Tuple[pd.Series, pd.Series, pd.DataFrame]:
        """Return ``(Y, T, X)`` for a split (``train``/``validation``/``test``)."""
        df = self._split_frame(split)
        y_col = self.outcome_column()
        t_col = self.treatment_column()
        x_cols = self.covariate_columns()
        return df[y_col].copy(), df[t_col].copy(), df[x_cols].copy()

    def _split_frame(self, split: str) -> pd.DataFrame:
        key = split.lower().strip()
        if key in ("val", "valid", "validation"):
            return self.validation
        if key == "train":
            return self.train
        if key == "test":
            return self.test
        raise ValueError(f"Unknown split {split!r}; use train/validation/test")


def _normalize_scenario(scenario: str) -> str:
    key = str(scenario).strip().replace("\\", "/").strip("/")
    if not key:
        raise ValueError("scenario must be a non-empty string")
    return key


def resolve_scenario_paths(scenario: str) -> ScenarioPaths:
    """Build :class:`ScenarioPaths` for ``scenario`` under DATA_ROOT."""
    key = _normalize_scenario(scenario)
    root = scenario_dir(key)
    if not root.is_dir():
        raise FileNotFoundError(
            f"Scenario directory not found: {root} "
            f"(scenario={key!r}, DATA_ROOT={data_root()})"
        )

    def _p(name: str) -> Path:
        return root / name

    observed_all = _p("observed.csv")
    truth_all = _p("truth.csv")
    return ScenarioPaths(
        root=root,
        observed_train=_p("observed_train.csv"),
        observed_validation=_p("observed_validation.csv"),
        observed_test=_p("observed_test.csv"),
        truth_train=_p("truth_train.csv"),
        truth_validation=_p("truth_validation.csv"),
        truth_test=_p("truth_test.csv"),
        metadata=_p("metadata.json"),
        identification=_p("identification.json"),
        scorecard=_p("scorecard.json"),
        splits=_p("splits.json"),
        observed_all=observed_all if observed_all.is_file() else None,
        truth_all=truth_all if truth_all.is_file() else None,
    )


def _read_json(path: Path) -> Dict[str, Any]:
    if not path.is_file():
        return {}
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, dict):
        raise ValueError(f"Expected JSON object in {path}")
    return data


def _read_csv(path: Path) -> pd.DataFrame:
    if not path.is_file():
        raise FileNotFoundError(f"Required CSV not found: {path}")
    return pd.read_csv(path)


def load_json_sidecar(scenario: str, name: str) -> Dict[str, Any]:
    """Load a JSON sidecar file (metadata, identification, scorecard, splits)."""
    paths = resolve_scenario_paths(scenario)
    mapping = {
        "metadata": paths.metadata,
        "meta": paths.metadata,
        "identification": paths.identification,
        "scorecard": paths.scorecard,
        "splits": paths.splits,
    }
    key = name.lower().strip()
    if key not in mapping:
        raise ValueError(
            f"Unknown sidecar {name!r}; expected one of {sorted(set(mapping))}"
        )
    return _read_json(mapping[key])


def load_observed(
    scenario: str,
    split: str = "train",
) -> pd.DataFrame:
    """Load an observed split (student-safe; no potential outcomes).

    Parameters
    ----------
    scenario:
        e.g. ``'real/jobs'``.
    split:
        ``'train'``, ``'validation'`` (aliases: ``val``, ``valid``),
        ``'test'``, or ``'all'`` (concat of train+val+test, or ``observed.csv``).
    """
    paths = resolve_scenario_paths(scenario)
    key = split.lower().strip()
    if key in ("val", "valid"):
        key = "validation"

    if key == "train":
        return _read_csv(paths.observed_train)
    if key == "validation":
        return _read_csv(paths.observed_validation)
    if key == "test":
        return _read_csv(paths.observed_test)
    if key == "all":
        if paths.observed_all is not None and paths.observed_all.is_file():
            return _read_csv(paths.observed_all)
        frames = [
            _read_csv(paths.observed_train),
            _read_csv(paths.observed_validation),
            _read_csv(paths.observed_test),
        ]
        return pd.concat(frames, axis=0, ignore_index=True)

    raise ValueError(
        f"Unknown split {split!r}; use train/validation/test/all"
    )


def load_truth(
    scenario: str,
    split: str = "test",
) -> pd.DataFrame:
    """Load ground truth potentials / ITE for evaluation only.

    .. warning::

        **Evaluation-only.** Do not call from student estimation cells.
        Columns typically include ``y0``, ``y1``, ``tau`` (and often
        ``treatment`` + factual outcome). Use only in autograder code or
        notebook sections explicitly marked as ground-truth evaluation.

    Parameters
    ----------
    scenario:
        Scenario key under DATA_ROOT.
    split:
        ``'train'``, ``'validation'``, ``'test'``, or ``'all'``.
    """
    paths = resolve_scenario_paths(scenario)
    key = split.lower().strip()
    if key in ("val", "valid"):
        key = "validation"

    if key == "train":
        return _read_csv(paths.truth_train)
    if key == "validation":
        return _read_csv(paths.truth_validation)
    if key == "test":
        return _read_csv(paths.truth_test)
    if key == "all":
        if paths.truth_all is not None and paths.truth_all.is_file():
            return _read_csv(paths.truth_all)
        frames = [
            _read_csv(paths.truth_train),
            _read_csv(paths.truth_validation),
            _read_csv(paths.truth_test),
        ]
        return pd.concat(frames, axis=0, ignore_index=True)

    raise ValueError(
        f"Unknown split {split!r}; use train/validation/test/all"
    )


def load_scenario(scenario: str) -> ScenarioBundle:
    """Load observed splits + metadata sidecars for a scenario.

    Parameters
    ----------
    scenario:
        ``'real/jobs'``, ``'synthetic/inference/ihdp_medium'``, ``'real/ihdp'``.

    Returns
    -------
    ScenarioBundle
        train, validation, test (observed DataFrames), meta, identification,
        scorecard, splits dicts, and path objects. Truth is **not** loaded.
    """
    key = _normalize_scenario(scenario)
    paths = resolve_scenario_paths(key)

    train = _read_csv(paths.observed_train)
    validation = _read_csv(paths.observed_validation)
    test = _read_csv(paths.observed_test)

    meta = _read_json(paths.metadata)
    identification = _read_json(paths.identification)
    scorecard = _read_json(paths.scorecard)
    splits = _read_json(paths.splits)

    scenario_id = str(
        meta.get("scenario_id")
        or SCENARIO_IDS.get(key)
        or key.replace("/", "_")
    )

    return ScenarioBundle(
        scenario=key,
        scenario_id=scenario_id,
        train=train,
        validation=validation,
        test=test,
        meta=meta,
        identification=identification,
        scorecard=scorecard,
        splits=splits,
        paths=paths,
    )


def infer_outcome_column(df: pd.DataFrame) -> str:
    """Return outcome column name (``re78`` or ``outcome``)."""
    if OUTCOME_COL_JOBS in df.columns:
        return OUTCOME_COL_JOBS
    if OUTCOME_COL_IHDP in df.columns:
        return OUTCOME_COL_IHDP
    raise KeyError(
        f"Could not infer outcome column; expected {OUTCOME_COL_JOBS!r} "
        f"or {OUTCOME_COL_IHDP!r}. Columns: {list(df.columns)}"
    )


def infer_covariate_columns(
    df: pd.DataFrame,
    extra_exclude: Optional[Sequence[str]] = None,
) -> List[str]:
    """Covariates = all columns except treatment, outcome, ids, truth."""
    exclude = set(_NON_COVARIATE)
    if extra_exclude:
        exclude.update(extra_exclude)
    return [c for c in df.columns if c not in exclude]


def get_ytx(
    df: pd.DataFrame,
    y_col: Optional[str] = None,
    t_col: str = TREATMENT_COL,
    x_cols: Optional[Sequence[str]] = None,
) -> Tuple[pd.Series, pd.Series, pd.DataFrame]:
    """Extract ``(Y, T, X)`` from an observed DataFrame."""
    y_name = y_col or infer_outcome_column(df)
    x_names = list(x_cols) if x_cols is not None else infer_covariate_columns(df)
    if t_col not in df.columns:
        raise KeyError(f"Treatment column {t_col!r} not in frame")
    if y_name not in df.columns:
        raise KeyError(f"Outcome column {y_name!r} not in frame")
    missing = [c for c in x_names if c not in df.columns]
    if missing:
        raise KeyError(f"Missing covariate columns: {missing}")
    return df[y_name].copy(), df[t_col].copy(), df[list(x_names)].copy()


def assert_no_truth_columns(df: pd.DataFrame, context: str = "") -> None:
    """Raise if a frame still contains ground-truth columns (leakage guard)."""
    present = [c for c in TRUTH_COLS if c in df.columns]
    if present:
        msg = f"Truth columns present {present}"
        if context:
            msg += f" ({context})"
        raise ValueError(msg)


def list_available_scenarios() -> List[str]:
    """List scenario relative paths that contain ``observed_train.csv``."""
    root = data_root()
    if not root.is_dir():
        return []
    found: List[str] = []
    for path in sorted(root.rglob("observed_train.csv")):
        rel = path.parent.relative_to(root).as_posix()
        found.append(rel)
    return found
