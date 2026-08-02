from __future__ import annotations


def to_dowhy_model(benchmark):
    if benchmark.data is None:
        raise ValueError(f"{benchmark.id} has no tabular data loaded")
    if benchmark.treatment is None or benchmark.outcome is None:
        raise ValueError(f"{benchmark.id} does not define treatment/outcome for DoWhy")
    try:
        from dowhy import CausalModel
    except ImportError as exc:
        raise ImportError("Install optional dependency 'dowhy' to use this adapter") from exc

    return CausalModel(
        data=benchmark.data,
        treatment=benchmark.treatment,
        outcome=benchmark.outcome,
        common_causes=benchmark.covariates or None,
        effect_modifiers=benchmark.effect_modifiers or None,
    )
