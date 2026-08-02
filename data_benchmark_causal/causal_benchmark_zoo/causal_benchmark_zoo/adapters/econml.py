from __future__ import annotations


def to_econml_arrays(benchmark):
    if benchmark.data is None:
        raise ValueError(f"{benchmark.id} has no tabular data loaded")
    if benchmark.treatment is None or benchmark.outcome is None:
        raise ValueError(f"{benchmark.id} does not define treatment/outcome for EconML")

    y = benchmark.data[benchmark.outcome].to_numpy()
    t = benchmark.data[benchmark.treatment].to_numpy()
    x = None
    w = benchmark.data[benchmark.covariates].to_numpy() if benchmark.covariates else None
    return y, t, x, w
