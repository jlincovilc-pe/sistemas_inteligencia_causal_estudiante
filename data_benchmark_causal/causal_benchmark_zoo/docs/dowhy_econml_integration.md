# DoWhy and EconML integration

The repository includes optional adapters:

```python
from causal_benchmark_zoo.adapters.dowhy import to_dowhy_model
from causal_benchmark_zoo.adapters.econml import to_econml_arrays
```

## Current status

No processed tabular ATE/CATE benchmark is currently active. Therefore these adapters are present but not yet demonstrated with real bundled data.

Current active benchmarks (`bnlearn_asia`, `bnlearn_alarm`) are graph-only and should not be passed to DoWhy/EconML as treatment-effect datasets.

## Expected future use

Once a tabular benchmark such as Lalonde or CSuite is processed:

```python
from causal_benchmark_zoo import load_benchmark
from causal_benchmark_zoo.adapters.econml import to_econml_arrays

bench = load_benchmark("lalonde_nsw")
y, t, x, w = to_econml_arrays(bench)
```

For DoWhy:

```python
from causal_benchmark_zoo.adapters.dowhy import to_dowhy_model

model = to_dowhy_model(bench)
identified = model.identify_effect()
```

## Reporting rule

For real datasets such as Lalonde, report experimental reference estimates with standard errors and confidence intervals when computable. Do not call them exact ground truth constants.
