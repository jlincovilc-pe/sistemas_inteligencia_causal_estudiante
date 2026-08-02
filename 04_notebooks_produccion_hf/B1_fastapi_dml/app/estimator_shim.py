"""Portable PLR estimator for serving (no sklearn/pandas).

Used when unpickling A2 joblib without importing the full Serie A stack.
The class layout matches ``lib.dml_utils.SerializablePLREstimator``.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Sequence, Tuple, Union

import numpy as np

MatrixLike = Union[np.ndarray, Sequence[Sequence[float]]]


@dataclass
class SerializablePLREstimator:
    """Minimal ATE-only PLR payload for Serie B (B1) serving."""

    ate_: float
    se_: Optional[float] = None
    ci_low_: Optional[float] = None
    ci_high_: Optional[float] = None
    feature_names_: Optional[List[str]] = None
    method_: str = "plr"
    n_folds_: int = 0
    training_n_: int = 0
    extra_: Dict[str, Any] = field(default_factory=dict)

    def const_marginal_ate(self, X: Any = None) -> float:
        return float(self.ate_)

    def ate(self, X: Any = None) -> float:
        return self.const_marginal_ate(X)

    def predict(self, X: MatrixLike) -> np.ndarray:
        X_arr = np.asarray(X, dtype=float)
        if X_arr.ndim == 1:
            X_arr = X_arr.reshape(1, -1)
        n = int(X_arr.shape[0])
        return np.full(n, float(self.ate_), dtype=float)

    def conf_int(self, alpha: float = 0.05) -> Tuple[float, float]:
        if self.ci_low_ is not None and self.ci_high_ is not None:
            return float(self.ci_low_), float(self.ci_high_)
        if self.se_ is None:
            raise ValueError("No SE/CI stored on this estimator")
        z = 1.96
        return float(self.ate_ - z * self.se_), float(self.ate_ + z * self.se_)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "ate": self.ate_,
            "se": self.se_,
            "ci_low": self.ci_low_,
            "ci_high": self.ci_high_,
            "feature_names": self.feature_names_,
            "method": self.method_,
            "n_folds": self.n_folds_,
            "training_n": self.training_n_,
            "extra": self.extra_,
        }


def load_plr_joblib(path) -> Any:
    """Load joblib remapping ``SerializablePLREstimator`` to this shim."""
    import io
    import pickle
    from pathlib import Path

    import joblib

    path = Path(path)

    class _Remap(pickle.Unpickler):
        def find_class(self, module: str, name: str):
            if name == "SerializablePLREstimator":
                return SerializablePLREstimator
            return super().find_class(module, name)

    # Prefer joblib (numpy pickle); fall back to remap unpickler
    try:
        # Inject shim into sys.modules so joblib/pickle resolve the class
        import sys
        import types

        # Register fake lib.dml_utils if needed
        if "lib" not in sys.modules:
            sys.modules["lib"] = types.ModuleType("lib")
        if "lib.dml_utils" not in sys.modules:
            mod = types.ModuleType("lib.dml_utils")
            mod.SerializablePLREstimator = SerializablePLREstimator
            sys.modules["lib.dml_utils"] = mod
        else:
            sys.modules["lib.dml_utils"].SerializablePLREstimator = (  # type: ignore
                SerializablePLREstimator
            )

        return joblib.load(path)
    except Exception:
        with path.open("rb") as f:
            return _Remap(f).load()
