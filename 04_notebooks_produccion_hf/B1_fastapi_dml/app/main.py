"""FastAPI entrypoint for B1 — serve A2 DML estimator.

Routes:
  GET  /health
  GET  /metadata
  POST /predict

Run locally::

    cd 04_notebooks_produccion_hf/B1_fastapi_dml
    uvicorn app.main:app --host 0.0.0.0 --port 8000
"""

from __future__ import annotations

import os
from contextlib import asynccontextmanager
from typing import Any, Dict, List, Optional, Union

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from .inference import (
    encode_features,
    health_payload,
    load_model,
    predict_effects,
)
from .paths import default_artifacts_dir

# ---------------------------------------------------------------------------
# Schemas
# ---------------------------------------------------------------------------


class PredictRequest(BaseModel):
    """Either a single feature map or a batch of maps; or a dense matrix."""

    features: Optional[Dict[str, float]] = Field(
        default=None,
        description="Single observation: {x0: …, x24: …}",
    )
    instances: Optional[List[Dict[str, float]]] = Field(
        default=None,
        description="Batch of observations as feature maps",
    )
    matrix: Optional[List[List[float]]] = Field(
        default=None,
        description="Dense matrix rows in feature_list order",
    )

    model_config = {"extra": "forbid"}


class PredictResponse(BaseModel):
    effect: float
    effects: List[float]
    ate: float
    se: Optional[float] = None
    ci_low: Optional[float] = None
    ci_high: Optional[float] = None
    n: int
    method: str
    estimand: str = "ATE"


# ---------------------------------------------------------------------------
# App lifespan — load model once
# ---------------------------------------------------------------------------

_MODEL = None


def get_model():
    global _MODEL
    if _MODEL is None:
        _MODEL = load_model()
    return _MODEL


@asynccontextmanager
async def lifespan(app: FastAPI):
    global _MODEL
    # Allow empty load in pure schema tests via env
    if os.environ.get("B1_SKIP_MODEL_LOAD") == "1":
        yield
        return
    try:
        _MODEL = load_model()
    except Exception as exc:  # pragma: no cover — surfaced on /health
        _MODEL = None
        app.state.load_error = str(exc)
    else:
        app.state.load_error = None
    yield


app = FastAPI(
    title="B1 Causal DML Service",
    description=(
        "Sirve el estimador DML de la Serie A (A2, ihdp_medium). "
        "Estimando: ATE bajo PLR. Ver model card / training_meta."
    ),
    version="0.1.0",
    lifespan=lifespan,
)


@app.get("/health")
def health() -> Dict[str, Any]:
    err = getattr(app.state, "load_error", None)
    if _MODEL is None:
        return {
            "status": "error",
            "model_loaded": False,
            "error": err or "model not loaded",
            "artifacts_dir": str(default_artifacts_dir()),
        }
    return health_payload(_MODEL)


@app.get("/metadata")
def metadata() -> Dict[str, Any]:
    if _MODEL is None:
        raise HTTPException(status_code=503, detail="model not loaded")
    lo, hi = _MODEL.ci
    return {
        "feature_names": _MODEL.feature_names,
        "n_features": len(_MODEL.feature_names),
        "ate": _MODEL.ate,
        "se": _MODEL.se,
        "ci_low": lo,
        "ci_high": hi,
        "method": _MODEL.method,
        "training_meta": _MODEL.meta,
        "estimand": _MODEL.meta.get("estimand", "ATE"),
        "assumptions": _MODEL.meta.get("assumptions", []),
    }


@app.post("/predict", response_model=PredictResponse)
def predict(body: PredictRequest) -> PredictResponse:
    if _MODEL is None:
        raise HTTPException(status_code=503, detail="model not loaded")

    try:
        if body.matrix is not None:
            import numpy as np

            X = encode_features(np.asarray(body.matrix, dtype=float), _MODEL.feature_names)
        elif body.instances is not None:
            X = encode_features(body.instances, _MODEL.feature_names)
        elif body.features is not None:
            X = encode_features(body.features, _MODEL.feature_names)
        else:
            raise HTTPException(
                status_code=422,
                detail="Provide one of: features, instances, matrix",
            )
        result = predict_effects(_MODEL, X)
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    return PredictResponse(
        effect=result.effect,
        effects=result.effects,
        ate=result.ate,
        se=result.se,
        ci_low=result.ci_low,
        ci_high=result.ci_high,
        n=result.n,
        method=result.method,
        estimand=result.estimand,
    )
