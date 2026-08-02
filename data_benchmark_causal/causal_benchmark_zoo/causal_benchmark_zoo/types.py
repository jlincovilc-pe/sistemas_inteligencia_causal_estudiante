from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

import pandas as pd
import networkx as nx


@dataclass(frozen=True)
class GroundTruth:
    kind: str
    estimand: str | None = None
    value: float | None = None
    standard_error: float | None = None
    confidence_interval: tuple[float, float] | None = None
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class CausalBenchmark:
    id: str
    name: str
    category: str
    data: pd.DataFrame | None
    graph: nx.DiGraph | None
    treatment: str | None
    outcome: str | None
    covariates: list[str]
    effect_modifiers: list[str]
    ground_truth: GroundTruth
    manifest: dict[str, Any]
