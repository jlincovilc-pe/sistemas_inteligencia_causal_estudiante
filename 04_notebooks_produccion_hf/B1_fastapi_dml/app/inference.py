"""Pure inference helpers (no FastAPI) — avoids training-serving skew in the route layer."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Mapping, Optional, Sequence, Union

import numpy as np

from .paths import artifact_paths, default_artifacts_dir, ensure_serie_a_on_path

ArrayLike = Union[Sequence[float], np.ndarray, Mapping[str, float]]


@dataclass
class PredictResult:
    effect: float
    effects: List[float]
    ate: float
    se: Optional[float]
    ci_low: Optional[float]
    ci_high: Optional[float]
    n: int
    method: str
    estimand: str = "ATE"


@dataclass
class LoadedModel:
    estimator: Any
    feature_names: List[str]
    meta: Dict[str, Any]
    joblib_path: Path

    @property
    def ate(self) -> float:
        if hasattr(self.estimator, "const_marginal_ate"):
            return float(self.estimator.const_marginal_ate())
        if hasattr(self.estimator, "ate"):
            return float(self.estimator.ate())
        if hasattr(self.estimator, "ate_"):
            return float(self.estimator.ate_)
        raise AttributeError("Estimator has no ATE interface")

    @property
    def se(self) -> Optional[float]:
        v = getattr(self.estimator, "se_", None)
        if v is None:
            v = self.meta.get("se")
        return None if v is None else float(v)

    @property
    def ci(self) -> tuple[Optional[float], Optional[float]]:
        lo = getattr(self.estimator, "ci_low_", None)
        hi = getattr(self.estimator, "ci_high_", None)
        if lo is None:
            lo = self.meta.get("ci_low")
        if hi is None:
            hi = self.meta.get("ci_high")
        return (
            None if lo is None else float(lo),
            None if hi is None else float(hi),
        )

    @property
    def method(self) -> str:
        return str(
            getattr(self.estimator, "method_", None)
            or self.meta.get("backend_method")
            or self.meta.get("method")
            or "unknown"
        )


def load_feature_list(path: Path) -> List[str]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, list) or not data:
        raise ValueError(f"feature_list.json must be a non-empty list: {path}")
    return [str(x) for x in data]


def load_meta(path: Path) -> Dict[str, Any]:
    if not path.is_file():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def load_model(artifacts_dir: Optional[Path] = None) -> LoadedModel:
    """Load A2 joblib + sidecars.

    Uses :func:`app.estimator_shim.load_plr_joblib` so serving does not
    require pandas/sklearn — only numpy + joblib.
    """
    # Optional: Serie A on path for other tooling; not required for shim load
    try:
        ensure_serie_a_on_path()
    except Exception:
        pass

    from .estimator_shim import load_plr_joblib

    paths = artifact_paths(artifacts_dir)
    joblib_path = paths["joblib"]
    if not joblib_path.is_file():
        raise FileNotFoundError(
            f"Missing estimator joblib at {joblib_path}. "
            "Run scripts/sync_a2_artifacts.py or export A2 first."
        )
    estimator = load_plr_joblib(joblib_path)
    features = load_feature_list(paths["feature_list"])
    meta = load_meta(paths["training_meta"])
    # Prefer feature list from estimator if present
    est_feats = getattr(estimator, "feature_names_", None)
    if est_feats:
        features = [str(x) for x in est_feats]
    return LoadedModel(
        estimator=estimator,
        feature_names=features,
        meta=meta,
        joblib_path=joblib_path,
    )


def encode_features(
    rows: Union[Mapping[str, float], Sequence[Mapping[str, float]], np.ndarray],
    feature_names: Sequence[str],
) -> np.ndarray:
    """Encode covariates to a 2d float array in ``feature_names`` order.

    Accepts:
    - one dict ``{feature: value}``
    - list of dicts
    - 2d array already ordered
    """
    if isinstance(rows, np.ndarray):
        X = np.asarray(rows, dtype=float)
        if X.ndim == 1:
            X = X.reshape(1, -1)
        if X.shape[1] != len(feature_names):
            raise ValueError(
                f"Expected {len(feature_names)} features, got {X.shape[1]}"
            )
        return X

    if isinstance(rows, Mapping):
        row_list = [rows]
    else:
        row_list = list(rows)

    matrix = []
    for i, row in enumerate(row_list):
        if not isinstance(row, Mapping):
            raise TypeError(f"row {i} must be a mapping of feature -> value")
        missing = [f for f in feature_names if f not in row]
        if missing:
            raise ValueError(
                f"row {i} missing features: {missing[:5]}"
                + ("…" if len(missing) > 5 else "")
            )
        matrix.append([float(row[f]) for f in feature_names])
    return np.asarray(matrix, dtype=float)


def predict_effects(model: LoadedModel, X: np.ndarray) -> PredictResult:
    """Run estimator; separate from HTTP layer."""
    est = model.estimator
    if hasattr(est, "predict"):
        raw = np.asarray(est.predict(X), dtype=float).reshape(-1)
    else:
        ate = model.ate
        raw = np.full(X.shape[0], ate, dtype=float)

    ate = model.ate
    lo, hi = model.ci
    return PredictResult(
        effect=float(raw[0]) if len(raw) else float(ate),
        effects=[float(x) for x in raw.tolist()],
        ate=float(ate),
        se=model.se,
        ci_low=lo,
        ci_high=hi,
        n=int(X.shape[0]),
        method=model.method,
        estimand=str(model.meta.get("estimand", "ATE")),
    )


def health_payload(model: LoadedModel) -> Dict[str, Any]:
    lo, hi = model.ci
    return {
        "status": "ok",
        "model_loaded": True,
        "joblib": str(model.joblib_path.name),
        "n_features": len(model.feature_names),
        "ate": model.ate,
        "se": model.se,
        "ci_low": lo,
        "ci_high": hi,
        "method": model.method,
        "scenario_id": model.meta.get("scenario_id"),
        "artifacts_dir": str(default_artifacts_dir()),
    }
